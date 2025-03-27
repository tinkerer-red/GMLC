function BasicEscapeCharacterTestSuite() : TestSuite() constructor {
	
	addFact("Hex escape sequences (\\x)", function() {
		compile_and_execute(@'
			var s = "\x41\x20\x5a";
			assert_equals("\x41\x20\x5A", chr(0x41) + chr(0x20) + chr(0x5A), "Hex escape sequence \\x failed.");
		')
	});

	addFact("Unicode escape sequences (\\u)", function() {
		compile_and_execute(@'
			var s = "\u0041\u0020\u005A";
			assert_equals(s, "A Z", "Unicode escape sequence \\u failed.");
		')
	});

	addFact("Full-width Unicode escape (\\uFFFF)", function() {
		compile_and_execute(@'
			var s = "\uffff";
			assert_equals(string_length(s), 1, "Unicode character \\uffff should be one character long.");
		')
	});

	addFact("Newline escape (\\n)", function() {
		compile_and_execute(@'
			assert_equals("\n", chr(10), "Newline \\n not correctly interpreted.");
		')
	});

	addFact("Carriage return escape (\\r)", function() {
		compile_and_execute(@'
			assert_equals("\r", chr(13), "Carriage return \\r not correctly interpreted.");
		')
	});

	addFact("Tab escape (\\t)", function() {
		compile_and_execute(@'
			assert_equals("\t", chr(9), "Tab \\t not correctly interpreted.");
		')
	});

	addFact("Form feed escape (\\f)", function() {
		compile_and_execute(@'
			assert_equals("\f", chr(12), "Form feed \\f not correctly interpreted.");
		')
	});

	addFact("Vertical tab escape (\\v)", function() {
		compile_and_execute(@'
			assert_equals("\v",	chr(11), "Vertical tab \\v not correctly interpreted.");
		')
	});

	addFact("Backspace escape (\\b)", function() {
		compile_and_execute(@'
			assert_equals("\b",	chr(8), "Backspace \\b not correctly interpreted.");
		')
	});

	addFact("Null escape (\\0)", function() {
		compile_and_execute(@'
			assert_equals("\0",	chr(0), "Null escape \\0 not correctly interpreted.");
		')
	});
}
