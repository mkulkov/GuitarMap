# RuStorePayBillingSubscription
# @brief Подписка, оформленная в SDK Billing Client.
class_name RuStorePayBillingSubscription extends RuStorePayPurchase

# @brief Статус подписки.
var status: ERuStorePaySubscriptionPurchaseStatus.Item:
	set(v):
		_set_status(v)
	get:
		return get_status()

# @brief Идентификатор продукта, который был присвоен продукту в консоли RuStore.
var productId: RuStorePayProductId = null

# @brief Дата окончания срока действия подписки.
var expirationDate: RuStorePayTime = null

# @brief Флаг, указывающий, активен ли льготный период для подписки.
var gracePeriodEnabled: bool = false

# @brief Токен для серверной валидации покупки подписки.
var subscriptionToken: RuStorePaySubscriptionToken = null
