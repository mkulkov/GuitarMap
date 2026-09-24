extends SceneTree

const Comparison := preload("res://scripts/application/material_comparison.gd")
const Learning := preload("res://scripts/application/learning_model.gd")


func _init() -> void:
	_test_scale_catalog_comparisons()
	_test_chord_and_arpeggio_catalog_comparisons()
	_test_major_to_minor_differences()
	_test_alternate_tuning_positions()
	_test_defaults_and_invalid_requests()
	print("Material comparison tests passed: catalogs, interval deltas, tuning, and invalid input.")
	quit()


func _test_scale_catalog_comparisons() -> void:
	var model := Learning.new()
	model.topic = "scales"
	model.scale_id = "major"
	model.language = "en"
	for record: Dictionary in model.scale_records():
		var comparison := Comparison.compare(model, record.id)
		assert(comparison.valid, comparison.error)
		assert(comparison.source_name == "Major / Ionian")
		assert(comparison.target_name == record.names.en)
		assert(comparison.source_positions.size() == 150)
		assert(comparison.target_positions.size() == 150)


func _test_chord_and_arpeggio_catalog_comparisons() -> void:
	var model := Learning.new()
	model.topic = "chords"
	model.chord_id = "major"
	for record: Variant in model.chord_records():
		var comparison := Comparison.compare(model, record.id)
		assert(comparison.valid, comparison.error)
		assert(comparison.target_name == record.names.ru)
	model.topic = "arpeggios"
	for record: Variant in model.chord_records():
		assert(Comparison.compare(model, record.id).valid)


func _test_major_to_minor_differences() -> void:
	var model := Learning.new()
	model.topic = "scales"
	model.scale_id = "major"
	var scale_comparison := Comparison.compare(model, "natural_minor")
	assert(scale_comparison.valid)
	assert(scale_comparison.removed_intervals == [4, 9, 11])
	assert(scale_comparison.added_intervals == [3, 8, 10])

	model.topic = "chords"
	model.chord_id = "major"
	var chord_comparison := Comparison.compare(model, "minor")
	assert(chord_comparison.common_intervals == [0, 7])
	assert(chord_comparison.removed_intervals == [4])
	assert(chord_comparison.added_intervals == [3])


func _test_alternate_tuning_positions() -> void:
	var model := Learning.new()
	model.topic = "scales"
	model.scale_id = "major"
	model.tuning = PackedInt32Array([28, 33, 38, 43])
	var comparison := Comparison.compare(model, "natural_minor")
	assert(comparison.valid)
	assert(comparison.source_positions.size() == 100)
	assert(comparison.target_positions.size() == 100)
	for positions: Array in [comparison.source_positions, comparison.target_positions]:
		for string_index in range(4):
			for fret in range(25):
				var position: Dictionary = positions[string_index * 25 + fret]
				assert(position.string_index == string_index)
				assert(position.fret == fret)
				assert(position.midi_note == [28, 33, 38, 43][string_index] + fret)


func _test_defaults_and_invalid_requests() -> void:
	var model := Learning.new()
	model.topic = "scales"
	model.scale_id = "major"
	assert(Comparison.default_target_id(model) == "natural_minor")
	model.topic = "chords"
	assert(Comparison.default_target_id(model) == "minor")
	model.chord_id = "minor"
	assert(Comparison.default_target_id(model) == "major")
	var original_scale_id := model.scale_id
	var invalid := Comparison.compare(model, "missing")
	assert(not invalid.valid)
	assert(not invalid.error.is_empty())
	assert(invalid.source_positions.is_empty())
	assert(model.scale_id == original_scale_id)
	model.topic = "caged"
	assert(not Comparison.compare(model, "major").valid)
