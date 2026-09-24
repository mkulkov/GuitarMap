# RuStoreFeatureAvailabilityResult
# @brief Проверка доступности функционала.
class_name RuStoreFeatureAvailabilityResult extends RefCounted

# @brief
#	Информация о доступности.
#	Если все условия выполняются, возвращается isAvailable == true.
#	В противном случае возвращается isAvailable == false.
var isAvailable: bool = false

# @brief Информация об ошибке.
var cause: RuStoreError = null

func _init(json: String = ""):
	if json != "":
		var obj = JSON.parse_string(json)
		isAvailable = obj["isAvailable"]
		
		if obj.has("cause"):
			var jcause = JSON.stringify(obj["cause"])
			cause = RuStoreError.new(jcause)
