//t = 0
//var _i=1; repeat(1024) {
//    str = "function __gmlc_execute_block_"+string_replace_all(string_format(_i, 4, 0), " ", "0")+"__() {"
    
//    var w = ceil(sqrt(_i))
//    var h = floor(sqrt(_i))
//    var total = 0
//    var should_break = false;
    
//    var _j=0; repeat (h) {
//        str += "\n"+"    "
//        t+=1
//        repeat(w) {
//            str += "__func" + string_replace_all( string_format(_j, 4, 0), " ", 0)+"(); "
//            total += 1
//            if (total == _i) {
//                should_break = true;
//                break
//            }
//        _j++}
//    }
    
//    str += "\n"+"}"
//    t+=1
//    show_debug_message(str)
    
//_i++}

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
		show_debug_message($"{expected} != {result}")
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
function __struct_equals(_recieved, _expected) {
	if (_recieved == undefined) return false;
	
	var _names = struct_get_names(_expected);
	var _i=0; repeat(array_length(_names)){
		var _name = _names[_i];
		var _expected_value = _expected[$ _name];
		
		if !struct_exists(_recieved, _name) {
			show_debug_message($"Recieved struct is missing the expected key '{_name}'")
		}
		
		if (typeof(_expected_value) != typeof(_recieved[$ _name])) {
			show_debug_message($"Recieved struct's key ({_name}) is mismatched typeof() with the expected '{_name}'")
			show_debug_message($"Recieved '{typeof(_recieved[$ _name])}'\nExpected '{typeof(_expected_value)}'")
			show_debug_message($"Recieved '{_recieved[$ _name]}'\nExpected '{_expected_value}'")
		}
		
		switch (typeof(_expected_value)) {
			case "struct":{
				if !__struct_equals(_recieved[$ _name], _expected_value) {
					show_debug_message($"Recieved struct's child struct is mismatched with the expected key '{_name}'")
					return false;
				}
			break;}
			case "array":{
				if !__array_equals(_recieved[$ _name], _expected_value) {
					show_debug_message($"Recieved struct's child array is mismatched with the expected key '{_name}'")
					return false;
				}
			break;}
			default:
				if (_recieved[$ _name] != _expected_value) {
					show_debug_message($"Recieved struct's key is mismatched with the expected key '{_name}'")
					show_debug_message($"Recieved ({_recieved[$ _name]})\nExpected '{_expected_value}'")
					return false;
				}
			break;
		}
	_i+=1}
	
	return true;
}
function __array_equals(_recieved, _expected) {
	if (_recieved == undefined) return false;
	
	if (array_length(_recieved) != array_length(_expected)) {
		log("Array lengths dont match")
		log($"Recieved: {array_length(_recieved)}\nExpected: {array_length(_expected)}")
		return false;
	}
	
	var _i=0; repeat(array_length(_expected)){
		var _expected_value = _expected[_i];
		
		if (typeof(_expected_value) != typeof(_recieved[_i])) {
			show_debug_message($"Recieved array's index ({_i}) is mismatched with the expected index '{_i}'")
			show_debug_message($"Recieved ({_recieved[_i]})\nExpected '{_expected_value}'")
		}
		
		switch (typeof(_expected_value)) {
			case "struct":{
				if !__struct_equals(_recieved[_i], _expected_value) {
					show_debug_message($"Recieved array's child struct is mismatched with the expected index's struct '{_i}'")
					return false;
				}
			break;}
			case "array":{
				if !__array_equals(_recieved[_i], _expected_value) {
					show_debug_message($"Recieved array's child array is mismatched with the expected index's value '{_i}'")
					return false;
				}
			break;}
			default:
				if (_recieved[_i] != _expected_value) {
					show_debug_message($"Recieved array's index ({_i}) is mismatched with the expected index '{_i}'")
					show_debug_message($"Recieved ({_recieved[_i]})\nExpected '{_expected_value}'")
					return false;
				}
			break;
		}
	_i+=1}
	
	return true;
}

log("\n\n\n")

#region Tokenizer Tests
function run_tokenize_test(description, input, expected) {
	log($"Attempting Tokenizer Test :: {description}")
	
	var tokenizer = new GML_Tokenizer();
	tokenizer.initialize(input);
	var program = tokenizer.parseAll();
	
	__compare_results(description, program, expected);
}
function run_all_tokenize_test() {
log("~~~~~ Tokenizer Unit Tests ~~~~~\n")

#region Whitespace handling remains unchanged as there are no tokens expected
run_tokenize_test("Test whitespace handling", "    ",
{
  tokens:[
  ],
});
run_tokenize_test("Test whitespace varients", "   \t\n", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Whitespace,
      name:"\n",
      line:1.0,
      column:5.0,
      value:"\n"
    }
  ],
});
#endregion
#region Test cases for number tokenization
run_tokenize_test("Test number tokenization", "123 456.789 01234", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"123",
      line:1.0,
      column:1.0,
      value:123.0
    },
    {
      type: __GMLC_TokenType.Number,
      name:"456.789",
      line:1.0,
      column:5.0,
      value:456.78899999999999
    },
    {
      type: __GMLC_TokenType.Number,
      name:"01234",
      line:1.0,
      column:13.0,
      value:1234.0
    }
  ],
});

// Test case for floating point edge cases
run_tokenize_test("Test floating point edge cases", ".5 5.", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:".5",
      line:1.0,
      column:1.0,
      value:0.5
    },
    {
      type: __GMLC_TokenType.Number,
      name:"5.",
      line:1.0,
      column:4.0,
      value:5.0
    }
  ],
});

run_tokenize_test("Test tokenize_number", "123 4.56 7_890", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"123",
      line:1.0,
      column:1.0,
      value:123.0
    },
    {
      type: __GMLC_TokenType.Number,
      name:"4.56",
      line:1.0,
      column:5.0,
      value:4.56
    },
    {
      type: __GMLC_TokenType.Number,
      name:"7_890",
      line:1.0,
      column:10.0,
      value:7890.0
    }
  ],
});

#endregion
#region Test cases for identifiers and keywords
run_tokenize_test("Test identifiers and keywords", "function varName if else", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Keyword,
      name:"function",
      line:1.0,
      column:1.0,
      value:"function"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"varName",
      line:1.0,
      column:10.0,
      value:"varName"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"if",
      line:1.0,
      column:18.0,
      value:"if"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"else",
      line:1.0,
      column:21.0,
      value:"else"
    }
  ],
});

run_tokenize_test("Test tokenize_identifier", "variableName _with_underscore CamelCase123 function globalvar region if(){}else{}", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Identifier,
      name:"variableName",
      line:1.0,
      column:1.0,
      value:"variableName"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"_with_underscore",
      line:1.0,
      column:14.0,
      value:"_with_underscore"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"CamelCase123",
      line:1.0,
      column:31.0,
      value:"CamelCase123"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"function",
      line:1.0,
      column:44.0,
      value:"function"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"globalvar",
      line:1.0,
      column:53.0,
      value:"globalvar"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"region",
      line:1.0,
      column:63.0,
      value:"region"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"if",
      line:1.0,
      column:70.0,
      value:"if"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:"(",
      line:1.0,
      column:72.0,
      value:"("
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:")",
      line:1.0,
      column:73.0,
      value:")"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:"{",
      line:1.0,
      column:74.0,
      value:"{"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:"}",
      line:1.0,
      column:75.0,
      value:"}"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"else",
      line:1.0,
      column:76.0,
      value:"else"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:"{",
      line:1.0,
      column:80.0,
      value:"{"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:"}",
      line:1.0,
      column:81.0,
      value:"}"
    }
  ],
});

#endregion
#region Test cases for operator tokenization
run_tokenize_test("Test operator tokenization", "+ - * / == != < <= > >= && ||",
{
  tokens:[
    {
      type: __GMLC_TokenType.Operator,
      name:"+",
      line:1.0,
      column:1.0,
      value:"+"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"-",
      line:1.0,
      column:3.0,
      value:"-"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"*",
      line:1.0,
      column:5.0,
      value:"*"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"\/",
      line:1.0,
      column:7.0,
      value:"\/"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"==",
      line:1.0,
      column:9.0,
      value:"=="
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"!=",
      line:1.0,
      column:12.0,
      value:"!="
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"<",
      line:1.0,
      column:15.0,
      value:"<"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"<=",
      line:1.0,
      column:17.0,
      value:"<="
    },
    {
      type: __GMLC_TokenType.Operator,
      name:">",
      line:1.0,
      column:20.0,
      value:">"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:">=",
      line:1.0,
      column:22.0,
      value:">="
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"&&",
      line:1.0,
      column:25.0,
      value:"&&"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"||",
      line:1.0,
      column:28.0,
      value:"||"
    }
  ],
});

run_tokenize_test("Test tokenize_operator", "+ - * / % ??=",
{
  tokens:[
    {
      type: __GMLC_TokenType.Operator,
      name:"+",
      line:1.0,
      column:1.0,
      value:"+"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"-",
      line:1.0,
      column:3.0,
      value:"-"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"*",
      line:1.0,
      column:5.0,
      value:"*"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"\/",
      line:1.0,
      column:7.0,
      value:"\/"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"%",
      line:1.0,
      column:9.0,
      value:"mod"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"??=",
      line:1.0,
      column:11.0,
      value:"??="
    }
  ],
});
// Test case for chained operators
run_tokenize_test("Test chained operators", "+++", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Operator,
      name:"++",
      line:1.0,
      column:1.0,
      value:"++"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"+",
      line:1.0,
      column:3.0,
      value:"+"
    }
  ],
});

#endregion
#region Test cases for string literal tokenization
run_tokenize_test("Test string literal tokenization", @'"Hello, World!" "Another\"String"', 
{
  tokens:[
    {
      type: __GMLC_TokenType.String,
      name:"\"Hello, World!\"",
      line:1.0,
      column:1.0,
      value:"Hello, World!"
    },
    {
      type: __GMLC_TokenType.String,
      name:"\"Another\"String\"",
      line:1.0,
      column:17.0,
      value:"Another\"String"
    }
  ],
});
run_tokenize_test("Test empty string literal tokenization", "\"\"", 
{
  tokens:[
    {
      type: __GMLC_TokenType.String,
      name:"\"\"",
      line:1.0,
      column:1.0,
      value:""
    }
  ],
});
// Test case for escape characters in strings
run_tokenize_test("Test escape sequences in strings", "\"Line\\nBreak\"", 
{
  tokens:[
    {
      type: __GMLC_TokenType.String,
      name:"\"Line\nBreak\"",
      line:1.0,
      column:1.0,
      value:"Line\nBreak"
    }
  ],
});
run_tokenize_test("Test tokenize_string_literal", "\"This is a stringLiteral\" \"\\tThis is a stringLiteral\\nWith line breaks\"", 
{
  tokens:[
    {
      type: __GMLC_TokenType.String,
      name:"\"This is a stringLiteral\"",
      line:1.0,
      column:1.0,
      value:"This is a stringLiteral"
    },
    {
      type: __GMLC_TokenType.String,
      name:"\"\tThis is a stringLiteral\nWith line breaks\"",
      line:1.0,
      column:27.0,
      value:"\tThis is a stringLiteral\nWith line breaks"
    }
  ],
});

#endregion
#region Test cases for raw string literal tokenization
run_tokenize_test("Test Raw string literal tokenization", "@'This is a test of the system'", 
{
  tokens:[
    {
      type: __GMLC_TokenType.String,
      name:"@'This is a test of the system'",
      line:1.0,
      column:1.0,
      value:"This is a test of the system"
    }
  ],
});

run_tokenize_test("Test tokenize_raw_string_literals", "@\"This is a stringBlock\nwith a line break\" @'This is a second stringBlock\nwith a line break'", 
{
  tokens:[
    {
      type: __GMLC_TokenType.String,
      name:"@\"This is a stringBlock\nwith a line break\"",
      line:1.0,
      column:1.0,
      value:"This is a stringBlock\nwith a line break"
    },
    {
      type: __GMLC_TokenType.String,
      name:"@'This is a second stringBlock\nwith a line break'",
      line:2.0,
      column:20.0,
      value:"This is a second stringBlock\nwith a line break"
    }
  ],
});

#endregion
#region Test cases for line comment tokenization
run_tokenize_test("Test line comment tokenization", "// This is a comment\n// Another line", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Comment,
      name:"\/\/ This is a comment",
      line:1.0,
      column:1.0,
      value:"\/\/ This is a comment"
    },
    {
      type: __GMLC_TokenType.Whitespace,
      name:"\n",
      line:1.0,
      column:21.0,
      value:"\n"
    },
    {
      type: __GMLC_TokenType.Comment,
      name:"\/\/ Another line",
      line:2.0,
      column:1.0,
      value:"\/\/ Another line"
    }
  ],
});
#endregion
#region Test cases for block comment tokenization
run_tokenize_test("Test block comment tokenization", "/* Block comment */ int x = 5;", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Comment,
      name:"\/* Block comment *\/",
      line:1.0,
      column:1.0,
      value:"\/* Block comment *\/"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"int",
      line:1.0,
      column:21.0,
      value:"int"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"x",
      line:1.0,
      column:25.0,
      value:"x"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"=",
      line:1.0,
      column:27.0,
      value:"="
    },
    {
      type: __GMLC_TokenType.Number,
      name:"5",
      line:1.0,
      column:29.0,
      value:5.0
    }
  ],
});
// Test case for nested block comments
run_tokenize_test("Test nested block comments", "/* Comment */ Nested /* End */", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Comment,
      name:"\/* Comment *\/",
      line:1.0,
      column:1.0,
      value:"\/* Comment *\/"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"Nested",
      line:1.0,
      column:15.0,
      value:"Nested"
    },
    {
      type: __GMLC_TokenType.Comment,
      name:"\/* End *\/",
      line:1.0,
      column:22.0,
      value:"\/* End *\/"
    }
  ],
});
run_tokenize_test("Test tokenize_comment_line and block", @'// This is the comment
/*This is the comment
on
multiple lines*/
var b = 2;',
{
  tokens:[
    {
      type: __GMLC_TokenType.Comment,
      name:"\/\/ This is the comment",
      line:1.0,
      column:1.0,
      value:"\/\/ This is the comment"
    },
    {
      type: __GMLC_TokenType.Whitespace,
      name:"\n",
      line:1.0,
      column:24.0,
      value:"\n"
    },
    {
      type: __GMLC_TokenType.Comment,
      name:"\/*This is the comment\r\non\r\nmultiple lines*\/",
      line:2.0,
      column:1.0,
      value:"\/*This is the comment\r\non\r\nmultiple lines*\/"
    },
    {
      type: __GMLC_TokenType.Whitespace,
      name:"\n",
      line:4.0,
      column:18.0,
      value:"\n"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"var",
      line:5.0,
      column:1.0,
      value:"var"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"b",
      line:5.0,
      column:5.0,
      value:"b"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"=",
      line:5.0,
      column:7.0,
      value:"="
    },
    {
      type: __GMLC_TokenType.Number,
      name:"2",
      line:5.0,
      column:9.0,
      value:2.0
    }
  ],
});

#endregion
#region Test cases for mixed content
run_tokenize_test("Test mixed content", @'var x = 100; // variable declaration
function test() { return x; }',
{
  tokens:[
    {
      type: __GMLC_TokenType.Keyword,
      name:"var",
      line:1.0,
      column:1.0,
      value:"var"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"x",
      line:1.0,
      column:5.0,
      value:"x"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"=",
      line:1.0,
      column:7.0,
      value:"="
    },
    {
      type: __GMLC_TokenType.Number,
      name:"100",
      line:1.0,
      column:9.0,
      value:100.0
    },
    {
      type: __GMLC_TokenType.Comment,
      name:"\/\/ variable declaration",
      line:1.0,
      column:14.0,
      value:"\/\/ variable declaration"
    },
    {
      type: __GMLC_TokenType.Whitespace,
      name:"\n",
      line:1.0,
      column:38.0,
      value:"\n"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"function",
      line:2.0,
      column:1.0,
      value:"function"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"test",
      line:2.0,
      column:10.0,
      value:"test"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:"(",
      line:2.0,
      column:14.0,
      value:"("
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:")",
      line:2.0,
      column:15.0,
      value:")"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:"{",
      line:2.0,
      column:17.0,
      value:"{"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"return",
      line:2.0,
      column:19.0,
      value:"return"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"x",
      line:2.0,
      column:26.0,
      value:"x"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:"}",
      line:2.0,
      column:29.0,
      value:"}"
    }
  ],
});
#endregion
#region Test case for simple hexadecimal number tokenization
run_tokenize_test("Test hexadecimal number tokenization", "$FFFFFFFF", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"$FFFFFFFF",
      line:1.0,
      column:1.0,
      value:4294967295.0
    }
  ],
});
#endregion
#region Test case for mixed tokens involving a hexadecimal number
run_tokenize_test("Test hexadecimal number mixed tokens", "$Fg=1", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"$F",
      line:1.0,
      column:1.0,
      value:15.0
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"g",
      line:1.0,
      column:3.0,
      value:"g"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"=",
      line:1.0,
      column:4.0,
      value:"="
    },
    {
      type: __GMLC_TokenType.Number,
      name:"1",
      line:1.0,
      column:5.0,
      value:1.0
    }
  ],
});
#endregion
#region Test case for a long hexadecimal number tokenization
run_tokenize_test("Test hexadecimal number <number> tokenization", "0xF", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"0xF",
      line:1.0,
      column:1.0,
      value:15.0
    }
  ],
});
run_tokenize_test("Test hexadecimal number <number> tokenization", "0xFFFFFFF", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"0xFFFFFFF",
      line:1.0,
      column:1.0,
      value:268435455.0
    }
  ],
});
run_tokenize_test("Test hexadecimal number <int64> tokenization", "$FFFFFFFF",
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"$FFFFFFFF",
      line:1.0,
      column:1.0,
      value:$FFFFFFFF
    }
  ],
});
run_tokenize_test("Test hexadecimal number <int64> tokenization", "0xFFFFFFFFFFFFFFF", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"0xFFFFFFFFFFFFFFF",
      line:1.0,
      column:1.0,
      value:0xFFFFFFFFFFFFFFF
    }
  ],
});
#endregion
#region Test case for simple binary number tokenization
run_tokenize_test("Test binary number <number> tokenization", "0b1",
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"0b1",
      line:1.0,
      column:1.0,
      value:1.0
    }
  ],
});
run_tokenize_test("Test binary number <number> tokenization", "0b1111111111111111111111111111111", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"0b1111111111111111111111111111111",
      line:1.0,
      column:1.0,
      value:2147483647.0
    }
  ],
});
run_tokenize_test("Test binary number <int64> tokenization", "0b11111111111111111111111111111111", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"0b11111111111111111111111111111111",
      line:1.0,
      column:1.0,
      value:0b11111111111111111111111111111111
    }
  ],
});
run_tokenize_test("Test binary number <int64> tokenization", "0b11111111111111111111111111111111111111111111111111111111111111", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"0b11111111111111111111111111111111111111111111111111111111111111",
      line:1.0,
      column:1.0,
      value:0b11111111111111111111111111111111111111111111111111111111111111
    }
  ],
});
#endregion
#region Test case for binary number tokenization with mixed tokens
run_tokenize_test("Test binary number tokenization", "0b1111a=2", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"0b1111",
      line:1.0,
      column:1.0,
      value:15.0
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"a",
      line:1.0,
      column:7.0,
      value:"a"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"=",
      line:1.0,
      column:8.0,
      value:"="
    },
    {
      type: __GMLC_TokenType.Number,
      name:"2",
      line:1.0,
      column:9.0,
      value:2.0
    }
  ],
});
#endregion
#region Test case for recognizing a function identifier token
run_tokenize_test("Test Function Identifier tokenization", "animcurve_get_channel", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Function,
      name:"animcurve_get_channel",
      line:1.0,
      column:1.0,
      value:845.0
    }
  ],
});
#endregion
#region Test case for recognizing a constant identifier token
run_tokenize_test("Test Constant Identifier tokenization", "c_red", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Number,
      name:"c_red",
      line:1.0,
      column:1.0,
      value:255.0
    }
  ],
});
#endregion
#region Test case for simple macro definition
run_tokenize_test("Test simple macro tokenization", "#macro TOTAL_WEAPONS 10", 
{
  tokens:[
    {
      type: __GMLC_TokenType.Operator,
      name:"#",
      line:1.0,
      column:1.0,
      value:"#"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"macro",
      line:1.0,
      column:2.0,
      value:"macro"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"TOTAL_WEAPONS",
      line:1.0,
      column:8.0,
      value:"TOTAL_WEAPONS"
    },
    {
      type: __GMLC_TokenType.Number,
      name:"10",
      line:1.0,
      column:22.0,
      value:10.0
    }
  ],
});
#endregion
#region Test case for macro with a complex expression
run_tokenize_test("Test macro with expression tokenization", "#macro COL make_colour_hsv(irandom(255), 255, 255)",{
  tokens:[
    {
      type: __GMLC_TokenType.Operator,
      name:"#",
      line:1.0,
      column:1.0,
      value:"#"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"macro",
      line:1.0,
      column:2.0,
      value:"macro"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"COL",
      line:1.0,
      column:8.0,
      value:"COL"
    },
    {
      type: __GMLC_TokenType.Function,
      name:"make_colour_hsv",
      line:1.0,
      column:12.0,
      value:402.0
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:"(",
      line:1.0,
      column:27.0,
      value:"("
    },
    {
      type: __GMLC_TokenType.Function,
      name:"irandom",
      line:1.0,
      column:28.0,
      value:219.0
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:"(",
      line:1.0,
      column:35.0,
      value:"("
    },
    {
      type: __GMLC_TokenType.Number,
      name:"255",
      line:1.0,
      column:36.0,
      value:255.0
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:")",
      line:1.0,
      column:39.0,
      value:")"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:",",
      line:1.0,
      column:40.0,
      value:","
    },
    {
      type: __GMLC_TokenType.Number,
      name:"255",
      line:1.0,
      column:42.0,
      value:255.0
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:",",
      line:1.0,
      column:45.0,
      value:","
    },
    {
      type: __GMLC_TokenType.Number,
      name:"255",
      line:1.0,
      column:47.0,
      value:255.0
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:")",
      line:1.0,
      column:50.0,
      value:")"
    }
  ],
});
#endregion
#region Test case for multi-line macro definition
run_tokenize_test("Test multi-line macro tokenization", @'#macro HELLO show_debug_message("Hello" + \
string(player_name) + \
", how are you today?")',
{
  tokens:[
    {
      type: __GMLC_TokenType.Operator,
      name:"#",
      line:1.0,
      column:1.0,
      value:"#"
    },
    {
      type: __GMLC_TokenType.Keyword,
      name:"macro",
      line:1.0,
      column:2.0,
      value:"macro"
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"HELLO",
      line:1.0,
      column:8.0,
      value:"HELLO"
    },
    {
      type: __GMLC_TokenType.Function,
      name:"show_debug_message",
      line:1.0,
      column:14.0,
      value:1146.0
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:"(",
      line:1.0,
      column:32.0,
      value:"("
    },
    {
      type: __GMLC_TokenType.String,
      name:"\"Hello\"",
      line:1.0,
      column:33.0,
      value:"Hello"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"+",
      line:1.0,
      column:41.0,
      value:"+"
    },
    {
      type: __GMLC_TokenType.EscapeOperator,
      name:"\\",
      line:1.0,
      column:43.0,
      value:"\\"
    },
    {
      type: __GMLC_TokenType.Whitespace,
      name:"\n",
      line:1.0,
      column:45.0,
      value:"\n"
    },
    {
      type: __GMLC_TokenType.Function,
      name:"string",
      line:2.0,
      column:1.0,
      value:264.0
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:"(",
      line:2.0,
      column:7.0,
      value:"("
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"player_name",
      line:2.0,
      column:8.0,
      value:"player_name"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:")",
      line:2.0,
      column:19.0,
      value:")"
    },
    {
      type: __GMLC_TokenType.Operator,
      name:"+",
      line:2.0,
      column:21.0,
      value:"+"
    },
    {
      type: __GMLC_TokenType.EscapeOperator,
      name:"\\",
      line:2.0,
      column:23.0,
      value:"\\"
    },
    {
      type: __GMLC_TokenType.Whitespace,
      name:"\n",
      line:2.0,
      column:25.0,
      value:"\n"
    },
    {
      type: __GMLC_TokenType.String,
      name:"\", how are you today?\"",
      line:3.0,
      column:1.0,
      value:", how are you today?"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:")",
      line:3.0,
      column:23.0,
      value:")"
    }
  ],
});
#endregion
#region Test case for using an enum identifier
run_tokenize_test("Test Enum Identifier tokenization", "AudioLFOType.Triangle",
{
  tokens:[
    {
      type: __GMLC_TokenType.Identifier,
      name:"AudioLFOType",
      line:1.0,
      column:1.0,
      value:"AudioLFOType"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:".",
      line:1.0,
      column:13.0,
      value:"."
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"Triangle",
      line:1.0,
      column:14.0,
      value:"Triangle"
    }
  ],
});
#endregion
#region Test case for a complex template string with expressions embedded
//run_tokenize_test("Test String Template tokenization", "$\"This is a {variable} with an expression {funcCall()} included\"", [
//	{type: "TemplateString", name:"$\"This is a {variable} with an expression {funcCall()} included\"", value: [
//		{type: "TemplateLiteral", value: "This is a ", line: 1, column: 3},
//		{type: "TemplateExpression", value: "variable", line: 1, column: 15},
//		{type: "TemplateLiteral", value: " with an expression ", line: 1, column: 25},
//		{type: "TemplateExpression", value: "funcCall()", line: 1, column: 45},
//		{type: "TemplateLiteral", value: " included", line: 1, column: 57}
//	], line: 1, column: 1}
//]);
#endregion
#region Test case for Illegal
// Test case for Unicode characters in identifiers
run_tokenize_test("Test Unicode identifiers", "变量",
{
  tokens:[
    {
      type: __GMLC_TokenType.Illegal,
      name:"变",
      line:1.0,
      column:1.0,
      value:"Object: {<OBJ>} Event: {<EVENT>} at line 1 : invalid token 变"
    },
    {
      type: __GMLC_TokenType.Illegal,
      name:"量",
      line:1.0,
      column:2.0,
      value:"Object: {<OBJ>} Event: {<EVENT>} at line 1 : invalid token 量"
    }
  ],
});
// Test case for incomplete tokens
run_tokenize_test("Test incomplete tokens", "\"Hello 0x /*",
{
  tokens:[
    {
      type: __GMLC_TokenType.Illegal,
      name:"\"Hello 0x \/*",
      line:1.0,
      column:1.0,
      value:"Object: {<OBJ>} Event: {<EVENT>} at line 1 : Error parsing string literal - found newline within string"
    }
  ],
});
#endregion

log("\n\n\n")
}
//run_all_tokenize_test();
#endregion

