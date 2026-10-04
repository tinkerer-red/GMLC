// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-04.
function GmlEvaluationOrderTestSuite() : TestSuite() constructor {

	addFact("a + b [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_add), "string:A,B=3", "GameMaker no longer gives the measured result");
	});
	addFact("a + b [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 1) + case_ev("B", 2);
return case_log() + "=" + string(_r);'); }), "string:A,B=3", "GMLC differs from GameMaker");
	});

	addFact("a - b [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_sub), "string:A,B=3", "GameMaker no longer gives the measured result");
	});
	addFact("a - b [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 5) - case_ev("B", 2);
return case_log() + "=" + string(_r);'); }), "string:A,B=3", "GMLC differs from GameMaker");
	});

	addFact("a * b [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_mul), "string:A,B=6", "GameMaker no longer gives the measured result");
	});
	addFact("a * b [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 2) * case_ev("B", 3);
return case_log() + "=" + string(_r);'); }), "string:A,B=6", "GMLC differs from GameMaker");
	});

	addFact("a / b [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_div), "string:A,B=3", "GameMaker no longer gives the measured result");
	});
	addFact("a / b [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 6) / case_ev("B", 2);
return case_log() + "=" + string(_r);'); }), "string:A,B=3", "GMLC differs from GameMaker");
	});

	addFact("a mod b [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_mod), "string:A,B=1", "GameMaker no longer gives the measured result");
	});
	addFact("a mod b [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 7) mod case_ev("B", 3);
return case_log() + "=" + string(_r);'); }), "string:A,B=1", "GMLC differs from GameMaker");
	});

	addFact("string a + string b [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_concat), "string:A,B=xy", "GameMaker no longer gives the measured result");
	});
	addFact("string a + string b [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", "x") + case_ev("B", "y");
return case_log() + "=" + string(_r);'); }), "string:A,B=xy", "GMLC differs from GameMaker");
	});

	addFact("a == b [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_eq), "string:A,B=1", "GameMaker no longer gives the measured result");
	});
	addFact("a == b [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 1) == case_ev("B", 1);
return case_log() + "=" + string(_r);'); }), "string:A,B=1", "GMLC differs from GameMaker");
	});

	addFact("a < b [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_lt), "string:A,B=1", "GameMaker no longer gives the measured result");
	});
	addFact("a < b [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 1) < case_ev("B", 2);
return case_log() + "=" + string(_r);'); }), "string:A,B=1", "GMLC differs from GameMaker");
	});

	addFact("a && b, both true [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_and_both), "string:A,B=1", "GameMaker no longer gives the measured result");
	});
	addFact("a && b, both true [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", true) && case_ev("B", true);
return case_log() + "=" + string(_r);'); }), "string:A,B=1", "GMLC differs from GameMaker");
	});

	addFact("a && b, a false [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_and_short), "string:A=0", "GameMaker no longer gives the measured result");
	});
	addFact("a && b, a false [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", false) && case_ev("B", true);
return case_log() + "=" + string(_r);'); }), "string:A=0", "GMLC differs from GameMaker");
	});

	addFact("a || b, a true [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_or_short), "string:A=1", "GameMaker no longer gives the measured result");
	});
	addFact("a || b, a true [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", true) || case_ev("B", false);
return case_log() + "=" + string(_r);'); }), "string:A=1", "GMLC differs from GameMaker");
	});

	addFact("a || b, a false [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_or_both), "string:A,B=1", "GameMaker no longer gives the measured result");
	});
	addFact("a || b, a false [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", false) || case_ev("B", true);
return case_log() + "=" + string(_r);'); }), "string:A,B=1", "GMLC differs from GameMaker");
	});

	addFact("a ^^ b [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_xor), "string:A,B=1", "GameMaker no longer gives the measured result");
	});
	addFact("a ^^ b [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", true) ^^ case_ev("B", false);
return case_log() + "=" + string(_r);'); }), "string:A,B=1", "GMLC differs from GameMaker");
	});

	addFact("a & b [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_bitand), "string:A,B=1", "GameMaker no longer gives the measured result");
	});
	addFact("a & b [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 3) & case_ev("B", 1);
return case_log() + "=" + string(_r);'); }), "string:A,B=1", "GMLC differs from GameMaker");
	});

	addFact("a << b [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_shl), "string:A,B=8", "GameMaker no longer gives the measured result");
	});
	addFact("a << b [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 1) << case_ev("B", 3);
return case_log() + "=" + string(_r);'); }), "string:A,B=8", "GMLC differs from GameMaker");
	});

	addFact("a ?? b, a undefined [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_nullish_left), "string:A,B=2", "GameMaker no longer gives the measured result");
	});
	addFact("a ?? b, a undefined [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", undefined) ?? case_ev("B", 2);
