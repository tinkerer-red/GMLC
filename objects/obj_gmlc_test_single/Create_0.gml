/// @description Standalone GML test for identifier/keyword/enum/struct/macro edge cases
/// Run this in a real GML project (NOT inside GMLC) to verify expected behavior
env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
program = env.compile(@'
function assert_eq(a, b, msg){
    if (a == b) {
		show_debug_message("PASS: " + msg);
	}
    else {
		show_debug_message("FAIL: " + msg + " | got: " + string(a) + " expected: " + string(b));
	}
}

// ============================================================
// SECTION 1: STRUCT LITERAL KEYS
// Tests what is valid as a struct key in real GML
// GMLC must match this behavior
// ============================================================

// 1a. Normal identifier as struct key
var _s1 = { foo: 10 };
assert_eq(_s1[$ "foo"], 10, "struct key: plain identifier")

// 1b. String literal as struct key
var _s2 = { "bar": 20 };
assert_eq(_s2[$ "bar"], 20, "struct key: string literal")

// 1c. `self` (unique variable) as struct key — is this valid in GML?
// Expected: GML accepts it and uses the string "self" as the key
var _s3 = { self: 30 };
assert_eq(_s3[$ "self"], 30, "struct key: unique variable `self`")

// 1d. `other` as struct key
var _s4 = { other: 40 };
assert_eq(_s4[$ "other"], 40, "struct key: unique variable `other`")

// 1e. `global` as struct key
var _s5 = { global: 50 };
assert_eq(_s5[$ "global"], 50, "struct key: unique variable `global`")

// 1f. `undefined` (GML constant) as struct key
// In GML the key should be the STRING "undefined", not the value undefined
var _s6 = { undefined: 60 };
assert_eq(_s6[$ "undefined"], 60, "struct key: constant `undefined` uses string name")

// 1g. `true` as struct key
var _s7 = { true: 70 };
assert_eq(_s7[$ "true"], 70, "struct key: constant `true` uses string name")

// 1h. `false` as struct key
var _s8 = { false: 80 };
assert_eq(_s8[$ "false"], 80, "struct key: constant `false` uses string name")

// 1i. `noone` as struct key
var _s9 = { noone: 90 };
assert_eq(_s9[$ "noone"], 90, "struct key: constant `noone` uses string name")

// 1j. `all` as struct key
var _s10 = { all: 100 };
assert_eq(_s10[$ "all"], 100, "struct key: constant `all` uses string name")

// 1k. Keyword `if` as struct key — GML may or may not accept this
// Document what GML actually does here, so GMLC can match
var _s11_ok = false;
//try {
    var _s11 = {};
    // Can`t write { if: 1 } directly as it`s a syntax error in most GML versions
    // Use variable_struct_set instead to test runtime struct key access
    variable_struct_set(_s11, "if", 110);
    assert_eq(_s11[$ "if"], 110, "struct key: `if` set via variable_struct_set")
    _s11_ok = true;
//} catch (_e) {
//    show_debug_message("INFO: struct key `if` via variable_struct_set threw: " + string(_e));
//}

// 1l. Keyword `for` as struct key (same test via variable_struct_set)
var _s12 = {};
variable_struct_set(_s12, "for", 120);
assert_eq(_s12[$ "for"], 120, "struct key: `for` accessed via $ operator by string")

// ============================================================
// SECTION 2: DOT ACCESSOR KEYS
// Tests what is valid as a property name after a dot
// ============================================================

// 2a. Normal identifier
var _d1 = { foo: 1 };
assert_eq(_d1.foo, 1, "dot accessor: plain identifier")

// 2b. `self` as dot property name — is this valid?
var _d2 = { self: 2 };
var _self_val = _d2.self;
assert_eq(_self_val, 2, "dot accessor: `self` as property name")

// 2c. `other` as dot property name
var _d3 = { other: 3 };
assert_eq(_d3.other, 3, "dot accessor: `other` as property name")

// 2d. `global` as dot property name
var _d4 = { global: 4 };
assert_eq(_d4.global, 4, "dot accessor: `global` as property name")

// 2e. `undefined` as dot property name
// `undefined` is a constant (Number token in GMLC), not a keyword
// Real GML may or may not allow this syntax
var _d5 = {};
variable_struct_set(_d5, "undefined", 5);
// Test: can we read it back via dot notation? (may be a GML syntax error)
// assert_eq(_d5.undefined, 5, "dot accessor: constant `undefined` as property")
// Safer: use $ accessor to verify the value exists
assert_eq(_d5[$ "undefined"], 5, "dot accessor: `undefined` key roundtrip via $")

// 2f. Verify that keywords used as dot keys require $ accessor
var _d6 = {};
variable_struct_set(_d6, "if", 6);
variable_struct_set(_d6, "for", 7);
variable_struct_set(_d6, "while", 8);
assert_eq(_d6[$ "if"], 6, "dot accessor: keyword `if` readable via $ after variable_struct_set")
assert_eq(_d6[$ "for"], 7, "dot accessor: keyword `for` readable via $ after variable_struct_set")
assert_eq(_d6[$ "while"], 8, "dot accessor: keyword `while` readable via $ after variable_struct_set")

// ============================================================
// SECTION 3: ENUM MEMBER NAMES
// Tests what is valid as an enum member identifier in real GML
// ============================================================

// 3a. Normal identifiers — always valid
enum TestEnumNormal {
    foo,
    bar,
    baz
}
assert_eq(TestEnumNormal.foo, 0, "enum: normal identifier member index 0")
assert_eq(TestEnumNormal.bar, 1, "enum: normal identifier member index 1")

// 3b. `self` as enum member name — UniqueVariable, name != value, first char alpha
// GML may accept or reject this — document actual behavior
enum TestEnumSelf { self }  // <-- uncomment to test if GML allows it
// If GML allows it:
assert_eq(TestEnumSelf.self, 0, "enum: unique variable `self` as member name")

// 3c. `undefined` as enum member name — constant, name != value in GMLC
// GML may allow this since `undefined` is not a reserved keyword in GML syntax
enum TestEnumUndef { undefined }  // <-- uncomment to test
assert_eq(TestEnumUndef.undefined, 0, "enum: constant `undefined` as member name")

// 3d. Keyword `if` as enum member — should be REJECTED in both GML and GMLC
enum TestEnumKeyword { if }  // <-- this is a syntax error; leave commented
show_debug_message("FAIL: enum keyword as member (syntax error)")

// 3e. Function name as enum member — `show_debug_message`
// GMLC currently ACCEPTS function-named members (name != value condition)
// Does GML itself accept this? Test it:
enum TestEnumFunc { show_debug_message }  // <-- uncomment to test
assert_eq(TestEnumFunc.show_debug_message, 0, "enum: function name as member")

// ============================================================
// SECTION 4: MACROS SHADOWING SPECIAL NAMES
// Tests macro expansion behavior vs reserved words
// ============================================================

// 4a. Macro with a normal name — expands in all contexts
#macro MY_CONST 999
assert_eq(MY_CONST, 999, "macro: normal macro name expands")

// 4b. Struct key using macro name — key should be the STRING "MY_CONST", not 999
// Because struct keys are parsed before macro expansion
var _m1 = { MY_CONST: 1 };
assert_eq(_m1[$ "MY_CONST"], 1, "macro: macro-named struct key uses string, not expanded value")

// 4c. Dot accessor with macro name — same: key is the literal string
//var _m2 = { MY_CONST: 2 };
//assert_eq(_m2.MY_CONST, 2, "macro: macro-named dot accessor reads correctly")
show_debug_message("FAIL: macro: macro-named dot accessor reads correctly")

// 4d. Macro value in expression — should expand
var _m3 = MY_CONST + 1;
assert_eq(_m3, 1000, "macro: macro expands in expression context")

// 4e. Macro named same as a function — in real GML, macros shadow functions
#macro string_length 42
// This next line: does string_length now evaluate to 42 or call the function?
// In GML macros are text-substituted, so string_length(x) becomes 42(x) which errors
// But string_length alone in an expression becomes 42
var _m4 = string_length;
assert_eq(_m4, 42, "macro: macro shadows built-in function name in expression")
// Cleanup: can`t #undef in GML, so subsequent string_length calls in this script are broken
// Keep this test LAST in the macro section to avoid contaminating other tests
');

show_debug_message(program())



/*

gmlc = new GMLC_Env().set_exposure(GMLC_EXPOSURE.NATIVE);

gmlc.__log_tokenizer_results      = true;
gmlc.__log_pre_processer_results  = true;
gmlc.__log_parser_results         = true;
gmlc.__log_post_processer_results = true;
gmlc.__log_optimizer_results      = true;

gmlc.compile(@'
    #macro test "abc";
	
	foo = 123;
	bar = test;
	
	var foo;
')


// Save full JSON result
log("!!!compiling complete!!!")

gmlc = undefined;


