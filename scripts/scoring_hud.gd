extends Label

var target_ball
var target_timer


# Called when the node enters the scene tree for the first time.
func _ready():
	target_ball = get_parent().get_parent().get_node("target_ball")
	target_timer = target_ball.get_node("Timer")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if(target_ball != null):
		update_value()
	pass


func update_value():
	if(target_ball.cashing_in):
		var number = "%.2f" % target_timer.get_time_left()
		text = number
	else:
		text = str("")
