extends SceneTree

const StudyPlaybackScript := preload("res://scripts/application/study_playback.gd")

var _finished_count := 0
var _sequence_finished_count := 0

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio := GuitarAudioEngine.new()
	var sequence := NoteSequencePlayer.new()
	var playback = StudyPlaybackScript.new()
	root.add_child(audio)
	root.add_child(sequence)
	root.add_child(playback)
	await process_frame
	sequence.configure(audio)
	playback.configure(sequence, audio)

	playback.finished.connect(func() -> void: _finished_count += 1)
	sequence.playback_finished.connect(func() -> void: _sequence_finished_count += 1)
	playback.start([60, 64, 67, 72], 1.0, 0.01, 0.7, false, 0.0, 45)
	var sustained_drone_slot: int = audio.voice_snapshot(playback._drone_handle).slot
	assert((audio._players[sustained_drone_slot].stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD)
	await create_timer(0.05).timeout
	assert(playback._drone_pulse_handles.size() == 1)
	assert(not audio.voice_snapshot(playback._drone_pulse_handles[0]).is_empty())
	await create_timer(2.6).timeout
	assert(playback.is_active())
	assert(audio._players[sustained_drone_slot].playing)
	assert(not audio.voice_snapshot(playback._drone_handle).is_empty())
	playback.stop()
	assert(playback._drone_handle == -1)
	playback.start([60, 64], 0.01, 0.01, 0.7, false, 0.0, 48)
	assert(playback.is_active())
	assert(playback._drone_handle >= 0)
	assert(not audio.voice_snapshot(playback._drone_handle).is_empty())
	var drone_slot: int = audio.voice_snapshot(playback._drone_handle).slot
	assert((audio._players[drone_slot].stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD)
	await create_timer(0.5).timeout
	assert(_finished_count == 1)
	assert(not playback.is_active())
	assert(playback._drone_handle == -1)

	playback.start([60], 0.01, 0.01, 0.7, true, 0.2, 48)
	await create_timer(0.05).timeout
	assert(playback.is_active())
	assert(not playback._pause_timer.is_stopped())
	var started_before_stop := audio.get_active_voice_count()
	assert(started_before_stop >= 1)
	playback.stop()
	assert(not playback.is_active())
	assert(playback._pause_timer.is_stopped())
	await create_timer(0.25).timeout
	assert(not playback.is_active())
	assert(sequence.is_playing() == false)

	playback.queue_free()
	sequence.queue_free()
	audio.queue_free()
	await process_frame
	print("Study playback tests passed: completion, loop cancellation during pause, and owned tonic drone cleanup.")
	quit()
