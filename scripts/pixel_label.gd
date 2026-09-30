class_name PixelLabel
extends Control

# m5x7 is a 5x7 pixel face. Font size 16 draws it at 1x, 32 at 2x.
const NATIVE := 16
var text := ""
var ink := Color("2a1c10")
var shadow := Color(0.16, 0.1, 0.06, 0.85)
var scale_px := 2
var wrap_width := 280
var plate := Color(0, 0, 0, 0)
var font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font()
	_measure()
	queue_redraw()


func set_text(value: String) -> void:
	text = value
	_measure()
	queue_redraw()


func _font() -> Font:
	if font == null:
		font = load("res://art/m5x7.ttf")
	return font


func _font_size() -> int:
	return NATIVE * maxi(1, scale_px)


func _line_height() -> int:
	# Glyphs are 7px at native size. Keep the lines on that grid.
	return 8 * maxi(1, scale_px)


func _measure() -> void:
	var face := _font()
	var lines := _wrap(text)
	var px := _font_size()
	var widest := 8
	for line in lines:
		var width := int(ceil(face.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x))
		widest = maxi(widest, width)
	custom_minimum_size = Vector2(widest + 2, maxi(_line_height(), lines.size() * _line_height()))
	size = custom_minimum_size


func _draw() -> void:
	var face := _font()
	if plate.a > 0.0:
		draw_rect(Rect2(Vector2(-2, -1), custom_minimum_size + Vector2(4, 2)), plate)
	var lines := _wrap(text)
	var px := _font_size()
	var step := _line_height()
	var baseline0 := float(step - 1)
	for i in lines.size():
		var baseline := baseline0 + float(i * step)
		draw_string(face, Vector2(1, baseline + 1), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, px, shadow)
		draw_string(face, Vector2(0, baseline), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, px, ink)


func _wrap(value: String) -> PackedStringArray:
	var out := PackedStringArray()
	var face := _font()
	var px := _font_size()
	var limit := 100000.0 if wrap_width <= 0 else float(wrap_width)
	for raw in value.split("\n"):
		var line := ""
		for word in raw.split(" "):
			var trial := word if line == "" else line + " " + word
			var width := face.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
			if width > limit and line != "":
				out.append(line)
				line = word
			else:
				line = trial
		out.append(line)
	if out.is_empty():
		out.append("")
	return out
