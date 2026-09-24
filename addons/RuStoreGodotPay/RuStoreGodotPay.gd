# RuStoreGodotPayClient
# @brief Класс реализует API для интеграции платежей в мобильное приложение.
class_name RuStoreGodotPayClient extends Object

const SINGLETON_NAME = "RuStoreGodotPay"

var _isInitialized: bool = false
var _clientWrapper: Object = null

var _core_client: RuStoreGodotCoreUtils = null

# @brief Действие, выполняемое при успешном завершении операции get_user_authorization_status.
signal on_get_user_authorization_status_success

# @brief Действие, выполняемое в случае ошибки get_user_authorization_status.
signal on_get_user_authorization_status_failure

# @brief Действие, выполняемое при успешном завершении операции get_purchase_availability.
signal on_get_purchase_availability_success

# @brief Действие, выполняемое в случае ошибки get_purchase_availability.
signal on_get_purchase_availability_failure

# @brief Действие, выполняемое при успешном завершении операции get_products.
signal on_get_products_success

# @brief Действие, выполняемое в случае ошибки get_products.
signal on_get_products_failure

# @brief Действие, выполняемое при успешном завершении операции get_purchases.
signal on_get_purchases_success

# @brief Действие, выполняемое в случае ошибки get_purchases.
signal on_get_purchases_failure

# @brief Действие, выполняемое при успешном завершении операции get_purchase.
signal on_get_purchase_success

# @brief Действие, выполняемое в случае ошибки get_purchase.
signal on_get_purchase_failure

# @brief Действие, выполняемое при успешном завершении операции purchase.
signal on_purchase_success

# @brief Действие, выполняемое в случае ошибки purchase.
signal on_purchase_failure

# @brief Действие, выполняемое при успешном завершении операции purchase_two_step.
signal on_purchase_two_step_success

# @brief Действие, выполняемое в случае ошибки purchase_two_step.
signal on_purchase_two_step_failure

# @brief Действие, выполняемое при успешном завершении операции confirm_two_step_purchase.
signal on_confirm_two_step_purchase_success

# @brief Действие, выполняемое в случае ошибки confirm_two_step_purchase.
signal on_confirm_two_step_purchase_failure

# @brief Действие, выполняемое при успешном завершении операции cancel_two_step_purchas.
signal on_cancel_two_step_purchase_success

# @brief Действие, выполняемое в случае ошибки cancel_two_step_purchas.
signal on_cancel_two_step_purchase_failure

# @brief Действие, выполняемое при успешном завершении операции update_acknowledgement_state.
signal on_update_acknowledgement_state_success

# @brief Действие, выполняемое в случае ошибки update_acknowledgement_state.
signal on_update_acknowledgement_state_failure

# @brief Действие, выполняемое при успешном завершении операции get_billing_subscriptions.
signal on_get_billing_subscriptions_success

# @brief Действие, выполняемое в случае ошибки get_billing_subscriptions.
signal on_get_billing_subscriptions_failure

# @brief Действие, выполняемое при успешном завершении платежа.
signal on_payment_completed

# @brief Действие, выполняемое при ошибке платежа.
signal on_payment_failed

# @brief Действие, выполняемое при начале процесса оплаты.
signal on_payment_started

# @brief Действие, выполняемое при отмене покупки пользователем.
signal on_purchase_cancelled

# @brief Действие, выполняемое при создании покупки.
signal on_purchase_created

static var _instance: RuStoreGodotPayClient = null


# @brief
#	Получить экземпляр RuStoreGodotPayClient.
# @return
#	Возвращает указатель на единственный экземпляр RuStoreGodotPayClient (реализация паттерна Singleton).
#	Если экземпляр еще не создан, создает его.
static func get_instance() -> RuStoreGodotPayClient:
	if _instance == null:
		_instance = RuStoreGodotPayClient.new()
	return _instance


