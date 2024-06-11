


var _parser = new GML_Tokenizer();

// Test tokenize_whitespace
show_debug_message("Testing tokenize_whitespace");
_parser.__parse_first_pass("   \t\n");
// Expected: Whitespace tokens for spaces, tab, and newline

// Test tokenize_operator
show_debug_message("Testing tokenize_operator");
_parser.__parse_first_pass("+ - * / %");
// Expected: Operator tokens for each arithmetic operator

// Test tokenize_number
show_debug_message("Testing tokenize_number");
_parser.__parse_first_pass("123 4.56 7_890");
// Expected: Number tokens for 123, 4.56, and 7890 (underscore ignored in numbers)

// Test tokenize_number with leading underscore (should be treated as identifier)
show_debug_message("Testing tokenize_number with leading underscore");
_parser.__parse_first_pass("_123");
// Expected: Identifier token for _123

// Test tokenize_identifier
show_debug_message("Testing tokenize_identifier");
_parser.__parse_first_pass("variableName _with_underscore CamelCase123");
// Expected: Identifier tokens for each example identifier

// Test tokenize_illegal
show_debug_message("Testing tokenize_illegal");
_parser.__parse_first_pass("£");
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_literal
show_debug_message("Testing tokenize_string_literal");
_parser.__parse_first_pass("\"This is a stringLitteral\"");
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_literal
show_debug_message("Testing tokenize_string_literal with escapes");
_parser.__parse_first_pass("\"\\tThis is a stringLitteral\\nWith line breaks\"");
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_legacy
show_debug_message("Testing tokenize_string_legacy with \"");
_parser.__parse_first_pass("@\"This is a stringBlock\nwith a line break\"");
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_legacy
show_debug_message("Testing tokenize_string_legacy with '");
_parser.__parse_first_pass("@'This is a stringBlock\nwith a line break'");
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_expression
show_debug_message("Testing tokenize_string_expression");
_parser.__parse_first_pass(@'var _example1 = $"A1 { abc } A2";');

// Test tokenize_string_expression
show_debug_message("Testing tokenize_string_expression");
_parser.__parse_first_pass(@'var _example1 = $"A1 { $"B1 { $"C1 { D1 } C2 { D2 } C3" } B2" } A2";');
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_expression
show_debug_message("Testing tokenize_string_expression with line breaks");
_parser.__parse_first_pass(@'var _example2 = $"A1 {
$"B1 {
$"C1 {
D
} C2"
} B2"
} A2";');
// Expected: Illegal tokens for each unrecognized character

// Test tokenize_string_expression
show_debug_message("Testing tokenize_comment_line");
_parser.__parse_first_pass(@'var a = 1; //This is the comment');

// Test tokenize_string_expression
show_debug_message("Testing tokenize_comment_block");
_parser.__parse_first_pass(@'var a = 1; /*This is the comment
on
multiple lines*/
var b = 2;');


var _buf = buffer_load("test.gml");
var _gml = buffer_read(_buf, buffer_string);
buffer_delete(_buf);


show_debug_message("=========== Testing everything");
_parser.__parse_first_pass(_gml);

