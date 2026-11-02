#region jsDoc
/// @func    GMLC_Opt_LoopUnswitch()
/// @desc    `loop-unswitch`: an `if` in a loop body whose test cannot change while the loop runs is tested once,
///          and the loop is written once for each outcome. `for (...) { if (_fast) { a(); } b(); }` becomes
///          `if (_fast) { for (...) { a(); b(); } } else { for (...) { b(); } }`. The test is built from numeric
///          locals that hold a value and are not written in the loop, so it cannot throw, and the loop is no larger
///          than `max_nodes` nodes.
/// @returns {Struct.GMLC_Opt_LoopUnswitch}
#endregion
function GMLC_Opt_LoopUnswitch() : GMLC_OptimizerPass("loop-unswitch") constructor {
	#region Config
	static max_nodes = 200;
	#endregion

	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    A copy of the function with its loops unswitched, or undefined when there is none.
	/// @self    GMLC_Opt_LoopUnswitch
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _st = { cx: _cx, apply: false, root: _node, defs: [], kinds: undefined };
		if (!__gmlc_opt_walk_statement_lists(_node, _st, true, method(self, __rewrite))) return undefined;
		var _copy = __gmlc_opt_clone(_node);
		_st.apply = true;
		array_resize(_st.defs, 0);
		__gmlc_opt_walk_statement_lists(_copy, _st, true, method(self, __rewrite));
		return _copy;
	};
	#endregion

	#region Loops
	#region jsDoc
	/// @func    __rewrite(_loop, _st, _body, _i)
	/// @desc    The `if` that takes the place of a loop with an invariant `if` in its body, holding the loop once for
	///          each outcome, or undefined when the loop does not qualify. Without `_st.apply` an array says it
	///          qualifies.
	/// @self    GMLC_Opt_LoopUnswitch
	/// @param   {Struct.ASTNode}        _loop : The loop
	/// @param   {Struct}                _st   : The walk state
	/// @param   {Array<Struct.ASTNode>} _body : The statement list the loop is in
	/// @param   {Real}                  _i    : The loop's place in it
	/// @returns {Array<Struct.ASTNode>|Undefined}
	#endregion
	static __rewrite = function(_loop, _st, _body, _i) {
		var _kind = _loop.kind;
		if (_kind != __GMLC_NodeKind_For) && (_kind != __GMLC_NodeKind_While) && (_kind != __GMLC_NodeKind_Repeat) return undefined;
		if (_st.kinds == undefined) _st.kinds = __gmlc_opt_local_kinds(_st.root, _st.cx);
		var _stmts = _loop.body.body;
		var _k = -1;
		var _s = 0; repeat (array_length(_stmts)) {
			if (_stmts[_s].kind == __GMLC_NodeKind_If) && (__safe(_stmts[_s].test, _st, _loop) > 0) {
				_k = _s;
				break;
			}
		_s++}
		if (_k < 0) return undefined;
		if (__count(_loop) > max_nodes) || (__gmlc_opt_has_function(_loop)) || (_st.cx.optimizer.__containsNoOp(_loop)) return undefined;
		if (!_st.apply) return [];
		_st.cx.stats[$ "unswitched"]++;
		var _span = _loop.span;
		var _other = __gmlc_opt_clone(_loop);
		var _if = _loop.body.body[_k];
		_loop.body.body[_k] = _if.consequent;
		var _else = _other.body.body[_k].alternate;
		if (_else != undefined) {
			_other.body.body[_k] = _else;
		}
		else {
			array_delete(_other.body.body, _k, 1);
		}
		return [new ASTIf(_span, _if.test, new ASTBlock(_span, [_loop]), new ASTBlock(_span, [_other]))];
	};

	#region jsDoc
	/// @func    __safe(_node, _st, _loop)
	/// @desc    How many locals an expression reads when nothing in it can throw and nothing in it changes while a
	///          loop runs: literals, numeric locals that hold a value before the loop and are not written in it,
	///          and arithmetic, comparisons and logic of those. -1 for any other expression.
	/// @self    GMLC_Opt_LoopUnswitch
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _st   : The walk state
	/// @param   {Struct.ASTNode} _loop : The loop
	/// @returns {Real}
	#endregion
	static __safe = function(_node, _st, _loop) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: return ((_node.ty == "real") || (_node.ty == "int64") || (_node.ty == "bool")) ? 0 : -1;
			case __GMLC_NodeKind_Identifier: {
				if (!__gmlc_opt_is_local(_node)) return (__gmlc_opt_constant_level(_node, _st.cx) == 1) ? 0 : -1;
				if ((_st.kinds[$ _node.name] ?? 0) < 1) || (!array_contains(_st.defs, _node.name)) || (__gmlc_opt_writes(_loop, _node.name)) return -1;
				return 1;
			}
			case __GMLC_NodeKind_Unary: return __safe(_node[$ "argument"], _st, _loop);
			case __GMLC_NodeKind_Binary: {
				switch (_node.op) {
					case "+": case "-": case "*": case "/": case "==": case "!=": case "<": case "<=": case ">": case ">=": {
						var _left = __safe(_node.left, _st, _loop);
						var _right = __safe(_node.right, _st, _loop);
						return ((_left < 0) || (_right < 0)) ? -1 : _left + _right;
					}
				}
				return -1;
			}
			case __GMLC_NodeKind_Logical: {
				var _first = __safe(_node.left, _st, _loop);
				var _second = __safe(_node.right, _st, _loop);
				return ((_first < 0) || (_second < 0)) ? -1 : _first + _second;
			}
		}
		return -1;
	};

	#region jsDoc
	/// @func    __count(_node)
	/// @desc    How many nodes there are under a node, itself included.
	/// @self    GMLC_Opt_LoopUnswitch
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Real}
	#endregion
	static __count = function(_node) {
		var _n = 1;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					_n += __count(_child);
				}
			_i++}
		_field_index++}
		return _n;
	};
	#endregion

}
