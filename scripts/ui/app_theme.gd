class_name FretFormulaTheme
extends RefCounted

## Shared dark UI palette for the landscape-first FretFormula interface.
## The scene owns its layout; this class only supplies reusable Control styling.

# Semantic palette: the fretboard renderer and Control theme share these values.
const BACKGROUND_BASE := Color("06131d")
const BACKGROUND_SURFACE := Color("0a1b29")
const BACKGROUND_ELEVATED := Color("102535")
const TEXT_PRIMARY := Color("edf7ff")
const TEXT_SECONDARY := Color("8faac0")
const ACCENT_CYAN := Color("22d8f2")
const NOTE_ROOT := Color("f25355")
const NOTE_MINOR_THIRD := Color("9a63ed")
const NOTE_FOURTH := Color("298cf0")
const NOTE_FIFTH := Color("17cfcf")
const NOTE_MINOR_SEVENTH := Color("e7a932")
const NOTE_FLAT_SECOND := Color("f28b38")
const NOTE_SECOND := Color("e9c846")
const NOTE_MAJOR_THIRD := Color("6ccb5f")
const NOTE_FLAT_FIFTH := Color("c86dd7")
const NOTE_FLAT_SIXTH := Color("d96c98")
const NOTE_SIXTH := Color("6da3ff")
const NOTE_SEVENTH := Color("9bde72")
const BORDER_NORMAL := Color("214052")
const BORDER_ACTIVE := ACCENT_CYAN
const WOOD_DARK := Color("3a1e13")
const WOOD_LIGHT := Color("572d1b")

const SURFACE := BACKGROUND_SURFACE
const SURFACE_RAISED := BACKGROUND_ELEVATED
const SURFACE_HOVER := Color("14364a")
const SURFACE_PRESSED := Color("14657b")
const BORDER := BORDER_NORMAL
const BORDER_HOVER := Color("38728c")
const FOCUS := Color("63e6f7")
const TEXT := TEXT_PRIMARY
const TEXT_MUTED := TEXT_SECONDARY
const ACCENT := ACCENT_CYAN
const ACCENT_HOVER := Color("61eafb")
const ACCENT_PRESSED := Color("0aa9c4")
const RADIUS := 10


static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16

	_apply_font_colors(theme)
	_apply_control_styles(theme)
	_apply_container_styles(theme)
	_apply_variations(theme)
	return theme


static func note_color_for_interval(interval_from_root: int) -> Color:
	match posmod(interval_from_root, 12):
		0: return NOTE_ROOT
		1: return NOTE_FLAT_SECOND
		2: return NOTE_SECOND
		3: return NOTE_MINOR_THIRD
		4: return NOTE_MAJOR_THIRD
		5: return NOTE_FOURTH
		6: return NOTE_FLAT_FIFTH
		7: return NOTE_FIFTH
		8: return NOTE_FLAT_SIXTH
		9: return NOTE_SIXTH
		10: return NOTE_MINOR_SEVENTH
		_: return NOTE_SEVENTH


static func _apply_font_colors(theme: Theme) -> void:
	for type_name in ["Label", "Button", "OptionButton", "CheckButton", "SpinBox", "LineEdit", "PopupMenu"]:
		theme.set_color("font_color", type_name, TEXT)
	for type_name in ["Button", "OptionButton"]:
		theme.set_color("font_hover_color", type_name, Color.WHITE)
		theme.set_color("font_pressed_color", type_name, Color.WHITE)
		theme.set_color("font_focus_color", type_name, Color.WHITE)
	theme.set_color("font_placeholder_color", "LineEdit", TEXT_MUTED)
	theme.set_color("font_outline_color", "Label", Color("07131d"))
	theme.set_constant("outline_size", "Label", 1)


static func _apply_control_styles(theme: Theme) -> void:
	var normal := _box(SURFACE_RAISED, BORDER)
	var hover := _box(SURFACE_HOVER, BORDER_HOVER)
	var pressed := _box(SURFACE_PRESSED, BORDER_ACTIVE)
	var focus := _box(SURFACE_HOVER, FOCUS, 2)

	for type_name in ["Button", "OptionButton"]:
		_set_interaction_boxes(theme, type_name, normal, hover, pressed, focus)

	theme.set_stylebox("normal", "LineEdit", normal)
	theme.set_stylebox("read_only", "LineEdit", _box(SURFACE, BORDER))
	theme.set_stylebox("focus", "LineEdit", focus)
	theme.set_stylebox("updown", "SpinBox", normal)
	theme.set_stylebox("normal", "SpinBox", normal)
	theme.set_stylebox("focus", "SpinBox", focus)

	# CheckButton retains Godot's familiar check glyph while gaining the shared focus and text treatment.
	theme.set_stylebox("normal", "CheckButton", _transparent_box())
	theme.set_stylebox("hover", "CheckButton", _transparent_box(BORDER_HOVER))
	theme.set_stylebox("focus", "CheckButton", _transparent_box(FOCUS, 2))

	theme.set_stylebox("slider", "HSlider", _box(SURFACE, BORDER, 4, 1, 4, 4))
	theme.set_stylebox("grabber_area", "HSlider", _box(ACCENT, BORDER_ACTIVE, RADIUS, 1, 8, 8))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _box(ACCENT_HOVER, FOCUS, RADIUS, 1, 8, 8))

	var popup_panel := _box(SURFACE, BORDER, RADIUS, 1, 10, 10)
	theme.set_stylebox("panel", "PopupMenu", popup_panel)
	theme.set_stylebox("hover", "PopupMenu", _box(SURFACE_HOVER, BORDER_HOVER, 6, 1, 8, 6))
	theme.set_stylebox("separator", "PopupMenu", _box(BORDER, BORDER, 0, 0, 1, 1))
	theme.set_constant("item_start_padding", "PopupMenu", 10)
	theme.set_constant("item_end_padding", "PopupMenu", 10)
	theme.set_constant("v_separation", "PopupMenu", 4)


