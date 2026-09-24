class_name ChordVoicing
extends RefCounted

## Chooses the fullest fingerable chord voicing from fretboard positions.
## A barre spans one continuous set of sounding strings; when every string
## cannot be played, the largest contiguous playable subset is retained.

const HAND_POSITION_WIDTH := 4


static func select(positions: Array[Dictionary], intervals: Array) -> Array[Dictionary]:
	var required := _unique_intervals(intervals)
	if positions.is_empty() or required.is_empty():
		return []
	var bases := _hand_position_bases(positions)
	var state := {"best": [], "score": -INF}
	for base: int in bases:
		var candidates := positions.filter(func(position: Dictionary) -> bool:
			var fret := int(position.fret)
			return fret == 0 or (fret >= base and fret < base + HAND_POSITION_WIDTH)
		)
		_search_coverage(required, candidates, 0, {}, state)
	var result: Array[Dictionary] = []
	for position: Dictionary in state.best:
		result.append(position.duplicate(true))
	return result


static func _unique_intervals(intervals: Array) -> Array[int]:
	var result: Array[int] = []
	for raw_interval: Variant in intervals:
		var interval := posmod(int(raw_interval), 12)
		if not result.has(interval):
			result.append(interval)
	result.sort()
	if result.has(0):
		result.erase(0)
		result.push_front(0)
	return result


static func _hand_position_bases(positions: Array[Dictionary]) -> Array[int]:
	var result: Array[int] = []
	for position: Dictionary in positions:
		var fret := int(position.fret)
		if fret > 0 and not result.has(fret):
			result.append(fret)
	result.sort()
	return result


static func _search_coverage(required: Array[int], candidates: Array, index: int, selected: Dictionary, state: Dictionary) -> void:
	if index >= required.size():
		_search_completion(candidates, _string_indexes(candidates), 0, selected, state)
		return
	var interval := required[index]
	for candidate: Dictionary in candidates:
		if int(candidate.interval) != interval:
			continue
		var string_index := int(candidate.string_index)
		if selected.has(string_index):
			continue
		var next := selected.duplicate(true)
		next[string_index] = candidate.duplicate(true)
		_search_coverage(required, candidates, index + 1, next, state)


static func _search_completion(candidates: Array, strings: Array[int], index: int, selected: Dictionary, state: Dictionary) -> void:
	if index >= strings.size():
		_consider_complete_voicing(selected, state)
		return
	var string_index := strings[index]
	if selected.has(string_index):
		_search_completion(candidates, strings, index + 1, selected, state)
		return
	# A string may be muted if using it would invalidate an otherwise full form.
	_search_completion(candidates, strings, index + 1, selected, state)
	for candidate: Dictionary in candidates:
		if int(candidate.string_index) != string_index:
			continue
		var next := selected.duplicate(true)
		next[string_index] = candidate.duplicate(true)
		_search_completion(candidates, strings, index + 1, next, state)


static func _consider_complete_voicing(selected: Dictionary, state: Dictionary) -> void:
	var result: Array[Dictionary] = []
	for position: Dictionary in selected.values():
		result.append(position)
	result.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.string_index) < int(right.string_index)
	)
	if not is_fingerable(result):
		return
	var score := _voicing_score(result)
	if score > float(state.score):
		state.best = result.duplicate(true)
		state.score = score


static func is_fingerable(voicing: Array[Dictionary]) -> bool:
	if voicing.is_empty() or not _uses_contiguous_strings(voicing):
		return false
	var fretted: Array[int] = []
	for position: Dictionary in voicing:
		if int(position.fret) > 0:
			fretted.append(int(position.fret))
	if not fretted.is_empty():
		fretted.sort()
		if fretted[-1] - fretted[0] >= HAND_POSITION_WIDTH:
			return false
	return _minimum_finger_groups(voicing) <= 4


static func _voicing_score(voicing: Array[Dictionary]) -> float:
	var fretted: Array[int] = []
	var minimum_string := 128
	var maximum_string := -1
	for position: Dictionary in voicing:
		if int(position.fret) > 0:
			fretted.append(int(position.fret))
		minimum_string = mini(minimum_string, int(position.string_index))
		maximum_string = maxi(maximum_string, int(position.string_index))
	var span := 0
	if not fretted.is_empty():
		fretted.sort()
		span = fretted[-1] - fretted[0]
	var string_span := maximum_string - minimum_string
	return float(voicing.size() * 10000 - _minimum_finger_groups(voicing) * 100 - string_span * 10 - span)


static func _minimum_finger_groups(voicing: Array[Dictionary]) -> int:
	var groups := _finger_group_count(voicing)
	var fretted: Array[int] = []
	for position: Dictionary in voicing:
		if int(position.fret) > 0:
			fretted.append(int(position.fret))
	if not fretted.is_empty():
		fretted.sort()
		var barre_fret := fretted[0]
		if _can_use_barre(voicing, barre_fret):
			groups = mini(groups, _finger_group_count(voicing, barre_fret))
	return groups


static func _finger_group_count(voicing: Array[Dictionary], barre_fret: int = -1) -> int:
	var by_fret := {}
	for position: Dictionary in voicing:
		var fret := int(position.fret)
		if fret <= 0:
			continue
		if not by_fret.has(fret):
			by_fret[fret] = []
		(by_fret[fret] as Array).append(int(position.string_index))
	var groups := 0
	for raw_fret: Variant in by_fret:
		var fret := int(raw_fret)
		if fret == barre_fret:
			groups += 1
			continue
		var strings: Array = by_fret[fret]
		strings.sort()
		var previous := -2
		for string_index: int in strings:
			if string_index != previous + 1:
				groups += 1
			previous = string_index
	return groups


static func _string_indexes(candidates: Array) -> Array[int]:
	var result: Array[int] = []
	for candidate: Dictionary in candidates:
		var string_index := int(candidate.string_index)
		if not result.has(string_index):
			result.append(string_index)
	result.sort()
	return result


static func _uses_contiguous_strings(voicing: Array[Dictionary]) -> bool:
	var strings: Array[int] = []
	for position: Dictionary in voicing:
		var string_index := int(position.string_index)
		if strings.has(string_index):
			return false
		strings.append(string_index)
	strings.sort()
	for index in range(1, strings.size()):
		if strings[index] != strings[index - 1] + 1:
			return false
	return true


static func _can_use_barre(voicing: Array[Dictionary], barre_fret: int) -> bool:
	for position: Dictionary in voicing:
		if int(position.fret) < barre_fret:
			return false
	return true
