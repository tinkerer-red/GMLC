// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-07.
function GmlNegateBoolTestSuite() : TestSuite() constructor {

	addFact("(-x) + 0 with x = true [GameMaker]", function() {
		assert_equals(case_run(case_negate_bool_neg_true_plus_zero), "string:number:BFF0000000000000", "GameMaker no longer gives the measured result");
	});
	addFact("(-x) + 0 with x = true [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(_x) { return -_x; };
return case_exact(f(true) + 0);'); }), "string:number:BFF0000000000000", "GMLC differs from GameMaker");
	});

	addFact("(-x) == -1 with x = true [GameMaker]", function() {
		assert_equals(case_run(case_negate_bool_neg_true_equals_minus_one), "string:1:0:0", "GameMaker no longer gives the measured result");
	});
	addFact("(-x) == -1 with x = true [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(_x) { return -_x; };
return string(f(true) == -1) + ":" + string(f(true) == 1) + ":" + string(f(true) == true);'); }), "string:1:0:0", "GMLC differs from GameMaker");
	});

	addFact("-x with x = false [GameMaker]", function() {
		assert_equals(case_run(case_negate_bool_neg_false), "string:bool:0", "GameMaker no longer gives the measured result");
	});
	addFact("-x with x = false [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(_x) { return -_x; };
return case_exact(f(false));'); }), "string:bool:0", "GMLC differs from GameMaker");
	});

	addFact("real(-x) with x = true [GameMaker]", function() {
		assert_equals(case_run(case_negate_bool_neg_true_real), "string:number:BFF0000000000000", "GameMaker no longer gives the measured result");
	});
	addFact("real(-x) with x = true [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(_x) { return -_x; };
return case_exact(real(f(true)));'); }), "string:number:BFF0000000000000", "GMLC differs from GameMaker");
	});

	addFact("(-x) * 1 with x = true [GameMaker]", function() {
		assert_equals(case_run(case_negate_bool_neg_true_times_one), "string:number:BFF0000000000000", "GameMaker no longer gives the measured result");
	});
	addFact("(-x) * 1 with x = true [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(_x) { return -_x; };
return case_exact(f(true) * 1);'); }), "string:number:BFF0000000000000", "GMLC differs from GameMaker");
	});

	addFact("0 - x with x = true [GameMaker]", function() {
		assert_equals(case_run(case_negate_bool_zero_minus_true), "string:number:BFF0000000000000", "GameMaker no longer gives the measured result");
	});
	addFact("0 - x with x = true [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(_x) { return 0 - _x; };
return case_exact(f(true));'); }), "string:number:BFF0000000000000", "GMLC differs from GameMaker");
	});

	addFact("x * -1 with x = true [GameMaker]", function() {
		assert_equals(case_run(case_negate_bool_true_times_minus_one), "string:number:BFF0000000000000", "GameMaker no longer gives the measured result");
	});
	addFact("x * -1 with x = true [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(_x) { return _x * -1; };
return case_exact(f(true));'); }), "string:number:BFF0000000000000", "GMLC differs from GameMaker");
	});
}

function case_negate_bool_neg_true_plus_zero() {
var f = function(_x) { return -_x; };
return case_exact(f(true) + 0);
}

function case_negate_bool_neg_true_equals_minus_one() {
var f = function(_x) { return -_x; };
return string(f(true) == -1) + ":" + string(f(true) == 1) + ":" + string(f(true) == true);
}

function case_negate_bool_neg_false() {
var f = function(_x) { return -_x; };
return case_exact(f(false));
}

function case_negate_bool_neg_true_real() {
var f = function(_x) { return -_x; };
return case_exact(real(f(true)));
}

function case_negate_bool_neg_true_times_one() {
var f = function(_x) { return -_x; };
return case_exact(f(true) * 1);
}

function case_negate_bool_zero_minus_true() {
var f = function(_x) { return 0 - _x; };
return case_exact(f(true));
}

function case_negate_bool_true_times_minus_one() {
var f = function(_x) { return _x * -1; };
return case_exact(f(true));
}
