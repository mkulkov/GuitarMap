extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = load("res://scenes/app/main.tscn").instantiate()
	var path := "user://overlay_test_%d.json" % Time.get_ticks_usec()
	scene.settings_store = SettingsStore.new(path)
	root.add_child(scene)
	scene.settings.scale_id = "harmonic_minor"
	scene._select_shape("C")
	scene._select_layer("scale")
	assert(scene.theory_overlay_hint.visible)
	assert(scene.theory_overlay_hint.text.contains("C♯"))
	var outside: Array = scene.board.positions.filter(func(p: Dictionary): return p.in_shape and not p.in_scale)
	assert(not outside.is_empty())
	assert(outside.all(func(p: Dictionary): return p.pitch_class == 1))
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for dimensions in [Vector2i(1672, 900), Vector2i(1280, 720)]:
		root.size = dimensions
		for frame in 5: await process_frame
		assert(scene.practice_button.get_global_rect().end.y <= dimensions.y + 1)
		assert(scene.theory_overlay_hint.is_visible_in_tree())
	for topic in ["caged", "scales"]:
		scene._select_topic(topic)
		scene._select_layer("scale")
		var sequence: Array = scene._material_positions()
		assert(sequence.size() == 15)
		assert(sequence[0].is_root and sequence[7].is_root and sequence[-1].is_root)
		assert(sequence[7].midi_note == sequence[0].midi_note + 12)
		for index in 7:
			assert(sequence[index].midi_note < sequence[index + 1].midi_note)
			assert(sequence[index].midi_note == sequence[14 - index].midi_note)
		assert(sequence.all(func(p: Dictionary): return p.in_scale))
	scene._select_topic("arpeggios")
	var arpeggio: Array = scene._material_positions()
	for index in range(1, arpeggio.size()):
		assert(arpeggio[index].midi_note > arpeggio[index - 1].midi_note)
	scene._select_topic("caged")
	scene._select_layer("chord")
	assert(not scene.theory_overlay_hint.visible)
	assert(scene._material_positions().any(func(p: Dictionary): return p.pitch_class == 1))
	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	print("Scale overlay tests passed: explicit outside-scale CAGED tones, ascending/descending scale, unchanged arpeggio and chord.")
	quit()
