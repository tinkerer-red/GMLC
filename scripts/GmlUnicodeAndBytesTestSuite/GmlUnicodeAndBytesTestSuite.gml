// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-04.
function GmlUnicodeAndBytesTestSuite() : TestSuite() constructor {

	addFact("string_length of one emoji [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_emoji_length), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("string_length of one emoji [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string_length("😀");'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("string_byte_length of one emoji [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_emoji_byte_length), "number:4", "GameMaker no longer gives the measured result");
	});
	addFact("string_byte_length of one emoji [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string_byte_length("😀");'); }), "number:4", "GMLC differs from GameMaker");
	});

	addFact("ord of one emoji [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_emoji_ord), "number:128512", "GameMaker no longer gives the measured result");
	});
	addFact("ord of one emoji [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return ord("😀");'); }), "number:128512", "GMLC differs from GameMaker");
	});

	addFact("characters of a string with an emoji [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_emoji_chars), "string:3:97,128512,98", "GameMaker no longer gives the measured result");
	});
	addFact("characters of a string with an emoji [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords("a😀b");'); }), "string:3:97,128512,98", "GMLC differs from GameMaker");
	});

	addFact("string_char_at after an emoji [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_emoji_char_at), "string:b", "GameMaker no longer gives the measured result");
	});
	addFact("string_char_at after an emoji [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string_char_at("a😀b", 3);'); }), "string:b", "GMLC differs from GameMaker");
	});

	addFact("string_pos after an emoji [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_emoji_pos), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("string_pos after an emoji [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string_pos("b", "a😀b");'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("chr of an emoji code point [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_emoji_chr), "string:1:128512", "GameMaker no longer gives the measured result");
	});
	addFact("chr of an emoji code point [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_ords(chr(128512));'); }), "string:1:128512", "GMLC differs from GameMaker");
	});

	addFact("string_length of an accented letter [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_accent_length), "number:1", "GameMaker no longer gives the measured result");
	});
	addFact("string_length of an accented letter [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return string_length("é");'); }), "number:1", "GMLC differs from GameMaker");
	});

	addFact("bytes of 1.0 [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_f64_one), "string:3FF0000000000000", "GameMaker no longer gives the measured result");
	});
	addFact("bytes of 1.0 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_f64_hex(1);'); }), "string:3FF0000000000000", "GMLC differs from GameMaker");
	});

	addFact("bytes of -0.0 [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_f64_negative_zero), "string:8000000000000000", "GameMaker no longer gives the measured result");
	});
	addFact("bytes of -0.0 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_f64_hex(-1 / infinity);'); }), "string:8000000000000000", "GMLC differs from GameMaker");
	});

	addFact("bytes of NaN [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_f64_nan), "string:7FF8000000000000", "GameMaker no longer gives the measured result");
	});
	addFact("bytes of NaN [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_f64_hex(NaN);'); }), "string:7FF8000000000000", "GMLC differs from GameMaker");
	});

	addFact("bytes of infinity [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_f64_infinity), "string:7FF0000000000000", "GameMaker no longer gives the measured result");
	});
	addFact("bytes of infinity [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_f64_hex(infinity);'); }), "string:7FF0000000000000", "GMLC differs from GameMaker");
	});

	addFact("bytes of 10^300 [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_f64_large), "string:7E37E43C8800759C", "GameMaker no longer gives the measured result");
	});
	addFact("bytes of 10^300 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_f64_hex(power(10, 300));'); }), "string:7E37E43C8800759C", "GMLC differs from GameMaker");
	});

	addFact("bytes of 0.1 [GameMaker]", function() {
		assert_equals(case_run(case_unicode_and_bytes_f64_tenth), "string:3FB999999999999A", "GameMaker no longer gives the measured result");
	});
	addFact("bytes of 0.1 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return case_f64_hex(0.1);'); }), "string:3FB999999999999A", "GMLC differs from GameMaker");
	});
}

function case_unicode_and_bytes_emoji_length() {
return string_length("😀");
}

function case_unicode_and_bytes_emoji_byte_length() {
return string_byte_length("😀");
}

function case_unicode_and_bytes_emoji_ord() {
return ord("😀");
}

function case_unicode_and_bytes_emoji_chars() {
return case_ords("a😀b");
}

function case_unicode_and_bytes_emoji_char_at() {
return string_char_at("a😀b", 3);
}

function case_unicode_and_bytes_emoji_pos() {
return string_pos("b", "a😀b");
}

function case_unicode_and_bytes_emoji_chr() {
return case_ords(chr(128512));
}

function case_unicode_and_bytes_accent_length() {
return string_length("é");
}

function case_unicode_and_bytes_f64_one() {
return case_f64_hex(1);
}

function case_unicode_and_bytes_f64_negative_zero() {
return case_f64_hex(-1 / infinity);
}

function case_unicode_and_bytes_f64_nan() {
return case_f64_hex(NaN);
}

function case_unicode_and_bytes_f64_infinity() {
return case_f64_hex(infinity);
}

function case_unicode_and_bytes_f64_large() {
return case_f64_hex(power(10, 300));
}

function case_unicode_and_bytes_f64_tenth() {
return case_f64_hex(0.1);
}
