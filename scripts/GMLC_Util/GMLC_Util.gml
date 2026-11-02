#region Assets and Scripts
#region jsDoc
/// @func    asset_get_name(_asset)
/// @desc    The name of any asset, by its type; undefined for an unknown asset.
/// @param   {Asset} _asset : The asset
/// @returns {String}
#endregion
function asset_get_name(_asset) {
	var _type = asset_get_type(_asset);
	switch(_type) {
		case asset_object:         return object_get_name(_asset);
		case asset_sprite:         return sprite_get_name(_asset);
		case asset_sound:          return audio_get_name(_asset);
		case asset_room:           return room_get_name(_asset);
		case asset_tiles:          return tileset_get_name(_asset);
		case asset_path:           return path_get_name(_asset);
		case asset_script:         return script_get_name(_asset);
		case asset_font:           return font_get_name(_asset);
		case asset_timeline:       return timeline_get_name(_asset);
		case asset_shader:         return shader_get_name(_asset);
		case asset_animationcurve: return animcurve_get(_asset).name;
		case asset_sequence:       return sequence_get(_asset).name;
		case asset_particlesystem: return particle_get_info(_asset).name;
		
		case asset_unknown: default:
			return undefined;
	}
}

#region jsDoc
/// @func    is_script(_value)
/// @desc    Whether a value is the handle of a script or built-in function.
/// @param   {Any} _value : The value
/// @returns {Bool}
#endregion
function is_script(_value) {
	if !is_handle(_value) return false;
	return script_exists(_value);
}

#region jsDoc
/// @func    script_get_index(_script_name)
/// @desc    The index of a script or built-in function by name; asset_get_index gives -1 for built-ins.
/// @param   {String} _script_name : The name
/// @returns {Real}
#endregion
function script_get_index(_script_name) {
	static __built_in_lookup = undefined;
	
	//entirely because asset_get_index returns -1 for builtin functions
	if (__built_in_lookup == undefined) {
		var _lookup = {};
		
		var _i=0; repeat(10_000) {
			var _name = script_get_name(_i);
			if !(string_starts_with(_name, "@")) {
				_lookup[$ _name] = _i;
			}
		_i++}
		
		__built_in_lookup = _lookup;
	}
	
	return __built_in_lookup[$ _script_name] ?? asset_get_index(_script_name);
}
#endregion

#region Structs
#region jsDoc
/// @func    struct_filter(_input, _predicate)
/// @desc    A new struct with the entries of _input for which _predicate(key, value) is true.
/// @param   {Struct}   _input     : The struct
/// @param   {Function} _predicate : function(key, value) -> Bool
/// @returns {Struct}
#endregion
function struct_filter(_input, _predicate) {
	var _output = {};
	var _keys = struct_get_names(_input);
	
	for (var i = 0; i < array_length(_keys); i++) {
		var _key = _keys[i];
		var _value = _input[$ _key];
		
		if (_predicate(_key, _value)) {
			_output[$ _key] = _value;
		}
	}
	
	return _output;
}

#region jsDoc
/// @func    static_exists(_struct, _name)
/// @desc    Whether a struct's statics, or the statics of their parents, hold a name.
/// @param   {Struct} _struct : The struct
/// @param   {String} _name   : The name
/// @returns {Bool}
#endregion
function static_exists(_struct, _name) {
	var _static = static_get(_struct)
	
	//early out
	if (_static[$ _name] != undefined) return true;
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, _name) { return true; }
		_static = static_get(_static)
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_struct_has(_struct, _key)
/// @desc    struct_exists for tables keyed by names from source code: every struct answers `toString` with the same
///          default method, which does not count; a `toString` the table itself holds does.
/// @param   {Struct} _struct : The table
/// @param   {String} _key    : The name
/// @returns {Bool}
#endregion
function __gmlc_struct_has(_struct, _key) {
	static __defaultToString = undefined;
	if (__defaultToString == undefined) {
		var _empty = {};
		__defaultToString = _empty[$ "toString"];
	}
	if (!struct_exists(_struct, _key)) return false;
	return (_key != "toString") || (_struct[$ _key] != __defaultToString);
}

