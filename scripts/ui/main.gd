extends Control

const AppTheme = preload("res://scripts/ui/app_theme.gd")
const BoardView = preload("res://scripts/ui/fretboard_view.gd")
const MiniView = preload("res://scripts/ui/mini_neck_view.gd")
const NoteNames = preload("res://scripts/domain/note_spelling.gd")

const TOPICS := ["scales", "chords", "arpeggios", "caged"]
const SHAPES := ["C", "A", "G", "E", "D"]
const LAYERS := ["roots", "chord", "scale"]
const NOTE_NAMES_SHARP := ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
const NOTE_NAMES_FLAT := ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

var settings_store := SettingsStore.new()
var practice_stats_store := PracticeStatsStore.new()
var settings: Dictionary
var language := "ru"
var explorer := ScaleExplorer.new()
var learning: LearningModel
var audio_engine: GuitarAudioEngine
var touch_coordinator: TouchVoiceCoordinator
var sequence_player: NoteSequencePlayer
var practice_session: PracticeSession

var board: LearningFretboardView
var mini_neck: MiniNeckView
var tonic_selector: OptionButton
var scale_selector: OptionButton
var chord_selector: OptionButton
var settings_button: Button
var scale_play_button: Button
var topic_buttons: Dictionary = {}
var shape_buttons: Dictionary = {}
var layer_buttons: Dictionary = {}
var title_label: Label
var theory_panel: PanelContainer
var theory_title: Label
var theory_subtitle: Label
var theory_formula: Label
var theory_notes: Label
var theory_chips: HFlowContainer
var theory_body: Label
var theory_overlay_hint: Label
var theory_compact_button: Button
var theory_sheet: PanelContainer
var theory_sheet_title: Label
var theory_sheet_formula: Label
var theory_sheet_notes: Label
var theory_sheet_body: Label
var shape_row: HBoxContainer
var fret_back_button: Button
var fret_forward_button: Button
var legend_row: HBoxContainer
var lower_row: HBoxContainer
var mini_row: HBoxContainer
var practice_button: Button
var practice_bar: PanelContainer
var practice_label: Label
var settings_panel: PanelContainer
var settings_scrim: ColorRect
var tuning_selector: OptionButton
var guitar_selector: OptionButton
var volume_slider: HSlider
var language_selector: OptionButton
var mirror_toggle: CheckButton
var custom_tuning_edit: LineEdit
var custom_apply_button: Button
var fret_count_selector: OptionButton
var spelling_selector: OptionButton
var tempo_slider: HSlider
var tempo_value_label: Label
var settings_status_label: Label
var settings_title: Label
var tuning_label: Label
var guitar_label: Label
var volume_label: Label
var fret_count_label: Label
var spelling_label: Label
var tempo_label: Label
var language_label: Label
var close_settings_button: Button
var app_title: Label
var brand_box: HBoxContainer
var brand_icon: TextureRect
var header_row: HBoxContainer
var header_margin: MarginContainer
var header: PanelContainer
var tabs: PanelContainer
var content_margin: MarginContainer
var main_row: HBoxContainer
var _visible_range := Vector2i(3, 9)
var _all_positions: Array[Dictionary] = []
var _playback_positions: Array[Dictionary] = []
var _tuning_records: Array = []
var _practice_generation := 0


func _ready() -> void:
	theme = AppTheme.create()
	settings = settings_store.load_settings()
	language = str(settings.language)
	learning = LearningModel.new()
	_apply_settings_to_models()
	_build_ui()
	_create_audio()
	resized.connect(_apply_responsive_layout)
	_refresh_learning_view()
	_apply_responsive_layout()


func _apply_settings_to_models() -> void:
	learning.tonic = int(settings.tonic)
	learning.scale_id = str(settings.scale_id)
	learning.topic = str(settings.study_topic)
	learning.shape = str(settings.caged_shape)
	learning.layer = str(settings.study_layer)
	learning.chord_id = str(settings.chord_id)
	learning.spelling = str(settings.spelling)
	learning.language = language
	learning.fret_count = int(settings.fret_count)
	if not explorer.select_tuning(str(settings.tuning_id)):
		explorer.select_tuning("standard")
	if str(settings.tuning_id) == "custom" and not settings.custom_tuning.is_empty():
		learning.tuning = settings.custom_tuning.duplicate()
	elif explorer.tuning != null:
		learning.tuning = explorer.tuning.open_string_midi.duplicate()
	_visible_range = learning.recommended_range()


