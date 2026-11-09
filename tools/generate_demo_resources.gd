extends SceneTree

const STEP_DIRECTORY := "res://example/steps"
const SEQUENCE_PATH := "res://example/spotlight_guide_sequence.tres"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var absolute_directory := ProjectSettings.globalize_path(STEP_DIRECTORY)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		push_error("Could not create demo resource directory.")
		quit(1)
		return

	var specifications := [
		{
			"file": "01_settings.tres",
			"title": "Find your settings",
			"body": (
				"Settings live in the top-left corner. Use them to switch themes, "
				+ "audio and display options without leaving the map."
			),
			"target": "SettingsButton",
			"placement": "right",
		},
		{
			"file": "02_objective.tres",
			"title": "Read the current objective",
			"body": (
				"The map panel always shows the active objective and the next "
				+ "location to explore."
			),
			"target": "MapPanel",
			"placement": "right",
		},
		{
			"file": "03_inventory.tres",
			"title": "Manage your supplies",
			"body": (
				"Inventory items can be inspected before moving. This guide pauses "
				+ "gameplay so the player cannot double-submit actions."
			),
			"target": "InventoryPanel",
			"placement": "left",
		},
		{
			"file": "04_build.tres",
			"title": "Build when you are ready",
			"body": (
				"Build costs coins. The spotlight tracks this button even after "
				+ "the window changes size."
			),
			"target": "BuildButton",
			"placement": "above",
		},
		{
			"file": "05_end_turn.tres",
			"title": "End the turn",
			"body": (
				"Completed guides are stored in a local ConfigFile. The finished "
				+ "signal is ready for a game-specific save system."
			),
			"target": "EndTurnButton",
			"placement": "above",
		},
	]

	var steps: Array[SpotlightGuide_Step] = []
	for specification: Dictionary in specifications:
		var step := SpotlightGuide_Step.new()
		step.title = String(specification["title"])
		step.body = String(specification["body"])
		step.target_path = NodePath(String(specification["target"]))
		step.placement = String(specification["placement"])
		step.focus_padding = 10.0
		var step_path := STEP_DIRECTORY.path_join(String(specification["file"]))
		var save_error := ResourceSaver.save(step, step_path)
		if save_error != OK:
			push_error("Could not save %s (error %d)." % [step_path, save_error])
			quit(1)
			return
		var saved_step := ResourceLoader.load(step_path) as SpotlightGuide_Step
		if saved_step == null:
			push_error("Could not reload %s after saving." % step_path)
			quit(1)
			return
		steps.append(saved_step)

	var sequence := SpotlightGuide_Sequence.new()
	sequence.id = &"demo_first_run"
	sequence.display_name = "First Run"
	sequence.steps = steps
	var sequence_error := ResourceSaver.save(sequence, SEQUENCE_PATH)
	if sequence_error != OK:
		push_error("Could not save demo sequence (error %d)." % sequence_error)
		quit(1)
		return

	print("DEMO_RESOURCES_GENERATED")
	quit(0)
