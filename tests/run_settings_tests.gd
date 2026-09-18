extends SceneTree

const SettingsStore := preload("res://scripts/infrastructure/settings_store.gd")

var settings_path := "user://guitarmap_settings_tests_%d.json" % Time.get_ticks_usec()


func _init() -> void:
	_test_missing_file_uses_defaults()
	_test_round_trip_normalizes_integral_floats()
	_test_corrupt_file_uses_defaults_without_rewrite()
	_test_invalid_saved_file_uses_defaults()
	_test_invalid_save_preserves_valid_file()
	_test_valid_save_replaces_existing_file()
	_test_custom_tuning_rules()
	_test_guitar_type_is_compatible_and_validated()
	_test_schema_mismatch_uses_defaults()
	_test_learning_state_round_trip_and_legacy()
	_cleanup()
	print("Settings tests passed: fallback, validation, atomic save, custom tuning, and schema version.")
	quit()


func _test_missing_file_uses_defaults() -> void:
	_remove(settings_path)
	var loaded := SettingsStore.new(settings_path).load_settings()
	assert(loaded.used_fallback)
	assert(not loaded.load_errors.is_empty())
	assert(loaded.tonic == SettingsStore.defaults().tonic)
	assert(not FileAccess.file_exists(settings_path))


func _test_round_trip_normalizes_integral_floats() -> void:
	var store := SettingsStore.new(settings_path)
	var settings := SettingsStore.defaults()
	settings.tonic = 0.0
	settings.fret_count = 12.0
	settings.master_volume = 1.0
	settings.display_mode = 1.0
	assert(store.save_settings(settings).ok)
	var loaded := store.load_settings()
	assert(not loaded.used_fallback)
	assert(loaded.tonic is int)
	assert(loaded.tonic == 0)
	assert(loaded.fret_count is int)
	assert(loaded.display_mode == 1)


func _test_corrupt_file_uses_defaults_without_rewrite() -> void:
	_write_text(settings_path, "{ malformed")
	var loaded := SettingsStore.new(settings_path).load_settings()
	assert(loaded.used_fallback)
	assert(_read_text(settings_path) == "{ malformed")


func _test_invalid_saved_file_uses_defaults() -> void:
	var invalid := SettingsStore.defaults()
	invalid.tonic = true
	_write_text(settings_path, JSON.stringify(invalid))
	var loaded := SettingsStore.new(settings_path).load_settings()
	assert(loaded.used_fallback)
	assert(loaded.tonic == SettingsStore.defaults().tonic)
	assert(_read_text(settings_path).contains("true"))


func _test_invalid_save_preserves_valid_file() -> void:
	var store := SettingsStore.new(settings_path)
	var valid := SettingsStore.defaults()
	valid.language = "en"
	assert(store.save_settings(valid).ok)
	var before := _read_text(settings_path)
	var invalid := valid.duplicate(true)
	invalid.master_volume = true
	var result := store.save_settings(invalid)
	assert(not result.ok)
	assert(not result.errors.is_empty())
	assert(_read_text(settings_path) == before)
	assert(store.load_settings().language == "en")


func _test_valid_save_replaces_existing_file() -> void:
	var store := SettingsStore.new(settings_path)
	var first := SettingsStore.defaults()
	first.language = "ru"
	first.tonic = 2
	assert(store.save_settings(first).ok)
	var second := SettingsStore.defaults()
	second.language = "en"
	second.tonic = 7
	assert(store.save_settings(second).ok)
	var loaded := store.load_settings()
	assert(not loaded.used_fallback)
	assert(loaded.language == "en")
	assert(loaded.tonic == 7)


func _test_custom_tuning_rules() -> void:
	var store := SettingsStore.new(settings_path)
	var custom := SettingsStore.defaults()
	custom.tuning_id = "custom"
	custom.custom_tuning = [40.0, 45, 50, 55, 59, 64]
	assert(store.save_settings(custom).ok)
	var loaded := store.load_settings()
	assert(loaded.tuning_id == "custom")
	assert(loaded.custom_tuning == [40, 45, 50, 55, 59, 64])
	custom.custom_tuning = []
	assert(not store.save_settings(custom).ok)
	custom.tuning_id = "standard"
	custom.custom_tuning = [40]
	assert(not store.save_settings(custom).ok)


func _test_guitar_type_is_compatible_and_validated() -> void:
	var store := SettingsStore.new(settings_path)
	var electric := SettingsStore.defaults()
	electric.guitar_type = "electric"
	assert(store.save_settings(electric).ok)
	assert(store.load_settings().guitar_type == "electric")
	var legacy := SettingsStore.defaults()
	legacy.erase("guitar_type")
	_write_text(settings_path, JSON.stringify(legacy))
	assert(store.load_settings().guitar_type == "acoustic")
	electric.guitar_type = "piano"
	assert(not store.save_settings(electric).ok)


func _test_schema_mismatch_uses_defaults() -> void:
	var mismatched := SettingsStore.defaults()
	mismatched.schema_version = 2
	_write_text(settings_path, JSON.stringify(mismatched))
	var loaded := SettingsStore.new(settings_path).load_settings()
	assert(loaded.used_fallback)
	assert(str(loaded.load_errors).contains("schema_version"))


func _test_learning_state_round_trip_and_legacy() -> void:
	var store := SettingsStore.new(settings_path)
	var state := SettingsStore.defaults()
	state.study_topic = "arpeggios"
	state.caged_shape = "G"
	state.study_layer = "roots"
	state.chord_id = "minor_7"
	assert(store.save_settings(state).ok)
	var loaded := store.load_settings()
	assert(loaded.study_topic == "arpeggios" and loaded.caged_shape == "G")
	assert(loaded.study_layer == "roots" and loaded.chord_id == "minor_7")
	for key in ["study_topic", "caged_shape", "study_layer", "chord_id"]:
		state.erase(key)
	_write_text(settings_path, JSON.stringify(state))
	loaded = store.load_settings()
	assert(not loaded.used_fallback)
	assert(loaded.study_topic == "caged" and loaded.caged_shape == "E")
	state.caged_shape = "F"
	assert(not store.save_settings(state).ok)


func _write_text(file_path: String, content: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(content)
	file.close()


func _read_text(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	assert(file != null)
	var content := file.get_as_text()
	file.close()
	return content


func _remove(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		assert(DirAccess.remove_absolute(file_path) == OK)


func _cleanup() -> void:
	_remove(settings_path)
	var directory := DirAccess.open("user://")
	if directory == null:
		return
	for file_name in directory.get_files():
		if file_name.begins_with(settings_path.get_file() + ".tmp-"):
			assert(directory.remove(file_name) == OK)
