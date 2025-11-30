function compile_and_execute(_string) {
	static __faster = 0;
	
	static gmlc = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
	var _program = gmlc.compile(_string);
	
	var _did_crash = false;
	var _crash_report = undefined;
	
	try {
		var _r = executeProgram(_program);
	}
	catch(err) {
		_did_crash = true;
		_crash_report = json_stringify(__reStruct(err));
	}
	
	if (global.gCurrentTest != undefined) {
		var _succeeded = (array_length(struct_get_names(global.gCurrentTest.getDiagnostics())) == 0);
		if (_succeeded) {
			// Check github issues to see if we need to close an open issue about the test.
		}
		else {
			var _test_name = global.gCurrentTest.getName();
			var _diagnostics = global.gCurrentTest.getDiagnostics();
			global.TestFailed[$ _test_name] = _diagnostics;
			
			// open a github issue.
			
		}
	}
	
	return _r;
}
