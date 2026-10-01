class_name ReportsPanel
extends PanelContainer

var game: HarborGame
var body: VBoxContainer


func _ready() -> void:
	PanelSkin.apply_panel(self)
	visible = false
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -280
	offset_top = -220
	offset_right = 280
	offset_bottom = 220
	body = VBoxContainer.new()
	add_child(body)


func toggle() -> void:
	visible = not visible
	if visible:
		refresh()


func refresh() -> void:
	if game == null:
		return
	for c in body.get_children():
		c.queue_free()
	body.add_child(PanelSkin.label("Reports"))
	var hist: Array = game.economy.history
	if hist.is_empty():
		body.add_child(PanelSkin.label("No months yet — unpause to tick.", 26))
	else:
		var cash_line := "Cash: "
		var mem_line := "Members: "
		var start := maxi(0, hist.size() - 12)
		for i in range(start, hist.size()):
			cash_line += "%s " % SimCatalog.money(int(hist[i]["cash"]))
			mem_line += "%d " % int(hist[i]["members"])
		body.add_child(PanelSkin.label(cash_line, 22))
		body.add_child(PanelSkin.label(mem_line, 22))
		body.add_child(PanelSkin.label("Demand slips/bar/racing: %d / %d / %d" % [int(game.demand.slips), int(game.demand.bar), int(game.demand.racing)], 24))
		if not game.economy.last_ledger.is_empty():
			var L: Dictionary = game.economy.last_ledger
			body.add_child(PanelSkin.label("Last month net %s (in %s / out %s)" % [SimCatalog.money(int(L.get("net", 0))), SimCatalog.money(int(L.get("income", 0))), SimCatalog.money(int(L.get("expense", 0)))], 24))
	var close := PanelSkin.button("Close")
	close.pressed.connect(func(): visible = false)
	body.add_child(close)
