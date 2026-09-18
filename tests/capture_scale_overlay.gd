extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var scene = load("res://scenes/app/main.tscn").instantiate()
	var path := "user://overlay_capture_%d.json" % Time.get_ticks_usec()
	scene.settings_store = SettingsStore.new(path)
	root.add_child(scene)
	scene.settings.scale_id = "harmonic_minor"
	for index in scene.explorer.scales.size():
		if scene.explorer.scales[index].id == "harmonic_minor": scene.scale_selector.select(index)
	scene._select_shape("C")
	scene._select_layer("scale")
	for dimensions in [Vector2i(1672, 900), Vector2i(1280, 720)]:
		root.size = dimensions
		DisplayServer.window_set_size(dimensions)
		for frame in 10: await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://build/verification/caged_scale_%dx%d.png" % [dimensions.x, dimensions.y]) == OK)
	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	quit()
