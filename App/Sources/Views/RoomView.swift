import SwiftUI

/// 部屋：壁の物を調べ、クロスワードを解いて道具を集め、扉を開ける。
/// 広い画面（iPhone Duo の内側など。horizontal size class が regular）では、部屋の絵と盤を左右に並べる
struct RoomView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.horizontalSizeClass) private var sizeClass
    let index: Int

    private var room: Room { model.rooms[index] }
    private var progress: RoomProgress { model.roomProgress(index) }

    var body: some View {
        ZStack {
            WoodWall(lamp: UnitPoint(x: 0.5, y: 0.08), floorRatio: 0.2).ignoresSafeArea()
            if sizeClass == .regular {
                HStack(spacing: 20) {
                    roomColumn.frame(maxWidth: 520)
                    Group {
                        if let board = model.board, model.openObject != nil {
                            BoardPanel(board: board, title: room.objects[model.openObject ?? 0].name, subtitle: room.title)
                        } else {
                            RoomGuide(room: room, progress: progress)
                        }
                    }
                    .frame(maxWidth: 560)
                }
                .padding(20)
            } else {
                roomColumn.padding(.horizontal, 16)
                    .accessibilityHidden(model.openObject != nil || model.door != nil || model.showIntro)
                if let board = model.board, let o = model.openObject {
                    ZStack {
                        Ink.deep.ignoresSafeArea()
                        BoardPanel(board: board, title: room.objects[o].name, subtitle: room.title)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
                }
            }
            if model.door != nil {
                DoorOverlay(room: room, index: index)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(3)
            }
            if model.showIntro {
                StoryCard(eyebrow: room.subtitle, title: room.title, text: room.intro, button: tr("部屋を調べる", "Look around"), buttonID: "main.closeIntro") {
                    model.closeIntro()
                }
                .transition(.opacity)
                .zIndex(4)
            }
            if case .room(let r) = model.result, r == index {
                ResultView(kind: .room(index))
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(5)
            }
        }
    }

    private var roomColumn: some View {
        VStack(spacing: 12) {
            header
            RoomScene(index: index)
                .frame(maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom) { bottomBar.padding(.top, 8) }
    }

    private var header: some View {
        HStack(spacing: 12) {
            RoundBrassButton(systemImage: "chevron.left", label: tr("広間へ戻る", "Back to the hall")) { model.goHome() }
                .accessibilityIdentifier("main.leave")
            VStack(alignment: .leading, spacing: 2) {
                Text(room.subtitle).font(Typo.label(11)).kerning(0.6).foregroundStyle(Ink.brass)
                Text(room.title).font(Typo.title(21)).foregroundStyle(Ink.onWall).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                ClockLabel()
                Text(trf("文字盤 %d / %d", "Dials %d / %d", progress.solvedCount, room.objects.count))
                    .font(Typo.label(10))
                    .foregroundStyle(Ink.onWallSoft)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.top, 6)
    }

    /// 下に固定：道具のトレイと、扉を調べるボタン
    private var bottomBar: some View {
        let items = Inventory.items(room: room, progress: progress)
        return VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text(tr("道具", "Tools"))
                    .font(Typo.label(11)).kerning(0.6)
                    .foregroundStyle(Ink.brass)
                    .frame(width: 44)
                ForEach(0..<4, id: \.self) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Ink.deep.opacity(0.85))
                        RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Ink.brassDeep.opacity(0.7), lineWidth: 1)
                        if i < items.count {
                            ItemGlyph(kind: items[i]).padding(8)
                                .transition(.scale(scale: 0.3).combined(with: .opacity))
                        }
                    }
                    .frame(height: 48)
                    .accessibilityLabel(i < items.count ? items[i].name : tr("空きの棚", "Empty slot"))
                }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: Radius.plate, style: .continuous).fill(LinearGradient(colors: [Ink.brassDeep, Color(hex: 0x6E5226)], startPoint: .top, endPoint: .bottom)))
            .animation(model.reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.7), value: items.count)
            Button {
                model.tapDoor()
            } label: {
                Label(Inventory.doorReady(room: room, progress: progress) ? tr("扉の文字盤を回す", "Turn the door dials") : tr("扉を調べる", "Check the door"), systemImage: "door.left.hand.closed")
            }
            .buttonStyle(BrassButtonStyle(prominent: Inventory.doorReady(room: room, progress: progress)))
            .accessibilityIdentifier("main.door")
        }
    }
}

/// 部屋の絵：真ん中に扉、左右に物が 2 つずつ
struct RoomScene: View {
    @Environment(AppModel.self) private var model
    let index: Int

