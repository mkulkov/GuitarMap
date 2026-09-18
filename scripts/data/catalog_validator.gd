class_name CatalogValidator
extends RefCounted

const Scale := preload("res://scripts/domain/scale_definition.gd")
const Tuning := preload("res://scripts/domain/tuning.gd")
const IntervalDefinition := preload("res://scripts/domain/interval.gd")
const SCHEMA_VERSION := 1


static func validate_catalog(document: Variant, kind: String, source_name: String = "") -> Dictionary:
	var errors := PackedStringArray()
	var catalog_key := _catalog_key(kind)
	if catalog_key.is_empty():
		errors.append(_document_error(source_name, "Unsupported catalog kind '%s'." % kind))
		return _failure(errors)
	if not document is Dictionary:
		errors.append(_document_error(source_name, "Catalog root must be an object."))
		return _failure(errors)
	if not document.has("schema_version"):
		errors.append(_document_error(source_name, "Missing schema_version."))
		return _failure(errors)
	var version: Variant = _whole_number(document["schema_version"])
	if version == null or int(version) != SCHEMA_VERSION:
		errors.append(_document_error(source_name, "schema_version must be %d." % SCHEMA_VERSION))
		return _failure(errors)
	if not document.has(catalog_key) or not document[catalog_key] is Array:
		errors.append(_document_error(source_name, "'%s' must be an array." % catalog_key))
		return _failure(errors)

	var records: Array[Dictionary] = []
	var ids := {}
	var aliases := {}
	for raw_record in document[catalog_key]:
		if not raw_record is Dictionary:
			errors.append(_document_error(source_name, "Catalog records must be objects."))
			continue
		var record_errors := PackedStringArray()
		var normalized := _validate_record(raw_record, kind, record_errors)
		var record_id := str(raw_record.get("id", "<missing id>"))
		for error in record_errors:
			errors.append(_record_error(source_name, record_id, error))
		if not record_errors.is_empty():
			continue
		if ids.has(normalized.id):
			errors.append(_record_error(source_name, normalized.id, "Duplicate id."))
			continue
		if aliases.has(normalized.id):
			errors.append(_record_error(source_name, normalized.id, "Id conflicts with alias."))
			continue
		var conflicts := false
		for alias in normalized.get("aliases", []):
			if alias == normalized.id or ids.has(alias) or aliases.has(alias):
				errors.append(_record_error(source_name, normalized.id, "Duplicate alias '%s'." % alias))
				conflicts = true
		if conflicts:
			continue
		ids[normalized.id] = true
		for alias in normalized.get("aliases", []):
			aliases[alias] = true
		records.append(normalized)
	return {"ok": errors.is_empty(), "records": records if errors.is_empty() else [], "errors": errors}


static func _validate_record(raw: Dictionary, kind: String, errors: PackedStringArray) -> Dictionary:
	var normalized: Dictionary = {}
	for key in ["id", "name_key"]:
		if not raw.get(key, null) is String or str(raw.get(key, "")).is_empty():
			errors.append("'%s' must be a non-empty string." % key)
		else:
			normalized[key] = raw[key]
	if not raw.get("names", null) is Dictionary:
		errors.append("'names' must be an object with ru and en strings.")
	else:
		var names: Dictionary = raw.names
		for language in ["ru", "en"]:
			if not names.get(language, null) is String or str(names.get(language, "")).is_empty():
				errors.append("names.%s must be a non-empty string." % language)
		normalized["names"] = names.duplicate(true)
	if raw.has("metadata"):
		if not raw.metadata is Dictionary:
			errors.append("'metadata' must be an object.")
		else:
			normalized["metadata"] = raw.metadata.duplicate(true)

	if kind == "scale" or kind == "scales":
		_validate_scale(raw, normalized, errors)
	else:
		_validate_tuning(raw, normalized, errors)
	return normalized


static func _validate_scale(raw: Dictionary, normalized: Dictionary, errors: PackedStringArray) -> void:
	if not raw.get("category", null) is String or str(raw.get("category", "")).is_empty():
		errors.append("'category' must be a non-empty string.")
	else:
		normalized["category"] = raw.category
	if not raw.get("intervals", null) is Array:
		errors.append("'intervals' must be an array.")
		return
	var intervals := _normalized_integers(raw.intervals, "intervals", errors)
	if errors.is_empty() or not intervals.is_empty():
		for error in Scale.validation_errors(intervals):
			errors.append(error)
		normalized["intervals"] = intervals
	_validate_degree_labels_and_aliases(raw, normalized, intervals.size(), errors)


