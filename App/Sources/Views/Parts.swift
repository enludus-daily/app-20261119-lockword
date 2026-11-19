import SwiftUI

// MARK: - 壁と床

/// 胡桃材の羽目板の壁（Canvas で部品と同じ大きさに描く。押せる範囲を覆わない）
struct WoodWall: View {
    var lamp: UnitPoint = UnitPoint(x: 0.2, y: 0.12)
    var floorRatio: CGFloat = 0

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Ink.wall))
            // 羽目板：幅 ~120pt ごとの縦の板、板の中に細い木目
            let boards = max(3, Int(size.width / 120))
            let bw = size.width / CGFloat(boards)
            let wallH = size.height * (1 - floorRatio)
            var rng = SeededRandom(seed: 7)
            for i in 0..<boards {
                let x = CGFloat(i) * bw
                let inset = CGRect(x: x + 10, y: 14, width: bw - 20, height: wallH * 0.56)
                ctx.fill(Path(roundedRect: inset, cornerRadius: 3), with: .color(Ink.panel))
                ctx.stroke(Path(roundedRect: inset, cornerRadius: 3), with: .color(Ink.deep.opacity(0.7)), lineWidth: 1.2)
                let lower = CGRect(x: x + 10, y: wallH * 0.62, width: bw - 20, height: wallH * 0.32)
                ctx.fill(Path(roundedRect: lower, cornerRadius: 3), with: .color(Ink.panel.opacity(0.85)))
                ctx.stroke(Path(roundedRect: lower, cornerRadius: 3), with: .color(Ink.deep.opacity(0.7)), lineWidth: 1.2)
                for _ in 0..<5 {
                    let gx = x + 16 + CGFloat(rng.next() % UInt64(max(1, Int(bw - 32))))
                    var p = Path()
                    p.move(to: CGPoint(x: gx, y: 20))
                    p.addCurve(to: CGPoint(x: gx + 3, y: wallH * 0.56 + 8),
                               control1: CGPoint(x: gx - 4, y: wallH * 0.2),
                               control2: CGPoint(x: gx + 6, y: wallH * 0.4))
                    ctx.stroke(p, with: .color(Ink.grain.opacity(0.55)), lineWidth: 0.7)
                }
                // 板の継ぎ目
                ctx.fill(Path(CGRect(x: x, y: 0, width: 1.5, height: wallH)), with: .color(Ink.deep.opacity(0.8)))
            }
            // 腰の見切り（真鍮の細い線）
            ctx.fill(Path(CGRect(x: 0, y: wallH * 0.59, width: size.width, height: 2)), with: .color(Ink.brassDeep.opacity(0.7)))
            if floorRatio > 0 {
                let floor = CGRect(x: 0, y: wallH, width: size.width, height: size.height - wallH)
                ctx.fill(Path(floor), with: .color(Ink.floor))
                ctx.fill(Path(CGRect(x: 0, y: wallH, width: size.width, height: 4)), with: .color(Ink.deep))
                for k in 1..<6 {
                    let y = wallH + floor.height * CGFloat(k) / 6
                    ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 0.8)), with: .color(Ink.deep.opacity(0.6)))
                }
            }
            // ランプの光（題材に理由のあるグラデーションはここだけ）
            let center = CGPoint(x: size.width * lamp.x, y: size.height * lamp.y)
            let r = max(size.width, size.height) * 0.75
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                     with: .radialGradient(Gradient(colors: [Ink.glow.opacity(0.22), Ink.glow.opacity(0.06), .clear]),
                                           center: center, startRadius: 0, endRadius: r))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - 羊皮紙と真鍮

/// 羊皮紙のカード（縁が少し焼けている）
struct Parchment: View {
    var radius: CGFloat = Radius.card

    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            let path = Path(roundedRect: rect, cornerRadius: radius, style: .continuous)
            ctx.fill(path, with: .color(Ink.paper))
            // 縁の焼け
            ctx.stroke(path, with: .color(Ink.paperDeep), lineWidth: 6)
            ctx.stroke(Path(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: radius, style: .continuous), with: .color(Ink.brassDeep.opacity(0.35)), lineWidth: 1)
            // 紙の粒（固定の乱数）
            var rng = SeededRandom(seed: 3)
            let dots = Int(size.width * size.height / 900)
            for _ in 0..<min(dots, 400) {
                let x = CGFloat(rng.next() % UInt64(max(1, Int(size.width))))
                let y = CGFloat(rng.next() % UInt64(max(1, Int(size.height))))
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.2, height: 1.2)), with: .color(Ink.paperDeep.opacity(0.6)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// 真鍮の札（題・名札）
struct BrassPlate<Content: View>: View {
    var padding: CGFloat = 10
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, padding + 4)
            .padding(.vertical, padding * 0.6)
            .background {
                RoundedRectangle(cornerRadius: Radius.plate / 2, style: .continuous)
                    .fill(LinearGradient(colors: [Ink.brassSoft, Ink.brass, Ink.brassDeep], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: Radius.plate / 2, style: .continuous).inset(by: 2).stroke(Ink.brassDeep.opacity(0.6), lineWidth: 0.8))
                    .overlay(alignment: .leading) { screw.padding(.leading, 4) }
                    .overlay(alignment: .trailing) { screw.padding(.trailing, 4) }
                    .allowsHitTesting(false)
            }
    }

    private var screw: some View {
        Circle().fill(Ink.brassDeep).frame(width: 3.5, height: 3.5)
    }
}