#region jsDoc
/// @func    __gmlc_struct_get(_struct, _key)
/// @desc    The value of a name in a table keyed by names from source code, undefined when the table itself does
///          not hold it.
/// @param   {Struct} _struct : The table
/// @param   {String} _key    : The name
/// @returns {Any}
#endregion
function __gmlc_struct_get(_struct, _key) {
	return __gmlc_struct_has(_struct, _key) ? _struct[$ _key] : undefined;
}
#endregion

#region Numbers
#region jsDoc
/// @func    __gmlc_is_zero(_x)
/// @desc    Whether a number is exactly 0 or -0. GameMaker compares reals within math_get_epsilon (`0.00001 == 0` is
///          true), so the compiler's own decisions read the bits.
/// @param   {Real} _x : The number
/// @returns {Bool}
#endregion
function __gmlc_is_zero(_x) {
	static __buffer = buffer_create(8, buffer_fixed, 1);
	buffer_poke(__buffer, 0, buffer_f64, _x);
	return (buffer_peek(__buffer, 0, buffer_u32) == 0) && ((buffer_peek(__buffer, 4, buffer_u32) & 0x7FFFFFFF) == 0);
}

#region jsDoc
/// @func    __gmlc_same_real(_a, _b)
/// @desc    Whether two numbers have the same bits.
/// @param   {Real} _a : A number
/// @param   {Real} _b : A number
/// @returns {Bool}
#endregion
function __gmlc_same_real(_a, _b) {
	static __buffer = buffer_create(16, buffer_fixed, 1);
	buffer_poke(__buffer, 0, buffer_f64, _a);
	buffer_poke(__buffer, 8, buffer_f64, _b);
	return (buffer_peek(__buffer, 0, buffer_u32) == buffer_peek(__buffer, 8, buffer_u32)) && (buffer_peek(__buffer, 4, buffer_u32) == buffer_peek(__buffer, 12, buffer_u32));
}

#region jsDoc
/// @func    __gmlc_is_whole(_x)
/// @desc    Whether a number is exactly a whole number; NaN and the infinities are not.
/// @param   {Real} _x : The number
/// @returns {Bool}
#endregion
function __gmlc_is_whole(_x) {
	// frac of an infinity is 0 in GameMaker
	if (is_nan(_x)) || (is_infinity(_x)) return false;
	return __gmlc_is_zero(frac(_x));
}

#region jsDoc
/// @func    __gmlc_power_folds(_x, _y, _result)
/// @desc    Whether `power(_x, _y)` folds: whole arguments, an exponent from 0 to 64 and a whole result within 2^53,
///          which every C runtime gives exactly; other results may differ in their last bit from one runtime to
///          another.
/// @param   {Any} _x      : The base
/// @param   {Any} _y      : The exponent
/// @param   {Any} _result : What power gave
/// @returns {Bool}
#endregion
function __gmlc_power_folds(_x, _y, _result) {
	if (!is_numeric(_x)) || (!is_numeric(_y)) || (!is_numeric(_result)) return false;
	return __gmlc_is_whole(_x) && __gmlc_is_whole(_y) && (_y >= 0) && (_y <= 64) && __gmlc_is_whole(_result)
		&& (abs(_result) <= 9007199254740992);
}

#region jsDoc
/// @func    __gmlc_string_format_folds(_args)
/// @desc    Whether `string_format` may run while compiling: GameMaker's runner ends outright when the text passes
///          about 1100 characters, so a width or decimal count above 512 or not finite, or a value of 10^100 or
///          more, stays a call.
/// @param   {Array} _args : The arguments
/// @returns {Bool}
#endregion
function __gmlc_string_format_folds(_args) {
	static __largest = power(10, 100);
	var _i = 1; repeat (2) {
		var _n = _args[_i];
		if (is_numeric(_n)) && ((is_nan(_n)) || (is_infinity(_n)) || (abs(_n) > 512)) return false;
	_i++}
	var _x = _args[0];
	return !(is_numeric(_x) && (abs(_x) >= __largest));
}

#region jsDoc
/// @func    __gmlc_int32(_x)
/// @desc    An int64 cut to its low 32 bits, read as a signed int32, as GameMaker's runtime reads a count or a size.
/// @param   {Real} _x : The number
/// @returns {Real}
#endregion
function __gmlc_int32(_x) {
	var _n = _x & 0xFFFFFFFF;
	return (_n >= 0x80000000) ? _n - 0x100000000 : _n;
}

