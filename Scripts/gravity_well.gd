extends Area2D
var attraction_force = 40

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



var _attracted_objects = []

func _input(event):
	if event.is_action_pressed("make_well"):
		make_well(event)

func make_well(event):
	print("mouse button event at ", event.position)
	self.position = event.position
	_attracted_objects.clear()

func _physics_process(_delta):
	for i in _attracted_objects:
		if i.has_method("attract_to"):
			i.attract_to(global_position, attraction_force)

func _on_body_entered(body):
	_attracted_objects.append(body)

func _on_body_exited(body):
	_attracted_objects.erase(_attracted_objects.find(body))
