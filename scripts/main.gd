extends Node2D

@export var ball_scene : PackedScene

var ball_value_low = 1
var ball_value_high = 1

var ball_spawner_rng : RandomNumberGenerator

# Called when the node enters the scene tree for the first time.
func _ready():
	print("ready")


func start_game():
	$gravity_well.activate()
	$SpawnTimer.start()
	$target_ball.start()
	ball_spawner_rng = RandomNumberGenerator.new()
	for child in find_children("*Ball*", "", false, false):
		print(child)
		child.queue_free()


func restart_game():
	start_game()


func end_game():
	$gravity_well.deactivate()
	$SpawnTimer.stop()
	$target_ball.end()
	$HUD.show_restart()


func _on_spawn_timer_timeout():
	spawn_ball()


func spawn_ball():
	var ball = ball_scene.instantiate()
	ball.gravity_well = $gravity_well
	var spawn_pos = $SpawnPos
	
	ball.position = spawn_pos.position
	var initial_x = ball_spawner_rng.randf_range(30, 100)
	var initial_y = ball_spawner_rng.randf_range(30, 100)
	var sign_x = 1 if ball_spawner_rng.randi_range(0, 1) else -1
	var sign_y = 1 if ball_spawner_rng.randi_range(0, 1) else -1
	ball.initial_impulse = Vector2(initial_x * sign_x, initial_y * sign_y)
	print(ball_value_high)
	ball.ball_value = ball_spawner_rng.randi_range(ball_value_low, ball_value_high - 1)
	add_child(ball)
