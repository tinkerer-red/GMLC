#region PreProcessor.gml
// For a batch of files: `collect` reads each file's #macro and enum definitions, regions and @NoOp pragmas and keeps
// the other significant tokens; one `merge` builds the batch's definitions (the configuration chain picks each macro,
// duplicates and cycles are errors, enum members get their values on demand); `expand` then writes each file's
// tokens with every macro use and every `Enum.Member` replaced by fresh tokens. It reads no environment, except
// whether `nameof` is exposed.

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
	///          Throws the first error.
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
					__error("GMLC0308", _t, "a backslash outside a #macro body");
					break;
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
		__throwFirstError();
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
	///          are batch-global; members get their values when first needed. Throws the first error.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _units       : Results of collect, in batch order
	/// @param   {Array<String>} _configChain : The active configuration and its ancestors, ending with "Default"
	/// @returns {Struct} The batch's definitions
	#endregion
	static merge = function(_units, _configChain) {
		diagnostics = [];
		var _batch = { keys: {}, active: {}, names: [], cyclic: {}, enums: {}, enumNames: [], values: {} };
		
		// definitions by (configuration, name), first one kept
		var _u = 0; repeat (array_length(_units)) {
			var _macros = _units[_u].macros;
			var _m = 0; repeat (array_length(_macros)) {
				var _def = _macros[_m];
				var _key = (_def.config ?? "Default") + ":" + _def.name;
				if (struct_exists(_batch.keys, _key)) {
					__error("GMLC0303", _def.token, $"macro {_def.name} is already defined");
				}
				else {
					_batch.keys[$ _key] = _def;
				}
			_m++}
			var _enums = _units[_u].enums;
			var _e = 0; repeat (array_length(_enums)) {
				var _enum = _enums[_e];
				if (__gmlc_struct_has(_batch.enums, _enum.name)) {
					__error("GMLC0311", _enum.token, $"enum {_enum.name} has already been defined");
				}
				else {
					_batch.enums[$ _enum.name] = _enum;
					array_push(_batch.enumNames, _enum.name);
					_batch.values[$ _enum.name] = {};
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
		__throwFirstError();
		return _batch;
	};
	
	#region jsDoc
	/// @func    expand(_unit, _batch)
	/// @desc    Writes the unit's tokens with every use of an active macro replaced by copies of its body (nested uses
	///          too) and every `Enum.Member` replaced by the member's value. `nameof(...)` becomes the written name
	///          when the environment exposes `nameof`, and nothing inside it is expanded. Sets the program's tokens
	///          and tables and returns the program. Throws the first error.
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
				if (_nameof) && (_t.value == "nameof") && (_i + 1 < _n) && (_stream[_i + 1].value == "(") {
					_i = __nameof(_stream, _i, _withMacros);
					continue;
				}
				if (__isExpandable(_batch, _t.value)) {
					__emitExpansion(_batch, _t, _batch.active[$ _t.value], 1, _withMacros);
					_i++;
					continue;
				}
			}
			array_push(_withMacros, _t);
			if (array_length(_withMacros) > maxExpandedTokens) {
				__error("GMLC0306", _t, "more than 8,000,000 tokens after macro expansion");
				break;
			}
			_i++;
		}
		__throwFirstError();
		
		var _program = _unit.program;
		_program.tokens = __replaceEnumRefs(_batch, _withMacros);
		
		// the compile-time value of each member of this file's enums, undefined when it has none
		var _e = 0; repeat (array_length(_unit.enums)) {
			var _enum = _unit.enums[_e];
			var _m = 0; repeat (array_length(_enum.members)) {
				var _member = _enum.members[_m];
				var _value = __memberTokens(_batch, _enum.name, _member.name, _member.token);
				_member.value = (array_length(_value) == 1) && (_value[0].kind == __GMLC_TokenKind_Number) ? _value[0].value : undefined;
			_m++}
		_e++}
		_program.macros = _unit.macros;
		_program.enums = _unit.enums;
		_program.regions = _unit.regions;
		_program.pragmas = _unit.pragmas;
		__throwFirstError();
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
			__error("GMLC0301", _directive, "#macro without a name");
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
			__error("GMLC0302", _nameToken, $"#macro name expected, got {_nameToken.name}");
		}
		else if (_nameToken.name == "nameof") && env.isFunction("nameof") {
			__error("GMLC0317", _nameToken, "#macro cannot redefine nameof");
		}
		_i++;
		
		var _body = [];
		var _textStart = (_i < _n) && (_tokens[_i].kind != __GMLC_TokenKind_Newline) ? _tokens[_i].start : _nameToken[$ "end"];
		var _textEnd = _nameToken[$ "end"];
		while (_i < _n) {
			var _t = _tokens[_i];
			if (_t.kind == __GMLC_TokenKind_Newline) break;
			_textEnd = _t[$ "end"];
			if (_t.kind == __GMLC_TokenKind_Comment) {
				if (string_pos("\n", _t.name) > 0) {
					__error("GMLC0309", _t, "a block comment over several lines inside a #macro body");
				}
			}
			else if (_t.kind == __GMLC_TokenKind_Backslash) {
				// only comments and more backslashes may follow (`;\\` continues, as in GameMaker), then the line break
				// that the body continues past
				_i++;
				while (_i < _n) && (_tokens[_i].kind != __GMLC_TokenKind_Newline) {
					if (_tokens[_i].kind != __GMLC_TokenKind_Comment) && (_tokens[_i].kind != __GMLC_TokenKind_Backslash) {
						__error("GMLC0307", _tokens[_i], "text after the continuation backslash of a #macro");
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
			__warning("GMLC0304", _body[_last], $"#macro {_nameToken.name} ends with ;");
		}
		array_push(_unit.macros, {
			name: _nameToken.name, config: _config, body: _body, token: _nameToken,
			span: new GMLC_Span(_directive.file, _directive.start, _textEnd),
			text: _unit.program.file.text(_textStart, _textEnd),
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
				__error("GMLC0310", _nameToken, $"enum {_enum.name} has no closing brace");
				return _n;
			}
			var _t = _tokens[_i];
			if (_t.value == "}") break;
			
			var _member = _t;
			var _good = __isWordText(_member.name);
			if (!_good) __error("GMLC0310", _member, $"malformed enum entry {_member.name}");
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
					__error("GMLC0310", _v, $"malformed enum entry {_member.name}");
					_good = false;
				}
				_i++;
			}
			if (_good) {
				if (__gmlc_struct_has(_enum.memberIndex, _member.name)) {
					__error("GMLC0312", _member, $"enum {_enum.name} has member {_member.name} twice");
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
		var _body = _batch.active[$ _name].body;
		var _b = 0; repeat (array_length(_body)) {
			var _t = _body[_b];
			if (_t.kind == __GMLC_TokenKind_Identifier) && __gmlc_struct_has(_batch.active, _t.value) {
				var _s = __gmlc_struct_get(_state, _t.value) ?? 0;
				if (_s == 1) {
					// a cycle: the part of the path from that name on
					var _from = array_get_index(_path, _t.value);
					var _cycle = [];
					array_copy(_cycle, 0, _path, _from, array_length(_path) - _from);
					var _c = 0; repeat (array_length(_cycle)) { _batch.cyclic[$ _cycle[_c]] = true; _c++ }
					array_push(_cycle, _t.value);
					__error("GMLC0305", _batch.active[$ _cycle[0]].token, "recursive macro expansion: " + string_join_ext(" -> ", _cycle));
				}
				else if (_s == 0) {
					__visitMacro(_batch, _t.value, _state, _path);
				}
			}
		_b++}
		array_pop(_path);
		_state[$ _name] = 2;
	};
	
	#region jsDoc
	/// @func    __memberTokens(_batch, _enumName, _memberName, _use)
	/// @desc    The tokens that replace `Enum.Member`: one int64 Number when the value is known at compile time
	///          (number literals, `( )`, `+ - * / div mod & | ^ << >> ~` and other members), otherwise
	///          `__gmlc_enum_value(<value>)`, which gives the int64 of the value at run time. A member without a value
	///          is the previous member plus one (0 for the first). Values are computed once per batch.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct} _batch      : The merged batch
	/// @param   {String} _enumName   : The enum
	/// @param   {String} _memberName : The member
	/// @param   {Struct} _use        : Token of the use, for positions
	/// @returns {Array<Struct>|Undefined} undefined when the enum has no such member
	#endregion
	static __memberTokens = function(_batch, _enumName, _memberName, _use) {
		var _enum = _batch.enums[$ _enumName];
		var _index = __gmlc_struct_get(_enum.memberIndex, _memberName);
		if (_index == undefined) return undefined;
		var _memo = _batch.values[$ _enumName];
		var _known = __gmlc_struct_get(_memo, _memberName);
		if (_known != undefined) {
			if (is_array(_known)) return _known;
			__error("GMLC0315", _use, $"enum member {_enumName}.{_memberName} depends on itself");
			return [__numberToken(int64(0), _use)];
		}
		_memo[$ _memberName] = "in progress";
		
		var _member = _enum.members[_index];
		var _result;
		if (_member.init != undefined) {
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
			_expanded = __replaceEnumRefs(_batch, _expanded);
			var _value = __evaluate(_expanded);
			_result = (_value != undefined) ? [__numberToken(_value, _member.token)] : __enumWrapper(_expanded, _member.token);
		}
		else if (_index == 0) {
			_result = [__numberToken(int64(0), _member.token)];
		}
		else {
			var _previous = __memberTokens(_batch, _enumName, _enum.members[_index - 1].name, _member.token);
			if (array_length(_previous) == 1) && (_previous[0].kind == __GMLC_TokenKind_Number) {
				_result = [__numberToken(_previous[0].value + 1, _member.token)];
			}
			else {
				var _plusOne = [__newToken(__GMLC_TokenKind_Op, __GMLC_TokenType_Punctuation, "(", "(", _member.token)];
				array_copy(_plusOne, 1, _previous, 0, array_length(_previous));
				array_push(_plusOne,
					__newToken(__GMLC_TokenKind_Op, __GMLC_TokenType_Punctuation, ")", ")", _member.token),
					__newToken(__GMLC_TokenKind_Op, __GMLC_TokenType_Operator, "+", "+", _member.token),
					__numberToken(int64(1), _member.token));
				_result = __enumWrapper(_plusOne, _member.token);
			}
		}
		_memo[$ _memberName] = _result;
		return _result;
	};
	
	#region jsDoc
	/// @func    __evaluate(_tokens)
	/// @desc    The int64 value of an enum member's value when it is known at compile time: integral number literals
	///          with `( )`, unary `- + ~` and binary `* / div mod + - << >> & ^ |` in the parser's precedence. `/`
	///          only when exact; shift counts 0 to 63.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Array<Struct>} _tokens : The value's tokens, macros and enum references already replaced
	/// @returns {Int64|Undefined} undefined when the value is not of that form
	#endregion
	static __evaluate = function(_tokens) {
		var _state = { tokens: _tokens, pos: 0 };
		var _value = __evalBinary(_state, 0);
		if (_value == undefined) || (_state.pos != array_length(_tokens)) return undefined;
		return _value;
	};
	// operator tiers, loosest first: | ^ & (<< >>) (+ -) (* / div mod)
	static __evalTiers = [["|"], ["^"], ["&"], ["<<", ">>"], ["+", "-"], ["*", "/", "div", "mod"]];
	static __evalBinary = function(_state, _tier) {
		if (_tier >= array_length(__evalTiers)) return __evalUnary(_state);
		var _left = __evalBinary(_state, _tier + 1);
		while (_left != undefined) && (_state.pos < array_length(_state.tokens)) {
			var _t = _state.tokens[_state.pos];
			if (_t.kind != __GMLC_TokenKind_Op) || !array_contains(__evalTiers[_tier], _t.value) break;
			_state.pos++;
			var _right = __evalBinary(_state, _tier + 1);
			if (_right == undefined) return undefined;
			switch (_t.value) {
				case "|": _left = _left | _right; break;
				case "^": _left = _left ^ _right; break;
				case "&": _left = _left & _right; break;
				case "<<": if (_right < 0) || (_right > 63) return undefined; _left = _left << _right; break;
				case ">>": if (_right < 0) || (_right > 63) return undefined; _left = _left >> _right; break;
				case "+": _left = _left + _right; break;
				case "-": _left = _left - _right; break;
				case "*": _left = _left * _right; break;
				case "/": if (_right == 0) || (_left mod _right != 0) return undefined; _left = _left div _right; break;
				case "div": if (_right == 0) return undefined; _left = _left div _right; break;
				case "mod": if (_right == 0) return undefined; _left = _left mod _right; break;
			}
			_left = int64(_left);
		}
		return _left;
	};
	static __evalUnary = function(_state) {
		if (_state.pos >= array_length(_state.tokens)) return undefined;
		var _t = _state.tokens[_state.pos];
		if (_t.kind == __GMLC_TokenKind_Op) {
			switch (_t.value) {
				case "-": _state.pos++; var _v = __evalUnary(_state); return (_v == undefined) ? undefined : int64(-_v);
				case "+": _state.pos++; return __evalUnary(_state);
				case "~": _state.pos++; var _v = __evalUnary(_state); return (_v == undefined) ? undefined : int64(~_v);
				case "(":
					_state.pos++;
					var _v = __evalBinary(_state, 0);
					if (_v == undefined) || (_state.pos >= array_length(_state.tokens)) || (_state.tokens[_state.pos].value != ")") return undefined;
					_state.pos++;
					return _v;
			}
			return undefined;
		}
		if (_t.kind == __GMLC_TokenKind_Number) {
			var _v = _t.value;
			if (is_int64(_v)) { _state.pos++; return _v; }
			if (is_real(_v)) && (frac(_v) == 0) && (abs(_v) < 9007199254740992) { _state.pos++; return int64(_v); }
		}
		return undefined;
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
		if (_depth > maxMacroDepth) {
			__error("GMLC0306", _use, $"macro {_def.name} nests more than 64 deep");
			return;
		}
		var _origin = new GMLC_Origin("macro", _def.name, undefined, _def.config, _def.span, __span(_use));
		var _body = _def.body;
		var _b = 0; repeat (array_length(_body)) {
			var _t = _body[_b];
			if (_t.kind == __GMLC_TokenKind_Identifier) && __isExpandable(_batch, _t.value) {
				__emitExpansion(_batch, _use, _batch.active[$ _t.value], _depth + 1, _out);
			}
			else {
				array_push(_out, __copyToken(_t, _t.type, _t.value, _origin));
			}
		_b++}
	};
	
	#region jsDoc
	/// @func    __replaceEnumRefs(_batch, _tokens)
	/// @desc    Returns the tokens with every `Enum.Member` of a batch enum (not itself after a `.`) replaced by the
	///          member's tokens. A member the enum does not have is an error.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @param   {Struct}        _batch  : The merged batch
	/// @param   {Array<Struct>} _tokens : Tokens after macro expansion
	/// @returns {Array<Struct>}
	#endregion
	static __replaceEnumRefs = function(_batch, _tokens) {
		if (array_length(_batch.enumNames) == 0) return _tokens;
		var _out = [];
		var _n = array_length(_tokens);
		var _i = 0;
		while (_i < _n) {
			var _t = _tokens[_i];
			if (_t.kind == __GMLC_TokenKind_Identifier) && __gmlc_struct_has(_batch.enums, _t.value)
			&& (_i + 2 < _n) && (_tokens[_i + 1].value == ".") && __isWordText(_tokens[_i + 2].name)
			&& ((_i == 0) || (_tokens[_i - 1].value != ".")) {
				var _member = __memberTokens(_batch, _t.value, _tokens[_i + 2].name, _t);
				if (_member == undefined) {
					__error("GMLC0314", _tokens[_i + 2], $"enum reference {_t.value}.{_tokens[_i + 2].name} does not exist");
					_i += 3;
					continue;
				}
				var _enumDef = _batch.enums[$ _t.value];
				var _memberDef = _enumDef.members[_enumDef.memberIndex[$ _tokens[_i + 2].name]];
				var _origin = new GMLC_Origin("enum", _t.value, _tokens[_i + 2].name, undefined, _memberDef.span, new GMLC_Span(_t.file, _t.start, _tokens[_i + 2][$ "end"]));
				if (array_length(_member) == 1) {
					// one number: its text is the reference, as written
					array_push(_out, __copyToken(_member[0], _member[0].type, _member[0].value, _origin, undefined, _t.value + "." + _tokens[_i + 2].name));
				}
				else {
					var _m = 0; repeat (array_length(_member)) {
						array_push(_out, __copyToken(_member[_m], _member[_m].type, _member[_m].value, _origin));
					_m++}
				}
				_i += 3;
				continue;
			}
			array_push(_out, _t);
			_i++;
		}
		return _out;
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
	static __newToken = function(_kind, _type, _name, _value, _at) {
		return __copyToken(_at, _type, _value, undefined, _kind, _name);
	};
	static __numberToken = function(_value, _at) {
		var _token = __newToken(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, string(_value), _value, _at);
		_token.ty = is_int64(_value) ? "int64" : "real";
		return _token;
	};
	#region jsDoc
	/// @func    __enumWrapper(_tokens, _at)
	/// @desc    The tokens of `__gmlc_enum_value(<_tokens>)`: the int64 of a member's value at run time. The name is
	///          GMLC's own helper; the resolver binds it only where an enum reference made it.
	/// @self    GMLC_Gen_1_PreProcessor
	/// @returns {Array<Struct>}
	#endregion
	static __enumWrapper = function(_tokens, _at) {
		var _out = [
			__newToken(__GMLC_TokenKind_Identifier, __GMLC_TokenType_Identifier, "__gmlc_enum_value", "__gmlc_enum_value", _at),
			__newToken(__GMLC_TokenKind_Op, __GMLC_TokenType_Punctuation, "(", "(", _at),
		];
		array_copy(_out, 2, _tokens, 0, array_length(_tokens));
		array_push(_out, __newToken(__GMLC_TokenKind_Op, __GMLC_TokenType_Punctuation, ")", ")", _at));
		return _out;
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
	
	static __error = function(_code, _token, _message) {
		array_push(diagnostics, { code: _code, severity: "error", token: _token, message: _message });
	};
	static __warning = function(_code, _token, _message) {
		array_push(diagnostics, { code: _code, severity: "warning", token: _token, message: _message });
	};
	static __throwFirstError = function() {
		var _i = 0; repeat (array_length(diagnostics)) {
			var _d = diagnostics[_i];
			if (_d.severity == "error") {
				var _at = (sources != undefined) ? sources.position(_d.token) : { fileName: "", line: 0, column: 0, lineString: "" };
				throw_gmlc_error(_d.code + ": " + _d.message, _at.line, _at.lineString, _at.column, _at.fileName);
			}
		_i++}
	};
	#endregion
	}
	
	#endregion
		