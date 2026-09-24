class_name UnsupportedDonationAdapter
extends DonationAdapter


func _init() -> void:
	platform_id = "unsupported"


func initialize(configuration_value: Dictionary) -> void:
	configuration = configuration_value.duplicate(true)
	call_deferred("_finish_initialize")


func _finish_initialize() -> void:
	initialized.emit(false, "platform_unsupported")
