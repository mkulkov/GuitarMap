extends SceneTree

func _init() -> void:
	var sizes := [Vector2(640, 360), Vector2(800, 360), Vector2(1024, 600), Vector2(1280, 800), Vector2(1280, 720), Vector2(1440, 900), Vector2(1920, 1080)]
	for size in sizes:
		var policy := ResponsiveLayout.policy_for(size)
		assert(policy.cell_size >= 44)
		assert(policy.margin >= 6)
	assert(ResponsiveLayout.policy_for(Vector2(640, 360)).category == "phone")
	assert(ResponsiveLayout.policy_for(Vector2(1024, 600)).category == "tablet")
	assert(ResponsiveLayout.policy_for(Vector2(1920, 1080)).category == "desktop")
	assert(not ResponsiveLayout.policy_for(Vector2(640, 360)).show_status)
	assert(is_equal_approx(ResponsiveLayout.density_scale(420, true), 2.625))
	assert(is_equal_approx(ResponsiveLayout.density_scale(640, true), 3.0))
	assert(is_equal_approx(ResponsiveLayout.density_scale(420, false), 1.0))
	assert(ResponsiveLayout.policy_for(Vector2(2400, 1080) / ResponsiveLayout.density_scale(420, true)).category == "tablet")
	var inset := ResponsiveLayout.safe_margins(Vector2(1280, 720), Vector2i(1280, 720), Rect2i(80, 0, 1200, 696), 12)
	assert(inset == {"left": 80, "right": 12, "top": 12, "bottom": 24})
	var scaled := ResponsiveLayout.safe_margins(Vector2(640, 360), Vector2i(1280, 720), Rect2i(80, 0, 1120, 720), 6)
	assert(scaled == {"left": 40, "right": 40, "top": 6, "bottom": 6})
	var unavailable := ResponsiveLayout.safe_margins(Vector2(640, 360), Vector2i(640, 360), Rect2i(), 6)
	assert(unavailable == {"left": 6, "right": 6, "top": 6, "bottom": 6})
	print("Responsive tests passed: sizes, density-independent touch cells and safe-area margins.")
	quit()
