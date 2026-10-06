// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-06.
function GmlStatementTestSuite() : TestSuite() constructor {

	addFact("default before the cases of a switch [GameMaker]", function() {
		assert_equals(case_run(case_statements_switch_default_first), "string:2", "GameMaker no longer gives the measured result");
	});
	addFact("default before the cases of a switch [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = "";
switch (2) {
	default: r += "d";
	case 1: r += "1"; break;
	case 2: r += "2"; break;
}
return r;'); }), "string:2", "GMLC differs from GameMaker");
	});

	addFact("default before the cases, no case matches [GameMaker]", function() {
		assert_equals(case_run(case_statements_switch_default_first_no_match), "string:d1", "GameMaker no longer gives the measured result");
	});
	addFact("default before the cases, no case matches [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = "";
switch (5) {
	default: r += "d";
	case 1: r += "1"; break;
	case 2: r += "2"; break;
}
return r;'); }), "string:d1", "GMLC differs from GameMaker");
	});

	// a function expression called at the start of a statement: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   unexpected symbol ")" in expression
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a function expression called at the start of a statement [GameMaker]", function() {
	//   global.stmt_iife_ran = 0;
	//   function() { global.stmt_iife_ran = 1; }();
	//   return global.stmt_iife_ran;
	// });
	addFact("a function expression called at the start of a statement [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'global.stmt_iife_ran = 0;
function() { global.stmt_iife_ran = 1; }();
return global.stmt_iife_ran;'); }), "number:1", "GMLC no longer gives its result");
	});

	addFact("a static method named toString [GameMaker]", function() {
		assert_equals(case_run(case_statements_tostring_static_method), "string:named 4", "GameMaker no longer gives the measured result");
	});
	addFact("a static method named toString [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'function StmtNamed(_n) constructor {
	n = _n;
	static toString = function() { return "named " + string(n); };
}
return string(new StmtNamed(4));'); }), "string:named 4", "GMLC differs from GameMaker");
	});

	addFact("a struct literal key named toString [GameMaker]", function() {
		assert_equals(case_run(case_statements_tostring_struct_key), "string:S", "GameMaker no longer gives the measured result");
	});
	addFact("a struct literal key named toString [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { toString: function() { return "S"; } };
return string(s);'); }), "string:S", "GMLC differs from GameMaker");
	});

	addFact("a local variable named toString [GameMaker]", function() {
		assert_equals(case_run(case_statements_tostring_local), "number:4", "GameMaker no longer gives the measured result");
	});
	addFact("a local variable named toString [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var toString = 3;
return toString + 1;'); }), "number:4", "GMLC differs from GameMaker");
	});

	addFact("a var list ending in a comma, then an if [GameMaker]", function() {
		assert_equals(case_run(case_statements_var_trailing_comma_if), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("a var list ending in a comma, then an if [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 1,
if (a == 1) a = 2;
return a;'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("a var list ending in a comma, then another var [GameMaker]", function() {
		assert_equals(case_run(case_statements_var_trailing_comma_var), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("a var list ending in a comma, then another var [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 1,
var b = 2;
return a + b;'); }), "number:3", "GMLC differs from GameMaker");
	});

	// a static list ending in a comma: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   static variables must be assigned a value
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a static list ending in a comma [GameMaker]", function() {
	//   function stmt_static_comma() {
	//   	static s = 5,
	//   	return s;
	//   }
	//   return stmt_static_comma();
	// });
	addFact("a static list ending in a comma [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'function stmt_static_comma() {
	static s = 5,
	return s;
}
return stmt_static_comma();'); }), "number:5", "GMLC no longer gives its result");
	});

	// a static without a value: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   static variables must be assigned a value
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("a static without a value [GameMaker]", function() {
	//   function stmt_static_bare() {
	//   	static s;
	//   	return 1;
	//   }
	//   return stmt_static_bare();
	// });
	addFact("a static without a value is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'function stmt_static_bare() {
	static s;
	return 1;
}
return stmt_static_bare();'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// the second static of a list without a value: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   static variables must be assigned a value
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("the second static of a list without a value [GameMaker]", function() {
	//   function stmt_static_second() {
	//   	static a = 1, b;
	//   	return a;
	//   }
	//   return stmt_static_second();
	// });
	addFact("the second static of a list without a value is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'function stmt_static_second() {
	static a = 1, b;
	return a;
}
return stmt_static_second();'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("a // @NoOp comment before a closing brace [GameMaker]", function() {
		assert_equals(case_run(case_statements_noop_comment_before_close), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("a // @NoOp comment before a closing brace [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 0;
if (true) {
	r = 1;
	// @NoOp
}
return r;'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("a // @NoOp comment before else [GameMaker]", function() {
		assert_equals(case_run(case_statements_noop_comment_before_else), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("a // @NoOp comment before else [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 0;
if (false) r = 1;
// @NoOp
else r = 2;
return r;'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("a // @NoOp comment inside an argument list [GameMaker]", function() {
		assert_equals(case_run(case_statements_noop_comment_in_arguments), "number:6", "GameMaker no longer gives the measured result");
	});
	addFact("a // @NoOp comment inside an argument list [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_sum3(1, // @NoOp
	2, 3);'); }), "number:6", "GMLC differs from GameMaker");
	});

	addFact("a number alone as a struct entry [GameMaker]", function() {
		assert_equals(case_run(case_statements_struct_shorthand_number), "string:{\"5\":5.0}", "GameMaker no longer gives the measured result");
	});
	addFact("a number alone as a struct entry [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { 5 };
return json_stringify(s);'); }), "string:{\"5\":5.0}", "GMLC differs from GameMaker");
	});

	addFact("two numbers alone as struct entries [GameMaker]", function() {
		assert_equals(case_run(case_statements_struct_shorthand_number_two), "string:5:7", "GameMaker no longer gives the measured result");
	});
	addFact("two numbers alone as struct entries [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { 5, 7 };
return string(s[$ "5"]) + ":" + string(s[$ "7"]);'); }), "string:5:7", "GMLC differs from GameMaker");
	});

	addFact("a keyword alone as a struct entry [GameMaker]", function() {
		assert_equals(case_run(case_statements_struct_shorthand_keyword), "error", "GameMaker no longer gives the measured result");
	});
	addFact("a keyword alone as a struct entry [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { repeat };
return 1;'); }), "error", "GMLC differs from GameMaker");
	});

	// an alias word alone as a struct entry: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   Expected id
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("an alias word alone as a struct entry [GameMaker]", function() {
	//   var s = { and };
	//   return 1;
	// });
	addFact("an alias word alone as a struct entry is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { and };
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// ++ on a number: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   malformed assignment
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("++ on a number [GameMaker]", function() {
	//   var a = ++5;
	//   return 1;
	// });
	addFact("++ on a number is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = ++5;
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// postfix ++ on a number: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   malformed assignment
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("postfix ++ on a number [GameMaker]", function() {
	//   var a = 5++;
	//   return 1;
	// });
	addFact("postfix ++ on a number is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 5++;
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// ++ on a call: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   malformed assignment
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("++ on a call [GameMaker]", function() {
	//   var a = case_sum3(1, 2, 3)++;
	//   return 1;
	// });
	addFact("++ on a call is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = case_sum3(1, 2, 3)++;
return 1;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("default between two cases [GameMaker]", function() {
		assert_equals(case_run(case_statements_switch_default_middle), "string:3", "GameMaker no longer gives the measured result");
	});
	addFact("default between two cases [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = "";
switch (3) {
	case 1: r += "1";
	default: r += "d";
	case 2: r += "2"; break;
	case 3: r += "3";
}
return r;'); }), "string:3", "GMLC differs from GameMaker");
	});

	addFact("a parameter named toString [GameMaker]", function() {
		assert_equals(case_run(case_statements_tostring_parameter), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("a parameter named toString [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function(toString) { return toString + 1; };
return f(4);'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("a var list ending in a comma at the end of a block [GameMaker]", function() {
		assert_equals(case_run(case_statements_var_trailing_comma_end_of_block), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("a var list ending in a comma at the end of a block [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 0;
if (true) {
	var a = 3,
}
r = a;
return r;'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("names alone as struct entries [GameMaker]", function() {
		assert_equals(case_run(case_statements_struct_shorthand_names), "string:123", "GameMaker no longer gives the measured result");
	});
	addFact("names alone as struct entries [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 1, b = 2, c = 3;
var s = { a, b, c };
return string(s.a) + string(s.b) + string(s.c);'); }), "string:123", "GMLC differs from GameMaker");
	});

	// a quoted key alone as a struct entry: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   got string 'a' expected id
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("a quoted key alone as a struct entry [GameMaker]", function() {
	//   var a = 4;
	//   var s = { "a" };
	//   return s.a;
	// });
	addFact("a quoted key alone as a struct entry is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 4;
var s = { "a" };
return s.a;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// gml_pragma("@NoOp") before a statement: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   unknown pragma '@NoOp'
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("gml_pragma(\"@NoOp\") before a statement [GameMaker]", function() {
	//   var r = 0;
	//   gml_pragma("@NoOp");
	//   r = 2;
	//   return r;
	// });
}

function case_statements_switch_default_first() {
var r = "";
switch (2) {
	default: r += "d";
	case 1: r += "1"; break;
	case 2: r += "2"; break;
}
return r;
}

function case_statements_switch_default_first_no_match() {
var r = "";
switch (5) {
	default: r += "d";
	case 1: r += "1"; break;
	case 2: r += "2"; break;
}
return r;
}

function case_statements_tostring_static_method() {
function StmtNamed(_n) constructor {
	n = _n;
	static toString = function() { return "named " + string(n); };
}
return string(new StmtNamed(4));
}

function case_statements_tostring_struct_key() {
var s = { toString: function() { return "S"; } };
return string(s);
}

function case_statements_tostring_local() {
var toString = 3;
return toString + 1;
}

function case_statements_var_trailing_comma_if() {
var a = 1,
if (a == 1) a = 2;
return a;
}

function case_statements_var_trailing_comma_var() {
var a = 1,
var b = 2;
return a + b;
}

function case_statements_noop_comment_before_close() {
var r = 0;
if (true) {
	r = 1;
	// @NoOp
}
return r;
}

function case_statements_noop_comment_before_else() {
var r = 0;
if (false) r = 1;
// @NoOp
else r = 2;
return r;
}

function case_statements_noop_comment_in_arguments() {
return case_sum3(1, // @NoOp
	2, 3);
}

function case_statements_struct_shorthand_number() {
var s = { 5 };
return json_stringify(s);
}

function case_statements_struct_shorthand_number_two() {
var s = { 5, 7 };
return string(s[$ "5"]) + ":" + string(s[$ "7"]);
}

function case_statements_struct_shorthand_keyword() {
var s = { repeat };
return 1;
}

function case_statements_switch_default_middle() {
var r = "";
switch (3) {
	case 1: r += "1";
	default: r += "d";
	case 2: r += "2"; break;
	case 3: r += "3";
}
return r;
}

function case_statements_tostring_parameter() {
var f = function(toString) { return toString + 1; };
return f(4);
}

function case_statements_var_trailing_comma_end_of_block() {
var r = 0;
if (true) {
	var a = 3,
}
r = a;
return r;
}

function case_statements_struct_shorthand_names() {
var a = 1, b = 2, c = 3;
var s = { a, b, c };
return string(s.a) + string(s.b) + string(s.c);
}
