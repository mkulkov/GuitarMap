class_name RuStorePayJsonParser

static func ToPurchaseAvailabilityResult(json: String = "") -> RuStorePayGetPurchaseAvailabilityResult:
	var result: RuStorePayGetPurchaseAvailabilityResult = null
	if json != "":
		var obj = JSON.parse_string(json)
		result = RuStorePayGetPurchaseAvailabilityResult.new()
		result.isAvailable = obj["isAvailable"]
		
		if obj.has("cause"):
			var jcause = JSON.stringify(obj["cause"])
			result.cause = to_RuStorePaymentException_classes(jcause)
	
	return result

static func ToPayProduct(json: String = "") -> RuStorePayProduct:
	var product: RuStorePayProduct = null
	if json != "":
		var obj = JSON.parse_string(json)
		product = RuStorePayProduct.new()
		
		product.amountLabel = RuStorePayAmountLabel.new(obj["amountLabel"]["value"])
		product.currency = RuStorePayCurrency.new(obj["currency"]["value"])
		if obj.has("description"):
			product.description = RuStorePayDescription.new(obj["description"]["value"])
		product.imageUrl = RuStorePayUrl.new(obj["imageUrl"]["value"])
		if obj.has("price"):
			product.price = RuStorePayPrice.new(obj["price"]["value"])
		product.productId = RuStorePayProductId.new(obj["productId"]["value"])
		if obj.has("promoImageUrl"):
			product.promoImageUrl = RuStorePayUrl.new(obj["promoImageUrl"]["value"])
		if obj.has("subscriptionInfo"):
			product.subscriptionInfo = _ToRuStorePaySubscriptionInfo(obj["subscriptionInfo"])
		product.title = RuStorePayTitle.new(obj["title"]["value"])
		product.type = ERuStorePayProductType.Item.get(obj["type"])
	
	return product

static func ToPayPurchase(json: String = ""):
	var purchase: RuStorePayPurchase = null
	if json != "":
		var obj = JSON.parse_string(json)
		if obj.has("productType"):
			return _ToPayProductPurchase(obj);
		else:
			return _ToPaySubscriptionPurchase(obj);

static func _ToPayProductPurchase(obj: Dictionary) -> RuStorePayProductPurchase:
	var purchase = RuStorePayProductPurchase.new()
	
	purchase.amountLabel = RuStorePayAmountLabel.new(obj["amountLabel"]["value"])
	purchase.currency = RuStorePayCurrency.new(obj["currency"]["value"])
	purchase.description = RuStorePayDescription.new(obj["description"]["value"])
	if obj.has("developerPayload"):
		purchase.developerPayload = RuStorePayDeveloperPayload.new(obj["developerPayload"]["value"])
	purchase.invoiceId = RuStorePayInvoiceId.new(obj["invoiceId"]["value"])
	if obj.has("orderId"):
		purchase.orderId = RuStorePayOrderId.new(obj["orderId"]["value"])
	purchase.price = RuStorePayPrice.new(obj["price"]["value"])
	purchase.productId = RuStorePayProductId.new(obj["productId"]["value"])
	purchase.productType = ERuStorePayProductType.Item.get(obj["productType"])
	purchase.purchaseId = RuStorePayPurchaseId.new(obj["purchaseId"]["value"])
	if obj.has("purchaseTime"):
		purchase.purchaseTime = RuStorePayTime.new(obj["purchaseTime"])
	purchase.purchaseType = ERuStorePayPurchaseType.Item.get(obj["purchaseType"])
	purchase.quantity = RuStorePayQuantity.new(obj["quantity"]["value"])
	purchase.status = ERuStorePayProductPurchaseStatus.Item.get(obj["status"])
	purchase.sandbox = obj["sandbox"]
	purchase.acknowledgementState = ERuStorePayAcknowledgementState.Item.get(obj["acknowledgementState"])
	
	return purchase

