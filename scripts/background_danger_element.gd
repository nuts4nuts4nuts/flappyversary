extends ColorRect

var initial_position = position
var initial_color = color
var tween
var color_tween
var target_ball
var activated
var activated_cashing_in
@export var color2 : Color

# Called when the node enters the scene tree for the first time.
func _ready():
	activated = false
	target_ball = get_parent().get_node("target_ball")
	#tween = create_tween()
	#tween.tween_property(self, "position", Vector2(-177, -2589), 0.6)
	#tween.tween_property(self, "position", Vector2(-177, -7930), 10)
	#flash_color_to()
	
	
	#tween.tween_property(self, "position", Vector2(-177, -2591), 0.6)
	#tween.tween_property(self, "position", initial_position, 0.6)
	#tween.tween_property(self, "position", Vector2(-177, -7591), 10)
	#activate()

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
"
	$AnimationPlayerMove.play("entry")
	$AnimationPlayerColor.play("flash_combine")
	$AnimationPlayerText.play("scroll_to_loop_start")

func return_to_normal():
	#if(tween):
	#	tween.kill()
	#tween = create_tween()
	#tween.tween_property(self, "position:x", initial_position.x, 0.6)
	$AnimationPlayerMove.play_backwards("entry")
	$AnimationPlayerText.play_backwards("scroll_loop")
	activated = false
	activated_cashing_in = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(target_ball != null):
		update_value()
		#pass

func update_value():
	if(!activated and target_ball.check_dying()):
		activate()
		#pass
	elif(activated and !target_ball.check_dying()):
		return_to_normal()
	
	if(!activated_cashing_in and target_ball.cashing_in):
		activate_cashing_in()
	elif(activated_cashing_in and !target_ball.cashing_in):
		return_to_normal()


func _on_animation_player_move_animation_finished(anim_name):
	if(anim_name == "scroll_to_loop_start"):
		print("scrolled to loop start")
		$AnimationPlayerText.play("scroll_loop")
	pass
