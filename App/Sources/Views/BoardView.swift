import SwiftUI

/// クロスワードの盤（羊皮紙のマス）。部屋の物と、今日の小部屋で使う
struct GridView: View {
    @Environment(AppModel.self) private var model
    let board: Board
    var maxCell: CGFloat = 54

    var body: some View {
        GeometryReader { geo in
            let p = board.puzzle
            let side = max(24, min(maxCell, geo.size.width / CGFloat(p.cols), geo.size.height / CGFloat(p.rows)))
            let cells = Set(p.allCells)
            let selected = Set(board.selectedEntry.cells)
            let cursor = board.cursor
            VStack(spacing: 0) {
                ForEach(0..<p.rows, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<p.cols, id: \.self) { c in
                            let cell = Cell(row: r, col: c)
                            if cells.contains(cell) {
                                CellView(board: board, cell: cell, side: side, inSelected: selected.contains(cell), isCursor: cursor == cell)
                            } else {
                                Color.clear.frame(width: side, height: side)
                            }
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct CellView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let board: Board
    let cell: Cell
    let side: CGFloat
    let inSelected: Bool
    let isCursor: Bool

    private var letter: String? { board.filled[cell] }
    private var locked: Bool { board.isLocked(cell) }
    private var isMark: Bool { board.puzzle.mark == cell }

    /// 解けた瞬間に弾む：その語のマスだけ、先頭から 55ms ずつ遅らせる
    private var solvedIndex: Int? {
        guard let e = model.lastSolvedEntry, board.puzzle.entries.indices.contains(e) else { return nil }
        return board.puzzle.entries[e].cells.firstIndex(of: cell)
    }

    private var wrongHere: Bool {
        guard let e = model.lastWrongEntry, board.puzzle.entries.indices.contains(e) else { return false }
        return board.puzzle.entries[e].cells.contains(cell)
    }

    var body: some View {
        let bounce = solvedIndex != nil && !reduceMotion
        let delay = Double(solvedIndex ?? 0) * 0.055
        let shake = wrongHere && !reduceMotion
        Button {
            model.select(cell)
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Radius.cell, style: .continuous)
                    .fill(fill)
                RoundedRectangle(cornerRadius: Radius.cell, style: .continuous)
                    .strokeBorder(isCursor ? Ink.brassDeep : Ink.inkSoft.opacity(0.35), lineWidth: isCursor ? 2.5 : 0.8)
                if isMark {
                    // 扉の文字が入るマス：右下に真鍮の丸
                    Circle()
                        .strokeBorder(Ink.brassDeep, lineWidth: 1.5)
                        .background(Circle().fill(Ink.brass.opacity(locked ? 0.6 : 0.25)))
                        .frame(width: side * 0.26, height: side * 0.26)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(side * 0.07)
                }
                if let n = board.puzzle.number(at: cell) {
                    Text("\(n)")
                        .font(.system(size: max(8, side * 0.2), weight: .semibold, design: .serif))
                        .foregroundStyle(Ink.inkSoft)
                        .padding(.leading, side * 0.07)
                        .padding(.top, side * 0.03)
                }
                Text(letter ?? "")
                    .font(Typo.title(side * 0.52, locked ? .bold : .medium))
                    .foregroundStyle(locked ? Ink.ink : Ink.inkSoft)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentTransition(.opacity)
            }
            .frame(width: side - 3, height: side - 3)
            .frame(width: side, height: side)
            .keyframeAnimator(initialValue: CGFloat(1), trigger: model.wordTick) { v, scale in
                v.scaleEffect(bounce ? scale : 1)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(1, duration: max(0.001, delay))
                    SpringKeyframe(1.16, duration: 0.14)
                    SpringKeyframe(1, duration: 0.3, spring: .bouncy)
                }
            }
            .keyframeAnimator(initialValue: CGFloat(0), trigger: model.wrongTick) { v, x in
                v.offset(x: shake ? x : 0)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(-7, duration: 0.05)
                    LinearKeyframe(6, duration: 0.05)
                    LinearKeyframe(-5, duration: 0.05)
                    LinearKeyframe(4, duration: 0.05)
                    LinearKeyframe(-2, duration: 0.05)
                    LinearKeyframe(1, duration: 0.05)
                    LinearKeyframe(0, duration: 0.05)
                }
            }
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(accessibility)
    }

    private var fill: Color {
        if locked { return Ink.solved }
        if isCursor { return Ink.paperShade }
        if inSelected { return Ink.paperShade.opacity(0.75) }
        return Ink.paper
    }

    private var accessibility: String {
        let content = letter ?? tr("空き", "empty")
        return trf("%d 行 %d 列、%@", "Row %d column %d, %@", cell.row + 1, cell.col + 1, content)
    }
}

/// 今のカギ（番号・向き・文・ヒント）
struct ClueBar: View {
    @Environment(AppModel.self) private var model
    let board: Board

