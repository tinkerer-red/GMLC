gmlc = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);

//sprite refs which are not exported (they are intentionally not exported for test purposes)
gmlc.exposeConstants({
	"sprTileset": sprTileset,
	"sprTilesetReplacement": sprTilesetReplacement,
})
//audio groups
gmlc.exposeConstants({
	"audiogroup_default": audiogroup_default,
	"audiogroup_MP3": audiogroup_MP3,
	"audiogroup_OGG": audiogroup_OGG,
	"audiogroup_WAV": audiogroup_WAV,
})

gmlc.exposeConstants({
	"pprint": function(){
	    var _str = "";
		var _i=0; repeat(argument_count) {
			_str += json_stringify(__reStruct(argument[_i]), true)+"\n";
		_i++}
		show_debug_message(_str)
	},
})



#macro FRAMEWORK_SHOULD_CATCH true

#macro SINGLE_TEST_MODE false

// If single test mode is set to true this will be the path to the test being run
single_test_path = "BasicArrayTestSuite@array_copy test #1";

/// @description Start Framework
/// This is the entry point for the frameowork execution.
testFramework = new TestFrameworkRun();

// ################# TEST SUITE REGISTRATION #################
//// Register your test suites here...
testFramework.addSuite(OptimizerConstantFoldingTestSuite);
testFramework.addSuite(OptimizerConstantPropagationTestSuite);
testFramework.addSuite(OptimizerUnreachableCodeTestSuite);
testFramework.addSuite(BasicEscapeCharacterTestSuite);
testFramework.addSuite(BasicCompoundAssignmentAccessorsTestSuite);
testFramework.addSuite(BasicConstructorTestSuit);
testFramework.addSuite(EmptyBlockAcceptanceTestSuite);
testFramework.addSuite(BinaryConditionTestSuite);
testFramework.addSuite(DotChainPerformanceTestSuite);

var _added_tests = []

//*
// Add all of the official test suites from their .gml files in included folder \__TEST\*.gml
var _file_names = file_find_all("__TESTS/*gml");
for(var i=0; i<array_length(_file_names); i++) {
	//log(_file_names[i]);
	var _script_str = "\n\n\n"+file_read_all_text("__TESTS/"+_file_names[i]);
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
			var _func = _program_data.globals[$ _global_name];
			if (is_gmlc_constructor(_func))
			&& (!array_contains(_added_tests, _func)) {
				show_debug_message(_global_name);
				testFramework.addSuite(_func);
				array_push(_added_tests, _func);
			}
		}
	}
	
}
//*/

socket = undefined;
network_buffer = undefined; 
using_remote_server = false;

// ###########################################################

// Only update the remote server flag if this is NOT a single test mode
if (!SINGLE_TEST_MODE) {
	using_remote_server = config_get_param("remote_server");
}

if (using_remote_server) { 
 
	// Using remote server 
	socket = network_create_socket(network_socket_tcp); 
	network_buffer = buffer_create(1, buffer_grow, 1); 
	 
	var _url = config_get_param("remote_server_address"); 
	var _port = config_get_param("remote_server_port");
	 
	network_connect_raw_async(socket, _url, _port); 
} else {
	
	if (SINGLE_TEST_MODE) {
		var _test = testFramework.findTestByPath(single_test_path);
		_test.run(function(_test) {
	
			show_debug_message(_test.getResultData());
	
		}, { suite: "Unknown", results_to_publish: [] });
	} 
	else {		
		testFramework.run(undefined, {});
	}
}
