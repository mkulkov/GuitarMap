extends SceneTree

const MIX_RATE := 48000.0
const PROBE_FRAMES := 128

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Audio probe driver: %s, mix rate: %s Hz" % [AudioServer.get_driver_name(), AudioServer.get_mix_rate()])
	_check(is_equal_approx(_midi_frequency(69), 440.0), "MIDI 69 must resolve to exactly 440 Hz")
	_check(is_equal_approx(_midi_frequency(60), 261.6255653005986), "MIDI 60 frequency formula drifted")
	await _probe_polyphonic()
	await _probe_wav_player_pool()
	await _probe_generator_pool()
	_probe_release_envelope()
	PluckedStringFactory.clear_cache()
	await create_timer(0.1).timeout
	if _failures == 0:
		print("Audio probe passed: polyphonic, cached WAV pool, and generator pool lifecycle.")
		quit()
	else:
		push_error("Audio probe failed with %d checks." % _failures)
		quit(1)


func _probe_polyphonic() -> void:
	var player := AudioStreamPlayer.new()
	root.add_child(player)
	var polyphonic := AudioStreamPolyphonic.new()
	polyphonic.polyphony = 2
	player.stream = polyphonic
	player.play()
	await process_frame
	var playback := player.get_stream_playback() as AudioStreamPlaybackPolyphonic
	_check(playback != null, "AudioStreamPolyphonic must expose AudioStreamPlaybackPolyphonic")
	if playback == null:
		player.queue_free()
		return
	var source := _looping_sine_wave(440.0)
	var first_id := playback.play_stream(source, 0.0, -18.0, _midi_frequency(69) / 440.0, AudioServer.PLAYBACK_TYPE_STREAM)
	var second_id := playback.play_stream(source, 0.0, -18.0, _midi_frequency(76) / 440.0, AudioServer.PLAYBACK_TYPE_STREAM)
	var overflow_id := playback.play_stream(source, 0.0, 0.0, 1.0, AudioServer.PLAYBACK_TYPE_STREAM)
	print("Polyphonic IDs: first=%d second=%d overflow=%d" % [first_id, second_id, overflow_id])
	_check(first_id >= 0 and second_id >= 0 and first_id != second_id, "Polyphonic playback must return distinct live IDs")
	_check(overflow_id == AudioStreamPlaybackPolyphonic.INVALID_ID, "Polyphonic capacity must return INVALID_ID")
	_check(playback.is_stream_playing(first_id) and playback.is_stream_playing(second_id), "Both polyphonic IDs must remain independently active")
	playback.set_stream_volume(first_id, -36.0)
	playback.set_stream_pitch_scale(first_id, _midi_frequency(70) / 440.0)
	playback.stop_stream(first_id)
	await create_timer(0.05).timeout
	print("After stop_stream: first=%s second=%s" % [playback.is_stream_playing(first_id), playback.is_stream_playing(second_id)])
	_check(not playback.is_stream_playing(first_id) and playback.is_stream_playing(second_id), "Stopping one polyphonic ID must preserve the other")
	var replacement_id := playback.play_stream(source, 0.0, 0.0, 1.0, AudioServer.PLAYBACK_TYPE_STREAM)
	_check(replacement_id >= 0 and playback.is_stream_playing(replacement_id), "Released polyphonic capacity must be reusable")
	player.stop()
	await create_timer(0.05).timeout
	print("After player.stop: second=%s replacement=%s player=%s" % [playback.is_stream_playing(second_id), playback.is_stream_playing(replacement_id), player.playing])
	_check(not playback.is_stream_playing(second_id) and not playback.is_stream_playing(replacement_id), "Stopping the host player must stop all polyphonic IDs")
	player.free()
	await create_timer(0.05).timeout