func _create_audio() -> void:
	audio_engine = GuitarAudioEngine.new()
	audio_engine.name = "AudioEngine"
	add_child(audio_engine)
	audio_engine.set_master_volume(float(settings.master_volume))
	audio_engine.set_timbre(StringName(str(settings.guitar_type)))
	touch_coordinator = TouchVoiceCoordinator.new(audio_engine)
	sequence_player = NoteSequencePlayer.new()
	sequence_player.name = "SequencePlayer"
	add_child(sequence_player)
	sequence_player.configure(audio_engine)
	sequence_player.note_started.connect(_on_sequence_note)
	sequence_player.note_released.connect(func(_index: int, _midi: int): board.clear_playback_highlight())
	sequence_player.playback_finished.connect(_on_playback_finished)
	board.position_pressed.connect(_on_position_pressed)
	board.position_moved.connect(_on_position_moved)
	board.position_released.connect(func(owner_id: int): touch_coordinator.release(owner_id))


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("03111b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var root_column := VBoxContainer.new()
	root_column.name = "LearningWorkspace"
	root_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_column.add_theme_constant_override("separation", 0)
	add_child(root_column)

	header = _panel("HeaderPanel")
	header.custom_minimum_size.y = 86
	root_column.add_child(header)
	_build_header(header)

	tabs = _panel("TabsPanel")
	tabs.custom_minimum_size.y = 64
	root_column.add_child(tabs)
	_build_tabs(tabs)

	content_margin = MarginContainer.new()
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_set_margins(content_margin, 26, 20, 24, 20)
	root_column.add_child(content_margin)
	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	content_margin.add_child(content)

	var title_row := HBoxContainer.new()
	title_row.name = "TitleAndShapes"
	title_row.custom_minimum_size.y = 58
	title_row.add_theme_constant_override("separation", 18)
	content.add_child(title_row)
	title_label = Label.new()
	title_label.name = "StudyTitle"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color("f2f7ff"))
	title_row.add_child(title_label)
	fret_back_button = _button("‹", "IconButton", 44)
	fret_back_button.name = "FretBackButton"
	fret_back_button.tooltip_text = _t("Предыдущие лады", "Previous frets")
	fret_back_button.custom_minimum_size.x = 44
	fret_back_button.visible = false
	fret_back_button.pressed.connect(_move_visible_range.bind(-3))
	title_row.add_child(fret_back_button)
	fret_forward_button = _button("›", "IconButton", 44)
	fret_forward_button.name = "FretForwardButton"
	fret_forward_button.tooltip_text = _t("Следующие лады", "Next frets")
	fret_forward_button.custom_minimum_size.x = 44
	fret_forward_button.visible = false
	fret_forward_button.pressed.connect(_move_visible_range.bind(3))
	title_row.add_child(fret_forward_button)
	shape_row = HBoxContainer.new()
	shape_row.name = "CagedShapeSelector"
	shape_row.add_theme_constant_override("separation", 0)
	shape_row.custom_minimum_size = Vector2(380, 48)
	title_row.add_child(shape_row)
	for shape in SHAPES:
		var shape_button := _button(shape, "SegmentButton", 48)
		shape_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shape_button.pressed.connect(_select_shape.bind(shape))
		shape_buttons[shape] = shape_button
		shape_row.add_child(shape_button)

	main_row = HBoxContainer.new()
	main_row.name = "FretboardAndTheory"
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 20)
	content.add_child(main_row)
	board = BoardView.new()
	board.name = "Fretboard"
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_child(board)
	theory_panel = _panel("TheoryPanel")
	theory_panel.name = "TheoryCard"
	theory_panel.custom_minimum_size.x = 330
	main_row.add_child(theory_panel)
	_build_theory_card(theory_panel)

	lower_row = HBoxContainer.new()
	lower_row.name = "LayersAndLegend"
	lower_row.custom_minimum_size.y = 58
	lower_row.add_theme_constant_override("separation", 18)
	content.add_child(lower_row)
	var layer_group := HBoxContainer.new()
	layer_group.name = "LayerSelector"
	layer_group.custom_minimum_size.x = 720
	layer_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layer_group.add_theme_constant_override("separation", 0)
	lower_row.add_child(layer_group)
	for layer_value in LAYERS:
		var layer_button := _button(_layer_text(layer_value), "SegmentButton", 48)
		layer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		layer_button.pressed.connect(_select_layer.bind(layer_value))
		layer_buttons[layer_value] = layer_button
		layer_group.add_child(layer_button)
	legend_row = HBoxContainer.new()
	legend_row.name = "Legend"
	legend_row.alignment = BoxContainer.ALIGNMENT_CENTER
	legend_row.add_theme_constant_override("separation", 18)
	lower_row.add_child(legend_row)
	_add_legend_item(legend_row, "◆", _t("Тоника", "Root"), AppTheme.NOTE_ROOT)
	_add_legend_item(legend_row, "●", _t("Терция", "Third"), Color("9168f3"))
	_add_legend_item(legend_row, "●", _t("Квинта", "Fifth"), Color("2ed3f2"))
	theory_compact_button = _button(_t("Теория", "Theory"), "PracticeButton", 44)
	theory_compact_button.visible = false
	theory_compact_button.pressed.connect(_toggle_theory_sheet)
	lower_row.add_child(theory_compact_button)

	mini_row = HBoxContainer.new()
	mini_row.name = "MiniNeckAndPractice"
	mini_row.custom_minimum_size.y = 76
	mini_row.add_theme_constant_override("separation", 22)
	content.add_child(mini_row)
	mini_neck = MiniView.new()
	mini_neck.name = "MiniNeckNavigator"
	mini_neck.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mini_neck.range_requested.connect(_set_visible_range)
	mini_row.add_child(mini_neck)
	practice_button = _button(_t("К практике  →", "Practice  →"), "PracticeButton", 58)
	practice_button.custom_minimum_size.x = 255
	practice_button.pressed.connect(_toggle_practice)
	mini_row.add_child(practice_button)

	practice_bar = _panel("PracticePanel")
	practice_bar.name = "PracticeBar"
	practice_bar.visible = false
	practice_bar.custom_minimum_size.y = 52
	content.add_child(practice_bar)
	var practice_box := HBoxContainer.new()
	practice_box.add_theme_constant_override("separation", 12)
	practice_bar.add_child(practice_box)
	practice_label = Label.new()
	practice_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	practice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	practice_label.add_theme_font_size_override("font_size", 19)
	practice_box.add_child(practice_label)
	var close_practice := _button("×", "IconButton", 44)
	close_practice.pressed.connect(_stop_practice)
	practice_box.add_child(close_practice)

	_build_settings_overlay()
	_build_theory_sheet()


func _build_header(parent: PanelContainer) -> void:
	header_margin = MarginContainer.new()
	_set_margins(header_margin, 30, 8, 28, 8)
	parent.add_child(header_margin)
	header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 26)
	header_margin.add_child(header_row)
	brand_box = HBoxContainer.new()
	brand_box.name = "Brand"
	brand_box.custom_minimum_size.x = 350
	brand_box.add_theme_constant_override("separation", 14)
	header_row.add_child(brand_box)
	brand_icon = TextureRect.new()
	brand_icon.texture = load("res://assets/brand_mark.svg")
	brand_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand_icon.custom_minimum_size = Vector2(54, 60)
	brand_box.add_child(brand_icon)
	app_title = Label.new()
	app_title.text = "GuitarMap"
	app_title.add_theme_font_size_override("font_size", 34)
	app_title.add_theme_color_override("font_color", Color("eef6ff"))
	brand_box.add_child(app_title)

	tonic_selector = OptionButton.new()
	tonic_selector.name = "TonicSelector"
	tonic_selector.fit_to_longest_item = false
	tonic_selector.custom_minimum_size = Vector2(245, 54)
	for index in 12:
		tonic_selector.add_item("%s: %s" % [_t("Тоника", "Tonic"), _note_name(index)], index)
	tonic_selector.selected = int(settings.tonic)
	tonic_selector.item_selected.connect(_on_tonic_selected)
	header_row.add_child(tonic_selector)

	scale_selector = OptionButton.new()
	scale_selector.name = "ScaleSelector"
	scale_selector.fit_to_longest_item = false
	scale_selector.custom_minimum_size = Vector2(270, 54)
	_populate_scale_selector()
	scale_selector.item_selected.connect(_on_scale_selected)
	header_row.add_child(scale_selector)
	chord_selector = OptionButton.new()
	chord_selector.name = "ChordSelector"
	chord_selector.fit_to_longest_item = false
	chord_selector.custom_minimum_size = Vector2(270, 54)
	_populate_chord_selector()
	chord_selector.item_selected.connect(_on_chord_selected)
	header_row.add_child(chord_selector)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(spacer)
	scale_play_button = _button("▶  %s" % _t("Слушать", "Listen"), "ScalePlayButton", 56)
	scale_play_button.custom_minimum_size.x = 238
	scale_play_button.pressed.connect(_play_current_material)
	header_row.add_child(scale_play_button)
	settings_button = _button("⚙", "IconButton", 54)
	settings_button.name = "SettingsButton"
	settings_button.custom_minimum_size.x = 62
	settings_button.tooltip_text = _t("Настройки", "Settings")
	settings_button.pressed.connect(_toggle_settings)
	header_row.add_child(settings_button)


