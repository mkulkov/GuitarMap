class_name RuStoreDonationAdapter
extends DonationAdapter

const PayClient = preload("res://addons/RuStoreGodotPay/RuStoreGodotPay.gd")
const ProductId = preload("res://addons/RuStoreGodotPay/RuStorePayProductId.gd")
const PurchaseId = preload("res://addons/RuStoreGodotPay/RuStorePayPurchaseId.gd")
const PurchaseParams = preload("res://addons/RuStoreGodotPay/RuStorePayProductPurchaseParams.gd")

var _client: Object
var _available := false
var _pending := false


func _init() -> void:
	platform_id = "rustore"


func initialize(configuration_value: Dictionary) -> void:
	configuration = configuration_value.duplicate(true)
	if not OS.has_feature("rustore") or not Engine.has_singleton("RuStoreGodotPay"):
		initialized.emit(false, "plugin_unavailable")
		return
	_client = PayClient.get_instance()
	_client.on_get_purchase_availability_success.connect(_on_availability_success)
	_client.on_get_purchase_availability_failure.connect(_on_availability_failure)
	_client.on_get_products_success.connect(_on_products_success)
	_client.on_get_products_failure.connect(_on_products_failure)
	_client.on_purchase_success.connect(_on_purchase_success)
	_client.on_purchase_failure.connect(_on_purchase_failure)
	_client.on_get_purchases_success.connect(_on_purchases_success)
	_client.on_get_purchases_failure.connect(_on_purchases_failure)
	_client.get_purchase_availability()


func _on_availability_success(result: Object) -> void:
	_available = result != null and bool(result.get("isAvailable"))
	initialized.emit(_available, "ready" if _available else "payments_unavailable")


func _on_availability_failure(error: Object) -> void:
	initialized.emit(false, _error_status(error))


func load_products() -> void:
	var product_ids := _configured_product_ids()
	if not _available or product_ids.is_empty():
		catalog_unavailable.emit("product_not_configured")
		return
	var sdk_product_ids: Array = []
	for product_id in product_ids:
		sdk_product_ids.append(ProductId.new(product_id))
	_client.get_products(sdk_product_ids)


func _on_products_success(products: Array) -> void:
	var configured_ids := _configured_product_ids()
	var catalog: Array[Dictionary] = []
	for product in products:
		if product == null or product.productId == null:
			continue
		var product_id := str(product.productId.value)
		if not configured_ids.has(product_id):
			continue
		var title := str(product.title.value) if product.title != null else ""
		var price := str(product.amountLabel.value) if product.amountLabel != null else ""
		catalog.append({
			"product_id": product_id,
			"title": title,
			"price": price,
		})
	if catalog.is_empty():
		catalog_unavailable.emit("product_unavailable")
		return
	catalog_loaded.emit(catalog)


func _on_products_failure(error: Object) -> void:
	catalog_unavailable.emit(_error_status(error))


func purchase(product_id: String) -> void:
	if not _available or _pending or not _configured_product_ids().has(product_id):
		purchase_finished.emit(false, "not_available", product_id, "")
		return
	_pending = true
	_client.purchase(PurchaseParams.new(ProductId.new(product_id)))


func _on_purchase_success(result: Object) -> void:
	_pending = false
	var product_id := str(result.productId.value) if result != null and result.productId != null else ""
	var transaction_id := str(result.purchaseId.value) if result != null and result.purchaseId != null else ""
	purchase_finished.emit(not product_id.is_empty() and not transaction_id.is_empty(), "confirmed", product_id, transaction_id)


func _on_purchase_failure(failed_product: Object, error: Object) -> void:
	_pending = false
	var product_id := str(failed_product.value) if failed_product != null else ""
	purchase_finished.emit(false, _error_status(error), product_id, "")


func restore_pending_purchases() -> void:
	if _client != null:
		_client.get_purchases()


func _on_purchases_success(purchases: Array) -> void:
	var configured_ids := _configured_product_ids()
	for purchase_value in purchases:
		if purchase_value != null and purchase_value.productId != null \
				and configured_ids.has(str(purchase_value.productId.value)) and purchase_value.purchaseId != null:
			purchase_recovered.emit(str(purchase_value.productId.value), str(purchase_value.purchaseId.value))


func _on_purchases_failure(_error: Object) -> void:
	pass


func acknowledge(transaction_id: String) -> void:
	if _client != null and not transaction_id.is_empty():
		_client.update_acknowledgement_state(
			PurchaseId.new(transaction_id),
			ERuStorePayAcknowledgementState.Item.ACKNOWLEDGED
		)


func _error_status(error: Object) -> String:
	if error != null:
		var error_name: Variant = error.get("name")
		if error_name != null and not str(error_name).is_empty():
			return str(error_name)
	return "provider_error"


func _configured_product_ids() -> Array[String]:
	var result: Array[String] = []
	for product_configuration in configuration.get("products", []):
		if product_configuration is Dictionary:
			var product_id := str(product_configuration.get("product_id", ""))
			if not product_id.is_empty():
				result.append(product_id)
	return result
