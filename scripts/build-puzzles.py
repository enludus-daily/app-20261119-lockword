#!/usr/bin/env python3
"""手で書いた問題（content/ja.json・content/en.json）から、クロスワードの盤を組んで Swift のデータにする。

使い方: python3 scripts/build-puzzles.py [--check]
- 言葉の並べ方（どこで交わるか）だけを自動で決める。言葉・カギ・ヒントは全部手で書いたもの
- 全部の言葉が 1 つにつながり、ほかの言葉と横に触れない（交わる所だけで重なる）盤を探す。盤は最大 7×7
- 部屋の物の盤には、最後の扉の文字（final の k 文字目）が入るマスに印を付ける
- 組めない言葉の組があれば止まる（言葉を入れ替える）
- --check：App/Sources/Model/PuzzleData.swift が最新でなければ exit 1
"""
import json
import sys
from pathlib import Path

FAILS = []
MAXW = 8
MAXH = 8
SMALL = str.maketrans('ァィゥェォッャュョヮ', 'アイウエオツヤユヨワ')


def letters(word, lang):
    if lang == 'ja':
        w = word.translate(SMALL)
        for ch in w:
            if not ('ア' <= ch <= 'ン' or ch == 'ー' or ch == 'ヴ'):
                raise SystemExit(f'カタカナ以外の文字: {word!r}')
        return list(w)
    w = word.upper()
    if not w.isalpha() or not w.isascii():
        raise SystemExit(f'英字以外の文字: {word!r}')
    return list(w)


class Grid:
    def __init__(self):
        self.cells = {}
        self.placed = []  # (index, r, c, across)

    def can_place(self, w, r, c, across):
        dr, dc = (0, 1) if across else (1, 0)
        crossings = 0
        # 前後のマスは空いていること
        if (r - dr, c - dc) in self.cells or (r + dr * len(w), c + dc * len(w)) in self.cells:
            return -1
        for i, ch in enumerate(w):
            rr, cc = r + dr * i, c + dc * i
            have = self.cells.get((rr, cc))
            if have is not None:
                if have != ch:
                    return -1
                # 同じ向きの言葉と重ならない
                for (_, pr, pc, pa, pw) in self.placed:
                    if pa == across and self._covers(pr, pc, pa, pw, rr, cc):
                        return -1
                crossings += 1
            else:
                # 横（言葉の向きと直角）のマスが空いていること
                for s in (-1, 1):
                    if (rr + dc * s, cc + dr * s) in self.cells:
                        return -1
        return crossings

    @staticmethod
    def _covers(pr, pc, pa, pw, r, c):
        if pa:
            return r == pr and pc <= c < pc + len(pw)
        return c == pc and pr <= r < pr + len(pw)

    def place(self, idx, w, r, c, across):
        dr, dc = (0, 1) if across else (1, 0)
        added = []
        for i, ch in enumerate(w):
            k = (r + dr * i, c + dc * i)
            if k not in self.cells:
                self.cells[k] = ch
                added.append(k)
        self.placed.append((idx, r, c, across, w))
        return added

    def unplace(self, added):
        for k in added:
            del self.cells[k]
        self.placed.pop()

    def bounds(self):
        rs = [k[0] for k in self.cells]
        cs = [k[1] for k in self.cells]
        return min(rs), max(rs), min(cs), max(cs)


