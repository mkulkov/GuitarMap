extends SceneTree

const VoicePool := preload("res://scripts/audio/audio_voice_pool.gd")


func _init() -> void:
	_test_independent_owners_and_same_position()
	_test_release_and_all_notes_off()
	_test_releasing_steal_and_tie_break()
	_test_active_stealing_branches()
	_test_stale_handles_after_reuse()
	print("Voice pool tests passed: 2/6/12 owners, releases, all-off, deterministic stealing, stale handles.")
	quit()


func _test_independent_owners_and_same_position() -> void:
	var pool := VoicePool.new()
	var first := pool.allocate(64, 0.75, 10, 0)
	var second := pool.allocate(64, 0.75, 11, 0)
	assert(first.handle != second.handle)
	assert(first.slot != second.slot)
	assert(pool.active_count() == 2)
	assert(pool.voice(first.handle).midi_note == pool.voice(second.handle).midi_note)
	assert(pool.voice(first.handle).owner_id == 10)
	assert(pool.voice(second.handle).owner_id == 11)

	var six_pool := VoicePool.new()
	_fill_pool(six_pool, 10)
	assert(six_pool.active_count() == 6)

	var twelve_pool := VoicePool.new()
	var handles: Array[int] = []
	for owner_id in range(12):
		var allocation := twelve_pool.allocate(60, 0.5, owner_id, owner_id)
		handles.append(allocation.handle)
		assert(allocation.stolen_handle == -1)
	assert(twelve_pool.active_count() == 12)
	assert(handles[0] != handles[11])


func _test_release_and_all_notes_off() -> void:
	var pool := VoicePool.new()
	var first := pool.allocate(60, 0.8, 1, 0)
	var second := pool.allocate(64, 0.8, 2, 1)
	assert(pool.mark_releasing(first.handle, 10))
	assert(pool.voice(first.handle).state == "releasing")
	assert(pool.voice(second.handle).state == "active")
	assert(pool.release_complete(first.handle))
	assert(pool.voice(first.handle).is_empty())
	assert(pool.active_count() == 1)
	assert(pool.voice(second.handle).owner_id == 2)
	var cleared := pool.all_notes_off()
	assert(cleared.size() == 1)
	assert(cleared[0].handle == second.handle)
	assert(pool.active_count() == 0)
	assert(pool.active_voices().is_empty())


func _test_releasing_steal_and_tie_break() -> void:
	var pool := VoicePool.new(6)
	var handles: Array[int] = _fill_pool(pool, 0)
	assert(pool.mark_releasing(handles[0], 80))
	assert(pool.mark_releasing(handles[1], 40))
	var replacement := pool.allocate(72, 0.6, 99, 100)
	assert(replacement.stolen_handle == handles[1])
	assert(replacement.slot == 1)

	var tie_pool := VoicePool.new(6)
	var tied_handles: Array[int] = _fill_pool(tie_pool, 0)
	assert(tie_pool.mark_releasing(tied_handles[0], 50))
	assert(tie_pool.mark_releasing(tied_handles[1], 50))
	var tie_replacement := tie_pool.allocate(73, 0.6, 99, 100)
	assert(tie_replacement.stolen_handle == tied_handles[0])


func _test_active_stealing_branches() -> void:
	var mature_pool := VoicePool.new(6, 120)
	var mature_handles: Array[int] = _fill_pool(mature_pool, 0)
	var mature_replacement := mature_pool.allocate(72, 0.5, 90, 120)
	assert(mature_replacement.stolen_handle == mature_handles[0])

	var fresh_pool := VoicePool.new(6, 120)
	var fresh_handles: Array[int] = _fill_pool(fresh_pool, 100)
	var fresh_replacement := fresh_pool.allocate(72, 0.5, 90, 110)
	assert(fresh_replacement.stolen_handle == fresh_handles[0])


func _test_stale_handles_after_reuse() -> void:
	var pool := VoicePool.new(6)
	var original := pool.allocate(60, 0.7, 1, 0)
	assert(pool.release_complete(original.handle))
	var replacement := pool.allocate(61, 0.7, 2, 1)
	assert(replacement.slot == original.slot)
	assert(replacement.handle != original.handle)
	assert(not pool.mark_releasing(original.handle, 2))
	assert(not pool.release_complete(original.handle))
	assert(not pool.set_backend_id(original.handle, "stale"))
	assert(pool.set_backend_id(replacement.handle, "current"))
	assert(pool.voice(replacement.handle).backend_id == "current")
	assert(pool.voice(replacement.handle).state == "active")


func _fill_pool(pool, start_ms: int) -> Array[int]:
	var handles: Array[int] = []
	for owner_id in range(6):
		var allocation: Dictionary = pool.allocate(48 + owner_id, 0.5, owner_id, start_ms + owner_id)
		handles.append(allocation.handle)
	return handles
