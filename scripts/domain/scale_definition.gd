class_name ScaleDefinition
extends RefCounted

enum NoteRole { ROOT, CHARACTERISTIC, SECONDARY }

var id: String
var name_key: String
var category: String
var intervals: PackedInt32Array
var degree_labels: PackedStringArray
var aliases: PackedStringArray
var metadata: Dictionary
var characteristic_offsets: PackedInt32Array


func _init(
		id_value: String,
		name_key_value: String,
		category_value: String,
		intervals_value: Array,
		degree_labels_value: Array = [],
		aliases_value: Array = [],
		metadata_value: Dictionary = {}
) -> void:
	var errors := validation_errors(intervals_value)
	assert(errors.is_empty(), "Invalid scale intervals: %s" % "; ".join(errors))
	assert(
		degree_labels_value.is_empty() or degree_labels_value.size() == intervals_value.size(),
		"Degree labels must be empty or match the number of intervals."
	)
	id = id_value
	name_key = name_key_value
	category = category_value
	intervals = _to_packed_intervals(intervals_value)
	degree_labels = _to_packed_strings(degree_labels_value)
	aliases = _to_packed_strings(aliases_value)
	metadata = metadata_value.duplicate(true)
	characteristic_offsets = _to_packed_intervals(metadata.get("characteristic_offsets", []))


static func validation_errors(raw: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	if raw.is_empty():
		errors.append("Intervals must not be empty.")
		return errors

	var seen := {}
	var has_root := false
	var previous_interval := -1
	for value in raw:
		if not value is int:
			errors.append("Interval values must be integers.")
			continue
		var interval: int = value
		if interval < 0 or interval > 11:
			errors.append("Interval %d must be between 0 and 11." % interval)
			continue
		if seen.has(interval):
			errors.append("Interval %d is duplicated." % interval)
			continue
		if interval <= previous_interval:
			errors.append("Intervals must be in strictly ascending order.")
			continue
		seen[interval] = true
		previous_interval = interval
		has_root = has_root or interval == 0
	if not has_root:
		errors.append("Intervals must contain 0 for the tonic.")
	return errors


func contains_interval(semitones: int) -> bool:
	return intervals.has(posmod(semitones, 12))


func note_role(interval_from_root: int) -> NoteRole:
	var normalized := posmod(interval_from_root, 12)
	if normalized == 0:
		return NoteRole.ROOT
	if characteristic_offsets.has(normalized):
		return NoteRole.CHARACTERISTIC
	return NoteRole.SECONDARY


static func _to_packed_intervals(raw: Array) -> PackedInt32Array:
	var result := PackedInt32Array()
	for value in raw:
		result.append(value)
	return result


static func _to_packed_strings(raw: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value in raw:
		result.append(str(value))
	return result
