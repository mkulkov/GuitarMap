# ERuStorePayAcknowledgementState
# @brief Состояние подтверждения покупки.
class_name ERuStorePayAcknowledgementState

# @brief Доступные значения.
enum Item {
	# @brief Покупка ожидает подтверждения разработчиком.
	PENDING,
	
	# @brief Покупка подтверждена разработчиком.
	ACKNOWLEDGED,
	
	# @brief Состояние неизвестно.
	UNKNOWN
}
