extends SceneTree

func _init() -> void:
	PluckedStringFactory.clear_cache()
	var a4 := PluckedStringFactory.stream_for(69, GuitarTimbre.ACOUSTIC)
	assert(a4.mix_rate == 44100)
	assert(a4.format == AudioStreamWAV.FORMAT_16_BITS)
	assert(not a4.stereo and a4.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	assert(a4.data.size() == int(44100 * PluckedStringFactory.DURATION_SECONDS) * 2)
	assert(a4 == PluckedStringFactory.stream_for(69))
	assert(a4 == PluckedStringFactory.stream_for(69, GuitarTimbre.ACOUSTIC))
	assert(a4 != PluckedStringFactory.stream_for(70))
	var electric_a4 := PluckedStringFactory.stream_for(69, GuitarTimbre.ELECTRIC)
	assert(electric_a4 == PluckedStringFactory.stream_for(69, GuitarTimbre.ELECTRIC))
	assert(electric_a4 != a4 and electric_a4.data != a4.data)
	_assert_safe_peak(a4)
	_assert_safe_peak(electric_a4)
	assert(PluckedStringFactory.USE_BAKED_SAMPLES)
	var baked_acoustic_c4 := PluckedStringFactory.stream_for(60, GuitarTimbre.ACOUSTIC)
	var baked_electric_c4 := PluckedStringFactory.stream_for(60, GuitarTimbre.ELECTRIC)
	assert(baked_acoustic_c4.mix_rate == 44100 and baked_electric_c4.mix_rate == 44100)
	assert(baked_acoustic_c4.data.size() == int(44100 * PluckedStringFactory.DURATION_SECONDS) * 2)
	_assert_safe_peak(baked_acoustic_c4)
	_assert_safe_peak(baked_electric_c4)
	var c4_frequency := Pitch.new(60).frequency()
	assert(_tone_score(baked_acoustic_c4, c4_frequency) > _tone_score(baked_acoustic_c4, Pitch.new(59).frequency()) * 1.35)
	assert(_tone_score(baked_acoustic_c4, c4_frequency) > _tone_score(baked_acoustic_c4, Pitch.new(61).frequency()) * 1.35)
	assert(_tail_rms(baked_acoustic_c4) < 0.002)
	assert(_tail_rms(baked_electric_c4) < 0.002)
	assert(PluckedStringFactory.PEAK_AMPLITUDE * GuitarAudioEngine.SAFE_MIX_GAIN * GuitarAudioEngine.CAPACITY < 1.0)
	for timbre in GuitarTimbre.all():
		for anchor_midi in GuitarAudioEngine.BASE_MIDI_NOTES:
			var anchor_stream := PluckedStringFactory.stream_for(anchor_midi, timbre)
			assert(anchor_stream.mix_rate == 44100)
			assert(anchor_stream.data.size() == int(44100 * PluckedStringFactory.DURATION_SECONDS) * 2)
			_assert_safe_peak(anchor_stream)
			assert(_tail_rms(anchor_stream) < 0.002)
			var anchor_frequency := Pitch.new(anchor_midi).frequency()
			assert(_tone_score(anchor_stream, anchor_frequency) > _tone_score(anchor_stream, Pitch.new(anchor_midi - 1).frequency()) * 1.20)
			assert(_tone_score(anchor_stream, anchor_frequency) > _tone_score(anchor_stream, Pitch.new(anchor_midi + 1).frequency()) * 1.20)
	assert(is_equal_approx(Pitch.new(69).frequency(), 440.0))
	assert(_tone_score(a4, 440.0) > _tone_score(a4, Pitch.new(68).frequency()) * 1.35)
	assert(_tone_score(a4, 440.0) > _tone_score(a4, Pitch.new(70).frequency()) * 1.35)
	var deterministic_pcm := a4.data.duplicate()
	PluckedStringFactory.clear_cache()
	assert(deterministic_pcm == PluckedStringFactory.stream_for(69, GuitarTimbre.ACOUSTIC).data)
	PluckedStringFactory.clear_cache()
	PluckedStringFactory.prewarm(GuitarAudioEngine.BASE_MIDI_NOTES, GuitarTimbre.ACOUSTIC)
	PluckedStringFactory.prewarm(GuitarAudioEngine.BASE_MIDI_NOTES, GuitarTimbre.ELECTRIC)
	assert(PluckedStringFactory.cached_stream_count() == 16)
	assert(PluckedStringFactory.stream_for(60, GuitarTimbre.ACOUSTIC).data != PluckedStringFactory.stream_for(60, GuitarTimbre.ELECTRIC).data)
	print("Synth factory tests passed: 16 baked anchors, safe PCM/tails, deterministic cache and exact fundamentals.")
	quit()


func _assert_safe_peak(stream: AudioStreamWAV) -> void:
	var peak := 0
	for offset in range(0, stream.data.size(), 2):
		peak = maxi(peak, absi(stream.data.decode_s16(offset)))
	assert(peak > 1000)
	assert(peak <= ceili(PluckedStringFactory.PEAK_AMPLITUDE * 32767.0))


func _tone_score(stream: AudioStreamWAV, frequency: float) -> float:
	var first_frame := int(0.08 * stream.mix_rate)
	var frame_count := int(0.30 * stream.mix_rate)
	var real := 0.0
	var imaginary := 0.0
	for index in frame_count:
		var sample := float(stream.data.decode_s16((first_frame + index) * 2)) / 32768.0
		var phase := TAU * frequency * float(index) / stream.mix_rate
		real += sample * cos(phase)
		imaginary += sample * sin(phase)
	return sqrt(real * real + imaginary * imaginary) / frame_count


func _tail_rms(stream: AudioStreamWAV) -> float:
	var frame_count := int(0.02 * stream.mix_rate)
	var first_frame := int(stream.data.size() / 2) - frame_count
	var sum_squares := 0.0
	for index in frame_count:
		var sample := float(stream.data.decode_s16((first_frame + index) * 2)) / 32768.0
		sum_squares += sample * sample
	return sqrt(sum_squares / frame_count)
