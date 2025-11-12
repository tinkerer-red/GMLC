/// @desc
/// @feather ignore all




/* allows for
// #define
// multiline strings with out @ accessor
// single quote strings example
// hashtags in strings represent newlines
// array 2d `arr[x, y]`
*/



#region GMLC_GM14_Converter.gml
	#region GMLC_GM14_Converter Module
	/*
	Purpose: There are a lot of deprocated function calls and assignments which need to be converted to modern gml standards. This module supports many of those conversions
	
	Methods:
	
	optimize(ast): Entry function that takes an AST and returns an optimized AST.
	constantFolding(ast): Traverses the AST and evaluates expressions that can be determined at compile-time.
	deadCodeElimination(ast): Removes parts of the AST that do not affect the program outcome, such as unreachable code.
	*/
	#endregion
	function GMLC_GM14_Converter() constructor {
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
			currentNode = array_pop(nodeStack);
			
			// Process children first (post-order traversal)
			if (currentNode.node.visited == false) {
				currentNode.node.visited = true;
				
				// Push current node back onto stack to process after children
				array_push(nodeStack, currentNode);
				
				currentNode.node.push_children_to_node_stack(nodeStack);
			}
			else {
				// Process the current node as all children have been processed
				var _node = convert(currentNode.node);
				_node.visited = false
				
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
		
		static convert = function(_ast) {
			var _orig_ast = undefined;
			
			//keep optimizing until there are no optimizers which change the node.
			while (_ast != _orig_ast) {
				var _orig_ast = _ast
				
			}
			
			return _ast;
		};
		
		static nodeStackPush = function(parent=undefined, key=undefined, index=undefined) {
			var node;
			if (index !=  undefined) {
				node = parent[$ key][index];
			}
			else {
				node = parent[$ key];
			}
			array_push(nodeStack, {node, parent, key, index})
		}
		
		#region converters
		
		static convertBackgrounds = function(node) {
			
			if (node.type == "FunctionCall") {
				if (node.callee.value == array_get) {
					var ind_node = arguments[0]
					if (ind_node.type == "Identifier") {
						
						switch (ind_node.value) {
							case "background_visible": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.Visible, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_foreground": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.Foreground, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_index": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.Index, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_x": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.X, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_y": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.Y, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_width": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.Width, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_height": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.Height, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_htiled": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.HTiled, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_vtiled": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.VTiled, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_xscale": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.XScale, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_yscale": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.YScale, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_hspeed": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.HSpeed, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_vspeed": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.VSpeed, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_blend": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.Blend, ind_node.line, ind_node.lineString),
									]
								);
							break;}
							case "background_alpha": {
								return new ASTCallExpression(
									new ASTLiteral(__background_get, ind_node.line, ind_node.lineString, "__background_get"),
									[
										new ASTLiteral(e__BG.Alpha, ind_node.line, ind_node.lineString),
									]
								);
							break;}
						}
						
					}
				}
				if (node.callee.value == array_set) {
					var ind_node = arguments[0]
					if (ind_node.type == "Identifier") {
						
						switch (ind_node.value) {
							case "background_visible": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.Visible, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_foreground": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.Foreground, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_index": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.Index, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_x": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.X, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_y": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.Y, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_width": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.Width, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_height": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.Height, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_htiled": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.HTiled, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_vtiled": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.VTiled, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_xscale": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.XScale, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_yscale": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.YScale, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_hspeed": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.HSpeed, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_vspeed": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.VSpeed, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_blend": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.Blend, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
							case "background_alpha": {
								return new ASTCallExpression(
									new ASTLiteral(__background_set, ind_node.line, ind_node.lineString, "__background_set"),
									[
										new ASTLiteral(e__BG.Alpha, ind_node.line, ind_node.lineString),
										arguments[1]
									]
								);
							break;}
						}
						
					}
				}
			}
			
			if (node.type == "AssignmentExpression") {
				if (node.left.type == "Identifier") {
					if (node.left.value == "background_color") || (node.left.value == "background_colour") {
						return new ASTCallExpression(
							new ASTLiteral(__background_set_colour, _node.line, _node.lineString, "__background_set_colour"),
							[node.right ]
						);
					}
				}
			}
			
			if (node.type == "Identifier") {
				switch (node.value) {
					case "background_color":
					case "background_colour":{
						return new ASTCallExpression(
								new ASTLiteral(__background_get_colour, _node.line, _node.lineString, "__background_get_colour"),
								[]
							);
					break;}
					
					case "background_showcolor":
					case "background_showcolour":{
						return new ASTCallExpression(
								new ASTLiteral(__background_get_showcolour, _node.line, _node.lineString, "__background_get_showcolour"),
								[]
							);
					break;}
					
				}
			}
			
			//background_visible
			return new ASTCallExpression(
								new ASTLiteral(background_visible, _node.line, _node.lineString, "background_visible"),
								[]
							);
			//background_showcolor
			return new ASTCallExpression(
								new ASTLiteral(background_showcolor, _node.line, _node.lineString, "background_showcolor"),
								[]
							);
							
			
			
			return node;
		}
		
		static convertViews = function(node) {
			
			if (node.type == "AssignmentExpression") {
				if (node.left.type == "Identifier") {
					if (node.left.value == "background_color") || (node.left.value == "background_colour") {
						return new ASTCallExpression(
							new ASTLiteral(__background_set_colour, _node.line, _node.lineString, "__background_set_colour"),
							[node.right ]
						);
					}
				}
			}
			
			if (node.type == "FunctionCall") {
				if (node.callee.value == array_get) {
					var ind_node = arguments[0]
					if (ind_node.type == "Identifier") {
						if (ind_node.value == "background_visible") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.Visible, _node.line, _node.lineString, "e__BG.Visible"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_foreground") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.Foreground, _node.line, _node.lineString, "e__BG.Foreground"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_index") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.Index, _node.line, _node.lineString, "e__BG.Index"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_x") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.X, _node.line, _node.lineString, "e__BG.X"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_y") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.Y, _node.line, _node.lineString, "e__BG.Y"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_width") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.Width, _node.line, _node.lineString, "e__BG.Width"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_height") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.Height, _node.line, _node.lineString, "e__BG.Height"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_htiled") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.HTiled, _node.line, _node.lineString, "e__BG.HTiled"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_vtiled") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.VTiled, _node.line, _node.lineString, "e__BG.VTiled"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_xscale") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.XScale, _node.line, _node.lineString, "e__BG.XScale"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_yscale") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.YScale, _node.line, _node.lineString, "e__BG.YScale"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_hspeed") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.HSpeed, _node.line, _node.lineString, "e__BG.HSpeed"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_vspeed") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.VSpeed, _node.line, _node.lineString, "e__BG.VSpeed"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_blend") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.Blend, _node.line, _node.lineString, "e__BG.Blend"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_alpha") {
							return new ASTCallExpression(
								new ASTLiteral(__background_get, _node.line, _node.lineString, "__background_get"),
								[
									new ASTLiteral(e__BG.Alpha, _node.line, _node.lineString, "e__BG.Alpha"),
									node.right
								]
							);
							
						}
						
						
						
						
						
						
						
						
						
						
						
						
						if (ind_node.value == "view_visible") {
							
						}
						if (ind_node.value == "view_hport") {
							
						}
						if (ind_node.value == "view_hview") {
							
						}
						if (ind_node.value == "view_wport") {
							
						}
						if (ind_node.value == "view_wview") {
							
						}
						if (ind_node.value == "view_xport") {
							
						}
						if (ind_node.value == "view_xview") {
							
						}
						if (ind_node.value == "view_yport") {
							
						}
						if (ind_node.value == "view_yview") {
							
						}
					}
				}
				if (node.callee.value == array_set) {
					var ind_node = arguments[0]
					if (ind_node.type == "Identifier") {
						if (ind_node.value == "background_visible") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.Visible, _node.line, _node.lineString, "e__BG.Visible"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_foreground") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.Foreground, _node.line, _node.lineString, "e__BG.Foreground"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_index") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.Index, _node.line, _node.lineString, "e__BG.Index"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_x") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.X, _node.line, _node.lineString, "e__BG.X"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_y") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.Y, _node.line, _node.lineString, "e__BG.Y"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_width") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.Width, _node.line, _node.lineString, "e__BG.Width"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_height") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.Height, _node.line, _node.lineString, "e__BG.Height"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_htiled") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.HTiled, _node.line, _node.lineString, "e__BG.HTiled"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_vtiled") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.VTiled, _node.line, _node.lineString, "e__BG.VTiled"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_xscale") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.XScale, _node.line, _node.lineString, "e__BG.XScale"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_yscale") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.YScale, _node.line, _node.lineString, "e__BG.YScale"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_hspeed") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.HSpeed, _node.line, _node.lineString, "e__BG.HSpeed"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_vspeed") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.VSpeed, _node.line, _node.lineString, "e__BG.VSpeed"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_blend") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.Blend, _node.line, _node.lineString, "e__BG.Blend"),
									node.right
								]
							);
							
						}
						if (ind_node.value == "background_alpha") {
							return new ASTCallExpression(
								new ASTLiteral(__background_set, _node.line, _node.lineString, "__background_set"),
								[
									new ASTLiteral(e__BG.Alpha, _node.line, _node.lineString, "e__BG.Alpha"),
									node.right
								]
							);
							
						}
					}
				}
				
			}
			
			
			
			//background_visible
			return new ASTCallExpression(
								new ASTLiteral(background_visible, _node.line, _node.lineString, "background_visible"),
								[]
							);
			//background_showcolor
			return new ASTCallExpression(
								new ASTLiteral(background_showcolor, _node.line, _node.lineString, "background_showcolor"),
								[]
							);
							
			
			
			return node;
		}
		
		#endregion
		
		#region Helper Functions
		
		
		
		#endregion
	}
#endregion




