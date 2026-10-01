class_name BuildCursor
extends Node2D

signal place_requested(tool_id: String, cell: Vector2i)

var grid: HarborGrid
var tool_id: String = ""
var ghost := Sprite2D.new()
var atlas: Texture2D
var cell := Vector2i(-1, -1)
var valid := false


func _ready() -> void:
	atlas = load("res://art/harbor_atlas.png")
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.centered = false
	ghost.z_index = 20
	add_child(ghost)
	visible = false


func set_tool(id: String) -> void:
	tool_id = id
	visible = id != ""
	_update_ghost_tex()


func _update_ghost_tex() -> void:
	if atlas == null:
		return
	var atlas_coords := Vector2i(8, 5) ## green ghost default
	ghost.texture = _region(atlas_coords)


func _region(coords: Vector2i) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = atlas
	at.region = Rect2(coords.x * 16, coords.y * 16, 16, 16)
	return at


func update_from_world(world_pos: Vector2) -> void:
	if tool_id == "" or grid == null:
		visible = false
		return
	visible = true
	var local := world_pos / float(SimCatalog.SCALE)
	var cx := int(floor(local.x / float(SimCatalog.TILE)))
	var cy := int(floor(local.y / float(SimCatalog.TILE)))
	cell = Vector2i(cx, cy)
	valid = grid.can_place(tool_id, cx, cy)
	position = Vector2(cx * SimCatalog.TILE, cy * SimCatalog.TILE) * SimCatalog.SCALE
	scale = Vector2(SimCatalog.SCALE, SimCatalog.SCALE)
	ghost.texture = _region(Vector2i(8, 5) if valid else Vector2i(9, 5))
	ghost.modulate = Color(1, 1, 1, 0.75)


func try_click() -> void:
	if tool_id == "" or not valid:
		return
	place_requested.emit(tool_id, cell)