#region jsDoc
/// @func    __gmlc_string_repeat_failure(_args)
/// @desc    How a constant `string_repeat` fails when its length passes int32. GameMaker reads the count as an int32,
///          computes the length (byte length times count) in int32 and asks for that length plus one bytes: a request
///          that reads as -33 or less throws "Memory allocation failed"; any other succeeds, and writing the string
///          past it ends the runner. Returns [ends the runner, message], or undefined when the call does not fail
///          this way.
/// @param   {Array} _args : The arguments
/// @returns {Array,Undefined}
#endregion
function __gmlc_string_repeat_failure(_args) {
	static __int64Range = power(2, 63);
	var _text = _args[0];
	var _count = _args[1];
	if (!is_string(_text)) || (!is_numeric(_count)) return undefined;
	if (is_real(_count)) && ((is_nan(_count)) || (abs(_count) >= __int64Range)) return undefined;
	var _n = __gmlc_int32(int64(_count));
	if (_n <= 0) return undefined;
	var _length = string_byte_length(_text) * _n;
	if (_length < 2147483647) return undefined;
	var _request = __gmlc_int32(_length + 1);
	if (_request > -33) return [true, "a string of " + string(_length) + " bytes from string_repeat"];
	// the request as an unsigned 64-bit size, 2^64 plus a request from -2^31 to -33
	return [false, "Memory allocation failed: Attempting to allocate 1844674407" + string(1562067968 + (_request + 2147483648)) + " bytes\n"];
}

#region jsDoc
/// @func    __gmlc_real_text(_x)
/// @desc    A real as the shortest decimal text that reads back to the same value, without an exponent (GML has no
///          exponent literals): json_stringify's 17 significant digits rounded to the fewest that read back, with the
///          point moved; NaN and the infinities by their GML names. `string` rounds for display.
/// @param   {Real} _x : The number
/// @returns {String}
#endregion
function __gmlc_real_text(_x) {
	if (is_nan(_x)) return "NaN";
	if (is_infinity(_x)) return (_x > 0) ? "infinity" : "-infinity";
	var _text = json_stringify(_x);
	var _e = string_pos("e", _text);
	var _mantissa = (_e == 0) ? _text : string_copy(_text, 1, _e - 1);
	var _exponent = (_e == 0) ? 0 : real(string_delete(_text, 1, _e));
	var _sign = "";
	if (string_char_at(_mantissa, 1) == "-") {
		_sign = "-";
		_mantissa = string_delete(_mantissa, 1, 1);
	}
	var _dot = string_pos(".", _mantissa);
	var _digits = (_dot == 0) ? _mantissa : string_delete(_mantissa, _dot, 1);
	var _point = ((_dot == 0) ? string_length(_mantissa) : _dot - 1) + _exponent;
	while (string_length(_digits) > 1) && (string_char_at(_digits, 1) == "0") {
		_digits = string_delete(_digits, 1, 1);
		_point -= 1;
	}
	while (string_length(_digits) > 1) && (string_char_at(_digits, string_length(_digits)) == "0") {
		_digits = string_copy(_digits, 1, string_length(_digits) - 1);
	}
	if (_digits == "0") return _sign + "0";
	var _count = 1; repeat (string_length(_digits) - 1) {
		var _rounded = __gmlc_real_round_digits(_digits, _count, _point);
		var _candidate = __gmlc_real_place_point(_sign, _rounded[0], _rounded[1]);
		if (__gmlc_same_real(real(_candidate), _x)) return _candidate;
	_count++}
	return __gmlc_real_place_point(_sign, _digits, _point);
}

