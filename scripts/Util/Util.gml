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

/// @description Creates a new constructor instance from the specified constructor and array of arguments.
/// @param {Function} Constructor Description
/// @param {Array<Any>} [args] Description
/// @param {Real} [offset] Description
/// @param {Real} [length] Description
/// @pure
/// @return {Struct}
/// feather ignore all
function constructor_call_ext(_constructor, _args = undefined, _offset = 0, _length = undefined) {
	_length ??= is_array(_args) ? array_length(_args) : 0;
	_args ??= [];
	
	// Short circuting, since the arguments array is optional! Not for GMLC constructors: they read their program
	// data through `other`, which only the with() path below sets (`new` on a method-bound GMLC constructor with no
	// arguments ran with an undefined self)
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

function is_gmlc_function(_program) {
	if (is_method(_program)) {
		var _func = method_get_index(_program)
		if (_func == __GMLCexecuteFunction)
		|| (_func == static_get(__gmlc_method)[$ "__executeMethodFunction"]) {
			return true;
		}
	}
	return false;
}

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

function is_script(_value) {
	if !is_handle(_value) return false;
	return script_exists(_value);
}

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
/// @func    __gmlc_enum_value(_value)
/// @desc    The value of an enum member whose value is an expression: the int64 of a number or bool (truncated, as
///          GameMaker does); anything else is an error, as GameMaker refuses it.
/// @param   {Any} _value : The value of the member's expression
/// @returns {Int64}
#endregion
function __gmlc_enum_value(_value) {
	if (is_real(_value) || is_int64(_value) || is_bool(_value)) return int64(_value);
	throw_gmlc_error("enum assignment must be an integer constant");
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
/// @desc    The value of a name in a table keyed by names from source code, undefined when the table does not hold it
///          (see __gmlc_struct_has).
/// @param   {Struct} _struct : The table
/// @param   {String} _key    : The name
/// @returns {Any}
#endregion
function __gmlc_struct_get(_struct, _key) {
	return __gmlc_struct_has(_struct, _key) ? _struct[$ _key] : undefined;
}
#region jsDoc
/// @func    __GMLC_InternalFunctions()
/// @desc    GMLC's own run-time helpers that the pipeline writes calls to, by name.
/// @returns {Struct}
#endregion
function __GMLC_InternalFunctions() {
	static __functions = {
		__gmlc_enum_value: __gmlc_enum_value,
	};
	return __functions;
}

#region jsDoc
/// @func    __gmlc_node_position(_node)
/// @desc    Where a compiled node is in its source: file name, line, column and line text, from its span and the
///          program's source table; undefined when the node has none.
/// @param   {Struct} _node : A compiled node (anything with `span` and `rootNode`)
/// @returns {Struct|Undefined}
#endregion
function __gmlc_node_position(_node) {
	var _span = is_struct(_node) ? _node[$ "span"] : undefined;
	var _root = is_struct(_node) ? _node[$ "rootNode"] : undefined;
	var _sources = is_struct(_root) ? _root[$ "sources"] : undefined;
	if (_span == undefined) || (_sources == undefined) return undefined;
	return _sources.position(_span);
}

function throw_gmlc_error(_err, _line=undefined, _lineString=undefined, _column=undefined, _script=undefined) {
	var _token = struct_get(self, "currentToken");
	var _env   = struct_get(self, "env");
	
	// a compiled node knows where it is by its span
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
		_script = (_env != undefined) ? (struct_get(_env, "currentScriptName") ?? "") : "";
	}

	var _error = {
		message:    string(_err),
		script:     _script,
		line:       _line,
		column:     _column,
		lineString: _lineString,
		stacktrace: debug_get_callstack(),
	};
	throw _error;
}

function script_get_index(_script_name) {
	static __built_in_lookup = undefined;
	
	//entirely because asset_get_index returns -1 for builtin functions
	if (__built_in_lookup = undefined) {
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

// please dont use this in a final project.
function execute_string(_string) {
	static gmlc = new GMLC_Env().set_exposure(GMLC_EXPOSURE.NATIVE);
	var _program = gmlc.compile(_string);
	var _r = executeProgram(_program);
	return _r;
}
