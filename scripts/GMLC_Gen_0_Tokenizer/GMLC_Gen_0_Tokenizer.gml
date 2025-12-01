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
function GMLC_Gen_0_Tokenizer(_env) : FlexiParseBase() constructor {
	env = _env;
	
	//these are speed based look up tables for our env, these will get initialized
	__keyword_lookup  = undefined;
	__function_lookup = undefined;
	__constant_lookup = undefined;
	__variable_lookup = undefined;
	
	sourceCodeString = "";
	sourceCodeCharLength = 0;
	sourceCodeByteLength = 0;
	sourceCodeBuffer = undefined;
	sourceCodeLineArray = undefined;
	
	charPos = 0;
	bytePos = 0;
	currentCharCode = undefined;
	
	templateStringDepth = 0;
	
	tokens = undefined;
	program = undefined;
	
	line = 1;
	column = 0;
	finished = false;
	
	lastFiveTokens = array_create(5, undefined);
	
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
		
		//update our env lookup tables
		env.__keyword_lookup  ??= __gmlc_convert_to_array_map(env.getAllKeywords());
		env.__function_lookup ??= __gmlc_convert_to_array_map(env.getAllFunctions());
		env.__constant_lookup ??= __gmlc_convert_to_array_map(env.getAllConstants());
		env.__variable_lookup ??= __gmlc_convert_to_array_map(env.getAllVariables());
		
		__keyword_lookup  = env.__keyword_lookup;
		__function_lookup = env.__function_lookup;
		__constant_lookup = env.__constant_lookup;
		__variable_lookup = env.__variable_lookup;
		
		__nextToken();
		
		return self;
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
		
		lastFiveTokens[0] = lastFiveTokens[1];
		lastFiveTokens[1] = lastFiveTokens[2];
		lastFiveTokens[2] = lastFiveTokens[3];
		lastFiveTokens[3] = lastFiveTokens[4];
		lastFiveTokens[4] = currentCharCode;
		
		return currentCharCode;
	}
	
	static __shouldBreakParserSteps = function(_output) {
		return (_output != false) || (currentCharCode == undefined)
	}
	
	#region Parser Functions
	
	static parseSkipWhitespace = function() {
		var _byte_start = bytePos;
		if (__char_is_whitespace(currentCharCode)) {
			while (currentCharCode != undefined) {
				if (currentCharCode == ord("\n")) {
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Whitespace, "\n", "\n", line, column, _byte_start, bytePos);
					array_push(tokens, _token);
					return _token;
				}
				
				if (!__char_is_whitespace(__peekUTF8() ?? 0)) {
					break;
				}
				
				__nextUTF8();
			}
			
			nextToken();
			return true;
		}
		//show_debug_message($":: parseSkipWhitespace :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseKeywords = function() {
		var _start_line = line;
		var _start_column = column;
		var _byte_start = bytePos;
		
		var _node = __keyword_lookup;
		var _char_index = 0;
		
		while (true) {
			var _byte = __peekUTF8(_char_index); // you’ll want this to peek *raw bytes*, not chars
			if (_byte == undefined) break;
			
			var _next = _node[_byte];
			if (_next == undefined) break;
			
			_node = _next;
			_char_index++;
			
			if (_node[0] != undefined)
			&& (!__char_is_alphanumeric(__peekUTF8(_char_index))) {
				
				//skip ahead
				var _identifier = "";
				
				repeat(_char_index-1) {
					_identifier += chr(currentCharCode);
					__nextUTF8();
				}
				
				_identifier += chr(currentCharCode);
				
				nextToken();
				
				switch (_identifier) {
					case "begin":{
						var _token = new __GMLC_create_token(__GMLC_TokenType.Punctuation, _identifier, "{", _start_line, _start_column, _byte_start, bytePos);
					break;}
					case "end":{
						var _token = new __GMLC_create_token(__GMLC_TokenType.Punctuation, _identifier, "}", _start_line, _start_column, _byte_start, bytePos);
					break;}
					case "mod":{
						var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "mod", _start_line, _start_column, _byte_start, bytePos);
					break;}
					case "div":{
						var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "div", _start_line, _start_column, _byte_start, bytePos);
					break;}
					case "not":{
						var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "!", _start_line, _start_column, _byte_start, bytePos);
					break;}
					case "and":{
						var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "&&", _start_line, _start_column, _byte_start, bytePos);
					break;}
					case "or":{
						var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "||", _start_line, _start_column, _byte_start, bytePos);
					break;}
					case "xor":{
						var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "^^", _start_line, _start_column, _byte_start, bytePos);
					break;}
					case "_GMLINE_":{
						var _token = new __GMLC_create_token(__GMLC_TokenType.Number, "_GMLINE_", _start_line, _start_line, _start_column, _byte_start, bytePos);
					break;}
					case "_GMFUNCTION_":{
						//this is actually handled later when we parse, for now just return the keyword
						throw_gmlc_error("_GMFUNCTION_ is currently not supported")
					break;}
					default:{
						var _token = new __GMLC_create_token(__GMLC_TokenType.Keyword, _identifier, _identifier, _start_line, _start_column, _byte_start, bytePos);
					break;}
				}
				
				array_push(tokens, _token);
				return _token;
			}
		}
		
		//show_debug_message($":: parseIdentifier :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseFunctions = function() {
		var _start_line = line;
		var _start_column = column;
		var _byte_start = bytePos;
		
		var _node = __function_lookup;
		var _char_index = 0;
		
		while (true) {
			var _byte = __peekUTF8(_char_index); // you’ll want this to peek *raw bytes*, not chars
			if (_byte == undefined) break;
			
			var _next = _node[_byte];
			if (_next == undefined) break;
			
			_node = _next;
			_char_index++;
			
			if (_node[0] != undefined)
			&& (!__char_is_alphanumeric(__peekUTF8(_char_index))) {
				
				//skip ahead
				var _identifier = "";
				
				repeat(_char_index-1) {
					_identifier += chr(currentCharCode);
					__nextUTF8();
				}
				
				_identifier += chr(currentCharCode);
				
				var _return = env.getFunction(_identifier)
				
				//if there was no match 
				if (_return == undefined) {
					var _return = env.getFunction(_identifier)
					return false;
				}
				
				nextToken();
				
				if (_identifier == "nameof") // will only occure when the vanilla `nameof` is exposed
				&& (_return.value == -1) // only possible for compile time operations
				&& (currentCharCode == ord("(")){
					var _startCharCode = currentCharCode;
					var _byte_start = bytePos;
					var _start_line = line;
					var _start_column = column;
					
					__expectUTF8(ord("(")); //consume (
					
					var _raw_string = "nameof("
					var _string = __fetchAllUntil(ord(")"));
					_raw_string += _string+")";
			
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.String, _raw_string, _string, _start_line, _start_column, _byte_start, bytePos);
					array_push(tokens, _token);
					return _token;
					
				}
				else {
					var _token = new __GMLC_create_token(__GMLC_TokenType.Function, _identifier, _return.value, _start_line, _start_column, _byte_start, bytePos);
					array_push(tokens, _token);
					return _token;
				}
			}
		}
		
		//show_debug_message($":: parseIdentifier :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	

	
	
	static parseConstants = function() {
		var _start_line = line;
		var _start_column = column;
		var _byte_start = bytePos;
		
		var _node = __constant_lookup;
		var _char_index = 0;
		
		while (true) {
			var _byte = __peekUTF8(_char_index); // you’ll want this to peek *raw bytes*, not chars
			if (_byte == undefined) break;
			
			var _next = _node[_byte];
			if (_next == undefined) break;
			
			_node = _next;
			_char_index++;
			
			if (_node[0] != undefined)
			&& (!__char_is_alphanumeric(__peekUTF8(_char_index))) {
				
				//skip ahead
				var _identifier = "";
				
				repeat(_char_index-1) {
					_identifier += chr(currentCharCode);
					__nextUTF8();
				}
				
				_identifier += chr(currentCharCode);
				
				var _return = env.getConstant(_identifier);
				
				//if there was no match 
				if (_return == undefined) {
					var _return = env.getConstant(_identifier)
					return false;
				}
				
				nextToken();
				var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _identifier, _return.value, _start_line, _start_column, _byte_start, bytePos);
				array_push(tokens, _token);
				return _token;
			}
		}
		
		//show_debug_message($":: parseIdentifier :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseVariables = function() {
		var _start_line = line;
		var _start_column = column;
		var _byte_start = bytePos;
		
		var _node = __variable_lookup;
		var _char_index = 0;
		
		while (true) {
			var _byte = __peekUTF8(_char_index); // you’ll want this to peek *raw bytes*, not chars
			if (_byte == undefined) break;
			
			var _next = _node[_byte];
			if (_next == undefined) break;
			
			_node = _next;
			_char_index++;
			
			if (_node[0] != undefined)
			&& (!__char_is_alphanumeric(__peekUTF8(_char_index))) {
				
				//skip ahead
				var _identifier = "";
				
				repeat(_char_index-1) {
					_identifier += chr(currentCharCode);
					__nextUTF8();
				}
				
				_identifier += chr(currentCharCode);
				
				var _return = env.getVariable(_identifier)
				
				//if there was no match 
				if (_return == undefined) {
					var _return = env.getVariable(_identifier)
					return false;
				}
				
				nextToken();
				var _token = new __GMLC_create_token(__GMLC_TokenType.UniqueVariable, _identifier, _return.value, _start_line, _start_column, _byte_start, bytePos);
				array_push(tokens, _token);
				return _token;
			}
		}
		
		//show_debug_message($":: parseIdentifier :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseCommentLine = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		var _byte_start = bytePos;
		if (currentCharCode == ord("/") && _next_char == ord("/")) {
			//var _start_pos = charPos;
			var _start_line = line;
			var _start_column = column;
			
			__expectUTF8(ord("/")); //consume first /
			__expectUTF8(ord("/")); //consume second /
			var _raw_string = "//";
			
			while (currentCharCode != undefined)
			{
				_raw_string += chr(currentCharCode);
				
				var _next_char = __peekUTF8();
				if (_next_char == ord("\n"))
				|| (_next_char == ord("\r")) {
					break;
				}
				
				__nextUTF8();
			}
			
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.Comment, _raw_string, _raw_string, _start_line, _start_column, _byte_start, bytePos);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseCommentLine :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseCommentBlock = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		var _byte_start = bytePos;
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
					__expectUTF8(ord("*")); //consume *
					
					//we dont actually want to consume this, flexi parse will move us onto our next thing on it's own.
					//__expectUTF8(ord("/")); //consume /
					
					_raw_string += "*/";
					
					break;
				}
				_raw_string += chr(currentCharCode);
				__nextUTF8();
			}
			
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.Comment, _raw_string, _raw_string, _start_line, _start_column, _byte_start, bytePos);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseCommentBlock :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseStringLiteral = function() {
		var _startCharCode = currentCharCode;
		var _byte_start = bytePos;
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
				nextToken();
				var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column, _byte_start, bytePos);
				array_push(tokens, _token);
				return _token;
			}
			
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.String, _raw_string, _string, _start_line, _start_column, _byte_start, bytePos);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseStringLiteral :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseHexNumbers = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		var _byte_start = bytePos;
		if (currentCharCode == ord("$") && __char_is_hex(_next_char))
		|| (currentCharCode == ord("#") && __char_is_hex(_next_char))
		|| (currentCharCode == ord("0") && _next_char == ord("x"))
		{
			var _start_line = line;
			var _start_column = column;
			
			//this will force a requirement of 6 digits
			var _is_color = false;
			
			if (currentCharCode == ord("$")) {
				__nextUTF8(); // consume $
				var _raw_string = "$";
			}
			else if (currentCharCode == ord("#")) {
				__nextUTF8(); // consume #
				var _raw_string = "#";
				var _is_color = true;
			}
			else if (currentCharCode == ord("0")) {
				__nextUTF8(); // consume 0
				__nextUTF8(); // consume x
				var _raw_string = "0x"
			}
			else {
				throw_gmlc_error($"Entered parseHexNumbers with a non-valid entry string : {chr(currentCharCode)} This is a bug! Please report!")
			}
			
			//this is the string actually passed into `real()`
			var _hex_str = "0x"
			
			var _len = 0;
			while (currentCharCode != undefined)
			&& (__char_is_hex(currentCharCode))
			{
				var _char = chr(currentCharCode);
				
				if (currentCharCode != ord("_")) {
					_len += 1;
					_hex_str += _char;
				}
				
				_raw_string += _char;
				
				if (!__char_is_hex(__peekUTF8() ?? 0)) {
					break;
				}
				
				__nextUTF8();
			}
			
			#region Error Handling
			//ensure the resulting string of a #color is exactly 6 digits long
			if (_is_color)
			&& (_len != 6) {
				throw_gmlc_error($"Script: \{Script1\} at line { _start_line} : css hex color needs to be 6 digits\n{_raw_string}")
			}
			
			//ensure hex numbers are less then 16 digits long
			if (_len > 16) {
				var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {_start_line} : Hex number {_raw_string} is too large or too small :: input length == {_len}";
				nextToken();
				var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column, _byte_start, bytePos);
				array_push(tokens, _token);
				return _token;
			}
			#endregion
			
			var _hex_value = real(_hex_str);
			
			static __maxSigned32 = 0x7FFFFFFF
			if (_hex_value > __maxSigned32 || _hex_value < -__maxSigned32-1) _hex_value = __hexTo64Bit(_hex_str);
			
			
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _raw_string, _hex_value, _start_line, _start_column, _byte_start, bytePos);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseHexNumbers :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseStringTemplate = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		var _byte_start = bytePos;
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
		var _byte_start = bytePos;
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
				nextToken();
				var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column, _byte_start, bytePos);
				array_push(tokens, _token);
				return _token;
			}
			#endregion
			
			var _str = string_replace_all(_raw_string, "_", "")
			var _binary_value = real(_str);
			
			static __maxSigned32 = 0x7FFFFFFF
			if (_binary_value > __maxSigned32 || _binary_value < -__maxSigned32-1) _binary_value = __binaryTo64Bit(_str);
			
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _raw_string, _binary_value, _start_line, _start_column, _byte_start, bytePos);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseBinaryNumber :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseNumber = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		var _byte_start = bytePos;
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
			
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _num_string, _number, _start_line, _start_column, _byte_start, bytePos);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseNumber :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseIdentifier = function() {
		var _startCharCode = currentCharCode;
		var _byte_start = bytePos;
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
			
			
			#region nameof()
			if (_identifier == "nameof") {
				var _start_line = line;
				var _start_column = column;
					
				__nextUTF8();
				__expectUTF8(ord("(")); //consume @
					
				var _raw_string = "nameof(";
				var _string = __fetchAllUntil(ord(")"));
				_raw_string += _string+")"
				
				nextToken();
				var _token = new __GMLC_create_token(__GMLC_TokenType.String, _raw_string, _string, _start_line, _start_column, _byte_start, bytePos);
				array_push(tokens, _token);
				return _token;
			}
			#endregion
			#region Functions
				
			//var _index = env.getFunction(_identifier);
			//if (_index != undefined) {
			//	nextToken();
			//	var _token = new __GMLC_create_token(__GMLC_TokenType.Function, _identifier, _index.value, _start_line, _start_column, _byte_start, bytePos);
			//	array_push(tokens, _token);
			//	return _token;
			//}
				
			#endregion
			#region Constants
			
			//var _index = env.getConstant(_identifier);
			//if (_index != undefined) {
			//	nextToken();
			//	var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _identifier, _index.value, _start_line, _start_column, _byte_start, bytePos);
			//	array_push(tokens, _token);
			//	return _token;
			//}
			
			#endregion
			#region Variables
			
			//var _index = env.getVariable(_identifier);
			//if (_index != undefined) {
			//	nextToken();
			//	var _token = new __GMLC_create_token(__GMLC_TokenType.UniqueVariable, _identifier, _identifier, _start_line, _start_column, _byte_start, bytePos);
			//	array_push(tokens, _token);
			//	return _token;
			//}
			
			#endregion
			#region Enum Constants
			var _index = env.getEnum(_identifier);
			if (_index != undefined) {
				var _found = false;
				
				var _enum_tail_arr = struct_get_names(_index.value);
				
				//find the shortest/longest string
				var _shortest = infinity; var _longest  = 0;
				var _i=0; repeat(array_length(_enum_tail_arr)) {
					var _length = string_length(_enum_tail_arr[_i])
					_shortest = min(_shortest, _length);
					_longest  = max(_longest , _length);
				_i++}
				
				//define the range we will be peeking
				var _peek_length = _shortest;
				var _iterations = _longest - _peek_length;
				
				var _offset = 1; //skip the dot
				
				var _temp_identifier = "";
				var _i=_offset+1; repeat(_peek_length - 1) { //offload the adding of the last init char to the next loop since it already started with string adding
					_temp_identifier += chr(__peekUTF8(_i));
				_i++}
				
				
				
				//iterate through all and try to find a match
				var _i=_offset; repeat(_iterations+1) { // account for last char of start
					var _nextIterToken = __peekUTF8(_peek_length+_i);
						
					if (_nextIterToken == undefined) {
						break;
					}
						
					_temp_identifier += chr(_nextIterToken);
					
					if (array_contains(_enum_tail_arr, _temp_identifier)) {
						var _val = _index.value[$ _temp_identifier];
						var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _temp_identifier, _val, _start_line, _start_column, _byte_start, bytePos);
						_found = true;
						break;
					}
					
				_i+=1;}//end repeat loop
				
				if (_found) {
					var _jump = _offset+string_length(_temp_identifier);
					repeat (_jump) __nextUTF8();
					
					__nextUTF8() //we do one extra to continue to the next
					
					array_push(tokens, _token);
					return _token;
				}
			}
			
			#endregion
			#region Keywords
				
			//var _index = env.getKeyword(_identifier);
			//if (_index != undefined) {
			//	switch (_identifier) {
			//		case "begin":{
			//			var _token = new __GMLC_create_token(__GMLC_TokenType.Punctuation, _identifier, "{", _start_line, _start_column, _byte_start, bytePos);
			//			array_push(tokens, _token);
			//			return _token;
			//		break;}
			//		case "end":{
			//			var _token = new __GMLC_create_token(__GMLC_TokenType.Punctuation, _identifier, "}", _start_line, _start_column, _byte_start, bytePos);
			//			array_push(tokens, _token);
			//			return _token;
			//		break;}
			//		case "mod":{
			//			var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "mod", _start_line, _start_column, _byte_start, bytePos);
			//			array_push(tokens, _token);
			//			return _token;
			//		break;}
			//		case "div":{
			//			var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "div", _start_line, _start_column, _byte_start, bytePos);
			//			array_push(tokens, _token);
			//			return _token;
			//		break;}
			//		case "not":{
			//			var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "!", _start_line, _start_column, _byte_start, bytePos);
			//			array_push(tokens, _token);
			//			return _token;
			//		break;}
			//		case "and":{
			//			var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "&&", _start_line, _start_column, _byte_start, bytePos);
			//			array_push(tokens, _token);
			//			return _token;
			//		break;}
			//		case "or":{
			//			var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "||", _start_line, _start_column, _byte_start, bytePos);
			//			array_push(tokens, _token);
			//			return _token;
			//		break;}
			//		case "xor":{
			//			var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "^^", _start_line, _start_column, _byte_start, bytePos);
			//			array_push(tokens, _token);
			//			return _token;
			//		break;}
			//		case "_GMLINE_":{
			//			var _token = new __GMLC_create_token(__GMLC_TokenType.Number, "_GMLINE_", _start_line, _start_line, _start_column, _byte_start, bytePos);
			//			array_push(tokens, _token);
			//			return _token;
			//		break;}
			//		case "_GMFUNCTION_":{
			//			//this is actually handled later when we parse, for now just return the keyword
			//			throw_gmlc_error("_GMFUNCTION_ is currently not supported")
			//		break;}
			//	}
				
			//	var _token = new __GMLC_create_token(__GMLC_TokenType.Keyword, _identifier, _identifier, _start_line, _start_column, _byte_start, bytePos);
			//	array_push(tokens, _token);
			//	return _token;
			//}
				
			#endregion
			// else...
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.Identifier, _identifier, _identifier, _start_line, _start_column, _byte_start, bytePos);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseIdentifier :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseRawStringLiteral = function() {
		var _startCharCode = currentCharCode;
		var _next_char = __peekUTF8() ?? 0;
		var _byte_start = bytePos;
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
			
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.String, _raw_string, _string, _start_line, _start_column, _byte_start, bytePos);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseRawStringLiteral :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseOperator = function() {
		var _startCharCode = currentCharCode;
		var _byte_start = bytePos;
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
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("#"): { // #
					_op_string += chr(currentCharCode);
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("$"): { // $
					_op_string += chr(currentCharCode);
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
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
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					_op_string += chr(currentCharCode);
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, "mod", _start_line, _start_column, _byte_start, bytePos);
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
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("="): { // &=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
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
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
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
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("+"): { // ++
							__nextUTF8();
							_op_string += chr(currentCharCode);
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
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
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("-"): { // --
							__nextUTF8();
							_op_string += chr(currentCharCode);
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
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
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
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
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, "!=", _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("="): { // <=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("<"): { // <<
							__nextUTF8();
							_op_string += chr(currentCharCode);
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
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
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
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
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord(">"): {
							__nextUTF8();
							_op_string += chr(currentCharCode);
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
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
									nextToken();
									var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
									array_push(tokens, _token);
									return _token;
								break;}
							}
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("@"): { // @
					_op_string += chr(currentCharCode);
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
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
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("="): { // ^=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
					array_push(tokens, _token);
					return _token;
				break;};
				case ord("~"): { // ~
					_op_string += chr(currentCharCode);
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
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
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
						case ord("="): { // |=
							__nextUTF8();
							_op_string += chr(currentCharCode);
							nextToken();
							var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
							array_push(tokens, _token);
							return _token;
						break;}
					}
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column, _byte_start, bytePos);
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
		var _byte_start = bytePos;
		if (__char_is_punctuation(currentCharCode)) {
			var _start_line = line;
			var _start_column = column;
		
			var _punctuation = chr(currentCharCode);
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.Punctuation, _punctuation, _punctuation, _start_line, _start_column, _byte_start, bytePos);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parsePunctuation :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseEscapeOperator = function() {
		var _startCharCode = currentCharCode;
		var _byte_start = bytePos;
		if (currentCharCode == ord(@'\')) {
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.EscapeOperator, "\\", "\\", line, column, _byte_start, bytePos);
			array_push(tokens, _token);
			return _token;
		}
		//show_debug_message($":: parseEscapeOperator :: Could not parse char : {_startCharCode} '{chr(_startCharCode)}'")
		return false;
	};
	
	static parseIllegal = function() {
		var _start_line = line;
		var _start_column = column;
		var _byte_start = bytePos;
		
		log(
			"Illegal token found! Here is relevant information which may be vital to helping hunt it down,",
			"Due note if this is a #region, then this will be handled at a later step and this can be ignored. <3",
			lastFiveTokens,
			charPos,
			sourceCodeCharLength,
			string_copy(sourceCodeString, (charPos-20) ? charPos-20 : 0, charPos)
		)
		
		var illegalChar = chr(currentCharCode);
		var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {_start_line} : invalid token \"{illegalChar}\"";
		nextToken();
		var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, illegalChar, _error, _start_line, _start_column, _byte_start, bytePos);
		
		array_push(tokens, _token);
		
		//why the fuck did we throw errors here?! that should happen when we actually parse, for all we know a macro or region could make this a string or comment
		// DONT THROW ERRORS HERE!!!
		//throw_gmlc_error(_error)
		
		return _token;
	};
	
	array_push(parserSteps,
		parseSkipWhitespace,
		parseKeywords,
		parseFunctions,
		parseConstants,
		parseVariables,
		parseCommentLine,
		parseCommentBlock,
		parseStringLiteral,
		parseStringTemplate,
		parseHexNumbers,
		parseBinaryNumber,
		parseIdentifier,
		parseNumber,
		parseRawStringLiteral,
		parseOperator,
		parsePunctuation,
		parseEscapeOperator,
		parseIllegal
	);
	
	#endregion
	
	#region Util
	
	static tokenizeTemplateString = function(_suffix=false) {
		// _suffix is used to state that we are attempting to close an already open template string
		
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		var _byte_start = bytePos;
		
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
					nextToken();
					var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column, _byte_start, bytePos);
					array_push(tokens, _token);
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
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.String, _raw_string, _string, _start_line, _start_column, _byte_start, bytePos);
		}
		// $" begin {
		else if (string_starts_with(_raw_string, @'$"') && string_ends_with(_raw_string, "{")) {
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.TemplateStringBegin, _raw_string, _string, _start_line, _start_column, _byte_start, bytePos);
		}
		// } middle {
		if (string_starts_with(_raw_string, "}") && string_ends_with(_raw_string, "{")) {
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.TemplateStringMiddle, _raw_string, _string, _start_line, _start_column, _byte_start, bytePos);
		}
		// } end "
		if (string_starts_with(_raw_string, "}") && string_ends_with(_raw_string, @'"')) {
			nextToken();
			var _token = new __GMLC_create_token(__GMLC_TokenType.TemplateStringEnd, _raw_string, _string, _start_line, _start_column, _byte_start, bytePos);
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
function __GMLC_create_token(_type, _name, _value, _line, _column, _byte_start, _byte_end, _lineString = other.sourceCodeLineArray[_line-1]) constructor {
	type   = _type;
	name   = _name;
	value  = _value;
	line   = _line;
	column = _column;
	byteStart  = _byte_start;
	byteEnd    = _byte_end;
	lineString = _lineString;
		
	static toString = function() {
		return $"\{type: \"{type}\", name: \"{name}\", value: \"{value}\", line: {line}, column: {column}, lineString: {lineString}\}"
	}
};
#endregion
#endregion


