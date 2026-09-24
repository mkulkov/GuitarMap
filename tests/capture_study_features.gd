extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280, 720)
	var scene = load("res://scenes/app/main.tscn").instantiate()
	var path := "user://study_capture_%d.json" % Time.get_ticks_usec()
	scene.settings_store = SettingsStore.new(path)
	root.add_child(scene)
	scene._select_topic("scales")
	scene.study_tools.toggle()
	scene.study_tools._comparison_target_id = "natural_minor"
	scene.study_tools._comparison_showing_target = true
	scene.study_tools._apply_comparison_display()
	await _capture("comparison")
	scene._select_topic("caged")
	scene.study_tools._show_tab("comparison")
	scene.study_tools._move_caged(CagedConnection.adjacent(scene.learning, 1))
	await create_timer(0.7).timeout
	await _capture("caged")
	scene._select_topic("chords")
	scene.study_tools._show_tab("lesson")
	scene.study_tools._start_lesson()
	scene.study_tools._change_lesson_step(1)
	await _capture("lesson")
	scene.study_tools.end_study()
	scene._select_topic("scales")
	scene.study_tools.show_playback()
	scene.study_tools._toggle_route()
	await _capture("route")
	scene.study_tools.inspect_note(scene.board.positions[5])
	await _capture("note")
	scene.study_tools.show_playback()
	await _capture("playback")
	root.size = Vector2i(640, 360)
	await _capture("compact")
	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	quit()


func _capture(label: String) -> void:
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://build/verification/study_%s.png" % label) == OK)
	print("Captured study_" + label)
