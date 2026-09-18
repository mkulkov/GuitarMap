extends SceneTree

const Chord := preload("res://scripts/domain/chord_definition.gd")
const Arpeggio := preload("res://scripts/domain/arpeggio_definition.gd")


func _init() -> void:
	var chords := Chord.load_catalog()
	assert(chords.ok, str(chords.errors))
	assert(chords.catalog.size() == 9)
	assert(Array(chords.catalog.major.intervals) == [0, 4, 7])
	assert(Array(chords.catalog.minor.intervals) == [0, 3, 7])
	for chord_id in chords.catalog:
		var chord = chords.catalog[chord_id]
		assert(chord.contains_interval(0))
		for interval in chord.intervals:
			assert(interval >= 0 and interval <= 11)
	var arpeggios := Arpeggio.load_catalog(Arpeggio.CATALOG_PATH, chords.catalog)
	assert(arpeggios.ok, str(arpeggios.errors))
	assert(arpeggios.catalog.size() == 9)
	for order in Arpeggio.VALID_ORDERS:
		assert(arpeggios.catalog.values().any(func(item) -> bool: return item.order == order))
	for arpeggio_id in arpeggios.catalog:
		var arpeggio = arpeggios.catalog[arpeggio_id]
		var chord = chords.catalog[arpeggio.chord_id]
		for step in arpeggio.steps:
			assert(chord.contains_interval(step.interval))
		assert(arpeggio.midi_offsets().size() == arpeggio.steps.size())
	_test_rejections(chords.catalog)
	print("Harmony tests passed: data-driven chord formulas, arpeggio orders, chord-tone references, and strict invalid-data rejection.")
	quit()


func _test_rejections(chord_catalog: Dictionary) -> void:
	for raw in [
		{"id":"bad","name_key":"bad","category":"test","names":{"ru":"bad","en":"bad"},"intervals":[4,7]},
		{"id":"bad","name_key":"bad","category":"test","names":{"ru":"bad","en":"bad"},"intervals":[0,4,4]},
		{"id":"bad","name_key":"bad","category":"test","names":{"ru":"bad","en":"bad"},"intervals":[0,12]},
	]:
		assert(not Chord.validation_errors(raw).is_empty())
	var invalid_order := {"id":"bad","name_key":"bad","chord_id":"major","order":"ascending","names":{"ru":"bad","en":"bad"},"steps":[{"interval":0,"octave_offset":0},{"interval":7,"octave_offset":0},{"interval":4,"octave_offset":0}]}
	assert(not Arpeggio.validation_errors(invalid_order).is_empty())
	var unknown_chord := {"id":"bad","name_key":"bad","chord_id":"unknown","order":"ascending","names":{"ru":"bad","en":"bad"},"steps":[{"interval":0,"octave_offset":0},{"interval":7,"octave_offset":0}]}
	var path := "user://invalid_arpeggios.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":1,"arpeggios":[unknown_chord]}))
	file.close()
	assert(not Arpeggio.load_catalog(path, chord_catalog).ok)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
