// Helpers of the GameMaker behaviour suites. Generated; do not edit by hand.
global.__case_log = [];

/// Clears the evaluation log.
function case_log_reset() {
	global.__case_log = [];
}

/// Records _tag in the evaluation log and returns _value.
function case_ev(_tag, _value) {
	array_push(global.__case_log, _tag);
	return _value;
}

/// The evaluation log as "A,B,C".
function case_log() {
	var _s = "";
	for (var _i = 0; _i < array_length(global.__case_log); _i++) {
		_s += (_i > 0 ? "," : "") + string(global.__case_log[_i]);
	}
	return _s;
}

/// "<typeof>:<string>" of a value.
function case_repr(_v) {
	return typeof(_v) + ":" + string(_v);
}

/// Runs _fn and returns case_repr of its result, or "error" when it throws.
function case_run(_fn) {
	try {
		return case_repr(_fn());
	}
	catch (_e) {
		return "error";
	}
}

/// "<length>:<ord of each character>" of a string.
function case_ords(_s) {
	var _out = string(string_length(_s)) + ":";
	for (var _i = 1; _i <= string_length(_s); _i++) {
		_out += (_i > 1 ? "," : "") + string(ord(string_char_at(_s, _i)));
	}
	return _out;
}

/// Returns _v: a value the compiler cannot fold through.
function case_id(_v) {
	return _v;
}

function case_sum3(_a, _b, _c) {
	return _a + _b + _c;
}

function case_pair(_a, _b) constructor {
	a = _a;
	b = _b;
}

/// "<typeof>:<value>" with every bit of a number kept: "number:" and the 16 hexadecimal digits of its f64.
function case_exact(_v) {
	if (typeof(_v) == "number") return "number:" + case_f64_hex(_v);
	if (is_string(_v)) {
		// a string with bytes outside printable ASCII is written as base64, so the result file stays valid UTF-8
		for (var _i = 1; _i <= string_byte_length(_v); _i++) {
			var _byte = string_byte_at(_v, _i);
			if (_byte < 32) || (_byte > 126) return "string64:" + base64_encode(_v);
		}
	}
	return typeof(_v) + ":" + string(_v);
}

/// Calls _fn(_a, _b) and returns case_exact of its result, or "error" when it throws.
function case_try(_fn, _a = undefined, _b = undefined) {
	try {
		return case_exact(_fn(_a, _b));
	}
	catch (_e) {
		return "error";
	}
}

/// Eight hexadecimal digits of the low 32 bits of _n.
function case_hex32(_n) {
	var _h = "";
	repeat (8) {
		_h = string_char_at("0123456789ABCDEF", (_n & 15) + 1) + _h;
		_n = _n >> 4;
	}
	return _h;
}

/// The 8 bytes of _x written as buffer_f64, as 16 hexadecimal digits, high word first.
function case_f64_hex(_x) {
	var _b = buffer_create(8, buffer_fixed, 1);
	buffer_write(_b, buffer_f64, _x);
	var _lo = buffer_peek(_b, 0, buffer_u32);
	var _hi = buffer_peek(_b, 4, buffer_u32);
	buffer_delete(_b);
	return case_hex32(_hi) + case_hex32(_lo);
}

/// Compiles _src with the optimizer on and runs it.
function case_gmlc_optimized(_src) {
	static __env = undefined;
	if (__env == undefined) {
		__env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL).enable_test_mode(true);
		__env.should_optimize = true;
	}
	return executeProgram(__env.compile(_src));
}
