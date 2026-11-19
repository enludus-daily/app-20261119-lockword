import Foundation
import Testing
@testable import Lockword

/// 小さな見本の盤：KEY（横）と EAR（縦、E で交わる）
private let sample = Crossword(rows: 3, cols: 3, entries: [
    Entry(number: 1, row: 0, col: 0, across: true, answer: ["K", "E", "Y"], clue: "Opens a lock", hint: "Turn it"),
    Entry(number: 2, row: 0, col: 1, across: false, answer: ["E", "A", "R"], clue: "You hear with it", hint: "Lend me your ___"),
], itemEntry: 0, mark: Cell(row: 2, col: 1))

struct BoardTests {
    @Test func typingTheRightLettersSolvesTheWordAndGivesTheItem() {
        var b = Board(puzzle: sample)
        b.select(entry: 0)
        #expect(b.type("K") == .placed(Cell(row: 0, col: 0)))
        #expect(b.type("E") == .placed(Cell(row: 0, col: 1)))
        #expect(b.type("Y") == .solved(entry: 0, item: true, complete: false))
        #expect(b.isLocked(Cell(row: 0, col: 1)))
    }

    @Test func aCrossingLetterIsSkippedOnceLocked() {
        var b = Board(puzzle: sample)
        b.select(entry: 0)
        for l in ["K", "E", "Y"] { _ = b.type(l) }
        b.select(entry: 1)
        // E は解けた語のマスなので、次は A のマスに入る
        #expect(b.cursor == Cell(row: 1, col: 1))
        _ = b.type("A")
        #expect(b.type("R") == .solved(entry: 1, item: false, complete: true))
        #expect(b.isComplete)
    }

    @Test func aWrongWordShakesAndClearsOnlyUnlockedSquares() {
        var b = Board(puzzle: sample)
        b.select(entry: 0)
        for l in ["K", "E", "Y"] { _ = b.type(l) }
        b.select(entry: 1)
        _ = b.type("X")
        #expect(b.type("Z") == .wrong(entry: 1))
        #expect(b.filled[Cell(row: 0, col: 1)] == "E")
        #expect(b.filled[Cell(row: 1, col: 1)] == nil)
        #expect(b.mistakes == 1)
    }

    @Test func backspaceRemovesTheLastUnlockedLetter() {
        var b = Board(puzzle: sample)
        b.select(entry: 0)
        _ = b.type("K")
        _ = b.type("E")
        b.backspace()
        #expect(b.filled[Cell(row: 0, col: 1)] == nil)
        #expect(b.filled[Cell(row: 0, col: 0)] == "K")
    }

    @Test func hintsGoLetterThenMeaningThenAnswer() {
        var b = Board(puzzle: sample)
        b.select(entry: 1)
        _ = b.revealLetter()
        #expect(b.filled[Cell(row: 0, col: 1)] == "E")
        b.showHint()
        #expect(b.shownHints.contains(1))
        #expect(b.revealWord() == .solved(entry: 1, item: false, complete: false))
        #expect(b.hintsUsed == 4)
        #expect(b.stars == 1)
    }

    @Test func starsDropWithHints() {
        var b = Board(puzzle: sample)
        #expect(b.stars == 3)
        b.showHint()
        #expect(b.stars == 2)
    }

    @Test func tappingTheCrossingSquareTwiceSwitchesDirection() {
        var b = Board(puzzle: sample)
        b.select(entry: 0)
        b.select(cell: Cell(row: 0, col: 1))
        #expect(b.selected == 1)
        b.select(cell: Cell(row: 0, col: 1))
        #expect(b.selected == 0)
    }

    @Test func keysContainEveryLetterOfTheAnswerAndStayTheSame() {
        let keys = Board.keys(for: sample.entries[0], japanese: false)
        #expect(Set(["K", "E", "Y"]).isSubset(of: Set(keys)))
        #expect(keys.count == 8)
        #expect(keys == Board.keys(for: sample.entries[0], japanese: false))
    }

    @Test func savedCellsRoundTrip() {
        var b = Board(puzzle: sample)
        _ = b.type("K")
        let restored = Board(puzzle: sample, filled: Board.cells(from: b.savedCells))
        #expect(restored.filled == b.filled)
    }
}

struct PuzzleDataTests {
    static let all: [(String, [Room], [DailyPuzzle])] = [
        ("ja", PuzzleData.japaneseRooms, PuzzleData.japaneseDaily),
        ("en", PuzzleData.englishRooms, PuzzleData.englishDaily),
    ]

