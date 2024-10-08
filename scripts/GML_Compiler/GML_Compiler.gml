/// @desc
/// @feather ignore all



#region ParserBase.gml
	#region ParserBase
	/*
	Purpose: The base constructor for all parsers to abide by, helps to standardize function names, and allow for easy logging, debugging, and async execution.
	
	Methods:
	
	initialize  :: initialize the parser with it's input data, this will also execute the custom initialize function supplied
	cleanup     :: cleans up any active time source, this will also execute the custom cleanup function supplied
	isFinished :: returns if the parsing is finished
	finalize    :: should not be called externally, it's called as soon as the parsing is finished, this will also execute the custom finalize function supplied
	parseAll    :: forcibly parse all, regardless of time or cpu usage.
	parseAsync  :: creates a time source which will parse passively until it's finished then execute the callback with the supplied data from your custom finalize function
	nextToken   :: this will execute your custom nextToken function with the input being the current token.

	*/
	#endregion
	function ParserBase() constructor {
		//init variables:
		
		target = undefined;
		stack = [];
		finished = false;
		
		logEnabled = false;
		
		should_catch_errors = false;
		error_handler = function(_error){ show_debug_message("[ERROR] " + instanceof(self) + " :: " + string(_error)); }
		
		async_active = false;
		async_max_time = (1/gamespeed_fps * 1_000) * (1/8) //the max time to spend parsing, default is 1/8th of a frame time.
		async_start_time = undefined;
		async_time_source = undefined;
		async_callback = undefined;
		
		#region jsDoc
		/// @func    initialize()
		/// @desc    Initializes the parser with its input data. Executes the custom initialize function.
		///
		///          New stack is resized, and the custom initialization logic is applied.
		/// @self    ParserBase
		/// @param   {any} _input : The input data to initialize the parser with
		/// @returns {undefined}
		#endregion
		static initialize = function(_input) {
			array_resize(stack, 0);
			__initialize(_input);
			currentTarget = undefined;
		};
		
		#region jsDoc
		/// @func    cleanup()
		/// @desc    Cleans up any active time source. Also executes the custom cleanup function.
		/// @self    ParserBase
		/// @returns {undefined}
		#endregion
		static cleanup = function() {
			if (async_time_source != undefined) {
				time_source_destroy(async_time_source);
			}
			__cleanup();
		}
		
		#region jsDoc
		/// @func    isFinished()
		/// @desc    Checks if the parsing is finished.
		/// @self    ParserBase
		/// @returns {boolean}
		#endregion
		static isFinished = function() {
			return __isFinished();
		}
		
		#region jsDoc
		/// @func    finalize()
		/// @desc    Finalizes the parsing process. Executes the custom finalize function.
		/// @self    ParserBase
		/// @returns {any}
		#endregion
		static finalize = function() {
			return __finalize()
		}
		
		#region jsDoc
		/// @func    parseAll()
		/// @desc    Parses all tokens in the stack regardless of CPU usage or time. Calls nextToken for every token until finished.
		/// @self    ParserBase
		/// @returns {any} : The result of the finalize function after parsing all tokens
		#endregion
		static parseAll = function() {
			while (array_length(stack)) {
				nextToken();
			}
			return finalize();
		}
		
		#region jsDoc
		/// @func    parseAsync()
		/// @desc    Asynchronously parses the tokens in the stack. Parses until it's finished or until time runs out.
		///
		///          If the parsing is completed, the callback is executed. Optionally accepts an error callback.
		/// @self    ParserBase
		/// @param   {function} _callback  : The callback to execute when parsing is complete
		/// @param   {function} [_errback] : Optional error callback to handle parsing errors
		/// @returns {any} : The time source reference for the async execution
		#endregion
		static parseAsync = function(_callback, _errback=undefined) {
			async_active = true;
			async_callback = _callback;
			error_handler  = _errback ?? error_handler;
			
			var _asyncParse = method(self, function() {
				async_start_time = current_time;
				while (current_time-async_start_time < async_max_time) {
					parseNext();
					
					if (isFinished()) {
						async_active = false;
						async_callback(finalize());
						time_source_destroy(async_time_source);
						async_time_source = undefined;
					}
				}
			})
			
			//execute the time source
			async_time_source = time_source_create(time_source_game, 1, time_source_units_frames, _asyncParse, [], -1)
			time_source_start(async_time_source)
			
			return async_time_source
		}
		
		#region jsDoc
		/// @func    nextToken()
		/// @desc    Processes the next token from the stack. If errors are to be caught, they will be handled via the error handler.
		/// @self    ParserBase
		/// @returns {undefined}
		#endregion
		static nextToken = function() {
			if (should_catch_errors) {
				try {
					__nextToken(target);
				} catch (e) {
					error_handler(e);
				}
			}
			else {
				__nextToken(target);
			}
		};
		
		#region jsDoc
		/// @func    setErrorHandler()
		/// @desc    Sets a custom error handler function to handle errors during parsing.
		/// @self    ParserBase
		/// @param   {function} _handler : The custom error handler function
		/// @returns {undefined}
		#endregion
		static setErrorHandler = function(_handler) {
			error_handler = _handler;
		}
		
		#region jsDoc
		/// @func    setAsyncMaxTime()
		/// @desc    Sets the maximum time allowed for async parsing within one frame.
		/// @self    ParserBase
		/// @param   {number} _max_time : The maximum time (in ms) allowed for async parsing
		/// @returns {undefined}
		#endregion
		static setAsyncMaxTime = function(_max_time) {
			async_max_time = _max_time;
		};
		
		#region jsDoc
		/// @func    print()
		/// @desc    Logs a message to the console if logging is enabled.
		/// @self    ParserBase
		/// @param   {string} _str : The message to log
		/// @returns {undefined}
		#endregion
		static print = function(_str) {
		    if (logEnabled) {
		        show_debug_message("[INFO] Logger :: " + _str);
		    }
		};
		
		#region jsDoc
		/// @func    setLogEnabled()
		/// @desc    Enables or disables logging for the parser.
		/// @self    ParserBase
		/// @param   {boolean} enabled : Whether logging should be enabled
		/// @returns {undefined}
		#endregion
		static setLogEnabled = function(enabled) {
		    logEnabled = enabled;
		};
		
		#region jsDoc
		/// @func    setErrorHandler()
		/// @desc    Sets whether errors should be caught during parsing and handled by the error handler.
		/// @self    ParserBase
		/// @param   {boolean} _enabled : Whether error catching should be enabled
		/// @returns {undefined}
		#endregion
		static setErrorHandler = function(_enabled) {
			should_catch_errors = _enabled;
		}
		
		#region jsDoc
		/// @func    asyncPause()
		/// @desc    Pauses the asynchronous parsing process.
		/// @self    ParserBase
		/// @returns {undefined}
		#endregion
		static asyncPause = function() {
			if (async_time_source != undefined) {
				time_source_pause(async_time_source);
				async_active = false;
			}
		};
		
		#region jsDoc
		/// @func    asyncResume()
		/// @desc    Resumes the asynchronous parsing process.
		/// @self    ParserBase
		/// @returns {undefined}
		#endregion
		static asyncResume = function() {
			if (async_time_source != undefined) {
				time_source_start(async_time_source);
				async_active = true;
			}
		};
		
		#region jsDoc
		/// @func    asyncCancel()
		/// @desc    Cancels the asynchronous parsing process and destroys the active time source.
		/// @self    ParserBase
		/// @returns {undefined}
		#endregion
		static asyncCancel = function() {
			if (async_time_source != undefined) {
				time_source_destroy(async_time_source);
				async_time_source = undefined;
				async_active = false;
			}
		};
		
		#region jsDoc
		/// @func    setCustomInitialize()
		/// @desc    Sets the custom initialize function to be used by the parser.
		/// @self    ParserBase
		/// @param   {function} _func : The custom initialization function
		/// @returns {undefined}
		#endregion
		static setCustomInitialize = function(_func) {
			__initialize = _func;
		}
		
		#region jsDoc
		/// @func    setCustomCleanup()
		/// @desc    Sets the custom cleanup function to be used by the parser.
		/// @self    ParserBase
		/// @param   {function} _func : The custom cleanup function
		/// @returns {undefined}
		#endregion
		static setCustomCleanup = function(_func) {
			__cleanup = _func;
		}
		
		#region jsDoc
		/// @func    setCustomFinalize()
		/// @desc    Sets the custom finalize function to be used by the parser.
		/// @self    ParserBase
		/// @param   {function} _func : The custom finalize function
		/// @returns {undefined}
		#endregion
		static setCustomFinalize = function(_func) {
			__finalize = _func;
		}
		
		#region jsDoc
		/// @func    setCustomIsFinished()
		/// @desc    Sets the custom isFinished function to check if parsing is completed.
		/// @self    ParserBase
		/// @param   {function} _func : The custom isFinished function
		/// @returns {undefined}
		#endregion
		static setCustomIsFinished = function(_func) {
			__isFinished = _func;
		}
		
		#region jsDoc
		/// @func    setCustomNextToken()
		/// @desc    Sets the custom nextToken function to process tokens in the stack.
		/// @self    ParserBase
		/// @param   {function} _func : The custom nextToken function
		/// @returns {undefined}
		#endregion
		static setCustomNextToken = function(_func) {
			__nextToken = _func;
		}
	}
#endregion





#macro GML_COMPILER_GM1_4 false
/* allows for
// #define
// multiline strings with out @ accessor
// single quote strings example
// hashtags in strings represent newlines
// array 2d `arr[x, y]`
*/

#macro GML_COMPILER_DEBUG false


