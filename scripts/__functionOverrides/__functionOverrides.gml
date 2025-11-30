// this script contains a bunch of functions which imitate native functions,
// but to allow for us to work better with gmlc
#region method()
#macro __vanilla_method method
#macro method __gmlc_method
function __gmlc_method(_struct, _func) {
	//these two are the same exact thing, one is just a constructor
	static __executeMethodFunction = function() {
		// -- This is the only difference between the two functions
		__GMLC_DEFAULT_SELF_AND_OTHER
		var _target = target;
		var _func = func;
		
		var _prevOther = global.gmlc_other_instance;
		var _prevSelf  = global.gmlc_self_instance;
		
		//dont update scope if we are already on the correct scope,
		// and dont update scope if it's an unbound method
		if (_target != undefined) {
			global.gmlc_other_instance = _prevSelf;
			global.gmlc_self_instance = _target;
		}
		//////////////////////////////////////////////////////////
		
		static argArr = array_create(argument_count, undefined);
		var _argArr = argArr;
		array_resize(_argArr, argument_count)
		var _i=argument_count-1; repeat(argument_count) {
			_argArr[_i] = argument[_i];
		_i--}
		
		
		if (_target != undefined) {
			
			var _return = method_call(_func, _argArr);
			
			global.gmlc_other_instance = _prevOther;
			global.gmlc_self_instance  = _prevSelf;
		}
		else {
			var _return = method_call(_func, _argArr);
		}
		
		array_resize(_argArr, 0)
		return _return;
	}
	static __executeMethodConstructor = function() constructor {
		// -- This is the only difference between the two functions
		//check to see if this is a `new` expression, or some `script_execute` equivalent using `method_call`
		var _self_is_gmlc  = self[$ "__@@is_gmlc_function@@__"];
		var _is_new_expression = !_self_is_gmlc;
		if (_is_new_expression) {
			with other {
				__GMLC_DEFAULT_SELF_AND_OTHER
				var _target = target;
				var _func = func;
			}
			
			var _prevOther = global.gmlc_other_instance;
			var _prevSelf  = global.gmlc_self_instance;
			global.gmlc_other_instance = _target;
			global.gmlc_self_instance = self;
		}
		else {
			__GMLC_DEFAULT_SELF_AND_OTHER
			var _target = target;
			var _func = func;
			
			var _prevOther = global.gmlc_other_instance;
			var _prevSelf  = global.gmlc_self_instance;
		}
		//////////////////////////////////////////////////////////
		
		static argArr = array_create(argument_count, undefined);
		var _argArr = argArr;
		array_resize(_argArr, argument_count)
		var _i=argument_count-1; repeat(argument_count) {
			_argArr[_i] = argument[_i];
		_i--}
		
		
		if (_target != undefined) {
			//this is just method_call, but it works on constructors
			var _program_data = method_get_self(_func);
			var _program_func = method_get_index(_func);
			with (_program_data) {
				var _return = script_execute_ext(_func, _argArr)
			}
			
			global.gmlc_other_instance = _prevOther;
			global.gmlc_self_instance  = _prevSelf;
		}
		else {
			//this is just method_call, but it works on constructors
			var _program_data = method_get_self(_func);
			var _program_func = method_get_index(_func);
			with (_program_data) {
				var _return = script_execute_ext(_func, _argArr)
			}
		}
		
		array_resize(_argArr, 0)
		return _return;
	}
	
	
	
	if (is_gmlc_program(_func)) {
		//a gmlc function
		var _exe = (is_constructor(_func)) ? __executeMethodConstructor : __executeMethodFunction;
		
		return __vanilla_method({
			"__@@is_gmlc_method@@__": true,
			target: _struct,
			func: _func,
		}, _exe)
	}
	else if (is_gmlc_method(_func)) {
		//a gmlc method
		var _exe = (is_constructor(_func)) ? __executeMethodConstructor : __executeMethodFunction;
		
		return __vanilla_method({
			"__@@is_gmlc_method@@__": true,
			target: _struct,
			func: method_get_self(_func).func,
		}, _exe)
	}
	else {
		//a native gml function/method
		return __vanilla_method(_struct, _func);
	}
}
#endregion

#region typeof()
#macro __vanilla_typeof typeof
#macro typeof __gmlc_typeof
function __gmlc_typeof(_val) {
	if (is_method(_val)) {
		if (is_gmlc_method(_val)) {
			return "method"
		}
		if (is_gmlc_program(_val)) {
			return "ref"
		}
	}
	
	// any number of other things
	return __vanilla_typeof(_val);
}
#endregion

