class_name StudyTools
extends PanelContainer

const MaterialComparison := preload("res://scripts/application/material_comparison.gd")
const GuidedStudy := preload("res://scripts/application/guided_study.gd")
const CagedConnection := preload("res://scripts/application/caged_connection.gd")
const Learning := preload("res://scripts/application/learning_model.gd")

var route_enabled := false
var active_lesson := false

var _host: Control
var _guard := false
var _tab := "comparison"
var _tab_buttons: Dictionary = {}
var _content: VBoxContainer
var _comparison_source: LearningModel
var _comparison_target_id := ""
var _comparison_showing_target := false
var _comparison_baseline := {}
var _lesson_steps: Array[Dictionary] = []
var _lesson_index := 0
var _lesson_original_layer := ""
var _route: Array[Dictionary] = []
var _loop_enabled := false
var _pause_seconds := 0.0
var _drone_enabled := false
var _shell_title: Label
var _inspected_note: Dictionary = {}


func setup(host_scene: Control) -> void:
	_host = host_scene
	name = "StudyTools"
	custom_minimum_size.x = 400
	visible = false
	if get_parent() == null and _host != null:
		_host.add_child(self)
	visibility_changed.connect(_on_visibility_changed)
	_build_shell()
	layout_panel(_host.size if _host != null else Vector2(1280, 720))


func material_changed() -> void:
	if _guard:
		return
	_end_study(false)
	_comparison_source = null
	_comparison_target_id = ""
	_comparison_baseline.clear()
	_comparison_showing_target = false
	if visible:
		_rebuild_content()


func toggle() -> void:
	if _host != null and _host.practice_session != null:
		_host._stop_practice()
	visible = not visible
	if visible:
		if _host != null and _host.settings_panel != null and _host.settings_panel.visible:
			_host._toggle_settings()
		move_to_front()
		layout_panel(_host.size if _host != null else size)
		_rebuild_content()


func show_playback() -> void:
	if _host != null and _host.practice_session != null:
		_host._stop_practice()
	_tab = "playback"
	visible = true
	move_to_front()
	layout_panel(_host.size if _host != null else size)
	_rebuild_content()


func layout_panel(viewport_size: Vector2) -> void:
	if _host != null and viewport_size.x >= 1100.0 and viewport_size.y >= 560.0 and _host.main_row != null:
		position = _host.main_row.global_position + Vector2(maxf(0.0, _host.main_row.size.x - 400.0), 0.0)
		size = Vector2(400.0, maxf(180.0, _host.main_row.size.y))
		return
	var panel_width := minf(400.0, maxf(300.0, viewport_size.x - 24.0))
	var top := 76.0 if viewport_size.y >= 560.0 else 42.0
	position = Vector2(maxf(12.0, viewport_size.x - panel_width - 16.0), top)
	size = Vector2(panel_width, maxf(180.0, viewport_size.y - top - 16.0))


func _on_visibility_changed() -> void:
	if _host != null:
		_host._apply_responsive_layout()


func inspect_note(position: Dictionary) -> void:
	if position.is_empty():
		return
	_inspected_note = position.duplicate(true)
	_clear_visual_features("note")
	_tab = "note"
	_set_tab_selected()
	_show_note(_inspected_note)
	visible = true
	if _host != null:
		_host._stop_all_audio("study_note_inspection")


func route_for_playback() -> Array[Dictionary]:
	if route_enabled and _host != null:
		_route.clear()
		var positions: Array = _host.box_positions if _host.learning.topic == "scales" and _host.scale_view_mode != 2 else GuidedStudy.route(_host.learning, _host._visible_range)
		for position: Dictionary in positions:
			if _host.learning.layer == "roots" and not position.is_root: continue
			if _host.learning.layer == "chord" and not position.in_chord: continue
			_route.append(position)
		_host.board.route_positions = _route.duplicate(true)
		_host.board.queue_redraw()
	return _route.duplicate(true) if route_enabled else []


func playback_options() -> Dictionary:
	return {
		"loop_enabled": _loop_enabled,
		"pause_seconds": _pause_seconds,
		"drone_enabled": _drone_enabled,
	}


func end_study() -> void:
	_end_study(true)


