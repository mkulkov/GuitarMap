# RuStorePayPurchase
# @brief Информация о покупке.
class_name RuStorePaySubscriptionPurchase extends RuStorePayPurchase

# @brief Статус покупки.
var status: ERuStorePaySubscriptionPurchaseStatus.Item:
	set(v):
		_set_status(v)
	get:
		return get_status()

# @brief Идентификатор продукта, который был присвоен продукту в консоли RuStore.
var productId: RuStorePayProductId = null

# @brief Дата окончания срока действия подписки (необязательный параметр).
var expirationDate: RuStorePayTime = null

# @brief Флаг, указывающий, активен ли льготный период для подписки.
var gracePeriodEnabled: bool = false

# @brief Состояние подтверждения покупки.
var acknowledgementState: ERuStorePayAcknowledgementState.Item = ERuStorePayAcknowledgementState.Item.UNKNOWN
