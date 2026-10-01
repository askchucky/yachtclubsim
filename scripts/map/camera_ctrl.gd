class_name CameraCtrl
extends Camera2D

## Pan with middle/right drag or WASD; zoom 1x/2x/3x integer.

var zoom_level: int = 1
var dragging := false
var drag_last := Vector2.ZERO
var bounds := Rect2(0, 0, 3072, 1728)


func _ready() -> void:
	position_smoothing_enabled = false
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	_apply_zoom()


func set_bounds_from_map(size_px: Vector2) -> void:
	bounds = Rect2(Vector2.ZERO, size_px)
	position = size_px * 0.5


func _apply_zoom() -> void:
	zoom = Vector2(zoom_level, zoom_level)


func cycle_zoom() -> void:
	zoom_level = 1 if zoom_level >= 3 else zoom_level + 1
	_apply_zoom()


func set_zoom_level(z: int) -> void:
	zoom_level = clampi(z, 1, 3)
	_apply_zoom()


func _process(delta: float) -> void:
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move.x += 1
	if move != Vector2.ZERO:
		position += move.normalized() * 400.0 * delta / float(zoom_level)
		_clamp()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			dragging = mb.pressed
			drag_last = mb.position
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			set_zoom_level(zoom_level + 1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			set_zoom_level(zoom_level - 1)
	elif event is InputEventMouseMotion and dragging:
		var mm := event as InputEventMouseMotion
		position -= mm.relative / zoom
		drag_last = mm.position
		_clamp()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z:
			cycle_zoom()


func _clamp() -> void:
	var half := get_viewport_rect().size * 0.5 / zoom
	position.x = clampf(position.x, bounds.position.x + half.x, bounds.end.x - half.x)
	position.y = clampf(position.y, bounds.position.y + half.y, bounds.end.y - half.y)
