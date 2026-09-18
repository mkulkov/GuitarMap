class_name JsonCatalogLoader
extends RefCounted

const Validator := preload("res://scripts/data/catalog_validator.gd")

static func load_catalog(path: String, kind: String) -> Dictionary:
	var errors := PackedStringArray()
	if not FileAccess.file_exists(path):
		errors.append("%s: File does not exist." % path)
		return {"ok": false, "records": [], "errors": errors}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("%s: Could not open file." % path)
		return {"ok": false, "records": [], "errors": errors}
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		errors.append("%s: Invalid JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {"ok": false, "records": [], "errors": errors}
	return Validator.validate_catalog(json.data, kind, path)


static func load_with_fallback(builtin_path: String, user_path: String, kind: String) -> Dictionary:
	var builtin := load_catalog(builtin_path, kind)
	if not builtin.ok:
		return {"ok": false, "records": [], "errors": builtin.errors, "used_fallback": false}
	var builtin_records: Array = builtin.records.duplicate(true)
	if user_path.is_empty() or not FileAccess.file_exists(user_path):
		return {"ok": true, "records": builtin_records, "errors": PackedStringArray(), "used_fallback": false}

	var user := load_catalog(user_path, kind)
	if not user.ok:
		return {"ok": true, "records": builtin_records, "errors": user.errors, "used_fallback": true}
	var combined: Array = builtin_records.duplicate(true)
	combined.append_array(user.records)
	var merged_document := {"schema_version": Validator.SCHEMA_VERSION, _catalog_key(kind): combined}
	var merged := Validator.validate_catalog(merged_document, kind, "%s + %s" % [builtin_path, user_path])
	if not merged.ok:
		return {"ok": true, "records": builtin_records, "errors": merged.errors, "used_fallback": true}
	return {"ok": true, "records": merged.records, "errors": PackedStringArray(), "used_fallback": false}


static func _catalog_key(kind: String) -> String:
	return "scales" if kind == "scale" or kind == "scales" else "tunings"
