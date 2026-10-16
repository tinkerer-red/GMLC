#region jsDoc
/// @func    GMLC_Gen_2_Parser(_env)
/// @desc    Parses the preprocessed tokens of one file to a syntax tree; names stay unresolved.
/// @param   {Struct.GMLC_Env} _env : The environment
/// @returns {Struct.GMLC_Gen_2_Parser}
#endregion
function GMLC_Gen_2_Parser(_env) constructor {
	#region Config
	static maxDepth = 256; // deeper nesting is an error, so deep code cannot exhaust the stack

	// tightest highest; `=` in an expression is equality
	static __binaryTiers = {
		"??": 1, "||": 2, "&&": 3, "^^": 4,
		"==": 5, "!=": 5, "<": 5, "<=": 5, ">": 5, ">=": 5, "=": 5,
		"|": 6, "&": 6, "^": 6,
		"<<": 7, ">>": 7,
		"+": 8, "-": 8,
		"*": 9, "/": 9, "div": 9, "mod": 9,
	};
	#endregion

	#region Init
	env = _env; // only its switched-on extensions are read

	program = undefined;
	tokens = [];
	token_count = 0;
	token_index = 0;
	current_token = undefined;
	previous_token = undefined;
	script = undefined;
	depth = 0;
	diagnostics = [];
	pragma_index = 0; // the first pragma that has no statement yet
	extension_state = {};
	__extension_id = 0;
	__statement_hooks = {};
	__primary_hooks = {};
	__postfix_hooks = {};
	#endregion

	#region Public
	#region jsDoc
	/// @func    initialize(_program, [_kind])
	/// @desc    Prepares parsing of one preprocessed file.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Struct} _program : The preprocessor's program record
	/// @param   {String} [_kind]  : "script", or "event" for an object's event code
	#endregion
	static initialize = function(_program, _kind = "script") {
		program = _program;
		__startTokens(_program.tokens);
		depth = 0;
		diagnostics = [];
		pragma_index = 0;
		__initializeExtensions();

		var _file = _program.file;
		script = new ASTScript(new GMLC_Span(_file.file_id, 0, _file.byteLength()));
		script.unit_kind = _kind;

		script.macros = _program.macros;
		script.enums = _program.enums;
		script.regions = _program.regions;
		script.pragmas = _program.pragmas;
	};

	#region jsDoc
	/// @func    parseAll()
	/// @desc    Parses the whole file and rewrites the extensions' constructs to plain GML. Throws when there is an
	///          error.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTScript}
	#endregion
	static parseAll = function() {
		while (current_token != undefined) {
			array_push(script.body, parseStatement());
		}
		__parseEnumValues();
		var _extensions = env.extensions;
		var _x = 0; repeat (array_length(_extensions)) {
			var _extension = _extensions[_x];
			if (_extension.rewrite != undefined) _extension.rewrite(script, self, extension_state[$ _extension.name]);
		_x++}
		__targetFunctionPragmas();
		if (__gmlc_has_errors(diagnostics)) __gmlc_throw_diagnostics(diagnostics, program[$ "sources"] ?? new GMLC_SourceTable(program.file));
		return script;
	};

	#region Tokens
	#region jsDoc
	/// @func    nextToken()
	/// @desc    Moves to the next token; `current_token` is undefined at the end.
	/// @self    GMLC_Gen_2_Parser
	#endregion
	static nextToken = function() {
		previous_token = current_token;
		token_index++;
		current_token = (token_index < token_count) ? tokens[token_index] : undefined;
	};

	#region jsDoc
	/// @func    peekToken()
	/// @desc    The token after the current one, undefined at the end.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct|Undefined}
	#endregion
	static peekToken = function() {
		return (token_index + 1 < token_count) ? tokens[token_index + 1] : undefined;
	};

	#region jsDoc
	/// @func    isPunctuation(_value)
	/// @desc    Whether the current token is the punctuation _value.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {String} _value : The token text
	/// @returns {Bool}
	#endregion
	static isPunctuation = function(_value) {
		return (current_token != undefined) && (current_token.type == __GMLC_TokenType_Punctuation) && (current_token.value == _value);
	};

	#region jsDoc
	/// @func    isOperator(_value)
	/// @desc    Whether the current token is the operator _value.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {String} _value : The token text
	/// @returns {Bool}
	#endregion
	static isOperator = function(_value) {
		return (current_token != undefined) && (current_token.type == __GMLC_TokenType_Operator) && (current_token.value == _value);
	};

	#region jsDoc
	/// @func    isKeyword(_value)
	/// @desc    Whether the current token is the keyword _value.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {String} _value : The token text
	/// @returns {Bool}
	#endregion
	static isKeyword = function(_value) {
		return (current_token != undefined) && (current_token.type == __GMLC_TokenType_Keyword) && (current_token.value == _value);
	};

	#region jsDoc
	/// @func    expectToken(_type, _value, [_opener])
	/// @desc    Takes the token _value of _type, or stops with GMLC1002.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Real}   _type     : The token type
	/// @param   {String} _value    : The token text
	/// @param   {Struct} [_opener] : The bracket the token closes, which the error then labels
	#endregion
	static expectToken = function(_type, _value, _opener = undefined) {
		if (current_token == undefined) {
			__fail("GMLC1002", undefined, [_value, "the end of the file"], undefined, _opener);
		}
		if (current_token.type != _type) || (current_token.value != _value) {
			__fail("GMLC1002", current_token, [_value, current_token.name], undefined, _opener);
		}
		nextToken();
	};

	#region jsDoc
	/// @func    optionalToken(_type, _value)
	/// @desc    Takes the current token when it is _value of _type.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Real}   _type  : The token type
	/// @param   {String} _value : The token text
	/// @returns {Bool}
	#endregion
	static optionalToken = function(_type, _value) {
		if (current_token != undefined) && (current_token.type == _type) && (current_token.value == _value) {
			nextToken();
			return true;
		}
		return false;
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
		var _last = previous_token ?? _first;
		var _from = __site(_first);
		var _to = __site(_last);
		_node.span = new GMLC_Span(_from.file, _from.start, max(_from[$ "end"], _to[$ "end"]));
		var _origin = _first[$ "origin"];
		_node.origin = (_origin != undefined) && (_origin == _last[$ "origin"]) ? _origin : undefined;
		return _node;
	};
	#endregion

	#region Statements
	#region jsDoc
	/// @func    parseStatement()
	/// @desc    Parses one statement and the `;` that may end it. A `;` on its own is an Empty statement. The
	///          `@NoOp` pragmas written before it target it, bodies included.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode}
	#endregion
	static parseStatement = function() {
		if (++depth > maxDepth) __fail("GMLC1030");
		var _first = current_token;
		var _statement;

		var _pragmas = script.pragmas;
		var _firstPragma = pragma_index;
		var _site = __site(_first);
		while (pragma_index < array_length(_pragmas)) && (_pragmas[pragma_index].span.start < _site.start) {
			pragma_index++;
		}
		var _lastPragma = pragma_index;

		switch (current_token.type) {
			case __GMLC_TokenType_Punctuation: {
				if (current_token.value == ";") {
					nextToken();
					_statement = finish(new ASTEmpty(), _first);
					__targetPragmas(_firstPragma, _lastPragma, _statement);
					depth--;
					return _statement;
				}
				_statement = (current_token.value == "{") ? parseBlock() : parseExpressionStatement();
			break;}
			case __GMLC_TokenType_Keyword: {
				switch (current_token.value) {
					case "var":       _statement = parseVariableDeclaration(); break;
					case "static":    _statement = parseVariableDeclaration(); break;
					case "globalvar": _statement = parseGlobalvar(); break;
					case "function": {
						var _next = peekToken();
						_statement = (_next != undefined) && (_next.type == __GMLC_TokenType_Identifier) ? parseFunctionDeclaration() : parseExpressionStatement();
					break;}
					case "if":       _statement = parseIfStatement(); break;
					case "for":      _statement = parseForStatement(); break;
					case "while":    _statement = parseWhileStatement(); break;
					case "repeat":   _statement = parseRepeatStatement(); break;
					case "with":     _statement = parseWithStatement(); break;
					case "do":       _statement = parseDoUntilStatement(); break;  // Note: Adjust this if the actual keyword differs
					case "switch":   _statement = parseSwitchStatement(); break;
					case "try":      _statement = parseTryCatchStatement(); break;
					case "return":   _statement = parseReturnStatement(); break;
					case "throw":    _statement = parseThrowExpression(); break;
					case "delete":   _statement = parseDeleteStatement(); break;
					case "break": {
						nextToken(); // Consume break
						_statement = finish(new ASTBreak(), _first);
					break;}
					case "continue": {
						nextToken();
						_statement = finish(new ASTContinue(), _first);
					break;}
					case "exit": {
						nextToken(); // Consume exit
						_statement = finish(new ASTExit(), _first);
					break;}
					case "case":
					case "default":  __fail("GMLC1026", current_token, [current_token.value]); break;
					case "else":     __fail("GMLC1024"); break;
					case "enum":     __fail("GMLC1012"); break;
					default:         _statement = parseExpressionStatement(); break;  // Assume any other token starts an expression statement
				}
			break;}
			default: {
				_statement = __extensionStatement() ?? parseExpressionStatement();
			break;}
		}

		if (optionalToken(__GMLC_TokenType_Punctuation, ";")) {
			finish(_statement, _first);
		}
		__targetPragmas(_firstPragma, _lastPragma, _statement);
		depth--;
		return _statement;
	};

	#region jsDoc
	/// @func    parseBlock()
	/// @desc    Parses `{ statements }` (`begin` and `end` arrive as braces).
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTBlock}
	#endregion
	static parseBlock = function() {
		var _first = current_token;
		expectToken(__GMLC_TokenType_Punctuation, "{"); // Consume the {
		var _body = [];
		// Parse each statement until } is found
		while (current_token != undefined) && !isPunctuation("}") {
			array_push(_body, parseStatement());
		}
		if (current_token == undefined) __fail("GMLC1003", _first);
		nextToken(); // Consume the }
		return finish(new ASTBlock(undefined, _body), _first); // Return a block statement containing all parsed statements
	};

	#region jsDoc
	/// @func    parseBody()
	/// @desc    Parses the body of a statement: a block, or one statement wrapped in a block with its span.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTBlock}
	#endregion
	static parseBody = function() {
		if (current_token == undefined) __fail("GMLC1002", current_token, ["a statement", "the end of the file"]);
		var _statement = parseStatement();
		if (_statement.kind == __GMLC_NodeKind_Block) return _statement;
		// If no {, its a single statement block
		return new ASTBlock(_statement.span, [_statement], _statement.origin);
	};

	#region jsDoc
	/// @func    parseExpressionStatement()
	/// @desc    Parses an assignment or an expression statement. As in GameMaker, an expression statement must be
	///          a call, `new` or `++`/`--`: `x;` is an error.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTExprStmt}
	#endregion
	static parseExpressionStatement = function() {
		var _first = current_token;
		var _target = parseUnaryExpression();
		if (current_token != undefined) && (current_token.type == __GMLC_TokenType_Operator) {
			switch (current_token.value) {
				case "=": case "+=": case "-=": case "*=": case "/=": case "%=":
				case "&=": case "|=": case "^=": case "??=": {
					var _op = current_token.value;
					__checkTarget(_target, false);
					nextToken();
					var _value = parseExpression();
					var _assign = finish(new ASTAssign(undefined, _op, _target, _value), _first);
					return finish(new ASTExprStmt(undefined, _assign), _first);
				}
			}
		}
		var _expression = parseConditionalExpression(_target, _first);
		switch (_expression.kind) {
			case __GMLC_NodeKind_Call:
			case __GMLC_NodeKind_MethodCall:
			case __GMLC_NodeKind_New:
			case __GMLC_NodeKind_Update:
			break;
			default: __fail("GMLC1006", _first);
		}
		return finish(new ASTExprStmt(undefined, _expression), _first);
	};

	#region jsDoc
	/// @func    parseVariableDeclaration()
	/// @desc    Parses `var` or `static` and its declarators. As in GameMaker, a keyword right after `var` ends an
	///          empty list (`var static x = 1` is a static), a comma not followed by a name ends the list, and
	///          `then` can name a static but not a var.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode}
	#endregion
	static parseVariableDeclaration = function() {
		var _first = current_token;
		var _isStatic = (current_token.value == "static");
		nextToken();
		var _declarations = [];
		if (!_isStatic) && (current_token != undefined) && (current_token.type == __GMLC_TokenType_Keyword) {
			return finish(new ASTVarDeclList(undefined, _declarations), _first);
		}
		//parse all declarations
		do {
			var _declFirst = current_token;
			//these must be a identifier one can not `var try = 123`
			var _target = __parseName("a variable name", _isStatic);
			var _init = undefined;
			if (isOperator("=")) {
				nextToken();
				_init = parseExpression();
			}
			else if (_isStatic) {
				__fail("GMLC1023");
			}
			array_push(_declarations, finish(new ASTVarDecl(undefined, _target, _init), _declFirst));
		}
		until (!optionalToken(__GMLC_TokenType_Punctuation, ",")
			|| (current_token == undefined) || (current_token.type != __GMLC_TokenType_Identifier));
		return finish(_isStatic ? new ASTStaticDecl(undefined, _declarations) : new ASTVarDeclList(undefined, _declarations), _first);
	};

	#region jsDoc
	/// @func    parseGlobalvar()
	/// @desc    Parses `globalvar a, b`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTGlobalVarDecl}
	#endregion
	static parseGlobalvar = function() {
		var _first = current_token;
		nextToken();
		var _names = [];
		do {
			array_push(_names, __parseName("a variable name"));
			if (isOperator("=")) __fail("GMLC1011");
		}
		until (!optionalToken(__GMLC_TokenType_Punctuation, ","));
		return finish(new ASTGlobalVarDecl(undefined, _names), _first);
	};

	#region jsDoc
	/// @func    parseFunctionDeclaration()
	/// @desc    Parses `function name(...) {}` at the start of a statement: a FunctionDecl, or a ConstructorDecl with
	///          `constructor`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode}
	#endregion
	static parseFunctionDeclaration = function() {
		var _first = current_token;
		nextToken();
		//consume the function's identifier
		var _name = current_token.name;
		nextToken();
		var _rest = parseFunctionRest();
		if (_rest.is_constructor) {
			return finish(new ASTConstructorDecl(undefined, _name, _rest.params, _rest.parent, _rest.body), _first);
		}
		return finish(new ASTFunctionDecl(undefined, _name, _rest.params, _rest.body), _first);
	};

	#region jsDoc
	/// @func    parseFunctionRest()
	/// @desc    Parses what follows the name of a function: parameters, an optional `: Parent(args)`, an optional
	///          `constructor` and the body.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct} {params, parent, is_constructor, body}
	#endregion
	static parseFunctionRest = function() {
		var _params = parseArgumentDefaultList();
		var _parent = undefined;
		var _colon = current_token;
		if (optionalToken(__GMLC_TokenType_Punctuation, ":")) {
			_parent = parsePostfixExpression();
			if (_parent.kind != __GMLC_NodeKind_Call) __fail("GMLC1001", _colon, undefined, "GMLC1001.parent-call");
		}
		var _isConstructor = optionalToken(__GMLC_TokenType_Keyword, "constructor");
		if (_parent != undefined) && (!_isConstructor) __fail("GMLC1010", _colon);
		var _body = parseBlock();
		return { params: _params, parent: _parent, is_constructor: _isConstructor, body: _body };
	};

	#region jsDoc
	/// @func    parseArgumentDefaultList()
	/// @desc    Parses `(a, b = 1)`: the parameters of a function.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Array<Struct.ASTParam>}
	#endregion
	static parseArgumentDefaultList = function() {
		var _open = current_token;
		expectToken(__GMLC_TokenType_Punctuation, "(");
		var _params = [];
		while (!isPunctuation(")")) {
			var _first = current_token;
			var _target = __parseName("a parameter name"); // Parse the parameter name
			var _default = undefined;
			if (isOperator("=")) {
				nextToken();
				_default = parseExpression();
			}
			array_push(_params, finish(new ASTParam(undefined, _target, _default), _first));
			if (!optionalToken(__GMLC_TokenType_Punctuation, ",")) break;
		}
		expectToken(__GMLC_TokenType_Punctuation, ")", _open);  // Close parameters list
		return _params;
	};

	#region jsDoc
	/// @func    parseIfStatement()
	/// @desc    Parses `if test [then] body [else body]`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTIf}
	#endregion
	static parseIfStatement = function() {
		var _first = current_token;
		// Assume current_token is if
		nextToken(); // Move past if
		var _test = parseHeader("if");
		optionalToken(__GMLC_TokenType_Keyword, "then");
		var _consequent = parseBody();
		var _alternate = undefined;
		if (optionalToken(__GMLC_TokenType_Keyword, "else")) { // Consume else
			_alternate = parseBody();
		}
		return finish(new ASTIf(undefined, _test, _consequent, _alternate), _first);
	};

	#region jsDoc
	/// @func    parseForStatement()
	/// @desc    Parses `for (init; test; update) body`; each part of the header may be empty.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTFor}
	#endregion
	static parseForStatement = function() {
		var _first = current_token;
		nextToken(); // Move past for
		var _open = current_token;
		expectToken(__GMLC_TokenType_Punctuation, "(");
		var _init = undefined;
		//it's possible to make a for statement with no initializer variable
		if (!isPunctuation(";")) {
			_init = isKeyword("var") ? parseVariableDeclaration() : (__extensionStatement() ?? parseExpressionStatement());
		}
		expectToken(__GMLC_TokenType_Punctuation, ";");
		//it's possible to make a for statement with no conditional statement
		var _test = isPunctuation(";") ? undefined : parseExpression();
		expectToken(__GMLC_TokenType_Punctuation, ";");
		var _update = undefined;
		if (!isPunctuation(")")) {
			//example of a really cursed for statement, but it is valid syntax

			//for (;; {
			//  show_message("me second!");
			//  break;
			//}) {
			//  show_message("me first!");
			//}
			_update = isPunctuation("{") ? parseBlock() : parseExpressionStatement();
		}
		//these are typically already handled by the parseBlock
		//frequently people will accidently include multiple ; at the end of their line, just ignore this.
		while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}
		expectToken(__GMLC_TokenType_Punctuation, ")", _open);
		var _body = parseBody();
		return finish(new ASTFor(undefined, _init, _test, _update, _body), _first);
	};

	#region jsDoc
	/// @func    parseHeader(_keyword)
	/// @desc    Parses the expression after `if`, `while`, `repeat` or `with`. GameMaker reads `if (c) ++x;` as
	///          `if ((c)++) x;`; a `++` or `--` right after the `)` gets warning GMLC1033.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {String} _keyword : The statement's keyword, for the message
	/// @returns {Struct.ASTNode}
	#endregion
	static parseHeader = function(_keyword) {
		var _open = current_token;
		var _expression = parseExpression();
		if (_expression.kind == __GMLC_NodeKind_Update) && !_expression.prefix
		&& (_open.type == __GMLC_TokenType_Punctuation) && (_open.value == "(")
		&& (previous_token != undefined) && (previous_token.type == __GMLC_TokenType_Operator)
		&& ((previous_token.value == "++") || (previous_token.value == "--")) {
			__report("GMLC1033", previous_token, [previous_token.value, _keyword]);
		}
		return _expression;
	};

	#region jsDoc
	/// @func    parseWhileStatement()
	/// @desc    Parses `while test body`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTWhile}
	#endregion
	static parseWhileStatement = function() {
		var _first = current_token;
		// Assume current_token is while
		nextToken(); // Move past while
		var _test = parseHeader("while");
		var _body = parseBody();
		return finish(new ASTWhile(undefined, _test, _body), _first);
	};

	#region jsDoc
	/// @func    parseRepeatStatement()
	/// @desc    Parses `repeat count body`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTRepeat}
	#endregion
	static parseRepeatStatement = function() {
		var _first = current_token;
		// Assume current_token is repeat
		nextToken(); // Move past repeat
		var _count = parseHeader("repeat");
		var _body = parseBody();
		return finish(new ASTRepeat(undefined, _count, _body), _first);
	};

	#region jsDoc
	/// @func    parseWithStatement()
	/// @desc    Parses `with target body`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTWith}
	#endregion
	static parseWithStatement = function() {
		var _first = current_token;
		// Assume current_token is with
		nextToken(); // Move past with
		var _target = parseHeader("with");
		var _body = parseBody();
		return finish(new ASTWith(undefined, _target, _body), _first);
	};

	#region jsDoc
	/// @func    parseDoUntilStatement()
	/// @desc    Parses `do body until test`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTDoUntil}
	#endregion
	static parseDoUntilStatement = function() {
		var _first = current_token;
		// Assume current_token is do
		nextToken(); // Move past do
		var _body = parseBody();
		if (!isKeyword("until")) __fail("GMLC1025");
		nextToken();
		var _test = parseExpression();
		return finish(new ASTDoUntil(undefined, _body, _test), _first);
	};

	#region jsDoc
	/// @func    parseSwitchStatement()
	/// @desc    Parses `switch value { case x: ... default: ... }`; a second `default` gets warning GMLC1008.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTSwitch}
	#endregion
	static parseSwitchStatement = function() {
		var _first = current_token;
		nextToken(); // Move past switch
		var _discriminant = parseExpression(); // Parse the switch expression
		var _open = current_token;
		expectToken(__GMLC_TokenType_Punctuation, "{"); // Ensure { and consume it
		var _cases = [];
		var _hasDefault = false;
		while (current_token != undefined) && !isPunctuation("}") {
			var _caseFirst = current_token;
			if (isKeyword("case")) {
				nextToken(); //consume case
				var _test = parseExpression();
				expectToken(__GMLC_TokenType_Punctuation, ":"); // Ensure : and consume it
				var _clause = new ASTCase(undefined, _test, __parseCaseBody());
			}
			else if (isKeyword("default")) {
				// GameMaker uses the last `default`
				if (_hasDefault) __report("GMLC1008", current_token);
				_hasDefault = true;
				nextToken(); //consume default
				expectToken(__GMLC_TokenType_Punctuation, ":"); // Ensure : and consume it
				var _clause = new ASTDefault(undefined, __parseCaseBody());
			}
			else {
				__fail("GMLC1007");
			}
			array_push(_cases, finish(_clause, _caseFirst));
		}
		if (current_token == undefined) __fail("GMLC1003", _open);
		nextToken();
		return finish(new ASTSwitch(undefined, _discriminant, _cases), _first);
	};

	#region jsDoc
	/// @func    parseTryCatchStatement()
	/// @desc    Parses `try body [catch (name) body] [finally body]`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTTry}
	#endregion
	static parseTryCatchStatement = function() {
		var _first = current_token;
		nextToken();
		var _block = parseBody();  // Parse the block of statements under try
		var _catchParam = undefined;
		var _catchBody = undefined;
		var _finallyBody = undefined;
		if (optionalToken(__GMLC_TokenType_Keyword, "catch")) {  // Move past catch
			if (!isPunctuation("(")) __fail("GMLC1020");
			var _open = current_token;
			nextToken();
			//parse and identify the exception variable as a local variable.
			_catchParam = __parseName("the name of the caught value");
			expectToken(__GMLC_TokenType_Punctuation, ")", _open);
			_catchBody = parseBody();  // Parse the block of statements under catch
		}
		if (optionalToken(__GMLC_TokenType_Keyword, "finally")) {  // Move past finally
			_finallyBody = parseBody();  // Parse the block of statements under finally
		}
		return finish(new ASTTry(undefined, _block, _catchParam, _catchBody, _finallyBody), _first);
	};

	#region jsDoc
	/// @func    parseReturnStatement()
	/// @desc    Parses `return [value]`. There is no value when a `;`, a closing bracket, the end of the file
	///          or a keyword other than `function` and `new` follows.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTReturn}
	#endregion
	static parseReturnStatement = function() {
		var _first = current_token;
		nextToken(); // Consume return
		var _argument = undefined;
		var _t = current_token;
		// dont attempt to parse if its expected to return undefined
		// dont attempt to parse if end of block statement
		var _ends = (_t == undefined) || ((_t.type == __GMLC_TokenType_Punctuation)
			&& ((_t.value == ";") || (_t.value == "}") || (_t.value == ")") || (_t.value == "]") || (_t.value == ",") || (_t.value == ":")));
		// dont attempt to parse keywords if new block is starting, or if a function is being defined.
		_ends = _ends || ((_t.type == __GMLC_TokenType_Keyword) && (_t.value != "function") && (_t.value != "new"));
		if (!_ends) _argument = parseExpression(); // Parse the return expression if any
		return finish(new ASTReturn(undefined, _argument), _first);
	};

	#region jsDoc
	/// @func    parseThrowExpression()
	/// @desc    Parses `throw value`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTThrow}
	#endregion
	static parseThrowExpression = function() {
		var _first = current_token;
		nextToken();
		var _argument = parseExpression();
		return finish(new ASTThrow(undefined, _argument), _first);
	};

	#region jsDoc
	/// @func    parseDeleteStatement()
	/// @desc    Parses `delete target`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTDelete}
	#endregion
	static parseDeleteStatement = function() {
		var _first = current_token;
		nextToken();
		var _target = parsePostfixExpression();
		return finish(new ASTDelete(undefined, _target), _first);
	};
	#endregion

	#region Expressions
	#region jsDoc
	/// @func    parseExpression()
	/// @desc    Parses one expression; nesting deeper than maxDepth stops with GMLC1030.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode}
	#endregion
	static parseExpression = function() {
		if (++depth > maxDepth) __fail("GMLC1030");
		var _expression = parseConditionalExpression();
		depth--;
		return _expression;
	};

	#region jsDoc
	/// @func    parseConditionalExpression([_left], [_first])
	/// @desc    Parses binary operators and an optional `test ? a : b`. While the nullish-chaining
	///          extension is off, `?.` stops with GMLC1013.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Struct.ASTNode} [_left]  : The left operand, already parsed
	/// @param   {Struct}         [_first] : The first token of the left operand
	/// @returns {Struct.ASTNode}
	#endregion
	static parseConditionalExpression = function(_left = undefined, _first = current_token) {
		var _test = parseBinary(1, _left, _first);
		if (!isOperator("?")) return _test;
		// `?.` belongs to the nullish-chaining extension, which is off here
		var _next = peekToken();
		if (_next != undefined) && (_next.type == __GMLC_TokenType_Punctuation) && (_next.value == ".") && (_next.start == current_token[$ "end"]) {
			var _at = __site(current_token);
			var _dot = __site(_next);
			__fail("GMLC1013", new GMLC_Span(_at.file, _at.start, _dot[$ "end"]));
		}
		nextToken(); // consume ?
		// the branches go through parseExpression so a long ?: chain hits the nesting limit, not the stack
		var _consequent = parseExpression(); // Parse the true branch
		expectToken(__GMLC_TokenType_Punctuation, ":"); // Consume :
		var _alternate = parseExpression(); // Parse the false branch
		return finish(new ASTConditional(undefined, _test, _consequent, _alternate), _first);
	};

	#region jsDoc
	/// @func    parseBinary(_minTier, [_left], [_first])
	/// @desc    Parses binary operators of tier _minTier or tighter, left to right: each operator takes as its right
	///          operand everything of a tighter tier.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Real}           _minTier : The loosest tier to take
	/// @param   {Struct.ASTNode} [_left]  : The left operand, already parsed
	/// @param   {Struct}         [_first] : The first token of the left operand
	/// @returns {Struct.ASTNode}
	#endregion
	static parseBinary = function(_minTier, _left = undefined, _first = current_token) {
		var _expression = _left ?? parseUnaryExpression();
		while (current_token != undefined) && (current_token.type == __GMLC_TokenType_Operator) {
			var _op = current_token.value;
			var _tier = __binaryTiers[$ _op];
			if (_tier == undefined) || (_tier < _minTier) break;
			nextToken();
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

	#region jsDoc
	/// @func    parseUnaryExpression()
	/// @desc    Parses the prefix operators `!`, `-`, `+`, `~`, `++` and `--`, then a postfix expression.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode}
	#endregion
	static parseUnaryExpression = function() {
		if (current_token != undefined) && (current_token.type == __GMLC_TokenType_Operator) {
			var _first = current_token;
			switch (current_token.value) {
				case "!": case "-": case "+": case "~": case "++": case "--": {
					if (++depth > maxDepth) __fail("GMLC1030");
					var _op = current_token.value;
					nextToken();
					var _argument = parseUnaryExpression(); // Right-associative
					var _node;
					if (_op == "++") || (_op == "--") {
						__checkTarget(_argument, true);
						_node = new ASTUpdate(undefined, _op, true, _argument);
					}
					else {
						_node = new ASTUnary(undefined, _op, _argument);
					}
					depth--;
					return finish(_node, _first);
				}
			}
		}
		return parsePostfixExpression();
	};

	#region jsDoc
	/// @func    parsePostfixExpression()
	/// @desc    Parses a primary and its calls, accessors and `.name` steps; a postfix `++` or `--` ends the chain.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode}
	#endregion
	static parsePostfixExpression = function() {
		var _first = current_token;
		var _expression = parsePrimaryExpression();
		var _afterDot = false;
		while (current_token != undefined) {
			if (current_token.type == __GMLC_TokenType_Punctuation) {
				switch (current_token.value) {
					case "(": {
						var _args = parseArgumentInput();
						// Dot accessor callees become CallMethodExpression so scope update is free and target is evaluated once
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
						_expression = parseBracketAccessor(_expression, _first);
						_afterDot = false;
						continue;
					}
					case ".": {
						nextToken(); // Consume .
						var _member = __parseMemberName();
						_expression = finish(new ASTIndex(undefined, "Dot", _expression, [], _member), _first);
						_afterDot = true;
						continue;
					}
				}
			}
			else if (current_token.type == __GMLC_TokenType_Operator) {
				var _extension = __gmlc_struct_get(__postfix_hooks, current_token.value);
				if (_extension != undefined) {
					var _node = _extension.parsePostfix(self, _expression, _first);
					if (_node == undefined) break;
					_expression = _node;
					_afterDot = false;
					continue;
				}
				if (current_token.value == "++") || (current_token.value == "--") {
					__checkTarget(_expression, true);
					var _op = current_token.value;
					nextToken();
					return finish(new ASTUpdate(undefined, _op, false, _expression), _first);
				}
			}
			break;
		}
		return _expression;
	};

	#region jsDoc
	/// @func    parseArgumentInput()
	/// @desc    Parses `(a, , b)`: the arguments of a call. A missing argument before a comma is an Empty node; a
	///          trailing comma adds nothing.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Array<Struct.ASTNode>}
	#endregion
	static parseArgumentInput = function() {
		var _open = current_token;
		expectToken(__GMLC_TokenType_Punctuation, "("); // Ensure ( and consume it
		var _args = [];
		while (true) {
			if (current_token == undefined) __fail("GMLC1002", undefined, [")", "the end of the file"], undefined, _open);
			if (isPunctuation(")")) break;
			if (isPunctuation(",")) {
				//handle empty argument values as undefined `func(,,,,,arg5)`
				var _site = __site(current_token);
				array_push(_args, new ASTEmpty(new GMLC_Span(_site.file, _site.start, _site.start)));
				nextToken();  // Consume the comma to continue to the next argument
				continue;
			}
			array_push(_args, parseExpression());
			if (isPunctuation(")")) break;
			__separator(")", _open);
		}
		nextToken(); // Ensure ) and consume it
		return _args;
	};

	#region jsDoc
	/// @func    parseBracketAccessor(_object, _first)
	/// @desc    Parses one accessor after an expression: `[i]`, `[i, j]`, `[@ i]`, `[@ i, j]`, `[| i]`, `[? k]`,
	///          `[# x, y]`, `[$ k]`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTIndex}
	#endregion
	static parseBracketAccessor = function(_object, _first) {
		var _openToken = current_token;
		var _open = _openToken.value;
		nextToken(); // Consume [
		//parse the index/key
		var _keys = [parseExpression()];
		if (optionalToken(__GMLC_TokenType_Punctuation, ",")) {
			//parse the second array index
			array_push(_keys, parseExpression());
		}
		expectToken(__GMLC_TokenType_Punctuation, "]", _openToken); // Consume ]
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
		var _gridKeys = (_accessor == "Grid") && !_two;
		var _oneKey = _two && ((_accessor == "List") || (_accessor == "Map") || (_accessor == "Struct"));
		if (_gridKeys || _oneKey) {
			__fail("GMLC1001", previous_token, [_open, (_accessor == "Grid") ? "2" : "1"], "GMLC1001.accessor-keys");
		}
		return finish(new ASTIndex(undefined, _accessor, _object, _keys, undefined), _first);
	};

	#region jsDoc
	/// @func    parsePrimaryExpression()
	/// @desc    Parses a literal, a name, a parenthesised expression, an array or struct literal, a template string, a
	///          function expression or `new`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode}
	#endregion
	static parsePrimaryExpression = function() {
		if (current_token == undefined) __fail("GMLC1002", current_token, ["an expression", "the end of the file"]);
		var _first = current_token;
		switch (current_token.type) {
			// Handle literals
			case __GMLC_TokenType_Number:
			case __GMLC_TokenType_String: {
				nextToken();
				return finish(__literal(_first), _first);
			}
			case __GMLC_TokenType_TemplateStringBegin: return parseTemplate();
			case __GMLC_TokenType_Identifier: {
				var _extension = __gmlc_struct_get(__primary_hooks, current_token.value);
				if (_extension != undefined) {
					var _node = _extension.parsePrimary(self);
					if (_node != undefined) return _node;
				}
				nextToken(); // Move past the identifier
				return finish(new ASTIdentifier(undefined, _first.name), _first);
			}
			case __GMLC_TokenType_Keyword: {
				switch (current_token.value) {
					case "function": return parseFunctionExpr();
					case "new":      return parseNewExpression();
				}
			break;}
			case __GMLC_TokenType_Punctuation: {
				switch (current_token.value) {
					case "(": {
						// Handle expressions wrapped in parentheses
						// parentheses leave no node
						var _open = current_token;
						nextToken(); // Consume (
						var _inner = parseExpression();
						expectToken(__GMLC_TokenType_Punctuation, ")", _open);
						return _inner;
					}
					case "[": case "[@": return parseArrayCreation();
					case "{": return parseStructCreation();
				}
			break;}
		}
		__fail("GMLC1001", current_token, [current_token.name]);
	};

	#region jsDoc
	/// @func    parseTemplate()
	/// @desc    Parses `$"text {expression} text"`: the unescaped text parts and the expressions between them.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTTemplateString}
	#endregion
	static parseTemplate = function() {
		var _first = current_token;
		var _strings = [current_token.value];
		var _exprs = [];
		//consume the beginning
		nextToken();
		while (true) {
			if (current_token == undefined) __fail("GMLC1002", undefined, ["}", "the end of the file"], undefined, _first);
			if (current_token.type == __GMLC_TokenType_TemplateStringMiddle) || (current_token.type == __GMLC_TokenType_TemplateStringEnd) {
				// an empty `{}`: the span covers both braces
				var _before = __site(tokens[token_index - 1]);
				var _after = __site(current_token);
				__fail("GMLC1014", new GMLC_Span(_after.file, _before[$ "end"] - 1, _after.start + 1));
			}
			array_push(_exprs, parseExpression());
			if (current_token == undefined) __fail("GMLC1002", undefined, ["}", "the end of the file"], undefined, _first);
			if (current_token.type == __GMLC_TokenType_TemplateStringMiddle) {
				array_push(_strings, current_token.value);
				nextToken();  // Consume the middle segment
				continue;
			}
			if (current_token.type == __GMLC_TokenType_TemplateStringEnd) {
				//add the template strings end, then consume
				array_push(_strings, current_token.value);
				nextToken();
				break;
			}
			__fail("GMLC1002", current_token, ["}", current_token.name]);
		}
		return finish(new ASTTemplateString(undefined, _strings, _exprs), _first);
	};

	#region jsDoc
	/// @func    parseArrayCreation()
	/// @desc    Parses `[a, b]`; an element left out stops with GMLC1017.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTArrayLiteral}
	#endregion
	static parseArrayCreation = function() {
		var _first = current_token;
		nextToken();
		var _elements = [];
		while (!isPunctuation("]")) {
			if (current_token == undefined) __fail("GMLC1002", undefined, ["]", "the end of the file"], undefined, _first);
			if (isPunctuation(",")) __fail("GMLC1017");
			array_push(_elements, parseExpression());
			if (isPunctuation("]")) break;
			__separator("]", _first);
		}
		nextToken();
		return finish(new ASTArrayLiteral(undefined, _elements), _first);
	};

	#region jsDoc
	/// @func    parseStructCreation()
	/// @desc    Parses `{key: value, "key": value, name}`. As in GameMaker, a name or a number alone is shorthand:
	///          `{a}` is `{a: a}`, `{5}` is `{5: 5}`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTStructLiteral}
	#endregion
	static parseStructCreation = function() {
		var _first = current_token;
		nextToken();
		var _entries = [];
		while (!isPunctuation("}")) {
			if (current_token == undefined) __fail("GMLC1002", undefined, ["}", "the end of the file"], undefined, _first);
			var _keyToken = current_token;
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
					if (!__isAliasWord(_keyToken)) __fail("GMLC1015", _keyToken, [_keyToken.name]);
					_key = _keyToken.name;
				break;}
				default: {
					__fail("GMLC1015", _keyToken, [_keyToken.name]);
				}
			}
			nextToken();  // Move past the identifier
			var _value;
			var _shorthand = false;
			if (optionalToken(__GMLC_TokenType_Punctuation, ":")) {
				_value = parseExpression();
			}
			else {
				_shorthand = true;
				if (_keyToken.type == __GMLC_TokenType_Identifier) {
					_value = finish(new ASTIdentifier(undefined, _key), _keyToken);
				}
				else if (_keyToken.type == __GMLC_TokenType_Number) {
					_value = finish(__literal(_keyToken), _keyToken);
				}
				else {
					__fail("GMLC1002", current_token, [":", (current_token != undefined) ? current_token.name : "the end of the file"]);
				}
			}
			//push the key and the value
			array_push(_entries, finish(new ASTStructEntry(undefined, _key, _quoted, _shorthand, _value), _keyToken));
			if (isPunctuation("}")) break;
			__separator("}", _first);
		}
		nextToken();
		return finish(new ASTStructLiteral(undefined, _entries), _first);
	};

	#region jsDoc
	/// @func    parseFunctionExpr()
	/// @desc    Parses `function [name](...) [: Parent(...)] [constructor] {}` in an expression.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTFunctionExpr}
	#endregion
	static parseFunctionExpr = function() {
		var _first = current_token;
		nextToken();
		var _name = undefined;
		if (current_token != undefined) && (current_token.type == __GMLC_TokenType_Identifier) {
			_name = current_token.name;
			nextToken();
		}
		var _rest = parseFunctionRest();
		return finish(new ASTFunctionExpr(undefined, _name, _rest.is_constructor, _rest.params, _rest.parent, _rest.body), _first);
	};

	#region jsDoc
	/// @func    parseNewExpression()
	/// @desc    Parses `new Callee(args)`: the callee is a name or a parenthesised expression with `.name` and index
	///          steps; the first argument list belongs to `new`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNew}
	#endregion
	static parseNewExpression = function() {
		var _first = current_token;
		nextToken();
		var _calleeFirst = current_token;
		var _callee;
		if (isPunctuation("(")) {
			var _open = current_token;
			nextToken();
			_callee = parseExpression();
			expectToken(__GMLC_TokenType_Punctuation, ")", _open);
		}
		else {
			_callee = __parseName("a constructor");
		}
		while (current_token != undefined) && (current_token.type == __GMLC_TokenType_Punctuation) {
			switch (current_token.value) {
				case ".": {
					nextToken(); // Consume .
					var _member = __parseMemberName();
					_callee = finish(new ASTIndex(undefined, "Dot", _callee, [], _member), _calleeFirst);
					continue;
				}
				case "[": case "[@": case "[|": case "[?": case "[#": case "[$": {
					_callee = parseBracketAccessor(_callee, _calleeFirst);
					continue;
				}
			}
			break;
		}
		var _args = isPunctuation("(") ? parseArgumentInput() : [];
		return finish(new ASTNew(undefined, _callee, _args), _first);
	};
	#endregion
	#endregion

	#region Private
	#region Setup
	#region jsDoc
	/// @func    __parseEnumValues()
	/// @desc    Parses the expanded value of every enum member to its `init` expression.
	/// @self    GMLC_Gen_2_Parser
	#endregion
	static __parseEnumValues = function() {
		var _tokens = tokens;
		var _e = 0; repeat (array_length(script.enums)) {
			var _members = script.enums[_e].members;
			var _m = 0; repeat (array_length(_members)) {
				var _value = _members[_m].expanded;
				if (_value != undefined) {
					__startTokens(_value);
					var _init = parseExpression();
					if (current_token != undefined) __fail("GMLC1002", current_token, ["the end of the enum value", current_token.name]);
					_members[_m].init = _init;
				}
			_m++}
		_e++}
		__startTokens(_tokens);
		token_index = token_count;
		current_token = undefined;
	};

	#region jsDoc
	/// @func    __initializeExtensions()
	/// @desc    Resets the extensions' state and indexes the words and operators their hooks start at.
	/// @self    GMLC_Gen_2_Parser
	#endregion
	static __initializeExtensions = function() {
		extension_state = {};
		__extension_id = 0;
		__statement_hooks = {};
		__primary_hooks = {};
		__postfix_hooks = {};
		var _extensions = env.extensions;
		var _x = 0; repeat (array_length(_extensions)) {
			var _extension = _extensions[_x];
			extension_state[$ _extension.name] = {};
			var _w = 0; repeat (array_length(_extension.statementWords)) {
				__statement_hooks[$ _extension.statementWords[_w]] = _extension;
			_w++}
			var _w = 0; repeat (array_length(_extension.primaryWords)) {
				__primary_hooks[$ _extension.primaryWords[_w]] = _extension;
			_w++}
			var _w = 0; repeat (array_length(_extension.postfixOperators)) {
				__postfix_hooks[$ _extension.postfixOperators[_w]] = _extension;
			_w++}
		_x++}
	};

	#region jsDoc
	/// @func    __extensionStatement()
	/// @desc    The statement a switched-on extension parses at a name that starts one, else undefined.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __extensionStatement = function() {
		if (current_token == undefined) || (current_token.type != __GMLC_TokenType_Identifier) return undefined;
		var _extension = __gmlc_struct_get(__statement_hooks, current_token.value);
		return (_extension != undefined) ? _extension.parseStatement(self) : undefined;
	};

	#region jsDoc
	/// @func    __startTokens(_tokens)
	/// @desc    Starts reading a token array from its first token.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Array<Struct>} _tokens : The tokens
	#endregion
	static __startTokens = function(_tokens) {
		tokens = _tokens;
		token_count = array_length(_tokens);
		token_index = 0;
		current_token = (token_count > 0) ? _tokens[0] : undefined;
		previous_token = undefined;
	};
	#endregion

	#region Diagnostics and spans
	#region jsDoc
	/// @func    __separator(_closer, _open)
	/// @desc    Takes the comma between two items of a list; anything else stops with GMLC1016.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {String} _closer : The bracket that ends the list
	/// @param   {Struct} _open   : The bracket that opened it
	#endregion
	static __separator = function(_closer, _open) {
		if (current_token == undefined) __fail("GMLC1002", undefined, [_closer, "the end of the file"], undefined, _open);
		if (!isPunctuation(",")) __fail("GMLC1016", current_token, [_closer, current_token.name], undefined, _open);
		nextToken();  // Skip the comma
	};

	#region jsDoc
	/// @func    __report(_code, [_at], [_args], [_messageId], [_opener])
	/// @desc    Records a diagnostic at a token or span; undefined is the end of the file.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {String}        _code        : The code
	/// @param   {Struct}        [_at]        : A token or a span
	/// @param   {Array<String>} [_args]      : The values the message's template takes
	/// @param   {String}        [_messageId] : The code, or the code and a variant key
	/// @param   {Struct}        [_opener]    : The bracket left open
	#endregion
	static __report = function(_code, _at = current_token, _args = undefined, _messageId = _code, _opener = undefined) {
		var _span;
		if (_at == undefined) {
			var _end = program.file.byteLength();
			_span = new GMLC_Span(program.file.file_id, _end, _end);
		}
		else {
			var _site = __site(_at);
			_span = new GMLC_Span(_site.file, _site.start, _site[$ "end"]);
		}
		var _diagnostic = new GMLC_Diagnostic(_code, _span, _args, _messageId);
		if (_opener != undefined) {
			var _open = __site(_opener);
			array_push(_diagnostic.labels, new GMLC_Label(new GMLC_Span(_open.file, _open.start, _open[$ "end"]), _code + ".unclosed-delimiter", [_opener.name]));
		}
		array_push(diagnostics, _diagnostic);
	};

	#region jsDoc
	/// @func    __fail(_code, [_at], [_args], [_messageId], [_opener])
	/// @desc    Records a syntax error and stops: the parser does not recover.
	/// @self    GMLC_Gen_2_Parser
	#endregion
	static __fail = function(_code, _at = current_token, _args = undefined, _messageId = _code, _opener = undefined) {
		__report(_code, _at, _args, _messageId, _opener);
		__gmlc_throw_diagnostics(diagnostics, program[$ "sources"] ?? new GMLC_SourceTable(program.file));
	};

	#region jsDoc
	/// @func    __site(_t)
	/// @desc    Where a token counts in a span: at its use when a macro or an enum reference made it.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Struct} _t : The token
	/// @returns {Struct}
	#endregion
	static __site = function(_t) {
		var _origin = _t[$ "origin"];
		return (_origin != undefined) ? _origin.use_span : _t;
	};

	#region jsDoc
	/// @func    __targetPragmas(_from, _to, _statement)
	/// @desc    Targets the pragmas _from to _to - 1, written before this statement, at its whole span.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Real}           _from      : The first pragma
	/// @param   {Real}           _to        : The pragma after the last
	/// @param   {Struct.ASTNode} _statement : The statement
	#endregion
	static __targetPragmas = function(_from, _to, _statement) {
		if (_to == _from) return;
		var _span = _statement.span;
		var _target = new GMLC_Span(_span.file, _span.start, _span[$ "end"]);
		var _p = _from; repeat (_to - _from) {
			script.pragmas[_p].target = _target;
		_p++}
	};

	#region jsDoc
	/// @func    __targetFunctionPragmas()
	/// @desc    Targets each `gml_pragma("@NoOp")` at the function it stands in; outside every function it targets
	///          nothing.
	/// @self    GMLC_Gen_2_Parser
	#endregion
	static __targetFunctionPragmas = function() {
		var _pragmas = script.pragmas;
		var _i = 0; repeat (array_length(_pragmas)) {
			var _pragma = _pragmas[_i];
			// a comment pragma keeps its statement
			if (program.file.textBetween(_pragma.span.start, _pragma.span.start + 1) != "/") {
				var _function = __functionAround(script, _pragma.span);
				_pragma.target = (_function != undefined) ? new GMLC_Span(_function.span.file, _function.span.start, _function.span[$ "end"]) : undefined;
			}
		_i++}
	};

	#region jsDoc
	/// @func    __functionAround(_node, _span)
	/// @desc    The innermost function node under _node whose span holds _span, or undefined.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Struct.ASTNode}   _node : The node to search
	/// @param   {Struct.GMLC_Span} _span : The span
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __functionAround = function(_node, _span) {
		var _children = _node.children();
		var _i = 0; repeat (array_length(_children)) {
			var _child = _children[_i];
			var _s = _child.span;
			if (_s != undefined) && (_s.file == _span.file) && (_s.start <= _span.start) && (_s[$ "end"] >= _span[$ "end"]) {
				var _inner = __functionAround(_child, _span);
				if (_inner != undefined) return _inner;
				var _kind = _child.kind;
				return ((_kind == __GMLC_NodeKind_FunctionDecl) || (_kind == __GMLC_NodeKind_ConstructorDecl) || (_kind == __GMLC_NodeKind_FunctionExpr)) ? _child : undefined;
			}
		_i++}
		return undefined;
	};
	#endregion

	#region Parse helpers
	#region jsDoc
	/// @func    __checkTarget(_target, _update)
	/// @desc    Stops with GMLC1004 unless _target can be assigned. A literal from a macro or an enum member is left for
	///          the resolver to report; `++` and `--` take any literal.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Struct.ASTNode} _target : The target
	/// @param   {Bool}           _update : Whether it is the target of `++` or `--`
	#endregion
	static __checkTarget = function(_target, _update) {
		switch (_target.kind) {
			case __GMLC_NodeKind_Identifier:
			case __GMLC_NodeKind_Index:
			return;
			case __GMLC_NodeKind_Literal: {
				if (_update) || (_target.origin != undefined) return;
			break;}
		}
		__fail("GMLC1004", _target.span, undefined, _update ? "GMLC1004.update" : "GMLC1004");
	};

	#region jsDoc
	/// @func    __parseName(_what, [_thenIsName])
	/// @desc    Takes a name. Keywords are not names in GameMaker, except `then` when _thenIsName.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {String} _what         : What was expected, for the error
	/// @param   {Bool}   [_thenIsName] : Whether `then` is a name here
	/// @returns {String}
	#endregion
	static __parseName = function(_what, _thenIsName = false) {
		var _first = current_token;
		if (_first == undefined) __fail("GMLC1002", current_token, [_what, "the end of the file"]);
		var _then = _thenIsName && (_first.type == __GMLC_TokenType_Keyword) && (_first.value == "then");
		if (_first.type != __GMLC_TokenType_Identifier) && (!_then) {
			__fail("GMLC1002", current_token, [_what, _first.name]);
		}
		nextToken();
		return finish(new ASTIdentifier(undefined, _first.name), _first);
	};

	#region jsDoc
	/// @func    __parseCaseBody()
	/// @desc    The statements of a `case` or `default` up to the next `case`, `default` or `}`.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {Array<Struct.ASTNode>}
	#endregion
	static __parseCaseBody = function() {
		var _body = [];
		while (current_token != undefined) && !isPunctuation("}") && !isKeyword("case") && !isKeyword("default") {
			array_push(_body, parseStatement());
		}
		return _body;
	};

	#region jsDoc
	/// @func    __parseMemberName()
	/// @desc    Takes the name after `.`: an identifier, a keyword or an alias word.
	/// @self    GMLC_Gen_2_Parser
	/// @returns {String}
	#endregion
	static __parseMemberName = function() {
		if (current_token == undefined) __fail("GMLC1002", current_token, ["a name after .", "the end of the file"]);
		switch (current_token.type) {
			case __GMLC_TokenType_Identifier:
			case __GMLC_TokenType_Keyword: {
				var _name = current_token.name;
				nextToken();
				return _name;
			}
			case __GMLC_TokenType_Operator: {
				if (__isAliasWord(current_token)) {
					var _name = current_token.name;
					nextToken();
					return _name;
				}
			break;}
		}
		__fail("GMLC1002", current_token, ["a name after .", current_token.name]);
	};

	#region jsDoc
	/// @func    __isAliasWord(_t)
	/// @desc    Whether an operator token is an alias word (`and`, `div`, ...), which arrive as operators.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Struct} _t : The token
	/// @returns {Bool}
	#endregion
	static __isAliasWord = function(_t) {
		return __char_is_alphabetic(string_ord_at(_t.name, 1));
	};

	#region jsDoc
	/// @func    __literal(_t)
	/// @desc    A Literal node of a number or string token.
	/// @self    GMLC_Gen_2_Parser
	/// @param   {Struct} _t : The token
	/// @returns {Struct.ASTLiteral}
	#endregion
	static __literal = function(_t) {
		return new ASTLiteral(undefined, (_t.type == __GMLC_TokenType_String) ? "string" : _t.ty, _t.name, _t.value);
	};
	#endregion
	#endregion
}
