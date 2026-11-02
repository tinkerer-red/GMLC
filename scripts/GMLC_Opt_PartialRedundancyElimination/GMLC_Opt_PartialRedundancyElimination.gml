#region jsDoc
/// @func    GMLC_Opt_PartialRedundancyElimination()
/// @desc    The `partial-redundancy-elimination` optimizer pass: a pure built-in call that one branch of an `if`
///          computes and the statement right after the `if` computes again is computed once on each way in and read
///          from a temporary. `if (_a) { _x = lengthdir_x(_r, _d); } _y = lengthdir_x(_r, _d) * 2;` computes the call
///          at the end of an added `else` instead of in the statement after, and the `_a` branch keeps its result.
/// @returns {Struct.GMLC_Opt_PartialRedundancyElimination}
#endregion
function GMLC_Opt_PartialRedundancyElimination() : GMLC_OptimizerPass("partial-redundancy-elimination") constructor {
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with the partially redundant calls shared, or undefined when none is. A function with a
	///          `break` or `continue` inside a `try` is left alone: the loop kinds disagree on what those do.
	/// @self    GMLC_Opt_PartialRedundancyElimination
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (__gmlc_opt_has_try_jump(_node, true)) return undefined;
		var _state = { optimizer: _cx.optimizer, cx: _cx, root: _node, reads: {}, writes: {}, params: __gmlc_opt_function_param_names(_node) };
		return __gmlc_opt_rewritten_lists(_node, _state, true, method(self, __list));
	};
	#endregion

	#region Sharing
	#region jsDoc
	/// @func    __list(_body, _state)
	/// @desc    Shares the calls of each `if` and the statement after it in one list, first to last.
	/// @self    GMLC_Opt_PartialRedundancyElimination
	/// @param   {Array<Struct.ASTNode>} _body  : The statements
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list, undefined when nothing changed
	#endregion
	static __list = function(_body, _state) {
		var _list = _body;
		var _changed = false;
		var _i = 0; repeat (array_length(_body) - 1) {
			var _hit = __diamond(_list, _i, _state);
			if (_hit != undefined) {
				if (!_changed) {
					_list = variable_clone(_body, 0);
					_changed = true;
				}
				_list[_i] = _hit.first;
				_list[_i + 1] = _hit.second;
				_state.cx.stats[$ "shared"]++;
			}
		_i++}
		return _changed ? _list : undefined;
	};

	#region jsDoc
	/// @func    __diamond(_list, _i, _state)
	/// @desc    Shares one call between the `if` at an index and the statement after it: one branch computes it before
	///          the join, the statement after the join computes it again, so the way without it computes it last and
	///          the later statement reads a temporary.
	/// @self    GMLC_Opt_PartialRedundancyElimination
	/// @param   {Array<Struct.ASTNode>} _list  : The statements
	/// @param   {Real}                  _i     : The place of the `if`
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Struct|Undefined} {first, second}: the statements that take the place of the two
	#endregion
	static __diamond = function(_list, _i, _state) {
		var _first = _list[_i];
		var _second = _list[_i + 1];
		if (_first.kind != __GMLC_NodeKind_If) return undefined;
		if (_second.kind != __GMLC_NodeKind_ExprStmt) && (_second.kind != __GMLC_NodeKind_VarDeclList) return undefined;
		if (_first.consequent.kind != __GMLC_NodeKind_Block) return undefined;
		if (_first.alternate != undefined) && (_first.alternate.kind != __GMLC_NodeKind_Block) return undefined;
		var _optimizer = _state.optimizer;
		if (_optimizer.__containsNoOp(_first)) || (_optimizer.__containsNoOp(_second)) return undefined;

		var _found = [];
		__collect(_second, _found);
		var _c = 0; repeat (array_length(_found)) {
			var _call = _found[_c];
			if (__eligible(_call)) {
				var _hit = __share(_list, _i, _call, _state);
				if (_hit != undefined) return _hit;
			}
		_c++}
		return undefined;
	};

	#region jsDoc
	/// @func    __share(_list, _i, _call, _state)
	/// @desc    Shares one call between an `if` and the statement after it, when one branch computes it as part of a
	///          statement of its own list, nothing changes its locals from there to the end of the branch, and the
	///          other way in has an end to compute it at.
	/// @self    GMLC_Opt_PartialRedundancyElimination
	/// @param   {Array<Struct.ASTNode>} _list  : The statements
	/// @param   {Real}                  _i     : The place of the `if`
	/// @param   {Struct.ASTNode}        _call  : The call
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Struct|Undefined} {first, second}
	#endregion
	static __share = function(_list, _i, _call, _state) {
		var _first = _list[_i];
		var _second = _list[_i + 1];
		var _optimizer = _state.optimizer;
		var _names = [];
		__gmlc_opt_collect_local_names(_call, _names);
		var _n = 0; repeat (array_length(_names)) {
			if (__gmlc_opt_writes(_second, _names[_n])) return undefined;
		_n++}

		var _then_at = __computes(_first.consequent, _call, _names, _optimizer);
		var _else_at = (_first.alternate == undefined) ? -1 : __computes(_first.alternate, _call, _names, _optimizer);
		var _has_then = (_then_at >= 0);
		if (_has_then == (_else_at >= 0)) return undefined;

		var _computing = _has_then ? _first.consequent : _first.alternate;
		var _missing = _has_then ? _first.alternate : _first.consequent;
		var _at = _has_then ? _then_at : _else_at;
		if (__gmlc_opt_terminates(_computing)) return undefined;
		if (_missing != undefined) && (__gmlc_opt_terminates(_missing)) return undefined;

		var _name = _state.cx.optimizer.newTemporary(_state.cx);
		var _before = __gmlc_opt_span_point(_computing.body[_at].span);
		var _after = __gmlc_opt_span_point(_second.span);

		// the computing branch: the call is stored before its statement, which reads the temporary
		var _body = variable_clone(_computing.body, 0);
		var _statement = _body[_at];
		_body[_at] = __swap(_statement, _call, _name) ?? _statement;
		var _store_first = _has_then;
		array_insert(_body, _at, __store(_call, _name, _before, _store_first));
		var _new_computing = __gmlc_opt_rebuild_children(_computing, [{ key: "body", index: undefined, node: _body }]);

		// the other way in: the call is computed at its end
		var _new_missing;
		if (_missing == undefined) {
			_new_missing = new ASTBlock(_after, [__store(_call, _name, _after, false)]);
		}
		else {
			var _tail = variable_clone(_missing.body, 0);
			array_push(_tail, __store(_call, _name, _after, !_has_then));
			_new_missing = __gmlc_opt_rebuild_children(_missing, [{ key: "body", index: undefined, node: _tail }]);
		}

		var _edits = [];
		array_push(_edits, { key: (_has_then ? "consequent" : "alternate"), index: undefined, node: _new_computing });
		array_push(_edits, { key: (_has_then ? "alternate" : "consequent"), index: undefined, node: _new_missing });
		return { first: __gmlc_opt_rebuild_children(_first, _edits), second: __swap(_second, _call, _name) ?? _second };
	};

	#region jsDoc
	/// @func    __computes(_block, _call, _names, _optimizer)
	/// @desc    Where a branch computes a call as part of one of its own statements and keeps its locals until the
	///          end of the branch.
	/// @self    GMLC_Opt_PartialRedundancyElimination
	/// @param   {Struct.ASTNode} _block     : The branch
	/// @param   {Struct.ASTNode} _call      : The call
	/// @param   {Array<String>}  _names     : The locals the call reads
	/// @param   {Struct}         _optimizer : The optimizer
	/// @returns {Real} The place of the statement, -1 when there is none
	#endregion
	static __computes = function(_block, _call, _names, _optimizer) {
		var _body = _block.body;
		var _count = array_length(_body);
		var _p = 0; repeat (_count) {
			var _stmt = _body[_p];
			if (_stmt.kind == __GMLC_NodeKind_ExprStmt) || (_stmt.kind == __GMLC_NodeKind_VarDeclList) {
				var _found = [];
				__collect(_stmt, _found);
				var _f = 0; repeat (array_length(_found)) {
					if (__gmlc_opt_same(_found[_f], _call)) {
						var _k = _p; repeat (_count - _p) {
							if (_optimizer.__containsNoOp(_body[_k])) return -1;
							var _n = 0; repeat (array_length(_names)) {
								if (__gmlc_opt_writes(_body[_k], _names[_n])) return -1;
							_n++}
						_k++}
						return _p;
					}
				_f++}
			}
		_p++}
		return -1;
	};

	#region jsDoc
	/// @func    __store(_call, _name, _span, _declare)
	/// @desc    The statement that keeps a copy of the call in the temporary: `var t = call;` where the temporary
	///          first appears in the text, `t = call;` after.
	/// @self    GMLC_Opt_PartialRedundancyElimination
	/// @param   {Struct.ASTNode}   _call    : The call
	/// @param   {String}           _name    : The temporary
	/// @param   {Struct.GMLC_Span} _span    : The span
	/// @param   {Bool}             _declare : Whether this statement declares the temporary
	/// @returns {Struct.ASTNode}
	#endregion
	static __store = function(_call, _name, _span, _declare) {
		var _copy = __gmlc_opt_clone(_call);
		__gmlc_opt_retag_span(_copy, _span);
		if (_declare) return __gmlc_opt_var(_name, _copy, _span);
		return new ASTExprStmt(_span, new ASTAssign(_span, "=", __gmlc_opt_local(_name, _span), _copy));
	};

	#region jsDoc
	/// @func    __swap(_node, _call, _name)
	/// @desc    A node with every copy of a call replaced by a read of the temporary, nested functions left out.
	/// @self    GMLC_Opt_PartialRedundancyElimination
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct.ASTNode} _call : The call
	/// @param   {String}         _name : The temporary
	/// @returns {Struct.ASTNode|Undefined} The new node, undefined when it holds no copy
	#endregion
	static __swap = function(_node, _call, _name) {
		if (_node.kind == __GMLC_NodeKind_Call) && (__gmlc_opt_same(_node, _call)) return __gmlc_opt_local(_name, _node.span);
		if (__gmlc_opt_is_function(_node)) return undefined;
		var _slots = _node.childSlots();
		var _edits = [];
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new = __swap(_slot.node, _call, _name);
			if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
		_i++}
		return (array_length(_edits) == 0) ? undefined : __gmlc_opt_rebuild_children(_node, _edits);
	};

	#region jsDoc
	/// @func    __collect(_node, _out)
	/// @desc    Collects the calls a statement always evaluates, outermost first: not those on the right of `&&`, `||`
	///          and `??`, nor in the branches of `?:`.
	/// @self    GMLC_Opt_PartialRedundancyElimination
	/// @param   {Struct.ASTNode}        _node : The node
	/// @param   {Array<Struct.ASTNode>} _out  : Gets the calls
	#endregion
	static __collect = function(_node, _out) {
		switch (_node.kind) {
			case __GMLC_NodeKind_ExprStmt: __collect(_node.expression, _out); break;
			case __GMLC_NodeKind_VarDeclList: {
				var _i = 0; repeat (array_length(_node.declarations)) {
					if (_node.declarations[_i].init != undefined) __collect(_node.declarations[_i].init, _out);
				_i++}
			break;}
			case __GMLC_NodeKind_Assign: {
				if (_node.target.kind == __GMLC_NodeKind_Index) __collect(_node.target, _out);
				__collect(_node.value, _out);
			break;}
			case __GMLC_NodeKind_Binary:
			case __GMLC_NodeKind_Unary:
			case __GMLC_NodeKind_Index:
			case __GMLC_NodeKind_ArrayLiteral:
			case __GMLC_NodeKind_MethodCall: {
				var _child_fields = _node.childFields;
				var _field_index = 0; repeat (array_length(_child_fields)) {
					var _child_value = _node[$ _child_fields[_field_index]];
					var _child_many = is_array(_child_value);
					var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
						var _child = _child_many ? _child_value[_i] : _child_value;
						if (_child != undefined) {
							__collect(_child, _out);
						}
					_i++}
				_field_index++}
			break;}
			case __GMLC_NodeKind_Call: {
				array_push(_out, _node);
				var _i = 0; repeat (array_length(_node.args)) {
					__collect(_node.args[_i], _out);
				_i++}
			break;}
			case __GMLC_NodeKind_Logical:
			case __GMLC_NodeKind_Nullish: __collect(_node.left, _out); break;
			case __GMLC_NodeKind_Conditional: __collect(_node.test, _out); break;
		}
	};

	#region jsDoc
	/// @func    __eligible(_node)
	/// @desc    Whether a call is worth sharing and safe to compute somewhere else: a pure built-in that cannot throw,
	///          allocate or differ between runs, of literals, locals, built-in constants, enum names and such calls.
	/// @self    GMLC_Opt_PartialRedundancyElimination
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __eligible = function(_node) {
		if (_node.origin != undefined) && (_node.origin.config != undefined) return false;
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: return true;
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				return (_symbol != undefined) && ((_symbol.kind == "Local") || (_symbol.kind == "BuiltinConstant") || (_symbol.kind == "Enum"));
			}
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) return false;
				var _effects = __GmlcDataEffects();
				var _entry = _effects[$ _name];
				if (_entry == undefined) || (_entry.class != "pure") || (_entry.may_throw) || (_entry.allocates) || (_entry.nondeterministic) return false;
				if (!__gmlc_opt_args_accepted(_name, _node.args, __gmlc_opt_value_type)) return false;
				var _i = 0; repeat (array_length(_node.args)) {
					if (!__eligible(_node.args[_i])) return false;
				_i++}
				return true;
			}
		}
		return false;
	};


	#endregion

	#region Facts about locals
	#endregion
}
