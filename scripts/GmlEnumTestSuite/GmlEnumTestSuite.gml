// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-05.
function GmlEnumTestSuite() : TestSuite() constructor {

	addFact("a member with a plain number [GameMaker]", function() {
		assert_equals(case_run(case_enums_plain), "string:int64:1", "GameMaker no longer gives the measured result");
	});
	addFact("a member with a plain number [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnPlain { X = 1 }
return typeof(CaseEnPlain.X) + ":" + string(CaseEnPlain.X);'); }), "string:int64:1", "GMLC differs from GameMaker");
	});

	addFact("members without a value count up from the previous one [GameMaker]", function() {
		assert_equals(case_run(case_enums_auto), "string:int64:11", "GameMaker no longer gives the measured result");
	});
	addFact("members without a value count up from the previous one [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnAuto { A, B = 10, C }
return typeof(CaseEnAuto.C) + ":" + string(CaseEnAuto.C);'); }), "string:int64:11", "GMLC differs from GameMaker");
	});

	addFact("arithmetic on constants [GameMaker]", function() {
		assert_equals(case_run(case_enums_arith), "string:int64:7", "GameMaker no longer gives the measured result");
	});
	addFact("arithmetic on constants [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnArith { X = 1 + 2 * 3 }
return typeof(CaseEnArith.X) + ":" + string(CaseEnArith.X);'); }), "string:int64:7", "GMLC differs from GameMaker");
	});

	addFact("a ternary on constants [GameMaker]", function() {
		assert_equals(case_run(case_enums_ternary), "string:int64:5", "GameMaker no longer gives the measured result");
	});
	addFact("a ternary on constants [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnTern { X = 1 > 0 ? 5 : 6 }
return typeof(CaseEnTern.X) + ":" + string(CaseEnTern.X);'); }), "string:int64:5", "GMLC differs from GameMaker");
	});

	addFact("a negative value [GameMaker]", function() {
		assert_equals(case_run(case_enums_negative), "string:int64:-3", "GameMaker no longer gives the measured result");
	});
	addFact("a negative value [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnNeg { X = -3 }
return typeof(CaseEnNeg.X) + ":" + string(CaseEnNeg.X);'); }), "string:int64:-3", "GMLC differs from GameMaker");
	});

	addFact("a hex literal of 2^31 [GameMaker]", function() {
		assert_equals(case_run(case_enums_hex_big), "string:int64:2147483648", "GameMaker no longer gives the measured result");
	});
	addFact("a hex literal of 2^31 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnHex { X = $80000000 }
return typeof(CaseEnHex.X) + ":" + string(CaseEnHex.X);'); }), "string:int64:2147483648", "GMLC differs from GameMaker");
	});

	addFact("a fractional value [GameMaker]", function() {
		assert_equals(case_run(case_enums_float), "string:int64:1", "GameMaker no longer gives the measured result");
	});
	addFact("a fractional value [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnFloat { X = 1.5 }
return typeof(CaseEnFloat.X) + ":" + string(CaseEnFloat.X);'); }), "string:int64:1", "GMLC differs from GameMaker");
	});

	addFact("a bool [GameMaker]", function() {
		assert_equals(case_run(case_enums_bool), "string:int64:1", "GameMaker no longer gives the measured result");
	});
	addFact("a bool [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnBool { X = true }
return typeof(CaseEnBool.X) + ":" + string(CaseEnBool.X);'); }), "string:int64:1", "GMLC differs from GameMaker");
	});

	// a string: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   enum assignment must be an integer constant
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("a string [GameMaker]", function() {
	//   enum CaseEnStr { X = "a" }
	//   return typeof(CaseEnStr.X) + ":" + string(CaseEnStr.X);
	// });
	addFact("a string is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnStr { X = "a" }
return typeof(CaseEnStr.X) + ":" + string(CaseEnStr.X);'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// a previous member of the same enum: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   enum assignment must be an integer constant
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a previous member of the same enum [GameMaker]", function() {
	//   enum CaseEnPrev { A = 2, B = A * 3 }
	//   return typeof(CaseEnPrev.B) + ":" + string(CaseEnPrev.B);
	// });

	addFact("a previous member written E.A [GameMaker]", function() {
		assert_equals(case_run(case_enums_prev_member_qualified), "string:int64:3", "GameMaker no longer gives the measured result");
	});
	addFact("a previous member written E.A [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnPrevQ { A = 2, B = CaseEnPrevQ.A + 1 }
return typeof(CaseEnPrevQ.B) + ":" + string(CaseEnPrevQ.B);'); }), "string:int64:3", "GMLC differs from GameMaker");
	});

	addFact("a member of another enum [GameMaker]", function() {
		assert_equals(case_run(case_enums_other_enum), "string:int64:5", "GameMaker no longer gives the measured result");
	});
	addFact("a member of another enum [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnOtherA { X = 4 }
enum CaseEnOtherB { Y = CaseEnOtherA.X + 1 }
return typeof(CaseEnOtherB.Y) + ":" + string(CaseEnOtherB.Y);'); }), "string:int64:5", "GMLC differs from GameMaker");
	});

	addFact("a macro [GameMaker]", function() {
		assert_equals(case_run(case_enums_macro), "string:int64:7", "GameMaker no longer gives the measured result");
	});
	addFact("a macro [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'#macro CASE_EN_MACRO 7
enum CaseEnMacro { X = CASE_EN_MACRO }
return typeof(CaseEnMacro.X) + ":" + string(CaseEnMacro.X);'); }), "string:int64:7", "GMLC differs from GameMaker");
	});

	addFact("a built-in constant [GameMaker]", function() {
		assert_equals(case_run(case_enums_builtin_constant), "string:int64:255", "GameMaker no longer gives the measured result");
	});
	addFact("a built-in constant [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnBuiltinConst { X = c_red }
return typeof(CaseEnBuiltinConst.X) + ":" + string(CaseEnBuiltinConst.X);'); }), "string:int64:255", "GMLC differs from GameMaker");
	});

	addFact("string_length of a literal [GameMaker]", function() {
		assert_equals(case_run(case_enums_string_length), "string:int64:3", "GameMaker no longer gives the measured result");
	});
	addFact("string_length of a literal [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnStrLen { X = string_length("abc") }
return typeof(CaseEnStrLen.X) + ":" + string(CaseEnStrLen.X);'); }), "string:int64:3", "GMLC differs from GameMaker");
	});

	addFact("ord of a literal [GameMaker]", function() {
		assert_equals(case_run(case_enums_ord), "string:int64:65", "GameMaker no longer gives the measured result");
	});
	addFact("ord of a literal [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnOrd { X = ord("A") }
return typeof(CaseEnOrd.X) + ":" + string(CaseEnOrd.X);'); }), "string:int64:65", "GMLC differs from GameMaker");
	});

	addFact("real of a string literal [GameMaker]", function() {
		assert_equals(case_run(case_enums_real_of_string), "string:int64:5", "GameMaker no longer gives the measured result");
	});
	addFact("real of a string literal [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnReal { X = real("5") }
return typeof(CaseEnReal.X) + ":" + string(CaseEnReal.X);'); }), "string:int64:5", "GMLC differs from GameMaker");
	});

	addFact("abs and floor of literals [GameMaker]", function() {
		assert_equals(case_run(case_enums_abs_floor), "string:int64:6", "GameMaker no longer gives the measured result");
	});
	addFact("abs and floor of literals [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnAbs { X = abs(-4) + floor(2.7) }
return typeof(CaseEnAbs.X) + ":" + string(CaseEnAbs.X);'); }), "string:int64:6", "GMLC differs from GameMaker");
	});

	// a built-in GameMaker does not fold (string_pos): GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   enum assignment must be an integer constant
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a built-in GameMaker does not fold (string_pos) [GameMaker]", function() {
	//   enum CaseEnPos { X = string_pos("b", "abc") }
	//   return typeof(CaseEnPos.X) + ":" + string(CaseEnPos.X);
	// });

	// irandom: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   enum assignment must be an integer constant
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("irandom [GameMaker]", function() {
	//   enum CaseEnRand { X = irandom(0) }
	//   return typeof(CaseEnRand.X) + ":" + string(CaseEnRand.X);
	// });

	// a user function: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   enum assignment must be an integer constant
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a user function [GameMaker]", function() {
	//   enum CaseEnUser { X = case_sum3(1, 2, 3) }
	//   return typeof(CaseEnUser.X) + ":" + string(CaseEnUser.X);
	// });

	// a local variable: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   enum assignment must be an integer constant
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a local variable [GameMaker]", function() {
	//   var v = 5;
	//   enum CaseEnLocal { X = v }
	//   return typeof(CaseEnLocal.X) + ":" + string(CaseEnLocal.X);
	// });

	// a global variable: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   enum assignment must be an integer constant
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a global variable [GameMaker]", function() {
	//   global.case_en_g = 5;
	//   enum CaseEnGlobal { X = global.case_en_g }
	//   return typeof(CaseEnGlobal.X) + ":" + string(CaseEnGlobal.X);
	// });

	addFact("a member after one set by a call counts up from it [GameMaker]", function() {
		assert_equals(case_run(case_enums_auto_after_call), "string:int64:3", "GameMaker no longer gives the measured result");
	});
	addFact("a member after one set by a call counts up from it [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnAutoCall { A = string_length("ab"), B }
return typeof(CaseEnAutoCall.B) + ":" + string(CaseEnAutoCall.B);'); }), "string:int64:3", "GMLC differs from GameMaker");
	});

	addFact("a member used above its enum [GameMaker]", function() {
		assert_equals(case_run(case_enums_used_before_declared), "string:int64:9", "GameMaker no longer gives the measured result");
	});
	addFact("a member used above its enum [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = typeof(CaseEnLater.X) + ":" + string(CaseEnLater.X);
enum CaseEnLater { X = 9 }
return r;'); }), "string:int64:9", "GMLC differs from GameMaker");
	});

	addFact("a member plus a number literal [GameMaker]", function() {
		assert_equals(case_run(case_enums_member_plus_one), "string:number:5", "GameMaker no longer gives the measured result");
	});
	addFact("a member plus a number literal [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnPlus { X = 4 }
return typeof(CaseEnPlus.X + 1) + ":" + string(CaseEnPlus.X + 1);'); }), "string:number:5", "GMLC differs from GameMaker");
	});

	addFact("a member times a fractional literal [GameMaker]", function() {
		assert_equals(case_run(case_enums_member_times_real), "string:number:1.50", "GameMaker no longer gives the measured result");
	});
	addFact("a member times a fractional literal [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnTimes { X = 3 }
return typeof(CaseEnTimes.X * 0.5) + ":" + string(CaseEnTimes.X * 0.5);'); }), "string:number:1.50", "GMLC differs from GameMaker");
	});

	addFact("a member stored in a variable [GameMaker]", function() {
		assert_equals(case_run(case_enums_member_in_variable), "string:int64:6", "GameMaker no longer gives the measured result");
	});
	addFact("a member stored in a variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnVar { X = 6 }
var v = CaseEnVar.X;
return typeof(v) + ":" + string(v);'); }), "string:int64:6", "GMLC differs from GameMaker");
	});

	addFact("a folded built-in with two arguments (max) [GameMaker]", function() {
		assert_equals(case_run(case_enums_max_two_args), "string:int64:3", "GameMaker no longer gives the measured result");
	});
	addFact("a folded built-in with two arguments (max) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'enum CaseEnMax { X = max(1, 2), Y }
return typeof(CaseEnMax.Y) + ":" + string(CaseEnMax.Y);'); }), "string:int64:3", "GMLC differs from GameMaker");
	});

	// array_length of an array literal: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-05):
	//   enum assignment must be an integer constant
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("array_length of an array literal [GameMaker]", function() {
	//   enum CaseEnArrLen { X = array_length([1, 2, 3]) }
	//   return typeof(CaseEnArrLen.X) + ":" + string(CaseEnArrLen.X);
	// });
}

function case_enums_plain() {
enum CaseEnPlain { X = 1 }
return typeof(CaseEnPlain.X) + ":" + string(CaseEnPlain.X);
}

function case_enums_auto() {
enum CaseEnAuto { A, B = 10, C }
return typeof(CaseEnAuto.C) + ":" + string(CaseEnAuto.C);
}

function case_enums_arith() {
enum CaseEnArith { X = 1 + 2 * 3 }
return typeof(CaseEnArith.X) + ":" + string(CaseEnArith.X);
}

function case_enums_ternary() {
enum CaseEnTern { X = 1 > 0 ? 5 : 6 }
return typeof(CaseEnTern.X) + ":" + string(CaseEnTern.X);
}

function case_enums_negative() {
enum CaseEnNeg { X = -3 }
return typeof(CaseEnNeg.X) + ":" + string(CaseEnNeg.X);
}

function case_enums_hex_big() {
enum CaseEnHex { X = $80000000 }
return typeof(CaseEnHex.X) + ":" + string(CaseEnHex.X);
}

function case_enums_float() {
enum CaseEnFloat { X = 1.5 }
return typeof(CaseEnFloat.X) + ":" + string(CaseEnFloat.X);
}

function case_enums_bool() {
enum CaseEnBool { X = true }
return typeof(CaseEnBool.X) + ":" + string(CaseEnBool.X);
}

function case_enums_prev_member_qualified() {
enum CaseEnPrevQ { A = 2, B = CaseEnPrevQ.A + 1 }
return typeof(CaseEnPrevQ.B) + ":" + string(CaseEnPrevQ.B);
}

function case_enums_other_enum() {
enum CaseEnOtherA { X = 4 }
enum CaseEnOtherB { Y = CaseEnOtherA.X + 1 }
return typeof(CaseEnOtherB.Y) + ":" + string(CaseEnOtherB.Y);
}

function case_enums_macro() {
#macro CASE_EN_MACRO 7
enum CaseEnMacro { X = CASE_EN_MACRO }
return typeof(CaseEnMacro.X) + ":" + string(CaseEnMacro.X);
}

function case_enums_builtin_constant() {
enum CaseEnBuiltinConst { X = c_red }
return typeof(CaseEnBuiltinConst.X) + ":" + string(CaseEnBuiltinConst.X);
}

function case_enums_string_length() {
enum CaseEnStrLen { X = string_length("abc") }
return typeof(CaseEnStrLen.X) + ":" + string(CaseEnStrLen.X);
}

function case_enums_ord() {
enum CaseEnOrd { X = ord("A") }
return typeof(CaseEnOrd.X) + ":" + string(CaseEnOrd.X);
}

function case_enums_real_of_string() {
enum CaseEnReal { X = real("5") }
return typeof(CaseEnReal.X) + ":" + string(CaseEnReal.X);
}

function case_enums_abs_floor() {
enum CaseEnAbs { X = abs(-4) + floor(2.7) }
return typeof(CaseEnAbs.X) + ":" + string(CaseEnAbs.X);
}

function case_enums_auto_after_call() {
enum CaseEnAutoCall { A = string_length("ab"), B }
return typeof(CaseEnAutoCall.B) + ":" + string(CaseEnAutoCall.B);
}

function case_enums_used_before_declared() {
var r = typeof(CaseEnLater.X) + ":" + string(CaseEnLater.X);
enum CaseEnLater { X = 9 }
return r;
}

function case_enums_member_plus_one() {
enum CaseEnPlus { X = 4 }
return typeof(CaseEnPlus.X + 1) + ":" + string(CaseEnPlus.X + 1);
}

function case_enums_member_times_real() {
enum CaseEnTimes { X = 3 }
return typeof(CaseEnTimes.X * 0.5) + ":" + string(CaseEnTimes.X * 0.5);
}

function case_enums_member_in_variable() {
enum CaseEnVar { X = 6 }
var v = CaseEnVar.X;
return typeof(v) + ":" + string(v);
}

function case_enums_max_two_args() {
enum CaseEnMax { X = max(1, 2), Y }
return typeof(CaseEnMax.Y) + ":" + string(CaseEnMax.Y);
}
