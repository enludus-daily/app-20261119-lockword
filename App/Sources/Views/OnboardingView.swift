import SwiftUI

/// 最初の案内（3 ページ。自前のページ送り：TabView(.page) は撮影で黒い丸が出るので使わない）
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private var pages: [(String, String)] {
        [
            (tr("閉じこめられた", "Locked in"), tr("夜の古い屋敷。扉には文字盤があり、鍵はどこにもない。", "An old manor at night. The door has letter dials, and there is no key.")),
            (tr("物にクロスワード", "A crossword in every object"), tr("肖像画、長持ち、柱時計。部屋の物それぞれに、小さなクロスワードが刻まれている。", "A portrait, a chest, a clock. Each object hides a tiny crossword.")),
            (tr("答えが道具になる", "Answers become tools"), tr("「カギ」を解けば鍵が手に入り、次の物が開く。印のマスの文字を集めて、扉を開けよう。", "Solve KEY and you get a key that opens the next object. Collect the marked letters to open the door.")),
        ]
    }

    var body: some View {
        ZStack {
            WoodWall(lamp: UnitPoint(x: 0.5, y: 0.1), floorRatio: 0.18).ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer(minLength: 10)
                illustration
                    .frame(height: 230)
                    .id(page)
                    .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                VStack(spacing: 10) {
                    Text(pages[page].0)
                        .font(Typo.title(28))
                        .foregroundStyle(Ink.brassSoft)
                        .multilineTextAlignment(.center)
                    Text(pages[page].1)
                        .font(Typo.body(.body))
                        .foregroundStyle(Ink.onWall)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if page == 2 {
                        Text(tr("記録は端末の中だけに残り、外に送らない。", "Your progress stays on this device. Nothing is sent anywhere."))
                            .font(Typo.body(.caption))
                            .foregroundStyle(Ink.onWallSoft)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 28)
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule().fill(i == page ? Ink.brass : Ink.grain).frame(width: i == page ? 22 : 8, height: 8)
                    }
                }
                .accessibilityHidden(true)
                Spacer(minLength: 10)
            }
            .frame(maxWidth: 560)
            .safeAreaInset(edge: .bottom) {
                Group {
                    if page < pages.count - 1 {
                        Button(tr("つぎへ", "Next")) {
                            model.press()
                            withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.85)) { page += 1 }
                        }
                        .accessibilityIdentifier("main.onboardingNext")
                    } else {
                        Button(tr("第一の部屋へ", "Enter the first room")) { model.finishOnboarding() }
                            .accessibilityIdentifier("main.start")
                    }
                }
                .buttonStyle(BrassButtonStyle())
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .frame(maxWidth: 520)
            }
        }
    }

    @ViewBuilder
    private var illustration: some View {
        switch page {
        case 0:
            HStack(alignment: .bottom, spacing: 18) {
                ObjectArt(kind: .clock).frame(width: 70, height: 170)
                DoorArt(letters: [nil, nil, nil, nil], items: [(.candle, false), (.lens, false)]).frame(width: 120, height: 210)
                ObjectArt(kind: .painting).frame(width: 90, height: 100).padding(.bottom, 80)
            }
        case 1:
            VStack(spacing: 12) {
                ObjectArt(kind: .painting).frame(width: 110, height: 110)
                MiniGrid(word: Lang.isJapanese ? ["カ", "ギ"] : ["K", "E", "Y"], filled: 1)
            }
        default:
            HStack(spacing: 8) {
                MiniGrid(word: Lang.isJapanese ? ["カ", "ギ"] : ["K", "E", "Y"], filled: 3)
                Image(systemName: "arrow.right").font(.title2).foregroundStyle(Ink.brass)
                ItemGlyph(kind: .key).frame(width: 46, height: 46)
                    .padding(10)
                    .background(Circle().fill(Ink.deep.opacity(0.8)))
                Image(systemName: "arrow.right").font(.title2).foregroundStyle(Ink.brass)
                ObjectArt(kind: .chest, solved: true).frame(width: 64, height: 64)
            }
        }
    }
}

/// 案内の見本のマス
struct MiniGrid: View {
    let word: [String]
    let filled: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(word.enumerated()), id: \.offset) { i, l in
                Text(i < filled ? l : "")
                    .font(Typo.title(24, .bold))
                    .foregroundStyle(Ink.ink)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: Radius.cell).fill(i < filled ? Ink.solved : Ink.paper))
                    .overlay(RoundedRectangle(cornerRadius: Radius.cell).strokeBorder(i == filled ? Ink.brassDeep : Ink.inkSoft.opacity(0.35), lineWidth: i == filled ? 2.5 : 0.8))
            }
        }
        .padding(8)
        .background(Parchment(radius: Radius.plate))
        .accessibilityHidden(true)
    }
}
