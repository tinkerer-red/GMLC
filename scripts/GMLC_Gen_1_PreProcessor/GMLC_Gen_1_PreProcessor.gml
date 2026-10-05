#region PreProcessor.gml

function GMLC_Gen_1_PreProcessor(_env) : FlexiParseBase() constructor {
	env = _env;
	
	program = undefined;
	tokens = undefined;
	processedTokens = [];
	currentTokenIndex = 0;
	currentToken = undefined;
	finished = false;
	
	lastFiveTokens = array_create(5, undefined);
	
	
	#region Basic
	#region jsDoc
	/// @func    initialize()
	/// @desc    Initializes the parser with its input data. Executes the custom initialize function.
	///
	///          New stack is resized, and the custom initialization logic is applied.
	/// @self    ParserBase
	/// @param   {any} _input : The input data to initialize the parser with
	/// @returns {undefined}
	#endregion
	static __initialize = function(_programTokens) {

		program = _programTokens;
		tokens = _programTokens.tokens;
		processedTokens = [];
		program.tokens = processedTokens;
		currentTokenIndex = -1;
		currentToken = undefined;
		finished = false;


		__nextToken();
	};
	
	#region jsDoc
	/// @func    cleanup()
	/// @desc    Cleans up any active time source. Also executes the custom cleanup function.
	/// @self    ParserBase
	/// @returns {undefined}
	#endregion
	static __cleanup = function() {
			
	}
	
	#region jsDoc
	/// @func    isFinished()
	/// @desc    Checks if the parsing is finished.
	/// @self    ParserBase
	/// @returns {boolean}
	#endregion
	static __isFinished = function() {
		return finished;
	};
	
	#region jsDoc
	/// @func    finalize()
	/// @desc    Finalizes the parsing process. Executes the custom finalize function.
	/// @self    ParserBase
	/// @returns {any}
	#endregion
	static __finalize = function() {
		return program;
	}
	
	#endregion
		
	#region Parsing Steps
	#region jsDoc
	/// @func    nextToken()
	/// @desc    Processes the next token using the added parser steps. If errors are to be caught, they will be handled via the error handler.
	/// @self    ParserBase
	/// @returns {undefined}
	#endregion
	static __nextToken = function() {
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
			finished = true;
		}
		
		return currentToken;
	};
	
	#region jsDoc
	/// @func    peekToken()
	/// @desc    peek into the proceeding token.
	/// @self    ParserBase
	/// @returns {struct}
	#endregion
	static __peekToken = function() {
		if (currentTokenIndex + 1 < array_length(tokens)) {
			return tokens[currentTokenIndex + 1];
		}
		else {
			return undefined; // No more tokens
		}
	};
	
	#region jsDoc
	/// @func    shouldBreakParserSteps()
	/// @desc    Returns if the parser should stop iterating through the parser steps
	/// @self    ParserBase
	/// @param   {any} inputToken : The token to be parsed by the registered parser steps
	/// @param   {any} outputToken : The token produced after parsing steps
	/// @returns {bool}
	#endregion
	static __shouldBreakParserSteps = function(_output) {
		return (_output == true) || finished;
	};
		
	#region Parsers
	
	static parseWhiteSpaces = function() {
		if (currentToken.type == __GMLC_TokenType_Comment)
		{
			var _str = string_replace_all(string_replace_all(currentToken.value, "\t", ""), " ", "")
			if string_pos("@NoOp", _str)
			{
				//change the token type and mark for processing
				currentToken.type = __GMLC_TokenType_NoOpPragma;
				array_push(processedTokens, currentToken);
				__nextToken();
				return true;
			}
		}
		if (currentToken.type == __GMLC_TokenType_Whitespace)
		|| (currentToken.type == __GMLC_TokenType_Comment)
		|| (currentToken.type == __GMLC_TokenType_Region)
		{
			__nextToken();
			return true;
		}
		return false;
	}
	
	static parseMacro = function() {
		static parseMacroBody = function() {
			var body = [];
			var previousTokenWasEscape = false;
			var _length = array_length(tokens)
			
			while (currentTokenIndex < _length) {
				// Check for line break not preceded by a backslash escape
				if (currentToken.type == __GMLC_TokenType_Whitespace)
				&& (currentToken.value == "\n") {
					if (previousTokenWasEscape) {
						previousTokenWasEscape = false; //begin parsing again
					}
					else{
						break;  // End of macro body
					}
				}
				
				// Check if current token is an escape operator, and update flag
				if (currentToken.type == __GMLC_TokenType_EscapeOperator) {
					previousTokenWasEscape = true;
				}
				else if (currentToken.type == __GMLC_TokenType_Whitespace)
				|| (currentToken.type == __GMLC_TokenType_Comment)
				|| (currentToken.type == __GMLC_TokenType_Region)
				|| (previousTokenWasEscape) //specifically completely ignore everything after a `\`
				{
					//dont do shit
				}
				else {
					array_push(body, currentToken);
				}
				
				__nextToken();
			}
			
			__nextToken();
			return body;
		};
		
		if (env.isKeyword("#macro"))
		&& (optionalToken(__GMLC_TokenType_Keyword, "#macro")) {
			
			var name = currentToken.name; // Assuming next token is the macro name
			array_push(program.MacroVarNames, name);
			
			__nextToken();
			
			var macroBody = parseMacroBody(); // Collect the macro body starting after the name
			program.MacroVar[$ name] = macroBody;
			
			return true;
		}
		
		return false;
	}
	
	static parseEnum = function() {
		if (env.isKeyword("enum"))
		&& (currentToken.type == __GMLC_TokenType_Keyword)
		&& (currentToken.value == "enum")
		{
			var enumName, memberName, _expr;
			var enumMembers = [];
			// the previous member, for a member without a value (one more than it): its value when it is a plain
			// number, else its tokens
			var _prevValue = int64(-1);
			var _prevTokens = undefined;
			
			// Ensure the current token is enum
			expectToken(__GMLC_TokenType_Keyword, "enum")
			
			if (currentToken.type != __GMLC_TokenType_Identifier) {
				throw_gmlc_error($"Enum Declaration expecting Identifier, got :: {currentToken}", currentToken.line, currentToken.lineString, currentToken.column);
			}
			
			enumName = currentToken.value;  // Next token should be the enum name
			var _enum_struct = {};
			
			__nextToken(); // skip enum name
			skipWhitespaces() // such as optional line breaks
			expectToken(__GMLC_TokenType_Punctuation, "{") // Expecting a { to start the enum block
			
			optionalToken(__GMLC_TokenType_Whitespace, "\n");
			
			var _length = array_length(tokens);
			while (currentTokenIndex < _length && !(currentToken.type == __GMLC_TokenType_Punctuation && currentToken.value == "}")) {
				skipWhitespaces();
				
				
				//apparently it can be any stream of text! how fun! so keywords, unique identifiers, doesnt matter! ffs...
				if (currentToken.type != __GMLC_TokenType_Identifier)
				&& (currentToken.name != currentToken.value)
				&& (!__char_is_alphabetic(ord(string_char_at(currentToken.name, 1)))) {
					throw_gmlc_error($"Enum.Key Declaration expecting Identifier, got :: {currentToken}", currentToken.line, currentToken.lineString, currentToken.column);
				}
				
				memberName = currentToken.name;
				array_push(enumMembers, memberName)
				__nextToken(); // Move past the member name
				
				// Check for = to see if a value is assigned
				var _sourceInfo = currentToken.sourceInfo;
				if (currentToken.value == "=") {
					__nextToken(); // Move past =
					// the value runs to the `,` or `}` that ends the member; commas and braces inside brackets belong to it
					var _value_tokens = [];
					var _depth = 0;
					while (currentTokenIndex < _length) {
						var _punct = (currentToken.type == __GMLC_TokenType_Punctuation) ? currentToken.value : "";
						if (_depth == 0)
						&& (currentToken.name == "," || currentToken.value == "}" || currentToken.value == "\n") {
							break;
						}
						if (_punct == "(" || _punct == "[" || _punct == "{") _depth++;
						if (_punct == ")" || _punct == "]" || _punct == "}") _depth--;
						array_push(_value_tokens, currentToken);
						__nextToken();
					}
					
					var _literal = __enumLiteralValue(_value_tokens);
					if (_literal != undefined) {
						_prevValue = _literal;
						_prevTokens = undefined;
						_expr = [__enumNumberToken(_literal, _sourceInfo)];
					}
					else {
						// any other value: int64 of the expression where the member is used (GameMaker only accepts
						// what its compiler can evaluate; GMLC evaluates the same expressions at run time)
						_expr = __enumInt64Tokens(_value_tokens, _sourceInfo);
						_prevTokens = _expr;
					}
				}
				else if (_prevTokens == undefined) {
					// no value: one more than the previous member (0 for the first)
					_prevValue += 1;
					_expr = [__enumNumberToken(_prevValue, _sourceInfo)];
				}
				else {
					var _plus_one = [new __GMLC_create_token(__GMLC_TokenType_Punctuation, "(", "(", _sourceInfo)];
					array_copy(_plus_one, 1, _prevTokens, 0, array_length(_prevTokens));
					array_push(_plus_one,
						new __GMLC_create_token(__GMLC_TokenType_Punctuation, ")", ")", _sourceInfo),
						new __GMLC_create_token(__GMLC_TokenType_Operator, "+", "+", _sourceInfo),
						new __GMLC_create_token(__GMLC_TokenType_Number, "1", 1, _sourceInfo));
					_expr = __enumInt64Tokens(_plus_one, _sourceInfo);
					_prevTokens = _expr;
				}
				
				// Add member to the list
				_enum_struct[$ memberName] = _expr;
				
				// Handle commas between enum members
				if (currentToken.name == ",") {
					__nextToken();
				}
				
				skipWhitespaces();
				
			}
			
			expectToken(__GMLC_TokenType_Punctuation, "}")
			
			program.EnumVar[$ enumName] = _enum_struct;
			program.EnumVarNames[$ enumName] = enumMembers;
			
			//frequently people will accidently include multiple ; at the end of their line, just ignore this.
			while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}
			
			return true;
		}
		return false;
	}
	
	#region jsDoc
	/// @func    __enumLiteralValue(_tokens)
	/// @desc    Returns the int64 value of an enum member written as a plain number (optionally signed), a bool or
	///          a built-in constant, truncated as GameMaker does (`1.5` is 1, `true` is 1), or undefined for any
	///          other expression.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _tokens : The member's value tokens
	/// @returns {Int64|Undefined}
	#endregion
	static __enumLiteralValue = function(_tokens) {
		var _sign = 1;
		var _i = 0;
		if (array_length(_tokens) == 2)
		&& (_tokens[0].type == __GMLC_TokenType_Operator)
		&& (_tokens[0].value == "-" || _tokens[0].value == "+") {
			_sign = (_tokens[0].value == "-") ? -1 : 1;
			_i = 1;
		}
		if (array_length(_tokens) != _i + 1) return undefined;
		var _token = _tokens[_i];
		if (_token.type != __GMLC_TokenType_Number) return undefined;
		var _value = _token.value;
		if (!is_real(_value) && !is_int64(_value) && !is_bool(_value)) return undefined;
		return (_sign < 0) ? -int64(_value) : int64(_value);
	}
	#region jsDoc
	/// @func    __enumNumberToken(_value, _sourceInfo)
	/// @desc    Returns a Number token holding an enum member's int64 value.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Int64}  _value      : The member's value
	/// @param   {Struct} _sourceInfo : Source position of the member
	/// @returns {Struct}
	#endregion
	static __enumNumberToken = function(_value, _sourceInfo) {
		return new __GMLC_create_token(__GMLC_TokenType_Number, string(_value), _value, _sourceInfo);
	}
	#region jsDoc
	/// @func    __enumInt64Tokens(_tokens, _sourceInfo)
	/// @desc    Returns the tokens of `__gmlc_enum_value(<_tokens>)`, the int64 value of an enum member's expression.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _tokens     : The expression's tokens
	/// @param   {Struct}        _sourceInfo : Source position of the member
	/// @returns {Array<Struct>}
	#endregion
	static __enumInt64Tokens = function(_tokens, _sourceInfo) {
		var _out = [
			new __GMLC_create_token(__GMLC_TokenType_Function, "__gmlc_enum_value", method(undefined, __gmlc_enum_value), _sourceInfo),
			new __GMLC_create_token(__GMLC_TokenType_Punctuation, "(", "(", _sourceInfo),
		];
		array_copy(_out, 2, _tokens, 0, array_length(_tokens));
		array_push(_out, new __GMLC_create_token(__GMLC_TokenType_Punctuation, ")", ")", _sourceInfo));
		return _out;
	}
	
	static parseRegion = function() {
		static parseRegionTitle = function() {
			var title = "";
			var _length = array_length(tokens)
			while (currentTokenIndex < _length) {
				// Check for line break not preceded by a backslash escape
				if (currentToken.type == __GMLC_TokenType_Whitespace)
				&& (currentToken.value == "\n") {
					break;  // End of macro body
				}
				
				title += currentToken.name;
				currentToken.type = __GMLC_TokenType_Comment;
				
				__nextToken();
			}
			
			__nextToken();
			return title;
		};
		
		if (currentToken.type == __GMLC_TokenType_Keyword) {
			if (currentToken.value == "#region") {
				expectToken(__GMLC_TokenType_Keyword, "#region");
				var regionTitle = parseRegionTitle();
				return true;
			}
			if (currentToken.value == "#endregion") {
				expectToken(__GMLC_TokenType_Keyword, "#endregion");
				var regionTitle = parseRegionTitle(); //apparently endregion can also have a closer title. who knew!
				return true;
			}
		}
		
		return false;
	}
	
	static parseAcceptance = function() {
		//push everything back in
		array_push(processedTokens, currentToken);
		__nextToken();
		return true;
	}
	
	addParserStep(parseWhiteSpaces)
	addParserStep(parseMacro)
	addParserStep(parseEnum)
	addParserStep(parseRegion)
	//addParserStep(parseDefine) //this should only be active when gms1.4 support is enabled
	addParserStep(parseAcceptance)
		
	#endregion
	
	#endregion
	
	#region Helper Functions
	
	static expectToken = function(expectedType, expectedValue=undefined) {
		if (currentToken.type != expectedType)
		|| (expectedValue != undefined && currentToken.value != expectedValue) {
			throw_gmlc_error($"Expected {expectedValue}, got {currentToken}", currentToken.line, currentToken.lineString, currentToken.column);
		}
		__nextToken();
	};
	
	static optionalToken = function(optionalType, optionalValue) {
		if (currentToken == undefined) return false;
		
		if (currentToken.type == optionalType && currentToken.value == optionalValue) {
			__nextToken();
			return true;
		}
		
		return false;
	};
	
	static skipWhitespaces = function(){
		while (currentToken != undefined) {
			if (currentToken.type == __GMLC_TokenType_Whitespace)
			|| (currentToken.type == __GMLC_TokenType_Comment) {
				__nextToken(); // skip whitespaces
			}
			else break;
		}
	}
	
	#endregion
	
}

#endregion


