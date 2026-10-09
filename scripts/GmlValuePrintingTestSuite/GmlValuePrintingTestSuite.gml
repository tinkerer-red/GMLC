// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-07.
function GmlValuePrintingTestSuite() : TestSuite() constructor {

	addFact("string(10^21) [GameMaker]", function() {
		assert_equals(case_run(case_value_printing_string_1e21), "string:1000000000000000000000.00", "GameMaker no longer gives the measured result");
	});
	addFact("string(10^21) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string(power(10, 21));'); }), "string:1000000000000000000000.00", "GMLC differs from GameMaker");
	});

	addFact("string(0.1) [GameMaker]", function() {
		assert_equals(case_run(case_value_printing_string_tenth), "string:0.10", "GameMaker no longer gives the measured result");
	});
	addFact("string(0.1) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string(0.1);'); }), "string:0.10", "GMLC differs from GameMaker");
	});

	addFact("string(1/3) [GameMaker]", function() {
		assert_equals(case_run(case_value_printing_string_third), "string:0.33", "GameMaker no longer gives the measured result");
	});
	addFact("string(1/3) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string(1/3);'); }), "string:0.33", "GMLC differs from GameMaker");
	});

	addFact("string_format(1/3, 0, 17) [GameMaker]", function() {
		assert_equals(case_run(case_value_printing_string_format_17), "string:0.33333333333333331", "GameMaker no longer gives the measured result");
	});
	addFact("string_format(1/3, 0, 17) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string_format(1/3, 0, 17);'); }), "string:0.33333333333333331", "GMLC differs from GameMaker");
	});

	addFact("string(2^53) [GameMaker]", function() {
		assert_equals(case_run(case_value_printing_string_large_integer), "string:9007199254740992", "GameMaker no longer gives the measured result");
	});
	addFact("string(2^53) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string(power(2, 53));'); }), "string:9007199254740992", "GMLC differs from GameMaker");
	});

	addFact("string(-2.5) [GameMaker]", function() {
		assert_equals(case_run(case_value_printing_string_negative_fraction), "string:-2.50", "GameMaker no longer gives the measured result");
	});
	addFact("string(-2.5) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string(-2.5);'); }), "string:-2.50", "GMLC differs from GameMaker");
	});
}

function case_value_printing_string_1e21() {
return string(power(10, 21));
}

function case_value_printing_string_tenth() {
return string(0.1);
}

function case_value_printing_string_third() {
return string(1/3);
}

function case_value_printing_string_format_17() {
return string_format(1/3, 0, 17);
}

function case_value_printing_string_large_integer() {
return string(power(2, 53));
}

function case_value_printing_string_negative_fraction() {
return string(-2.5);
}
