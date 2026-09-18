extends SceneTree

const ANCHORS: PackedInt32Array = [36, 60, 84]


func _init() -> void:
	PluckedStringFactory.clear_cache()
	assert(GuitarTimbre.all() == [GuitarTimbre.ACOUSTIC, GuitarTimbre.ELECTRIC])
	for timbre in GuitarTimbre.all():
		PluckedStringFactory.prewarm(ANCHORS, timbre)
		for midi_note in ANCHORS:
			assert(PluckedStringFactory.is_cached(midi_note, timbre))
	assert(PluckedStringFactory.cached_stream_count() == ANCHORS.size() * GuitarTimbre.all().size())

	var acoustic := PluckedStringFactory.stream_for(60, GuitarTimbre.ACOUSTIC)
	var electric := PluckedStringFactory.stream_for(60, GuitarTimbre.ELECTRIC)
	assert(acoustic.data != electric.data)
	# Electric sustains its body longer, and the two attacks have measurably
	# different upper-harmonic energy.
	assert(_window_rms(electric, 1.60, 0.20) > _window_rms(acoustic, 1.60, 0.20) * 1.25)
	var acoustic_high := _early_high_band_score(acoustic, 60)
	var electric_high := _early_high_band_score(electric, 60)
	assert(absf(acoustic_high - electric_high) > maxf(acoustic_high, electric_high) * 0.05)

	PluckedStringFactory.clear_cache()
	print("Guitar timbre tests passed: distinct acoustic/electric spectra, sustain and prewarmed cache keys.")
	quit()


func _window_rms(stream: AudioStreamWAV, start_seconds: float, duration_seconds: float) -> float:
	var first_frame := int(start_seconds * stream.mix_rate)
	var frame_count := int(duration_seconds * stream.mix_rate)
	var sum_squares := 0.0
	for index in frame_count:
		var sample := float(stream.data.decode_s16((first_frame + index) * 2)) / 32768.0
		sum_squares += sample * sample
	return sqrt(sum_squares / frame_count)


func _early_high_band_score(stream: AudioStreamWAV, midi_note: int) -> float:
	var fundamental := Pitch.new(midi_note).frequency()
	var score := 0.0
	for harmonic in range(6, 14):
		score += _tone_score(stream, fundamental * harmonic, 0.005, 0.05)
	return score


func _tone_score(stream: AudioStreamWAV, frequency: float, start_seconds: float, duration_seconds: float) -> float:
	var first_frame := int(start_seconds * stream.mix_rate)
	var frame_count := int(duration_seconds * stream.mix_rate)
	var real := 0.0
	var imaginary := 0.0
	for index in frame_count:
		var sample := float(stream.data.decode_s16((first_frame + index) * 2)) / 32768.0
		var phase := TAU * frequency * float(index) / stream.mix_rate
		real += sample * cos(phase)
		imaginary += sample * sin(phase)
	return sqrt(real * real + imaginary * imaginary) / frame_count
