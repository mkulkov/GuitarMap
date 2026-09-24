class_name LearningModel
extends RefCounted

const JsonLoader := preload("res://scripts/data/json_catalog_loader.gd")
const ChordType := preload("res://scripts/domain/chord_definition.gd")
const NoteNames := preload("res://scripts/domain/note_spelling.gd")
const Theory := preload("res://scripts/domain/music_theory.gd")

const FRET_COUNT := 24
const STANDARD_TUNING: PackedInt32Array = [40, 45, 50, 55, 59, 64]
const CAGED_SHAPES: PackedStringArray = ["C", "A", "G", "E", "D"]
const INTERVAL_LABELS: PackedStringArray = [
	"1", "b2", "2", "b3", "3", "4", "b5", "5", "b6", "6", "b7", "7",
]
const CAGED_TEMPLATES := {
	# Offsets are relative to the root fret on anchor_string. Missing strings
	# are deliberately muted, just as they are in the five open major forms.
	"C": {"anchor_string": 1, "offsets": {1: 0, 2: -1, 3: -3, 4: -2, 5: -3}},
	"A": {"anchor_string": 1, "offsets": {1: 0, 2: 2, 3: 2, 4: 2, 5: 0}},
	"G": {"anchor_string": 0, "offsets": {0: 0, 1: -1, 2: -3, 3: -3, 4: -3, 5: 0}},
	"E": {"anchor_string": 0, "offsets": {0: 0, 1: 2, 2: 2, 3: 1, 4: 0, 5: 0}},
	"D": {"anchor_string": 2, "offsets": {2: 0, 3: 2, 4: 3, 5: 2}},
}

var tonic: int = 9
var scale_id: String = "major"
var topic: String = "caged"
var shape: String = "E"
var layer: String = "chord"
var tuning: Variant = STANDARD_TUNING.duplicate()
var chord_id: String = "major"
var spelling: String = "sharp"
var language: String = "ru"
var fret_count: int = FRET_COUNT
var shape_fret_offset: int = 0

var errors := PackedStringArray()
var scales: Array[Dictionary] = []
var chords: Dictionary = {}


func _init() -> void:
	var scale_result := JsonLoader.load_with_fallback(
		"res://data/scales.json", "user://scales.json", "scales"
	)
	if scale_result.ok:
		for record: Dictionary in scale_result.records:
			scales.append(record)
	else:
		errors.append_array(scale_result.errors)

	var chord_result := ChordType.load_catalog()
	if chord_result.ok:
		chords = chord_result.catalog
	else:
		errors.append_array(chord_result.errors)


func positions() -> Array[Dictionary]:
	var open_notes := _open_string_notes()
	if open_notes.is_empty():
		return []

	var scale_record := _scale_record()
	var chord_record: Variant = _chord_record()
	var scale_intervals: Array = scale_record.get("intervals", [])
	var scale_degrees: Array = scale_record.get("degree_labels", [])
	var chord_intervals: Array = _chord_intervals(chord_record)

	var shape_lookup := {}
	for slot: Dictionary in _caged_slots():
		shape_lookup[_position_key(slot.string_index, slot.fret)] = true

	var result: Array[Dictionary] = []
	for string_index in open_notes.size():
		for fret in range(_effective_fret_count() + 1):
			# MIDI itself is bounded even when a caller supplies an unusually high
			# custom tuning. The physical grid remains complete through fret 24.
			var midi_note := clampi(int(open_notes[string_index]) + fret, 0, 127)
			var interval := posmod(midi_note - tonic, 12)
			var scale_index := scale_intervals.find(interval)
			var in_scale := scale_index >= 0
			var in_chord := chord_intervals.has(interval)
			var in_shape := shape_lookup.has(_position_key(string_index, fret))
			var degree := INTERVAL_LABELS[interval]
			if in_scale and scale_index < scale_degrees.size():
				degree = str(scale_degrees[scale_index])
			var note := NoteNames.name_for(midi_note, spelling, tonic, degree)
			var is_root := interval == 0
			result.append({
				"string_index": string_index,
				"fret": fret,
				"midi_note": midi_note,
				"pitch_class": posmod(midi_note, 12),
				"octave": Theory.octave(midi_note),
				"note": note,
				"degree": degree,
				"interval": interval,
				"in_scale": in_scale,
				"in_chord": in_chord,
				"in_shape": in_shape,
				"is_root": is_root,
				# Compatibility aliases used by the existing fretboard view.
				"is_tonic": is_root,
				"is_chord_tone": in_chord,
				"role": _visual_role(interval, in_scale, in_chord, in_shape),
				"is_active": _is_active(is_root, in_scale, in_chord, in_shape),
			})
	return result