#region jsDoc
/// @func    __gmlc_real_round_digits(_digits, _count, _point)
/// @desc    The first `_count` of `_digits`, rounded half up on the next digit, without trailing zeros, and the
///          point position (one more when the rounding carries past the first digit).
/// @param   {String} _digits : Significant digits
/// @param   {Real} _count : How many to keep (fewer than there are)
/// @param   {Real} _point : The number of digits before the decimal point
/// @returns {Array} [digits, point]
#endregion
function __gmlc_real_round_digits(_digits, _count, _point) {
	var _out = string_copy(_digits, 1, _count);
	var _at = _point;
	if (ord(string_char_at(_digits, _count + 1)) >= ord("5")) {
		var _k = _count;
		while (true) {
			if (_k == 0) {
				_out = "1" + string_copy(_out, 1, string_length(_out) - 1);
				_at += 1;
				break;
			}
			var _c = string_char_at(_out, _k);
			if (_c == "9") {
				_out = string_set_byte_at(_out, _k, ord("0"));
			}
			else {
				_out = string_set_byte_at(_out, _k, ord(_c) + 1);
				break;
			}
			_k -= 1;
		}
	}
	while (string_length(_out) > 1) && (string_char_at(_out, string_length(_out)) == "0") {
		_out = string_copy(_out, 1, string_length(_out) - 1);
	}
	return [_out, _at];
}

#region jsDoc
/// @func    __gmlc_real_place_point(_sign, _digits, _point)
/// @desc    Significant digits with `_point` digits before the decimal point, written without an exponent.
/// @param   {String} _sign : "" or "-"
/// @param   {String} _digits : Significant digits
/// @param   {Real} _point : The number of digits before the decimal point
/// @returns {String}
#endregion
function __gmlc_real_place_point(_sign, _digits, _point) {
	var _count = string_length(_digits);
	if (_point <= 0) return _sign + "0." + string_repeat("0", -_point) + _digits;
	if (_point >= _count) return _sign + _digits + string_repeat("0", _point - _count);
	return _sign + string_copy(_digits, 1, _point) + "." + string_delete(_digits, 1, _point);
}
#endregion

#region Constructors
#region jsDoc
/// @description Creates a new constructor instance from the specified constructor and array of arguments.
/// @param {Function} Constructor Description
/// @param {Array<Any>} [args] Description
/// @param {Real} [offset] Description
/// @param {Real} [length] Description
/// @pure
/// @return {Struct}
/// feather ignore all
#endregion
function constructor_call_ext(_constructor, _args = undefined, _offset = 0, _length = undefined) {
	_length ??= is_array(_args) ? array_length(_args) : 0;
	_args ??= [];
	
	// Short circuting, since the arguments array is optional!
	// not for GMLC constructors: they read their program data through `other`, which only the with() path below sets
	if (_length == 0) && (!is_gmlc_constructor(_constructor)) {
		return new _constructor();
	}
	
	var _struct = {};
	var _self = self;
	
	if (is_method(_constructor)) {
		_self = method_get_self(_constructor);
	}
	
	/* 
		Method scopes can have `undefined`, so this needs to be treated as such.
		We are also doing a double with(), to be respectful of `other` scope rules. 
		Which includes methodized constructors with a set scope.
	*/
	with (_self ?? self) {
		with (_struct) {
			/* 
				Note: Yes, `script_execute_ext` working on methods 
				I've been informed it is indeed intentional. 
				See here https://discord.com/channels/724320164371497020/1009467299956269076/1292512712500318218
			        Or https://github.com/YoYoGames/GameMaker-Bugs/issues/7920
                        */
			script_execute_ext(_constructor, _args, _offset, _length);
			return _struct;
		}
	}
}

#region jsDoc
/// @func    __gmlc_new_native(_constructor, _args)
/// @desc    Runs `new _constructor(...)` with the values of _args as arguments, for constructors that are not GMLC
///          constructors (GameMaker's own `new` sets up `self` and the statics). Up to 16 arguments use `new`
///          directly; more go through constructor_call_ext.
/// @param   {Function}   _constructor : The constructor
/// @param   {Array<Any>} _args        : The arguments
/// @returns {Struct}
#endregion
function __gmlc_new_native(_constructor, _args) {
	var a = _args;
	switch (array_length(a)) {
		case 0:  return new _constructor();
		case 1:  return new _constructor(a[0]);
		case 2:  return new _constructor(a[0], a[1]);
		case 3:  return new _constructor(a[0], a[1], a[2]);
		case 4:  return new _constructor(a[0], a[1], a[2], a[3]);
		case 5:  return new _constructor(a[0], a[1], a[2], a[3], a[4]);
		case 6:  return new _constructor(a[0], a[1], a[2], a[3], a[4], a[5]);
		case 7:  return new _constructor(a[0], a[1], a[2], a[3], a[4], a[5], a[6]);
		case 8:  return new _constructor(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7]);
		case 9:  return new _constructor(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8]);
		case 10: return new _constructor(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9]);
		case 11: return new _constructor(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10]);
		case 12: return new _constructor(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11]);
		case 13: return new _constructor(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11], a[12]);
		case 14: return new _constructor(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11], a[12], a[13]);
		case 15: return new _constructor(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11], a[12], a[13], a[14]);
		case 16: return new _constructor(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11], a[12], a[13], a[14], a[15]);
	}
	return constructor_call_ext(_constructor, _args);
}
#endregion

