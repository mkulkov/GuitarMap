class_name ChordDefinition
extends RefCounted

const CATALOG_PATH := "res://data/chords.json"

var id: String
var name_key: String
var category: String
var intervals: PackedInt32Array
var aliases: PackedStringArray
var names: Dictionary


func _init(raw: Dictionary) -> void:
	var errors := validation_errors(raw)
	assert(errors.is_empty(), "Invalid chord definition: %s" % "; ".join(errors))
	id = raw.id
	name_key = raw.name_key
	category = raw.category
	intervals = _packed_intervals(raw.intervals)
	aliases = _packed_strings(raw.get("aliases", []))
	names = raw.names.duplicate(true)


static func load_catalog(path: String = CATALOG_PATH) -> Dictionary:
	var document := _read_document(path)
	if not document.ok:
		return document
	var errors := PackedStringArray()
	var catalog := {}
	var aliases := {}
	var raw_chords: Variant = document.document.get("chords", null)
	if not raw_chords is Array:
		errors.append("%s: 'chords' must be an array." % path)
		return _failure(errors)
	for raw_chord: Variant in raw_chords:
		if not raw_chord is Dictionary:
			errors.append("%s: Chord records must be objects." % path)
			continue
		var record_errors := validation_errors(raw_chord)
		var record_id := str(raw_chord.get("id", "<missing id>"))
		for error in record_errors:
			errors.append("%s [%s]: %s" % [path, record_id, error])
		if not record_errors.is_empty():
			continue
		if catalog.has(record_id):
			errors.append("%s [%s]: Duplicate id." % [path, record_id])
			continue
		var conflicts := false
		for alias: String in raw_chord.get("aliases", []):
			if alias == record_id or catalog.has(alias) or aliases.has(alias):
				errors.append("%s [%s]: Duplicate alias '%s'." % [path, record_id, alias])
				conflicts = true
		if conflicts:
			continue
		catalog[record_id] = ChordDefinition.new(raw_chord)
		for alias: String in raw_chord.get("aliases", []):
			aliases[alias] = record_id
	return {"ok": errors.is_empty(), "catalog": catalog if errors.is_empty() else {}, "errors": errors}


static func validation_errors(raw: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not raw is Dictionary:
		errors.append("Chord definition must be an object.")
		return errors
	for key in ["id", "name_key", "category"]:
		if not raw.get(key, null) is String or str(raw.get(key, "")).is_empty():
			errors.append("'%s' must be a non-empty string." % key)
	if not raw.get("names", null) is Dictionary:
		errors.append("'names' must be an object with ru and en strings.")
	else:
		for language in ["ru", "en"]:
			if not raw.names.get(language, null) is String or str(raw.names.get(language, "")).is_empty():
				errors.append("names.%s must be a non-empty string." % language)
	if not raw.get("intervals", null) is Array:
		errors.append("'intervals' must be an array.")
		return errors
	var intervals: Array = raw.intervals
	if intervals.is_empty():
		errors.append("Intervals must not be empty.")
		return errors
	var seen := {}
	var previous := -1
	var has_root := false
	for value in intervals:
		var interval_value: Variant = _whole_number(value)
		if interval_value == null:
			errors.append("Interval values must be integers.")
			continue
		var interval: int = interval_value
		if interval < 0 or interval > 11:
			errors.append("Interval %d must be between 0 and 11." % interval)
			continue
		if seen.has(interval):
			errors.append("Interval %d is duplicated." % interval)
			continue
		if interval <= previous:
			errors.append("Intervals must be in strictly ascending order.")
			continue
		seen[interval] = true
		previous = interval
		has_root = has_root or interval == 0
	if not has_root:
		errors.append("Intervals must contain 0 for the root.")
	_validate_aliases(raw, errors)
	return errors


func contains_interval(semitones: int) -> bool:
	return intervals.has(posmod(semitones, 12))


static func _read_document(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _failure(PackedStringArray(["%s: File does not exist." % path]))
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure(PackedStringArray(["%s: Could not open file." % path]))
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return _failure(PackedStringArray(["%s: Invalid JSON at line %d." % [path, json.get_error_line()]]))
	if not json.data is Dictionary:
		return _failure(PackedStringArray(["%s: Catalog root must be an object." % path]))
	if json.data.get("schema_version", null) != 1:
		return _failure(PackedStringArray(["%s: schema_version must be 1." % path]))
	return {"ok": true, "document": json.data, "errors": PackedStringArray()}


static func _validate_aliases(raw: Dictionary, errors: PackedStringArray) -> void:
	if not raw.has("aliases"):
		return
	if not raw.aliases is Array:
		errors.append("'aliases' must be an array.")
		return
	var seen := {}
	for alias in raw.aliases:
		if not alias is String or str(alias).is_empty():
			errors.append("Aliases must be non-empty strings.")
		elif seen.has(alias):
			errors.append("Duplicate alias '%s'." % alias)
		else:
			seen[alias] = true


static func _packed_intervals(raw: Array) -> PackedInt32Array:
	var result := PackedInt32Array()
	for value in raw:
		result.append(int(value))
	return result


static func _packed_strings(raw: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value in raw:
		result.append(str(value))
	return result


static func _failure(errors: PackedStringArray) -> Dictionary:
	return {"ok": false, "catalog": {}, "errors": errors}


static func _whole_number(value: Variant) -> Variant:
	if value is bool:
		return null
	if value is int:
		return value
	if value is float and is_finite(value) and value == floor(value):
		return int(value)
	return null
