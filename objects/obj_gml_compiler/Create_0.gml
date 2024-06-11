/// Feather ignore all

function Environment() constructor {
	__ = {
		tokenizer : undefined, //Constructor used to tokenize the string, the returned information from a tokenizer will be able to be used in the renderer to expand/collapes code blocks in a text editor, but additionally it will be formatted in a way so that the compiler can build programs from the output.
		renderer  : undefined, //The renderer used to draw they formatting and syntax highlight to the screen.
		compiler  : undefined, //The compiler which will contruct runnable code from the output of the tokenizer.
		token_array : undefined,
	}
	static set_tokenizer = function(_tokenizer) {
		__.tokenizer = _tokenizer;
		return self;
	}
	static get_tokenizer = function() {
		return __.tokenizer;
	}
	
	static set_renderer = function(_renderer) {
		__.renderer = _renderer;
		return self;
	}
	static get_renderer = function() {
		return __.renderer;
	}
	
	static set_compiler = function(_compiler) {
		__.compiler = _compiler;
		return self;
	}
	static get_compiler = function() {
		return __.compiler;
	}
	
	static parse = function(_string) {
		validate_component(__.tokenizer);
		__.token_array = __.tokenizer.parse(_string);
		renderer.parse(__.token_array);
	}
	static draw = function() {
		__.renderer.draw();
	}
	static compile = function() {
		__.compiler.compile(__.token_array);
	}
	static run = function() {
		__.compiler.run();
	}
	
	static validate_component = function(_component) {
		if (_component == undefined) {
			throw "Component not set";
		}
	}

}

function Tokenizer() constructor {
	
	#region Methods
		
		static add_token_to_lookup = function(_name, _data) {
			if (struct_exists(__token_lookup_table, _name)) {
				var _existing_type_arr = __token_lookup_table[$ _name].type_arr
				if (!array_contains(_existing_type_arr, _data.type_arr)) {
					
					var _i=0; repeat(array_length(_data.type_arr)) {
						
						array_push(_existing_type_arr, _data.type_arr[_i]);
						
						var _existing_data = __token_lookup_table[$ _name].data;
						if (_existing_data != undefined) {
							//struct_merge
							struct_foreach(_data.data, method(_existing_data, function(_name, _value) {
								if (self[$ _name] == undefined) {
									self[$ _name] = _value;
								}
							}));
						}
						else {
							__token_lookup_table[$ _name].data = _data.data;
						}
					_i+=1;}//end repeat loop
					
				}
			}
			else {
				__token_lookup_table[$ _name] = _data;
			}
		}
		
	#endregion
	#region Constructors
		
		static lookup_token_struct = function(_name, _type, _data={data:{}}, _deprecated=false) constructor {
			name       = _name;
			type_arr   = [_type];
			data       = _data;
			deprecated = _deprecated;
			length     = string_length(_name);
		}
		
	#endregion	
	
	static Token = function(_type, _str, _data, _pos, _length) constructor {
			type     = _type;
			str      = _str;
			value    = _value;
			position = _pos;
			length   = _length;
	}
	__token_lookup_table = {}
	
	// Main parse method
	static parse = function(_string) {
		var _token_arr = [];
		var _pos = 1;
		while (_pos <= string_length(_string)) {
			_pos = tokenize_whitespace(_string, _pos);
			_pos = tokenize_operator(_string, _pos, _token_arr);
			_pos = tokenize_number(_string, _pos, _token_arr);
			_pos = tokenize_identifier(_string, _pos, _token_arr);
			// Add more tokenization logic as needed
		}
		return _token_arr;
	}
	
	static parse_async = function(_string) {
		/* parse the string, except run it through coroutines to make sure we only run so many opperations a second, picking up where we had left off on the last frame until the full string has been properly tokenized */
	}
	
}
function Renderer() constructor {
	themes = {}; // Object to hold different themes
	
	static set_theme = function(_themeName) {
		// Logic to set the current theme
	}
	static add_theme = function(_themeName, _themeDetails) {
		themes[_themeName] = _themeDetails;
	}
	
	static parse = function(_token_arr) {
		/* parse the token array into a draw-able set of instructions */
	}
	static parse_async = function(_token_arr) {
		/* parse the token array into a draw-able set of instructions across multiple frames using coroutines */
	}
	static draw = function() {
		/* draw the cached tokenized data */
	}
	static draw_culled = function(_line, _width) {
		/* draw the cached tokenized data with culling to skip over the first or last lines when focused in the center of the string */
	}
	
}
function Compiler() constructor {
	lastCompiledProgram = undefined;

	static compile = function(_token_arr) {
		var _program = {};
		// Compilation logic
		lastCompiledProgram = _program;
		return _program;
	}
	static compile_async = function(_token_arr) {
		/* compile the tokens into an exacutable program across multiple frames using coroutines */
	}
	static run = function() {
		if (lastCompiledProgram == undefined) {
			throw "No compiled program available";
		}
		// Logic to execute the last compiled program
	}
}



function GML_Environment() : Environment() constructor {
	set_tokenizer();
	set_renderer();
	set_compiler();
}

