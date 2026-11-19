import StoreKit
import SwiftUI

/// シートの共通の地（暗い木の壁）と見出し
struct SheetFrame<Content: View>: View {
    @Environment(AppModel.self) private var model
    let title: String
    var closeID = "main.closeSheet"
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            WoodWall(lamp: UnitPoint(x: 0.5, y: 0)).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text(title).font(Typo.title(24)).foregroundStyle(Ink.brassSoft)
                    Spacer()
                    RoundBrassButton(systemImage: "xmark", label: tr("閉じる", "Close")) {
                        model.press()
                        model.activeSheet = nil
                    }
                    .accessibilityIdentifier(closeID)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 8)
                ScrollView {
                    content
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        .frame(maxWidth: 600)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

/// 羊皮紙の区切り
struct PaperSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(Typo.label(11)).kerning(1).foregroundStyle(Ink.brassDeep)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Parchment())
    }
}

// MARK: - 設定

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmReset = false

    var body: some View {
        @Bindable var model = model
        SheetFrame(title: tr("設定", "Settings")) {
            VStack(spacing: 14) {
                PaperSection(title: "PRO") {
                    if model.isPro {
                        Label(tr("Pro を使っています。ありがとう！", "You have Pro. Thank you!"), systemImage: "checkmark.seal.fill")
                            .font(Typo.body(.subheadline, .semibold)).foregroundStyle(Ink.ink)
                    } else {
                        Button {
                            model.press()
                            model.activeSheet = .paywall
                        } label: {
                            Label(tr("屋敷のすべての部屋を開く", "Unlock every room of the manor"), systemImage: "key.fill")
                        }
                        .buttonStyle(BrassButtonStyle())
                    }
                }
                PaperSection(title: tr("音と手ざわり", "Sound & touch")) {
                    Toggle(tr("効果音", "Sound effects"), isOn: $model.soundOn)
                    Toggle(tr("振動", "Haptics"), isOn: $model.hapticsOn)
                }
                PaperSection(title: tr("知らせ", "Reminder")) {
                    Toggle(tr("毎晩 21 時に今日の小部屋を知らせる", "Remind me at 9 pm about today's nook"), isOn: Binding(get: { model.reminderOn }, set: { on in
                        Task { await model.setReminder(on) }
                    }))
                    if model.reminderDenied {
                        Text(tr("通知が許可されていません。設定アプリの「通知」から許可できます。", "Notifications are off. You can allow them in the Settings app."))
                            .font(Typo.body(.caption)).foregroundStyle(Ink.wax)
                        Button(tr("設定アプリを開く", "Open Settings")) {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                        .font(Typo.body(.caption, .semibold))
                    }
                }
                PaperSection(title: tr("遊び方", "How to play")) {
                    Button(tr("案内をもう一度見る", "Show the intro again")) { model.replayOnboarding() }
                        .font(Typo.body(.subheadline, .semibold))
                    Text(tr("マスを押すと語を選ぶ。同じマスをもう一度押すと縦と横が切り替わる。印の丸があるマスの文字が、最後の扉の文字盤に入る。", "Tap a square to pick a word. Tap it again to switch between across and down. Letters in squares with a brass circle go on the final door."))
                        .font(Typo.body(.caption)).foregroundStyle(Ink.inkSoft)
                }
                PaperSection(title: tr("記録を消す", "Erase progress")) {
                    Button(tr("記録をすべて消す", "Erase all progress"), role: .destructive) { confirmReset = true }
                        .font(Typo.body(.subheadline, .semibold))
                }
                PaperSection(title: tr("プライバシー", "Privacy")) {
                    Text(tr("記録は端末の中だけに保存し、外に送りません。ログイン・広告・解析はありません。", "Your progress is saved only on this device and never sent anywhere. No login, ads or analytics."))
                        .font(Typo.body(.caption)).foregroundStyle(Ink.inkSoft)
                    Text(trf("バージョン %@", "Version %@", Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"))
                        .font(Typo.body(.caption2)).foregroundStyle(Ink.inkSoft)
                }
            }
            .tint(Ink.brassDeep)
            .foregroundStyle(Ink.ink)
        }
        .confirmationDialog(tr("記録をすべて消しますか？", "Erase all progress?"), isPresented: $confirmReset, titleVisibility: .visible) {
            Button(tr("消す", "Erase"), role: .destructive) { model.resetProgress() }
            Button(tr("やめる", "Cancel"), role: .cancel) {}
        }
    }
}

// MARK: - 課金

struct PaywallView: View {
    @Environment(AppModel.self) private var model
    @State private var buying = false
    @State private var message: String?

    var body: some View {
        SheetFrame(title: "Pro", closeID: "main.closePaywall") {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    ItemGlyph(kind: .key).frame(width: 52, height: 52).rotationEffect(.degrees(-30))
                    Text(tr("屋敷のすべての部屋へ", "Every room of the manor"))
                        .font(Typo.title(26)).foregroundStyle(Ink.brassSoft).multilineTextAlignment(.center)
                    Text(tr("一度の買い切り。サブスクではありません。", "One-time purchase. Not a subscription."))
                        .font(Typo.body(.caption)).foregroundStyle(Ink.onWallSoft)
                }
                .padding(.vertical, 6)
                feature(.telescope, tr("天文室と時計塔の 2 部屋", "Two more rooms: the Observatory and the Clock Tower"), tr("物 8 つ・言葉 32・物語の結末まで", "8 objects, 32 words, and the story's ending"))
                feature(.desk, tr("ヒントの 3 段目「答え」を何度でも", "Unlimited level-3 hints that reveal the answer"), tr("1 文字・意味で詰まっても、先へ進める", "Never stay stuck on a word"))
                feature(.bookshelf, tr("過去 14 日の小部屋をいつでも", "Replay the last 14 days of nooks"), tr("逃した日も、連続の記録とは別に遊べる", "Catch up on days you missed"))
                feature(.chest, tr("これから増える部屋も", "Future rooms included"), tr("追加の部屋は Pro のまま遊べる", "New rooms come free with Pro"))
                buyBlock
                Text(tr("家族共有に対応。購入は App Store の Apple ID で管理されます。", "Family Sharing supported. Purchases are tied to your Apple ID."))
                    .font(Typo.body(.caption2)).foregroundStyle(Ink.onWallSoft).multilineTextAlignment(.center)
            }
        }
    }

    private func feature(_ kind: ObjectKind, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 14) {
            ObjectArt(kind: kind).frame(width: 54, height: 58)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(Typo.body(.subheadline, .semibold)).foregroundStyle(Ink.ink)
                Text(detail).font(Typo.body(.caption)).foregroundStyle(Ink.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Parchment(radius: Radius.plate))
    }

    @ViewBuilder
    private var buyBlock: some View {
        if model.isPro {
            Label(tr("Pro を使っています", "You have Pro"), systemImage: "checkmark.seal.fill")
                .font(Typo.title(18)).foregroundStyle(Ink.brassSoft)
        } else {
            VStack(spacing: 10) {
                switch model.purchases.loadState {
                case .idle, .loading:
                    ProgressView().tint(Ink.brass)
                    Text(tr("値段を読み込んでいます…", "Loading the price…")).font(Typo.body(.caption)).foregroundStyle(Ink.onWallSoft)
                case .unavailable:
                    Text(tr("いまは購入できません。通信を確かめて、もう一度開いてください。", "Purchases aren't available right now. Check your connection and try again."))
                        .font(Typo.body(.caption)).foregroundStyle(Ink.onWall).multilineTextAlignment(.center)
                    Button(tr("もう一度読み込む", "Try again")) { Task { await model.purchases.load() } }
                        .buttonStyle(BrassButtonStyle(prominent: false))
                case .ready:
                    if let product = model.purchases.products.first {
                        Button {
                            Task { await buy(product) }
                        } label: {
                            Text(trf("%@ で Pro にする", "Get Pro for %@", product.displayPrice))
                        }
                        .buttonStyle(BrassButtonStyle())
                        .disabled(buying)
                        .accessibilityIdentifier("main.buy")
                    }
                }
                if let message {
                    Text(message).font(Typo.body(.caption)).foregroundStyle(Ink.onWall)
                }
                Button(tr("購入を復元", "Restore purchase")) {
                    Task {
                        await model.purchases.restore()
                        message = model.isPro ? tr("復元しました", "Restored") : tr("復元できる購入が見つかりません", "No purchase to restore")
                    }
                }
                .font(Typo.body(.subheadline, .semibold))
                .foregroundStyle(Ink.brassSoft)
                .frame(minHeight: 44)
            }
        }
    }

    private func buy(_ product: Product) async {
        buying = true
        let r = await model.purchases.purchase(product)
        buying = false
        switch r {
        case .purchased: message = tr("ありがとう！すべての部屋が開きました", "Thank you! Every room is open")
        case .pending: message = tr("承認を待っています", "Waiting for approval")
        case .cancelled: message = nil
        case .failed: message = tr("購入できませんでした。もう一度お試しください", "The purchase didn't go through. Please try again")
        }
    }
}

