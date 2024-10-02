
#macro RefuseTest return __RefuseTest
function __RefuseTest(_desc="Red Manually refused this test"){
	assert_true(false, _desc)
}

#macro ShouldTryCatch true

