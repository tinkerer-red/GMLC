// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-06.
function GmlExceptionTestSuite() : TestSuite() constructor {

	addFact("try/finally without catch passes the error on after finally [GameMaker]", function() {
		assert_equals(case_run(case_exceptions_finally_without_catch), "string:cleanup,caught boom", "GameMaker no longer gives the measured result");
	});
	addFact("try/finally without catch passes the error on after finally [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var _log = "";
try {
	try { throw "boom"; }
	finally { _log += "cleanup,"; }
	_log += "after,";
}
catch (e) { _log += "caught " + string(e); }
return _log;'); }), "string:cleanup,caught boom", "GMLC differs from GameMaker");
	});

	addFact("finally runs when the catch block throws [GameMaker]", function() {
		assert_equals(case_run(case_exceptions_catch_that_throws), "string:caught second", "GameMaker no longer gives the measured result");
	});
	addFact("finally runs when the catch block throws [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var _log = "";
try {
	try { throw "first"; }
	catch (e) { throw "second"; }
	finally { _log += "cleanup,"; }
}
catch (e) { _log += "caught " + string(e); }
return _log;'); }), "string:caught second", "GMLC differs from GameMaker");
	});

	addFact("finally runs after a catch that handles the error [GameMaker]", function() {
		assert_equals(case_run(case_exceptions_finally_after_catch), "string:caught,cleanup,after", "GameMaker no longer gives the measured result");
	});
	addFact("finally runs after a catch that handles the error [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var _log = "";
try { throw "x"; }
catch (e) { _log += "caught,"; }
finally { _log += "cleanup,"; }
_log += "after";
return _log;'); }), "string:caught,cleanup,after", "GMLC differs from GameMaker");
	});

	addFact("a catch outside a with runs on the original self [GameMaker]", function() {
		assert_equals(case_run(case_exceptions_throw_inside_with_restores_self), "string:2:0", "GameMaker no longer gives the measured result");
	});
	addFact("a catch outside a with runs on the original self [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { yv: 0 };
var o = { yv: 0 };
with (s) {
	try { with (o) { throw 1; } }
	catch (e) { yv = 2; }
}
return string(s.yv) + ":" + string(o.yv);'); }), "string:2:0", "GMLC differs from GameMaker");
	});

	addFact("a recursive function that threw still works afterwards [GameMaker]", function() {
		assert_equals(case_run(case_exceptions_throw_out_of_recursion_then_call_again), "number:63", "GameMaker no longer gives the measured result");
	});
	addFact("a recursive function that threw still works afterwards [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'global.sc_g = function(n, deep) {
	if (n == 0) { if (deep) { throw "bottom"; } return 0; }
	return 1 + global.sc_g(n - 1, deep);
};
var r = 0;
repeat (3) { try { global.sc_g(4, true); } catch (e) { r += 1; } }
repeat (20) { r += global.sc_g(3, false); }
return r;'); }), "number:63", "GMLC differs from GameMaker");
	});

	addFact("arguments are right after a call that threw [GameMaker]", function() {
		assert_equals(case_run(case_exceptions_throw_out_of_function_keeps_arguments), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("arguments are right after a call that threw [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var h = function(a, b) {
	if (a == 0) { throw "zero"; }
	return a + b;
};
try { h(0, 5); } catch (e) {}
return h(2, 3);'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("a finally outside a with runs on the original self [GameMaker]", function() {
		assert_equals(case_run(case_exceptions_finally_after_with_runs_on_original_self), "string:3:0", "GameMaker no longer gives the measured result");
	});
	addFact("a finally outside a with runs on the original self [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { yv: 0 };
var o = { yv: 0 };
with (s) {
	try {
		try { with (o) { throw 1; } }
		finally { yv = 3; }
	}
	catch (e) {}
}
return string(s.yv) + ":" + string(o.yv);'); }), "string:3:0", "GMLC differs from GameMaker");
	});

	addFact("a recursive function that catches its own inner error keeps its locals [GameMaker]", function() {
		assert_equals(case_run(case_exceptions_catch_inside_recursion_keeps_locals), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("a recursive function that catches its own inner error keeps its locals [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'global.sc_k = function(n) {
	var mine = n;
	if (n == 0) { throw "bottom"; }
	try { global.sc_k(n - 1); } catch (e) {}
	return mine;
};
return global.sc_k(3);'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("a constructor that threw still works afterwards [GameMaker]", function() {
		assert_equals(case_run(case_exceptions_throw_out_of_constructor_then_new_again), "string:3:4", "GameMaker no longer gives the measured result");
	});
	addFact("a constructor that threw still works afterwards [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'global.ScThrows = function(n) constructor {
	v = n;
	if (n < 0) { throw "negative"; }
};
var r = 0;
repeat (3) { try { new global.ScThrows(-1); } catch (e) { r += 1; } }
var c = new global.ScThrows(4);
return string(r) + ":" + string(c.v);'); }), "string:3:4", "GMLC differs from GameMaker");
	});
}

function case_exceptions_finally_without_catch() {
var _log = "";
try {
	try { throw "boom"; }
	finally { _log += "cleanup,"; }
	_log += "after,";
}
catch (e) { _log += "caught " + string(e); }
return _log;
}

function case_exceptions_catch_that_throws() {
var _log = "";
try {
	try { throw "first"; }
	catch (e) { throw "second"; }
	finally { _log += "cleanup,"; }
}
catch (e) { _log += "caught " + string(e); }
return _log;
}

function case_exceptions_finally_after_catch() {
var _log = "";
try { throw "x"; }
catch (e) { _log += "caught,"; }
finally { _log += "cleanup,"; }
_log += "after";
return _log;
}

function case_exceptions_throw_inside_with_restores_self() {
var s = { yv: 0 };
var o = { yv: 0 };
with (s) {
	try { with (o) { throw 1; } }
	catch (e) { yv = 2; }
}
return string(s.yv) + ":" + string(o.yv);
}

function case_exceptions_throw_out_of_recursion_then_call_again() {
global.sc_g = function(n, deep) {
	if (n == 0) { if (deep) { throw "bottom"; } return 0; }
	return 1 + global.sc_g(n - 1, deep);
};
var r = 0;
repeat (3) { try { global.sc_g(4, true); } catch (e) { r += 1; } }
repeat (20) { r += global.sc_g(3, false); }
return r;
}

function case_exceptions_throw_out_of_function_keeps_arguments() {
var h = function(a, b) {
	if (a == 0) { throw "zero"; }
	return a + b;
};
try { h(0, 5); } catch (e) {}
return h(2, 3);
}

function case_exceptions_finally_after_with_runs_on_original_self() {
var s = { yv: 0 };
var o = { yv: 0 };
with (s) {
	try {
		try { with (o) { throw 1; } }
		finally { yv = 3; }
	}
	catch (e) {}
}
return string(s.yv) + ":" + string(o.yv);
}

function case_exceptions_catch_inside_recursion_keeps_locals() {
global.sc_k = function(n) {
	var mine = n;
	if (n == 0) { throw "bottom"; }
	try { global.sc_k(n - 1); } catch (e) {}
	return mine;
};
return global.sc_k(3);
}

function case_exceptions_throw_out_of_constructor_then_new_again() {
global.ScThrows = function(n) constructor {
	v = n;
	if (n < 0) { throw "negative"; }
};
var r = 0;
repeat (3) { try { new global.ScThrows(-1); } catch (e) { r += 1; } }
var c = new global.ScThrows(4);
return string(r) + ":" + string(c.v);
}
