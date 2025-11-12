#region JSDocs
/// @function file_find_all(filename)
/// @description Reads entire content of a given file as a string, or returns undefined if the file doesn't exist.
/// @param {string} mask        The mask to use for searching.
/// @return {array<string>}
#endregion
function file_find_all(_file_mask) {
    var file_names = [];
	var file_name = file_find_first(_file_mask, fa_none);
	while (file_name != "") {
	    array_push(file_names, file_name);
	    file_name = file_find_next();
	}
	file_find_close();
	return file_names;
}

#region JSDocs
/// @function file_read_all_text(filename)
/// @description Reads entire content of a given file as a string, or returns undefined if the file doesn't exist.
/// @param {string} filename        The path of the file to read the content of.
#endregion
function file_read_all_text(_filename) {
    if (!file_exists(_filename)) {
        return undefined;
    }
    
    var _buffer = buffer_load(_filename);
	var _result = (buffer_get_size(_buffer)) ? buffer_read(_buffer, buffer_string) : undefined;
    buffer_delete(_buffer);
    return _result;
}

#region JSDocs
/// @function file_write_all_text(filename,content)
/// @description Creates or overwrites a given file with the given string content.
/// @param {string} filename        The path of the file to create/overwrite.
/// @param {string} content            The content to create/overwrite the file with.
#endregion
function file_write_all_text(_filename, _content) {
    var _buffer = buffer_create(string_length(_content), buffer_grow, 1);
    buffer_write(_buffer, buffer_string, _content);
    buffer_save(_buffer, _filename);
    buffer_delete(_buffer);
}

#region JSDocs
/// @function json_load(filename)
/// @description Loads a given JSON file into a GML value (struct/array/string/real).
/// @param {string} filename        The path of the JSON file to load.
#endregion
function json_load(_filename) {
    var _json_content = file_read_all_text(_filename);
    if (is_undefined(_json_content))
        return undefined;
    
    try {
        return json_parse(_json_content);
    } catch (_) {
        // if the file content isn't a valid JSON, prevent crash and return undefined instead
        return undefined;
    }
}

#region JSDocs
/// @function json_save(filename,value)
/// @description Saves a given GML value (struct/array/string/real) into a JSON file.
/// @param {string} filename        The path of the JSON file to save.
/// @param {any} value                The value to save as a JSON file.
#endregion
function json_save(_filename, _value) {
    var _json_content = json_stringify(_value, true);
    file_write_all_text(_filename, _json_content);
}
