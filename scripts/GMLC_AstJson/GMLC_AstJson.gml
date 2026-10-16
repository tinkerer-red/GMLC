// the JSON form of a syntax tree, for dumps and for trees made outside GMLC:
//   {"stage": "parsed", "contract_version": 2, "files": [{"id", "name", "project", "text"}...], "root": <node>}
// the files carry their text, so a program compiled from a dump still gives the line of an error.
// GameMaker's json_parse reads an integer above 2^53 back as an int64; JSON has no nan or infinities, so they are
// the strings "nan", "inf", "-inf".

#region jsDoc
/// @func    gmlc_ast_contract_version()
/// @desc    The version of the node table that dumps are written in; a reader refuses any other.
/// @returns {Real}
#endregion
function gmlc_ast_contract_version() {
	return 2;
}

#region Writer
#region jsDoc
/// @func    gmlc_ast_to_json(_ast, _sources, [_stage], [_pretty])
/// @desc    The JSON dump of a tree: the envelope with the stage, the contract version, the files of the compile and
///          the tree.
/// @param   {Struct.ASTNode}          _ast      : The tree
/// @param   {Struct.GMLC_SourceTable} _sources  : The compile's files
/// @param   {String}                  [_stage]  : "parsed", "resolved", ...
/// @param   {Bool}                    [_pretty] : Indent the output for reading
/// @returns {String}
#endregion
function gmlc_ast_to_json(_ast, _sources, _stage = "parsed", _pretty = false) {
	var _w = { buffer: buffer_create(4096, buffer_grow, 1), pretty: _pretty, depth: 0 };
	__gmlc_json_open(_w, "{");
	__gmlc_json_key(_w, "stage", true);
	__gmlc_json_text(_w, json_stringify(_stage));
	__gmlc_json_key(_w, "contract_version", false);
	__gmlc_json_text(_w, string(gmlc_ast_contract_version()));
	__gmlc_json_key(_w, "files", false);
	__gmlc_json_open(_w, "[");
	var _files = (_sources != undefined) ? _sources.files : [];
	var _first = true;
	var _i = 0; repeat (array_length(_files)) {
		var _file = _files[_i];
		if (_file != undefined) {
			__gmlc_json_item(_w, _first);
			_first = false;
			__gmlc_json_open(_w, "{");
			__gmlc_json_key(_w, "id", true);
			__gmlc_json_text(_w, string(_file.file_id));
			__gmlc_json_key(_w, "name", false);
			__gmlc_json_text(_w, json_stringify(_file.name));
			__gmlc_json_key(_w, "project", false);
			__gmlc_json_text(_w, (_file.project == undefined) ? "null" : json_stringify(_file.project));
			__gmlc_json_key(_w, "text", false);
			__gmlc_json_text(_w, json_stringify(_file.source));
			__gmlc_json_close(_w, "}");
		}
	_i++}
	__gmlc_json_close(_w, "]");
	__gmlc_json_key(_w, "root", false);
	__gmlc_json_value(_w, _ast);
	__gmlc_json_close(_w, "}");
	
	// bytes that are not UTF-8 are written as U+FFFD, so the dump is UTF-8
	var _lossy = false;
	_i = 0; repeat (array_length(_files)) {
		if (_files[_i][$ "invalid_utf8"] == true) _lossy = true;
	_i++}
	if (_lossy) {
		var _out = __gmlc_lossy_utf8_buffer(_w.buffer, buffer_tell(_w.buffer));
		buffer_delete(_w.buffer);
		_w.buffer = _out;
	}
	buffer_write(_w.buffer, buffer_u8, 0);
	buffer_seek(_w.buffer, buffer_seek_start, 0);
	var _text = buffer_read(_w.buffer, buffer_string);
	buffer_delete(_w.buffer);
	return _text;
}