func caged_positions() -> Array[Dictionary]:
	if not is_caged_compatible():
		return []
	return positions().filter(func(position: Dictionary) -> bool: return position.in_shape)


func recommended_range() -> Vector2i:
	var slots := _caged_slots()
	if slots.is_empty() and is_caged_compatible():
		slots = _caged_slots_with_limit(127)
	if slots.is_empty():
		return Vector2i(0, 12)
	var minimum_fret := 127
	var maximum_fret := 0
	for slot: Dictionary in slots:
		minimum_fret = mini(minimum_fret, int(slot.fret))
		maximum_fret = maxi(maximum_fret, int(slot.fret))
	return Vector2i(maxi(0, minimum_fret - 2), mini(36, maximum_fret + 2))


func explanation() -> Dictionary:
	var tonic_name := NoteNames.name_for(tonic, spelling)
	var scale_record := _scale_record()
	var chord_record: Variant = _chord_record()
	var use_english := language.to_lower().begins_with("en")
	var scale_name := _localized_name(scale_record, scale_id, "en" if use_english else "ru")
	var chord_name := _chord_name(chord_record, chord_id, "en" if use_english else "ru")
	var chord_formula := _formula_for_chord(chord_record)
	var chord_notes := _note_names_for_intervals(_chord_intervals(chord_record))
	var compatible := true
	var title := ""
	var formula := ""
	var note_names: Array[String] = []
	var body := ""
	var message := ""
	var available_in_range := not _caged_slots().is_empty()

	match topic.to_lower():
		"scales":
			title = "%s · %s" % [tonic_name, scale_name]
			formula = str(scale_record.get("metadata", {}).get("degree_formula", ""))
			if use_english and formula == "Все 12 полутонов":
				formula = "All 12 semitones"
			note_names = _note_names_for_intervals(scale_record.get("intervals", []), scale_record.get("degree_labels", []))
			if use_english:
				body = "%s contains the degrees %s. Explore their repeated positions and listen to how each degree resolves to %s." % [scale_name, formula, tonic_name]
			else:
				body = str(scale_record.get("metadata", {}).get("learning_description", ""))
		"chords":
			title = "%s · %s" % [tonic_name, chord_name]
			formula = chord_formula
			note_names = chord_notes
			body = ("The chord is built from the highlighted degrees. The root is its tonal centre; the other notes define its quality."
				if use_english else
				"Аккорд собирается из отмеченных ступеней. Тоника задаёт опору, остальные звуки определяют его качество.")
		"arpeggios":
			title = ("%s · %s arpeggio" if use_english else "%s · Арпеджио %s") % [tonic_name, chord_name]
			formula = " → ".join(_chord_degree_labels(chord_record) + ["1"])
			note_names = chord_notes
			body = ("The arpeggio plays the chord tones in sequence. The fretboard highlights every position as it sounds."
				if use_english else
				"Арпеджио последовательно раскрывает звуки аккорда. Подсветка на грифе показывает каждую исполняемую позицию.")
		"caged":
			compatible = is_caged_compatible()
			title = ("%s shape · %s major" if use_english else "Форма %s · %s мажор") % [shape.to_upper(), tonic_name]
			formula = "1 · 3 · 5"
			note_names = _note_names_for_intervals([0, 4, 7], ["1", "3", "5"])
			if compatible and available_in_range:
				var neck_range := recommended_range()
				body = (("Movable %s shape connects the root, major third, and fifth. Compare it with the selected %s scale on frets %d–%d."
					if use_english else
					"Переносимая форма %s соединяет тонику, большую терцию и квинту. Сравните её с выбранной гаммой «%s» на ладах %d–%d.") % [shape.to_upper(), scale_name, neck_range.x, neck_range.y])
				if not _scale_contains_major_triad(scale_record):
					message = ("The CAGED major shape is shown over the selected %s scale. Its major third may be outside that scale."
						if use_english else
						"Мажорная форма CAGED показана поверх выбранной гаммы «%s». Её большая терция может не входить в эту гамму.") % scale_name
					body += " " + message
				if not _chord_contains_major_triad(chord_record):
					var chord_message := ("CAGED still shows a major shape; the selected %s chord uses a different formula."
						if use_english else
						"CAGED по-прежнему показывает мажорную форму; выбранный аккорд «%s» использует другую формулу.") % chord_name
					message = (message + " " + chord_message).strip_edges()
					body += " " + chord_message
			elif compatible:
				var required_range := recommended_range()
				message = (("The complete %s shape needs frets %d–%d. Increase the visible fret range."
					if use_english else
					"Для полной формы %s нужны лады %d–%d. Увеличьте видимый диапазон грифа.") % [shape.to_upper(), required_range.x, required_range.y])
				body = message
			else:
				message = ("CAGED is available for standard tuning and its uniform transpositions. The selected tuning changes the intervals between strings."
					if use_english else
					"CAGED доступен для стандартного строя и его равномерных транспозиций. В выбранном строе интервалы между струнами отличаются.")
				body = message
		_:
			compatible = false
			title = "Learning topic unavailable" if use_english else "Учебная тема недоступна"
			message = ("Unknown topic: %s" if use_english else "Неизвестная тема: %s") % topic
			body = message

	var shape_index := CAGED_SHAPES.find(shape.to_upper())
	var previous_shape := ""
	var next_shape := ""
	if shape_index >= 0:
		previous_shape = CAGED_SHAPES[posmod(shape_index - 1, CAGED_SHAPES.size())]
		next_shape = CAGED_SHAPES[(shape_index + 1) % CAGED_SHAPES.size()]
	return {
		"title": title,
		"formula": formula,
		"notes": " · ".join(note_names),
		"note_names": note_names,
		"body": body,
		"compatible": compatible,
		"message": message,
		"previous_shape": previous_shape,
		"next_shape": next_shape,
		"language": "en" if use_english else "ru",
		"scale_overlay_compatible": _scale_contains_major_triad(scale_record),
		"chord_overlay_compatible": _chord_contains_major_triad(chord_record),
		"available_in_range": available_in_range,
	}


