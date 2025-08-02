gmlc = new GMLC_Env().set_exposure(GMLC_EXPOSURE.NATIVE);

gmlc.__log_tokenizer_results      = true;
gmlc.__log_pre_processer_results  = true;
gmlc.__log_parser_results         = true;
gmlc.__log_post_processer_results = true;
gmlc.__log_optimizer_results      = true;

gmlc.compile(@'
	foo = 123;
	bar = "abc";
	
	var foo;
')


// Save full JSON result
log("!!!compiling complete!!!")

gmlc = undefined;


