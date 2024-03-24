extends Node2D

@export var gravity_distance: Curve
@export var max_distance: int = 1024
@export var target_mult: int = 400
@export var non_target_mult: int = 300

var attraction_force = 40
var game_started = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func activate():
	print("well active")
	game_started = true


func deactivate():
	print("well not active")
	game_started = false


func _input(event):
	if game_started and event.is_action_pressed("make_well"):
		make_well(event)


func make_well(event):
	print("mouse button event at ", event.position)
	self.position = event.position


func get_gravity_power(raw_distance: int, target_ball: bool):
	var power_mult = target_mult if target_ball else non_target_mult
	return gravity_distance.sample(min(float(raw_distance) / float(max_distance), 1.0)) * power_mult


func get_sucked(other, target_ball: bool):
	var other_to_well = global_position - other.avg_global_position()
	var distance = other_to_well.length()
	var force = get_gravity_power(distance, target_ball)
	var direction = other_to_well.normalized()
	other.apply_central_force(force * direction)