#region Tokenizer.gml
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
function GML_Tokenizer() constructor {
	sourceCodeString = "";
	sourceCodeCharLength = 0;
	sourceCodeByteLength = 0;
	sourceCodeBuffer = undefined;
	sourceCodeLineArray = undefined;
	
	charPos = 0;
	bytePos = 0;
	
	currentCharCode = undefined;
	currentChar = undefined;
	
	tokens = undefined;
	program = undefined;
	
	line = 1;
	column = 0;
	
	finished = false;
	
	templateStringDepth = 0;
	
	keywords = ["globalvar", "var", "if", "then", "else", "begin", "end", "for", "while", "do", "until", "repeat", "switch", "case", "default", "break", "continue", "with", "exit", "return", "global", "mod", "div", "not", "and", "or", "xor", "enum", "function", "new", "constructor", "static", "region", "endregion", "macro", "try", "catch", "finally", "define", "throw"];
	
	// Initialize tokenizer with source code
	static initialize = function(_sourceCode) {
		sourceCodeString = _sourceCode;
		sourceCodeCharLength = string_length(sourceCodeString);
		tokens = [];
		program = new __GMLC_ProgramTokens(tokens);
		
		sourceCodeLineArray = string_split(string_replace_all(_sourceCode, "\r", ""), "\n");
		
		sourceCodeByteLength = string_byte_length(sourceCodeString);
		charPos = 0;
		bytePos = 0;
		
		if (sourceCodeBuffer != undefined && buffer_exists(sourceCodeBuffer)) { buffer_delete(sourceCodeBuffer); };
		sourceCodeBuffer = buffer_create(sourceCodeByteLength, buffer_fixed, 1);
	    buffer_write(sourceCodeBuffer, buffer_text, sourceCodeString);
		buffer_seek(sourceCodeBuffer, buffer_seek_start, 0);
		
		//init the charPos, bytePos, and currentCharCode
		__nextUTF8();
		
		line = 1;
		column = 1;
		
		finished = false;
	};
	
	static cleanup = function() {
		if (sourceCodeBuffer != undefined && buffer_exists(sourceCodeBuffer)) { buffer_delete(sourceCodeBuffer); };
	}
	
	static parseAll = function() {
		//reset incase a user ran this while half way through a coroutine compile
		initialize(sourceCodeString);
		
		while (!finished) {
			parseNext()
		}
		
		return program;
	}
	
	static parseNext = function() {
		var _token = detectToken();
		if (_token != undefined) {
			array_push(tokens, _token);
			
			if (GML_COMPILER_DEBUG) {
				static __lastString = ""
				var _str = string(charPos/sourceCodeCharLength/10)
				if (__lastString != _str) {
					do_trace($"{real(_str)*1000}% Finished")
					__lastString = _str;
				}
			}
		}
		
	};
	
	static skipWhitespace = function() {
		var _char = currentCharCode;
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		while (currentCharCode != undefined) {
			if (currentCharCode == ord("\n")) {
				var _token = new __GMLC_create_token(__GMLC_TokenType.Whitespace, "\n", "\n", line, column);
				__nextUTF8();
				return _token;
			}
			
			if (__char_is_whitespace(currentCharCode)) {
				__nextUTF8();
			}
			else {
				break;
			}
		}
		return undefined;
	};
	
	static detectToken = function() {
		//skip white spaces
		var _token = skipWhitespace();
		if (_token != undefined) {
			return _token;
		}
		
		//if the whitespace was the end of the token stream
		if (currentCharCode == undefined) {
			finished = true;
			return undefined; // No more tokens
		}
		
		var _char = currentCharCode;
		//var _debug_char = chr(_char);
		
		//we dont need the next char most of the time so this cuts out about 95% of the time we needed it
		if (_char == ord("/"))
		|| (_char == ord("$"))
		|| (_char == ord("0"))
		|| (_char == ord("."))
		|| (_char == ord("@")) {
			var _next_char = __peekUTF8() ?? 0;
		}
		
		//comments
		if (_char == ord("/") && _next_char == ord("/")) {
			return tokenizeCommentLine();
		}
		//comment blocks
		else if (_char == ord("/") && _next_char == ord("*")) {
			return tokenizeCommentBlock();
		}
		//string literals "example"
		else if (_char == ord(@'"')) {
			return tokenizeStringLiteral();
		}
		//hex numbers
		else if (_char == ord("$") && __char_is_hex(_next_char)) || (_char == ord("0") && _next_char == ord("x")) {
			return tokenizeHexNumber();
		}
		//string templates
		else if (_char == ord("$") && _next_char == ord(@'"')) {
			return tokenizeTemplateString(false);
		}
		else if (templateStringDepth > 0 && _char == ord(@'}')) {
			return tokenizeTemplateString(true);
		}
		//binary numbers
		else if (_char == ord("0") && _next_char == ord("b")) {
			return tokenizeBinaryNumber();
		}
		//numbers
		else if (__char_is_digit(_char)) || (_char == ord(".") && __char_is_digit(_next_char)) {
			return tokenizeNumber();
		}
		//identifiers
		else if (__char_is_alphabetic(_char)) {
			return tokenizeIdentifier();
		}
		//string literals @'example'
		else if (_char == ord("@") && (_next_char == ord("") || _next_char == ord(@'"'))) {
			return tokenizeRawStringLiteral();
		}
		//operators
		else if (__char_is_operator(_char)) {
			return tokenizeOperator();
		}
		//punctuation
		else if (__char_is_punctuation(_char)) {
			return tokenizePunctuation();
		}
		//escape char and macro new lines
		else if (_char == ord("\\")) {
			//this is really only ever used for use with macros as everything else is accounted for with strings, apart from that there is no other time a `\` should exist outside a string.
			var _token = new __GMLC_create_token(__GMLC_TokenType.EscapeOperator, "\\", "\\", line, column);
			__nextUTF8();
			return _token;
		}
		
		return tokenizeIllegal();
		
	};
	
	#region Token Creators
	
	static tokenizeNumber = function() {
		var hasDecimal = false;
		var _char = currentCharCode;
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		var _num_string = ""
		while (currentCharCode != undefined)
		&& (__char_is_digit(currentCharCode) || currentCharCode == ord(".") || currentCharCode == ord("_")) {
			if (currentCharCode == ord(".")) {
				if (hasDecimal) break; // Prevent multiple decimals
				hasDecimal = true;
			}
			_num_string += chr(currentCharCode);
			__nextUTF8();
		}
		
		var _str = real(string_replace_all(_num_string, "_", ""));
		var _number = real(_str);
		if (_number > 2147483647 || _number < -2147483648) _number = int64(_number);
		
		
		_number = (_number <= $FFFFFFF) ? real(_number) : int64(_number);
		
		var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _num_string, _number, _start_line, _start_column);
		
		return _token;
	};
	
	static tokenizeHexNumber = function() {
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		if (currentCharCode == ord("$")) {
			__nextUTF8();
			var _raw_string = "$"
		}
		else if (currentCharCode == ord("0")) {
			__nextUTF8(); // 0x
			__nextUTF8();
			var _raw_string = "0x"
		}
		else {
			throw_gmlc_error($"Entered tokenizeHexNumber with a non-valid entry string : {chr(currentCharCode)}")
		}
		
		var _len = 0;
		//var _hex_value = 0;
		while (currentCharCode != undefined && __char_is_hex(currentCharCode)) {
			//_hex_value = _hex_value << 4;
			
			if (currentCharCode >= ord("0") && currentCharCode <= ord("9")) {
				//_hex_value += currentCharCode - ord("0");
				_len += 1;
			}
			else if (currentCharCode >= ord("A") && currentCharCode <= ord("F")) {
				//_hex_value += currentCharCode - ord("A") + 10;
				_len += 1;
			}
			else if (currentCharCode >= ord("a") && currentCharCode <= ord("f")) {
				//_hex_value += currentCharCode - ord("a") + 10;
				_len += 1;
			}
			
			_raw_string += chr(currentCharCode);
			__nextUTF8();
		}
		
		#region Error Handling
		if (_len > 16) {
			var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {_start_line} : Hex number {_raw_string} is too large or too small :: input length == {_len}";
			var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column);
			return _token;
		}
		
		//if (_hex_value < 0) {
		//	var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {_start_line} : Hex number {_raw_string} is too large or too small :: hex value == {_hex_value}";
		//	var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column);
		//	return _token;
		//}
		#endregion
		var _str = string_replace(_raw_string, "$", "0x")
		_str = string_replace_all(_str, "_", "")
		var _hex_value = real(_str);
		if (_hex_value > 2147483647 || _hex_value < -2147483648) _hex_value = int64(_hex_value);
		
		var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _raw_string, _hex_value, _start_line, _start_column);
		return _token;
	};
	
	static tokenizeBinaryNumber = function() {
		var _char = currentCharCode;
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		if (currentCharCode == ord("0")) {
			__expectUTF8(ord("0"));
			__expectUTF8(ord("b"));
			var _raw_string = "0b";
		}
		else {
			throw_gmlc_error($"Entered tokenizeBinaryNumber with a non-valid entry string : {chr(_char)}")
		}
		
		var _len = 0;
		while (currentCharCode != undefined && __char_is_binary(currentCharCode)) {
			//_binary_value = _binary_value << 1;
			
			//_binary_value += currentCharCode - ord("0");
			
			_len += 1;
			_raw_string += chr(currentCharCode);
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
		if (_binary_value > 2147483647 || _binary_value < -2147483648) _binary_value = int64(_binary_value);
		
		var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _raw_string, _binary_value, _start_line, _start_column);
		return _token;
	};
	
	static tokenizeIdentifier = function() {
		var _char = currentCharCode;
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		var _raw_string = "";
		while (currentCharCode != undefined && __char_is_alphanumeric(currentCharCode)) {
			_raw_string += chr(currentCharCode);
			__nextUTF8();
		}
		
		var _identifier = _raw_string
		
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
			return _token;
		}	
		#endregion
		#region Functions
		
		if (_type == asset_script) && (_index > -1) {
			var _token = new __GMLC_create_token(__GMLC_TokenType.Function, _identifier, _index, _start_line, _start_column);
			return _token;
		}
		//built in functions
		static __functions_lookup = __ExistingFunctions();
		var _index = struct_get(__functions_lookup, _identifier)
		if (_index != undefined) {
			var _token = new __GMLC_create_token(__GMLC_TokenType.Function, _identifier, _index, _start_line, _start_column);
			return _token;
		}
		
		static __dep_functions_lookup = __DeprocatedFunctions();
		var _index = struct_get(__dep_functions_lookup, _identifier)
		if (_index != undefined) {
			var _token = new __GMLC_create_token(__GMLC_TokenType.Function, _identifier, _index, _start_line, _start_column);
			return _token;
		}
		
		#endregion
		#region Constants
		
		
		static __constants_lookup = __ExistingConstants();
		var _constant = struct_get(__constants_lookup, _identifier)
		if (_constant != undefined) {
			var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _identifier, _constant, _start_line, _start_column);
			return _token;
		}
		
		static __dep_constants_lookup = __DeprocatedConstants();
		var _constant = struct_get(__dep_constants_lookup, _identifier)
		if (_constant != undefined) {
			var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _identifier, _constant, _start_line, _start_column);
			return _token;
		}
		
		static __unique_variables_arr = __ExistingUniqueVariables();
		if (array_contains(__unique_variables_arr, _identifier)) {
			var _token = new __GMLC_create_token(__GMLC_TokenType.UniqueVariable, _identifier, _identifier, _start_line, _start_column);
			return _token;
		}
		
		#endregion
		#region Enum Constants
		
		static __enum_header_arr = __ExistingEnumerationHeaderStrings();
		if (array_contains(__enum_header_arr, _identifier)) {
			
			static __enum_arr = __ExistingEnumerationStrings();
			
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
			var _i=0; repeat(_peek_length) {
				_temp_identifier += chr(__peekUTF8(_i));
			_i++}
			
			//iterate through all and try to find a match
			var _i=0; repeat(_iterations) {
				_temp_identifier += chr(__peekUTF8(_peek_length+_i));
				
				if (array_contains(__enum_arr, _temp_identifier)) {
					static __enum_lookup = __ExistingEnumerations();
					var _val = struct_get(__enum_lookup, _temp_identifier)
					
					var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _temp_identifier, _val, _start_line, _start_column);
					_found = true;
					break;
				}
				
			_i+=1;}//end repeat loop
			
			if (_found) {
				var _jump = string_length(_temp_identifier) - string_length(_identifier);
				repeat (_jump) __nextUTF8();
				return _token;
			}
		}
		
		#endregion
		#region Keywords
		
		if (array_contains(keywords, _identifier)) {
			switch (_identifier) {
				case "begin":{
					var _token = new __GMLC_create_token(__GMLC_TokenType.Punctuation, _identifier, "{", _start_line, _start_column);
					
					return _token;
				break;}
				case "end":{
					var _token = new __GMLC_create_token(__GMLC_TokenType.Punctuation, _identifier, "}", _start_line, _start_column);
					
					return _token;
				break;}
				case "mod":{
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "mod", _start_line, _start_column);
					
					return _token;
				break;}
				case "div":{
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "div", _start_line, _start_column);
					
					return _token;
				break;}
				case "not":{
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "!", _start_line, _start_column);
					
					return _token;
				break;}
				case "and":{
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "&&", _start_line, _start_column);
					
					return _token;
				break;}
				case "or":{
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "||", _start_line, _start_column);
					
					return _token;
				break;}
				case "xor":{
					var _token = new __GMLC_create_token(__GMLC_TokenType.Operator, _identifier, "^^", _start_line, _start_column);
					
					return _token;
				break;}
			}
			
			var _token = new __GMLC_create_token(__GMLC_TokenType.Keyword, _identifier, _identifier, _start_line, _start_column);
			
			return _token;
		}
		
		#endregion
		
		if (_identifier == "true")           return new __GMLC_create_token(__GMLC_TokenType.Number, "true", true, _start_line, _start_column);
		else if (_identifier == "false")     return new __GMLC_create_token(__GMLC_TokenType.Number, "false", false, _start_line, _start_column);
		else if (_identifier == "infinity")  return new __GMLC_create_token(__GMLC_TokenType.Number, "infinity", infinity, _start_line, _start_column);
		else if (_identifier == "undefined") return new __GMLC_create_token(__GMLC_TokenType.Number, "undefined", undefined, _start_line, _start_column);
		else if (_identifier == "NaN")       return new __GMLC_create_token(__GMLC_TokenType.Number, "NaN", NaN, _start_line, _start_column);
		
		var _token = new __GMLC_create_token(__GMLC_TokenType.Identifier, _identifier, _identifier, _start_line, _start_column);
		return _token;
		//*/
	};
	
	static tokenizeOperator = function() {
		var _char = currentCharCode;
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		var start = charPos;
		
		var _op_string = "";
		
		switch (currentCharCode) {
			case ord("!"): { // !
				_op_string += chr(currentCharCode);
				__nextUTF8();
				switch (currentCharCode) {
					case ord("="): { // !=
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
				}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("#"): { // #
				_op_string += chr(currentCharCode);
				__nextUTF8();
				//switch (currentCharCode) {
				//	case ord("EMPTY"): {
						
				//	break;}
				//}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("$"): { // $
				_op_string += chr(currentCharCode);
				__nextUTF8();
				//switch (currentCharCode) {
				//	case ord("EMPTY"): {
						
				//	break;}
				//}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("%"): { // %
				_op_string += chr(currentCharCode);
				__nextUTF8();
				//switch (currentCharCode) {
				//	case ord("EMPTY"): {
						
				//	break;}
				//}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, "mod", _start_line, _start_column);
			break;};
			case ord("&"): { // &
				_op_string += chr(currentCharCode);
				__nextUTF8();
				switch (currentCharCode) {
					case ord("&"): { // &&
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
					case ord("="): { // &=
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
				}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("*"): { // *
				_op_string += chr(currentCharCode);
				__nextUTF8();
				switch (currentCharCode) {
					case ord("="): { // *=
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
				}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("+"): { // +
				_op_string += chr(currentCharCode);
				__nextUTF8();
				switch (currentCharCode) {
					case ord("="): { // +=
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
					case ord("+"): { // ++
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
				}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("-"): { // -
				_op_string += chr(currentCharCode);
				__nextUTF8();
				switch (currentCharCode) {
					case ord("="): { // -=
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
					case ord("-"): { // --
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
				}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("/"): { // /
				_op_string += chr(currentCharCode);
				__nextUTF8();
				switch (currentCharCode) {
					case ord("="): {
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
				}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("<"): { // <
				_op_string += chr(currentCharCode);
				__nextUTF8();
				switch (currentCharCode) {
					case ord(">"): { // <> AKA: !=
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, "!=", _start_line, _start_column);
					break;}
					case ord("="): { // <=
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
					case ord("<"): { // <<
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
				}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("="): { // =
				_op_string += chr(currentCharCode);
				__nextUTF8();
				switch (currentCharCode) {
					case ord("="): {
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
				}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord(">"): { // >
				_op_string += chr(currentCharCode);
				__nextUTF8();
				switch (currentCharCode) {
					case ord("="): {
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
					case ord(">"): {
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
				}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("?"): { // ?
				_op_string += chr(currentCharCode);
				__nextUTF8();
				switch (currentCharCode) {
					case ord("?"): { // ??
						_op_string += chr(currentCharCode);
						__nextUTF8();
						switch (currentCharCode) {
							case ord("="): { // ??=
								_op_string += chr(currentCharCode);
								__nextUTF8();
								return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
							break;}
						}
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
					break;}
				}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("@"): { // @
				_op_string += chr(currentCharCode);
				__nextUTF8();
				//switch (currentCharCode) {
				//	case ord("EMPTY"): {
						
				//	break;}
				//}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("^"): { // ^
				_op_string += chr(currentCharCode);
				__nextUTF8();
				switch (currentCharCode) {
					case ord("^"): { // ^^
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
					case ord("="): { // ^=
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
				}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("~"): { // ~
				_op_string += chr(currentCharCode);
				__nextUTF8();
				//switch (currentCharCode) {
				//	case ord("EMPTY"): {
						
				//	break;}
				//}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			case ord("|"): { // |
				_op_string += chr(currentCharCode);
				__nextUTF8();
				switch (currentCharCode) {
					case ord("|"): { // ||
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
					case ord("="): { // |=
						_op_string += chr(currentCharCode);
						__nextUTF8();
						return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);
					break;}
				}
				return new __GMLC_create_token(__GMLC_TokenType.Operator, _op_string, _op_string, _start_line, _start_column);	
			break;};
			default: {
				throw_gmlc_error($"Entered tokenizeOperator with a non-valid entry string : {chr(currentCharCode)}")
			break;}
		}
		
	};
	
	static tokenizePunctuation = function() {
		var _char = currentCharCode;
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		var _punctuation = chr(currentCharCode);
		__nextUTF8();
		return new __GMLC_create_token(__GMLC_TokenType.Punctuation, _punctuation, _punctuation, _start_line, _start_column);
	}
	
	static tokenizeStringLiteral = function() {
		var _char = currentCharCode;
		var _start_pos = charPos;
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
							//__nextUTF8();
						break;}
						case ord(@'"'): { // \"
							_char = "\"";
							//__nextUTF8();
						break;}
						case ord(@'n'): { // \n
							_char = "\n";
							//__nextUTF8();
						break;}
						case ord(@'r'): { // \r
							_char = "\r";
							//__nextUTF8();
						break;}
						case ord(@'t'): { // \t
							_char = "\t";
							//__nextUTF8();
						break;}
						case ord(@'f'): { // \f
							_char = "\f";
							//__nextUTF8();
						break;}
						case ord(@'v'): { // \v
							_char = "\v";
							//__nextUTF8();
						break;}
						case ord(@'b'): { // \b
							_char = "\b";
							//__nextUTF8();
						break;}
						case ord(@'0'): { // \0
							_char = "\0";
							//__nextUTF8();
							if (currentCharCode == ord("0") && __peekUTF8() == ord("0")) { // \000
								__nextUTF8();
								__nextUTF8();
								_char = "\000"
							}
						break;}
						case ord(@'u'): { // \v
							_char = "0x";
							__nextUTF8();
							
							var _len = 0;
							while (currentCharCode != undefined && __char_is_hex(currentCharCode) && (_len <= 5)) {
								if (currentCharCode >= ord("0") && currentCharCode <= ord("9")) {
									_len += 1;
								}
								else if (currentCharCode >= ord("A") && currentCharCode <= ord("F")) {
									_len += 1;
								}
								else if (currentCharCode >= ord("a") && currentCharCode <= ord("f")) {
									_len += 1;
								}
								
								_char += chr(currentCharCode);
								
								//if the next char is not hex back out
								if (!__char_is_hex(__peekUTF8())) break;
								
								
								__nextUTF8();
							}
							
							_char = chr(real(_char))
							log(_char)
							
						break;}
						default: {
							_char = "";
						break;}
					}
				break;}
				case ord(@'"'): { // "
					_raw_string += "\"";
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
			
			__nextUTF8();
			
			if (_string_closed || _should_break) break;
		}
		
		if (!_string_closed) {
			var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {_start_line} : Error parsing string literal - found newline within string";
			var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column);
			return _token;
		}
		
		var _token = new __GMLC_create_token(__GMLC_TokenType.String, _raw_string, _string, _start_line, _start_column);
		return _token;
	};
	
	static tokenizeRawStringLiteral = function() {
		var _char = currentCharCode;
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		__expectUTF8(ord("@")); //consume @
		
		var _start_quote = currentCharCode;
		
		__nextUTF8(); // consume starting quote
		
		var _raw_string = "@"+chr(_start_quote);//add the starting quote
		var _string = __fetchAllUntil(_start_quote);
		_raw_string += _string+chr(currentCharCode) // add the closing quote
		__expectUTF8(_start_quote); // consume ending quote
		
		var _token = new __GMLC_create_token(__GMLC_TokenType.String, _raw_string, _string, _start_line, _start_column);
		return _token;
	};
	
	static tokenizeTemplateString = function(_suffix=false) {
		// _suffix is used to state that we are attempting to close an already open template string
		
		var _char = currentCharCode;
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
						case ord(@'{'): { // \\
							_char = "{";
							//__nextUTF8();
						break;}
						case ord(@'\'): { // \\
							_char = "\\";
							//__nextUTF8();
						break;}
						case ord(@'"'): { // \"
							_char = "\"";
							//__nextUTF8();
						break;}
						case ord(@'n'): { // \n
							_char = "\n";
							//__nextUTF8();
						break;}
						case ord(@'r'): { // \r
							_char = "\r";
							//__nextUTF8();
						break;}
						case ord(@'t'): { // \t
							_char = "\t";
							//__nextUTF8();
						break;}
						case ord(@'f'): { // \f
							_char = "\f";
							//__nextUTF8();
						break;}
						case ord(@'v'): { // \v
							_char = "\v";
							//__nextUTF8();
						break;}
						case ord(@'b'): { // \b
							_char = "\b";
							//__nextUTF8();
						break;}
						case ord(@'0'): { // \0
							_char = "\0";
							//__nextUTF8();
							if (currentCharCode == ord("0") && __peekUTF8() == ord("0")) { // \000
								__nextUTF8();
								__nextUTF8();
								_char = "\000"
							}
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
			
			__nextUTF8();
			
			if (_string_closed || _should_break) break;
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
	
	static tokenizeCommentLine = function() {
		var _char = currentCharCode;
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		__expectUTF8(ord("/")); //consume first /
		__expectUTF8(ord("/")); //consume second /
		var _raw_string = "//";
		//var _string = "";
		while (currentCharCode != undefined && currentCharCode != ord("\n") && currentCharCode != ord("\r")) {
			_raw_string += chr(currentCharCode);
			//_string += chr(currentCharCode);
			__nextUTF8();
		}
		
		//if (currentCharCode != undefined) {
		//	__expectUTF8(ord("\n")); //consume \n
		//}
		
		var _token = new __GMLC_create_token(__GMLC_TokenType.Comment, _raw_string, _raw_string, _start_line, _start_column);
		
		return _token;
	};
	
	static tokenizeCommentBlock = function() {
		var _char = currentCharCode;
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		__expectUTF8(ord("/")); //consume /
		__expectUTF8(ord("*")); //consume *
		var _raw_string = "/*";
		//var _string = "";
		
		while (currentCharCode != undefined && !(currentCharCode == ord("*") && __peekUTF8() == ord("/"))) {
			_raw_string += chr(currentCharCode);
			//_string += chr(currentCharCode);
			__nextUTF8();
		}
		
		__expectUTF8(ord("*")); //consume *
		__expectUTF8(ord("/")); //consume /
		
		_raw_string += "*/";
		
		var _token = new __GMLC_create_token(__GMLC_TokenType.Comment, _raw_string, _raw_string, _start_line, _start_column);
		return _token;
	};
	
	static tokenizeIllegal = function() {
		var _char = currentCharCode;
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		var illegalChar = chr(currentCharCode);
		var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {_start_line} : invalid token {illegalChar}";
		var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, illegalChar, _error, _start_line, _start_column);
		__nextUTF8();
		return _token;
	};
	
	#endregion
	
}
#region Buffer Accessors

function __nextUTF8() {
	gml_pragma("forceinline");
	if (charPos >= sourceCodeCharLength) {
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
		
	return currentCharCode;
}
	
function __peekUTF8(_look_ahead=1) {
	gml_pragma("forceinline");
	if (charPos > sourceCodeCharLength-1) return undefined;
		
	var _prev_charCode = currentCharCode;
	var _prev_charPos  = charPos;
	var _prev_bytePos  = bytePos;
	var _prev_line     = line;
	var _prev_column   = column;
		
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
		
	return _nextCharCode;
}
	
function __expectUTF8(_ord) {
	gml_pragma("forceinline");
	if is_string(_ord) {
		throw_gmlc_error("please use character code instead of a string")
	}
		
	if (currentCharCode != _ord) {
		throw_gmlc_error($"Expected {_ord} ({chr(_ord)}), got {currentCharCode} ({chr(currentCharCode)})");
	}
		
	__nextUTF8();
}
	
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
#endregion

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

#region Parser.gml
	
	#region 2. Parser Module
	/*
	Purpose: To take tokens from the Tokenizer and build an Abstract Syntax Tree (AST) that represents the program structure.
	
	Methods:
	
	parse(tokens): Convert a list of tokens into an AST.
	parseExpression(tokens): Parse an expression from tokens.
	parseStatement(tokens): Parse a statement from tokens.
	*/
	#endregion
	function GML_Parser() constructor {
		finished = false;
		tokens = undefined;
		currentTokenIndex = 0;
		currentToken = undefined;
		currentFunction = undefined;
		scriptAST = undefined;
		
		lastFiveTokens = array_create(5, undefined);
		
		static initialize = function(_program) {
			finished = false;
			
			scriptAST = new ASTScript();
			currentScript = scriptAST;
			
			program = _program;
			tokens = _program.tokens;
			
			//apply the variable names and token streams from program to ast
			scriptAST.MacroVar      = program.MacroVar;
			scriptAST.MacroVarNames = program.MacroVarNames;
			
			scriptAST.EnumVar      = program.EnumVar;
			scriptAST.EnumVarNames = program.EnumVarNames;
			
			scriptAST.GlobalVar      = program.GlobalVar;
			scriptAST.GlobalVarNames = program.GlobalVarNames;
			
			// Note this function isnt actually async, so if there is a module with tons of lines of code its possible for this to cause lag.
			// For development i just said fuck it though.
			replaceAllMacrosAndEnums(_program.tokens);
			
			currentTokenIndex = 0;
			currentToken = tokens[currentTokenIndex];
			currentFunction = undefined;
			
			operatorStack = []; // Stack for operators
			operandStack = []; // Stack for operands (AST nodes)
			
			replaceAllMacrosAndEnums();
		};
		
		static cleanup = function() {
			// i mean idk, what do you wanna do?
		}
		
		static parseAll = function() {
			while (!finished) {
				parseNext();
			}
			
			return scriptAST;
		};
		
		static parseNext = function() {
			if (currentToken != undefined) {
				while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
				
				var statement = parseStatement();
				if (statement) {
					array_push(scriptAST.statements.statements, statement);
				}
				
				if (GML_COMPILER_DEBUG) {
					static __lastString = ""
					var _str = string(currentTokenIndex/array_length(tokens)/10)
					if (__lastString != _str) {
						do_trace($"{real(_str)*1000}% Finished")
						__lastString = _str;
					}
				}
			}
			else {
				finished = true;
			}
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
		
		static replaceAllMacrosAndEnums = function(_tokens) {
			var _loop_count = 0;
			var _hasChanged = true;
			while (_hasChanged) { //recursively ensure all macros and enums have been applied
				_hasChanged = false;
				for (var _i = 0; _i < array_length(_tokens); _i++) {
					var _token = _tokens[_i];
				
					if (_token.type == __GMLC_TokenType.Identifier) {
					
						var _scopeType = __find_ScopeType_from_string(_token.value);
					
						if (_scopeType == ScopeType.MACRO) {
							
							var _macroTokens = currentScript.MacroVar[$ _token.value];
							
							array_delete(_tokens, _i, 1); //remove the macro from the token array
							array_insert_ext(_tokens, _i, _macroTokens); //insert the macro definition into the token array
							
							_hasChanged = true;
						}
					
						if (_scopeType == ScopeType.ENUM) {
							var _header = _token.value;
							
							if (_i < array_length(_tokens)-2)
							&& (_tokens[_i+1].type == __GMLC_TokenType.Punctuation)
							&& (_tokens[_i+1].value == ".")
							&& (_tokens[_i+2].type == __GMLC_TokenType.Identifier) {
								
								var _member = _tokens[_i+2].value;
								var _enumTokens = currentScript.EnumVar[$ _header][$ _member];
								
								array_delete(_tokens, _i, 3); //remove the enum from the token array
								array_insert_ext(_tokens, _i, _enumTokens); //insert the enum definition into the token array
								
								_hasChanged = true;
							}
						}
					
					}
				}
				_loop_count++
				if (_loop_count > 1000) {
					throw_gmlc_error($"Recursive Macro or Enum Declaration detected! Quitting")
				}
			}
		}
		
		#region AST Builder Methods
		
		static parseStatement = function() {
			switch (currentToken.value) {
				case "if":			return parseIfStatement();
				case "for":			return parseForStatement();
				case "while":		return parseWhileStatement();
				case "do":			return parseDoUntilStatement();  // Note: Adjust this if the actual keyword differs
				case "switch":		return parseSwitchStatement();
				case "with":		return parseWithStatement();
				case "repeat":		return parseRepeatStatement();
				case "try":			return parseTryCatchStatement();
				case "throw":		return parseThrowExpression();
				case "function":	parseFunctionDeclaration() return undefined;
				case "#define":		parseDefineFunctionDeclaration() return undefined;
				//case "let":			//
				case "var":			//
				case "static":		//
				case "globalvar":	return parseVariableDeclaration();
				case "continue":	return parseContinueStatement();
				case "break":		return parseBreakStatement();
				case "exit":		return parseExitStatement();
				case "return":		return parseReturnStatement();
				case "#macro":		return parseReturnStatement();
				case "enum":		return parseReturnStatement();
				case "{":			return parseBlock();
				default:			return parseExpressionStatement();  // Assume any other token starts an expression statement
			}
		};
		
		static parseBlock = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			if (currentToken.value == "{") {
				nextToken(); // Consume the {
				var _statements = [];
				while (currentToken != undefined && currentToken.value != "}") {
					var _statement = parseStatement();
					
					if (_statement != undefined) {
						array_push(_statements, _statement);
					}
					
					//consume optional `;`
					optionalToken(__GMLC_TokenType.Punctuation, ";")
					
					// Parse each statement until } is found
					// Optional: Handle error checking for unexpected end of file
				}
				nextToken(); // Consume the }
				
				//compile better code
				if (array_length(_statements) == 1) {
					return _statements[0];
				}
				
				return new ASTBlockStatement(_statements, line, lineString); // Return a block statement containing all parsed statements
			}
			else {
				// If no {, its a single statement block
				var singleStatement = parseStatement();
				return new ASTBlockStatement([singleStatement], line, lineString);
			}
		};
		
		#region Statements
		#region Keyword Statement types
		
		static parseIfStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is if
			nextToken(); // Move past if
			var _condition = parseConditionalExpression();
			optionalToken(__GMLC_TokenType.Keyword, "then")
			var _codeBlock = parseBlock();
			var _elseBlock = undefined;
			
			
			
			if (currentToken != undefined)
			&& (currentToken.value == "else") {
				nextToken(); // Consume else
				_elseBlock = parseBlock();
			}
			return new ASTIfStatement(_condition, _codeBlock, _elseBlock, line, lineString);
		};
		
		static parseForStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Move past for
			expectToken(__GMLC_TokenType.Punctuation, "(");
			
			if (currentToken.value == "var") {
				var _initialization = parseVariableDeclaration();
			}
			else {
				var _initialization = parseExpression();
			}
			optionalToken(__GMLC_TokenType.Punctuation, ";"); //these are typically already handled by the parseExpression
			var _condition = parseConditionalExpression();
			optionalToken(__GMLC_TokenType.Punctuation, ";"); //these are typically already handled by the parseExpression
			var _increment = parseExpression();
			optionalToken(__GMLC_TokenType.Punctuation, ";"); //these are typically already handled by the parseExpression
			expectToken(__GMLC_TokenType.Punctuation, ")");
			var _codeBlock = parseBlock();
			return new ASTForStatement(_initialization, _condition, _increment, _codeBlock, line, lineString);
		};
		
		static parseWhileStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is while
			nextToken(); // Move past while
			var _condition = parseConditionalExpression();
			var _codeBlock = parseBlock();
			return new ASTWhileStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseRepeatStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is repeat
			nextToken(); // Move past repeat
			var _condition = parseExpression();
			var _codeBlock = parseBlock();
			return new ASTRepeatStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseDoUntilStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is do
			nextToken(); // Move past do
			var _codeBlock = parseBlock();
			expectToken(__GMLC_TokenType.Keyword, "until");
			var _condition = parseConditionalExpression();
			return new ASTDoUntillStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseSwitchStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
		    nextToken(); // Move past switch
		    var switchExpression = parseExpression(); // Parse the switch expression
		    
			expectToken(__GMLC_TokenType.Punctuation, "{"); // Ensure { and consume it
			
			var cases = [];
		    var statements = undefined;
		    var _expectClosingCurly = false;
			
		    while (currentToken != undefined && currentToken.value != "}") {
				if (currentToken.type == __GMLC_TokenType.Keyword) {
					if (currentToken.value == "case") {
						if (_expectClosingCurly) {
							throw_gmlc_error($"switch/case statement was opened with \{ but was never closed")
						}
						
						var caseLine = currentToken.line;
						var caseLineString = currentToken.lineString;
						
						expectToken(__GMLC_TokenType.Keyword, "case"); //consume case
						var _label = parseExpression();
						
						expectToken(__GMLC_TokenType.Punctuation, ":"); // Ensure : and consume it
						_expectClosingCurly = optionalToken(__GMLC_TokenType.Punctuation, "{")
						
						statements = [];
						array_push(cases, new ASTCaseExpression(_label, statements, caseLine, caseLineString));
					}
					else if (currentToken.value == "default") {
						if (_expectClosingCurly) {
							throw_gmlc_error($"switch/case statement was opened with \{ but was never closed")
						}
						
						var caseLine = currentToken.line;
						var caseLineString = currentToken.lineString;
						
						nextToken(); //consume default
						
						expectToken(__GMLC_TokenType.Punctuation, ":"); // Ensure : and consume it
						_expectClosingCurly = optionalToken(__GMLC_TokenType.Punctuation, "{")
						
						statements = [];
						array_push(cases, new ASTCaseDefault(statements, line, lineString));
					}
					else {
						array_push(statements, parseStatement());
						if (_expectClosingCurly && optionalToken(__GMLC_TokenType.Punctuation, "}")) {
							_expectClosingCurly = false;
						}
					}
				}
				else {
					array_push(statements, parseStatement());
					if (_expectClosingCurly && optionalToken(__GMLC_TokenType.Punctuation, "}")) {
						_expectClosingCurly = false;
					}
				}
		    }

		    expectToken(__GMLC_TokenType.Punctuation, "}"); // Ensure } and consume it

		    return new ASTSwitchStatement(switchExpression, cases, line, lineString);
		};
		
		static parseWithStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is with
			nextToken(); // Move past with
			var _condition = parseExpression();
			var _codeBlock = parseBlock();
			return new ASTWithStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseTryCatchStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Keyword, "try");  // Expect the try keyword
			var _tryBlock = parseBlock();  // Parse the block of statements under try
			
			var _catchBlock = undefined;
			var _exceptionVar = undefined;
			if (currentToken != undefined)
			&& (currentToken.value == "catch") {
				nextToken();  // Move past catch
				expectToken(__GMLC_TokenType.Punctuation, "(");
				
				//parse and identify the exception variable as a local variable.
				_exceptionVar = currentToken.value;  // Parse the exception variable
				array_push(scriptAST.LocalVarNames, _exceptionVar);
				
				nextToken();  // Move past Identifier
				expectToken(__GMLC_TokenType.Punctuation, ")");
				_catchBlock = parseBlock();  // Parse the block of statements under catch
			}
			
			var _finallyBlock = undefined;
			if (currentToken != undefined)
			&& (currentToken.value == "finally") {
				nextToken();  // Move past finally
				_finallyBlock = parseBlock();  // Parse the block of statements under finally
			}
			
			return new ASTTryStatement(_tryBlock, _catchBlock, _exceptionVar, _finallyBlock, line, lineString);
		};
		
		static parseThrowExpression = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Keyword, "throw");  // Expect the try keyword
			var _err_message = parseExpressionStatement();  // Parse the block of statements under try
			
			return new ASTThrowExpression(_err_message, line, lineString);
		};
		
		#endregion
		#region Keyword Executions
		static parseContinueStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume break
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Optionally consume the semicolon
			return new ASTContinueStatement(line, lineString);
		};
		
		static parseBreakStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume break
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Optionally consume the semicolon
			return new ASTBreakStatement(line, lineString);
		};
		
		static parseExitStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume exit
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Optionally consume the semicolon
			return new ASTExitStatement(line, lineString);
		};
		
		static parseReturnStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume return
			var expr = undefined;
			if (currentToken.value != ";") {
				expr = parseExpression(); // Parse the return expression if any
			}
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Optionally consume the semicolon
			
			return new ASTReturnStatement(expr, line, lineString);
		};
		#endregion
		#region Declarations / Definitions
		
		static parseFunctionDeclaration = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			#region `function`
			expectToken(__GMLC_TokenType.Keyword, "function");
			#endregion
			
			#region function `identifier` :: the function's name if provided
			var functionName = undefined;
			if (currentToken.type == __GMLC_TokenType.Identifier) {
				var functionName = currentToken.value;
				//consume the function's identifier
				nextToken();
			}
			else {
				static __anon_id = 0;
				var functionName = $"GMLC@anon@{__anon_id++}";
			}
			#endregion
			
			#region function`(arguments)` :: the argument list, or an emply block statement
			
			var _argList = parseArgumentDefaultList();
			
			var _local_var_names = [];
			var _i=0; repeat(array_length(_argList.statements)) {
				var _arg = _argList.statements[_i]
				array_push(_local_var_names, _arg.identifier)
			_i++}
			
			#endregion
			
			var _isConstructor = false;
			var _parentName = undefined;
			var _parentCall = undefined;
			#region function foo() `:` bar() constructor {} :: check and consume the `:` if it has a parent defined
			if (optionalToken(__GMLC_TokenType.Punctuation, ":")) {
				#region function foo() : `bar`() constructor {} :: parse constructor parent
				
				var _identifier = parsePrimaryExpression();
				var _parent = parseFunctionCall(_identifier);
				
				if (_parent.type != __GMLC_NodeType.CallExpression)
				|| (_identifier.type != __GMLC_NodeType.Identifier) {  ///////////////////////// This line might cause errors, maybe the preprocessor should evaluate function name declarations
					throw_gmlc_error($"line {line}:: {lineString}\nTrying to set a constructor parent to a non global defined value, got :: {_parent.name}")
				}
				
				#endregion
				
				_parentCall = _parent;
				_parentName = _parent.callee.value;
			}
			#endregion
			#region function foo() `constructor` :: parse constructor keyword (if provided)
			if (optionalToken(__GMLC_TokenType.Keyword, "constructor")) {
				_isConstructor = true;
			}
			#endregion
			
			
			
			// Register function as a global variable and move its body to GlobalVar
			if (!_isConstructor) {
				var globalFunctionNode = new ASTFunctionDeclaration(
												functionName,
												_argList,
												_local_var_names,
												undefined, //will be set after body is parsed
												line,
												lineString
										)
			}
			else {
				var globalFunctionNode = new ASTConstructorDeclaration(
												functionName,
												_parentName,
												_argList,
												_parentCall,
												_local_var_names,
												undefined, //will be set after body is parsed
												line,
												lineString
										)
			}
			
			//cache the old current function, incase we are declaring a function inside a function
			var _old_function = currentFunction;
			currentFunction = globalFunctionNode;
			
			// Parse the function body
			globalFunctionNode.statements = parseBlock();
			
			//reset the current function
			currentFunction = _old_function;
			
			// Add to GlobalVar mapping of the Program node
			scriptAST.GlobalVar[$ functionName] = globalFunctionNode;
			array_push(scriptAST.GlobalVarNames, functionName);
			
			// Return a reference to the function in the global scope
			return new ASTIdentifier(functionName, ScopeType.GLOBAL, line, lineString);
		};
		static parseArgumentDefaultList = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Punctuation, "(");
			var parameters = [];
			while (currentToken.value != ")") {
			    var _argNode = parseArgumentDefaultSingle()
				_argNode.argument_index = array_length(parameters);
				
				array_push(parameters, _argNode);
				
				
			    if (currentToken.value == ",") {
			        nextToken();  // Handle multiple parameters
			    }
			}
			nextToken();  // Close parameters list
			
			return new ASTArgumentList(parameters, line, lineString);
			
		}
		static parseArgumentDefaultSingle = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			var identifier = currentToken.value;  // Parse the parameter name
			nextToken();  // Move past Identifier
			
			var expr = undefined;
			if (optionalToken(__GMLC_TokenType.Operator, "=")) {
				expr = parseAssignmentExpression(); // Assignment is right-associative
			}
			else { 
				expr = new ASTLiteral(undefined, line, lineString);
			}
			
			return new ASTArgument(identifier, expr, undefined, line, lineString);
		}
		
		//used for gms1.4 #define funcName
		static parseDefineFunctionDeclaration = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Define, "#define");
			var functionName = $"GMLC@{currentToken.value}";  // Parse the function identifier
			nextToken();  // Move past Identifier
			
			var globalFunctionNode = new ASTFunctionDeclaration(functionName, [], [], undefined,  line, lineString);
			
			//cache the old current function, incase we are declaring a function inside a function
			var _old_function = currentFunction;
			currentFunction = globalFunctionNode;
			
			//build the body
			var _body = [];
			while (currentToken != undefined && currentToken.value != "#define") {
				var _statement = parseStatement();
				array_push(_body, _statement);
				// Parse each statement until } is found
				// Optional: Handle error checking for unexpected end of file
				if (GML_COMPILER_DEBUG) {
					static __lastString = ""
					var _str = string(currentTokenIndex/array_length(tokens))
					if (__lastString != _str) {
						do_trace($"{real(_str)*100}% Finished")
						__lastString = _str;
					}
				}
			}
			if (currentToken != undefined) nextToken(); // Consume the }
			globalFunctionNode.statements = new ASTBlockStatement(_body, line, lineString); // Return a block statement containing all parsed statements;
			
			//reset the current function
			currentFunction = _old_function;
			
			// Add to GlobalVar mapping of the Program node
			scriptAST.GlobalVar[$ functionName] = globalFunctionNode;
			array_push(scriptAST.GlobalVarNames, functionName);
			
			// Return a reference to the function in the global scope
			return new ASTIdentifier(functionName, ScopeType.GLOBAL, line, lineString);
		};
		
		static parseVariableDeclaration = function () {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			var _should_hoist = false
			var type = currentToken.value;  // var, globalvar, or static
			
			var _scope = undefined;
			switch (type) {
				//case "let":{
				//	//dont to nuttin`!
				//break;}
				case "var":{
					_scope = ScopeType.LOCAL;
				break;}
				case "static":{
					_should_hoist = true;
					_scope = ScopeType.STATIC;
				break;}
				case "globalvar":{
					_scope = ScopeType.GLOBAL;
				break;}
				default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?")
			}
			
			nextToken();
			
			var declarations = [];
			
		    while (true) {
				// optionally skip redeclarations
				var varLine = currentToken.line;
				var varLineString = currentToken.lineString;
				
				if (currentToken.type != __GMLC_TokenType.Identifier) {
		            throw_gmlc_error($"Expected identifier in variable declaration.\nRecieved: {currentToken}\nLast five tokens:\n{lastFiveTokens}");
		        }
				
		        var identifier = currentToken.value;
				nextToken();
				
				//mark the variable tables
				var _tableArr = undefined
				if (currentFunction == undefined) {
					//script scrope
					switch (_scope) {
						//case "let":{
						//	//dont to nuttin`!
						//break;}
						case ScopeType.LOCAL: _tableArr = scriptAST.LocalVarNames; break;
						case ScopeType.STATIC: throw_gmlc_error($"Script: <SCRIPT_NAME> at line {currentToken.line} : static can only be declared inside a function"); break;
						case ScopeType.GLOBAL: _tableArr = scriptAST.GlobalVarNames; break;
						default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?")
					}
					
				}
				else {
					//function scope
					switch (_scope) {
						//case "let":{
						//	//dont to nuttin`!
						//break;}
						case ScopeType.LOCAL:  _tableArr = currentFunction.LocalVarNames; break;
						case ScopeType.STATIC: _tableArr = currentFunction.StaticVarNames; break;
						case ScopeType.GLOBAL: _tableArr = scriptAST.GlobalVarNames; break;
						default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?")
					}
				}
				if (!array_contains(_tableArr, identifier)) {
					array_push(_tableArr, identifier);
				}
				
				
				//fetch expression
				var expr = undefined;
				if (optionalToken(__GMLC_TokenType.Operator, "=")) {
					expr = parseConditionalExpression();
					
					// a unique check to apply static functions names
					if (_scope == ScopeType.STATIC) {
						//if this is a static function assignment, assign the static identifiers name to the functions name
						if (expr.type == "Identifier")
						&& (expr.scope == ScopeType.GLOBAL) {
							var _possibleFunc = scriptAST.GlobalVar[$ expr.identifier]
							if (_possibleFunc.type == "FunctionDeclaration") {
								var _newFuncName = $"GMLC@{identifier}@{string_replace(_possibleFunc.functionName, "GMLC@", "")}"
									
								//change the global look up
								struct_remove(scriptAST.GlobalVar, _possibleFunc.functionName);
								scriptAST.GlobalVar[$ _newFuncName] = _possibleFunc;
								var _arr_index = array_get_index(scriptAST.GlobalVarNames, _possibleFunc.functionName);
								array_delete(scriptAST.GlobalVarNames, _arr_index, 1);
								array_push(scriptAST.GlobalVarNames, _newFuncName);
									
								//change the functions name
								_possibleFunc.functionName = _newFuncName;
									
								//change the identifier
								expr.identifier = _newFuncName;
							}
						}
					}
					
					switch (_scope) {
						//case "let":{
						//	//dont to nuttin`!
						//break;}
						case ScopeType.LOCAL:
						case ScopeType.GLOBAL:{
							array_push(declarations, new ASTVariableDeclaration(identifier, expr, _scope, varLine, varLineString));
						break;}
						case ScopeType.STATIC:{
							array_push(currentFunction.StaticVarArray, new ASTVariableDeclaration(identifier, expr, ScopeType.STATIC, varLine, varLineString))
						break;}
						default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?")
					}
					
				}
				
				if (optionalToken(__GMLC_TokenType.Punctuation, ";")) {
					break
				}
		        if (currentToken == undefined || currentToken.value != ",") {
		            break; // End of declaration list
		        }
				
		        nextToken(); // Consume , and move to the next identifier
		    }
			
			if (_should_hoist) {
				return undefined;
			}
			
			return new ASTVariableDeclarationList(declarations, _scope, line, lineString);
		};
		
		#endregion
		#region Execution
		
		static parseNewExpression = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Keyword, "new");  // Expect the new keyword
			
			var _funcCall = parseExpressionStatement();
			
			return new ASTNewExpression( _funcCall, line, lineString);
		};
		
		#endregion
		
		static parseExpressionStatement = function() {
			var expr = parseExpression();
			if (expr == undefined) {
				throw_gmlc_error($"Getting an error parsing expression, current token is:\n{currentToken}\nLast Five Tokens:\n{lastFiveTokens}")
			}
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Handle the optional semicolon
			return expr;
		}
		
		#endregion
		
		#region Expressions
		static parseExpression = function() {
			return parseAssignmentExpression(); // Start from the highest precedence that is not unary or primary
		};
		
		static parseConditionalExpression = function() {
			return parseConditionalEqualityExpression(); // Start from the highest precedence that is not unary or primary
		};
		
		static parseAssignmentExpression = function() {
			var expr = parseLogicalOrExpression();
			static __arr = ["=", "+=", "-=", "*=", "/=", "^=", "&=", "|="];
			if (currentToken != undefined && currentToken.type == __GMLC_TokenType.Operator && array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseAssignmentExpression(); // Assignment is right-associative
				expr = new ASTAssignmentExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};
		
		static parseConditionalEqualityExpression = function() {
			var expr = parseLogicalOrExpression();
			static __arr = ["=", "==", "!="];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = (currentToken.value == "=") ? "==" : currentToken.value;
				
				nextToken();
				var right = parseLogicalOrExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};
		
		// Add the conditional parsing at the right level
		static parseLogicalOrExpression = function() {
			var expr = parseLogicalAndExpression();
			while (currentToken != undefined && currentToken.type == __GMLC_TokenType.Operator && currentToken.value == "||") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseLogicalAndExpression();
				expr = new ASTLogicalExpression(operator, expr, right, line, lineString);
			}
			return parseTerneryExpression(expr); // Check if this is a conditional expression after logical operations
		};

		static parseTerneryExpression = function(expr) {
			if (currentToken != undefined && currentToken.type == __GMLC_TokenType.Operator && currentToken.value == "?") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				expectToken(__GMLC_TokenType.Operator, "?"); // Consume ?
				var trueExpr = parseExpression(); // Parse the true branch
				expectToken(__GMLC_TokenType.Punctuation, ":"); // Consume :
				var falseExpr = parseExpression(); // Parse the false branch
				expr = new ASTConditionalExpression(expr, trueExpr, falseExpr, line, lineString);
			}
			return expr;
		};

		static parseLogicalAndExpression = function() {
			var expr = parseLogicalXorExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (currentToken.value == "&&") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseOrExpression();
				expr = new ASTLogicalExpression(operator, expr, right, line, lineString);
			}
			
			return expr;
		};

		static parseLogicalXorExpression = function() {
			var expr = parseNullishExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (currentToken.value == "^^") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseOrExpression();
				expr = new ASTLogicalExpression(operator, expr, right, line, lineString);
			}
			
			return expr;
		};
		
		static parseNullishExpression = function() {
			var expr = parseBitwiseOrExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (currentToken.value == "??") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseOrExpression();
				expr = new ASTNullishExpression(operator, expr, right, line, lineString);
			}
			
			return expr;
		};
		
		static parseBitwiseOrExpression = function() {
			var expr = parseBitwiseXorExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (currentToken.value == "|") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseXorExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			
			return expr;
		};

		static parseBitwiseXorExpression = function() {
			var expr = parseBitwiseAndExpression();
			while (currentToken != undefined) && (currentToken.value == "^") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseAndExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			
			return expr;
		};

		static parseBitwiseAndExpression = function() {
			var expr = parseEqualityExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (currentToken.value == "&") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseEqualityExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			
			return expr;
		};

		static parseEqualityExpression = function() {
			var expr = parseRelationalExpression();
			static __arr = ["==", "!="];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseRelationalExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};

		static parseRelationalExpression = function() {
			var expr = parseShiftExpression();
			
			static __arr = ["<", "<=", ">", ">="];
			while (currentToken != undefined)
			&& (currentToken.type == __GMLC_TokenType.Operator)
			&& (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseShiftExpression();
				var _prev_expr = expr
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};
		
		static parseShiftExpression = function() {
			var expr = parseAdditiveExpression();
			static __arr = ["<<", ">>"];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseAdditiveExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};

		static parseAdditiveExpression = function() {
			var expr = parseMultiplicativeExpression();
			static __arr = ["+", "-"];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseMultiplicativeExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};

		static parseMultiplicativeExpression = function() {
			var expr = parseUnaryExpression();
			static __arr = ["*", "/", "mod", "div"];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseUnaryExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};

		static parseUnaryExpression = function() {
			static __arr = ["!", "+", "-", "~", "++", "--"];
			if (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var expr = parseUnaryExpression(); // Right-associative
				
				if (operator == "++" || operator == "--") {
					return new ASTUpdateExpression(operator, expr, true, line, lineString);
				}
				
				return new ASTUnaryExpression(operator, expr, line, lineString);
			}
			else {
				return parsePostfixExpression();
			}
		};

		static parsePostfixExpression = function() {
			var expr = parseAccessExpression();
			static __arr = ["++", "--"];
			if (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value))
			&& !(expr.type == "Literal" && expr.scope == ScopeType.CONST) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				var postfixExpr = new ASTUpdateExpression(operator, expr, false, line, lineString);
				nextToken();
				expr = postfixExpr;
			}
			return expr;
		};
		
		static parseAccessExpression = function() {
			var expr = parsePrimaryExpression();
			
			var _should_break = false;
			while (currentToken != undefined) {
				switch (currentToken.value) {
					case "(": {
						if (expr.name == "nameof") {
							return new ASTLiteral(expr.name, expr.line, expr.lineString);
						}
						else {
							expr = parseFunctionCall(expr);
						}
					break;}
					case "[": {
						expr = parseBracketAccessor(expr);
					break;}
					case ".": {
						expr = parseDotAccessor(expr);
					break;}
					default: {
						return expr
					break;}
				}
			}
			return expr;
		};
		
		static parsePrimaryExpression = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			if (currentToken == undefined) {
				throw_gmlc_error("Unexpected end of input");
			}
			
			switch (currentToken.type) {
				case __GMLC_TokenType.Number:
				case __GMLC_TokenType.String:{
					
					// Handle literals
					var node = new ASTLiteral(currentToken.value, line, lineString);
					nextToken();
					return node;
					
				break;}
				case __GMLC_TokenType.Identifier:{
					
					var _scopeType = __find_ScopeType_from_string(currentToken.value);
					
					if (_scopeType == ScopeType.MACRO) {
						
						var _macroTokens = variable_clone(currentScript.MacroVar[$ currentToken.value]);
						
						array_delete(tokens, currentTokenIndex, 1); //remove the macro from the token array
						array_insert_ext(tokens, currentTokenIndex, _macroTokens); //insert the macro definition into the token array
						
						return node;
					}
					
					if (_scopeType == ScopeType.ENUM) {
						var _header = currentToken.value
						if (optionalToken(__GMLC_TokenType.Punctuation, ".")) {
							if (currentToken.type == __GMLC_TokenType.Identifier) {
								var _member = currentToken.value;
								var _enumTokens = variable_clone(currentScript.EnumVar[$ _header][$ _member]);
								
								array_delete(tokens, currentTokenIndex, 1); //remove the enum from the token array
								array_insert_ext(tokens, currentTokenIndex, _enumTokens); //insert the enum definition into the token array
								
								return node;
							}
						}
						
						//this will eventually get defaulted to instance if no dot accessor is eventually found
						var node = new ASTIdentifier(currentToken.value, undefined, line, lineString);
						nextToken(); // Move past the identifier
						return node;
					}
					
					if (_scopeType == ScopeType.CONST) {
						var node = new ASTIdentifier(currentToken.value, ScopeType.CONST, line, lineString);
						nextToken(); // Move past the identifier
						return node;
					}
					
					if (_scopeType == ScopeType.SELF) {
						var node = new ASTIdentifier(currentToken.value, undefined, line, lineString);
						nextToken(); // Move past the identifier
						return node;
					}
					
					var node = new ASTIdentifier(currentToken.value, _scopeType, line, lineString);
					
					nextToken(); // Move past the identifier
					return node;
					
				break;}
				case __GMLC_TokenType.Function:{
					var _func = getReplacementFunction(currentToken.value)
					var node = new ASTFunction(_func, line, lineString);
					nextToken(); // Move past the identifier
					return node;
					
				break;}
				case __GMLC_TokenType.Keyword:{
					switch (currentToken.value) {
						case "function": return parseFunctionDeclaration();
						case "new": return parseNewExpression()
					}
				break;}
				case __GMLC_TokenType.Punctuation:{
					
					if (currentToken.value == "(") {
						// Handle expressions wrapped in parentheses
						nextToken(); // Consume (
						var expr = parseExpression();
						expectToken(__GMLC_TokenType.Punctuation, ")");
						return expr;
					}
					
					if (currentToken.value == "[") {
						return parseArrayCreation();
					}
					
					if (currentToken.value == "{") {
						return parseStructCreation();
					}
					
				break;}
				case __GMLC_TokenType.UniqueVariable:{
					
					// Handle literals
					var node = new ASTUniqueIdentifier(currentToken.value, line, lineString);
					nextToken();
					return node;
					
				break;}
				case __GMLC_TokenType.TemplateStringBegin:{
					
					var _template_string = currentToken.value;
					
					//consume the beginning
					nextToken();
					
					var _arguments = [];
					var _index = 0;
					while (currentToken != undefined && currentToken.type != __GMLC_TokenType.TemplateStringEnd) {
						var _expr = parseExpression()
						array_push(_arguments, _expr); // Parse each argument as an expression
						_template_string += "{"+string(_index)+"}"
						
						if (currentToken.type == __GMLC_TokenType.TemplateStringMiddle) {
							_template_string += currentToken.value;
							nextToken();  // Consume the middle segment
						}
					}
					
					//add the template strings end, then consume
					_template_string += currentToken.value;
					nextToken();  // Consume the middle segment
					
					//push the template string into the beginning of the arguments
					array_insert(_arguments, 0, new ASTLiteral(_template_string, line, lineString));
					
					var _literalStringFunction = new ASTFunction(string, line, lineString);
					var _node = new ASTCallExpression(_literalStringFunction, _arguments, line, lineString);
					
					return _node
				break;}
			}
			
			throw_gmlc_error($"Unexpected token in expression: {currentToken}\nLast five tokens were:\n{lastFiveTokens}");
		};
		
		static parseArrayCreation = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			var elements = [];
		    
		    expectToken(__GMLC_TokenType.Punctuation, "[");
		    while (currentToken != undefined && currentToken.value != "]") {
		        var element = parseExpression();
				array_push(elements, element);
		        
				if (currentToken.value == ",") {
		            nextToken();  // Skip the comma
		        }
		    }
		    expectToken(__GMLC_TokenType.Punctuation, "]");
			
			return new ASTArrayPattern(elements, line, lineString);
		};
		
		static parseStructCreation = function() {
		    var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			var _args = [];
		    
		    expectToken(__GMLC_TokenType.Punctuation, "{");
		    while (currentToken != undefined && currentToken.value != "}") {
		        if (currentToken.type != __GMLC_TokenType.Identifier)
				&& (currentToken.type != __GMLC_TokenType.String)
				&& (currentToken.type != __GMLC_TokenType.UniqueVariable)
				&& (currentToken.type != __GMLC_TokenType.Number)
				{
		            throw_gmlc_error($"Expected identifier for struct property name.\n{currentToken}\nLast Five Tokens:\n{json_stringify(lastFiveTokens, true)}");
		        }
				
		        var key = currentToken;
		        nextToken();  // Move past the identifier
				
				if (optionalToken(__GMLC_TokenType.Punctuation, ":")) {
					var value = parseExpression();
				}
				else if (key.type == __GMLC_TokenType.String)
				     || (key.type == __GMLC_TokenType.Identifier)
				     || (key.type == __GMLC_TokenType.UniqueVariable)
				     || (key.type == __GMLC_TokenType.Number)
				{
					var value = new ASTIdentifier(key.value, __find_ScopeType_from_string(key.value), key.line, key.lineString);
				}
				else {
					throw_gmlc_error($"Object: {Object1} Event: {Create} at line {line} : got {key.type} {key.value} expected id")
				}
		        
				//push the key and the value
				array_push(
					_args,
					new ASTLiteral(key.value, key.line, key.lineString),
					value
				);
				
		        if (currentToken.value == ",") {
		            nextToken();  // Skip the comma
		        }
				
		    }
		    expectToken(__GMLC_TokenType.Punctuation, "}");
			
			// Properties are not all constants, use a runtime function to create the struct
			return new ASTStructPattern(_args, line, lineString)
		};
		
		static parseFunctionCall = function(callee) {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			var arg = parseArgumentInput();
			
			return new ASTCallExpression(callee, arg, line, lineString);
		};
		static parseArgumentInput = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			var _arguments = [];
			expectToken(__GMLC_TokenType.Punctuation, "("); // Ensure ( and consume it
			
			//early out
			if (currentToken != undefined && currentToken.value != ")") {
				while (currentToken != undefined && currentToken.value != ")") {
					var _expr = parseExpression()
					
					array_push(_arguments, _expr); // Parse each argument as an expression
					if (currentToken.value == ",") {
						nextToken();  // Consume the comma to continue to the next argument
					}
				}
			}
			
			if (currentToken == undefined) {
				throw_gmlc_error($"<Object>: <Object1> <Event>: <Create> at line {line} : Symbol , or ) expected, got <EndOfFile>")
			}
			
			expectToken(__GMLC_TokenType.Punctuation, ")"); // Ensure ) and consume it
			
			return _arguments;
		}
		
		
		static parseDotAccessor = function(object) {
		    var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume .
		    if (currentToken.type != __GMLC_TokenType.Identifier) {
		        throw_gmlc_error("Expected identifier after .");
		    }
			
			var _expr = new ASTAccessorExpression(
				object,
				new ASTLiteral(currentToken.value, currentToken.line, currentToken.lineString),
				undefined,
				__GMLC_AccessorType.Dot,
				line,
				lineString
			)
			
			nextToken(); // Consume identifer key
			
			return _expr
		};
		
		static parseBracketAccessor = function(object) {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume [
			var accessorType = __GMLC_AccessorType.Array; // Default to array accessor
			
			switch (currentToken.value) {
				case "|":{
					accessorType = __GMLC_AccessorType.List;
					nextToken(); // Consume |
				break;}
				case "?":{
					accessorType = __GMLC_AccessorType.Map;
					nextToken(); // Consume ?
				break;}
				case "#":{
					accessorType = __GMLC_AccessorType.Grid;
					nextToken(); // Consume #
				break;}
				case "$":{
					accessorType = __GMLC_AccessorType.Struct;
					nextToken(); // Consume $
				break;}
				case "@":{
					accessorType = __GMLC_AccessorType.Array;
					nextToken(); // Consume @
				break;}
			}
			
			//parse the index/key
			var _val1 = parseExpression();
			var _val2 = undefined;
			if (currentToken.value == ",") {
				nextToken();
				//parse the second array index
				var _val2 = parseExpression();
			}
			
			expectToken(__GMLC_TokenType.Punctuation, "]"); // Consume ]
			
			return new ASTAccessorExpression(
				object,
				_val1,
				_val2,
				accessorType,
				line,
				lineString
			)
			
		};
		
		#endregion
		
		#region Helper Functions
		
		static expectToken = function(expectedType, expectedValue) {
			if (currentToken == undefined) {
				throw_gmlc_error($"Unexpected end of input. Expected {expectedValue} but found EOF.");
			}
			if (currentToken.type != expectedType || currentToken.value != expectedValue) {
				pprint("lastFiveTokens :: ",lastFiveTokens)
				throw_gmlc_error($"Syntax Error: Expected {expectedValue} at line {currentToken.line}, column {currentToken.column}, but found {currentToken}\nLast five tokens:\n{lastFiveTokens}.");
			}
			nextToken();
		};
		
		static optionalToken = function(optionalType, optionalValue) {
			if (currentToken == undefined) return false;
			
			if (currentToken.type == optionalType && currentToken.value == optionalValue) {
				nextToken();
				return true;
			}
			
			return false;
		};
		
		static getReplacementFunction = function(_func) {
			switch (_func) {
				case method             : return __method            ;
				case is_instanceof      : return __is_instanceof     ;
				case static_get         : return __static_get        ;
				
				case static_set         : return __static_set        ;
				case typeof             : return __typeof            ;
				case method_get_index   : return __method_get_index  ;
				case method_get_self    : return __method_get_self   ;
				case method_call        : return __method_call       ;
				case script_execute     : return __script_execute    ;
				case script_execute_ext : return __script_execute_ext;
				
				default					: return _func;
			}
			
		}
		
		#endregion
		
		#endregion
		
	}
	
