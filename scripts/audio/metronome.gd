class_name PracticeMetronome
extends Node

signal beat(beat_number: int, accented: bool)

var tempo_bpm := 120
var beats_per_bar := 4
var subdivision := 1
var accent_enabled := true
var volume := 0.5
var running := false

var _next_tick_usec := 0.0
var _tick_index := 0
var _players: Array[AudioStreamPlayer] = []
var _streams: Array[AudioStreamWAV] = []
var _player_index := 0


func _ready() -> void:
	_streams = [_make_click(1100.0, 0.75), _make_click(760.0, 0.55), _make_click(540.0, 0.32)]
	for index in 4:
		var player := AudioStreamPlayer.new()
		player.name = "Click%d" % index
		add_child(player)
		_players.append(player)
	set_process(false)


func start() -> void:
	_tick_index = 0
	_next_tick_usec = float(Time.get_ticks_usec())
	running = true
	set_process(true)
	_process(0.0)


func stop() -> void:
	running = false
	set_process(false)
	for player in _players:
		player.stop()


func configure(bpm: int, bar_beats: int, divisions: int, accent: bool, gain: float) -> void:
	tempo_bpm = clampi(bpm, 30, 240)
	beats_per_bar = clampi(bar_beats, 1, 12)
	subdivision = 1 if divisions not in [1, 2, 3, 4] else divisions
	accent_enabled = accent
	volume = clampf(gain, 0.0, 1.0)
	if running:
		start()


func _process(_delta: float) -> void:
	if not running:
		return
	var now := float(Time.get_ticks_usec())
	var interval := 60000000.0 / float(tempo_bpm * subdivision)
	while now >= _next_tick_usec:
		var main_beat := _tick_index % subdivision == 0
		var beat_number := int(_tick_index / subdivision) % beats_per_bar + 1
		var accented := main_beat and beat_number == 1 and accent_enabled
		var player := _players[_player_index]
		_player_index = (_player_index + 1) % _players.size()
		player.stream = _streams[0 if accented else (1 if main_beat else 2)]
		player.volume_linear = volume
		player.play()
		if main_beat:
			beat.emit(beat_number, accented)
		_tick_index += 1
		_next_tick_usec += interval
		if _next_tick_usec < now - interval:
			_next_tick_usec = now + interval
			break


func _make_click(frequency: float, gain: float) -> AudioStreamWAV:
	var rate := 22050
	var sample_count := int(rate * 0.035)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var seconds := float(index) / float(rate)
		var envelope := exp(-seconds * 115.0)
		var sample := int(clampf(sin(TAU * frequency * seconds) * envelope * gain, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(index * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream
