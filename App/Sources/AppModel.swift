import Foundation
import Observation
import SwiftUI
import UserNotifications

enum Screen: Equatable {
    case home
    case room(Int)
    case daily
}

enum ActiveSheet: String, Identifiable {
    case settings, paywall, records, share
    var id: String { rawValue }
}

enum ResultKind: Equatable {
    case room(Int)
    case daily
}

/// 画面の上に一瞬出す知らせ（道具を手に入れた・文字が分かった など）
struct Banner: Equatable {
    var title: String
    var detail: String
    var item: ItemKind?
    var letter: String?
    var id = UUID()
}

/// 最後の扉の文字盤
struct DoorState: Equatable {
    var slots: [String?]
    var keys: [String]
    var used: [Bool]
    var wrong = 0

    init(letters: [String], seed: String) {
        slots = Array(repeating: nil, count: letters.count)
        var rng = SeededRandom(seed: SeededRandom.seed(seed))
        var k = letters
        // 並びが答えと同じにならないように回す
        for _ in 0..<6 {
            k.shuffle(using: &rng)
            if k != letters { break }
        }
        keys = k
        used = Array(repeating: false, count: k.count)
    }
}

@MainActor
@Observable
final class AppModel {
    // MARK: 保存するもの
    var progress = Progress() { didSet { save() } }
    var onboarded: Bool { didSet { if persists { defaults.set(onboarded, forKey: "onboarded") } } }
    var soundOn: Bool { didSet { if persists { defaults.set(soundOn, forKey: "sound") } } }
    var hapticsOn: Bool { didSet { if persists { defaults.set(hapticsOn, forKey: "haptics") } } }
    var reminderOn: Bool { didSet { if persists { defaults.set(reminderOn, forKey: "reminder") } } }
    var paywallOffered: Bool { didSet { if persists { defaults.set(paywallOffered, forKey: "paywallOffered") } } }

    // MARK: 画面
    var screen: Screen = .home
    var openObject: Int?
    var board: Board?
    var door: DoorState?
    var result: ResultKind?
    var activeSheet: ActiveSheet?
    var banner: Banner?
    var showIntro = false
    var unlocking: Int?
    var lockedNotice: Int?
    var reminderDenied = false
    var dailyDayOffset = 0

    // MARK: 手応え（README の手応えの表）
    var pressTick = 0
    var letterTick = 0
    var wordTick = 0
    var itemTick = 0
    var wrongTick = 0
    var unlockTick = 0
    var completeTick = 0
    var escapeTick = 0
    var lastSolvedEntry: Int?
    var lastWrongEntry: Int?

    // MARK: そのほか
    var now: Date
    let calendar: Calendar
    var reduceMotion = false
    /// 撮影中（時計を止め、保存しない）
    var still = false
    var proOverride: Bool?
    let purchases: PurchaseStore
    @ObservationIgnored let persists: Bool
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var clock: Task<Void, Never>?
    @ObservationIgnored private var bannerTask: Task<Void, Never>?

    static let bundleID = Bundle.main.bundleIdentifier ?? "com.enludus.daily.014"
    static var proID: String { ProductID.pro(bundleID: bundleID) }

    init(persists: Bool = true, now: Date = Date()) {
        self.persists = persists
        self.now = now
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        self.calendar = cal
        let d = UserDefaults.standard
        if persists {
            onboarded = d.bool(forKey: "onboarded")
            soundOn = d.object(forKey: "sound") as? Bool ?? true
            hapticsOn = d.object(forKey: "haptics") as? Bool ?? true
            reminderOn = d.bool(forKey: "reminder")
            paywallOffered = d.bool(forKey: "paywallOffered")
        } else {
            onboarded = true
            soundOn = false
            hapticsOn = true
            reminderOn = false
            paywallOffered = true
        }
        purchases = PurchaseStore(productIDs: [AppModel.proID], proProductIDs: [AppModel.proID])
        if persists, let data = d.data(forKey: "progress"), let p = try? JSONDecoder().decode(Progress.self, from: data) {
            progress = p
        }
    }

