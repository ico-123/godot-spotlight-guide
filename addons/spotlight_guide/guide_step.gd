@tool
class_name SpotlightGuide_Step
extends Resource

@export var title: String = ""
@export_multiline var body: String = ""
@export_node_path("Control") var target_path: NodePath
@export_enum("auto", "right", "left", "above", "below") var placement: String = "auto"
@export_range(0.0, 64.0, 1.0) var focus_padding: float = 10.0
@export var pause_game: bool = true
@export var allow_skip: bool = true