#region PreProcessor Tests
function run_preprocessor_test(description, input, expected) {
	log($"Attempting Pre Processor Test :: {description}")
	
	var tokenizer = new GML_Tokenizer();
	tokenizer.initialize(input);
	var program = tokenizer.parseAll();
	
	var preprocessor = new GML_PreProcessor();
	preprocessor.initialize(program);
	var program = preprocessor.parseAll();
	
	__compare_results(description, program, expected);
}
function run_all_preprocessor_test() {
log("~~~~~ PreProcessor Unit Tests ~~~~~\n")
#region Test 1: Single Value Macro
run_preprocessor_test("Single Value Macro",
@'#macro TOTAL_WEAPONS 10

TOTAL_WEAPONS',
{
  tokens:[
    {
      type: __GMLC_TokenType.Identifier,
      name:"TOTAL_WEAPONS",
      line:3.0,
      column:1.0,
      value:"TOTAL_WEAPONS"
    }
  ],
  MacroVar:{
    TOTAL_WEAPONS:[
      {
        type: __GMLC_TokenType.Number,
        name:"10",
        line:1.0,
        column:22.0,
        value:10.0
      }
    ]
  },
  MacroVarNames:[
    "TOTAL_WEAPONS"
  ]
});
#endregion
#region Test 2: Statement Macro
run_preprocessor_test("Statement Macro",
@'#macro INIT_LOGIC log("Starting")

INIT_LOGIC',
{
  tokens:[
    {
      type: __GMLC_TokenType.Identifier,
      name:"INIT_LOGIC",
      line:3.0,
      column:1.0,
      value:"INIT_LOGIC"
    }
  ],
  MacroVar:{
    INIT_LOGIC:[
      {
        type: __GMLC_TokenType.Function,
        name:"log",
        line:1.0,
        column:19.0,
        value: log
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:"(",
        line:1.0,
        column:22.0,
        value:"("
      },
      {
        type: __GMLC_TokenType.String,
        name:"\"Starting\"",
        line:1.0,
        column:23.0,
        value:"Starting"
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:")",
        line:1.0,
        column:33.0,
        value:")"
      }
    ]
  },
  MacroVarNames:[
    "INIT_LOGIC"
  ]
});
#endregion
#region Test 3: Multiline Macro
run_preprocessor_test("Multiline Macro",
@'#macro HELLO show_debug_message("Hello" + \
string(player_name) + \
", how are you today?");

HELLO',
{
  tokens:[
    {
      type: __GMLC_TokenType.Identifier,
      name:"HELLO",
      line:5.0,
      column:1.0,
      value:"HELLO"
    }
  ],
  MacroVar:{
    HELLO:[
      {
        type: __GMLC_TokenType.Function,
        name:"show_debug_message",
        line:1.0,
        column:14.0,
        value:1146.0
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:"(",
        line:1.0,
        column:32.0,
        value:"("
      },
      {
        type: __GMLC_TokenType.String,
        name:"\"Hello\"",
        line:1.0,
        column:33.0,
        value:"Hello"
      },
      {
        type: __GMLC_TokenType.Operator,
        name:"+",
        line:1.0,
        column:41.0,
        value:"+"
      },
      {
        type: __GMLC_TokenType.Function,
        name:"string",
        line:2.0,
        column:1.0,
        value:264.0
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:"(",
        line:2.0,
        column:7.0,
        value:"("
      },
      {
        type: __GMLC_TokenType.Identifier,
        name:"player_name",
        line:2.0,
        column:8.0,
        value:"player_name"
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:")",
        line:2.0,
        column:19.0,
        value:")"
      },
      {
        type: __GMLC_TokenType.Operator,
        name:"+",
        line:2.0,
        column:21.0,
        value:"+"
      },
      {
        type: __GMLC_TokenType.String,
        name:"\", how are you today?\"",
        line:3.0,
        column:1.0,
        value:", how are you today?"
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:")",
        line:3.0,
        column:23.0,
        value:")"
      }
    ]
  },
  MacroVarNames:[
    "HELLO"
  ]
});
#endregion
#region Test 4: Basic Enum
run_preprocessor_test("Basic Enum",
@'enum RAINBOW {
    RED,
    ORANGE,
    YELLOW,
    GREEN,
    BLUE,
    INDIGO,
    VIOLET
}

RAINBOW.GREEN',
{
  EnumVar:{
    RAINBOW:{
      RED:[
        {
          type: __GMLC_TokenType.Number,
          name:",",
          line:2.0,
          column:8.0,
          value:0.0
        }
      ],
      ORANGE:[
        {
          type: __GMLC_TokenType.Number,
          name:",",
          line:3.0,
          column:11.0,
          value:1.0
        }
      ],
      YELLOW:[
        {
          type: __GMLC_TokenType.Number,
          name:",",
          line:4.0,
          column:11.0,
          value:2.0
        }
      ],
      GREEN:[
        {
          type: __GMLC_TokenType.Number,
          name:",",
          line:5.0,
          column:10.0,
          value:3.0
        }
      ],
      BLUE:[
        {
          type: __GMLC_TokenType.Number,
          name:",",
          line:6.0,
          column:9.0,
          value:4.0
        }
      ],
      INDIGO:[
        {
          type: __GMLC_TokenType.Number,
          name:",",
          line:7.0,
          column:11.0,
          value:5.0
        }
      ],
      VIOLET:[
        {
          type: __GMLC_TokenType.Number,
          name:"\n",
          line:8.0,
          column:12.0,
          value:6.0
        }
      ]
    }
  },
  EnumVarNames:{
    RAINBOW:[
      "RED",
      "ORANGE",
      "YELLOW",
      "GREEN",
      "BLUE",
      "INDIGO",
      "VIOLET"
    ]
  },
  tokens:[
    {
      type: __GMLC_TokenType.Identifier,
      name:"RAINBOW",
      line:11.0,
      column:1.0,
      value:"RAINBOW"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:".",
      line:11.0,
      column:8.0,
      value:"."
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"GREEN",
      line:11.0,
      column:9.0,
      value:"GREEN"
    }
  ],
});
#endregion
#region Test 5: Enums Built with Other Enums
run_preprocessor_test("Enums Built with Other Enums",
@'enum BASE {
    FIRST = 1,
    SECOND
}

enum DERIVED {
    NEXT = BASE.FIRST + 3
}

DERIVED.NEXT',
{
  EnumVar:{
    BASE:{
      FIRST:[
        {
          type: __GMLC_TokenType.Number,
          name:"1",
          line:2.0,
          column:13.0,
          value:1.0
        }
      ],
      SECOND:[
        {
          type: __GMLC_TokenType.Number,
          name:"\n",
          line:3.0,
          column:12.0,
          value:1.0
        }
      ]
    },
    DERIVED:{
      NEXT:[
        {
          type: __GMLC_TokenType.Identifier,
          name:"BASE",
          line:7.0,
          column:12.0,
          value:"BASE"
        },
        {
          type: __GMLC_TokenType.Punctuation,
          name:".",
          line:7.0,
          column:16.0,
          value:"."
        },
        {
          type: __GMLC_TokenType.Identifier,
          name:"FIRST",
          line:7.0,
          column:17.0,
          value:"FIRST"
        },
        {
          type: __GMLC_TokenType.Operator,
          name:"+",
          line:7.0,
          column:23.0,
          value:"+"
        },
        {
          type: __GMLC_TokenType.Number,
          name:"3",
          line:7.0,
          column:25.0,
          value:3.0
        }
      ]
    }
  },
  EnumVarNames:{
    BASE:[
      "FIRST",
      "SECOND"
    ],
    DERIVED:[
      "NEXT"
    ]
  },
  tokens:[
    {
      type: __GMLC_TokenType.Identifier,
      name:"DERIVED",
      line:10.0,
      column:1.0,
      value:"DERIVED"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:".",
      line:10.0,
      column:8.0,
      value:"."
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"NEXT",
      line:10.0,
      column:9.0,
      value:"NEXT"
    }
  ],
});
#endregion
#region Test 6: Enum Using a Macro Value
run_preprocessor_test("Enum Using a Macro Value",
@'#macro BASE_VALUE 10

enum VALUES {
    ONE = BASE_VALUE
}

VALUES.ONE',
{
  EnumVar:{
    VALUES:{
      ONE:[
        {
          type: __GMLC_TokenType.Identifier,
          name:"BASE_VALUE",
          line:4.0,
          column:11.0,
          value:"BASE_VALUE"
        }
      ]
    }
  },
  EnumVarNames:{
    VALUES:[
      "ONE"
    ]
  },
  tokens:[
    {
      type: __GMLC_TokenType.Identifier,
      name:"VALUES",
      line:7.0,
      column:1.0,
      value:"VALUES"
    },
    {
      type: __GMLC_TokenType.Punctuation,
      name:".",
      line:7.0,
      column:7.0,
      value:"."
    },
    {
      type: __GMLC_TokenType.Identifier,
      name:"ONE",
      line:7.0,
      column:8.0,
      value:"ONE"
    }
  ],
  MacroVar:{
    BASE_VALUE:[
      {
        type: __GMLC_TokenType.Number,
        name:"10",
        line:1.0,
        column:19.0,
        value:10.0
      }
    ]
  },
  MacroVarNames:[
    "BASE_VALUE"
  ]
});
#endregion
#region Test 7: Macro Containing Enum
run_preprocessor_test("Macro Containing Enum",
@'#macro TEST foo.bar
enum foo {
    bar
}

TEST',
{
  EnumVar:{
    foo:{
      bar:[
        {
          type: __GMLC_TokenType.Number,
          name:"\n",
          line:3.0,
          column:9.0,
          value:0.0
        }
      ]
    }
  },
  EnumVarNames:{
    foo:[
      "bar"
    ]
  },
  tokens:[
    {
      type: __GMLC_TokenType.Identifier,
      name:"TEST",
      line:6.0,
      column:1.0,
      value:"TEST"
    }
  ],
  MacroVar:{
    TEST:[
      {
        type: __GMLC_TokenType.Identifier,
        name:"foo",
        line:1.0,
        column:13.0,
        value:"foo"
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:".",
        line:1.0,
        column:16.0,
        value:"."
      },
      {
        type: __GMLC_TokenType.Identifier,
        name:"bar",
        line:1.0,
        column:17.0,
        value:"bar"
      }
    ]
  },
  MacroVarNames:[
    "TEST"
  ]
});
#endregion

// Additional tests for Multiline Macro, Basic Enum, Enums Built with Other Enums,
// and Enum Using a Macro Value would follow a similar structure.

log("\n\n\n")
}
//run_all_preprocessor_test();
#endregion

#region Parse unit tests
function run_parse_test(description, input, expected) {
	log($"Attempting Parser Test :: {description}")
	
	var tokenizer = new GML_Tokenizer();
	tokenizer.initialize(input);
	var tokens = tokenizer.parseAll();
	
	var preprocessor = new GML_PreProcessor();
	preprocessor.initialize(tokens);
	var tokens = preprocessor.parseAll();
	
	var parser = new GML_Parser();
	parser.initialize(tokens);
	var ast = parser.parseAll();
	
	__compare_results(description, ast, expected);
}
function run_all_parser_tests() {
log("~~~~~ Parser Unit Tests ~~~~~\n")
#region Macros and Enums
#region Test 1: Single Value Macro
run_parse_test("Single Value Macro",
@'#macro TOTAL_WEAPONS 10

TOTAL_WEAPONS',
{
  type:"__GMLC_NodeType.Script",
  statements:[
    {
      type:"__GMLC_NodeType.Literal",
      value:10.0,
      line:1.0,
      scope:"ScopeType.CONST"
    }
  ],
  MacroVar:{
    TOTAL_WEAPONS:[
      {
        type: __GMLC_TokenType.Number,
        name:"10",
        line:1.0,
        lineString:"#macro TOTAL_WEAPONS 10",
        column:22.0,
        value:10.0
      }
    ]
  },
  MacroVarNames:[
    "TOTAL_WEAPONS"
  ],
});
#endregion
#region Test 2: Statement Macro
run_parse_test("Statement Macro",
@'#macro INIT_LOGIC log("Starting")

INIT_LOGIC',
{
  type:"__GMLC_NodeType.Script",
  statements:[
    {
      type:"__GMLC_NodeType.CallExpression",
      line:1.0,
      callee:{
        type:"__GMLC_NodeType.Function",
        value: log,
        name:"log",
        line:1.0
      },
      arguments:[
        {
          type:"__GMLC_NodeType.Literal",
          value:"Starting",
          line:1.0,
          scope:"ScopeType.CONST"
        }
      ]
    }
  ],
  MacroVar:{
    INIT_LOGIC:[
      {
        type: __GMLC_TokenType.Function,
        name:"log",
        line:1.0,
        lineString:"#macro INIT_LOGIC log(\"Starting\")",
        column:19.0,
        value: log
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:"(",
        line:1.0,
        lineString:"#macro INIT_LOGIC log(\"Starting\")",
        column:22.0,
        value:"("
      },
      {
        type: __GMLC_TokenType.String,
        name:"\"Starting\"",
        line:1.0,
        lineString:"#macro INIT_LOGIC log(\"Starting\")",
        column:23.0,
        value:"Starting"
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:")",
        line:1.0,
        lineString:"#macro INIT_LOGIC log(\"Starting\")",
        column:33.0,
        value:")"
      }
    ]
  },
  MacroVarNames:[
    "INIT_LOGIC"
  ],
});
#endregion
#region Test 3: Multiline Macro
run_parse_test("Multiline Macro",
@'#macro HELLO show_debug_message("Hello" + \
string(player_name) + \
", how are you today?");

HELLO',
{
  type:"__GMLC_NodeType.Script",
  statements:[
    {
      type:"__GMLC_NodeType.CallExpression",
      line:1.0,
      callee:{
        type:"__GMLC_NodeType.Function",
        value:1146.0,
        name:"show_debug_message",
        line:1.0
      },
      arguments:[
        {
          type:"__GMLC_NodeType.BinaryExpression",
          line:2.0,
          operator:"+",
          left:{
            type:"__GMLC_NodeType.BinaryExpression",
            line:1.0,
            operator:"+",
            left:{
              type:"__GMLC_NodeType.Literal",
              value:"Hello",
              line:1.0,
              scope:"ScopeType.CONST"
            },
            right:{
              type:"__GMLC_NodeType.CallExpression",
              line:2.0,
              callee:{
                type:"__GMLC_NodeType.Function",
                value:264.0,
                name:"string",
                line:2.0
              },
              arguments:[
                {
                  type:"__GMLC_NodeType.Identifier",
                  value:"player_name",
                  line:2.0,
                }
              ]
            }
          },
          right:{
            type:"__GMLC_NodeType.Literal",
            value:", how are you today?",
            line:3.0,
            scope:"ScopeType.CONST"
          }
        }
      ]
    }
  ],
  MacroVar:{
    HELLO:[
      {
        type: __GMLC_TokenType.Function,
        name:"show_debug_message",
        line:1.0,
        lineString:"#macro HELLO show_debug_message(\"Hello\" + \\",
        column:14.0,
        value:1146.0
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:"(",
        line:1.0,
        lineString:"#macro HELLO show_debug_message(\"Hello\" + \\",
        column:32.0,
        value:"("
      },
      {
        type: __GMLC_TokenType.String,
        name:"\"Hello\"",
        line:1.0,
        lineString:"#macro HELLO show_debug_message(\"Hello\" + \\",
        column:33.0,
        value:"Hello"
      },
      {
        type: __GMLC_TokenType.Operator,
        name:"+",
        line:1.0,
        lineString:"#macro HELLO show_debug_message(\"Hello\" + \\",
        column:41.0,
        value:"+"
      },
      {
        type: __GMLC_TokenType.Function,
        name:"string",
        line:2.0,
        lineString:"string(player_name) + \\",
        column:1.0,
        value:264.0
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:"(",
        line:2.0,
        lineString:"string(player_name) + \\",
        column:7.0,
        value:"("
      },
      {
        type: __GMLC_TokenType.Identifier,
        name:"player_name",
        line:2.0,
        lineString:"string(player_name) + \\",
        column:8.0,
        value:"player_name"
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:")",
        line:2.0,
        lineString:"string(player_name) + \\",
        column:19.0,
        value:")"
      },
      {
        type: __GMLC_TokenType.Operator,
        name:"+",
        line:2.0,
        lineString:"string(player_name) + \\",
        column:21.0,
        value:"+"
      },
      {
        type: __GMLC_TokenType.String,
        name:"\", how are you today?\"",
        line:3.0,
        lineString:"\", how are you today?\");",
        column:1.0,
        value:", how are you today?"
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:")",
        line:3.0,
        lineString:"\", how are you today?\");",
        column:23.0,
        value:")"
      }
    ]
  },
  MacroVarNames:[
    "HELLO"
  ],
});
#endregion
#region Test 4: Basic Enum
run_parse_test("Basic Enum",
@'enum RAINBOW {
    RED,
    ORANGE,
    YELLOW,
    GREEN,
    BLUE,
    INDIGO,
    VIOLET
}

RAINBOW.GREEN',
{
  type:"__GMLC_NodeType.Script",
  statements:[
    {
      type:"__GMLC_NodeType.Literal",
      value:3.0,
      line:5.0,
      scope:"ScopeType.CONST"
    }
  ],
  EnumVar:{
    RAINBOW:{
      YELLOW:[
        {
          type: __GMLC_TokenType.Number,
          name:",",
          line:4.0,
          lineString:"    YELLOW,",
          column:11.0,
          value:2.0
        }
      ],
      GREEN:[
        {
          type: __GMLC_TokenType.Number,
          name:",",
          line:5.0,
          lineString:"    GREEN,",
          column:10.0,
          value:3.0
        }
      ],
      BLUE:[
        {
          type: __GMLC_TokenType.Number,
          name:",",
          line:6.0,
          lineString:"    BLUE,",
          column:9.0,
          value:4.0
        }
      ],
      INDIGO:[
        {
          type: __GMLC_TokenType.Number,
          name:",",
          line:7.0,
          lineString:"    INDIGO,",
          column:11.0,
          value:5.0
        }
      ],
      VIOLET:[
        {
          type: __GMLC_TokenType.Number,
          name:"\n",
          line:8.0,
          lineString:"    VIOLET",
          column:12.0,
          value:6.0
        }
      ],
      RED:[
        {
          type: __GMLC_TokenType.Number,
          name:",",
          line:2.0,
          lineString:"    RED,",
          column:8.0,
          value:0.0
        }
      ],
      ORANGE:[
        {
          type: __GMLC_TokenType.Number,
          name:",",
          line:3.0,
          lineString:"    ORANGE,",
          column:11.0,
          value:1.0
        }
      ]
    }
  },
  EnumVarNames:{
    RAINBOW:[
      "RED",
      "ORANGE",
      "YELLOW",
      "GREEN",
      "BLUE",
      "INDIGO",
      "VIOLET"
    ]
  },
});
#endregion
#region Test 5: Enums Built with Other Enums
run_parse_test("Enums Built with Other Enums",
@'enum BASE {
    FIRST = 1,
    SECOND
}

enum DERIVED {
    NEXT = BASE.FIRST + 3
}

DERIVED.NEXT',
{
  type:"__GMLC_NodeType.Script",
  statements:[
    {
      type:"__GMLC_NodeType.BinaryExpression",
      line:7.0,
      operator:"+",
      left:{
        type:"__GMLC_NodeType.Literal",
        value:1.0,
        line:2.0,
        scope:"ScopeType.CONST"
      },
      right:{
        type:"__GMLC_NodeType.Literal",
        value:3.0,
        line:7.0,
        scope:"ScopeType.CONST"
      }
    }
  ],
  EnumVar:{
    DERIVED:{
      NEXT:[
        {
          type: __GMLC_TokenType.Identifier,
          name:"BASE",
          line:7.0,
          lineString:"    NEXT = BASE.FIRST + 3",
          column:12.0,
          value:"BASE"
        },
        {
          type: __GMLC_TokenType.Punctuation,
          name:".",
          line:7.0,
          lineString:"    NEXT = BASE.FIRST + 3",
          column:16.0,
          value:"."
        },
        {
          type: __GMLC_TokenType.Identifier,
          name:"FIRST",
          line:7.0,
          lineString:"    NEXT = BASE.FIRST + 3",
          column:17.0,
          value:"FIRST"
        },
        {
          type: __GMLC_TokenType.Operator,
          name:"+",
          line:7.0,
          lineString:"    NEXT = BASE.FIRST + 3",
          column:23.0,
          value:"+"
        },
        {
          type: __GMLC_TokenType.Number,
          name:"3",
          line:7.0,
          lineString:"    NEXT = BASE.FIRST + 3",
          column:25.0,
          value:3.0
        }
      ]
    },
    BASE:{
      FIRST:[
        {
          type: __GMLC_TokenType.Number,
          name:"1",
          line:2.0,
          lineString:"    FIRST = 1,",
          column:13.0,
          value:1.0
        }
      ],
      SECOND:[
        {
          type: __GMLC_TokenType.Number,
          name:"\n",
          line:3.0,
          lineString:"    SECOND",
          column:12.0,
          value:1.0
        }
      ]
    }
  },
  EnumVarNames:{
    DERIVED:[
      "NEXT"
    ],
    BASE:[
      "FIRST",
      "SECOND"
    ]
  },
});
#endregion
#region Test 6: Enum Using a Macro Value
run_parse_test("Enum Using a Macro Value",
@'#macro BASE_VALUE 10

enum VALUES {
    ONE = BASE_VALUE
}

VALUES.ONE',
{
  type:"__GMLC_NodeType.Script",
  statements:[
    {
      type:"__GMLC_NodeType.Literal",
      value:10.0,
      line:1.0,
      scope:"ScopeType.CONST"
    }
  ],
  MacroVar:{
    BASE_VALUE:[
      {
        type: __GMLC_TokenType.Number,
        name:"10",
        line:1.0,
        lineString:"#macro BASE_VALUE 10",
        column:19.0,
        value:10.0
      }
    ]
  },
  MacroVarNames:[
    "BASE_VALUE"
  ],
  EnumVar:{
    VALUES:{
      ONE:[
        {
          type: __GMLC_TokenType.Identifier,
          name:"BASE_VALUE",
          line:4.0,
          lineString:"    ONE = BASE_VALUE",
          column:11.0,
          value:"BASE_VALUE"
        }
      ]
    }
  },
  EnumVarNames:{
    VALUES:[
      "ONE"
    ]
  },
});
#endregion
#region Test 7: Macro Containing Enum
run_parse_test("Macro Containing Enum",
@'#macro TEST foo.bar
enum foo {
    bar
}

TEST',
{
  type:"__GMLC_NodeType.Script",
  statements:[
    {
      type:"__GMLC_NodeType.Literal",
      value:0.0,
      line:3.0,
      scope:"ScopeType.CONST"
    }
  ],
  MacroVar:{
    TEST:[
      {
        type: __GMLC_TokenType.Identifier,
        name:"foo",
        line:1.0,
        lineString:"#macro TEST foo.bar",
        column:13.0,
        value:"foo"
      },
      {
        type: __GMLC_TokenType.Punctuation,
        name:".",
        line:1.0,
        lineString:"#macro TEST foo.bar",
        column:16.0,
        value:"."
      },
      {
        type: __GMLC_TokenType.Identifier,
        name:"bar",
        line:1.0,
        lineString:"#macro TEST foo.bar",
        column:17.0,
        value:"bar"
      }
    ]
  },
  MacroVarNames:[
    "TEST"
  ],
  EnumVar:{
    foo:{
      bar:[
        {
          type: __GMLC_TokenType.Number,
          name:"\n",
          line:3.0,
          lineString:"    bar",
          column:9.0,
          value:0.0
        }
      ]
    }
  },
  EnumVarNames:{
    foo:[
      "bar"
    ]
  },
});
#endregion
#endregion
#region Keyword Statements
#region Expression statement
run_parse_test("1 + 1;",
@'1+1',
{
	type: __GMLC_NodeType.Script,
	statements:[
	{
		operator:"+",
		type: __GMLC_NodeType.BinaryExpression,
		left:{
			type: __GMLC_NodeType.Literal,
			value:1.0
		},
		right:{
			type: __GMLC_NodeType.Literal,
			value:1.0
		}
	}]
}
);
#endregion
#region Postfix Addition
run_parse_test("x++",
@'x++',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.UpdateExpression,
      line:1.0,
      prefix:false,
      operator:"++",
      expr:{
        type: __GMLC_NodeType.Identifier,
        value:"x",
        line:1.0,
        scope: undefined
      }
    }
  ],
});
#endregion
#region Expression statement
run_parse_test("y = 1;",
@'y = 1;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.AssignmentExpression,
      line:1.0,
      operator:"=",
      left:{
        type: __GMLC_NodeType.Identifier,
        value:"y",
        line:1.0,
        scope: undefined
      },
      right:{
        type: __GMLC_NodeType.Literal,
        value:1.0,
        line:1.0,
        scope: ScopeType.CONST
      }
    }
  ],
});
#endregion
#region Expression statement
run_parse_test("h = a + b * c - (d & e % f div g)",
@'h = a + b * c - (d & e % f div g)',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.AssignmentExpression,
      line:1.0,
      operator:"=",
      left:{
        type: __GMLC_NodeType.Identifier,
        value:"h",
        line:1.0,
        scope: undefined
      },
      right:{
        type: __GMLC_NodeType.BinaryExpression,
        line:1.0,
        operator:"-",
        left:{
          type: __GMLC_NodeType.BinaryExpression,
          line:1.0,
          operator:"+",
          left:{
            type: __GMLC_NodeType.Identifier,
            value:"a",
            line:1.0,
            scope: undefined
          },
          right:{
            type: __GMLC_NodeType.BinaryExpression,
            line:1.0,
            operator:"*",
            left:{
              type: __GMLC_NodeType.Identifier,
              value:"b",
              line:1.0,
              scope: undefined
            },
            right:{
              type: __GMLC_NodeType.Identifier,
              value:"c",
              line:1.0,
              scope: undefined
            }
          }
        },
        right:{
          type: __GMLC_NodeType.BinaryExpression,
          line:1.0,
          operator:"&",
          left:{
            type: __GMLC_NodeType.Identifier,
            value:"d",
            line:1.0,
            scope: undefined
          },
          right:{
            type: __GMLC_NodeType.BinaryExpression,
            line:1.0,
            operator:"div",
            left:{
              type: __GMLC_NodeType.BinaryExpression,
              line:1.0,
              operator:"mod",
              left:{
                type: __GMLC_NodeType.Identifier,
                value:"e",
                line:1.0,
                scope: undefined
              },
              right:{
                type: __GMLC_NodeType.Identifier,
                value:"f",
                line:1.0,
                scope: undefined
              }
            },
            right:{
              type: __GMLC_NodeType.Identifier,
              value:"g",
              line:1.0,
              scope: undefined
            }
          }
        }
      }
    }
  ],
});
#endregion
#region If Statement Test
run_parse_test("if statement",
@'if (x > 0) {
	y = 1;
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.IfStatement,
      condition:{
        type: __GMLC_NodeType.BinaryExpression,
        line:1.0,
        operator:">",
        left:{
          type: __GMLC_NodeType.Identifier,
          value:"x",
          line:1.0,
          scope: undefined
        },
        right:{
          type: __GMLC_NodeType.Literal,
          value:0.0,
          line:1.0,
          scope: ScopeType.CONST
        }
      },
      line:1.0,
      consequent:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.AssignmentExpression,
            line:2.0,
            operator:"=",
            left:{
              type: __GMLC_NodeType.Identifier,
              value:"y",
              line:2.0,
              scope: undefined
            },
            right:{
              type: __GMLC_NodeType.Literal,
              value:1.0,
              line:2.0,
              scope: ScopeType.CONST
            }
          }
        ]
      },
      alternate: undefined
    }
  ],
});
#endregion
#region If/Else Statement Test
run_parse_test("if/else statement",
@'if (x > 0) {
	y = 1;
} else {
	y = 2;
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.IfStatement,
      condition:{
        type: __GMLC_NodeType.BinaryExpression,
        line:1.0,
        operator:">",
        left:{
          type: __GMLC_NodeType.Identifier,
          value:"x",
          line:1.0,
          scope: undefined
        },
        right:{
          type: __GMLC_NodeType.Literal,
          value:0.0,
          line:1.0,
          scope: ScopeType.CONST
        }
      },
      line:1.0,
      consequent:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.AssignmentExpression,
            line:2.0,
            operator:"=",
            left:{
              type: __GMLC_NodeType.Identifier,
              value:"y",
              line:2.0,
              scope: undefined
            },
            right:{
              type: __GMLC_NodeType.Literal,
              value:1.0,
              line:2.0,
              scope: ScopeType.CONST
            }
          }
        ]
      },
      alternate:{
        type: __GMLC_NodeType.BlockStatement,
        line:3.0,
        statements:[
          {
            type: __GMLC_NodeType.AssignmentExpression,
            line:4.0,
            operator:"=",
            left:{
              type: __GMLC_NodeType.Identifier,
              value:"y",
              line:4.0,
              scope: undefined
            },
            right:{
              type: __GMLC_NodeType.Literal,
              value:2.0,
              line:4.0,
              scope: ScopeType.CONST
            }
          }
        ]
      }
    }
  ],
});
#endregion
#region For Statement Test
run_parse_test("for statement",
@'for (var i = 0; i < 10; i++) {
	print(i);
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.ForStatement,
      condition:{
        right:{
          type: __GMLC_NodeType.Literal,
          line:1.0,
          value:10.0,
          scope: ScopeType.CONST
        },
        type: __GMLC_NodeType.BinaryExpression,
        line:1.0,
        operator:"<",
        left:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"i",
          scope: ScopeType.LOCAL
        }
      },
      codeBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.CallExpression,
            line:2.0,
            arguments:[
              {
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"i",
                scope: ScopeType.LOCAL
              }
            ],
            callee:{
              type: __GMLC_NodeType.Identifier,
              line:2.0,
              value:"print",
            }
          }
        ]
      },
      line:1.0,
      initialization:{
        type: __GMLC_NodeType.VariableDeclarationList,
        line:1.0,
        statements:{
          type: __GMLC_NodeType.BlockStatement,
          line:1.0,
          statements:[
            {
              expr:{
                type: __GMLC_NodeType.Literal,
                line:1.0,
                value:0.0,
                scope: ScopeType.CONST
              },
              type: __GMLC_NodeType.VariableDeclaration,
              line:1.0,
              identifier:"i",
              scope: ScopeType.LOCAL
            }
          ]
        }
      },
      increment:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"i",
          scope: ScopeType.LOCAL
        },
        type: __GMLC_NodeType.UpdateExpression,
        line:1.0,
        prefix:false,
        operator:"++"
      }
    }
  ],
  LocalVarNames:[
    "i"
  ]
}
);
#endregion
#region While Statement Test
run_parse_test("while statement",
@'while (x < 10) {
	x += 1;
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.WhileStatement,
      condition:{
        type: __GMLC_NodeType.BinaryExpression,
        line:1.0,
        operator:"<",
        left:{
          type: __GMLC_NodeType.Identifier,
          value:"x",
          line:1.0,
          scope: undefined
        },
        right:{
          type: __GMLC_NodeType.Literal,
          value:10.0,
          line:1.0,
          scope: ScopeType.CONST
        }
      },
      codeBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.AssignmentExpression,
            line:2.0,
            operator:"+=",
            left:{
              type: __GMLC_NodeType.Identifier,
              value:"x",
              line:2.0,
              scope: undefined
            },
            right:{
              type: __GMLC_NodeType.Literal,
              value:1.0,
              line:2.0,
              scope: ScopeType.CONST
            }
          }
        ]
      },
      line:1.0
    }
  ],
}
);
#endregion
#region Try-Catch-Finally Test
run_parse_test("try-catch-finally statement",
@'try {
	riskyOperation();
}
catch (e) {
	handleError(e);
}
finally {
	cleanup();
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.TryStatement,
      tryBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.CallExpression,
            line:2.0,
            callee:{
              type: __GMLC_NodeType.Identifier,
              value:"riskyOperation",
              line:2.0,
              scope: undefined
            },
            arguments:[
            ]
          }
        ]
      },
      exceptionVar:"e",
      line:1.0,
      catchBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:4.0,
        statements:[
          {
            type: __GMLC_NodeType.CallExpression,
            line:5.0,
            callee:{
              type: __GMLC_NodeType.Identifier,
              value:"handleError",
              line:5.0,
              scope: undefined
            },
            arguments:[
              {
                type: __GMLC_NodeType.Identifier,
                value:"e",
                line:5.0,
                scope: ScopeType.LOCAL
              }
            ]
          }
        ]
      },
      finallyBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:7.0,
        statements:[
          {
            type: __GMLC_NodeType.CallExpression,
            line:8.0,
            callee:{
              type: __GMLC_NodeType.Identifier,
              value:"cleanup",
              line:8.0,
              scope: undefined
            },
            arguments:[
            ]
          }
        ]
      }
    }
  ],
  LocalVarNames:[
    "e"
  ]
}
);
#endregion
#region Repeat Statement Test
run_parse_test("repeat statement",
@'repeat (10) {
	x += 1;
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.RepeatStatement,
      condition:{
        type: __GMLC_NodeType.Literal,
        value:10.0,
        line:1.0,
        scope: ScopeType.CONST
      },
      codeBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.AssignmentExpression,
            line:2.0,
            operator:"+=",
            left:{
              type: __GMLC_NodeType.Identifier,
              value:"x",
              line:2.0,
              scope: undefined
            },
            right:{
              type: __GMLC_NodeType.Literal,
              value:1.0,
              line:2.0,
              scope: ScopeType.CONST
            }
          }
        ]
      },
      line:1.0
    }
  ],
});
#endregion
#region Do/Until Statement Test
run_parse_test("do/until statement",
@'do {
	x += 1;
}
until (x >= 10);',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.DoUntillStatement,
      condition:{
        type: __GMLC_NodeType.BinaryExpression,
        line:4.0,
        operator:">=",
        left:{
          type: __GMLC_NodeType.Identifier,
          value:"x",
          line:4.0,
          scope: undefined
        },
        right:{
          type: __GMLC_NodeType.Literal,
          value:10.0,
          line:4.0,
          scope: ScopeType.CONST
        }
      },
      codeBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.AssignmentExpression,
            line:2.0,
            operator:"+=",
            left:{
              type: __GMLC_NodeType.Identifier,
              value:"x",
              line:2.0,
              scope: undefined
            },
            right:{
              type: __GMLC_NodeType.Literal,
              value:1.0,
              line:2.0,
              scope: ScopeType.CONST
            }
          }
        ]
      },
      line:1.0
    }
  ],
});
#endregion
#region Switch Statement Test
run_parse_test("switch statement",
@'switch (x) {
	case 1:
		print("one");
	break;
	case 2:
		print("two");
	break;
	default:
		print("other");
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.SwitchStatement,
      line:1.0,
      switchExpression:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      cases:[
        {
          label:{
            type: __GMLC_NodeType.Literal,
            line:2.0,
            value:1.0,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.CaseExpression,
          codeBlock:{
            type: __GMLC_NodeType.Base,
            line:"BlockStatement"
          },
          line:2.0
        },
        {
          label:{
            type: __GMLC_NodeType.Literal,
            line:5.0,
            value:2.0,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.CaseExpression,
          codeBlock:{
            type: __GMLC_NodeType.Base,
            line:"BlockStatement"
          },
          line:5.0
        },
        {
          type: __GMLC_NodeType.CaseDefault,
          codeBlock:{
            type: __GMLC_NodeType.Base,
            line:"BlockStatement"
          },
          line:1.0
        }
      ]
    }
  ],
}
);
run_parse_test("switch statement : stacked cases",
@'switch (expr) {
	case 1:
	case 2:
		foo=12
	break
	default:
		bar=3;
	break;
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.SwitchStatement,
      line:1.0,
      switchExpression:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"expr",
      },
      cases:[
        {
          label:{
            type: __GMLC_NodeType.Literal,
            line:2.0,
            value:1.0,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.CaseExpression,
          codeBlock:{
            type: __GMLC_NodeType.Base,
            line:"BlockStatement"
          },
          line:2.0
        },
        {
          label:{
            type: __GMLC_NodeType.Literal,
            line:3.0,
            value:2.0,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.CaseExpression,
          codeBlock:{
            type: __GMLC_NodeType.Base,
            line:"BlockStatement"
          },
          line:3.0
        },
        {
          type: __GMLC_NodeType.CaseDefault,
          codeBlock:{
            type: __GMLC_NodeType.Base,
            line:"BlockStatement"
          },
          line:1.0
        }
      ]
    }
  ],
}
);

