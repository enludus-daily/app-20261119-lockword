import SwiftUI

/// 最後の扉：集めた文字を並べて、扉の言葉にする
struct DoorOverlay: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let room: Room
    let index: Int

    var body: some View {
        ZStack {
            Ink.deep.opacity(0.97).ignoresSafeArea()
            WoodWall(lamp: UnitPoint(x: 0.5, y: 0.2)).opacity(0.6).ignoresSafeArea()
            if let d = model.door {
                let calm = reduceMotion
                VStack(spacing: 18) {
                    HStack {
                        Spacer()
                        RoundBrassButton(systemImage: "xmark", label: tr("閉じる", "Close")) { model.closeDoor() }
                            .accessibilityIdentifier("main.closeDoor")
                    }
                    Text(tr("最後の扉", "The final door")).font(Typo.label(12)).kerning(1.2).foregroundStyle(Ink.brass)
                    Text(room.finalClue)
                        .font(Typo.title(20))
                        .foregroundStyle(Ink.onWall)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    // 文字盤
                    HStack(spacing: 10) {
                        ForEach(Array(d.slots.enumerated()), id: \.offset) { _, s in
                            Text(s ?? "")
                                .font(Typo.title(30, .bold))
                                .foregroundStyle(Ink.ink)
                                .frame(width: 62, height: 62)
                                .background(Circle().fill(s == nil ? Ink.panel : Ink.brassSoft))
                                .overlay(Circle().inset(by: 2).stroke(Ink.brass, lineWidth: 2))
                                .overlay(Circle().inset(by: 8).stroke(Ink.brassDeep.opacity(0.5), lineWidth: 1))
                                .woodShadow()
                        }
                    }
                    .keyframeAnimator(initialValue: CGFloat(0), trigger: d.wrong) { v, x in
                        v.offset(x: calm ? 0 : x)
                    } keyframes: { _ in
                        KeyframeTrack {
                            LinearKeyframe(-9, duration: 0.06)
                            LinearKeyframe(8, duration: 0.06)
                            LinearKeyframe(-6, duration: 0.06)
                            LinearKeyframe(5, duration: 0.06)
                            LinearKeyframe(-3, duration: 0.06)
                            LinearKeyframe(0, duration: 0.06)
                        }
                    }
                    if d.wrong > 0 {
                        Text(tr("錠は動かない。並べ方を変えてみよう", "The lock won't budge. Try another order"))
                            .font(Typo.body(.caption)).foregroundStyle(Ink.waxSoft)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 12) {
                        Text(tr("集めた文字", "Letters you found")).font(Typo.label(11)).kerning(0.6).foregroundStyle(Ink.brass)
                        HStack(spacing: 10) {
                            ForEach(Array(d.keys.enumerated()), id: \.offset) { i, k in
                                Button { model.doorKey(i) } label: {
                                    Text(k)
                                        .font(Typo.title(26, .semibold))
                                        .foregroundStyle(Ink.ink)
                                        .frame(width: 58, height: 58)
                                        .background(Circle().fill(LinearGradient(colors: [Ink.brassSoft, Ink.brass], startPoint: .top, endPoint: .bottom)))
                                        .overlay(Circle().inset(by: 1.5).stroke(Ink.brassDeep, lineWidth: 1))
                                }
                                .buttonStyle(PressStyle())
                                .opacity(d.used[i] ? 0.25 : 1)
                                .disabled(d.used[i])
                                .accessibilityIdentifier(i == 0 ? "main.doorKey" : "doorKey\(i)")
                            }
                        }
                        Button { model.doorBackspace() } label: {
                            Label(tr("1 文字もどす", "Undo a letter"), systemImage: "delete.left")
                        }
                        .buttonStyle(BrassButtonStyle(prominent: false))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
        }
    }
}

/// 脱出の結果（部屋・今日の小部屋）
struct ResultView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let kind: ResultKind
    @State private var shown = false

    var body: some View {
        ZStack {
            Ink.deep.opacity(0.9).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    EscapeLetter(kind: kind)
                        .scaleEffect(shown || reduceMotion ? 1 : 0.85)
                        .rotationEffect(.degrees(shown || reduceMotion ? -1.5 : -6))
                        .opacity(shown || reduceMotion ? 1 : 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 20)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom) { buttons.padding(.horizontal, 20).padding(.top, 8) }
            if !reduceMotion { Confetti(trigger: model.escapeTick).allowsHitTesting(false).ignoresSafeArea() }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { shown = true }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        VStack(spacing: 10) {
            switch kind {
            case .room(let r):
                if r + 1 < model.rooms.count {
                    Button(model.isRoomLocked(r + 1) ? tr("次の部屋へ（Pro）", "Next room (Pro)") : tr("次の部屋へ", "Next room")) { model.nextRoom(after: r) }
                        .buttonStyle(BrassButtonStyle())
                        .accessibilityIdentifier("main.nextRoom")
                }
                HStack(spacing: 10) {
                    Button(tr("共有", "Share")) { model.activeSheet = .share }
                        .buttonStyle(BrassButtonStyle(prominent: false))
                        .accessibilityIdentifier("main.share")
                    Button(tr("広間へ", "To the hall")) { model.goHome() }
                        .buttonStyle(BrassButtonStyle(prominent: false))
                        .accessibilityIdentifier("main.backHome")
                }
            case .daily:
                Button(tr("広間へ", "To the hall")) { model.goHome() }
                    .buttonStyle(BrassButtonStyle())
                    .accessibilityIdentifier("main.backHome")
                Button(tr("共有", "Share")) { model.activeSheet = .share }
                    .buttonStyle(BrassButtonStyle(prominent: false))
                    .accessibilityIdentifier("main.share")
            }
        }
    }
}

/// 封蝋つきの手紙（結果と共有カードで使う）
struct EscapeLetter: View {
    @Environment(AppModel.self) private var model
    let kind: ResultKind

    var body: some View {
        VStack(spacing: 14) {
            WaxSeal().frame(width: 64, height: 64)
            switch kind {
            case .room(let r):
                let room = model.rooms[r]
                let p = model.roomProgress(r)
                Text(tr("脱出", "Escaped")).font(Typo.label(12)).kerning(1.4).foregroundStyle(Ink.brassDeep)
                Text(room.title).font(Typo.title(28)).foregroundStyle(Ink.ink).multilineTextAlignment(.center)
                Text(room.final.joined())
                    .font(Typo.title(40, .bold)).kerning(6)
                    .foregroundStyle(Ink.brassDeep)
                stats(time: p.seconds, stars: p.stars, extra: p.bestSeconds.map { trf("最速 %@", "Best %@", clockText($0)) })
                Text(room.outro).font(Typo.body(.subheadline)).foregroundStyle(Ink.inkSoft).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            case .daily:
                let d = model.dailyResult(model.dailyDate)
                Text(model.dailyDayOffset == 0 ? tr("今日の小部屋から脱出", "Escaped today's nook") : tr("過去の小部屋から脱出", "Escaped a past nook"))
                    .font(Typo.label(12)).kerning(1.4).foregroundStyle(Ink.brassDeep)
                Text(model.currentDaily.title).font(Typo.title(28)).foregroundStyle(Ink.ink)
                stats(time: d?.seconds ?? 0, stars: d?.stars ?? 0, extra: nil)
                HStack(spacing: 8) {
                    ItemGlyph(kind: .candle).frame(width: 22, height: 22)
                    Text(trf("%d 日つづけて脱出", "%d-day streak", model.streak))
                        .font(Typo.title(18, .semibold)).foregroundStyle(Ink.ink)
                        .contentTransition(.numericText())
                }
                Text(tr("明日の小部屋は、夜 0 時に開く", "Tomorrow's nook opens at midnight"))
                    .font(Typo.body(.caption)).foregroundStyle(Ink.inkSoft)
            }
        }
        .padding(26)
        .frame(maxWidth: 440)
        .background(Parchment())
        .paperShadow()
    }

    private func stats(time: Int, stars: Int, extra: String?) -> some View {
        HStack(spacing: 18) {
            VStack(spacing: 2) {
                Text(clockText(time)).font(Typo.title(26, .medium)).monospacedDigit().kerning(-1).foregroundStyle(Ink.ink)
                Text(tr("かかった時間", "Time")).font(Typo.label(10)).foregroundStyle(Ink.inkSoft)
            }
            VStack(spacing: 4) {
                StarRow(count: stars, size: 20, color: Ink.brassDeep)
                Text(extra ?? tr("ヒントが少ないほど星が増える", "Fewer hints, more stars")).font(Typo.label(10)).foregroundStyle(Ink.inkSoft)
            }
        }
    }
}

/// 封蝋（小さな赤い点として使う）
struct WaxSeal: View {
    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            var blob = Path()
            for i in 0..<24 {
                let a = Double(i) * .pi / 12
                let r = size.width / 2 * (i % 2 == 0 ? 1 : 0.9)
                let p = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
                if i == 0 { blob.move(to: p) } else { blob.addLine(to: p) }
            }
            blob.closeSubpath()
            ctx.fill(blob, with: .color(Ink.wax))
            ctx.stroke(Path(ellipseIn: CGRect(x: size.width * 0.18, y: size.height * 0.18, width: size.width * 0.64, height: size.height * 0.64)), with: .color(Ink.waxSoft), lineWidth: 1.5)
        }
        .overlay(ItemGlyph(kind: .key, color: Ink.waxSoft, shade: Ink.waxSoft).padding(18))
        .accessibilityHidden(true)
    }
}

/// 紙吹雪の代わりに、真鍮の火の粉（固定の乱数で毎回同じに舞う。1 回だけ）
struct Confetti: View {
    let trigger: Int
    @State private var start = Date.distantPast
    @State private var running = false

    var body: some View {
        TimelineView(.animation(paused: !running)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSince(start)
                guard t >= 0, t < 2.4 else { return }
                var rng = SeededRandom(seed: 99)
                for _ in 0..<48 {
                    let x0 = CGFloat(rng.next() % 1000) / 1000 * size.width
                    let speed = 120 + CGFloat(rng.next() % 200)
                    let drift = CGFloat(Int(rng.next() % 120) - 60)
                    let y = size.height * 0.15 + CGFloat(t) * speed * 0.6 - 40
                    let x = x0 + drift * CGFloat(sin(t * 2 + Double(x0)))
                    let alpha = max(0, 1 - t / 2.4)
                    let s: CGFloat = 3 + CGFloat(rng.next() % 3)
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: s, height: s)), with: .color(Ink.glow.opacity(alpha)))
                }
            }
        }
        .onAppear { fire() }
        .onChange(of: trigger) { _, _ in fire() }
    }

    private func fire() {
        start = Date()
        running = true
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            running = false
        }
    }
}
