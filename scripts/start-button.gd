extends Control

@export var button_text = "Start"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Button.text = button_text


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	pass # Replace with function body.


func restart_game():
	# Remove all balls
	# Remove UI
	pass
