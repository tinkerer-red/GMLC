#region PostProcessor.gml
	#region PostProcessor Module
	/*
	Purpose: To refine the AST for better performance during interpretation.
	
	Methods:
	
	optimize(ast): Entry function that takes an AST and returns an optimized AST.
	constantFolding(ast): Traverses the AST and evaluates expressions that can be determined at compile-time.
	deadCodeElimination(ast): Removes parts of the AST that do not affect the program outcome, such as unreachable code.
	*/
	#endregion
	function GMLC_Gen_3_PostProcessor(_env) constructor {
		env = _env;
		
		//init variables:
		
		ast = undefined;
		currentScript = undefined;
		nodeStack = [];
		finished = false;
		
		static initialize = function(_ast) {
			ast = _ast;
			currentScript = ast;
			currentFunction = undefined;
			nodeStack = [];  // Stack to keep track of nodes to visit
			currentNode = undefined;
			
			// Push the script onto the stack, being the last one to get parsed
			array_push(nodeStack, {node: ast, parent: undefined, key: undefined, index: undefined}) // Start with the root node
			
			// Parse the Global Functions
			struct_foreach(_ast.GlobalVar, function(_name, _value){
				array_push(nodeStack, {node: _value, parent: currentScript.GlobalVar, key: _name, index: undefined})
			})
			
			finished = !array_length(nodeStack);
		};
		
		static cleanup = function() {
		
		}
		
		static parseAll = function() {
			while (!finished) {
				nextNode();
			}
			return ast;
		}
		
		static nextNode = function() {
			if (!array_length(nodeStack)) {
				finished = true;
				return;
			}
		
		    // Get current node from the stack
			var currentNode = array_pop(nodeStack);
			
			// Process children first (post-order traversal)
			if (currentNode.node.visited == false) {
				currentNode.node.visited = true;
				
				if (currentNode.node.type == __GMLC_NodeType_FunctionDeclaration)
				|| (currentNode.node.type == __GMLC_NodeType_ConstructorDeclaration) {
					currentFunction = currentNode.node
				}
				
				array_push(nodeStack, currentNode);
				
				// Push current node back onto stack to process after children
				currentNode.node.push_children_to_node_stack(nodeStack);
			}
			else {
				if (currentNode.node.type == __GMLC_NodeType_FunctionDeclaration) {
					currentFunction = undefined;
				}
				
				// Process the current node as all children have been processed
				var _node = Process(currentNode.node);
				_node.visited = false;
				
				if (currentNode.parent == undefined) {
					//the entire tree has been optimized and we are at the top most "Program" node
					if (array_length(nodeStack)) {
						throw_gmlc_error($"We still have nodes in the nodeStack, we shouldnt be finished")
					}
					
					finished = true;
					ast = _node;
				}
				else {
					//reset the visit so the next module can make use of it
					if (currentNode.index != undefined) {
						currentNode.parent[$ currentNode.key][currentNode.index] = _node;
					}
					else {
						currentNode.parent[$ currentNode.key] = _node;
					}
				}
				
			}
		};
		
		static Process = function(node) {
			
			//attempt to repopulate all scopes which pass through
			if (struct_exists(node, "scope")) {
				var _scopeType = __determineScopeType(node)
				node.scope = _scopeType;
			}
			
			switch (node.type) {
			    case __GMLC_NodeType_Script:{
					
				break;}
				case __GMLC_NodeType_FunctionDeclaration:{
					
				break;}
				case __GMLC_NodeType_ArgumentList:{
					
				break;}
				case __GMLC_NodeType_Argument:{
					
				break;}
				
				case __GMLC_NodeType_BlockStatement:{
					//iterate through children, and stack block statements together, this includes variable lists.
					var _new_arr = [];
					var _i=0; repeat(array_length(node.statements)) {
						var _child = node.statements[_i];
						switch (_child.type) {
							case __GMLC_NodeType_VariableDeclarationList: {
								
								var _declarations = _child.statements.statements
								var _j=0; repeat(array_length(_declarations)) {
									array_push(_new_arr, _declarations[_j]);
								_j++}
								
							break}
							case __GMLC_NodeType_BlockStatement: {
								
								var _statements = _child.statements
								var _j=0; repeat(array_length(_statements)) {
									array_push(_new_arr, _statements[_j]);
								_j++}
								
							break}
							default: {
								array_push(_new_arr, _child);
							break;}
						}
					_i++}
					node.statements = _new_arr;
				break;}
				case __GMLC_NodeType_IfStatement:{
					
				break;}
				case __GMLC_NodeType_ForStatement:{
				    
			    break;}
				case __GMLC_NodeType_WhileStatement:{
					
				break;}
				case __GMLC_NodeType_RepeatStatement:{
					
				break;}
				case __GMLC_NodeType_DoUntilStatement:{
					
				break;}
				case __GMLC_NodeType_WithStatement:{
					
				break;}
				case __GMLC_NodeType_TryStatement:{
					
				break;}
				case __GMLC_NodeType_SwitchStatement:{
					
				break;}
				case __GMLC_NodeType_CaseExpression:
				case __GMLC_NodeType_CaseDefault:{
					
				break;}
				
				case __GMLC_NodeType_BreakStatement:
				case __GMLC_NodeType_ContinueStatement:{
					
				break;}
				case __GMLC_NodeType_ExitStatement:{
					
				break;}
				case __GMLC_NodeType_ReturnStatement:{
					
				break;}
				
				case __GMLC_NodeType_VariableDeclarationList:{
					//decompress list into a single block statement, which will be extracted by the parent block statement
					
				break;}
				case __GMLC_NodeType_VariableDeclaration:{
					
				break;}
				
				case __GMLC_NodeType_CallExpression:{
					
				break;}
				case __GMLC_NodeType_NewExpression:{
					
				break;}
				
				case __GMLC_NodeType_ExpressionStatement:{
					
				break;}
				case __GMLC_NodeType_AssignmentExpression:{
					
					if (node.left.type == __GMLC_NodeType_AccessorExpression) {
						//handled in compiler
					}
					else if (node.left.type == __GMLC_NodeType_Identifier) {
						node.left.scope = __determineScopeType(node.left)
					}
				break;}
				case __GMLC_NodeType_BinaryExpression:{
					
				break;}
				case __GMLC_NodeType_LogicalExpression:{
					
				break;}
				case __GMLC_NodeType_NullishExpression:{
					
				break;}
				case __GMLC_NodeType_UnaryExpression:{
					switch (node.operator) {
						case "!":{
							
						break;}
						case "+":{
							//nothing is needed here
						break;}
						case "-":{
							
						break;}
						case "~":{
							
						break;}
						case "++":{
							
						break;}
						case "--":{
							
						break;}
					}
				break;}
				case __GMLC_NodeType_UpdateExpression:{
					if (node.expr.type == __GMLC_NodeType_AccessorExpression) {
						// this is handled in the compiler
					}
					else if (node.expr.type == __GMLC_NodeType_Identifier) {
						node.expr.scope = __determineScopeType(node.expr);
					}
					
					return node;
				break;}
				case __GMLC_NodeType_AccessorExpression:{
					
				break;}
				case __GMLC_NodeType_ConditionalExpression:{
					
				break;}
				
				case __GMLC_NodeType_Literal:{
				    
			    break;}
				case __GMLC_NodeType_Identifier:{
					var _scopeType = __determineScopeType(node)
					node.scope = _scopeType;
				break;}
				
				case __GMLC_NodeType_UniqueIdentifier:{
					
				break;}
				
				case __GMLC_NodeType_ConstructorDeclaration:{
					
				break;}
				case __GMLC_NodeType_EmptyNode:{
					//do nothing, this is just a place holder
				break;}
				/*
				case __GMLC_NodeType_PropertyAccessor:{
					throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
				break;}
				case __GMLC_NodeType_AccessorExpression:{
					throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
				break;}
				case __GMLC_NodeType_MethodVariableConstructor:{
					throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
				break;}
				case __GMLC_NodeType_MethodVariableFunction:{
					throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
				break;}
				//*/
				default: throw_gmlc_error($"Current Node does not have a valid type for the post processor,\ntype: {node.type}\ncurrentNode: {node}")
				
				// Add cases for other types of nodes
			}
			
			return node;
		};
		
		#region Processors
		
		#endregion
		
		#region Helper Functions
		static __argumentsAreLiteral = function(_arguments) {
			var _i=0; repeat(array_length(_arguments)) {
				if (_arguments[_i].type != __GMLC_NodeType_Literal) {
					return false;
				}
			_i+=1;}//end repeat loop
			return true;
		}
		
		static __build_literal_from_function_call_constant_folding = function(_script, node) {
			if (!__argumentsAreLiteral(node.arguments)) return node;
								
			//remap the arguments
			var _arr = node.arguments;
			var _new_arr = [];
			var _i=0; repeat(array_length(_arr)) {
				_new_arr[_i] = _arr[_i].value;
			_i+=1;}//end repeat loop
			
			return new ASTLiteral(script_execute_ext(_script, _new_arr), node.line, node.lineString);
		}
		
		#endregion
	}
#endregion