function GML_Tokenizer() : Tokenizer() constructor {
	
	#region Variables
		
		static __GmlSpec = GmlSpec();
		
		static TokenType = {
			Function               : "Function",
			Variable               : "Variable",
			Constant               : "Constant",
			StructureMember        : "StructureMember",
			Enumeration            : "Enumeration",
			EnumerationMember	     : "EnumerationMember",
			Operator               : "Operator",
			Whitespace             : "Whitespace",
			CommentLine            : "CommentLine",
			CommentBlock           : "CommentBlock",
			Keyword                : "Keyword",
			CurlyBracket           : "CurlyBracket",
			StringLitteral         : "StringLitteral",
			StringLitteralBlock    : "StringLitteralBlock",
			StringExpression       : "StringExpression",
			Number                 : "Number",
			Identifier             : "Identifier",
			Illegal                : "Illegal",
			StringLiteral          : "StringLiteral",
			StringLegacy           : "StringLegacy",
			StringExpressionBegin  : "StringExpressionBegin",
			StringExpressionMiddle : "StringExpressionMiddle",
			StringExpressionEnd    : "StringExpressionEnd",
		}
		
	#endregion
	
	#region Methods
		
		function convert_escaped_string(_escaped_string) {
			var _result = "";
			var _pos = 1;
			var _str_length = string_length(_escaped_string);
			
			repeat (_str_length - _pos + 1) {
				var _char = string_char_at(_escaped_string, _pos);
				if (_char == string_char_at("\\", 1) && _pos < _str_length) {
					// Handle escape sequences
					_pos += 1; // Move to the escaped character
					var _next_char = string_char_at(_escaped_string, _pos);
					switch (_next_char) {
						case "t" : _result += "\t"; break;
						case "b" : _result += "\b"; break;
						case "n" : _result += "\n"; break;
						case "r" : _result += "\r"; break;
						case "f" : _result += "\f"; break;
						case "s" : _result += "\s"; break;
						case "'" : _result += "\'"; break;
						case "\"": _result += "\""; break;
						case "\\": _result += "\\"; break;
						// Add more escape sequences as needed
						default: _result += _next_char; // Unrecognized escape sequence, treat as literal character
					}
				} else {
					_result += string_char_at(_escaped_string, _pos);
				}
				_pos += 1;
			}
			
			return _result;
		}
		
	#endregion
	
	#region Private
		
		static __GmlSpec_to_lookup = function(_gml_spec) {
			static is_deprecated = function(_data) {
				//deprication check
				var _dep = false;
				if (struct_exists(_data, "Deprecated")) {
					if (is_string(_data.Deprecated)) {
						if (_data.Deprecated == "true") {
							_dep = true;
						}
					}
					else if (is_numeric(_data.Deprecated) || is_bool(_data.Deprecated)) {
						_dep = _data.Deprecated;
					}
				}
				
				return _dep;
			}
			
			var _lookup_table = {};
			
			var _specs = _gml_spec.GameMakerLanguageSpec;
			
			var _function_arr = _specs.Functions.Function;
			var _i=0; repeat(array_length(_function_arr)) {
				var _val = _function_arr[_i];
				add_token_to_lookup(_val.Name, new lookup_token_struct(_val.Name, TokenType.Function, {feather: _val}, is_deprecated(_val)));
			_i+=1;}//end repeat loop
		
			var _variable_arr = _specs.Variables.Variable;
			var _i=0; repeat(array_length(_variable_arr)) {
				var _val = _variable_arr[_i];
				add_token_to_lookup(_val.Name, new lookup_token_struct(_val.Name, TokenType.Variable, {feather: _val}, is_deprecated(_val)));
			_i+=1;}//end repeat loop
		
			var _constant_arr = _specs.Constants.Constant;
			var _i=0; repeat(array_length(_constant_arr)) {
				var _val = _constant_arr[_i];
				add_token_to_lookup(_val.Name, new lookup_token_struct(_val.Name, TokenType.Constant, {feather: _val}, is_deprecated(_val)));
			_i+=1;}//end repeat loop
		
			var _structure_arr = _specs.Structures.Structure;
			var _i=0; repeat(array_length(_structure_arr)) {
				var _outter = _structure_arr[_i];
				var _inner_arr = _outter.Field;
			
				var _j=0; repeat(array_length(_inner_arr)) {
				
					var _val = _inner_arr[_j];
					add_token_to_lookup(_val.Name, new lookup_token_struct(_val.Name, TokenType.StructureMember, {feather: _val}, is_deprecated(_val)));
				
				_j+=1;}//end repeat loop
			
			_i+=1;}//end repeat loop
		
			var _enumeration_arr = _specs.Enumerations.Enumeration;
			var _i=0; repeat(array_length(_enumeration_arr)) {
				var _val = _enumeration_arr[_i];
				add_token_to_lookup(_val.Name, new lookup_token_struct(_val.Name, TokenType.Enumeration, {feather: _val}, is_deprecated(_val)));
			
				var _j=0; repeat(array_length(_val.Member)) {
					var _sub_val = _val.Member[_j];
					
					add_token_to_lookup(_sub_val.Name, new lookup_token_struct(_sub_val.Name, TokenType.EnumerationMember, {feather: _sub_val}, is_deprecated(_sub_val)));
				
				_j+=1;}//end repeat loop
			
			_i+=1;}//end repeat loop
		
		
			return _lookup_table;
		}
		static __build_lookup_table = function() {
			var _token_lookup_table = __GmlSpec_to_lookup(__GmlSpec);
			
			var _i=0; repeat(array_length(__operator_arr)) {
				var _op = __operator_arr[_i];
				add_token_to_lookup(_op, new lookup_token_struct(_op, TokenType.Operator));
			_i+=1;}//end repeat loop
			
			var _i=0; repeat(array_length(__keywords_arr)) {
				var _keyword = __keywords_arr[_i];
				add_token_to_lookup(_keyword, new lookup_token_struct(_keyword, TokenType.Keyword));
			_i+=1;}//end repeat loop
			
			
			return __token_lookup_table;
			
			#region Deprocated
			/*
			#region Operators
			
			var _i=0; repeat(array_length(__operator_arr)) {
				var _key = __operator_arr[_i];
				var _data = new lookup_token_struct(_key, TokenType.Operator);
				add_token_to_lookup(_key, _data);
			_i+=1;}//end repeat loop
			
			#endregion
			
			#region Whitespaces
			
			var _i=0; repeat(array_length(__whitespace_arr)) {
				var _key = __whitespace_arr[_i];
				var _data = new lookup_token_struct(_key, TokenType.Whitespace);
				add_token_to_lookup(_key, _data);
			_i+=1;}//end repeat loop
			
			#endregion
			
			#region Comments
			
			// CommentLine
			static __comment_line = "//";
			var _key = __comment_line;
			var _data = new lookup_token_struct(_key, TokenType.CommentLine);
			add_token_to_lookup(_key, _data);
			
			// CommentBlock
			static __comment_block_arr = ["/"+"*", "*"+"/"];
			var _i=0; repeat(array_length(__comment_block_arr)) {
				var _key = __comment_block_arr[_i];
				var _data = new lookup_token_struct(_key, TokenType.CommentBlock);
				add_token_to_lookup(_key, _data);
			_i+=1;}//end repeat loop
			
			#endregion
			
			#region Keywords
			
			var _i=0; repeat(array_length(__keywords_arr)) {
				var _key = __keywords_arr[_i];
				var _data = new lookup_token_struct(_key, TokenType.Keyword);
				add_token_to_lookup(_key, _data);
			_i+=1;}//end repeat loop
			
			#endregion
			
			#region Curly Brackets
			static __brackets_arr = ["{", "}"];
			
			var _i=0; repeat(array_length(__brackets_arr)) {
				var _key = __brackets_arr[_i];
				var _data = new lookup_token_struct(_key, TokenType.CurlyBracket);
				add_token_to_lookup(_key, _data);
			_i+=1;}//end repeat loop
			
			#endregion
			
			#region Strings
			// StringLitteral
			static __string_arr = ["\""];
			
			var _i=0; repeat(array_length(__comment_block_arr)) {
				var _key = __comment_block_arr[_i];
				var _data = new lookup_token_struct(_key, TokenType.StringLitteral);
				add_token_to_lookup(_key, _data);
			_i+=1;}//end repeat loop
			
			#endregion
			*/
			#endregion
		}
		
		#region Variables
		//used in several functions
		
		__open_brackets = [];
		__open_bracket_reasons = {
			StringExpression : "StringExpression",
			Expression       : "Expression",
		}
		
		static __whitespace_arr = [" ", "\t", "\r", "\n"];
		
		#region __operator_arr
		static __operator_arr = [
			/* Assigning */ "=",
			/* Combining */ "&&", "||", "^^",
			/* Nullish */ "??", "??=",
			/* Comparing */ "<", "<=", "==", "!=", ">", ">=",
			/* Bitwise */ "|", "&", "^", "<<", ">>",
			/* Arithmetical */ "+", "-", "*", "/",
			/* Increment/Decrement */ "++", "--",
			/* Division and Modulo */ /*"div", "mod",*/ "%",
			/* Unary */ "!", "-", "~",
			/* syntax */ ",", ";", ".", ":", "(", ")", "[", "]",
			/* accessors */ "@", "#", "|", "?", "$"
		];
		//organize them from longest string to shortest
		array_sort(__operator_arr, function(_elem1, _elem2){
			return string_length(_elem2) - string_length(_elem1);
		})
		#endregion
		
		#region __keywords_arr
		static __keywords_arr = [
			"globalvar", "var", "if", "then", "else",
			"begin", "end", "for", "while", "do",
			"until", "repeat", "switch", "case", "default",
			"break", "continue", "with", "exit", "return",
			"self", "other", "noone", "all", "global",
			"local", "mod", "div", "not", "and",
			"or", "xor", "enum", "function", "new",
			"constructor", "static", "region", "endregion", "macro",
			"try", "catch", "finally"
		];
		//organize them from longest string to shortest
		array_sort(__keywords_arr, function(_elem1, _elem2){
			return string_length(_elem2) - string_length(_elem1);
		})
		#endregion
		
		__token_lookup_table = __build_lookup_table();
		
		#endregion
		
		static parse = function(_str) {
			var _token_arr = tokenize_string(_str);
			var _ast = abstract_syntax_tree_from_tokens(_token_arr);
			return _ast;
		}
		
		static tokenize_string = function(_str) {
			var _token_arr = [];
			var _str_length = string_length(_str);
			var _pos = 1;
			
			while (_pos <= _str_length) {
				var old_pos = _pos;
				_pos = tokenize_whitespace(_str, _pos, _token_arr, _str_length);
				_pos = tokenize_number(_str, _pos, _token_arr, _str_length);
				_pos = tokenize_identifier(_str, _pos, _token_arr, _str_length);
				_pos = tokenize_string_legacy(_str, _pos, _token_arr, _str_length);
				_pos = tokenize_string_expression(_str, _pos, _token_arr, _str_length);
				_pos = tokenize_string_literal(_str, _pos, _token_arr, _str_length);
				_pos = tokenize_comment_line(_str, _pos, _token_arr, _str_length);
				_pos = tokenize_comment_block(_str, _pos, _token_arr, _str_length);
				_pos = tokenize_region(_str, _pos, _token_arr, _str_length);
				_pos = tokenize_macro(_str, _pos, _token_arr, _str_length);
				
				// If position has not advanced, tokenize as illegal
				if (_pos == old_pos) {
					_pos = tokenize_operator(_str, _pos, _token_arr, _str_length);
				}
				if (_pos == old_pos) {
					_pos = tokenize_illegal(_str, _pos, _token_arr, _str_length);
				}
			}
			
			return _token_arr;
		};
		#region First Pass :: Tokenizer methods
		
		// Tokenization functions for different token types
		static tokenize_whitespace = function(_string, _pos, _token_arr, _str_length=string_length(_string)) {
			repeat(_str_length - _pos + 1) {
				var char = string_char_at(_string, _pos);
				if (array_contains(__whitespace_arr, char)) {
					var token = new Token(TokenType.Whitespace, char, char, _pos, 1);
					array_push(_token_arr, token);
					_pos += 1;
				} else {
					break;
				}
			}//end repeat loop
			
			return _pos;
		};
		
		static tokenize_operator = function(_string, _pos, _token_arr, _str_length=string_length(_string)) {
			repeat(_str_length - _pos + 1) {
				var _i=0; repeat(array_length(__operator_arr)) {
					var _op = __operator_arr[_i];
					var _op_length = string_length(_op);
					
					if (string_copy(_string, _pos, _op_length) == _op) {
						var token = new Token(TokenType.Operator, _op, _op, _pos, _op_length);
						array_push(_token_arr, token);
						_pos += _op_length;
					}
				_i+=1;}//end repeat loop
			}//end repeat loop
			
			return _pos;
		};
		
		static tokenize_number = function(_string, _pos, _token_arr, _str_length=string_length(_string)) {
			static __zero_byte = string_byte_at("0", 1);
			static __nine_byte = string_byte_at("9", 1);
			static __period_byte = string_byte_at(".", 1);
			static __underscore_byte = string_byte_at("_", 1);
			
			var _start = _pos;
			var _last_was_digit = false;  // Flag to indicate if the last character was a digit
			var _encountered_period = false;  // Flag to track if a period has been encountered
			
			repeat(_str_length - _pos + 1) {
				
				var _char = string_char_at(_string, _pos);
				var _char_byte_length = string_byte_length(_char);
				var _char_byte = string_byte_at(_char, 1);
				
				if (_char_byte_length != 1)	{
					break;
				}
				
				if (_char_byte >= __zero_byte && _char_byte <= __nine_byte) {
					_last_was_digit = true;
					_pos += 1;
				} else if (_char_byte == __underscore_byte && _last_was_digit && _pos < _str_length - 1) {
					// Allow underscore only if it's not at the start, end, and not after another underscore
					_last_was_digit = false;
					_pos += 1;
				} else if (_char_byte == __period_byte && !_encountered_period && _last_was_digit) {
					// Allow a single period if it's not the first character and not after an underscore
					_encountered_period = true;
					_last_was_digit = false;
					_pos += 1;
				} else {
					break;
				}
			}//end repeat loop
			
			if (_pos > _start && _last_was_digit) {
				// Remove underscores from the number string for parsing
				var _number_str = string_copy(_string, _start, _pos - _start)
				var _number = real(string_replace_all(_number_str, "_", ""));
				var token = new Token(TokenType.Number, _number_str, _number, _start, _pos - _start);
				array_push(_token_arr, token);
			}
			
			return _pos;
		};
		
		static tokenize_identifier = function(_string, _pos, _token_arr, _str_length=string_length(_string)) {
			static __a_byte = string_byte_at("a", 1);
			static __z_byte = string_byte_at("z", 1);
			static __A_byte = string_byte_at("A", 1);
			static __Z_byte = string_byte_at("Z", 1);
			static __underscore_byte = string_byte_at("_", 1);
			static __zero_byte = string_byte_at("0", 1);
			static __nine_byte = string_byte_at("9", 1);
			
			var _start = _pos;
			
			repeat(_str_length - _pos + 1) {
				var _char = string_char_at(_string, _pos);
				var _char_byte_length = string_byte_length(_char);
				var _char_byte = string_byte_at(_char, 1);
				
				if (_char_byte_length != 1)	{
					break;
				}
				
				if (_char_byte >= __a_byte && _char_byte <= __z_byte)
				|| (_char_byte >= __A_byte && _char_byte <= __Z_byte)
				|| (_char_byte == __underscore_byte)
				|| (_pos > _start && _char_byte >= __zero_byte && _char_byte <= __nine_byte) {
					_pos += 1;
				} else {
					break;
				}
			}//end repeat loop
			
			if (_pos > _start) {
				var _identifier_str = string_copy(_string, _start, _pos - _start);
				if (struct_exists(__token_lookup_table, _identifier_str)) {
					var _token = new Token(__token_lookup_table[$ _identifier_str].type_arr[0], _identifier_str, _identifier_str, _start, _pos - _start);
					array_push(_token_arr, _token);
				}
				else {
					var _token = new Token(TokenType.Identifier, _identifier_str, _identifier_str, _start, _pos - _start);
					array_push(_token_arr, _token);
				}
			}
			
			return _pos;
		};
		
		static tokenize_illegal = function(_string, _pos, _token_arr, _str_length=string_length(_string)) {
			var char = string_char_at(_string, _pos);
			var token = new Token(TokenType.Illegal, char, char, _pos, 1);
			array_push(_token_arr, token);
			return _pos + 1;
		};
		
		static tokenize_string_literal = function(_string, _pos, _token_arr, _str_length=string_length(_string)) {
			static __quote_byte = string_byte_at("\"", 1);
			static __backlsash_byte = string_byte_at("\\", 1);
			static __newline_byte = string_byte_at("\"", 1);
			
			if (string_char_at(_string, _pos) == "\"") {
				var start = _pos;
				_pos += 1;
				
				var _found_closing_quote = false;
				while (_pos <= _str_length) {
					var _char = string_char_at(_string, _pos);
					var _char_byte_length = string_byte_length(_char);
					var _char_byte = string_byte_at(_char, 1);
					
					if (_char_byte == __quote_byte) {
						_found_closing_quote = true;
						_pos += 1;
						break; // Closing quote found
					} else if (_char_byte == __backlsash_byte && _pos < _str_length) {
						_pos += 2; // Skip escape character and the next character
					} else if (_char_byte == __newline_byte) {
						break; // End the string literal if a line break is encountered
					} else {
						_pos += 1;
					}
				}
				
				var _str_content = string_copy(_string, start, _pos - start + 1);
				
				var _str_value = _str_content;
				if (string_starts_with(_str_value, "\"")) _str_value = string_delete(_str_value, 1, 1);
				if (string_ends_with(_str_value, "\"")) _str_value = string_delete(_str_value, string_length(_str_value), 1);
				_str_value = convert_escaped_string(_str_value);
				
				var token = new Token(TokenType.StringLiteral, _str_content, _str_value, start, _pos - start + 1);
				array_push(_token_arr, token);
				
				if (_found_closing_quote) {
					_pos += 1; // Skip closing quote
				}
			}
			return _pos;
		};
		
		static tokenize_string_legacy = function(_string, _pos, _token_arr, _str_length=string_length(_string)) {
			var _start_char = string_char_at(_string, _pos);
			var _start = _pos;
			var _closing_char = undefined;
			
			if (_start_char == "@") {
				if (_pos <= _str_length - 1 && (string_char_at(_string, _pos + 1) == "\"" || string_char_at(_string, _pos + 1) == "'")) {
					_closing_char = string_char_at(_string, _pos + 1);
					_pos += 2; // Skip opening @" or @'
				}
			}
			else if (_start_char == "\"" || _start_char == "'") {
				// Check if the previous token was an @ operator
				var _token_arr_length = array_length(_token_arr)
				if (_token_arr_length > 0 && _token_arr[_token_arr_length - 1].type == TokenType.Operator && _token_arr[_token_arr_length - 1].data == "@") {
					// Remove the last token (@ operator)
					array_pop(_token_arr)
					_start -= 1; // Adjust the starting position
					_closing_char = _start_char;
					_pos += 1; // Skip opening " or '
				}
			}
			
			if (_closing_char != undefined) {
				// Parse the string content
				while (_pos <= _str_length) {
					if (string_char_at(_string, _pos) == _closing_char) {
						_pos += 1;
						break;
					}
					_pos += 1;
				}
				
				var strContent = string_copy(_string, _start, _pos - _start);
				log(["strContent", strContent])
				var _str_value = string_copy(_string, 3, string_length(_string)-3)
				log(["_str_value", _str_value])
				var token = new Token(TokenType.StringLegacy, strContent, _start, _pos - _start);
				array_push(_token_arr, token);
		
				if (_pos < _str_length) {
					_pos += 1; // Skip closing quote if it's found
				}
			}
			return _pos;
		};
		
		static tokenize_string_expression = function(_string, _pos, _token_arr, _str_length=string_length(_string)) {
			static __dollar_byte = string_byte_at("$", 1);
			static __brace_open_byte = string_byte_at("{", 1);
			static __brace_close_byte = string_byte_at("}", 1);
			static __quote_byte = string_byte_at("\"", 1);
			static __newline_byte = string_byte_at("\n", 1);
			static __backlsash_byte = string_byte_at("\\", 1);
			
			//a constant used in this function
			static __expression_depth = 0; // Depth of nested string expressions
			
			var _start_char = undefined;
			var _start = _pos;
			
			var _char = string_char_at(_string, _pos);
			var _char_byte_length = string_byte_length(_char);
			var _char_byte = string_byte_at(_char, 1);
			
			var _start_byte = string_byte_at(_string, _pos);
			
			#region StringExpressionBegin
				
				if (_char_byte == __dollar_byte) {
					if (_pos <= _str_length - 1)
					&& (string_char_at(_string, _pos + 1) == "\"") {
						_start_char = string_char_at(_string, _pos);
						_pos += 2; // Skip opening $"
					}
				}
				else if (_char_byte == __quote_byte) {
					// Check if the previous token was an $ operator
					var _token_arr_length = array_length(_token_arr)
					if (_token_arr_length > 0 && _token_arr[_token_arr_length - 1].type == TokenType.Operator && _token_arr[_token_arr_length - 1].data == "$") {
						// Remove the last token ($ operator)
						array_pop(_token_arr)
						_start -= 1; // Adjust the starting position
						_start_char = string_char_at(_string, _pos);
						_pos += 1; // Skip opening "
					}
				}
				
				// Check for the start of a string expression ($")
				if (_start_char != undefined) {
					
					// Process until the string expression is closed or input ends
					var _found_closing_symbol = false;
					var _token_type = TokenType.StringExpressionBegin;
					while (_pos <= _str_length) {
						
						var _char = string_char_at(_string, _pos);
						var _char_byte_length = string_byte_length(_char);
						var _char_byte = string_byte_at(_char, 1);
						
						if (_char_byte == __brace_open_byte) {
							_found_closing_symbol = true;
							__expression_depth += 1;
							_pos += 1;
							break; // Closing quote found
						} else if (_char_byte == __quote_byte) {
							_found_closing_symbol = true;
							_token_type = TokenType.StringLitteral;
							_pos += 1;
							break; // Closing quote found
						} else if (_char_byte == __backlsash_byte && _pos < _str_length) {
							_pos += 2; // Skip escape character and the next character
						} else if (_char_byte == __newline_byte) {
							break; // End the string literal if a line break is encountered
						} else {
							_pos += 1;
						}
					}
					
					// Add the token
					var strExprContent = string_copy(_string, _start, _pos - _start);
					var token = new Token(_token_type, strExprContent, _start, _pos - _start);
					array_push(_token_arr, token);
					
					// Add the open bracket reason
					if (_token_type == TokenType.StringExpressionBegin) {
						array_push(__open_brackets, __open_bracket_reasons.StringExpression);
					}
					
				}
				
			#endregion
			
			#region StringExpressionMiddle/End
				
				if (array_length(__open_brackets) && __open_brackets[array_length(__open_brackets) - 1] == __open_bracket_reasons.StringExpression)
				&& (_char_byte == __brace_close_byte) {
					//update the curly bracket array.
					array_pop(__open_brackets);
					__expression_depth -= 1;
					
					_start_char = string_char_at(_string, _pos);
					_pos += 1; // Skip expression closing }
					
					// Process until the string expression is closed or input ends
					var _found_closing_symbol = false;
					var _token_type = TokenType.StringExpressionMiddle;
					while (_pos <= _str_length) {
						var _char = string_char_at(_string, _pos);
						var _char_byte_length = string_byte_length(_char);
						var _char_byte = string_byte_at(_char, 1);
						if (_char_byte == __brace_open_byte) {
							_found_closing_symbol = true;
							__expression_depth += 1;
							_pos += 1;
							break; // Closing quote found
						} else if (_char_byte == __quote_byte) {
							_found_closing_symbol = true;
							_token_type = TokenType.StringExpressionEnd;
							_pos += 1;
							break; // Closing quote found
						} else if (_char_byte == __backlsash_byte && _pos < _str_length) {
							_pos += 2; // Skip escape character and the next character
						} else if (_char_byte == __newline_byte) {
							break; // End the string literal if a line break is encountered
						} else {
							_pos += 1;
						}
					}
					
					// Add the token
					var strExprContent = string_copy(_string, _start, _pos - _start);
					var token = new Token(_token_type, strExprContent, _start, _pos - _start);
					array_push(_token_arr, token);
				}
				
				
			#endregion
			
			return _pos;
		};
		
		static tokenize_comment_line = function(_string, _pos, _token_arr, _str_length=string_length(_string)) {
			static __newline_byte = string_byte_at("\n", 1);
			
			if (_pos <= _str_length - 1 && string_copy(_string, _pos, 2) == "//") {
				var _start = _pos;
				_pos += 2; // Skip the //
				
				// Continue until the end of the line or string
				repeat (_str_length - _pos + 1) {
					var _char = string_char_at(_string, _pos);
					var _char_byte_length = string_byte_length(_char);
					var _char_byte = string_byte_at(_char, 1);
					
					if (_char_byte == __newline_byte) {
						break;
					}
					
					_pos += 1;
				}
				
				var _comment = string_copy(_string, _start, _pos - _start);
				var _token = new Token(TokenType.CommentLine, _comment, _start, _pos - _start);
				array_push(_token_arr, _token);
			}
			
			return _pos;
		};
		
		static tokenize_comment_block = function(_string, _pos, _token_arr, _str_length=string_length(_string)) {
			static __forward_slash_byte = string_byte_at("/", 1);
			static __asterisk_byte = string_byte_at("*", 1);
			
			if (_pos <= _str_length - 1 && string_copy(_string, _pos, 2) == "/*") {
				var _start = _pos;
				_pos += 2; // Skip the /*
				
				// Continue until the closing */ is found or the end of the string
				repeat (_str_length - _pos /* + 1 */) { //one charactor less then the full string
					if (string_byte_at(string_char_at(_string, _pos), 1) == __asterisk_byte)
					&& (string_byte_at(string_char_at(_string, _pos + 1), 1) == __forward_slash_byte) {
						_pos += 2; // Skip the */
						break;
					}
					_pos += 1;
				}
				
				var _comment = string_copy(_string, _start, _pos - _start);
				var _token = new Token(TokenType.CommentBlock, _comment, _start, _pos - _start);
				array_push(_token_arr, _token);
			}
			
			return _pos;
		};
		
		static tokenize_region = function(_string, _pos, _token_arr, _str_length=string_length(_string)) {
			static __hash_byte = string_byte_at("#", 1);
			static __newline_byte = string_byte_at("\n", 1);
			
			//#region
			static __region_str = "#region";
			static __region_str_length = string_length(__region_str);
			if (_pos <= _str_length - __region_str_length)
			&& (string_copy(_string, _pos, __region_str_length) == __region_str) {
				var _start = _pos;
				_pos += __region_str_length; // Skip the #region
				
				// Add the #region keyword token
				var _keyword_token = new Token(TokenType.Keyword, __region_str, _start, __region_str_length);
				array_push(_token_arr, _keyword_token);
				
				// Process the rest of the line as a comment
				var _comment_start = _pos;
				repeat (_str_length - _pos + 1) {
					var _char_byte = string_byte_at(string_char_at(_string, _pos), 1);
					if (_char_byte == __newline_byte) {
						break;
					}
					_pos += 1;
				}
				
				// Add the rest of the line as a commentLine
				var _comment = string_copy(_string, _comment_start, _pos - _comment_start);
				var _comment_token = new Token(TokenType.CommentLine, _comment, _comment_start, _pos - _comment_start);
				array_push(_token_arr, _comment_token);
				
			}
			
			//#endregion
			static __endregion_str = "#endregion";
			static __endregion_str_length = string_length(__endregion_str);
			if (_pos <= _str_length - __endregion_str_length)
			&& (string_copy(_string, _pos, __endregion_str_length) == __endregion_str) {
				var _start = _pos;
				_pos += __endregion_str_length; // Skip the #region
				
				// Add the #region keyword token
				var _keyword_token = new Token(TokenType.Keyword, __endregion_str, _start, __endregion_str_length);
				array_push(_token_arr, _keyword_token);
				
			}
			
			return _pos;
		};
		
		static tokenize_macro = function(_string, _pos, _token_arr, _str_length=string_length(_string)) {
			static __hash_byte = string_byte_at("#", 1);
			static __newline_byte = string_byte_at("\n", 1);
			
			//#endregion
			static __macro_str = "#macro";
			static __macro_str_length = string_length(__macro_str);
			if (_pos <= _str_length - __macro_str_length)
			&& (string_copy(_string, _pos, __macro_str_length) == __macro_str) {
				var _start = _pos;
				_pos += __macro_str_length; // Skip the #region
				
				// Add the #region keyword token
				var _keyword_token = new Token(TokenType.Keyword, __macro_str, _start, __macro_str_length);
				array_push(_token_arr, _keyword_token);
				
			}
			
			return _pos;
		};
		
		#endregion
		
		// Function to start the second pass and build AST
		static abstract_syntax_tree_from_tokens = function(_token_arr) {
			var _ast = {}; // Initialize empty AST
			var _pos = 0;
			var _len = array_length(_token_arr);
			
			while (_pos < _len) {
				var old_pos = _pos;
				
				// Example of invoking a method based on the current token type
				switch (_token_arr[_pos].type) {
					case TokenType.Function:{
						_pos = process_function_declaration(_token_arr, _pos, _ast);
					break;}
					case TokenType.Variable:{
						// do stuff...
					break;}
					case TokenType.Constant:{
						// do stuff...
					break;}
					case TokenType.StructureMember:{
						// do stuff...
					break;}
					case TokenType.Enumeration:{
						// do stuff...
					break;}
					case TokenType.EnumerationMember:{
						// do stuff...
					break;}
					case TokenType.Operator:{
						// do stuff...
					break;}
					case TokenType.Whitespace:{
						// do stuff...
					break;}
					case TokenType.CommentLine:{
						// do stuff...
					break;}
					case TokenType.CommentBlock:{
						// do stuff...
					break;}
					case TokenType.Keyword:{
						//switch (_token_arr[_pos].type)
					break;}
					case TokenType.CurlyBracket:{
						// do stuff...
					break;}
					case TokenType.StringLitteral:{
						// do stuff...
					break;}
					case TokenType.StringLitteralBlock:{
						// do stuff...
					break;}
					case TokenType.StringExpression:{
						// do stuff...
					break;}
					case TokenType.Number:{
						// do stuff...
					break;}
					case TokenType.Identifier:{
						// do stuff...
					break;}
					case TokenType.Illegal:{
						// do stuff...
					break;}
					case TokenType.StringLiteral:{
						// do stuff...
					break;}
					case TokenType.StringLegacy:{
						// do stuff...
					break;}
					case TokenType.StringExpressionBegin:{
						// do stuff...
					break;}
					case TokenType.StringExpressionMiddle:{
						// do stuff...
					break;}
					case TokenType.StringExpressionEnd:{
						// do stuff...
					break;}
					
					
					case TokenType.If:
						_pos = process_if_statement(_token_arr, _pos, _ast);
						break;
					case TokenType.For:
						_pos = process_for_loop(_token_arr, _pos, _ast);
						break;
					case TokenType.While:
						_pos = process_while_loop(_token_arr, _pos, _ast);
						break;
					case TokenType.Var:
					case TokenType.GlobalVar:
					case TokenType.Static:
						_pos = process_variable_declaration(_token_arr, _pos, _ast);
						break;
					default:
						_pos = process_error(_token_arr, _pos, _ast);
						break;
				}
				
				// If no progress, handle as an error or specific case
				if (_pos == old_pos) {
					// Handle unexpected token or structure
					_pos = process_error(_token_arr, _pos, _ast);
				}
			}

			return _ast;
		};
		#region Second Pass :: Abstract Syntax Tree Methods
		// AST Node Structures
		function AST() {
			// General-purpose Expression Node
			static Expression = function(_content) constructor {
				type = "EXPRESSION";
				content = _content; // Could be a single node or an array of nodes representing the expression
			}
			
			// General-purpose Statement Node
			static Statement = function(_content) constructor {
				type = "STATEMENT";
				content = _content; // Could be a single node or an array of nodes representing the statement
			}
			
			#region Functions
			
			// Function declaration
			static Function = function(_parameters, _statement) constructor {
				type = "FUNCTION";
				parameters = _parameters;
				statement = _statement; // 'statement' is an AST representing the function body
			}
			
			// Function Execution
			static FunctionExec = function(_functionName, _arguments) constructor {
				type = "FUNCTION_EXEC";
				functionName = _functionName; // Name of the function being called
				arguments = _arguments; // Array of AST nodes representing the arguments passed to the function
			}
			
			#endregion
			
			#region Constructor Nodes
			
			// Constructor declaration
			static Constructor = function(_name, _parameters, _statement) constructor {
				type = "CONSTRUCTOR";
				name = _name; // Name of the constructor
				parameters = _parameters; // Parameters for the constructor
				statement = _statement; // 'statement' is an AST representing the constructor body
			}
			
			// New object instantiation
			static New = function(_constructorName, _arguments) constructor {
				type = "NEW";
				constructorName = _constructorName; // Name of the constructor being invoked
				arguments = _arguments; // Arguments passed to the constructor
			}
			
			#endregion
			
			#region Expression Nodes
			
			// If statement
			static If = function(_expression, _statement, _else_statement) constructor {
				type = "IF";
				expression = _expression; // if (<expression>)
				statement = _statement; // AST for the 'if' block
				else_statement = _else_statement; // AST for the 'else' block (if present)
			}
			
			// Switch statement
			static Switch = function(_expression, _cases, _default_case) constructor {
				type = "SWITCH";
				expression = _expression;
				cases = _cases; // Array of 'case' nodes, each with its own AST for the case body
				default_case = _default_case; // AST for the 'default' case (if present)
			}
			
			// Case for switch statement
			static Case = function(_expression, _statement) constructor {
				type = "CASE";
				expression = _expression; // The case condition (e.g., a constant value)
				statement = _statement; // AST for the case body
			}
			
			// For loop
			static For = function(_assignment, _expression, _operation, _statement) constructor {
				type = "FOR";
				assignment = _assignment; // AST for initialization part
				expression = _expression; // AST for condition part
				operation = _operation; // AST for increment part
				statement = _statement; // AST for the body of the loop
			}
			
			// While loop
			static While = function(_expression, _statement) constructor {
				type = "WHILE";
				expression = _expression; // AST for condition
				statement = _statement; // AST for the loop body
			}
			
			// Repeat loop
			static Repeat = function(_expression, _statement) constructor {
				type = "REPEAT";
				expression = _expression; // AST for condition
				statement = _statement; // AST for the loop body
			}
			
			// Then statement (commonly used in if-then-else)
			static Then = function(_statement) constructor {
				type = "THEN";
				statement = _statement; // AST for the 'then' block
			}
			
			// Do/Until loop
			static DoUntil = function(_expression, _statement) constructor {
				type = "DO_UNTIL";
				expression = _expression; // AST for the loop body
				statement = _statement; // AST for the until condition
			}
			
			// Break statement
			static Break = function() constructor {
				type = "BREAK";
			}
			
			// Continue statement
			static Continue = function() constructor {
				type = "CONTINUE";
			}
			
			// Exit statement (exit from a function)
			static Exit = function() constructor {
				type = "EXIT";
			}
			
			// Return statement
			static Return = function(_expression) constructor {
				type = "RETURN";
				expression = _expression; // AST for the expression to return
			}
			
			#endregion
			
			#region Try Catch Nodes
			
			static Try = function(_tryStatement, _catchNode, _finallyStatement) constructor {
				type = "TRY";
				tryStatement = _tryStatement; // AST for the try block
				catchNode = _catchNode;   // AST 'Catch' node representing catch (optional)
				finallyStatement = _finallyStatement; // AST for the finally block (optional)
			}
			
			static Catch = function(_exceptionVar, _statement) constructor {
				type = "CATCH";
				exceptionVar = _exceptionVar; // Name of the variable holding the caught exception
				statement = _statement;	   // AST for the catch block
			}
			
			static Finally = function(_statement) constructor {
				type = "FINALLY";
				statement = _statement; // AST for the finally block
			}
			
			#endregion
			
			#region Variable Declaration Nodes
			
			// GlobalVar declaration
			static GlobalVar = function(_name, _expression) constructor {
				type = "GLOBALVAR";
				name = _name; // Name of the global variable
				expression = _expression; // AST for the value assigned to the global variable
			}
			
			// Var declaration (local variable)
			static Var = function(_name, _expression) constructor {
				type = "VAR";
				name = _name; // Name of the local variable
				expression = _expression; // AST for the value assigned to the local variable
			}
			
			// Static variable declaration
			// For a constructor: scoped to all instances
			// For a function: scoped to each call of the function
			static Static = function(_name, _expression, _context) constructor {
				type = "STATIC";
				name = _name; // Name of the static variable
				expression = _expression; // AST for the value assigned to the static variable
				context = _context; // Context of the static variable (e.g., "constructor" or "function")
			}
			
			// Let declaration (block-scoped variable)
			static Let = function(_name, _expression) constructor {
				type = "LET";
				name = _name; // Name of the block-scoped variable
				expression = _expression; // AST for the value assigned to the block-scoped variable
			}
			
			#endregion
			
			#region Instance Nodes
			
			// 'with' statement
			static With = function(_object, _statement) constructor {
				type = "WITH";
				object = _object; // Object or instance identifier for 'with' context
				statement = _statement; // AST for the statement within the 'with' block
			}
			// 'self' reference
			static Self = function() constructor {
				type = "SELF";
				// Represents the current instance in the scope
			}
			// 'other' reference
			static Other = function() constructor {
				type = "OTHER";
				// Represents the other instance in a collision event or 'with' statement
			}
			// 'noone' constant
			static Noone = function() constructor {
				type = "NOONE";
				// Represents a non-existent instance
			}
			// 'all' reference
			static All = function() constructor {
				type = "ALL";
				// Represents all instances of a certain type or all instances in general
			}
			
			#endregion
			
			#region Math Nodes
			
			// Binary operators: +, -, *, /, <, <=, ==, !=, >, >=, and (&&), or (||), xor (^^)
			static BinaryOp = function(_left, _operator, _right) constructor {
				type = "BINARY_OP";
				left = _left; // Left operand (AST Node)
				operator = _operator; // Operator (e.g., '+', '-', '*', '/', etc.)
				right = _right; // Right operand (AST Node)
			}
			// Unary operators: not (!), -, ~
			static UnaryOp = function(_operator, _operand) constructor {
				type = "UNARY_OP";
				operator = _operator; // Operator (e.g., '!', '-', '~')
				operand = _operand; // Operand (AST Node)
			}
			// Increment/Decrement: ++, --
			static IncDecOp = function(_variable, _operator, _isPrefix) constructor {
				type = "INC_DEC_OP";
				variable = _variable; // Variable to increment/decrement
				operator = _operator; // Operator ('++' or '--')
				isPrefix = _isPrefix; // true if prefix (++x), false if postfix (x++)
			}
			// Assignment: =
			static Assignment = function(_variable, _expression) constructor {
				type = "ASSIGNMENT";
				variable = _variable; // Variable to assign to
				expression = _expression; // Expression (AST Node) to assign
			}
			// Nullish Coalescing: ??, ??=
			static NullishCoalescing = function(_variable, _defaultValue, _isAssignment) constructor {
				type = "NULLISH_COALESCING";
				variable = _variable; // Variable to check for nullish value
				defaultValue = _defaultValue; // Default value if variable is nullish
				isAssignment = _isAssignment; // true if '??=', false if '??'
			}
			// Bitwise operators: |, &, ^, <<, >>
			static BitwiseOp = function(_left, _operator, _right) constructor {
				type = "BITWISE_OP";
				left = _left;
				operator = _operator;
				right = _right;
			}
			// Division and Modulo: div, mod (%)
			static DivModOp = function(_left, _operator, _right) constructor {
				type = "DIV_MOD_OP";
				left = _left; // Left operand
				operator = _operator; // Operator ('div', 'mod', '%')
				right = _right; // Right operand
			}
			
			#endregion
			
			#region Enums Nodes
			
			// Enum declaration
			static Enum = function(_name, _fields) constructor {
				type = "ENUM";
				name = _name; // Name of the enum
				fields = _fields; // Array of 'EnumField' nodes
			}
			
			// Field within an enum
			static EnumField = function(_name, _value) constructor {
				type = "ENUM_FIELD";
				name = _name; // Name of the field
				value = _value; // Integer value assigned to the field (optional)
			}
			
			#endregion
			
			#region Region Nodes
			
			// Region start
			static Region = function(_name) constructor {
				type = "REGION";
				name = _name; // Optional name or description for the region
			}
			
			// Region end
			static EndRegion = function() constructor {
				type = "ENDREGION";
				// No additional properties needed
			}
			
			#endregion
			
			#region Macro Node
			
			// Extended Macro definition with configuration
			static Macro = function(_name, _expression, _configuration) constructor {
				type = "MACRO";
				name = _name;
				expression = _expression;
				configuration = _configuration; // Optional configuration
			}
			
			#endregion
			
			#region Object Creation Nodes
			
			static Array = function(_elements) constructor {
				type = "ARRAY";
				elements = _elements; // Array of AST nodes representing the elements in the array
			}
			
			static Struct = function(_fields) constructor {
				type = "STRUCT";
				fields = _fields; // Array of AST nodes representing the fields in the struct
			}
			
			#endregion
			
			#region Accessor Nodes
			
			static StructAccessor = function(_struct, _key) constructor {
				type = "STRUCT_ACCESSOR";
				struct = _struct; // AST Node representing the struct
				key = _key; // Property name being accessed
			}
			
			static ArrayAccessor = function(_array, _index) constructor {
				type = "ARRAY_ACCESSOR";
				array = _array; // AST Node representing the array
				index = _index; // Index for the element being accessed
			}
			
			static DSListAccessor = function(_list, _index) constructor {
				type = "DS_LIST_ACCESSOR";
				list = _list; // AST Node representing the DS list
				index = _index; // Index for the element being accessed
			}
			
			static DSMapAccessor = function(_map, _key) constructor {
				type = "DS_MAP_ACCESSOR";
				map = _map; // AST Node representing the DS map
				key = _key; // Key for the value being accessed
			}
			
			static DSGridAccessor = function(_grid, _x, _y) constructor {
				type = "DS_GRID_ACCESSOR";
				grid = _grid; // AST Node representing the DS grid
				x = _x; // X-coordinate in the grid
				y = _y; // Y-coordinate in the grid
			}
			
			#endregion
			
			static Comment = function(_text, _isBlockComment) constructor {
				type = "COMMENT";
				text = _text; // Text of the comment
				isBlockComment = _isBlockComment; // true for block comments, false for line comments
			}
			
			static Error = function(_message, _location) constructor {
				type = "ERROR";
				message = _message; // Error message
				location = _location; // Location or context of the error in the source code
			}
			
		}
		AST();
		
		#region AST Construction Methods
		
		static process_function_declaration = function(_token_arr, _pos, _ast) {
			// Method to parse a function declaration and create a corresponding AST node
			// Returns the updated position and modifies the AST
		};
		
		static process_if_statement = function(_token_arr, _pos, _ast) {
			// Method to parse an if statement and create corresponding AST nodes
			// Returns the updated position and modifies the AST
		};
		
		static process_for_loop = function(_token_arr, _pos, _ast) {
			// Method to parse a for loop and create a corresponding AST node
			// Returns the updated position and modifies the AST
		};
		
		static process_while_loop = function(_token_arr, _pos, _ast) {
			// Method to parse a while loop and create a corresponding AST node
			// Returns the updated position and modifies the AST
		};
		
		static process_variable_declaration = function(_token_arr, _pos, _ast) {
			// Method to parse variable declarations and create corresponding AST nodes
			// Returns the updated position and modifies the AST
		};
		
		static process_expression = function(_token_arr, _pos, _ast) {
			// Method to parse expressions and create corresponding AST nodes
			// Returns the updated position and modifies the AST
		};
		
		static process_error = function(_token_arr, _pos, _ast) {
			// Method to handle unexpected tokens or structures
			// Returns the updated position and modifies the AST
		};
		
		#endregion
		
		#endregion
		
		static __parse_hinting_pass = function() {
			//this method is used to itterate through all the variable definitions in a scope and apply them.
		}
		
	#endregion
	
	//restructure
}
function GML_Renderer() : Renderer() constructor {
	static __GmlSpec = GmlSpec();
}
function GML_Compiler() : Compiler() constructor {
	static __GmlSpec = GmlSpec();
	/* Define the conversion from token array to a compiled order of instructions */
}


