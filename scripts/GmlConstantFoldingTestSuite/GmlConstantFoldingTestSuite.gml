// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-07.
function GmlConstantFoldingTestSuite() : TestSuite() constructor {

	addFact("5 & 3 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_5_band_3), "string:number:1", "GameMaker no longer gives the measured result");
	});
	addFact("5 & 3 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 5 & 3; return typeof(r) + ":" + string(r);'); }), "string:int64:1", "GMLC differs from GameMaker");
	});

	addFact("5 | 3 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_5_bor_3), "string:number:7", "GameMaker no longer gives the measured result");
	});
	addFact("5 | 3 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 5 | 3; return typeof(r) + ":" + string(r);'); }), "string:int64:7", "GMLC differs from GameMaker");
	});

	addFact("5 ^ 3 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_5_bxor_3), "string:number:6", "GameMaker no longer gives the measured result");
	});
	addFact("5 ^ 3 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 5 ^ 3; return typeof(r) + ":" + string(r);'); }), "string:int64:6", "GMLC differs from GameMaker");
	});

	addFact("1 << 3 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_1_shl_3), "string:number:8", "GameMaker no longer gives the measured result");
	});
	addFact("1 << 3 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 1 << 3; return typeof(r) + ":" + string(r);'); }), "string:int64:8", "GMLC differs from GameMaker");
	});

	addFact("16 >> 2 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_16_shr_2), "string:number:4", "GameMaker no longer gives the measured result");
	});
	addFact("16 >> 2 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 16 >> 2; return typeof(r) + ":" + string(r);'); }), "string:int64:4", "GMLC differs from GameMaker");
	});

	addFact("~5 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_not5), "string:number:-6", "GameMaker no longer gives the measured result");
	});
	addFact("~5 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = ~5; return typeof(r) + ":" + string(r);'); }), "string:int64:-6", "GMLC differs from GameMaker");
	});

	addFact("7 div 2 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_7_div_2), "string:number:3", "GameMaker no longer gives the measured result");
	});
	addFact("7 div 2 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 7 div 2; return typeof(r) + ":" + string(r);'); }), "string:number:3", "GMLC differs from GameMaker");
	});

	addFact("7 mod 3 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_7_mod_3), "string:number:1", "GameMaker no longer gives the measured result");
	});
	addFact("7 mod 3 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 7 mod 3; return typeof(r) + ":" + string(r);'); }), "string:number:1", "GMLC differs from GameMaker");
	});

	addFact("2 + 3 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_2_plus_3), "string:number:5", "GameMaker no longer gives the measured result");
	});
	addFact("2 + 3 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 2 + 3; return typeof(r) + ":" + string(r);'); }), "string:number:5", "GMLC differs from GameMaker");
	});

	addFact("7 / 2 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_7_over_2), "string:number:3.50", "GameMaker no longer gives the measured result");
	});
	addFact("7 / 2 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 7 / 2; return typeof(r) + ":" + string(r);'); }), "string:number:3.50", "GMLC differs from GameMaker");
	});

	addFact("-5 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_minus5), "string:number:-5", "GameMaker no longer gives the measured result");
	});
	addFact("-5 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = -5; return typeof(r) + ":" + string(r);'); }), "string:number:-5", "GMLC differs from GameMaker");
	});

	addFact("1 == 1 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_1_eq_1), "string:bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("1 == 1 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 1 == 1; return typeof(r) + ":" + string(r);'); }), "string:bool:1", "GMLC differs from GameMaker");
	});

	addFact("2147483648 | 0 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_2147483648_bor_0), "string:int64:2147483648", "GameMaker no longer gives the measured result");
	});
	addFact("2147483648 | 0 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 2147483648 | 0; return typeof(r) + ":" + string(r);'); }), "string:int64:2147483648", "GMLC differs from GameMaker");
	});

	addFact("0x80000000 & 1 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_0x80000000_band_1), "string:int64:0", "GameMaker no longer gives the measured result");
	});
	addFact("0x80000000 & 1 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 0x80000000 & 1; return typeof(r) + ":" + string(r);'); }), "string:int64:0", "GMLC differs from GameMaker");
	});

	addFact("$80000000 & 1 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hex80000000_band_1), "string:int64:0", "GameMaker no longer gives the measured result");
	});
	addFact("$80000000 & 1 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = $80000000 & 1; return typeof(r) + ":" + string(r);'); }), "string:int64:0", "GMLC differs from GameMaker");
	});

	addFact("2147483648 + 1 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_2147483648_plus_1), "string:int64:2147483649", "GameMaker no longer gives the measured result");
	});
	addFact("2147483648 + 1 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 2147483648 + 1; return typeof(r) + ":" + string(r);'); }), "string:number:2147483649", "GMLC differs from GameMaker");
	});

	addFact("$FFFFFFFFFF + 1 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hexffffffffff_plus_1), "string:int64:1099511627776", "GameMaker no longer gives the measured result");
	});
	addFact("$FFFFFFFFFF + 1 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = $FFFFFFFFFF + 1; return typeof(r) + ":" + string(r);'); }), "string:number:1099511627776", "GMLC differs from GameMaker");
	});

	addFact("$FFFFFFFFFF & 1 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hexffffffffff_band_1), "string:int64:1", "GameMaker no longer gives the measured result");
	});
	addFact("$FFFFFFFFFF & 1 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = $FFFFFFFFFF & 1; return typeof(r) + ":" + string(r);'); }), "string:int64:1", "GMLC differs from GameMaker");
	});

	addFact("$7FFFFFFF & 1 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hex7fffffff_band_1), "string:number:1", "GameMaker no longer gives the measured result");
	});
	addFact("$7FFFFFFF & 1 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = $7FFFFFFF & 1; return typeof(r) + ":" + string(r);'); }), "string:int64:1", "GMLC differs from GameMaker");
	});

	addFact("4294967296 & 1 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_4294967296_band_1), "string:number:0", "GameMaker no longer gives the measured result");
	});
	addFact("4294967296 & 1 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 4294967296 & 1; return typeof(r) + ":" + string(r);'); }), "string:int64:0", "GMLC differs from GameMaker");
	});

	addFact("$100000000 & 1 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hex100000000_band_1), "string:int64:0", "GameMaker no longer gives the measured result");
	});
	addFact("$100000000 & 1 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = $100000000 & 1; return typeof(r) + ":" + string(r);'); }), "string:int64:0", "GMLC differs from GameMaker");
	});

	addFact("~2147483648 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_not2147483648), "string:int64:-2147483649", "GameMaker no longer gives the measured result");
	});
	addFact("~2147483648 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = ~2147483648; return typeof(r) + ":" + string(r);'); }), "string:int64:-2147483649", "GMLC differs from GameMaker");
	});

	addFact("2147483648 << 1 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_2147483648_shl_1), "string:int64:4294967296", "GameMaker no longer gives the measured result");
	});
	addFact("2147483648 << 1 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 2147483648 << 1; return typeof(r) + ":" + string(r);'); }), "string:int64:4294967296", "GMLC differs from GameMaker");
	});

	addFact("$80000000 * 2 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hex80000000_times_2), "string:int64:4294967296", "GameMaker no longer gives the measured result");
	});
	addFact("$80000000 * 2 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = $80000000 * 2; return typeof(r) + ":" + string(r);'); }), "string:number:4294967296", "GMLC differs from GameMaker");
	});

	addFact("2147483648 * 2 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_2147483648_times_2), "string:int64:4294967296", "GameMaker no longer gives the measured result");
	});
	addFact("2147483648 * 2 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 2147483648 * 2; return typeof(r) + ":" + string(r);'); }), "string:number:4294967296", "GMLC differs from GameMaker");
	});

	addFact("$80000000 div 2 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hex80000000_div_2), "string:int64:1073741824", "GameMaker no longer gives the measured result");
	});
	addFact("$80000000 div 2 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = $80000000 div 2; return typeof(r) + ":" + string(r);'); }), "string:number:1073741824", "GMLC differs from GameMaker");
	});

	addFact("(1 + 2) & 3 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_1_plus_2_band_3), "string:number:3", "GameMaker no longer gives the measured result");
	});
	addFact("(1 + 2) & 3 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = (1 + 2) & 3; return typeof(r) + ":" + string(r);'); }), "string:int64:3", "GMLC differs from GameMaker");
	});

	addFact("true + 1 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_true_plus_1), "string:number:2", "GameMaker no longer gives the measured result");
	});
	addFact("true + 1 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = true + 1; return typeof(r) + ":" + string(r);'); }), "string:number:2", "GMLC differs from GameMaker");
	});

	addFact("!0xA7 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_lnot0xa7), "string:number:0", "GameMaker no longer gives the measured result");
	});
	addFact("!0xA7 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = !0xA7; return typeof(r) + ":" + string(r);'); }), "string:bool:0", "GMLC differs from GameMaker");
	});

	addFact("0b1011 && 0b1011 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_0b1011_and_0b1011), "string:number:1", "GameMaker no longer gives the measured result");
	});
	addFact("0b1011 && 0b1011 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 0b1011 && 0b1011; return typeof(r) + ":" + string(r);'); }), "string:bool:1", "GMLC differs from GameMaker");
	});

	addFact("1.5 ^^ 167 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_1_5_xor_167), "string:number:0", "GameMaker no longer gives the measured result");
	});
	addFact("1.5 ^^ 167 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 1.5 ^^ 167; return typeof(r) + ":" + string(r);'); }), "string:bool:0", "GMLC differs from GameMaker");
	});

	addFact("a & b on variables [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_rt_band), "string:int64:1", "GameMaker no longer gives the measured result");
	});
	addFact("a & b on variables [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 5; var b = 3; var r = a & b; return typeof(r) + ":" + string(r);'); }), "string:int64:1", "GMLC differs from GameMaker");
	});

	addFact("int64 variable + 1 [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_rt_int64_plus), "string:number:1099511627776", "GameMaker no longer gives the measured result");
	});
	addFact("int64 variable + 1 [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = $FFFFFFFFFF; var b = 1; var r = a + b; return typeof(r) + ":" + string(r);'); }), "string:number:1099511627776", "GMLC differs from GameMaker");
	});

	addFact("a && b on variables [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_rt_and), "string:bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("a && b on variables [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 0b1011; var b = 0b1011; var r = a && b; return typeof(r) + ":" + string(r);'); }), "string:bool:1", "GMLC differs from GameMaker");
	});

	addFact("!a on a variable [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_rt_lnot), "string:bool:0", "GameMaker no longer gives the measured result");
	});
	addFact("!a on a variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 0xA7; var r = !a; return typeof(r) + ":" + string(r);'); }), "string:bool:0", "GMLC differs from GameMaker");
	});

	addFact("shift by 167 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_shift_0), "string:number:0", "GameMaker no longer gives the measured result");
	});
	addFact("shift by 167 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 11 << 167; return typeof(r) + ":" + string(r);'); }), "string:int64:6047313952768", "GMLC differs from GameMaker");
	});

	addFact("shift by 64 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_shift_1), "string:number:0", "GameMaker no longer gives the measured result");
	});
	addFact("shift by 64 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 11 << 64; return typeof(r) + ":" + string(r);'); }), "string:int64:11", "GMLC differs from GameMaker");
	});

	addFact("negative right shift by 167 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_shift_2), "string:number:0", "GameMaker no longer gives the measured result");
	});
	addFact("negative right shift by 167 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = -11 >> 167; return typeof(r) + ":" + string(r);'); }), "string:int64:-1", "GMLC differs from GameMaker");
	});

	addFact("shift by 63 (constants) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_shift_3), "string:int64:-9223372036854775808", "GameMaker no longer gives the measured result");
	});
	addFact("shift by 63 (constants) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = 11 << 63; return typeof(r) + ":" + string(r);'); }), "string:int64:-9223372036854775808", "GMLC differs from GameMaker");
	});

	addFact("a << 64 on variables [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_rt_shift_64), "string:int64:11", "GameMaker no longer gives the measured result");
	});
	addFact("a << 64 on variables [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = 11; var c = 64; var r = a << c; return typeof(r) + ":" + string(r);'); }), "string:int64:11", "GMLC differs from GameMaker");
	});

	addFact("5 & 3 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_5_band_3_rt), "string:int64:1", "GameMaker no longer gives the measured result");
	});
	addFact("5 & 3 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(5) & case_id(3); return typeof(r) + ":" + string(r);'); }), "string:int64:1", "GMLC differs from GameMaker");
	});

	addFact("5 | 3 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_5_bor_3_rt), "string:int64:7", "GameMaker no longer gives the measured result");
	});
	addFact("5 | 3 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(5) | case_id(3); return typeof(r) + ":" + string(r);'); }), "string:int64:7", "GMLC differs from GameMaker");
	});

	addFact("5 ^ 3 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_5_bxor_3_rt), "string:int64:6", "GameMaker no longer gives the measured result");
	});
	addFact("5 ^ 3 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(5) ^ case_id(3); return typeof(r) + ":" + string(r);'); }), "string:int64:6", "GMLC differs from GameMaker");
	});

	addFact("1 << 3 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_1_shl_3_rt), "string:int64:8", "GameMaker no longer gives the measured result");
	});
	addFact("1 << 3 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(1) << case_id(3); return typeof(r) + ":" + string(r);'); }), "string:int64:8", "GMLC differs from GameMaker");
	});

	addFact("16 >> 2 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_16_shr_2_rt), "string:int64:4", "GameMaker no longer gives the measured result");
	});
	addFact("16 >> 2 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(16) >> case_id(2); return typeof(r) + ":" + string(r);'); }), "string:int64:4", "GMLC differs from GameMaker");
	});

	addFact("~5 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_not5_rt), "string:int64:-6", "GameMaker no longer gives the measured result");
	});
	addFact("~5 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = ~case_id(5); return typeof(r) + ":" + string(r);'); }), "string:int64:-6", "GMLC differs from GameMaker");
	});

	addFact("7 div 2 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_7_div_2_rt), "string:number:3", "GameMaker no longer gives the measured result");
	});
	addFact("7 div 2 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(7) div case_id(2); return typeof(r) + ":" + string(r);'); }), "string:number:3", "GMLC differs from GameMaker");
	});

	addFact("7 mod 3 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_7_mod_3_rt), "string:number:1", "GameMaker no longer gives the measured result");
	});
	addFact("7 mod 3 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(7) mod case_id(3); return typeof(r) + ":" + string(r);'); }), "string:number:1", "GMLC differs from GameMaker");
	});

	addFact("2 + 3 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_2_plus_3_rt), "string:number:5", "GameMaker no longer gives the measured result");
	});
	addFact("2 + 3 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(2) + case_id(3); return typeof(r) + ":" + string(r);'); }), "string:number:5", "GMLC differs from GameMaker");
	});

	addFact("7 / 2 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_7_over_2_rt), "string:number:3.50", "GameMaker no longer gives the measured result");
	});
	addFact("7 / 2 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(7) / case_id(2); return typeof(r) + ":" + string(r);'); }), "string:number:3.50", "GMLC differs from GameMaker");
	});

	addFact("-5 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_minus5_rt), "string:number:-5", "GameMaker no longer gives the measured result");
	});
	addFact("-5 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = -case_id(5); return typeof(r) + ":" + string(r);'); }), "string:number:-5", "GMLC differs from GameMaker");
	});

	addFact("1 == 1 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_1_eq_1_rt), "string:bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("1 == 1 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(1) == case_id(1); return typeof(r) + ":" + string(r);'); }), "string:bool:1", "GMLC differs from GameMaker");
	});

	addFact("2147483648 | 0 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_2147483648_bor_0_rt), "string:int64:2147483648", "GameMaker no longer gives the measured result");
	});
	addFact("2147483648 | 0 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(2147483648) | case_id(0); return typeof(r) + ":" + string(r);'); }), "string:int64:2147483648", "GMLC differs from GameMaker");
	});

	addFact("0x80000000 & 1 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_0x80000000_band_1_rt), "string:int64:0", "GameMaker no longer gives the measured result");
	});
	addFact("0x80000000 & 1 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(0x80000000) & case_id(1); return typeof(r) + ":" + string(r);'); }), "string:int64:0", "GMLC differs from GameMaker");
	});

	addFact("$80000000 & 1 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hex80000000_band_1_rt), "string:int64:0", "GameMaker no longer gives the measured result");
	});
	addFact("$80000000 & 1 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id($80000000) & case_id(1); return typeof(r) + ":" + string(r);'); }), "string:int64:0", "GMLC differs from GameMaker");
	});

	addFact("2147483648 + 1 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_2147483648_plus_1_rt), "string:number:2147483649", "GameMaker no longer gives the measured result");
	});
	addFact("2147483648 + 1 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(2147483648) + case_id(1); return typeof(r) + ":" + string(r);'); }), "string:number:2147483649", "GMLC differs from GameMaker");
	});

	addFact("$FFFFFFFFFF + 1 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hexffffffffff_plus_1_rt), "string:number:1099511627776", "GameMaker no longer gives the measured result");
	});
	addFact("$FFFFFFFFFF + 1 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id($FFFFFFFFFF) + case_id(1); return typeof(r) + ":" + string(r);'); }), "string:number:1099511627776", "GMLC differs from GameMaker");
	});

	addFact("$FFFFFFFFFF & 1 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hexffffffffff_band_1_rt), "string:int64:1", "GameMaker no longer gives the measured result");
	});
	addFact("$FFFFFFFFFF & 1 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id($FFFFFFFFFF) & case_id(1); return typeof(r) + ":" + string(r);'); }), "string:int64:1", "GMLC differs from GameMaker");
	});

	addFact("$7FFFFFFF & 1 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hex7fffffff_band_1_rt), "string:int64:1", "GameMaker no longer gives the measured result");
	});
	addFact("$7FFFFFFF & 1 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id($7FFFFFFF) & case_id(1); return typeof(r) + ":" + string(r);'); }), "string:int64:1", "GMLC differs from GameMaker");
	});

	addFact("4294967296 & 1 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_4294967296_band_1_rt), "string:int64:0", "GameMaker no longer gives the measured result");
	});
	addFact("4294967296 & 1 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(4294967296) & case_id(1); return typeof(r) + ":" + string(r);'); }), "string:int64:0", "GMLC differs from GameMaker");
	});

	addFact("$100000000 & 1 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hex100000000_band_1_rt), "string:int64:0", "GameMaker no longer gives the measured result");
	});
	addFact("$100000000 & 1 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id($100000000) & case_id(1); return typeof(r) + ":" + string(r);'); }), "string:int64:0", "GMLC differs from GameMaker");
	});

	addFact("~2147483648 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_not2147483648_rt), "string:int64:-2147483649", "GameMaker no longer gives the measured result");
	});
	addFact("~2147483648 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = ~case_id(2147483648); return typeof(r) + ":" + string(r);'); }), "string:int64:-2147483649", "GMLC differs from GameMaker");
	});

	addFact("2147483648 << 1 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_2147483648_shl_1_rt), "string:int64:4294967296", "GameMaker no longer gives the measured result");
	});
	addFact("2147483648 << 1 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(2147483648) << case_id(1); return typeof(r) + ":" + string(r);'); }), "string:int64:4294967296", "GMLC differs from GameMaker");
	});

	addFact("$80000000 * 2 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hex80000000_times_2_rt), "string:number:4294967296", "GameMaker no longer gives the measured result");
	});
	addFact("$80000000 * 2 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id($80000000) * case_id(2); return typeof(r) + ":" + string(r);'); }), "string:number:4294967296", "GMLC differs from GameMaker");
	});

	addFact("2147483648 * 2 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_2147483648_times_2_rt), "string:number:4294967296", "GameMaker no longer gives the measured result");
	});
	addFact("2147483648 * 2 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(2147483648) * case_id(2); return typeof(r) + ":" + string(r);'); }), "string:number:4294967296", "GMLC differs from GameMaker");
	});

	addFact("$80000000 div 2 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_hex80000000_div_2_rt), "string:number:1073741824", "GameMaker no longer gives the measured result");
	});
	addFact("$80000000 div 2 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id($80000000) div case_id(2); return typeof(r) + ":" + string(r);'); }), "string:number:1073741824", "GMLC differs from GameMaker");
	});

	addFact("(1 + 2) & 3 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_1_plus_2_band_3_rt), "string:int64:3", "GameMaker no longer gives the measured result");
	});
	addFact("(1 + 2) & 3 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = (case_id(1) + case_id(2)) & case_id(3); return typeof(r) + ":" + string(r);'); }), "string:int64:3", "GMLC differs from GameMaker");
	});

	addFact("true + 1 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_true_plus_1_rt), "string:number:2", "GameMaker no longer gives the measured result");
	});
	addFact("true + 1 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(true) + case_id(1); return typeof(r) + ":" + string(r);'); }), "string:number:2", "GMLC differs from GameMaker");
	});

	addFact("!0xA7 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_lnot0xa7_rt), "string:bool:0", "GameMaker no longer gives the measured result");
	});
	addFact("!0xA7 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = !case_id(0xA7); return typeof(r) + ":" + string(r);'); }), "string:bool:0", "GMLC differs from GameMaker");
	});

	addFact("0b1011 && 0b1011 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_0b1011_and_0b1011_rt), "string:bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("0b1011 && 0b1011 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(0b1011) && case_id(0b1011); return typeof(r) + ":" + string(r);'); }), "string:bool:1", "GMLC differs from GameMaker");
	});

	addFact("1.5 ^^ 167 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_1_5_xor_167_rt), "string:bool:0", "GameMaker no longer gives the measured result");
	});
	addFact("1.5 ^^ 167 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(1.5) ^^ case_id(167); return typeof(r) + ":" + string(r);'); }), "string:bool:0", "GMLC differs from GameMaker");
	});

	addFact("shift by 167 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_shift_0_rt), "string:int64:6047313952768", "GameMaker no longer gives the measured result");
	});
	addFact("shift by 167 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(11) << case_id(167); return typeof(r) + ":" + string(r);'); }), "string:int64:6047313952768", "GMLC differs from GameMaker");
	});

	addFact("shift by 64 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_shift_1_rt), "string:int64:11", "GameMaker no longer gives the measured result");
	});
	addFact("shift by 64 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(11) << case_id(64); return typeof(r) + ":" + string(r);'); }), "string:int64:11", "GMLC differs from GameMaker");
	});

	addFact("negative right shift by 167 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_shift_2_rt), "string:int64:-1", "GameMaker no longer gives the measured result");
	});
	addFact("negative right shift by 167 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = -case_id(11) >> case_id(167); return typeof(r) + ":" + string(r);'); }), "string:int64:-1", "GMLC differs from GameMaker");
	});

	addFact("shift by 63 (values) [GameMaker]", function() {
		assert_equals(case_run(case_constant_folding_const_shift_3_rt), "string:int64:-9223372036854775808", "GameMaker no longer gives the measured result");
	});
	addFact("shift by 63 (values) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var r = case_id(11) << case_id(63); return typeof(r) + ":" + string(r);'); }), "string:int64:-9223372036854775808", "GMLC differs from GameMaker");
	});
}

