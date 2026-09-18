class_name Pitch
extends RefCounted

const A4_MIDI := 69
const A4_FREQUENCY := 440.0

var midi_note: int
var pitch_class: int:
	get:
		return posmod(midi_note, 12)
var octave: int:
	get:
		return floori(float(midi_note) / 12.0) - 1


func _init(midi_note_value: int) -> void:
	midi_note = midi_note_value


func frequency() -> float:
	return A4_FREQUENCY * pow(2.0, float(midi_note - A4_MIDI) / 12.0)


func transposed(semitones: int) -> Pitch:
	return Pitch.new(midi_note + semitones)