    var body: some View {
        let e = board.selectedEntry
        HStack(spacing: 10) {
            Button { step(-1) } label: {
                Image(systemName: "chevron.left").frame(width: 36, height: 44)
            }
            .accessibilityLabel(tr("前のカギ", "Previous clue"))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(trf("%d %@", "%d %@", e.number, e.across ? tr("横", "Across") : tr("縦", "Down")))
                        .font(Typo.label(12))
                        .kerning(0.6)
                        .foregroundStyle(Ink.brassDeep)
                    Text(trf("%d 文字", "%d letters", e.answer.count))
                        .font(Typo.label(11))
                        .foregroundStyle(Ink.inkSoft)
                    if board.isSolved(board.selected) {
                        Image(systemName: "checkmark.seal.fill").font(.caption).foregroundStyle(Ink.brassDeep)
                    }
                }
                Text(e.clue)
                    .font(Typo.body(.subheadline, .medium))
                    .foregroundStyle(Ink.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if board.shownHints.contains(board.selected) {
                    Text(trf("ヒント：%@", "Hint: %@", e.hint))
                        .font(Typo.body(.caption).italic())
                        .foregroundStyle(Ink.inkSoft)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            Button { step(1) } label: {
                Image(systemName: "chevron.right").frame(width: 36, height: 44)
            }
            .accessibilityIdentifier("main.nextClue")
            .accessibilityLabel(tr("次のカギ", "Next clue"))
        }
        .foregroundStyle(Ink.brassDeep)
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .frame(minHeight: 76)
        .background(Parchment(radius: Radius.plate))
    }

    private func step(_ d: Int) {
        let n = board.puzzle.entries.count
        model.selectEntry(((board.selected + d) % n + n) % n)
    }
}

/// 文字の鍵盤（木の札）とヒント・消す
struct KeyTray: View {
    @Environment(AppModel.self) private var model
    let board: Board

    var body: some View {
        let keys = board.keys(for: board.selected, japanese: Lang.isJapanese)
        let solved = board.isSolved(board.selected)
        VStack(spacing: 8) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: keys.count > 8 ? 5 : 4)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(keys.enumerated()), id: \.offset) { i, k in
                    Button { model.type(k) } label: {
                        Text(k)
                            .font(Typo.title(22, .semibold))
                            .foregroundStyle(Ink.ink)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(KeyCap())
                    }
                    .buttonStyle(PressStyle())
                    .disabled(solved)
                    .opacity(solved ? 0.45 : 1)
                    .accessibilityIdentifier(i == 0 ? "main.key" : "key\(i)")
                }
            }
            HStack(spacing: 8) {
                Button { model.hint() } label: {
                    HStack(spacing: 6) {
                        ItemGlyph(kind: .lens, color: Ink.ink, shade: Ink.ink).frame(width: 18, height: 18)
                        Text(hintLabel).lineLimit(1).minimumScaleFactor(0.7)
                        if model.nextHintTier == 3 && !model.isPro {
                            Text(model.canRevealWord ? tr("1 回お試し", "1 free try") : "Pro")
                                .font(Typo.label(10))
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Capsule().fill(Ink.ink.opacity(0.12)))
                        }
                    }
                }
                .buttonStyle(BrassButtonStyle())
                .disabled(solved)
                .accessibilityIdentifier("main.hint")
                Button { model.backspace() } label: {
                    Image(systemName: "delete.left").font(.system(size: 18, weight: .semibold))
                }
                .buttonStyle(BrassButtonStyle(prominent: false))
                .frame(width: 84)
                .accessibilityLabel(tr("1 文字消す", "Delete a letter"))
            }
        }
    }

    private var hintLabel: String {
        switch model.nextHintTier {
        case 1: tr("ヒント：1 文字", "Hint: a letter")
        case 2: tr("ヒント：意味", "Hint: meaning")
        default: tr("ヒント：答え", "Hint: answer")
        }
    }
}

/// 木の札（下辺だけ厚い）
struct KeyCap: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.key, style: .continuous).fill(Color(hex: 0x9C7A4E)).offset(y: 3)
            RoundedRectangle(cornerRadius: Radius.key, style: .continuous).fill(Color(hex: 0xE9D6AE))
            RoundedRectangle(cornerRadius: Radius.key, style: .continuous).inset(by: 1).stroke(Color(hex: 0xF7EBCF), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

/// 盤の画面（ヘッダー・盤・カギ・鍵盤）。下の鍵盤は画面の下に固定
struct BoardPanel: View {
    @Environment(AppModel.self) private var model
    let board: Board
    let title: String
    let subtitle: String
    var closeID = "main.closeBoard"

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(subtitle).font(Typo.label(11)).kerning(0.6).foregroundStyle(Ink.brass)
                    Text(title).font(Typo.title(20)).foregroundStyle(Ink.onWall).lineLimit(1).minimumScaleFactor(0.7)
                }
                Spacer()
                Text(trf("%d / %d 語", "%d / %d words", board.solvedCount, board.puzzle.entries.count))
                    .font(Typo.title(15, .medium))
                    .monospacedDigit()
                    .foregroundStyle(Ink.brassSoft)
                    .contentTransition(.numericText())
                RoundBrassButton(systemImage: "xmark", label: tr("閉じる", "Close")) { model.closeBoard() }
                    .accessibilityIdentifier(closeID)
            }
            GridView(board: board)
                .padding(12)
                .background(Parchment())
                .paperShadow()
                .frame(maxHeight: .infinity)
            ClueBar(board: board)
        }
        .safeAreaInset(edge: .bottom) {
            KeyTray(board: board)
                .padding(.top, 8)
        }
    }
}
