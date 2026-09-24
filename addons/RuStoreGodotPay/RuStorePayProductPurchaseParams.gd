# RuStorePayProductPurchaseParams
# @brief Параметры покупки продукта.
class_name RuStorePayProductPurchaseParams extends RefCounted

# @brief Идентификатор продукта, который был присвоен продукту в консоли RuStore.
var productId: RuStorePayProductId = null

# @brief
#	Адрес электронной почты пользователя.
#	При использовании данного параметра поле email пользователя автоматически заполняется этим значением при отправке чека,
#	как для платежей вне RuStore, так и для случаев, когда пользователь не авторизован в RuStore.
var appUserEmail: RuStorePayAppUserEmail = null

# @brief
#	Внутренний ID пользователя в приложении (необязательный параметр).
#	Максимальная длина 128 символов.
var appUserId: RuStorePayAppUserId = null

# @brief
#	Строка с дополнительной информацией о заказе,
#	которую вы можете установить при инициализации процесса покупки (необязательный параметр).
var developerPayload: RuStorePayDeveloperPayload = null

# @brief
#	Уникальный идентификатор оплаты, сформированный приложением (необязательный параметр).
#	Если вы укажете этот параметр в вашей системе, вы получите его в ответе при работе с API.
#	Если не укажете, он будет сгенерирован автоматически (uuid).
#	Максимальная длина 150 символов.
var orderId: RuStorePayOrderId = null

# @brief Количество продукта (необязательный параметр).
var quantity: RuStorePayQuantity = null

func _init(
	productId: RuStorePayProductId,
	appUserEmail: RuStorePayAppUserEmail = null,
	appUserId: RuStorePayAppUserId = null,
	developerPayload: RuStorePayDeveloperPayload = null,
	orderId: RuStorePayOrderId = null,
	quantity: RuStorePayQuantity = null
):
	self.productId = productId
	self.appUserEmail = appUserEmail
	self.appUserId = appUserId
	self.developerPayload = developerPayload
	self.orderId = orderId
	self.quantity = quantity
