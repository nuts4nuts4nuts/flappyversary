extends Node2D

var game_started = false
var particles
var well_config: Dictionary


func _ready():
	particles = get_node("GPUParticles2D")


func configure(config: Dictionary):
	well_config = config


func activate():
	game_started = true


func deactivate():
	game_started = false


func _input(event):
	if game_started and event.is_action_pressed("make_well"):
		make_well(event)


func make_well(event):
	self.position = event.position
	particles.restart()
	# $place_well_sound.play()


func get_gravity_power(raw_distance: int):
	var gravity_distance = well_config["gravity_distance"]
	var max_distance = well_config["max_distance"]
	var non_target_mult = well_config["non_target_mult"]
	return gravity_distance.sample(min(float(raw_distance) / float(max_distance), 1.0)) * non_target_mult


func get_sucked(other):
	var other_to_well = global_position - other.avg_global_position()
	var distance = (global_position - other.nearest_global_position(global_position)).length()
	var force = get_gravity_power(distance)
	var direction = other_to_well.normalized()
	other.apply_central_force(force * direction)
