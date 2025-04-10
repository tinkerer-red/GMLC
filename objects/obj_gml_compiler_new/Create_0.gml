gmlc = new GMLC_Env();

var _root_dir = "C:/Users/Red/Documents/GameMakerStudio2/__compile_tests_from_github/__gms23";
var _gml_files = gumshoe(_root_dir, "gml"); // flat array of all .gml files recursively
var _report = {};
var _file_results = [];
var _success_count = 0;

// Compile each .gml file
for (var i = 0; i < array_length(_gml_files); i++) {
	var _file_path = _gml_files[i];
	var _source = "";
	var _success = false;
	var _meta = undefined;
	
	// Read file
	log($"\tReading:: {_file_path}")
	_source = file_read_all_text(_file_path);
	if (_source == undefined) continue;
	
	// Compile
	log($"\tCompiling:: {_file_path}")
	try {
		var _program = gmlc.compile(_source);
		_success = true;
		log($"\tSuccess:: {_file_path}")
	}
	catch (err) {
		log($"\t\tFailed:: {_file_path}\n{json(err)}")
		_meta = err;
	}

	if (_success) _success_count++;

	// Extract repo path key (everything after root folder)
	var _repo_key = string_replace_all(_file_path, _root_dir + "/", "");
	var _slash_index = string_pos("/", _repo_key);
	if (_slash_index > 0) {
		_repo_key = string_copy(_repo_key, 1, _slash_index - 1);
	}

	// Init repo entry if needed
	if (!variable_struct_exists(_report, _repo_key)) {
		_report[$ _repo_key] = {
			files: [],
			success_count: 0,
			success_rate: 0,
			success: false
		};
	}

	// Push file result
	var _file_entry = {
		dir: _file_path,
		success: _success,
		meta_data: _meta
	};
	array_push(_report[$ _repo_key].files, _file_entry);

	if (_success) _report[$ _repo_key].success_count++;
}

// Finalize repo report
var _keys = variable_struct_get_names(_report);
for (var i = 0; i < array_length(_keys); i++) {
	var _key = _keys[i];
	var _entry = _report[$ _key];
	var _total = array_length(_entry.files);
	_entry.success_rate = _total > 0 ? (_entry.success_count / _total) : 1;
	_entry.success = (_entry.success_count == _total);
}

// Save full JSON result
json_save("compile_report.json", _report);
log("!!!compiling complete!!!")

