extends RigidBody2D

signal merged
signal cashed

@export var initial_impulse: Vector2
@export var gravity_well: Node2D
@export var color_normal: Color
@export var color_cash: Color

var color: Color

var merge_boost = 0.2
var ball_value = 2
var base_force = 50
var is_target = true
var target_progress = 1
var cashing_in = false
var merged_balls = []
var cashing_bonus = 1

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
