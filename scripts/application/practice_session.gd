class_name PracticeSession
extends RefCounted

## A UI-independent note-finding exercise over a supplied fretboard model.
## The caller owns rendering and may present a task in any notation it needs.

const TARGET_MIDI := "midi"
const TARGET_PITCH_CLASS := "pitch_class"

var target_kind: String
var _positions: Array[Dictionary] = []
var _positions_by_key := {}
var _random := RandomNumberGenerator.new()
var _active_task := {}
var _task_count := 0
var _attempts := 0
var _correct := 0
var _streak := 0
var _best_streak := 0


func _init(available_positions: Array, target_kind_value: String = TARGET_MIDI, seed: int = 0) -> void:
	assert(target_kind_value == TARGET_MIDI or target_kind_value == TARGET_PITCH_CLASS, "Unsupported practice target kind.")
	target_kind = target_kind_value
	_random.seed = seed
	for raw_position in available_positions:
		var position := _normalized_position(raw_position)
		var key := _position_key(int(position.string_index), int(position.fret))
		assert(not _positions_by_key.has(key), "Practice positions must have unique string_index + fret keys.")
		_positions.append(position)
		_positions_by_key[key] = position
	assert(not _positions.is_empty(), "A practice session needs at least one available fret position.")


func next_task() -> Dictionary:
	var position: Dictionary = _positions[_random.randi_range(0, _positions.size() - 1)]
	_task_count += 1
	_active_task = {
		"id": _task_count,
		"target_kind": target_kind,
		"target_value": int(position.midi_note) if target_kind == TARGET_MIDI else posmod(int(position.midi_note), 12),
	}
	return _active_task.duplicate(true)


func submit_answer(string_index: int, fret: int) -> Dictionary:
	assert(not _active_task.is_empty(), "Generate a practice task before submitting an answer.")
	var task := _active_task.duplicate(true)
	var position: Dictionary = _positions_by_key.get(_position_key(string_index, fret), {})
	var expected: int = int(task.target_value)
	var actual: Variant = null
	if not position.is_empty():
		actual = int(position.midi_note) if target_kind == TARGET_MIDI else posmod(int(position.midi_note), 12)
	var is_correct := actual != null and int(actual) == expected
	_attempts += 1
	if is_correct:
		_correct += 1
		_streak += 1
		_best_streak = maxi(_best_streak, _streak)
	else:
		_streak = 0
	_active_task = {}
	return {
		"task": task,
		"answer": {"string_index": string_index, "fret": fret},
		"actual_value": actual,
		"correct": is_correct,
		"snapshot": snapshot(),
	}


func has_active_task() -> bool:
	return not _active_task.is_empty()


func snapshot() -> Dictionary:
	return {
		"target_kind": target_kind,
		"available_position_count": _positions.size(),
		"task_count": _task_count,
		"has_active_task": has_active_task(),
		"active_task": _active_task.duplicate(true),
		"attempts": _attempts,
		"correct": _correct,
		"streak": _streak,
		"best_streak": _best_streak,
	}


static func _normalized_position(raw_position: Variant) -> Dictionary:
	assert(raw_position is Dictionary, "Practice positions must be dictionaries from the fretboard model.")
	var string_index: Variant = raw_position.get("string_index", null)
	var fret: Variant = raw_position.get("fret", null)
	var midi_note: Variant = raw_position.get("midi_note", null)
	assert(_is_integer(string_index) and int(string_index) >= 0, "Practice position string_index must be a non-negative integer.")
	assert(_is_integer(fret) and int(fret) >= 0, "Practice position fret must be a non-negative integer.")
	assert(_is_integer(midi_note) and int(midi_note) >= 0 and int(midi_note) <= 127, "Practice position midi_note must be a MIDI integer.")
	var position: Dictionary = raw_position.duplicate(true)
	position["string_index"] = int(string_index)
	position["fret"] = int(fret)
	position["midi_note"] = int(midi_note)
	return position


static func _is_integer(value: Variant) -> bool:
	return value is int and not value is bool


static func _position_key(string_index: int, fret: int) -> String:
	return "%d:%d" % [string_index, fret]
