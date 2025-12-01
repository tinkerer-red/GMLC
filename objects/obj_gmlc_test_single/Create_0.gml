
var env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
env.exposeMacros({
	"test_timeout_millis": "timeoutMillis",
	"test_filter": "platformFilter",
	"test_start_hook": "startHook",
	"test_end_hook": "endHook"
})

program = env.compile(@'
#macro FOO_BAR "abcde"
timeoutMillis = FOO_BAR;
return test_timeout_millis;
');

show_debug_message(program())

function RunForAllBufferDataTypes(testFunc) {
    
    var data = [
    [ buffer_bool, true, "buffer_bool" ],
    
    [ buffer_u8, 10, "buffer_u8" ],
    [ buffer_u16, 14532, "buffer_u16" ],
    [ buffer_u32, 2930471932, "buffer_u32" ],
    [ buffer_u64, 14738282109100, "buffer_u64" ],
    
    [ buffer_s8, -10, "buffer_s8" ],
    [ buffer_s16, -27145, "buffer_s16" ],
    [ buffer_s32, -2102943143, "buffer_s32" ],
    
    [ buffer_f16, -2.34, "buffer_f16" ],
    [ buffer_f32, -493200.1934, "buffer_f32" ],
    [ buffer_f64, -147382821091.992, "buffer_f64" ],
    [ buffer_string, "Hello world, this is a test string!", "buffer_string" ],
    ];
    
    var dataLength = array_length(data);
    for (var i = 0; i < dataLength; i++) {
        
        var current = data[i];
        
        var type = current[0];
        var value = current[1];
        var typeString = current[2];
        var typeSize = buffer_sizeof(type);
        var testBuffer = buffer_create(1, buffer_grow, 1);
        
        if (platform_browser() && type == buffer_f16) continue;
    
        testFunc(testBuffer, type, value, typeString, typeSize);
    }
    
    if (buffer_exists(testBuffer))
    {
        buffer_delete(testBuffer);
    }
}

// Set lower epsilon value to ensure rounding errors don't interfere with test results
math_set_epsilon(0.01);

// For all buffer data types, create a buffer, write some data to it, then check that the data was correctly written
RunForAllBufferDataTypes(function(testBuffer, type, value, typeString, typeSize) {
    buffer_write(testBuffer, type, value);
    var output = buffer_peek(testBuffer, 0, type);
    if (output != value) {
		throw "buffer_write/peek(), failed to write/peek the correct value (type: "+typeString+")";
	}
	else {
		show_debug_message("success")
	}
});

// Reset to default epsilon value
math_set_epsilon(0.00001);


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


