// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-04.
function GmlLegacySyntaxTestSuite() : TestSuite() constructor {

	addFact(":= assigns [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_colon_assign), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact(":= assigns [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 0;
a := 5;
return a;'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("not is ! [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_not_word), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("not is ! [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return not false;'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("and is && [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_and_word), "number:0", "GameMaker no longer gives the measured result");
	});
	addFact("and is && [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return true and false;'); }), "number:0", "GMLC differs from GameMaker");
	});

	addFact("or is || [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_or_word), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("or is || [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return false or true;'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("xor is ^^ [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_xor_word), "number:0", "GameMaker no longer gives the measured result");
	});
	addFact("xor is ^^ [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return true xor true;'); }), "number:0", "GMLC differs from GameMaker");
	});

	addFact("<> is != [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_angle_neq), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("<> is != [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 1 <> 2;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("begin and end are braces [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_begin_end), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("begin and end are braces [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 0;
if (true) begin a = 1; end
return a;'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("then after an if condition [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_then_word), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("then after an if condition [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 0;
if (true) then a = 1;
return a;'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("if without parentheses, with then [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_then_no_parens), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("if without parentheses, with then [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 0;
if a == 0 then a = 2;
return a;'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("= compares inside an if condition [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_single_eq_compare), "string:equal", "GameMaker no longer gives the measured result");
	});
	addFact("= compares inside an if condition [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 1;
if (a = 1) return "equal";
return "not equal";'); }), "string:equal", "GMLC differs from GameMaker");
	});

	addFact("= in a var initialiser after a comparison operand [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_single_eq_in_expression), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("= in a var initialiser after a comparison operand [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 1;
var b = (a = 1);
return b;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("div is integer division [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_div_word), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("div is integer division [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 7 div 2;'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("mod is remainder [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_mod_word), "number:-1", "GameMaker no longer gives the measured result");
	});
	addFact("mod is remainder [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return -7 mod 3;'); }), "number:-1", "GMLC differs from GameMaker");
	});

	addFact("not 1 == 2 binds not first [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_not_precedence), "bool:0", "GameMaker no longer gives the measured result");
	});
	addFact("not 1 == 2 binds not first [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return not 1 == 2;'); }), "bool:0", "GMLC differs from GameMaker");
	});

	addFact("true or false and false [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_word_precedence), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("true or false and false [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return true or false and false;'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("and short-circuits like && [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_and_word_order), "string:A=0", "GameMaker no longer gives the measured result");
	});
	addFact("and short-circuits like && [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", false) and case_ev("B", true);
return case_log() + "=" + string(_r);'); }), "string:A=0", "GMLC differs from GameMaker");
	});

	addFact("globalvar declaration [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_globalvar), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("globalvar declaration [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'globalvar case_legacy_gv;
case_legacy_gv = 3;
return global.case_legacy_gv;'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("assigning past the end grows an array [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_array_grow_by_index), "string:[ 0,0,1 ]", "GameMaker no longer gives the measured result");
	});
	addFact("assigning past the end grows an array [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var arr = [];
arr[2] = 1;
return string(arr);'); }), "string:[ 0,0,1 ]", "GMLC differs from GameMaker");
	});

	addFact("a[i, j] is a[i][j] [GameMaker]", function() {
		assert_equals(case_run(case_legacy_syntax_array_2d_comma), "string:3 2", "GameMaker no longer gives the measured result");
	});
	addFact("a[i, j] is a[i][j] [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var arr = [];
arr[1, 2] = 3;
return string(arr[1][2]) + " " + string(array_length(arr));'); }), "string:3 2", "GMLC differs from GameMaker");
	});

	// var arr[10] = 0: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-04):
	//   Cannot set a constant ("[") to a value
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("var arr[10] = 0 [GameMaker]", function() {
	//   var arr[10] = 0;
	//   return string(arr);
	// });
	addFact("var arr[10] = 0 is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var arr[10] = 0;
return string(arr);'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// not as a variable name: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-04):
	//   unexpected symbol "=" in expression
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("not as a variable name [GameMaker]", function() {
	//   var not = 1;
	//   return not;
	// });
	addFact("not as a variable name is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var not = 1;
return not;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// then as a variable name: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-04):
	//   Assignment operator expected
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("then as a variable name [GameMaker]", function() {
	//   var then = 1;
	//   return then;
	// });
	addFact("then as a variable name is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var then = 1;
return then;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// begin as a variable name: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-04):
	//   unexpected symbol "=" in expression
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("begin as a variable name [GameMaker]", function() {
	//   var begin = 1;
	//   return begin;
	// });
	addFact("begin as a variable name is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var begin = 1;
return begin;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// xor as a variable name: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-04):
	//   unexpected symbol "xor" in expression
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("xor as a variable name [GameMaker]", function() {
	//   var xor = 1;
	//   return xor;
	// });
	addFact("xor as a variable name is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var xor = 1;
return xor;'); }), "error", "GMLC accepts code GameMaker refuses");
	});
}

function case_legacy_syntax_colon_assign() {
var a = 0;
a := 5;
return a;
}

function case_legacy_syntax_not_word() {
return not false;
}

function case_legacy_syntax_and_word() {
return true and false;
}

function case_legacy_syntax_or_word() {
return false or true;
}

function case_legacy_syntax_xor_word() {
return true xor true;
}

function case_legacy_syntax_angle_neq() {
return 1 <> 2;
}

function case_legacy_syntax_begin_end() {
var a = 0;
if (true) begin a = 1; end
return a;
}

function case_legacy_syntax_then_word() {
var a = 0;
if (true) then a = 1;
return a;
}

function case_legacy_syntax_then_no_parens() {
var a = 0;
if a == 0 then a = 2;
return a;
}

function case_legacy_syntax_single_eq_compare() {
var a = 1;
if (a = 1) return "equal";
return "not equal";
}

function case_legacy_syntax_single_eq_in_expression() {
var a = 1;
var b = (a = 1);
return b;
}

function case_legacy_syntax_div_word() {
return 7 div 2;
}

function case_legacy_syntax_mod_word() {
return -7 mod 3;
}

function case_legacy_syntax_not_precedence() {
return not 1 == 2;
}

function case_legacy_syntax_word_precedence() {
return true or false and false;
}

function case_legacy_syntax_and_word_order() {
case_log_reset();
var _r = case_ev("A", false) and case_ev("B", true);
return case_log() + "=" + string(_r);
}

function case_legacy_syntax_globalvar() {
globalvar case_legacy_gv;
case_legacy_gv = 3;
return global.case_legacy_gv;
}

function case_legacy_syntax_array_grow_by_index() {
var arr = [];
arr[2] = 1;
return string(arr);
}

function case_legacy_syntax_array_2d_comma() {
var arr = [];
arr[1, 2] = 3;
return string(arr[1][2]) + " " + string(array_length(arr));
}
