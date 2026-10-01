class_name BudgetPanel
extends PanelContainer

var game: HarborGame
var sliders: Dictionary = {}


func _ready() -> void:
	PanelSkin.apply_panel(self)
	visible = false
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -340
	offset_top = 70
	offset_right = -12
	offset_bottom = 440
	var v := VBoxContainer.new()
	add_child(v)
	v.add_child(PanelSkin.label("Budget"))
	for key in [["dredging", "Dredging"], ["dock_maint", "Dock maint"], ["insurance", "Insurance"], ["staff_pay", "Staff pay"], ["racing", "Racing"], ["social", "Social"]]:
		var row := HBoxContainer.new()
		var lab := PanelSkin.label(key[1], 26)
		lab.custom_minimum_size = Vector2(120, 0)
		row.add_child(lab)
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 150
		s.step = 5
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var k: String = key[0]
		s.value_changed.connect(func(v): _on_change(k, int(v)))
		sliders[k] = s
		row.add_child(s)
		v.add_child(row)
	var loan := PanelSkin.button("Borrow $50,000")
	loan.pressed.connect(_borrow)
	v.add_child(loan)
	var close := PanelSkin.button("Close")
	close.pressed.connect(func(): visible = false)
	v.add_child(close)


func toggle() -> void:
	visible = not visible
	if visible:
		refresh()


func refresh() -> void:
	if game == null:
		return
	for k in sliders.keys():
		sliders[k].set_value_no_signal(float(game.economy.budget.get(k, 100)))


func _on_change(key: String, value: int) -> void:
	if game == null:
		return
	game.economy.budget[key] = value
	game.changed.emit()


func _borrow() -> void:
	if game == null:
		return
	if game.economy.loan + SimCatalog.LOAN_STEP > SimCatalog.LOAN_STEP * 4:
		if not game.politics.can_approve_big_move():
			return
		var res := game.politics.try_big_move("big_loan", game.economy)
		game._post("commodore", res["text"])
	else:
		game.economy.borrow(1)
		game._post("commodore", "Borrowed %s." % SimCatalog.money(SimCatalog.LOAN_STEP))
	game.changed.emit()
	SimSave.write(game)