func _end_study(restore_layer: bool) -> void:
	if restore_layer and active_lesson and not _lesson_original_layer.is_empty() and _host != null:
		_guard = true
		_host.settings.study_layer = _lesson_original_layer
		_host._select_layer(_lesson_original_layer)
		_guard = false
	active_lesson = false
	_lesson_steps.clear()
	_lesson_index = 0
	_lesson_original_layer = ""
	route_enabled = false
	_route.clear()
	if _host != null and _host.board != null:
		_host.board.comparison_roles.clear()
		_host.board.focus_intervals.clear()
		_host.board.highlighted_pitch_class = -1
		_host.board.route_positions.clear()
		_host.board.previous_shape.clear()
		_host.board.queue_redraw()


func localize() -> void:
	if _shell_title != null:
		_shell_title.text = _t("Изучать", "Explore")
	for tab_id: String in _tab_buttons:
		_tab_buttons[tab_id].text = _tab_text(tab_id)
	if visible:
		if _tab == "note" and not _inspected_note.is_empty():
			_show_note(_inspected_note)
		else:
			_rebuild_content()


func _build_shell() -> void:
	var margin := MarginContainer.new()
	_set_margins(margin, 16, 14, 16, 14)
	add_child(margin)
	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 10)
	margin.add_child(shell)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	shell.add_child(header)
	_shell_title = Label.new()
	_shell_title.text = _t("Изучать", "Explore")
	_shell_title.add_theme_font_size_override("font_size", 25)
	_shell_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_shell_title)
	var close := _button("×", 44)
	close.tooltip_text = _t("Закрыть", "Close")
	close.pressed.connect(func(): visible = false)
	header.add_child(close)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 2)
	shell.add_child(tabs)
	for tab_id in ["comparison", "lesson", "playback", "note"]:
		var button := _button(_tab_text(tab_id), 36)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_show_tab.bind(tab_id))
		_tab_buttons[tab_id] = button
		tabs.add_child(button)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)
	_set_tab_selected()


func _rebuild_content() -> void:
	if _content == null:
		return
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	match _tab:
		"lesson": _build_lesson()
		"playback": _build_playback()
		"note":
			if _inspected_note.is_empty(): _build_note_empty()
			else: _show_note(_inspected_note)
		_: _build_comparison()
	_set_tab_selected()


func _show_tab(tab_id: String) -> void:
	_tab = tab_id
	_rebuild_content()


func _set_tab_selected() -> void:
	for key: String in _tab_buttons:
		var button: Button = _tab_buttons[key]
		button.button_pressed = key == _tab
		button.theme_type_variation = "SegmentSelected" if key == _tab else "SegmentButton"


func _build_comparison() -> void:
	if _host == null:
		return
	var model: LearningModel = _host.learning
	if model.topic.to_lower() == "caged":
		_build_caged_connection(model)
		return
	if not model.topic.to_lower() in ["scales", "chords", "arpeggios"]:
		_add_text(_t("Сравнение недоступно для этого материала.", "Comparison is unavailable for this material."))
		return
	if _comparison_source == null:
		_comparison_source = _clone_model(model)
		_comparison_baseline = _snapshot_settings()
		_comparison_target_id = MaterialComparison.default_target_id(model)
	var current_source_id := _comparison_source.scale_id if _comparison_source.topic == "scales" else _comparison_source.chord_id
	_add_heading(_t("Сравнение A / B", "A / B comparison"))
	var target := OptionButton.new()
	target.name = "ComparisonTarget"
	target.fit_to_longest_item = false
	target.clip_text = true
	target.custom_minimum_size.y = 44
	var records: Array = _comparison_source.scale_records() if _comparison_source.topic == "scales" else _comparison_source.chord_records()
	if _comparison_source.topic == "scales":
		preload("res://scripts/ui/scale_menu.gd").populate(target, records, _language(), _comparison_target_id)
	else:
		for index in records.size():
			var record: Variant = records[index]
			var record_id := str(record.id)
			var names: Dictionary = record.names
			target.add_item(str(names.get(_language(), record_id)), index)
			target.set_item_metadata(index, record_id)
			if record_id == _comparison_target_id:
				target.select(index)
	target.item_selected.connect(func(index: int):
		if index >= 0 and index < target.item_count and not target.is_item_separator(index):
			_comparison_target_id = str(target.get_item_metadata(index))
			_comparison_showing_target = false
			_apply_comparison_display()
	)
	_content.add_child(target)
	var comparison: Dictionary = MaterialComparison.compare(_comparison_source, _comparison_target_id)
	if not comparison.valid:
		_add_text(str(comparison.error), Color("ffadad"))
		return
	_add_text("A: %s\nB: %s" % [comparison.source_name, comparison.target_name], Color("d7e8ff"))
	_add_text(_delta_text(comparison), Color("b9cbea"))
	var switch_button := _button(
		_t("Показать A", "Show A") if _comparison_showing_target else _t("Показать B", "Show B"), 42
	)
	switch_button.pressed.connect(func():
		_comparison_showing_target = not _comparison_showing_target
		_apply_comparison_display()
	)
	_content.add_child(switch_button)
	var reset := _button(_t("Сбросить сравнение", "Reset comparison"), 40)
	reset.pressed.connect(_reset_comparison)
	_content.add_child(reset)
	if current_source_id == _comparison_target_id:
		_add_text(_t("Выберите другой материал для различий.", "Choose another material to see differences."), Color("b9cbea"))
	else:
		_add_text(_t("Общее приглушено; + только в показанном, − только в другом.", "Common notes are subdued; + only in the displayed material, − only in the other one."), Color("8de8ff"))
	_apply_comparison_roles(comparison)


