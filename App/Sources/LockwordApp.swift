import SwiftUI

@main
struct LockwordApp: App {
    /// アプリ全体で 1 つだけ（App の init は何度も呼ばれることがあるので、ここで作り直さない）
    private let model = Launch.shared

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
    }
}

struct RootView: View {
    let model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var model = model
        ZStack {
            Ink.wall.ignoresSafeArea()
            if !model.onboarded {
                OnboardingView()
                    .transition(.opacity)
            } else {
                switch model.screen {
                case .home:
                    HomeView()
                        .transition(.opacity)
                case .room(let i):
                    RoomView(index: i)
                        .id("room\(i)")
                        .transition(.opacity)
                case .daily:
                    DailyView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            if let b = model.banner {
                VStack {
                    BannerView(banner: b)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .allowsHitTesting(false)
                .zIndex(10)
                .id(b.id)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: model.screen)
        .environment(model)
        // 夜の屋敷が世界。暗い木の壁なので、画面はダークに固定する
        .preferredColorScheme(.dark)
        .sheet(item: $model.activeSheet) { sheet in
            SheetContent(sheet: sheet).environment(model).environment(\.locale, Lang.locale).preferredColorScheme(.dark)
        }
        // 手応えの表（README）：押す・1 文字・語が解けた・道具・違う・錠が外れる・盤が全部解けた・脱出
        .sensoryFeedback(trigger: model.pressTick) { _, _ in model.hapticsOn ? .selection : nil }
        .sensoryFeedback(trigger: model.letterTick) { _, _ in model.hapticsOn ? .impact(weight: .light, intensity: 0.6) : nil }
        .sensoryFeedback(trigger: model.wordTick) { _, _ in model.hapticsOn ? .impact(weight: .medium) : nil }
        .sensoryFeedback(trigger: model.itemTick) { _, _ in model.hapticsOn ? .impact(weight: .heavy) : nil }
        .sensoryFeedback(trigger: model.wrongTick) { _, _ in model.hapticsOn ? .error : nil }
        .sensoryFeedback(trigger: model.unlockTick) { _, _ in model.hapticsOn ? .impact(flexibility: .rigid) : nil }
        .sensoryFeedback(trigger: model.completeTick) { _, _ in model.hapticsOn ? .success : nil }
        .sensoryFeedback(trigger: model.escapeTick) { _, _ in model.hapticsOn ? .success : nil }
        .task { await Launch.run(model) }
        .task { await model.purchases.load() }
        .onAppear { model.reduceMotion = reduceMotion }
        .onChange(of: reduceMotion) { _, v in model.reduceMotion = v }
        .onChange(of: scenePhase) { _, phase in
            model.active = phase == .active
            if phase == .active && !model.still { model.now = Date() }
        }
        .environment(\.locale, Lang.locale)
    }
}

struct SheetContent: View {
    let sheet: ActiveSheet
    var body: some View {
        switch sheet {
        case .settings: SettingsView()
        case .paywall: PaywallView()
        case .records: RecordsView()
        case .share: ShareSheet()
        }
    }
}

/// 見本の記録（撮影・デモ・UI テスト）
enum Samples {
    /// 部屋の物の盤を、決まった語まで解いた状態にする
    static func cells(_ puzzle: Crossword, entries: Int) -> [String: String] {
        var out: [String: String] = [:]
        for e in puzzle.entries.prefix(entries) {
            for (i, c) in e.cells.enumerated() { out[c.key] = e.answer[i] }
        }
        return out
    }

    /// その語の、まだ空いているマスに入る文字（順に打てば解ける）
    static func remaining(_ board: Board, entry: Int) -> [String] {
        let e = board.puzzle.entries[entry]
        return e.cells.indices.filter { board.filled[e.cells[$0]] == nil }.map { e.answer[$0] }
    }

    static func progress(now: Date, calendar: Calendar, model: AppModel) -> Progress {
        var p = Progress()
        let japanese = Lang.isJapanese
        let rooms = Content.rooms
        // 第一の部屋：肖像画と本棚が解け、長持ちは鍵で開いて途中
        var r0 = RoomProgress()
        r0.introSeen = true
        r0.seconds = 312
        for i in [0, 2] {
            let pz = rooms[0].objects[i].puzzle
            r0.objects[i] = ObjectProgress(cells: cells(pz, entries: pz.entries.count), solved: true, unlocked: true, hintsUsed: i == 2 ? 1 : 0, mistakes: 0, stars: i == 2 ? 2 : 3)
        }
        r0.objects[1] = ObjectProgress(cells: cells(rooms[0].objects[1].puzzle, entries: 1), solved: false, unlocked: true)
        p.rooms[Progress.roomKey(rooms[0].id, japanese: japanese)] = r0
        // きのうまで 5 日、今日の小部屋から出た
        let list = Content.dailies
        for k in 1...5 {
            let date = calendar.date(byAdding: .day, value: -k, to: now) ?? now
            let dz = list[Content.dailyIndex(for: date, calendar: calendar, count: list.count)].puzzle
            p.daily[Progress.dailyKey(Progress.dayKey(date, calendar: calendar), japanese: japanese)] = DailyResult(cells: cells(dz, entries: dz.entries.count), solved: true, seconds: 180 + k * 37, hintsUsed: k % 3 == 0 ? 1 : 0, mistakes: 0, stars: k % 3 == 0 ? 2 : 3)
        }
        p.wordsSolved = 47
        p.tutorialDone = true
        return p
    }
}

/// 起動の仕方：ふつう・撮影（-screenshotScene <名前>）・デモ（-demo）・UI テスト（-uiTestFresh）。
/// 撮影とデモは見本のデータで動かし、保存されたデータを書き換えない
@MainActor
enum Launch {
    /// 撮る画面の名前。後ろに _ja を付けると日本語で撮る（CI のシミュレータは英語のため）
    static var scene: String? {
        var value = UserDefaults.standard.string(forKey: "screenshotScene") ?? ""
        if value.hasSuffix("_ja") { value = String(value.dropLast(3)) }
        return value.isEmpty || value == "launch" ? nil : value
    }

    static var forcesJapanese: Bool {
        UserDefaults.standard.string(forKey: "screenshotScene")?.hasSuffix("_ja") ?? false
    }

    static var isDemo: Bool { ProcessInfo.processInfo.arguments.contains("-demo") }
    static var isFreshUITest: Bool { ProcessInfo.processInfo.arguments.contains("-uiTestFresh") }

    static let shared: AppModel = makeModel()

    /// 撮影の日（決まった日にして、連続日数などが毎回同じになるように）
    static func stageDate() -> Date {
        var c = DateComponents()
        c.year = 2026
        c.month = 11
        c.day = 19
        c.hour = 21
        c.minute = 40
        return Calendar.current.date(from: c) ?? Date()
    }

    static func makeModel() -> AppModel {
        Lang.forcedJapanese = forcesJapanese
        if isFreshUITest {
            for key in ["progress", "onboarded", "sound", "haptics", "reminder", "paywallOffered"] {
                UserDefaults.standard.removeObject(forKey: key)
            }
            let model = AppModel()
            model.soundOn = false
            return model
        }
        guard isDemo || scene != nil else { return AppModel() }
        let now = stageDate()
        let model = AppModel(persists: false, now: now)
        model.still = scene != nil
        model.onboarded = scene != "onboarding"
        if scene != "fresh" && scene != "onboarding" && !isDemo {
            model.progress = Samples.progress(now: now, calendar: model.calendar, model: model)
        }
        return model
    }

    static func run(_ model: AppModel) async {
        if isDemo {
            await Demo.play(model)
            return
        }
        guard let scene else { return }
        try? await Task.sleep(for: .milliseconds(200))
        switch scene {
        case "room":
            model.enterRoom(0)
            model.showIntro = false
        case "intro":
            model.updateRoom(1) { $0.introSeen = false }
            model.enterRoom(1)
        case "board":
            model.enterRoom(0)
            model.showIntro = false
            model.openBoard(1)
        case "hint":
            model.enterRoom(0)
            model.showIntro = false
            model.openBoard(1)
            model.board?.advance()
            model.board?.showHint()
            _ = model.board?.revealLetter()
        case "item":
            model.enterRoom(0)
            model.showIntro = false
            model.openBoard(3)
            if let b = model.board {
                let e = b.puzzle.itemEntry ?? 0
                model.board?.select(entry: e)
                let letters = Samples.remaining(model.board ?? b, entry: e)
                for l in letters.dropLast() { _ = model.board?.type(l) }
                if let last = letters.last { model.type(last) }
            }
        case "locked":
            model.enterRoom(0)
            model.showIntro = false
            model.tapObject(3)
        case "door":
            solveRoom(model, 0)
            model.enterRoom(0)
            model.showIntro = false
            model.tapDoor()
            if let first = model.rooms[0].final.first, let k = model.door?.keys.firstIndex(of: first) { model.doorKey(k) }
        case "result":
            solveRoom(model, 0)
            model.updateRoom(0) { $0.escaped = true; $0.bestSeconds = 641; $0.seconds = 641; $0.stars = 3 }
            model.enterRoom(0)
            model.showIntro = false
            model.result = .room(0)
        case "daily":
            model.startDaily()
            if let b = model.board {
                model.board?.select(entry: 0)
                for l in Samples.remaining(b, entry: 0) { _ = model.board?.type(l) }
                model.board?.select(entry: 1)
                if let nb = model.board, let l = Samples.remaining(nb, entry: 1).first { _ = model.board?.type(l) }
            }
        case "dailyDone":
            let key = Progress.dailyKey(model.todayKey, japanese: Lang.isJapanese)
            let dz = model.daily(for: model.now).puzzle
            model.progress.daily[key] = DailyResult(cells: Samples.cells(dz, entries: dz.entries.count), solved: true, seconds: 214, hintsUsed: 0, mistakes: 1, stars: 3)
            model.startDaily()
        case "homeDone":
            let key = Progress.dailyKey(model.todayKey, japanese: Lang.isJapanese)
            model.progress.daily[key] = DailyResult(solved: true, seconds: 214, stars: 3)
        case "pro":
            model.proOverride = true
            model.enterRoom(2)
        case "settings": model.activeSheet = .settings
        case "paywall": model.activeSheet = .paywall
        case "records": model.activeSheet = .records
        case "share":
            solveRoom(model, 0)
            model.updateRoom(0) { $0.escaped = true; $0.bestSeconds = 641; $0.seconds = 641; $0.stars = 3 }
            model.result = .room(0)
            model.activeSheet = .share
        default: break
        }
    }

    static func solveRoom(_ model: AppModel, _ r: Int) {
        let room = model.rooms[r]
        model.updateRoom(r) { p in
            p.introSeen = true
            p.seconds = 598
            for i in room.objects.indices {
                let pz = room.objects[i].puzzle
                p.objects[i] = ObjectProgress(cells: Samples.cells(pz, entries: pz.entries.count), solved: true, unlocked: true, hintsUsed: 0, mistakes: 0, stars: 3)
            }
        }
    }
}

/// デモの再生（YouTube の録画用。人の操作なしで約 18 秒）
/// 広間 → 第一の部屋 → 肖像画のクロスワードを解く → 「鍵」が道具になる → 長持ちの錠が外れる
@MainActor
enum Demo {
    static func play(_ model: AppModel) async {
        func wait(_ seconds: Double) async { try? await Task.sleep(for: .milliseconds(Int(seconds * 1000))) }
        await wait(1.8)
        model.enterRoom(0)
        await wait(2.2)
        model.closeIntro()
        await wait(1.0)
        model.tapObject(0)
        await wait(1.2)
        guard let puzzle = model.board?.puzzle else { return }
        // 道具の語を最後に解く
        let order = puzzle.entries.indices.filter { $0 != puzzle.itemEntry } + [puzzle.itemEntry ?? 0]
        for e in order {
            guard model.board != nil else { return }
            model.selectEntry(e)
            await wait(0.35)
            guard let b = model.board else { return }
            for l in Samples.remaining(b, entry: e) {
                guard let nb = model.board, !nb.isSolved(e) else { break }
                model.type(l)
                await wait(0.28)
            }
            await wait(0.5)
        }
        await wait(2.2)
        model.tapObject(1)
    }
}