func _probe_wav_player_pool() -> void:
	var host := Node.new()
	root.add_child(host)
	var players: Array[AudioStreamPlayer] = []
	var prewarm_started := Time.get_ticks_usec()
	var cached_c4 := PluckedStringFactory.stream_for(60)
	_check(cached_c4 == PluckedStringFactory.stream_for(60), "Plucked WAV synthesis must reuse its MIDI cache entry")
	_check(cached_c4.mix_rate == PluckedStringFactory.MIX_RATE, "Cached WAV must retain the factory mix rate")
	for voice_index in range(12):
		var player := AudioStreamPlayer.new()
		player.stream = PluckedStringFactory.stream_for(60 + voice_index)
		player.volume_db = -42.0
		host.add_child(player)
		player.play()
		players.append(player)
	var prewarm_msec := (Time.get_ticks_usec() - prewarm_started) / 1000.0
	await process_frame
	_check(players.all(func(player: AudioStreamPlayer) -> bool: return player.playing), "All 12 cached WAV player nodes must play independently")
	for fade_step in range(1, 5):
		players[4].volume_db = lerpf(-42.0, -80.0, fade_step / 4.0)
		await create_timer(0.01).timeout
	players[4].stop()
	_check(not players[4].playing, "A faded cached WAV voice must stop independently")
	_check(players[3].playing and players[5].playing, "Stopping one cached WAV voice must preserve adjacent voices")
	players[4].stream = PluckedStringFactory.stream_for(72)
	players[4].volume_db = -42.0
	players[4].play()
	await process_frame
	_check(players[4].playing, "A released cached WAV slot must restart with a new MIDI stream")
	print("Cached WAV probe: 12 players, %.1f ms cold prewarm, independent 40 ms fade/stop, slot restart succeeded." % prewarm_msec)
	for player in players:
		player.stop()
	players.clear()
	host.free()
	await create_timer(0.05).timeout


func _probe_generator_pool() -> void:
	var host := Node.new()
	root.add_child(host)
	var players: Array[AudioStreamPlayer] = []
	var playbacks: Array[AudioStreamGeneratorPlayback] = []
	for voice_index in range(12):
		var generator := AudioStreamGenerator.new()
		generator.mix_rate_mode = AudioStreamGenerator.MIX_RATE_CUSTOM
		generator.mix_rate = MIX_RATE
		generator.buffer_length = 0.05
		var player := AudioStreamPlayer.new()
		player.stream = generator
		host.add_child(player)
		player.play()
		players.append(player)
		var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
		_check(playback != null, "Generator voice %d must expose its own playback" % voice_index)
		if playback == null:
			continue
		playbacks.append(playback)
		var phase := 0.0
		var frequency := _midi_frequency(60 + voice_index)
		var phase_increment := frequency / MIX_RATE
		var frame_count: int = mini(PROBE_FRAMES, playback.get_frames_available())
		_check(frame_count > 0, "Generator voice %d must accept PCM frames" % voice_index)
		for _frame_index in range(frame_count):
			var sample := sin(phase * TAU) * 0.05
			playback.push_frame(Vector2(sample, sample))
			phase = fmod(phase + phase_increment, 1.0)
	await process_frame
	_check(playbacks.size() == 12, "The pool must expose 12 independent generator playbacks")
	players[4].stop()
	_check(not players[4].playing, "A selected generator voice must stop")
	_check(players[3].playing and players[5].playing, "Stopping one generator voice must preserve adjacent voices")
	var total_skips := 0
	for playback in playbacks:
		total_skips += playback.get_skips()
	print("Generator probe: 12 players, 0.05 s buffers, immediate underrun count: %d" % total_skips)
	for player in players:
		player.stop()
	playbacks.clear()
	players.clear()
	host.free()
	await create_timer(0.05).timeout


func _probe_release_envelope() -> void:
	var release_frames := int(MIX_RATE * 0.04)
	var previous_gain := 1.0
	for frame_index in range(release_frames):
		var gain := 1.0 - float(frame_index + 1) / release_frames
		_check(gain <= previous_gain, "Release gain must be monotonic")
		previous_gain = gain
	_check(is_zero_approx(previous_gain), "A 40 ms release must terminate at zero gain")


func _looping_sine_wave(frequency: float) -> AudioStreamWAV:
	var frame_count := 4800
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame_index in range(frame_count):
		var sample := int(round(sin(TAU * frequency * frame_index / MIX_RATE) * 8192.0))
		bytes.encode_s16(frame_index * 2, sample)
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = int(MIX_RATE)
	wave.data = bytes
	wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wave.loop_begin = 0
	wave.loop_end = frame_count
	return wave


func _midi_frequency(midi_note: int) -> float:
	return 440.0 * pow(2.0, (midi_note - 69) / 12.0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
