class_name BoardPanel
extends PanelContainer

var game: HarborGame
var body: VBoxContainer


func _ready() -> void:
	PanelSkin.apply_panel(self)
	visible = false
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 12
	offset_top = 70
	offset_right = 340
	offset_bottom = 460
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
	body.add_child(PanelSkin.label("Board"))
	for id in SimCatalog.BOARD:
		var ap: int = int(game.politics.board.get(id, 0))
		body.add_child(PanelSkin.label("%s  %d" % [SimCatalog.NAMES.get(id, id), ap], 26))
	body.add_child(PanelSkin.label("Flag officers", 28))
	for id in SimCatalog.FLAGS:
		var ap2: int = int(game.politics.advisors.get(id, 0))
		body.add_child(PanelSkin.label("%s  %d" % [SimCatalog.NAMES[id], ap2], 26))
	var seats := game.politics.seats_over(50)
	body.add_child(PanelSkin.label("Seats over 50: %d/5 · big moves %s" % [seats, "OK" if seats >= 3 else "blocked"], 24))
	var assess := PanelSkin.button("Special assessment")
	assess.pressed.connect(func():
		var r := game.politics.try_big_move("special_assessment", game.economy)
		game._post("commodore", r["text"])
		game.changed.emit()
		refresh()
	)
	body.add_child(assess)
	var close := PanelSkin.button("Close")
	close.pressed.connect(func(): visible = false)
	body.add_child(close)
