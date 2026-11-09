extends Control

const FULL_SEQUENCE := preload("res://example/spotlight_guide_sequence.tres")

const ACCENT := Color("#78f0b0")
const PANEL_COLOR := Color("#111c33")
const PANEL_BORDER := Color("#29405f")
const MUTED := Color("#8fa3bf")

var guide: SpotlightGuide_Overlay
var replay_button: Button


func _ready() -> void:
	_build_game_ui()
	if OS.has_feature("web"):
		_build_web_demo_notice()
	_build_guide()
	await get_tree().process_frame
	guide.start()


func _build_guide() -> void:
	guide = SpotlightGuide_Overlay.new()
	guide.name = "SpotlightGuideOverlay"
	guide.sequence = FULL_SEQUENCE
	guide.target_root_path = NodePath("..")
	guide.save_progress = not OS.has_feature("web")
	guide.skip_if_completed = false
	if OS.has_feature("web"):
		guide.sequence = _create_web_sequence()
	guide.guide_finished.connect(_on_guide_finished)
	add_child(guide)


func _create_web_sequence() -> SpotlightGuide_Sequence:
	var web_sequence := FULL_SEQUENCE.duplicate(true) as SpotlightGuide_Sequence
	var public_steps: Array[SpotlightGuide_Step] = []
	for index: int in mini(2, web_sequence.steps.size()):
		public_steps.append(web_sequence.steps[index])
	web_sequence.steps = public_steps
	return web_sequence


