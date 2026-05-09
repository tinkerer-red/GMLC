/// @description Standalone GML test for identifier/keyword/enum/struct/macro edge cases
/// Run this in a real GML project (NOT inside GMLC) to verify expected behavior
env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
program = env.compile(@'
show_debug_message(show_debug_message)
//42(real(show_debug_message))
');

show_debug_message(program())


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


