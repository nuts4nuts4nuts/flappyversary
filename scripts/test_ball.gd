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

func test_steal_children():
	var example_ball = ball_group.new()
	var ball_value = _ball.ball_value
	var other_ball_value = example_ball.ball_value
	var other_children = example_ball.get_children()

	_ball.steal_children(example_ball)
	assert_eq(_ball.ball_value, ball_value + other_ball_value)

	# TODO: this doesn't work right now because we aren't spawning reall ball groups - just the scripts
	# not worth spending this time on but read up and return
	#print(len(_ball.get_children()))
	#print(len(other_children))
	#for child in other_children:
		#assert_has(_ball.get_children(), child)
