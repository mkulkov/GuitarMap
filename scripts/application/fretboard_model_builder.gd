class_name FretboardModelBuilder
extends RefCounted

static func build(tuning: GuitarTuning, fret_count: int, tonic: int, scale: ScaleDefinition, spelling: String) -> Array[Dictionary]:
	assert(fret_count >= 0 and fret_count <= 48)
	var result: Array[Dictionary] = []
	for string_index in tuning.open_string_midi.size():
		for fret in range(fret_count + 1):
			var position := FretPosition.new(tuning, string_index, fret, tonic)
			var interval := position.interval_from_tonic
			if not scale.contains_interval(interval):
				continue
			var degree := scale.degree_labels[scale.intervals.find(interval)]
			var note := NoteSpelling.name_for(position.midi_note, spelling, tonic, degree)
			var role := scale.note_role(interval)
			result.append({"string_index": string_index, "fret": fret,
				"midi_note": position.midi_note, "pitch_class": position.pitch_class,
				"octave": position.octave, "interval": interval, "degree": degree,
				"note": note, "frequency": Pitch.new(position.midi_note).frequency(),
				"note_role": role, "is_tonic": role == ScaleDefinition.NoteRole.ROOT, "is_chord_tone": false})
	return result
