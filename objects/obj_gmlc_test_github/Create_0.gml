gmlc = new GMLC_Env().set_exposure(GMLC_EXPOSURE.NATIVE);

var _root_dir = "C:/Users/Red/Documents/GameMaker Studio 2/__compile_tests_from_github/__gms23";

// Enumerate top-level repo folders
_repo_dirs = [];
var _dir = file_find_first(_root_dir + "/*", fa_directory);
while (_dir != "") {
	if (_dir != "." && _dir != "..") {
		array_push(_repo_dirs, _dir);
	}
	_dir = file_find_next();
}
file_find_close();


var _report = {};
var _total_success = 0;
var _total_files   = 0;

var _length = array_length(_repo_dirs);
var _i = 0; repeat(_length) {
	var _repo_name = _repo_dirs[_i];
	
	print_progress(_i, _length, "Building Batch")
	show_debug_message(_repo_name)
	
	var _repo_path = _root_dir + "/" + _repo_name;

	// Collect all .gml files for this repo
	var _gml_files = gumshoe(_repo_path, "gml", false);
	var _sources = [];
	var _j = 0; repeat(array_length(_gml_files)) {
		var _path   = _gml_files[_j];
		var _source = gmlc_file_read_all_text(_path);
		if (_source != undefined) {
			array_push(_sources, { source: _source, name: _path });
		}
	_j++;}

	// Compile this repo as its own isolated batch (errors silenced — failures recorded in entries)
	var _batch_result = new GMLC_BatchResult();
	var _error = undefined;
	try {
		_batch_result = gmlc.compile_batch(_sources);
	} catch (_e) {
		_error = _e;
	}
	
	var _repo_report = {};
	_repo_report.file_count    = array_length(_gml_files);
	_repo_report.success_count = _batch_result.get_success_count();
	_repo_report.success_rate  = _batch_result.get_success_rate();
	
	if (_error != undefined) { _repo_report.error = _error; }
	
	_report[$ _repo_name] = _repo_report;
	_total_success += _repo_report.success_count;
	_total_files   += _repo_report.file_count;
	
_i++;}

// Top-level summary across all repos
_report.success_count = _total_success;
_report.file_count    = _total_files;
_report.success_rate  = (_total_files > 0) ? (_total_success / _total_files) : 1;

json_save("compile_report.json", _report);
show_debug_message($"!!!compiling complete!!! {_total_success}/{_total_files} ({string(_report.success_rate * 100)}%)");

gmlc = undefined;
