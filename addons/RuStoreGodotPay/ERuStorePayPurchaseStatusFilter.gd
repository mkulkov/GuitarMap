# ERuStorePayPurchaseStatusFilter
# @brief Статус покупки.
class_name ERuStorePayPurchaseStatusFilter

# @brief Доступные значения.
enum Item {
	# @brief
	#	Только для двухстадийной оплаты,
	#	промежуточный статус,
	#	средства на счёте покупателя захолдированы,
	#	покупка ожидает подтверждения от разработчика.
	PAID,
	
	# @brief Покупка успешно оплачена.
	CONFIRMED,
	
	# @brief Подписка активна.
	ACTIVE,
	
	# @brief Подписка приостановлена из-за проблем с оплатой.
	PAUSED
}
