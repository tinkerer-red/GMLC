gmlc = new GMLC_Env().set_exposure(GMLC_EXPOSURE.NATIVE);

//place holder to specifically test Juju's code.
//gmlc.compile(file_read_all_text("C:/Users/Red/Documents/GameMakerStudio2/__compile_tests_from_github/__gms23/JujuAdams__SHA-and-HMAC/scripts/hmac_sha1/hmac_sha1.gml"))

var _root_dir = "C:/Users/Red/Documents/GameMakerStudio2/__compile_tests_from_github/__gms23";
var _gml_files = gumshoe(_root_dir, "gml", true); // flat array of all .gml files recursively

compile_file = function(_file_path) {
	// Read file
	//log($"\tReading:: {_file_path}")
	var _source = file_read_all_text(_file_path);
	if (_source == undefined) {
		return {
			success: true,
			meta_data: undefined,
			dir: _file_path
		};
	}
			
	var _success = false;
	var _meta = undefined;
			
	// Compile
	//log($"\tCompiling:: {_file_path}")
	try {
		var _program = gmlc.compile(_source);
		_success = true;
		//log($"\tSuccess:: {_file_path}")
	}
	catch (err) {
		show_debug_message($"\t\tFailed:: {_file_path}\n{json_stringify(err, true)}")
		_meta = err;
	}
			
	return {
		success: _success,
		meta_data: _meta,
		dir: _file_path
	};
}

compile_struct = function(_struct, _path, _report={}) {
	var _success_rate = 0;
	var _success_count = 0;
	var _file_count = 0;
	
	var _keys = variable_struct_get_names(_struct);
	for (var i = 0; i < array_length(_keys); i++) {
		var _key = _keys[i];
		var _entry = _struct[$ _key];
		
		if (is_struct(_entry)) {
			var _return = compile_struct(_entry, _path+"/"+_key);
			
			_success_count += _return.success_count;
			_file_count += _return.file_count;
			
			_report[$ _key] = _return;
		}
		else {
			var _file_path = _path+"/"+_key;
			var _return = compile_file(_file_path)
			
			_file_count++
			if (_return.success) _success_count++
			
			_report[$ _key] = _return;
		}
		
	}
	
	_success_rate = _success_count / _file_count;
	
	_report.success_rate = _success_rate;
	_report.success_count = _success_count;
	_report.file_count = _file_count;
	
	return _report;
}

var _report_final = compile_struct(_gml_files, _root_dir);

// Save full JSON result
json_save("compile_report.json", _report_final);
show_debug_message("!!!compiling complete!!!")

gmlc = undefined;


