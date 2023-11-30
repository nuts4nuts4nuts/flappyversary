extends RigidBody2D

signal merged
signal cashed

@export var initial_impulse: Vector2
@export var gravity_well: Node2D
@export var color_normal: Color
@export var color_cash: Color
@export var death_time: float

var color: Color

var merge_boost = 0.2
var ball_value = 2
var base_force = 50
var is_target = true
var target_progress = 1
var cashing_in = false
var merged_balls = []
var cashing_bonus = 1
var current_death_time = 0.0

func steal_children(other):
	print(name + " stealing")
	var children = other.get_children()
	for child in children:
		print(child.name)
		if "Visuals" in child.name:
			merged.connect(child.get_node("Value")._on_ball_merged)
		child.reparent(self)
		merged_balls.append(child)
	merged.emit()
	target_progress += 1
	other.queue_free()
	if !cashing_in && target_progress >= ball_value:
		start_cash_in()
	elif cashing_in:
		cashing_bonus += 1
		var timer = get_node("Timer")
		var time_remaining = timer.get_time_left()
		timer.stop()
		timer.start(time_remaining + 1)
		print(time_remaining + 1)


func start_cash_in():
	cashing_in = true
	get_node("Timer").start()
	color = color_cash
	sleeping = true


func finish_cash_in():
	cashing_in = false
	for ball in merged_balls:
		ball.queue_free()
	merged_balls = []
	color = color_normal
	sleeping = false
	target_progress = 1
	ball_value += cashing_bonus
	cashed.emit()


func check_out_of_bounds():
	for child in find_children("*Collider*", "Node2D", false, false):
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
		if x_min < 0.0 or x_max > vp_width or y_min < 0.0 or y_max > vp_height:
			return true
	return false


func _process(delta):
	print(current_death_time)
	if check_out_of_bounds():
		current_death_time += delta
		if current_death_time > death_time:
			# End game!
			pass
	elif current_death_time > 0:
		current_death_time = max(0, current_death_time - delta)


func _ready():
	color = color_normal
	apply_central_impulse(initial_impulse)


func _physics_process(delta):
	if(gravity_well != null && !cashing_in):
		var me_to_well = gravity_well.global_position - global_position
		var distance = me_to_well.length_squared()
		var direction = me_to_well.normalized()

		var force = base_force * direction
		var falloff = 1 / max(1, (distance / 10000))
		apply_force(force * falloff, Vector2.ZERO)


func _on_body_entered(body):
	var my_velocity = linear_velocity
	var their_velocity = body.linear_velocity
	if body.ball_value == ball_value:
		sleeping = true
		call_deferred("steal_children", body)


func _on_timer_timeout():
	finish_cash_in()
