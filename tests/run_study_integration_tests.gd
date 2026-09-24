extends SceneTree

const CagedConnection := preload("res://scripts/application/caged_connection.gd")

var _settings_path := "user://fret_formula_study_integration_%d.json" % Time.get_ticks_usec()
var _stats_path := "user://fret_formula_study_integration_stats_%d.json" % Time.get_ticks_usec()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var scene = load("res://scenes/app/main.tscn").instantiate()
	scene.settings_store = SettingsStore.new(_settings_path)
	scene.practice_stats_store = PracticeStatsStore.new(_stats_path)
	root.add_child(scene)
	await process_frame
	assert(scene.is_node_ready())
	assert(scene.study_tools != null)

	await _test_panel_bounds(scene)
	await _test_scale_and_chord_comparison(scene)
	await _test_lesson_and_route(scene)
	await _test_note_inspection(scene)
	await _test_caged_transition(scene)
	_test_bass_string_drone(scene)
	await _test_playback_cancellation(scene)

	scene._stop_all_audio("study_integration_cleanup")
	scene.queue_free()
	await process_frame
	await create_timer(0.12).timeout
	for path in [_settings_path, _stats_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("Study integration tests passed: panel bounds, comparisons, lesson, route, inspection, CAGED transition and playback cancellation.")
	quit()


func _test_panel_bounds(scene: Control) -> void:
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = dimensions
		scene.study_tools.toggle()
		await process_frame
		assert(scene.study_tools.visible)
		assert(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(scene.study_tools.get_global_rect()))
		scene.study_tools.toggle()
		assert(not scene.study_tools.visible)


func _test_scale_and_chord_comparison(scene: Control) -> void:
	scene._select_topic("scales")
	scene.settings.scale_id = "major"
	scene._refresh_learning_view()
	scene.study_tools.toggle()
	scene.study_tools._show_tab("comparison")
	scene.study_tools._comparison_target_id = "natural_minor"
	scene.study_tools._comparison_showing_target = true
	scene.study_tools._apply_comparison_display()
	assert(str(scene.settings.scale_id) == "natural_minor")
	assert(not scene.board.comparison_roles.is_empty())
	assert(scene.board.comparison_roles.values().has("common"))
	assert(scene.board.comparison_roles.values().has("removed"))
	scene.study_tools._comparison_showing_target = false
	scene.study_tools._apply_comparison_display()
	assert(str(scene.settings.scale_id) == "major")

	scene._select_topic("chords")
	scene.settings.chord_id = "major"
	scene._refresh_learning_view()
	scene.study_tools._show_tab("comparison")
	scene.study_tools._comparison_target_id = "minor"
	scene.study_tools._comparison_showing_target = true
	scene.study_tools._apply_comparison_display()
	assert(str(scene.settings.chord_id) == "minor")
	assert(not scene.board.comparison_roles.is_empty())
	scene.study_tools.end_study()


func _test_lesson_and_route(scene: Control) -> void:
	scene._select_topic("chords")
	scene.settings.chord_id = "major"
	scene._refresh_learning_view()
	scene.study_tools._show_tab("lesson")
	scene.study_tools._start_lesson()
	assert(scene.study_tools.active_lesson)
	assert(scene.board.focus_intervals == [0])
	scene.study_tools._change_lesson_step(1)
	assert(scene.board.focus_intervals == [0, 4])
	assert(scene._material_positions().all(func(position: Dictionary): return int(position.interval) in [0, 4]))
	scene.study_tools.end_study()
	assert(scene.board.focus_intervals.is_empty())

	scene._select_topic("scales")
	scene._select_layer("scale")
	scene.study_tools.show_playback()
	scene.study_tools._toggle_route()
	var route: Array[Dictionary] = scene.study_tools.route_for_playback()
	assert(not route.is_empty())
	assert(scene.board.route_positions.size() == route.size())
	scene._play_current_material()
	var expected: Array[Dictionary] = route.duplicate(true)
	for index in range(route.size() - 2, -1, -1):
		expected.append(route[index])
	assert(scene._playback_positions.map(func(position: Dictionary): return int(position.midi_note)) == expected.map(func(position: Dictionary): return int(position.midi_note)))
	scene._stop_all_audio("route_asserted")
	scene.study_tools._toggle_route()


func _test_bass_string_drone(scene: Control) -> void:
	scene._on_tonic_selected(9) # A: fifth fret of the standard sixth string.
	assert(scene._drone_midi_for_tonic() == 45)
	scene.learning.tuning = PackedInt32Array([33, 38, 43, 48, 52, 57])
	scene.learning.tonic = 0
	scene.settings.tonic = 0 # C: third fret of the custom bass string.
	assert(scene._drone_midi_for_tonic() == 36)
	scene._apply_settings_to_models()
	scene._refresh_learning_view()


func _test_note_inspection(scene: Control) -> void:
	var position: Dictionary = scene._all_positions[0]
	scene.study_tools.inspect_note(position)
	assert(scene.study_tools.visible)
	var labels: Array[Node] = scene.study_tools._content.find_children("", "Label", true, false)
	assert(labels.any(func(label: Node): return not (label as Label).text.is_empty()))
	var all_notes := _button_containing(scene.study_tools._content, "Все такие")
	all_notes.pressed.emit()
	assert(scene.board.highlighted_pitch_class == int(position.pitch_class))
	scene.study_tools.inspect_note(position)
	var clear := _button_containing(scene.study_tools._content, "Очистить")
	clear.pressed.emit()
	assert(scene.board.highlighted_pitch_class == -1)


func _test_caged_transition(scene: Control) -> void:
	scene._select_topic("caged")
	var old_positions: Array[Dictionary] = scene.learning.caged_positions()
	var adjacent: Dictionary = CagedConnection.adjacent(scene.learning, 1)
	assert(not old_positions.is_empty() and not adjacent.is_empty())
	scene.study_tools._move_caged(adjacent)
	var next_positions: Array[Dictionary] = scene.learning.caged_positions()
	assert(scene.board.previous_shape.map(_position_key) == old_positions.map(_position_key))
	assert(not next_positions.is_empty())
	var common := old_positions.filter(func(old: Dictionary): return next_positions.any(func(next: Dictionary): return _position_key(old) == _position_key(next)))
	assert(not common.is_empty(), "Adjacent CAGED shapes must retain common fretboard positions.")


func _test_playback_cancellation(scene: Control) -> void:
	scene._select_topic("scales")
	scene._select_layer("scale")
	scene.study_tools.show_playback()
	var loop := scene.study_tools._content.get_node("LoopToggle") as CheckButton
	loop.button_pressed = true
	scene.study_tools._show_tab("note")
	scene.study_tools.show_playback()
	assert(scene.study_tools.playback_options().loop_enabled)
	scene._play_current_material()
	assert(scene.study_playback.is_active())
	scene._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(not scene.study_playback.is_active())

	scene._play_current_material()
	assert(scene.study_playback.is_active())
	scene._on_tempo_changed(120.0)
	assert(not scene.study_playback.is_active())

	scene._play_current_material()
	assert(scene.study_playback.is_active())
	scene._select_topic("arpeggios")
	assert(not scene.study_playback.is_active())
	scene.study_tools._reset_comparison()
	assert(scene.board.comparison_roles.is_empty())
	assert(not scene.study_tools.visible)


func _button_containing(parent: Node, text_value: String) -> Button:
	var buttons: Array[Node] = parent.find_children("", "Button", true, false)
	for button_node: Node in buttons:
		var candidate := button_node as Button
		if candidate.text.contains(text_value): return candidate
	assert(false, "Study control not found: %s" % text_value)
	return null


func _position_key(position: Dictionary) -> Vector2i:
	return Vector2i(int(position.string_index), int(position.fret))
