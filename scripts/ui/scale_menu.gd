extends RefCounted

const GROUP_NAMES := {
	"core": ["Базовые гаммы", "Core scales"],
	"pentatonic": ["Пентатоники", "Pentatonic scales"],
	"blues": ["Блюзовые гаммы", "Blues scales"],
	"modes": ["Диатонические лады", "Diatonic modes"],
	"minor_scales": ["Разновидности минора", "Minor variants"],
	"advanced": ["Джазовые доминантовые", "Jazz dominant scales"],
	"symmetric": ["Симметричные гаммы", "Symmetric scales"],
	"exotic": ["Экзотические гаммы", "Exotic scales"],
	"chromatic": ["Хроматика", "Chromatic"],
}


static func populate(menu: OptionButton, records: Array, language: String, selected_id: String) -> void:
	menu.clear()
	var sorted := records.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.get("order", 999)) < int(b.get("order", 999)))
	var previous_group := ""
	var selected := -1
	for record: Dictionary in sorted:
		var category := str(record.get("category", "other"))
		if category != previous_group:
			var labels: Array = GROUP_NAMES.get(category, ["Другие", "Other"])
			menu.add_separator(str(labels[1 if language == "en" else 0]))
			previous_group = category
		menu.add_item(str(record.names.get(language, record.names.get("en", record.id))))
		var index := menu.item_count - 1
		menu.set_item_metadata(index, str(record.id))
		if selected < 0 or str(record.id) == selected_id:
			selected = index
	menu.select(selected)
