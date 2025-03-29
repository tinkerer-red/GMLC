#region Tokenizer.gml

#region 1. Tokenizer Module
/*
Purpose: To split the source code into a stream of tokens that the parser can understand.
	
Methods:
	
initialize(): Set up initial configurations and variables, such as the position in the string and the source code.
nextToken(): Retrieve and return the next token from the source code, advancing the position.
peekToken(): Look at the next token without removing it from the stream or advancing the position.
tokenize(sourceCode): Takes the entire source code as input and converts it into tokens until the end of the string.
*/
#endregion
function GML_Tokenizer() : FlexiParseBase() constructor {
	sourceCodeString = "";
	sourceCodeCharLength = 0;
	sourceCodeByteLength = 0;
	sourceCodeBuffer = undefined;
	sourceCodeLineArray = undefined;
	
	charPos = 0;
	bytePos = 0;
	
	currentCharCode = undefined;
	
	tokens = undefined;
	program = undefined;
	
	line = 1;
	column = 0;
	
	finished = false;
	
	templateStringDepth = 0;
	
	
	sandboxed = false;
	keywords = ["globalvar", "var", "if", "then", "else", "begin", "end", "for", "while", "do",
	"until", "repeat", "switch", "case", "default", "break", "continue", "with", "exit", "return",
	"global", "mod", "div", "not", "and", "or", "xor", "enum", "function", "new", "constructor",
	"static", "region", "endregion", "macro", "try", "catch", "finally", "define", "throw",
	"delete", "_GMLINE_", "_GMFUNCTION_"];
	
	// Initialize tokenizer with source code
	static __initialize = function(_sourceCode) {
		sourceCodeString = string_replace_all(string_replace_all(_sourceCode, "\r\n", "\n"), "\r", "\n");
		sourceCodeCharLength = string_length(sourceCodeString);
		tokens = [];
		program = new __GMLC_ProgramTokens(tokens);
		
		sourceCodeLineArray = string_split(sourceCodeString, "\n");
		
		sourceCodeByteLength = string_byte_length(sourceCodeString);
		charPos = 0;
		bytePos = 0;
		
		//destroy old buffer if we were previously parsing
		__cleanup();
		
		sourceCodeBuffer = buffer_create(sourceCodeByteLength, buffer_fixed, 1);
	    buffer_write(sourceCodeBuffer, buffer_text, sourceCodeString);
		buffer_seek(sourceCodeBuffer, buffer_seek_start, 0);
		
		line = 1;
		column = 0;
		
		finished = false;
	};
	
	static __cleanup = function() {
		if (sourceCodeBuffer != undefined && buffer_exists(sourceCodeBuffer)) {
			buffer_delete(sourceCodeBuffer);
			sourceCodeBuffer = undefined;
		};
	}
	
	static __isFinished = function() {
		return finished;
	}
	
	static __finalize = function() {
		return program;
	}
	
	static __nextToken = function() {
		__nextUTF8()
		return currentCharCode;
	}
	
	static __shouldBreakParserSteps = function(_output) {
		return (_output != false) || (currentCharCode == undefined)
	}
	
	#region Parser Functions
	
	static parseSkipWhitespace = function() {
		if (__char_is_whitespace(currentCharCode)) {
			while (currentCharCode != undefined) {
				if (currentCharCode == ord("\n")) {
					var _token = new __GMLC_create_token(__GMLC_TokenType.Whitespace, "\n", "\n", line, column);
					array_push(tokens, _token);
					return _token;
				}
				
				if (!__char_is_whitespace(__peekUTF8() ?? 0)) {
					break;
				}
				
				__nextUTF8();
			}
			
			return true;
		}
		//show_debug_message($":: parseSkipWhitespace :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseCommentLine = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		if (currentCharCode == ord("/") && _next_char == ord("/")) {
			//var _start_pos = charPos;
			var _start_line = line;
			var _start_column = column;
		
			__expectUTF8(ord("/")); //consume first /
			__expectUTF8(ord("/")); //consume second /
			var _raw_string = "//";
			
			while (currentCharCode != undefined)
			&& (currentCharCode != ord("\n"))
			&& (currentCharCode != ord("\r"))
			{
				_raw_string += chr(currentCharCode);
				__nextUTF8();
			}
			
			var _token = new __GMLC_create_token(__GMLC_TokenType.Comment, _raw_string, _raw_string, _start_line, _start_column);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseCommentLine :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseCommentBlock = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		if (currentCharCode == ord("/") && _next_char == ord("*")) {
			var _start_line = line;
			var _start_column = column;
		
			__expectUTF8(ord("/")); //consume /
			__expectUTF8(ord("*")); //consume *
			var _raw_string = "/*";
		
			while (currentCharCode != undefined)
			{
				if (currentCharCode == ord("*"))
				&& (__peekUTF8() == ord("/")) {
					break;
				}
				_raw_string += chr(currentCharCode);
				__nextUTF8();
			}
		
			__expectUTF8(ord("*")); //consume *
			__expectUTF8(ord("/")); //consume /
		
			_raw_string += "*/";
		
			var _token = new __GMLC_create_token(__GMLC_TokenType.Comment, _raw_string, _raw_string, _start_line, _start_column);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseCommentBlock :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseStringLiteral = function() {
		var _startCharCode = currentCharCode;
		if (currentCharCode == ord(@'"')) {
			//var _start_pos = charPos;
			var _start_line = line;
			var _start_column = column;
			
			var _raw_string = chr(currentCharCode);
			var _string = "";
			var _string_closed = false;
			var _should_break = false;
			
			__expectUTF8(ord("\"")); // consume the entry quote "
			
			while (currentCharCode != undefined) {
				var _char = chr(currentCharCode);
				
				//convert escape charactors 
				switch (currentCharCode) {
					case ord(@'\'): {
						__nextUTF8();
						switch (currentCharCode) {
							case ord(@'\'): { // \\
								_char = "\\";
							break;}
							case ord(@'"'): { // \"
								_char = "\"";
							break;}
							case ord(@'n'): { // \n
								_char = "\n";
							break;}
							case ord(@'r'): { // \r
								_char = "\r";
							break;}
							case ord(@'t'): { // \t
								_char = "\t";
							break;}
							case ord(@'f'): { // \f
								_char = "\f";
							break;}
							case ord(@'v'): { // \v
								_char = "\v";
							break;}
							case ord(@'b'): { // \b
								_char = "\b";
							break;}
							case ord(@'0'): { // \0
								_char = "\0";
								if (__peekUTF8() == ord("0") && __peekUTF8(1) == ord("0")) { // \000
									__nextUTF8();
									__nextUTF8();
									_char = "\000"
								}
							break;}
							case ord(@'u'): { // \uFFFFF
								_char = "0x";
								if (__char_is_hex(__peekUTF8() ?? 0)) {
									__nextUTF8();
									
									var _len = 0;
									while (currentCharCode != undefined)
									&& (__char_is_hex(currentCharCode))
									&& (currentCharCode != ord("_"))
									&& (_len <= 5)
									{
										_len += 1;
										_char += chr(currentCharCode);
										
										//if the next char is not hex back out
										var _nextToken = __peekUTF8();
										if (!__char_is_hex(_nextToken)) 
										|| (_nextToken == "_")
										{
											break;
										}
										
										__nextUTF8();
									}
								}
								
								_char = chr(real(_char))
							
							break;}
							case ord(@'x'): { // \xFF
								_char = "0x";
								if (__char_is_hex(__peekUTF8() ?? 0)) {
									__nextUTF8();
									
									var _len = 0;
									while (currentCharCode != undefined)
									&& (__char_is_hex(currentCharCode))
									&& (currentCharCode != ord("_"))
									&& (_len < 2)
									{
										_len += 1;
										_char += chr(currentCharCode);
										
										//if the next char is not hex back out
										var _nextToken = __peekUTF8();
										if (!__char_is_hex(_nextToken)) 
										|| (_nextToken == "_")
										{
											break;
										}
										
										__nextUTF8();
									}
								}
								
								if (string_length(_char) == 2) {
									throw_gmlc_error($"Error : <FileName>({_start_line}) : Error parsing \\x HEX value. 2 digits required.")
								}
								
								_char = chr(real(_char))
							
							break;}
							default: {
								_char = "";
							break;}
						}
					break;}
					case ord(@'"'): { // "
						_raw_string += @'"';
						_char = "";
						_string_closed = true;
					break;}
					case ord("\n"): { // \n
						_char = "";
						_should_break = true;
					break;}
				}
			
				_raw_string += _char;
				_string += _char;
			
				if (_string_closed || _should_break) break;
				
				__nextUTF8();
			}
			
			if (!_string_closed) {
				var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {_start_line} : Error parsing string literal - found newline within string";
				var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column);
				array_push(tokens, _token);
				return _token;
			}
			
			var _token = new __GMLC_create_token(__GMLC_TokenType.String, _raw_string, _string, _start_line, _start_column);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseStringLiteral :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseHexNumbers = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		
		if (currentCharCode == ord("$") && __char_is_hex(_next_char))
		|| (currentCharCode == ord("0") && _next_char == ord("x"))
		{
			var _start_line = line;
			var _start_column = column;
			
			if (currentCharCode == ord("$")) {
				__nextUTF8(); // consume $
				var _raw_string = "$"
			}
			else if (currentCharCode == ord("0")) {
				__nextUTF8(); // consume 0
				__nextUTF8(); // consume x
				var _raw_string = "0x"
			}
			else {
				throw_gmlc_error($"Entered parseHexNumbers with a non-valid entry string : {chr(currentCharCode)}")
			}
			
			var _len = 0;
			while (currentCharCode != undefined)
			&& (__char_is_hex(currentCharCode))
			{
				if (currentCharCode >= ord("0") && currentCharCode <= ord("9")) {
					_len += 1;
				}
				else if (currentCharCode >= ord("A") && currentCharCode <= ord("F")) {
					_len += 1;
				}
				else if (currentCharCode >= ord("a") && currentCharCode <= ord("f")) {
					_len += 1;
				}
				
				_raw_string += chr(currentCharCode);
				
				if (!__char_is_hex(__peekUTF8() ?? 0)) {
					break;
				}
				
				__nextUTF8();
			}
			
			#region Error Handling
			if (_len > 16) {
				var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {_start_line} : Hex number {_raw_string} is too large or too small :: input length == {_len}";
				var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column);
				return _token;
			}
			#endregion
			
			var _str = string_replace(_raw_string, "$", "0x")
			_str = string_replace_all(_str, "_", "")
			var _hex_value = real(_str);
			
			static __maxSigned32 = 0x7FFFFFFF
			if (_hex_value > __maxSigned32 || _hex_value < -__maxSigned32-1) _hex_value = __hexTo64Bit(_str);
			
			
			var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _raw_string, _hex_value, _start_line, _start_column);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseHexNumbers :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseStringTemplate = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		if (currentCharCode == ord("$"))
		&& (_next_char == ord(@'"'))
		{
			var _token = tokenizeTemplateString(false);
			array_push(tokens, _token);
			return _token;
		}
		if (templateStringDepth > 0)
		&& (currentCharCode == ord(@'}'))
		{
			var _token = tokenizeTemplateString(true);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseStringTemplate :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseBinaryNumber = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		if (currentCharCode == ord("0"))
		&& (_next_char == ord("b"))
		{
			var _start_line = line;
			var _start_column = column;
			
			if (currentCharCode == ord("0"))
			{
				__expectUTF8(ord("0")); // consume 0
				__expectUTF8(ord("b")); // consume b
				var _raw_string = "0b";
			}
			else
			{
				throw_gmlc_error($"Entered tokenizeBinaryNumber with a non-valid entry string : {chr(currentCharCode)}")
			}
			
			var _len = 0;
			while (currentCharCode != undefined)
			&& (__char_is_binary(currentCharCode))
			{
				_len += 1;
				_raw_string += chr(currentCharCode);
				
				if (!__char_is_binary(__peekUTF8() ?? 0)) {
					break;
				}
				
				__nextUTF8();
			}
			
			#region Error Handling
			if (_len > 64) {
				var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {line} : Binary number {_raw_string} is too large or too small";
				var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_str, _error, _start_line, _start_column);
				return _token;
			}
			#endregion
			
			var _str = string_replace_all(_raw_string, "_", "")
			var _binary_value = real(_str);
			
			static __maxSigned32 = 0x7FFFFFFF
			if (_binary_value > __maxSigned32 || _binary_value < -__maxSigned32-1) _binary_value = __binaryTo64Bit(_str);
			
			var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _raw_string, _binary_value, _start_line, _start_column);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseBinaryNumber :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseNumber = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		if (__char_is_digit(currentCharCode))
		|| (currentCharCode == ord(".") && __char_is_digit(_next_char))
		{
			var hasDecimal = false;
			var _start_line = line;
			var _start_column = column;
			
			var _num_string = ""
			while (currentCharCode != undefined)
			&& (__char_is_digit(currentCharCode) || currentCharCode == ord(".") || currentCharCode == ord("_"))
			{
				if (currentCharCode == ord(".")) {
					if (hasDecimal) { break; } // Prevent multiple decimals
					hasDecimal = true;
				}
				
				_num_string += chr(currentCharCode);
				
				
				var _nextToken = __peekUTF8() ?? 0
				if not (__char_is_digit(_nextToken) || _nextToken == ord(".") || _nextToken == ord("_")) {
					break;
				}
				
				__nextUTF8();
			}
			
			var _str = string_replace_all(_num_string, "_", "");
			var _number = real(_str);
			static __maxSigned32 = 0x7FFFFFFF
			if (_number > __maxSigned32 || _number < -__maxSigned32-1) _number = int64(_str);
			
			var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _num_string, _number, _start_line, _start_column);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseNumber :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseIdentifier = function() {
		var _startCharCode = currentCharCode;
		if (__char_is_alphabetic(currentCharCode))
		{
			var _start_line = line;
			var _start_column = column;
			
			var _raw_string = "";
			while (currentCharCode != undefined)
			&& (__char_is_alphanumeric(currentCharCode))
			{
				_raw_string += chr(currentCharCode);
				
				if (!__char_is_alphanumeric(__peekUTF8() ?? 0)) {
					break;
				}
				
				__nextUTF8();
			}
			
			var _identifier = _raw_string
			
			if (!sandboxed) {
				var _index = asset_get_index(_identifier);
				var _type = asset_get_type(_identifier)
				
				#region Assets
				if (is_handle(_index))
				&& (_index > -1)
				&& ((_type == asset_object)
				|| (_type == asset_sprite)
				|| (_type == asset_sound)
				|| (_type == asset_room)
				|| (_type == asset_tiles)
				|| (_type == asset_path)
				//|| (_type == asset_script)
				|| (_type == asset_font)
				|| (_type == asset_timeline)
				|| (_type == asset_shader)
				|| (_type == asset_animationcurve)
				|| (_type == asset_sequence)
				|| (_type == asset_particlesystem))
				{
					var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _identifier, _index, _start_line, _start_column);
					array_push(tokens, _token);
					return _token;
				}	
				#endregion
				#region Functions
			
				if (_type == asset_script) && (_index > -1) {
					var _token = new __GMLC_create_token(__GMLC_TokenType.Function, _identifier, _index, _start_line, _start_column);
					array_push(tokens, _token);
					return _token;
				}
				//built in functions
				static __functions_lookup = __ExistingFunctions();
				var _index = struct_get(__functions_lookup, _identifier)
				if (_index != undefined) {
					var _token = new __GMLC_create_token(__GMLC_TokenType.Function, _identifier, _index, _start_line, _start_column);
					array_push(tokens, _token);
					return _token;
				}
			
				static __dep_functions_lookup = __DeprocatedFunctions();
				var _index = struct_get(__dep_functions_lookup, _identifier)
				if (_index != undefined) {
					var _token = new __GMLC_create_token(__GMLC_TokenType.Function, _identifier, _index, _start_line, _start_column);
					array_push(tokens, _token);
					return _token;
				}
			
				#endregion
				#region Constants
			
			
				static __constants_lookup = __ExistingConstants();
				var _constant = struct_get(__constants_lookup, _identifier)
				if (_constant != undefined) {
					var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _identifier, _constant, _start_line, _start_column);
					array_push(tokens, _token);
					return _token;
				}
			
				static __dep_constants_lookup = __DeprocatedConstants();
				var _constant = struct_get(__dep_constants_lookup, _identifier)
				if (_constant != undefined) {
					var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _identifier, _constant, _start_line, _start_column);
					array_push(tokens, _token);
					return _token;
				}
			
				static __unique_variables_arr = __ExistingUniqueVariables();
				if (array_contains(__unique_variables_arr, _identifier)) {
					var _token = new __GMLC_create_token(__GMLC_TokenType.UniqueVariable, _identifier, _identifier, _start_line, _start_column);
					array_push(tokens, _token);
					return _token;
				}
			
				#endregion
				#region Enum Constants
			
				static __enum_header_arr = __ExistingEnumHeaderStrings();
				if (array_contains(__enum_header_arr, _identifier)) {
				
					static __enum_arr = __ExistingEnumStrings();
				
					var _found = false;
				
					//find the shortest/longest string
					var _shortest = infinity; var _longest  = 0;
					var _i=0; repeat(array_length(__enum_arr)) {
						var _length = string_length(__enum_arr[_i])
						_shortest = min(_shortest, _length);
						_longest  = max(_longest , _length);
					_i++}
				
					//define the range we will be peeking
					var _peek_length = _shortest - string_length(_identifier);
					var _iterations = _longest - string_length(_identifier) - _peek_length;
				
					var _temp_identifier = _identifier
					var _i=1; repeat(_peek_length) {
						_temp_identifier += chr(__peekUTF8(_i));
					_i++}
				
					//iterate through all and try to find a match
					var _i=1; repeat(_iterations) {
						var _nextIterToken = __peekUTF8(_peek_length+_i);
						
						if (_nextIterToken == undefined) {
							break;
						}
						
						_temp_identifier += chr(_nextIterToken);
					
						if (array_contains(__enum_arr, _temp_identifier)) {
							static __enum_lookup = __ExistingEnums();
							var _val = struct_get(__enum_lookup, _temp_identifier)
						
							var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _temp_identifier, _val, _start_line, _start_column);
							_found = true;
							break;
						}
					
					_i+=1;}//end repeat loop
				
					if (_found) {
						var _jump = string_length(_temp_identifier) - string_length(_identifier);
						repeat (_jump) __nextUTF8();
						
						array_push(tokens, _token);
						return _token;
					}
				}
			
				#endregion
				#region Keywords
			
				if (array_contains(keywords, _identifier)) {
					switch (_identifier) {
						case "begin":{
							var _token = new __GMLC_create_token(__GMLC_TokenType.Punctuation, _identifier, "{", _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case "end":{
							var _token = new __GMLC_create_token(__GMLC_TokenType.Punctuation, _identifier, "}", _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case "mod":{
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "mod", _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case "div":{
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "div", _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case "not":{
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "!", _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case "and":{
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "&&", _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case "or":{
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "||", _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case "xor":{
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "^^", _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case "_GMLINE_":{
							var _token = new __GMLC_create_token(__GMLC_TokenType.Number, "_GMLINE_", _start_line, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case "_GMFUNCTION_":{
							//this is actually handled later when we parse, for now just return the keyword
							throw_gmlc_error("_GMFUNCTION_ is currently not supported")
						break;}
					}
				
					var _token = new __GMLC_create_token(__GMLC_TokenType.Keyword, _identifier, _identifier, _start_line, _start_column);
					array_push(tokens, _token);
					return _token;
				}
				
				if (_identifier == "nameof") {
					var _start_line = line;
					var _start_column = column;
					
					__nextUTF8();
					__expectUTF8(ord("(")); //consume @
					
					var _raw_string = "nameof(";
					var _string = __fetchAllUntil(ord(")"));
					_raw_string += _string+")"
					
					var _token = new __GMLC_create_token(__GMLC_TokenType.String, _raw_string, _string, _start_line, _start_column);
					
					array_push(tokens, _token);
					return _token;
				}
				
				#endregion
			
				if (_identifier == "true")           var _token = new __GMLC_create_token(__GMLC_TokenType.Number, "true", true, _start_line, _start_column);
				else if (_identifier == "false")     var _token = new __GMLC_create_token(__GMLC_TokenType.Number, "false", false, _start_line, _start_column);
				else if (_identifier == "infinity")  var _token = new __GMLC_create_token(__GMLC_TokenType.Number, "infinity", infinity, _start_line, _start_column);
				else if (_identifier == "undefined") var _token = new __GMLC_create_token(__GMLC_TokenType.Number, "undefined", undefined, _start_line, _start_column);
				else if (_identifier == "NaN")       var _token = new __GMLC_create_token(__GMLC_TokenType.Number, "NaN", NaN, _start_line, _start_column);
				else                                 var _token = new __GMLC_create_token(__GMLC_TokenType.Identifier, _identifier, _identifier, _start_line, _start_column);
				
				array_push(tokens, _token);
				return _token;
			}
			else {
				// parse the exposed functions and assets
				//var _data = exposedIdentifiers[$ _identifier]
				//var _type = _data.type;
				//var _identifier = _data.value;
				//var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _identifier, _index, _start_line, _start_column);
				//array_push(tokens, _token);
				return _token;
			}
		}
		//show_debug_message($":: parseIdentifier :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseRawStringLiteral = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		if (currentCharCode == ord("@"))
		&& (_next_char == ord("'") || _next_char == ord(@'"'))
		{
			var _start_line = line;
			var _start_column = column;
			
			__expectUTF8(ord("@")); //consume @
			
			var _start_quote = currentCharCode;
			
			__nextUTF8(); // consume starting quote
			
			var _raw_string = "@"+chr(_start_quote);//add the starting quote
			var _string = __fetchAllUntil(_start_quote);
			_raw_string += _string+chr(currentCharCode) // add the closing quote
			
			var _token = new __GMLC_create_token(__GMLC_TokenType.String, _raw_string, _string, _start_line, _start_column);
			
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseRawStringLiteral :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseOperator = function() {
		var _startCharCode = currentCharCode;
		if (__char_is_operator(currentCharCode)) {
			//var _start_pos = charPos;
			var _start_line = line;
			var _start_column = column;
			
			var start = charPos;
			
			var _op_string = "";
			
			switch (currentCharCode) {
				case ord("!"): { // !
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord("="): { // !=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("#"): { // #
					_op_string += chr(currentCharCode);
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("$"): { // $
					_op_string += chr(currentCharCode);
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("%"): { // %
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord("="): { // %=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					_op_string += chr(currentCharCode);
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, "mod", _start_line, _start_column);
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("&"): { // &
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord("&"): { // &&
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("="): { // &=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("*"): { // *
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord("="): { // *=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("+"): { // +
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord("="): { // +=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("+"): { // ++
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("-"): { // -
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord("="): { // -=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("-"): { // --
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("/"): { // /
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord("="): {
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("<"): { // <
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord(">"): { // <> AKA: !=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, "!=", _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("="): { // <=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("<"): { // <<
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("="): { // =
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord("="): {
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord(">"): { // >
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord("="): {
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord(">"): {
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("?"): { // ?
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord("?"): { // ??
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _nextToken = __peekUTF8() ?? 0;
							switch (_nextToken) {
								case ord("="): { // ??=
									__nextUTF8();
									_op_string += chr(currentCharCode);
									var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
									array_push(tokens, _token);
									return _token;
								break;}
							}
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
							array_push(tokens, _token);
							return _token;
						break;}
					}
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("@"): { // @
					_op_string += chr(currentCharCode);
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("^"): { // ^
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord("^"): { // ^^
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("="): { // ^=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("~"): { // ~
					_op_string += chr(currentCharCode);
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("|"): { // |
					_op_string += chr(currentCharCode);
					var _nextToken = __peekUTF8() ?? 0;
					switch (_nextToken) {
						case ord("|"): { // ||
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("="): { // |=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					array_push(tokens, _token);
					return _token;
				break;};
				default: {
					throw_gmlc_error($"Entered tokenizeOperator with a non-valid entry string : {chr(currentCharCode)}")
				break;}
			}
			
		}
		//show_debug_message($":: parseOperator :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parsePunctuation = function() {
		var _startCharCode = currentCharCode;
		if (__char_is_punctuation(currentCharCode)) {
			var _start_line = line;
			var _start_column = column;
		
			var _punctuation = chr(currentCharCode);
			var _token = new __GMLC_create_token(__GMLC_TokenType.Punctuation, _punctuation, _punctuation, _start_line, _start_column);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parsePunctuation :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseEscapeOperator = function() {
		var _startCharCode = currentCharCode;
		if (currentCharCode == ord(@'\')) {
			var _token = new __GMLC_create_token(__GMLC_TokenType.EscapeOperator, "\\", "\\", line, column);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseEscapeOperator :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseIllegal = function() {
		var _start_line = line;
		var _start_column = column;
		
		var illegalChar = chr(currentCharCode);
		var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {_start_line} : invalid token \"{illegalChar}\"";
		var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, illegalChar, _error, _start_line, _start_column);
		
		array_push(tokens, _token);
		throw_gmlc_error(_error)
		return _token;
	};
	
	array_push(parserSteps, parseSkipWhitespace);
	array_push(parserSteps, parseCommentLine);
	array_push(parserSteps, parseCommentBlock);
	array_push(parserSteps, parseStringLiteral);
	array_push(parserSteps, parseHexNumbers);
	array_push(parserSteps, parseStringTemplate);
	array_push(parserSteps, parseBinaryNumber);
	array_push(parserSteps, parseNumber);
	array_push(parserSteps, parseIdentifier);
	array_push(parserSteps, parseRawStringLiteral);
	array_push(parserSteps, parseOperator);
	array_push(parserSteps, parsePunctuation);
	array_push(parserSteps, parseEscapeOperator);
	array_push(parserSteps, parseIllegal);
	
	#endregion
	
	
	#region Util
	
	static tokenizeTemplateString = function(_suffix=false) {
		// _suffix is used to state that we are attempting to close an already open template string
		
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		var _raw_string = chr(currentCharCode);
		var _string = "";
		var _string_closed = false;
		var _should_break = false;
		
		// consume the entry quote $"
		if (!_suffix) {
			__expectUTF8(ord("$"));
			__expectUTF8(ord(@'"'));
			_raw_string += @'"';
			templateStringDepth += 1;
		}
		else {
			__expectUTF8(ord("}"));
		}
		
		
		while (currentCharCode != undefined) {
			var _char = chr(currentCharCode);
			
			//convert escape charactors 
			switch (currentCharCode) {
				case ord(@'\'): {
					__nextUTF8();
					switch (currentCharCode) {
						case ord(@'\'): { // \\
							_char = "\\";
						break;}
						case ord(@'"'): { // \"
							_char = "\"";
						break;}
						case ord(@'n'): { // \n
							_char = "\n";
						break;}
						case ord(@'r'): { // \r
							_char = "\r";
						break;}
						case ord(@'t'): { // \t
							_char = "\t";
						break;}
						case ord(@'f'): { // \f
							_char = "\f";
						break;}
						case ord(@'v'): { // \v
							_char = "\v";
						break;}
						case ord(@'b'): { // \b
							_char = "\b";
						break;}
						case ord(@'0'): { // \0
							_char = "\0";
							if (__peekUTF8() == ord("0") && __peekUTF8(1) == ord("0")) { // \000
								__nextUTF8();
								__nextUTF8();
								_char = "\000"
							}
						break;}
						case ord(@'u'): { // \uFFFFF
							_char = "0x";
							if (__char_is_hex(__peekUTF8() ?? 0)) {
								__nextUTF8();
									
								var _len = 0;
								while (currentCharCode != undefined)
								&& (__char_is_hex(currentCharCode))
								&& (currentCharCode != ord("_"))
								&& (_len <= 5)
								{
									_len += 1;
									_char += chr(currentCharCode);
										
									//if the next char is not hex back out
									var _nextToken = __peekUTF8();
									if (!__char_is_hex(_nextToken)) 
									|| (_nextToken == "_")
									{
										break;
									}
										
									__nextUTF8();
								}
							}
								
							_char = chr(real(_char))
							
						break;}
						case ord(@'x'): { // \xFF
							_char = "0x";
							if (__char_is_hex(__peekUTF8() ?? 0)) {
								__nextUTF8();
									
								var _len = 0;
								while (currentCharCode != undefined)
								&& (__char_is_hex(currentCharCode))
								&& (currentCharCode != ord("_"))
								&& (_len < 2)
								{
									_len += 1;
									_char += chr(currentCharCode);
										
									//if the next char is not hex back out
									var _nextToken = __peekUTF8();
									if (!__char_is_hex(_nextToken)) 
									|| (_nextToken == "_")
									{
										break;
									}
										
									__nextUTF8();
								}
							}
								
							if (string_length(_char) == 2) {
								throw_gmlc_error($"Error : <FileName>({_start_line}) : Error parsing \\x HEX value. 2 digits required.")
							}
								
							_char = chr(real(_char))
							
						break;}
						default: {
							_char = "";
						break;}
					}
				break;}
				case ord(@'"'): { // "
					_raw_string += "\"";
					_char = "";
					templateStringDepth -= 1;
					_string_closed = true;
				break;}
				case ord("\n"): { // \n
					var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {_start_line} : Error parsing string literal - found newline within string";
					var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column);
					return _token;
				break;}
				case ord(@'{'): { // "
					if (!_suffix) {
						//increase the depth so we know how many we should close
						_raw_string += "{";
						_char = "";
						_should_break = true;
					}
					else {
						//if this is the middle segment
						_raw_string += "{";
						_char = "";
						_should_break = true;
					}
				break;}
			}
			
			_raw_string += _char;
			_string += _char;
			
			
			if (_string_closed || _should_break) break;
			
			__nextUTF8();
		}
		
		
		
		// $" full "
		if (string_starts_with(_raw_string, @'$"') && string_ends_with(_raw_string, @'"')) {
			var _token = new __GMLC_create_token(__GMLC_TokenType.String, _raw_string, _string, _start_line, _start_column);
		}
		// $" begin {
		else if (string_starts_with(_raw_string, @'$"') && string_ends_with(_raw_string, "{")) {
			var _token = new __GMLC_create_token(__GMLC_TokenType.TemplateStringBegin, _raw_string, _string, _start_line, _start_column);
		}
		// } middle {
		if (string_starts_with(_raw_string, "}") && string_ends_with(_raw_string, "{")) {
			var _token = new __GMLC_create_token(__GMLC_TokenType.TemplateStringMiddle, _raw_string, _string, _start_line, _start_column);
		}
		// } end "
		if (string_starts_with(_raw_string, "}") && string_ends_with(_raw_string, @'"')) {
			var _token = new __GMLC_create_token(__GMLC_TokenType.TemplateStringEnd, _raw_string, _string, _start_line, _start_column);
		}
		
		return _token;
	};
	
	#endregion
	
}

#endregion



#region Util
#region Buffer Accessors
/// @ignore
function __nextUTF8() {
	gml_pragma("forceinline");
	if (charPos >= sourceCodeCharLength) {
		finished = true;
		currentCharCode = undefined
		return undefined;
	}
	
	if (currentCharCode == ord("\n")) {
		line += 1;
		column = 1;
	}
	else {
		column += 1;
	}
	
	var _character = buffer_read(sourceCodeBuffer, buffer_u8);
	
	//Basic Latin
	if ((_character & 0x80) == 0x00) {
		bytePos += 1;
		currentCharCode = _character;
	}
	else if ((_character & $E0) == $C0) { //110xxxxx 10xxxxxx
		bytePos += 2;
		currentCharCode = ((_character & $1F) << 6) | (buffer_read(sourceCodeBuffer, buffer_u8) & $3F);
	}
	else if ((_character & $F0) == $E0) { //1110xxxx 10xxxxxx 10xxxxxx
		bytePos += 3;
		var _b = buffer_read(sourceCodeBuffer, buffer_u8);
		var _c = buffer_read(sourceCodeBuffer, buffer_u8);
		currentCharCode = ((_character & $0F) << 12) | ((_b & $3F) <<  6) | (_c & $3F);
	}
	else if ((_character & $F8) == $F0) { //11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
		bytePos += 4;
		var _b = buffer_read(sourceCodeBuffer, buffer_u8);
		var _c = buffer_read(sourceCodeBuffer, buffer_u8);
		var _d = buffer_read(sourceCodeBuffer, buffer_u8);
		currentCharCode = ((_character & $07) << 18) | ((_b & $3F) << 12) | ((_c & $3F) <<  6) | (_d & $3F);
	}
	else {
		bytePos += 1;
		currentCharCode = _character;
	}
	
	charPos += 1;
	
	return currentCharCode;
}
/// @ignore
function __peekUTF8(_look_ahead=1) {
	gml_pragma("forceinline");
	if (charPos > sourceCodeCharLength-1) return undefined;
		
	var _prev_charCode = currentCharCode;
	var _prev_charPos  = charPos;
	var _prev_bytePos  = bytePos;
	var _prev_line     = line;
	var _prev_column   = column;
	var _prev_finished = finished;
		
	repeat(_look_ahead) {
		__nextUTF8();
	}
		
	var _nextCharCode = currentCharCode;
		
	currentCharCode = _prev_charCode;
	buffer_seek(sourceCodeBuffer, buffer_seek_relative, _prev_bytePos-bytePos);
	charPos = _prev_charPos;
	bytePos = _prev_bytePos;
	line = _prev_line;
	column = _prev_column;
	finished = _prev_finished;
	
	return _nextCharCode;
}
/// @ignore
function __expectUTF8(_ord) {
	gml_pragma("forceinline");
	if is_string(_ord) {
		throw_gmlc_error("please use character code instead of a string")
	}
		
	if (currentCharCode != _ord) {
		throw_gmlc_error($"Expected {_ord} ({chr(_ord)}), got {currentCharCode} ({chr(currentCharCode)})\n({line}){sourceCodeLineArray[line-1]}");
	}
		
	__nextUTF8();
}
/// @ignore
function __optionalUTF8(_ord) {
	gml_pragma("forceinline");
	if is_string(_ord) {
		throw_gmlc_error("please use character code instead of a string")
	}
	
	var _character = buffer_read(sourceCodeBuffer, buffer_u8);
	var _charCode = 0;
	
	//Basic Latin
	if ((_character & 0x80) == 0x00) {
		_charCode = _character;
	}
	else if ((_character & $E0) == $C0) { //110xxxxx 10xxxxxx
		_charCode = ((_character & $1F) << 6) | (buffer_read(sourceCodeBuffer, buffer_u8) & $3F);
	}
	else if ((_character & $F0) == $E0) { //1110xxxx 10xxxxxx 10xxxxxx
		var _b = buffer_read(sourceCodeBuffer, buffer_u8);
		var _c = buffer_read(sourceCodeBuffer, buffer_u8);
		_charCode = ((_character & $0F) << 12) | ((_b & $3F) <<  6) | (_c & $3F);
	}
	else if ((_character & $F8) == $F0) { //11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
		var _b = buffer_read(sourceCodeBuffer, buffer_u8);
		var _c = buffer_read(sourceCodeBuffer, buffer_u8);
		var _d = buffer_read(sourceCodeBuffer, buffer_u8);
		_charCode = ((_character & $07) << 18) | ((_b & $3F) << 12) | ((_c & $3F) <<  6) | (_d & $3F);
	}
	
	buffer_seek(sourceCodeBuffer, buffer_seek_start, bytePos);
	return (_charCode == _ord);
}
/// @ignore
function __fetchAllUntil(_ord) {
	gml_pragma("forceinline");
	if (charPos >= sourceCodeCharLength) {
		currentCharCode = undefined
		return undefined;
	}
		
	var _string = "";
	while (currentCharCode != _ord && charPos < sourceCodeCharLength) {
		if (currentCharCode == ord("\n")) {
			line += 1;
			column = 1;
		}
		else {
			column += 1;
		}
			
		_string += chr(currentCharCode);
			
		var _character = buffer_read(sourceCodeBuffer, buffer_u8);
		
		//Basic Latin
		if ((_character & 0x80) == 0x00) {
			bytePos += 1;
			currentCharCode = _character;
		}
		else if ((_character & $E0) == $C0) { //110xxxxx 10xxxxxx
			bytePos += 2;
			currentCharCode = ((_character & $1F) << 6) | (buffer_read(sourceCodeBuffer, buffer_u8) & $3F);
		}
		else if ((_character & $F0) == $E0) { //1110xxxx 10xxxxxx 10xxxxxx
			bytePos += 3;
			var _b = buffer_read(sourceCodeBuffer, buffer_u8);
			var _c = buffer_read(sourceCodeBuffer, buffer_u8);
			currentCharCode = ((_character & $0F) << 12) | ((_b & $3F) <<  6) | (_c & $3F);
		}
		else if ((_character & $F8) == $F0) { //11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
			bytePos += 3;
			var _b = buffer_read(sourceCodeBuffer, buffer_u8);
			var _c = buffer_read(sourceCodeBuffer, buffer_u8);
			var _d = buffer_read(sourceCodeBuffer, buffer_u8);
			currentCharCode = ((_character & $07) << 18) | ((_b & $3F) << 12) | ((_c & $3F) <<  6) | (_d & $3F);
		}
		else {
			bytePos += 1;
			currentCharCode = _character;
		}
		
		charPos += 1;
	}
		
	return _string;
}
/// @ignore
function __fetchAllUntilExt(_arr_of_ords) {
	gml_pragma("forceinline");
	if (charPos >= sourceCodeCharLength) {
		currentCharCode = undefined
		return undefined;
	}
		
	var _string = "";
	while (!array_contains(_arr_of_ords, currentCharCode) && charPos < sourceCodeCharLength) {
		if (currentCharCode == ord("\n")) {
			line += 1;
			column = 1;
		}
		else {
			column += 1;
		}
			
		_string += chr(currentCharCode);
			
		var _character = buffer_read(sourceCodeBuffer, buffer_u8);
		
		//Basic Latin
		if ((_character & 0x80) == 0x00) {
			bytePos += 1;
			currentCharCode = _character;
		}
		else if ((_character & $E0) == $C0) { //110xxxxx 10xxxxxx
			bytePos += 2;
			currentCharCode = ((_character & $1F) << 6) | (buffer_read(sourceCodeBuffer, buffer_u8) & $3F);
		}
		else if ((_character & $F0) == $E0) { //1110xxxx 10xxxxxx 10xxxxxx
			bytePos += 3;
			var _b = buffer_read(sourceCodeBuffer, buffer_u8);
			var _c = buffer_read(sourceCodeBuffer, buffer_u8);
			currentCharCode = ((_character & $0F) << 12) | ((_b & $3F) <<  6) | (_c & $3F);
		}
		else if ((_character & $F8) == $F0) { //11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
			bytePos += 3;
			var _b = buffer_read(sourceCodeBuffer, buffer_u8);
			var _c = buffer_read(sourceCodeBuffer, buffer_u8);
			var _d = buffer_read(sourceCodeBuffer, buffer_u8);
			currentCharCode = ((_character & $07) << 18) | ((_b & $3F) << 12) | ((_c & $3F) <<  6) | (_d & $3F);
		}
		else {
			bytePos += 1;
			currentCharCode = _character;
		}
		
		charPos += 1;
	}
		
	return _string;
}

#endregion
#region Helper Functions
/// @ignore
function __char_is_digit(char) {
    gml_pragma("forceinline");
    return (char >= ord("0") && char <= ord("9"));
}

/// @ignore
function __char_is_alphanumeric(char) {
    gml_pragma("forceinline");
    return (char >= ord("a") && char <= ord("z"))
	|| (char >= ord("A") && char <= ord("Z"))
	|| (char >= ord("0") && char <= ord("9"))
	|| (char == ord("_"));
}

/// @ignore
function __char_is_alphabetic(char) {
    gml_pragma("forceinline");
    return (char >= ord("a") && char <= ord("z"))
	|| (char >= ord("A") && char <= ord("Z"))
	|| (char == ord("_"));
}

/// @ignore
function __char_is_hex(char) {
    gml_pragma("forceinline");
    return (char >= ord("a") && char <= ord("f"))
	|| (char >= ord("A") && char <= ord("F"))
	|| (char >= ord("0") && char <= ord("9"))
	|| (char == ord("_"));
}

/// @ignore
function __char_is_binary(char) {
    gml_pragma("forceinline");
    return (char >= ord("0") && char <= ord("1"))
	|| (char == ord("_"));
}

/// @ignore
function __char_is_operator(char) {
    gml_pragma("forceinline");
	return (char >= ord("!") && char <= ord("&") && char != ord("\"")) // ! # $ % &
	|| (char >= ord("*") && char <= ord("/") && char != ord(",") && char != ord(".")) // * + - /
	|| (char >= ord("<") && char <= ord("@")) // < = > ? @
	|| (char == ord("^"))
	|| (char == ord("~"))
	|| (char == ord("|"));
	
}

/// @ignore
function __char_is_punctuation(char) {
    gml_pragma("forceinline");
	return (char == ord("("))
	|| (char == ord(")"))
	|| (char == ord("{"))
	|| (char == ord("}"))
	|| (char == ord("."))
	|| (char == ord(","))
	|| (char == ord("["))
	|| (char == ord("]"))
	|| (char == ord(":"))
	|| (char == ord(";"));
}

/// @ignore
function __char_is_whitespace(char) {
    gml_pragma("forceinline");
    return char >= 0x09 && char <= 0x0D || char == 0x20 || char == 0x85;
}

/// @ignore
function __hexTo64Bit(_hexString) {
    // Strip the "0x" prefix and underscores
    _hexString = string_replace_all(string_delete(_hexString, 1, 2), "_", "");

    // Initialize the high and low 32-bit parts
    var highValue = 0;
    var lowValue = 0;
    var len = string_length(_hexString);

    // Parse hex manually and split into high and low 32-bit parts
    for (var i = 0; i < len; i++) {
        var _char = ord(string_char_at(_hexString, i + 1));
        
        var digit;
        if (_char >= ord("0") && _char <= ord("9")) {
            digit = _char - ord("0");
        } else if (_char >= ord("a") && _char <= ord("f")) {
            digit = _char - ord("a") + 10;
        } else if (_char >= ord("A") && _char <= ord("F")) {
            digit = _char - ord("A") + 10;
        } else {
            throw "Invalid character in hex string: " + chr(_char);
        }

        if (len - i > 8) {  // Assign to highValue if in the first 8 hex digits
            highValue = (highValue << 4) | digit;
        } else {  // Assign to lowValue for the last 8 hex digits
            lowValue = (lowValue << 4) | digit;
        }
    }

    // Apply 2's complement for highValue if needed
    if (highValue >= 0x80000000) {
        highValue -= 0x100000000;  // Convert to signed 32-bit
    }

    // Combine high and low parts into a 64-bit signed integer
    return (highValue << 32 ) | lowValue;
}

/// @ignore
function __binaryTo64Bit(_binaryString) {
    // Strip the "0b" prefix and underscores
    _binaryString = string_replace_all(string_delete(_binaryString, 1, 2), "_", "");

    // Initialize high and low 32-bit parts
    var highValue = 0;
    var lowValue = 0;
    var len = string_length(_binaryString);

    // Parse binary manually and split into high and low 32-bit parts
    for (var i = 0; i < len; i++) {
        var _char = string_char_at(_binaryString, i + 1);

        var digit;
        if (_char == "0") {
            digit = 0;
        } else if (_char == "1") {
            digit = 1;
        } else {
            throw "Invalid character in binary string: " + _char;
        }

        if (len - i > 32) {  // Assign to highValue if in the first 32 bits
            highValue = (highValue << 1) | digit;
        } else {  // Assign to lowValue for the remaining bits
            lowValue = (lowValue << 1) | digit;
        }
    }

    // Apply 2's complement for highValue if needed
    if (highValue >= 0x80000000) {
        highValue -= 0x100000000;  // Convert to signed 32-bit
    }

    // Combine high and low parts into a 64-bit signed integer
    return (highValue << 32 ) | lowValue;
}

#endregion
#region Constructors
/// @ignore
function __GMLC_ProgramTokens(_tokens) constructor {
	GlobalVar = {};
	MacroVar  = {};
	EnumVar   = {};
	GlobalVarNames = [];
	MacroVarNames  = [];
	EnumVarNames   = {}; //structure is {HEADER1: [TAIL1, TAIL2, TAIL3], HEADER2: [TAIL1, TAIL2, TAIL3]}
	LocalVarNames  = [];
	
	tokens = _tokens;
}
/// @ignore
function __GMLC_create_token(_type, _name, _value, _line, _column, _lineString = other.sourceCodeLineArray[_line-1]) constructor {
	type   = _type;
	name   = _name;
	value  = _value;
	line   = _line;
	column = _column;
	lineString = _lineString;
		
	static toString = function() {
		return $"\{type: \"{type}\", name: \"{name}\", value: \"{value}\", line: {line}, column: {column}, lineString: {lineString}\}"
	}
};
#endregion
#endregion