    private func check(_ p: Crossword) {
        #expect(p.rows <= 8 && p.cols <= 8)
        var seen: [Cell: String] = [:]
        for e in p.entries {
            for (i, c) in e.cells.enumerated() {
                #expect(c.row < p.rows && c.col < p.cols)
                if let have = seen[c] { #expect(have == e.answer[i]) }
                seen[c] = e.answer[i]
            }
        }
        // 全部の語がつながっている
        var reached: Set<Int> = [0]
        var changed = true
        while changed {
            changed = false
            for i in p.entries.indices where !reached.contains(i) {
                if reached.contains(where: { !Set(p.entries[$0].cells).isDisjoint(with: p.entries[i].cells) }) {
                    reached.insert(i)
                    changed = true
                }
            }
        }
        #expect(reached.count == p.entries.count)
    }

    @Test func everyRoomPuzzleIsConsistentAndOpensTheDoor() {
        for (_, rooms, _) in Self.all {
            #expect(rooms.count == 4)
            for room in rooms {
                #expect(room.objects.count == 4)
                for (i, o) in room.objects.enumerated() {
                    check(o.puzzle)
                    #expect(o.puzzle.markLetter == room.final[i])
                    #expect(o.puzzle.itemEntry != nil)
                }
                // 道具のつながり：1 番目 → 2 番目、3 番目 → 4 番目
                #expect(room.objects[1].requires == room.objects[0].gives)
                #expect(room.objects[3].requires == room.objects[2].gives)
                #expect(room.objects[0].requires == nil && room.objects[2].requires == nil)
            }
        }
    }

    @Test func thereAreAtLeastTenDailyNooksPerLanguage() {
        for (_, _, daily) in Self.all {
            #expect(daily.count >= 10)
            for d in daily { check(d.puzzle) }
        }
    }

    @Test func englishAndJapaneseAreDifferentPuzzles() {
        let ja = Set(PuzzleData.japaneseRooms.flatMap { $0.objects.flatMap { $0.puzzle.entries.map(\.word) } })
        let en = Set(PuzzleData.englishRooms.flatMap { $0.objects.flatMap { $0.puzzle.entries.map(\.word) } })
        #expect(ja.isDisjoint(with: en))
        #expect(en.allSatisfy { $0.allSatisfy { $0.isASCII && $0.isUppercase } })
    }

    @Test func dailyIndexIsStablePerDayAndCycles() {
        let cal = Calendar(identifier: .gregorian)
        let d = Date(timeIntervalSince1970: 1_800_000_000)
        let a = Content.dailyIndex(for: d, calendar: cal, count: 10)
        #expect(a == Content.dailyIndex(for: d, calendar: cal, count: 10))
        let next = Content.dailyIndex(for: d.addingTimeInterval(86_400), calendar: cal, count: 10)
        #expect(next == (a + 1) % 10)
    }
}

struct ProgressTests {
    let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }()

    func date(_ day: Int) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 11, day: day, hour: 12))!
    }

    @Test func streakCountsBackFromTodayOrYesterday() {
        var p = Progress()
        for d in [16, 17, 18] {
            p.daily[Progress.dailyKey(Progress.dayKey(date(d), calendar: cal), japanese: true)] = DailyResult(solved: true)
        }
        #expect(p.streak(today: date(18), calendar: cal) == 3)
        // 今日がまだでも、昨日まで続いていれば数える
        #expect(p.streak(today: date(19), calendar: cal) == 3)
        #expect(p.streak(today: date(21), calendar: cal) == 0)
    }

    @Test func eitherLanguageCountsForTheStreak() {
        var p = Progress()
        p.daily[Progress.dailyKey(Progress.dayKey(date(18), calendar: cal), japanese: true)] = DailyResult(solved: true)
        p.daily[Progress.dailyKey(Progress.dayKey(date(19), calendar: cal), japanese: false)] = DailyResult(solved: true)
        #expect(p.streak(today: date(19), calendar: cal) == 2)
    }

    @Test func objectsOpenOnlyWithTheirTool() {
        let room = PuzzleData.englishRooms[0]
        var rp = RoomProgress()
        #expect(Inventory.canOpen(0, room: room, progress: rp))
        #expect(!Inventory.canOpen(1, room: room, progress: rp))
        rp.objects[0] = ObjectProgress(solved: true)
        #expect(Inventory.items(room: room, progress: rp) == [room.objects[0].gives])
        #expect(Inventory.canOpen(1, room: room, progress: rp))
        #expect(!Inventory.doorReady(room: room, progress: rp))
        for i in 0..<4 { rp.objects[i] = ObjectProgress(solved: true) }
        #expect(Inventory.doorReady(room: room, progress: rp))
        #expect(Inventory.doorLetters(room: room, progress: rp).compactMap { $0 } == room.final)
    }

    @Test func doorKeysAreShuffledButHoldTheSameLetters() {
        let d = DoorState(letters: ["L", "O", "R", "E"], seed: "study")
        #expect(d.keys.sorted() == ["E", "L", "O", "R"])
        #expect(d.keys != ["L", "O", "R", "E"])
        #expect(d.slots.allSatisfy { $0 == nil })
    }

    @Test func progressSurvivesEncoding() throws {
        var p = Progress()
        var r = RoomProgress()
        r.objects[2] = ObjectProgress(cells: ["0,1": "A"], solved: true, unlocked: true, hintsUsed: 1, mistakes: 0, stars: 2)
        p.rooms["en:study"] = r
        let data = try JSONEncoder().encode(p)
        #expect(try JSONDecoder().decode(Progress.self, from: data) == p)
    }
}
