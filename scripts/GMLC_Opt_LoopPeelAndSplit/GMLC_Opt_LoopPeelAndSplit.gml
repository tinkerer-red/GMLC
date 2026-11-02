#region jsDoc
/// @func    GMLC_Opt_LoopPeelAndSplit()
/// @desc    `loop-peel-and-split`: a `for` loop whose only statement tells its first pass from the others by the
///          counter (`if (_i == 0) {...} else {...}`) has that pass written out before the loop, so the test is gone
///          from every other pass. `for (var _i = 0; _i < _n; _i++) { if (_i == 0) { a(); } else { b(_i); } }`
///          becomes `if (0 < _n) { a(); } for (var _i = 1; _i < _n; _i++) { b(_i); }`. The counter must have no
///          later reader.
/// @returns {Struct.GMLC_Opt_LoopPeelAndSplit}
#endregion
function GMLC_Opt_LoopPeelAndSplit() : GMLC_OptimizerPass("loop-peel-and-split") constructor {
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    A copy of the function with its first passes peeled, or undefined when there is none.
	/// @self    GMLC_Opt_LoopPeelAndSplit
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
	/// @desc    The guarded first pass and the loop that follows it, or undefined when the loop does not qualify.
	///          Without `_st.apply` an array says it qualifies.
	/// @self    GMLC_Opt_LoopPeelAndSplit
	/// @param   {Struct.ASTNode}        _loop : The loop
	/// @param   {Struct}                _st   : The walk state
	/// @param   {Array<Struct.ASTNode>} _body : The statement list the loop is in
	/// @param   {Real}                  _i    : The loop's place in it
	/// @returns {Array<Struct.ASTNode>|Undefined}
	#endregion
	static __rewrite = function(_loop, _st, _body, _i) {
		if (_loop.kind != __GMLC_NodeKind_For) return undefined;
		var _counter = __counter(_loop);
		if (_counter == undefined) return undefined;
		var _name = _counter.name;
		var _limit = _loop.test.right;
		if (__gmlc_opt_count_mentions(_limit, _name) != 0) || (__gmlc_opt_has_function(_limit)) return undefined;
		var _stmts = _loop.body.body;
		if (array_length(_stmts) != 1) || (_stmts[0].kind != __GMLC_NodeKind_If) return undefined;
		var _if = _stmts[0];
		if (_if.alternate == undefined) return undefined;
		var _first = __firstBranch(_if, _name, _counter.start);
		if (_first == undefined) return undefined;
		var _peeled = _first ? _if.consequent : _if.alternate;
		var _rest = _first ? _if.alternate : _if.consequent;
		if (__gmlc_opt_has_function(_peeled)) || (__gmlc_opt_writes(_peeled, _name)) || (__escapes(_peeled)) return undefined;
		if (__gmlc_opt_live_refs(_st.root, _name) != 0) || (_st.cx.optimizer.__containsNoOp(_loop)) return undefined;
		var _span = _loop.span;
		var _start = real(_counter.start);
		var _literal = _st.cx.optimizer.__literal(_start, _span);
		if (_literal == undefined) || (_st.cx.optimizer.__literal(_start + 1, _span) == undefined) return undefined;
		if (!_st.apply) return [];
		_st.cx.stats[$ "peeled"]++;
		var _guard = new ASTIf(_span, new ASTBinary(_span, _loop.test.op, _literal, __gmlc_opt_clone(_limit)), _peeled, undefined);
		__substitute(_peeled, _name, _start, _st.cx);
		var _init = _loop.init;
		if (_init.kind == __GMLC_NodeKind_VarDeclList) {
			_init.declarations[0].init = _st.cx.optimizer.__literal(_start + 1, _init.declarations[0].init.span);
		}
		else {
			_init.expression.value = _st.cx.optimizer.__literal(_start + 1, _init.expression.value.span);
		}
		_loop.body = _rest;
		return [_guard, _loop];
	};

	#region jsDoc
	/// @func    __counter(_loop)
	/// @desc    The counter and the first value of a `for` loop written `for (var i = 3; i < limit; i++)` (`<=` or
	///          `+= 1` as well, or `i = 3` in place of the declaration), or undefined for any other loop.
	/// @self    GMLC_Opt_LoopPeelAndSplit
	/// @param   {Struct.ASTNode} _loop : The loop
	/// @returns {Struct|Undefined} {name, start} with the start as written
	#endregion
	static __counter = function(_loop) {
		var _header = __gmlc_opt_counted_header(_loop);
		if (_header == undefined) || (_header.step != 1) || ((_header.cmp != "<") && (_header.cmp != "<=")) return undefined;
		var _start = _header.start;
		if (_start.kind != __GMLC_NodeKind_Literal) || (_start.ty != "real") || (!__gmlc_opt_whole_text(_start.lexeme)) || (string_length(_start.lexeme) > 9) return undefined;
		return { name: _header.name, start: _start.lexeme };
	};

	#region jsDoc
	/// @func    __firstBranch(_if, _name, _start)
	/// @desc    Which branch of an `if` the first pass takes and no other does: true for the `then` branch when the
	///          test is `i == start` or `i <= start`, false for the `else` branch when it is `i != start` or
	///          `i > start`, undefined for any other test.
	/// @self    GMLC_Opt_LoopPeelAndSplit
	/// @param   {Struct.ASTNode} _if    : The `if`
	/// @param   {String}         _name  : The counter
	/// @param   {String}         _start : The counter's first value as written
	/// @returns {Bool|Undefined}
	#endregion
	static __firstBranch = function(_if, _name, _start) {
		var _test = _if.test;
		if (_test.kind != __GMLC_NodeKind_Binary) || (!__gmlc_opt_is_local(_test.left)) || (_test.left.name != _name) return undefined;
		if (_test.right.kind != __GMLC_NodeKind_Literal) || (_test.right.ty != "real") || (_test.right.lexeme != _start) return undefined;
		switch (_test.op) {
			case "==": case "<=": return true;
			case "!=": case ">": return false;
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __escapes(_node)
	/// @desc    Whether a `break` or `continue` is written anywhere under a node.
	/// @self    GMLC_Opt_LoopPeelAndSplit
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __escapes = function(_node) {
		if (_node.kind == __GMLC_NodeKind_Break) || (_node.kind == __GMLC_NodeKind_Continue) return true;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__escapes(_child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};

	#region jsDoc
	/// @func    __substitute(_node, _name, _value, _cx)
	/// @desc    Puts a number in place of every read of a local under a node.
	/// @self    GMLC_Opt_LoopPeelAndSplit
	/// @param   {Struct.ASTNode} _node  : The node, changed in place
	/// @param   {String}         _name  : The local
	/// @param   {Real}           _value : The number
	/// @param   {Struct}         _cx    : The pass context
	#endregion
	static __substitute = function(_node, _name, _value, _cx) {
		var _slots = _node.childSlots();
		var _s = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_s];
			if (__gmlc_opt_is_local(_slot.node)) && (_slot.node.name == _name) {
				var _literal = _cx.optimizer.__literal(_value, _slot.node.span);
				if (_node.kind == __GMLC_NodeKind_StructEntry) _node.shorthand = false;
				if (_slot.index == undefined) {
					_node[$ _slot.key] = _literal;
				}
				else {
					_node[$ _slot.key][_slot.index] = _literal;
				}
			}
			else {
				__substitute(_slot.node, _name, _value, _cx);
			}
		_s++}
	};
	#endregion

}