func _build_tabs(parent: PanelContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	parent.add_child(row)
	for topic_value in TOPICS:
		var button := _button(_topic_text(topic_value), "TabButton", 58)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_topic.bind(topic_value))
		topic_buttons[topic_value] = button
		row.add_child(button)


func _build_theory_card(parent: PanelContainer) -> void:
	var margin := MarginContainer.new()
	_set_margins(margin, 26, 22, 24, 20)
	parent.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	theory_title = Label.new()
	theory_title.add_theme_font_size_override("font_size", 31)
	theory_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(theory_title)
	theory_subtitle = Label.new()
	theory_subtitle.add_theme_font_size_override("font_size", 22)
	theory_subtitle.add_theme_color_override("font_color", Color("b9cbea"))
	theory_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(theory_subtitle)
	var separator := HSeparator.new()
	separator.modulate = Color("1a5270")
	column.add_child(separator)
	theory_formula = Label.new()
	theory_formula.add_theme_font_size_override("font_size", 56)
	theory_formula.add_theme_color_override("font_color", Color("f3f7ff"))
	theory_formula.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(theory_formula)
	theory_notes = Label.new()
	theory_notes.add_theme_font_size_override("font_size", 23)
	theory_notes.add_theme_color_override("font_color", Color("d6ddff"))
	theory_notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	theory_notes.visible = false
	column.add_child(theory_notes)
	theory_chips = HFlowContainer.new()
	theory_chips.add_theme_constant_override("separation", 10)
	column.add_child(theory_chips)
	theory_overlay_hint = Label.new()
	theory_overlay_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	theory_overlay_hint.add_theme_font_size_override("font_size", 16)
	theory_overlay_hint.add_theme_color_override("font_color", Color("ffc77a"))
	column.add_child(theory_overlay_hint)
	theory_body = Label.new()
	theory_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	theory_body.add_theme_font_size_override("font_size", 18)
	theory_body.add_theme_color_override("font_color", Color("b6c7dc"))
	theory_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(theory_body)


func _build_settings_overlay() -> void:
	settings_scrim = ColorRect.new()
	settings_scrim.name = "SettingsScrim"
	settings_scrim.color = Color(0.0, 0.025, 0.05, 0.73)
	settings_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_scrim.visible = false
	add_child(settings_scrim)
	settings_scrim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			_toggle_settings()
	)
	settings_panel = _panel("SettingsPanel")
	settings_panel.name = "SettingsPanel"
	# A top-left anchor keeps this modal inside the visible root when the
	# headless capture changes the window size between frames.
	settings_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	settings_panel.position = Vector2(20, 20)
	settings_panel.size = Vector2(390, 620)
	settings_panel.visible = false
	add_child(settings_panel)
	var margin := MarginContainer.new()
	_set_margins(margin, 24, 22, 24, 22)
	settings_panel.add_child(margin)
	var shell := VBoxContainer.new()
	shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_theme_constant_override("separation", 12)
	margin.add_child(shell)
	settings_title = Label.new()
	settings_title.text = _t("Настройки", "Settings")
	settings_title.add_theme_font_size_override("font_size", 28)
	shell.add_child(settings_title)
	var scroll := ScrollContainer.new()
	scroll.name = "SettingsScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)

	tuning_label = _settings_label(column, _t("Строй", "Tuning"))
	tuning_selector = _settings_option(column)
	_tuning_records = explorer.tunings
	for index in _tuning_records.size():
		var record: Dictionary = _tuning_records[index]
		tuning_selector.add_item(str(record.names.get(language, record.names.en)), index)
	var tuning_index := _tuning_index(str(settings.tuning_id))
	if tuning_index >= 0:
		tuning_selector.selected = tuning_index
	tuning_selector.item_selected.connect(_on_tuning_selected)

	custom_tuning_edit = LineEdit.new()
	custom_tuning_edit.name = "CustomTuningEdit"
	custom_tuning_edit.placeholder_text = _t("MIDI через запятую: 40,45,50…", "Comma-separated MIDI: 40,45,50…")
	if str(settings.tuning_id) == "custom":
		custom_tuning_edit.text = _custom_tuning_text(settings.custom_tuning)
	custom_tuning_edit.custom_minimum_size.y = 44
	column.add_child(custom_tuning_edit)
	custom_apply_button = _button(_t("Применить свой строй", "Apply custom tuning"), "SegmentButton", 44)
	custom_apply_button.pressed.connect(_apply_custom_tuning)
	column.add_child(custom_apply_button)
	settings_status_label = Label.new()
	settings_status_label.name = "SettingsStatus"
	settings_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_status_label.visible = false
	column.add_child(settings_status_label)

	fret_count_label = _settings_label(column, _t("Количество ладов", "Fret count"))
	fret_count_selector = _settings_option(column)
	for fret_count in range(12, 37):
		fret_count_selector.add_item(str(fret_count), fret_count)
	fret_count_selector.selected = clampi(int(settings.fret_count) - 12, 0, 24)
	fret_count_selector.item_selected.connect(_on_fret_count_selected)

	spelling_label = _settings_label(column, _t("Названия нот", "Note spelling"))
	spelling_selector = _settings_option(column)
	_populate_spelling_selector()
	spelling_selector.item_selected.connect(_on_spelling_selected)

	tempo_label = _settings_label(column, _t("Темп", "Tempo"))
	var tempo_row := HBoxContainer.new()
	tempo_row.add_theme_constant_override("separation", 12)
	column.add_child(tempo_row)
	tempo_slider = HSlider.new()
	tempo_slider.name = "TempoSlider"
	tempo_slider.min_value = 30.0
	tempo_slider.max_value = 240.0
	tempo_slider.step = 1.0
	tempo_slider.value = float(settings.tempo_bpm)
	tempo_slider.custom_minimum_size.y = 44
	tempo_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tempo_slider.value_changed.connect(_on_tempo_changed)
	tempo_row.add_child(tempo_slider)
	tempo_value_label = Label.new()
	tempo_value_label.name = "TempoValue"
	tempo_value_label.custom_minimum_size = Vector2(72, 44)
	tempo_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tempo_row.add_child(tempo_value_label)
	_update_tempo_label()

	guitar_label = _settings_label(column, _t("Тембр", "Timbre"))
	guitar_selector = _settings_option(column)
	guitar_selector.add_item(_t("Акустическая гитара", "Acoustic guitar"), 0)
	guitar_selector.add_item(_t("Электрогитара", "Electric guitar"), 1)
	guitar_selector.selected = 1 if str(settings.guitar_type) == "electric" else 0
	guitar_selector.item_selected.connect(_on_guitar_selected)

	volume_label = _settings_label(column, _t("Громкость", "Volume"))
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.value = float(settings.master_volume)
	volume_slider.custom_minimum_size.y = 44
	volume_slider.value_changed.connect(_on_volume_changed)
	column.add_child(volume_slider)

	language_label = _settings_label(column, _t("Язык", "Language"))
	language_selector = _settings_option(column)
	language_selector.add_item("Русский", 0)
	language_selector.add_item("English", 1)
	language_selector.selected = 1 if language == "en" else 0
	language_selector.item_selected.connect(_on_language_selected)
	mirror_toggle = CheckButton.new()
	mirror_toggle.text = _t("Зеркальный гриф", "Mirror fretboard")
	mirror_toggle.button_pressed = bool(settings.mirrored)
	mirror_toggle.custom_minimum_size.y = 44
	mirror_toggle.toggled.connect(_on_mirror_toggled)
	column.add_child(mirror_toggle)
	close_settings_button = _button(_t("Готово", "Done"), "ScalePlayButton", 48)
	close_settings_button.pressed.connect(_toggle_settings)
	column.add_child(close_settings_button)


