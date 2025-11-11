var globalsBag = {
	scale_mult: 2,
	base_value: 10
};

var env = new GMLC_Env();
env.exposeConstants({"global": globalsBag})

// script A: uses scale_mult
var progA = env.compile("return global.base_value * global.scale_mult;");

// script B: uses the same globals
var progB = env.compile("return global.base_value + global.scale_mult;");

// script B: uses the same globals
var progC = env.compile(@'return variable_global_get("scale_mult")');
var progC = env.compile(@'
var _a = {name: "a"};
var _b = {name: "b"};

var _stat = static_get(_a);
_stat.name = "stat";

show_debug_message(static_get(_a));
show_debug_message(static_get(_b));
');

show_debug_message("A=" + string(progA())); // -> 20
show_debug_message("B=" + string(progB())); // -> 12
show_debug_message("C=" + string(progC())); // -> 2


var _a = {name: "a"};
var _b = {name: "b"};

var _stat = static_get(_a);
_stat.name = "stat";

show_debug_message(static_get(_a));
show_debug_message(static_get(_b));


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


