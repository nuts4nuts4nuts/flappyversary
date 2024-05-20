extends GPUParticles2D

var particle_pos: Vector2
var last_pos: Vector2
var mat: ParticleProcessMaterial

func _ready():
	last_pos = global_position
	mat = process_material

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if last_pos != global_position:
		particle_pos = last_pos
	
	var current_to_last = particle_pos - global_position
	var direction = current_to_last.normalized()
	var speed = current_to_last.length_squared()
	
	var speed_normalized = speed / 100
	mat.scale_min = speed_normalized
	mat.scale_max = speed_normalized
	mat.color.a = speed_normalized
	mat.direction = Vector3(direction.x, direction.y, 0)

	last_pos = global_position
