extends SceneTree

func _init() -> void:
	var explorer := ScaleExplorer.new()
	assert(explorer.errors.is_empty())
	for record: Dictionary in explorer.scales:
		explorer.scale_id = record.id
		for tonic in range(12):
			explorer.tonic = tonic
			var model := explorer.model()
			var expected_count := 0
			for index in range(6):
				for fret in range(25):
					if record.intervals.has(posmod(explorer.tuning.midi_at(index, fret) - tonic, 12)):
						expected_count += 1
			assert(model.size() == expected_count)
			for position: Dictionary in model:
				assert(position.midi_note == explorer.tuning.midi_at(position.string_index, position.fret))
				assert(position.is_tonic == (position.pitch_class == tonic))
				assert(position.note_role in [ScaleDefinition.NoteRole.ROOT, ScaleDefinition.NoteRole.CHARACTERISTIC, ScaleDefinition.NoteRole.SECONDARY])
	var snapshot := explorer.model()
	snapshot[0].midi_note = -999
	assert(explorer.model()[0].midi_note != -999)
	assert(explorer.select_tuning("drop_d"))
	assert(explorer.tuning.midi_at(0, 0) == 38)
	explorer.scale_id = "dorian"
	explorer.tonic = 2
	var dorian := explorer.model()
	assert(dorian.filter(func(position: Dictionary): return position.interval == 0)[0].note_role == ScaleDefinition.NoteRole.ROOT)
	assert(dorian.filter(func(position: Dictionary): return position.interval == 3)[0].note_role == ScaleDefinition.NoteRole.CHARACTERISTIC)
	assert(dorian.filter(func(position: Dictionary): return position.interval == 2)[0].note_role == ScaleDefinition.NoteRole.SECONDARY)
	print("Application tests passed: every scale/tonic, exact pitches, cache isolation, alternate tuning.")
	quit()
