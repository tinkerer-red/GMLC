// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-07.
function GmlAsiTestSuite() : TestSuite() constructor {

	addFact("`var a` then `b = 1` on the next line [GameMaker]", function() {
		assert_equals(case_run(case_asi_var_newline_name), "error", "GameMaker no longer gives the measured result");
	});
	addFact("`var a` then `b = 1` on the next line [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a
b = 1;
return string(a) + ":" + string(b);'); }), "error", "GMLC differs from GameMaker");
	});

	// `px` then `++py` on the next line: GameMaker 2024.14.4.268 refuses to compile this:
	//   Assignment operator expected
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("`px` then `++py` on the next line [GameMaker]", function() {
	//   var px = 1, py = 1;
	//   px
	//   ++py;
	//   return string(px) + ":" + string(py);
	// });
	addFact("`px` then `++py` on the next line is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var px = 1, py = 1;
px
++py;
return string(px) + ":" + string(py);'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("`a = b` then `-c` on the next line [GameMaker]", function() {
		assert_equals(case_run(case_asi_minus_next_line), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("`a = b` then `-c` on the next line [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var b = 5, c = 2;
var a = b
-c;
return a;'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("`return` then a value on the next line [GameMaker]", function() {
		assert_equals(case_run(case_asi_return_newline_value), "number:7", "GameMaker no longer gives the measured result");
	});
	addFact("`return` then a value on the next line [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return
7;'); }), "number:7", "GMLC differs from GameMaker");
	});

	addFact("`fx = fy` then `(fz)` on the next line [GameMaker]", function() {
		assert_equals(case_run(case_asi_call_next_line), "number:6", "GameMaker no longer gives the measured result");
	});
	addFact("`fx = fy` then `(fz)` on the next line [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var fy = function(_v) { return _v * 2; };
var fz = 3;
var fx = fy
(fz);
return fx;'); }), "number:6", "GMLC differs from GameMaker");
	});

	// `if (c) ++px;`: GameMaker 2024.14.4.268 refuses to compile this:
	//   Assignment operator expected
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("`if (c) ++px;` [GameMaker]", function() {
	//   var c = true, px = 1;
	//   if (c) ++px;
	//   return px;
	// });
	addFact("`if (c) ++px;` is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var c = true, px = 1;
if (c) ++px;
return px;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("`a = 1 b = 2` on one line [GameMaker]", function() {
		assert_equals(case_run(case_asi_two_assignments_one_line), "string:1:2", "GameMaker no longer gives the measured result");
	});
	addFact("`a = 1 b = 2` on one line [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a, b;
a = 1 b = 2
return string(a) + ":" + string(b);'); }), "string:1:2", "GMLC differs from GameMaker");
	});

	addFact("`if (c) ++m[? \"k\"] = 123;` with c = 1 [GameMaker]", function() {
		assert_equals(case_run(case_asi_if_prefix_increment_map_true), "string:2:123", "GameMaker no longer gives the measured result");
	});
	addFact("`if (c) ++m[? \"k\"] = 123;` with c = 1 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var c = 1, m = ds_map_create();
if (c) ++m[? "k"] = 123;
var r = string(c) + ":" + string(m[? "k"]);
ds_map_destroy(m);
return r;'); }), "string:2:123", "GMLC differs from GameMaker");
	});

	addFact("`if (c) ++m[? \"k\"] = 123;` with c = 0 [GameMaker]", function() {
		assert_equals(case_run(case_asi_if_prefix_increment_map_false), "string:1:undefined", "GameMaker no longer gives the measured result");
	});
	addFact("`if (c) ++m[? \"k\"] = 123;` with c = 0 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var c = 0, m = ds_map_create();
if (c) ++m[? "k"] = 123;
var r = string(c) + ":" + string(m[? "k"]);
ds_map_destroy(m);
return r;'); }), "string:1:undefined", "GMLC differs from GameMaker");
	});

	addFact("`if (c) { ++px; }` [GameMaker]", function() {
		assert_equals(case_run(case_asi_if_prefix_increment_braced), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("`if (c) { ++px; }` [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var c = true, px = 1;
if (c) { ++px; }
return px;'); }), "number:2", "GMLC differs from GameMaker");
	});

	// `if (c) --px;`: GameMaker 2024.14.4.268 refuses to compile this:
	//   Assignment operator expected
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("`if (c) --px;` [GameMaker]", function() {
	//   var c = true, px = 1;
	//   if (c) --px;
	//   return px;
	// });
	addFact("`if (c) --px;` is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var c = true, px = 1;
if (c) --px;
return px;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// `if (c) ++ px;`: GameMaker 2024.14.4.268 refuses to compile this:
	//   Assignment operator expected
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("`if (c) ++ px;` [GameMaker]", function() {
	//   var c = true, px = 1;
	//   if (c) ++ px;
	//   return px;
	// });
	addFact("`if (c) ++ px;` is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var c = true, px = 1;
if (c) ++ px;
return px;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("`++ px;` with a space [GameMaker]", function() {
		assert_equals(case_run(case_asi_prefix_increment_spaced), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("`++ px;` with a space [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var px = 1;
++ px;
return px;'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("`px ++;` with a space [GameMaker]", function() {
		assert_equals(case_run(case_asi_postfix_increment_spaced), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("`px ++;` with a space [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var px = 1;
px ++;
return px;'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("`(px)++;` [GameMaker]", function() {
		assert_equals(case_run(case_asi_postfix_increment_paren), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("`(px)++;` [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var px = 1;
(px)++;
return px;'); }), "number:2", "GMLC differs from GameMaker");
	});

	// `repeat (2) ++px;`: GameMaker 2024.14.4.268 refuses to compile this:
	//   Assignment operator expected
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("`repeat (2) ++px;` [GameMaker]", function() {
	//   var px = 1;
	//   repeat (2) ++px;
	//   return px;
	// });
	addFact("`repeat (2) ++px;` is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var px = 1;
repeat (2) ++px;
return px;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// `while (px < 3) ++px;`: GameMaker 2024.14.4.268 refuses to compile this:
	//   Assignment operator expected
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("`while (px < 3) ++px;` [GameMaker]", function() {
	//   var px = 1;
	//   while (px < 3) ++px;
	//   return px;
	// });
	addFact("`while (px < 3) ++px;` is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var px = 1;
while (px < 3) ++px;
return px;'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// `with (s) ++v;`: GameMaker 2024.14.4.268 refuses to compile this:
	//   Assignment operator expected
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("`with (s) ++v;` [GameMaker]", function() {
	//   var s = { v: 1 };
	//   with (s) ++v;
	//   return s.v;
	// });
	addFact("`with (s) ++v;` is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { v: 1 };
with (s) ++v;
return s.v;'); }), "error", "GMLC accepts code GameMaker refuses");
	});
}

function case_asi_var_newline_name() {
var a
b = 1;
return string(a) + ":" + string(b);
}

function case_asi_minus_next_line() {
var b = 5, c = 2;
var a = b
-c;
return a;
}

function case_asi_return_newline_value() {
return
7;
}

function case_asi_call_next_line() {
var fy = function(_v) { return _v * 2; };
var fz = 3;
var fx = fy
(fz);
return fx;
}

function case_asi_two_assignments_one_line() {
var a, b;
a = 1 b = 2
return string(a) + ":" + string(b);
}

function case_asi_if_prefix_increment_map_true() {
var c = 1, m = ds_map_create();
if (c) ++m[? "k"] = 123;
var r = string(c) + ":" + string(m[? "k"]);
ds_map_destroy(m);
return r;
}

function case_asi_if_prefix_increment_map_false() {
var c = 0, m = ds_map_create();
if (c) ++m[? "k"] = 123;
var r = string(c) + ":" + string(m[? "k"]);
ds_map_destroy(m);
return r;
}

function case_asi_if_prefix_increment_braced() {
var c = true, px = 1;
if (c) { ++px; }
return px;
}

function case_asi_prefix_increment_spaced() {
var px = 1;
++ px;
return px;
}

function case_asi_postfix_increment_spaced() {
var px = 1;
px ++;
return px;
}

function case_asi_postfix_increment_paren() {
var px = 1;
(px)++;
return px;
}
