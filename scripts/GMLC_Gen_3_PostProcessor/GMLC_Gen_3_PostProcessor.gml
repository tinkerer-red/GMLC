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
				
				if (currentNode.node.type == __GMLC_NodeType.FunctionDeclaration)
				|| (currentNode.node.type == __GMLC_NodeType.ConstructorDeclaration) {
					currentFunction = currentNode.node
				}
				
				array_push(nodeStack, currentNode);
				
				// Push current node back onto stack to process after children
				currentNode.node.push_children_to_node_stack(nodeStack);
			}
			else {
				if (currentNode.node.type == __GMLC_NodeType.FunctionDeclaration) {
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
			    case __GMLC_NodeType.Script:{
					
				break;}
				case __GMLC_NodeType.FunctionDeclaration:{
					
				break;}
				case __GMLC_NodeType.ArgumentList:{
					
				break;}
				case __GMLC_NodeType.Argument:{
					
				break;}
				
				case __GMLC_NodeType.BlockStatement:{
					//iterate through children, and stack block statements together, this includes variable lists.
					var _new_arr = [];
					var _i=0; repeat(array_length(node.statements)) {
						var _child = node.statements[_i];
						switch (_child.type) {
							case __GMLC_NodeType.VariableDeclarationList: {
								
								var _declarations = _child.statements.statements
								var _j=0; repeat(array_length(_declarations)) {
									array_push(_new_arr, _declarations[_j]);
								_j++}
								
							break}
							case __GMLC_NodeType.BlockStatement: {
								
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
				case __GMLC_NodeType.IfStatement:{
					
				break;}
				case __GMLC_NodeType.ForStatement:{
				    
			    break;}
				case __GMLC_NodeType.WhileStatement:{
					
				break;}
				case __GMLC_NodeType.RepeatStatement:{
					
				break;}
				case __GMLC_NodeType.DoUntilStatement:{
					
				break;}
				case __GMLC_NodeType.WithStatement:{
					
				break;}
				case __GMLC_NodeType.TryStatement:{
					
				break;}
				case __GMLC_NodeType.SwitchStatement:{
					
				break;}
				case __GMLC_NodeType.CaseExpression:
				case __GMLC_NodeType.CaseDefault:{
					
				break;}
				
				case __GMLC_NodeType.BreakStatement:
				case __GMLC_NodeType.ContinueStatement:{
					
				break;}
				case __GMLC_NodeType.ExitStatement:{
					
				break;}
				case __GMLC_NodeType.ReturnStatement:{
					
				break;}
				
				case __GMLC_NodeType.VariableDeclarationList:{
					//decompress list into a single block statement, which will be extracted by the parent block statement
					
				break;}
				case __GMLC_NodeType.VariableDeclaration:{
					
				break;}
				
				case __GMLC_NodeType.CallExpression:{
					
				break;}
				case __GMLC_NodeType.NewExpression:{
					
				break;}
				
				case __GMLC_NodeType.ExpressionStatement:{
					
				break;}
				case __GMLC_NodeType.AssignmentExpression:{
					
					if (node.left.type == __GMLC_NodeType.AccessorExpression) {
						//handled in compiler
					}
					else if (node.left.type == __GMLC_NodeType.Identifier) {
						node.left.scope = __determineScopeType(node.left)
					}
				break;}
				case __GMLC_NodeType.BinaryExpression:{
					
				break;}
				case __GMLC_NodeType.LogicalExpression:{
					
				break;}
				case __GMLC_NodeType.NullishExpression:{
					
				break;}
				case __GMLC_NodeType.UnaryExpression:{
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
				case __GMLC_NodeType.UpdateExpression:{
					if (node.expr.type == __GMLC_NodeType.AccessorExpression) {
						// this is handled in the compiler
					}
					else if (node.expr.type == __GMLC_NodeType.Identifier) {
						node.expr.scope = __determineScopeType(node.expr);
					}
					
					return node;
				break;}
				case __GMLC_NodeType.AccessorExpression:{
					
				break;}
				case __GMLC_NodeType.ConditionalExpression:{
					
				break;}
				
				case __GMLC_NodeType.Literal:{
				    
			    break;}
				case __GMLC_NodeType.Identifier:{
					var _scopeType = __determineScopeType(node)
					node.scope = _scopeType;
				break;}
				
				case __GMLC_NodeType.UniqueIdentifier:{
					
				break;}
				
				case __GMLC_NodeType.ConstructorDeclaration:{
					
				break;}
				case __GMLC_NodeType.EmptyNode:{
					//do nothing, this is just a place holder
				break;}
				/*
				case __GMLC_NodeType.PropertyAccessor:{
					throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
				break;}
				case __GMLC_NodeType.AccessorExpression:{
					throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
				break;}
				case __GMLC_NodeType.MethodVariableConstructor:{
					throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
				break;}
				case __GMLC_NodeType.MethodVariableFunction:{
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
				if (_arguments[_i].type != __GMLC_NodeType.Literal) {
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
