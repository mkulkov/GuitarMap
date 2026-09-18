extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var scene = load("res://scenes/app/main.tscn").instantiate()
	var path := "user://theory_sheet_test_%d.json" % Time.get_ticks_usec()
	scene.settings_store = SettingsStore.new(path)
	root.add_child(scene)
	scene.settings.scale_id = "harmonic_minor"
	scene._select_layer("scale")
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = dimensions
		for frame in 5: await process_frame
		for topic in ["scales", "chords", "arpeggios", "caged"]:
			scene._select_topic(topic)
			scene.theory_compact_button.pressed.emit()
			for frame in 5: await process_frame
			assert(scene.theory_sheet.visible)
			assert(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(scene.theory_sheet.get_global_rect()))
			assert(not scene.theory_sheet_title.text.is_empty())
			assert(not scene.theory_sheet_body.text.is_empty())
			assert(scene.theory_sheet.get_global_rect().encloses(scene.theory_sheet_title.get_global_rect()))
			assert(scene.theory_sheet.get_global_rect().intersects(scene.theory_sheet_body.get_global_rect()))
			if OS.get_cmdline_user_args().has("--capture") and topic == "caged":
				await RenderingServer.frame_post_draw
				assert(root.get_texture().get_image().save_png("res://build/verification/theory_sheet_%dx%d.png" % [dimensions.x, dimensions.y]) == OK)
			scene._toggle_theory_sheet()
			assert(not scene.theory_sheet.visible)
	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	print("Theory sheet tests passed: four topics, visible text, bounded modal, compact layouts and close/reopen.")
	quit()
