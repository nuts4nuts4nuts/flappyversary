extends Label

	
func _process(_delta):
	update_value()


func update_value():
	text = str(get_parent().get_parent().ball_value)
