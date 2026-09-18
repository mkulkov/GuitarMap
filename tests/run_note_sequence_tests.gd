extends SceneTree

class FakeAudio:
	extends RefCounted
	var next_handle := 1
	var started: Array[Dictionary] = []
	var stopped: Array[int] = []

	func note_on(midi_note: int, velocity: float, owner_id: int) -> int:
		var handle := next_handle
		next_handle += 1
		started.append({"handle": handle, "midi_note": midi_note, "velocity": velocity, "owner_id": owner_id})
		return handle

	func note_off(handle: int) -> void:
		stopped.append(handle)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fake := FakeAudio.new()
	var player := NoteSequencePlayer.new()
	root.add_child(player)
	player.configure(fake)
	player.play_chord([60, 64, 67], 0.01)
	await create_timer(0.03).timeout
	assert(fake.started.map(func(item): return item.midi_note) == [60, 64, 67])
	assert(fake.stopped == [1, 2, 3])

	fake.started.clear()
	fake.stopped.clear()
	player.play_arpeggio([57, 60, 64], 0.01, 0.01)
	await create_timer(0.12).timeout
	assert(fake.started.map(func(item): return item.midi_note) == [57, 60, 64])
	assert(fake.stopped == [4, 5, 6])

	fake.started.clear()
	fake.stopped.clear()
	player.play_chord([48, 52], 1.0)
	await process_frame
	player.stop()
	assert(fake.stopped == [7, 8])
	assert(not player.is_playing())
	player.queue_free()
	await process_frame
	print("Note sequence tests passed: chord, ordered arpeggio and isolated cancellation.")
	quit()
