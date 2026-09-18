class_name NoteSequencePlayer
extends Node

signal note_started(index: int, midi_note: int)
signal note_released(index: int, midi_note: int)
signal playback_finished

const OWNER_BASE := -10000

var _audio_engine: Object
var _handles: Array[int] = []
var _generation := 0


func configure(audio_engine: Object) -> void:
	_audio_engine = audio_engine


func play_chord(midi_notes: Array, duration: float = 0.7, velocity: float = 0.75) -> void:
	stop()
	var generation := _generation
	for index in mini(midi_notes.size(), GuitarAudioEngine.CAPACITY):
		var midi_note := int(midi_notes[index])
		var handle := int(_audio_engine.note_on(midi_note, velocity, OWNER_BASE - index))
		if handle >= 0:
			_handles.append(handle)
			note_started.emit(index, midi_note)
	await get_tree().create_timer(maxf(duration, 0.01)).timeout
	if generation != _generation:
		return
	_release_owned()
	playback_finished.emit()


func play_arpeggio(midi_notes: Array, step_seconds: float = 0.22, gate_seconds: float = 0.18, velocity: float = 0.75) -> void:
	stop()
	var generation := _generation
	for index in midi_notes.size():
		if generation != _generation:
			return
		var midi_note := int(midi_notes[index])
		var handle := int(_audio_engine.note_on(midi_note, velocity, OWNER_BASE - index))
		if handle >= 0:
			_handles.append(handle)
			note_started.emit(index, midi_note)
		await get_tree().create_timer(maxf(gate_seconds, 0.01)).timeout
		if generation != _generation:
			return
		if handle >= 0:
			_audio_engine.note_off(handle)
			_handles.erase(handle)
			note_released.emit(index, midi_note)
		var rest := maxf(0.0, step_seconds - gate_seconds)
		if rest > 0.0:
			await get_tree().create_timer(rest).timeout
	_release_owned()
	if generation == _generation:
		playback_finished.emit()


func stop() -> void:
	_generation += 1
	_release_owned()
	playback_finished.emit()


func is_playing() -> bool:
	return not _handles.is_empty()


func _release_owned() -> void:
	if _audio_engine != null:
		for handle in _handles:
			_audio_engine.note_off(handle)
	_handles.clear()


func _exit_tree() -> void:
	stop()
