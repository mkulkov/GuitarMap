# RuStorePayProductPurchaseResult
# @brief Результат успешного завершения покупки цифрового товара.
class_name RuStorePayProductPurchaseResult extends RefCounted

# @brief Идентификатор счёта.
var invoiceId: RuStorePayInvoiceId = null
	
# @brief
#	Уникальный идентификатор оплаты, сформированный приложением (необязательный параметр).
#	Если вы укажете этот параметр в вашей системе, вы получите его в ответе при работе с API.
#	Если не укажете, он будет сгенерирован автоматически (uuid).
#	Максимальная длина 150 символов.
var orderId: RuStorePayOrderId = null

# @brief Идентификатор продукта, который был присвоен продукту в консоли RuStore.
var productId: RuStorePayProductId = null

# @brief Тип продукта.
var productType: ERuStorePayProductType.Item = 0

# @brief Идентификатор покупки.
var purchaseId: RuStorePayPurchaseId = null

# @brief Тип покупки.
var purchaseType: ERuStorePayPurchaseType.Item = 0

# @brief Количество купленного продукта.
var quantity: RuStorePayQuantity = null

# @brief
#	Определяет, является ли платёж тестовым.
#	Значения могут быть true или false, где true обозначает тестовый платёж, а false – реальный.
var sandbox: bool = false
