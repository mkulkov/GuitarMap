# ERuStorePayUserAuthorizationStatus
# @brief Статус авторизации пользователя.
class_name ERuStorePayUserAuthorizationStatus

# @brief Доступные значения.
enum Item {
	# @brief Пользователь авторизован в RuStore или через VK ID на платежной шторке.
	AUTHORIZED,
	
	# @brief
	#	Пользователь неавторизован в RuStore.
	# 	Данное значение также вернется если у пользователя нет установленного МП RuStore на девайсе.
	UNAUTHORIZED
}
