extends SceneTree

const OUTPUT_DIR := "res://.godot/verification"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var state_path := "%s/monetization_capture_state.json" % OUTPUT_DIR
	if FileAccess.file_exists(state_path):
		DirAccess.remove_absolute(state_path)
	var scene = load("res://scenes/app/main.tscn").instantiate()
	scene.settings_store = SettingsStore.new("%s/monetization_capture_settings.json" % OUTPUT_DIR)
	scene.monetization_state_path = state_path
	root.add_child(scene)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(root.size)
	await _settle()
	scene._toggle_about()
	await _settle()
	assert(root.get_texture().get_image().save_png("%s/monetization_about_1280x720.png" % OUTPUT_DIR) == OK)
	scene._toggle_about()
	scene._show_donation_prompt()
	await _settle()
	assert(root.get_texture().get_image().save_png("%s/monetization_prompt_1280x720.png" % OUTPUT_DIR) == OK)
	root.size = Vector2i(640, 360)
	DisplayServer.window_set_size(root.size)
	await _settle()
	assert(root.get_texture().get_image().save_png("%s/monetization_prompt_640x360.png" % OUTPUT_DIR) == OK)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(root.size)
	await _settle()
	scene._purchase_donation(0)
	await _settle()
	assert(scene.supporter_heart.visible and not scene.donation_prompt_panel.visible)
	scene._toggle_about()
	await _settle()
	assert(scene.about_donation_buttons.size() == 3)
	for button in scene.about_donation_buttons:
		assert(button.visible)
	scene._toggle_about()
	assert(root.get_texture().get_image().save_png("%s/monetization_supported_1280x720.png" % OUTPUT_DIR) == OK)
	root.size = Vector2i(640, 360)
	DisplayServer.window_set_size(root.size)
	await _settle()
	assert(scene.brand_icon.visible and scene.supporter_heart.visible)
	assert(root.get_texture().get_image().save_png("%s/monetization_supported_640x360.png" % OUTPUT_DIR) == OK)
	scene.queue_free()
	await process_frame
	for path in [state_path, "%s/monetization_capture_settings.json" % OUTPUT_DIR]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	quit()


func _settle() -> void:
	for _frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
