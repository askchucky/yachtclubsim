class_name AnnualCard
extends PanelContainer

signal closed

var body: VBoxContainer


func _ready() -> void:
	PanelSkin.apply_panel(self)
	visible = false
	z_index = 30
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -260
	offset_top = -200
	offset_right = 260
	offset_bottom = 200
	body = VBoxContainer.new()
	add_child(body)


func show_report(report: Dictionary) -> void:
	for c in body.get_children():
		c.queue_free()
	body.add_child(PanelSkin.label("Annual report · Year %d" % int(report.get("year", 1))))
	body.add_child(PanelSkin.label("Cash %s · Loan %s" % [SimCatalog.money(int(report.get("cash", 0))), SimCatalog.money(int(report.get("loan", 0)))], 26))
	var m: Dictionary = report.get("members", {})
	body.add_child(PanelSkin.label("Members %d (R%d S%d C%d)" % [int(m.get("total", 0)), int(m.get("regular", 0)), int(m.get("social", 0)), int(m.get("crew", 0))], 24))
	var s: Dictionary = report.get("slips", {})
	body.add_child(PanelSkin.label("Slips %d filled of %d" % [int(s.get("filled", 0)), int(s.get("total", 0))], 24))
	var d: Dictionary = report.get("demand", {})
	body.add_child(PanelSkin.label("Demand S/B/R %d/%d/%d" % [int(d.get("slips", 0)), int(d.get("bar", 0)), int(d.get("racing", 0))], 24))
	var L: Dictionary = report.get("ledger", {})
	if not L.is_empty():
		body.add_child(PanelSkin.label("Income %s · Expense %s · Net %s" % [SimCatalog.money(int(L.get("income", 0))), SimCatalog.money(int(L.get("expense", 0))), SimCatalog.money(int(L.get("net", 0)))], 22))
	var close := PanelSkin.button("Continue")
	close.pressed.connect(func():
		visible = false
		closed.emit()
	)
	body.add_child(close)
	visible = true


func show_ending(kind: String, text: String) -> void:
	for c in body.get_children():
		c.queue_free()
	body.add_child(PanelSkin.label("Game over"))
	body.add_child(PanelSkin.label(text, 28))
	var again := PanelSkin.button("New Harbor Year")
	again.pressed.connect(func():
		visible = false
		closed.emit()
	)
	body.add_child(again)
	visible = true
