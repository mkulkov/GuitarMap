extends SceneTree

const OUTPUT_DIR := "res://.godot/verification"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var scene = load("res://scenes/app/main.tscn").instantiate()
	var settings_path := "user://fret_formula_visual_%d.json" % Time.get_ticks_usec()
	scene.settings_store = SettingsStore.new(settings_path)
	root.add_child(scene)
	for dimensions in [Vector2i(1672, 941), Vector2i(1280, 720), Vector2i(960, 540), Vector2i(640, 360), Vector2i(720, 1280), Vector2i(2400, 1080)]:
		root.size = dimensions
		DisplayServer.window_set_size(dimensions)
		await _settle()
		var output := "%s/learning_%dx%d.png" % [OUTPUT_DIR, dimensions.x, dimensions.y]
		assert(root.get_texture().get_image().save_png(output) == OK)
		print(output)
	scene.settings_button.pressed.emit()
	await _settle()
	assert(root.get_texture().get_image().save_png("%s/learning_settings.png" % OUTPUT_DIR) == OK)
	scene._toggle_settings()
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(root.size)
	for topic in ["scales", "chords", "arpeggios"]:
		scene._select_topic(topic)
		await _settle()
		assert(root.get_texture().get_image().save_png("%s/learning_%s.png" % [OUTPUT_DIR, topic]) == OK)
	scene._on_language_selected(1)
	scene._toggle_practice()
	await _settle()
	assert(root.get_texture().get_image().save_png("%s/learning_practice_en.png" % OUTPUT_DIR) == OK)
	scene._stop_practice()
	await _settle()
	assert(root.get_texture().get_image().save_png("%s/learning_after_practice_1280x720.png" % OUTPUT_DIR) == OK)
	root.size = Vector2i(640, 360)
	DisplayServer.window_set_size(root.size)
	scene._toggle_settings()
	await _settle()
	assert(root.get_texture().get_image().save_png("%s/learning_settings_compact.png" % OUTPUT_DIR) == OK)
	scene.queue_free()
	await process_frame
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_path)
	quit()


func _settle() -> void:
	for _frame in 10:
		await process_frame
	await RenderingServer.frame_post_draw