func is_caged_compatible() -> bool:
	var open_notes := _open_string_notes()
	if open_notes.size() != STANDARD_TUNING.size():
		return false
	var transposition := int(open_notes[0]) - STANDARD_TUNING[0]
	for string_index in STANDARD_TUNING.size():
		if int(open_notes[string_index]) - STANDARD_TUNING[string_index] != transposition:
			return false
	return CAGED_TEMPLATES.has(shape.to_upper())


func scale_records() -> Array[Dictionary]:
	return scales.duplicate(true)


func chord_records() -> Array:
	return chords.values().duplicate()


func _caged_slots() -> Array[Dictionary]:
	return _caged_slots_with_limit(_effective_fret_count())


func _caged_slots_with_limit(maximum_fret: int) -> Array[Dictionary]:
	if not is_caged_compatible():
		return []
	var open_notes := _open_string_notes()
	var template: Dictionary = CAGED_TEMPLATES[shape.to_upper()]
	var anchor_string := int(template.anchor_string)
	var offsets: Dictionary = template.offsets
	var first_root_fret := posmod(tonic - int(open_notes[anchor_string]), 12)
	var minimum_offset := 0
	var maximum_offset := 0
	for offset: int in offsets.values():
		minimum_offset = mini(minimum_offset, offset)
		maximum_offset = maxi(maximum_offset, offset)
	var root_fret := -1
	for octave_shift in range(0, 12):
		var candidate := first_root_fret + octave_shift * 12
		if candidate + minimum_offset >= 0 and candidate + maximum_offset <= maximum_fret:
			root_fret = candidate
			break
	if root_fret < 0:
		return []
	root_fret += shape_fret_offset
	if root_fret + minimum_offset < 0 or root_fret + maximum_offset > maximum_fret:
		return []

	var result: Array[Dictionary] = []
	for raw_string_index: Variant in offsets.keys():
		var string_index := int(raw_string_index)
		var fret := root_fret + int(offsets[raw_string_index])
		if fret >= 0 and fret <= maximum_fret:
			result.append({"string_index": string_index, "fret": fret})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.string_index < b.string_index
	)
	return result


