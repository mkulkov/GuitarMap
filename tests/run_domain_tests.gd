extends SceneTree

const Tuning := preload("res://scripts/domain/tuning.gd")
const Theory := preload("res://scripts/domain/music_theory.gd")
const PitchType := preload("res://scripts/domain/pitch.gd")
const ScaleType := preload("res://scripts/domain/scale_definition.gd")
const Spelling := preload("res://scripts/domain/note_spelling.gd")
const Position := preload("res://scripts/domain/fret_position.gd")


func _init() -> void:
	var tuning := Tuning.new()
	assert(tuning.midi_at(0, 0) == 40)
	assert(tuning.midi_at(0, 5) == 45)
	assert(tuning.midi_at(5, 5) == 69)
	assert(Theory.scientific_name(40) == "E2")
	assert(Theory.scientific_name(69) == "A4")
	for midi in range(-24, 152):
		var pitch := PitchType.new(midi)
		assert(pitch.pitch_class == Theory.pitch_class(midi))
		assert(pitch.octave == Theory.octave(midi))
		assert(pitch.transposed(12).midi_note == midi + 12)
		assert(Theory.pitch_class(midi) >= 0 and Theory.pitch_class(midi) < 12)
		assert(Theory.pitch_class(midi + 12) == Theory.pitch_class(midi))
		assert(Theory.octave(midi + 12) == Theory.octave(midi) + 1)
	for boundary in [[-1, -2], [0, -1], [11, -1], [12, 0], [59, 3], [60, 4]]:
		assert(Theory.octave(boundary[0]) == boundary[1])
	for notes in [
		[40, 45, 50, 55, 59, 64],
		[38, 45, 50, 55, 59, 64],
		[35, 40, 45, 50, 55, 59, 64],
		[60],
	]:
		var alternate := Tuning.new("test", PackedInt32Array(notes))
		for string_index in notes.size():
			for fret in range(25):
				assert(alternate.midi_at(string_index, fret) == notes[string_index] + fret)
				var position := Position.new(alternate, string_index, fret, 9)
				assert(position.midi_note == notes[string_index] + fret)
				assert(position.interval_from_tonic == posmod(position.pitch_class - 9, 12))
				assert(alternate.midi_at(string_index, fret + 12) == alternate.midi_at(string_index, fret) + 12)
	assert(is_equal_approx(PitchType.new(69).frequency(), 440.0))
	assert(is_equal_approx(PitchType.new(81).frequency(), 880.0))
	assert(Interval.new(3).degree_label == "b3")
	for invalid in [[], [0, 0], [0, 7, 3], [1, 3], [0, -1], [0, 12], [0, 1.5], [0, "3"]]:
		assert(not ScaleType.validation_errors(invalid).is_empty())
	for invalid in [[], [-1], [128], [40.5], ["40"]]:
		assert(not Tuning.validation_errors(invalid).is_empty())
	assert(Tuning.validation_errors([40, 45, 50, 55, 59, 64]).is_empty())
	var scale := ScaleType.new("test", "scale.test", "test", [0, 2, 4, 5, 7, 9, 11])
	for tonic in range(12):
		for midi in range(128):
			assert(scale.contains_interval(posmod(midi - tonic, 12)) == [0, 2, 4, 5, 7, 9, 11].has(posmod(midi - tonic, 12)))
	var sharps := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var flats := ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
	for pc in range(12):
		assert(Spelling.name_for(60 + pc, "sharp") == sharps[pc])
		assert(Spelling.name_for(60 + pc, "flat") == flats[pc])
	assert(Spelling.name_for(70, "context", 5, "4") == "Bb")
	assert(Spelling.name_for(65, "context", 6, "7") == "E#")
	print("Domain tests passed: tuning, pitch class, octave, scientific note name.")
	quit()
