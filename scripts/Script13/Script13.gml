/// @desc
/// @feather ignore all


#macro GML_COMPILER_GM1_4 false
/* allows for
// #define
// multiline strings with out @ accessor
// single quote strings 'example'
// hashtags in strings represent newlines
// array 2d `arr[x, y]`
*/

#macro GML_COMPILER_DEBUG false

#region AST.gml
	
	
#endregion

#region Languages
/// @desc Converts CSV data from a file into a language struct
/// @arg filename

function loadLanguageFromCSV(filename) {
	var file_grid = load_csv(filename);  // Load the CSV into a DS grid
	var languageStruct = {};  // Create a new map to hold the language mappings
	
	var ww = ds_grid_width(file_grid);
	var hh = ds_grid_height(file_grid);
	
	// Iterate over rows, assuming the first row contains keys and the second row contains values
	if (hh > 1) {  // Check if there are at least two rows
		for (var i = 1; i < hh; i++) {
			var key = file_grid[# 0, i];  // The key is in the first row
			var value = file_grid[# 2, i];  // The value is in the second row
			languageStruct[$ key] = value;  // Add to the struct
		}
	}
	
	ds_grid_destroy(file_grid);  // Clean up the DS grid to free memory
	return languageStruct;  // Return the populated language struct
}

#endregion

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
#region Token Enum
enum tok {
	eAnd, // &&
	eArrayClose, // ]
	eArrayOpen, // [
	eAssign, // =
	eAssignMinus, // -=
	eAssignOr, // |=
	eAssignPlus, // +=
	eBegin, // {
	eBinary, // 
	eBitAnd, // &
	eBitNegate, // ~
	eBitOr, // |
	eBitShiftLeft, // <<
	eBitXor, // ^
	eBlock, // used to declare a block statement, an array of statements
	eBreak, // break keyword
	eCase, // case keyword
	eCatch, // catch keyword
	eClose, // )
	eConditional, // ?
	eConstant, // any constant variable
	eContinue, // continue keyword
	eDefault, // default keyword
	eDiv, // div keyword
	eDivide, // /
	eDot, // .
	eEOF, // marks the end of a file
	eElse, // else keyword
	eEnd, // }
	eEnum, // enum keyword
	eEqual, // =
	eFinally, // finally keyword
	eFor, // for keyworf
	eFunction, // function; as in just a function it's self
	eFunctionDecl, // `function` keyword
	eGreater, // >
	eGreaterEqual, // >=
	eGridArrayOpen, // [#
	eIf, // if keyword
	eLabel, // :
	eLess, // <
	eLessEqual, // <=
	eMinus, // -
	eMod, // % or mod
	eName, // any unidentified text thus far
	eNew, // new keyword
	eNot, // !
	eNotEqual, // !=
	eNullCoalesce, // ??
	eNullCoalesceAssign, // ??=
	eNumber, // any number declaration `1` `$FF` `0xFF` `0b1111`
	eOpen, // (
	eOr, // ||
	ePlus, // +
	ePlusPlus, // ++
	ePost, // ++ (also) but used for the second pass
	eRepeat, // repeat keyword
	eReturn, // return keyword
	eSepArgument, // ,
	eSepStatement, // ;
	eStatic, // static keyword
	eString, // any string literal @"example", @'example', "example"
	eStructArrayOpen, // [$
	eSwitch, // switch keyword
	eTemplateString, // the mark of a template string
	eThrow, // throw keyword
	eTime, // *
	eTry, // try keyword
	eUnary, // ~ ! - +, this is only applied on second pass when building the ast
	eVar, // var keyword
	eVariable, // 
	eVariableSimple, // 
	eWhile, // while keyword
	eWith, // with keyword
	eXor, // ^^
}
//enum __GMLC_TokenType {
//	Whitespace,
//	Identifier,
//	Number,
//	Operator,
//	Keyword,
//	Function,
//	Punctuation,
//
//	UniqueVariable, //things like `argument`, `argument0`, `current_day`, etc.
//	
//	String,
//	TemplateString,
//	
//	EscapeOperator,
//	
//	Comment,
//	
//	Macro,
//	Region,
//	Enum,
//	
//	Illegal,
//	SIZE
//}

//used for debugging
function __GMLC_TokenType() {
	static Whitespace = "__GMLC_TokenType.Whitespace";
	static Identifier = "__GMLC_TokenType.Identifier";
	static Number = "__GMLC_TokenType.Number";
	static Operator = "__GMLC_TokenType.Operator";
	static Keyword = "__GMLC_TokenType.Keyword";
	static Function = "__GMLC_TokenType.Function";
	static Punctuation = "__GMLC_TokenType.Punctuation";
	
	static UniqueVariable = "__GMLC_TokenType.UniqueVariable";
	
	static String = "__GMLC_TokenType.String";
	static TemplateString = "__GMLC_TokenType.TemplateString";
	
	static EscapeOperator = "__GMLC_TokenType.EscapeOperator";
	
	static Comment = "__GMLC_TokenType.Comment";
	
	static Macro = "__GMLC_TokenType.Macro";
	static Region = "__GMLC_TokenType.Region";
	static Enum = "__GMLC_TokenType.Enum";
	static Define = "__GMLC_TokenType.Define";
	
	static Illegal = "__GMLC_TokenType.Illegal";
	
	static SIZE = "SIZE"
}
__GMLC_TokenType();

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
	
	keywords = ["globalvar", "var", "if", "then", "else", "begin", "end", "for", "while", "do", "until", "repeat", "switch", "case", "default", "break", "continue", "with", "exit", "return", "global", "mod", "div", "not", "and", "or", "xor", "enum", "function", "new", "constructor", "static", "region", "endregion", "macro", "try", "catch", "finally", "define", "throw"];
	language_struct = loadLanguageFromCSV("english.csv");
	
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
					show_debug_message($"{real(_str)*1000}% Finished")
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
			
			if (__char_is_whitespace(currentCharCode) || currentCharCode == ord(";")) {
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
		
		if (_char == ord("/") && _next_char == ord("/")) {
			return tokenizeCommentLine();
		}
		else if (_char == ord("/") && _next_char == ord("*")) {
			return tokenizeCommentBlock();
		}
		else if (_char == ord(@'"')) {
			return tokenizeStringLiteral();
		}
		else if (_char == ord("$") && __char_is_hex(_next_char)) || (_char == ord("0") && _next_char == ord("x")) {
			return tokenizeHexNumber();
		}
		else if (_char == ord("$") && _next_char == ord(@'"')) {
			return tokenizeTemplateString();
		}
		else if (_char == ord("0") && _next_char == ord("b")) {
			return tokenizeBinaryNumber();
		}
		else if (__char_is_digit(_char)) || (_char == ord(".") && __char_is_digit(_next_char)) {
			return tokenizeNumber();
		}
		else if (__char_is_alphabetic(_char)) {
			return tokenizeIdentifier();
		}
		else if (_char == ord("@") && (_next_char == ord("'") || _next_char == ord(@'"'))) {
			return tokenizeRawStringLiteral();
		}
		else if (__char_is_operator(_char)) {
			return tokenizeOperator();
		}
		else if (__char_is_punctuation(_char)) {
			return tokenizePunctuation();
		}
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
		
		var _number = real(string_replace_all(_num_string, "_", ""));
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
			throw $"\nEntered 'tokenizeHexNumber' with a non-valid entry string : {chr(_char)}"
		}
		
		var _len = 0;
		var _hex_value = 0;
		while (currentCharCode != undefined && __char_is_hex(currentCharCode)) {
			_hex_value = _hex_value << 4;
			
			if (currentCharCode >= ord("0") && currentCharCode <= ord("9")) {
				_hex_value += currentCharCode - ord("0");
			}
			else if (currentCharCode >= ord("A") && currentCharCode <= ord("F")) {
				_hex_value += currentCharCode - ord("A") + 10;
			}
			else if (currentCharCode >= ord("a") && currentCharCode <= ord("f")) {
				_hex_value += currentCharCode - ord("a") + 10;
			}
			
			_raw_string += chr(currentCharCode);
			_len += 1;
			__nextUTF8();
		}
		
		#region Error Handling
		if (_len > 16) {
			var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {_start_line} : Hex number {_raw_string} is too large or too small";
			var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column);
			return _token;
		}
		
		if (_hex_value < 0) {
			var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {_start_line} : Hex number {_raw_string} is too large or too small";
			var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column);
			return _token;
		}
		#endregion
		
		_hex_value = (_hex_value <= $FFFFFFF) ? real(_hex_value) : int64(_hex_value);
		
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
			throw $"\nEntered 'tokenizeBinaryNumber' with a non-valid entry string : {chr(_char)}"
		}
		
		var _len = 0;
		var _binary_value = 0;
		while (currentCharCode != undefined && __char_is_binary(currentCharCode)) {
			_binary_value = _binary_value << 1;
			
			_binary_value += currentCharCode - ord("0");
			
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
		if (_binary_value < 0) {
			var _error = $"Object: \{<OBJ>\} Event: \{<EVENT>\} at line {line} : Binary number {_raw_string} is too large or too small";
			var _token = new __GMLC_create_token(__GMLC_TokenType.Illegal, _raw_string, _error, _start_line, _start_column);
			return _token;
		}
		#endregion
		
		_binary_value = (_binary_value <= 0b1111111111111111111111111111111) ? real(_binary_value) : int64(_binary_value);
		
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
		
		#region Functions
		
		var _index = asset_get_index(_identifier);
		if (_index > -1) {
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
		
		//static __enum_header_arr = __ExistingEnumerationHeaderStrings();
		//if (array_contains(__enum_header_arr, _identifier)) {
		//	
		//	static __enum_arr = __ExistingEnumerationStrings();
		//	var _i=0; repeat(array_length(__enum_arr)) {
		//		
		//		var _enum = __enum_arr[_i];
		//		if (string_pos_ext(_enum, sourceCodeString, start) == start) {
		//			static __enum_lookup = __ExistingEnumerations();
		//			var _val = struct_get(__enum_lookup, _enum)
		//			
		//			var _token = new __GMLC_create_token(__GMLC_TokenType.Number, _enum, _val, _start_line, _start_column);
		//			return _token;
		//		}
		//		
		//	_i+=1;}//end repeat loop
		//}
		
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
		/*
		// micro optimization
		static __mappingStruct = {
			"true": 1,
			"false": 2,
			"infinity": 3,
			"undefined": 4,
			"NaN": 5,
		}
		switch (__mappingStruct[$ _identifier]) {
			case 1 : return new __GMLC_create_token(__GMLC_TokenType.Identifier, "true", true, _start_line, _start_column);
			case 2 : return new __GMLC_create_token(__GMLC_TokenType.Identifier, "false", false, _start_line, _start_column);
			case 3 : return new __GMLC_create_token(__GMLC_TokenType.Identifier, "infinity", infinity, _start_line, _start_column);
			case 4 : return new __GMLC_create_token(__GMLC_TokenType.Identifier, "undefined", undefined, _start_line, _start_column);
			case 5 : return new __GMLC_create_token(__GMLC_TokenType.Identifier, "NaN", NaN, _start_line, _start_column);
			default: return new __GMLC_create_token(__GMLC_TokenType.Identifier, _identifier, _identifier, _start_line, _start_column);
		}
		/*/
		if (_identifier == "true")           return new __GMLC_create_token(__GMLC_TokenType.Identifier, "true", true, _start_line, _start_column);
		else if (_identifier == "false")     return new __GMLC_create_token(__GMLC_TokenType.Identifier, "false", false, _start_line, _start_column);
		else if (_identifier == "infinity")  return new __GMLC_create_token(__GMLC_TokenType.Identifier, "infinity", infinity, _start_line, _start_column);
		else if (_identifier == "undefined") return new __GMLC_create_token(__GMLC_TokenType.Identifier, "undefined", undefined, _start_line, _start_column);
		else if (_identifier == "NaN")       return new __GMLC_create_token(__GMLC_TokenType.Identifier, "NaN", NaN, _start_line, _start_column);
		
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
				throw $"\nEntered 'tokenizeOperator' with a non-valid entry string : {chr(currentCharCode)}"
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
	
	static tokenizeTemplateString = function() {
		var _char = currentCharCode;
		var _start_pos = charPos;
		var _start_line = line;
		var _start_column = column;
		
		//unfinished
		
		var _name = string_copy(sourceCode, start, charPos - start);
		var _token = new __GMLC_create_token(__GMLC_TokenType.TemplateString, _name, tokens, _orig_line, _orig_column);
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
	
	#region unused
	//static tokenizeMacro = function() {
	//	var start = charPos;
	//	var _orig_line = line;
	//	var _orig_column = column;
			
	//	charPos += 6; // Skip the '#macro' keyword itself, assuming '#macro' was already detected
	//	column += 6;
		
	//	var _name = string_copy(sourceCode, start, charPos - start);
	//	var _token = new __GMLC_create_token(__GMLC_TokenType.Macro, "#macro", "#macro", _orig_line, _orig_column);
	//	return _token;
	//};
	
	//static tokenizeEnum = function() {
	//	var start = charPos;
	//	var _orig_line = line;
	//	var _orig_column = column;
			
	//	charPos += 4; // Skip the 'enum' keyword itself, assuming 'enum' was already detected
	//	column += 4;
		
	//	var _name = string_copy(sourceCode, start, charPos - start);
	//	var _token = new __GMLC_create_token(__GMLC_TokenType.Enum, __GMLC_TokenType.Enum, __GMLC_TokenType.Enum, _orig_line, _orig_column);
	//	return _token;
	//};
	
	//static tokenizeRegion = function() {
	//	var start = charPos;
	//	var _orig_line = line;
	//	var _orig_column = column;
		
	//	var _type = undefined;
		
	//	var _char = string_char_at(sourceCode, charPos+1);
	//	if (_char == "r") {
	//		//skip #region
	//		charPos += 7;
	//		column += 7;
	//		_type = "#region"
	//		//skip the comment block of the region
	//		var _dist = string_pos_ext("\n", sourceCode, charPos) - charPos;
	//		charPos += _dist;
	//		column += _dist;
	//	}
	//	else if (_char == "e") {
	//		//skip #endregion
	//		charPos += 10;
	//		column += 10;
	//		_type = "#endregion"
	//	}
	//	else {
	//		throw "\naww fuck"
	//	}
		
	//	var _name = string_copy(sourceCode, start, charPos - start);
	//	var _token = new __GMLC_create_token(__GMLC_TokenType.Region, _name, _type, _orig_line, _orig_column);
	//	return _token;
	//};
	
	//static tokenizeDefine = function() {
	//	var start = charPos;
	//	var _orig_line = line;
	//	var _orig_column = column;
			
	//	charPos += 7; // Skip the '#macro' keyword itself, assuming '#macro' was already detected
	//	column += 7;
		
	//	var _name = string_copy(sourceCode, start, charPos - start);
	//	var _token = new __GMLC_create_token(__GMLC_TokenType.Define, "#define", "#define", _orig_line, _orig_column);
	//	return _token;
	//};
	
	#endregion
	
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
		throw "please use character code instead of a string"
	}
		
	if (currentCharCode != _ord) {
		throw $"\n\nExpected '{_ord} ({chr(_ord)})', got '{currentCharCode} ({chr(currentCharCode)})'";
	}
		
	__nextUTF8();
}
	
function __optionalUTF8(_ord) {
	gml_pragma("forceinline");
	if is_string(_ord) {
		throw "please use character code instead of a string"
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
					show_debug_message($"{real(_str)*1000}% Finished")
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
			throw $"\n\nExpected '{expectedValue}', got '{currentToken}'";
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
		
		// Ensure the current token is 'enum'
		expectToken(__GMLC_TokenType.Keyword, "enum")
		
		if (currentToken.type != __GMLC_TokenType.Identifier) {
			throw $"\nEnum Declaration expecting Identifier, got :: {currentToken}";
		}
		
		enumName = currentToken.value;  // Next token should be the enum name
		var _enum_struct = {};
		
		nextToken(); // skip enum name
		skipWhitespaces() // such as optional line breaks
		expectToken(__GMLC_TokenType.Punctuation, "{") // Expecting a '{' to start the enum block
		
		optionalToken(__GMLC_TokenType.Whitespace, "\n");
		
		var _length = array_length(tokens);
		while (currentTokenIndex < _length && currentToken.value != "}") {
			skipWhitespaces();
			
			if (currentToken.type != __GMLC_TokenType.Identifier) {
				throw $"\nEnum.Key Declaration expecting Identifier, got :: {currentToken}";
			}
			
			memberName = currentToken.value;
			array_push(enumMembers, memberName)
			nextToken(); // Move past the member name
			
			// Check for '=' to see if a value is assigned
			if (currentToken.value == "=") {
				nextToken(); // Move past '='
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
		nextToken(); // Move past '}'
		
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
		
		language_struct = loadLanguageFromCSV("english.csv");
		
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
			
			// Note this function isn't actually async, so if there is a module with tons of lines of code its possible for this to cause lag.
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
				var statement = parseStatement();
				if (statement) {
					array_push(scriptAST.statements, statement);
				}
				
				if (GML_COMPILER_DEBUG) {
					static __lastString = ""
					var _str = string(currentTokenIndex/array_length(tokens)/10)
					if (__lastString != _str) {
						show_debug_message($"{real(_str)*1000}% Finished")
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
					throw $"Recursive Macro or Enum Declaration detected! Quitting"
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
				case "throw":		return parseThrowStatement();
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
				default:			return parseExpressionStatement();  // Assume any other token starts an expression statement
			}
		};
		
		static parseBlock = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			if (currentToken.value == "{") {
				nextToken(); // Consume the '{'
				var _statements = [];
				while (currentToken != undefined && currentToken.value != "}") {
					var _statement = parseStatement();
					array_push(_statements, _statement);
					// Parse each statement until '}' is found
					// Optional: Handle error checking for unexpected end of file
				}
				nextToken(); // Consume the '}'
				return new ASTBlockStatement(_statements, line, lineString); // Return a block statement containing all parsed statements
			}
			else {
				// If no '{', it's a single statement block
				var singleStatement = parseStatement();
				return new ASTBlockStatement([singleStatement], line, lineString);
			}
		};
		
		#region Statements
		#region Keyword Statement types
		
		static parseIfStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is 'if'
			nextToken(); // Move past 'if'
			var _condition = parseConditionalExpression();
			optionalToken(__GMLC_TokenType.Keyword, "then")
			var _codeBlock = parseBlock();
			var _elseBlock = undefined;
			
			
			
			if (currentToken != undefined)
			&& (currentToken.value == "else") {
				nextToken(); // Consume 'else'
				_elseBlock = parseBlock();
			}
			return new ASTIfStatement(_condition, _codeBlock, _elseBlock, line, lineString);
		};
		
		static parseForStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Move past 'for'
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
			expectToken(__GMLC_TokenType.Punctuation, ")");
			var _codeBlock = parseBlock();
			return new ASTForStatement(_initialization, _condition, _increment, _codeBlock, line, lineString);
		};
		
		static parseWhileStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is 'while'
			nextToken(); // Move past 'while'
			var _condition = parseConditionalExpression();
			var _codeBlock = parseBlock();
			return new ASTWhileStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseRepeatStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is 'repeat'
			nextToken(); // Move past 'repeat'
			var _condition = parseExpression();
			var _codeBlock = parseBlock();
			return new ASTRepeatStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseDoUntilStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is 'do'
			nextToken(); // Move past 'do'
			var _codeBlock = parseBlock();
			expectToken(__GMLC_TokenType.Keyword, "until");
			var _condition = parseConditionalExpression();
			return new ASTDoUntillStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseSwitchStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
		    nextToken(); // Move past 'switch'
		    var switchExpression = parseExpression(); // Parse the switch expression
		    
			expectToken(__GMLC_TokenType.Punctuation, "{"); // Ensure '{' and consume it
			
			var cases = [];
		    var statements = undefined;
		    var _expectClosingCurly = false;
			
		    while (currentToken != undefined && currentToken.value != "}") {
				if (currentToken.type == __GMLC_TokenType.Keyword) {
					if (currentToken.value == "case") {
						if (_expectClosingCurly) {
							throw $"\nswitch/case statement was opened with \{ but was never closed"
						}
						
						var caseLine = currentToken.line;
						var caseLineString = currentToken.lineString;
						
						expectToken(__GMLC_TokenType.Keyword, "case"); //consume 'case'
						var _label = parseExpression();
						
						expectToken(__GMLC_TokenType.Punctuation, ":"); // Ensure ':' and consume it
						_expectClosingCurly = optionalToken(__GMLC_TokenType.Punctuation, "{")
						
						statements = [];
						array_push(cases, new ASTCaseExpression(_label, statements, caseLine, caseLineString));
					}
					else if (currentToken.value == "default") {
						if (_expectClosingCurly) {
							throw $"\nswitch/case statement was opened with \{ but was never closed"
						}
						
						var caseLine = currentToken.line;
						var caseLineString = currentToken.lineString;
						
						nextToken(); //consume 'default'
						
						expectToken(__GMLC_TokenType.Punctuation, ":"); // Ensure ':' and consume it
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

		    expectToken(__GMLC_TokenType.Punctuation, "}"); // Ensure '}' and consume it

		    return new ASTSwitchStatement(switchExpression, cases, line, lineString);
		};
		
		static parseWithStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is 'with'
			nextToken(); // Move past 'with'
			var _condition = parseExpression();
			var _codeBlock = parseBlock();
			return new ASTWithStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseTryCatchStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Keyword, "try");  // Expect the 'try' keyword
			var _tryBlock = parseBlock();  // Parse the block of statements under 'try'
			
			var _catchBlock = undefined;
			var _exceptionVar = undefined;
			if (currentToken != undefined)
			&& (currentToken.value == "catch") {
				nextToken();  // Move past 'catch'
				expectToken(__GMLC_TokenType.Punctuation, "(");
				
				//parse and identify the exception variable as a local variable.
				_exceptionVar = currentToken.value;  // Parse the exception variable
				array_push(scriptAST.LocalVarNames, _exceptionVar);
				
				nextToken();  // Move past Identifier
				expectToken(__GMLC_TokenType.Punctuation, ")");
				_catchBlock = parseBlock();  // Parse the block of statements under 'catch'
			}
			
			var _finallyBlock = undefined;
			if (currentToken != undefined)
			&& (currentToken.value == "finally") {
				nextToken();  // Move past 'finally'
				_finallyBlock = parseBlock();  // Parse the block of statements under 'finally'
			}
			
			return new ASTTryStatement(_tryBlock, _catchBlock, _exceptionVar, _finallyBlock, line, lineString);
		};
		
		static parseThrowStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Keyword, "throw");  // Expect the 'try' keyword
			var _err_message = parseExpressionStatement();  // Parse the block of statements under 'try'
			
			return new ASTThrowStatement(_err_message, line, lineString);
		};
		
		#endregion
		#region Keyword Executions
		static parseContinueStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume 'break'
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Optionally consume the semicolon
			return new ASTContinueStatement(line, lineString);
		};
		
		static parseBreakStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume 'break'
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Optionally consume the semicolon
			return new ASTBreakStatement(line, lineString);
		};
		
		static parseExitStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume 'exit'
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Optionally consume the semicolon
			return new ASTExitStatement(line, lineString);
		};
		
		static parseReturnStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume 'return'
			var expr = undefined;
			if (currentToken.value != ";" && currentToken.type != __GMLC_TokenType.Punctuation) {
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
			
			expectToken(__GMLC_TokenType.Keyword, "function");
			var functionName = $"GMLC@{currentToken.value}";  // Parse the function identifier
			nextToken();  // Move past Identifier
			
			expectToken(__GMLC_TokenType.Punctuation, "(");
			var _local_var_names = [];
			var parameters = [];
			while (currentToken.value != ")") {
			    var identifier = currentToken.value;  // Parse the parameter name
			    nextToken();  // Move past Identifier
				
				var expr = undefined;
				if (optionalToken(__GMLC_TokenType.Operator, "=")) {
					expr = parseAssignmentExpression(); // Assignment is right-associative
				}
				else { 
					expr = new ASTLiteral(undefined, line, lineString);
				}
				
				array_push(parameters, new ASTFunctionVariableDeclaration(identifier, expr, line, lineString));
				array_push(_local_var_names, identifier);
				
			    if (currentToken.value == ",") {
			        nextToken();  // Handle multiple parameters
			    }
			}
			nextToken();  // Close parameters list
			
			// Register function as a global variable and move its body to GlobalVar
			var globalFunctionNode = new ASTFunctionDeclaration(
											functionName,
											new ASTFunctionVariableDeclarationList(parameters, line, lineString),
											_local_var_names,
											undefined, //will be set after body is parsed
											line,
											lineString
									)
			
			
			//cache the old current function, incase we are declaring a function inside a function
			var _old_function = currentFunction;
			currentFunction = globalFunctionNode;
			
			// Parse the function body
			globalFunctionNode.body = parseBlock();
			
			//reset the current function
			currentFunction = _old_function;
			
			// Add to GlobalVar mapping of the Program node
			scriptAST.GlobalVar[$ functionName] = globalFunctionNode;
			array_push(scriptAST.GlobalVarNames, functionName);
			
			// Return a reference to the function in the global scope
			return new ASTIdentifier(functionName, ScopeType.GLOBAL, line, lineString);
		};
		static parseFunctionExpression = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			static __anon_id = 0;
			// thing = function()
			expectToken(__GMLC_TokenType.Keyword, "function");
			
			expectToken(__GMLC_TokenType.Punctuation, "(");
			var _local_var_names = [];
			var parameters = [];
			while (currentToken.value != ")") {
			    var identifier = currentToken.value;  // Parse the parameter name
			    nextToken();  // Move past Identifier
				
				var expr = undefined;
				if (optionalToken(__GMLC_TokenType.Operator, "=")) {
					expr = parseAssignmentExpression(); // Assignment is right-associative
				}
				else {
					expr = new ASTLiteral(undefined, line, lineString);
				}
				
				array_push(parameters, new ASTFunctionVariableDeclaration(identifier, expr, line, lineString));
				array_push(_local_var_names, identifier);
				
			    if (currentToken.value == ",") {
			        nextToken();  // Handle multiple parameters
			    }
			}
			nextToken();  // Close parameters list
			
			var functionName = $"GMLC@anon@{__anon_id++}";
			
			// Register function as a global variable and move its body to GlobalVar
			var globalFunctionNode = new ASTFunctionDeclaration(
											functionName,
											new ASTFunctionVariableDeclarationList(parameters, line, lineString),
											_local_var_names,
											undefined, //will be set after body is parsed
											line,
											lineString
									)
			
			
			//cache the old current function, incase we are declaring a function inside a function
			var _old_function = currentFunction;
			currentFunction = globalFunctionNode;
			
			// Parse the function body
			globalFunctionNode.body = parseBlock();
			
			//reset the current function
			currentFunction = _old_function;
			
			// Add to GlobalVar mapping of the Program node
			scriptAST.GlobalVar[$ functionName] = globalFunctionNode;
			array_push(scriptAST.GlobalVarNames, functionName);
			
			return new ASTIdentifier(functionName, ScopeType.GLOBAL, line, lineString);
		};
		
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
				// Parse each statement until '}' is found
				// Optional: Handle error checking for unexpected end of file
				if (GML_COMPILER_DEBUG) {
					static __lastString = ""
					var _str = string(currentTokenIndex/array_length(tokens))
					if (__lastString != _str) {
						show_debug_message($"{real(_str)*100}% Finished")
						__lastString = _str;
					}
				}
			}
			if (currentToken != undefined) nextToken(); // Consume the '}'
			globalFunctionNode.body = new ASTBlockStatement(_body, line, lineString); // Return a block statement containing all parsed statements;
			
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
			
			var type = currentToken.value;  // 'var', 'globalvar', or 'static'
			
			var _scope = undefined;
			switch (type) {
				//case "let":{
				//	//dont to nuttin`!
				//break;}
				case "var":{
					_scope = ScopeType.LOCAL;
				break;}
				case "static":{
					_scope = ScopeType.STATIC;
				break;}
				case "globalvar":{
					_scope = ScopeType.GLOBAL;
				break;}
				default: throw $"\nHow did we enter variable declaration with out meeting a variable keyword?"
			}
			
			nextToken();
			
			var declarations = [];
		    while (true) {
				// optionally skip redeclarations
				var varLine = currentToken.line;
				var varLineString = currentToken.lineString;
				
				if (currentToken.type != __GMLC_TokenType.Identifier) {
		            throw $"\nExpected identifier in variable declaration.\nRecieved: {currentToken}\nLast five tokens:\n{lastFiveTokens}";
		        }
				
		        var identifier = currentToken.value;
		        nextToken();
				
				var expr = undefined;
				if (optionalToken(__GMLC_TokenType.Operator, "=")) {
					expr = parseConditionalExpression();
				}
				
				
				//mark the variable tables
				if (currentFunction == undefined) {
					//script scrope
					switch (_scope) {
						//case "let":{
						//	//dont to nuttin`!
						//break;}
						case ScopeType.LOCAL:{
							array_push(scriptAST.LocalVarNames, identifier);
						break;}
						case ScopeType.STATIC:{
							throw $"\nScript: <SCRIPT_NAME> at line {currentToken.line} : static can only be declared inside a function";
						break;}
						case ScopeType.GLOBAL:{
							array_push(scriptAST.GlobalVarNames, identifier);
						break;}
						default: throw $"\nHow did we enter variable declaration with out meeting a variable keyword?"
					}
					
				}
				else {
					//function scope
					switch (_scope) {
						//case "let":{
						//	//dont to nuttin`!
						//break;}
						case ScopeType.LOCAL:{
							array_push(currentFunction.LocalVarNames, identifier);
						break;}
						case ScopeType.STATIC:{
							array_push(currentFunction.StaticVarNames, identifier);
							//if this is a static function assignment, assign the static identifier's name to the function's name
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
									
									//change the function's name
									_possibleFunc.functionName = _newFuncName;
									
									//change the identifier
									expr.identifier = _newFuncName;
								}
							}
						break;}
						case ScopeType.GLOBAL:{
							array_push(scriptAST.GlobalVarNames, identifier);
						break;}
						default: throw $"\nHow did we enter variable declaration with out meeting a variable keyword?"
					}
				}
				
		        array_push(declarations, new ASTVariableDeclaration(identifier, expr, _scope, varLine, varLineString));
				
		        if (currentToken == undefined || currentToken.value != ",") {
		            break; // End of declaration list
		        }
				
		        nextToken(); // Consume ',' and move to the next identifier
		    }
			
			
			return new ASTVariableDeclarationList(declarations, line, lineString);
		};
		
		#endregion
		#region Execution
		
		static parseNewExpression = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Keyword, "new");  // Expect the 'new' keyword
			
			var _constructorName = parseIdentifier();  // Parse the constructor function name
			// Optionally, ensure that the constructorName refers to a valid constructor
			// This validation might require additional context about declared constructors
			
			expectToken(__GMLC_TokenType.Punctuation, "(");  // Expect an opening parenthesis for the arguments
			
			var _arguments = [];
			while (currentToken.value != ")") {
				array_push(_arguments, parseExpression()); // Parse each argument as an expression
				if (currentToken.value == ",") {
					nextToken();  // Consume the comma to continue to the next argument
				}
			}
			
			expectToken(__GMLC_TokenType.Punctuation, ")");  // Expect a closing parenthesis
			return new ASTNewExpression( _constructorName, _arguments, line, lineString);
		};
		
		#endregion
		
		static parseExpressionStatement = function() {
			var expr = parseExpression();
			if (expr == undefined) {
				throw $"\nGetting an error parsing expression, current token is:\n{currentToken}\nLast Five Tokens:\n{lastFiveTokens}"
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
				
				var operator = currentToken.value;
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
				
				expectToken(__GMLC_TokenType.Operator, "?"); // Consume '?'
				var trueExpr = parseExpression(); // Parse the true branch
				expectToken(__GMLC_TokenType.Punctuation, ":"); // Consume ':'
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
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseShiftExpression();
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
					new ASTUpdateExpression(operator, expr, true, line, lineString);
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
						expr = parseFunctionCall(expr);
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
				throw "\nUnexpected end of input";
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
					
					if (_scopeType == ScopeType.INSTANCE) {
						var node = new ASTIdentifier(currentToken.value, undefined, line, lineString);
						nextToken(); // Move past the identifier
						return node;
					}
					
					var node = new ASTIdentifier(currentToken.value, _scopeType, line, lineString);
					nextToken(); // Move past the identifier
					return node;
					
				break;}
				case __GMLC_TokenType.Function:{
					
					var node = new ASTFunction(currentToken.value, line, lineString);
					nextToken(); // Move past the identifier
					return node;
					
				break;}
				case __GMLC_TokenType.Keyword:{
					
					if (currentToken.value == "function") {
						return parseFunctionExpression();
					}
				
				break;}
				case __GMLC_TokenType.Punctuation:{
					
					if (currentToken.value == "(") {
						// Handle expressions wrapped in parentheses
						nextToken(); // Consume '('
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
				case __GMLC_TokenType.UniqueVariable: {
					
					// Handle literals
					var node = new ASTUniqueIdentifier(currentToken.value, line, lineString);
					nextToken();
					return node;
					
				break;}
			}
			
			throw $"\n\nUnexpected token in expression: {currentToken}\nLast five tokens were:\n{lastFiveTokens}";
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
			
			var _keys = [];
		    var _exprs = [];
		    
		    expectToken(__GMLC_TokenType.Punctuation, "{");
		    while (currentToken != undefined && currentToken.value != "}") {
		        if (currentToken.type != __GMLC_TokenType.Identifier)
				&& (currentToken.type != __GMLC_TokenType.String) {
		            throw $"\nExpected identifier for struct property name.\n{currentToken}\nLast Five Tokens:\n{json_stringify(lastFiveTokens, true)}";
		        }
				
		        var key = currentToken;
		        nextToken();  // Move past the identifier
				
				if (optionalToken(__GMLC_TokenType.Punctuation, ":")) {
					var value = parseExpression();
				}
				else if (key.type == __GMLC_TokenType.Identifier) {
					var value = new ASTIdentifier(key.value, undefined, key.line, key.lineString);
				}
				else {
					throw $"\nObject: {Object1} Event: {Create} at line {line} : got {key.type} '{key.value}' expected id"
				}
		        
				//this is a literal because it's technically an argument for a struct creation.
				array_push(_keys, new ASTLiteral(key.value, key.line, key.lineString));
				array_push(_exprs, value);
				
		        if (currentToken.value == ",") {
		            nextToken();  // Skip the comma
		        }
				
		    }
		    expectToken(__GMLC_TokenType.Punctuation, "}");
			
			// Properties are not all constants, use a runtime function to create the struct
			return new ASTStructPattern(_keys, _exprs, line, lineString)
		};
		
		static parseFunctionCall = function(callee) {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			var args = [];
			expectToken(__GMLC_TokenType.Punctuation, "("); // Ensure '(' and consume it

			if (currentToken != undefined && currentToken.value != ")") {
				while (currentToken != undefined && currentToken.value != ")") {
					array_push(args, parseExpression()); // Parse each argument
					if (currentToken != undefined && currentToken.value == ",") {
						nextToken(); // Consume ',' to move to the next argument
					}
				} 
			}
			
			
			expectToken(__GMLC_TokenType.Punctuation, ")"); // Ensure ')' and consume it
			return new ASTCallExpression(callee, args, line, lineString);
		};
		
		static parseDotAccessor = function(object) {
		    var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume '.'
		    if (currentToken.type != __GMLC_TokenType.Identifier) {
		        throw "Expected identifier after '.'";
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
			
			nextToken(); // Consume '['
			var accessorType = __GMLC_AccessorType.Array; // Default to array accessor
			
			switch (currentToken.value) {
				case "|":{
					accessorType = __GMLC_AccessorType.List;
					nextToken(); // Consume '|'
				break;}
				case "?":{
					accessorType = __GMLC_AccessorType.Map;
					nextToken(); // Consume '?'
				break;}
				case "#":{
					accessorType = __GMLC_AccessorType.Grid;
					nextToken(); // Consume '#'
				break;}
				case "$":{
					accessorType = __GMLC_AccessorType.Struct;
					nextToken(); // Consume '$'
				break;}
				case "@":{
					accessorType = __GMLC_AccessorType.Array;
					nextToken(); // Consume '@'
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
			
			expectToken(__GMLC_TokenType.Punctuation, "]"); // Consume ']'
			
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
				throw $"\n\nUnexpected end of input. Expected '{expectedValue}' but found EOF.";
			}
			if (currentToken.type != expectedType || currentToken.value != expectedValue) {
				throw $"\n\nSyntax Error: Expected '{expectedValue}' at line {currentToken.line}, column {currentToken.column}, but found '{currentToken}'\nLast five tokens:\n{lastFiveTokens}.";
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
						throw $"\nWe still have nodes in the nodeStack, we shouldn't be finished"
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
						return new ASTNode("FunctionCall", {
							callee: new ASTNode("Function", {value: __background_set_colour, name: "__background_set_colour"}),
							arguments: [ node.right ]
						});
					}
				}
			}
			
			if (node.type == "Identifier") {
				switch (node.value) {
					case "background_color":
					case "background_colour":{
						return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get_colour, name: "__background_get_colour"}),
								arguments: []
							});
					break;}
					
					case "background_showcolor":
					case "background_showcolour":{
						return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get_showcolour, name: "__background_get_showcolour"}),
								arguments: []
							});
					break;}
					
				}
			}
			
			//background_visible
			return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: background_visible, name: "background_visible"}),
								arguments: []
							});
			//background_showcolor
			return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: background_showcolor, name: "background_showcolor"}),
								arguments: []
							});
							
			
			
			return node;
		}
		
		static convertViews = function(node) {
			
			if (node.type == "AssignmentExpression") {
				if (node.left.type == "Identifier") {
					if (node.left.value == "background_color") || (node.left.value == "background_colour") {
						return new ASTNode("FunctionCall", {
							callee: new ASTNode("Function", {value: __background_set_colour, name: "__background_set_colour"}),
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
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Visible, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_foreground") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Foreground, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_index") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Index, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_x") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.X, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_y") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Y, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_width") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Width, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_height") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Height, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_htiled") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.HTiled, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_vtiled") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.VTiled, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_xscale") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.XScale, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_yscale") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.YScale, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_hspeed") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.HSpeed, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_vspeed") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.VSpeed, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_blend") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Blend, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_alpha") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_get, name: "__background_get"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Alpha, scope: ScopeType.CONST}),
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
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Visible, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_foreground") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Foreground, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_index") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Index, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_x") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.X, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_y") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Y, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_width") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Width, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_height") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Height, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_htiled") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.HTiled, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_vtiled") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.VTiled, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_xscale") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.XScale, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_yscale") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.YScale, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_hspeed") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.HSpeed, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_vspeed") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.VSpeed, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_blend") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Blend, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
						if (ind_node.value == "background_alpha") {
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: __background_set, name: "__background_set"}),
								arguments: [
									new ASTNode("Literal", {value: e__BG.Alpha, scope: ScopeType.CONST}),
									node.right
								]
							});
							
						}
					}
				}
				
			}
			
			
			
			//background_visible
			return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: background_visible, name: "background_visible"}),
								arguments: []
							});
			//background_showcolor
			return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: background_showcolor, name: "background_showcolor"}),
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
				
				if (currentNode.node.type == __GMLC_NodeType.FunctionDeclaration) {
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
						throw $"\nWe still have nodes in the nodeStack, we shouldn't be finished"
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
			
			switch (node.type) {
			    case __GMLC_NodeType.Script:{
					
				break;}
				case __GMLC_NodeType.FunctionDeclaration:{
					
				break;}
				case __GMLC_NodeType.FunctionVariableDeclarationList:{
					
				break;}
				case __GMLC_NodeType.FunctionVariableDeclaration:{
					
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
				
				case __GMLC_NodeType.ThrowStatement: {
					
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
						var getterFunc, setterFunc, rightExpr;
						
						// Determine the getter and setter functions based on the accessor type
						switch (node.left.accessorType) {
							case __GMLC_AccessorType.Array:{
								getterFunc = new ASTFunction(array_get, node.line, node.lineString);
								setterFunc = new ASTFunction(array_set, node.line, node.lineString);
							break;}
							case __GMLC_AccessorType.Grid:{
								getterFunc = new ASTFunction(ds_grid_get, node.line, node.lineString);
								setterFunc = new ASTFunction(ds_grid_set, node.line, node.lineString);
							break;}
							case __GMLC_AccessorType.List:{
								getterFunc = new ASTFunction(ds_list_find_value, node.line, node.lineString);
								setterFunc = new ASTFunction(ds_list_set, node.line, node.lineString);
							break;}
							case __GMLC_AccessorType.Map:{
								getterFunc = new ASTFunction(ds_map_find_value, node.line, node.lineString);
								setterFunc = new ASTFunction(ds_map_set, node.line, node.lineString);
							break;}
							case __GMLC_AccessorType.Struct:{
								getterFunc = new ASTFunction(struct_get, node.line, node.lineString);
								setterFunc = new ASTFunction(struct_set, node.line, node.lineString);
							break;}
							case __GMLC_AccessorType.Dot:{
								getterFunc = new ASTFunction(__struct_get_with_error, node.line, node.lineString);
								setterFunc = new ASTFunction(struct_set, node.line, node.lineString);
							break;}
							default: throw $"\nUnsupported accessor type: {node.left.accessorType}";
						}

						var getterArgs = [node.left.expr];
						var setterArgs = [node.left.expr];

						// Add arguments for array and grid accessors
						array_push(getterArgs, node.left.val1);
						array_push(setterArgs, node.left.val1);
						
						if (node.left.accessorType == __GMLC_AccessorType.Grid) {
							array_push(getterArgs, node.left.val2);
							array_push(setterArgs, node.left.val2);
						}

						switch (node.operator) {
							case "+=": rightExpr = new ASTBinaryExpression(OpCode.PLUS,        new ASTCallExpression(getterFunc, getterArgs, node.line, node.lineString), node.right, node.line, node.lineString);
							case "-=": rightExpr = new ASTBinaryExpression(OpCode.SUBTRACT,    new ASTCallExpression(getterFunc, getterArgs, node.line, node.lineString), node.right, node.line, node.lineString);
							case "*=": rightExpr = new ASTBinaryExpression(OpCode.MULTIPLY,    new ASTCallExpression(getterFunc, getterArgs, node.line, node.lineString), node.right, node.line, node.lineString);
							case "/=": rightExpr = new ASTBinaryExpression(OpCode.DIVIDE,      new ASTCallExpression(getterFunc, getterArgs, node.line, node.lineString), node.right, node.line, node.lineString);
							case "^=": rightExpr = new ASTBinaryExpression(OpCode.BITWISE_XOR, new ASTCallExpression(getterFunc, getterArgs, node.line, node.lineString), node.right, node.line, node.lineString);
							case "&=": rightExpr = new ASTBinaryExpression(OpCode.BITWISE_AND, new ASTCallExpression(getterFunc, getterArgs, node.line, node.lineString), node.right, node.line, node.lineString);
							case "|=": rightExpr = new ASTBinaryExpression(OpCode.BITWISE_OR,  new ASTCallExpression(getterFunc, getterArgs, node.line, node.lineString), node.right, node.line, node.lineString);
							case "=": {
								rightExpr = node.right; // Direct assignment doesn't need an operator
							break;} // Direct assignment doesn't need an operator
							default: throw $"\nUnsupported assignment operator: {node.operator}";
						}
						
						
						array_push(setterArgs, rightExpr);
						
						// Create the function call node for setting the value
						node = new ASTCallExpression(setterFunc, setterArgs, node.line, node.lineString)
						
						
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
						var increment = (node.operator == "++");
						var prefix = node.prefix; // Since this is a postfix expression
						
						switch (node.expr.accessorType) {
							case __GMLC_AccessorType.Array:{
								node = new ASTCallExpression(
									new ASTFunction(__array_update, node.line, node.lineString),
									[
										node.expr.expr,
										node.expr.val1,
										new ASTLiteral(increment, node.line, node.lineString),
										new ASTLiteral(prefix, node.line, node.lineString)
									],
									node.line,
									node.lineString
								);	
							break;}
							case __GMLC_AccessorType.Grid:{
								node = new ASTCallExpression(
									new ASTFunction(__grid_update, node.line, node.lineString),
									[
										node.expr.expr,
										node.expr.val1,
										node.expr.val2,
										new ASTLiteral(increment, node.line, node.lineString),
										new ASTLiteral(prefix, node.line, node.lineString)
									],
									node.line,
									node.lineString
								);	
							break;}
							case __GMLC_AccessorType.List:{
								node = new ASTCallExpression(
									new ASTFunction(__list_update, node.line, node.lineString),
									[
										node.expr.expr,
										node.expr.val1,
										new ASTLiteral(increment, node.line, node.lineString),
										new ASTLiteral(prefix, node.line, node.lineString)
									],
									node.line,
									node.lineString
								);	
							break;}
							case __GMLC_AccessorType.Map:{
								node = new ASTCallExpression(
									new ASTFunction(__map_update, node.line, node.lineString),
									[
										node.expr.expr,
										node.expr.val1,
										new ASTLiteral(increment, node.line, node.lineString),
										new ASTLiteral(prefix, node.line, node.lineString)
									],
									node.line,
									node.lineString
								);	
							break;}
							case __GMLC_AccessorType.Struct:{
								node = new ASTCallExpression(
									new ASTFunction(__struct_update, node.line, node.lineString),
									[
										node.expr.expr,
										node.expr.val1,
										new ASTLiteral(increment, node.line, node.lineString),
										new ASTLiteral(prefix, node.line, node.lineString)
									],
									node.line,
									node.lineString
								);	
							break;}
							case __GMLC_AccessorType.Dot:{
								node = new ASTCallExpression(
									new ASTFunction(__struct_with_error_update, node.line, node.lineString),
									[
										node.expr.expr,
										node.expr.val1,
										new ASTLiteral(increment, node.line, node.lineString),
										new ASTLiteral(prefix, node.line, node.lineString)
									],
									node.line,
									node.lineString
								);	
							break;}
						}
						
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
				/*
				case __GMLC_NodeType.PropertyAccessor:{
					throw $"\n{currentNode.type} :: Not implimented yet"
				break;}
				case __GMLC_NodeType.AccessorExpression:{
					throw $"\n{currentNode.type} :: Not implimented yet"
				break;}
				case __GMLC_NodeType.ConstructorFunction:{
					throw $"\n{currentNode.type} :: Not implimented yet"
				break;}
				case __GMLC_NodeType.MethodVariableConstructor:{
					throw $"\n{currentNode.type} :: Not implimented yet"
				break;}
				case __GMLC_NodeType.MethodVariableFunction:{
					throw $"\n{currentNode.type} :: Not implimented yet"
				break;}
				//*/
				default: throw $"\nCurrent Node does not have a valid type for the post processor,\ntype: {node.type}\ncurrentNode: {node}"
				
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
		    var _getterFunc, _setterFunc;
			
			// Getter context
		    switch (accessorType) {
				case __GMLC_AccessorType.Array:  _getterFunc = new ASTFunction(array_get,               node.line, node.lineString); _setterFunc = new ASTFunction(array_set,   node.line, node.lineString); break;
				case __GMLC_AccessorType.List:   _getterFunc = new ASTFunction(ds_list_find_value,      node.line, node.lineString); _setterFunc = new ASTFunction(ds_list_set, node.line, node.lineString); break;
				case __GMLC_AccessorType.Map:    _getterFunc = new ASTFunction(ds_map_find_value,       node.line, node.lineString); _setterFunc = new ASTFunction(ds_map_set,  node.line, node.lineString); break;
				case __GMLC_AccessorType.Grid:   _getterFunc = new ASTFunction(ds_grid_get,             node.line, node.lineString); _setterFunc = new ASTFunction(ds_grid_set, node.line, node.lineString); break;
				case __GMLC_AccessorType.Struct: _getterFunc = new ASTFunction(struct_get,              node.line, node.lineString); _setterFunc = new ASTFunction(struct_set,  node.line, node.lineString); break;
				case __GMLC_AccessorType.Dot:    _getterFunc = new ASTFunction(__struct_get_with_error, node.line, node.lineString); _setterFunc = new ASTFunction(struct_set,  node.line, node.lineString); break;
				default: throw $"\nUnexpected entry into handleAccessorFunctionCall with accessorType: {accessorType}" break;
			}
			
			var _get_expr = new ASTCallExpression(_getterFunc, _args, node.line, node.lineString);
			//var expr = parseLogicalOrExpression();
			
			if (currentToken != undefined)
			&& (currentToken.type == __GMLC_NodeType.Operator) {
				var _op = currentToken.value;
				var _new_args = variable_clone(_args);
				var right;
				
				// Handle compound assignments
				static __op_arr = ["+=", "-=", "*=", "/=", "^=", "&=", "|=", "++", "--"];
				if (_op == "=") {
					nextToken(); // Consume the operator
					
					var expr = parseLogicalOrExpression();
					array_push(_new_args, expr);
					return new ASTNode("FunctionCall", {callee: _setterFunc, arguments: _new_args});
				}
				else if (array_contains(__op_arr, _op)) {
					nextToken(); // Consume the operator
					
					// Determine the right-hand side expression based on the operator
					switch (_op) {
						case "+=": case "-=": case "*=": case "/=":
						case "^=": case "&=": case "|=":
						    right = parseLogicalOrExpression(); break;
						case "++": case "--":
						    right = new ASTNode("Literal", {value: 1, scope: ScopeType.CONST}); break;
					}
					
					// Create binary expression node
					var adjustedOperator = string_copy(_op, 1, 1); // Remove '=' or adjust for '++'/'--'
					var expr = new ASTNode("BinaryExpression", {operator: adjustedOperator, left: _get_expr, right: right});
					array_push(_new_args, expr);
					
					// Return the setter function call with updated arguments
					return new ASTNode("FunctionCall", {callee: _setterFunc, arguments: _new_args});
				}
				else {
					return _get_expr; // For unsupported operators or when no assignment is detected
				}
			}
			
		    return _get_expr;
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
						throw $"\nWe still have nodes in the nodeStack, we shouldn't be finished"
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
								return new ASTNode("Literal", {value: node.left.value | node.right.value, scope: ScopeType.CONST});
							break;}
							case "^":{
								return new ASTNode("Literal", {value: node.left.value ^ node.right.value, scope: ScopeType.CONST});
							break;}
							case "&":{
								return new ASTNode("Literal", {value: node.left.value & node.right.value, scope: ScopeType.CONST});
							break;}
							case "==":{
								return new ASTNode("Literal", {value: node.left.value == node.right.value, scope: ScopeType.CONST});
							break;}
							case "!=":{
								return new ASTNode("Literal", {value: node.left.value != node.right.value, scope: ScopeType.CONST});
							break;}
							case "<":{
								return new ASTNode("Literal", {value: node.left.value < node.right.value, scope: ScopeType.CONST});
							break;}
							case "<=":{
								return new ASTNode("Literal", {value: node.left.value <= node.right.value, scope: ScopeType.CONST});
							break;}
							case ">":{
								return new ASTNode("Literal", {value: node.left.value > node.right.value, scope: ScopeType.CONST});
							break;}
							case ">=":{
								return new ASTNode("Literal", {value: node.left.value >= node.right.value, scope: ScopeType.CONST});
							break;}
							case "<<":{
								return new ASTNode("Literal", {value: node.left.value << node.right.value, scope: ScopeType.CONST});
							break;}
							case ">>":{
								return new ASTNode("Literal", {value: node.left.value >> node.right.value, scope: ScopeType.CONST});
							break;}
							case "+":{
								return new ASTNode("Literal", {value: node.left.value + node.right.value, scope: ScopeType.CONST});
							break;}
							case "-":{
								return new ASTNode("Literal", {value: node.left.value - node.right.value, scope: ScopeType.CONST});
							break;}
							case "*":{
								return new ASTNode("Literal", {value: node.left.value * node.right.value, scope: ScopeType.CONST});
							break;}
							case "/":{
								return new ASTNode("Literal", {value: node.left.value / node.right.value, scope: ScopeType.CONST});
							break;}
							case "mod":{
								if (node.right.value == 0) {
									throw $"\nDoMod :: Divide by zero"
								}
								return new ASTNode("Literal", {value: node.left.value mod node.right.value, scope: ScopeType.CONST});
							break;}
							case "div":{
								if (node.right.value == 0) {
									throw $"\nDoRem :: Divide by zero"
								}
								return new ASTNode("Literal", {value: node.left.value div node.right.value, scope: ScopeType.CONST});
							break;}
						}
					}
				break;}
				case "LogicalExpression":{
					if (node.left.type == "Literal" && node.right.type == "Literal") {
					    switch (node.operator) {
							case "||":{
								return new ASTNode("Literal", {value: node.left.value || node.right.value, scope: ScopeType.CONST});
							break;}
							case "&&":{
								return new ASTNode("Literal", {value: node.left.value && node.right.value, scope: ScopeType.CONST});
							break;}
							case "^^":{
								return new ASTNode("Literal", {value: node.left.value ^^ node.right.value, scope: ScopeType.CONST});
							break;}
					    }
					}
					else if (node.left.type == "Literal" || node.right.type == "Literal") {
					    switch (node.operator) {
							case "||":{
								if (node.left.type  == "Literal" && node.left.value ) return new ASTNode("Literal", {value: true, scope: ScopeType.CONST});
								if (node.right.type == "Literal" && node.right.value) return new ASTNode("Literal", {value: true, scope: ScopeType.CONST});
							break;}
							case "&&":{
								if (node.left.type  == "Literal" && !node.left.value ) return new ASTNode("Literal", {value: false, scope: ScopeType.CONST});
								if (node.right.type == "Literal" && !node.right.value) return new ASTNode("Literal", {value: false, scope: ScopeType.CONST});
							break;}
					    }
					}
				break;}
				case "NullishExpression":{
					if (node.left.type == "Literal" && node.left.value == undefined) {
						return node.right;
					}
				break;}
				case "UnaryExpression":{
					if (node.expr.type == "Literal") {
					    switch (node.operator) {
							case "!":{
								return new ASTNode("Literal", {value: !node.expr.value, scope: ScopeType.CONST});
							break;}
							case "+":{
								return new ASTNode("Literal", {value: +node.expr.value, scope: ScopeType.CONST});
							break;}
							case "-":{
								return new ASTNode("Literal", {value: -node.expr.value, scope: ScopeType.CONST});
							break;}
							case "~":{
								return new ASTNode("Literal", {value: ~node.expr.value, scope: ScopeType.CONST});
							break;}
							case "++":{
								return new ASTNode("Literal", {value: ++node.expr.value, scope: ScopeType.CONST});
							break;}
							case "--":{
								return new ASTNode("Literal", {value: --node.expr.value, scope: ScopeType.CONST});
							break;}
					    }
					}
				break;}
				case "ConditionalExpression":{
					if (node.condition.type == "Literal") {
					    // If the condition is a literal, determine which branch to take
						if (node.condition.value) {
							if (node.trueExpr.type == "Literal") {
								return new ASTNode("Literal", {value: node.trueExpr.value, scope: ScopeType.CONST});
							}
						}
						else {
							if (node.falseExpr.type == "Literal") {
								return new ASTNode("Literal", {value: node.falseExpr.value, scope: ScopeType.CONST});
							}
						}
					}
				break;}
				case "ExpressionStatement":{
					if (node.expr.type == "Literal") {
					    // If the condition is a literal, determine which branch to take
						return new ASTNode("Literal", {value: node.expr.value, scope: ScopeType.CONST});
					}
				break;}
				case "FunctionCall":{
					switch (node.callee.value) {
						case abs:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for abs is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(abs, node);
						break;}
						case angle_difference:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for angle_difference is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(angle_difference, node);
						break;}
						case ansi_char:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for ansi_char is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(ansi_char, node);
						break;}
						case arccos:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for arccos is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(arccos, node);
						break;}
						case arcsin:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for arcsin is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(arcsin, node);
						break;}
						case arctan:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for arctan is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(arctan, node);
						break;}
						case arctan2:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for arctan2 is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(arctan2, node);
						break;}
						case buffer_sizeof:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for buffer_sizeof is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(buffer_sizeof, node);
						break;}
						case ceil:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for ceil is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(ceil, node);
						break;}
						case chr:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for chr is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(chr, node);
						break;}
						case clamp:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for clamp is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(clamp, node);
						break;}
						case color_get_blue:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for color_get_blue is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(color_get_blue, node);
						break;}
						case color_get_green:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for color_get_green is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(color_get_green, node);
						break;}
						case color_get_red:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for color_get_red is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(color_get_red, node);
						break;}
						case colour_get_blue:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for colour_get_blue is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(colour_get_blue, node);
						break;}
						case colour_get_green:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for colour_get_green is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(colour_get_green, node);
						break;}
						case colour_get_red:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for colour_get_red is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(colour_get_red, node);
						break;}
						case cos:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for cos is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(cos, node);
						break;}
						case darccos:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for darccos is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(darccos, node);
						break;}
						case darcsin:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for darcsin is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(darcsin, node);
						break;}
						case darctan:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for darctan is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(darctan, node);
						break;}
						case darctan2:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for darctan2 is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(darctan2, node);
						break;}
						case dcos:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for dcos is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(dcos, node);
						break;}
						case degtorad:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for degtorad is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(degtorad, node);
						break;}
						case dot_product:{
							if (array_length(node.arguments) != 4) {
								throw $"\nArgument count for dot_product is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(dot_product, node);
						break;}
						case dot_product_3d:{
							if (array_length(node.arguments) != 6) {
								throw $"\nArgument count for dot_product_3d is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(dot_product_3d, node);
						break;}
						case dot_product_3d_normalised:{
							if (array_length(node.arguments) != 6) {
								throw $"\nArgument count for dot_product_3d_normalised is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(dot_product_3d_normalised, node);
						break;}
						case dot_product_normalised:{
							if (array_length(node.arguments) != 4) {
								throw $"\nArgument count for dot_product_normalised is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(dot_product_normalised, node);
						break;}
						case dsin:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for dsin is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(dsin, node);
						break;}
						case dtan:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for dtan is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(dtan, node);
						break;}
						case exp:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for exp is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(exp, node);
						break;}
						case floor:{
							if (array_length(node.arguments) != XXX) {
								throw $"\nArgument count for floor is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(floor, node);
						break;}
						case frac:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for frac is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(frac, node);
						break;}
						case int64:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for int64 is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(int64, node);
						break;}
						case is_array:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for is_array is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(is_array, node);
						break;}
						case is_bool:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for is_bool is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(is_bool, node);
						break;}
						case is_callable:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for is_callable is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(is_callable, node);
						break;}
						case is_handle:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for is_handle is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(is_handle, node);
						break;}
						case is_infinity:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for is_infinity is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(is_infinity, node);
						break;}
						case is_int32:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for is_int32 is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(is_int32, node);
						break;}
						case is_method:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for is_method is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(is_method, node);
						break;}
						case is_nan:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for is_nan is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(is_nan, node);
						break;}
						case is_numeric:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for is_numeric is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(is_numeric, node);
						break;}
						case is_ptr:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for is_ptr is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(is_ptr, node);
						break;}
						case is_struct:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for is_struct is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(is_struct, node);
						break;}
						case is_undefined:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for is_undefined is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(is_undefined, node);
						break;}
						case lengthdir_x:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for lengthdir_x is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(lengthdir_x, node);
						break;}
						case lengthdir_y:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for lengthdir_y is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(lengthdir_y, node);
						break;}
						case lerp:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for lerp is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(lerp, node);
						break;}
						case ln:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for ln is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(ln, node);
						break;}
						case log10:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for log10 is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(log10, node);
						break;}
						case log2:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for log2 is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(log2, node);
						break;}
						case logn:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for logn is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(logn, node);
						break;}
						case make_color_rgb:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for make_color_rgb is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(make_color_rgb, node);
						break;}
						case make_colour_rgb:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for make_colour_rgb is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(make_colour_rgb, node);
						break;}
						case max:{
							if (array_length(node.arguments) < 1) {
								throw $"\nArgument count for max is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(max, node);
						break;}
						case mean:{
							if (array_length(node.arguments) < 1) {
								throw $"\nArgument count for mean is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(mean, node);
						break;}
						case median:{
							if (array_length(node.arguments) < 1) {
								throw $"\nArgument count for median is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(median, node);
						break;}
						case min:{
							if (array_length(node.arguments) < 1) {
								throw $"\nArgument count for min is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(min, node);
						break;}
						case object_exists:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for object_exists is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(object_exists, node);
						break;}
						case object_get_name:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for object_get_name is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(object_get_name, node);
						break;}
						case object_get_parent:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for object_get_parent is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(object_get_parent, node);
						break;}
						case object_get_physics:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for object_get_physics is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(object_get_physics, node);
						break;}
						case object_is_ancestor:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for object_is_ancestor is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(object_is_ancestor, node);
						break;}
						case ord:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for ord is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(ord, node);
						break;}
						case os_get_config:{
							return __build_literal_from_function_call_constant_folding(os_get_config, node);
						break;}
						case point_direction:{
							if (array_length(node.arguments) != 4) {
								throw $"\nArgument count for point_direction is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(point_direction, node);
						break;}
						case point_distance:{
							if (array_length(node.arguments) != 4) {
								throw $"\nArgument count for point_distance is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(point_distance, node);
						break;}
						case point_distance_3d:{
							if (array_length(node.arguments) != 6) {
								throw $"\nArgument count for point_distance_3d is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(point_distance_3d, node);
						break;}
						case power:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for power is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(power, node);
						break;}
						case radtodeg:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for radtodeg is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(radtodeg, node);
						break;}
						case real:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for real is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(real, node);
						break;}
						case round:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for round is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(round, node);
						break;}
						case script_exists:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for script_exists is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(script_exists, node);
						break;}
						case script_get_name:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for script_get_name is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(script_get_name, node);
						break;}
						case sign:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for sign is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(sign, node);
						break;}
						case sin:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for sin is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(sin, node);
						break;}
						case sqr:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for sqr is incorrect!\nArgument Count : {array_length(node.arguments)}"
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
								throw $"\nArgument count for string_lower is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_lower, node);
						break;}
						case string_upper:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for string_upper is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_upper, node);
						break;}
						case string_repeat:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for string_repeat is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_repeat, node);
						break;}
						case tan:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for tan is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(tan, node);
						break;}
						case variable_get_hash:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for variable_get_hash is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(variable_get_hash, node);
						break;}
						
						//organize these later....
						
						case code_is_compiled:{
							return __build_literal_from_function_call_constant_folding(code_is_compiled, node);
						break;}
						case string_byte_length:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for string_byte_length is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_byte_length, node);
						break;}
						case string_char_at:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for string_char_at is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_char_at, node);
						break;}
						case string_concat_ext:{
							if (array_length(node.arguments) >= 1)
							&& (array_length(node.arguments) <= 3) {
								throw $"\nArgument count for string_concat_ext is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_concat_ext, node);
						break;}
						case string_copy:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for string_copy is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_copy, node);
						break;}
						case string_count:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for string_count is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_count, node);
						break;}
						case string_delete:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for string_delete is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_delete, node);
						break;}
						case string_digits:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for string_digits is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_digits, node);
						break;}
						case string_ends_with:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for string_ends_with is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_ends_with, node);
						break;}
						case string_ext:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for string_ext is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_ext, node);
						break;}
						case string_format:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for string_format is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_format, node);
						break;}
						case string_hash_to_newline:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for string_hash_to_newline is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_hash_to_newline, node);
						break;}
						case string_insert:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for string_insert is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_insert, node);
						break;}
						case string_join_ext:{
							if (array_length(node.arguments) >= 2)
							&& (array_length(node.arguments) <= 4) {
								throw $"\nArgument count for string_join_ext is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_join_ext, node);
						break;}
						case string_last_pos:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for string_last_pos is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_last_pos, node);
						break;}
						case string_last_pos_ext:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for string_last_pos_ext is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_last_pos_ext, node);
						break;}
						case string_length:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for string_length is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_length, node);
						break;}
						case string_letters:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for string_letters is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_letters, node);
						break;}
						case string_ord_at:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for string_ord_at is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_ord_at, node);
						break;}
						case string_pos:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for string_pos is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_pos, node);
						break;}
						case string_pos_ext:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for string_pos_ext is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_pos_ext, node);
						break;}
						case string_replace:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for string_replace is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_replace, node);
						break;}
						case string_replace_all:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for string_replace_all is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_replace_all, node);
						break;}
						case string_set_byte_at:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for string_set_byte_at is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_set_byte_at, node);
						break;}
						case string_starts_with:{
							if (array_length(node.arguments) != 2) {
								throw $"\nArgument count for string_starts_with is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_starts_with, node);
						break;}
						case string_trim:{
							if (array_length(node.arguments) >= 1)
							&& (array_length(node.arguments) <= 2) {
								throw $"\nArgument count for string_trim is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_trim, node);
						break;}
						case string_trim_end:{
							if (array_length(node.arguments) >= 1)
							&& (array_length(node.arguments) <= 2) {
								throw $"\nArgument count for string_trim_end is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_trim_end, node);
						break;}
						case string_trim_start:{
							if (array_length(node.arguments) >= 1)
							&& (array_length(node.arguments) <= 2) {
								throw $"\nArgument count for string_trim_start is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(string_trim_start, node);
						break;}
						case md5_string_unicode:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for md5_string_unicode is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(md5_string_unicode, node);
						break;}
						case md5_string_utf8:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for md5_string_utf8 is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(md5_string_utf8, node);
						break;}
						case color_get_hue:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for color_get_hue is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(color_get_hue, node);
						break;}
						case colour_get_hue:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for colour_get_hue is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(colour_get_hue, node);
						break;}
						case color_get_saturation:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for color_get_saturation is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(color_get_saturation, node);
						break;}
						case colour_get_saturation:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for colour_get_saturation is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(colour_get_saturation, node);
						break;}
						case color_get_value:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for color_get_value is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(color_get_value, node);
						break;}
						case colour_get_value:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for colour_get_value is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(colour_get_value, node);
						break;}
						case base64_encode:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for base64_encode is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(base64_encode, node);
						break;}
						case base64_decode:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for base64_decode is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(base64_decode, node);
						break;}
						case sha1_string_utf8:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for sha1_string_utf8 is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(sha1_string_utf8, node);
						break;}
						case sha1_string_unicode:{
							if (array_length(node.arguments) != 1) {
								throw $"\nArgument count for sha1_string_unicode is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(sha1_string_unicode, node);
						break;}
						case make_color_hsv:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for make_color_hsv is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(make_color_hsv, node);
						break;}
						case make_colour_hsv:{
							if (array_length(node.arguments) != 3) {
								throw $"\nArgument count for make_colour_hsv is incorrect!\nArgument Count : {array_length(node.arguments)}"
							}
							return __build_literal_from_function_call_constant_folding(make_colour_hsv, node);
						break;}
						
						
						//all of the ones above use the same code
						case string:{
							if (array_length(node.arguments) < 1) {
								throw $"\nArgument count for string is incorrect!\nArgument Count : {array_length(node.arguments)}"
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
								throw $"\nArgument count for string_concat is incorrect!\nArgument Count : {array_length(node.arguments)}"
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
									return new ASTNode("FunctionCall", {callee: node.callee, arguments: _arr});
								}
							}
							
						break;}
						case string_join:{
							if (array_length(node.arguments) < 1) {
								throw $"\nArgument count for string_join is incorrect!\nArgument Count : {array_length(node.arguments)}"
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
						
						
//buffer_sizeof

						
					}
				break;}
				// Add more cases as needed for different node types
			}
			
			return node;
		};
		
		static singleWriteOptimization = function(node) {
			// Replace single-assignment variables with their values
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
								return new ASTBlockStatement([], node.line, node.lineString)
							}
						}
					}
				break;}
				case "ForStatement":{
					if (node.condition.type == "Literal") {
						if (!node.condition.value) {
							return new ASTBlockStatement([], node.line, node.lineString)
						}
					}
				break;}
				case "WhileStatement":{
					if (node.condition.type == "Literal") {
						if (!node.condition.value) {
							return new ASTBlockStatement([], node.line, node.lineString)
						}
					}
				break;}
				case "RepeatStatement":{
					if (node.condition.type == "Literal") {
						if (!node.condition.value) {
							return new ASTBlockStatement([], node.line, node.lineString)
						}
					}
				break;}
				case "DoUntillStatement":{
					if (node.condition.type == "Literal") {
						if (!node.condition.value) {
							return new ASTBlockStatement([], node.line, node.lineString)
						}
					}
				break;}
				case "WithStatement":{
					if (node.condition.type == "Literal") {
						if (node.condition.value == noone) {
							return new ASTBlockStatement([], node.line, node.lineString)
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
								_return = new ASTBlockStatement([], node.line, node.lineString)
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
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: struct_get_from_hash, name: "struct_get_from_hash"}),
								arguments: [
									node.arguments[0],
									new ASTNode("Literal", {value: variable_get_hash(_arg.value), scope: ScopeType.CONST})
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
							return new ASTNode("FunctionCall", {
								callee: new ASTNode("Function", {value: struct_set_from_hash, name: "struct_set_from_hash"}),
								arguments: [
									node.arguments[0],
									new ASTNode("Literal", {value: variable_get_hash(_arg.value), scope: ScopeType.CONST}),
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
								return new ASTNode("FunctionCall", {
									callee: new ASTNode("Function", {value: string_concat, name: "string_concat"}),
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
			// Hoist and remove duplicate variable declarations
		};
		
		static tailCallOptimization = function(node) {
			// Convert tail-recursive functions into iterative forms
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
		
		static memoryAccessOptimization = function(node) {
			// Reorder data accesses to improve cache locality
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
		
		static handleAccessorFunctionCall = function(accessorType, _args) {
		    var _getterFunc, _setterFunc;
			
			// Getter context
		    switch (accessorType) {
				case __GMLC_AccessorType.Array:  _getterFunc = new ASTFunction(array_get,               node.line, node.lineString); _setterFunc = new ASTFunction(array_set,   node.line, node.lineString); break;
				case __GMLC_AccessorType.List:   _getterFunc = new ASTFunction(ds_list_find_value,      node.line, node.lineString); _setterFunc = new ASTFunction(ds_list_set, node.line, node.lineString); break;
				case __GMLC_AccessorType.Map:    _getterFunc = new ASTFunction(ds_map_find_value,       node.line, node.lineString); _setterFunc = new ASTFunction(ds_map_set,  node.line, node.lineString); break;
				case __GMLC_AccessorType.Grid:   _getterFunc = new ASTFunction(ds_grid_get,             node.line, node.lineString); _setterFunc = new ASTFunction(ds_grid_set, node.line, node.lineString); break;
				case __GMLC_AccessorType.Struct: _getterFunc = new ASTFunction(struct_get,              node.line, node.lineString); _setterFunc = new ASTFunction(struct_set,  node.line, node.lineString); break;
				case __GMLC_AccessorType.Dot:    _getterFunc = new ASTFunction(__struct_get_with_error, node.line, node.lineString); _setterFunc = new ASTFunction(struct_set,  node.line, node.lineString); break;
				default: throw $"\nUnexpected entry into handleAccessorFunctionCall with accessorType: {accessorType}" break;
			}
			
			var _get_expr = new ASTCallExpression(_getterFunc, _args, node.line, node.lineString);
			//var expr = parseLogicalOrExpression();
			
			if (currentToken != undefined)
			&& (currentToken.type == __GMLC_NodeType.Operator) {
				var _op = currentToken.value;
				var _new_args = variable_clone(_args);
				var right;
				
				// Handle compound assignments
				static __op_arr = ["+=", "-=", "*=", "/=", "^=", "&=", "|=", "++", "--"];
				if (_op == "=") {
					nextToken(); // Consume the operator
					
					var expr = parseLogicalOrExpression();
					array_push(_new_args, expr);
					return new ASTNode("FunctionCall", {callee: _setterFunc, arguments: _new_args});
				}
				else if (array_contains(__op_arr, _op)) {
					nextToken(); // Consume the operator
					
					// Determine the right-hand side expression based on the operator
					switch (_op) {
						case "+=": case "-=": case "*=": case "/=":
						case "^=": case "&=": case "|=":
						    right = parseLogicalOrExpression(); break;
						case "++": case "--":
						    right = new ASTNode("Literal", {value: 1, scope: ScopeType.CONST}); break;
					}
					
					// Create binary expression node
					var adjustedOperator = string_copy(_op, 1, 1); // Remove '=' or adjust for '++'/'--'
					var expr = new ASTNode("BinaryExpression", {operator: adjustedOperator, left: _get_expr, right: right});
					array_push(_new_args, expr);
					
					// Return the setter function call with updated arguments
					return new ASTNode("FunctionCall", {callee: _setterFunc, arguments: _new_args});
				}
				else {
					return _get_expr; // For unsupported operators or when no assignment is detected
				}
			}
			
		    return _get_expr;
		};
		#endregion
	}
#endregion

#region Interpreter.gml
	
	#region 4. Interpreter Module
	/*
	Purpose: To traverse the AST and execute the program.
	
	Methods:
	
	interpret(ast): Traverse the AST and execute commands.
	evaluateExpression(node): Evaluate an expression AST node.
	executeStatement(node): Execute a statement AST node.
	*/
	#endregion
	#region ByteOp Enum
	// add or remove a slash here to toggle between enums and string lookups
	/*
	enum ByteOp {
		OPERATOR, //any mathmatical or logical operation
		CALL, // function call
		INC, // Increment
		DEC, // Decrement
		JUMP, // Jump
		JUMP_IF_TRUE, // Jump if true
		JUMP_IF_FALSE, // Jump if false
		RETURN, // Return a value
		DUP, // Duplicate the top of the stack
		POP, // Pop the top of the stack
		
		
		// Loading from a variable location
		LOAD,
		STORE,
		
		// try-catch-finally specific ops
		TRY_START,
		TRY_END,
		CATCH_START,
		CATCH_END,
		FINALLY_START,
		FINALLY_END,
		
		END, // end of file OR Exit statement
		
		__SIZE__,
	}
	enum ScopeType {
		GLOBAL,
		LOCAL,
		STATIC,
		INSTANCE,
		CONST,
		UNIQUE,
		
		__SIZE__
	}
	enum OpCode {
		REMAINDER,    // The remainder `%` operator.
	    MULTIPLY,    // The `*` operator.
	    DIVIDE,    // The `/` operator.
	    DIVIDE_INT,    // The integer division `//` operator.
	    SUBTRACT,    // The `-` operator.
	    PLUS,    // The `+` operator.
	    EQUAL,    // The `==` operator.
	    NOT_EQUAL,    // The `!=` operator.
	    GREATER,    // The `>` operator.
	    GREATER_EQUAL,    // The `>=` operator.
	    LESS,    // The `<` operator.
	    LESS_EQUAL,    // The `<=` operator.
	    NOT,    // The logical negation `!` operator.
	    BITWISE_NOT,    // The bitwise negation `~` operator.
	    SHIFT_RIGHT,    // The bitwise right shift `>>` operator.
	    SHIFT_LEFT,    // The bitwise left shift `<<` operator.
	    BITWISE_AND,    // The bitwise AND `&` operator.
	    BITWISE_XOR,    // The bitwise XOR `^` operator.
	    BITWISE_OR,    // The bitwise OR `|` operator.
		OR,    // The logical OR operator.
		AND,    // The logical AND operator.
	    XOR,    // The logical XOR operator.
		NEGATE,    // The negation prefix.
		INC,    // increment.
		DEC,    // decrement.
		
		__SIZE__
	}
	/*/
	function ByteOp() {
		static OPERATOR = "ByteOp.OPERATOR";
		static CALL = "ByteOp.CALL";
		static JUMP = "ByteOp.JUMP";
		static JUMP_IF_TRUE = "ByteOp.JUMP_IF_TRUE";
		static JUMP_IF_FALSE = "ByteOp.JUMP_IF_FALSE";
		static RETURN = "ByteOp.RETURN";
		static DUP = "ByteOp.DUP";
		static POP = "ByteOp.POP";
		
		static JUMP_EXPECT = "ByteOp.JUMP_EXPECT"
		
				// Loading from a variable location
		static LOAD = "ByteOp.LOAD";
		static STORE = "ByteOp.STORE";
		
				// try-catch-finally specific ops
		static TRY_START = "ByteOp.TRY_START";
		static TRY_END = "ByteOp.TRY_END";
		static CATCH_START = "ByteOp.CATCH_START";
		static CATCH_END = "ByteOp.CATCH_END";
		static FINALLY_START = "ByteOp.FINALLY_START";
		static FINALLY_END = "ByteOp.FINALLY_END";
		
		static WITH_START = "ByteOp.WITH_START";
		static WITH_END =   "ByteOp.WITH_END";
		
		static END = "ByteOp.END";
		
		static THROW = "ByteOp.THROW";
		
		static __SIZE__ = "__SIZE__";
	}
	function ScopeType() {
		static MACRO = "ScopeType.MACRO";
		static GLOBAL = "ScopeType.GLOBAL";
		static ENUM = "ScopeType.ENUM";
		static UNIQUE = "ScopeType.UNIQUE";
		static LOCAL = "ScopeType.LOCAL";
		static STATIC = "ScopeType.STATIC";
		static INSTANCE = "ScopeType.INSTANCE";
		static CONST = "ScopeType.CONST";
		
		static __SIZE__ = "__SIZE__";
	}
	function OpCode() {
		static REMAINDER = "OpCode.REMAINDER";
		static MULTIPLY = "OpCode.MULTIPLY";
		static DIVIDE = "OpCode.DIVIDE";
		static DIVIDE_INT = "OpCode.DIVIDE_INT";
		static SUBTRACT = "OpCode.SUBTRACT";
		static PLUS = "OpCode.PLUS";
		static EQUAL = "OpCode.EQUAL";
		static NOT_EQUAL = "OpCode.NOT_EQUAL";
		static GREATER = "OpCode.GREATER";
		static GREATER_EQUAL = "OpCode.GREATER_EQUAL";
		static LESS = "OpCode.LESS";
		static LESS_EQUAL = "OpCode.LESS_EQUAL";
		static NOT = "OpCode.NOT";
		static BITWISE_NOT = "OpCode.BITWISE_NOT";
		static SHIFT_RIGHT = "OpCode.SHIFT_RIGHT";
		static SHIFT_LEFT = "OpCode.SHIFT_LEFT";
		static BITWISE_AND = "OpCode.BITWISE_AND";
		static BITWISE_XOR = "OpCode.BITWISE_XOR";
		static BITWISE_OR = "OpCode.BITWISE_OR";
		static OR = "OpCode.OR";
		static AND = "OpCode.AND";
		static XOR = "OpCode.XOR";
		static NEGATE = "OpCode.NEGATE";
		static INC = "OpCode.INC";
		static DEC = "OpCode.DEC";
		static NULLISH = "OpCode.NULLISH";
		
		static __SIZE__ = "__SIZE__";
	}
	ByteOp()
	ScopeType()
	OpCode()
	//*/
	#endregion
	#region Classes
	function __GMLC_Script() constructor {
		GlobalVar = {};
		IR = [];
		
		static execute = __executeIR
	}
	function __GMLC_Function() constructor {
		StaticVar = {};
		IR = [];
		
		static execute = __executeIR
	}
	#endregion
	#region Functions
	function __executeIR(_argument0, _argument1, _argument2, _argument3, _argument4, _argument5, _argument6, _argument7, _argument8, _argument9, _argument10, _argument11, _argument12, _argument13, _argument14, _argument15) {
		var _ir = self.IR;
		var _ip = 0; // the instruction pointer
	    var _stack = [];
		var _framePointer = 0; // To manage function calls and returns
		
	    var _globalVar = self[$ "GlobalVar"]; //to manage global variables
	    var _staticVar = self[$ "StaticVar"]; //to manage static variables
	    var _localVar = {}; //to manage local variables
	    
		return __executeInstructionUntil(_ir, _ip, _stack, _globalVar, _staticVar, _localVar, ByteOp.END, 0);
	}
	function __executeInstructionUntil(_ir, _ip, _stack, _globalVar, _staticVar, _localVar, _endByte, _depth) {
		gml_pragma("forceinline");
		
		var _preffix = string_repeat(" - ", (_depth+1)*2)
		log($"{_preffix}Entered :: {_ip} :: __executeInstructionUntil :: {_endByte}")
		
		//var _ir_length = array_length(_ir);
		//while (_ip < _ir_length) {
		while (true) {
			var _instr = _ir[_ip]; // the instruction
				
			log($"{_preffix}IP :: {_ip} :: {_instr}")
			var _op = _instr.op
		    switch (_op) {
	            
				case ByteOp.OPERATOR: {
					var right = array_pop(_stack);
					var left, result;
					
					switch(_instr.operator) {
						case OpCode.REMAINDER:{
							left = array_pop(_stack);
							result = left % right;
						break;}
						case OpCode.MULTIPLY:{
							left = array_pop(_stack);
							result = left * right;
						break;}
						case OpCode.DIVIDE:{
							left = array_pop(_stack);
							result = left / right;
						break;}
						case OpCode.DIVIDE_INT:{
							left = array_pop(_stack);
							result = left div right;
						break;}
						case OpCode.SUBTRACT:{
							left = array_pop(_stack);
							result = left - right;
						break;}
						case OpCode.PLUS:{
							left = array_pop(_stack);
							result = left + right;
						break;}
						case OpCode.EQUAL:{
							left = array_pop(_stack);
							result = (left == right);
						break;}
						case OpCode.NOT_EQUAL:{
							left = array_pop(_stack);
							result = (left != right);
						break;}
						case OpCode.GREATER:{
							left = array_pop(_stack);
							result = (left > right);
						break;}
						case OpCode.GREATER_EQUAL:{
							left = array_pop(_stack);
							result = (left >= right);
						break;}
						case OpCode.LESS:{
							left = array_pop(_stack);
							result = (left < right);
						break;}
						case OpCode.LESS_EQUAL:{
							left = array_pop(_stack);
							result = (left <= right);
						break;}
						case OpCode.NOT:{
							result = !right;
						break;}
						case OpCode.BITWISE_NOT:{
							result = ~right;
						break;}
						case OpCode.SHIFT_RIGHT:{
							left = array_pop(_stack);
							result = left >> right;
						break;}
						case OpCode.SHIFT_LEFT:{
							left = array_pop(_stack);
							result = left << right;
						break;}
						case OpCode.BITWISE_AND:{
							left = array_pop(_stack);
							result = left & right;
						break;}
						case OpCode.BITWISE_XOR:{
							left = array_pop(_stack);
							result = left ^ right;
						break;}
						case OpCode.BITWISE_OR:{
							left = array_pop(_stack);
							result = left | right;
						break;}
						case OpCode.OR:{
							left = array_pop(_stack);
							result = left || right;
						break;}
						case OpCode.AND:{
							left = array_pop(_stack);
							result = left && right;
						break;}
						case OpCode.XOR:{
							left = array_pop(_stack);
							result = (left ^^ right);
						break;}
						case OpCode.NEGATE:{
							result = -right;
						break;}
						case OpCode.INC:{
							result = right + 1;
						break;}
						case OpCode.DEC:{
							result = right - 1;
						break;}
						case OpCode.NULLISH:{
							left = array_pop(_stack);
							result = left ?? right;
						break;}
						
					}
					
					array_push(_stack, result);
					
				break;}
				
				case ByteOp.CALL:{
					var _result;
					
					// Retrieve arguments for the function. `_instr.count` tells us how many arguments are passed.
					var _args = [];
					var _stack_length = array_length(_stack);
					var _i=0; repeat(_instr.count) {
						array_push(_args, _stack[_stack_length - _instr.count + _i]); // Reverse order since stack is LIFO
					_i+=1;}//end repeat loop
					
					//resize stack
					array_resize(_stack, _stack_length - _instr.count)
					
					//execute depending on if it's a gml global script, or a module we're simply pointing to
					//var _func;
					//if (is_instanceof(_instr.value, __GMLC_Script)) _func = _instr.value.execute;
					//else if (is_instanceof(_instr.value, __GMLC_Function)) _func = _instr.value.execute;
					//else _func = _instr.value;
					var _func = array_pop(_stack);
					
					//excute
					if (is_instanceof(_func, __GMLC_Function)) {
						switch(_instr.count) {
							case 0:  _func.execute();
							case 1:  _func.execute(_args[0]);
							case 2:  _func.execute(_args[0], _args[1]);
							case 3:  _func.execute(_args[0], _args[1], _args[2]);
							case 4:  _func.execute(_args[0], _args[1], _args[2], _args[3]);
							case 5:  _func.execute(_args[0], _args[1], _args[2], _args[3], _args[4]);
							case 6:  _func.execute(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5]);
							case 7:  _func.execute(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6]);
							case 8:  _func.execute(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7]);
							case 9:  _func.execute(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8]);
							case 10: _func.execute(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9]);
							case 11: _func.execute(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10]);
							case 12: _func.execute(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10], _args[11]);
							case 13: _func.execute(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10], _args[11], _args[12]);
							case 14: _func.execute(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10], _args[11], _args[12], _args[13]);
							case 15: _func.execute(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10], _args[11], _args[12], _args[13], _args[14]);
						}
					}
					else {
						//log(["_func", _func, script_get_name(_func)])
						//log(["_args", _args])
						_result = script_execute_ext(_func, _args);
					}
					
					// Push the result of the function call onto the stack
					array_push(_stack, _result);
					
					
					// Manage stack frame when we impliment that if necessary
					// Here handle more complex frame operations when we maintain a call stack
					// For example:
					// _framePointer = array_length(_stack); // Update frame pointer to new frame
					// _localVar = {}; // Reset local variables for the new frame
				break;}
				case ByteOp.JUMP:{
					// Adjust the instruction pointer based on offset
					_ip += _instr.offset;
					
					if (GML_COMPILER_DEBUG)
					&& (_ir[_ip].op != ByteOp.JUMP_EXPECT) {
						log("IR :: "+json_stringify(self, true))
						throw $"\nJumped to unexpected location\nJump instruction :: {_instr}\nCurrent Instruction :: {_ir[_ip]}\nIP :: {_ip}"
					}
					
					continue; //skip the _ip inc
				break;}
				case ByteOp.JUMP_IF_TRUE:{
					// Jump if true
					if (array_pop(_stack)) {
						_ip += _instr.offset;
						
						if (GML_COMPILER_DEBUG)
						&& (_ir[_ip].op != ByteOp.JUMP_EXPECT) {
							log("IR :: "+json_stringify(self, true))
							throw $"\nJumped to unexpected location\nJump instruction :: {_instr}\nCurrent Instruction :: {_ir[_ip]}\nIP :: {_ip}"
						}
						
						continue; //skip the _ip inc
					}
				break;}
				case ByteOp.JUMP_IF_FALSE:{
					// Jump if false
					if (!array_pop(_stack)) {
						_ip += _instr.offset;
						
						if (GML_COMPILER_DEBUG)
						&& (_ir[_ip].op != ByteOp.JUMP_EXPECT) {
							log("IR :: "+json_stringify(self, true))
							throw $"\nJumped to unexpected location\nJump instruction :: {_instr}\nCurrent Instruction :: {_ir[_ip]}\nIP :: {_ip}"
						}
						
						continue; //skip the _ip inc
					}
				break;}
				
				case ByteOp.DUP:{
					// Duplicate the last element on the stack
					_stack[array_length(_stack)] = _stack[array_length(_stack)-1];
				break;}
				case ByteOp.POP:{
					//Clear the last element from the stack (used for internal clean ups of repeat loops)
					array_pop(_stack)
				break;}
				case ByteOp.LOAD:{
					//
					switch (_instr.scope) {
						case ScopeType.GLOBAL:{
							//
							array_push(_stack, __struct_get_with_error(_globalVar, _instr.value));
						break;}
						case ScopeType.LOCAL:{
							//
							array_push(_stack, __struct_get_with_error(_localVar, _instr.value));
						break;}
						case ScopeType.STATIC:{
							//
							array_push(_stack, __struct_get_with_error(_staticVar, _instr.value));
						break;}
						case ScopeType.INSTANCE:{
							//
							if (is_instanceof(self, __GMLC_Script)) {
								/// NOTE: this is only a partch to continue testing, in the long run we should already know the scope.
								array_push(_stack, __struct_get_with_error(_globalVar, _instr.value));
							}
							else {
								array_push(_stack, __struct_get_with_error(self, _instr.value));
							}
						break;}
						case ScopeType.CONST:{
							// Load a constant value
							array_push(_stack, _instr.value);
						break;}
						case ScopeType.UNIQUE:{
							// Find the constant to load
							var _val;
							switch (_instr.value) {
								case "self":                     _val = self;                        break;
								case "other":                    _val = other;                       break;
								case "all":                      _val = all;                         break;
								case "noone":                    _val = noone;                       break;
								
								case "fps":                      _val = fps;                       break;
								case "room":                     _val = room;                      break;
								case "lives":                    _val = lives;                     break;
								case "score":                    _val = score;                     break;
								case "health":                   _val = health;                    break;
								case "mouse_x":                  _val = mouse_x;                   break;
								case "visible":                  _val = visible;                   break;
								case "managed":                  _val = managed;                   break;
								case "mouse_y":                  _val = mouse_y;                   break;
								case "os_type":                  _val = os_type;                   break;
								case "game_id":                  _val = game_id;                   break;
								case "iap_data":                 _val = iap_data;                  break;
								case "argument":                 _val = argument;                  break;
								case "fps_real":                 _val = fps_real;                  break;
								case "room_last":                _val = room_last;                 break;
								case "argument4":                _val = argument4;                 break;
								case "argument2":                _val = argument2;                 break;
								case "argument3":                _val = argument3;                 break;
								case "argument9":                _val = argument9;                 break;
								case "argument6":                _val = argument6;                 break;
								case "argument1":                _val = argument1;                 break;
								case "argument8":                _val = argument8;                 break;
								case "os_device":                _val = os_device;                 break;
								case "argument0":                _val = argument0;                 break;
								case "argument7":                _val = argument7;                 break;
								case "argument5":                _val = argument5;                 break;
								case "delta_time":               _val = delta_time;                break;
								case "show_lives":               _val = show_lives;                break;
								case "path_index":               _val = path_index;                break;
								case "room_first":               _val = room_first;                break;
								case "room_width":               _val = room_width;                break;
								case "view_hport":               _val = view_hport;                break;
								case "view_xport":               _val = view_xport;                break;
								case "view_yport":               _val = view_yport;                break;
								case "debug_mode":               _val = debug_mode;                break;
								case "event_data":               _val = event_data;                break;
								case "view_wport":               _val = view_wport;                break;
								case "os_browser":               _val = os_browser;                break;
								case "os_version":               _val = os_version;                break;
								case "argument10":               _val = argument10;                break;
								case "argument11":               _val = argument11;                break;
								case "argument12":               _val = argument12;                break;
								case "argument14":               _val = argument14;                break;
								case "argument15":               _val = argument15;                break;
								case "room_speed":               _val = room_speed;                break;
								case "show_score":               _val = show_score;                break;
								case "argument13":               _val = argument13;                break;
								case "error_last":               _val = error_last;                break;
								case "display_aa":               _val = display_aa;                break;
								case "async_load":               _val = async_load;                break;
								case "instance_id":              _val = instance_id;               break;
								case "current_day":              _val = current_day;               break;
								case "view_camera":              _val = view_camera;               break;
								case "room_height":              _val = room_height;               break;
								case "show_health":              _val = show_health;               break;
								case "mouse_button":             _val = mouse_button;              break;
								case "keyboard_key":             _val = keyboard_key;              break;
								case "view_visible":             _val = view_visible;              break;
								case "game_save_id":             _val = game_save_id;              break;
								case "current_hour":             _val = current_hour;              break;
								case "room_caption":             _val = room_caption;              break;
								case "view_enabled":             _val = view_enabled;              break;
								case "event_action":             _val = event_action;              break;
								case "view_current":             _val = view_current;              break;
								case "current_time":             _val = current_time;              break;
								case "current_year":             _val = current_year;              break;
								case "browser_width":            _val = browser_width;             break;
								case "webgl_enabled":            _val = webgl_enabled;             break;
								case "current_month":            _val = current_month;             break;
								case "caption_score":            _val = caption_score;             break;
								case "caption_lives":            _val = caption_lives;             break;
								case "gamemaker_pro":            _val = gamemaker_pro;             break;
								case "cursor_sprite":            _val = cursor_sprite;             break;
								case "caption_health":           _val = caption_health;            break;
								case "instance_count":           _val = instance_count;            break;
								case "argument_count":           _val = argument_count;            break;
								case "error_occurred":           _val = error_occurred;            break;
								case "current_minute":           _val = current_minute;            break;
								case "current_second":           _val = current_second;            break;
								case "temp_directory":           _val = temp_directory;            break;
								case "browser_height":           _val = browser_height;            break;
								case "view_surface_id":          _val = view_surface_id;           break;
								case "room_persistent":          _val = room_persistent;           break;
								case "current_weekday":          _val = current_weekday;           break;
								case "keyboard_string":          _val = keyboard_string;           break;
								case "cache_directory":          _val = cache_directory;           break;
								case "mouse_lastbutton":         _val = mouse_lastbutton;          break;
								case "keyboard_lastkey":         _val = keyboard_lastkey;          break;
								case "wallpaper_config":         _val = wallpaper_config;          break;
								case "background_color":         _val = background_color;          break;
								case "program_directory":        _val = program_directory;         break;
								case "game_project_name":        _val = game_project_name;         break;
								case "game_display_name":        _val = game_display_name;         break;
								case "argument_relative":        _val = argument_relative;         break;
								case "keyboard_lastchar":        _val = keyboard_lastchar;         break;
								case "working_directory":        _val = working_directory;         break;
								case "rollback_event_id":        _val = rollback_event_id;         break;
								case "background_colour":        _val = background_colour;         break;
								case "font_texture_page_size":   _val = font_texture_page_size;    break;
								case "application_surface":      _val = application_surface;       break;
								case "rollback_api_server":      _val = rollback_api_server;       break;
								case "gamemaker_registered":     _val = gamemaker_registered;      break;
								case "background_showcolor":     _val = background_showcolor;      break;
								case "rollback_event_param":     _val = rollback_event_param;      break;
								case "background_showcolour":    _val = background_showcolour;     break;
								case "rollback_game_running":    _val = rollback_game_running;     break;
								case "rollback_current_frame":   _val = rollback_current_frame;    break;
								case "rollback_confirmed_frame": _val = rollback_confirmed_frame;  break;
								
							}
							// Push to stack
							array_push(_stack, _val);
						break;}
					}
				break;}
				case ByteOp.STORE:{
					//
					var _result = array_pop(_stack);
					
					switch (_instr.scope) {
						case ScopeType.GLOBAL:{
							//
							struct_set(_globalVar, _instr.value, _result);
						break;}
						case ScopeType.LOCAL:{
							//
							struct_set(_localVar, _instr.value, _result);
						break;}
						case ScopeType.STATIC:{
							//
							struct_set(_staticVar, _instr.value, _result);
						break;}
						case ScopeType.INSTANCE:{
							//
							if (is_instanceof(self, __GMLC_Script)) {
								/// NOTE: this is only a partch to continue testing, in the long run we should already know the scope.
								struct_set(_globalVar, _instr.value, _result);
							}
							else {
								struct_set(self, _instr.value, _result);
							}
							
						break;}
						case ScopeType.CONST:{
							throw $"\nCan't ByteOp.STORE a ScopeType.CONST";
						break;}
						case ScopeType.UNIQUE:{
							// Find the constant to load
							var _val;
							switch (_instr.value) {
								//case "fps":                      fps                       = _val; break;
								case "room":                     room                      = _val; break;
								case "lives":                    lives                     = _val; break;
								case "score":                    score                     = _val; break;
								case "health":                   health                    = _val; break;
								//case "mouse_x":                  mouse_x                   = _val; break;
								case "visible":                  visible                   = _val; break;
								//case "managed":                  managed                   = _val; break;
								//case "mouse_y":                  mouse_y                   = _val; break;
								//case "os_type":                  os_type                   = _val; break;
								//case "game_id":                  game_id                   = _val; break;
								//case "iap_data":                 iap_data                  = _val; break;
								case "argument":                 argument                  = _val; break;
								//case "fps_real":                 fps_real                  = _val; break;
								//case "room_last":                room_last                 = _val; break;
								case "argument4":                argument4                 = _val; break;
								case "argument2":                argument2                 = _val; break;
								case "argument3":                argument3                 = _val; break;
								case "argument9":                argument9                 = _val; break;
								case "argument6":                argument6                 = _val; break;
								case "argument1":                argument1                 = _val; break;
								case "argument8":                argument8                 = _val; break;
								//case "os_device":                os_device                 = _val; break;
								case "argument0":                argument0                 = _val; break;
								case "argument7":                argument7                 = _val; break;
								case "argument5":                argument5                 = _val; break;
								case "delta_time":               delta_time                = _val; break;
								case "show_lives":               show_lives                = _val; break;
								//case "path_index":               path_index                = _val; break;
								//case "room_first":               room_first                = _val; break;
								case "room_width":               room_width                = _val; break;
								case "view_hport":               view_hport                = _val; break;
								case "view_xport":               view_xport                = _val; break;
								case "view_yport":               view_yport                = _val; break;
								//case "debug_mode":               debug_mode                = _val; break;
								//case "event_data":               event_data                = _val; break;
								case "view_wport":               view_wport                = _val; break;
								//case "os_browser":               os_browser                = _val; break;
								//case "os_version":               os_version                = _val; break;
								case "argument10":               argument10                = _val; break;
								case "argument11":               argument11                = _val; break;
								case "argument12":               argument12                = _val; break;
								case "argument14":               argument14                = _val; break;
								case "argument15":               argument15                = _val; break;
								case "room_speed":               room_speed                = _val; break;
								case "show_score":               show_score                = _val; break;
								case "argument13":               argument13                = _val; break;
								case "error_last":               error_last                = _val; break;
								//case "display_aa":               display_aa                = _val; break;
								//case "async_load":               async_load                = _val; break;
								//case "instance_id":              instance_id               = _val; break;
								//case "current_day":              current_day               = _val; break;
								case "view_camera":              view_camera               = _val; break;
								case "room_height":              room_height               = _val; break;
								case "show_health":              show_health               = _val; break;
								case "mouse_button":             mouse_button              = _val; break;
								case "keyboard_key":             keyboard_key              = _val; break;
								case "view_visible":             view_visible              = _val; break;
								//case "game_save_id":             game_save_id              = _val; break;
								//case "current_hour":             current_hour              = _val; break;
								case "room_caption":             room_caption              = _val; break;
								case "view_enabled":             view_enabled              = _val; break;
								//case "event_action":             event_action              = _val; break;
								//case "view_current":             view_current              = _val; break;
								//case "current_time":             current_time              = _val; break;
								//case "current_year":             current_year              = _val; break;
								//case "browser_width":            browser_width             = _val; break;
								//case "webgl_enabled":            webgl_enabled             = _val; break;
								//case "current_month":            current_month             = _val; break;
								case "caption_score":            caption_score             = _val; break;
								case "caption_lives":            caption_lives             = _val; break;
								//case "gamemaker_pro":            gamemaker_pro             = _val; break;
								case "cursor_sprite":            cursor_sprite             = _val; break;
								case "caption_health":           caption_health            = _val; break;
								//case "instance_count":           instance_count            = _val; break;
								//case "argument_count":           argument_count            = _val; break;
								case "error_occurred":           error_occurred            = _val; break;
								//case "current_minute":           current_minute            = _val; break;
								//case "current_second":           current_second            = _val; break;
								//case "temp_directory":           temp_directory            = _val; break;
								//case "browser_height":           browser_height            = _val; break;
								case "view_surface_id":          view_surface_id           = _val; break;
								case "room_persistent":          room_persistent           = _val; break;
								//case "current_weekday":          current_weekday           = _val; break;
								case "keyboard_string":          keyboard_string           = _val; break;
								//case "cache_directory":          cache_directory           = _val; break;
								case "mouse_lastbutton":         mouse_lastbutton          = _val; break;
								case "keyboard_lastkey":         keyboard_lastkey          = _val; break;
								//case "wallpaper_config":         wallpaper_config          = _val; break;
								case "background_color":         background_color          = _val; break;
								//case "program_directory":        program_directory         = _val; break;
								//case "game_project_name":        game_project_name         = _val; break;
								//case "game_display_name":        game_display_name         = _val; break;
								//case "argument_relative":        argument_relative         = _val; break;
								case "keyboard_lastchar":        keyboard_lastchar         = _val; break;
								//case "working_directory":        working_directory         = _val; break;
								//case "rollback_event_id":        rollback_event_id         = _val; break;
								case "background_colour":        background_colour         = _val; break;
								case "font_texture_page_size":   font_texture_page_size    = _val; break;
								//case "application_surface":      application_surface       = _val; break;
								//case "rollback_api_server":      rollback_api_server       = _val; break;
								//case "gamemaker_registered":     gamemaker_registered      = _val; break;
								case "background_showcolor":     background_showcolor      = _val; break;
								//case "rollback_event_param":     rollback_event_param      = _val; break;
								case "background_showcolour":    background_showcolour     = _val; break;
								//case "rollback_game_running":    rollback_game_running     = _val; break;
								//case "rollback_current_frame":   rollback_current_frame    = _val; break;
								//case "rollback_confirmed_frame": rollback_confirmed_frame  = _val; break;
								
							}
							// Push to stack
							array_push(_stack, _val);
						break;}
					}
				break;}
				case ByteOp.TRY_START:{
					var _temp_ip = _ip
					try {
						_ip++; // Move past the TRY_START
						
						//executeBlockUntil
						_ip = __executeInstructionUntil(_ir, _ip, _stack, _globalVar, _staticVar, _localVar, ByteOp.TRY_END, _depth+1);
						
					}
					catch(_err) {
						//log($"{_preffix}Catch")
						//push the err to the stack
						array_push(_stack, _err);
						
						_instr = _ir[_ip]
						if (_instr.op == ByteOp.RETURN)
						|| (_instr.op == ByteOp.END) {
							return _ip;
						}
						
						//move forward until we find TRY_END
						_instr = _ir[_ip]
						while (_instr.op != ByteOp.TRY_END) {
							_ip++;
							_instr = _ir[_ip];
						}
						
						_ip++; // Move past the TRY_END
						_instr = _ir[_ip];
						
						//early out if no CATCH_START was defined
						if (_instr.op != ByteOp.CATCH_START) return _ip;
						
						_ip++; // Move past the CATCH_START
						_instr = _ir[_ip];
						
						//executeBlockUntil
						_ip = __executeInstructionUntil(_ir, _ip, _stack, _globalVar, _staticVar, _localVar, ByteOp.CATCH_END, _depth+1);
					}
					finally {
						//log($"{_preffix}Finally :: {_instr}")
						_ip = _temp_ip;
						
						_instr = _ir[_ip]
						
						if (_instr.op != ByteOp.RETURN)
						&& (_instr.op != ByteOp.END) {
							
							_instr = _ir[_ip];
							if (_instr.op != ByteOp.FINALLY_START) {
								
								
								//move forward until we find TRY_END
								_instr = _ir[_ip];
								if (_instr.op == ByteOp.TRY_START) {
									while (_instr.op != ByteOp.TRY_END) {
										_ip++;
										_instr = _ir[_ip];
									}
									
									_ip++;
								}
						
								//move forward until we find the CATCH_END
								_instr = _ir[_ip];
								if (_instr.op == ByteOp.CATCH_START) {
									while (_instr.op != ByteOp.CATCH_END) {
										_ip++;
										_instr = _ir[_ip];
									}
									
									_ip++;
								}
							}
						
							//early out if no FINALLY_START was defined
							_instr = _ir[_ip];
							if (_instr.op == ByteOp.FINALLY_START) {
								_ip++; // Move past the FINALLY_START
							
								//executeBlockUntil
								_ip = __executeInstructionUntil(_ir, _ip, _stack, _globalVar, _staticVar, _localVar, ByteOp.FINALLY_END, _depth+1);
								
							}
						}
						
						
					}
					
				break;}
				
				case ByteOp.THROW:{
					// Terminate the execution
					throw array_pop(_stack);
				break;}
				
				case ByteOp.__SIZE__:{
					//
				break;}
		    }
			
			switch (_op) {
	            
				case ByteOp.RETURN:{
					// Pop the return value from the stack
					if (_depth == 0) {
						var _ret = array_pop(_stack);
						//log($"{_preffix}Returning :: {_ret} :: depth :: {_depth} :: __executeInstructionUntil :: {_endByte}\n{_stack}")
						return _ret;
					}
					//log($"{_preffix}Leaving :: {_ip} :: __executeInstructionUntil :: {_endByte}")
					return _ip;
				break;}
				
				case ByteOp.END:{
					log("found byte op end")
					// Terminate the execution
					if (_depth == 0) {
						return undefined;
					}
					return _ip
				break;}
		    }
				
			log(["_instr", _instr])
			_ip++;
		}
		
		throw "We should not be able to reach this location!"
	}
	#endregion
	function GML_Interpreter() constructor {
		origScript = undefined;
		currentScript = undefined;
		currentFunction = undefined;
		nodeStack = undefined;
		finished = false;
		
		//counter IDs
		__SwitchStatementCounterID = 0;
		__RepeatStatementCounterID = 0;
		
		static initialize = function(_ast) {
			origScript = new __GMLC_Script();
			currentScript = _ast;
			currentFunction = undefined;
			nodeStack = [];
			
			//apply the variable names and token streams from program to ast
			//origScript.MacroVar      = _ast.MacroVar;
			//origScript.MacroVarNames = _ast.MacroVarNames;
			//
			//origScript.EnumVar      = _ast.EnumVar;
			//origScript.EnumVarNames = _ast.EnumVarNames;
			//
			//origScript.GlobalVar      = _ast.GlobalVar;
			//origScript.GlobalVarNames = _ast.GlobalVarNames;
			
			// The last thing to be parsed will be the Script it's self
			array_push(nodeStack, {node: _ast, parent: undefined, key: undefined, index: undefined})
			
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
			
			var _i=0; repeat(array_length(origScript.IR)) {
				var _val = origScript.IR[_i];
				if (is_instanceof(_val, ASTNode) || is_array(_val)) {
					throw $"\nThere was an unconverted node!\n{_val}"
				}
				
			_i+=1;}//end repeat loop
			
			return origScript;
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
				
				if (currentNode.node.type == __GMLC_NodeType.FunctionDeclaration) {
					currentFunction = currentNode.node
				}
				
				// Push current node back onto stack to process after children
				array_push(nodeStack, currentNode);
				
				// Push current node back onto stack to process after children
				currentNode.node.push_children_to_node_stack(nodeStack);
			}
			else {
				if (currentNode.node.type == __GMLC_NodeType.FunctionDeclaration) {
					currentFunction = undefined;
				}
				
				// Process the current node as all children have been processed
				var _ir = generateIR(currentNode.node);
				
				if (currentNode.parent == undefined) {
					//the entire tree has been generated and we are at the top most "Program" node
					
					if (array_length(nodeStack)) {
						throw $"\nWe still have nodes in the nodeStack, we shouldn't be finished"
					}
					
					finished = true;
				}
				else {
					//reset the visit so the next module can make use of it
					if (currentNode.index != undefined) {
						currentNode.parent[$ currentNode.key][currentNode.index] = _ir;
					}
					else {
						currentNode.parent[$ currentNode.key] = _ir;
					}
				}
				
			}
		};
		
		static generateIR = function(node) {
			var ir = [];
			
			switch (node.type) {
			    case __GMLC_NodeType.Script:{
					//array concat all statements into a single IR stream and apply to module's IR
					
					switch (array_length(node.statements)) {
						case 0:                                                          break;
						case 1:  ir = node.statements[0];                                break;
						default: ir = script_execute_ext(array_concat, node.statements); break;
					}
					
					array_push(ir, {op: ByteOp.END, line: node.line, lineString: node.lineString});
					
					origScript.IR = array_concat(origScript.IR, ir);
					
					
					//push the global functions and constructors
					var _names = struct_get_names(node.GlobalVar)
					var _i=0; repeat(array_length(_names)) {
						
						//overwrite the globals in the module with the provided ones
						origScript.GlobalVar[$ _names[_i]] = node.GlobalVar[$ _names[_i]];
						
					_i+=1;}//end repeat loop
					
					currentScript = origScript;
					
					return undefined;
				break;}
				case __GMLC_NodeType.FunctionDeclaration:{
					var _defFunc = new __GMLC_Function();
					
					// Handle parameters and body
					_defFunc.IR = array_concat(_defFunc.IR, node.parameters, node.body);
					array_push(_defFunc.IR, {op: ByteOp.END, line: node.line, lineString: node.lineString})
					
					//return the function module to be placed in the
					currentScript.GlobalVar[$ node.name] = _defFunc;
					currentFunction = undefined;
					
					return _defFunc;
				break;}
				case __GMLC_NodeType.FunctionVariableDeclarationList:{
					// currentNode.statements
					ir = array_concat(ir, node.statements)
					
				break;}
				case __GMLC_NodeType.FunctionVariableDeclaration:{
					array_push(ir, { op: ByteOp.LOAD, scope: ScopeType.UNIQUE, value: $"argument{node.argument_index}" , line: node.line, lineString: node.lineString});
					
					//push the default expression
					ir = array_concat(ir, node.expr);
					
					array_push(ir, { op: ByteOp.OPERATOR, operator: OpCode.NULLISH , line: node.line, lineString: node.lineString});
					array_push(ir, { op : ByteOp.STORE, scope : ScopeType.LOCAL, value : node.identifier });
				break;}
				
				case __GMLC_NodeType.BlockStatement:{
					// currentNode.statements
					
					//compress into a single array
					switch (array_length(node.statements)) {
						case 0:                                                          break;
						case 1:  ir = node.statements[0];                                break;
						default: ir = script_execute_ext(array_concat, node.statements); break;
					}
				break;}
				case __GMLC_NodeType.IfStatement:{
					// Generate IR for the condition
				    ir = array_concat(ir, node.condition);
					
				    // Conditional jump to skip 'then' block if condition is false
				    var ifFalseJumpIndex = array_length(ir);
				    ir[ifFalseJumpIndex] = {op: ByteOp.JUMP_IF_FALSE, offset: undefined};  // offset patched la, line: node.line, lineString: node.lineStringter
					
				    // Generate IR for the 'then' block
				    ir = array_concat(ir, node.consequent);
					
				    // Jump after then block to skip 'else' block
				    if (node.alternate != undefined) {
						var jmpToEndIndex = array_length(ir);
				        ir[jmpToEndIndex] = {op: ByteOp.JUMP, offset: undefined};  // offset patched la, line: node.line, lineString: node.lineStringter
				    }
					
				    // Patch the jump-if-false to next instruction
				    ir[ifFalseJumpIndex].offset = array_length(ir)-ifFalseJumpIndex;
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
					
				    // Generate IR for the 'else' block if present
				    if (node.alternate != undefined) {
				        ir = array_concat(ir, node.alternate);

				        // Patch the unconditional jump to next instruction
				        ir[jmpToEndIndex].offset = array_length(ir)-jmpToEndIndex;
						if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
				    }
				break;}
				case __GMLC_NodeType.ForStatement:{
				    // Initialization
				    ir = array_concat(ir, node.initialization);
					
					// Jump to the following instruction
					var startLoopIndex = array_length(ir);
				    
					// Condition
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
				    ir = array_concat(ir, node.condition);
					
				    // Conditional jump to end if false
					var exitJumpIndex = array_length(ir);
				    ir[exitJumpIndex] = {op: ByteOp.JUMP_IF_FALSE, offset: undefined}; // offset will be patched la, line: node.line, lineString: node.lineStringter
				    
				    // Body of the loop
					ir = array_concat(ir, node.codeBlock);
					
					// Adapt the continue statements to this position
					__handleContinues(ir);
					
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
					
					// Increment
					ir = array_concat(ir, node.increment);
					
				    // Jump back to start
				    array_push(ir, {op: ByteOp.JUMP, offset: startLoopIndex-array_length(ir)}); // negative relative direct, line: node.line, lineString: node.lineStringion
					
					
				    // Patch the exit jump
				    ir[exitJumpIndex].offset = array_length(ir)-exitJumpIndex; // possitive relative direction
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
					
					//adapt the break statements to this position
					__handleBreaks(ir);
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
			    break;}
				case __GMLC_NodeType.WhileStatement:{
					var startLoopIndex = array_length(ir);
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
				    
					// Generate IR for the condition
				    ir = array_concat(ir, node.condition);
					
				    // Conditional jump to end if false
					var exitJumpIndex = array_length(ir);
				    ir[exitJumpIndex] = {op: ByteOp.JUMP_IF_FALSE, offset: undefined};  // offset patched la, line: node.line, lineString: node.lineStringter
					
				    // Generate IR for the loop body
				    ir = array_concat(ir, node.codeBlock);
					
					//adapt the continue statements to this position
					__handleContinues(ir);
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
					
				    // Jump back to condition
				    array_push(ir, {op: ByteOp.JUMP, offset: startLoopIndex - array_length(ir), line: node.line, lineString: node.lineString});
					
				    // Patch the exit jump to jump here
				    ir[exitJumpIndex].offset = array_length(ir) - exitJumpIndex;
					
					//adapt the break statements to this position
					__handleBreaks(ir);
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
				break;}
				case __GMLC_NodeType.RepeatStatement:{
					var _ref_str = $"__@@RepeatStatementCounterID{__RepeatStatementCounterID++}@@";
					
					// Push the initial loop count (from node.condition)
					ir = array_concat(ir, node.condition)
					
					// Duplicate the top of the stack for decrementing while keeping the original count
					array_push(ir, {op: ByteOp.STORE, scope: ScopeType.LOCAL, value: _ref_str, line: node.line, lineString: node.lineString});
					
					// Loop restarts here
					var loopStartIndex = array_length(ir);
					
					// Load the ref
					array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.LOCAL, value: _ref_str, line: node.line, lineString: node.lineString});
					
					// Loop setup
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
					var exitJumpIndex = array_length(ir);
					ir[exitJumpIndex] = {op: ByteOp.JUMP_IF_FALSE, offset: undefined};  // Will be patc, line: node.line, lineString: node.lineStringhed
					
					// Generate IR for the loop body
					ir = array_concat(ir, node.codeBlock);
					
					//adapt the continue statements to this position
					__handleContinues(ir);
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
					
					// Reload the reference
					array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.LOCAL, value: _ref_str, line: node.line, lineString: node.lineString});
					
					// Decrement the loop counter
					array_push(ir, {op: ByteOp.OPERATOR, operator: OpCode.DEC, line: node.line, lineString: node.lineString});
					
					// Duplicate the loop counter for the next iteration check
					array_push(ir, {op: ByteOp.STORE, scope: ScopeType.LOCAL, value: _ref_str, line: node.line, lineString: node.lineString});
					
					// Jump back to start
					array_push(ir, {op: ByteOp.JUMP, offset: loopStartIndex - array_length(ir), line: node.line, lineString: node.lineString});
					
					// Patch the exit jump to exit the loop
					ir[exitJumpIndex].offset = array_length(ir) - exitJumpIndex;
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
					
					//adapt the break statements to this position
					__handleBreaks(ir);
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
					
				break;}
				case __GMLC_NodeType.DoUntillStatement:{
					// currentNode.condition
					// currentNode.codeBlock
					var startLoopIndex = array_length(ir);
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
					
					// Generate IR for the loop body first since it executes before the condition check
					ir = array_concat(ir, node.codeBlock);
					
					//adapt the continue statements to this position
					__handleContinues(ir);
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
					
					// Generate IR for the condition
					ir = array_concat(ir, node.condition);
					
					// Jump back to the start of the loop body if condition is false
					array_push(ir, {op: ByteOp.JUMP_IF_FALSE, offset: startLoopIndex - array_length(ir)});  // To be patched to jump back if fa, line: node.line, lineString: node.lineStringlse
					
					//adapt the break statements to this position
					__handleBreaks(ir);
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
				break;}
				case __GMLC_NodeType.WithStatement:{
					// currentNode.condition
					// currentNode.codeBlock
					// Load the condition
					ir = array_concat(ir, node.condition);
					
					// Start of try block
					array_push(ir, {op: ByteOp.WITH_START, line: node.line, lineString: node.lineString});
					
					// IR for try block
					ir = array_concat(ir, node.codeBlock);
					
					// End of try block, start of catch
					array_push(ir, {op: ByteOp.WITH_END, line: node.line, lineString: node.lineString});
					
				break;}
				case __GMLC_NodeType.TryStatement:{
					// Start of try block
					array_push(ir, {op: ByteOp.TRY_START, line: node.line, lineString: node.lineString});
					
					// IR for try block
					ir = array_concat(ir, node.tryBlock);
					
					// End of try block, start of catch
					array_push(ir, {op: ByteOp.TRY_END, line: node.line, lineString: node.lineString});
					
					// IR for catch block
					if (node.catchBlock != undefined) {
						array_push(ir, {op: ByteOp.CATCH_START, line: node.line, lineString: node.lineString});
						// The VM will push the catch expression's value onto the stack.
						array_push(ir, {op: ByteOp.STORE, scope: ScopeType.LOCAL, value: node.exceptionVar, line: node.line, lineString: node.lineString});
						
					    ir = array_concat(ir, node.catchBlock);
						
						// End of catch block
						array_push(ir, {op: ByteOp.CATCH_END, line: node.line, lineString: node.lineString});
					}
					
					// IR for finally block
					if (node.finallyBlock != undefined) {
						array_push(ir, {op: ByteOp.FINALLY_START, line: node.line, lineString: node.lineString});
						
					    ir = array_concat(ir, node.finallyBlock);
						
						// End of finally block
						array_push(ir, {op: ByteOp.FINALLY_END, line: node.line, lineString: node.lineString});
					}
					
				break;}
				case __GMLC_NodeType.SwitchStatement:{
					var _ref_str = $"__@@SwitchStatementCounterID{__SwitchStatementCounterID++}@@";
					
					// Evaluate the switch expression
					ir = array_concat(ir, node.switchExpression);
					
					// Store the reference
					array_push(ir, {op: ByteOp.STORE, scope: ScopeType.LOCAL, value: _ref_str, line: node.line, lineString: node.lineString});
					
					var caseJumps = [];
					var _caseDefautLoc = undefined;
					
					// Prepare to compare and jump
					for (var i = 0; i < array_length(node.cases); i++) {
						
					    var caseNode = node.cases[i];
						if (caseNode.type == __GMLC_NodeType.CaseExpression) {
					        // Reload the reference
							array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.LOCAL, value: _ref_str, line: node.line, lineString: node.lineString});
							
							// Compare switch expression to case label
					        ir = array_concat(ir, caseNode.label);
					        array_push(ir, {op: ByteOp.OPERATOR, operator: OpCode.EQUAL, line: node.line, lineString: node.lineString});

					        // Jump to case start if true
							var jumpIndex = array_length(ir);
					        ir[jumpIndex] = {op: ByteOp.JUMP_IF_TRUE, offset: undefined}; // To be patc, line: node.line, lineString: node.lineStringhed
					        array_push(caseJumps, jumpIndex);
					    }
					}
					
					// Jump to default case or out of switch if no match
					var defaultJumpIndex = array_length(ir);
					ir[defaultJumpIndex] = {op: ByteOp.JUMP, offset: undefined}; // To be patc, line: node.line, lineString: node.lineStringhed
					
					// Generate case blocks
					for (var i = 0; i < array_length(node.cases); i++) {
					    var caseNode = node.cases[i];
					    // Patch the jump to this case
						switch(caseNode.type) {
							case __GMLC_NodeType.CaseExpression:{
								ir[caseJumps[i]].offset = array_length(ir) - caseJumps[i];
								if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
								
								// Generate case block IR
								ir = array_concat(ir, caseNode.codeBlock);
							break;}
							case __GMLC_NodeType.CaseDefault:{
								_caseDefautLoc = i
							break;}
						}
					}
					
					//patch the default/exit location
					ir[defaultJumpIndex].offset = array_length(ir) - defaultJumpIndex;
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
					
					// Generate default case if exists
					if (_caseDefautLoc != undefined) {
						ir = array_concat(ir, node.cases[_caseDefautLoc].codeBlock);
					}
					
					//adapt the break statements to this position
					__handleBreaks(ir);
					if GML_COMPILER_DEBUG array_push(ir, {op: ByteOp.JUMP_EXPEC, line: node.line, lineString: node.lineStringT})
				break;}
				case __GMLC_NodeType.CaseExpression:
				case __GMLC_NodeType.CaseDefault:{
					// handled by parent
					// the child nodes should already have been added into the nodeStack so they will already be compiled
					return node;
				break;}
				
				case __GMLC_NodeType.ThrowStatement: {
					ir = array_concat(ir, node.error);
					array_push(ir, {op: ByteOp.THROW, line: node.line, lineString: node.lineString});
				break;}
				
				case __GMLC_NodeType.BreakStatement:
				case __GMLC_NodeType.ContinueStatement:{
					// SKIP, this is handled by parent statements
					array_push(ir, node)
				break;}
				case __GMLC_NodeType.ExitStatement:{
					// Simply append an END operation to indicate termination of execution
					array_push(ir, {op: ByteOp.END, line: node.line, lineString: node.lineString})
				break;}
				case __GMLC_NodeType.ReturnStatement:{
					// If there is an expression associated with the return, evaluate it
					if (node.expr != undefined) {
					    ir = array_concat(ir, node.expr);
						// Push the result of the expression onto the stack (if any)
						array_push(ir, {op: ByteOp.RETURN, line: node.line, lineString: node.lineString});
					}
					else {
						array_push(ir, {op: ByteOp.END, line: node.line, lineString: node.lineString});
					}
					
				break;}
				
				case __GMLC_NodeType.VariableDeclarationList:{
					ir = array_concat(ir, node.statements);
				break;}
				case __GMLC_NodeType.VariableDeclaration:{
					// Check if there is an initializing expression
					if (node.expr != undefined) {
						// Evaluate the initializing expression
						ir = array_concat(ir, node.expr);
					} else {
						// Push a default value like `undefined` for uninitialized variables
					    array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.CONST, value: undefined, line: node.line, lineString: node.lineString});
					}

					// Determine the storage operation based on scope
					var _scopeType;
					switch (node.scope) {
						case ScopeType.GLOBAL:{
							_scopeType = ScopeType.GLOBAL;
						break;}
						case ScopeType.STATIC:{
							_scopeType = ScopeType.STATIC;
						break;}
						case ScopeType.LOCAL:{
							_scopeType = ScopeType.LOCAL;
						break;}
						case ScopeType.CONST:{
							_scopeType = ScopeType.CONST;
						break;}
						default:{
							_scopeType = ScopeType.INSTANCE;
						break;}
					}
					
					// Store the result of the expression into the variable based on scope
					array_push(ir, {op: ByteOp.STORE, scope: _scopeType, value: node.identifier, line: node.line, lineString: node.lineString});
					break;
				break;}
				
				case __GMLC_NodeType.CallExpression:{
					//push the function onto the stack
					ir = array_concat(ir, node.callee);
					
					//push the arguments onto the stack
					var _arg_ir;
					switch (array_length(node.arguments)) {
						case 0:  _arg_ir = undefined                                         break;
						case 1:  _arg_ir = node.arguments[0];                                break;
						default: _arg_ir = script_execute_ext(array_concat, node.arguments); break;
					}
					
					if (_arg_ir != undefined) {
						ir = array_concat(ir, _arg_ir);
					}
					
					array_push(ir, {op: ByteOp.CALL, count: array_length(node.arguments), line: node.line, lineString: node.lineString});
					
				break;}
				case __GMLC_NodeType.NewExpression:{
					
				break;}
				
				case __GMLC_NodeType.ExpressionStatement:{
					ir = array_concat(ir, node.expr);
				break;}
				case __GMLC_NodeType.AssignmentExpression:{
					
					// Determine the load operation based on the scope of the left-hand side
					if (array_length(node.left) > 1) {
						throw $"\nThere is a more unique assignment expression going on here, what is it?\n{json_stringify(node, true)}"
					}
					
					var _scopeType = __determineScopeType(node.left);
					
					// Load existing value for compound assignments
					if (node.operator != "=") {
						array_push(ir, {op: ByteOp.LOAD, scope: _scopeType, value: node.left.value, line: node.line, lineString: node.lineString});
					}
					
					// Evaluate the right-hand side expression
					ir = array_concat(ir, node.right);
					
					// Determine the operation to apply
					var operator;
					switch (node.operator) {
						case "+=": operator = OpCode.PLUS;        break;
						case "-=": operator = OpCode.SUBTRACT;    break;
						case "*=": operator = OpCode.MULTIPLY;    break;
						case "/=": operator = OpCode.DIVIDE;      break;
						case "^=": operator = OpCode.BITWISE_XOR; break;
						case "&=": operator = OpCode.BITWISE_AND; break;
						case "|=": operator = OpCode.BITWISE_OR;  break;
						case "=":  operator = undefined;          break; // Direct assignment doesn't need an operator
						default: throw $"\nUnsupported assignment operator: {node.operator}";
					}
					
					if (node.operator != "=") {
						array_push(ir, {op: ByteOp.OPERATOR, operator: operator, line: node.line, lineString: node.lineString});
					}
					
					// Store the computed value back
					array_push(ir, {op: ByteOp.STORE, scope: _scopeType, value: node.left.value, line: node.line, lineString: node.lineString});
				break;}
				case __GMLC_NodeType.BinaryExpression:{
					// Load the operands
					ir = array_concat(ir, node.left);
					ir = array_concat(ir, node.right);
					
					var _opCode;
					switch (node.operator) {
						case "=":   //
						case "==":  _opCode = OpCode.EQUAL         break;
						case "|":   _opCode = OpCode.BITWISE_OR;   break;
						case "^":   _opCode = OpCode.BITWISE_XOR;  break;
						case "&":   _opCode = OpCode.BITWISE_AND;  break;
						case "!=":  _opCode = OpCode.NOT_EQUAL     break;
						case "<":   _opCode = OpCode.LESS          break;
						case "<=":  _opCode = OpCode.LESS_EQUAL    break;
						case ">":   _opCode = OpCode.GREATER       break;
						case ">=":  _opCode = OpCode.GREATER_EQUAL break;
						case "<<":  _opCode = OpCode.SHIFT_LEFT    break;
						case ">>":  _opCode = OpCode.SHIFT_RIGHT   break;
						case "+":   _opCode = OpCode.PLUS          break;
						case "-":   _opCode = OpCode.SUBTRACT      break;
						case "*":   _opCode = OpCode.MULTIPLY      break;
						case "/":   _opCode = OpCode.DIVIDE        break;
						case "mod": _opCode = OpCode.REMAINDER     break;
						case "div": _opCode = OpCode.DIVIDE_INT    break;
					}
					// Apply the operation
					array_push(ir, {op: ByteOp.OPERATOR, operator: _opCode, line: node.line, lineString: node.lineString});
				break;}
				case __GMLC_NodeType.LogicalExpression:{
					// Load the operands
					ir = array_concat(ir, node.left);
					ir = array_concat(ir, node.right);
					
					switch (node.operator) {
						case "||": _opCode = OpCode.OR  break;
						case "&&": _opCode = OpCode.AND break;
						case "^^": _opCode = OpCode.XOR break;
					}

					
					// Apply the operation
					array_push(ir, {op: ByteOp.OPERATOR, operator: _opCode, line: node.line, lineString: node.lineString});
				break;}
				case __GMLC_NodeType.NullishExpression:{
					// Load the operands
					ir = array_concat(ir, node.left);
					ir = array_concat(ir, node.right);
					
					// Apply the operation
					array_push(ir, {op: ByteOp.OPERATOR, operator: OpCode.NULLISH, line: node.line, lineString: node.lineString});
				break;}
				case __GMLC_NodeType.UnaryExpression:{
					// Determine the load operation based on the scope of the expression
					var _scopeType = node.expr[0].scope;
					
					//push the identifier onto the stack
					ir = array_concat(ir, node.expr);
					
					switch (node.operator) {
						case "!":{
							array_push(ir, {op: ByteOp.OPERATOR, operator: OpCode.NOT, line: node.line, lineString: node.lineString});
						break;}
						case "+":{
							//nothing is needed here
						break;}
						case "-":{
							array_push(ir, {op: ByteOp.OPERATOR, operator: OpCode.NEGATE, line: node.line, lineString: node.lineString});
						break;}
						case "~":{
							array_push(ir, {op: ByteOp.OPERATOR, operator: OpCode.BITWISE_NOT, line: node.line, lineString: node.lineString});
						break;}
						case "++":{
							array_push(ir, {op: ByteOp.OPERATOR, operator: OpCode.INC, line: node.line, lineString: node.lineString});
							array_push(ir, {op: ByteOp.DUP, line: node.line, lineString: node.lineString});
							array_push(ir, {op: ByteOp.STORE, scope: _scopeType, value: node.expr[0].value, line: node.line, lineString: node.lineString});
							
						break;}
						case "--":{
							array_push(ir, {op: ByteOp.OPERATOR, operator: OpCode.DEC, line: node.line, lineString: node.lineString});
							array_push(ir, {op: ByteOp.DUP, line: node.line, lineString: node.lineString});
							array_push(ir, {op: ByteOp.STORE, scope: _scopeType, value: node.expr[0].value, line: node.line, lineString: node.lineString});
							
						break;}
					}
				break;}
				case __GMLC_NodeType.UpdateExpression:{
					// Determine the load operation based on the scope of the expression
					var _scopeType = __determineScopeType(node.expr);
					
					// Load and modify the value
					array_push(ir, {op: ByteOp.LOAD, scope: _scopeType, value: node.expr.value, line: node.line, lineString: node.lineString});
					array_push(ir, {op: ByteOp.DUP, line: node.line, lineString: node.lineString});
					var opCode = (node.operator == "++" ? OpCode.INC : OpCode.DEC);
					array_push(ir, {op: ByteOp.OPERATOR, operator: opCode, line: node.line, lineString: node.lineString});
					
					array_push(ir, {op: ByteOp.STORE, scope: _scopeType, value: node.expr.value, line: node.line, lineString: node.lineString});
				break;}
				
				case __GMLC_NodeType.ConditionalExpression:{
					// Evaluate the condition
					ir = array_concat(ir, node.condition);
					
					// Conditional jump to the false expression
					var falseExprJumpIndex = array_length(ir);
					array_push(ir, {op: ByteOp.JUMP_IF_FALSE, offset: undefined});  // offset patched la, line: node.line, lineString: node.lineStringter
					
					// Generate IR for the true expression
					ir = array_concat(ir, node.trueExpr);
					
					// Unconditional jump to skip the false expression
					var endExprJumpIndex = array_length(ir);
					array_push(ir, {op: ByteOp.JUMP, offset: undefined});  // offset patched la, line: node.line, lineString: node.lineStringter
					
					// Set the jump offset for the false expression
					var falseExprStartIndex = array_length(ir);
					ir[falseExprJumpIndex].offset = falseExprStartIndex - falseExprJumpIndex;
					
					// Generate IR for the false expression
					ir = array_concat(ir, node.falseExpr);
					
					// Patch the unconditional jump to go past the false expression
					var endExprIndex = array_length(ir);
					ir[endExprJumpIndex].offset = endExprIndex - endExprJumpIndex;
					
					// The result of the true or false expression is now on top of the stack
				break;}
				
				case __GMLC_NodeType.ArrayPattern:{
					
					//push the function
					array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.CONST, value: __NewGMLArray, name: "__NewGMLArray", line: node.line, lineString: node.lineString})
					
					//push the arguments
					var _arg_ir;
					switch (array_length(node.elements)) {
						case 0:  _arg_ir = undefined                                        break;
						case 1:  _arg_ir = node.elements[0];                                break;
						default: _arg_ir = script_execute_ext(array_concat, node.elements); break;
					}
					if (_arg_ir != undefined) ir = array_concat(ir, _arg_ir);
					
					//push the call op
					array_push(ir, {op: ByteOp.CALL, count: node.length, line: node.line, lineString: node.lineString, foo: "bar"});
					
				break;}
				case __GMLC_NodeType.StructPattern:{
					//push the function
					array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.CONST, value: __NewGMLStruct, name: "__NewGMLStruct", line: node.line, lineString: node.lineString})
					
					//push the arguments
					ir = array_concat(ir, node.arguments)
					
					//push the call op
					array_push(ir, {op: ByteOp.CALL, count: node.length, line: node.line, lineString: node.lineString, foo: "bar"});
					
				break;}
				case __GMLC_NodeType.Literal:{
					array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.CONST, value: node.value, line: node.line, lineString: node.lineString});
			    break;}
				case __GMLC_NodeType.Identifier:{
					var _scope = __determineScopeType(node);
					array_push(ir, {op: ByteOp.LOAD, scope: _scope, value: node.value, line: node.line, lineString: node.lineString});
					//nothing to see here
				break;}
				
				case __GMLC_NodeType.UniqueIdentifier:{
					array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.UNIQUE, value: node.value, line: node.line, lineString: node.lineString});
					//nothing to see here
				break;}
				
				case __GMLC_NodeType.AccessorExpression:{
					
					// load the getter function
					switch (node.accessorType) {
						case __GMLC_AccessorType.Array:  array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.CONST, value: array_get,               name: "array_get"              , line: node.line, lineString: node.lineString}) break;
						case __GMLC_AccessorType.Grid:   array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.CONST, value: ds_grid_get,             name: "ds_grid_get"            , line: node.line, lineString: node.lineString}) break;
						case __GMLC_AccessorType.List:   array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.CONST, value: ds_list_find_value,      name: "ds_list_find_value"     , line: node.line, lineString: node.lineString}) break;
						case __GMLC_AccessorType.Map:    array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.CONST, value: ds_map_find_value,       name: "ds_map_find_value"      , line: node.line, lineString: node.lineString}) break;
						case __GMLC_AccessorType.Struct: array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.CONST, value: struct_get,              name: "struct_get"             , line: node.line, lineString: node.lineString}) break;
						case __GMLC_AccessorType.Dot:    array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.CONST, value: __struct_get_with_error, name: "__struct_get_with_error", line: node.line, lineString: node.lineString}) break;
						default: throw $"\nUnsupported accessor type: {node.accessorType}\n{node}";
					}
					
					// push the array expression and index argument
					ir = array_concat(ir, node.expr, node.val1)
					
					//if grid push the second argument
					var _count = 2;
					if (node.accessorType == __GMLC_AccessorType.Grid) {
						ir = array_concat(ir, node.val2)
						_count = 3;
					}
					
					
					array_push(ir, {op: ByteOp.CALL, count: _count, line: node.line, lineString: node.lineString});
					
				break;}
				
				case __GMLC_NodeType.Function:{
					if (node.value != undefined) {
						array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.CONST, value: node.value, name: script_get_name(node.value), line: node.line, lineString: node.lineString});
					}
					else {
						array_push(ir, {op: ByteOp.LOAD, scope: ScopeType.GLOBAL, value: node.name, line: node.line, lineString: node.lineString});
					}
				break;}
				/*
				case __GMLC_NodeType.PropertyAccessor:{
					throw $"\n{currentNode.type} :: Not implimented yet"
				break;}
				case __GMLC_NodeType.AccessorExpression:{
					throw $"\n{currentNode.type} :: Not implimented yet"
				break;}
				case __GMLC_NodeType.ConstructorFunction:{
					throw $"\n{currentNode.type} :: Not implimented yet"
				break;}
				case __GMLC_NodeType.MethodVariableConstructor:{
					throw $"\n{currentNode.type} :: Not implimented yet"
				break;}
				case __GMLC_NodeType.MethodVariableFunction:{
					throw $"\n{currentNode.type} :: Not implimented yet"
				break;}
				//*/
				default: throw $"\nCurrent Node does not have a valid type for the optimizer,\ntype: {node.type}\ncurrentNode: {node}"
				
				// Add cases for other types of nodes
			}
			
			return ir;
		}
		
		#region Helper Functions
		static __handleBreaks = function(ir, offset=0) {
			//breaks will automatically calculate to the end of their IR array, the offset will add to that jump position
			var _length = array_length(ir);
			var _i=0; repeat(_length) {
				var node = ir[_i]
				if (struct_exists(node, "type"))
				&& (node.type == __GMLC_NodeType.BreakStatement) {
					ir[_i] = {op: ByteOp.JUMP, offset: _length-_i+offset, line: node.line, lineString: node.lineString}
				}
			_i+=1;}//end repeat loop
		}
		static __handleContinues = function(ir, offset=0) {
			//breaks will automatically calculate to the end of their IR array, the offset will add to that jump position
			var _length = array_length(ir);
			var _i=0; repeat(_length) {
				var node = ir[_i]
				if (struct_exists(node, "type"))
				&& (node.type == __GMLC_NodeType.ContinueStatement) {
					ir[_i] = {op: ByteOp.JUMP, offset: _length-_i+offset, line: node.line, lineString: node.lineString}
				}
			_i+=1;}//end repeat loop
		}
		#endregion
	}
	