run_parse_test("switch statement : arbitrary (unneeded) brackets",
@'switch (expr) {
	case 1:{
		_one=1;
	break}
	case 2:{
		_two=2;
	}break;
	default:
		_default=3;
	break;
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.SwitchStatement,
      line:1.0,
      switchExpression:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"expr",
      },
      cases:[
        {
          label:{
            type: __GMLC_NodeType.Literal,
            line:2.0,
            value:1.0,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.CaseExpression,
          codeBlock:{
            type: __GMLC_NodeType.Base,
            line:"BlockStatement"
          },
          line:2.0
        },
        {
          label:{
            type: __GMLC_NodeType.Literal,
            line:5.0,
            value:2.0,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.CaseExpression,
          codeBlock:{
            type: __GMLC_NodeType.Base,
            line:"BlockStatement"
          },
          line:5.0
        },
        {
          type: __GMLC_NodeType.CaseDefault,
          codeBlock:{
            type: __GMLC_NodeType.Base,
            line:"BlockStatement"
          },
          line:1.0
        }
      ]
    }
  ],
}
);

run_parse_test("switch statement : default stacked",
@'switch (expr) {
	case 1:
	case 2:
	default:
		should = execute;
	break;
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.SwitchStatement,
      line:1.0,
      switchExpression:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"expr",
      },
      cases:[
        {
          label:{
            type: __GMLC_NodeType.Literal,
            line:2.0,
            value:1.0,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.CaseExpression,
          codeBlock:{
            type: __GMLC_NodeType.Base,
            line:"BlockStatement"
          },
          line:2.0
        },
        {
          label:{
            type: __GMLC_NodeType.Literal,
            line:3.0,
            value:2.0,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.CaseExpression,
          codeBlock:{
            type: __GMLC_NodeType.Base,
            line:"BlockStatement"
          },
          line:3.0
        },
        {
          type: __GMLC_NodeType.CaseDefault,
          codeBlock:{
            type: __GMLC_NodeType.Base,
            line:"BlockStatement"
          },
          line:1.0
        }
      ]
    }
  ],
}
);
#endregion
#region With Statement Test
run_parse_test("with statement",
@'with (obj_Player) {
	x = 100;
	y = 200;
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.WithStatement,
      condition:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"obj_Player",
      },
      codeBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            left:{
              type: __GMLC_NodeType.Identifier,
              line:2.0,
              value:"x",
            },
            type: __GMLC_NodeType.AssignmentExpression,
            right:{
              type: __GMLC_NodeType.Literal,
              line:2.0,
              value:100.0,
              scope: ScopeType.CONST
            },
            line:2.0,
            operator:"="
          },
          {
            left:{
              type: __GMLC_NodeType.Identifier,
              line:3.0,
              value:"y",
            },
            type: __GMLC_NodeType.AssignmentExpression,
            right:{
              type: __GMLC_NodeType.Literal,
              line:3.0,
              value:200.0,
              scope: ScopeType.CONST
            },
            line:3.0,
            operator:"="
          }
        ]
      },
      line:1.0
    }
  ],
}
);
#endregion
#region Mixed Test 1: If-Else with Nested For Loop
run_parse_test("if-else with nested for loop",
@'if (x > 0) {
	for (var i = 0; i < x; i++) {
		print(i);
	}
}
else {
	print("x is non-positive");
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.IfStatement,
      condition:{
        right:{
          type: __GMLC_NodeType.Literal,
          line:1.0,
          value:0.0,
          scope: ScopeType.CONST
        },
        type: __GMLC_NodeType.BinaryExpression,
        line:1.0,
        operator:">",
        left:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"x",
          scope: undefined
        }
      },
      line:1.0,
      consequent:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.ForStatement,
            condition:{
              right:{
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"x",
                scope: undefined
              },
              type: __GMLC_NodeType.BinaryExpression,
              line:2.0,
              operator:"<",
              left:{
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"i",
                scope: ScopeType.LOCAL
              }
            },
            codeBlock:{
              type: __GMLC_NodeType.BlockStatement,
              line:2.0,
              statements:[
                {
                  type: __GMLC_NodeType.CallExpression,
                  line:3.0,
                  arguments:[
                    {
                      type: __GMLC_NodeType.Identifier,
                      line:3.0,
                      value:"i",
                      scope: ScopeType.LOCAL
                    }
                  ],
                  callee:{
                    type: __GMLC_NodeType.Identifier,
                    line:3.0,
                    value:"print",
                    scope: undefined
                  }
                }
              ]
            },
            line:2.0,
            initialization:{
              type: __GMLC_NodeType.VariableDeclarationList,
              line:2.0,
              statements:{
                type: __GMLC_NodeType.BlockStatement,
                line:2.0,
                statements:[
                  {
                    expr:{
                      type: __GMLC_NodeType.Literal,
                      line:2.0,
                      value:0.0,
                      scope: ScopeType.CONST
                    },
                    type: __GMLC_NodeType.VariableDeclaration,
                    line:2.0,
                    identifier:"i",
                    scope: ScopeType.LOCAL
                  }
                ]
              }
            },
            increment:{
              expr:{
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"i",
                scope: ScopeType.LOCAL
              },
              type: __GMLC_NodeType.UpdateExpression,
              line:2.0,
              prefix:false,
              operator:"++"
            }
          }
        ]
      },
      alternate:{
        type: __GMLC_NodeType.BlockStatement,
        line:6.0,
        statements:[
          {
            type: __GMLC_NodeType.CallExpression,
            line:7.0,
            arguments:[
              {
                type: __GMLC_NodeType.Literal,
                line:7.0,
                value:"x is non-positive",
                scope: ScopeType.CONST
              }
            ],
            callee:{
              type: __GMLC_NodeType.Identifier,
              line:7.0,
              value:"print",
              scope: undefined
            }
          }
        ]
      }
    }
  ],
  LocalVarNames:[
    "i"
  ]
}
);
#endregion
#region Mixed Test 2: Switch Inside a While Loop
run_parse_test("switch inside while loop",
@'while (x < 10) {
	switch (x) {
		case 1:
			x += 2;
		break;
		default:
			x += 1;
	}
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.WhileStatement,
      condition:{
        left:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"x",
        },
        type: __GMLC_NodeType.BinaryExpression,
        right:{
          type: __GMLC_NodeType.Literal,
          line:1.0,
          value:10.0,
          scope: ScopeType.CONST
        },
        line:1.0,
        operator:"<"
      },
      codeBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.SwitchStatement,
            line:2.0,
            switchExpression:{
              type: __GMLC_NodeType.Identifier,
              line:2.0,
              value:"x",
            },
            cases:[
              {
                label:{
                  type: __GMLC_NodeType.Literal,
                  line:3.0,
                  value:1.0,
                  scope: ScopeType.CONST
                },
                type: __GMLC_NodeType.CaseExpression,
                codeBlock:{
                  type: __GMLC_NodeType.Base,
                  line:"BlockStatement"
                },
                line:3.0
              },
              {
                type: __GMLC_NodeType.CaseDefault,
                codeBlock:{
                  type: __GMLC_NodeType.Base,
                  line:"BlockStatement"
                },
                line:2.0
              }
            ]
          }
        ]
      },
      line:1.0
    }
  ],
}
);
#endregion
#region Mixed Test 3: Nested If with Do-Until Loop
run_parse_test("nested if with do-until loop",
@'if (x > 0) {
	do {
		x -= 1; print(x);
	}
	until (x == 0);
}
else {
	print("x was not positive");
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.IfStatement,
      condition:{
        left:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"x",
        },
        type: __GMLC_NodeType.BinaryExpression,
        right:{
          type: __GMLC_NodeType.Literal,
          line:1.0,
          value:0.0,
          scope: ScopeType.CONST
        },
        line:1.0,
        operator:">"
      },
      line:1.0,
      consequent:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.DoUntillStatement,
            condition:{
              left:{
                type: __GMLC_NodeType.Identifier,
                line:5.0,
                value:"x",
              },
              type: __GMLC_NodeType.BinaryExpression,
              right:{
                type: __GMLC_NodeType.Literal,
                line:5.0,
                value:0.0,
                scope: ScopeType.CONST
              },
              line:5.0,
              operator:"=="
            },
            codeBlock:{
              type: __GMLC_NodeType.BlockStatement,
              line:2.0,
              statements:[
                {
                  left:{
                    type: __GMLC_NodeType.Identifier,
                    line:3.0,
                    value:"x",
                  },
                  type: __GMLC_NodeType.AssignmentExpression,
                  right:{
                    type: __GMLC_NodeType.Literal,
                    line:3.0,
                    value:1.0,
                    scope: ScopeType.CONST
                  },
                  line:3.0,
                  operator:"-="
                },
                {
                  type: __GMLC_NodeType.CallExpression,
                  line:3.0,
                  arguments:[
                    {
                      type: __GMLC_NodeType.Identifier,
                      line:3.0,
                      value:"x",
                    }
                  ],
                  callee:{
                    type: __GMLC_NodeType.Identifier,
                    line:3.0,
                    value:"print",
                  }
                }
              ]
            },
            line:2.0
          }
        ]
      },
      alternate:{
        type: __GMLC_NodeType.BlockStatement,
        line:7.0,
        statements:[
          {
            type: __GMLC_NodeType.CallExpression,
            line:8.0,
            arguments:[
              {
                type: __GMLC_NodeType.Literal,
                line:8.0,
                value:"x was not positive",
                scope: ScopeType.CONST
              }
            ],
            callee:{
              type: __GMLC_NodeType.Identifier,
              line:8.0,
              value:"print",
            }
          }
        ]
      }
    }
  ],
}
);
#endregion
#region Double For Loop Test
run_parse_test("double for loop",
@'for (var i = 0; i < 5; i++) {
	for (var j = 0; j < 5; j++) {
		print(i * j);
	}
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.ForStatement,
      condition:{
        right:{
          type: __GMLC_NodeType.Literal,
          line:1.0,
          value:5.0,
          scope: ScopeType.CONST
        },
        type: __GMLC_NodeType.BinaryExpression,
        line:1.0,
        operator:"<",
        left:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"i",
          scope: ScopeType.LOCAL
        }
      },
      codeBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.ForStatement,
            condition:{
              right:{
                type: __GMLC_NodeType.Literal,
                line:2.0,
                value:5.0,
                scope: ScopeType.CONST
              },
              type: __GMLC_NodeType.BinaryExpression,
              line:2.0,
              operator:"<",
              left:{
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"j",
                scope: ScopeType.LOCAL
              }
            },
            codeBlock:{
              type: __GMLC_NodeType.BlockStatement,
              line:2.0,
              statements:[
                {
                  type: __GMLC_NodeType.CallExpression,
                  line:3.0,
                  arguments:[
                    {
                      right:{
                        type: __GMLC_NodeType.Identifier,
                        line:3.0,
                        value:"j",
                        scope: ScopeType.LOCAL
                      },
                      type: __GMLC_NodeType.BinaryExpression,
                      line:3.0,
                      operator:"*",
                      left:{
                        type: __GMLC_NodeType.Identifier,
                        line:3.0,
                        value:"i",
                        scope: ScopeType.LOCAL
                      }
                    }
                  ],
                  callee:{
                    type: __GMLC_NodeType.Identifier,
                    line:3.0,
                    value:"print",
                    scope: undefined
                  }
                }
              ]
            },
            line:2.0,
            initialization:{
              type: __GMLC_NodeType.VariableDeclarationList,
              line:2.0,
              statements:{
                type: __GMLC_NodeType.BlockStatement,
                line:2.0,
                statements:[
                  {
                    expr:{
                      type: __GMLC_NodeType.Literal,
                      line:2.0,
                      value:0.0,
                      scope: ScopeType.CONST
                    },
                    type: __GMLC_NodeType.VariableDeclaration,
                    line:2.0,
                    identifier:"j",
                    scope: ScopeType.LOCAL
                  }
                ]
              }
            },
            increment:{
              expr:{
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"j",
                scope: ScopeType.LOCAL
              },
              type: __GMLC_NodeType.UpdateExpression,
              line:2.0,
              prefix:false,
              operator:"++"
            }
          }
        ]
      },
      line:1.0,
      initialization:{
        type: __GMLC_NodeType.VariableDeclarationList,
        line:1.0,
        statements:{
          type: __GMLC_NodeType.BlockStatement,
          line:1.0,
          statements:[
            {
              expr:{
                type: __GMLC_NodeType.Literal,
                line:1.0,
                value:0.0,
                scope: ScopeType.CONST
              },
              type: __GMLC_NodeType.VariableDeclaration,
              line:1.0,
              identifier:"i",
              scope: ScopeType.LOCAL
            }
          ]
        }
      },
      increment:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"i",
          scope: ScopeType.LOCAL
        },
        type: __GMLC_NodeType.UpdateExpression,
        line:1.0,
        prefix:false,
        operator:"++"
      }
    }
  ],
  LocalVarNames:[
    "i",
    "j"
  ]
}
);
#endregion
#region Double Repeat Loop Test
run_parse_test("double repeat loop",
@'repeat (5) {
	repeat (5) {
		print("nested repeat");
	}
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.RepeatStatement,
      condition:{
        type: __GMLC_NodeType.Literal,
        line:1.0,
        value:5.0,
        scope: ScopeType.CONST
      },
      codeBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.RepeatStatement,
            condition:{
              type: __GMLC_NodeType.Literal,
              line:2.0,
              value:5.0,
              scope: ScopeType.CONST
            },
            codeBlock:{
              type: __GMLC_NodeType.BlockStatement,
              line:2.0,
              statements:[
                {
                  type: __GMLC_NodeType.CallExpression,
                  line:3.0,
                  arguments:[
                    {
                      type: __GMLC_NodeType.Literal,
                      line:3.0,
                      value:"nested repeat",
                      scope: ScopeType.CONST
                    }
                  ],
                  callee:{
                    type: __GMLC_NodeType.Identifier,
                    line:3.0,
                    value:"print",
                  }
                }
              ]
            },
            line:2.0
          }
        ]
      },
      line:1.0
    }
  ],
}
);
#endregion
#region Try-Catch-Finally with Nested Switch
run_parse_test("try-catch-finally with nested switch",
@'try {
	switch(x) {
		case 1:
			print("one");
		break;
	}
}
catch (e) {
	print(e);
}
finally {
	print("done");
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.TryStatement,
      line:1.0,
      tryBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.SwitchStatement,
            line:2.0,
            switchExpression:{
              type: __GMLC_NodeType.Identifier,
              line:2.0,
              value:"x",
            },
            cases:[
              {
                label:{
                  type: __GMLC_NodeType.Literal,
                  line:3.0,
                  value:1.0,
                  scope: ScopeType.CONST
                },
                type: __GMLC_NodeType.CaseExpression,
                codeBlock:{
                  type: __GMLC_NodeType.Base,
                  line:"BlockStatement"
                },
                line:3.0
              }
            ]
          }
        ]
      },
      exceptionVar:"e",
      catchBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:8.0,
        statements:[
          {
            type: __GMLC_NodeType.CallExpression,
            line:9.0,
            arguments:[
              {
                type: __GMLC_NodeType.Identifier,
                line:9.0,
                value:"e",
                scope: ScopeType.LOCAL
              }
            ],
            callee:{
              type: __GMLC_NodeType.Identifier,
              line:9.0,
              value:"print",
            }
          }
        ]
      },
      finallyBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:11.0,
        statements:[
          {
            type: __GMLC_NodeType.CallExpression,
            line:12.0,
            arguments:[
              {
                type: __GMLC_NodeType.Literal,
                line:12.0,
                value:"done",
                scope: ScopeType.CONST
              }
            ],
            callee:{
              type: __GMLC_NodeType.Identifier,
              line:12.0,
              value:"print",
            }
          }
        ]
      }
    }
  ],
  LocalVarNames:[
    "e"
  ]
}
);
#endregion
#region Function Declaration with Nested Loops and Conditional
run_parse_test("function declaration with nested loops and conditional",
@'function calculate(x) {
	for (var i = 0; i < x; i++) {
		if (i % 2 == 0) {
			print(i);
		}
	}
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
  ],
  GlobalVar:{
    "GMLC@calculate":{
      type: __GMLC_NodeType.FunctionDeclaration,
      name:"GMLC@calculate",
      line:1.0,
      parameters:[
        {
          expr:{
            type: __GMLC_NodeType.Literal,
            line:1.0,
            value: undefined,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.VariableDeclaration,
          line:1.0,
          identifier:"x",
          scope: ScopeType.LOCAL
        }
      ],
      body:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.ForStatement,
            condition:{
              right:{
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"x",
                scope: ScopeType.LOCAL
              },
              type: __GMLC_NodeType.BinaryExpression,
              line:2.0,
              operator:"<",
              left:{
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"i",
                scope: ScopeType.LOCAL
              }
            },
            codeBlock:{
              type: __GMLC_NodeType.BlockStatement,
              line:2.0,
              statements:[
                {
                  type: __GMLC_NodeType.IfStatement,
                  condition:{
                    right:{
                      type: __GMLC_NodeType.Literal,
                      line:3.0,
                      value:0.0,
                      scope: ScopeType.CONST
                    },
                    type: __GMLC_NodeType.BinaryExpression,
                    line:3.0,
                    operator:"==",
                    left:{
                      right:{
                        type: __GMLC_NodeType.Literal,
                        line:3.0,
                        value:2.0,
                        scope: ScopeType.CONST
                      },
                      type: __GMLC_NodeType.BinaryExpression,
                      line:3.0,
                      operator:"mod",
                      left:{
                        type: __GMLC_NodeType.Identifier,
                        line:3.0,
                        value:"i",
                        scope: ScopeType.LOCAL
                      }
                    }
                  },
                  line:3.0,
                  consequent:{
                    type: __GMLC_NodeType.BlockStatement,
                    line:3.0,
                    statements:[
                      {
                        type: __GMLC_NodeType.CallExpression,
                        line:4.0,
                        arguments:[
                          {
                            type: __GMLC_NodeType.Identifier,
                            line:4.0,
                            value:"i",
                            scope: ScopeType.LOCAL
                          }
                        ],
                        callee:{
                          type: __GMLC_NodeType.Identifier,
                          line:4.0,
                          value:"print",
                          scope: undefined
                        }
                      }
                    ]
                  },
                  alternate: undefined
                }
              ]
            },
            line:2.0,
            initialization:{
              type: __GMLC_NodeType.VariableDeclarationList,
              line:2.0,
              statements:{
                type: __GMLC_NodeType.BlockStatement,
                line:2.0,
                statements:[
                  {
                    expr:{
                      type: __GMLC_NodeType.Literal,
                      line:2.0,
                      value:0.0,
                      scope: ScopeType.CONST
                    },
                    type: __GMLC_NodeType.VariableDeclaration,
                    line:2.0,
                    identifier:"i",
                    scope: ScopeType.LOCAL
                  }
                ]
              }
            },
            increment:{
              expr:{
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"i",
                scope: ScopeType.LOCAL
              },
              type: __GMLC_NodeType.UpdateExpression,
              line:2.0,
              prefix:false,
              operator:"++"
            }
          }
        ]
      },
      LocalVarNames:[
        "x",
        "i"
      ],
    }
  },
  GlobalVarNames:[
    "GMLC@calculate"
  ],
}
);
#endregion
#region Complex Expression Evaluation
run_parse_test("complex expression evaluation",
@'var result = ((x + y) * (x - y)) / 2;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:1.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            expr:{
              right:{
                type: __GMLC_NodeType.Literal,
                line:1.0,
                value:2.0,
                scope: ScopeType.CONST
              },
              type: __GMLC_NodeType.BinaryExpression,
              line:1.0,
              operator:"\/",
              left:{
                right:{
                  right:{
                    type: __GMLC_NodeType.Identifier,
                    line:1.0,
                    value:"y",
                    scope: undefined
                  },
                  type: __GMLC_NodeType.BinaryExpression,
                  line:1.0,
                  operator:"-",
                  left:{
                    type: __GMLC_NodeType.Identifier,
                    line:1.0,
                    value:"x",
                    scope: undefined
                  }
                },
                type: __GMLC_NodeType.BinaryExpression,
                line:1.0,
                operator:"*",
                left:{
                  right:{
                    type: __GMLC_NodeType.Identifier,
                    line:1.0,
                    value:"y",
                    scope: undefined
                  },
                  type: __GMLC_NodeType.BinaryExpression,
                  line:1.0,
                  operator:"+",
                  left:{
                    type: __GMLC_NodeType.Identifier,
                    line:1.0,
                    value:"x",
                    scope: undefined
                  }
                }
              }
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:1.0,
            identifier:"result",
            scope: ScopeType.LOCAL
          }
        ]
      }
    }
  ],
  LocalVarNames:[
    "result"
  ]
}
);
#endregion
#region Complex Control Flow with Function Calls
run_parse_test("complex control flow with function calls",
@'var x = 0;
while (x < 10) {
	x++;
	print(x);
	if (x == 5) {
		break;
	}
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:1.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.Literal,
              line:1.0,
              value:0.0,
              scope: ScopeType.CONST
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:1.0,
            identifier:"x",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      type: __GMLC_NodeType.WhileStatement,
      condition:{
        right:{
          type: __GMLC_NodeType.Literal,
          line:2.0,
          value:10.0,
          scope: ScopeType.CONST
        },
        type: __GMLC_NodeType.BinaryExpression,
        line:2.0,
        operator:"<",
        left:{
          type: __GMLC_NodeType.Identifier,
          line:2.0,
          value:"x",
          scope: ScopeType.LOCAL
        }
      },
      codeBlock:{
        type: __GMLC_NodeType.BlockStatement,
        line:2.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.Identifier,
              line:3.0,
              value:"x",
              scope: ScopeType.LOCAL
            },
            type: __GMLC_NodeType.UpdateExpression,
            line:3.0,
            prefix:false,
            operator:"++"
          },
          {
            type: __GMLC_NodeType.CallExpression,
            line:4.0,
            arguments:[
              {
                type: __GMLC_NodeType.Identifier,
                line:4.0,
                value:"x",
                scope: ScopeType.LOCAL
              }
            ],
            callee:{
              type: __GMLC_NodeType.Identifier,
              line:4.0,
              value:"print",
              scope: undefined
            }
          },
          {
            type: __GMLC_NodeType.IfStatement,
            condition:{
              right:{
                type: __GMLC_NodeType.Literal,
                line:5.0,
                value:5.0,
                scope: ScopeType.CONST
              },
              type: __GMLC_NodeType.BinaryExpression,
              line:5.0,
              operator:"==",
              left:{
                type: __GMLC_NodeType.Identifier,
                line:5.0,
                value:"x",
                scope: ScopeType.LOCAL
              }
            },
            line:5.0,
            consequent:{
              type: __GMLC_NodeType.BlockStatement,
              line:5.0,
              statements:[
                {
                  type: __GMLC_NodeType.BreakStatement,
                  line:6.0
                }
              ]
            },
            alternate: undefined
          }
        ]
      },
      line:2.0
    }
  ],
  LocalVarNames:[
    "x"
  ]
}
);
#endregion
#endregion
#region Expressions and Operators
#region 1. Test for parseAssignmentExpression
run_parse_test("parseAssignmentExpression",
@'x = y + 1;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.AssignmentExpression,
      right:{
        left:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"y",
        },
        type: __GMLC_NodeType.BinaryExpression,
        right:{
          type: __GMLC_NodeType.Literal,
          line:1.0,
          value:1.0,
          scope: ScopeType.CONST
        },
        line:1.0,
        operator:"+"
      },
      line:1.0,
      operator:"="
    }
  ],
}
);
#endregion
#region 2. Test for parseLogicalOrExpression
run_parse_test("parseLogicalOrExpression",
@'a || b;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"a",
      },
      type: __GMLC_NodeType.LogicalExpression,
      right:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"b",
      },
      line:1.0,
      operator:"||"
    }
  ],
}
);
#endregion
#region 3. Test for parseLogicalAndExpression
run_parse_test("parseLogicalAndExpression",
@'x && y;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.LogicalExpression,
      right:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"y",
      },
      line:1.0,
      operator:"&&"
    }
  ],
}
);
#endregion
#region 4. Test for parseBitwiseOrExpression
run_parse_test("parseBitwiseOrExpression",
@'x | y;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.BinaryExpression,
      right:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"y",
      },
      line:1.0,
      operator:"|"
    }
  ],
}
);
#endregion
#region 5. Test for parseBitwiseXorExpression
run_parse_test("parseBitwiseXorExpression",
@'x ^ y;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.BinaryExpression,
      right:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"y",
      },
      line:1.0,
      operator:"^"
    }
  ],
}
);
#endregion
#region 6. Test for parseBitwiseAndExpression
run_parse_test("parseBitwiseAndExpression",
@'x & y;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.BinaryExpression,
      right:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"y",
      },
      line:1.0,
      operator:"&"
    }
  ],
}
);
#endregion
#region 7. Test for parseEqualityExpression
run_parse_test("parseEqualityExpression",
@'x == y;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.BinaryExpression,
      right:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"y",
      },
      line:1.0,
      operator:"=="
    }
  ],
}
);
#endregion
#region 8. Test for parseRelationalExpression
run_parse_test("parseRelationalExpression",
@'x < y;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.BinaryExpression,
      right:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"y",
      },
      line:1.0,
      operator:"<"
    }
  ],
}
);
#endregion
#region 9. Test for parseShiftExpression
run_parse_test("parseShiftExpression",
@'x >> y;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.BinaryExpression,
      right:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"y",
      },
      line:1.0,
      operator:">>"
    }
  ],
}
);
#endregion
#region 10. Test for parseAdditiveExpression
run_parse_test("parseAdditiveExpression",
@'x + y;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.BinaryExpression,
      right:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"y",
      },
      line:1.0,
      operator:"+"
    }
  ],
}
);
#endregion
#region 11. Test for parseMultiplicativeExpression
run_parse_test("parseMultiplicativeExpression",
@'x * y;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.BinaryExpression,
      right:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"y",
      },
      line:1.0,
      operator:"*"
    }
  ],
}
);
#endregion
#region 12. Test for parseUnaryExpression
run_parse_test("parseUnaryExpression",
@'!x;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      expr:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.UnaryExpression,
      line:1.0,
      operator:"!"
    }
  ],
}
);
#endregion
#region 13. Test for parsePostfixExpression
run_parse_test("parsePostfixExpression",
@'x++;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      expr:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.UpdateExpression,
      line:1.0,
      prefix:false,
      operator:"++"
    }
  ],
}
);
#endregion
#region 1. Mixed Logical and Arithmetic Expressions
run_parse_test("Mixed Logical and Arithmetic Expressions",
@'x = (y + 2) * 3 && z || w;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.AssignmentExpression,
      right:{
        left:{
          left:{
            left:{
              left:{
                type: __GMLC_NodeType.Identifier,
                line:1.0,
                value:"y",
              },
              type: __GMLC_NodeType.BinaryExpression,
              right:{
                type: __GMLC_NodeType.Literal,
                line:1.0,
                value:2.0,
                scope: ScopeType.CONST
              },
              line:1.0,
              operator:"+"
            },
            type: __GMLC_NodeType.BinaryExpression,
            right:{
              type: __GMLC_NodeType.Literal,
              line:1.0,
              value:3.0,
              scope: ScopeType.CONST
            },
            line:1.0,
            operator:"*"
          },
          type: __GMLC_NodeType.LogicalExpression,
          right:{
            type: __GMLC_NodeType.Identifier,
            line:1.0,
            value:"z",
          },
          line:1.0,
          operator:"&&"
        },
        type: __GMLC_NodeType.LogicalExpression,
        right:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"w",
        },
        line:1.0,
        operator:"||"
      },
      line:1.0,
      operator:"="
    }
  ],
}
);
#endregion
#region 2. Nested Parentheses and Mixed Operators
run_parse_test("Nested Parentheses and Mixed Operators",
@'result = ((a + b) / (c - d)) << 2;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"result",
      },
      type: __GMLC_NodeType.AssignmentExpression,
      right:{
        left:{
          left:{
            left:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"a",
            },
            type: __GMLC_NodeType.BinaryExpression,
            right:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"b",
            },
            line:1.0,
            operator:"+"
          },
          type: __GMLC_NodeType.BinaryExpression,
          right:{
            left:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"c",
            },
            type: __GMLC_NodeType.BinaryExpression,
            right:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"d",
            },
            line:1.0,
            operator:"-"
          },
          line:1.0,
          operator:"\/"
        },
        type: __GMLC_NodeType.BinaryExpression,
        right:{
          type: __GMLC_NodeType.Literal,
          line:1.0,
          value:2.0,
          scope: ScopeType.CONST
        },
        line:1.0,
        operator:"<<"
      },
      line:1.0,
      operator:"="
    }
  ],
}
);
#endregion
#region 3. Complex Logical Expressions
run_parse_test("Complex Logical Expressions",
@'(x && y) || (z && (a || b));',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        left:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"x",
        },
        type: __GMLC_NodeType.LogicalExpression,
        right:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"y",
        },
        line:1.0,
        operator:"&&"
      },
      type: __GMLC_NodeType.LogicalExpression,
      right:{
        left:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"z",
        },
        type: __GMLC_NodeType.LogicalExpression,
        right:{
          left:{
            type: __GMLC_NodeType.Identifier,
            line:1.0,
            value:"a",
          },
          type: __GMLC_NodeType.LogicalExpression,
          right:{
            type: __GMLC_NodeType.Identifier,
            line:1.0,
            value:"b",
          },
          line:1.0,
          operator:"||"
        },
        line:1.0,
        operator:"&&"
      },
      line:1.0,
      operator:"||"
    }
  ],
}
);
#endregion
#region 4. Assignment Chaining with Logical Operations
/// NOTE: Technically this isnt valid GML, however it cost minimal extra to continue to include this.
run_parse_test("Assignment Chaining with Logical Operations",
@'x = y = (a && b);',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.AssignmentExpression,
      right:{
        left:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"y",
        },
        type: __GMLC_NodeType.AssignmentExpression,
        right:{
          left:{
            type: __GMLC_NodeType.Identifier,
            line:1.0,
            value:"a",
          },
          type: __GMLC_NodeType.LogicalExpression,
          right:{
            type: __GMLC_NodeType.Identifier,
            line:1.0,
            value:"b",
          },
          line:1.0,
          operator:"&&"
        },
        line:1.0,
        operator:"="
      },
      line:1.0,
      operator:"="
    }
  ],
}
);
#endregion
#region 5. Complex Arithmetic with Precedence
run_parse_test("Complex Arithmetic with Precedence",
@'x = a + b * (c - d) / e;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.AssignmentExpression,
      right:{
        left:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"a",
        },
        type: __GMLC_NodeType.BinaryExpression,
        right:{
          left:{
            left:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"b",
            },
            type: __GMLC_NodeType.BinaryExpression,
            right:{
              left:{
                type: __GMLC_NodeType.Identifier,
                line:1.0,
                value:"c",
              },
              type: __GMLC_NodeType.BinaryExpression,
              right:{
                type: __GMLC_NodeType.Identifier,
                line:1.0,
                value:"d",
              },
              line:1.0,
              operator:"-"
            },
            line:1.0,
            operator:"*"
          },
          type: __GMLC_NodeType.BinaryExpression,
          right:{
            type: __GMLC_NodeType.Identifier,
            line:1.0,
            value:"e",
          },
          line:1.0,
          operator:"\/"
        },
        line:1.0,
        operator:"+"
      },
      line:1.0,
      operator:"="
    }
  ],
}
);
#endregion
#region 6. Unary and Postfix Mix
run_parse_test("Unary and Postfix Mix",
@'++x * !y;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"x",
        },
        type: __GMLC_NodeType.UnaryExpression,
        line:1.0,
        operator:"++"
      },
      type: __GMLC_NodeType.BinaryExpression,
      right:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:1.0,
          value:"y",
        },
        type: __GMLC_NodeType.UnaryExpression,
        line:1.0,
        operator:"!"
      },
      line:1.0,
      operator:"*"
    }
  ],
}
);
#endregion
#region 1. Deeply Nested Expressions with Logical, Relational, and Arithmetic Operators
run_parse_test("Deeply Nested Complex Expression",
@'x = ((a + b * (c ? d : e) / f) << 2) || (g && h || i);',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"x",
      },
      type: __GMLC_NodeType.AssignmentExpression,
      right:{
        left:{
          left:{
            left:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"a",
            },
            type: __GMLC_NodeType.BinaryExpression,
            right:{
              left:{
                left:{
                  type: __GMLC_NodeType.Identifier,
                  line:1.0,
                  value:"b",
                },
                type: __GMLC_NodeType.BinaryExpression,
                right:{
                  type: __GMLC_NodeType.ConditionalExpression,
                  condition:{
                    type: __GMLC_NodeType.Identifier,
                    line:1.0,
                    value:"c",
                  },
                  line:1.0,
                  trueExpr:{
                    type: __GMLC_NodeType.Identifier,
                    line:1.0,
                    value:"d",
                  },
                  falseExpr:{
                    type: __GMLC_NodeType.Identifier,
                    line:1.0,
                    value:"e",
                  }
                },
                line:1.0,
                operator:"*"
              },
              type: __GMLC_NodeType.BinaryExpression,
              right:{
                type: __GMLC_NodeType.Identifier,
                line:1.0,
                value:"f",
              },
              line:1.0,
              operator:"\/"
            },
            line:1.0,
            operator:"+"
          },
          type: __GMLC_NodeType.BinaryExpression,
          right:{
            type: __GMLC_NodeType.Literal,
            line:1.0,
            value:2.0,
            scope: ScopeType.CONST
          },
          line:1.0,
          operator:"<<"
        },
        type: __GMLC_NodeType.LogicalExpression,
        right:{
          left:{
            left:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"g",
            },
            type: __GMLC_NodeType.LogicalExpression,
            right:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"h",
            },
            line:1.0,
            operator:"&&"
          },
          type: __GMLC_NodeType.LogicalExpression,
          right:{
            type: __GMLC_NodeType.Identifier,
            line:1.0,
            value:"i",
          },
          line:1.0,
          operator:"||"
        },
        line:1.0,
        operator:"||"
      },
      line:1.0,
      operator:"="
    }
  ],
}
);
#endregion
#region 2. Expression Combining Unary, Multiplicative, Additive, and Assignment Operators
run_parse_test("Complex Unary, Multiplicative, and Additive Expression",
@'result = -a * b + c / !d - (e += f) * g;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"result",
      },
      type: __GMLC_NodeType.AssignmentExpression,
      right:{
        left:{
          left:{
            left:{
              expr:{
                type: __GMLC_NodeType.Identifier,
                line:1.0,
                value:"a",
              },
              type: __GMLC_NodeType.UnaryExpression,
              line:1.0,
              operator:"-"
            },
            type: __GMLC_NodeType.BinaryExpression,
            right:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"b",
            },
            line:1.0,
            operator:"*"
          },
          type: __GMLC_NodeType.BinaryExpression,
          right:{
            left:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"c",
            },
            type: __GMLC_NodeType.BinaryExpression,
            right:{
              expr:{
                type: __GMLC_NodeType.Identifier,
                line:1.0,
                value:"d",
              },
              type: __GMLC_NodeType.UnaryExpression,
              line:1.0,
              operator:"!"
            },
            line:1.0,
            operator:"\/"
          },
          line:1.0,
          operator:"+"
        },
        type: __GMLC_NodeType.BinaryExpression,
        right:{
          left:{
            left:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"e",
            },
            type: __GMLC_NodeType.AssignmentExpression,
            right:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"f",
            },
            line:1.0,
            operator:"+="
          },
          type: __GMLC_NodeType.BinaryExpression,
          right:{
            type: __GMLC_NodeType.Identifier,
            line:1.0,
            value:"g",
          },
          line:1.0,
          operator:"*"
        },
        line:1.0,
        operator:"-"
      },
      line:1.0,
      operator:"="
    }
  ],
}
);
#endregion
#region 3. Complex Expression Using Bitwise, Logical, and Conditional Operators
run_parse_test("Complex Bitwise, Logical, and Conditional Expression",
@'final = ((x & y) | (z ^ w)) && (a ? b : (c && d));',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"final",
      },
      type: __GMLC_NodeType.AssignmentExpression,
      right:{
        left:{
          left:{
            left:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"x",
            },
            type: __GMLC_NodeType.BinaryExpression,
            right:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"y",
            },
            line:1.0,
            operator:"&"
          },
          type: __GMLC_NodeType.BinaryExpression,
          right:{
            left:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"z",
            },
            type: __GMLC_NodeType.BinaryExpression,
            right:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"w",
            },
            line:1.0,
            operator:"^"
          },
          line:1.0,
          operator:"|"
        },
        type: __GMLC_NodeType.LogicalExpression,
        right:{
          type: __GMLC_NodeType.ConditionalExpression,
          condition:{
            type: __GMLC_NodeType.Identifier,
            line:1.0,
            value:"a",
          },
          line:1.0,
          trueExpr:{
            type: __GMLC_NodeType.Identifier,
            line:1.0,
            value:"b",
          },
          falseExpr:{
            left:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"c",
            },
            type: __GMLC_NodeType.LogicalExpression,
            right:{
              type: __GMLC_NodeType.Identifier,
              line:1.0,
              value:"d",
            },
            line:1.0,
            operator:"&&"
          }
        },
        line:1.0,
        operator:"&&"
      },
      line:1.0,
      operator:"="
    }
  ],
}
);
#endregion
#region If Statement Test
run_parse_test("'=' Equal inside conditional expression",
@'if (x = 0) {
	break;
}',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.IfStatement,
	  condition:{
		right:{
		  type: __GMLC_NodeType.Literal,
		  value:0.0
		},
		type: __GMLC_NodeType.AssignmentExpression,
		left:{
		  type: __GMLC_NodeType.Identifier,
		  value:"x"
		},
		operator:"="
	  },
	  consequent:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			type: __GMLC_NodeType.BreakStatement
		  }
		]
	  },
	  alternate: undefined
	}
  ]
}
);
#endregion
#endregion
#region Function Declaration Test
run_parse_test("function declaration",
@'function sum(a, b) {
	return a + b;
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
  ],
  GlobalVar:{
    "GMLC@sum":{
      type: __GMLC_NodeType.FunctionDeclaration,
      name:"GMLC@sum",
      line:1.0,
      parameters:[
        {
          expr:{
            type: __GMLC_NodeType.Literal,
            line:1.0,
            value: undefined,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.VariableDeclaration,
          line:1.0,
          identifier:"a",
          scope: ScopeType.LOCAL
        },
        {
          expr:{
            type: __GMLC_NodeType.Literal,
            line:1.0,
            value: undefined,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.VariableDeclaration,
          line:1.0,
          identifier:"b",
          scope: ScopeType.LOCAL
        }
      ],
      body:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            expr:{
              left:{
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"a",
                scope: ScopeType.LOCAL
              },
              type: __GMLC_NodeType.BinaryExpression,
              right:{
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"b",
                scope: ScopeType.LOCAL
              },
              line:2.0,
              operator:"+"
            },
            type: __GMLC_NodeType.ReturnStatement,
            line:2.0
          }
        ]
      },
      LocalVarNames:[
        "a",
        "b"
      ],
    }
  },
  GlobalVarNames:[
    "GMLC@sum"
  ],
}
);
#endregion
#region Function Declaration Test anon
run_parse_test("function declaration <anon>",
@'add = function(a, b) {
	return a + b;
}
sub = function(a, b) {
	return a - b;
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"add",
      },
      type: __GMLC_NodeType.AssignmentExpression,
      right:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"GMLC@anon@0",
        scope: ScopeType.GLOBAL
      },
      line:1.0,
      operator:"="
    },
    {
      left:{
        type: __GMLC_NodeType.Identifier,
        line:4.0,
        value:"sub",
      },
      type: __GMLC_NodeType.AssignmentExpression,
      right:{
        type: __GMLC_NodeType.Identifier,
        line:4.0,
        value:"GMLC@anon@1",
        scope: ScopeType.GLOBAL
      },
      line:4.0,
      operator:"="
    }
  ],
  GlobalVar:{
    "GMLC@anon@0":{
      type: __GMLC_NodeType.FunctionDeclaration,
      name:"GMLC@anon@0",
      line:1.0,
      parameters:[
        {
          expr:{
            type: __GMLC_NodeType.Literal,
            line:1.0,
            value: undefined,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.VariableDeclaration,
          line:1.0,
          identifier:"a",
          scope: ScopeType.LOCAL
        },
        {
          expr:{
            type: __GMLC_NodeType.Literal,
            line:1.0,
            value: undefined,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.VariableDeclaration,
          line:1.0,
          identifier:"b",
          scope: ScopeType.LOCAL
        }
      ],
      body:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            expr:{
              left:{
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"a",
                scope: ScopeType.LOCAL
              },
              type: __GMLC_NodeType.BinaryExpression,
              right:{
                type: __GMLC_NodeType.Identifier,
                line:2.0,
                value:"b",
                scope: ScopeType.LOCAL
              },
              line:2.0,
              operator:"+"
            },
            type: __GMLC_NodeType.ReturnStatement,
            line:2.0
          }
        ]
      },
      LocalVarNames:[
        "a",
        "b"
      ],
    },
    "GMLC@anon@1":{
      type: __GMLC_NodeType.FunctionDeclaration,
      name:"GMLC@anon@1",
      line:4.0,
      parameters:[
        {
          expr:{
            type: __GMLC_NodeType.Literal,
            line:4.0,
            value: undefined,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.VariableDeclaration,
          line:4.0,
          identifier:"a",
          scope: ScopeType.LOCAL
        },
        {
          expr:{
            type: __GMLC_NodeType.Literal,
            line:4.0,
            value: undefined,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.VariableDeclaration,
          line:4.0,
          identifier:"b",
          scope: ScopeType.LOCAL
        }
      ],
      body:{
        type: __GMLC_NodeType.BlockStatement,
        line:4.0,
        statements:[
          {
            expr:{
              left:{
                type: __GMLC_NodeType.Identifier,
                line:5.0,
                value:"a",
                scope: ScopeType.LOCAL
              },
              type: __GMLC_NodeType.BinaryExpression,
              right:{
                type: __GMLC_NodeType.Identifier,
                line:5.0,
                value:"b",
                scope: ScopeType.LOCAL
              },
              line:5.0,
              operator:"-"
            },
            type: __GMLC_NodeType.ReturnStatement,
            line:5.0
          }
        ]
      },
      LocalVarNames:[
        "a",
        "b"
      ],
    }
  },
  GlobalVarNames:[
    "GMLC@anon@0",
    "GMLC@anon@1"
  ],
}
);
#endregion
#region Function Declaration Test anon
run_parse_test("function declaration with statics, globals, and var",
@'foo = function(a, b) {
	static __bar = function(){};
	globalvar BAR = 1;
	var _bar = 2;
}',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      right:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"GMLC@anon@2",
        scope: ScopeType.GLOBAL
      },
      type: __GMLC_NodeType.AssignmentExpression,
      line:1.0,
      operator:"=",
      left:{
        type: __GMLC_NodeType.Identifier,
        line:1.0,
        value:"foo",
        scope: undefined
      }
    }
  ],
  GlobalVar:{
    "GMLC@anon@3":{
      type: __GMLC_NodeType.FunctionDeclaration,
      name:"GMLC@anon@3",
      line:2.0,
      parameters:[
      ],
      body:{
        type: __GMLC_NodeType.BlockStatement,
        line:2.0,
        statements:[
        ]
      },
    },
    "GMLC@anon@2":{
      type: __GMLC_NodeType.FunctionDeclaration,
      name:"GMLC@anon@2",
      line:1.0,
      parameters:[
        {
          expr:{
            type: __GMLC_NodeType.Literal,
            line:1.0,
            value: undefined,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.VariableDeclaration,
          line:1.0,
          identifier:"a",
          scope: ScopeType.LOCAL
        },
        {
          expr:{
            type: __GMLC_NodeType.Literal,
            line:1.0,
            value: undefined,
            scope: ScopeType.CONST
          },
          type: __GMLC_NodeType.VariableDeclaration,
          line:1.0,
          identifier:"b",
          scope: ScopeType.LOCAL
        }
      ],
      body:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            type: __GMLC_NodeType.VariableDeclarationList,
            line:2.0,
            statements:{
              type: __GMLC_NodeType.BlockStatement,
              line:2.0,
              statements:[
                {
                  expr:{
                    type: __GMLC_NodeType.Identifier,
                    line:2.0,
                    value:"GMLC@anon@3",
                    scope: ScopeType.GLOBAL
                  },
                  type: __GMLC_NodeType.VariableDeclaration,
                  line:2.0,
                  identifier:"__bar",
                  scope: ScopeType.STATIC
                }
              ]
            }
          },
          {
            type: __GMLC_NodeType.VariableDeclarationList,
            line:3.0,
            statements:{
              type: __GMLC_NodeType.BlockStatement,
              line:3.0,
              statements:[
                {
                  expr:{
                    type: __GMLC_NodeType.Literal,
                    line:3.0,
                    value:1.0,
                    scope: ScopeType.CONST
                  },
                  type: __GMLC_NodeType.VariableDeclaration,
                  line:3.0,
                  identifier:"BAR",
                  scope: ScopeType.GLOBAL
                }
              ]
            }
          },
          {
            type: __GMLC_NodeType.VariableDeclarationList,
            line:4.0,
            statements:{
              type: __GMLC_NodeType.BlockStatement,
              line:4.0,
              statements:[
                {
                  expr:{
                    type: __GMLC_NodeType.Literal,
                    line:4.0,
                    value:2.0,
                    scope: ScopeType.CONST
                  },
                  type: __GMLC_NodeType.VariableDeclaration,
                  line:4.0,
                  identifier:"_bar",
                  scope: ScopeType.LOCAL
                }
              ]
            }
          }
        ]
      },
      LocalVarNames:[
        "a",
        "b",
        "_bar"
      ],
      StaticVar:{
      },
      StaticVarNames:[
        "__bar"
      ]
    }
  },
  GlobalVarNames:[
    "GMLC@anon@3",
    "BAR",
    "GMLC@anon@2"
  ],
}
);
#endregion
#region Multiple Variable Declarations
run_parse_test("multiple variable declarations with and without initialization",
@'var _tile = 5, _src;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:1.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.Literal,
              line:1.0,
              value:5.0,
              scope: ScopeType.CONST
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:1.0,
            identifier:"_tile",
            scope: ScopeType.LOCAL
          },
          {
            expr: undefined,
            type: __GMLC_NodeType.VariableDeclaration,
            line:1.0,
            identifier:"_src",
            scope: ScopeType.LOCAL
          }
        ]
      }
    }
  ],
  LocalVarNames:[
    "_tile",
    "_src"
  ]
}
);

