class_name NewsPanel
extends PanelContainer

var game: HarborGame
var body: VBoxContainer


func _ready() -> void:
	PanelSkin.apply_panel(self)
	visible = false
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 12
	offset_top = 70
	offset_right = 420
	offset_bottom = 500
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
	body.add_child(PanelSkin.label("News"))
	var n := 0
	for line in game.news_feed:
		if n >= 12:
			break
		var who: String = str(line.get("who", ""))
		var person: String = str(SimCatalog.NAMES.get(who, who))
		body.add_child(PanelSkin.label("%s — %s" % [person, str(line.get("text", ""))], 22))
		n += 1
	var close := PanelSkin.button("Close")
	close.pressed.connect(func(): visible = false)
	body.add_child(close)
