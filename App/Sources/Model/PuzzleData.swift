// このファイルは scripts/build-puzzles.py が content/*.json から作る。手で直さない。
// 言葉・カギ・ヒント・物語は手で書いたもの。盤の並べ方（交わる位置）だけを自動で決めている。

import Foundation

enum PuzzleData {
    static let japaneseRooms: [Room] = [
        Room(id: "study", title: "伯爵の書斎", subtitle: "第一の部屋", intro: "目をさますと、ランプが一つだけ灯る書斎にいた。扉には四つの文字盤。壁の物たちに、小さなクロスワードが刻まれている。", outro: "最後の文字がそろうと、扉の錠がひとりでに外れた。廊下の奥で、蓄音機が鳴りはじめる。",
             final: ["ハ", "ジ", "マ", "リ"], finalClue: "物語はここから。最初の一歩", objects: [
            RoomObject(kind: .painting, name: "伯爵の肖像画", note: "額縁の裏に、何かが隠されている", requires: nil, gives: .key, puzzle: Crossword(rows: 4, cols: 6, entries: [
                Entry(number: 2, row: 0, col: 4, across: true, answer: ["カ", "ギ"], clue: "扉や錠前を開ける金属の道具", hint: "錠前に差しこんで回す"),
                Entry(number: 2, row: 0, col: 4, across: false, answer: ["カ", "ク", "ス"], clue: "人に見えないようにしまう", hint: "宝物を○○○"),
                Entry(number: 1, row: 0, col: 1, across: false, answer: ["ガ", "ク", "ブ", "チ"], clue: "絵のまわりを囲む枠", hint: "額と縁、と書く"),
                Entry(number: 3, row: 1, col: 0, across: true, answer: ["ハ", "ク", "シ", "ヤ", "ク"], clue: "貴族の位の一つ。この屋敷のあるじ", hint: "公・侯・○・子・男の三番目"),
            ], itemEntry: 0, mark: Cell(row: 1, col: 0))),
            RoomObject(kind: .chest, name: "鍵のかかった長持ち", note: "古い錠前。鍵があれば開きそうだ", requires: .key, gives: .candle, puzzle: Crossword(rows: 5, cols: 7, entries: [
                Entry(number: 1, row: 0, col: 0, across: true, answer: ["ロ", "ウ", "ソ", "ク"], clue: "火をともす、ろうの棒", hint: "誕生日のケーキに立てる"),
                Entry(number: 2, row: 0, col: 3, across: false, answer: ["ク", "ラ", "ヤ", "ミ"], clue: "光のない、まっ暗な所", hint: "○○○○でろうそくを灯す"),
                Entry(number: 3, row: 2, col: 5, across: false, answer: ["ジ", "シ", "ヨ"], clue: "言葉の意味を調べる本", hint: "国語○○、英和○○"),
                Entry(number: 4, row: 3, col: 3, across: true, answer: ["ミ", "ツ", "シ", "ツ"], clue: "外から入れず、出られない部屋", hint: "○○○○の謎"),
            ], itemEntry: 0, mark: Cell(row: 2, col: 5))),
            RoomObject(kind: .bookshelf, name: "天井までの本棚", note: "一冊だけ、背表紙が逆さまだ", requires: nil, gives: .gear, puzzle: Crossword(rows: 3, cols: 7, entries: [
                Entry(number: 1, row: 0, col: 0, across: true, answer: ["ハ", "グ", "ル", "マ"], clue: "歯のついた車。時計の中でかみ合って回る", hint: "機械の中の、ぎざぎざの輪"),
                Entry(number: 3, row: 0, col: 3, across: false, answer: ["マ", "ド"], clue: "光や風を入れる、壁の開いた所", hint: "○○ガラス"),
                Entry(number: 4, row: 1, col: 3, across: true, answer: ["ド", "ク", "シ", "ヨ"], clue: "本を読むこと", hint: "秋は○○○○の季節"),
                Entry(number: 2, row: 0, col: 1, across: false, answer: ["グ", "リ", "ム"], clue: "昔話を集めたドイツの兄弟", hint: "『白雪姫』『ヘンゼルとグレーテル』"),
            ], itemEntry: 0, mark: Cell(row: 0, col: 3))),
            RoomObject(kind: .desk, name: "伯爵の机", note: "引き出しに歯車の形のくぼみがある", requires: .gear, gives: .lens, puzzle: Crossword(rows: 5, cols: 6, entries: [
                Entry(number: 1, row: 0, col: 3, across: false, answer: ["ム", "シ", "メ", "ガ", "ネ"], clue: "小さな字を大きく見せる、柄のついたレンズ", hint: "探偵の道具"),
                Entry(number: 3, row: 2, col: 3, across: true, answer: ["メ", "モ"], clue: "忘れないように書きとめた短い文", hint: "○○帳"),
                Entry(number: 2, row: 1, col: 0, across: true, answer: ["ヒ", "キ", "ダ", "シ"], clue: "机の、引いて開ける箱", hint: "四次元○○○○"),
                Entry(number: 4, row: 4, col: 3, across: true, answer: ["ネ", "ム", "リ"], clue: "ねむること。この屋敷は長い○○○の中", hint: "○○○姫"),
            ], itemEntry: 0, mark: Cell(row: 4, col: 5))),
        ]),
        Room(id: "music", title: "月夜の音楽室", subtitle: "第二の部屋", intro: "廊下の先は音楽室。蓄音機が同じ小節をくり返している。扉の錠は、四つの音の文字で開くらしい。", outro: "文字盤が鳴り、扉が開いた。階段の上から、星の光が差しこんでいる。",
             final: ["カ", "ナ", "デ", "ル"], finalClue: "楽器を鳴らして、音楽を○○○○", objects: [
            RoomObject(kind: .gramophone, name: "止まらない蓄音機", note: "ラッパの奥で、何かが光った", requires: nil, gives: .ring, puzzle: Crossword(rows: 5, cols: 5, entries: [
                Entry(number: 1, row: 0, col: 1, across: true, answer: ["ユ", "ビ", "ワ"], clue: "指にはめる輪の飾り", hint: "結婚のしるしに贈る"),
                Entry(number: 2, row: 0, col: 3, across: false, answer: ["ワ", "ル", "ツ"], clue: "三拍子のおどりの曲", hint: "ズン・チャッ・チャ"),
                Entry(number: 4, row: 2, col: 1, across: false, answer: ["ル", "ビ", "ー"], clue: "赤くかがやく宝石", hint: "七月の誕生石"),
                Entry(number: 3, row: 2, col: 0, across: true, answer: ["カ", "ル", "テ", "ツ", "ト"], clue: "四人で演奏する組", hint: "弦楽○○○○○"),
            ], itemEntry: 0, mark: Cell(row: 2, col: 0))),
            RoomObject(kind: .safe, name: "壁の金庫", note: "ダイヤルに、指輪の形の刻印", requires: .ring, gives: .coin, puzzle: Crossword(rows: 4, cols: 5, entries: [
                Entry(number: 3, row: 0, col: 4, across: false, answer: ["コ", "イ", "ン"], clue: "金属のお金。ここでは仕掛けを動かす", hint: "○○ロッカー"),
                Entry(number: 1, row: 0, col: 0, across: false, answer: ["ナ", "ン", "バ", "ー"], clue: "番号。金庫を開ける数", hint: "背中の○○○○"),
                Entry(number: 4, row: 2, col: 0, across: true, answer: ["バ", "イ", "オ", "リ", "ン"], clue: "あごにはさんで弓でひく楽器", hint: "弦楽器の花形"),
                Entry(number: 2, row: 0, col: 2, across: true, answer: ["キ", "ン", "コ"], clue: "大事な物をしまう鉄の箱", hint: "銀行の○○○"),
            ], itemEntry: 0, mark: Cell(row: 0, col: 0))),
            RoomObject(kind: .fireplace, name: "冷えた暖炉", note: "灰の中に、金属のきらめき", requires: nil, gives: .key, puzzle: Crossword(rows: 3, cols: 3, entries: [
                Entry(number: 1, row: 0, col: 0, across: false, answer: ["カ", "ギ"], clue: "暖炉の灰から出てきた、ねじ巻きの○○", hint: "時計にも差しこむ金属の道具"),
                Entry(number: 1, row: 0, col: 0, across: true, answer: ["カ", "エ", "デ"], clue: "秋に赤くなる、手の形の葉の木", hint: "メープルシロップの木"),
                Entry(number: 2, row: 0, col: 2, across: false, answer: ["デ", "ン", "キ"], clue: "明かりをともす力。今夜は止まっている", hint: "○○○をつける"),
                Entry(number: 3, row: 2, col: 1, across: true, answer: ["マ", "キ"], clue: "暖炉で燃やす木", hint: "○○割り"),
            ], itemEntry: 0, mark: Cell(row: 0, col: 2))),
            RoomObject(kind: .clock, name: "柱時計", note: "ねじ巻きの穴がある。止まったままだ", requires: .key, gives: .gear, puzzle: Crossword(rows: 4, cols: 5, entries: [
                Entry(number: 1, row: 0, col: 0, across: true, answer: ["ハ", "グ", "ル", "マ"], clue: "時計の中でかみ合う、歯のある輪", hint: "機械の、ぎざぎざの車"),
                Entry(number: 1, row: 0, col: 0, across: false, answer: ["ハ", "リ"], clue: "時刻を指す細い棒", hint: "長い○○と短い○○"),
                Entry(number: 2, row: 0, col: 3, across: false, answer: ["マ", "ヨ", "ナ", "カ"], clue: "夜の十二時ごろ", hint: "○○○○の鐘が鳴る"),
                Entry(number: 3, row: 3, col: 2, across: true, answer: ["ジ", "カ", "ン"], clue: "時計がはかるもの", hint: "○○○割り"),
            ], itemEntry: 0, mark: Cell(row: 0, col: 2))),
        ]),
        Room(id: "observatory", title: "屋根裏の天文室", subtitle: "第三の部屋", intro: "丸い天窓の下に、望遠鏡と地球儀。扉の文字盤には、星の形の印が四つ。", outro: "四つの星が灯り、天窓がゆっくり開いた。遠くで、時計塔の鐘が鳴る。",
             final: ["ホ", "シ", "ゾ", "ラ"], finalClue: "夜に見上げる、星でいっぱいの空", objects: [
            RoomObject(kind: .telescope, name: "真鍮の望遠鏡", note: "筒の中に、丸めた紙が入っている", requires: nil, gives: .map, puzzle: Crossword(rows: 5, cols: 7, entries: [
                Entry(number: 2, row: 1, col: 2, across: true, answer: ["チ", "ズ"], clue: "土地や星の位置を描いた図", hint: "宝の○○"),
                Entry(number: 3, row: 1, col: 3, across: false, answer: ["ズ", "カ", "ン"], clue: "絵や写真で調べる本", hint: "昆虫○○○"),
                Entry(number: 1, row: 0, col: 0, across: false, answer: ["ホ", "ウ", "キ", "ボ", "シ"], clue: "長い尾を引く星", hint: "すい星のこと"),
                Entry(number: 4, row: 3, col: 0, across: true, answer: ["ボ", "ウ", "エ", "ン", "キ", "ヨ", "ウ"], clue: "遠くの物を大きく見る筒", hint: "天体○○○○○○○"),
            ], itemEntry: 0, mark: Cell(row: 0, col: 0))),
            RoomObject(kind: .globe, name: "動かない地球儀", note: "台に、地図をはめるくぼみがある", requires: .map, gives: .compass, puzzle: Crossword(rows: 4, cols: 5, entries: [
                Entry(number: 4, row: 3, col: 0, across: true, answer: ["ラ", "シ", "ン", "バ", "ン"], clue: "北を指す針の道具", hint: "船乗りのコンパス"),
                Entry(number: 2, row: 1, col: 3, across: true, answer: ["シ", "マ"], clue: "海にかこまれた陸", hint: "宝○○"),
                Entry(number: 3, row: 2, col: 1, across: false, answer: ["ニ", "シ"], clue: "太陽が沈む方角", hint: "東の反対"),
                Entry(number: 1, row: 0, col: 4, across: false, answer: ["ア", "マ", "ゾ", "ン"], clue: "南アメリカの大きな川", hint: "流域が世界一広い川"),
            ], itemEntry: 0, mark: Cell(row: 1, col: 3))),
            RoomObject(kind: .bookshelf, name: "星図の棚", note: "棚の奥に、小さな鍵がぶら下がっている", requires: nil, gives: .key, puzzle: Crossword(rows: 4, cols: 5, entries: [
                Entry(number: 1, row: 0, col: 0, across: true, answer: ["カ", "ギ"], clue: "棚の奥にかかっていた、小さな○○", hint: "錠前に差しこんで回す"),
                Entry(number: 2, row: 0, col: 1, across: false, answer: ["ギ", "ン", "ガ"], clue: "無数の星の集まり", hint: "○○○鉄道の夜"),
                Entry(number: 3, row: 2, col: 0, across: true, answer: ["ナ", "ガ", "レ", "ボ", "シ"], clue: "夜空をすっと横切る光", hint: "消える前に願いごと"),
                Entry(number: 3, row: 2, col: 0, across: false, answer: ["ナ", "ゾ"], clue: "わからないこと。解くもの", hint: "○○解き"),
            ], itemEntry: 0, mark: Cell(row: 3, col: 0))),
            RoomObject(kind: .chest, name: "天文学者の箱", note: "鍵穴が星の形をしている", requires: .key, gives: .candle, puzzle: Crossword(rows: 4, cols: 6, entries: [
                Entry(number: 2, row: 2, col: 2, across: true, answer: ["ロ", "ウ", "ソ", "ク"], clue: "火をともす、ろうの棒", hint: "停電のときに灯す"),
                Entry(number: 1, row: 0, col: 2, across: false, answer: ["オ", "ー", "ロ", "ラ"], clue: "北の空にゆれる光のカーテン", hint: "北極の近くで見える"),
                Entry(number: 3, row: 2, col: 4, across: false, answer: ["ソ", "ラ"], clue: "頭の上に広がる所", hint: "青い○○"),
                Entry(number: 4, row: 3, col: 0, across: true, answer: ["ヨ", "ゾ", "ラ"], clue: "夜の空", hint: "星がまたたく○○○"),
            ], itemEntry: 0, mark: Cell(row: 3, col: 4))),
        ]),
        Room(id: "tower", title: "時計塔の最上階", subtitle: "第四の部屋", intro: "巨大な文字盤の裏側。歯車がきしみ、針は真夜中の手前で止まっている。最後の扉の先は、外の世界だ。", outro: "鐘が十二回鳴った。扉の向こうに、夜明け前の町が広がっている。屋敷の外へ出られた。",
             final: ["エ", "イ", "エ", "ン"], finalClue: "終わりのない、いつまでも続く時", objects: [
            RoomObject(kind: .clock, name: "大時計の裏側", note: "歯車が一つ、外れかけている", requires: nil, gives: .gear, puzzle: Crossword(rows: 4, cols: 5, entries: [
                Entry(number: 2, row: 2, col: 0, across: true, answer: ["ハ", "グ", "ル", "マ"], clue: "かみ合って回る、歯のある輪", hint: "機械の、ぎざぎざの車"),
                Entry(number: 1, row: 0, col: 3, across: false, answer: ["ゼ", "ン", "マ", "イ"], clue: "巻くと力をためる、うず巻きのばね", hint: "○○○○じかけのおもちゃ"),
                Entry(number: 3, row: 3, col: 3, across: true, answer: ["イ", "エ"], clue: "人が住む建物", hint: "○○路につく"),
                Entry(number: 2, row: 2, col: 0, across: false, answer: ["ハ", "リ"], clue: "時計の時刻を指す棒", hint: "秒○○"),
            ], itemEntry: 0, mark: Cell(row: 3, col: 4))),
            RoomObject(kind: .chest, name: "時計職人の箱", note: "ふたに歯車をはめる穴がある", requires: .gear, gives: .ring, puzzle: Crossword(rows: 3, cols: 7, entries: [
                Entry(number: 1, row: 0, col: 0, across: true, answer: ["ユ", "ビ", "ワ"], clue: "指にはめる輪の飾り", hint: "内側に名前を彫ることも"),
                Entry(number: 2, row: 0, col: 2, across: false, answer: ["ワ", "イ", "ン"], clue: "ぶどうから作るお酒", hint: "赤と白がある"),
                Entry(number: 4, row: 2, col: 1, across: true, answer: ["ビ", "ン"], clue: "ガラスの入れ物", hint: "○○の中の手紙"),
                Entry(number: 3, row: 1, col: 2, across: true, answer: ["イ", "ニ", "シ", "ヤ", "ル"], clue: "名前の頭文字", hint: "指輪の内側に彫る文字"),
            ], itemEntry: 0, mark: Cell(row: 1, col: 2))),
            RoomObject(kind: .painting, name: "未完成の絵", note: "絵の具の下に、硬い円いもの", requires: nil, gives: .coin, puzzle: Crossword(rows: 5, cols: 6, entries: [
                Entry(number: 3, row: 2, col: 0, across: true, answer: ["コ", "イ", "ン"], clue: "金属の小さなお金", hint: "表か裏か"),
                Entry(number: 2, row: 1, col: 4, across: false, answer: ["エ", "ン", "ピ", "ツ"], clue: "芯の入った木の筆記具", hint: "HB や 2B"),
                Entry(number: 1, row: 0, col: 2, across: false, answer: ["キ", "ヤ", "ン", "バ", "ス"], clue: "油絵をかく布", hint: "絵をかく白い布地"),
                Entry(number: 4, row: 4, col: 2, across: true, answer: ["ス", "ケ", "ツ", "チ"], clue: "見たものをさっと描くこと", hint: "○○○○ブック"),
            ], itemEntry: 0, mark: Cell(row: 1, col: 4))),
            RoomObject(kind: .safe, name: "塔の金庫", note: "コインを入れる細い口がある", requires: .coin, gives: .key, puzzle: Crossword(rows: 4, cols: 4, entries: [
                Entry(number: 3, row: 2, col: 0, across: false, answer: ["カ", "ギ"], clue: "最後の扉を開ける、大きな○○", hint: "錠前に差しこんで回す"),
                Entry(number: 3, row: 2, col: 0, across: true, answer: ["カ", "ウ", "ン", "ト"], clue: "数を数えること", hint: "○○○○ダウン"),
                Entry(number: 1, row: 0, col: 1, across: true, answer: ["ト", "ビ", "ラ"], clue: "出入り口の戸", hint: "○○○を開ける"),
                Entry(number: 2, row: 0, col: 3, across: false, answer: ["ラ", "ス", "ト"], clue: "いちばんおしまい", hint: "○○○スパート"),
            ], itemEntry: 0, mark: Cell(row: 2, col: 2))),
        ]),
    ]

