#region Diagnostics
// the problems the stages find: warnings come back with a program, errors stop it.

#region jsDoc
/// @func    GMLC_Diagnostic(_code, _span, [_args], [_messageId])
/// @desc    One reported problem. Its severity and Feather code come from the catalog entry of its code.
/// @param   {String}           _code      : The code, GMLC and four digits
/// @param   {Struct.GMLC_Span} _span      : Where the problem is
/// @param   {Array<String>}    [_args]    : The values the message's template takes, none when left out
/// @param   {String}           [_messageId] : The code, or the code and a variant key ("GMLC1001.parent-call")
/// @returns {Struct.GMLC_Diagnostic}
#endregion
function GMLC_Diagnostic(_code, _span, _args = undefined, _messageId = _code) constructor {
	static __noArgs = []; // shared; args are never changed
	var _messages = __GmlcDataMessages();
	var _entry = _messages[$ _code];
	code = _code;
	feather_code = _entry.feather_code;
	severity = _entry.severity;
	span = _span;
	message_id = _messageId;
	args = _args ?? __noArgs;
	labels = [];
	fix = undefined;
}

#region jsDoc
/// @func    GMLC_Label(_span, _messageId, _args)
/// @desc    A second place a diagnostic points at, such as the bracket an error left unclosed.
/// @param   {Struct.GMLC_Span} _span      : The place
/// @param   {String}           _messageId : The code and a label key of the catalog ("GMLC1002.unclosed-delimiter")
/// @param   {Array<String>}    _args      : The values the label's template takes
/// @returns {Struct.GMLC_Label}
#endregion
function GMLC_Label(_span, _messageId, _args) constructor {
	span = _span;
	message_id = _messageId;
	args = _args;
}

#region jsDoc
/// @func    __gmlc_diagnostic_message(_diagnostic)
/// @desc    The text of a diagnostic: the template of its message id with `{0}`, `{1}`, ... replaced by its arguments.
/// @param   {Struct.GMLC_Diagnostic} _diagnostic : The diagnostic
/// @returns {String}
#endregion
function __gmlc_diagnostic_message(_diagnostic) {
	// a label has no code of its own: its message id starts with its diagnostic's
	var _code = string_copy(_diagnostic.message_id, 1, 8);
	var _messages = __GmlcDataMessages();
	var _entry = _messages[$ _code];
	var _template = _entry.template;
	if (_diagnostic.message_id != _code) {
		var _variant = string_delete(_diagnostic.message_id, 1, 9);
		_template = _entry.variants[$ _variant] ?? _entry.labels[$ _variant] ?? _template;
	}
	// one pass over the template, so an argument that holds `{1}` is never replaced again
	var _out = "";
	var _from = 1;
	var _open = string_pos("{", _template);
	while (_open > 0) {
		var _close = string_pos_ext("}", _template, _open);
		if (_close == 0) break;
		var _inside = string_copy(_template, _open + 1, _close - _open - 1);
		var _index = (_inside != "") && (string_digits(_inside) == _inside) ? real(_inside) : -1;
		_out += string_copy(_template, _from, _open - _from);
		if (_index >= 0) && (_index < array_length(_diagnostic.args)) {
			_out += _diagnostic.args[_index];
		}
		else {
			_out += string_copy(_template, _open, _close - _open + 1);
		}
		_from = _close + 1;
		_open = string_pos_ext("{", _template, _from);
	}
	return _out + string_copy(_template, _from, string_length(_template) - _from + 1);
}