func _init():
	_core_client = RuStoreGodotCoreUtils.get_instance()
	_clientWrapper = Engine.get_singleton(SINGLETON_NAME)
	_clientWrapper.rustore_on_get_user_authorization_status_success.connect(_on_get_user_authorization_status_success)
	_clientWrapper.rustore_on_get_user_authorization_status_failure.connect(_on_get_user_authorization_status_failure)
	_clientWrapper.rustore_get_purchase_availability_success.connect(_on_get_purchase_availability_success)
	_clientWrapper.rustore_get_purchase_availability_failure.connect(_on_get_purchase_availability_failure)
	_clientWrapper.rustore_on_get_products_success.connect(_on_get_products_success)
	_clientWrapper.rustore_on_get_products_failure.connect(_on_get_products_failure)
	_clientWrapper.rustore_on_get_purchases_success.connect(_on_get_purchases_success)
	_clientWrapper.rustore_on_get_purchases_failure.connect(_on_get_purchases_failure)	
	_clientWrapper.rustore_on_get_purchase_success.connect(_on_get_purchase_success)
	_clientWrapper.rustore_on_get_purchase_failure.connect(_on_get_purchase_failure)
	_clientWrapper.rustore_on_purchase_success.connect(_on_purchase_success)
	_clientWrapper.rustore_on_purchase_failure.connect(_on_purchase_failure)
	_clientWrapper.rustore_on_purchase_two_step_success.connect(_on_purchase_two_step_success)
	_clientWrapper.rustore_on_purchase_two_step_failure.connect(_on_purchase_two_step_failure)
	_clientWrapper.rustore_on_confirm_two_step_purchase_success.connect(_on_confirm_two_step_purchase_success)
	_clientWrapper.rustore_on_confirm_two_step_purchase_failure.connect(_on_confirm_two_step_purchase_failure)
	_clientWrapper.rustore_on_cancel_two_step_purchase_success.connect(_on_cancel_two_step_purchase_success)
	_clientWrapper.rustore_on_cancel_two_step_purchase_failure.connect(_on_cancel_two_step_purchase_failure)
	_clientWrapper.rustore_on_update_acknowledgement_state_success.connect(_on_update_acknowledgement_state_success)
	_clientWrapper.rustore_on_update_acknowledgement_state_failure.connect(_on_update_acknowledgement_state_failure)
	_clientWrapper.rustore_on_get_billing_subscriptions_success.connect(_on_get_billing_subscriptions_success)
	_clientWrapper.rustore_on_get_billing_subscriptions_failure.connect(_on_get_billing_subscriptions_failure)
	_clientWrapper.rustore_on_payment_completed.connect(_on_payment_completed)
	_clientWrapper.rustore_on_payment_failed.connect(_on_payment_failed)
	_clientWrapper.rustore_on_payment_started.connect(_on_payment_started)
	_clientWrapper.rustore_on_purchase_cancelled.connect(_on_purchase_cancelled)
	_clientWrapper.rustore_on_purchase_created.connect(_on_purchase_created)


# Get user authorization status
# @brief Проверка статуса авторизации пользователя.
func get_user_authorization_status():
	_clientWrapper.getUserAuthorizationStatus()

func _on_get_user_authorization_status_success(data: String):
	var obj = ERuStorePayUserAuthorizationStatus.Item.get(data)
	if obj != null:
		on_get_user_authorization_status_success.emit(obj as ERuStorePayUserAuthorizationStatus.Item)
	else:
		var error = RuStoreError.new()
		error.name = "InvalidPurchaseStatus"
		error.description = "Received unknown purchase status: '%s'" % data
		on_get_user_authorization_status_failure.emit(obj)

func _on_get_user_authorization_status_failure(data: String):
	var obj = RuStorePayJsonParser.to_RuStorePaymentException_classes(data)
	on_get_user_authorization_status_failure.emit(obj)


# Get purchase availability
# @brief Проверка доступности платежей.
func get_purchase_availability():
	_clientWrapper.getPurchaseAvailability()

func _on_get_purchase_availability_success(data: String):
	var obj = RuStorePayJsonParser.ToPurchaseAvailabilityResult(data)
	on_get_purchase_availability_success.emit(obj)

func _on_get_purchase_availability_failure(data: String):
	var obj = RuStorePayJsonParser.to_RuStorePaymentException_classes(data)
	on_get_purchase_availability_failure.emit(obj)


# Is RuStore installed
# @brief Проверка установлен ли на устройстве пользователя RuStore.
# @return Возвращает true, если RuStore установлен, в противном случае — false.
# @deprecated
func is_rustore_installed() -> bool:
	return _clientWrapper.isRuStoreInstalled()


