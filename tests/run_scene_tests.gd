extends SceneTree

var settings_path := "res://.godot/verification/fret_formula_scene_test_%d.json" % Time.get_ticks_usec()
var stats_path := "res://.godot/verification/fret_formula_scene_stats_test_%d.json" % Time.get_ticks_usec()
var monetization_path := "res://.godot/verification/fret_formula_scene_monetization_test_%d.json" % Time.get_ticks_usec()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/verification")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var scene = load("res://scenes/app/main.tscn").instantiate()
	scene.settings_store = SettingsStore.new(settings_path)
	scene.practice_stats_store = PracticeStatsStore.new(stats_path)
	scene.monetization_state_path = monetization_path
	root.add_child(scene)
	var dimensions_to_check := [Vector2i(640, 360), Vector2i(720, 1280), Vector2i(1035, 381), Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(1672, 941), Vector2i(2400, 1080)]
	if OS.get_cmdline_user_args().has("--functional-only"):
		dimensions_to_check = [Vector2i(1672, 941)]
	for dimensions in dimensions_to_check:
		root.size = dimensions
		for _frame in 5: await process_frame
		assert(scene.board.get_global_rect().end.x <= dimensions.x + 1, "Board width overflows %s: %s" % [dimensions, scene.board.get_global_rect()])
		assert(scene.board.get_global_rect().end.y <= dimensions.y + 1, "Board height overflows %s: %s" % [dimensions, scene.board.get_global_rect()])
		assert(scene.tonic_selector.get_global_rect().position.x >= 0)
		assert(scene.settings_button.get_global_rect().end.x <= dimensions.x + 1)
		assert(scene.about_button.get_global_rect().end.x <= dimensions.x + 1)
		var icon_only: bool = dimensions.x < 800 or dimensions.y < 470
		assert(scene.brand_icon.visible == icon_only)
		assert(scene.brand_logo.visible != icon_only)
		assert(scene.brand_box.get_global_rect().end.x <= dimensions.x + 1)
		assert(scene.brand_icon.texture.resource_path == "res://assets/formula_fret_icon.png")
		assert(scene.brand_logo.texture.resource_path == "res://assets/formula_fret_logo_compact.png")
		assert(scene.brand_box.get_global_rect().position.x <= scene.board.get_global_rect().position.x, "Logo must start at the string-label edge.")
		assert(scene.about_button.get_index() == scene.settings_button.get_index() + 1)
		assert(scene.practice_button.get_global_rect().end.y <= dimensions.y + 1, "Practice overflows %s: %s" % [dimensions, scene.practice_button.get_global_rect()])
		assert(scene.lower_row.get_global_rect().end.y <= dimensions.y + 1)
		assert(scene.topic_buttons.size() == 4 and scene.shape_buttons.size() == 5)
		var shape_host: Control = scene.compact_shape_host if icon_only else scene.theory_column
		assert(scene.shape_row.get_parent() == shape_host)
		assert(scene.box_selector.get_parent() == scene.tabs_row)
		assert(scene.title_label.get_parent() == scene.theory_column)
		assert(scene.title_label.get_index() == scene.theory_title.get_index() + 1)
		assert(scene.title_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and not scene.title_label.clip_text)
		for string_index in 6:
			for fret in range(scene.board.visible_range.x, scene.board.visible_range.y + 1):
				var position: Dictionary = scene.board.position_at(scene.board.position_center_for(string_index, fret))
				assert(position.string_index == string_index and position.fret == fret)
	assert(scene.learning.tonic == 9 and scene.learning.scale_id == "major")
	assert(scene.learning.topic == "caged" and scene.learning.shape == "E")
	assert(scene.board.visible_range == Vector2i(3, 9))
	assert(not scene.box_selector.visible)
	for shape in ["C", "A", "G", "E", "D"]:
		scene.shape_buttons[shape].pressed.emit()
		assert(scene.learning.shape == shape)
		assert(not scene.learning.caged_positions().is_empty())
	scene.shape_buttons.E.pressed.emit()
	for topic in ["scales", "chords", "arpeggios", "caged"]:
		scene.topic_buttons[topic].pressed.emit()
		assert(scene.learning.topic == topic)
	scene._select_topic("scales")
	assert(scene.box_selector.visible and scene.box_selector.get_parent() == scene.theory_column and not scene.theory_subtitle.visible and not scene.shape_row.visible and not scene.compact_shape_host.visible)
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
	root.size = Vector2i(1024, 600)
	for _frame in 5: await process_frame
	var stable_header_rect: Rect2 = scene.header.get_global_rect()
	var stable_tabs_rect: Rect2 = scene.tabs.get_global_rect()
	for topic in ["scales", "chords", "arpeggios", "caged"]:
		scene._select_topic(topic)
		for _frame in 3: await process_frame
		assert(scene.header.get_global_rect().is_equal_approx(stable_header_rect), "Header changes when selecting %s: %s != %s" % [topic, scene.header.get_global_rect(), stable_header_rect])
		assert(scene.tabs.get_global_rect().is_equal_approx(stable_tabs_rect), "Tab panel changes when selecting %s: %s != %s" % [topic, scene.tabs.get_global_rect(), stable_tabs_rect])
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
	scene._toggle_about()
	assert(scene.about_panel.visible and scene.about_scrim.visible)
	assert(scene.about_donation_buttons.size() == 3)
	assert(scene.about_donation_heading.text == "Buy the developer a coffee")
	assert(scene.about_donation_buttons[0].text.contains("99"))
	assert(scene.about_donation_buttons[1].text.contains("199"))
	assert(scene.about_donation_buttons[2].text.contains("499"))
	assert(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(scene.about_panel.get_global_rect()))
	scene._toggle_about()
	scene._show_donation_prompt()
	assert(scene.donation_prompt_panel.visible and scene.donation_prompt_title.text.contains("Формула грифа"))
	assert(scene.donation_prompt_body.text.contains("without subscriptions, ads, or locked features"))
	assert(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(scene.donation_prompt_panel.get_global_rect()))
	assert(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(scene.donation_prompt_title.get_global_rect()))
	assert(scene.donation_prompt_buttons.size() == 3)
	assert(scene.donation_prompt_donation_heading.text == "Buy the developer a coffee")
	assert(is_equal_approx(scene.donation_prompt_buttons[0].get_global_rect().position.y, scene.donation_prompt_buttons[1].get_global_rect().position.y))
	assert(is_equal_approx(scene.donation_prompt_buttons[1].get_global_rect().position.y, scene.donation_prompt_buttons[2].get_global_rect().position.y))
	scene._purchase_donation(0)
	for _frame in 4:
		await process_frame
	assert(scene.supporter_heart.visible)
	assert(not scene.donation_prompt_panel.visible)
	root.size = Vector2i(640, 360)
	for _frame in 5: await process_frame
	assert(scene.brand_icon.visible and not scene.brand_logo.visible)
	assert(scene.supporter_heart.visible)
	assert(scene.brand_box.get_global_rect().end.x <= 641)
	root.size = Vector2i(1280, 720)
	for _frame in 5: await process_frame
	scene._toggle_about()
	assert(scene.about_panel.visible and scene.about_donation_buttons.all(func(button: Button): return button.visible))
	scene._toggle_about()
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
	assert(not scene.mini_row.visible, "Compact practice exit must not leave an empty mini-neck row.")
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
	for path in [settings_path, stats_path, monetization_path]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("Scene tests passed: portrait/landscape layouts, responsive branding, learning topics/forms/layers, playback, independent touch voices, language, settings, practice and custom tuning.")
	quit()
