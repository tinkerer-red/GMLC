#region AST JSON
// The JSON form of a syntax tree, for dumps and for trees made outside GMLC. A dump is an envelope:
//   {"stage": "parsed", "contract_version": 1, "files": [{"id", "name", "project", "text"}...], "root": <node>}
// Every node is an object with "kind", "span", its kind's fields in order, then "origin"; records (Span, Symbol,
// Origin, Diagnostic, ...) are objects with their fields in order. Integers and int64 values are JSON numbers
// (GameMaker reads one above 2^53 back as an int64), reals keep the digits that read back to the same double, and the
// reals JSON has no number for are the strings "nan", "inf", "-inf". The files carry their text, so a program compiled
// from a dump still gives the line of an error.
// Reading is one json_parse whose filter turns each object into its constructor and each value into its contract
// type; anything the contract does not have is an error.

#region jsDoc
/// @func    GMLC_AstContractVersion()
/// @desc    The version of the node table that dumps are written in; a reader refuses any other.
/// @returns {Real}
#endregion
function GMLC_AstContractVersion() {
	return 1;
}

#region Writer
#region jsDoc
/// @func    GMLC_AstToJson(_ast, _sources, [_stage], [_pretty])
/// @desc    The JSON dump of a tree: the envelope with the stage, the contract version, the files of the compile and
///          the tree.
/// @param   {Struct.ASTNode}          _ast      : The tree
/// @param   {Struct.GMLC_SourceTable} _sources  : The compile's files
/// @param   {String}                  [_stage]  : "parsed", "resolved", ...
/// @param   {Bool}                    [_pretty] : Indent the output for reading
/// @returns {String}
#endregion
function GMLC_AstToJson(_ast, _sources, _stage = "parsed", _pretty = false) {
	var _w = { buffer: buffer_create(4096, buffer_grow, 1), pretty: _pretty, depth: 0 };
	__GMLC_jsonOpen(_w, "{");
	__GMLC_jsonKey(_w, "stage", true);
	__GMLC_jsonText(_w, json_stringify(_stage));
	__GMLC_jsonKey(_w, "contract_version", false);
	__GMLC_jsonText(_w, string(GMLC_AstContractVersion()));
	__GMLC_jsonKey(_w, "files", false);
	__GMLC_jsonOpen(_w, "[");
	var _files = (_sources != undefined) ? _sources.files : [];
	var _first = true;
	var _i = 0; repeat (array_length(_files)) {
		var _file = _files[_i];
		if (_file != undefined) {
			__GMLC_jsonItem(_w, _first);
			_first = false;
			__GMLC_jsonOpen(_w, "{");
			__GMLC_jsonKey(_w, "id", true);
			__GMLC_jsonText(_w, string(_file.fileId));
			__GMLC_jsonKey(_w, "name", false);
			__GMLC_jsonText(_w, json_stringify(_file.name));
			__GMLC_jsonKey(_w, "project", false);
			__GMLC_jsonText(_w, (_file.project == undefined) ? "null" : json_stringify(_file.project));
			__GMLC_jsonKey(_w, "text", false);
			__GMLC_jsonText(_w, json_stringify(_file.source));
			__GMLC_jsonClose(_w, "}");
		}
	_i++}
	__GMLC_jsonClose(_w, "]");
	__GMLC_jsonKey(_w, "root", false);
	__GMLC_jsonValue(_w, _ast);
	__GMLC_jsonClose(_w, "}");
	
	// bytes of a file that are not UTF-8 (the lexer reported GMLC0001) are written as U+FFFD, so the dump is UTF-8
	var _lossy = false;
	_i = 0; repeat (array_length(_files)) {
		if (_files[_i][$ "invalidUtf8"] == true) _lossy = true;
	_i++}
	if (_lossy) __GMLC_jsonReplaceInvalidUtf8(_w);
	buffer_write(_w.buffer, buffer_u8, 0);
	buffer_seek(_w.buffer, buffer_seek_start, 0);
	var _text = buffer_read(_w.buffer, buffer_string);
	buffer_delete(_w.buffer);
	return _text;
}