# Get products
# @brief Получение списка продуктов, добавленных в ваше приложение через консоль RuStore.
# @param productIds
#	Список идентификаторов продуктов (задаются при создании продукта в консоли разработчика).
#	Список продуктов имеет ограничение в размере 1000 элементов.
func get_products(productIds: Array[RuStorePayProductId]):
	var ids: Array[String] = []
	for item in productIds:
		ids.push_back(item.value)
	_clientWrapper.getProducts(ids)

func _on_get_products_success(data: String):
	var obj_arr: Array[RuStorePayProduct] = []
	var str_arr = JSON.parse_string(data)
	for str_item in str_arr:
		var obj_item: RuStorePayProduct = RuStorePayJsonParser.ToPayProduct(str(str_item))
		obj_arr.append(obj_item)
	on_get_products_success.emit(obj_arr)

func _on_get_products_failure(data: String):
	var obj = RuStorePayJsonParser.to_RuStorePaymentException_classes(data)
	on_get_products_failure.emit(obj)


# Get purchases
# @brief Получение списка покупок пользователя.
# @param product_type Тип продукта для фильтрации: ERuStorePayProductType.Item или null (все типы).
# @param purchase_status Статус покупки для фильтрации: ERuStorePayPurchaseStatusFilter.Item или null (все статусы).
# @param acknowledgement_state Состояние подтверждения для фильтрации: ERuStorePayAcknowledgementState.Item или null (все состояния).
func get_purchases(
		product_type: Variant = null,
		purchase_status: Variant = null,
		acknowledgement_state: Variant = null,
	):
	var _product_type = _get_enum_key_or_empty(ERuStorePayProductType.Item, product_type)
	
	var _purchase_status = _get_enum_key_or_empty(ERuStorePayPurchaseStatusFilter.Item, purchase_status)
	var _purchase_status_resolved = ""
	match _purchase_status:
		"PAID":
			_purchase_status_resolved = "ProductPurchaseStatus.PAID"
		"CONFIRMED":
			_purchase_status_resolved = "ProductPurchaseStatus.CONFIRMED"
		"ACTIVE":
			_purchase_status_resolved = "SubscriptionPurchaseStatus.ACTIVE"
		"PAUSED":
			_purchase_status_resolved = "SubscriptionPurchaseStatus.PAUSED"
	
	var _acknowledgement_state = _get_enum_key_or_empty(ERuStorePayAcknowledgementState.Item, acknowledgement_state)
	
	_clientWrapper.getPurchases(_product_type, _purchase_status_resolved, _acknowledgement_state)

func _get_enum_key_or_empty(enum_type: Dictionary, value: Variant, prefix: String = "") -> String:
	if value == null:
		return ""
	if not enum_type.values().has(value):
		push_error("Invalid enum value: ", value)
		return ""
	return prefix + enum_type.keys()[value]

func _on_get_purchases_success(data: String):
	var obj_arr: Array[RuStorePayPurchase] = []
	var str_arr = JSON.parse_string(data)
	for str_item in str_arr:
		var obj_item = RuStorePayJsonParser.ToPayPurchase(str(str_item))
		obj_arr.append(obj_item)
	on_get_purchases_success.emit(obj_arr)

func _on_get_purchases_failure(data: String):
	var obj = RuStorePayJsonParser.to_RuStorePaymentException_classes(data)
	on_get_purchases_failure.emit(obj)


# Get purchase
# @brief Получение информации о покупке.
# @param purchaseId Идентификатор продукта, который был присвоен продукту в консоли RuStore.
func get_purchase(purchase_id: RuStorePayPurchaseId):
	_clientWrapper.getPurchase(purchase_id.value)

func _on_get_purchase_success(data: String):
	var obj = RuStorePayJsonParser.ToPayPurchase(data)
	on_get_purchase_success.emit(obj)

func _on_get_purchase_failure(purchase_id: String, data: String):
	var id = RuStorePayPurchaseId.new(purchase_id)
	var obj = RuStorePayJsonParser.to_RuStorePaymentException_classes(data)
	on_get_purchase_failure.emit(purchase_id, obj)


