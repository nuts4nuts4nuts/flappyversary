extends Node2D

var game_started = false
var particles
var main


# Called when the node enters the scene tree for the first time.
func _ready():
	main = get_parent()
	particles = get_node("GPUParticles2D")


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
	particles.restart()


func get_gravity_power(raw_distance: int, target_ball: bool):
	var gravity_distance = main.well_mappings[main.well_profile]["gravity_distance"]
	var max_distance = main.well_mappings[main.well_profile]["max_distance"]
	var target_mult = 0 if main.stationary_targetball else main.well_mappings[main.well_profile]["target_mult"]
	var non_target_mult = main.well_mappings[main.well_profile]["non_target_mult"]
	var power_mult = target_mult if target_ball else non_target_mult
	return gravity_distance.sample(min(float(raw_distance) / float(max_distance), 1.0)) * power_mult


func get_sucked(other, target_ball: bool):
	var other_to_well = global_position - other.avg_global_position()
	var distance = (global_position - other.nearest_global_position(global_position)).length()
	var force = get_gravity_power(distance, target_ball)
	var direction = other_to_well.normalized()
	other.apply_central_force(force * direction)