// MARK: - 記録

struct RecordsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        SheetFrame(title: tr("記録", "Records"), closeID: "main.closeRecords") {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    stat("\(model.streak)", tr("日つづけて", "day streak"))
                    stat("\(model.progress.roomsEscaped)", tr("部屋から脱出", "rooms escaped"))
                    stat("\(model.progress.wordsSolved)", tr("解いた言葉", "words solved"))
                }
                PaperSection(title: tr("この 4 週間の小部屋", "Nooks, last 4 weeks")) {
                    DayGrid()
                        .frame(height: 120)
                    Text(model.progress.solvedDays.isEmpty ? tr("まだ記録がない。今日の小部屋から始めよう。", "No nooks yet. Start with today's.") : tr("濃いマスは、その日の小部屋から出られた日。", "Filled squares are days you escaped the nook."))
                        .font(Typo.body(.caption)).foregroundStyle(Ink.inkSoft)
                }
                PaperSection(title: tr("屋敷の部屋", "Rooms of the manor")) {
                    ForEach(0..<model.rooms.count, id: \.self) { i in
                        let p = model.roomProgress(i)
                        HStack {
                            Text(model.rooms[i].title).font(Typo.body(.subheadline, .semibold)).foregroundStyle(Ink.ink)
                            Spacer()
                            if p.escaped {
                                StarRow(count: p.stars, color: Ink.brassDeep)
                                Text(p.bestSeconds.map(clockText) ?? "-").font(Typo.body(.caption)).monospacedDigit().foregroundStyle(Ink.inkSoft)
                                Button(tr("もう一度", "Replay")) { model.activeSheet = nil; model.replayRoom(i) }
                                    .font(Typo.body(.caption, .semibold))
                                    .foregroundStyle(Ink.brassDeep)
                            } else {
                                Text(trf("文字盤 %d / 4", "Dials %d / 4", p.solvedCount)).font(Typo.body(.caption)).foregroundStyle(Ink.inkSoft)
                            }
                        }
                        .frame(minHeight: 32)
                    }
                }
                PaperSection(title: tr("過去の小部屋（Pro）", "Past nooks (Pro)")) {
                    ForEach(1..<15, id: \.self) { offset in
                        let date = model.calendar.date(byAdding: .day, value: -offset, to: model.now) ?? model.now
                        let r = model.dailyResult(date)
                        Button {
                            model.startDaily(dayOffset: offset)
                        } label: {
                            HStack {
                                Text(date.formatted(.dateTime.month().day().locale(Lang.locale))).font(Typo.body(.caption)).monospacedDigit().foregroundStyle(Ink.inkSoft).frame(width: 60, alignment: .leading)
                                Text(model.daily(for: date).title).font(Typo.body(.subheadline)).foregroundStyle(Ink.ink)
                                Spacer()
                                if r?.solved == true {
                                    StarRow(count: r?.stars ?? 0, color: Ink.brassDeep)
                                } else if !model.isPro {
                                    PadlockShape().fill(Ink.brassDeep).frame(width: 11, height: 14)
                                } else {
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Ink.brassDeep)
                                }
                            }
                            .frame(minHeight: 34)
                        }
                    }
                }
            }
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Typo.title(30, .bold)).monospacedDigit().kerning(-1).foregroundStyle(Ink.ink)
            Text(label).font(Typo.label(10)).foregroundStyle(Ink.inkSoft).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Parchment(radius: Radius.plate))
    }
}

