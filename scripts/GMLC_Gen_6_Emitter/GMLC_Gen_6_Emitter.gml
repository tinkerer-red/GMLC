#region jsDoc
/// @func    GMLC_Gen_6_Emitter(_env)
/// @desc    GML text from a lowered or optimized tree: what GameMaker compiles in place of the source. Every item is
///          printed in one layout (4 spaces, braces on the header line, a semicolon after every simple statement),
///          and parentheses are written wherever two different operators meet, so the text never depends on
///          GameMaker's precedence. Comments, `#macro` lines, enum declarations and regions are copied from the source
///          as they are, in their place between the statements; a `@NoOp` pragma call is copied inside `/* */`,
///          since GameMaker refuses it. A value that came from a
///          macro is written as the macro's name when the whole expansion is one part of the tree; an enum value as
///          `Enum.Member`.
/// @param   {Struct.GMLC_Env} _env : The environment (preserve_lines, extensions)
/// @returns {Struct.GMLC_Gen_6_Emitter}
#endregion
function GMLC_Gen_6_Emitter(_env) constructor {
	#region Config
	static indentUnit = "    ";
	#endregion
	
	#region Init
	env = _env;
	
	out = buffer_create(1 << 16, buffer_grow, 1);
	src = buffer_create(1, buffer_grow, 1);
	file = undefined;
	src_length = 0;
	pieces = [];
	piece = 0;
	indent = 0;
	line_open = false;
	line_comment = false; // also set after a macro or region: the line must end before more text
	last_end = -1;
	can_blank = false;
	printed = 0;
	__indents = [""];
	__runs = {};
	__counts = {};
	__tokens = [];
	__unclosed = false;
	__has_runs = false;
	__absorb = 0;        // how many `;` right after the last statement the parser takes as its own
	__use_parentheses = false;
	__preserve = false;
	__anchor = 1;
	__out_line = 1;
	__pending_space = false;
	__moved = false;
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    emit(_ast, _program)
	/// @desc    The GML text of one file's tree. With GMLC_Env.preserve_lines every statement, comment and closing
	///          bracket stays on its source line and the file keeps its line count; when that cannot hold the
	///          source is returned as it is.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTScript} _ast     : The lowered or optimized tree
	/// @param   {Struct}           _program : The file's program record after preprocessing (file, tokens, comments)
	/// @returns {String}
	#endregion
	static emit = function(_ast, _program) {
		file = _program.file;
		src_length = string_byte_length(file.source);
		buffer_resize(src, src_length + 1);
		buffer_seek(src, buffer_seek_start, 0);
		buffer_write(src, buffer_text, file.source);
		buffer_poke(src, src_length, buffer_u8, 0);
		buffer_seek(out, buffer_seek_start, 0);
		indent = 0;
		line_open = false;
		line_comment = false;
		last_end = -1;
		can_blank = false;
		printed = 0;
		__unclosed = false;
		__absorb = 0;
		__preserve = env.preserve_lines;
		__anchor = 1;
		__out_line = 1;
		__pending_space = false;
		__moved = false;
		__collectPieces(_ast, _program);
		__collectRuns(_program.tokens, _ast);
		
		__writeStatements(_ast.body);
		__writePieces(infinity);
		if (__preserve) {
			var _lines = array_length(file.line_starts);
			if (__moved) || (__out_line > _lines) return file.source;
			repeat (_lines - __out_line) buffer_write(out, buffer_u8, 10);
		}
		// a block comment that is never closed runs to the end of the file: a line break after it would join it
		else if (line_open) && !__unclosed buffer_write(out, buffer_text, "\n");
		
		buffer_write(out, buffer_u8, 0);
		buffer_seek(out, buffer_seek_start, 0);
		return buffer_read(out, buffer_string);
	};
	#endregion
	
	#region Private
	#region Source
	#region jsDoc
	/// @func    __sourceText(_start, _end)
	/// @desc    The source text between two byte offsets.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Real} _start : First byte
	/// @param   {Real} _end   : Byte after the last
	/// @returns {String}
	#endregion
	static __sourceText = function(_start, _end) {
		if (_end <= _start) return "";
		var _keep = buffer_peek(src, _end, buffer_u8);
		buffer_poke(src, _end, buffer_u8, 0);
		buffer_seek(src, buffer_seek_start, _start);
		var _text = buffer_read(src, buffer_string);
		buffer_poke(src, _end, buffer_u8, _keep);
		return _text;
	};
	
	#region jsDoc
	/// @func    __lineOf(_offset)
	/// @desc    The source line of a byte offset (clamped to the file).
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Real} _offset : Byte offset
	/// @returns {Real}
	#endregion
	static __lineOf = function(_offset) {
		return file.lineOf(clamp(_offset, 0, src_length));
	};
	
	#region jsDoc
	/// @func    __blankBetween(_from, _to)
	/// @desc    Whether an empty line lies between two source offsets.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Real} _from : Byte offset
	/// @param   {Real} _to   : Byte offset
	/// @returns {Bool}
	#endregion
	static __blankBetween = function(_from, _to) {
		if (_from < 0) || (_to <= _from) return false;
		var _a = __lineOf(_from);
		var _b = __lineOf(_to);
		var _starts = file.line_starts;
		var _l = _a + 1; repeat (max(0, _b - _a - 1)) {
			var _p = _starts[_l - 1];
			var _end = (_l < array_length(_starts)) ? _starts[_l] - 1 : src_length;
			while (_p < _end) {
				var _c = buffer_peek(src, _p, buffer_u8);
				if (_c != 32) && (_c != 9) break;
				_p++;
			}
			if (_p >= _end) return true;
		_l++}
		return false;
	};
	
	#region jsDoc
	/// @func    __breakBetween(_from, _to)
	/// @desc    Whether two source offsets are on different lines.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Real} _from : Byte offset
	/// @param   {Real} _to   : Byte offset
	/// @returns {Bool}
	#endregion
	static __breakBetween = function(_from, _to) {
		if (_from < 0) || (_to < _from) return false;
		return __lineOf(_from) < __lineOf(_to);
	};
	#endregion
	
	#region Pieces copied from the source
	#region jsDoc
	/// @func    __collectPieces(_ast, _program)
	/// @desc    Gathers what is copied from the source (comments, macro lines, enums, regions, pragma calls)
	///          in source order; a piece inside another one is dropped.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTScript} _ast     : The tree
	/// @param   {Struct}           _program : The file's program record
	#endregion
	static __collectPieces = function(_ast, _program) {
		pieces = [];
		piece = 0;
		var _comments = _program[$ "comments"] ?? [];
		var _i = 0; repeat (array_length(_comments)) {
			array_push(pieces, { start: _comments[_i].start, stop: _comments[_i][$ "end"], comment: true });
		_i++}
		_i = 0; repeat (array_length(_ast.macros)) {
			// a macro is the rest of its line: a comment after its value is part of it
			var _span = _ast.macros[_i].span;
			var _line = __lineOf(max(_span.start, _span[$ "end"] - 1));
			var _stop = (_line < array_length(file.line_starts)) ? file.line_starts[_line] - 1 : src_length;
			array_push(pieces, { start: _span.start, stop: max(_stop, _span[$ "end"]), comment: false });
		_i++}
		// with a language extension on, enum values may use what only the extension knows: write them as numbers
		var _values = (array_length(env.extensions) > 0);
		_i = 0; repeat (array_length(_ast.enums)) {
			var _span = _ast.enums[_i].span;
			array_push(pieces, { start: _span.start, stop: _span[$ "end"], comment: false, node: _values ? _ast.enums[_i] : undefined });
		_i++}
		_i = 0; repeat (array_length(_ast.regions)) {
			var _span = _ast.regions[_i].span;
			array_push(pieces, { start: _span.start, stop: _span[$ "end"], comment: false });
		_i++}
		_i = 0; repeat (array_length(_ast.pragmas)) {
			// a `/// @NoOp` comment is already among the comments
			var _span = _ast.pragmas[_i].span;
			if (buffer_peek(src, _span.start, buffer_u8) != ord("/")) {
				array_push(pieces, { start: _span.start, stop: _span[$ "end"], comment: false, pragma: true });
			}
		_i++}
		array_sort(pieces, function(_a, _b) { return _a.start - _b.start; });
		// a piece inside another one (a comment on a macro line) is written with it
		var _kept = [];
		var _stop = -1;
		_i = 0; repeat (array_length(pieces)) {
			if (pieces[_i].start >= _stop) {
				array_push(_kept, pieces[_i]);
				_stop = pieces[_i].stop;
			}
		_i++}
		pieces = _kept;
	};
	
	#region jsDoc
	/// @func    __writePieces(_limit)
	/// @desc    Writes the pieces that start before an offset: on the line before when the source has them on the
	///          same line, else each on a line of its own.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Real} _limit : Byte offset the pieces start before
	#endregion
	static __writePieces = function(_limit) {
		var _n = array_length(pieces);
		while (piece < _n) && (pieces[piece].start < _limit) {
			var _p = pieces[piece++];
			if (_p[$ "node"] != undefined) {
				__anchorAt(_p.start, true);
				if (can_blank) && __blankBetween(last_end, _p.start) __blankLine();
				__startLine();
				var _enum = _p.node;
				__write("enum " + _enum.name + " { ");
				var _m = 0; repeat (array_length(_enum.members)) {
					var _member = _enum.members[_m];
					if (_m > 0) __write(", ");
					__write(_member.name);
					if (_member.explicit) __write(" = " + string(_member.value));
				_m++}
				__write(" }");
				line_comment = true;
				last_end = max(last_end, _p.stop);
				can_blank = true;
				printed++;
				continue;
			}
			var _text = __sourceText(_p.start, _p.stop);
			// GameMaker refuses the pragma call
			if (_p[$ "pragma"] == true) _text = "/*" + _text + "*/";
			if (__preserve) {
				__anchorAt(_p.start, true);
				__pending_space = line_open;
				__writeAtLine(_text);
			}
			else if (_p.comment) && (line_open) && (!line_comment) && (last_end > 0) && (__lineOf(_p.start) == __lineOf(last_end - 1)) {
				buffer_write(out, buffer_text, " " + _text);
			}
			else {
				if (can_blank) && __blankBetween(last_end, _p.start) __blankLine();
				__startLine();
				buffer_write(out, buffer_text, _text);
			}
			// a `//` comment, a macro or a region ends its line (a pragma call too, unless lines are kept)
			if (__preserve) {
				line_comment = ((_p.comment) && (string_char_at(_text, 2) == "/")) || ((!_p.comment) && (string_char_at(_text, 1) == "#"));
			}
			else {
				line_comment = !_p.comment || (string_char_at(_text, 2) == "/");
			}
			__unclosed = (_p.comment) && (string_char_at(_text, 2) == "*") && ((string_length(_text) < 4) || (string_copy(_text, string_length(_text) - 1, 2) != "*/"));
			last_end = max(last_end, _p.stop);
			can_blank = true;
			printed++;
		}
	};
	#endregion
	
	#region Macro uses
	#region jsDoc
	/// @func    __collectRuns(_tokens, _ast)
	/// @desc    Records the tokens each macro use expanded to, and counts how many nodes of the tree came
	///          from each use.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Array<Struct>}    _tokens : The file's tokens after preprocessing
	/// @param   {Struct.ASTScript} _ast    : The tree
	#endregion
	static __collectRuns = function(_tokens, _ast) {
		__runs = {};
		__has_runs = false;
		__tokens = _tokens;
		var _n = array_length(_tokens);
		var _run = undefined;
		var _at = -1;
		var _i = 0; repeat (_n) {
			var _origin = _tokens[_i][$ "origin"];
			var _use = ((_origin != undefined) && (_origin.kind == "macro")) ? _origin.use_span.start : -1;
			if (_use != _at) {
				if (_run != undefined) _run.next = _i;
				_run = undefined;
				_at = _use;
				if (_use >= 0) {
					_run = { first: _i, last: _i, next: _n, stop: _origin.use_span[$ "end"], file: _origin.use_span.file };
					__runs[$ string(_use)] = _run;
					__has_runs = true;
				}
			}
			else if (_run != undefined) {
				_run.last = _i;
			}
		_i++}
		__counts = {};
		if (!__has_runs) return;
		var _stack = [_ast];
		while (array_length(_stack) > 0) {
			var _node = array_pop(_stack);
			var _origin = _node.origin;
			if (_origin != undefined) && (_origin.kind == "macro") {
				var _key = string(_origin.use_span.start);
				__counts[$ _key] = (__counts[$ _key] ?? 0) + 1;
			}
			var _children = _node.children();
			array_copy(_stack, array_length(_stack), _children, 0, array_length(_children));
		}
	};
	
	#region jsDoc
	/// @func    __useOf(_node)
	/// @desc    The offset of the macro use a node's first token came from, or -1: only single-token nodes have an
	///          origin, and the first of them down the first children holds the node's first token.
	/// @self    GMLC_Gen_6_Emitter
	/// @returns {Real}
	#endregion
	static __useOf = function(_node) {
		while (true) {
			var _origin = _node.origin;
			if (_origin != undefined) return (_origin.kind == "macro") ? _origin.use_span.start : -1;
			var _children = _node.children();
			if (array_length(_children) == 0) return -1;
			_node = _children[0];
		}
	};
	
	#region jsDoc
	/// @func    __countFrom(_node, _use)
	/// @desc    How many nodes of a subtree came from the macro use at _use, or -1 when one came from elsewhere; a
	///          node with no origin of its own is made of its children's tokens, unless it has none.
	/// @self    GMLC_Gen_6_Emitter
	/// @returns {Real}
	#endregion
	static __countFrom = function(_node, _use) {
		var _origin = _node.origin;
		var _children = _node.children();
		var _count = 0;
		if (_origin != undefined) {
			if (_origin.kind != "macro") || (_origin.use_span.start != _use) return -1;
			_count = 1;
		}
		else if (array_length(_children) == 0) {
			return -1;
		}
		var _i = 0; repeat (array_length(_children)) {
			var _c = __countFrom(_children[_i], _use);
			if (_c < 0) return -1;
			_count += _c;
		_i++}
		return _count;
	};
	
	#region jsDoc
	/// @func    __macroUse(_node, _expr, _statement)
	/// @desc    Whether a node is the whole of a macro use, so the use can be written in its place: the expression
	///          spans exactly the use, every node the use became is in the subtree and nothing else is, and the use
	///          takes no arguments.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _node      : An expression, or the statement that holds one
	/// @param   {Struct.ASTNode} _expr      : The expression
	/// @param   {Bool}           _statement : Whether _node is the statement
	/// @returns {Real} 0 when not, 1 when it is, 2 when it is and its tokens end with a semicolon
	#endregion
	static __macroUse = function(_node, _expr, _statement) {
		if (!__has_runs) return 0;
		var _use = __useOf(_node);
		if (_use < 0) return 0;
		var _run = __runs[$ string(_use)];
		if (_run == undefined) || (_run.file != file.file_id) return 0;
		if (_expr.span.start != _use) || (_expr.span[$ "end"] != _run.stop) return 0;
		var _first = _run.first;
		var _last = _run.last;
		var _semicolon = false;
		if (_statement) {
			while (_last >= _first) && (__tokenText(_last) == ";") {
				_last--;
				_semicolon = true;
			}
		}
		if (_last < _first) || !__balanced(_first, _last) return 0;
		var _parens = false;
		while (_last > _first) && (__tokenText(_first) == "(") && (__tokenText(_last) == ")") && __balanced(_first + 1, _last - 1) {
			_first++;
			_last--;
			_parens = true;
		}
		if (__tokenText(_first) != __firstText(_expr)) || (__tokenText(_last) != __lastText(_expr)) return 0;
		// a use with arguments: the `(` after the name is part of the use
		var _p = _run.stop;
		while (_p < src_length) {
			var _b = buffer_peek(src, _p, buffer_u8);
			if (_b != 32) && (_b != 9) break;
			_p++;
		}
		if (_p < src_length) && (buffer_peek(src, _p, buffer_u8) == ord("(")) {
			if (_run.next >= array_length(__tokens)) || (__tokens[_run.next].start != _p) return 0;
		}
		if (__countFrom(_node, _use) != (__counts[$ string(_use)] ?? 0)) return 0;
		__use_parentheses = _parens;
		return _semicolon ? 2 : 1;
	};
	
	#region jsDoc
	/// @func    __macroName(_node)
	/// @desc    The source text of the macro use a node is the whole of, or undefined.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _node : An expression
	/// @returns {String|Undefined}
	#endregion
	static __macroName = function(_node) {
		if (!__has_runs) || (__macroUse(_node, _node, false) == 0) return undefined;
		var _use = __useOf(_node);
		return __sourceText(_use, __runs[$ string(_use)].stop);
	};
	
	#region jsDoc
	/// @func    __tokenText(_i)
	/// @desc    The text of a token of the file.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Real} _i : Token index
	/// @returns {String}
	#endregion
	static __tokenText = function(_i) {
		return __tokens[_i].name;
	};
	
	#region jsDoc
	/// @func    __balanced(_first, _last)
	/// @desc    Whether the brackets of a run of tokens open and close in pairs.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Real} _first : First token index
	/// @param   {Real} _last  : Last token index
	/// @returns {Bool}
	#endregion
	static __balanced = function(_first, _last) {
		var _open = [];
		var _i = _first; repeat (_last - _first + 1) {
			var _t = __tokens[_i];
			if (_t.kind == __GMLC_TokenKind_Op) {
				switch (_t.value) {
					case "(": case "[": case "{": array_push(_open, _t.value); break;
					case "[@": case "[|": case "[?": case "[#": case "[$": array_push(_open, "["); break;
					case ")": if (array_length(_open) == 0) || (array_pop(_open) != "(") return false; break;
					case "]": if (array_length(_open) == 0) || (array_pop(_open) != "[") return false; break;
					case "}": if (array_length(_open) == 0) || (array_pop(_open) != "{") return false; break;
				}
			}
		_i++}
		return (array_length(_open) == 0);
	};
	
	#region jsDoc
	/// @func    __firstText(_node)
	/// @desc    The text of an expression's first token, or undefined for a kind it does not know.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _node : An expression
	/// @returns {String|Undefined}
	#endregion
	static __firstText = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: return _node.lexeme;
			case __GMLC_NodeKind_Identifier: return _node.name;
			case __GMLC_NodeKind_Index: return __firstText(_node.object);
			case __GMLC_NodeKind_Call: return __firstText(_node.callee);
			case __GMLC_NodeKind_MethodCall: return __firstText(_node.object);
			case __GMLC_NodeKind_New: return "new";
			case __GMLC_NodeKind_Binary: case __GMLC_NodeKind_Logical: case __GMLC_NodeKind_Nullish: return __firstText(_node.left);
			case __GMLC_NodeKind_Unary: return _node.op;
			case __GMLC_NodeKind_Update: return _node.prefix ? _node.op : __firstText(_node.argument);
			case __GMLC_NodeKind_Conditional: return __firstText(_node.test);
			case __GMLC_NodeKind_Assign: return __firstText(_node.target);
			case __GMLC_NodeKind_ArrayLiteral: return "[";
			case __GMLC_NodeKind_StructLiteral: return "{";
			case __GMLC_NodeKind_FunctionExpr: return "function";
			case __GMLC_NodeKind_Nameof: return "nameof";
			case __GMLC_NodeKind_TemplateString: return "$\"";
		}
		return undefined;
	};
	
	#region jsDoc
	/// @func    __lastText(_node)
	/// @desc    The text of an expression's last token, or undefined for a kind it does not know.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _node : An expression
	/// @returns {String|Undefined}
	#endregion
	static __lastText = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: return _node.lexeme;
			case __GMLC_NodeKind_Identifier: return _node.name;
			case __GMLC_NodeKind_Index: return (_node.accessor == "Dot") ? _node.member : "]";
			case __GMLC_NodeKind_Call: case __GMLC_NodeKind_MethodCall: case __GMLC_NodeKind_New: case __GMLC_NodeKind_Nameof: return ")";
			case __GMLC_NodeKind_Binary: case __GMLC_NodeKind_Logical: case __GMLC_NodeKind_Nullish: return __lastText(_node.right);
			case __GMLC_NodeKind_Unary: return __lastText(_node.argument);
			case __GMLC_NodeKind_Update: return _node.prefix ? __lastText(_node.argument) : _node.op;
			case __GMLC_NodeKind_Conditional: return __lastText(_node.alternate);
			case __GMLC_NodeKind_Assign: return __lastText(_node.value);
			case __GMLC_NodeKind_ArrayLiteral: return "]";
			case __GMLC_NodeKind_StructLiteral: case __GMLC_NodeKind_FunctionExpr: return "}";
		}
		return undefined;
	};
	#endregion
	
	#region Lines
	#region jsDoc
	/// @func    __indentText(_level)
	/// @desc    The indentation text of a nesting level.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Real} _level : Nesting level
	/// @returns {String}
	#endregion
	static __indentText = function(_level) {
		while (array_length(__indents) <= _level) {
			array_push(__indents, __indents[array_length(__indents) - 1] + indentUnit);
		}
		return __indents[_level];
	};
	
	#region jsDoc
	/// @func    __startLine()
	/// @desc    Starts a new output line at the current indentation; with preserve_lines it only notes that
	///          the next text needs a space.
	/// @self    GMLC_Gen_6_Emitter
	#endregion
	static __startLine = function() {
		if (__preserve) {
			// the next text goes on its own line only when the source has it there
			__pending_space = line_open;
			return;
		}
		if (line_open) buffer_write(out, buffer_text, "\n");
		buffer_write(out, buffer_text, __indentText(indent));
		line_open = true;
		line_comment = false;
	};
	
	#region jsDoc
	/// @func    __blankLine()
	/// @desc    Writes an empty line (nothing with preserve_lines).
	/// @self    GMLC_Gen_6_Emitter
	#endregion
	static __blankLine = function() {
		if (__preserve) return;
		if (line_open) buffer_write(out, buffer_text, "\n");
		buffer_write(out, buffer_text, "\n");
		line_open = false;
		line_comment = false;
	};
	
	#region jsDoc
	/// @func    __write(_text)
	/// @desc    Writes text, on a new line when the last text written ends its line.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {String} _text : The text
	#endregion
	static __write = function(_text) {
		if (__preserve) {
			__writeAtLine(_text);
			__unclosed = false;
			return;
		}
		if (line_comment) __startLine();
		buffer_write(out, buffer_text, _text);
		__unclosed = false;
	};
	
	#region jsDoc
	/// @func    __anchorAt(_offset, _node)
	/// @desc    With preserve_lines, the next text belongs on the line of a source offset; a node whose line is
	///          already behind the output cannot keep it (the emit falls back to the source).
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Real} _offset : Byte offset
	/// @param   {Bool} _node   : False for a closing bracket, whose line may be behind the output
	#endregion
	static __anchorAt = function(_offset, _node) {
		if (!__preserve) return;
		var _line = __lineOf(_offset);
		if (_node) && (_line < __out_line) && (_offset > 0) __moved = true;
		__anchor = _line;
	};
	
	#region jsDoc
	/// @func    __writeAtLine(_text)
	/// @desc    With preserve_lines, writes text on its source line, adding line breaks to reach it.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {String} _text : The text
	#endregion
	static __writeAtLine = function(_text) {
		if (line_comment) && (__anchor <= __out_line) {
			__anchor = __out_line + 1;
			__moved = true;
		}
		var _at = buffer_tell(out);
		if (__anchor > __out_line) {
			while (_at > 0) && (buffer_peek(out, _at - 1, buffer_u8) == 32) _at--;
			buffer_seek(out, buffer_seek_start, _at);
			repeat (__anchor - __out_line) buffer_write(out, buffer_u8, 10);
			__out_line = __anchor;
			buffer_write(out, buffer_text, __indentText(indent));
		}
		else if (__pending_space) && (_at > 0) {
			var _last = buffer_peek(out, _at - 1, buffer_u8);
			if (_last != 32) && (_last != 10) buffer_write(out, buffer_u8, 32);
		}
		__pending_space = false;
		line_comment = false;
		line_open = true;
		buffer_write(out, buffer_text, _text);
		__out_line += string_count("\n", _text);
	};
	#endregion
	
	#region Statements
	#region jsDoc
	/// @func    __writeStatements(_body)
	/// @desc    Writes a list of statements with the source pieces between them and the source's empty lines.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Array<Struct.ASTNode>} _body : The statements
	#endregion
	static __writeStatements = function(_body) {
		var _i = 0; repeat (array_length(_body)) {
			var _s = _body[_i];
			if (_s.kind == __GMLC_NodeKind_Empty) && (_i > 0) && (line_open) {
				__write(string_repeat(";", __absorb + 1));
				__absorb = 0;
				last_end = max(last_end, _s.span[$ "end"]);
				_i++;
				continue;
			}
			__writePieces(_s.span.start);
			if (can_blank) && __blankBetween(last_end, _s.span.start) __blankLine();
			__startLine();
			__anchorAt(_s.span.start, true);
			__absorb = __writeStatement(_s);
			last_end = max(last_end, _s.span[$ "end"]);
			can_blank = true;
			printed++;
			// pieces inside the statement that were not written in it
			__writePieces(_s.span[$ "end"]);
		_i++}
	};
	
	#region jsDoc
	/// @func    __writeBlock(_block)
	/// @desc    Writes a block in braces with its statements indented.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _block : A Block node
	#endregion
	static __writeBlock = function(_block) {
		__write("{");
		var _before = printed;
		last_end = _block.span.start + 1;
		can_blank = false;
		indent++;
		__writeStatements(_block.body);
		__writePieces(_block.span[$ "end"]);
		indent--;
		if (printed != _before) __startLine();
		__anchorAt(_block.span[$ "end"] - 1, false);
		__write("}");
		last_end = max(last_end, _block.span[$ "end"]);
	};
	
	#region jsDoc
	/// @func    __writeStatement(_s)
	/// @desc    Writes a statement. The parser takes one `;` right after it as its own for each statement that ends
	///          at its last `}` (a block, the `if`, loop or `try` whose body it is, every `if` of an `else if`).
	/// @self    GMLC_Gen_6_Emitter
	/// @returns {Real} How many `;` right after it the parser takes as its own
	#endregion
	static __writeStatement = function(_s) {
		switch (_s.kind) {
			case __GMLC_NodeKind_ExprStmt: {
				var _use = __macroUse(_s, _s.expression, true);
				if (_use == 0) _use = __macroUse(_s.expression, _s.expression, false);
				if (_use > 0) {
					var _at = __useOf(_s);
					__write(__sourceText(_at, __runs[$ string(_at)].stop) + ((_use == 2) ? "" : ";"));
					break;
				}
				// a `gml_pragma("@NoOp")` call GMLC did not take as the pragma stays a call: parentheses keep GameMaker from
				// reading it as one
				var _e = _s.expression;
				if (_e.kind == __GMLC_NodeKind_Call) && (_e.callee.kind == __GMLC_NodeKind_Identifier) && (_e.callee.name == "gml_pragma") {
					__write("(gml_pragma)");
					__writeItems(_e.args, _e.callee.span[$ "end"], _e.span[$ "end"] - 1, "(", ")", false);
					__write(";");
					break;
				}
				__writeExpression(_e);
				__write(";");
			break;}
			case __GMLC_NodeKind_VarDeclList: {
				// `var` before a keyword declares nothing; a semicolon after it would be an error
				if (array_length(_s.declarations) == 0) {
					__write("var");
					return 1;
				}
				__write("var ");
				__declarations(_s.declarations);
				__write(";");
			break;}
			case __GMLC_NodeKind_StaticDecl: {
				__write("static ");
				__declarations(_s.declarations);
				__write(";");
			break;}
			case __GMLC_NodeKind_GlobalVarDecl: {
				__write("globalvar ");
				var _i = 0; repeat (array_length(_s.names)) {
					if (_i > 0) __write(", ");
					__write(_s.names[_i].name);
				_i++}
				__write(";");
			break;}
			case __GMLC_NodeKind_FunctionDecl: {
				__write("function " + _s.name);
				__params(_s.params);
				__write(" ");
				__writeBlock(_s.body);
			return 1;}
			case __GMLC_NodeKind_ConstructorDecl: {
				__write("function " + _s.name);
				__params(_s.params);
				if (_s.parent != undefined) {
					__write(" : ");
					__writeExpression(_s.parent);
				}
				__write(" constructor ");
				__writeBlock(_s.body);
			return 1;}
			case __GMLC_NodeKind_Block: {
				__writeBlock(_s);
			return 1;}
			case __GMLC_NodeKind_If: {
				__write("if (");
				__writeExpression(_s.test);
				__write(") ");
				__writeBlock(_s.consequent);
				var _ifs = 1;
				var _else = _s.alternate;
				while (_else != undefined) {
					__write(" else ");
					// `else if` when the block holds one if and no piece of the source before or after it
					if (array_length(_else.body) == 1) && (_else.body[0].kind == __GMLC_NodeKind_If) && !__piecesIn(_else.span.start, _else.body[0].span.start) && !__piecesIn(_else.body[0].span[$ "end"], _else.span[$ "end"]) {
						var _inner = _else.body[0];
						__write("if (");
						__writeExpression(_inner.test);
						__write(") ");
						__writeBlock(_inner.consequent);
						_else = _inner.alternate;
						_ifs++;
					}
					else {
						__writeBlock(_else);
						_else = undefined;
					}
				}
			return 1 + _ifs;}
			case __GMLC_NodeKind_For: {
				__write("for (");
				if (_s.init != undefined) {
					if (_s.init.kind == __GMLC_NodeKind_VarDeclList) {
						__write("var ");
						__declarations(_s.init.declarations);
					}
					else {
						__writeExpression(_s.init.expression);
					}
				}
				__write(";");
				if (_s.test != undefined) {
					__write(" ");
					__writeExpression(_s.test);
				}
				__write(";");
				if (_s.update != undefined) {
					__write(" ");
					if (_s.update.kind == __GMLC_NodeKind_Block) {
						__write("{");
						var _i = 0; repeat (array_length(_s.update.body)) {
							__write(" ");
							__writeStatement(_s.update.body[_i]);
						_i++}
						__write((array_length(_s.update.body) > 0) ? " }" : "}");
					}
					else {
						__writeExpression(_s.update.expression);
					}
				}
				__write(") ");
				__writeBlock(_s.body);
			return 2;}
			case __GMLC_NodeKind_While: {
				__write("while (");
				__writeExpression(_s.test);
				__write(") ");
				__writeBlock(_s.body);
			return 2;}
			case __GMLC_NodeKind_Repeat: {
				__write("repeat (");
				__writeExpression(_s.count);
				__write(") ");
				__writeBlock(_s.body);
			return 2;}
			case __GMLC_NodeKind_With: {
				__write("with (");
				__writeExpression(_s.target);
				__write(") ");
				__writeBlock(_s.body);
			return 2;}
			case __GMLC_NodeKind_DoUntil: {
				__write("do ");
				__writeBlock(_s.body);
				__write(" until (");
				__writeExpression(_s.test);
				__write(");");
			break;}
			case __GMLC_NodeKind_Switch: {
				__write("switch (");
				__writeExpression(_s.discriminant);
				__write(") {");
				var _before = printed;
				last_end = _s.discriminant.span[$ "end"] + 1;
				can_blank = false;
				indent++;
				var _i = 0; repeat (array_length(_s.cases)) {
					var _case = _s.cases[_i];
					__writePieces(_case.span.start);
					if (can_blank) && __blankBetween(last_end, _case.span.start) __blankLine();
					__startLine();
					__anchorAt(_case.span.start, true);
					if (_case.kind == __GMLC_NodeKind_Case) {
						__write("case ");
						__writeExpression(_case.test);
						__write(":");
						last_end = _case.test.span[$ "end"] + 1;
					}
					else {
						__write("default:");
						last_end = _case.span.start + 8;
					}
					printed++;
					can_blank = false;
					var _body = _case.body;
					if (array_length(_body) == 1) && (_body[0].kind == __GMLC_NodeKind_Block) && !__piecesIn(last_end, _body[0].span.start) {
						__write(" ");
						__writeBlock(_body[0]);
						last_end = max(last_end, _body[0].span[$ "end"]);
						__writePieces(_case.span[$ "end"]);
					}
					else {
						indent++;
						__writeStatements(_body);
						indent--;
					}
					can_blank = true;
				_i++}
				__writePieces(_s.span[$ "end"]);
				indent--;
				if (printed != _before) __startLine();
				__anchorAt(_s.span[$ "end"] - 1, false);
				__write("}");
			return 1;}
			case __GMLC_NodeKind_Try: {
				__write("try ");
				__writeBlock(_s.block);
				if (_s.catch_body != undefined) {
					__write(" catch (" + ((_s.catch_param != undefined) ? _s.catch_param.name : "") + ") ");
					__writeBlock(_s.catch_body);
				}
				if (_s.finally_body != undefined) {
					__write(" finally ");
					__writeBlock(_s.finally_body);
				}
			return 2;}
			case __GMLC_NodeKind_Return: {
				if (_s.argument == undefined) {
					__write("return;");
					break;
				}
				__write("return ");
				__writeExpression(_s.argument);
				__write(";");
			break;}
			case __GMLC_NodeKind_Throw: {
				__write("throw ");
				__writeExpression(_s.argument);
				__write(";");
			break;}
			case __GMLC_NodeKind_Delete: {
				__write("delete ");
				__writeExpression(_s.target);
				__write(";");
			break;}
			case __GMLC_NodeKind_Break: __write("break;"); break;
			case __GMLC_NodeKind_Continue: __write("continue;"); break;
			case __GMLC_NodeKind_Exit: __write("exit;"); break;
			case __GMLC_NodeKind_Empty: __write(";"); break;
			default:
				throw "GMLC_Gen_6_Emitter: no form for a " + _s.kindName + " statement";
		}
		return 0;
	};
	
	#region jsDoc
	/// @func    __piecesIn(_from, _to)
	/// @desc    Whether a source piece not written yet starts between two offsets.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Real} _from : Byte offset
	/// @param   {Real} _to   : Byte offset
	/// @returns {Bool}
	#endregion
	static __piecesIn = function(_from, _to) {
		var _i = piece; repeat (array_length(pieces) - piece) {
			var _start = pieces[_i].start;
			if (_start >= _to) return false;
			if (_start >= _from) return true;
		_i++}
		return false;
	};
	
	#region jsDoc
	/// @func    __declarations(_list)
	/// @desc    Writes the declarations of a `var` or `static` statement, separated by commas.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Array<Struct.ASTNode>} _list : The declarations
	#endregion
	static __declarations = function(_list) {
		var _i = 0; repeat (array_length(_list)) {
			if (_i > 0) __write(", ");
			var _d = _list[_i];
			__write(_d.target.name);
			if (_d.init != undefined) {
				__write(" = ");
				__writeExpression(_d.init);
			}
		_i++}
	};
	
	#region jsDoc
	/// @func    __params(_params)
	/// @desc    Writes a function's parameters and their defaults in parentheses.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Array<Struct.ASTNode>} _params : The parameters
	#endregion
	static __params = function(_params) {
		__write("(");
		var _i = 0; repeat (array_length(_params)) {
			if (_i > 0) __write(", ");
			__write(_params[_i].target.name);
			if (_params[_i][$ "default"] != undefined) {
				__write(" = ");
				__writeExpression(_params[_i][$ "default"]);
			}
		_i++}
		__write(")");
	};
	#endregion
	
	#region Expressions
	#region jsDoc
	/// @func    __isChain(_node)
	/// @desc    Whether a node is an identifier, call or index, which `.`, `(` or `[` can follow as it is.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _node : An expression
	/// @returns {Bool}
	#endregion
	static __isChain = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier: case __GMLC_NodeKind_Call: case __GMLC_NodeKind_MethodCall:
			case __GMLC_NodeKind_Index:
				return true;
		}
		return false;
	};
	
	#region jsDoc
	/// @func    __operand(_node, _parentGroup, _right)
	/// @desc    Writes an operand of a binary, nullish or conditional expression: in parentheses when its
	///          operator differs from the parent's, it is a right operand, or the parent is a conditional.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _node        : The operand
	/// @param   {String}         _parentGroup : The parent's operator (`??` or `?:` for those)
	/// @param   {Bool}           _right       : Whether it is the right operand
	#endregion
	static __operand = function(_node, _parentGroup, _right) {
		var _group = undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Binary: case __GMLC_NodeKind_Logical: _group = _node.op; break;
			case __GMLC_NodeKind_Nullish: _group = "??"; break;
			case __GMLC_NodeKind_Conditional: _group = "?:"; break;
		}
		__wrapped(_node, (_group != undefined) && ((_group != _parentGroup) || _right || (_parentGroup == "?:")));
	};
	
	#region jsDoc
	/// @func    __wrapped(_node, _wrap)
	/// @desc    A node, in parentheses when _wrap is true; a macro use written as its name needs them too, unless
	///          its tokens have their own.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Bool}           _wrap : Whether to write parentheses
	#endregion
	static __wrapped = function(_node, _wrap) {
		var _name = __macroName(_node);
		if (_name != undefined) {
			__write((_wrap && !__use_parentheses) ? "(" + _name + ")" : _name);
			return;
		}
		if (_wrap) __write("(");
		__writeExpression(_node);
		if (_wrap) __write(")");
	};
	
	#region jsDoc
	/// @func    __unaryOperand(_node)
	/// @desc    Writes the operand of a unary or update operator, in parentheses unless it is a single item.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _node : The operand
	#endregion
	static __unaryOperand = function(_node) {
		var _atom = false;
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier: case __GMLC_NodeKind_Call: case __GMLC_NodeKind_MethodCall:
			case __GMLC_NodeKind_Index: case __GMLC_NodeKind_ArrayLiteral: case __GMLC_NodeKind_StructLiteral:
			case __GMLC_NodeKind_TemplateString: case __GMLC_NodeKind_Nameof:
				_atom = true;
			break;
			case __GMLC_NodeKind_Literal:
				_atom = (string_char_at(_node.lexeme, 1) != "-") || (_node.origin != undefined);
			break;
		}
		__wrapped(_node, !_atom);
	};
	
	#region jsDoc
	/// @func    __chainObject(_node)
	/// @desc    Writes the object before `.` or `[`, in parentheses unless it is a chain.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _node : The object
	#endregion
	static __chainObject = function(_node) {
		__wrapped(_node, !__isChain(_node));
	};
	
	#region jsDoc
	/// @func    __writeExpression(_node)
	/// @desc    Writes an expression; a macro use as the macro's name and an enum value as `Enum.Member`.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _node : The expression
	#endregion
	static __writeExpression = function(_node) {
		__anchorAt(_node.span.start, true);
		if (__has_runs) {
			var _name = __macroName(_node);
			if (_name != undefined) {
				__write(_name);
				return;
			}
		}
		var _origin = _node.origin;
		if (_origin != undefined) {
			switch (_origin.kind) {
				case "enum":
					if (_node.kind == __GMLC_NodeKind_Literal) {
						__write(_origin.name + "." + _origin.member);
						return;
					}
					break;
				case "compile_time":
					// `_GMLINE_` keeps the line it had; GameMaker gives the other names their values
					if (_node.kind == __GMLC_NodeKind_Literal) && (_origin.name != "_GMLINE_") {
						__write(_origin.name);
						return;
					}
					break;
			}
		}
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: __writeLiteral(_node); break;
			case __GMLC_NodeKind_Identifier: __write(_node.name); break;
			case __GMLC_NodeKind_Binary: case __GMLC_NodeKind_Logical: {
				__operand(_node.left, _node.op, false);
				__write(" " + _node.op + " ");
				__operand(_node.right, _node.op, true);
			break;}
			case __GMLC_NodeKind_Nullish: {
				__operand(_node.left, "??", false);
				__write(" ?? ");
				__operand(_node.right, "??", true);
			break;}
			case __GMLC_NodeKind_Conditional: {
				__operand(_node.test, "?:", false);
				__write(" ? ");
				__operand(_node.consequent, "?:", false);
				__write(" : ");
				__operand(_node.alternate, "?:", false);
			break;}
			case __GMLC_NodeKind_Assign: {
				__writeExpression(_node.target);
				__write(" " + _node.op + " ");
				__writeExpression(_node.value);
			break;}
			case __GMLC_NodeKind_Unary: {
				__write(_node.op);
				__unaryOperand(_node.argument);
			break;}
			case __GMLC_NodeKind_Update: {
				if (_node.prefix) {
					__write(_node.op);
					__unaryOperand(_node.argument);
				}
				else {
					__unaryOperand(_node.argument);
					__write(_node.op);
				}
			break;}
			case __GMLC_NodeKind_Call: {
				// `(a.b)(c)`: without the parentheses it is a method call
				var _callee = _node.callee;
				__wrapped(_callee, !__isChain(_callee) || ((_callee.kind == __GMLC_NodeKind_Index) && (_callee.accessor == "Dot")));
				__writeItems(_node.args, _callee.span[$ "end"], _node.span[$ "end"] - 1, "(", ")", false);
			break;}
			case __GMLC_NodeKind_MethodCall: {
				__chainObject(_node.object);
				__write("." + _node.member);
				__writeItems(_node.args, _node.object.span[$ "end"], _node.span[$ "end"] - 1, "(", ")", false);
			break;}
			case __GMLC_NodeKind_New: {
				__write("new ");
				var _callee = _node.callee;
				while (_callee.kind == __GMLC_NodeKind_Index) _callee = _callee.object;
				__wrapped(_node.callee, _callee.kind != __GMLC_NodeKind_Identifier);
				__writeItems(_node.args, _node.callee.span[$ "end"], _node.span[$ "end"] - 1, "(", ")", false);
			break;}
			case __GMLC_NodeKind_Index: {
				__chainObject(_node.object);
				if (_node.accessor == "Dot") {
					__write("." + _node.member);
					break;
				}
				__write(__opener(_node));
				var _i = 0; repeat (array_length(_node.keys)) {
					if (_i > 0) __write(", ");
					__writeExpression(_node.keys[_i]);
				_i++}
				__write("]");
			break;}
			case __GMLC_NodeKind_ArrayLiteral: {
				var _open = (array_length(_node.elements) > 0) && __joinsBracket(_node.elements[0]) ? "[ " : "[";
				__writeItems(_node.elements, _node.span.start + 1, _node.span[$ "end"] - 1, _open, "]", false);
			break;}
			case __GMLC_NodeKind_StructLiteral: {
				__writeItems(_node.entries, _node.span.start + 1, _node.span[$ "end"] - 1, "{", "}", true);
			break;}
			case __GMLC_NodeKind_TemplateString: {
				__write("$\"");
				var _i = 0; repeat (array_length(_node.strings)) {
					__write(__escape(_node.strings[_i], true));
					if (_i < array_length(_node.exprs)) {
						__write("{");
						__writeExpression(_node.exprs[_i]);
						__write("}");
					}
				_i++}
				__write("\"");
			break;}
			case __GMLC_NodeKind_FunctionExpr: {
				__write("function");
				// the resolver names an anonymous function GMLC@anon@N, which is not written
				if (_node.name != undefined) && !string_starts_with(_node.name, "GMLC@anon@") __write(" " + _node.name);
				__params(_node.params);
				if (_node.parent != undefined) {
					__write(" : ");
					__writeExpression(_node.parent);
				}
				if (_node.is_constructor) __write(" constructor");
				__write(" ");
				__writeBlock(_node.body);
			break;}
			case __GMLC_NodeKind_Nameof: __write("nameof(" + _node.name + ")"); break;
			case __GMLC_NodeKind_Empty: break;
			default:
				throw "GMLC_Gen_6_Emitter: no form for a " + _node.kindName + " expression";
		}
	};
	
	#region jsDoc
	/// @func    __opener(_node)
	/// @desc    The opening bracket of an index expression, with its accessor.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _node : An Index node
	/// @returns {String}
	#endregion
	static __opener = function(_node) {
		switch (_node.accessor) {
			case "ArrayAt": case "Array2DAt": return "[@ ";
			case "List": return "[| ";
			case "Map": return "[? ";
			case "Grid": return "[# ";
			case "Struct": return "[$ ";
		}
		return __joinsBracket(_node.keys[0]) ? "[ " : "[";
	};
	
	#region jsDoc
	/// @func    __joinsBracket(_node)
	/// @desc    Whether a node starts with `@`, `$`, `#`, `|` or `?`, which right after `[` would be read as an
	///          accessor.
	/// @self    GMLC_Gen_6_Emitter
	/// @returns {Bool}
	#endregion
	static __joinsBracket = function(_node) {
		var _first = __firstText(_node);
		if (_first == undefined) return false;
		var _c = string_char_at(_first, 1);
		return (_c == "@") || (_c == "$") || (_c == "#") || (_c == "|") || (_c == "?");
	};
	
	#region jsDoc
	/// @func    __writeItems(_items, _from, _close, _open, _closeText, _entries)
	/// @desc    A bracketed list: arguments, array elements or struct entries. Where the source breaks the line
	///          before an item or the closing bracket, the output does too. A hole at the end of the list keeps its
	///          comma.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Array<Struct.ASTNode>} _items     : The items
	/// @param   {Real}                  _from      : Source offset after the opening bracket
	/// @param   {Real}                  _close     : Source offset of the closing bracket
	/// @param   {String}                _open      : The opening bracket
	/// @param   {String}                _closeText : The closing bracket
	/// @param   {Bool}                  _entries   : Whether the items are struct entries
	#endregion
	static __writeItems = function(_items, _from, _close, _open, _closeText, _entries) {
		__write(_open);
		var _n = array_length(_items);
		var _prev = _from;
		var _broken = false;
		var _blank = can_blank;
		can_blank = false;
		var _i = 0; repeat (_n) {
			var _item = _items[_i];
			if (_i > 0) __write(",");
			var _start = _item.span.start;
			var _break = (_item.kind != __GMLC_NodeKind_Empty) && (_start >= _prev) && __breakBetween(_prev, _start)
				// an item written starting with `#` may not start a line
				&& !((_item.kind == __GMLC_NodeKind_Literal) && (string_char_at(_item.lexeme, 1) == "#"));
			if (_break) {
				if (!_broken) indent++;
				_broken = true;
				__writePieces(_start);
				__startLine();
			}
			else if (_i > 0) && (_item.kind != __GMLC_NodeKind_Empty) {
				__write(" ");
			}
			if (!_entries) {
				__writeExpression(_item);
			}
			else if (_item.shorthand) {
				__anchorAt(_item.span.start, true);
				__write(_item.key);
			}
			else {
				__anchorAt(_item.span.start, true);
				__write(_item.quoted ? "\"" + __escape(_item.key, false) + "\"" : _item.key);
				__write(": ");
				__writeExpression(_item.value);
			}
			if (_item.kind != __GMLC_NodeKind_Empty) {
				_prev = _item.span[$ "end"];
				last_end = max(last_end, _prev);
			}
		_i++}
		if (_n > 0) && (_items[_n - 1].kind == __GMLC_NodeKind_Empty) __write(",");
		if (_n > 0) && (_close >= _prev) && __breakBetween(_prev, _close) {
			if (!_broken) indent++;
			__writePieces(_close);
			indent--;
			_broken = false;
			__startLine();
		}
		if (_broken) indent--;
		can_blank = _blank;
		if (_n > 0) __anchorAt(_close, false);
		__write(_closeText);
	};
	
	#region jsDoc
	/// @func    __writeLiteral(_node)
	/// @desc    Writes a literal as its source text; a string without one is written quoted and escaped.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {Struct.ASTNode} _node : A Literal node
	#endregion
	static __writeLiteral = function(_node) {
		var _lexeme = _node.lexeme;
		switch (_node.ty) {
			case "string":
				// a folded string or one from a macro has no text of its own in the source
				if (__sourceText(_node.span.start, _node.span[$ "end"]) != _lexeme) {
					__write("\"" + __escape(_node.value, false) + "\"");
					return;
				}
				break;
		}
		__write(_lexeme);
	};
	
	#region jsDoc
	/// @func    __escape(_text, _template)
	/// @desc    Escapes text for a string literal, or for a template string.
	/// @self    GMLC_Gen_6_Emitter
	/// @param   {String} _text     : The text
	/// @param   {Bool}   _template : Whether `{` must be escaped too
	/// @returns {String}
	#endregion
	static __escape = function(_text, _template) {
		_text = string_replace_all(_text, "\\", "\\\\");
		_text = string_replace_all(_text, "\"", "\\\"");
		_text = string_replace_all(_text, "\n", "\\n");
		_text = string_replace_all(_text, "\r", "\\r");
		_text = string_replace_all(_text, "\t", "\\t");
		// other control characters as \x and two hex digits, so none is written raw
		var _c = 1; repeat (127) {
			if (_c < 32) || (_c == 127) {
				var _char = chr(_c);
				if (string_pos(_char, _text) > 0) _text = string_replace_all(_text, _char, "\\x" + string_copy("0123456789ABCDEF", (_c >> 4) + 1, 1) + string_copy("0123456789ABCDEF", (_c & 15) + 1, 1));
			}
		_c++}
		if (_template) _text = string_replace_all(_text, "{", "\\{");
		return _text;
	};
	#endregion
	#endregion
}
