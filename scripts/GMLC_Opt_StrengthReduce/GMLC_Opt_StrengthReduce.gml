#region jsDoc
/// @func    GMLC_Opt_StrengthReduce()
/// @desc    The `strength-reduce` optimizer pass: the square of a name that holds a double, written `sqr(x)` or
///          `power(x, 2)`, becomes the product `x * x`, which gives the same bits without a call.
///          `sqr(_dx) + sqr(_dy)` becomes `(_dx * _dx) + (_dy * _dy)`.
/// @returns {Struct.GMLC_Opt_StrengthReduce}
#endregion
function GMLC_Opt_StrengthReduce() : GMLC_OptimizerPass("strength-reduce") constructor {
	#region Init
	#endregion
	
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with its squares written as products, or undefined when it has none.
	/// @self    GMLC_Opt_StrengthReduce
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _state = { cx: _cx, optimizer: _cx.optimizer, root: _node, kinds: undefined };
		return __walk(_node, _state, true);
	};
	#endregion
	
	#region Walk
	#region jsDoc
	/// @func    __walk(_node, _state, _isRoot, [_isStatement])
	/// @desc    Rewrites the squares under a node, inner ones first, nested functions and frozen code left out,
	///          without changing the node. A call that is a whole statement stays a call: GameMaker refuses a
	///          statement that is only an operator.
	/// @self    GMLC_Opt_StrengthReduce
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct}         _state  : The pass's state
	/// @param   {Bool}           _isRoot : Whether the node is the function itself
	/// @param   {Bool}           [_isStatement] : Whether the node is the expression of an expression statement
	/// @returns {Struct.ASTNode|Undefined} The new node, undefined when nothing changed
	#endregion
	static __walk = function(_node, _state, _isRoot, _isStatement = false) {
		if (!_isRoot) && ((__gmlc_opt_is_function(_node)) || ((_state.optimizer.has_no_op_targets) && (_state.optimizer.__isNoOp(_node)))) return undefined;
		var _slots = _node.childSlots();
		var _edits = [];
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new = __walk(_slot.node, _state, false, _node.kind == __GMLC_NodeKind_ExprStmt);
			if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
		_i++}
		var _current = _node;
		if (array_length(_edits) > 0) _current = __gmlc_opt_rebuild_children(_node, _edits);
		if (_current.kind == __GMLC_NodeKind_Call) && (!_isStatement) {
			var _product = __square(_current, _state);
			if (_product != undefined) return _product;
		}
		return (_current == _node) ? undefined : _current;
	};
	
	#endregion
	
	#region Squares
	#region jsDoc
	/// @func    __square(_call, _state)
	/// @desc    `x * x` for `sqr(x)` and `power(x, 2)` when x is a name that holds a double: a product of doubles gives
	///          the bits the call gives, and a name costs nothing to read twice.
	/// @self    GMLC_Opt_StrengthReduce
	/// @param   {Struct.ASTNode} _call  : The call
	/// @param   {Struct}         _state : The pass's state
	/// @returns {Struct.ASTBinary|Undefined}
	#endregion
	static __square = function(_call, _state) {
		var _name = __gmlc_opt_builtin_call(_call);
		if (_name == undefined) return undefined;
		var _args = _call.args;
		if (_name == "sqr") {
			if (array_length(_args) != 1) return undefined;
		}
		else if (_name == "power") {
			if (array_length(_args) != 2) return undefined;
			var _exponent = _args[1];
			if (_exponent.kind != __GMLC_NodeKind_Literal) || (_exponent.ty != "real") || (_exponent.value != 2) return undefined;
		}
		else {
			return undefined;
		}
		var _base = _args[0];
		if (_base.kind != __GMLC_NodeKind_Identifier) || (_base.symbol == undefined) return undefined;
		var _leaf = (_base.symbol.kind == "Local") || (_base.symbol.kind == "BuiltinVar") || (_base.symbol.kind == "BuiltinConstant") || ((_base.symbol.kind == "Self") && (__gmlc_opt_builtin_variable(_base.name) != undefined));
		if (!_leaf) return undefined;
		// the VM reads a built-in instance variable slower than it calls `sqr` once
		if (_state.cx.optimizer.outputName() == "gml-source-vm") && ((_base.symbol.kind == "BuiltinVar") || (_base.symbol.kind == "Self")) return undefined;
		if (_state.kinds == undefined) _state.kinds = __gmlc_opt_local_value_kinds(_state.root, _state.cx);
		if (__gmlc_opt_value_kind(_base, _state.kinds, _state.cx) != 2) return undefined;
		_state.cx.stats[$ "reduced"]++;
		return new ASTBinary(_call.span, "*", _base, __gmlc_opt_clone(_base));
	};
	#endregion
	
}
