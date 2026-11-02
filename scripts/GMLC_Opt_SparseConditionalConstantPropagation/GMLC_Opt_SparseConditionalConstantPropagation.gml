#region jsDoc
/// @func    GMLC_Opt_SparseConditionalConstantPropagation()
/// @desc    The `sparse-conditional-constant-propagation` optimizer pass: follows the values of the locals through
///          the function together with which branches can run, so a local that only a never-taken branch changes
///          stays constant across a loop, and its reads and tests become literals. `var _m = 0; repeat (_n) { if (_m == 1)
///          { _m = 2; } t += _m; }` reads `0` for `_m`, and the test becomes `false`. Only numbers, bools, short strings and
///          `undefined` held in locals are followed, and only operations that cannot throw are computed.
/// @returns {Struct.GMLC_Opt_SparseConditionalConstantPropagation}
#endregion
function GMLC_Opt_SparseConditionalConstantPropagation() : GMLC_OptimizerPass("sparse-conditional-constant-propagation") constructor {
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with the constants its flow proves written in, or undefined when there is none. A
	///          function with a `break` or `continue` inside a `try` is left alone: the loop kinds disagree on what
	///          those do.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (__gmlc_opt_has_try_jump(_node, true)) || (__gmlc_opt_uses_arguments(_node, true)) return undefined;
		var _ctx = { optimizer: _cx.optimizer, cx: _cx, epsilon: _cx.epsilon_set, stack: [] };
		var _st = { live: true, v: {} };
		switch (_node.kind) {
			case __GMLC_NodeKind_Script: {
				var _body = __list(_node.body, _st, _ctx, true);
				return (_body == undefined) ? undefined : __gmlc_opt_rebuild_children(_node, [{ key: "body", index: undefined, node: _body }]);
			}
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr: {
				var _new = __stmt(_node.body, _st, _ctx, true);
				return (_new == undefined) ? undefined : __gmlc_opt_rebuild_children(_node, [{ key: "body", index: undefined, node: _new }]);
			}
		}
		return undefined;
	};
	#endregion

	#region Statements
	#region jsDoc
	/// @func    __list(_body, _st, _ctx, _rw)
	/// @desc    Follows a statement list in order; the state becomes what holds after it. Statements after one that
	///          never completes are not followed.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Array<Struct.ASTNode>} _body : The statements
	/// @param   {Struct}                _st   : The state before the list, changed
	/// @param   {Struct}                _ctx  : The pass's context
	/// @param   {Bool}                  _rw   : Whether to write the constants in
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list, undefined when nothing changed
	#endregion
	static __list = function(_body, _st, _ctx, _rw) {
		var _list = _body;
		var _changed = false;
		var _optimizer = _ctx.optimizer;
		var _i = 0; repeat (array_length(_body)) {
			if (!_st.live) break;
			var _stmt = _body[_i];
			if (_optimizer.__isNoOp(_stmt)) {
				_st.v = {};
			}
			else {
				var _new = __stmt(_stmt, _st, _ctx, _rw);
				if (_new != undefined) {
					if (!_changed) {
						_list = variable_clone(_body, 0);
						_changed = true;
					}
					_list[_i] = _new;
				}
				if (_optimizer.__containsNoOp(_stmt)) _st.v = {};
			}
		_i++}
		return _changed ? _list : undefined;
	};

	#region jsDoc
	/// @func    __stmt(_node, _st, _ctx, _rw)
	/// @desc    Follows one statement; the state becomes what holds after it, and with _rw the reads of constant
	///          locals and the tests the state decides are replaced.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node : The statement
	/// @param   {Struct}         _st   : The state before the statement, changed
	/// @param   {Struct}         _ctx  : The pass's context
	/// @param   {Bool}           _rw   : Whether to write the constants in
	/// @returns {Struct.ASTNode|Undefined} The new statement, undefined when nothing changed
	#endregion
	static __stmt = function(_node, _st, _ctx, _rw) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Block: {
				var _body = __list(_node.body, _st, _ctx, _rw);
				return (_body == undefined) ? undefined : __gmlc_opt_rebuild_children(_node, [{ key: "body", index: undefined, node: _body }]);
			}
			case __GMLC_NodeKind_ExprStmt: {
				var _new = __head(_node.expression, _st, _ctx, _rw);
				return (_new == undefined) ? undefined : __gmlc_opt_rebuild_children(_node, [{ key: "expression", index: undefined, node: _new }]);
			}
			case __GMLC_NodeKind_VarDeclList: return __declarations(_node, _st, _ctx, _rw);
			case __GMLC_NodeKind_Return:
			case __GMLC_NodeKind_Throw: {
				var _new = (_node.argument == undefined) ? undefined : __head(_node.argument, _st, _ctx, _rw);
				_st.live = false;
				return (_new == undefined) ? undefined : __gmlc_opt_rebuild_children(_node, [{ key: "argument", index: undefined, node: _new }]);
			}
			case __GMLC_NodeKind_Exit: _st.live = false; return undefined;
			case __GMLC_NodeKind_Break: {
				var _frame = __frame(_ctx, false);
				if (_frame != undefined) array_push(_frame.breaks, __copy(_st));
				_st.live = false;
				return undefined;
			}
			case __GMLC_NodeKind_Continue: {
				var _frame = __frame(_ctx, true);
				if (_frame != undefined) array_push(_frame.conts, __copy(_st));
				_st.live = false;
				return undefined;
			}
			case __GMLC_NodeKind_If: return __ifStatement(_node, _st, _ctx, _rw);
			case __GMLC_NodeKind_While:
			case __GMLC_NodeKind_For:
			case __GMLC_NodeKind_Repeat:
			case __GMLC_NodeKind_DoUntil:
			case __GMLC_NodeKind_With: return __loopStatement(_node, _st, _ctx, _rw);
			case __GMLC_NodeKind_Switch: return __switchStatement(_node, _st, _ctx, _rw);
			case __GMLC_NodeKind_Try: return __tryStatement(_node, _st, _ctx, _rw);
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __declarations(_node, _st, _ctx, _rw)
	/// @desc    Follows `var a = 1, b = a;`: each declarator sees the ones before it.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node : The declaration list
	/// @param   {Struct}         _st   : The state, changed
	/// @param   {Struct}         _ctx  : The pass's context
	/// @param   {Bool}           _rw   : Whether to write the constants in
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __declarations = function(_node, _st, _ctx, _rw) {
		var _edits = [];
		var _decls = _node.declarations;
		var _i = 0; repeat (array_length(_decls)) {
			var _decl = _decls[_i];
			if (_decl.init == undefined) {
				struct_remove(_st.v, _decl.target.name);
			}
			else {
				var _blocked = [];
				__written(_decl.init, _blocked);
				var _value = (array_length(_blocked) == 0) ? __eval(_decl.init, _st, _ctx) : [false];
				var _new = _rw ? __sub(_decl.init, _st, _ctx, _blocked) : undefined;
				__forget(_st, _blocked);
				__set(_st, _decl.target.name, _value, _decl.init.span, _ctx);
				if (_new != undefined) array_push(_edits, { key: "declarations", index: _i, node: __gmlc_opt_rebuild_children(_decl, [{ key: "init", index: undefined, node: _new }]) });
			}
		_i++}
		return (array_length(_edits) == 0) ? undefined : __gmlc_opt_rebuild_children(_node, _edits);
	};

	#region jsDoc
	/// @func    __head(_expr, _st, _ctx, _rw)
	/// @desc    Follows an expression that a statement evaluates once: an assignment or an increment of a local sets
	///          its value in the state, anything written inside another expression is forgotten.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _expr : The expression
	/// @param   {Struct}         _st   : The state, changed
	/// @param   {Struct}         _ctx  : The pass's context
	/// @param   {Bool}           _rw   : Whether to write the constants in
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __head = function(_expr, _st, _ctx, _rw) {
		var _blocked = [];
		var _new;
		if (_expr.kind == __GMLC_NodeKind_Assign) && (__rootLocal(_expr.target) != undefined) {
			var _name = __rootLocal(_expr.target);
			__written(_expr.value, _blocked);
			var _value = [false];
			if (array_length(_blocked) == 0) && (_expr.target.kind == __GMLC_NodeKind_Identifier) {
				_value = __assigned(_expr, _name, _st, _ctx);
			}
			_new = _rw ? __sub(_expr, _st, _ctx, _blocked) : undefined;
			__forget(_st, _blocked);
			__set(_st, _name, _value, _expr.span, _ctx);
			return _new;
		}
		if (_expr.kind == __GMLC_NodeKind_Update) && (__gmlc_opt_is_local(_expr.argument)) {
			var _name = _expr.argument.name;
			var _lit = _st.v[$ _name];
			var _value = [false];
			if (_lit != undefined) && (typeof(_lit.value) == "number") {
				_value = [true, (_expr.op == "++") ? _lit.value + 1 : _lit.value - 1];
				if (!__finite(_value[1])) _value = [false];
			}
			__set(_st, _name, _value, _expr.span, _ctx);
			return undefined;
		}
		__written(_expr, _blocked);
		_new = _rw ? __sub(_expr, _st, _ctx, _blocked) : undefined;
		__forget(_st, _blocked);
		return _new;
	};

	#region jsDoc
	/// @func    __assigned(_assign, _name, _st, _ctx)
	/// @desc    The value a local takes from `x = v`, `x += v`, `x -= v` or `x *= v`.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _assign : The assignment
	/// @param   {String}         _name   : The local
	/// @param   {Struct}         _st     : The state
	/// @param   {Struct}         _ctx    : The pass's context
	/// @returns {Array} [true, value], or [false]
	#endregion
	static __assigned = function(_assign, _name, _st, _ctx) {
		var _right = __eval(_assign.value, _st, _ctx);
		if (!_right[0]) return [false];
		if (_assign.op == "=") return _right;
		var _lit = _st.v[$ _name];
		if (_lit == undefined) return [false];
		switch (_assign.op) {
			case "+=": return __binary("+", _lit.value, _right[1], _ctx);
			case "-=": return __binary("-", _lit.value, _right[1], _ctx);
			case "*=": return __binary("*", _lit.value, _right[1], _ctx);
		}
		return [false];
	};

	#region jsDoc
	/// @func    __test(_expr, _st, _ctx, _rw)
	/// @desc    Follows a test: whether the state decides it, and with _rw the expression that takes its place.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _expr : The test
	/// @param   {Struct}         _st   : The state, changed by the writes in the test
	/// @param   {Struct}         _ctx  : The pass's context
	/// @param   {Bool}           _rw   : Whether to write the constants in
	/// @returns {Struct} {node, truth}: the new test (undefined when unchanged) and its truth (undefined when unknown)
	#endregion
	static __test = function(_expr, _st, _ctx, _rw) {
		var _blocked = [];
		__written(_expr, _blocked);
		var _truth = undefined;
		if (array_length(_blocked) == 0) {
			var _value = __eval(_expr, _st, _ctx);
			if (_value[0]) _truth = __truth(_value[1]);
		}
		var _new = undefined;
		if (_rw) {
			if (_truth != undefined) && (_expr.kind != __GMLC_NodeKind_Literal) && (!__gmlc_opt_is_opaque(_expr)) {
				_new = _ctx.optimizer.__literal(_truth, _expr.span);
				if (_new != undefined) _ctx.cx.stats[$ "tests_decided"]++;
			}
			else {
				_new = __sub(_expr, _st, _ctx, _blocked);
			}
		}
		__forget(_st, _blocked);
		return { node: _new, truth: _truth };
	};

	#region jsDoc
	/// @func    __ifStatement(_node, _st, _ctx, _rw)
	/// @desc    Follows an `if`: a test the state decides leaves one branch to follow, otherwise both are and the
	///          states they end in are joined.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node : The statement
	/// @param   {Struct}         _st   : The state, changed
	/// @param   {Struct}         _ctx  : The pass's context
	/// @param   {Bool}           _rw   : Whether to write the constants in
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __ifStatement = function(_node, _st, _ctx, _rw) {
		var _edits = [];
		var _test = __test(_node.test, _st, _ctx, _rw);
		if (_test.node != undefined) array_push(_edits, { key: "test", index: undefined, node: _test.node });
		var _known = (_test.truth != undefined);
		var _then_st = __copy(_st);
		var _else_st = __copy(_st);
		if (!_known) || (_test.truth) {
			var _then = __stmt(_node.consequent, _then_st, _ctx, _rw);
			if (_then != undefined) array_push(_edits, { key: "consequent", index: undefined, node: _then });
		}
		else {
			_then_st.live = false;
		}
		if (!_known) || (!_test.truth) {
			if (_node.alternate != undefined) {
				var _else = __stmt(_node.alternate, _else_st, _ctx, _rw);
				if (_else != undefined) array_push(_edits, { key: "alternate", index: undefined, node: _else });
			}
		}
		else {
			_else_st.live = false;
		}
		var _out = __join(_then_st, _else_st);
		_st.live = _out.live;
		_st.v = _out.v;
		return (array_length(_edits) == 0) ? undefined : __gmlc_opt_rebuild_children(_node, _edits);
	};

	#region jsDoc
	/// @func    __tryStatement(_node, _st, _ctx, _rw)
	/// @desc    Follows a `try`: what it writes is not known inside the `catch` and `finally` parts nor after it.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node : The statement
	/// @param   {Struct}         _st   : The state, changed
	/// @param   {Struct}         _ctx  : The pass's context
	/// @param   {Bool}           _rw   : Whether to write the constants in
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __tryStatement = function(_node, _st, _ctx, _rw) {
		var _edits = [];
		var _after = __copy(_st);
		var _names = [];
		__written(_node, _names);
		if (_node.catch_param != undefined) array_push(_names, _node.catch_param.name);
		__forget(_after, _names);
		var _block = __stmt(_node.block, __copy(_st), _ctx, _rw);
		if (_block != undefined) array_push(_edits, { key: "block", index: undefined, node: _block });
		if (_node.catch_body != undefined) {
			var _catch = __stmt(_node.catch_body, __copy(_after), _ctx, _rw);
			if (_catch != undefined) array_push(_edits, { key: "catch_body", index: undefined, node: _catch });
		}
		if (_node.finally_body != undefined) {
			var _finally = __stmt(_node.finally_body, __copy(_after), _ctx, _rw);
			if (_finally != undefined) array_push(_edits, { key: "finally_body", index: undefined, node: _finally });
		}
		_st.v = _after.v;
		return (array_length(_edits) == 0) ? undefined : __gmlc_opt_rebuild_children(_node, _edits);
	};

	#region jsDoc
	/// @func    __switchStatement(_node, _st, _ctx, _rw)
	/// @desc    Follows a `switch`: what it writes is not known inside its cases nor after it.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node : The statement
	/// @param   {Struct}         _st   : The state, changed
	/// @param   {Struct}         _ctx  : The pass's context
	/// @param   {Bool}           _rw   : Whether to write the constants in
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __switchStatement = function(_node, _st, _ctx, _rw) {
		var _edits = [];
		var _head = __head(_node.discriminant, _st, _ctx, _rw);
		if (_head != undefined) array_push(_edits, { key: "discriminant", index: undefined, node: _head });
		var _inside = __copy(_st);
		var _names = [];
		__written(_node, _names);
		__forget(_inside, _names);
		array_push(_ctx.stack, { loop: false, breaks: [], conts: [] });
		var _cases = _node.cases;
		var _i = 0; repeat (array_length(_cases)) {
			var _case = _cases[_i];
			var _case_edits = [];
			if (_case.kind == __GMLC_NodeKind_Case) {
				var _blocked = [];
				__written(_case.test, _blocked);
				var _new = _rw ? __sub(_case.test, _inside, _ctx, _blocked) : undefined;
				if (_new != undefined) array_push(_case_edits, { key: "test", index: undefined, node: _new });
			}
			var _body = __list(_case.body, __copy(_inside), _ctx, _rw);
			if (_body != undefined) array_push(_case_edits, { key: "body", index: undefined, node: _body });
			if (array_length(_case_edits) > 0) array_push(_edits, { key: "cases", index: _i, node: __gmlc_opt_rebuild_children(_case, _case_edits) });
		_i++}
		array_pop(_ctx.stack);
		_st.v = _inside.v;
		return (array_length(_edits) == 0) ? undefined : __gmlc_opt_rebuild_children(_node, _edits);
	};
	#endregion

	#region Loops
	#region jsDoc
	/// @func    __loopStatement(_node, _st, _ctx, _rw)
	/// @desc    Follows a loop to its fixed point: the state at its top is what the way in and every way back agree
	///          on, found by following the body again until the state stops changing; then, with _rw, once more to
	///          write the constants in.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node : The statement
	/// @param   {Struct}         _st   : The state before the loop, changed to the state after it
	/// @param   {Struct}         _ctx  : The pass's context
	/// @param   {Bool}           _rw   : Whether to write the constants in
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __loopStatement = function(_node, _st, _ctx, _rw) {
		var _edits = [];
		// what runs once before the loop
		switch (_node.kind) {
			case __GMLC_NodeKind_For: {
				if (_node.init != undefined) {
					var _init = __run(_node.init, _st, _ctx, _rw);
					if (_init != undefined) array_push(_edits, { key: "init", index: undefined, node: _init });
				}
			break;}
			case __GMLC_NodeKind_Repeat: {
				var _count = __head(_node.count, _st, _ctx, _rw);
				if (_count != undefined) array_push(_edits, { key: "count", index: undefined, node: _count });
			break;}
			case __GMLC_NodeKind_With: {
				var _target = __head(_node.target, _st, _ctx, _rw);
				if (_target != undefined) array_push(_edits, { key: "target", index: undefined, node: _target });
			break;}
		}

		var _entry = __copy(_st);
		var _top = __copy(_entry);
		var _round = 0; repeat (16) {
			var _pass = __loopPass(_node, _top, _ctx, false);
			var _next = __join(_entry, _pass.back);
			if (__equal(_next, _top)) break;
			_top = _next;
			_round++;
		}
		if (_round >= 16) {
			// not settled: nothing a loop writes is known
			var _names = [];
			__written(_node, _names);
			__forget(_top, _names);
		}
		var _final = __loopPass(_node, _top, _ctx, _rw);
		var _out = _final.exit;
		var _b = 0; repeat (array_length(_final.breaks)) {
			_out = __join(_out, _final.breaks[_b]);
		_b++}
		_st.live = _out.live;
		_st.v = _out.v;
		var _loop_edits = _final.edits;
		array_copy(_edits, array_length(_edits), _loop_edits, 0, array_length(_loop_edits));
		return (array_length(_edits) == 0) ? undefined : __gmlc_opt_rebuild_children(_node, _edits);
	};

	#region jsDoc
	/// @func    __loopPass(_node, _top, _ctx, _rw)
	/// @desc    Follows one trip of a loop from the state at its top.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node : The loop
	/// @param   {Struct}         _top  : The state at the top of the loop
	/// @param   {Struct}         _ctx  : The pass's context
	/// @param   {Bool}           _rw   : Whether to write the constants in
	/// @returns {Struct} {back, exit, breaks, edits}: the state going back to the top, the state leaving at the
	///          loop's own test, the states at each `break`, and the replacements to write
	#endregion
	static __loopPass = function(_node, _top, _ctx, _rw) {
		var _frame = { loop: true, breaks: [], conts: [] };
		array_push(_ctx.stack, _frame);
		var _edits = [];
		var _st = __copy(_top);
		var _back;
		var _exit;
		switch (_node.kind) {
			case __GMLC_NodeKind_While: {
				var _test = __test(_node.test, _st, _ctx, _rw);
				if (_test.node != undefined) array_push(_edits, { key: "test", index: undefined, node: _test.node });
				var _known = (_test.truth != undefined);
				_exit = __copy(_st);
				if (_known) && (_test.truth) _exit.live = false;
				if (_known) && (!_test.truth) {
					_st.live = false;
				}
				else {
					var _body = __stmt(_node.body, _st, _ctx, _rw);
					if (_body != undefined) array_push(_edits, { key: "body", index: undefined, node: _body });
				}
				_back = __withConts(_st, _frame);
			break;}
			case __GMLC_NodeKind_For: {
				var _known = false;
				var _truth = true;
				if (_node.test != undefined) {
					var _test = __test(_node.test, _st, _ctx, _rw);
					if (_test.node != undefined) array_push(_edits, { key: "test", index: undefined, node: _test.node });
					_known = (_test.truth != undefined);
					if (_known) _truth = _test.truth;
				}
				else {
					_known = true;
				}
				_exit = __copy(_st);
				if (_known) && (_truth) _exit.live = false;
				if (_known) && (!_truth) {
					_st.live = false;
				}
				else {
					var _body = __stmt(_node.body, _st, _ctx, _rw);
					if (_body != undefined) array_push(_edits, { key: "body", index: undefined, node: _body });
				}
				_back = __withConts(_st, _frame);
				if (_back.live) && (_node.update != undefined) {
					var _update = __run(_node.update, _back, _ctx, _rw);
					if (_update != undefined) array_push(_edits, { key: "update", index: undefined, node: _update });
				}
			break;}
			case __GMLC_NodeKind_Repeat:
			case __GMLC_NodeKind_With: {
				_exit = __copy(_st);
				var _body = __stmt(_node.body, _st, _ctx, _rw);
				if (_body != undefined) array_push(_edits, { key: "body", index: undefined, node: _body });
				_back = __withConts(_st, _frame);
			break;}
			case __GMLC_NodeKind_DoUntil: {
				var _body = __stmt(_node.body, _st, _ctx, _rw);
				if (_body != undefined) array_push(_edits, { key: "body", index: undefined, node: _body });
				var _at_test = __withConts(_st, _frame);
				var _test = __test(_node.test, _at_test, _ctx, _rw);
				if (_test.node != undefined) array_push(_edits, { key: "test", index: undefined, node: _test.node });
				_exit = __copy(_at_test);
				_back = __copy(_at_test);
				if (_test.truth != undefined) {
					if (_test.truth) {
						_back.live = false;
					}
					else {
						_exit.live = false;
					}
				}
			break;}
		}
		array_pop(_ctx.stack);
		return { back: _back, exit: _exit, breaks: _frame.breaks, edits: _edits };
	};

	#region jsDoc
	/// @func    __withConts(_st, _frame)
	/// @desc    The state at the end of a body joined with the states at its `continue` statements.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct} _st    : The state at the end of the body
	/// @param   {Struct} _frame : The loop's frame
	/// @returns {Struct}
	#endregion
	static __withConts = function(_st, _frame) {
		var _out = __copy(_st);
		var _i = 0; repeat (array_length(_frame.conts)) {
			_out = __join(_out, _frame.conts[_i]);
		_i++}
		return _out;
	};

	#region jsDoc
	/// @func    __frame(_ctx, _loop)
	/// @desc    The innermost loop or `switch` a `break` leaves, or the innermost loop a `continue` goes to.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct} _ctx  : The pass's context
	/// @param   {Bool}   _loop : Whether only loops count
	/// @returns {Struct|Undefined}
	#endregion
	static __frame = function(_ctx, _loop) {
		var _stack = _ctx.stack;
		var _i = array_length(_stack) - 1; repeat (array_length(_stack)) {
			if (!_loop) || (_stack[_i].loop) return _stack[_i];
		_i--}
		return undefined;
	};

	#region jsDoc
	/// @func    __run(_node, _st, _ctx, _rw)
	/// @desc    Follows a statement or an expression, as the parts of a `for` header are written either way.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node : The statement or expression
	/// @param   {Struct}         _st   : The state, changed
	/// @param   {Struct}         _ctx  : The pass's context
	/// @param   {Bool}           _rw   : Whether to write the constants in
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __run = function(_node, _st, _ctx, _rw) {
		var _kind = _node.kind;
		if (_kind >= __GMLC_NodeKind_Assign) && (_kind <= __GMLC_NodeKind_Nameof) return __head(_node, _st, _ctx, _rw);
		return __stmt(_node, _st, _ctx, _rw);
	};
	#endregion

	#region Expressions
	#region jsDoc
	/// @func    __sub(_node, _st, _ctx, _blocked)
	/// @desc    An expression with the reads of constant locals replaced by their literals; locals the expression
	///          writes keep their names, and so do those in a place that needs the variable.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node    : The expression
	/// @param   {Struct}         _st      : The state
	/// @param   {Struct}         _ctx     : The pass's context
	/// @param   {Array<String>}  _blocked : The locals to leave alone
	/// @returns {Struct.ASTNode|Undefined} The new expression, undefined when nothing changed
	#endregion
	static __sub = function(_node, _st, _ctx, _blocked) {
		if (__gmlc_opt_is_function(_node)) || (_ctx.optimizer.__isNoOp(_node)) return undefined;
		if (__gmlc_opt_is_local(_node)) {
			var _top = __read(_node, _st, _blocked);
			if (_top != undefined) _ctx.cx.stats[$ "reads_replaced"]++;
			return _top;
		}
		var _slots = _node.childSlots();
		var _edits = [];
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _child = _slot.node;
			var _new = undefined;
			if (__gmlc_opt_is_local(_child)) {
				var _read = __read(_child, _st, _blocked);
				// the YYC operand rule holds inside a loop, beside an operand whose value is not known
				var _yyc = (_ctx.optimizer.outputName() == "gml-source-yyc") && (!__besideKnown(_node, _slot, _st));
				if (_read != undefined) && (__replaceable(_node, _slot, _read, _yyc)) {
					_new = _read;
					_ctx.cx.stats[$ "reads_replaced"]++;
				}
			}
			else {
				_new = __sub(_child, _st, _ctx, _blocked);
			}
			if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
		_i++}
		return (array_length(_edits) == 0) ? undefined : __gmlc_opt_rebuild_children(_node, _edits);
	};

	#region jsDoc
	/// @func    __read(_node, _st, _blocked)
	/// @desc    The literal that takes the place of a read of a local, or undefined when its value is not known.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node    : The read
	/// @param   {Struct}         _st      : The state
	/// @param   {Array<String>}  _blocked : The locals to leave alone
	/// @returns {Struct.ASTLiteral|Undefined}
	#endregion
	static __read = function(_node, _st, _blocked) {
		var _lit = _st.v[$ _node.name];
		if (_lit == undefined) || (array_contains(_blocked, _node.name)) || (__gmlc_opt_is_opaque(_node)) return undefined;
		return new ASTLiteral(_node.span, _lit.ty, _lit.lexeme, _lit.value);
	};
	
	#region jsDoc
	/// @func    __besideKnown(_node, _slot, _st)
	/// @desc    Whether the other operand of a binary node is made of literals and locals whose values the state knows.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node : The node that holds the read
	/// @param   {Struct}         _slot : The read's place in it
	/// @param   {Struct}         _st   : The state
	/// @returns {Bool}
	#endregion
	static __besideKnown = function(_node, _slot, _st) {
		if (_node.kind != __GMLC_NodeKind_Binary) && (_node.kind != __GMLC_NodeKind_Logical) return false;
		var _other = (_slot.key == "left") ? _node.right : _node.left;
		return __gmlc_opt_constant_tree(_other, _st.v);
	};

	#region jsDoc
	/// @func    __replaceable(_parent, _slot, _lit, _yyc)
	/// @desc    Whether a literal may stand where a local is read: not where the variable itself is meant (the
	///          target of a write, the object of `a.b`, the callee), and not next to an int64 literal when it is a
	///          whole number, because there GameMaker's compiler computes with integers where a variable is a real.
	///          For YYC a whole number stays a local beside a non-literal operand of an arithmetic operator: YYC runs
	///          `_i + 1` slower than `_i + _m` with `var _m = 1`.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _parent : The node that holds the read
	/// @param   {Struct}         _slot   : The read's place in it
	/// @param   {Struct.ASTNode} _lit    : The literal
	/// @param   {Bool}           _yyc    : Whether the YYC operand rule holds here (the output is GML source for YYC, the
	///                                    read is inside a loop and the other operand's value is not known)
	/// @returns {Bool}
	#endregion
	static __replaceable = function(_parent, _slot, _lit, _yyc) {
		var _key = _slot.key;
		switch (_parent.kind) {
			case __GMLC_NodeKind_Assign:     if (_key == "target") return false; break;
			case __GMLC_NodeKind_Update:
			case __GMLC_NodeKind_Delete:
			return false;
			case __GMLC_NodeKind_VarDecl:    if (_key == "target") return false; break;
			case __GMLC_NodeKind_Index:      if (_key == "object") return false; break;
			case __GMLC_NodeKind_MethodCall: if (_key == "object") return false; break;
			case __GMLC_NodeKind_Call: {
				if (_key == "callee") return false;
				if (_yyc) && (__gmlc_opt_yyc_slow_argument(_parent, _slot.index, _lit, {})) return false;
			break;}
			case __GMLC_NodeKind_Binary:
			case __GMLC_NodeKind_Logical: {
				var _other = (_key == "left") ? _parent.right : _parent.left;
				if (_other.kind == __GMLC_NodeKind_Literal) && (_other.ty == "int64") && (_lit.ty == "real") return false;
				if (_yyc) && (_parent.kind == __GMLC_NodeKind_Binary) && (_other.kind != __GMLC_NodeKind_Literal)
				&& (__gmlc_opt_yyc_slow_operand(_parent.op, _lit)) {
					return false;
				}
			break;}
		}
		return true;
	};

	#region jsDoc
	/// @func    __eval(_node, _st, _ctx)
	/// @desc    The value of an expression when the state decides it and computing it cannot throw: literals,
	///          constant locals and built-in constants, `!` and `-`, `+ - *` and the comparisons of numbers, `+`, `==`
	///          and `!=` of strings, `&&`, `||`, `^^` and `?:`.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _st   : The state
	/// @param   {Struct}         _ctx  : The pass's context
	/// @returns {Array} [true, value], or [false]
	#endregion
	static __eval = function(_node, _st, _ctx) {
		if (__gmlc_opt_is_opaque(_node)) return [false];
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: {
				switch (_node.ty) {
					case "real": case "string": case "bool": case "undefined": return [true, _node.value];
				}
				return [false];
			}
			case __GMLC_NodeKind_Identifier: {
				if (__gmlc_opt_is_local(_node)) {
					var _lit = _st.v[$ _node.name];
					return (_lit == undefined) ? [false] : [true, _lit.value];
				}
				if (_node.symbol != undefined) && (_node.symbol.kind == "BuiltinConstant") {
					var _constant = _ctx.optimizer.__constantValue(_node);
					if (_constant[0]) && (!__finite(_constant[1])) return [false];
					return _constant;
				}
				return [false];
			}
			case __GMLC_NodeKind_Unary: {
				var _a = __eval(_node.argument, _st, _ctx);
				if (!_a[0]) return [false];
				var _type = typeof(_a[1]);
				if (_node.op == "!") && ((_type == "number") || (_type == "bool")) return [true, !_a[1]];
				if (_node.op == "-") && (_type == "number") && (__finite(-_a[1])) return [true, -_a[1]];
				return [false];
			}
			case __GMLC_NodeKind_Binary: {
				var _l = __eval(_node.left, _st, _ctx);
				if (!_l[0]) return [false];
				var _r = __eval(_node.right, _st, _ctx);
				if (!_r[0]) return [false];
				return __binary(_node.op, _l[1], _r[1], _ctx);
			}
			case __GMLC_NodeKind_Logical: {
				var _l = __eval(_node.left, _st, _ctx);
				if (!_l[0]) return [false];
				var _a = __truth(_l[1]);
				if (_a == undefined) return [false];
				if (_node.op == "&&") && (!_a) return [true, false];
				if (_node.op == "||") && (_a) return [true, true];
				var _r = __eval(_node.right, _st, _ctx);
				if (!_r[0]) return [false];
				var _b = __truth(_r[1]);
				if (_b == undefined) return [false];
				return [true, (_node.op == "^^") ? (_a != _b) : _b];
			}
			case __GMLC_NodeKind_Conditional: {
				var _t = __eval(_node.test, _st, _ctx);
				if (!_t[0]) return [false];
				var _truth = __truth(_t[1]);
				if (_truth == undefined) return [false];
				return __eval(_truth ? _node.consequent : _node.alternate, _st, _ctx);
			}
		}
		return [false];
	};

	#region jsDoc
	/// @func    __binary(_op, _a, _b, _ctx)
	/// @desc    `_a _op _b` for the operations that cannot throw on their operand types.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {String} _op  : The operator
	/// @param   {Any}    _a   : The left value
	/// @param   {Any}    _b   : The right value
	/// @param   {Struct} _ctx : The pass's context
	/// @returns {Array} [true, value], or [false]
	#endregion
	static __binary = function(_op, _a, _b, _ctx) {
		var _ta = typeof(_a);
		var _tb = typeof(_b);
		var _numbers = ((_ta == "number") || (_ta == "bool")) && ((_tb == "number") || (_tb == "bool"));
		var _strings = (_ta == "string") && (_tb == "string");
		var _ok = false;
		switch (_op) {
			case "+": _ok = _numbers || _strings; break;
			case "-":
			case "*": _ok = _numbers; break;
			case "==":
			case "!=": _ok = _numbers || _strings; break;
			case "<":
			case "<=":
			case ">":
			case ">=": _ok = _numbers; break;
		}
		if (!_ok) return [false];
		// with math_set_epsilon somewhere in the compile a comparison of reals depends on it
		if (_ctx.epsilon) && ((_op == "==") || (_op == "!=") || (_op == "<") || (_op == "<=") || (_op == ">") || (_op == ">=")) && ((_ta == "number") || (_tb == "number")) return [false];
		var _value = __GMLCbinaryValue(_op, _a, _b);
		if (!__finite(_value)) return [false];
		return [true, _value];
	};

	#region jsDoc
	/// @func    __truth(_value)
	/// @desc    Whether a number or bool counts as true, undefined for any other value.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Any} _value : The value
	/// @returns {Bool|Undefined}
	#endregion
	static __truth = function(_value) {
		var _type = typeof(_value);
		if (_type == "bool") return _value;
		if (_type == "number") return (_value) ? true : false;
		return undefined;
	};

	#region jsDoc
	/// @func    __finite(_value)
	/// @desc    Whether a value is not NaN or an infinity.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Any} _value : The value
	/// @returns {Bool}
	#endregion
	static __finite = function(_value) {
		if (typeof(_value) != "number") return true;
		return !is_nan(_value) && !is_infinity(_value);
	};

	#endregion

	#region State
	#region jsDoc
	/// @func    __copy(_st)
	/// @desc    A copy of a state.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct} _st : The state {live, v}: whether the code is reached, and the literal of each constant local
	/// @returns {Struct}
	#endregion
	static __copy = function(_st) {
		return { live: _st.live, v: variable_clone(_st.v, 0) };
	};

	#region jsDoc
	/// @func    __join(_a, _b)
	/// @desc    What two states agree on where their ways meet; a state that is not reached agrees with the other.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct} _a : A state
	/// @param   {Struct} _b : Another state
	/// @returns {Struct}
	#endregion
	static __join = function(_a, _b) {
		if (!_a.live) return __copy(_b);
		if (!_b.live) return __copy(_a);
		var _out = { live: true, v: {} };
		var _names = struct_get_names(_a.v);
		var _i = 0; repeat (array_length(_names)) {
			var _x = _a.v[$ _names[_i]];
			var _y = _b.v[$ _names[_i]];
			if (_y != undefined) && (__sameLiteral(_x, _y)) _out.v[$ _names[_i]] = _x;
		_i++}
		return _out;
	};

	#region jsDoc
	/// @func    __equal(_a, _b)
	/// @desc    Whether two states are the same.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct} _a : A state
	/// @param   {Struct} _b : Another state
	/// @returns {Bool}
	#endregion
	static __equal = function(_a, _b) {
		if (_a.live != _b.live) return false;
		var _names = struct_get_names(_a.v);
		if (array_length(_names) != struct_names_count(_b.v)) return false;
		var _i = 0; repeat (array_length(_names)) {
			var _y = _b.v[$ _names[_i]];
			if (_y == undefined) || (!__sameLiteral(_a.v[$ _names[_i]], _y)) return false;
		_i++}
		return true;
	};

	#region jsDoc
	/// @func    __sameLiteral(_x, _y)
	/// @desc    Whether two literals hold the same type and value.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _x : A literal
	/// @param   {Struct.ASTNode} _y : Another literal
	/// @returns {Bool}
	#endregion
	static __sameLiteral = function(_x, _y) {
		return (_x.ty == _y.ty) && (typeof(_x.value) == typeof(_y.value)) && (_x.value == _y.value);
	};

	#region jsDoc
	/// @func    __set(_st, _name, _value, _span, _ctx)
	/// @desc    Records the value a local takes, or that it is not known: only a value that reads back as a literal of
	///          a followed type, a string no longer than 64 bytes, is kept.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct}           _st    : The state, changed
	/// @param   {String}           _name  : The local
	/// @param   {Array}            _value : [true, value], or [false]
	/// @param   {Struct.GMLC_Span} _span  : Where the literal is said to be
	/// @param   {Struct}           _ctx   : The pass's context
	#endregion
	static __set = function(_st, _name, _value, _span, _ctx) {
		struct_remove(_st.v, _name);
		if (!_value[0]) return;
		if (typeof(_value[1]) == "string") && (string_byte_length(_value[1]) > 64) return;
		var _lit = _ctx.optimizer.__literal(_value[1], _span);
		if (_lit == undefined) return;
		_st.v[$ _name] = _lit;
	};

	#region jsDoc
	/// @func    __forget(_st, _names)
	/// @desc    Drops the locals from a state.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct}        _st    : The state, changed
	/// @param   {Array<String>} _names : The locals
	#endregion
	static __forget = function(_st, _names) {
		var _i = 0; repeat (array_length(_names)) {
			struct_remove(_st.v, _names[_i]);
		_i++}
	};

	#region jsDoc
	/// @func    __rootLocal(_target)
	/// @desc    The local at the root of a written place (`a` of `a[0].b`), undefined when it is not one.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _target : The written place
	/// @returns {String|Undefined}
	#endregion
	static __rootLocal = function(_target) {
		while (_target.kind == __GMLC_NodeKind_Index) {
			_target = _target.object;
		}
		return __gmlc_opt_is_local(_target) ? _target.name : undefined;
	};

	#region jsDoc
	/// @func    __written(_node, _out)
	/// @desc    Collects the locals written under a node (assigned, incremented, or the root of a written place),
	///          nested functions left out.
	/// @self    GMLC_Opt_SparseConditionalConstantPropagation
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Array<String>}  _out  : Gets the names
	#endregion
	static __written = function(_node, _out) {
		if (__gmlc_opt_is_function(_node)) return;
		var _name = undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Assign: _name = __rootLocal(_node.target); break;
			case __GMLC_NodeKind_Update: _name = __rootLocal(_node.argument); break;
			case __GMLC_NodeKind_Delete: _name = __rootLocal(_node.target); break;
			case __GMLC_NodeKind_VarDecl: _name = _node.target.name; break;
		}
		if (_name != undefined) && (!array_contains(_out, _name)) array_push(_out, _name);
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__written(_child, _out);
				}
			_i++}
		_field_index++}
	};

	#endregion
}
