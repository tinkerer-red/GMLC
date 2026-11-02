#region jsDoc
/// @func    GMLC_Opt_RedundantConversionElim()
/// @desc    The `redundant-conversion-elim` optimizer pass: removes a conversion or a type test whose answer the kind
///          of its argument gives. `real(_n)` of a Real, `string(_s)` of a string and `floor(_n)` of a whole number
///          become the argument, `abs(_n)` of a number that is not below zero too; `is_string(_s)` of a string
///          becomes `true`, and `typeof(_n)` of a Real becomes `"number"`. The argument must be known from the tree
///          and, when the call is replaced by a constant, free of effects and unable to throw.
/// @returns {Struct.GMLC_Opt_RedundantConversionElim}
#endregion
function GMLC_Opt_RedundantConversionElim() : GMLC_OptimizerPass("redundant-conversion-elim") constructor {
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Replaces the conversions and type tests the kinds of their arguments settle.
	/// @self    GMLC_Opt_RedundantConversionElim
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _registry = __gmlc_optimizer_pass_registry();
		var _range = _registry[$ "value-range-simplify"];
		var _w = _range.analyze(_node, _cx, [__GMLC_NodeKind_Call]);
		var _edits = [];
		var _i = 0; repeat (array_length(_w.events)) {
			var _e = _w.events[_i];
			var _edit = __decide(_range, _e, _cx);
			if (_edit != undefined) && (!_cx.optimizer.__containsNoOp(_e.node)) {
				_edit.path = _e.path;
				array_push(_edits, _edit);
				_cx.stats[$ (_edit.op == "child") ? "conversions_removed" : "tests_decided"]++;
			}
		_i++}
		return _range.applyEdits(_node, _edits);
	};

	#region jsDoc
	/// @func    __decide(_range, _event, _cx)
	/// @desc    What replaces a call, or undefined.
	/// @self    GMLC_Opt_RedundantConversionElim
	/// @param   {Struct} _range : The range analysis
	/// @param   {Struct} _event : The call and the facts of its arguments
	/// @param   {Struct} _cx    : The pass context
	/// @returns {Struct|Undefined}
	#endregion
	static __decide = function(_range, _event, _cx) {
		var _name = __gmlc_opt_builtin_call(_event.node);
		if (_name == undefined) || (array_length(_event.operands) != 1) return undefined;
		var _arg = _event.operands[0];
		var _f = _arg.f;
		switch (_name) {
			case "real": return (_f.k == GMLC_RANGE_KIND.REAL) ? { op: "child", i: 1 } : undefined;
			case "bool": return (_f.k == GMLC_RANGE_KIND.BOOL) ? { op: "child", i: 1 } : undefined;
			case "int64": return (_f.k == GMLC_RANGE_KIND.INT64) ? { op: "child", i: 1 } : undefined;
			case "string": return (_f.k == GMLC_RANGE_KIND.STRING) ? { op: "child", i: 1 } : undefined;
			case "floor": case "ceil": case "round":
				return ((_f.k == GMLC_RANGE_KIND.REAL) && (_f.whole)) ? { op: "child", i: 1 } : undefined;
			case "abs":
				return ((_f.k == GMLC_RANGE_KIND.REAL) && (_f.lo >= 0) && (!_f.nz)) ? { op: "child", i: 1 } : undefined;
			case "typeof": {
				var _type = _range.typeName(_f);
				if (_type == undefined) || (!_arg.safe) return undefined;
				var _literal = _cx.optimizer.__literal(_type, _event.node.span);
				return (_literal == undefined) ? undefined : { op: "literal", node: _literal };
			}
		}
		var _d = _range.isDecided(_name, _f);
		if (_d == -1) || (!_arg.safe) return undefined;
		var _literal = _cx.optimizer.__literal(_d == 1, _event.node.span);
		return (_literal == undefined) ? undefined : { op: "literal", node: _literal };
	};
}