func _apply_comparison_display() -> void:
	if _host == null or _comparison_source == null:
		return
	_clear_visual_features("comparison")
	_guard = true
	if _comparison_showing_target:
		if _comparison_source.topic == "scales":
			_host.settings.scale_id = _comparison_target_id
		else:
			_host.settings.chord_id = _comparison_target_id
	else:
		_restore_comparison_material()
	_host._refresh_learning_view()
	_host._populate_scale_selector()
	_host._populate_chord_selector()
	_guard = false
	var comparison := MaterialComparison.compare(_comparison_source, _comparison_target_id)
	if comparison.valid:
		_apply_comparison_roles(comparison)
	_rebuild_content()


func _apply_comparison_roles(comparison: Dictionary) -> void:
	if _host == null or _host.board == null:
		return
	var roles := {}
	for position: Dictionary in comparison.source_positions:
		var interval := int(position.interval)
		var role := ""
		if comparison.common_intervals.has(interval): role = "common"
		elif comparison.removed_intervals.has(interval): role = "removed" if _comparison_showing_target else "added"
		elif comparison.added_intervals.has(interval): role = "added" if _comparison_showing_target else "removed"
		if not role.is_empty():
			roles[Vector2i(int(position.string_index), int(position.fret))] = role
	_host.board.comparison_roles = roles
	_host.board.focus_intervals.clear()
	_host.board.highlighted_pitch_class = -1
	_host.board.route_positions.clear()
	_host.board.queue_redraw()


func _reset_comparison() -> void:
	if _host == null:
		return
	_guard = true
	_restore_comparison_material()
	_host._refresh_learning_view()
	_host._populate_scale_selector()
	_host._populate_chord_selector()
	_guard = false
	_comparison_source = null
	_comparison_target_id = ""
	_comparison_baseline.clear()
	_comparison_showing_target = false
	end_study()
	visible = false


