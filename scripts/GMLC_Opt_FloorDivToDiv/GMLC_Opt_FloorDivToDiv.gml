#region jsDoc
/// @func    GMLC_Opt_FloorDivToDiv()
/// @desc    The `floor-div-to-div` optimizer pass: `floor(_a / _b)` becomes `_a div _b`, one operator instead of a
///          division and a call, when `_a` is a whole number from zero up below 2^53 and `_b` is a whole number from
///          1 to 2^31 (a constant, as in `floor(_x / 32)` for a counter `_x`). For those operands both give the same
///          whole number; for a negative or fractional `_a` or a fractional `_b` they do not, so those are left.
/// @returns {Struct.GMLC_Opt_FloorDivToDiv}
#endregion
function GMLC_Opt_FloorDivToDiv() : GMLC_OptimizerPass("floor-div-to-div") constructor {
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Replaces `floor(a / b)` where the operands make `a div b` give the same number.
	/// @self    GMLC_Opt_FloorDivToDiv
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _registry = __gmlc_optimizer_pass_registry();
		var _range = _registry[$ "value-range-simplify"];
		var _w = _range.analyze(_node, _cx, [__GMLC_NodeKind_Call, __GMLC_NodeKind_Binary]);
		var _edits = [];
		// YYC gives some built-ins' whole numbers as integers, which `div` keeps where `floor` gives a real
		// (`array_length(_a) div 2` is an int on YYC): there the dividend is no call
		var _yyc = (_cx.optimizer.outputName() == "gml-source-yyc");
		var _divisions = {};
		var _i = 0; repeat (array_length(_w.events)) {
			var _e = _w.events[_i];
			if (_e.node.kind == __GMLC_NodeKind_Binary) {
				if (_e.node.op == "/") _divisions[$ _range.pathKey(_e.path)] = _e;
			}
			else if (__gmlc_opt_builtin_call(_e.node) == "floor") && (array_length(_e.node.args) == 1) {
				var _path = array_concat(_e.path, [1]);
				var _division = _divisions[$ _range.pathKey(_path)];
				if (_division != undefined) && (__qualifies(_division.operands[0].f, _division.operands[1].f)) && (!(_yyc && (_division.node.left.kind == __GMLC_NodeKind_Call)))
				&& (!_cx.optimizer.__containsNoOp(_e.node)) {
					array_push(_edits, { path: _e.path, op: "div", i: 1 });
					_cx.stats[$ "floors_replaced"]++;
				}
			}
		_i++}
		return _range.applyEdits(_node, _edits);
	};

	#region jsDoc
	/// @func    __qualifies(_a, _b)
	/// @desc    Whether `floor(a / b)` and `a div b` give the same number: `a` a whole Real from zero up (not
	///          negative zero) below 2^53, so the quotient never rounds up to the next whole number, and `b` a
	///          single whole Real from 1 to 2^31.
	/// @self    GMLC_Opt_FloorDivToDiv
	/// @param   {Struct} _a : The fact of the dividend
	/// @param   {Struct} _b : The fact of the divisor
	/// @returns {Bool}
	#endregion
	static __qualifies = function(_a, _b) {
		if (_a.k != GMLC_RANGE_KIND.REAL) || (_b.k != GMLC_RANGE_KIND.REAL) return false;
		if (!_a.whole) || (_a.nan) || (_a.nz) || (_a.lo < 0) || (_a.hi >= 9007199254740992) return false;
		return (_b.lo == _b.hi) && (_b.whole) && (_b.lo >= 1) && (_b.lo <= 2147483648);
	};
}
