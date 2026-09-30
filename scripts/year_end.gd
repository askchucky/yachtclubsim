class_name YearEnd
extends PanelContainer

signal new_year
signal next_winter

var title_label := PixelLabel.new()
var body := PixelLabel.new()
var face := TextureRect.new()
var next_button := Button.new()
var new_button := Button.new()


func _ready() -> void:
	visible = false
	z_index = 20
	add_theme_stylebox_override("panel", UiSkin.frame(false))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	box.add_child(top)
	face.custom_minimum_size = Vector2(48, 48)
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var names = JSON.parse_string(FileAccess.get_file_as_string("res://art/catalog.json"))
	var idx: int = names["faces"].find("commodore")
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://art/faces.png")
	atlas.region = Rect2(idx * 24, 0, 24, 24)
	atlas.filter_clip = true
	face.texture = atlas
	top.add_child(face)
	title_label.scale_px = 2
	title_label.wrap_width = 420
	top.add_child(title_label)
	body.scale_px = 2
	body.wrap_width = 480
	body.custom_minimum_size = Vector2(460, 80)
	box.add_child(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	_button(next_button, "Open next winter")
	_button(new_button, "Start a new year")
	row.add_child(next_button)
	row.add_child(new_button)
	next_button.pressed.connect(func() -> void: next_winter.emit())
	new_button.pressed.connect(func() -> void: new_year.emit())


func show_result(sim: YearSim) -> void:
	visible = true
	title_label.set_text("Game over" if sim.outcome == "insolvent" or sim.outcome == "zero" or sim.outcome == "hollow" else "Year %d" % sim.year)
	body.set_text("Cash %s\nRegular %d, Social %d, Crew %d (%d members)\nSlips %d/%d\nDemand  Slips %d   Bar %d   Racing %d\n\n%s" % [
		SimData.money(sim.cash), sim.regular, sim.social, sim.crew, sim.members(),
		sim.slips_filled, SimData.SLIP_CAP, sim.demand_slips, sim.demand_bar, sim.demand_racing,
		SimData.outcome_line(sim.outcome),
	])
	next_button.visible = sim.outcome == "solvent"


func _button(button: Button, text: String) -> void:
	button.custom_minimum_size = Vector2(200, 44)
	UiSkin.paint_button(button)
	var label := PixelLabel.new()
	label.scale_px = 2
	label.wrap_width = 190
	label.set_text(text)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