    var body: some View {
        let room = model.rooms[index]
        let progress = model.roomProgress(index)
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let objW = min(w * 0.31, 170)
            let objH = min(h * 0.4, objW * 1.25)
            let spots = [CGPoint(x: w * 0.19, y: h * 0.27), CGPoint(x: w * 0.81, y: h * 0.27), CGPoint(x: w * 0.19, y: h * 0.74), CGPoint(x: w * 0.81, y: h * 0.74)]
            ZStack {
                // 窓（夜空と月）
                WindowArt()
                    .frame(width: w * 0.24, height: h * 0.2)
                    .position(x: w * 0.5, y: h * 0.12)
                // 扉
                Button { model.tapDoor() } label: {
                    DoorArt(letters: Inventory.doorLetters(room: room, progress: progress),
                            items: room.doorItems.map { ($0, Inventory.items(room: room, progress: progress).contains($0)) })
                        .frame(width: w * 0.3, height: h * 0.58)
                }
                .buttonStyle(PressStyle())
                .position(x: w * 0.5, y: h * 0.58)
                .accessibilityLabel(tr("最後の扉", "The final door"))
                ForEach(0..<room.objects.count, id: \.self) { i in
                    ObjectButton(room: room, roomIndex: index, objectIndex: i, progress: progress)
                        .frame(width: objW, height: objH)
                        .position(spots[i % spots.count])
                }
            }
        }
    }
}

struct ObjectButton: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let room: Room
    let roomIndex: Int
    let objectIndex: Int
    let progress: RoomProgress

    var body: some View {
        let object = room.objects[objectIndex]
        let op = progress.object(objectIndex)
        let canOpen = Inventory.canOpen(objectIndex, room: room, progress: progress)
        let needsItem = object.requires != nil && !op.unlocked
        let shakeMe = model.lockedNotice == objectIndex && !reduceMotion
        let wobble = model.unlocking == objectIndex && !reduceMotion
        Button { model.tapObject(objectIndex) } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    // 解けた物にはランプの光が当たる
                    if op.solved {
                        Ellipse().fill(Ink.glow.opacity(0.22)).blur(radius: 12).allowsHitTesting(false)
                    }
                    ObjectArt(kind: object.kind, solved: op.solved, locked: needsItem && !canOpen)
                    badge(op: op, needsItem: needsItem, canOpen: canOpen, item: object.requires)
                    if roomIndex == 0 && objectIndex == 0 && progress.solvedCount == 0 && op.cells.isEmpty {
                        // 最初の 10 秒：どこから触ればよいか
                        Text(tr("ここから", "Start here"))
                            .font(Typo.label(11)).kerning(0.6)
                            .foregroundStyle(Ink.ink)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(Ink.glow))
                            .overlay(Capsule().stroke(Ink.brassDeep, lineWidth: 1))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .offset(y: 6)
                            .allowsHitTesting(false)
                    }
                }
                .frame(maxHeight: .infinity)
                BrassPlate(padding: 6) {
                    Text(object.name)
                        .font(Typo.label(11))
                        .foregroundStyle(Ink.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .keyframeAnimator(initialValue: CGFloat(0), trigger: model.wrongTick) { v, x in
                v.offset(x: shakeMe ? x : 0)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(-6, duration: 0.05)
                    LinearKeyframe(5, duration: 0.05)
                    LinearKeyframe(-3, duration: 0.05)
                    LinearKeyframe(0, duration: 0.05)
                }
            }
            .keyframeAnimator(initialValue: CGFloat(0), trigger: model.unlockTick) { v, angle in
                v.rotationEffect(.degrees(wobble ? angle : 0))
            } keyframes: { _ in
                KeyframeTrack {
                    SpringKeyframe(-4, duration: 0.12)
                    SpringKeyframe(3, duration: 0.12)
                    SpringKeyframe(0, duration: 0.3, spring: .bouncy)
                }
            }
        }
        .buttonStyle(PressStyle())
        .accessibilityIdentifier("main.object\(objectIndex)")
        .accessibilityLabel(label(op: op, canOpen: canOpen, object: object))
    }

    @ViewBuilder
    private func badge(op: ObjectProgress, needsItem: Bool, canOpen: Bool, item: ItemKind?) -> some View {
        if op.solved {
            Text(room.objects[objectIndex].puzzle.markLetter ?? "")
                .font(Typo.title(15, .bold))
                .foregroundStyle(Ink.ink)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Ink.brassSoft))
                .overlay(Circle().inset(by: 1.5).stroke(Ink.brassDeep, lineWidth: 1.2))
                .offset(x: 4, y: -4)
        } else if needsItem, let item {
            HStack(spacing: 2) {
                PadlockShape().fill(canOpen ? Ink.brass : Ink.wax).frame(width: 12, height: 15)
                ItemGlyph(kind: item, color: canOpen ? Ink.brass : Ink.onWallSoft, shade: Ink.deep).frame(width: 16, height: 16)
            }
            .padding(5)
            .background(Capsule().fill(Ink.deep.opacity(0.9)))
            .offset(x: 4, y: -4)
        }
    }

    private func label(op: ObjectProgress, canOpen: Bool, object: RoomObject) -> String {
        if op.solved { return trf("%@、解けた", "%@, solved", object.name) }
        if !canOpen { return trf("%@、%@が要る", "%@, needs the %@", object.name, object.requires?.name ?? "") }
        return object.name
    }
}

