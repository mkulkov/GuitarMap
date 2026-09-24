extends SceneTree

const Box := preload("res://scripts/application/scale_box.gd")


func _init() -> void:
	var model := LearningModel.new()
	model.topic = "scales"
	model.layer = "scale"
	for scale: Dictionary in model.scales:
		model.scale_id = str(scale.id)
		for tonic in 12:
			model.tonic = tonic
			var anchor := posmod(tonic - int(model.tuning[0]), 12)
			var notes := Box.build(model, anchor)
			assert(not notes.is_empty(), "%s / %d" % [scale.id, tonic])
			var strings := {}
			for index in notes.size():
				var note: Dictionary = notes[index]
				strings[note.string_index] = true
				assert(note.in_scale)
				assert(int(note.midi_note) == int(model.tuning[int(note.string_index)]) + int(note.fret))
				if index > 0: assert(int(notes[index - 1].midi_note) < int(note.midi_note))
			assert(strings.size() == 6)
	model.tonic = 9
	model.scale_id = "minor_pentatonic"
	var first := Box.build(model, 5)
	assert(first.map(func(p: Dictionary): return int(p.fret)) == [5, 8, 5, 7, 5, 7, 5, 7, 5, 8, 5, 8])
	var second := Box.build(model, 8)
	assert(second.map(func(p: Dictionary): return int(p.fret)) == [8, 10, 7, 10, 7, 10, 7, 9, 8, 10, 8, 10])
	for anchor in [5, 8, 10, 12, 15]:
		assert(Box.build(model, anchor).size() == 12)
	model.scale_id = "major"
	assert(Box.build(model, 5, true).size() == 18)
	model.tuning = PackedInt32Array([38, 45, 50, 55, 59, 64])
	assert(not Box.build(model, 7).is_empty())
	model.tuning = PackedInt32Array([28, 33, 38, 43])
	assert(Box.build(model, 5, true).size() == 12)
	print("Scale boxes passed: 21 scales x 12 roots, six strings, five pentatonic boxes, 3NPS, alternate tuning.")
	quit()
