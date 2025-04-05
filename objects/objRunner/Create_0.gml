/// @description Start Framework
/// This is the entry point for the frameowork execution.
testFramework = new TestFrameworkRun();

gmlc = new GMLC_Env();
gmlc.exposeConstants({
	"sprTileset": sprTileset,
	"sprTilesetReplacement": sprTilesetReplacement,
	
	"audiogroup_default": audiogroup_default,
	"audiogroup_MP3": audiogroup_MP3,
	"audiogroup_OGG": audiogroup_OGG,
	"audiogroup_WAV": audiogroup_WAV,
})

// ################# TEST SUITE REGISTRATION #################
var _string = @'
function test() : TestSuite() constructor {
	static func_static = true;
	func_local = true;
	show_debug_message(static_get(self))
	show_debug_message(static_get(static_get(self)))
	show_debug_message(addFact)
}
'

var _program = gmlc.compile(_string);
var _self = method_get_self(_program)
var t = new _self.globals.test();
log(instanceof(t));
log(t);
var t = constructor_call_ext(_self.globals.test);
log(instanceof(t));
log(t);

//// Register your test suites here...
//testFramework.addSuite(OptimizerConstantFoldingTestSuite);
//testFramework.addSuite(OptimizerConstantPropagationTestSuite);
//testFramework.addSuite(OptimizerUnreachableCodeTestSuite);
//testFramework.addSuite(BasicEscapeCharacterTestSuite);
//testFramework.addSuite(BasicCompoundAssignmentAccessorsTestSuite);
testFramework.addSuite(BasicConstructorTestSuit);


//*
// Add all of the official test suites from their .gml files in included folder \__TEST\*.gml
var _file_names = file_find_all("__TESTS/*gml");
for(var i=0; i<array_length(_file_names); i++) {
	//log(_file_names[i]);
	var _script_str = file_read_all_text("__TESTS/"+_file_names[i]);
	//log(string_replace_all(string_replace_all(string_copy(_script_str, 0, 200), "\t", ""), "\n", ""));
	var _program = gmlc.compile(_script_str);
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
//*/

// ###########################################################

testFramework.run(undefined, {});
