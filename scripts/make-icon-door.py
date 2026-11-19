#!/usr/bin/env python3
"""カギことばのアイコン：胡桃材の壁に、羊皮紙のクロスワードのマスと真鍮の鍵。1024×1024・透過なし。"""
import os
from PIL import Image, ImageDraw, ImageFilter

S = 1024 * 2
img = Image.new('RGB', (S, S), (0x3A, 0x28, 0x1C))
d = ImageDraw.Draw(img)
# 羽目板
for i in range(4):
    x = i * S // 4
    d.rectangle([x + 40, 60, x + S // 4 - 40, S - 60], fill=(0x4A, 0x34, 0x24), outline=(0x2E, 0x20, 0x17), width=8)
# ランプの光
glow = Image.new('L', (S, S), 0)
ImageDraw.Draw(glow).ellipse([S * 0.1, S * 0.05, S * 0.9, S * 0.85], fill=90)
glow = glow.filter(ImageFilter.GaussianBlur(220))
img = Image.composite(Image.new('RGB', (S, S), (0xFF, 0xD9, 0x8A)), img, glow)
d = ImageDraw.Draw(img)
# 羊皮紙のマス（3×3、黒マス 2 つ）
cell = 300
ox, oy = (S - cell * 3) // 2, int(S * 0.2)
blocks = {(0, 2), (2, 0)}
for r in range(3):
    for c in range(3):
        x0, y0 = ox + c * cell, oy + r * cell
        if (r, c) in blocks:
            d.rectangle([x0 + 10, y0 + 10, x0 + cell - 10, y0 + cell - 10], fill=(0x2E, 0x20, 0x17))
        else:
            d.rectangle([x0 + 10, y0 + 10, x0 + cell - 10, y0 + cell - 10], fill=(0xEF, 0xE2, 0xC4), outline=(0xC9, 0xB0, 0x80), width=6)
# 真鍮の鍵（斜め）
key = Image.new('RGBA', (S, S), (0, 0, 0, 0))
k = ImageDraw.Draw(key)
brass, deep = (0xC9, 0xA4, 0x5C, 255), (0x8C, 0x6A, 0x2F, 255)
cx, cy, R = S * 0.5, S * 0.5, 230
k.ellipse([cx - R - 640, cy - R, cx + R - 640, cy + R], fill=brass, outline=deep, width=24)
k.ellipse([cx - 110 - 640, cy - 110, cx + 110 - 640, cy + 110], fill=(0, 0, 0, 0))
k.rectangle([cx - 420, cy - 70, cx + 640, cy + 70], fill=brass, outline=deep, width=20)
k.rectangle([cx + 360, cy + 60, cx + 450, cy + 260], fill=brass, outline=deep, width=16)
k.rectangle([cx + 520, cy + 60, cx + 610, cy + 200], fill=brass, outline=deep, width=16)
key = key.rotate(35, resample=Image.BICUBIC, center=(cx, cy))
shadow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
shadow.paste((0, 0, 0, 150), mask=key.split()[3].point(lambda a: 255 if a > 0 else 0))
shadow = shadow.filter(ImageFilter.GaussianBlur(30))
img = img.convert('RGBA')
img.alpha_composite(shadow, (24, 40))
img.alpha_composite(key, (0, 60))
out = os.path.join(os.path.dirname(__file__), '..', 'App', 'Resources', 'Assets.xcassets', 'AppIcon.appiconset', 'AppIcon.png')
img.convert('RGB').resize((1024, 1024), Image.LANCZOS).save(out)
print('wrote', out)
