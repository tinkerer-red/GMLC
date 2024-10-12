
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
	var tokens = tokenizer.parseAsync(method(
		
		{description, expectedReturn},
		function(tokens) {
			log($"Attempting Interpreter Test :: {description}")
			
			var preprocessor = new GML_PreProcessor();
			preprocessor.initialize(tokens);
			var preprocessedTokens = preprocessor.parseAll();
		
			var parser = new GML_Parser();
			parser.initialize(preprocessedTokens);
			var ast = parser.parseAll();
		
			var postprocessor = new GML_PostProcessor();
			postprocessor.initialize(ast);
			var ast = postprocessor.parseAll();
			
			var _program = compileProgram(ast);
			var outputReturn = executeProgram(_program)
			
			expectedReturn = (is_callable(expectedReturn)) ? expectedReturn() : expectedReturn;
			
			var _same = __compare_results(description, outputReturn, expectedReturn);
			if (!_same) {
				log($"AST ::\n{json_stringify(ast, true)}\n")
				//log($"Program Method ::\n{json_stringify(__printMethodStructure(_program), true)}\n")
			}
			
		}
	));
	
	
	
	//var _program = undefined;
	////try {
	//	//log($"AST ::\n{json_stringify(ast, true)}\n")
	//	var _program = compileProgram(ast);
	//	//log($"Program Method ::\n{json_stringify(__printMethodStructure(_program), true)}\n")
	//	var outputReturn = executeProgram(_program)
	////}catch(e) {
	////	log($"AST ::\n{json_stringify(ast, true)}\n")
	////	log($"Program Method ::\n{json_stringify(__printMethodStructure(_program), true)}\n")
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
	//	//log($"Program Method ::\n{json_stringify(__printMethodStructure(_program), true)}\n")
	//}
}
function run_all_interpreter_tests() {
log("~~~~~ Interpreter Unit Tests ~~~~~\n");
var _s = get_timer()
#region HIDE

//run_interpreter_test("Boop",
//@'
//sound = audio_play_sound(snd_coinpickup_OGG, 1, false);
//',
//undefined,
//function(){
//	foo = 0;
//	var bar = method({foo: 1}, function(){
//		return foo
//	})
//	return bar()
//}
//);
run_interpreter_test("Parenting Constructors inherited arguments and Static structs",
@'
function a(arg0) constructor {
	static overwrite = "A Overwrite"
	static aStatic = "This is A`s Static"
	aInstance = "This is A`s Instance"
	argumentChain = arg0;
	localChain = 0;
}
function b(arg0) : a(arg0+1) constructor {
	static overwrite = "B Overwrite"
	static bStatic = "This is B`s Static"
	bInstance = "This is B`s Instance"
	localChain++;
}
function c(arg0) : b(arg0+1) constructor {
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
	function a(arg0) constructor {
		static overwrite = "A Overwrite"
		static aStatic = "This is A`s Static"
		aInstance = "This is A`s Instance"
		argumentChain = arg0;
		localChain = 0;
	}
	function b(arg0) : a(arg0+1) constructor {
		static overwrite = "B Overwrite"
		static bStatic = "This is B`s Static"
		bInstance = "This is B`s Instance"
		localChain++;
	}
	function c(arg0) : b(arg0+1) constructor {
		static overwrite = "C Overwrite"
		static cStatic = "This is C`s Static"
		cInstance = "This is C`s Instance"
		localChain++;
	}
	
	var _a = new a(1);
	var _b = new b(2);
	var _c = new c(3);
	
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
#region Accessors <Array, Grid, List, Map, Struct>
run_interpreter_test("Array access and modification",
@'
var arr = [0, 1, 2];
arr[0] = 1;
var test = arr[2];
return string(arr);',
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
} catch (_err) {
	return _err;
}
return count;',
function(){
	var count = 0;
	try {
		repeat (5) {
			count++;
			if (count == 3) throw "Error at 3";
		}
	} catch (_err) {
		return _err;
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

#region Jump Instruction Tests

#region If Statement Basic
#region Jump Test Basic If Test
run_interpreter_test("Jump Test Basic If Test",
@'if (true) return 1;
return 0;
',
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
function(){
	xx = 0;
	function __recursiveWith() {
		with (self) {
			with (other) {
				if (xx < 3) {
					xx += 1;
					__recursiveWith();
				}
			}
		}
		return xx;
	}
	return __recursiveWith();
})

#endregion
#region Do/Until Loop with Recursive Call
//run_interpreter_test("Do/Until Loop with Recursive Call",
//@'xx = 0;
//function increment() {
//	do {
//		xx++;
//		if (xx < 9) __increment();
//	} until (xx == 10);
//}
//__increment();
//return xx;',
//function(){
//	xx = 0;
//	function __increment() {
//		do {
//			xx++;
//			if (xx < 9) increment();
//		} until (xx == 10);
//	}
//	__increment();
//	return xx;
//})
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

#region Advanced Try with Nested Try Catch Finally and Returns
/*
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
/*
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
//*/
#endregion
#region Advanced Nested Try Catch Finally
/*
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
//*/
#endregion
log($"Finished compiling and executing tests in {(get_timer() - _s)/1_000}")
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


