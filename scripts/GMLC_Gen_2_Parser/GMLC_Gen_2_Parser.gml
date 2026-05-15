#region Parser.gml

	#region 2. Parser Module
	/*
	Purpose: To take tokens from the Tokenizer and build an Abstract Syntax Tree (AST) that represents the program structure.

	Methods:

	parse(tokens): Convert a list of tokens into an AST.
	parseExpression(tokens): Parse an expression from tokens.
	parseStatement(tokens): Parse a statement from tokens.
	*/
	#endregion
	function GMLC_Gen_2_Parser(_env) constructor {
		env = _env;

		finished = false;
		tokens = undefined;
		currentTokenIndex = 0;
		currentToken = undefined;
		currentFunction = undefined;
		currentMetadataFunctionName = undefined;
		currentScope = ScopeType_GLOBAL; //used to change `function(){}` into `method(self, function(){}` when applicable
		scriptAST = undefined;

		lastFiveTokens = array_create(5, undefined);

		static initialize = function(_program) {
			finished = false;

			program = _program;
			tokens = _program.tokens;
			currentFunction = undefined;
			currentMetadataFunctionName = undefined;
			var _sourceInfo = (array_length(tokens) > 0) ? currentSourceInfo(tokens[0].sourceInfo) : currentSourceInfo(program.sourceInfo);

			scriptAST = new ASTScript(_sourceInfo);
			currentScript = scriptAST;

			//apply the variable names and token streams from program to ast
			scriptAST.MacroVar      = program.MacroVar;
			scriptAST.MacroVarNames = program.MacroVarNames;

			scriptAST.EnumVar      = program.EnumVar;
			scriptAST.EnumVarNames = program.EnumVarNames;

			scriptAST.GlobalVar      = program.GlobalVar;
			scriptAST.GlobalVarNames = program.GlobalVarNames;

			// Note this function isnt actually async, so if there is a module with tons of lines of code its possible for this to cause lag.
			// For development i just said fuck it though.

			replaceAllMacrosAndEnums(tokens);

			currentTokenIndex = 0;
			currentToken = (array_length(tokens) > 0) ? tokens[currentTokenIndex] : undefined;

			operatorStack = []; // Stack for operators
			operandStack = []; // Stack for operands (AST nodes)

		};

		static cleanup = function() {
			// i mean idk, what do you wanna do?
		}
		
		static currentSourceInfo = function(_sourceInfo, _functionName=undefined) {
			var _resolvedFunctionName = _functionName ?? ((currentFunction != undefined) ? currentFunction.name : (currentMetadataFunctionName ?? _sourceInfo.functionName));
			return new GMLC_SourceInfo(_sourceInfo.fileName, _resolvedFunctionName, _sourceInfo.lineString, _sourceInfo.line, _sourceInfo.column, _sourceInfo.byteStart, _sourceInfo.byteEnd);
		}

		static parseAll = function() {
			while (!finished) {
				parseNext();
			}

			return scriptAST;
		};

		static parseNext = function() {
			if (currentToken != undefined) {

				//frequently people will accidently include multiple ; at the end of their line, just ignore this.
				while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}

				if (currentToken == undefined) return;

				var statement = parseStatement();

				//frequently people will accidently include multiple ; at the end of their line, just ignore this.
				while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}

				if (statement) {
					array_push(scriptAST.statements.statements, statement);
				}
			}
			else {
				finished = true;
			}
		};

		static nextToken = function() {
			lastFiveTokens[0] = lastFiveTokens[1];
			lastFiveTokens[1] = lastFiveTokens[2];
			lastFiveTokens[2] = lastFiveTokens[3];
			lastFiveTokens[3] = lastFiveTokens[4];
			lastFiveTokens[4] = currentToken;

			currentTokenIndex++;
			if (currentTokenIndex < array_length(tokens)) {
				currentToken = tokens[currentTokenIndex];
			}
			else {
				currentToken = undefined; // End of token stream
			}
		};

		static peekToken = function() {
			if (currentTokenIndex + 1 < array_length(tokens)) {
				return tokens[currentTokenIndex + 1];
			}
			else {
				return undefined; // No more tokens
			}
		};

		static replaceAllMacrosAndEnums = function(_tokens) {
			var _loop_count = 0;
			var _hasChanged = true;
			while (_hasChanged) { //recursively ensure all macros and enums have been applied
				_hasChanged = false;
				for (var _i = 0; _i < array_length(_tokens); _i++) {
					var _token = _tokens[_i];

					if (_token.type == __GMLC_TokenType_Identifier)
					|| (_token.type == __GMLC_TokenType_Function) {

						var _lookup = _token.name;
						var _scopeType = __find_ScopeType_from_string(_lookup);

						if (_scopeType == ScopeType_MACRO) {

							var _macroTokens = currentScript.MacroVar[$ _lookup];

							array_delete(_tokens, _i, 1); //remove the macro from the token array
							array_insert_ext(_tokens, _i, _macroTokens); //insert the macro definition into the token array

							_hasChanged = true;
						}

						if (_token.type == __GMLC_TokenType_Identifier)
						&& (_scopeType == ScopeType_ENUM) {
							var _header = _token.value;

							var _next1 = (_i+1 < array_length(_tokens)) ? _tokens[_i+1] : undefined;
							var _next2 = (_i+2 < array_length(_tokens)) ? _tokens[_i+2] : undefined;
							var _memberIsKey = (_next2 != undefined)
							    && ((_next2.type == __GMLC_TokenType_Identifier)
							    ||  (_next2.type == __GMLC_TokenType_UniqueVariable)
							    ||  (_next2.type == __GMLC_TokenType_Function)
							    ||  (_next2.type == __GMLC_TokenType_Number
							        && __char_is_alphabetic(ord(string_char_at(_next2.name, 1)))));

							if (_next1 != undefined)
							&& (_next1.type == __GMLC_TokenType_Punctuation)
							&& (_next1.value == ".")
							&& _memberIsKey {

								var _member = _next2.name;
								var _enumTokens = variable_clone(currentScript.EnumVar[$ _header][$ _member]);

								array_delete(_tokens, _i, 3); //remove the enum from the token array
								array_insert_ext(_tokens, _i, _enumTokens); //insert the enum definition into the token array

								_hasChanged = true;
							}
						}

					}
				}
				_loop_count++
				if (_loop_count > 10_000) {
					throw_gmlc_error($"Recursive Macro or Enum Declaration detected! Quitting", currentToken.line, currentToken.lineString, currentSourceInfo(currentToken.sourceInfo).column)
				}
			}
		}

		#region AST Builder Methods

		static parseStatement = function() {
			switch (currentToken.value) {
				case "if":			return parseIfStatement();
				case "for":			return parseForStatement();
				case "while":		return parseWhileStatement();
				case "do":			return parseDoUntilStatement();  // Note: Adjust this if the actual keyword differs
				case "switch":		return parseSwitchStatement();
				case "with":		return parseWithStatement();
				case "repeat":		return parseRepeatStatement();
				case "try":			return parseTryCatchStatement();
				case "throw":		return parseThrowExpression();
				case "function":	parseFunctionDeclaration() return undefined;
				//case "let":			//
				case "var":			//
				case "static":		//
				case "globalvar":	return parseVariableDeclaration();
				case "continue":	return parseContinueStatement();
				case "break":		return parseBreakStatement();
				case "exit":		return parseExitStatement();
				case "return":		return parseReturnStatement();
				case "delete":		return parseDeleteStatement();
				//case "#macro":		return undefined;
				//case "enum":		return undefined;
				case "{":			return parseBlock();
				default:			return parseExpressionStatement();  // Assume any other token starts an expression statement
			}
		};

		static parseBlock = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			if (currentToken.value == "{") {
				nextToken(); // Consume the {
				var _statements = [];
				while (currentToken != undefined && currentToken.value != "}") {
					//specifically Juju Adams will use `;` in macros to denote the next line, i really only ever expect a block statement to start with a `;` if its a Juju macro
					//frequently people will accidently include multiple ; at the end of their line, just ignore this.
					while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}
					if (currentToken == undefined || currentToken.value == "}") break;

					var _statement = parseStatement();

					if (_statement != undefined) {
						array_push(_statements, _statement);
					}

					//frequently people will accidently include multiple ; at the end of their line, just ignore this.
					while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}
					if (currentToken == undefined || currentToken.value == "}") break;

					// Parse each statement until } is found
					// Optional: Handle error checking for unexpected end of file
				}

				//frequently people will accidently include multiple ; at the end of their line, just ignore this.
				while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}

				nextToken(); // Consume the }

				//compile better code
				if (array_length(_statements) == 0) {
					return new ASTEmpty(sourceInfo);
				}

				if (array_length(_statements) == 1) {
					return _statements[0];
				}

				return new ASTBlockStatement(_statements, sourceInfo); // Return a block statement containing all parsed statements
			}
			else {
				// If no {, its a single statement block
				var singleStatement = parseStatement();

				//frequently people will accidently include multiple ; at the end of their line, just ignore this.
				while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}

				return new ASTBlockStatement([singleStatement], sourceInfo);
			}
		};

		#region Statements
		#region Keyword Statement types

		static parseIfStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			// Assume currentToken is if
			nextToken(); // Move past if
			var _condition = parseConditionalExpression();
			optionalToken(__GMLC_TokenType_Keyword, "then")
			var _codeBlock = parseBlock();
			var _elseBlock = undefined;



			if (currentToken != undefined)
			&& (currentToken.value == "else") {
				nextToken(); // Consume else
				_elseBlock = parseBlock();
			}
			return new ASTIfStatement(_condition, _codeBlock, _elseBlock, sourceInfo);
		};

		static parseForStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			nextToken(); // Move past for
			expectToken(__GMLC_TokenType_Punctuation, "(");

			//example of a really cursed for statement, but it is valid syntax
			//////////////////////////////////////////////////////////////
			//for (;; {
			//  show_message("me second!");
			//  break;
			//}) {
			//  show_message("me first!");
			//}
			/////////////////////////////////////////////////////////////



			//it's possible to make a for statement with no initializer variable
			if (currentToken.name != ";") {
				if (currentToken.value == "var") {
					var _initialization = parseVariableDeclaration();
				}
				else {
					var _initialization = parseExpression();
				}
			}
			else {
				var _initialization = undefined;
			}
			optionalToken(__GMLC_TokenType_Punctuation, ";");

			//it's possible to make a for statement with no conditional statement
			if (currentToken.name != ";") {
				var _condition = parseConditionalExpression();
			}
			else {
				var _condition = undefined;
			}
			optionalToken(__GMLC_TokenType_Punctuation, ";");

			if (currentToken.name != ")" && currentToken.name != ";") {
				var _increment = parseBlock();
			}
			else {
				var _increment = undefined;
			}

			//these are typically already handled by the parseBlock
			//frequently people will accidently include multiple ; at the end of their line, just ignore this.
			while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}

			expectToken(__GMLC_TokenType_Punctuation, ")");

			var _codeBlock = parseBlock();
			return new ASTForStatement(_initialization, _condition, _increment, _codeBlock, sourceInfo);
		};

		static parseWhileStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			// Assume currentToken is while
			nextToken(); // Move past while
			var _condition = parseConditionalExpression();
			var _codeBlock = parseBlock();
			return new ASTWhileStatement(_condition, _codeBlock, sourceInfo);
		};

		static parseRepeatStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			// Assume currentToken is repeat
			nextToken(); // Move past repeat
			var _condition = parseExpression();
			var _codeBlock = parseBlock();
			return new ASTRepeatStatement(_condition, _codeBlock, sourceInfo);
		};

		static parseDoUntilStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			// Assume currentToken is do
			nextToken(); // Move past do
			var _codeBlock = parseBlock();
			expectToken(__GMLC_TokenType_Keyword, "until");
			var _condition = parseConditionalExpression();
			return new ASTDoUntilStatement(_condition, _codeBlock, sourceInfo);
		};

		static parseSwitchStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

		    nextToken(); // Move past switch
		    var switchExpression = parseExpression(); // Parse the switch expression

			expectToken(__GMLC_TokenType_Punctuation, "{"); // Ensure { and consume it

			var cases = [];
		    var statements = undefined;

		    while (currentToken != undefined && currentToken.value != "}") {
				if (currentToken.type == __GMLC_TokenType_Keyword) {
					if (currentToken.value == "case") {
						var caseLine = currentToken.line;
							var caseLineString = currentToken.lineString;

							var caseSourceInfo = currentSourceInfo(currentToken.sourceInfo);

						expectToken(__GMLC_TokenType_Keyword, "case"); //consume case
						var _label = parseExpression();

						expectToken(__GMLC_TokenType_Punctuation, ":"); // Ensure : and consume it

						statements = [];
						array_push(cases, new ASTCaseExpression(_label, statements, caseSourceInfo));
					}
					else if (currentToken.value == "default") {
						var caseLine = currentToken.line;
							var caseLineString = currentToken.lineString;

							var caseSourceInfo = currentSourceInfo(currentToken.sourceInfo);

						nextToken(); //consume default

						expectToken(__GMLC_TokenType_Punctuation, ":"); // Ensure : and consume it

						statements = [];
						array_push(cases, new ASTCaseDefault(statements, sourceInfo));
					}
					else {
						array_push(statements, parseStatement());

						//frequently people will accidently include multiple ; at the end of their line, just ignore this.
						while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}

					}
				}
				else {
					array_push(statements, parseStatement());

					//frequently people will accidently include multiple ; at the end of their line, just ignore this.
					while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}

				}
		    }

		    expectToken(__GMLC_TokenType_Punctuation, "}"); // Ensure } and consume it

			//frequently people will accidently include multiple ; at the end of their line, just ignore this.
			while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}

		    return new ASTSwitchStatement(switchExpression, cases, sourceInfo);
		};

		static parseWithStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			// Assume currentToken is with
			nextToken(); // Move past with
			var _condition = parseExpression();
			var _codeBlock = parseBlock();
			return new ASTWithStatement(_condition, _codeBlock, sourceInfo);
		};

		static parseTryCatchStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			expectToken(__GMLC_TokenType_Keyword, "try");  // Expect the try keyword
			var _tryBlock = parseBlock();  // Parse the block of statements under try

			var _catchBlock = undefined;
			var _exceptionVar = undefined;
			if (currentToken != undefined)
			&& (currentToken.value == "catch") {
				nextToken();  // Move past catch
				expectToken(__GMLC_TokenType_Punctuation, "(");

				//parse and identify the exception variable as a local variable.
				_exceptionVar = currentToken.value;  // Parse the exception variable
				array_push((currentFunction ?? scriptAST).LocalVarNames, _exceptionVar);

				nextToken();  // Move past Identifier
				expectToken(__GMLC_TokenType_Punctuation, ")");
				_catchBlock = parseBlock();  // Parse the block of statements under catch
			}

			var _finallyBlock = undefined;
			if (currentToken != undefined)
			&& (currentToken.value == "finally") {
				nextToken();  // Move past finally
				_finallyBlock = parseBlock();  // Parse the block of statements under finally
			}

			return new ASTTryStatement(_tryBlock, _catchBlock, _exceptionVar, _finallyBlock, sourceInfo);
		};

		static parseThrowExpression = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			expectToken(__GMLC_TokenType_Keyword, "throw");  // Expect the try keyword
			var _err_message = parseExpressionStatement();  // Parse the block of statements under try

			return new ASTCallExpression(new ASTLiteral(method(undefined, throw_gmlc_error), sourceInfo, "throw_gmlc_error"), [_err_message], sourceInfo);
		};

		#endregion
		#region Keyword Executions
		static parseContinueStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			nextToken(); // Consume break
			return new ASTContinueStatement(sourceInfo);
		};

		static parseBreakStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			nextToken(); // Consume break
			return new ASTBreakStatement(sourceInfo);
		};

		static parseExitStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			nextToken(); // Consume exit
			return new ASTExitStatement(sourceInfo);
		};

		static parseReturnStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			nextToken(); // Consume return
			var expr = undefined;
			if (currentToken.name == ";") {
				// dont attempt to parse if its expected to return undefined
			}
			else if (currentToken.type == __GMLC_TokenType_Keyword)
			&& (currentToken.value != "new")
			&& (currentToken.value != "function") {
				// dont attempt to parse keywords if new block is starting, or if a function is being defined.
			}
			else if (currentToken.type == __GMLC_TokenType_Punctuation)
			&& (currentToken.value == "}") {
				// dont attempt to parse if end of block statement
			}
			else if (currentToken.type == __GMLC_TokenType_Whitespace)
			&& (currentToken.value == "\n") {
				// dont attempt to parse if end of block statement
			}
			else {
				expr = parseConditionalExpression(); // Parse the return expression if any
			}

			return new ASTReturnStatement(expr, sourceInfo);
		};

		static parseDeleteStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			nextToken(); // Consume `default`
			var expr = parseLogicalOrExpression(); // cascades down the tree and across to ternary.

			return new ASTAssignmentExpression("=", expr, new ASTLiteral(undefined, sourceInfo), sourceInfo);
		};

		#endregion
		#region Declarations / Definitions

		static parseFunctionDeclaration = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			#region `function`
			expectToken(__GMLC_TokenType_Keyword, "function");
			#endregion

			#region function `identifier` :: the function's name if provided
			var functionName = undefined;
			if (currentToken.type == __GMLC_TokenType_Identifier) {
				var functionName = currentToken.value;
				//consume the function's identifier
				nextToken();
			}
			else if (currentToken.type == __GMLC_TokenType_Function) {
				throw_gmlc_error($"Duplicate function name of existing function :: {currentToken.name}", line, lineString, sourceInfo.column)
			}
			else {
				static __anon_id = 0;
				var functionName = $"GMLC@anon@{__anon_id++}";
			}
			sourceInfo = currentSourceInfo(sourceInfo, functionName);
			#endregion

			#region function`(arguments)` :: the argument list, or an emply block statement

			var _old_metadata_function_name = currentMetadataFunctionName;
			currentMetadataFunctionName = functionName;
			var _argList = parseArgumentDefaultList();

			var _local_var_names = [];
			var _i=0; repeat(array_length(_argList.statements)) {
				var _arg = _argList.statements[_i]
				array_push(_local_var_names, _arg.identifier)
			_i++}

			#endregion

			var _isConstructor = false;
			var _parentName = undefined;
			var _parentCall = undefined;
			#region function foo() `:` bar() constructor {} :: check and consume the `:` if it has a parent defined
			if (optionalToken(__GMLC_TokenType_Punctuation, ":")) {
				#region function foo() : `bar`() constructor {} :: parse constructor parent

				var _parent = parseCallAccessExpression();

				//if its an internally defined function, like a function defined in the same program we're parsing
				if (_parent.type != __GMLC_NodeType_CallExpression) {
					throw_gmlc_error($"Trying to set a constructor parent to a non global defined value, got :: {_parent}", line, lineString, sourceInfo.column)
				}

				//if it's a global identifier
				if (!is_callable(_parent.callee.value))
				&& (_parent.callee.type == __GMLC_NodeType_Identifier)
				&& (_parent.callee.scope == ScopeType_GLOBAL)
				{
					var _ref = program.GlobalVar[$ _parent.callee.value]
					if (_ref.type != __GMLC_NodeType_ConstructorDeclaration) {
						throw_gmlc_error($"Trying to set a constructor parent to a non global defined value, got :: {_parent.callee.name}", line, lineString, sourceInfo.column)
					}
				}


				#endregion

				_parentCall = _parent;
				_parentName = _parent.callee.name;
			}
			#endregion
			#region function foo() `constructor` :: parse constructor keyword (if provided)
			if (optionalToken(__GMLC_TokenType_Keyword, "constructor")) {
				_isConstructor = true;
			}
			#endregion



			// Register function as a global variable and move its body to GlobalVar
			if (!_isConstructor) {
				var globalFunctionNode = new ASTFunctionDeclaration(
					functionName,
					_argList,
					_local_var_names,
					undefined, //will be set after body is parsed
					sourceInfo
				)
			}
			else {
				var globalFunctionNode = new ASTConstructorDeclaration(
					functionName,
					_parentName,
					_argList,
					_parentCall,
					_local_var_names,
					undefined, //will be set after body is parsed
					sourceInfo
				)
			}


			//cache the old current function, incase we are declaring a function inside a function
			var _old_function = currentFunction;
			var _old_scope = currentScope;
			currentFunction = globalFunctionNode;

			//change the scope if needed
			if (_isConstructor) currentScope = ScopeType_SELF;

			// Parse the function body and apply it
			globalFunctionNode.statements = parseBlock();

			//reset the current function
			currentFunction = _old_function;
			currentScope = _old_scope;
			currentMetadataFunctionName = _old_metadata_function_name;

			// Add to GlobalVar mapping of the Program node
			scriptAST.GlobalVar[$ functionName] = globalFunctionNode;
			array_push(scriptAST.GlobalVarNames, functionName);

			var _func_ref = new ASTIdentifier(functionName, ScopeType_GLOBAL, sourceInfo);

			// now correctly set the assignment, either a global lookup, or a method call, depending on if it's inside a constructor or not
			switch (currentScope) {
				case ScopeType_GLOBAL: {
					var _func = _func_ref;
				break;}
				case ScopeType_STATIC: {
					var _func = new ASTCallExpression(
						new ASTLiteral(method(undefined, __gmlc_method), sourceInfo, "__method"),
						[
							new ASTLiteral(undefined, sourceInfo, "undefined"),
							_func_ref
						],
						sourceInfo
					)
				break;}
				case ScopeType_SELF  : {
					var _self = new ASTUniqueIdentifier(env.getVariable("self").value, sourceInfo);
					var _func = new ASTCallExpression(
						new ASTLiteral(method(undefined, __gmlc_method), sourceInfo, "__method"),
						[
							_self,
							_func_ref
						],
						sourceInfo
					)
				break;}
			}


			// Return a reference to the function in the global scope
			return _func;
		};
		static parseArgumentDefaultList = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			expectToken(__GMLC_TokenType_Punctuation, "(");
			var parameters = [];
			while (currentToken.name != ")") {
			    var _argNode = parseArgumentDefaultSingle()
				_argNode.argument_index = array_length(parameters);

				array_push(parameters, _argNode);


			    if (currentToken.name == ",") {
			        nextToken();  // Handle multiple parameters
			    }
			}
			nextToken();  // Close parameters list

			return new ASTArgumentList(parameters, sourceInfo);

		}
		static parseArgumentDefaultSingle = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			var identifier = currentToken.value;  // Parse the parameter name
			nextToken();  // Move past Identifier

			var expr = undefined;
			if (optionalToken(__GMLC_TokenType_Operator, "=")) {
				expr = parseAssignmentExpression(); // Assignment is right-associative
			}
			else {
				expr = new ASTLiteral(undefined, sourceInfo);
			}

			return new ASTArgument(identifier, expr, undefined, sourceInfo);
		}


		static parseVariableDeclaration = function () {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);
			var _should_hoist = false
			var type = currentToken.value;  // var, globalvar, or static
			var _variable_scope = undefined;

			// convert string to scope type
			switch (type) {
				//case "let":{
				//	//dont to nuttin`!
				//break;}
				case "var":{
					_variable_scope = ScopeType_LOCAL;
				break;}
				case "static":{
					_should_hoist = true;
					_variable_scope = ScopeType_STATIC;
				break;}
				case "globalvar":{
					_variable_scope = ScopeType_GLOBAL;
				break;}
				default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?", currentToken.line, currentToken.lineString, currentSourceInfo(currentToken.sourceInfo).column)
			}


			// Fetch the array containing variable names
			var _tableArr = undefined
			if (currentFunction == undefined) {
				//script scrope
				switch (_variable_scope) {
					//case "let":{
					//	//dont to nuttin`!
					//break;}
					case ScopeType_LOCAL: _tableArr = scriptAST.LocalVarNames; break;
					case ScopeType_STATIC: throw_gmlc_error($"Script: {env.currentScriptName} at line {currentToken.line} : static can only be declared inside a function", currentToken.line, currentToken.lineString, currentSourceInfo(currentToken.sourceInfo).column); break;
					case ScopeType_GLOBAL: _tableArr = scriptAST.GlobalVarNames; break;
					default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?", currentToken.line, currentToken.lineString, currentSourceInfo(currentToken.sourceInfo).column)
				}

			}
			else {
				//function scope
				switch (_variable_scope) {
					//case "let":{
					//	//dont to nuttin`!
					//break;}
					case ScopeType_LOCAL:  _tableArr = currentFunction.LocalVarNames; break;
					case ScopeType_STATIC: _tableArr = currentFunction.StaticVarNames; break;
					case ScopeType_GLOBAL: _tableArr = scriptAST.GlobalVarNames; break;
					default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?", currentToken.line, currentToken.lineString, currentSourceInfo(currentToken.sourceInfo).column)
				}
			}


			// Cache the scoping and update if needed
			var _old_scope = currentScope;
			if (_variable_scope = ScopeType_STATIC) {
				currentScope = _variable_scope;
			}


			nextToken();

			var declarations = [];

			// this variable is used to help prevent issues where many variables are defined at once but were not properly ended with `;`:
			var _found_one = false;
			// Example:
			// var c_black = #000000,
			//     c_white = #000000,
			//
			// with (thing) { ... }

			//parse all declarations
		    while (true) {
				// optionally skip redeclarations
				var varLine = currentToken.line;
				var varLineString = currentToken.lineString;

				var varSourceInfo = currentSourceInfo(currentToken.sourceInfo);

				//these must be a identifier one can not `var try = 123`
				if (currentToken.type != __GMLC_TokenType_Identifier) {
					if (_found_one) {
						break;
					}

		            throw_gmlc_error($"Expected identifier in variable declaration.\nRecieved: {currentToken}\nLast five tokens:\n{lastFiveTokens}", varLine, varLineString, varSourceInfo.column);
		        }

				// we parse anything which starts with an identifier to ensure there is no postfix op attached to it like `++`, and accessor, or function call
		        var identifier = parsePostfixExpression();

				if (identifier.type != __GMLC_NodeType_Identifier) {
					if (_found_one) {
						break;
					}

					throw_gmlc_error($"Expected identifier in variable declaration.\nRecieved type: {identifier.type}, {currentToken}\nLast five tokens:\n{lastFiveTokens}", varLine, varLineString, varSourceInfo.column);
				}

				//push to the table array
				if (!array_contains(_tableArr, identifier)) {
					array_push(_tableArr, identifier.name);
				}

				_found_one = true;

				//fetch expression
				var expr = undefined;
				if (optionalToken(__GMLC_TokenType_Operator, "=")) {
					expr = parseConditionalExpression();
					var _declaration = new ASTVariableDeclaration(identifier, expr, _variable_scope, varSourceInfo);

					// either push it to the declarations array, or push it to the statics array
					switch (_variable_scope) {
						//case "let":{
						//	//dont to nuttin`!
						//break;}
						case ScopeType_LOCAL:
						case ScopeType_GLOBAL:{
							array_push(declarations, _declaration);
						break;}
						case ScopeType_STATIC:{
							array_push(currentFunction.StaticVarArray, _declaration)
						break;}
						default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?", currentToken.line, currentToken.lineString, currentSourceInfo(currentToken.sourceInfo).column)
					}

				}

				if (currentToken.name == ";") {
					break
				}
		        if (currentToken == undefined || currentToken.name != ",") {
		            break; // End of declaration list
		        }

		        nextToken(); // Consume , and move to the next identifier
		    }

			//reset the current scope
			currentScope = _old_scope;

			if (_should_hoist) {
				return undefined;
			}

			if (array_length(declarations) == 1) {
				return declarations[0];
			}
			else {
				return new ASTVariableDeclarationList(declarations, _variable_scope, sourceInfo);
			}
		};

		#endregion
		#region Execution

		static parseNewExpression = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			expectToken(__GMLC_TokenType_Keyword, "new");  // Expect the new keyword

			var expr = parseAccessExpression();
			expr = parseFunctionCall(expr);

			return new ASTNewExpression(expr, sourceInfo);
		};

		#endregion

		static parseExpressionStatement = function() {
			var expr = parseExpression();
			if (expr == undefined) {
				throw_gmlc_error($"Getting an error parsing expression, current token is:\n{currentToken}\nLast Five Tokens:\n{lastFiveTokens}", currentToken.line, currentToken.lineString, currentSourceInfo(currentToken.sourceInfo).column)
			}
			return expr;
		}

		#endregion

		#region Expressions
		static parseExpression = function() {
			return parseAssignmentExpression();
		};

		static parseConditionalExpression = function() {
			var expr = parseConditionalEqualityExpression();

			if (currentToken != undefined && currentToken.type == __GMLC_TokenType_Operator && currentToken.value == "?") {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);
				nextToken(); // consume ?
				var trueExpr = parseConditionalExpression();
				expectToken(__GMLC_TokenType_Punctuation, ":");
				var falseExpr = parseConditionalExpression();
				return new ASTConditionalExpression(expr, trueExpr, falseExpr, sourceInfo);
			}

			return expr;
		};

		// Handles ternary without the equality-= of parseConditionalEqualityExpression,
		// so parseAssignmentExpression can still treat = as assignment.
		static parseTernaryExpression = function() {
			var expr = parseLogicalOrExpression();

			if (currentToken != undefined && currentToken.type == __GMLC_TokenType_Operator && currentToken.value == "?") {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);
				nextToken(); // consume ?
				var trueExpr = parseConditionalExpression();
				expectToken(__GMLC_TokenType_Punctuation, ":");
				var falseExpr = parseConditionalExpression();
				return new ASTConditionalExpression(expr, trueExpr, falseExpr, sourceInfo);
			}

			return expr;
		};

		static parseAssignmentExpression = function() {
			var expr = parseTernaryExpression();
			static __arr = ["=", "+=", "-=", "*=", "/=", "^=", "&=", "|=", "%=", "??="];
			if (currentToken != undefined && currentToken.type == __GMLC_TokenType_Operator && array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseAssignmentExpression(); // Assignment is right-associative

				expr = new ASTAssignmentExpression(operator, expr, right, sourceInfo);
			}
			return expr;
		};

		static parseConditionalEqualityExpression = function() {
			var expr = parseLogicalOrExpression();
			static __arr = ["=", "==", "!="];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType_Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = (currentToken.value == "=") ? "==" : currentToken.value;

				nextToken();
				var right = parseLogicalOrExpression();
				expr = new ASTBinaryExpression(operator, expr, right, sourceInfo);
			}
			return expr;
		};

		static parseLogicalOrExpression = function() {
			var expr = parseLogicalAndExpression();
			while (currentToken != undefined && currentToken.type == __GMLC_TokenType_Operator && currentToken.value == "||") {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseLogicalAndExpression();
				expr = new ASTLogicalExpression(operator, expr, right, sourceInfo);
			}
			return parseTerneryExpression(expr); // Check if this is a conditional expression after logical operations
		};

		static parseTerneryExpression = function(expr) {

			if (currentToken != undefined && currentToken.type == __GMLC_TokenType_Operator && currentToken.value == "?") {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				expectToken(__GMLC_TokenType_Operator, "?"); // Consume ?
				var trueExpr = parseExpression(); // Parse the true branch
				expectToken(__GMLC_TokenType_Punctuation, ":"); // Consume :
				var falseExpr = parseExpression(); // Parse the false branch
				expr = new ASTConditionalExpression(expr, trueExpr, falseExpr, sourceInfo);
			}
			return expr;
		};

		static parseLogicalAndExpression = function() {
			var expr = parseLogicalXorExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType_Operator && (currentToken.value == "&&") {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseOrExpression();
				expr = new ASTLogicalExpression(operator, expr, right, sourceInfo);
			}

			return expr;
		};

		static parseLogicalXorExpression = function() {
			var expr = parseNullishExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType_Operator && (currentToken.value == "^^") {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseOrExpression();
				expr = new ASTLogicalExpression(operator, expr, right, sourceInfo);
			}

			return expr;
		};

		static parseNullishExpression = function() {
			var expr = parseBitwiseOrExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType_Operator && (currentToken.value == "??") {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseOrExpression();
				expr = new ASTNullishExpression(operator, expr, right, sourceInfo);
			}

			return expr;
		};

		static parseBitwiseOrExpression = function() {
			var expr = parseBitwiseXorExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType_Operator && (currentToken.value == "|") {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseXorExpression();
				expr = new ASTBinaryExpression(operator, expr, right, sourceInfo);
			}

			return expr;
		};

		static parseBitwiseXorExpression = function() {
			var expr = parseBitwiseAndExpression();
			while (currentToken != undefined) && (currentToken.value == "^") {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseAndExpression();
				expr = new ASTBinaryExpression(operator, expr, right, sourceInfo);
			}

			return expr;
		};

		static parseBitwiseAndExpression = function() {
			var expr = parseEqualityExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType_Operator && (currentToken.value == "&") {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseEqualityExpression();
				expr = new ASTBinaryExpression(operator, expr, right, sourceInfo);
			}

			return expr;
		};

		static parseEqualityExpression = function() {
			var expr = parseRelationalExpression();
			static __arr = ["==", "!="];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType_Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseRelationalExpression();
				expr = new ASTBinaryExpression(operator, expr, right, sourceInfo);
			}
			return expr;
		};

		static parseRelationalExpression = function() {
			var expr = parseShiftExpression();

			static __arr = ["<", "<=", ">", ">="];
			while (currentToken != undefined)
			&& (currentToken.type == __GMLC_TokenType_Operator)
			&& (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseShiftExpression();
				var _prev_expr = expr
				expr = new ASTBinaryExpression(operator, expr, right, sourceInfo);
			}
			return expr;
		};

		static parseShiftExpression = function() {
			var expr = parseAdditiveExpression();
			static __arr = ["<<", ">>"];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType_Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseAdditiveExpression();
				expr = new ASTBinaryExpression(operator, expr, right, sourceInfo);
			}
			return expr;
		};

		static parseAdditiveExpression = function() {
			var expr = parseMultiplicativeExpression();
			static __arr = ["+", "-"];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType_Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseMultiplicativeExpression();
				expr = new ASTBinaryExpression(operator, expr, right, sourceInfo);
			}
			return expr;
		};

		static parseMultiplicativeExpression = function() {
			var expr = parseUnaryExpression();
			static __arr = ["*", "/", "mod", "div"];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType_Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var right = parseUnaryExpression();
				expr = new ASTBinaryExpression(operator, expr, right, sourceInfo);
			}
			return expr;
		};

		static parseUnaryExpression = function() {
			static __arr = ["!", "+", "-", "~", "++", "--"];
			if (currentToken != undefined) && currentToken.type == __GMLC_TokenType_Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				nextToken();
				var expr = parseUnaryExpression(); // Right-associative

				if (operator == "++" || operator == "--") {
					return new ASTUpdateExpression(operator, expr, true, sourceInfo);
				}

				return new ASTUnaryExpression(operator, expr, sourceInfo);
			}
			else {
				return parsePostfixExpression();
			}
		};

		static parsePostfixExpression = function() {
			var expr = parseCallAccessExpression();
			static __arr = ["++", "--"];
			if (currentToken != undefined) && currentToken.type == __GMLC_TokenType_Operator && (array_contains(__arr, currentToken.value))
			&& !(expr.type == "Literal" && expr.scope == ScopeType_CONST) {
				var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

				var operator = currentToken.value;
				var postfixExpr = new ASTUpdateExpression(operator, expr, false, sourceInfo);
				nextToken();
				expr = postfixExpr;
			}
			return expr;
		};

		static parseCallAccessExpression = function() {
			var expr = parseAccessExpression();

			while (currentToken != undefined) {
				if (currentToken.type == __GMLC_TokenType_Punctuation) {
					switch (currentToken.value) {
						case "(": {
							expr = parseFunctionCall(expr);
						break;}
						case "[": {
							expr = parseBracketAccessor(expr);
						break;}
						case ".": {
							expr = parseDotAccessor(expr);
						break;}
						default: {
							return expr
						break;}
					}
				}
				else {
					return expr
				}
			}
			return expr;
		};

		static parseAccessExpression = function() {
			var expr = parsePrimaryExpression();

			var _should_break = false;
			while (currentToken != undefined) {
				if (currentToken.type == __GMLC_TokenType_Punctuation) {
					switch (currentToken.value) {
						case "[": {
							expr = parseBracketAccessor(expr);
						break;}
						case ".": {
							expr = parseDotAccessor(expr);
						break;}
						default: {
							return expr
						break;}
					}
				}
				else {
					return expr
				}
			}
			return expr;
		};
		
		static parsePrimaryExpression = function() {
			if (currentToken == undefined) {
				var sourceInfo = currentSourceInfo(program.sourceInfo);
				throw_gmlc_error("Unexpected end of input", sourceInfo.line, sourceInfo.lineString, sourceInfo.column);
			}
			
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			switch (currentToken.type) {
				case __GMLC_TokenType_Number:
				case __GMLC_TokenType_String:{

					// Handle literals
					var node = new ASTLiteral(currentToken.value, sourceInfo);
					nextToken();
					return node;

				break;}
				case __GMLC_TokenType_Identifier:{

					var _scopeType = __find_ScopeType_from_string(currentToken.value);

					if (_scopeType == ScopeType_MACRO) {

						var _macroTokens = variable_clone(currentScript.MacroVar[$ currentToken.value]);

						array_delete(tokens, currentTokenIndex, 1); //remove the macro from the token array
						array_insert_ext(tokens, currentTokenIndex, _macroTokens); //insert the macro definition into the token array

						return node;
					}

					if (_scopeType == ScopeType_ENUM) {
						var _header = currentToken.value
						if (optionalToken(__GMLC_TokenType_Punctuation, ".")) {
							if (currentToken.type == __GMLC_TokenType_Identifier) {
								var _member = currentToken.value;
								var _enumTokens = variable_clone(currentScript.EnumVar[$ _header][$ _member]);

								array_delete(tokens, currentTokenIndex, 1); //remove the enum from the token array
								array_insert_ext(tokens, currentTokenIndex, _enumTokens); //insert the enum definition into the token array

								return node;
							}
						}

						//this will eventually get defaulted to instance if no dot accessor is eventually found
						var node = new ASTIdentifier(currentToken.value, undefined, sourceInfo);
						nextToken(); // Move past the identifier
						return node;
					}

					if (_scopeType == ScopeType_CONST) {
						var _data = env.getConstant(currentToken.value) ?? env.getFunction(currentToken.value)
						var node = new ASTLiteral(_data.value, sourceInfo);
						nextToken(); // Move past the identifier
						return node;
					}

					if (_scopeType == ScopeType_SELF) {
						var node = new ASTIdentifier(currentToken.value, undefined, sourceInfo);
						nextToken(); // Move past the identifier
						return node;
					}

					var node = new ASTIdentifier(currentToken.value, _scopeType, sourceInfo);

					nextToken(); // Move past the identifier
					return node;

				break;}
				case __GMLC_TokenType_Function:{
					var node = new ASTLiteral(currentToken.value, sourceInfo, currentToken.name);
					nextToken(); // Move past the identifier
					return node;

				break;}
				case __GMLC_TokenType_Keyword:{
					switch (currentToken.value) {
						case "function": return parseFunctionDeclaration();
						case "new": return parseNewExpression()
						case "_GMFUNCTION_":{

						break;}
					}
				break;}
				case __GMLC_TokenType_Punctuation:{

					if (currentToken.name == "(") {
						// Handle expressions wrapped in parentheses
						nextToken(); // Consume (
						var expr = parseConditionalExpression();
						expectToken(__GMLC_TokenType_Punctuation, ")");
						return expr;
					}

					if (currentToken.value == "[") {
						return parseArrayCreation();
					}

					if (currentToken.value == "{") {
						return parseStructCreation();
					}

				break;}
				case __GMLC_TokenType_UniqueVariable:{

					// Handle literals
					var node = new ASTUniqueIdentifier(currentToken.value, sourceInfo);
					nextToken();
					return node;

				break;}
				case __GMLC_TokenType_TemplateStringBegin:{

					var _template_string = currentToken.value;

					//consume the beginning
					nextToken();

					var _arguments = [];
					var _index = 0;
					while (currentToken != undefined && currentToken.type != __GMLC_TokenType_TemplateStringEnd) {
						if (currentToken.type == __GMLC_TokenType_TemplateStringMiddle) {
							_template_string += currentToken.value;
							nextToken();  // Consume the middle segment
						}
						else {
							var _expr = parseExpression()
							array_push(_arguments, _expr); // Parse each argument as an expression
							_template_string += "{"+string(_index)+"}"
							_index++
						}
					}

					//add the template strings end, then consume
					_template_string += currentToken.value;
					nextToken();  // Consume the middle segment

					//push the template string into the beginning of the arguments
					array_insert(_arguments, 0, new ASTLiteral(_template_string, sourceInfo));

					var _literalStringFunction = new ASTLiteral(string, sourceInfo, "string");
					var _node = new ASTCallExpression(_literalStringFunction, _arguments, sourceInfo);

					return _node
				break;}
				case __GMLC_TokenType_NoOpPragma: {
					nextToken();
					if (currentToken == undefined) return undefined;
					var _node = parseStatement();
					//frequently people will accidently include multiple ; at the end of their line, just ignore this.
					while (optionalToken(__GMLC_TokenType_Punctuation, ";")) {}
					_node.skipOptimization = true;
					return _node;

				break;}
			}

			throw_gmlc_error($"Unexpected token in expression: {currentToken}\nLast five tokens were:\n{json_stringify(lastFiveTokens, true)}", line, lineString, sourceInfo.column);
		};

		static parseArrayCreation = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			var elements = [];

		    expectToken(__GMLC_TokenType_Punctuation, "[");
		    while (currentToken != undefined && currentToken.name != "]") {
		        var element = parseExpression();
				array_push(elements, element);

				if (currentToken.name == ",") {
		            nextToken();  // Skip the comma
		        }
		    }
		    expectToken(__GMLC_TokenType_Punctuation, "]");

			return new ASTCallExpression(new ASTLiteral(method(undefined, __NewGMLArray), sourceInfo, "__NewGMLArray"), elements, sourceInfo);
		};

		static parseStructCreation = function() {
		    var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			var _args = [];

		    expectToken(__GMLC_TokenType_Punctuation, "{");
		    while (currentToken != undefined && currentToken.value != "}") {
		        if (currentToken.type != __GMLC_TokenType_Identifier)
				&& (currentToken.type != __GMLC_TokenType_String)
				&& (currentToken.type != __GMLC_TokenType_UniqueVariable)
				&& (currentToken.type != __GMLC_TokenType_Number)
				&& (currentToken.type != __GMLC_TokenType_Keyword)
				&& (currentToken.type != __GMLC_TokenType_Function)
				{
		            throw_gmlc_error($"Expected identifier for struct property name.\n{currentToken}\nLast Five Tokens:\n{json_stringify(lastFiveTokens, true)}", currentToken.line, currentToken.lineString, currentSourceInfo(currentToken.sourceInfo).column);
		        }

				var key = currentToken;
		        nextToken();  // Move past the identifier

				if (optionalToken(__GMLC_TokenType_Punctuation, ":")) {
					var _prev_scope = currentScope;
					currentScope = ScopeType_SELF;

					var value = parseConditionalExpression();

					currentScope = _prev_scope;
				}
				else if (key.type == __GMLC_TokenType_String)
				     || (key.type == __GMLC_TokenType_Identifier)
				     || (key.type == __GMLC_TokenType_UniqueVariable)
				     || (key.type == __GMLC_TokenType_Number)
				{
					var value = new ASTIdentifier(key.value, __find_ScopeType_from_string(key.value), currentSourceInfo(key.sourceInfo));
				}
				else {
					throw_gmlc_error($"Object: {Object1} Event: {Create} at line {line} : got {key.type} {key.value} expected id", key.line, key.lineString, currentSourceInfo(key.sourceInfo).column)
				}

				//correct constants to be the string they are expected to be
				if (key.type != __GMLC_TokenType_String)
				&& (key.value != key.name) {
					key.value = key.name;
				}

				//push the key and the value
				array_push(
					_args,
					new ASTLiteral(key.value, currentSourceInfo(key.sourceInfo)),
					value
				);

		        if (currentToken.name == ",") {
		            nextToken();  // Skip the comma
		        }

		    }
		    expectToken(__GMLC_TokenType_Punctuation, "}");

			// Properties are not all constants, use a runtime function to create the struct
			return new ASTCallExpression(new ASTLiteral(method(undefined, __NewGMLStruct), sourceInfo, "__NewGMLStruct"), _args, sourceInfo);
		};

		static parseFunctionCall = function(callee) {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			var arg = parseArgumentInput();

			// Dot accessor callees become CallMethodExpression so scope update is free and target is evaluated once
			if (callee.type == __GMLC_NodeType_AccessorExpression)
			&& (callee.accessorType == __GMLC_AccessorType_Dot) {
				return new ASTCallMethodExpression(callee.expr, callee.val1.value, arg, sourceInfo);
			}

			return new ASTCallExpression(callee, arg, sourceInfo);
		};
		static parseArgumentInput = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			var _arguments = [];
			expectToken(__GMLC_TokenType_Punctuation, "("); // Ensure ( and consume it

			//early out
			if (currentToken != undefined && currentToken.name != ")") {

				var _found_closing_bracket = false;
				var _argument_found = false;

				while (currentToken != undefined) {

					if (currentToken.name == ")") break;

					if (currentToken.name == ",") {
						//handle empty argument values as undefined `func(,,,,,arg5)`
						if (!_argument_found) {
							array_push(_arguments, new ASTLiteral(undefined, currentSourceInfo(currentToken.sourceInfo))); // Parse each argument as an expression
						}

						nextToken();  // Consume the comma to continue to the next argument
						_argument_found = false;
					}
					else {
						// Parse each argument as a conditional expression
						var _expr = parseConditionalExpression()
						array_push(_arguments, _expr);
						_argument_found = true;
					}

				}
			}

			if (currentToken == undefined) {
				throw_gmlc_error($"<Object>: <Object1> <Event>: <Create> at line {line} : Symbol , or ) expected, got <EndOfFile>", line, lineString, sourceInfo.column)
			}

			expectToken(__GMLC_TokenType_Punctuation, ")"); // Ensure ) and consume it

			return _arguments;
		}


		static parseDotAccessor = function(object) {
		    var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			nextToken(); // Consume .
			var _keyLine = currentToken.line;
			var _keyLineString = currentToken.lineString;

			var _keySourceInfo = currentSourceInfo(currentToken.sourceInfo);
			var _key = parseKey(); // validates type, returns string name, advances

			var _expr = new ASTAccessorExpression(
				object,
				new ASTLiteral(_key, _keySourceInfo),
				undefined,
				__GMLC_AccessorType_Dot,
				sourceInfo
			)

			return _expr
		};

		static parseBracketAccessor = function(object) {
			var line = currentToken.line;
			var lineString = currentToken.lineString;

			var sourceInfo = currentSourceInfo(currentToken.sourceInfo);

			nextToken(); // Consume [
			var accessorType = __GMLC_AccessorType_Array; // Default to array accessor

			switch (currentToken.value) {
				case "|":{
					accessorType = __GMLC_AccessorType_List;
					nextToken(); // Consume |
				break;}
				case "?":{
					accessorType = __GMLC_AccessorType_Map;
					nextToken(); // Consume ?
				break;}
				case "#":{
					accessorType = __GMLC_AccessorType_Grid;
					nextToken(); // Consume #
				break;}
				case "$":{
					accessorType = __GMLC_AccessorType_Struct;
					nextToken(); // Consume $
				break;}
				case "@":{
					accessorType = __GMLC_AccessorType_Array;
					nextToken(); // Consume @
				break;}
			}

			//parse the index/key
			var _val1 = parseExpression();
			var _val2 = undefined;
			if (currentToken.name == ",") {
				nextToken();
				//parse the second array index
				var _val2 = parseExpression();
			}

			expectToken(__GMLC_TokenType_Punctuation, "]"); // Consume ]

			return new ASTAccessorExpression(
				object,
				_val1,
				_val2,
				accessorType,
				sourceInfo
			)

		};

		#endregion

		#region Helper Functions

		// Validates the current token can be used as a property/member key, returns its string name, and advances.
		// Valid: Identifier, UniqueVariable, Function, and constant-style Number tokens (name starts with letter or _).
		// Rejects numeric literals (123, 0xff, #ff) even though they are Number tokens.
		static parseKey = function() {
			switch (currentToken.type) {
				case __GMLC_TokenType_Identifier:
				case __GMLC_TokenType_UniqueVariable:
				case __GMLC_TokenType_Keyword:
				case __GMLC_TokenType_Function:{
					var _name = currentToken.name;
					nextToken();
					return _name;
				break;}
				case __GMLC_TokenType_Number:{
					var _first = string_ord_at(currentToken.name, 1);
					if (__char_is_alphabetic(_first) || (_first == ord("_"))) {
						var _name = currentToken.name;
						nextToken();
						return _name;
					}
				break;}
			}

			throw_gmlc_error($"Expected identifier after .\n{currentToken.lineString}\n", currentToken.line, currentToken.lineString, currentSourceInfo(currentToken.sourceInfo).column);
		};

		static expectToken = function(expectedType, expectedValue) {
			if (currentToken == undefined) {
				throw_gmlc_error($"Unexpected end of input. Expected {expectedValue} but found EOF.");
			}
			if (currentToken.type != expectedType || currentToken.value != expectedValue) {
				//pprint("lastFiveTokens :: ",lastFiveTokens)
				throw_gmlc_error($"Syntax Error: Expected {expectedValue} but found {currentToken}\nLast five tokens:\n{lastFiveTokens}.", currentToken.line, currentToken.lineString, currentSourceInfo(currentToken.sourceInfo).column);
			}
			nextToken();
		};

		static optionalToken = function(optionalType, optionalValue) {
			if (currentToken == undefined) return false;

			if (currentToken.type == optionalType && currentToken.value == optionalValue) {
				nextToken();
				return true;
			}

			return false;
		};

		#endregion

		#endregion

	}

