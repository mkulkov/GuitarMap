class_name FretPosition
extends RefCounted

var tuning: GuitarTuning
var string_index: int
var fret: int
var tonic_pitch_class: int
var midi_note: int:
	get:
		return tuning.midi_at(string_index, fret)
var pitch_class: int:
	get:
		return posmod(midi_note, 12)
var octave: int:
	get:
		return floori(float(midi_note) / 12.0) - 1
var interval_from_tonic: int:
	get:
		return posmod(pitch_class - tonic_pitch_class, 12)


func _init(
		tuning_value: GuitarTuning,
		string_index_value: int,
		fret_value: int,
		tonic_pitch_class_value: int = 0
) -> void:
	assert(tuning_value != null, "A fret position needs a tuning.")
	assert(string_index_value >= 0 and string_index_value < tuning_value.open_string_midi.size())
	assert(fret_value >= 0, "Fret must be zero or greater.")
	tuning = tuning_value
	string_index = string_index_value
	fret = fret_value
	tonic_pitch_class = posmod(tonic_pitch_class_value, 12)
