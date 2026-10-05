// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-04.
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
