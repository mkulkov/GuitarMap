class_name GuitarAudioEngine
extends Node

signal voice_started(handle: int, midi_note: int, owner_id: int)
signal voice_stopped(handle: int, reason: String)

const CAPACITY := 12
const RELEASE_SECONDS := 0.06
const SUPPORTED_MIDI_MIN := 24
const SUPPORTED_MIDI_MAX := 108
const BASE_MIDI_NOTES: PackedInt32Array = [24, 36, 48, 60, 72, 84, 96, 108]
const SAFE_MIX_GAIN := 0.25

var _pool := AudioVoicePool.new(CAPACITY)
var _players: Array[AudioStreamPlayer] = []
var _releases: Dictionary = {}
var _master_volume: float = 0.8
var _ready_for_notes: bool = false
var _timbre: StringName = GuitarTimbre.DEFAULT


func _ready() -> void:
	for slot in CAPACITY:
		var player := AudioStreamPlayer.new()
		player.name = "Voice%d" % slot
		add_child(player)
		_players.append(player)
	for midi_note in BASE_MIDI_NOTES:
		PluckedStringFactory.stream_for(midi_note, _timbre)
	_ready_for_notes = true
	set_process(true)


func note_on(midi_note: int, velocity: float, owner_id: int) -> int:
	if not _ready_for_notes or midi_note < SUPPORTED_MIDI_MIN or midi_note > SUPPORTED_MIDI_MAX:
		return -1
	var allocation := _pool.allocate(midi_note, clampf(velocity, 0.0, 1.0), owner_id, Time.get_ticks_msec())
	var handle: int = allocation.handle
	var slot: int = allocation.slot
	var stolen_handle: int = allocation.stolen_handle
	if stolen_handle >= 0:
		_releases.erase(stolen_handle)
		_players[slot].stop()
		voice_stopped.emit(stolen_handle, "stolen")
	var base_midi := _nearest_base_midi(midi_note)
	var player := _players[slot]
	player.stream = PluckedStringFactory.stream_for(base_midi, _timbre)
	player.pitch_scale = Pitch.new(midi_note).frequency() / Pitch.new(base_midi).frequency()
	player.volume_db = _volume_db(velocity)
	player.play()
	_pool.set_backend_id(handle, slot)
	voice_started.emit(handle, midi_note, owner_id)
	return handle


func note_off(handle: int) -> void:
	var voice := _pool.voice(handle)
	if voice.is_empty() or not _pool.mark_releasing(handle, Time.get_ticks_msec()):
		return
	_releases[handle] = {"remaining": RELEASE_SECONDS, "start_db": _players[voice.slot].volume_db}


func all_notes_off(reason: String = "requested") -> void:
	for voice: Dictionary in _pool.all_notes_off():
		_players[voice.slot].stop()
		voice_stopped.emit(voice.handle, reason)
	_releases.clear()


func set_master_volume(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	for voice: Dictionary in _pool.active_voices():
		if voice.state == "active":
			_players[voice.slot].volume_db = _volume_db(voice.velocity)


func set_timbre(value: StringName) -> void:
	assert(GuitarTimbre.is_valid(value), "Unsupported guitar timbre: %s" % value)
	if _timbre == value:
		return
	all_notes_off("timbre_changed")
	_timbre = value
	PluckedStringFactory.prewarm(BASE_MIDI_NOTES, _timbre)


func get_timbre() -> StringName:
	return _timbre


func get_active_voice_count() -> int:
	return _pool.active_count()


func is_ready_for_notes() -> bool:
	return _ready_for_notes


func voice_snapshot(handle: int) -> Dictionary:
	return _pool.voice(handle)


func _process(delta: float) -> void:
	for handle: int in _releases.keys():
		var voice := _pool.voice(handle)
		if voice.is_empty():
			_releases.erase(handle)
			continue
		var release: Dictionary = _releases[handle]
		release.remaining = float(release.remaining) - delta
		if release.remaining <= 0.0:
			_players[voice.slot].stop()
			_pool.release_complete(handle)
			_releases.erase(handle)
			voice_stopped.emit(handle, "released")
		else:
			var progress := 1.0 - float(release.remaining) / RELEASE_SECONDS
			_players[voice.slot].volume_db = lerpf(float(release.start_db), -60.0, progress)
			_releases[handle] = release
	for voice: Dictionary in _pool.active_voices():
		if voice.state == "active" and not _players[voice.slot].playing:
			_pool.release_complete(voice.handle)
			voice_stopped.emit(voice.handle, "stream_finished")


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT or what == MainLoop.NOTIFICATION_APPLICATION_PAUSED:
		all_notes_off("application_inactive")


func _exit_tree() -> void:
	all_notes_off("tree_exit")
	for player: AudioStreamPlayer in _players:
		player.stream = null
	PluckedStringFactory.clear_cache()


func _nearest_base_midi(midi_note: int) -> int:
	var selected := BASE_MIDI_NOTES[0]
	var distance := absi(midi_note - selected)
	for candidate in BASE_MIDI_NOTES:
		var candidate_distance := absi(midi_note - candidate)
		if candidate_distance < distance:
			selected = candidate
			distance = candidate_distance
	return selected


func _volume_db(velocity: float) -> float:
	var linear := SAFE_MIX_GAIN * _master_volume * clampf(velocity, 0.0, 1.0)
	return linear_to_db(maxf(linear, 0.0001))
