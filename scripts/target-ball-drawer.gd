extends Node2D

var cash_in_timer
# Called when the node enters the scene tree for the first time.
func _ready():
	cash_in_timer = get_parent().get_parent().get_node("Timer")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	queue_redraw()


func _draw():
	draw_circle(position, 50.0, get_parent().get_parent().color)
