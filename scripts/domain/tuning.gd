class_name GuitarTuning
extends RefCounted

const STANDARD_NAME := "Standard (E A D G B E)"
const STANDARD_OPEN_MIDI: PackedInt32Array = [40, 45, 50, 55, 59, 64]

var id: String
var name_key: String
var display_name: String
var open_string_midi: PackedInt32Array


func _init(
		name_value: String = STANDARD_NAME,
		notes_value: PackedInt32Array = STANDARD_OPEN_MIDI,
		id_value: String = "standard",
		name_key_value: String = "tuning.standard"
) -> void:
	id = id_value
	name_key = name_key_value
	display_name = name_value
	open_string_midi = notes_value.duplicate()
	var errors := validation_errors(_to_array(open_string_midi))
	assert(errors.is_empty(), "Invalid tuning: %s" % "; ".join(errors))


static func validation_errors(raw: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	if raw.is_empty():
		errors.append("A tuning needs at least one string.")
		return errors
	for value in raw:
		if not value is int:
			errors.append("Open-string MIDI values must be integers.")
			continue
		var midi_note: int = value
		if midi_note < 0 or midi_note > 127:
			errors.append("Open-string MIDI %d must be between 0 and 127." % midi_note)
	return errors


static func from_raw(
		name_value: String,
		raw_notes: Array,
		id_value: String = "",
		name_key_value: String = ""
) -> GuitarTuning:
	var errors := validation_errors(raw_notes)
	assert(errors.is_empty(), "Invalid tuning: %s" % "; ".join(errors))
	var notes := PackedInt32Array()
	for value in raw_notes:
		notes.append(value)
	return GuitarTuning.new(name_value, notes, id_value, name_key_value)


func midi_at(string_index: int, fret: int) -> int:
	assert(string_index >= 0 and string_index < open_string_midi.size())
	assert(fret >= 0)
	return open_string_midi[string_index] + fret


static func _to_array(notes: PackedInt32Array) -> Array:
	var result: Array = []
	for note in notes:
		result.append(note)
	return result
