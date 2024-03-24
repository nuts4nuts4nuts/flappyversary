extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. '`delta' is the elapsed time since the previous frame.
func _process(_delta):
	queue_redraw()


func _draw():
	draw_circle(position, 64.0, get_parent().get_parent().color)
