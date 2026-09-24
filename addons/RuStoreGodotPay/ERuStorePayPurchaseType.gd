# ERuStorePayPurchaseType
# @brief Тип покупки.
class_name ERuStorePayPurchaseType

# @brief Доступные значения.
enum Item {
	# @brief Значение по умолчанию.
	UNKNOWN,
	
	# @brief Одностадийная оплата.
	ONE_STEP,
	
	# @brief Двухстадийная оплата.
	TWO_STEP,
	
	# @brief Значение не определено.
	UNDEFINED
}
