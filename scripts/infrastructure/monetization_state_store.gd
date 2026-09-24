class_name MonetizationStateStore
extends RefCounted

const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://fret_formula_monetization.json"

var path: String


func _init(path_value: String = DEFAULT_PATH) -> void:
	path = path_value


static func defaults() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"launch_count": 0,
		"support_count": 0,
		"applied_transaction_ids": [],
	}


func load_state() -> Dictionary:
	if not FileAccess.file_exists(path):
		return defaults()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return defaults()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return _normalize(parsed)


func register_launch() -> Dictionary:
	var state := load_state()
	state.launch_count = int(state.launch_count) + 1
	var result := _save(state)
	result["launch_count"] = int(state.launch_count)
	result["should_offer"] = bool(result.ok) and int(state.support_count) == 0 \
		and int(state.launch_count) >= 5 and int(state.launch_count) <= 15 \
		and int(state.launch_count) % 5 == 0
	return result


func record_transaction(transaction_id: String) -> Dictionary:
	if transaction_id.is_empty():
		return {"ok": false, "is_new": false, "support_count": int(load_state().support_count)}
	var state := load_state()
	var transaction_ids: Array = state.applied_transaction_ids
	if transaction_ids.has(transaction_id):
		return {"ok": true, "is_new": false, "support_count": int(state.support_count)}
	transaction_ids.append(transaction_id)
	state.applied_transaction_ids = transaction_ids
	state.support_count = int(state.support_count) + 1
	var result := _save(state)
	result["is_new"] = bool(result.ok)
	result["support_count"] = int(state.support_count)
	return result


func _normalize(raw: Variant) -> Dictionary:
	if not raw is Dictionary or int(raw.get("schema_version", -1)) != SCHEMA_VERSION:
		return defaults()
	var transaction_ids: Array = []
	var raw_ids: Variant = raw.get("applied_transaction_ids", [])
	if raw_ids is Array:
		for value in raw_ids:
			var transaction_id := str(value)
			if not transaction_id.is_empty() and not transaction_ids.has(transaction_id):
				transaction_ids.append(transaction_id)
	return {
		"schema_version": SCHEMA_VERSION,
		"launch_count": maxi(0, int(raw.get("launch_count", 0))),
		"support_count": maxi(0, int(raw.get("support_count", 0))),
		"applied_transaction_ids": transaction_ids,
	}


func _save(state: Dictionary) -> Dictionary:
	var directory_path := path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(directory_path) != OK:
		return {"ok": false, "error": "directory"}
	var temporary_path := "%s.tmp-%d" % [path, Time.get_ticks_usec()]
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "open"}
	file.store_string(JSON.stringify(_normalize(state)))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		_remove(temporary_path)
		return {"ok": false, "error": "write"}
	var directory := DirAccess.open(directory_path)
	if directory == null or directory.rename(temporary_path.get_file(), path.get_file()) != OK:
		_remove(temporary_path)
		return {"ok": false, "error": "replace"}
	return {"ok": true, "error": ""}


func _remove(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
