#region jsDoc
/// @func    GMLC_Opt_CorrelatedFactPropagation()
/// @desc    The `correlated-fact-propagation` optimizer pass: after a test of a local, inside the branch it guards
///          (or after a branch that leaves), the same test, `is_undefined`, `x != undefined` and `x ?? y` on that
///          local fold. `if (_s != undefined) { if (_s == undefined) { f(); } }` loses the inner test. A fact ends
///          when its local is written.
/// @returns {Struct.GMLC_Opt_CorrelatedFactPropagation}
#endregion
function GMLC_Opt_CorrelatedFactPropagation() : GMLC_OptimizerPass("correlated-fact-propagation") constructor {
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with the tests its facts decide folded, or undefined when none is. A function with a
	///          `break` or `continue` inside a `try` is left alone: the loop kinds disagree on what those do.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (__gmlc_opt_has_try_jump(_node, true)) || (__gmlc_opt_uses_arguments(_node, true)) return undefined;
		var _state = { optimizer: _cx.optimizer, cx: _cx, epsilon: _cx.epsilon_set };
		var _env = { undef: {}, tests: [] };
		switch (_node.kind) {
			case __GMLC_NodeKind_Script: {
				var _body = __list(_node.body, _env, _state);
				return (_body == undefined) ? undefined : __gmlc_opt_rebuild_children(_node, [{ key: "body", index: undefined, node: _body }]);
			}
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr: {
				var _new = __stmt(_node.body, _env, _state);
				return (_new == undefined) ? undefined : __gmlc_opt_rebuild_children(_node, [{ key: "body", index: undefined, node: _new }]);
			}
		}
		return undefined;
	};
	#endregion

	#region Statements
	#region jsDoc
	/// @func    __list(_body, _env, _state)
	/// @desc    Runs a statement list in order; the facts are updated to what holds after it.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Array<Struct.ASTNode>} _body  : The statements
	/// @param   {Struct}                _env   : The facts that hold before the list
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list, undefined when nothing changed
	#endregion
	static __list = function(_body, _env, _state) {
		var _list = _body;
		var _changed = false;
		var _optimizer = _state.optimizer;
		var _i = 0; repeat (array_length(_body)) {
			var _stmt = _body[_i];
			if (_optimizer.__isNoOp(_stmt)) {
				__clear(_env);
			}
			else {
				var _new = __stmt(_stmt, _env, _state);
				if (_new != undefined) {
					if (!_changed) {
						_list = variable_clone(_body, 0);
						_changed = true;
					}
					_list[_i] = _new;
				}
				if (_optimizer.__containsNoOp(_stmt)) __clear(_env);
			}
		_i++}
		return _changed ? _list : undefined;
	};

	#region jsDoc
	/// @func    __stmt(_node, _env, _state)
	/// @desc    Folds the tests inside a statement under the facts that hold before it; the facts are updated to what
	///          holds after it.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct.ASTNode} _node  : The statement
	/// @param   {Struct}         _env   : The facts that hold before the statement
	/// @param   {Struct}         _state : The pass's state
	/// @returns {Struct.ASTNode|Undefined} The new statement, undefined when nothing changed
	#endregion
	static __stmt = function(_node, _env, _state) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Block: {
				var _body = __list(_node.body, _env, _state);
				return (_body == undefined) ? undefined : __gmlc_opt_rebuild_children(_node, [{ key: "body", index: undefined, node: _body }]);
			}
			case __GMLC_NodeKind_If: return __ifStatement(_node, _env, _state);
			case __GMLC_NodeKind_ExprStmt:
			case __GMLC_NodeKind_VarDeclList:
			case __GMLC_NodeKind_Return:
			case __GMLC_NodeKind_Throw: {
				var _inner = __without(_env, _node);
				var _new = __children(_node, _inner, _state);
				__killWrites(_env, _node);
				return _new;
			}
			case __GMLC_NodeKind_While:
			case __GMLC_NodeKind_For:
			case __GMLC_NodeKind_Repeat:
			case __GMLC_NodeKind_DoUntil:
			case __GMLC_NodeKind_With: return __loopStatement(_node, _env, _state);
			case __GMLC_NodeKind_Switch: return __switchStatement(_node, _env, _state);
			case __GMLC_NodeKind_Try: {
				var _after = __without(_env, _node);
				var _edits = [];
				var _block = __stmt(_node.block, __copyEnv(_env), _state);
				if (_block != undefined) array_push(_edits, { key: "block", index: undefined, node: _block });
				if (_node.catch_body != undefined) {
					var _catch = __stmt(_node.catch_body, __copyEnv(_after), _state);
					if (_catch != undefined) array_push(_edits, { key: "catch_body", index: undefined, node: _catch });
				}
				if (_node.finally_body != undefined) {
					var _finally = __stmt(_node.finally_body, __copyEnv(_after), _state);
					if (_finally != undefined) array_push(_edits, { key: "finally_body", index: undefined, node: _finally });
				}
				__replaceEnv(_env, _after);
				return (array_length(_edits) == 0) ? undefined : __gmlc_opt_rebuild_children(_node, _edits);
			}
		}
		__killWrites(_env, _node);
		return undefined;
	};

	#region jsDoc
	/// @func    __ifStatement(_node, _env, _state)
	/// @desc    An `if`: the test is folded, each branch runs under what the test shows, and what holds after it is
	///          what both ways agree on, or the way that does not leave.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct.ASTNode} _node  : The statement
	/// @param   {Struct}         _env   : The facts that hold before the statement
	/// @param   {Struct}         _state : The pass's state
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __ifStatement = function(_node, _env, _state) {
		var _edits = [];
		var _before = __without(_env, _node.test);
		var _test = _node.test;
		var _new_test = __expr(_test, _before, _state);
		if (_new_test != undefined) _test = _new_test;
		if (_test.kind != __GMLC_NodeKind_Literal) && (!__gmlc_opt_is_opaque(_test)) {
			var _known = __known(_before, _test, _state.optimizer);
			if (_known != undefined) {
				_test = _state.optimizer.__literal(_known, _test.span);
				_new_test = _test;
				_state.cx.stats[$ "tests_folded"]++;
			}
		}
		if (_new_test != undefined) array_push(_edits, { key: "test", index: undefined, node: _new_test });

		var _then_env = __copyEnv(_before);
		__assume(_then_env, _test, true, _state);
		var _else_env = __copyEnv(_before);
		__assume(_else_env, _test, false, _state);
		var _then = __stmt(_node.consequent, _then_env, _state);
		if (_then != undefined) array_push(_edits, { key: "consequent", index: undefined, node: _then });
		var _has_else = (_node.alternate != undefined);
		if (_has_else) {
			var _else = __stmt(_node.alternate, _else_env, _state);
			if (_else != undefined) array_push(_edits, { key: "alternate", index: undefined, node: _else });
		}

		var _then_ends = __gmlc_opt_terminates(_node.consequent);
		var _else_ends = _has_else && __gmlc_opt_terminates(_node.alternate);
		if (_then_ends && !_else_ends) {
			__replaceEnv(_env, _else_env);
		}
		else if (_else_ends && !_then_ends) {
			__replaceEnv(_env, _then_env);
		}
		else {
			__replaceEnv(_env, _before);
			__killWrites(_env, _node.consequent);
			if (_has_else) __killWrites(_env, _node.alternate);
		}
		return (array_length(_edits) == 0) ? undefined : __gmlc_opt_rebuild_children(_node, _edits);
	};

	#region jsDoc
	/// @func    __loopStatement(_node, _env, _state)
	/// @desc    A loop or `with`: only facts about locals it never writes hold inside it and after it.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct.ASTNode} _node  : The statement
	/// @param   {Struct}         _env   : The facts that hold before the statement
	/// @param   {Struct}         _state : The pass's state
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __loopStatement = function(_node, _env, _state) {
		var _edits = [];
		if (_node.kind == __GMLC_NodeKind_For) && (_node.init != undefined) {
			var _init_env = __without(_env, _node.init);
			var _init = __children(_node.init, _init_env, _state);
			__killWrites(_env, _node.init);
			if (_init != undefined) array_push(_edits, { key: "init", index: undefined, node: _init });
		}
		var _inside = __without(_env, _node);
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			if (_slot.key != "init") {
				var _env_child = __copyEnv(_inside);
				var _new;
				if (_slot.key == "body") {
					var _test = _node[$ "test"];
					if (_test != undefined) && (_node.kind != __GMLC_NodeKind_DoUntil) __assume(_env_child, _test, true, _state);
					_new = __stmt(_slot.node, _env_child, _state);
				}
				else {
					_new = __expr(_slot.node, _env_child, _state);
				}
				if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
			}
		_i++}
		__replaceEnv(_env, _inside);
		return (array_length(_edits) == 0) ? undefined : __gmlc_opt_rebuild_children(_node, _edits);
	};

	#region jsDoc
	/// @func    __switchStatement(_node, _env, _state)
	/// @desc    A `switch`: its cases run under the facts about locals it never writes.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct.ASTNode} _node  : The statement
	/// @param   {Struct}         _env   : The facts that hold before the statement
	/// @param   {Struct}         _state : The pass's state
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __switchStatement = function(_node, _env, _state) {
		var _edits = [];
		var _inside = __without(_env, _node);
		var _new = __expr(_node.discriminant, __copyEnv(_inside), _state);
		if (_new != undefined) array_push(_edits, { key: "discriminant", index: undefined, node: _new });
		var _cases = _node.cases;
		var _i = 0; repeat (array_length(_cases)) {
			var _case = _cases[_i];
			var _case_edits = [];
			if (_case.kind == __GMLC_NodeKind_Case) {
				var _test = __expr(_case.test, __copyEnv(_inside), _state);
				if (_test != undefined) array_push(_case_edits, { key: "test", index: undefined, node: _test });
			}
			var _body = __list(_case.body, __copyEnv(_inside), _state);
			if (_body != undefined) array_push(_case_edits, { key: "body", index: undefined, node: _body });
			if (array_length(_case_edits) > 0) array_push(_edits, { key: "cases", index: _i, node: __gmlc_opt_rebuild_children(_case, _case_edits) });
		_i++}
		__replaceEnv(_env, _inside);
		return (array_length(_edits) == 0) ? undefined : __gmlc_opt_rebuild_children(_node, _edits);
	};

	#endregion

	#region Expressions
	#region jsDoc
	/// @func    __children(_node, _env, _state)
	/// @desc    Folds the expressions under a node, in the same facts.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Struct}         _env   : The facts
	/// @param   {Struct}         _state : The pass's state
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __children = function(_node, _env, _state) {
		var _slots = _node.childSlots();
		var _edits = [];
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new = __expr(_slot.node, _env, _state);
			if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
		_i++}
		return (array_length(_edits) == 0) ? undefined : __gmlc_opt_rebuild_children(_node, _edits);
	};

	#region jsDoc
	/// @func    __expr(_node, _env, _state)
	/// @desc    Folds an expression under the facts that hold where it is evaluated; the right side of `&&`, `||`
	///          and `??` and the branches of `?:` get the facts the left side or the test shows.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct.ASTNode} _node  : The expression
	/// @param   {Struct}         _env   : The facts
	/// @param   {Struct}         _state : The pass's state
	/// @returns {Struct.ASTNode|Undefined} The new expression, undefined when nothing changed
	#endregion
	static __expr = function(_node, _env, _state) {
		if (__gmlc_opt_is_function(_node)) || (_state.optimizer.__isNoOp(_node)) return undefined;
		var _current = undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Logical: {
				if (_node.op == "^^") {
					_current = __children(_node, _env, _state);
					break;
				}
				var _edits = [];
				var _left = _node.left;
				var _new_left = __expr(_left, _env, _state);
				if (_new_left != undefined) {
					_left = _new_left;
					array_push(_edits, { key: "left", index: undefined, node: _new_left });
				}
				var _inner = __copyEnv(_env);
				__assume(_inner, _left, _node.op == "&&", _state);
				var _new_right = __expr(_node.right, _inner, _state);
				if (_new_right != undefined) array_push(_edits, { key: "right", index: undefined, node: _new_right });
				if (array_length(_edits) > 0) _current = __gmlc_opt_rebuild_children(_node, _edits);
			break;}
			case __GMLC_NodeKind_Nullish: {
				var _edits = [];
				var _new_left = __expr(_node.left, _env, _state);
				if (_new_left != undefined) array_push(_edits, { key: "left", index: undefined, node: _new_left });
				var _inner = __copyEnv(_env);
				var _left = _new_left ?? _node.left;
				if (__gmlc_opt_is_local(_left)) _inner.undef[$ _left.name] = true;
				var _new_right = __expr(_node.right, _inner, _state);
				if (_new_right != undefined) array_push(_edits, { key: "right", index: undefined, node: _new_right });
				if (array_length(_edits) > 0) _current = __gmlc_opt_rebuild_children(_node, _edits);
			break;}
			case __GMLC_NodeKind_Conditional: {
				var _edits = [];
				var _test = _node.test;
				var _new_test = __expr(_test, _env, _state);
				if (_new_test != undefined) _test = _new_test;
				if (_test.kind != __GMLC_NodeKind_Literal) && (!__gmlc_opt_is_opaque(_test)) {
					var _known = __known(_env, _test, _state.optimizer);
					if (_known != undefined) {
						_test = _state.optimizer.__literal(_known, _test.span);
						_new_test = _test;
						_state.cx.stats[$ "tests_folded"]++;
					}
				}
				if (_new_test != undefined) array_push(_edits, { key: "test", index: undefined, node: _new_test });
				var _then_env = __copyEnv(_env);
				__assume(_then_env, _test, true, _state);
				var _new_then = __expr(_node.consequent, _then_env, _state);
				if (_new_then != undefined) array_push(_edits, { key: "consequent", index: undefined, node: _new_then });
				var _else_env = __copyEnv(_env);
				__assume(_else_env, _test, false, _state);
				var _new_else = __expr(_node.alternate, _else_env, _state);
				if (_new_else != undefined) array_push(_edits, { key: "alternate", index: undefined, node: _new_else });
				if (array_length(_edits) > 0) _current = __gmlc_opt_rebuild_children(_node, _edits);
			break;}
			default: _current = __children(_node, _env, _state);
		}
		var _target = _current ?? _node;
		var _folded = __fold(_target, _env, _state);
		if (_folded != undefined) _state.cx.stats[$ (_target.kind == __GMLC_NodeKind_Nullish) ? "nullish_folded" : "tests_folded"]++;
		return _folded ?? _current;
	};

	#region jsDoc
	/// @func    __fold(_node, _env, _state)
	/// @desc    The value of a test or a `??` the facts decide, or undefined: a test of a known fact is a bool, `x ?? y`
	///          is `x` for a local known to be set and `y` for one known to be undefined.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct.ASTNode} _node  : The expression, its parts already folded
	/// @param   {Struct}         _env   : The facts
	/// @param   {Struct}         _state : The pass's state
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __fold = function(_node, _env, _state) {
		if (__gmlc_opt_is_opaque(_node)) return undefined;
		if (_node.kind == __GMLC_NodeKind_Nullish) {
			var _left = _node.left;
			if (!__gmlc_opt_is_local(_left)) return undefined;
			var _is_undef = _env.undef[$ _left.name];
			if (_is_undef == undefined) return undefined;
			if (_is_undef) {
				var _right = _node.right;
				if (_right.kind == __GMLC_NodeKind_Identifier) && (_right.name == "self") return undefined;
				return _right;
			}
			return __droppable(_node.right, _state) ? _left : undefined;
		}
		if (!__isBool(_node)) return undefined;
		var _known = __known(_env, _node, _state.optimizer);
		if (_known == undefined) return undefined;
		return _state.optimizer.__literal(_known, _node.span);
	};
	#endregion

	#region Facts
	#region jsDoc
	/// @func    __undefTest(_node, _optimizer)
	/// @desc    The local a test asks about for `undefined`: `x == undefined`, `x != undefined` or `is_undefined(x)`.
	///          `undefined` written in source is a built-in constant, not a literal.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct.ASTNode}              _node      : The expression
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _optimizer : The optimizer
	/// @returns {Struct|Undefined} {name, eq}: eq is whether the test is true exactly when the local is undefined
	#endregion
	static __undefTest = function(_node, _optimizer) {
		if (_node.kind == __GMLC_NodeKind_Binary) && ((_node.op == "==") || (_node.op == "!=")) {
			var _a = _node.left;
			var _b = _node.right;
			if (__gmlc_opt_is_local(_b)) {
				var _swap = _a;
				_a = _b;
				_b = _swap;
			}
			if (!__gmlc_opt_is_local(_a)) return undefined;
			var _known = _optimizer.__constantValue(_b);
			if (_known[0]) && (is_undefined(_known[1])) return { name: _a.name, eq: (_node.op == "==") };
			return undefined;
		}
		if (__gmlc_opt_builtin_call(_node) == "is_undefined") && (array_length(_node.args) == 1) && (__gmlc_opt_is_local(_node.args[0])) return { name: _node.args[0].name, eq: true };
		return undefined;
	};

	#region jsDoc
	/// @func    __known(_env, _node, _optimizer)
	/// @desc    Whether the facts decide a test: its truth, or undefined.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct}                      _env       : The facts
	/// @param   {Struct.ASTNode}              _node      : The expression
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _optimizer : The optimizer
	/// @returns {Bool|Undefined}
	#endregion
	static __known = function(_env, _node, _optimizer) {
		var _test = __undefTest(_node, _optimizer);
		if (_test != undefined) {
			var _is_undef = _env.undef[$ _test.name];
			return (_is_undef == undefined) ? undefined : (_is_undef == _test.eq);
		}
		if (_node.kind == __GMLC_NodeKind_Unary) && (_node.op == "!") {
			var _inner = __known(_env, _node.argument, _optimizer);
			return (_inner == undefined) ? undefined : !_inner;
		}
		var _tests = _env.tests;
		var _i = 0; repeat (array_length(_tests)) {
			if (__gmlc_opt_same(_tests[_i].expr, _node)) return _tests[_i].truth;
		_i++}
		return undefined;
	};

	#region jsDoc
	/// @func    __assume(_env, _cond, _truth, _state)
	/// @desc    Adds what a test shows when it is true or false to the facts.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct}         _env   : The facts, changed
	/// @param   {Struct.ASTNode} _cond  : The test
	/// @param   {Bool}           _truth : Whether the test held
	/// @param   {Struct}         _state : The pass's state
	#endregion
	static __assume = function(_env, _cond, _truth, _state) {
		if (__gmlc_opt_is_opaque(_cond)) return;
		if (_cond.kind == __GMLC_NodeKind_Unary) && (_cond.op == "!") {
			__assume(_env, _cond.argument, !_truth, _state);
			return;
		}
		if (_cond.kind == __GMLC_NodeKind_Logical) {
			if ((_cond.op == "&&") && _truth) || ((_cond.op == "||") && !_truth) {
				__assume(_env, _cond.left, _truth, _state);
				__assume(_env, _cond.right, _truth, _state);
				return;
			}
		}
		var _test = __undefTest(_cond, _state.optimizer);
		if (_test != undefined) {
			_env.undef[$ _test.name] = (_truth == _test.eq);
			return;
		}
		if (_cond.kind == __GMLC_NodeKind_Literal) || (!__gmlc_opt_is_stable(_cond)) return;
		if (_state.epsilon) && (__gmlc_opt_has_comparison(_cond)) return;
		if (__known(_env, _cond, _state.optimizer) != undefined) return;
		var _names = [];
		__gmlc_opt_collect_local_names(_cond, _names);
		array_push(_env.tests, { expr: _cond, truth: _truth, names: _names });
	};

	#region jsDoc
	/// @func    __isBool(_node)
	/// @desc    Whether an expression always gives a bool: a comparison, `!`, `&&`, `||`, `^^` or an `is_` function.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __isBool = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Logical: return true;
			case __GMLC_NodeKind_Unary: return (_node.op == "!");
			case __GMLC_NodeKind_Binary: {
				switch (_node.op) {
					case "==": case "!=": case "<": case "<=": case ">": case ">=": return true;
				}
				return false;
			}
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				return (_name != undefined) && (string_copy(_name, 1, 3) == "is_");
			}
		}
		return false;
	};

	#region jsDoc
	/// @func    __droppable(_node, _state)
	/// @desc    Whether an expression that never runs may leave the code: it holds no function, no built-in constant
	///          (an asset reference is one) and nothing frozen.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct.ASTNode} _node  : The expression
	/// @param   {Struct}         _state : The pass's state
	/// @returns {Bool}
	#endregion
	static __droppable = function(_node, _state) {
		if (_state.optimizer.__containsNoOp(_node)) return false;
		return __droppableTree(_node);
	};

	#region jsDoc
	/// @func    __droppableTree(_node)
	/// @desc    Whether no function and no built-in constant is written under a node.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __droppableTree = function(_node) {
		if (__gmlc_opt_is_function(_node)) return false;
		if (_node.kind == __GMLC_NodeKind_Identifier) && (_node.symbol != undefined) && ((_node.symbol.kind == "BuiltinConstant") || (_node.symbol.kind == "Asset")) return false;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__droppableTree(_child)) return false;
				}
			_i++}
		_field_index++}
		return true;
	};

	#endregion

	#region Environment
	#region jsDoc
	/// @func    __copyEnv(_env)
	/// @desc    A copy of the facts to change on one way through the code.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct} _env : The facts
	/// @returns {Struct}
	#endregion
	static __copyEnv = function(_env) {
		return { undef: variable_clone(_env.undef, 0), tests: variable_clone(_env.tests, 0) };
	};

	#region jsDoc
	/// @func    __replaceEnv(_env, _from)
	/// @desc    Makes the facts the same as another set.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct} _env  : The facts, changed
	/// @param   {Struct} _from : The facts to take
	#endregion
	static __replaceEnv = function(_env, _from) {
		_env.undef = _from.undef;
		_env.tests = _from.tests;
	};

	#region jsDoc
	/// @func    __clear(_env)
	/// @desc    Forgets every fact.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct} _env : The facts, changed
	#endregion
	static __clear = function(_env) {
		_env.undef = {};
		_env.tests = [];
	};

	#region jsDoc
	/// @func    __without(_env, _node)
	/// @desc    A copy of the facts without those about locals written under a node.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct}         _env  : The facts
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Struct}
	#endregion
	static __without = function(_env, _node) {
		var _copy = __copyEnv(_env);
		__killWrites(_copy, _node);
		return _copy;
	};

	#region jsDoc
	/// @func    __killWrites(_env, _node)
	/// @desc    Forgets the facts about locals written under a node.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct}         _env  : The facts, changed
	/// @param   {Struct.ASTNode} _node : The node
	#endregion
	static __killWrites = function(_env, _node) {
		var _names = struct_get_names(_env.undef);
		var _tests = _env.tests;
		var _t = 0; repeat (array_length(_tests)) {
			var _in = _tests[_t].names;
			array_copy(_names, array_length(_names), _in, 0, array_length(_in));
		_t++}
		_names = array_unique(_names);
		var _i = 0; repeat (array_length(_names)) {
			if (__gmlc_opt_writes(_node, _names[_i])) __kill(_env, _names[_i]);
		_i++}
	};

	#region jsDoc
	/// @func    __kill(_env, _name)
	/// @desc    Forgets the facts about a local.
	/// @self    GMLC_Opt_CorrelatedFactPropagation
	/// @param   {Struct} _env  : The facts, changed
	/// @param   {String} _name : The local
	#endregion
	static __kill = function(_env, _name) {
		struct_remove(_env.undef, _name);
		var _kept = [];
		var _tests = _env.tests;
		var _i = 0; repeat (array_length(_tests)) {
			if (!array_contains(_tests[_i].names, _name)) array_push(_kept, _tests[_i]);
		_i++}
		_env.tests = _kept;
	};
	#endregion

}
