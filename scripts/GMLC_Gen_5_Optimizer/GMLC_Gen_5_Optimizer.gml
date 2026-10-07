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
	function GMLC_Gen_5_Optimizer(_env) constructor  {
		env = _env;
		
		//init variables:
		
		ast = undefined;
		sources = undefined;
		noOpTargets = []; // the ranges `// @NoOp` covers (the next line, with the bodies on it), which are left as they are
		hasNoOpTargets = false; // whether noOpTargets has any entry
		optimization_occured = false; //used so all optimizers can register if a change has occured and we should re attempt optimizers
		foldSlot = undefined; // where the node constantFolding works on is held
		foldAll = false; // foldExpression: a value that exists only while compiling, where every fold is taken

		static initialize = function(_ast, _sources = undefined) {
			ast = _ast;
			sources = _sources;
			noOpTargets = [];
			var _i = 0; repeat (array_length(_ast.pragmas)) {
				var _target = _ast.pragmas[_i].target;
				if (_target != undefined) array_push(noOpTargets, _target);
			_i++}
			hasNoOpTargets = (array_length(noOpTargets) > 0);
		};
		
		static cleanup = function() {
		
		}
		
		static parseAll = function() {
			//keep optimizing the whole tree until no optimizer changes it
			do {
				optimization_occured = false;
				ast = __visit(ast, undefined);
			}
			until (!optimization_occured);
			return ast;
		}
		
		#region jsDoc
		/// @func    __visit(_node, _slot)
		/// @desc    Optimizes the children of a node, then the node itself (post-order). Returns the node to put in its place.
		/// @self    GMLC_Gen_5_Optimizer
		/// @param   {Struct.ASTNode} _node : The node
		/// @param   {Struct}         _slot : Where it is held ({parent, key, index}), undefined at the root
		/// @returns {Struct.ASTNode}
		#endregion
		static __visit = function(_node, _slot) {
			//skip nodes from optimization
			if (__isNoOp(_node)) return _node;
			
			var _slots = _node.childSlots();
			var _i = 0; repeat (array_length(_slots)) {
				var _child = _slots[_i];
				var _new = __visit(_child.node, _child);
				if (_new != _child.node) {
					if (_child.index != undefined) {
						_node[$ _child.key][_child.index] = _new;
					}
					else {
						_node[$ _child.key] = _new;
					}
				}
			_i++}
			
			return optimize({
				node: _node,
				parent: (_slot != undefined) ? _slot.parent : undefined,
				key: (_slot != undefined) ? _slot.key : undefined,
				index: (_slot != undefined) ? _slot.index : undefined,
			});
		};
		
		// whether a node is inside a range a `// @NoOp` covers
		static __isNoOp = function(_node) {
			if (!hasNoOpTargets) || (_node.span == undefined) return false;
			var _span = _node.span;
			var _i = 0; repeat (array_length(noOpTargets)) {
				var _target = noOpTargets[_i];
				if (_span.file == _target.file) && (_span.start >= _target.start) && (_span[$ "end"] <= _target[$ "end"]) return true;
			_i++}
			return false;
		};
		
		// whether a node is or holds the target of a `// @NoOp`
		static __containsNoOp = function(_node) {
			if (!hasNoOpTargets) return false;
			if (__isNoOp(_node)) return true;
			var _children = _node.children();
			var _i = 0; repeat (array_length(_children)) {
				if (__containsNoOp(_children[_i])) return true;
			_i++}
			return false;
		};
		
		static optimize = function(_node_data) {
			var _start_node = undefined;
			
			//keep optimizing until there are no optimizers which change the node.
			while (_node_data.node != _start_node) {
				var _start_node = _node_data.node;
				
				_node_data.node = constantFolding(_node_data);
				_node_data.node = constantPropagation(_node_data);
				_node_data.node = eliminateDeadCode(_node_data);
				_node_data.node = strengthReduction(_node_data);
				//_node_data.node = optimizeAlternateFunctions(_node_data);
				
				if (_start_node != _node_data.node) {
					optimization_occured = true
				}
			}
			
			return _node_data.node;
		};
		
		#region Optimizers
		
		#region JSDocs
		/// @function    constantPropagation(_node)
		/// @description Propagates constants throughout the code, replacing occurrences of a constant with its value.
		/// @param       {ASTNode}    _astNode    The AST node containing constants.
		/// @return      {ASTNode}    _astNode    The optimized AST node with constants propagated.
		#endregion
		static constantPropagation = function(_node_data) {
			var _node = _node_data.node;
			
			// propagation runs over a statement list, from a local set to a literal into the statements after it
			if (_node.kind != __GMLC_NodeKind_Block) && (_node.kind != __GMLC_NodeKind_Script) {
				return _node;
			}
			
			var _body = _node.body;
			var _i = 0; repeat (array_length(_body)) {
				var _statement = _body[_i];
				
				if (!__isNoOp(_statement)) {
					// var x = <literal>, ...
					if (_statement.kind == __GMLC_NodeKind_VarDeclList) {
						var _declarations = _statement.declarations;
						var _j = 0; repeat (array_length(_declarations)) {
							var _declaration = _declarations[_j];
							var _constant_data = __constantLocal(_declaration.target, _declaration.init);
							if (_constant_data != undefined) {
								show_debug_message($"Optimizer :: constantPropagation :: Has found Constant `{_declaration.target.name}` in line ({__line(_declaration)}) `{__lineString(_declaration)}`")
								if (!__propagateToList(_declarations, _j + 1, _constant_data)) {
									__propagateToList(_body, _i + 1, _constant_data);
								}
							}
						_j++}
					}
					// x = <literal>;
					else if (_statement.kind == __GMLC_NodeKind_ExprStmt)
					&& (_statement.expression.kind == __GMLC_NodeKind_Assign)
					&& (_statement.expression.op == "=")
					{
						var _assign = _statement.expression;
						var _constant_data = __constantLocal(_assign.target, _assign.value);
						if (_constant_data != undefined) {
							show_debug_message($"Optimizer :: constantPropagation :: Has found Constant `{_assign.target.name}` in line ({__line(_assign)}) `{__lineString(_assign)}`")
							__propagateToList(_body, _i + 1, _constant_data);
						}
					}
				}
			
			_i++}
			
			return _node;
		}
		
		// what propagation needs to know about a local set to a literal, undefined when it is not one
		static __constantLocal = function(_target, _value) {
			if (_value == undefined) || (_value.kind != __GMLC_NodeKind_Literal) return undefined;
			if (_target.kind != __GMLC_NodeKind_Identifier) || (_target.symbol == undefined) return undefined;
			if (_target.symbol.kind != "Local") || (_target.symbol.slot == undefined) return undefined;
			return {
				slot : _target.symbol.slot,
				literal : _value,
			};
		};
		
		// whether a node reads or writes the local of _constant_data
		static __isConstantLocal = function(_node, _constant_data) {
			return (_node.kind == __GMLC_NodeKind_Identifier)
				&& (_node.symbol != undefined)
				&& (_node.symbol.kind == "Local")
				&& (_node.symbol.slot == _constant_data.slot);
		};
		
		// the variable an assignment target writes: `a` of `a`, `a[0]`, `a.b`
		static __rootIdentifier = function(_node) {
			while (_node.kind == __GMLC_NodeKind_Index) {
				_node = _node.object;
			}
			return _node;
		};
		
		// propagates into the statements (or declarators) of an array from an index on; returns true when it stopped
		static __propagateToList = function(_array, _from, _constant_data) {
			var _i = _from; repeat (array_length(_array) - _from) {
				var _return = __propagateConstants(_array[_i], _constant_data);
				if (is_instanceof(_return, ASTNode)) {
					_array[_i] = _return;
				}
				else if (_return == true) {
					return true;
				}
			_i++}
			return false;
		};
		
		// returns the node to put in its place, true when propagation must stop, false to go on
		static __propagateConstants = function(_node, _constant_data) {
			// a node marked `// @NoOp` is left as it is
			if (__isNoOp(_node)) {
				return __writesLocal(_node, _constant_data);
			}
			
			switch (_node.kind) {
				case __GMLC_NodeKind_Identifier: {
					if (__isConstantLocal(_node, _constant_data)) {
						var _literal = _constant_data.literal;
						show_debug_message($"Optimizer :: constantPropagation :: Could replace `{_node.name}` with `{_literal.lexeme}` in line ({__line(_node)}) `{__lineString(_node)}`")
						optimization_occured = true;
						return new ASTLiteral(_node.span, _literal.ty, _literal.lexeme, _literal.value);
					}
					return false;
				break;}
				
				case __GMLC_NodeKind_Assign: {
					if (__isConstantLocal(__rootIdentifier(_node.target), _constant_data)) {
						// the value is read before the write
						// example :: xx = xx + 1;
						if (!__writesLocal(_node.value, _constant_data)) {
							var _return = __propagateConstants(_node.value, _constant_data);
							if (is_instanceof(_return, ASTNode)) {
								_node.value = _return;
							}
						}
						return true;
					}
				break;}
				
				case __GMLC_NodeKind_VarDecl: {
					// example :: var xx = xx + 1;
					if (_node.init != undefined) {
						if (__writesLocal(_node.init, _constant_data)) {
							return true;
						}
						var _return = __propagateConstants(_node.init, _constant_data);
						if (is_instanceof(_return, ASTNode)) {
							_node.init = _return;
						}
					}
					return __isConstantLocal(_node.target, _constant_data);
				break;}
				
				case __GMLC_NodeKind_ExprStmt: {
					var _return = __propagateConstants(_node.expression, _constant_data);
					if (is_instanceof(_return, ASTNode)) {
						_node.expression = _return;
						return false;
					}
					return _return;
				break;}
				
				// statements run in order, so propagation can go on up to the one that writes the local
				case __GMLC_NodeKind_Block: {
					return __propagateToChildren(_node, _constant_data);
				break;}
				
				// a nested function has its own locals
				case __GMLC_NodeKind_FunctionDecl:
				case __GMLC_NodeKind_ConstructorDecl:
				case __GMLC_NodeKind_FunctionExpr: {
					return false;
				break;}
				
				// when the local is written inside, only the part that runs first is safe
				case __GMLC_NodeKind_If:
				case __GMLC_NodeKind_Switch:
				case __GMLC_NodeKind_With:
				case __GMLC_NodeKind_Repeat:
				case __GMLC_NodeKind_For:
				case __GMLC_NodeKind_While:
				case __GMLC_NodeKind_DoUntil:
				case __GMLC_NodeKind_Try: {
					if (__writesLocal(_node, _constant_data)) {
						var _key = undefined;
						switch (_node.kind) {
							case __GMLC_NodeKind_If:     _key = "test";         break;
							case __GMLC_NodeKind_Switch: _key = "discriminant"; break;
							case __GMLC_NodeKind_With:   _key = "target";       break;
							case __GMLC_NodeKind_Repeat: _key = "count";        break;
							case __GMLC_NodeKind_For:    _key = "init";         break;
						}
						if (_key != undefined) && (_node[$ _key] != undefined) && (!__writesLocal(_node[$ _key], _constant_data)) {
							var _return = __propagateConstants(_node[$ _key], _constant_data);
							if (is_instanceof(_return, ASTNode)) {
								_node[$ _key] = _return;
							}
						}
						return true;
					}
				break;}
		    }
			
			// the order an expression reads and writes its parts in is not known: stop at any write
			if (__writesLocal(_node, _constant_data)) {
				return true;
			}
			
			return __propagateToChildren(_node, _constant_data)
		}
		static __propagateToChildren = function(_node, _constant_data) {
			var _children = _node.childSlots()
			var _i=0; repeat(array_length(_children)) {
				var _child_data = _children[_i]
				var _child_node = _child_data.node
				
				// a local used where a literal would fold differently from the run time value keeps its name
				if (_child_node.kind == __GMLC_NodeKind_Identifier)
				&& (!__canReplaceIn(_node, _child_data.key, _constant_data.literal.value))
				{
					_i++
					continue;
				}
				
				var _return = __propagateConstants(_child_node, _constant_data)
				
				if (is_instanceof(_return, ASTNode))
				{
					if (_child_data.index == undefined)
					{
						_node[$ _child_data.key] = _return;
					}
					else {
						_node[$ _child_data.key][_child_data.index] = _return;
					}
				}
				else if (_return == true) {
					//inform parent we are done propigating
					return true;
				}
			_i++}
			
			//it is still safe to continue propigating
			return false;
		}
		
		// whether a node may write the local of _constant_data
		static __writesLocal = function(_node, _constant_data) {
			switch (_node.kind) {
				case __GMLC_NodeKind_Assign: {
					if (__isConstantLocal(__rootIdentifier(_node.target), _constant_data)) return true;
				break;}
				case __GMLC_NodeKind_Update: {
					if (__isConstantLocal(__rootIdentifier(_node[$ "argument"]), _constant_data)) return true;
				break;}
				case __GMLC_NodeKind_Delete: {
					if (__isConstantLocal(__rootIdentifier(_node.target), _constant_data)) return true;
				break;}
				case __GMLC_NodeKind_VarDecl: {
					if (__isConstantLocal(_node.target, _constant_data)) return true;
				break;}
				case __GMLC_NodeKind_Try: {
					if (_node.catch_param != undefined) && (__isConstantLocal(_node.catch_param, _constant_data)) return true;
				break;}
				// a nested function has its own locals
				case __GMLC_NodeKind_FunctionDecl:
				case __GMLC_NodeKind_ConstructorDecl:
				case __GMLC_NodeKind_FunctionExpr: {
					return false;
				break;}
			}
			
			var _children = _node.children();
			var _i=0; repeat(array_length(_children)) {
				if (__writesLocal(_children[_i], _constant_data)) {
					return true;
				}
			_i++}
			
			return false;
		}
		
		#region jsDoc
		/// @func    foldExpression(_node, [_sources])
		/// @desc    An expression with every part known while compiling folded as constant folding folds it, for a value
		///          that exists only while compiling (an enum member's): every fold is taken, as no run-time operator
		///          will see the result. Returns the folded expression, a Literal when it all folded.
		/// @self    GMLC_Gen_5_Optimizer
		/// @param   {Struct.ASTNode}          _node      : The expression
		/// @param   {Struct.GMLC_SourceTable} [_sources] : The compile's files, for the positions of errors
		/// @returns {Struct.ASTNode}
		#endregion
		static foldExpression = function(_node, _sources = undefined) {
			var _sources0 = sources;
			var _noOp0 = hasNoOpTargets;
			sources = _sources;
			hasNoOpTargets = false;
			foldAll = true;
			var _holder = new ASTExprStmt(_node.span, _node);
			var _error = undefined;
			try {
				do {
					optimization_occured = false;
					__foldTree(_holder, undefined);
				}
				until (!optimization_occured);
			}
			catch (_e) {
				_error = _e;
			}
			foldAll = false;
			sources = _sources0;
			hasNoOpTargets = _noOp0;
			if (_error != undefined) throw _error;
			return _holder.expression;
		};
		static __foldTree = function(_node, _slot) {
			var _slots = _node.childSlots();
			var _i = 0; repeat (array_length(_slots)) {
				var _child = _slots[_i];
				var _new = __foldTree(_child.node, _child);
				if (_new != _child.node) {
					if (_child.index != undefined) {
						_node[$ _child.key][_child.index] = _new;
					}
					else {
						_node[$ _child.key] = _new;
					}
				}
			_i++}
			if (_slot == undefined) return _node;
			var _data = { node: _node, parent: _slot.parent, key: _slot.key, index: _slot.index };
			var _folded = constantFolding(_data);
			if (_folded != _node) optimization_occured = true;
			return _folded;
		};
		
		#region JSDocs
		/// @function    constantFolding(_node)
		/// @description Performs constant folding by evaluating constant expressions at compile-time (e.g., `2 + 2` becomes `4`).
		/// @param       {ASTNode}    _astNode    The AST node representing the expression.
		/// @return      {ASTNode}    _astNode    The AST node with folded constants.
		#endregion
		static constantFolding = function(_node_data) {
			var _node   = _node_data.node;
			var _parent = _node_data.parent;
			var _key    = _node_data.key;
			var _index  = _node_data.index;
		    
			
			foldSlot = _node_data;
			
			switch (_node.kind) {
				case __GMLC_NodeKind_Binary:
				case __GMLC_NodeKind_Logical:{
					// operands that are all constants fold as the compiler folds them
					var _folded = __foldOperator(_node);
					if (_folded != undefined) {
						return _folded;
					}
					
					// a constant left side of `&&` or `||` decides the result without running the right side
					if (_node.kind == __GMLC_NodeKind_Logical)
					&& ((_node.op == "&&") || (_node.op == "||"))
					{
						var _left = __constantValue(_node.left);
						if (_left[0]) && (is_numeric(_left[1])) {
							var _truthy = (_left[1]) ? true : false;
							if (_truthy == (_node.op == "||"))
							&& (!__containsNoOp(_node.right))
							&& (__keepsValue(_node_data, _truthy))
							{
								show_debug_message($"Optimizer :: constantFolding :: Could use literal of `{_truthy}` in line ({__line(_node)}) `{__lineString(_node)}`")
								return __literal(_truthy, _node.span);
							}
						}
					}
				break;}
				case __GMLC_NodeKind_Nullish:{
					var _left = __constantValue(_node.left);
					if (_left[0]) {
						if (_left[1] == undefined) {
							var _right = __constantValue(_node.right);
							if (!_right[0]) || (__keepsValue(_node_data, _right[1])) {
								show_debug_message($"Optimizer :: constantFolding :: Could collapse nullish express to right side only in line ({__line(_node)}) `{__lineString(_node)}`")
								return _node.right;
							}
						}
						else if (!__containsNoOp(_node.right)) && (__keepsValue(_node_data, _left[1])) {
							show_debug_message($"Optimizer :: constantFolding :: Could collapse nullish express to left side only in line ({__line(_node)}) `{__lineString(_node)}`")
							return _node.left;
						}
					}
				break;}
				case __GMLC_NodeKind_Unary:{
					if (_node.op == "+") {
						// the compiler compiles `+x` as `x`
						var _argument = __constantValue(_node[$ "argument"]);
						if (_argument[0]) && (__keepsValue(_node_data, _argument[1])) {
							show_debug_message($"Optimizer :: constantFolding :: Could remove unary `+` in line ({__line(_node)}) `{__lineString(_node)}`")
							return _node[$ "argument"];
						}
					}
					else {
						var _folded = __foldOperator(_node);
						if (_folded != undefined) {
							return _folded;
						}
					}
				break;}
				case __GMLC_NodeKind_Conditional:{
					return __foldConditional(_node_data);
				break;}
				case __GMLC_NodeKind_Call:{
					var _callee = __calleeFunction(_node);
					if (_callee != undefined) {
						switch (_callee) {
							case choose:{
								if (array_length(_node.args) == 1) {
									var _argument = __constantValue(_node.args[0]);
									if (!_argument[0]) || (__keepsValue(_node_data, _argument[1])) {
										return _node.args[0];
									}
								}
								
							break;}
							case sqrt:{
								/// ==================================================
								/// NOTE:
								/// This is the only math operation that is affected by `math_set_epsilon`
								/// avoid optimizing this at compile time
								/// ==================================================
								return _node
							break;}
							case string:{
								//Remove these if the request for change has been approved
								// This exists because of an oddity in the language
								/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8088
								if (array_length(_node.args) < 1) {
									/// Re add this if the oddity gets fixed
									//throw_gmlc_error($"Argument count for string is incorrect!\nArgument Count : {array_length(_node.args)}\nline ({__line(_node)}) {__lineString(_node)}")
									
									//this is also an odd variable as its different depending on the situation
									/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8090
									return __literal("", _node.span);
								}
								if (__argumentsAreLiteral(_node.args)) {
									return __build_literal_from_function_call_constant_folding(string, _node);
								}
								else if (_node.args[0].kind == __GMLC_NodeKind_Literal) {
									var _arr = _node.args;
									var _exec_arr = [_arr[0].value]; //the execution array
									var _new_arr = []; // the new arg array
									var _holder_index = 0;
									var _changed = false;
								
									var _i=1; repeat(array_length(_arr)-1) {
										var _sub_node = _arr[_i]
										if (_sub_node.kind == __GMLC_NodeKind_Literal) {
											_changed = true;
											array_push(_exec_arr, _sub_node.value);
										}
										else {
											array_push(_new_arr, _sub_node);
											array_push(_exec_arr, $"\{{_holder_index}\}");
											_holder_index++
										}
									_i+=1;}//end repeat loop
								
									if (_changed) {
										array_insert(_new_arr, 0, __literal(script_execute_ext(string, _exec_arr), _node.span))
										show_debug_message($"Optimizer :: constantFolding :: Could use optimize `string` first argument to `{_new_arr[0].value}` in line ({__line(_node)}) `{__lineString(_node)}`")
										return new ASTCall(_node.span, _node.callee, _new_arr);
									}
								}
							break;}
							case string_concat:{
								if (array_length(_node.args) < 1) {
									return _node; // a wrong argument count is the resolver's error
								}
							
								if (__argumentsAreLiteral(_node.args)) {
									return __build_literal_from_function_call_constant_folding(string_concat, _node);
								}
								else {
									var _arr = _node.args;
									var _changed = false;
							
									var _i=0; repeat(array_length(_arr)-1) {
										if (_arr[_i].kind == __GMLC_NodeKind_Literal)
										&& (_arr[_i+1].kind == __GMLC_NodeKind_Literal) {
											_changed = true;
											
											var _value = string_concat(_arr[_i].value, _arr[_i+1].value);
											show_debug_message($"Optimizer :: constantFolding :: Could use optimize a `string_concat` argument to `{_value}` in line ({__line(_node)}) `{__lineString(_node)}`")
											var _struct = __literal(_value, _arr[_i].span)
											
											array_delete(_arr, _i, 2)
											array_insert(_arr, _i, _struct);
											continue;
										}
									_i+=1;}//end repeat loop
								
									if (_changed) {
										return new ASTCall(_node.span, _node.callee, _arr);
									}
								}
							
							break;}
							case string_join:{
								if (array_length(_node.args) < 1) {
									return _node; // a wrong argument count is the resolver's error
								}
							
								if (__argumentsAreLiteral(_node.args)) {
									return __build_literal_from_function_call_constant_folding(string_join, _node);
								}
								else if (_node.args[0].kind == __GMLC_NodeKind_Literal) { // delimiter is literal
									var _arr = _node.args;
									var _changed = false;
									
									var _i=1; repeat(array_length(_arr)-2) {
										
										if (_arr[_i].kind == __GMLC_NodeKind_Literal)
										&& (_arr[_i+1].kind == __GMLC_NodeKind_Literal) {
											_changed = true;
											
											var _value = string_join(_arr[0].value, _arr[_i].value, _arr[_i+1].value);
											show_debug_message($"Optimizer :: constantFolding :: Could use optimize a `string_join` argument to `{_value}` in line ({__line(_node)}) `{__lineString(_node)}`")
											var _struct = __literal(_value, _arr[_i].span);
											
											array_delete(_arr, _i, 2)
											array_insert(_arr, _i, _struct);
											continue;
										}
										
									_i+=1;}//end repeat loop
								
									if (_changed) {
										return new ASTCall(_node.span, _node.callee, _arr);
									}
								}
							
							break;}
							case string_join_ext:{
								// GameMaker gives "" for fewer than two arguments
								/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8088
								if (array_length(_node.args) < 2) {
									return __literal("", _node.span)
								}
								if (array_length(_node.args) > 4) {
									return _node; // a wrong argument count is the resolver's error
								}
								return __build_literal_from_function_call_constant_folding(string_join_ext, _node);
							break;}
							default:{
								// the built-ins every compile-time fold shares (GMLC_Env.foldableFunctions)
								var _arity = env.foldableArity(_node.callee.name);
								if (_arity == undefined) break;
								var _count = array_length(_node.args);
								if (_count < _arity[0]) || ((_arity[1] >= 0) && (_count > _arity[1])) {
									return _node; // a wrong argument count is the resolver's error
								}
								return __build_literal_from_function_call_constant_folding(_callee, _node);
							break;}
						}
						//end switch
					}
				break;}
				// Add more cases as needed for different _node types
			}
			
			return _node;
			
		}
		
		#region JSDocs
		/// @function    eliminateDeadCode(_node)
		/// @description Removes code that is never executed, such as code following a `return` or `break` statement.
		/// @param       {ASTNode}    _astNode    The AST node representing the block of code.
		/// @return      {ASTNode}    _astNode    The AST node with unreachable code removed.
		#endregion
		static eliminateDeadCode = function(_node_data) {
			var _node   = _node_data.node;
			var _parent = _node_data.parent;
			var _key    = _node_data.key;
			var _index  = _node_data.index;
		    
			switch (_node.kind) {
				case __GMLC_NodeKind_If:{
					var _test = __constantValue(_node.test);
					if (_test[0]) && (is_numeric(_test[1])) {
						if (_test[1]) {
							if (_node.alternate == undefined) || (!__containsNoOp(_node.alternate)) {
								show_debug_message($"Optimizer :: eliminateDeadCode :: Could optimize `if` statement to `true` block only in line ({__line(_node)}) `{__lineString(_node)}`")
								return _node.consequent;
							}
						}
						else if (!__containsNoOp(_node.consequent)) {
							if (_node.alternate != undefined) {
								show_debug_message($"Optimizer :: eliminateDeadCode :: Could optimize `if` statement to `else` block only in line ({__line(_node)}) `{__lineString(_node)}`")
								return _node.alternate;
							}
							else {
								show_debug_message($"Optimizer :: eliminateDeadCode :: Could remove `if` statement in line ({__line(_node)}) `{__lineString(_node)}`")
								return new ASTEmpty(_node.span);
							}
						}
					}
				break;}
				case __GMLC_NodeKind_For:{
					if (_node.test != undefined) {
						var _test = __constantValue(_node.test);
						if (_test[0]) && (is_numeric(_test[1])) && (!_test[1])
						&& (!__containsNoOp(_node.body)) && ((_node.update == undefined) || (!__containsNoOp(_node.update)))
						{
							// the init still runs once
							show_debug_message($"Optimizer :: eliminateDeadCode :: Could optimize `for` by keeping only its init in line ({__line(_node)}) `{__lineString(_node)}`")
							return _node.init ?? new ASTEmpty(_node.span);
						}
					}
				break;}
				case __GMLC_NodeKind_While:{
					if (_node.test != undefined) {
						var _test = __constantValue(_node.test);
						if (_test[0]) && (is_numeric(_test[1])) && (!_test[1]) && (!__containsNoOp(_node.body)) {
							show_debug_message($"Optimizer :: eliminateDeadCode :: Could optimize `while` by removing it entirely in line ({__line(_node)}) `{__lineString(_node)}`")
							return new ASTEmpty(_node.span);
						}
					}
				break;}
				case __GMLC_NodeKind_Repeat:{
					if (_node.count != undefined) {
						var _count = __constantValue(_node.count);
						if (_count[0]) && (is_numeric(_count[1])) && (_count[1] <= 0) && (!__containsNoOp(_node.body)) {
							show_debug_message($"Optimizer :: eliminateDeadCode :: Could optimize `repeat` by removing it entirely in line ({__line(_node)}) `{__lineString(_node)}`")
							return new ASTEmpty(_node.span);
						}
					}
				break;}
				case __GMLC_NodeKind_DoUntil:{
					if (_node.test.kind == __GMLC_NodeKind_Literal) {
						
						/// There isnt really a way to optimizer this on the AST level, we can convert this into a breakable block statement on compile level, however if we want to re export as a string we dont want to mess with this on the AST optimization level.
						
						//if (_node.condition.value) {
						//	show_debug_message($"Optimizer :: eliminateDeadCode :: Could optimize `do` by removing it entirely in line ({__line(_node)}) `{__lineString(_node)}`")
						//	return new ASTEmpty(_node.span);
						//}
					}
				break;}
				case __GMLC_NodeKind_With:{
					var _target = __constantValue(_node.target);
					if (_target[0]) && (is_numeric(_target[1])) && (!__containsNoOp(_node.body)) {
						if (_target[1] == noone) {
							show_debug_message($"Optimizer :: eliminateDeadCode :: Could optimize `with` by removing it entirely in line ({__line(_node)}) `{__lineString(_node)}`")
							return new ASTEmpty(_node.span);
						}
					}
				break;}
				case __GMLC_NodeKind_Switch:{
					if (_node.discriminant.kind == __GMLC_NodeKind_Literal) {
						
						/// this was trash and doesnt account for inner statements breaking out, additionally it complicates break statements, and re exporting the code.
						
						//var _val = _node.switchExpression.value;
						//var _found_case = false;
						//var _found_break = false;
						//var _return = _node;
						
						//var _i=0; repeat(array_length(_node.cases)) {
						//	var _case = _node.cases[_i]
							
						//	if (_case.kind == "CaseExpression" && _case.label == _val)
						//	|| (_case.kind == "CaseDefault")
						//	{
						//		_found_case = true;
						//		_return = new ASTBlockStatement([], _node.sourceInfo);
						//		break;
						//	}
							
						//	if (_found_case) {
						//		var _arr = _case.codeBlock.statements;
						//		var _j=0; repeat(array_length(_arr)) {
						//			var _statement = _arr[_j]
						//			if (_statement.kind == "BreakStatement") {
						//				_found_break = true;
						//				break;
						//			}
									
						//			array_push(_statements, _statement);
									
						//		_j+=1;}//end repeat loop
								
						//		if (_found_break) {
						//			break;
						//		}
								
						//	}
							
						//_i+=1;}//end repeat loop
						
						//return _return;
					}
				break;}
				case __GMLC_NodeKind_Conditional:{
					return __foldConditional(_node_data);
				break;}
			}
			
			return _node;
		}
		
		#region JSDocs
		/// @function    strengthReduction(_astNode)
		/// @description Replaces existing functions with slightly optimized varients which prerform better for the specific task. IE: converting a value to a string is faster with `string_concat` then `string`, as `string` has several additional checks, and `string_concat` already converts a value to a string
		/// @param       {ASTNode}    _astNode    The AST node representing a small code block.
		/// @return      {ASTNode}    _astNode    The optimized AST node after peephole optimizations.
		#endregion
		static strengthReduction = function(_node_data) {
			var _node   = _node_data.node;
			var _parent = _node_data.parent;
			var _key    = _node_data.key;
			var _index  = _node_data.index;
			
			// Convert struct access using literals to hashed access
			//new ASTNode(Function, {value: currentToken.value, name: currentToken.name})
			if (_node.kind == __GMLC_NodeKind_Call) {
				switch (__calleeFunction(_node)) {
					case struct_get:
					case variable_struct_get:{
						// Convert struct access using literals to hashed access
						var _arg = _node.args[1];
						if (_arg.kind == __GMLC_NodeKind_Literal)
						&& (typeof(_arg.value) == "string")
						&& (env.isFunction("struct_get_from_hash")) {
							return new ASTCall(_node.span, __builtin("struct_get_from_hash", _node.span), [
								_node.args[0],
								__literal(variable_get_hash(_arg.value), _arg.span)
							]);
						}
					break;}
						
					case struct_set:
					case variable_struct_set:{
						// Convert struct access using literals to hashed access
						var _arg = _node.args[1];
						if (_arg.kind == __GMLC_NodeKind_Literal)
						&& (typeof(_arg.value) == "string")
						&& (env.isFunction("struct_set_from_hash")) {
							return new ASTCall(_node.span, __builtin("struct_set_from_hash", _node.span), [
								_node.args[0],
								__literal(variable_get_hash(_arg.value), _arg.span),
								_node.args[2]
							]);
						}
					break;}
					
					case string:{
						// String with single argument is faster to use string_concat
						if (array_length(_node.args) == 1) && (env.isFunction("string_concat")) {
							var _arg = _node.args[0]
							if (_arg.kind != __GMLC_NodeKind_Literal) {
								return new ASTCall(_node.span, __builtin("string_concat", _node.span), _node.args);
							}
						}
					break;}
				}
			}
			
			return _node;
		};
		
		
		
		
		#region JSDocs
		/// @function    removeRedundantTypeChecks(_node)
		/// @description This function removes redundant type checks from code. If we can determine with certainty that a variable will never be of a particular type, 
		///              we remove the unnecessary check (e.g., `is_string()` when it’s known the value cannot be a string).
		/// @param       {ASTNode}    _astNode    The AST node to check for type redundancies.
		/// @return      {ASTNode}    _astNode    The optimized AST node without unnecessary type checks.
		#endregion
		static removeRedundantTypeChecks = function(_node) {
		    // Pseudocode:
		    // 1. Traverse the AST tree to identify any type checks like is_string(), is_method(), etc.
		    // 2. Analyze the variable or expression to determine if the type check is needed.
		    // 3. Remove the check if it's redundant. 
		    //    Example: 
		    //      Before: if (is_string(value)) { ... }
		    //      After: Removed if it's known value is never a string.
		    // 4. Return the optimized AST node.
		}

		#region JSDocs
		/// @function    simplifyIncrementExpressions(_node)
		/// @description Simplifies expressions like `arr[0] = arr[0] + 1` to `arr[0]++` to save cycles and improve readability.
		/// @param       {ASTNode}    _astNode    The AST node containing an expression to simplify.
		/// @return      {ASTNode}    _astNode    The optimized AST node with simplified increment/decrement expressions.
		#endregion
		static simplifyIncrementExpressions = function(_node) {
		    // Pseudocode:
		    // 1. Look for patterns where a value is being assigned to itself with an increment/decrement operation.
		    // 2. Replace the expression with the more concise increment (++) or decrement (--) operator.
		    //    Example:
		    //      Before: arr[0] = arr[0] + 1;
		    //      After: arr[0]++;
		    // 3. Handle both prefix and postfix cases, ensuring side effects are preserved.
		    // 4. Return the updated AST node.
		}

		#region JSDocs
		/// @function    optimizeInfinityExpressions(_node)
		/// @description Optimizes mathematical expressions involving `infinity`, as the results can be deduced without computation. 
		///              For example, any multiplication by infinity results in infinity, and division by infinity results in 0.
		/// @param       {ASTNode}    _astNode    The AST node containing math expressions to optimize.
		/// @return      {ASTNode}    _astNode    The optimized AST node with simplified infinity operations.
		#endregion
		static optimizeInfinityExpressions = function(_node) {
		    // Pseudocode:
		    // 1. Traverse the AST to locate any expressions containing the keyword 'infinity'.
		    // 2. Apply the following transformations:
		    //    - Any number multiplied by infinity is infinity.
		    //    - Any number divided by infinity is 0.
		    //    Example:
		    //      Before: result = 5 * infinity;
		    //      After: result = infinity;
		    // 3. Ensure the changes reflect in the bytecode for execution efficiency.
		    // 4. Return the updated AST node.
		}
		
		#region JSDocs
		/// @function    inlineSimpleFunctions(_node)
		/// @description Inlines simple functions into the code when they are short and frequently called to avoid the overhead of function calls.
		/// @param       {ASTNode}    _astNode    The AST node representing the function call.
		/// @return      {ASTNode}    _astNode    The optimized AST node with inlined function bodies.
		#endregion
		static inlineSimpleFunctions = function(_node) {
		    // Pseudocode:
		    // 1. Identify functions that meet the criteria for inlining (e.g., short, no side effects, frequent calls).
		    // 2. Replace the function call in the AST with the body of the function.
		    //    Example:
		    //      Before: result = simpleFunction();
		    //      After: result = <inlined function body>;
		    // 3. Ensure that inlining respects variable scope and context.
		    // 4. Return the updated AST node.
		}
		
		#region JSDocs
		/// @function    simplifyConditionalExpressions(_node)
		/// @description Simplifies conditional expressions. For instance, `if (true && condition)` becomes `if (condition)`.
		/// @param       {ASTNode}    _astNode    The AST node representing the conditional expression.
		/// @return      {ASTNode}    _astNode    The simplified AST node.
		#endregion
		static simplifyConditionalExpressions = function(_node) {
		    // Pseudocode:
		    // 1. Traverse the AST and locate conditional expressions (`if`, `else`, `ternary operators`).
		    // 2. Simplify expressions where possible, removing constant conditions.
		    //    Example:
		    //      Before: if (true && condition)
		    //      After: if (condition)
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    improveLoopIterations(_node)
		/// @description Optimizes loop iterations by removing unnecessary computations and using efficient constructs.
		/// @param       {ASTNode}    _astNode    The AST node representing a loop.
		/// @return      {ASTNode}    _astNode    The optimized AST node with improved iteration performance.
		#endregion
		static improveLoopIterations = function(_node) {
		    // Pseudocode:
		    // 1. Traverse loops (`for`, `repeat`, `while`, `doUntil`) and check for opportunities to improve iteration efficiency.
		    // 2. Ensure minimal work is done inside the loop, e.g., precompute values outside the loop.
		    //    Example: move constant expressions or variables that don't change outside the loop.
		    //    Before: for (var i = 0; i < expensiveCalculation(); i++) { ... }
		    //    After: var limit = expensiveCalculation(); for (var i = 0; i < limit; i++) { ... }
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    loopInvariantCodeMotion(_node)
		/// @description Hoists loop-invariant code outside loops to reduce unnecessary computations during iterations.
		/// @param       {ASTNode}    _astNode    The AST node representing a loop.
		/// @return      {ASTNode}    _astNode    The optimized AST node with loop-invariant code moved out.
		#endregion
		static loopInvariantCodeMotion = function(_node) {
		    // Pseudocode:
		    // 1. Traverse the loop and identify expressions or variables that don't change during loop execution.
		    // 2. Move these expressions outside the loop to avoid repeated calculations.
		    //    Example:
		    //      Before: for (var i = 0; i < n; i++) { var x = constantCalculation(); ... }
		    //      After: var x = constantCalculation(); for (var i = 0; i < n; i++) { ... }
		    // 3. Return the updated AST node.
		}
		
		#region JSDocs
		/// @function    shortCircuitBooleanEvaluation(_node)
		/// @description Optimizes boolean expressions by short-circuiting them. If the result of a boolean expression is already known, the rest is not evaluated.
		/// @param       {ASTNode}    _astNode    The AST node representing a boolean expression.
		/// @return      {ASTNode}    _astNode    The optimized AST node with short-circuiting applied.
		#endregion
		static shortCircuitBooleanEvaluation = function(_node) {
		    // Pseudocode:
		    // 1. Identify boolean expressions involving `&&` or `||`.
		    // 2. Apply short-circuiting logic. If the first operand determines the result, remove the rest of the expression.
		    //    Example:
		    //      Before: if (expensiveFunction() && true) { ... }
		    //      After: if (expensiveFunction()) { ... }
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    removeNullEmptyCheck(_node)
		/// @description Simplifies checks for null or empty values. For instance, replace `if (thing != undefined)` with `if (thing)`.
		/// @param       {ASTNode}    _astNode    The AST node representing a null/empty check.
		/// @return      {ASTNode}    _astNode    The optimized AST node with simplified checks.
		#endregion
		static removeNullEmptyCheck = function(_node) {
		    // Pseudocode:
		    // 1. Identify checks for null, empty, or undefined values.
		    // 2. Simplify them where appropriate. 
		    //    Example:
		    //      Before: if (thing != undefined)
		    //      After: if (thing)
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    foldLogicalExpressions(_node)
		/// @description Optimizes logical expressions like `a && false` by folding them to `false` at compile time.
		/// @param       {ASTNode}    _astNode    The AST node representing a logical expression.
		/// @return      {ASTNode}    _astNode    The optimized AST node with logical expressions folded.
		#endregion
		static foldLogicalExpressions = function(_node) {
		    // Pseudocode:
		    // 1. Identify logical expressions where one of the operands makes the result obvious.
		    //    Example:
		    //      Before: a && false
		    //      After: false
		    // 2. Apply folding for both `&&` and `||` cases.
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    foldAssignments(_node)
		/// @description Optimizes assignments like `a = a + 1` to use more efficient operators like `a++`.
		/// @param       {ASTNode}    _astNode    The AST node representing an assignment.
		/// @return      {ASTNode}    _astNode    The optimized AST node with folded assignments.
		#endregion
		static foldAssignments = function(_node) {
		    // Pseudocode:
		    // 1. Identify assignment patterns like `a = a + 1` or `b = b * a`.
		    // 2. Replace them with more efficient operators:
		    //    - `a = a + 1` becomes `a++`
		    //    - `b = b * a` becomes `b *= a`
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    loopUnrolling(_node)
		/// @description Unrolls loops if the number of iterations is small and known at compile time, improving performance by reducing loop overhead.
		/// @param       {ASTNode}    _astNode    The AST node representing a loop.
		/// @return      {ASTNode}    _astNode    The optimized AST node with loop unrolling applied.
		#endregion
		static loopUnrolling = function(_node) {
		    // Pseudocode:
		    // 1. Check if the loop has a small, fixed iteration count.
		    // 2. Unroll the loop by manually duplicating the body of the loop.
		    //    Example:
		    //      Before: for (var i = 0; i < 4; i++) { ... }
		    //      After: (body of the loop repeated 4 times)
		    // 3. Ensure that the total expression size remains within reasonable limits (e.g., 1024 bytes).
		    // 4. Return the unrolled AST node.
		}
		
		#region JSDocs
		/// @function    commonSubexpressionElimination(_astNode)
		/// @description Eliminates repeated subexpressions by calculating them once and reusing the result.
		/// @param       {ASTNode}    _astNode    The AST node containing common subexpressions.
		/// @return      {ASTNode}    _astNode    The optimized AST node with common subexpressions eliminated.
		#endregion
		static commonSubexpressionElimination = function(_node) {
		    // Pseudocode:
		    // 1. Identify repeated expressions within the same scope.
		    //    Example:
		    //      Before: c = (a - b) + 1; d = (a - b) + 2;
		    //      After: var _temp = (a - b); c = _temp + 1; d = _temp + 2;
		    // 2. Store the result of the first evaluation and reuse it for subsequent calculations.
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    peepholeOptimizations(_astNode)
		/// @description Performs small, localized optimizations that can be found by looking at a few adjacent instructions.
		/// @param       {ASTNode}    _astNode    The AST node representing a small code block.
		/// @return      {ASTNode}    _astNode    The optimized AST node after peephole optimizations.
		#endregion
		static peepholeOptimizations = function(_node) {
		    // Pseudocode:
		    // 1. Look for small, low-level optimizations by examining adjacent instructions or expressions.
		    // 2. Examples include:
		    //    - Removing redundant loads and stores.
		    //    - Merging adjacent operations (e.g., a = b; b = a can be optimized away).
		    // 3. Return the optimized AST node.
		}
		
		
		//array_push(parserSteps, constantFolding);
		
		//array_push(parserSteps, removeRedundantTypeChecks);
		//array_push(parserSteps, simplifyIncrementExpressions);
		//array_push(parserSteps, optimizeInfinityExpressions);
		//array_push(parserSteps, inlineSimpleFunctions);
		//array_push(parserSteps, simplifyConditionalExpressions);
		//array_push(parserSteps, optimizeVariableScope);
		//array_push(parserSteps, optimizePickOneFunctions);
		//array_push(parserSteps, improveLoopIterations);
		//array_push(parserSteps, loopInvariantCodeMotion);
		//array_push(parserSteps, constantPropagation);
		//array_push(parserSteps, shortCircuitBooleanEvaluation);
		//array_push(parserSteps, removeNullEmptyCheck);
		//array_push(parserSteps, foldLogicalExpressions);
		//array_push(parserSteps, foldAssignments);
		//array_push(parserSteps, strengthReduction);
		//array_push(parserSteps, loopUnrolling);
		//array_push(parserSteps, commonSubexpressionElimination);
		//array_push(parserSteps, peepholeOptimizations);
		//array_push(parserSteps, optimizeAlternateFunctions);
		
		
		
		#endregion
		
		#region Helper Functions
		// the line of a node and its text, for the messages
		static __line = function(_node) {
			return (sources != undefined) ? sources.position(_node.span).line : 0;
		};
		static __lineString = function(_node) {
			return (sources != undefined) ? sources.position(_node.span).lineString : "";
		};
		
		// a Literal of a value the optimizer computed; an int64 that the compiler must keep as int64 is written in hex
		static __literal = function(_value, _span, _int64Typed = true) {
			var _ty = "real";
			var _lexeme;
			if (is_string(_value)) {
				_ty = "string";
				_lexeme = json_stringify(_value);
			}
			else if (is_bool(_value)) {
				_ty = "bool";
				_lexeme = (_value) ? "true" : "false";
			}
			else if (is_int64(_value)) {
				_ty = "int64";
				_lexeme = (_int64Typed) ? __hexLexeme(_value) : string(_value);
			}
			else if (is_undefined(_value)) {
				_ty = "undefined";
				_lexeme = "undefined";
			}
			else {
				_lexeme = __realLexeme(_value);
			}
			return new ASTLiteral(_span, _ty, _lexeme, _value);
		};
		
		// the text of a real that reads back to the same value
		static __realLexeme = function(_value) {
			if (!is_real(_value)) return string(_value);
			if (is_nan(_value)) return "NaN";
			if (is_infinity(_value)) return (_value > 0) ? "infinity" : "-infinity";
			if (frac(_value) == 0) && (abs(_value) < 9007199254740992) return string(int64(_value));
			return json_stringify(_value);
		};
		
		// an int64 as a hex literal, which the compiler reads as an int64
		static __hexLexeme = function(_value) {
			var _digits = "";
			var _i = 0; repeat (16) {
				_digits = string_char_at("0123456789ABCDEF", real((_value >> (_i * 4)) & 0xF) + 1) + _digits;
			_i++}
			return "0x" + _digits;
		};
		
		// [true, value] when a node is a compile-time constant (a literal or a built-in constant), else [false]
		static __constantValue = function(_node) {
			if (_node.kind == __GMLC_NodeKind_Literal) {
				return [true, _node.value];
			}
			if (_node.kind == __GMLC_NodeKind_Identifier) && (_node.symbol != undefined) && (_node.symbol.kind == "BuiltinConstant") {
				var _data = env.getConstant(_node.name);
				if (_data != undefined) {
					var _value = _data.value;
					if (is_bool(_value)) || (is_real(_value)) || (is_undefined(_value)) || (is_string(_value)) {
						return [true, _value];
					}
				}
			}
			return [false];
		};
		
		// whether a constant can take the place of the node in _node_data without changing how its parent folds
		static __keepsValue = function(_node_data, _value) {
			if (foldAll) || (_node_data.parent == undefined) return true;
			return __canReplaceIn(_node_data.parent, _node_data.key, _value);
		};
		
		// The compiler folds operators on constants with other types than the same operators give at run time
		// (`!false` folds to 1, `5 & 3` folds to a real). A value only known to the optimizer (a propagated local, a
		// folded call) must not turn an operator the compiler would run into one it folds, unless both agree: strings
		// never fold, and comparisons of bools and whole numbers give the same bool.
		static __canReplaceIn = function(_parent, _key, _value) {
			switch (_parent.kind) {
				case __GMLC_NodeKind_Index:
				case __GMLC_NodeKind_MethodCall: {
					return (_key != "object");
				}
				case __GMLC_NodeKind_Unary:
				case __GMLC_NodeKind_Logical: {
					return is_string(_value);
				}
				case __GMLC_NodeKind_Binary: {
					if (is_string(_value)) return true;
					switch (_parent.op) {
						case "==": case "!=": case "<": case "<=": case ">": case ">=": {
							return (is_bool(_value)) || ((is_real(_value)) && (frac(_value) == 0) && (abs(_value) < 9007199254740992));
						}
					}
					return false;
				}
			}
			return true;
		};
		
		// an operator on constants folded as the compiler folds it, undefined when it does not fold
		static __foldOperator = function(_node) {
			// two strings join the same way at compile time and at run time
			if (_node.kind == __GMLC_NodeKind_Binary) && (_node.op == "+")
			&& (_node.left.kind == __GMLC_NodeKind_Literal) && (is_string(_node.left.value))
			&& (_node.right.kind == __GMLC_NodeKind_Literal) && (is_string(_node.right.value))
			{
				var _string = _node.left.value + _node.right.value;
				show_debug_message($"Optimizer :: constantFolding :: Could use literal of `{_string}` in line ({__line(_node)}) `{__lineString(_node)}`")
				return __literal(_string, _node.span);
			}
			
			// an error leaves the node to the run time, which raises it where GameMaker does
			try {
				var _constant = __GMLCconstantValue(self, _node);
				if (!_constant[0]) return undefined;
				var _value = __GMLCconstantEmit(_constant);
			}
			catch (_err) {
				return undefined;
			}
			
			// a whole number this large does not read back as the same number
			if (!_constant[2]) && (is_int64(_value)) && (abs(_constant[1]) >= power(2, 63)) return undefined;
			
			show_debug_message($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({__line(_node)}) `{__lineString(_node)}`")
			return __literal(_value, _node.span, _constant[2]);
		};
		
		// a ternary with a constant condition becomes the branch it takes
		static __foldConditional = function(_node_data) {
			var _node = _node_data.node;
			var _test = __constantValue(_node.test);
			if (!_test[0]) || (!is_numeric(_test[1])) return _node;
			
			var _taken   = (_test[1]) ? _node.consequent : _node.alternate;
			var _dropped = (_test[1]) ? _node.alternate : _node.consequent;
			if (__containsNoOp(_dropped)) return _node;
			
			var _value = __constantValue(_taken);
			if (_value[0]) && (!__keepsValue(_node_data, _value[1])) return _node;
			
			if (_test[1]) {
				show_debug_message($"Optimizer :: constantFolding :: Could collapse ternary expression to left side in line ({__line(_node)}) `{__lineString(_node)}`")
			}
			else {
				show_debug_message($"Optimizer :: constantFolding :: Could collapse ternary expression to right side in line ({__line(_node)}) `{__lineString(_node)}`")
			}
			return _taken;
		};
		
		// the function a call calls when its callee names a built-in function, else undefined
		static __calleeFunction = function(_node) {
			var _callee = _node.callee;
			if (_callee.kind != __GMLC_NodeKind_Identifier) || (_callee.symbol == undefined) || (_callee.symbol.kind != "BuiltinFunction") return undefined;
			var _data = env.getFunction(_callee.name);
			return (_data != undefined) ? (_data[$ "raw"] ?? _data.value) : undefined;
		};
		
		// an Identifier naming a built-in function
		static __builtin = function(_name, _span) {
			var _identifier = new ASTIdentifier(_span, _name);
			_identifier.symbol = new GMLC_Symbol("BuiltinFunction", _name);
			return _identifier;
		};
		
		static __argumentsAreLiteral = function(_arguments) {
			var _i=0; repeat(array_length(_arguments)) {
				if (_arguments[_i].kind != __GMLC_NodeKind_Literal) {
					return false;
				}
			_i+=1;}//end repeat loop
			return true;
		}
		
		static __build_literal_from_function_call_constant_folding = function(_script, _node) {
			if (!__argumentsAreLiteral(_node.args)) return _node;
			
			//remap the arguments
			var _arr = _node.args;
			var _new_arr = [];
			var _i=0; repeat(array_length(_arr)) {
				_new_arr[_i] = _arr[_i].value;
			_i+=1;}//end repeat loop
			
			try {
				var _value = script_execute_ext(_script, _new_arr)
			}
			catch (err) {
				// an error leaves the call to the run time, which raises it where GameMaker does
				return _node;
			}
			
			// only values a literal can hold, where the parent does not fold them differently
			if (!is_string(_value)) && (!is_numeric(_value)) && (!is_undefined(_value)) return _node;
			if (foldSlot != undefined) && (foldSlot.node == _node) && (!__keepsValue(foldSlot, _value)) return _node;
			
			show_debug_message($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({__line(_node)}) `{__lineString(_node)}`")
			return __literal(_value, _node.span);
		}
		
		#endregion
	}
#endregion
