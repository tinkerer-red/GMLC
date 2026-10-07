// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-06.
function GmlPrecedenceTestSuite() : TestSuite() constructor {

	addFact("?? is looser than || [GameMaker]", function() {
		assert_equals(case_run(case_precedence_nullish_below_or), "number:0", "GameMaker no longer gives the measured result");
	});
	addFact("?? is looser than || [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 0 ?? 0 || 1;'); }), "number:0", "GMLC differs from GameMaker");
	});

	addFact("^^ is tighter than || [GameMaker]", function() {
		assert_equals(case_run(case_precedence_xor_above_or), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("^^ is tighter than || [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return true || false ^^ true;'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("^^ is tighter than && (xor first) [GameMaker]", function() {
		assert_equals(case_run(case_precedence_xor_above_and_left), "number:0", "GameMaker no longer gives the measured result");
	});
	addFact("^^ is tighter than && (xor first) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return true ^^ true && false;'); }), "number:0", "GMLC differs from GameMaker");
	});

	addFact("^^ is tighter than && (and first) [GameMaker]", function() {
		assert_equals(case_run(case_precedence_xor_above_and_right), "number:0", "GameMaker no longer gives the measured result");
	});
	addFact("^^ is tighter than && (and first) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return false && true ^^ true;'); }), "number:0", "GMLC differs from GameMaker");
	});

	addFact("&& is tighter than || [GameMaker]", function() {
		assert_equals(case_run(case_precedence_and_above_or), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("&& is tighter than || [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return true || true && false;'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("?? is looser than && [GameMaker]", function() {
		assert_equals(case_run(case_precedence_nullish_below_and), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("?? is looser than && [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 5 ?? 0 && 0;'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("?? is looser than ^^ [GameMaker]", function() {
		assert_equals(case_run(case_precedence_nullish_below_xor), "number:0", "GameMaker no longer gives the measured result");
	});
	addFact("?? is looser than ^^ [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 0 ?? 1 ^^ 1;'); }), "number:0", "GMLC differs from GameMaker");
	});

	addFact("?: is looser than ?? [GameMaker]", function() {
		assert_equals(case_run(case_precedence_ternary_below_nullish), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("?: is looser than ?? [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 0 ?? 1 ? 2 : 3;'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("| is tighter than == [GameMaker]", function() {
		assert_equals(case_run(case_precedence_bitor_above_equal), "bool:0", "GameMaker no longer gives the measured result");
	});
	addFact("| is tighter than == [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 1 | 2 == 2;'); }), "bool:0", "GMLC differs from GameMaker");
	});

	addFact("& is tighter than == [GameMaker]", function() {
		assert_equals(case_run(case_precedence_bitand_above_equal), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("& is tighter than == [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 6 & 3 == 2;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("| is tighter than < [GameMaker]", function() {
		assert_equals(case_run(case_precedence_bitor_above_less), "bool:0", "GameMaker no longer gives the measured result");
	});
	addFact("| is tighter than < [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 1 | 2 < 3;'); }), "bool:0", "GMLC differs from GameMaker");
	});

	addFact("| and & share a tier [GameMaker]", function() {
		assert_equals(case_run(case_precedence_bitwise_one_tier_or_and), "number:0", "GameMaker no longer gives the measured result");
	});
	addFact("| and & share a tier [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 1 | 2 & 0;'); }), "number:0", "GMLC differs from GameMaker");
	});

	addFact("| and ^ share a tier [GameMaker]", function() {
		assert_equals(case_run(case_precedence_bitwise_one_tier_or_xor), "number:0", "GameMaker no longer gives the measured result");
	});
	addFact("| and ^ share a tier [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 1 | 1 ^ 1;'); }), "number:0", "GMLC differs from GameMaker");
	});

	addFact("^ and & share a tier [GameMaker]", function() {
		assert_equals(case_run(case_precedence_bitwise_one_tier_xor_and), "number:0", "GameMaker no longer gives the measured result");
	});
	addFact("^ and & share a tier [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 1 ^ 1 & 0;'); }), "number:0", "GMLC differs from GameMaker");
	});

	addFact("<< is tighter than | [GameMaker]", function() {
		assert_equals(case_run(case_precedence_shift_above_bitor), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("<< is tighter than | [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 1 | 2 << 1;'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("<< is tighter than < [GameMaker]", function() {
		assert_equals(case_run(case_precedence_shift_above_less), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("<< is tighter than < [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 3 < 2 << 1;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("+ is tighter than & [GameMaker]", function() {
		assert_equals(case_run(case_precedence_additive_above_bitand), "number:0", "GameMaker no longer gives the measured result");
	});
	addFact("+ is tighter than & [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 2 & 3 + 1;'); }), "number:0", "GMLC differs from GameMaker");
	});

	addFact("< and == share a tier (less first) [GameMaker]", function() {
		assert_equals(case_run(case_precedence_equality_relational_one_tier_a), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("< and == share a tier (less first) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 2 < 3 == 1;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("< and == share a tier (equal first) [GameMaker]", function() {
		assert_equals(case_run(case_precedence_equality_relational_one_tier_b), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("< and == share a tier (equal first) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 0 == 1 < 2;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("!= and > share a tier [GameMaker]", function() {
		assert_equals(case_run(case_precedence_equality_relational_one_tier_c), "bool:0", "GameMaker no longer gives the measured result");
	});
	addFact("!= and > share a tier [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 3 != 2 > 1;'); }), "bool:0", "GMLC differs from GameMaker");
	});

	addFact("+ is tighter than << [GameMaker]", function() {
		assert_equals(case_run(case_precedence_additive_above_shift), "number:8", "GameMaker no longer gives the measured result");
	});
	addFact("+ is tighter than << [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 1 << 2 + 1;'); }), "number:8", "GMLC differs from GameMaker");
	});

	addFact("* and mod are tighter than + [GameMaker]", function() {
		assert_equals(case_run(case_precedence_multiplicative_tier), "number:4", "GameMaker no longer gives the measured result");
	});
	addFact("* and mod are tighter than + [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 2 + 3 * 4 mod 5;'); }), "number:4", "GMLC differs from GameMaker");
	});

	addFact("prefix ! binds before + [GameMaker]", function() {
		assert_equals(case_run(case_precedence_prefix_not_before_plus), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("prefix ! binds before + [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return !0 + 1;'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("! is tighter than == [GameMaker]", function() {
		assert_equals(case_run(case_precedence_prefix_not_above_equal), "bool:0", "GameMaker no longer gives the measured result");
	});
	addFact("! is tighter than == [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return !0 == 2;'); }), "bool:0", "GMLC differs from GameMaker");
	});

	addFact("~ is tighter than & [GameMaker]", function() {
		assert_equals(case_run(case_precedence_prefix_tilde_above_bitand), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("~ is tighter than & [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return ~0 & 3;'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("a = b = c assigns a the comparison of b and c [GameMaker]", function() {
		assert_equals(case_run(case_precedence_chained_assign), "array:[ 0,2 ]", "GameMaker no longer gives the measured result");
	});
	addFact("a = b = c assigns a the comparison of b and c [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var b = 2;
var c = 3;
var a = 0;
a = b = c;
return [a, b];'); }), "array:[ 0,2 ]", "GMLC differs from GameMaker");
	});

	addFact("= in a condition compares, below || [GameMaker]", function() {
		assert_equals(case_run(case_precedence_equal_in_condition_with_or), "string:taken", "GameMaker no longer gives the measured result");
	});
	addFact("= in a condition compares, below || [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var x1 = 1;
var y1 = 0;
if (x1 = 0 || y1 = 0) return "taken";
return "not taken";'); }), "string:taken", "GMLC differs from GameMaker");
	});

	addFact("= in a return value compares [GameMaker]", function() {
		assert_equals(case_run(case_precedence_equal_in_return), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("= in a return value compares [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var p = "";
return p = "";'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("= in a ternary test compares [GameMaker]", function() {
		assert_equals(case_run(case_precedence_equal_in_ternary_test), "string:one", "GameMaker no longer gives the measured result");
	});
	addFact("= in a ternary test compares [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = 1;
return f = 1 ? "one" : "other";'); }), "string:one", "GMLC differs from GameMaker");
	});

	// a ternary in the false branch of a ternary: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   unexpected symbol "?" in expression
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a ternary in the false branch of a ternary [GameMaker]", function() {
	//   return false ? 1 : true ? 2 : 3;
	// });
	addFact("a ternary in the false branch of a ternary [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return false ? 1 : true ? 2 : 3;'); }), "number:2", "GMLC no longer gives its result");
	});

	addFact("& and | share a tier (& first) [GameMaker]", function() {
		assert_equals(case_run(case_precedence_bitwise_one_tier_and_or), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("& and | share a tier (& first) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 2 & 0 | 1;'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("& and ^ share a tier (& first) [GameMaker]", function() {
		assert_equals(case_run(case_precedence_bitwise_one_tier_and_xor), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("& and ^ share a tier (& first) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 0 & 1 ^ 1;'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("^ and | share a tier (^ first) [GameMaker]", function() {
		assert_equals(case_run(case_precedence_bitwise_one_tier_xor_or), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("^ and | share a tier (^ first) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return 1 ^ 1 | 1;'); }), "number:1", "GMLC differs from GameMaker");
	});

	// three ternaries chained in false branches: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   unexpected symbol "?" in expression
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("three ternaries chained in false branches [GameMaker]", function() {
	//   return false ? 1 : false ? 2 : true ? 3 : 4;
	// });
	addFact("three ternaries chained in false branches [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return false ? 1 : false ? 2 : true ? 3 : 4;'); }), "number:3", "GMLC no longer gives its result");
	});

	// a ternary in the false branch is not reached when the test is true: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   unexpected symbol "?" in expression
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a ternary in the false branch is not reached when the test is true [GameMaker]", function() {
	//   return true ? 1 : false ? 2 : 3;
	// });
	addFact("a ternary in the false branch is not reached when the test is true [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return true ? 1 : false ? 2 : 3;'); }), "number:1", "GMLC no longer gives its result");
	});
}

function case_precedence_nullish_below_or() {
return 0 ?? 0 || 1;
}

function case_precedence_xor_above_or() {
return true || false ^^ true;
}

function case_precedence_xor_above_and_left() {
return true ^^ true && false;
}

function case_precedence_xor_above_and_right() {
return false && true ^^ true;
}

function case_precedence_and_above_or() {
return true || true && false;
}

function case_precedence_nullish_below_and() {
return 5 ?? 0 && 0;
}

function case_precedence_nullish_below_xor() {
return 0 ?? 1 ^^ 1;
}

function case_precedence_ternary_below_nullish() {
return 0 ?? 1 ? 2 : 3;
}

function case_precedence_bitor_above_equal() {
return 1 | 2 == 2;
}

function case_precedence_bitand_above_equal() {
return 6 & 3 == 2;
}

function case_precedence_bitor_above_less() {
return 1 | 2 < 3;
}

function case_precedence_bitwise_one_tier_or_and() {
return 1 | 2 & 0;
}

function case_precedence_bitwise_one_tier_or_xor() {
return 1 | 1 ^ 1;
}

function case_precedence_bitwise_one_tier_xor_and() {
return 1 ^ 1 & 0;
}

function case_precedence_shift_above_bitor() {
return 1 | 2 << 1;
}

function case_precedence_shift_above_less() {
return 3 < 2 << 1;
}

function case_precedence_additive_above_bitand() {
return 2 & 3 + 1;
}

function case_precedence_equality_relational_one_tier_a() {
return 2 < 3 == 1;
}

function case_precedence_equality_relational_one_tier_b() {
return 0 == 1 < 2;
}

function case_precedence_equality_relational_one_tier_c() {
return 3 != 2 > 1;
}

function case_precedence_additive_above_shift() {
return 1 << 2 + 1;
}

function case_precedence_multiplicative_tier() {
return 2 + 3 * 4 mod 5;
}

function case_precedence_prefix_not_before_plus() {
return !0 + 1;
}

function case_precedence_prefix_not_above_equal() {
return !0 == 2;
}

function case_precedence_prefix_tilde_above_bitand() {
return ~0 & 3;
}

function case_precedence_chained_assign() {
var b = 2;
var c = 3;
var a = 0;
a = b = c;
return [a, b];
}

function case_precedence_equal_in_condition_with_or() {
var x1 = 1;
var y1 = 0;
if (x1 = 0 || y1 = 0) return "taken";
return "not taken";
}

function case_precedence_equal_in_return() {
var p = "";
return p = "";
}

function case_precedence_equal_in_ternary_test() {
var f = 1;
return f = 1 ? "one" : "other";
}

function case_precedence_bitwise_one_tier_and_or() {
return 2 & 0 | 1;
}

function case_precedence_bitwise_one_tier_and_xor() {
return 0 & 1 ^ 1;
}

function case_precedence_bitwise_one_tier_xor_or() {
return 1 ^ 1 | 1;
}