#endregion


#region Helper Functions
/// @ignore
function __determineScopeType(_node) {
	gml_pragma("forceinline");

	var _scope = _node.scope;
	if (_scope == undefined) {
		return __find_ScopeType_from_string(_node.value);
	}
	return _scope
}
/// @ignore
function __find_ScopeType_from_string(_string) {
	gml_pragma("forceinline");
	// Ordered in priority

	//ScopeType_MACRO;
	//ScopeType_GLOBAL;
	//ScopeType_ENUM;
	//ScopeType_UNIQUE;
	//ScopeType_LOCAL;
	//ScopeType_STATIC;
	//ScopeType_SELF;
	//ScopeType_CONST;

	if array_contains(currentScript.MacroVarNames, _string) return ScopeType_MACRO;
	if array_contains(currentScript.GlobalVarNames, _string) return ScopeType_GLOBAL;
	if struct_exists(currentScript.EnumVarNames, _string) return ScopeType_ENUM;


	// Asset Handling
	if (env.isFunction(_string)) {
		return ScopeType_CONST;
	}
	else if (env.isConstant(_string)) {
		return ScopeType_CONST;
	}

	if (currentFunction != undefined) {
		if array_contains(currentFunction.LocalVarNames,  _string) return ScopeType_LOCAL;
		if array_contains(currentFunction.StaticVarNames, _string) return ScopeType_STATIC;
	}
	else {
		if array_contains(currentScript.LocalVarNames, _string) return ScopeType_LOCAL;
	}

	return ScopeType_SELF;  // Default to instance if scope is unknown

}
/// @ignore
function array_insert_ext(array, index, arr_of_val, offset=0, length=max(array_length(arr_of_val)-offset, 0)) {
	static __args = [];
	if (length == 0) return;
	array_resize(__args, length);
	array_copy(__args, 0, arr_of_val, offset, length);
	array_insert(__args, 0, array, index);
	return script_execute_ext(array_insert, __args);
}
#endregion
