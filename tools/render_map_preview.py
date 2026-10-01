#!/usr/bin/env python3
"""Render Harbor Year start map preview from atlas + layout rules (mirrors start_maps.gd)."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ATLAS = Image.open(ROOT / "art/harbor_atlas.png").convert("RGBA")
TILE = 16
W, H = 96, 54
SCALE = 2

# cell constants match SimCatalog
WATER, DEEP, SHALLOW, CHANNEL = 1, 2, 3, 4
GRASS, SAND = 5, 6
PIER, SLIP, BW = 10, 11, 12
CLUB, BAR, FUEL, YARD, RACE, OFFICE = 20, 21, 22, 23, 24, 25
PATH, TREE, FLOWERS, LIGHTS = 30, 31, 32, 33

GROUND = {
    DEEP: (1, 1), SHALLOW: (2, 1), CHANNEL: (3, 1), GRASS: (4, 1), SAND: (5, 1),
    PATH: (15, 1), TREE: (4, 1), FLOWERS: (5, 1), LIGHTS: (5, 1),
    CLUB: (5, 1), BAR: (5, 1), FUEL: (5, 1), YARD: (5, 1), RACE: (5, 1), OFFICE: (5, 1),
    PIER: (0, 1), SLIP: (0, 1), BW: (0, 1), WATER: (0, 1),
}
OVERLAY = {
    PIER: (1, 2), SLIP: (3, 3), BW: (4, 3), CLUB: (0, 4), BAR: (3, 4),
    FUEL: (4, 4), YARD: (5, 4), RACE: (6, 4), OFFICE: (7, 4),
    TREE: (14, 1), FLOWERS: (11, 3), LIGHTS: (12, 3),
}


def tile(tx, ty):
    return ATLAS.crop((tx * TILE, ty * TILE, (tx + 1) * TILE, (ty + 1) * TILE))


def fill(cells, x0, y0, x1, y1, v):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            cells[y][x] = v


def build():
    cells = [[WATER for _ in range(W)] for _ in range(H)]
    fill(cells, 0, 0, W - 1, 16, GRASS)
    fill(cells, 0, 14, W - 1, 17, SAND)
    fill(cells, 0, 18, W - 1, H - 1, WATER)
    fill(cells, 0, 30, W - 1, H - 1, DEEP)
    fill(cells, 38, 10, 56, 16, SAND)
    fill(cells, 40, 12, 48, 14, PATH)
    cells[11][44] = CLUB
    cells[12][48] = BAR
    cells[12][40] = OFFICE
    cells[13][52] = RACE
    cells[13][36] = YARD
    cells[15][50] = FUEL
    for x, y in [(42, 10), (46, 10), (50, 10), (43, 15), (47, 15)]:
        cells[y][x] = TREE
    cells[15][45] = FLOWERS
    cells[14][49] = FLOWERS
    cells[15][44] = LIGHTS

    def pier(rx, ry, length):
        for dy in range(length):
            y = ry + dy
            cells[y][rx] = PIER
            if dy >= 1 and dy % 2 == 1 and dy < length - 1:
                for sx in (rx - 1, rx + 1):
                    if cells[y][sx] in (WATER, DEEP, SHALLOW):
                        cells[y][sx] = SLIP

    pier(32, 17, 16)
    pier(44, 17, 16)
    pier(58, 17, 16)

    def channel(x, y):
        if cells[y][x] not in (PIER, SLIP):
            cells[y][x] = CHANNEL

    for y in range(18, 22):
        for x in range(36, 42):
            channel(x, y)
    for y in range(21, H):
        for x in range(37, 41):
            channel(x, y)
    for x in range(33, 38):
        channel(x, 20)
    for x in range(41, 46):
        channel(x, 20)
    for x in range(45, 59):
        channel(x, 21)
    for x in range(28, 72):
        cells[28][x] = BW
    for y in range(22, 29):
        cells[y][28] = BW
        cells[y][71] = BW
    for x in range(37, 41):
        cells[28][x] = CHANNEL
    return cells


def render(cells, out: Path):
    img = Image.new("RGBA", (W * TILE, H * TILE))
    for y in range(H):
        for x in range(W):
            c = cells[y][x]
            g = GROUND.get(c, (0, 1))
            img.paste(tile(*g), (x * TILE, y * TILE))
            o = OVERLAY.get(c)
            if o:
                t = tile(*o)
                img.paste(t, (x * TILE, y * TILE), t)
    # crop to club/piers area and scale
    crop = img.crop((28 * TILE, 8 * TILE, 74 * TILE, 34 * TILE))
    crop = crop.resize((crop.width * SCALE, crop.height * SCALE), Image.NEAREST)
    out.parent.mkdir(parents=True, exist_ok=True)
    crop.save(out)
    print("wrote", out, crop.size)


if __name__ == "__main__":
    out = Path("/cursor/stores/bc-1c0fe0b7-4fe4-449e-9c14-0f8cd5d145a7/media/harbor-sim-start-map.png")
    render(build(), out)
