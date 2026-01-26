extends Node

class ClusterData:
	var balls: Array = []
	var value: int
	var timer: Timer
	var is_cashing: bool = false
	var cluster_id: int

var clusters: Dictionary = {}  # cluster_id -> ClusterData
var next_cluster_id: int = 0
var cash_in_duration: float = 3.0
var main_scene: Node = null


func _ready():
	GameEvents.game_restarting.connect(_on_game_restarting)


func _on_game_restarting():
	clear_all_clusters()


func clear_all_clusters():
	for cluster_id in clusters.keys():
		var cluster = clusters[cluster_id]
		if cluster.timer:
			cluster.timer.queue_free()
	clusters.clear()
	next_cluster_id = 0


func handle_same_value_collision(ball_a, ball_b):
	# Don't allow new clusters after game has ended
	if main_scene and not main_scene.game_running:
		return

	var a_cluster = ball_a.cluster_id
	var b_cluster = ball_b.cluster_id

	if a_cluster == -1 and b_cluster == -1:
		# Neither in cluster - create new
		create_cluster([ball_a, ball_b], ball_a.ball_value)
	elif a_cluster == -1:
		# A not in cluster - join B's cluster
		add_ball_to_cluster(ball_a, b_cluster)
	elif b_cluster == -1:
		# B not in cluster - join A's cluster
		add_ball_to_cluster(ball_b, a_cluster)
	elif a_cluster != b_cluster:
		# Both in different clusters - merge clusters
		merge_clusters(a_cluster, b_cluster)
	# else: same cluster, do nothing


func create_cluster(balls: Array, value: int):
	var cluster = ClusterData.new()
	cluster.cluster_id = next_cluster_id
	cluster.value = value
	cluster.balls = balls.duplicate()
	cluster.is_cashing = true

	# Assign cluster_id to balls and start cashing visual
	for ball in balls:
		ball.cluster_id = next_cluster_id
		ball.start_cashing()

	# Create and start timer
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = cash_in_duration
	add_child(timer)
	timer.timeout.connect(_on_cluster_timer_timeout.bind(next_cluster_id))
	timer.start()
	cluster.timer = timer

	clusters[next_cluster_id] = cluster

	GameEvents.cluster_cashing_in.emit(next_cluster_id, value, balls.size(), cash_in_duration)
	next_cluster_id += 1


func add_ball_to_cluster(ball, cluster_id: int):
	if not clusters.has(cluster_id):
		return

	var cluster = clusters[cluster_id]
	cluster.balls.append(ball)
	ball.cluster_id = cluster_id
	ball.start_cashing()

	# Reset timer
	cluster.timer.stop()
	cluster.timer.start(cash_in_duration)

	GameEvents.cluster_cashing_in.emit(cluster_id, cluster.value, cluster.balls.size(), cash_in_duration)


func merge_clusters(cluster_id_a: int, cluster_id_b: int):
	if not clusters.has(cluster_id_a) or not clusters.has(cluster_id_b):
		return

	var cluster_a = clusters[cluster_id_a]
	var cluster_b = clusters[cluster_id_b]

	# Merge B into A (balls from B should already be cashing)
	for ball in cluster_b.balls:
		cluster_a.balls.append(ball)
		ball.cluster_id = cluster_id_a
		# Ensure cashing state in case it wasn't set
		ball.start_cashing()

	# Stop and remove B's timer
	cluster_b.timer.stop()
	cluster_b.timer.queue_free()
	clusters.erase(cluster_id_b)

	# Reset A's timer
	cluster_a.timer.stop()
	cluster_a.timer.start(cash_in_duration)

	GameEvents.cluster_cashing_in.emit(cluster_id_a, cluster_a.value, cluster_a.balls.size(), cash_in_duration)


func _on_cluster_timer_timeout(cluster_id: int):
	if not clusters.has(cluster_id):
		return

	var cluster = clusters[cluster_id]
	var n = cluster.value
	var b = cluster.balls.size()
	var new_value = n * int(pow(2, b - 1))

	# Calculate center of mass
	var center = Vector2.ZERO
	var valid_balls = 0
	for ball in cluster.balls:
		if is_instance_valid(ball):
			center += ball.global_position
			valid_balls += 1

	if valid_balls == 0:
		# All balls were freed somehow
		cluster.timer.queue_free()
		clusters.erase(cluster_id)
		return

	center /= valid_balls

	# Remove old balls
	for ball in cluster.balls:
		if is_instance_valid(ball):
			ball.queue_free()

	# Spawn merged ball via main scene
	if main_scene:
		main_scene.spawn_ball(center, new_value, Vector2.ZERO)

	GameEvents.cluster_merged.emit(new_value, center)
	cluster.timer.queue_free()
	clusters.erase(cluster_id)


func remove_ball_from_cluster(ball):
	if ball.cluster_id == -1:
		return

	var cluster_id = ball.cluster_id
	if not clusters.has(cluster_id):
		return

	var cluster = clusters[cluster_id]
	cluster.balls.erase(ball)

	# If cluster now has less than 2 balls, cancel it
	if cluster.balls.size() < 2:
		for remaining_ball in cluster.balls:
			if is_instance_valid(remaining_ball):
				remaining_ball.cluster_id = -1
				remaining_ball.stop_cashing()
		cluster.timer.stop()
		cluster.timer.queue_free()
		clusters.erase(cluster_id)
