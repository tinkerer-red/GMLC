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
		
		// an Identifier naming one of the compatibility functions
		static __builtin = function(_name, _span) {
			var _identifier = new ASTIdentifier(_span, _name);
			_identifier.symbol = new GMLC_Symbol("BuiltinFunction", _name);
			return _identifier;
		};
		
		static nextNode = function() {
			if (!array_length(nodeStack)) {
				finished = true;
				return;
			}
		
		    // Get current node from the stack
			currentNode = array_pop(nodeStack);
			
			// Process children first (post-order traversal)
			if (!(currentNode[$ "visited"] ?? false)) {
				currentNode.visited = true;
				
				// Push current node back onto stack to process after children
				array_push(nodeStack, currentNode);
				
				var _slots = currentNode.node.childSlots();
				array_reverse_ext(_slots);
				array_copy(nodeStack, array_length(nodeStack), _slots, 0, array_length(_slots));
			}
			else {
				// Process the current node as all children have been processed
				var _node = convert(currentNode.node);
				
				if (currentNode.parent == undefined) {
					//the entire tree has been optimized and we are at the top most "Program" node
					if (array_length(nodeStack)) {
						__gmlc_internal_error("the converter finished with nodes left on its stack")
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
			
			if (node.kind == __GMLC_NodeKind_Call) {
				if (node.callee.value == array_get) {
					var ind_node = arguments[0]
					if (ind_node.kind == __GMLC_NodeKind_Identifier) {
						
						switch (ind_node.name) {
							case "background_visible": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Visible), e__BG.Visible),
									]);
							break;}
							case "background_foreground": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Foreground), e__BG.Foreground),
									]);
							break;}
							case "background_index": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Index), e__BG.Index),
									]);
							break;}
							case "background_x": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.X), e__BG.X),
									]);
							break;}
							case "background_y": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Y), e__BG.Y),
									]);
							break;}
							case "background_width": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Width), e__BG.Width),
									]);
							break;}
							case "background_height": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Height), e__BG.Height),
									]);
							break;}
							case "background_htiled": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.HTiled), e__BG.HTiled),
									]);
							break;}
							case "background_vtiled": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.VTiled), e__BG.VTiled),
									]);
							break;}
							case "background_xscale": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.XScale), e__BG.XScale),
									]);
							break;}
							case "background_yscale": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.YScale), e__BG.YScale),
									]);
							break;}
							case "background_hspeed": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.HSpeed), e__BG.HSpeed),
									]);
							break;}
							case "background_vspeed": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.VSpeed), e__BG.VSpeed),
									]);
							break;}
							case "background_blend": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Blend), e__BG.Blend),
									]);
							break;}
							case "background_alpha": {
								return new ASTCall(ind_node.span, __builtin("__background_get", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Alpha), e__BG.Alpha),
									]);
							break;}
						}
						
					}
				}
				if (node.callee.value == array_set) {
					var ind_node = arguments[0]
					if (ind_node.kind == __GMLC_NodeKind_Identifier) {
						
						switch (ind_node.name) {
							case "background_visible": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Visible), e__BG.Visible),
										arguments[1]
									]);
							break;}
							case "background_foreground": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Foreground), e__BG.Foreground),
										arguments[1]
									]);
							break;}
							case "background_index": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Index), e__BG.Index),
										arguments[1]
									]);
							break;}
							case "background_x": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.X), e__BG.X),
										arguments[1]
									]);
							break;}
							case "background_y": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Y), e__BG.Y),
										arguments[1]
									]);
							break;}
							case "background_width": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Width), e__BG.Width),
										arguments[1]
									]);
							break;}
							case "background_height": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Height), e__BG.Height),
										arguments[1]
									]);
							break;}
							case "background_htiled": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.HTiled), e__BG.HTiled),
										arguments[1]
									]);
							break;}
							case "background_vtiled": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.VTiled), e__BG.VTiled),
										arguments[1]
									]);
							break;}
							case "background_xscale": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.XScale), e__BG.XScale),
										arguments[1]
									]);
							break;}
							case "background_yscale": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.YScale), e__BG.YScale),
										arguments[1]
									]);
							break;}
							case "background_hspeed": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.HSpeed), e__BG.HSpeed),
										arguments[1]
									]);
							break;}
							case "background_vspeed": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.VSpeed), e__BG.VSpeed),
										arguments[1]
									]);
							break;}
							case "background_blend": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Blend), e__BG.Blend),
										arguments[1]
									]);
							break;}
							case "background_alpha": {
								return new ASTCall(ind_node.span, __builtin("__background_set", ind_node.span), [
										new ASTLiteral(ind_node.span, "real", string(e__BG.Alpha), e__BG.Alpha),
										arguments[1]
									]);
							break;}
						}
						
					}
				}
			}
			
			if (node.kind == __GMLC_NodeKind_Assign) {
				if (node.target.kind == __GMLC_NodeKind_Identifier) {
					if (node.target.name == "background_color") || (node.target.name == "background_colour") {
						return new ASTCall(_node.span, __builtin("__background_set_colour", _node.span), [node.value]);
					}
				}
			}
			
			if (node.kind == __GMLC_NodeKind_Identifier) {
				switch (node.name) {
					case "background_color":
					case "background_colour":{
						return new ASTCall(_node.span, __builtin("__background_get_colour", _node.span), []);
					break;}
					
					case "background_showcolor":
					case "background_showcolour":{
						return new ASTCall(_node.span, __builtin("__background_get_showcolour", _node.span), []);
					break;}
					
				}
			}
			
			//background_visible
			return new ASTCall(_node.span, __builtin("background_visible", _node.span), []);
			//background_showcolor
			return new ASTCall(_node.span, __builtin("background_showcolor", _node.span), []);
							
			
			
			return node;
		}
		
		static convertViews = function(node) {
			
			if (node.kind == __GMLC_NodeKind_Assign) {
				if (node.target.kind == __GMLC_NodeKind_Identifier) {
					if (node.target.name == "background_color") || (node.target.name == "background_colour") {
						return new ASTCall(_node.span, __builtin("__background_set_colour", _node.span), [node.value]);
					}
				}
			}
			
			if (node.kind == __GMLC_NodeKind_Call) {
				if (node.callee.value == array_get) {
					var ind_node = arguments[0]
					if (ind_node.kind == __GMLC_NodeKind_Identifier) {
						if (ind_node.name == "background_visible") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Visible), e__BG.Visible),
									node.value
								]);
								
						}
						if (ind_node.name == "background_foreground") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Foreground), e__BG.Foreground),
									node.value
								]);
								
						}
						if (ind_node.name == "background_index") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Index), e__BG.Index),
									node.value
								]);
								
						}
						if (ind_node.name == "background_x") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.X), e__BG.X),
									node.value
								]);
								
						}
						if (ind_node.name == "background_y") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Y), e__BG.Y),
									node.value
								]);
								
						}
						if (ind_node.name == "background_width") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Width), e__BG.Width),
									node.value
								]);
								
						}
						if (ind_node.name == "background_height") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Height), e__BG.Height),
									node.value
								]);
								
						}
						if (ind_node.name == "background_htiled") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.HTiled), e__BG.HTiled),
									node.value
								]);
								
						}
						if (ind_node.name == "background_vtiled") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.VTiled), e__BG.VTiled),
									node.value
								]);
								
						}
						if (ind_node.name == "background_xscale") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.XScale), e__BG.XScale),
									node.value
								]);
								
						}
						if (ind_node.name == "background_yscale") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.YScale), e__BG.YScale),
									node.value
								]);
								
						}
						if (ind_node.name == "background_hspeed") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.HSpeed), e__BG.HSpeed),
									node.value
								]);
								
						}
						if (ind_node.name == "background_vspeed") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.VSpeed), e__BG.VSpeed),
									node.value
								]);
								
						}
						if (ind_node.name == "background_blend") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Blend), e__BG.Blend),
									node.value
								]);
								
						}
						if (ind_node.name == "background_alpha") {
							return new ASTCall(_node.span, __builtin("__background_get", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Alpha), e__BG.Alpha),
									node.value
								]);
							
						}
						
						
						
						
						
						
						
						
						
						
						
						
						if (ind_node.name == "view_visible") {
							
						}
						if (ind_node.name == "view_hport") {
							
						}
						if (ind_node.name == "view_hview") {
							
						}
						if (ind_node.name == "view_wport") {
							
						}
						if (ind_node.name == "view_wview") {
							
						}
						if (ind_node.name == "view_xport") {
							
						}
						if (ind_node.name == "view_xview") {
							
						}
						if (ind_node.name == "view_yport") {
							
						}
						if (ind_node.name == "view_yview") {
							
						}
					}
				}
				if (node.callee.value == array_set) {
					var ind_node = arguments[0]
					if (ind_node.kind == __GMLC_NodeKind_Identifier) {
						if (ind_node.name == "background_visible") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Visible), e__BG.Visible),
									node.value
								]);
								
						}
						if (ind_node.name == "background_foreground") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Foreground), e__BG.Foreground),
									node.value
								]);
								
						}
						if (ind_node.name == "background_index") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Index), e__BG.Index),
									node.value
								]);
								
						}
						if (ind_node.name == "background_x") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.X), e__BG.X),
									node.value
								]);
								
						}
						if (ind_node.name == "background_y") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Y), e__BG.Y),
									node.value
								]);
								
						}
						if (ind_node.name == "background_width") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Width), e__BG.Width),
									node.value
								]);
								
						}
						if (ind_node.name == "background_height") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Height), e__BG.Height),
									node.value
								]);
								
						}
						if (ind_node.name == "background_htiled") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.HTiled), e__BG.HTiled),
									node.value
								]);
								
						}
						if (ind_node.name == "background_vtiled") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.VTiled), e__BG.VTiled),
									node.value
								]);
								
						}
						if (ind_node.name == "background_xscale") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.XScale), e__BG.XScale),
									node.value
								]);
								
						}
						if (ind_node.name == "background_yscale") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.YScale), e__BG.YScale),
									node.value
								]);
								
						}
						if (ind_node.name == "background_hspeed") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.HSpeed), e__BG.HSpeed),
									node.value
								]);
								
						}
						if (ind_node.name == "background_vspeed") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.VSpeed), e__BG.VSpeed),
									node.value
								]);
								
						}
						if (ind_node.name == "background_blend") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Blend), e__BG.Blend),
									node.value
								]);
								
						}
						if (ind_node.name == "background_alpha") {
							return new ASTCall(_node.span, __builtin("__background_set", _node.span), [
									new ASTLiteral(_node.span, "real", string(e__BG.Alpha), e__BG.Alpha),
									node.value
								]);
							
						}
					}
				}
				
			}
			
			
			
			//background_visible
			return new ASTCall(_node.span, __builtin("background_visible", _node.span), []);
			//background_showcolor
			return new ASTCall(_node.span, __builtin("background_showcolor", _node.span), []);
							
			
			
			return node;
		}
		
		#endregion
		
		#region Helper Functions
		
		
		
		#endregion
	}
#endregion



