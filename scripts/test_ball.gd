extends GutTest

var ball_group = load('res://scripts/ball.gd')
var _ball = null

func before_all():
	_ball = ball_group.new()

func after_all():
	_ball.queue_free()

func test_ball_assigned():
	var example_ball = ball_group.new()
	assert_eq(typeof(_ball), typeof(example_ball))
	example_ball.queue_free()
