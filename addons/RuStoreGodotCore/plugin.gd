@tool
extends EditorPlugin

var export_plugin : AndroidExportPlugin

func _enter_tree():
    export_plugin = AndroidExportPlugin.new()
    add_export_plugin(export_plugin)

func _exit_tree():
    remove_export_plugin(export_plugin)
    export_plugin = null

class AndroidExportPlugin extends EditorExportPlugin:
    var _plugin_name = "RuStoreGodotCore"

    func _supports_platform(platform):
        if platform is EditorExportPlatformAndroid:
            return true
        return false

    func _get_android_libraries(platform, debug):
        return PackedStringArray(["res://addons/RuStoreGodotCore/RuStoreGodotCore.aar"])

    func _get_android_dependencies(platform, debug):
        return PackedStringArray(["com.google.code.gson:gson:2.10.1"])

    func _get_android_dependencies_maven_repos(platform, debug):
        return PackedStringArray(["https://nexus-external.vkteam.ru/repository/maven-rustore-exposed"])

    func _get_name():
        return _plugin_name
