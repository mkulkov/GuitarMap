class_name ScaleFingering
extends RefCounted

## Builds one playable, root-anchored position from the displayed fretboard model.
## The first string starts at its tonic; the remaining strings may reach one fret
## below it, which preserves standard position-V patterns such as A natural minor.

static func ascending_positions(model: Array[Dictionary], string_count: int, fret_count: int) -> Array[Dictionary]:
	var sixth_string_roots: Array[Dictionary] = []
	for position: Dictionary in model:
		if int(position.string_index) == 0 and int(position.interval) == 0:
			sixth_string_roots.append(position)
	if sixth_string_roots.is_empty():
		return []
	sixth_string_roots.sort_custom(func(left: Dictionary, right: Dictionary): return int(left.fret) < int(right.fret))
	var root_fret := int(sixth_string_roots[0].fret)
	var box_start := maxi(0, root_fret - 1)
	var box_end := mini(fret_count, root_fret + 3)
	var result: Array[Dictionary] = []
	var previous_midi := -1
	for string_index in string_count:
		var string_positions: Array[Dictionary] = []
		for position: Dictionary in model:
			var fret := int(position.fret)
			var lower_bound := root_fret if string_index == 0 else box_start
			if int(position.string_index) == string_index and fret >= lower_bound and fret <= box_end:
				string_positions.append(position)
		string_positions.sort_custom(func(left: Dictionary, right: Dictionary): return int(left.fret) < int(right.fret))
		for position: Dictionary in string_positions:
			# Adjacent guitar strings overlap. A position at or below the previous
			# pitch is an alternate duplicate, not the next note of an ascending scale.
			if int(position.midi_note) > previous_midi:
				result.append(position)
				previous_midi = int(position.midi_note)
	return result


static func round_trip_positions(model: Array[Dictionary], string_count: int, fret_count: int) -> Array[Dictionary]:
	var ascending := ascending_positions(model, string_count, fret_count)
	if ascending.is_empty():
		return []
	var result: Array[Dictionary] = ascending.duplicate(true)
	for index in range(ascending.size() - 2, -1, -1):
		result.append(ascending[index].duplicate(true))
	return result
