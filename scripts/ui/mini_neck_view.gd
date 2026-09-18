class_name MiniNeckView
extends Control

signal range_requested(range_value: Vector2i)

var positions: Array[Dictionary] = []
var visible_range := Vector2i(3, 9)
var fret_count := 24
var string_count := 6


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(480, 68)


func configure(model: Array[Dictionary], strings: int, frets: int, range_value: Vector2i) -> void:
	positions = model.duplicate(true)
	string_count = strings
	fret_count = frets
	visible_range = range_value
	queue_redraw()


func set_visible_range(range_value: Vector2i) -> void:
	visible_range = range_value
	queue_redraw()


func _draw() -> void:
	var neck := Rect2(4, 7, size.x - 8, size.y - 15)
	draw_rect(neck, Color("0c1822"))
	draw_rect(neck, Color("36566c"), false, 1.2)
	for fret in range(fret_count + 1):
		var x := neck.position.x + neck.size.x * float(fret) / float(fret_count)
		draw_line(Vector2(x, neck.position.y), Vector2(x, neck.end.y), Color("334b5e"), 1.0)
	for string_index in range(string_count):
		var y := neck.position.y + neck.size.y * (float(string_index) + 0.5) / float(string_count)
		draw_line(Vector2(neck.position.x, y), Vector2(neck.end.x, y), Color("53697b", 0.65), 1.0)
	for position: Dictionary in positions:
		if not bool(position.get("in_shape", false)):
			continue
		var x := neck.position.x + neck.size.x * float(int(position.fret)) / float(fret_count)
		var row := string_count - 1 - int(position.string_index)
		var y := neck.position.y + neck.size.y * (float(row) + 0.5) / float(string_count)
		draw_circle(Vector2(x, y), 3.2, Color("9ad7ee"))
	var start_x := neck.position.x + neck.size.x * float(visible_range.x) / float(fret_count)
	var end_x := neck.position.x + neck.size.x * float(visible_range.y) / float(fret_count)
	var selection := Rect2(start_x, neck.position.y + 1, maxf(28.0, end_x - start_x), neck.size.y - 2)
	draw_rect(selection, Color("13cdf2", 0.13))
	draw_style_box(_outline(), selection)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_request_at(event.position.x)
	elif event is InputEventScreenTouch and event.pressed:
		_request_at(event.position.x)


func _request_at(x: float) -> void:
	var center_fret := clampi(roundi((x / maxf(size.x, 1.0)) * fret_count), 3, fret_count - 3)
	var width := visible_range.y - visible_range.x
	var start := clampi(center_fret - width / 2, 0, fret_count - width)
	range_requested.emit(Vector2i(start, start + width))


func _outline() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color("18d9fb")
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	return style
