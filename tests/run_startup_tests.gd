extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var packed_scene := load("res://scenes/app/startup.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	root.size = Vector2i(1280, 720)
	for _frame in 4:
		await process_frame
	assert(scene.progress_bar != null)
	assert(scene.status_label.text == "Подготавливаем гриф…")
	assert(scene.brand_icon.texture != null)
	assert(scene.brand_icon.texture.resource_path == "res://assets/formula_fret_logo_compact.png")
	assert(scene.progress_bar.get_global_rect().size.x >= 400.0)
	var project_config := FileAccess.get_file_as_string("res://project.godot")
	assert(project_config.contains('config/name="FretFormula"'))
	assert(project_config.contains('config/icon="res://assets/app_icon.png"'))
	assert(project_config.contains("boot_splash/bg_color=Color(0.0156863, 0.0705882, 0.109804, 1)"))
	assert(project_config.contains('boot_splash/image="res://assets/boot_splash_icon.png"'))
	var export_config := FileAccess.get_file_as_string("res://export_presets.cfg")
	assert(export_config.contains('"[splash]android:windowSplashScreenBackground": "#04121C"'))
	assert(export_config.contains('package/unique_name="ru.mkulkov.fretformula"'))
	assert(export_config.contains('package/name="Формула грифа"'))
	for shell_path in ["res://web/yandex_shell.html", "res://web/vk_shell.html"]:
		var shell := FileAccess.get_file_as_string(shell_path)
		assert(shell.contains("<title>Формула грифа</title>"))
		assert(shell.contains("window.FretFormulaPlatform"))
	var prepared_scene := ResourceLoader.load_threaded_get("res://scenes/app/main.tscn") as PackedScene
	assert(prepared_scene != null)
	scene.queue_free()
	await process_frame
	print("Startup tests passed: branded loading screen initializes with progress and a readable landscape layout.")
	quit()
