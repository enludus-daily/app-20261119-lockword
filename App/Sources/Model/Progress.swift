import Foundation

/// 1 つの物（盤）の進み具合
struct ObjectProgress: Codable, Equatable, Sendable {
    var cells: [String: String] = [:]
    var solved = false
    var unlocked = false
    var hintsUsed = 0
    var mistakes = 0
    var stars = 0
}

/// 1 つの部屋の進み具合
struct RoomProgress: Codable, Equatable, Sendable {
    var objects: [Int: ObjectProgress] = [:]
    var escaped = false
    var seconds = 0
    var bestSeconds: Int?
    var stars = 0
    var introSeen = false

    func object(_ i: Int) -> ObjectProgress { objects[i] ?? ObjectProgress() }

    var solvedCount: Int { objects.values.filter(\.solved).count }
}

/// 今日の小部屋の結果
struct DailyResult: Codable, Equatable, Sendable {
    var cells: [String: String] = [:]
    var solved = false
    var seconds = 0
    var hintsUsed = 0
    var mistakes = 0
    var stars = 0
}

/// 端末の中だけに保存する記録（UserDefaults・JSON）
struct Progress: Codable, Equatable, Sendable {
    /// 言語ごとに部屋が違うので、キーは「言語:部屋」
    var rooms: [String: RoomProgress] = [:]
    /// キーは「言語:yyyy-MM-dd」
    var daily: [String: DailyResult] = [:]
    var wordsSolved = 0
    var trialRevealUsed = false
    var tutorialDone = false

    static func roomKey(_ id: String, japanese: Bool) -> String { (japanese ? "ja:" : "en:") + id }
    static func dailyKey(_ day: String, japanese: Bool) -> String { (japanese ? "ja:" : "en:") + day }

    static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// 解けた日（言語は問わない）
    var solvedDays: Set<String> {
        Set(daily.filter(\.value.solved).keys.compactMap { $0.split(separator: ":").last.map(String.init) })
    }

    /// 続けて解いた日数（今日か昨日まで続いていれば数える）
    func streak(today: Date, calendar: Calendar) -> Int {
        let days = solvedDays
        var date = today
        if !days.contains(Progress.dayKey(date, calendar: calendar)) {
            guard let y = calendar.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = y
        }
        var count = 0
        while days.contains(Progress.dayKey(date, calendar: calendar)) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return count
    }

    var roomsEscaped: Int { rooms.values.filter(\.escaped).count }
}

/// 道具の持ち物：解いた物から出た道具（扉や錠に使っても残す。使ったかは unlocked で分かる）
enum Inventory {
    static func items(room: Room, progress: RoomProgress) -> [ItemKind] {
        room.objects.indices.compactMap { i in progress.object(i).solved ? room.objects[i].gives : nil }
    }

    /// 物が開けられるか（道具が要らない、または持っている）
    static func canOpen(_ index: Int, room: Room, progress: RoomProgress) -> Bool {
        guard let need = room.objects[index].requires else { return true }
        return progress.object(index).unlocked || items(room: room, progress: progress).contains(need)
    }

    /// 扉の文字（解けた物の印の文字。解けていない所は nil）
    static func doorLetters(room: Room, progress: RoomProgress) -> [String?] {
        room.objects.indices.map { i in progress.object(i).solved ? room.objects[i].puzzle.markLetter : nil }
    }

    static func doorReady(room: Room, progress: RoomProgress) -> Bool {
        room.objects.indices.allSatisfy { progress.object($0).solved }
    }
}
