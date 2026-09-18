extends SceneTree

const Learning := preload("res://scripts/application/learning_model.gd")

const OPEN_SHAPES := {
	"C": {"tonic": 0, "positions": [[1, 3], [2, 2], [3, 0], [4, 1], [5, 0]]},
	"A": {"tonic": 9, "positions": [[1, 0], [2, 2], [3, 2], [4, 2], [5, 0]]},
	"G": {"tonic": 7, "positions": [[0, 3], [1, 2], [2, 0], [3, 0], [4, 0], [5, 3]]},
	"E": {"tonic": 4, "positions": [[0, 0], [1, 2], [2, 2], [3, 1], [4, 0], [5, 0]]},
	"D": {"tonic": 2, "positions": [[2, 0], [3, 2], [4, 3], [5, 2]]},
}


func _init() -> void:
	_test_full_chromatic_grid()
	_test_approved_a_major_e_shape()
	_test_open_shape_fingerings()
	_test_all_shapes_in_all_tonics()
	_test_tuning_compatibility()
	_test_configurable_fret_range()
	_test_layers_are_independent()
	_test_explanations_and_catalogs()
	print("Learning tests passed: full grid, theory layers, explanations, and real CAGED forms across 12 tonics.")
	quit()


func _test_full_chromatic_grid() -> void:
	var model := Learning.new()
	assert(model.errors.is_empty(), str(model.errors))
	assert(model.tonic == 9)
	assert(model.scale_id == "major")
	assert(model.topic == "caged")
	assert(model.shape == "E")
	assert(model.layer == "chord")
	var positions := model.positions()
	assert(positions.size() == 6 * 25)
	for string_index in 6:
		for fret in range(25):
			var position: Dictionary = positions[string_index * 25 + fret]
			assert(position.string_index == string_index)
			assert(position.fret == fret)
			assert(position.midi_note == [40, 45, 50, 55, 59, 64][string_index] + fret)
			assert(position.interval == posmod(position.midi_note - 9, 12))
			for key in ["note", "degree", "in_scale", "in_chord", "in_shape", "is_root", "role", "is_active"]:
				assert(position.has(key), "Missing learning-position key: %s" % key)
	assert(_at(positions, 0, 5).note == "A")
	assert(_at(positions, 0, 5).degree == "1")
	assert(_at(positions, 0, 6).note == "Bb")
	assert(not _at(positions, 0, 6).in_scale)


func _test_approved_a_major_e_shape() -> void:
	var model := Learning.new()
	model.tonic = 9
	model.shape = "E"
	var expected := [[0, 5], [1, 7], [2, 7], [3, 6], [4, 5], [5, 5]]
	assert(_coordinates(model.caged_positions()) == expected)
	assert(model.recommended_range() == Vector2i(3, 9))
	for position: Dictionary in model.caged_positions():
		assert([0, 4, 7].has(position.interval))
		assert(position.in_chord)
		assert(position.in_scale)
		assert(position.is_active)
	var explanation := model.explanation()
	assert(explanation.compatible)
	assert(explanation.title == "Форма E · A мажор")
	assert(explanation.formula == "1 · 3 · 5")
	assert(explanation.notes == "A · C# · E")
	assert(explanation.previous_shape == "G")
	assert(explanation.next_shape == "D")


func _test_open_shape_fingerings() -> void:
	var model := Learning.new()
	for shape_id: String in OPEN_SHAPES:
		model.shape = shape_id
		model.tonic = OPEN_SHAPES[shape_id].tonic
		assert(_coordinates(model.caged_positions()) == OPEN_SHAPES[shape_id].positions, shape_id)


func _test_all_shapes_in_all_tonics() -> void:
	var model := Learning.new()
	for shape_id: String in Learning.CAGED_SHAPES:
		model.shape = shape_id
		for tonic in range(12):
			model.tonic = tonic
			var shape_positions := model.caged_positions()
			assert(shape_positions.size() == Learning.CAGED_TEMPLATES[shape_id].offsets.size())
			assert(shape_positions.any(func(position: Dictionary) -> bool: return position.is_root))
			for position: Dictionary in shape_positions:
				assert(position.fret >= 0 and position.fret <= 24)
				assert([0, 4, 7].has(position.interval), "%s tonic %d: %s" % [shape_id, tonic, position])
				assert(posmod(position.midi_note, 12) == posmod([40, 45, 50, 55, 59, 64][position.string_index] + position.fret, 12))


