class_name DonationService
extends Node

signal product_changed(info: Dictionary)
signal products_changed(products: Array[Dictionary])
signal availability_changed(available: bool, status: String)
signal purchase_pending_changed(pending: bool)
signal purchase_finished(success: bool, status: String)
signal support_count_changed(count: int)

const CONFIG_PATH := "res://config/monetization.json"

var state_store: MonetizationStateStore
var adapter_override: DonationAdapter
var product_info: Dictionary = {}
var products: Array[Dictionary] = []
var platform_id := "unsupported"
var _configuration: Dictionary = {}
var _adapter: DonationAdapter
var _purchase_pending := false


func _init(state_path: String = MonetizationStateStore.DEFAULT_PATH) -> void:
	state_store = MonetizationStateStore.new(state_path)


func initialize() -> void:
	_configuration = _load_configuration()
	platform_id = _detect_platform()
	var platform_configuration: Dictionary = _configuration.get("platforms", {}).get(platform_id, {}).duplicate(true)
	if not bool(platform_configuration.get("enabled", false)) or _configured_products(platform_configuration).is_empty():
		availability_changed.emit(false, "not_configured")
		return
	_adapter = adapter_override if adapter_override != null else _create_adapter(platform_id)
	_adapter.initialized.connect(_on_initialized)
	_adapter.catalog_loaded.connect(_on_catalog_loaded)
	_adapter.catalog_unavailable.connect(func(status: String): availability_changed.emit(false, status))
	_adapter.purchase_finished.connect(_on_purchase_finished)
	_adapter.purchase_recovered.connect(_on_purchase_recovered)
	_adapter.initialize(platform_configuration)


func register_launch_and_should_offer() -> bool:
	return bool(state_store.register_launch().get("should_offer", false))


func can_purchase(product_id: String = "") -> bool:
	if _purchase_pending or products.is_empty():
		return false
	return product_id.is_empty() or not _find_product(product_id).is_empty()


func purchase(product_id: String = "") -> bool:
	var requested_id := product_id
	if requested_id.is_empty() and not products.is_empty():
		requested_id = str(products[0].get("product_id", ""))
	if not can_purchase(requested_id) or _adapter == null:
		return false
	_purchase_pending = true
	purchase_pending_changed.emit(true)
	_adapter.purchase(requested_id)
	return true


func support_count() -> int:
	return int(state_store.load_state().support_count)


func has_supported() -> bool:
	return support_count() > 0


func _on_initialized(success: bool, status: String) -> void:
	if not success:
		availability_changed.emit(false, status)
		return
	_adapter.load_products()
	_adapter.restore_pending_purchases()


func _on_catalog_loaded(catalog: Array[Dictionary]) -> void:
	var ordered_products: Array[Dictionary] = []
	var platform_configuration: Dictionary = _configuration.get("platforms", {}).get(platform_id, {})
	for configured_product in _configured_products(platform_configuration):
		var product_id := str(configured_product.get("product_id", ""))
		var sdk_product := _find_product_in(catalog, product_id)
		if sdk_product.is_empty():
			availability_changed.emit(false, "catalog_incomplete")
			return
		var title := str(sdk_product.get("title", ""))
		var price := str(sdk_product.get("price", ""))
		var button_style := str(configured_product.get("button_style", "price_only"))
		var button_text := "%s · %s" % [title, price] if button_style == "title_price" else price
		if button_text.strip_edges().is_empty() or price.is_empty() or (button_style == "title_price" and title.is_empty()):
			availability_changed.emit(false, "sdk_label_missing")
			return
		var decorated := sdk_product.duplicate(true)
		decorated["button_text"] = button_text
		decorated["button_style"] = button_style
		ordered_products.append(decorated)
	products = ordered_products
	product_info = products[0].duplicate(true)
	product_changed.emit(product_info)
	products_changed.emit(products)
	availability_changed.emit(true, "ready")


func _on_purchase_finished(success: bool, status: String, product_id: String, transaction_id: String) -> void:
	_purchase_pending = false
	purchase_pending_changed.emit(false)
	if not success or _find_product(product_id).is_empty():
		purchase_finished.emit(false, status)
		return
	var result := state_store.record_transaction(transaction_id)
	if not bool(result.ok):
		purchase_finished.emit(false, "persistence_failed")
		return
	_adapter.acknowledge(transaction_id)
	if bool(result.is_new):
		support_count_changed.emit(int(result.support_count))
	purchase_finished.emit(true, "confirmed" if bool(result.is_new) else "duplicate_callback")


func _on_purchase_recovered(product_id: String, transaction_id: String) -> void:
	var platform_configuration: Dictionary = _configuration.get("platforms", {}).get(platform_id, {})
	var configured_ids: Array[String] = []
	for configured_product in _configured_products(platform_configuration):
		configured_ids.append(str(configured_product.get("product_id", "")))
	if not configured_ids.has(product_id):
		return
	var result := state_store.record_transaction(transaction_id)
	if bool(result.ok):
		_adapter.acknowledge(transaction_id)
		if bool(result.is_new):
			support_count_changed.emit(int(result.support_count))


func _detect_platform() -> String:
	if adapter_override != null:
		return adapter_override.platform_id
	if OS.has_feature("rustore"):
		return "rustore"
	if OS.has_feature("yandex_games"):
		return "yandex_games"
	if OS.has_feature("vk_mini_apps"):
		return "vk_mini_apps"
	if OS.is_debug_build() or OS.has_feature("editor"):
		return "debug"
	return "unsupported"


func _create_adapter(detected_platform: String) -> DonationAdapter:
	match detected_platform:
		"debug": return DebugDonationAdapter.new()
		"rustore": return RuStoreDonationAdapter.new()
		"yandex_games", "vk_mini_apps": return WebDonationAdapter.new(detected_platform)
		_: return UnsupportedDonationAdapter.new()


func _load_configuration() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary and int(parsed.get("schema_version", -1)) == 1:
		return parsed
	return {}


func _configured_products(platform_configuration: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for product_value in platform_configuration.get("products", []):
		if product_value is Dictionary and not str(product_value.get("product_id", "")).is_empty():
			result.append(product_value)
	return result


func _find_product(product_id: String) -> Dictionary:
	return _find_product_in(products, product_id)


func _find_product_in(catalog: Array[Dictionary], product_id: String) -> Dictionary:
	for product in catalog:
		if str(product.get("product_id", "")) == product_id:
			return product
	return {}
