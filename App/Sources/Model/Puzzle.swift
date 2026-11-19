import Foundation

/// 盤のマス（行・列）
struct Cell: Hashable, Codable, Sendable, Comparable {
    let row: Int
    let col: Int

    static func < (a: Cell, b: Cell) -> Bool { (a.row, a.col) < (b.row, b.col) }

    /// 保存用のキー "r,c"
    var key: String { "\(row),\(col)" }

    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    init?(key: String) {
        let parts = key.split(separator: ",").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        self.init(row: parts[0], col: parts[1])
    }
}

/// クロスワードの 1 語（答えは 1 マス 1 文字）
struct Entry: Hashable, Sendable {
    let number: Int
    let row: Int
    let col: Int
    let across: Bool
    let answer: [String]
    let clue: String
    let hint: String

    var cells: [Cell] {
        answer.indices.map { i in across ? Cell(row: row, col: col + i) : Cell(row: row + i, col: col) }
    }

    var word: String { answer.joined() }
}

struct Crossword: Sendable {
    let rows: Int
    let cols: Int
    let entries: [Entry]
    /// 解くと道具になる語（entries の添字）
    let itemEntry: Int?
    /// 最後の扉の文字が入るマス
    let mark: Cell?

    /// 正しい文字（マス → 文字）
    var solution: [Cell: String] {
        var out: [Cell: String] = [:]
        for e in entries {
            for (i, c) in e.cells.enumerated() { out[c] = e.answer[i] }
        }
        return out
    }

    var allCells: [Cell] { solution.keys.sorted() }

    /// そのマスを通る語（横を先に）
    func entries(at cell: Cell) -> [Int] {
        entries.indices.filter { entries[$0].cells.contains(cell) }.sorted { entries[$0].across && !entries[$1].across }
    }

    /// マスの左上に出す番号
    func number(at cell: Cell) -> Int? {
        entries.first { $0.row == cell.row && $0.col == cell.col }?.number
    }

    var markLetter: String? { mark.flatMap { solution[$0] } }
}

/// 部屋の物（絵は自作の Shape で描く）
enum ObjectKind: String, Codable, Sendable, CaseIterable {
    case painting, chest, bookshelf, desk, gramophone, safe, fireplace, clock, telescope, globe
}

/// 解いた言葉から手に入る道具
enum ItemKind: String, Codable, Sendable, CaseIterable {
    case key, candle, gear, lens, ring, coin, map, compass

    var name: String {
        switch self {
        case .key: tr("鍵", "Key")
        case .candle: tr("ろうそく", "Candle")
        case .gear: tr("歯車", "Gear")
        case .lens: tr("虫めがね", "Lens")
        case .ring: tr("指輪", "Ring")
        case .coin: tr("コイン", "Coin")
        case .map: tr("星の地図", "Star map")
        case .compass: tr("羅針盤", "Compass")
        }
    }
}

struct RoomObject: Sendable {
    let kind: ObjectKind
    let name: String
    let note: String
    let requires: ItemKind?
    let gives: ItemKind
    let puzzle: Crossword
}

struct Room: Sendable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let intro: String
    let outro: String
    /// 扉の言葉（物の順に 1 文字ずつ）
    let final: [String]
    let finalClue: String
    let objects: [RoomObject]

    /// 扉に要る道具：2 番目と 4 番目の物から出る道具
    var doorItems: [ItemKind] { [objects[1].gives, objects[3].gives] }
}

struct DailyPuzzle: Sendable {
    let title: String
    let kind: ObjectKind
    let puzzle: Crossword
}

/// 言語ごとの中身
enum Content {
    static var rooms: [Room] { Lang.isJapanese ? PuzzleData.japaneseRooms : PuzzleData.englishRooms }
    static var dailies: [DailyPuzzle] { Lang.isJapanese ? PuzzleData.japaneseDaily : PuzzleData.englishDaily }

    /// 無料で入れる部屋の数（残りは Pro）
    static let freeRooms = 2

    /// その日の小部屋（日付から決まる。全員同じ）
    static func dailyIndex(for date: Date, calendar: Calendar, count: Int) -> Int {
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return ((day % count) + count) % count
    }
}
