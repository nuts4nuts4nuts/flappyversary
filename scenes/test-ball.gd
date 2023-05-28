extends RigidBody2D

var gravity = 0

var _velocity = Vector2.ZERO
var _last_position


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func attract_to(pos, force):
	var dist = global_position.distance_to(pos)
	var v = global_position.direction_to(pos) * force
	#v = v.clamped(dist)
	print(v)
	self.linear_velocity += v
	var resistance = -0.1 * self.linear_velocity
	self.linear_velocity += resistance

func _physics_process(delta):
	_velocity.y += gravity
	
	if global_position.x < 0:
		global_position.x = get_viewport_rect().size.x
	elif global_position.x > get_viewport_rect().size.x:
		global_position.x = 0
	
	
	
	
	_last_position = global_position