func _build_theory_sheet() -> void:
	theory_sheet = _panel("SettingsPanel")
	theory_sheet.name = "TheorySheet"
	theory_sheet.set_anchors_preset(Control.PRESET_TOP_LEFT)
	theory_sheet.size = Vector2(540, 350)
	theory_sheet.visible = false
	add_child(theory_sheet)
	var margin := MarginContainer.new()
	_set_margins(margin, 24, 20, 24, 20)
	theory_sheet.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	theory_sheet_title = Label.new()
	theory_sheet_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	theory_sheet_title.add_theme_font_size_override("font_size", 25)
	theory_sheet_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(theory_sheet_title)
	var close := _button("×", "IconButton", 42)
	close.pressed.connect(_toggle_theory_sheet)
	top.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.name = "TheoryTextScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 10)
	scroll.add_child(text_column)
	theory_sheet_formula = Label.new()
	theory_sheet_formula.add_theme_font_size_override("font_size", 29)
	theory_sheet_formula.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(theory_sheet_formula)
	theory_sheet_notes = Label.new()
	theory_sheet_notes.add_theme_color_override("font_color", Color("c9d9f2"))
	theory_sheet_notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(theory_sheet_notes)
	theory_sheet_body = Label.new()
	theory_sheet_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	theory_sheet_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	theory_sheet_body.add_theme_color_override("font_color", Color("a9bed3"))
	text_column.add_child(theory_sheet_body)


func _refresh_learning_view() -> void:
	if board != null and touch_coordinator != null:
		_stop_all_audio("learning_material_changed")
		if practice_session != null:
			_stop_practice()
	learning.tonic = int(settings.tonic)
	learning.scale_id = str(settings.scale_id)
	learning.topic = str(settings.study_topic)
	learning.shape = str(settings.caged_shape)
	learning.layer = str(settings.study_layer)
	learning.chord_id = str(settings.chord_id)
	learning.spelling = str(settings.spelling)
	learning.language = language
	learning.fret_count = int(settings.fret_count)
	_all_positions = learning.positions()
	var recommended := learning.recommended_range()
	if str(settings.study_topic) == "caged":
		_visible_range = recommended
	_visible_range = _clamped_range(_visible_range)
	var labels: Array[String] = []
	for midi in learning.tuning:
		labels.append(_note_name(posmod(int(midi), 12)))
	board.configure(_all_positions, learning.tuning.size(), int(settings.fret_count), bool(settings.mirrored), labels, _visible_range)
	board.set_learning_context(str(settings.study_topic), str(settings.study_layer))
	mini_neck.configure(_all_positions, learning.tuning.size(), int(settings.fret_count), _visible_range)
	_update_explanation()
	_update_selected_styles()
	_save_settings()


func _update_explanation() -> void:
	var explanation: Dictionary = learning.explanation()
	var topic_value := str(settings.study_topic)
	shape_row.visible = topic_value == "caged"
	chord_selector.visible = topic_value in ["chords", "arpeggios"]
	scale_selector.visible = topic_value in ["scales", "caged"]
	if topic_value == "caged":
		title_label.text = "%s %s · %s %s" % [_tonic_title(), _t("мажор", "major"), _t("форма", "shape"), str(settings.caged_shape)]
		theory_title.text = "%s %s" % [_t("Форма", "Shape"), str(settings.caged_shape)]
	else:
		title_label.text = str(explanation.get("title", _topic_text(topic_value)))
		theory_title.text = _topic_text(topic_value)
	theory_subtitle.text = _theory_subtitle(topic_value)
	theory_formula.text = str(explanation.get("formula", ""))
	theory_formula.add_theme_font_size_override("font_size", 56 if topic_value in ["caged", "chords"] else 30)
	var note_values: Variant = explanation.get("notes", "")
	theory_notes.text = "  ·  ".join(note_values) if note_values is Array else str(note_values)
	_rebuild_theory_chips(explanation)
	theory_overlay_hint.visible = topic_value == "caged" and str(settings.study_layer) == "scale"
	var outside_notes: Array[String] = []
	for position: Dictionary in _all_positions:
		if bool(position.in_shape) and not bool(position.in_scale):
			var note := _pretty_note(str(position.note))
			if not outside_notes.has(note): outside_notes.append(note)
	theory_overlay_hint.text = _t("Обводка — звуки формы.", "Outline: shape tones.")
	if not outside_notes.is_empty():
		theory_overlay_hint.text += "\n" + _t("! Вне гаммы: ", "! Outside scale: ") + ", ".join(outside_notes)
	if not bool(explanation.get("compatible", true)):
		theory_body.text = str(explanation.get("message", ""))
	else:
		theory_body.text = str(explanation.get("body", ""))
	theory_sheet_title.text = theory_title.text
	theory_sheet_formula.text = theory_formula.text
	theory_sheet_notes.text = theory_notes.text
	theory_sheet_body.text = theory_body.text
	if theory_overlay_hint.visible:
		theory_sheet_body.text = theory_overlay_hint.text + "\n\n" + theory_sheet_body.text


