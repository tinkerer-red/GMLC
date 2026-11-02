#region jsDoc
/// @func    GMLC_Opt_JumpThreading()
/// @desc    The `jump-threading` optimizer pass: a flag set in one `if` and tested by the next goes straight to the
///          code it selects, and a second test that repeats the first one joins its branch. `if (_c) { a(); _f = true; }
///          if (_f) { b(); }` with `_f = false` before becomes `if (_c) { a(); b(); }`; `if (_t) { a(); } if (_t && _u)
///          { b(); }` becomes `if (_t) { a(); if (_u) { b(); } }`.
/// @returns {Struct.GMLC_Opt_JumpThreading}
#endregion
function GMLC_Opt_JumpThreading() : GMLC_OptimizerPass("jump-threading") constructor {
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with the threadable tests joined, or undefined when none is.
	/// @self    GMLC_Opt_JumpThreading
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _state = { optimizer: _cx.optimizer, cx: _cx, root: _node, reads: {}, writes: {}, params: __gmlc_opt_function_param_names(_node), epsilon: _cx.epsilon_set };
		return __gmlc_opt_rewritten_lists(_node, _state, true, method(self, __list));
	};
	#endregion

	#region Threading
	#region jsDoc
	/// @func    __list(_body, _state)
	/// @desc    Threads the pairs of neighboring `if` statements of one list, first to last; a joined pair leaves one
	///          statement that is tried with its next neighbor.
	/// @self    GMLC_Opt_JumpThreading
	/// @param   {Array<Struct.ASTNode>} _body  : The statements
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list, undefined when nothing changed
	#endregion
	static __list = function(_body, _state) {
		var _list = _body;
		var _changed = false;
		var _j = 0;
		while (_j < array_length(_list) - 1) {
			var _key = "flags_threaded";
			var _new = __flag(_list, _j, _state);
			if (_new == undefined) {
				_key = "tests_joined";
				_new = __sequence(_list, _j, _state);
			}
			if (_new == undefined) {
				_j++;
			}
			else {
				if (!_changed) {
					_list = variable_clone(_body, 0);
					_changed = true;
				}
				_list[_j] = _new;
				array_delete(_list, _j + 1, 1);
				_state.cx.stats[$ _key]++;
			}
		}
		return _changed ? _list : undefined;
	};

	#region jsDoc
	/// @func    __flag(_list, _j, _state)
	/// @desc    Threads `if (c) { ...; f = true; }` followed by `if (f) { ... }` when `f` was false before and these
	///          are the only places it is touched: the second `if` moves to the end of the first one's branch.
	/// @self    GMLC_Opt_JumpThreading
	/// @param   {Array<Struct.ASTNode>} _list  : The statements
	/// @param   {Real}                  _j     : The place of the first `if`
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Struct.ASTNode|Undefined} The `if` that takes the place of both
	#endregion
	static __flag = function(_list, _j, _state) {
		var _first = _list[_j];
		var _second = _list[_j + 1];
		if (_first.kind != __GMLC_NodeKind_If) || (_second.kind != __GMLC_NodeKind_If) return undefined;
		if (!__gmlc_opt_is_local(_second.test)) return undefined;
		var _name = _second.test.name;
		if (_first.consequent.kind != __GMLC_NodeKind_Block) return undefined;
		var _set_body = _first.consequent.body;
		var _count = array_length(_set_body);
		if (_count == 0) return undefined;
		var _set = __flagWrite(_set_body[_count - 1], _name, _state.optimizer);
		if (_set == undefined) return undefined;
		if (__gmlc_opt_count_reads(_state.root, _state.reads, _name) != 1) || (__gmlc_opt_count_writes(_state.root, _state.writes, _name) != 2) || (array_contains(_state.params, _name)) return undefined;
		var _optimizer = _state.optimizer;
		if (_optimizer.__containsNoOp(_first)) || (_optimizer.__containsNoOp(_second)) return undefined;

		// the other write is a statement of this list before the first `if`
		var _start = undefined;
		var _i = 0; repeat (_j) {
			if (_optimizer.__containsNoOp(_list[_i])) {
				_start = undefined;
				break;
			}
			if (__gmlc_opt_writes(_list[_i], _name)) {
				if (_start != undefined) return undefined;
				_start = _i;
			}
		_i++}
		if (_start == undefined) return undefined;
		var _init = __flagWrite(_list[_start], _name, _optimizer);
		if (_init == undefined) || (_init == _set) return undefined;
		var _k = _start + 1; repeat (_j - _start - 1) {
			if (_optimizer.__containsNoOp(_list[_k])) return undefined;
		_k++}

		var _then_tail = __statements(_second.consequent);
		var _else_tail = (_second.alternate == undefined) ? [] : __statements(_second.alternate);
		var _taken = (_set) ? _then_tail : _else_tail;
		var _other = (_set) ? _else_tail : _then_tail;

		var _body = variable_clone(_set_body, 0);
		array_delete(_body, _count - 1, 1);
		_body = array_concat(_body, _taken);
		var _edits = [{ key: "consequent", index: undefined, node: __gmlc_opt_rebuild_children(_first.consequent, [{ key: "body", index: undefined, node: _body }]) }];

		var _rest = (_first.alternate == undefined) ? [] : __statements(_first.alternate);
		_rest = array_concat(_rest, _other);
		if (array_length(_rest) == 0) {
			_edits[1] = { key: "alternate", index: undefined, node: undefined };
		}
		else if (_first.alternate != undefined) && (_first.alternate.kind == __GMLC_NodeKind_Block) {
			_edits[1] = { key: "alternate", index: undefined, node: __gmlc_opt_rebuild_children(_first.alternate, [{ key: "body", index: undefined, node: _rest }]) };
		}
		else {
			_edits[1] = { key: "alternate", index: undefined, node: new ASTBlock(_first.span, _rest) };
		}
		return __gmlc_opt_rebuild_children(_first, _edits);
	};

	#region jsDoc
	/// @func    __flagWrite(_stmt, _name, _optimizer)
	/// @desc    Whether a statement stores a bool constant in a local, `var f = true;` or `f = true;`, and which.
	///          `true` and `false` written in source are built-in constants, not literals.
	/// @self    GMLC_Opt_JumpThreading
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @param   {String}         _name : The local
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _optimizer : The optimizer
	/// @returns {Bool|Undefined} The stored value, undefined for any other statement
	#endregion
	static __flagWrite = function(_stmt, _name, _optimizer) {
		var _target;
		var _value;
		if (_stmt.kind == __GMLC_NodeKind_VarDeclList) {
			if (array_length(_stmt.declarations) != 1) return undefined;
			_target = _stmt.declarations[0].target;
			_value = _stmt.declarations[0].init;
		}
		else if (_stmt.kind == __GMLC_NodeKind_ExprStmt) && (_stmt.expression.kind == __GMLC_NodeKind_Assign) && (_stmt.expression.op == "=") {
			_target = _stmt.expression.target;
			_value = _stmt.expression.value;
		}
		else {
			return undefined;
		}
		if (_value == undefined) return undefined;
		var _known = _optimizer.__constantValue(_value);
		if (!_known[0]) || (!is_bool(_known[1])) return undefined;
		if (!__gmlc_opt_is_local(_target)) || (_target.name != _name) return undefined;
		return _known[1] ? true : false;
	};

	#region jsDoc
	/// @func    __statements(_node)
	/// @desc    The statements of a branch: those of a block, or the one statement.
	/// @self    GMLC_Opt_JumpThreading
	/// @param   {Struct.ASTNode} _node : The branch
	/// @returns {Array<Struct.ASTNode>}
	#endregion
	static __statements = function(_node) {
		return (_node.kind == __GMLC_NodeKind_Block) ? _node.body : [_node];
	};

	#region jsDoc
	/// @func    __sequence(_list, _j, _state)
	/// @desc    Threads `if (t) { A }` followed by `if (t && u) { B }` or `if (t) { B }` into one test: `t` still holds
	///          after `A`, and fails on the other path, so the second `if` joins the end of `A`.
	/// @self    GMLC_Opt_JumpThreading
	/// @param   {Array<Struct.ASTNode>} _list  : The statements
	/// @param   {Real}                  _j     : The place of the first `if`
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Struct.ASTNode|Undefined} The `if` that takes the place of both
	#endregion
	static __sequence = function(_list, _j, _state) {
		var _first = _list[_j];
		var _second = _list[_j + 1];
		if (_first.kind != __GMLC_NodeKind_If) || (_second.kind != __GMLC_NodeKind_If) return undefined;
		if (_second.alternate != undefined) || (_first.consequent.kind != __GMLC_NodeKind_Block) return undefined;
		var _test = _first.test;
		if (_test.kind == __GMLC_NodeKind_Literal) || (!__gmlc_opt_is_stable(_test)) return undefined;
		if (_state.epsilon) && (__gmlc_opt_has_comparison(_test)) return undefined;

		var _rest = undefined;
		if (__gmlc_opt_same(_second.test, _test)) {
			_rest = undefined;
		}
		else if (_second.test.kind == __GMLC_NodeKind_Logical) && (_second.test.op == "&&") && (__gmlc_opt_same(_second.test.left, _test)) {
			_rest = _second.test.right;
		}
		else {
			return undefined;
		}
		var _optimizer = _state.optimizer;
		if (_optimizer.__containsNoOp(_first)) || (_optimizer.__containsNoOp(_second)) return undefined;
		var _names = [];
		__gmlc_opt_collect_local_names(_test, _names);
		var _n = 0; repeat (array_length(_names)) {
			if (__gmlc_opt_writes(_first.consequent, _names[_n])) return undefined;
			if (_first.alternate != undefined) && (__gmlc_opt_writes(_first.alternate, _names[_n])) return undefined;
		_n++}

		var _body = variable_clone(_first.consequent.body, 0);
		if (_rest == undefined) {
			_body = array_concat(_body, __statements(_second.consequent));
		}
		else {
			array_push(_body, new ASTIf(_second.span, _rest, _second.consequent, undefined));
		}
		return __gmlc_opt_rebuild_children(_first, [{ key: "consequent", index: undefined, node: __gmlc_opt_rebuild_children(_first.consequent, [{ key: "body", index: undefined, node: _body }]) }]);
	};

	#endregion

	#region Facts about locals
	#endregion
}
