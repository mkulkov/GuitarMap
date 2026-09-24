# RuStorePaymentException
# @brief Информация об ошибках платежного клиента.
class_name RuStorePaymentException extends RuStoreError

# @brief Информация об ошибке.
var cause: RuStoreError = null

# @brief Схема приложения не задана.
class ApplicationSchemeWasNotProvided extends RuStorePaymentException:
	pass


# @brief Ошибка получения платежного токена.
class EmptyPaymentTokenException extends RuStorePaymentException:
	pass


# @brief Произошла отмена покупки продукта (пользователь закрыл платежную шторку).
class ProductPurchaseCancelled extends RuStorePaymentException:
	
	# @brief Тип продукта (необязательный параметр).
	var productType: ERuStorePayProductType.Item = 0
	
	# @brief Идентификатор покупки (необязательный параметр).
	var purchaseId: RuStorePayPurchaseId = null
	
	# @brief Тип покупки (необязательный параметр).
	var purchaseType: ERuStorePayPurchaseType.Item = 0


# @brief Ошибка покупки продукта (невозможно установить статус покупки).
class ProductPurchaseException extends RuStorePaymentException:
	
	# @brief Идентификатор счёта (необязательный параметр).
	var invoiceId: RuStorePayInvoiceId = null
	
	# @brief
	#	Уникальный идентификатор оплаты, сформированный приложением (необязательный параметр).
	#	Если вы укажете этот параметр в вашей системе, вы получите его в ответе при работе с API.
	#	Если не укажете, он будет сгенерирован автоматически (uuid).
	#	Максимальная длина 150 символов.
	var orderId: RuStorePayOrderId = null
	
	# @brief Идентификатор продукта, который был присвоен продукту в консоли RuStore (необязательный параметр).
	var productId: RuStorePayProductId = null
	
	# @brief Тип продукта (необязательный параметр).
	var productType: ERuStorePayProductType.Item = 0
	
	# @brief Идентификатор покупки (необязательный параметр).
	var purchaseId: RuStorePayPurchaseId = null
	
	# @brief Тип покупки (необязательный параметр).
	var purchaseType: ERuStorePayPurchaseType.Item = 0
	
	# @brief Количество продукта (необязательный параметр).
	var quantity: RuStorePayQuantity = null
	
	# @brief
	#	Флаг, указывающий признак тестового платежа в песочнице.
	#	Если true — покупка совершена в режиме тестирования.
	var sandbox: bool = false


# @brief Ошибка повторной инициализации SDK.
class RuStorePayClientAlreadyExist extends RuStorePaymentException:
	pass


# @brief Попытка обратиться к публичным интерфейсам SDK до момента её инициализации.
class RuStorePayClientNotCreated extends RuStorePaymentException:
	pass


# @brief Запущен процесс оплаты неизвестного типа продукта.
class RuStorePayInvalidActivePurchase extends RuStorePaymentException:
	pass


# @brief Не задан обязательный параметр console_app_id_value для инициализации SDK.
class RuStorePayInvalidConsoleAppId extends RuStorePaymentException:
	pass


# @brief Неверная сигнатура ответа (возникает при попытке совершить мошеннические действия).
class RuStorePaySignatureException extends RuStorePaymentException:
	pass


# @brief Общая ошибка SDK.
class RuStorePaymentCommonException extends RuStorePaymentException:
	pass


# @brief Ошибка сетевого взаимодействия SDK.
class RuStorePaymentNetworkException extends RuStorePaymentException:
	
	# @brief Код ошибки.
	var code = ""
	
	# @brief Идентификатор ошибки.
	var id: String = ""


# @brief Ошибка оплаты сохраненной картой.
class RuStoreInvalidCardBindingIdException extends RuStorePaymentException:
	pass
