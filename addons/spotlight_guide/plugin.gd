@tool
extends EditorPlugin

const OWNED_AUTOLOADS := [
	"SpotlightGuide_Runtime",
]

const OWNED_INPUT_ACTIONS := [
	"SpotlightGuide_Next",
	"SpotlightGuide_Skip",
	"SpotlightGuide_Close",
]


func _enter_tree() -> void:
	_check_project_conflicts()


func _check_project_conflicts() -> void:
	for autoload_name: String in OWNED_AUTOLOADS:
		var setting_name := "autoload/" + autoload_name
		if ProjectSettings.has_setting(setting_name):
			push_warning(
				"Spotlight Guide: autoload '%s' already exists. "
				% autoload_name
				+ "Rename the existing autoload or the plugin's autoload before enabling the plugin."
			)

	for action_name: String in OWNED_INPUT_ACTIONS:
		if InputMap.has_action(action_name):
			push_warning(
				"Spotlight Guide: InputMap action '%s' already exists. "
				% action_name
				+ "The plugin will not overwrite it. Rename one of the actions if they are unrelated."
			)

