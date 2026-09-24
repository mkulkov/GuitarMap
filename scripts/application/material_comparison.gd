class_name MaterialComparison
extends RefCounted

const Learning := preload("res://scripts/application/learning_model.gd")
const GuitarTuning := preload("res://scripts/domain/tuning.gd")


static func compare(source: LearningModel, target_id: String) -> Dictionary:
	var result := _empty_result()
	if source == null:
		result.error = "A learning model is required."
		return result

	var topic := source.topic.to_lower()
	if not topic in ["scales", "chords", "arpeggios"]:
		result.error = "Comparison is available for scales, chords, and arpeggios."
		return result
	if not source.errors.is_empty():
		result.error = "; ".join(source.errors)
		return result

	var source_material: Variant = _material_for(source, topic, _source_id(source, topic))
	var target_material: Variant = _material_for(source, topic, target_id)
	if _is_missing(source_material):
		result.error = "Unknown source %s '%s'." % [_material_label(topic), _source_id(source, topic)]
		return result
	if _is_missing(target_material):
		result.error = "Unknown target %s '%s'." % [_material_label(topic), target_id]
		return result

	var source_intervals := _sorted_intervals(source_material.intervals)
	var target_intervals := _sorted_intervals(target_material.intervals)
	result.common_intervals = _intersection(source_intervals, target_intervals)
	result.removed_intervals = _difference(source_intervals, target_intervals)
	result.added_intervals = _difference(target_intervals, source_intervals)
	result.source_name = _localized_name(source_material, source.language, _source_id(source, topic))
	result.target_name = _localized_name(target_material, source.language, target_id)

	var target_model := _copy_model(source)
	if topic == "scales":
		target_model.scale_id = str(target_material.id)
	else:
		target_model.chord_id = str(target_material.id)
	result.source_positions = source.positions()
	result.target_positions = target_model.positions()
	result.valid = true
	return result


static func default_target_id(model: LearningModel) -> String:
	if model == null:
		return "major"
	var topic := model.topic.to_lower()
	var source_id := _source_id(model, topic)
	if topic == "scales" and source_id == "major":
		return "natural_minor"
	if topic in ["chords", "arpeggios"] and source_id == "major":
		return "minor"
	return "major"


static func _empty_result() -> Dictionary:
	return {
		"common_intervals": [],
		"removed_intervals": [],
		"added_intervals": [],
		"source_positions": [],
		"target_positions": [],
		"source_name": "",
		"target_name": "",
		"valid": false,
		"error": "",
	}


static func _source_id(model: LearningModel, topic: String) -> String:
	return model.scale_id if topic == "scales" else model.chord_id


static func _material_for(model: LearningModel, topic: String, material_id: String) -> Variant:
	if topic == "scales":
		for record: Dictionary in model.scales:
			if record.id == material_id or record.get("aliases", []).has(material_id):
				return record
		return {}
	if model.chords.has(material_id):
		return model.chords[material_id]
	for record: Variant in model.chords.values():
		if record.aliases.has(material_id):
			return record
	return {}


static func _is_missing(material: Variant) -> bool:
	return material is Dictionary and material.is_empty()


static func _copy_model(source: LearningModel) -> LearningModel:
	var copy := Learning.new()
	copy.tonic = source.tonic
	copy.scale_id = source.scale_id
	copy.topic = source.topic
	copy.shape = source.shape
	copy.layer = source.layer
	copy.tuning = _copy_tuning(source.tuning)
	copy.chord_id = source.chord_id
	copy.spelling = source.spelling
	copy.language = source.language
	copy.fret_count = source.fret_count
	copy.scales = source.scales.duplicate(true)
	copy.chords = source.chords.duplicate()
	return copy


static func _copy_tuning(tuning: Variant) -> Variant:
	if tuning is GuitarTuning:
		return GuitarTuning.new(tuning.display_name, tuning.open_string_midi, tuning.id, tuning.name_key)
	if tuning is PackedInt32Array or tuning is PackedInt64Array or tuning is Array:
		return tuning.duplicate()
	return tuning


static func _sorted_intervals(raw_intervals: Variant) -> Array:
	var intervals: Array[int] = []
	for raw_interval: Variant in raw_intervals:
		var interval := int(raw_interval)
		if not intervals.has(interval):
			intervals.append(interval)
	intervals.sort()
	return intervals


static func _intersection(left: Array, right: Array) -> Array:
	var result: Array[int] = []
	for interval: int in left:
		if right.has(interval):
			result.append(interval)
	return result


static func _difference(left: Array, right: Array) -> Array:
	var result: Array[int] = []
	for interval: int in left:
		if not right.has(interval):
			result.append(interval)
	return result


static func _localized_name(material: Variant, language: String, fallback: String) -> String:
	var locale := "en" if language.to_lower().begins_with("en") else "ru"
	if material is Dictionary:
		return str(material.get("names", {}).get(locale, fallback))
	return str(material.names.get(locale, fallback))


static func _material_label(topic: String) -> String:
	return "scale" if topic == "scales" else "chord"
