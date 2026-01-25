extends Label

var time_remaining: float = 0.0
var is_dying: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	text = ""
	GameEvents.target_ball_dying.connect(_on_target_dying)
	GameEvents.target_ball_safe.connect(_on_target_safe)


func _on_target_dying(remaining: float):
	is_dying = true
	time_remaining = remaining
	text = "%.2f" % time_remaining


func _on_target_safe():
	is_dying = false
	text = ""