func _build_caged_connection(model: LearningModel) -> void:
	_add_heading(_t("Связь форм CAGED", "CAGED shape connection"))
	if not model.is_caged_compatible():
		_add_text(_t("Для этого строя CAGED недоступен: интервалы между струнами изменены.", "CAGED is unavailable for this tuning because the string intervals changed."), Color("ffc77a"))
		return
	_add_text(_t("Белая обводка показывает общие звуки; форма остаётся мажорной 1 · 3 · 5.", "The white outline marks common notes; every form keeps the major 1 · 3 · 5 chord."), Color("d7e8ff"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_content.add_child(row)
	for direction in [-1, 1]:
		var adjacent := CagedConnection.adjacent(model, direction)
		var button := _button("‹" if direction < 0 else "›", 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = adjacent.is_empty()
		button.tooltip_text = _t("Предыдущая форма", "Previous shape") if direction < 0 else _t("Следующая форма", "Next shape")
		button.pressed.connect(_move_caged.bind(adjacent))
		row.add_child(button)
	if not model.caged_positions().is_empty():
		_add_text(_t("Текущая форма: ", "Current shape: ") + model.shape.to_upper(), Color("b9cbea"))


func _move_caged(adjacent: Dictionary) -> void:
	if adjacent.is_empty() or _host == null:
		return
	_clear_visual_features("caged")
	var old_positions: Array[Dictionary] = _host.learning.caged_positions()
	_guard = true
	_host.settings.caged_shape = str(adjacent.shape)
	_host.learning.shape_fret_offset = int(adjacent.offset)
	_host._refresh_learning_view()
	_guard = false
	var next_positions: Array[Dictionary] = _host.learning.caged_positions()
	var visible := _transition_range(old_positions, next_positions, int(_host.settings.fret_count))
	_host._set_visible_range(visible)
	_host.board.show_shape_transition(old_positions)
	_rebuild_content()


func _build_lesson() -> void:
	if _host == null:
		return
	_add_heading(_t("Урок", "Lesson"))
	if not active_lesson:
		var begin := _button(_t("Начать урок", "Start lesson"), 44)
		begin.pressed.connect(_start_lesson)
		_content.add_child(begin)
		_add_text(_t("Шаги меняют только слой подсветки и не меняют выбранный материал.", "Steps only change the highlight layer; your selected material stays unchanged."), Color("b9cbea"))
		return
	if _lesson_steps.is_empty():
		_add_text(_t("Для этого материала нет шагов урока.", "There are no lesson steps for this material."), Color("ffc77a"))
		return
	var step: Dictionary = _lesson_steps[_lesson_index]
	_add_text("%d / %d" % [_lesson_index + 1, _lesson_steps.size()], Color("8de8ff"))
	_add_heading(str(step.title))
	_add_text(str(step.body), Color("d7e8ff"))
	var row := HBoxContainer.new()
	_content.add_child(row)
	var back := _button("‹", 40)
	back.disabled = _lesson_index == 0
	back.pressed.connect(_change_lesson_step.bind(-1))
	row.add_child(back)
	var next := _button("›", 40)
	next.disabled = _lesson_index >= _lesson_steps.size() - 1
	next.pressed.connect(_change_lesson_step.bind(1))
	row.add_child(next)
	var stop := _button(_t("Завершить урок", "End lesson"), 40)
	stop.pressed.connect(func(): end_study(); _rebuild_content())
	_content.add_child(stop)


func _start_lesson() -> void:
	if _host == null:
		return
	_clear_visual_features("lesson")
	_lesson_steps = GuidedStudy.steps(_host.learning)
	_lesson_index = 0
	_lesson_original_layer = str(_host.settings.study_layer)
	active_lesson = not _lesson_steps.is_empty()
	_apply_lesson_step()
	_rebuild_content()


func _change_lesson_step(delta: int) -> void:
	_lesson_index = clampi(_lesson_index + delta, 0, _lesson_steps.size() - 1)
	_apply_lesson_step()
	_rebuild_content()


func _apply_lesson_step() -> void:
	if not active_lesson or _host == null or _lesson_steps.is_empty():
		return
	var step: Dictionary = _lesson_steps[_lesson_index]
	_guard = true
	_host._select_layer(str(step.layer))
	_guard = false
	_host.board.focus_intervals = Array(step.highlight_intervals).duplicate()
	_host.board.comparison_roles.clear()
	_host.board.highlighted_pitch_class = -1
	_host.board.queue_redraw()
	if bool(step.listen):
		_host._play_current_material()


func _build_playback() -> void:
	_add_heading(_t("Воспроизведение", "Playback"))
	var tempo := SpinBox.new()
	tempo.name = "TempoSpin"
	tempo.min_value = 30
	tempo.max_value = 240
	tempo.step = 1
	tempo.value = float(_host.settings.tempo_bpm) if _host != null else 120.0
	tempo.custom_minimum_size.y = 42
	tempo.tooltip_text = _t("Темп", "Tempo")
	tempo.value_changed.connect(func(value: float):
		if _host != null: _host._on_tempo_changed(value)
	)
	_content.add_child(_labeled(_t("Темп", "Tempo"), tempo))
	var loop := CheckButton.new()
	loop.name = "LoopToggle"
	loop.text = _t("Повторять", "Loop")
	loop.button_pressed = _loop_enabled
	loop.toggled.connect(func(value: bool):
		_loop_enabled = value
		_host._stop_all_audio("loop_changed")
	)
	_content.add_child(loop)
	var pause := SpinBox.new()
	pause.name = "PauseSpin"
	pause.min_value = 0
	pause.max_value = 5
	pause.step = 0.1
	pause.value = _pause_seconds
	pause.custom_minimum_size.y = 42
	pause.value_changed.connect(func(value: float):
		_pause_seconds = value
		_host._stop_all_audio("pause_changed")
	)
	_content.add_child(_labeled(_t("Пауза между повторами, сек", "Pause between loops, sec"), pause))
	var drone := CheckButton.new()
	drone.name = "DroneToggle"
	drone.text = _t("Басовая тоника", "Bass tonic")
	drone.button_pressed = _drone_enabled
	drone.toggled.connect(func(value: bool):
		_drone_enabled = value
		_host._stop_all_audio("drone_changed")
	)
	_content.add_child(drone)
	var route := _button(_t("Показать маршрут", "Show route"), 42)
	route.button_pressed = route_enabled
	route.pressed.connect(_toggle_route)
	_content.add_child(route)
	_add_text(_t("Басовая тоника звучит во время проигрывания. Для аккорда включите маршрут.", "The bass tonic plays during playback. Enable a route for chords."), Color("b9cbea"))
	_add_text(_t("Шаг / палец. 0 — открытая струна; аппликатура примерная.", "Step / finger. 0 is an open string; fingering is a suggestion."), Color("b9cbea"))


func _toggle_route() -> void:
	if _host == null:
		return
	_host._stop_all_audio("route_changed")
	_clear_visual_features("route")
	route_enabled = not route_enabled
	_route.clear()
	if route_enabled:
		route_for_playback()
	_host.board.route_positions = _route.duplicate(true)
	_host.board.queue_redraw()
	_rebuild_content()


func _build_note_empty() -> void:
	_add_heading(_t("Нота", "Note"))
	_add_text(_t("Удержите ноту на грифе, чтобы открыть её свойства.", "Long-press a note on the fretboard to inspect it."), Color("b9cbea"))


func _show_note(position: Dictionary) -> void:
	if _content == null:
		return
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_add_heading(_t("Нота", "Note"))
	var role := _note_role(position)
	_add_text("%s\nMIDI %d · %s\n%s" % [str(position.note), int(position.midi_note), _octave_text(position), role], Color("d7e8ff"))
	var all_notes := _button(_t("Все такие ноты на грифе", "All matching notes on fretboard"), 42)
	all_notes.pressed.connect(func():
		if _host != null:
			_host._select_scale_view(2)
			_host.board.highlighted_pitch_class = int(position.pitch_class)
			_host._set_visible_range(Vector2i(0, int(_host.settings.fret_count)))
			_host.board.queue_redraw()
			visible = false
	)
	_content.add_child(all_notes)
	var clear := _button(_t("Очистить подсветку", "Clear highlight"), 40)
	clear.pressed.connect(func():
		if _host != null:
			_host.board.highlighted_pitch_class = -1
			_host.board.queue_redraw()
	)
	_content.add_child(clear)


func _clear_visual_features(keep: String) -> void:
	if active_lesson and keep != "lesson":
		_end_study(true)
	if keep != "lesson":
		active_lesson = false
		_lesson_steps.clear()
	if keep != "route":
		route_enabled = false
		_route.clear()
	if _host != null and _host.board != null:
		if keep != "comparison": _host.board.comparison_roles.clear()
		if keep != "lesson": _host.board.focus_intervals.clear()
		if keep != "note": _host.board.highlighted_pitch_class = -1
		if keep != "route": _host.board.route_positions.clear()
		_host.board.queue_redraw()


func _clone_model(source: LearningModel) -> LearningModel:
	var copy := Learning.new()
	copy.tonic = source.tonic
	copy.scale_id = source.scale_id
	copy.topic = source.topic
	copy.shape = source.shape
	copy.layer = source.layer
	copy.tuning = source.tuning.duplicate() if source.tuning is Array or source.tuning is PackedInt32Array else source.tuning
	copy.chord_id = source.chord_id
	copy.spelling = source.spelling
	copy.language = source.language
	copy.fret_count = source.fret_count
	copy.scales = source.scales.duplicate(true)
	copy.chords = source.chords.duplicate()
	return copy


func _snapshot_settings() -> Dictionary:
	return {
		"scale_id": _host.settings.scale_id,
		"chord_id": _host.settings.chord_id,
		"caged_shape": _host.settings.caged_shape,
	}


func _restore_comparison_material() -> void:
	if _comparison_baseline.is_empty() or _host == null:
		return
	_host.settings.scale_id = _comparison_baseline.scale_id
	_host.settings.chord_id = _comparison_baseline.chord_id
	_host.settings.caged_shape = _comparison_baseline.caged_shape


func _transition_range(old_positions: Array[Dictionary], next_positions: Array[Dictionary], fret_count: int) -> Vector2i:
	var all_positions: Array[Dictionary] = old_positions + next_positions
	if all_positions.is_empty():
		return Vector2i(0, mini(12, fret_count))
	var minimum := fret_count
	var maximum := 0
	for position: Dictionary in all_positions:
		minimum = mini(minimum, int(position.fret))
		maximum = maxi(maximum, int(position.fret))
	if maximum - minimum <= 12:
		return Vector2i(maxi(0, minimum - 2), mini(fret_count, maximum + 2))
	minimum = fret_count
	maximum = 0
	for position: Dictionary in next_positions:
		minimum = mini(minimum, int(position.fret))
		maximum = maxi(maximum, int(position.fret))
	return Vector2i(maxi(0, minimum - 2), mini(fret_count, maximum + 2))


func _delta_text(comparison: Dictionary) -> String:
	return "%s: %s\n%s: %s\n%s: %s" % [
		_t("Общие ступени", "Common degrees"), _degree_list(comparison.common_intervals),
		_t("Только A", "Only A"), _degree_list(comparison.removed_intervals),
		_t("Только B", "Only B"), _degree_list(comparison.added_intervals),
	]


func _degree_list(intervals: Array) -> String:
	var names := ["1", "♭2", "2", "♭3", "3", "4", "♭5", "5", "♭6", "6", "♭7", "7"]
	var result := PackedStringArray()
	for interval in intervals:
		result.append(names[int(interval) % 12])
	return " · ".join(result) if not result.is_empty() else "—"


func _note_role(position: Dictionary) -> String:
	var labels: Array[String] = []
	if bool(position.is_root): labels.append(_t("тоника", "root"))
	if int(position.interval) in [3, 4]: labels.append(_t("терция", "third"))
	if int(position.interval) == 7: labels.append(_t("квинта", "fifth"))
	if bool(position.in_chord): labels.append(_t("звук аккорда", "chord tone"))
	if bool(position.in_scale): labels.append(_t("ступень гаммы", "scale tone"))
	return "%s: %s" % [_t("Степень", "Degree"), str(position.degree)] + "\n" + ", ".join(labels)


func _octave_text(position: Dictionary) -> String:
	return _t("октава ", "octave ") + str(position.octave)


func _add_heading(text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 20)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(label)


func _add_text(text_value: String, color: Color = Color("d7e8ff")) -> void:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	_content.add_child(label)


func _labeled(label_text: String, control: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	box.add_child(label)
	box.add_child(control)
	return box


func _button(text_value: String, height: int) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = height
	button.theme_type_variation = "SegmentButton"
	return button


func _set_margins(container: MarginContainer, left: int, top: int, right: int, bottom: int) -> void:
	container.add_theme_constant_override("margin_left", left)
	container.add_theme_constant_override("margin_top", top)
	container.add_theme_constant_override("margin_right", right)
	container.add_theme_constant_override("margin_bottom", bottom)


func _tab_text(tab_id: String) -> String:
	match tab_id:
		"lesson": return _t("Урок", "Lesson")
		"playback": return _t("Игра", "Playback")
		"note": return _t("Нота", "Note")
		_: return _t("Сравнить", "Compare")


func _t(ru: String, en: String) -> String:
	return en if _language() == "en" else ru


func _language() -> String:
	return str(_host.language) if _host != null else "ru"


func _check_value(node_name: String) -> bool:
	var node := _content.get_node_or_null(NodePath(node_name)) as CheckButton
	return node.button_pressed if node != null else false


func _spin_value(node_name: String) -> float:
	var node := _content.get_node_or_null(NodePath(node_name)) as SpinBox
	return node.value if node != null else 0.0
