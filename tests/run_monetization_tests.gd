extends SceneTree

var state_path := "res://.godot/verification/fret_formula_monetization_test_%d.json" % Time.get_ticks_usec()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_launch_schedule_and_idempotency()
	await _test_debug_service()
	_test_platform_contracts()
	_remove(state_path)
	print("Monetization tests passed: launch schedule, transaction idempotency, SDK labels and platform bridges.")
	quit()


func _test_launch_schedule_and_idempotency() -> void:
	var store := MonetizationStateStore.new(state_path)
	var offered_at: Array[int] = []
	for launch in range(1, 16):
		var result := store.register_launch()
		assert(result.ok, str(result))
		if result.should_offer:
			offered_at.append(launch)
	assert(offered_at == [5, 10, 15])
	for _launch in 5:
		assert(not store.register_launch().should_offer)
	_remove(state_path)
	store = MonetizationStateStore.new(state_path)
	for _launch in 4:
		assert(not store.register_launch().should_offer)
	assert(store.record_transaction("transaction-before-offer").ok)
	for _launch in 11:
		assert(not store.register_launch().should_offer)
	_remove(state_path)
	store = MonetizationStateStore.new(state_path)
	var first := store.record_transaction("transaction-1")
	var duplicate := store.record_transaction("transaction-1")
	assert(first.ok and first.is_new and first.support_count == 1)
	assert(duplicate.ok and not duplicate.is_new and duplicate.support_count == 1)


func _test_debug_service() -> void:
	_remove(state_path)
	var service := DonationService.new(state_path)
	service.adapter_override = DebugDonationAdapter.new()
	root.add_child(service)
	service.initialize()
	for _frame in 4:
		await process_frame
	assert(service.platform_id == "debug")
	assert(service.products.size() == 3, str(service.products))
	assert(str(service.products[0].get("button_text", "")) == "99 ₽", str(service.products))
	assert(str(service.products[1].get("button_text", "")) == "199 ₽", str(service.products))
	assert(str(service.products[2].get("button_text", "")) == "499 ₽", str(service.products))
	assert(service.can_purchase())
	assert(service.purchase("fret_formula_donation_199"))
	for _frame in 3:
		await process_frame
	assert(service.support_count() == 1 and service.has_supported())
	assert(service.purchase("fret_formula_donation_499"))
	for _frame in 3:
		await process_frame
	assert(service.support_count() == 2)
	assert(service.products.size() == 3)
	assert(service.can_purchase("fret_formula_donation_99"))
	service.queue_free()
	await process_frame


func _test_platform_contracts() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/monetization.json"))
	assert(config.platforms.rustore.products.size() == 3)
	assert(config.platforms.yandex_games.products.size() == 3)
	assert(config.platforms.rustore.products[0].product_id == "fret_formula_donation_99")
	assert(config.platforms.rustore.products[2].product_id == "fret_formula_donation_499")
	assert(not config.platforms.vk_mini_apps.enabled)
	var yandex_shell := FileAccess.get_file_as_string("res://web/yandex_shell.html")
	assert(yandex_shell.contains("getCatalog") and yandex_shell.contains("product.title"))
	assert(yandex_shell.contains("product.price") and yandex_shell.contains("consumePurchase"))
	assert(yandex_shell.contains("purchaseToken") and yandex_shell.contains("productIdsJson"))
	var vk_shell := FileAccess.get_file_as_string("res://web/vk_shell.html")
	assert(vk_shell.contains("sdk_catalog_unavailable") and vk_shell.contains("not_configured"))


func _remove(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
