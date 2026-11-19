import SwiftUI

/// 世界：夜の古い洋館の書斎。暗い胡桃材の壁・真鍮の金具・ランプの温かい光・羊皮紙のマス目。
/// 色・書体・形はここで決める（色の 16 進をほかのファイルに書かない）。
/// 暗い地の夜の室内なので、画面はダークに固定する（前日までの明るいアプリと並べて違う）。
extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Ink {
    // 壁（胡桃材）の段階：deep（いちばん奥）→ wall → panel（羽目板）→ grain（木目の線）
    static let deep = Color(hex: 0x2E2017)
    static let wall = Color(hex: 0x3A281C)
    static let panel = Color(hex: 0x4A3424)
    static let grain = Color(hex: 0x5C4330)
    static let floor = Color(hex: 0x33241A)

    // 真鍮の段階：deep（影・文字）→ brass（金具）→ soft（光った面）→ glow（ランプの光）
    static let brassDeep = Color(hex: 0x8C6A2F)
    static let brass = Color(hex: 0xC9A45C)
    static let brassSoft = Color(hex: 0xE6CF96)
    static let glow = Color(hex: 0xFFD98A)

    // 羊皮紙の段階：paper（マス）→ paperDeep（縁・押したマス）→ paperShade（選んだ語）
    static let paper = Color(hex: 0xEFE2C4)
    static let paperDeep = Color(hex: 0xD9C69C)
    static let paperShade = Color(hex: 0xF6E3A6)
    static let solved = Color(hex: 0xE3CF8E)

    // 文字：羊皮紙の上はこげ茶のインク、壁の上は羊皮紙色
    static let ink = Color(hex: 0x2B1E14)
    static let inkSoft = Color(hex: 0x6B5844)
    static let onWall = Color(hex: 0xEFE2C4)
    static let onWallSoft = Color(hex: 0xB9A486)

    // 封蝋（違う・錠）の小さな点だけ
    static let wax = Color(hex: 0x8E2F2A)
    static let waxSoft = Color(hex: 0xB5574C)

    // 夜の窓
    static let night = Color(hex: 0x1F2A3C)
    static let moon = Color(hex: 0xF3E9C8)
}

enum Typo {
    /// 題字・大きな数字・マスの文字：セリフ（日本語は明朝）
    static func title(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// 本文：サンセリフ。Dynamic Type に追従する
    static func body(_ style: Font.TextStyle = .subheadline, _ weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default).weight(weight)
    }

    /// 小さなラベル（字間を開ける）
    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }
}

/// 角丸の段階
enum Radius {
    static let cell: CGFloat = 4
    static let key: CGFloat = 8
    static let plate: CGFloat = 12
    static let card: CGFloat = 16
}

/// 影：普段の木の影と、浮いた羊皮紙の影の 2 種類
extension View {
    func woodShadow() -> some View { shadow(color: .black.opacity(0.35), radius: 6, y: 3) }
    func paperShadow() -> some View { shadow(color: .black.opacity(0.45), radius: 14, y: 8) }
}
