#region PreProcessor.gml
// For a batch of files: `collect` reads each file's #macro and enum definitions, regions and @NoOp pragmas (the comment
// or the statement `gml_pragma("@NoOp")`) and keeps the other significant tokens; one `merge` builds the batch's
// definitions (the configuration chain picks each macro, duplicates and cycles are errors, enum names are
// batch-wide); `expand` then writes each file's tokens with every macro use replaced by fresh tokens and gives each
// enum member's value its macros. Enum references stay as written; lowering gives them their values. It reads no environment, except
// whether `nameof` is exposed and which language extensions are switched on (a macro definition an extension takes,
// such as one with parameters, is expanded by that extension).

function GMLC_Gen_1_PreProcessor(_env) constructor {
	#region Config
	static maxMacroDepth = 64;          // macro uses nested deeper than this are an error
	static maxExpandedTokens = 8000000; // the most tokens one file may grow to by macro expansion
	#endregion

	env = _env;
	diagnostics = [];
	sources = undefined; // the compile's GMLC_SourceTable, for the positions of errors
	
	#region Public
	#region jsDoc
	/// @func    collect(_program)
	/// @desc    Reads one file's lexer tokens: #macro definitions, enum declarations, regions and `@NoOp` pragmas go
	///          to tables, comments and line breaks are dropped, everything else stays in the stream in order.
	///          Problems go to `diagnostics`; the caller stops after every file of the batch is collected.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct} _program : The lexer's program record (`tokens`)
	/// @returns {Struct} The file's definitions: {program, stream, macros, enums, regions, pragmas}
	#endregion
	static collect = function(_program) {
		diagnostics = [];
		var _unit = { program: _program, stream: [], macros: [], enums: [], regions: [], pragmas: [] };
		var _tokens = _program.tokens;
		var _n = array_length(_tokens);
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
					if (__isNoOpPragma(_t.name)) {
						// the parser fills `target` with the span of the first statement after it
						array_push(_unit.pragmas, new GMLC_Pragma("NoOp", __span(_t), undefined));
					}
					break;
				case __GMLC_TokenKind_Region:
					array_push(_unit.regions, new GMLC_Region(__span(_t), (_t.value == "endregion"), __regionTitle(_t.name)));
					break;
				case __GMLC_TokenKind_Backslash:
					__report("GMLC0308", _t);
					break;
				case __GMLC_TokenKind_Identifier: {
					// `gml_pragma("@NoOp");` as a statement is the pragma too (GMLC only; GameMaker refuses it)
					var _end = (_t.name == "gml_pragma") ? __noOpPragmaCall(_tokens, _i, _unit.stream) : -1;
					if (_end >= 0) {
						array_push(_unit.pragmas, new GMLC_Pragma("NoOp", new GMLC_Span(_t[$ "file"], _t.start, _tokens[_end - 1][$ "end"]), undefined));
						_i = _end;
						continue;
					}
					array_push(_unit.stream, _t);
				break;}
				case __GMLC_TokenKind_Keyword:
					if (_t.value == "enum") && __startsEnum(_tokens, _i) {
						_i = __collectEnum(_tokens, _i, _unit);
						continue;
					}
					array_push(_unit.stream, _t);
					break;
				default:
					array_push(_unit.stream, _t);
					break;
			}
			_i++;
		}
		return _unit;
	};
	
	#region jsDoc
	/// @func    hostMacro(_name, _program)
	/// @desc    The definition of a macro the host exposes: its value lexed on its own, comments, line breaks and
	///          backslashes left out (a value may span lines). It has configuration Default.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {String} _name    : The macro's name
	/// @param   {Struct} _program : The lexer's program record of the value
	/// @returns {Struct} The definition, as collect makes them
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
		var _at = new __GMLC_create_token(__GMLC_TokenType_Identifier, _name, _name, _program.file.fileId, 0, 0);
		_at.kind = __GMLC_TokenKind_Identifier;
		var _end = (array_length(_tokens) > 0) ? _tokens[array_length(_tokens) - 1][$ "end"] : 0;
		return {
			name: _name, config: undefined, body: _body, token: _at,
			span: new GMLC_Span(_at.file, 0, _end), text: _program.file.text(0, _end),
		};
	};
	
	#region jsDoc
	/// @func    merge(_units, _configChain)
	/// @desc    Builds the batch's definitions from the units in order (the exposed macros first). Macros are keyed by
	///          configuration and name: a second definition of a key is an error, and for each name the definition
	///          whose configuration comes first in the chain is the active one. A macro cycle is an error. Enum names
	///          are batch-global; their values are given in lowering. Throws the first error.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _units       : Results of collect, in batch order
	/// @param   {Array<String>} _configChain : The active configuration and its ancestors, ending with "Default"
	/// @returns {Struct} The batch's definitions
	#endregion
	static merge = function(_units, _configChain) {
		diagnostics = [];
		var _batch = { keys: {}, active: {}, names: [], cyclic: {}, enums: {}, enumNames: [] };
		
		// definitions by (configuration, name), first one kept
		var _u = 0; repeat (array_length(_units)) {
			var _macros = _units[_u].macros;
			var _m = 0; repeat (array_length(_macros)) {
				var _def = _macros[_m];
				var _key = (_def.config ?? "Default") + ":" + _def.name;
				if (struct_exists(_batch.keys, _key)) {
					// GameMaker checks only the configuration it builds (measured)
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
					array_push(_batch.enumNames, _enum.name);
				}
			_e++}
		_u++}
		
		// the active definition of each name: the first configuration of the chain that defines it
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
		__throwErrors();
		return _batch;
	};
	
	#region jsDoc
	/// @func    expand(_unit, _batch)
	/// @desc    Writes the unit's tokens with every use of an active macro replaced by copies of its body (nested uses
	///          too); `Enum.Member` references stay, checked against the batch's enums. `nameof(...)` becomes the written name
	///          when the environment exposes `nameof`, and nothing inside it is expanded. Sets the program's tokens
	///          and tables and returns the program. Problems go to `diagnostics`; the caller stops after every file
	///          of the batch is expanded.
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
		var _i = 0;
		while (_i < _n) {
			var _t = _stream[_i];
			if (_t.kind == __GMLC_TokenKind_Identifier) {
				// a macro named nameof replaces the operator, as in GameMaker (measured)
				if (_nameof) && (_t.value == "nameof") && !__gmlc_struct_has(_batch.active, "nameof") && (_i + 1 < _n) && (_stream[_i + 1].value == "(") {
					_i = __nameof(_stream, _i, _withMacros);
					continue;
				}
				if (__isExpandable(_batch, _t.value)) {
					var _def = _batch.active[$ _t.value];
					if (_def[$ "extension"] != undefined) {
						_i = _def.extension.expandMacro(self, _batch, _stream, _i, _def, 1, _withMacros, _t);
						continue;
					}
					__emitExpansion(_batch, _t, _def, 1, _withMacros);
					_i++;
					continue;
				}
			}
			array_push(_withMacros, _t);
			if (array_length(_withMacros) > maxExpandedTokens) {
				__report("GMLC0306", _t);
				break;
			}
			_i++;
		}
		
		var _program = _unit.program;
		__checkEnumRefs(_batch, _withMacros);
		_program.tokens = _withMacros;
		
		// each member's value with its macros expanded, for the parser
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
		return _program;
	};
	#endregion
	
	#region Collect
	#region jsDoc
	/// @func    __collectMacro(_tokens, _i, _unit)
	/// @desc    Reads `#macro [Config:]NAME body` starting at the directive. The body runs to the first line break
	///          not continued by a backslash; comments are left out of its tokens and kept in its text. Records the
	///          definition in the unit.
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
		var _nameToken = _tokens[_i];
		var _config = undefined;
		// `Config:NAME`, written without spaces
		if (_i + 2 < _n) && (_tokens[_i + 1].value == ":") && (_tokens[_i + 1].start == _nameToken.end)
		&& (_tokens[_i + 2].start == _tokens[_i + 1].end) && __isWordText(_tokens[_i + 2].name) {
			_config = _nameToken.name;
			_nameToken = _tokens[_i + 2];
			_i += 2;
		}
		if (!__isWordText(_nameToken.name)) {
			__report("GMLC0302", _nameToken, [_nameToken.name]);
		}
		_i++;
		
		// a language extension may take the definition (a parameter list right after the name)
		var _params = undefined;
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
			if (_t.kind == __GMLC_TokenKind_Newline) break;
			_textEnd = _t[$ "end"];
			if (_t.kind == __GMLC_TokenKind_Comment) {
				if (string_pos("\n", _t.name) > 0) {
					__report("GMLC0309", _t);
				}
			}
			else if (_t.kind == __GMLC_TokenKind_Backslash) {
				// only comments and more backslashes may follow (`;\\` continues, as in GameMaker), then the line break
				// that the body continues past
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
		if (_last >= 0) && (_body[_last].value == ";") {
			__report("GMLC0304", _body[_last], [_nameToken.name]);
		}
		array_push(_unit.macros, {
			name: _nameToken.name, config: _config, body: _body, token: _nameToken,
			span: new GMLC_Span(_directive.file, _directive.start, _textEnd),
			text: _unit.program.file.text(_textStart, _textEnd),
			params: _params, extension: _owner,
		});
		return _i;
	};
	
	#region jsDoc
	/// @func    __startsEnum(_tokens, _i)
	/// @desc    Whether the `enum` keyword at _i starts a declaration: a name, then `{`, line breaks and comments
	///          allowed between them.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _tokens : The file's lexer tokens
	/// @param   {Real}          _i      : Index of the `enum` keyword
	/// @returns {Bool}
	#endregion
	static __startsEnum = function(_tokens, _i) {
		var _j = __nextSignificant(_tokens, _i + 1);
		if (_j < 0) || (_tokens[_j].kind != __GMLC_TokenKind_Identifier) return false;
		var _k = __nextSignificant(_tokens, _j + 1);
		return (_k >= 0) && (_tokens[_k].value == "{");
	};
	
	#region jsDoc
	/// @func    __collectEnum(_tokens, _i, _unit)
	/// @desc    Reads `enum Name { member [= value], ... }` starting at `enum`. Members are separated by commas at
	///          bracket depth 0; a member's value is every token up to that comma or the closing brace. The
	///          semicolons right after the declaration are dropped. Records the declaration in the unit.
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
		var _enum = { name: _nameToken.name, token: _nameToken, members: [], memberIndex: {}, span: undefined };
		var _enumStart = _tokens[_i].start;
		_i = __nextSignificant(_tokens, _j + 1) + 1; // past `{`
		
		while (true) {
			_i = __nextSignificant(_tokens, _i);
			if (_i < 0) {
				__report("GMLC0310", _nameToken, [_enum.name], "GMLC0310.no-closing-brace");
				return _n;
			}
			var _t = _tokens[_i];
			if (_t.value == "}") break;
			
			var _member = _t;
			var _good = __isWordText(_member.name);
			if (!_good) __report("GMLC0310", _member, [_member.name]);
			_i++;
			
			// the value: every token up to the comma or closing brace at depth 0
			var _init = undefined;
			var _k = __nextSignificant(_tokens, _i);
			if (_good) && (_k >= 0) && (_tokens[_k].value == "=") {
				_init = [];
				_i = _k + 1;
			}
			var _depth = 0;
			var _memberEnd = _member[$ "end"];
			while (_i < _n) {
				var _v = _tokens[_i];
				if (_v.kind == __GMLC_TokenKind_Newline) || (_v.kind == __GMLC_TokenKind_Comment) { _i++; continue; }
				if (_depth == 0) && ((_v.value == ",") || (_v.value == "}")) break;
				if (_v.value == "(") || (_v.value == "[") || (_v.value == "{") _depth++;
				if (_v.value == ")") || (_v.value == "]") || (_v.value == "}") _depth--;
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
				if (__gmlc_struct_has(_enum.memberIndex, _member.name)) {
					__report("GMLC0312", _member, [_enum.name, _member.name]);
				}
				else {
					_enum.memberIndex[$ _member.name] = array_length(_enum.members);
					array_push(_enum.members, {
						name: _member.name, token: _member, init: _init, value: undefined,
						span: new GMLC_Span(_member.file, _member.start, _memberEnd),
					});
				}
			}
			if (_i < _n) && (_tokens[_i].value == ",") _i++;
		}
		_enum.span = new GMLC_Span(_nameToken.file, _enumStart, _tokens[_i][$ "end"]);
		_i++; // past `}`
		
		// frequently people put ; after the closing brace
		while (true) {
			var _k = __nextSignificant(_tokens, _i);
			if (_k < 0) || (_tokens[_k].value != ";") break;
			_i = _k + 1;
		}
		array_push(_unit.enums, _enum);
		return _i;
	};
	
	#region jsDoc
	/// @func    __isNoOpPragma(_text)
	/// @desc    Whether a comment is the `@NoOp` pragma: a line comment whose text after `//` or `///` and optional
	///          spaces starts with the word `@NoOp`.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {String} _text : The comment's source text
	/// @returns {Bool}
	#endregion
	static __isNoOpPragma = function(_text) {
		if (string_copy(_text, 1, 2) != "//") return false;
		var _p = 3;
		var _len = string_length(_text);
		if (string_char_at(_text, _p) == "/") _p++;
		while (_p <= _len) && ((string_char_at(_text, _p) == " ") || (string_char_at(_text, _p) == "\t")) _p++;
		if (string_copy(_text, _p, 5) != "@NoOp") return false;
		return (_p + 5 > _len) || !__char_is_alphanumeric(ord(string_char_at(_text, _p + 5)));
	};
	
	#region jsDoc
	/// @func    __noOpPragmaCall(_tokens, _i, _stream)
	/// @desc    At `gml_pragma`: when the tokens are the statement `gml_pragma("@NoOp")` with an optional `;`, the index
	///          after it, else -1. It is a statement when it starts the file or follows `;`, `{` or `}`, or follows a
	///          line break after anything but `)`, `else` or `do` (whose statement it would be).
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _tokens : The file's tokens
	/// @param   {Real}          _i      : The index of `gml_pragma`
	/// @param   {Array<Struct>} _stream : The tokens kept so far
	/// @returns {Real}
	#endregion
	static __noOpPragmaCall = function(_tokens, _i, _stream) {
		var _count = array_length(_stream);
		if (_count > 0) {
			var _prev = _stream[_count - 1];
			var _v = _prev.value;
			var _closes = (_v == ";") || (_v == "{") || (_v == "}");
			if (!_closes) {
				var _broken = false;
				var _j = _i - 1;
				while (_j >= 0) && (_tokens[_j] != _prev) {
					if (_tokens[_j].kind == __GMLC_TokenKind_Newline) _broken = true;
					_j--;
				}
				if (!_broken) || (_v == ")") || (_v == "else") || (_v == "do") return -1;
			}
		}
		var _open = __nextSignificant(_tokens, _i + 1);
		if (_open < 0) || (_tokens[_open].value != "(") return -1;
		var _text = __nextSignificant(_tokens, _open + 1);
		if (_text < 0) || (_tokens[_text].kind != __GMLC_TokenKind_String) || (_tokens[_text].value != "@NoOp") return -1;
		var _close = __nextSignificant(_tokens, _text + 1);
		if (_close < 0) || (_tokens[_close].value != ")") return -1;
		var _after = __nextSignificant(_tokens, _close + 1);
		if (_after >= 0) && (_tokens[_after].value == ";") return _after + 1;
		return _close + 1;
	};
	
	#region jsDoc
	/// @func    __regionTitle(_text)
	/// @desc    The title of a `#region` line: the text after the directive word, trimmed.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {String} _text : The region token's source text
	/// @returns {String}
	#endregion
	static __regionTitle = function(_text) {
		var _p = 2;
		var _len = string_length(_text);
		while (_p <= _len) && __char_is_alphanumeric(ord(string_char_at(_text, _p))) _p++;
		return string_trim(string_copy(_text, _p, _len - _p + 1));
	};
	#endregion
	
	#region Merge
	#region jsDoc
	/// @func    __findCycles(_batch)
	/// @desc    Searches the macro graph (each active macro to the active macros its body names) depth first, names
	///          in byte order. Each cycle is reported once, at the first macro of the cycle, with its path; every
	///          macro on a cycle is marked cyclic.
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
	static __visitMacro = function(_batch, _name, _state, _path) {
		_state[$ _name] = 1;
		array_push(_path, _name);
		var _def = _batch.active[$ _name];
		var _body = _def.body;
		var _params = _def[$ "params"] ?? [];
		var _b = 0; repeat (array_length(_body)) {
			var _t = _body[_b];
			// a parameter of the macro is not a use of a macro of that name
			if (_t.kind == __GMLC_TokenKind_Identifier) && __gmlc_struct_has(_batch.active, _t.value) && !array_contains(_params, _t.value) {
				var _s = __gmlc_struct_get(_state, _t.value) ?? 0;
				if (_s == 1) {
					// a cycle: the part of the path from that name on
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
	/// @func    __emitExpansion(_batch, _use, _def, _depth, _out)
	/// @desc    Appends copies of a macro's body to _out, expanding the macros it names, up to depth 64.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct}        _batch : The merged batch
	/// @param   {Struct}        _use   : The token of the outermost use
	/// @param   {Struct}        _def   : The macro definition
	/// @param   {Real}          _depth : Nesting depth, 1 for a use in the file
	/// @param   {Array<Struct>} _out   : Tokens written so far
	#endregion
	static __emitExpansion = function(_batch, _use, _def, _depth, _out) {
		__emitTokens(_batch, _use, _def, _def.body, _depth, _out);
	};
	
	#region jsDoc
	/// @func    __emitTokens(_batch, _use, _def, _tokens, _depth, _out)
	/// @desc    Appends copies of the tokens a macro's use stands for (its body, or the body with its arguments put in),
	///          with the macro's origin, expanding the macros they name, up to depth 64. A language extension that
	///          expands a macro of its own calls it with the tokens it made.
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
				if (_inner[$ "extension"] != undefined) {
					_b = _inner.extension.expandMacro(self, _batch, _tokens, _b, _inner, _depth + 1, _out, _use);
					continue;
				}
				__emitExpansion(_batch, _use, _inner, _depth + 1, _out);
			}
			else {
				array_push(_out, __copyToken(_t, _t.type, _t.value, _origin));
			}
			_b++;
		}
	};
	
	#region jsDoc
	/// @func    __checkEnumRefs(_batch, _tokens)
	/// @desc    Reports every `Enum.Member` of a batch enum (not itself after a `.`) whose enum has no such member. The
	///          references stay as they are written: lowering gives them their values once every stage has seen them.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct}        _batch  : The merged batch
	/// @param   {Array<Struct>} _tokens : Tokens after macro expansion
	#endregion
	static __checkEnumRefs = function(_batch, _tokens) {
		if (array_length(_batch.enumNames) == 0) return;
		var _n = array_length(_tokens);
		var _i = 0; repeat (_n) {
			var _t = _tokens[_i];
			if (_t.kind == __GMLC_TokenKind_Identifier) && __gmlc_struct_has(_batch.enums, _t.value)
			&& (_i + 2 < _n) && (_tokens[_i + 1].value == ".") && __isWordText(_tokens[_i + 2].name)
			&& ((_i == 0) || (_tokens[_i - 1].value != ".")) {
				if (!__gmlc_struct_has(_batch.enums[$ _t.value].memberIndex, _tokens[_i + 2].name)) {
					__report("GMLC0314", _tokens[_i + 2], [_t.value, _tokens[_i + 2].name]);
				}
			}
		_i++}
	};
	
	#region jsDoc
	/// @func    __expandValue(_batch, _member)
	/// @desc    The tokens of an enum member's value with the macros it uses expanded, its enum references checked.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct} _batch  : The merged batch
	/// @param   {Struct} _member : The member, as __collectEnum records it
	/// @returns {Array<Struct>|Undefined} undefined for a member without a value
	#endregion
	static __expandValue = function(_batch, _member) {
		if (_member.init == undefined) return undefined;
		var _expanded = [];
		var _b = 0; repeat (array_length(_member.init)) {
			var _t = _member.init[_b];
			if (_t.kind == __GMLC_TokenKind_Identifier) && __isExpandable(_batch, _t.value) {
				__emitExpansion(_batch, _t, _batch.active[$ _t.value], 1, _expanded);
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
	/// @desc    `nameof(<name>)` becomes a String token holding the tokens inside the parentheses joined as written
	///          (`nameof(E.m)` is "E.m"); nothing inside is expanded.
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
			if (_t.value == "(") _depth++;
			if (_t.value == ")") {
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
		var _string = __copyToken(_stream[_i], __GMLC_TokenType_String, _text, undefined, __GMLC_TokenKind_String, "nameof(" + _text + ")");
		_string[$ "end"] = _stream[_j][$ "end"];
		_string.ty = "string";
		array_push(_out, _string);
		return _j + 1;
	};
	#endregion
	
	#region Tokens and diagnostics
	#region jsDoc
	/// @func    __copyToken(_t, _type, _value, _origin, [_kind], [_name])
	/// @desc    A new token with the position of _t (tokens are never modified once made).
	/// @self    GMLC_Gen_1_PreProcessor
	/// @returns {Struct}
	#endregion
	static __copyToken = function(_t, _type, _value, _origin, _kind = undefined, _name = undefined) {
		var _c = new __GMLC_create_token(_type, _name ?? _t.name, _value, _t.file, _t.start, _t[$ "end"]);
		_c.kind = _kind ?? _t.kind;
		_c.ty = _t[$ "ty"];
		_c.origin = _origin;
		return _c;
	};
	static __span = function(_t) {
		return new GMLC_Span(_t[$ "file"], _t.start, _t[$ "end"]);
	};
	static __nextSignificant = function(_tokens, _i) {
		var _n = array_length(_tokens);
		while (_i < _n) {
			var _k = _tokens[_i].kind;
			if (_k != __GMLC_TokenKind_Newline) && (_k != __GMLC_TokenKind_Comment) return _i;
			_i++;
		}
		return -1;
	};
	static __isWordText = function(_s) {
		var _len = string_length(_s);
		if (_len == 0) || !__char_is_alphabetic(ord(string_char_at(_s, 1))) return false;
		var _p = 2; repeat (_len - 1) {
			if (!__char_is_alphanumeric(ord(string_char_at(_s, _p)))) return false;
		_p++}
		return true;
	};
	
	// a problem at a token; its severity is the catalogue's
	static __report = function(_code, _at, _args = undefined, _messageId = _code) {
		array_push(diagnostics, new GMLC_Diagnostic(_code, new GMLC_Span(_at.file, _at.start, _at[$ "end"]), _args, _messageId));
	};
	static __errorCount = function() {
		var _count = 0;
		var _i = 0; repeat (array_length(diagnostics)) {
			if (diagnostics[_i].severity == "error") _count++;
		_i++}
		return _count;
	};
	static __throwErrors = function() {
		if (__gmlc_has_errors(diagnostics)) __gmlc_throw_diagnostics(diagnostics, sources);
	};
	#endregion
	}
	
	#endregion
		