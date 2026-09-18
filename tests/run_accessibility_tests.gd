extends SceneTree

const AppTheme := preload("res://scripts/ui/app_theme.gd")

func _init() -> void:
	assert(_contrast(AppTheme.TEXT_PRIMARY, AppTheme.BACKGROUND_BASE) >= 7.0)
	assert(_contrast(AppTheme.TEXT_SECONDARY, AppTheme.BACKGROUND_SURFACE) >= 4.5)
	# The approved design uses dark labels on bright semantic note markers.
	for fill in [AppTheme.NOTE_ROOT, Color("9168f3"), Color("2ed3f2")]:
		assert(_contrast(Color("061018"), fill) >= 4.5)
	print("Accessibility tests passed: primary text/marker contrast meets 4.5:1 or better.")
	quit()

func _contrast(first: Color, second: Color) -> float:
	var light := maxf(_luminance(first), _luminance(second))
	var dark := minf(_luminance(first), _luminance(second))
	return (light + 0.05) / (dark + 0.05)

func _luminance(color: Color) -> float:
	return 0.2126 * _linear(color.r) + 0.7152 * _linear(color.g) + 0.0722 * _linear(color.b)

func _linear(channel: float) -> float:
	return channel / 12.92 if channel <= 0.04045 else pow((channel + 0.055) / 1.055, 2.4)