#region instanceof()
#macro __vanilla_instanceof instanceof
#macro instanceof __gmlc_instanceof
function __gmlc_instanceof(_val) {
	if (is_method(_val)) {
		if (is_gmlc_program(_val))
		|| (is_gmlc_method(_val)) {
			return "function"
		}
	}
	else {
		if (is_gmlc_constructed(_val)) {
			return _val[$ "__@@gmlc_script_name@@__"];
		}
	}
	
	// any number of other things
	return __vanilla_instanceof(_val);
}
#endregion

#region is_instanceof()
#macro __vanilla_is_instanceof is_instanceof
//#macro is_instanceof __gmlc_is_instanceof
function __gmlc_is_instanceof(_struct, _constructor) {
	
	if (is_method(_constructor)) {
		var _should_parse = false;
		
		if (is_gmlc_method(_constructor)) {
			//var _target = method_get_self(_struct).target
			_constructor = method_get_self(_constructor).func;
		}
		
		if (is_gmlc_program(_constructor)) {
			var _program_data = method_get_self(_constructor);
			
			var _constructor_statics = _program_data.statics;
			var _struct_statics = static_get(_struct);
			if (_struct_statics == _constructor_statics) {
				return true;
			}
			else {
				var _should_parse = true;
			}
		}
		
		if (_should_parse) {
			while(_struct_statics != undefined) {
				if (_struct_statics == _constructor_statics) {
					return true;
				}
				_struct_statics = static_get(_struct_statics);
			}
			
			return false;
		}
	}
	// any number of other things
	return __vanilla_is_instanceof(_struct, _constructor);
}
#endregion

function __new(_func, argArr=[]) {
	return constructor_call_ext(_func, argArr);
}

function __gmlc_static_get(_struct) {
	
	if (is_method(_struct)) {
		if (is_gmlc_method(_struct)) {
			//var _target = method_get_self(_struct).target
			var _program = method_get_self(_struct).func;
			var _program_data = method_get_self(_program);
			var _statics = _program_data.statics;
			return _statics
		}
		
		if (is_gmlc_program(_struct)) {
			var _program_data = method_get_self(_struct);
			var _statics = _program_data.statics
			return _statics
		}
	}
	
	// any number of other things
	return static_get(_struct);
	
}

function __gmlc_static_set(_targetStruct, _staticStruct) {
	if (is_gmlc_program(_targetStruct)) {
		_targetStruct.statics = _staticStruct;
		return static_set(method_get_self(_targetStruct), _staticStruct);
	}
	
	// any number of other things
	return static_set(_targetStruct, _staticStruct);
	
}

function __gmlc_method_get_index(_method) {
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

function __gmlc_method_get_self(_method) {
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

function __gmlc_script_execute(ind) {
	static __argArr = [];
	array_resize(__argArr, 0);
	
	if (argument_count > 1) {
		var _i=1; repeat(argument_count-1) {
			__argArr[_i] = argument[_i];
		_i++}
		
		return __gmlc_script_execute_ext(argument0, __argArr)
	}
	
	return __gmlc_script_execute_ext(argument0)
	
}

function __gmlc_script_execute_ext(ind, array=undefined, offset=0, num_args=array_length(array)-offset) {
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
	
	
			var n = offset, i=0;
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
		else if (is_gmlc_program(ind)) {
			return method_call(ind, __argArr);
		}
	}
	
	return script_execute_ext(ind, __argArr);
}

function __gmlc_script_get_name(ind) {
	
	if (is_method(ind)) {
		if (is_gmlc_method(ind)) {
			//var _target = method_get_self(_struct).target
			ind = method_get_self(ind).func;
		}
		
		if (is_gmlc_program(ind)) {
			var _program_data = method_get_self(ind);
			var _statics = _program_data.statics
			var _name = _statics[$ "__@@gmlc_script_name@@__"]
			return _name;
		}
	}
	
	// any number of other things
	return script_get_name(ind);
	
}

////////////////////////////////////////////////
//These need to be methoded to the ENV
////////////////////////////////////////////////
function __gmlc_variable_global_exists(_name) {
	var _global = self.getConstant("global");
	return (is_struct(_global)) ? struct_exists(_global.value, _name) : throw_gmlc_error("`variable_global_exists()` can not opperate on `global`.");
}
function __gmlc_variable_global_get(_name) {
	var _global = self.getConstant("global");
	return (is_struct(_global)) ? struct_get(_global.value, _name) : throw_gmlc_error("`variable_global_get()` can not opperate on `global`.");
}
function __gmlc_variable_global_set(_name, _val) {
	var _global = self.getConstant("global");
	return (is_struct(_global)) ? struct_set(_global.value, _name, _val) : throw_gmlc_error("`variable_global_set()` can not opperate on `global`.");
}
////////////////////////////////////////////////
////////////////////////////////////////////////
////////////////////////////////////////////////

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
	
	//set the statics so they are unique
	static_set(_struct, {});
	
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
