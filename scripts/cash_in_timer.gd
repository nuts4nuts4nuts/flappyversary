extends Label

var cluster_id: int = -1
var time_remaining: float = 0.0


func init(id: int, duration: float):
	cluster_id = id
	time_remaining = duration
	GameEvents.cluster_cashing_in.connect(_on_cluster_cashing_in)


func _on_cluster_cashing_in(id: int, _value: int, _ball_count: int, duration: float):
	if id == cluster_id:
		time_remaining = duration


func _process(delta: float):
	if not ClusterManager.clusters.has(cluster_id):
		queue_free()
		return

	var cluster = ClusterManager.clusters[cluster_id]
	var center = Vector2.ZERO
	var valid = 0
	for ball in cluster.balls:
		if is_instance_valid(ball):
			center += ball.global_position
			valid += 1

	if valid > 0:
		global_position = center / valid + Vector2(-size.x / 2.0, -size.y - 80.0)

	time_remaining -= delta
	text = "%.1f" % maxf(0.0, time_remaining)
