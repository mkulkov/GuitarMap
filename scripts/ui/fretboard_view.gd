class_name LearningFretboardView
extends Control

const AppTheme = preload("res://scripts/ui/app_theme.gd")

signal position_pressed(owner_id: int, position: Dictionary)
signal position_moved(owner_id: int, position: Dictionary)
signal position_released(owner_id: int)
signal zoom_changed(value: float)

var positions: Array[Dictionary] = []
var string_count := 6
var fret_count := 24
var mirrored := false
var display_mode := 2
var cell_size := 48
var geometry: FretboardGeometry
var active: Dictionary = {}
var playback_keys: Dictionary = {}
var open_string_labels: Array[String] = []
var visible_range := Vector2i(3, 9)
var topic := "caged"
var layer := "chord"
var practice_hidden := false
var practice_target_pitch_class := -1
var feedback_key := Vector2i(-1, -1)
var feedback_correct := false
var zoom := 1.0

var _lookup: Dictionary = {}
var _shape_lookup: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_rebuild_geometry)
	_rebuild_geometry()


func configure(model: Array[Dictionary], strings: int, frets: int, mirror: bool = false, string_labels: Array[String] = [], range_value: Vector2i = Vector2i(-1, -1)) -> void:
	positions = model.duplicate(true)
	string_count = maxi(1, strings)
	fret_count = maxi(0, frets)
	mirrored = mirror
	open_string_labels = string_labels.duplicate()
	if range_value.x >= 0 and range_value.y >= range_value.x:
		visible_range = Vector2i(clampi(range_value.x, 0, fret_count), clampi(range_value.y, 0, fret_count))
	_lookup.clear()
	_shape_lookup.clear()
	for position: Dictionary in positions:
		var key := Vector2i(int(position.string_index), int(position.fret))
		_lookup[key] = position
		if bool(position.get("in_shape", false)):
			_shape_lookup[key] = true
	custom_minimum_size = Vector2(520, 260)
	_rebuild_geometry()


func set_learning_context(topic_value: String, layer_value: String) -> void:
	topic = topic_value
	layer = layer_value
	queue_redraw()


func set_visible_range(range_value: Vector2i) -> void:
	visible_range = Vector2i(clampi(range_value.x, 0, fret_count), clampi(range_value.y, 0, fret_count))
	_rebuild_geometry()


func set_practice_mode(hidden: bool, target_pitch_class: int = -1) -> void:
	practice_hidden = hidden
	practice_target_pitch_class = target_pitch_class
	feedback_key = Vector2i(-1, -1)
	queue_redraw()


func show_practice_feedback(position: Dictionary, correct: bool) -> void:
	feedback_key = Vector2i(int(position.get("string_index", -1)), int(position.get("fret", -1)))
	feedback_correct = correct
	queue_redraw()


func fit_to_viewport_width(_width: float) -> void:
	_rebuild_geometry()


func fit_to_viewport(_viewport_size: Vector2) -> void:
	_rebuild_geometry()


func set_cell_size(value: int) -> void:
	cell_size = maxi(44, value)
	queue_redraw()


func set_zoom(value: float) -> void:
	zoom = clampf(value, 0.8, 1.8)
	zoom_changed.emit(zoom)
	queue_redraw()


func zoom_in() -> void:
	set_zoom(zoom + 0.1)


func zoom_out() -> void:
	set_zoom(zoom - 0.1)


func _rebuild_geometry() -> void:
	var display_frets := maxi(0, visible_range.y - visible_range.x)
	var viewport := Vector2(maxf(size.x, 100.0), maxf(size.y, 110.0))
	var left_margin := 56.0 if size.x > 700.0 else 44.0
	var rect := Rect2(
		Vector2(left_margin, 7.0),
		Vector2(maxf(40.0, viewport.x - left_margin - 8.0), maxf(60.0, viewport.y - 39.0))
	)
	geometry = FretboardGeometry.new(
		rect,
		string_count,
		display_frets,
		mirrored
	)
	# A cropped learning window has no open-string cell. Make its first visible
	# fret the same visual width as its neighbours instead of inheriting the
	# narrow nut reservation used by the full-neck geometry.
	geometry.open_string_width = geometry.rect.size.x / float(display_frets + 1)
	queue_redraw()


func position_center_for(string_index: int, fret: int) -> Vector2:
	if geometry == null or fret < visible_range.x or fret > visible_range.y:
		return Vector2(-1000, -1000)
	return geometry.position_center(string_index, fret - visible_range.x)