static func _ToPaySubscriptionPurchase(obj: Dictionary) -> RuStorePaySubscriptionPurchase:
	var purchase = RuStorePaySubscriptionPurchase.new()
	
	purchase.purchaseId = RuStorePayPurchaseId.new(obj["purchaseId"]["value"])
	purchase.invoiceId = RuStorePayInvoiceId.new(obj["invoiceId"]["value"])
	if obj.has("orderId"):
		purchase.orderId = RuStorePayOrderId.new(obj["orderId"]["value"])
	purchase.purchaseType = ERuStorePayPurchaseType.Item.get(obj["purchaseType"])
	purchase.description = RuStorePayDescription.new(obj["description"]["value"])
	if obj.has("purchaseTime"):
		purchase.purchaseTime = RuStorePayTime.new(obj["purchaseTime"])
	purchase.price = RuStorePayPrice.new(obj["price"]["value"])
	purchase.amountLabel = RuStorePayAmountLabel.new(obj["amountLabel"]["value"])
	purchase.currency = RuStorePayCurrency.new(obj["currency"]["value"])
	if obj.has("developerPayload"):
		purchase.developerPayload = RuStorePayDeveloperPayload.new(obj["developerPayload"]["value"])
	purchase.sandbox = obj["sandbox"]
	purchase.status = ERuStorePaySubscriptionPurchaseStatus.Item.get(obj["status"])
	purchase.productId = RuStorePayProductId.new(obj["productId"]["value"])
	if obj.has("expirationDate"):
		purchase.expirationDate = RuStorePayTime.new(obj["expirationDate"])
	purchase.gracePeriodEnabled = obj["gracePeriodEnabled"]
	purchase.acknowledgementState = ERuStorePayAcknowledgementState.Item.get(obj["acknowledgementState"])
	
	return purchase

static func ToPayBillingSubscription(obj: Dictionary) -> RuStorePayBillingSubscription:
	var purchase = RuStorePayBillingSubscription.new()
	
	purchase.purchaseId = RuStorePayPurchaseId.new(obj["purchaseId"]["value"])
	purchase.invoiceId = RuStorePayInvoiceId.new(obj["invoiceId"]["value"])
	if obj.has("orderId"):
		purchase.orderId = RuStorePayOrderId.new(obj["orderId"]["value"])
	purchase.purchaseType = ERuStorePayPurchaseType.Item.get(obj["purchaseType"])
	purchase.description = RuStorePayDescription.new(obj["description"]["value"])
	if obj.has("purchaseTime"):
		purchase.purchaseTime = RuStorePayTime.new(obj["purchaseTime"])
	purchase.price = RuStorePayPrice.new(obj["price"]["value"])
	purchase.amountLabel = RuStorePayAmountLabel.new(obj["amountLabel"]["value"])
	purchase.currency = RuStorePayCurrency.new(obj["currency"]["value"])
	if obj.has("developerPayload"):
		purchase.developerPayload = RuStorePayDeveloperPayload.new(obj["developerPayload"]["value"])
	purchase.sandbox = obj["sandbox"]
	purchase.status = ERuStorePaySubscriptionPurchaseStatus.Item.get(obj["status"])
	purchase.productId = RuStorePayProductId.new(obj["productId"]["value"])
	purchase.expirationDate = RuStorePayTime.new(obj["expirationDate"])
	purchase.gracePeriodEnabled = obj["gracePeriodEnabled"]
	purchase.subscriptionToken = RuStorePaySubscriptionToken.new(obj["subscriptionToken"]["value"])
	
	return purchase

static func to_ProductPurchaseResult(json: String = "") -> RuStorePayProductPurchaseResult:	
	var result: RuStorePayProductPurchaseResult = null
	if json != "":
		var obj = JSON.parse_string(json)
		result = RuStorePayProductPurchaseResult.new()
		
		result.invoiceId = RuStorePayInvoiceId.new(obj["invoiceId"]["value"])
		if obj.has("orderId"):
			result.orderId = RuStorePayOrderId.new(obj["orderId"]["value"])
		result.productId = RuStorePayProductId.new(obj["productId"]["value"])
		result.productType = ERuStorePayProductType.Item.get(obj["productType"])
		result.purchaseId = RuStorePayPurchaseId.new(obj["purchaseId"]["value"])
		result.purchaseType = ERuStorePayPurchaseType.Item.get(obj["purchaseType"])
		result.quantity = RuStorePayQuantity.new(obj["quantity"]["value"])
		result.sandbox = obj["sandbox"]
	
	return result

