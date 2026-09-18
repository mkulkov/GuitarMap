class_name TouchVoiceCoordinator
extends RefCounted

## Backend-agnostic ownership of one independent voice per touch contact.
## The backend must provide note_on(midi, velocity, owner) -> handle,
## note_off(handle), and all_notes_off(reason).

const INVALID_HANDLE := -1
const INVALID_POSITION_KEY := Vector2i(-1, -1)

var _audio_engine: Object
var _contacts: Dictionary = {}


func _init(audio_engine: Object) -> void:
	assert(audio_engine != null, "TouchVoiceCoordinator needs an audio engine.")
	_audio_engine = audio_engine


func press(owner_id: int, position: Dictionary, velocity: float = 0.8) -> int:
	# A repeated press is a retrigger: its previous voice ends before a new one starts.
	if _contacts.has(owner_id):
		_stop_voice(_contacts[owner_id])
	if not _is_valid_position(position):
		if _contacts.has(owner_id):
			_contacts[owner_id] = _inactive_contact()
		return INVALID_HANDLE
	var contact := _contact_for(position)
	_contacts[owner_id] = contact
	return _start_voice(owner_id, contact, velocity)


func move(owner_id: int, position: Dictionary, velocity: float = 0.8) -> int:
	if not _contacts.has(owner_id):
		return INVALID_HANDLE
	var current: Dictionary = _contacts[owner_id]
	if not _is_valid_position(position):
		_stop_voice(current)
		_contacts[owner_id] = _inactive_contact()
		return INVALID_HANDLE
	var key := _position_key(position)
	if current.position_key == key:
		return int(current.voice_handle)
	_stop_voice(current)
	var contact := _contact_for(position)
	_contacts[owner_id] = contact
	return _start_voice(owner_id, contact, velocity)


func release(owner_id: int) -> bool:
	if not _contacts.has(owner_id):
		return false
	_stop_voice(_contacts[owner_id])
	_contacts.erase(owner_id)
	return true


func cancel_all(reason: String) -> void:
	_audio_engine.all_notes_off(reason)
	_contacts.clear()


func contact(owner_id: int) -> Dictionary:
	return _contacts.get(owner_id, {}).duplicate(true)


func contacts() -> Dictionary:
	return _contacts.duplicate(true)


func active_contact_count() -> int:
	return _contacts.size()


func _start_voice(owner_id: int, contact: Dictionary, velocity: float) -> int:
	var handle := int(_audio_engine.note_on(int(contact.midi_note), clampf(velocity, 0.0, 1.0), owner_id))
	contact.voice_handle = handle
	contact.pressed_at_ms = Time.get_ticks_msec()
	_contacts[owner_id] = contact
	return handle


func _stop_voice(contact: Dictionary) -> void:
	var handle := int(contact.get("voice_handle", INVALID_HANDLE))
	if handle != INVALID_HANDLE:
		_audio_engine.note_off(handle)


func _contact_for(position: Dictionary) -> Dictionary:
	return {
		"position_key": _position_key(position),
		"string_index": int(position.string_index),
		"fret": int(position.fret),
		"midi_note": int(position.midi_note),
		"voice_handle": INVALID_HANDLE,
		"pressed_at_ms": 0,
	}


func _inactive_contact() -> Dictionary:
	return {
		"position_key": INVALID_POSITION_KEY,
		"string_index": -1,
		"fret": -1,
		"midi_note": -1,
		"voice_handle": INVALID_HANDLE,
		"pressed_at_ms": 0,
	}


func _is_valid_position(position: Dictionary) -> bool:
	return position.has("string_index") and position.has("fret") and position.has("midi_note") \
		and int(position.string_index) >= 0 and int(position.fret) >= 0


func _position_key(position: Dictionary) -> Vector2i:
	return Vector2i(int(position.string_index), int(position.fret))
