extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://example/demo.tscn") as PackedScene
	_check(packed_scene != null, "Demo scene must load.")
	if packed_scene == null:
		_finish()
		return

	var demo := packed_scene.instantiate()
	root.add_child(demo)
	var guide := demo.get_node_or_null("SpotlightGuideOverlay") as SpotlightGuide_Overlay
	_check(guide != null, "Demo must create a SpotlightGuide_Overlay.")
	if guide == null:
		_finish()
		return

	var web_sequence := demo.call("_create_web_sequence") as SpotlightGuide_Sequence
	_check(web_sequence != null, "Web demo sequence must be creatable.")
	if web_sequence != null:
		_check(
			web_sequence.steps.size() == 2,
			"Web demo must expose exactly two steps."
		)

	guide.reset_saved_progress()
	await process_frame
	await process_frame

	var expected_targets := [
		"SettingsButton",
		"MapPanel",
		"InventoryPanel",
		"BuildButton",
		"EndTurnButton",
	]

	_check(bool(guide.get("_active")), "Guide should start automatically.")
	for index: int in expected_targets.size():
		var target := guide.get("_current_target") as Control
		_check(target != null, "Step %d should resolve a Control target." % (index + 1))
		if target != null:
			_check(
				target.name == expected_targets[index],
				"Step %d expected target %s, got %s."
				% [index + 1, expected_targets[index], target.name]
			)

		var callout := guide.get("_callout") as Control
		var viewport_rect := root.get_visible_rect()
		_check(
			viewport_rect.encloses(Rect2(callout.position, callout.size)),
			"Step %d callout must remain inside the viewport." % (index + 1)
		)
		guide.advance()
		await process_frame

	_check(not bool(guide.get("_active")), "Guide should be inactive after the last step.")
	_check(not paused, "Game pause state must be restored after completion.")
	_check(guide.is_completed(&"demo_first_run"), "Completion state must be persisted.")

	guide.skip_if_completed = false
	guide.start()
	await process_frame
	_check(bool(guide.get("_active")), "Guide should restart for the skip test.")
	guide.skip()
	await process_frame
	_check(not bool(guide.get("_active")), "Skip should close the guide.")
	_check(not paused, "Skip must restore the original game pause state.")

	guide.reset_saved_progress()
	guide.save_progress = false
	guide.start()
	await process_frame
	_check(bool(guide.get("_active")), "Guide should start with persistence disabled.")
	for _index: int in 5:
		guide.advance()
		await process_frame
	_check(
		guide.is_completed(&"demo_first_run"),
		"Disabled persistence should still retain completion in memory."
	)

	root.size = Vector2i(1024, 768)
	await process_frame
	guide.start()
	await process_frame
	var resized_callout := guide.get("_callout") as Control
	_check(
		root.get_visible_rect().encloses(
			Rect2(resized_callout.position, resized_callout.size)
		),
		"Callout must remain inside the viewport after resizing."
	)
	guide.skip()
	root.size = Vector2i(1280, 720)
	print("SMOKE_TEST_OK")
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error("SMOKE TEST: " + message)


func _finish() -> void:
	if _failures.is_empty():
		print("ALL_CHECKS_PASSED")
		quit(0)
		return
	push_error("SMOKE TEST FAILED: %d issue(s)." % _failures.size())
	quit(1)