def solve(words):
    """全部の言葉を交わらせて置く。小さく、交わりの多い盤を選ぶ"""
    order = sorted(range(len(words)), key=lambda i: -len(words[i]))
    best = [None]

    def score(g):
        r0, r1, c0, c1 = g.bounds()
        h, w = r1 - r0 + 1, c1 - c0 + 1
        cross = sum(len(p[4]) for p in g.placed) - len(g.cells)
        return (h * w - cross * 6 + abs(h - w) * 2, h, w)

    def rec(g, rest, budget):
        if budget[0] <= 0:
            return
        budget[0] -= 1
        if not rest:
            r0, r1, c0, c1 = g.bounds()
            if r1 - r0 + 1 <= MAXH and c1 - c0 + 1 <= MAXW:
                s = score(g)
                if best[0] is None or s < best[0][0]:
                    best[0] = (s, list(g.placed))
            return
        # つなげられる言葉を順に試す
        for pick in rest:
            w = words[pick]
            options = []
            for (_, pr, pc, pa, pw) in g.placed:
                for i, ch in enumerate(pw):
                    rr, cc = (pr, pc + i) if pa else (pr + i, pc)
                    for j, wch in enumerate(w):
                        if wch != ch:
                            continue
                        across = not pa
                        r, c = (rr, cc - j) if across else (rr - j, cc)
                        x = g.can_place(w, r, c, across)
                        if x > 0:
                            options.append((r, c, across))
            for (r, c, across) in set(options):
                added = g.place(pick, w, r, c, across)
                r0, r1, c0, c1 = g.bounds()
                if r1 - r0 + 1 <= MAXH and c1 - c0 + 1 <= MAXW:
                    rec(g, [x for x in rest if x != pick], budget)
                g.unplace(added)
            # 先頭の言葉を置けないなら、あとの言葉で試す価値はある（順に試す）
    for first in order[:2]:
        for across in (True, False):
            g = Grid()
            g.place(first, words[first], 0, 0, across)
            rec(g, [i for i in order if i != first], [400000])
    if best[0] is None:
        return None
    placed = best[0][1]
    rs = []
    for (idx, r, c, a, w) in placed:
        for i in range(len(w)):
            rs.append((r + (0 if a else i), c + (i if a else 0)))
    r0 = min(x[0] for x in rs)
    c0 = min(x[1] for x in rs)
    h = max(x[0] for x in rs) - r0 + 1
    w = max(x[1] for x in rs) - c0 + 1
    out = {idx: (r - r0, c - c0, a) for (idx, r, c, a, _) in placed}
    return out, h, w


def number(entries):
    starts = sorted({(e['r'], e['c']) for e in entries})
    nums = {s: i + 1 for i, s in enumerate(starts)}
    for e in entries:
        e['n'] = nums[(e['r'], e['c'])]


def build_puzzle(spec, lang, final_letter=None, where=''):
    words = [letters(w[0], lang) for w in spec['words']]
    res = solve(words)
    if res is None:
        FAILS.append(f'{where}: 盤を組めません: {[w[0] for w in spec["words"]]}')
        return {'rows': 1, 'cols': 1, 'entries': [], 'item': None, 'mark': None}
    pos, h, w = res
    entries = []
    for i, wd in enumerate(spec['words']):
        r, c, a = pos[i]
        if len(wd) != 3 or not wd[1].strip() or not wd[2].strip():
            raise SystemExit(f'{where}: 言葉・カギ・ヒントの 3 つが要ります: {wd}')
        entries.append({'a': words[i], 'clue': wd[1], 'hint': wd[2], 'r': r, 'c': c, 'across': a})
    number(entries)
    if not entries:
        return {'rows': 1, 'cols': 1, 'entries': [], 'item': None, 'mark': None}
    cells = {}
    for e in entries:
        for i, ch in enumerate(e['a']):
            cells[(e['r'] + (0 if e['across'] else i), e['c'] + (i if e['across'] else 0))] = ch
    item = None
    if spec.get('item'):
        it = letters(spec['item'], lang)
        found = [k for k, e in enumerate(entries) if e['a'] == it]
        if not found:
            raise SystemExit(f'{where}: 道具の言葉 {spec["item"]} が盤にありません')
        item = found[0]
    mark = None
    if final_letter is not None:
        # 道具の言葉の外で、交わらないマスを優先する
        cand = [k for k, ch in sorted(cells.items()) if ch == final_letter]
        if not cand:
            raise SystemExit(f'{where}: 扉の文字 {final_letter} が盤にありません')
        def crossed(k):
            n = 0
            for e in entries:
                for i in range(len(e['a'])):
                    if (e['r'] + (0 if e['across'] else i), e['c'] + (i if e['across'] else 0)) == k:
                        n += 1
            return n
        cand.sort(key=lambda k: (crossed(k), k))
        mark = cand[0]
    return {'rows': h, 'cols': w, 'entries': entries, 'item': item, 'mark': mark}


