function file_text_read_all(_fname) {
	if !file_exists(_fname) throw $"File does not exist: {_fname}"
	
	var _str = "";
	var _file = file_text_open_read(_fname);
	while (!file_text_eof(_file)) {
	    _str += file_text_read_string(_file) + "\n";
	    file_text_readln(_file);
	}
	file_text_close(_file);
	
	return _str;
}
