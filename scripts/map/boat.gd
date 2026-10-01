class_name MapBoat
extends Node2D

var path: Array[Vector2i] = []
var path_i: int = 0
var speed := 28.0
var bob_t := 0.0
var sprite := ColorRect.new()
var returning := false


func _ready() -> void:
	sprite.size = Vector2(10, 6)
	sprite.color = Color("d38c35")
	sprite.position = Vector2(-5, -3)
	add_child(sprite)
	z_index = 5


func setup(p: Array[Vector2i], start_world: Vector2) -> void:
	path = p
	path_i = 0
	position = start_world
	returning = false


func _process(delta: float) -> void:
	bob_t += delta
	sprite.position.y = -3 + sin(bob_t * 3.0) * 1.5
	if path.is_empty() or path_i >= path.size():
		if not returning and path.size() > 1:
			path.reverse()
			path_i = 0
			returning = true
		else:
			queue_free()
		return
	var target_cell: Vector2i = path[path_i]
	var target := Vector2(target_cell.x + 0.5, target_cell.y + 0.5) * SimCatalog.TILE * SimCatalog.SCALE
	var dir := target - position
	if dir.length() < 2.0:
		path_i += 1
		return
	position += dir.normalized() * speed * delta