#region jsDoc
/// @func    __gmlc_json_node(_w, _node)
/// @desc    A node in its field order: kind, span, the kind's fields, origin.
#endregion
function __gmlc_json_node(_w, _node) {
	__gmlc_json_open(_w, "{");
	__gmlc_json_key(_w, "kind", true);
	__gmlc_json_text(_w, json_stringify(_node.kindName));
	__gmlc_json_key(_w, "span", false);
	__gmlc_json_value(_w, _node.span);
	var _fields = _node.fields;
	var _i = 0; repeat (array_length(_fields)) {
		var _field = _fields[_i];
		__gmlc_json_key(_w, _field, false);
		if (_field == "value") && (_node.kind == __GMLC_NodeKind_Literal) {
			__gmlc_json_text(_w, __gmlc_json_literal_value(_node.ty, _node.value));
		}
		else {
			__gmlc_json_value(_w, _node[$ _field]);
		}
	_i++}
	__gmlc_json_key(_w, "origin", false);
	__gmlc_json_value(_w, _node.origin);
	__gmlc_json_close(_w, "}");
}

#region jsDoc
/// @func    __gmlc_json_record_fields(_record)
/// @desc    The fields of a contract record (span, symbol, origin, ...) in their written order.
/// @param   {Struct} _record : The record
/// @returns {Array<String>}
#endregion
function __gmlc_json_record_fields(_record) {
	static __span = ["file", "start", "end"];
	static __symbol = ["kind", "name", "slot"];
	static __origin = ["kind", "name", "member", "config", "def_span", "use_span"];
	static __region = ["span", "is_end", "title"];
	static __pragma = ["pragma", "span", "target"];
	static __function = ["fn_id", "name", "fn_kind", "registration", "binding", "parent_fn", "params", "locals", "statics", "facts"];
	static __facts = ["statement_count", "node_count", "uses_argument_array", "uses_argument_count", "max_argument_index",
		"has_statics", "has_nested_functions", "contains_with", "contains_exit", "contains_try", "reads_other",
		"uses_compile_time_names", "direct_recursion", "single_trailing_return"];
	static __diagnostic = ["code", "feather_code", "severity", "span", "message_id", "args", "labels", "fix"];
	static __label = ["span", "message_id", "args"];
	static __unit = ["tokens", "macros", "enums", "regions", "pragmas"];
	if (is_instanceof(_record, GMLC_Span)) return __span;
	if (is_instanceof(_record, GMLC_Symbol)) return __symbol;
	if (is_instanceof(_record, GMLC_Origin)) return __origin;
	if (is_instanceof(_record, GMLC_Region)) return __region;
	if (is_instanceof(_record, GMLC_Pragma)) return __pragma;
	if (is_instanceof(_record, GMLC_FunctionInfo)) return __function;
	if (is_instanceof(_record, GMLC_FunctionFacts)) return __facts;
	if (is_instanceof(_record, GMLC_Diagnostic)) return __diagnostic;
	if (is_instanceof(_record, GMLC_Label)) return __label;
	if (is_instanceof(_record, GMLC_PreprocessedUnit)) return __unit;
	__gmlc_internal_error($"a {instanceof(_record)} struct is not a record of the AST contract");
}

#region jsDoc
/// @func    __gmlc_json_value(_w, _value)
/// @desc    Writes any value of a dump: null, bool, string, number, array, node, token or record.
/// @param   {Struct} _w     : The writer, {buffer, pretty, depth}
/// @param   {Any}    _value : The value
#endregion
function __gmlc_json_value(_w, _value) {
	if (is_undefined(_value)) {
		__gmlc_json_text(_w, "null");
	}
	else if (is_bool(_value)) {
		__gmlc_json_text(_w, _value ? "true" : "false");
	}
	else if (is_string(_value)) {
		__gmlc_json_text(_w, json_stringify(_value));
	}
	else if (is_numeric(_value)) {
		__gmlc_json_text(_w, __gmlc_json_number(_value));
	}
	else if (is_array(_value)) {
		__gmlc_json_open(_w, "[");
		var _i = 0; repeat (array_length(_value)) {
			__gmlc_json_item(_w, _i == 0);
			__gmlc_json_value(_w, _value[_i]);
		_i++}
		__gmlc_json_close(_w, "]");
	}
	else if (is_instanceof(_value, ASTNode)) {
		__gmlc_json_node(_w, _value);
	}
	else if (is_instanceof(_value, __GMLC_create_token)) {
		__gmlc_json_token(_w, _value);
	}
	else if (is_struct(_value)) {
		var _fields = __gmlc_json_record_fields(_value);
		__gmlc_json_open(_w, "{");
		var _i = 0; repeat (array_length(_fields)) {
			__gmlc_json_key(_w, _fields[_i], _i == 0);
			__gmlc_json_value(_w, _value[$ _fields[_i]]);
		_i++}
		__gmlc_json_close(_w, "}");
	}
	else {
		__gmlc_internal_error($"a {typeof(_value)} cannot be written to an AST dump");
	}
}

