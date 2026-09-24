class_name DebugDonationAdapter
extends DonationAdapter

var purchase_succeeds := true
var _sequence := 0


func _init() -> void:
	platform_id = "debug"


func initialize(configuration_value: Dictionary) -> void:
	configuration = configuration_value.duplicate(true)
	call_deferred("_finish_initialize")


func _finish_initialize() -> void:
	initialized.emit(bool(configuration.get("enabled", false)), "ready")


func load_products() -> void:
	var products: Array[Dictionary] = []
	for product_configuration_value in configuration.get("products", []):
		if not product_configuration_value is Dictionary:
			continue
		var product_configuration: Dictionary = product_configuration_value
		var product: Dictionary = product_configuration.get("product", {}).duplicate(true)
		product["product_id"] = str(product_configuration.get("product_id", ""))
		if str(product.product_id).is_empty() or str(product.get("title", "")).is_empty() \
				or str(product.get("price", "")).is_empty():
			catalog_unavailable.emit("debug_product_missing")
			return
		products.append(product)
	if products.is_empty():
		catalog_unavailable.emit("debug_catalog_missing")
		return
	call_deferred("_emit_catalog", products)


func _emit_catalog(products: Array[Dictionary]) -> void:
	catalog_loaded.emit(products)


func purchase(product_id: String) -> void:
	var configured_ids: Array[String] = []
	for product_configuration in configuration.get("products", []):
		if product_configuration is Dictionary:
			configured_ids.append(str(product_configuration.get("product_id", "")))
	if not configured_ids.has(product_id):
		purchase_finished.emit(false, "product_not_configured", product_id, "")
		return
	_sequence += 1
	var transaction_id := "debug-%d-%d" % [Time.get_ticks_usec(), _sequence]
	call_deferred("_finish_purchase", product_id, transaction_id)


func _finish_purchase(product_id: String, transaction_id: String) -> void:
	purchase_finished.emit(
		purchase_succeeds,
		"confirmed" if purchase_succeeds else "debug_declined",
		product_id,
		transaction_id if purchase_succeeds else ""
	)