run_parse_test("multiple variable declarations without initialization",
@'var _tile, _src;',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			expr: undefined,
			identifier:"_tile",
			type: __GMLC_NodeType.VariableDeclaration,
		  },
		  {
			expr: undefined,
			identifier:"_src",
			type: __GMLC_NodeType.VariableDeclaration,
		  }
		]
	  }
	}
  ]
}
);

#endregion
#region Accessors <Array, Grid, List, Map, Struct>
run_parse_test("Array access and modification",
@'var arr = [0, 1, 2];
arr[0] = 1;
var test = ++arr[2]--;
return arr;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:1.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.ArrayPattern,
              line:1.0,
              elements:[
                {
                  type: __GMLC_NodeType.Literal,
                  line:1.0,
                  value:0.0,
                  scope: ScopeType.CONST
                },
                {
                  type: __GMLC_NodeType.Literal,
                  line:1.0,
                  value:1.0,
                  scope: ScopeType.CONST
                },
                {
                  type: __GMLC_NodeType.Literal,
                  line:1.0,
                  value:2.0,
                  scope: ScopeType.CONST
                }
              ]
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:1.0,
            identifier:"arr",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      right:{
        type: __GMLC_NodeType.Literal,
        line:2.0,
        value:1.0,
        scope: ScopeType.CONST
      },
      type: __GMLC_NodeType.AssignmentExpression,
      line:2.0,
      operator:"=",
      left:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:2.0,
          value:"arr",
          scope: ScopeType.LOCAL
        },
        type: __GMLC_NodeType.AccessorExpression,
        line:2.0,
        val1:{
          type: __GMLC_NodeType.Literal,
          line:2.0,
          value:0.0,
          scope: ScopeType.CONST
        },
        val2: undefined,
        accessorType:"__GMLC_AccessorType.Array"
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:3.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:3.0,
        statements:[
          {
            expr:{
              expr:{
                expr:{
                  expr:{
                    type: __GMLC_NodeType.Identifier,
                    line:3.0,
                    value:"arr",
                    scope: ScopeType.LOCAL
                  },
                  type: __GMLC_NodeType.AccessorExpression,
                  line:3.0,
                  val1:{
                    type: __GMLC_NodeType.Literal,
                    line:3.0,
                    value:2.0,
                    scope: ScopeType.CONST
                  },
                  val2: undefined,
                  accessorType:"__GMLC_AccessorType.Array"
                },
                type: __GMLC_NodeType.UpdateExpression,
                line:3.0,
                prefix:false,
                operator:"--"
              },
              type: __GMLC_NodeType.UnaryExpression,
              line:3.0,
              operator:"++"
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:3.0,
            identifier:"test",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      expr:{
        type: __GMLC_NodeType.Identifier,
        line:4.0,
        value:"arr",
        scope: ScopeType.LOCAL
      },
      type: __GMLC_NodeType.ReturnStatement,
      line:4.0
    }
  ],
  LocalVarNames:[
    "arr",
    "test"
  ]
}
);

