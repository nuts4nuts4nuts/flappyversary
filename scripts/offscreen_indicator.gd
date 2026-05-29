extends Node2D

@onready var arrow: Polygon2D = $Arrow

@export var min_scale: float = 0.7
@export var max_scale: float = 1.1
@export var calm_color: Color = Color(1.0, 0.95, 0.2, 0.95)
@export var danger_color: Color = Color(0.95, 0.1, 0.1, 1.0)

func update_indicator(edge_position: Vector2, angle: float, urgency: float):
	global_position = edge_position
	rotation = angle

	var clamped = clampf(urgency, 0.0, 1.0)
	arrow.color = calm_color.lerp(danger_color, clamped)
	var s = lerpf(min_scale, max_scale, clamped)
	scale = Vector2.ONE * s
