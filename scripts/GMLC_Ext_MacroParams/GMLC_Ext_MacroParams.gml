#region Extension: macro-params
// `#macro NAME(A, B) body`: a name directly followed by `(` takes parameters. A use `NAME(x, y)` becomes the body
// with each parameter name (not after a `.`) replaced by its argument's tokens, then expands as usual; a use without
// `(` stays a name. Without the extension, GameMaker's meaning holds: a body starting with `(A, B)`.

#region jsDoc
/// @func    GMLC_Ext_MacroParams()
/// @desc    The `macro-params` extension.
/// @returns {Struct.GMLC_Ext_MacroParams}
#endregion
function GMLC_Ext_MacroParams() : GMLC_Extension("macro-params") constructor {
	#region jsDoc
	/// @func    collectMacro(_pre, _tokens, _i, _nameToken)
	/// @desc    Reads the parameter list right after a macro's name. Returns undefined when the name is not directly
	///          followed by `(`, so the definition stays an ordinary macro.
	/// @self    GMLC_Ext_MacroParams
	/// @param   {Struct.GMLC_Gen_1_PreProcessor} _pre       : The preprocessor
	/// @param   {Array<Struct>}                  _tokens    : The file's lexer tokens
	/// @param   {Real}                           _i         : Index of the token after the name
	/// @param   {Struct}                         _nameToken : The name
	/// @returns {Struct|Undefined} {params, next}: the parameter names and the index of the body's first token
	#endregion
	static collectMacro = function(_pre, _tokens, _i, _nameToken) {
		var _n = array_length(_tokens);
		if (_i >= _n) || (_tokens[_i].value != "(") || (_tokens[_i].start != _nameToken[$ "end"]) return undefined;
		var _params = [];
		var _j = _i + 1;
		var _ok = true;
		if (_j < _n) && (_tokens[_j].value == ")") {
			_j++;
		}
		else {
			while (true) {
				if (_j >= _n) || (_tokens[_j].kind != __GMLC_TokenKind_Identifier) || array_contains(_params, _tokens[_j].value) {
					_ok = false;
					break;
				}
				array_push(_params, _tokens[_j].value);
				_j++;
				if (_j < _n) && (_tokens[_j].value == ",") {
					_j++;
					continue;
				}
				if (_j < _n) && (_tokens[_j].value == ")") {
					_j++;
					break;
				}
				_ok = false;
				break;
			}
		}
		if (!_ok) {
			_pre.__report("GMLC0319", _nameToken, [_nameToken.name]);
			// the rest of the line is taken as the body, so the file goes on from the next line
			while (_j < _n) && (_tokens[_j].kind != __GMLC_TokenKind_Newline) _j++;
		}
		return { params: _params, next: _j };
	};
	
	#region jsDoc
	/// @func    expandMacro(_pre, _batch, _tokens, _i, _def, _depth, _out, _use)
	/// @desc    Expands a use of a macro with parameters at _tokens[_i]: reads its arguments, puts them into the body
	///          and expands the result. A use without `(` is left as the name.
	/// @self    GMLC_Ext_MacroParams
	/// @param   {Struct.GMLC_Gen_1_PreProcessor} _pre    : The preprocessor
	/// @param   {Struct}                         _batch  : The merged batch
	/// @param   {Array<Struct>}                  _tokens : The tokens being expanded
	/// @param   {Real}                           _i      : Index of the macro's name
	/// @param   {Struct}                         _def    : The definition
	/// @param   {Real}                           _depth  : Nesting depth of the expansion
	/// @param   {Array<Struct>}                  _out    : Tokens written so far
	/// @param   {Struct}                         _use    : The token of the outermost use, for the origin
	/// @returns {Real} Index of the first token after the use
	#endregion
	static expandMacro = function(_pre, _batch, _tokens, _i, _def, _depth, _out, _use) {
		var _n = array_length(_tokens);
		if (_i + 1 >= _n) || (_tokens[_i + 1].kind != __GMLC_TokenKind_Op) || (_tokens[_i + 1].value != "(") {
			array_push(_out, _tokens[_i]);
			return _i + 1;
		}
		
		// the arguments: tokens split at commas outside brackets, up to the `)` that closes the list
		var _args = [];
		var _current = [];
		var _level = 0;
		var _j = _i + 2;
		var _closed = false;
		while (_j < _n) {
			var _t = _tokens[_j];
			var _v = (_t.kind == __GMLC_TokenKind_Op) ? _t.value : ""; // a string's text is not a bracket
			if (_level == 0) && (_v == ")") {
				_closed = true;
				break;
			}
			if (_level == 0) && (_v == ",") {
				array_push(_args, _current);
				_current = [];
				_j++;
				continue;
			}
			if (_v == "(") || (_v == "{") || (string_char_at(_v, 1) == "[") _level++;
			if (_v == ")") || (_v == "}") || (_v == "]") _level--;
			array_push(_current, _t);
			_j++;
		}
		if (!_closed) {
			// no closing `)`: the parser reports it where it reads the name
			array_push(_out, _tokens[_i]);
			return _i + 1;
		}
		if (array_length(_args) > 0) || (array_length(_current) > 0) array_push(_args, _current);
		
		var _params = _def.params;
		if (array_length(_args) != array_length(_params)) {
			_pre.__report("GMLC0318", _tokens[_i], [_def.name, string(array_length(_params)), string(array_length(_args))]);
			return _j + 1;
		}
		
		// the body with each parameter replaced by its argument's tokens
		var _body = _def.body;
		var _filled = [];
		var _b = 0; repeat (array_length(_body)) {
			var _t = _body[_b];
			var _p = (_t.kind == __GMLC_TokenKind_Identifier) && ((_b == 0) || (_body[_b - 1].value != "."))
				? array_get_index(_params, _t.value) : -1;
			if (_p >= 0) {
				array_copy(_filled, array_length(_filled), _args[_p], 0, array_length(_args[_p]));
			}
			else {
				array_push(_filled, _t);
			}
		_b++}
		_pre.__emitTokens(_batch, _use, _def, _filled, _depth, _out);
		return _j + 1;
	};
}
#endregion