#region GMLC Type Checks
#region jsDoc
/// @func    is_gmlc_program(_program)
/// @desc    Whether a value is a program GMLC compiled.
/// @param   {Any} _program : The value
/// @returns {Bool}
#endregion
function is_gmlc_program(_program) {
	if (is_method(_program)) {
		var _self = method_get_self(_program);
		if (_self != undefined)
		&& (_self != global)
		&& (struct_exists(_self, "__@@is_gmlc_program@@__")) {
				return true;
		}
	}
	return false;
}

#region jsDoc
/// @func    is_gmlc_function(_program)
/// @desc    Whether a value is a function GMLC compiled.
/// @param   {Any} _program : The value
/// @returns {Bool}
#endregion
function is_gmlc_function(_program) {
	if (is_method(_program)) {
		var _func = method_get_index(_program)
		if (_func == __GMLCexecuteFunction) || (_func == __GMLCexecuteFunctionDirect)
		|| (_func == static_get(__gmlc_method)[$ "__executeMethodFunction"]) {
			return true;
		}
	}
	return false;
}

#region jsDoc
/// @func    is_gmlc_constructor(_program)
/// @desc    Whether a value is a constructor GMLC compiled.
/// @param   {Any} _program : The value
/// @returns {Bool}
#endregion
function is_gmlc_constructor(_program) {
	if (is_method(_program)) {
		var _func = method_get_index(_program)
		if (_func == __GMLCexecuteConstructor)
		|| (_func == static_get(__gmlc_method)[$ "__executeMethodConstructor"]) {
			return true;
		}
	}
	return false;
}

#region jsDoc
/// @func    is_gmlc_method(_program)
/// @desc    Whether a value is a GMLC function bound to a `self` with method().
/// @param   {Any} _program : The value
/// @returns {Bool}
#endregion
function is_gmlc_method(_program) {
	if (is_method(_program)) {
		var _self = method_get_self(_program);
		if (_self != undefined)
		&& (_self != global)
		&& (struct_exists(_self, "__@@is_gmlc_method@@__")) {
				return true;
		}
	}
	return false;
}

#region jsDoc
/// @func    is_gmlc_constructed(_struct)
/// @desc    Whether a struct was made by a GMLC constructor.
/// @param   {Any} _struct : The value
/// @returns {Bool}
#endregion
function is_gmlc_constructed(_struct) {
	//this only returns true when ever a struct was created by a gmlc constructor,
	// there is no reason to use this for anything else,
	// as a generic struct made by gmlc would still only need to be a struct
	// no need for additional information
	return !is_method(_struct)
		&& is_struct(_struct)
		&& is_struct(static_get(_struct)) // sometimes its undefined
		&& struct_exists(static_get(_struct), "__@@is_gmlc_constructed@@__")
}
#endregion

#region Errors
#region jsDoc
/// @func    __gmlc_node_position(_node)
/// @desc    Where a compiled node is in its source: file name, line, column and line text, from its span and the
///          program's source table; undefined when the node has none.
/// @param   {Struct} _node : A compiled node (anything with `span` and `root_node`)
/// @returns {Struct|Undefined}
#endregion
function __gmlc_node_position(_node) {
	var _span = is_struct(_node) ? _node[$ "span"] : undefined;
	var _root = is_struct(_node) ? _node[$ "root_node"] : undefined;
	var _sources = is_struct(_root) ? _root[$ "sources"] : undefined;
	if (_span == undefined) || (_sources == undefined) return undefined;
	return _sources.position(_span);
}

