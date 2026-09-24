extends Control

const AppTheme = preload("res://scripts/ui/app_theme.gd")
const MAIN_SCENE := "res://scenes/app/main.tscn"
const MINIMUM_DISPLAY_SECONDS := 0.7
const PUBLIC_APP_NAME := "Формула грифа"

var _elapsed := 0.0
var _request_started := false
var _transitioning := false
var progress_bar: ProgressBar
var status_label: Label
var brand_icon: TextureRect


func _ready() -> void:
	DisplayServer.window_set_title(PUBLIC_APP_NAME)
	theme = AppTheme.create()
	_build_ui()
	ResourceLoader.load_threaded_request(MAIN_SCENE, "PackedScene")
	_request_started = true


func _process(delta: float) -> void:
	_elapsed += delta
	if not _request_started or _transitioning:
		return
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(MAIN_SCENE, progress)
	var fraction := float(progress[0]) if not progress.is_empty() else 0.0
	progress_bar.value = clampf(fraction * 100.0, 4.0, 100.0)
	if status == ResourceLoader.THREAD_LOAD_LOADED and _elapsed >= MINIMUM_DISPLAY_SECONDS:
		_open_workspace()
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		status_label.text = "Не удалось подготовить рабочее пространство"
		progress_bar.value = 0.0


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("04121c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var layout := CenterContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layout)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(420, 0)
	column.add_theme_constant_override("separation", 14)
	layout.add_child(column)

	brand_icon = TextureRect.new()
	brand_icon.texture = load("res://assets/formula_fret_logo_compact.png")
	brand_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand_icon.custom_minimum_size = Vector2(400, 96)
	brand_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(brand_icon)
	var subtitle := Label.new()
	subtitle.text = "Интерактивный гриф · теория и практика"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("9bb8cf"))
	column.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	column.add_child(spacer)
	progress_bar = ProgressBar.new()
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(420, 12)
	progress_bar.value = 4.0
	progress_bar.add_theme_stylebox_override("background", _bar_style(Color("0a2332"), Color("214052"), 6))
	progress_bar.add_theme_stylebox_override("fill", _bar_style(Color("22d8f2"), Color("22d8f2"), 6))
	column.add_child(progress_bar)
	status_label = Label.new()
	status_label.text = "Подготавливаем гриф…"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color("8faac0"))
	column.add_child(status_label)


func _bar_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style


func _open_workspace() -> void:
	_transitioning = true
	progress_bar.value = 100.0
	status_label.text = "Готово"
	var scene := ResourceLoader.load_threaded_get(MAIN_SCENE) as PackedScene
	if scene != null:
		get_tree().change_scene_to_packed(scene)