/// 主なボタン：真鍮の板。下辺だけ厚く、押すと沈む
struct BrassButtonStyle: ButtonStyle {
    var prominent = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typo.title(17, .semibold))
            .foregroundStyle(prominent ? Ink.ink : Ink.onWall)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.plate, style: .continuous)
                        .fill(prominent ? Ink.brassDeep : Ink.deep)
                        .offset(y: configuration.isPressed ? 1 : 4)
                    RoundedRectangle(cornerRadius: Radius.plate, style: .continuous)
                        .fill(prominent ? AnyShapeStyle(LinearGradient(colors: [Ink.brassSoft, Ink.brass], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Ink.panel))
                        .overlay(RoundedRectangle(cornerRadius: Radius.plate, style: .continuous).inset(by: 1).stroke(prominent ? Ink.brassSoft.opacity(0.8) : Ink.grain, lineWidth: 1))
                        .offset(y: configuration.isPressed ? 1 : 0)
                }
            }
            .offset(y: configuration.isPressed ? 1 : 0)
            .padding(.bottom, 4)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// 丸い真鍮のボタン（閉じる・設定など）
struct RoundBrassButton: View {
    let systemImage: String
    let label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Ink.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(LinearGradient(colors: [Ink.brassSoft, Ink.brass], startPoint: .top, endPoint: .bottom)))
                .overlay(Circle().inset(by: 1.5).stroke(Ink.brassDeep.opacity(0.6), lineWidth: 1))
                .woodShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// 押すと少し縮むだけ（盤のマス・物）
struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - 星

struct StarRow: View {
    let count: Int
    var size: CGFloat = 12
    var color: Color = Ink.brass

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                StarShape()
                    .fill(i < count ? color : color.opacity(0.22))
                    .frame(width: size, height: size)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(trf("星 %d つ", "%d stars", count))
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        for i in 0..<10 {
            let a = Double(i) * .pi / 5 - .pi / 2
            let rr = i % 2 == 0 ? r : r * 0.45
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * rr, y: c.y + CGFloat(sin(a)) * rr)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - 錠前

struct PadlockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let body = CGRect(x: rect.minX, y: rect.minY + h * 0.42, width: w, height: h * 0.58)
        p.addRoundedRect(in: body, cornerSize: CGSize(width: w * 0.14, height: w * 0.14))
        var shackle = Path()
        shackle.addArc(center: CGPoint(x: rect.midX, y: rect.minY + h * 0.38), radius: w * 0.3, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addPath(shackle.strokedPath(StrokeStyle(lineWidth: w * 0.14)))
        p.addRect(CGRect(x: rect.midX - w * 0.37, y: rect.minY + h * 0.36, width: w * 0.14, height: h * 0.1))
        p.addRect(CGRect(x: rect.midX + w * 0.23, y: rect.minY + h * 0.36, width: w * 0.14, height: h * 0.1))
        return p
    }
}

// MARK: - 知らせ

struct BannerView: View {
    let banner: Banner

    var body: some View {
        HStack(spacing: 12) {
            if let item = banner.item {
                ItemGlyph(kind: item)
                    .frame(width: 30, height: 30)
                    .padding(6)
                    .background(Circle().fill(Ink.deep))
            } else if let letter = banner.letter {
                Text(letter)
                    .font(Typo.title(22, .bold))
                    .foregroundStyle(Ink.ink)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Ink.brassSoft))
                    .overlay(Circle().inset(by: 2).stroke(Ink.brassDeep, lineWidth: 1.5))
            } else {
                PadlockShape().fill(Ink.wax).frame(width: 22, height: 28).padding(10)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title).font(Typo.title(16, .semibold)).foregroundStyle(Ink.ink)
                Text(banner.detail).font(Typo.body(.caption)).foregroundStyle(Ink.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Parchment(radius: Radius.plate))
        .paperShadow()
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}
