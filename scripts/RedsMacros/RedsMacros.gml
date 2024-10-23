window_set_size(256, 256)
window_set_position(display_get_width()/2-128, display_get_height()/2-128)

#macro RefuseTest return __RefuseTest
function __RefuseTest(_desc="Red Manually refused this test"){
	assert_true(false, _desc)
}

#macro ShouldTryCatch false

