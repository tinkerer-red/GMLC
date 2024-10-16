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
	function GML_Parser() constructor {
		finished = false;
		tokens = undefined;
		currentTokenIndex = 0;
		currentToken = undefined;
		currentFunction = undefined;
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
			replaceAllMacrosAndEnums(_program.tokens);
			
			currentTokenIndex = 0;
			currentToken = tokens[currentTokenIndex];
			currentFunction = undefined;
			
			operatorStack = []; // Stack for operators
			operandStack = []; // Stack for operands (AST nodes)
			
			replaceAllMacrosAndEnums();
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
				while (optionalToken(__GMLC_TokenType.Punctuation, ";")) {}
				
				var statement = parseStatement();
				if (statement) {
					array_push(scriptAST.statements.statements, statement);
				}
				
				if (GML_COMPILER_DEBUG) {
					static __lastString = ""
					var _str = string(currentTokenIndex/array_length(tokens)/10)
					if (__lastString != _str) {
						do_trace($"{real(_str)*1000}% Finished")
						__lastString = _str;
					}
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
				if (_loop_count > 1000) {
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
				case "#define":		parseDefineFunctionDeclaration() return undefined;
				//case "let":			//
				case "var":			//
				case "static":		//
				case "globalvar":	return parseVariableDeclaration();
				case "continue":	return parseContinueStatement();
				case "break":		return parseBreakStatement();
				case "exit":		return parseExitStatement();
				case "return":		return parseReturnStatement();
				case "#macro":		return parseReturnStatement();
				case "enum":		return parseReturnStatement();
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
					var _statement = parseStatement();
					
					if (_statement != undefined) {
						array_push(_statements, _statement);
					}
					
					//consume optional `;`
					optionalToken(__GMLC_TokenType.Punctuation, ";")
					
					// Parse each statement until } is found
					// Optional: Handle error checking for unexpected end of file
				}
				nextToken(); // Consume the }
				
				//compile better code
				if (array_length(_statements) == 1) {
					return _statements[0];
				}
				
				return new ASTBlockStatement(_statements, line, lineString); // Return a block statement containing all parsed statements
			}
			else {
				// If no {, its a single statement block
				var singleStatement = parseStatement();
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
			
			if (currentToken.value == "var") {
				var _initialization = parseVariableDeclaration();
			}
			else {
				var _initialization = parseExpression();
			}
			optionalToken(__GMLC_TokenType.Punctuation, ";"); //these are typically already handled by the parseExpression
			var _condition = parseConditionalExpression();
			optionalToken(__GMLC_TokenType.Punctuation, ";"); //these are typically already handled by the parseExpression
			var _increment = parseExpression();
			optionalToken(__GMLC_TokenType.Punctuation, ";"); //these are typically already handled by the parseExpression
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
			return new ASTDoUntillStatement(_condition, _codeBlock, line, lineString);
		};
		
		static parseSwitchStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
		    nextToken(); // Move past switch
		    var switchExpression = parseExpression(); // Parse the switch expression
		    
			expectToken(__GMLC_TokenType.Punctuation, "{"); // Ensure { and consume it
			
			var cases = [];
		    var statements = undefined;
		    var _expectClosingCurly = false;
			
		    while (currentToken != undefined && currentToken.value != "}") {
				if (currentToken.type == __GMLC_TokenType.Keyword) {
					if (currentToken.value == "case") {
						if (_expectClosingCurly) {
							throw_gmlc_error($"switch/case statement was opened with \{ but was never closed")
						}
						
						var caseLine = currentToken.line;
						var caseLineString = currentToken.lineString;
						
						expectToken(__GMLC_TokenType.Keyword, "case"); //consume case
						var _label = parseExpression();
						
						expectToken(__GMLC_TokenType.Punctuation, ":"); // Ensure : and consume it
						_expectClosingCurly = optionalToken(__GMLC_TokenType.Punctuation, "{")
						
						statements = [];
						array_push(cases, new ASTCaseExpression(_label, statements, caseLine, caseLineString));
					}
					else if (currentToken.value == "default") {
						if (_expectClosingCurly) {
							throw_gmlc_error($"switch/case statement was opened with \{ but was never closed")
						}
						
						var caseLine = currentToken.line;
						var caseLineString = currentToken.lineString;
						
						nextToken(); //consume default
						
						expectToken(__GMLC_TokenType.Punctuation, ":"); // Ensure : and consume it
						_expectClosingCurly = optionalToken(__GMLC_TokenType.Punctuation, "{")
						
						statements = [];
						array_push(cases, new ASTCaseDefault(statements, line, lineString));
					}
					else {
						array_push(statements, parseStatement());
						if (_expectClosingCurly && optionalToken(__GMLC_TokenType.Punctuation, "}")) {
							_expectClosingCurly = false;
						}
					}
				}
				else {
					array_push(statements, parseStatement());
					if (_expectClosingCurly && optionalToken(__GMLC_TokenType.Punctuation, "}")) {
						_expectClosingCurly = false;
					}
				}
		    }

		    expectToken(__GMLC_TokenType.Punctuation, "}"); // Ensure } and consume it

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
				array_push(scriptAST.LocalVarNames, _exceptionVar);
				
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
			
			return new ASTThrowExpression(_err_message, line, lineString);
		};
		
		#endregion
		#region Keyword Executions
		static parseContinueStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume break
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Optionally consume the semicolon
			return new ASTContinueStatement(line, lineString);
		};
		
		static parseBreakStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume break
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Optionally consume the semicolon
			return new ASTBreakStatement(line, lineString);
		};
		
		static parseExitStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume exit
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Optionally consume the semicolon
			return new ASTExitStatement(line, lineString);
		};
		
		static parseReturnStatement = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			nextToken(); // Consume return
			var expr = undefined;
			if (currentToken.value != ";") {
				expr = parseExpression(); // Parse the return expression if any
			}
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Optionally consume the semicolon
			
			return new ASTReturnStatement(expr, line, lineString);
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
				
				var _identifier = parsePrimaryExpression();
				var _parent = parseFunctionCall(_identifier);
				
				if (_parent.type != __GMLC_NodeType.CallExpression)
				|| (_identifier.type != __GMLC_NodeType.Identifier) {  ///////////////////////// This line might cause errors, maybe the preprocessor should evaluate function name declarations
					throw_gmlc_error($"line {line}:: {lineString}\nTrying to set a constructor parent to a non global defined value, got :: {_parent.name}")
				}
				
				#endregion
				
				_parentCall = _parent;
				_parentName = _parent.callee.value;
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
			currentFunction = globalFunctionNode;
			
			// Parse the function body
			globalFunctionNode.statements = parseBlock();
			
			//reset the current function
			currentFunction = _old_function;
			
			// Add to GlobalVar mapping of the Program node
			scriptAST.GlobalVar[$ functionName] = globalFunctionNode;
			array_push(scriptAST.GlobalVarNames, functionName);
			
			// Return a reference to the function in the global scope
			return new ASTIdentifier(functionName, ScopeType.GLOBAL, line, lineString);
		};
		static parseArgumentDefaultList = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Punctuation, "(");
			var parameters = [];
			while (currentToken.value != ")") {
			    var _argNode = parseArgumentDefaultSingle()
				_argNode.argument_index = array_length(parameters);
				
				array_push(parameters, _argNode);
				
				
			    if (currentToken.value == ",") {
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
		
		//used for gms1.4 #define funcName
		static parseDefineFunctionDeclaration = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Define, "#define");
			var functionName = $"GMLC@{currentToken.value}";  // Parse the function identifier
			nextToken();  // Move past Identifier
			
			var globalFunctionNode = new ASTFunctionDeclaration(functionName, [], [], undefined,  line, lineString);
			
			//cache the old current function, incase we are declaring a function inside a function
			var _old_function = currentFunction;
			currentFunction = globalFunctionNode;
			
			//build the body
			var _body = [];
			while (currentToken != undefined && currentToken.value != "#define") {
				var _statement = parseStatement();
				array_push(_body, _statement);
				// Parse each statement until } is found
				// Optional: Handle error checking for unexpected end of file
				if (GML_COMPILER_DEBUG) {
					static __lastString = ""
					var _str = string(currentTokenIndex/array_length(tokens))
					if (__lastString != _str) {
						do_trace($"{real(_str)*100}% Finished")
						__lastString = _str;
					}
				}
			}
			if (currentToken != undefined) nextToken(); // Consume the }
			globalFunctionNode.statements = new ASTBlockStatement(_body, line, lineString); // Return a block statement containing all parsed statements;
			
			//reset the current function
			currentFunction = _old_function;
			
			// Add to GlobalVar mapping of the Program node
			scriptAST.GlobalVar[$ functionName] = globalFunctionNode;
			array_push(scriptAST.GlobalVarNames, functionName);
			
			// Return a reference to the function in the global scope
			return new ASTIdentifier(functionName, ScopeType.GLOBAL, line, lineString);
		};
		
		static parseVariableDeclaration = function () {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			var _should_hoist = false
			var type = currentToken.value;  // var, globalvar, or static
			
			var _scope = undefined;
			switch (type) {
				//case "let":{
				//	//dont to nuttin`!
				//break;}
				case "var":{
					_scope = ScopeType.LOCAL;
				break;}
				case "static":{
					_should_hoist = true;
					_scope = ScopeType.STATIC;
				break;}
				case "globalvar":{
					_scope = ScopeType.GLOBAL;
				break;}
				default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?")
			}
			
			nextToken();
			
			var declarations = [];
			
		    while (true) {
				// optionally skip redeclarations
				var varLine = currentToken.line;
				var varLineString = currentToken.lineString;
				
				if (currentToken.type != __GMLC_TokenType.Identifier) {
		            throw_gmlc_error($"Expected identifier in variable declaration.\nRecieved: {currentToken}\nLast five tokens:\n{lastFiveTokens}");
		        }
				
		        var identifier = currentToken.value;
				nextToken();
				
				//mark the variable tables
				var _tableArr = undefined
				if (currentFunction == undefined) {
					//script scrope
					switch (_scope) {
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
					switch (_scope) {
						//case "let":{
						//	//dont to nuttin`!
						//break;}
						case ScopeType.LOCAL:  _tableArr = currentFunction.LocalVarNames; break;
						case ScopeType.STATIC: _tableArr = currentFunction.StaticVarNames; break;
						case ScopeType.GLOBAL: _tableArr = scriptAST.GlobalVarNames; break;
						default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?")
					}
				}
				if (!array_contains(_tableArr, identifier)) {
					array_push(_tableArr, identifier);
				}
				
				
				//fetch expression
				var expr = undefined;
				if (optionalToken(__GMLC_TokenType.Operator, "=")) {
					expr = parseConditionalExpression();
					
					// a unique check to apply static functions names
					if (_scope == ScopeType.STATIC) {
						//if this is a static function assignment, assign the static identifiers name to the functions name
						if (expr.type == __GMLC_NodeType.Identifier)
						&& (expr.scope == ScopeType.GLOBAL) {
							var _possibleFunc = scriptAST.GlobalVar[$ expr.value];
							if (_possibleFunc != undefined) {
								#region Change Function Name
								var _newFuncName = $"GMLC@{identifier}@{string_replace(_possibleFunc.functionName, "GMLC@", "")}"
									
								//change the global look up
								struct_remove(scriptAST.GlobalVar, _possibleFunc.functionName);
								scriptAST.GlobalVar[$ _newFuncName] = _possibleFunc;
								var _arr_index = array_get_index(scriptAST.GlobalVarNames, _possibleFunc.functionName);
								array_delete(scriptAST.GlobalVarNames, _arr_index, 1);
								array_push(scriptAST.GlobalVarNames, _newFuncName);
									
								//change the functions name
								_possibleFunc.functionName = _newFuncName;
									
								//change the identifier
								expr.identifier = _newFuncName;
								#endregion
								
								#region Assign as method
								if (_possibleFunc.type == __GMLC_NodeType.FunctionDeclaration)
								|| (_possibleFunc.type == __GMLC_NodeType.ConstructorDeclaration) {
									expr = new ASTCallExpression(
										new ASTFunction( __method, line, lineString ),
										[ new ASTLiteral(undefined, line, lineString), expr, ],
										line,
										lineString)
								}
								#endregion
							}
						}
						
					}
					
					switch (_scope) {
						//case "let":{
						//	//dont to nuttin`!
						//break;}
						case ScopeType.LOCAL:
						case ScopeType.GLOBAL:{
							array_push(declarations, new ASTVariableDeclaration(identifier, expr, _scope, varLine, varLineString));
						break;}
						case ScopeType.STATIC:{
							array_push(currentFunction.StaticVarArray, new ASTVariableDeclaration(identifier, expr, ScopeType.STATIC, varLine, varLineString))
						break;}
						default: throw_gmlc_error($"How did we enter variable declaration with out meeting a variable keyword?")
					}
					
				}
				
				if (optionalToken(__GMLC_TokenType.Punctuation, ";")) {
					break
				}
		        if (currentToken == undefined || currentToken.value != ",") {
		            break; // End of declaration list
		        }
				
		        nextToken(); // Consume , and move to the next identifier
		    }
			
			if (_should_hoist) {
				return undefined;
			}
			
			return new ASTVariableDeclarationList(declarations, _scope, line, lineString);
		};
		
		#endregion
		#region Execution
		
		static parseNewExpression = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			expectToken(__GMLC_TokenType.Keyword, "new");  // Expect the new keyword
			
			var _funcCall = parseExpressionStatement();
			
			return new ASTNewExpression( _funcCall, line, lineString);
		};
		
		#endregion
		
		static parseExpressionStatement = function() {
			var expr = parseExpression();
			if (expr == undefined) {
				throw_gmlc_error($"Getting an error parsing expression, current token is:\n{currentToken}\nLast Five Tokens:\n{lastFiveTokens}")
			}
			optionalToken(__GMLC_TokenType.Punctuation, ";"); // Handle the optional semicolon
			return expr;
		}
		
		#endregion
		
		#region Expressions
		static parseExpression = function() {
			return parseAssignmentExpression(); // Start from the highest precedence that is not unary or primary
		};
		
		static parseConditionalExpression = function() {
			return parseConditionalEqualityExpression(); // Start from the highest precedence that is not unary or primary
		};
		
		static parseAssignmentExpression = function() {
			var expr = parseLogicalOrExpression();
			static __arr = ["=", "+=", "-=", "*=", "/=", "^=", "&=", "|="];
			if (currentToken != undefined && currentToken.type == __GMLC_TokenType.Operator && array_contains(__arr, currentToken.value)) {
				var line = currentToken.line;
				var lineString = currentToken.lineString;
				
				var operator = currentToken.value;
				nextToken();
				var right = parseAssignmentExpression(); // Assignment is right-associative
				
				//check if it's a function or constructor
				if (right.type == __GMLC_NodeType.Identifier)
				&& (right.scope == ScopeType.GLOBAL) {
					var _possibleFunc = scriptAST.GlobalVar[$ right.value];
					if (_possibleFunc != undefined) {
						if (_possibleFunc.type == __GMLC_NodeType.FunctionDeclaration)
						|| (_possibleFunc.type == __GMLC_NodeType.ConstructorDeclaration) {
							right = new ASTCallExpression(
								new ASTFunction( __method, line, lineString ),
								[ new ASTUniqueIdentifier("self", line, lineString), right, ],
								line,
								lineString)
						}
					}
				}
				
				
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
		
		// Add the conditional parsing at the right level
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
			var expr = parseAccessExpression();
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
		
		static parseAccessExpression = function() {
			var expr = parsePrimaryExpression();
			
			var _should_break = false;
			while (currentToken != undefined) {
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
						var node = new ASTIdentifier(currentToken.value, ScopeType.CONST, line, lineString);
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
					var _func = getReplacementFunction(currentToken.value)
					var node = new ASTFunction(_func, line, lineString);
					nextToken(); // Move past the identifier
					return node;
					
				break;}
				case __GMLC_TokenType.Keyword:{
					switch (currentToken.value) {
						case "function": return parseFunctionDeclaration();
						case "new": return parseNewExpression()
					}
				break;}
				case __GMLC_TokenType.Punctuation:{
					
					if (currentToken.value == "(") {
						// Handle expressions wrapped in parentheses
						nextToken(); // Consume (
						var expr = parseExpression();
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
						var _expr = parseExpression()
						array_push(_arguments, _expr); // Parse each argument as an expression
						_template_string += "{"+string(_index)+"}"
						
						if (currentToken.type == __GMLC_TokenType.TemplateStringMiddle) {
							_template_string += currentToken.value;
							nextToken();  // Consume the middle segment
						}
					}
					
					//add the template strings end, then consume
					_template_string += currentToken.value;
					nextToken();  // Consume the middle segment
					
					//push the template string into the beginning of the arguments
					array_insert(_arguments, 0, new ASTLiteral(_template_string, line, lineString));
					
					var _literalStringFunction = new ASTFunction(string, line, lineString);
					var _node = new ASTCallExpression(_literalStringFunction, _arguments, line, lineString);
					
					return _node
				break;}
			}
			
			throw_gmlc_error($"Unexpected token in expression: {currentToken}\nLast five tokens were:\n{json(lastFiveTokens)}");
		};
		
		static parseArrayCreation = function() {
			var line = currentToken.line;
			var lineString = currentToken.lineString;
			
			var elements = [];
		    
		    expectToken(__GMLC_TokenType.Punctuation, "[");
		    while (currentToken != undefined && currentToken.value != "]") {
		        var element = parseExpression();
				array_push(elements, element);
		        
				if (currentToken.value == ",") {
		            nextToken();  // Skip the comma
		        }
		    }
		    expectToken(__GMLC_TokenType.Punctuation, "]");
			
			return new ASTArrayPattern(elements, line, lineString);
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
					var value = parseExpression();
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
		        
				//push the key and the value
				array_push(
					_args,
					new ASTLiteral(key.value, key.line, key.lineString),
					value
				);
				
		        if (currentToken.value == ",") {
		            nextToken();  // Skip the comma
		        }
				
		    }
		    expectToken(__GMLC_TokenType.Punctuation, "}");
			
			// Properties are not all constants, use a runtime function to create the struct
			return new ASTStructPattern(_args, line, lineString)
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
			if (currentToken != undefined && currentToken.value != ")") {
				while (currentToken != undefined && currentToken.value != ")") {
					var _expr = parseExpression()
					
					array_push(_arguments, _expr); // Parse each argument as an expression
					if (currentToken.value == ",") {
						nextToken();  // Consume the comma to continue to the next argument
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
		    if (currentToken.type != __GMLC_TokenType.Identifier) {
		        throw_gmlc_error("Expected identifier after .");
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
			if (currentToken.value == ",") {
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
				pprint("lastFiveTokens :: ",lastFiveTokens)
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
		
		static getReplacementFunction = function(_func) {
			switch (_func) {
				case method             : return __method            ;
				case is_instanceof      : return __is_instanceof     ;
				case static_get         : return __static_get        ;
				
				case static_set         : return __static_set        ;
				case typeof             : return __typeof            ;
				case method_get_index   : return __method_get_index  ;
				case method_get_self    : return __method_get_self   ;
				case method_call        : return __method_call       ;
				case script_execute     : return __script_execute    ;
				case script_execute_ext : return __script_execute_ext;
				
				default					: return _func;
			}
			
		}
		
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
	//NOTE: replace this with an asset look up table built into the build environment later, for API usage as a
	// modding tool to prevent users from messing with the source code too much
	var _index = asset_get_index(_string);
	var _type = asset_get_type(_string)
	if (_index != asset_script) && (_index > -1) {
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