func _open_string_notes() -> PackedInt32Array:
	if tuning is GuitarTuning:
		return tuning.open_string_midi.duplicate()
	var result := PackedInt32Array()
	if tuning is PackedInt32Array or tuning is PackedInt64Array or tuning is Array:
		for raw_note: Variant in tuning:
			if not raw_note is int:
				return PackedInt32Array()
			var midi_note := int(raw_note)
			if midi_note < 0 or midi_note > 127:
				return PackedInt32Array()
			result.append(midi_note)
	return result


func _scale_record() -> Dictionary:
	for record: Dictionary in scales:
		if record.id == scale_id or record.get("aliases", []).has(scale_id):
			return record
	return {}


func _chord_record() -> Variant:
	if chords.has(chord_id):
		return chords[chord_id]
	for candidate: Variant in chords.values():
		if candidate.aliases.has(chord_id):
			return candidate
	return {}


func _localized_name(record: Dictionary, fallback: String, locale: String) -> String:
	if record.is_empty():
		return fallback
	return str(record.get("names", {}).get(locale, fallback))


func _chord_name(record: Variant, fallback: String, locale: String) -> String:
	if record is Dictionary and record.is_empty():
		return fallback
	return str(record.names.get(locale, fallback))


func _chord_intervals(record: Variant) -> Array:
	if record is Dictionary and record.is_empty():
		return []
	return Array(record.intervals)


func _chord_degree_labels(record: Variant) -> Array[String]:
	var result: Array[String] = []
	for interval: int in _chord_intervals(record):
		result.append(INTERVAL_LABELS[interval])
	return result


func _formula_for_chord(record: Variant) -> String:
	return " · ".join(_chord_degree_labels(record))


func _note_names_for_intervals(intervals: Array, degree_labels: Array = []) -> Array[String]:
	var result: Array[String] = []
	for index in intervals.size():
		var interval := int(intervals[index])
		var degree := INTERVAL_LABELS[interval]
		if index < degree_labels.size():
			degree = str(degree_labels[index])
		result.append(NoteNames.name_for(tonic + interval, spelling, tonic, degree))
	return result


func _scale_contains_major_triad(record: Dictionary) -> bool:
	var intervals: Array = record.get("intervals", [])
	return intervals.has(0) and intervals.has(4) and intervals.has(7)


func _chord_contains_major_triad(record: Variant) -> bool:
	var intervals := _chord_intervals(record)
	return intervals.has(0) and intervals.has(4) and intervals.has(7)


func _effective_fret_count() -> int:
	return clampi(fret_count, 12, 36)


func _visual_role(interval: int, in_scale: bool, in_chord: bool, in_shape: bool) -> String:
	if interval == 0:
		return "root"
	if interval == 3 or interval == 4:
		return "third"
	if interval == 7:
		return "fifth"
	if in_shape:
		return "shape"
	if in_chord:
		return "chord"
	if in_scale:
		return "scale"
	return "chromatic"


func _is_active(is_root: bool, in_scale: bool, in_chord: bool, in_shape: bool) -> bool:
	match topic.to_lower():
		"scales":
			return in_scale
		"chords", "arpeggios":
			return in_chord
		"caged":
			match layer.to_lower():
				"roots":
					return is_root and in_shape
				"scale":
					return in_scale
				_:
					return in_shape
	return false


func _position_key(string_index: int, fret: int) -> String:
	return "%d:%d" % [string_index, fret]
