class_name SpotlightGuide_Overlay
extends CanvasLayer

signal step_changed(index: int, total: int)
signal step_completed(index: int, sequence_id: StringName)
signal guide_finished(sequence_id: StringName)
signal guide_skipped(sequence_id: StringName)

const SAVE_PATH := "user://spotlight_guide_progress.cfg"
const CALLOUT_WIDTH := 370.0
const SCREEN_MARGIN := 24.0
const TARGET_GAP := 42.0

@export var sequence: SpotlightGuide_Sequence
@export_node_path("Node") var target_root_path: NodePath
@export var autoplay := false
@export var save_progress := true
@export var skip_if_completed := true
@export var dim_color := Color(0.015, 0.02, 0.035, 0.82)
@export var accent_color := Color("#78f0b0")

var _surface: SpotlightGuide_Surface
var _arrow: SpotlightGuide_Arrow
var _callout: PanelContainer
var _progress_label: Label
var _title_label: Label
var _body_label: Label
var _skip_button: Button
var _next_button: Button

var _current_index := -1
var _current_target: Control
var _active := false
var _saved_game_paused := false
var _memory_completed: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	if autoplay:
		start.call_deferred()


func _process(_delta: float) -> void:
	if not _active or not is_instance_valid(_current_target):
		return
	_refresh_layout(_current_target.get_global_rect())


func start(sequence_override: SpotlightGuide_Sequence = null) -> bool:
	if sequence_override != null:
		sequence = sequence_override
	if sequence == null or sequence.steps.is_empty():
		push_warning("Spotlight Guide: cannot start without a sequence containing at least one step.")
		return false
	if _active:
		return false
	if skip_if_completed and _is_completed(String(sequence.id)):
		return false

	_active = true
	_saved_game_paused = get_tree().paused
	_current_index = 0
	_set_overlay_visible(true)
	_show_step(_current_index)
	return true


func advance() -> void:
	if not _active:
		return
	if sequence == null or sequence.steps.is_empty():
		_finish()
		return

	step_completed.emit(_current_index, sequence.id)
	_current_index += 1
	if _current_index >= sequence.steps.size():
		_finish()
	else:
		_show_step(_current_index)


func skip() -> void:
	if not _active:
		return
	var skipped_id := sequence.id if sequence != null else &""
	_active = false
	_restore_pause()
	_set_overlay_visible(false)
	guide_skipped.emit(skipped_id)


func reset_saved_progress() -> void:
	_memory_completed.clear()
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	if config.has_section("completed"):
		config.erase_section("completed")
		config.save(SAVE_PATH)


func is_completed(sequence_id: StringName) -> bool:
	return _is_completed(String(sequence_id))


func _show_step(index: int) -> void:
	var step: SpotlightGuide_Step = sequence.steps[index]
	_current_target = _resolve_target(step)
	_progress_label.text = "%d / %d" % [index + 1, sequence.steps.size()]
	_title_label.text = step.title
	_body_label.text = step.body
	_skip_button.visible = step.allow_skip
	_next_button.text = "Finish" if index == sequence.steps.size() - 1 else "Next"

	if step.pause_game:
		get_tree().paused = true
	else:
		get_tree().paused = _saved_game_paused

	if _current_target == null:
		push_warning(
			"Spotlight Guide: target '%s' was not found or is not a Control."
			% step.target_path
		)
		_surface.clear_focus()
		_arrow.hide_arrow()
		_position_callout_centered()
	else:
		_refresh_layout(_current_target.get_global_rect())

	step_changed.emit(index, sequence.steps.size())
	_body_label.reset_size()
	_title_label.reset_size()
	_progress_label.reset_size()
	_callout.reset_size()


func _refresh_layout(target_rect: Rect2) -> void:
	var step: SpotlightGuide_Step = sequence.steps[_current_index]
	var focus_rect := target_rect.grow(step.focus_padding)
	_surface.dim_color = dim_color
	_surface.accent_color = accent_color
	_surface.set_focus(target_rect, step.focus_padding)
	_position_callout(focus_rect, step.placement)


func _position_callout(focus_rect: Rect2, placement: String) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var minimum_size := _callout.get_combined_minimum_size()
	var callout_size := Vector2(maxf(CALLOUT_WIDTH, minimum_size.x), minimum_size.y)
	_callout.size = callout_size

	var resolved_placement := _resolve_placement(focus_rect, callout_size, placement)
	var callout_position := focus_rect.get_center() - callout_size * 0.5
	match resolved_placement:
		"right":
			callout_position = Vector2(
				focus_rect.end.x + TARGET_GAP,
				focus_rect.get_center().y - callout_size.y * 0.5
			)
		"left":
			callout_position = Vector2(
				focus_rect.position.x - TARGET_GAP - callout_size.x,
				focus_rect.get_center().y - callout_size.y * 0.5
			)
		"above":
			callout_position = Vector2(
				focus_rect.get_center().x - callout_size.x * 0.5,
				focus_rect.position.y - TARGET_GAP - callout_size.y
			)
		"below":
			callout_position = Vector2(
				focus_rect.get_center().x - callout_size.x * 0.5,
				focus_rect.end.y + TARGET_GAP
			)

	callout_position.x = clampf(
		callout_position.x,
		SCREEN_MARGIN,
		maxf(SCREEN_MARGIN, viewport_size.x - callout_size.x - SCREEN_MARGIN)
	)
	callout_position.y = clampf(
		callout_position.y,
		SCREEN_MARGIN,
		maxf(SCREEN_MARGIN, viewport_size.y - callout_size.y - SCREEN_MARGIN)
	)
	_callout.position = callout_position

	var callout_rect := Rect2(callout_position, callout_size)
	var start_point := _closest_point_on_rect(callout_rect, focus_rect.get_center())
	var end_point := _closest_point_on_rect(focus_rect, callout_rect.get_center())
	_arrow.set_arrow(start_point, end_point, accent_color)


