class_name PanelSkin
extends RefCounted

## Wood-and-parchment UI helpers.


static func font() -> Font:
	return load("res://art/m5x7.ttf")


static func apply_panel(p: PanelContainer) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f3e6c8")
	sb.border_color = Color("773421")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)


static func label(text: String, size: int = 32) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color("3b2a1a"))
	return l


static func button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", 28)
	var n := StyleBoxFlat.new()
	n.bg_color = Color("c49c5c")
	n.border_color = Color("773421")
	n.set_border_width_all(2)
	n.set_corner_radius_all(2)
	n.content_margin_left = 8
	n.content_margin_right = 8
	var h := n.duplicate()
	h.bg_color = Color("d8b06e")
	var pr := n.duplicate()
	pr.bg_color = Color("a56243")
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_color_override("font_color", Color("fff8ea"))
	return b