/// 夜の窓
struct WindowArt: View {
    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            ctx.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(Ink.night))
            ctx.fill(Path(ellipseIn: CGRect(x: size.width * 0.62, y: size.height * 0.16, width: size.width * 0.2, height: size.width * 0.2)), with: .color(Ink.moon))
            var rng = SeededRandom(seed: 11)
            for _ in 0..<10 {
                let x = CGFloat(rng.next() % 1000) / 1000 * size.width
                let y = CGFloat(rng.next() % 1000) / 1000 * size.height * 0.7
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.6, height: 1.6)), with: .color(Ink.moon.opacity(0.8)))
            }
            ctx.stroke(Path(roundedRect: rect, cornerRadius: 4), with: .color(Ink.brassDeep), lineWidth: 3)
            ctx.fill(Path(CGRect(x: size.width / 2 - 1.5, y: 0, width: 3, height: size.height)), with: .color(Ink.brassDeep))
            ctx.fill(Path(CGRect(x: 0, y: size.height / 2 - 1.5, width: size.width, height: 3)), with: .color(Ink.brassDeep))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// 広い画面の右側：部屋の物語と、調べる順の手がかり
struct RoomGuide: View {
    @Environment(AppModel.self) private var model
    let room: Room
    let progress: RoomProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(room.subtitle).font(Typo.label(12)).kerning(0.6).foregroundStyle(Ink.brassDeep)
            Text(room.title).font(Typo.title(26)).foregroundStyle(Ink.ink)
            Text(room.intro).font(Typo.body(.body)).foregroundStyle(Ink.inkSoft).fixedSize(horizontal: false, vertical: true)
            Divider().overlay(Ink.paperDeep)
            ForEach(0..<room.objects.count, id: \.self) { i in
                let o = room.objects[i]
                let op = progress.object(i)
                HStack(spacing: 10) {
                    ObjectArt(kind: o.kind).frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(o.name).font(Typo.body(.subheadline, .semibold)).foregroundStyle(Ink.ink)
                        Text(op.solved ? trf("解けた・%@を手に入れた", "Solved · got the %@", o.gives.name) : o.note)
                            .font(Typo.body(.caption)).foregroundStyle(Ink.inkSoft)
                    }
                    Spacer()
                    if op.solved { StarRow(count: op.stars) }
                }
            }
            Spacer()
            Text(tr("左の物をタップすると、ここにクロスワードが開く", "Tap an object on the left to open its crossword here"))
                .font(Typo.body(.caption)).foregroundStyle(Ink.inkSoft)
        }
        .padding(22)
        .background(Parchment())
        .paperShadow()
    }
}

/// 物語のカード（部屋に入ったとき）
struct StoryCard: View {
    let eyebrow: String
    let title: String
    let text: String
    let button: String
    let buttonID: String
    var action: () -> Void

    var body: some View {
        ZStack {
            Ink.deep.opacity(0.82).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(eyebrow).font(Typo.label(12)).kerning(1.2).foregroundStyle(Ink.brassDeep)
                Text(title).font(Typo.title(28)).foregroundStyle(Ink.ink).multilineTextAlignment(.center)
                Rectangle().fill(Ink.brassDeep.opacity(0.5)).frame(width: 60, height: 1)
                Text(text).font(Typo.body(.body)).foregroundStyle(Ink.inkSoft).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                Button(button, action: action)
                    .buttonStyle(BrassButtonStyle())
                    .accessibilityIdentifier(buttonID)
                    .padding(.top, 6)
            }
            .padding(26)
            .background(Parchment())
            .paperShadow()
            .padding(.horizontal, 24)
            .frame(maxWidth: 480)
        }
    }
}

/// 経過時間（毎秒変わるので、ここだけが描き直される）
struct ClockLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Text(clockText(model.elapsed))
            .font(Typo.title(17, .medium))
            .monospacedDigit()
            .foregroundStyle(Ink.brassSoft)
    }
}
