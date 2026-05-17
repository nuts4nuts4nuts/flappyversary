extends Sprite2D
var main

var value
var impulse
signal expired(pos, value, impulse)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func init(_time, _value, _impulse):
	value = _value
	impulse = _impulse
	$visibility_timer.wait_time = _time
	$visibility_timer.start()

func _on_despawn_timer_timeout() -> void:
	expired.emit(global_position, value, impulse)
	queue_free()

func _on_visibility_timer_timeout() -> void:
	print("VISIBLE NOW")
	visible = true
	$despawn_timer.start()
