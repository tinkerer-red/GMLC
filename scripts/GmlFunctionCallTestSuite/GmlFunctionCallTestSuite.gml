// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-05.
function GmlFunctionCallTestSuite() : TestSuite() constructor {

	addFact("script_execute of a built-in with one argument [GameMaker]", function() {
		assert_equals(case_run(case_function_calls_script_execute_builtin), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("script_execute of a built-in with one argument [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return script_execute(sqrt, 9);'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("script_execute passes its arguments in order [GameMaker]", function() {
		assert_equals(case_run(case_function_calls_script_execute_args_order), "string:abc", "GameMaker no longer gives the measured result");
	});
	addFact("script_execute passes its arguments in order [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return script_execute(string_concat, "a", "b", "c");'); }), "string:abc", "GMLC differs from GameMaker");
	});

	addFact("script_execute of a function with two arguments [GameMaker]", function() {
		assert_equals(case_run(case_function_calls_script_execute_function), "number:12", "GameMaker no longer gives the measured result");
	});
	addFact("script_execute of a function with two arguments [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(_a, _b) { return _a * 10 + _b; };
return script_execute(f, 1, 2);'); }), "number:12", "GMLC differs from GameMaker");
	});

	addFact("script_execute with no arguments [GameMaker]", function() {
		assert_equals(case_run(case_function_calls_script_execute_no_args), "number:0", "GameMaker no longer gives the measured result");
	});
	addFact("script_execute with no arguments [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function() { return argument_count; };
return script_execute(f);'); }), "number:0", "GMLC differs from GameMaker");
	});

	addFact("script_execute_ext with an offset and a count [GameMaker]", function() {
		assert_equals(case_run(case_function_calls_script_execute_ext_offset), "string:bc", "GameMaker no longer gives the measured result");
	});
	addFact("script_execute_ext with an offset and a count [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return script_execute_ext(string_concat, ["a", "b", "c", "d"], 1, 2);'); }), "string:bc", "GMLC differs from GameMaker");
	});
}

function case_function_calls_script_execute_builtin() {
return script_execute(sqrt, 9);
}

function case_function_calls_script_execute_args_order() {
return script_execute(string_concat, "a", "b", "c");
}

function case_function_calls_script_execute_function() {
var f = function(_a, _b) { return _a * 10 + _b; };
return script_execute(f, 1, 2);
}

function case_function_calls_script_execute_no_args() {
var f = function() { return argument_count; };
return script_execute(f);
}

function case_function_calls_script_execute_ext_offset() {
return script_execute_ext(string_concat, ["a", "b", "c", "d"], 1, 2);
}
