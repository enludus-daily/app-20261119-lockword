import Foundation

/// 毎回同じ並びになる乱数（鍵盤の並び・紙吹雪。撮影とテストが安定する）
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// 文字列から決まる種（hashValue は起動ごとに変わるので使わない）
    static func seed(_ text: String) -> UInt64 {
        var h: UInt64 = 0xCBF2_9CE4_8422_2325
        for b in text.utf8 {
            h ^= UInt64(b)
            h = h &* 0x0000_0100_0000_01B3
        }
        return h
    }
}

/// 文字を入れた結果（画面の手応えを決める）
enum TypeResult: Equatable {
    /// 何も起きない（入れる所がない）
    case none
    /// 1 マス入った
    case placed(Cell)
    /// 語が解けた（item: 道具の語か、complete: 盤が全部解けたか）
    case solved(entry: Int, item: Bool, complete: Bool)
    /// 埋まったが違った（その語の、解けていないマスを消した）
    case wrong(entry: Int)
}

/// 1 つの盤を解いている状態。画面から切り離してテストする
struct Board: Equatable {
    static func == (a: Board, b: Board) -> Bool {
        a.filled == b.filled && a.selected == b.selected && a.hintsUsed == b.hintsUsed && a.mistakes == b.mistakes && a.shownHints == b.shownHints
    }

    let puzzle: Crossword
    private let solution: [Cell: String]
    private(set) var filled: [Cell: String]
    private(set) var selected: Int
    private(set) var hintsUsed = 0
    private(set) var mistakes = 0
    /// 意味のヒントを見せた語
    private(set) var shownHints: Set<Int> = []

    init(puzzle: Crossword, filled: [Cell: String] = [:], hintsUsed: Int = 0, mistakes: Int = 0) {
        self.puzzle = puzzle
        self.solution = puzzle.solution
        self.filled = filled.filter { puzzle.solution[$0.key] != nil }
        self.hintsUsed = hintsUsed
        self.mistakes = mistakes
        self.selected = 0
        self.selected = firstUnsolved(after: -1) ?? 0
    }

    // MARK: - 状態

    func isSolved(_ entry: Int) -> Bool {
        let e = puzzle.entries[entry]
        return e.cells.enumerated().allSatisfy { i, c in filled[c] == e.answer[i] }
    }

    var solvedEntries: Set<Int> { Set(puzzle.entries.indices.filter(isSolved)) }

    var isComplete: Bool { puzzle.entries.indices.allSatisfy(isSolved) }

    /// 解けた語のマスは動かせない
    func isLocked(_ cell: Cell) -> Bool {
        puzzle.entries.indices.contains { isSolved($0) && puzzle.entries[$0].cells.contains(cell) }
    }

    var selectedEntry: Entry { puzzle.entries[selected] }

    /// 次に文字が入るマス
    var cursor: Cell? {
        selectedEntry.cells.first { filled[$0] == nil && !isLocked($0) }
    }

    /// 星：ヒントなし・間違い 1 回までで 3、ヒント 1 回までで 2、ほかは 1
    var stars: Int {
        if hintsUsed == 0 && mistakes <= 1 { return 3 }
        if hintsUsed <= 1 { return 2 }
        return 1
    }

    var solvedCount: Int { solvedEntries.count }

    // MARK: - 操作

    mutating func select(entry: Int) {
        guard puzzle.entries.indices.contains(entry) else { return }
        selected = entry
    }

    /// マスを押す：同じ語の中なら交わる語へ切り替え、違う語なら今の向きを優先して選ぶ
    mutating func select(cell: Cell) {
        let here = puzzle.entries(at: cell)
        guard !here.isEmpty else { return }
        if here.contains(selected) {
            if here.count > 1, let other = here.first(where: { $0 != selected }) { selected = other }
            return
        }
        let sameDirection = here.first { puzzle.entries[$0].across == selectedEntry.across }
        selected = sameDirection ?? here[0]
    }

    mutating func type(_ letter: String) -> TypeResult {
        guard !isSolved(selected), let cell = cursor else { return .none }
        filled[cell] = letter
        return settle(after: cell)
    }

