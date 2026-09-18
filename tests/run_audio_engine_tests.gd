extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var engine := GuitarAudioEngine.new()
	root.add_child(engine)
	await process_frame
	assert(engine.is_ready_for_notes())
	assert(engine.get_timbre() == GuitarTimbre.ACOUSTIC)
	var acoustic_stream := PluckedStringFactory.stream_for(60, GuitarTimbre.ACOUSTIC)
	engine.set_timbre(GuitarTimbre.ELECTRIC)
	assert(engine.get_timbre() == GuitarTimbre.ELECTRIC)
	var electric_handle := engine.note_on(60, 0.8, 501)
	assert(electric_handle > 0)
	var electric_slot: int = engine.voice_snapshot(electric_handle).slot
	assert(engine._players[electric_slot].stream != acoustic_stream)
	engine.all_notes_off()
	assert(engine.note_on(23, 1.0, 500) == -1)
	assert(engine.note_on(109, 1.0, 500) == -1)
	for midi_note in range(GuitarAudioEngine.SUPPORTED_MIDI_MIN, GuitarAudioEngine.SUPPORTED_MIDI_MAX + 1):
		var base_midi: int = engine._nearest_base_midi(midi_note)
		assert(absi(midi_note - base_midi) <= 6)
		var ratio := Pitch.new(midi_note).frequency() / Pitch.new(base_midi).frequency()
		assert(ratio >= pow(2.0, -0.5) and ratio <= pow(2.0, 0.5))
	var handles: Array[int] = []
	for owner_id in range(12):
		var handle := engine.note_on(60 + owner_id, 0.8, owner_id)
		assert(handle > 0)
		handles.append(handle)
	assert(engine.get_active_voice_count() == 12)
	assert(engine.voice_snapshot(handles[4]).owner_id == 4)
	engine.note_off(handles[4])
	engine._process(GuitarAudioEngine.RELEASE_SECONDS + 0.01)
	assert(engine.voice_snapshot(handles[4]).is_empty())
	assert(engine.get_active_voice_count() == 11)
	assert(not engine.voice_snapshot(handles[3]).is_empty())
	assert(not engine.voice_snapshot(handles[5]).is_empty())
	var replacement := engine.note_on(69, 1.0, 99)
	assert(replacement > handles[-1])
	assert(engine.get_active_voice_count() == 12)
	var expected_ratio := Pitch.new(69).frequency() / Pitch.new(72).frequency()
	assert(is_equal_approx(engine._players[engine.voice_snapshot(replacement).slot].pitch_scale, expected_ratio))
	var stolen := engine.note_on(70, 0.7, 100)
	assert(stolen > replacement and engine.get_active_voice_count() == 12)
	engine._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(engine.get_active_voice_count() == 0)
	for player: AudioStreamPlayer in engine._players:
		assert(not player.playing)
	engine.queue_free()
	await process_frame
	await process_frame
	PluckedStringFactory.clear_cache()
	await create_timer(0.1).timeout
	print("Audio engine tests passed: 12 WAV voices, pitch ratio, release, stealing and focus cleanup.")
	quit()