# Purchase
# @brief Покупка продукта.
# @param parameters Параметры покупки продукта.
# @param preferred_purchase_type Предпочитаемый тип покупки.
# @param sdk_theme Цветовая тема платежной шторки.
# @param enable_purchase_event_listener Дополнительный набор callback функций.
func purchase(
		parameters: RuStorePayProductPurchaseParams,
		preferred_purchase_type: ERuStorePayPreferredPurchaseType.Item = ERuStorePayPreferredPurchaseType.Item.ONE_STEP,
		sdk_theme: ERuStorePaySdkTheme.Item = ERuStorePaySdkTheme.Item.LIGHT,
		enable_purchase_event_listener: bool = false,
	):
	var params: Dictionary = { "productId" : parameters.productId.value }
	if parameters.appUserEmail != null:
		params["appUserEmail"] = parameters.appUserEmail.value
	if parameters.appUserId != null:
		params["appUserId"] = parameters.appUserId.value
	if parameters.developerPayload != null:
		params["developerPayload"] = parameters.developerPayload.value
	if parameters.orderId != null:
		params["orderId"] = parameters.orderId.value
	if parameters.quantity != null:
		params["quantity"] = parameters.quantity.value
	_clientWrapper.purchase(
		params,
		ERuStorePayPreferredPurchaseType.Item.keys()[preferred_purchase_type],
		ERuStorePaySdkTheme.Item.keys()[sdk_theme],
		enable_purchase_event_listener,
	)

func _on_purchase_success(data: String):
	var obj = RuStorePayJsonParser.to_ProductPurchaseResult(data)
	on_purchase_success.emit(obj)

func _on_purchase_failure(productId: String, data: String):
	var id = RuStorePayProductId.new(productId)
	var obj = RuStorePayJsonParser.to_RuStorePaymentException_classes(data)
	on_purchase_failure.emit(id, obj)


# @brief Покупка продукта с двустадийной оплатой.
# @param parameters Параметры покупки продукта.
# @param sdk_theme Цветовая тема платежной шторки.
# @param enable_purchase_event_listener Дополнительный набор callback функций.
func purchase_two_step(
		parameters: RuStorePayProductPurchaseParams,
		sdk_theme: ERuStorePaySdkTheme.Item = ERuStorePaySdkTheme.Item.LIGHT,
		enable_purchase_event_listener: bool = false,
	):
	var params: Dictionary = { "productId" : parameters.productId.value }
	if parameters.appUserEmail != null:
		params["appUserEmail"] = parameters.appUserEmail.value
	if parameters.appUserId != null:
		params["appUserId"] = parameters.appUserId.value
	if parameters.developerPayload != null:
		params["developerPayload"] = parameters.developerPayload.value
	if parameters.orderId != null:
		params["orderId"] = parameters.orderId.value
	if parameters.quantity != null:
		params["quantity"] = parameters.quantity.value
	_clientWrapper.purchaseTwoStep(
		params,
		ERuStorePaySdkTheme.Item.keys()[sdk_theme],
		enable_purchase_event_listener
	)

func _on_purchase_two_step_success(data: String):
	var obj = RuStorePayJsonParser.to_ProductPurchaseResult(data)
	on_purchase_two_step_success.emit(obj)

func _on_purchase_two_step_failure(productId: String, data: String):
	var id = RuStorePayProductId.new(productId)
	var obj = RuStorePayJsonParser.to_RuStorePaymentException_classes(data)
	on_purchase_two_step_failure.emit(id, obj)

func _on_payment_completed(data: String) -> void:
	_emit_purchase_event(on_payment_completed, data)

func _on_payment_failed(data: String) -> void:
	_emit_purchase_event(on_payment_failed, data)

func _on_payment_started(data: String) -> void:
	_emit_purchase_event(on_payment_started, data)

func _on_purchase_cancelled(data: String) -> void:
	_emit_purchase_event(on_purchase_cancelled, data)

func _on_purchase_created(data: String) -> void:
	_emit_purchase_event(on_purchase_created, data)

func _emit_purchase_event(sig: Signal, data: String) -> void:
	var d := RuStorePayJsonParser.to_purchase_event_payload(data)
	sig.emit(d["productId"], d["purchaseId"], d["invoiceId"])