#endregion

#region GMLC_GM1_4_Converter.gml
	#region GMLC_GM1_4_Converter Module
	/*
	Purpose: There are a lot of deprocated function calls and assignments which need to be converted to modern gml standards. This module supports many of those conversions
	
	Methods:
	
	optimize(ast): Entry function that takes an AST and returns an optimized AST.
	constantFolding(ast): Traverses the AST and evaluates expressions that can be determined at compile-time.
	deadCodeElimination(ast): Removes parts of the AST that do not affect the program outcome, such as unreachable code.
	*/
	#endregion
	function GMLC_GM1_4_Converter() constructor {
		//init variables:
		
		ast = undefined;
		nodeStack = [];
		finished = false;
		
		static initialize = function(_ast) {
			ast = _ast;
			nodeStack = [];  // Stack to keep track of nodes to visit
			array_push(nodeStack, {node: ast, parent: undefined, key: undefined, index: undefined}) // Start with the root node
			finished = !array_length(nodeStack);
			currentNode = undefined;
		};
		
		static cleanup = function() {
		
		}
		
		static parseAll = function() {
			while (!finished) {
				nextNode();
			}
			return ast;
		}
		
		static nextNode = function() {
			if (!array_length(nodeStack)) {
				finished = true;
				return;
			}
		
		    // Get current node from the stack
			currentNode = array_pop(nodeStack);
			
			// Process children first (post-order traversal)
			if (currentNode.node.visited == false) {
				currentNode.node.visited = true;
				
				// Push current node back onto stack to process after children
				array_push(nodeStack, currentNode);
				
				currentNode.node.push_children_to_node_stack(nodeStack);
			}
			else {
				// Process the current node as all children have been processed
				var _node = convert(currentNode.node);
				_node.visited = false
				
				if (currentNode.parent == undefined) {
					//the entire tree has been optimized and we are at the top most "Program" node
					if (array_length(nodeStack)) {
						throw_gmlc_error($"We still have nodes in the nodeStack, we shouldnt be finished")
					}
					
					finished = true;
					ast = _node;
				}
				else {
					//reset the visit so the next module can make use of it
					if (currentNode.index != undefined) {
						currentNode.parent[$ currentNode.key][currentNode.index] = _node;
					}
					else {
						currentNode.parent[$ currentNode.key] = _node;
					}
				}
				
			}
		};
		
		static convert = function(_ast) {
			var _orig_ast = undefined;
			
			//keep optimizing until there are no optimizers which change the node.
			while (_ast != _orig_ast) {
				var _orig_ast = _ast
				
			}
			
			return _ast;
		};
		
		static nodeStackPush = function(parent=undefined, key=undefined, index=undefined) {
			var node;
			if (index !=  undefined) {
				node = parent[$ key][index];
			}
			else {
				node = parent[$ key];
			}
			array_push(nodeStack, {node, parent, key, index})
		}
		
		#region converters
		
		static convertBackgrounds = function(node) {
			
			if (node.type == "FunctionCall") {
				if (node.callee.value == array_get) {
					var ind_node = arguments[0]
					if (ind_node.type == "Identifier") {
						
						switch (ind_node.value) {
							case "background_visible": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Visible, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_foreground": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Foreground, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_index": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Index, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_x": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.X, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_y": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Y, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_width": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Width, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_height": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Height, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_htiled": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.HTiled, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_vtiled": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.VTiled, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_xscale": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.XScale, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_yscale": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.YScale, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_hspeed": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.HSpeed, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_vspeed": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.VSpeed, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_blend": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Blend, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_alpha": {
								return new ASTCallExpression(
									new ASTFunction(__background_get, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Alpha, ind_node.line, ind_node.lineString),
									]
								);
							break;}
						}
						
					}
				}
				if (node.callee.value == array_set) {
					var ind_node = arguments[0]
					if (ind_node.type == "Identifier") {
						
						switch (ind_node.value) {
							case "background_visible": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Visible, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_foreground": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Foreground, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_index": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Index, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_x": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.X, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_y": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Y, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_width": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Width, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_height": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Height, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_htiled": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.HTiled, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_vtiled": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.VTiled, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_xscale": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.XScale, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_yscale": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.YScale, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_hspeed": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.HSpeed, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_vspeed": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.VSpeed, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_blend": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Blend, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_alpha": {
								return new ASTCallExpression(
									new ASTFunction(__background_set, ind_node.line, ind_node.lineString),
									[
										new ASTLiteral(e__BG.Alpha, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
						}
						
					}
				}
			}
			
			if (node.type == "AssignmentExpression") {
				if (node.left.type == "Identifier") {
					if (node.left.value == "background_color") || (node.left.value == "background_colour") {
						return new ASTNodes("FunctionCall", {
							callee: new ASTNodes("Function", {value: __background_set_colour, name: "__background_set_colour"}),
							arguments: [ node.right ]
						});
					}
				}
			}
			
			if (node.type == "Identifier") {
				switch (node.value) {
					case "background_color":
					case "background_colour":{
						return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get_colour, name: "__background_get_colour"}),
								arguments: []
							});
					break;}
					
					case "background_showcolor":
					case "background_showcolour":{
						return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get_showcolour, name: "__background_get_showcolour"}),
								arguments: []
							});
					break;}
					
				}
			}
			
			//background_visible
			return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: background_visible, name: "background_visible"}),
								arguments: []
							});
			//background_showcolor
			return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: background_showcolor, name: "background_showcolor"}),
								arguments: []
							});
							
			
			
			return node;
		}
		
		static convertViews = function(node) {
			
			if (node.type == "AssignmentExpression") {
				if (node.left.type == "Identifier") {
					if (node.left.value == "background_color") || (node.left.value == "background_colour") {
						return new ASTNodes("FunctionCall", {
							callee: new ASTNodes("Function", {value: __background_set_colour, name: "__background_set_colour"}),
							arguments: [ node.right ]
						});
					}
				}
			}
			
			if (node.type == "FunctionCall") {
				if (node.callee.value == array_get) {
					var ind_node = arguments[0]
					if (ind_node.type == "Identifier") {
						if (ind_node.value == "background_visible") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Visible, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_foreground") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Foreground, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_index") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Index, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_x") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.X, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_y") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Y, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_width") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Width, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_height") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Height, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_htiled") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.HTiled, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_vtiled") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.VTiled, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_xscale") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.XScale, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_yscale") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.YScale, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_hspeed") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.HSpeed, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_vspeed") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.VSpeed, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_blend") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Blend, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_alpha") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Alpha, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						
						
						
						
						
						
						
						
						
						
						
						
						if (ind_node.value == "view_visible") {
							
						}
						if (ind_node.value == "view_hport") {
							
						}
						if (ind_node.value == "view_hview") {
							
						}
						if (ind_node.value == "view_wport") {
							
						}
						if (ind_node.value == "view_wview") {
							
						}
						if (ind_node.value == "view_xport") {
							
						}
						if (ind_node.value == "view_xview") {
							
						}
						if (ind_node.value == "view_yport") {
							
						}
						if (ind_node.value == "view_yview") {
							
						}
					}
				}
				if (node.callee.value == array_set) {
					var ind_node = arguments[0]
					if (ind_node.type == "Identifier") {
						if (ind_node.value == "background_visible") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Visible, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_foreground") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Foreground, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_index") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Index, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_x") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.X, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_y") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Y, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_width") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Width, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_height") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Height, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_htiled") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.HTiled, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_vtiled") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.VTiled, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_xscale") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.XScale, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_yscale") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.YScale, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_hspeed") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.HSpeed, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_vspeed") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.VSpeed, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_blend") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Blend, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_alpha") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNodes("Literal", {value: e__BG.Alpha, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
					}
				}
				
			}
			
			
			
			//background_visible
			return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: background_visible, name: "background_visible"}),
								arguments: []
							});
			//background_showcolor
			return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: background_showcolor, name: "background_showcolor"}),
								arguments: []
							});
							
			
			
			return node;
		}
		
		#endregion
		
		#region Helper Functions
		
		
		
		#endregion
	}
