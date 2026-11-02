#region jsDoc
/// @func    GMLC_Opt_ArrayPipelineFuse()
/// @desc    A chain of `array_map` and `array_filter` calls with function literals, optionally ended by `array_reduce`
///          with a start value, becomes one loop with no array between the stages: `var _sum = array_reduce(array_map(
///          _items, function(_i) { return _i.price; }), function(_a, _b) { return _a + _b; }, 0);` becomes a `for`
///          loop that adds each price. Every literal must return one value computed without effects from its own
///          parameters, at most one of them may fail, and a stage after a filter must not read its index.
/// @returns {Struct.GMLC_Opt_ArrayPipelineFuse}
#endregion
function GMLC_Opt_ArrayPipelineFuse() : GMLC_OptimizerPass("array-pipeline-fuse") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Writes the chains of a function that can be one loop as one loop.
	/// @self    GMLC_Opt_ArrayPipelineFuse
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (__count(_node, _cx) == 0) return undefined;
		var _new = __gmlc_opt_clone(_node);
		__rewrite(_new, _cx);
		return _new;
	};
	#endregion

	#region Private
	#region jsDoc
	/// @func    __count(_node, _cx)
	/// @desc    How many statements of a node hold a chain that can be one loop, nested functions left out.
	/// @self    GMLC_Opt_ArrayPipelineFuse
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Real}
	#endregion
	static __count = function(_node, _cx) {
		var _n = 0;
		if (__gmlc_opt_is_statement_list(_node)) {
			var _body = _node.body;
			var _s = 0; repeat (array_length(_body)) {
				if (__match(_body[_s], _cx) != undefined) _n++;
			_s++}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__gmlc_opt_is_function(_child)) _n += __count(_child, _cx);
				}
			_i++}
		_field_index++}
		return _n;
	};

	#region jsDoc
	/// @func    __rewrite(_node, _cx)
	/// @desc    Writes the chains of a copy as loops, in place, nested functions left out.
	/// @self    GMLC_Opt_ArrayPipelineFuse
	/// @param   {Struct.ASTNode} _node : The node, a copy this pass owns
	/// @param   {Struct}         _cx   : The pass context
	#endregion
	static __rewrite = function(_node, _cx) {
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__gmlc_opt_is_function(_child)) __rewrite(_child, _cx);
				}
			_i++}
		_field_index++}
		if (!__gmlc_opt_is_statement_list(_node)) return;
		var _old = _node.body;
		var _body = [];
		var _s = 0; repeat (array_length(_old)) {
			var _match = __match(_old[_s], _cx);
			if (_match == undefined) {
				array_push(_body, _old[_s]);
			}
			else {
				__expand(_match, _old[_s], _body, _cx);
			}
		_s++}
		_node.body = _body;
	};

	#region jsDoc
	/// @func    __match(_statement, _cx)
	/// @desc    What a statement that holds a chain is, or undefined: how the result is kept (mode 1 `var x =`, 2
	///          `x =`) and the chain.
	/// @self    GMLC_Opt_ArrayPipelineFuse
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {Struct}         _cx        : The pass context
	/// @returns {Struct|Undefined} {mode, chain}
	#endregion
	static __match = function(_statement, _cx) {
		var _call = undefined;
		var _mode = 0;
		if (_statement.kind == __GMLC_NodeKind_ExprStmt) {
			var _expression = _statement.expression;
			if (_expression.kind == __GMLC_NodeKind_Assign) && (_expression.op == "=") && __gmlc_opt_is_local(_expression.target) && (_expression.value.kind == __GMLC_NodeKind_Call) {
				_call = _expression.value;
				_mode = 2;
			}
		}
		else if (_statement.kind == __GMLC_NodeKind_VarDeclList) && (array_length(_statement.declarations) == 1) {
			var _declaration = _statement.declarations[0];
			if (_declaration.init != undefined) && (_declaration.init.kind == __GMLC_NodeKind_Call) && (_declaration.target.kind == __GMLC_NodeKind_Identifier) {
				_call = _declaration.init;
				_mode = 1;
			}
		}
		if (_call == undefined) || (_cx.optimizer.__isNoOp(_statement)) return undefined;
		var _chain = __chain(_call, _cx);
		if (_chain == undefined) return undefined;
		return { mode: _mode, chain: _chain };
	};

	#region jsDoc
	/// @func    __chain(_call, _cx)
	/// @desc    The stages of a chain of calls, or undefined: `array_map` and `array_filter` with function literals
	///          (innermost first), then optionally an `array_reduce` with a literal and a trivial start value, and the
	///          array they start from. There must be two stages at least, every literal must be accepted by `__stage`,
	///          at most one of them may throw, and no stage after a filter may read its index.
	/// @self    GMLC_Opt_ArrayPipelineFuse
	/// @param   {Struct.ASTCall} _call : The outermost call
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct|Undefined} {stages, reduce, source}
	#endregion
	static __chain = function(_call, _cx) {
		var _stages = [];
		var _reduce = undefined;
		var _node = _call;
		if (__gmlc_opt_builtin_call(_node) == "array_reduce") {
			if (array_length(_node.args) != 3) || (_node.args[1].kind != __GMLC_NodeKind_FunctionExpr) || (!__gmlc_opt_is_trivial(_node.args[2])) return undefined;
			_reduce = { fn: _node.args[1], init: _node.args[2] };
			_node = _node.args[0];
		}
		while (true) {
			var _name = __gmlc_opt_builtin_call(_node);
			if ((_name != "array_map") && (_name != "array_filter")) || (array_length(_node.args) != 2) || (_node.args[1].kind != __GMLC_NodeKind_FunctionExpr) break;
			array_insert(_stages, 0, { filter: (_name == "array_filter"), fn: _node.args[1] });
			_node = _node.args[0];
		}
		var _total = array_length(_stages) + ((_reduce != undefined) ? 1 : 0);
		if (_total < 2) return undefined;
		var _throwers = 0;
		var _filtered = false;
		var _s = 0; repeat (array_length(_stages)) {
			var _info = __stage(_stages[_s].fn, _stages[_s].filter ? 1 : 0, _filtered, _cx);
			if (_info == undefined) return undefined;
			_stages[_s].params = _info.params;
			_stages[_s].expr = _info.expr;
			if (_info.throws) _throwers++;
			if (_stages[_s].filter) _filtered = true;
		_s++}
		if (_reduce != undefined) {
			var _info = __stage(_reduce.fn, 2, _filtered, _cx);
			if (_info == undefined) return undefined;
			_reduce.params = _info.params;
			_reduce.expr = _info.expr;
			if (_info.throws) _throwers++;
		}
		if (_throwers > 1) return undefined;
		return { stages: _stages, reduce: _reduce, source: _node };
	};

	#region jsDoc
	/// @func    __stage(_fn, _role, _filtered, _cx)
	/// @desc    What a stage's function literal is, or undefined: parameters without defaults (up to two, and for a
	///          reduce two or three), a body of one `return value;`, a value without effects whose names are its
	///          parameters, instance and global variables and built-ins (a filter's value must be boolean), and an
	///          index parameter only where no filter came before.
	/// @self    GMLC_Opt_ArrayPipelineFuse
	/// @param   {Struct.ASTFunctionExpr} _fn       : The literal
	/// @param   {Real}                   _role     : 0 map, 1 filter, 2 reduce
	/// @param   {Bool}                   _filtered : Whether a filter comes before the stage
	/// @param   {Struct}                 _cx       : The pass context
	/// @returns {Struct|Undefined} {params, expr, throws}
	#endregion
	static __stage = function(_fn, _role, _filtered, _cx) {
		if (_fn.is_constructor) || (_fn.parent != undefined) || (_cx.optimizer.__isNoOp(_fn)) return undefined;
		var _count = array_length(_fn.params);
		if (_role == 2) {
			if (_count < 2) || (_count > 3) return undefined;
		}
		else if (_count > 2) {
			return undefined;
		}
		var _params = [];
		var _p = 0; repeat (_count) {
			var _param = _fn.params[_p];
			if (_param[$ "default"] != undefined) || (_param.target.kind != __GMLC_NodeKind_Identifier) return undefined;
			array_push(_params, _param.target.name);
		_p++}
		var _statements = _fn.body.body;
		if (array_length(_statements) != 1) || (_statements[0].kind != __GMLC_NodeKind_Return) || (_statements[0].argument == undefined) return undefined;
		if (_cx.optimizer.__isNoOp(_statements[0])) return undefined;
		var _expr = _statements[0].argument;
		if (!__expr_ok(_expr, _params, _cx)) || (__gmlc_opt_has_effects(_expr)) return undefined;
		if (_role == 1) && (!__gmlc_opt_is_boolean_expr(_expr)) return undefined;
		var _index = (_role == 2) ? 2 : 1;
		if (_filtered) && (_count > _index) && (__gmlc_opt_count_mentions(_expr, _params[_index]) > 0) return undefined;
		return { params: _params, expr: _expr, throws: __gmlc_opt_may_throw(_expr) };
	};

	#region jsDoc
	/// @func    __expr_ok(_node, _names, _cx)
	/// @desc    Whether the names under an expression can be read from inside a loop in the same function: locals are
	///          the literal's parameters, no `other`, `self` or `argument`, no static, no function literal, outside
	///          frozen code.
	/// @self    GMLC_Opt_ArrayPipelineFuse
	/// @param   {Struct.ASTNode} _node  : The expression
	/// @param   {Array<String>}  _names : The literal's parameters
	/// @param   {Struct}         _cx    : The pass context
	/// @returns {Bool}
	#endregion
	static __expr_ok = function(_node, _names, _cx) {
		if (_cx.optimizer.__isNoOp(_node)) || (__gmlc_opt_is_function(_node)) return false;
		if (_node.kind == __GMLC_NodeKind_Identifier) {
			var _symbol = _node.symbol;
			if (_symbol == undefined) return false;
			if (_symbol.kind == "Local") return array_contains(_names, _node.name);
			if (_symbol.kind == "Static") return false;
			if (_symbol.kind == "BuiltinVar") return (_node.name != "other") && (_node.name != "self") && (string_pos("argument", _node.name) != 1);
			return true;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__expr_ok(_child, _names, _cx)) return false;
				}
			_i++}
		_field_index++}
		return true;
	};

	#region jsDoc
	/// @func    __expand(_match, _statement, _out, _cx)
	/// @desc    Adds the statements that replace a statement holding a chain to a list: the source and its length in
	///          temporaries, the array (or start value) that collects the result, and one loop that runs each stage on
	///          each element (a map in a new local, a filter as an `if` around the rest), ending in the push (or the
	///          reduce step); then the result kept where the chain's value went.
	/// @self    GMLC_Opt_ArrayPipelineFuse
	/// @param   {Struct}         _match     : What the statement is
	/// @param   {Struct.ASTNode} _statement : The statement, a copy this pass owns
	/// @param   {Array}          _out       : The statements so far, added to
	/// @param   {Struct}         _cx        : The pass context
	#endregion
	static __expand = function(_match, _statement, _out, _cx) {
		var _span = _statement.span;
		var _optimizer = _cx.optimizer;
		var _zero = _optimizer.__literal(0, _span);
		if (_zero == undefined) {
			array_push(_out, _statement);
			return;
		}
		var _chain = _match.chain;
		var _stages = _chain.stages;
		var _reduce = _chain.reduce;
		var _source = _chain.source;
		_cx.stats[$ "fused"]++;
		_cx.stats[$ "stages_fused"] += array_length(_stages) + ((_reduce != undefined) ? 1 : 0);
		var _plain = __gmlc_opt_is_local(_source);
		var _t_source = _plain ? _source.name : _optimizer.newTemporary(_cx);
		var _t_length = _optimizer.newTemporary(_cx);
		var _t_result = _optimizer.newTemporary(_cx);
		var _t_index = _optimizer.newTemporary(_cx);
		var _t_element = _optimizer.newTemporary(_cx);
		var _steps = [];
		var _current = _t_element;
		var _s = 0; repeat (array_length(_stages)) {
			var _stage = _stages[_s];
			var _map = {};
			if (array_length(_stage.params) >= 1) _map[$ _stage.params[0]] = _current;
			if (array_length(_stage.params) >= 2) _map[$ _stage.params[1]] = _t_index;
			__gmlc_opt_rename_locals(_stage.expr, _map);
			if (_stage.filter) {
				array_push(_steps, { filter: true, node: _stage.expr });
			}
			else {
				var _t_value = _optimizer.newTemporary(_cx);
				array_push(_steps, { filter: false, node: __gmlc_opt_var(_t_value, _stage.expr, _stage.expr.span) });
				_current = _t_value;
			}
		_s++}
		var _last;
		if (_reduce != undefined) {
			var _map = {};
			_map[$ _reduce.params[0]] = _t_result;
			_map[$ _reduce.params[1]] = _current;
			if (array_length(_reduce.params) >= 3) _map[$ _reduce.params[2]] = _t_index;
			__gmlc_opt_rename_locals(_reduce.expr, _map);
			_last = new ASTExprStmt(_reduce.expr.span, new ASTAssign(_reduce.expr.span, "=", __gmlc_opt_local(_t_result, _reduce.expr.span), _reduce.expr));
		}
		else {
			_last = new ASTExprStmt(_span, __gmlc_opt_builtin_call_node("array_push", [__gmlc_opt_local(_t_result, _span), __gmlc_opt_local(_current, _span)], _span));
		}
		var _inner = [_last];
		_s = array_length(_steps) - 1; repeat (array_length(_steps)) {
			var _step = _steps[_s];
			if (_step.filter) {
				_inner = [new ASTIf(_step.node.span, _step.node, new ASTBlock(_step.node.span, _inner), undefined)];
			}
			else {
				array_insert(_inner, 0, _step.node);
			}
		_s--}
		var _read = new ASTIndex(_span, "Array", __gmlc_opt_source_or_local(_plain, _source, _t_source, _span), [__gmlc_opt_local(_t_index, _span)], undefined);
		array_insert(_inner, 0, __gmlc_opt_var(_t_element, _read, _span));
		if (!_plain) array_push(_out, __gmlc_opt_var(_t_source, _source, _span));
		array_push(_out, __gmlc_opt_var(_t_length, __gmlc_opt_builtin_call_node("array_length", [__gmlc_opt_source_or_local(_plain, _source, _t_source, _span)], _span), _span));
		array_push(_out, __gmlc_opt_var(_t_result, (_reduce != undefined) ? _reduce.init : new ASTArrayLiteral(_span, []), _span));
		var _test = new ASTBinary(_span, "<", __gmlc_opt_local(_t_index, _span), __gmlc_opt_local(_t_length, _span));
		var _update = new ASTExprStmt(_span, new ASTUpdate(_span, "++", false, __gmlc_opt_local(_t_index, _span)));
		array_push(_out, new ASTFor(_span, __gmlc_opt_var(_t_index, _zero, _span), _test, _update, new ASTBlock(_span, _inner)));
		if (_match.mode == 1) {
			_statement.declarations[0].init = __gmlc_opt_local(_t_result, _span);
		}
		else {
			_statement.expression.value = __gmlc_opt_local(_t_result, _span);
		}
		array_push(_out, _statement);
	};
	#endregion
}
