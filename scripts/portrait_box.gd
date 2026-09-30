class_name PortraitBox
extends PanelContainer

var flag_box := VBoxContainer.new()
var body := PixelLabel.new()
var face := TextureRect.new()
var die_view := TextureRect.new()
var faces: Texture2D
var dice: Texture2D
var face_names: Array = []


static func compose(sim: YearSim) -> String:
	if sim.intro_pending:
		return "Commodore: the reserve target is $150,000, and the cash on hand is a thin reserve."
	if sim.portrait_hold != "":
		return sim.portrait_hold
	var title: String = SimData.EVENT_TITLES[sim.last_event]
	var delta := int(sim.mood_deltas.get(sim.speaker, 0))
	var line := ""
	if delta == 0:
		line = "Commodore watches the harbor, still at %s. Die %d: %s" % [SimData.mood_text(int(sim.moods["commodore"])), sim.last_die, title]
	else:
		var who: String = SimData.NAMES[sim.speaker]
		line = "%s felt this most and is now at %s. Die %d: %s" % [who, SimData.mood_text(int(sim.moods[sim.speaker])), sim.last_die, title]
	if sim.note != "":
		line += ", and " + sim.note
	return line + "."


func _ready() -> void:
	faces = load("res://art/faces.png")
	dice = load("res://art/dice.png")
	var names = JSON.parse_string(FileAccess.get_file_as_string("res://art/catalog.json"))
	face_names = names["faces"]
	add_theme_stylebox_override("panel", UiSkin.frame(false))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	box.add_child(top)
	face.custom_minimum_size = Vector2(40, 40)
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture = _face_tex("commodore")
	top.add_child(face)
	die_view.custom_minimum_size = Vector2(32, 32)
	die_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	die_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	die_view.visible = false
	top.add_child(die_view)
	flag_box.add_theme_constant_override("separation", 0)
	top.add_child(flag_box)
	body.scale_px = 2
	body.wrap_width = 490
	body.custom_minimum_size = Vector2(490, 32)
	box.add_child(body)


func refresh(sim: YearSim) -> void:
	while flag_box.get_child_count() > 0:
		var child := flag_box.get_child(0)
		flag_box.remove_child(child)
		child.free()
	for id in SimData.FLAGS:
		flag_box.add_child(_flag_row(str(id), int(sim.moods[id])))
	show_line(compose(sim))
	show_face(sim.speaker if not sim.intro_pending else "commodore")
	set_die(-1)


func show_line(text: String) -> void:
	body.set_text(text)


func show_face(id: String) -> void:
	face.texture = _face_tex(id)


func set_die(face_index: int) -> void:
	die_view.visible = face_index >= 1
	if face_index < 1:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = dice
	atlas.region = Rect2((face_index - 1) * 16, 0, 16, 16)
	atlas.filter_clip = true
	die_view.texture = atlas


func _flag_row(id: String, mood: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var mark := TextureRect.new()
	mark.custom_minimum_size = Vector2(24, 24)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mark.texture = _mood_tex(SimData.mood_kind(mood))
	row.add_child(mark)
	var label := PixelLabel.new()
	label.scale_px = 2
	label.wrap_width = 240
	label.set_text("%s %s" % [SimData.NAMES[id], SimData.mood_text(mood)])
	row.add_child(label)
	return row


func _face_tex(id: String) -> AtlasTexture:
	var idx := face_names.find(id)
	if idx < 0:
		idx = 0
	var atlas := AtlasTexture.new()
	atlas.atlas = faces
	atlas.region = Rect2(idx * 24, 0, 24, 24)
	atlas.filter_clip = true
	return atlas


func _mood_tex(kind: String) -> AtlasTexture:
	var icons: Texture2D = load("res://art/icons.png")
	var names := ["coin", "people", "anchor", "sun", "snow", "leaf", "heart", "dot", "cloud"]
	var idx := names.find(kind)
	if idx < 0:
		idx = 7
	var atlas := AtlasTexture.new()
	atlas.atlas = icons
	atlas.region = Rect2(idx * 16, 0, 16, 16)
	atlas.filter_clip = true
	return atlas
