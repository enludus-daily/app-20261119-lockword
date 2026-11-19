import SwiftUI

/// 広間：今日の小部屋と、屋敷の 4 つの部屋の扉
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ZStack {
            WoodWall(lamp: UnitPoint(x: 0.25, y: 0.05)).ignoresSafeArea()
            Group {
                if sizeClass == .regular {
                    HStack(alignment: .top, spacing: 24) {
                        VStack(spacing: 18) {
                            emblem
                            TodayCard()
                            Spacer()
                        }
                        .frame(maxWidth: 420)
                        ScrollView { roomList.padding(.bottom, 20) }
                            .frame(maxWidth: 520)
                    }
                    .padding(24)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            emblem
                            TodayCard()
                            roomList
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { mainButton }
        }
    }

    private var emblem: some View {
        VStack(spacing: 6) {
            HStack {
                RoundBrassButton(systemImage: "chart.bar.doc.horizontal", label: tr("記録", "Records")) {
                    model.press()
                    model.activeSheet = .records
                }
                .accessibilityIdentifier("main.records")
                Spacer()
                RoundBrassButton(systemImage: "gearshape", label: tr("設定", "Settings")) {
                    model.press()
                    model.activeSheet = .settings
                }
                .accessibilityIdentifier("main.settings")
            }
            ItemGlyph(kind: .key)
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-30))
            Text(tr("カギことば", "Lockword"))
                .font(Typo.title(38, .bold))
                .kerning(Lang.isJapanese ? 2 : -1)
                .foregroundStyle(Ink.brassSoft)
            Text(tr("言葉で開ける、夜の屋敷", "Solve the words. Open the doors."))
                .font(Typo.label(12))
                .kerning(1)
                .foregroundStyle(Ink.onWallSoft)
        }
        .padding(.top, 6)
    }

    private var roomList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("屋敷の部屋", "Rooms of the manor"))
                .font(Typo.label(12)).kerning(1)
                .foregroundStyle(Ink.brass)
            ForEach(0..<model.rooms.count, id: \.self) { i in
                RoomRow(index: i)
            }
            Text(tr("部屋の物に刻まれたクロスワードを解くと、答えの言葉が道具になる。", "Every object hides a crossword. Each answer becomes a tool."))
                .font(Typo.body(.caption))
                .foregroundStyle(Ink.onWallSoft)
                .padding(.top, 4)
        }
    }

    /// 下に固定：今日の小部屋（解けていたら、続きの部屋へ）
    private var mainButton: some View {
        let solvedToday = model.todayResult?.solved == true
        let next = model.rooms.indices.first { !model.roomProgress($0).escaped && !model.isRoomLocked($0) }
        return VStack(spacing: 0) {
            if solvedToday, let next {
                Button(trf("%@の続きへ", "Continue: %@", model.rooms[next].title)) { model.enterRoom(next) }
                    .buttonStyle(BrassButtonStyle())
                    .accessibilityIdentifier("main.continue")
            } else {
                Button(solvedToday ? tr("今日の小部屋をもう一度見る", "Review today's nook") : tr("今日の小部屋をひらく", "Open today's nook")) { model.startDaily() }
                    .buttonStyle(BrassButtonStyle())
                    .accessibilityIdentifier("main.daily")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .background(LinearGradient(colors: [Ink.deep.opacity(0), Ink.deep.opacity(0.9)], startPoint: .top, endPoint: .center).allowsHitTesting(false))
    }
}

/// 今日の小部屋の札
struct TodayCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let daily = model.daily(for: model.now)
        let result = model.todayResult
        Button { model.startDaily() } label: {
            HStack(spacing: 14) {
                ObjectArt(kind: daily.kind, solved: result?.solved == true)
                    .frame(width: 70, height: 76)
                VStack(alignment: .leading, spacing: 4) {
                    Text(trf("今日の小部屋・%@", "Today's nook · %@", model.now.formatted(.dateTime.month().day().locale(Lang.locale))))
                        .font(Typo.label(11)).kerning(0.6)
                        .foregroundStyle(Ink.brassDeep)
                    Text(daily.title).font(Typo.title(21)).foregroundStyle(Ink.ink)
                    if let result, result.solved {
                        HStack(spacing: 8) {
                            StarRow(count: result.stars, color: Ink.brassDeep)
                            Text(clockText(result.seconds)).font(Typo.body(.caption)).monospacedDigit().foregroundStyle(Ink.inkSoft)
                            Text(tr("脱出ずみ", "Escaped")).font(Typo.label(10)).foregroundStyle(Ink.brassDeep)
                        }
                    } else {
                        Text(trf("%d 語のクロスワード・5 分ほど", "%d-word crossword · about 5 min", daily.puzzle.entries.count))
                            .font(Typo.body(.caption)).foregroundStyle(Ink.inkSoft)
                    }
                }
                Spacer(minLength: 0)
                VStack(spacing: 2) {
                    ItemGlyph(kind: .candle).frame(width: 26, height: 26)
                    Text("\(model.streak)")
                        .font(Typo.title(24, .bold)).monospacedDigit()
                        .foregroundStyle(Ink.ink)
                        .contentTransition(.numericText())
                    Text(tr("日つづけて", "day streak")).font(Typo.label(9)).foregroundStyle(Ink.inkSoft)
                }
                .accessibilityElement(children: .combine)
            }
            .padding(16)
            .background(Parchment())
            .paperShadow()
        }
        .buttonStyle(PressStyle())
    }
}

