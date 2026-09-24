extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.gui_embed_subwindows = true
	root.size = Vector2i(1280, 900)
	var scene = load("res://scenes/app/main.tscn").instantiate()
	var path := "user://scale_menu_capture_%d.json" % Time.get_ticks_usec()
	scene.settings_store = SettingsStore.new(path)
	root.add_child(scene)
	scene._select_topic("scales")
	var menu: OptionButton = scene.scale_selector
	var ids: Array[String] = []
	var groups := 0
	for index in menu.item_count:
		if menu.is_item_separator(index):
			groups += 1
			continue
		var id := str(menu.get_item_metadata(index))
		assert(not ids.has(id))
		ids.append(id)
		scene._on_scale_selected(index)
		assert(scene.learning.scale_id == id)
	assert(ids.size() == 21 and groups == 9)
	assert(ids.slice(0, 6) == ["major", "natural_minor", "minor_pentatonic", "major_pentatonic", "minor_blues", "major_blues"])
	scene.settings.scale_id = "harmonic_minor"
	scene._refresh_learning_view()
	scene._populate_scale_selector()
	assert(menu.get_item_metadata(menu.selected) == "harmonic_minor")
	scene.study_tools.toggle()
	var comparison := scene.study_tools._content.get_node("ComparisonTarget") as OptionButton
	assert(comparison.item_count == menu.item_count)
	scene.study_tools.hide()
	for frame in 10: await process_frame
	menu.show_popup()
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/verification/scale_menu.png")
	menu.get_popup().hide()
	scene.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	DirAccess.remove_absolute(path)
	print("Grouped scale menu verified: 21 IDs, nine groups, selection, comparison.")
	quit()
