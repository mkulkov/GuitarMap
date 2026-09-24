class_name GuidedStudy
extends RefCounted

## Small, data-only study prompts and playable routes for the active lesson.
## The caller decides how to render the prompts and play the returned notes.

static func steps(model: LearningModel) -> Array[Dictionary]:
	var english := model.language.to_lower().begins_with("en")
	var tonic := _tonic_name(model)
	var topic := model.topic.to_lower()
	# CAGED describes a movable major shape, independently of the chord selected
	# before entering this topic.
	var chord_intervals: Array = [0, 4, 7] if topic == "caged" else _chord_intervals(model)
	var triad := _triad_intervals(chord_intervals)
	var result: Array[Dictionary] = []

	if topic == "caged" and not model.is_caged_compatible():
		return [_step(
			"CAGED unavailable" if english else "CAGED недоступен",
			"This tuning changes the string intervals, so this CAGED shape cannot be shown reliably." if english else "Этот строй меняет интервалы между струнами, поэтому форму CAGED нельзя показать достоверно.",
			"chord", false, []
		)]

	result.append(_step(
		"Find %s" % tonic if english else "Найдите тонику %s" % tonic,
		"Play each highlighted %s and hear the centre of the current selection." % tonic if english else "Сыграйте каждую отмеченную ноту %s и услышьте опору текущего материала." % tonic,
		"roots", false, [0]
	))

	if topic == "scales":
		result.append(_step(
			"Trace the selected scale" if english else "Пройдите выбранную гамму",
			"Play every highlighted note across the strings, then return. The root is your reference inside the pattern." if english else "Пройдите все выделенные ноты по струнам и вернитесь обратно. Тоника — опора внутри рисунка; крайняя нота не обязана быть тоникой.",
			"scale", true, []
		))
	else:
		var cumulative: Array[int] = [0]
		for interval: int in chord_intervals:
			if interval == 0:
				continue
			cumulative.append(interval)
			var tone_name := _chord_tone_name(interval, english)
			result.append(_step(
				("Add %s" if english else "Добавьте %s") % tone_name,
				("Add the %s to the root, then play the two tones together." if english else "Добавьте %s к тонике и сыграйте эти два звука вместе.") % tone_name,
				"chord", false, cumulative
			))
		result.append(_step(
			"Hear the chord tones" if english else "Услышьте звуки аккорда",
			"Play the highlighted chord tones together, then compare their colour with %s." % tonic if english else "Сыграйте отмеченные звуки аккорда вместе, затем сравните их звучание с тоникой %s." % tonic,
			"chord", true, chord_intervals
		))
		if topic == "arpeggios":
			result.append(_step(
				"Play the arpeggio upward" if english else "Сыграйте арпеджио вверх",
				"Use the route to hear the selected chord one note at a time up to the octave." if english else "Используйте маршрут, чтобы услышать выбранный аккорд по одному звуку до октавы.",
				"chord", true, chord_intervals
			))
		elif topic == "caged":
			result.append(_step(
				"Connect this CAGED shape" if english else "Свяжите эту форму CAGED",
				"Follow the selected shape, then compare its chord tones with the current scale." if english else "Пройдите по выбранной форме, затем сравните её звуки аккорда с текущей гаммой.",
				"chord", true, triad
			))

	result.append(_step(
		"Relate it to the scale" if english else "Свяжите с гаммой",
		"Notice which current scale degrees support the selected chord and which add tension." if english else "Заметьте, какие ступени текущей гаммы поддерживают выбранный аккорд, а какие создают напряжение.",
		"scale", false, []
	))
	return result


static func route(model: LearningModel, visible_range: Vector2i) -> Array[Dictionary]:
	var positions := _eligible_positions(model, visible_range)
	if positions.is_empty():
		return []
	var intervals := _route_intervals(model, positions)
	if intervals.is_empty():
		return []
	var roots: Array[int] = []
	for position: Dictionary in positions:
		if int(position.interval) == 0:
			roots.append(int(position.midi_note))
	roots.sort()
	for root_midi: int in roots:
		var targets: Array[int] = []
		for interval: int in intervals:
			targets.append(root_midi + interval)
		targets.append(root_midi + 12)
		var selected := _select_targets(positions, targets)
		if selected.size() == targets.size():
			_assign_suggested_fingers(selected)
			return selected
	return []