var _parser = new GML_Tokenizer();


// Test tokenize_whitespace
show_debug_message("Testing tokenize_whitespace");
log(_parser.parse("   \t\n"));
// Expected: Whitespace tokens for spaces, tab, and newline

// Test tokenize_operator
show_debug_message("Testing tokenize_operator");
log(_parser.parse("+ - * / %"));

show_debug_message("========== Testing tokenize_operator");
log(_parser.parse("??="));

// Expected: Operator tokens for each arithmetic operator

// Test tokenize_number
show_debug_message("Testing tokenize_number");
log(_parser.parse("123 4.56 7_890"));
// Expected: Number tokens for 123, 4.56, and 7890 (underscore ignored in numbers)

// Test tokenize_number with leading underscore (should be treated as identifier)
show_debug_message("Testing tokenize_number with leading underscore");
log(_parser.parse("_123"));
// Expected: Identifier token for _123

// Test tokenize_identifier
show_debug_message("Testing tokenize_identifier");
log(_parser.parse("variableName _with_underscore CamelCase123"));
// Expected: Identifier tokens for each example identifier

// Test tokenize_identifier
show_debug_message("=========== Testing tokenize_identifier");
log(_parser.parse("function globalvar region"));

// Test tokenize_identifier
show_debug_message("=========== Testing tokenize_identifier");
log(_parser.parse("if(){}else{}"));


