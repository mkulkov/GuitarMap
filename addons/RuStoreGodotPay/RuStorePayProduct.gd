# RuStorePayProduct
# @brief Информация о продукте.
class_name RuStorePayProduct extends RefCounted

# @brief Отформатированная цена покупки, включая валютный знак.
var amountLabel: RuStorePayAmountLabel = null

# @brief Код валюты ISO 4217.
var currency: RuStorePayCurrency = null

# @brief Описание на языке language (необязательный параметр).
var description: RuStorePayDescription = null

# @brief Ссылка на картинку.
var imageUrl: RuStorePayUrl = null

# @brief Цена в минимальных единицах (например в копейках) (необязательный параметр).
var price: RuStorePayPrice = null

# @brief Идентификатор продукта, который был присвоен продукту в консоли RuStore.
var productId: RuStorePayProductId = null

var promoImageUrl: RuStorePayUrl = null

# @brief Информация о подписке.
var subscriptionInfo: RuStorePaySubscriptionInfo = null

# @brief Название продукта на языке language.
var title: RuStorePayTitle = null

# @brief Тип продукта.
var type: ERuStorePayProductType.Item = 0
