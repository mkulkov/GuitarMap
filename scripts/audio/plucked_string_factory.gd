class_name PluckedStringFactory
extends RefCounted

const MIX_RATE := 44100
const DURATION_SECONDS := 2.4
const PEAK_AMPLITUDE := 0.30
const BAKED_MIDI_NOTES: PackedInt32Array = [24, 36, 48, 60, 72, 84, 96, 108]
const USE_BAKED_SAMPLES := true

static var _cache: Dictionary = {}


static func stream_for(midi_note: int, timbre: StringName = GuitarTimbre.DEFAULT) -> AudioStreamWAV:
	assert(midi_note >= 0 and midi_note <= 127)
	assert(GuitarTimbre.is_valid(timbre), "Unsupported guitar timbre: %s" % timbre)
	var cache_key := _cache_key(midi_note, timbre)
	if _cache.has(cache_key):
		return _cache[cache_key]
	if USE_BAKED_SAMPLES and BAKED_MIDI_NOTES.has(midi_note):
		var baked_path := "res://assets/audio/%s/midi_%d.wav" % [timbre, midi_note]
		var baked := load(baked_path) as AudioStreamWAV
		if baked != null:
			_cache[cache_key] = baked
			return baked
	var frequency := Pitch.new(midi_note).frequency()
	var frame_count := int(MIX_RATE * DURATION_SECONDS)
	var pcm := PackedByteArray()
	pcm.resize(frame_count * 2)
	var samples := _synthesize_plucked_string(frequency, frame_count, midi_note, timbre)
	for frame in frame_count:
		var sample := clampf(samples[frame] * PEAK_AMPLITUDE, -PEAK_AMPLITUDE, PEAK_AMPLITUDE)
		pcm.encode_s16(frame * 2, int(round(sample * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = pcm
	_cache[cache_key] = stream
	return stream


static func prewarm(midi_notes: PackedInt32Array, timbre: StringName = GuitarTimbre.DEFAULT) -> void:
	assert(GuitarTimbre.is_valid(timbre), "Unsupported guitar timbre: %s" % timbre)
	for midi_note in midi_notes:
		stream_for(midi_note, timbre)


static func is_cached(midi_note: int, timbre: StringName = GuitarTimbre.DEFAULT) -> bool:
	return _cache.has(_cache_key(midi_note, timbre))


static func cached_stream_count() -> int:
	return _cache.size()


static func clear_cache() -> void:
	_cache.clear()


static func _cache_key(midi_note: int, timbre: StringName) -> String:
	return "%s:%d" % [timbre, midi_note]


static func _synthesize_plucked_string(frequency: float, frame_count: int, midi_note: int, timbre: StringName) -> PackedFloat32Array:
	# A Karplus-Strong delay line models a plucked string instead of a sustained
	# sine oscillator. The same initial string is then voiced as an acoustic body
	# or a gain-driven magnetic pickup.
	var delay_length := maxi(2, roundi(float(MIX_RATE) / frequency))
	var string_state := PackedFloat32Array()
	string_state.resize(delay_length)
	var random_state: int = 1337 + midi_note * 7919 + (17 if timbre == GuitarTimbre.ELECTRIC else 0)
	for index in delay_length:
		random_state = _next_noise_state(random_state)
		var noise := float(random_state % 65536) / 32768.0 - 1.0
		# Plucking near the bridge preserves a bright but non-keyboard attack.
		string_state[index] = noise * (0.72 + 0.28 * sin(TAU * float(index) / delay_length))
	var output := PackedFloat32Array()
	output.resize(frame_count)
	var cursor := 0
	var damping := 0.99695 if timbre == GuitarTimbre.ACOUSTIC else 0.99865
	var previous := 0.0
	var pick_envelope := 1.0
	var acoustic_body_envelope := 1.0
	for frame in frame_count:
		var next_cursor := cursor + 1
		if next_cursor == delay_length:
			next_cursor = 0
		var raw := string_state[cursor]
		var filtered := (raw + string_state[next_cursor]) * 0.5 * damping
		string_state[cursor] = filtered
		var pick_noise := 0.0
		if frame < 950:
			random_state = _next_noise_state(random_state)
			pick_noise = (float(random_state % 65536) / 32768.0 - 1.0) * pick_envelope
			pick_envelope *= 0.9979
		var sample := raw * 0.88 + pick_noise * (0.16 if timbre == GuitarTimbre.ACOUSTIC else 0.09)
		if timbre == GuitarTimbre.ACOUSTIC:
			# Layered soundboard resonance adds the low-mid body of a concert acoustic.
			var body := raw - previous * 0.34
			previous = raw
			var time := float(frame) / MIX_RATE
			var body_resonance := sin(TAU * frequency * time) * 0.17
			body_resonance += sin(TAU * frequency * 2.0 * time) * 0.075
			body_resonance += sin(TAU * frequency * 0.5 * time) * 0.055
			sample = (sample * 0.79 + body * 0.26 + body_resonance * acoustic_body_envelope) * acoustic_body_envelope
			acoustic_body_envelope *= 0.9999968
		else:
			# Pickup blend and stronger soft clipping create a full gained electric voice.
			var pickup := sample * 1.18 - previous * 0.18
			previous = sample
			var driven := pickup * 5.8
			var saturated := driven / (1.0 + absf(driven))
			var harmonic_body := sin(TAU * frequency * 2.0 * float(frame) / MIX_RATE) * 0.055
			sample = (saturated * 0.91 + harmonic_body) * (0.985 + 0.015 * exp(-float(frame) / (MIX_RATE * 1.4)))
		output[frame] = sample
		cursor = next_cursor
	return output


static func _next_noise_state(value: int) -> int:
	return int((int(value) * 1103515245 + 12345) & 0x7fffffff)
