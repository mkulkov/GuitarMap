class_name ScaleExplorer
extends RefCounted

var scales: Array = []
var tunings: Array = []
var errors := PackedStringArray()
var tonic: int = 9
var scale_id: String = "minor_pentatonic"
var tuning_id: String = "standard"
var fret_count: int = 24
var spelling: String = "sharp"
var tuning: GuitarTuning
var _cache_key: String = ""
var _cache: Array[Dictionary] = []

func _init() -> void:
	var scale_result := JsonCatalogLoader.load_with_fallback("res://data/scales.json", "user://scales.json", "scales")
	var tuning_result := JsonCatalogLoader.load_with_fallback("res://data/tunings.json", "user://tunings.json", "tunings")
	errors.append_array(scale_result.errors)
	errors.append_array(tuning_result.errors)
	if not scale_result.ok or not tuning_result.ok:
		return
	scales = scale_result.records
	tunings = tuning_result.records
	select_tuning(tuning_id)

func select_tuning(id_value: String) -> bool:
	for record: Dictionary in tunings:
		if record.id == id_value:
			tuning_id = id_value
			tuning = GuitarTuning.from_raw(record.names.en, record.open_string_midi, record.id, record.name_key)
			return true
	return false

func scale_record() -> Dictionary:
	for record: Dictionary in scales:
		if record.id == scale_id or record.get("aliases", []).has(scale_id):
			return record
	return {}

func model() -> Array[Dictionary]:
	var record := scale_record()
	if record.is_empty() or tuning == null:
		return []
	var key := str([tonic, record, tuning.open_string_midi, fret_count, spelling])
	if key != _cache_key:
		var definition := ScaleDefinition.new(record.id, record.name_key, record.category, record.intervals, record.degree_labels, record.get("aliases", []), record.get("metadata", {}))
		_cache = FretboardModelBuilder.build(tuning, fret_count, tonic, definition, spelling)
		_cache_key = key
	# Return owned snapshots: a view may add roles without corrupting cached pitch data.
	return _cache.duplicate(true)
