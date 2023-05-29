extends RigidBody2D

signal merged

@export var initial_impulse: Vector2
@export var gravity_well: Node2D

var merge_boost = 0.2
var ball_value = 1
var force = 100000

func _ready():
	apply_central_impulse(initial_impulse)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _physics_process(delta):
	if(gravity_well != null):
		var me_to_well = gravity_well.global_position - global_position
		var distance = me_to_well.length_squared()
		var direction = me_to_well.normalized()

		var base_force = force * direction
		var falloff = 1 / max(1, distance)
		apply_force(base_force * falloff, Vector2.ZERO)


func _on_body_entered(body):
	var my_velocity = linear_velocity
	var their_velocity = body.linear_velocity
	
	if name < body.name:
		print(name + " stealing")
		apply_central_impulse((my_velocity + their_velocity) * 0.2)
		ball_value += ball_value
		var children = body.get_children()
		for child in children:
			print(child.name)
			if "Visuals" in child.name:
				merged.connect(child.get_node("Value")._on_ball_merged)
			child.reparent(self)
		body.queue_free()

	merged.emit()
