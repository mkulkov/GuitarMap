class_name CagedConnection
extends RefCounted


static func adjacent(model: LearningModel, direction: int) -> Dictionary:
	var current := model.caged_positions()
	if current.is_empty(): return {}
	var center := _center(current)
	var best := {}
	var distance := INF
	var probe := LearningModel.new()
	probe.tonic = model.tonic
	probe.tuning = model.tuning
	probe.fret_count = model.fret_count
	probe.spelling = model.spelling
	for shape in LearningModel.CAGED_SHAPES:
		probe.shape = shape
		for offset in [0, 12, 24]:
			probe.shape_fret_offset = offset
			var candidate := probe.caged_positions()
			if candidate.is_empty(): continue
			var difference := (_center(candidate) - center) * signi(direction)
			if difference > 0.1 and difference < distance:
				distance = difference
				best = {"shape": shape, "offset": offset, "positions": candidate}
	return best


static func _center(positions: Array[Dictionary]) -> float:
	var sum := 0.0
	for position in positions: sum += float(position.fret)
	return sum / maxf(1.0, positions.size())
