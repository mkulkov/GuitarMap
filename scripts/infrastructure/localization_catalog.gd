class_name LocalizationCatalog
extends RefCounted

const VERSION := 1
const LANGUAGES := ["ru", "en"]
const DEFAULT_LANGUAGE := "ru"

var _strings: Dictionary = {}

static func load_from_file(path: String = "res://data/ui_strings.json") -> LocalizationCatalog:
	var catalog := LocalizationCatalog.new()
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "Unable to open localization catalog: %s" % path)
	var parsed = JSON.parse_string(file.get_as_text())
	assert(parsed is Dictionary, "Localization catalog must be a JSON object.")
	catalog._load_data(parsed)
	return catalog

func _load_data(data: Dictionary) -> void:
	assert(data.get("version", null) == VERSION, "Unsupported localization catalog version.")
	var strings = data.get("strings", null)
	assert(strings is Dictionary and not strings.is_empty(), "Localization catalog must contain strings.")
	for key in strings:
		var values = strings[key]
		assert(values is Dictionary, "Localization entry must be an object: %s" % key)
		for language in LANGUAGES:
			assert(values.has(language), "Missing %s translation for %s" % [language, key])
			assert(values[language] is String and not str(values[language]).strip_edges().is_empty(), "Empty %s translation for %s" % [language, key])
		_strings[str(key)] = {"ru": str(values.ru), "en": str(values.en)}

func validate() -> bool:
	return not _strings.is_empty()

func keys() -> Array[String]:
	var result: Array[String] = []
	for key in _strings:
		result.append(str(key))
	return result

func text(key: String, language: String = DEFAULT_LANGUAGE) -> String:
	if not _strings.has(key):
		return key
	var values: Dictionary = _strings[key]
	if values.has(language) and not str(values[language]).strip_edges().is_empty():
		return str(values[language])
	if values.has(DEFAULT_LANGUAGE):
		return str(values[DEFAULT_LANGUAGE])
	return key
