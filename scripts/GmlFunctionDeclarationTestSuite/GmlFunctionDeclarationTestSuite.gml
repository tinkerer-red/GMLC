// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-06.
function GmlFunctionDeclarationTestSuite() : TestSuite() constructor {

	addFact("a function declared in a constructor is a variable of the new struct, not a static [GameMaker]", function() {
		assert_equals(case_run(case_function_declarations_constructor_function_is_instance_variable), "string:1:0:1", "GameMaker no longer gives the measured result");
	});
	addFact("a function declared in a constructor is a variable of the new struct, not a static [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'function GmlFdA() constructor { function step() { return 1; } }
var a = new GmlFdA();
return string(struct_exists(a, "step")) + ":" + string(struct_exists(static_get(a), "step")) + ":" + string(a.step());'); }), "string:1:0:1", "GMLC differs from GameMaker");
	});

	addFact("the name of a function declared in a constructor starts with gml_Script_name@Constructor@ [GameMaker]", function() {
		assert_equals(case_run(case_function_declarations_constructor_function_name), "string:gml_Script_step@GmlFdB@", "GameMaker no longer gives the measured result");
	});
	addFact("the name of a function declared in a constructor starts with gml_Script_name@Constructor@ [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'function GmlFdB() constructor { function step() { return _GMFUNCTION_; } }
var b = new GmlFdB();
return string_copy(b.step(), 1, 23);'); }), "string:gml_Script_step@GmlFdB@", "GMLC differs from GameMaker");
	});

	addFact("two constructors each keep their own function of the same name [GameMaker]", function() {
		assert_equals(case_run(case_function_declarations_constructor_function_two_constructors), "string:cd", "GameMaker no longer gives the measured result");
	});
	addFact("two constructors each keep their own function of the same name [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'function GmlFdC() constructor { function step() { return "c"; } }
function GmlFdD() constructor { function step() { return "d"; } }
var c = new GmlFdC();
var d = new GmlFdD();
return c.step() + d.step();'); }), "string:cd", "GMLC differs from GameMaker");
	});

	addFact("a function declared in a constructor is not a global variable [GameMaker]", function() {
		assert_equals(case_run(case_function_declarations_constructor_function_not_global), "bool:0", "GameMaker no longer gives the measured result");
	});
	addFact("a function declared in a constructor is not a global variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'function GmlFdE() constructor { function gml_fd_step_e() { return 1; } }
var e = new GmlFdE();
return variable_global_exists("gml_fd_step_e");'); }), "bool:0", "GMLC differs from GameMaker");
	});

	addFact("a function declared inside a function can be called there [GameMaker]", function() {
		assert_equals(case_run(case_function_declarations_function_in_function), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("a function declared inside a function can be called there [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'function gml_fd_outer() { function gml_fd_inner() { return 2; } return gml_fd_inner(); }
return gml_fd_outer();'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("a function declared inside a function becomes a variable of the caller's self [GameMaker]", function() {
		assert_equals(case_run(case_function_declarations_function_in_function_goes_to_self), "string:1", "GameMaker no longer gives the measured result");
	});
	addFact("a function declared inside a function becomes a variable of the caller's self [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'function gml_fd_outer2() { function gml_fd_inner2() { return 3; } }
var holder = {};
with (holder) { gml_fd_outer2(); }
return string(struct_exists(holder, "gml_fd_inner2"));'); }), "string:1", "GMLC differs from GameMaker");
	});
}

function case_function_declarations_constructor_function_is_instance_variable() {
function GmlFdA() constructor { function step() { return 1; } }
var a = new GmlFdA();
return string(struct_exists(a, "step")) + ":" + string(struct_exists(static_get(a), "step")) + ":" + string(a.step());
}

function case_function_declarations_constructor_function_name() {
function GmlFdB() constructor { function step() { return _GMFUNCTION_; } }
var b = new GmlFdB();
return string_copy(b.step(), 1, 23);
}

function case_function_declarations_constructor_function_two_constructors() {
function GmlFdC() constructor { function step() { return "c"; } }
function GmlFdD() constructor { function step() { return "d"; } }
var c = new GmlFdC();
var d = new GmlFdD();
return c.step() + d.step();
}

function case_function_declarations_constructor_function_not_global() {
function GmlFdE() constructor { function gml_fd_step_e() { return 1; } }
var e = new GmlFdE();
return variable_global_exists("gml_fd_step_e");
}

function case_function_declarations_function_in_function() {
function gml_fd_outer() { function gml_fd_inner() { return 2; } return gml_fd_inner(); }
return gml_fd_outer();
}

function case_function_declarations_function_in_function_goes_to_self() {
function gml_fd_outer2() { function gml_fd_inner2() { return 3; } }
var holder = {};
with (holder) { gml_fd_outer2(); }
return string(struct_exists(holder, "gml_fd_inner2"));
}