#region jsDoc
/// @func    __gmlc_sort_diagnostics(_diagnostics)
/// @desc    The diagnostics in report order, by file, start, end, code, message id and arguments, without exact
///          duplicates, so the result does not depend on the order the stages ran in.
/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : The diagnostics
/// @returns {Array<Struct.GMLC_Diagnostic>} A sorted copy
#endregion
function __gmlc_sort_diagnostics(_diagnostics) {
	#region jsDoc
	/// @func    __compare(_a, _b)
	/// @desc    The report order of two diagnostics: negative, zero (same) or positive, for array_sort.
	/// @param   {Struct.GMLC_Diagnostic} _a : One diagnostic
	/// @param   {Struct.GMLC_Diagnostic} _b : The other
	/// @returns {Real}
	#endregion
	static __compare = function(_a, _b) {
		if (_a.span.file != _b.span.file) return _a.span.file - _b.span.file;
		if (_a.span.start != _b.span.start) return _a.span.start - _b.span.start;
		if (_a.span[$ "end"] != _b.span[$ "end"]) return _a.span[$ "end"] - _b.span[$ "end"];
		if (_a.code != _b.code) return (_a.code < _b.code) ? -1 : 1;
		if (_a.message_id != _b.message_id) return (_a.message_id < _b.message_id) ? -1 : 1;
		var _n = min(array_length(_a.args), array_length(_b.args));
		var _i = 0; repeat (_n) {
			if (_a.args[_i] != _b.args[_i]) return (_a.args[_i] < _b.args[_i]) ? -1 : 1;
		_i++}
		return array_length(_a.args) - array_length(_b.args);
	};
	var _sorted = array_create(array_length(_diagnostics));
	array_copy(_sorted, 0, _diagnostics, 0, array_length(_diagnostics));
	array_sort(_sorted, __compare);
	var _out = [];
	var _i = 0; repeat (array_length(_sorted)) {
		if (_i == 0) || (__compare(_sorted[_i - 1], _sorted[_i]) != 0) array_push(_out, _sorted[_i]);
	_i++}
	return _out;
}

#region jsDoc
/// @func    gmlc_diagnostics_to_text(_diagnostics, _sources)
/// @desc    The diagnostics as text for people: severity, code and message, then where (file:line:column), the line
///          and a mark under the problem, and the Feather code when there is one.
/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : The diagnostics
/// @param   {Struct.GMLC_SourceTable}       _sources     : The compile's files
/// @returns {String}
#endregion
function gmlc_diagnostics_to_text(_diagnostics, _sources) {
	var _list = __gmlc_sort_diagnostics(_diagnostics);
	_sources ??= new GMLC_SourceTable();
	var _out = "";
	var _i = 0; repeat (array_length(_list)) {
		var _d = _list[_i];
		var _at = _sources.position(_d.span);
		var _gutter = string_repeat(" ", string_length(string(_at.line)));
		_out += $"{_d.severity}[{_d.code}]: {__gmlc_diagnostic_message(_d)}\n";
		_out += $"{_gutter}--> {_at.fileName}:{_at.line}:{_at.column}\n";
		if (_at.line > 0) {
			var _file = _sources.files[_d.span.file];
			var _endColumn = (_file.lineOf(_d.span[$ "end"]) == _at.line) ? _file.columnOf(_d.span[$ "end"]) : string_length(_at.lineString) + 1;
			var _width = max(1, _endColumn - _at.column);
			// under the line before the mark: its tabs kept, every other character a space, so the mark lines up
			var _lead = string_copy(_at.lineString, 1, _at.column - 1);
			var _pad = "";
			var _c = 1; repeat (string_length(_lead)) {
				_pad += (string_char_at(_lead, _c) == "\t") ? "\t" : " ";
			_c++}
			_out += $"{_gutter} |\n{_at.line} | {_at.lineString}\n{_gutter} | {_pad}{string_repeat("^", _width)}\n";
		}
		var _l = 0; repeat (array_length(_d.labels)) {
			var _label = _d.labels[_l];
			var _labelAt = _sources.position(_label.span);
			_out += $"{_gutter} = {_labelAt.fileName}:{_labelAt.line}:{_labelAt.column}: {__gmlc_diagnostic_message(_label)}\n";
		_l++}
		if (_d.feather_code != undefined) _out += $"{_gutter} = note: Feather {_d.feather_code}\n";
	_i++}
	return _out;
}

