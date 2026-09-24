# ERuStorePayProductType
# @brief Тип продукта.
class_name ERuStorePayProductType

# @brief Доступные значения.
enum Item {
	# @brief Значение по умолчанию.
	UNKNOWN,
	
	# @brief
	#	Непотребляемй товар.
	#	Можно купить один раз.
	NON_CONSUMABLE_PRODUCT,
	
	# @brief
	#	Потребляемый товар.
	#	Можно купить много раз.
	CONSUMABLE_PRODUCT,
	
	# @brief Подписка.
	SUBSCRIPTION
}
