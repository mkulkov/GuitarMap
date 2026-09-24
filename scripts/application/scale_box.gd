extends RefCounted

## Routes are physical string/fret positions, never octave-limited pitch lists.
static func anchors(model: LearningModel) -> Array[int]:
	var result: Array[int] = []
	for point: Dictionary in model.positions():
		if int(point.string_index) == 0 and _base_intervals(model).has(int(point.interval)):
			result.append(int(point.fret))
	return result


static func _base_intervals(model: LearningModel) -> Array:
	if model.scale_id == "minor_blues": return [0, 3, 5, 7, 10]
	if model.scale_id == "major_blues": return [0, 2, 4, 7, 9]
	for record: Dictionary in model.scales:
		if str(record.id) == model.scale_id: return record.intervals
	return []


static func build(model: LearningModel, anchor: int, three_per_string: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var positions := model.positions()
	var base := _base_intervals(model)
	var pentatonic := base.size() == 5
	var fixed_count := 3 if three_per_string else (2 if pentatonic else 0)
	var previous_midi := -1
	for string_index in model.tuning.size():
		var candidates: Array[Dictionary] = []
		for point: Dictionary in positions:
			if int(point.string_index) != string_index or not base.has(int(point.interval)): continue
			if string_index == 0 and int(point.fret) < anchor: continue
			if int(point.midi_note) <= previous_midi: continue
			if fixed_count == 0 and (int(point.fret) < maxi(0, anchor - 1) or int(point.fret) > anchor + 3): continue
			candidates.append(point.duplicate(true))
		if fixed_count > 0:
			if candidates.size() < fixed_count: return []
			candidates.resize(fixed_count)
		if candidates.is_empty(): return []
		# The six-note blues scale follows the pentatonic box with blue notes added.
		if model.scale_id in ["minor_blues", "major_blues"]:
			var first := int(candidates[0].fret)
			var last := int(candidates[-1].fret)
			for point: Dictionary in positions:
				if int(point.string_index) == string_index and point.in_scale and not base.has(int(point.interval)) and int(point.fret) > first and int(point.fret) < last:
					candidates.append(point.duplicate(true))
			candidates.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.fret) < int(b.fret))
		previous_midi = int(candidates[-1].midi_note)
		var minimum := int(candidates[0].fret)
		var maximum := int(candidates[-1].fret)
		for point: Dictionary in candidates:
			point.suggested_finger = 0 if int(point.fret) == 0 else (-1 if maximum - minimum > 4 else mini(4, int(point.fret) - minimum + 1))
			result.append(point)
	return result