#region jsDoc
/// @func    gmlc_diagnostics_to_json(_diagnostics, _sources, [_pretty])
/// @desc    The diagnostics as the `diagnostics` stage dump: the dump envelope whose root is the sorted records,
///          each without its rendered text.
/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : The diagnostics
/// @param   {Struct.GMLC_SourceTable}       _sources     : The compile's files
/// @param   {Bool}                          [_pretty]    : Indent the output for reading
/// @returns {String}
#endregion
function gmlc_diagnostics_to_json(_diagnostics, _sources, _pretty = false) {
	return gmlc_ast_to_json(__gmlc_sort_diagnostics(_diagnostics), _sources, "diagnostics", _pretty);
}

#region jsDoc
/// @func    __gmlc_has_errors(_diagnostics)
/// @desc    Whether a list holds an error-level diagnostic.
/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : The diagnostics
/// @returns {Bool}
#endregion
function __gmlc_has_errors(_diagnostics) {
	var _i = 0; repeat (array_length(_diagnostics)) {
		if (_diagnostics[_i].severity == "error") return true;
	_i++}
	return false;
}

#region jsDoc
/// @func    __gmlc_internal_error(_message, [_span], [_sources])
/// @desc    Stops a compile at a fault of GMLC itself (a stage was given a tree it cannot handle): GMLC5901 with the
///          message, thrown as a stage's errors are. Errors of the compiled program while it runs are not diagnostics
///          and are thrown with throw_gmlc_error.
/// @param   {String}                  _message   : What went wrong
/// @param   {Struct.GMLC_Span}        [_span]    : Where, when known
/// @param   {Struct.GMLC_SourceTable} [_sources] : The compile's files, for the position
#endregion
function __gmlc_internal_error(_message, _span = undefined, _sources = undefined) {
	__gmlc_throw_diagnostics([new GMLC_Diagnostic("GMLC5901", _span ?? new GMLC_Span(0, 0, 0), [_message])], _sources);
}

#region jsDoc
/// @func    __gmlc_throw_diagnostics(_diagnostics, _sources)
/// @desc    Stops a compile on its first error.
/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : The diagnostics, at least one an error
/// @param   {Struct.GMLC_SourceTable}       _sources     : The compile's files, for the position
#endregion
function __gmlc_throw_diagnostics(_diagnostics, _sources) {
	throw __gmlc_diagnostics_error(_diagnostics, _sources);
}

#region jsDoc
/// @func    __gmlc_diagnostics_error(_diagnostics, _sources)
/// @desc    The error struct of a compile's first error (message "CODE: text", script, line, column,
///          lineString) with every diagnostic so far under `diagnostics`.
/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : The diagnostics, at least one an error
/// @param   {Struct.GMLC_SourceTable}       _sources     : The compile's files, for the position
/// @returns {Struct}
#endregion
function __gmlc_diagnostics_error(_diagnostics, _sources) {
	var _list = __gmlc_sort_diagnostics(_diagnostics);
	var _first = undefined;
	var _i = 0; repeat (array_length(_list)) {
		if (_list[_i].severity == "error") {
			_first = _list[_i];
			break;
		}
	_i++}
	_first ??= _list[0];
	var _at = (_sources ?? new GMLC_SourceTable()).position(_first.span);
	return {
		message: _first.code + ": " + __gmlc_diagnostic_message(_first),
		script: _at.fileName,
		line: _at.line,
		column: _at.column,
		lineString: _at.lineString,
		stacktrace: debug_get_callstack(),
		diagnostics: _list,
	};
}
#endregion

