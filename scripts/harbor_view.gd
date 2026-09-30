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
var flag: Sprite2D
var flag_frames: Array = []
var dog: Sprite2D
var dog_frames: Array = []
var gull_sprites: Array = []


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
	boat_root.z_index = 3
	people_root.z_index = 4
	world.add_child(boat_root)
	world.add_child(people_root)
	_bulbs()
	_people()
	_critters()
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
		var route: Array = people[id]["wander"]
		if route.size() >= 2:
			body.position = _along(route, clock * 14.0 + phase * 6.0)
			body.texture = frames[2 + int(clock * 6.0 + phase) % 4]
		else:
			body.texture = frames[int(clock * 2.2 + phase) % 2]
			body.position = base + Vector2(sin(clock * 1.3 + phase) * 0.6, sin(clock * 2.0 + phase) * 0.7)
	if flag != null and flag_frames.size() == 2:
		flag.texture = flag_frames[int(clock * 3.0) % 2]
	if dog != null and dog_frames.size() == 2:
		dog.texture = dog_frames[int(clock * 2.0) % 2]
		dog.position = dog.get_meta("base") + Vector2(sin(clock * 1.4) * 3.0, 0)
	for gull in gull_sprites:
		var sprite: Sprite2D = gull["sprite"]
		var origin: Vector2 = gull["origin"]
		var phase := float(gull["phase"])
		var frames: Array = gull["frames"]
		sprite.position = origin + Vector2(cos(clock * 0.7 + phase) * 22.0, sin(clock * 0.9 + phase) * 6.0)
		sprite.texture = frames[int(clock * 5.0 + phase) % 2]
		sprite.flip_h = cos(clock * 0.7 + phase) < 0.0


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
	var cell := int(catalog.get("boat_cell", 28))
	var kinds := 7
	if catalog.has("boats"):
		kinds = maxi(1, (catalog["boats"] as Array).size())
	var ties: Array = catalog["ties"]
	var filled := mini(sim.slips_filled, ties.size())
	for i in filled:
		var at: Array = ties[i]
		var sprite := _boat_sprite(i % kinds, 3, cell)
		sprite.position = Vector2(float(at[0]), float(at[1]))
		sprite.flip_h = at.size() > 2 and int(at[2]) == 1
		boat_root.add_child(sprite)
		tied.append({"sprite": sprite, "base": sprite.position.y, "phase": float(i)})
	var moving := sim.moving_count()
	if moving <= 0:
		return
	var order := ["loop", "weave", "in", "out"]
	var keys: Array = []
	for key in order:
		if catalog["paths"].has(key):
			keys.append(key)
	if keys.is_empty():
		return
	var paths := {}
	var per := {}
	for key in keys:
		paths[key] = _path(catalog["paths"][key])
		per[key] = 0
	for i in moving:
		per[keys[i % keys.size()]] += 1
	var seen := {}
	for key in keys:
		seen[key] = 0
	for i in moving:
		var key: String = str(keys[i % keys.size()])
		var slot: int = int(seen[key])
		seen[key] = slot + 1
		var boat := HarborBoat.new()
		boat.cell = cell
		boat.col = i % kinds
		boat.sheet = sheets["boats"]
		boat.sprite = _boat_sprite(boat.col, 0, cell)
		boat.sprite.position = Vector2.ZERO
		boat.add_child(boat.sprite)
		boat.wake = Sprite2D.new()
		boat.wake.texture = wake_tex
		boat.wake.centered = true
		boat.wake.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		boat.add_child(boat.wake)
		boat.pace = 20.0 + float((i * 3) % 5) * 3.0
		boat.moving = true
		paths[key].add_child(boat)
		boat.progress_ratio = (float(slot) + 0.5) / float(maxi(1, int(per[key])))


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
		var frames: Array = []
		for frame in 6:
			frames.append(_person_tex(i, frame))
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
		if catalog.has("label_pos") and (catalog["label_pos"] as Dictionary).has(id):
			var spot: Array = catalog["label_pos"][id]
			label.position = Vector2(float(spot[0]), float(spot[1]))
		else:
			var name_w := label.custom_minimum_size.x
			label.position = base * int(catalog["scale"]) + Vector2(8 - name_w * 0.5, -20)
		label.z_index = 6
		label_root.add_child(label)
		var route: Array = []
		if catalog.has("wander") and catalog["wander"].has(id):
			route = catalog["wander"][id].duplicate()
			if route.size() > 2:
				var first: Array = route[0]
				var last: Array = route[route.size() - 1]
				if int(first[0]) != int(last[0]) or int(first[1]) != int(last[1]):
					route.append(first)
		people[id] = {
			"sprite": body, "mood": mood, "base": base, "phase": float(i),
			"frames": frames, "wander": route,
		}


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