    private func save() {
        guard persists, !still, let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: "progress")
    }

    var isPro: Bool { proOverride ?? purchases.entitlements.isPro }
    var japanese: Bool { Lang.isJapanese }
    var rooms: [Room] { Content.rooms }

    func roomProgress(_ i: Int) -> RoomProgress {
        progress.rooms[Progress.roomKey(rooms[i].id, japanese: japanese)] ?? RoomProgress()
    }

    func updateRoom(_ i: Int, _ change: (inout RoomProgress) -> Void) {
        let key = Progress.roomKey(rooms[i].id, japanese: japanese)
        var p = progress.rooms[key] ?? RoomProgress()
        change(&p)
        progress.rooms[key] = p
    }

    func isRoomLocked(_ i: Int) -> Bool { i >= Content.freeRooms && !isPro }

    // MARK: - 今日の小部屋

    var dailyDate: Date { calendar.date(byAdding: .day, value: -dailyDayOffset, to: now) ?? now }
    var todayKey: String { Progress.dayKey(now, calendar: calendar) }
    func daily(for date: Date) -> DailyPuzzle {
        let list = Content.dailies
        return list[Content.dailyIndex(for: date, calendar: calendar, count: list.count)]
    }
    var currentDaily: DailyPuzzle { daily(for: dailyDate) }
    func dailyResult(_ date: Date) -> DailyResult? {
        progress.daily[Progress.dailyKey(Progress.dayKey(date, calendar: calendar), japanese: japanese)]
    }
    var todayResult: DailyResult? { dailyResult(now) }
    var streak: Int { progress.streak(today: now, calendar: calendar) }

    // MARK: - 移動

    func press() { pressTick += 1 }

    func finishOnboarding() {
        press()
        withAnimation(.easeOut(duration: 0.35)) { onboarded = true }
        // 最初の 10 秒：そのまま第一の部屋へ
        enterRoom(0)
    }

    func enterRoom(_ i: Int) {
        press()
        if isRoomLocked(i) {
            activeSheet = .paywall
            return
        }
        play(.door)
        screen = .room(i)
        openObject = nil
        board = nil
        door = nil
        result = nil
        if !roomProgress(i).introSeen && !roomProgress(i).escaped {
            showIntro = true
        }
        elapsed = roomProgress(i).seconds
        startClock()
    }

    func closeIntro() {
        press()
        showIntro = false
        if case .room(let i) = screen { updateRoom(i) { $0.introSeen = true } }
    }

    func goHome() {
        press()
        stopClock()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) {
            screen = .home
            openObject = nil
            board = nil
            door = nil
            result = nil
            showIntro = false
        }
        if !paywallOffered && !isPro && progress.roomsEscaped >= 1 {
            // 価値を感じた直後（最初の部屋から出た）にだけ、一度だけ見せる
            paywallOffered = true
            activeSheet = .paywall
        }
    }

    // MARK: - 部屋の物

    func tapObject(_ index: Int) {
        guard case .room(let r) = screen else { return }
        let room = rooms[r]
        let rp = roomProgress(r)
        press()
        if !Inventory.canOpen(index, room: room, progress: rp) {
            lockedNotice = index
            wrongTick += 1
            play(.locked)
            let need = room.objects[index].requires?.name ?? ""
            show(Banner(title: trf("%@が要る", "Needs the %@", need), detail: room.objects[index].note, item: room.objects[index].requires))
            return
        }
        if room.objects[index].requires != nil && !rp.object(index).unlocked {
            updateRoom(r) { $0.objects[index, default: ObjectProgress()].unlocked = true }
            unlocking = index
            unlockTick += 1
            play(.unlock)
            Task {
                try? await Task.sleep(for: .milliseconds(still ? 0 : 650))
                self.unlocking = nil
                self.openBoard(index)
            }
            return
        }
        openBoard(index)
    }

    func openBoard(_ index: Int) {
        guard case .room(let r) = screen else { return }
        let op = roomProgress(r).object(index)
        let puzzle = rooms[r].objects[index].puzzle
        board = Board(puzzle: puzzle, filled: Board.cells(from: op.cells), hintsUsed: op.hintsUsed, mistakes: op.mistakes)
        lastSolvedEntry = nil
        lastWrongEntry = nil
        withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.86)) { openObject = index }
        play(.page)
    }

    func closeBoard() {
        press()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            openObject = nil
            if screen != .daily { board = nil }
        }
        if screen == .daily { goHome() }
    }

    // MARK: - 盤の操作

    func select(_ cell: Cell) {
        guard board != nil, !(boardSolved) else { return }
        board?.select(cell: cell)
        press()
    }

    func selectEntry(_ i: Int) {
        guard board != nil else { return }
        board?.select(entry: i)
        press()
    }

    var boardSolved: Bool { board?.isComplete ?? false }

    func type(_ letter: String) {
        guard var b = board else { return }
        let r = b.type(letter)
        board = b
        handle(r)
    }

    func backspace() {
        guard board != nil else { return }
        board?.backspace()
        press()
        play(.key)
        persistBoard()
    }

    /// ヒントの段階：1 文字 → 意味 → 答え（Pro。無料でも 1 回だけ試せる）
    var nextHintTier: Int {
        guard let b = board else { return 1 }
        if b.shownHints.contains(b.selected) { return 3 }
        let e = b.selectedEntry
        let opened = e.cells.enumerated().contains { i, c in b.filled[c] == e.answer[i] && !b.isLocked(c) }
        return opened ? 2 : 1
    }

    var canRevealWord: Bool { isPro || !progress.trialRevealUsed }

    func hint() {
        guard var b = board, !b.isSolved(b.selected) else { return }
        press()
        switch nextHintTier {
        case 1:
            let r = b.revealLetter()
            board = b
            play(.hint)
            handle(r, fromHint: true)
        case 2:
            b.showHint()
            board = b
            play(.hint)
            persistBoard()
        default:
            guard canRevealWord else {
                activeSheet = .paywall
                return
            }
            if !isPro { progress.trialRevealUsed = true }
            let r = b.revealWord()
            board = b
            play(.hint)
            handle(r, fromHint: true)
        }
    }

    private func handle(_ r: TypeResult, fromHint: Bool = false) {
        switch r {
        case .none:
            return
        case .placed:
            letterTick += 1
            if !fromHint { play(.key) }
        case .wrong(let e):
            lastWrongEntry = e
            wrongTick += 1
            play(.wrong)
        case .solved(let e, let item, let complete):
            lastSolvedEntry = e
            progress.wordsSolved += 1
            wordTick += 1
            play(.word)
            if item, case .room(let ri) = screen, let o = openObject {
                let it = rooms[ri].objects[o].gives
                itemTick += 1
                play(.item)
                show(Banner(title: trf("%@を手に入れた", "Got the %@", it.name), detail: tr("解いた言葉が、道具になった", "The word turned into a tool"), item: it))
            }
            if complete {
                finishBoard()
            } else {
                Task {
                    try? await Task.sleep(for: .milliseconds(still ? 0 : 380))
                    self.board?.advance()
                }
            }
        }
        persistBoard()
    }

    private func persistBoard() {
        guard let b = board else { return }
        if case .room(let r) = screen, let o = openObject {
            updateRoom(r) { p in
                var op = p.objects[o] ?? ObjectProgress()
                op.cells = b.savedCells
                op.hintsUsed = b.hintsUsed
                op.mistakes = b.mistakes
                p.objects[o] = op
            }
        } else if screen == .daily {
            let key = Progress.dailyKey(Progress.dayKey(dailyDate, calendar: calendar), japanese: japanese)
            var d = progress.daily[key] ?? DailyResult()
            d.cells = b.savedCells
            d.hintsUsed = b.hintsUsed
            d.mistakes = b.mistakes
            progress.daily[key] = d
        }
    }

    private func finishBoard() {
        guard let b = board else { return }
        completeTick += 1
        persistBoard()
        if case .room(let r) = screen, let o = openObject {
            updateRoom(r) { p in
                var op = p.objects[o] ?? ObjectProgress()
                op.solved = true
                op.unlocked = true
                op.stars = b.stars
                p.objects[o] = op
            }
            let room = rooms[r]
            let letter = room.objects[o].puzzle.markLetter ?? ""
            Task {
                try? await Task.sleep(for: .milliseconds(still ? 0 : 1300))
                self.play(.letter)
                self.show(Banner(title: trf("扉の文字「%@」が分かった", "Door letter found: %@", letter), detail: Inventory.doorReady(room: room, progress: self.roomProgress(r)) ? tr("扉を調べよう", "Check the door") : tr("ほかの物も調べよう", "Search the other objects"), letter: letter))
                withAnimation(self.reduceMotion ? nil : .easeOut(duration: 0.3)) {
                    self.openObject = nil
                    self.board = nil
                }
            }
        } else if screen == .daily {
            stopClock()
            let key = Progress.dailyKey(Progress.dayKey(dailyDate, calendar: calendar), japanese: japanese)
            var d = progress.daily[key] ?? DailyResult()
            d.solved = true
            d.stars = b.stars
            progress.daily[key] = d
            Task {
                try? await Task.sleep(for: .milliseconds(still ? 0 : 900))
                self.escapeTick += 1
                self.play(.escape)
                withAnimation(self.reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8)) { self.result = .daily }
            }
        }
    }

    // MARK: - 最後の扉

    func tapDoor() {
        guard case .room(let r) = screen else { return }
        press()
        let room = rooms[r]
        let rp = roomProgress(r)
        guard Inventory.doorReady(room: room, progress: rp) else {
            wrongTick += 1
            play(.locked)
            let found = Inventory.doorLetters(room: room, progress: rp).compactMap { $0 }.count
            show(Banner(title: tr("扉はまだ開かない", "The door won't open yet"), detail: trf("文字盤 %d / %d・道具 2 つが要る", "Dials %d / %d · needs 2 tools", found, room.final.count)))
            return
        }
        play(.unlock)
        door = DoorState(letters: room.final, seed: room.id)
    }

    func doorKey(_ index: Int) {
        guard var d = door, !d.used[index], let slot = d.slots.firstIndex(where: { $0 == nil }) else { return }
        d.slots[slot] = d.keys[index]
        d.used[index] = true
        letterTick += 1
        play(.key)
        if !d.slots.contains(where: { $0 == nil }) {
            checkDoor(&d)
        }
        door = d
    }

    func doorBackspace() {
        guard var d = door, let last = d.slots.lastIndex(where: { $0 != nil }), let letter = d.slots[last] else { return }
        d.slots[last] = nil
        if let k = d.keys.indices.first(where: { d.used[$0] && d.keys[$0] == letter }) { d.used[k] = false }
        door = d
        press()
    }

    func closeDoor() {
        press()
        door = nil
    }

    private func checkDoor(_ d: inout DoorState) {
        guard case .room(let r) = screen else { return }
        let room = rooms[r]
        if d.slots.compactMap({ $0 }) == room.final {
            escape(r)
        } else {
            d.wrong += 1
            wrongTick += 1
            play(.wrong)
            d.slots = Array(repeating: nil, count: d.slots.count)
            d.used = Array(repeating: false, count: d.used.count)
        }
    }

    private func escape(_ r: Int) {
        stopClock()
        let room = rooms[r]
        updateRoom(r) { p in
            p.escaped = true
            p.bestSeconds = min(p.bestSeconds ?? Int.max, p.seconds)
            let stars = room.objects.indices.map { p.object($0).stars }
            p.stars = max(1, Int((Double(stars.reduce(0, +)) / Double(max(1, stars.count))).rounded()))
        }
        Task {
            try? await Task.sleep(for: .milliseconds(still ? 0 : 700))
            self.escapeTick += 1
            self.play(.escape)
            withAnimation(self.reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8)) {
                self.door = nil
                self.result = .room(r)
            }
        }
    }

    /// 出た部屋をもう一度遊ぶ（記録の星と最速は残す）
    func replayRoom(_ r: Int) {
        updateRoom(r) { p in
            let best = p.bestSeconds
            let stars = p.stars
            p = RoomProgress()
            p.escaped = true
            p.bestSeconds = best
            p.stars = stars
            p.introSeen = true
        }
        enterRoom(r)
    }

    func nextRoom(after r: Int) {
        if r + 1 < rooms.count { enterRoom(r + 1) } else { goHome() }
    }

    // MARK: - 今日の小部屋

    func startDaily(dayOffset: Int = 0) {
        press()
        if dayOffset > 0 && !isPro {
            activeSheet = .paywall
            return
        }
        activeSheet = nil
        dailyDayOffset = dayOffset
        let saved = dailyResult(dailyDate)
        board = Board(puzzle: currentDaily.puzzle, filled: Board.cells(from: saved?.cells ?? [:]), hintsUsed: saved?.hintsUsed ?? 0, mistakes: saved?.mistakes ?? 0)
        lastSolvedEntry = nil
        lastWrongEntry = nil
        result = nil
        door = nil
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) {
            screen = .daily
        }
        play(.page)
        elapsed = saved?.seconds ?? 0
        if saved?.solved == true {
            result = .daily
        } else {
            startClock()
        }
    }

    // MARK: - 時計

    private func startClock() {
        clock?.cancel()
        guard !still else { return }
        clock = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }
                self.tickClock()
            }
        }
    }

    private func stopClock() {
        flushClock()
        clock?.cancel()
        clock = nil
    }

    var active = true {
        didSet { if !active { flushClock() } }
    }

    /// いまの部屋・小部屋の経過秒。毎秒は保存せず（記録全体を書き直すと重い）、離れる・解けるときに記録へ書く
    var elapsed = 0

    private func tickClock() {
        guard active, result == nil, !showIntro, screen != .home else { return }
        elapsed += 1
    }

    /// 経過秒を記録に書く
    func flushClock() {
        guard clock != nil else { return }
        switch screen {
        case .room(let r):
            let e = elapsed
            if roomProgress(r).seconds != e { updateRoom(r) { $0.seconds = e } }
        case .daily:
            let key = Progress.dailyKey(Progress.dayKey(dailyDate, calendar: calendar), japanese: japanese)
            var d = progress.daily[key] ?? DailyResult()
            if d.seconds != elapsed {
                d.seconds = elapsed
                progress.daily[key] = d
            }
        case .home:
            break
        }
    }

    // MARK: - 知らせ・音

    func show(_ b: Banner) {
        bannerTask?.cancel()
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) { banner = b }
        guard !still else { return }
        bannerTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            withAnimation(self.reduceMotion ? nil : .easeOut(duration: 0.3)) { self.banner = nil }
        }
    }

    func play(_ cue: SoundBox.Cue) {
        guard soundOn, !still else { return }
        SoundBox.shared.play(cue)
    }

    // MARK: - 通知（毎晩 21 時に今日の小部屋を知らせる。端末の中だけ）

    func setReminder(_ on: Bool) async {
        let center = UNUserNotificationCenter.current()
        guard on else {
            center.removeAllPendingNotificationRequests()
            reminderOn = false
            return
        }
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else {
            reminderOn = false
            reminderDenied = true
            return
        }
        reminderDenied = false
        let content = UNMutableNotificationContent()
        content.title = tr("今日の小部屋が開いた", "Today's nook is open")
        content.body = tr("5 分のクロスワードで、鍵をひとつ。", "One five-minute crossword, one key.")
        var when = DateComponents()
        when.hour = 21
        let request = UNNotificationRequest(identifier: "daily", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: true))
        try? await center.add(request)
        reminderOn = true
    }

    // MARK: - 記録を消す

    func resetProgress() {
        progress = Progress()
        screen = .home
    }

    func replayOnboarding() {
        activeSheet = nil
        onboarded = false
    }
}

/// 秒を「分:秒」に
func clockText(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}