#region Suppressions
#region jsDoc
/// @func    __gmlc_suppress_diagnostics(_diagnostics, _sources)
/// @desc    The diagnostics left by the `// gmlc-ignore CODE[, CODE]: reason` comments of their files: a comment on
///          its own line covers the next line with code, one after code covers its own line, and a code may be a
///          prefix (GMLC31). Errors are never suppressed. A comment without a reason adds GMLC5401 (it still applies),
///          a code that no diagnostic has GMLC5403.
/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : The diagnostics of a compile
/// @param   {Struct.GMLC_SourceTable}       _sources     : Its files
/// @param   {Real}                          [_file]      : Only this file's comments (one unit of a batch)
/// @returns {Array<Struct.GMLC_Diagnostic>}
#endregion
function __gmlc_suppress_diagnostics(_diagnostics, _sources, _file = undefined) {
	if (_sources == undefined) return _diagnostics;
	var _rules = []; // {file, line, codes}
	var _added = [];
	var _f = 0; repeat (array_length(_sources.files)) {
		var _source = _sources.files[_f];
		if (_source != undefined) && ((_file == undefined) || (_file == _f)) && (string_pos("gmlc-ignore", _source.source) > 0) __gmlc_suppressions(_source, _rules, _added);
	_f++}
	if (array_length(_rules) == 0) && (array_length(_added) == 0) return _diagnostics;
	var _kept = [];
	var _d = 0; repeat (array_length(_diagnostics)) {
		if (!__gmlc_suppressed(_diagnostics[_d], _rules, _sources)) array_push(_kept, _diagnostics[_d]);
	_d++}
	array_copy(_kept, array_length(_kept), _added, 0, array_length(_added));
	return _kept;
}

#region jsDoc
/// @func    __gmlc_suppressed(_diagnostic, _rules, _sources)
/// @desc    Whether a suppression comment covers a diagnostic's line and code. Errors never are.
/// @param   {Struct.GMLC_Diagnostic}  _diagnostic : The diagnostic
/// @param   {Array<Struct>}           _rules      : The suppressions, {file, line, codes}
/// @param   {Struct.GMLC_SourceTable} _sources    : The compile's files
/// @returns {Bool}
#endregion
function __gmlc_suppressed(_diagnostic, _rules, _sources) {
	if (_diagnostic.severity == "error") return false;
	var _file = _diagnostic.span.file;
	if (_file >= array_length(_sources.files)) || (_sources.files[_file] == undefined) return false;
	var _line = _sources.files[_file].lineOf(_diagnostic.span.start);
	var _r = 0; repeat (array_length(_rules)) {
		var _rule = _rules[_r];
		if (_rule.file == _file) && (_rule.line == _line) {
			var _c = 0; repeat (array_length(_rule.codes)) {
				if (string_pos(_rule.codes[_c], _diagnostic.code) == 1) return true;
			_c++}
		}
	_r++}
	return false;
}

