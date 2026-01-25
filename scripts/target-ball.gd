extends RigidBody2D

signal merged
signal update_text
signal dead
signal cashed_in

@export var gravity_well: Node2D
@export var color_normal: Color
@export var color_cash: Color
@export var base_ball_value: int = 2
@export var base_cashing_bonus: int = 1
@export var start_pos: Vector2 = Vector2(0.5, 0.33)
@export var minimum_mass = 2
var initial_mass = mass

var color: Color
var merge_boost = 0.2
var ball_value = base_ball_value
var is_target = true
var target_progress = 1
var cashing_in = false
var merged_balls = []
var cashing_bonus = base_cashing_bonus
var current_death_time = 0.0
var config: Dictionary = {}
var was_close_to_death_last_frame = false


func configure(game_config: Dictionary):
	config = game_config


func start():
	position = get_viewport_rect().size * start_pos
	freeze = false
	ball_value = base_ball_value
	for ball in merged_balls:
		ball.queue_free()
	merged_balls = []
	color = color_normal
	target_progress = 1
	current_death_time = 0.0
	was_close_to_death_last_frame = false
	cashing_in = false
	GameEvents.target_ball_safe.emit()
	update_text.emit()


func end():
	freeze = true
	position = get_viewport_rect().get_center()


func apply_mass_damage(damage_portion: float):
	var damage = initial_mass * damage_portion
	mass = max(minimum_mass, mass - damage)
	print("targetball mass: " + str(mass))


func steal_children(other):
	print(name + " stealing")
	var children = other.get_children()
	for child in children:
		for subchild in child.get_children():
			if subchild is BallValue:
				subchild.display_ball_value = false
			if subchild is BallDrawer:
				subchild.color_alpha = 0.1
		print(child.name)
		child.reparent(self)
		merged_balls.append(child)
		child = false
	merged.emit()
	target_progress += 1
	other.queue_free()
	if !cashing_in:
		match config.scoring_behavior:
			config.SCORING_CONDITION_NOfN:
				if target_progress >= ball_value:
					start_cash_in()
			config.SCORING_CONDITION_OneOfN:
				start_cash_in()
	else:
		cashing_bonus += 1
		var timer = get_node("Timer")
		timer.stop()
		timer.start(timer.wait_time)
		GameEvents.target_ball_cashing_in.emit(timer.wait_time)
		print(timer.get_time_left())

func start_cash_in():
	cashing_in = true
	var timer: Timer = get_node("Timer")
	timer.wait_time = config.cashing_method.call(ball_value)
	timer.start()
	color = color_cash
	GameEvents.target_ball_cashing_in.emit(timer.wait_time)


func finish_cash_in():
	cashing_in = false
	for ball in merged_balls:
		ball.queue_free()
	merged_balls = []
	color = color_normal
	target_progress = 1
	var increase_by = config.scoring_method.call(cashing_bonus)
	print("increase by ", increase_by)
	ball_value += increase_by
	cashing_bonus = base_cashing_bonus
	update_text.emit()
	cashed_in.emit()
	GameEvents.target_ball_cashed_in.emit()


# true if ANY is out of bounds (and not cashing)
func check_dying():
	if config.is_empty():
		return false

	if !config.is_game_running.call():
		return false

	match config.death_condition:
		config.DEATH_CONDITION_Always:
			return !cashing_in
		config.DEATH_CONDITION_OffScreen:
			for child in find_children("", "BallCollider", false, false):
				var child_node = child as CollisionShape2D
				var circle = child_node.shape as CircleShape2D
				var pos = child_node.global_position
				var radius = circle.radius
				var vp_width = get_viewport_rect().size.x
				var vp_height = get_viewport_rect().size.y

				var x_min = pos.x - radius
				var x_max = pos.x + radius
				var y_min = pos.y - radius
				var y_max = pos.y + radius
				if x_min < 0.0 or x_max > vp_width or y_min < 0.0 or y_max > vp_height:
					return !cashing_in
			return false


func death_time():
	return config.death_times[config.death_condition]


func close_to_death():
	if !check_dying():
		return false

	match config.death_condition:
		config.DEATH_CONDITION_Always:
			return (death_time() - current_death_time) < 15.0
		config.DEATH_CONDITION_OffScreen:
			return true


func avg_global_position():
	var pos = Vector2()
	var children = find_children("", "BallCollider", false, false)
	for child in children:
		pos += child.global_position
	return pos / children.size()


func nearest_global_position(point: Vector2):
	var distance: float = INF
	var nearest_so_far: Vector2
	var children = find_children("", "BallCollider", false, false)
	for child in children:
		var child_to_point_distance = (point - child.global_position).length()
		if child_to_point_distance < distance:
			distance = child_to_point_distance
			nearest_so_far = child.global_position
	return nearest_so_far


func _process(delta):
#	queue_redraw()
	if config.is_empty():
		return

	var is_dying = check_dying()
	if is_dying:
		current_death_time += delta
		if current_death_time > death_time():
			# End game!
			mass = initial_mass
			dead.emit()
	else: # not dying
		match config.death_condition:
			config.DEATH_CONDITION_Always:
				current_death_time = 0
			config.DEATH_CONDITION_OffScreen:
				current_death_time = max(0, current_death_time - delta)

	# Emit signals based on close_to_death() for UI updates
	var is_close = close_to_death()
	if is_close:
		var time_remaining = death_time() - current_death_time
		GameEvents.target_ball_dying.emit(time_remaining)
	elif was_close_to_death_last_frame:
		GameEvents.target_ball_safe.emit()

	was_close_to_death_last_frame = is_close

	if cashing_in or config.stationary_targetball:
		angular_velocity = 0
		linear_velocity = Vector2(0, 0)


#func _draw():
#	var p = avg_global_position() - global_position
#	draw_circle(p, 15.0, Color.DARK_GREEN)


func _ready():
	color = color_normal


func _physics_process(_delta):
	if(gravity_well != null && !cashing_in):
		gravity_well.get_sucked(self, true)


func _on_body_entered(body):
	if body.ball_value == ball_value:
		call_deferred("steal_children", body)


func _on_timer_timeout():
	finish_cash_in()
