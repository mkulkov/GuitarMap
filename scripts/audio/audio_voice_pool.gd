class_name AudioVoicePool
extends RefCounted

## Backend-independent, deterministic ownership of a fixed number of voices.
## A handle is intentionally never reused: callers can safely ignore stale events.

const MINIMUM_CAPACITY := 6

var _slots: Array[Dictionary] = []
var _next_handle := 1
var _fresh_window_ms: int


func _init(capacity: int = 12, fresh_window_ms: int = 120) -> void:
	assert(capacity >= MINIMUM_CAPACITY, "AudioVoicePool capacity must be at least %d." % MINIMUM_CAPACITY)
	assert(fresh_window_ms >= 0, "AudioVoicePool fresh window cannot be negative.")
	_fresh_window_ms = fresh_window_ms
	_slots.resize(capacity)
	for slot in range(capacity):
		_slots[slot] = {}


func allocate(midi_note: int, velocity: float, owner_id: int, now_ms: int) -> Dictionary:
	assert(midi_note >= 0 and midi_note <= 127, "MIDI note must be in 0..127.")
	assert(velocity >= 0.0 and velocity <= 1.0, "Velocity must be in 0.0..1.0.")
	var slot := _free_slot()
	if slot < 0:
		slot = _oldest_releasing_slot()
	if slot < 0:
		slot = _oldest_active_slot(now_ms, true)
	if slot < 0:
		slot = _oldest_active_slot(now_ms, false)

	var stolen_handle := -1
	if not _slots[slot].is_empty():
		stolen_handle = _slots[slot].handle
	var handle := _next_handle
	_next_handle += 1
	_slots[slot] = {
		"handle": handle,
		"slot": slot,
		"state": "active",
		"midi_note": midi_note,
		"velocity": velocity,
		"owner_id": owner_id,
		"created_at": now_ms,
		"released_at": -1,
		"backend_id": null,
	}
	return {"handle": handle, "slot": slot, "stolen_handle": stolen_handle}


func mark_releasing(handle: int, now_ms: int) -> bool:
	var slot := _slot_for_handle(handle)
	if slot < 0 or _slots[slot].state != "active":
		return false
	_slots[slot].state = "releasing"
	_slots[slot].released_at = now_ms
	return true


func release_complete(handle: int) -> bool:
	var slot := _slot_for_handle(handle)
	if slot < 0:
		return false
	_slots[slot] = {}
	return true


func set_backend_id(handle: int, id: Variant) -> bool:
	var slot := _slot_for_handle(handle)
	if slot < 0:
		return false
	_slots[slot].backend_id = id
	return true


func voice(handle: int) -> Dictionary:
	var slot := _slot_for_handle(handle)
	if slot < 0:
		return {}
	return _slots[slot].duplicate(true)


func active_voices() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in _slots:
		if not slot.is_empty():
			result.append(slot.duplicate(true))
	return result


func active_count() -> int:
	var count := 0
	for slot in _slots:
		if not slot.is_empty():
			count += 1
	return count


func all_notes_off() -> Array[Dictionary]:
	var cleared := active_voices()
	for slot in range(_slots.size()):
		_slots[slot] = {}
	return cleared


func _free_slot() -> int:
	for slot in range(_slots.size()):
		if _slots[slot].is_empty():
			return slot
	return -1


func _oldest_releasing_slot() -> int:
	var selected := -1
	for slot in range(_slots.size()):
		var candidate: Dictionary = _slots[slot]
		if candidate.is_empty() or candidate.state != "releasing":
			continue
		if selected < 0 or _is_older(candidate, _slots[selected], "released_at"):
			selected = slot
	return selected


func _oldest_active_slot(now_ms: int, require_mature: bool) -> int:
	var selected := -1
	for slot in range(_slots.size()):
		var candidate: Dictionary = _slots[slot]
		if candidate.is_empty() or candidate.state != "active":
			continue
		var is_mature: bool = now_ms - candidate.created_at >= _fresh_window_ms
		if require_mature != is_mature:
			continue
		if selected < 0 or _is_older(candidate, _slots[selected], "created_at"):
			selected = slot
	return selected


func _is_older(candidate: Dictionary, current: Dictionary, timestamp_key: String) -> bool:
	if candidate[timestamp_key] != current[timestamp_key]:
		return candidate[timestamp_key] < current[timestamp_key]
	return candidate.handle < current.handle


func _slot_for_handle(handle: int) -> int:
	for slot in range(_slots.size()):
		if not _slots[slot].is_empty() and _slots[slot].handle == handle:
			return slot
	return -1
