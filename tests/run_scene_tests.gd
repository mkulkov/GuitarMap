extends SceneTree

var settings_path := "user://guitarmap_scene_test_%d.json" % Time.get_ticks_usec()
var stats_path := "user://guitarmap_scene_stats_test_%d.json" % Time.get_ticks_usec()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var scene = load("res://scenes/app/main.tscn").instantiate()
	scene.settings_store = SettingsStore.new(settings_path)
	scene.practice_stats_store = PracticeStatsStore.new(stats_path)
	root.add_child(scene)
	var dimensions_to_check := [Vector2i(640, 360), Vector2i(1035, 381), Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(1672, 941), Vector2i(2400, 1080)]
	if OS.get_cmdline_user_args().has("--functional-only"):
		dimensions_to_check = [Vector2i(1672, 941)]
	for dimensions in dimensions_to_check:
		root.size = dimensions
		for _frame in 5: await process_frame
		assert(scene.board.get_global_rect().end.x <= dimensions.x + 1, "Board width overflows %s: %s" % [dimensions, scene.board.get_global_rect()])
		assert(scene.board.get_global_rect().end.y <= dimensions.y + 1, "Board height overflows %s: %s" % [dimensions, scene.board.get_global_rect()])
		assert(scene.tonic_selector.get_global_rect().position.x >= 0)
		assert(scene.settings_button.get_global_rect().end.x <= dimensions.x + 1)
		assert(scene.practice_button.get_global_rect().end.y <= dimensions.y + 1, "Practice overflows %s: %s" % [dimensions, scene.practice_button.get_global_rect()])
		assert(scene.lower_row.get_global_rect().end.y <= dimensions.y + 1)
		assert(scene.topic_buttons.size() == 4 and scene.shape_buttons.size() == 5)
		for string_index in 6:
			for fret in range(scene.board.visible_range.x, scene.board.visible_range.y + 1):
				var position: Dictionary = scene.board.position_at(scene.board.position_center_for(string_index, fret))
				assert(position.string_index == string_index and position.fret == fret)
	assert(scene.learning.tonic == 9 and scene.learning.scale_id == "major")
	assert(scene.learning.topic == "caged" and scene.learning.shape == "E")
	assert(scene.board.visible_range == Vector2i(3, 9))
	for shape in ["C", "A", "G", "E", "D"]:
		scene.shape_buttons[shape].pressed.emit()
		assert(scene.learning.shape == shape)
		assert(not scene.learning.caged_positions().is_empty())
	scene.shape_buttons.E.pressed.emit()
	for topic in ["scales", "chords", "arpeggios", "caged"]:
		scene.topic_buttons[topic].pressed.emit()
		assert(scene.learning.topic == topic)
	scene._select_topic("chords")
	assert(scene.chord_selector.item_count == 9)
	for chord_index in 9:
		scene._on_chord_selected(chord_index)
		var chord: Variant = scene.learning.chord_records()[chord_index]
		assert(scene.learning.chord_id == chord.id)
		assert(scene._material_positions().all(func(p: Dictionary): return chord.intervals.has(p.interval)))
	scene._on_chord_selected(0)
	scene._select_topic("caged")
	scene._select_layer("roots")
	var root_sequence: Array = scene._material_positions()
	assert(not root_sequence.is_empty())
	assert(root_sequence.all(func(p: Dictionary): return p.is_root))
	scene._select_layer("scale")
	var scale_sequence: Array = scene._material_positions()
	assert(scale_sequence.any(func(p: Dictionary): return not p.in_chord))
	scene._select_layer("chord")
	var held_handles: Array[int] = []
	for owner_id in 6:
		scene.board._press(owner_id, scene.board.position_center_for(owner_id, 5))
		held_handles.append(scene.touch_coordinator.contact(owner_id).voice_handle)
	assert(scene.touch_coordinator.active_contact_count() == 6)
	assert(scene.audio_engine.get_active_voice_count() == 6)
	scene.board._release(1)
	assert(scene.touch_coordinator.active_contact_count() == 5)
	assert(scene.audio_engine.voice_snapshot(held_handles[2]).owner_id == 2)
	scene._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(scene.audio_engine.get_active_voice_count() == 0)
	assert(scene.board.active.is_empty())
	scene._play_current_material()
	assert(scene.sequence_player.is_playing())
	assert(scene.board.playback_keys.size() >= 3)
	scene._stop_all_audio("test")
	assert(not scene.sequence_player.is_playing() and scene.board.playback_keys.is_empty())
	scene._on_guitar_selected(1)
	assert(scene.audio_engine.get_timbre() == GuitarTimbre.ELECTRIC)
	scene._on_language_selected(1)
	assert(scene.learning.language == "en")
	assert(scene.topic_buttons.scales.text == "Scales & modes")
	root.size = Vector2i(1280, 720)
	for topic in ["scales", "chords", "arpeggios", "caged"]:
		scene._select_topic(topic)
		for _frame in 5: await process_frame
		assert(scene.theory_panel.get_global_rect().end.x <= 1281, "English theory card overflows for " + topic)
	scene._select_topic("scales")
	for scale_index in scene.scale_selector.item_count:
		scene._on_scale_selected(scale_index)
		for _frame in 3: await process_frame
		assert(scene.theory_panel.get_global_rect().end.x <= 1281, "Scale card overflows")
	assert(scene.theory_compact_button.text == "Theory")
	scene._select_topic("caged")
	scene._on_mirror_toggled(true)
	assert(scene.board.mirrored)
	scene._toggle_settings()
	assert(scene.settings_panel.visible)
	await process_frame
	assert(scene.settings_panel.size.x > 200 and scene.settings_panel.size.y > 200)
	assert(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(scene.settings_panel.get_global_rect()))
	scene._on_fret_count_selected(24)
	assert(scene.learning.fret_count == 36)
	scene._on_fret_count_selected(12)
	scene._on_spelling_selected(1)
	assert(scene.learning.spelling == "flat")
	scene._on_tempo_changed(120.0)
	assert(is_equal_approx(scene.seconds_per_beat(), 0.5))
	assert(is_equal_approx(scene.playback_timing().step_seconds, 0.5))
	scene._on_spelling_selected(0)
	scene._toggle_settings()
	assert(not scene.settings_panel.visible)
	scene._toggle_practice()
	assert(scene.practice_session.has_active_task() and scene.board.practice_hidden)
	var target: int = scene.practice_session.snapshot().active_task.target_value
	var answer: Dictionary = scene.board.positions.filter(func(p: Dictionary): return p.pitch_class == target and p.fret >= scene.board.visible_range.x and p.fret <= scene.board.visible_range.y)[0]
	scene._on_position_pressed(77, answer)
	assert(scene.practice_session.snapshot().correct == 1)
	scene._stop_practice()
	# Let the cancelled feedback timer finish and verify it cannot restart practice.
	await create_timer(0.75).timeout
	assert(not scene.board.practice_hidden)
	assert(scene.practice_session == null)
	assert(scene.practice_stats_store.load_stats().correct == 1)
	scene._on_tonic_selected(0)
	assert(scene.learning.tonic == 0)
	assert(scene.audio_engine.get_active_voice_count() == 0)
	scene.custom_tuning_edit.text = "28,33,38,43"
	scene._apply_custom_tuning()
	assert(scene.board.string_count == 4)
	assert(not scene.learning.explanation().compatible)
	assert(not scene.learning.explanation().message.is_empty())
	scene.custom_tuning_edit.text = "not a tuning"
	scene._apply_custom_tuning()
	assert(scene.board.string_count == 4)
	var saved: Dictionary = scene.settings_store.load_settings()
	assert(saved.language == "en" and saved.guitar_type == "electric")
	assert(saved.tuning_id == "custom" and saved.custom_tuning == [28, 33, 38, 43])
	scene._stop_all_audio("test_complete")
	scene.queue_free()
	await process_frame
	# The audio mixer releases its stopped WAV playback on its next mixing block.
	await create_timer(0.12).timeout
	for path in [settings_path, stats_path]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("Scene tests passed: landscape layouts, learning topics/forms/layers, playback, independent touch voices, language, settings, practice and custom tuning.")
	quit()
