
var env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
env.exposeMacros({
	"test_timeout_millis": "timeoutMillis",
	"test_filter": "platformFilter",
	"test_start_hook": "startHook",
	"test_end_hook": "endHook"
})

program = env.compile(@'
a[2] = 10;
show_debug_message(a);

var b;
b[2] = 20;
show_debug_message(b);
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


