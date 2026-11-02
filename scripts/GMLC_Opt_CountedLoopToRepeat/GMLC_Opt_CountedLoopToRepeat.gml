#region jsDoc
/// @func    GMLC_Opt_CountedLoopToRepeat()
/// @desc    `counted-loop-to-repeat`: a `for` that counts from 0 up to a whole-number limit with a counter nothing
///          else reads becomes a `repeat`. `for (var _i = 0; _i < _n; _i++) { step(); }` becomes
///          `repeat (_n) { step(); }`. The limit is a whole literal or a local that only holds whole numbers and is
///          not written in the loop, so `repeat` counts the same trips; the counter must have no later reader.
/// @returns {Struct.GMLC_Opt_CountedLoopToRepeat}
#endregion
function GMLC_Opt_CountedLoopToRepeat() : GMLC_OptimizerPass("counted-loop-to-repeat") constructor {
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    A copy of the function with its counted loops turned into `repeat` loops, or undefined when there is
	///          none.
	/// @self    GMLC_Opt_CountedLoopToRepeat
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
	/// @desc    The `repeat` that takes the place of a counted `for` loop, or undefined when the loop does not
	///          qualify. Without `_st.apply` an empty array says it qualifies.
	/// @self    GMLC_Opt_CountedLoopToRepeat
	/// @param   {Struct.ASTNode} _loop : The loop
	/// @param   {Struct}         _st   : The walk state
	/// @param   {Array<Struct.ASTNode>} _body : The statement list the loop is in
	/// @param   {Real}           _i    : The loop's place in it
	/// @returns {Array<Struct.ASTNode>|Undefined}
	#endregion
	static __rewrite = function(_loop, _st, _body, _i) {
		if (_loop.kind != __GMLC_NodeKind_For) || (_st.cx.epsilon_set) return undefined;
		var _name = __counter(_loop);
		if (_name == undefined) return undefined;
		var _limit = _loop.test.right;
		if (__gmlc_opt_count_mentions(_limit, _name) != 0) || (__gmlc_opt_count_mentions(_loop.body, _name) != 0) return undefined;
		if (_limit.kind == __GMLC_NodeKind_Literal) {
			if (_limit.ty != "real") || (!__gmlc_opt_whole_text(_limit.lexeme)) return undefined;
		}
		else if (__gmlc_opt_is_local(_limit)) {
			if (_st.kinds == undefined) _st.kinds = __kinds(_st.root, _st.cx);
			if ((_st.kinds[$ _limit.name] ?? 0) != 2) || (__gmlc_opt_writes(_loop.body, _limit.name)) return undefined;
		}
		else {
			return undefined;
		}
		if (__gmlc_opt_live_refs(_st.root, _name) != 0) || (_st.cx.optimizer.__containsNoOp(_loop)) return undefined;
		if (!_st.apply) return [];
		_st.cx.stats[$ "converted"]++;
		return [new ASTRepeat(_loop.span, _limit, _loop.body)];
	};

	#region jsDoc
	/// @func    __counter(_loop)
	/// @desc    The counter of a `for` loop written `for (var i = 0; i < limit; i++)` (or `i += 1`, or with `i = 0`
	///          in place of the declaration), or undefined for any other loop.
	/// @self    GMLC_Opt_CountedLoopToRepeat
	/// @param   {Struct.ASTNode} _loop : The loop
	/// @returns {String|Undefined}
	#endregion
	static __counter = function(_loop) {
		var _header = __gmlc_opt_counted_header(_loop);
		if (_header == undefined) || (_header.step != 1) || (_header.cmp != "<") return undefined;
		var _start = _header.start;
		if (_start.kind != __GMLC_NodeKind_Literal) || (_start.ty != "real") || (_start.lexeme != "0") return undefined;
		return _header.name;
	};
	#endregion

	#region Kinds
	#region jsDoc
	/// @func    __kinds(_root, _cx)
	/// @desc    What each local of a function holds, from every write to it: 2 when only whole numbers, 1 when only
	///          numbers and booleans, 0 otherwise. Parameters and catch variables are 0.
	/// @self    GMLC_Opt_CountedLoopToRepeat
	/// @param   {Struct.ASTNode} _root : The function, or the Script
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct} Local name to 0, 1 or 2
	#endregion
	static __kinds = function(_root, _cx) {
		var _writes = {};
		var _params = _root[$ "params"];
		if (_params != undefined) {
			var _p = 0; repeat (array_length(_params)) {
				var _flagged = __gmlc_opt_writes_record(_writes, _params[_p].target.name);
				_flagged.bad = true;
			_p++}
		}
		__gmlc_opt_collect_writes(_root, _writes, true);
		var _names = struct_get_names(_writes);
		var _kinds = {};
		var _n = 0; repeat (array_length(_names)) {
			_kinds[$ _names[_n]] = _writes[$ _names[_n]].bad ? 0 : 2;
		_n++}
		var _changed = true;
		while (_changed) {
			_changed = false;
			var _m = 0; repeat (array_length(_names)) {
				var _entry = _writes[$ _names[_m]];
				var _level = _kinds[$ _names[_m]];
				var _v = 0; repeat (array_length(_entry.values)) {
					var _write = _entry.values[_v];
					var _l = __level(_write.value, _kinds, _cx);
					if (_write.op == "/=") || (_write.op == "&=") || (_write.op == "|=") || (_write.op == "^=") _l = min(_l, 1);
					_level = min(_level, _l);
				_v++}
				if (_level != _kinds[$ _names[_m]]) {
					_kinds[$ _names[_m]] = _level;
					_changed = true;
				}
			_m++}
		}
		return _kinds;
	};

	#region jsDoc
	/// @func    __level(_node, _kinds, _cx)
	/// @desc    What an expression holds when it finishes: 2 a whole number, 1 a number or boolean, 0 anything.
	/// @self    GMLC_Opt_CountedLoopToRepeat
	/// @param   {Struct.ASTNode} _node  : The expression
	/// @param   {Struct}         _kinds : Local name to 0, 1 or 2
	/// @param   {Struct}         _cx    : The pass context
	/// @returns {Real}
	#endregion
	static __level = function(_node, _kinds, _cx) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: {
				if (_node.ty == "real") return __gmlc_opt_whole_text(_node.lexeme) ? 2 : 1;
				return ((_node.ty == "int64") || (_node.ty == "bool")) ? 1 : 0;
			}
			case __GMLC_NodeKind_Identifier: return __gmlc_opt_is_local(_node) ? (_kinds[$ _node.name] ?? 0) : max(0, __gmlc_opt_constant_level(_node, _cx));
			case __GMLC_NodeKind_Unary: {
				if (_node.op == "-") || (_node.op == "+") return __level(_node[$ "argument"], _kinds, _cx);
				return ((_node.op == "!") || (_node.op == "~")) ? 1 : 0;
			}
			case __GMLC_NodeKind_Binary: {
				var _l = __level(_node.left, _kinds, _cx);
				var _r = __level(_node.right, _kinds, _cx);
				switch (_node.op) {
					case "+": case "-": case "*": case "div": case "mod": return min(_l, _r);
					case "==": case "!=": case "<": case "<=": case ">": case ">=": return 1;
				}
				return (min(_l, _r) >= 1) ? 1 : 0;
			}
			case __GMLC_NodeKind_Logical: return 1;
			case __GMLC_NodeKind_Conditional: return min(__level(_node.consequent, _kinds, _cx), __level(_node.alternate, _kinds, _cx));
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				switch (_name) {
					case "array_length": case "string_length": case "floor": case "ceil": case "round": case "sign":
					case "instance_number": case "irandom": case "irandom_range":
					return 2;
					case "abs": case "min": case "max": {
						var _lowest = (array_length(_node.args) > 0) ? 2 : 0;
						var _a = 0; repeat (array_length(_node.args)) {
							_lowest = min(_lowest, __level(_node.args[_a], _kinds, _cx));
						_a++}
						return _lowest;
					}
				}
				return 0;
			}
		}
		return 0;
	};
	
	#endregion

}
