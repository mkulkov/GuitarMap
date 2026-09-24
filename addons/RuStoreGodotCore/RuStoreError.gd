# RuStoreError
# @brief Информация об ошибке.
class_name RuStoreError extends RefCounted

# @brief
#	Название ошибки.
#	Содержит имя simpleName класса ошибки.
var name: String = ""

# @brief Сообщение ошибки.
var description: String = ""

func _init(json: String = ""):
	if json != "":
		var obj = JSON.parse_string(json)
		
		if obj.has("simpleName"):
			name = obj["simpleName"]
		
		if obj.has("detailMessage"):
			description = obj["detailMessage"]
