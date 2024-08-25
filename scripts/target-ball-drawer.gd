extends Node2D

var color_alpha: float = 1.0

var cash_in_timer
# Called when the node enters the scene tree for the first time.
func _ready():
	cash_in_timer = get_parent().get_parent().get_node("Timer")
	pass # Replace with function body.


# Called every frame. '_delta' is the elapsed time since the previous frame.
func _process(_delta):
	queue_redraw()


func _draw():
	var color = Color(get_parent().get_parent().color)
	color.a = color_alpha
	draw_circle(position, 100.0, color)
