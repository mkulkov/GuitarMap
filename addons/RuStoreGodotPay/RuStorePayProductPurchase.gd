# RuStorePayPurchase
# @brief Информация о покупке.
class_name RuStorePayProductPurchase extends RuStorePayPurchase

# @brief Статус покупки.
var status: ERuStorePayProductPurchaseStatus.Item:
	set(v):
		_set_status(v)
	get:
		return get_status()

# @brief Идентификатор продукта, который был присвоен продукту в консоли RuStore.
var productId: RuStorePayProductId = null

# @brief Тип продукта.
var productType: ERuStorePayProductType.Item = 0

# @brief Количество продукта.
var quantity: RuStorePayQuantity = null

# @brief Состояние подтверждения покупки.
var acknowledgementState: ERuStorePayAcknowledgementState.Item = ERuStorePayAcknowledgementState.Item.UNKNOWN