func _test_tuning_compatibility() -> void:
	var model := Learning.new()
	model.tuning = PackedInt32Array([38, 43, 48, 53, 57, 62])
	assert(model.is_caged_compatible())
	for shape_id: String in Learning.CAGED_SHAPES:
		model.shape = shape_id
		for tonic in range(12):
			model.tonic = tonic
			for position: Dictionary in model.caged_positions():
				assert([0, 4, 7].has(position.interval))

	model.tuning = PackedInt32Array([38, 45, 50, 55, 59, 64])
	assert(not model.is_caged_compatible())
	assert(model.caged_positions().is_empty())
	assert(not model.explanation().compatible)
	assert(not model.explanation().message.is_empty())
	assert(model.positions().size() == 150)

	model.tuning = PackedInt32Array([28, 33, 38, 43])
	assert(model.positions().size() == 100)
	assert(not model.is_caged_compatible())


func _test_configurable_fret_range() -> void:
	var model := Learning.new()
	model.fret_count = 36
	assert(model.positions().size() == 6 * 37)
	model.fret_count = 3
	assert(model.positions().size() == 6 * 13)
	model.fret_count = 99
	assert(model.positions().size() == 6 * 37)

	model.fret_count = 12
	model.tonic = 0
	model.shape = "D"
	assert(model.is_caged_compatible())
	assert(model.caged_positions().is_empty())
	var details := model.explanation()
	assert(details.compatible)
	assert(not details.available_in_range)
	assert(details.message.contains("лады"))
	assert(model.recommended_range().y > 12)
	model.fret_count = 24
	assert(not model.caged_positions().is_empty())


func _test_layers_are_independent() -> void:
	var model := Learning.new()
	model.tonic = 9
	model.shape = "E"
	model.scale_id = "natural_minor"
	var major_third := _at(model.positions(), 3, 6)
	assert(major_third.in_shape)
	assert(major_third.in_chord)
	assert(not major_third.in_scale)

	model.layer = "roots"
	var root_count := model.positions().filter(func(position: Dictionary) -> bool: return position.is_active).size()
	assert(root_count == model.caged_positions().filter(func(position: Dictionary) -> bool: return position.is_root).size())
	model.layer = "scale"
	assert(model.positions().filter(func(position: Dictionary) -> bool: return position.is_active).all(func(position: Dictionary) -> bool: return position.in_scale))
	model.topic = "chords"
	assert(model.positions().filter(func(position: Dictionary) -> bool: return position.is_active).all(func(position: Dictionary) -> bool: return position.in_chord))
	model.topic = "caged"
	var details := model.explanation()
	assert(not details.scale_overlay_compatible)
	assert(not details.message.is_empty())
	model.scale_id = "major"
	model.chord_id = "minor"
	details = model.explanation()
	assert(not details.chord_overlay_compatible)
	assert(details.message.contains("аккорд"))


func _test_explanations_and_catalogs() -> void:
	var model := Learning.new()
	assert(model.scale_records().size() == 21)
	assert(model.chord_records().size() == 9)
	for topic_id in ["scales", "chords", "arpeggios", "caged"]:
		model.topic = topic_id
		var details := model.explanation()
		for key in ["title", "formula", "notes", "body", "compatible", "message"]:
			assert(details.has(key), "%s missing %s" % [topic_id, key])
		assert(not details.title.is_empty())
		assert(not details.formula.is_empty())
		assert(not details.notes.is_empty())
		assert(not details.body.is_empty())
	model.topic = "caged"
	model.language = "en"
	var english := model.explanation()
	assert(english.language == "en")
	assert(english.title == "E shape · A major")
	assert(english.body.contains("Movable E shape"))

	model.tuning = PackedInt32Array([120, 120, 120, 120, 120, 120])
	for position: Dictionary in model.positions():
		assert(position.midi_note <= 127)


func _coordinates(positions: Array) -> Array:
	return positions.map(func(position: Dictionary) -> Array: return [position.string_index, position.fret])


func _at(positions: Array, string_index: int, fret: int) -> Dictionary:
	return positions[string_index * 25 + fret]