#region jsDoc
/// @func    __gmlc_json_token(_w, _token)
/// @desc    A token as the contract's Token record: kind (its name), span, text, ty (numbers only), value and origin.
///          The value is the token's meaning where its kind has one (keyword, canonical operator, number, unescaped
///          string, region word), null otherwise.
/// @param   {Struct} _w     : The writer
/// @param   {Struct} _token : The token
#endregion
function __gmlc_json_token(_w, _token) {
	static __kinds = ["Eof", "Illegal", "Newline", "Comment", "Region", "Backslash", "MacroDirective", "Identifier", "Keyword",
		"Number", "String", "TemplateFull", "TemplateHead", "TemplateMiddle", "TemplateTail", "Op"];
	var _kind = _token.kind;
	var _ty = undefined;
	var _value = "null";
	switch (_kind) {
		case __GMLC_TokenKind_Number: {
			_ty = _token[$ "ty"] ?? (is_int64(_token.value) ? "int64" : "real");
			_value = __gmlc_json_literal_value(_ty, _token.value);
		break;}
		case __GMLC_TokenKind_Keyword:
		case __GMLC_TokenKind_Op:
		case __GMLC_TokenKind_String:
		case __GMLC_TokenKind_TemplateFull:
		case __GMLC_TokenKind_TemplateHead:
		case __GMLC_TokenKind_TemplateMiddle:
		case __GMLC_TokenKind_TemplateTail:
		case __GMLC_TokenKind_Region: {
			_value = json_stringify(_token.value);
		break;}
	}
	__gmlc_json_open(_w, "{");
	__gmlc_json_key(_w, "kind", true);
	__gmlc_json_text(_w, json_stringify(__kinds[_kind]));
	__gmlc_json_key(_w, "span", false);
	__gmlc_json_value(_w, new GMLC_Span(_token.file, _token.start, _token[$ "end"]));
	__gmlc_json_key(_w, "text", false);
	__gmlc_json_text(_w, json_stringify(_token.name));
	__gmlc_json_key(_w, "ty", false);
	__gmlc_json_text(_w, (_ty == undefined) ? "null" : json_stringify(_ty));
	__gmlc_json_key(_w, "value", false);
	__gmlc_json_text(_w, _value);
	__gmlc_json_key(_w, "origin", false);
	__gmlc_json_value(_w, _token[$ "origin"]);
	__gmlc_json_close(_w, "}");
}

#region jsDoc
/// @func    __gmlc_json_number(_value)
/// @desc    A number as JSON: an int64 or a whole real by its digits, any other real with the digits that read back to
///          the same double; NaN and the infinities as the strings "nan", "inf" and "-inf", -0 as -0.0.
/// @param   {Real|Int64} _value : The number
/// @returns {String}
#endregion
function __gmlc_json_number(_value) {
	if (is_int64(_value)) return string(_value);
	if (is_nan(_value)) return "\"nan\"";
	if (is_infinity(_value)) return (_value > 0) ? "\"inf\"" : "\"-inf\"";
	if (__gmlc_is_zero(_value)) return (1 / _value < 0) ? "-0.0" : "0";
	if (__gmlc_is_whole(_value)) && (abs(_value) < 9007199254740992) return string(int64(_value));
	return json_stringify(_value);
}

#region jsDoc
/// @func    __gmlc_json_literal_value(_ty, _value)
/// @desc    The JSON of a Literal's value by its type: int64, color and real as numbers, strings,
///          bools and undefined as JSON.
/// @param   {String} _ty    : The literal's type
/// @param   {Any}    _value : The value
/// @returns {String}
#endregion
function __gmlc_json_literal_value(_ty, _value) {
	switch (_ty) {
		case "int64":
		case "color": return string(int64(_value));
		case "real": return __gmlc_json_number(real(_value));
		case "string": return json_stringify(_value);
		case "bool": return _value ? "true" : "false";
		case "undefined": return "null";
	}
	__gmlc_internal_error($"unknown literal type {_ty}");
}

