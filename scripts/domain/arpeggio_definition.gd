class_name ArpeggioDefinition
extends RefCounted

const CATALOG_PATH := "res://data/arpeggios.json"
const VALID_ORDERS := ["ascending", "descending", "up_down"]

var id: String
var name_key: String
var chord_id: String
var order: String
var steps: Array[Dictionary]
var names: Dictionary


func _init(raw: Dictionary) -> void:
	var errors := validation_errors(raw)
	assert(errors.is_empty(), "Invalid arpeggio definition: %s" % "; ".join(errors))
	id = raw.id
	name_key = raw.name_key
	chord_id = raw.chord_id
	order = raw.order
	names = raw.names.duplicate(true)
	for raw_step: Dictionary in raw.steps:
		var step: Dictionary = raw_step.duplicate(true)
		step.interval = int(raw_step.interval)
		step.octave_offset = int(raw_step.octave_offset)
		steps.append(step)


static func load_catalog(path: String = CATALOG_PATH, chord_catalog: Dictionary = {}) -> Dictionary:
	var document := ChordDefinition._read_document(path)
	if not document.ok:
		return _failure(document.errors)
	var errors := PackedStringArray()
	var catalog := {}
	var raw_arpeggios: Variant = document.document.get("arpeggios", null)
	if not raw_arpeggios is Array:
		errors.append("%s: 'arpeggios' must be an array." % path)
		return _failure(errors)
	for raw_arpeggio: Variant in raw_arpeggios:
		if not raw_arpeggio is Dictionary:
			errors.append("%s: Arpeggio records must be objects." % path)
			continue
		var record_errors := validation_errors(raw_arpeggio)
		var record_id := str(raw_arpeggio.get("id", "<missing id>"))
		var chord_id := str(raw_arpeggio.get("chord_id", ""))
		if not chord_catalog.is_empty():
			if not chord_catalog.has(chord_id):
				record_errors.append("Unknown chord_id '%s'." % chord_id)
			else:
				var chord: ChordDefinition = chord_catalog[chord_id]
				for step: Dictionary in raw_arpeggio.get("steps", []):
					var interval_value: Variant = ChordDefinition._whole_number(step.get("interval", null))
					if interval_value != null and not chord.contains_interval(int(interval_value)):
						record_errors.append("Step interval %d is not in chord '%s'." % [int(interval_value), chord_id])
		for error in record_errors:
			errors.append("%s [%s]: %s" % [path, record_id, error])
		if not record_errors.is_empty():
			continue
		if catalog.has(record_id):
			errors.append("%s [%s]: Duplicate id." % [path, record_id])
			continue
		catalog[record_id] = ArpeggioDefinition.new(raw_arpeggio)
	return {"ok": errors.is_empty(), "catalog": catalog if errors.is_empty() else {}, "errors": errors}


static func validation_errors(raw: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not raw is Dictionary:
		errors.append("Arpeggio definition must be an object.")
		return errors
	for key in ["id", "name_key", "chord_id", "order"]:
		if not raw.get(key, null) is String or str(raw.get(key, "")).is_empty():
			errors.append("'%s' must be a non-empty string." % key)
	if raw.get("order", "") is String and not VALID_ORDERS.has(raw.order):
		errors.append("order must be one of %s." % ", ".join(VALID_ORDERS))
	if not raw.get("names", null) is Dictionary:
		errors.append("'names' must be an object with ru and en strings.")
	else:
		for language in ["ru", "en"]:
			if not raw.names.get(language, null) is String or str(raw.names.get(language, "")).is_empty():
				errors.append("names.%s must be a non-empty string." % language)
	if not raw.get("steps", null) is Array:
		errors.append("'steps' must be an array.")
		return errors
	var raw_steps: Array = raw.steps
	if raw_steps.size() < 2:
		errors.append("An arpeggio needs at least two steps.")
		return errors
	var midi_offsets: Array[int] = []
	for raw_step in raw_steps:
		if not raw_step is Dictionary:
			errors.append("Arpeggio steps must be objects.")
			continue
		var interval: Variant = raw_step.get("interval", null)
		var octave: Variant = raw_step.get("octave_offset", null)
		var normalized_interval: Variant = ChordDefinition._whole_number(interval)
		var normalized_octave: Variant = ChordDefinition._whole_number(octave)
		if normalized_interval == null or int(normalized_interval) < 0 or int(normalized_interval) > 11:
			errors.append("Step intervals must be integers between 0 and 11.")
			continue
		if normalized_octave == null or int(normalized_octave) < -2 or int(normalized_octave) > 2:
			errors.append("Step octave_offset must be an integer between -2 and 2.")
			continue
		midi_offsets.append(int(normalized_interval) + 12 * int(normalized_octave))
	if midi_offsets.size() == raw_steps.size() and raw.get("order", "") is String:
		_validate_order(raw.order, midi_offsets, errors)
	return errors


func midi_offsets() -> PackedInt32Array:
	var result := PackedInt32Array()
	for step in steps:
		result.append(int(step.interval) + 12 * int(step.octave_offset))
	return result


static func _validate_order(order_value: String, offsets: Array[int], errors: PackedStringArray) -> void:
	match order_value:
		"ascending":
			if not _strictly_increasing(offsets):
				errors.append("ascending steps must be strictly increasing in pitch.")
		"descending":
			if not _strictly_decreasing(offsets):
				errors.append("descending steps must be strictly decreasing in pitch.")
		"up_down":
			var peak_index := offsets.find(offsets.max())
			if peak_index <= 0 or peak_index >= offsets.size() - 1 or not _strictly_increasing(offsets.slice(0, peak_index + 1)) or not _strictly_decreasing(offsets.slice(peak_index, offsets.size())):
				errors.append("up_down steps must rise to one interior peak then strictly fall.")


static func _strictly_increasing(offsets: Array) -> bool:
	for index in range(1, offsets.size()):
		if offsets[index] <= offsets[index - 1]:
			return false
	return true


static func _strictly_decreasing(offsets: Array) -> bool:
	for index in range(1, offsets.size()):
		if offsets[index] >= offsets[index - 1]:
			return false
	return true


static func _failure(errors: PackedStringArray) -> Dictionary:
	return {"ok": false, "catalog": {}, "errors": errors}
