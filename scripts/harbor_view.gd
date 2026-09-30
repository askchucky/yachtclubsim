class_name HarborView
extends Node2D

var sim: YearSim
var world := Node2D.new()
var water := Sprite2D.new()
var land := Sprite2D.new()
var boat_root := Node2D.new()
var people_root := Node2D.new()
var label_root := Node2D.new()
var wanted := PixelLabel.new()
var catalog: Dictionary = {}
var sheets := {}
var water_frames: Array = []
var land_frames := {}
var people := {}
var bulbs: Array = []
var tied: Array = []
var clock := 0.0
var shown_season := -1
var wake_tex: Texture2D


func _ready() -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://art/catalog.json"))
	var scale := int(catalog["scale"])
	world.scale = Vector2(scale, scale)
	add_child(world)
	add_child(label_root)
	for i in 4:
		water_frames.append(load("res://art/water_%d.png" % i))
		land_frames[i] = load("res://art/land_%s.png" % ["winter", "spring", "summer", "fall"][i])
	sheets["people"] = load("res://art/people.png")
	sheets["boats"] = load("res://art/boats.png")
	sheets["icons"] = load("res://art/icons.png")
	wake_tex = load("res://art/wake.png")
	sheets["shadow"] = load("res://art/shadow.png")
	for sprite in [water, land]:
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	water.texture = water_frames[0]
	land.texture = land_frames[0]
	world.add_child(water)
	world.add_child(land)
	world.add_child(boat_root)
	world.add_child(people_root)
	_bulbs()
	_people()
	wanted.scale_px = 1
	wanted.ink = Color("fff8ea")
	wanted.set_text("Wanted")
	wanted.position = Vector2(70, 40) * scale
	wanted.z_index = 8
	label_root.add_child(wanted)
	if sim != null:
		refresh(sim)


func _process(delta: float) -> void:
	clock += delta
	water.texture = water_frames[int(clock * 4.0) % 4]
	var summer := shown_season == SimData.SUMMER
	for bulb in bulbs:
		var pulse := sin(clock * (7.0 if summer else 3.0) + float(bulb.position.x))
		bulb.visible = shown_season != SimData.WINTER
		bulb.modulate = Color(1, 1, 1, 1.0 if pulse > 0.0 else 0.25)
	for item in tied:
		var sprite: Sprite2D = item["sprite"]
		sprite.position.y = float(item["base"]) + sin(clock * 2.2 + float(item["phase"])) * 1.1
	for id in people.keys():
		var body: Sprite2D = people[id]["sprite"]
		var base: Vector2 = people[id]["base"]
		var phase := float(people[id]["phase"])
		var frames: Array = people[id]["frames"]
		body.texture = frames[int(clock * 2.5 + phase) % 2]
		body.position = base + Vector2(sin(clock * 0.7 + phase) * 2.0, sin(clock * 2.0 + phase) * 0.6)


func refresh(sim_state: YearSim) -> void:
	sim = sim_state
	apply_world(sim)
	apply_people(sim)
	apply_boats(sim)


func apply_world(sim_state: YearSim) -> void:
	sim = sim_state
	var next: Texture2D = land_frames[sim.season]
	if shown_season == -1:
		land.texture = next
	elif shown_season != sim.season:
		_fade_land(next)
	shown_season = sim.season
	water.modulate = [Color(0.78, 0.86, 0.92), Color(0.9, 1, 0.95), Color(1, 1, 1), Color(0.9, 0.86, 0.75)][sim.season]
	wanted.visible = sim.empty_jobs().size() > 0


func apply_people(sim_state: YearSim) -> void:
	sim = sim_state
	for id in people.keys():
		var icon: Sprite2D = people[id]["mood"]
		var kind := SimData.mood_kind(int(sim.moods[id]))
		icon.texture = _icon(kind)
		icon.scale = Vector2.ONE


func apply_boats(sim_state: YearSim) -> void:
	sim = sim_state
	for child in boat_root.get_children():
		child.free()
	tied.clear()
	var moving := sim.moving_count()
	if moving == 0:
		var count := mini(12, sim.slips_filled)
		for i in count:
			var at: Array = catalog["ties"][i % catalog["ties"].size()]
			var sprite := _boat_sprite(i, true)
			sprite.position = Vector2(float(at[0]), float(at[1]))
			sprite.flip_h = i % 2 == 0
			boat_root.add_child(sprite)
			tied.append({"sprite": sprite, "base": sprite.position.y, "phase": float(i)})
		return
	var paths := {
		"out": _path(catalog["paths"]["out"]),
		"in": _path(catalog["paths"]["in"]),
		"loop": _path(catalog["paths"]["loop"]),
		"stay": _path(catalog["paths"]["stay"]),
	}
	var keys := ["out", "in", "loop", "stay"]
	for i in moving:
		var boat := HarborBoat.new()
		boat.sprite = _boat_sprite(i, false)
		boat.sprite.centered = true
		boat.sprite.position = Vector2(0, -6)
		boat.add_child(boat.sprite)
		if i % 4 != 3:
			boat.wake = Sprite2D.new()
			boat.wake.texture = wake_tex
			boat.wake.centered = true
			boat.wake.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			boat.add_child(boat.wake)
		boat.pace = 28.0 + float(i % 5) * 6.0
		boat.moving = i % 4 != 3
		paths[keys[i % 4]].add_child(boat)
		var slot := int(i / 4)
		var per_path := maxi(1, int((moving + 3) / 4))
		boat.progress_ratio = (float(slot) + 0.5) / float(per_path)


