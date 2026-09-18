class_name SettingsStore
extends RefCounted

const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://guitarmap_settings.json"

var path: String


func _init(path_value: String = DEFAULT_PATH) -> void:
	path = path_value


static func defaults() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"tonic": 9,
		"scale_id": "major",
		"study_topic": "caged",
		"caged_shape": "E",
		"study_layer": "chord",
		"chord_id": "major",
		"tuning_id": "standard",
		"custom_tuning": [],
		"fret_count": 24,
		"mirrored": false,
		"spelling": "sharp",
		"guitar_type": "acoustic",
		"master_volume": 1.0,
		"tempo_bpm": 60,
		"language": "ru",
		"display_mode": 0,
	}


func load_settings() -> Dictionary:
	if not FileAccess.file_exists(path):
		return _fallback(["%s: Settings file does not exist." % path])
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fallback(["%s: Could not open settings file." % path])
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return _fallback(["%s: Invalid JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()]])
	var validation := _validate(json.data)
	if not validation.ok:
		return _fallback(validation.errors)
	var settings: Dictionary = validation.settings
	settings["load_errors"] = PackedStringArray()
	settings["used_fallback"] = false
	return settings


func save_settings(settings: Dictionary) -> Dictionary:
	var validation := _validate(settings)
	if not validation.ok:
		return {"ok": false, "errors": validation.errors}
	var directory_path := path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(directory_path) != OK:
		return {"ok": false, "errors": PackedStringArray(["%s: Could not create settings directory." % directory_path])}
	var temporary_path := "%s.tmp-%d" % [path, Time.get_ticks_usec()]
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "errors": PackedStringArray(["%s: Could not open temporary settings file." % temporary_path])}
	file.store_string(JSON.stringify(validation.settings))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		_remove_file(temporary_path)
		return {"ok": false, "errors": PackedStringArray(["%s: Could not write settings." % temporary_path])}
	var directory := DirAccess.open(directory_path)
	if directory == null or directory.rename(temporary_path.get_file(), path.get_file()) != OK:
		_remove_file(temporary_path)
		return {"ok": false, "errors": PackedStringArray(["%s: Could not replace settings atomically." % path])}
	return {"ok": true, "errors": PackedStringArray()}


static func _validate(raw: Variant) -> Dictionary:
	var errors := PackedStringArray()
	if not raw is Dictionary:
		errors.append("Settings document must be an object.")
		return {"ok": false, "errors": errors}
	var normalized := {}
	var schema: Variant = _whole_number(raw.get("schema_version", null))
	if schema == null or int(schema) != SCHEMA_VERSION:
		errors.append("schema_version must equal %d." % SCHEMA_VERSION)
	else:
		normalized["schema_version"] = SCHEMA_VERSION
	_normalize_integer(raw, normalized, errors, "tonic", 0, 11)
	_normalize_nonempty_string(raw, normalized, errors, "scale_id")
	_normalize_nonempty_string(raw, normalized, errors, "tuning_id")
	_normalize_integer(raw, normalized, errors, "fret_count", 12, 36)
	_normalize_boolean(raw, normalized, errors, "mirrored")
	_normalize_enum(raw, normalized, errors, "spelling", ["sharp", "flat", "context"])
	if raw.has("guitar_type"):
		_normalize_enum(raw, normalized, errors, "guitar_type", ["acoustic", "electric"])
	else:
		# Compatible extension of schema 1: older saved settings use acoustic.
		normalized["guitar_type"] = "acoustic"
	_normalize_number(raw, normalized, errors, "master_volume", 0.0, 1.0)
	if raw.has("tempo_bpm"):
		_normalize_integer(raw, normalized, errors, "tempo_bpm", 30, 240)
	else:
		normalized["tempo_bpm"] = 60
	_normalize_enum(raw, normalized, errors, "language", ["ru", "en"])
	_normalize_integer(raw, normalized, errors, "display_mode", 0, 2)
	_normalize_custom_tuning(raw, normalized, errors)
	# Additive schema-1 extension: legacy files retain all existing preferences.
	var learning_defaults := defaults()
	for key in ["study_topic", "caged_shape", "study_layer", "chord_id"]:
		if not raw.has(key):
			normalized[key] = learning_defaults[key]
	if raw.has("study_topic"):
		_normalize_enum(raw, normalized, errors, "study_topic", ["scales", "chords", "arpeggios", "caged"])
	if raw.has("caged_shape"):
		_normalize_enum(raw, normalized, errors, "caged_shape", ["C", "A", "G", "E", "D"])
	if raw.has("study_layer"):
		_normalize_enum(raw, normalized, errors, "study_layer", ["roots", "chord", "scale"])
	if raw.has("chord_id"):
		_normalize_nonempty_string(raw, normalized, errors, "chord_id")
	return {"ok": errors.is_empty(), "settings": normalized, "errors": errors}


static func _normalize_integer(raw: Dictionary, normalized: Dictionary, errors: PackedStringArray, key: String, minimum: int, maximum: int) -> void:
	var value: Variant = _whole_number(raw.get(key, null))
	if value == null or int(value) < minimum or int(value) > maximum:
		errors.append("%s must be a whole number from %d to %d." % [key, minimum, maximum])
		return
	normalized[key] = int(value)


static func _normalize_nonempty_string(raw: Dictionary, normalized: Dictionary, errors: PackedStringArray, key: String) -> void:
	var value: Variant = raw.get(key, null)
	if not value is String or value.is_empty():
		errors.append("%s must be a non-empty string." % key)
		return
	normalized[key] = value


static func _normalize_boolean(raw: Dictionary, normalized: Dictionary, errors: PackedStringArray, key: String) -> void:
	var value: Variant = raw.get(key, null)
	if not value is bool:
		errors.append("%s must be a boolean." % key)
		return
	normalized[key] = value


static func _normalize_enum(raw: Dictionary, normalized: Dictionary, errors: PackedStringArray, key: String, allowed: Array) -> void:
	var value: Variant = raw.get(key, null)
	if not value is String or not allowed.has(value):
		errors.append("%s must be one of %s." % [key, ", ".join(allowed)])
		return
	normalized[key] = value


static func _normalize_number(raw: Dictionary, normalized: Dictionary, errors: PackedStringArray, key: String, minimum: float, maximum: float) -> void:
	var value: Variant = raw.get(key, null)
	if value is bool or not (value is int or value is float) or not is_finite(float(value)) or float(value) < minimum or float(value) > maximum:
		errors.append("%s must be a number from %.1f to %.1f." % [key, minimum, maximum])
		return
	normalized[key] = int(value) if float(value) == floor(float(value)) else float(value)


static func _normalize_custom_tuning(raw: Dictionary, normalized: Dictionary, errors: PackedStringArray) -> void:
	var value: Variant = raw.get("custom_tuning", null)
	if not value is Array:
		errors.append("custom_tuning must be an array.")
		return
	var notes: Array = []
	for index in value.size():
		var midi: Variant = _whole_number(value[index])
		if midi == null or int(midi) < 0 or int(midi) > 127:
			errors.append("custom_tuning[%d] must be a whole MIDI value from 0 to 127." % index)
			continue
		notes.append(int(midi))
	var tuning_id: Variant = raw.get("tuning_id", null)
	if tuning_id == "custom" and notes.is_empty():
		errors.append("custom_tuning must not be empty when tuning_id is custom.")
	elif tuning_id != "custom" and not notes.is_empty():
		errors.append("custom_tuning must be empty unless tuning_id is custom.")
	normalized["custom_tuning"] = notes


static func _whole_number(value: Variant) -> Variant:
	if value is bool:
		return null
	if value is int:
		return value
	if value is float and is_finite(value) and value == floor(value):
		return int(value)
	return null


func _fallback(errors: PackedStringArray) -> Dictionary:
	var settings := defaults()
	settings["load_errors"] = errors
	settings["used_fallback"] = true
	return settings


func _remove_file(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