static func to_RuStorePaymentException_classes(json: String = "") -> RuStorePaymentException:
	if json != "":
		var obj = JSON.parse_string(json)
		var type: String = ""
		if obj.has("simpleName"):
			type = obj["simpleName"]
		
		if type == "ApplicationSchemeWasNotProvided":
			return to_ApplicationSchemeWasNotProvided(json);
		elif type == "EmptyPaymentTokenException":
			return to_EmptyPaymentTokenException(json);
		elif type == "ProductPurchaseCancelled":
			return to_ProductPurchaseCancelled(json)
		elif type == "ProductPurchaseException":
			return to_ProductPurchaseException(json)
		elif type == "RuStorePayClientAlreadyExist":
			return to_RuStorePayClientAlreadyExist(json)
		elif type == "RuStorePayClientNotCreated":
			return to_RuStorePayClientNotCreated(json)
		elif type == "RuStorePayInvalidActivePurchase":
			return to_RuStorePayInvalidActivePurchase(json)
		elif type == "RuStorePayInvalidConsoleAppId":
			return to_RuStorePayInvalidConsoleAppId(json)
		elif type == "RuStorePaySignatureException":
			return to_RuStorePaySignatureException(json)
		elif type == "RuStorePaymentCommonException":
			return to_RuStorePaymentCommonException(json)
		elif type == "RuStorePaymentNetworkException":
			return to_RuStorePaymentNetworkException(json)
		elif type == "InvalidCardBindingIdException":
			return to_InvalidCardBindingIdException(json)
		else:
			return to_RustorePaymentException(json)
	else:
		return null

static func try_parse_exception(json: String, instance: RuStorePaymentException) -> bool:
	if json != "":
		var obj = JSON.parse_string(json)
		
		if obj.has("simpleName"):
			instance.name = obj["simpleName"]
		if obj.has("detailMessage"):
			instance.description = obj["detailMessage"]
		if obj.has("cause"):
			var jcause = JSON.stringify(obj["cause"])
			instance.cause = RuStoreError.new(jcause)
			
		return true
	else:
		return false

static func to_RustorePaymentException(json: String = "") -> RuStorePaymentException:
	var result = RuStorePaymentException.new()
	if try_parse_exception(json, result):
		return result
	else:
		return null

static func to_ApplicationSchemeWasNotProvided(json: String = "") -> RuStorePaymentException.ApplicationSchemeWasNotProvided:
	var result = RuStorePaymentException.ApplicationSchemeWasNotProvided.new()
	if try_parse_exception(json, result):
		return result
	else:
		return null

static func to_EmptyPaymentTokenException(json: String = "") -> RuStorePaymentException.EmptyPaymentTokenException:
	var result = RuStorePaymentException.EmptyPaymentTokenException.new()
	if try_parse_exception(json, result):
		return result
	else:
		return null

static func to_ProductPurchaseCancelled(json: String = "") -> RuStorePaymentException.ProductPurchaseCancelled:
	var result = RuStorePaymentException.ProductPurchaseCancelled.new()
	if try_parse_exception(json, result):
		var obj = JSON.parse_string(json)
		if obj.has("productType"):
			result.productType = ERuStorePayProductType.Item.get(obj["productType"])
		if obj.has("purchaseId"):
			result.purchaseId = RuStorePayPurchaseId.new(obj["purchaseId"]["value"])
		if obj.has("purchaseType"):
			result.purchaseType = ERuStorePayPurchaseType.Item.get(obj["purchaseType"])
		
		return result
	else:
		return null

static func to_ProductPurchaseException(json: String = "") -> RuStorePaymentException.ProductPurchaseException:
	var result = RuStorePaymentException.ProductPurchaseException.new()
	if try_parse_exception(json, result):
		var obj = JSON.parse_string(json)
		if obj.has("invoiceId"):
			result.invoiceId = RuStorePayInvoiceId.new(obj["invoiceId"]["value"])
		if obj.has("orderId"):
			result.orderId = RuStorePayOrderId.new(obj["orderId"]["value"])
		if obj.has("productId"):
			result.productId = RuStorePayProductId.new(obj["productId"]["value"])
		if obj.has("purchaseId"):
			result.purchaseId = RuStorePayPurchaseId.new(obj["purchaseId"]["value"])
		if obj.has("productType"):
			result.productType = ERuStorePayProductType.Item.get(obj["productType"])
		if obj.has("quantity"):
			result.quantity = RuStorePayQuantity.new(obj["quantity"]["value"])
		if obj.has("purchaseType"):
			result.purchaseType = ERuStorePayPurchaseType.Item.get(obj["purchaseType"])
		if obj.has("sandbox"):
			result.sandbox = obj["sandbox"]
		
		return result
	else:
		return null

static func to_RuStorePayClientAlreadyExist(json: String = "") -> RuStorePaymentException.RuStorePayClientAlreadyExist:
	var result = RuStorePaymentException.RuStorePayClientAlreadyExist.new()
	if try_parse_exception(json, result):
		return result
	else:
		return null

