class_name TouchOptionSelector
extends Button

signal item_selected(index: int)
signal menu_requested(selector)

var _items: Array[String] = []
var selected: int = -1

var item_count: int:
	get:
		return _items.size()


func _ready() -> void:
	pressed.connect(func(): menu_requested.emit(self))


func add_item(value: String) -> void:
	_items.append(value)
	if selected < 0:
		select(0)


func clear() -> void:
	_items.clear()
	selected = -1
	text = ""


func select(index: int) -> void:
	if index < 0 or index >= _items.size():
		return
	selected = index
	_refresh_text()


func choose(index: int) -> void:
	if index < 0 or index >= _items.size():
		return
	select(index)
	item_selected.emit(index)


func set_item_text(index: int, value: String) -> void:
	if index < 0 or index >= _items.size():
		return
	_items[index] = value
	if selected == index:
		_refresh_text()


func get_item_text(index: int) -> String:
	return _items[index] if index >= 0 and index < _items.size() else ""


func _refresh_text() -> void:
	text = _items[selected] + "  ▾"