func _draw() -> void:
	if geometry == null:
		return
	_draw_neck()
	_draw_shape_contour()
	_draw_markers()


func _draw_neck() -> void:
	var board := geometry.rect
	draw_style_box(_box(Color("060b10"), Color("14394d"), 8, 1), board.grow(4.0))
	draw_rect(board, Color("151d24"))
	for band in 14:
		var y := board.position.y + board.size.y * (float(band) + 0.5) / 14.0
		draw_line(Vector2(board.position.x, y), Vector2(board.end.x, y + sin(float(band) * 1.7) * 1.6), Color("a8c1ce", 0.035), 1.0)
	for local_fret in range(geometry.fret_count + 1):
		var span := geometry.fret_span(local_fret)
		var x := span.x
		draw_line(Vector2(x + 1.5, board.position.y), Vector2(x + 1.5, board.end.y), Color("020609", 0.75), 3.0)
		draw_line(Vector2(x, board.position.y), Vector2(x, board.end.y), Color("d6d5d0", 0.68), 1.2)
		var actual_fret := visible_range.x + local_fret
		var center_x := geometry.position_center(0, local_fret).x
		_text(Vector2(center_x - 20.0, board.end.y + 25.0), str(actual_fret), 15, Color("829fbe"), 40.0)
		if actual_fret in [3, 5, 7, 9, 12, 15, 17, 19, 21, 24]:
			if actual_fret in [12, 24]:
				draw_circle(Vector2(center_x, board.position.y + board.size.y * 0.38), 3.5, Color("667486"))
				draw_circle(Vector2(center_x, board.position.y + board.size.y * 0.62), 3.5, Color("667486"))
			else:
				draw_circle(Vector2(center_x, board.get_center().y), 4.0, Color("667486"))
	draw_line(Vector2(board.end.x, board.position.y), Vector2(board.end.x, board.end.y), Color("d6d5d0", 0.68), 1.2)
	for string_index in range(string_count):
		var center := geometry.position_center(string_index, 0)
		var thickness := 0.9 + float(string_count - string_index) * 0.20
		draw_line(Vector2(board.position.x, center.y + 1.0), Vector2(board.end.x, center.y + 1.0), Color("020407", 0.8), thickness + 1.6)
		draw_line(Vector2(board.position.x, center.y), Vector2(board.end.x, center.y), Color("d6d2cb", 0.78), thickness)
		var open_note := open_string_labels[string_index] if string_index < open_string_labels.size() else str(string_index + 1)
		var label_center := Vector2(board.position.x - 37.0, center.y)
		var label_radius := minf(21.0, board.size.y / float(string_count) * 0.43)
		draw_circle(label_center, label_radius, Color("071a2a"))
		draw_arc(label_center, label_radius, 0.0, TAU, 40, Color("173d5c"), 1.2, true)
		var label_size := mini(17, roundi(label_radius * 1.1))
		_text(label_center + Vector2(-18.0, label_size * 0.35), open_note, label_size, Color("d7e8ff"), 36.0)


func _draw_shape_contour() -> void:
	if topic != "caged" or layer != "chord" or _shape_lookup.is_empty() or practice_hidden:
		return
	var path: Array[Vector2] = []
	for displayed_row in range(string_count):
		var string_index := string_count - 1 - displayed_row
		for key: Vector2i in _shape_lookup:
			if key.x == string_index and key.y >= visible_range.x and key.y <= visible_range.y:
				path.append(position_center_for(key.x, key.y))
				break
	if path.size() < 2:
		return
	var half_width := maxf(_marker_radius() * 1.35, geometry.cell_size().x * 0.44)
	var half_row := geometry.cell_size().y * 0.48
	var transition := geometry.cell_size().y * 0.18
	var left_edge: Array[Vector2] = [path[0] + Vector2(-half_width, -half_row)]
	var right_edge: Array[Vector2] = [path[0] + Vector2(half_width, -half_row)]
	# Expand the region before contracting the opposite edge. This creates
	# connected fret-cell terraces, not a diagonal line suggesting note order.
	for index in range(path.size() - 1):
		var current := path[index]
		var following := path[index + 1]
		var middle_y := (current.y + following.y) * 0.5
		var direction := signf(following.x - current.x)
		var left_y := middle_y + direction * transition
		var right_y := middle_y - direction * transition
		left_edge.append(Vector2(current.x - half_width, left_y))
		left_edge.append(Vector2(following.x - half_width, left_y))
		right_edge.append(Vector2(current.x + half_width, right_y))
		right_edge.append(Vector2(following.x + half_width, right_y))
	left_edge.append(path[-1] + Vector2(-half_width, half_row))
	right_edge.append(path[-1] + Vector2(half_width, half_row))
	right_edge.reverse()
	var outline: Array[Vector2] = []
	for point in left_edge + right_edge:
		var bounded := Vector2(clampf(point.x, geometry.rect.position.x + 2, geometry.rect.end.x - 2), clampf(point.y, geometry.rect.position.y + 2, geometry.rect.end.y - 2))
		if outline.is_empty() or outline[-1].distance_to(bounded) > 0.1:
			outline.append(bounded)
	var rounded := _rounded_polygon(outline, minf(20.0, half_row * 0.5))
	if rounded.size() >= 3:
		draw_colored_polygon(rounded, Color("27d6f2", 0.12))
		var closed := rounded.duplicate()
		closed.append(rounded[0])
		draw_polyline(closed, Color("32d9f2", 0.46), 1.5, true)


func _rounded_polygon(points: Array[Vector2], radius: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in points.size():
		var corner := points[index]
		var previous := points[posmod(index - 1, points.size())]
		var following := points[(index + 1) % points.size()]
		var entry := corner + (previous - corner).normalized() * minf(radius, corner.distance_to(previous) * 0.45)
		var exit_point := corner + (following - corner).normalized() * minf(radius, corner.distance_to(following) * 0.45)
		for step in 7:
			var weight := float(step) / 6.0
			result.append(entry.lerp(corner, weight).lerp(corner.lerp(exit_point, weight), weight))
	return result

func _draw_markers() -> void:
	for position: Dictionary in positions:
		var fret := int(position.fret)
		if fret < visible_range.x or fret > visible_range.y:
			continue
		var key := Vector2i(int(position.string_index), fret)
		var center := position_center_for(key.x, key.y)
		var root := bool(position.get("is_root", position.get("is_tonic", false)))
		var in_scale := bool(position.get("in_scale", true))
		var in_chord := bool(position.get("in_chord", position.get("is_chord_tone", false)))
		var in_shape := bool(position.get("in_shape", false))
		var bright := _is_bright(in_scale, in_chord, in_shape, root)
		if practice_hidden:
			bright = false
		var shape_overlay := topic == "caged" and layer == "scale" and in_shape and not practice_hidden
		if not in_scale and not bright and not practice_hidden and not shape_overlay:
			continue
		var radius := _marker_radius()
		if shape_overlay and not in_scale:
			_draw_outside_scale_marker(center, radius, position)
		elif bright:
			_draw_learning_marker(center, radius, position, root)
		else:
			_draw_context_marker(center, radius * 0.78, position, practice_hidden)
		if shape_overlay and in_scale:
			draw_arc(center, radius + 4.0, 0.0, TAU, 48, Color("d5f6ff"), 2.0, true)
		if active.values().has(key) or playback_keys.has(key):
			draw_circle(center, radius + 8.0, Color("45dcff", 0.13))
			draw_arc(center, radius + 8.0, 0.0, TAU, 48, Color("5eeaff"), 2.4, true)
		if key == feedback_key:
			draw_arc(center, radius + 11.0, 0.0, TAU, 48, Color("69e49a") if feedback_correct else Color("ff6c79"), 4.0, true)


func _is_bright(in_scale: bool, in_chord: bool, in_shape: bool, root: bool) -> bool:
	if layer == "roots":
		return root and (topic != "caged" or in_shape)
	if layer == "scale":
		return in_scale
	if topic == "caged":
		return in_shape
	return in_chord


func _draw_outside_scale_marker(center: Vector2, radius: float, position: Dictionary) -> void:
	var color := Color("ffc77a")
	draw_circle(center, radius, Color("111c28"))
	for segment in 12:
		var angle := TAU * float(segment) / 12.0
		draw_arc(center, radius + 4.0, angle, angle + TAU / 18.0, 5, color, 2.0, true)
	_text(center + Vector2(-radius, -1.0), _pretty_note(str(position.note)), int(radius * 0.82), color, radius * 2.0)
	_text(center + Vector2(-radius, radius * 0.55), str(position.degree), int(radius * 0.50), color, radius * 2.0)
	var badge := center + Vector2(radius * 0.80, -radius * 0.80)
	draw_circle(badge, 9.0, color)
	_text(badge + Vector2(-7, 5), "!", 14, Color("111c28"), 14)


func _draw_context_marker(center: Vector2, radius: float, position: Dictionary, hidden: bool) -> void:
	draw_circle(center, radius, Color("314154", 0.54))
	draw_arc(center, radius, 0.0, TAU, 32, Color("8097b2", 0.55), 1.3, true)
	if not hidden:
		_text(center + Vector2(-radius, 5.0), _pretty_note(str(position.get("note", ""))), int(radius * 0.9), Color("b3c2d5"), radius * 2.0)


func _draw_learning_marker(center: Vector2, radius: float, position: Dictionary, root: bool) -> void:
	var interval := posmod(int(position.get("interval", 0)), 12)
	var color := AppTheme.NOTE_ROOT if root else (Color("9168f3") if interval in [3, 4] else (Color("2ed3f2") if interval == 7 else AppTheme.note_color_for_interval(interval)))
	draw_circle(center, radius + 7.0, Color(color.r, color.g, color.b, 0.13))
	if root:
		var corners: Array[Vector2] = [center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)]
		var diamond := _rounded_polygon(corners, radius * 0.14)
		draw_colored_polygon(diamond, color)
		draw_polyline(PackedVector2Array(Array(diamond) + [diamond[0]]), color.lightened(0.35), 1.5, true)
	else:
		draw_circle(center, radius, color)
		draw_arc(center, radius, 0.0, TAU, 40, color.lightened(0.35), 1.4, true)
	var note := _pretty_note(str(position.get("note", "")))
	var degree := str(position.get("degree", ""))
	_text(center + Vector2(-radius, -1.0), note, int(radius * 0.82), Color("061018"), radius * 2.0)
	_text(center + Vector2(-radius, radius * 0.55), degree, int(radius * 0.50), Color("061018"), radius * 2.0)


