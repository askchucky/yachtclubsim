class_name HarborHud
extends PanelContainer

var cash_label := PixelLabel.new()
var members_label := PixelLabel.new()
var slips_label := PixelLabel.new()
var season_label := PixelLabel.new()
var season_icon := TextureRect.new()
var pip_rows: Array = []
var icons: Texture2D
var cash_shown := 0
var cash_tween: Tween


static func cash_text(sim: YearSim) -> String:
	return "Cash %s" % SimData.money(sim.cash)


static func reserve_text() -> String:
	return "Reserve %s" % SimData.money(SimData.RESERVE)


static func members_text(sim: YearSim) -> String:
	return "Members %d" % sim.members()


static func slips_text(sim: YearSim) -> String:
	return "Slips %d/%d" % [sim.slips_filled, SimData.SLIP_CAP]


static func season_text(sim: YearSim) -> String:
	var text := "Season %s" % sim.season_name()
	if not sim.channel_open:
		text += "  ·  Channel closed"
	return text


static func demand_values(sim: YearSim) -> Array:
	return [sim.demand_slips, sim.demand_bar, sim.demand_racing]


func _ready() -> void:
	icons = load("res://art/icons.png")
	add_theme_stylebox_override("panel", UiSkin.frame(false))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	row.add_child(_stat(0, cash_label))
	row.add_child(_stat(1, members_label))
	row.add_child(_stat(2, slips_label))
	var season_panel := _stat(3, season_label)
	season_icon = season_panel.get_child(0).get_child(0)
	row.add_child(season_panel)
	row.add_child(_demand())


func refresh(sim: YearSim) -> void:
	if cash_tween:
		cash_tween.kill()
	cash_shown = sim.cash
	cash_label.set_text(cash_text(sim))
	members_label.set_text(members_text(sim))
	slips_label.set_text(slips_text(sim))
	season_label.set_text(season_text(sim))
	var icon_index: int = [4, 3, 3, 5][sim.season]
	season_icon.texture = _icon(icon_index)
	_paint_pips(demand_values(sim))


func animate_cash(target: int) -> void:
	if cash_tween:
		cash_tween.kill()
	cash_tween = create_tween()
	cash_tween.tween_method(_show_cash, cash_shown, target, 0.85)
	cash_tween.finished.connect(func() -> void: cash_tween = null)


func _show_cash(value: float) -> void:
	cash_shown = int(value)
	cash_label.set_text("Cash %s" % SimData.money(cash_shown))


func _paint_pips(values: Array) -> void:
	for r in pip_rows.size():
		var pips: Array = pip_rows[r]
		for i in pips.size():
			var pip: TextureRect = pips[i]
			pip.texture = _pip_tex(i < int(values[r]))


func _stat(icon_index: int, label: PixelLabel) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UiSkin.frame(false))
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.texture = _icon(icon_index)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)
	label.scale_px = 2
	label.wrap_width = 220
	box.add_child(label)
	return panel


func _demand() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.frame(false))
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	for title in ["Slips", "Bar", "Racing"]:
		var line := VBoxContainer.new()
		var name := PixelLabel.new()
		name.scale_px = 2
		name.wrap_width = 80
		name.set_text(title)
		line.add_child(name)
		var pips_box := HBoxContainer.new()
		var pips: Array = []
		for _i in 4:
			var pip := TextureRect.new()
			pip.custom_minimum_size = Vector2(8, 8)
			pip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			pip.texture = _pip_tex(false)
			pips_box.add_child(pip)
			pips.append(pip)
		pip_rows.append(pips)
		line.add_child(pips_box)
		box.add_child(line)
	return panel


func _icon(index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = icons
	atlas.region = Rect2(index * 16, 0, 16, 16)
	atlas.filter_clip = true
	return atlas


func _pip_tex(on: bool) -> Texture2D:
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var fill := Color("f0c36a") if on else Color("3a2416")
	var edge := Color("a87820") if on else Color("1a100c")
	for y in 8:
		for x in 8:
			var col := fill
			if x == 0 or y == 0 or x == 7 or y == 7:
				col = edge
			elif on and x < 3 and y < 3:
				col = Color("fff0b0")
			image.set_pixel(x, y, col)
	return ImageTexture.create_from_image(image)
