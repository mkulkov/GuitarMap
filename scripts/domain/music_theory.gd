class_name MusicTheory
extends RefCounted

const NOTE_NAMES_SHARP: PackedStringArray = [
	"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
]


static func pitch_class(midi_note: int) -> int:
	return posmod(midi_note, 12)


static func note_name(midi_note: int) -> String:
	return NOTE_NAMES_SHARP[pitch_class(midi_note)]


static func octave(midi_note: int) -> int:
	return floori(float(midi_note) / 12.0) - 1


static func scientific_name(midi_note: int) -> String:
	return "%s%d" % [note_name(midi_note), octave(midi_note)]

