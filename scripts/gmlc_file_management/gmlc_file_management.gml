#region jsDoc
/// @func    __gmlc_file_read_text(_filename)
/// @desc    Returns the whole text of a file, or undefined when the file does not exist or is empty.
/// @param   {String} _filename : Path of the file to read
/// @returns {String|Undefined}
#endregion
function __gmlc_file_read_text(_filename) {
	if (!file_exists(_filename)) return undefined;
	
	var _buffer = buffer_load(_filename);
	var _text = undefined;
	if (buffer_get_size(_buffer) > 0) {
		_text = buffer_read(_buffer, buffer_string);
	}
	buffer_delete(_buffer);
	return _text;
}

#region jsDoc
/// @func    __gmlc_file_write_text(_filename, _content)
/// @desc    Writes a string to a file, creating it or replacing what it held.
/// @param   {String} _filename : Path of the file to write
/// @param   {String} _content  : The text to write
#endregion
function __gmlc_file_write_text(_filename, _content) {
	var _buffer = buffer_create(string_byte_length(_content) + 1, buffer_fixed, 1);
	buffer_write(_buffer, buffer_string, _content);
	buffer_save(_buffer, _filename);
	buffer_delete(_buffer);
}

#region jsDoc
/// @func    __gmlc_json_save(_filename, _value)
/// @desc    Saves a value (struct, array, string or number) to a file as indented JSON.
/// @param   {String} _filename : Path of the JSON file to write
/// @param   {Any}    _value    : The value to save
#endregion
function __gmlc_json_save(_filename, _value) {
	__gmlc_file_write_text(_filename, json_stringify(_value, true));
}

#region jsDoc
/// @func    __gmlc_json_load(_filename)
/// @desc    Returns the value stored as JSON in a file, or undefined when the file is missing, empty or not valid JSON.
/// @param   {String} _filename : Path of the JSON file to load
/// @returns {Any}
#endregion
function __gmlc_json_load(_filename) {
	var _text = __gmlc_file_read_text(_filename);
	if (_text == undefined) return undefined;
	try {
		return json_parse(_text);
	}
	catch (_error) {
		return undefined;
	}
}
