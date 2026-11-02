#region jsDoc
/// @func    GMLC_Opt_ConstantFunctionEval()
/// @desc    The `constant-function-eval` optimizer pass. A call of a built-in the fold list allows, with literals
///          for every argument, becomes the value it returns: `max(100, 80 + 30)` is `110` once the sum is folded.
///          The value comes from the same evaluation the constant folding uses. A call of any other built-in
///          with literal arguments is counted and left, and so is a call whose evaluation fails.
/// @returns {Struct.GMLC_Opt_ConstantFunctionEval}
#endregion
function GMLC_Opt_ConstantFunctionEval() : GMLC_OptimizerPass("constant-function-eval") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The literal a call of an allowed built-in on literals returns, or undefined to keep the node.
	/// @self    GMLC_Opt_ConstantFunctionEval
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (_node.kind != __GMLC_NodeKind_Call) return undefined;
		var _optimizer = _cx.optimizer;
		var _function = _optimizer.__calleeFunction(_node);
		if (_function == undefined) return undefined;
		var _name = _node.callee.name;
		if (__foldedElsewhere(_name)) return undefined;
		if (!_optimizer.__argumentsAreLiteral(_node.args)) return undefined;
		var _count = array_length(_node.args);
		var _arity = _cx.env.foldableArity(_name);
		if (_arity == undefined) {
			if (_count > 0) _cx.stats[$ "refused_not_allowlisted"]++;
			return undefined;
		}
		if (_count < _arity[0]) || ((_arity[1] >= 0) && (_count > _arity[1])) return undefined;
		var _folded = _optimizer.__build_literal_from_function_call_constant_folding(_function, { node: _node, parent: undefined, key: undefined, index: undefined });
		if (_folded != _node) {
			_cx.stats[$ "calls_folded"]++;
			return _folded;
		}
		if (__failed(_optimizer, _node)) _cx.stats[$ "refused_error"]++;
		return undefined;
	};
	#endregion

	#region Private
	#region jsDoc
	/// @func    __foldedElsewhere(_name)
	/// @desc    Whether the constant folding treats a built-in by rules of its own (string building, `choose`,
	///          character codes, `sqrt`), which this pass leaves to it.
	/// @self    GMLC_Opt_ConstantFunctionEval
	/// @param   {String} _name : The built-in
	/// @returns {Bool}
	#endregion
	static __foldedElsewhere = function(_name) {
		switch (_name) {
			case "choose": case "sqrt": case "string": case "string_concat": case "string_join": case "string_join_ext":
			case "chr": case "ansi_char":
			return true;
		}
		return false;
	};

	#region jsDoc
	/// @func    __failed(_optimizer, _node)
	/// @desc    Whether the optimizer recorded the evaluation of a call as failing.
	/// @self    GMLC_Opt_ConstantFunctionEval
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _optimizer : The optimizer
	/// @param   {Struct.ASTNode}              _node      : The call
	/// @returns {Bool}
	#endregion
	static __failed = function(_optimizer, _node) {
		var _failing = _optimizer.__failing;
		var _i = 0; repeat (array_length(_failing)) {
			if (_failing[_i].node == _node) return true;
		_i++}
		return false;
	};
	#endregion
}