// a node: kind, span, the kind's fields in order, origin
function __GMLC_jsonNode(_w, _node) {
	__GMLC_jsonOpen(_w, "{");
	__GMLC_jsonKey(_w, "kind", true);
	__GMLC_jsonText(_w, json_stringify(_node.kindName));
	__GMLC_jsonKey(_w, "span", false);
	__GMLC_jsonValue(_w, _node.span);
	var _fields = _node.fields;
	var _i = 0; repeat (array_length(_fields)) {
		var _field = _fields[_i];
		__GMLC_jsonKey(_w, _field, false);
		if (_field == "value") && (_node.kind == __GMLC_NodeKind_Literal) {
			__GMLC_jsonText(_w, __GMLC_jsonLiteralValue(_node.ty, _node.value));
		}
		else {
			__GMLC_jsonValue(_w, _node[$ _field]);
		}
	_i++}
	__GMLC_jsonKey(_w, "origin", false);
	__GMLC_jsonValue(_w, _node.origin);
	__GMLC_jsonClose(_w, "}");
}

// the fields of a record in order, by its constructor
function __GMLC_jsonRecordFields(_record) {
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

function __GMLC_jsonValue(_w, _value) {
	if (is_undefined(_value)) {
		__GMLC_jsonText(_w, "null");
	}
	else if (is_bool(_value)) {
		__GMLC_jsonText(_w, _value ? "true" : "false");
	}
	else if (is_string(_value)) {
		__GMLC_jsonText(_w, json_stringify(_value));
	}
	else if (is_numeric(_value)) {
		__GMLC_jsonText(_w, __GMLC_jsonNumber(_value));
	}
	else if (is_array(_value)) {
		__GMLC_jsonOpen(_w, "[");
		var _i = 0; repeat (array_length(_value)) {
			__GMLC_jsonItem(_w, _i == 0);
			__GMLC_jsonValue(_w, _value[_i]);
		_i++}
		__GMLC_jsonClose(_w, "]");
	}
	else if (is_instanceof(_value, ASTNode)) {
		__GMLC_jsonNode(_w, _value);
	}
	else if (is_instanceof(_value, __GMLC_create_token)) {
		__GMLC_jsonToken(_w, _value);
	}
	else if (is_struct(_value)) {
		var _fields = __GMLC_jsonRecordFields(_value);
		__GMLC_jsonOpen(_w, "{");
		var _i = 0; repeat (array_length(_fields)) {
			__GMLC_jsonKey(_w, _fields[_i], _i == 0);
			__GMLC_jsonValue(_w, _value[$ _fields[_i]]);
		_i++}
		__GMLC_jsonClose(_w, "}");
	}
	else {
		__gmlc_internal_error($"a {typeof(_value)} cannot be written to an AST dump");
	}
}

#region jsDoc
/// @func    __GMLC_jsonToken(_w, _token)
/// @desc    A token as the contract's Token record: kind (its name), span, text, ty (numbers only), value and origin.
///          The value is the token's meaning where its kind has one (keyword, canonical operator, number, cooked
///          string, region word), null otherwise.
/// @param   {Struct} _w     : The writer
/// @param   {Struct} _token : The token
#endregion
function __GMLC_jsonToken(_w, _token) {
	static __kinds = ["Eof", "Illegal", "Newline", "Comment", "Region", "Backslash", "MacroDirective", "Identifier", "Keyword",
		"Number", "String", "TemplateFull", "TemplateHead", "TemplateMiddle", "TemplateTail", "Op"];
	var _kind = _token.kind;
	var _ty = undefined;
	var _value = "null";
	switch (_kind) {
		case __GMLC_TokenKind_Number: {
			_ty = _token[$ "ty"] ?? (is_int64(_token.value) ? "int64" : "real");
			_value = __GMLC_jsonLiteralValue(_ty, _token.value);
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
	__GMLC_jsonOpen(_w, "{");
	__GMLC_jsonKey(_w, "kind", true);
	__GMLC_jsonText(_w, json_stringify(__kinds[_kind]));
	__GMLC_jsonKey(_w, "span", false);
	__GMLC_jsonValue(_w, new GMLC_Span(_token.file, _token.start, _token[$ "end"]));
	__GMLC_jsonKey(_w, "text", false);
	__GMLC_jsonText(_w, json_stringify(_token.name));
	__GMLC_jsonKey(_w, "ty", false);
	__GMLC_jsonText(_w, (_ty == undefined) ? "null" : json_stringify(_ty));
	__GMLC_jsonKey(_w, "value", false);
	__GMLC_jsonText(_w, _value);
	__GMLC_jsonKey(_w, "origin", false);
	__GMLC_jsonValue(_w, _token[$ "origin"]);
	__GMLC_jsonClose(_w, "}");
}

#region jsDoc
/// @func    __GMLC_jsonNumber(_value)
/// @desc    A number as JSON: an int64 or a whole real by its digits, any other real with the digits that read back to
///          the same double; NaN and the infinities as the strings "nan", "inf" and "-inf", -0 as -0.0.
/// @param   {Real|Int64} _value : The number
/// @returns {String}
#endregion
function __GMLC_jsonNumber(_value) {
	if (is_int64(_value)) return string(_value);
	if (is_nan(_value)) return "\"nan\"";
	if (is_infinity(_value)) return (_value > 0) ? "\"inf\"" : "\"-inf\"";
	if (__gmlc_is_zero(_value)) return (1 / _value < 0) ? "-0.0" : "0";
	if (__gmlc_is_whole(_value)) && (abs(_value) < 9007199254740992) return string(int64(_value));
	return json_stringify(_value);
}

#region jsDoc
/// @func    __GMLC_jsonLiteralValue(_ty, _value)
/// @desc    The JSON of a Literal's value by its type: int64, colour and real as numbers (see __GMLC_jsonNumber), strings,
///          bools and undefined as JSON.
/// @param   {String} _ty    : The literal's type
/// @param   {Any}    _value : The value
/// @returns {String}
#endregion
function __GMLC_jsonLiteralValue(_ty, _value) {
	switch (_ty) {
		case "int64":
		case "colour": return string(int64(_value));
		case "real": return __GMLC_jsonNumber(real(_value));
		case "string": return json_stringify(_value);
		case "bool": return _value ? "true" : "false";
		case "undefined": return "null";
	}
	__gmlc_internal_error($"unknown literal type {_ty}");
}

// output: text, objects and arrays, keys and items, indented when pretty
function __GMLC_jsonReplaceInvalidUtf8(_w) {
	var _out = __GMLC_lossyUtf8Buffer(_w.buffer, buffer_tell(_w.buffer));
	buffer_delete(_w.buffer);
	_w.buffer = _out;
}

// a text with U+FFFD for each byte that is not part of a valid UTF-8 sequence
function __GMLC_lossyUtf8(_text) {
	var _size = string_byte_length(_text);
	var _in = buffer_create(_size + 1, buffer_fixed, 1);
	buffer_write(_in, buffer_text, _text);
	var _out = __GMLC_lossyUtf8Buffer(_in, _size);
	buffer_delete(_in);
	buffer_write(_out, buffer_u8, 0);
	buffer_seek(_out, buffer_seek_start, 0);
	var _result = buffer_read(_out, buffer_string);
	buffer_delete(_out);
	return _result;
}

// a new buffer holding the first _size bytes of _in with every byte that does not start a valid UTF-8 sequence
// replaced by U+FFFD (EF BF BD), written up to its end
function __GMLC_lossyUtf8Buffer(_in, _size) {
	var _out = buffer_create(_size + 16, buffer_grow, 1);
	var _p = 0;
	while (_p < _size) {
		var _n = __GMLC_utf8Length(_in, _p, _size);
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

// the length of the valid UTF-8 sequence at a byte (shortest form, at most U+10FFFF, no surrogate), 0 when none
function __GMLC_utf8Length(_buffer, _p, _size) {
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

function __GMLC_jsonText(_w, _text) {
	buffer_write(_w.buffer, buffer_text, _text);
}
function __GMLC_jsonOpen(_w, _bracket) {
	buffer_write(_w.buffer, buffer_text, _bracket);
	_w.depth++;
}
function __GMLC_jsonClose(_w, _bracket) {
	_w.depth--;
	if (_w.pretty) __GMLC_jsonNewline(_w);
	buffer_write(_w.buffer, buffer_text, _bracket);
}
function __GMLC_jsonKey(_w, _key, _first) {
	__GMLC_jsonItem(_w, _first);
	buffer_write(_w.buffer, buffer_text, "\"" + _key + (_w.pretty ? "\": " : "\":"));
}
function __GMLC_jsonItem(_w, _first) {
	if (!_first) buffer_write(_w.buffer, buffer_text, ",");
	if (_w.pretty) __GMLC_jsonNewline(_w);
}
function __GMLC_jsonNewline(_w) {
	buffer_write(_w.buffer, buffer_u8, 10);
	repeat (_w.depth) buffer_write(_w.buffer, buffer_text, "  ");
}
#endregion

#region Reader
#region jsDoc
/// @func    GMLC_AstFromJson(_text)
/// @desc    Reads a dump written with GMLC_AstToJson: the envelope with the tree made of node constructors and the
///          files as a source table. Throws when the contract version differs or the dump has anything the contract
///          does not.
/// @param   {String} _text : The JSON
/// @returns {Struct} {stage, sources, root}
#endregion
function GMLC_AstFromJson(_text) {
	// the filter must be a method: json_parse ignores a plain function
	static __filter = __vanilla_method(undefined, __GMLC_astJsonFilter);
	var _envelope = json_parse(_text, __filter, true);
	if (_envelope[$ "contract_version"] != GMLC_AstContractVersion()) {
		__gmlc_internal_error($"the AST dump has contract version {_envelope[$ "contract_version"]}, GMLC reads {GMLC_AstContractVersion()}");
	}
	if (!is_instanceof(_envelope[$ "root"], ASTNode)) {
		__gmlc_internal_error("the AST dump has no tree under \"root\"");
	}
	var _sources = new GMLC_SourceTable();
	var _files = _envelope[$ "files"] ?? [];
	var _i = 0; repeat (array_length(_files)) {
		var _file = _files[_i];
		_sources.add(new GMLC_SourceFile(real(_file.id), _file.name, _file[$ "text"] ?? "", undefined, _file[$ "project"]));
	_i++}
	return { stage: _envelope[$ "stage"], sources: _sources, root: _envelope.root };
}

#region jsDoc
/// @func    __GMLC_astJsonFilter(_key, _value)
/// @desc    The json_parse filter of the reader. A record is known by the field that holds it (`span`, `symbol`,
///          `origin`, `regions`, ...); any other object with a "kind" is a node, built by its kind's constructor with
///          all of its fields; values are converted to their contract type. Every other value is kept.
/// @param   {Any} _key   : The value's key or index
/// @param   {Any} _value : The value, its children already read
/// @returns {Any}
#endregion
function __GMLC_astJsonFilter(_key, _value) {
	switch (_key) {
		case "span":
		case "def_span":
		case "use_span": return __GMLC_jsonReadSpan(_value);
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
				_value[_i] = new GMLC_Pragma(_p.pragma, _p.span, __GMLC_jsonReadSpan(_p[$ "target"]));
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
	
	var _kinds = __GMLC_NodeKinds();
	var _index = __gmlc_struct_get(_kinds.byName, _kind);
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
			_node.value = __GMLC_jsonReadLiteralValue(_node.ty, _value.value);
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

// a span, its numbers as reals
function __GMLC_jsonReadSpan(_value) {
	if (_value == undefined) return undefined;
	return new GMLC_Span(real(_value.file), real(_value.start), real(_value[$ "end"]));
}

// a Literal's value as its type (int64 from the number json_parse gives, whatever its size)
function __GMLC_jsonReadLiteralValue(_ty, _value) {
	switch (_ty) {
		case "int64":  return int64(_value);
		case "colour": return real(_value);
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
#endregion
