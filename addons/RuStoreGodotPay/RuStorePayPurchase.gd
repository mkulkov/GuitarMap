# RuStorePayPurchase
# @brief Информация о покупке.
class_name RuStorePayPurchase extends RefCounted

# @brief Идентификатор покупки.
var purchaseId: RuStorePayPurchaseId = null

# @brief Идентификатор счёта.
var invoiceId: RuStorePayInvoiceId = null

# @brief
#	Уникальный идентификатор оплаты, сформированный приложением (необязательный параметр).
#	Если вы укажете этот параметр в вашей системе, вы получите его в ответе при работе с API.
#	Если не укажете, он будет сгенерирован автоматически (uuid).
#	Максимальная длина 150 символов.
var orderId: RuStorePayOrderId = null

# @brief Тип покупки.
var purchaseType: ERuStorePayPurchaseType.Item = 0

# @brief Описание на языке language.
var description: RuStorePayDescription = null

# @brief Время покупки (необязательный параметр).
var purchaseTime: RuStorePayTime = null

# @brief Цена в минимальных единицах (например в копейках).
var price: RuStorePayPrice = null

# @brief Отформатированная цена покупки, включая валютный знак.
var amountLabel: RuStorePayAmountLabel = null

# @brief Код валюты ISO 4217.
var currency: RuStorePayCurrency = null

# @brief
#	Строка с дополнительной информацией о заказе,
#	которую вы можете установить при инициализации процесса покупки (необязательный параметр).
var developerPayload: RuStorePayDeveloperPayload = null

# @brief
#	Определяет, является ли платёж тестовым.
#	Значения могут быть true или false, где true обозначает тестовый платёж, а false – реальный.
var sandbox: bool = false

var _status = 0

func _set_status(value):
	_status = value
	
# @brief Статус покупки.
func get_status():
	return _status
