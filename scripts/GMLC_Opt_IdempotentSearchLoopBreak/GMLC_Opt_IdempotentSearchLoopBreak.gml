#region jsDoc
/// @func    GMLC_Opt_IdempotentSearchLoopBreak()
/// @desc    `idempotent-search-loop-break`: a counted `for` loop whose only statement sets flags to constants when a
///          condition holds stops at the first hit, because every later hit sets the same values again.
///          `for (var _i = 0; _i < _n; _i++) { if (_i * _i > _k) { _found = true; } }` gets a `break` after the
///          store. The condition cannot throw, the flags are named nowhere else in the loop, and the counter has no
///          later reader.
/// @returns {Struct.GMLC_Opt_IdempotentSearchLoopBreak}
#endregion
function GMLC_Opt_IdempotentSearchLoopBreak() : GMLC_OptimizerPass("idempotent-search-loop-break") constructor {
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    A copy of the function with a `break` in its search loops, or undefined when there is none.
	/// @self    GMLC_Opt_IdempotentSearchLoopBreak
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
	/// @desc    The loop with a `break` after its stores, or undefined when it does not qualify. Without
	///          `_st.apply` an array says it qualifies.
	/// @self    GMLC_Opt_IdempotentSearchLoopBreak
	/// @param   {Struct.ASTNode}        _loop : The loop
	/// @param   {Struct}                _st   : The walk state
	/// @param   {Array<Struct.ASTNode>} _body : The statement list the loop is in
	/// @param   {Real}                  _i    : The loop's place in it
	/// @returns {Array<Struct.ASTNode>|Undefined}
	#endregion
	static __rewrite = function(_loop, _st, _body, _i) {
		if (_loop.kind != __GMLC_NodeKind_For) return undefined;
		var _name = __counter(_loop);
		if (_name == undefined) return undefined;
		var _limit = _loop.test.right;
		if (!__invariant(_limit, _loop)) return undefined;
		var _stmts = _loop.body.body;
		if (array_length(_stmts) != 1) || (_stmts[0].kind != __GMLC_NodeKind_If) || (_stmts[0].alternate != undefined) return undefined;
		var _if = _stmts[0];
		var _stores = _if.consequent.body;
		if (array_length(_stores) == 0) return undefined;
		var _counts = {};
		var _s = 0; repeat (array_length(_stores)) {
			var _store = _stores[_s];
			if (_store.kind != __GMLC_NodeKind_ExprStmt) || (_store.expression.kind != __GMLC_NodeKind_Assign) return undefined;
			var _assign = _store.expression;
			if (_assign.op != "=") || (!__gmlc_opt_is_local(_assign.target)) || (__gmlc_opt_constant_level(_assign.value, _st.cx) < 0) return undefined;
			var _target = _assign.target.name;
			_counts[$ _target] = (_counts[$ _target] ?? 0) + 1;
		_s++}
		var _targets = struct_get_names(_counts);
		var _t = 0; repeat (array_length(_targets)) {
			if (_targets[_t] == _name) || (__gmlc_opt_count_mentions(_loop, _targets[_t]) != _counts[$ _targets[_t]]) return undefined;
		_t++}
		if (_st.kinds == undefined) _st.kinds = __gmlc_opt_local_kinds(_st.root, _st.cx);
		if (__safe(_if.test, _st, _loop, _name) < 0) return undefined;
		if (__gmlc_opt_live_refs(_st.root, _name) != 0) || (_st.cx.optimizer.__containsNoOp(_loop)) return undefined;
		if (!_st.apply) return [];
		_st.cx.stats[$ "breaks_added"]++;
		array_push(_stores, new ASTBreak(_if.span));
		return [_loop];
	};

	#region jsDoc
	/// @func    __counter(_loop)
	/// @desc    The counter of a `for` loop written `for (var i = 3; i < limit; i++)` (`<=` or `+= 1` as well, or
	///          `i = 3` in place of the declaration), or undefined for any other loop.
	/// @self    GMLC_Opt_IdempotentSearchLoopBreak
	/// @param   {Struct.ASTNode} _loop : The loop
	/// @returns {String|Undefined}
	#endregion
	static __counter = function(_loop) {
		var _header = __gmlc_opt_counted_header(_loop);
		if (_header == undefined) || (_header.step != 1) || ((_header.cmp != "<") && (_header.cmp != "<=")) return undefined;
		var _start = _header.start;
		if (_start.kind != __GMLC_NodeKind_Literal) || (_start.ty != "real") || (!__gmlc_opt_whole_text(_start.lexeme)) return undefined;
		return _header.name;
	};

	#region jsDoc
	/// @func    __invariant(_limit, _loop)
	/// @desc    Whether a loop limit has the same value on every pass: a literal, a local the body does not write,
	///          or the length of such a local. The body holds no call, so nothing else can change an array.
	/// @self    GMLC_Opt_IdempotentSearchLoopBreak
	/// @param   {Struct.ASTNode} _limit : The limit
	/// @param   {Struct.ASTNode} _loop  : The loop
	/// @returns {Bool}
	#endregion
	static __invariant = function(_limit, _loop) {
		if (_limit.kind == __GMLC_NodeKind_Literal) return true;
		if (__gmlc_opt_is_local(_limit)) return !__gmlc_opt_writes(_loop.body, _limit.name);
		if (__gmlc_opt_builtin_call(_limit) == "array_length") && (array_length(_limit.args) == 1) && (__gmlc_opt_is_local(_limit.args[0])) {
			return !__gmlc_opt_writes(_loop.body, _limit.args[0].name);
		}
		return false;
	};

	#region jsDoc
	/// @func    __safe(_node, _st, _loop, _counter)
	/// @desc    How many locals an expression reads when nothing in it can throw: literals, the loop's counter,
	///          numeric locals that hold a value before the loop and are not written in it, and arithmetic,
	///          comparisons and logic of those. -1 for any other expression.
	/// @self    GMLC_Opt_IdempotentSearchLoopBreak
	/// @param   {Struct.ASTNode} _node    : The expression
	/// @param   {Struct}         _st      : The walk state
	/// @param   {Struct.ASTNode} _loop    : The loop
	/// @param   {String}         _counter : The loop's counter
	/// @returns {Real}
	#endregion
	static __safe = function(_node, _st, _loop, _counter) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: return ((_node.ty == "real") || (_node.ty == "int64") || (_node.ty == "bool")) ? 0 : -1;
			case __GMLC_NodeKind_Identifier: {
				if (!__gmlc_opt_is_local(_node)) return (__gmlc_opt_constant_level(_node, _st.cx) == 1) ? 0 : -1;
				if (_node.name == _counter) return 1;
				if ((_st.kinds[$ _node.name] ?? 0) < 1) || (!array_contains(_st.defs, _node.name)) || (__gmlc_opt_writes(_loop, _node.name)) return -1;
				return 1;
			}
			case __GMLC_NodeKind_Unary: return __safe(_node[$ "argument"], _st, _loop, _counter);
			case __GMLC_NodeKind_Binary: {
				switch (_node.op) {
					case "+": case "-": case "*": case "/": case "==": case "!=": case "<": case "<=": case ">": case ">=": {
						var _left = __safe(_node.left, _st, _loop, _counter);
						var _right = __safe(_node.right, _st, _loop, _counter);
						return ((_left < 0) || (_right < 0)) ? -1 : _left + _right;
					}
				}
				return -1;
			}
			case __GMLC_NodeKind_Logical: {
				var _first = __safe(_node.left, _st, _loop, _counter);
				var _second = __safe(_node.right, _st, _loop, _counter);
				return ((_first < 0) || (_second < 0)) ? -1 : _first + _second;
			}
		}
		return -1;
	};
	#endregion

}
