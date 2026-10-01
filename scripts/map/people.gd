class_name MapPeople
extends Node2D

## Twelve named people wander near clubhouse / piers.

var game: HarborGame
var bodies: Dictionary = {}
var clock := 0.0


func _ready() -> void:
	z_index = 6


func bind(g: HarborGame) -> void:
	game = g
	_rebuild()


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	bodies.clear()
	if game == null:
		return
	var ids: Array = []
	for id in SimCatalog.FLAGS:
		ids.append(id)
	for id in SimCatalog.MEMBERS:
		ids.append(id)
	for id in SimCatalog.STAFF:
		if bool(game.employed.get(id, false)):
			ids.append(id)
	var i := 0
	for id in ids:
		var r := ColorRect.new()
		r.size = Vector2(6, 10)
		r.color = _color(str(id))
		var base := Vector2(44 + (i % 8) * 2, 12 + (i / 8) * 2)
		r.position = base * SimCatalog.TILE * SimCatalog.SCALE
		r.set_meta("base", r.position)
		r.set_meta("phase", float(i) * 0.7)
		r.set_meta("id", id)
		add_child(r)
		bodies[id] = r
		i += 1


func _color(id: String) -> Color:
	match id:
		"commodore":
			return Color("773421")
		"vice":
			return Color("a56243")
		"rear":
			return Color("d38c35")
		"helen", "ruth":
			return Color("c29c8a")
		"dockmaster", "yard_boss":
			return Color("72654b")
		_:
			return Color("e8e5de")


func _process(delta: float) -> void:
	clock += delta
	for id in bodies.keys():
		var r: ColorRect = bodies[id]
		var base: Vector2 = r.get_meta("base")
		var phase: float = r.get_meta("phase")
		r.position = base + Vector2(sin(clock * 0.7 + phase) * 8.0, cos(clock * 0.5 + phase) * 5.0)
