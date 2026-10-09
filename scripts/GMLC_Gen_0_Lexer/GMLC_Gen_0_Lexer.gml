#region Lexer
// GMLC_Gen_0_Lexer: GML source text to tokens, a pure function of the source bytes that never reads the environment.
// Bad input becomes an Illegal token plus a diagnostic; the first error is thrown once the whole file is lexed.
// Tokens carry kind, file, byte range and ty, plus the type, name and value the later stages read; lines and
// columns come from the file's GMLC_SourceFile when needed.

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

#region jsDoc
/// @func    GMLC_Gen_0_Lexer(_env)
/// @desc    Lexer stage. `initialize(source, fileName)` then `parseAll()` returns the program token record that the
///          preprocessor reads. The environment is kept only so the stage API stays the same; it is never read.
/// @param   {Struct.GMLC_Env} _env : The environment that owns this stage
/// @returns {Struct.GMLC_Gen_0_Lexer}
#endregion
function GMLC_Gen_0_Lexer(_env) constructor {
	env = _env;
	
	buf = undefined;        // normalised source, buffer_u8
	len = 0;                // its length in bytes
	pos = 0;                // current byte offset
	scratch = buffer_create(256, buffer_grow, 1);
	
	fileName = "input";
	fileId = 0;             // number of the file in the compile's source table
	lineStarts = [0];       // byte offset of the start of every line
	hadBom = false;
	crlfDominant = false;
	
	tokens = [];            // tokens for the preprocessor (no Eof)
	eofToken = undefined;
	diagnostics = [];       // GMLC_Diagnostic records of this file
	modes = [];             // template mode stack: one entry per open interpolation, its count of open `{`
	program = undefined;
	
	#region Tables
	static __keywords = {
		"if": true, "then": true, "else": true, "for": true, "while": true, "do": true, "until": true,
		"repeat": true, "switch": true, "case": true, "default": true, "break": true, "continue": true,
		"with": true, "exit": true, "return": true, "var": true, "globalvar": true, "static": true, "enum": true,
		"function": true, "constructor": true, "new": true, "delete": true, "throw": true, "try": true,
		"catch": true, "finally": true,
	};
	// alias words: their canonical operator spelling
	static __aliases = {
		"and": "&&", "or": "||", "xor": "^^", "not": "!", "div": "div", "mod": "mod", "begin": "{", "end": "}",
	};
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    initialize(_source, _fileName, [_fileId])
	/// @desc    Prepares lexing of one file: normalises the source into a byte buffer (BOM removed at offset 0, every
	///          run of CR followed by LF and every other CR becomes LF) and builds the line table.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {String} _source   : Source text
	/// @param   {String} _fileName : Name used in positions and errors
	/// @param   {Real}   [_fileId] : Number of the file in the compile's source table
	#endregion
	static initialize = function(_source, _fileName = "input", _fileId = 0) {
		fileName = _fileName;
		fileId = _fileId;
		tokens = [];
		eofToken = undefined;
		diagnostics = [];
		modes = [];
		pos = 0;
		
		var _rawLen = string_byte_length(_source);
		
		if (buf != undefined) buffer_delete(buf);
		buf = buffer_create(_rawLen + 1, buffer_fixed, 1);
		
		hadBom = (_rawLen >= 3)
			&& (string_byte_at(_source, 1) == 0xEF)
			&& (string_byte_at(_source, 2) == 0xBB)
			&& (string_byte_at(_source, 3) == 0xBF);
		
		// line by line: each line's bytes are written whole, not byte by byte. A run of CR right before a LF is part of
		// that one line break; any other CR is a line break of its own.
		var _crlf = 0;
		var _lf = 0;
		lineStarts = [0];
		var _lines = string_split(_source, "\n");
		if (hadBom) _lines[0] = string_delete(_lines[0], 1, 1);
		var _hasCr = (string_pos("\r", _source) > 0); // most files have none: their lines skip the CR checks
		var _count = array_length(_lines);
		var _l = 0; repeat (_count) {
			var _line = _lines[_l];
			var _broken = (_l < _count - 1); // a LF follows
			var _crs = _hasCr ? string_count("\r", _line) : 0;
			// the run of CR right before the LF, written as that one line break: the line's bytes are written whole
			// and the buffer steps back over them
			var _k = 0;
			if (_crs > 0) && (_broken) {
				var _bytes = string_byte_length(_line);
				while (_k < _bytes) && (string_byte_at(_line, _bytes - _k) == 13) _k++;
			}
			if (_crs > _k) {
				// a CR elsewhere in the line is a line break of its own
				var _parts = string_split(_line, "\r");
				var _p = 0; repeat (array_length(_parts) - _k) {
					if (_p > 0) {
						buffer_write(buf, buffer_u8, 10);
						array_push(lineStarts, buffer_tell(buf));
					}
					buffer_write(buf, buffer_text, _parts[_p]);
				_p++}
			}
			else {
				buffer_write(buf, buffer_text, _line);
				if (_k > 0) buffer_seek(buf, buffer_seek_relative, -_k);
			}
			if (_broken) {
				buffer_write(buf, buffer_u8, 10);
				array_push(lineStarts, buffer_tell(buf));
				if (_k > 0) _crlf++; else _lf++;
			}
		_l++}
		len = buffer_tell(buf);
		crlfDominant = (_crlf > _lf);
		
		program = new __GMLC_ProgramTokens(tokens, new GMLC_SourceFile(fileId, fileName, __text(0, len), lineStarts));
		return self;
	};
	#region jsDoc
	/// @func    parseAll()
	/// @desc    Lexes the whole file. Throws when a diagnostic is an error, after lexing; `program` still holds the
	///          tokens then.
	/// @self    GMLC_Gen_0_Lexer
	/// @returns {Struct} The program token record (tokens, the file's lines and the empty declaration tables)
	#endregion
	static parseAll = function() {
		while (nextToken() != __GMLC_TokenKind_Eof) {}
		program.tokens = tokens;
		program.eof = eofToken;
		
		if (__gmlc_has_errors(diagnostics)) {
			var _sources = new GMLC_SourceTable();
			_sources.add(program.file);
			__gmlc_throw_diagnostics(diagnostics, _sources);
		}
		return program;
	};
	#endregion
	
	#region Token loop
	#region jsDoc
	/// @func    nextToken()
	/// @desc    Lexes one token at `pos` (whitespace before it is skipped) and appends it.
	/// @self    GMLC_Gen_0_Lexer
	/// @returns {Real} The kind of the token
	#endregion
	static nextToken = function() {
		__skipWhitespace();
		var _start = pos;
		if (pos >= len) {
			eofToken = __makeToken(__GMLC_TokenKind_Eof, __GMLC_TokenType_Whitespace, _start, _start, undefined);
			return __GMLC_TokenKind_Eof;
		}
		
		var _b = __byte(pos);
		
		// inside an interpolation, braces are counted so the `}` that ends it is found
		if (array_length(modes) > 0) {
			if (_b == ord("{")) {
				modes[array_length(modes) - 1]++;
				pos++;
				return __pushOp(_start, "{", "{");
			}
			if (_b == ord("}")) {
				if (modes[array_length(modes) - 1] > 0) {
					modes[array_length(modes) - 1]--;
					pos++;
					return __pushOp(_start, "}", "}");
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
					__high = false;
					while (pos < len) {
						var _c = __byte(pos);
						if (_c == 10) break;
						if (_c >= 0x80) __high = true;
						pos++;
					}
					return __push(__GMLC_TokenKind_Comment, __GMLC_TokenType_Comment, _start, __utf8Value(_start, __text(_start, pos)));
				}
				if (_n == ord("*")) {
					pos += 2;
					__high = false;
					var _closed = false;
					while (pos < len) {
						var _c = __byte(pos);
						if (_c == ord("*")) && (__byte(pos + 1) == ord("/")) {
							pos += 2;
							_closed = true;
							break;
						}
						if (_c >= 0x80) __high = true;
						pos++;
					}
					// an unclosed block comment runs to the end of the file
					return __push(__GMLC_TokenKind_Comment, __GMLC_TokenType_Comment, _start, __utf8Value(_start, __text(_start, pos)));
				}
				return lexOperator(_start);
			}
			case ord("\""): return lexString(_start);
			case ord("@"): {
				var _n = __byte(pos + 1);
				if (_n == ord("\"")) || (_n == ord("'")) return lexVerbatim(_start);
				pos++;
				return __illegal(2, _start, ["@"]);
			}
			case ord("$"): {
				var _n = __byte(pos + 1);
				if (_n == ord("\"")) {
					pos += 2;
					return scanTemplateText(_start, true);
				}
				if (__isHex(_n)) return lexNumber(_start);
				pos++;
				return __illegal(2, _start, ["$"]);
			}
			case ord("#"): return lexDirective(_start);
			case ord("'"): {
				// a single-quoted string is not GML: Illegal to the closing quote on this line
				pos++;
				__high = false;
				while (pos < len) && (__byte(pos) != 10) && (__byte(pos) != ord("'")) {
					if (__byte(pos) >= 0x80) __high = true;
					pos++;
				}
				if (pos < len) && (__byte(pos) == ord("'")) pos++;
				__utf8Value(_start, ""); // marks the file when its bytes are not UTF-8
				return __illegal(17, _start);
			}
			case ord("\\"): {
				pos++;
				return __push(__GMLC_TokenKind_Backslash, __GMLC_TokenType_EscapeOperator, _start, "\\");
			}
			case ord("."): {
				if (__isDigit(__byte(pos + 1))) return lexNumber(_start);
				pos++;
				return __pushOp(_start, ".", ".");
			}
			case ord("["): {
				// `[|`, `[?`, `[#`, `[$`, `[@` written together are always accessor tokens, as in GameMaker
				// (`[#ff0000]` and `[$FF]` are refused, and a string right after `[@` keeps its escapes)
				var _n = __byte(pos + 1);
				if (_n == ord("|")) || (_n == ord("?")) || (_n == ord("#")) || (_n == ord("$")) || (_n == ord("@")) {
					pos += 2;
					return __pushOp(_start, "[" + chr(_n), "[" + chr(_n));
				}
				pos++;
				return __pushOp(_start, "[", "[");
			}
		}
		
		if (__isDigit(_b)) return lexNumber(_start);
		if (__isWordStart(_b)) return lexWord(_start);
		if (_b < 128) return lexOperator(_start);
		
		// non-ASCII outside strings and comments
		var _cp = __decode(pos);
		if (_cp < 0) {
			pos++;
			return __illegal(1, _start);
		}
		pos += __utf8Length(_b);
		return __illegal(2, _start, [__text(_start, pos)]);
	};
	#endregion
	
	#region Words
	#region jsDoc
	/// @func    lexWord(_start)
	/// @desc    Lexes `[A-Za-z_][A-Za-z0-9_]*`: a keyword, an alias word (an operator) or an identifier. After `.`
	///          every word is an identifier (`s.end`, `s.repeat`), as in GameMaker. Constants (`true`, `false`,
	///          `undefined`, `pi`, ...) are identifiers; the parser resolves them.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of the word
	/// @returns {Real} The kind of the token
	#endregion
	static lexWord = function(_start) {
		// the word's bytes are read in place: this runs for every byte of every name (__isWordByte, __byte)
		var _p = pos;
		while (_p < len) {
			var _b = buffer_peek(buf, _p, buffer_u8);
			if (!(((_b >= 97) && (_b <= 122)) || ((_b >= 65) && (_b <= 90)) || (_b == 95) || ((_b >= 48) && (_b <= 57)))) break;
			_p++;
		}
		pos = _p;
		var _word = __text(_start, pos);
		
		// the last token that is not a line break, comment or region
		var _afterDot = false;
		var _i = array_length(tokens) - 1;
		while (_i >= 0) {
			var _prev = tokens[_i];
			var _k = _prev.kind;
			if (_k != __GMLC_TokenKind_Newline) && (_k != __GMLC_TokenKind_Comment) && (_k != __GMLC_TokenKind_Region) {
				_afterDot = (_k == __GMLC_TokenKind_Op) && (_prev.value == ".");
				break;
			}
			_i--;
		}
		if (!_afterDot) {
			if (__gmlc_struct_has(__keywords, _word)) {
				return __push(__GMLC_TokenKind_Keyword, __GMLC_TokenType_Keyword, _start, _word);
			}
			var _alias = __gmlc_struct_get(__aliases, _word);
			if (_alias != undefined) {
				return __pushOp(_start, _alias, _word);
			}
		}
		return __push(__GMLC_TokenKind_Identifier, __GMLC_TokenType_Identifier, _start, _word);
	};
	#endregion
	
	#region Directives
	#region jsDoc
	/// @func    lexDirective(_start)
	/// @desc    Lexes a token starting with `#`: `#macro`, `#region` / `#endregion` (one token to the end of the line,
	///          the title is free text), a colour `#RRGGBB`, or an error for any other directive.
	///          GameMaker accepts directives after code on the same line.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of `#`
	/// @returns {Real} The kind of the token
	#endregion
	static lexDirective = function(_start) {
		var _i = pos + 1;
		while (_i < len) && (__isWordByte(__byte(_i))) _i++;
		var _word = __text(pos + 1, _i);
		
		if (_word == "macro") {
			pos = _i;
			var _token = __makeToken(__GMLC_TokenKind_MacroDirective, __GMLC_TokenType_Keyword, _start, pos, "#macro");
			array_push(tokens, _token);
			return __GMLC_TokenKind_MacroDirective;
		}
		if (_word == "region") || (_word == "endregion") {
			while (pos < len) && (__byte(pos) != 10) pos++;
			return __push(__GMLC_TokenKind_Region, __GMLC_TokenType_Region, _start, _word);
		}
		
		// a colour: exactly six hex digits
		var _h = pos + 1;
		while (_h < len) && (__isHex(__byte(_h))) _h++;
		if (_h > pos + 1) && (_h == _i) {
			if (_h - (pos + 1) == 6) {
				pos = _h;
				var _rgb = __hexValue(_start + 1, _h);
				var _r = (_rgb >> 16) & 0xFF;
				var _g = (_rgb >> 8) & 0xFF;
				var _b = _rgb & 0xFF;
				var _token = __makeToken(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, pos, real(_r + _g * 256 + _b * 65536));
				_token.ty = "colour";
				array_push(tokens, _token);
				return __GMLC_TokenKind_Number;
			}
			pos = _h;
			return __illegal(5, _start);
		}
		
		if (_word != "") {
			while (pos < len) && (__byte(pos) != 10) pos++;
			return __illegal(3, _start, [_word]);
		}
		pos++;
		return __illegal(2, _start, ["#"]);
	};
	#endregion
	
	#region Numbers
	#region jsDoc
	/// @func    lexNumber(_start)
	/// @desc    Lexes a decimal, `0x` / `$` hex or `0b` binary literal and types it as GameMaker does:
	///          whole decimals above 2^31-1 are int64 up to 2^63-1; hex and binary above 2^31-1
	///          are int64 unless their 64-bit value fits in 32 bits (`$FFFFFFFFFFFFFFFF` is -1); `_` may follow any
	///          digit. A number running into a letter or a second `.` is malformed.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of the literal
	/// @returns {Real} The kind of the token
	#endregion
	static lexNumber = function(_start) {
		var _b = __byte(pos);
		
		// hex and binary
		var _radix = 0;
		var _digits = pos;
		if (_b == ord("$")) {
			_radix = 16;
			_digits = pos + 1;
		}
		else if (_b == ord("0")) && (__byte(pos + 1) == ord("x")) {
			_radix = 16;
			_digits = pos + 2;
		}
		else if (_b == ord("0")) && (__byte(pos + 1) == ord("b")) {
			_radix = 2;
			_digits = pos + 2;
		}
		if (_radix != 0) {
			var _i = _digits;
			var _count = 0;
			while (_i < len) {
				var _c = __byte(_i);
				if (_c == ord("_")) { _i++; continue; }
				if (_radix == 16) && (__isHex(_c)) { _count++; _i++; continue; }
				if (_radix == 2) && (_c == ord("0") || _c == ord("1")) { _count++; _i++; continue; }
				break;
			}
			pos = _i;
			if (_count == 0) || (__isWordByte(__byte(pos))) {
				while (pos < len) && (__isWordByte(__byte(pos)) || __byte(pos) == ord(".")) pos++;
				return __illegal(6, _start, [__text(_start, pos)]);
			}
			if ((_radix == 16) && (_count > 16)) || ((_radix == 2) && (_count > 64)) {
				return __illegal(7, _start);
			}
			var _v = (_radix == 16) ? __hexValue(_digits, pos) : __binaryValue(_digits, pos);
			var _token;
			if (_v >= 0) && (_v <= 2147483647) {
				_token = __makeToken(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, pos, real(_v));
				_token.ty = "real";
			}
			else if (_v >= -2147483648) && (_v < 0) {
				// the 64-bit value fits in 32 bits: a real
				_token = __makeToken(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, pos, real(_v));
				_token.ty = "real";
			}
			else {
				_token = __makeToken(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, pos, _v);
				_token.ty = "int64";
			}
			array_push(tokens, _token);
			return __GMLC_TokenKind_Number;
		}
		
		// decimal
		var _dot = false;
		while (pos < len) {
			var _c = __byte(pos);
			if (__isDigit(_c)) || (_c == ord("_")) { pos++; continue; }
			if (_c == ord(".")) && (!_dot) { _dot = true; pos++; continue; }
			break;
		}
		if (__isWordByte(__byte(pos))) || ((__byte(pos) == ord(".")) && __isDigit(__byte(pos + 1))) {
			while (pos < len) && (__isWordByte(__byte(pos)) || __byte(pos) == ord(".")) pos++;
			return __illegal(6, _start, [__text(_start, pos)]);
		}
		var _text = string_replace_all(__text(_start, pos), "_", "");
		var _token;
		if (_dot) {
			_token = __makeToken(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, pos, real(_text));
			_token.ty = "real";
		}
		else {
			// strip leading zeros to compare magnitudes as text
			var _digitsText = _text;
			while (string_length(_digitsText) > 1) && (string_char_at(_digitsText, 1) == "0") _digitsText = string_delete(_digitsText, 1, 1);
			if (__decimalAtMost(_digitsText, "2147483647")) {
				_token = __makeToken(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, pos, real(_digitsText));
				_token.ty = "real";
			}
			else if (__decimalAtMost(_digitsText, "9223372036854775807")) {
				_token = __makeToken(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, pos, int64(_digitsText));
				_token.ty = "int64";
			}
			else {
				__report(8, _start, pos, [__text(_start, pos)]);
				_token = __makeToken(__GMLC_TokenKind_Number, __GMLC_TokenType_Number, _start, pos, real(_digitsText));
				_token.ty = "real";
			}
		}
		array_push(tokens, _token);
		return __GMLC_TokenKind_Number;
	};
	#endregion
	
	#region Strings
	#region jsDoc
	/// @func    lexString(_start)
	/// @desc    Lexes `"..."` with escapes. A raw line break or the end of the file ends it with an
	///          error.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of the opening quote
	/// @returns {Real} The kind of the token
	#endregion
	static lexString = function(_start) {
		pos++;
		var _cooked = __cookText(_start, ord("\""), false);
		var _end = __cookEnd;
		if (_end == "quote") {
			pos++;
		}
		else if (_end == "newline") {
			__report(10, _start, pos);
		}
		else {
			__report(9, _start, pos);
		}
		var _token = __makeToken(__GMLC_TokenKind_String, __GMLC_TokenType_String, _start, pos, __utf8Value(_start, _cooked));
		array_push(tokens, _token);
		return __GMLC_TokenKind_String;
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
		__high = false;
		while (pos < len) {
			var _c = __byte(pos);
			if (_c == _quote) break;
			if (_c >= 0x80) __high = true;
			pos++;
		}
		var _value = __text(_from, pos);
		if (pos < len) {
			pos++;
		}
		else {
			__report(9, _start, pos);
		}
		var _token = __makeToken(__GMLC_TokenKind_String, __GMLC_TokenType_String, _start, pos, __utf8Value(_start, _value));
		array_push(tokens, _token);
		return __GMLC_TokenKind_String;
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
		var _cooked = __cookText(_start, ord("\""), true);
		var _end = __cookEnd;
		var _kind, _type;
		if (_end == "brace") {
			pos++;
			array_push(modes, 0);
			_kind = _isStart ? __GMLC_TokenKind_TemplateHead : __GMLC_TokenKind_TemplateMiddle;
			_type = _isStart ? __GMLC_TokenType_TemplateStringBegin : __GMLC_TokenType_TemplateStringMiddle;
		}
		else {
			if (_end == "quote") {
				pos++;
			}
			else if (_end == "newline") {
				__report(14, _start, pos);
			}
			else {
				__report(13, _start, pos);
			}
			// a template with no interpolation is a plain string to the parser
			_kind = _isStart ? __GMLC_TokenKind_TemplateFull : __GMLC_TokenKind_TemplateTail;
			_type = _isStart ? __GMLC_TokenType_String : __GMLC_TokenType_TemplateStringEnd;
		}
		var _token = __makeToken(_kind, _type, _start, pos, __utf8Value(_start, _cooked));
		array_push(tokens, _token);
		return _kind;
	};
	
	__cookEnd = "";
	__high = false; // a byte of 0x80 or more was in the text the last string, template text or comment scan read
	
	#region jsDoc
	/// @func    __utf8Value(_start, _value)
	/// @desc    The value of a string, template text or comment token that ends at `pos`. Any bytes are allowed there;
	///          when they are not all UTF-8, the value has U+FFFD for each bad byte, so the
	///          token's value stays text.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real}   _start : Byte offset of the token
	/// @param   {String} _value : The token's value
	/// @returns {String}
	#endregion
	static __utf8Value = function(_start, _value) {
		if (!__high) return _value;
		var _p = _start;
		while (_p < pos) {
			var _n = __GMLC_utf8Length(buf, _p, len);
			if (_n == 0) {
				program.file.invalidUtf8 = true; // its dumps then replace those bytes
				return __GMLC_lossyUtf8(_value);
			}
			_p += _n;
		}
		return _value;
	};
	#region jsDoc
	/// @func    __cookText(_start, _quote, _template)
	/// @desc    Reads string text from `pos` and returns it with escapes applied, leaving `pos` on what ended it and
	///          `__cookEnd` set to "quote", "brace" (templates only), "newline" or "eof". After `\0` the rest of
	///          the text is dropped, as GameMaker strings end at the first NUL.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start    : Byte offset of the literal, for diagnostics
	/// @param   {Real} _quote    : Byte that closes the text
	/// @param   {Bool} _template : true in a template string, where `{` opens an interpolation
	/// @returns {String}
	#endregion
	static __cookText = function(_start, _quote, _template) {
		var _out = "";
		var _run = pos;
		var _ended = false; // after \0
		__high = false;
		while (true) {
			if (pos >= len) { __cookEnd = "eof"; break; }
			var _c = __byte(pos);
			if (_c == _quote) { __cookEnd = "quote"; break; }
			if (_c == 10) { __cookEnd = "newline"; break; }
			if (_template) && (_c == ord("{")) { __cookEnd = "brace"; break; }
			if (_c != ord("\\")) {
				if (_c >= 0x80) __high = true;
				pos++;
				continue;
			}
			
			if (!_ended) _out += __text(_run, pos);
			pos++;
			var _piece = __readEscape(_start);
			if (__escapeEndsString) _ended = true;
			if (!_ended) _out += _piece;
			_run = pos;
		}
		if (!_ended) _out += __text(_run, pos);
		return _out;
	};
	
	__escapeEndsString = false;
	#region jsDoc
	/// @func    __readEscape(_start)
	/// @desc    Reads the escape after a backslash at `pos` and returns the text it stands for:
	///          x takes exactly 2 hex digits; u every following hex digit, at most 0x10FFFF and no surrogate; octal 1
	///          to 3 digits below 256, and code 0 ends the string (`__escapeEndsString`); a backslash before a line
	///          break joins the lines; n r t b f v a are control characters; any other character stands for itself.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : Byte offset of the literal, for diagnostics
	/// @returns {String}
	#endregion
	static __readEscape = function(_start) {
		__escapeEndsString = false;
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
				if (__isHexDigit(__byte(pos))) && (__isHexDigit(__byte(pos + 1))) {
					var _v = __hexValue(pos, pos + 2);
					pos += 2;
					return __escapeChar(_v);
				}
				__report(12, _escStart, pos, [__text(_escStart, pos)]);
				return "";
			}
			case ord("u"): {
				pos++;
				var _from = pos;
				while (pos < len) && (__isHexDigit(__byte(pos))) pos++;
				if (pos == _from) || (pos - _from > 8) {
					__report(12, _escStart, pos, [__text(_escStart, pos)]);
					return "";
				}
				var _v = __hexValue(_from, pos);
				if (_v > 0x10FFFF) || ((_v >= 0xD800) && (_v <= 0xDFFF)) {
					__report(12, _escStart, pos, [__text(_escStart, pos)]);
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
				__report(12, _escStart, pos, [__text(_escStart, pos)]);
				return "";
			}
			return __escapeChar(_v);
		}
		// any other character stands for itself (one code point); a byte that is not UTF-8 is marked like any other
		if (_c >= 0x80) __high = true;
		var _l = min(__utf8Length(_c), len - pos);
		var _piece = __text(pos, pos + _l);
		pos += _l;
		return _piece;
	};
	#region jsDoc
	/// @func    __escapeChar(_code)
	/// @desc    Returns chr(_code), except that code 0 ends the string (GameMaker strings stop at the first NUL) and
	///          gives "".
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _code : Character code
	/// @returns {String}
	#endregion
	static __escapeChar = function(_code) {
		if (_code == 0) {
			__escapeEndsString = true;
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
		var _c = chr(__byte(pos));
		var _n = (pos + 1 < len) ? chr(__byte(pos + 1)) : "";
		var _n2 = (pos + 2 < len) ? chr(__byte(pos + 2)) : "";
		var _two = _c + _n;
		
		if (_two == "<<" || _two == ">>") && (_n2 == "=") {
			pos += 3;
			return __illegal(16, _start, [_two + "="]);
		}
		if (_two == "??") && (_n2 == "=") {
			pos += 3;
			return __pushOp(_start, "??=", "??=");
		}
		switch (_two) {
			case "==": case "!=": case "<=": case ">=": case "<<": case ">>": case "++": case "--":
			case "&&": case "||": case "^^": case "+=": case "-=": case "*=": case "/=": case "%=":
			case "&=": case "|=": case "^=": case "??":
				pos += 2;
				return __pushOp(_start, _two, _two);
			case "<>":
				pos += 2;
				return __pushOp(_start, "!=", "<>");
			case ":=":
				pos += 2;
				return __pushOp(_start, "=", ":=");
		}
		switch (_c) {
			case "(": case ")": case "]": case "{": case "}": case ",": case ";": case ":": case "?":
			case "=": case "<": case ">": case "+": case "-": case "*": case "/": case "!": case "~":
			case "&": case "|": case "^":
				pos++;
				return __pushOp(_start, _c, _c);
			case "%":
				pos++;
				return __pushOp(_start, "mod", "%");
		}
		pos++;
		return __illegal(2, _start, [_c]);
	};
	#endregion
	
	#region Helpers
	static __byte = function(_p) {
		return (_p < len) ? buffer_peek(buf, _p, buffer_u8) : -1;
	};
	static __isDigit = function(_b) { return (_b >= 48) && (_b <= 57); };
	static __isHexDigit = function(_b) {
		return ((_b >= 48) && (_b <= 57)) || ((_b >= 65) && (_b <= 70)) || ((_b >= 97) && (_b <= 102));
	};
	static __isHex = function(_b) { return __isHexDigit(_b); };
	static __isWordStart = function(_b) {
		return ((_b >= 65) && (_b <= 90)) || ((_b >= 97) && (_b <= 122)) || (_b == 95);
	};
	// the same byte ranges are read in place in lexWord, where they are tested for every byte of every name
	static __isWordByte = function(_b) { return __isWordStart(_b) || __isDigit(_b); };
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
	/// @desc    Skips whitespace other than LF: the code points GameMaker's manual lists (tab to carriage return,
	///          space, U+0085, U+00A0, U+1680, U+180E, U+2000 to U+200D, U+2028, U+2029, U+202F, U+205F, U+2060,
	///          U+3000, U+FEFF).
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
	/// @func    __text(_start, _end)
	/// @desc    Returns the source text between two byte offsets.
	/// @self    GMLC_Gen_0_Lexer
	/// @param   {Real} _start : First byte
	/// @param   {Real} _end   : Byte after the last
	/// @returns {String}
	#endregion
	static __text = function(_start, _end) {
		var _n = _end - _start;
		if (_n <= 0) return "";
		if (buffer_get_size(scratch) < _n + 1) buffer_resize(scratch, _n + 1);
		buffer_copy(buf, _start, _n, scratch, 0);
		buffer_poke(scratch, _n, buffer_u8, 0);
		buffer_seek(scratch, buffer_seek_start, 0);
		return buffer_read(scratch, buffer_string);
	};
	static __hexValue = function(_start, _end) {
		var _v = int64(0);
		for (var _i = _start; _i < _end; _i++) {
			var _c = __byte(_i);
			if (_c == ord("_")) continue;
			var _d = (_c <= 57) ? _c - 48 : ((_c <= 70) ? _c - 55 : _c - 87);
			_v = (_v << 4) | _d;
		}
		return _v;
	};
	static __binaryValue = function(_start, _end) {
		var _v = int64(0);
		for (var _i = _start; _i < _end; _i++) {
			var _c = __byte(_i);
			if (_c == ord("_")) continue;
			_v = (_v << 1) | (_c - 48);
		}
		return _v;
	};
	static __decimalAtMost = function(_digits, _limit) {
		if (string_length(_digits) != string_length(_limit)) return string_length(_digits) < string_length(_limit);
		return (_digits <= _limit);
	};
	static __makeToken = function(_kind, _type, _start, _end, _value) {
		var _token = new __GMLC_create_token(_type, __text(_start, _end), _value, fileId, _start, _end);
		_token.kind = _kind;
		_token.ty = undefined;
		return _token;
	};
	static __push = function(_kind, _type, _start, _value) {
		array_push(tokens, __makeToken(_kind, _type, _start, pos, _value));
		return _kind;
	};
	static __pushOp = function(_start, _value, _text) {
		// the parser reads brackets, braces, `,`, `;`, `:` and `.` as punctuation and the rest as operators
		var _type = __GMLC_TokenType_Operator;
		switch (_value) {
			case "(": case ")": case "[": case "]": case "{": case "}": case ",": case ";": case ":": case ".":
			case "[|": case "[?": case "[#": case "[$": case "[@":
				_type = __GMLC_TokenType_Punctuation;
			break;
		}
		var _token = __makeToken(__GMLC_TokenKind_Op, _type, _start, pos, _value);
		array_push(tokens, _token);
		return __GMLC_TokenKind_Op;
	};
	static __illegal = function(_code, _start, _args = undefined) {
		__report(_code, _start, pos, _args);
		array_push(tokens, __makeToken(__GMLC_TokenKind_Illegal, __GMLC_TokenType_Illegal, _start, pos, undefined));
		return __GMLC_TokenKind_Illegal;
	};
	static __report = function(_code, _start, _end, _args = undefined) {
		if (_code == 1) program.file.invalidUtf8 = true; // its dumps then replace those bytes
		var _name = "GMLC" + string_replace_all(string_format(_code, 4, 0), " ", "0");
		array_push(diagnostics, new GMLC_Diagnostic(_name, new GMLC_Span(fileId, _start, _end), _args));
	};
	#endregion
}
#endregion

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
	eof = undefined; // the Eof token, which the token list leaves out
	// filled by the preprocessor
	macros  = [];
	enums   = [];
	regions = [];
	pragmas = [];
	
	tokens = _tokens;
	fileName = _file.name;
}
#region jsDoc
/// @func    __GMLC_create_token(_type, _name, _value, _file, _start, _end)
/// @desc    A token as the preprocessor and parser read it: type, source text (name), value and where it is.
/// @param   {Real}   _type  : __GMLC_TokenType_* of the token
/// @param   {String} _name  : Source text
/// @param   {Any}    _value : Value
/// @param   {Real}   _file  : Number of the file in the compile's source table
/// @param   {Real}   _start : First byte
/// @param   {Real}   _end   : Byte after the last
/// @returns {Struct}
#endregion
function __GMLC_create_token(_type, _name, _value, _file, _start, _end) constructor {
	type   = _type;
	name   = _name;
	value  = _value;
	file   = _file;
	start  = _start;
	self[$ "end"] = _end; // `end` is a keyword outside of `[$ ]` and `.`
	
	static toString = function() {
		return $"\{type: \"{type}\", name: \"{name}\", value: \"{value}\", file: {file}, start: {start}\}"
	}
};
#endregion

#region Character classes
/// @ignore
function __char_is_digit(char) {
	return (char >= ord("0") && char <= ord("9"));
}
/// @ignore
function __char_is_alphabetic(char) {
	return (char >= ord("A") && char <= ord("Z"))
		|| (char >= ord("a") && char <= ord("z"))
		|| (char == ord("_"));
}
/// @ignore
function __char_is_alphanumeric(char) {
	return __char_is_alphabetic(char) || __char_is_digit(char);
}
#endregion