#endregion

#region PostProcessor.gml
	#region PostProcessor Module
	/*
	Purpose: To refine the AST for better performance during interpretation.
	
	Methods:
	
	optimize(ast): Entry function that takes an AST and returns an optimized AST.
	constantFolding(ast): Traverses the AST and evaluates expressions that can be determined at compile-time.
	deadCodeElimination(ast): Removes parts of the AST that do not affect the program outcome, such as unreachable code.
	*/
	#endregion
	function GML_PostProcessor() constructor {
		//init variables:
		
		ast = undefined;
		currentScript = undefined;
		nodeStack = [];
		finished = false;
		
		static initialize = function(_ast) {
			ast = _ast;
			currentScript = ast;
			currentFunction = undefined;
			nodeStack = [];  // Stack to keep track of nodes to visit
			currentNode = undefined;
			
			// Push the script onto the stack, being the last one to get parsed
			array_push(nodeStack, {node: ast, parent: undefined, key: undefined, index: undefined}) // Start with the root node
			
			// Parse the Global Functions
			struct_foreach(_ast.GlobalVar, function(_name, _value){
				array_push(nodeStack, {node: _value, parent: currentScript.GlobalVar, key: _name, index: undefined})
			})
			
			finished = !array_length(nodeStack);
		};
		
		static cleanup = function() {
		
		}
		
		static parseAll = function() {
			while (!finished) {
				nextNode();
			}
			return ast;
		}
		
		static nextNode = function() {
			if (!array_length(nodeStack)) {
				finished = true;
				return;
			}
		
		    // Get current node from the stack
			var currentNode = array_pop(nodeStack);
			
			// Process children first (post-order traversal)
			if (currentNode.node.visited == false) {
				currentNode.node.visited = true;
				
				if (currentNode.node.type == __GMLC_NodeType.FunctionDeclaration)
				|| (currentNode.node.type == __GMLC_NodeType.ConstructorDeclaration) {
					currentFunction = currentNode.node
				}
				
				array_push(nodeStack, currentNode);
				
				// Push current node back onto stack to process after children
				currentNode.node.push_children_to_node_stack(nodeStack);
			}
			else {
				if (currentNode.node.type == __GMLC_NodeType.FunctionDeclaration) {
					currentFunction = undefined;
				}
				
				// Process the current node as all children have been processed
				var _node = Process(currentNode.node);
				_node.visited = false;
				
				if (currentNode.parent == undefined) {
					//the entire tree has been optimized and we are at the top most "Program" node
					if (array_length(nodeStack)) {
						throw_gmlc_error($"We still have nodes in the nodeStack, we shouldnt be finished")
					}
					
					finished = true;
					ast = _node;
				}
				else {
					//reset the visit so the next module can make use of it
					if (currentNode.index != undefined) {
						currentNode.parent[$ currentNode.key][currentNode.index] = _node;
					}
					else {
						currentNode.parent[$ currentNode.key] = _node;
					}
				}
				
			}
		};
		
		static Process = function(node) {
			
			//attempt to repopulate all scopes which pass through
			if (struct_exists(node, "scope")) {
				var _scopeType = __determineScopeType(node)
				node.scope = _scopeType;
			}
			
			switch (node.type) {
			    case __GMLC_NodeType.Script:{
					
				break;}
				case __GMLC_NodeType.FunctionDeclaration:{
					
				break;}
				case __GMLC_NodeType.ArgumentList:{
					
				break;}
				case __GMLC_NodeType.Argument:{
					
				break;}
				
				case __GMLC_NodeType.BlockStatement:{
					
				break;}
				case __GMLC_NodeType.IfStatement:{
					
				break;}
				case __GMLC_NodeType.ForStatement:{
				    
			    break;}
				case __GMLC_NodeType.WhileStatement:{
					
				break;}
				case __GMLC_NodeType.RepeatStatement:{
					
				break;}
				case __GMLC_NodeType.DoUntillStatement:{
					
				break;}
				case __GMLC_NodeType.WithStatement:{
					
				break;}
				case __GMLC_NodeType.TryStatement:{
					
				break;}
				case __GMLC_NodeType.SwitchStatement:{
					
				break;}
				case __GMLC_NodeType.CaseExpression:
				case __GMLC_NodeType.CaseDefault:{
					
				break;}
				
				case __GMLC_NodeType.ThrowExpression: {
					
				break;}
				
				case __GMLC_NodeType.BreakStatement:
				case __GMLC_NodeType.ContinueStatement:{
					
				break;}
				case __GMLC_NodeType.ExitStatement:{
					
				break;}
				case __GMLC_NodeType.ReturnStatement:{
					
				break;}
				
				case __GMLC_NodeType.VariableDeclarationList:{
					
				break;}
				case __GMLC_NodeType.VariableDeclaration:{
					
				break;}
				
				case __GMLC_NodeType.CallExpression:{
					
				break;}
				case __GMLC_NodeType.NewExpression:{
					
				break;}
				
				case __GMLC_NodeType.ExpressionStatement:{
					
				break;}
				case __GMLC_NodeType.AssignmentExpression:{
					
					if (node.left.type == __GMLC_NodeType.AccessorExpression) {
						//scope all children
						//if (node.left.expr.type == __GMLC_NodeType.Identifier) {
						//	node.left.expr.scope = __determineScopeType(node.left.expr.scope);
						//}
						//if (node.left.val1.type == __GMLC_NodeType.Identifier) {
						//	node.left.val1.scope = __determineScopeType(node.left.val1.scope);
						//}
						//if (node.left.val2.type != undefined)
						//|| (node.left.val2.type == __GMLC_NodeType.Identifier) {
						//	node.left.val2.scope = __determineScopeType(node.left.val2.scope);
						//}
						
						//do nothing the compiler will handle the funny business with the following code:
						// var arr;
						// arr[1,2] = 1;
						
						
					}
					else if (node.left.type == __GMLC_NodeType.Identifier) {
						node.left.scope = __determineScopeType(node.left)
					}
				break;}
				case __GMLC_NodeType.BinaryExpression:{
					
				break;}
				case __GMLC_NodeType.LogicalExpression:{
					
				break;}
				case __GMLC_NodeType.NullishExpression:{
					
				break;}
				case __GMLC_NodeType.UnaryExpression:{
					switch (node.operator) {
						case "!":{
							
						break;}
						case "+":{
							//nothing is needed here
						break;}
						case "-":{
							
						break;}
						case "~":{
							
						break;}
						case "++":{
							
						break;}
						case "--":{
							
						break;}
					}
				break;}
				case __GMLC_NodeType.UpdateExpression:{
					if (node.expr.type == __GMLC_NodeType.AccessorExpression) {
						
						throw_gmlc_error("updating accessor")
						
						//var increment = (node.operator == "++");
						//var prefix = node.prefix; // Since this is a postfix expression
						
						//switch (node.expr.accessorType) {
						//	case __GMLC_AccessorType.Array:{
						//		node = new ASTCallExpression(
						//			new ASTFunction(__array_update, node.line, node.lineString),
						//			[
						//				node.expr.expr,
						//				node.expr.val1,
						//				new ASTLiteral(increment, node.line, node.lineString),
						//				new ASTLiteral(prefix, node.line, node.lineString)
						//			],
						//			node.line,
						//			node.lineString
						//		);	
						//	break;}
						//	case __GMLC_AccessorType.Grid:{
						//		node = new ASTCallExpression(
						//			new ASTFunction(__grid_update, node.line, node.lineString),
						//			[
						//				node.expr.expr,
						//				node.expr.val1,
						//				node.expr.val2,
						//				new ASTLiteral(increment, node.line, node.lineString),
						//				new ASTLiteral(prefix, node.line, node.lineString)
						//			],
						//			node.line,
						//			node.lineString
						//		);	
						//	break;}
						//	case __GMLC_AccessorType.List:{
						//		node = new ASTCallExpression(
						//			new ASTFunction(__list_update, node.line, node.lineString),
						//			[
						//				node.expr.expr,
						//				node.expr.val1,
						//				new ASTLiteral(increment, node.line, node.lineString),
						//				new ASTLiteral(prefix, node.line, node.lineString)
						//			],
						//			node.line,
						//			node.lineString
						//		);	
						//	break;}
						//	case __GMLC_AccessorType.Map:{
						//		node = new ASTCallExpression(
						//			new ASTFunction(__map_update, node.line, node.lineString),
						//			[
						//				node.expr.expr,
						//				node.expr.val1,
						//				new ASTLiteral(increment, node.line, node.lineString),
						//				new ASTLiteral(prefix, node.line, node.lineString)
						//			],
						//			node.line,
						//			node.lineString
						//		);	
						//	break;}
						//	case __GMLC_AccessorType.Struct:{
						//		node = new ASTCallExpression(
						//			new ASTFunction(__struct_update, node.line, node.lineString),
						//			[
						//				node.expr.expr,
						//				node.expr.val1,
						//				new ASTLiteral(increment, node.line, node.lineString),
						//				new ASTLiteral(prefix, node.line, node.lineString)
						//			],
						//			node.line,
						//			node.lineString
						//		);	
						//	break;}
						//	case __GMLC_AccessorType.Dot:{
						//		node = new ASTCallExpression(
						//			new ASTFunction(__struct_with_error_update, node.line, node.lineString),
						//			[
						//				node.expr.expr,
						//				node.expr.val1,
						//				new ASTLiteral(increment, node.line, node.lineString),
						//				new ASTLiteral(prefix, node.line, node.lineString)
						//			],
						//			node.line,
						//			node.lineString
						//		);	
						//	break;}
						//}
						
					}
					else if (node.expr.type == __GMLC_NodeType.Identifier) {
						node.expr.scope = __determineScopeType(node.expr);
					}
					
					return node;
				break;}
				case __GMLC_NodeType.AccessorExpression:{
					
				break;}
				case __GMLC_NodeType.ConditionalExpression:{
					
				break;}
				
				case __GMLC_NodeType.ArrayPattern:{
					
				break;}
				case __GMLC_NodeType.StructPattern:{
					//loop through all children and post process them aswell
					
					//throw_gmlc_error("why havent we stopped")
				break;}
				case __GMLC_NodeType.Literal:{
				    
			    break;}
				case __GMLC_NodeType.Identifier:{
					var _scopeType = __determineScopeType(node)
					node.scope = _scopeType;
				break;}
				
				case __GMLC_NodeType.UniqueIdentifier:{
					
				break;}
				
				case __GMLC_NodeType.Function:{
					
				break;}
				case __GMLC_NodeType.ConstructorDeclaration:{
					
				break;}
				/*
				case __GMLC_NodeType.PropertyAccessor:{
					throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
				break;}
				case __GMLC_NodeType.AccessorExpression:{
					throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
				break;}
				case __GMLC_NodeType.MethodVariableConstructor:{
					throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
				break;}
				case __GMLC_NodeType.MethodVariableFunction:{
					throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
				break;}
				//*/
				default: throw_gmlc_error($"Current Node does not have a valid type for the post processor,\ntype: {node.type}\ncurrentNode: {node}")
				
				// Add cases for other types of nodes
			}
			
			return node;
		};
		
		#region Processors
		
		#endregion
		
		#region Helper Functions
		static __argumentsAreLiteral = function(_arguments) {
			var _i=0; repeat(array_length(_arguments)) {
				if (_arguments[_i].type != __GMLC_NodeType.Literal) {
					return false;
				}
			_i+=1;}//end repeat loop
			return true;
		}
		
		static __build_literal_from_function_call_constant_folding = function(_script, node) {
			if (!__argumentsAreLiteral(node.arguments)) return node;
								
			//remap the arguments
			var _arr = node.arguments;
			var _new_arr = [];
			var _i=0; repeat(array_length(_arr)) {
				_new_arr[_i] = _arr[_i].value;
			_i+=1;}//end repeat loop
			
			return new ASTLiteral(script_execute_ext(_script, _new_arr), node.line, node.lineString);
		}
		
		static handleAccessorFunctionCall = function(accessorType, _args) {
		    //var _getterFunc, _setterFunc;
			
			//// Getter context
		    //switch (accessorType) {
			//	case __GMLC_AccessorType.Array:  _getterFunc = new ASTFunction(array_get,               node.line, node.lineString); _setterFunc = new ASTFunction(array_set,   node.line, node.lineString); break;
			//	case __GMLC_AccessorType.List:   _getterFunc = new ASTFunction(ds_list_find_value,      node.line, node.lineString); _setterFunc = new ASTFunction(ds_list_set, node.line, node.lineString); break;
			//	case __GMLC_AccessorType.Map:    _getterFunc = new ASTFunction(ds_map_find_value,       node.line, node.lineString); _setterFunc = new ASTFunction(ds_map_set,  node.line, node.lineString); break;
			//	case __GMLC_AccessorType.Grid:   _getterFunc = new ASTFunction(ds_grid_get,             node.line, node.lineString); _setterFunc = new ASTFunction(ds_grid_set, node.line, node.lineString); break;
			//	case __GMLC_AccessorType.Struct: _getterFunc = new ASTFunction(struct_get,              node.line, node.lineString); _setterFunc = new ASTFunction(struct_set,  node.line, node.lineString); break;
			//	case __GMLC_AccessorType.Dot:    _getterFunc = new ASTFunction(__struct_get_with_error, node.line, node.lineString); _setterFunc = new ASTFunction(struct_set,  node.line, node.lineString); break;
			//	default: throw_gmlc_error($"Unexpected entry into handleAccessorFunctionCall with accessorType: {accessorType}") break;
			//}
			
			//var _get_expr = new ASTCallExpression(_getterFunc, _args, node.line, node.lineString);
			////var expr = parseLogicalOrExpression();
			
			//if (currentToken != undefined) {
			//	var _op = currentToken.value;
			//	var _new_args = variable_clone(_args);
			//	var right;
				
			//	// Handle compound assignments
			//	static __op_arr = ["+=", "-=", "*=", "/=", "^=", "&=", "|=", "++", "--"];
			//	if (_op == "=") {
			//		nextToken(); // Consume the operator
					
			//		var expr = parseLogicalOrExpression();
			//		array_push(_new_args, expr);
			//		return new ASTNodes("FunctionCall", {callee: _setterFunc, arguments: _new_args});
			//	}
			//	else if (array_contains(__op_arr, _op)) {
			//		nextToken(); // Consume the operator
					
			//		// Determine the right-hand side expression based on the operator
			//		switch (_op) {
			//			case "+=": case "-=": case "*=": case "/=":
			//			case "^=": case "&=": case "|=":
			//			    right = parseLogicalOrExpression(); break;
			//			case "++": case "--":
			//			    right = new ASTNodes("Literal", {value: 1, scope: ScopeType.CONST}); break;
			//		}
					
			//		// Create binary expression node
			//		var adjustedOperator = string_copy(_op, 1, 1); // Remove = or adjust for ++/--
			//		var expr = new ASTNodes("BinaryExpression", {operator: adjustedOperator, left: _get_expr, right: right});
			//		array_push(_new_args, expr);
					
			//		// Return the setter function call with updated arguments
			//		return new ASTNodes("FunctionCall", {callee: _setterFunc, arguments: _new_args});
			//	}
			//	else {
			//		return _get_expr; // For unsupported operators or when no assignment is detected
			//	}
			//}
			
		    //return _get_expr;
		};
		#endregion
	}
