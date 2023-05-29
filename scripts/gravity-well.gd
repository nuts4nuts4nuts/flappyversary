extends Node2D
var attraction_force = 40

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _input(event):
	if event.is_action_pressed("make_well"):
		make_well(event)

func make_well(event):
	print("mouse button event at ", event.position)
	self.position = event.position

