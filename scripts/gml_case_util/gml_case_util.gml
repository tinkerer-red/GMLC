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

function case_sum3(_a, _b, _c) {
	return _a + _b + _c;
}

function case_pair(_a, _b) constructor {
	a = _a;
	b = _b;
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
