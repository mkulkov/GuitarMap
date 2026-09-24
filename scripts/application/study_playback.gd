class_name StudyPlayback
extends Node

## Repeats scale and arpeggio material through the existing sequence player.
## Chords remain the caller's direct responsibility because their playback is
## intentionally simultaneous rather than a stepped pass.

signal finished

const DRONE_OWNER_ID := -9000
const DRONE_VELOCITY := 0.60
const DRONE_PULSE_OWNER_BASE := -9100
const DRONE_PULSE_VELOCITY := 0.80

var _sequence: NoteSequencePlayer
var _audio: GuitarAudioEngine
var _pause_timer: Timer
var _notes: Array = []
var _step_seconds := 0.22
var _gate_seconds := 0.18
var _velocity := 0.75
var _loop_enabled := false
var _pause_seconds := 0.0
var _drone_midi := -1
var _drone_handle := -1
var _drone_pulse_handles: Array[int] = []
var _active := false
var _pass_running := false
var _launching_pass := false
var _generation := 0


func _ready() -> void:
	_pause_timer = Timer.new()
	_pause_timer.name = "StudyPassPause"
	_pause_timer.one_shot = true
	add_child(_pause_timer)
	_pause_timer.timeout.connect(_on_pause_timeout)


func configure(sequence: NoteSequencePlayer, audio: GuitarAudioEngine) -> void:
	if _sequence != null and _sequence.playback_finished.is_connected(_on_sequence_finished):
		_sequence.playback_finished.disconnect(_on_sequence_finished)
	if _sequence != null and _sequence.note_started.is_connected(_on_sequence_note_started):
		_sequence.note_started.disconnect(_on_sequence_note_started)
	_sequence = sequence
	_audio = audio
	if _sequence != null:
		_sequence.playback_finished.connect(_on_sequence_finished)
		_sequence.note_started.connect(_on_sequence_note_started)


func start(notes: Array, step: float, gate: float, velocity: float, loop_enabled: bool, pause_seconds: float, drone_midi: int = -1) -> void:
	stop()
	if _sequence == null or _audio == null or notes.is_empty():
		return
	_notes = notes.duplicate()
	_step_seconds = maxf(step, 0.01)
	_gate_seconds = maxf(gate, 0.01)
	_velocity = clampf(velocity, 0.0, 1.0)
	_loop_enabled = loop_enabled
	_pause_seconds = maxf(pause_seconds, 0.0)
	_drone_midi = drone_midi
	_active = true
	if _drone_midi >= 0:
		_start_drone()
	_start_pass()


func stop() -> void:
	_generation += 1
	_active = false
	_pass_running = false
	_launching_pass = false
	if _pause_timer != null:
		_pause_timer.stop()
	if _sequence != null:
		_sequence.stop()
	_stop_drone()


func is_active() -> bool:
	return _active


func _start_pass() -> void:
	if not _active or _sequence == null:
		return
	_launching_pass = true
	_sequence.play_arpeggio(_notes, _step_seconds, _gate_seconds, _velocity)
	_launching_pass = false
	_pass_running = true


func _on_sequence_finished() -> void:
	# NoteSequencePlayer emits playback_finished for its defensive stop() at the
	# beginning of every pass. Only the completion after a launched pass matters.
	if not _active or _launching_pass or not _pass_running:
		return
	_pass_running = false
	if not _loop_enabled:
		_active = false
		_stop_drone()
		finished.emit()
		return
	if _pause_seconds <= 0.0:
		_start_pass()
		return
	_pause_timer.start(_pause_seconds)


func _on_pause_timeout() -> void:
	if _active:
		_start_pass()


func _process(_delta: float) -> void:
	_drone_pulse_handles = _drone_pulse_handles.filter(func(handle: int) -> bool: return _audio != null and not _audio.voice_snapshot(handle).is_empty())
	if _active and _drone_midi >= 0 and _drone_handle >= 0 and _audio != null:
		if _audio.voice_snapshot(_drone_handle).is_empty():
			_start_drone()


func _on_sequence_note_started(index: int, _midi_note: int) -> void:
	if not _active or _audio == null or _drone_midi < 0:
		return
	var handle := _audio.note_on(_drone_midi, DRONE_PULSE_VELOCITY, DRONE_PULSE_OWNER_BASE - index)
	if handle >= 0:
		_drone_pulse_handles.append(handle)


func _start_drone() -> void:
	if _audio == null or _drone_midi < 0:
		return
	if _drone_handle >= 0 and not _audio.voice_snapshot(_drone_handle).is_empty():
		return
	_drone_handle = _audio.note_on(_drone_midi, DRONE_VELOCITY, DRONE_OWNER_ID, true)


func _stop_drone() -> void:
	if _audio != null and _drone_handle >= 0:
		_audio.note_off(_drone_handle)
	if _audio != null:
		for handle: int in _drone_pulse_handles:
			_audio.note_off(handle)
	_drone_handle = -1
	_drone_pulse_handles.clear()


func _exit_tree() -> void:
	stop()