func _marker_radius() -> float:
	if geometry == null:
		return 18.0
	return clampf(geometry.cell_size().y * 0.36, 14.0, 32.0)


func set_playback_midi(midi_note: int) -> void:
	playback_keys.clear()
	for position: Dictionary in positions:
		if int(position.midi_note) == midi_note:
			playback_keys[Vector2i(int(position.string_index), int(position.fret))] = true
	queue_redraw()


func set_playback_position(position: Dictionary) -> void:
	playback_keys.clear()
	if not position.is_empty():
		playback_keys[Vector2i(int(position.string_index), int(position.fret))] = true
	queue_redraw()


func add_playback_position(position: Dictionary) -> void:
	if not position.is_empty():
		playback_keys[Vector2i(int(position.string_index), int(position.fret))] = true
	queue_redraw()


func clear_playback_highlight() -> void:
	playback_keys.clear()
	queue_redraw()


func position_at(point: Vector2) -> Dictionary:
	if geometry == null:
		return {}
	var local_key := geometry.hit_test(point)
	if local_key.x < 0:
		return {}
	return _lookup.get(Vector2i(local_key.x, local_key.y + visible_range.x), {}).duplicate(true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not OS.has_feature("mobile") and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(-1, event.position)
		else:
			_release(-1)
		accept_event()
	elif event is InputEventMouseMotion and not OS.has_feature("mobile") and active.has(-1):
		_move(-1, event.position)
	elif event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			_press(event.index, event.position)
		else:
			_release(event.index)
		accept_event()
	elif event is InputEventScreenDrag:
		_move(event.index, event.position)
		accept_event()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not OS.has_feature("mobile") and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_release(-1)
	elif event is InputEventScreenTouch and (not event.pressed or event.canceled):
		_release(event.index)


func _press(owner: int, point: Vector2) -> void:
	var position := position_at(point)
	if position.is_empty():
		return
	active[owner] = Vector2i(int(position.string_index), int(position.fret))
	position_pressed.emit(owner, position)
	queue_redraw()


func _move(owner: int, point: Vector2) -> void:
	if not active.has(owner):
		return
	var position := position_at(point)
	var key := Vector2i(int(position.get("string_index", -1)), int(position.get("fret", -1)))
	if active[owner] == key:
		return
	active[owner] = key
	position_moved.emit(owner, position)
	queue_redraw()


func _release(owner: int) -> void:
	if active.erase(owner):
		position_released.emit(owner)
		queue_redraw()


func clear_contacts() -> void:
	for owner: int in active.keys():
		_release(owner)


func _text(at: Vector2, value: String, font_size: int, color: Color, width: float) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_CENTER, width, maxi(9, font_size), color)


func _pretty_note(value: String) -> String:
	return value.replace("#", "♯").replace("b", "♭")


func _box(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