func _resolve_placement(
	focus_rect: Rect2,
	callout_size: Vector2,
	preferred_placement: String
) -> String:
	if preferred_placement != "auto":
		return preferred_placement

	var viewport_size := get_viewport().get_visible_rect().size
	if focus_rect.end.x + TARGET_GAP + callout_size.x <= viewport_size.x - SCREEN_MARGIN:
		return "right"
	if focus_rect.position.x - TARGET_GAP - callout_size.x >= SCREEN_MARGIN:
		return "left"
	if focus_rect.end.y + TARGET_GAP + callout_size.y <= viewport_size.y - SCREEN_MARGIN:
		return "below"
	return "above"


func _position_callout_centered() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var minimum_size := _callout.get_combined_minimum_size()
	_callout.size = Vector2(maxf(CALLOUT_WIDTH, minimum_size.x), minimum_size.y)
	_callout.position = (viewport_size - _callout.size) * 0.5


func _closest_point_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)


func _resolve_target(step: SpotlightGuide_Step) -> Control:
	var target_root: Node = get_node_or_null(target_root_path)
	if target_root == null and is_inside_tree():
		target_root = get_tree().current_scene
	if target_root == null:
		return null

	var node := target_root.get_node_or_null(step.target_path)
	if node is Control:
		return node
	if node != null:
		push_warning(
			"Spotlight Guide: '%s' resolved to %s. The first version only supports Control targets."
			% [step.target_path, node.get_class()]
		)
	return null


func _finish() -> void:
	if sequence == null:
		return
	_mark_completed(String(sequence.id))
	var finished_id := sequence.id
	_active = false
	_restore_pause()
	_set_overlay_visible(false)
	guide_finished.emit(finished_id)


func _restore_pause() -> void:
	if is_inside_tree():
		get_tree().paused = _saved_game_paused


func _set_overlay_visible(value: bool) -> void:
	_surface.visible = value
	_arrow.visible = value
	_callout.visible = value


func _is_completed(sequence_id: String) -> bool:
	if sequence_id.is_empty():
		return false
	if _memory_completed.has(sequence_id):
		return true
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	return bool(config.get_value("completed", sequence_id, false))


func _mark_completed(sequence_id: String) -> void:
	if sequence_id.is_empty():
		return
	_memory_completed[sequence_id] = true
	if not save_progress:
		return
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("completed", sequence_id, true)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning(
			"Spotlight Guide: could not save progress (error %d). "
			% error
			+ "Completion remains available in memory for this session."
		)


func _build_ui() -> void:
	_surface = SpotlightGuide_Surface.new()
	_surface.name = "InputBlocker"
	_surface.z_index = 0
	add_child(_surface)
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_arrow = SpotlightGuide_Arrow.new()
	_arrow.name = "Arrow"
	_arrow.z_index = 1
	add_child(_arrow)
	_arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_callout = PanelContainer.new()
	_callout.name = "Callout"
	_callout.z_index = 2
	_callout.mouse_filter = Control.MOUSE_FILTER_STOP
	_callout.add_theme_stylebox_override("panel", _create_callout_style())
	add_child(_callout)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	_callout.add_child(content)

	_progress_label = Label.new()
	_progress_label.add_theme_color_override("font_color", accent_color)
	_progress_label.add_theme_font_size_override("font_size", 14)
	content.add_child(_progress_label)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color("#f8fafc"))
	content.add_child(_title_label)

	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.custom_minimum_size = Vector2(CALLOUT_WIDTH - 40.0, 0.0)
	_body_label.add_theme_font_size_override("font_size", 16)
	_body_label.add_theme_color_override("font_color", Color("#cbd5e1"))
	content.add_child(_body_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	content.add_child(button_row)

	_skip_button = Button.new()
	_skip_button.text = "Skip"
	_skip_button.custom_minimum_size = Vector2(100.0, 42.0)
	_skip_button.pressed.connect(skip)
	button_row.add_child(_skip_button)

	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.custom_minimum_size = Vector2(0.0, 42.0)
	_next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next_button.add_theme_color_override("font_color", Color("#0b1220"))
	_next_button.add_theme_stylebox_override("normal", _create_primary_button_style(accent_color))
	_next_button.add_theme_stylebox_override("hover", _create_primary_button_style(accent_color.lightened(0.12)))
	_next_button.pressed.connect(advance)
	button_row.add_child(_next_button)

	_set_overlay_visible(false)


func _create_callout_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0f172a")
	style.border_color = Color("#334155")
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 18
	return style


func _create_primary_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	return style

