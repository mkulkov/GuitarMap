# ERuStorePaySubscriptionPurchaseStatus
# @brief Статус покупки.
class_name ERuStorePaySubscriptionPurchaseStatus

# @brief Доступные значения.
enum Item {
	# @brief Создан счет на оплату, покупка ожидает оплаты.
	INVOICE_CREATED,
	
	# @brief Покупка отменена покупателем.
	CANCELLED,
	
	# @brief Истекло время на оплату покупки.
	EXPIRED,
	
	# @brief Запущена оплата.
	PROCESSING,
	
	# @brief Покупка отклонена (например, ввиду недостатка средств).
	REJECTED,
	
	# @brief Подписка активна.
	ACTIVE,
	
	# @brief Подписка приостановлена из-за проблем с оплатой.
	PAUSED,
	
	# @brief
	#	Закончились попытки списания по подписке (все были неуспешными).
	#	Подписка закрыта автоматически из-за проблем с оплатой.
	TERMINATED,
	
	# @brief
	#	Подписка была отменена пользователем или разработчиком.
	#	Истек срок оплаченного периода, подписка закрыта.
	CLOSED
}
