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
		currentScope = ScopeType.GLOBAL; //used to change `function(){}` into `method(self, function(){}` when applicable
		scriptAST = undefined;
		
		lastFiveTokens = array_create(5, undefined);
		
		static initialize = function(_program) {
			finished = false;
			
			scriptAST = new ASTScript();
			currentScript = scriptAST;
			
			program = _program;
			tokens = _program.tokens;
			
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
			currentFunction = undefined;
			
			operatorStack = []; // Stack for operators
			operandStack = []; // Stack for operands (AST nodes)
			
		};
		
		static cleanup = function() {
			// i mean idk, what do you wanna do?
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
				while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
				
				if (currentToken == undefined) return;
				
				var statement = parseStatement();
				
				//frequently people will accidently include multiple ; at the end of their line, just ignore this.
				while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
				
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
				
					if (_token.type == __GMLC_TokenType.Identifier) {
					
						var _scopeType = __find_ScopeType_from_string(_token.value);
					
						if (_scopeType == ScopeType.MACRO) {
							
							var _macroTokens = currentScript.MacroVar[$ _token.value];
							
							//replace the new token data with the existing information data.
							//additionally mark the information as macro body token
							
							//_token.name
							//_token.line
							//_token.lineString
							//_token.byteStart
							//_token.byteEnd
							//_token.column
							
							//"type":"__GMLC_TokenType.Punctuation",
							//"line":4.0,
							//"lineString":"\tfoo = 123;",
							//"name":";",
							//"value":";",
							//"byteStart":37.0,
							//"byteEnd":38.0,
							//"column":11.0
							
							array_delete(_tokens, _i, 1); //remove the macro from the token array
							array_insert_ext(_tokens, _i, _macroTokens); //insert the macro definition into the token array
							
							_hasChanged = true;
						}
					
						if (_scopeType == ScopeType.ENUM) {
							var _header = _token.value;
							
							if (_i < array_length(_tokens)-2)
							&& (_tokens[_i+1].type == __GMLC_TokenType.Punctuation)
							&& (_tokens[_i+1].value == ".")
							&& (_tokens[_i+2].type == __GMLC_TokenType.Identifier) {
								
								var _member = _tokens[_i+2].value;
								var _enumTokens = currentScript.EnumVar[$ _header][$ _member];
								
								array_delete(_tokens, _i, 3); //remove the enum from the token array
								array_insert_ext(_tokens, _i, _enumTokens); //insert the enum definition into the token array
								
								_hasChanged = true;
							}
						}
					
					}
				}
				_loop_count++
				if (_loop_count > 10_000) {
					throw_gmlc_error($"Recursive Macro or Enum Declaration detected! Quitting")
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
			
			if (currentToken.value == "{") {
				nextToken(); // Consume the {
				var _statements = [];
				while (currentToken != undefined && currentToken.value != "}") {
					//specifically Juju Adams will use `;` in macros to denote the next line, i really only ever expect a block statement to start with a `;` if its a Juju macro
					//frequently people will accidently include multiple ; at the end of their line, just ignore this.
					while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
					
					var _statement = parseStatement();
					
					if (_statement != undefined) {
						array_push(_statements, _statement);
					}
					
					//frequently people will accidently include multiple ; at the end of their line, just ignore this.
					while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
					
					// Parse each statement until } is found
					// Optional: Handle error checking for unexpected end of file
				}
				
				//frequently people will accidently include multiple ; at the end of their line, just ignore this.
				while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
				
				nextToken(); // Consume the }
				
				//compile better code
				if (array_length(_statements) == 0) {
					return new ASTEmpty();
				}
				
				if (array_length(_statements) == 1) {
					return _statements[0];
				}
				
				return new ASTBlockStatement(_statements, line, lineString); // Return a block statement containing all parsed statements
			}
			else {
				// If no {, its a single statement block
				var singleStatement = parseStatement();
				
				//frequently people will accidently include multiple ; at the end of their line, just ignore this.
				while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
				
				return new ASTBlockStatement([singleStatement], line, lineString);
			}
		};
		
		#region Statements
		#region Keyword Statement types
		
		static parseIfStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is if
			nextToken(); // Move past if
			var _condition = parseConditionalExpression();
			optionalToken(__GMLC_TokenType.Keyword, "then")
			var _codeBlock = parseBlock();
			var _elseBlock = undefined;
			
			
			
			if (currentToken != undefined)
			&& (currentToken.value == "else") {
				nextToken(); // Consume else
				_elseBlock = parseBlock();
			}
			return new ASTIfStatement(_condition, _codeBlock, _elseBlock, line, lineString);
		};
		
		static parseForStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Move past for
			expectToken(__GMLC_TokenType.Punctuation, "(");
			
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
			expectToken(__GMLC_TokenType.Punctuation, ";");
			
			//it's possible to make a for statement with no conditional statement
			if (currentToken.name != ";") {
				var _condition = parseConditionalExpression();
			}
			else {
				var _condition = undefined;
			}
			expectToken(__GMLC_TokenType.Punctuation, ";");
			
			if (currentToken.name != ")" && currentToken.name != ";") {
				var _increment = parseBlock();
			}
			else {
				var _increment = undefined;
			}
			
			//these are typically already handled by the parseBlock
			//frequently people will accidently include multiple ; at the end of their line, just ignore this.
			while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
			
			expectToken(__GMLC_TokenType.Punctuation, ")");
			
			var _codeBlock = parseBlock();
			return new ASTForStatement(_initialization, _condition, _increment, _codeBlock, line, lineString);
		};
		
		static parseWhileStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is while
			nextToken(); // Move past while
			var _condition = parseConditionalExpression();
			var _codeBlock = parseBlock();
			return new ASTWhileStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseRepeatStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is repeat
			nextToken(); // Move past repeat
			var _condition = parseExpression();
			var _codeBlock = parseBlock();
			return new ASTRepeatStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseDoUntilStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is do
			nextToken(); // Move past do
			var _codeBlock = parseBlock();
			expectToken(__GMLC_TokenType.Keyword, "until");
			var _condition = parseConditionalExpression();
			return new ASTDoUntilStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseSwitchStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
		    nextToken(); // Move past switch
		    var switchExpression = parseExpression(); // Parse the switch expression
		    
			expectToken(__GMLC_TokenType.Punctuation, "{"); // Ensure { and consume it
			
			var cases = [];
		    var statements = undefined;
		    
		    while (currentToken != undefined && currentToken.value != "}") {
				if (currentToken.type == __GMLC_TokenType.Keyword) {
					if (currentToken.value == "case") {
						var caseLine = currentToken.line;
						var caseLineString = currentToken.lineString;
						
						expectToken(__GMLC_TokenType.Keyword, "case"); //consume case
						var _label = parseExpression();
						
						expectToken(__GMLC_TokenType.Punctuation, ":"); // Ensure : and consume it
						
						statements = [];
						array_push(cases, new ASTCaseExpression(_label, statements, caseLine, caseLineString));
					}
					else if (currentToken.value == "default") {
						var caseLine = currentToken.line;
						var caseLineString = currentToken.lineString;
						
						nextToken(); //consume default
						
						expectToken(__GMLC_TokenType.Punctuation, ":"); // Ensure : and consume it
						
						statements = [];
						array_push(cases, new ASTCaseDefault(statements, line, lineString));
					}
					else {
						array_push(statements, parseStatement());
						
						//frequently people will accidently include multiple ; at the end of their line, just ignore this.
						while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
						
					}
				}
				else {
					array_push(statements, parseStatement());
					
					//frequently people will accidently include multiple ; at the end of their line, just ignore this.
					while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
					
				}
		    }

		    expectToken(__GMLC_TokenType.Punctuation, "}"); // Ensure } and consume it
			
			//frequently people will accidently include multiple ; at the end of their line, just ignore this.
			while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}

		    return new ASTSwitchStatement(switchExpression, cases, line, lineString);
		};
		
		static parseWithStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			// Assume currentToken is with
			nextToken(); // Move past with
			var _condition = parseExpression();
			var _codeBlock = parseBlock();
			return new ASTWithStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseTryCatchStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Keyword, "try");  // Expect the try keyword
			var _tryBlock = parseBlock();  // Parse the block of statements under try
			
			var _catchBlock = undefined;
			var _exceptionVar = undefined;
			if (currentToken != undefined)
			&& (currentToken.value == "catch") {
				nextToken();  // Move past catch
				expectToken(__GMLC_TokenType.Punctuation, "(");
				
				//parse and identify the exception variable as a local variable.
				_exceptionVar = currentToken.value;  // Parse the exception variable
				array_push((currentFunction ?? scriptAST).LocalVarNames, _exceptionVar);
				
				nextToken();  // Move past Identifier
				expectToken(__GMLC_TokenType.Punctuation, ")");
				_catchBlock = parseBlock();  // Parse the block of statements under catch
			}
			
			var _finallyBlock = undefined;
			if (currentToken != undefined)
			&& (currentToken.value == "finally") {
				nextToken();  // Move past finally
				_finallyBlock = parseBlock();  // Parse the block of statements under finally
			}
			
			return new ASTTryStatement(_tryBlock, _catchBlock, _exceptionVar, _finallyBlock, line, lineString);
		};
		
		static parseThrowExpression = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Keyword, "throw");  // Expect the try keyword
			var _err_message = parseExpressionStatement();  // Parse the block of statements under try
			
			return new ASTCallExpression(new ASTLiteral(throw_gmlc_error, line, lineString, "throw_gmlc_error"), [_err_message], line, lineString);
		};
		
		#endregion
		#region Keyword Executions
		static parseContinueStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume break
			return new ASTContinueStatement(line, lineString);
		};
		
		static parseBreakStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume break
			return new ASTBreakStatement(line, lineString);
		};
		
		static parseExitStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume exit
			return new ASTExitStatement(line, lineString);
		};
		
		static parseReturnStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume return
			var expr = undefined;
			if (currentToken.name == ";") {
				// dont attempt to parse if its expected to return undefined
			}
			else if (currentToken.type == __GMLC_TokenType.Keyword)
			&& (currentToken.value != "new") {
				// dont attempt to parse keywords if new block is starting
			}
			else if (currentToken.type == __GMLC_TokenType.Punctuation)
			&& (currentToken.value == "}") {
				// dont attempt to parse if end of block statement
			}
			else {
				expr = parseExpression(); // Parse the return expression if any
			}
			
			return new ASTReturnStatement(expr, line, lineString);
		};
		
		static parseDeleteStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume `default`
			var expr = parseLogicalOrExpression(); // cascades down the tree and across to ternary.
			
			return new ASTAssignmentExpression("=", expr, new ASTLiteral(undefined, line, lineString), line, lineString);
		};
		
		#endregion
		#region Declarations / Definitions
		
		static parseFunctionDeclaration = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			#region `function`
			expectToken(__GMLC_TokenType.Keyword, "function");
			#endregion
			
			#region function `identifier` :: the function's name if provided
			var functionName = undefined;
			if (currentToken.type == __GMLC_TokenType.Identifier) {
				var functionName = currentToken.value;
				//consume the function's identifier
				nextToken();
			}
			else if (currentToken.type == __GMLC_TokenType.Function) {
				throw_gmlc_error($"Duplicate function name of existing function :: {currentToken.name}\nline({line}) {lineString}")
			}
			else {
				static __anon_id = 0;
				var functionName = $"GMLC@anon@{__anon_id++}";
			}
			#endregion
			
			#region function`(arguments)` :: the argument list, or an emply block statement
			
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
			if (optionalToken(__GMLC_TokenType.Punctuation, ":")) {
				#region function foo() : `bar`() constructor {} :: parse constructor parent
				
				var _parent = parseCallAccessExpression();
				
				//if its an internally defined function, like a function defined in the same program we're parsing
				if (_parent.type != __GMLC_NodeType.CallExpression) {
					throw_gmlc_error($"line {line}:: {lineString}\nTrying to set a constructor parent to a non global defined value, got :: {_parent}")
				}
				
				//if it's a global identifier
				if (!is_callable(_parent.callee.value))
				&& (_parent.callee.type == __GMLC_NodeType.Identifier)
				&& (_parent.callee.scope == ScopeType.GLOBAL)
				{
					var _ref = program.GlobalVar[$ _parent.callee.value]
					if (_ref.type != __GMLC_NodeType.ConstructorDeclaration) {
						throw_gmlc_error($"line {line}:: {lineString}\nTrying to set a constructor parent to a non global defined value, got :: {_parent.callee.name}")
					}
				}
				
				
				#endregion
				
				_parentCall = _parent;
				_parentName = _parent.callee.name;
			}
			#endregion
			#region function foo() `constructor` :: parse constructor keyword (if provided)
			if (optionalToken(__GMLC_TokenType.Keyword, "constructor")) {
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
					line,
					lineString
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
					line,
					lineString
				)
			}
			
			
			//cache the old current function, incase we are declaring a function inside a function
			var _old_function = currentFunction;
			var _old_scope = currentScope;
			currentFunction = globalFunctionNode;
			
			//change the scope if needed
			if (_isConstructor) currentScope = ScopeType.SELF;
			
			// Parse the function body and apply it
			globalFunctionNode.statements = parseBlock();
			
			//reset the current function
			currentFunction = _old_function;
			currentScope = _old_scope;
			
			// Add to GlobalVar mapping of the Program node
			scriptAST.GlobalVar[$ functionName] = globalFunctionNode;
			array_push(scriptAST.GlobalVarNames, functionName);
			
			var _func_ref = new ASTIdentifier(functionName, ScopeType.GLOBAL, line, lineString);
			
			// now correctly set the assignment, either a global lookup, or a method call, depending on if it's inside a constructor or not
			switch (currentScope) {
				case ScopeType.GLOBAL: {
					var _func = _func_ref;
				break;}
				case ScopeType.STATIC: {
					var _func = new ASTCallExpression(
						new ASTLiteral(__gmlc_method, line, lineString, "__method"),
						[
							new ASTLiteral(undefined, line, lineString, "undefined"),
							_func_ref
						], 
						line,
						lineString
					)
				break;}
				case ScopeType.SELF  : {
					var _self = new ASTUniqueIdentifier(env.getVariable("self").value, line, lineString);
					var _func = new ASTCallExpression(
						new ASTLiteral(__gmlc_method, line, lineString, "__method"),
						[
							_self,
							_func_ref
						], 
						line,
						lineString
					)
				break;}
			}
			
			
			// Return a reference to the function in the global scope
			return _func;
		};
		static parseArgumentDefaultList = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Punctuation, "(");
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
			
			return new ASTArgumentList(parameters, line, lineString);
			
		}
		static parseArgumentDefaultSingle = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			var identifier = currentToken.value;  // Parse the parameter name
			nextToken();  // Move past Identifier
			
			var expr = undefined;
			if (optionalToken(__GMLC_TokenType.Operator, "=")) {
				expr = parseAssignmentExpression(); // Assignment is right-associative
			}
			else { 
				expr = new ASTLiteral(undefined, line, lineString);
			}
			
			return new ASTArgument(identifier, expr, undefined, line, lineString);
		}
		
		
		static parseVariableDeclaration = function () {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			var _should_hoist = false
			var type = currentToken.value;  // var, globalvar, or static
			var _variable_scope = undefined;
			
			// convert string to scope type
			switch (type) {
				//case "let":{
				//	//dont to nuttin`!
				//break;}
				case "var":{
					_variable_scope = ScopeType.LOCAL;
				break;}
				case "static":{
					_should_hoist = true;
					_variable_scope = ScopeType.STATIC;
				break;}
				case "globalvar":{
					_variable_scope = ScopeType.GLOBAL;
				break;}
				default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?")
			}
			
			
			// Fetch the array containing variable names
			var _tableArr = undefined
			if (currentFunction == undefined) {
				//script scrope
				switch (_variable_scope) {
					//case "let":{
					//	//dont to nuttin`!
					//break;}
					case ScopeType.LOCAL: _tableArr = scriptAST.LocalVarNames; break;
					case ScopeType.STATIC: throw_gmlc_error($"Script: <SCRIPT_NAME> at line {currentToken.line} : static can only be declared inside a function"); break;
					case ScopeType.GLOBAL: _tableArr = scriptAST.GlobalVarNames; break;
					default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?")
				}
					
			}
			else {
				//function scope
				switch (_variable_scope) {
					//case "let":{
					//	//dont to nuttin`!
					//break;}
					case ScopeType.LOCAL:  _tableArr = currentFunction.LocalVarNames; break;
					case ScopeType.STATIC: _tableArr = currentFunction.StaticVarNames; break;
					case ScopeType.GLOBAL: _tableArr = scriptAST.GlobalVarNames; break;
					default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?")
				}
			}
			
			
			// Cache the scoping and update if needed
			var _old_scope = currentScope;
			if (_variable_scope = ScopeType.STATIC) {
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
				
				if (currentToken.type != __GMLC_TokenType.Identifier) {
					if (_found_one) {
						break;
					}
					
		            throw_gmlc_error($"Expected identifier in variable declaration.\nRecieved: {currentToken}\nLast five tokens:\n{lastFiveTokens}");
		        }
				
				// we parse anything which starts with an identifier to ensure there is no postfix op attached to it like `++`, and accessor, or function call
		        var identifier = parsePostfixExpression();
				
				if (identifier.type != __GMLC_NodeType.Identifier) {
					if (_found_one) {
						break;
					}
					
					throw_gmlc_error($"Expected identifier in variable declaration.\nRecieved type: {identifier.type}, {currentToken}\nLast five tokens:\n{lastFiveTokens}");
				}
				
				//push to the table array
				if (!array_contains(_tableArr, identifier)) {
					array_push(_tableArr, identifier.name);
				}
				
				_found_one = true;
				
				//fetch expression
				var expr = undefined;
				if (optionalToken(__GMLC_TokenType.Operator, "=")) {
					expr = parseConditionalExpression();
					var _declaration = new ASTVariableDeclaration(identifier, expr, _variable_scope, varLine, varLineString);
					
					// either push it to the declarations array, or push it to the statics array
					switch (_variable_scope) {
						//case "let":{
						//	//dont to nuttin`!
						//break;}
						case ScopeType.LOCAL:
						case ScopeType.GLOBAL:{
							array_push(declarations, _declaration);
						break;}
						case ScopeType.STATIC:{
							array_push(currentFunction.StaticVarArray, _declaration)
						break;}
						default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?")
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
				return new ASTVariableDeclarationList(declarations, _variable_scope, line, lineString);
			}
		};
		
		#endregion
		#region Execution
		
		static parseNewExpression = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Keyword, "new");  // Expect the new keyword
			
			var expr = parseAccessExpression();
			expr = parseFunctionCall(expr);
			
			return new ASTNewExpression(expr, line, lineString);
			
			//var _args = expr.arguments;
			//array_insert(_args, 0, expr.callee)
			
			//return new ASTCallExpression(
			//	new ASTLiteral(
			//		constructor_call_ext,
			//		line,
			//		lineString,
			//		"new"
			//	),
			//	_args,
			//	line,
			//	lineString
			//);
		};
		
		#endregion
		
		static parseExpressionStatement = function() {
			var expr = parseExpression();
			if (expr == undefined) {
				throw_gmlc_error($"Getting an error parsing expression, current token is:\n{currentToken}\nLast Five Tokens:\n{lastFiveTokens}")
			}
			return expr;
		}
		
		#endregion
		
		#region Expressions
		static parseExpression = function() {
			return parseAssignmentExpression();
		};
		
		static parseConditionalExpression = function() {
			return parseConditionalEqualityExpression();
		};
		
		static parseAssignmentExpression = function() {
			var expr = parseLogicalOrExpression();
			static __arr = ["=", "+=", "-=", "*=", "/=", "^=", "&=", "|=", "%=", "??="];
			if (currentToken != undefined && currentToken.type == __GMLC_TokenType.Operator && array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseAssignmentExpression(); // Assignment is right-associative
				
				expr = new ASTAssignmentExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};
		
		static parseConditionalEqualityExpression = function() {
			var expr = parseLogicalOrExpression();
			static __arr = ["=", "==", "!="];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = (currentToken.value == "=") ? "==" : currentToken.value;
				
				nextToken();
				var right = parseLogicalOrExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};
		
		static parseLogicalOrExpression = function() {
			var expr = parseLogicalAndExpression();
			while (currentToken != undefined && currentToken.type == __GMLC_TokenType.Operator && currentToken.value == "||") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseLogicalAndExpression();
				expr = new ASTLogicalExpression(operator, expr, right, line, lineString);
			}
			return parseTerneryExpression(expr); // Check if this is a conditional expression after logical operations
		};

		static parseTerneryExpression = function(expr) {
			
			if (currentToken != undefined && currentToken.type == __GMLC_TokenType.Operator && currentToken.value == "?") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				expectToken(__GMLC_TokenType.Operator, "?"); // Consume ?
				var trueExpr = parseExpression(); // Parse the true branch
				expectToken(__GMLC_TokenType.Punctuation, ":"); // Consume :
				var falseExpr = parseExpression(); // Parse the false branch
				expr = new ASTConditionalExpression(expr, trueExpr, falseExpr, line, lineString);
			}
			return expr;
		};

		static parseLogicalAndExpression = function() {
			var expr = parseLogicalXorExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (currentToken.value == "&&") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseOrExpression();
				expr = new ASTLogicalExpression(operator, expr, right, line, lineString);
			}
			
			return expr;
		};

		static parseLogicalXorExpression = function() {
			var expr = parseNullishExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (currentToken.value == "^^") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseOrExpression();
				expr = new ASTLogicalExpression(operator, expr, right, line, lineString);
			}
			
			return expr;
		};
		
		static parseNullishExpression = function() {
			var expr = parseBitwiseOrExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (currentToken.value == "??") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseOrExpression();
				expr = new ASTNullishExpression(operator, expr, right, line, lineString);
			}
			
			return expr;
		};
		
		static parseBitwiseOrExpression = function() {
			var expr = parseBitwiseXorExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (currentToken.value == "|") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseXorExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			
			return expr;
		};

		static parseBitwiseXorExpression = function() {
			var expr = parseBitwiseAndExpression();
			while (currentToken != undefined) && (currentToken.value == "^") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseBitwiseAndExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			
			return expr;
		};

		static parseBitwiseAndExpression = function() {
			var expr = parseEqualityExpression();
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (currentToken.value == "&") {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseEqualityExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			
			return expr;
		};

		static parseEqualityExpression = function() {
			var expr = parseRelationalExpression();
			static __arr = ["==", "!="];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseRelationalExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};

		static parseRelationalExpression = function() {
			var expr = parseShiftExpression();
			
			static __arr = ["<", "<=", ">", ">="];
			while (currentToken != undefined)
			&& (currentToken.type == __GMLC_TokenType.Operator)
			&& (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseShiftExpression();
				var _prev_expr = expr
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};
		
		static parseShiftExpression = function() {
			var expr = parseAdditiveExpression();
			static __arr = ["<<", ">>"];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseAdditiveExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};

		static parseAdditiveExpression = function() {
			var expr = parseMultiplicativeExpression();
			static __arr = ["+", "-"];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseMultiplicativeExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};

		static parseMultiplicativeExpression = function() {
			var expr = parseUnaryExpression();
			static __arr = ["*", "/", "mod", "div"];
			while (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseUnaryExpression();
				expr = new ASTBinaryExpression(operator, expr, right, line, lineString);
			}
			return expr;
		};

		static parseUnaryExpression = function() {
			static __arr = ["!", "+", "-", "~", "++", "--"];
			if (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var expr = parseUnaryExpression(); // Right-associative
				
				if (operator == "++" || operator == "--") {
					return new ASTUpdateExpression(operator, expr, true, line, lineString);
				}
				
				return new ASTUnaryExpression(operator, expr, line, lineString);
			}
			else {
				return parsePostfixExpression();
			}
		};

		static parsePostfixExpression = function() {
			var expr = parseCallAccessExpression();
			static __arr = ["++", "--"];
			if (currentToken != undefined) && currentToken.type == __GMLC_TokenType.Operator && (array_contains(__arr, currentToken.value))
			&& !(expr.type == "Literal" && expr.scope == ScopeType.CONST) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				var postfixExpr = new ASTUpdateExpression(operator, expr, false, line, lineString);
				nextToken();
				expr = postfixExpr;
			}
			return expr;
		};
		
		static parseCallAccessExpression = function() {
			var expr = parseAccessExpression();
			
			while (currentToken != undefined) {
				if (currentToken.type == __GMLC_TokenType.Punctuation) {
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
				if (currentToken.type == __GMLC_TokenType.Punctuation) {
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
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			if (currentToken == undefined) {
				throw_gmlc_error("Unexpected end of input");
			}
			
			switch (currentToken.type) {
				case __GMLC_TokenType.Number:
				case __GMLC_TokenType.String:{
					
					// Handle literals
					var node = new ASTLiteral(currentToken.value, line, lineString);
					nextToken();
					return node;
					
				break;}
				case __GMLC_TokenType.Identifier:{
					
					var _scopeType = __find_ScopeType_from_string(currentToken.value);
					
					if (_scopeType == ScopeType.MACRO) {
						
						var _macroTokens = variable_clone(currentScript.MacroVar[$ currentToken.value]);
						
						array_delete(tokens, currentTokenIndex, 1); //remove the macro from the token array
						array_insert_ext(tokens, currentTokenIndex, _macroTokens); //insert the macro definition into the token array
						
						return node;
					}
					
					if (_scopeType == ScopeType.ENUM) {
						var _header = currentToken.value
						if (optionalToken(__GMLC_TokenType.Punctuation, ".")) {
							if (currentToken.type == __GMLC_TokenType.Identifier) {
								var _member = currentToken.value;
								var _enumTokens = variable_clone(currentScript.EnumVar[$ _header][$ _member]);
								
								array_delete(tokens, currentTokenIndex, 1); //remove the enum from the token array
								array_insert_ext(tokens, currentTokenIndex, _enumTokens); //insert the enum definition into the token array
								
								return node;
							}
						}
						
						//this will eventually get defaulted to instance if no dot accessor is eventually found
						var node = new ASTIdentifier(currentToken.value, undefined, line, lineString);
						nextToken(); // Move past the identifier
						return node;
					}
					
					if (_scopeType == ScopeType.CONST) {
						var _data = env.getConstant(currentToken.value) ?? env.getFunction(currentToken.value)
						var node = new ASTLiteral(_data.value, line, lineString);
						nextToken(); // Move past the identifier
						return node;
					}
					
					if (_scopeType == ScopeType.SELF) {
						var node = new ASTIdentifier(currentToken.value, undefined, line, lineString);
						nextToken(); // Move past the identifier
						return node;
					}
					
					var node = new ASTIdentifier(currentToken.value, _scopeType, line, lineString);
					
					nextToken(); // Move past the identifier
					return node;
					
				break;}
				case __GMLC_TokenType.Function:{
					var node = new ASTLiteral(currentToken.value, line, lineString, currentToken.name);
					nextToken(); // Move past the identifier
					return node;
					
				break;}
				case __GMLC_TokenType.Keyword:{
					switch (currentToken.value) {
						case "function": return parseFunctionDeclaration();
						case "new": return parseNewExpression()
						case "_GMFUNCTION_":{
							
						break;}
					}
				break;}
				case __GMLC_TokenType.Punctuation:{
					
					if (currentToken.name == "(") {
						// Handle expressions wrapped in parentheses
						nextToken(); // Consume (
						var expr = parseConditionalExpression();
						expectToken(__GMLC_TokenType.Punctuation, ")");
						return expr;
					}
					
					if (currentToken.value == "[") {
						return parseArrayCreation();
					}
					
					if (currentToken.value == "{") {
						return parseStructCreation();
					}
					
				break;}
				case __GMLC_TokenType.UniqueVariable:{
					
					// Handle literals
					var node = new ASTUniqueIdentifier(currentToken.value, line, lineString);
					nextToken();
					return node;
					
				break;}
				case __GMLC_TokenType.TemplateStringBegin:{
					
					var _template_string = currentToken.value;
					
					//consume the beginning
					nextToken();
					
					var _arguments = [];
					var _index = 0;
					while (currentToken != undefined && currentToken.type != __GMLC_TokenType.TemplateStringEnd) {
						if (currentToken.type == __GMLC_TokenType.TemplateStringMiddle) {
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
					array_insert(_arguments, 0, new ASTLiteral(_template_string, line, lineString));
					
					var _literalStringFunction = new ASTLiteral(string, line, lineString, "string");
					var _node = new ASTCallExpression(_literalStringFunction, _arguments, line, lineString);
					
					return _node
				break;}
				case __GMLC_TokenType.NoOpPragma: {
					nextToken();
					if (currentToken == undefined) return undefined;
					var _node = parseStatement();
					//frequently people will accidently include multiple ; at the end of their line, just ignore this.
					while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
					_node.skipOptimization = true;
					return _node;
					
				break;}
			}
			
			throw_gmlc_error($"Unexpected token in expression: {currentToken}\nLast five tokens were:\n{json(lastFiveTokens)}");
		};
		
		static parseArrayCreation = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			var elements = [];
		    
		    expectToken(__GMLC_TokenType.Punctuation, "[");
		    while (currentToken != undefined && currentToken.name != "]") {
		        var element = parseExpression();
				array_push(elements, element);
		        
				if (currentToken.name == ",") {
		            nextToken();  // Skip the comma
		        }
		    }
		    expectToken(__GMLC_TokenType.Punctuation, "]");
			
			return new ASTCallExpression(new ASTLiteral(__NewGMLArray, line, lineString, "__NewGMLArray"), elements, line, lineString);
		};
		
		static parseStructCreation = function() {
		    var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			var _args = [];
		    
		    expectToken(__GMLC_TokenType.Punctuation, "{");
		    while (currentToken != undefined && currentToken.value != "}") {
		        if (currentToken.type != __GMLC_TokenType.Identifier)
				&& (currentToken.type != __GMLC_TokenType.String)
				&& (currentToken.type != __GMLC_TokenType.UniqueVariable)
				&& (currentToken.type != __GMLC_TokenType.Number)
				{
		            throw_gmlc_error($"Expected identifier for struct property name.\n{currentToken}\nLast Five Tokens:\n{json_stringify(lastFiveTokens, true)}");
		        }
				
		        var key = currentToken;
		        nextToken();  // Move past the identifier
				
				if (optionalToken(__GMLC_TokenType.Punctuation, ":")) {
					var _prev_scope = currentScope;
					currentScope = ScopeType.SELF;
					
					var value = parseConditionalExpression();
					
					currentScope = _prev_scope;
				}
				else if (key.type == __GMLC_TokenType.String)
				     || (key.type == __GMLC_TokenType.Identifier)
				     || (key.type == __GMLC_TokenType.UniqueVariable)
				     || (key.type == __GMLC_TokenType.Number)
				{
					var value = new ASTIdentifier(key.value, __find_ScopeType_from_string(key.value), key.line, key.lineString);
				}
				else {
					throw_gmlc_error($"Object: {Object1} Event: {Create} at line {line} : got {key.type} {key.value} expected id")
				}
		        
				//correct constants to be the string they are expected to be
				if (key.type != __GMLC_TokenType.String)
				&& (key.value != key.name) {
					key.value = key.name;
				}
				
				//push the key and the value
				array_push(
					_args,
					new ASTLiteral(key.value, key.line, key.lineString),
					value
				);
				
		        if (currentToken.name == ",") {
		            nextToken();  // Skip the comma
		        }
				
		    }
		    expectToken(__GMLC_TokenType.Punctuation, "}");
			
			// Properties are not all constants, use a runtime function to create the struct
			return new ASTCallExpression(new ASTLiteral(__NewGMLStruct, line, lineString, "__NewGMLStruct"), _args, line, lineString);
		};
		
		static parseFunctionCall = function(callee) {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			var arg = parseArgumentInput();
			
			return new ASTCallExpression(callee, arg, line, lineString);
		};
		static parseArgumentInput = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			var _arguments = [];
			expectToken(__GMLC_TokenType.Punctuation, "("); // Ensure ( and consume it
			
			//early out
			if (currentToken != undefined && currentToken.name != ")") {
				
				var _found_closing_bracket = false;
				var _argument_found = false;
				
				while (currentToken != undefined) {
					
					if (currentToken.name == ")") break;
					
					if (currentToken.name == ",") {
						//handle empty argument values as undefined `func(,,,,,arg5)`
						if (!_argument_found) {
							array_push(_arguments, new ASTLiteral(undefined, currentToken.line, currentToken.lineString)); // Parse each argument as an expression
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
				throw_gmlc_error($"<Object>: <Object1> <Event>: <Create> at line {line} : Symbol , or ) expected, got <EndOfFile>")
			}
			
			expectToken(__GMLC_TokenType.Punctuation, ")"); // Ensure ) and consume it
			
			return _arguments;
		}
		
		
		static parseDotAccessor = function(object) {
		    var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume .
		    if (currentToken.type != __GMLC_TokenType.Identifier)
		    && (currentToken.type != __GMLC_TokenType.UniqueVariable) {
		        throw_gmlc_error($"Expected identifier after .\n{lineString}\n");
		    }
			
			var _expr = new ASTAccessorExpression(
				object,
				new ASTLiteral(currentToken.value, currentToken.line, currentToken.lineString),
				undefined,
				__GMLC_AccessorType.Dot,
				line,
				lineString
			)
			
			nextToken(); // Consume identifer key
			
			return _expr
		};
		
		static parseBracketAccessor = function(object) {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume [
			var accessorType = __GMLC_AccessorType.Array; // Default to array accessor
			
			switch (currentToken.value) {
				case "|":{
					accessorType = __GMLC_AccessorType.List;
					nextToken(); // Consume |
				break;}
				case "?":{
					accessorType = __GMLC_AccessorType.Map;
					nextToken(); // Consume ?
				break;}
				case "#":{
					accessorType = __GMLC_AccessorType.Grid;
					nextToken(); // Consume #
				break;}
				case "$":{
					accessorType = __GMLC_AccessorType.Struct;
					nextToken(); // Consume $
				break;}
				case "@":{
					accessorType = __GMLC_AccessorType.Array;
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
			
			expectToken(__GMLC_TokenType.Punctuation, "]"); // Consume ]
			
			return new ASTAccessorExpression(
				object,
				_val1,
				_val2,
				accessorType,
				line,
				lineString
			)
			
		};
		
		#endregion
		
		#region Helper Functions
		
		static expectToken = function(expectedType, expectedValue) {
			if (currentToken == undefined) {
				throw_gmlc_error($"Unexpected end of input. Expected {expectedValue} but found EOF.");
			}
			if (currentToken.type != expectedType || currentToken.value != expectedValue) {
				//pprint("lastFiveTokens :: ",lastFiveTokens)
				throw_gmlc_error($"Syntax Error: Expected {expectedValue} at line {currentToken.line}, column {currentToken.column}, but found {currentToken}\nLast five tokens:\n{lastFiveTokens}.");
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
	
	//ScopeType.MACRO;
	//ScopeType.GLOBAL;
	//ScopeType.ENUM;
	//ScopeType.UNIQUE;
	//ScopeType.LOCAL;
	//ScopeType.STATIC;
	//ScopeType.SELF;
	//ScopeType.CONST;
	
	if array_contains(currentScript.MacroVarNames, _string) return ScopeType.MACRO;
	if array_contains(currentScript.GlobalVarNames, _string) return ScopeType.GLOBAL;
	if struct_exists(currentScript.EnumVarNames, _string) return ScopeType.ENUM;
	
	
	// Asset Handling
	if (env.isFunction(_string)) {
		return ScopeType.CONST;
	}
	else if (env.isConstant(_string)) {
		return ScopeType.CONST;
	}
	
	if (currentFunction != undefined) {
		if array_contains(currentFunction.LocalVarNames,  _string) return ScopeType.LOCAL;
		if array_contains(currentFunction.StaticVarNames, _string) return ScopeType.STATIC;
	}
	else {
		if array_contains(currentScript.LocalVarNames, _string) return ScopeType.LOCAL;
	}
	
	return ScopeType.SELF;  // Default to instance if scope is unknown
	
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

