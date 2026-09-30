class_name HarborBoat
extends PathFollow2D

var pace := 48.0
var moving := true
var sprite: Sprite2D
var wake: Sprite2D
var sheet: Texture2D
var col := 0
var cell := 28
var _row := -1
var _flip := false


func _process(delta: float) -> void:
	if not moving:
		return
	var path := get_parent() as Path2D
	if path == null or path.curve == null:
		return
	var length := path.curve.get_baked_length()
	if length <= 1.0:
		return
	var before := progress
	progress = fposmod(progress + pace * delta, length)
	if sprite == null:
		return
	var a := path.curve.sample_baked(before)
	var b := path.curve.sample_baked(progress)
	var dx := b.x - a.x
	var dy := b.y - a.y
	var row := 0
	var flip := false
	if absf(dx) >= absf(dy):
		row = 0
		flip = dx < 0.0
	elif dy < 0.0:
		row = 1
	else:
		row = 2
	if row != _row or flip != _flip:
		_row = row
		_flip = flip
		sprite.flip_h = flip
		if sheet != null:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * cell, row * cell, cell, cell)
			atlas.filter_clip = true
			sprite.texture = atlas
	if wake != null:
		wake.visible = true
		if row == 0:
			wake.rotation = 0.0
			wake.flip_h = flip
			wake.position = Vector2(12.0 if flip else -12.0, 2.0)
		elif row == 1:
			wake.rotation = PI * 0.5
			wake.flip_h = false
			wake.position = Vector2(0, 12)
		else:
			wake.rotation = -PI * 0.5
			wake.flip_h = false
			wake.position = Vector2(0, -12)
