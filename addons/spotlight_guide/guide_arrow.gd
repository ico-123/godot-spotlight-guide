class_name SpotlightGuide_Arrow
extends Control

var start_point := Vector2.ZERO
var end_point := Vector2.ZERO
var arrow_color := Color("#78f0b0")
var show_arrow := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_arrow(from: Vector2, to: Vector2, color: Color) -> void:
	start_point = from
	end_point = to
	arrow_color = color
	show_arrow = true
	queue_redraw()


func hide_arrow() -> void:
	show_arrow = false
	queue_redraw()


func _draw() -> void:
	if not show_arrow:
		return

	var direction := (end_point - start_point).normalized()
	if direction == Vector2.ZERO:
		return

	var perpendicular := Vector2(-direction.y, direction.x)
	var arrow_base := end_point - direction * 15.0
	draw_line(start_point, arrow_base, arrow_color, 3.0, true)
	draw_colored_polygon(
		PackedVector2Array([
			end_point,
			arrow_base + perpendicular * 8.0,
			arrow_base - perpendicular * 8.0,
		]),
		arrow_color
	)