func _update_selected_styles() -> void:
	for key in topic_buttons:
		_set_selected(topic_buttons[key], str(key) == str(settings.study_topic), "TabSelected", "TabButton")
	for key in shape_buttons:
		_set_selected(shape_buttons[key], str(key) == str(settings.caged_shape), "SegmentSelected", "SegmentButton")
	for key in layer_buttons:
		layer_buttons[key].text = _layer_text(str(key))
		_set_selected(layer_buttons[key], str(key) == str(settings.study_layer), "LayerSelected", "SegmentButton")


func _select_topic(topic_value: String) -> void:
	_stop_all_audio("topic_changed")
	settings.study_topic = topic_value
	if topic_value == "scales":
		settings.study_layer = "scale"
	elif topic_value in ["chords", "arpeggios"]:
		settings.study_layer = "chord"
	_refresh_learning_view()


func _select_shape(shape_value: String) -> void:
	_stop_all_audio("shape_changed")
	settings.caged_shape = shape_value
	_refresh_learning_view()


func _select_layer(layer_value: String) -> void:
	_stop_all_audio("layer_changed")
	settings.study_layer = layer_value
	learning.layer = layer_value
	board.set_learning_context(str(settings.study_topic), layer_value)
	_update_selected_styles()
	_update_explanation()
	_save_settings()


func _on_tonic_selected(index: int) -> void:
	settings.tonic = index
	_refresh_learning_view()


func _on_scale_selected(index: int) -> void:
	if index >= 0 and index < explorer.scales.size():
		settings.scale_id = str(explorer.scales[index].id)
		_refresh_learning_view()


func _on_chord_selected(index: int) -> void:
	var records := learning.chord_records()
	if index >= 0 and index < records.size():
		settings.chord_id = str(records[index].id)
		_refresh_learning_view()


func _set_visible_range(range_value: Vector2i) -> void:
	_visible_range = _clamped_range(range_value)
	board.set_visible_range(_visible_range)
	mini_neck.set_visible_range(_visible_range)


func _move_visible_range(delta: int) -> void:
	_set_visible_range(Vector2i(_visible_range.x + delta, _visible_range.y + delta))


func _play_current_material() -> void:
	if sequence_player.is_playing():
		sequence_player.stop()
		scale_play_button.text = "▶  %s" % _t("Слушать", "Listen")
		return
	_playback_positions = _material_positions()
	if _playback_positions.is_empty():
		return
	var midi_notes: Array = _playback_positions.map(func(position: Dictionary): return int(position.midi_note))
	if str(settings.study_topic) in ["chords", "caged"] and str(settings.study_layer) == "chord":
		sequence_player.play_chord(midi_notes, playback_timing().chord_duration, 0.76)
	else:
		var timing := playback_timing()
		sequence_player.play_arpeggio(midi_notes, timing.step_seconds, timing.gate_seconds, 0.76)
	scale_play_button.text = "■  %s" % _t("Стоп", "Stop")


func _material_positions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen_midi := {}
	for position: Dictionary in _all_positions:
		if int(position.fret) < _visible_range.x or int(position.fret) > _visible_range.y:
			continue
		var include := false
		match str(settings.study_layer):
			"roots": include = bool(position.is_root) and (str(settings.study_topic) != "caged" or bool(position.in_shape))
			"scale": include = bool(position.in_scale)
			_:
				include = bool(position.in_shape) if str(settings.study_topic) == "caged" else bool(position.in_chord)
		if not include or seen_midi.has(int(position.midi_note)):
			continue
		seen_midi[int(position.midi_note)] = true
		result.append(position)
	result.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.midi_note) < int(b.midi_note))
	if str(settings.study_topic) in ["scales", "arpeggios"] or str(settings.study_layer) == "scale":
		result = _root_to_root(result)
	if str(settings.study_topic) == "caged" and str(settings.study_layer) == "chord" and result.size() > 6:
		result.resize(6)
	if str(settings.study_layer) == "scale":
		var ascending := result.duplicate()
		for index in range(ascending.size() - 2, -1, -1):
			result.append(ascending[index])
	return result


func _root_to_root(sorted_positions: Array[Dictionary]) -> Array[Dictionary]:
	var first_root := -1
	for index in sorted_positions.size():
		if bool(sorted_positions[index].is_root):
			first_root = index
			break
	if first_root < 0:
		return sorted_positions
	var result: Array[Dictionary] = []
	var root_midi := int(sorted_positions[first_root].midi_note)
	for index in range(first_root, sorted_positions.size()):
		var position: Dictionary = sorted_positions[index]
		if int(position.midi_note) > root_midi + 12:
			break
		result.append(position)
		if result.size() > 1 and bool(position.is_root):
			break
	return result


func _on_sequence_note(index: int, midi_note: int) -> void:
	if index < _playback_positions.size():
		if str(settings.study_topic) in ["chords", "caged"] and str(settings.study_layer) == "chord":
			if index == 0: board.clear_playback_highlight()
			board.add_playback_position(_playback_positions[index])
		else:
			board.set_playback_position(_playback_positions[index])
	else:
		board.set_playback_midi(midi_note)


func _on_playback_finished() -> void:
	board.clear_playback_highlight()
	scale_play_button.text = "▶" if size.x < 800.0 else ("▶  %s" % _t("Слушать", "Listen"))


func _on_position_pressed(owner_id: int, position: Dictionary) -> void:
	touch_coordinator.press(owner_id, position, 0.78)
	if practice_session != null and practice_session.has_active_task():
		var result := practice_session.submit_answer(int(position.string_index), int(position.fret))
		board.show_practice_feedback(position, bool(result.correct))
		practice_label.text = _t("Верно!", "Correct!") if result.correct else _t("Пока нет. Посмотри связь и попробуй следующую.", "Not yet. Notice the relation and try the next one.")
		_practice_generation += 1
		_next_practice_after_delay(_practice_generation)


func _on_position_moved(owner_id: int, position: Dictionary) -> void:
	touch_coordinator.move(owner_id, position, 0.74)


func _toggle_practice() -> void:
	if practice_session != null:
		_stop_practice()
		return
	var available: Array[Dictionary] = []
	for position: Dictionary in _all_positions:
		if int(position.fret) >= _visible_range.x and int(position.fret) <= _visible_range.y and bool(position.in_scale):
			available.append(position)
	practice_session = PracticeSession.new(available, PracticeSession.TARGET_PITCH_CLASS, Time.get_ticks_msec())
	practice_bar.visible = true
	mini_row.visible = false
	practice_button.text = _t("Закончить", "Finish")
	_start_next_practice_task()


