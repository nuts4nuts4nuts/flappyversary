extends ColorRect

var initial_position = position
var initial_color = color
var tween
var color_tween
var activated = false
var activated_cashing_in = false
var is_dying = false
var is_cashing_in = false
@export var color2 : Color

# Called when the node enters the scene tree for the first time.
func _ready():
	GameEvents.target_ball_dying.connect(_on_target_dying)
	GameEvents.target_ball_safe.connect(_on_target_safe)
	GameEvents.cluster_cashing_in.connect(_on_cashing_in)
	GameEvents.cluster_merged.connect(_on_cashed_in)
	GameEvents.game_restarting.connect(_on_game_restarting)


func _on_target_dying(_time_remaining: float):
	is_dying = true
	if !activated:
		activate()


func _on_target_safe():
	is_dying = false
	if activated and !is_cashing_in:
		return_to_normal()


func _on_cashing_in(_cluster_id: int, _value: int, _ball_count: int, _time: float):
	is_cashing_in = true
	if !activated_cashing_in:
		activate_cashing_in()


func _on_cashed_in(_new_value: int, _position: Vector2):
	is_cashing_in = false
	if activated_cashing_in:
		return_to_normal()

func flash_color_to():
	color_tween = create_tween()
	color_tween.tween_property(self, "color", color2, 0.6)
	#color_tween.tween_callback(flash_color_back()).set_delay(0.6)
	await color_tween.finished
	flash_color_back()

func flash_color_back():
	var color_tween2 = create_tween()
	color_tween2.tween_property(self, "color", initial_color, 0.6)
	#color_tween2.tween_callback(flash_color_to()).set_delay(0.6)
	await color_tween2.finished
	flash_color_to()

func activate():
	activated = true
	$background_danger_text.text = "危
險
危
險
危
險
危
險
危
險
危
險
危
險
"
	$AnimationPlayerMove.play("entry")
	$AnimationPlayerColor.play("flash")
	$AnimationPlayerText.play("scroll")
	print("UI active")
	#if(tween):
	#	tween.kill()
	#tween = create_tween()
	#tween.tween_property(self, "position", Vector2(-177, -2589), 0.6)
	#tween.tween_property(self, "position", Vector2(-177, -7930), 10)
	
	

func activate_cashing_in():
	activated_cashing_in = true
	$background_danger_text.text = "融
合
融
合
融
合
融
合
融
合
融
合
融
合
"
	$AnimationPlayerMove.play("entry")
	$AnimationPlayerColor.play("flash_combine")
	$AnimationPlayerText.play("scroll_to_loop_start")

func return_to_normal():
	$AnimationPlayerMove.play_backwards("entry")
	$AnimationPlayerText.play_backwards("scroll_loop")
	activated = false
	activated_cashing_in = false


func _on_game_restarting():
	# Reset all state and hide immediately
	is_dying = false
	is_cashing_in = false
	activated = false
	activated_cashing_in = false
	$AnimationPlayerMove.stop()
	$AnimationPlayerColor.stop()
	$AnimationPlayerText.stop()
	position = initial_position
	color = initial_color



func _on_animation_player_move_animation_finished(anim_name):
	if(anim_name == "scroll_to_loop_start"):
		print("scrolled to loop start")
		$AnimationPlayerText.play("scroll_loop")
	pass