#region jsDoc
/// @func    __gmlc_suppressions(_file, _rules, _added)
/// @desc    The suppressions of one file: its line comments, found outside strings and block comments.
#endregion
function __gmlc_suppressions(_file, _rules, _added) {
	var _text = _file.source;
	var _n = string_byte_length(_text);
	var _b = buffer_create(_n + 1, buffer_fixed, 1);
	buffer_write(_b, buffer_text, _text);
	var _pending = []; // the codes of comments on their own lines, for the next line with code
	var _line = 1;
	var _hasCode = false;
	var _i = 0;
	while (_i < _n) {
		var _c = buffer_peek(_b, _i, buffer_u8);
		var _next = (_i + 1 < _n) ? buffer_peek(_b, _i + 1, buffer_u8) : 0;
		if (_c == 10) {
			_line++;
			_hasCode = false;
			_i++;
			continue;
		}
		if (_c == 32) || (_c == 9) || (_c == 13) {
			_i++;
			continue;
		}
		if (_c == 47) && (_next == 47) {
			var _end = _i;
			while (_end < _n) && (buffer_peek(_b, _end, buffer_u8) != 10) _end++;
			__gmlc_suppression(__gmlc_byte_copy(_text, _i + 2, _end), new GMLC_Span(_file.file_id, _i, _end), _line, _hasCode, _rules, _pending, _added);
			_i = _end;
			continue;
		}
		if (_c == 47) && (_next == 42) {
			_i += 2;
			while (_i < _n) && !((buffer_peek(_b, _i, buffer_u8) == 42) && (_i + 1 < _n) && (buffer_peek(_b, _i + 1, buffer_u8) == 47)) {
				if (buffer_peek(_b, _i, buffer_u8) == 10) {
					_line++;
					_hasCode = false;
				}
				_i++;
			}
			_i += 2;
			continue;
		}
		if (!_hasCode) {
			_hasCode = true;
			var _p = 0; repeat (array_length(_pending)) {
				array_push(_rules, { file: _file.file_id, line: _line, codes: _pending[_p] });
			_p++}
			_pending = [];
		}
		if (_c == 64) && ((_next == 34) || (_next == 39)) {
			// a verbatim string, which may span lines
			_i += 2;
			while (_i < _n) && (buffer_peek(_b, _i, buffer_u8) != _next) {
				if (buffer_peek(_b, _i, buffer_u8) == 10) _line++;
				_i++;
			}
			_i++;
			continue;
		}
		if (_c == 34) {
			_i++;
			while (_i < _n) {
				var _s = buffer_peek(_b, _i, buffer_u8);
				if (_s == 34) || (_s == 10) break;
				_i += (_s == 92) ? 2 : 1;
			}
			if (_i < _n) && (buffer_peek(_b, _i, buffer_u8) == 34) _i++;
			continue;
		}
		_i++;
	}
	buffer_delete(_b);
}

#region jsDoc
/// @func    __gmlc_suppression(_comment, _span, _line, _hasCode, _rules, _pending, _added)
/// @desc    Reads one line comment: a `gmlc-ignore` comment adds its codes to _rules (after code) or _pending (on its own
///          line), and GMLC5401 or GMLC5403 to _added when it has no reason or names an unknown code.
/// @param   {String}                        _comment : The comment's text after `//`
/// @param   {Struct.GMLC_Span}              _span    : Where the comment is
/// @param   {Real}                          _line    : Its line
/// @param   {Bool}                          _hasCode : Whether code comes before it on its line
/// @param   {Array<Struct>}                 _rules   : The suppressions found so far
/// @param   {Array<Array<String>>}          _pending : Codes waiting for the next line with code
/// @param   {Array<Struct.GMLC_Diagnostic>} _added   : The diagnostics the comments add
#endregion
function __gmlc_suppression(_comment, _span, _line, _hasCode, _rules, _pending, _added) {
	var _t = string_trim(_comment);
	if (string_pos("gmlc-ignore", _t) != 1) return;
	_t = string_delete(_t, 1, 11);
	if (_t != "") && (string_char_at(_t, 1) != " ") && (string_char_at(_t, 1) != "	") return;
	var _colon = string_pos(":", _t);
	var _reason = (_colon > 0) ? string_trim(string_delete(_t, 1, _colon)) : "";
	var _parts = string_split((_colon > 0) ? string_copy(_t, 1, _colon - 1) : _t, ",", true);
	var _codes = [];
	var _messages = __GmlcDataMessages();
	var _p = 0; repeat (array_length(_parts)) {
		var _code = string_trim(_parts[_p]);
		if (_code != "") {
			array_push(_codes, _code);
			var _known = struct_exists(_messages, _code);
			if (!_known) {
				var _names = struct_get_names(_messages);
				var _k = 0; repeat (array_length(_names)) {
					if (string_pos(_code, _names[_k]) == 1) {
						_known = true;
						break;
					}
				_k++}
			}
			if (!_known) array_push(_added, new GMLC_Diagnostic("GMLC5403", _span, [_code]));
		}
	_p++}
	if (_reason == "") array_push(_added, new GMLC_Diagnostic("GMLC5401", _span, [string_join_ext(", ", _codes)]));
	if (_hasCode) array_push(_rules, { file: _span.file, line: _line, codes: _codes });
	else array_push(_pending, _codes);
}
#endregion
