// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-06.
function GmlScopingTestSuite() : TestSuite() constructor {

	addFact("a local named like a script function [GameMaker]", function() {
		assert_equals(case_run(case_scoping_local_shadows_script_function), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("a local named like a script function [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var case_sum3 = 5;
return case_sum3;'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("an argument named like a script function [GameMaker]", function() {
		assert_equals(case_run(case_scoping_argument_shadows_script_function), "number:7", "GameMaker no longer gives the measured result");
	});
	addFact("an argument named like a script function [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(case_sum3) { return case_sum3; };
return f(7);'); }), "number:7", "GMLC differs from GameMaker");
	});

	addFact("a static named like a script function [GameMaker]", function() {
		assert_equals(case_run(case_scoping_static_shadows_script_function), "number:9", "GameMaker no longer gives the measured result");
	});
	addFact("a static named like a script function [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function() { static case_sum3 = 9; return case_sum3; };
return f();'); }), "number:9", "GMLC differs from GameMaker");
	});

	addFact("a var written after the name is first assigned [GameMaker]", function() {
		assert_equals(case_run(case_scoping_var_after_first_use), "string:2:0", "GameMaker no longer gives the measured result");
	});
	addFact("a var written after the name is first assigned [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = {};
var f = method(s, function() {
	sc_late = 1;
	var sc_late = 2;
	return string(sc_late) + ":" + string(struct_exists(self, "sc_late"));
});
return f();'); }), "string:2:0", "GMLC differs from GameMaker");
	});

	addFact("assigning to a script function's name [GameMaker]", function() {
		assert_equals(case_run(case_scoping_assign_to_script_function), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("assigning to a script function's name [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_sum3 = 5;
return 1;'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("a function declared inside a function body [GameMaker]", function() {
		assert_equals(case_run(case_scoping_function_declared_in_function), "string:1:4", "GameMaker no longer gives the measured result");
	});
	addFact("a function declared inside a function body [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = {};
var f = method(s, function() {
	function sc_inner() { return 4; }
	return string(struct_exists(self, "sc_inner")) + ":" + string(sc_inner());
});
return f();'); }), "string:1:4", "GMLC differs from GameMaker");
	});

	addFact("a function declared inside a constructor [GameMaker]", function() {
		assert_equals(case_run(case_scoping_function_declared_in_constructor), "string:1:3", "GameMaker no longer gives the measured result");
	});
	addFact("a function declared inside a constructor [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function() constructor {
	v = 3;
	function sc_m() { return v; }
};
var c = new C();
return string(struct_exists(c, "sc_m")) + ":" + string(c.sc_m());'); }), "string:1:3", "GMLC differs from GameMaker");
	});

	addFact("a function expression inside a function body is bound to that function's self [GameMaker]", function() {
		assert_equals(case_run(case_scoping_function_expression_in_function_bound), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("a function expression inside a function body is bound to that function's self [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = {};
var f = method(s, function() {
	var g = function() {};
	return method_get_self(g) == self;
});
return f();'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("a function expression returned by a static method [GameMaker]", function() {
		assert_equals(case_run(case_scoping_function_expression_in_static_method), "string:1:0", "GameMaker no longer gives the measured result");
	});
	addFact("a function expression returned by a static method [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function() constructor {
	static mk = function() { return function() {}; };
};
var c = new C();
var g = c.mk();
return string(method_get_self(g) == c) + ":" + string(is_undefined(method_get_self(g)));'); }), "string:1:0", "GMLC differs from GameMaker");
	});

	addFact("a function expression inside a struct literal's function [GameMaker]", function() {
		assert_equals(case_run(case_scoping_function_expression_in_struct_method), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("a function expression inside a struct literal's function [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { mk: function() { return function() {}; } };
var g = s.mk();
return method_get_self(g) == s;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("reading a script function's name after assigning to it [GameMaker]", function() {
		assert_equals(case_run(case_scoping_assign_to_script_function_then_read), "string:ref", "GameMaker no longer gives the measured result");
	});
	addFact("reading a script function's name after assigning to it [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_sum3 = 5;
return typeof(case_sum3);'); }), "string:ref", "GMLC differs from GameMaker");
	});

	// assigning to a built-in function's name: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   "abs" is read-only function
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("assigning to a built-in function's name [GameMaker]", function() {
	//   abs = 5;
	//   return 1;
	// });
	addFact("assigning to a built-in function's name is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'abs = 5;
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// assigning to a built-in constant: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   Cannot set a constant ("c_red") to a value
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("assigning to a built-in constant [GameMaker]", function() {
	//   c_red = 5;
	//   return 1;
	// });
	addFact("assigning to a built-in constant is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'c_red = 5;
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});
}

function case_scoping_local_shadows_script_function() {
var case_sum3 = 5;
return case_sum3;
}

function case_scoping_argument_shadows_script_function() {
var f = function(case_sum3) { return case_sum3; };
return f(7);
}

function case_scoping_static_shadows_script_function() {
var f = function() { static case_sum3 = 9; return case_sum3; };
return f();
}

function case_scoping_var_after_first_use() {
var s = {};
var f = method(s, function() {
	sc_late = 1;
	var sc_late = 2;
	return string(sc_late) + ":" + string(struct_exists(self, "sc_late"));
});
return f();
}

function case_scoping_assign_to_script_function() {
case_sum3 = 5;
return 1;
}

function case_scoping_function_declared_in_function() {
var s = {};
var f = method(s, function() {
	function sc_inner() { return 4; }
	return string(struct_exists(self, "sc_inner")) + ":" + string(sc_inner());
});
return f();
}

function case_scoping_function_declared_in_constructor() {
var C = function() constructor {
	v = 3;
	function sc_m() { return v; }
};
var c = new C();
return string(struct_exists(c, "sc_m")) + ":" + string(c.sc_m());
}

function case_scoping_function_expression_in_function_bound() {
var s = {};
var f = method(s, function() {
	var g = function() {};
	return method_get_self(g) == self;
});
return f();
}

function case_scoping_function_expression_in_static_method() {
var C = function() constructor {
	static mk = function() { return function() {}; };
};
var c = new C();
var g = c.mk();
return string(method_get_self(g) == c) + ":" + string(is_undefined(method_get_self(g)));
}

function case_scoping_function_expression_in_struct_method() {
var s = { mk: function() { return function() {}; } };
var g = s.mk();
return method_get_self(g) == s;
}

function case_scoping_assign_to_script_function_then_read() {
case_sum3 = 5;
return typeof(case_sum3);
}