#region jsDoc
/// @func    __gmlc_lossy_utf8(_text)
/// @desc    The text with each byte that does not start a valid UTF-8 sequence replaced by U+FFFD.
/// @param   {String} _text : The text
/// @returns {String}
#endregion
function __gmlc_lossy_utf8(_text) {
	var _size = string_byte_length(_text);
	var _in = buffer_create(_size + 1, buffer_fixed, 1);
	buffer_write(_in, buffer_text, _text);
	var _out = __gmlc_lossy_utf8_buffer(_in, _size);
	buffer_delete(_in);
	buffer_write(_out, buffer_u8, 0);
	buffer_seek(_out, buffer_seek_start, 0);
	var _result = buffer_read(_out, buffer_string);
	buffer_delete(_out);
	return _result;
}

#region jsDoc
/// @func    __gmlc_lossy_utf8_buffer(_in, _size)
/// @desc    A new buffer: the first _size bytes of _in, each byte that does not start a valid UTF-8
///          sequence written as U+FFFD.
#endregion
function __gmlc_lossy_utf8_buffer(_in, _size) {
	var _out = buffer_create(_size + 16, buffer_grow, 1);
	var _p = 0;
	while (_p < _size) {
		var _n = __gmlc_utf8_length(_in, _p, _size);
		if (_n == 0) {
			buffer_write(_out, buffer_u8, 0xEF);
			buffer_write(_out, buffer_u8, 0xBF);
			buffer_write(_out, buffer_u8, 0xBD);
			_p++;
		}
		else {
			buffer_copy(_in, _p, _n, _out, buffer_tell(_out));
			buffer_seek(_out, buffer_seek_relative, _n);
			_p += _n;
		}
	}
	return _out;
}

#region jsDoc
/// @func    __gmlc_utf8_length(_buffer, _p, _size)
/// @desc    The length of the valid UTF-8 sequence at a byte (shortest form, at most U+10FFFF, no
///          surrogate), 0 when none.
#endregion
function __gmlc_utf8_length(_buffer, _p, _size) {
	var _b = buffer_peek(_buffer, _p, buffer_u8);
	if (_b < 0x80) return 1;
	var _n = (_b >= 0xF0) ? 4 : ((_b >= 0xE0) ? 3 : ((_b >= 0xC0) ? 2 : 0));
	if (_n == 0) || (_p + _n > _size) return 0;
	var _cp = _b & ((_n == 2) ? 0x1F : ((_n == 3) ? 0x0F : 0x07));
	var _i = 1; repeat (_n - 1) {
		var _c = buffer_peek(_buffer, _p + _i, buffer_u8);
		if (_c < 0x80) || (_c > 0xBF) return 0;
		_cp = (_cp << 6) | (_c & 0x3F);
	_i++}
	if ((_n == 2) && (_cp < 0x80)) || ((_n == 3) && (_cp < 0x800)) || ((_n == 4) && (_cp < 0x10000)) return 0;
	if (_cp > 0x10FFFF) || ((_cp >= 0xD800) && (_cp <= 0xDFFF)) return 0;
	return _n;
}

#region jsDoc
/// @func    __gmlc_json_text(_w, _text)
/// @desc    Writes text as it is.
/// @param   {Struct} _w    : The writer, {buffer, pretty, depth}
/// @param   {String} _text : The text
#endregion
function __gmlc_json_text(_w, _text) {
	buffer_write(_w.buffer, buffer_text, _text);
}

#region jsDoc
/// @func    __gmlc_json_open(_w, _bracket)
/// @desc    Writes an opening bracket and goes one level deeper.
/// @param   {Struct} _w       : The writer, {buffer, pretty, depth}
/// @param   {String} _bracket : `{` or `[`
#endregion
function __gmlc_json_open(_w, _bracket) {
	buffer_write(_w.buffer, buffer_text, _bracket);
	_w.depth++;
}

#region jsDoc
/// @func    __gmlc_json_close(_w, _bracket)
/// @desc    Goes one level back and writes a closing bracket, on a new line when pretty.
/// @param   {Struct} _w       : The writer, {buffer, pretty, depth}
/// @param   {String} _bracket : `}` or `]`
#endregion
function __gmlc_json_close(_w, _bracket) {
	_w.depth--;
	if (_w.pretty) __gmlc_json_newline(_w);
	buffer_write(_w.buffer, buffer_text, _bracket);
}