static func _apply_container_styles(theme: Theme) -> void:
	theme.set_stylebox("panel", "PanelContainer", _box(SURFACE, BORDER, 16, 1, 14, 12))


static func _apply_variations(theme: Theme) -> void:
	theme.set_type_variation("AccentButton", "Button")
	theme.set_type_variation("ScalePlayButton", "Button")
	theme.set_type_variation("ScalePlayButtonActive", "Button")
	_set_interaction_boxes(
		theme,
		"AccentButton",
		_box(ACCENT, BORDER_ACTIVE),
		_box(ACCENT_HOVER, FOCUS),
		_box(ACCENT_PRESSED, BORDER_ACTIVE),
		_box(ACCENT_HOVER, FOCUS, 2)
	)
	_set_interaction_boxes(theme, "ScalePlayButton", _box(SURFACE_RAISED, BORDER_ACTIVE, RADIUS, 1, 16, 10), _box(SURFACE_HOVER, FOCUS, RADIUS, 1, 16, 10), _box(SURFACE_PRESSED, BORDER_ACTIVE, RADIUS, 1, 16, 10), _box(SURFACE_HOVER, FOCUS, RADIUS, 2, 16, 10))
	_set_interaction_boxes(theme, "ScalePlayButtonActive", _box(ACCENT_PRESSED, BORDER_ACTIVE, RADIUS, 1, 16, 10), _box(ACCENT, FOCUS, RADIUS, 1, 16, 10), _box(SURFACE_PRESSED, BORDER_ACTIVE, RADIUS, 1, 16, 10), _box(ACCENT, FOCUS, RADIUS, 2, 16, 10))
	theme.set_color("font_color", "ScalePlayButton", ACCENT_HOVER)
	theme.set_color("font_color", "ScalePlayButtonActive", TEXT_PRIMARY)

	for variation in ["SegmentButton", "SegmentSelected", "IconButton", "FooterButton", "NavButton", "NavSelected", "TabButton", "TabSelected", "LayerSelected", "PracticeButton"]:
		theme.set_type_variation(variation, "Button")
	_set_interaction_boxes(
		theme,
		"SegmentButton",
		_box(SURFACE, BORDER, 6, 1, 12, 6),
		_box(SURFACE_HOVER, BORDER_HOVER, 6, 1, 12, 6),
		_box(SURFACE_PRESSED, BORDER_ACTIVE, 6, 1, 12, 6),
		_box(SURFACE_HOVER, FOCUS, 6, 2, 12, 6)
	)
	_set_interaction_boxes(theme, "TabButton", _box(Color("061827"), Color("14334a"), 0, 0, 18, 8), _box(Color("0b2638"), Color("24516a"), 0, 0, 18, 8), _box(Color("0c3347"), ACCENT, 0, 0, 18, 8), _box(Color("0b2638"), FOCUS, 0, 2, 18, 8))
	_set_interaction_boxes(theme, "TabSelected", _box(Color("082032"), ACCENT, 0, 0, 18, 8), _box(Color("0b293c"), ACCENT_HOVER, 0, 0, 18, 8), _box(Color("0d3c50"), ACCENT, 0, 0, 18, 8), _box(Color("0b293c"), FOCUS, 0, 2, 18, 8))
	theme.set_color("font_color", "TabButton", Color("a6bde0"))
	for state in ["normal", "hover", "pressed"]:
		# Keep the inactive tab's layout footprint equal to TabSelected. Otherwise
		# the selected underline changes the minimum height of the whole tab row.
		theme.get_stylebox(state, "TabButton").border_width_bottom = 3
		theme.get_stylebox(state, "TabSelected").border_width_bottom = 3
	theme.set_color("font_color", "TabSelected", ACCENT)
	_set_interaction_boxes(theme, "LayerSelected", _box(Color("0d6198"), ACCENT, 8, 2, 14, 7), _box(Color("1474a8"), ACCENT_HOVER, 8, 2, 14, 7), _box(Color("0b526f"), ACCENT, 8, 2, 14, 7), _box(Color("1474a8"), FOCUS, 8, 2, 14, 7))
	_set_interaction_boxes(theme, "PracticeButton", _box(Color("092037"), Color("174267"), 14, 1, 22, 10), _box(Color("0d2b44"), ACCENT, 14, 1, 22, 10), _box(Color("0e4059"), ACCENT, 14, 1, 22, 10), _box(Color("0d2b44"), FOCUS, 14, 2, 22, 10))
	_set_interaction_boxes(
		theme,
		"SegmentSelected",
		_box(ACCENT, BORDER_ACTIVE, 6, 1, 12, 6),
		_box(ACCENT_HOVER, FOCUS, 6, 1, 12, 6),
		_box(ACCENT_PRESSED, BORDER_ACTIVE, 6, 1, 12, 6),
		_box(ACCENT_HOVER, FOCUS, 6, 2, 12, 6)
	)
	_set_interaction_boxes(theme, "IconButton", _box(SURFACE_RAISED, BORDER, 99, 1, 10, 10), _box(SURFACE_HOVER, BORDER_HOVER, 99, 1, 10, 10), _box(SURFACE_PRESSED, BORDER_ACTIVE, 99, 1, 10, 10), _box(SURFACE_HOVER, FOCUS, 99, 2, 10, 10))
	_set_interaction_boxes(
		theme,
		"FooterButton",
		_box(Color("10202d"), BORDER, 22, 1, 16, 8),
		_box(SURFACE_HOVER, BORDER_HOVER, 22, 1, 16, 8),
		_box(SURFACE_PRESSED, BORDER_ACTIVE, 22, 1, 16, 8),
		_box(SURFACE_HOVER, FOCUS, 22, 2, 16, 8)
	)
	_set_interaction_boxes(
		theme,
		"NavButton",
		_box(Color("071824"), Color.TRANSPARENT, 18, 0, 20, 10),
		_box(Color("0d2939"), BORDER, 18, 1, 20, 10),
		_box(Color("103f50"), BORDER_ACTIVE, 18, 1, 20, 10),
		_box(Color("0d2939"), FOCUS, 18, 2, 20, 10)
	)
	_set_interaction_boxes(
		theme,
		"NavSelected",
		_box(Color("0b2b3b"), BORDER_ACTIVE, 18, 1, 20, 10),
		_box(Color("10394a"), FOCUS, 18, 1, 20, 10),
		_box(Color("0d5163"), BORDER_ACTIVE, 18, 1, 20, 10),
		_box(Color("10394a"), FOCUS, 18, 2, 20, 10)
	)

	for variation in ["HeaderPanel", "SettingsPanel", "SummaryPanel", "ToolbarPanel", "NavPanel", "TabsPanel", "TheoryPanel", "PracticePanel"]:
		theme.set_type_variation(variation, "PanelContainer")
	theme.set_stylebox("panel", "HeaderPanel", _box(Color("071a26", 0.78), BORDER, 0, 1, 0, 0))
	theme.set_stylebox("panel", "SettingsPanel", _box(SURFACE, BORDER, 16, 1, 16, 14))
	theme.set_stylebox("panel", "SummaryPanel", _box(Color("081a26", 0.72), Color("18384a"), 16, 1, 18, 12))
	theme.set_stylebox("panel", "ToolbarPanel", _box(Color("071a26", 0.82), Color("173648"), 18, 1, 16, 8))
	theme.set_stylebox("panel", "NavPanel", _box(Color("061723", 0.94), Color("1b4155"), 20, 1, 8, 8))
	theme.set_stylebox("panel", "TabsPanel", _box(Color("061827", 0.92), Color("16374e"), 0, 1, 0, 0))
	theme.set_stylebox("panel", "TheoryPanel", _box(Color("051725", 0.94), Color("17405d"), 18, 1, 0, 0))
	theme.set_stylebox("panel", "PracticePanel", _box(Color("09243a", 0.96), ACCENT, 12, 1, 16, 8))
	theme.set_type_variation("HintLabel", "Label")
	theme.set_color("font_color", "HintLabel", Color("9bb8cf"))
	theme.set_type_variation("SectionLabel", "Label")
	theme.set_color("font_color", "SectionLabel", Color("b9d7e8"))
	theme.set_font_size("font_size", "SectionLabel", 14)


static func _set_interaction_boxes(theme: Theme, type_name: StringName, normal: StyleBox, hover: StyleBox, pressed: StyleBox, focus: StyleBox) -> void:
	theme.set_stylebox("normal", type_name, normal)
	theme.set_stylebox("hover", type_name, hover)
	theme.set_stylebox("pressed", type_name, pressed)
	theme.set_stylebox("focus", type_name, focus)


static func _box(fill: Color, border: Color, radius: int = RADIUS, border_width: int = 1, horizontal_margin: int = 12, vertical_margin: int = 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = horizontal_margin
	box.content_margin_right = horizontal_margin
	box.content_margin_top = vertical_margin
	box.content_margin_bottom = vertical_margin
	return box


static func _transparent_box(border: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	return _box(Color.TRANSPARENT, border, RADIUS, border_width, 8, 6)

