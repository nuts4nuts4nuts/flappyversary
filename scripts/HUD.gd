extends CanvasLayer

var _parent

# Called when the node enters the scene tree for the first time.
func _ready():
	_parent = get_parent()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_button_pressed():
	if $StartButton.text == "Start":
		$StartButton.hide()
		_parent.start_game()
	else:
		$StartButton.hide()
		_parent.restart_game()


func show_restart():
	$StartButton.text = "Restart"
	$StartButton.show()
