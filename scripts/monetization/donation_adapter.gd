class_name DonationAdapter
extends RefCounted

signal initialized(success: bool, status: String)
signal catalog_loaded(products: Array[Dictionary])
signal catalog_unavailable(status: String)
signal purchase_finished(success: bool, status: String, product_id: String, transaction_id: String)
signal purchase_recovered(product_id: String, transaction_id: String)

var platform_id := "unsupported"
var configuration: Dictionary = {}


func initialize(configuration_value: Dictionary) -> void:
	configuration = configuration_value.duplicate(true)
	initialized.emit(false, "unsupported")


func load_products() -> void:
	catalog_unavailable.emit("unsupported")


func restore_pending_purchases() -> void:
	pass


func purchase(_product_id: String) -> void:
	purchase_finished.emit(false, "unsupported", "", "")


func acknowledge(_transaction_id: String) -> void:
	pass
