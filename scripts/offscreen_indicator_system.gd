extends Node2D

@export var indicator_scene: PackedScene
@export var indicator_margin: float = 100.0
@export var max_indicators: int = 5

var is_active: bool = false
var indicators: Dictionary = {}  # ball instance id -> indicator node

func set_active(active: bool):
	is_active = active
	if not is_active:
		clear_indicators()


func _process(_delta: float):
	if not is_active:
		return
	update_indicators()


func update_indicators():
	if indicator_scene == null:
		return

	var rect = get_viewport_rect()
	var center = rect.size * 0.5
	var candidates: Array = []

	var host = get_parent()
	if host == null:
		return

	for child in host.get_children():
		if child is BallGroup and is_instance_valid(child) and is_ball_completely_offscreen(child):
			candidates.append(child)

	candidates.sort_custom(func(a: BallGroup, b: BallGroup):
		return a.current_death_time > b.current_death_time
	)

	var visible_ids: Dictionary = {}
	var count = mini(max_indicators, candidates.size())
	for i in range(count):
		var ball: BallGroup = candidates[i]
		var ball_id = ball.get_instance_id()
		visible_ids[ball_id] = true

		if not indicators.has(ball_id):
			indicators[ball_id] = indicator_scene.instantiate()
			add_child(indicators[ball_id])

		var indicator = indicators[ball_id]
		if not is_instance_valid(indicator):
			indicators.erase(ball_id)
			continue

		var dir = ball.global_position - center
		if dir.length_squared() < 1.0:
			dir = Vector2.RIGHT
		dir = dir.normalized()

		var half = rect.size * 0.5 - Vector2.ONE * indicator_margin
		half.x = maxf(half.x, 1.0)
		half.y = maxf(half.y, 1.0)

		var tx = INF if is_zero_approx(dir.x) else absf(half.x / dir.x)
		var ty = INF if is_zero_approx(dir.y) else absf(half.y / dir.y)
		var t = minf(tx, ty)
		var edge = center + dir * t
		edge.x = clampf(edge.x, indicator_margin, rect.size.x - indicator_margin)
		edge.y = clampf(edge.y, indicator_margin, rect.size.y - indicator_margin)

		var urgency = ball.current_death_time / maxf(ball.death_time, 0.001)
		indicator.update_indicator(edge, dir.angle(), urgency)

	for id in indicators.keys():
		if not visible_ids.has(id):
			var stale = indicators[id]
			if is_instance_valid(stale):
				stale.queue_free()
			indicators.erase(id)


func clear_indicators():
	for id in indicators.keys():
		var indicator = indicators[id]
		if is_instance_valid(indicator):
			indicator.queue_free()
	indicators.clear()


func is_ball_completely_offscreen(ball: BallGroup) -> bool:
	var vp = get_viewport_rect().size
	var colliders = ball.find_children("", "BallCollider", false, false)
	if colliders.is_empty():
		return false

	for child in colliders:
		var collider = child as CollisionShape2D
		if collider == null:
			return false
		var circle = collider.shape as CircleShape2D
		if circle == null:
			return false

		var pos = collider.global_position
		var radius = circle.radius
		var x_min = pos.x - radius
		var x_max = pos.x + radius
		var y_min = pos.y - radius
		var y_max = pos.y + radius

		var fully_outside = x_max < 0.0 or x_min > vp.x or y_max < 0.0 or y_min > vp.y
		if not fully_outside:
			return false

	return true