func _boat_sprite(col: int, row: int, cell: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = _region(sheets["boats"], Rect2(col * cell, row * cell, cell, cell))
	sprite.z_index = 3
	var shadow := Sprite2D.new()
	shadow.texture = sheets["shadow"]
	shadow.centered = true
	shadow.position = Vector2(0, 8 if row == 3 else 10)
	shadow.scale = Vector2(1.15, 0.8) if row == 3 else Vector2.ONE
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


func _critters() -> void:
	var flag_tex: Texture2D = load("res://art/flag.png")
	var flag_w := 14
	var flag_h := 12
	if catalog.has("flag_size"):
		var flag_size: Array = catalog["flag_size"]
		flag_w = int(flag_size[0])
		flag_h = int(flag_size[1])
	flag_frames = [
		_region(flag_tex, Rect2(0, 0, flag_w, flag_h)),
		_region(flag_tex, Rect2(0, flag_h, flag_w, flag_h)),
	]
	flag = Sprite2D.new()
	flag.centered = false
	flag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flag.texture = flag_frames[0]
	flag.z_index = 5
	var flag_at: Array = catalog.get("flag", [103, 0])
	flag.position = Vector2(float(flag_at[0]), float(flag_at[1]))
	world.add_child(flag)
	var dog_tex: Texture2D = load("res://art/dog.png")
	dog_frames = [
		_region(dog_tex, Rect2(0, 0, 16, 12)),
		_region(dog_tex, Rect2(0, 12, 16, 12)),
	]
	dog = Sprite2D.new()
	dog.centered = false
	dog.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dog.texture = dog_frames[0]
	dog.z_index = 4
	var dog_at: Array = catalog.get("dog", [6, 292])
	dog.position = Vector2(float(dog_at[0]), float(dog_at[1]))
	dog.set_meta("base", dog.position)
	world.add_child(dog)
	var gull_tex: Texture2D = load("res://art/gull.png")
	var gull_frames := [
		_region(gull_tex, Rect2(0, 0, 10, 8)),
		_region(gull_tex, Rect2(0, 8, 10, 8)),
	]
	var spots: Array = catalog.get("gulls", [])
	for i in spots.size():
		var gull := Sprite2D.new()
		gull.centered = true
		gull.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		gull.texture = gull_frames[0]
		gull.z_index = 5
		var spot: Array = spots[i]
		gull.position = Vector2(float(spot[0]), float(spot[1]))
		world.add_child(gull)
		gull_sprites.append({
			"sprite": gull,
			"origin": gull.position,
			"phase": float(i) * 1.7,
			"frames": gull_frames,
		})


func _along(points: Array, dist: float) -> Vector2:
	var total := 0.0
	var lengths: Array = []
	for i in range(points.size() - 1):
		var a := Vector2(float(points[i][0]), float(points[i][1]))
		var b := Vector2(float(points[i + 1][0]), float(points[i + 1][1]))
		var span := a.distance_to(b)
		lengths.append(span)
		total += span
	if total < 1.0:
		return Vector2(float(points[0][0]), float(points[0][1]))
	var walk := fposmod(dist, total)
	for i in lengths.size():
		var span := float(lengths[i])
		if walk <= span:
			var a := Vector2(float(points[i][0]), float(points[i][1]))
			var b := Vector2(float(points[i + 1][0]), float(points[i + 1][1]))
			return a.lerp(b, walk / maxf(0.001, span))
		walk -= span
	return Vector2(float(points[0][0]), float(points[0][1]))


func _path(points: Array) -> Path2D:
	var path := Path2D.new()
	var curve := Curve2D.new()
	for point in points:
		curve.add_point(Vector2(float(point[0]), float(point[1])))
	path.curve = curve
	boat_root.add_child(path)
	return path