static func _step(title: String, body: String, layer: String, listen: bool, intervals: Array) -> Dictionary:
	return {
		"title": title,
		"body": body,
		"layer": layer,
		"listen": listen,
		"highlight_intervals": intervals.duplicate(),
	}


static func _tonic_name(model: LearningModel) -> String:
	for position: Dictionary in model.positions():
		if int(position.interval) == 0:
			return str(position.note)
	return str(model.tonic)


static func _chord_intervals(model: LearningModel) -> Array:
	var result: Array[int] = []
	for position: Dictionary in model.positions():
		var interval := int(position.interval)
		if position.in_chord and not result.has(interval):
			result.append(interval)
	result.sort()
	return result


static func _triad_intervals(chord_intervals: Array) -> Array:
	var result: Array[int] = [0]
	for interval: int in chord_intervals:
		if interval in [3, 4, 7] and not result.has(interval):
			result.append(interval)
	return result


static func _chord_tone_name(interval: int, english: bool) -> String:
	var names_en := {
		1: "minor second", 2: "major second", 3: "minor third", 4: "major third",
		5: "fourth", 6: "diminished fifth", 7: "fifth", 8: "minor sixth",
		9: "major sixth", 10: "minor seventh", 11: "major seventh",
	}
	var names_ru := {
		1: "малую секунду", 2: "большую секунду", 3: "малую терцию", 4: "большую терцию",
		5: "кварту", 6: "уменьшённую квинту", 7: "квинту", 8: "малую сексту",
		9: "большую сексту", 10: "малую септиму", 11: "большую септиму",
	}
	return str((names_en if english else names_ru).get(interval, "selected tone" if english else "выбранный звук"))


static func _eligible_positions(model: LearningModel, visible_range: Vector2i) -> Array[Dictionary]:
	var minimum_fret := mini(visible_range.x, visible_range.y)
	var maximum_fret := maxi(visible_range.x, visible_range.y)
	var topic := model.topic.to_lower()
	var layer := model.layer.to_lower()
	var selected: Array[Dictionary] = []
	for position: Dictionary in model.positions():
		var fret := int(position.fret)
		if fret < minimum_fret or fret > maximum_fret:
			continue
		var included := false
		match layer:
			"roots":
				included = position.is_root and (topic != "caged" or position.in_shape)
			"scale":
				included = position.in_scale
			_:
				included = position.in_shape if topic == "caged" else position.in_chord
		if included:
			selected.append(position.duplicate(true))
	return selected


static func _route_intervals(model: LearningModel, positions: Array[Dictionary]) -> Array[int]:
	var available: Array[int] = []
	for position: Dictionary in positions:
		var interval := int(position.interval)
		if not available.has(interval):
			available.append(interval)
	available.sort()
	if model.layer.to_lower() == "roots":
		var root_only: Array[int] = []
		if available.has(0):
			root_only.append(0)
		return root_only
	return available


static func _select_targets(positions: Array[Dictionary], targets: Array[int]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var previous: Dictionary = {}
	for target: int in targets:
		var candidates: Array[Dictionary] = []
		for position: Dictionary in positions:
			if int(position.midi_note) == target:
				candidates.append(position)
		if candidates.is_empty():
			return []
		candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
			return _transition_cost(previous, left) < _transition_cost(previous, right)
		)
		var choice: Dictionary = candidates[0].duplicate(true)
		result.append(choice)
		previous = choice
	return result


static func _transition_cost(previous: Dictionary, candidate: Dictionary) -> int:
	if previous.is_empty():
		return int(candidate.fret)
	return abs(int(candidate.string_index) - int(previous.string_index)) * 12 + abs(int(candidate.fret) - int(previous.fret)) * 2


static func _assign_suggested_fingers(route_positions: Array[Dictionary]) -> void:
	var minimum_fret := 128
	var maximum_fret := 0
	for position: Dictionary in route_positions:
		var fret := int(position.fret)
		if fret > 0:
			minimum_fret = mini(minimum_fret, fret)
			maximum_fret = maxi(maximum_fret, fret)
	var fits_four_frets := minimum_fret <= maximum_fret and maximum_fret - minimum_fret <= 3
	for position: Dictionary in route_positions:
		var fret := int(position.fret)
		if fret == 0:
			position.suggested_finger = 0
		elif fits_four_frets:
			position.suggested_finger = fret - minimum_fret + 1
		else:
			# -1 means that this route does not fit one four-fret hand position.
			position.suggested_finger = -1