#endregion

#region GML Emulated functions
function __struct_get_with_error(struct, name) {
	if (struct_exists(struct, name)) return struct_get(struct, name);
	
	throw $"\nVariable <unknown_object>.{name} not set before reading it."
	//throw $"\nVariable <unknown_object>.{name} not set before reading it.\n at gmlc_{objectType}_{objectName}_{eventType}_{eventNumber} (line {lineNumber}) - {lineString}"
}

function __script_execute_ext(ind, array) {
	//execute GMLC Script
	if (is_instanceof(ind, __GMLC_Script))   return ind.execute(array);
	
	//execute GMLC Function
	if (is_instanceof(ind, __GMLC_Function)) return ind.execute(array);
	
	//execute GML Script/Function
	return script_execute_ext(ind, array)
}

function __NewGMLArray() {
	var _arr = [];
	var _i=0; repeat(argument_count) {
		_arr[_i] = argument[_i];
	_i+=1;}//end repeat loop
	return _arr;
}

function __NewGMLStruct() {
	var _struct = {};
	var _i=0; repeat(argument_count/2) {
		_struct[$ argument[_i]] = argument[_i+1];
	_i+=2;}//end repeat loop
	
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
	if (!struct_exists(struct, name)) throw $"\nVariable <unknown_object>.{name} not set before reading it."
	
	if (increment)  && (prefix)  return ++struct[$ name];
	if (increment)  && (!prefix) return   struct[$ name]++;
	if (!increment) && (prefix)  return --struct[$ name];
	if (!increment) && (!prefix) return   struct[$ name]--;
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
	|| (char == ord(":"));
}

/// @ignore
function __char_is_whitespace(char) {
    gml_pragma("forceinline");
    return char >= 0x09 && char <= 0x0D || char == 0x20 || char == 0x85;
}

/// @ignore
function __determineScopeType(_node) {
	gml_pragma("forceinline");
	
	if (_node[$ "scope"] != undefined) {
		return _node[$ "scope"];
	}
	
	return __find_ScopeType_from_string(_node.value);
	
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
	//ScopeType.INSTANCE;
	//ScopeType.CONST;
	
	if array_contains(currentScript.MacroVarNames, _string) return ScopeType.MACRO;
	if array_contains(currentScript.GlobalVarNames, _string) return ScopeType.GLOBAL;
	if struct_exists(currentScript.EnumVarNames, _string) return ScopeType.ENUM;
	
	if (currentFunction != undefined) {
		if array_contains(currentFunction.LocalVarNames,  _string) return ScopeType.LOCAL;
		if array_contains(currentFunction.StaticVarNames, _string) return ScopeType.STATIC;
	}
	else {
		if array_contains(currentScript.LocalVarNames, _string) return ScopeType.LOCAL;
	}
	
	return ScopeType.INSTANCE;  // Default to instance if scope is unknown
	
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