return case_log() + "=" + string(_r);'); }), "string:A,B=2", "GMLC differs from GameMaker");
	});

	addFact("a ?? b, a defined [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_nullish_short), "string:A=1", "GameMaker no longer gives the measured result");
	});
	addFact("a ?? b, a defined [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 1) ?? case_ev("B", 2);
return case_log() + "=" + string(_r);'); }), "string:A=1", "GMLC differs from GameMaker");
	});

	addFact("c ? a : b [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_ternary), "string:C,A=1", "GameMaker no longer gives the measured result");
	});
	addFact("c ? a : b [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("C", true) ? case_ev("A", 1) : case_ev("B", 2);
return case_log() + "=" + string(_r);'); }), "string:C,A=1", "GMLC differs from GameMaker");
	});

	addFact("a + b + c [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_chain_add), "string:A,B,C=6", "GameMaker no longer gives the measured result");
	});
	addFact("a + b + c [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 1) + case_ev("B", 2) + case_ev("C", 3);
return case_log() + "=" + string(_r);'); }), "string:A,B,C=6", "GMLC differs from GameMaker");
	});

	addFact("a + b * c [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_mixed_precedence), "string:A,B,C=7", "GameMaker no longer gives the measured result");
	});
	addFact("a + b * c [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 1) + case_ev("B", 2) * case_ev("C", 3);
return case_log() + "=" + string(_r);'); }), "string:A,B,C=7", "GMLC differs from GameMaker");
	});

	addFact("a < b == c [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_compare_chain), "string:A,B,C=1", "GameMaker no longer gives the measured result");
	});
	addFact("a < b == c [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("A", 1) < case_ev("B", 2) == case_ev("C", true);
return case_log() + "=" + string(_r);'); }), "string:A,B,C=1", "GMLC differs from GameMaker");
	});

	addFact("arguments of a built-in call [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_builtin_args), "string:C,B,A=3", "GameMaker no longer gives the measured result");
	});
	addFact("arguments of a built-in call [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = max(case_ev("A", 1), case_ev("B", 2), case_ev("C", 3));
return case_log() + "=" + string(_r);'); }), "string:C,B,A=3", "GMLC differs from GameMaker");
	});

	addFact("arguments of a script call [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_script_args), "string:C,B,A=6", "GameMaker no longer gives the measured result");
	});
	addFact("arguments of a script call [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_sum3(case_ev("A", 1), case_ev("B", 2), case_ev("C", 3));
return case_log() + "=" + string(_r);'); }), "string:C,B,A=6", "GMLC differs from GameMaker");
	});

	addFact("arguments with a nested call [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_nested_args), "string:D,C,B,A=10", "GameMaker no longer gives the measured result");
	});
	addFact("arguments with a nested call [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_sum3(case_ev("A", 1), case_sum3(case_ev("B", 2), case_ev("C", 3), 0), case_ev("D", 4));
return case_log() + "=" + string(_r);'); }), "string:D,C,B,A=10", "GMLC differs from GameMaker");
	});

	addFact("callee expression against arguments [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_callee_expr), "string:C,B,A,F=6", "GameMaker no longer gives the measured result");
	});
	addFact("callee expression against arguments [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("F", case_sum3)(case_ev("A", 1), case_ev("B", 2), case_ev("C", 3));
return case_log() + "=" + string(_r);'); }), "string:C,B,A,F=6", "GMLC differs from GameMaker");
	});

	addFact("method call target against arguments [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_method_target), "string:T,A=10", "GameMaker no longer gives the measured result");
	});
	addFact("method call target against arguments [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { m: function(_x) { return _x * 10; } };
var _r = case_ev("T", s).m(case_ev("A", 1));
return case_log() + "=" + string(_r);'); }), "string:T,A=10", "GMLC differs from GameMaker");
	});

	addFact("constructor arguments [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_new_args), "string:B,A=1,2", "GameMaker no longer gives the measured result");
	});
	addFact("constructor arguments [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var p = new case_pair(case_ev("A", 1), case_ev("B", 2));
return case_log() + "=" + string(p.a) + "," + string(p.b);'); }), "string:B,A=1,2", "GMLC differs from GameMaker");
	});

	addFact("array literal elements [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_array_literal), "string:C,B,A=[ 1,2,3 ]", "GameMaker no longer gives the measured result");
	});
	addFact("array literal elements [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = [case_ev("A", 1), case_ev("B", 2), case_ev("C", 3)];
return case_log() + "=" + string(_r);'); }), "string:C,B,A=[ 1,2,3 ]", "GMLC differs from GameMaker");
	});

	addFact("struct literal values [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_struct_literal), "string:B,A=1,2", "GameMaker no longer gives the measured result");
	});
	addFact("struct literal values [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { x: case_ev("A", 1), y: case_ev("B", 2) };
return case_log() + "=" + string(s.x) + "," + string(s.y);'); }), "string:B,A=1,2", "GMLC differs from GameMaker");
	});

	addFact("array read plus value [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_read), "string:I,B=21", "GameMaker no longer gives the measured result");
	});
	addFact("array read plus value [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [10, 20];
var _r = arr[case_ev("I", 1)] + case_ev("B", 1);
return case_log() + "=" + string(_r);'); }), "string:I,B=21", "GMLC differs from GameMaker");
	});

	addFact("array expression against its index [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_target_read), "string:I,T=20", "GameMaker no longer gives the measured result");
	});
	addFact("array expression against its index [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [10, 20];
var _r = case_ev("T", arr)[case_ev("I", 1)];
return case_log() + "=" + string(_r);'); }), "string:I,T=20", "GMLC differs from GameMaker");
	});

	addFact("arr[i] = v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_assign), "string:V,I=[ 0,5 ]", "GameMaker no longer gives the measured result");
	});
	addFact("arr[i] = v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [0, 0];
arr[case_ev("I", 1)] = case_ev("V", 5);
return case_log() + "=" + string(arr);'); }), "string:V,I=[ 0,5 ]", "GMLC differs from GameMaker");
	});

	addFact("arr[i][j] = v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_assign_2d), "string:V,I,J=[ [ 0,0 ],[ 5,0 ] ]", "GameMaker no longer gives the measured result");
	});
	addFact("arr[i][j] = v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [[0, 0], [0, 0]];
arr[case_ev("I", 1)][case_ev("J", 0)] = case_ev("V", 5);
return case_log() + "=" + string(arr);'); }), "string:V,I,J=[ [ 0,0 ],[ 5,0 ] ]", "GMLC differs from GameMaker");
	});

	addFact("arr[i] += v evaluates i once [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_compound), "string:I,V=[ 1,6 ]", "GameMaker no longer gives the measured result");
	});
	addFact("arr[i] += v evaluates i once [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [1, 1];
arr[case_ev("I", 1)] += case_ev("V", 5);
return case_log() + "=" + string(arr);'); }), "string:I,V=[ 1,6 ]", "GMLC differs from GameMaker");
	});

	addFact("s[$ k] = v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_struct_key_assign), "string:V,K=1", "GameMaker no longer gives the measured result");
	});
	addFact("s[$ k] = v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = {};
s[$ case_ev("K", "k")] = case_ev("V", 1);
return case_log() + "=" + string(s[$ "k"]);'); }), "string:V,K=1", "GMLC differs from GameMaker");
	});

	addFact("m[? k] = v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_map_assign), "string:V,K=1", "GameMaker no longer gives the measured result");
	});
	addFact("m[? k] = v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var m = ds_map_create();
m[? case_ev("K", "k")] = case_ev("V", 1);
var _r = m[? "k"];
ds_map_destroy(m);
return case_log() + "=" + string(_r);'); }), "string:V,K=1", "GMLC differs from GameMaker");
	});

	addFact("t.x = v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_dot_assign), "string:V,T=1", "GameMaker no longer gives the measured result");
	});
	addFact("t.x = v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { x: 0 };
case_ev("T", s).x = case_ev("V", 1);
return case_log() + "=" + string(s.x);'); }), "string:V,T=1", "GMLC differs from GameMaker");
	});

	addFact("t.x += v evaluates t once [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_dot_compound), "string:T,V=3", "GameMaker no longer gives the measured result");
	});
	addFact("t.x += v evaluates t once [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { x: 1 };
case_ev("T", s).x += case_ev("V", 2);
return case_log() + "=" + string(s.x);'); }), "string:T,V=3", "GMLC differs from GameMaker");
	});

	addFact("arr[i++] = i [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_postfix_in_index), "string:[ 0,20 ] i=1", "GameMaker no longer gives the measured result");
	});
	addFact("arr[i++] = i [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var i = 0;
var arr = [10, 20];
arr[i++] = i;
return string(arr) + " i=" + string(i);'); }), "string:[ 0,20 ] i=1", "GMLC differs from GameMaker");
	});

	addFact("i++ + i [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_postfix_then_read), "string:3 i=2", "GameMaker no longer gives the measured result");
	});
	addFact("i++ + i [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var i = 1;
var _r = i++ + i;
return string(_r) + " i=" + string(i);'); }), "string:3 i=2", "GMLC differs from GameMaker");
	});

	addFact("++i + i++ [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_prefix_postfix_mix), "string:4 i=3", "GameMaker no longer gives the measured result");
	});
	addFact("++i + i++ [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var i = 1;
var _r = ++i + i++;
return string(_r) + " i=" + string(i);'); }), "string:4 i=3", "GMLC differs from GameMaker");
	});

	addFact("repeat count evaluated once [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_repeat_count), "string:N=3", "GameMaker no longer gives the measured result");
	});
	addFact("repeat count evaluated once [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var n = 0;
repeat (case_ev("N", 3)) { n++; }
return case_log() + "=" + string(n);'); }), "string:N=3", "GMLC differs from GameMaker");
	});

	addFact("for loop init, condition and step [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_for_parts), "string:I,C,B,S,C,B,S,C", "GameMaker no longer gives the measured result");
	});
	addFact("for loop init, condition and step [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
for (var i = case_ev("I", 0); case_ev("C", i < 2); i = case_ev("S", i + 1)) { case_ev("B", 0); }
return case_log();'); }), "string:I,C,B,S,C,B,S,C", "GMLC differs from GameMaker");
	});

	addFact("t[i] = v with a computed target [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_assign_target), "string:V,I,T=[ 0,5 ]", "GameMaker no longer gives the measured result");
	});
	addFact("t[i] = v with a computed target [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [0, 0];
case_ev("T", arr)[case_ev("I", 1)] = case_ev("V", 5);
return case_log() + "=" + string(arr);'); }), "string:V,I,T=[ 0,5 ]", "GMLC differs from GameMaker");
	});

	addFact("t[i][j] = v with a computed target [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_assign_2d_target), "string:V,J,I,T=[ [ 0,0 ],[ 5,0 ] ]", "GameMaker no longer gives the measured result");
	});
	addFact("t[i][j] = v with a computed target [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [[0, 0], [0, 0]];
case_ev("T", arr)[case_ev("I", 1)][case_ev("J", 0)] = case_ev("V", 5);
return case_log() + "=" + string(arr);'); }), "string:V,J,I,T=[ [ 0,0 ],[ 5,0 ] ]", "GMLC differs from GameMaker");
	});

	addFact("arr[i][j][k] = v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_assign_3d), "string:V,I,J,K=[ [ [ 0,5 ] ] ]", "GameMaker no longer gives the measured result");
	});
	addFact("arr[i][j][k] = v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [[[0, 0]]];
arr[case_ev("I", 0)][case_ev("J", 0)][case_ev("K", 1)] = case_ev("V", 5);
return case_log() + "=" + string(arr);'); }), "string:V,I,J,K=[ [ [ 0,5 ] ] ]", "GMLC differs from GameMaker");
	});

	addFact("t[$ k] = v with a computed target [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_struct_key_assign_target), "string:V,K,T=1", "GameMaker no longer gives the measured result");
	});
	addFact("t[$ k] = v with a computed target [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = {};
case_ev("T", s)[$ case_ev("K", "k")] = case_ev("V", 1);
return case_log() + "=" + string(s[$ "k"]);'); }), "string:V,K,T=1", "GMLC differs from GameMaker");
	});

	addFact("t[? k] = v with a computed target [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_map_assign_target), "string:V,K,T=1", "GameMaker no longer gives the measured result");
	});
	addFact("t[? k] = v with a computed target [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var m = ds_map_create();
case_ev("T", m)[? case_ev("K", "k")] = case_ev("V", 1);
var _r = m[? "k"];
ds_map_destroy(m);
return case_log() + "=" + string(_r);'); }), "string:V,K,T=1", "GMLC differs from GameMaker");
	});

	addFact("l[| i] = v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_list_assign), "string:V,I,T=5", "GameMaker no longer gives the measured result");
	});
	addFact("l[| i] = v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var l = ds_list_create();
ds_list_add(l, 0, 0);
case_ev("T", l)[| case_ev("I", 1)] = case_ev("V", 5);
var _r = l[| 1];
ds_list_destroy(l);
return case_log() + "=" + string(_r);'); }), "string:V,I,T=5", "GMLC differs from GameMaker");
	});

	addFact("g[# x, y] = v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_grid_assign), "string:V,Y,X,T=5", "GameMaker no longer gives the measured result");
	});
	addFact("g[# x, y] = v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var g = ds_grid_create(2, 2);
case_ev("T", g)[# case_ev("X", 1), case_ev("Y", 0)] = case_ev("V", 5);
var _r = g[# 1, 0];
ds_grid_destroy(g);
return case_log() + "=" + string(_r);'); }), "string:V,Y,X,T=5", "GMLC differs from GameMaker");
	});

	addFact("t.a.b = v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_dot_assign_chain), "string:V,T=1", "GameMaker no longer gives the measured result");
	});
	addFact("t.a.b = v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { a: { b: 0 } };
case_ev("T", s).a.b = case_ev("V", 1);
return case_log() + "=" + string(s.a.b);'); }), "string:V,T=1", "GMLC differs from GameMaker");
	});

	addFact("t[i] += v with a computed target [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_compound_target), "string:I,T,V,I,T=[ 1,6 ]", "GameMaker no longer gives the measured result");
	});
	addFact("t[i] += v with a computed target [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [1, 1];
case_ev("T", arr)[case_ev("I", 1)] += case_ev("V", 5);
return case_log() + "=" + string(arr);'); }), "string:I,T,V,I,T=[ 1,6 ]", "GMLC differs from GameMaker");
	});

	addFact("arr[i][j] += v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_compound_2d), "string:I,J,V=[ [ 1,1 ],[ 6,1 ] ]", "GameMaker no longer gives the measured result");
	});
	addFact("arr[i][j] += v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [[1, 1], [1, 1]];
arr[case_ev("I", 1)][case_ev("J", 0)] += case_ev("V", 5);
return case_log() + "=" + string(arr);'); }), "string:I,J,V=[ [ 1,1 ],[ 6,1 ] ]", "GMLC differs from GameMaker");
	});

	addFact("t[$ k] += v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_struct_key_compound), "string:K,T,V,K,T=3", "GameMaker no longer gives the measured result");
	});
	addFact("t[$ k] += v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { k: 1 };
case_ev("T", s)[$ case_ev("K", "k")] += case_ev("V", 2);
return case_log() + "=" + string(s.k);'); }), "string:K,T,V,K,T=3", "GMLC differs from GameMaker");
	});

	addFact("t[? k] += v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_map_compound), "string:K,T,V,K,T=3", "GameMaker no longer gives the measured result");
	});
	addFact("t[? k] += v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var m = ds_map_create();
m[? "k"] = 1;
case_ev("T", m)[? case_ev("K", "k")] += case_ev("V", 2);
var _r = m[? "k"];
ds_map_destroy(m);
return case_log() + "=" + string(_r);'); }), "string:K,T,V,K,T=3", "GMLC differs from GameMaker");
	});

	addFact("t[| i] += v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_list_compound), "string:I,T,V,I,T=3", "GameMaker no longer gives the measured result");
	});
	addFact("t[| i] += v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var l = ds_list_create();
ds_list_add(l, 1, 1);
case_ev("T", l)[| case_ev("I", 1)] += case_ev("V", 2);
var _r = l[| 1];
ds_list_destroy(l);
return case_log() + "=" + string(_r);'); }), "string:I,T,V,I,T=3", "GMLC differs from GameMaker");
	});

	addFact("t[# x, y] += v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_grid_compound), "string:Y,X,T,V,Y,X,T=3", "GameMaker no longer gives the measured result");
	});
	addFact("t[# x, y] += v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var g = ds_grid_create(2, 2);
ds_grid_clear(g, 1);
case_ev("T", g)[# case_ev("X", 1), case_ev("Y", 0)] += case_ev("V", 2);
var _r = g[# 1, 0];
ds_grid_destroy(g);
return case_log() + "=" + string(_r);'); }), "string:Y,X,T,V,Y,X,T=3", "GMLC differs from GameMaker");
	});

	addFact("t.a.b += v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_dot_compound_chain), "string:T,V=3", "GameMaker no longer gives the measured result");
	});
	addFact("t.a.b += v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { a: { b: 1 } };
case_ev("T", s).a.b += case_ev("V", 2);
return case_log() + "=" + string(s.a.b);'); }), "string:T,V=3", "GMLC differs from GameMaker");
	});

	addFact("t[i][j] read [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_read_2d), "string:J,I,T=3", "GameMaker no longer gives the measured result");
	});
	addFact("t[i][j] read [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [[1, 2], [3, 4]];
var _r = case_ev("T", arr)[case_ev("I", 1)][case_ev("J", 0)];
return case_log() + "=" + string(_r);'); }), "string:J,I,T=3", "GMLC differs from GameMaker");
	});

	addFact("t[$ k] read [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_struct_key_read), "string:K,T=7", "GameMaker no longer gives the measured result");
	});
	addFact("t[$ k] read [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { k: 7 };
var _r = case_ev("T", s)[$ case_ev("K", "k")];
return case_log() + "=" + string(_r);'); }), "string:K,T=7", "GMLC differs from GameMaker");
	});

	addFact("t[? k] read [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_map_read), "string:K,T=7", "GameMaker no longer gives the measured result");
	});
	addFact("t[? k] read [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var m = ds_map_create();
m[? "k"] = 7;
var _r = case_ev("T", m)[? case_ev("K", "k")];
ds_map_destroy(m);
return case_log() + "=" + string(_r);'); }), "string:K,T=7", "GMLC differs from GameMaker");
	});

	addFact("t[| i] read [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_list_read), "string:I,T=6", "GameMaker no longer gives the measured result");
	});
	addFact("t[| i] read [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var l = ds_list_create();
ds_list_add(l, 5, 6);
var _r = case_ev("T", l)[| case_ev("I", 1)];
ds_list_destroy(l);
return case_log() + "=" + string(_r);'); }), "string:I,T=6", "GMLC differs from GameMaker");
	});

	addFact("t[# x, y] read [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_grid_read), "string:Y,X,T=9", "GameMaker no longer gives the measured result");
	});
	addFact("t[# x, y] read [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var g = ds_grid_create(2, 2);
g[# 1, 0] = 9;
var _r = case_ev("T", g)[# case_ev("X", 1), case_ev("Y", 0)];
ds_grid_destroy(g);
return case_log() + "=" + string(_r);'); }), "string:Y,X,T=9", "GMLC differs from GameMaker");
	});

	addFact("t.m(a) where t.m is read from a computed target [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_callee_member), "string:T,B,A=3", "GameMaker no longer gives the measured result");
	});
	addFact("t.m(a) where t.m is read from a computed target [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { m: function(_a, _b) { return _a + _b; } };
var _r = case_ev("T", s).m(case_ev("A", 1), case_ev("B", 2));
return case_log() + "=" + string(_r);'); }), "string:T,B,A=3", "GMLC differs from GameMaker");
	});

	addFact("t[i](a) callee from an array [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_callee_index), "string:C,B,A,I,T=6", "GameMaker no longer gives the measured result");
	});
	addFact("t[i](a) callee from an array [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var fns = [case_sum3];
var _r = case_ev("T", fns)[case_ev("I", 0)](case_ev("A", 1), case_ev("B", 2), case_ev("C", 3));
return case_log() + "=" + string(_r);'); }), "string:C,B,A,I,T=6", "GMLC differs from GameMaker");
	});

	addFact("f(a)(b) callee returned by a call [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_callee_nested_call), "string:B,A,F=3", "GameMaker no longer gives the measured result");
	});
	addFact("f(a)(b) callee returned by a call [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var _r = case_ev("F", function(_x) { return method({ x: _x }, function(_y) { return x + _y; }); })(case_ev("A", 1))(case_ev("B", 2));
return case_log() + "=" + string(_r);'); }), "string:B,A,F=3", "GMLC differs from GameMaker");
	});

	addFact("new with three arguments [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_new_args_three), "string:C,B,A=1,2", "GameMaker no longer gives the measured result");
	});
	addFact("new with three arguments [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var p = new case_pair(case_ev("A", 1), case_ev("B", case_ev("C", 2)));
return case_log() + "=" + string(p.a) + "," + string(p.b);'); }), "string:C,B,A=1,2", "GMLC differs from GameMaker");
	});

	addFact("arr[f()] = g() with side effects on the array [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_assign_value_call_index), "string:V,I=[ 0,0,3 ]", "GameMaker no longer gives the measured result");
	});
	addFact("arr[f()] = g() with side effects on the array [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [0, 0, 0];
arr[case_ev("I", array_length(arr) - 1)] = case_ev("V", array_length(arr));
return case_log() + "=" + string(arr);'); }), "string:V,I=[ 0,0,3 ]", "GMLC differs from GameMaker");
	});

	addFact("s[$ k++] style: arr[i++] = i++ [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_postfix_in_struct_key), "string:[ 0,0,0 ] i=2", "GameMaker no longer gives the measured result");
	});
	addFact("s[$ k++] style: arr[i++] = i++ [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var i = 0;
var arr = [0, 0, 0];
arr[i++] = i++;
return string(arr) + " i=" + string(i);'); }), "string:[ 0,0,0 ] i=2", "GMLC differs from GameMaker");
	});

	addFact("arr[i][j] read from a variable [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_read_2d_local), "string:I,J=3", "GameMaker no longer gives the measured result");
	});
	addFact("arr[i][j] read from a variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [[1, 2], [3, 4]];
var _r = arr[case_ev("I", 1)][case_ev("J", 0)];
return case_log() + "=" + string(_r);'); }), "string:I,J=3", "GMLC differs from GameMaker");
	});

	addFact("s[$ k] += v on a variable [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_struct_key_compound_local), "string:K,V,K=3", "GameMaker no longer gives the measured result");
	});
	addFact("s[$ k] += v on a variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { k: 1 };
s[$ case_ev("K", "k")] += case_ev("V", 2);
return case_log() + "=" + string(s.k);'); }), "string:K,V,K=3", "GMLC differs from GameMaker");
	});

	addFact("m[? k] += v on a variable [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_map_compound_local), "string:K,V,K=3", "GameMaker no longer gives the measured result");
	});
	addFact("m[? k] += v on a variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var m = ds_map_create();
m[? "k"] = 1;
m[? case_ev("K", "k")] += case_ev("V", 2);
var _r = m[? "k"];
ds_map_destroy(m);
return case_log() + "=" + string(_r);'); }), "string:K,V,K=3", "GMLC differs from GameMaker");
	});

	addFact("g[# x, y] += v on a variable [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_grid_compound_local), "string:Y,X,V,Y,X=3", "GameMaker no longer gives the measured result");
	});
	addFact("g[# x, y] += v on a variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var g = ds_grid_create(2, 2);
ds_grid_clear(g, 1);
g[# case_ev("X", 1), case_ev("Y", 0)] += case_ev("V", 2);
var _r = g[# 1, 0];
ds_grid_destroy(g);
return case_log() + "=" + string(_r);'); }), "string:Y,X,V,Y,X=3", "GMLC differs from GameMaker");
	});

	addFact("l[| i] += v on a variable [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_list_compound_local), "string:I,V,I=3", "GameMaker no longer gives the measured result");
	});
	addFact("l[| i] += v on a variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var l = ds_list_create();
ds_list_add(l, 1, 1);
l[| case_ev("I", 1)] += case_ev("V", 2);
var _r = l[| 1];
ds_list_destroy(l);
return case_log() + "=" + string(_r);'); }), "string:I,V,I=3", "GMLC differs from GameMaker");
	});

	addFact("t.arr[i] += v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_member_array_compound), "string:T,I,V=[ 1,3 ]", "GameMaker no longer gives the measured result");
	});
	addFact("t.arr[i] += v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { arr: [1, 1] };
case_ev("T", s).arr[case_ev("I", 1)] += case_ev("V", 2);
return case_log() + "=" + string(s.arr);'); }), "string:T,I,V=[ 1,3 ]", "GMLC differs from GameMaker");
	});

	addFact("t.arr[i][j] = v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_member_array_assign_2d), "string:V,T,I,J=[ [ 0,0 ],[ 5,0 ] ]", "GameMaker no longer gives the measured result");
	});
	addFact("t.arr[i][j] = v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { arr: [[0, 0], [0, 0]] };
case_ev("T", s).arr[case_ev("I", 1)][case_ev("J", 0)] = case_ev("V", 5);
return case_log() + "=" + string(s.arr);'); }), "string:V,T,I,J=[ [ 0,0 ],[ 5,0 ] ]", "GMLC differs from GameMaker");
	});

	addFact("s.arr[i] += v with s a variable [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_local_member_array_compound), "string:I,V=[ 1,3 ]", "GameMaker no longer gives the measured result");
	});
	addFact("s.arr[i] += v with s a variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { arr: [1, 1] };
s.arr[case_ev("I", 1)] += case_ev("V", 2);
return case_log() + "=" + string(s.arr);'); }), "string:I,V=[ 1,3 ]", "GMLC differs from GameMaker");
	});

	addFact("s.arr[i][j] = v with s a variable [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_local_member_array_assign_2d), "string:V,I,J=[ [ 0,0 ],[ 5,0 ] ]", "GameMaker no longer gives the measured result");
	});
	addFact("s.arr[i][j] = v with s a variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { arr: [[0, 0], [0, 0]] };
s.arr[case_ev("I", 1)][case_ev("J", 0)] = case_ev("V", 5);
return case_log() + "=" + string(s.arr);'); }), "string:V,I,J=[ [ 0,0 ],[ 5,0 ] ]", "GMLC differs from GameMaker");
	});

	addFact("global.arr[i] += v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_global_array_compound), "string:I,V=[ 1,3 ]", "GameMaker no longer gives the measured result");
	});
	addFact("global.arr[i] += v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
global.case_order_arr = [1, 1];
global.case_order_arr[case_ev("I", 1)] += case_ev("V", 2);
return case_log() + "=" + string(global.case_order_arr);'); }), "string:I,V=[ 1,3 ]", "GMLC differs from GameMaker");
	});

	addFact("t[i]++ [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_postfix_target), "string:I,T,I,T=1 [ 1,2 ]", "GameMaker no longer gives the measured result");
	});
	addFact("t[i]++ [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [1, 1];
var _r = case_ev("T", arr)[case_ev("I", 1)]++;
return case_log() + "=" + string(_r) + " " + string(arr);'); }), "string:I,T,I,T=1 [ 1,2 ]", "GMLC differs from GameMaker");
	});

	addFact("arr[i]++ [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_index_postfix_local), "string:I=1 [ 1,2 ]", "GameMaker no longer gives the measured result");
	});
	addFact("arr[i]++ [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var arr = [1, 1];
var _r = arr[case_ev("I", 1)]++;
return case_log() + "=" + string(_r) + " " + string(arr);'); }), "string:I=1 [ 1,2 ]", "GMLC differs from GameMaker");
	});

	addFact("t.x++ [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_dot_postfix_target), "string:T=1 2", "GameMaker no longer gives the measured result");
	});
	addFact("t.x++ [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { x: 1 };
var _r = case_ev("T", s).x++;
return case_log() + "=" + string(_r) + " " + string(s.x);'); }), "string:T=1 2", "GMLC differs from GameMaker");
	});

	addFact("++t[$ k] [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_struct_key_prefix_target), "string:K,T,K,T=2 2", "GameMaker no longer gives the measured result");
	});
	addFact("++t[$ k] [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var s = { k: 1 };
var _r = ++case_ev("T", s)[$ case_ev("K", "k")];
return case_log() + "=" + string(_r) + " " + string(s.k);'); }), "string:K,T,K,T=2 2", "GMLC differs from GameMaker");
	});

	addFact("local x = v [GameMaker]", function() {
		assert_equals(case_run(case_evaluation_order_assign_var_value), "string:V,W=3", "GameMaker no longer gives the measured result");
	});
	addFact("local x = v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'case_log_reset();
var x1 = 0;
x1 = case_ev("V", 1) + case_ev("W", 2);
return case_log() + "=" + string(x1);'); }), "string:V,W=3", "GMLC differs from GameMaker");
	});
}

