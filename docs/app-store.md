# App Store 提出の準備

> 名前・説明・キーワードなどの正本は `docs/app-store.json`（`.github/workflows/asc.yml` の metadata が App Store Connect に API で入れる）。ここは審査の危険と、本人がすることの記録。

| 項目 | 内容 |
|---|---|
| Bundle ID | com.enludus.daily.014 |
| アプリ名 | カギことば / Lockword（App Store 名：カギことば：クロスワード脱出 / Lockword: Crossword Escape）（AI が決めた。本人の許可 2026-11-04） |
| サポート URL | https://github.com/enludus-daily/app-20261119-lockword/issues |
| プライバシーポリシー URL | https://github.com/enludus-daily/app-20261119-lockword/blob/main/PRIVACY.md |
| 年齢区分の答え | すべて「なし」の想定（暴力なし・ギャンブルなし〔賭け・お金のやりとりなし〕・Web 閲覧なし・生成 AI なし・ユーザー間のやりとりなし）→ 4+。本人が入力 |
| 輸出コンプライアンス | `ITSAppUsesNonExemptEncryption = NO`（標準の暗号だけ。ビルドの答えは asc が NO で入れる） |

## 審査の危険

- 4.3(b) の種類に当たらない理由：クロスワードと脱出ゲームを組み合わせたゲーム。懐中電灯・占い・単純なタイマーなどではない
- 既存のアプリとの意味のある違い：言葉を打って進む脱出ゲーム（Escape Room: Mystery Word など）は答えを打つと次の画面へ進むだけ。ここは部屋の物ごとに交わりのあるクロスワードがあり、**答えの言葉が道具になって別の物の錠を開け**、盤の印の文字を集めて扉の言葉を組み立てる
- 長く使える価値（4.2）：今日の小部屋（毎日・全員同じ）と続けた日数・屋敷 4 部屋の物語・日本語と英語で別に作った 228 語
- 他社の名前・商標・見た目を使っていないか：特定の脱出ゲーム・新聞のクロスワードの名前や見た目を使わない。絵・アイコンは自作の図形
- Apple Intelligence を使う場合、使えない端末での動き：使わない
- 通知：今日の小部屋の知らせ（設定でオンにしたときだけ許可を求める。端末の中の予定通知で、通信しない）

## 収益の道筋（本人が選ぶ）

- 買い切り Pro ¥480（StoreKit 2。`com.enludus.daily.014.pro`。asc.yml の products で作る）
- 理由と勝算の表：README の「課金」

## App プライバシーの答え（下書き。申告は本人。公開 API がない）

- データの収集：**なし**（根拠：通信しない、解析・広告 SDK なし、保存は端末の UserDefaults だけ）
- トラッキング：なし
- Privacy manifest：`App/Resources/PrivacyInfo.xcprivacy`（UserDefaults: CA92.1）

## スクリーンショット

CI の artifact `screenshots`（iPhone Duo のシミュレータ）。足りない画面は本人と相談。

## 本人がすること

- [ ] App プライバシーを申告する（API がない）
- [ ] 年齢区分を答える
- [ ] TestFlight で動作を確かめる（内部テストのグループ `daily-internal` に自動で配信される）
- [ ] スクリーンショットを確かめる
- [ ] 審査に提出する
