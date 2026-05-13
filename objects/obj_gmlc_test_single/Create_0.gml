/// @description Standalone GML test for identifier/keyword/enum/struct/macro edge cases
/// Run this in a real GML project (NOT inside GMLC) to verify expected behavior
env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
program = env.compile(@'
var _hex_value_a = $123ABC;
var _hex_value_b = #123ABC;
show_debug_message(_hex_value_a)
show_debug_message(_hex_value_b)
');

show_debug_message(program())

var _hex_value_a = $123ABC;
var _hex_value_b = #123ABC;
show_debug_message(_hex_value_a)
show_debug_message(_hex_value_b)
/*

gmlc = new GMLC_Env().set_exposure(GMLC_EXPOSURE.NATIVE);

gmlc.__log_tokenizer_results      = true;
gmlc.__log_pre_processer_results  = true;
gmlc.__log_parser_results         = true;
gmlc.__log_post_processer_results = true;
gmlc.__log_optimizer_results      = true;

gmlc.compile(@'
    #macro test "abc";
	
	foo = 123;
	bar = test;
	
	var foo;
')


// Save full JSON result
log("!!!compiling complete!!!")

gmlc = undefined;


