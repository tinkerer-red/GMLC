
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
//    log(str)
    
//_i++}

show_debug_overlay(true)


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
run_tokenize_test("Test Raw string literal tokenization", @'"This is a test of the system"', 
{
  tokens:[
    {
      type: __GMLC_TokenType.String,
      name:@'"This is a test of the system"',
      line:1.0,
      column:1.0,
      value:"This is a test of the system"
    }
  ],
});

//run_tokenize_test("Test tokenize_raw_string_literals",
//"\"This is a stringLiteral\\nwith a line break\" @'This is a second rawStringLiteral'", 
//{
//  tokens:[
//    {
//      column:1.0,
//      type: __GMLC_TokenType.String,
//      name:"\"This is a stringLiteral\\nwith a line break\"",
//      line:1.0,
//      value:"This is a stringLiteral\nwith a line break"
//    },
//    {
//      column:45.0,
//      type: __GMLC_TokenType.String,
//      name:"@'This is a second rawStringLiteral\nwith a line break'",
//      line:1.0,
//      value:"This is a second rawStringLiteral\nwith a line break"
//    }
//  ],
//});

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
    },
    {
      column:30.0,
      type: __GMLC_TokenType.Punctuation,
      name:";",
      line:1.0,
      value:";"
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
    },
    {
      column:10.0,
      type: __GMLC_TokenType.Punctuation,
      name:";",
      line:5.0,
      lineString:"var b = 2;",
      value:";"
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
      column:12.0,
      type: __GMLC_TokenType.Punctuation,
      name:";",
      line:1.0,
      value:";"
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
      column:27.0,
      type: __GMLC_TokenType.Punctuation,
      name:";",
      line:2.0,
      value:";"
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
      value: real(animcurve_get_channel)
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
      value: real(show_debug_message)
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
      value: real(string)
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


log("\n\n\n")

#region Interpreter Unit Tests
function run_interpreter_test(description, input, expectedReturn=undefined) {
	
	
	var tokenizer = new GML_Tokenizer();
	tokenizer.initialize(input);
	tokenizer.parseAsync(method(
	{description, expectedReturn},
	function(tokens) {
		
		var preprocessor = new GML_PreProcessor();
		preprocessor.initialize(tokens);
		preprocessor.parseAsync(method(
		self,
		function(preprocessedTokens) {
			
			log($"Attempting Interpreter Test :: {description}")
			
			var parser = new GML_Parser();
			parser.initialize(preprocessedTokens);
			var ast = parser.parseAll();
			
			var postprocessor = new GML_PostProcessor();
			postprocessor.initialize(ast);
			var ast = postprocessor.parseAll();
			
			log("\n\n\n")
			log(" :: Default AST :: ")
			pprint(ast)
			log("\n\n\n")
			
			var optimizer = new GML_Optimizer();
			optimizer.initialize(ast);
			var ast = optimizer.parseAll();
			
			log("\n\n\n")
			log(" :: Optimized AST :: ")
			pprint(ast)
			log("\n\n\n")
			
			var _program = compileProgram(ast);
			var outputReturn = executeProgram(_program)
			
			expectedReturn = (is_callable(expectedReturn)) ? expectedReturn() : expectedReturn;
			
			var _same = __compare_results(description, outputReturn, expectedReturn);
			if (!_same) {
				log($"AST ::\n{json_stringify(ast, true)}\n")
			}
			
		}));
	}));
	
	
	
	//var _program = undefined;
	////try {
	//	//log($"AST ::\n{json_stringify(ast, true)}\n")
	//	var _program = compileProgram(ast);
	//	var outputReturn = executeProgram(_program)
	////}catch(e) {
	////	log($"AST ::\n{json_stringify(ast, true)}\n")
	////	log(e)
	////	return;
	////}
	//
	//expectedReturn = (is_callable(expectedReturn)) ? expectedReturn() : expectedReturn;
	//
	////if (expectedModule != undefined) __compare_results(description, outputModule, expectedModule);
	////log(json_stringify(outputReturn, true))
	////log(json_stringify(expectedReturn, true))
	//var _same = __compare_results(description, outputReturn, expectedReturn);
	//if (!_same) {
	//	log($"AST ::\n{json_stringify(ast, true)}\n")
	//}
}
function run_all_interpreter_tests() {
log("~~~~~ Interpreter Unit Tests ~~~~~\n");
var _s = get_timer()

run_interpreter_test("Boop",
@'
var result1 = 2 + 2;
/// @NoOp
var result2 = 2 + 2;
log(result1)
log(result2)
',
function(){
	return undefined;
}
);

return;

#region HIDE

run_interpreter_test("Boop",
@'
var _func = function(){ static __struct = { x: 0 } }
_func()
_func.__struct.x = 0
assert_equals(_func.__struct.x,   0, "Static external variable get failed.");
assert_equals(_func.__struct.x++, 0, "Static external variable PlusPlus Suffix failed.");
assert_equals(++_func.__struct.x, 2, "Static external variable PlusPlus Prefix failed.");
assert_equals(_func.__struct.x--, 2, "Static external variable MinusMinus Suffix failed.");
assert_equals(--_func.__struct.x, 0, "Static external variable MinusMinus Prefix failed.");
assert_equals(_func.__struct.x,   0, "Static external variable get failed.");
assert_struct_equals(static_get(_func), { __struct: {x : 0} }, "Static handles are not the same")
assert_equals(static_get(_func).__struct, _func.__struct, "Static handles are not the same")
',
function(){
	foo = function() constructor {
		bar = {}
	}
	
	var a0 = new foo();
	
	delete a0.bar;
	
	return a0.bar // should equal undefined
}
);
run_interpreter_test("Boop",
@'
foo = function() constructor {
	bar = {}
}

var a0 = new foo();

delete a0.bar;

return a0.bar // should equal undefined
',
function(){
	foo = function() constructor {
		bar = {}
	}
	
	var a0 = new foo();
	
	delete a0.bar;
	
	return a0.bar // should equal undefined
}
);
run_interpreter_test("Parenting Constructors inherited arguments and Static structs",
@'
function __GMLC_a(arg0) constructor {
	static overwrite = "A Overwrite"
	static aStatic = "This is A`s Static"
	aInstance = "This is A`s Instance"
	argumentChain = arg0;
	localChain = 0;
}
function __GMLC_b(arg0) : __GMLC_a(arg0+1) constructor {
	static overwrite = "B Overwrite"
	static bStatic = "This is B`s Static"
	bInstance = "This is B`s Instance"
	localChain++;
}
function __GMLC_c(arg0) : __GMLC_b(arg0+1) constructor {
	static overwrite = "C Overwrite"
	static cStatic = "This is C`s Static"
	cInstance = "This is C`s Instance"
	localChain++;
}
	
var _a = new a(1);
var _b = new b(2);
var _c = new c(3);
	
return string(_c);
',
function(){
	function __GML_a(arg0) constructor {
		static overwrite = "A Overwrite"
		static aStatic = "This is A`s Static"
		aInstance = "This is A`s Instance"
		argumentChain = arg0;
		localChain = 0;
	}
	function __GML_b(arg0) : __GML_a(arg0+1) constructor {
		static overwrite = "B Overwrite"
		static bStatic = "This is B`s Static"
		bInstance = "This is B`s Instance"
		localChain++;
	}
	function __GML_c(arg0) : __GML_b(arg0+1) constructor {
		static overwrite = "C Overwrite"
		static cStatic = "This is C`s Static"
		cInstance = "This is C`s Instance"
		localChain++;
	}
	
	var _a = new __GML_a(1);
	var _b = new __GML_b(2);
	var _c = new __GML_c(3);
	
	return string(_c);
}
);


//*
run_interpreter_test("Boop",
@'
var _constructor = function() constructor { }

var _result = array_create_ext(10, method( { const: _constructor }, function() { return new const(); }));
assert_array_length(_result, 10, "array_create_ext should create array with correct size (constructor)");
',
function(){
	var _constructor = function() constructor { }
	
	var _result = array_create_ext(10, method( { const: _constructor }, function() { return new const(); }));
	assert_array_length(_result, 10, "array_create_ext should create array with correct size (constructor)");
}
);


#region complex expression evaluation
run_interpreter_test("complex expression evaluation", 
@'x = 2;
y = 4;
var result = ((x + y) * (x - y)) / 2;
return result',
function(){
	x = 2;
	y = 4;
	var result = ((x + y) * (x - y)) / 2;
	return result	
}
)
#endregion

#region Varriable Apply With Postfix
run_interpreter_test("Varriable Apply With Postfix", 
@'x=1;
x++
return x;',
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
@'var arr = [1, 2, 3];
arr[0] = 10;
return arr[0];',
function(){
  var arr = [1, 2, 3];
  arr[0] = 10;
  return arr[0];
}
)

#endregion
#region 2. Array Modification Through Function
run_interpreter_test("Array Modification Through Function",
@'var arr = [1, 7, 5, 6];
array_sort(arr, true);
return arr[1];',
function(){
	var arr = [1, 7, 5, 6];
	array_sort(arr, true);
	return arr[1];
}
)

#endregion
#region 3. Array Element Increment
//run_interpreter_test("Array Element Increment",
//@'var arr = [10, 20, 30];
//arr[2]++;
//return arr[2];',
//function(){
//  var arr = [10, 20, 30];
//  arr[2]++;
//  return arr[2];
//}
//)
#endregion
#region 4. Dynamic Array Creation with Loop
run_interpreter_test("Dynamic Array Creation with Loop",
@'var arr = [];
for (var i = 0; i < 5; i++) {
  arr[i] = i * 2;
}
return arr[3];',
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
@'var arr = [100, 200, 300];
var result = string(arr[1]);
return result;',
function(){
	var arr = [100, 200, 300];
	var result = string(arr[1]);
	return result;
}
)
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
function(){
	var _x=0;
	--_x;
	return --_x
}
)
#endregion

log($"Finished compiling and executing tests in {(get_timer() - _s)/1_000}")
//*/
}
run_all_interpreter_tests();
#endregion

log("\n\n\n")

function attempt_file_parsing(_fname) {
	log($"Attempting to execute file: {_fname}")
	var _str = file_read_all_text(_fname);
	
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
	var _str = file_read_all_text(_fname);
	
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
	
	
	return method(outputModule.GlobalVar[$ "GMLC@'osg"], outputModule.GlobalVar[$ "GMLC@'osg"].execute);
	
	
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
//attempt_file_parsing("shadowspear1 - shadowspear1s One-Script Tower Defense Game.gml")
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


