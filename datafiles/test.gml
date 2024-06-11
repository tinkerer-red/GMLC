/*
Hello!
This file demonstrates various constructs that gml_string supports.
*/
var str = "this is a so-called \"string literal\"."
var str_vbt = @'and this is a "verbatim string literal"';
var str_expression = $"and this is a {test}";
var num1 = 2.3, num2 = .32, num3 = 0.59, num4 = 1_000;
var hex_gms1 = $21C;
var hex_gms2 = 0x21C;
var hex_color = #889EC5;
var bin = 0b101;
var pound_sign = £; // (illegal character)
			
   
// macros:
#macro m1 -1
var _m1 = abs(m1);

self.foo = "bar";

#region Hello
#endregion

var _arr = [1, "a", c_white];

// enums:
enum E { A, B, C }
var e_a = E.A;
var e_amiss = E.Missing; // should not highlight as part of enum

// 2.3 functions:
var f = function() {}
function make_uid() {
	static _count = 0;
	return _count++;
}
_count += 1; // should not highlight as local
function add(_one, _two = _one + 1) { // second _one should highlight as local
	return _one + _two;
}

// 2.3 constructors:
function A(_name) constructor {
	name = _name;
	static greet = function(_who) {
		var _tmp = "Hello to " + _who + " from " + name;
		return _tmp; // should highlight as local
		return _name; // should not highlight as local (belongs to constructor)
	}
	return _name; // should highlight as local
	return _tmp; // should not highlight as local (belongs to method)
}
function B(_name) : A(_name) constructor {
	static A_greet = greet;
	static greet = function(_who) {
		var _result = A_greet(_who);
		return _result + "!!";
	}
}

// classic multi-scripts:
#define one
return two()
#define two
return one()
