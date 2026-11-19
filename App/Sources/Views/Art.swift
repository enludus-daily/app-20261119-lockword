import SwiftUI

// 部屋の物と道具の絵。外部の画像を使わず、Canvas と Path で描く。

/// 道具（真鍮のトレイに並ぶ）
struct ItemGlyph: View {
    let kind: ItemKind
    var color: Color = Ink.brass
    var shade: Color = Ink.brassDeep

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height)
            let o = CGPoint(x: (size.width - s) / 2, y: (size.height - s) / 2)
            func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: o.x + x * s, y: o.y + y * s, width: w * s, height: h * s) }
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: o.x + x * s, y: o.y + y * s) }
            let line = s * 0.08
            switch kind {
            case .key:
                ctx.stroke(Path(ellipseIn: r(0.08, 0.3, 0.36, 0.36)), with: .color(color), lineWidth: line * 1.2)
                ctx.fill(Path(r(0.42, 0.44, 0.5, 0.09)), with: .color(color))
                ctx.fill(Path(r(0.72, 0.53, 0.07, 0.15)), with: .color(color))
                ctx.fill(Path(r(0.84, 0.53, 0.07, 0.1)), with: .color(color))
            case .candle:
                ctx.fill(Path(roundedRect: r(0.36, 0.38, 0.28, 0.5), cornerRadius: s * 0.03), with: .color(Ink.paper))
                ctx.fill(Path(r(0.26, 0.86, 0.48, 0.07)), with: .color(color))
                var flame = Path()
                flame.move(to: pt(0.5, 0.08))
                flame.addQuadCurve(to: pt(0.5, 0.34), control: pt(0.66, 0.26))
                flame.addQuadCurve(to: pt(0.5, 0.08), control: pt(0.34, 0.26))
                ctx.fill(flame, with: .color(Ink.glow))
                ctx.fill(Path(r(0.49, 0.32, 0.02, 0.07)), with: .color(Ink.ink))
            case .gear:
                let c = pt(0.5, 0.5)
                var g = Path()
                for i in 0..<16 {
                    let a = Double(i) * .pi / 8
                    let rr = (i % 2 == 0 ? 0.44 : 0.34) * s
                    let a2 = a + .pi / 8
                    let p0 = CGPoint(x: c.x + CGFloat(cos(a)) * rr, y: c.y + CGFloat(sin(a)) * rr)
                    if i == 0 { g.move(to: p0) } else { g.addLine(to: p0) }
                    g.addLine(to: CGPoint(x: c.x + CGFloat(cos(a2)) * rr, y: c.y + CGFloat(sin(a2)) * rr))
                }
                g.closeSubpath()
                ctx.fill(g, with: .color(color))
                ctx.fill(Path(ellipseIn: r(0.38, 0.38, 0.24, 0.24)), with: .color(shade))
            case .lens:
                ctx.stroke(Path(ellipseIn: r(0.12, 0.1, 0.5, 0.5)), with: .color(color), lineWidth: line)
                ctx.fill(Path(ellipseIn: r(0.16, 0.14, 0.42, 0.42)), with: .color(Ink.glow.opacity(0.25)))
                var handle = Path()
                handle.move(to: pt(0.56, 0.56))
                handle.addLine(to: pt(0.88, 0.88))
                ctx.stroke(handle, with: .color(shade), style: StrokeStyle(lineWidth: line * 1.6, lineCap: .round))
            case .ring:
                ctx.stroke(Path(ellipseIn: r(0.18, 0.32, 0.64, 0.56)), with: .color(color), lineWidth: line * 1.3)
                var gem = Path()
                gem.move(to: pt(0.5, 0.06))
                gem.addLine(to: pt(0.64, 0.2))
                gem.addLine(to: pt(0.5, 0.36))
                gem.addLine(to: pt(0.36, 0.2))
                gem.closeSubpath()
                ctx.fill(gem, with: .color(Ink.waxSoft))
            case .coin:
                ctx.fill(Path(ellipseIn: r(0.12, 0.12, 0.76, 0.76)), with: .color(color))
                ctx.stroke(Path(ellipseIn: r(0.2, 0.2, 0.6, 0.6)), with: .color(shade), lineWidth: line * 0.5)
                ctx.fill(StarShape().path(in: r(0.36, 0.36, 0.28, 0.28)), with: .color(shade))
            case .map:
                var p = Path()
                p.move(to: pt(0.1, 0.2)); p.addLine(to: pt(0.36, 0.12)); p.addLine(to: pt(0.64, 0.2)); p.addLine(to: pt(0.9, 0.12))
                p.addLine(to: pt(0.9, 0.8)); p.addLine(to: pt(0.64, 0.88)); p.addLine(to: pt(0.36, 0.8)); p.addLine(to: pt(0.1, 0.88))
                p.closeSubpath()
                ctx.fill(p, with: .color(Ink.paper))
                for (x, y) in [(0.25, 0.4), (0.45, 0.6), (0.7, 0.35), (0.6, 0.7)] {
                    ctx.fill(StarShape().path(in: r(CGFloat(x) - 0.05, CGFloat(y) - 0.05, 0.1, 0.1)), with: .color(shade))
                }
            case .compass:
                ctx.fill(Path(ellipseIn: r(0.1, 0.1, 0.8, 0.8)), with: .color(color))
                ctx.fill(Path(ellipseIn: r(0.18, 0.18, 0.64, 0.64)), with: .color(Ink.paper))
                var n = Path()
                n.move(to: pt(0.5, 0.2)); n.addLine(to: pt(0.58, 0.5)); n.addLine(to: pt(0.42, 0.5)); n.closeSubpath()
                ctx.fill(n, with: .color(Ink.wax))
                var sth = Path()
                sth.move(to: pt(0.5, 0.8)); sth.addLine(to: pt(0.58, 0.5)); sth.addLine(to: pt(0.42, 0.5)); sth.closeSubpath()
                ctx.fill(sth, with: .color(Ink.inkSoft))
            }
        }
        .accessibilityLabel(kind.name)
    }
}

