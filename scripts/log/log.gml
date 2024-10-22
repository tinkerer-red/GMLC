function log(_str) {
	var _new_str = "";
	var _i=0; repeat(argument_count) {
		_new_str += string(argument[_i])+" ";
	_i++}
	show_debug_message(_new_str);
}

function json(_input) {
	return json_stringify(_input, true)
}

function pprint(_thing) {
	var _str = "";
	var _i=0; repeat(argument_count) {
		_str += json_stringify(__reStruct(argument[_i]), true)
	_i++}
	show_debug_message(_str)
}
/// @ignore
function __reStruct(_struct) {
	static __recursion_memory = []
	static __depth = 0;
	if (__depth == 0) { array_resize(__recursion_memory, 0) };
	__depth++
	
	if (is_method(_struct)) {
		var _self = method_get_self(_struct);
		var _outputStruct = __reStruct(_self)
		__depth--
		return _outputStruct
	}
	
	if (is_array(_struct)) {
		var _inputArray = []
		var _i=0; repeat(array_length(_struct)) {
			var _expr = _struct[_i];
			_inputArray[_i] = __reStruct(_expr)
		_i++}
		__depth--
		return _inputArray
	}
	
	if (is_struct(_struct)) {
		if (array_get_index(__recursion_memory, _struct) == -1) {
			array_push(__recursion_memory, _struct);
		}
		else {
			__depth--
			return "<Recursive Reference>";
		}
		
		var _outputStruct = {}
		var _names = struct_get_names(_struct)
		var _length = array_length(_names)
		if (_length < 300) {
			var _i=0; repeat(_length) {
				var _name = _names[_i];
			
			
				//skip these from printing
				if (_name == "errorMessage")
				|| (_name == "rootNode")
				|| (_name == "parentNode") {
					_i++
					continue;
				}
			
				var _new_name = _name;
				if (string_starts_with(_name, "@@")) {
					_new_name = string_replace(_name, "@@", "_@@")
				}
			
				_outputStruct[$ _new_name] = __reStruct(_struct[$ _name])
			_i++}
		}
		else {
			_outputStruct = "<Struct Is too Large to Print>"
		}
		__depth--
		return _outputStruct
	}
	
	if (is_handle(_struct))
	&& (script_exists(_struct))
	{
		__depth--
		return script_get_name(_struct)
	}
	
	__depth--
	return _struct;
}

#region jsDoc
/// @func    trace()
/// @desc    This function will create a custom debug message  that is shown in the compiler window at runtime.
///
///          .
///
///          output: `<file>/<function>:<line>: <string>`
/// @param   {string} str : The string you wish to log
/// @returns {undefined}
#endregion
#macro trace  __trace(_GMFILE_, _GMFUNCTION_, _GMLINE_)
function __trace(_file, _func, _line) {
		static __struct = {};
		
		__struct.__location = $"{_file}/{_func}:{_line}";
		return method(__struct, function(_str)
    {
        show_debug_message(__location + ": " + string(_str));
    });
}