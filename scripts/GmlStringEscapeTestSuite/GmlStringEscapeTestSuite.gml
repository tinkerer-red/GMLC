// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-04.
function GmlStringEscapeTestSuite() : TestSuite() constructor {

	addFact("\\n [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_newline), "string:3:97,10,98", "GameMaker no longer gives the measured result");
	});
	addFact("\\n [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("a\nb");'); }), "string:3:97,10,98", "GMLC differs from GameMaker");
	});

	addFact("\\r and \\t [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_cr_tab), "string:2:13,9", "GameMaker no longer gives the measured result");
	});
	addFact("\\r and \\t [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\r\t");'); }), "string:2:13,9", "GMLC differs from GameMaker");
	});

	addFact("\\b and \\f [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_backspace_formfeed), "string:2:8,12", "GameMaker no longer gives the measured result");
	});
	addFact("\\b and \\f [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\b\f");'); }), "string:2:8,12", "GMLC differs from GameMaker");
	});

	addFact("\\a and \\v [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_bell_vtab), "string:2:7,11", "GameMaker no longer gives the measured result");
	});
	addFact("\\a and \\v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\a\v");'); }), "string:2:7,11", "GMLC differs from GameMaker");
	});

	addFact("\\\\ [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_backslash), "string:1:92", "GameMaker no longer gives the measured result");
	});
	addFact("\\\\ [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\\");'); }), "string:1:92", "GMLC differs from GameMaker");
	});

	addFact("\\\" and \\' [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_quotes), "string:2:34,39", "GameMaker no longer gives the measured result");
	});
	addFact("\\\" and \\' [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\"\' + "'" + @'");'); }), "string:2:34,39", "GMLC differs from GameMaker");
	});

	// \x4: GameMaker 2024.14.4.268 refuses to compile this:
	//   Error parsing \x HEX value. 2 digits required.
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("\\x4 [GameMaker]", function() {
	//   return case_ords("\x4");
	// });
	addFact("\\x4 is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\x4");'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("\\x41 [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_hex_two_digits), "string:1:65", "GameMaker no longer gives the measured result");
	});
	addFact("\\x41 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\x41");'); }), "string:1:65", "GMLC differs from GameMaker");
	});

	addFact("\\x414 [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_hex_three_digits), "string:2:65,52", "GameMaker no longer gives the measured result");
	});
	addFact("\\x414 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\x414");'); }), "string:2:65,52", "GMLC differs from GameMaker");
	});

	addFact("\\u41 [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_unicode_two_digits), "string:1:65", "GameMaker no longer gives the measured result");
	});
	addFact("\\u41 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\u41");'); }), "string:1:65", "GMLC differs from GameMaker");
	});

	addFact("\\u0041 [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_unicode_four_digits), "string:1:65", "GameMaker no longer gives the measured result");
	});
	addFact("\\u0041 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\u0041");'); }), "string:1:65", "GMLC differs from GameMaker");
	});

	addFact("\\u1F600 [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_unicode_five_digits), "string:1:128512", "GameMaker no longer gives the measured result");
	});
	addFact("\\u1F600 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\u1F600");'); }), "string:1:128512", "GMLC differs from GameMaker");
	});

	// \u110000: GameMaker 2024.14.4.268 refuses to compile this:
	//   Error parsing \u value. Unicode value invalid. between 0xd800-0xdfff OR 0x10FFFF max.
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("\\u110000 [GameMaker]", function() {
	//   return case_ords("\u110000");
	// });
	addFact("\\u110000 is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\u110000");'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("\\101 [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_octal), "string:1:65", "GameMaker no longer gives the measured result");
	});
	addFact("\\101 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\101");'); }), "string:1:65", "GMLC differs from GameMaker");
	});

	// \777: GameMaker 2024.14.4.268 refuses to compile this:
	//   Error parsing \??? OCTAL value. Value must be less than 255.
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("\\777 [GameMaker]", function() {
	//   return case_ords("\777");
	// });
	addFact("\\777 is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\777");'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("\\0 inside a string [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_nul), "string:1:97", "GameMaker no longer gives the measured result");
	});
	addFact("\\0 inside a string [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("a\0b");'); }), "string:1:97", "GMLC differs from GameMaker");
	});

	addFact("\\q [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_unknown_escape), "string:1:113", "GameMaker no longer gives the measured result");
	});
	addFact("\\q [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\q");'); }), "string:1:113", "GMLC differs from GameMaker");
	});

	addFact("\\{ and \\} in a plain string [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_brace_escapes), "string:2:123,125", "GameMaker no longer gives the measured result");
	});
	addFact("\\{ and \\} in a plain string [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\{\}");'); }), "string:2:123,125", "GMLC differs from GameMaker");
	});

	addFact("backslash before a line break [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_backslash_newline), "string:2:97,98", "GameMaker no longer gives the measured result");
	});
	addFact("backslash before a line break [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("a\
b");'); }), "string:2:97,98", "GMLC differs from GameMaker");
	});

	// line break inside a plain string: GameMaker 2024.14.4.268 refuses to compile this:
	//   Error parsing string - found newline within string
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("line break inside a plain string [GameMaker]", function() {
	//   return case_ords("a
	//   b");
	// });
	addFact("line break inside a plain string is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("a
b");'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// single-quoted plain string: GameMaker 2024.14.4.268 refuses to compile this:
	//   invalid token '
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("single-quoted plain string [GameMaker]", function() {
	//   return case_ords('ab');
	// });
	addFact("single-quoted plain string is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords(' + "'" + @'ab' + "'" + @');'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("@\"\" keeps backslashes [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_raw_no_escapes), "string:4:97,92,110,98", "GameMaker no longer gives the measured result");
	});
	addFact("@\"\" keeps backslashes [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords(@"a\nb");'); }), "string:4:97,92,110,98", "GMLC differs from GameMaker");
	});

	addFact("@'' keeps backslashes [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_raw_single_no_escapes), "string:4:97,92,110,98", "GameMaker no longer gives the measured result");
	});
	addFact("@'' keeps backslashes [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords(@' + "'" + @'a\nb' + "'" + @');'); }), "string:4:97,92,110,98", "GMLC differs from GameMaker");
	});

	addFact("@\"\" keeps a line break [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_raw_line_break), "string:3:97,10,98", "GameMaker no longer gives the measured result");
	});
	addFact("@\"\" keeps a line break [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords(@"a
b");'); }), "string:3:97,10,98", "GMLC differs from GameMaker");
	});

	// @"a""b": GameMaker 2024.14.4.268 refuses to compile this:
	//   got 'b' expected ',' or ')'
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("@\"a\"\"b\" [GameMaker]", function() {
	//   return case_ords(@"a""b");
	// });
	addFact("@\"a\"\"b\" is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords(@"a""b");'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("$\"{1 + 1}\" [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_template_expression), "string:3:120,50,121", "GameMaker no longer gives the measured result");
	});
	addFact("$\"{1 + 1}\" [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords($"x{1 + 1}y");'); }), "string:3:120,50,121", "GMLC differs from GameMaker");
	});

	addFact("\\{ in a template [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_template_brace_escape), "string:5:97,123,98,125,99", "GameMaker no longer gives the measured result");
	});
	addFact("\\{ in a template [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords($"a\{b\}c");'); }), "string:5:97,123,98,125,99", "GMLC differs from GameMaker");
	});

	addFact("\\n in a template [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_template_escape_n), "string:3:97,10,98", "GameMaker no longer gives the measured result");
	});
	addFact("\\n in a template [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords($"a\nb");'); }), "string:3:97,10,98", "GMLC differs from GameMaker");
	});

	addFact("string literal inside a template expression [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_template_string_inside), "string:2:105,110", "GameMaker no longer gives the measured result");
	});
	addFact("string literal inside a template expression [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords($"{"in"}");'); }), "string:2:105,110", "GMLC differs from GameMaker");
	});

	addFact("struct literal inside a template expression [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_template_struct_inside), "string:1:49", "GameMaker no longer gives the measured result");
	});
	addFact("struct literal inside a template expression [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords($"{ {a: 1}.a }");'); }), "string:1:49", "GMLC differs from GameMaker");
	});

	// @$"" (raw template): GameMaker 2024.14.4.268 refuses to compile this:
	//   invalid token @
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("@$\"\" (raw template) [GameMaker]", function() {
	//   return case_ords(@$"a{1}");
	// });
	addFact("@$\"\" (raw template) is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords(@$"a{1}");'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	// $@"" (template raw): GameMaker 2024.14.4.268 refuses to compile this:
	//   Hex number $ has an illegal format
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("$@\"\" (template raw) [GameMaker]", function() {
	//   return case_ords($@"a{1}");
	// });
	addFact("$@\"\" (template raw) is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords($@"a{1}");'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("\\u1F642 assigned to a variable [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_unicode_1f642_var), "string:1:128578", "GameMaker no longer gives the measured result");
	});
	addFact("\\u1F642 assigned to a variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = "\u1F642";
return case_ords(s);'); }), "string:1:128578", "GMLC differs from GameMaker");
	});

	addFact("\\u1F642 as an argument [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_unicode_1f642_arg), "string:1:128578", "GameMaker no longer gives the measured result");
	});
	addFact("\\u1F642 as an argument [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\u1F642");'); }), "string:1:128578", "GMLC differs from GameMaker");
	});

	addFact("\\u1F600 assigned to a variable [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_unicode_1f600_var), "string:1:128512", "GameMaker no longer gives the measured result");
	});
	addFact("\\u1F600 assigned to a variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = "\u1F600";
return case_ords(s);'); }), "string:1:128512", "GMLC differs from GameMaker");
	});

	addFact("\\u1F642\\u8001\\u20AC\\u41 [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_unicode_greedy_mix), "string:4:128578,32769,8364,65", "GameMaker no longer gives the measured result");
	});
	addFact("\\u1F642\\u8001\\u20AC\\u41 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\u1F642\u8001\u20AC\u41");'); }), "string:4:128578,32769,8364,65", "GMLC differs from GameMaker");
	});

	addFact("\\u10FFFF [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_unicode_six_digits), "string:1:1114111", "GameMaker no longer gives the measured result");
	});
	addFact("\\u10FFFF [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\u10FFFF");'); }), "string:1:1114111", "GMLC differs from GameMaker");
	});

	addFact("\\u0041B [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_unicode_leading_zero_five), "string:1:1051", "GameMaker no longer gives the measured result");
	});
	addFact("\\u0041B [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\u0041B");'); }), "string:1:1051", "GMLC differs from GameMaker");
	});

	// \u1234567: GameMaker 2024.14.4.268 refuses to compile this:
	//   Error parsing \u value. Unicode value invalid. between 0xd800-0xdfff OR 0x10FFFF max.
	// The GameMaker fact stays commented out so this case is not written again; GMLC must refuse it too.
	// addFact("\\u1234567 [GameMaker]", function() {
	//   return case_ords("\u1234567");
	// });
	addFact("\\u1234567 is refused [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\u1234567");'); }), "error", "GMLC accepts code GameMaker refuses");
	});

	addFact("\\u01F642 [GameMaker]", function() {
		assert_equals(case_run(case_string_escapes_unicode_six_then_more), "string:1:128578", "GameMaker no longer gives the measured result");
	});
	addFact("\\u01F642 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("\u01F642");'); }), "string:1:128578", "GMLC differs from GameMaker");
	});
}

