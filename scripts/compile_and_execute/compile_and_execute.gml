global.TestSpeeds = json_load("PrevTestSpeeds.json") ?? {};
global.TestFailed = {};

function compile_and_execute(_string) {
	static __faster = 0;
	
	static gmlc = new GMLC_Env()
	var _program = gmlc.compile(_string);
	
	//GC_START
	var _start = get_timer();
	var _r = executeProgram(_program);
	var _end = get_timer() - _start;
	//GC_LOG
	
	if (global.gCurrentTest != undefined) {
		var _succeeded = (array_length(struct_get_names(global.gCurrentTest.getDiagnostics())) == 0)
		var _prev_time = global.TestSpeeds[$ global.gCurrentTest.getName()] ?? infinity;
		var _current_time = _end/1_000
		if (_succeeded) {
			if (_current_time < _prev_time*0.5) {
				log("Current Test is significantly ::FASTER::")
				global.TestSpeeds[$ global.gCurrentTest.getName()] = _end/1_000;
				json_save("PrevTestSpeeds.json", global.TestSpeeds)
			}
			if (_current_time > _prev_time/0.5) {
				log("Current Test is significantly ::SLOWER::")
			}
			//we do not log tests which are with in a varying degree of results
		}
		else {
			global.TestFailed[$ global.gCurrentTest.getName()] = global.gCurrentTest.getDiagnostics()
			json_save("PrevTestSpeeds.json", global.TestSpeeds)
		}
	}
	
	return _r;
}

function compile_code(_string) {
	static gmlc = new GMLC_Env()
	var _program = gmlc.compile(_string);
	
	return _program;
	
}

function execute_code(_program) {
	return executeProgram(_program)
}