/// 部屋の物。solved なら少し明るく、locked なら暗い
struct ObjectArt: View {
    let kind: ObjectKind
    var solved = false
    var locked = false

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func r(_ x: CGFloat, _ y: CGFloat, _ ww: CGFloat, _ hh: CGFloat) -> CGRect { CGRect(x: x * w, y: y * h, width: ww * w, height: hh * h) }
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * w, y: y * h) }
            let wood = Color(hex: 0x6E4A2E)
            let woodDark = Color(hex: 0x4F3420)
            let woodLight = Color(hex: 0x8A6240)
            switch kind {
            case .painting:
                ctx.fill(Path(r(0.08, 0.06, 0.84, 0.82)), with: .color(Ink.brass))
                ctx.stroke(Path(r(0.11, 0.09, 0.78, 0.76)), with: .color(Ink.brassDeep), lineWidth: 2)
                ctx.fill(Path(r(0.16, 0.14, 0.68, 0.66)), with: .color(Color(hex: 0x3D4A3A)))
                // 肖像：肩と顔
                ctx.fill(Path(ellipseIn: r(0.38, 0.24, 0.24, 0.26)), with: .color(Color(hex: 0xC9A98A)))
                var shoulders = Path()
                shoulders.move(to: pt(0.22, 0.8))
                shoulders.addQuadCurve(to: pt(0.78, 0.8), control: pt(0.5, 0.36))
                ctx.fill(shoulders, with: .color(Color(hex: 0x24303A)))
                ctx.fill(Path(r(0.47, 0.52, 0.06, 0.1)), with: .color(Ink.paper))
            case .chest:
                ctx.fill(Path(roundedRect: r(0.08, 0.42, 0.84, 0.48), cornerRadius: 4), with: .color(wood))
                var lid = Path()
                lid.addRoundedRect(in: r(0.08, 0.24, 0.84, 0.22), cornerSize: CGSize(width: w * 0.2, height: h * 0.12))
                ctx.fill(lid, with: .color(woodLight))
                for x in [0.2, 0.76] { ctx.fill(Path(r(CGFloat(x), 0.24, 0.05, 0.66)), with: .color(Ink.brassDeep)) }
                ctx.fill(Path(roundedRect: r(0.42, 0.4, 0.16, 0.18), cornerRadius: 3), with: .color(Ink.brass))
                ctx.fill(Path(ellipseIn: r(0.475, 0.45, 0.05, 0.05)), with: .color(Ink.ink))
            case .bookshelf:
                ctx.fill(Path(r(0.1, 0.04, 0.8, 0.92)), with: .color(woodDark))
                let colors: [Color] = [Color(hex: 0x6B2E2A), Color(hex: 0x2F4A3E), Color(hex: 0x8A6A3A), Color(hex: 0x3B3F5C), Color(hex: 0x704A2A), Color(hex: 0x5A2F44)]
                for shelf in 0..<3 {
                    let y = 0.08 + CGFloat(shelf) * 0.3
                    var x: CGFloat = 0.14
                    var k = shelf * 2
                    while x < 0.82 {
                        let bw: CGFloat = 0.06 + CGFloat((k * 7) % 3) * 0.015
                        let bh: CGFloat = 0.2 + CGFloat((k * 5) % 3) * 0.02
                        ctx.fill(Path(r(x, y + 0.24 - bh, min(bw, 0.86 - x), bh)), with: .color(colors[k % colors.count]))
                        ctx.fill(Path(r(x, y + 0.24 - bh + 0.03, min(bw, 0.86 - x), 0.012)), with: .color(Ink.brass.opacity(0.7)))
                        x += bw + 0.008
                        k += 1
                    }
                    ctx.fill(Path(r(0.1, y + 0.24, 0.8, 0.04)), with: .color(woodLight))
                }
            case .desk:
                ctx.fill(Path(r(0.04, 0.4, 0.92, 0.08)), with: .color(woodLight))
                ctx.fill(Path(r(0.1, 0.48, 0.3, 0.42)), with: .color(wood))
                ctx.fill(Path(r(0.8, 0.48, 0.08, 0.42)), with: .color(wood))
                for y in [0.54, 0.7] {
                    ctx.stroke(Path(r(0.13, CGFloat(y), 0.24, 0.12)), with: .color(woodDark), lineWidth: 1.5)
                    ctx.fill(Path(ellipseIn: r(0.23, CGFloat(y) + 0.05, 0.04, 0.03)), with: .color(Ink.brass))
                }
                // ランプ
                ctx.fill(Path(r(0.66, 0.2, 0.03, 0.2)), with: .color(Ink.brassDeep))
                var shade = Path()
                shade.move(to: pt(0.58, 0.22)); shade.addLine(to: pt(0.62, 0.08)); shade.addLine(to: pt(0.74, 0.08)); shade.addLine(to: pt(0.78, 0.22)); shade.closeSubpath()
                ctx.fill(shade, with: .color(Color(hex: 0x3F5A44)))
                ctx.fill(Path(ellipseIn: r(0.5, 0.18, 0.36, 0.2)), with: .color(Ink.glow.opacity(0.25)))
                ctx.fill(Path(r(0.2, 0.34, 0.2, 0.06)), with: .color(Ink.paper))
            case .gramophone:
                ctx.fill(Path(r(0.18, 0.62, 0.64, 0.28)), with: .color(wood))
                ctx.fill(Path(ellipseIn: r(0.22, 0.56, 0.5, 0.1)), with: .color(Color(hex: 0x1E1814)))
                var horn = Path()
                horn.move(to: pt(0.5, 0.6))
                horn.addQuadCurve(to: pt(0.86, 0.06), control: pt(0.52, 0.2))
                horn.addQuadCurve(to: pt(0.92, 0.42), control: pt(1.0, 0.22))
                horn.addQuadCurve(to: pt(0.54, 0.62), control: pt(0.62, 0.42))
                horn.closeSubpath()
                ctx.fill(horn, with: .color(Ink.brass))
                ctx.stroke(horn, with: .color(Ink.brassDeep), lineWidth: 1.5)
                ctx.fill(Path(ellipseIn: r(0.8, 0.1, 0.12, 0.3)), with: .color(Ink.brassDeep))
            case .safe:
                ctx.fill(Path(roundedRect: r(0.12, 0.12, 0.76, 0.78), cornerRadius: 6), with: .color(Color(hex: 0x3E4448)))
                ctx.stroke(Path(roundedRect: r(0.17, 0.17, 0.66, 0.68), cornerRadius: 4), with: .color(Color(hex: 0x5A6266)), lineWidth: 2)
                ctx.fill(Path(ellipseIn: r(0.34, 0.3, 0.32, 0.32)), with: .color(Ink.brass))
                ctx.stroke(Path(ellipseIn: r(0.39, 0.35, 0.22, 0.22)), with: .color(Ink.brassDeep), lineWidth: 1.5)
                for i in 0..<12 {
                    let a = Double(i) * .pi / 6
                    let c = pt(0.5, 0.46)
                    var tick = Path()
                    tick.move(to: CGPoint(x: c.x + CGFloat(cos(a)) * w * 0.12, y: c.y + CGFloat(sin(a)) * w * 0.12))
                    tick.addLine(to: CGPoint(x: c.x + CGFloat(cos(a)) * w * 0.155, y: c.y + CGFloat(sin(a)) * w * 0.155))
                    ctx.stroke(tick, with: .color(Ink.brassDeep), lineWidth: 1)
                }
                ctx.fill(Path(r(0.62, 0.7, 0.16, 0.05)), with: .color(Ink.brass))
            case .fireplace:
                ctx.fill(Path(r(0.06, 0.12, 0.88, 0.82)), with: .color(Color(hex: 0x6A5A4C)))
                ctx.fill(Path(r(0.02, 0.08, 0.96, 0.08)), with: .color(woodLight))
                var arch = Path()
                arch.move(to: pt(0.22, 0.94))
                arch.addLine(to: pt(0.22, 0.46))
                arch.addQuadCurve(to: pt(0.78, 0.46), control: pt(0.5, 0.24))
                arch.addLine(to: pt(0.78, 0.94))
                arch.closeSubpath()
                ctx.fill(arch, with: .color(Color(hex: 0x1F1712)))
                // 灰と、残り火
                ctx.fill(Path(ellipseIn: r(0.3, 0.82, 0.4, 0.1)), with: .color(Color(hex: 0x5C5650)))
                ctx.fill(Path(ellipseIn: r(0.44, 0.84, 0.1, 0.05)), with: .color(Ink.waxSoft.opacity(solved ? 0.9 : 0.5)))
            case .clock:
                ctx.fill(Path(r(0.3, 0.04, 0.4, 0.92)), with: .color(wood))
                ctx.fill(Path(r(0.26, 0.02, 0.48, 0.06)), with: .color(woodLight))
                ctx.fill(Path(ellipseIn: r(0.34, 0.1, 0.32, 0.26)), with: .color(Ink.paper))
                ctx.stroke(Path(ellipseIn: r(0.34, 0.1, 0.32, 0.26)), with: .color(Ink.brass), lineWidth: 2)
                var hands = Path()
                hands.move(to: pt(0.5, 0.23)); hands.addLine(to: pt(0.5, 0.14))
                hands.move(to: pt(0.5, 0.23)); hands.addLine(to: pt(0.57, 0.21))
                ctx.stroke(hands, with: .color(Ink.ink), lineWidth: 1.5)
                ctx.fill(Path(r(0.38, 0.44, 0.24, 0.42)), with: .color(woodDark))
                ctx.fill(Path(r(0.495, 0.44, 0.01, 0.26)), with: .color(Ink.brassDeep))
                ctx.fill(Path(ellipseIn: r(0.44, 0.68, 0.12, 0.1)), with: .color(Ink.brass))
            case .telescope:
                var tube = Path()
                tube.move(to: pt(0.12, 0.5)); tube.addLine(to: pt(0.82, 0.12)); tube.addLine(to: pt(0.9, 0.26)); tube.addLine(to: pt(0.2, 0.64)); tube.closeSubpath()
                ctx.fill(tube, with: .color(Ink.brass))
                ctx.stroke(tube, with: .color(Ink.brassDeep), lineWidth: 1.5)
                ctx.fill(Path(ellipseIn: r(0.8, 0.1, 0.1, 0.18)), with: .color(Ink.brassDeep))
                var legs = Path()
                legs.move(to: pt(0.5, 0.42)); legs.addLine(to: pt(0.3, 0.94))
                legs.move(to: pt(0.5, 0.42)); legs.addLine(to: pt(0.7, 0.94))
                legs.move(to: pt(0.5, 0.42)); legs.addLine(to: pt(0.5, 0.94))
                ctx.stroke(legs, with: .color(woodLight), lineWidth: 3)
            case .globe:
                ctx.fill(Path(ellipseIn: r(0.18, 0.06, 0.64, 0.64)), with: .color(Color(hex: 0x5E7A6A)))
                var land = Path()
                land.addEllipse(in: r(0.3, 0.18, 0.18, 0.24))
                land.addEllipse(in: r(0.52, 0.36, 0.16, 0.14))
                ctx.fill(land, with: .color(Color(hex: 0xC9B27C)))
                ctx.stroke(Path(ellipseIn: r(0.14, 0.02, 0.72, 0.72)), with: .color(Ink.brass), lineWidth: 2.5)
                ctx.fill(Path(r(0.47, 0.74, 0.06, 0.14)), with: .color(woodDark))
                ctx.fill(Path(roundedRect: r(0.3, 0.86, 0.4, 0.08), cornerRadius: 3), with: .color(wood))
            }
            if locked {
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Ink.deep.opacity(0.35)))
            }
        }
        .accessibilityHidden(true)
    }
}

