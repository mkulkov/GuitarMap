extends SceneTree

var _settings_path := "user://fret_formula_chord_playback_%d.json" % Time.get_ticks_usec()
var _stats_path := "user://fret_formula_chord_playback_stats_%d.json" % Time.get_ticks_usec()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var scene: Control = (load("res://scenes/app/main.tscn") as PackedScene).instantiate()
	scene.settings_store = SettingsStore.new(_settings_path)
	scene.practice_stats_store = PracticeStatsStore.new(_stats_path)
	root.add_child(scene)
	await process_frame
	scene._select_topic("chords")
	scene.settings.chord_id = "major"
	scene._refresh_learning_view()

	var voicing: Array[Dictionary] = scene._material_positions()
	assert(_contains_all_intervals(voicing, [0, 4, 7]))
	assert(_has_one_note_per_string(voicing))
	assert(voicing.size() == scene.learning.tuning.size())
	assert(_fretted_span(voicing) < 4)
	assert(ChordVoicing.is_fingerable(voicing))
	assert(scene.board.chord_voicing_keys.size() == voicing.size())
	scene._play_current_material()
	assert(scene.board.playback_keys.keys().all(func(key: Vector2i) -> bool:
		return voicing.any(func(position: Dictionary) -> bool:
			return key == Vector2i(int(position.string_index), int(position.fret))
		)
	))
	scene._stop_all_audio("chord_playback_test")
	scene.queue_free()
	await process_frame
	await create_timer(0.12).timeout
	for path in [_settings_path, _stats_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	await create_timer(0.12).timeout
	print("Chord playback integration tests passed: compact voicing drives both audio and highlight.")
	quit()


func _contains_all_intervals(voicing: Array[Dictionary], expected: Array) -> bool:
	var actual: Array = voicing.map(func(position: Dictionary) -> int: return int(position.interval))
	for interval in expected:
		if not actual.has(interval):
			return false
	return true


func _has_one_note_per_string(voicing: Array[Dictionary]) -> bool:
	var strings := {}
	for position: Dictionary in voicing:
		var string_index := int(position.string_index)
		if strings.has(string_index):
			return false
		strings[string_index] = true
	return true


func _fretted_span(voicing: Array[Dictionary]) -> int:
	var frets: Array[int] = []
	for position: Dictionary in voicing:
		if int(position.fret) > 0:
			frets.append(int(position.fret))
	if frets.is_empty():
		return 0
	frets.sort()
	return frets[-1] - frets[0]
