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

function __static_get(_struct) {
	var _json = __printMethodStructure(_struct);
	
	if (is_gmlc_constructed(_struct)) {
		return static_get(_struct)
	}
	
	if (is_method(_struct)) {
		if (is_gmlc_method(_struct)) {
			var _r = static_get(method_get_self(_struct).func)
			return _r
		}
		
		if (is_gmlc_program(_struct)) {
			var _r = static_get(method_get_self(_struct))
			return _r
		}
	}
	
	// any number of other things
	return static_get(_struct);
	
}

function __static_set(_targetStruct, _staticStruct) {
	if (is_gmlc_program(_targetStruct)) {
		_targetStruct.statics = _staticStruct;
		return static_set(method_get_self(_targetStruct), _staticStruct);
	}
	
	// any number of other things
	return static_set(_targetStruct, _staticStruct);
	
}

function __method_get_index(_method) {
	if (is_method(_method)) {
		if (is_gmlc_method(_method)) {
			return method_get_self(_method).func;
		}
		
		if (is_gmlc_program(_method)) {
			return undefined;
		}
	}
	
	// any number of other things
	return method_get_index(_method);
	
}

function __method_get_self(_method) {
	if (is_method(_method)) {
		if (is_gmlc_method(_method)) {
			return method_get_self(_method).target;
		}
		
		if (is_gmlc_program(_method)) {
			return undefined;
		}
	}
	
	// any number of other things
	return method_get_self(_method);
	
}

function __typeof(_val) {
	if (is_method(_val)) {
		if (is_gmlc_method(_val)) {
			return "method"
		}
		if (is_gmlc_program(_val)) {
			return "ref"
		}
	}
	
	// any number of other things
	return typeof(_val);
}

function __script_execute(ind) {
	static __argArr = [];
	array_resize(__argArr, 0);
	
	if (argument_count > 1) {
		var _i=1; repeat(argument_count-1) {
			__argArr[_i] = argument[_i];
		_i++}
		
		return __script_execute_ext(argument0, __argArr)
	}
	
	return __script_execute_ext(argument0)
	
}

function __script_execute_ext(ind, array=undefined, offset=0, num_args=array_length(array)-offset) {
	static __argArr = [];
	array_resize(__argArr, 0)
	
	/// code coppied from html5 source, modified for speed improvements
	if (array != undefined) {
		var _length = array_length(array)
		if (_length) {
			var dir = 1;
			if (offset < 0) offset = _length + offset;
			if (offset >= _length) offset = _length;
			if (num_args < 0) {
				dir = -1;
				if ((offset + num_args) < 0) {
					num_args = offset+1;
				} // end if
				else {
					num_args = -num_args;
				} // end else
			} // end if
			else {
				if ((offset + num_args) > _length) {
					num_args = _length - offset;
				} // end if
			} // end else
	
	
			var n = offset, i=num_args-offset;
			repeat (num_args) {
				__argArr[i] = array[n];
			++i; n+=dir}
		}
	}
	///////////////////////////////////////////
	
	if (is_method(ind)) {
		if (is_gmlc_method(ind)) {
			var _self = method_get_self(ind);
			var _func = _self.func;
			return method_call(_func, __argArr);
		}
		if (is_gmlc_program(ind)) {
			return method_call(ind, __argArr);
		}
	}
	
	return script_execute_ext(ind, __argArr);
}

function __struct_get_with_error(struct, name) {
	if (struct_exists(struct, name)) return struct_get(struct, name);
	
	throw_gmlc_error($"Variable <unknown_object>.{name} not set before reading it.")
	//throw_gmlc_error($"Variable <unknown_object>.{name} not set before reading it.\n at gmlc_{objectType}_{objectName}_{eventType}_{eventNumber} (line {lineNumber}) - {lineString}")
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
	if (!struct_exists(struct, name)) throw_gmlc_error($"Variable <unknown_object>.{name} not set before reading it.")
	
	if (increment)  && (prefix)  return ++struct[$ name];
	if (increment)  && (!prefix) return   struct[$ name]++;
	if (!increment) && (prefix)  return --struct[$ name];
	if (!increment) && (!prefix) return   struct[$ name]--;
}
