extends Sprite2D
var main

var value
signal expired(pos, value)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass

func init(_time, _value):
	value = _value
	$visibility_timer.wait_time = _time
	$visibility_timer.start()

func _on_despawn_timer_timeout() -> void:
	expired.emit(global_position, value)
	queue_free()


func _on_visibility_timer_timeout() -> void:
	print("VISIBLE NOW")
	visible = true
	$despawn_timer.start()
