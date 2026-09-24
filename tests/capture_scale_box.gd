extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280, 720)
	var scene = load("res://scenes/app/main.tscn").instantiate()
	var path := "user://box_capture_%d.json" % Time.get_ticks_usec()
	scene.settings_store = SettingsStore.new(path)
	root.add_child(scene)
	scene.settings.scale_id = "minor_pentatonic"
	scene._select_topic("scales")
	scene._populate_scale_selector()
	assert(scene.box_positions.size() == 12)
	var trip: Array = scene._material_positions()
	assert(trip.size() == 23)
	assert(trip[11].string_index == 5 and trip[12].string_index == 5)
	assert(trip[0].fret == trip[-1].fret and trip[0].string_index == trip[-1].string_index)
	scene._play_current_material()
	assert(scene._playback_positions.size() == 23)
	scene._stop_all_audio("capture")
	await _capture("pentatonic_box1")
	scene._move_visible_range(3)
	assert(scene.box_anchor == 8)
	assert(scene.box_positions[0].interval != 0)
	assert(scene._material_positions().size() == 23)
	await _capture("pentatonic_box2")
	scene.settings.scale_id = "major"
	scene.box_anchor = -1
	scene._refresh_learning_view()
	scene._populate_scale_selector()
	scene._select_scale_view(1)
	assert(scene.box_positions.size() == 18)
	assert(scene._material_positions().size() == 35)
	await _capture("major_3nps")
	root.size = Vector2i(640, 360)
	await _capture("box_compact")
	scene.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	DirAccess.remove_absolute(path)
	print("Box integration verified: all strings, complete round trip, non-root endpoints, adjacent boxes and 3NPS.")
	quit()


func _capture(label: String) -> void:
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/verification/%s.png" % label)
