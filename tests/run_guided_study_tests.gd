extends SceneTree

const Learning := preload("res://scripts/application/learning_model.gd")
const GuidedStudy := preload("res://scripts/application/guided_study.gd")


func _init() -> void:
	_test_steps_cover_topics_and_languages()
	_test_caged_warning()
	_test_scale_route_is_complete_and_playable()
	_test_chord_route_and_custom_tuning()
	_test_finger_annotations()
	print("Guided study tests passed: topic lessons, CAGED warning, octave routes, custom tuning, and suggested fingers.")
	quit()


func _test_steps_cover_topics_and_languages() -> void:
	var model := Learning.new()
	for topic: String in ["scales", "chords", "arpeggios", "caged"]:
		model.topic = topic
		var lesson := GuidedStudy.steps(model)
		assert(not lesson.is_empty(), topic)
		for step: Dictionary in lesson:
			for key in ["title", "body", "layer", "listen", "highlight_intervals"]:
				assert(step.has(key), "%s missing %s" % [topic, key])
			assert(not str(step.title).is_empty())
		assert(lesson.any(func(step: Dictionary) -> bool: return step.layer == "roots"))
		assert(lesson.any(func(step: Dictionary) -> bool: return step.layer == "scale"))
		if topic == "scales":
			assert(lesson.filter(func(step: Dictionary) -> bool: return step.layer == "scale").all(func(step: Dictionary) -> bool: return step.highlight_intervals.is_empty()))
		if topic == "chords":
			var chord_steps := lesson.filter(func(step: Dictionary) -> bool: return step.layer == "chord" and not step.listen)
			assert(chord_steps.size() >= 2)
			assert(chord_steps[0].highlight_intervals == [0, 4])
			assert(chord_steps[1].highlight_intervals == [0, 4, 7])
	model.language = "en"
	model.topic = "chords"
	assert(GuidedStudy.steps(model)[0].title.begins_with("Find"))
	model.chord_id = "sus4"
	var sus_steps := GuidedStudy.steps(model)
	assert(sus_steps.any(func(step: Dictionary) -> bool: return step.title.contains("fourth")))
	assert(not sus_steps.any(func(step: Dictionary) -> bool: return step.title.contains("third")))
	model.topic = "caged"
	model.chord_id = "minor"
	var caged_minor := GuidedStudy.steps(model)
	var caged_build := caged_minor.filter(func(step: Dictionary) -> bool: return step.layer == "chord" and not step.listen)
	assert(caged_build[0].highlight_intervals == [0, 4])
	assert(caged_build[1].highlight_intervals == [0, 4, 7])


func _test_caged_warning() -> void:
	var model := Learning.new()
	model.topic = "caged"
	model.tuning = PackedInt32Array([38, 45, 50, 55, 59, 64])
	var lesson := GuidedStudy.steps(model)
	assert(lesson.size() == 1)
	assert(lesson[0].title.contains("недоступен"))


func _test_scale_route_is_complete_and_playable() -> void:
	var model := Learning.new()
	model.topic = "scales"
	model.scale_id = "major"
	model.tonic = 9
	model.layer = "scale"
	var route := GuidedStudy.route(model, Vector2i(0, 24))
	assert(not route.is_empty())
	assert(int(route[0].interval) == 0)
	assert(int(route[-1].interval) == 0)
	assert(int(route[-1].midi_note) == int(route[0].midi_note) + 12)
	assert(route.size() == 8)
	_assert_route_membership(route, func(position: Dictionary) -> bool: return position.in_scale)
	model.layer = "roots"
	var roots := GuidedStudy.route(model, Vector2i(0, 24))
	assert(roots.size() == 2)
	assert(roots.all(func(position: Dictionary) -> bool: return position.is_root))
	assert(int(roots[-1].midi_note) == int(roots[0].midi_note) + 12)
	model.layer = "chord"
	var chord_layer := GuidedStudy.route(model, Vector2i(0, 24))
	assert(chord_layer.all(func(position: Dictionary) -> bool: return position.in_chord))


func _test_chord_route_and_custom_tuning() -> void:
	var model := Learning.new()
	model.topic = "chords"
	model.chord_id = "major"
	var standard_route := GuidedStudy.route(model, Vector2i(3, 9))
	assert(standard_route.map(func(position: Dictionary) -> int: return int(position.interval)) == [0, 4, 7, 0])
	assert(int(standard_route[-1].midi_note) == int(standard_route[0].midi_note) + 12)
	model.topic = "chords"
	model.tuning = PackedInt32Array([28, 33, 38, 43])
	var route := GuidedStudy.route(model, Vector2i(0, 24))
	assert(not route.is_empty())
	assert(route.all(func(position: Dictionary) -> bool: return position.in_chord))
	_assert_route_membership(route, func(position: Dictionary) -> bool: return position.in_chord)


func _test_finger_annotations() -> void:
	var model := Learning.new()
	model.topic = "scales"
	var route := GuidedStudy.route(model, Vector2i(0, 24))
	for position: Dictionary in route:
		assert(position.has("suggested_finger"))
		var finger := int(position.suggested_finger)
		if int(position.fret) == 0:
			assert(finger == 0)
		else:
			assert(finger == -1 or (finger >= 1 and finger <= 4))
	var narrow := GuidedStudy.route(model, Vector2i(5, 8))
	for position: Dictionary in narrow:
		if int(position.fret) > 0:
			assert(int(position.suggested_finger) == -1 or int(position.suggested_finger) <= 4)


func _assert_route_membership(route: Array[Dictionary], predicate: Callable) -> void:
	var midi_notes := {}
	for index in route.size():
		var position: Dictionary = route[index]
		assert(predicate.call(position))
		var midi := int(position.midi_note)
		assert(not midi_notes.has(midi))
		midi_notes[midi] = true
		if index > 0:
			assert(midi > int(route[index - 1].midi_note))
