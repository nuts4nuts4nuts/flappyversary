extends CanvasLayer

var _parent

# Called when the node enters the scene tree for the first time.
func _ready():
	_parent = get_parent()
	$ShareButton	.hide()

func _on_start_button_pressed():
	$StartButton.hide()
	$ShareButton	.hide()
	if $StartButton.text == "Start":
		_parent.start_game()
	else:
		_parent.restart_game()


func _on_share_button_pressed() -> void:
	screenshot()


func show_restart():
	$StartButton.text = "Restart"
	$StartButton.show()
	$ShareButton	.show()


func screenshot():
	var capture = get_viewport().get_texture().get_image()
	var _time = Time.get_datetime_string_from_system()
	var filename = OS.get_data_dir() + "/Screenshot-{0}.png".format({"0":_time})
	capture.save_png(filename)