    mutating func backspace() {
        let cells = selectedEntry.cells
        if let last = cells.last(where: { filled[$0] != nil && !isLocked($0) }) {
            filled[last] = nil
        }
    }

    /// ヒント 1：1 文字あける（空いているか違うマス）
    mutating func revealLetter() -> TypeResult {
        guard !isSolved(selected) else { return .none }
        let e = selectedEntry
        guard let i = e.cells.indices.first(where: { filled[e.cells[$0]] != e.answer[$0] }) else { return .none }
        filled[e.cells[i]] = e.answer[i]
        hintsUsed += 1
        return settle(after: e.cells[i])
    }

    /// ヒント 2：意味を見せる
    mutating func showHint() {
        guard !shownHints.contains(selected) else { return }
        shownHints.insert(selected)
        hintsUsed += 1
    }

    /// ヒント 3：答えを見せる（Pro）
    mutating func revealWord() -> TypeResult {
        guard !isSolved(selected) else { return .none }
        let e = selectedEntry
        for (i, c) in e.cells.enumerated() { filled[c] = e.answer[i] }
        hintsUsed += 2
        return settle(after: e.cells.last ?? Cell(row: 0, col: 0))
    }

    /// 次の解けていない語へ（なければ今のまま）
    mutating func advance() {
        if let next = firstUnsolved(after: selected) { selected = next }
    }

    func firstUnsolved(after index: Int) -> Int? {
        let n = puzzle.entries.count
        guard n > 0 else { return nil }
        for step in 1...n {
            let i = ((index + step) % n + n) % n
            if !isSolved(i) { return i }
        }
        return nil
    }

    /// 入れたあとに、解けたか・違ったかを決める
    private mutating func settle(after cell: Cell) -> TypeResult {
        let before = selected
        // 交わる語が、この 1 文字で解けたかも見る
        let touched = puzzle.entries(at: cell)
        let e = selectedEntry
        let full = e.cells.allSatisfy { filled[$0] != nil }
        if isSolved(before) {
            return .solved(entry: before, item: before == puzzle.itemEntry, complete: isComplete)
        }
        if let other = touched.first(where: { $0 != before && isSolved($0) && !wasSolved($0, without: cell) }) {
            return .solved(entry: other, item: other == puzzle.itemEntry, complete: isComplete)
        }
        if full {
            for c in e.cells where !isLocked(c) { filled[c] = nil }
            mistakes += 1
            return .wrong(entry: before)
        }
        return .placed(cell)
    }

    /// cell を入れる前から解けていたか（交わる語の「いま解けた」を見分ける）
    private func wasSolved(_ entry: Int, without cell: Cell) -> Bool {
        var copy = filled
        copy[cell] = nil
        let e = puzzle.entries[entry]
        return e.cells.enumerated().allSatisfy { i, c in copy[c] == e.answer[i] }
    }

    // MARK: - 鍵盤

    /// その語の文字と、まぎらわしい文字を混ぜた鍵盤（毎回同じ並び）
    func keys(for entry: Int, japanese: Bool) -> [String] {
        Board.keys(for: puzzle.entries[entry], japanese: japanese)
    }

    static let japanesePool = Array("アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワンガギグゲゴザジズゼゾダデドバビブベボパピプペポー").map(String.init)
    static let englishPool = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init)

    static func keys(for entry: Entry, japanese: Bool) -> [String] {
        var letters: [String] = []
        for l in entry.answer where !letters.contains(l) { letters.append(l) }
        let total = min(10, max(8, letters.count + 3))
        var rng = SeededRandom(seed: SeededRandom.seed(entry.word + entry.clue))
        var pool = (japanese ? japanesePool : englishPool).filter { !letters.contains($0) }
        pool.shuffle(using: &rng)
        letters += pool.prefix(total - letters.count)
        letters.shuffle(using: &rng)
        return letters
    }

    // MARK: - 保存

    var savedCells: [String: String] {
        Dictionary(uniqueKeysWithValues: filled.map { ($0.key.key, $0.value) })
    }

    static func cells(from saved: [String: String]) -> [Cell: String] {
        var out: [Cell: String] = [:]
        for (k, v) in saved { if let c = Cell(key: k) { out[c] = v } }
        return out
    }
}
