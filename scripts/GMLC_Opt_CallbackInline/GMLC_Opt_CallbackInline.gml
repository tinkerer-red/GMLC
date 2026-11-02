#region jsDoc
/// @func    GMLC_Opt_CallbackInline()
/// @desc    `array_foreach`, `array_map` and `array_filter` given a function literal become a loop with the literal's
///          body written inside: `var _alive = array_filter(units, function(_u) { return _u.hp > 0; });` becomes a
///          `for` loop over `units` that pushes each element whose test holds. The call must be a whole statement
///          (or the value of `var x =` or `x =`), and the literal must be simple: no call but a pure, observer or draw
///          built-in, no write to an array element, no `return` but the last statement, no `try`, `with`, `static`,
///          nested function, `self`, `other` or `argument`, so nothing in it can change the array or leave early.
/// @returns {Struct.GMLC_Opt_CallbackInline}
#endregion
function GMLC_Opt_CallbackInline() : GMLC_OptimizerPass("callback-inline") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Writes the calls of a function that can be a loop as loops.
	/// @self    GMLC_Opt_CallbackInline
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
	/// @desc    How many statements of a node can be inlined, nested functions left out.
	/// @self    GMLC_Opt_CallbackInline
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
	/// @desc    Writes the inlinable statements of a copy as loops, in place, nested functions left out.
	/// @self    GMLC_Opt_CallbackInline
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
	/// @desc    What a statement that can be inlined is, or undefined: its kind ("foreach", "map" or "filter"), how the
	///          result is kept (mode 0 none, 1 `var x =`, 2 `x =`), the local, and what the literal is.
	/// @self    GMLC_Opt_CallbackInline
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {Struct}         _cx        : The pass context
	/// @returns {Struct|Undefined} {kind, mode, target, info}
	#endregion
	static __match = function(_statement, _cx) {
		var _call = undefined;
		var _target = undefined;
		var _mode = 0;
		if (_statement.kind == __GMLC_NodeKind_ExprStmt) {
			var _expression = _statement.expression;
			if (_expression.kind == __GMLC_NodeKind_Call) {
				_call = _expression;
			}
			else if (_expression.kind == __GMLC_NodeKind_Assign) && (_expression.op == "=") && __gmlc_opt_is_local(_expression.target) && (_expression.value.kind == __GMLC_NodeKind_Call) {
				_call = _expression.value;
				_target = _expression.target.name;
				_mode = 2;
			}
		}
		else if (_statement.kind == __GMLC_NodeKind_VarDeclList) && (array_length(_statement.declarations) == 1) {
			var _declaration = _statement.declarations[0];
			if (_declaration.init != undefined) && (_declaration.init.kind == __GMLC_NodeKind_Call) && (_declaration.target.kind == __GMLC_NodeKind_Identifier) {
				_call = _declaration.init;
				_target = _declaration.target.name;
				_mode = 1;
			}
		}
		if (_call == undefined) return undefined;
		var _name = __gmlc_opt_builtin_call(_call);
		if (_name == undefined) || (array_length(_call.args) != 2) return undefined;
		var _kind;
		if (_name == "array_foreach") {
			if (_mode != 0) return undefined;
			_kind = "foreach";
		}
		else if (_name == "array_map") {
			if (_mode == 0) return undefined;
			_kind = "map";
		}
		else if (_name == "array_filter") {
			if (_mode == 0) return undefined;
			_kind = "filter";
		}
		else {
			return undefined;
		}
		var _fn = _call.args[1];
		if (_fn.kind != __GMLC_NodeKind_FunctionExpr) || (__is_stage(_call.args[0])) return undefined;
		if (_cx.optimizer.__isNoOp(_statement)) return undefined;
		var _info = __simple(_fn, _kind, _cx);
		if (_info == undefined) return undefined;
		return { kind: _kind, mode: _mode, target: _target, info: _info };
	};

	#region jsDoc
	/// @func    __is_stage(_node)
	/// @desc    Whether a node is a map or filter call with a function literal, the start of a pipeline that another
	///          pass joins into one loop.
	/// @self    GMLC_Opt_CallbackInline
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __is_stage = function(_node) {
		var _name = __gmlc_opt_builtin_call(_node);
		return ((_name == "array_map") || (_name == "array_filter")) && (array_length(_node.args) >= 2) && (_node.args[1].kind == __GMLC_NodeKind_FunctionExpr);
	};

	#region jsDoc
	/// @func    __simple(_fn, _kind, _cx)
	/// @desc    What a function literal is when its body can be written inside a loop, or undefined: its parameter
	///          names, the names of its locals (declared with a value at the top level of its body or in a top-level
	///          `for`) and whether it ends in a `return`. A map or filter must end in `return value;` and a filter's
	///          value must be a comparison or another boolean.
	/// @self    GMLC_Opt_CallbackInline
	/// @param   {Struct.ASTFunctionExpr} _fn   : The literal
	/// @param   {String}                 _kind : "foreach", "map" or "filter"
	/// @param   {Struct}                 _cx   : The pass context
	/// @returns {Struct|Undefined} {params, locals, tail}
	#endregion
	static __simple = function(_fn, _kind, _cx) {
		if (_fn.is_constructor) || (_fn.parent != undefined) || (_cx.optimizer.__isNoOp(_fn)) return undefined;
		var _count = array_length(_fn.params);
		if (_count > 2) return undefined;
		var _params = [];
		var _p = 0; repeat (_count) {
			var _param = _fn.params[_p];
			if (_param[$ "default"] != undefined) || (_param.target.kind != __GMLC_NodeKind_Identifier) return undefined;
			array_push(_params, _param.target.name);
		_p++}
		var _statements = _fn.body.body;
		var _total = array_length(_statements);
		var _tail = (_total > 0) && (_statements[_total - 1].kind == __GMLC_NodeKind_Return);
		var _last = _tail ? _total - 1 : _total;
		var _argument = _tail ? _statements[_last].argument : undefined;
		if (_kind != "foreach") && (_argument == undefined) return undefined;
		if (_kind == "filter") && ((!__gmlc_opt_is_boolean_expr(_argument)) || (_count > 0 && __gmlc_opt_writes(_fn.body, _params[0]))) return undefined;
		if (_kind == "foreach") && (_argument != undefined) && (!__gmlc_opt_is_trivial(_argument)) && (_argument.kind != __GMLC_NodeKind_Call) && (_argument.kind != __GMLC_NodeKind_Assign) && (_argument.kind != __GMLC_NodeKind_Update) return undefined;
		var _locals = [];
		var _s = 0; repeat (_last) {
			var _statement = _statements[_s];
			var _list = undefined;
			if (_statement.kind == __GMLC_NodeKind_VarDeclList) {
				_list = _statement;
			}
			else if (_statement.kind == __GMLC_NodeKind_For) && (_statement.init != undefined) && (_statement.init.kind == __GMLC_NodeKind_VarDeclList) {
				_list = _statement.init;
			}
			if (_list != undefined) {
				var _d = 0; repeat (array_length(_list.declarations)) {
					var _declaration = _list.declarations[_d];
					if (_declaration.init == undefined) || (_declaration.target.kind != __GMLC_NodeKind_Identifier) return undefined;
					var _local = _declaration.target.name;
					if (array_contains(_params, _local)) return undefined;
					if (!array_contains(_locals, _local)) array_push(_locals, _local);
				_d++}
			}
		_s++}
		var _names = array_concat(_params, _locals);
		_s = 0; repeat (_last) {
			if (!__ok_statement(_statements[_s], _names, _cx)) return undefined;
		_s++}
		if (_argument != undefined) && ((_cx.optimizer.__isNoOp(_statements[_last])) || (!__ok(_argument, _names, _cx))) return undefined;
		return { params: _params, locals: _locals, tail: _tail };
	};

	#region jsDoc
	/// @func    __ok_statement(_statement, _names, _cx)
	/// @desc    Whether a statement of the literal's body can move into the loop: a declaration (at the top level or in
	///          a top-level `for`) is checked by its values, any other statement by `__ok`.
	/// @self    GMLC_Opt_CallbackInline
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {Array<String>}  _names     : The parameters and locals
	/// @param   {Struct}         _cx        : The pass context
	/// @returns {Bool}
	#endregion
	static __ok_statement = function(_statement, _names, _cx) {
		if (_cx.optimizer.__isNoOp(_statement)) return false;
		var _list = undefined;
		if (_statement.kind == __GMLC_NodeKind_VarDeclList) {
			_list = _statement;
		}
		else if (_statement.kind == __GMLC_NodeKind_For) && (_statement.init != undefined) && (_statement.init.kind == __GMLC_NodeKind_VarDeclList) {
			_list = _statement.init;
		}
		if (_list == undefined) return __ok(_statement, _names, _cx);
		var _d = 0; repeat (array_length(_list.declarations)) {
			if (!__ok(_list.declarations[_d].init, _names, _cx)) return false;
		_d++}
		if (_statement.kind == __GMLC_NodeKind_VarDeclList) return true;
		if (_statement.test != undefined) && (!__ok(_statement.test, _names, _cx)) return false;
		if (_statement.update != undefined) && (!__ok(_statement.update, _names, _cx)) return false;
		return __ok(_statement.body, _names, _cx);
	};

	#region jsDoc
	/// @func    __ok(_node, _names, _cx)
	/// @desc    Whether a node of the literal's body can move into the loop: it reads only the literal's own names,
	///          instance and global variables, calls only pure, observer and draw built-ins, writes no array element,
	///          and has no `return`, `exit`, `break`, `continue`, `try`, `with`, `static`, `delete`, `new`, method call,
	///          nested function or declaration outside the places `__simple` found.
	/// @self    GMLC_Opt_CallbackInline
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Array<String>}  _names : The parameters and locals
	/// @param   {Struct}         _cx    : The pass context
	/// @returns {Bool}
	#endregion
	static __ok = function(_node, _names, _cx) {
		if (_cx.optimizer.__isNoOp(_node)) return false;
		switch (_node.kind) {
			case __GMLC_NodeKind_FunctionExpr: case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_Exit: case __GMLC_NodeKind_Break: case __GMLC_NodeKind_Continue: case __GMLC_NodeKind_Return:
			case __GMLC_NodeKind_Try: case __GMLC_NodeKind_With: case __GMLC_NodeKind_StaticDecl: case __GMLC_NodeKind_GlobalVarDecl:
			case __GMLC_NodeKind_Delete: case __GMLC_NodeKind_VarDecl: case __GMLC_NodeKind_VarDeclList:
			case __GMLC_NodeKind_New: case __GMLC_NodeKind_MethodCall:
			return false;
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				if (_symbol == undefined) return false;
				if (_symbol.kind == "Local") return array_contains(_names, _node.name);
				if (_symbol.kind == "Static") return false;
				if (_symbol.kind == "BuiltinVar") return (_node.name != "other") && (_node.name != "self") && (string_pos("argument", _node.name) != 1);
				return true;
			}
			case __GMLC_NodeKind_Call: {
				var _builtin = __gmlc_opt_builtin_call(_node);
				if (_builtin == undefined) return false;
				var _class = __gmlc_opt_call_class(_builtin);
				if (_class != "pure") && (_class != "observer") && (_class != "render") return false;
				var _a = 0; repeat (array_length(_node.args)) {
					if (!__ok(_node.args[_a], _names, _cx)) return false;
				_a++}
				return true;
			}
			case __GMLC_NodeKind_Assign:
				if (__writes_array(_node.target)) return false;
			break;
			case __GMLC_NodeKind_Update:
				if (__writes_array(_node.argument)) return false;
			break;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__ok(_child, _names, _cx)) return false;
				}
			_i++}
		_field_index++}
		return true;
	};

	#region jsDoc
	/// @func    __writes_array(_target)
	/// @desc    Whether an assignment target is an element of an array.
	/// @self    GMLC_Opt_CallbackInline
	/// @param   {Struct.ASTNode} _target : The target
	/// @returns {Bool}
	#endregion
	static __writes_array = function(_target) {
		if (_target.kind != __GMLC_NodeKind_Index) return false;
		var _accessor = _target.accessor;
		return (_accessor == "Array") || (_accessor == "ArrayAt") || (_accessor == "Array2D") || (_accessor == "Array2DAt");
	};

	#region jsDoc
	/// @func    __expand(_match, _statement, _out, _cx)
	/// @desc    Adds the statements that replace an inlinable statement to a list: the source and its length in
	///          temporaries, the loop with the literal's body (its parameters and locals made temporaries), and the
	///          result kept where the call's value went.
	/// @self    GMLC_Opt_CallbackInline
	/// @param   {Struct}         _match     : What the statement is
	/// @param   {Struct.ASTNode} _statement : The statement, a copy this pass owns
	/// @param   {Array}          _out       : The statements so far, added to
	/// @param   {Struct}         _cx        : The pass context
	#endregion
	static __expand = function(_match, _statement, _out, _cx) {
		var _call;
		switch (_match.mode) {
			case 0: _call = _statement.expression; break;
			case 1: _call = _statement.declarations[0].init; break;
			default: _call = _statement.expression.value; break;
		}
		var _span = _statement.span;
		var _optimizer = _cx.optimizer;
		var _zero = _optimizer.__literal(0, _span);
		if (_zero == undefined) {
			array_push(_out, _statement);
			return;
		}
		_cx.stats[$ "inlined"]++;
		var _source = _call.args[0];
		var _fn = _call.args[1];
		var _info = _match.info;
		var _kind = _match.kind;
		var _params = _info.params;
		var _plain = __gmlc_opt_is_local(_source);
		var _t_source = _plain ? _source.name : _optimizer.newTemporary(_cx);
		var _t_length = _optimizer.newTemporary(_cx);
		var _t_index = _optimizer.newTemporary(_cx);
		var _t_result = (_kind != "foreach") ? _optimizer.newTemporary(_cx) : undefined;
		var _t_element = ((array_length(_params) >= 1) || (_kind == "filter")) ? _optimizer.newTemporary(_cx) : undefined;
		var _t_param_index = ((array_length(_params) >= 2) && __gmlc_opt_writes(_fn.body, _params[1])) ? _optimizer.newTemporary(_cx) : undefined;
		var _map = {};
		if (array_length(_params) >= 1) _map[$ _params[0]] = _t_element;
		if (array_length(_params) >= 2) _map[$ _params[1]] = (_t_param_index != undefined) ? _t_param_index : _t_index;
		var _l = 0; repeat (array_length(_info.locals)) {
			_map[$ _info.locals[_l]] = _optimizer.newTemporary(_cx);
		_l++}
		var _element_read = (_t_element != undefined) && ((_kind == "filter") || (__gmlc_opt_count_mentions(_fn.body, _params[0]) > 0));
		__gmlc_opt_rename_locals(_fn.body, _map);
		if (!_plain) array_push(_out, __gmlc_opt_var(_t_source, _source, _span));
		// the source's span: the call's closing bracket would print on the last line of the statement
		array_push(_out, __gmlc_opt_var(_t_length, __gmlc_opt_builtin_call_node("array_length", [__gmlc_opt_source_or_local(_plain, _source, _t_source, _source.span)], _source.span), _span));
		if (_kind == "map") {
			array_push(_out, __gmlc_opt_var(_t_result, __gmlc_opt_builtin_call_node("array_create", [__gmlc_opt_local(_t_length, _span)], _span), _span));
		}
		else if (_kind == "filter") {
			array_push(_out, __gmlc_opt_var(_t_result, new ASTArrayLiteral(_span, []), _span));
		}
		var _loop = [];
		if (_element_read) {
			var _read = new ASTIndex(_span, "Array", __gmlc_opt_source_or_local(_plain, _source, _t_source, _span), [__gmlc_opt_local(_t_index, _span)], undefined);
			array_push(_loop, __gmlc_opt_var(_t_element, _read, _span));
		}
		if (_t_param_index != undefined) {
			array_push(_loop, __gmlc_opt_var(_t_param_index, __gmlc_opt_local(_t_index, _span), _span));
		}
		var _statements = _fn.body.body;
		var _last = _info.tail ? array_length(_statements) - 1 : array_length(_statements);
		var _s = 0; repeat (_last) {
			array_push(_loop, _statements[_s]);
		_s++}
		if (_info.tail) {
			var _tail = _statements[_last];
			var _value = _tail.argument;
			if (_kind == "map") {
				var _slot = new ASTIndex(_tail.span, "Array", __gmlc_opt_local(_t_result, _tail.span), [__gmlc_opt_local(_t_index, _tail.span)], undefined);
				array_push(_loop, new ASTExprStmt(_tail.span, new ASTAssign(_tail.span, "=", _slot, _value)));
			}
			else if (_kind == "filter") {
				var _push = __gmlc_opt_builtin_call_node("array_push", [__gmlc_opt_local(_t_result, _tail.span), __gmlc_opt_local(_t_element, _tail.span)], _tail.span);
				array_push(_loop, new ASTIf(_tail.span, _value, new ASTBlock(_tail.span, [new ASTExprStmt(_tail.span, _push)]), undefined));
			}
			else if (_value != undefined) && (!__gmlc_opt_is_trivial(_value)) {
				array_push(_loop, new ASTExprStmt(_value.span, _value));
			}
		}
		var _test = new ASTBinary(_span, "<", __gmlc_opt_local(_t_index, _span), __gmlc_opt_local(_t_length, _span));
		var _update = new ASTExprStmt(_span, new ASTUpdate(_span, "++", false, __gmlc_opt_local(_t_index, _span)));
		array_push(_out, new ASTFor(_span, __gmlc_opt_var(_t_index, _zero, _span), _test, _update, new ASTBlock(_span, _loop)));
		switch (_match.mode) {
			case 1:
				_statement.declarations[0].init = __gmlc_opt_local(_t_result, _span);
				array_push(_out, _statement);
			break;
			case 2:
				_statement.expression.value = __gmlc_opt_local(_t_result, _span);
				array_push(_out, _statement);
			break;
		}
	};
	#endregion
}
