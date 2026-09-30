class_name UiSkin
extends RefCounted


static func frame(down: bool = false) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	var path := "res://art/frame_down.png" if down else "res://art/frame.png"
	box.texture = load(path)
	box.texture_margin_left = 8
	box.texture_margin_right = 8
	box.texture_margin_top = 8
	box.texture_margin_bottom = 8
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box


static func paint_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", frame(false))
	button.add_theme_stylebox_override("hover", frame(true))
	button.add_theme_stylebox_override("pressed", frame(true))
	button.add_theme_stylebox_override("disabled", frame(false))
	button.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
