// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-06.
function GmlJsonNumberTestSuite() : TestSuite() constructor {

	addFact("json_parse of the largest int64 [GameMaker]", function() {
		assert_equals(case_run(case_json_parse_int64_max), "string:int64:9223372036854775807", "GameMaker no longer gives the measured result");
	});
	addFact("json_parse of the largest int64 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var v = json_parse("{\"a\":9223372036854775807}").a;
return typeof(v) + ":" + string(v);'); }), "string:int64:9223372036854775807", "GMLC differs from GameMaker");
	});

	addFact("json_parse of 2^53 + 1 [GameMaker]", function() {
		assert_equals(case_run(case_json_parse_above_double), "string:int64:9007199254740993", "GameMaker no longer gives the measured result");
	});
	addFact("json_parse of 2^53 + 1 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var v = json_parse("{\"a\":9007199254740993}").a;
return typeof(v) + ":" + string(v);'); }), "string:int64:9007199254740993", "GMLC differs from GameMaker");
	});

	addFact("json_parse of a small integer [GameMaker]", function() {
		assert_equals(case_run(case_json_parse_small_integer), "string:number:12", "GameMaker no longer gives the measured result");
	});
	addFact("json_parse of a small integer [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var v = json_parse("{\"a\":12}").a;
return typeof(v) + ":" + string(v);'); }), "string:number:12", "GMLC differs from GameMaker");
	});

	addFact("json_parse of the smallest int64 [GameMaker]", function() {
		assert_equals(case_run(case_json_parse_negative_int64_min), "string:number:-9223372036854775808", "GameMaker no longer gives the measured result");
	});
	addFact("json_parse of the smallest int64 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var v = json_parse("{\"a\":-9223372036854775808}").a;
return typeof(v) + ":" + string(v);'); }), "string:number:-9223372036854775808", "GMLC differs from GameMaker");
	});

	addFact("json_stringify of an int64 above 2^53 [GameMaker]", function() {
		assert_equals(case_run(case_json_stringify_int64), "string:{\"a\":\"@i64@20000000000001$i64$\"}", "GameMaker no longer gives the measured result");
	});
	addFact("json_stringify of an int64 above 2^53 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return json_stringify({ a: int64(9007199254740993) });'); }), "string:{\"a\":\"@i64@20000000000001$i64$\"}", "GMLC differs from GameMaker");
	});

	addFact("json_stringify of a bool [GameMaker]", function() {
		assert_equals(case_run(case_json_stringify_bool), "string:{\"a\":true}", "GameMaker no longer gives the measured result");
	});
	addFact("json_stringify of a bool [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return json_stringify({ a: true });'); }), "string:{\"a\":true}", "GMLC differs from GameMaker");
	});

	addFact("json_parse of true [GameMaker]", function() {
		assert_equals(case_run(case_json_parse_bool), "string:bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("json_parse of true [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var v = json_parse("{\"a\":true}").a;
return typeof(v) + ":" + string(v);'); }), "string:bool:1", "GMLC differs from GameMaker");
	});

	addFact("json_stringify of 0.1 + 0.2 round trips [GameMaker]", function() {
		assert_equals(case_run(case_json_stringify_real_precision), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("json_stringify of 0.1 + 0.2 round trips [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var v = 0.1 + 0.2;
return json_parse(json_stringify({ a: v })).a == v;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("json_parse of -(2^53 + 1) [GameMaker]", function() {
		assert_equals(case_run(case_json_parse_negative_below_double), "string:int64:-9007199254740993", "GameMaker no longer gives the measured result");
	});
	addFact("json_parse of -(2^53 + 1) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var v = json_parse("{\"a\":-9007199254740993}").a;
return typeof(v) + ":" + string(v);'); }), "string:int64:-9007199254740993", "GMLC differs from GameMaker");
	});

	addFact("json_parse of 17 significant digits gives the same double [GameMaker]", function() {
		assert_equals(case_run(case_json_parse_real_digits_round_trip), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("json_parse of 17 significant digits gives the same double [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var v = json_parse("{\"a\":0.30000000000000004}").a;
return v == 0.1 + 0.2;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("json_parse of a 17-digit real gives a number [GameMaker]", function() {
		assert_equals(case_run(case_json_parse_real_digits_type), "string:number", "GameMaker no longer gives the measured result");
	});
	addFact("json_parse of a 17-digit real gives a number [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return typeof(json_parse("{\"a\":0.30000000000000004}").a);'); }), "string:number", "GMLC differs from GameMaker");
	});

	addFact("json_parse of -0.0 [GameMaker]", function() {
		assert_equals(case_run(case_json_parse_negative_zero), "string:number:-inf", "GameMaker no longer gives the measured result");
	});
	addFact("json_parse of -0.0 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var v = json_parse("{\"a\":-0.0}").a;
return typeof(v) + ":" + string(1 / v);'); }), "string:number:-inf", "GMLC differs from GameMaker");
	});
}

function case_json_parse_int64_max() {
var v = json_parse("{\"a\":9223372036854775807}").a;
return typeof(v) + ":" + string(v);
}

function case_json_parse_above_double() {
var v = json_parse("{\"a\":9007199254740993}").a;
return typeof(v) + ":" + string(v);
}

function case_json_parse_small_integer() {
var v = json_parse("{\"a\":12}").a;
return typeof(v) + ":" + string(v);
}

function case_json_parse_negative_int64_min() {
var v = json_parse("{\"a\":-9223372036854775808}").a;
return typeof(v) + ":" + string(v);
}

function case_json_stringify_int64() {
return json_stringify({ a: int64(9007199254740993) });
}

function case_json_stringify_bool() {
return json_stringify({ a: true });
}

function case_json_parse_bool() {
var v = json_parse("{\"a\":true}").a;
return typeof(v) + ":" + string(v);
}

function case_json_stringify_real_precision() {
var v = 0.1 + 0.2;
return json_parse(json_stringify({ a: v })).a == v;
}

function case_json_parse_negative_below_double() {
var v = json_parse("{\"a\":-9007199254740993}").a;
return typeof(v) + ":" + string(v);
}

function case_json_parse_real_digits_round_trip() {
var v = json_parse("{\"a\":0.30000000000000004}").a;
return v == 0.1 + 0.2;
}

function case_json_parse_real_digits_type() {
return typeof(json_parse("{\"a\":0.30000000000000004}").a);
}

function case_json_parse_negative_zero() {
var v = json_parse("{\"a\":-0.0}").a;
return typeof(v) + ":" + string(1 / v);
}
