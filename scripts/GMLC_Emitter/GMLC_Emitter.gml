#region Emitter.gml
	#region Emitter Module
	/*
	GML text from a lowered or optimized tree: what GameMaker compiles in place of the source. Every item is printed
	in one layout (4 spaces, braces on the header line, a semicolon after every simple statement), and parentheses
	are written wherever two different operators meet, so the text never depends on GameMaker's precedence.
	Comments, `#macro` lines, enum declarations, regions and `@NoOp` pragma calls are copied from the source as they
	are, in their place between the statements. A value that came from a macro is written as the macro's name when
	the whole expansion is one part of the tree; an enum value as `Enum.Member`.
	*/
	#endregion
	function GMLC_Emitter(_env) constructor {
		#region Config
		static indentUnit = "    ";
		#endregion

		env = _env;

		out = buffer_create(1 << 16, buffer_grow, 1); // the text being written
		src = buffer_create(1, buffer_grow, 1);       // the file's bytes, read in place
		file = undefined;    // the GMLC_SourceFile of the tree
		srcLength = 0;
		pieces = [];         // the parts copied from the source, in order: {start, end, comment}
		piece = 0;           // the next one to write
		indent = 0;
		lineOpen = false;    // whether the current output line has text
		lineComment = false; // whether that text ends with a `//` comment
		lastEnd = -1;        // the source offset after the last thing written, for comments on the same line
		canBlank = false;    // whether a blank line of the source may be kept before the next item
		printed = 0;         // statements and pieces written so far
		__indents = [""];
		__runs = {};         // the tokens of each macro use by the offset of the use: {first, last, next, stop}
		__counts = {};       // the nodes made only of what each macro use became, by the offset of the use
		__tokens = [];
		__unclosed = false;  // whether the last piece written is a block comment without its `*/`
		__hasRuns = false;   // whether the file has a macro use
		__absorb = 0;        // how many `;` right after the last statement written it takes as its own
		__useParens = false; // whether the tokens of the last macro use found whole are in parentheses of their own

		#region jsDoc
		/// @func    emit(_ast, _program)
		/// @desc    The GML text of one file's tree.
		/// @self    GMLC_Emitter
		/// @param   {Struct.ASTScript} _ast     : The lowered or optimized tree
		/// @param   {Struct}           _program : The file's program record after preprocessing (file, tokens,
		///                                        comments)
		/// @returns {String}
		#endregion
		static emit = function(_ast, _program) {
			file = _program.file;
			srcLength = string_byte_length(file.source);
			buffer_resize(src, srcLength + 1);
			buffer_seek(src, buffer_seek_start, 0);
			buffer_write(src, buffer_text, file.source);
			buffer_poke(src, srcLength, buffer_u8, 0);
			buffer_seek(out, buffer_seek_start, 0);
			indent = 0;
			lineOpen = false;
			lineComment = false;
			lastEnd = -1;
			canBlank = false;
			printed = 0;
			__unclosed = false;
			__absorb = 0;
			__collectPieces(_ast, _program);
			__collectRuns(_program.tokens);
			__countOrigins(_ast);

			__list(_ast.body);
			__flush(infinity);
			// a block comment that is never closed runs to the end of the file: a line break after it would join it
			if (lineOpen) && !__unclosed buffer_write(out, buffer_text, "\n");

			buffer_write(out, buffer_u8, 0);
			buffer_seek(out, buffer_seek_start, 0);
			var _text = buffer_read(out, buffer_string);
			__runs = {};
			__counts = {};
			__tokens = [];
			pieces = [];
			return _text;
		};
		#endregion

		#region Source
		// the source text between two byte offsets
		static __text = function(_start, _end) {
			if (_end <= _start) return "";
			var _keep = buffer_peek(src, _end, buffer_u8);
			buffer_poke(src, _end, buffer_u8, 0);
			buffer_seek(src, buffer_seek_start, _start);
			var _text = buffer_read(src, buffer_string);
			buffer_poke(src, _end, buffer_u8, _keep);
			return _text;
		};

		// the 1-based line of a byte offset
		static __line = function(_offset) {
			return file.lineOf(clamp(_offset, 0, srcLength));
		};

		// whether a line of the source holds only spaces and tabs
		static __isBlankLine = function(_line) {
			var _starts = file.lineStarts;
			var _p = _starts[_line - 1];
			var _end = (_line < array_length(_starts)) ? _starts[_line] - 1 : srcLength;
			while (_p < _end) {
				var _b = buffer_peek(src, _p, buffer_u8);
				if (_b != 32) && (_b != 9) return false;
				_p++;
			}
			return true;
		};

		// whether the source has a blank line between two offsets
		static __blankBetween = function(_from, _to) {
			if (_from < 0) || (_to <= _from) return false;
			var _a = __line(_from);
			var _b = __line(_to);
			var _l = _a + 1; repeat (max(0, _b - _a - 1)) {
				if (__isBlankLine(_l)) return true;
			_l++}
			return false;
		};

		// whether the source breaks the line between two offsets
		static __breakBetween = function(_from, _to) {
			if (_from < 0) || (_to < _from) return false;
			return __line(_from) < __line(_to);
		};
		#endregion

		#region Pieces copied from the source
		// the comments, macro lines, enum declarations, regions and pragma calls of the file, in order
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
				var _line = __line(max(_span.start, _span[$ "end"] - 1));
				var _stop = (_line < array_length(file.lineStarts)) ? file.lineStarts[_line] - 1 : srcLength;
				array_push(pieces, { start: _span.start, stop: max(_stop, _span[$ "end"]), comment: false });
			_i++}
			// with a language extension on, an enum's values may use what only the extension knows (a `const`, a
			// `let`, a macro with arguments): its values are written as numbers
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
				// a `gml_pragma("@NoOp")` call; a `/// @NoOp` comment is among the comments
				var _span = _ast.pragmas[_i].span;
				if (buffer_peek(src, _span.start, buffer_u8) != ord("/")) {
					array_push(pieces, { start: _span.start, stop: _span[$ "end"], comment: false });
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

		// an enum with its values as numbers: `enum E { A, B = 2 }`, where a member without a value of its own in the
		// source keeps none
		static __enumText = function(_enum) {
			__write("enum " + _enum.name + " { ");
			var _m = 0; repeat (array_length(_enum.members)) {
				var _member = _enum.members[_m];
				if (_m > 0) __write(", ");
				__write(_member.name);
				if (_member.explicit) __write(" = " + string(_member.value));
			_m++}
			__write(" }");
		};

		// writes the pieces that start before an offset: on the line before when the source has them on the same line,
		// else each on a line of its own
		static __flush = function(_limit) {
			var _n = array_length(pieces);
			while (piece < _n) && (pieces[piece].start < _limit) {
				var _p = pieces[piece++];
				if (_p[$ "node"] != undefined) {
					if (canBlank) && __blankBetween(lastEnd, _p.start) __blankLine();
					__startLine();
					__enumText(_p.node);
					lineComment = true;
					lastEnd = max(lastEnd, _p.stop);
					canBlank = true;
					printed++;
					continue;
				}
				var _text = __text(_p.start, _p.stop);
				if (_p.comment) && (lineOpen) && (!lineComment) && (lastEnd > 0) && (__line(_p.start) == __line(lastEnd - 1)) {
					buffer_write(out, buffer_text, " " + _text);
				}
				else {
					if (canBlank) && __blankBetween(lastEnd, _p.start) __blankLine();
					__startLine();
					buffer_write(out, buffer_text, _text);
				}
				// a `//` comment, a macro or a region ends its line
				lineComment = !_p.comment || (string_char_at(_text, 2) == "/");
				__unclosed = (_p.comment) && (string_char_at(_text, 2) == "*") && ((string_length(_text) < 4) || (string_copy(_text, string_length(_text) - 1, 2) != "*/"));
				lastEnd = max(lastEnd, _p.stop);
				canBlank = true;
				printed++;
			}
		};
		#endregion

		#region Macro uses
		// the runs of tokens each macro use became, by the offset of the use
		static __collectRuns = function(_tokens) {
			__runs = {};
			__hasRuns = false;
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
						__hasRuns = true;
					}
				}
				else if (_run != undefined) {
					_run.last = _i;
				}
			_i++}
		};

		// how many nodes came from each macro use, by the offset of the use
		static __countOrigins = function(_ast) {
			__counts = {};
			if (!__hasRuns) return;
			var _stack = [_ast];
			while (array_length(_stack) > 0) {
				var _node = array_pop(_stack);
				var _origin = _node.origin;
				if (_origin != undefined) && (_origin.kind == "macro") {
					var _key = string(_origin.use_span.start);
					__counts[$ _key] = (__counts[$ _key] ?? 0) + 1;
				}
				var _children = _node.children();
				var _i = 0; repeat (array_length(_children)) {
					array_push(_stack, _children[_i]);
				_i++}
			}
		};

		// the offset of the macro use a node's first token came from, or -1: only the nodes of single tokens have an
		// origin, and the first of them down the first children holds the node's first token
		static __useOf = function(_node) {
			while (true) {
				var _origin = _node.origin;
				if (_origin != undefined) return (_origin.kind == "macro") ? _origin.use_span.start : -1;
				var _children = _node.children();
				if (array_length(_children) == 0) return -1;
				_node = _children[0];
			}
		};

		// how many nodes of a subtree came from the macro use at _use, or -1 when one came from elsewhere; a node with
		// no origin of its own is made of its children's tokens, unless it has none
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
		/// @desc    Whether a node is the whole of a macro use, so the use can be written in its place: its expression
		///          spans exactly the use (the tokens of an expansion have the span of their use), the tokens of the
		///          use start and end with its expression's (around any outer pair of parentheses) and their brackets
		///          pair up, every node the use became is in the node's subtree and every token there came from it,
		///          and it is not a use with arguments. For a statement (_statement true) the tokens may end with
		///          semicolons.
		/// @self    GMLC_Emitter
		/// @param   {Struct.ASTNode} _node      : An expression, or the statement that holds one
		/// @param   {Struct.ASTNode} _expr      : The expression
		/// @param   {Bool}           _statement : Whether _node is the statement
		/// @returns {Real} 0 when not, 1 when it is, 2 when it is and its tokens end with a semicolon
		#endregion
		static __macroUse = function(_node, _expr, _statement) {
			if (!__hasRuns) return 0;
			var _use = __useOf(_node);
			if (_use < 0) return 0;
			var _run = __runs[$ string(_use)];
			if (_run == undefined) || (_run.file != file.fileId) return 0;
			if (_expr.span.start != _use) || (_expr.span[$ "end"] != _run.stop) return 0;
			// the tokens, without semicolons at the end of a statement and outer parentheses
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
			while (_p < srcLength) {
				var _b = buffer_peek(src, _p, buffer_u8);
				if (_b != 32) && (_b != 9) break;
				_p++;
			}
			if (_p < srcLength) && (buffer_peek(src, _p, buffer_u8) == ord("(")) {
				if (_run.next >= array_length(__tokens)) || (__tokens[_run.next].start != _p) return 0;
			}
			if (__countFrom(_node, _use) != (__counts[$ string(_use)] ?? 0)) return 0;
			__useParens = _parens;
			return _semicolon ? 2 : 1;
		};

		// the text of the macro use a node is the whole of, or undefined
		static __macroName = function(_node) {
			if (!__hasRuns) || (__macroUse(_node, _node, false) == 0) return undefined;
			var _use = __useOf(_node);
			return __text(_use, __runs[$ string(_use)].stop);
		};

		static __tokenText = function(_i) {
			return __tokens[_i].name;
		};

		// whether the brackets of tokens _first.._last pair up
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

		// the text of the first token a node is written with
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

		// the text of the last token a node is written with
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
		static __indentText = function(_level) {
			while (array_length(__indents) <= _level) {
				array_push(__indents, __indents[array_length(__indents) - 1] + indentUnit);
			}
			return __indents[_level];
		};

		// ends the current line and starts the next one at the current indentation
		static __startLine = function() {
			if (lineOpen) buffer_write(out, buffer_text, "\n");
			buffer_write(out, buffer_text, __indentText(indent));
			lineOpen = true;
			lineComment = false;
		};

		// an empty line
		static __blankLine = function() {
			if (lineOpen) buffer_write(out, buffer_text, "\n");
			buffer_write(out, buffer_text, "\n");
			lineOpen = false;
			lineComment = false;
		};

		// text on the current line; after a `//` comment it goes on the next line
		static __write = function(_text) {
			if (lineComment) __startLine();
			buffer_write(out, buffer_text, _text);
			__unclosed = false;
		};
		#endregion

		#region Statements
		// a list of statements, each on lines of its own, with the pieces of the source between them
		static __list = function(_body) {
			var _i = 0; repeat (array_length(_body)) {
				var _s = _body[_i];
				if (_s.kind == __GMLC_NodeKind_Empty) && (_i > 0) && (lineOpen) {
					// `;` on the line of the statement before, after as many as that statement takes as its own
					__write(string_repeat(";", __absorb + 1));
					__absorb = 0;
					lastEnd = max(lastEnd, _s.span[$ "end"]);
					_i++;
					continue;
				}
				__flush(_s.span.start);
				if (canBlank) && __blankBetween(lastEnd, _s.span.start) __blankLine();
				__startLine();
				__absorb = __statement(_s);
				lastEnd = max(lastEnd, _s.span[$ "end"]);
				canBlank = true;
				printed++;
				// pieces inside the statement that were not written in it
				__flush(_s.span[$ "end"]);
			_i++}
		};

		// `{`, the statements of a block on lines of their own, then `}` on a line of its own (`{}` when nothing is
		// in it)
		static __block = function(_block) {
			__write("{");
			var _before = printed;
			lastEnd = _block.span.start + 1;
			canBlank = false;
			indent++;
			__list(_block.body);
			__flush(_block.span[$ "end"]);
			indent--;
			if (printed != _before) __startLine();
			__write("}");
			lastEnd = max(lastEnd, _block.span[$ "end"]);
		};

		// a statement; how many `;` right after it the parser takes as its own: none after one written with its own
		// `;`, one for each statement that ends at its last `}` (a block, and the `if`, loop or `try` whose body it is,
		// every `if` of an `else if` chain)
		static __statement = function(_s) {
			switch (_s.kind) {
				case __GMLC_NodeKind_ExprStmt: {
					// a macro use that is the whole statement, with its semicolon or without
					var _use = __macroUse(_s, _s.expression, true);
					if (_use == 0) _use = __macroUse(_s.expression, _s.expression, false);
					if (_use > 0) {
						var _at = __useOf(_s);
						__write(__text(_at, __runs[$ string(_at)].stop) + ((_use == 2) ? "" : ";"));
						break;
					}
					// a `gml_pragma("@NoOp")` call that GMLC did not take as the pragma (in an if without braces) stays
					// a call: the parentheses keep it from being read as the pragma at the start of a block
					var _e = _s.expression;
					if (_e.kind == __GMLC_NodeKind_Call) && (_e.callee.kind == __GMLC_NodeKind_Identifier) && (_e.callee.name == "gml_pragma") {
						__write("(gml_pragma)");
						__items(_e.args, _e.callee.span[$ "end"], _e.span[$ "end"] - 1, "(", ")", false);
						__write(";");
						break;
					}
					__expr(_e);
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
					__block(_s.body);
				return 1;}
				case __GMLC_NodeKind_ConstructorDecl: {
					__write("function " + _s.name);
					__params(_s.params);
					if (_s.parent != undefined) {
						__write(" : ");
						__expr(_s.parent);
					}
					__write(" constructor ");
					__block(_s.body);
				return 1;}
				case __GMLC_NodeKind_Block: {
					__block(_s);
				return 1;}
				case __GMLC_NodeKind_If: {
					__write("if (");
					__expr(_s.test);
					__write(") ");
					__block(_s.consequent);
					var _ifs = 1;
					var _else = _s.alternate;
					while (_else != undefined) {
						__write(" else ");
						// `else if` when the block holds one if and no piece of the source before or after it
						if (array_length(_else.body) == 1) && (_else.body[0].kind == __GMLC_NodeKind_If) && !__piecesIn(_else.span.start, _else.body[0].span.start) && !__piecesIn(_else.body[0].span[$ "end"], _else.span[$ "end"]) {
							var _inner = _else.body[0];
							__write("if (");
							__expr(_inner.test);
							__write(") ");
							__block(_inner.consequent);
							_else = _inner.alternate;
							_ifs++;
						}
						else {
							__block(_else);
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
							__expr(_s.init.expression);
						}
					}
					__write(";");
					if (_s.test != undefined) {
						__write(" ");
						__expr(_s.test);
					}
					__write(";");
					if (_s.update != undefined) {
						__write(" ");
						if (_s.update.kind == __GMLC_NodeKind_Block) {
							__inlineBlock(_s.update);
						}
						else {
							__expr(_s.update.expression);
						}
					}
					__write(") ");
					__block(_s.body);
				return 2;}
				case __GMLC_NodeKind_While: {
					__write("while (");
					__expr(_s.test);
					__write(") ");
					__block(_s.body);
				return 2;}
				case __GMLC_NodeKind_Repeat: {
					__write("repeat (");
					__expr(_s.count);
					__write(") ");
					__block(_s.body);
				return 2;}
				case __GMLC_NodeKind_With: {
					__write("with (");
					__expr(_s.target);
					__write(") ");
					__block(_s.body);
				return 2;}
				case __GMLC_NodeKind_DoUntil: {
					__write("do ");
					__block(_s.body);
					__write(" until (");
					__expr(_s.test);
					__write(");");
				break;}
				case __GMLC_NodeKind_Switch: {
					__write("switch (");
					__expr(_s.discriminant);
					__write(") {");
					var _before = printed;
					lastEnd = _s.discriminant.span[$ "end"] + 1;
					canBlank = false;
					indent++;
					var _i = 0; repeat (array_length(_s.cases)) {
						var _case = _s.cases[_i];
						__flush(_case.span.start);
						if (canBlank) && __blankBetween(lastEnd, _case.span.start) __blankLine();
						__startLine();
						if (_case.kind == __GMLC_NodeKind_Case) {
							__write("case ");
							__expr(_case.test);
							__write(":");
							lastEnd = _case.test.span[$ "end"] + 1;
						}
						else {
							__write("default:");
							lastEnd = _case.span.start + 8;
						}
						printed++;
						canBlank = false;
						// a case whose body is one block opens it on the line of its label
						var _body = _case.body;
						if (array_length(_body) == 1) && (_body[0].kind == __GMLC_NodeKind_Block) && !__piecesIn(lastEnd, _body[0].span.start) {
							__write(" ");
							__block(_body[0]);
							lastEnd = max(lastEnd, _body[0].span[$ "end"]);
							__flush(_case.span[$ "end"]);
						}
						else {
							indent++;
							__list(_body);
							indent--;
						}
						canBlank = true;
					_i++}
					__flush(_s.span[$ "end"]);
					indent--;
					if (printed != _before) __startLine();
					__write("}");
				return 1;}
				case __GMLC_NodeKind_Try: {
					__write("try ");
					__block(_s.block);
					if (_s.catch_body != undefined) {
						__write(" catch (" + ((_s.catch_param != undefined) ? _s.catch_param.name : "") + ") ");
						__block(_s.catch_body);
					}
					if (_s.finally_body != undefined) {
						__write(" finally ");
						__block(_s.finally_body);
					}
				return 2;}
				case __GMLC_NodeKind_Return: {
					if (_s.argument == undefined) {
						__write("return;");
						break;
					}
					__write("return ");
					__expr(_s.argument);
					__write(";");
				break;}
				case __GMLC_NodeKind_Throw: {
					__write("throw ");
					__expr(_s.argument);
					__write(";");
				break;}
				case __GMLC_NodeKind_Delete: {
					__write("delete ");
					__expr(_s.target);
					__write(";");
				break;}
				case __GMLC_NodeKind_Break: __write("break;"); break;
				case __GMLC_NodeKind_Continue: __write("continue;"); break;
				case __GMLC_NodeKind_Exit: __write("exit;"); break;
				case __GMLC_NodeKind_Empty: __write(";"); break;
				default:
					throw "GMLC_Emitter: no form for a " + _s.kindName + " statement";
			}
			return 0;
		};

		// whether a piece of the source not yet written starts between two offsets
		static __piecesIn = function(_from, _to) {
			var _i = piece; repeat (array_length(pieces) - piece) {
				var _start = pieces[_i].start;
				if (_start >= _to) return false;
				if (_start >= _from) return true;
			_i++}
			return false;
		};

		// a block on the current line, as the update of a for: `{ a++; b++; }`
		static __inlineBlock = function(_block) {
			__write("{");
			var _i = 0; repeat (array_length(_block.body)) {
				__write(" ");
				__statement(_block.body[_i]);
			_i++}
			__write((array_length(_block.body) > 0) ? " }" : "}");
		};

		static __declarations = function(_list) {
			var _i = 0; repeat (array_length(_list)) {
				if (_i > 0) __write(", ");
				var _d = _list[_i];
				__write(_d.target.name);
				if (_d.init != undefined) {
					__write(" = ");
					__expr(_d.init);
				}
			_i++}
		};

		static __params = function(_params) {
			__write("(");
			var _i = 0; repeat (array_length(_params)) {
				if (_i > 0) __write(", ");
				__write(_params[_i].target.name);
				if (_params[_i][$ "default"] != undefined) {
					__write(" = ");
					__expr(_params[_i][$ "default"]);
				}
			_i++}
			__write(")");
		};
		#endregion

		#region Expressions
		// the operator a node shares with its neighbours for parentheses, undefined for one that has none
		static __group = function(_node) {
			switch (_node.kind) {
				case __GMLC_NodeKind_Binary: case __GMLC_NodeKind_Logical: return _node.op;
				case __GMLC_NodeKind_Nullish: return "??";
				case __GMLC_NodeKind_Conditional: return "?:";
			}
			return undefined;
		};

		// whether a node is written as one unit that an operator in front of it applies to whole
		static __isAtom = function(_node) {
			switch (_node.kind) {
				case __GMLC_NodeKind_Identifier: case __GMLC_NodeKind_Call: case __GMLC_NodeKind_MethodCall:
				case __GMLC_NodeKind_Index: case __GMLC_NodeKind_ArrayLiteral: case __GMLC_NodeKind_StructLiteral:
				case __GMLC_NodeKind_TemplateString: case __GMLC_NodeKind_Nameof:
					return true;
				case __GMLC_NodeKind_Literal:
					return (string_char_at(_node.lexeme, 1) != "-") || (_node.origin != undefined);
			}
			return false;
		};

		// whether a node can be written before `.`, `[` or `(` without parentheses
		static __isChain = function(_node) {
			switch (_node.kind) {
				case __GMLC_NodeKind_Identifier: case __GMLC_NodeKind_Call: case __GMLC_NodeKind_MethodCall:
					return true;
				case __GMLC_NodeKind_Index:
					return true;
			}
			return false;
		};

		// an operand of a binary, logical, nullish or conditional parent
		static __operand = function(_node, _parentGroup, _right) {
			var _group = __group(_node);
			__wrapped(_node, (_group != undefined) && ((_group != _parentGroup) || _right || (_parentGroup == "?:")));
		};

		// a node in parentheses when _wrap is true; a macro use written as its name needs them too, unless its tokens
		// are in parentheses of their own
		static __wrapped = function(_node, _wrap) {
			var _name = __macroName(_node);
			if (_name != undefined) {
				__write((_wrap && !__useParens) ? "(" + _name + ")" : _name);
				return;
			}
			if (_wrap) __write("(");
			__expr(_node);
			if (_wrap) __write(")");
		};

		// the operand of a prefix or postfix operator
		static __unaryOperand = function(_node) {
			__wrapped(_node, !__isAtom(_node));
		};

		// what `.`, `[` or `(` follows
		static __chainObject = function(_node) {
			__wrapped(_node, !__isChain(_node));
		};

		static __expr = function(_node) {
			if (__hasRuns) {
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
				case __GMLC_NodeKind_Literal: __literal(_node); break;
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
					__expr(_node.target);
					__write(" " + _node.op + " ");
					__expr(_node.value);
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
					__items(_node.args, _callee.span[$ "end"], _node.span[$ "end"] - 1, "(", ")", false);
				break;}
				case __GMLC_NodeKind_MethodCall: {
					__chainObject(_node.object);
					__write("." + _node.member);
					__items(_node.args, _node.object.span[$ "end"], _node.span[$ "end"] - 1, "(", ")", false);
				break;}
				case __GMLC_NodeKind_New: {
					__write("new ");
					__wrapped(_node.callee, !__isNewCallee(_node.callee));
					__items(_node.args, _node.callee.span[$ "end"], _node.span[$ "end"] - 1, "(", ")", false);
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
						__expr(_node.keys[_i]);
					_i++}
					__write("]");
				break;}
				case __GMLC_NodeKind_ArrayLiteral: {
					var _open = (array_length(_node.elements) > 0) && __joinsBracket(_node.elements[0]) ? "[ " : "[";
					__items(_node.elements, _node.span.start + 1, _node.span[$ "end"] - 1, _open, "]", false);
				break;}
				case __GMLC_NodeKind_StructLiteral: {
					__items(_node.entries, _node.span.start + 1, _node.span[$ "end"] - 1, "{", "}", true);
				break;}
				case __GMLC_NodeKind_TemplateString: {
					__write("$\"");
					var _i = 0; repeat (array_length(_node.strings)) {
						__write(__escape(_node.strings[_i], true));
						if (_i < array_length(_node.exprs)) {
							__write("{");
							__expr(_node.exprs[_i]);
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
						__expr(_node.parent);
					}
					if (_node.is_constructor) __write(" constructor");
					__write(" ");
					__block(_node.body);
				break;}
				case __GMLC_NodeKind_Nameof: __write("nameof(" + _node.name + ")"); break;
				case __GMLC_NodeKind_Empty: break;
				default:
					throw "GMLC_Emitter: no form for a " + _node.kindName + " expression";
			}
		};

		// whether the callee of `new` is written without parentheses: a name, or names and indexes after one
		static __isNewCallee = function(_node) {
			while (_node.kind == __GMLC_NodeKind_Index) {
				_node = _node.object;
			}
			return (_node.kind == __GMLC_NodeKind_Identifier);
		};

		// the bracket an accessor opens with
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

		// whether a node starts with `@`, `$`, `#`, `|` or `?`, which right after `[` would be read as an accessor
		static __joinsBracket = function(_node) {
			var _first = __firstText(_node);
			if (_first == undefined) return false;
			var _c = string_char_at(_first, 1);
			return (_c == "@") || (_c == "$") || (_c == "#") || (_c == "|") || (_c == "?");
		};

		#region jsDoc
		/// @func    __items(_items, _from, _close, _open, _closeText, _entries)
		/// @desc    A bracketed list: arguments, array elements or struct entries. Where the source breaks the line
		///          before an item or before the closing bracket, the item starts a line of its own one level in, the
		///          bracket one at the level of the line it closes; the pieces of the source before it are written
		///          there. A hole at the end of the list keeps a comma after it.
		/// @self    GMLC_Emitter
		/// @param   {Array<Struct.ASTNode>} _items     : The items
		/// @param   {Real}                  _from      : Source offset after the opening bracket
		/// @param   {Real}                  _close     : Source offset of the closing bracket
		/// @param   {String}                _open      : The opening bracket
		/// @param   {String}                _closeText : The closing bracket
		/// @param   {Bool}                  _entries   : Whether the items are struct entries
		#endregion
		static __items = function(_items, _from, _close, _open, _closeText, _entries) {
			__write(_open);
			var _n = array_length(_items);
			var _prev = _from;
			var _broken = false;
			var _blank = canBlank;
			canBlank = false;
			var _i = 0; repeat (_n) {
				var _item = _items[_i];
				if (_i > 0) __write(",");
				var _start = _item.span.start;
				var _break = (_item.kind != __GMLC_NodeKind_Empty) && (_start >= _prev) && __breakBetween(_prev, _start) && !__startsWithHash(_item);
				if (_break) {
					if (!_broken) indent++;
					_broken = true;
					__flush(_start);
					__startLine();
				}
				else if (_i > 0) && (_item.kind != __GMLC_NodeKind_Empty) {
					__write(" ");
				}
				if (_entries) {
					__entry(_item);
				}
				else {
					__expr(_item);
				}
				if (_item.kind != __GMLC_NodeKind_Empty) {
					_prev = _item.span[$ "end"];
					lastEnd = max(lastEnd, _prev);
				}
			_i++}
			if (_n > 0) && (_items[_n - 1].kind == __GMLC_NodeKind_Empty) __write(",");
			if (_n > 0) && (_close >= _prev) && __breakBetween(_prev, _close) {
				if (!_broken) indent++;
				__flush(_close);
				indent--;
				_broken = false;
				__startLine();
			}
			if (_broken) indent--;
			canBlank = _blank;
			__write(_closeText);
		};

		// whether an item is written starting with `#`, which may not start a line
		static __startsWithHash = function(_node) {
			return (_node.kind == __GMLC_NodeKind_Literal) && (string_char_at(_node.lexeme, 1) == "#");
		};

		static __entry = function(_entry) {
			if (_entry.shorthand) {
				__write(_entry.key);
				return;
			}
			__write(_entry.quoted ? "\"" + __escape(_entry.key, false) + "\"" : _entry.key);
			__write(": ");
			__expr(_entry.value);
		};

		static __literal = function(_node) {
			var _lexeme = _node.lexeme;
			switch (_node.ty) {
				case "string":
					// a folded string or one from a macro has no text of its own in the source
					if (__text(_node.span.start, _node.span[$ "end"]) != _lexeme) {
						__write("\"" + __escape(_node.value, false) + "\"");
						return;
					}
					break;
				case "real":
					// a whole number of 2^31 or more would be read as an int64
					if (abs(_node.value) >= 2147483648) && __isDigits(_lexeme) {
						__write(_lexeme + ".0");
						return;
					}
					break;
			}
			__write(_lexeme);
		};

		// whether a text is digits, with a minus sign in front or not
		static __isDigits = function(_text) {
			var _n = string_length(_text);
			if (_n == 0) return false;
			var _i = (string_char_at(_text, 1) == "-") ? 2 : 1;
			if (_i > _n) return false;
			repeat (_n - _i + 1) {
				var _c = ord(string_char_at(_text, _i));
				if (_c < ord("0")) || (_c > ord("9")) return false;
				_i++;
			}
			return true;
		};

		// a string's text as it is written between double quotes (of a template string when _template is true)
		static __escape = function(_text, _template) {
			_text = string_replace_all(_text, "\\", "\\\\");
			_text = string_replace_all(_text, "\"", "\\\"");
			_text = string_replace_all(_text, "\n", "\\n");
			_text = string_replace_all(_text, "\r", "\\r");
			_text = string_replace_all(_text, "\t", "\\t");
			// the other control characters as \x and two hex digits, so none is written raw
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
	}
#endregion