#region jsDoc
/// @func    throw_gmlc_error(_err, [_line], [_lineString], [_column], [_script])
/// @desc    Throws an error of a compiled program as GameMaker shapes its errors; the place comes from the
///          arguments, else from the node or token that throws.
/// @param   {Any}    _err          : The message
/// @param   {Real}   [_line]       : The line
/// @param   {String} [_lineString] : The line's text
/// @param   {Real}   [_column]     : The column
/// @param   {String} [_script]     : The file's name
#endregion
function throw_gmlc_error(_err, _line=undefined, _lineString=undefined, _column=undefined, _script=undefined) {
	var _token = struct_get(self, "current_token");
	var _env   = struct_get(self, "env");
	
	if (_line == undefined) {
		var _at = __gmlc_node_position(self);
		if (_at != undefined) {
			_line = _at.line;
			_lineString ??= _at.lineString;
			_column ??= _at.column;
			_script ??= _at.fileName;
		}
	}
	
	if (_line == undefined) {
		_line = (_token != undefined) ? struct_get(_token, "line") : undefined;
		if (_line == undefined) _line = struct_get(self, "line") ?? 0;
	}
	if (_lineString == undefined) {
		_lineString = (_token != undefined) ? struct_get(_token, "lineString") : undefined;
		if (_lineString == undefined) _lineString = struct_get(self, "lineString") ?? "";
	}
	if (_column == undefined) {
		_column = (_token != undefined) ? struct_get(_token, "column") : undefined;
		if (_column == undefined) _column = struct_get(self, "column") ?? 0;
	}
	if (_script == undefined) {
		_script = (_env != undefined) ? (struct_get(_env, "current_script_name") ?? "") : "";
	}
	
	// GameMaker's fields; the stack trace holds the compiled frames when debug executors run, else this line
	var _stack = __GMLCdebugStacktrace();
	if (array_length(_stack) == 0) _stack = [string(_script) + " (line " + string(_line) + ")"];
	var _message = string(_err);
	var _error = {
		message:     _message,
		longMessage: $"{_message}\n at {_script} (line {_line}) - {_lineString}",
		script:      _script,
		line:        _line,
		column:      _column,
		lineString:  _lineString,
		stacktrace:  _stack,
	};
	throw _error;
}
#endregion

#region Runtime
#region jsDoc
/// @func    __gmlc_internal_functions()
/// @desc    GMLC's own run-time helpers that the pipeline writes calls to, by name.
/// @returns {Struct}
#endregion
function __gmlc_internal_functions() {
	static __functions = {};
	return __functions;
}

// please dont use this in a final project.
#region jsDoc
/// @func    execute_string(_string)
/// @desc    Compiles GML text with every function exposed and runs it.
/// @param   {String} _string : The GML
/// @returns {Any} What the program returns
#endregion
function execute_string(_string) {
	static gmlc = new GMLC_Env().set_exposure(GMLC_EXPOSURE.NATIVE);
	var _program = gmlc.compile(_string);
	var _r = executeProgram(_program);
	return _r;
}
#endregion

#region Files and JSON
#region jsDoc
/// @func    __gmlc_find_files(_directory, _extension, [_recursive])
/// @desc    The paths of the files with an extension in a directory, and with _recursive in its folders too, sorted;
///          `/` separates the folders.
/// @param   {String} _directory   : The directory
/// @param   {String} _extension   : The extension, without the dot
/// @param   {Bool}   [_recursive] : Whether the folders inside are searched too
/// @returns {Array<String>}
#endregion
function __gmlc_find_files(_directory, _extension, _recursive = false) {
	var _dir = string_replace_all(_directory, "\\", "/");
	if (_dir != "") && (string_char_at(_dir, string_length(_dir)) != "/") _dir += "/";
	var _out = [];
	var _name = file_find_first(_dir + "*." + _extension, fa_none);
	while (_name != "") {
		array_push(_out, _dir + _name);
		_name = file_find_next();
	}
	file_find_close();
	if (_recursive) {
		// the folders first: a search cannot run inside another
		var _folders = [];
		_name = file_find_first(_dir + "*", fa_directory);
		while (_name != "") {
			if (_name != ".") && (_name != "..") && directory_exists(_dir + _name) array_push(_folders, _dir + _name);
			_name = file_find_next();
		}
		file_find_close();
		var _f = 0; repeat (array_length(_folders)) {
			var _inner = __gmlc_find_files(_folders[_f], _extension, true);
			array_copy(_out, array_length(_out), _inner, 0, array_length(_inner));
		_f++}
	}
	array_sort(_out, true);
	return _out;
}

