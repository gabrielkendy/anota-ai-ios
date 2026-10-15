#!/usr/bin/env python
"""Gera os icones do app iOS a partir do print de identidade (brand/anota-ai-appicon.png)."""
import os
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
FONTE = os.path.normpath(os.path.join(AQUI, "..", "brand", "anota-ai-appicon.png"))
DEST = os.path.join(AQUI, "AnotaAI", "Assets.xcassets", "AppIcon.appiconset")
TAMANHOS = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]

img = Image.open(FONTE).convert("RGB")
fundo = img.getpixel((0, 0))
px = img.load()
xs, ys = [], []
for y in range(0, img.height, 2):
    for x in range(0, img.width, 2):
        p = px[x, y]
        if abs(p[0] - fundo[0]) + abs(p[1] - fundo[1]) + abs(p[2] - fundo[2]) > 24:
            xs.append(x)
            ys.append(y)

minx, maxx = min(xs), max(xs)
miny, maxy = min(ys), max(ys)
lado = max(maxx - minx, maxy - miny)
cx, cy = (minx + maxx) // 2, (miny + maxy) // 2
quad = img.crop((cx - lado // 2, cy - lado // 2, cx + lado // 2, cy + lado // 2))

os.makedirs(DEST, exist_ok=True)
for n in TAMANHOS:
    quad.resize((n, n), Image.LANCZOS).save(os.path.join(DEST, "icon-%d.png" % n))

print("icones iOS gerados:", TAMANHOS)
