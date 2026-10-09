#region Diagnostics
// The problems the stages find, one record per problem, with their order and their text and JSON forms. Each stage
// reports into its own list and the environment gathers them: warnings come back with a program, errors stop it.
// A message's text is its template in the generated catalogue (__GmlcMessagesData) with the arguments filled in.

#region jsDoc
/// @func    GMLC_Diagnostic(_code, _span, [_args], [_messageId])
/// @desc    One reported problem. Its severity and Feather code come from the catalogue entry of its code.
/// @param   {String}           _code      : The code, GMLC and four digits
/// @param   {Struct.GMLC_Span} _span      : Where the problem is
/// @param   {Array<String>}    [_args]    : The values the message's template takes, none when left out
/// @param   {String}           [_messageId] : The code, or the code and a variant key ("GMLC1001.parent-call")
/// @returns {Struct.GMLC_Diagnostic}
#endregion
function GMLC_Diagnostic(_code, _span, _args = undefined, _messageId = _code) constructor {
	static __noArgs = []; // shared by every diagnostic without arguments; args are never changed
	var _entry = __GmlcMessagesData()[$ _code];
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
/// @param   {String}           _messageId : The code and a label key of the catalogue ("GMLC1002.unclosed-delimiter")
/// @param   {Array<String>}    _args      : The values the label's template takes
/// @returns {Struct.GMLC_Label}
#endregion
function GMLC_Label(_span, _messageId, _args) constructor {
	span = _span;
	message_id = _messageId;
	args = _args;
}

#region jsDoc
/// @func    GMLC_DiagnosticMessage(_diagnostic)
/// @desc    The text of a diagnostic: the template of its message id with `{0}`, `{1}`, ... replaced by its arguments.
/// @param   {Struct.GMLC_Diagnostic} _diagnostic : The diagnostic
/// @returns {String}
#endregion
function GMLC_DiagnosticMessage(_diagnostic) {
	// a label has no code of its own: its message id starts with its diagnostic's
	var _code = string_copy(_diagnostic.message_id, 1, 8);
	var _entry = __GmlcMessagesData()[$ _code];
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
			_out += _diagnostic.args[real(_index)];
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
/// @func    GMLC_SortDiagnostics(_diagnostics)
/// @desc    The diagnostics in report order, by file, start, end, code, message id and arguments, without exact
///          duplicates, so the result does not depend on the order the stages ran in.
/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : The diagnostics
/// @returns {Array<Struct.GMLC_Diagnostic>} A sorted copy
#endregion
function GMLC_SortDiagnostics(_diagnostics) {
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
/// @func    GMLC_DiagnosticsToText(_diagnostics, _sources)
/// @desc    The diagnostics as text for people: severity, code and message, then where (file:line:column), the line
///          and a mark under the problem, and the Feather code when there is one.
/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : The diagnostics
/// @param   {Struct.GMLC_SourceTable}       _sources     : The compile's files
/// @returns {String}
#endregion
function GMLC_DiagnosticsToText(_diagnostics, _sources) {
	var _list = GMLC_SortDiagnostics(_diagnostics);
	_sources ??= new GMLC_SourceTable(); // without files every place is unknown
	var _out = "";
	var _i = 0; repeat (array_length(_list)) {
		var _d = _list[_i];
		var _at = _sources.position(_d.span);
		var _gutter = string_repeat(" ", string_length(string(_at.line)));
		_out += $"{_d.severity}[{_d.code}]: {GMLC_DiagnosticMessage(_d)}\n";
		_out += $"{_gutter}--> {_at.fileName}:{_at.line}:{_at.column}\n";
		if (_at.line > 0) {
			// the mark covers the span on its first line, at least one character
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
			_out += $"{_gutter} = {_labelAt.fileName}:{_labelAt.line}:{_labelAt.column}: {GMLC_DiagnosticMessage(_label)}\n";
		_l++}
		if (_d.feather_code != undefined) _out += $"{_gutter} = note: Feather {_d.feather_code}\n";
	_i++}
	return _out;
}

#region jsDoc
/// @func    GMLC_DiagnosticsToJson(_diagnostics, _sources, [_pretty])
/// @desc    The diagnostics as the `diagnostics` stage dump: the dump envelope whose root is the sorted records,
///          each without its rendered text.
/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : The diagnostics
/// @param   {Struct.GMLC_SourceTable}       _sources     : The compile's files
/// @param   {Bool}                          [_pretty]    : Indent the output for reading
/// @returns {String}
#endregion
function GMLC_DiagnosticsToJson(_diagnostics, _sources, _pretty = false) {
	return GMLC_AstToJson(GMLC_SortDiagnostics(_diagnostics), _sources, "diagnostics", _pretty);
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
/// @desc    Stops a compile on its first error: throws the error struct GMLC always threw (message "CODE: text",
///          script, line, column, lineString) with every diagnostic so far under `diagnostics`.
/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : The diagnostics, at least one an error
/// @param   {Struct.GMLC_SourceTable}       _sources     : The compile's files, for the position
#endregion
function __gmlc_throw_diagnostics(_diagnostics, _sources) {
	var _list = GMLC_SortDiagnostics(_diagnostics);
	var _first = undefined;
	var _i = 0; repeat (array_length(_list)) {
		if (_list[_i].severity == "error") {
			_first = _list[_i];
			break;
		}
	_i++}
	_first ??= _list[0];
	var _at = (_sources ?? new GMLC_SourceTable()).position(_first.span);
	throw {
		message: _first.code + ": " + GMLC_DiagnosticMessage(_first),
		script: _at.fileName,
		line: _at.line,
		column: _at.column,
		lineString: _at.lineString,
		stacktrace: debug_get_callstack(),
		diagnostics: _list,
	};
}
#endregion
