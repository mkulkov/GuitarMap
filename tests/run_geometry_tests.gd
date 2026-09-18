extends SceneTree

const Geometry := preload("res://scripts/application/fretboard_geometry.gd")


func _init() -> void:
	for viewport_size in [
		Vector2(640, 360), Vector2(800, 360), Vector2(1024, 600), Vector2(1280, 800),
		Vector2(1280, 720), Vector2(1440, 900), Vector2(1920, 1080),
	]:
		_test_all_centers(viewport_size, 6, 24, false)
		_test_all_centers(viewport_size, 6, 24, true)
	_test_edges_and_outside()
	_test_arbitrary_string_and_fret_counts()
	_test_fit_to_viewport()
	_test_physical_fret_spacing()
	print("Geometry tests passed: centers, edges, mirroring, fit-to-width, strings, and fret ranges.")
	quit()


func _test_all_centers(viewport_size: Vector2, strings: int, frets: int, mirrored: bool) -> void:
	var board_rect := Rect2(Vector2(48, 20), Vector2(
		maxf(viewport_size.x - 64.0, float(frets + 1) * 48.0),
		maxf(240.0, float(strings) * 48.0)
	))
	var geometry := Geometry.new(board_rect, strings, frets, mirrored)
	for string_index in strings:
		for fret in frets + 1:
			assert(geometry.hit_test(geometry.position_center(string_index, fret)) == Vector2i(string_index, fret))


func _test_edges_and_outside() -> void:
	var geometry := Geometry.new(Rect2(Vector2(10, 20), Vector2(130, 60)), 3, 4)
	assert(geometry.hit_test(Vector2(10, 20)) == Vector2i(2, 0))
	assert(geometry.hit_test(Vector2(140, 80)) == Vector2i(0, 4))
	assert(geometry.hit_test(Vector2(9.99, 20)) == Vector2i(-1, -1))
	assert(geometry.hit_test(Vector2(140.01, 80)) == Vector2i(-1, -1))
	assert(geometry.hit_test(Vector2(10, 80.01)) == Vector2i(-1, -1))
	var mirrored := Geometry.new(Rect2(Vector2(10, 20), Vector2(130, 60)), 3, 4, true)
	assert(mirrored.hit_test(Vector2(10, 20)) == Vector2i(2, 4))
	assert(mirrored.hit_test(Vector2(140, 80)) == Vector2i(0, 0))


func _test_arbitrary_string_and_fret_counts() -> void:
	for strings in [1, 6, 7]:
		for frets in [12, 24, 36]:
			var geometry := Geometry.new(Rect2(Vector2(3, 7), Vector2(777, 333)), strings, frets)
			assert(geometry.hit_test(geometry.position_center(0, 0)) == Vector2i(0, 0))
			assert(geometry.hit_test(geometry.position_center(strings - 1, frets)) == Vector2i(strings - 1, frets))


func _test_fit_to_viewport() -> void:
	for viewport in [Vector2(640, 360), Vector2(800, 360), Vector2(1280, 720)]:
		var rect := Geometry.fitted_rect(viewport, 6, 24)
		assert(is_equal_approx(rect.position.x, 18.0))
		assert(is_equal_approx(rect.end.x, viewport.x - 4.0))
		assert(rect.position.y >= 10.0 and rect.end.y <= viewport.y - 22.0)
		var geometry := Geometry.new(rect, 6, 24)
		assert(geometry.cell_size().x > 0.0)
		for string_index in 6:
			assert(geometry.hit_test(geometry.position_center(string_index, 0)) == Vector2i(string_index, 0))
			assert(geometry.hit_test(geometry.position_center(string_index, 24)) == Vector2i(string_index, 24))
	var mirrored := Geometry.new(Geometry.fitted_rect(Vector2(640, 360), 7, 36), 7, 36, true)
	assert(mirrored.hit_test(mirrored.position_center(0, 0)) == Vector2i(0, 0))
	assert(mirrored.hit_test(mirrored.position_center(6, 36)) == Vector2i(6, 36))


func _test_physical_fret_spacing() -> void:
	var geometry := Geometry.new(Rect2(Vector2(48, 20), Vector2(1200, 240)), 6, 24)
	var fret_1 := geometry.fret_span(1)
	var fret_12 := geometry.fret_span(12)
	var fret_24 := geometry.fret_span(24)
	assert(fret_1.y - fret_1.x > fret_12.y - fret_12.x)
	assert(fret_12.y - fret_12.x > fret_24.y - fret_24.x)
	for fret in range(1, 25):
		assert(geometry.hit_test(geometry.position_center(0, fret)).y == fret)
