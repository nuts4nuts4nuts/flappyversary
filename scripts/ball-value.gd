class_name BallValue

extends Label

var display_ball_value = true

func _process(_delta):
	update_value()


func update_value():
	if display_ball_value == true:
		text = str(get_parent().get_parent().ball_value)
	else:
		text = str(get_parent().get_parent().target_progress)