func pop_moods() -> void:
	if sim == null:
		return
	for id in people.keys():
		if int(sim.mood_deltas.get(id, 0)) == 0:
			continue
		var icon: Sprite2D = people[id]["mood"]
		icon.scale = Vector2(0.2, 0.2)
		var tw := create_tween()
		tw.tween_property(icon, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK)


func _fade_land(next: Texture2D) -> void:
	var ghost := Sprite2D.new()
	ghost.centered = false
	ghost.texture = next
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.modulate.a = 0.0
	ghost.z_index = 1
	world.add_child(ghost)
	var tw := create_tween()
	tw.tween_property(ghost, "modulate:a", 1.0, 0.45)
	tw.tween_callback(func() -> void:
		land.texture = next
		ghost.queue_free()
	)


func _people() -> void:
	var order: Array = catalog["people_order"]
	for i in order.size():
		var id := str(order[i])
		var at: Array = catalog["people"][id]
		var base := Vector2(float(at[0]), float(at[1]))
		var body := Sprite2D.new()
		body.centered = false
		body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		body.texture = _person_tex(i, 0)
		body.position = base
		var frames := [_person_tex(i, 0), _person_tex(i, 1)]
		body.set_meta("frames", frames)
		var shadow := Sprite2D.new()
		shadow.texture = sheets["shadow"]
		shadow.centered = true
		shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		shadow.position = Vector2(8, 30)
		body.add_child(shadow)
		people_root.add_child(body)
		var mood := Sprite2D.new()
		mood.centered = true
		mood.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mood.position = Vector2(8, -6)
		mood.texture = _icon("dot")
		body.add_child(mood)
		var label := PixelLabel.new()
		label.scale_px = 2
		label.ink = Color("fff8ea")
		label.plate = Color(0.1, 0.06, 0.03, 0.82)
		label.wrap_width = 160
		label.set_text(SimData.NAMES[id])
		var below := base.y > 150.0
		var name_w := label.custom_minimum_size.x
		label.position = base * int(catalog["scale"]) + Vector2(8 - name_w * 0.5, 68 if below else -20)
		label.z_index = 6
		label_root.add_child(label)
		people[id] = {"sprite": body, "mood": mood, "base": base, "phase": float(i), "frames": frames}


func _bulbs() -> void:
	var tex: Texture2D = load("res://art/bulb.png")
	for spot in catalog["bulbs"]:
		var bulb := Sprite2D.new()
		bulb.texture = tex
		bulb.centered = true
		bulb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bulb.position = Vector2(float(spot[0]), float(spot[1]))
		bulb.z_index = 4
		world.add_child(bulb)
		bulbs.append(bulb)


func _person_tex(index: int, frame: int) -> AtlasTexture:
	return _region(sheets["people"], Rect2(index * 16, frame * 32, 16, 32))


func _boat_sprite(index: int, moored: bool) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var col := index % 7
	sprite.texture = _region(sheets["boats"], Rect2(col * 48, 28 if moored else 0, 48, 28))
	sprite.z_index = 3
	var shadow := Sprite2D.new()
	shadow.texture = sheets["shadow"]
	shadow.centered = true
	shadow.position = Vector2(0, 10)
	shadow.z_index = -1
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.add_child(shadow)
	return sprite


func _icon(kind: String) -> AtlasTexture:
	var names: Array = catalog["icons"]
	var idx := names.find(kind)
	if idx < 0:
		idx = 0
	return _region(sheets["icons"], Rect2(idx * 16, 0, 16, 16))


func _region(sheet: Texture2D, rect: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = rect
	atlas.filter_clip = true
	return atlas


func _path(points: Array) -> Path2D:
	var path := Path2D.new()
	var curve := Curve2D.new()
	for point in points:
		curve.add_point(Vector2(float(point[0]), float(point[1])))
	path.curve = curve
	boat_root.add_child(path)
	return path
