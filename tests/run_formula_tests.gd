extends SceneTree

const Loader := preload("res://scripts/data/json_catalog_loader.gd")
const EXPECTED := {
	"major_pentatonic": [0, 2, 4, 7, 9],
	"minor_pentatonic": [0, 3, 5, 7, 10],
	"major": [0, 2, 4, 5, 7, 9, 11],
	"natural_minor": [0, 2, 3, 5, 7, 8, 10],
	"harmonic_minor": [0, 2, 3, 5, 7, 8, 11],
	"melodic_minor": [0, 2, 3, 5, 7, 9, 11],
	"minor_blues": [0, 3, 5, 6, 7, 10],
	"dorian": [0, 2, 3, 5, 7, 9, 10],
	"phrygian": [0, 1, 3, 5, 7, 8, 10],
	"lydian": [0, 2, 4, 6, 7, 9, 11],
	"mixolydian": [0, 2, 4, 5, 7, 9, 10],
	"locrian": [0, 1, 3, 5, 6, 8, 10],
	"major_blues": [0, 2, 3, 4, 7, 9],
	"phrygian_dominant": [0, 1, 4, 5, 7, 8, 10],
	"double_harmonic_major": [0, 1, 4, 5, 7, 8, 11],
	"hungarian_minor": [0, 2, 3, 6, 7, 8, 11],
	"whole_tone": [0, 2, 4, 6, 8, 10],
	"diminished_half_whole": [0, 1, 3, 4, 6, 7, 9, 10],
	"diminished_whole_half": [0, 2, 3, 5, 6, 8, 9, 11],
	"chromatic": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
	"altered": [0, 1, 3, 4, 6, 8, 10],
}


func _init() -> void:
	var result: Dictionary = Loader.load_catalog("res://data/scales.json", "scales")
	assert(result.ok, str(result.errors))
	assert(result.records.size() == EXPECTED.size())
	assert(result.records.map(func(record: Dictionary): return record.category) == ["core", "core", "pentatonic", "pentatonic", "blues", "blues", "major_modes", "major_modes", "minor_modes", "minor_modes", "minor_modes", "minor_scales", "minor_scales", "exotic", "exotic", "exotic", "symmetric", "symmetric", "symmetric", "symmetric", "advanced"])
	for record: Dictionary in result.records:
		assert(record.intervals == EXPECTED[record.id])
		for field in ["degree_formula", "characteristic_offsets", "characteristic_degrees", "short_description", "character", "typical_chords", "learning_description", "complexity_order"]:
			assert(record.metadata.has(field), "%s is missing %s" % [record.id, field])
		var definition := ScaleDefinition.new(record.id, record.name_key, record.category, record.intervals, record.degree_labels)
		for tonic in range(12):
			for midi in range(128):
				assert(definition.contains_interval(posmod(midi - tonic, 12)) == EXPECTED[record.id].has(posmod(midi - tonic, 12)))
	var tunings: Dictionary = Loader.load_catalog("res://data/tunings.json", "tunings")
	assert(tunings.ok, str(tunings.errors))
	assert(tunings.records[0].open_string_midi == [40, 45, 50, 55, 59, 64])
	print("Formula tests passed: 21 canonical scales x 12 tonics x 128 pitches; tunings.")
	quit()