#region jsDoc
/// @func    __gmlc_json_key(_w, _key, _first)
/// @desc    Writes an object's key, after a comma unless it is the first.
/// @param   {Struct} _w     : The writer, {buffer, pretty, depth}
/// @param   {String} _key   : The key
/// @param   {Bool}   _first : Whether it is the object's first key
#endregion
function __gmlc_json_key(_w, _key, _first) {
	__gmlc_json_item(_w, _first);
	buffer_write(_w.buffer, buffer_text, "\"" + _key + (_w.pretty ? "\": " : "\":"));
}

#region jsDoc
/// @func    __gmlc_json_item(_w, _first)
/// @desc    Starts an item: the comma unless it is the first, then its new line when pretty.
/// @param   {Struct} _w     : The writer, {buffer, pretty, depth}
/// @param   {Bool}   _first : Whether it is the first item
#endregion
function __gmlc_json_item(_w, _first) {
	if (!_first) buffer_write(_w.buffer, buffer_text, ",");
	if (_w.pretty) __gmlc_json_newline(_w);
}

#region jsDoc
/// @func    __gmlc_json_newline(_w)
/// @desc    Writes a new line and the indent of the current depth.
/// @param   {Struct} _w : The writer, {buffer, pretty, depth}
#endregion
function __gmlc_json_newline(_w) {
	buffer_write(_w.buffer, buffer_u8, 10);
	repeat (_w.depth) buffer_write(_w.buffer, buffer_text, "  ");
}
#endregion

#region Reader
#region jsDoc
/// @func    gmlc_ast_from_json(_text)
/// @desc    Reads a dump written with gmlc_ast_to_json: the envelope with the tree (an array of trees for a batch of
///          files) made of node constructors and the files as a source table. Throws when the contract version
///          differs or the dump has anything the contract does not.
/// @param   {String} _text : The JSON
/// @returns {Struct} {stage, sources, root}
#endregion
function gmlc_ast_from_json(_text) {
	// the filter must be a method: json_parse ignores a plain function
	static __filter = __vanilla_method(undefined, __gmlc_ast_json_filter);
	var _envelope = json_parse(_text, __filter, true);
	if (_envelope[$ "contract_version"] != gmlc_ast_contract_version()) {
		__gmlc_internal_error($"the AST dump has contract version {_envelope[$ "contract_version"]}, GMLC reads {gmlc_ast_contract_version()}");
	}
	var _root = _envelope[$ "root"];
	var _trees = is_array(_root) ? _root : [_root];
	var _t = 0; repeat (array_length(_trees)) {
		if (!is_instanceof(_trees[_t], ASTNode)) {
			__gmlc_internal_error("the AST dump has no tree under \"root\"");
		}
	_t++}
	var _sources = new GMLC_SourceTable();
	var _files = _envelope[$ "files"] ?? [];
	var _i = 0; repeat (array_length(_files)) {
		var _file = _files[_i];
		_sources.add(new GMLC_SourceFile(real(_file.id), _file.name, _file[$ "text"] ?? "", undefined, _file[$ "project"]));
	_i++}
	return { stage: _envelope[$ "stage"], sources: _sources, root: _envelope.root };
}

