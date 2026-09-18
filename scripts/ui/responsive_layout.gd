class_name ResponsiveLayout
extends RefCounted

static func density_scale(dpi: int, mobile: bool) -> float:
	if not mobile or dpi <= 0:
		return 1.0
	return clampf(float(dpi) / 160.0, 1.0, 3.0)


static func policy_for(viewport_size: Vector2) -> Dictionary:
	# The desktop reference itself is a shallow 1035x381 landscape view. Height
	# alone must not hide the brand or turn it into the phone header.
	var compact := viewport_size.x < 760.0
	var category := "phone" if viewport_size.x < 900.0 else ("tablet" if viewport_size.x < 1400.0 else "desktop")
	return {
		"category": category,
		"compact": compact,
		"margin": 6 if compact else 12,
		"cell_size": 44 if compact else 48,
		"show_status": viewport_size.y >= 430.0,
	}


static func safe_margins(viewport_size: Vector2, window_size: Vector2i, safe_area: Rect2i, base_margin: int) -> Dictionary:
	var margins := {
		"left": base_margin,
		"right": base_margin,
		"top": base_margin,
		"bottom": base_margin,
	}
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or window_size.x <= 0 or window_size.y <= 0:
		return margins
	if safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return margins
	var scale := Vector2(viewport_size.x / float(window_size.x), viewport_size.y / float(window_size.y))
	margins.left = maxi(base_margin, roundi(maxf(0.0, safe_area.position.x * scale.x)))
	margins.right = maxi(base_margin, roundi(maxf(0.0, (window_size.x - safe_area.end.x) * scale.x)))
	margins.top = maxi(base_margin, roundi(maxf(0.0, safe_area.position.y * scale.y)))
	margins.bottom = maxi(base_margin, roundi(maxf(0.0, (window_size.y - safe_area.end.y) * scale.y)))
	return margins
