extends SceneTree

const Fingering := preload("res://scripts/application/scale_fingering.gd")


func _init() -> void:
	var explorer := ScaleExplorer.new()
	assert(explorer.errors.is_empty())
	for record: Dictionary in explorer.scales:
		explorer.scale_id = record.id
		for tonic in range(12):
			explorer.tonic = tonic
			var model := explorer.model()
			var ascending := Fingering.ascending_positions(model, explorer.tuning.open_string_midi.size(), explorer.fret_count)
			var round_trip := Fingering.round_trip_positions(model, explorer.tuning.open_string_midi.size(), explorer.fret_count)
			assert(not ascending.is_empty(), "%s tonic %d has no fingering." % [record.id, tonic])
			assert(int(ascending[0].string_index) == 0 and int(ascending[0].interval) == 0)
			var keys := {}
			for position: Dictionary in ascending:
				var key := "%d:%d" % [position.string_index, position.fret]
				assert(not keys.has(key), "%s repeats %s." % [record.id, key])
				keys[key] = true
				assert(record.intervals.has(int(position.interval)))
			for index in range(ascending.size() - 1):
				assert(int(ascending[index].midi_note) < int(ascending[index + 1].midi_note), "%s tonic %d repeats or descends at %d." % [record.id, tonic, index])
			assert(round_trip.size() == ascending.size() * 2 - 1)
			for index in ascending.size():
				assert(round_trip[index].string_index == ascending[index].string_index and round_trip[index].fret == ascending[index].fret)
			for index in range(ascending.size() - 1):
				assert(round_trip[ascending.size() + index].string_index == ascending[ascending.size() - 2 - index].string_index and round_trip[ascending.size() + index].fret == ascending[ascending.size() - 2 - index].fret)
	explorer.scale_id = "natural_minor"
	explorer.tonic = 9
	var a_minor := Fingering.ascending_positions(explorer.model(), 6, 24)
	assert(a_minor.map(func(position: Dictionary): return int(position.midi_note)) == [45, 47, 48, 50, 52, 53, 55, 57, 59, 60, 62, 64, 65, 67, 69, 71, 72])
	explorer.scale_id = "lydian"
	explorer.tonic = 9
	var a_lydian := Fingering.ascending_positions(explorer.model(), 6, 24)
	print("A Lydian ascending: ", a_lydian.map(func(position: Dictionary): return "%s%d@%d:%d" % [position.note, position.octave, position.string_index + 1, position.fret]))
	print("Scale fingering tests passed: 21 scales x 12 tonics, exact position paths and A natural minor reference fingering.")
	quit()
