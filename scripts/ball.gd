class_name BallGroup

extends RigidBody2D

signal merged
signal ball_expired_offscreen(damage_portion: float)

@export var initial_impulse: Vector2
@export var gravity_well: Node2D
@export var color: Color
@export var color_cashing: Color = Color(0, 0.7, 0.2, 1)  # Green when cashing in
@export var death_time: float = 5
@export var targetball_mass_damage_portion: float = 0.2
@export var mass_damage_enabled: bool = false

var is_target = false
var merge_boost = 0.2
var ball_value = 1:
	set(value):
		ball_value = value
		update_scale_for_value()
var base_force = 200
var current_death_time = 0.0
var cluster_id: int = -1  # -1 = not in cluster
var is_dying_offscreen: bool = false
var is_cashing: bool = false
var original_color: Color
var has_triggered_death: bool = false

func _ready():
	original_color = color
	update_scale_for_value()
	apply_central_impulse(initial_impulse)
	GameEvents.game_restarting.connect(_on_game_restarting)


func update_scale_for_value():
	# Scale based on value - value 1 is base size, value 64 is 2x size
	var scale_factor = pow(float(ball_value), 1.0 / 6.0)  # Sixth root: 64 -> 2x

	# Scale the visuals
	var visuals = get_node_or_null("Visuals")
	if visuals:
		visuals.scale = Vector2(scale_factor, scale_factor)

	# Scale the collision shape
	var collider = get_node_or_null("Collider")
	if collider and collider.shape:
		var new_shape = CircleShape2D.new()
		new_shape.radius = 64.0 * scale_factor
		collider.shape = new_shape


func _on_game_restarting():
	queue_free()


func _exit_tree():
	if GameEvents.game_restarting.is_connected(_on_game_restarting):
		GameEvents.game_restarting.disconnect(_on_game_restarting)
	# Clean up cluster reference
	if cluster_id != -1:
		ClusterManager.remove_ball_from_cluster(self)


func _process(delta):
	# Pause death timer while any cluster is cashing in
	var any_cluster_cashing = ClusterManager.clusters.size() > 0

	if check_out_of_bounds():
		if not any_cluster_cashing:
			current_death_time += delta
		is_dying_offscreen = true
		if current_death_time > death_time and not has_triggered_death:
			# Ball is leaving screen - this ends the game (only emit once)
			has_triggered_death = true
			GameEvents.ball_leaving_screen.emit(self)
	elif current_death_time > 0:
		if not any_cluster_cashing:
			current_death_time = max(0, current_death_time - delta)
		if is_dying_offscreen:
			is_dying_offscreen = false


# true if ALL are out of bounds
func check_out_of_bounds():
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
		if x_min > 0.0 and x_max < vp_width and y_min > 0.0 and y_max < vp_height:
			return false
	return true


func _physics_process(_delta):
	if is_cashing:
		# Freeze when cashing in
		linear_velocity = Vector2.ZERO
		angular_velocity = 0
	elif gravity_well != null:
		gravity_well.get_sucked(self)


func start_cashing():
	is_cashing = true
	color = color_cashing


func stop_cashing():
	is_cashing = false
	color = original_color


func _on_body_entered(body):
	if body is BallGroup and body.ball_value == ball_value:
		# Same value collision - delegate to ClusterManager
		# Only process if we're the "lower" name to avoid double-processing
		if name < body.name:
			ClusterManager.handle_same_value_collision(self, body)


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
