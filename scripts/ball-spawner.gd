extends Node2D

export (PackedScene) var ball

var ball_value_low = 1
var ball_value_high = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_timer_timeout():
	spawn_ball()


func spawn_ball():
	var ball = ball.instantiate()
	add_child(ball)
