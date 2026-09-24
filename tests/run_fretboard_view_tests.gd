extends SceneTree

const Board := preload("res://scripts/ui/fretboard_view.gd")
const Learning := preload("res://scripts/application/learning_model.gd")
var pressed: Array[Dictionary] = []
var released: Array[int] = []
var navigation_deltas: Array[int] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var board := Board.new()
	root.add_child(board)
	var learning := Learning.new()
	var model := learning.positions()
	board.position_pressed.connect(func(owner: int, position: Dictionary): pressed.append({"owner": owner, "position": position}))
	board.position_released.connect(func(owner: int): released.append(owner))
	board.fret_navigation_requested.connect(func(delta: int): navigation_deltas.append(delta))
	for dimensions in [Vector2(640, 300), Vector2(1000, 450), Vector2(1280, 560)]:
		board.size = dimensions
		board.configure(model, 6, 24, false, [], Vector2i(3, 9))
		await process_frame
		assert(board.geometry.rect.end.x <= board.size.x + 0.01)
		assert(board.geometry.rect.end.y <= board.size.y + 0.01)
		for string_index in 6:
			for fret in range(3, 10):
				var center := board.position_center_for(string_index, fret)
				var position := board.position_at(center)
				assert(position.string_index == string_index and position.fret == fret)
				assert(position.midi_note == [40, 45, 50, 55, 59, 64][string_index] + fret)
		assert(board.position_at(Vector2(-5, -5)).is_empty())
		# A cropped fretted column is not the narrow open-string/nut strip.
		var first_span := board.geometry.fret_span(0)
		var second_span := board.geometry.fret_span(1)
		assert(first_span.y - first_span.x >= (second_span.y - second_span.x) * 0.7)
	board._press(1, board.position_center_for(0, 5))
	board._press(2, board.position_center_for(5, 5))
	assert(board.active.size() == 2)
	assert(pressed.size() == 2)
	assert(pressed[0].position.midi_note == 45 and pressed[1].position.midi_note == 69)
	board._release(1)
	assert(board.active.size() == 1 and board.active.has(2))
	assert(released == [1])
	board.clear_contacts()
	assert(board.active.is_empty() and released == [1, 2])
	board.set_playback_position(model.filter(func(p: Dictionary): return p.string_index == 0 and p.fret == 5)[0])
	assert(board.playback_keys.size() == 1 and board.playback_keys.has(Vector2i(0, 5)))
	board.clear_playback_highlight()
	assert(board.playback_keys.is_empty())
	board.set_practice_mode(true, 9)
	assert(board.practice_hidden)
	board.set_practice_mode(false)
	assert(not board.practice_hidden)
	var free_point := (board.position_center_for(0, 3) + board.position_center_for(1, 4)) * 0.5
	assert(not board._is_marker_at(free_point))
	var swipe_distance := maxf(100.0, board.geometry.cell_size().x * 1.2)
	board._begin_navigation(-1, free_point)
	board._drag_navigation(-1, free_point + Vector2(-swipe_distance, 0))
	board._drag_navigation(-1, free_point + Vector2(swipe_distance, 0))
	board._end_pointer(-1)
	assert(navigation_deltas == [3, -3], "Background drag must page the fretboard in both directions.")
	assert(board._is_marker_at(board.position_center_for(0, 5)))
	board.configure(model, 6, 24, true, [], Vector2i(3, 9))
	await process_frame
	assert(board.position_center_for(0, 3).x > board.position_center_for(0, 9).x)
	for fret in range(3, 10):
		assert(board.position_at(board.position_center_for(0, fret)).fret == fret)
	learning.tuning = PackedInt32Array([28, 33, 38, 43])
	board.configure(learning.positions(), 4, 24, false, [], Vector2i(0, 6))
	await process_frame
	assert(board.position_at(board.position_center_for(3, 6)).midi_note == 49)
	board.queue_free()
	await process_frame
	print("Fretboard view tests passed: visible ranges, crop geometry, exact MIDI hit tests, independent contacts, mirror, bass, playback and practice state.")
	quit()
