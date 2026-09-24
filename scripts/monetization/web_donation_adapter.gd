class_name WebDonationAdapter
extends DonationAdapter

var _bridge: Variant
var _initialize_callback: JavaScriptObject
var _catalog_callback: JavaScriptObject
var _purchase_callback: JavaScriptObject
var _restore_callback: JavaScriptObject
var _acknowledge_callback: JavaScriptObject


func _init(platform_value: String = "web") -> void:
	platform_id = platform_value


func initialize(configuration_value: Dictionary) -> void:
	configuration = configuration_value.duplicate(true)
	if not OS.has_feature("web"):
		initialized.emit(false, "not_web")
		return
	_bridge = JavaScriptBridge.get_interface("FretFormulaPlatform")
	if _bridge == null:
		initialized.emit(false, "bridge_unavailable")
		return
	_initialize_callback = JavaScriptBridge.create_callback(_on_initialized)
	_bridge.initialize(_initialize_callback)


func _on_initialized(arguments: Array) -> void:
	var data := _decode(arguments)
	var actual_platform := str(data.get("platform", ""))
	initialized.emit(bool(data.get("success", false)) and actual_platform == platform_id, str(data.get("status", "failed")))


func load_products() -> void:
	_catalog_callback = JavaScriptBridge.create_callback(_on_catalog_loaded)
	_bridge.loadDonationCatalog(JSON.stringify(_configured_product_ids()), _catalog_callback)


func _on_catalog_loaded(arguments: Array) -> void:
	var data := _decode(arguments)
	if not bool(data.get("success", false)):
		catalog_unavailable.emit(str(data.get("status", "catalog_unavailable")))
		return
	var products: Array[Dictionary] = []
	for product_value in data.get("products", []):
		if product_value is Dictionary:
			products.append(product_value)
	catalog_loaded.emit(products)


func purchase(product_id: String) -> void:
	_purchase_callback = JavaScriptBridge.create_callback(_on_purchase_finished)
	_bridge.purchaseDonation(product_id, _purchase_callback)


func _on_purchase_finished(arguments: Array) -> void:
	var data := _decode(arguments)
	purchase_finished.emit(
		bool(data.get("success", false)),
		str(data.get("status", "failed")),
		str(data.get("product_id", "")),
		str(data.get("transaction_id", ""))
	)


func restore_pending_purchases() -> void:
	_restore_callback = JavaScriptBridge.create_callback(_on_restored)
	_bridge.restoreDonations(JSON.stringify(_configured_product_ids()), _restore_callback)


func _on_restored(arguments: Array) -> void:
	var data := _decode(arguments)
	var purchases: Variant = data.get("purchases", [])
	if not purchases is Array:
		return
	for purchase_value in purchases:
		if purchase_value is Dictionary:
			purchase_recovered.emit(str(purchase_value.get("product_id", "")), str(purchase_value.get("transaction_id", "")))


func acknowledge(transaction_id: String) -> void:
	if _acknowledge_callback == null:
		_acknowledge_callback = JavaScriptBridge.create_callback(func(_arguments: Array): pass)
	_bridge.acknowledgeDonation(transaction_id, _acknowledge_callback)


func _decode(arguments: Array) -> Dictionary:
	if arguments.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(str(arguments[0]))
	return parsed if parsed is Dictionary else {}


func _configured_product_ids() -> Array[String]:
	var result: Array[String] = []
	for product_configuration in configuration.get("products", []):
		if product_configuration is Dictionary:
			var product_id := str(product_configuration.get("product_id", ""))
			if not product_id.is_empty():
				result.append(product_id)
	return result
