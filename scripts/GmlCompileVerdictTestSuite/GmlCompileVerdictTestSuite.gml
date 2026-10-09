// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-06.
function GmlCompileVerdictTestSuite() : TestSuite() constructor {

	// a parameter name used twice: GameMaker 2024.14.4.268 refuses to compile this:
	//   argument name a already used in function declaration
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("a parameter name used twice [GameMaker]", function() {
	//   var f = function(a, a) { return a; };
	//   return f(1, 2);
	// });
	addFact("a parameter name used twice is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(a, a) { return a; };
return f(1, 2);'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// assigning to pi: GameMaker 2024.14.4.268 refuses to compile this:
	//   Cannot set a constant ("pi") to a value
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("assigning to pi [GameMaker]", function() {
	//   pi = 3;
	//   return 1;
	// });
	addFact("assigning to pi is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'pi = 3;
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// assigning to noone: GameMaker 2024.14.4.268 refuses to compile this:
	//   Cannot set a constant ("noone") to a value
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("assigning to noone [GameMaker]", function() {
	//   noone = 0;
	//   return 1;
	// });
	addFact("assigning to noone is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'noone = 0;
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("assigning to id [GameMaker]", function() {
		assert_equals(case_run(case_compile_verdicts_assign_id), "error", "GameMaker no longer gives the measured result");
	});
	addFact("assigning to id [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'id = 3;
return 1;'); }), "error", "GMLC differs from GameMaker");
	});

	// assigning to instance_count: GameMaker 2024.14.4.268 refuses to compile this:
	//   "instance_count" is read-only
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("assigning to instance_count [GameMaker]", function() {
	//   instance_count = 0;
	//   return 1;
	// });
	addFact("assigning to instance_count is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'instance_count = 0;
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// assigning to _GMLINE_: GameMaker 2024.14.4.268 refuses to compile this:
	//   Cannot set a constant ("_GMLINE_") to a value
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("assigning to _GMLINE_ [GameMaker]", function() {
	//   _GMLINE_ = 1;
	//   return 1;
	// });
	addFact("assigning to _GMLINE_ is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'_GMLINE_ = 1;
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// writing through an index of _GMFILE_: GameMaker 2024.14.4.268 refuses to compile this:
	//   Assignment operator expected
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("writing through an index of _GMFILE_ [GameMaker]", function() {
	//   _GMFILE_[0] = 1;
	//   return 1;
	// });
	addFact("writing through an index of _GMFILE_ is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'_GMFILE_[0] = 1;
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// a built-in called with too few arguments: GameMaker 2024.14.4.268 refuses to compile this:
	//   wrong number of arguments for function string_length
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("a built-in called with too few arguments [GameMaker]", function() {
	//   return string_length();
	// });
	addFact("a built-in called with too few arguments is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string_length();'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// a built-in called with too many arguments: GameMaker 2024.14.4.268 refuses to compile this:
	//   wrong number of arguments for function string_length
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("a built-in called with too many arguments [GameMaker]", function() {
	//   return string_length("a", "b");
	// });
	addFact("a built-in called with too many arguments is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string_length("a", "b");'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("new on a built-in function [GameMaker]", function() {
		assert_equals(case_run(case_compile_verdicts_new_builtin_function), "error", "GameMaker no longer gives the measured result");
	});
	addFact("new on a built-in function [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = new show_debug_message("x");
return 1;'); }), "error", "GMLC differs from GameMaker");
	});

	// a var named like a built-in function: GameMaker 2024.14.4.268 refuses to compile this:
	//   cannot use function / script name for a variable, using "sprite_get_width"
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("a var named like a built-in function [GameMaker]", function() {
	//   var sprite_get_width = 1;
	//   return sprite_get_width;
	// });
	addFact("a var named like a built-in function is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var sprite_get_width = 1;
return sprite_get_width;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("the same var declared twice in one function [GameMaker]", function() {
		assert_equals(case_run(case_compile_verdicts_var_declared_twice), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("the same var declared twice in one function [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 1;
var a = 2;
return a;'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("a static initialised from a local of the same function [GameMaker]", function() {
		assert_equals(case_run(case_compile_verdicts_static_reads_local), "error", "GameMaker no longer gives the measured result");
	});
	addFact("a static initialised from a local of the same function [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function() { var t = 5; static s = t; return s; };
return f();'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("a parameter with a default before one without [GameMaker]", function() {
		assert_equals(case_run(case_compile_verdicts_optional_before_required), "string:1:2", "GameMaker no longer gives the measured result");
	});
	addFact("a parameter with a default before one without [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(a = 1, b) { return string(a) + ":" + string(b); };
return f(undefined, 2);'); }), "string:1:2", "GMLC differs from GameMaker");
	});

	addFact("argument0 in a function with named parameters [GameMaker]", function() {
		assert_equals(case_run(case_compile_verdicts_argument_with_named_parameters), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("argument0 in a function with named parameters [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(a) { return argument0 + a; };
return f(1);'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("a function reads a local of the function around it [GameMaker]", function() {
		assert_equals(case_run(case_compile_verdicts_nested_function_reads_enclosing_local), "error", "GameMaker no longer gives the measured result");
	});
	addFact("a function reads a local of the function around it [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var k = 3;
var f = function() { return k; };
return f();'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("a constructor called without new [GameMaker]", function() {
		assert_equals(case_run(case_compile_verdicts_constructor_called_without_new), "error", "GameMaker no longer gives the measured result");
	});
	addFact("a constructor called without new [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function() constructor { v = 1; };
var c = C();
return 1;'); }), "error", "GMLC differs from GameMaker");
	});

	// an argument to a built-in that takes none: GameMaker 2024.14.4.268 refuses to compile this:
	//   wrong number of arguments for function video_get_duration
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("an argument to a built-in that takes none [GameMaker]", function() {
	//   var v = 0;
	//   return video_get_duration(v);
	// });
	addFact("an argument to a built-in that takes none is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var v = 0;
return video_get_duration(v);'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// a var named like a built-in variable: GameMaker 2024.14.4.268 refuses to compile this:
	//   cannot redeclare a builtin variable
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a var named like a built-in variable [GameMaker]", function() {
	//   var x = 1;
	//   return x;
	// });

	// assigning to a built-in function: GameMaker 2024.14.4.268 refuses to compile this:
	//   "abs" is read-only function
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("assigning to a built-in function [GameMaker]", function() {
	//   abs = 2;
	//   return 1;
	// });
	addFact("assigning to a built-in function is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'abs = 2;
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// incrementing a built-in constant: GameMaker 2024.14.4.268 refuses to compile this:
	//   malformed assignment
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("incrementing a built-in constant [GameMaker]", function() {
	//   pi++;
	//   return 1;
	// });
	addFact("incrementing a built-in constant is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'pi++;
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("incrementing a built-in function [GameMaker]", function() {
		assert_equals(case_run(case_compile_verdicts_increment_builtin_function), "error", "GameMaker no longer gives the measured result");
	});
	addFact("incrementing a built-in function [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'abs++;
return 1;'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("argument[] in a function with named parameters [GameMaker]", function() {
		assert_equals(case_run(case_compile_verdicts_argument_array_named_params), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("argument[] in a function with named parameters [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(a) { return argument[0] + argument_count; };
return f(4);'); }), "number:5", "GMLC differs from GameMaker");
	});
}

function case_compile_verdicts_assign_id() {
id = 3;
return 1;
}

function case_compile_verdicts_new_builtin_function() {
var s = new show_debug_message("x");
return 1;
}

function case_compile_verdicts_var_declared_twice() {
var a = 1;
var a = 2;
return a;
}

function case_compile_verdicts_static_reads_local() {
var f = function() { var t = 5; static s = t; return s; };
return f();
}

function case_compile_verdicts_optional_before_required() {
var f = function(a = 1, b) { return string(a) + ":" + string(b); };
return f(undefined, 2);
}

function case_compile_verdicts_argument_with_named_parameters() {
var f = function(a) { return argument0 + a; };
return f(1);
}

function case_compile_verdicts_nested_function_reads_enclosing_local() {
var k = 3;
var f = function() { return k; };
return f();
}

function case_compile_verdicts_constructor_called_without_new() {
var C = function() constructor { v = 1; };
var c = C();
return 1;
}

function case_compile_verdicts_increment_builtin_function() {
abs++;
return 1;
}

function case_compile_verdicts_argument_array_named_params() {
var f = function(a) { return argument[0] + argument_count; };
return f(4);
}
