// unit testing
function __compare_results(desc, result, expected) {
	if (is_array(expected)) && (!__array_equals(result, expected)) {
		show_debug_message($"!!!   Array Value Mismatch   !!!")
		show_debug_message($"expected != result")
		show_debug_message($"{expected} != {result}")
		show_debug_message("Got :: " + json_stringify(result, true));
		return false;
	}
	else if (is_struct(expected)) && (!__struct_equals(result, expected)) {
		show_debug_message($"!!!   Struct Value Mismatch   !!!")
		show_debug_message($"expected != result")
		show_debug_message("Expected :: " + json_stringify(expected, true));
		show_debug_message("Got :: " + json_stringify(result, true));
		return false;
	}
	else if (!is_array(expected) && !is_struct(expected)) && (expected != result) {
		//show_debug_message("Test Failed: " + description);
		show_debug_message($"!!!   Literal Value Mismatch   !!!")
		show_debug_message($"expected != result")
		show_debug_message($"{expected} != {result}")
		show_debug_message("Got :: " + json_stringify(result, true));
		return false;
	}
	else if (typeof(expected) != typeof(result)) {
		//show_debug_message("Test Failed: " + description);
		show_debug_message($"!!!   Type Mismatch   !!!")
		show_debug_message($"expected != result")
		show_debug_message($"{typeof(expected)} != {typeof(result)}")
		show_debug_message("Got :: " + json_stringify(result, true));
		return false;
	}
	else {
        show_debug_message("		Test Passed: " + desc);
        //show_debug_message($"Return :: {result}");
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
			show_debug_message($"{string_repeat("\t", _depth)}Recieved struct is missing the expected key {_name}")
		}
		
		if (typeof(_expected_value) != typeof(_recieved[$ _name])) {
			show_debug_message($"{string_repeat("\t", _depth)}Recieved structs key ({_name}) is mismatched typeof() with the expected {_name}")
			show_debug_message($"{string_repeat("\t", _depth)}Recieved {typeof(_recieved[$ _name])}\nExpected {typeof(_expected_value)}")
			show_debug_message($"{string_repeat("\t", _depth)}Recieved {_recieved[$ _name]}\nExpected {_expected_value}")
		}
		
		switch (typeof(_expected_value)) {
			case "struct":{
				if !__struct_equals(_recieved[$ _name], _expected_value, _depth+1) {
					show_debug_message($"{string_repeat("\t", _depth)}Recieved structs child struct is mismatched with the expected key {_name}")
					return false;
				}
			break;}
			case "array":{
				if !__array_equals(_recieved[$ _name], _expected_value, _depth+1) {
					show_debug_message($"{string_repeat("\t", _depth)}Recieved structs child array is mismatched with the expected key {_name}")
					return false;
				}
			break;}
			default:
				if (_recieved[$ _name] != _expected_value) {
					show_debug_message($"{string_repeat("\t", _depth)}Recieved structs key is mismatched with the expected key {_name}")
					show_debug_message($"{string_repeat("\t", _depth)}Recieved ({_recieved[$ _name]})\nExpected {_expected_value}")
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
		show_debug_message("Array lengths dont match")
		show_debug_message($"Recieved: {array_length(_recieved)}\nExpected: {array_length(_expected)}")
		return false;
	}
	
	var _i=0; repeat(array_length(_expected)){
		var _expected_value = _expected[_i];
		
		if (typeof(_expected_value) != typeof(_recieved[_i])) {
			show_debug_message($"{string_repeat("\t", _depth)}Recieved arrays index ({_i}) is mismatched with the expected index {_i}")
			show_debug_message($"{string_repeat("\t", _depth)}Recieved ({_recieved[_i]})\nExpected {_expected_value}")
		}
		
		switch (typeof(_expected_value)) {
			case "struct":{
				if !__struct_equals(_recieved[_i], _expected_value, _depth+1) {
					show_debug_message($"{string_repeat("\t", _depth)}Recieved arrays child struct is mismatched with the expected indexs struct {_i}")
					return false;
				}
			break;}
			case "array":{
				if !__array_equals(_recieved[_i], _expected_value, _depth+1) {
					show_debug_message($"{string_repeat("\t", _depth)}Recieved arrays child array is mismatched with the expected indexs value {_i}")
					return false;
				}
			break;}
			default:
				if (_recieved[_i] != _expected_value) {
					show_debug_message($"{string_repeat("\t", _depth)}Recieved arrays index ({_i}) is mismatched with the expected index {_i}")
					show_debug_message($"{string_repeat("\t", _depth)}Recieved ({_recieved[_i]})\nExpected {_expected_value}")
					return false;
				}
			break;
		}
	_i+=1}
	
	return true;
}

