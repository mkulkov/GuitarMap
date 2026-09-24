class_name LearningFretboardView
extends Control

const AppTheme = preload("res://scripts/ui/app_theme.gd")

signal position_pressed(owner_id: int, position: Dictionary)
signal position_moved(owner_id: int, position: Dictionary)
signal position_released(owner_id: int)
signal zoom_changed(value: float)
signal position_inspected(position: Dictionary)
signal fret_navigation_requested(delta: int)

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
var comparison_roles: Dictionary = {}
var box_keys: Dictionary = {}
var chord_voicing_keys: Dictionary = {}
var focus_intervals: Array = []
var highlighted_pitch_class := -1
var route_positions: Array[Dictionary] = []
var previous_shape: Array[Dictionary] = []
var transition_progress := 1.0
var _transition_tween: Tween
var _hold_started: Dictionary = {}
var _navigation_starts: Dictionary = {}

var _lookup: Dictionary = {}
var _shape_lookup: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_rebuild_geometry)
	_rebuild_geometry()
	set_process(true)


func _process(_delta: float) -> void:
	for owner: int in _hold_started.keys():
		if Time.get_ticks_msec() - int(_hold_started[owner]) >= 550:
			_hold_started.erase(owner)
			if active.has(owner):
				var inspected: Dictionary = _lookup.get(active[owner], {}).duplicate(true)
				_release(owner)
				if not inspected.is_empty(): position_inspected.emit(inspected)
			break


func show_shape_transition(old_positions: Array[Dictionary]) -> void:
	previous_shape = old_positions.duplicate(true)
	transition_progress = 0.0
	if _transition_tween != null: _transition_tween.kill()
	_transition_tween = create_tween()
	_transition_tween.tween_method(_set_transition_progress, 0.0, 1.0, 0.65)
	queue_redraw()


func _set_transition_progress(value: float) -> void:
	transition_progress = value
	queue_redraw()


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
	_draw_study_overlays()


func _draw_study_overlays() -> void:
	if practice_hidden: return
	for old: Dictionary in previous_shape:
		if old.fret < visible_range.x or old.fret > visible_range.y: continue
		var key := Vector2i(int(old.string_index), int(old.fret))
		var center := position_center_for(key.x, key.y)
		if _shape_lookup.has(key):
			draw_arc(center, _marker_radius() + 5, 0, TAU, 40, Color("e9fbff"), 3, true)
		elif transition_progress < 1.0:
			draw_circle(center, _marker_radius(), Color(0.5, 0.7, 0.8, (1.0 - transition_progress) * 0.6))
	for index in route_positions.size():
		var point: Dictionary = route_positions[index]
		if point.fret < visible_range.x or point.fret > visible_range.y: continue
		var center := position_center_for(int(point.string_index), int(point.fret))
		if index > 0:
			var prior: Dictionary = route_positions[index - 1]
			var start := position_center_for(int(prior.string_index), int(prior.fret))
			if start.x > -100:
				var vector := (center - start).normalized()
				var end := center - vector * (_marker_radius() + 4)
				draw_line(start + vector * (_marker_radius() + 4), end, Color("d7faff", 0.65), 2, true)
				draw_line(end, end - vector.rotated(0.5) * 9, Color("d7faff"), 2, true)
				draw_line(end, end - vector.rotated(-0.5) * 9, Color("d7faff"), 2, true)
		var label := str(index + 1)
		if int(point.get("suggested_finger", -1)) >= 0: label += "/" + str(point.suggested_finger)
		var at := center + Vector2(-20, -_marker_radius() - 10)
		draw_style_box(_box(Color("061520"), Color("8de8ff"), 4, 1), Rect2(at - Vector2(0, 13), Vector2(40, 18)))
		_text(at, label, 12, Color("effcff"), 40)


