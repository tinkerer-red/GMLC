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
	
	// Short circuting, since the arguments array is optional!
	if (_length == 0) {
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

function is_constructor(_func){
	if (is_method(_func)) {
		return asset_has_tags(method_get_index(_func), "@@constructor");
	}
	else {
		return asset_has_tags(_func, "@@constructor");
	}
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

function throw_gmlc_error(_err) {
	log(_err)
	throw @'
===GMLC===
'+string(_err)+"\n=========\n\n";

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