function case_constant_folding_const_5_band_3() {
var r = 5 & 3; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_5_bor_3() {
var r = 5 | 3; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_5_bxor_3() {
var r = 5 ^ 3; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_1_shl_3() {
var r = 1 << 3; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_16_shr_2() {
var r = 16 >> 2; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_not5() {
var r = ~5; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_7_div_2() {
var r = 7 div 2; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_7_mod_3() {
var r = 7 mod 3; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_2_plus_3() {
var r = 2 + 3; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_7_over_2() {
var r = 7 / 2; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_minus5() {
var r = -5; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_1_eq_1() {
var r = 1 == 1; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_2147483648_bor_0() {
var r = 2147483648 | 0; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_0x80000000_band_1() {
var r = 0x80000000 & 1; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hex80000000_band_1() {
var r = $80000000 & 1; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_2147483648_plus_1() {
var r = 2147483648 + 1; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hexffffffffff_plus_1() {
var r = $FFFFFFFFFF + 1; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hexffffffffff_band_1() {
var r = $FFFFFFFFFF & 1; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hex7fffffff_band_1() {
var r = $7FFFFFFF & 1; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_4294967296_band_1() {
var r = 4294967296 & 1; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hex100000000_band_1() {
var r = $100000000 & 1; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_not2147483648() {
var r = ~2147483648; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_2147483648_shl_1() {
var r = 2147483648 << 1; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hex80000000_times_2() {
var r = $80000000 * 2; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_2147483648_times_2() {
var r = 2147483648 * 2; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hex80000000_div_2() {
var r = $80000000 div 2; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_1_plus_2_band_3() {
var r = (1 + 2) & 3; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_true_plus_1() {
var r = true + 1; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_lnot0xa7() {
var r = !0xA7; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_0b1011_and_0b1011() {
var r = 0b1011 && 0b1011; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_1_5_xor_167() {
var r = 1.5 ^^ 167; return typeof(r) + ":" + string(r);
}

function case_constant_folding_rt_band() {
var a = 5; var b = 3; var r = a & b; return typeof(r) + ":" + string(r);
}

function case_constant_folding_rt_int64_plus() {
var a = $FFFFFFFFFF; var b = 1; var r = a + b; return typeof(r) + ":" + string(r);
}

function case_constant_folding_rt_and() {
var a = 0b1011; var b = 0b1011; var r = a && b; return typeof(r) + ":" + string(r);
}

function case_constant_folding_rt_lnot() {
var a = 0xA7; var r = !a; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_shift_0() {
var r = 11 << 167; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_shift_1() {
var r = 11 << 64; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_shift_2() {
var r = -11 >> 167; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_shift_3() {
var r = 11 << 63; return typeof(r) + ":" + string(r);
}

function case_constant_folding_rt_shift_64() {
var a = 11; var c = 64; var r = a << c; return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_5_band_3_rt() {
var r = case_id(5) & case_id(3); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_5_bor_3_rt() {
var r = case_id(5) | case_id(3); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_5_bxor_3_rt() {
var r = case_id(5) ^ case_id(3); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_1_shl_3_rt() {
var r = case_id(1) << case_id(3); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_16_shr_2_rt() {
var r = case_id(16) >> case_id(2); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_not5_rt() {
var r = ~case_id(5); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_7_div_2_rt() {
var r = case_id(7) div case_id(2); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_7_mod_3_rt() {
var r = case_id(7) mod case_id(3); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_2_plus_3_rt() {
var r = case_id(2) + case_id(3); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_7_over_2_rt() {
var r = case_id(7) / case_id(2); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_minus5_rt() {
var r = -case_id(5); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_1_eq_1_rt() {
var r = case_id(1) == case_id(1); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_2147483648_bor_0_rt() {
var r = case_id(2147483648) | case_id(0); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_0x80000000_band_1_rt() {
var r = case_id(0x80000000) & case_id(1); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hex80000000_band_1_rt() {
var r = case_id($80000000) & case_id(1); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_2147483648_plus_1_rt() {
var r = case_id(2147483648) + case_id(1); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hexffffffffff_plus_1_rt() {
var r = case_id($FFFFFFFFFF) + case_id(1); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hexffffffffff_band_1_rt() {
var r = case_id($FFFFFFFFFF) & case_id(1); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hex7fffffff_band_1_rt() {
var r = case_id($7FFFFFFF) & case_id(1); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_4294967296_band_1_rt() {
var r = case_id(4294967296) & case_id(1); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hex100000000_band_1_rt() {
var r = case_id($100000000) & case_id(1); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_not2147483648_rt() {
var r = ~case_id(2147483648); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_2147483648_shl_1_rt() {
var r = case_id(2147483648) << case_id(1); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hex80000000_times_2_rt() {
var r = case_id($80000000) * case_id(2); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_2147483648_times_2_rt() {
var r = case_id(2147483648) * case_id(2); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_hex80000000_div_2_rt() {
var r = case_id($80000000) div case_id(2); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_1_plus_2_band_3_rt() {
var r = (case_id(1) + case_id(2)) & case_id(3); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_true_plus_1_rt() {
var r = case_id(true) + case_id(1); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_lnot0xa7_rt() {
var r = !case_id(0xA7); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_0b1011_and_0b1011_rt() {
var r = case_id(0b1011) && case_id(0b1011); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_1_5_xor_167_rt() {
var r = case_id(1.5) ^^ case_id(167); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_shift_0_rt() {
var r = case_id(11) << case_id(167); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_shift_1_rt() {
var r = case_id(11) << case_id(64); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_shift_2_rt() {
var r = -case_id(11) >> case_id(167); return typeof(r) + ":" + string(r);
}

function case_constant_folding_const_shift_3_rt() {
var r = case_id(11) << case_id(63); return typeof(r) + ":" + string(r);
}