func _draw_neck() -> void:
	var board := geometry.rect
	draw_style_box(_box(Color("060b10"), Color("14394d"), 8, 1), board.grow(4.0))
	draw_rect(board, Color("151d24"))
	for band in 14:
		var y := board.position.y + board.size.y * (float(band) + 0.5) / 14.0
		draw_line(Vector2(board.position.x, y), Vector2(board.end.x, y + sin(float(band) * 1.7) * 1.6), Color("a8c1ce", 0.035), 1.0)
	_draw_box_background()
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


func _draw_box_background() -> void:
	if topic != "scales" or box_keys.is_empty() or practice_hidden or highlighted_pitch_class >= 0:
		return
	var rows: Array[Vector3] = []
	var padding := minf(geometry.cell_size().x * 0.42, _marker_radius() + 12.0)
	for string_index in string_count:
		var left := INF
		var right := -INF
		var row_y := 0.0
		for key: Vector2i in box_keys:
			if key.x != string_index or key.y < visible_range.x or key.y > visible_range.y: continue
			var center := position_center_for(key.x, key.y)
			left = minf(left, center.x - padding)
			right = maxf(right, center.x + padding)
			row_y = center.y
		if left != INF:
			rows.append(Vector3(row_y, maxf(left, geometry.rect.position.x + 2), minf(right, geometry.rect.end.x - 2)))
	if rows.is_empty(): return
	rows.sort_custom(func(a: Vector3, b: Vector3): return a.x < b.x)
	var half_row := geometry.cell_size().y * 0.46
	var left_edge: Array[Vector2] = [Vector2(rows[0].y, maxf(geometry.rect.position.y + 2, rows[0].x - half_row))]
	var right_edge: Array[Vector2] = [Vector2(rows[0].z, left_edge[0].y)]
	for index in range(rows.size() - 1):
		var middle := (rows[index].x + rows[index + 1].x) * 0.5
		left_edge.append(Vector2(rows[index].y, middle))
		left_edge.append(Vector2(rows[index + 1].y, middle))
		right_edge.append(Vector2(rows[index].z, middle))
		right_edge.append(Vector2(rows[index + 1].z, middle))
	var bottom := minf(geometry.rect.end.y - 2, rows[-1].x + half_row)
	left_edge.append(Vector2(rows[-1].y, bottom))
	right_edge.append(Vector2(rows[-1].z, bottom))
	right_edge.reverse()
	var outline: Array[Vector2] = []
	for point in left_edge + right_edge:
		if outline.is_empty() or outline[-1].distance_to(point) > 0.1: outline.append(point)
	var rounded := _rounded_polygon(outline, minf(12.0, half_row * 0.4))
	if rounded.size() < 3: return
	draw_colored_polygon(rounded, Color("35cfe5", 0.065))
	rounded.append(rounded[0])
	draw_polyline(rounded, Color("68dce9", 0.23), 1.2, true)


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
		if topic == "chords" and layer == "chord" and not chord_voicing_keys.is_empty():
			bright = chord_voicing_keys.has(key)
		if not focus_intervals.is_empty(): bright = bright and focus_intervals.has(int(position.interval))
		var comparison := str(comparison_roles.get(key, ""))
		if comparison == "common": bright = false
		if comparison == "added": bright = true
		if highlighted_pitch_class >= 0: bright = int(position.pitch_class) == highlighted_pitch_class
		if not box_keys.is_empty() and highlighted_pitch_class < 0: bright = bright and box_keys.has(key)
		if practice_hidden:
			bright = false
		var shape_overlay := topic == "caged" and layer == "scale" and in_shape and not practice_hidden
		if not in_scale and not bright and not practice_hidden and not shape_overlay and comparison != "removed":
			continue
		var radius := _marker_radius()
		if comparison == "removed" and not practice_hidden:
			_draw_context_marker(center, radius, position, false)
			_text(center + Vector2(radius - 3, -radius + 5), "−", 19, Color("ffc77a"), 20)
		elif shape_overlay and not in_scale:
			_draw_outside_scale_marker(center, radius, position)
		elif bright:
			_draw_learning_marker(center, radius, position, root)
		else:
			_draw_context_marker(center, radius * 0.78, position, practice_hidden)
		if shape_overlay and in_scale:
			draw_arc(center, radius + 4.0, 0.0, TAU, 48, Color("d5f6ff"), 2.0, true)
		if comparison == "added" and not practice_hidden:
			_text(center + Vector2(radius - 3, -radius + 5), "+", 19, Color("b0ffcb"), 20)
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
	if topic == "caged" and bool(position.get("in_shape", false)) and not previous_shape.is_empty():
		var stayed := previous_shape.any(func(old: Dictionary): return old.string_index == position.string_index and old.fret == position.fret)
		if not stayed: color.a = lerpf(0.25, 1.0, transition_progress)
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
	return clampf(minf(geometry.cell_size().y * 0.36, geometry.cell_size().x * 0.34), 8.0, 32.0)


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
			if _is_marker_at(event.position):
				_press(-1, event.position)
			else:
				_begin_navigation(-1, event.position)
		else:
			_end_pointer(-1)
		accept_event()
	elif event is InputEventMouseMotion and not OS.has_feature("mobile"):
		if _navigation_starts.has(-1):
			_drag_navigation(-1, event.position)
		elif active.has(-1):
			_move(-1, event.position)
	elif event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			if _is_marker_at(event.position):
				_press(event.index, event.position)
			else:
				_begin_navigation(event.index, event.position)
		else:
			_end_pointer(event.index)
		accept_event()
	elif event is InputEventScreenDrag:
		if _navigation_starts.has(event.index):
			_drag_navigation(event.index, event.position)
		else:
			_move(event.index, event.position)
		accept_event()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not OS.has_feature("mobile") and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_end_pointer(-1)
	elif event is InputEventScreenTouch and (not event.pressed or event.canceled):
		_end_pointer(event.index)