function case_string_escapes_newline() {
return case_ords("a\nb");
}

function case_string_escapes_cr_tab() {
return case_ords("\r\t");
}

function case_string_escapes_backspace_formfeed() {
return case_ords("\b\f");
}

function case_string_escapes_bell_vtab() {
return case_ords("\a\v");
}

function case_string_escapes_backslash() {
return case_ords("\\");
}

function case_string_escapes_quotes() {
return case_ords("\"\'");
}

function case_string_escapes_hex_two_digits() {
return case_ords("\x41");
}

function case_string_escapes_hex_three_digits() {
return case_ords("\x414");
}

function case_string_escapes_unicode_two_digits() {
return case_ords("\u41");
}

function case_string_escapes_unicode_four_digits() {
return case_ords("\u0041");
}

function case_string_escapes_unicode_five_digits() {
return case_ords("\u1F600");
}

function case_string_escapes_octal() {
return case_ords("\101");
}

function case_string_escapes_nul() {
return case_ords("a\0b");
}

function case_string_escapes_unknown_escape() {
return case_ords("\q");
}

function case_string_escapes_brace_escapes() {
return case_ords("\{\}");
}

function case_string_escapes_backslash_newline() {
return case_ords("a\
b");
}

function case_string_escapes_raw_no_escapes() {
return case_ords(@"a\nb");
}

