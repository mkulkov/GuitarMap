class_name PracticeStatsStore
extends RefCounted

## Versioned aggregate practice statistics. Reads never rewrite a damaged file.

const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://guitarmap_practice_stats.json"

var path: String


func _init(path_value: String = DEFAULT_PATH) -> void:
	path = path_value


static func defaults() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"sessions": 0,
		"attempts": 0,
		"correct": 0,
		"best_streak": 0,
	}


func load_stats() -> Dictionary:
	if not FileAccess.file_exists(path):
		return _fallback(["%s: Practice statistics file does not exist." % path])
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fallback(["%s: Could not open practice statistics file." % path])
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return _fallback(["%s: Invalid JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()]])
	var validation := _validate(json.data)
	if not validation.ok:
		return _fallback(validation.errors)
	var stats: Dictionary = validation.stats
	stats["load_errors"] = PackedStringArray()
	stats["used_fallback"] = false
	return stats


func save_stats(stats: Dictionary) -> Dictionary:
	var validation := _validate(stats)
	if not validation.ok:
		return {"ok": false, "errors": validation.errors}
	var directory_path := path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(directory_path) != OK:
		return {"ok": false, "errors": PackedStringArray(["%s: Could not create practice statistics directory." % directory_path])}
	var temporary_path := "%s.tmp-%d" % [path, Time.get_ticks_usec()]
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "errors": PackedStringArray(["%s: Could not open temporary practice statistics file." % temporary_path])}
	file.store_string(JSON.stringify(validation.stats))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		_remove_file(temporary_path)
		return {"ok": false, "errors": PackedStringArray(["%s: Could not write practice statistics." % temporary_path])}
	var directory := DirAccess.open(directory_path)
	if directory == null or directory.rename(temporary_path.get_file(), path.get_file()) != OK:
		_remove_file(temporary_path)
		return {"ok": false, "errors": PackedStringArray(["%s: Could not replace practice statistics atomically." % path])}
	return {"ok": true, "errors": PackedStringArray()}


func record_session(session: Dictionary) -> Dictionary:
	var session_validation := _validate_session(session)
	if not session_validation.ok:
		return {"ok": false, "errors": session_validation.errors}
	var loaded := load_stats()
	var stats := defaults() if loaded.used_fallback else _strip_runtime_fields(loaded)
	stats.sessions += 1
	stats.attempts += int(session_validation.session.attempts)
	stats.correct += int(session_validation.session.correct)
	stats.best_streak = maxi(int(stats.best_streak), int(session_validation.session.best_streak))
	var saved := save_stats(stats)
	saved["stats"] = stats.duplicate(true)
	saved["recovered_from_fallback"] = bool(loaded.used_fallback)
	saved["load_errors"] = loaded.load_errors.duplicate()
	return saved


static func _validate(raw: Variant) -> Dictionary:
	var errors := PackedStringArray()
	if not raw is Dictionary:
		errors.append("Practice statistics document must be an object.")
		return {"ok": false, "errors": errors}
	var normalized := {}
	var schema: Variant = _whole_number(raw.get("schema_version", null))
	if schema == null or int(schema) != SCHEMA_VERSION:
		errors.append("schema_version must equal %d." % SCHEMA_VERSION)
	else:
		normalized["schema_version"] = SCHEMA_VERSION
	_normalize_nonnegative(raw, normalized, errors, "sessions")
	_normalize_nonnegative(raw, normalized, errors, "attempts")
	_normalize_nonnegative(raw, normalized, errors, "correct")
	_normalize_nonnegative(raw, normalized, errors, "best_streak")
	if normalized.has("correct") and normalized.has("attempts") and int(normalized.correct) > int(normalized.attempts):
		errors.append("correct cannot exceed attempts.")
	if normalized.has("best_streak") and normalized.has("attempts") and int(normalized.best_streak) > int(normalized.attempts):
		errors.append("best_streak cannot exceed attempts.")
	return {"ok": errors.is_empty(), "stats": normalized, "errors": errors}


static func _validate_session(raw: Variant) -> Dictionary:
	var errors := PackedStringArray()
	if not raw is Dictionary:
		errors.append("Practice session snapshot must be an object.")
		return {"ok": false, "errors": errors}
	var normalized := {}
	_normalize_nonnegative(raw, normalized, errors, "attempts")
	_normalize_nonnegative(raw, normalized, errors, "correct")
	_normalize_nonnegative(raw, normalized, errors, "best_streak")
	if normalized.has("correct") and normalized.has("attempts") and int(normalized.correct) > int(normalized.attempts):
		errors.append("Session correct cannot exceed attempts.")
	if normalized.has("best_streak") and normalized.has("attempts") and int(normalized.best_streak) > int(normalized.attempts):
		errors.append("Session best_streak cannot exceed attempts.")
	return {"ok": errors.is_empty(), "session": normalized, "errors": errors}


static func _normalize_nonnegative(raw: Dictionary, normalized: Dictionary, errors: PackedStringArray, key: String) -> void:
	var value: Variant = _whole_number(raw.get(key, null))
	if value == null or int(value) < 0:
		errors.append("%s must be a non-negative whole number." % key)
		return
	normalized[key] = int(value)


static func _whole_number(value: Variant) -> Variant:
	if value is bool:
		return null
	if value is int:
		return value
	if value is float and is_finite(value) and value == floor(value):
		return int(value)
	return null


func _fallback(errors: PackedStringArray) -> Dictionary:
	var stats := defaults()
	stats["load_errors"] = errors
	stats["used_fallback"] = true
	return stats


static func _strip_runtime_fields(stats: Dictionary) -> Dictionary:
	var result := defaults()
	for key in result:
		result[key] = stats[key]
	return result


func _remove_file(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