#region jsDoc
/// @func    __gmlc_json_parse_loose(_text)
/// @desc    Parses JSON as GameMaker writes its project files (`.yy`, `.yyp`): like json_parse, but a comma right
///          before a closing `}` or `]` is allowed.
/// @param   {String} _text : The JSON text
/// @returns {Any}
#endregion
function __gmlc_json_parse_loose(_text) {
	var _size = string_byte_length(_text);
	var _in = buffer_create(_size + 1, buffer_fixed, 1);
	buffer_write(_in, buffer_string, _text);
	var _out = buffer_create(_size + 1, buffer_fixed, 1);
	var _inString = false;
	var _escaped = false;
	var _comma = false; // a comma read but not written yet: dropped when a closing bracket comes next
	var _i = 0; repeat (_size) {
		var _byte = buffer_peek(_in, _i, buffer_u8);
		if (_inString) {
			buffer_write(_out, buffer_u8, _byte);
			if (_escaped) _escaped = false;
			else if (_byte == 92) _escaped = true;       // backslash
			else if (_byte == 34) _inString = false;     // quote
		}
		else if (_byte == 44) {                          // comma
			if (_comma) buffer_write(_out, buffer_u8, 44);
			_comma = true;
		}
		else if (_byte == 32) || (_byte == 9) || (_byte == 10) || (_byte == 13) {
			buffer_write(_out, buffer_u8, _byte);
		}
		else {
			if (_comma) && (_byte != 125) && (_byte != 93) buffer_write(_out, buffer_u8, 44);
			_comma = false;
			buffer_write(_out, buffer_u8, _byte);
			if (_byte == 34) _inString = true;
		}
	_i++}
	if (_comma) buffer_write(_out, buffer_u8, 44);
	buffer_write(_out, buffer_u8, 0);
	buffer_seek(_out, buffer_seek_start, 0);
	var _clean = buffer_read(_out, buffer_string);
	buffer_delete(_in);
	buffer_delete(_out);
	return json_parse(_clean);
}
#endregion

#region File management
#region jsDoc
/// @function __gmlc_file_read_text(filename)
/// @description Reads entire content of a given file as a string, or returns undefined if the file doesn't exist.
/// @param {string} filename        The path of the file to read the content of.
#endregion
function __gmlc_file_read_text(_filename) {
	if (!file_exists(_filename)) return undefined;
	
	var _buffer = buffer_load(_filename);
	var _text = undefined;
	if (buffer_get_size(_buffer) > 0) {
		_text = buffer_read(_buffer, buffer_string);
	}
	buffer_delete(_buffer);
	return _text;
}

#region jsDoc
/// @function __gmlc_file_write_text(filename,content)
/// @description Creates or overwrites a given file with the given string content.
/// @param {string} filename        The path of the file to create/overwrite.
/// @param {string} content            The content to create/overwrite the file with.
#endregion
function __gmlc_file_write_text(_filename, _content) {
	// the text only: buffer_string would also write its terminating zero byte into the file
	var _size = string_byte_length(_content);
	var _buffer = buffer_create(_size + 1, buffer_fixed, 1);
	buffer_write(_buffer, buffer_text, _content);
	buffer_save_ext(_buffer, _filename, 0, _size);
	buffer_delete(_buffer);
}

#region jsDoc
/// @function __gmlc_json_save(filename,value)
/// @description Saves a given GML value (struct/array/string/real) into a JSON file.
/// @param {string} filename        The path of the JSON file to save.
/// @param {any} value                The value to save as a JSON file.
#endregion
function __gmlc_json_save(_filename, _value) {
	__gmlc_file_write_text(_filename, json_stringify(_value, true));
}

#region jsDoc
/// @function __gmlc_json_load(filename)
/// @description Loads a given JSON file into a GML value (struct/array/string/real).
/// @param {string} filename        The path of the JSON file to load.
#endregion
function __gmlc_json_load(_filename) {
	var _text = __gmlc_file_read_text(_filename);
	if (_text == undefined) return undefined;
	try {
		return json_parse(_text);
	}
	catch (_error) {
		// if the file content isn't a valid JSON, prevent crash and return undefined instead
		return undefined;
	}
}
#endregion
