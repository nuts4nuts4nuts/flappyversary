extends Node
@export var test_ball_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	get_node("Ball")._gravity_well = $gravity_well
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("make_well"):
		make_well(event)

func make_well(event):
	print("mouse button eevent at ", event.position)


func _on_ball_timer_timeout():
	print("BALLING")
	var test_ball = test_ball_scene.instantiate()
	test_ball
	var ball_spawn_location = $spawn_position.position
	#get_node("ball_path/ball_path_location")
	#ball_spawn_location.h_offset = randi()
	#var direction = ball_spawn_location.rotation + PI / 2
	#test_ball.position = ball_spawn_location.position
	
	#direction += randf_range(-PI / 4, PI / 4)
	#test_ball.rotation = direction
	#var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	
	#test_ball.linear_velocity = velocity.rotated(direction)
	add_child(test_ball)
