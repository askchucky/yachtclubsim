# Harbor Year

A SimCity-style yacht club sim. Build piers, slips, a breakwater, and channels on a Tiny Islands tile grid. Set prices and a budget, answer to a board and advisors, and keep the fictional club solvent month after month. Insolvency is a hard loss.

Godot 4.7, GDScript, web export. Tileset base is [Tiny Islands](assets/tiny-islands/) by Majadroid (CC0); club pieces are hand-drawn to match its palette (`art/STYLE_GUIDE.md`).

## Play

```
/home/ubuntu/.local/bin/godot --path /workspace
```

Or open the web build (served locally on port **8741**):

```
python3 -m http.server 8741 --directory build/web
```

Then open `http://127.0.0.1:8741/`.

### Controls

- **WASD / arrows** — pan · **right/middle drag** — pan · **Z / wheel** — zoom 1×–3×
- **Bottom toolbar** — build pier, slip, breakwater, dredge, buildings, amenity tiles, bulldoze
- **Top bar** — pause / 1× / 2× / 3×, Prices, Budget, Board, News, Reports
- **Space** — pause/unpause · **.** — advance one month
- **Harbor Year / Empty Shore** — start maps ($90k furnished harbor vs $250k empty shore)

Autosave: `user://harbor_sim.json` each month.

## Headless checks

```
godot --headless --path /workspace -s res://tests/sim_checks.gd
```

Checks cover placement rules, channel reachability, three-year solvency on the default map, dredging neglect, slip-fee demand, and storm damage vs breakwater/insurance.

## Layout

- `scripts/sim/` — clock, grid, catalog, economy, demand, politics, events, save, game
- `scripts/map/` — TileMap draw, build cursor, camera, boat A*, people
- `scripts/ui/` — top bar, toolbar, panels, annual card
- `art/harbor_atlas.png` — Tiny Islands samples + hand-drawn club tiles
- `build/web/` — exported HTML5 build for Vercel

## Export

```
godot --headless --path /workspace --export-release Web build/web/index.html
```
