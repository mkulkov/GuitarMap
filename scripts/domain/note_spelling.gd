class_name NoteSpelling
extends RefCounted

const SHARP_NAMES: PackedStringArray = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
const FLAT_NAMES: PackedStringArray = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
const LETTERS: PackedStringArray = ["C", "D", "E", "F", "G", "A", "B"]
const NATURAL_PITCH_CLASSES: PackedInt32Array = [0, 2, 4, 5, 7, 9, 11]


static func name_for(
		midi_note: int,
		preference: String = "sharp",
		tonic_pitch_class: int = 0,
		degree_label: String = ""
) -> String:
	var pitch_class := posmod(midi_note, 12)
	if degree_label.is_empty():
		return _names_for(preference)[pitch_class]

	var degree_number := _degree_number(degree_label)
	if degree_number < 1 or degree_number > 7:
		return _names_for(preference)[pitch_class]
	var tonic_letter_index := _letter_index(_names_for(preference)[posmod(tonic_pitch_class, 12)])
	var letter_index := posmod(tonic_letter_index + degree_number - 1, LETTERS.size())
	return _with_accidental(LETTERS[letter_index], NATURAL_PITCH_CLASSES[letter_index], pitch_class)


static func _names_for(preference: String) -> PackedStringArray:
	return FLAT_NAMES if preference.to_lower() == "flat" else SHARP_NAMES


static func _degree_number(degree_label: String) -> int:
	var digits := ""
	for character in degree_label:
		if character >= "0" and character <= "9":
			digits += character
	return int(digits)


static func _letter_index(name: String) -> int:
	return LETTERS.find(name.left(1))


static func _with_accidental(letter: String, natural_pitch_class: int, target_pitch_class: int) -> String:
	match posmod(target_pitch_class - natural_pitch_class, 12):
		0:
			return letter
		1:
			return letter + "#"
		2:
			return letter + "##"
		10:
			return letter + "bb"
		11:
			return letter + "b"
		_:
			return letter
