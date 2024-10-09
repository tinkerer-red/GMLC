#region Optimizer.gml
	#region Optimizer Module
	/*
	Purpose: To refine the AST for better performance during interpretation.
	
	Methods:
	
	optimize(ast): Entry function that takes an AST and returns an optimized AST.
	constantFolding(ast): Traverses the AST and evaluates expressions that can be determined at compile-time.
	deadCodeElimination(ast): Removes parts of the AST that do not affect the program outcome, such as unreachable code.
	*/
	#endregion
	function GML_Optimizer() constructor {
		//init variables:
		
		ast = undefined;
		nodeStack = [];
		finished = false;
		
		static initialize = function(_ast) {
			ast = _ast;
			nodeStack = [];  // Stack to keep track of nodes to visit
			array_push(nodeStack, {node: ast, parent: undefined, key: undefined, index: undefined}) // Start with the root node
			finished = !array_length(nodeStack);
			currentNode = undefined;
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
				
				array_push(nodeStack, currentNode);
				
				// Push current node back onto stack to process after children
				currentNode.node.push_children_to_node_stack(nodeStack);
			}
			else {
				// Process the current node as all children have been processed
				var _node = optimize(currentNode.node);
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
		
		static optimize = function(_ast) {
			var _orig_ast = undefined;
			
			//keep optimizing until there are no optimizers which change the node.
			while (_ast != _orig_ast) {
				var _orig_ast = _ast
				_ast = constantFolding(_ast);
				//_ast = singleWriteOptimization(_ast);
				_ast = deadCodeElimination(_ast);
				//_ast = inlineFunctions(_ast);
				//_ast = optimizeLoops(_ast);
				_ast = optimizeAlternateFunctions(_ast);
				//_ast = variableHoisting(_ast);
			
				//_ast = tailCallOptimization(_ast);
				//_ast = commonSubexpressionElimination(_ast);
				//_ast = strengthReduction(_ast);
				//_ast = loopUnrolling(_ast);
				//_ast = branchPredictionHints(_ast);
				//_ast = lazyEvaluation(_ast);
				//_ast = memoryAccessOptimization(_ast);
			}
			
			return _ast;
		};
		
		#region Optimizers
		
		static constantFolding = function(node) {
			// Evaluate and simplify expressions with constant values
			
			// Recursive constant folding on child nodes first (if applicable)
			switch (node.type) {
				case "BinaryExpression":{
					if (node.left.type == "Literal" && node.right.type == "Literal") {
					    // Both nodes are literals, perform constant folding
					    switch (node.operator) {
							case "|":{
								return new ASTLiteral(node.left.value | node.right.value, node.line, node.lineString);
							break;}
							case "^":{
								return new ASTLiteral(node.left.value ^ node.right.value, node.line, node.lineString);
							break;}
							case "&":{
								return new ASTLiteral(node.left.value & node.right.value, node.line, node.lineString);
							break;}
							case "==":{
								return new ASTLiteral(node.left.value == node.right.value, node.line, node.lineString);
							break;}
							case "!=":{
								return new ASTLiteral(node.left.value != node.right.value, node.line, node.lineString);
							break;}
							case "<":{
								return new ASTLiteral(node.left.value < node.right.value, node.line, node.lineString);
							break;}
							case "<=":{
								return new ASTLiteral(node.left.value <= node.right.value, node.line, node.lineString);
							break;}
							case ">":{
								return new ASTLiteral(node.left.value > node.right.value, node.line, node.lineString);
							break;}
							case ">=":{
								return new ASTLiteral(node.left.value >= node.right.value, node.line, node.lineString);
							break;}
							case "<<":{
								return new ASTLiteral(node.left.value << node.right.value, node.line, node.lineString);
							break;}
							case ">>":{
								return new ASTLiteral(node.left.value >> node.right.value, node.line, node.lineString);
							break;}
							case "+":{
								return new ASTLiteral(node.left.value + node.right.value, node.line, node.lineString);
							break;}
							case "-":{
								return new ASTLiteral(node.left.value - node.right.value, node.line, node.lineString);
							break;}
							case "*":{
								return new ASTLiteral(node.left.value * node.right.value, node.line, node.lineString);
							break;}
							case "/":{
								return new ASTLiteral(node.left.value / node.right.value, node.line, node.lineString);
							break;}
							case "mod":{
								if (node.right.value == 0) {
									throw_gmlc_error($"DoMod :: Divide by zero")
								}
								return new ASTLiteral(node.left.value mod node.right.value, node.line, node.lineString);
							break;}
							case "div":{
								if (node.right.value == 0) {
									throw_gmlc_error($"DoRem :: Divide by zero")
								}
								return new ASTLiteral(node.left.value div node.right.value, node.line, node.lineString);
							break;}
						}
					}
				break;}
				case "LogicalExpression":{
					if (node.left.type == "Literal" && node.right.type == "Literal") {
					    switch (node.operator) {
							case "||":{
								return new ASTLiteral(node.left.value || node.right.value, node.line, node.lineString);
							break;}
							case "&&":{
								return new ASTLiteral(node.left.value && node.right.value, node.line, node.lineString);
							break;}
							case "^^":{
								return new ASTLiteral(node.left.value ^^ node.right.value, node.line, node.lineString);
							break;}
					    }
					}
					else if (node.left.type == "Literal" || node.right.type == "Literal") {
					    switch (node.operator) {
							case "||":{
								if (node.left.type  == "Literal" && node.left.value ) return new ASTLiteral(true, node.line, node.lineString);
								if (node.right.type == "Literal" && node.right.value) return new ASTLiteral(true, node.line, node.lineString);
							break;}
							case "&&":{
								if (node.left.type  == "Literal" && !node.left.value ) return new ASTLiteral(false, node.line, node.lineString);
								if (node.right.type == "Literal" && !node.right.value) return new ASTLiteral(false, node.line, node.lineString);
							break;}
					    }
					}
				break;}
				case "NullishExpression":{
					if (node.left.type == "Literal") {
						if (node.left.value == undefined) {
							return node.right;
						}
						else {
							return node.left;
						}
					}
				break;}
				case "UnaryExpression":{
					if (node.expr.type == "Literal") {
					    switch (node.operator) {
							case "!":{
								return new ASTLiteral(!node.expr.value, node.line, node.lineString);
							break;}
							case "+":{
								return new ASTLiteral(+node.expr.value, node.line, node.lineString);
							break;}
							case "-":{
								return new ASTLiteral(-node.expr.value, node.line, node.lineString);
							break;}
							case "~":{
								return new ASTLiteral(~node.expr.value, node.line, node.lineString);
							break;}
							case "++":{
								return new ASTLiteral(++node.expr.value, node.line, node.lineString);
							break;}
							case "--":{
								return new ASTLiteral(--node.expr.value, node.line, node.lineString);
							break;}
					    }
					}
				break;}
				case "ConditionalExpression":{
					if (node.condition.type == "Literal") {
					    // If the condition is a literal, determine which branch to take
						if (node.condition.value) {
							return node.trueExpr;
						}
						else {
							return node.falseExpr;
						}
					}
				break;}
				case "ExpressionStatement":{
					if (node.expr.type == "Literal") {
					    // If the condition is a literal, determine which branch to take
						return new ASTLiteral(node.expr.value, node.line, node.lineString);
					}
				break;}
				case "FunctionCall":{
					switch (node.callee.value) {
						case abs:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for abs is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(abs, node);
						break;}
						case angle_difference:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for angle_difference is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(angle_difference, node);
						break;}
						case ansi_char:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for ansi_char is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(ansi_char, node);
						break;}
						case arccos:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for arccos is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(arccos, node);
						break;}
						case arcsin:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for arcsin is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(arcsin, node);
						break;}
						case arctan:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for arctan is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(arctan, node);
						break;}
						case arctan2:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for arctan2 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(arctan2, node);
						break;}
						case buffer_sizeof:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for buffer_sizeof is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(buffer_sizeof, node);
						break;}
						case ceil:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for ceil is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(ceil, node);
						break;}
						case chr:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for chr is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(chr, node);
						break;}
						case clamp:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for clamp is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(clamp, node);
						break;}
						case color_get_blue:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for color_get_blue is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(color_get_blue, node);
						break;}
						case color_get_green:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for color_get_green is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(color_get_green, node);
						break;}
						case color_get_red:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for color_get_red is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(color_get_red, node);
						break;}
						case colour_get_blue:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for colour_get_blue is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(colour_get_blue, node);
						break;}
						case colour_get_green:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for colour_get_green is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(colour_get_green, node);
						break;}
						case colour_get_red:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for colour_get_red is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(colour_get_red, node);
						break;}
						case cos:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for cos is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(cos, node);
						break;}
						case darccos:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for darccos is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(darccos, node);
						break;}
						case darcsin:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for darcsin is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(darcsin, node);
						break;}
						case darctan:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for darctan is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(darctan, node);
						break;}
						case darctan2:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for darctan2 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(darctan2, node);
						break;}
						case dcos:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for dcos is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dcos, node);
						break;}
						case degtorad:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for degtorad is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(degtorad, node);
						break;}
						case dot_product:{
							if (array_length(node.arguments) != 4) {
								throw_gmlc_error($"Argument count for dot_product is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dot_product, node);
						break;}
						case dot_product_3d:{
							if (array_length(node.arguments) != 6) {
								throw_gmlc_error($"Argument count for dot_product_3d is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dot_product_3d, node);
						break;}
						case dot_product_3d_normalised:{
							if (array_length(node.arguments) != 6) {
								throw_gmlc_error($"Argument count for dot_product_3d_normalised is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dot_product_3d_normalised, node);
						break;}
						case dot_product_normalised:{
							if (array_length(node.arguments) != 4) {
								throw_gmlc_error($"Argument count for dot_product_normalised is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dot_product_normalised, node);
						break;}
						case dsin:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for dsin is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dsin, node);
						break;}
						case dtan:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for dtan is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(dtan, node);
						break;}
						case exp:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for exp is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(exp, node);
						break;}
						case floor:{
							if (array_length(node.arguments) != XXX) {
								throw_gmlc_error($"Argument count for floor is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(floor, node);
						break;}
						case frac:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for frac is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(frac, node);
						break;}
						case int64:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for int64 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(int64, node);
						break;}
						case is_array:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_array is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_array, node);
						break;}
						case is_bool:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_bool is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_bool, node);
						break;}
						case is_callable:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_callable is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_callable, node);
						break;}
						case is_handle:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_handle is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_handle, node);
						break;}
						case is_infinity:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_infinity is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_infinity, node);
						break;}
						case is_int32:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_int32 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_int32, node);
						break;}
						case is_method:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_method is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_method, node);
						break;}
						case is_nan:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_nan is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_nan, node);
						break;}
						case is_numeric:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_numeric is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_numeric, node);
						break;}
						case is_ptr:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_ptr is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_ptr, node);
						break;}
						case is_struct:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_struct is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_struct, node);
						break;}
						case is_undefined:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for is_undefined is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(is_undefined, node);
						break;}
						case lengthdir_x:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for lengthdir_x is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(lengthdir_x, node);
						break;}
						case lengthdir_y:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for lengthdir_y is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(lengthdir_y, node);
						break;}
						case lerp:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for lerp is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(lerp, node);
						break;}
						case ln:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for ln is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(ln, node);
						break;}
						case log10:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for log10 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(log10, node);
						break;}
						case log2:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for log2 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(log2, node);
						break;}
						case logn:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for logn is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(logn, node);
						break;}
						case make_color_rgb:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for make_color_rgb is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(make_color_rgb, node);
						break;}
						case make_colour_rgb:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for make_colour_rgb is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(make_colour_rgb, node);
						break;}
						case max:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for max is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(max, node);
						break;}
						case mean:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for mean is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(mean, node);
						break;}
						case median:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for median is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(median, node);
						break;}
						case min:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for min is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(min, node);
						break;}
						case object_exists:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for object_exists is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(object_exists, node);
						break;}
						case object_get_name:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for object_get_name is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(object_get_name, node);
						break;}
						case object_get_parent:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for object_get_parent is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(object_get_parent, node);
						break;}
						case object_get_physics:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for object_get_physics is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(object_get_physics, node);
						break;}
						case object_is_ancestor:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for object_is_ancestor is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(object_is_ancestor, node);
						break;}
						case ord:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for ord is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(ord, node);
						break;}
						case os_get_config:{
							return __build_literal_from_function_call_constant_folding(os_get_config, node);
						break;}
						case point_direction:{
							if (array_length(node.arguments) != 4) {
								throw_gmlc_error($"Argument count for point_direction is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(point_direction, node);
						break;}
						case point_distance:{
							if (array_length(node.arguments) != 4) {
								throw_gmlc_error($"Argument count for point_distance is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(point_distance, node);
						break;}
						case point_distance_3d:{
							if (array_length(node.arguments) != 6) {
								throw_gmlc_error($"Argument count for point_distance_3d is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(point_distance_3d, node);
						break;}
						case power:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for power is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(power, node);
						break;}
						case radtodeg:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for radtodeg is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(radtodeg, node);
						break;}
						case real:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for real is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(real, node);
						break;}
						case round:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for round is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(round, node);
						break;}
						case script_exists:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for script_exists is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(script_exists, node);
						break;}
						case script_get_name:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for script_get_name is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(script_get_name, node);
						break;}
						case sign:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for sign is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(sign, node);
						break;}
						case sin:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for sin is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(sin, node);
						break;}
						case sqr:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for sqr is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(sqr, node);
						break;}
						case sqrt:{
							/// ==================================================
							/// NOTE:
							/// This is the only math operation that is affected by `math_set_epsilon`
							/// avoid optimizing this at compile time
							/// ==================================================
							return node
						break;}
						case string_lower:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_lower is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_lower, node);
						break;}
						case string_upper:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_upper is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_upper, node);
						break;}
						case string_repeat:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_repeat is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_repeat, node);
						break;}
						case tan:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for tan is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(tan, node);
						break;}
						
						//organize these later....
						
						case code_is_compiled:{
							return __build_literal_from_function_call_constant_folding(code_is_compiled, node);
						break;}
						case string_byte_length:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_byte_length is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_byte_length, node);
						break;}
						case string_char_at:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_char_at is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_char_at, node);
						break;}
						case string_concat_ext:{
							if (array_length(node.arguments) >= 1)
							&& (array_length(node.arguments) <= 3) {
								throw_gmlc_error($"Argument count for string_concat_ext is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_concat_ext, node);
						break;}
						case string_copy:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_copy is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_copy, node);
						break;}
						case string_count:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_count is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_count, node);
						break;}
						case string_delete:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_delete is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_delete, node);
						break;}
						case string_digits:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_digits is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_digits, node);
						break;}
						case string_ends_with:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_ends_with is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_ends_with, node);
						break;}
						case string_ext:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_ext is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_ext, node);
						break;}
						case string_format:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_format is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_format, node);
						break;}
						case string_hash_to_newline:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_hash_to_newline is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_hash_to_newline, node);
						break;}
						case string_insert:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_insert is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_insert, node);
						break;}
						case string_join_ext:{
							if (array_length(node.arguments) >= 2)
							&& (array_length(node.arguments) <= 4) {
								throw_gmlc_error($"Argument count for string_join_ext is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_join_ext, node);
						break;}
						case string_last_pos:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_last_pos is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_last_pos, node);
						break;}
						case string_last_pos_ext:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_last_pos_ext is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_last_pos_ext, node);
						break;}
						case string_length:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_length is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_length, node);
						break;}
						case string_letters:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for string_letters is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_letters, node);
						break;}
						case string_ord_at:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_ord_at is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_ord_at, node);
						break;}
						case string_pos:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_pos is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_pos, node);
						break;}
						case string_pos_ext:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_pos_ext is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_pos_ext, node);
						break;}
						case string_replace:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_replace is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_replace, node);
						break;}
						case string_replace_all:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_replace_all is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_replace_all, node);
						break;}
						case string_set_byte_at:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for string_set_byte_at is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_set_byte_at, node);
						break;}
						case string_starts_with:{
							if (array_length(node.arguments) != 2) {
								throw_gmlc_error($"Argument count for string_starts_with is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_starts_with, node);
						break;}
						case string_trim:{
							if (array_length(node.arguments) >= 1)
							&& (array_length(node.arguments) <= 2) {
								throw_gmlc_error($"Argument count for string_trim is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_trim, node);
						break;}
						case string_trim_end:{
							if (array_length(node.arguments) >= 1)
							&& (array_length(node.arguments) <= 2) {
								throw_gmlc_error($"Argument count for string_trim_end is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_trim_end, node);
						break;}
						case string_trim_start:{
							if (array_length(node.arguments) >= 1)
							&& (array_length(node.arguments) <= 2) {
								throw_gmlc_error($"Argument count for string_trim_start is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(string_trim_start, node);
						break;}
						case md5_string_unicode:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for md5_string_unicode is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(md5_string_unicode, node);
						break;}
						case md5_string_utf8:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for md5_string_utf8 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(md5_string_utf8, node);
						break;}
						case color_get_hue:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for color_get_hue is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(color_get_hue, node);
						break;}
						case colour_get_hue:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for colour_get_hue is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(colour_get_hue, node);
						break;}
						case color_get_saturation:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for color_get_saturation is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(color_get_saturation, node);
						break;}
						case colour_get_saturation:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for colour_get_saturation is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(colour_get_saturation, node);
						break;}
						case color_get_value:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for color_get_value is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(color_get_value, node);
						break;}
						case colour_get_value:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for colour_get_value is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(colour_get_value, node);
						break;}
						case base64_encode:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for base64_encode is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(base64_encode, node);
						break;}
						case base64_decode:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for base64_decode is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(base64_decode, node);
						break;}
						case sha1_string_utf8:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for sha1_string_utf8 is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(sha1_string_utf8, node);
						break;}
						case sha1_string_unicode:{
							if (array_length(node.arguments) != 1) {
								throw_gmlc_error($"Argument count for sha1_string_unicode is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(sha1_string_unicode, node);
						break;}
						case make_color_hsv:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for make_color_hsv is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(make_color_hsv, node);
						break;}
						case make_colour_hsv:{
							if (array_length(node.arguments) != 3) {
								throw_gmlc_error($"Argument count for make_colour_hsv is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							return __build_literal_from_function_call_constant_folding(make_colour_hsv, node);
						break;}
						
						
						//all of the ones above use the same code
						case string:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for string is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							if (__argumentsAreLiteral(node.arguments)) {
								return __build_literal_from_function_call_constant_folding(string_lower, node);
							}
							else if (node.arguments[0].type == __GMLC_NodeType.Literal) {
								var _exec_arr = [_arr[0].value]; //the execution array
								var _new_arr = []; // the new arg array
								var _holder_index = 0;
								var _changed = false;
								
								var _i=1; repeat(array_length(_arr)-1) {
									if (_arr[_i].type == __GMLC_NodeType.Literal) {
										_changed = true;
										array_push(_exec_arr, _arr[_i].value);
									}
									else {
										array_push(_new_arr, _arr[_i].value);
										array_push(_exec_arr, $"\{{_holder_index}\}");
										_holder_index++
									}
								_i+=1;}//end repeat loop
								
								if (_changed) {
									array_insert(_new_arr, 0, script_execute_ext(string, _exec_arr))
									return new ASTCallExpression(node.callee, _new_arr);
								}
							}
						break;}
						case string_concat:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for string_concat is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							
							if (__argumentsAreLiteral(node.arguments)) {
								return __build_literal_from_function_call_constant_folding(string_concat, node);
							}
							else {
								var _arr = node.arguments;
								var _changed = false;
							
								var _i=0; repeat(array_length(_arr)-1) {
									if (_arr[_i].type == __GMLC_NodeType.Literal)
									&& (_arr[_i+1].type == __GMLC_NodeType.Literal) {
										_changed = true;
										var _struct = new ASTLiteral(string_concat(_arr[_i].value, _arr[_i+1].value), _arr[_i].line, _arr[_i].lineString)
										array_delete(_arr, _i, 2)
										array_insert(_arr, _i, _struct);
										continue;
									}
								_i+=1;}//end repeat loop
								
								if (_changed) {
									return new ASTNodes("FunctionCall", {callee: node.callee, arguments: _arr});
								}
							}
							
						break;}
						case string_join:{
							if (array_length(node.arguments) < 1) {
								throw_gmlc_error($"Argument count for string_join is incorrect!\nArgument Count : {array_length(node.arguments)}")
							}
							
							if (__argumentsAreLiteral(node.arguments)) {
								return __build_literal_from_function_call_constant_folding(string_join, node);
							}
							else if (node.arguments[0].type == __GMLC_NodeType.Literal) {
								var _arr = node.arguments;
								var _changed = false;
								
								var _i=1; repeat(array_length(_arr)-1) {
									if (_arr[_i].type == __GMLC_NodeType.Literal)
									&& (_arr[_i+1].type == __GMLC_NodeType.Literal) {
										_changed = true;
										var _struct = new ASTLiteral(string_join(_arr[0], _arr[_i].value, _arr[_i+1].value), _arr[_i].line, _arr[_i].lineString);
										array_delete(_arr, _i, 2)
										array_insert(_arr, _i, _struct);
										continue;
									}
								_i+=1;}//end repeat loop
								
								if (_changed) {
									return new ASTCallExpression(node.callee, _arr);
								}
							}
							
						break;}
						
					}
				break;}
				// Add more cases as needed for different node types
			}
			
			return node;
		};
		
		static singleWriteOptimization = function(node) {
			// Replace single-assignment variables with their values
			// this essentially acts as a constant value.
			
		};
		
		static deadCodeElimination = function(node) {
			// Remove unnecessary nodes
			switch (node.type) {
				case "IfStatement":{
					if (node.condition.type == "Literal") {
						if (node.condition.value) {
							return node.consequent;
						}
						else {
							if (node.alternate != undefined) {
								return node.alternate;
							}
							else {
								return new ASTNodes("BlockStatement", {statements: []})
							}
						}
					}
				break;}
				case "ForStatement":{
					if (node.condition.type == "Literal") {
						if (!node.condition.value) {
							return new ASTNodes("BlockStatement", {statements: []})
						}
					}
				break;}
				case "WhileStatement":{
					if (node.condition.type == "Literal") {
						if (!node.condition.value) {
							return new ASTNodes("BlockStatement", {statements: []})
						}
					}
				break;}
				case "RepeatStatement":{
					if (node.condition.type == "Literal") {
						if (!node.condition.value) {
							return new ASTNodes("BlockStatement", {statements: []})
						}
					}
				break;}
				case "DoUntillStatement":{
					if (node.condition.type == "Literal") {
						if (!node.condition.value) {
							return new ASTNodes("BlockStatement", {statements: []})
						}
					}
				break;}
				case "WithStatement":{
					if (node.condition.type == "Literal") {
						if (node.condition.value == noone) {
							return new ASTNodes("BlockStatement", {statements: []})
						}
					}
				break;}
				case "SwitchStatement":{
					if (node.switchExpression.type == "Literal") {
						var _val = node.switchExpression.value;
						var _found_case = false;
						var _found_break = false;
						var _return = node;
						
						var _i=0; repeat(array_length(node.cases)) {
							var _case = node.cases[_i]
							
							if (_case.type == "CaseExpression" && _case.label == _val)
							|| (_case.type == "CaseDefault") {
								_found_case = true;
								var _statements = []
								_return = new ASTNodes("BlockStatement", {statements: _statements});
								break;
							}
							
							if (_found_case) {
								var _arr = _case.codeBlock.statements;
								var _j=0; repeat(array_length(_arr)) {
									var _statement = _arr[_j]
									if (_statement.type == "BreakStatement") {
										_found_break = true;
										break;
									}
									
									array_push(_statements, _statement);
									
								_j+=1;}//end repeat loop
								
								if (_found_break) {
									break;
								}
								
							}
							
						_i+=1;}//end repeat loop
						
						return _return;
					}
				break;}
				case "ConditionalExpression":{
					if (node.condition.type == "Literal") {
					    // If the condition is a literal, determine which branch to take
						return (node.condition.value) ? node.trueExpr : node.falseExpr;
					}
				break;}
			}
			
			return node;
		};
		
		static inlineFunctions = function(node) {
			// Inline functions that are marked for inlining
		};
		
		static optimizeLoops = function(node) {
			// Convert certain for-loops to repeat-loops where applicable
		};
		
		static optimizeAlternateFunctions = function(node) {
			// Convert struct access using literals to hashed access
			//new ASTNode(Function, {value: currentToken.value, name: currentToken.name})
			if (node.type == "FunctionCall") {
				switch (node.callee.value) {
					case struct_get:
					case variable_struct_get:{
						// Convert struct access using literals to hashed access
						var _arg = node.arguments[1];
						if (_arg.type == "Literal") 
						&& (typeof(_arg.value) == "string") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: struct_get_from_hash, name: "struct_get_from_hash"}),
								arguments: [
									node.arguments[0],
									new ASTNodes("Literal", {value: variable_get_hash(_arg.value), scope: ScopeType.CONST})
								]
							});
						}
					break;}
						
					case struct_set:
					case variable_struct_set:{
						// Convert struct access using literals to hashed access
						var _arg = node.arguments[1];
						if (_arg.type == "Literal") 
						&& (typeof(_arg.value) == "string") {
							return new ASTNodes("FunctionCall", {
								callee: new ASTNodes("Function", {value: struct_set_from_hash, name: "struct_set_from_hash"}),
								arguments: [
									node.arguments[0],
									new ASTNodes("Literal", {value: variable_get_hash(_arg.value), scope: ScopeType.CONST}),
									node.arguments[2]
								]
							});
						}
					break;}
					
					case string:{
						// String with single argument is faster to use string_concat
						if (array_length(node.arguments) == 1) {
							var _arg = node.arguments[0]
							if (_arg.type != "Literal") {
								return new ASTNodes("FunctionCall", {
									callee: new ASTNodes("Function", {value: string_concat, name: "string_concat"}),
									arguments: node.arguments
								});
							}
						}
					break;}
				}
			}
			
			return node;
		};
		
		static variableHoisting = function(node) {
			// Hoist and variable declarations (specifically outside of loops when ever possible)
		};
		
		static commonSubexpressionElimination = function(node) {
			// Eliminate duplicate expressions by reusing the result stored in a temporary variable
		};
		
		static strengthReduction = function(node) {
			// Replace expensive operations with cheaper ones
		};
		
		static loopUnrolling = function(node) {
			// Explicitly expand loop iterations to decrease loop overhead
		};
		
		static branchPredictionHints = function(node) {
			// Provide hints to optimize CPU branch prediction
		};
		
		static lazyEvaluation = function(node) {
			// Delay the evaluation of expressions until their results are needed
		};
		
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
