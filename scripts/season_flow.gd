extends Node2D

const SAVE_PATH := "user://harbor_year.json"

var sim := YearSim.new()
var harbor: HarborView
var hud: HarborHud
var portrait: PortraitBox
var year_end: YearEnd
var choice_panel := PanelContainer.new()
var blurb := PixelLabel.new()
var play := ResolvePlay.new()
var spend_box := VBoxContainer.new()
var politics_box := VBoxContainer.new()
var confirm := Button.new()
var spend_group := ButtonGroup.new()
var politics_group := ButtonGroup.new()


func _ready() -> void:
	DisplayServer.window_set_title("Harbor Year")
	var loaded := _load()
	_build()
	if not loaded:
		sim.fresh()
		_season_start()
	else:
		_refresh()
		if sim.outcome != "":
			year_end.show_result(sim)
			choice_panel.hide()
		else:
			_rebuild_choices()


func _build() -> void:
	harbor = HarborView.new()
	harbor.sim = sim
	add_child(harbor)
	var ui := CanvasLayer.new()
	add_child(ui)
	portrait = PortraitBox.new()
	portrait.set_anchors_preset(Control.PRESET_TOP_LEFT)
	portrait.offset_left = 560
	portrait.offset_top = 0
	portrait.offset_right = 1276
	portrait.offset_bottom = 66
	portrait.clip_contents = true
	portrait.z_index = 4
	ui.add_child(portrait)
	play.finished.connect(_on_resolved)
	add_child(play)
	_build_choices()
	ui.add_child(choice_panel)
	hud = HarborHud.new()
	hud.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hud.offset_left = 0
	hud.offset_top = -100
	hud.z_index = 2
	hud.offset_right = 0
	hud.offset_bottom = 0
	ui.add_child(hud)
	year_end = YearEnd.new()
	year_end.set_anchors_preset(Control.PRESET_CENTER)
	year_end.offset_left = -270
	year_end.offset_top = -210
	year_end.offset_right = 270
	year_end.offset_bottom = 210
	year_end.new_year.connect(_on_new_year)
	year_end.next_winter.connect(_on_next_winter)
	ui.add_child(year_end)


func _build_choices() -> void:
	choice_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	choice_panel.offset_left = 712
	choice_panel.offset_top = 400
	choice_panel.offset_right = 1272
	choice_panel.offset_bottom = 616
	choice_panel.clip_contents = true
	choice_panel.z_index = 4
	choice_panel.add_theme_stylebox_override("panel", UiSkin.frame(false))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	choice_panel.add_child(box)
	blurb.scale_px = 2
	blurb.wrap_width = 520
	box.add_child(blurb)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	columns.add_theme_constant_override("separation", 8)
	box.add_child(columns)
	columns.add_child(_column("Spend", spend_box))
	columns.add_child(_column("Politics", politics_box))
	confirm.text = ""
	confirm.custom_minimum_size = Vector2(0, 36)
	confirm.pressed.connect(_on_confirm)
	UiSkin.paint_button(confirm)
	var confirm_label := PixelLabel.new()
	confirm_label.scale_px = 2
	confirm_label.wrap_width = 200
	confirm_label.set_text("Confirm")
	confirm.add_child(confirm_label)
	box.add_child(confirm)


func _column(title: String, holder: VBoxContainer) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := PixelLabel.new()
	label.scale_px = 2
	label.wrap_width = 240
	label.set_text(title)
	column.add_child(label)
	column.add_child(holder)
	return column


func _season_start() -> void:
	sim.prepare_season()
	_save()
	choice_panel.show()
	year_end.hide()
	_rebuild_choices()
	_refresh()


func _rebuild_choices() -> void:
	_clear(spend_box)
	_clear(politics_box)
	spend_group = ButtonGroup.new()
	politics_group = ButtonGroup.new()
	var options: Dictionary = SimData.choices(sim.season)
	blurb.set_text("Year %d, %s. %s One spend, one political pick." % [sim.year, sim.season_name(), SimData.BLURB[sim.season]])
	for item in options["spend"]:
		spend_box.add_child(_choice_button(str(item[0]), str(item[1]), spend_group))
	for item in options["politics"]:
		politics_box.add_child(_choice_button(str(item[0]), str(item[1]), politics_group))
	_fit_choice_panel()
	_update_confirm()


func _fit_choice_panel() -> void:
	var box := choice_panel.get_child(0) as Control
	var content := int(ceil(box.get_combined_minimum_size().y))
	# Frame content margins are 6px top and bottom. No spare parchment below Confirm.
	var panel_h := content + 12
	choice_panel.offset_left = 712
	choice_panel.offset_right = 1272
	choice_panel.offset_bottom = 616
	choice_panel.offset_top = 616 - panel_h


func _choice_button(id: String, text: String, group: ButtonGroup) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_group = group
	button.set_meta("id", id)
	button.toggled.connect(func(_on: bool) -> void: _update_confirm())
	UiSkin.paint_button(button)
	var label := PixelLabel.new()
	label.scale_px = 2
	label.wrap_width = 250
	label.position = Vector2(8, 6)
	label.set_text(text)
	button.custom_minimum_size = Vector2(260, label.custom_minimum_size.y + 14)
	button.add_child(label)
	return button


func _update_confirm() -> void:
	confirm.disabled = _picked(spend_group) == "" or _picked(politics_group) == ""


func _picked(group: ButtonGroup) -> String:
	var button := group.get_pressed_button()
	if button == null:
		return ""
	return str(button.get_meta("id"))


func _on_confirm() -> void:
	if play.playing or year_end.visible:
		return
	var spend := _picked(spend_group)
	var politics := _picked(politics_group)
	if spend == "" or politics == "":
		return
	var before := sim.cash
	sim.resolve(spend, politics)
	choice_panel.hide()
	play.start(portrait, hud, harbor, sim, before, spend, politics)


func _on_resolved() -> void:
	if sim.outcome != "":
		_save()
		_refresh()
		year_end.show_result(sim)
	else:
		_season_start()


func _on_new_year() -> void:
	sim.fresh()
	_season_start()


func _on_next_winter() -> void:
	sim.continue_next_winter()
	_season_start()


func _refresh() -> void:
	harbor.refresh(sim)
	hud.refresh(sim)
	portrait.refresh(sim)


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(sim.to_dict()))


func _load() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return false
	sim.from_dict(data)
	return true


func _clear(node: Node) -> void:
	while node.get_child_count() > 0:
		var child := node.get_child(0)
		node.remove_child(child)
		child.free()


func _unhandled_input(event: InputEvent) -> void:
	var click := false
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		click = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	if play.playing and (click or event.is_action_pressed("ui_accept")):
		play.advance()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		_on_confirm()
