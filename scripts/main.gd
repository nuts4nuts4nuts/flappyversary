extends Node2D

enum SPAWNING_ALGORITHM {PureRandom, DontRepeat, CountUp}
var spawn_funcs = {
	SPAWNING_ALGORITHM.PureRandom: algo_pure_random,
	SPAWNING_ALGORITHM.DontRepeat: algo_dont_repeat,
	SPAWNING_ALGORITHM.CountUp: algo_count_up,
}
enum WELL_PROFILE {Standard, FastAndClose, Strong}
@export var well_profile : WELL_PROFILE
var standard_well = {"max_distance": 1024,
					 "non_target_mult": 300,
					 "gravity_distance": load("res://gravity_curves/standard.tres")}
var fast_and_close_well = {"max_distance": 256,
						   "non_target_mult": 800,
						   "gravity_distance": load("res://gravity_curves/fast_and_close.tres")}
var strong_well = {"max_distance": 300,
					"non_target_mult": 1200,
					"gravity_distance": load("res://gravity_curves/strong.tres")}
var well_mappings = {
	WELL_PROFILE.Standard: standard_well,
	WELL_PROFILE.FastAndClose: fast_and_close_well,
	WELL_PROFILE.Strong: strong_well
}
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
@export var spawn_balls_on_cash_in : bool = false
@export var cash_in_ball_spawn_offset_min : float = -300
@export var cash_in_ball_spawn_offset_max : float = 300

var cashin_ball_spawn_initial_delay = 0.2

var ball_spawner_rng : RandomNumberGenerator
var spawn_pos_ratio : float

var game_running = false

var last_generated_number = 0
var high_score: int = 2
var was_any_ball_dying: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	print("ready")
	$gravity_well.configure(well_mappings[well_profile])
	ClusterManager.main_scene = self

	# Connect to cluster signals
	GameEvents.ball_leaving_screen.connect(_on_ball_leaving_screen)
	GameEvents.cluster_merged.connect(_on_cluster_merged)

	if spawn_balls_on_cash_in:
		GameEvents.cluster_merged.connect(_on_cluster_cashed_in_spawn_balls)

	$HUD.start_requested.connect(start_game)
	$HUD.restart_requested.connect(restart_game)


func _process(delta):
	$SpawnTimer.wait_time = spawn_interval
	spawn_pos_ratio += delta * spawn_pos_orbit_speed
	if spawn_pos_ratio > 1.0:
		spawn_pos_ratio -= 1.0

	# Centralized death tracking - find ball with highest death time
	if game_running:
		update_death_danger_state()

	queue_redraw()


func update_death_danger_state():
	var max_death_time: float = 0.0
	var most_endangered_ball: BallGroup = null

	for child in get_children():
		if child is BallGroup and child.is_dying_offscreen:
			if child.current_death_time > max_death_time:
				max_death_time = child.current_death_time
				most_endangered_ball = child

	if most_endangered_ball:
		var time_remaining = max(0.0, most_endangered_ball.death_time - max_death_time)
		GameEvents.target_ball_dying.emit(time_remaining)
		was_any_ball_dying = true
	elif was_any_ball_dying:
		GameEvents.target_ball_safe.emit()
		was_any_ball_dying = false


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
	GameEvents.game_restarting.emit()  # Balls self-cleanup
	game_running = true
	high_score = 2
	was_any_ball_dying = false
	ball_spawner_rng = RandomNumberGenerator.new()
	ClusterManager.clear_all_clusters()
	$gravity_well.activate()
	spawn_starting_ball()
	$SpawnTimer.start()


func spawn_starting_ball():
	var start_pos = get_viewport_rect().size * Vector2(0.5, 0.33)
	spawn_ball(start_pos, 2, Vector2.ZERO)


func restart_game():
	start_game()


func sleep(sec):
	await get_tree().create_timer(sec).timeout


func end_game():
	$gravity_well.deactivate()
	$SpawnTimer.stop()
	$HUD.show_restart()
	game_running = false
	# Reset danger state so UI hides
	if was_any_ball_dying:
		was_any_ball_dying = false
		GameEvents.target_ball_safe.emit()


func _on_ball_leaving_screen(_ball):
	end_game()


func _on_cluster_merged(new_value, _pos):
	if new_value > high_score:
		high_score = new_value
		GameEvents.high_score_updated.emit(high_score)


func _on_cluster_cashed_in_spawn_balls(_new_value, _pos):
	populate_with_new_balls()


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
	var top_range = int(ceil(max_spawn_value_methods[max_spawn_value_method].call(high_score)))
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
