class_name PricesPanel
extends PanelContainer

var game: HarborGame
var sliders: Dictionary = {}
var open := false


func _ready() -> void:
	PanelSkin.apply_panel(self)
	visible = false
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -340
	offset_top = 70
	offset_right = -12
	offset_bottom = 420
	var v := VBoxContainer.new()
	add_child(v)
	v.add_child(PanelSkin.label("Prices"))
	for key in [["dues_regular", "Regular dues"], ["dues_social", "Social dues"], ["dues_crew", "Crew dues"], ["slip_fee", "Slip fee / mo"], ["fb_minimum", "F&B minimum"], ["initiation", "Initiation"]]:
		var row := HBoxContainer.new()
		var lab := PanelSkin.label(key[1], 26)
		lab.custom_minimum_size = Vector2(140, 0)
		row.add_child(lab)
		var s := HSlider.new()
		s.min_value = 100
		s.max_value = 5000
		s.step = 25
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var k: String = key[0]
		s.value_changed.connect(func(v): _on_change(k, int(v)))
		sliders[k] = s
		row.add_child(s)
		v.add_child(row)
	var close := PanelSkin.button("Close")
	close.pressed.connect(func(): hide_panel())
	v.add_child(close)


func toggle() -> void:
	if visible:
		hide_panel()
	else:
		show_panel()


func show_panel() -> void:
	visible = true
	refresh()


func hide_panel() -> void:
	visible = false


func refresh() -> void:
	if game == null:
		return
	for k in sliders.keys():
		sliders[k].set_value_no_signal(float(game.economy.prices.get(k, 0)))


func _on_change(key: String, value: int) -> void:
	if game == null:
		return
	var old: int = int(game.economy.prices[key])
	if key.begins_with("dues_") and absi(value - old) > old / 10:
		if not game.politics.can_approve_big_move():
			sliders[key].set_value_no_signal(float(old))
			return
	game.economy.prices[key] = value
	game.changed.emit()