func _build_web_demo_notice() -> void:
	var notice := PanelContainer.new()
	notice.position = Vector2(432.0, 24.0)
	notice.size = Vector2(416.0, 38.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#132b2a")
	style.border_color = Color("#2f6e5b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	notice.add_theme_stylebox_override("panel", style)
	add_child(notice)

	var label := _make_label(
		"WEB DEMO  •  Progress is not saved in the browser",
		13,
		Color("#9be8c4")
	)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice.add_child(label)


func _build_game_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color("#07101f")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_full_rect(background)
	add_child(background)

	var glow := ColorRect.new()
	glow.color = Color(0.08, 0.45, 0.34, 0.14)
	glow.position = Vector2(390.0, 70.0)
	glow.size = Vector2(760.0, 540.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var title := _make_label("LANTERN DISTRICT", 30, Color("#f8fafc"))
	title.position = Vector2(56.0, 96.0)
	title.size = Vector2(420.0, 42.0)
	add_child(title)

	var subtitle := _make_label("Turn 04  •  The night market is open", 16, MUTED)
	subtitle.position = Vector2(58.0, 138.0)
	subtitle.size = Vector2(450.0, 28.0)
	add_child(subtitle)

	_add_top_stat("COINS", "1,280", Vector2(930.0, 40.0), Color("#f3c969"))
	_add_top_stat("ENERGY", "7 / 9", Vector2(1064.0, 40.0), ACCENT)

	var settings := _make_button("Settings", Vector2(56.0, 38.0), Vector2(126.0, 42.0))
	settings.name = "SettingsButton"
	add_child(settings)

	var map_panel := _make_panel(
		"MapPanel",
		Vector2(278.0, 186.0),
		Vector2(610.0, 360.0),
		PANEL_COLOR,
		PANEL_BORDER
	)
	add_child(map_panel)
	_build_map_content(map_panel)

	var inventory_panel := _make_panel(
		"InventoryPanel",
		Vector2(922.0, 140.0),
		Vector2(300.0, 356.0),
		PANEL_COLOR,
		PANEL_BORDER
	)
	add_child(inventory_panel)
	_build_inventory_content(inventory_panel)

	var build_button := _make_button(
		"Build  •  240",
		Vector2(938.0, 520.0),
		Vector2(268.0, 52.0)
	)
	build_button.name = "BuildButton"
	build_button.add_theme_stylebox_override("normal", _make_button_style(Color("#1d5c4f")))
	build_button.add_theme_stylebox_override("hover", _make_button_style(Color("#287965")))
	add_child(build_button)

	var end_turn := _make_button(
		"End Turn",
		Vector2(1044.0, 622.0),
		Vector2(178.0, 48.0)
	)
	end_turn.name = "EndTurnButton"
	end_turn.add_theme_stylebox_override("normal", _make_button_style(Color("#78f0b0")))
	end_turn.add_theme_color_override("font_color", Color("#07101f"))
	end_turn.add_theme_stylebox_override("hover", _make_button_style(Color("#a4ffd0")))
	add_child(end_turn)

	replay_button = _make_button(
		"Replay Guide",
		Vector2(56.0, 622.0),
		Vector2(170.0, 48.0)
	)
	replay_button.pressed.connect(_on_replay_pressed)
	add_child(replay_button)


func _build_map_content(panel: PanelContainer) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)
	var title := _make_label("ACTIVE QUEST", 14, ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_make_label("NIGHT MARKET", 13, MUTED))

	content.add_child(
		_make_label("Find the missing courier before sunrise.", 22, Color("#f8fafc"))
	)

	var map_background := Panel.new()
	map_background.custom_minimum_size = Vector2(0.0, 206.0)
	map_background.add_theme_stylebox_override("panel", _make_button_style(Color("#0b1628")))
	content.add_child(map_background)

	_add_map_point(map_background, Vector2(144.0, 116.0), "A", ACCENT)
	_add_map_point(map_background, Vector2(326.0, 82.0), "B", Color("#f3c969"))
	_add_map_point(map_background, Vector2(474.0, 148.0), "C", Color("#7aa8ff"))

	var progress := ProgressBar.new()
	progress.value = 62
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0.0, 8.0)
	content.add_child(progress)
	content.add_child(_make_label("Objective progress  •  62%", 13, MUTED))


func _build_inventory_content(panel: PanelContainer) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	content.add_child(_make_label("INVENTORY", 14, ACCENT))
	_add_inventory_row(content, "Signal Lantern", "3")
	_add_inventory_row(content, "Map Fragment", "1")
	_add_inventory_row(content, "Coin Pouch", "12")

	var hint := _make_label(
		"Tip: Supplies can be inspected before moving.",
		13,
		MUTED
	)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(240.0, 60.0)
	content.add_child(hint)


func _add_inventory_row(parent: VBoxContainer, item_name: String, count: String) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 54.0)
	panel.add_theme_stylebox_override("panel", _make_button_style(Color("#0b1628")))
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var dot := ColorRect.new()
	dot.color = ACCENT
	dot.custom_minimum_size = Vector2(8.0, 8.0)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)
	var label := _make_label(item_name, 15, Color("#e2e8f0"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(_make_label(count, 14, MUTED))


func _add_map_point(parent: Control, point: Vector2, label_text: String, color: Color) -> void:
	var node := Panel.new()
	node.position = point
	node.size = Vector2(34.0, 34.0)
	node.add_theme_stylebox_override("panel", _make_button_style(color))
	parent.add_child(node)
	var label := _make_label(label_text, 15, Color("#07101f"))
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_child(label)


func _add_top_stat(title_text: String, value_text: String, pos: Vector2, color: Color) -> void:
	var panel := _make_panel(
		"",
		pos,
		Vector2(118.0, 74.0),
		PANEL_COLOR,
		PANEL_BORDER
	)
	add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(content)
	content.add_child(_make_label(title_text, 11, MUTED))
	content.add_child(_make_label(value_text, 20, color))


func _make_panel(
	node_name: String,
	pos: Vector2,
	rect_size: Vector2,
	fill_color: Color,
	border_color: Color
) -> PanelContainer:
	var panel := PanelContainer.new()
	if not node_name.is_empty():
		panel.name = node_name
	panel.position = pos
	panel.size = rect_size
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_button(
	label_text: String,
	pos: Vector2,
	rect_size: Vector2
) -> Button:
	var button := Button.new()
	button.text = label_text
	button.position = pos
	button.size = rect_size
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override("normal", _make_button_style(Color("#172640")))
	button.add_theme_stylebox_override("hover", _make_button_style(Color("#203657")))
	button.add_theme_color_override("font_color", Color("#e2e8f0"))
	return button


func _make_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(9)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func set_full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _on_guide_finished(_sequence_id: StringName) -> void:
	replay_button.disabled = false


func _on_replay_pressed() -> void:
	guide.reset_saved_progress()
	guide.start()

