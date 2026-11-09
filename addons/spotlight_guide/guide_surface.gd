class_name SpotlightGuide_Surface
extends Control

var focus_rect := Rect2()
var has_focus := false
var focus_padding := 10.0
var dim_color := Color(0.015, 0.02, 0.035, 0.82)
var accent_color := Color("#78f0b0")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_focus(rect: Rect2, padding: float) -> void:
	focus_rect = rect
	focus_padding = padding
	has_focus = true
	queue_redraw()


func clear_focus() -> void:
	has_focus = false
	queue_redraw()


func _draw() -> void:
	var full_rect := Rect2(Vector2.ZERO, size)
	if not has_focus:
		draw_rect(full_rect, dim_color, true)
		return

	var focus := focus_rect.grow(focus_padding).intersection(full_rect)
	var top_height := maxf(0.0, focus.position.y)
	var bottom_y := minf(size.y, focus.end.y)
	var left_width := maxf(0.0, focus.position.x)
	var right_x := minf(size.x, focus.end.x)

	draw_rect(Rect2(0.0, 0.0, size.x, top_height), dim_color, true)
	draw_rect(
		Rect2(0.0, bottom_y, size.x, maxf(0.0, size.y - bottom_y)),
		dim_color,
		true
	)
	draw_rect(
		Rect2(0.0, focus.position.y, left_width, focus.size.y),
		dim_color,
		true
	)
	draw_rect(
		Rect2(right_x, focus.position.y, maxf(0.0, size.x - right_x), focus.size.y),
		dim_color,
		true
	)

	draw_rect(focus, accent_color, false, 3.0, true)
	draw_rect(focus.grow(4.0), Color(accent_color, 0.25), false, 1.0, true)

