extends Label

var is_cashing_in: bool = false
var cash_in_start_time: float = 0.0
var cash_in_wait_time: float = 0.0


func _ready():
	text = ""
	GameEvents.target_ball_cashing_in.connect(_on_cashing_in)
	GameEvents.target_ball_cashed_in.connect(_on_cashed_in)


func _on_cashing_in(wait_time: float):
	is_cashing_in = true
	cash_in_wait_time = wait_time
	cash_in_start_time = Time.get_ticks_msec() / 1000.0


func _on_cashed_in():
	is_cashing_in = false
	text = ""


func _process(_delta):
	if is_cashing_in:
		var elapsed = (Time.get_ticks_msec() / 1000.0) - cash_in_start_time
		var remaining = max(0, cash_in_wait_time - elapsed)
		text = "%.2f" % remaining
