extends SceneTree

const Catalog := preload("res://scripts/infrastructure/localization_catalog.gd")

func _init() -> void:
	var catalog := Catalog.load_from_file()
	assert(catalog.validate())
	var keys := catalog.keys()
	assert(keys.size() >= 25)
	for key in keys:
		assert(not catalog.text(key, "ru").strip_edges().is_empty())
		assert(not catalog.text(key, "en").strip_edges().is_empty())
		assert(catalog.text(key, "ru") != key)
		assert(catalog.text(key, "en") != key)
	assert(catalog.text("app.title", "de") == catalog.text("app.title", "ru"))
	assert(catalog.text("missing.key", "en") == "missing.key")
	print("Localization tests passed: version 1, RU/EN parity, non-empty values, and fallback.")
	quit()