    static let japaneseDaily: [DailyPuzzle] = [
        DailyPuzzle(title: "台所の小部屋", kind: .desk, puzzle: Crossword(rows: 3, cols: 8, entries: [
            Entry(number: 1, row: 0, col: 0, across: false, answer: ["ナ", "ベ"], clue: "火にかけて煮る道具", hint: "○○料理"),
            Entry(number: 3, row: 1, col: 0, across: true, answer: ["ベ", "ン", "ト", "ウ"], clue: "箱につめて持っていく食事", hint: "お○○○○箱"),
            Entry(number: 2, row: 0, col: 3, across: false, answer: ["ト", "ウ", "フ"], clue: "大豆から作る白い四角の食べ物", hint: "冷ややっこ"),
            Entry(number: 5, row: 2, col: 3, across: true, answer: ["フ", "ラ", "イ", "パ", "ン"], clue: "いため物に使う平たい鍋", hint: "目玉焼きを焼く"),
            Entry(number: 4, row: 1, col: 7, across: false, answer: ["パ", "ン"], clue: "小麦粉をこねて焼いた主食", hint: "食○○"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "海辺の小部屋", kind: .globe, puzzle: Crossword(rows: 4, cols: 6, entries: [
            Entry(number: 3, row: 2, col: 1, across: false, answer: ["ウ", "ミ"], clue: "しおからい大きな水", hint: "○○の日"),
            Entry(number: 1, row: 0, col: 0, across: false, answer: ["ミ", "ナ", "ト"], clue: "船がとまる所", hint: "横浜は○○○町"),
            Entry(number: 2, row: 2, col: 0, across: true, answer: ["ト", "ウ", "ダ", "イ"], clue: "光で船に場所を知らせる塔", hint: "岬に立つ白い塔"),
            Entry(number: 4, row: 2, col: 3, across: false, answer: ["イ", "カ"], clue: "足が十本の海の生き物", hint: "するめの材料"),
            Entry(number: 5, row: 3, col: 3, across: true, answer: ["カ", "モ", "メ"], clue: "海辺を飛ぶ白い鳥", hint: "○○○の水兵さん"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "庭の小部屋", kind: .painting, puzzle: Crossword(rows: 4, cols: 6, entries: [
            Entry(number: 1, row: 0, col: 0, across: true, answer: ["ハ", "ナ"], clue: "草木に咲くもの", hint: "○○見"),
            Entry(number: 2, row: 0, col: 1, across: false, answer: ["ナ", "エ"], clue: "植える前の小さな草木", hint: "○○木"),
            Entry(number: 3, row: 1, col: 1, across: true, answer: ["エ", "ダ"], clue: "木の幹から分かれた部分", hint: "小○○"),
            Entry(number: 4, row: 1, col: 2, across: false, answer: ["ダ", "リ", "ア"], clue: "夏に大きく咲く、メキシコ生まれの花", hint: "天竺牡丹とも"),
            Entry(number: 5, row: 3, col: 2, across: true, answer: ["ア", "サ", "ガ", "オ"], clue: "朝に咲くつるの花", hint: "夏休みの観察日記"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "雨の日の小部屋", kind: .fireplace, puzzle: Crossword(rows: 5, cols: 7, entries: [
            Entry(number: 2, row: 2, col: 0, across: true, answer: ["ア", "メ"], clue: "空から降る水", hint: "梅○○"),
            Entry(number: 3, row: 2, col: 1, across: false, answer: ["メ", "ダ", "カ"], clue: "小川にすむ小さな魚", hint: "○○○の学校"),
            Entry(number: 1, row: 0, col: 4, across: true, answer: ["カ", "エ", "ル"], clue: "雨の日に鳴く緑の生き物", hint: "おたまじゃくしが育つと"),
            Entry(number: 4, row: 4, col: 1, across: true, answer: ["カ", "ミ", "ナ", "リ"], clue: "ゴロゴロ鳴って光るもの", hint: "○○○○さまにおへそを取られる"),
            Entry(number: 1, row: 0, col: 4, across: false, answer: ["カ", "タ", "ツ", "ム", "リ"], clue: "雨の日に出てくる、からを背負った生き物", hint: "でんでんむし"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "旅の小部屋", kind: .globe, puzzle: Crossword(rows: 4, cols: 6, entries: [
            Entry(number: 4, row: 1, col: 3, across: true, answer: ["キ", "ツ", "プ"], clue: "乗り物に乗るための券", hint: "片道○○○"),
            Entry(number: 3, row: 1, col: 1, across: false, answer: ["キ", "シ", "ヤ"], clue: "蒸気で走る列車", hint: "○○○ぽっぽ"),
            Entry(number: 5, row: 3, col: 0, across: true, answer: ["シ", "ヤ", "シ", "ン"], clue: "カメラでうつしたもの", hint: "記念○○○○"),
            Entry(number: 2, row: 1, col: 0, across: true, answer: ["エ", "キ"], clue: "列車が止まる所", hint: "○○前"),
            Entry(number: 1, row: 0, col: 3, across: false, answer: ["エ", "キ", "ベ", "ン"], clue: "駅で売っている弁当", hint: "旅のお楽しみの弁当"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "森の小部屋", kind: .bookshelf, puzzle: Crossword(rows: 4, cols: 5, entries: [
            Entry(number: 4, row: 1, col: 3, across: false, answer: ["モ", "リ"], clue: "木がたくさん生えている所", hint: "○○のくまさん"),
            Entry(number: 1, row: 0, col: 0, across: true, answer: ["キ", "ノ", "コ"], clue: "森に生える、かさのあるもの", hint: "しいたけ、まつたけ"),
            Entry(number: 2, row: 0, col: 2, across: false, answer: ["コ", "ケ"], clue: "しめった所に生える緑のじゅうたん", hint: "○○むす"),
            Entry(number: 3, row: 1, col: 2, across: true, answer: ["ケ", "モ", "ノ"], clue: "毛におおわれた四つ足の動物", hint: "○○○道"),
            Entry(number: 1, row: 0, col: 0, across: false, answer: ["キ", "ツ", "ツ", "キ"], clue: "くちばしで木をたたく鳥", hint: "コンコンと幹に穴をあける"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "音の小部屋", kind: .gramophone, puzzle: Crossword(rows: 6, cols: 7, entries: [
            Entry(number: 3, row: 2, col: 4, across: true, answer: ["タ", "イ", "コ"], clue: "ばちでたたく楽器", hint: "和○○○"),
            Entry(number: 4, row: 2, col: 6, across: false, answer: ["コ", "ト"], clue: "十三本の弦の和楽器", hint: "『春の海』を奏でる"),
            Entry(number: 5, row: 5, col: 3, across: true, answer: ["オ", "ト"], clue: "耳に聞こえるひびき", hint: "○○楽"),
            Entry(number: 1, row: 0, col: 0, across: true, answer: ["ハ", "ー", "モ", "ニ", "カ"], clue: "口にあてて吹く、穴の並んだ楽器", hint: "吹いても吸っても鳴る"),
            Entry(number: 2, row: 0, col: 4, across: false, answer: ["カ", "ス", "タ", "ネ", "ツ", "ト"], clue: "手のひらで打ち合わせる楽器", hint: "スペインの踊りでカチカチ"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "冬の小部屋", kind: .fireplace, puzzle: Crossword(rows: 5, cols: 6, entries: [
            Entry(number: 1, row: 0, col: 4, across: false, answer: ["ユ", "キ"], clue: "冬に空から降る白いもの", hint: "○○だるま"),
            Entry(number: 2, row: 1, col: 3, across: true, answer: ["ス", "キ", "ー"], clue: "雪の坂を板ですべる", hint: "○○○場"),
            Entry(number: 4, row: 4, col: 2, across: true, answer: ["テ", "ブ", "ク", "ロ"], clue: "手にはめる防寒具", hint: "片方なくしがち"),
            Entry(number: 2, row: 1, col: 3, across: false, answer: ["ス", "ト", "ー", "ブ"], clue: "部屋を暖める道具", hint: "石油○○○○"),
            Entry(number: 3, row: 2, col: 0, across: true, answer: ["ス", "ケ", "ー", "ト"], clue: "氷の上をすべる", hint: "フィギュア○○○○"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "教室の小部屋", kind: .desk, puzzle: Crossword(rows: 6, cols: 8, entries: [
            Entry(number: 3, row: 2, col: 5, across: false, answer: ["コ", "ク", "バ", "ン"], clue: "チョークで書く緑の板", hint: "○○○○消し"),
            Entry(number: 4, row: 3, col: 2, across: true, answer: ["チ", "ヨ", "ー", "ク"], clue: "黒板に書く白い棒", hint: "石灰の筆記具"),
            Entry(number: 1, row: 0, col: 0, across: true, answer: ["ノ", "ー", "ト"], clue: "字を書く紙のたば", hint: "○○○パソコン"),
            Entry(number: 2, row: 0, col: 2, across: false, answer: ["ト", "モ", "ダ", "チ"], clue: "仲よしの人", hint: "○○○○百人できるかな"),
            Entry(number: 5, row: 5, col: 4, across: true, answer: ["セ", "ン", "セ", "イ"], clue: "学校で教える人", hint: "○○○、質問です"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "お茶の小部屋", kind: .chest, puzzle: Crossword(rows: 6, cols: 7, entries: [
            Entry(number: 1, row: 0, col: 0, across: true, answer: ["オ", "チ", "ヤ"], clue: "緑の葉から入れる飲み物", hint: "○○○の間"),
            Entry(number: 4, row: 3, col: 3, across: false, answer: ["ヤ", "カ", "ン"], clue: "湯をわかす道具", hint: "○○○の口から湯気"),
            Entry(number: 5, row: 4, col: 3, across: true, answer: ["カ", "ス", "テ", "ラ"], clue: "長崎名物の黄色い焼き菓子", hint: "ポルトガルから来たお菓子"),
            Entry(number: 3, row: 3, col: 0, across: true, answer: ["セ", "ン", "チ", "ヤ"], clue: "いちばんよく飲まれる日本の緑茶", hint: "玉露より身近な緑茶"),
            Entry(number: 2, row: 0, col: 1, across: false, answer: ["チ", "ヤ", "ワ", "ン"], clue: "ごはんやお茶を入れる器", hint: "お○○○○"),
        ], itemEntry: nil, mark: nil)),
    ]

    static let englishRooms: [Room] = [
        Room(id: "study", title: "The Earl's Study", subtitle: "Room One", intro: "You wake in a study lit by a single lamp. The door has four letter dials. Every object on the walls hides a tiny crossword.", outro: "The last letter clicks into place and the lock falls open. Down the hall, a gramophone starts to play.",
             final: ["L", "O", "R", "E"], finalClue: "The old stories and secrets of a place", objects: [
            RoomObject(kind: .painting, name: "The Earl's Portrait", note: "Something is tucked behind the frame", requires: nil, gives: .key, puzzle: Crossword(rows: 4, cols: 5, entries: [
                Entry(number: 2, row: 0, col: 4, across: false, answer: ["K", "E", "Y"], clue: "Opens a lock", hint: "Turn it in the keyhole"),
                Entry(number: 3, row: 1, col: 0, across: true, answer: ["F", "R", "A", "M", "E"], clue: "Border around a painting", hint: "It holds a portrait on the wall"),
                Entry(number: 1, row: 0, col: 2, across: false, answer: ["E", "A", "R", "L"], clue: "Noble who owned this house", hint: "A British count"),
                Entry(number: 4, row: 3, col: 0, across: true, answer: ["O", "I", "L"], clue: "Paint used for old portraits", hint: "___ on canvas"),
            ], itemEntry: 0, mark: Cell(row: 3, col: 2))),
            RoomObject(kind: .chest, name: "Locked Chest", note: "An old lock. A key would open it", requires: .key, gives: .candle, puzzle: Crossword(rows: 4, cols: 8, entries: [
                Entry(number: 2, row: 1, col: 0, across: true, answer: ["C", "A", "N", "D", "L", "E"], clue: "Wax stick with a wick", hint: "Blow it out on a birthday"),
                Entry(number: 3, row: 1, col: 4, across: false, answer: ["L", "I", "D"], clue: "Top of a chest", hint: "Close the ___"),
                Entry(number: 1, row: 0, col: 1, across: false, answer: ["O", "A", "K"], clue: "Hard wood for old furniture", hint: "Grows from an acorn"),
                Entry(number: 4, row: 3, col: 4, across: true, answer: ["D", "U", "S", "T"], clue: "Gray powder on old things", hint: "Wipe it off a shelf"),
            ], itemEntry: 0, mark: Cell(row: 0, col: 1))),
            RoomObject(kind: .bookshelf, name: "Towering Bookshelf", note: "One book is shelved upside down", requires: nil, gives: .gear, puzzle: Crossword(rows: 6, cols: 8, entries: [
                Entry(number: 2, row: 2, col: 0, across: true, answer: ["G", "E", "A", "R"], clue: "Toothed wheel in a machine", hint: "Cogs turn in a clock"),
                Entry(number: 1, row: 0, col: 5, across: false, answer: ["N", "O", "V", "E", "L"], clue: "Long story in a book", hint: "A work of fiction"),
                Entry(number: 3, row: 2, col: 3, across: false, answer: ["R", "E", "A", "D"], clue: "What you do with a book", hint: "Past tense sounds like a color"),
                Entry(number: 4, row: 4, col: 3, across: true, answer: ["A", "T", "L", "A", "S"], clue: "Book of maps", hint: "A Titan who held up the sky"),
            ], itemEntry: 0, mark: Cell(row: 2, col: 3))),
            RoomObject(kind: .desk, name: "The Earl's Desk", note: "The drawer has a gear-shaped slot", requires: .gear, gives: .lens, puzzle: Crossword(rows: 4, cols: 7, entries: [
                Entry(number: 4, row: 3, col: 3, across: true, answer: ["L", "E", "N", "S"], clue: "Curved glass that magnifies", hint: "In a camera or magnifier"),
                Entry(number: 1, row: 0, col: 0, across: false, answer: ["I", "N", "K"], clue: "Liquid for a pen", hint: "Squids squirt it too"),
                Entry(number: 3, row: 1, col: 0, across: true, answer: ["N", "O", "T", "E"], clue: "Short written message", hint: "Leave a ___ on the desk"),
                Entry(number: 2, row: 0, col: 3, across: false, answer: ["S", "E", "A", "L"], clue: "Wax stamp on a letter", hint: "Also a sea animal"),
            ], itemEntry: 0, mark: Cell(row: 3, col: 4))),
        ]),
        Room(id: "music", title: "The Moonlit Music Room", subtitle: "Room Two", intro: "The hall leads to a music room. A gramophone repeats the same bar. The lock wants four letters of sound.", outro: "The dials chime and the door swings open. Starlight spills down the stairs above.",
             final: ["T", "U", "N", "E"], finalClue: "A melody you can hum", objects: [
            RoomObject(kind: .gramophone, name: "Endless Gramophone", note: "Something glints inside the horn", requires: nil, gives: .ring, puzzle: Crossword(rows: 6, cols: 7, entries: [
                Entry(number: 1, row: 0, col: 0, across: true, answer: ["R", "I", "N", "G"], clue: "Band worn on a finger", hint: "Wedding ___"),
                Entry(number: 3, row: 2, col: 1, across: true, answer: ["R", "E", "C", "O", "R", "D"], clue: "Vinyl disc you play", hint: "Spin it on a turntable"),
                Entry(number: 4, row: 4, col: 0, across: true, answer: ["W", "A", "L", "T", "Z"], clue: "Dance in three beats", hint: "One-two-three, one-two-three"),
                Entry(number: 2, row: 0, col: 2, across: false, answer: ["N", "E", "E", "D", "L", "E"], clue: "It rides the groove of a record", hint: "Also used for sewing"),
            ], itemEntry: 0, mark: Cell(row: 4, col: 3))),
            RoomObject(kind: .safe, name: "Wall Safe", note: "A ring is engraved on the dial", requires: .ring, gives: .coin, puzzle: Crossword(rows: 4, cols: 6, entries: [
                Entry(number: 1, row: 0, col: 0, across: false, answer: ["C", "O", "I", "N"], clue: "Small metal money", hint: "Heads or tails"),
                Entry(number: 2, row: 0, col: 2, across: true, answer: ["D", "I", "A", "L"], clue: "Knob you turn on a safe", hint: "Spin it to a number"),
                Entry(number: 3, row: 3, col: 0, across: true, answer: ["N", "U", "M", "B", "E", "R"], clue: "One part of a code", hint: "Seven is one"),
                Entry(number: 2, row: 0, col: 2, across: false, answer: ["D", "R", "U", "M"], clue: "Instrument you hit", hint: "Snare or bass"),
            ], itemEntry: 0, mark: Cell(row: 2, col: 2))),
            RoomObject(kind: .fireplace, name: "Cold Fireplace", note: "Metal glints in the ashes", requires: nil, gives: .key, puzzle: Crossword(rows: 5, cols: 7, entries: [
                Entry(number: 2, row: 0, col: 5, across: false, answer: ["K", "E", "Y"], clue: "Winds a clock, or opens a lock", hint: "Found in the ashes"),
                Entry(number: 4, row: 4, col: 0, across: true, answer: ["E", "M", "B", "E", "R"], clue: "Glowing bit of coal", hint: "Left after the flames"),
                Entry(number: 1, row: 0, col: 3, across: false, answer: ["S", "M", "O", "K", "E"], clue: "Rises from a fire", hint: "Where there's ___, there's fire"),
                Entry(number: 3, row: 1, col: 0, across: true, answer: ["C", "H", "I", "M", "N", "E", "Y"], clue: "Lets smoke out of the house", hint: "Santa comes down it"),
            ], itemEntry: 0, mark: Cell(row: 1, col: 4))),
            RoomObject(kind: .clock, name: "Grandfather Clock", note: "There's a winding hole. It has stopped", requires: .key, gives: .gear, puzzle: Crossword(rows: 5, cols: 7, entries: [
                Entry(number: 1, row: 0, col: 6, across: false, answer: ["G", "E", "A", "R"], clue: "Toothed wheel inside a clock", hint: "Cog"),
                Entry(number: 3, row: 1, col: 3, across: false, answer: ["H", "A", "N", "D"], clue: "Pointer on a clock face", hint: "Hour ___"),
                Entry(number: 2, row: 1, col: 2, across: true, answer: ["C", "H", "I", "M", "E"], clue: "Ringing sound of a clock", hint: "Ding, dong"),
                Entry(number: 4, row: 3, col: 0, across: true, answer: ["N", "O", "O", "N"], clue: "Twelve o'clock in the day", hint: "High ___"),
            ], itemEntry: 0, mark: Cell(row: 1, col: 6))),
        ]),
        Room(id: "observatory", title: "The Attic Observatory", subtitle: "Room Three", intro: "A telescope and a globe sit under a round skylight. The door's dials are marked with four stars.", outro: "Four stars light up and the skylight slides open. Far away, the clock tower bell rings.",
             final: ["S", "T", "A", "R"], finalClue: "It twinkles in the night sky", objects: [
            RoomObject(kind: .telescope, name: "Brass Telescope", note: "A rolled paper is stuck in the tube", requires: nil, gives: .map, puzzle: Crossword(rows: 5, cols: 7, entries: [
                Entry(number: 3, row: 2, col: 4, across: true, answer: ["M", "A", "P"], clue: "Drawing of where things are", hint: "Treasure ___"),
                Entry(number: 4, row: 4, col: 0, across: true, answer: ["O", "R", "B", "I", "T"], clue: "Path around a planet", hint: "The Moon's path around Earth"),
                Entry(number: 2, row: 0, col: 4, across: false, answer: ["C", "O", "M", "E", "T"], clue: "Icy body with a glowing tail", hint: "Halley's ___"),
                Entry(number: 1, row: 0, col: 1, across: true, answer: ["S", "P", "A", "C", "E"], clue: "Where stars and planets are", hint: "Outer ___"),
            ], itemEntry: 0, mark: Cell(row: 0, col: 1))),
            RoomObject(kind: .globe, name: "Frozen Globe", note: "The stand has a slot for a map", requires: .map, gives: .compass, puzzle: Crossword(rows: 7, cols: 7, entries: [
                Entry(number: 4, row: 3, col: 0, across: true, answer: ["C", "O", "M", "P", "A", "S", "S"], clue: "Its needle points north", hint: "A sailor's tool"),
                Entry(number: 3, row: 2, col: 1, across: false, answer: ["N", "O", "R", "T", "H"], clue: "Where a compass points", hint: "Opposite of south"),
                Entry(number: 1, row: 0, col: 4, across: false, answer: ["I", "S", "L", "A", "N", "D"], clue: "Land with water all around", hint: "Treasure ___"),
                Entry(number: 2, row: 1, col: 2, across: true, answer: ["W", "E", "S", "T"], clue: "Where the sun sets", hint: "Opposite of east"),
            ], itemEntry: 0, mark: Cell(row: 1, col: 5))),
            RoomObject(kind: .bookshelf, name: "Star Chart Shelf", note: "A small key hangs at the back", requires: nil, gives: .key, puzzle: Crossword(rows: 6, cols: 7, entries: [
                Entry(number: 3, row: 3, col: 1, across: false, answer: ["K", "E", "Y"], clue: "Hung at the back of the shelf", hint: "Opens a lock"),
                Entry(number: 1, row: 0, col: 6, across: false, answer: ["G", "A", "L", "A", "X", "Y"], clue: "Huge group of stars", hint: "The Milky Way is one"),
                Entry(number: 4, row: 5, col: 0, across: true, answer: ["M", "Y", "S", "T", "E", "R", "Y"], clue: "Something to solve", hint: "A whodunit"),
                Entry(number: 2, row: 3, col: 0, across: true, answer: ["S", "K", "Y"], clue: "Blue by day, starry by night", hint: "The ___'s the limit"),
            ], itemEntry: 0, mark: Cell(row: 1, col: 6))),
            RoomObject(kind: .chest, name: "Astronomer's Box", note: "The keyhole is shaped like a star", requires: .key, gives: .candle, puzzle: Crossword(rows: 6, cols: 8, entries: [
                Entry(number: 1, row: 0, col: 0, across: false, answer: ["C", "A", "N", "D", "L", "E"], clue: "Wax light with a wick", hint: "Light one in a blackout"),
                Entry(number: 4, row: 4, col: 2, across: true, answer: ["A", "U", "R", "O", "R", "A"], clue: "Lights dancing in polar skies", hint: "Northern lights"),
                Entry(number: 3, row: 2, col: 0, across: true, answer: ["N", "I", "G", "H", "T"], clue: "When the stars come out", hint: "Opposite of day"),
                Entry(number: 2, row: 1, col: 4, across: false, answer: ["S", "T", "A", "R"], clue: "Twinkle, twinkle, little ___", hint: "The Sun is one"),
            ], itemEntry: 0, mark: Cell(row: 4, col: 6))),
        ]),
        Room(id: "tower", title: "Top of the Clock Tower", subtitle: "Room Four", intro: "Behind the giant clock face, gears creak. The hands stopped just before midnight. The last door leads outside.", outro: "The bell rings twelve times. Beyond the door, the town waits before dawn. You made it out.",
             final: ["T", "I", "M", "E"], finalClue: "What every clock measures", objects: [
            RoomObject(kind: .clock, name: "Back of the Great Clock", note: "One gear is coming loose", requires: nil, gives: .gear, puzzle: Crossword(rows: 6, cols: 8, entries: [
                Entry(number: 4, row: 5, col: 4, across: true, answer: ["G", "E", "A", "R"], clue: "Toothed wheel that turns", hint: "Cog"),
                Entry(number: 3, row: 2, col: 0, across: true, answer: ["T", "O", "W", "E", "R"], clue: "Tall building with a clock", hint: "Big Ben stands in one"),
                Entry(number: 2, row: 0, col: 4, across: false, answer: ["S", "P", "R", "I", "N", "G"], clue: "Coil that stores power", hint: "Also a season"),
                Entry(number: 1, row: 0, col: 0, across: false, answer: ["W", "A", "T", "C", "H"], clue: "Clock you wear", hint: "Wrist___"),
            ], itemEntry: 0, mark: Cell(row: 2, col: 0))),
            RoomObject(kind: .chest, name: "Clockmaker's Box", note: "The lid has a hole for a gear", requires: .gear, gives: .ring, puzzle: Crossword(rows: 4, cols: 8, entries: [
                Entry(number: 1, row: 0, col: 0, across: false, answer: ["R", "I", "N", "G"], clue: "Band worn on a finger", hint: "Engraved inside"),
                Entry(number: 2, row: 0, col: 4, across: false, answer: ["W", "I", "N", "E"], clue: "Drink made from grapes", hint: "Red or white"),
                Entry(number: 4, row: 3, col: 3, across: true, answer: ["J", "E", "W", "E", "L"], clue: "Precious stone", hint: "Crown ___"),
                Entry(number: 3, row: 1, col: 0, across: true, answer: ["I", "N", "I", "T", "I", "A", "L"], clue: "First letter of a name", hint: "Engraved inside a ring"),
            ], itemEntry: 0, mark: Cell(row: 1, col: 2))),
            RoomObject(kind: .painting, name: "Unfinished Painting", note: "Something hard and round under the paint", requires: nil, gives: .coin, puzzle: Crossword(rows: 6, cols: 6, entries: [
                Entry(number: 3, row: 2, col: 0, across: true, answer: ["C", "O", "I", "N"], clue: "Small metal money", hint: "Heads or tails"),
                Entry(number: 1, row: 0, col: 5, across: false, answer: ["E", "A", "S", "E", "L"], clue: "Stand that holds a painting", hint: "An artist's tripod"),
                Entry(number: 2, row: 1, col: 1, across: false, answer: ["M", "O", "D", "E", "L"], clue: "Person who sits for a portrait", hint: "Pose for the artist"),
                Entry(number: 4, row: 4, col: 0, across: true, answer: ["P", "E", "N", "C", "I", "L"], clue: "Wooden tool for sketching", hint: "HB or 2B"),
            ], itemEntry: 0, mark: Cell(row: 1, col: 1))),
            RoomObject(kind: .safe, name: "Tower Safe", note: "It has a thin slot for a coin", requires: .coin, gives: .key, puzzle: Crossword(rows: 4, cols: 6, entries: [
                Entry(number: 1, row: 0, col: 0, across: true, answer: ["K", "E", "Y"], clue: "Big one for the final door", hint: "Opens a lock"),
                Entry(number: 3, row: 0, col: 4, across: false, answer: ["D", "O", "O", "R"], clue: "Way in and out of a room", hint: "Open the ___"),
                Entry(number: 2, row: 0, col: 1, across: false, answer: ["E", "X", "I", "T"], clue: "Way out", hint: "Sign over a door"),
                Entry(number: 4, row: 3, col: 0, across: true, answer: ["S", "T", "A", "I", "R", "S"], clue: "Steps that go up or down", hint: "Climb the ___"),
            ], itemEntry: 0, mark: Cell(row: 0, col: 1))),
        ]),
    ]

    static let englishDaily: [DailyPuzzle] = [
        DailyPuzzle(title: "The Kitchen Nook", kind: .desk, puzzle: Crossword(rows: 6, cols: 6, entries: [
            Entry(number: 1, row: 0, col: 0, across: true, answer: ["S", "P", "O", "O", "N"], clue: "Tool for soup", hint: "Silver ___"),
            Entry(number: 5, row: 4, col: 1, across: true, answer: ["B", "R", "E", "A", "D"], clue: "Baked loaf", hint: "___ and butter"),
            Entry(number: 2, row: 0, col: 1, across: false, answer: ["P", "A", "N"], clue: "Flat cooking pot", hint: "Frying ___"),
            Entry(number: 3, row: 2, col: 0, across: true, answer: ["O", "N", "I", "O", "N"], clue: "Bulb that makes you cry", hint: "It has layers"),
            Entry(number: 4, row: 2, col: 3, across: false, answer: ["O", "V", "E", "N"], clue: "Box that bakes", hint: "Preheat the ___"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "The Seaside Nook", kind: .globe, puzzle: Crossword(rows: 5, cols: 8, entries: [
            Entry(number: 4, row: 3, col: 4, across: true, answer: ["W", "A", "V", "E"], clue: "Moving ridge of water", hint: "Surfers ride it"),
            Entry(number: 1, row: 0, col: 2, across: false, answer: ["S", "H", "E", "L", "L"], clue: "Hard home of a clam", hint: "Find it on the beach"),
            Entry(number: 2, row: 1, col: 2, across: true, answer: ["H", "A", "R", "B", "O", "R"], clue: "Where ships dock", hint: "Pearl ___"),
            Entry(number: 5, row: 4, col: 0, across: true, answer: ["G", "U", "L", "L"], clue: "White sea bird", hint: "Sea___"),
            Entry(number: 3, row: 1, col: 5, across: false, answer: ["B", "O", "A", "T"], clue: "Floats and carries people", hint: "Row, row, row your ___"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "The Garden Nook", kind: .painting, puzzle: Crossword(rows: 5, cols: 6, entries: [
            Entry(number: 1, row: 0, col: 2, across: false, answer: ["R", "O", "S", "E"], clue: "Thorny flower", hint: "A ___ by any other name"),
            Entry(number: 4, row: 3, col: 0, across: true, answer: ["S", "E", "E", "D"], clue: "Plant it to grow", hint: "Sunflower ___"),
            Entry(number: 3, row: 1, col: 0, across: false, answer: ["H", "O", "S", "E"], clue: "Long tube for water", hint: "Garden ___"),
            Entry(number: 2, row: 0, col: 5, across: false, answer: ["T", "U", "L", "I", "P"], clue: "Cup-shaped spring flower", hint: "Holland's flower"),
            Entry(number: 1, row: 0, col: 2, across: true, answer: ["R", "O", "O", "T"], clue: "Underground part of a plant", hint: "Square ___"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "The Rainy Nook", kind: .fireplace, puzzle: Crossword(rows: 6, cols: 7, entries: [
            Entry(number: 5, row: 4, col: 1, across: true, answer: ["C", "L", "O", "U", "D"], clue: "Gray thing in the sky", hint: "Rain falls from it"),
            Entry(number: 3, row: 2, col: 1, across: true, answer: ["P", "U", "D", "D", "L", "E"], clue: "Pool left after rain", hint: "Jump in it with boots"),
            Entry(number: 4, row: 2, col: 3, across: false, answer: ["D", "R", "O", "P"], clue: "Tiny bit of rain", hint: "Rain___"),
            Entry(number: 1, row: 0, col: 0, across: true, answer: ["S", "T", "O", "R", "M"], clue: "Wild weather", hint: "Thunder___"),
            Entry(number: 2, row: 0, col: 4, across: false, answer: ["M", "U", "D"], clue: "Wet dirt", hint: "Clear as ___"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "The Travel Nook", kind: .globe, puzzle: Crossword(rows: 6, cols: 8, entries: [
            Entry(number: 2, row: 0, col: 3, across: false, answer: ["T", "I", "C", "K", "E", "T"], clue: "Pass to ride", hint: "One-way ___"),
            Entry(number: 3, row: 1, col: 6, across: false, answer: ["T", "R", "A", "I", "N"], clue: "It runs on rails", hint: "Choo-choo"),
            Entry(number: 4, row: 3, col: 5, across: true, answer: ["B", "A", "G"], clue: "Holds your things", hint: "Pack your ___"),
            Entry(number: 1, row: 0, col: 0, across: true, answer: ["P", "H", "O", "T", "O"], clue: "Picture you take", hint: "Say cheese"),
            Entry(number: 5, row: 5, col: 0, across: true, answer: ["S", "T", "A", "T", "I", "O", "N"], clue: "Where trains stop", hint: "Train ___"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "The Forest Nook", kind: .bookshelf, puzzle: Crossword(rows: 6, cols: 7, entries: [
            Entry(number: 4, row: 2, col: 5, across: false, answer: ["T", "R", "E", "E"], clue: "Tall plant with a trunk", hint: "Family ___"),
            Entry(number: 5, row: 3, col: 2, across: true, answer: ["A", "C", "O", "R", "N"], clue: "Nut of an oak", hint: "Squirrels bury it"),
            Entry(number: 1, row: 0, col: 0, across: false, answer: ["M", "O", "S", "S"], clue: "Soft green on rocks", hint: "A rolling stone gathers none"),
            Entry(number: 2, row: 1, col: 0, across: true, answer: ["O", "W", "L"], clue: "Night bird that hoots", hint: "Wise old ___"),
            Entry(number: 3, row: 1, col: 2, across: false, answer: ["L", "E", "A", "F"], clue: "Green part of a tree", hint: "Turn over a new ___"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "The Sound Nook", kind: .gramophone, puzzle: Crossword(rows: 6, cols: 7, entries: [
            Entry(number: 3, row: 2, col: 0, across: true, answer: ["F", "L", "U", "T", "E"], clue: "Pipe held sideways and blown", hint: "Silver wind instrument"),
            Entry(number: 5, row: 5, col: 3, across: true, answer: ["S", "O", "N", "G"], clue: "Music with words", hint: "Sing a ___"),
            Entry(number: 4, row: 2, col: 4, across: false, answer: ["E", "C", "H", "O"], clue: "Sound that comes back", hint: "Hello... hello..."),
            Entry(number: 2, row: 0, col: 2, across: false, answer: ["L", "O", "U", "D"], clue: "Not quiet", hint: "Turn it down!"),
            Entry(number: 1, row: 0, col: 0, across: true, answer: ["B", "E", "L", "L"], clue: "Rings ding-dong", hint: "Wedding ___"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "The Winter Nook", kind: .fireplace, puzzle: Crossword(rows: 6, cols: 7, entries: [
            Entry(number: 1, row: 0, col: 3, across: false, answer: ["S", "N", "O", "W"], clue: "White flakes", hint: "___man"),
            Entry(number: 2, row: 1, col: 0, across: false, answer: ["S", "C", "A", "R", "F"], clue: "Wrapped around your neck", hint: "Knitted ___"),
            Entry(number: 4, row: 5, col: 0, across: true, answer: ["F", "R", "O", "S", "T"], clue: "Ice on the window", hint: "Jack ___"),
            Entry(number: 1, row: 0, col: 3, across: true, answer: ["S", "L", "E", "D"], clue: "Ride it downhill", hint: "It has runners"),
            Entry(number: 3, row: 2, col: 0, across: true, answer: ["C", "O", "C", "O", "A"], clue: "Hot chocolate drink", hint: "Top it with marshmallows"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "The Classroom Nook", kind: .desk, puzzle: Crossword(rows: 8, cols: 8, entries: [
            Entry(number: 3, row: 3, col: 2, across: true, answer: ["C", "H", "A", "L", "K"], clue: "Writes on a board", hint: "White stick"),
            Entry(number: 1, row: 0, col: 6, across: false, answer: ["D", "E", "S", "K"], clue: "Where you sit and work", hint: "School ___"),
            Entry(number: 3, row: 3, col: 2, across: false, answer: ["C", "L", "A", "S", "S"], clue: "Group of students", hint: "First ___"),
            Entry(number: 4, row: 7, col: 0, across: true, answer: ["L", "E", "S", "S", "O", "N"], clue: "What a teacher gives", hint: "Learn your ___"),
            Entry(number: 2, row: 1, col: 3, across: true, answer: ["R", "U", "L", "E", "R"], clue: "Draws straight lines", hint: "Also a king"),
        ], itemEntry: nil, mark: nil)),
        DailyPuzzle(title: "The Tea Nook", kind: .chest, puzzle: Crossword(rows: 6, cols: 7, entries: [
            Entry(number: 4, row: 2, col: 1, across: true, answer: ["T", "E", "A", "P", "O", "T"], clue: "Pot for brewing tea", hint: "Short and stout"),
            Entry(number: 1, row: 0, col: 4, across: false, answer: ["C", "U", "P"], clue: "Small drinking vessel", hint: "World ___"),
            Entry(number: 2, row: 0, col: 6, across: false, answer: ["K", "E", "T", "T", "L", "E"], clue: "Boils water", hint: "Whistles when ready"),
            Entry(number: 5, row: 4, col: 0, across: true, answer: ["S", "C", "O", "N", "E"], clue: "Baked treat with cream", hint: "With jam and clotted cream"),
            Entry(number: 3, row: 1, col: 2, across: false, answer: ["L", "E", "M", "O", "N"], clue: "Sour yellow fruit", hint: "A slice in your tea"),
        ], itemEntry: nil, mark: nil)),
    ]

}
