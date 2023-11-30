extends RigidBody2D

signal merged

@export var initial_impulse: Vector2
@export var gravity_well: Node2D
@export var color: Color

var is_target = false
var merge_boost = 0.2
var ball_value = 1
var base_force = 200

func _ready():
	apply_central_impulse(initial_impulse)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _physics_process(delta):
	if(gravity_well != null):
		var me_to_well = gravity_well.global_position - global_position
		var distance = me_to_well.length()
		#print(distance)
		if(! distance > 250):
			
			
			var direction = me_to_well.normalized()

			var force = base_force * direction
			var falloff = 1 / max(1, (distance / 10000))
			apply_force(force * falloff, Vector2.ZERO)


func _on_body_entered(body):
	var my_velocity = linear_velocity
	var their_velocity = body.linear_velocity
	
	if !body.is_target && name < body.name:
		call_deferred("steal_children", body)


func steal_children(other):
	print(name + " stealing")
	ball_value += other.ball_value
	var children = other.get_children()
	for child in children:
		print(child.name)
		if "Visuals" in child.name:
			merged.connect(child.get_node("Value")._on_ball_merged)
		child.reparent(self)
	other.queue_free()
	merged.emit()
