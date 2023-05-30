extends RigidBody2D

signal merged

@export var initial_impulse: Vector2
@export var gravity_well: Node2D
@export var color_normal: Color
@export var color_cash: Color

var color: Color

var merge_boost = 0.2
var ball_value = 2
var base_force = 50
var is_target = true
var target_progress = 0
var cashing_in = false

func _ready():
	color = color_normal
	apply_central_impulse(initial_impulse)


func _physics_process(delta):
	if(gravity_well != null):
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
		call_deferred("steal_children", body)


func steal_children(other):
	print(name + " stealing")
	var children = other.get_children()
	for child in children:
		print(child.name)
		if "Visuals" in child.name:
			merged.connect(child.get_node("Value")._on_ball_merged)
		child.reparent(self)
	merged.emit()
	target_progress += 1
	other.queue_free()
	if !cashing_in && target_progress >= ball_value:
		start_cash_in()


func start_cash_in():
	get_node("Timer").start()
	color = color_cash
	freeze = true
	sleeping = true


func _on_timer_timeout():
	queue_free()
