class_name SegmentedSelector
extends HBoxContainer

signal item_selected(index: int)

var selected: int = -1
var _items: Array[String] = []
var _buttons: Array[Button] = []

var item_count: int:
	get:
		return _items.size()


func _ready() -> void:
	add_theme_constant_override("separation", 0)


func add_item(value: String) -> void:
	var index := _items.size()
	_items.append(value)
	var button := Button.new()
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(68, 40)
	button.text = value
	button.pressed.connect(func(): choose(index))
	_buttons.append(button)
	add_child(button)
	if selected < 0:
		select(0)
	_refresh_styles()


func clear() -> void:
	_items.clear()
	selected = -1
	for button in _buttons:
		button.queue_free()
	_buttons.clear()


func select(index: int) -> void:
	if index < 0 or index >= _items.size():
		return
	selected = index
	_refresh_styles()


func choose(index: int) -> void:
	if index < 0 or index >= _items.size():
		return
	select(index)
	item_selected.emit(index)


func set_item_text(index: int, value: String) -> void:
	if index < 0 or index >= _items.size():
		return
	_items[index] = value
	_buttons[index].text = value


func get_item_text(index: int) -> String:
	return _items[index] if index >= 0 and index < _items.size() else ""


func _refresh_styles() -> void:
	for index in _buttons.size():
		var button := _buttons[index]
		button.set_pressed_no_signal(index == selected)
		button.theme_type_variation = "SegmentSelected" if index == selected else "SegmentButton"
