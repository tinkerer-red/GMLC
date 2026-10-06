#region Parser.gml
// GMLC_Gen_2_Parser: the preprocessed tokens of one file to a syntax tree.
// One node kind per construct, every body a Block, names left unresolved (the resolver binds them), nothing lowered.
// It reads only the file's tokens and declaration tables, never the environment. Binary operators are parsed by
// precedence climbing over these tiers, loosest first, in the order GameMaker uses (measured):
//   ?:   ??   ||   &&   ^^   == != < <= > >= (and `=` as equality)   | & ^   << >>   + -   * / div mod   prefix   postfix
// `=` assigns only at the start of a statement, in declarations and in parameter defaults; anywhere else it compares.
// Every node gets the span of its tokens (a token from a macro or an enum reference counts at its use) and, when its
// first and last tokens came from the same macro use or enum reference, that origin. Each `@NoOp` pragma gets as
// its target the first statement that starts after it and every other statement that starts on that statement's
// line: the whole next line, and with it the bodies of the statements on it (a function, an if, a loop).

function GMLC_Gen_2_Parser(_env) constructor {
	#region Config
	static maxDepth = 256; // syntax nested deeper than this is an error
	#endregion

	env = _env; // kept so the stage API stays the same; never read
	
	program = undefined;
	tokens = [];
	tokenCount = 0;
	tokenIndex = 0;
	currentToken = undefined;
	previousToken = undefined;
	script = undefined;
	depth = 0;
	pragmaIndex = 0; // the first pragma that has no statement yet
	openTarget = undefined; // the target of the last pragmas while statements on its line may still extend it
	
	#region Tables
	// the tier of each binary operator, tightest highest; `=` there compares
	static __binaryTiers = {
		"??": 1, "||": 2, "&&": 3, "^^": 4,
		"==": 5, "!=": 5, "<": 5, "<=": 5, ">": 5, ">=": 5, "=": 5,
		"|": 6, "&": 6, "^": 6,
		"<<": 7, ">>": 7,
		"+": 8, "-": 8,
		"*": 9, "/": 9, "div": 9, "mod": 9,
	};
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    initialize(_program)
	/// @desc    Prepares parsing of one preprocessed file.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Struct} _program : The preprocessor's program record (tokens, file and declaration tables)
	#endregion
	static initialize = function(_program) {
		program = _program;
		tokens = _program.tokens;
		tokenCount = array_length(tokens);
		tokenIndex = 0;
		currentToken = (tokenCount > 0) ? tokens[0] : undefined;
		previousToken = undefined;
		depth = 0;
		pragmaIndex = 0;
		openTarget = undefined;
		
		var _file = _program.file;
		script = new ASTScript(new GMLC_Span(_file.fileId, 0, _file.byteLength()), []);
		
		// the declaration tables of the file, as nodes
		var _i = 0; repeat (array_length(_program.macros)) {
			var _def = _program.macros[_i];
			array_push(script.macros, new ASTMacroDecl(_def.span, _def.name, _def.config, _def.text));
		_i++}
		_i = 0; repeat (array_length(_program.enums)) {
			var _def = _program.enums[_i];
			var _members = [];
			var _m = 0; repeat (array_length(_def.members)) {
				var _member = _def.members[_m];
				array_push(_members, new ASTEnumMember(_member.span, _member.name, _member.value, _member.init != undefined));
			_m++}
			array_push(script.enums, new ASTEnumDecl(_def.span, _def.name, _members));
		_i++}
		script.regions = _program.regions;
		script.pragmas = _program.pragmas;
	};
	
	#region jsDoc
	/// @func    parseAll()
	/// @desc    Parses the whole file. Throws the first syntax error.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTScript}
	#endregion
	static parseAll = function() {
		while (currentToken != undefined) {
			array_push(script.body, parseStatement());
		}
		return script;
	};

	static cleanup = function() {};
	#endregion

	#region Tokens
	static advance = function() {
		previousToken = currentToken;
		tokenIndex++;
		currentToken = (tokenIndex < tokenCount) ? tokens[tokenIndex] : undefined;
	};
	
	static peek = function() {
		return (tokenIndex + 1 < tokenCount) ? tokens[tokenIndex + 1] : undefined;
	};
	
	static isPunctuation = function(_value) {
		return (currentToken != undefined) && (currentToken.type == __GMLC_TokenType_Punctuation) && (currentToken.value == _value);
	};
	
	static isOperator = function(_value) {
		return (currentToken != undefined) && (currentToken.type == __GMLC_TokenType_Operator) && (currentToken.value == _value);
	};
	
	static isKeyword = function(_value) {
		return (currentToken != undefined) && (currentToken.type == __GMLC_TokenType_Keyword) && (currentToken.value == _value);
	};
	
	#region jsDoc
	/// @func    expect(_type, _value)
	/// @desc    Consumes the current token when it is the given one, otherwise throws GMLC1002.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Real}   _type  : Token type
	/// @param   {String} _value : Token value
	#endregion
	static expect = function(_type, _value) {
		if (currentToken == undefined) {
			__error("GMLC1002", $"expected {_value}, found the end of the file");
		}
		if (currentToken.type != _type) || (currentToken.value != _value) {
			__error("GMLC1002", $"expected {_value}, found {currentToken.name}");
		}
		advance();
	};

	static optional = function(_type, _value) {
		if (currentToken != undefined) && (currentToken.type == _type) && (currentToken.value == _value) {
			advance();
			return true;
		}
		return false;
	};

	#region jsDoc
	/// @func    __error(_code, _message, [_token])
	/// @desc    Throws a syntax error at a token (the current one, or the last one at the end of the file).
	/// @self    GMLC_Gen_2_Parser
	#endregion
	static __error = function(_code, _message, _token = undefined) {
		_token ??= currentToken ?? previousToken;
		var _sources = program[$ "sources"];
		var _at;
		if (_token == undefined) {
			_at = { fileName: program.file.name, line: 1, column: 1, lineString: "" };
		}
		else if (_sources != undefined) {
			_at = _sources.position(_token);
		}
		else {
			_at = program.file.position(_token.start);
		}
		throw_gmlc_error(_code + ": " + _message, _at.line, _at.lineString, _at.column, _at.fileName);
	};
	#endregion

	#region Spans and origins
	// Where a token counts in a span: at its use when a macro or an enum reference made it (a token has the fields
	// of a span: file, start, end)
	static __site = function(_t) {
		var _origin = _t[$ "origin"];
		return (_origin != undefined) ? _origin.use_span : _t;
	};
	
	#region jsDoc
	/// @func    finish(_node, _first)
	/// @desc    Gives a node the span from its first token to the last token consumed, and the origin of its tokens when
	///          the first and the last came from the same macro use or enum reference.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Struct}         _first : Its first token
	/// @returns {Struct.ASTNode}
	#endregion
	static finish = function(_node, _first) {
		var _last = previousToken ?? _first;
		var _from = __site(_first);
		var _to = __site(_last);
		_node.span = new GMLC_Span(_from.file, _from.start, max(_from[$ "end"], _to[$ "end"]));
		// one macro use or enum reference makes one origin, shared by all of its tokens
		var _origin = _first[$ "origin"];
		_node.origin = (_origin != undefined) && (_origin == _last[$ "origin"]) ? _origin : undefined;
		return _node;
	};
	
	// a body that is not a block is wrapped in one with its span
	static __asBlock = function(_statement) {
		if (_statement == undefined) return new ASTBlock(__emptySpan(), []);
		if (_statement.kind == __GMLC_NodeKind_Block) return _statement;
		return new ASTBlock(_statement.span, [_statement], _statement.origin);
	};
	
	static __emptySpan = function() {
		var _t = previousToken ?? currentToken;
		if (_t == undefined) return new GMLC_Span(program.file.fileId, 0, 0);
		var _site = __site(_t);
		return new GMLC_Span(_site.file, _site[$ "end"], _site[$ "end"]);
	};
	#endregion

	#region Statements
	#region jsDoc
	/// @func    parseStatement()
	/// @desc    Parses one statement and the `;` that may end it. A `;` on its own is an Empty statement. The
	///          `@NoOp` pragmas before it target it and the rest of its line.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode}
	#endregion
	static parseStatement = function() {
		if (++depth > maxDepth) __error("GMLC1030", "the code is nested too deeply");
		var _first = currentToken;
		var _statement;
		
		// the pragmas written before this statement
		var _pragmas = script.pragmas;
		var _firstPragma = pragmaIndex;
		var _site = __site(_first);
		while (pragmaIndex < array_length(_pragmas)) && (_pragmas[pragmaIndex].span.start < _site.start) {
			pragmaIndex++;
		}
		
		switch (currentToken.type) {
			case __GMLC_TokenType_Punctuation: {
				if (currentToken.value == ";") {
					advance();
					_statement = finish(new ASTEmpty(), _first);
					__targetPragmas(_firstPragma, _statement);
					depth--;
					return _statement;
				}
				_statement = (currentToken.value == "{") ? parseBlock() : parseSimpleStatement();
			break;}
			case __GMLC_TokenType_Keyword: {
				switch (currentToken.value) {
					case "var":       _statement = parseDeclList(); break;
					case "static":    _statement = parseDeclList(); break;
					case "globalvar": _statement = parseGlobalvar(); break;
					case "function": {
						var _next = peek();
						_statement = (_next != undefined) && (_next.type == __GMLC_TokenType_Identifier) ? parseFunctionDecl() : parseSimpleStatement();
					break;}
					case "if":       _statement = parseIf(); break;
					case "for":      _statement = parseFor(); break;
					case "while":    _statement = parseWhile(); break;
					case "repeat":   _statement = parseRepeat(); break;
					case "with":     _statement = parseWith(); break;
					case "do":       _statement = parseDoUntil(); break;
					case "switch":   _statement = parseSwitch(); break;
					case "try":      _statement = parseTry(); break;
					case "return":   _statement = parseReturn(); break;
					case "throw":    _statement = parseThrow(); break;
					case "delete":   _statement = parseDelete(); break;
					case "break": {
						advance();
						_statement = finish(new ASTBreak(), _first);
					break;}
					case "continue": {
						advance();
						_statement = finish(new ASTContinue(), _first);
					break;}
					case "exit": {
						advance();
						_statement = finish(new ASTExit(), _first);
					break;}
					case "case":
					case "default":  __error("GMLC1026", $"`{currentToken.value}` outside a switch"); break;
					case "else":     __error("GMLC1024", "`else` without an `if`"); break;
					case "enum":     __error("GMLC1012", "an enum declaration the preprocessor did not read"); break;
					default:         _statement = parseSimpleStatement(); break;
				}
			break;}
			default: {
				_statement = parseSimpleStatement();
			break;}
		}

		// the `;` that ends a statement belongs to it
		if (optional(__GMLC_TokenType_Punctuation, ";")) {
			finish(_statement, _first);
		}
		__targetPragmas(_firstPragma, _statement);
		depth--;
		return _statement;
	};
	
	#region jsDoc
	/// @func    __targetPragmas(_from, _statement)
	/// @desc    The pragmas from _from up to pragmaIndex were written before this statement: their target starts with it.
	///          A later statement of the same nesting that starts on the same line extends the target to its end.
	/// @self    GMLC_Gen_2_Parser
	#endregion
	static __targetPragmas = function(_from, _statement) {
		var _span = _statement.span;
		if (pragmaIndex > _from) {
			var _target = new GMLC_Span(_span.file, _span.start, _span[$ "end"]);
			var _p = _from; repeat (pragmaIndex - _from) {
				script.pragmas[_p].target = _target;
			_p++}
			openTarget = { target: _target, depth: depth, line: __lineOf(_span) };
			return;
		}
		if (openTarget == undefined) || (depth > openTarget.depth) return;
		if (depth == openTarget.depth) && (_span.file == openTarget.target.file) && (__lineOf(_span) == openTarget.line) {
			openTarget.target[$ "end"] = _span[$ "end"];
			return;
		}
		openTarget = undefined;
	};
	
	// the line a span starts on in this file, -1 for another file
	static __lineOf = function(_span) {
		return (_span.file == program.file.fileId) ? program.file.lineOf(_span.start) : -1;
	};
	
	#region jsDoc
	/// @func    parseBlock()
	/// @desc    Parses `{ statements }` (`begin` and `end` arrive as braces).
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTBlock}
	#endregion
	static parseBlock = function() {
		var _first = currentToken;
		expect(__GMLC_TokenType_Punctuation, "{");
		var _body = [];
		while (currentToken != undefined) && !isPunctuation("}") {
			array_push(_body, parseStatement());
		}
		if (currentToken == undefined) __error("GMLC1003", "a block is not closed", _first);
		advance();
		return finish(new ASTBlock(undefined, _body), _first);
	};
	
	#region jsDoc
	/// @func    parseBody()
	/// @desc    Parses the body of a statement: a block, or one statement wrapped in a block with its span.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTBlock}
	#endregion
	static parseBody = function() {
		if (currentToken == undefined) __error("GMLC1002", "expected a statement, found the end of the file");
		return __asBlock(parseStatement());
	};
	
	#region jsDoc
	/// @func    parseSimpleStatement()
	/// @desc    Parses an assignment (`target op value`) or an expression statement.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTExprStmt}
	#endregion
	static parseSimpleStatement = function() {
		var _first = currentToken;
		var _target = parseUnary();
		if (currentToken != undefined) && (currentToken.type == __GMLC_TokenType_Operator) {
			switch (currentToken.value) {
				case "=": case "+=": case "-=": case "*=": case "/=": case "%=":
				case "&=": case "|=": case "^=": case "??=": {
					var _op = currentToken.value;
					__checkTarget(_target, _first);
					advance();
					var _value = parseExpression();
					var _assign = finish(new ASTAssign(undefined, _op, _target, _value), _first);
					return finish(new ASTExprStmt(undefined, _assign), _first);
				}
			}
		}
		// not an assignment: the rest of an expression that starts with what was parsed
		var _expression = parseConditional(_target, _first);
		return finish(new ASTExprStmt(undefined, _expression), _first);
	};
	
	static __checkTarget = function(_target, _first) {
		switch (_target.kind) {
			case __GMLC_NodeKind_Identifier:
			case __GMLC_NodeKind_Index:
			return;
			case __GMLC_NodeKind_Literal: {
				// a macro's or an enum member's value, left for the resolver to report
				if (_target.origin != undefined) return;
			break;}
		}
		__error("GMLC1004", "this cannot be assigned to", _first);
	};
	
	#region jsDoc
	/// @func    parseDeclList()
	/// @desc    Parses `var` or `static` and its declarators: a VarDeclList or a StaticDecl.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode}
	#endregion
	static parseDeclList = function() {
		var _first = currentToken;
		var _isStatic = (currentToken.value == "static");
		advance();
		var _declarations = [];
		do {
			var _declFirst = currentToken;
			// GameMaker takes `then` as the name of a static, not of a var (measured)
			var _target = __parseName("a variable name", _isStatic);
			var _init = undefined;
			if (isOperator("=")) {
				advance();
				_init = parseExpression();
			}
			else if (_isStatic) {
				__error("GMLC1023", "a static variable must be given a value");
			}
			array_push(_declarations, finish(new ASTVarDecl(undefined, _target, _init), _declFirst));
		}
		// a comma not followed by a name ends the list (`var a = 0,` then the next statement, which GameMaker accepts)
		until (!optional(__GMLC_TokenType_Punctuation, ",")
			|| (currentToken == undefined) || (currentToken.type != __GMLC_TokenType_Identifier));
		return finish(_isStatic ? new ASTStaticDecl(undefined, _declarations) : new ASTVarDeclList(undefined, _declarations), _first);
	};
	
	#region jsDoc
	/// @func    parseGlobalvar()
	/// @desc    Parses `globalvar a, b`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTGlobalVarDecl}
	#endregion
	static parseGlobalvar = function() {
		var _first = currentToken;
		advance();
		var _names = [];
		do {
			array_push(_names, __parseName("a variable name"));
			if (isOperator("=")) __error("GMLC1011", "a globalvar declaration cannot have a value");
		}
		until (!optional(__GMLC_TokenType_Punctuation, ","));
		return finish(new ASTGlobalVarDecl(undefined, _names), _first);
	};
	
	// an Identifier from a name token: keywords are not names, as GameMaker refuses them, except `then` where
	// _thenIsName says GameMaker takes it
	static __parseName = function(_what, _thenIsName = false) {
		var _first = currentToken;
		if (_first == undefined) __error("GMLC1002", $"expected {_what}, found the end of the file");
		var _then = _thenIsName && (_first.type == __GMLC_TokenType_Keyword) && (_first.value == "then");
		if (_first.type != __GMLC_TokenType_Identifier) && (!_then) {
			__error("GMLC1002", $"expected {_what}, found {_first.name}");
		}
		advance();
		return finish(new ASTIdentifier(undefined, _first.name), _first);
	};
	
	#region jsDoc
	/// @func    parseFunctionDecl()
	/// @desc    Parses `function name(...) {}` at the start of a statement: a FunctionDecl, or a ConstructorDecl with
	///          `constructor`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode}
	#endregion
	static parseFunctionDecl = function() {
		var _first = currentToken;
		advance(); // function
		var _name = currentToken.name;
		advance();
		var _rest = parseFunctionRest();
		if (_rest.isConstructor) {
			return finish(new ASTConstructorDecl(undefined, _name, _rest.params, _rest.parent, _rest.body), _first);
		}
		return finish(new ASTFunctionDecl(undefined, _name, _rest.params, _rest.body), _first);
	};
	
	#region jsDoc
	/// @func    parseFunctionRest()
	/// @desc    Parses what follows the name of a function: parameters, an optional `: Parent(args)`, an optional
	///          `constructor` and the body.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct} {params, parent, isConstructor, body}
	#endregion
	static parseFunctionRest = function() {
		var _params = parseParams();
		var _parent = undefined;
		var _colon = currentToken;
		if (optional(__GMLC_TokenType_Punctuation, ":")) {
			_parent = parsePostfix();
			if (_parent.kind != __GMLC_NodeKind_Call) __error("GMLC1001", "a parent constructor must be a call", _colon);
		}
		var _isConstructor = optional(__GMLC_TokenType_Keyword, "constructor");
		if (_parent != undefined) && (!_isConstructor) __error("GMLC1010", "a parent call needs `constructor`", _colon);
		var _body = parseBlock();
		return { params: _params, parent: _parent, isConstructor: _isConstructor, body: _body };
	};
	
	#region jsDoc
	/// @func    parseParams()
	/// @desc    Parses `(a, b = 1)`: the parameters of a function.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Array<Struct.ASTParam>}
	#endregion
	static parseParams = function() {
		expect(__GMLC_TokenType_Punctuation, "(");
		var _params = [];
		while (!isPunctuation(")")) {
			var _first = currentToken;
			var _target = __parseName("a parameter name");
			var _default = undefined;
			if (isOperator("=")) {
				advance();
				_default = parseExpression();
			}
			array_push(_params, finish(new ASTParam(undefined, _target, _default), _first));
			if (!optional(__GMLC_TokenType_Punctuation, ",")) break;
		}
		expect(__GMLC_TokenType_Punctuation, ")");
		return _params;
	};
	
	static parseIf = function() {
		var _first = currentToken;
		advance();
		var _test = parseExpression();
		optional(__GMLC_TokenType_Keyword, "then");
		var _consequent = parseBody();
		var _alternate = undefined;
		if (optional(__GMLC_TokenType_Keyword, "else")) {
			_alternate = parseBody();
		}
		return finish(new ASTIf(undefined, _test, _consequent, _alternate), _first);
	};
	
	static parseFor = function() {
		var _first = currentToken;
		advance();
		expect(__GMLC_TokenType_Punctuation, "(");
		var _init = undefined;
		if (!isPunctuation(";")) {
			_init = isKeyword("var") ? parseDeclList() : parseSimpleStatement();
		}
		expect(__GMLC_TokenType_Punctuation, ";");
		var _test = isPunctuation(";") ? undefined : parseExpression();
		expect(__GMLC_TokenType_Punctuation, ";");
		var _update = undefined;
		if (!isPunctuation(")")) {
			// GameMaker also takes a block here: `for (;; { i++ })`
			_update = isPunctuation("{") ? parseBlock() : parseSimpleStatement();
		}
		while (optional(__GMLC_TokenType_Punctuation, ";")) {}
		expect(__GMLC_TokenType_Punctuation, ")");
		var _body = parseBody();
		return finish(new ASTFor(undefined, _init, _test, _update, _body), _first);
	};
	
	static parseWhile = function() {
		var _first = currentToken;
		advance();
		var _test = parseExpression();
		var _body = parseBody();
		return finish(new ASTWhile(undefined, _test, _body), _first);
	};
	
	static parseRepeat = function() {
		var _first = currentToken;
		advance();
		var _count = parseExpression();
		var _body = parseBody();
		return finish(new ASTRepeat(undefined, _count, _body), _first);
	};
	
	static parseWith = function() {
		var _first = currentToken;
		advance();
		var _target = parseExpression();
		var _body = parseBody();
		return finish(new ASTWith(undefined, _target, _body), _first);
	};
	
	static parseDoUntil = function() {
		var _first = currentToken;
		advance();
		var _body = parseBody();
		if (!isKeyword("until")) __error("GMLC1025", "keyword until expected");
		advance();
		var _test = parseExpression();
		return finish(new ASTDoUntil(undefined, _body, _test), _first);
	};
	
	static parseSwitch = function() {
		var _first = currentToken;
		advance();
		var _discriminant = parseExpression();
		expect(__GMLC_TokenType_Punctuation, "{");
		var _cases = [];
		var _hasDefault = false;
		while (currentToken != undefined) && !isPunctuation("}") {
			var _caseFirst = currentToken;
			if (isKeyword("case")) {
				advance();
				var _test = parseExpression();
				expect(__GMLC_TokenType_Punctuation, ":");
				var _clause = new ASTCase(undefined, _test, __parseCaseBody());
			}
			else if (isKeyword("default")) {
				if (_hasDefault) __error("GMLC1008", "default cannot be used multiple times");
				_hasDefault = true;
				advance();
				expect(__GMLC_TokenType_Punctuation, ":");
				var _clause = new ASTDefault(undefined, __parseCaseBody());
			}
			else {
				__error("GMLC1007", "a statement in a switch must come after case or default");
			}
			array_push(_cases, finish(_clause, _caseFirst));
		}
		if (currentToken == undefined) __error("GMLC1003", "a switch is not closed", _first);
		advance();
		return finish(new ASTSwitch(undefined, _discriminant, _cases), _first);
	};
	
	static __parseCaseBody = function() {
		var _body = [];
		while (currentToken != undefined) && !isPunctuation("}") && !isKeyword("case") && !isKeyword("default") {
			array_push(_body, parseStatement());
		}
		return _body;
	};
	
	static parseTry = function() {
		var _first = currentToken;
		advance();
		var _block = parseBody();
		var _catchParam = undefined;
		var _catchBody = undefined;
		var _finallyBody = undefined;
		if (optional(__GMLC_TokenType_Keyword, "catch")) {
			if (!isPunctuation("(")) __error("GMLC1020", "catch needs ( name )");
			advance();
			_catchParam = __parseName("the name of the caught value");
			expect(__GMLC_TokenType_Punctuation, ")");
			_catchBody = parseBody();
		}
		if (optional(__GMLC_TokenType_Keyword, "finally")) {
			_finallyBody = parseBody();
		}
		return finish(new ASTTry(undefined, _block, _catchParam, _catchBody, _finallyBody), _first);
	};
	
	static parseReturn = function() {
		var _first = currentToken;
		advance();
		var _argument = __startsExpression() ? parseExpression() : undefined;
		return finish(new ASTReturn(undefined, _argument), _first);
	};
	
	// whether the current token can start an expression (`return` takes a value only then)
	static __startsExpression = function() {
		if (currentToken == undefined) return false;
		switch (currentToken.type) {
			case __GMLC_TokenType_Punctuation: return (currentToken.value != ";") && (currentToken.value != "}") && (currentToken.value != ")") && (currentToken.value != "]") && (currentToken.value != ",") && (currentToken.value != ":");
			case __GMLC_TokenType_Keyword: return (currentToken.value == "function") || (currentToken.value == "new");
		}
		return true;
	};
	
	static parseThrow = function() {
		var _first = currentToken;
		advance();
		var _argument = parseExpression();
		return finish(new ASTThrow(undefined, _argument), _first);
	};
	
	static parseDelete = function() {
		var _first = currentToken;
		advance();
		var _target = parsePostfix();
		return finish(new ASTDelete(undefined, _target), _first);
	};
	#endregion

	#region Expressions
	// The conditional and binary tiers take an optional left operand already parsed (with its first token), so a
	// statement that started as an assignment target can continue as an expression.
	
	static parseExpression = function() {
		if (++depth > maxDepth) __error("GMLC1030", "the code is nested too deeply");
		var _expression = parseConditional();
		depth--;
		return _expression;
	};
	
	static parseConditional = function(_left = undefined, _first = currentToken) {
		var _test = parseBinary(1, _left, _first);
		if (!isOperator("?")) return _test;
		advance();
		// each branch counts toward the nesting limit, so a long chain of conditionals cannot exhaust the stack
		var _consequent = parseExpression();
		expect(__GMLC_TokenType_Punctuation, ":");
		var _alternate = parseExpression();
		return finish(new ASTConditional(undefined, _test, _consequent, _alternate), _first);
	};
	
	#region jsDoc
	/// @func    parseBinary(_minTier, [_left], [_first])
	/// @desc    Parses binary operators of tier _minTier or tighter (see __binaryTiers), left to right: each operator
	///          takes as its right operand everything of a tighter tier.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Real}           _minTier : The loosest tier to take
	/// @param   {Struct.ASTNode} [_left]  : The left operand, already parsed
	/// @param   {Struct}         [_first] : The first token of the left operand
	/// @returns {Struct.ASTNode}
	#endregion
	static parseBinary = function(_minTier, _left = undefined, _first = currentToken) {
		var _expression = _left ?? parseUnary();
		while (currentToken != undefined) && (currentToken.type == __GMLC_TokenType_Operator) {
			var _op = currentToken.value;
			var _tier = __binaryTiers[$ _op];
			if (_tier == undefined) || (_tier < _minTier) break;
			advance();
			var _right = parseBinary(_tier + 1);
			switch (_tier) {
				case 1: _expression = new ASTNullish(undefined, _expression, _right); break;
				case 2: case 3: case 4: _expression = new ASTLogical(undefined, _op, _expression, _right); break;
				default: _expression = new ASTBinary(undefined, (_op == "=") ? "==" : _op, _expression, _right); break;
			}
			finish(_expression, _first);
		}
		return _expression;
	};

	static parseUnary = function() {
		if (currentToken != undefined) && (currentToken.type == __GMLC_TokenType_Operator) {
			var _first = currentToken;
			switch (currentToken.value) {
				case "!": case "-": case "+": case "~": {
					if (++depth > maxDepth) __error("GMLC1030", "the code is nested too deeply");
					var _op = currentToken.value;
					advance();
					var _argument = parseUnary();
					depth--;
					return finish(new ASTUnary(undefined, _op, _argument), _first);
				}
				case "++": case "--": {
					if (++depth > maxDepth) __error("GMLC1030", "the code is nested too deeply");
					var _op = currentToken.value;
					advance();
					var _argument = parseUnary();
					__checkUpdateTarget(_argument, _first);
					depth--;
					return finish(new ASTUpdate(undefined, _op, true, _argument), _first);
				}
			}
		}
		return parsePostfix();
	};
	
	// what `++` and `--` change: a name, an index, or a literal (left for the resolver to report)
	static __checkUpdateTarget = function(_target, _first) {
		switch (_target.kind) {
			case __GMLC_NodeKind_Identifier:
			case __GMLC_NodeKind_Index:
			case __GMLC_NodeKind_Literal:
			return;
		}
		__error("GMLC1004", "this cannot be incremented or decremented", _first);
	};
	
	#region jsDoc
	/// @func    parsePostfix()
	/// @desc    Parses a primary and its postfix steps in order: arguments make a Call (a MethodCall right after
	///          `.name`), `[` and the accessor openers an Index, `.name` an Index with the Dot accessor; a trailing `++`
	///          or `--` makes a postfix Update and ends the chain.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode}
	#endregion
	static parsePostfix = function() {
		var _first = currentToken;
		var _expression = parsePrimary();
		var _afterDot = false;
		while (currentToken != undefined) {
			if (currentToken.type == __GMLC_TokenType_Punctuation) {
				switch (currentToken.value) {
					case "(": {
						var _args = parseArguments();
						if (_afterDot) {
							_expression = finish(new ASTMethodCall(undefined, _expression.object, _expression.member, _args), _first);
						}
						else {
							_expression = finish(new ASTCall(undefined, _expression, _args), _first);
						}
						_afterDot = false;
						continue;
					}
					case "[": case "[@": case "[|": case "[?": case "[#": case "[$": {
						// the same openers as in __isIndexOpener
						_expression = parseIndex(_expression, _first);
						_afterDot = false;
						continue;
					}
					case ".": {
						advance();
						var _member = __parseMemberName();
						_expression = finish(new ASTIndex(undefined, "Dot", _expression, [], _member), _first);
						_afterDot = true;
						continue;
					}
				}
			}
			else if (isOperator("++") || isOperator("--")) {
				__checkUpdateTarget(_expression, _first);
				var _op = currentToken.value;
				advance();
				return finish(new ASTUpdate(undefined, _op, false, _expression), _first);
			}
			break;
		}
		return _expression;
	};
	
	// the word after `.`: any identifier, keyword or alias word, by its source text
	static __parseMemberName = function() {
		if (currentToken == undefined) __error("GMLC1002", "expected a name after ., found the end of the file");
		switch (currentToken.type) {
			case __GMLC_TokenType_Identifier:
			case __GMLC_TokenType_Keyword: {
				var _name = currentToken.name;
				advance();
				return _name;
			}
			case __GMLC_TokenType_Operator: {
				if (__isAliasWord(currentToken)) {
					var _name = currentToken.name;
					advance();
					return _name;
				}
			break;}
		}
		__error("GMLC1002", $"expected a name after ., found {currentToken.name}");
	};
	
	// alias words (`and`, `div`, ...) arrive as operators; their text starts with a letter
	static __isAliasWord = function(_t) {
		return __char_is_alphabetic(string_ord_at(_t.name, 1));
	};
	
	#region jsDoc
	/// @func    parseArguments()
	/// @desc    Parses `(a, , b)`: the arguments of a call. A missing argument before a comma is an Empty node; a
	///          trailing comma adds nothing.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Array<Struct.ASTNode>}
	#endregion
	static parseArguments = function() {
		var _open = currentToken;
		expect(__GMLC_TokenType_Punctuation, "(");
		var _args = [];
		while (true) {
			if (currentToken == undefined) __error("GMLC1002", "expected , or ), found the end of the file", _open);
			if (isPunctuation(")")) break;
			if (isPunctuation(",")) {
				// a hole: Empty, zero-width at the comma
				var _site = __site(currentToken);
				array_push(_args, new ASTEmpty(new GMLC_Span(_site.file, _site.start, _site.start)));
				advance();
				continue;
			}
			array_push(_args, parseExpression());
			if (isPunctuation(")")) break;
			if (!isPunctuation(",")) __error("GMLC1016", $"expected , or ), found {currentToken.name}");
			advance();
		}
		advance();
		return _args;
	};
	
	#region jsDoc
	/// @func    parseIndex(_object, _first)
	/// @desc    Parses one accessor after an expression: `[i]`, `[i, j]`, `[@ i]`, `[@ i, j]`, `[| i]`, `[? k]`,
	///          `[# x, y]`, `[$ k]`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTIndex}
	#endregion
	static parseIndex = function(_object, _first) {
		var _open = currentToken.value;
		advance();
		var _keys = [parseExpression()];
		if (optional(__GMLC_TokenType_Punctuation, ",")) {
			array_push(_keys, parseExpression());
		}
		expect(__GMLC_TokenType_Punctuation, "]");
		var _two = (array_length(_keys) == 2);
		var _accessor;
		switch (_open) {
			case "[":  _accessor = _two ? "Array2D" : "Array"; break;
			case "[@": _accessor = _two ? "Array2DAt" : "ArrayAt"; break;
			case "[|": _accessor = "List"; break;
			case "[?": _accessor = "Map"; break;
			case "[#": _accessor = "Grid"; break;
			case "[$": _accessor = "Struct"; break;
		}
		// a grid takes two keys, a list, a map and a struct one
		var _gridKeys = (_accessor == "Grid") && !_two;
		var _oneKey = _two && ((_accessor == "List") || (_accessor == "Map") || (_accessor == "Struct"));
		if (_gridKeys || _oneKey) {
			__error("GMLC1001", $"the accessor {_open} takes {(_accessor == "Grid") ? 2 : 1} key(s)");
		}
		return finish(new ASTIndex(undefined, _accessor, _object, _keys, undefined), _first);
	};
	
	#region jsDoc
	/// @func    parsePrimary()
	/// @desc    Parses a literal, a name, a parenthesised expression, an array or struct literal, a template string, a
	///          function expression or `new`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode}
	#endregion
	static parsePrimary = function() {
		if (currentToken == undefined) __error("GMLC1002", "expected an expression, found the end of the file");
		var _first = currentToken;
		switch (currentToken.type) {
			case __GMLC_TokenType_Number:
			case __GMLC_TokenType_String: {
				advance();
				return finish(__literal(_first), _first);
			}
			case __GMLC_TokenType_TemplateStringBegin: return parseTemplate();
			case __GMLC_TokenType_Identifier: {
				advance();
				return finish(new ASTIdentifier(undefined, _first.name), _first);
			}
			case __GMLC_TokenType_Keyword: {
				switch (currentToken.value) {
					case "function": return parseFunctionExpr();
					case "new":      return parseNew();
				}
			break;}
			case __GMLC_TokenType_Punctuation: {
				switch (currentToken.value) {
					case "(": {
						// parentheses leave no node
						advance();
						var _inner = parseExpression();
						expect(__GMLC_TokenType_Punctuation, ")");
						return _inner;
					}
					case "[": case "[@": return parseArrayLiteral();
					case "{": return parseStructLiteral();
				}
			break;}
		}
		__error("GMLC1001", $"unexpected {currentToken.name}");
	};

	// the Literal of a number or string token
	static __literal = function(_t) {
		var _ty = _t[$ "ty"];
		if (_ty == undefined) {
			if (_t.type == __GMLC_TokenType_String) {
				_ty = "string";
			}
			else if (is_int64(_t.value)) {
				_ty = "int64";
			}
			else {
				_ty = "real";
			}
		}
		return new ASTLiteral(undefined, _ty, _t.name, _t.value);
	};
	
	#region jsDoc
	/// @func    parseTemplate()
	/// @desc    Parses `$"text {expression} text"`: the cooked text parts and the expressions between them.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTTemplateString}
	#endregion
	static parseTemplate = function() {
		var _first = currentToken;
		var _strings = [currentToken.value];
		var _exprs = [];
		advance();
		while (true) {
			if (currentToken == undefined) __error("GMLC1002", "a template string is not closed", _first);
			if (currentToken.type == __GMLC_TokenType_TemplateStringMiddle) || (currentToken.type == __GMLC_TokenType_TemplateStringEnd) {
				__error("GMLC1014", "an empty {} in a template string");
			}
			array_push(_exprs, parseExpression());
			if (currentToken == undefined) __error("GMLC1002", "a template string is not closed", _first);
			if (currentToken.type == __GMLC_TokenType_TemplateStringMiddle) {
				array_push(_strings, currentToken.value);
				advance();
				continue;
			}
			if (currentToken.type == __GMLC_TokenType_TemplateStringEnd) {
				array_push(_strings, currentToken.value);
				advance();
				break;
			}
			__error("GMLC1002", $"expected }} in a template string, found {currentToken.name}");
		}
		return finish(new ASTTemplateString(undefined, _strings, _exprs), _first);
	};
	
	static parseArrayLiteral = function() {
		var _first = currentToken;
		advance(); // `[` or `[@`
		var _elements = [];
		while (!isPunctuation("]")) {
			if (currentToken == undefined) __error("GMLC1002", "an array literal is not closed", _first);
			if (isPunctuation(",")) __error("GMLC1017", "an empty element in an array literal");
			array_push(_elements, parseExpression());
			if (isPunctuation("]")) break;
			if (!isPunctuation(",")) __error("GMLC1016", $"expected , or ], found {(currentToken != undefined) ? currentToken.name : "the end of the file"}");
			advance();
		}
		advance();
		return finish(new ASTArrayLiteral(undefined, _elements), _first);
	};
	
	#region jsDoc
	/// @func    parseStructLiteral()
	/// @desc    Parses `{key: value, "key": value, name}`. A key is a word or a string; a word alone is shorthand for
	///          `name: name`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTStructLiteral}
	#endregion
	static parseStructLiteral = function() {
		var _first = currentToken;
		advance(); // {
		var _entries = [];
		while (!isPunctuation("}")) {
			if (currentToken == undefined) __error("GMLC1002", "a struct literal is not closed", _first);
			var _keyToken = currentToken;
			var _quoted = false;
			var _key;
			switch (_keyToken.type) {
				case __GMLC_TokenType_String: {
					_quoted = true;
					_key = _keyToken.value;
				break;}
				case __GMLC_TokenType_Identifier:
				case __GMLC_TokenType_Keyword:
				case __GMLC_TokenType_Number: {
					_key = _keyToken.name;
				break;}
				case __GMLC_TokenType_Operator: {
					if (!__isAliasWord(_keyToken)) __error("GMLC1015", $"{_keyToken.name} cannot be a struct key");
					_key = _keyToken.name;
				break;}
				default: {
					__error("GMLC1015", $"{_keyToken.name} cannot be a struct key");
				}
			}
			advance();
			var _value;
			var _shorthand = false;
			if (optional(__GMLC_TokenType_Punctuation, ":")) {
				_value = parseExpression();
			}
			else {
				// `{name}` is `{name: name}` and `{5}` is `{5: 5}`, as GameMaker reads them; nothing else stands alone
				_shorthand = true;
				if (_keyToken.type == __GMLC_TokenType_Identifier) {
					_value = finish(new ASTIdentifier(undefined, _key), _keyToken);
				}
				else if (_keyToken.type == __GMLC_TokenType_Number) {
					_value = finish(__literal(_keyToken), _keyToken);
				}
				else {
					__error("GMLC1002", $"expected : after the struct key {_keyToken.name}");
				}
			}
			array_push(_entries, finish(new ASTStructEntry(undefined, _key, _quoted, _shorthand, _value), _keyToken));
			if (isPunctuation("}")) break;
			if (!isPunctuation(",")) __error("GMLC1016", $"expected , or }}, found {(currentToken != undefined) ? currentToken.name : "the end of the file"}");
			advance();
		}
		advance();
		return finish(new ASTStructLiteral(undefined, _entries), _first);
	};
	
	#region jsDoc
	/// @func    parseFunctionExpr()
	/// @desc    Parses `function [name](...) [: Parent(...)] [constructor] {}` in an expression.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTFunctionExpr}
	#endregion
	static parseFunctionExpr = function() {
		var _first = currentToken;
		advance(); // function
		var _name = undefined;
		if (currentToken != undefined) && (currentToken.type == __GMLC_TokenType_Identifier) {
			_name = currentToken.name;
			advance();
		}
		var _rest = parseFunctionRest();
		return finish(new ASTFunctionExpr(undefined, _name, _rest.isConstructor, _rest.params, _rest.parent, _rest.body), _first);
	};
	
	#region jsDoc
	/// @func    parseNew()
	/// @desc    Parses `new Callee(args)`: the callee is a name or a parenthesised expression with `.name` and index
	///          steps; the first argument list belongs to `new`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNew}
	#endregion
	static parseNew = function() {
		var _first = currentToken;
		advance(); // new
		var _calleeFirst = currentToken;
		var _callee;
		if (isPunctuation("(")) {
			advance();
			_callee = parseExpression();
			expect(__GMLC_TokenType_Punctuation, ")");
		}
		else {
			_callee = __parseName("a constructor");
		}
		while (currentToken != undefined) && (currentToken.type == __GMLC_TokenType_Punctuation) {
			if (currentToken.value == ".") {
				advance();
				var _member = __parseMemberName();
				_callee = finish(new ASTIndex(undefined, "Dot", _callee, [], _member), _calleeFirst);
				continue;
			}
			if (__isIndexOpener(currentToken.value)) {
				_callee = parseIndex(_callee, _calleeFirst);
				continue;
			}
			break;
		}
		var _args = isPunctuation("(") ? parseArguments() : [];
		return finish(new ASTNew(undefined, _callee, _args), _first);
	};
	
	static __isIndexOpener = function(_value) {
		switch (_value) {
			case "[": case "[@": case "[|": case "[?": case "[#": case "[$": return true;
		}
		return false;
	};
	#endregion
}
#endregion
