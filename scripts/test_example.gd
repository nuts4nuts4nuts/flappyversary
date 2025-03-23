extends GutTest

func before_all():
	gut.p("Runs once before all tests")

func test_passes():
	assert_eq(1, 1)

# func test_fails():
# 	assert_eq(1, 2)
