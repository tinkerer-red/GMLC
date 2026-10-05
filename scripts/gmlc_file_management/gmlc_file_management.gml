#region jsDoc
/// @func    file_find_all(_file_mask)
/// @desc    Returns the names of every file matching a mask (file_find_first / file_find_next), in the order found.
/// @param   {String} _file_mask : The mask to search with
/// @returns {Array<String>}
#endregion
function file_find_all(_file_mask) {
	var _names = [];
	for (var _name = file_find_first(_file_mask, fa_none); _name != ""; _name = file_find_next()) {
		array_push(_names, _name);
	}
	file_find_close();
	return _names;
}

#region jsDoc
/// @func    gmlc_file_read_all_text(_filename)
/// @desc    Returns the whole text of a file, or undefined when the file does not exist or is empty.
/// @param   {String} _filename : Path of the file to read
/// @returns {String|Undefined}
#endregion
function gmlc_file_read_all_text(_filename) {
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
/// @func    file_write_all_text(_filename, _content)
/// @desc    Writes a string to a file, creating it or replacing what it held.
/// @param   {String} _filename : Path of the file to write
/// @param   {String} _content  : The text to write
#endregion
function file_write_all_text(_filename, _content) {
	var _buffer = buffer_create(string_byte_length(_content) + 1, buffer_fixed, 1);
    buffer_write(_buffer, buffer_string, _content);
    buffer_save(_buffer, _filename);
    buffer_delete(_buffer);
}

#region jsDoc
/// @func    json_load(_filename)
/// @desc    Returns the value stored as JSON in a file, or undefined when the file is missing or is not valid JSON.
/// @param   {String} _filename : Path of the JSON file to load
/// @returns {Any}
#endregion
function json_load(_filename) {
	var _text = gmlc_file_read_all_text(_filename);
	if (_text == undefined) return undefined;
    try {
		return json_parse(_text);
	}
	catch (_error) {
        return undefined;
    }
}

#region jsDoc
/// @func    json_save(_filename, _value)
/// @desc    Saves a value (struct, array, string or number) to a file as indented JSON.
/// @param   {String} _filename : Path of the JSON file to write
/// @param   {Any}    _value    : The value to save
#endregion
function json_save(_filename, _value) {
	file_write_all_text(_filename, json_stringify(_value, true));
}
