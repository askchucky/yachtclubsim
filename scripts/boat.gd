class_name HarborBoat
extends PathFollow2D

var pace := 48.0
var moving := true
var sprite: Sprite2D
var wake: Sprite2D


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
	if absf(b.x - a.x) > 0.15:
		sprite.flip_h = b.x < a.x
	if wake != null:
		wake.flip_h = sprite.flip_h
		wake.position = Vector2(16 if sprite.flip_h else -16, 6)
		wake.visible = true
