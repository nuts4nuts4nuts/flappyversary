extends Node

signal game_over_requested

enum LOSS_MODE {OffscreenBallDeath, CountdownResetOnHighScore}
enum TIMER_RESET_METHOD {Linear, Log2, Sqrt}
enum COUNTDOWN_PAUSE_MODE {PredictedHighScoreCashIn, LastSecondAnyCashIn}

@export var mode: LOSS_MODE = LOSS_MODE.OffscreenBallDeath

@export_group("Loss Condition")
@export var timer_reset_method: TIMER_RESET_METHOD = TIMER_RESET_METHOD.Log2
@export var countdown_pause_mode: COUNTDOWN_PAUSE_MODE = COUNTDOWN_PAUSE_MODE.PredictedHighScoreCashIn
@export var panic_pause_threshold_seconds: float = 1.0
@export var base_time_seconds: float = 30.0
@export var per_value_seconds: float = 0.8
@export var min_reset_time_seconds: float = 3.0
@export var max_reset_time_seconds: float = 60.0

var is_running: bool = false
var time_remaining: float = 0.0
var current_high_score: int = 1

func _ready():
	GameEvents.ball_leaving_screen.connect(_on_ball_leaving_screen)
	GameEvents.high_score_updated.connect(_on_high_score_updated)
	GameEvents.game_restarting.connect(_on_game_restarting)


func _process(delta: float):
	if not is_running:
		return

	if mode == LOSS_MODE.CountdownResetOnHighScore:
		var should_pause = _should_pause_countdown()
		if not should_pause:
			time_remaining = maxf(0.0, time_remaining - delta)
		GameEvents.target_ball_dying.emit(time_remaining)
		if time_remaining <= 0.0:
			is_running = false
			game_over_requested.emit()


func start_condition(initial_largest_value: int):
	is_running = true
	current_high_score = maxi(1, initial_largest_value)
	if mode == LOSS_MODE.CountdownResetOnHighScore:
		reset_countdown_for_value(initial_largest_value)
	else:
		GameEvents.target_ball_safe.emit()


func stop_condition():
	is_running = false
	GameEvents.target_ball_safe.emit()


func should_track_offscreen_danger() -> bool:
	return mode == LOSS_MODE.OffscreenBallDeath


func reset_countdown_for_value(largest_value: int):
	var reset_time = _time_for_value(largest_value)
	time_remaining = clampf(reset_time, min_reset_time_seconds, max_reset_time_seconds)


func _time_for_value(value: int) -> float:
	var clamped_value = maxi(1, value)
	match timer_reset_method:
		TIMER_RESET_METHOD.Linear:
			return base_time_seconds + per_value_seconds * float(clamped_value)
		TIMER_RESET_METHOD.Sqrt:
			return base_time_seconds + per_value_seconds * sqrt(float(clamped_value))
		_:
			return base_time_seconds + per_value_seconds * (log(float(clamped_value)) / log(2.0))


func _should_pause_countdown() -> bool:
	match countdown_pause_mode:
		COUNTDOWN_PAUSE_MODE.LastSecondAnyCashIn:
			return _should_pause_last_second_any_cashing()
		_:
			return _should_pause_countdown_for_pending_high_score()


func _should_pause_countdown_for_pending_high_score() -> bool:
	for cluster in ClusterManager.clusters.values():
		var ball_count = cluster.balls.size()
		if ball_count < 2:
			continue

		var projected_value = int(cluster.value) * int(pow(2, ball_count - 1))
		if projected_value > current_high_score:
			return true

	return false


func _should_pause_last_second_any_cashing() -> bool:
	if time_remaining > panic_pause_threshold_seconds:
		return false
	return not ClusterManager.clusters.is_empty()


func _on_ball_leaving_screen(_ball):
	if is_running and mode == LOSS_MODE.OffscreenBallDeath:
		game_over_requested.emit()


func _on_high_score_updated(value: int):
	current_high_score = maxi(1, value)
	if is_running and mode == LOSS_MODE.CountdownResetOnHighScore:
		reset_countdown_for_value(value)


func _on_game_restarting():
	stop_condition()
