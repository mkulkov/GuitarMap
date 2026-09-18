class_name StringSoundLab
extends Control

## Isolated five-note sound lab. The JSON in `preset_output` is the hand-off
## contract for applying a selected string sound to the main audio engine.

const NOTE_OPTIONS: Array[Dictionary] = [
	{"name": "E3", "midi": 52},
	{"name": "A3", "midi": 57},
	{"name": "D4", "midi": 62},
	{"name": "G4", "midi": 67},
	{"name": "B4", "midi": 71},
]
const MIX_RATE := 44100
const DURATION_SECONDS := 2.4

var parameters := {
	"attack": 0.55,
	"brightness": 0.58,
	"sustain": 0.62,
	"body": 0.48,
	"drive": 0.0,
	"volume": 0.72,
}

var preset_output: TextEdit
var status_label: Label
var _sliders: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_build_ui()
	for index in NOTE_OPTIONS.size():
		var player := AudioStreamPlayer.new()
		player.name = "PreviewVoice%d" % index
		add_child(player)
		_players.append(player)
	_refresh_preset_output()


func preset_dictionary() -> Dictionary:
	return {
		"schema": "guitarmap.string_sound_lab.v1",
		"parameters": parameters.duplicate(true),
	}


func play_note(note_index: int) -> void:
	if note_index < 0 or note_index >= NOTE_OPTIONS.size() or _players.is_empty():
		return
	var option: Dictionary = NOTE_OPTIONS[note_index]
	var player := _players[note_index]
	player.stream = _stream_for(int(option.midi))
	player.volume_db = linear_to_db(maxf(float(parameters.volume), 0.001))
	player.play()
	status_label.text = "Звучит %s. Настройте регуляторы и нажмите «Копировать JSON»." % option.name


func _exit_tree() -> void:
	# AudioStreamPlayer.stop() alone can leave the backend playback holding the
	# generated WAV until process shutdown. Detach every runtime-created stream
	# while the players are still valid so closing the lab releases both objects.
	for player in _players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_players.clear()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("07131e")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "Лаборатория звучания струн"
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)
	var hint := Label.new()
	hint.text = "Пять нот для быстрой настройки атаки, затухания и окраски. Основное приложение не меняется, пока вы не выберете пресет."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(hint)
	var notes := HFlowContainer.new()
	notes.add_theme_constant_override("h_separation", 10)
	notes.add_theme_constant_override("v_separation", 10)
	layout.add_child(notes)
	for index in NOTE_OPTIONS.size():
		var option: Dictionary = NOTE_OPTIONS[index]
		var button := Button.new()
		button.text = "%s\nMIDI %d" % [option.name, option.midi]
		button.custom_minimum_size = Vector2(112, 62)
		button.pressed.connect(play_note.bind(index))
		notes.add_child(button)
	var controls := GridContainer.new()
	controls.columns = 2
	controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("h_separation", 18)
	controls.add_theme_constant_override("v_separation", 8)
	layout.add_child(controls)
	_add_parameter(controls, "attack", "Атака медиатора", "Шум и резкость первого касания")
	_add_parameter(controls, "brightness", "Яркость", "Высокие гармоники струны")
	_add_parameter(controls, "sustain", "Сустейн", "Длительность затухания")
	_add_parameter(controls, "body", "Корпус", "Низко-средний резонанс")
	_add_parameter(controls, "drive", "Перегруз", "Мягкая сатурация звукоснимателя")
	_add_parameter(controls, "volume", "Громкость", "Уровень предпрослушивания")
	var export_title := Label.new()
	export_title.text = "Пресет для переноса в основное приложение"
	export_title.add_theme_font_size_override("font_size", 18)
	layout.add_child(export_title)
	preset_output = TextEdit.new()
	preset_output.editable = false
	preset_output.custom_minimum_size = Vector2(0, 105)
	preset_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(preset_output)
	var copy_button := Button.new()
	copy_button.text = "Копировать JSON"
	copy_button.pressed.connect(_copy_preset)
	layout.add_child(copy_button)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status_label)


func _add_parameter(parent: GridContainer, key: String, title: String, tooltip: String) -> void:
	var label := Label.new()
	label.text = title
	label.tooltip_text = tooltip
	parent.add_child(label)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = float(parameters[key])
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_set_parameter.bind(key))
	row.add_child(slider)
	var value := Label.new()
	value.name = "Value"
	value.custom_minimum_size.x = 42
	value.text = "%.2f" % slider.value
	row.add_child(value)
	_sliders[key] = {"slider": slider, "value": value}
	parent.add_child(row)


func _set_parameter(value: float, key: String) -> void:
	parameters[key] = snappedf(value, 0.01)
	var controls: Dictionary = _sliders[key]
	controls.value.text = "%.2f" % float(parameters[key])
	_refresh_preset_output()


func _refresh_preset_output() -> void:
	if preset_output != null:
		preset_output.text = JSON.stringify(preset_dictionary(), "  ")


func _copy_preset() -> void:
	DisplayServer.clipboard_set(JSON.stringify(preset_dictionary(), "  "))
	status_label.text = "JSON скопирован. Сохраните его: по нему выбранные значения будут перенесены в основной синтезатор."


func _stream_for(midi_note: int) -> AudioStreamWAV:
	var frequency := 440.0 * pow(2.0, (float(midi_note) - 69.0) / 12.0)
	var frame_count := int(MIX_RATE * DURATION_SECONDS)
	var delay_length := maxi(2, roundi(float(MIX_RATE) / frequency))
	var delay_line := PackedFloat32Array()
	delay_line.resize(delay_length)
	var random_state := 1459 + midi_note * 7919
	for index in delay_length:
		random_state = _next_noise_state(random_state)
		var noise := float(random_state % 65536) / 32768.0 - 1.0
		delay_line[index] = noise * lerpf(0.45, 1.0, float(parameters.attack))
	var damping := lerpf(0.9920, 0.99945, float(parameters.sustain))
	var brightness := lerpf(0.25, 0.92, float(parameters.brightness))
	var pcm := PackedByteArray()
	pcm.resize(frame_count * 2)
	var cursor := 0
	var previous := 0.0
	for frame in frame_count:
		var next_cursor := (cursor + 1) % delay_length
		var raw := delay_line[cursor]
		var smoothed := lerpf((raw + delay_line[next_cursor]) * 0.5, raw, brightness) * damping
		delay_line[cursor] = smoothed
		var time := float(frame) / MIX_RATE
		var body := sin(TAU * frequency * time) * 0.16 + sin(TAU * frequency * 0.5 * time) * 0.07
		var sample := raw * 0.88 + body * float(parameters.body) * exp(-time * 1.8)
		var drive := float(parameters.drive) * 5.5
		if drive > 0.0:
			sample = sample * (1.0 - float(parameters.drive)) + (sample * drive) / (1.0 + absf(sample * drive)) * float(parameters.drive)
		var attack_noise := 0.0
		if frame < 850:
			random_state = _next_noise_state(random_state)
			attack_noise = (float(random_state % 65536) / 32768.0 - 1.0) * float(parameters.attack) * exp(-float(frame) / 180.0)
		sample = clampf((sample + attack_noise * 0.22) * 0.28, -0.85, 0.85)
		pcm.encode_s16(frame * 2, roundi(sample * 32767.0))
		previous = raw
		cursor = next_cursor
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = pcm
	return stream


func _next_noise_state(value: int) -> int:
	return int((int(value) * 1103515245 + 12345) & 0x7fffffff)
