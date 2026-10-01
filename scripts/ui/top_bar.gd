class_name TopBar
extends PanelContainer

signal speed_changed(speed: int)
signal panel_requested(name: String)

var game: HarborGame
var cash_l: Label
var date_l: Label
var members_l: Label
var slips_l: Label
var channel_l: Label


func _ready() -> void:
	PanelSkin.apply_panel(self)
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	offset_left = 8
	offset_top = 8
	offset_right = -8
	offset_bottom = 56
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	cash_l = PanelSkin.label("$0")
	date_l = PanelSkin.label("Y1 Jan")
	members_l = PanelSkin.label("Members 0")
	slips_l = PanelSkin.label("Slips 0/0")
	channel_l = PanelSkin.label("Channel")
	for l in [date_l, cash_l, members_l, slips_l, channel_l]:
		row.add_child(l)
	row.add_child(_spacer())
	for s in [["II", 0], [">", 1], [">>", 2], [">>>", 3]]:
		var b := PanelSkin.button(s[0])
		var spd: int = s[1]
		b.pressed.connect(func(): speed_changed.emit(spd))
		row.add_child(b)
	for pname in ["Prices", "Budget", "Board", "News", "Reports"]:
		var b2 := PanelSkin.button(pname)
		var panel_name: String = pname.to_lower()
		b2.pressed.connect(func(): panel_requested.emit(panel_name))
		row.add_child(b2)


func _spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func refresh() -> void:
	if game == null:
		return
	cash_l.text = SimCatalog.money(game.economy.cash)
	if game.economy.loan > 0:
		cash_l.text += "  loan %s" % SimCatalog.money(game.economy.loan)
	date_l.text = "Y%d %s · %s" % [game.clock.year, game.clock.month_name(), game.clock.season_name()]
	members_l.text = "Members %d" % game.members()
	slips_l.text = "Slips %d/%d" % [game.grid.filled_slips(), game.grid.slip_count()]
	channel_l.text = "Channel open" if game.channel_open() else "Channel CLOSED"
	channel_l.add_theme_color_override("font_color", Color("2f6b2f") if game.channel_open() else Color("a03030"))
