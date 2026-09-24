extends SceneTree

const ChordVoicingScript := preload("res://scripts/application/chord_voicing.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var tuning := [40, 45, 50, 55, 59, 64]
	for tonic in 12:
		for intervals in [[0, 4, 7], [0, 3, 7], [0, 4, 7, 10], [0, 3, 7, 10]]:
			var positions := _positions_for(tuning, tonic, intervals)
			var voicing: Array[Dictionary] = ChordVoicingScript.select(positions, intervals)
			assert(not voicing.is_empty(), "Expected a playable voicing for tonic %d." % tonic)
			assert(_contains_all_intervals(voicing, intervals))
			assert(_has_one_note_per_string(voicing))
			assert(voicing.size() == tuning.size(), "Expected a full six-string voicing for tonic %d." % tonic)
			assert(_fretted_span(voicing) < ChordVoicingScript.HAND_POSITION_WIDTH)
			assert(ChordVoicingScript.is_fingerable(voicing))
	var a_diminished_positions := _positions_for(tuning, 9, [0, 3, 6]).filter(func(position: Dictionary) -> bool: return int(position.fret) >= 3 and int(position.fret) <= 9)
	var a_diminished := ChordVoicingScript.select(a_diminished_positions, [0, 3, 6])
	assert(a_diminished.size() == 4)
	assert(not a_diminished.any(func(position: Dictionary) -> bool: return int(position.string_index) == 4 and int(position.fret) == 4))
	assert(ChordVoicingScript.select([], [0, 4, 7]).is_empty())
	print("Chord voicing tests passed: full chord coverage, one note per string and compact hand position.")
	quit()


func _positions_for(tuning: Array, tonic: int, intervals: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for string_index in tuning.size():
		for fret in 13:
			var interval := posmod(int(tuning[string_index]) + fret - tonic, 12)
			if intervals.has(interval):
				result.append({"string_index": string_index, "fret": fret, "interval": interval, "midi_note": int(tuning[string_index]) + fret})
	return result


func _contains_all_intervals(voicing: Array[Dictionary], expected: Array) -> bool:
	var result: Array = voicing.map(func(position: Dictionary) -> int: return int(position.interval))
	for interval in expected:
		if not result.has(interval):
			return false
	return true


func _has_one_note_per_string(voicing: Array[Dictionary]) -> bool:
	var strings := {}
	for position: Dictionary in voicing:
		var string_index := int(position.string_index)
		if strings.has(string_index):
			return false
		strings[string_index] = true
	return true


func _fretted_span(voicing: Array[Dictionary]) -> int:
	var frets: Array[int] = []
	for position: Dictionary in voicing:
		if int(position.fret) > 0:
			frets.append(int(position.fret))
	if frets.is_empty():
		return 0
	frets.sort()
	return frets[-1] - frets[0]
