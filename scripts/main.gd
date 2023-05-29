extends Node2D

@export var ball_scene : PackedScene

var ball_value_low = 1
var ball_value_high = 2

var ball_spawner_rng : RandomNumberGenerator

# Called when the node enters the scene tree for the first time.
func _ready():
	$SpawnTimer.start()
	ball_spawner_rng = RandomNumberGenerator.new()


func _on_spawn_timer_timeout():
	spawn_ball()


func spawn_ball():
	var ball = ball_scene.instantiate()
	
	var spawn_pos = $BallSpawnPos
	
	ball.position = spawn_pos.position
	var initial_x = ball_spawner_rng.randf_range(30, 100)
	var initial_y = ball_spawner_rng.randf_range(30, 100)
	var sign_x = 1 if ball_spawner_rng.randi_range(0, 1) else -1
	var sign_y = 1 if ball_spawner_rng.randi_range(0, 1) else -1
	ball.initial_impulse = Vector2(initial_x * sign_x, initial_y * sign_y)
	add_child(ball)
