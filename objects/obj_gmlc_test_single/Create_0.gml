
var env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
program = env.compile(@'
function addArguments() 
{
    var _result = 0;
    
    for (var _n = argument_count - 1; _n>=0; --_n) {
        _result += argument[_n];
    }
    return _result;
}

var _array = [ 10, 20, 30, 40, 50, 60];

// Execute addArguments and check that it correctly sums the inputted array
var _result = script_execute_ext(addArguments, _array);
return _result;
');

show_debug_message(program())
show_debug_message(program())
show_debug_message(program())
show_debug_message(program())
show_debug_message(program())
show_debug_message(program())
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