#endregion

#region Optimizer.gml
	#region Optimizer Module
	/*
	Purpose: To refine the AST for better performance during interpretation.
	
	Methods:
	
	optimize(ast): Entry function that takes an AST and returns an optimized AST.
	constantFolding(ast): Traverses the AST and evaluates expressions that can be determined at compile-time.
	deadCodeElimination(ast): Removes parts of the AST that do not affect the program outcome, such as unreachable code.
	*/
	#endregion
	function GML_Optimizer() constructor {
		//init variables:
		
		ast = undefined;
		nodeStack = [];
		finished = false;
		
		static initialize = function(_ast) {
			ast = _ast;
			nodeStack = [];  // Stack to keep track of nodes to visit
			array_push(nodeStack, {node: ast, parent: undefined, key: undefined, index: undefined}) // Start with the root node
			finished = !array_length(nodeStack);
			currentNode = undefined;
		};
		
		static cleanup = function() {
		
		}
		
		static parseAll = function() {
			while (!finished) {
				nextNode();
			}
			return ast;
		}
		
		static nextNode = function() {
			if (!array_length(nodeStack)) {
				finished = true;
				return;
			}
		
		    // Get current node from the stack
			var currentNode = array_pop(nodeStack);
			
			// Process children first (post-order traversal)
			if (currentNode.node.visited == false) {
				currentNode.node.visited = true;
				
				array_push(nodeStack, currentNode);
				
				// Push current node back onto stack to process after children
				currentNode.node.push_children_to_node_stack(nodeStack);
			}
			else {
				// Process the current node as all children have been processed
				var _node = optimize(currentNode.node);
				_node.visited = false;
				
				if (currentNode.parent == undefined) {
					//the entire tree has been optimized and we are at the top most "Program" node
					if (array_length(nodeStack)) {
						throw_gmlc_error($"We still have nodes in the nodeStack, we shouldnt be finished")
					}
					
					finished = true;
					ast = _node;
				}
				else {
					//reset the visit so the next module can make use of it
					if (currentNode.index != undefined) {
						currentNode.parent[$ currentNode.key][currentNode.index] = _node;
					}
					else {
						currentNode.parent[$ currentNode.key] = _node;
					}
				}
				
			}
		};
		
		static optimize = function(_ast) {
			var _orig_ast = undefined;
			
			//keep optimizing until there are no optimizers which change the node.
			while (_ast != _orig_ast) {
				var _orig_ast = _ast
				_ast = constantFolding(_ast);
				//_ast = singleWriteOptimization(_ast);
				_ast = deadCodeElimination(_ast);
				//_ast = inlineFunctions(_ast);
				//_ast = optimizeLoops(_ast);
				_ast = optimizeAlternateFunctions(_ast);
				//_ast = variableHoisting(_ast);
			
				//_ast = tailCallOptimization(_ast);
				//_ast = commonSubexpressionElimination(_ast);
				//_ast = strengthReduction(_ast);
				//_ast = loopUnrolling(_ast);
				//_ast = branchPredictionHints(_ast);
				//_ast = lazyEvaluation(_ast);
				//_ast = memoryAccessOptimization(_ast);
			}
			
			return _ast;
		};
		
		#region Optimizers
		
		static constantFolding = function(node) {
			// Evaluate and simplify expressions with constant values
			
			// Recursive constant folding on child nodes first (if applicable)
			switch (node.type) {
				case "BinaryExpression":{
					if (node.left.type == "Literal" && node.right.type == "Literal") {
					    // Both nodes are literals, perform constant folding
					    switch (node.operator) {
							case "|":{
								return new ASTLiteral(node.left.value | node.right.value, node.line, node.lineString);
							break;}
							case "^":{
								return new ASTLiteral(node.left.value ^ node.right.value, node.line, node.lineString);
							break;}
							case "&":{
								return new ASTLiteral(node.left.value & node.right.value, node.line, node.lineString);
							break;}
							case "==":{
								return new ASTLiteral(node.left.value == node.right.value, node.line, node.lineString);
							break;}
							case "!=":{
								return new ASTLiteral(node.left.value != node.right.value, node.line, node.lineString);
							break;}
							case "<":{
								return new ASTLiteral(node.left.value < node.right.value, node.line, node.lineString);
							break;}
							case "<=":{
								return new ASTLiteral(node.left.value <= node.right.value, node.line, node.lineString);
							break;}
							case ">":{
								return new ASTLiteral(node.left.value > node.right.value, node.line, node.lineString);
							break;}
							case ">=":{
								return new ASTLiteral(node.left.value >= node.right.value, node.line, node.lineString);
							break;}
							case "<<":{
								return new ASTLiteral(node.left.value << node.right.value, node.line, node.lineString);
							break;}
							case ">>":{
								return new ASTLiteral(node.left.value >> node.right.value, node.line, node.lineString);
							break;}
							case "+":{
								return new ASTLiteral(node.left.value + node.right.value, node.line, node.lineString);
							break;}
							case "-":{
								return new ASTLiteral(node.left.value - node.right.value, node.line, node.lineString);
							break;}
							case "*":{
								return new ASTLiteral(node.left.value * node.right.value, node.line, node.lineString);
							break;}
							case "/":{
								return new ASTLiteral(node.left.value / node.right.value, node.line, node.lineString);
							break;}
							case "mod":{
								if (node.right.value == 0) {
									throw_gmlc_error($"DoMod :: Divide by zero")
								}
								return new ASTLiteral(node.left.value mod node.right.value, node.line, node.lineString);
							break;}
							case "div":{
								if (node.right.value == 0) {
									throw_gmlc_error($"DoRem :: Divide by zero")
								}
								return new ASTLiteral(node.left.value div node.right.value, node.line, node.lineString);
							break;}
						}
					}
				break;}
				case "LogicalExpression":{
					if (node.left.type == "Literal" && node.right.type == "Literal") {
					    switch (node.operator) {
							case "||":{
								return new ASTLiteral(node.left.value || node.right.value, node.line, node.lineString);
							break;}
							case "&&":{
								return new ASTLiteral(node.left.value && node.right.value, node.line, node.lineString);
							break;}
							case "^^":{
								return new ASTLiteral(node.left.value ^^ node.right.value, node.line, node.lineString);
							break;}
					    }
					}
					else if (node.left.type == "Literal" || node.right.type == "Literal") {
					    switch (node.operator) {
							case "||":{
								if (node.left.type  == "Literal" && node.left.value ) return new ASTLiteral(true, node.line, node.lineString);
								if (node.right.type == "Literal" && node.right.value) return new ASTLiteral(true, node.line, node.lineString);
							break;}
							case "&&":{
								if (node.left.type  == "Literal" && !node.left.value ) return new ASTLiteral(false, node.line, node.lineString);
								if (node.right.type == "Literal" && !node.right.value) return new ASTLiteral(false, node.line, node.lineString);
							break;}
					    }
					}
				break;}
				case "NullishExpression":{
					if (node.left.type == "Literal") {
						if (node.left.value == undefined) {
							return node.right;
						}
						else {
							return node.left;
						}
					}
				break;}
				case "UnaryExpression":{
					if (node.expr.type == "Literal") {
					    switch (node.operator) {
							case "!":{
								return new ASTLiteral(!node.expr.value, node.line, node.lineString);
							break;}
							case "+":{
								return new ASTLiteral(+node.expr.value, node.line, node.lineString);
							break;}
							case "-":{
								return new ASTLiteral(-node.expr.value, node.line, node.lineString);
							break;}
							case "~":{
								return new ASTLiteral(~node.expr.value, node.line, node.lineString);
							break;}
							case "++":{
								return new ASTLiteral(++node.expr.value, node.line, node.lineString);
							break;}
							case "--":{
								return new ASTLiteral(--node.expr.value, node.line, node.lineString);
							break;}
					    }
					}
				break;}
				case "ConditionalExpression":{
					if (node.condition.type == "Literal") {
					    // If the condition is a literal, determine which branch to take
						if (node.condition.value) {
							return node.trueExpr;
						}
						else {
							return node.falseExpr;
						}
					}
				break;}
				case "ExpressionStatement":{
					if (node.expr.type == "Literal") {
					    // If the condition is a literal, determine which branch to take
						return new ASTLiteral(node.expr.value, node.line, node.lineString);
					}
				break;}
				case "FunctionCall":{
					switch (node.callee.value) {
						case abs:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for abs is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(abs, node);
						break;}
						case angle_difference:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for angle_difference is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(angle_difference, node);
						break;}
						case ansi_char:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for ansi_char is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(ansi_char, node);
						break;}
						case arccos:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for arccos is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(arccos, node);
						break;}
						case arcsin:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for arcsin is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(arcsin, node);
						break;}
						case arctan:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for arctan is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(arctan, node);
						break;}
						case arctan2:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for arctan2 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(arctan2, node);
						break;}
						case buffer_sizeof:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for buffer_sizeof is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(buffer_sizeof, node);
						break;}
						case ceil:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for ceil is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(ceil, node);
						break;}
						case chr:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for chr is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(chr, node);
						break;}
						case clamp:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for clamp is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(clamp, node);
						break;}
						case color_get_blue:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for color_get_blue is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(color_get_blue, node);
						break;}
						case color_get_green:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for color_get_green is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(color_get_green, node);
						break;}
						case color_get_red:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for color_get_red is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(color_get_red, node);
						break;}
						case colour_get_blue:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for colour_get_blue is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(colour_get_blue, node);
						break;}
						case colour_get_green:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for colour_get_green is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(colour_get_green, node);
						break;}
						case colour_get_red:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for colour_get_red is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(colour_get_red, node);
						break;}
						case cos:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for cos is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(cos, node);
						break;}
						case darccos:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for darccos is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(darccos, node);
						break;}
						case darcsin:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for darcsin is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(darcsin, node);
						break;}
						case darctan:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for darctan is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(darctan, node);
						break;}
						case darctan2:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for darctan2 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(darctan2, node);
						break;}
						case dcos:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for dcos is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dcos, node);
						break;}
						case degtorad:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for degtorad is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(degtorad, node);
						break;}
						case dot_product:{
							if (array_length(node.arguments) != 4) {
								throw_gmlc_error($"Argument count for dot_product is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dot_product, node);
						break;}
						case dot_product_3d:{
							if (array_length(node.arguments) != 6) {
								throw_gmlc_error($"Argument count for dot_product_3d is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dot_product_3d, node);
						break;}
						case dot_product_3d_normalised:{
							if (array_length(node.arguments) != 6) {
								throw_gmlc_error($"Argument count for dot_product_3d_normalised is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dot_product_3d_normalised, node);
						break;}
						case dot_product_normalised:{
							if (array_length(node.arguments) != 4) {
								throw_gmlc_error($"Argument count for dot_product_normalised is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dot_product_normalised, node);
						break;}
						case dsin:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for dsin is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dsin, node);
						break;}
						case dtan:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for dtan is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dtan, node);
						break;}
						case exp:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for exp is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(exp, node);
						break;}
						case floor:{
							if (array_length(node.arguments) != XXX) {
								throw_gmlc_error($"Argument count for floor is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(floor, node);
						break;}
						case frac:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for frac is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(frac, node);
						break;}
						case int64:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for int64 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(int64, node);
						break;}
						case is_array:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_array is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_array, node);
						break;}
						case is_bool:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_bool is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_bool, node);
						break;}
						case is_callable:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_callable is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_callable, node);
						break;}
						case is_handle:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_handle is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_handle, node);
						break;}
						case is_infinity:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_infinity is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_infinity, node);
						break;}
						case is_int32:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_int32 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_int32, node);
						break;}
						case is_method:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_method is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_method, node);
						break;}
						case is_nan:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_nan is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_nan, node);
						break;}
						case is_numeric:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_numeric is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_numeric, node);
						break;}
						case is_ptr:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_ptr is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_ptr, node);
						break;}
						case is_struct:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_struct is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_struct, node);
						break;}
						case is_undefined:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_undefined is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_undefined, node);
						break;}
						case lengthdir_x:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for lengthdir_x is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(lengthdir_x, node);
						break;}
						case lengthdir_y:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for lengthdir_y is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(lengthdir_y, node);
						break;}
						case lerp:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for lerp is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(lerp, node);
						break;}
						case ln:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for ln is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(ln, node);
						break;}
						case log10:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for log10 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(log10, node);
						break;}
						case log2:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for log2 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(log2, node);
						break;}
						case logn:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for logn is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(logn, node);
						break;}
						case make_color_rgb:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for make_color_rgb is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(make_color_rgb, node);
						break;}
						case make_colour_rgb:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for make_colour_rgb is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(make_colour_rgb, node);
						break;}
						case max:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for max is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(max, node);
						break;}
						case mean:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for mean is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(mean, node);
						break;}
						case median:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for median is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(median, node);
						break;}
						case min:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for min is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(min, node);
						break;}
						case object_exists:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for object_exists is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(object_exists, node);
						break;}
						case object_get_name:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for object_get_name is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(object_get_name, node);
						break;}
						case object_get_parent:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for object_get_parent is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(object_get_parent, node);
						break;}
						case object_get_physics:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for object_get_physics is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(object_get_physics, node);
						break;}
						case object_is_ancestor:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for object_is_ancestor is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(object_is_ancestor, node);
						break;}
						case ord:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for ord is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(ord, node);
						break;}
						case os_get_config:{
							return __build_literal_from_function_call_constant_folding(os_get_config, node);
						break;}
						case point_direction:{
							if (array_length(node.arguments) != 4) {
								throw_gmlc_error($"Argument count for point_direction is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(point_direction, node);
						break;}
						case point_distance:{
							if (array_length(node.arguments) != 4) {
								throw_gmlc_error($"Argument count for point_distance is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(point_distance, node);
						break;}
						case point_distance_3d:{
							if (array_length(node.arguments) != 6) {
								throw_gmlc_error($"Argument count for point_distance_3d is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(point_distance_3d, node);
						break;}
						case power:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for power is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(power, node);
						break;}
						case radtodeg:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for radtodeg is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(radtodeg, node);
						break;}
						case real:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for real is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(real, node);
						break;}
						case round:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for round is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(round, node);
						break;}
						case script_exists:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for script_exists is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(script_exists, node);
						break;}
						case script_get_name:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for script_get_name is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(script_get_name, node);
						break;}
						case sign:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for sign is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(sign, node);
						break;}
						case sin:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for sin is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(sin, node);
						break;}
						case sqr:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for sqr is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(sqr, node);
						break;}
						case sqrt:{
							/// ==================================================
							/// NOTE:
							/// This is the only math operation that is affected by `math_set_epsilon`
							/// avoid optimizing this at compile time
							/// ==================================================
							return node
						break;}
						case string_lower:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_lower is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_lower, node);
						break;}
						case string_upper:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_upper is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_upper, node);
						break;}
						case string_repeat:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_repeat is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_repeat, node);
						break;}
						case tan:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for tan is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(tan, node);
						break;}
						
						//organize these later....
						
						case code_is_compiled:{
							return __build_literal_from_function_call_constant_folding(code_is_compiled, node);
						break;}
						case string_byte_length:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_byte_length is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_byte_length, node);
						break;}
						case string_char_at:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_char_at is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_char_at, node);
						break;}
						case string_concat_ext:{
							if (array_length(node.arguments) >= 1)
							&& (array_length(node.arguments) <= 3) {
								throw_gmlc_error($"Argument count for string_concat_ext is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_concat_ext, node);
						break;}
						case string_copy:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_copy is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_copy, node);
						break;}
						case string_count:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_count is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_count, node);
						break;}
						case string_delete:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_delete is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_delete, node);
						break;}
						case string_digits:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_digits is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_digits, node);
						break;}
						case string_ends_with:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_ends_with is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_ends_with, node);
						break;}
						case string_ext:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_ext is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_ext, node);
						break;}
						case string_format:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_format is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_format, node);
						break;}
						case string_hash_to_newline:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_hash_to_newline is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_hash_to_newline, node);
						break;}
						case string_insert:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_insert is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_insert, node);
						break;}
						case string_join_ext:{
							if (array_length(node.arguments) >= 2)
							&& (array_length(node.arguments) <= 4) {
								throw_gmlc_error($"Argument count for string_join_ext is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_join_ext, node);
						break;}
						case string_last_pos:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_last_pos is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_last_pos, node);
						break;}
						case string_last_pos_ext:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_last_pos_ext is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_last_pos_ext, node);
						break;}
						case string_length:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_length is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_length, node);
						break;}
						case string_letters:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_letters is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_letters, node);
						break;}
						case string_ord_at:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_ord_at is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_ord_at, node);
						break;}
						case string_pos:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_pos is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_pos, node);
						break;}
						case string_pos_ext:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_pos_ext is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_pos_ext, node);
						break;}
						case string_replace:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_replace is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_replace, node);
						break;}
						case string_replace_all:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_replace_all is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_replace_all, node);
						break;}
						case string_set_byte_at:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_set_byte_at is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_set_byte_at, node);
						break;}
						case string_starts_with:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_starts_with is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_starts_with, node);
						break;}
						case string_trim:{
							if (array_length(node.arguments) >= 1)
							&& (array_length(node.arguments) <= 2) {
								throw_gmlc_error($"Argument count for string_trim is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_trim, node);
						break;}
						case string_trim_end:{
							if (array_length(node.arguments) >= 1)
							&& (array_length(node.arguments) <= 2) {
								throw_gmlc_error($"Argument count for string_trim_end is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_trim_end, node);
						break;}
						case string_trim_start:{
							if (array_length(node.arguments) >= 1)
							&& (array_length(node.arguments) <= 2) {
								throw_gmlc_error($"Argument count for string_trim_start is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_trim_start, node);
						break;}
						case md5_string_unicode:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for md5_string_unicode is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(md5_string_unicode, node);
						break;}
						case md5_string_utf8:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for md5_string_utf8 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(md5_string_utf8, node);
						break;}
						case color_get_hue:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for color_get_hue is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(color_get_hue, node);
						break;}
						case colour_get_hue:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for colour_get_hue is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(colour_get_hue, node);
						break;}
						case color_get_saturation:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for color_get_saturation is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(color_get_saturation, node);
						break;}
						case colour_get_saturation:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for colour_get_saturation is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(colour_get_saturation, node);
						break;}
						case color_get_value:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for color_get_value is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(color_get_value, node);
						break;}
						case colour_get_value:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for colour_get_value is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(colour_get_value, node);
						break;}
						case base64_encode:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for base64_encode is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(base64_encode, node);
						break;}
						case base64_decode:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for base64_decode is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(base64_decode, node);
						break;}
						case sha1_string_utf8:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for sha1_string_utf8 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(sha1_string_utf8, node);
						break;}
						case sha1_string_unicode:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for sha1_string_unicode is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(sha1_string_unicode, node);
						break;}
						case make_color_hsv:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for make_color_hsv is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(make_color_hsv, node);
						break;}
						case make_colour_hsv:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for make_colour_hsv is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(make_colour_hsv, node);
						break;}
						
						
						//all of the ones above use the same code
						case string:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for string is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							if (__argumentsAreLiteral(node.arguments)) {
								return __build_literal_from_function_call_constant_folding(string_lower, node);
							}
							else if (node.arguments[0].type == __GMLC_NodeType.Literal) {
								var _exec_arr = [_arr[0].value]; //the execution array
								var _new_arr = []; // the new arg array
								var _holder_index = 0;
								var _changed = false;
								
								var _i=1; repeat(array_length(_arr)-1) {
									if (_arr[_i].type == __GMLC_NodeType.Literal) {
										_changed = true;
										array_push(_exec_arr, _arr[_i].value);
									}
									else {
										array_push(_new_arr, _arr[_i].value);
										array_push(_exec_arr, $"\{{_holder_index}\}");
										_holder_index++
									}
								_i+=1;}//end repeat loop
								
								if (_changed) {
									array_insert(_new_arr, 0, script_execute_ext(string, _exec_arr))
									return new ASTCallExpression(node.callee, _new_arr);
								}
							}
						break;}
						case string_concat:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for string_concat is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							
							if (__argumentsAreLiteral(node.arguments)) {
								return __build_literal_from_function_call_constant_folding(string_concat, node);
							}
							else {
								var _arr = node.arguments;
								var _changed = false;
							
								var _i=0; repeat(array_length(_arr)-1) {
									if (_arr[_i].type == __GMLC_NodeType.Literal)
									&& (_arr[_i+1].type == __GMLC_NodeType.Literal) {
										_changed = true;
										var _struct = new ASTLiteral(string_concat(_arr[_i].value, _arr[_i+1].value), _arr[_i].line, _arr[_i].lineString)
										array_delete(_arr, _i, 2)
										array_insert(_arr, _i, _struct);
										continue;
									}
								_i+=1;}//end repeat loop
								
								if (_changed) {
									return new ASTNodes("FunctionCall", {callee: node.callee, arguments: _arr});
								}
							}
							
						break;}
						case string_join:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for string_join is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							
							if (__argumentsAreLiteral(node.arguments)) {
								return __build_literal_from_function_call_constant_folding(string_join, node);
							}
							else if (node.arguments[0].type == __GMLC_NodeType.Literal) {
								var _arr = node.arguments;
								var _changed = false;
								
								var _i=1; repeat(array_length(_arr)-1) {
									if (_arr[_i].type == __GMLC_NodeType.Literal)
									&& (_arr[_i+1].type == __GMLC_NodeType.Literal) {
										_changed = true;
										var _struct = new ASTLiteral(string_join(_arr[0], _arr[_i].value, _arr[_i+1].value), _arr[_i].line, _arr[_i].lineString);
										array_delete(_arr, _i, 2)
										array_insert(_arr, _i, _struct);
										continue;
									}
								_i+=1;}//end repeat loop
								
								if (_changed) {
									return new ASTCallExpression(node.callee, _arr);
								}
							}
							
						break;}
						
					}
				break;}
				// Add more cases as needed for different node types
			}
			
			return node;
		};
		
		static singleWriteOptimization = function(node) {
			// Replace single-assignment variables with their values
			// this essentially acts as a constant value.
			
		};
		
		static deadCodeElimination = function(node) {
			// Remove unnecessary nodes
			switch (node.type) {
				case "IfStatement":{
					if (node.condition.type == "Literal") {
						if (node.condition.value) {
							return node.consequent;
						}
						else {
							if (node.alternate != undefined) {
								return node.alternate;
							}
							else {
								return new ASTNodes("BlockStatement", {statements: []})
							}
						}
					}
				break;}
				case "ForStatement":{
					if (node.condition.type == "Literal") {
						if (!node.condition.value) {
							return new ASTNodes("BlockStatement", {statements: []})
						}
					}
				break;}
				case "WhileStatement":{
					if (node.condition.type == "Literal") {
						if (!node.condition.value) {
							return new ASTNodes("BlockStatement", {statements: []})
						}
					}
				break;}
				case "RepeatStatement":{
					if (node.condition.type == "Literal") {
						if (!node.condition.value) {
							return new ASTNodes("BlockStatement", {statements: []})
						}
					}
				break;}
				case "DoUntillStatement":{
					if (node.condition.type == "Literal") {
						if (!node.condition.value) {
							return new ASTNodes("BlockStatement", {statements: []})
						}
					}
				break;}
				case "WithStatement":{
					if (node.condition.type == "Literal") {
						if (node.condition.value == noone) {
							return new ASTNodes("BlockStatement", {statements: []})
						}
					}
				break;}
				case "SwitchStatement":{
					if (node.switchExpression.type == "Literal") {
						var _val = node.switchExpression.value;
						var _found_case = false;
						var _found_break = false;
						var _return = node;
						
						var _i=0; repeat(array_length(node.cases)) {
							var _case = node.cases[_i]
							
							if (_case.type == "CaseExpression" && _case.label == _val)
							|| (_case.type == "CaseDefault") {
								_found_case = true;
								var _statements = []
								_return = new ASTNodes("BlockStatement", {statements: _statements});
								break;
							}
							
							if (_found_case) {
								var _arr = _case.codeBlock.statements;
								var _j=0; repeat(array_length(_arr)) {
									var _statement = _arr[_j]
									if (_statement.type == "BreakStatement") {
										_found_break = true;
										break;
									}
									
									array_push(_statements, _statement);
									
								_j+=1;}//end repeat loop
								
								if (_found_break) {
									break;
								}
								
							}
							
						_i+=1;}//end repeat loop
						
						return _return;
					}
				break;}
				case "ConditionalExpression":{
					if (node.condition.type == "Literal") {
					    // If the condition is a literal, determine which branch to take
						return (node.condition.value) ? node.trueExpr : node.falseExpr;
					}
				break;}
			}
			
			return node;
		};
		
		static inlineFunctions = function(node) {
			// Inline functions that are marked for inlining
		};
		
		static optimizeLoops = function(node) {
			// Convert certain for-loops to repeat-loops where applicable
		};
		
		static optimizeAlternateFunctions = function(node) {
			// Convert struct access using literals to hashed access
			//new ASTNode(Function, {value: currentToken.value, name: currentToken.name})
			if (node.type == "FunctionCall") {
				switch (node.callee.value) {
					case struct_get:
					case variable_struct_get:{
						// Convert struct access using literals to hashed access
						var _arg = node.arguments[1];
						if (_arg.type == "Literal") 
						&& (typeof(_arg.value) == "string") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: struct_get_from_hash, name: "struct_get_from_hash"}),
								arguments: [
									node.arguments[0],
									new ASTNodes("Literal", {value: variable_get_hash(_arg.value), scope: ScopeType.CONST})
								]
							});
						}
					break;}
						
					case struct_set:
					case variable_struct_set:{
						// Convert struct access using literals to hashed access
						var _arg = node.arguments[1];
						if (_arg.type == "Literal") 
						&& (typeof(_arg.value) == "string") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: struct_set_from_hash, name: "struct_set_from_hash"}),
								arguments: [
									node.arguments[0],
									new ASTNodes("Literal", {value: variable_get_hash(_arg.value), scope: ScopeType.CONST}),
									node.arguments[2]
								]
							});
						}
					break;}
					
					case string:{
						// String with single argument is faster to use string_concat
						if (array_length(node.arguments) == 1) {
							var _arg = node.arguments[0]
							if (_arg.type != "Literal") {
								return new ASTNodes("FunctionCall", {
									callee: new ASTNodes("Function", {value: string_concat, name: "string_concat"}),
									arguments: node.arguments
								});
							}
						}
					break;}
				}
			}
			
			return node;
		};
		
		static variableHoisting = function(node) {
			// Hoist and variable declarations (specifically outside of loops when ever possible)
		};
		
		static commonSubexpressionElimination = function(node) {
			// Eliminate duplicate expressions by reusing the result stored in a temporary variable
		};
		
		static strengthReduction = function(node) {
			// Replace expensive operations with cheaper ones
		};
		
		static loopUnrolling = function(node) {
			// Explicitly expand loop iterations to decrease loop overhead
		};
		
		static branchPredictionHints = function(node) {
			// Provide hints to optimize CPU branch prediction
		};
		
		static lazyEvaluation = function(node) {
			// Delay the evaluation of expressions until their results are needed
		};
		
		#endregion
		
		#region Helper Functions
		static __argumentsAreLiteral = function(_arguments) {
			var _i=0; repeat(array_length(_arguments)) {
				if (_arguments[_i].type != __GMLC_NodeType.Literal) {
					return false;
				}
			_i+=1;}//end repeat loop
			return true;
		}
		
		static __build_literal_from_function_call_constant_folding = function(_script, node) {
			if (!__argumentsAreLiteral(node.arguments)) return node;
								
			//remap the arguments
			var _arr = node.arguments;
			var _new_arr = [];
			var _i=0; repeat(array_length(_arr)) {
				_new_arr[_i] = _arr[_i].value;
			_i+=1;}//end repeat loop
			
			return new ASTLiteral(script_execute_ext(_script, _new_arr), node.line, node.lineString);
		}
		
		#endregion
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
function __determineScopeType(_node) {
	gml_pragma("forceinline");
	
	var _scope = _node.scope;
	if (_scope == undefined) {
		return __find_ScopeType_from_string(_node.value);
	}
	return _scope
}
/// @ignore
function __find_ScopeType_from_string(_string) {
	gml_pragma("forceinline");
	// Ordered in priority
	
	//ScopeType.MACRO;
	//ScopeType.GLOBAL;
	//ScopeType.ENUM;
	//ScopeType.UNIQUE;
	//ScopeType.LOCAL;
	//ScopeType.STATIC;
	//ScopeType.SELF;
	//ScopeType.CONST;
	
	if array_contains(currentScript.MacroVarNames, _string) return ScopeType.MACRO;
	if array_contains(currentScript.GlobalVarNames, _string) return ScopeType.GLOBAL;
	if struct_exists(currentScript.EnumVarNames, _string) return ScopeType.ENUM;
	
	
	// Asset Handling
	//NOTE: replace this with an asset look up table built into the build environment later, for API usage as a
	// modding tool to prevent users from messing with the source code too much
	var _index = asset_get_index(_string);
	var _type = asset_get_type(_string)
	if (_index != asset_script) && (_index > -1) {
		return ScopeType.CONST;
	}
	
	
	if (currentFunction != undefined) {
		if array_contains(currentFunction.LocalVarNames,  _string) return ScopeType.LOCAL;
		if array_contains(currentFunction.StaticVarNames, _string) return ScopeType.STATIC;
	}
	else {
		if array_contains(currentScript.LocalVarNames, _string) return ScopeType.LOCAL;
	}
	
	return ScopeType.SELF;  // Default to instance if scope is unknown
	
}
/// @ignore
function array_insert_ext(array, index, arr_of_val, offset=0, length=max(array_length(arr_of_val)-offset, 0)) {
	static __args = [];
	if (length == 0) return;
	array_resize(__args, length);
	array_copy(__args, 0, arr_of_val, offset, length);
	array_insert(__args, 0, array, index);
	return script_execute_ext(array_insert, __args);
}
#endregion


