function __gmlc_convert_to_array_map(_map) {
	static __buff = buffer_create(0, buffer_grow, 1);
		
	var root = array_create(256, undefined); // Root node
		
	var _names = struct_get_names(_map);
	var _length = array_length(_names);
		
	for (var _i = 0; _i < _length; _i++) {
	    var _find = _names[_i];
	    var _replace = _map[$ _find];
			
	    buffer_write(__buff, buffer_text, _find);
	    var _byte_len = buffer_tell(__buff);
	    buffer_seek(__buff, buffer_seek_start, 0);
			
	    var node = root; // Start at root
	    var _j = 0;
			
	    while (_j < _byte_len) {
	        var _byte = buffer_read(__buff, buffer_u8);
	        _j++;
				
	        if (node[_byte] == undefined) {
	            node[_byte] = array_create(256, undefined); // Create new array node
	        }
	        node = node[_byte]; // Move to next depth
	    }
			
	    node[0] = _replace; // Store replacement in index `0`, since `0` in a string is a terminator byte.
			
	    buffer_resize(__buff, 0); // Reset buffer for next word
	}
		
	return root; // Return just the trie
};

function __gmlc_array_to_struct_map(_arr) {
	var _s = {};
	for (var i = 0; i < array_length(_arr); i++) {
		_s[$ _arr[i]] = _arr[i];
	}
	return _s;
}