func _is_marker_at(point: Vector2) -> bool:
	if geometry == null:
		return false
	var hit_radius := _marker_radius() + 8.0
	for position: Dictionary in positions:
		var fret := int(position.fret)
		if fret < visible_range.x or fret > visible_range.y:
			continue
		if point.distance_to(position_center_for(int(position.string_index), fret)) <= hit_radius:
			return true
	return false


func _begin_navigation(owner: int, point: Vector2) -> void:
	_navigation_starts[owner] = point


func _drag_navigation(owner: int, point: Vector2) -> void:
	if not _navigation_starts.has(owner):
		return
	var start: Vector2 = _navigation_starts[owner]
	var threshold := maxf(36.0, geometry.cell_size().x * 0.55) if geometry != null else 48.0
	if absf(point.x - start.x) < threshold:
		return
	# Dragging left reveals higher frets; dragging right reveals lower frets.
	var direction := 1 if point.x < start.x else -1
	_navigation_starts[owner] = start + Vector2(threshold * -direction, 0.0)
	fret_navigation_requested.emit(direction * 3)


func _end_pointer(owner: int) -> void:
	_navigation_starts.erase(owner)
	_release(owner)


func _press(owner: int, point: Vector2) -> void:
	var position := position_at(point)
	if position.is_empty():
		return
	active[owner] = Vector2i(int(position.string_index), int(position.fret))
	_hold_started[owner] = Time.get_ticks_msec()
	position_pressed.emit(owner, position)
	queue_redraw()


func _move(owner: int, point: Vector2) -> void:
	if not active.has(owner):
		return
	var position := position_at(point)
	var key := Vector2i(int(position.get("string_index", -1)), int(position.get("fret", -1)))
	if active[owner] == key:
		return
	_hold_started.erase(owner)
	active[owner] = key
	position_moved.emit(owner, position)
	queue_redraw()


func _release(owner: int) -> void:
	_hold_started.erase(owner)
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
