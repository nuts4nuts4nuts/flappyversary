extends Node2D

enum SPAWNING_ALGORITHM {PureRandom, DontRepeat, CountUp}
var spawn_funcs = {
	SPAWNING_ALGORITHM.PureRandom: algo_pure_random,
	SPAWNING_ALGORITHM.DontRepeat: algo_dont_repeat,
	SPAWNING_ALGORITHM.CountUp: algo_count_up,
}
enum SCORING_CONDITION {NOfN, OneOfN}
enum DEATH_CONDITION {OffScreen, Always}
@export var death_condition : DEATH_CONDITION
@export var death_times = {
	DEATH_CONDITION.OffScreen: 5,
	DEATH_CONDITION.Always: 60,
}
enum WELL_PROFILE {Standard, FastAndClose, Strong}
@export var well_profile : WELL_PROFILE
var standard_well = {"max_distance": 1024,
					 "target_mult": 400,
					 "non_target_mult": 300,
					 "gravity_distance": load("res://gravity_curves/standard.tres")}
var fast_and_close_well = {"max_distance": 256,
						   "target_mult": 300,
						   "non_target_mult": 800,
						   "gravity_distance": load("res://gravity_curves/fast_and_close.tres")}
var strong_well = {"max_distance": 300,
					"target_mult": 300,
					"non_target_mult": 1200,
					"gravity_distance": load("res://gravity_curves/strong.tres")}
var well_mappings = {
	WELL_PROFILE.Standard: standard_well,
	WELL_PROFILE.FastAndClose: fast_and_close_well,
	WELL_PROFILE.Strong: strong_well
}
enum SCORING_METHOD {AddN, TwoToN}
var scoring_methods = {
	SCORING_METHOD.AddN: func (n): return n,
	SCORING_METHOD.TwoToN: func (n): return 2**(n-1)
}
@export var scoring_method : SCORING_METHOD
enum CASHING_METHOD {N, FiveBaseFastGrowth}
var cashing_methods = {
	CASHING_METHOD.N: func (n): return n,
	CASHING_METHOD.FiveBaseFastGrowth: func (n): return 5 + floor(n*1.5)
}
@export var cashing_method : CASHING_METHOD
enum MAX_SPAWN_VALUE_METHOD {N, NDivTwo, NDivFour}
var max_spawn_value_methods = {
	MAX_SPAWN_VALUE_METHOD.N: func (n): return n,
	MAX_SPAWN_VALUE_METHOD.NDivTwo: func (n): return n / 2,
	MAX_SPAWN_VALUE_METHOD.NDivFour: func (n): return n / 4
}
@export var max_spawn_value_method : MAX_SPAWN_VALUE_METHOD

@export var ball_scene : PackedScene
@export var ball_spawn_warning_scene : PackedScene
@export var spawn_interval : float = 4.0
@export var spawn_pos_orbit_speed : float = 0.20
@export var spawn_algorithm : SPAWNING_ALGORITHM
@export var scoring_behavior : SCORING_CONDITION
@export var mass_damage : bool = false
@export var stationary_targetball : bool = false
@export var spawn_balls_on_cash_in : bool = false
@export var cash_in_ball_spawn_offset_min : float = -300
@export var cash_in_ball_spawn_offset_max : float = 300

var cashin_ball_spawn_initial_delay = 0.2

var ball_spawner_rng : RandomNumberGenerator
var spawn_pos_ratio : float

var game_running = false

var last_generated_number = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	print("ready")
	if(spawn_balls_on_cash_in):
		$target_ball.cashed_in.connect(populate_with_new_balls)


func _process(delta):
	$SpawnTimer.wait_time = spawn_interval
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
			spawn_ball(get_global_mouse_position(), key_number, Vector2.ZERO)
		
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
	var ball_value = generate_new_number(last_generated_number)
	print(last_generated_number)
	spawn_ball(ball_spawn_pos(get_viewport_rect(), spawn_pos_ratio), last_generated_number, direction * velo)

func populate_with_new_balls():
	var delay = cashin_ball_spawn_initial_delay
	for x in range(3):
		for y in range(3):
			var warning = ball_spawn_warning_scene.instantiate()
			add_child(warning)
			warning.global_position = Vector2(x * 1200 + 700 + ball_spawner_rng.randi_range(cash_in_ball_spawn_offset_min, cash_in_ball_spawn_offset_max), y * 700 + 500 + ball_spawner_rng.randi_range(cash_in_ball_spawn_offset_min, cash_in_ball_spawn_offset_max))
			warning.expired.connect(spawn_ball)
			warning.init(delay, generate_new_number(last_generated_number))
			delay += cashin_ball_spawn_initial_delay


func generate_new_number(previous_number):
	var top_range = int(ceil(max_spawn_value_methods[max_spawn_value_method].call($target_ball.ball_value)))
	last_generated_number = spawn_funcs[spawn_algorithm].call(top_range, previous_number)
	return last_generated_number


func algo_pure_random(top_range, previous_number):
	return ball_spawner_rng.randi_range(1, top_range)


func algo_dont_repeat(top_range, previous_number):
	var new_number = ball_spawner_rng.randi_range(1, top_range - 1)
	if(new_number >= previous_number):
		new_number += 1
	return new_number


func algo_count_up(top_range, previous_number):
	return previous_number % top_range + 1


func spawn_ball(pos, value = 1, impulse = Vector2.ZERO):
	print("ball spawning")
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
