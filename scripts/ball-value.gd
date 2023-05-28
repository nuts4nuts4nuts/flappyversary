extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	update_value()


func _on_ball_merged():
	update_value()


func update_value():
	text = str(get_parent().get_parent().ball_value)
