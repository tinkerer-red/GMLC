
var env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
program = env.compile(@'
var vstring = "Hello World!";
// Check that using an index beyond the size of the string will clamp to the string size
return string_delete(vstring, 100, 1);
');

var vstring = "Hello World!";
// Check that using an index beyond the size of the string will clamp to the string size
var res = string_delete(vstring, 100, 1);

show_debug_message(program())
show_debug_message(res)

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


