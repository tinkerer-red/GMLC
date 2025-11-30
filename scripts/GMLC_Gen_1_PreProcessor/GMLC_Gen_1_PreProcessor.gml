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
		currentToken = undefined; // tokens[currentTokenIndex];
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
		if (currentToken.type == __GMLC_TokenType.Comment)
		{
			var _str = string_replace_all(string_replace_all(currentToken.value, "\t", ""), " ", "")
			if string_pos("@NoOp", _str)
			{
				//change the token type and mark for processing
				currentToken.type = __GMLC_TokenType.NoOpPragma;
				array_push(processedTokens, currentToken);
				__nextToken();
				return true;
			}
		}
		if (currentToken.type == __GMLC_TokenType.Whitespace)
		|| (currentToken.type == __GMLC_TokenType.Comment)
		|| (currentToken.type == __GMLC_TokenType.Region)
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
				if (currentToken.type == __GMLC_TokenType.Whitespace)
				&& (currentToken.value == "\n") {
					if (previousTokenWasEscape) {
						previousTokenWasEscape = false; //begin parsing again
					}
					else{
						break;  // End of macro body
					}
				}
				
				// Check if current token is an escape operator, and update flag
				if (currentToken.type == __GMLC_TokenType.EscapeOperator) {
					previousTokenWasEscape = true;
				}
				else if (currentToken.type == __GMLC_TokenType.Whitespace)
				|| (currentToken.type == __GMLC_TokenType.Comment)
				|| (currentToken.type == __GMLC_TokenType.Region)
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
		
		if (currentToken.type == __GMLC_TokenType.Operator)
		&& (currentToken.value == "#")
		{
			var _next_token = __peekToken();
			if (_next_token.type == __GMLC_TokenType.Keyword)
			&& (_next_token.value == "macro")
			{
				expectToken(__GMLC_TokenType.Operator, "#")
				expectToken(__GMLC_TokenType.Keyword, "macro")
				
				var name = currentToken.value; // Assuming next token is the macro name
				array_push(program.MacroVarNames, name);
				
				__nextToken();
				
				var macroBody = parseMacroBody(); // Collect the macro body starting after the name
				program.MacroVar[$ name] = macroBody;
				
				return true;
			}
		}
		
		return false;
	}
	
	static parseEnum = function() {
		if (currentToken.type == __GMLC_TokenType.Keyword)
		&& (currentToken.value == "enum")
		{
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
			
			__nextToken(); // skip enum name
			skipWhitespaces() // such as optional line breaks
			expectToken(__GMLC_TokenType.Punctuation, "{") // Expecting a { to start the enum block
			
			optionalToken(__GMLC_TokenType.Whitespace, "\n");
			
			var _length = array_length(tokens);
			while (currentTokenIndex < _length && !(currentToken.type == __GMLC_TokenType.Punctuation && currentToken.value == "}")) {
				skipWhitespaces();
				
				if (currentToken.type != __GMLC_TokenType.Identifier) {
					throw_gmlc_error($"Enum.Key Declaration expecting Identifier, got :: {currentToken}");
				}
				
				memberName = currentToken.value;
				array_push(enumMembers, memberName)
				__nextToken(); // Move past the member name
				
				// Check for = to see if a value is assigned
				if (currentToken.value == "=") {
					__nextToken(); // Move past =
					_expr = [];
					while (currentTokenIndex < _length) {
						if (currentToken.name != "," && currentToken.value != "}" && currentToken.value != "\n") {
							array_push(_expr, currentToken);
							__nextToken();
						}
						else {
							break;
						}
					}
				}
				else {
					// No explicit value, use the default incremental value
					_expr = [new __GMLC_create_token(__GMLC_TokenType.Number, currentToken.name, int64(defaultValue), currentToken.line, currentToken.column, currentToken.byteStart, currentToken.byteEnd, currentToken.lineString)];
				}
				
				// Add member to the list
				_enum_struct[$ memberName] = _expr;
				
				// Increment default value for the next potential member
				defaultValue++;
				
				// Handle commas between enum members
				if (currentToken.name == ",") {
					__nextToken();
				}
				
				skipWhitespaces();
				
			}
			
			expectToken(__GMLC_TokenType.Punctuation, "}")
			
			program.EnumVar[$ enumName] = _enum_struct;
			program.EnumVarNames[$ enumName] = enumMembers;
			
			//frequently people will accidently include multiple ; at the end of their line, just ignore this.
			while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
			
			return true;
		}
		return false;
	}
	
	static parseRegion = function() {
		static parseRegionTitle = function() {
			var title = "";
			var _length = array_length(tokens)
			while (currentTokenIndex < _length) {
				// Check for line break not preceded by a backslash escape
				if (currentToken.type == __GMLC_TokenType.Whitespace)
				&& (currentToken.value == "\n") {
					break;  // End of macro body
				}
				
				title += currentToken.name;
				currentToken.type = __GMLC_TokenType.Comment;
				
				__nextToken();
			}
			
			__nextToken();
			return title;
		};
		
		if (currentToken.type == __GMLC_TokenType.Keyword) {
			if (currentToken.value == "#region") {
				expectToken(__GMLC_TokenType.Keyword, "#region");
				var regionTitle = parseRegionTitle();
				return true;
			}
			if (currentToken.value == "#endregion") {
				expectToken(__GMLC_TokenType.Keyword, "#endregion");
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
			throw_gmlc_error($"Expected {expectedValue}, got {currentToken}\n({currentToken.line}){currentToken.lineString}");
		}
		__nextToken();
	};
	
	static optionalToken = function(optionalType, optionalValue) {
		if (currentToken == undefined) return;
		
		if (currentToken.type == optionalType && currentToken.value == optionalValue) {
			__nextToken();
		}
	};
	
	static skipWhitespaces = function(){
		while (currentToken != undefined) {
			if (currentToken.type == __GMLC_TokenType.Whitespace)
			|| (currentToken.type == __GMLC_TokenType.Comment) {
				__nextToken(); // skip whitespaces
			}
			else break;
		}
	}
	
	#endregion
	
}

#endregion


