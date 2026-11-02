#region jsDoc
/// @func    GMLC_Opt_ConstantPropagate()
/// @desc    `constant-propagate`: replaces the reads of a local that a literal was written to by the literal, up to
///          the first place the local is written again: `var _a = 2; b = _a + 1;` becomes `var _a = 2; b = 2 + 1;`.
///          The optimizer's sweep calls `sweep` on each node, inner ones first; only statement lists (the script and
///          blocks) do anything.
/// @returns {Struct.GMLC_Opt_ConstantPropagate}
#endregion
function GMLC_Opt_ConstantPropagate() : GMLC_OptimizerPass("constant-propagate") constructor {
	#region Sweep
	#region jsDoc
	/// @func    sweep(_node_data, _o)
	/// @desc    Propagates the constants a statement list gives its locals. The tree is changed in place; the node given
	///          is returned.
	/// @self    GMLC_Opt_ConstantPropagate
	/// @param   {Struct}                      _node_data : {node, parent, key, index}
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _o         : The optimizer
	/// @returns {Struct.ASTNode}
	#endregion
	static sweep = function(_node_data, _o) {
		var _node = _node_data.node;
		
		if (_node.kind != __GMLC_NodeKind_Block) && (_node.kind != __GMLC_NodeKind_Script) {
			return _node;
		}
		
		var _body = _node.body;
		// the locals of this list a literal sets and no other statement of it writes: an operand next to one of them
		// folds once both are propagated
		var _found = [];
		var _c = 0; repeat (array_length(_body)) {
			var _st = _body[_c];
			if (_st.kind == __GMLC_NodeKind_VarDeclList) {
				var _d = 0; repeat (array_length(_st.declarations)) {
					var _cd = __constantLocal(_st.declarations[_d].target, _st.declarations[_d].init);
					if (_cd != undefined) array_push(_found, { at: _c, cd: _cd });
				_d++}
			}
			else if (_st.kind == __GMLC_NodeKind_ExprStmt) && (_st.expression.kind == __GMLC_NodeKind_Assign) && (_st.expression.op == "=") {
				var _cd = __constantLocal(_st.expression.target, _st.expression.value);
				if (_cd != undefined) array_push(_found, { at: _c, cd: _cd });
			}
		_c++}
		var _constants = {};
		var _f = 0; repeat (array_length(_found)) {
			var _entry = _found[_f];
			var _written = false;
			var _b = 0; repeat (array_length(_body)) {
				if (_b != _entry.at) && (__writesLocal(_body[_b], _entry.cd)) {
					_written = true;
					break;
				}
			_b++}
			if (!_written) _constants[$ _entry.cd.name] = true;
		_f++}
		_o.__constant_propagate_constants = _constants;
		var _i = 0; repeat (array_length(_body)) {
			var _statement = _body[_i];
			
			if (!_o.__isNoOp(_statement)) {
				if (_statement.kind == __GMLC_NodeKind_VarDeclList) {
					var _declarations = _statement.declarations;
					var _j = 0; repeat (array_length(_declarations)) {
						var _declaration = _declarations[_j];
						var _constant_data = __constantLocal(_declaration.target, _declaration.init);
						if (_constant_data != undefined) {
							if (!__propagateToList(_declarations, _j + 1, _constant_data, _o)) {
								__propagateToList(_body, _i + 1, _constant_data, _o);
							}
						}
					_j++}
				}
				else if (_statement.kind == __GMLC_NodeKind_ExprStmt)
				&& (_statement.expression.kind == __GMLC_NodeKind_Assign)
				&& (_statement.expression.op == "=")
				{
					var _assign = _statement.expression;
					var _constant_data = __constantLocal(_assign.target, _assign.value);
					if (_constant_data != undefined) {
						__propagateToList(_body, _i + 1, _constant_data, _o);
					}
				}
			}
		
		_i++}
		
		return _node;
	};
	#endregion

	#region Helpers
	#region jsDoc
	/// @func    __constantLocal(_target, _value)
	/// @desc    The constant a local takes when a literal is written to it, or undefined.
	/// @self    GMLC_Opt_ConstantPropagate
	/// @param   {Struct.ASTNode} _target : The written expression
	/// @param   {Struct.ASTNode} _value  : The written value
	/// @returns {Struct|Undefined} {slot, literal}
	#endregion
	static __constantLocal = function(_target, _value) {
		if (_value == undefined) || (_value.kind != __GMLC_NodeKind_Literal) return undefined;
		if (_target.kind != __GMLC_NodeKind_Identifier) || (_target.symbol == undefined) return undefined;
		if (_target.symbol.kind != "Local") return undefined;
		// a local a pass made has no slot, and a name no other local has
		return {
			slot : _target.symbol.slot,
			name : _target.name,
			literal : _value,
		};
	};

	#region jsDoc
	/// @func    __isConstantLocal(_node, _constant_data)
	/// @desc    Whether a node is the constant local.
	/// @self    GMLC_Opt_ConstantPropagate
	/// @param   {Struct.ASTNode} _node          : The node
	/// @param   {Struct}         _constant_data : {slot, name, literal} of the local
	/// @returns {Bool}
	#endregion
	static __isConstantLocal = function(_node, _constant_data) {
		return (_node.kind == __GMLC_NodeKind_Identifier)
			&& (_node.symbol != undefined)
			&& (_node.symbol.kind == "Local")
			// a pass may write a local it did not make without its slot: the name is the local then
			&& (((_node.symbol.slot != undefined) && (_node.symbol.slot == _constant_data.slot)) || (((_node.symbol.slot == undefined) || (_constant_data.slot == undefined)) && (_node.name == _constant_data.name)));
	};

	#region jsDoc
	/// @func    __rootIdentifier(_node)
	/// @desc    The innermost object of an index chain (`a` of `a[0].b`).
	/// @self    GMLC_Opt_ConstantPropagate
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Struct.ASTNode}
	#endregion
	static __rootIdentifier = function(_node) {
		while (_node.kind == __GMLC_NodeKind_Index) {
			_node = _node.object;
		}
		return _node;
	};

	#region jsDoc
	/// @func    __propagateToList(_array, _from, _constant_data, _o)
	/// @desc    Propagates a constant local into the items of a list from an index on, until one writes the local.
	/// @self    GMLC_Opt_ConstantPropagate
	/// @param   {Array<Struct.ASTNode>}       _array         : Statements or declarations
	/// @param   {Real}                        _from          : First index
	/// @param   {Struct}                      _constant_data : {slot, name, literal} of the local
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _o             : The optimizer
	/// @returns {Bool} Whether propagation stopped
	#endregion
	static __propagateToList = function(_array, _from, _constant_data, _o) {
		var _i = _from; repeat (array_length(_array) - _from) {
			var _return = __propagateConstants(_array[_i], _constant_data, _o);
			if (is_instanceof(_return, ASTNode)) {
				_array[_i] = _return;
			}
			else if (_return == true) {
				return true;
			}
		_i++}
		return false;
	};

	#region jsDoc
	/// @func    __propagateConstants(_node, _constant_data, _o)
	/// @desc    Replaces reads of a constant local in a node by its literal, up to the first write of the local.
	/// @self    GMLC_Opt_ConstantPropagate
	/// @param   {Struct.ASTNode}              _node          : The node
	/// @param   {Struct}                      _constant_data : {slot, name, literal} of the local
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _o             : The optimizer
	/// @returns {Struct.ASTNode|Bool} The node to put in its place, true when propagation must stop, false to go on
	#endregion
	static __propagateConstants = function(_node, _constant_data, _o) {
		if (_o.__isNoOp(_node)) {
			return __writesLocal(_node, _constant_data);
		}
		
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier: {
				if (__isConstantLocal(_node, _constant_data)) {
					var _literal = _constant_data.literal;
					_o.optimization_occured = true;
					return new ASTLiteral(_node.span, _literal.ty, _literal.lexeme, _literal.value);
				}

				//safe to continue
				return false;
			break;}
			
			case __GMLC_NodeKind_Assign: {
				if (__isConstantLocal(__rootIdentifier(_node.target), _constant_data)) {
					//propigate to children incase the expression contains it's self and could be constant folded on additional optimize steps
					// example :: xx = xx + 1;
					if (!__writesLocal(_node.value, _constant_data)) {
						var _return = __propagateConstants(_node.value, _constant_data, _o);
						if (is_instanceof(_return, ASTNode)) {
							_node.value = _return;
						}
					}

					/// should break propagation
					return true;
				}
			break;}
			
			case __GMLC_NodeKind_VarDecl: {
				//propigate to children incase the expression contains it's self and could be constant folded on additional optimize steps
				// example :: var xx = xx + 1;
				if (_node.init != undefined) {
					if (__writesLocal(_node.init, _constant_data)) {
						return true;
					}
					var _return = __propagateConstants(_node.init, _constant_data, _o);
					if (is_instanceof(_return, ASTNode)) {
						_node.init = _return;
					}
				}
				return __isConstantLocal(_node.target, _constant_data);
			break;}
			
			case __GMLC_NodeKind_ExprStmt: {
				var _return = __propagateConstants(_node.expression, _constant_data, _o);
				if (is_instanceof(_return, ASTNode)) {
					_node.expression = _return;
					return false;
				}
				return _return;
			break;}
			
			// statements run in order, so propagation can go on up to the one that writes the local
			case __GMLC_NodeKind_Block: {
				return __propagateToChildren(_node, _constant_data, _o);
			break;}
			
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
						var _return = __propagateConstants(_node[$ _key], _constant_data, _o);
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
		
		return __propagateToChildren(_node, _constant_data, _o)
	};

	#region jsDoc
	/// @func    __propagateToChildren(_node, _constant_data, _o)
	/// @desc    Propagates a constant local into a node's children in order, up to the first write.
	/// @self    GMLC_Opt_ConstantPropagate
	/// @param   {Struct.ASTNode}              _node          : The node
	/// @param   {Struct}                      _constant_data : {slot, name, literal} of the local
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _o             : The optimizer
	/// @returns {Bool} Whether propagation stopped
	#endregion
	static __propagateToChildren = function(_node, _constant_data, _o) {
		var _children = _node.childSlots()
		var _i=0; repeat(array_length(_children)) {
			var _child_data = _children[_i]
			var _child_node = _child_data.node
			
			// a local used where a literal would fold differently from the run time value keeps its name
			if (_child_node.kind == __GMLC_NodeKind_Identifier)
			&& (!_o.__canReplaceIn(_node, _child_data.key))
			{
				_i++
				continue;
			}
			
			// the VM gives a real for a whole-number local next to an int64 where the literal keeps the int64
			// an int64 put next to an int64 stays one: only another value keeps the local
			if (_o.has_int64) && (_child_node.kind == __GMLC_NodeKind_Identifier) && (_constant_data.literal.ty != "int64") && (__gmlc_opt_int64_beside(_node, _child_data.key)) {
				_i++
				continue;
			}
			
			// YYC runs an arithmetic operator on a number literal slower than on a local that holds it (the VM does
			// not): for the YYC output an operand next to a non-literal keeps the local, in a loop or not, unless the
			// other operand is a literal or a local a literal sets (then the operation folds)
			if (_child_node.kind == __GMLC_NodeKind_Identifier) && (_o.outputName() == "gml-source-yyc")
			&& (__arithmeticBeside(_node, _child_data, _constant_data.literal, _o.__constant_propagate_constants)) {
				_i++
				continue;
			}
			
			var _return = __propagateConstants(_child_node, _constant_data, _o)
			
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
	};

	#region jsDoc
	/// @func    __arithmeticBeside(_node, _key, _literal, _constants)
	/// @desc    Whether the child `_key` of a node is an operand YYC runs slower as `_literal`
	///          (`__gmlc_opt_yyc_slow_operand`) beside an operand that is not made of literals and locals of `_constants`
	///          (`__gmlc_opt_constant_tree`).
	/// @self    GMLC_Opt_ConstantPropagate
	/// @param   {Struct.ASTNode}    _node      : The node
	/// @param   {String}            _key       : The child's field
	/// @param   {Struct.ASTLiteral} _literal   : The constant
	/// @param   {Struct}            _constants : Local names, as keys
	/// @returns {Bool}
	#endregion
	static __arithmeticBeside = function(_node, _slot, _literal, _constants) {
		var _key = _slot.key;
		// an argument of a built-in call
		if (_node.kind == __GMLC_NodeKind_Call) {
			return (_key == "args") && __gmlc_opt_yyc_slow_argument(_node, _slot.index, _literal, _constants);
		}
		if (_node.kind != __GMLC_NodeKind_Binary) return false;
		if (!__gmlc_opt_yyc_slow_operand(_node.op, _literal)) return false;
		var _other = (_key == "left") ? _node.right : _node.left;
		return !__gmlc_opt_constant_tree(_other, _constants);
	};

	#region jsDoc
	/// @func    __writesLocal(_node, _constant_data)
	/// @desc    Whether a node writes the constant local (not counting nested functions).
	/// @self    GMLC_Opt_ConstantPropagate
	/// @param   {Struct.ASTNode} _node          : The node
	/// @param   {Struct}         _constant_data : {slot, name, literal} of the local
	/// @returns {Bool}
	#endregion
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
	};
	#endregion
}