function case_string_escapes_raw_single_no_escapes() {
return case_ords(@'a\nb');
}

function case_string_escapes_raw_line_break() {
return case_ords(@"a
b");
}

function case_string_escapes_template_expression() {
return case_ords($"x{1 + 1}y");
}

function case_string_escapes_template_brace_escape() {
return case_ords($"a\{b\}c");
}

function case_string_escapes_template_escape_n() {
return case_ords($"a\nb");
}

function case_string_escapes_template_string_inside() {
return case_ords($"{"in"}");
}

function case_string_escapes_template_struct_inside() {
return case_ords($"{ {a: 1}.a }");
}

function case_string_escapes_unicode_1f642_var() {
var s = "\u1F642";
return case_ords(s);
}

function case_string_escapes_unicode_1f642_arg() {
return case_ords("\u1F642");
}

function case_string_escapes_unicode_1f600_var() {
var s = "\u1F600";
return case_ords(s);
}

function case_string_escapes_unicode_greedy_mix() {
return case_ords("\u1F642\u8001\u20AC\u41");
}

function case_string_escapes_unicode_six_digits() {
return case_ords("\u10FFFF");
}

function case_string_escapes_unicode_leading_zero_five() {
return case_ords("\u0041B");
}

function case_string_escapes_unicode_six_then_more() {
return case_ords("\u01F642");
}
