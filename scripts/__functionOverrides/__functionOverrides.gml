// this script contains a bunch of functions which imitate native functions,
// but to allow for us to work better with gmlc

/// @ignore
function __method(_struct, _func) {
	
	static __executeMethod = function() {
		var argArr = array_create(argument_count, undefined);
		var _i=argument_count-1; repeat(argument_count) {
			argArr[_i] = argument[_i];
		_i--}
		
		if (target != undefined) {
			var _prevOther = global.otherInstance;
			var _prevSelf  = global.selfInstance;
			global.otherInstance = global.selfInstance;
			global.selfInstance = target;
		
			var _return = method_call(func, argArr);
			
			global.otherInstance = _prevOther;
			global.selfInstance  = _prevSelf;
		}
		else {
			var _return = method_call(func, argArr);
		}
		
		return _return;
	}
	
	if (is_gmlc_program(_func)) {
		if (is_gmlc_method(_func)) {
			//a gmlc method
			return method({
				"__@@is_gmlc_method@@__": true,
				target: _struct,
				func: method_get_self(_func).func,
			}, __executeMethod)
		}
		else {
			//a gmlc function
			return method({
				"__@@is_gmlc_method@@__": true,
				target: _struct,
				func: _func,
			}, __executeMethod)
		}
	}
	else {
		//a native gml function/method
		return method(_struct, _func);
	}
}

function __new(_func, argArr=[]) {
	if (is_method(_func))
	&& (is_gmlc_program(_func)) {
		if (is_gmlc_method(_func)) {
			//a gmlc method
			throw_gmlc_error("target function for 'new' must be a constructor, this one is a gmlc method")
		}
		else {
			//init our arguments
			
			//run the parent
			var _constructor = method_get_self(_func);
			if (_constructor.parentCall != undefined) {
				var _struct = __new(parentCall.callee(), _args)
			}
			else {
				var _struct = {};
			}
			
			//run our body
			_constructor.statements();
		}
	}
	else {
		//a native gml constructor
		with (global.otherInstance) with (global.selfInstance) {
			return constructor_call_ext(_func, _argArr);
		}
	}	
}

function __instanceof(_struct) {
	if (is_gmlc_constructed(_struct)) {
		return _struct.__[$ "__@@gmlc_constructor_name@@__"]
	}
	
	if (is_method(_struct)) {
		if (is_gmlc_method(_struct)) {
			return "function"
		}
		
		if (is_gmlc_program(_struct)) {
			return undefined
		}
	}
	
	// any number of other things
	return instanceof(_struct);
	
}

function __is_instanceof(_struct, _constructor) {
	if (is_gmlc_constructed(_struct)) {
		static __base_struct_statics = static_get({});
		var _static = static_get(_struct);
		var _constructor_static = static_get(_constructor);
		while(_static != __base_struct_statics) {
			if (_static == _constructor_static) {
				return true;
			}
			_static = static_get(_static);
		}
		return false
	}
	
	// any number of other things
	return is_instanceof(_struct, _constructor);
	
}

function __struct_get_with_error(struct, name) {
	if (struct_exists(struct, name)) return struct_get(struct, name);
	
	throw_gmlc_error($"\nVariable <unknown_object>.{name} not set before reading it.")
	//throw_gmlc_error($"\nVariable <unknown_object>.{name} not set before reading it.\n at gmlc_{objectType}_{objectName}_{eventType}_{eventNumber} (line {lineNumber}) - {lineString}")
}

function __script_execute_ext(ind, array) {
	//execute GMLC Script
	if (is_instanceof(ind, __GMLC_Script))   return ind.execute(array);
	
	//execute GMLC Function
	if (is_instanceof(ind, __GMLC_Function)) return ind.execute(array);
	
	//execute GML Script/Function
	return script_execute_ext(ind, array)
}

function __NewGMLArray() {
	var _arr = [];
	var _i=argument_count-1; repeat(argument_count) {
		_arr[_i] = argument[_i];
	_i--;}//end repeat loop
	return _arr;
}

function __NewGMLStruct() {
	var _struct = {};
	var _i=0; repeat(argument_count/2) {
		_struct[$ argument[_i]] = argument[_i+1];
	_i+=2;}//end repeat loop
	
	return _struct;
}

function __array_update(arr, index, increment, prefix) {
	if (increment)  && (prefix)  return ++arr[index];
	if (increment)  && (!prefix) return   arr[index]++;
	if (!increment) && (prefix)  return --arr[index];
	if (!increment) && (!prefix) return   arr[index]--;
}
function __list_update(list, index, increment, prefix) {
	if (increment)  && (prefix)  return ++list[| index];
	if (increment)  && (!prefix) return   list[| index]++;
	if (!increment) && (prefix)  return --list[| index];
	if (!increment) && (!prefix) return   list[| index]--;
}
function __map_update(map, key, increment, prefix) {
	if (increment)  && (prefix)  return ++map[? key];
	if (increment)  && (!prefix) return   map[? key]++;
	if (!increment) && (prefix)  return --map[? key];
	if (!increment) && (!prefix) return   map[? key]--;
}
function __grid_update(grid, _x, _y, increment, prefix) {
	if (increment)  && (prefix)  return ++grid[# _x, _y];
	if (increment)  && (!prefix) return   grid[# _x, _y]++;
	if (!increment) && (prefix)  return --grid[# _x, _y];
	if (!increment) && (!prefix) return   grid[# _x, _y]--;
}
function __struct_update(struct, name, increment, prefix) {
	if (increment)  && (prefix)  return ++struct[$ name];
	if (increment)  && (!prefix) return   struct[$ name]++;
	if (!increment) && (prefix)  return --struct[$ name];
	if (!increment) && (!prefix) return   struct[$ name]--;
}
function __struct_with_error_update(struct, name, increment, prefix) {
	if (!struct_exists(struct, name)) throw_gmlc_error($"\nVariable <unknown_object>.{name} not set before reading it.")
	
	if (increment)  && (prefix)  return ++struct[$ name];
	if (increment)  && (!prefix) return   struct[$ name]++;
	if (!increment) && (prefix)  return --struct[$ name];
	if (!increment) && (!prefix) return   struct[$ name]--;
}