run_parse_test("List access and modification",
@'var list = ds_list_create();
list[| 0] = 1;
list[| 1] = 2;
ds_list_set(list, 2, 3);
var test = ++list[| 2]--;
var _return = test;
ds_list_destroy(list);
return _return;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:1.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.CallExpression,
              line:1.0,
              arguments:[
              ],
              callee:{
                type: __GMLC_NodeType.Function,
                name:"ds_list_create",
                value:1294.0,
                line:1.0
              }
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:1.0,
            identifier:"list",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      right:{
        type: __GMLC_NodeType.Literal,
        line:2.0,
        value:1.0,
        scope: ScopeType.CONST
      },
      type: __GMLC_NodeType.AssignmentExpression,
      line:2.0,
      operator:"=",
      left:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:2.0,
          value:"list",
          scope: ScopeType.LOCAL
        },
        type: __GMLC_NodeType.AccessorExpression,
        line:2.0,
        val1:{
          type: __GMLC_NodeType.Literal,
          line:2.0,
          value:0.0,
          scope: ScopeType.CONST
        },
        val2: undefined,
        accessorType:"__GMLC_AccessorType.List"
      }
    },
    {
      right:{
        type: __GMLC_NodeType.Literal,
        line:3.0,
        value:2.0,
        scope: ScopeType.CONST
      },
      type: __GMLC_NodeType.AssignmentExpression,
      line:3.0,
      operator:"=",
      left:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:3.0,
          value:"list",
          scope: ScopeType.LOCAL
        },
        type: __GMLC_NodeType.AccessorExpression,
        line:3.0,
        val1:{
          type: __GMLC_NodeType.Literal,
          line:3.0,
          value:1.0,
          scope: ScopeType.CONST
        },
        val2: undefined,
        accessorType:"__GMLC_AccessorType.List"
      }
    },
    {
      type: __GMLC_NodeType.CallExpression,
      line:4.0,
      arguments:[
        {
          type: __GMLC_NodeType.Identifier,
          line:4.0,
          value:"list",
          scope: ScopeType.LOCAL
        },
        {
          type: __GMLC_NodeType.Literal,
          line:4.0,
          value:2.0,
          scope: ScopeType.CONST
        },
        {
          type: __GMLC_NodeType.Literal,
          line:4.0,
          value:3.0,
          scope: ScopeType.CONST
        }
      ],
      callee:{
        type: __GMLC_NodeType.Function,
        name:"ds_list_set",
        value:1314.0,
        line:4.0
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:5.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:5.0,
        statements:[
          {
            expr:{
              expr:{
                expr:{
                  expr:{
                    type: __GMLC_NodeType.Identifier,
                    line:5.0,
                    value:"list",
                    scope: ScopeType.LOCAL
                  },
                  type: __GMLC_NodeType.AccessorExpression,
                  line:5.0,
                  val1:{
                    type: __GMLC_NodeType.Literal,
                    line:5.0,
                    value:2.0,
                    scope: ScopeType.CONST
                  },
                  val2: undefined,
                  accessorType:"__GMLC_AccessorType.List"
                },
                type: __GMLC_NodeType.UpdateExpression,
                line:5.0,
                prefix:false,
                operator:"--"
              },
              type: __GMLC_NodeType.UnaryExpression,
              line:5.0,
              operator:"++"
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:5.0,
            identifier:"test",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:6.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:6.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.Identifier,
              line:6.0,
              value:"test",
              scope: ScopeType.LOCAL
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:6.0,
            identifier:"_return",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      type: __GMLC_NodeType.CallExpression,
      line:7.0,
      arguments:[
        {
          type: __GMLC_NodeType.Identifier,
          line:7.0,
          value:"list",
          scope: ScopeType.LOCAL
        }
      ],
      callee:{
        type: __GMLC_NodeType.Function,
        name:"ds_list_destroy",
        value:1295.0,
        line:7.0
      }
    },
    {
      expr:{
        type: __GMLC_NodeType.Identifier,
        line:8.0,
        value:"_return",
        scope: ScopeType.LOCAL
      },
      type: __GMLC_NodeType.ReturnStatement,
      line:8.0
    }
  ],
  LocalVarNames:[
    "list",
    "test",
    "_return"
  ]
}
);

run_parse_test("Grid access and modification",
@'var grid = ds_grid_create(5, 5);
ds_grid_set_region(grid, 0,0, 4, 4, "example");
grid[# 0, 1] = 2;
var test = ++grid[# 3, 4]--;
var _return = test;
ds_grid_destroy(grid);
return _return;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:1.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.CallExpression,
              line:1.0,
              arguments:[
                {
                  type: __GMLC_NodeType.Literal,
                  line:1.0,
                  value:5.0,
                  scope: ScopeType.CONST
                },
                {
                  type: __GMLC_NodeType.Literal,
                  line:1.0,
                  value:5.0,
                  scope: ScopeType.CONST
                }
              ],
              callee:{
                type: __GMLC_NodeType.Function,
                name:"ds_grid_create",
                value:1365.0,
                line:1.0
              }
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:1.0,
            identifier:"grid",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      type: __GMLC_NodeType.CallExpression,
      line:2.0,
      arguments:[
        {
          type: __GMLC_NodeType.Identifier,
          line:2.0,
          value:"grid",
          scope: ScopeType.LOCAL
        },
        {
          type: __GMLC_NodeType.Literal,
          line:2.0,
          value:0.0,
          scope: ScopeType.CONST
        },
        {
          type: __GMLC_NodeType.Literal,
          line:2.0,
          value:0.0,
          scope: ScopeType.CONST
        },
        {
          type: __GMLC_NodeType.Literal,
          line:2.0,
          value:4.0,
          scope: ScopeType.CONST
        },
        {
          type: __GMLC_NodeType.Literal,
          line:2.0,
          value:4.0,
          scope: ScopeType.CONST
        },
        {
          type: __GMLC_NodeType.Literal,
          line:2.0,
          value:"example",
          scope: ScopeType.CONST
        }
      ],
      callee:{
        type: __GMLC_NodeType.Function,
        name:"ds_grid_set_region",
        value:1377.0,
        line:2.0
      }
    },
    {
      right:{
        type: __GMLC_NodeType.Literal,
        line:3.0,
        value:2.0,
        scope: ScopeType.CONST
      },
      type: __GMLC_NodeType.AssignmentExpression,
      line:3.0,
      operator:"=",
      left:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:3.0,
          value:"grid",
          scope: ScopeType.LOCAL
        },
        type: __GMLC_NodeType.AccessorExpression,
        line:3.0,
        val1:{
          type: __GMLC_NodeType.Literal,
          line:3.0,
          value:0.0,
          scope: ScopeType.CONST
        },
        val2:{
          type: __GMLC_NodeType.Literal,
          line:3.0,
          value:1.0,
          scope: ScopeType.CONST
        },
        accessorType:"__GMLC_AccessorType.Grid"
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:4.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:4.0,
        statements:[
          {
            expr:{
              expr:{
                expr:{
                  expr:{
                    type: __GMLC_NodeType.Identifier,
                    line:4.0,
                    value:"grid",
                    scope: ScopeType.LOCAL
                  },
                  type: __GMLC_NodeType.AccessorExpression,
                  line:4.0,
                  val1:{
                    type: __GMLC_NodeType.Literal,
                    line:4.0,
                    value:3.0,
                    scope: ScopeType.CONST
                  },
                  val2:{
                    type: __GMLC_NodeType.Literal,
                    line:4.0,
                    value:4.0,
                    scope: ScopeType.CONST
                  },
                  accessorType:"__GMLC_AccessorType.Grid"
                },
                type: __GMLC_NodeType.UpdateExpression,
                line:4.0,
                prefix:false,
                operator:"--"
              },
              type: __GMLC_NodeType.UnaryExpression,
              line:4.0,
              operator:"++"
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:4.0,
            identifier:"test",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:5.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:5.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.Identifier,
              line:5.0,
              value:"test",
              scope: ScopeType.LOCAL
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:5.0,
            identifier:"_return",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      type: __GMLC_NodeType.CallExpression,
      line:6.0,
      arguments:[
        {
          type: __GMLC_NodeType.Identifier,
          line:6.0,
          value:"grid",
          scope: ScopeType.LOCAL
        }
      ],
      callee:{
        type: __GMLC_NodeType.Function,
        name:"ds_grid_destroy",
        value:1366.0,
        line:6.0
      }
    },
    {
      expr:{
        type: __GMLC_NodeType.Identifier,
        line:7.0,
        value:"_return",
        scope: ScopeType.LOCAL
      },
      type: __GMLC_NodeType.ReturnStatement,
      line:7.0
    }
  ],
  LocalVarNames:[
    "grid",
    "test",
    "_return"
  ]
}
);

run_parse_test("Map access and modification",
@'var map = ds_map_create();
map[? "zero"] = 1;
ds_map_set(map, "zero", 2);
map[? "two"] = 3;
var test = ++map[? "two"]--;
var _return = test;
ds_map_destroy(map);
return _return;',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:1.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.CallExpression,
              line:1.0,
              arguments:[
              ],
              callee:{
                type: __GMLC_NodeType.Function,
                name:"ds_map_create",
                value:1317.0,
                line:1.0
              }
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:1.0,
            identifier:"map",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      right:{
        type: __GMLC_NodeType.Literal,
        line:2.0,
        value:1.0,
        scope: ScopeType.CONST
      },
      type: __GMLC_NodeType.AssignmentExpression,
      line:2.0,
      operator:"=",
      left:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:2.0,
          value:"map",
          scope: ScopeType.LOCAL
        },
        type: __GMLC_NodeType.AccessorExpression,
        line:2.0,
        val1:{
          type: __GMLC_NodeType.Literal,
          line:2.0,
          value:"zero",
          scope: ScopeType.CONST
        },
        val2: undefined,
        accessorType:"__GMLC_AccessorType.Map"
      }
    },
    {
      type: __GMLC_NodeType.CallExpression,
      line:3.0,
      arguments:[
        {
          type: __GMLC_NodeType.Identifier,
          line:3.0,
          value:"map",
          scope: ScopeType.LOCAL
        },
        {
          type: __GMLC_NodeType.Literal,
          line:3.0,
          value:"zero",
          scope: ScopeType.CONST
        },
        {
          type: __GMLC_NodeType.Literal,
          line:3.0,
          value:2.0,
          scope: ScopeType.CONST
        }
      ],
      callee:{
        type: __GMLC_NodeType.Function,
        name:"ds_map_set",
        value:1324.0,
        line:3.0
      }
    },
    {
      right:{
        type: __GMLC_NodeType.Literal,
        line:4.0,
        value:3.0,
        scope: ScopeType.CONST
      },
      type: __GMLC_NodeType.AssignmentExpression,
      line:4.0,
      operator:"=",
      left:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:4.0,
          value:"map",
          scope: ScopeType.LOCAL
        },
        type: __GMLC_NodeType.AccessorExpression,
        line:4.0,
        val1:{
          type: __GMLC_NodeType.Literal,
          line:4.0,
          value:"two",
          scope: ScopeType.CONST
        },
        val2: undefined,
        accessorType:"__GMLC_AccessorType.Map"
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:5.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:5.0,
        statements:[
          {
            expr:{
              expr:{
                expr:{
                  expr:{
                    type: __GMLC_NodeType.Identifier,
                    line:5.0,
                    value:"map",
                    scope: ScopeType.LOCAL
                  },
                  type: __GMLC_NodeType.AccessorExpression,
                  line:5.0,
                  val1:{
                    type: __GMLC_NodeType.Literal,
                    line:5.0,
                    value:"two",
                    scope: ScopeType.CONST
                  },
                  val2: undefined,
                  accessorType:"__GMLC_AccessorType.Map"
                },
                type: __GMLC_NodeType.UpdateExpression,
                line:5.0,
                prefix:false,
                operator:"--"
              },
              type: __GMLC_NodeType.UnaryExpression,
              line:5.0,
              operator:"++"
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:5.0,
            identifier:"test",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:6.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:6.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.Identifier,
              line:6.0,
              value:"test",
              scope: ScopeType.LOCAL
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:6.0,
            identifier:"_return",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      type: __GMLC_NodeType.CallExpression,
      line:7.0,
      arguments:[
        {
          type: __GMLC_NodeType.Identifier,
          line:7.0,
          value:"map",
          scope: ScopeType.LOCAL
        }
      ],
      callee:{
        type: __GMLC_NodeType.Function,
        name:"ds_map_destroy",
        value:1318.0,
        line:7.0
      }
    },
    {
      expr:{
        type: __GMLC_NodeType.Identifier,
        line:8.0,
        value:"_return",
        scope: ScopeType.LOCAL
      },
      type: __GMLC_NodeType.ReturnStatement,
      line:8.0
    }
  ],
  LocalVarNames:[
    "map",
    "test",
    "_return"
  ]
}
);

run_parse_test("Struct access and modification with error handling",
@'var struct = {zero: 0, one: 1, two: 2 };
struct[$ "zero"] = 1;
var test = ++struct[$ "two"]--;
return string(struct)',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:1.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.StructPattern,
              keys:[
                {
                  type: __GMLC_NodeType.Literal,
                  line:1.0,
                  value:"zero",
                  scope: ScopeType.CONST
                },
                {
                  type: __GMLC_NodeType.Literal,
                  line:1.0,
                  value:"one",
                  scope: ScopeType.CONST
                },
                {
                  type: __GMLC_NodeType.Literal,
                  line:1.0,
                  value:"two",
                  scope: ScopeType.CONST
                }
              ],
              exprs:[
                {
                  type: __GMLC_NodeType.Literal,
                  line:1.0,
                  value:0.0,
                  scope: ScopeType.CONST
                },
                {
                  type: __GMLC_NodeType.Literal,
                  line:1.0,
                  value:1.0,
                  scope: ScopeType.CONST
                },
                {
                  type: __GMLC_NodeType.Literal,
                  line:1.0,
                  value:2.0,
                  scope: ScopeType.CONST
                }
              ],
              line:1.0
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:1.0,
            identifier:"struct",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      right:{
        type: __GMLC_NodeType.Literal,
        line:2.0,
        value:1.0,
        scope: ScopeType.CONST
      },
      type: __GMLC_NodeType.AssignmentExpression,
      line:2.0,
      operator:"=",
      left:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:2.0,
          value:"struct",
          scope: ScopeType.LOCAL
        },
        type: __GMLC_NodeType.AccessorExpression,
        line:2.0,
        val1:{
          type: __GMLC_NodeType.Literal,
          line:2.0,
          value:"zero",
          scope: ScopeType.CONST
        },
        val2: undefined,
        accessorType:"__GMLC_AccessorType.Struct"
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:3.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:3.0,
        statements:[
          {
            expr:{
              expr:{
                expr:{
                  expr:{
                    type: __GMLC_NodeType.Identifier,
                    line:3.0,
                    value:"struct",
                    scope: ScopeType.LOCAL
                  },
                  type: __GMLC_NodeType.AccessorExpression,
                  line:3.0,
                  val1:{
                    type: __GMLC_NodeType.Literal,
                    line:3.0,
                    value:"two",
                    scope: ScopeType.CONST
                  },
                  val2: undefined,
                  accessorType:"__GMLC_AccessorType.Struct"
                },
                type: __GMLC_NodeType.UpdateExpression,
                line:3.0,
                prefix:false,
                operator:"--"
              },
              type: __GMLC_NodeType.UnaryExpression,
              line:3.0,
              operator:"++"
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:3.0,
            identifier:"test",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      expr:{
        type: __GMLC_NodeType.CallExpression,
        line:4.0,
        arguments:[
          {
            type: __GMLC_NodeType.Identifier,
            line:4.0,
            value:"struct",
            scope: ScopeType.LOCAL
          }
        ],
        callee:{
          type: __GMLC_NodeType.Function,
          name:"string",
          value:264.0,
          line:4.0
        }
      },
      type: __GMLC_NodeType.ReturnStatement,
      line:4.0
    }
  ],
  LocalVarNames:[
    "struct",
    "test"
  ]
}
);

run_parse_test("Struct Advance accessing and modification with error handling",
@'var two = 2
var struct = {one: 1, two};
struct.zero = 0;
struct[$ "zero"] = "ZERO";
struct_set(struct, "one", "ONE")
struct_set_from_hash(struct, variable_get_hash("one"), "oneAgain");
var _test1 = ++struct.two--;
var _test2 = ++struct[$ "two"]--;
var _test3 = struct_get(struct, "two");
var _test4 = struct_get_from_hash(struct, variable_get_hash("two"));
return string(struct)',
{
  type: __GMLC_NodeType.Script,
  line: undefined,
  statements:[
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:1.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:1.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.Literal,
              line:1.0,
              value:2.0,
              scope: ScopeType.CONST
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:1.0,
            identifier:"two",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:2.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:2.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.StructPattern,
              keys:[
                {
                  type: __GMLC_NodeType.Literal,
                  line:2.0,
                  value:"one",
                  scope: ScopeType.CONST
                },
                {
                  type: __GMLC_NodeType.Literal,
                  line:2.0,
                  value:"two",
                  scope: ScopeType.CONST
                }
              ],
              exprs:[
                {
                  type: __GMLC_NodeType.Literal,
                  line:2.0,
                  value:1.0,
                  scope: ScopeType.CONST
                },
                {
                  type: __GMLC_NodeType.Identifier,
                  line:2.0,
                  value:"two",
                  scope: undefined
                }
              ],
              line:2.0
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:2.0,
            identifier:"struct",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      right:{
        type: __GMLC_NodeType.Literal,
        line:3.0,
        value:0.0,
        scope: ScopeType.CONST
      },
      type: __GMLC_NodeType.AssignmentExpression,
      line:3.0,
      operator:"=",
      left:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:3.0,
          value:"struct",
          scope: ScopeType.LOCAL
        },
        type: __GMLC_NodeType.AccessorExpression,
        line:3.0,
        val1:{
          type: __GMLC_NodeType.Literal,
          line:3.0,
          value:"zero",
          scope: ScopeType.CONST
        },
        val2: undefined,
        accessorType:"__GMLC_AccessorType.Dot"
      }
    },
    {
      right:{
        type: __GMLC_NodeType.Literal,
        line:4.0,
        value:"ZERO",
        scope: ScopeType.CONST
      },
      type: __GMLC_NodeType.AssignmentExpression,
      line:4.0,
      operator:"=",
      left:{
        expr:{
          type: __GMLC_NodeType.Identifier,
          line:4.0,
          value:"struct",
          scope: ScopeType.LOCAL
        },
        type: __GMLC_NodeType.AccessorExpression,
        line:4.0,
        val1:{
          type: __GMLC_NodeType.Literal,
          line:4.0,
          value:"zero",
          scope: ScopeType.CONST
        },
        val2: undefined,
        accessorType:"__GMLC_AccessorType.Struct"
      }
    },
    {
      type: __GMLC_NodeType.CallExpression,
      line:5.0,
      arguments:[
        {
          type: __GMLC_NodeType.Identifier,
          line:5.0,
          value:"struct",
          scope: ScopeType.LOCAL
        },
        {
          type: __GMLC_NodeType.Literal,
          line:5.0,
          value:"one",
          scope: ScopeType.CONST
        },
        {
          type: __GMLC_NodeType.Literal,
          line:5.0,
          value:"ONE",
          scope: ScopeType.CONST
        }
      ],
      callee:{
        type: __GMLC_NodeType.Function,
        name:"struct_set",
        value:1180.0,
        line:5.0
      }
    },
    {
      type: __GMLC_NodeType.CallExpression,
      line:6.0,
      arguments:[
        {
          type: __GMLC_NodeType.Identifier,
          line:6.0,
          value:"struct",
          scope: ScopeType.LOCAL
        },
        {
          type: __GMLC_NodeType.CallExpression,
          line:6.0,
          arguments:[
            {
              type: __GMLC_NodeType.Literal,
              line:6.0,
              value:"one",
              scope: ScopeType.CONST
            }
          ],
          callee:{
            type: __GMLC_NodeType.Function,
            name:"variable_get_hash",
            value:1176.0,
            line:6.0
          }
        },
        {
          type: __GMLC_NodeType.Literal,
          line:6.0,
          value:"oneAgain",
          scope: ScopeType.CONST
        }
      ],
      callee:{
        type: __GMLC_NodeType.Function,
        name:"struct_set_from_hash",
        value:1181.0,
        line:6.0
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:7.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:7.0,
        statements:[
          {
            expr:{
              expr:{
                expr:{
                  expr:{
                    type: __GMLC_NodeType.Identifier,
                    line:7.0,
                    value:"struct",
                    scope: ScopeType.LOCAL
                  },
                  type: __GMLC_NodeType.AccessorExpression,
                  line:7.0,
                  val1:{
                    type: __GMLC_NodeType.Literal,
                    line:7.0,
                    value:"two",
                    scope: ScopeType.CONST
                  },
                  val2: undefined,
                  accessorType:"__GMLC_AccessorType.Dot"
                },
                type: __GMLC_NodeType.UpdateExpression,
                line:7.0,
                prefix:false,
                operator:"--"
              },
              type: __GMLC_NodeType.UnaryExpression,
              line:7.0,
              operator:"++"
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:7.0,
            identifier:"_test1",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:8.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:8.0,
        statements:[
          {
            expr:{
              expr:{
                expr:{
                  expr:{
                    type: __GMLC_NodeType.Identifier,
                    line:8.0,
                    value:"struct",
                    scope: ScopeType.LOCAL
                  },
                  type: __GMLC_NodeType.AccessorExpression,
                  line:8.0,
                  val1:{
                    type: __GMLC_NodeType.Literal,
                    line:8.0,
                    value:"two",
                    scope: ScopeType.CONST
                  },
                  val2: undefined,
                  accessorType:"__GMLC_AccessorType.Struct"
                },
                type: __GMLC_NodeType.UpdateExpression,
                line:8.0,
                prefix:false,
                operator:"--"
              },
              type: __GMLC_NodeType.UnaryExpression,
              line:8.0,
              operator:"++"
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:8.0,
            identifier:"_test2",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:9.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:9.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.CallExpression,
              line:9.0,
              arguments:[
                {
                  type: __GMLC_NodeType.Identifier,
                  line:9.0,
                  value:"struct",
                  scope: ScopeType.LOCAL
                },
                {
                  type: __GMLC_NodeType.Literal,
                  line:9.0,
                  value:"two",
                  scope: ScopeType.CONST
                }
              ],
              callee:{
                type: __GMLC_NodeType.Function,
                name:"struct_get",
                value:1178.0,
                line:9.0
              }
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:9.0,
            identifier:"_test3",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      type: __GMLC_NodeType.VariableDeclarationList,
      line:10.0,
      statements:{
        type: __GMLC_NodeType.BlockStatement,
        line:10.0,
        statements:[
          {
            expr:{
              type: __GMLC_NodeType.CallExpression,
              line:10.0,
              arguments:[
                {
                  type: __GMLC_NodeType.Identifier,
                  line:10.0,
                  value:"struct",
                  scope: ScopeType.LOCAL
                },
                {
                  type: __GMLC_NodeType.CallExpression,
                  line:10.0,
                  arguments:[
                    {
                      type: __GMLC_NodeType.Literal,
                      line:10.0,
                      value:"two",
                      scope: ScopeType.CONST
                    }
                  ],
                  callee:{
                    type: __GMLC_NodeType.Function,
                    name:"variable_get_hash",
                    value:1176.0,
                    line:10.0
                  }
                }
              ],
              callee:{
                type: __GMLC_NodeType.Function,
                name:"struct_get_from_hash",
                value:1179.0,
                line:10.0
              }
            },
            type: __GMLC_NodeType.VariableDeclaration,
            line:10.0,
            identifier:"_test4",
            scope: ScopeType.LOCAL
          }
        ]
      }
    },
    {
      expr:{
        type: __GMLC_NodeType.CallExpression,
        line:11.0,
        arguments:[
          {
            type: __GMLC_NodeType.Identifier,
            line:11.0,
            value:"struct",
            scope: ScopeType.LOCAL
          }
        ],
        callee:{
          type: __GMLC_NodeType.Function,
          name:"string",
          value:264.0,
          line:11.0
        }
      },
      type: __GMLC_NodeType.ReturnStatement,
      line:11.0
    }
  ],
  LocalVarNames:[
    "two",
    "struct",
    "_test1",
    "_test2",
    "_test3",
    "_test4"
  ]
}
);
#endregion
}
//run_all_parser_tests()
#endregion

#region PostProcessor Unit Tests
function run_post_processor_test(description, input, expectedAST) {
	log($"Attempting Post Processer Test :: {description}")
	
	var tokenizer = new GML_Tokenizer();
	tokenizer.initialize(input);
	var tokens = tokenizer.parseAll();
	
	var preprocessor = new GML_PreProcessor();
	preprocessor.initialize(tokens);
	var preprocessedTokens = preprocessor.parseAll();
	
	var parser = new GML_Parser();
	parser.initialize(preprocessedTokens);
	var ast = parser.parseAll();
	
	var postprocessor = new GML_PostProcessor();
	postprocessor.initialize(ast);
	var optimizedAST = postprocessor.parseAll();
	
	__compare_results(description, ast, expectedAST);
}
function run_all_post_processor_tests() {
log("~~~~~ Post Processor Unit Tests ~~~~~\n");

#region Optimize simple constant expressions
// Example test case
run_post_processor_test("Optimize simple constant expressions",
@'var x = 5 + 3;',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			scope:"LocalVar",
			expr:{
			  value:8.0,
			  type: __GMLC_NodeType.Literal,
			  scope:"Const"
			},
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"x",
		  }
		],
	  },
	}
  ],
}
);
#endregion
#region Optimize simple arithmetic constant expressions
run_post_processor_test("Optimize simple arithmetic constant expressions",
@'var result = 2 + 3 * 4;',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			scope:"LocalVar",
			expr:{
			  value:14.0,
			  type: __GMLC_NodeType.Literal,
			  scope:"Const"
			},
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"result",
		  }
		],
	  },
	}
  ],
}
);
#endregion
#region Eliminate unreachable code after unconditional branch
run_post_processor_test("Eliminate unreachable code after unconditional branch",
@'if (true) { var x = 1; } else { var x = 2; }',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.BlockStatement,
	  statements:[
		{
		  type: __GMLC_NodeType.VariableDeclarationList,
		  statements:{
			type: __GMLC_NodeType.BlockStatement,
			statements:[
			  {
				scope:"LocalVar",
				expr:{
				  value:1.0,
				  type: __GMLC_NodeType.Literal,
				  scope:"Const"
				},
				type: __GMLC_NodeType.VariableDeclaration,
				identifier:"x",
			  }
			],
		  },
		}
	  ]
	}
  ],
}
);
#endregion
#region Simplify logical expressions with constant values
run_post_processor_test("Simplify logical expressions with constant values",
@'var isValid = false && anything;',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			scope:"LocalVar",
			expr:{
			  value: false,
			  type: __GMLC_NodeType.Literal,
			  scope:"Const"
			},
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"isValid",
		  }
		],
	  },
	}
  ],
}
);
#endregion
#region Optimization of Struct Get with Literal to Hashed Access
run_post_processor_test("Optimize struct_get with string literal to hashed access",
@'var value = struct_get(someStruct, "key");',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  statements:{
		statements:[
		  {
			scope:"LocalVar",
			expr:{
			  callee:{
				value: struct_get_from_hash,
				type: __GMLC_NodeType.Function,
				name:"struct_get_from_hash",
			  },
			  arguments:[
				{
				  value:"someStruct",
				  type: __GMLC_NodeType.Identifier,
				},
				{
				  value: variable_get_hash("key"),
				  type: __GMLC_NodeType.Literal,
				  scope:"Const"
				}
			  ],
			  type: __GMLC_NodeType.FunctionCall,
			},
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"value",
		  }
		],
		type: __GMLC_NodeType.BlockStatement,
	  },
	  type: __GMLC_NodeType.VariableDeclarationList,
	}
  ],
}
);
#endregion
#region Optimization of Struct Set with Literal to Hashed Access
run_post_processor_test("Optimize struct_set with string literal to hashed access",
@'struct_set(someStruct, "key", 10);',
{
  statements:[
	{
	  expr:{
		callee:{
		  value: struct_set_from_hash,
		  type: __GMLC_NodeType.Function,
		  name:"struct_set_from_hash",
		},
		arguments:[
		  {
			value:"someStruct",
			type: __GMLC_NodeType.Identifier,
		  },
		  {
			value: variable_get_hash("key"),
			type: __GMLC_NodeType.Literal,
			scope:"Const"
		  },
		  {
			value: 10,
			type: __GMLC_NodeType.Literal,
			scope:"Const"
		  }
		],
		type: __GMLC_NodeType.FunctionCall,
	  },
	  type: __GMLC_NodeType.ExpressionStatement,
	}
  ],
  type: __GMLC_NodeType.Script,
}
);
#endregion
#region Optimization of Simple String Concatenation
run_post_processor_test("Optimize simple string concatenation",
@'var fullName = "John" + " Doe";',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"fullName",
			expr:{
			  type: __GMLC_NodeType.Literal,
			  value:"John Doe",
			  scope:"Const"
			}
		  }
		],
	  },
	}
  ],
}
);
#endregion
#region Precomputed Hash Value for Frequent Struct Keys
run_post_processor_test("Precompute hash for frequent struct keys",
@'var userAge = struct_get(user, "age");',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"userAge",
			expr:{
			  type: __GMLC_NodeType.FunctionCall,
			  callee:{
				value: struct_get_from_hash,
				type: __GMLC_NodeType.Function,
				name:"struct_get_from_hash",
			  },
			  arguments:[
				{type: __GMLC_NodeType.Identifier, value:"user"},
				{value: variable_get_hash("age"), type: __GMLC_NodeType.Literal, scope:"Const"}
			  ]
			}
		  }
		],
	  },
	}
  ],
}
);
#endregion
#region Precomputed Hash Value for Frequent Struct Keys
run_post_processor_test("Struct dot accessor and modification with error handling",
@'struct.zero = 1; var test = struct.two;',
{
  statements:[
	{
	  expr:{
		callee:{
		  value: struct_set_from_hash,
		  type: __GMLC_NodeType.Function,
		  name:"struct_set_from_hash",
		},
		arguments:[
		  {
			value:"struct",
			type: __GMLC_NodeType.Identifier,
		  },
		  {
			value: variable_get_hash("zero"),
			type: __GMLC_NodeType.Literal,
			scope:"Const"
		  },
		  {
			value:1.0,
			type: __GMLC_NodeType.Literal,
			scope:"Const"
		  }
		],
		type: __GMLC_NodeType.FunctionCall,
	  },
	  type: __GMLC_NodeType.ExpressionStatement,
	},
	{
	  statements:{
		statements:[
		  {
			scope:"LocalVar",
			expr:{
			  callee:{
				value: __struct_get_with_error,
				type: __GMLC_NodeType.Function,
				name:"__struct_get_with_error",
			  },
			  arguments:[
				{
				  value:"struct",
				  type: __GMLC_NodeType.Identifier,
				},
				{
				  value:"two",
				  type: __GMLC_NodeType.Literal,
				  scope:"Const"
				}
			  ],
			  type: __GMLC_NodeType.FunctionCall,
			},
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"test",
		  }
		],
		type: __GMLC_NodeType.BlockStatement,
	  },
	  type: __GMLC_NodeType.VariableDeclarationList,
	}
  ],
  type: __GMLC_NodeType.Script,
}
);
run_post_processor_test("Struct access and modification with error handling",
@'struct[$ "zero"] = 1; var test = struct[$ "two"];',
{
  statements:[
	{
	  expr:{
		callee:{
		  value: struct_set_from_hash,
		  type: __GMLC_NodeType.Function,
		  name:"struct_set_from_hash",
		},
		arguments:[
		  {
			value:"struct",
			type: __GMLC_NodeType.Identifier,
		  },
		  {
			value: variable_get_hash("zero"),
			type: __GMLC_NodeType.Literal,
			scope:"Const"
		  },
		  {
			value:1.0,
			type: __GMLC_NodeType.Literal,
			scope:"Const"
		  }
		],
		type: __GMLC_NodeType.FunctionCall,
	  },
	  type: __GMLC_NodeType.ExpressionStatement,
	},
	{
	  statements:{
		statements:[
		  {
			scope:"LocalVar",
			expr:{
			  callee:{
				value: struct_get_from_hash,
				type: __GMLC_NodeType.Function,
				name: "struct_get_from_hash",
			  },
			  arguments:[
				{
				  value:"struct",
				  type: __GMLC_NodeType.Identifier,
				},
				{
				  value: variable_get_hash("two"),
				  type: __GMLC_NodeType.Literal,
				  scope:"Const"
				}
			  ],
			  type: __GMLC_NodeType.FunctionCall,
			},
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"test",
		  }
		],
		type: __GMLC_NodeType.BlockStatement,
	  },
	  type: __GMLC_NodeType.VariableDeclarationList,
	}
  ],
  type: __GMLC_NodeType.Script,
}
);
#endregion

#region Arrays
#region 1. Array Creation and Direct Assignment
run_post_processor_test("Array Creation and Direct Assignment",
@"var arr = [1, 2, 3];
arr[0] = 10;
return arr[0];",
{})

#endregion
#region 2. Array Modification Through Function
run_post_processor_test("Array Modification Through Function",
@"var arr = [1, 7, 5, 6];
array_sort(arr, true);
return arr[1];",
{})

#endregion
#region 3. Array Element Increment
run_post_processor_test("Array Element Increment",
@"var arr = [10, 20, 30];
arr[2]++;
return arr[2];",
{})
#endregion
#region 4. Dynamic Array Creation with Loop
run_post_processor_test("Dynamic Array Creation with Loop",
@"var arr = [];
for (var i = 0; i < 5; i++) {
  arr[i] = i * 2;
}
return arr[3];",
{})
#endregion
#region 5. Array Access and Function Call
run_post_processor_test("Array Access and Function Call",
@"var arr = [100, 200, 300];
var result = string(arr[1]);
return result;",
{})
#endregion
#endregion


