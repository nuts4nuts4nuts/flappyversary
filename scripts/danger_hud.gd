extends Label

var target_ball


# Called when the node enters the scene tree for the first time.
func _ready():
	target_ball = get_parent().get_parent().get_node("target_ball")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if(target_ball != null):
		update_value()


func update_value():
	if(target_ball.check_dying()):
		var number = "%.2f" % (target_ball.death_time - target_ball.current_death_time)
		text = "COLLAPSE INCOMING IN " + number
	else:
		text = str("")
