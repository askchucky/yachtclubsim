class_name HarborMap
extends Node2D

## Draws TileMapLayers from HarborGrid using art/harbor_atlas.png.

const ATLAS := "res://art/harbor_atlas.png"

var grid: HarborGrid
var ground := TileMapLayer.new()
var overlay := TileMapLayer.new()
var atlas_tex: Texture2D
var source_id: int = 0
var tile_set: TileSet


func _ready() -> void:
	atlas_tex = load(ATLAS)
	tile_set = _make_tileset()
	ground.tile_set = tile_set
	overlay.tile_set = tile_set
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(ground)
	add_child(overlay)
	scale = Vector2(SimCatalog.SCALE, SimCatalog.SCALE)
	if grid != null:
		redraw()


func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(SimCatalog.TILE, SimCatalog.TILE)
	var src := TileSetAtlasSource.new()
	src.texture = atlas_tex
	src.texture_region_size = Vector2i(SimCatalog.TILE, SimCatalog.TILE)
	## create all atlas tiles present
	var cols := atlas_tex.get_width() / SimCatalog.TILE
	var rows := atlas_tex.get_height() / SimCatalog.TILE
	for y in rows:
		for x in cols:
			src.create_tile(Vector2i(x, y))
	ts.add_source(src, source_id)
	return ts


func redraw() -> void:
	if grid == null or tile_set == null:
		return
	ground.clear()
	overlay.clear()
	for y in grid.h:
		for x in grid.w:
			var cell := grid.get_cell(x, y)
			var g := _ground_atlas(cell, x, y)
			ground.set_cell(Vector2i(x, y), source_id, g)
			var o := _overlay_atlas(cell, x, y)
			if o.x >= 0:
				overlay.set_cell(Vector2i(x, y), source_id, o)


func _ground_atlas(cell: int, x: int, y: int) -> Vector2i:
	## row 1 terrain in atlas
	match cell:
		SimCatalog.CELL_DEEP:
			return Vector2i(1, 1)
		SimCatalog.CELL_SHALLOW:
			return Vector2i(2, 1)
		SimCatalog.CELL_CHANNEL:
			var silt_v := grid.silt[grid.idx(x, y)]
			return Vector2i(10, 4) if silt_v >= 80 else Vector2i(3, 1)
		SimCatalog.CELL_GRASS:
			return Vector2i(4, 1)
		SimCatalog.CELL_SAND:
			return Vector2i(5, 1)
		SimCatalog.CELL_PATH:
			return Vector2i(15, 1)
		SimCatalog.CELL_TREE:
			return Vector2i(4, 1)
		SimCatalog.CELL_FLOWERS, SimCatalog.CELL_LIGHTS:
			return Vector2i(5, 1)
		SimCatalog.CELL_CLUBHOUSE, SimCatalog.CELL_BAR, SimCatalog.CELL_FUEL, SimCatalog.CELL_YARD, SimCatalog.CELL_RACE, SimCatalog.CELL_OFFICE:
			return Vector2i(5, 1)
		SimCatalog.CELL_PIER, SimCatalog.CELL_SLIP, SimCatalog.CELL_BREAKWATER:
			return Vector2i(0, 1)
		_:
			return Vector2i(0, 1)


func _overlay_atlas(cell: int, x: int, y: int) -> Vector2i:
	match cell:
		SimCatalog.CELL_PIER:
			return _pier_tile(x, y)
		SimCatalog.CELL_SLIP:
			return _slip_tile(x, y)
		SimCatalog.CELL_BREAKWATER:
			return Vector2i(4, 3) ## H stone
		SimCatalog.CELL_CLUBHOUSE:
			return Vector2i(mini(2, grid.clubhouse_level - 1), 4)
		SimCatalog.CELL_BAR:
			return Vector2i(3, 4)
		SimCatalog.CELL_FUEL:
			return Vector2i(4, 4)
		SimCatalog.CELL_YARD:
			return Vector2i(5, 4)
		SimCatalog.CELL_RACE:
			return Vector2i(6, 4)
		SimCatalog.CELL_OFFICE:
			return Vector2i(7, 4)
		SimCatalog.CELL_TREE:
			return Vector2i(14, 1)
		SimCatalog.CELL_FLOWERS:
			return Vector2i(11, 3)
		SimCatalog.CELL_LIGHTS:
			return Vector2i(12, 3)
		_:
			return Vector2i(-1, -1)


func _pier_tile(x: int, y: int) -> Vector2i:
	var cond := grid.condition[grid.idx(x, y)]
	if cond < 30:
		return Vector2i(9, 4)
	if cond < 60:
		return Vector2i(8, 4)
	var n := grid.get_cell(x, y - 1) == SimCatalog.CELL_PIER
	var s := grid.get_cell(x, y + 1) == SimCatalog.CELL_PIER
	var e := grid.get_cell(x + 1, y) == SimCatalog.CELL_PIER
	var w := grid.get_cell(x - 1, y) == SimCatalog.CELL_PIER
	var count := int(n) + int(s) + int(e) + int(w)
	if count >= 3:
		return Vector2i(2, 2) ## T
	if n and s and not e and not w:
		return Vector2i(1, 2)
	if e and w and not n and not s:
		return Vector2i(0, 2)
	if n and s:
		return Vector2i(1, 2)
	if e and w:
		return Vector2i(0, 2)
	if n:
		return Vector2i(4, 2) ## END_N looking
	if s:
		return Vector2i(5, 2)
	if w:
		return Vector2i(6, 2)
	if e:
		return Vector2i(7, 2)
	return Vector2i(1, 2)


func _slip_tile(x: int, y: int) -> Vector2i:
	## face away from pier
	if grid.get_cell(x, y - 1) == SimCatalog.CELL_PIER:
		return Vector2i(1, 3) ## S finger
	if grid.get_cell(x, y + 1) == SimCatalog.CELL_PIER:
		return Vector2i(0, 3)
	if grid.get_cell(x - 1, y) == SimCatalog.CELL_PIER:
		return Vector2i(3, 3)
	if grid.get_cell(x + 1, y) == SimCatalog.CELL_PIER:
		return Vector2i(2, 3)
	return Vector2i(3, 3)


func map_size_px() -> Vector2:
	return Vector2(grid.w * SimCatalog.TILE * SimCatalog.SCALE, grid.h * SimCatalog.TILE * SimCatalog.SCALE)
