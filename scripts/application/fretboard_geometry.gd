class_name FretboardGeometry
extends RefCounted

var rect: Rect2
var string_count: int
var fret_count: int
var mirrored: bool
var open_string_width: float


func _init(rect_value: Rect2, string_count_value: int, fret_count_value: int, mirrored_value: bool = false) -> void:
	assert(rect_value.size.x > 0.0 and rect_value.size.y > 0.0, "Fretboard rect must have positive size.")
	assert(string_count_value > 0, "Fretboard needs at least one string.")
	assert(fret_count_value >= 0, "Fret count cannot be negative.")
	rect = rect_value
	string_count = string_count_value
	fret_count = fret_count_value
	mirrored = mirrored_value
	# With no body silhouette, the nut needs less reserved space. This gives the
	# playable frets more longitudinal room without changing their 12-TET order.
	open_string_width = clampf(rect.size.x * 0.024, 22.0, 30.0)


func position_center(string_index: int, fret: int) -> Vector2:
	assert(string_index >= 0 and string_index < string_count, "String index is outside the fretboard.")
	assert(fret >= 0 and fret <= fret_count, "Fret is outside the fretboard.")
	var displayed_row := string_count - 1 - string_index
	var center_x := _fret_center_x(fret)
	if mirrored:
		center_x = rect.end.x - (center_x - rect.position.x)
	return Vector2(center_x, rect.position.y + (float(displayed_row) + 0.5) * _cell_size().y)


func hit_test(point: Vector2) -> Vector2i:
	var rect_end := rect.end
	if point.x < rect.position.x or point.x > rect_end.x or point.y < rect.position.y or point.y > rect_end.y:
		return Vector2i(-1, -1)
	var local_x := point.x - rect.position.x
	if mirrored:
		local_x = rect.size.x - local_x
	var displayed_fret := _fret_at_local_x(local_x)
	var cell_size := _cell_size()
	var displayed_row := mini(floori((point.y - rect.position.y) / cell_size.y), string_count - 1)
	return Vector2i(string_count - 1 - displayed_row, displayed_fret)


func _cell_size() -> Vector2:
	return Vector2(rect.size.x / float(fret_count + 1), rect.size.y / float(string_count))


func fret_boundary(fret: int) -> float:
	## Right edge of the open-string area for 0, then the physical fret line for 1..fret_count.
	assert(fret >= 0 and fret <= fret_count, "Fret boundary is outside the fretboard.")
	var local_x := _boundary_local_x(fret)
	return rect.end.x - local_x if mirrored else rect.position.x + local_x


func fret_span(fret: int) -> Vector2:
	assert(fret >= 0 and fret <= fret_count, "Fret span is outside the fretboard.")
	var start_local := 0.0 if fret == 0 else _boundary_local_x(fret - 1)
	var end_local := _boundary_local_x(fret)
	var start_x := rect.end.x - start_local if mirrored else rect.position.x + start_local
	var end_x := rect.end.x - end_local if mirrored else rect.position.x + end_local
	return Vector2(minf(start_x, end_x), maxf(start_x, end_x))


func _boundary_local_x(fret: int) -> float:
	if fret == 0:
		return open_string_width
	var scale_width := rect.size.x - open_string_width
	# Preserve physically shrinking spacing while blending toward the reference's
	# almost-front-on camera view. A literal side-view 12-TET projection makes
	# the final frets too compressed for labels and touch targets at this scale.
	var physical := (1.0 - pow(2.0, -float(fret) / 12.0)) / (1.0 - pow(2.0, -float(fret_count) / 12.0))
	var uniform := float(fret) / float(fret_count)
	var normalized := lerpf(uniform, physical, 0.22)
	return open_string_width + scale_width * normalized


func _fret_center_x(fret: int) -> float:
	var start_local := 0.0 if fret == 0 else _boundary_local_x(fret - 1)
	var end_local := _boundary_local_x(fret)
	return rect.position.x + (start_local + end_local) * 0.5


func _fret_at_local_x(local_x: float) -> int:
	if local_x <= open_string_width:
		return 0
	for fret in range(1, fret_count + 1):
		if local_x <= _boundary_local_x(fret):
			return fret
	return fret_count


func cell_size() -> Vector2:
	return _cell_size()


static func fitted_rect(viewport_size: Vector2, string_count_value: int, fret_count_value: int, left_margin: float = 18.0, top_margin: float = 10.0, right_margin: float = 4.0, bottom_margin: float = 22.0, neck_scale: float = 1.0) -> Rect2:
	assert(viewport_size.x > left_margin + right_margin and viewport_size.y > top_margin + bottom_margin, "Viewport is too small for fretboard margins.")
	assert(string_count_value > 0 and fret_count_value >= 0, "Fretboard dimensions are invalid.")
	# A 650 mm classical scale with roughly 42 mm outer string spread at the nut
	# is very long relative to its string pitch. Keep that visual relationship
	# on screen while retaining enough row clearance for the large note markers.
	# The requested 1.5x neck width is applied only on the transverse axis;
	# longitudinal fret spacing remains governed by the same x geometry.
	# The fretboard is the primary instrument surface. Give each string enough
	# vertical room for a 40 px note marker at the 1280 px reference size.
	# Keep a compact top margin so the neck remains visually balanced below the
	# header instead of centring a shallow board in a large empty viewport.
	var effective_top_margin := maxf(top_margin, minf(56.0 * neck_scale, viewport_size.y * 0.15))
	var preferred_height := maxf(float(string_count_value) * 56.0, viewport_size.y * 0.48) * maxf(neck_scale, 0.1)
	var board_height := minf(viewport_size.y - effective_top_margin - bottom_margin, preferred_height)
	return Rect2(
		Vector2(left_margin, effective_top_margin),
		Vector2(viewport_size.x - left_margin - right_margin, board_height)
	)