func _start_next_practice_task() -> void:
	if practice_session == null:
		return
	var task := practice_session.next_task()
	var note_name := _note_name(int(task.target_value))
	practice_label.text = "%s:  %s" % [_t("Найдите на грифе", "Find on the fretboard"), note_name]
	board.set_practice_mode(true, int(task.target_value))


func _next_practice_after_delay(generation: int) -> void:
	await get_tree().create_timer(0.7).timeout
	if generation == _practice_generation and practice_session != null:
		_start_next_practice_task()


func _stop_practice() -> void:
	_practice_generation += 1
	if practice_session != null:
		practice_stats_store.record_session(practice_session.snapshot())
	practice_session = null
	practice_bar.visible = false
	mini_row.visible = true
	practice_button.text = _t("К практике  →", "Practice  →")
	board.set_practice_mode(false)


func _toggle_settings() -> void:
	var next_visible := not settings_panel.visible
	if next_visible:
		_layout_settings_panel(size)
	settings_panel.visible = next_visible
	settings_scrim.visible = next_visible
	if next_visible:
		settings_panel.move_to_front()


func _toggle_theory_sheet() -> void:
	theory_sheet.visible = not theory_sheet.visible
	if theory_sheet.visible:
		_update_explanation()
		_layout_theory_sheet(size)
		theory_sheet.move_to_front()


func _on_tuning_selected(index: int) -> void:
	if index < 0 or index >= _tuning_records.size(): return
	var record: Dictionary = _tuning_records[index]
	settings.tuning_id = str(record.id)
	settings.custom_tuning = []
	explorer.select_tuning(str(record.id))
	learning.tuning = record.open_string_midi.duplicate()
	_refresh_learning_view()


func _apply_custom_tuning() -> void:
	var notes: Array[int] = []
	for part in custom_tuning_edit.text.split(","):
		var value := str(part).strip_edges()
		if not value.is_valid_int():
			_set_settings_status(_t("Укажите MIDI-ноты через запятую.", "Enter comma-separated MIDI notes."), false)
			return
		var midi := int(value)
		if midi < 0 or midi > 127:
			_set_settings_status(_t("Каждая MIDI-нота: от 0 до 127.", "Each MIDI note must be from 0 to 127."), false)
			return
		notes.append(midi)
	if notes.is_empty():
		_set_settings_status(_t("Добавьте хотя бы одну MIDI-ноту.", "Add at least one MIDI note."), false)
		return
	settings.tuning_id = "custom"
	settings.custom_tuning = notes.duplicate()
	learning.tuning = notes.duplicate()
	tuning_selector.selected = -1
	_set_settings_status(_t("Свой строй применён.", "Custom tuning applied."), true)
	_refresh_learning_view()


func _on_guitar_selected(index: int) -> void:
	settings.guitar_type = "electric" if index == 1 else "acoustic"
	audio_engine.set_timbre(StringName(str(settings.guitar_type)))
	_save_settings()


func _on_volume_changed(value: float) -> void:
	settings.master_volume = value
	audio_engine.set_master_volume(value)
	_save_settings()


func _on_fret_count_selected(index: int) -> void:
	if index < 0 or index >= fret_count_selector.get_item_count():
		return
	settings.fret_count = int(fret_count_selector.get_item_id(index))
	_refresh_learning_view()


func _on_spelling_selected(index: int) -> void:
	var spellings := ["sharp", "flat", "context"]
	if index < 0 or index >= spellings.size():
		return
	settings.spelling = spellings[index]
	_refresh_learning_view()
	_rebuild_localized_text()


func _on_tempo_changed(value: float) -> void:
	settings.tempo_bpm = int(round(value))
	_update_tempo_label()
	_save_settings()


func _on_language_selected(index: int) -> void:
	language = "en" if index == 1 else "ru"
	settings.language = language
	learning.language = language
	_rebuild_localized_text()
	_save_settings()


func _on_mirror_toggled(value: bool) -> void:
	settings.mirrored = value
	_refresh_learning_view()


func _rebuild_localized_text() -> void:
	for index in 12:
		tonic_selector.set_item_text(index, "%s: %s" % [_t("Тоника", "Tonic"), _note_name(index)])
	_populate_scale_selector()
	_populate_chord_selector()
	practice_button.text = _t("К практике  →", "Practice  →")
	scale_play_button.text = "▶  %s" % _t("Слушать", "Listen")
	for topic_value in TOPICS:
		topic_buttons[topic_value].text = _topic_text(topic_value)
	theory_compact_button.text = _t("Теория", "Theory")
	fret_back_button.tooltip_text = _t("Предыдущие лады", "Previous frets")
	fret_forward_button.tooltip_text = _t("Следующие лады", "Next frets")
	_refresh_settings_text()
	_update_explanation()
	_update_selected_styles()