#region UNUSED
/*
#region Inlining Simple Functions
run_post_processor_test("Inline simple constant-return function",
@'function getConstant() { return 42; } var x = getConstant();',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			scope:"LocalVar",
			expr:{
			  value:42.0,
			  type: __GMLC_NodeType.Literal,
			  scope:"Const"
			},
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"x",
		  }
		],
	  },
	}
  ],
}
);
#endregion
#region Constant Propagation Through Function Calls
run_post_processor_test("Propagate constants through function calls",
@'function addTwo(a) { return a + 2; } var y = addTwo(3);',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			scope:"LocalVar",
			expr:{
			  value:5.0,
			  type: __GMLC_NodeType.Literal,
			  scope:"Const"
			},
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"y",
		  }
		],
	  },
	}
  ],
}
);
#endregion
#region Inlining Function Calls with Literal Arguments
run_post_processor_test("Inline function call with literal arguments",
@'function multiply(a, b) { return a * b; } var result = multiply(6, 7);',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			scope:"LocalVar",
			expr:{
			  value:42.0,
			  type: __GMLC_NodeType.Literal,
			  scope:"Const"
			},
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"result",
		  }
		],
	  },
	}
  ],
}
);
#endregion
#region Optimizing Redundant Function Calls
run_post_processor_test("Optimize redundant function calls",
@'function getId(x) { return x; } var id = getId(15);',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			scope:"LocalVar",
			expr:{
			  value:15.0,
			  type: __GMLC_NodeType.Literal,
			  scope:"Const"
			},
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"id",
		  }
		],
	  },
	}
  ],
}
);
#endregion
#region Inlining Functions within Conditionals
run_post_processor_test("Inline function within if condition",
@'function isActive() { return true; } if (isActive()) { var x = 1; }',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.IfStatement,
	  condition:{
		value:true,
		type: __GMLC_NodeType.Literal,
		scope:"Const"
	  },
	  consequent:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			type: __GMLC_NodeType.VariableDeclarationList,
			statements:{
			  type: __GMLC_NodeType.BlockStatement,
			  statements:[
				{
				  scope:"LocalVar",
				  expr:{
					value:1.0,
					type: __GMLC_NodeType.Literal,
					scope:"Const"
				  },
				  type: __GMLC_NodeType.VariableDeclaration,
				  identifier:"x",
				}
			  ],
			},
		  }
		]
	  },
	  alternate:undefined
	}
  ],
}
);
#endregion
#region Inlining Functions in Loop Conditions
run_post_processor_test("Inline function in while loop condition",
@'function hasItems() { return false; } while (hasItems()) { var y = 2; }',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.WhileStatement,
	  condition:{
		value:false,
		type: __GMLC_NodeType.Literal,
		scope:"Const"
	  },
	  codeBlock:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[]
	  }
	}
  ],
}
);
#endregion
#region Inlining Functions in Return Statements
run_post_processor_test("Inline function in return statement",
@'function calculateValue() { return 42; } function wrapper() { return calculateValue(); }',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.FunctionDeclaration,
	  functionName:"wrapper",
	  body:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			type: __GMLC_NodeType.ReturnStatement,
			expr:{
			  value:42.0,
			  type: __GMLC_NodeType.Literal,
			  scope:"Const"
			}
		  }
		]
	  }
	}
  ],
}
);
#endregion
#region Inlining Functions with Multiple Calls in a Single Expression
run_post_processor_test("Inline multiple calls in a single expression",
@'function getFive() { return 5; } var result = getFive() + getFive();',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			scope:"LocalVar",
			expr:{
			  type: __GMLC_NodeType.BinaryExpression,
			  operator:"+",
			  left:{
				value:5.0,
				type: __GMLC_NodeType.Literal,
				scope:"Const"
			  },
			  right:{
				value:5.0,
				type: __GMLC_NodeType.Literal,
				scope:"Const"
			  }
			},
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"result",
		  }
		],
	  },
	}
  ],
}
);
#endregion
#region Inlining Functions with Arguments Used Multiple Times
run_post_processor_test("Inline function with arguments used multiple times",
@'function double(x) { return x * 2; } var total = double(3) + double(3);',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			scope:"LocalVar",
			expr:{
			  type: __GMLC_NodeType.BinaryExpression,
			  operator:"+",
			  left:{
				value:6.0,
				type: __GMLC_NodeType.Literal,
				scope:"Const"
			  },
			  right:{
				value:6.0,
				type: __GMLC_NodeType.Literal,
				scope:"Const"
			  }
			},
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"total",
		  }
		],
	  },
	}
  ],
}
);
#endregion
#region Loop Unrolling with a Constant Loop Count
run_post_processor_test("Unroll loop with constant count",
@'for (var i = 0; i < 4; i++) { var x = x + 1; }',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.ExpressionStatement,
	  expr:{
		type: __GMLC_NodeType.AssignmentExpression,
		operator:"=",
		left:{type: __GMLC_NodeType.Identifier, value:"x"},
		right:{
		  type: __GMLC_NodeType.BinaryExpression,
		  operator:"+",
		  left:{type: __GMLC_NodeType.Identifier, value:"x"},
		  right:{value:4.0, type: __GMLC_NodeType.Literal, scope:"Const"}
		}
	  }
	}
  ],
}
);
#endregion
#region Constant Propagation in Loop Initialization
run_post_processor_test("Propagate constant in loop initialization",
@'var limit = 10; for (var i = 0; i < limit; i++) { var y = i; }',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.ForStatement,
	  initialization:{type: __GMLC_NodeType.VariableDeclaration, identifier:"i", expr:{value:0.0, type: __GMLC_NodeType.Literal, scope:"Const"}},
	  condition:{
		type: __GMLC_NodeType.BinaryExpression,
		operator:"<",
		left:{type: __GMLC_NodeType.Identifier, value:"i"},
		right:{value:10.0, type: __GMLC_NodeType.Literal, scope:"Const"}
	  },
	  increment:{
		type: __GMLC_NodeType.PostfixExpression,
		operator:"++",
		expr:{type: __GMLC_NodeType.Identifier, value:"i"}
	  },
	  codeBlock:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[]
	  }
	}
  ],
}
);
#endregion
#region Loop Invariant Code Motion
run_post_processor_test("Loop invariant code motion",
@'var a = 5; for (var i = 0; i < 10; i++) { var z = a * 2; }',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"z",
			expr:{
			  value:10.0,
			  type: __GMLC_NodeType.Literal,
			  scope:"Const"
			}
		  }
		],
	  },
	}
  ],
}
);
#endregion
#region Loop with Break Condition Simplified
run_post_processor_test("Simplify loop with constant break condition",
@'while (true) { break; }',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.BlockStatement,
	  statements:[]
	}
  ],
}
);
#endregion
#region Removing Redundant Computations in Loops							 //////////////////////////////////////NOT ACTIVE!
run_post_processor_test("Remove redundant computations in loop",
@'for (var i = 0; i < 10; i++) {
	var temp = "constant";
	var result = temp;
}',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.ForStatement,
	  initialization:{type: __GMLC_NodeType.VariableDeclaration, identifier:"i", expr:{value:0.0, type: __GMLC_NodeType.Literal, scope:"Const"}},
	  condition:{
		type: __GMLC_NodeType.BinaryExpression,
		operator:"<",
		left:{type: __GMLC_NodeType.Identifier, value:"i"},
		right:{value:10.0, type: __GMLC_NodeType.Literal, scope:"Const"}
	  },
	  increment:{
		type: __GMLC_NodeType.PostfixExpression,
		operator:"++",
		expr:{type: __GMLC_NodeType.Identifier, value:"i"}
	  },
	  codeBlock:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			type: __GMLC_NodeType.VariableDeclarationList,
			statements:{
			  type: __GMLC_NodeType.BlockStatement,
			  statements:[
				{
				  type: __GMLC_NodeType.VariableDeclaration,
				  identifier:"result",
				  expr:{value:"constant", type: __GMLC_NodeType.Literal, scope:"Const"}
				}
			  ],
			},
		  }
		]
	  }
	}
  ],
}
);
#endregion
#region Inlining Small Functions Directly into Call Sites
run_post_processor_test("Inline small function directly into call site",
@'function addOne(x) { return x + 1; } var result = addOne(5);',
{
  type: __GMLC_NodeType.Script,
  statements:[
	{
	  type: __GMLC_NodeType.VariableDeclarationList,
	  statements:{
		type: __GMLC_NodeType.BlockStatement,
		statements:[
		  {
			type: __GMLC_NodeType.VariableDeclaration,
			identifier:"result",
			expr:{
			  type: __GMLC_NodeType.BinaryExpression,
			  operator:"+",
			  left:{value:5.0, type: __GMLC_NodeType.Literal, scope:"Const"},
			  right:{value:1.0, type: __GMLC_NodeType.Literal, scope:"Const"}
			}
		  }
		],
	  },
	}
  ],
}
);
#endregion
//*/
#endregion
}
//run_all_post_processor_tests();
#endregion

#region Interpreter Unit Tests
function run_interpreter_test(description, input, expectedModule=undefined, expectedReturn=undefined) {
	log($"Attempting Interpreter Test :: {description}")
	
	var tokenizer = new GML_Tokenizer();
	tokenizer.initialize(input);
	var tokens = tokenizer.parseAll();
	
	var preprocessor = new GML_PreProcessor();
	preprocessor.initialize(tokens);
	var preprocessedTokens = preprocessor.parseAll();
	
	var parser = new GML_Parser();
	parser.initialize(preprocessedTokens);
	var ast = parser.parseAll();
	
	var postprocessor = new GML_PostProcessor();
	postprocessor.initialize(ast);
	var ast = postprocessor.parseAll();
	
	//log(["AST :: ", json_stringify(ast, true)])
	//var interpreter = new GML_Interpreter();
	//interpreter.initialize(ast);
	//var outputModule = interpreter.parseAll();
	
	//var outputReturn = outputModule.execute();
	var _program = undefined;
	//try {
		var _program = compileInLineProgram(ast);
		var outputReturn = executeInLineProgram(_program)
	//}catch(e) {
	//	log($"AST ::\n{json_stringify(ast, true)}\n")
	//	//log($"Program Method ::\n{json_stringify(__structMethodAST(_program), true)}\n")
	//	log(e)
	//	return;
	//}
	
	expectedReturn = (is_callable(expectedReturn)) ? expectedReturn() : expectedReturn;
	
	//if (expectedModule != undefined) __compare_results(description, outputModule, expectedModule);
	//log(json_stringify(outputReturn, true))
	//log(json_stringify(expectedReturn, true))
	var _same = __compare_results(description, outputReturn, expectedReturn);
	if (!_same) {
		//log($"AST ::\n{json_stringify(ast, true)}\n")
		log($"Program Method ::\n{json_stringify(__structMethodAST(_program), true)}\n")
	}
}
function run_all_interpreter_tests() {
log("~~~~~ Interpreter Unit Tests ~~~~~\n");

#region HIDE

//*
run_interpreter_test("Boop",
@'
			-- compute the factorial of n
			factorial = funtion(n) {
			  if (n <= 1) {
			    return 1;
			  }
			  return n * factorial(n - 1)
			}
			
			factorial(1) -- result: 1
			factorial(2) -- result: 2
			factorial(3) -- result: 6
			factorial(4) -- result: 24
			factorial(5) -- result: 120
			factorial(6) -- result: 720',
undefined,
function(){
	return "abcdefg";
}
);

#region complex expression evaluation
run_interpreter_test("complex expression evaluation", 
@'x = 2;
y = 4;
var result = ((x + y) * (x - y)) / 2;
return result',
undefined,
function(){
	x = 2;
	y = 4;
	var result = ((x + y) * (x - y)) / 2;
	return result	
}
)
#endregion
#region Accessors <Array, Grid, List, Map, Struct>
run_interpreter_test("Array access and modification",
@'var arr = [0, 1, 2];
arr[0] = 1;
var test = arr[2];
return string(arr);',
undefined,
function(){
	var arr = [0, 1, 2];
	arr[0] = 1;
	var test = arr[2];
	return string(arr);
}
);

run_interpreter_test("List access and modification",
@'var list = ds_list_create();
list[| 0] = 1;
list[| 1] = 2;
ds_list_set(list, 2, 3);
var test = list[| 2];
var _return = test;
ds_list_destroy(list);
return _return;',
undefined,
function(){
	var list = ds_list_create();
	list[| 0] = 1;
	list[| 1] = 2;
	ds_list_set(list, 2, 3);
	var test = list[| 2];
	var _return = test;
	ds_list_destroy(list);
	return _return;
}
);

run_interpreter_test("Grid access and modification",
@'var grid = ds_grid_create(5, 5);
ds_grid_set_region(grid, 0,0, 4, 4, "example");
grid[# 0, 1] = 2;
var test = grid[# 3, 4];
var _return = test;
ds_grid_destroy(grid);
return _return;',
undefined,
function(){
	var grid = ds_grid_create(5, 5);
	ds_grid_set_region(grid, 0,0, 4, 4, "example");
	grid[# 0, 1] = 2;
	var test = grid[# 3, 4];
	var _return = test;
	ds_grid_destroy(grid);
	return _return;
}
);

run_interpreter_test("Map access and modification",
@'var map = ds_map_create();
map[? "zero"] = 1;
ds_map_set(map, "zero", 2);
map[? "two"] = 3;
var test = map[? "two"];
var _return = test;
ds_map_destroy(map);
return _return;',
undefined,
function(){
	var map = ds_map_create();
	map[? "zero"] = 1;
	ds_map_set(map, "zero", 2);
	map[? "two"] = 3;
	var test = map[? "two"];
	var _return = test;
	ds_map_destroy(map);
	return _return;
}
);

run_interpreter_test("Struct access and modification with error handling",
@'var struct = {zero: 0, one: 1, two: 2 };
struct[$ "zero"] = 1;
var test = struct[$ "two"];
return string(struct)',
undefined,
function() {
	var struct = {zero: 0, one: 1, two: 2 };
	struct[$ "zero"] = 1;
	var test = struct[$ "two"];
	return string(struct)
}
);

run_interpreter_test("Basic Struct hash setting",
@'var struct = {one: 1};
struct_set_from_hash(struct, variable_get_hash("one"), "oneAgain");
return string(struct)',
undefined,
function(){
	var struct = {one: 1};
	struct_set_from_hash(struct, variable_get_hash("one"), "oneAgain");
	return string(struct)
}
);


run_interpreter_test("Struct Advance accessing and modification with error handling",
@'var two = 2
var struct = {one: 1, two};
struct.zero = 0;
struct[$ "zero"] = "ZERO";
struct_set(struct, "one", "ONE")
struct_set_from_hash(struct, variable_get_hash("one"), "oneAgain");
var _test1 = struct.two;
var _test2 = struct[$ "two"];
var _test3 = struct_get(struct, "two");
var _test4 = struct_get_from_hash(struct, variable_get_hash("two"));
return string(struct)',
undefined,
function(){
	var two = 2
	var struct = {one: 1, two};
	struct.zero = 0;
	struct[$ "zero"] = "ZERO";
	struct_set(struct, "one", "ONE")
	struct_set_from_hash(struct, variable_get_hash("one"), "oneAgain");
	var _test1 = struct.two;
	var _test2 = struct[$ "two"];
	var _test3 = struct_get(struct, "two");
	var _test4 = struct_get_from_hash(struct, variable_get_hash("two"));
	return string(struct)
}
);
#endregion
#region Repeat Statement Basic

#region Basic Repeat Loop Test
run_interpreter_test("Basic Repeat Loop Test",
@'var i = 0;
repeat (5) {
	i++;
}
return i;',
undefined,
function(){
	var i = 0;
	repeat (5) {
		i++;
	}
	return i;
})
#endregion
#region Repeat with Break Test
run_interpreter_test("Repeat with Break Test",
@'var count = 0;
repeat (10) {
	count++;
	if (count == 5) break;
}
return count;',
undefined,
function(){
	var count = 0;
	repeat (10) {
		count++;
		if (count == 5) break;
	}
	return count;
})
#endregion
#region Repeat with Continue Test
run_interpreter_test("Repeat with Continue Test",
@'var sum = 0;
repeat (10) {
	sum++;
	if (sum mod 2 == 0) continue;
}
return sum;',
undefined,
function(){
	var sum = 0;
	repeat (10) {
		sum++;
		if (sum mod 2 == 0) continue;
	}
	return sum;
})
#endregion
#region Repeat Nested Loops
run_interpreter_test("Repeat Nested Loops",
@'var outer = 0;
repeat (3) {
	var inner = 0;
	repeat (2) {
		inner++;
	}
	outer += inner;
}
return outer;',
undefined,
function(){
	var outer = 0;
	repeat (3) {
		var inner = 0;
		repeat (2) {
			inner++;
		}
		outer += inner;
	}
	return outer;
})
#endregion
#region Repeat with Return Inside Loop
run_interpreter_test("Repeat with Return Inside Loop",
@'repeat (5) {
	return "Exited";
}
return "Not Exited";',
undefined,
function(){
	repeat (5) {
		return "Exited";
	}
	return "Not Exited";
})
#endregion
#region Empty Repeat Loop
run_interpreter_test("Empty Repeat Loop",
@'repeat (5) {}
return "Done";',
undefined,
function(){
	repeat (5) {}
	return "Done";
})
#endregion

#endregion
#region Repeat Statement Advanced

#region Complex Repeat with Nested If and Continue
run_interpreter_test("Complex Repeat with Nested If and Continue",
@'var count = 0;
repeat (10) {
	count++;
	if (count % 2 == 0) {
		if (count == 6) continue;
		count += 10;
	}
}
return count;',
undefined,
function(){
	var count = 0;
	repeat (10) {
		count++;
		if (count % 2 == 0) {
			if (count == 6) continue;
			count += 10;
		}
	}
	return count;
})
#endregion
#region Repeat with Nested Breaks
run_interpreter_test("Repeat with Nested Breaks",
@'var i = 0;
repeat (5) {
	repeat (5) {
		i++;
		if (i == 10) break;
	}
	if (i == 10) break;
}
return i;',
undefined,
function(){
	var i = 0;
	repeat (5) {
		repeat (5) {
			i++;
			if (i == 10) break;
		}
		if (i == 10) break;
	}
	return i;
})
#endregion
#region Repeat with Conditional Continues and Breaks
run_interpreter_test("Repeat with Conditional Continues and Breaks",
@'var total = 0;
repeat (10) {
	if (total == 5) continue;
	total++;
	if (total == 8) break;
}
return total;',
undefined,
function(){
	var total = 0;
	repeat (10) {
		if (total == 5) continue;
		total++;
		if (total == 8) break;
	}
	return total;
})
#endregion
#region Repeat with External Modification and Check
run_interpreter_test("Repeat with External Modification and Check",
@'var flag = true;
var counter = 0;
repeat (10) {
	if (flag) {
		counter++;
		if (counter == 5) flag = false;
	}
}
return counter;',
undefined,
function(){
	var flag = true;
	var counter = 0;
	repeat (10) {
		if (flag) {
			counter++;
			if (counter == 5) flag = false;
		}
	}
	return counter;
})
#endregion
#region Deeply Nested Repeat Loops
run_interpreter_test("Deeply Nested Repeat Loops",
@'var _depth = 0;
repeat (3) {
	repeat (3) {
		repeat (3) {
			_depth++;
		}
	}
}
return _depth;',
undefined,
function(){
	var _depth = 0;
	repeat (3) {
		repeat (3) {
			repeat (3) {
				_depth++;
			}
		}
	}
	return _depth;
})
#endregion
#region Repeat with Error Handling
run_interpreter_test("Repeat with Error Handling",
@'var count = 0;
try {
	repeat (5) {
		count++;
		if (count == 3) throw "Error at 3";
	}
} catch (error) {
	return error;
}
return count;',
undefined,
function(){
	var count = 0;
	try {
		repeat (5) {
			count++;
			if (count == 3) throw "Error at 3";
		}
	} catch (error) {
		return error;
	}
	return count;
})

#endregion

#endregion
#region Varriable Apply With Postfix
run_interpreter_test("Varriable Apply With Postfix", 
@'x=1;
x++
return x;',
{
  IR:[
	{ op: ByteOp.LOAD, value:1.0, scope: ScopeType.CONST },
	{ op: ByteOp.STORE, value:"x", scope: ScopeType.INSTANCE },
	{ op: ByteOp.LOAD, value:"x", scope: ScopeType.INSTANCE },
	{ op: ByteOp.DUP },
	{ op: ByteOp.OPERATOR, operator: OpCode.INC },
	{ op: ByteOp.STORE, value:"x", scope: ScopeType.INSTANCE },
	{ op: ByteOp.LOAD, value:"x", scope: ScopeType.INSTANCE },
	{ op: ByteOp.RETURN },
	{ op: ByteOp.END }
  ],
},
function(){
	x=1;
	x++
	return x;
}
)
#endregion
#region Instance Var Apply
run_interpreter_test("Instance Var Apply", 
@'y = 1;
return y',
{
  IR:[
	{ op: ByteOp.LOAD,  value:1.0, scope: ScopeType.CONST },
	{ op: ByteOp.STORE, value:"y", scope: ScopeType.INSTANCE },
	{ op: ByteOp.LOAD,  value:"y", scope: ScopeType.INSTANCE },
	{ op: ByteOp.RETURN },
	{ op: ByteOp.END }
  ],
  GlobalVar:{
	y:1.0
  },

},
function(){
	y = 1;
	return y	
}
)
#endregion
#region Optimize simple constant expressions
run_interpreter_test("1 + 1;", 
@'x = 1+1
return x',
undefined,
function(){
	x = 1+1
	return x
}
)
#endregion
#region parseAssignmentExpression
run_interpreter_test("parseAssignmentExpression", 
@'y = 1;
x = y + 1;
return x;',
undefined,
function(){
	y = 1;
	x = y + 1;
	return x;
}
)
#endregion
#region parseLogicalOrExpression
run_interpreter_test("parseLogicalOrExpression", 
@'var _x = 2,
_y = 4,
_z = _x || _y;
return _z;',
undefined,
function(){
	var _x = 2,
	_y = 4,
	_z = _x || _y;
	return _z;
}
)
#endregion
#region parseLogicalAndExpression
run_interpreter_test("parseLogicalAndExpression", 
@'var _x = 2,
_y = 4,
_z = _x && _y;
return _z;',
undefined,
function(){
	var _x = 2,
	_y = 4,
	_z = _x && _y;
	return _z;
}
)
#endregion
#region parseBitwsieOrExpression
run_interpreter_test("parseBitwsieOrExpression", 
@'var _x = 2,
_y = 4,
_z = _x | _y;
return _z;',
undefined,
function(){
	var _x = 2,
	_y = 4,
	_z = _x | _y;
	return _z;
}
)
#endregion
#region parseBitwsieXorExpression
run_interpreter_test("parseBitwsieXorExpression", 
@'var _x = 2,
_y = 4,
_z = _x ^ _y;
return _z;',
undefined,
function(){
	var _x = 2,
	_y = 4,
	_z = _x ^ _y;
	return _z;
}
)
#endregion
#region parseBitwsieAndExpression
run_interpreter_test("parseBitwsieAndExpression", 
@'var _x = 2,
_y = 4,
_z = _x & _y;
return _z;',
undefined,
function(){
	var _x = 2,
	_y = 4,
	_z = _x & _y;
	return _z;
}
)
#endregion
#region parseEqualityExpression
run_interpreter_test("parseEqualityExpression", 
@'var _x = 2,
_y = 4,
_z = _x == _y;
return _z;',
undefined,
function(){
	var _x = 2,
	_y = 4,
	_z = _x == _y;
	return _z;
}
)
#endregion
#region parseRelationalExpression
run_interpreter_test("parseRelationalExpression", 
@'var _x = 2,
_y = 4,
_z = _x < _y;
return _z;',
undefined,
function(){
	var _x = 2,
	_y = 4,
	_z = _x < _y;
	return _z;
}
)
#endregion
#region parseShiftExpression
run_interpreter_test("parseShiftExpression", 
@'var _x = 2,
_y = 4,
_z = _x >> _y;
return _z;',
undefined,
function(){
	var _x = 2,
	_y = 4,
	_z = _x >> _y;
	return _z;
}
)
#endregion
#region parseAdditiveExpression
run_interpreter_test("parseAdditiveExpression", 
@'var _x = 2,
_y = 4,
_z = _x + _y;
return _z;',
undefined,
function(){
	var _x = 2,
	_y = 4,
	_z = _x + _y;
	return _z;
}
)
#endregion
#region parseMultiplicativeExpression
run_interpreter_test("parseMultiplicativeExpression", 
@'var _x = 2,
_y = 4,
_z = _x * _y;
return _z;',
undefined,
function(){
	var _x = 2,
	_y = 4,
	_z = _x * _y;
	return _z;
}
)
#endregion
#region parseUnaryExpression
run_interpreter_test("parseUnaryExpression", 
@'var _x = 1;
var _y = !_x;
return _y',
undefined,
function(){
	var _x = 1;
	var _y = !_x;
	return _y
}
)
#endregion
#region parsePostfixExpression
run_interpreter_test("parsePostfixExpression", 
@'var _x=0;
	_x++;
	return _x++;',
undefined,
function(){
	var _x=0;
	_x++;
	return _x++;
}
)
#endregion
#region Advanced Expression
run_interpreter_test("Advanced Expression", 
@'var a = 1,
b = a++,
c = a++,
d = a++,
e = a++,
f = a++,
g = a++,
h = a + b * c - (d & e % f div g)
return h',
undefined,
function(){
	var a = 1,
	b = a++,
	c = a++,
	d = a++,
	e = a++,
	f = a++,
	g = a++,
	h = a + b * c - (d & e % f div g)
	return h
}
)
#endregion
#region confusingPostfixExpression
run_interpreter_test("confusingPostfixExpression", 
@'var _a = 0
var _b = 1
var _c = _a+++_b;
return _a; //should be 1',
undefined,
function(){
	var _a = 0
	var _b = 1
	var _c = _a+++_b;
	return _a; //should be 1
}
)
#endregion

#region Arrays
#region 1. Array Creation and Direct Assignment
run_interpreter_test("Array Creation and Direct Assignment",
@"var arr = [1, 2, 3];
arr[0] = 10;
return arr[0];",
undefined,
function(){
  var arr = [1, 2, 3];
  arr[0] = 10;
  return arr[0];
}
)

#endregion
#region 2. Array Modification Through Function
run_interpreter_test("Array Modification Through Function",
@"var arr = [1, 7, 5, 6];
array_sort(arr, true);
return arr[1];",
undefined,
function(){
	var arr = [1, 7, 5, 6];
	array_sort(arr, true);
	return arr[1];
}
)

#endregion
#region 3. Array Element Increment
run_interpreter_test("Array Element Increment",
@"var arr = [10, 20, 30];
arr[2]++;
return arr[2];",
undefined,
function(){
  var arr = [10, 20, 30];
  arr[2]++;
  return arr[2];
}
)
#endregion
#region 4. Dynamic Array Creation with Loop
run_interpreter_test("Dynamic Array Creation with Loop",
@"var arr = [];
for (var i = 0; i < 5; i++) {
  arr[i] = i * 2;
}
return arr[3];",
undefined,
function() {
	var arr = [];
	for (var i = 0; i < 5; i++) {
		arr[i] = i * 2;
	}
	return arr[3];
}
)
#endregion
#region 5. Array Access and Function Call
run_interpreter_test("Array Access and Function Call",
@"var arr = [100, 200, 300];
var result = string(arr[1]);
return result;",
undefined,
function(){
	var arr = [100, 200, 300];
	var result = string(arr[1]);
	return result;
}
)
#endregion
#endregion

#region Jump Instruction Tests

#region If Statement Basic
#region Jump Test Basic If Test
run_interpreter_test("Jump Test Basic If Test",
@'if (true) return 1;
return 0;
',
undefined,
function(){
	if (true) return 1;
	return 0;
})
#endregion
#region Jump Test If-Else Test
run_interpreter_test("Jump Test If-Else Test",
@'if (false) return 0;
else return 1;
',
undefined,
function(){
	if (false) return 0;
	else return 1;
})
#endregion
#region Jump Test Nested If Test
run_interpreter_test("Jump Test Nested If Test",
@'if (true) {
   if (false) return 0;
   return 1;
}
return 2;
',
undefined,
function(){
	if (true) {
	   if (false) return 0;
	   return 1;
	}
	return 2;
})
#endregion
#region Jump Test If with Continue
run_interpreter_test("Jump Test If with Continue",
@'for (var i = 0; i < 3; i++) {
	if (i == 1) continue;
	return i;
}
return 3;
',
undefined,
function(){
	for (var i = 0; i < 3; i++) {
		if (i == 1) continue;
		return i;
	}
	return 3;

})
#endregion
#region Jump Test If with Continue
run_interpreter_test("Jump Test Multi If",
@'var i = 0;
if i = 0 {
	//i++
}
else {
	//i--
}
return i
',
undefined,
function(){
	for (var i = 0; i < 3; i++) {
		if (i == 1) continue;
		return i;
	}
	return 3;

})
#endregion
#region Jump Test If with Break
run_interpreter_test("Jump Test If with Break",
@'for (var i = 0; i < 3; i++) {
	if (i == 1) break;
	return i;
}
return 3;
',
undefined,
function(){
	for (var i = 0; i < 3; i++) {
		if (i == 1) break;
		return i;
	}
	return 3;
})
#endregion
#region Jump Test If with Return Early Out
run_interpreter_test("Jump Test If with Return Early Out",
@'if (true) return 1;
return 2; // This should never execute
',
undefined,
function(){
	if (true) return 1;
	return 2; // This should never execute
})
#endregion
#endregion
#region If Statement Advanced

#region Deeply Nested If Test
run_interpreter_test("Deeply Nested If Test",
@'if (true) {
	if (false) {
		if (true) return -1;
	} else return 1;
} else {
	return 0;
}
return 2;
',
undefined,
function(){
	if (true) {
		if (false) {
			if (true) return -1;
		} else return 1;
	} else {
		return 0;
	}
	return 2;
})
#endregion
#region If with Multiple Continues and Breaks
run_interpreter_test("If with Multiple Continues and Breaks",
@'for (var i = 0; i < 5; i++) {
	if (i == 2 || i == 3) continue;
	if (i == 4) break;
	if (i == 1) return i;
}
return 5;
',
undefined,
function(){
	for (var i = 0; i < 5; i++) {
		if (i == 2 || i == 3) continue;
		if (i == 4) break;
		if (i == 1) return i;
	}
	return 5;
})
#endregion
#region If with Logical Operators
run_interpreter_test("If with Logical Operators",
@'var xx = 10, yy = 20;
if (xx > 5 && yy < 25) {
	if (xx < yy || yy > 15) return xx + yy;
}
return xx - yy;
',
undefined,
function(){
	var xx = 10, yy = 20;
	if (xx > 5 && yy < 25) {
		if (xx < yy || yy > 15) return xx + yy;
	}
	return xx - yy;
})
#endregion
#region If with Array Operations
run_interpreter_test("If with Array Operations",
@'var arr = [1, 2, 3];
if (arr[1] == 2) {
	arr[2] = 10;
	if (arr[2] == 10) return arr[0] + arr[2];
}
return arr[1];
',
undefined,
function(){
	var arr = [1, 2, 3];
	if (arr[1] == 2) {
		arr[2] = 10;
		if (arr[2] == 10) return arr[0] + arr[2];
	}
	return arr[1];
})
#endregion
#region If-Else Ladder with Complex Conditions
run_interpreter_test("If-Else Ladder with Complex Conditions",
@'var num = 15;
if (num < 10) return num * 2;
else if (num > 10 && num < 20) return num / 2;
else return num + 5;
',
undefined,
function(){
	var num = 15;
	if (num < 10) return num * 2;
	else if (num > 10 && num < 20) return num / 2;
	else return num + 5;
})
#endregion
#region Deep Recursion in If Blocks
run_interpreter_test("Deep Recursion in If Blocks",
@'if (true) {
	if (true) {
		if (true) return 1;
	}
	return 0;
} else {
	if (true) return 2;
	else return 3;
}
',
undefined,
function(){
	if (true) {
		if (true) {
			if (true) return 1;
		}
		return 0;
	} else {
		if (true) return 2;
		else return 3;
	}
})
#endregion

