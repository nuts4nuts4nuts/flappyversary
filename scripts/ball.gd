class_name BallGroup

extends RigidBody2D

signal merged

@export var initial_impulse: Vector2
@export var gravity_well: Node2D
@export var color: Color
@export var death_time: float = 5
@export var targetball_mass_damage_portion: float = 0.2

var is_target = false
var merge_boost = 0.2
var ball_value = 1
var base_force = 200
var current_death_time = 0.0
var targetball
var main

func _ready():
	apply_central_impulse(initial_impulse)
	main = get_parent()
	targetball = get_parent().get_node("target_ball")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	queue_redraw()
	if check_out_of_bounds():
		current_death_time += delta
		if current_death_time > death_time:
			if(main.mass_damage):
				if((targetball.mass - targetball.initial_mass * targetball_mass_damage_portion) <= targetball.minimum_mass):
					targetball.mass = targetball.minimum_mass
				else:
					targetball.mass -= targetball.initial_mass * targetball_mass_damage_portion
				print("targetball mass: " + str(targetball.mass))
			queue_free()
	elif current_death_time > 0:
		current_death_time = max(0, current_death_time - delta)


#func _draw():
#	var p = avg_global_position() - global_position
#	draw_circle(p, 15.0, Color.DARK_GREEN)


# true if ALL are out of bounds
func check_out_of_bounds():
	for child in find_children("", "BallCollider", false, false):
		var child_node = child as CollisionShape2D
		var circle = child_node.shape as CircleShape2D
		var pos = child_node.global_position
		var radius = circle.radius
		var vp_width = get_viewport_rect().size.x
		var vp_height = get_viewport_rect().size.y

		var x_min = pos.x - radius
		var x_max = pos.x + radius
		var y_min = pos.y - radius
		var y_max = pos.y + radius
		if x_min > 0.0 and x_max < vp_width and y_min > 0.0 and y_max < vp_height:
			return false
	return true


func _physics_process(_delta):
	if(gravity_well != null):
		gravity_well.get_sucked(self, false)


func _on_body_entered(body):
	if !body.is_target and name < body.name:
		call_deferred("steal_children", body)


func steal_children(other):
	ball_value += other.ball_value
	var children = other.get_children()
	for child in children:
		child.reparent(self)
	other.queue_free()
	merged.emit()


func avg_global_position():
	var pos = Vector2()
	var children = find_children("", "BallCollider", false, false)
	for child in children:
		pos += child.global_position
	return pos / children.size()


func nearest_global_position(point: Vector2):
	var distance: float = INF
	var nearest_so_far: Vector2
	var children = find_children("", "BallCollider", false, false)
	for child in children:
		var child_to_point_distance = (point - child.global_position).length()
		if child_to_point_distance < distance:
			distance = child_to_point_distance
			nearest_so_far = child.global_position
	return nearest_so_far