/// 最後の扉（アーチ形。文字盤 n 個と、道具の穴 2 つ）
struct DoorArt: View {
    var letters: [String?]
    var items: [(ItemKind, Bool)]
    var open = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                DoorShape().fill(open ? Ink.glow.opacity(0.7) : Color(hex: 0x5A3A24))
                DoorShape().stroke(Ink.brassDeep, lineWidth: 3)
                if !open {
                    // 板の線
                    Canvas { ctx, size in
                        for k in 1..<4 {
                            let x = size.width * CGFloat(k) / 4
                            ctx.fill(Path(CGRect(x: x, y: size.height * 0.2, width: 1, height: size.height * 0.8)), with: .color(Ink.deep.opacity(0.6)))
                        }
                    }
                    .clipShape(DoorShape())
                    .allowsHitTesting(false)
                    VStack(spacing: h * 0.03) {
                        HStack(spacing: w * 0.03) {
                            ForEach(Array(letters.enumerated()), id: \.offset) { _, l in
                                Text(l ?? "?")
                                    .font(Typo.title(min(w * 0.13, 22), .bold))
                                    .foregroundStyle(l == nil ? Ink.brassDeep : Ink.ink)
                                    .frame(width: w * 0.19, height: w * 0.19)
                                    .background(Circle().fill(l == nil ? Ink.deep : Ink.brassSoft))
                                    .overlay(Circle().stroke(Ink.brass, lineWidth: 1.5))
                            }
                        }
                        HStack(spacing: w * 0.1) {
                            ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                                ItemGlyph(kind: it.0, color: it.1 ? Ink.brass : Ink.grain, shade: it.1 ? Ink.brassDeep : Ink.deep)
                                    .frame(width: w * 0.2, height: w * 0.2)
                                    .padding(4)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Ink.deep.opacity(0.8)))
                            }
                        }
                    }
                    .padding(.top, h * 0.18)
                    .frame(maxHeight: .infinity, alignment: .top)
                    Circle().fill(Ink.brass).frame(width: w * 0.07).position(x: w * 0.82, y: h * 0.62)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct DoorShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.width / 2
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.midX, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
