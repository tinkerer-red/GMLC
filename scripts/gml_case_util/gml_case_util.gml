// Helpers of the GameMaker behavior suites. Generated; do not edit by hand.
global.__case_log = [];
// what `self` is in a script's top-level code (script-top-level-self)
global.__case_top_self_is_global = (self == global);
global.__case_top_self_type = typeof(self);
__case_top_variable = 7;

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

/// Calls _fn(_a, _b) and returns "message:" and the text of the error it throws, or "none".
function case_error(_fn, _a = undefined, _b = undefined) {
	try {
		_fn(_a, _b);
	}
	catch (_e) {
		return "message:" + (is_struct(_e) ? string(_e[$ "message"]) : string(_e));
	}
	return "none";
}

/// The real whose f64 bits are the 16 hexadecimal digits _hex (high word first): an exact operand.
function case_f64(_hex) {
	var _b = buffer_create(8, buffer_fixed, 1);
	buffer_poke(_b, 4, buffer_u32, case_hex_u32(string_copy(_hex, 1, 8)));
	buffer_poke(_b, 0, buffer_u32, case_hex_u32(string_copy(_hex, 9, 8)));
	var _x = buffer_peek(_b, 0, buffer_f64);
	buffer_delete(_b);
	return _x;
}

/// The int64 whose two's-complement bits are the 16 hexadecimal digits _hex (high word first).
function case_i64(_hex) {
	var _b = buffer_create(8, buffer_fixed, 1);
	buffer_poke(_b, 4, buffer_u32, case_hex_u32(string_copy(_hex, 1, 8)));
	buffer_poke(_b, 0, buffer_u32, case_hex_u32(string_copy(_hex, 9, 8)));
	var _x = buffer_peek(_b, 0, buffer_u64);
	buffer_delete(_b);
	return _x;
}

/// The value of 8 hexadecimal digits (upper case).
function case_hex_u32(_h) {
	var _n = 0;
	for (var _i = 1; _i <= 8; _i++) {
		_n = _n * 16 + string_pos(string_char_at(_h, _i), "0123456789ABCDEF") - 1;
	}
	return _n;
}

/// A method value for the value-model operands.
function case_method() {
	return method(undefined, case_id);
}

/// Exact text of a value-model result: "<typeof>:<payload>", references as "a", "b" or "c" when they are that
/// operand and "new" otherwise.
function case_vm_cap(_r, _a, _b, _c) {
	var _t = typeof(_r);
	switch (_t) {
		case "number": return "number:" + case_f64_hex(_r);
		case "int64":
		case "int32": return _t + ":" + string(_r);
		case "bool":
			// a bool can hold another number (`-true` holds -1): then its number is recorded too
			var _n = _r + 0;
			if (_n != 0) && (_n != 1) return "boolnum:" + (_r ? "1" : "0") + ":" + case_f64_hex(_n);
			return "bool:" + (_r ? "1" : "0");
		case "string":
			// a long result is kept as its length and digest
			var _len = string_byte_length(_r);
			if (_len > 4096) return "stringlong:" + string(_len) + ":" + sha1_string_utf8(_r);
			if (_len == 0) return "string64:";
			// every byte through a buffer (base64_encode of a string stops at a NUL byte)
			var _buf = buffer_create(_len, buffer_fixed, 1);
			buffer_write(_buf, buffer_text, _r);
			var _out = buffer_base64_encode(_buf, 0, _len);
			buffer_delete(_buf);
			return "string64:" + _out;
		case "undefined": return "undefined:";
		case "ptr": return "ptr:" + ((_r == pointer_null) ? "null" : "other");
	}
	if (typeof(_a) == _t && _r == _a) return _t + ":a";
	if (typeof(_b) == _t && _r == _b) return _t + ":b";
	if (typeof(_c) == _t && _r == _c) return _t + ":c";
	return _t + ":new";
}

/// Calls _fn(_a, _b, _c) and returns case_vm_cap of its result, or "error64:" and the base64 of the message of what
/// it throws (the first line of a runtime error's message; the typeof of a thrown non-struct).
function case_vm(_fn, _a = undefined, _b = undefined, _c = undefined) {
	var _r;
	try {
		_r = _fn(_a, _b, _c);
	}
	catch (_e) {
		var _m = is_struct(_e) ? string(_e[$ "message"]) : ("thrown " + typeof(_e));
		var _nl = string_pos(chr(10), _m);
		if (_nl > 0) _m = string_copy(_m, 1, _nl - 1);
		return "error64:" + base64_encode(_m);
	}
	// captured outside the try: a failure of the capture is never reported as the operation's error
	return case_vm_cap(_r, _a, _b, _c);
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