#region jsDoc
/// @func    __gmlc_ast_json_filter(_key, _value)
/// @desc    The json_parse filter of the reader. A record is known by the field that holds it (`span`, `symbol`,
///          `origin`, `regions`, ...); any other object with a "kind" is a node, built by its kind's constructor with
///          all of its fields; values are converted to their contract type. Every other value is kept.
/// @param   {Any} _key   : The value's key or index
/// @param   {Any} _value : The value, its children already read
/// @returns {Any}
#endregion
function __gmlc_ast_json_filter(_key, _value) {
	switch (_key) {
		case "span":
		case "def_span":
		case "use_span": return __gmlc_json_read_span(_value);
		case "symbol": {
			if (_value == undefined) return undefined;
			return new GMLC_Symbol(_value.kind, _value.name, (_value[$ "slot"] != undefined) ? real(_value.slot) : undefined);
		}
		case "origin": {
			if (_value == undefined) return undefined;
			return new GMLC_Origin(_value.kind, _value.name, _value[$ "member"], _value[$ "config"], _value[$ "def_span"], _value.use_span);
		}
		case "regions": {
			var _i = 0; repeat (array_length(_value)) {
				var _r = _value[_i];
				_value[_i] = new GMLC_Region(_r.span, bool(_r.is_end), _r.title);
			_i++}
			return _value;
		}
		case "pragmas": {
			var _i = 0; repeat (array_length(_value)) {
				var _p = _value[_i];
				_value[_i] = new GMLC_Pragma(_p.pragma, _p.span, __gmlc_json_read_span(_p[$ "target"]));
			_i++}
			return _value;
		}
		case "functions": {
			var _i = 0; repeat (array_length(_value)) {
				var _f = _value[_i];
				var _info = new GMLC_FunctionInfo(real(_f.fn_id), _f[$ "name"], (_f[$ "parent_fn"] != undefined) ? real(_f.parent_fn) : undefined,
					_f.params, _f.locals, _f.statics);
				_info.fn_kind = _f[$ "fn_kind"];
				_info.registration = _f[$ "registration"];
				_info.binding = _f[$ "binding"];
				_info.facts = _f[$ "facts"];
				_value[_i] = _info;
			_i++}
			return _value;
		}
		case "facts": {
			if (_value == undefined) return undefined;
			var _facts = new GMLC_FunctionFacts();
			var _names = struct_get_names(_facts);
			var _i = 0; repeat (array_length(_names)) {
				var _field = _names[_i];
				var _read = _value[$ _field];
				_facts[$ _field] = is_bool(_facts[$ _field]) ? bool(_read) : real(_read);
			_i++}
			return _facts;
		}
	}
	if (!is_struct(_value)) return _value;
	var _kind = _value[$ "kind"];
	if (!is_string(_kind)) return _value;
	
	var _kinds = __gmlc_node_kinds();
	var _index = __gmlc_struct_get(_kinds.by_name, _kind);
	if (_index == undefined) {
		__gmlc_internal_error($"the AST dump has a node of unknown kind {_kind}");
	}
	var _constructor = _kinds.constructors[_index];
	var _node = new _constructor();
	var _fields = _node.fields;
	if (struct_names_count(_value) != array_length(_fields) + 3) {
		__gmlc_internal_error($"the {_kind} node of the AST dump does not have exactly kind, span, origin and the fields {_fields}");
	}
	var _i = 0; repeat (array_length(_fields)) {
		if (!struct_exists(_value, _fields[_i])) {
			__gmlc_internal_error($"the {_kind} node of the AST dump has no field {_fields[_i]}");
		}
		_node[$ _fields[_i]] = _value[$ _fields[_i]];
	_i++}
	_node.span = _value.span;
	_node.origin = _value[$ "origin"];
	
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal: {
			_node.value = __gmlc_json_read_literal_value(_node.ty, _value.value);
		break;}
		case __GMLC_NodeKind_EnumMember: {
			if (_node.value != undefined) _node.value = int64(_node.value);
		break;}
		case __GMLC_NodeKind_FunctionDecl:
		case __GMLC_NodeKind_ConstructorDecl:
		case __GMLC_NodeKind_FunctionExpr: {
			if (_node.fn_id != undefined) _node.fn_id = real(_node.fn_id);
		break;}
	}
	return _node;
}

#region jsDoc
/// @func    __gmlc_json_read_span(_value)
/// @desc    A span read from a dump; undefined for null.
/// @param   {Struct} _value : The parsed span, {file, start, end}
/// @returns {Struct.GMLC_Span}
#endregion
function __gmlc_json_read_span(_value) {
	if (_value == undefined) return undefined;
	return new GMLC_Span(real(_value.file), real(_value.start), real(_value[$ "end"]));
}

#region jsDoc
/// @func    __gmlc_json_read_literal_value(_ty, _value)
/// @desc    A Literal's value as its type; an int64 is made from the number json_parse gives, whatever
///          its size.
#endregion
function __gmlc_json_read_literal_value(_ty, _value) {
	switch (_ty) {
		case "int64":  return int64(_value);
		case "color": return real(_value);
		case "real": {
			if (is_string(_value)) {
				switch (_value) {
					case "nan":  return NaN;
					case "inf":  return infinity;
					case "-inf": return -infinity;
				}
				__gmlc_internal_error($"{_value} is not a real");
			}
			return real(_value);
		}
		case "bool":   return bool(_value);
	}
	return _value;
}
#endregion
