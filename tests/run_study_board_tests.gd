extends SceneTree

const Connection := preload("res://scripts/application/caged_connection.gd")
const Learning := preload("res://scripts/application/learning_model.gd")
const Board := preload("res://scripts/ui/fretboard_view.gd")

var inspected: Array[Dictionary] = []
var released: Array[int] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_caged_connections()
	await _test_board_long_press()
	print("Study board tests passed: CAGED neighbours in both directions and isolated long-press inspection.")
	quit()


func _test_caged_connections() -> void:
	for tonic in range(12):
		var model := Learning.new()
		model.tonic = tonic
		model.shape = "E"
		model.shape_fret_offset = 0
		var initial := model.caged_positions()
		assert(not initial.is_empty(), "tonic %d initial" % tonic)
		var upper := Connection.adjacent(model, 1)
		_assert_candidate(upper, 1, _mean_fret(initial))
		model.shape = str(upper.shape)
		model.shape_fret_offset = int(upper.offset)
		var lower := Connection.adjacent(model, -1)
		_assert_candidate(lower, -1, _mean_fret(model.caged_positions()))
		_assert_lower_boundary(model, tonic)

	var transposed := Learning.new()
	transposed.tonic = 9
	transposed.shape = "E"
	transposed.tuning = PackedInt32Array([38, 43, 48, 53, 57, 62])
	var transposed_upper := Connection.adjacent(transposed, 1)
	_assert_candidate(transposed_upper, 1, _mean_fret(transposed.caged_positions()))

	var drop_d := Learning.new()
	drop_d.tuning = PackedInt32Array([38, 45, 50, 55, 59, 64])
	assert(Connection.adjacent(drop_d, 1).is_empty())
	assert(Connection.adjacent(drop_d, -1).is_empty())


func _test_board_long_press() -> void:
	var board := Board.new()
	root.add_child(board)
	var model := Learning.new()
	board.size = Vector2(1000, 450)
	board.configure(model.positions(), 6, 24, false, [], Vector2i(3, 9))
	board.position_inspected.connect(func(position: Dictionary) -> void: inspected.append(position))
	board.position_released.connect(func(owner: int) -> void: released.append(owner))
	await process_frame

	board._press(10, board.position_center_for(0, 5))
	board._hold_started[10] = Time.get_ticks_msec() - 600
	board._process(0.0)
	assert(inspected.size() == 1)
	assert(inspected[0].midi_note == 45)
	assert(not board.active.has(10))
	assert(released == [10])

	board._press(11, board.position_center_for(0, 5))
	board._hold_started[11] = Time.get_ticks_msec() - 600
	board._move(11, board.position_center_for(0, 6))
	board._process(0.0)
	assert(inspected.size() == 1, "drag must cancel a hold")
	assert(board.active.has(11))
	board._release(11)

	board._press(12, board.position_center_for(0, 5))
	board._press(13, board.position_center_for(5, 5))
	board._hold_started[12] = Time.get_ticks_msec() - 600
	board._process(0.0)
	assert(inspected.size() == 2 and inspected[-1].midi_note == 45)
	assert(not board.active.has(12))
	assert(board.active.has(13), "inspection must not release another contact")
	board._release(13)
	board.queue_free()
	await process_frame


func _assert_candidate(candidate: Dictionary, direction: int, source_mean: float) -> void:
	assert(not candidate.is_empty())
	var positions: Array = candidate.positions
	assert(not positions.is_empty())
	var mean := _mean_fret(positions)
	assert(mean > source_mean if direction > 0 else mean < source_mean)
	for position: Dictionary in positions:
		assert(int(position.fret) >= 0 and int(position.fret) <= 24)
		assert(int(position.interval) in [0, 4, 7])
		assert(int(position.midi_note) == [40, 45, 50, 55, 59, 64][int(position.string_index)] + int(position.fret) or int(position.midi_note) == [38, 43, 48, 53, 57, 62][int(position.string_index)] + int(position.fret))


func _assert_lower_boundary(model: LearningModel, tonic: int) -> void:
	for step in range(20):
		var lower := Connection.adjacent(model, -1)
		if lower.is_empty():
			return
		model.shape = str(lower.shape)
		model.shape_fret_offset = int(lower.offset)
	assert(false, "tonic %d did not reach a lower CAGED boundary" % tonic)


func _mean_fret(positions: Array) -> float:
	var sum := 0.0
	for position: Dictionary in positions:
		sum += float(position.fret)
	return sum / positions.size()
