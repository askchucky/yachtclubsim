# Harbor Year style guide

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
