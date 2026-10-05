// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-05.
function GmlDirectiveTestSuite() : TestSuite() constructor {

	addFact("#region title containing # [GameMaker]", function() {
		assert_equals(case_run(case_directives_region_title_hash), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("#region title containing # [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#region Fix #42
var a = 1;
#endregion
return a;'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("#region title with an unbalanced quote [GameMaker]", function() {
		assert_equals(case_run(case_directives_region_title_quote), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("#region title with an unbalanced quote [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#region "unbalanced
var a = 2;
#endregion
return a;'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("#region title starting a block comment [GameMaker]", function() {
		assert_equals(case_run(case_directives_region_title_comment), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("#region title starting a block comment [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#region /* not a comment
var a = 3;
#endregion
return a;'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("#region title starting a template [GameMaker]", function() {
		assert_equals(case_run(case_directives_region_title_template), "number:4", "GameMaker no longer gives the measured result");
	});
	addFact("#region title starting a template [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#region $"x{
var a = 4;
#endregion
return a;'); }), "number:4", "GMLC differs from GameMaker");
	});

	addFact("#endregion followed by text [GameMaker]", function() {
		assert_equals(case_run(case_directives_endregion_text), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("#endregion followed by text [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#region a
var a = 5;
#endregion done #1 "x
return a;'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("#region after code on the same line [GameMaker]", function() {
		assert_equals(case_run(case_directives_region_after_code), "number:6", "GameMaker no longer gives the measured result");
	});
	addFact("#region after code on the same line [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 6; #region a
#endregion
return a;'); }), "number:6", "GMLC differs from GameMaker");
	});

	addFact("#macro indented with spaces [GameMaker]", function() {
		assert_equals(case_run(case_directives_macro_indented_spaces), "number:7", "GameMaker no longer gives the measured result");
	});
	addFact("#macro indented with spaces [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'    #macro CASE_DIR_M1 7
return CASE_DIR_M1;'); }), "number:7", "GMLC differs from GameMaker");
	});

	addFact("#macro indented with a tab [GameMaker]", function() {
		assert_equals(case_run(case_directives_macro_indented_tab), "number:8", "GameMaker no longer gives the measured result");
	});
	addFact("#macro indented with a tab [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'	#macro CASE_DIR_M2 8
return CASE_DIR_M2;'); }), "number:8", "GMLC differs from GameMaker");
	});

	addFact("#macro after code on the same line [GameMaker]", function() {
		assert_equals(case_run(case_directives_macro_after_code), "number:10", "GameMaker no longer gives the measured result");
	});
	addFact("#macro after code on the same line [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 1; #macro CASE_DIR_M3 9
return a + CASE_DIR_M3;'); }), "number:10", "GMLC differs from GameMaker");
	});

	addFact("#macro continued with a backslash [GameMaker]", function() {
		assert_equals(case_run(case_directives_macro_continued), "number:21", "GameMaker no longer gives the measured result");
	});
	addFact("#macro continued with a backslash [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_DIR_M4 1 + \
2
return CASE_DIR_M4 * 10;'); }), "number:21", "GMLC differs from GameMaker");
	});

	addFact("macro used above its #macro line [GameMaker]", function() {
		assert_equals(case_run(case_directives_macro_used_before), "number:11", "GameMaker no longer gives the measured result");
	});
	addFact("macro used above its #macro line [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = CASE_DIR_M5;
#macro CASE_DIR_M5 11
return a;'); }), "number:11", "GMLC differs from GameMaker");
	});

	addFact("g[# i, j] [GameMaker]", function() {
		assert_equals(case_run(case_directives_grid_accessor), "number:12", "GameMaker no longer gives the measured result");
	});
	addFact("g[# i, j] [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var g = ds_grid_create(2, 2);
g[# 1, 0] = 12;
var _r = g[# 1, 0];
ds_grid_destroy(g);
return _r;'); }), "number:12", "GMLC differs from GameMaker");
	});

	// [#ff0000] (no space after [): GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   unexpected symbol "[#" in expression
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("[#ff0000] (no space after [) [GameMaker]", function() {
	//   var a = [#ff0000];
	//   return a[0];
	// });
	addFact("[#ff0000] (no space after [) is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = [#ff0000];
return a[0];'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("[ #ff0000 ] (space after [) [GameMaker]", function() {
		assert_equals(case_run(case_directives_array_colour_space), "number:255", "GameMaker no longer gives the measured result");
	});
	addFact("[ #ff0000 ] (space after [) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = [ #ff0000 ];
return a[0];'); }), "number:255", "GMLC differs from GameMaker");
	});

	// [$FF] (no space after [): GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   unexpected symbol "[$" in expression
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("[$FF] (no space after [) [GameMaker]", function() {
	//   var a = [$FF];
	//   return a[0];
	// });
	addFact("[$FF] (no space after [) is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = [$FF];
return a[0];'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("[ $FF ] (space after [) [GameMaker]", function() {
		assert_equals(case_run(case_directives_array_hex_space), "number:255", "GameMaker no longer gives the measured result");
	});
	addFact("[ $FF ] (space after [) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = [ $FF ];
return a[0];'); }), "number:255", "GMLC differs from GameMaker");
	});

	addFact("[@\"s\"] (no space after [) [GameMaker]", function() {
		assert_equals(case_run(case_directives_array_raw_string), "string:s", "GameMaker no longer gives the measured result");
	});
	addFact("[@\"s\"] (no space after [) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = [@"s"];
return a[0];'); }), "string:s", "GMLC differs from GameMaker");
	});

	// [|1] (no space after [): GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   unexpected symbol "[|" in expression
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("[|1] (no space after [) [GameMaker]", function() {
	//   var a = [|1];
	//   return a[0];
	// });
	addFact("[|1] (no space after [) is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = [|1];
return a[0];'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("s.end [GameMaker]", function() {
		assert_equals(case_run(case_directives_member_end), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("s.end [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = {};
s.end = 1;
return s.end;'); }), "number:1", "GMLC differs from GameMaker");
	});

	// {end: 1}: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   unexpected symbol ":" in expression
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("{end: 1} [GameMaker]", function() {
	//   var s = {end: 1};
	//   return s.end;
	// });
	addFact("{end: 1} is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = {end: 1};
return s.end;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("s.begin [GameMaker]", function() {
		assert_equals(case_run(case_directives_member_begin), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("s.begin [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = {};
s.begin = 2;
return s.begin;'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("s.then [GameMaker]", function() {
		assert_equals(case_run(case_directives_member_then), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("s.then [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = {};
s.then = 3;
return s.then;'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("s.not [GameMaker]", function() {
		assert_equals(case_run(case_directives_member_not), "number:4", "GameMaker no longer gives the measured result");
	});
	addFact("s.not [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = {};
s.not = 4;
return s.not;'); }), "number:4", "GMLC differs from GameMaker");
	});

	addFact("s.mod [GameMaker]", function() {
		assert_equals(case_run(case_directives_member_mod), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("s.mod [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = {};
s.mod = 5;
return s.mod;'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("s.div [GameMaker]", function() {
		assert_equals(case_run(case_directives_member_div), "number:6", "GameMaker no longer gives the measured result");
	});
	addFact("s.div [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = {};
s.div = 6;
return s.div;'); }), "number:6", "GMLC differs from GameMaker");
	});

	addFact("s.repeat [GameMaker]", function() {
		assert_equals(case_run(case_directives_member_repeat), "number:7", "GameMaker no longer gives the measured result");
	});
	addFact("s.repeat [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = {};
s.repeat = 7;
return s.repeat;'); }), "number:7", "GMLC differs from GameMaker");
	});

	addFact("[@ then a quote: a verbatim string or the array accessor (escape kept?) [GameMaker]", function() {
		assert_equals(case_run(case_directives_array_at_escape), "string:3:0", "GameMaker no longer gives the measured result");
	});
	addFact("[@ then a quote: a verbatim string or the array accessor (escape kept?) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = [@"x\ty"];
return string(string_length(a[0])) + ":" + string(string_pos(chr(92), a[0]) > 0);'); }), "string:3:0", "GMLC differs from GameMaker");
	});

	addFact("[ @ with a space before the quote [GameMaker]", function() {
		assert_equals(case_run(case_directives_array_at_space_escape), "string:4:1", "GameMaker no longer gives the measured result");
	});
	addFact("[ @ with a space before the quote [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = [ @"x\ty"];
return string(string_length(a[0])) + ":" + string(string_pos(chr(92), a[0]) > 0);'); }), "string:4:1", "GMLC differs from GameMaker");
	});

	// a[@"1"] = 456 on an array: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   Only ds_map or struct can be looked up using a string.  Have you forgotten a '?' or '$' accessor?
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a[@\"1\"] = 456 on an array [GameMaker]", function() {
	//   var a = [0, 0];
	//   a[@"1"] = 456;
	//   return string(a);
	// });

	// a[@"1"] read on an array: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   Only ds_map or struct can be looked up using a string.  Have you forgotten a '?' or '$' accessor?
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a[@\"1\"] read on an array [GameMaker]", function() {
	//   var a = [5, 6];
	//   return a[@"1"];
	// });

	// a["1"] read on an array: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   Only ds_map or struct can be looked up using a string.  Have you forgotten a '?' or '$' accessor?
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a[\"1\"] read on an array [GameMaker]", function() {
	//   var a = [5, 6];
	//   return a["1"];
	// });

	// a["1"] = 456 on an array: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   Only ds_map or struct can be looked up using a string.  Have you forgotten a '?' or '$' accessor?
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a[\"1\"] = 456 on an array [GameMaker]", function() {
	//   var a = [0, 0];
	//   a["1"] = 456;
	//   return string(a);
	// });

	// a[@ string with an escape] = 456 on an array: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   Only ds_map or struct can be looked up using a string.  Have you forgotten a '?' or '$' accessor?
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a[@ string with an escape] = 456 on an array [GameMaker]", function() {
	//   var a = [0, 0];
	//   a[@"1\t"] = 456;
	//   return string(a);
	// });
}

function case_directives_region_title_hash() {
#region Fix #42
var a = 1;
#endregion
return a;
}

function case_directives_region_title_quote() {
#region "unbalanced
var a = 2;
#endregion
return a;
}

function case_directives_region_title_comment() {
#region /* not a comment
var a = 3;
#endregion
return a;
}

function case_directives_region_title_template() {
#region $"x{
var a = 4;
#endregion
return a;
}

function case_directives_endregion_text() {
#region a
var a = 5;
#endregion done #1 "x
return a;
}

function case_directives_region_after_code() {
var a = 6; #region a
#endregion
return a;
}

function case_directives_macro_indented_spaces() {
    #macro CASE_DIR_M1 7
return CASE_DIR_M1;
}

function case_directives_macro_indented_tab() {
	#macro CASE_DIR_M2 8
return CASE_DIR_M2;
}

function case_directives_macro_after_code() {
var a = 1; #macro CASE_DIR_M3 9
return a + CASE_DIR_M3;
}

function case_directives_macro_continued() {
#macro CASE_DIR_M4 1 + \
2
return CASE_DIR_M4 * 10;
}

function case_directives_macro_used_before() {
var a = CASE_DIR_M5;
#macro CASE_DIR_M5 11
return a;
}

function case_directives_grid_accessor() {
var g = ds_grid_create(2, 2);
g[# 1, 0] = 12;
var _r = g[# 1, 0];
ds_grid_destroy(g);
return _r;
}

function case_directives_array_colour_space() {
var a = [ #ff0000 ];
return a[0];
}

function case_directives_array_hex_space() {
var a = [ $FF ];
return a[0];
}

function case_directives_array_raw_string() {
var a = [@"s"];
return a[0];
}

function case_directives_member_end() {
var s = {};
s.end = 1;
return s.end;
}

function case_directives_member_begin() {
var s = {};
s.begin = 2;
return s.begin;
}

function case_directives_member_then() {
var s = {};
s.then = 3;
return s.then;
}

function case_directives_member_not() {
var s = {};
s.not = 4;
return s.not;
}

function case_directives_member_mod() {
var s = {};
s.mod = 5;
return s.mod;
}

function case_directives_member_div() {
var s = {};
s.div = 6;
return s.div;
}

function case_directives_member_repeat() {
var s = {};
s.repeat = 7;
return s.repeat;
}

function case_directives_array_at_escape() {
var a = [@"x\ty"];
return string(string_length(a[0])) + ":" + string(string_pos(chr(92), a[0]) > 0);
}

function case_directives_array_at_space_escape() {
var a = [ @"x\ty"];
return string(string_length(a[0])) + ":" + string(string_pos(chr(92), a[0]) > 0);
}
