extends SceneTree

const PracticeSession := preload("res://scripts/application/practice_session.gd")
const PracticeStatsStore := preload("res://scripts/infrastructure/practice_stats_store.gd")

var stats_path := "user://fret_formula_practice_tests_%d.json" % Time.get_ticks_usec()


func _init() -> void:
	_test_seeded_midi_tasks_are_deterministic()
	_test_pitch_class_answers_and_session_metrics()
	_test_snapshots_are_owned()
	_test_stats_fallback_and_atomic_aggregation()
	_test_corrupt_stats_do_not_rewrite_on_load()
	_cleanup()
	print("Practice tests passed: seeded tasks, domain answers, immutable snapshots, and versioned aggregate storage.")
	quit()


func _positions() -> Array:
	return [
		{"string_index": 0, "fret": 0, "midi_note": 40},
		{"string_index": 0, "fret": 5, "midi_note": 45},
		{"string_index": 1, "fret": 0, "midi_note": 45},
		{"string_index": 1, "fret": 3, "midi_note": 48},
	]


func _test_seeded_midi_tasks_are_deterministic() -> void:
	var first := PracticeSession.new(_positions(), PracticeSession.TARGET_MIDI, 88)
	var second := PracticeSession.new(_positions(), PracticeSession.TARGET_MIDI, 88)
	for ignored in range(6):
		assert(first.next_task() == second.next_task())


func _test_pitch_class_answers_and_session_metrics() -> void:
	var session := PracticeSession.new(_positions(), PracticeSession.TARGET_PITCH_CLASS, 2)
	var task := session.next_task()
	assert(task.target_kind == PracticeSession.TARGET_PITCH_CLASS)
	assert(task.target_value >= 0 and task.target_value <= 11)
	var wrong := session.submit_answer(9, 9)
	assert(not wrong.correct)
	assert(wrong.snapshot.attempts == 1)
	assert(wrong.snapshot.streak == 0)
	var next := session.next_task()
	var answer := _answer_for_pitch_class(_positions(), int(next.target_value))
	var right := session.submit_answer(int(answer.string_index), int(answer.fret))
	assert(right.correct)
	assert(right.snapshot.attempts == 2)
	assert(right.snapshot.correct == 1)
	assert(right.snapshot.streak == 1)
	assert(right.snapshot.best_streak == 1)


func _test_snapshots_are_owned() -> void:
	var session := PracticeSession.new(_positions(), PracticeSession.TARGET_MIDI, 4)
	var task := session.next_task()
	task.target_value = -1
	assert(session.snapshot().active_task.target_value >= 0)
	var snapshot := session.snapshot()
	snapshot.active_task.clear()
	assert(session.has_active_task())


func _test_stats_fallback_and_atomic_aggregation() -> void:
	_remove(stats_path)
	var store := PracticeStatsStore.new(stats_path)
	assert(store.load_stats().used_fallback)
	var first := {"attempts": 3, "correct": 2, "best_streak": 2}
	var second := {"attempts": 4.0, "correct": 4.0, "best_streak": 4.0}
	assert(store.record_session(first).ok)
	assert(store.record_session(second).ok)
	var loaded := store.load_stats()
	assert(not loaded.used_fallback)
	assert(loaded.sessions == 2)
	assert(loaded.attempts == 7)
	assert(loaded.correct == 6)
	assert(loaded.best_streak == 4)
	assert(not store.record_session({"attempts": 1, "correct": 2, "best_streak": 1}).ok)


func _test_corrupt_stats_do_not_rewrite_on_load() -> void:
	_write_text(stats_path, "{ malformed")
	var loaded := PracticeStatsStore.new(stats_path).load_stats()
	assert(loaded.used_fallback)
	assert(_read_text(stats_path) == "{ malformed")


func _answer_for_pitch_class(positions: Array, target_pitch_class: int) -> Dictionary:
	for position: Dictionary in positions:
		if posmod(int(position.midi_note), 12) == target_pitch_class:
			return position
	assert(false, "Fixture needs an answer for its generated pitch class.")
	return {}


func _write_text(file_path: String, content: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(content)
	file.close()


func _read_text(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	assert(file != null)
	var content := file.get_as_text()
	file.close()
	return content


func _remove(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		assert(DirAccess.remove_absolute(file_path) == OK)


func _cleanup() -> void:
	_remove(stats_path)
	var directory := DirAccess.open("user://")
	if directory == null:
		return
	for file_name in directory.get_files():
		if file_name.begins_with(stats_path.get_file() + ".tmp-"):
			assert(directory.remove(file_name) == OK)