# Confirm purchase
# @brief
#	Потребление (подтверждение) покупки.
#	После вызова подтверждения покупка перейдёт в статус CONFIRMED.
#	Запрос на потребление (подтверждение) покупки должен сопровождаться выдачей товара.
# @param purchase_id Идентификатор покупки.
# @param developer_payload Строка, содержащая дополнительную информацию о заказе (необязательный параметр).
func confirm_two_step_purchase(purchase_id: RuStorePayPurchaseId, developer_payload: RuStorePayDeveloperPayload = null):
	var params: Dictionary = { "purchaseId" : purchase_id.value }
	if developer_payload != null:
		params["developerPayload"] = developer_payload.value
	_clientWrapper.confirmTwoStepPurchase(params)

func _on_confirm_two_step_purchase_success(purchase_id: String):
	var id = RuStorePayPurchaseId.new(purchase_id)
	on_confirm_two_step_purchase_success.emit(id)

func _on_confirm_two_step_purchase_failure(purchase_id: String, data: String):
	var id = RuStorePayPurchaseId.new(purchase_id)
	var obj = RuStorePayJsonParser.to_RuStorePaymentException_classes(data)
	on_confirm_two_step_purchase_failure.emit(id, obj)


# Cancel purchase
# @brief
#	Отмена покупки.
#	Запрос на потребление (подтверждение) покупки должен сопровождаться выдачей товара.
# @param purchase_id Идентификатор покупки.
func cancel_two_step_purchase(purchase_id: RuStorePayPurchaseId):
	_clientWrapper.cancelTwoStepPurchase(purchase_id.value)

func _on_cancel_two_step_purchase_success(purchase_id: String):
	var id = RuStorePayPurchaseId.new(purchase_id)
	on_cancel_two_step_purchase_success.emit(id)

func _on_cancel_two_step_purchase_failure(purchase_id: String, data: String):
	var id = RuStorePayPurchaseId.new(purchase_id)
	var obj = RuStorePayJsonParser.to_RuStorePaymentException_classes(data)
	on_cancel_two_step_purchase_failure.emit(id, obj)


# Update acknowledgement state
# @brief Обновление состояния подтверждения покупки.
# @param purchase_id Идентификатор покупки.
# @param state Новое состояние подтверждения покупки.
# @param developer_payload Строка, содержащая дополнительную информацию о заказе (необязательный параметр).
func update_acknowledgement_state(
		purchase_id: RuStorePayPurchaseId,
		state: ERuStorePayAcknowledgementState.Item,
		developer_payload: RuStorePayDeveloperPayload = null
	):
	var params: Dictionary = {
		"purchaseId": purchase_id.value,
		"state": ERuStorePayAcknowledgementState.Item.keys()[state]
	}
	if developer_payload != null:
		params["developerPayload"] = developer_payload.value
	
	_clientWrapper.updateAcknowledgementState(params)

func _on_update_acknowledgement_state_success(purchase_id: String, data: String):
	var id = RuStorePayPurchaseId.new(purchase_id)
	var obj = ERuStorePayAcknowledgementState.Item.get(data)
	on_update_acknowledgement_state_success.emit(id, obj)

func _on_update_acknowledgement_state_failure(purchase_id: String, data: String):
	var id = RuStorePayPurchaseId.new(purchase_id)
	var obj = RuStorePayJsonParser.to_RuStorePaymentException_classes(data)
	on_update_acknowledgement_state_failure.emit(id, obj)


# Get billing subscriptions
# @brief Получение списка подписок, оформленных в SDK Billing Client.
func get_billing_subscriptions():
	_clientWrapper.getBillingSubscriptions()

func _on_get_billing_subscriptions_success(data: String):
	var obj_arr: Array[RuStorePayBillingSubscription] = []
	var parsed_arr = JSON.parse_string(data)
	if parsed_arr == null:
		on_get_billing_subscriptions_success.emit([])
		return
	for item in parsed_arr:
		var obj_item = RuStorePayJsonParser.ToPayBillingSubscription(item)
		obj_arr.append(obj_item)
	on_get_billing_subscriptions_success.emit(obj_arr)

func _on_get_billing_subscriptions_failure(data: String):
	var obj = RuStorePayJsonParser.to_RuStorePaymentException_classes(data)
	on_get_billing_subscriptions_failure.emit(obj)