// Test tokenize_illegal
show_debug_message("Testing tokenize_illegal");
log(_parser.parse("£"));
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_literal
show_debug_message("Testing tokenize_string_literal");
log(_parser.parse("\"This is a stringLitteral\""));
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_literal
show_debug_message("Testing tokenize_string_literal with escapes");
log(_parser.parse("\"\\tThis is a stringLitteral\\nWith line breaks\""));
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_legacy
show_debug_message("Testing tokenize_string_legacy with \"");
log(_parser.parse("@\"This is a stringBlock\nwith a line break\""));
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_legacy
show_debug_message("Testing tokenize_string_legacy with '");
log(_parser.parse("@'This is a stringBlock\nwith a line break'"));
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_expression
show_debug_message("Testing tokenize_string_expression");
log(_parser.parse(@'var _example1 = $"A1 { abc } A2";'));

// Test tokenize_string_expression
show_debug_message("Testing tokenize_string_expression");
log(_parser.parse(@'var _example1 = $"A1 { $"B1 { $"C1 { D1 } C2 { D2 } C3" } B2" } A2";'));
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_expression
show_debug_message("Testing tokenize_string_expression with line breaks");
log(_parser.parse(@'var _example2 = $"A1 {
$"B1 {
$"C1 {
D
} C2"
} B2"
} A2";'));
// Expected: Illegal tokens for each unrecognized character



// Test tokenize_string_expression
show_debug_message("=========== Testing tokenize_comment_line");
log(_parser.parse(@'var a = 1; //This is the comment'));

// Test tokenize_string_expression
show_debug_message("=========== Testing tokenize_comment_block");
log(_parser.parse(@'var a = 1; /*This is the comment
on
multiple lines*/
var b = 2;'));



log(_parser.parse(@'£var _arr = [1, "a", c_white];'));


