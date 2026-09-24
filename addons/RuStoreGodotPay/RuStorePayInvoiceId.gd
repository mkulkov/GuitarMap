# RuStorePayInvoiceId
# @brief
#	Идентификатор счета.
#	Используется дл¤ серверной валидации платежа, поиска платежей в консоли разработчика,
#	а также отображается покупателю в истории платежей в мобильном приложении RuStore.
class_name RuStorePayInvoiceId extends RuStorePayBaseValue

func _init(val: String):
	super(val)
