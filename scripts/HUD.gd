extends CanvasLayer

signal start_requested
signal restart_requested


func _ready():
	$ShareButton.hide()


func _on_start_button_pressed():
	$StartButton.hide()
	$ShareButton.hide()
	if $StartButton.text == "Start":
		start_requested.emit()
	else:
		restart_requested.emit()


func _on_share_button_pressed() -> void:
	screenshot()


func show_restart():
	$StartButton.text = "Restart"
	$StartButton.show()


func screenshot():
	var capture = get_viewport().get_texture().get_image()
	var _time = Time.get_datetime_string_from_system()
	var filename = OS.get_data_dir() + "/Screenshot-{0}.png".format({"0":_time})
	capture.save_png(filename)