static func _validate_tuning(raw: Dictionary, normalized: Dictionary, errors: PackedStringArray) -> void:
	if not raw.get("open_string_midi", null) is Array:
		errors.append("'open_string_midi' must be an array.")
		return
	var notes := _normalized_integers(raw.open_string_midi, "open_string_midi", errors)
	if errors.is_empty() or not notes.is_empty():
		for error in Tuning.validation_errors(notes):
			errors.append(error)
		normalized["open_string_midi"] = notes
	_validate_degree_labels_and_aliases(raw, normalized, -1, errors)


static func _validate_degree_labels_and_aliases(raw: Dictionary, normalized: Dictionary, expected_size: int, errors: PackedStringArray) -> void:
	for optional_key in ["degree_labels", "aliases"]:
		if not raw.has(optional_key):
			continue
		if not raw[optional_key] is Array:
			errors.append("'%s' must be an array." % optional_key)
			continue
		var values: Array = []
		var seen := {}
		for value in raw[optional_key]:
			if not value is String or str(value).is_empty():
				errors.append("%s values must be non-empty strings." % optional_key)
				continue
			if optional_key == "aliases" and seen.has(value):
				errors.append("Duplicate alias '%s'." % value)
				continue
			seen[value] = true
			values.append(value)
		if optional_key == "degree_labels" and expected_size >= 0 and values.size() != expected_size:
			errors.append("degree_labels must match the number of intervals.")
		normalized[optional_key] = values
	if expected_size >= 0 and not raw.has("degree_labels"):
		var generated: Array = []
		for interval in normalized.get("intervals", []):
			generated.append(IntervalDefinition.CANONICAL_DEGREE_LABELS[interval])
		normalized["degree_labels"] = generated
	elif expected_size >= 0 and raw.get("degree_labels", []) is Array and values_for(raw.degree_labels).size() == expected_size:
		for index in expected_size:
			if not _matches_interval(str(raw.degree_labels[index]), int(normalized.intervals[index])):
				errors.append("degree_labels[%d] does not match interval %d." % [index, normalized.intervals[index]])


static func _normalized_integers(raw: Array, field_name: String, errors: PackedStringArray) -> Array:
	var result: Array = []
	for value in raw:
		var whole: Variant = _whole_number(value)
		if whole == null:
			errors.append("%s values must be whole numbers." % field_name)
			continue
		result.append(int(whole))
	return result


static func _whole_number(value: Variant) -> Variant:
	if value is bool:
		return null
	if value is int:
		return value
	if value is float and is_finite(value) and value == floor(value):
		return int(value)
	return null


static func _catalog_key(kind: String) -> String:
	match kind:
		"scale", "scales":
			return "scales"
		"tuning", "tunings":
			return "tunings"
		_:
			return ""


static func _document_error(source_name: String, message: String) -> String:
	return "%s: %s" % [source_name if not source_name.is_empty() else "<catalog>", message]


static func _record_error(source_name: String, record_id: String, message: String) -> String:
	return "%s [%s]: %s" % [source_name if not source_name.is_empty() else "<catalog>", record_id, message]


static func _failure(errors: PackedStringArray) -> Dictionary:
	return {"ok": false, "records": [], "errors": errors}


static func _matches_interval(label: String, interval: int) -> bool:
	var accidental_offset := 0
	var index := 0
	while index < label.length() and (label[index] == "b" or label[index] == "#"):
		accidental_offset += -1 if label[index] == "b" else 1
		index += 1
	if index >= label.length():
		return false
	var degree_text := label.substr(index)
	if not degree_text.is_valid_int():
		return false
	var degree := int(degree_text)
	if degree < 1 or degree > 7:
		return false
	var natural_intervals: PackedInt32Array = [0, 2, 4, 5, 7, 9, 11]
	return posmod(natural_intervals[degree - 1] + accidental_offset, 12) == interval


static func values_for(raw: Array) -> Array:
	return raw
