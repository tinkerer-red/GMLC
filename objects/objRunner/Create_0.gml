/// @description Start Framework
/// This is the entry point for the frameowork execution.
testFramework = new TestFrameworkRun();

// ################# TEST SUITE REGISTRATION #################

var _string = @'
function foo() constructor {
	show_debug_message(function(){
		show_debug_message(self)
	});
}
var t = new foo();
t.bar();
'

tokenizer = new GML_Tokenizer();
tokenizer.initialize(_string);
var tokens = tokenizer.parseAll();

preprocessor = new GML_PreProcessor();
preprocessor.initialize(tokens);
var preprocessedTokens = preprocessor.parseAll();

parser = new GML_Parser();
parser.initialize(preprocessedTokens);
var ast = parser.parseAll();

postprocessor = new GML_PostProcessor();
postprocessor.initialize(ast);
var ast = postprocessor.parseAll();

var _program = compileProgram(ast);

_program();

//// Register your test suites here...
//testFramework.addSuite(OptimizerConstantFoldingTestSuite);
//testFramework.addSuite(OptimizerConstantPropagationTestSuite);
//testFramework.addSuite(OptimizerUnreachableCodeTestSuite);
//testFramework.addSuite(BasicEscapeCharacterTestSuite);
//testFramework.addSuite(BasicCompoundAssignmentAccessorsTestSuite);
//testFramework.addSuite(BasicConstructorTestSuit);
//testFramework.addSuite(BasicStatementExpressionsTestSuite);

// Add all of the official test suites from their .gml files in included folder \__TEST\*.gml
var _file_names = file_find_all("__TESTS/*gml");
for(var i=0; i<array_length(_file_names); i++) {
	log(_file_names[i]);
	var _script_str = file_read_all_text("__TESTS/"+_file_names[i]);
	log(string_replace_all(string_replace_all(string_copy(_script_str, 0, 200), "\t", ""), "\n", ""));
	var _program = compile_code(_script_str);
	//pprint(_program)
	var _program_data = method_get_self(_program);
	var _global_names = struct_get_names(_program_data.globals);
	
	for(var j=0; j<array_length(_global_names); j++) {
		var _global_name = _global_names[j];
		
		if (!string_starts_with(_global_name, "GMLC"))
		&& (string_pos("TestSuite", _global_name))
		{
			show_debug_message(_global_name);
			var _func = _program_data.globals[$ _global_name];
			testFramework.addSuite(_func);
		}
	}
}


// ###########################################################

testFramework.run(undefined, {});
