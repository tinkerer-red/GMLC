function GmlSpec() {
	//This struct was created by taking `GmlSpec.xml` from the path `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-<Runtime>`
	//Then running it through the following webpage converting tool. `https://jsonformatter.org/xml-to-json`
	
	static __GmlSpec = undefined;
	
	if (__GmlSpec == undefined) {
		var _buf = buffer_load("GmlSpec.json");
		var _str = buffer_read(_buf, buffer_string);
		buffer_delete(_buf);
		
		__GmlSpec = json_parse(_str);
	}
	
	//*
	repeat (10) log("\n")
	var _arr = __GmlSpec.GameMakerLanguageSpec.Functions.Function;
	var _i=0; repeat(array_length(_arr)) {
		var _func = _arr[_i];
		
		if (_func.Pure) {
			//var _throw = "";
			//if (struct_exists(_func, "Parameter")) {
			//	var _second_line = !struct_exists(_func, "Parameter") ? "" : ((is_struct(_func.Parameter)) ? $"	if (array_length(_node.arguments) != 1) \{\n" : $"	if (array_length(_node.arguments) >= 1) \{\n	&& (array_length(_node.arguments) <= {array_length(_func.Parameter)}) \{\n")
			//	_throw += _second_line
			//	+ $"		throw_gmlc_error($\"Argument count for {_func.Name} is incorrect!\\nArgument Count : \{array_length(_node.arguments)\}\\nline (\{_node.line\}) \{_node.lineString\}\")\n"
			//	+ $"	\}\n"
			//}
			//
			//show_debug_message($"case {_func.Name}:\{\n"
			//+ _throw
			//+ $"	return __build_literal_from_function_call_constant_folding({_func.Name}, _node);\n"
			//+ $"break;}")
			
			
			show_debug_message(_func.Name+"()")
		}
		
	_i+=1;}//end repeat loop
	repeat (10) log("\n")
	//*/
	
	return __GmlSpec;
	
}
GmlSpec();


