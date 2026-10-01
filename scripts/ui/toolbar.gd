class_name BuildToolbar
extends PanelContainer

signal tool_selected(tool_id: String)

var game: HarborGame
var group := ButtonGroup.new()
var status: Label


func _ready() -> void:
	PanelSkin.apply_panel(self)
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = 8
	offset_top = -78
	offset_right = -8
	offset_bottom = -8
	var v := VBoxContainer.new()
	add_child(v)
	status = PanelSkin.label("Select a tool", 26)
	v.add_child(status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	for t in SimCatalog.tools():
		var b := PanelSkin.button("%s %s" % [t["label"], SimCatalog.money(int(t["cost"]))])
		b.toggle_mode = true
		b.button_group = group
		var id: String = t["id"]
		b.pressed.connect(_on_tool.bind(id, t))
		row.add_child(b)
	var clear := PanelSkin.button("Hand")
	clear.pressed.connect(func():
		tool_selected.emit("")
		status.text = "Pan with right-drag · WASD · Z zoom"
	)
	row.add_child(clear)


func _on_tool(id: String, t: Dictionary) -> void:
	tool_selected.emit(id)
	status.text = "%s · cost %s · upkeep %s/mo" % [t["label"], SimCatalog.money(int(t["cost"])), SimCatalog.money(int(t["upkeep"]))]


func refresh() -> void:
	pass
