// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-05.
function GmlMacroTestSuite() : TestSuite() constructor {

	// the same macro defined twice in one file: GameMaker 2024.14.4.268 refuses to compile this:
	//   macro CASE_MA_DUP is already defined
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("the same macro defined twice in one file [GameMaker]", function() {
	//   #macro CASE_MA_DUP 1
	//   #macro CASE_MA_DUP 2
	//   return CASE_MA_DUP;
	// });
	addFact("the same macro defined twice in one file is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_DUP 1
#macro CASE_MA_DUP 2
return CASE_MA_DUP;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// two macros that expand to each other: GameMaker 2024.14.4.268 refuses to compile this:
	//   "CASE_MA_CYB" and "CASE_MA_CYA" are part of a recursive macro expansion
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("two macros that expand to each other [GameMaker]", function() {
	//   #macro CASE_MA_CYA CASE_MA_CYB
	//   #macro CASE_MA_CYB CASE_MA_CYA
	//   return 1;
	// });
	addFact("two macros that expand to each other is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_CYA CASE_MA_CYB
#macro CASE_MA_CYB CASE_MA_CYA
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// a macro that uses itself: GameMaker 2024.14.4.268 refuses to compile this:
	//   "CASE_MA_SELF" and "CASE_MA_SELF" are part of a recursive macro expansion
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("a macro that uses itself [GameMaker]", function() {
	//   #macro CASE_MA_SELF CASE_MA_SELF + 1
	//   return 1;
	// });
	addFact("a macro that uses itself is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_SELF CASE_MA_SELF + 1
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("a macro whose body uses another macro, defined later [GameMaker]", function() {
		assert_equals(case_run(case_macros_nested), "number:12", "GameMaker no longer gives the measured result");
	});
	addFact("a macro whose body uses another macro, defined later [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_OUT CASE_MA_IN + 1
#macro CASE_MA_IN 2
return CASE_MA_OUT * 10;'); }), "number:12", "GMLC differs from GameMaker");
	});

	addFact("a macro defined only for another configuration [GameMaker]", function() {
		assert_equals(case_run(case_macros_config_only_other), "error", "GameMaker no longer gives the measured result");
	});
	addFact("a macro defined only for another configuration [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro Debug:CASE_MA_CFG1 1
return CASE_MA_CFG1;'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("a default macro and a Debug override, under Default [GameMaker]", function() {
		assert_equals(case_run(case_macros_config_with_default), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("a default macro and a Debug override, under Default [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_CFG2 2
#macro Debug:CASE_MA_CFG2 1
return CASE_MA_CFG2;'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("a macro for a configuration the project does not have [GameMaker]", function() {
		assert_equals(case_run(case_macros_config_unknown), "error", "GameMaker no longer gives the measured result");
	});
	addFact("a macro for a configuration the project does not have [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro NoSuchConfig:CASE_MA_CFG3 3
return CASE_MA_CFG3;'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("a continuation backslash followed by a comment [GameMaker]", function() {
		assert_equals(case_run(case_macros_continued_comment), "number:21", "GameMaker no longer gives the measured result");
	});
	addFact("a continuation backslash followed by a comment [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_CC 1 + \ // note
2
return CASE_MA_CC * 10;'); }), "number:21", "GMLC differs from GameMaker");
	});

	// a token between the backslash and the line break: GameMaker 2024.14.4.268 refuses to compile this:
	//   "CASE_MA_TAB" and "CASE_MA_TAB" are part of a recursive macro expansion
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("a token between the backslash and the line break [GameMaker]", function() {
	//   #macro CASE_MA_TAB 1 \ 2
	//   return CASE_MA_TAB;
	// });
	addFact("a token between the backslash and the line break is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_TAB 1 \ 2
return CASE_MA_TAB;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// a block comment over two lines inside a body: GameMaker 2024.14.4.268 refuses to compile this:
	//   Assignment operator expected
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("a block comment over two lines inside a body [GameMaker]", function() {
	//   #macro CASE_MA_BC 1 /* two
	//   lines */ + 2
	//   return CASE_MA_BC;
	// });
	addFact("a block comment over two lines inside a body is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_BC 1 /* two
lines */ + 2
return CASE_MA_BC;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("a body that ends with ; [GameMaker]", function() {
		assert_equals(case_run(case_macros_trailing_semicolon), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("a body that ends with ; [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_SEMI 5;
var a = CASE_MA_SEMI
return a;'); }), "number:5", "GMLC differs from GameMaker");
	});

	// a macro with an empty body: GameMaker 2024.14.4.268 refuses to compile this:
	//   Assignment operator expected
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a macro with an empty body [GameMaker]", function() {
	//   #macro CASE_MA_EMPTY
	//   return CASE_MA_EMPTY 6;
	// });

	addFact("a macro name after a dot [GameMaker]", function() {
		assert_equals(case_run(case_macros_after_dot), "number:4", "GameMaker no longer gives the measured result");
	});
	addFact("a macro name after a dot [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_DOT val
var s = {};
s.CASE_MA_DOT = 4;
return s.val;'); }), "number:4", "GMLC differs from GameMaker");
	});

	addFact("a macro name as a struct literal key [GameMaker]", function() {
		assert_equals(case_run(case_macros_struct_key), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("a macro name as a struct literal key [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_KEY val
var s = { CASE_MA_KEY: 5 };
return s.val;'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("a body that is a statement fragment [GameMaker]", function() {
		assert_equals(case_run(case_macros_keyword_body), "number:7", "GameMaker no longer gives the measured result");
	});
	addFact("a body that is a statement fragment [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_RET return 7
CASE_MA_RET;'); }), "number:7", "GMLC differs from GameMaker");
	});

	addFact("a macro next to a number [GameMaker]", function() {
		assert_equals(case_run(case_macros_token_paste), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("a macro next to a number [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_NEG -
return 5 CASE_MA_NEG 2;'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("a macro name inside a string [GameMaker]", function() {
		assert_equals(case_run(case_macros_in_string), "string:CASE_MA_STR", "GameMaker no longer gives the measured result");
	});
	addFact("a macro name inside a string [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_STR 1
return "CASE_MA_STR";'); }), "string:CASE_MA_STR", "GMLC differs from GameMaker");
	});

	addFact("a line of a body that ends with two backslashes [GameMaker]", function() {
		assert_equals(case_run(case_macros_double_backslash), "number:21", "GameMaker no longer gives the measured result");
	});
	addFact("a line of a body that ends with two backslashes [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_DBL 1 + \\
2
return CASE_MA_DBL * 10;'); }), "number:21", "GMLC differs from GameMaker");
	});

	// a backslash with text after it, then a backslash at the line end: GameMaker 2024.14.4.268 refuses to compile this:
	//   Assignment operator expected
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("a backslash with text after it, then a backslash at the line end [GameMaker]", function() {
	//   #macro CASE_MA_BTB 1 \ + \
	//   2
	//   return CASE_MA_BTB * 10;
	// });
	addFact("a backslash with text after it, then a backslash at the line end is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_MA_BTB 1 \ + \
2
return CASE_MA_BTB * 10;'); }), "error", "GMLC accepts code GameMaker refuses");
	});
}

function case_macros_nested() {
#macro CASE_MA_OUT CASE_MA_IN + 1
#macro CASE_MA_IN 2
return CASE_MA_OUT * 10;
}

function case_macros_config_only_other() {
#macro Debug:CASE_MA_CFG1 1
return CASE_MA_CFG1;
}

function case_macros_config_with_default() {
#macro CASE_MA_CFG2 2
#macro Debug:CASE_MA_CFG2 1
return CASE_MA_CFG2;
}

function case_macros_config_unknown() {
#macro NoSuchConfig:CASE_MA_CFG3 3
return CASE_MA_CFG3;
}

function case_macros_continued_comment() {
#macro CASE_MA_CC 1 + \ // note
2
return CASE_MA_CC * 10;
}

function case_macros_trailing_semicolon() {
#macro CASE_MA_SEMI 5;
var a = CASE_MA_SEMI
return a;
}

function case_macros_after_dot() {
#macro CASE_MA_DOT val
var s = {};
s.CASE_MA_DOT = 4;
return s.val;
}

function case_macros_struct_key() {
#macro CASE_MA_KEY val
var s = { CASE_MA_KEY: 5 };
return s.val;
}

function case_macros_keyword_body() {
#macro CASE_MA_RET return 7
CASE_MA_RET;
}

function case_macros_token_paste() {
#macro CASE_MA_NEG -
return 5 CASE_MA_NEG 2;
}

function case_macros_in_string() {
#macro CASE_MA_STR 1
return "CASE_MA_STR";
}

function case_macros_double_backslash() {
#macro CASE_MA_DBL 1 + \\
2
return CASE_MA_DBL * 10;
}
