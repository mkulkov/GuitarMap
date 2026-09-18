class_name Interval
extends RefCounted

const CANONICAL_DEGREE_LABELS: PackedStringArray = [
	"1", "b2", "2", "b3", "3", "4", "b5", "5", "b6", "6", "b7", "7",
]

var semitones: int
var degree_label: String


func _init(semitones_value: int, degree_label_value: String = "") -> void:
	assert(semitones_value >= 0 and semitones_value <= 11, "An interval must be between 0 and 11 semitones.")
	semitones = semitones_value
	degree_label = degree_label_value if not degree_label_value.is_empty() else CANONICAL_DEGREE_LABELS[semitones]
