# RuStorePaySubscriptionPeriod
# @brief Интерфейс, представляющий период подписки.
class_name RuStorePaySubscriptionPeriod extends RefCounted

# @brief Период бесплатного тестового использования подписки.
class RuStorePayTrialPeriod extends RuStorePaySubscriptionPeriod:

	# @brief Длительность периода в формате ISO 8601.
	var duration: String

	# @brief Код валюты ISO 4217.
	var currency: String

	# @brief Цена в минимальных единицах валюты.
	var price: int

# @brief Период подписки с действием промо-акции.
class RuStorePayPromoPeriod extends RuStorePaySubscriptionPeriod:

	# @brief Длительность периода в формате ISO 8601.
	var duration: String

	# @brief Код валюты ISO 4217.
	var currency: String

	# @brief Цена в минимальных единицах валюты.
	var price: int

# @brief Основной период оплачиваемой подписки.
class RuStorePayMainPeriod extends RuStorePaySubscriptionPeriod:

	# @brief Длительность периода в формате ISO 8601.
	var duration: String
	
	# @brief Код валюты ISO 4217.
	var currency: String
	
	# @brief Цена в минимальных единицах валюты.
	var price: int

# @brief Грейс период.
class RuStorePayGracePeriod extends RuStorePaySubscriptionPeriod:

	# @brief Длительность периода в формате ISO 8601.
	var duration: String

# @brief Период ожидания или временной приостановки подписки.
class RuStorePayHoldPeriod extends RuStorePaySubscriptionPeriod:

	# @brief Длительность периода в формате ISO 8601.
	var duration: String
