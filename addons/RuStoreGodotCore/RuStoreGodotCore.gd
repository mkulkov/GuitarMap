# RuStoreGodotCoreUtils
# @brief Класс реализует коллекцию вспомогательных методов для взаимодействия с приложением RuStore.
class_name RuStoreGodotCoreUtils extends Object

const SINGLETON_NAME = "RuStoreGodotCore"

var _isInitialized: bool = false
var _clientWrapper: Object = null

static var _instance: RuStoreGodotCoreUtils = null


# @brief
#	Получить экземпляр RuStoreGodotCoreUtils.
# @return
#	Возвращает указатель на единственный экземпляр RuStoreGodotCoreUtils (реализация паттерна Singleton).
#	Если экземпляр еще не создан, создает его.
static func get_instance() -> RuStoreGodotCoreUtils:
	if _instance == null:
		_instance = RuStoreGodotCoreUtils.new()
	return _instance


func _init():
	if Engine.has_singleton(SINGLETON_NAME):
		_clientWrapper = Engine.get_singleton(SINGLETON_NAME)
		_isInitialized = true


func show_toast(data: String):
	return _clientWrapper.showToast(data)


func convert_to_iso8601(data: String) -> String:
	return _clientWrapper.convertToISO8601(data)


func copy_to_clipboard(data: String):
	_clientWrapper.copyToClipboard(data)


func get_from_clipboard() -> String:
	return _clientWrapper.getFromClipboard()


func get_string_resources(name: String) -> String:
	return _clientWrapper.getStringResources(name)


func get_int_resources(name: String) -> int:
	return _clientWrapper.getIntResources(name)


func get_string_shared_preferences(storageName: String, key: String, defaultValue: String) -> String:
	return _clientWrapper.getStringSharedPreferences(storageName, key, defaultValue)


func get_int_shared_preferences(storageName: String, key: String, defaultValue: int) -> int:
	return _clientWrapper.getIntSharedPreferences(storageName, key, defaultValue)


func set_string_shared_preferences(storageName: String, key: String, value: String):
	_clientWrapper.setStringSharedPreferences(storageName, key, value)


func set_int_shared_preferences(storageName: String, key: String, value: int):
	_clientWrapper.setIntSharedPreferences(storageName, key, value)


# @brief Проверка наличия приложения RuStore на устройстве пользователя.
# @return
#	Возвращает true, если RuStore установлен, в противном случае — false.
func is_rustore_installed() -> Variant:
	var json = _clientWrapper.isRuStoreInstalled()
	return JSON.parse_string(json)


# @brief Открыть веб-страницу для скачивания приложения RuStore.
func open_rustore_download_instruction():
	_clientWrapper.openRuStoreDownloadInstruction()


# @brief Запуск приложения RuStore.
func open_rustore():
	_clientWrapper.openRuStore()


# @brief
#	Запуск приложения RuStore для авторизации.
#	После успешной авторизации пользователя приложение RuStore автоматически закроется.
func open_rustore_authorization():
	_clientWrapper.openRuStoreAuthorization()