/// 4 週間のマス（Canvas。濃さで解けた日と星）
struct DayGrid: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let days = model.progress.solvedDays
        let keys: [String] = (0..<28).map { i in
            let d = model.calendar.date(byAdding: .day, value: -(27 - i), to: model.now) ?? model.now
            return Progress.dayKey(d, calendar: model.calendar)
        }
        Canvas { ctx, size in
            let gap: CGFloat = 4
            let side = min((size.width - gap * 6) / 7, (size.height - gap * 3) / 4)
            for (i, k) in keys.enumerated() {
                let r = CGRect(x: CGFloat(i % 7) * (side + gap), y: CGFloat(i / 7) * (side + gap), width: side, height: side)
                let solved = days.contains(k)
                ctx.fill(Path(roundedRect: r, cornerRadius: 4), with: .color(solved ? Ink.brassDeep : Ink.paperDeep.opacity(0.6)))
                if i == keys.count - 1 {
                    ctx.stroke(Path(roundedRect: r.insetBy(dx: 1, dy: 1), cornerRadius: 4), with: .color(Ink.ink), lineWidth: 1.5)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(trf("この 4 週間で %d 日", "%d days in the last 4 weeks", keys.filter { days.contains($0) }.count))
    }
}

// MARK: - 共有

struct ShareSheet: View {
    @Environment(AppModel.self) private var model
    @State private var image: Image?

    var body: some View {
        SheetFrame(title: tr("共有", "Share")) {
            VStack(spacing: 16) {
                ShareCard()
                    .frame(width: 320, height: 420)
                if let image {
                    ShareLink(item: image, preview: SharePreview(tr("カギことば", "Lockword"), image: image)) {
                        Label(tr("画像を共有", "Share the image"), systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(BrassButtonStyle())
                }
                Text(tr("答えは書かれないので、友だちにも安心して見せられる。", "No answers are shown, so it's safe to share."))
                    .font(Typo.body(.caption)).foregroundStyle(Ink.onWallSoft)
            }
        }
        .task {
            let renderer = ImageRenderer(content: ShareCard().environment(model).frame(width: 320, height: 420))
            renderer.scale = 3
            if let ui = renderer.uiImage { image = Image(uiImage: ui) }
        }
    }
}

/// 共有カード：扉と封蝋、時間と星。答えの言葉は出さない
struct ShareCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            WoodWall(lamp: UnitPoint(x: 0.5, y: 0.1))
            VStack(spacing: 14) {
                Text(tr("カギことば", "Lockword")).font(Typo.title(26, .bold)).foregroundStyle(Ink.brassSoft)
                DoorArt(letters: [nil, nil, nil, nil], items: [], open: true).frame(width: 110, height: 160)
                    .overlay(WaxSeal().frame(width: 54, height: 54).offset(y: 30))
                Text(title).font(Typo.title(20)).foregroundStyle(Ink.onWall).multilineTextAlignment(.center)
                HStack(spacing: 14) {
                    Text(clockText(seconds)).font(Typo.title(22, .medium)).monospacedDigit().foregroundStyle(Ink.brassSoft)
                    StarRow(count: stars, size: 16)
                }
                Text(trf("%d 日つづけて脱出", "%d-day streak", model.streak)).font(Typo.label(12)).foregroundStyle(Ink.onWallSoft)
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private var title: String {
        switch model.result {
        case .room(let r): trf("「%@」から脱出", "Escaped “%@”", model.rooms[r].title)
        default: trf("「%@」から脱出", "Escaped “%@”", model.currentDaily.title)
        }
    }

    private var seconds: Int {
        switch model.result {
        case .room(let r): model.roomProgress(r).seconds
        default: model.dailyResult(model.dailyDate)?.seconds ?? 0
        }
    }

    private var stars: Int {
        switch model.result {
        case .room(let r): model.roomProgress(r).stars
        default: model.dailyResult(model.dailyDate)?.stars ?? 0
        }
    }
}
