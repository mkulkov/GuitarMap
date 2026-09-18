extends SceneTree

const Loader := preload("res://scripts/data/json_catalog_loader.gd")
const IntervalDefinition := preload("res://scripts/domain/interval.gd")

var temp_directory := "user://guitarmap_catalog_tests_%d" % Time.get_ticks_usec()


func _init() -> void:
	DirAccess.make_dir_absolute(temp_directory)
	_test_valid_scale_normalizes_whole_numbers()
	_test_malformed_json_is_rejected()
	_test_duplicate_aliases_are_rejected()
	_test_self_alias_is_rejected()
	_test_tiny_fraction_is_rejected()
	_test_degree_labels_match_intervals()
	_test_invalid_tuning_is_rejected()
	_test_fallback_keeps_pristine_builtin_records()
	_cleanup()
	print("Catalog tests passed: validation, normalization, malformed data, and fallback.")
	quit()


func _test_valid_scale_normalizes_whole_numbers() -> void:
	var path := _write("valid_scales.json", {
		"schema_version": 1.0,
		"scales": [{
			"id": "major", "name_key": "scale.major", "category": "diatonic",
			"intervals": [0.0, 2.0, 4.0, 5.0, 7.0, 9.0, 11.0],
			"degree_labels": ["1", "2", "3", "4", "5", "6", "7"],
			"aliases": ["ionian"], "names": {"ru": "Мажор", "en": "Major"},
		}]
	})
	var result := Loader.load_catalog(path, "scales")
	assert(result.ok)
	assert(result.records.size() == 1)
	assert(result.records[0].intervals == [0, 2, 4, 5, 7, 9, 11])


func _test_malformed_json_is_rejected() -> void:
	var path := temp_directory.path_join("broken.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{ invalid json")
	file.close()
	var result := Loader.load_catalog(path, "scales")
	assert(not result.ok)
	assert(result.records.is_empty())
	assert(not result.errors.is_empty())


func _test_duplicate_aliases_are_rejected() -> void:
	var path := _write("duplicate_alias.json", {
		"schema_version": 1,
		"scales": [
			_scale("major", [0, 2, 4, 5, 7, 9, 11], ["ionian"]),
			_scale("minor", [0, 2, 3, 5, 7, 8, 10], ["ionian"]),
		]
	})
	var result := Loader.load_catalog(path, "scales")
	assert(not result.ok)
	assert(result.records.is_empty())
	assert(str(result.errors).contains(path))
	assert(str(result.errors).contains("minor"))


func _test_invalid_tuning_is_rejected() -> void:
	var path := _write("invalid_tunings.json", {
		"schema_version": 1,
		"tunings": [{
			"id": "bad", "name_key": "tuning.bad", "open_string_midi": [40.5],
			"names": {"ru": "Некорректный", "en": "Invalid"},
		}]
	})
	var result := Loader.load_catalog(path, "tunings")
	assert(not result.ok)
	assert(result.records.is_empty())


func _test_self_alias_is_rejected() -> void:
	var path := _write("self_alias.json", {
		"schema_version": 1,
		"scales": [_scale("major", [0, 2, 4, 5, 7, 9, 11], ["major"])]
	})
	assert(not Loader.load_catalog(path, "scales").ok)


func _test_tiny_fraction_is_rejected() -> void:
	var path := _write("tiny_fraction.json", {
		"schema_version": 1.0000001,
		"scales": [_scale("major", [0, 2, 4, 5, 7, 9, 11])]
	})
	assert(not Loader.load_catalog(path, "scales").ok)


func _test_degree_labels_match_intervals() -> void:
	var record := _scale("major", [0, 2, 4, 5, 7, 9, 11])
	record.degree_labels[3] = "#4"
	var path := _write("bad_labels.json", {"schema_version": 1, "scales": [record]})
	assert(not Loader.load_catalog(path, "scales").ok)


func _test_fallback_keeps_pristine_builtin_records() -> void:
	var builtin_path := _write("builtin.json", {
		"schema_version": 1,
		"scales": [_scale("major", [0, 2, 4, 5, 7, 9, 11])]
	})
	var user_path := _write("user.json", {
		"schema_version": 1,
		"scales": [_scale("major", [0, 3, 5, 7, 10])]
	})
	var result := Loader.load_with_fallback(builtin_path, user_path, "scales")
	assert(result.ok)
	assert(result.used_fallback)
	assert(result.records.size() == 1)
	assert(result.records[0].id == "major")
	assert(not result.errors.is_empty())
	result.records[0].id = "mutated"
	var reloaded := Loader.load_catalog(builtin_path, "scales")
	assert(reloaded.records[0].id == "major")


func _scale(id: String, intervals: Array, aliases: Array = []) -> Dictionary:
	var labels: Array = []
	for interval in intervals:
		labels.append(IntervalDefinition.new(interval).degree_label)
	return {
		"id": id, "name_key": "scale.%s" % id, "category": "test",
		"intervals": intervals, "degree_labels": labels, "aliases": aliases,
		"names": {"ru": id, "en": id},
	}


func _write(file_name: String, document: Dictionary) -> String:
	var path := temp_directory.path_join(file_name)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(document))
	file.close()
	return path


func _cleanup() -> void:
	var directory := DirAccess.open(temp_directory)
	if directory == null:
		return
	for file_name in directory.get_files():
		directory.remove(file_name)
	DirAccess.remove_absolute(temp_directory)
