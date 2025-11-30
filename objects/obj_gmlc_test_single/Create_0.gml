var env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
program = env.compile(@'
function factorial(_number) {
    if (_number <= 1) {
        return 1;
    }
    return _number * factorial(_number - 1);
}

function star_pattern(_depth) {
    if (_depth <= 1) {
        return "*";
    }

    var _inner_pattern = star_pattern(_depth - 1);
    return "[" + _inner_pattern + _inner_pattern + "]";
}

var _max_value = 6;
var _index = 0;
var _factorial_values = [];

show_debug_message("GMLC demo: factorials and recursive star pattern");

repeat (_max_value) {
    var _current_factorial = factorial(_index);
    var _current_pattern = star_pattern(max(1, _index));

    var _line =
        "n=" + string(_index) +
        "  factorial=" + string(_current_factorial) +
        "  pattern=" + _current_pattern;

    show_debug_message(_line);

    array_push(_factorial_values, _current_factorial);
    _index += 1;
}

var _summary = {
    values: _factorial_values,
    note: "returned this struct from inside the compiled program"
};

return _summary;
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