static func to_RuStorePayClientNotCreated(json: String = "") -> RuStorePaymentException.RuStorePayClientNotCreated:
	var result = RuStorePaymentException.RuStorePayClientNotCreated.new()
	if try_parse_exception(json, result):
		return result
	else:
		return null

static func to_RuStorePayInvalidActivePurchase(json: String = "") -> RuStorePaymentException.RuStorePayInvalidActivePurchase:
	var result = RuStorePaymentException.RuStorePayInvalidActivePurchase.new()
	if try_parse_exception(json, result):
		return result
	else:
		return null

static func to_RuStorePayInvalidConsoleAppId(json: String = "") -> RuStorePaymentException.RuStorePayInvalidConsoleAppId:
	var result = RuStorePaymentException.RuStorePayInvalidConsoleAppId.new()
	if try_parse_exception(json, result):
		return result
	else:
		return null

static func to_RuStorePaySignatureException(json: String = "") -> RuStorePaymentException.RuStorePaySignatureException:
	var result = RuStorePaymentException.RuStorePaySignatureException.new()
	if try_parse_exception(json, result):
		return result
	else:
		return null

static func to_RuStorePaymentCommonException(json: String = "") -> RuStorePaymentException.RuStorePaymentCommonException:
	var result = RuStorePaymentException.RuStorePaymentCommonException.new()
	if try_parse_exception(json, result):
		return result
	else:
		return null

static func to_RuStorePaymentNetworkException(json: String = "") -> RuStorePaymentException.RuStorePaymentNetworkException:
	var result = RuStorePaymentException.RuStorePaymentNetworkException.new()
	if try_parse_exception(json, result):
		var obj = JSON.parse_string(json)
		result.code = obj["code"]
		result.id = obj["id"]
		
		return result
	else:
		return null

static func to_InvalidCardBindingIdException(json: String = "") -> RuStorePaymentException.RuStoreInvalidCardBindingIdException:
	var result = RuStorePaymentException.RuStoreInvalidCardBindingIdException.new()
	if try_parse_exception(json, result):
		return result
	else:
		return null

static func _ToRuStorePaySubscriptionInfo(obj: Variant) -> RuStorePaySubscriptionInfo:
	if obj == null:
		return null
	
	var result = RuStorePaySubscriptionInfo.new()
	for period_data in obj["periods"]:
		var period = _ToRuStorePaySubscriptionPeriod(period_data)
		if period != null:
			result.periods.append(period)
	
	return result

static func _ToRuStorePaySubscriptionPeriod(obj: Variant) -> RuStorePaySubscriptionPeriod:
	if obj == null:
		return null
	
	var subscription = null
	var simple_name = obj["simpleName"]
	match simple_name:
		"TrialPeriod":
			subscription = RuStorePaySubscriptionPeriod.RuStorePayTrialPeriod.new()
		"PromoPeriod":
			subscription = RuStorePaySubscriptionPeriod.RuStorePayPromoPeriod.new()
		"MainPeriod":
			subscription = RuStorePaySubscriptionPeriod.RuStorePayMainPeriod.new()
		"GracePeriod":
			subscription = RuStorePaySubscriptionPeriod.RuStorePayGracePeriod.new()
		"HoldPeriod":
			subscription = RuStorePaySubscriptionPeriod.RuStorePayHoldPeriod.new()
	
	subscription.duration = obj["duration"]
	if obj.has("currency"):
		subscription.currency = obj["currency"]
	if obj.has("price"):
		subscription.price = obj["price"]
	
	return subscription

static func to_purchase_event_payload(json: String = "") -> Dictionary:
	if json == "":
		print("PurchaseEvent payload is empty")
		return {}
	
	var obj = JSON.parse_string(json)
	var productId  = _value_from(obj, "productId",  RuStorePayProductId)
	var purchaseId = _value_from(obj, "purchaseId", RuStorePayPurchaseId)
	var invoiceId  = _value_from(obj, "invoiceId",  RuStorePayInvoiceId)

	return {
		"productId":  productId,
		"purchaseId": purchaseId,
		"invoiceId":  invoiceId,
	}

static func _value_from(obj: Dictionary, key: String, ctor) -> Variant:
	var dict = obj.get(key, null)
	if dict == null:
		return null
	
	var value = dict.get("value", null) if typeof(dict) == TYPE_DICTIONARY else null

	return ctor.new(value) if value != null else null