/// 部屋の扉の行
struct RoomRow: View {
    @Environment(AppModel.self) private var model
    let index: Int

    var body: some View {
        let room = model.rooms[index]
        let p = model.roomProgress(index)
        let locked = model.isRoomLocked(index)
        Button { model.enterRoom(index) } label: {
            HStack(spacing: 14) {
                DoorArt(letters: room.final.indices.map { i in p.escaped ? Optional(room.final[i]) : (p.object(i).solved ? room.objects[i].puzzle.markLetter : nil) }, items: [], open: p.escaped)
                    .frame(width: 54, height: 78)
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.subtitle).font(Typo.label(10)).kerning(0.8).foregroundStyle(Ink.brass)
                    Text(room.title).font(Typo.title(19)).foregroundStyle(Ink.onWall)
                    if p.escaped {
                        HStack(spacing: 8) {
                            StarRow(count: p.stars)
                            if let best = p.bestSeconds {
                                Text(trf("最速 %@", "Best %@", clockText(best))).font(Typo.body(.caption)).monospacedDigit().foregroundStyle(Ink.onWallSoft)
                            }
                        }
                    } else if locked {
                        Text(tr("Pro で開く・物 4 つ、言葉 16", "Opens with Pro · 4 objects, 16 words")).font(Typo.body(.caption)).foregroundStyle(Ink.onWallSoft)
                    } else {
                        Text(p.solvedCount == 0 ? tr("物 4 つ、言葉 16・10〜15 分", "4 objects, 16 words · 10–15 min") : trf("文字盤 %d / 4・%@", "Dials %d / 4 · %@", p.solvedCount, clockText(p.seconds)))
                            .font(Typo.body(.caption)).monospacedDigit().foregroundStyle(Ink.onWallSoft)
                    }
                }
                Spacer(minLength: 0)
                if locked {
                    PadlockShape().fill(Ink.brass).frame(width: 18, height: 23)
                } else {
                    Image(systemName: "chevron.right").foregroundStyle(Ink.brass)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Ink.deep.opacity(0.75)))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Ink.brassDeep.opacity(0.6), lineWidth: 1))
        }
        .buttonStyle(PressStyle())
        .accessibilityIdentifier("room\(index)")
    }
}

/// 今日の小部屋：盤だけの小さな部屋
struct DailyView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ZStack {
            WoodWall(lamp: UnitPoint(x: 0.5, y: 0.0)).ignoresSafeArea()
            if let board = model.board {
                let daily = model.currentDaily
                let sub = model.dailyDayOffset == 0 ? tr("今日の小部屋", "Today's nook") : model.dailyDate.formatted(.dateTime.month().day().locale(Lang.locale))
                Group {
                    if sizeClass == .regular {
                        HStack(spacing: 24) {
                            VStack(spacing: 16) {
                                ObjectArt(kind: daily.kind, solved: board.isComplete).frame(width: 220, height: 240)
                                Text(daily.title).font(Typo.title(26)).foregroundStyle(Ink.onWall)
                                Text(tr("5 つの言葉を埋めると、小部屋の箱が開く。", "Fill all five words to open the little box."))
                                    .font(Typo.body(.subheadline)).foregroundStyle(Ink.onWallSoft).multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: 360)
                            BoardPanel(board: board, title: daily.title, subtitle: sub, closeID: "main.closeDaily").frame(maxWidth: 560)
                        }
                        .padding(20)
                    } else {
                        BoardPanel(board: board, title: daily.title, subtitle: sub, closeID: "main.closeDaily")
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                }
                .accessibilityHidden(model.result != nil)
            }
            if model.result == .daily {
                ResultView(kind: .daily)
                    .transition(.opacity)
                    .zIndex(3)
            }
        }
    }
}
