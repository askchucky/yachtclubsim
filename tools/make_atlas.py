#!/usr/bin/env python3
"""Build harbor atlas from Tiny Islands + hand-drawn club tiles."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets/tiny-islands/tilemap-separated.png"
OUT = ROOT / "art/harbor_atlas.png"
GUIDE = ROOT / "art/STYLE_GUIDE.md"

# Tiny Islands palette (sampled)
P = {
    "water": (99, 155, 255, 255),
    "water_lite": (203, 219, 252, 255),
    "grass": (50, 140, 25, 255),
    "grass_dk": (46, 94, 43, 255),
    "sand": (200, 182, 60, 255),
    "sand_dk": (155, 107, 47, 255),
    "wood": (165, 98, 67, 255),
    "wood_lt": (211, 140, 53, 255),
    "wood_dk": (119, 52, 33, 255),
    "plank": (183, 123, 48, 255),
    "plank_lt": (200, 159, 60, 255),
    "stone": (114, 116, 101, 255),
    "stone_dk": (87, 89, 79, 255),
    "stone_lt": (146, 126, 106, 255),
    "roof": (119, 52, 33, 255),
    "wall": (194, 156, 138, 255),
    "wall_lt": (232, 229, 222, 255),
    "awning": (211, 140, 53, 255),
    "awning_stripe": (119, 52, 33, 255),
    "deep": (62, 90, 180, 255),
    "channel": (70, 120, 220, 255),
    "shallow": (130, 175, 255, 255),
    "black": (0, 0, 0, 255),
    "white": (255, 255, 255, 255),
    "green_ghost": (80, 220, 120, 180),
    "red_ghost": (220, 80, 80, 180),
    "clear": (0, 0, 0, 0),
}

TILE = 16
# Atlas rows: 0 Tiny water/land samples, 1 custom terrain, 2 pier, 3 slips/bw, 4 buildings, 5 icons/ghost
COLS = 16
ROWS = 8


def new_tile(color=None) -> Image.Image:
    im = Image.new("RGBA", (TILE, TILE), color or P["clear"])
    return im


def put(atlas: Image.Image, tx: int, ty: int, tile: Image.Image) -> None:
    atlas.paste(tile, (tx * TILE, ty * TILE), tile)


def draw_water(deep=False, channel=False, shallow=False) -> Image.Image:
    im = new_tile()
    d = ImageDraw.Draw(im)
    base = P["deep"] if deep else (P["channel"] if channel else (P["shallow"] if shallow else P["water"]))
    d.rectangle([0, 0, 15, 15], fill=base)
    # sparse dither
    spark = P["water_lite"]
    for x, y in ((2, 3), (9, 5), (5, 11), (12, 12), (4, 7)):
        d.point((x, y), fill=spark)
    return im


def draw_grass() -> Image.Image:
    im = new_tile(P["grass"])
    d = ImageDraw.Draw(im)
    for x, y in ((3, 4), (10, 6), (6, 11), (13, 3), (1, 12)):
        d.point((x, y), fill=P["grass_dk"])
    return im


def draw_sand() -> Image.Image:
    im = new_tile(P["sand"])
    d = ImageDraw.Draw(im)
    for x, y in ((2, 5), (8, 3), (12, 10), (5, 13), (14, 7)):
        d.point((x, y), fill=P["sand_dk"])
    return im


def draw_coast(kind: str) -> Image.Image:
    """kind: N/S/E/W edges sand over water."""
    im = draw_water()
    d = ImageDraw.Draw(im)
    if "N" in kind:
        d.rectangle([0, 0, 15, 5], fill=P["sand"])
        d.line([(0, 5), (15, 5)], fill=P["sand_dk"])
    if "S" in kind:
        d.rectangle([0, 10, 15, 15], fill=P["sand"])
        d.line([(0, 10), (15, 10)], fill=P["sand_dk"])
    if "W" in kind:
        d.rectangle([0, 0, 5, 15], fill=P["sand"])
        d.line([(5, 0), (5, 15)], fill=P["sand_dk"])
    if "E" in kind:
        d.rectangle([10, 0, 15, 15], fill=P["sand"])
        d.line([(10, 0), (10, 15)], fill=P["sand_dk"])
    return im


def draw_pier(orient: str) -> Image.Image:
    im = new_tile()
    d = ImageDraw.Draw(im)
    # water under
    d.rectangle([0, 0, 15, 15], fill=P["water"])
    if orient in ("H", "T", "X", "E", "W"):
        d.rectangle([0, 4, 15, 11], fill=P["plank"])
        for x in range(0, 16, 3):
            d.line([(x, 4), (x, 11)], fill=P["wood_dk"])
        d.line([(0, 4), (15, 4)], fill=P["plank_lt"])
        d.line([(0, 11), (15, 11)], fill=P["wood_dk"])
    if orient in ("V", "T", "X", "N", "S"):
        d.rectangle([4, 0, 11, 15], fill=P["plank"])
        for y in range(0, 16, 3):
            d.line([(4, y), (11, y)], fill=P["wood_dk"])
        d.line([(4, 0), (4, 15)], fill=P["plank_lt"])
        d.line([(11, 0), (11, 15)], fill=P["wood_dk"])
    if orient == "END_N":
        d.rectangle([4, 0, 11, 11], fill=P["plank"])
        for y in range(0, 12, 3):
            d.line([(4, y), (11, y)], fill=P["wood_dk"])
    if orient == "END_S":
        d.rectangle([4, 4, 11, 15], fill=P["plank"])
    if orient == "END_W":
        d.rectangle([0, 4, 11, 11], fill=P["plank"])
    if orient == "END_E":
        d.rectangle([4, 4, 15, 11], fill=P["plank"])
    # stilts
    d.point((5, 13), fill=P["wood_dk"])
    d.point((10, 13), fill=P["wood_dk"])
    return im


def draw_slip(side: str) -> Image.Image:
    im = draw_water()
    d = ImageDraw.Draw(im)
    # finger pier stub
    if side == "N":
        d.rectangle([5, 0, 10, 8], fill=P["plank"])
        d.rectangle([3, 7, 12, 9], fill=P["wood"])
    elif side == "S":
        d.rectangle([5, 7, 10, 15], fill=P["plank"])
        d.rectangle([3, 6, 12, 8], fill=P["wood"])
    elif side == "W":
        d.rectangle([0, 5, 8, 10], fill=P["plank"])
        d.rectangle([7, 3, 9, 12], fill=P["wood"])
    else:
        d.rectangle([7, 5, 15, 10], fill=P["plank"])
        d.rectangle([6, 3, 8, 12], fill=P["wood"])
    # cleat
    d.rectangle([7, 7, 8, 8], fill=P["stone_lt"])
    return im


def draw_breakwater(kind: str) -> Image.Image:
    im = draw_water()
    d = ImageDraw.Draw(im)
    if kind == "H":
        d.rectangle([0, 5, 15, 10], fill=P["stone"])
        d.line([(0, 5), (15, 5)], fill=P["stone_lt"])
        d.line([(0, 10), (15, 10)], fill=P["stone_dk"])
    elif kind == "V":
        d.rectangle([5, 0, 10, 15], fill=P["stone"])
        d.line([(5, 0), (5, 15)], fill=P["stone_lt"])
        d.line([(10, 0), (10, 15)], fill=P["stone_dk"])
    elif kind == "SE":
        d.pieslice([-2, -2, 18, 18], 0, 90, fill=P["stone"])
    elif kind == "SW":
        d.pieslice([-2, -2, 18, 18], 90, 180, fill=P["stone"])
    elif kind == "NE":
        d.pieslice([-2, -2, 18, 18], 270, 360, fill=P["stone"])
    elif kind == "NW":
        d.pieslice([-2, -2, 18, 18], 180, 270, fill=P["stone"])
    else:
        d.rectangle([3, 3, 12, 12], fill=P["stone"])
    return im


def draw_clubhouse(level: int = 1) -> Image.Image:
    im = new_tile(P["grass"])
    d = ImageDraw.Draw(im)
    # base
    d.rectangle([1, 6, 14, 14], fill=P["wall"])
    d.rectangle([1, 6, 14, 7], fill=P["wall_lt"])
    # roof
    h = 5 + level
    d.polygon([(0, 7), (8, 7 - h), (15, 7)], fill=P["roof"])
    d.line([(0, 7), (8, 7 - h), (15, 7)], fill=P["wood_dk"])
    # door / windows
    d.rectangle([6, 10, 9, 14], fill=P["wood_dk"])
    d.rectangle([2, 9, 4, 11], fill=P["water_lite"])
    d.rectangle([11, 9, 13, 11], fill=P["water_lite"])
    if level >= 2:
        d.rectangle([7, 3, 8, 5], fill=P["wood"])  # cupola
    if level >= 3:
        d.rectangle([3, 4, 4, 5], fill=P["white"])  # flagpole base
        d.point((3, 2), fill=(220, 60, 60, 255))
    return im


def draw_bar() -> Image.Image:
    im = new_tile(P["sand"])
    d = ImageDraw.Draw(im)
    d.rectangle([1, 7, 14, 14], fill=P["wall"])
    # striped awning
    for x in range(1, 15, 2):
        col = P["awning"] if (x // 2) % 2 == 0 else P["awning_stripe"]
        d.rectangle([x, 5, x + 1, 8], fill=col)
    d.rectangle([5, 10, 10, 14], fill=P["wood_dk"])
    d.rectangle([2, 9, 3, 11], fill=P["water_lite"])
    d.rectangle([12, 9, 13, 11], fill=P["water_lite"])
    return im


def draw_building(kind: str) -> Image.Image:
    im = new_tile(P["sand"] if kind != "path" else P["grass"])
    d = ImageDraw.Draw(im)
    if kind == "fuel":
        d.rectangle([3, 4, 12, 14], fill=P["stone"])
        d.rectangle([6, 2, 9, 4], fill=P["wood_dk"])
        d.ellipse([5, 7, 10, 12], fill=(220, 80, 40, 255))
    elif kind == "yard":
        d.rectangle([1, 8, 14, 14], fill=P["stone_dk"])
        d.rectangle([4, 3, 11, 10], fill=P["stone"])
        d.line([(7, 1), (7, 8)], fill=P["wood"])
        d.line([(4, 4), (11, 4)], fill=P["wood_lt"])
    elif kind == "race":
        d.rectangle([2, 7, 13, 14], fill=P["wall"])
        d.polygon([(1, 8), (8, 3), (14, 8)], fill=P["awning"])
        d.rectangle([7, 10, 9, 14], fill=P["wood_dk"])
    elif kind == "office":
        d.rectangle([2, 6, 13, 14], fill=P["wall_lt"])
        d.rectangle([2, 5, 13, 6], fill=P["roof"])
        d.rectangle([6, 10, 9, 14], fill=P["wood"])
        d.rectangle([3, 8, 5, 10], fill=P["water_lite"])
    elif kind == "path":
        d.rectangle([0, 5, 15, 10], fill=P["sand_dk"])
        for x in (3, 8, 12):
            d.point((x, 7), fill=P["sand"])
    elif kind == "tree":
        d.ellipse([3, 2, 12, 12], fill=P["grass_dk"])
        d.rectangle([7, 11, 8, 15], fill=P["wood_dk"])
    elif kind == "flowers":
        for x, y, c in ((3, 10, (220, 80, 100, 255)), (8, 9, (240, 200, 60, 255)), (12, 11, (200, 100, 200, 255))):
            d.point((x, y), fill=c)
            d.point((x, y - 1), fill=P["grass"])
    elif kind == "lights":
        d.rectangle([7, 4, 8, 14], fill=P["stone_dk"])
        d.ellipse([5, 2, 10, 7], fill=(255, 230, 120, 255))
    return im


def draw_icon(kind: str) -> Image.Image:
    im = new_tile()
    d = ImageDraw.Draw(im)
    d.rectangle([1, 1, 14, 14], fill=P["wood"], outline=P["wood_dk"])
    if kind == "pier":
        d.rectangle([3, 6, 12, 9], fill=P["plank_lt"])
    elif kind == "slip":
        d.rectangle([4, 3, 7, 12], fill=P["plank"])
        d.rectangle([7, 7, 12, 9], fill=P["water"])
    elif kind == "bw":
        d.rectangle([2, 6, 13, 10], fill=P["stone"])
    elif kind == "dredge":
        d.ellipse([4, 4, 11, 11], fill=P["channel"])
    elif kind == "bulldoze":
        d.line([(4, 4), (11, 11)], fill=(220, 60, 60, 255), width=2)
        d.line([(11, 4), (4, 11)], fill=(220, 60, 60, 255), width=2)
    elif kind == "club":
        d.rectangle([4, 7, 11, 12], fill=P["wall"])
        d.polygon([(3, 8), (8, 4), (12, 8)], fill=P["roof"])
    else:
        d.rectangle([5, 5, 10, 10], fill=P["awning"])
    return im


def copy_ti_tile(src: Image.Image, sx: int, sy: int) -> Image.Image:
    """Tiny Islands separated atlas uses 16px tiles on even grid cells often."""
    return src.crop((sx * 16, sy * 16, sx * 16 + 16, sy * 16 + 16)).copy()


def main() -> None:
    src = Image.open(SRC).convert("RGBA")
    atlas = Image.new("RGBA", (COLS * TILE, ROWS * TILE), P["clear"])

    # Row 0: Tiny Islands samples (water, grass, sand, trees, stilts)
    samples = [(0, 0), (2, 0), (4, 0), (6, 0), (8, 0), (10, 0), (12, 0), (14, 0), (0, 2), (2, 2), (4, 2), (8, 5), (10, 5), (12, 5), (14, 5), (16, 5)]
    for i, (sx, sy) in enumerate(samples):
        put(atlas, i, 0, copy_ti_tile(src, sx, sy))

    # Row 1: terrain
    put(atlas, 0, 1, draw_water())
    put(atlas, 1, 1, draw_water(deep=True))
    put(atlas, 2, 1, draw_water(shallow=True))
    put(atlas, 3, 1, draw_water(channel=True))
    put(atlas, 4, 1, draw_grass())
    put(atlas, 5, 1, draw_sand())
    put(atlas, 6, 1, draw_coast("N"))
    put(atlas, 7, 1, draw_coast("S"))
    put(atlas, 8, 1, draw_coast("W"))
    put(atlas, 9, 1, draw_coast("E"))
    put(atlas, 10, 1, draw_coast("NE"))
    put(atlas, 11, 1, draw_coast("NW"))
    put(atlas, 12, 1, draw_coast("SE"))
    put(atlas, 13, 1, draw_coast("SW"))
    put(atlas, 14, 1, draw_building("tree"))
    put(atlas, 15, 1, draw_building("path"))

    # Row 2: pier pieces
    for i, o in enumerate(["H", "V", "T", "X", "END_N", "END_S", "END_W", "END_E", "N", "S", "E", "W"]):
        put(atlas, i, 2, draw_pier(o))

    # Row 3: slips + breakwater
    for i, s in enumerate(["N", "S", "W", "E"]):
        put(atlas, i, 3, draw_slip(s))
    for i, k in enumerate(["H", "V", "NE", "NW", "SE", "SW", "BLOCK"]):
        put(atlas, 4 + i, 3, draw_breakwater(k))
    put(atlas, 11, 3, draw_building("flowers"))
    put(atlas, 12, 3, draw_building("lights"))

    # Row 4: buildings
    put(atlas, 0, 4, draw_clubhouse(1))
    put(atlas, 1, 4, draw_clubhouse(2))
    put(atlas, 2, 4, draw_clubhouse(3))
    put(atlas, 3, 4, draw_bar())
    put(atlas, 4, 4, draw_building("fuel"))
    put(atlas, 5, 4, draw_building("yard"))
    put(atlas, 6, 4, draw_building("race"))
    put(atlas, 7, 4, draw_building("office"))
    # worn pier / broken
    worn = draw_pier("H")
    d = ImageDraw.Draw(worn)
    d.rectangle([6, 6, 9, 9], fill=P["water"])
    put(atlas, 8, 4, worn)
    broken = draw_pier("H")
    d = ImageDraw.Draw(broken)
    d.rectangle([4, 5, 12, 10], fill=P["water"])
    d.rectangle([2, 6, 4, 9], fill=P["plank"])
    put(atlas, 9, 4, broken)
    silt = draw_water(channel=True)
    d = ImageDraw.Draw(silt)
    for x, y in ((3, 4), (8, 8), (12, 5), (6, 12)):
        d.point((x, y), fill=P["sand_dk"])
    put(atlas, 10, 4, silt)

    # Row 5: tool icons + ghosts
    for i, k in enumerate(["pier", "slip", "bw", "dredge", "club", "bar", "bulldoze"]):
        put(atlas, i, 5, draw_icon(k))
    g = new_tile(P["green_ghost"])
    put(atlas, 8, 5, g)
    r = new_tile(P["red_ghost"])
    put(atlas, 9, 5, r)

    # Row 6: more TI tiles (boats/stilts if present)
    for i, (sx, sy) in enumerate([(0, 7), (2, 7), (4, 7), (6, 7), (8, 7), (12, 7), (14, 7), (16, 7), (18, 7), (0, 9), (3, 9), (6, 9), (9, 9), (12, 9), (15, 9), (18, 9)]):
        put(atlas, i, 6, copy_ti_tile(src, sx, sy))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT)
    print("wrote", OUT, atlas.size)

    GUIDE.write_text(
        """# Harbor Year style guide

Tileset base: **Tiny Islands** by Majadroid (CC0), `assets/tiny-islands/`.
Game atlas: `art/harbor_atlas.png` (16×16 tiles, drawn at 2× in-game).

## Palette (locked from Tiny Islands)

| Role | RGB |
|------|-----|
| Water | 99,155,255 |
| Water lite | 203,219,252 |
| Deep / channel | 62,90,180 / 70,120,220 |
| Grass | 50,140,25 |
| Grass dark | 46,94,43 |
| Sand | 200,182,60 |
| Sand dark | 155,107,47 |
| Wood / plank | 165,98,67 / 183,123,48 |
| Wood dark / light | 119,52,33 / 211,140,53 |
| Stone | 114,116,101 |
| Wall / roof | 194,156,138 / 119,52,33 |

## Rules

- 16px base tile, 2× nearest scale (32px on screen).
- Light from top-left; three tones per material.
- Selective 1px dark outlines on buildings and pier edges.
- Sparse dither only on water and sand.
- Hand-drawn club pieces (pier, slip, breakwater, clubhouse, bar) match this palette.
- Economy never lives in sprites — only in `scripts/sim/`.
""",
        encoding="utf-8",
    )
    print("wrote", GUIDE)


if __name__ == "__main__":
    main()
