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

// unit testing
function __compare_results(desc, result, expected) {
	if (is_array(expected)) && (!__array_equals(result, expected)) {
		log($"!!!   Array Value Mismatch   !!!")
		log($"expected != result")
		log($"{expected} != {result}")
		log("Got :: " + json_stringify(result, true));
		return false;
	}
	else if (is_struct(expected)) && (!__struct_equals(result, expected)) {
		log($"!!!   Struct Value Mismatch   !!!")
		log($"expected != result")
		log("Expected :: " + json_stringify(expected, true));
		log("Got :: " + json_stringify(result, true));
		return false;
	}
	else if (!is_array(expected) && !is_struct(expected)) && (expected != result) {
		//log("Test Failed: " + description);
		log($"!!!   Literal Value Mismatch   !!!")
		log($"expected != result")
		log($"{expected} != {result}")
		log("Got :: " + json_stringify(result, true));
		return false;
	}
	else if (typeof(expected) != typeof(result)) {
		//log("Test Failed: " + description);
		log($"!!!   Type Mismatch   !!!")
		log($"expected != result")
		log($"{typeof(expected)} != {typeof(result)}")
		log("Got :: " + json_stringify(result, true));
		return false;
	}
	else {
        log("		Test Passed: " + desc);
        //log($"Return :: {result}");
		return true;
    }
}
function __string_token_arr(_arr) {
	var _str = "[\n";
	var _i=0; repeat(array_length(_arr)) {
		var _sub_str = string_replace_all(string(_arr[_i]), "\n", "\\n");
		_str = string_concat(_str, _sub_str, ",\n");
	_i+=1}
	
	_str += "]";
	
	return _str;
}
function __struct_equals(_recieved, _expected, _depth=1) {
	if (_recieved == undefined) return false;
	
	var _names = struct_get_names(_expected);
	var _i=0; repeat(array_length(_names)){
		var _name = _names[_i];
		var _expected_value = _expected[$ _name];
		
		if !struct_exists(_recieved, _name) {
			log($"{string_repeat("\t", _depth)}Recieved struct is missing the expected key {_name}")
		}
		
		if (typeof(_expected_value) != typeof(_recieved[$ _name])) {
			log($"{string_repeat("\t", _depth)}Recieved structs key ({_name}) is mismatched typeof() with the expected {_name}")
			log($"{string_repeat("\t", _depth)}Recieved {typeof(_recieved[$ _name])}\nExpected {typeof(_expected_value)}")
			log($"{string_repeat("\t", _depth)}Recieved {_recieved[$ _name]}\nExpected {_expected_value}")
		}
		
		switch (typeof(_expected_value)) {
			case "struct":{
				if !__struct_equals(_recieved[$ _name], _expected_value, _depth+1) {
					log($"{string_repeat("\t", _depth)}Recieved structs child struct is mismatched with the expected key {_name}")
					return false;
				}
			break;}
			case "array":{
				if !__array_equals(_recieved[$ _name], _expected_value, _depth+1) {
					log($"{string_repeat("\t", _depth)}Recieved structs child array is mismatched with the expected key {_name}")
					return false;
				}
			break;}
			default:
				if (_recieved[$ _name] != _expected_value) {
					log($"{string_repeat("\t", _depth)}Recieved structs key is mismatched with the expected key {_name}")
					log($"{string_repeat("\t", _depth)}Recieved ({_recieved[$ _name]})\nExpected {_expected_value}")
					return false;
				}
			break;
		}
	_i+=1}
	
	return true;
}
function __array_equals(_recieved, _expected, _depth=1) {
	if (_recieved == undefined) return false;
	
	if (array_length(_recieved) != array_length(_expected)) {
		log("Array lengths dont match")
		log($"Recieved: {array_length(_recieved)}\nExpected: {array_length(_expected)}")
		return false;
	}
	
	var _i=0; repeat(array_length(_expected)){
		var _expected_value = _expected[_i];
		
		if (typeof(_expected_value) != typeof(_recieved[_i])) {
			log($"{string_repeat("\t", _depth)}Recieved arrays index ({_i}) is mismatched with the expected index {_i}")
			log($"{string_repeat("\t", _depth)}Recieved ({_recieved[_i]})\nExpected {_expected_value}")
		}
		
		switch (typeof(_expected_value)) {
			case "struct":{
				if !__struct_equals(_recieved[_i], _expected_value, _depth+1) {
					log($"{string_repeat("\t", _depth)}Recieved arrays child struct is mismatched with the expected indexs struct {_i}")
					return false;
				}
			break;}
			case "array":{
				if !__array_equals(_recieved[_i], _expected_value, _depth+1) {
					log($"{string_repeat("\t", _depth)}Recieved arrays child array is mismatched with the expected indexs value {_i}")
					return false;
				}
			break;}
			default:
				if (_recieved[_i] != _expected_value) {
					log($"{string_repeat("\t", _depth)}Recieved arrays index ({_i}) is mismatched with the expected index {_i}")
					log($"{string_repeat("\t", _depth)}Recieved ({_recieved[_i]})\nExpected {_expected_value}")
					return false;
				}
			break;
		}
	_i+=1}
	
	return true;
}
