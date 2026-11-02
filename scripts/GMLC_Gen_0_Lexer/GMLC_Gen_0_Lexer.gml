#macro __GMLC_TokenKind_Eof            0
#macro __GMLC_TokenKind_Illegal        1
#macro __GMLC_TokenKind_Newline        2
#macro __GMLC_TokenKind_Comment        3
#macro __GMLC_TokenKind_Region         4
#macro __GMLC_TokenKind_Backslash      5
#macro __GMLC_TokenKind_MacroDirective 6
#macro __GMLC_TokenKind_Identifier     7
#macro __GMLC_TokenKind_Keyword        8
#macro __GMLC_TokenKind_Number         9
#macro __GMLC_TokenKind_String         10
#macro __GMLC_TokenKind_TemplateFull   11
#macro __GMLC_TokenKind_TemplateHead   12
#macro __GMLC_TokenKind_TemplateMiddle 13
#macro __GMLC_TokenKind_TemplateTail   14
#macro __GMLC_TokenKind_Op             15

enum __GMLC_StringEnd { QUOTE, BRACE, NEWLINE, EOF }

#region jsDoc
/// @func    GMLC_Gen_0_Lexer(_env)
/// @desc    Lexer stage: `initialize(source, fileName)` then `parseAll()`. The environment is never read.
/// @param   {Struct.GMLC_Env} _env : The environment that owns this stage
/// @returns {Struct.GMLC_Gen_0_Lexer}
#endregion
function GMLC_Gen_0_Lexer(_env) constructor {
	#region Config
	// keywords map to true, alias words to the operator they spell
	static __words = {
		"if": true, "then": true, "else": true, "for": true, "while": true, "do": true, "until": true,
		"repeat": true, "switch": true, "case": true, "default": true, "break": true, "continue": true,
		"with": true, "exit": true, "return": true, "var": true, "globalvar": true, "static": true, "enum": true,
		"function": true, "constructor": true, "new": true, "delete": true, "throw": true, "try": true,
		"catch": true, "finally": true,
		"and": "&&", "or": "||", "xor": "^^", "not": "!", "div": "div", "mod": "mod", "begin": "{", "end": "}",
	};
	#endregion

	#region Init
	env = _env;

	buf = undefined;
	len = 0;
	pos = 0;

	file_name = "input";
	file_id = 0;

	tokens = [];
	eof_token = undefined;
	diagnostics = [];
	modes = [];             // one entry per open interpolation: its count of open `{`
	program = undefined;

	after_dot = false;       // the last token other than a line break, comment or region is `.`
	string_end = __GMLC_StringEnd.EOF;
	high = false;           // the last scan saw a byte of 0x80 or more
	escape_ends_string = false;
	#endregion

	#region Public
	#region jsDoc
	/// @func    initialize(_source, _fileName, [_fileId])
	/// @desc    Prepares lexing of one file: drops a leading BOM; a run of CR before LF is one line break and any
	///          other CR is a line break of its own.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {String} _source   : Source text
	/// @param   {String} _fileName : Name used in positions and errors
	/// @param   {Real}   [_fileId] : File number in the source table
	#endregion
	static initialize = function(_source, _fileName = "input", _fileId = 0) {
		file_name = _fileName;
		file_id = _fileId;
		tokens = [];
		eof_token = undefined;
		diagnostics = [];
		modes = [];
		pos = 0;
		after_dot = false;
		
		var _text = _source;
		if (string_byte_length(_text) >= 3) && (string_byte_at(_text, 1) == 0xEF) && (string_byte_at(_text, 2) == 0xBB) && (string_byte_at(_text, 3) == 0xBF) {
			_text = string_delete(_text, 1, 1);
		}
		if (string_pos("\r", _text) > 0) {
			var _lines = string_split(_text, "\n");
			var _l = 0; repeat (array_length(_lines) - 1) {
				_lines[_l] = string_trim_end(_lines[_l], ["\r"]);
			_l++}
			_text = string_replace_all(string_join_ext("\n", _lines), "\r", "\n");
		}
		len = string_byte_length(_text);
		
		if (buf != undefined) buffer_delete(buf);
		buf = buffer_create(len + 1, buffer_fixed, 1);
		buffer_write(buf, buffer_text, _text);
		
		program = new __GMLC_ProgramTokens(tokens, new GMLC_SourceFile(file_id, file_name, _text));
		return self;
	};

	#region jsDoc
	/// @func    parseAll()
	/// @desc    Lexes the whole file; throws after lexing when a diagnostic is an error.
	/// @self    GMLC_Gen_0_Lexer
	/// @returns {Struct} The program token record
	#endregion
	static parseAll = function() {
		while (nextToken() != __GMLC_TokenKind_Eof) {}
		program.tokens = tokens;
		program.eof = eof_token;

		if (__gmlc_has_errors(diagnostics)) __gmlc_throw_diagnostics(diagnostics, new GMLC_SourceTable(program.file));
		return program;
	};
	#endregion

	#region Private
	#region Token loop
	#region jsDoc
	/// @func    nextToken()
	/// @desc    Lexes one token at `pos` and appends it.
	/// @self    GMLC_Gen_0_Lexer
	/// @returns {Real} The kind of the token
	#endregion
	static nextToken = function() {
		__skipWhitespace();
		var _start = pos;
		if (pos >= len) {
			eof_token = new __GMLC_create_token(__GMLC_TokenType_Whitespace, "", undefined, file_id, _start, _start, __GMLC_TokenKind_Eof);
			return __GMLC_TokenKind_Eof;
		}

		var _b = __byte(pos);

		if (array_length(modes) > 0) {
			if (_b == ord("{")) {
				modes[array_length(modes) - 1]++;
				pos++;
				return __pushOp(_start, "{");
			}
			if (_b == ord("}")) {
				if (modes[array_length(modes) - 1] > 0) {
					modes[array_length(modes) - 1]--;
					pos++;
					return __pushOp(_start, "}");
				}
				array_pop(modes);
				pos++;
				return scanTemplateText(_start, false);
			}
		}

		switch (_b) {
			case 10: {
				pos++;
				return __push(__GMLC_TokenKind_Newline, __GMLC_TokenType_Whitespace, _start, "\n");
			}
			case ord("/"): {
				var _n = __byte(pos + 1);
				if (_n == ord("/")) {
					high = false;
					while (pos < len) {
						var _c = __byte(pos);
						if (_c == 10) break;
						if (_c >= 0x80) high = true;
						pos++;
					}
					return __push(__GMLC_TokenKind_Comment, __GMLC_TokenType_Comment, _start, __utf8Value(_start, __gmlc_buffer_text(buf, _start, pos)));
				}
				if (_n == ord("*")) {
					pos += 2;
					high = false;
					while (pos < len) {
						var _c = __byte(pos);
						if (_c == ord("*")) && (__byte(pos + 1) == ord("/")) {
							pos += 2;
							break;
						}
						if (_c >= 0x80) high = true;
						pos++;
					}
					// an unclosed block comment runs to the end of the file
					return __push(__GMLC_TokenKind_Comment, __GMLC_TokenType_Comment, _start, __utf8Value(_start, __gmlc_buffer_text(buf, _start, pos)));
				}
				return lexOperator(_start);
			}
			case ord("\""): return lexString(_start);
			case ord("@"): {
				var _n = __byte(pos + 1);
				if (_n == ord("\"")) || (_n == ord("'")) return lexVerbatim(_start);
				pos++;
				return __illegal("GMLC0002", _start, ["@"]);
			}
			case ord("$"): {
				var _n = __byte(pos + 1);
				if (_n == ord("\"")) {
					pos += 2;
					return scanTemplateText(_start, true);
				}
				if (__char_is_hex(_n)) return lexNumber(_start);
				pos++;
				return __illegal("GMLC0002", _start, ["$"]);
			}
			case ord("#"): return lexDirective(_start);
			case ord("'"): {
				// single quotes are not a GML string: Illegal up to the closing quote on this line
				pos++;
				high = false;
				while (pos < len) && (__byte(pos) != 10) && (__byte(pos) != ord("'")) {
					if (__byte(pos) >= 0x80) high = true;
					pos++;
				}
				if (pos < len) && (__byte(pos) == ord("'")) pos++;
				__markUtf8(_start);
				return __illegal("GMLC0017", _start);
			}
			case ord("\\"): {
				pos++;
				return __push(__GMLC_TokenKind_Backslash, __GMLC_TokenType_EscapeOperator, _start, "\\");
			}
			case ord("."): {
				if (__char_is_digit(__byte(pos + 1))) return lexNumber(_start);
				pos++;
				return __pushOp(_start, ".");
			}
			case ord("["): {
				// written together these are always accessors in GameMaker, so `[#ff0000]` and `[$FF]` are refused
				var _n = __byte(pos + 1);
				if (_n == ord("|")) || (_n == ord("?")) || (_n == ord("#")) || (_n == ord("$")) || (_n == ord("@")) {
					pos += 2;
					return __pushOp(_start, "[" + chr(_n));
				}
				pos++;
				return __pushOp(_start, "[");
			}
		}
		
		if (__char_is_digit(_b)) return lexNumber(_start);
		if (__char_is_alphabetic(_b)) return lexWord(_start);
		if (_b < 128) return lexOperator(_start);
		
		var _cp = __decode(pos);
		if (_cp < 0) {
			pos++;
			program.file.invalid_utf8 = true;
			return __illegal("GMLC0001", _start);
		}
		pos += __utf8Length(_b);
		return __illegal("GMLC0002", _start, [__gmlc_buffer_text(buf, _start, pos)]);
	};
	#endregion
	
	#region Words
	#region jsDoc
	/// @func    lexWord(_start)
	/// @desc    Lexes a keyword, an alias word (an operator) or an identifier. After `.` every word is an
	///          identifier (`s.end`), as in GameMaker. Constants such as `true` are identifiers.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of the word
	/// @returns {Real} The kind of the token
	#endregion
	static lexWord = function(_start) {
		// hot path: bytes are read in place
		var _p = pos;
		while (_p < len) {
			var _b = buffer_peek(buf, _p, buffer_u8);
			if (!(((_b >= 97) && (_b <= 122)) || ((_b >= 65) && (_b <= 90)) || (_b == 95) || ((_b >= 48) && (_b <= 57)))) break;
			_p++;
		}
		pos = _p;
		var _word = __gmlc_buffer_text(buf, _start, pos);
		
		if (!after_dot) {
			var _meaning = __words[$ _word];
			if (is_string(_meaning)) return __pushOp(_start, _meaning);
			if (is_bool(_meaning)) return __push(__GMLC_TokenKind_Keyword, __GMLC_TokenType_Keyword, _start, _word);
		}
		return __push(__GMLC_TokenKind_Identifier, __GMLC_TokenType_Identifier, _start, _word);
	};
	#endregion
	
	#region Directives
	#region jsDoc
	/// @func    lexDirective(_start)
	/// @desc    Lexes `#macro`, `#region` / `#endregion` (to the end of the line), a color `#RRGGBB`, or an error
	///          for any other directive. GameMaker accepts directives after code on the same line.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of `#`
	/// @returns {Real} The kind of the token
	#endregion
	static lexDirective = function(_start) {
		var _i = pos + 1;
		while (_i < len) && (__char_is_alphanumeric(__byte(_i))) _i++;
		var _word = __gmlc_buffer_text(buf, pos + 1, _i);
		
		if (_word == "macro") {
			pos = _i;
			return __push(__GMLC_TokenKind_MacroDirective, __GMLC_TokenType_Keyword, _start, "#macro");
		}
		if (_word == "region") || (_word == "endregion") {
			while (pos < len) && (__byte(pos) != 10) pos++;
			return __push(__GMLC_TokenKind_Region, __GMLC_TokenType_Region, _start, _word);
		}
		
		var _h = pos + 1;
		while (_h < len) && (__char_is_hex(__byte(_h))) _h++;
		if (_h > pos + 1) && (_h == _i) {
			if (_h - (pos + 1) == 6) {
				pos = _h;
				var _rgb = __hexValue(_start + 1, _h);
				var _r = (_rgb >> 16) & 0xFF;
				var _g = (_rgb >> 8) & 0xFF;
				var _b = _rgb & 0xFF;
				return __push(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, real(_r + _g * 256 + _b * 65536), "color");
			}
			pos = _h;
			return __illegal("GMLC0005", _start);
		}
		
		if (_word != "") {
			while (pos < len) && (__byte(pos) != 10) pos++;
			return __illegal("GMLC0003", _start, [_word]);
		}
		pos++;
		return __illegal("GMLC0002", _start, ["#"]);
	};
	#endregion
	
	#region Numbers
	#region jsDoc
	/// @func    lexNumber(_start)
	/// @desc    Lexes a decimal, `0x` / `$` hex or `0b` binary literal and types it as GameMaker does: whole
	///          decimals above 2^31-1 are int64 up to 2^63-1, also with a zero fraction (`2147483648.0`); hex and
	///          binary are int64 unless their 64-bit value fits in 32 bits (`$FFFFFFFFFFFFFFFF` is -1).
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of the literal
	/// @returns {Real} The kind of the token
	#endregion
	static lexNumber = function(_start) {
		var _b = __byte(pos);
		var _radix = 10;
		if (_b == ord("$")) {
			_radix = 16;
			pos += 1;
		}
		else if (_b == ord("0")) && (__byte(pos + 1) == ord("x")) {
			_radix = 16;
			pos += 2;
		}
		else if (_b == ord("0")) && (__byte(pos + 1) == ord("b")) {
			_radix = 2;
			pos += 2;
		}
		var _digits = pos;
		var _count = 0;
		var _dot = false;
		while (pos < len) {
			var _c = __byte(pos);
			if (_c == ord("_")) { pos++; continue; }
			var _isDigit = (_radix == 16) ? __char_is_hex(_c) : ((_radix == 2) ? ((_c == ord("0")) || (_c == ord("1"))) : __char_is_digit(_c));
			if (_isDigit) { _count++; pos++; continue; }
			if (_radix == 10) && (_c == ord(".")) && (!_dot) { _dot = true; pos++; continue; }
			break;
		}
		if (_count == 0) || (__char_is_alphanumeric(__byte(pos))) || ((_radix == 10) && (__byte(pos) == ord(".")) && __char_is_digit(__byte(pos + 1))) {
			while (pos < len) && (__char_is_alphanumeric(__byte(pos)) || __byte(pos) == ord(".")) pos++;
			return __illegal("GMLC0006", _start, [__gmlc_buffer_text(buf, _start, pos)]);
		}
		
		if (_radix != 10) {
			if ((_radix == 16) && (_count > 16)) || ((_radix == 2) && (_count > 64)) {
				return __illegal("GMLC0007", _start);
			}
			var _v = __hexValue(_digits, pos, (_radix == 16) ? 4 : 1);
			if (_v >= -2147483648) && (_v <= 2147483647) {
				return __push(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, real(_v), "real");
			}
			return __push(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, _v, "int64");
		}
		
		var _text = string_replace_all(__gmlc_buffer_text(buf, _start, pos), "_", "");
		var _point = string_pos(".", _text);
		var _whole = (_dot) ? string_copy(_text, 1, _point - 1) : _text;
		// leading zeros off, so magnitudes compare as text
		while (string_length(_whole) > 1) && (string_char_at(_whole, 1) == "0") _whole = string_delete(_whole, 1, 1);
		if (_dot) {
			var _fraction = string_delete(_text, 1, _point);
			if (string_count("0", _fraction) == string_length(_fraction)) && (!__decimalAtMost(_whole, "2147483647")) && (__decimalAtMost(_whole, "9223372036854775807")) {
				_dot = false;
			}
		}
		if (_dot) {
			return __push(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, real(_text), "real");
		}
		if (__decimalAtMost(_whole, "2147483647")) {
			return __push(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, real(_whole), "real");
		}
		if (__decimalAtMost(_whole, "9223372036854775807")) {
			return __push(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, int64(_whole), "int64");
		}
		__report("GMLC0008", _start, pos, [__gmlc_buffer_text(buf, _start, pos)]);
		return __push(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, real(_whole), "real");
	};
	#endregion
	
	#region Strings
	#region jsDoc
	/// @func    lexString(_start)
	/// @desc    Lexes `"..."` with escapes. A raw line break or the end of the file ends it with an error.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of the opening quote
	/// @returns {Real} The kind of the token
	#endregion
	static lexString = function(_start) {
		pos++;
		var _unescaped = __readStringText(_start, ord("\""), false);
		switch (string_end) {
			case __GMLC_StringEnd.QUOTE:   pos++; break;
			case __GMLC_StringEnd.NEWLINE: __report("GMLC0010", _start, pos); break;
			default:                     __report("GMLC0009", _start, pos); break;
		}
		return __push(__GMLC_TokenKind_String, __GMLC_TokenType_String, _start, __utf8Value(_start, _unescaped));
	};
	
	#region jsDoc
	/// @func    lexVerbatim(_start)
	/// @desc    Lexes `@"..."` or `@'...'`: no escapes, may span lines, ends at the first matching quote.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of `@`
	/// @returns {Real} The kind of the token
	#endregion
	static lexVerbatim = function(_start) {
		var _quote = __byte(pos + 1);
		pos += 2;
		var _from = pos;
		high = false;
		while (pos < len) {
			var _c = __byte(pos);
			if (_c == _quote) break;
			if (_c >= 0x80) high = true;
			pos++;
		}
		var _value = __gmlc_buffer_text(buf, _from, pos);
		if (pos < len) {
			pos++;
		}
		else {
			__report("GMLC0009", _start, pos);
		}
		return __push(__GMLC_TokenKind_String, __GMLC_TokenType_String, _start, __utf8Value(_start, _value));
	};
	
	#region jsDoc
	/// @func    scanTemplateText(_start, _isStart)
	/// @desc    Lexes the text part of a template string, after `$"` (_isStart) or after the `}` that ends an
	///          interpolation, up to the closing `"` or an unescaped `{`, which opens the next interpolation.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start   : Byte offset of `$` or `}`
	/// @param   {Bool} _isStart : true after `$"`
	/// @returns {Real} The kind of the token
	#endregion
	static scanTemplateText = function(_start, _isStart) {
		var _unescaped = __readStringText(_start, ord("\""), true);
		if (string_end == __GMLC_StringEnd.BRACE) {
			pos++;
			array_push(modes, 0);
			if (_isStart) return __push(__GMLC_TokenKind_TemplateHead, __GMLC_TokenType_TemplateStringBegin, _start, __utf8Value(_start, _unescaped));
			return __push(__GMLC_TokenKind_TemplateMiddle, __GMLC_TokenType_TemplateStringMiddle, _start, __utf8Value(_start, _unescaped));
		}
		switch (string_end) {
			case __GMLC_StringEnd.QUOTE:   pos++; break;
			case __GMLC_StringEnd.NEWLINE: __report("GMLC0014", _start, pos); break;
			default:                     __report("GMLC0013", _start, pos); break;
		}
		// a template with no interpolation is a plain string to the parser
		if (_isStart) return __push(__GMLC_TokenKind_TemplateFull, __GMLC_TokenType_String, _start, __utf8Value(_start, _unescaped));
		return __push(__GMLC_TokenKind_TemplateTail, __GMLC_TokenType_TemplateStringEnd, _start, __utf8Value(_start, _unescaped));
	};

	#region jsDoc
	/// @func    __utf8Value(_start, _value)
	/// @desc    The value of a string, template text or comment token ending at `pos`, with U+FFFD for each byte
	///          that is not UTF-8.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real}   _start : Byte offset of the token
	/// @param   {String} _value : The token's value
	/// @returns {String}
	#endregion
	static __utf8Value = function(_start, _value) {
		return __markUtf8(_start) ? __gmlc_lossy_utf8(_value) : _value;
	};

	#region jsDoc
	/// @func    __markUtf8(_start)
	/// @desc    Whether the bytes from _start to `pos` are not all UTF-8; marks the file when so.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of the token
	/// @returns {Bool}
	#endregion
	static __markUtf8 = function(_start) {
		if (!high) return false;
		var _p = _start;
		while (_p < pos) {
			var _n = __gmlc_utf8_length(buf, _p, len);
			if (_n == 0) {
				program.file.invalid_utf8 = true;
				return true;
			}
			_p += _n;
		}
		return false;
	};

	#region jsDoc
	/// @func    __readStringText(_start, _quote, _template)
	/// @desc    Reads string text from `pos` with escapes applied, leaving `pos` on what ended it (`string_end`). After
	///          `\0` the rest is dropped, as GameMaker strings end at the first NUL.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start    : Byte offset of the literal, for diagnostics
	/// @param   {Real} _quote    : Byte that closes the text
	/// @param   {Bool} _template : true in a template string, where `{` opens an interpolation
	/// @returns {String}
	#endregion
	static __readStringText = function(_start, _quote, _template) {
		var _out = "";
		var _run = pos;
		var _ended = false; // after \0
		high = false;
		while (true) {
			if (pos >= len) { string_end = __GMLC_StringEnd.EOF; break; }
			var _c = __byte(pos);
			if (_c == _quote) { string_end = __GMLC_StringEnd.QUOTE; break; }
			if (_c == 10) { string_end = __GMLC_StringEnd.NEWLINE; break; }
			if (_template) && (_c == ord("{")) { string_end = __GMLC_StringEnd.BRACE; break; }
			if (_c != ord("\\")) {
				if (_c >= 0x80) high = true;
				pos++;
				continue;
			}

			if (!_ended) _out += __gmlc_buffer_text(buf, _run, pos);
			pos++;
			var _piece = __readEscape(_start);
			if (escape_ends_string) _ended = true;
			if (!_ended) _out += _piece;
			_run = pos;
		}
		if (!_ended) _out += __gmlc_buffer_text(buf, _run, pos);
		return _out;
	};
	
	#region jsDoc
	/// @func    __readEscape(_start)
	/// @desc    Reads the escape after a backslash and returns the text it stands for: `x` takes exactly 2 hex
	///          digits; `u` every following hex digit, at most 0x10FFFF and no surrogate; octal 1 to 3 digits below
	///          256; a backslash before a line break joins the lines; any other character stands for itself.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of the literal, for diagnostics
	/// @returns {String}
	#endregion
	static __readEscape = function(_start) {
		escape_ends_string = false;
		if (pos >= len) return "";
		var _escStart = pos - 1;
		var _c = __byte(pos);
		switch (_c) {
			case ord("n"): pos++; return "\n";
			case ord("r"): pos++; return "\r";
			case ord("t"): pos++; return "\t";
			case ord("b"): pos++; return chr(8);
			case ord("f"): pos++; return chr(12);
			case ord("v"): pos++; return chr(11);
			case ord("a"): pos++; return chr(7);
			case 10: pos++; return "";
			case ord("x"): {
				pos++;
				if (__char_is_hex(__byte(pos))) && (__char_is_hex(__byte(pos + 1))) {
					var _v = __hexValue(pos, pos + 2);
					pos += 2;
					return __escapeChar(_v);
				}
				__report("GMLC0012", _escStart, pos, [__gmlc_buffer_text(buf, _escStart, pos)]);
				return "";
			}
			case ord("u"): {
				pos++;
				var _from = pos;
				while (pos < len) && (__char_is_hex(__byte(pos))) pos++;
				if (pos == _from) || (pos - _from > 8) {
					__report("GMLC0012", _escStart, pos, [__gmlc_buffer_text(buf, _escStart, pos)]);
					return "";
				}
				var _v = __hexValue(_from, pos);
				if (_v > 0x10FFFF) || ((_v >= 0xD800) && (_v <= 0xDFFF)) {
					__report("GMLC0012", _escStart, pos, [__gmlc_buffer_text(buf, _escStart, pos)]);
					return "";
				}
				return __escapeChar(_v);
			}
		}
		if (_c >= ord("0")) && (_c <= ord("7")) {
			var _v = 0;
			var _n = 0;
			while (_n < 3) && (pos < len) && (__byte(pos) >= ord("0")) && (__byte(pos) <= ord("7")) {
				_v = _v * 8 + (__byte(pos) - ord("0"));
				pos++;
				_n++;
			}
			if (_v > 255) {
				__report("GMLC0012", _escStart, pos, [__gmlc_buffer_text(buf, _escStart, pos)]);
				return "";
			}
			return __escapeChar(_v);
		}
		if (_c >= 0x80) high = true;
		var _l = min(__utf8Length(_c), len - pos);
		var _piece = __gmlc_buffer_text(buf, pos, pos + _l);
		pos += _l;
		return _piece;
	};
	
	#region jsDoc
	/// @func    __escapeChar(_code)
	/// @desc    chr(_code), but code 0 gives "" and ends the string (GameMaker strings stop at the first NUL).
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _code : Character code
	/// @returns {String}
	#endregion
	static __escapeChar = function(_code) {
		if (_code == 0) {
			escape_ends_string = true;
			return "";
		}
		return chr(_code);
	};
	#endregion
	
	#region Operators
	#region jsDoc
	/// @func    lexOperator(_start)
	/// @desc    Lexes punctuation and operators by longest match. `<>` is `!=`, `:=` is `=`, `%` is `mod`;
	///          `<<=` and `>>=` are not GML.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of the operator
	/// @returns {Real} The kind of the token
	#endregion
	static lexOperator = function(_start) {
		var _c = __byte(pos);
		var _n = __byte(pos + 1);
		
		var _op = undefined;
		if (_n == ord("=")) {
			switch (_c) {
				case ord("="): _op = "=="; break;
				case ord("!"): _op = "!="; break;
				case ord("<"): _op = "<="; break;
				case ord(">"): _op = ">="; break;
				case ord("+"): _op = "+="; break;
				case ord("-"): _op = "-="; break;
				case ord("*"): _op = "*="; break;
				case ord("/"): _op = "/="; break;
				case ord("%"): _op = "%="; break;
				case ord("&"): _op = "&="; break;
				case ord("|"): _op = "|="; break;
				case ord("^"): _op = "^="; break;
				case ord(":"): _op = "="; break;
			}
		}
		else if (_n == _c) {
			switch (_c) {
				case ord("<"): _op = "<<"; break;
				case ord(">"): _op = ">>"; break;
				case ord("+"): _op = "++"; break;
				case ord("-"): _op = "--"; break;
				case ord("&"): _op = "&&"; break;
				case ord("|"): _op = "||"; break;
				case ord("^"): _op = "^^"; break;
				case ord("?"): _op = "??"; break;
			}
		}
		else if (_c == ord("<")) && (_n == ord(">")) {
			_op = "!=";
		}
		if (_op != undefined) {
			if (__byte(pos + 2) == ord("=")) {
				if (_op == "<<") || (_op == ">>") {
					pos += 3;
					return __illegal("GMLC0016", _start, [_op + "="]);
				}
				if (_op == "??") {
					pos += 3;
					return __pushOp(_start, "??=");
				}
			}
			pos += 2;
			return __pushOp(_start, _op);
		}

		pos++;
		switch (_c) {
			case ord("("): case ord(")"): case ord("]"): case ord("{"): case ord("}"): case ord(","): case ord(";"):
			case ord(":"): case ord("?"): case ord("="): case ord("<"): case ord(">"): case ord("+"): case ord("-"):
			case ord("*"): case ord("/"): case ord("!"): case ord("~"): case ord("&"): case ord("|"): case ord("^"):
				return __pushOp(_start, chr(_c));
			case ord("%"):
				return __pushOp(_start, "mod");
		}
		return __illegal("GMLC0002", _start, [chr(_c)]);
	};
	#endregion

	#region Bytes and tokens
	#region jsDoc
	/// @func    __byte(_p)
	/// @desc    The byte at an offset, -1 past the end.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _p : Byte offset
	/// @returns {Real}
	#endregion
	static __byte = function(_p) {
		return (_p < len) ? buffer_peek(buf, _p, buffer_u8) : -1;
	};

	#region jsDoc
	/// @func    __utf8Length(_b)
	/// @desc    The length of the UTF-8 sequence a lead byte starts; 1 for a byte that cannot start one.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _b : The lead byte
	/// @returns {Real}
	#endregion
	static __utf8Length = function(_b) {
		if (_b < 0x80) return 1;
		if (_b >= 0xF0) return 4;
		if (_b >= 0xE0) return 3;
		if (_b >= 0xC0) return 2;
		return 1;
	};

	#region jsDoc
	/// @func    __decode(_p)
	/// @desc    Returns the code point at byte `_p`, or -1 when the bytes there are not valid UTF-8 (shortest form,
	///          at most 0x10FFFF, no surrogate).
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _p : Byte offset
	/// @returns {Real}
	#endregion
	static __decode = function(_p) {
		var _b = __byte(_p);
		if (_b < 0x80) return _b;
		var _n = __utf8Length(_b);
		if (_n == 1) return -1;
		var _cp = _b & ((_n == 2) ? 0x1F : ((_n == 3) ? 0x0F : 0x07));
		for (var _i = 1; _i < _n; _i++) {
			var _c = __byte(_p + _i);
			if (_c < 0x80) || (_c > 0xBF) return -1;
			_cp = (_cp << 6) | (_c & 0x3F);
		}
		if ((_n == 2) && (_cp < 0x80)) || ((_n == 3) && (_cp < 0x800)) || ((_n == 4) && (_cp < 0x10000)) return -1;
		if (_cp > 0x10FFFF) || ((_cp >= 0xD800) && (_cp <= 0xDFFF)) return -1;
		return _cp;
	};

	#region jsDoc
	/// @func    __skipWhitespace()
	/// @desc    Skips the whitespace code points GameMaker's manual lists, except LF.
	/// @self    GMLC_Gen_0_Lexer
	#endregion
	static __skipWhitespace = function() {
		while (pos < len) {
			var _b = __byte(pos);
			if (_b == 32) || (_b == 9) || (_b == 11) || (_b == 12) || (_b == 13) { pos++; continue; }
			if (_b < 0x80) return;
			var _cp = __decode(pos);
			if (_cp == 0x85) || (_cp == 0xA0) || (_cp == 0x1680) || (_cp == 0x180E)
			|| ((_cp >= 0x2000) && (_cp <= 0x200D)) || (_cp == 0x2028) || (_cp == 0x2029) || (_cp == 0x202F)
			|| (_cp == 0x205F) || (_cp == 0x2060) || (_cp == 0x3000) || (_cp == 0xFEFF) {
				pos += __utf8Length(_b);
				continue;
			}
			return;
		}
	};

	#region jsDoc
	/// @func    __hexValue(_start, _end, [_bits])
	/// @desc    The value of the digits from _start to _end, `_` skipped.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start  : The first digit's offset
	/// @param   {Real} _end    : The offset after the last digit
	/// @param   {Real} [_bits] : 4 for hex, 1 for binary
	/// @returns {Int64}
	#endregion
	static __hexValue = function(_start, _end, _bits = 4) {
		var _v = int64(0);
		for (var _i = _start; _i < _end; _i++) {
			var _c = __byte(_i);
			if (_c == ord("_")) continue;
			var _d = (_c <= 57) ? _c - 48 : ((_c <= 70) ? _c - 55 : _c - 87);
			_v = (_v << _bits) | _d;
		}
		return _v;
	};

	#region jsDoc
	/// @func    __decimalAtMost(_digits, _limit)
	/// @desc    Whether a decimal number written without leading zeros is at most _limit, compared as text.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {String} _digits : The digits
	/// @param   {String} _limit  : The limit's digits
	/// @returns {Bool}
	#endregion
	static __decimalAtMost = function(_digits, _limit) {
		if (string_length(_digits) != string_length(_limit)) return string_length(_digits) < string_length(_limit);
		return (_digits <= _limit);
	};

	#region jsDoc
	/// @func    __push(_kind, _type, _start, _value, [_ty])
	/// @desc    Appends a token from _start to `pos` and returns its kind; notes whether the last token other than a
	///          line break, comment or region is `.`.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real}   _kind  : __GMLC_TokenKind_* of the token
	/// @param   {Real}   _type  : __GMLC_TokenType_* of the token
	/// @param   {Real}   _start : Byte offset of the token
	/// @param   {Any}    _value : The token's value
	/// @param   {String} [_ty]  : "real", "int64" or "color" for a number
	/// @returns {Real}
	#endregion
	static __push = function(_kind, _type, _start, _value, _ty = undefined) {
		array_push(tokens, new __GMLC_create_token(_type, __gmlc_buffer_text(buf, _start, pos), _value, file_id, _start, pos, _kind, _ty));
		if (_kind != __GMLC_TokenKind_Newline) && (_kind != __GMLC_TokenKind_Comment) && (_kind != __GMLC_TokenKind_Region) {
			after_dot = (_kind == __GMLC_TokenKind_Op) && (_value == ".");
		}
		return _kind;
	};

	#region jsDoc
	/// @func    __pushOp(_start, _value)
	/// @desc    Appends an operator or punctuation token and returns its kind.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real}   _start : Byte offset of the token
	/// @param   {String} _value : The operator it stands for
	/// @returns {Real}
	#endregion
	static __pushOp = function(_start, _value) {
		var _type = __GMLC_TokenType_Operator;
		switch (_value) {
			case "(": case ")": case "[": case "]": case "{": case "}": case ",": case ";": case ":": case ".":
			case "[|": case "[?": case "[#": case "[$": case "[@":
				_type = __GMLC_TokenType_Punctuation;
			break;
		}
		return __push(__GMLC_TokenKind_Op, _type, _start, _value);
	};

	#region jsDoc
	/// @func    __illegal(_code, _start, [_args])
	/// @desc    Reports _code and appends an Illegal token from _start to `pos`.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {String}        _code   : The diagnostic's code
	/// @param   {Real}          _start  : Byte offset of the token
	/// @param   {Array<String>} [_args] : The values the message's template takes
	/// @returns {Real}
	#endregion
	static __illegal = function(_code, _start, _args = undefined) {
		__report(_code, _start, pos, _args);
		return __push(__GMLC_TokenKind_Illegal, __GMLC_TokenType_Illegal, _start, undefined);
	};

	#region jsDoc
	/// @func    __report(_code, _start, _end, [_args])
	/// @desc    Records a diagnostic for the bytes from _start to _end.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {String}        _code   : The code
	/// @param   {Real}          _start  : First byte
	/// @param   {Real}          _end    : Byte after the last
	/// @param   {Array<String>} [_args] : The values the message's template takes
	#endregion
	static __report = function(_code, _start, _end, _args = undefined) {
		array_push(diagnostics, new GMLC_Diagnostic(_code, new GMLC_Span(file_id, _start, _end), _args));
	};
	#endregion
	#endregion
}