def sw(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def emit_puzzle(p, indent):
    sp = ' ' * indent
    lines = [f'Crossword(rows: {p["rows"]}, cols: {p["cols"]}, entries: [']
    for e in p['entries']:
        ans = '[' + ', '.join(sw(x) for x in e['a']) + ']'
        lines.append(f'{sp}    Entry(number: {e["n"]}, row: {e["r"]}, col: {e["c"]}, across: {"true" if e["across"] else "false"}, answer: {ans}, clue: {sw(e["clue"])}, hint: {sw(e["hint"])}),')
    item = 'nil' if p['item'] is None else str(p['item'])
    mark = 'nil' if p['mark'] is None else f'Cell(row: {p["mark"][0]}, col: {p["mark"][1]})'
    lines.append(f'{sp}], itemEntry: {item}, mark: {mark})')
    return '\n'.join(lines)


def build(lang, data):
    out = []
    rooms = []
    for ri, room in enumerate(data['rooms']):
        final = letters(room['final'], lang)
        if len(final) != len(room['objects']):
            raise SystemExit(f'{lang} {room["id"]}: 扉の言葉の文字数と物の数が違う')
        objs = []
        for oi, ob in enumerate(room['objects']):
            p = build_puzzle(ob, lang, final[oi], f'{lang} {room["id"]} {ob["kind"]}')
            objs.append((ob, p))
        rooms.append((room, final, objs))
    dailies = [build_puzzle(d, lang, None, f'{lang} daily {i}') for i, d in enumerate(data['daily'])]
    for d, p in zip(data['daily'], dailies):
        p['title'] = d['title']
        p['kind'] = d['kind']
    return rooms, dailies


def emit(langs):
    out = ['// このファイルは scripts/build-puzzles.py が content/*.json から作る。手で直さない。',
           '// 言葉・カギ・ヒント・物語は手で書いたもの。盤の並べ方（交わる位置）だけを自動で決めている。',
           '', 'import Foundation', '', 'enum PuzzleData {']
    for lang, (rooms, dailies) in langs.items():
        name = 'japanese' if lang == 'ja' else 'english'
        out.append(f'    static let {name}Rooms: [Room] = [')
        for room, final, objs in rooms:
            out.append(f'        Room(id: {sw(room["id"])}, title: {sw(room["title"])}, subtitle: {sw(room["subtitle"])}, intro: {sw(room["intro"])}, outro: {sw(room["outro"])},')
            out.append(f'             final: [{", ".join(sw(x) for x in final)}], finalClue: {sw(room["finalClue"])}, objects: [')
            for ob, p in objs:
                req = 'nil' if ob.get('requires') is None else f'.{ob["requires"]}'
                gives = f'.{ob["gives"]}'
                out.append(f'            RoomObject(kind: .{ob["kind"]}, name: {sw(ob["name"])}, note: {sw(ob["note"])}, requires: {req}, gives: {gives}, puzzle: ' + emit_puzzle(p, 12) + '),')
            out.append('        ]),')
        out.append('    ]')
        out.append('')
        out.append(f'    static let {name}Daily: [DailyPuzzle] = [')
        for p in dailies:
            out.append(f'        DailyPuzzle(title: {sw(p["title"])}, kind: .{p["kind"]}, puzzle: ' + emit_puzzle(p, 8) + '),')
        out.append('    ]')
        out.append('')
    out.append('}')
    return '\n'.join(out) + '\n'


def main(argv):
    root = Path(__file__).resolve().parent.parent
    langs = {}
    for lang in ('ja', 'en'):
        data = json.loads((root / f'content/{lang}.json').read_text(encoding='utf-8'))
        langs[lang] = build(lang, data)
    if FAILS:
        print('\n'.join(FAILS))
        return 1
    text = emit(langs)
    target = root / 'App/Sources/Model/PuzzleData.swift'
    if '--check' in argv:
        if not target.exists() or target.read_text(encoding='utf-8') != text:
            print('PuzzleData.swift が最新ではありません: python3 scripts/build-puzzles.py')
            return 1
        print('ok')
        return 0
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding='utf-8')
    for lang, (rooms, dailies) in langs.items():
        n = sum(len(p['entries']) for _, _, objs in rooms for _, p in objs) + sum(len(p['entries']) for p in dailies)
        print(f'{lang}: 部屋 {len(rooms)}・今日の小部屋 {len(dailies)}・言葉 {n}')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
