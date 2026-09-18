extends SceneTree

const TouchVoiceCoordinator := preload("res://scripts/application/touch_voice_coordinator.gd")


class FakeAudioEngine extends RefCounted:
	var note_on_calls: Array[Dictionary] = []
	var note_off_calls: Array[int] = []
	var all_off_reasons: Array[String] = []
	var _next_handle := 1

	func note_on(midi_note: int, velocity: float, owner_id: int) -> int:
		var handle := _next_handle
		_next_handle += 1
		note_on_calls.append({"handle": handle, "midi_note": midi_note, "velocity": velocity, "owner_id": owner_id})
		return handle

	func note_off(handle: int) -> void:
		note_off_calls.append(handle)

	func all_notes_off(reason: String) -> void:
		all_off_reasons.append(reason)


func _init() -> void:
	_test_repeated_press_and_same_zone_drag()
	_test_cross_zone_empty_and_reentry()
	_test_independent_owners_and_same_position()
	_test_release_isolation_and_focus_cancel()
	print("Touch coordinator tests passed: retrigger, drag, re-entry, 2/6/12 contacts, isolation and focus cleanup.")
	quit()


func _test_repeated_press_and_same_zone_drag() -> void:
	var engine := FakeAudioEngine.new()
	var coordinator := TouchVoiceCoordinator.new(engine)
	var first := coordinator.press(3, _position(1, 5, 64))
	var repeated := coordinator.press(3, _position(1, 5, 64), 0.6)
	assert(first == 1 and repeated == 2)
	assert(engine.note_off_calls == [first])
	assert(engine.note_on_calls.size() == 2)
	assert(is_equal_approx(float(engine.note_on_calls[1].velocity), 0.6))
	assert(coordinator.move(3, _position(1, 5, 64)) == repeated)
	assert(engine.note_on_calls.size() == 2)
	var snapshot := coordinator.contact(3)
	snapshot.midi_note = -1
	assert(coordinator.contact(3).midi_note == 64)


func _test_cross_zone_empty_and_reentry() -> void:
	var engine := FakeAudioEngine.new()
	var coordinator := TouchVoiceCoordinator.new(engine)
	var first := coordinator.press(4, _position(0, 3, 43))
	var second := coordinator.move(4, _position(0, 4, 44))
	assert(second != first)
	assert(engine.note_off_calls == [first])
	assert(coordinator.move(4, {}) == -1)
	assert(engine.note_off_calls == [first, second])
	assert(coordinator.active_contact_count() == 1)
	assert(coordinator.contact(4).voice_handle == -1)
	var third := coordinator.move(4, _position(0, 5, 45))
	assert(third > second)
	assert(coordinator.contact(4).position_key == Vector2i(0, 5))


func _test_independent_owners_and_same_position() -> void:
	for count in [2, 6, 12]:
		var engine := FakeAudioEngine.new()
		var coordinator := TouchVoiceCoordinator.new(engine)
		var handles: Array[int] = []
		for owner_id in range(count):
			handles.append(coordinator.press(owner_id, _position(2, 7, 57)))
		assert(coordinator.active_contact_count() == count)
		assert(engine.note_on_calls.size() == count)
		assert(handles.front() != handles.back())
		assert(engine.note_on_calls[0].midi_note == engine.note_on_calls[count - 1].midi_note)
		assert(engine.note_on_calls[0].owner_id != engine.note_on_calls[count - 1].owner_id)


func _test_release_isolation_and_focus_cancel() -> void:
	var engine := FakeAudioEngine.new()
	var coordinator := TouchVoiceCoordinator.new(engine)
	var first := coordinator.press(10, _position(3, 2, 60))
	var second := coordinator.press(11, _position(3, 2, 60))
	assert(coordinator.release(10))
	assert(not coordinator.release(10))
	assert(engine.note_off_calls == [first])
	assert(coordinator.active_contact_count() == 1)
	assert(coordinator.contact(11).voice_handle == second)
	coordinator.cancel_all("focus_lost")
	assert(engine.all_off_reasons == ["focus_lost"])
	assert(coordinator.active_contact_count() == 0)


func _position(string_index: int, fret: int, midi_note: int) -> Dictionary:
	return {"string_index": string_index, "fret": fret, "midi_note": midi_note}