func _apply_responsive_layout() -> void:
	if not is_node_ready(): return
	var viewport_size := size
	var compact := viewport_size.y < 820.0 or viewport_size.x < 1450.0
	var very_compact := viewport_size.y < 470.0 or viewport_size.x < 800.0
	header.custom_minimum_size.y = 56 if very_compact else (68 if compact else 86)
	tabs.custom_minimum_size.y = 42 if very_compact else (50 if compact else 64)
	var safe := _safe_margins(8 if very_compact else (14 if compact else 24))
	_set_margins(content_margin, int(safe.left), 0 if very_compact else 8, int(safe.right), 0 if very_compact else 10)
	theory_panel.visible = not very_compact
	theory_panel.custom_minimum_size.x = 250 if compact else 330
	mini_row.visible = practice_session == null
	mini_neck.visible = not compact
	mini_row.custom_minimum_size.y = 48 if compact else 76
	practice_button.custom_minimum_size.y = 46 if compact else 58
	practice_button.custom_minimum_size.x = 190 if compact else 255
	legend_row.visible = not compact
	theory_compact_button.visible = compact
	lower_row.custom_minimum_size.y = 42 if very_compact else 52
	shape_row.custom_minimum_size.x = 270 if compact else 380
	var header_safe := _safe_margins(6 if very_compact else (14 if compact else 28))
	_set_margins(header_margin, int(header_safe.left), 0 if very_compact else 6, int(header_safe.right), 0 if very_compact else 6)
	header_row.add_theme_constant_override("separation", 6 if very_compact else (12 if compact else 26))
	brand_box.custom_minimum_size.x = 58 if very_compact else (220 if compact else 350)
	brand_icon.custom_minimum_size = Vector2(44, 48) if compact else Vector2(54, 60)
	app_title.visible = not very_compact
	tonic_selector.custom_minimum_size.x = 140 if very_compact else (180 if compact else 245)
	scale_selector.custom_minimum_size.x = 145 if very_compact else (215 if compact else 270)
	chord_selector.custom_minimum_size.x = scale_selector.custom_minimum_size.x
	scale_play_button.custom_minimum_size.x = 108 if very_compact else (168 if compact else 238)
	scale_play_button.text = "▶" if very_compact else ("▶  %s" % _t("Слушать", "Listen"))
	settings_button.custom_minimum_size.x = 48 if compact else 62
	tonic_selector.add_theme_font_size_override("font_size", 15 if compact else 19)
	scale_selector.add_theme_font_size_override("font_size", 15 if compact else 19)
	chord_selector.add_theme_font_size_override("font_size", 15 if compact else 19)
	scale_play_button.add_theme_font_size_override("font_size", 15 if compact else 19)
	for topic_button in topic_buttons.values():
		topic_button.custom_minimum_size.y = 38 if very_compact else (46 if compact else 58)
		topic_button.add_theme_font_size_override("font_size", 15 if compact else 19)
	for shape_button in shape_buttons.values():
		shape_button.custom_minimum_size.y = 34 if very_compact else 48
		shape_button.add_theme_font_size_override("font_size", 15 if compact else 18)
	for layer_button in layer_buttons.values():
		layer_button.custom_minimum_size.x = 0
	var layer_group := lower_row.get_node("LayerSelector") as HBoxContainer
	layer_group.custom_minimum_size.x = 0 if compact else 720
	if compact and practice_button.get_parent() != lower_row:
		practice_button.reparent(lower_row)
	elif not compact and practice_button.get_parent() != mini_row:
		practice_button.reparent(mini_row)
	mini_row.visible = not compact and practice_session == null
	title_label.visible = not very_compact
	fret_back_button.visible = compact
	fret_forward_button.visible = compact
	shape_row.custom_minimum_size.y = 34 if very_compact else 48
	var title_parent := title_label.get_parent() as Control
	title_parent.custom_minimum_size.y = 34 if very_compact else 58
	var compact_formula := str(settings.study_topic) in ["scales", "arpeggios"]
	var formula_size := (24 if compact else 30) if compact_formula else (42 if compact else 56)
	theory_formula.add_theme_font_size_override("font_size", formula_size)
	theory_body.visible = not compact
	title_label.add_theme_font_size_override("font_size", 22 if compact else 30)
	app_title.add_theme_font_size_override("font_size", 27 if compact else 34)
	board.custom_minimum_size.y = 140 if very_compact else 240
	_layout_settings_panel(viewport_size)
	_layout_theory_sheet(viewport_size)


func _layout_theory_sheet(viewport_size: Vector2) -> void:
	theory_sheet.size = Vector2(minf(620.0, viewport_size.x - 24.0), minf(480.0, viewport_size.y - 24.0))
	theory_sheet.position = (viewport_size - theory_sheet.size) * 0.5


func _stop_all_audio(reason: String) -> void:
	if sequence_player != null: sequence_player.stop()
	if touch_coordinator != null: touch_coordinator.cancel_all(reason)
	if board != null:
		board.clear_contacts()
		board.clear_playback_highlight()


func _notification(what: int) -> void:
	if what in [MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT, MainLoop.NOTIFICATION_APPLICATION_PAUSED]:
		_stop_all_audio("lifecycle")


func _save_settings() -> void:
	if settings_store != null:
		settings_store.save_settings(settings)


func _populate_scale_selector() -> void:
	if scale_selector == null: return
	scale_selector.clear()
	var selected_index := 0
	for index in explorer.scales.size():
		var record: Dictionary = explorer.scales[index]
		var display_name := str(record.names.get(language, record.names.en))
		scale_selector.add_item(display_name, index)
		if str(record.id) == str(settings.scale_id): selected_index = index
	scale_selector.selected = selected_index


func _populate_chord_selector() -> void:
	if chord_selector == null: return
	chord_selector.clear()
	var selected_index := 0
	var records := learning.chord_records()
	for index in records.size():
		var record = records[index]
		var names: Dictionary = record.names
		chord_selector.add_item(str(names.get(language, record.id)), index)
		if str(record.id) == str(settings.chord_id): selected_index = index
	chord_selector.selected = selected_index


func _populate_spelling_selector() -> void:
	if spelling_selector == null:
		return
	spelling_selector.clear()
	var options := [
		{"id": "sharp", "text": _t("Диезы (C♯)", "Sharps (C♯)")},
		{"id": "flat", "text": _t("Бемоли (D♭)", "Flats (D♭)")},
		{"id": "context", "text": _t("По контексту", "Contextual")},
	]
	var selected_index := 0
	for index in options.size():
		var option: Dictionary = options[index]
		spelling_selector.add_item(str(option.text), index)
		if str(option.id) == str(settings.spelling):
			selected_index = index
	spelling_selector.selected = selected_index


func _refresh_settings_text() -> void:
	if settings_title == null:
		return
	settings_title.text = _t("Настройки", "Settings")
	tuning_label.text = _t("Строй", "Tuning")
	guitar_label.text = _t("Тембр", "Timbre")
	volume_label.text = _t("Громкость", "Volume")
	fret_count_label.text = _t("Количество ладов", "Fret count")
	spelling_label.text = _t("Названия нот", "Note spelling")
	tempo_label.text = _t("Темп", "Tempo")
	language_label.text = _t("Язык", "Language")
	custom_tuning_edit.placeholder_text = _t("MIDI через запятую: 40,45,50…", "Comma-separated MIDI: 40,45,50…")
	custom_apply_button.text = _t("Применить свой строй", "Apply custom tuning")
	guitar_selector.set_item_text(0, _t("Акустическая гитара", "Acoustic guitar"))
	guitar_selector.set_item_text(1, _t("Электрогитара", "Electric guitar"))
	language_selector.set_item_text(0, "Русский")
	language_selector.set_item_text(1, "English")
	mirror_toggle.text = _t("Зеркальный гриф", "Mirror fretboard")
	close_settings_button.text = _t("Готово", "Done")
	for index in _tuning_records.size():
		var record: Dictionary = _tuning_records[index]
		tuning_selector.set_item_text(index, str(record.names.get(language, record.names.en)))
	_populate_spelling_selector()
	_update_tempo_label()


func _update_tempo_label() -> void:
	if tempo_value_label != null:
		tempo_value_label.text = "%d BPM" % int(settings.tempo_bpm)


