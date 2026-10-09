// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-07.
function GmlSwitchLabelTestSuite() : TestSuite() constructor {

	addFact("case ord(\"A\") [GameMaker]", function() {
		assert_equals(case_run(case_switch_labels_label_ord), "string:hit", "GameMaker no longer gives the measured result");
	});
	addFact("case ord(\"A\") [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'switch (65) { case ord("A"): return "hit"; default: return "miss"; }'); }), "string:hit", "GMLC differs from GameMaker");
	});

	addFact("case MACRO [GameMaker]", function() {
		assert_equals(case_run(case_switch_labels_label_macro), "string:hit", "GameMaker no longer gives the measured result");
	});
	addFact("case MACRO [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_SW_LABEL_MACRO 5
switch (5) { case CASE_SW_LABEL_MACRO: return "hit"; default: return "miss"; }'); }), "string:hit", "GMLC differs from GameMaker");
	});

	addFact("case Enum.B [GameMaker]", function() {
		assert_equals(case_run(case_switch_labels_label_enum), "string:hit", "GameMaker no longer gives the measured result");
	});
	addFact("case Enum.B [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseSwLabelEnum { A, B }
switch (1) { case CaseSwLabelEnum.B: return "hit"; default: return "miss"; }'); }), "string:hit", "GMLC differs from GameMaker");
	});

	addFact("case 1 + 2 [GameMaker]", function() {
		assert_equals(case_run(case_switch_labels_label_sum), "string:hit", "GameMaker no longer gives the measured result");
	});
	addFact("case 1 + 2 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'switch (3) { case 1 + 2: return "hit"; default: return "miss"; }'); }), "string:hit", "GMLC differs from GameMaker");
	});

	addFact("case variable [GameMaker]", function() {
		assert_equals(case_run(case_switch_labels_label_variable), "string:hit", "GameMaker no longer gives the measured result");
	});
	addFact("case variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var k = 2;
switch (2) { case k: return "hit"; default: return "miss"; }'); }), "string:hit", "GMLC differs from GameMaker");
	});

	// the same case twice: GameMaker 2024.14.4.268 refuses to compile this:
	//   duplicate case statement found
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("the same case twice [GameMaker]", function() {
	//   switch (1) { case 1: return "first"; case 1: return "second"; }
	//   return "none";
	// });
	addFact("the same case twice is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'switch (1) { case 1: return "first"; case 1: return "second"; }
return "none";'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("a string value against number and string cases [GameMaker]", function() {
		assert_equals(case_run(case_switch_labels_label_mixed), "string:number", "GameMaker no longer gives the measured result");
	});
	addFact("a string value against number and string cases [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'switch ("1") { case 1: return "number"; case "1": return "string"; default: return "neither"; }'); }), "string:number", "GMLC differs from GameMaker");
	});
}

function case_switch_labels_label_ord() {
switch (65) { case ord("A"): return "hit"; default: return "miss"; }
}

function case_switch_labels_label_macro() {
#macro CASE_SW_LABEL_MACRO 5
switch (5) { case CASE_SW_LABEL_MACRO: return "hit"; default: return "miss"; }
}

function case_switch_labels_label_enum() {
enum CaseSwLabelEnum { A, B }
switch (1) { case CaseSwLabelEnum.B: return "hit"; default: return "miss"; }
}

function case_switch_labels_label_sum() {
switch (3) { case 1 + 2: return "hit"; default: return "miss"; }
}

function case_switch_labels_label_variable() {
var k = 2;
switch (2) { case k: return "hit"; default: return "miss"; }
}

function case_switch_labels_label_mixed() {
switch ("1") { case 1: return "number"; case "1": return "string"; default: return "neither"; }
}