function case_evaluation_order_add() {
case_log_reset();
var _r = case_ev("A", 1) + case_ev("B", 2);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_sub() {
case_log_reset();
var _r = case_ev("A", 5) - case_ev("B", 2);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_mul() {
case_log_reset();
var _r = case_ev("A", 2) * case_ev("B", 3);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_div() {
case_log_reset();
var _r = case_ev("A", 6) / case_ev("B", 2);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_mod() {
case_log_reset();
var _r = case_ev("A", 7) mod case_ev("B", 3);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_concat() {
case_log_reset();
var _r = case_ev("A", "x") + case_ev("B", "y");
return case_log() + "=" + string(_r);
}

function case_evaluation_order_eq() {
case_log_reset();
var _r = case_ev("A", 1) == case_ev("B", 1);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_lt() {
case_log_reset();
var _r = case_ev("A", 1) < case_ev("B", 2);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_and_both() {
case_log_reset();
var _r = case_ev("A", true) && case_ev("B", true);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_and_short() {
case_log_reset();
var _r = case_ev("A", false) && case_ev("B", true);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_or_short() {
case_log_reset();
var _r = case_ev("A", true) || case_ev("B", false);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_or_both() {
case_log_reset();
var _r = case_ev("A", false) || case_ev("B", true);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_xor() {
case_log_reset();
var _r = case_ev("A", true) ^^ case_ev("B", false);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_bitand() {
case_log_reset();
var _r = case_ev("A", 3) & case_ev("B", 1);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_shl() {
case_log_reset();
var _r = case_ev("A", 1) << case_ev("B", 3);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_nullish_left() {
case_log_reset();
var _r = case_ev("A", undefined) ?? case_ev("B", 2);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_nullish_short() {
case_log_reset();
var _r = case_ev("A", 1) ?? case_ev("B", 2);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_ternary() {
case_log_reset();
var _r = case_ev("C", true) ? case_ev("A", 1) : case_ev("B", 2);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_chain_add() {
case_log_reset();
var _r = case_ev("A", 1) + case_ev("B", 2) + case_ev("C", 3);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_mixed_precedence() {
case_log_reset();
var _r = case_ev("A", 1) + case_ev("B", 2) * case_ev("C", 3);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_compare_chain() {
case_log_reset();
var _r = case_ev("A", 1) < case_ev("B", 2) == case_ev("C", true);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_builtin_args() {
case_log_reset();
var _r = max(case_ev("A", 1), case_ev("B", 2), case_ev("C", 3));
return case_log() + "=" + string(_r);
}

function case_evaluation_order_script_args() {
case_log_reset();
var _r = case_sum3(case_ev("A", 1), case_ev("B", 2), case_ev("C", 3));
return case_log() + "=" + string(_r);
}

function case_evaluation_order_nested_args() {
case_log_reset();
var _r = case_sum3(case_ev("A", 1), case_sum3(case_ev("B", 2), case_ev("C", 3), 0), case_ev("D", 4));
return case_log() + "=" + string(_r);
}

function case_evaluation_order_callee_expr() {
case_log_reset();
var _r = case_ev("F", case_sum3)(case_ev("A", 1), case_ev("B", 2), case_ev("C", 3));
return case_log() + "=" + string(_r);
}

function case_evaluation_order_method_target() {
case_log_reset();
var s = { m: function(_x) { return _x * 10; } };
var _r = case_ev("T", s).m(case_ev("A", 1));
return case_log() + "=" + string(_r);
}

function case_evaluation_order_new_args() {
case_log_reset();
var p = new case_pair(case_ev("A", 1), case_ev("B", 2));
return case_log() + "=" + string(p.a) + "," + string(p.b);
}

function case_evaluation_order_array_literal() {
case_log_reset();
var _r = [case_ev("A", 1), case_ev("B", 2), case_ev("C", 3)];
return case_log() + "=" + string(_r);
}

function case_evaluation_order_struct_literal() {
case_log_reset();
var s = { x: case_ev("A", 1), y: case_ev("B", 2) };
return case_log() + "=" + string(s.x) + "," + string(s.y);
}

function case_evaluation_order_index_read() {
case_log_reset();
var arr = [10, 20];
var _r = arr[case_ev("I", 1)] + case_ev("B", 1);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_index_target_read() {
case_log_reset();
var arr = [10, 20];
var _r = case_ev("T", arr)[case_ev("I", 1)];
return case_log() + "=" + string(_r);
}

function case_evaluation_order_index_assign() {
case_log_reset();
var arr = [0, 0];
arr[case_ev("I", 1)] = case_ev("V", 5);
return case_log() + "=" + string(arr);
}

function case_evaluation_order_index_assign_2d() {
case_log_reset();
var arr = [[0, 0], [0, 0]];
arr[case_ev("I", 1)][case_ev("J", 0)] = case_ev("V", 5);
return case_log() + "=" + string(arr);
}

function case_evaluation_order_index_compound() {
case_log_reset();
var arr = [1, 1];
arr[case_ev("I", 1)] += case_ev("V", 5);
return case_log() + "=" + string(arr);
}

function case_evaluation_order_struct_key_assign() {
case_log_reset();
var s = {};
s[$ case_ev("K", "k")] = case_ev("V", 1);
return case_log() + "=" + string(s[$ "k"]);
}

function case_evaluation_order_map_assign() {
case_log_reset();
var m = ds_map_create();
m[? case_ev("K", "k")] = case_ev("V", 1);
var _r = m[? "k"];
ds_map_destroy(m);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_dot_assign() {
case_log_reset();
var s = { x: 0 };
case_ev("T", s).x = case_ev("V", 1);
return case_log() + "=" + string(s.x);
}

function case_evaluation_order_dot_compound() {
case_log_reset();
var s = { x: 1 };
case_ev("T", s).x += case_ev("V", 2);
return case_log() + "=" + string(s.x);
}

function case_evaluation_order_postfix_in_index() {
var i = 0;
var arr = [10, 20];
arr[i++] = i;
return string(arr) + " i=" + string(i);
}

function case_evaluation_order_postfix_then_read() {
var i = 1;
var _r = i++ + i;
return string(_r) + " i=" + string(i);
}

function case_evaluation_order_prefix_postfix_mix() {
var i = 1;
var _r = ++i + i++;
return string(_r) + " i=" + string(i);
}

function case_evaluation_order_repeat_count() {
case_log_reset();
var n = 0;
repeat (case_ev("N", 3)) { n++; }
return case_log() + "=" + string(n);
}

function case_evaluation_order_for_parts() {
case_log_reset();
for (var i = case_ev("I", 0); case_ev("C", i < 2); i = case_ev("S", i + 1)) { case_ev("B", 0); }
return case_log();
}

function case_evaluation_order_index_assign_target() {
case_log_reset();
var arr = [0, 0];
case_ev("T", arr)[case_ev("I", 1)] = case_ev("V", 5);
return case_log() + "=" + string(arr);
}

function case_evaluation_order_index_assign_2d_target() {
case_log_reset();
var arr = [[0, 0], [0, 0]];
case_ev("T", arr)[case_ev("I", 1)][case_ev("J", 0)] = case_ev("V", 5);
return case_log() + "=" + string(arr);
}

function case_evaluation_order_index_assign_3d() {
case_log_reset();
var arr = [[[0, 0]]];
arr[case_ev("I", 0)][case_ev("J", 0)][case_ev("K", 1)] = case_ev("V", 5);
return case_log() + "=" + string(arr);
}

function case_evaluation_order_struct_key_assign_target() {
case_log_reset();
var s = {};
case_ev("T", s)[$ case_ev("K", "k")] = case_ev("V", 1);
return case_log() + "=" + string(s[$ "k"]);
}

function case_evaluation_order_map_assign_target() {
case_log_reset();
var m = ds_map_create();
case_ev("T", m)[? case_ev("K", "k")] = case_ev("V", 1);
var _r = m[? "k"];
ds_map_destroy(m);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_list_assign() {
case_log_reset();
var l = ds_list_create();
ds_list_add(l, 0, 0);
case_ev("T", l)[| case_ev("I", 1)] = case_ev("V", 5);
var _r = l[| 1];
ds_list_destroy(l);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_grid_assign() {
case_log_reset();
var g = ds_grid_create(2, 2);
case_ev("T", g)[# case_ev("X", 1), case_ev("Y", 0)] = case_ev("V", 5);
var _r = g[# 1, 0];
ds_grid_destroy(g);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_dot_assign_chain() {
case_log_reset();
var s = { a: { b: 0 } };
case_ev("T", s).a.b = case_ev("V", 1);
return case_log() + "=" + string(s.a.b);
}

function case_evaluation_order_index_compound_target() {
case_log_reset();
var arr = [1, 1];
case_ev("T", arr)[case_ev("I", 1)] += case_ev("V", 5);
return case_log() + "=" + string(arr);
}

function case_evaluation_order_index_compound_2d() {
case_log_reset();
var arr = [[1, 1], [1, 1]];
arr[case_ev("I", 1)][case_ev("J", 0)] += case_ev("V", 5);
return case_log() + "=" + string(arr);
}

function case_evaluation_order_struct_key_compound() {
case_log_reset();
var s = { k: 1 };
case_ev("T", s)[$ case_ev("K", "k")] += case_ev("V", 2);
return case_log() + "=" + string(s.k);
}

function case_evaluation_order_map_compound() {
case_log_reset();
var m = ds_map_create();
m[? "k"] = 1;
case_ev("T", m)[? case_ev("K", "k")] += case_ev("V", 2);
var _r = m[? "k"];
ds_map_destroy(m);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_list_compound() {
case_log_reset();
var l = ds_list_create();
ds_list_add(l, 1, 1);
case_ev("T", l)[| case_ev("I", 1)] += case_ev("V", 2);
var _r = l[| 1];
ds_list_destroy(l);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_grid_compound() {
case_log_reset();
var g = ds_grid_create(2, 2);
ds_grid_clear(g, 1);
case_ev("T", g)[# case_ev("X", 1), case_ev("Y", 0)] += case_ev("V", 2);
var _r = g[# 1, 0];
ds_grid_destroy(g);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_dot_compound_chain() {
case_log_reset();
var s = { a: { b: 1 } };
case_ev("T", s).a.b += case_ev("V", 2);
return case_log() + "=" + string(s.a.b);
}

function case_evaluation_order_index_read_2d() {
case_log_reset();
var arr = [[1, 2], [3, 4]];
var _r = case_ev("T", arr)[case_ev("I", 1)][case_ev("J", 0)];
return case_log() + "=" + string(_r);
}

function case_evaluation_order_struct_key_read() {
case_log_reset();
var s = { k: 7 };
var _r = case_ev("T", s)[$ case_ev("K", "k")];
return case_log() + "=" + string(_r);
}

function case_evaluation_order_map_read() {
case_log_reset();
var m = ds_map_create();
m[? "k"] = 7;
var _r = case_ev("T", m)[? case_ev("K", "k")];
ds_map_destroy(m);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_list_read() {
case_log_reset();
var l = ds_list_create();
ds_list_add(l, 5, 6);
var _r = case_ev("T", l)[| case_ev("I", 1)];
ds_list_destroy(l);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_grid_read() {
case_log_reset();
var g = ds_grid_create(2, 2);
g[# 1, 0] = 9;
var _r = case_ev("T", g)[# case_ev("X", 1), case_ev("Y", 0)];
ds_grid_destroy(g);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_callee_member() {
case_log_reset();
var s = { m: function(_a, _b) { return _a + _b; } };
var _r = case_ev("T", s).m(case_ev("A", 1), case_ev("B", 2));
return case_log() + "=" + string(_r);
}

function case_evaluation_order_callee_index() {
case_log_reset();
var fns = [case_sum3];
var _r = case_ev("T", fns)[case_ev("I", 0)](case_ev("A", 1), case_ev("B", 2), case_ev("C", 3));
return case_log() + "=" + string(_r);
}

function case_evaluation_order_callee_nested_call() {
case_log_reset();
var _r = case_ev("F", function(_x) { return method({ x: _x }, function(_y) { return x + _y; }); })(case_ev("A", 1))(case_ev("B", 2));
return case_log() + "=" + string(_r);
}

function case_evaluation_order_new_args_three() {
case_log_reset();
var p = new case_pair(case_ev("A", 1), case_ev("B", case_ev("C", 2)));
return case_log() + "=" + string(p.a) + "," + string(p.b);
}

function case_evaluation_order_assign_value_call_index() {
case_log_reset();
var arr = [0, 0, 0];
arr[case_ev("I", array_length(arr) - 1)] = case_ev("V", array_length(arr));
return case_log() + "=" + string(arr);
}

function case_evaluation_order_postfix_in_struct_key() {
var i = 0;
var arr = [0, 0, 0];
arr[i++] = i++;
return string(arr) + " i=" + string(i);
}

function case_evaluation_order_index_read_2d_local() {
case_log_reset();
var arr = [[1, 2], [3, 4]];
var _r = arr[case_ev("I", 1)][case_ev("J", 0)];
return case_log() + "=" + string(_r);
}

function case_evaluation_order_struct_key_compound_local() {
case_log_reset();
var s = { k: 1 };
s[$ case_ev("K", "k")] += case_ev("V", 2);
return case_log() + "=" + string(s.k);
}

function case_evaluation_order_map_compound_local() {
case_log_reset();
var m = ds_map_create();
m[? "k"] = 1;
m[? case_ev("K", "k")] += case_ev("V", 2);
var _r = m[? "k"];
ds_map_destroy(m);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_grid_compound_local() {
case_log_reset();
var g = ds_grid_create(2, 2);
ds_grid_clear(g, 1);
g[# case_ev("X", 1), case_ev("Y", 0)] += case_ev("V", 2);
var _r = g[# 1, 0];
ds_grid_destroy(g);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_list_compound_local() {
case_log_reset();
var l = ds_list_create();
ds_list_add(l, 1, 1);
l[| case_ev("I", 1)] += case_ev("V", 2);
var _r = l[| 1];
ds_list_destroy(l);
return case_log() + "=" + string(_r);
}

function case_evaluation_order_member_array_compound() {
case_log_reset();
var s = { arr: [1, 1] };
case_ev("T", s).arr[case_ev("I", 1)] += case_ev("V", 2);
return case_log() + "=" + string(s.arr);
}

function case_evaluation_order_member_array_assign_2d() {
case_log_reset();
var s = { arr: [[0, 0], [0, 0]] };
case_ev("T", s).arr[case_ev("I", 1)][case_ev("J", 0)] = case_ev("V", 5);
return case_log() + "=" + string(s.arr);
}

function case_evaluation_order_local_member_array_compound() {
case_log_reset();
var s = { arr: [1, 1] };
s.arr[case_ev("I", 1)] += case_ev("V", 2);
return case_log() + "=" + string(s.arr);
}

function case_evaluation_order_local_member_array_assign_2d() {
case_log_reset();
var s = { arr: [[0, 0], [0, 0]] };
s.arr[case_ev("I", 1)][case_ev("J", 0)] = case_ev("V", 5);
return case_log() + "=" + string(s.arr);
}

function case_evaluation_order_global_array_compound() {
case_log_reset();
global.case_order_arr = [1, 1];
global.case_order_arr[case_ev("I", 1)] += case_ev("V", 2);
return case_log() + "=" + string(global.case_order_arr);
}

function case_evaluation_order_index_postfix_target() {
case_log_reset();
var arr = [1, 1];
var _r = case_ev("T", arr)[case_ev("I", 1)]++;
return case_log() + "=" + string(_r) + " " + string(arr);
}

function case_evaluation_order_index_postfix_local() {
case_log_reset();
var arr = [1, 1];
var _r = arr[case_ev("I", 1)]++;
return case_log() + "=" + string(_r) + " " + string(arr);
}

function case_evaluation_order_dot_postfix_target() {
case_log_reset();
var s = { x: 1 };
var _r = case_ev("T", s).x++;
return case_log() + "=" + string(_r) + " " + string(s.x);
}

function case_evaluation_order_struct_key_prefix_target() {
case_log_reset();
var s = { k: 1 };
var _r = ++case_ev("T", s)[$ case_ev("K", "k")];
return case_log() + "=" + string(_r) + " " + string(s.k);
}

function case_evaluation_order_assign_var_value() {
case_log_reset();
var x1 = 0;
x1 = case_ev("V", 1) + case_ev("W", 2);
return case_log() + "=" + string(x1);
}
