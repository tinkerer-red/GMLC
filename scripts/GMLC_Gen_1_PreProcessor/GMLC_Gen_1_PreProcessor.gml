#region jsDoc
/// @func    GMLC_Gen_1_PreProcessor(_env)
/// @desc    Collects each file of a batch, merges the batch's definitions once, then expands each file.
/// @param   {Struct.GMLC_Env} _env : The environment
/// @returns {Struct.GMLC_Gen_1_PreProcessor}
#endregion
function GMLC_Gen_1_PreProcessor(_env) constructor {
	#region Config
	static maxMacroDepth = 64;
	static maxExpandedTokens = 8000000;
	#endregion

	#region Init
	env = _env;
	diagnostics = [];
	sources = undefined;
	#endregion

	#region Public
	#region jsDoc
	/// @func    collect(_program)
	/// @desc    Reads one file's macros, enums, regions, pragmas and comment positions; the other tokens stay in
	///          `stream`. Problems go to `diagnostics`.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct} _program : The lexer's program record (`tokens`)
	/// @returns {Struct} The file's definitions: {program, stream, macros, enums, regions, pragmas, comments}
	#endregion
	static collect = function(_program) {
		diagnostics = [];
		var _unit = { program: _program, stream: [], macros: [], enums: [], regions: [], pragmas: [], comments: [] };
		var _tokens = _program.tokens;
		var _n = array_length(_tokens);
		var _last = -1;
		var _i = 0;
		while (_i < _n) {
			var _t = _tokens[_i];
			switch (_t.kind) {
				case __GMLC_TokenKind_MacroDirective:
					_i = __collectMacro(_tokens, _i, _unit);
					continue;
				case __GMLC_TokenKind_Newline:
					break;
				case __GMLC_TokenKind_Comment:
					array_push(_unit.comments, __span(_t));
					if (__isNoOpPragma(_t.name)) {
						// the parser fills in its target statement
						array_push(_unit.pragmas, new GMLC_Pragma("NoOp", __span(_t), undefined));
					}
					break;
				case __GMLC_TokenKind_Region:
					//apparently endregion can also have a closer title. who knew!
					var _title = string_trim(string_delete(_t.name, 1, string_length(_t.value) + 1));
					array_push(_unit.regions, new GMLC_Region(__span(_t), (_t.value == "endregion"), _title));
					break;
				case __GMLC_TokenKind_Backslash:
					__report("GMLC0308", _t);
					break;
				case __GMLC_TokenKind_Identifier: {
					// `gml_pragma("@NoOp");` as a statement is the pragma too; GameMaker itself refuses it
					var _end = (_t.name == "gml_pragma") ? __noOpPragmaCall(_tokens, _i, _last) : -1;
					if (_end >= 0) {
						array_push(_unit.pragmas, new GMLC_Pragma("NoOp", new GMLC_Span(_t.file, _t.start, _tokens[_end - 1][$ "end"]), undefined));
						_i = _end;
						continue;
					}
					array_push(_unit.stream, _t);
					_last = _i;
				break;}
				case __GMLC_TokenKind_Keyword:
					if (_t.value == "enum") && __startsEnum(_tokens, _i) {
						_i = __collectEnum(_tokens, _i, _unit);
						continue;
					}
					array_push(_unit.stream, _t);
					_last = _i;
					break;
				default:
					array_push(_unit.stream, _t);
					_last = _i;
					break;
			}
			_i++;
		}
		return _unit;
	};

	#region jsDoc
	/// @func    hostMacro(_name, _program)
	/// @desc    A macro the host exposes, in configuration Default; its value may span lines.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {String} _name    : The macro's name
	/// @param   {Struct} _program : The lexer's program record of the value
	/// @returns {Struct.ASTMacroDecl}
	#endregion
	static hostMacro = function(_name, _program) {
		var _body = [];
		var _tokens = _program.tokens;
		var _i = 0; repeat (array_length(_tokens)) {
			var _k = _tokens[_i].kind;
			if (_k != __GMLC_TokenKind_Newline) && (_k != __GMLC_TokenKind_Comment) && (_k != __GMLC_TokenKind_Backslash) {
				array_push(_body, _tokens[_i]);
			}
		_i++}
		var _at = new __GMLC_create_token(__GMLC_TokenType_Identifier, _name, _name, _program.file.file_id, 0, 0, __GMLC_TokenKind_Identifier);
		var _end = (array_length(_tokens) > 0) ? _tokens[array_length(_tokens) - 1][$ "end"] : 0;
		var _macro = new ASTMacroDecl(new GMLC_Span(_at.file, 0, _end), _name, undefined, _program.file.textBetween(0, _end));
		// working fields of the preprocessor; a dump writes only the node's own fields
		_macro.tokens = _body;
		_macro.token = _at;
		_macro.params = [];
		_macro.extension = undefined;
		return _macro;
	};

	#region jsDoc
	/// @func    merge(_units, _configChain)
	/// @desc    Builds the batch's macros and enums. For each macro name the definition whose configuration comes
	///          first in the chain is active. Throws on duplicates and macro cycles.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _units       : Results of collect, in batch order
	/// @param   {Array<String>} _configChain : The active configuration and its ancestors, ending with "Default"
	/// @returns {Struct} The batch's definitions
	#endregion
	static merge = function(_units, _configChain) {
		diagnostics = [];
		var _batch = { keys: {}, active: {}, names: [], cyclic: {}, enums: {}, enum_names: [] };

		var _u = 0; repeat (array_length(_units)) {
			var _macros = _units[_u].macros;
			var _m = 0; repeat (array_length(_macros)) {
				var _def = _macros[_m];
				var _key = (_def.config ?? "Default") + ":" + _def.name;
				if (struct_exists(_batch.keys, _key)) {
					// GameMaker checks only the configuration it builds
					if (array_contains(_configChain, _def.config ?? "Default")) __report("GMLC0303", _def.token, [_def.name]);
				}
				else {
					_batch.keys[$ _key] = _def;
				}
			_m++}
			var _enums = _units[_u].enums;
			var _e = 0; repeat (array_length(_enums)) {
				var _enum = _enums[_e];
				if (__gmlc_struct_has(_batch.enums, _enum.name)) {
					__report("GMLC0311", _enum.token, [_enum.name]);
				}
				else {
					_batch.enums[$ _enum.name] = _enum;
					array_push(_batch.enum_names, _enum.name);
				}
			_e++}
		_u++}

		var _u = 0; repeat (array_length(_units)) {
			var _macros = _units[_u].macros;
			var _m = 0; repeat (array_length(_macros)) {
				var _name = _macros[_m].name;
				if (!__gmlc_struct_has(_batch.active, _name)) {
					var _c = 0; repeat (array_length(_configChain)) {
						var _def = _batch.keys[$ _configChain[_c] + ":" + _name];
						if (_def != undefined) {
							_batch.active[$ _name] = _def;
							array_push(_batch.names, _name);
							break;
						}
					_c++}
				}
			_m++}
		_u++}

		__findCycles(_batch);
		if (__gmlc_has_errors(diagnostics)) __gmlc_throw_diagnostics(diagnostics, sources);
		return _batch;
	};

	#region jsDoc
	/// @func    expand(_unit, _batch)
	/// @desc    Replaces every macro use with copies of its body; `nameof(...)` becomes a string when the environment
	///          exposes `nameof`. Enum references stay as written for lowering. Problems go to `diagnostics`.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct} _unit  : A result of collect
	/// @param   {Struct} _batch : The result of merge
	/// @returns {Struct} The program record, ready for the parser
	#endregion
	static expand = function(_unit, _batch) {
		diagnostics = [];
		var _withMacros = [];
		var _stream = _unit.stream;
		var _nameof = env.isFunction("nameof");
		var _n = array_length(_stream);
		var _run = 0;
		var _i = 0;
		while (_i < _n) && (array_length(_withMacros) <= maxExpandedTokens) {
			var _t = _stream[_i];
			if (_t.kind != __GMLC_TokenKind_Identifier) {
				_i++;
				continue;
			}
			// a macro named nameof replaces the operator, as in GameMaker
			var _isNameof = (_nameof) && (_t.value == "nameof") && !__gmlc_struct_has(_batch.active, "nameof") && (_i + 1 < _n) && (_stream[_i + 1].kind == __GMLC_TokenKind_Op) && (_stream[_i + 1].value == "(");
			if (!_isNameof) && !__isExpandable(_batch, _t.value) {
				_i++;
				continue;
			}
			array_copy(_withMacros, array_length(_withMacros), _stream, _run, _i - _run);
			if (_isNameof) {
				_i = __nameof(_stream, _i, _withMacros);
			}
			else {
				var _def = _batch.active[$ _t.value];
				if (_def.extension != undefined) {
					_i = _def.extension.expandMacro(self, _batch, _stream, _i, _def, 1, _withMacros, _t);
				}
				else {
					__emitTokens(_batch, _t, _def, _def.tokens, 1, _withMacros);
					_i++;
				}
			}
			_run = _i;
		}
		if (array_length(_withMacros) <= maxExpandedTokens) array_copy(_withMacros, array_length(_withMacros), _stream, _run, _n - _run);
		if (array_length(_withMacros) > maxExpandedTokens) {
			array_resize(_withMacros, maxExpandedTokens + 1);
			__report("GMLC0306", _withMacros[maxExpandedTokens]);
		}

		var _program = _unit.program;
		__checkEnumRefs(_batch, _withMacros);
		_program.tokens = _withMacros;

		var _e = 0; repeat (array_length(_unit.enums)) {
			var _enum = _unit.enums[_e];
			var _m = 0; repeat (array_length(_enum.members)) {
				var _member = _enum.members[_m];
				_member.expanded = __expandValue(_batch, _member);
			_m++}
		_e++}
		_program.macros = _unit.macros;
		_program.enums = _unit.enums;
		_program.regions = _unit.regions;
		_program.pragmas = _unit.pragmas;
		_program.comments = _unit.comments;
		return _program;
	};
	#endregion

	#region Private
	#region Collect
	#region jsDoc
	/// @func    __collectMacro(_tokens, _i, _unit)
	/// @desc    Reads `#macro [Config:]NAME body`; the body runs to the first line break not continued by a backslash.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _tokens : The file's lexer tokens
	/// @param   {Real}          _i      : Index of the #macro directive
	/// @param   {Struct}        _unit   : The unit being collected
	/// @returns {Real} Index of the first token after the definition
	#endregion
	static __collectMacro = function(_tokens, _i, _unit) {
		var _directive = _tokens[_i];
		var _n = array_length(_tokens);
		_i++;
		if (_i >= _n) || (_tokens[_i].kind == __GMLC_TokenKind_Newline) {
			__report("GMLC0301", _directive);
			return _i;
		}
		var _nameToken = _tokens[_i]; // Assuming next token is the macro name
		var _config = undefined;
		// `Config:NAME`, written without spaces
		if (_i + 2 < _n) && (_tokens[_i + 1].kind == __GMLC_TokenKind_Op) && (_tokens[_i + 1].value == ":") && (_tokens[_i + 1].start == _nameToken.end)
		&& (_tokens[_i + 2].start == _tokens[_i + 1].end) && __isWord(_tokens[_i + 2]) {
			_config = _nameToken.name;
			_nameToken = _tokens[_i + 2];
			_i += 2;
		}
		if (!__isWord(_nameToken)) {
			__report("GMLC0302", _nameToken, [_nameToken.name]);
		}
		_i++;

		var _params = [];
		var _owner = undefined;
		var _extensions = env.extensions;
		var _x = 0; repeat (array_length(_extensions)) {
			var _extension = _extensions[_x];
			if (_extension.collectMacro != undefined) {
				var _taken = _extension.collectMacro(self, _tokens, _i, _nameToken);
				if (_taken != undefined) {
					_params = _taken.params;
					_owner = _extension;
					_i = _taken.next;
					break;
				}
			}
		_x++}

		var _body = [];
		var _textStart = (_i < _n) && (_tokens[_i].kind != __GMLC_TokenKind_Newline) ? _tokens[_i].start : _nameToken[$ "end"];
		var _textEnd = _nameToken[$ "end"];
		while (_i < _n) {
			var _t = _tokens[_i];
			// Check for line break not preceded by a backslash escape
			if (_t.kind == __GMLC_TokenKind_Newline) break;  // End of macro body
			_textEnd = _t[$ "end"];
			if (_t.kind == __GMLC_TokenKind_Comment) {
				if (string_pos("\n", _t.name) > 0) {
					__report("GMLC0309", _t);
				}
			}
			else if (_t.kind == __GMLC_TokenKind_Backslash) {
				// only comments and more backslashes may follow, as in GameMaker (`;\\` continues)
				_i++;
				while (_i < _n) && (_tokens[_i].kind != __GMLC_TokenKind_Newline) {
					if (_tokens[_i].kind != __GMLC_TokenKind_Comment) && (_tokens[_i].kind != __GMLC_TokenKind_Backslash) {
						__report("GMLC0307", _tokens[_i]);
					}
					_textEnd = _tokens[_i][$ "end"];
					_i++;
				}
			}
			else {
				array_push(_body, _t);
			}
			_i++;
		}
		var _last = array_length(_body) - 1;
		if (_last >= 0) && (_body[_last].kind == __GMLC_TokenKind_Op) && (_body[_last].value == ";") {
			__report("GMLC0304", _body[_last], [_nameToken.name]);
		}
		var _macro = new ASTMacroDecl(new GMLC_Span(_directive.file, _directive.start, _textEnd), _nameToken.name, _config, _unit.program.file.textBetween(_textStart, _textEnd));
		_macro.tokens = _body;
		_macro.token = _nameToken;
		_macro.params = _params;
		_macro.extension = _owner;
		array_push(_unit.macros, _macro);
		return _i;
	};

	#region jsDoc
	/// @func    __startsEnum(_tokens, _i)
	/// @desc    Whether the `enum` keyword at _i is followed by a name and `{`.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _tokens : The file's lexer tokens
	/// @param   {Real}          _i      : Index of the `enum` keyword
	/// @returns {Bool}
	#endregion
	static __startsEnum = function(_tokens, _i) {
		var _j = __nextSignificant(_tokens, _i + 1);
		if (_j < 0) || (_tokens[_j].kind != __GMLC_TokenKind_Identifier) return false;
		var _k = __nextSignificant(_tokens, _j + 1);
		return (_k >= 0) && (_tokens[_k].kind == __GMLC_TokenKind_Op) && (_tokens[_k].value == "{");
	};

	#region jsDoc
	/// @func    __collectEnum(_tokens, _i, _unit)
	/// @desc    Reads `enum Name { member [= value], ... }` and the semicolons after it.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _tokens : The file's lexer tokens
	/// @param   {Real}          _i      : Index of the `enum` keyword
	/// @param   {Struct}        _unit   : The unit being collected
	/// @returns {Real} Index of the first token after the declaration
	#endregion
	static __collectEnum = function(_tokens, _i, _unit) {
		var _n = array_length(_tokens);
		var _j = __nextSignificant(_tokens, _i + 1);
		var _nameToken = _tokens[_j];
		var _enum = new ASTEnumDecl(undefined, _nameToken.name, []);
		_enum.token = _nameToken;
		_enum.member_index = {};
		var _enumStart = _tokens[_i].start;
		_i = __nextSignificant(_tokens, _j + 1) + 1;

		while (true) {
			_i = __nextSignificant(_tokens, _i);
			if (_i < 0) {
				__report("GMLC0310", _nameToken, [_enum.name], "GMLC0310.no-closing-brace");
				return _n;
			}
			var _t = _tokens[_i];
			if (_t.kind == __GMLC_TokenKind_Op) && (_t.value == "}") break;

			//apparently it can be any stream of text! how fun! so keywords, unique identifiers, doesnt matter! ffs...
			var _member = _t;
			var _good = __isWord(_member);
			if (!_good) __report("GMLC0310", _member, [_member.name]);
			_i++;

			// Check for = to see if a value is assigned
			var _init = undefined;
			var _k = __nextSignificant(_tokens, _i);
			if (_good) && (_k >= 0) && (_tokens[_k].kind == __GMLC_TokenKind_Op) && (_tokens[_k].value == "=") {
				_init = [];
				_i = _k + 1;
			}
			var _depth = 0;
			var _memberEnd = _member[$ "end"];
			while (_i < _n) {
				var _v = _tokens[_i];
				if (_v.kind == __GMLC_TokenKind_Newline) || (_v.kind == __GMLC_TokenKind_Comment) { _i++; continue; }
				var _op = (_v.kind == __GMLC_TokenKind_Op) ? _v.value : ""; // a string's text is not a bracket
				if (_depth == 0) && ((_op == ",") || (_op == "}")) break;
				if (_op == "(") || (_op == "{") || (string_char_at(_op, 1) == "[") _depth++;
				if (_op == ")") || (_op == "]") || (_op == "}") _depth--;
				if (_init != undefined) {
					array_push(_init, _v);
					_memberEnd = _v[$ "end"];
				}
				else if (_good) {
					__report("GMLC0310", _v, [_v.name]);
					_good = false;
				}
				_i++;
			}
			if (_good) {
				if (__gmlc_struct_has(_enum.member_index, _member.name)) {
					__report("GMLC0312", _member, [_enum.name, _member.name]);
				}
				else {
					// Add member to the list
					_enum.member_index[$ _member.name] = array_length(_enum.members);
					var _node = new ASTEnumMember(new GMLC_Span(_member.file, _member.start, _memberEnd), _member.name, undefined, (_init != undefined));
					_node.value_tokens = _init;
					_node.expanded = undefined; // value_tokens with their macros expanded, set by expand
					array_push(_enum.members, _node);
				}
			}
			// Handle commas between enum members
			if (_i < _n) && (_tokens[_i].kind == __GMLC_TokenKind_Op) && (_tokens[_i].value == ",") _i++;
		}
		_enum.span = new GMLC_Span(_nameToken.file, _enumStart, _tokens[_i][$ "end"]);
		_i++;

		//frequently people will accidently include multiple ; at the end of their line, just ignore this.
		while (true) {
			var _k = __nextSignificant(_tokens, _i);
			if (_k < 0) || (_tokens[_k].kind != __GMLC_TokenKind_Op) || (_tokens[_k].value != ";") break;
			_i = _k + 1;
		}
		array_push(_unit.enums, _enum);
		return _i;
	};

	#region jsDoc
	/// @func    __isNoOpPragma(_text)
	/// @desc    Whether a comment is the pragma `// @NoOp`: `//` or `///`, one space, an optional `@`, then `NoOp` or
	///          `noop` and a non-word character or the end; or exactly `/* NoOp */` with the same word forms.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {String} _text : The comment's source text
	/// @returns {Bool}
	#endregion
	static __isNoOpPragma = function(_text) {
		var _open = string_copy(_text, 1, 2);
		if (_open == "/*") {
			return (_text == "/* @NoOp */") || (_text == "/* NoOp */") || (_text == "/* @noop */") || (_text == "/* noop */");
		}
		if (_open != "//") return false;
		var _p = 3;
		if (string_char_at(_text, _p) == "/") _p++;
		if (string_char_at(_text, _p) != " ") return false;
		_p++;
		if (string_char_at(_text, _p) == "@") _p++;
		var _word = string_copy(_text, _p, 4);
		if (_word != "NoOp") && (_word != "noop") return false;
		return (_p + 4 > string_length(_text)) || !__char_is_alphanumeric(ord(string_char_at(_text, _p + 4)));
	};

	#region jsDoc
	/// @func    __noOpPragmaCall(_tokens, _i, _last)
	/// @desc    The index after the statement `gml_pragma("@NoOp");` at _i (the string `@NoOp`, `NoOp`, `@noop` or
	///          `noop`), else -1.
	///          After a line break it is a statement unless it follows `)`, `else` or `do`, whose body it would be.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _tokens : The file's tokens
	/// @param   {Real}          _i      : The index of `gml_pragma`
	/// @param   {Real}          _last   : The index of the last token kept in the stream, -1 for none
	/// @returns {Real}
	#endregion
	static __noOpPragmaCall = function(_tokens, _i, _last) {
		if (_last >= 0) {
			var _prev = _tokens[_last];
			var _v = ((_prev.kind == __GMLC_TokenKind_Op) || (_prev.kind == __GMLC_TokenKind_Keyword)) ? _prev.value : "";
			var _closes = (_v == ";") || (_v == "{") || (_v == "}");
			if (!_closes) {
				var _broken = false;
				var _j = _last + 1; repeat (_i - _last - 1) {
					if (_tokens[_j].kind == __GMLC_TokenKind_Newline) _broken = true;
				_j++}
				if (!_broken) || (_v == ")") || (_v == "else") || (_v == "do") return -1;
			}
		}
		var _open = __nextSignificant(_tokens, _i + 1);
		if (_open < 0) || (_tokens[_open].kind != __GMLC_TokenKind_Op) || (_tokens[_open].value != "(") return -1;
		var _text = __nextSignificant(_tokens, _open + 1);
		if (_text < 0) || (_tokens[_text].kind != __GMLC_TokenKind_String) return -1;
		var _value = _tokens[_text].value;
		if (_value != "@NoOp") && (_value != "NoOp") && (_value != "@noop") && (_value != "noop") return -1;
		var _close = __nextSignificant(_tokens, _text + 1);
		if (_close < 0) || (_tokens[_close].kind != __GMLC_TokenKind_Op) || (_tokens[_close].value != ")") return -1;
		var _after = __nextSignificant(_tokens, _close + 1);
		if (_after >= 0) && (_tokens[_after].kind == __GMLC_TokenKind_Op) && (_tokens[_after].value == ";") return _after + 1;
		return _close + 1;
	};
	#endregion

	#region Merge
	#region jsDoc
	/// @func    __findCycles(_batch)
	/// @desc    Reports each macro cycle once, in name order, and marks its macros cyclic.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct} _batch : The batch being merged
	#endregion
	static __findCycles = function(_batch) {
		var _names = variable_clone(_batch.names);
		array_sort(_names, true);
		var _state = {}; // 1 on the current path, 2 done
		var _path = [];
		var _i = 0; repeat (array_length(_names)) {
			if ((__gmlc_struct_get(_state, _names[_i]) ?? 0) == 0) __visitMacro(_batch, _names[_i], _state, _path);
		_i++}
	};

	#region jsDoc
	/// @func    __visitMacro(_batch, _name, _state, _path)
	/// @desc    Walks the macros a macro's value uses, depth first; reaching a macro on the current path reports
	///          the cycle and marks its macros cyclic.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct}        _batch : The batch being merged
	/// @param   {String}        _name  : The macro
	/// @param   {Struct}        _state : Name to 1 (on the current path) or 2 (done)
	/// @param   {Array<String>} _path  : The macros on the current path
	#endregion
	static __visitMacro = function(_batch, _name, _state, _path) {
		_state[$ _name] = 1;
		array_push(_path, _name);
		var _def = _batch.active[$ _name];
		var _body = _def.tokens;
		var _b = 0; repeat (array_length(_body)) {
			var _t = _body[_b];
			if (_t.kind == __GMLC_TokenKind_Identifier) && __gmlc_struct_has(_batch.active, _t.value) && !array_contains(_def.params, _t.value) {
				var _s = __gmlc_struct_get(_state, _t.value) ?? 0;
				if (_s == 1) {
					var _from = array_get_index(_path, _t.value);
					var _cycle = [];
					array_copy(_cycle, 0, _path, _from, array_length(_path) - _from);
					var _c = 0; repeat (array_length(_cycle)) { _batch.cyclic[$ _cycle[_c]] = true; _c++ }
					array_push(_cycle, _t.value);
					__report("GMLC0305", _batch.active[$ _cycle[0]].token, [string_join_ext(" -> ", _cycle)]);
				}
				else if (_s == 0) {
					__visitMacro(_batch, _t.value, _state, _path);
				}
			}
		_b++}
		array_pop(_path);
		_state[$ _name] = 2;
	};
	#endregion

	#region Expand
	#region jsDoc
	/// @func    __isExpandable(_batch, _name)
	/// @desc    Whether a name is an active macro that is not on a cycle.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct} _batch : The merged batch
	/// @param   {String} _name  : The identifier
	/// @returns {Bool}
	#endregion
	static __isExpandable = function(_batch, _name) {
		return __gmlc_struct_has(_batch.active, _name) && !__gmlc_struct_has(_batch.cyclic, _name);
	};

	#region jsDoc
	/// @func    __emitTokens(_batch, _use, _def, _tokens, _depth, _out)
	/// @desc    Appends copies of a macro use's tokens with the macro's origin, expanding nested uses up to
	///          maxMacroDepth. Language extensions call it with the tokens they made.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct}        _batch  : The merged batch
	/// @param   {Struct}        _use    : The token of the outermost use
	/// @param   {Struct}        _def    : The macro definition
	/// @param   {Array<Struct>} _tokens : The tokens to write
	/// @param   {Real}          _depth  : Nesting depth, 1 for a use in the file
	/// @param   {Array<Struct>} _out    : Tokens written so far
	#endregion
	static __emitTokens = function(_batch, _use, _def, _tokens, _depth, _out) {
		if (_depth > maxMacroDepth) {
			__report("GMLC0306", _use, [_def.name], "GMLC0306.depth");
			return;
		}
		var _origin = new GMLC_Origin("macro", _def.name, undefined, _def.config, _def.span, __span(_use));
		var _n = array_length(_tokens);
		var _b = 0;
		while (_b < _n) {
			var _t = _tokens[_b];
			if (_t.kind == __GMLC_TokenKind_Identifier) && __isExpandable(_batch, _t.value) {
				var _inner = _batch.active[$ _t.value];
				if (_inner.extension != undefined) {
					_b = _inner.extension.expandMacro(self, _batch, _tokens, _b, _inner, _depth + 1, _out, _use);
					continue;
				}
				__emitTokens(_batch, _use, _inner, _inner.tokens, _depth + 1, _out);
			}
			else {
				// a copy: tokens are never modified once made
				var _copy = new __GMLC_create_token(_t.type, _t.name, _t.value, _t.file, _t.start, _t[$ "end"], _t.kind, _t.ty);
				_copy.origin = _origin;
				array_push(_out, _copy);
			}
			_b++;
		}
	};

	#region jsDoc
	/// @func    __checkEnumRefs(_batch, _tokens)
	/// @desc    Reports every `Enum.Member` whose enum has no such member. The references stay as written for lowering.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct}        _batch  : The merged batch
	/// @param   {Array<Struct>} _tokens : Tokens after macro expansion
	#endregion
	static __checkEnumRefs = function(_batch, _tokens) {
		if (array_length(_batch.enum_names) == 0) return;
		var _n = array_length(_tokens);
		var _i = 0; repeat (_n) {
			var _t = _tokens[_i];
			if (_t.kind == __GMLC_TokenKind_Identifier) && __gmlc_struct_has(_batch.enums, _t.value)
			&& (_i + 2 < _n) && (_tokens[_i + 1].kind == __GMLC_TokenKind_Op) && (_tokens[_i + 1].value == ".") && __isWord(_tokens[_i + 2])
			&& ((_i == 0) || (_tokens[_i - 1].kind != __GMLC_TokenKind_Op) || (_tokens[_i - 1].value != ".")) {
				if (!__gmlc_struct_has(_batch.enums[$ _t.value].member_index, _tokens[_i + 2].name)) {
					__report("GMLC0314", _tokens[_i + 2], [_t.value, _tokens[_i + 2].name]);
				}
			}
		_i++}
	};

	#region jsDoc
	/// @func    __expandValue(_batch, _member)
	/// @desc    An enum member's value with its macros expanded.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct} _batch  : The merged batch
	/// @param   {Struct} _member : The member
	/// @returns {Array<Struct>|Undefined} undefined for a member without a value
	#endregion
	static __expandValue = function(_batch, _member) {
		if (_member.value_tokens == undefined) return undefined;
		var _expanded = [];
		var _b = 0; repeat (array_length(_member.value_tokens)) {
			var _t = _member.value_tokens[_b];
			if (_t.kind == __GMLC_TokenKind_Identifier) && __isExpandable(_batch, _t.value) {
				var _def = _batch.active[$ _t.value];
				__emitTokens(_batch, _t, _def, _def.tokens, 1, _expanded);
			}
			else {
				array_push(_expanded, _t);
			}
		_b++}
		__checkEnumRefs(_batch, _expanded);
		return _expanded;
	};

	#region jsDoc
	/// @func    __nameof(_stream, _i, _out)
	/// @desc    `nameof(E.m)` becomes the string "E.m"; nothing inside is expanded.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _stream : The unit's stream
	/// @param   {Real}          _i      : Index of `nameof`
	/// @param   {Array<Struct>} _out    : Tokens written so far
	/// @returns {Real} Index after the closing parenthesis
	#endregion
	static __nameof = function(_stream, _i, _out) {
		var _n = array_length(_stream);
		var _depth = 0;
		var _text = "";
		var _j = _i + 2;
		while (_j < _n) {
			var _t = _stream[_j];
			var _op = (_t.kind == __GMLC_TokenKind_Op) ? _t.value : "";
			if (_op == "(") _depth++;
			if (_op == ")") {
				if (_depth == 0) break;
				_depth--;
			}
			_text += _t.name;
			_j++;
		}
		if (_j >= _n) {
			// no closing parenthesis: leave it to the parser
			array_push(_out, _stream[_i]);
			return _i + 1;
		}
		var _at = _stream[_i];
		array_push(_out, new __GMLC_create_token(__GMLC_TokenType_String, "nameof(" + _text + ")", _text, _at.file, _at.start, _stream[_j][$ "end"], __GMLC_TokenKind_String, "string"));
		return _j + 1;
	};
	#endregion

	#region Tokens and diagnostics
	#region jsDoc
	/// @func    __span(_t)
	/// @desc    The span of a token.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct} _t : The token
	/// @returns {Struct.GMLC_Span}
	#endregion
	static __span = function(_t) {
		return new GMLC_Span(_t.file, _t.start, _t[$ "end"]);
	};

	#region jsDoc
	/// @func    __nextSignificant(_tokens, _i)
	/// @desc    The index of the first token at or after _i that is not a line break or a comment, -1 for none.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _tokens : The tokens
	/// @param   {Real}          _i      : The index to start at
	/// @returns {Real}
	#endregion
	static __nextSignificant = function(_tokens, _i) {
		var _n = array_length(_tokens);
		while (_i < _n) {
			var _k = _tokens[_i].kind;
			if (_k != __GMLC_TokenKind_Newline) && (_k != __GMLC_TokenKind_Comment) return _i;
			_i++;
		}
		return -1;
	};

	#region jsDoc
	/// @func    __isWord(_t)
	/// @desc    Whether a token is a word: an identifier, a keyword or an alias operator such as `and`.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct} _t : The token
	/// @returns {Bool}
	#endregion
	static __isWord = function(_t) {
		switch (_t.kind) {
			case __GMLC_TokenKind_Identifier:
			case __GMLC_TokenKind_Keyword:
				return true;
			case __GMLC_TokenKind_Op:
				// `and`, `div`, ... arrive as operators
				return __char_is_alphabetic(string_byte_at(_t.name, 1));
		}
		return false;
	};

	#region jsDoc
	/// @func    __report(_code, _at, [_args], [_messageId])
	/// @desc    Records a diagnostic at a token.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {String}        _code        : The code
	/// @param   {Struct}        _at          : The token
	/// @param   {Array<String>} [_args]      : The values the message's template takes
	/// @param   {String}        [_messageId] : The code, or the code and a variant key
	#endregion
	static __report = function(_code, _at, _args = undefined, _messageId = _code) {
		array_push(diagnostics, new GMLC_Diagnostic(_code, new GMLC_Span(_at.file, _at.start, _at[$ "end"]), _args, _messageId));
	};
	#endregion
	#endregion
}