#endregion

#region For Statement Basic

#region Simple For Loop
run_interpreter_test("Simple For Loop",
@'for (var i = 0; i < 3; i++) {
	return i;
}
return 3;
',
undefined,
function(){
	for (var i = 0; i < 3; i++) {
		return i;
	}
	return 3;
})
#endregion
#region Loop with Constant Condition
run_interpreter_test("Loop with Constant Condition",
@'for (var i = 0; true; i++) {
	if (i == 2) return i;
}
return 0;
',
undefined,
function(){
	for (var i = 0; true; i++) {
		if (i == 2) return i;
	}
	return 0;
})
#endregion
#region Empty Loop Body
run_interpreter_test("Empty Loop Body",
@'for (var i = 0; i < 5; i++) {}
return i;
',
undefined,
function(){
	for (var i = 0; i < 5; i++) {}
	return i;
})
#endregion
#region Loop with Unused Variable
run_interpreter_test("Loop with Unused Variable",
@'var xx = 10;
for (var i = 0; i < 3; i++) {
	xx = i;
}
return 5;
',
undefined,
function(){
	var xx = 10;
	for (var i = 0; i < 3; i++) {
		xx = i;
	}
	return 5;
})
#endregion
#region Loop with Redundant Iterations
run_interpreter_test("Loop with Redundant Iterations",
@'for (var i = 0; i < 10; i++) {
	if (i > 1) break;
}
return i;
',
undefined,
function(){
	for (var i = 0; i < 10; i++) {
		if (i > 1) break;
	}
	return i;
})
#endregion
#region Constant Condition and Break
run_interpreter_test("Constant Condition and Break",
@'for (var i = 0; true; i++) {
	if (i == 3) break;
}
return i;
',
undefined,
function(){
	for (var i = 0; true; i++) {
		if (i == 3) break;
	}
	return i;
})
#endregion
#region Basic Incrementing Loop
run_interpreter_test("Basic Incrementing Loop",
@'var sum = 0;
for (var i = 0; i < 3; i++) {
	sum += i;
}
return sum;',
undefined,
function(){
	var sum = 0;
	for (var i = 0; i < 3; i++) {
		sum += i;
	}
	return sum;
})
#endregion
#region Decrementing Loop
run_interpreter_test("Decrementing Loop",
@'var count = 3;
for (var i = 10; i > 7; i--) {
	count++;
}
return count;',
undefined,
function(){
	var count = 3;
	for (var i = 10; i > 7; i--) {
		count++;
	}
	return count;
})
#endregion
#region Loop with Break
run_interpreter_test("Loop with Break",
@'for (var i = 0; i < 10; i++) {
	if (i == 5) break;
}
return i;',
undefined,
function(){
	for (var i = 0; i < 10; i++) {
		if (i == 5) break;
	}
	return i;
})
#endregion
#region Loop with Continue
run_interpreter_test("Loop with Continue",
@'var sum = 0;
for (var i = 0; i < 5; i++) {
	if (i % 2 == 0) continue;
	sum += i;
}
return sum;',
undefined,
function(){
	var sum = 0;
	for (var i = 0; i < 5; i++) {
		if (i % 2 == 0) continue;
		sum += i;
	}
	return sum;
})
#endregion
#region Empty Loop
run_interpreter_test("Empty Loop",
@'for (var i = 0; i < 3; i++) {}
return i;',
undefined,
function(){
	for (var i = 0; i < 3; i++) {}
	return i;
})
#endregion
#region Nested Loops
run_interpreter_test("Nested Loops",
@'var total = 0;
for (var i = 0; i < 3; i++) {
	for (var j = 0; j < 3; j++) {
		total += i + j;
	}
}
return total;',
undefined,
function(){
	var total = 0;
	for (var i = 0; i < 3; i++) {
		for (var j = 0; j < 3; j++) {
			total += i + j;
		}
	}
	return total;
})	   

#endregion

#endregion
#region For Statement Advanced

#region For Loop with Early Return
run_interpreter_test("For Loop with Early Return",
@'for (var i = 0; i < 5; i++) {
	if (i == 3) return i;
}
return -1;',
undefined,
function(){
	for (var i = 0; i < 5; i++) {
		if (i == 3) return i;
	}
	return -1;
})
#endregion
#region For Loop with Nested Conditional Breaks
run_interpreter_test("For Loop with Nested Conditional Breaks",
@'for (var i = 0; i < 10; i++) {
	for (var j = 0; j < 10; j++) {
		if (j == 5) break;
		if (i == j) continue;
	}
	if (i == 8) break;
}
return i;',
undefined,
function(){
	for (var i = 0; i < 10; i++) {
		for (var j = 0; j < 10; j++) {
			if (j == 5) break;
			if (i == j) continue;
		}
		if (i == 8) break;
	}
	return i;
})
#endregion
#region For Loop with Multiple Continues and Breaks
run_interpreter_test("For Loop with Multiple Continues and Breaks",
@'var sum = 0;
for (var i = 0; i < 10; i++) {
	if (i % 3 == 0) continue;
	if (i == 7) break;
	sum += i;
}
return sum;',
undefined,
function(){
	var sum = 0;
	for (var i = 0; i < 10; i++) {
		if (i % 3 == 0) continue;
		if (i == 7) break;
		sum += i;
	}
	return sum;
})
#endregion
#region Deeply Nested For Loops
run_interpreter_test("Deeply Nested For Loops",
@'var result = 0;
for (var i = 0; i < 3; i++) {
	for (var j = 0; j < 3; j++) {
		for (var k = 0; k < 3; k++) {
			result += i + j + k;
			if (result > 10) return result;
		}
	}
}
return result;',
undefined,
function(){
	var result = 0;
	for (var i = 0; i < 3; i++) {
		for (var j = 0; j < 3; j++) {
			for (var k = 0; k < 3; k++) {
				result += i + j + k;
				if (result > 10) return result;
			}
		}
	}
	return result;
})
#endregion
#region Complex Loop with Multiple Jumps
run_interpreter_test("Complex Loop with Multiple Jumps",
@'var count = 0;
for (var i = 0; i < 5; i++) {
	if (i % 2 == 0) {
		count += i;
		continue;
	}
	if (i == 3) return count;
	count += 10;
}
return count;',
undefined,
function(){
	var count = 0;
	for (var i = 0; i < 5; i++) {
		if (i % 2 == 0) {
			count += i;
			continue;
		}
		if (i == 3) return count;
		count += 10;
	}
	return count;
})
#endregion
#region For Loop with Early Exit on a Specific Condition
run_interpreter_test("For Loop with Early Exit on a Specific Condition",
@'for (var i = 0; i < 10; i++) {
	for (var j = 0; j < 10; j++) {
		if (i * j > 20) return i * j;
	}
}
return -1;',
undefined,
function(){
	for (var i = 0; i < 10; i++) {
		for (var j = 0; j < 10; j++) {
			if (i * j > 20) return i * j;
		}
	}
	return -1;
})

#endregion
#region Complex For Statement
run_interpreter_test("Complex For Statement",
@'var _img_count = 3;
var _return = 0;
for (var i=0; i<_img_count; i++) {
	var _x = i*16;
	var _p = 0;
	for (var _y=0; _y<16; _y++) for (var xx=0; xx<16; xx++) {
		_p++
		_return += _p;
	}
}
return _return;
',
undefined,
function(){
  var _img_count = 3;
	var _return = 0;
	for (var i=0; i<_img_count; i++) {
		var _x = i*16;
		var _p = 0;
		for (var _y=0; _y<16; _y++) for (var xx=0; xx<16; xx++) {
			_p++
			_return += _p;
		}
	}
	
	return _return;
}
)

#endregion

#endregion

#region While Statement Basic

#region Simple While Loop Counting
run_interpreter_test("Simple While Loop Counting",
@'var i = 0;
while (i < 5) {
	i++;
}
return i;',
undefined,
function(){
	var i = 0;
	while (i < 5) {
		i++;
	}
	return i;
})
#endregion
#region While Loop with Break
run_interpreter_test("While Loop with Break",
@'var i = 0;
while (true) {
	i++;
	if (i == 3) break;
}
return i;',
undefined,
function(){
	var i = 0;
	while (true) {
		i++;
		if (i == 3) break;
	}
	return i;
})
#endregion
#region While Loop with Continue
run_interpreter_test("While Loop with Continue",
@'var i = 0;
var sum = 0;
while (i < 5) {
	i++;
	if (i % 2 == 0) continue;
	sum += i;
}
return sum;',
undefined,
function(){
	var i = 0;
	var sum = 0;
	while (i < 5) {
		i++;
		if (i % 2 == 0) continue;
		sum += i;
	}
	return sum;
})
#endregion
#region While Loop with Condition Variable Update
run_interpreter_test("While Loop with Condition Variable Update",
@'var xx = 10;
while (xx > 0) {
	xx -= 2;
}
return xx;',
undefined,
function(){
	var xx = 10;
	while (xx > 0) {
		xx -= 2;
	}
	return xx;
})
#endregion
#region Nested While Loops
run_interpreter_test("Nested While Loops",
@'var i = 0;
var j = 0;
while (i < 3) {
	while (j < 3) {
		j++;
	}
	i++;
}
return i + j;',
undefined,
function(){
	var i = 0;
	var j = 0;
	while (i < 3) {
		while (j < 3) {
			j++;
		}
		i++;
	}
	return i + j;
})
#endregion
#region Nested While Loops
run_interpreter_test("Nested While Loops",
@'var i = 0;
var j = 0;
while (i < 3) {
	while (j < 3) {
		j++;
	}
	i++;
}
return i + j;',
undefined,
function(){
	var i = 0;
	var j = 0;
	while (i < 3) {
		while (j < 3) {
			j++;
		}
		i++;
	}
	return i + j;
})
#endregion
#region While Loop with Return Inside
run_interpreter_test("While Loop with Return Inside",
@'var i = 0;
while (i < 10) {
	if (i == 5) return i;
	i++;
}
return -1;',
undefined,
function(){
	var i = 0;
	while (i < 10) {
		if (i == 5) return i;
		i++;
	}
	return -1;
})

#endregion

#endregion
#region While Statement Advanced

#region While Loop with Multiple Breaks and Continues
run_interpreter_test("While Loop with Multiple Breaks and Continues",
@'var i = 0;
while (i < 10) {
	i++;
	if (i == 3) continue;
	if (i == 7) break;
}
return i;',
undefined,
function(){
	var i = 0;
	while (i < 10) {
		i++;
		if (i == 3) continue;
		if (i == 7) break;
	}
	return i;
})
#endregion
#region Nested While Loops with Internal Flags
run_interpreter_test("Nested While Loops with Internal Flags",
@'var outer = 0;
var innerResult = 0;
while (outer < 3) {
	var inner = 0;
	while (inner < 5) {
		inner++;
		if (inner == 3) innerResult += inner;
	}
	outer++;
}
return innerResult;',
undefined,
function(){
	var outer = 0;
	var innerResult = 0;
	while (outer < 3) {
		var inner = 0;
		while (inner < 5) {
			inner++;
			if (inner == 3) innerResult += inner;
		}
		outer++;
	}
	return innerResult;
})
#endregion
#region Complex Conditional Logic in While
run_interpreter_test("Complex Conditional Logic in While",
@'var i = 0;
while (i < 10 && (i % 2 == 0 || i % 3 == 0)) {
	i++;
}
return i;',
undefined,
function(){
	var i = 0;
	while (i < 10 && (i % 2 == 0 || i % 3 == 0)) {
		i++;
	}
	return i;
})
#endregion
#region While Loop Generating a Sequence
run_interpreter_test("While Loop Generating a Sequence",
@'var i = 0;
var result = [];
while (i < 5) {
	result[i] = i * i;
	i++;
}
return result;',
undefined,
function(){
	var i = 0;
	var result = [];
	while (i < 5) {
		result[i] = i * i;
		i++;
	}
	return result;
})
#endregion
#region While Loop with Multiple Conditional Returns
run_interpreter_test("While Loop with Multiple Conditional Returns",
@'var i = 0;
while (i < 10) {
	if (i == 3) return "Early";
	if (i == 7) return "Late";
	i++;
}
return "None";',
undefined,
function(){
	var i = 0;
	while (i < 10) {
		if (i == 3) return "Early";
		if (i == 7) return "Late";
		i++;
	}
	return "None";
})
#endregion
#region While Loop with Error Handling
run_interpreter_test("While Loop with Error Handling",
@'var i = 0;
try {
	while (i < 5) {
		if (i == 3) throw "Error at 3"
		i++;
	}
} catch (error) {
	return error;
}
return i;',
undefined,
function(){
	var i = 0;
	try {
		while (i < 5) {
			if (i == 3) throw "Error at 3"
			i++;
		}
	} catch (error) {
		return error;
	}
	return i;
})

#endregion

#endregion

#region Do/Until Statement Basic

#region Basic Do/Until Loop Test
run_interpreter_test("Basic Do/Until Loop Test",
@'var i = 0;
do {
	i++;
} until (i == 5);
return i;',
undefined,
function(){
	var i = 0;
	do {
		i++;
	} until (i == 5);
	return i;
})
#endregion
#region Do/Until Loop with Break Test
run_interpreter_test("Do/Until Loop with Break Test",
@'var i = 0;
do {
	i++;
	if (i == 3) break;
} until (i == 5);
return i;',
undefined,
function(){
	var i = 0;
	do {
		i++;
		if (i == 3) break;
	} until (i == 5);
	return i;
})
#endregion
#region Do/Until Loop with Continue Test
run_interpreter_test("Do/Until Loop with Continue Test",
@'var i = 0;
do {
	i++;
	if (i % 2 == 0) continue;
} until (i == 5);
return i;',
undefined,
function(){
	var i = 0;
	do {
		i++;
		if (i % 2 == 0) continue;
	} until (i == 5);
	return i;
})
#endregion
#region Nested Do/Until Loops
run_interpreter_test("Nested Do/Until Loops",
@'var outer = 0;
do {
	var inner = 0;
	do {
		inner++;
	} until (inner == 2);
	outer += inner;
} until (outer == 6);
return outer;',
undefined,
function(){
	var outer = 0;
	do {
		var inner = 0;
		do {
			inner++;
		} until (inner == 2);
		outer += inner;
	} until (outer == 6);
	return outer;
})
#endregion
#region Do/Until Loop with Return Inside Loop
run_interpreter_test("Do/Until Loop with Return Inside Loop",
@'do {
	return "Exited";
} until (true);
return "Not Exited";',
undefined,
function(){
	do {
		return "Exited";
	} until (true);
	return "Not Exited";
})
#endregion
#region Do/Until Loop with Variable Initialization
run_interpreter_test("Do/Until Loop with Variable Initialization",
@'var result = 0;
do {
	var local = 10;
	result += local;
} until (result == 50);
return result;',
undefined,
function(){
	var result = 0;
	do {
		var local = 10;
		result += local;
	} until (result == 50);
	return result;
})
#endregion
#region Empty Do/Until Loop
run_interpreter_test("Empty Do/Until Loop",
@'do {} until (true);
return "Done";',
undefined,
function(){
	do {} until (true);
	return "Done";
})
#endregion
#region Basic Do/Until Loop Test
run_interpreter_test("Basic Do/Until Loop Test",
@'var i = 0;
do {
	i++;
} until (i >= 5);
return i;',
undefined,
function(){
	var i = 0;
	do {
		i++;
	} until (i >= 5);
	return i;
})
#endregion
#region Do/Until with Break Test
run_interpreter_test("Do/Until with Break Test",
@'var count = 0;
do {
	count++;
	if (count == 5) break;
} until (count > 10);
return count;',
undefined,
function(){
	var count = 0;
	do {
		count++;
		if (count == 5) break;
	} until (count > 10);
	return count;
})
#endregion
#region Do/Until with Continue Test
run_interpreter_test("Do/Until with Continue Test",
@'var sum = 0;
do {
	sum++;
	if (sum % 2 == 0) continue;
} until (sum >= 10);
return sum;',
undefined,
function(){
	var sum = 0;
	do {
		sum++;
		if (sum % 2 == 0) continue;
	} until (sum >= 10);
	return sum;
})
#endregion
#region Do/Until Nested Loops
run_interpreter_test("Do/Until Nested Loops",
@'var outer = 0;
do {
	var inner = 0;
	do {
		inner++;
	} until (inner >= 2);
	outer += inner;
} until (outer >= 6);
return outer;',
undefined,
function(){
	var outer = 0;
	do {
		var inner = 0;
		do {
			inner++;
		} until (inner >= 2);
		outer += inner;
	} until (outer >= 6);
	return outer;
})
#endregion
#region Do/Until with Return Inside Loop
run_interpreter_test("Do/Until with Return Inside Loop",
@'do {
	return "Exited";
} until (true);
return "Not Exited";',
undefined,
function(){
	do {
		return "Exited";
	} until (true);
	return "Not Exited";
})
#endregion
#region Do/Until Loop with Variable Initialization
run_interpreter_test("Do/Until Loop with Variable Initialization",
@'var result = 0;
do {
	var local = 10;
	result += local;
} until (result >= 50);
return result;',
undefined,
function(){
	var result = 0;
	do {
		var local = 10;
		result += local;
	} until (result >= 50);
	return result;
})
#endregion
#region Empty Do/Until Loop
run_interpreter_test("Empty Do/Until Loop",
@'do {} until (true);
return "Done";',
undefined,
function(){
	do {} until (true);
	return "Done";
})

#endregion

#endregion
#region Do/Until Statement Advanced

#region Do/Until Loop with Nested Breaks
run_interpreter_test("Do/Until Loop with Nested Breaks",
@'var i = 0;
do {
	do {
		i++;
		if (i == 10) break;
	} until (true);
	if (i == 10) break;
} until (true);
return i;',
undefined,
function(){
	var i = 0;
	do {
		do {
			i++;
			if (i == 10) break;
		} until (true);
		if (i == 10) break;
	} until (true);
	return i;
})
#endregion

#region Complex Do/Until with Nested If and Continue
run_interpreter_test("Complex Do/Until with Nested If and Continue",
@'var count = 0;
do {
	count++;
	if (count % 2 == 0) {
		if (count == 6) continue;
		count += 10;
	}
} until (count >= 30);
return count;',
undefined,
function(){
	var count = 0;
	do {
		count++;
		if (count % 2 == 0) {
			if (count == 6) continue;
			count += 10;
		}
	} until (count >= 30);
	return count;
})
#endregion
#region Do/Until with Nested Breaks
run_interpreter_test("Do/Until with Nested Breaks",
@'var xx = 0;
do {
	var yy = 0;
	do {
		yy++;
		if (yy == 5) break;
	} until (yy > 10);
	xx++;
	if (xx == 5) break;
} until (xx > 10);
return xx;',
undefined,
function(){
	var xx = 0;
	do {
		var yy = 0;
		do {
			yy++;
			if (yy == 5) break;
		} until (yy > 10);
		xx++;
		if (xx == 5) break;
	} until (xx > 10);
	return xx;
})
#endregion
#region Do/Until with Conditional Exits
run_interpreter_test("Do/Until with Conditional Exits",
@'var i = 0;
do {
	i++;
	if (i == 3) return "Exit at Three";
	if (i == 5) return "Exit at Five";
} until (i > 10);
return i;',
undefined,
function(){
	var i = 0;
	do {
		i++;
		if (i == 3) return "Exit at Three";
		if (i == 5) return "Exit at Five";
	} until (i > 10);
	return i;
})
#endregion
#region Deeply Nested Do/Until with Multiple Jump Conditions
run_interpreter_test("Deeply Nested Do/Until with Multiple Jump Conditions",
@'var level = 0;
do {
	do {
		level++;
		if (level == 5) break;
	} until (level >= 10);
	if (level == 5) break;
} until (level > 10);
return level;',
undefined,
function(){
	var level = 0;
	do {
		do {
			level++;
			if (level == 5) break;
		} until (level >= 10);
		if (level == 5) break;
	} until (level > 10);
	return level;
})

#endregion

#endregion

#region With Statement Basic

#region With Statement with self
run_interpreter_test("With Statement with self",
@'with (self) {
	return 1;
}
return 0;',
undefined,
function(){
	with (self) {
		return 1;
	}
	return 0;
})

#endregion
#region With Statement with other
run_interpreter_test("With Statement with other",
@'with (other) {
	return 1;
}
return 0;',
undefined,
function(){
	with (other) {
		return 1;
	}
	return 0;
})

#endregion
#region With Statement with all
run_interpreter_test("With Statement with all",
@'with (all) {
	return 1;
}
return 0;',
undefined,
function(){
	with (all) {
		return 1;
	}
	return 0;
})

#endregion
#region With Statement with struct
run_interpreter_test("With Statement with struct",
@'var myStruct = {id: 100};
with (myStruct) {
	return id;
}',
undefined,
function(){
	var myStruct = {id: 100};
	with (myStruct) {
		return id;
	}
})

#endregion
#region With Statement Multiple Commands
run_interpreter_test("With Statement Multiple Commands",
@'with (self) {
	var xx = 10;
	return xx;
}
return 0;',
undefined,
function(){
	with (self) {
		var xx = 10;
		return xx;
	}
	return 0;
})

#endregion
#region With Statement Nested
run_interpreter_test("With Statement Nested",
@'with (self) {
	with (other) {
		return 1;
	}
	return 0;
}',
undefined,
function(){
	with (self) {
		with (other) {
			return 1;
		}
		return 0;
	}
})

#endregion
#region With Statement Conditional
run_interpreter_test("With Statement Conditional",
@'with (self) {
	if (true) return 1;
	return 0;
}',
undefined,
function(){
	with (self) {
		if (true) return 1;
		return 0;
	}
})

#endregion

#endregion
#region With Statement Advanced

#region With Statement with Double Nested
run_interpreter_test("With Statement with Double Nested",
@'with (self) {
	with (other) {
		var xx = 10;
		return xx;
	}
	return 0;
}',
undefined,
function(){
	with (self) {
		with (other) {
			var xx = 10;
			return xx;
		}
		return 0;
	}
})

#endregion
#region With Statement with Noone
run_interpreter_test("With Statement with Noone",
@'with (noone) {
	return 1;
}
return 0;',
undefined,
function(){
	with (noone) {
		return 1;
	}
	return 0;
})

#endregion
#region With Statement with Continue in Loop
run_interpreter_test("With Statement with Continue in Loop",
@'for (var i = 0; i < 5; i++) {
	with (self) {
		if (i == 2) continue;
		return i;
	}
}
return 5;',
undefined,
function(){
	for (var i = 0; i < 5; i++) {
		with (self) {
			if (i == 2) continue;
			return i;
		}
	}
	return 5;
})

#endregion
#region With Statement with Break in Loop
run_interpreter_test("With Statement with Break in Loop",
@'for (var i = 0; i < 5; i++) {
	with (self) {
		if (i == 2) break;
		return i;
	}
}
return 5;',
undefined,
function(){
	for (var i = 0; i < 5; i++) {
		with (self) {
			if (i == 2) break;
			return i;
		}
	}
	return 5;
})

#endregion
#region With Statement Nested with All
run_interpreter_test("With Statement Nested with All",
@'with (all) {
	with (self) {
		return 1;
	}
	return 0;
}',
undefined,
function(){
	with (all) {
		with (self) {
			return 1;
		}
		return 0;
	}
})

#endregion
#region With Statement with Logical Conditions
run_interpreter_test("With Statement with Logical Conditions",
@'with (self) {
	if (true && false) return 0;
	else return 1;
}',
undefined,
function(){
	with (self) {
		if (true && false) return 0;
		else return 1;
	}
})

#endregion
#region With Statement with Multiple Controls
run_interpreter_test("With Statement with Multiple Controls",
@'with (self) {
	for (var i = 0; i < 3; i++) {
		if (i == 1) continue;
		else if (i == 2) break;
		return i;
	}
	return 3;
}',
undefined,
function(){
	with (self) {
		for (var i = 0; i < 3; i++) {
			if (i == 1) continue;
			else if (i == 2) break;
			return i;
		}
		return 3;
	}
})

#endregion
#region With Statement with Return Early Out
run_interpreter_test("With Statement with Return Early Out",
@'with (self) {
	return 1;
	return 2; // This should never execute
}',
undefined,
function(){
	with (self) {
		return 1;
		return 2; // This should never execute
	}
})

#endregion
#region With Statement Complex Logic
run_interpreter_test("With Statement Complex Logic",
@'with (self) {
	var xx = 0, yy = 0;
	while (xx < 5) {
		xx++;
		with (other) {
			yy += xx;
			if (yy > 10) break;
		}
	}
	return yy;
}',
undefined,
function(){
	with (self) {
		var xx = 0, yy = 0;
		while (xx < 5) {
			xx++;
			with (other) {
				yy += xx;
				if (yy > 10) break;
			}
		}
		return yy;
	}
})

#endregion

#endregion

#region Switch/Case/Default Statement Basic

#region Switch Basic Single Case
run_interpreter_test("Switch Basic Single Case",
@'switch (1) {
	case 1: return 1;
}',
undefined,
function(){
	switch (1) {
		case 1: return 1;
	}
})

#endregion
#region Switch Basic Two Cases
run_interpreter_test("Switch Basic Two Cases",
@'switch (2) {
	case 1: return 1;
	case 2: return 2;
}',
undefined,
function(){
	switch (2) {
		case 1: return 1;
		case 2: return 2;
	}
})

#endregion
#region Switch Basic Default Only
run_interpreter_test("Switch Basic Default Only",
@'switch (3) {
	default: return 3;
}',
undefined,
function(){
	switch (3) {
		default: return 3;
	}
})

#endregion
#region Switch Basic No Matching Case
run_interpreter_test("Switch Basic No Matching Case",
@'switch (4) {
	case 1: return 1;
	case 2: return 2;
	default: return 0;
}',
undefined,
function(){
	switch (4) {
		case 1: return 1;
		case 2: return 2;
		default: return 0;
	}
})

#endregion
#region Switch Basic Fall Through
run_interpreter_test("Switch Basic Fall Through",
@'switch (2) {
	case 1: 
	case 2: return 2;
	default: return 3;
}',
undefined,
function(){
	switch (2) {
		case 1:
		case 2: return 2;
		default: return 3;
	}
})

#endregion
#region Switch Basic Multiple Cases
run_interpreter_test("Switch Basic Multiple Cases",
@'switch (5) {
	case 1: return 1;
	case 2: return 2;
	case 3: return 3;
	case 4: return 4;
	case 5: return 5;
}',
undefined,
function(){
	switch (5) {
		case 1: return 1;
		case 2: return 2;
		case 3: return 3;
		case 4: return 4;
		case 5: return 5;
	}
})

#endregion
#region Switch Nested
run_interpreter_test("Switch Nested",
@'switch (2) {
	case 1: return 1;
	case 2: 
		switch (1) {
			case 1: return 10;
			default: return 11;
		}
	default: return 0;
}',
undefined,
function(){
	switch (2) {
		case 1: return 1;
		case 2: 
			switch (1) {
				case 1: return 10;
				default: return 11;
			}
		default: return 0;
	}
})

#endregion
#region Switch Case Complex Expression
run_interpreter_test("Switch Case Complex Expression",
@'var xx = 2;
switch (xx * 2) {
	case 2: return 1;
	case 4: return 2;
	default: return 3;
}',
undefined,
function(){
	var xx = 2;
	switch (xx * 2) {
		case 2: return 1;
		case 4: return 2;
		default: return 3;
	}
})

