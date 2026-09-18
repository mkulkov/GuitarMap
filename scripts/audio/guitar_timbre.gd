class_name GuitarTimbre
extends RefCounted

const ACOUSTIC: StringName = &"acoustic"
const ELECTRIC: StringName = &"electric"
const DEFAULT: StringName = ACOUSTIC


static func is_valid(timbre: StringName) -> bool:
	return timbre == ACOUSTIC or timbre == ELECTRIC


static func all() -> Array[StringName]:
	return [ACOUSTIC, ELECTRIC]