#region Token records
#region jsDoc
/// @func    __GMLC_ProgramTokens(_tokens, _file)
/// @desc    The lexer's output for one file: its tokens, its file and the declaration tables the preprocessor fills.
/// @param   {Array<Struct>}          _tokens : The tokens
/// @param   {Struct.GMLC_SourceFile} _file   : The file
/// @returns {Struct}
#endregion
function __GMLC_ProgramTokens(_tokens, _file) constructor {
	file = _file;
	eof = undefined; // not in tokens
	macros  = [];
	enums   = [];
	regions = [];
	pragmas = [];

	tokens = _tokens;
	file_name = _file.name;
}

#region jsDoc
/// @func    __GMLC_create_token(_type, _name, _value, _file, _start, _end, [_kind], [_ty])
/// @desc    A token: type, source text (name), value, byte range, kind and the type of a number's value.
/// @param   {Real}   _type   : __GMLC_TokenType_* of the token
/// @param   {String} _name   : Source text
/// @param   {Any}    _value  : Value
/// @param   {Real}   _file   : File number in the source table
/// @param   {Real}   _start  : First byte
/// @param   {Real}   _end    : Byte after the last
/// @param   {Real}   [_kind] : __GMLC_TokenKind_* of the token
/// @param   {String} [_ty]   : "real", "int64" or "color" for a number
/// @returns {Struct}
#endregion
function __GMLC_create_token(_type, _name, _value, _file, _start, _end, _kind = undefined, _ty = undefined) constructor {
	type   = _type;
	name   = _name;
	value  = _value;
	file   = _file;
	start  = _start;
	self[$ "end"] = _end; // `end` is a keyword outside of `[$ ]` and `.`
	kind   = _kind;
	ty     = _ty;

	#region jsDoc
	/// @func    toString()
	/// @desc    The token as text, for debugging.
	/// @self    __GMLC_create_token
	/// @returns {String}
	#endregion
	static toString = function() {
		return $"\{type: \"{type}\", name: \"{name}\", value: \"{value}\", file: {file}, start: {start}\}"
	}
};
#endregion