#endregion
#region Switch Case With Variables
run_interpreter_test("Switch Case With Variables",
@'var xx = 3;
switch (xx) {
	case 1: return 1;
	case 2: return 2;
	case 3: return xx * xx; // 9
	default: return 0;
}',
undefined,
function(){
	var xx = 3;
	switch (xx) {
		case 1: return 1;
		case 2: return 2;
		case 3: return xx * xx; // 9
		default: return 0;
	}
})

#endregion
#region Switch with Break Statements
run_interpreter_test("Switch with Break Statements",
@'switch (2) {
	case 1: return 1; break;
	case 2: return 2; break;
	case 3: return 3; break;
	default: return 4;
}',
undefined,
function(){
	switch (2) {
		case 1: return 1; break;
		case 2: return 2; break;
		case 3: return 3; break;
		default: return 4;
	}
})

#endregion
#region Switch with Conditional Returns
run_interpreter_test("Switch with Conditional Returns",
@'switch (3) {
	case 1: if (false) return 1; break;
	case 2: if (true) return 2; break;
	case 3: if (true) return 3; else return 0; break;
	default: return 4;
}',
undefined,
function(){
	switch (3) {
		case 1: if (false) return 1; break;
		case 2: if (true) return 2; break;
		case 3: if (true) return 3; else return 0; break;
		default: return 4;
	}
})

#endregion
#region Switch without Matching Case
run_interpreter_test("Switch without Matching Case",
@'switch (10) {
	case 1: return 1;
	case 2: return 2;
	case 3: return 3;
}
return 0',
undefined,
function(){
	switch (10) {
		case 1: return 1;
		case 2: return 2;
		case 3: return 3;
	}
	return 0; // Implicit default case
})

#endregion
#region Switch Multiple Breaks
run_interpreter_test("Switch Multiple Breaks",
@'switch (1) {
	case 1: break;
	case 2: break;
	default: break;
}
return 10',
undefined,
function(){
	switch (1) {
		case 1: break;
		case 2: break;
		default: break;
	}
	return 10;
})

#endregion
#region Switch with Continue in Loop
run_interpreter_test("Switch with Continue in Loop",
@'for (var i = 0; i < 3; i++) {
	switch (i) {
		case 0: continue;
		case 1: return 1;
		default: continue;
	}
}',
undefined,
function(){
	for (var i = 0; i < 3; i++) {
		switch (i) {
			case 0: continue;
			case 1: return 1;
			default: continue;
		}
	}
	return 2;
})

#endregion
#region Switch Nested with Breaks
run_interpreter_test("Switch Nested with Breaks",
@'switch (2) {
	case 1: switch (1) {
			 case 1: break;
		   }
		   break;
	case 2: return 2;
}',
undefined,
function(){
	switch (2) {
		case 1: switch (1) {
				 case 1: break;
			   }
			   break;
		case 2: return 2;
	}
	return 3;
})

#endregion
#region Switch with Complex Conditions
run_interpreter_test("Switch with Complex Conditions",
@'var xx = 2;
switch (xx) {
	case 1 + 1: return 10;  // Matches x
	case 2 * 2: return 20;
}',
undefined,
function(){
	var xx = 2;
	switch (xx) {
		case 1 + 1: return 10;  // Matches x
		case 2 * 2: return 20;
	}
	return 0; // No default case
})

#endregion
#region Switch Case Without Break
run_interpreter_test("Switch Case Without Break",
@'switch (2) {
	case 1: return 1;
	case 2: return 2; // Fall through
	case 3: return 3;
	default: return 4;
}',
undefined,
function(){
	switch (2) {
		case 1: return 1;
		case 2: return 2; // Fall through
		case 3: return 3;
		default: return 4;
	}
})

#endregion
#region Switch With Logical Conditions
run_interpreter_test("Switch With Logical Conditions",
@'var yy = 10;
switch (yy) {
	case 10: if (yy == 10) return 100;
			 else return 200;
	default: return 0;
}',
undefined,
function(){
	var yy = 10;
	switch (yy) {
		case 10: if (yy == 10) return 100;
				 else return 200;
		default: return 0;
	}
})

#endregion

#endregion
#region Switch/Case/Default Statement Advanced

#region Advanced Switch with Variables
run_interpreter_test("Advanced Switch with Variables",
@'var xx = 3;
switch (xx * 2) {
	case 1 * 3: break;
	case 2 * 3: return 2 * xx;
	case 3 * 3: return 3 * xx;
	default: return 0;
}',
undefined,
function(){
	var xx = 3;
	switch (xx * 2) {
		case 1 * 3: break;
		case 2 * 3: return 2 * xx;
		case 3 * 3: return 3 * xx;
		default: return 0;
	}
})

#endregion
#region Advanced Switch with Complex Condition and Continue
run_interpreter_test("Advanced Switch with Complex Condition and Continue",
@'var i = 0;
for (i = 0; i < 5; i++) {
	switch (i) {
		case 2: continue;
		case 3: return 3;
		default: break;
	}
}
return i;',
undefined,
function(){
	var i = 0;
	for (i = 0; i < 5; i++) {
		switch (i) {
			case 2: continue;
			case 3: return 3;
			default: break;
		}
	}
	return i;
})

#endregion
#region Advanced Nested Switch with Break and Continue
run_interpreter_test("Advanced Nested Switch with Break and Continue",
@'for (var j = 0; j < 4; j++) {
	switch (j) {
		case 1: 
			switch (j + 1) {
				case 2: continue;
			}
			break;
		case 2: return j;
		default: continue;
	}
}
return 4;',
undefined,
function(){
	for (var j = 0; j < 4; j++) {
		switch (j) {
			case 1: 
				switch (j + 1) {
					case 2: continue;
				}
				break;
			case 2: return j;
			default: continue;
		}
	}
	return 4;
})

#endregion
#region Advanced Switch with Function Calls and Break
run_interpreter_test("Advanced Switch with Function Calls and Break",
@'var k = 1;
switch (k) {
	case 1*2: break;
	case 2*2: return 2;
	default: return -1;
}',
undefined,
function(){
	var k = 1;
	switch (k) {
		case 1*2: break;
		case 2*2: return 2;
		default: return -1;
	}
})

#endregion
#region Switch without break leading to default
run_interpreter_test("Switch without break leading to default",
@'var z = 1;
switch (z) {
	case 1: 
	case 2: return 2;
	default: return 3;
}',
undefined,
function(){
	var z = 1;
	switch (z) {
		case 1: 
		case 2: return 2;
		default: return 3;
	}
})

#endregion
#region Switch with No Matching Case and Complex Default
run_interpreter_test("Switch with No Matching Case and Complex Default",
@'var yy = 5;
switch (yy) {
	case 1: return 1;
	case 2: return 2;
	default: if (yy > 3) return 10; else return 5;
}',
undefined,
function(){
	var yy = 5;
	switch (yy) {
		case 1: return 1;
		case 2: return 2;
		default: if (yy > 3) return 10; else return 5;
	}
})

#endregion
#region Complex Switch with Multiple Breaks and Returns
run_interpreter_test("Complex Switch with Multiple Breaks and Returns",
@'var n = 3;
switch (n) {
	case 1: if (n == 1) return 10; break;
	case 2: if (n > 1) return 20; break;
	case 3: return 30; break;
	default: return 40;
}',
undefined,
function(){
	var n = 3;
	switch (n) {
		case 1: if (n == 1) return 10; break;
		case 2: if (n > 1) return 20; break;
		case 3: return 30; break;
		default: return 40;
	}
})

#endregion
#region Switch with Logical Operations
run_interpreter_test("Switch with Logical Operations",
@'var v = 2;
switch (v + 1) {
	case 2: return 2;
	case 3: return 3;
	default: return 4;
}',
undefined,
function(){
	var v = 2;
	switch (v + 1) {
		case 2: return 2;
		case 3: return 3;
		default: return 4;
	}
})

#endregion
#region Switch with Array Elements
run_interpreter_test("Switch with Array Elements",
@'var arr = [0, 1, 2];
switch (arr[1]) {
	case 0: return 0;
	case 1: return 1;
	default: return -1;
}',
undefined,
function(){
	var arr = [0, 1, 2];
	switch (arr[1]) {
		case 0: return 0;
		case 1: return 1;
		default: return -1;
	}
})

#endregion

#endregion

#region Try/Catch/Finally Statement Basic

#region Basic Try without Error
run_interpreter_test("Basic Try without Error",
@'try {
	return 1;
} catch (e) {
	return 2;
}',
undefined,
function(){
	try {
		return 1;
	} catch (e) {
		return 2;
	}
})

#endregion
#region Try with Error
run_interpreter_test("Try with Error",
@'try {
	throw "Error";
	return 1;
} catch (e) {
	return 2;
}',
undefined,
function(){
	try {
		throw "Error";
		return 1;
	} catch (e) {
		return 2;
	}
})

#endregion
#region Try with Finally
run_interpreter_test("Try with Finally",
@'try {
	return 1;
} finally {
	//return 2;
}
return 2;',
undefined,
function(){
	try {
		return 1;
	} finally {
		//return 2;
	}
	return 2;
})

#endregion
#region Try Catch Finally with Error
run_interpreter_test("Try Catch Finally with Error",
@'try {
	throw "Error";
	return 1;
} catch (e) {
	return 2;
} finally {
	//return 3;
}
return 3;',
undefined,
function(){
	try {
		throw "Error";
		return 1;
	} catch (e) {
		return 2;
	} finally {
		//return 3;
	}
	return 3;
})

#endregion
#region Try without Error with Finally
run_interpreter_test("Try without Error with Finally",
@'try {
	return 1;
} catch (e) {
	return 2;
} finally {
	//return 3;
}
return 3;',
undefined,
function(){
	try {
		return 1;
	} catch (e) {
		return 2;
	} finally {
		//return 3;
	}
	return 3;
})

#endregion
#region Nested Try Catch
run_interpreter_test("Nested Try Catch",
@'try {
	try {
		throw "Error";
	} catch (e) {
		return 1;
	}
} catch (e) {
	return 2;
}',
undefined,
function(){
	try {
		try {
			throw "Error";
		} catch (e) {
			return 1;
		}
	} catch (e) {
		return 2;
	}
})

#endregion
#region Nested Try Finally
run_interpreter_test("Nested Try Finally",
@'try {
	try {
		return 1;
	} finally {
		//return 2;
	}
	return 2;
} finally {
	//return 3;
}
return 3;',
undefined,
function(){
	try {
		try {
			return 1;
		} finally {
			//return 2;
		}
		return 2;
	} finally {
		//return 3;
	}
	return 3;
})

#endregion
#region Try with Break
run_interpreter_test("Try with Break",
@'for (var i = 0; i < 3; i++) {
	try {
		if (i == 1) break;
		return i;
	} catch (e) {
		return 3;
	}
}
return 4;',
undefined,
function(){
	for (var i = 0; i < 3; i++) {
		try {
			if (i == 1) break;
			return i;
		} catch (e) {
			return 3;
		}
	}
	return 4;
})

#endregion
#region Try with Continue
run_interpreter_test("Try with Continue",
@'for (var i = 0; i < 3; i++) {
	try {
		if (i == 1) continue;
		return i;
	} catch (e) {
		return 3;
	}
}
return 4;',
undefined,
function(){
	for (var i = 0; i < 3; i++) {
		try {
			if (i == 1) continue;
			return i;
		} catch (e) {
			return 3;
		}
	}
	return 4;
})

#endregion
#region Try Catch Finally with Continue
run_interpreter_test("Try Catch Finally with Continue",
@'for (var i = 0; i < 3; i++) {
	try {
		if (i == 1) continue;
		return i;
	} catch (e) {
		return 3;
	} finally {
		//return 4;
	}
	return 4;
}
return 5;',
undefined,
function(){
	for (var i = 0; i < 3; i++) {
		try {
			if (i == 1) continue;
			return i;
		} catch (e) {
			return 3;
		} finally {
			//return 4;
		}
		return 4;
	}
	return 5;
})

#endregion

#endregion
#region Try/Catch/Finally Statement Advanced

#region Advanced Try with Nested Try Catch Finally
run_interpreter_test("Advanced Try with Nested Try Catch Finally",
@'try {
	try {
		throw "Error";
	} catch (e) {
		return 1;
	} finally {
		//return 2;
	}
} catch (e) {
	return 3;
} finally {
	//return 4;
}
return 5;',
undefined,
function(){
	try {
		try {
			throw "Error";
		} catch (e) {
			return 1;
		} finally {
			//return 2;
		}
	} catch (e) {
		return 3;
	} finally {
		//return 4;
	}
	return 5;
})

#endregion
#region Advanced Try Catch Finally with Continue and Break
run_interpreter_test("Advanced Try Catch Finally with Continue and Break",
@'for (var i = 0; i < 3; i++) {
	try {
		if (i == 1) continue;
		if (i == 2) break;
		return i;
	} catch (e) {
		return 3;
	} finally {
		//return 4;
	}
	return 4;
}
return 5;',
undefined,
function(){
	for (var i = 0; i < 3; i++) {
		try {
			if (i == 1) continue;
			if (i == 2) break;
			return i;
		} catch (e) {
			return 3;
		} finally {
			//return 4;
		}
		return 4;
	}
	return 5;
})

#endregion
#region Advanced Try Finally with Nested Loops
run_interpreter_test("Advanced Try Finally with Nested Loops",
@'for (var i = 0; i < 3; i++) {
	try {
		for (var j = 0; j < 3; j++) {
			if (i == 1 && j == 1) continue;
			if (i == 2 && j == 2) break;
			return i * 10 + j;
		}
	} finally {
		//return 100 + i;
	}
	return 100 + i;
}
return 200;',
undefined,
function(){
	for (var i = 0; i < 3; i++) {
		try {
			for (var j = 0; j < 3; j++) {
				if (i == 1 && j == 1) continue;
				if (i == 2 && j == 2) break;
				return i * 10 + j;
			}
		} finally {
			//return 100 + i;
		}
		return 100 + i;
	}
	return 200;
})

#endregion
#region Advanced Try Catch with Return Inside Loop
run_interpreter_test("Advanced Try Catch with Return Inside Loop",
@'for (var i = 0; i < 3; i++) {
	try {
		if (i == 1) throw "Error";
		return i;
	} catch (e) {
		return 10 + i;
	}
}
return 5;',
undefined,
function(){
	for (var i = 0; i < 3; i++) {
		try {
			if (i == 1) throw "Error";
			return i;
		} catch (e) {
			return 10 + i;
		}
	}
	return 5;
})

#endregion
#region Advanced Try Catch Finally with Conditional Return
run_interpreter_test("Advanced Try Catch Finally with Conditional Return",
@'try {
	if (true) throw "Error";
	return 1;
} catch (e) {
	if (false) return 2;
	return 3;
} finally {
	//if (true) return 4;
	//return 5;
}
return 6;',
undefined,
function(){
	try {
		if (true) throw "Error";
		return 1;
	} catch (e) {
		if (false) return 2;
		return 3;
	} finally {
		//if (true) return 4;
		//return 5;
	}
	return 6;
})

#endregion
#region Advanced Try Finally with Multiple Returns
run_interpreter_test("Advanced Try Finally with Multiple Returns",
@'try {
	return 1;
} finally {
	a = 1
	//return 2;
	//return 3;
}
return 4;',
undefined,
function(){
	try {
		return 1;
	} finally {
		a = 1;
		//return 2;
		//return 3;
	}
	return 4;
})
#endregion
#region Advanced Try with Continue and Break in Nested Loops
run_interpreter_test("Advanced Try with Continue and Break in Nested Loops",
@'for (var i = 0; i < 3; i++) {
	try {
		for (var j = 0; j < 3; j++) {
			if (i == 1) continue;
			if (j == 1) break;
			return i * 10 + j;
		}
	} finally {
		//return 100 + i;
	}
	return 100 + i;
}
return 200;',
undefined,
function(){
	for (var i = 0; i < 3; i++) {
		try {
			for (var j = 0; j < 3; j++) {
				if (i == 1) continue;
				if (j == 1) break;
				return i * 10 + j;
			}
		} finally {
			//return 100 + i;
		}
		return 100 + i;
	}
	return 200;
})

#endregion

#endregion

#endregion

//*/
#endregion


//*
#region Factorial Test
run_interpreter_test("Factorial Test",
@'// compute the factorial of n
function factorial(n) {
  if (n <= 1) {
	return 1;
  }
  return n * factorial(n - 1)
}

factorial(1) // result: 1
factorial(2) // result: 2
factorial(3) // result: 6
factorial(4) // result: 24
factorial(5) // result: 120
return factorial(6) // result: 720',
undefined,
function(){
	// compute the factorial of n
	factorial = function (n) {
	  if (n <= 1) {
		return 1;
	  }
	  return n * factorial(n - 1)
	}
	
	factorial(1) // result: 1
	factorial(2) // result: 2
	factorial(3) // result: 6
	factorial(4) // result: 24
	factorial(5) // result: 120
	return factorial(6) // result: 720
})
#endregion


#region parsePreffixExpression
run_interpreter_test("parsePreffixExpression", 
@'var _x=0;
--_x;
return --_x;',
undefined,
function(){
	var _x=0;
	--_x;
	return --_x
}
)
#endregion
#region Jump Test Recursive If Test
run_interpreter_test("Jump Test Recursive If Test",
@'xx = 0;
function recursiveTest() {
	if (xx < 3) {
		xx += 1;
		recursiveTest();
	}
	return xx;
}

return recursiveTest();',
undefined,
function(){
	xx = 0;
	function recursiveTest() {
		if (xx < 3) {
			xx += 1;
			recursiveTest();
		}
		return xx;
	}
	return recursiveTest();

})
#endregion
#region Nested If with Functions
run_interpreter_test("Nested If with Functions",
@'function check(a) {
	if (a > 5) {
		if (a < 10) return a * 2;
	} else if (a == 5) return a + 2;
	return a;
}
return check(7);
',
undefined,
function(){
	function check(a) {
		if (a > 5) {
			if (a < 10) return a * 2;
		} else if (a == 5) return a + 2;
		return a;
	}
	return check(7);
})
#endregion
#region For Loop with Function Calls and Break
run_interpreter_test("For Loop with Function Calls and Break",
@'function checkBreak(_x) { return _x == 4; }
var i;
for (i = 0; i < 10; i++) {
	if (checkBreak(i)) break;
}
return i;',
undefined,
function(){
	function checkBreak(_x) { return _x == 4; }
	var i;
	for (i = 0; i < 10; i++) {
		if (checkBreak(i)) break;
	}
	return i;
})
#endregion
#region While Loop with External Function Call
run_interpreter_test("While Loop with External Function Call",
@'function checkCondition(x) { return x < 5; }
var i = 0;
while (checkCondition(i)) {
	i++;
}
return i;',
undefined,
function(){
	function checkCondition(x) { return x < 5; }
	var i = 0;
	while (checkCondition(i)) {
		i++;
	}
	return i;
})
#endregion
#region While Loop with Recursion
run_interpreter_test("While Loop with Recursion",
@'function recursiveFunction(xx) {
	while (xx < 5) {
		xx = recursiveFunction(xx + 1);
	}
	return xx;
}
return recursiveFunction(0);',
undefined,
function(){
	function recursiveFunction(xx) {
		while (xx < 5) {
			xx = recursiveFunction(xx + 1);
		}
		return xx;
	}
	return recursiveFunction(0);
})
#endregion
#region Advanced Try with Nested Try Catch Finally and Returns
//*
run_interpreter_test("Advanced Try with Nested Try Catch Finally and Returns",
@'try {
	try {
		throw "Error";
	} catch (e) {
		try {
			return 1;
		} finally {
			//return 2;
		}
		return 2;
	} finally {
		//return 3;
	}
	return 3;
} catch (d) {
	return 4;
} finally {
	//return 5;
}
return 6;',
undefined,
function(){
	try {
		try {
			throw "Error";
		}
		catch (e) {
			try {
				return 1;
			} finally {
				//return 2;
			}
			return 2;
		}
		finally {
			//return 3;
		}
		return 3;
	} catch (d) {
		return 4;
	} finally {
		//return 5;
	}
	return 6;
})
//*/
#endregion
#region Advanced Try Catch with Nested Try Finally
run_interpreter_test("Advanced Try Catch with Nested Try Finally",
@'try {
	throw "Error";
} catch (e) {
	try {
		return 1;
	} finally {
		a = 1
		//return 2;
	}
	return 2;
} finally {
	a = 2
	//return 3;
}
return 4;',
undefined,
function(){
	try {
		throw "Error";
	} catch (e) {
		try {
			return 1;
		} finally {
			//return 2;
		}
		return 2;
	} finally {
		//return 3;
	}
	return 4;
})

#endregion
#region Advanced Nested Try Catch Finally
run_interpreter_test("Advanced Nested Try Catch Finally",
@'try {
	try {
		throw "Error";
	} catch (e) {
		try {
			return 1;
		} finally {
			//return 2;
		}
		return 2;
	} finally {
		//return 3;
	}
	return 3;
} catch (e) {
	return 4;
} finally {
	//return 5;
}
return 6;',
undefined,
function(){
	try {
		try {
			throw "Error";
		} catch (e) {
			try {
				return 1;
			} finally {
				//return 2;
			}
			return 2;
		} finally {
			//return 3;
		}
		return 3;
	} catch (e) {
		return 4;
	} finally {
		//return 5;
	}
	return 6;
})

#endregion
#region With Statement Recursive Double With
run_interpreter_test("With Statement Recursive Double With",
@'xx = 0;
function recursiveWith() {
	with (self) {
		with (other) {
			if (xx < 3) {
				xx += 1;
				recursiveWith();
			}
		}
	}
	return xx;
}
return recursiveWith();',
undefined,
function(){
	xx = 0;
	function recursiveWith() {
		with (self) {
			with (other) {
				if (xx < 3) {
					xx += 1;
					recursiveWith();
				}
			}
		}
		return xx;
	}
	return recursiveWith();
})

#endregion
#region Do/Until Loop with Recursive Call
run_interpreter_test("Do/Until Loop with Recursive Call",
@'xx = 0;
function increment() {
	do {
		xx++;
		if (xx < 9) increment();
	} until (xx == 10);
}
increment();
return xx;',
undefined,
function(){
	xx = 0;
	function increment() {
		do {
			xx++;
			if (xx < 9) increment();
		} until (xx == 10);
	}
	increment();
	return xx;
})
#endregion
#region Do/Until with Nested Functions and Recursion
run_interpreter_test("Do/Until with Nested Functions and Recursion",
@'depth = 0;
function increaseDepth() {
	do {
		depth++;
		if (depth < 5) increaseDepth();
	} until (depth >= 10);
}
increaseDepth();
return depth;',
undefined,
function(){
	depth = 0;
	function increaseDepth() {
		do {
			depth++;
			if (depth < 5) increaseDepth();
		} until (depth >= 10);
	}
	increaseDepth();
	return depth;
})
#endregion
#region Do/Until with External Function Calls and Modifications
run_interpreter_test("Do/Until with External Function Calls and Modifications",
@'counter = 0;
function modifyCounter() {
	counter += 5;
}
do {
	modifyCounter();
	if (counter >= 25) break;
} until (false);
return counter;',
undefined,
function(){
	counter = 0;
	function modifyCounter() {
		counter += 5;
	}
	do {
		modifyCounter();
		if (counter >= 25) break;
	} until (false);
	return counter;
})
#endregion
#region Do/Until with Error Handling and Recovery
run_interpreter_test("Do/Until with Error Handling and Recovery",
@'var attempts = 0;
do {
	try {
		attempts++;
		if (attempts == 3) throw "Fail at Three";
	} catch (error) {
		if (attempts < 5) continue;
	}
} until (attempts > 5);
return attempts;',
undefined,
function(){
	var attempts = 0;
	do {
		try {
			attempts++;
			if (attempts == 3) throw "Fail at Three";
		} catch (error) {
			if (attempts < 5) continue;
		}
	} until (attempts > 5);
	return attempts;
})
#endregion
//*/
}
run_all_interpreter_tests();
#endregion


log("\n\n\n")

function attempt_file_parsing(_fname) {
	log($"Attempting to execute file: {_fname}")
	var _str = file_text_read_all(_fname);
	
	//log(_str)
	
	var tokenizer = new GML_Tokenizer();
	tokenizer.initialize(_str);
	var tokens = tokenizer.parseAll();
	tokenizer.cleanup();
	
	var _success = true;
	var _i=0; repeat(array_length(tokens)){
		if (tokens[_i].type == "Illegal") {
			log($"Token error: {tokens[_i]}");
			_success = false;
		}
	}
	if (!_success) {
		log("Tokenizer Failed")
		return;
	}
	log("Tokenizer Completed")
	//*
	var preprocessor = new GML_PreProcessor();
	preprocessor.initialize(tokens);
	var tokens = preprocessor.parseAll();
	
	log("PreProcessor Completed")
	
	var parser = new GML_Parser();
	parser.initialize(tokens);
	var ast = parser.parseAll();
	
	log("Parser Completed")
	
	var postprocessor = new GML_PostProcessor();
	postprocessor.initialize(ast);
	var optimizedAST = postprocessor.parseAll();
	
	log("Post Processor Completed")
	
	var interpreter = new GML_Interpreter();
	interpreter.initialize(optimizedAST);
	var outputModule = interpreter.parseAll();
	
	log("Interpreter Completed")
	log(json_stringify(outputModule, true))
	log(string_repeat("\n", 5))
	
	var outputReturn = outputModule.execute();
	
	log("Execution Completed")
	
	log("Successfully Completed")
	//*/
	
}
function compile_file(_fname) {
	log($"Attempting to execute file: {_fname}")
	var _str = file_text_read_all(_fname);
	
	//log(_str)
	
	var tokenizer = new GML_Tokenizer();
	tokenizer.initialize(_str);
	var tokens = tokenizer.parseAll();
	tokenizer.cleanup();
	
	var _success = true;
	var _i=0; repeat(array_length(tokens)){
		if (tokens[_i].type == "Illegal") {
			log($"Token error: {tokens[_i]}");
			_success = false;
		}
	}
	if (!_success) {
		log("Tokenizer Failed")
		return;
	}
	log("Tokenizer Completed")
	//*
	var preprocessor = new GML_PreProcessor();
	preprocessor.initialize(tokens);
	var tokens = preprocessor.parseAll();
	
	log("PreProcessor Completed")
	
	var parser = new GML_Parser();
	parser.initialize(tokens);
	var ast = parser.parseAll();
	
	log("Parser Completed")
	
	var converter = new GMLC_GM1_4_Converter();
	converter.initialize(ast);
	var ast = converter.parseAll();
	
	log("Converter Completed")
	
	var postprocessor = new GML_PostProcessor();
	postprocessor.initialize(ast);
	var optimizedAST = postprocessor.parseAll();
	
	log("Post Processor Completed")
	
	var interpreter = new GML_Interpreter();
	interpreter.initialize(optimizedAST);
	var outputModule = interpreter.parseAll();
	
	log("Interpreter Completed")
	log(json_stringify(outputModule, true))
	log(string_repeat("\n", 5))
	
	
	return method(outputModule.GlobalVar[$ "GMLC@osg"], outputModule.GlobalVar[$ "GMLC@osg"].execute);
	
	
	var outputReturn = outputModule.execute();
	
	log("Execution Completed")
	
	log("Successfully Completed")
	//*/
	
}
//!sorted by file size!
//attempt_file_parsing("test.gml")
//attempt_file_parsing("PsychoDelph.gml")
//attempt_file_parsing("Chance.gml")
//attempt_file_parsing("Surgeon_.gml")
//attempt_file_parsing("Nallebeorn.gml")
//attempt_file_parsing("Threef - Flappy Souls.gml")
//attempt_file_parsing("Coded Games.gml")
//attempt_file_parsing("Matthew Brown.gml")
//attempt_file_parsing("Galladhan.gml")
//attempt_file_parsing("shadowspear1 - shadowspear1's One-Script Tower Defense Game.gml")
//attempt_file_parsing("Nocturne - OSG Asteroids.gml")
//attempt_file_parsing("YellowAfterLife - Pool of Doom.gml")
//attempt_file_parsing("JimmyBG - Forest Fox.gml")
//attempt_file_parsing("Alice - juegOS.gml")
//attempt_file_parsing("Mike - Mega Super Smash Track Buggy Racer.gml")

//game_end()


//PsychoDelph = compile_file("PsychoDelph.gml");
run_game = false;

/*
[]; // output: Constant array { value:[], type: __GMLC_NodeType.Literal, scope:"Const" }
[0, 1, 2]; // output: Constant array { value:[0,1,2], type: __GMLC_NodeType.Literal, scope:"Const" }
[identifier, "string", variable_get_hash("FunctionReturn")]; // output: NON-constant array which we will compile as a function call using __NewGMLArray(identifier, "string", variable_get_hash("FunctionReturn")) which can be optimized by the postprocessor

var _struct = {}; // output: { value:{}, type: __GMLC_NodeType.Literal, scope:"Const" }
var _struct = {one: 1, two: 2, three: 3}; // output: { value:{one: 1, two: 2, three: 3}, type: __GMLC_NodeType.Literal, scope:"Const" }
var _struct = {"one": 1, "two": 2, "three": 3}; // output: { value:{one: 1, two: 2, three: 3}, type: __GMLC_NodeType.Literal, scope:"Const" }
var _value = 1; var _struct = {val: _value}; // output: NON-constant Struct, which we will compile as a function call using __NewGMLStruct("val", _value)
var value = 2; var _struct = {value}; // output: NON-constant Struct, which we will compile as a function call using __NewGMLStruct("value", value)
var three = 3; var _struct = {one: 1, two: 2, three}; // output: NON-constant Struct, which we will compile as a function call using __NewGMLStruct("one", 1, "two", 2, "three", three)


