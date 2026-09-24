class_name RuStorePayBaseValue extends RefCounted

var value

func _init(val):
	value = val

func equals(other) -> bool:
	if other is RuStorePayBaseValue:
		return value == other.value
	return false

func get_hash_code() -> int:
	return hash(value)

func get_string() -> String:
	return get_class() + "(value='" + str(value) + "')"