func _layout_settings_panel(viewport_size: Vector2) -> void:
	var panel_width := minf(390.0, viewport_size.x - 32.0)
	var panel_height := minf(620.0, viewport_size.y - 32.0)
	settings_panel.size = Vector2(maxf(280.0, panel_width), maxf(180.0, panel_height))
	settings_panel.position = Vector2(
		maxf(16.0, viewport_size.x - settings_panel.size.x - 20.0),
		maxf(16.0, (viewport_size.y - settings_panel.size.y) * 0.5)
	)


func _custom_tuning_text(notes: Array) -> String:
	var values := PackedStringArray()
	for midi in notes:
		values.append(str(int(midi)))
	return ",".join(values)


func _set_settings_status(message: String, is_success: bool) -> void:
	if settings_status_label == null:
		return
	settings_status_label.text = message
	settings_status_label.add_theme_color_override("font_color", Color("70e2ae") if is_success else Color("ff9d9d"))
	settings_status_label.visible = not message.is_empty()


func seconds_per_beat() -> float:
	return 60.0 / clampf(float(settings.get("tempo_bpm", 60)), 30.0, 240.0)


func playback_timing() -> Dictionary:
	var beat_seconds := seconds_per_beat()
	return {
		"step_seconds": beat_seconds,
		"gate_seconds": beat_seconds * 0.8,
		"chord_duration": beat_seconds * 2.0,
	}


func _clamped_range(value: Vector2i) -> Vector2i:
	var count := int(settings.fret_count)
	var width := maxi(4, value.y - value.x)
	var start := clampi(value.x, 0, maxi(0, count - width))
	return Vector2i(start, mini(count, start + width))


func _tuning_index(id_value: String) -> int:
	for index in _tuning_records.size():
		if str(_tuning_records[index].id) == id_value: return index
	return -1


func _theory_subtitle(topic_value: String) -> String:
	var root := _note_name(int(settings.tonic))
	match topic_value:
		"caged": return "%s %s" % [_t("Аккорд", "Chord"), root]
		"chords": return "%s · %s" % [_t("Аккорд", "Chord"), root]
		"arpeggios": return _t("Звуки аккорда по очереди", "Chord tones one by one")
		_: return _t("Ступени выбранной гаммы", "Degrees of the selected scale")


func _tonic_title() -> String:
	if language == "en":
		return _note_name(int(settings.tonic))
	var russian_names := ["До", "До♯", "Ре", "Ре♯", "Ми", "Фа", "Фа♯", "Соль", "Соль♯", "Ля", "Ля♯", "Си"]
	return russian_names[posmod(int(settings.tonic), 12)]


func _rebuild_theory_chips(explanation: Dictionary) -> void:
	for child in theory_chips.get_children():
		child.queue_free()
	var raw_notes: Variant = explanation.get("note_names", [])
	var values: Array = raw_notes if raw_notes is Array else str(explanation.get("notes", "")).split(" · ")
	var degree_tokens := str(explanation.get("formula", "")).replace("·", " ").replace("→", " ").split(" ", false)
	for index in values.size():
		var chip := PanelContainer.new()
		var style := StyleBoxFlat.new()
		var degree := str(degree_tokens[index]) if index < degree_tokens.size() else ""
		style.bg_color = _chip_color_for_degree(degree)
		style.set_corner_radius_all(18)
		style.content_margin_left = 15
		style.content_margin_right = 15
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		chip.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.text = _pretty_note(str(values[index]))
		label.add_theme_font_size_override("font_size", 19)
		label.add_theme_color_override("font_color", Color("061018"))
		chip.add_child(label)
		theory_chips.add_child(chip)


func _chip_color_for_degree(degree: String) -> Color:
	match degree.strip_edges():
		"1": return AppTheme.NOTE_ROOT
		"b3", "♭3", "3", "#3", "♯3": return Color("9168f3")
		"b5", "♭5", "5", "#5", "♯5": return Color("2ed3f2")
		_: return Color("52687b")


func _topic_text(value: String) -> String:
	match value:
		"scales": return _t("Гаммы и лады", "Scales & modes")
		"chords": return _t("Аккорды", "Chords")
		"arpeggios": return _t("Арпеджио", "Arpeggios")
		_: return "CAGED"


func _layer_text(value: String) -> String:
	match value:
		"roots": return _t("Тоники", "Roots")
		"scale": return _t("Гамма", "Scale")
		_: return _t("Аккорд", "Chord")


func _note_name(pitch_class: int) -> String:
	return NoteNames.name_for(pitch_class, str(settings.spelling), int(settings.tonic))


func _pretty_note(value: String) -> String:
	return value.replace("#", "♯").replace("b", "♭")


func _t(ru: String, en: String) -> String:
	return en if language == "en" else ru


func _panel(variation: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = variation
	return panel


func _button(text_value: String, variation: String, height: float) -> Button:
	var button := Button.new()
	button.text = text_value
	button.theme_type_variation = variation
	button.custom_minimum_size.y = height
	button.focus_mode = Control.FOCUS_ALL
	return button


func _labeled_option(parent: VBoxContainer, label_text: String) -> OptionButton:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color("a8bfd3"))
	parent.add_child(label)
	var option := OptionButton.new()
	option.custom_minimum_size.y = 44
	parent.add_child(option)
	return option


func _settings_label(parent: VBoxContainer, label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	return label


func _settings_option(parent: VBoxContainer) -> OptionButton:
	var option := OptionButton.new()
	option.fit_to_longest_item = false
	option.custom_minimum_size.y = 44
	parent.add_child(option)
	return option


func _set_selected(button: Button, selected: bool, selected_variation: String, normal_variation: String) -> void:
	button.theme_type_variation = selected_variation if selected else normal_variation
	button.set_pressed_no_signal(selected)


func _add_legend_item(parent: HBoxContainer, symbol: String, label_text: String, color: Color) -> void:
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", 7)
	parent.add_child(item)
	var marker := Label.new()
	marker.text = symbol
	marker.add_theme_font_size_override("font_size", 23)
	marker.add_theme_color_override("font_color", color)
	item.add_child(marker)
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color("96afd0"))
	item.add_child(label)


func _set_margins(container: MarginContainer, left: int, top: int, right: int, bottom: int) -> void:
	container.add_theme_constant_override("margin_left", left)
	container.add_theme_constant_override("margin_top", top)
	container.add_theme_constant_override("margin_right", right)
	container.add_theme_constant_override("margin_bottom", bottom)


func _safe_margins(base: int) -> Dictionary:
	if not OS.has_feature("mobile"):
		return {"left": base, "right": base}
	var safe_area := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	var margins := ResponsiveLayout.safe_margins(size, window_size, safe_area, base)
	return {"left": int(margins.left), "right": int(margins.right)}
