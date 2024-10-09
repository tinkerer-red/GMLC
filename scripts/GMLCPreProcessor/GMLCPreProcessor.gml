#region PreProcessor.gml

function GML_PreProcessor() constructor {
	program = undefined;
	tokens = undefined;
	processedTokens = [];
	currentTokenIndex = 0;
	currentToken = undefined;
	passCount = 0;
	
	lastFiveTokens = array_create(5, undefined);
	
	static initialize = function(_programTokens) {
		
		program = _programTokens;
		tokens = _programTokens.tokens;
		processedTokens = [];
		program.tokens = processedTokens;
		currentTokenIndex = 0;
		currentToken = tokens[currentTokenIndex];
		passCount = 0;
	};
	
	static parseAll = function() {
		// First pass: collect macros and enums
		while (currentToken != undefined) {
			parseNext();
			
			if (GML_COMPILER_DEBUG) {
				static __lastString = ""
				var _str = string((currentTokenIndex+passCount*array_length(tokens))/(array_length(tokens)*(passState.SIZE))/10)
				if (__lastString != _str) {
					do_trace($"{real(_str)*1000}% Finished")
					__lastString = _str;
				}
			}
		}
		
		return program;
	};
	
	static parseNext = function() {
		
		switch (currentToken.type) {
			case __GMLC_TokenType.Whitespace:
			case __GMLC_TokenType.Comment:
			case __GMLC_TokenType.Region:{
				// These will be skipped in the final cleanup pass
				//array_push(processedTokens, currentToken);
			break;}
			case __GMLC_TokenType.Operator:{
				if (currentToken.value == "#") {
					var _next_token = peekToken();
					if (_next_token.type == __GMLC_TokenType.Keyword) {
						if (_next_token.value == "macro") {
							parseMacroDefinition();
							break;
						}
						if (_next_token.value == "define") {
							nextToken(); // skip #
							nextToken(); // skip define
							array_push(processedTokens, new __GMLC_create_token(__GMLC_TokenType.Define, "#define", "#define", currentToken.line, currentToken.column, currentToken.lineString));
							break;
						}
					}
				}
			/*break;*/} // dont break, we want everything to waterfall into default which didnt succeed
			case __GMLC_TokenType.Keyword:{
				if (currentToken.value == "enum") {
					parseEnumDefinition();
					break;
				}
			/*break;*/} // dont break, we want everything to waterfall into default which didnt succeed
			default:{
				//push everything back in
				array_push(processedTokens, currentToken);
			break;}
		}
		
		if (currentToken == undefined) {
			return program;
		}
		
		// Move to the next token
		nextToken();
		
		return undefined;
	};
	
	static nextToken = function() {
		lastFiveTokens[0] = lastFiveTokens[1];
		lastFiveTokens[1] = lastFiveTokens[2];
		lastFiveTokens[2] = lastFiveTokens[3];
		lastFiveTokens[3] = lastFiveTokens[4];
		lastFiveTokens[4] = currentToken;
		
		currentTokenIndex++;
		if (currentTokenIndex < array_length(tokens)) {
			currentToken = tokens[currentTokenIndex];
		}
		else {
			currentToken = undefined; // End of token stream
		}
	};
	
	static peekToken = function() {
		if (currentTokenIndex + 1 < array_length(tokens)) {
			return tokens[currentTokenIndex + 1];
		}
		else {
			return undefined; // No more tokens
		}
	};
	
	static expectToken = function(expectedType, expectedValue=undefined) {
		if (currentToken.type != expectedType)
		|| (expectedValue != undefined && currentToken.value != expectedValue) {
			throw_gmlc_error($"Expected {expectedValue}, got {currentToken}");
		}
		nextToken();
	};
	
	static optionalToken = function(optionalType, optionalValue) {
		if (currentToken.type == optionalType && currentToken.value == optionalValue) {
			nextToken();
		}
	};
	
	static skipWhitespaces = function(){
		while (currentToken != undefined) {
			if (currentToken.type == __GMLC_TokenType.Whitespace)
			|| (currentToken.type == __GMLC_TokenType.Comment) {
				nextToken(); // skip whitespaces
			}
			else break;
		}
	}
	
	#region PreProcessors
	
	static parseEnumDefinition = function() {
		var enumName, memberName, _expr;
		var enumMembers = [];
		var defaultValue = 0;  // Default start value for enum members
		
		// Ensure the current token is enum
		expectToken(__GMLC_TokenType.Keyword, "enum")
		
		if (currentToken.type != __GMLC_TokenType.Identifier) {
			throw_gmlc_error($"Enum Declaration expecting Identifier, got :: {currentToken}");
		}
		
		enumName = currentToken.value;  // Next token should be the enum name
		var _enum_struct = {};
		
		nextToken(); // skip enum name
		skipWhitespaces() // such as optional line breaks
		expectToken(__GMLC_TokenType.Punctuation, "{") // Expecting a { to start the enum block
		
		optionalToken(__GMLC_TokenType.Whitespace, "\n");
		
		var _length = array_length(tokens);
		while (currentTokenIndex < _length && currentToken.value != "}") {
			skipWhitespaces();
			
			if (currentToken.type != __GMLC_TokenType.Identifier) {
				throw_gmlc_error($"Enum.Key Declaration expecting Identifier, got :: {currentToken}");
			}
			
			memberName = currentToken.value;
			array_push(enumMembers, memberName)
			nextToken(); // Move past the member name
			
			// Check for = to see if a value is assigned
			if (currentToken.value == "=") {
				nextToken(); // Move past =
				_expr = [];
				while (currentTokenIndex < _length) {
					if (currentToken.value != "," && currentToken.value != "}" && currentToken.value != "\n") {
						array_push(_expr, currentToken);
						nextToken();
					}
					else {
						break;
					}
				}
			}
			else {
				// No explicit value, use the default incremental value
				_expr = [new __GMLC_create_token(__GMLC_TokenType.Number, currentToken.name, defaultValue, currentToken.line, currentToken.column, currentToken.lineString)];
			}
			
			// Add member to the list
			_enum_struct[$ memberName] = _expr;
			
			// Increment default value for the next potential member
			defaultValue++;
			
			// Handle commas between enum members
			if (currentToken.value == ",") {
				nextToken();
			}
			
			skipWhitespaces();
			
		}
		nextToken(); // Move past }
		
		program.EnumVar[$ enumName] = _enum_struct;
		program.EnumVarNames[$ enumName] = enumMembers;
	};
	
	static parseMacroDefinition = function() {
		expectToken(__GMLC_TokenType.Operator, "#")
		expectToken(__GMLC_TokenType.Keyword, "macro")
		
		var name = currentToken.value; // Assuming next token is the macro name
		array_push(program.MacroVarNames, name);
		
		nextToken();
		
		var macroBody = parseMacroBody(); // Collect the macro body starting after the name
		program.MacroVar[$ name] = macroBody;
		
	};
	
	static parseMacroBody = function() {
		var body = [];
		var previousTokenWasEscape = false;
		var _length = array_length(tokens)
		while (currentTokenIndex < _length) {
			// Check for line break not preceded by a backslash escape
			if (currentToken.type == __GMLC_TokenType.Whitespace && currentToken.value == "\n" && !previousTokenWasEscape) {
				break;  // End of macro body
			}
			
			// Check if current token is an escape operator, and update flag
			if (currentToken.type == __GMLC_TokenType.EscapeOperator) {
				previousTokenWasEscape = true;
			}
			else if (currentToken.type == __GMLC_TokenType.Whitespace)
			|| (currentToken.type == __GMLC_TokenType.Comment)
			|| (currentToken.type == __GMLC_TokenType.Region) {
				//dont do shit
			}
			else {
				previousTokenWasEscape = false;
				array_push(body, currentToken);
			}
			
			nextToken();
		}
		
		
		return body;
	};
	
	#region Helper Functions
	
	static currentTokenIsEnum = function(_arr, _index) {
		var _currentToken = _arr[ _index];
		
		if (_index >= array_length(_arr) - 2) return false;
		if (_currentToken.type != __GMLC_TokenType.Identifier) return false;
		
		if (_index >= 1) var _previous_token = _arr[_index - 1];
		var _current_token  = _arr[_index];
		var _next_token	 = _arr[_index + 1];
		var _second_token   = _arr[_index + 2];
		
		
		//early outs
		if (_index >= 1) && (_previous_token.type == __GMLC_TokenType.Punctuation) && (_previous_token.value == ".") return false;
		if (_next_token.type != __GMLC_TokenType.Punctuation) || (_next_token.value != ".") return false;
		if (_second_token.type != __GMLC_TokenType.Identifier) return false;
		
		var _enum_struct = struct_get(enumDefinitions, _current_token.value)
		return ((_enum_struct != undefined) && struct_exists(_enum_struct, _second_token.value));
	}
	
	static checkAndReplaceMacrosAndEnums = function(_src_arr, _dest_arr, _index) {
		var _currentToken = _src_arr[_index];
		
		//early out
		if (_currentToken.type != __GMLC_TokenType.Identifier) {
			array_push(_dest_arr, _currentToken);
			return;
		}
		
		if (struct_exists(macroDefinitions, _currentToken.value)) {
			var _macro = macroDefinitions[$ _currentToken.value];
			var _i=0; repeat(array_length(_macro)) {
				var _new_token = _macro[_i];
				_new_token.line = _currentToken.line;
				_new_token.column = _currentToken.column;
				array_push(_dest_arr, _new_token);
			_i+=1;};
		}
		else if (currentTokenIsEnum(_src_arr, _index)) {
			var _second_token = _src_arr[_index+2];
			var _enum_body = enumDefinitions[$ _currentToken.value][$ _second_token.value];
			var _i=0; repeat(array_length(_enum_body)) {
				var _new_token = _enum_body[_i];
				_new_token.line = _currentToken.line;
				_new_token.column = _currentToken.column;
				array_push(_dest_arr, _new_token);
			_i+=1;};
		}
		else {
			array_push(_dest_arr, _currentToken);
		}
	}
	
	#endregion
	
	#endregion
}

#endregion
