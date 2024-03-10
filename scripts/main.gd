extends Node2D

@export var ball_scene : PackedScene

var ball_value_low = 1
var ball_value_high = 1

var ball_spawner_rng : RandomNumberGenerator

var game_running = false

# Called when the node enters the scene tree for the first time.
func _ready():
	print("ready")


func _process():
	queue_redraw()


func _draw():
	


func _unhandled_key_input(event):
	if event.is_pressed():
		var key_number = int(event.key_label) - 48
		if key_number >= 0 and key_number < 10:
			spawn_ball(get_global_mouse_position(), Vector2.ZERO, key_number)


func start_game():
	game_running = true
	ball_spawner_rng = RandomNumberGenerator.new()
	for child in find_children("*Ball*", "", false, false):
		child.queue_free()
	$gravity_well.activate()
	$SpawnTimer.start()
	$target_ball.start()


func restart_game():
	start_game()


func sleep(sec):
	await get_tree().create_timer(sec).timeout


func end_game():
	$gravity_well.deactivate()
	$SpawnTimer.stop()
	$target_ball.end()
	$HUD.show_restart()
	game_running = false
	ball_value_high = 1


func _on_spawn_timer_timeout():
	var screen_center = get_viewport_rect().size / 2
	var spawn_pos = $SpawnPath/SpawnPosition
	spawn_pos.progress_ratio = ball_spawner_rng.randf()
	var direction = (screen_center - spawn_pos.position).normalized()
	var velo = ball_spawner_rng.randf_range(100, 200)
	spawn_ball(spawn_pos.position, direction * velo, ball_spawner_rng.randi_range(ball_value_low, ball_value_high - 1))


func spawn_ball(pos, impulse, value):
	var ball = ball_scene.instantiate()
	ball.gravity_well = $gravity_well

	ball.position = pos
	ball.initial_impulse = impulse
	ball.ball_value = value
	add_child(ball)


func _on_target_ball_update_text():
	ball_value_high += 1