#region Character classes
#region jsDoc
/// @func    __char_is_digit(char)
/// @desc    Whether a character code is a decimal digit.
/// @param   {Real} char : Character code
/// @returns {Bool}
/// @ignore
#endregion
function __char_is_digit(char) {
	return (char >= ord("0") && char <= ord("9"));
}

#region jsDoc
/// @func    __char_is_alphabetic(char)
/// @desc    Whether a character code can start a name: a letter or `_`.
/// @param   {Real} char : Character code
/// @returns {Bool}
/// @ignore
#endregion
function __char_is_alphabetic(char) {
	return (char >= ord("A") && char <= ord("Z"))
		|| (char >= ord("a") && char <= ord("z"))
		|| (char == ord("_"));
}

#region jsDoc
/// @func    __char_is_alphanumeric(char)
/// @desc    Whether a character code can be part of a name: a letter, a digit or `_`.
/// @param   {Real} char : Character code
/// @returns {Bool}
/// @ignore
#endregion
function __char_is_alphanumeric(char) {
	return __char_is_alphabetic(char) || __char_is_digit(char);
}

#region jsDoc
/// @func    __char_is_hex(char)
/// @desc    Whether a character code is a hexadecimal digit.
/// @param   {Real} char : Character code
/// @returns {Bool}
/// @ignore
#endregion
function __char_is_hex(char) {
	return __char_is_digit(char)
		|| (char >= ord("A") && char <= ord("F"))
		|| (char >= ord("a") && char <= ord("f"));
}
#endregion
