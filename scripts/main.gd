extends Node2D

enum SPAWNING_ALGORITHM {PureRandom, DontRepeat, CountUp}
var spawn_funcs = {
	SPAWNING_ALGORITHM.PureRandom: algo_pure_random,
	SPAWNING_ALGORITHM.DontRepeat: algo_dont_repeat,
	SPAWNING_ALGORITHM.CountUp: algo_count_up,
	}

@export var ball_scene : PackedScene
@export var spawn_pos_orbit_speed : float = 0.20
@export var spawn_algorithm : SPAWNING_ALGORITHM

var ball_spawner_rng : RandomNumberGenerator
var spawn_pos_ratio : float

var game_running = false

var steals = 0
var last_generated_number = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	print("ready")


func _process(delta):
	spawn_pos_ratio += delta * spawn_pos_orbit_speed
	if spawn_pos_ratio > 1.0:
		spawn_pos_ratio -= 1.0

	queue_redraw()


func _draw():
	draw_incoming_ball_indicator(ball_spawn_pos(get_viewport_rect(), spawn_pos_ratio), $SpawnTimer.time_left)


func _unhandled_key_input(event: InputEvent):
	# DEBUG STUFF
	if OS.has_feature("editor") and event.is_pressed():
		# spawn balls with 1 through 9
		var key_number = int(event.key_label) - 48
		
		if key_number >= 0 and key_number < 10:
			spawn_ball(get_global_mouse_position(), Vector2.ZERO, key_number)
		
		# change engine speed with up and down arrow
		if event.keycode == Key.KEY_UP:
			Engine.time_scale += 0.25
			print("Engine timescale: " + str(Engine.time_scale))
		elif event.keycode == Key.KEY_DOWN:
			Engine.time_scale -= 0.25
			print("Engine timescale: " + str(Engine.time_scale))


func start_game():
	game_running = true
	ball_spawner_rng = RandomNumberGenerator.new()
	for child in find_children("", "BallGroup", false, false):
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


func _on_spawn_timer_timeout():
	var direction = (get_viewport_rect().get_center() - ball_spawn_pos(get_viewport_rect(), spawn_pos_ratio)).normalized()
	var velo = ball_spawner_rng.randf_range(100, 200)
	if($target_ball.ball_value > 2):
		last_generated_number = generate_new_number(last_generated_number)
		print(last_generated_number)
	else:
		last_generated_number = 1
	spawn_ball(ball_spawn_pos(get_viewport_rect(), spawn_pos_ratio), direction * velo, last_generated_number)

func generate_new_number(previous_number):
	var top_range = int(ceil($target_ball.ball_value / 2.0))
	return spawn_funcs[spawn_algorithm].call(top_range, previous_number)

func algo_pure_random(top_range, previous_number):
	return ball_spawner_rng.randi_range(1, top_range)

func algo_dont_repeat(top_range, previous_number):
	var new_number = ball_spawner_rng.randi_range(1, top_range - 1)
	if(new_number >= previous_number):
		new_number += 1
	return new_number

func algo_count_up(top_range, previous_number):
	return previous_number % top_range + 1

func spawn_ball(pos, impulse, value):
	var ball = ball_scene.instantiate()
	ball.gravity_well = $gravity_well

	ball.position = pos
	ball.initial_impulse = impulse
	ball.ball_value = value
	add_child(ball)


func draw_incoming_ball_indicator(pos, time_to_spawn):
	var ball_size = 32.0
	var portion_of_spawn_timer_remaining = time_to_spawn / $SpawnTimer.wait_time
	var ball_scale = 1.0 - portion_of_spawn_timer_remaining
	draw_circle(pos, ball_size * ball_scale, Color.RED)


func ball_spawn_pos(rect: Rect2, t: float):
	var aspect_ratio = rect.size.x / rect.size.y
	var tx = aspect_ratio / (2 + 2 * aspect_ratio)
	var ty = 0.5 - tx
	if t < tx:
		return Vector2(lerpf(rect.position.x, rect.position.x + rect.size.x, t / tx), rect.position.y)
	elif t < tx + ty:
		t -= tx
		return Vector2(rect.position.x + rect.size.x, lerpf(rect.position.y, rect.position.y + rect.size.y, t / ty))
	elif t < 2 * tx + ty:
		t -= tx + ty
		return Vector2(lerpf(rect.position.x + rect.size.x, rect.position.x, t / tx), rect.position.y + rect.size.y)
	else:
		t -= 2 * tx + ty
		return Vector2(rect.position.x, lerpf(rect.position.y + rect.size.y, rect.position.y, t / ty))
