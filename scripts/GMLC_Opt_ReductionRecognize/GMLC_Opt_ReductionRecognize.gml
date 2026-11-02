#region jsDoc
/// @func    GMLC_Opt_ReductionRecognize()
/// @desc    The `reduction-recognize` optimizer pass: an instance or global variable that a loop only adds to, multiplies
///          or combines with itself, and that is set just before the loop, lives in a temporary during the loop and is
///          stored once after it.
///          `weight = 0; for (...) { weight += _w[_i]; }` becomes
///          `weight = 0; var _t = weight; for (...) { _t += _w[_i]; } weight = _t;`.
/// @returns {Struct.GMLC_Opt_ReductionRecognize}
#endregion
function GMLC_Opt_ReductionRecognize() : GMLC_OptimizerPass("reduction-recognize") constructor {
	#region Init
	#endregion
	
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with the reductions of its loops kept in temporaries, or undefined when none is.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _state = { cx: _cx, optimizer: _cx.optimizer, root: _node, kinds: undefined, in_try: 0, in_with: 0 };
		return __walk(_node, _state, true);
	};
	#endregion
	
	#region Walk
	#region jsDoc
	/// @func    __walk(_node, _state, _isRoot)
	/// @desc    Localizes the reductions of every loop under a node, outer loops first, nested functions and frozen
	///          code left out, without changing the node.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct}         _state  : The pass's state
	/// @param   {Bool}           _isRoot : Whether the node is the function itself
	/// @returns {Struct.ASTNode|Undefined} The new node, undefined when nothing changed
	#endregion
	static __walk = function(_node, _state, _isRoot) {
		if (!_isRoot) && ((__gmlc_opt_is_function(_node)) || ((_state.optimizer.has_no_op_targets) && (_state.optimizer.__isNoOp(_node)))) return undefined;
		var _current = _node;
		switch (_node.kind) {
			case __GMLC_NodeKind_Script:
			case __GMLC_NodeKind_Block:
			case __GMLC_NodeKind_Case:
			case __GMLC_NodeKind_Default: {
				var _body = __list(_node.body, _state);
				if (_body != undefined) _current = __gmlc_opt_rebuild_children(_node, [{ key: "body", index: undefined, node: _body }]);
			break;}
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr:
			case __GMLC_NodeKind_If:
			case __GMLC_NodeKind_For:
			case __GMLC_NodeKind_While:
			case __GMLC_NodeKind_Repeat:
			case __GMLC_NodeKind_DoUntil:
			case __GMLC_NodeKind_With:
			case __GMLC_NodeKind_Switch:
			case __GMLC_NodeKind_Try:
			break;
			default: return undefined;
		}
		var _slots = _current.childSlots();
		var _edits = [];
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			// a handler in the function could read the half-done total of a loop that throws
			var _guarded = (_current.kind == __GMLC_NodeKind_Try) && (_slot.key == "block");
			var _inside = (_current.kind == __GMLC_NodeKind_With) && (_slot.key == "body") && (__gmlc_opt_self_unknown(_current));
			if (_guarded) _state.in_try++;
			if (_inside) _state.in_with++;
			var _new = __walk(_slot.node, _state, false);
			if (_guarded) _state.in_try--;
			if (_inside) _state.in_with--;
			if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
		_i++}
		if (array_length(_edits) == 0) return (_current == _node) ? undefined : _current;
		return __gmlc_opt_rebuild_children(_current, _edits);
	};
	
	#region jsDoc
	/// @func    __list(_body, _state)
	/// @desc    Wraps each loop of a statement list that holds a reduction in the load and the store of its
	///          temporaries.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Array<Struct.ASTNode>} _body  : The statements
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list, undefined when nothing changed
	#endregion
	static __list = function(_body, _state) {
		var _out = undefined;
		var _k = 0; repeat (array_length(_body)) {
			var _statement = _body[_k];
			var _hit = ((_state.in_try == 0) && (__gmlc_opt_is_loop(_statement))) ? __localize(_body, _k, _state) : undefined;
			if (_hit == undefined) {
				if (_out != undefined) array_push(_out, _statement);
			}
			else {
				if (_out == undefined) {
					_out = array_create(_k);
					array_copy(_out, 0, _body, 0, _k);
				}
				array_copy(_out, array_length(_out), _hit.pre, 0, array_length(_hit.pre));
				array_push(_out, _hit.loop);
				array_copy(_out, array_length(_out), _hit.post, 0, array_length(_hit.post));
			}
		_k++}
		return _out;
	};
	#endregion
	
	#region Reductions
	#region jsDoc
	/// @func    __localize(_body, _k, _state)
	/// @desc    The loop at an index of a statement list with the reductions in it moved into temporaries: every
	///          variable the loop only accumulates into, whose first value is set just before the loop, when nothing in
	///          the loop can throw, call code, read the variable or leave the function.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Array<Struct.ASTNode>} _body  : The statements
	/// @param   {Real}                  _k     : The loop's place
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Struct|Undefined} {pre, loop, post}, undefined when nothing is localized
	#endregion
	static __localize = function(_body, _k, _state) {
		var _loop = _body[_k];
		var _optimizer = _state.optimizer;
		if (_optimizer.has_no_op_targets) && (_optimizer.__containsNoOp(_loop)) return undefined;
		var _found = [];
		__accumulators(_loop, _found);
		if (array_length(_found) == 0) return undefined;
		if (!__quiet(_loop)) return undefined;
		if (_state.kinds == undefined) _state.kinds = __gmlc_opt_local_value_kinds(_state.root, _state.cx);
		var _kept_keys = {};
		var _kept = [];
		var _a = 0; repeat (array_length(_found)) {
			var _acc = _found[_a];
			var _first = __initial(_body, _k, _acc, _state);
			if (_first > 0) && (__occurrences(_loop, _acc) == _acc.count) {
				_kept_keys[$ _acc.kind + ":" + _acc.name] = _first;
				array_push(_kept, _acc);
			}
		_a++}
		if (array_length(_kept) == 0) return undefined;
		var _x = { kept: _kept_keys, range: __range(_body, _k, _state), in_with: (_state.in_with > 0) };
		if (!__sound(_loop, _state, _x)) return undefined;
		var _start = new GMLC_Span(_loop.span.file, _loop.span.start, _loop.span.start);
		var _end = new GMLC_Span(_loop.span.file, _loop.span[$ "end"], _loop.span[$ "end"]);
		var _pre = [];
		var _post = [];
		var _new = _loop;
		_a = 0; repeat (array_length(_kept)) {
			var _item = _kept[_a];
			var _name = _optimizer.newTemporary(_state.cx);
			_new = __replace(_new, _item, _name) ?? _new;
			var _read = __gmlc_opt_clone(_item.node);
			_read.span = _start;
			array_push(_pre, __gmlc_opt_var(_name, _read, _start));
			var _target = __gmlc_opt_clone(_item.node);
			_target.span = _end;
			array_push(_post, new ASTExprStmt(_end, new ASTAssign(_end, "=", _target, __gmlc_opt_local(_name, _end))));
			_state.cx.stats[$ "accumulators_localized"]++;
		_a++}
		return { pre: _pre, loop: _new, post: _post };
	};
	
	#region jsDoc
	/// @func    __accumulators(_node, _found)
	/// @desc    Lists the instance and global variables a statement under a node updates with `+=`, `-=`, `*=`, `|=`,
	///          `&=` or `= max(...)` and `= min(...)` of itself, nested functions left out.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Array<Struct>}  _found : {kind, name, node, count} for each variable: its symbol kind, its name, its
	///                                    first target and how many names those statements hold
	#endregion
	static __accumulators = function(_node, _found) {
		if (__gmlc_opt_is_function(_node)) return;
		if (_node.kind == __GMLC_NodeKind_ExprStmt) && (_node.expression.kind == __GMLC_NodeKind_Assign) {
			var _assign = _node.expression;
			var _target = _assign.target;
			if (_target.kind == __GMLC_NodeKind_Identifier) && (_target.symbol != undefined) && (((_target.symbol.kind == "Self") && (__gmlc_opt_builtin_variable(_target.name) == undefined)) || (_target.symbol.kind == "Global")) {
				var _count = 0;
				switch (_assign.op) {
					case "+=": case "-=": case "*=": case "|=": case "&=": _count = 1; break;
					case "=": {
						var _function = __gmlc_opt_builtin_call(_assign.value);
						if (_function == "max") || (_function == "min") {
							var _args = _assign.value.args;
							if (array_length(_args) == 2) && ((__names(_args[0], _target.symbol.kind, _target.name)) || (__names(_args[1], _target.symbol.kind, _target.name))) _count = 2;
						}
					break;}
				}
				if (_count > 0) {
					var _f = 0; repeat (array_length(_found)) {
						if (_found[_f].kind == _target.symbol.kind) && (_found[_f].name == _target.name) break;
					_f++}
					if (_f < array_length(_found)) {
						_found[_f].count += _count;
					}
					else {
						array_push(_found, { kind: _target.symbol.kind, name: _target.name, node: _target, count: _count });
					}
				}
			}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__accumulators(_child, _found);
				}
			_i++}
		_field_index++}
	};
	
	#region jsDoc
	/// @func    __names(_node, _kind, _name)
	/// @desc    Whether a node is a name of a symbol kind.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _kind : The symbol kind
	/// @param   {String}         _name : The name
	/// @returns {Bool}
	#endregion
	static __names = function(_node, _kind, _name) {
		return (_node.kind == __GMLC_NodeKind_Identifier) && (_node.symbol != undefined) && (_node.symbol.kind == _kind) && (_node.name == _name);
	};
	
	#region jsDoc
	/// @func    __occurrences(_node, _acc)
	/// @desc    How many times a variable is named under a node, nested functions left out.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _acc  : The variable
	/// @returns {Real}
	#endregion
	static __occurrences = function(_node, _acc) {
		if (__gmlc_opt_is_function(_node)) return 0;
		if (_node.kind == __GMLC_NodeKind_Identifier) return __names(_node, _acc.kind, _acc.name) ? 1 : 0;
		var _n = 0;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					_n += __occurrences(_child, _acc);
				}
			_i++}
		_field_index++}
		return _n;
	};
	
	#region jsDoc
	/// @func    __initial(_body, _k, _acc, _state)
	/// @desc    What the variable holds before the loop: the kind of the value of the last plain assignment to it in
	///          the run of assignments right before the loop, 0 when there is none.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Array<Struct.ASTNode>} _body  : The statements
	/// @param   {Real}                  _k     : The loop's place
	/// @param   {Struct}                _acc   : The variable
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Real}
	#endregion
	static __initial = function(_body, _k, _acc, _state) {
		var _j = _k - 1;
		while (_j >= 0) {
			var _statement = _body[_j];
			if (_statement.kind != __GMLC_NodeKind_ExprStmt) || (_statement.expression.kind != __GMLC_NodeKind_Assign) || (_statement.expression.op != "=") return 0;
			var _target = _statement.expression.target;
			if (_target.kind != __GMLC_NodeKind_Identifier) return 0;
			if (__names(_target, _acc.kind, _acc.name)) return __gmlc_opt_value_kind(_statement.expression.value, _state.kinds, _state.cx);
			_j--;
		}
		return 0;
	};
	
	#region jsDoc
	/// @func    __quiet(_node)
	/// @desc    Whether the code under a node stays inside the function and calls only pure built-ins: no `with`, no
	///          other call, no `try`, no `throw`, `return`, `exit` or `delete`. Nested functions are not run by it.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __quiet = function(_node) {
		if (__gmlc_opt_is_function(_node)) return true;
		switch (_node.kind) {
			case __GMLC_NodeKind_With:
			case __GMLC_NodeKind_MethodCall:
			case __GMLC_NodeKind_New:
			case __GMLC_NodeKind_Try:
			case __GMLC_NodeKind_Throw:
			case __GMLC_NodeKind_Return:
			case __GMLC_NodeKind_Exit:
			case __GMLC_NodeKind_Delete:
			return false;
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) || (__gmlc_opt_call_class(_name) != "pure") return false;
			break;}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__quiet(_child)) return false;
				}
			_i++}
		_field_index++}
		return true;
	};
	
	#region jsDoc
	/// @func    __range(_body, _k, _state)
	/// @desc    The array reads the loop at an index of a statement list keeps inside the array: for
	///          `var _n = array_length(_a); ... for (var _i = 0; _i < _n; _i++)` with nothing between them or in the loop
	///          changing `_a`, `_n` or `_i`, the reads `_a[_i]`.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Array<Struct.ASTNode>} _body  : The statements
	/// @param   {Real}                  _k     : The loop's place
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Struct|Undefined} {array, index}
	#endregion
	static __range = function(_body, _k, _state) {
		var _loop = _body[_k];
		if (_loop.kind != __GMLC_NodeKind_For) return undefined;
		var _init = _loop.init;
		var _test = _loop.test;
		var _update = _loop.update;
		if (_init == undefined) || (_test == undefined) || (_update == undefined) return undefined;
		if (_init.kind != __GMLC_NodeKind_VarDeclList) || (array_length(_init.declarations) != 1) return undefined;
		var _start = _init.declarations[0].init;
		if (_start == undefined) || (_start.kind != __GMLC_NodeKind_Literal) || (_start.ty != "real") return undefined;
		if (_start.value < 0) || (_start.value != floor(_start.value)) return undefined;
		var _index = _init.declarations[0].target.name;
		if (_test.kind != __GMLC_NodeKind_Binary) || (_test.op != "<") return undefined;
		if (!__gmlc_opt_is_local(_test.left)) || (_test.left.name != _index) || (!__gmlc_opt_is_local(_test.right)) return undefined;
		var _limit = _test.right.name;
		if (_update.kind != __GMLC_NodeKind_ExprStmt) || (_update.expression.kind != __GMLC_NodeKind_Update) return undefined;
		var _step = _update.expression;
		if (_step.op != "++") || (!__gmlc_opt_is_local(_step.argument)) || (_step.argument.name != _index) return undefined;
		// the declaration and the step are its only writes
		if (__writes(_loop, _index) != 2) return undefined;
		if (__writes(_state.root, _limit, true) != 1) return undefined;
		var _j = _k - 1;
		var _source = undefined;
		while (_j >= 0) {
			var _statement = _body[_j];
			if (_statement.kind == __GMLC_NodeKind_VarDeclList) && (array_length(_statement.declarations) == 1) && (_statement.declarations[0].target.name == _limit) {
				_source = _statement.declarations[0];
				break;
			}
			if (__uses(_statement, _limit) > 0) return undefined;
			_j--;
		}
		if (_source == undefined) || (_source.init == undefined) return undefined;
		var _call = _source.init;
		if (__gmlc_opt_builtin_call(_call) != "array_length") || (array_length(_call.args) != 1) || (!__gmlc_opt_is_local(_call.args[0])) return undefined;
		var _array = _call.args[0].name;
		if (__writes(_loop, _array) > 0) return undefined;
		var _m = _j + 1; repeat (_k - _j - 1) {
			if (!__quiet(_body[_m])) || (__writes(_body[_m], _array) > 0) return undefined;
		_m++}
		return { array: _array, index: _index };
	};
	
	#region jsDoc
	/// @func    __sound(_node, _state, _x)
	/// @desc    Whether the statements under a node cannot throw: assignments to locals, to the variables kept in
	///          temporaries and plain ones to any other variable, `if`, loops and `switch` with conditions that cannot
	///          throw, and `break` and `continue`.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Struct.ASTNode} _node  : The statement
	/// @param   {Struct}         _state : The pass's state
	/// @param   {Struct}         _x     : {kept, range}: the variables kept in temporaries and the array reads inside
	///                                   the array
	/// @returns {Bool}
	#endregion
	static __sound = function(_node, _state, _x) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Block:
			case __GMLC_NodeKind_Case:
			case __GMLC_NodeKind_Default: {
				if (_node.kind == __GMLC_NodeKind_Case) && (!__condition(_node.test, _state, _x)) return false;
				var _i = 0; repeat (array_length(_node.body)) {
					if (!__sound(_node.body[_i], _state, _x)) return false;
				_i++}
				return true;
			}
			case __GMLC_NodeKind_Break:
			case __GMLC_NodeKind_Continue:
			case __GMLC_NodeKind_Empty:
			return true;
			case __GMLC_NodeKind_ExprStmt: return __effect(_node.expression, _state, _x);
			case __GMLC_NodeKind_VarDeclList: {
				var _d = 0; repeat (array_length(_node.declarations)) {
					var _init = _node.declarations[_d].init;
					if (_init != undefined) && (!__gmlc_opt_safe_value(_init, _state.kinds, _state.cx, _x)) return false;
				_d++}
				return true;
			}
			case __GMLC_NodeKind_If: {
				if (!__condition(_node.test, _state, _x)) || (!__sound(_node.consequent, _state, _x)) return false;
				return (_node.alternate == undefined) || (__sound(_node.alternate, _state, _x));
			}
			case __GMLC_NodeKind_For: {
				if (_node.init != undefined) && (!__sound(_node.init, _state, _x)) return false;
				if (_node.test != undefined) && (!__condition(_node.test, _state, _x)) return false;
				if (_node.update != undefined) && (!__sound(_node.update, _state, _x)) return false;
				return __sound(_node.body, _state, _x);
			}
			case __GMLC_NodeKind_While: return __condition(_node.test, _state, _x) && __sound(_node.body, _state, _x);
			case __GMLC_NodeKind_Repeat: return __condition(_node.count, _state, _x) && __sound(_node.body, _state, _x);
			case __GMLC_NodeKind_DoUntil: return __sound(_node.body, _state, _x) && __condition(_node.test, _state, _x);
			case __GMLC_NodeKind_Switch: {
				if (!__gmlc_opt_safe_value(_node.discriminant, _state.kinds, _state.cx, _x)) return false;
				var _c = 0; repeat (array_length(_node.cases)) {
					if (!__sound(_node.cases[_c], _state, _x)) return false;
				_c++}
				return true;
			}
		}
		return false;
	};
	
	#region jsDoc
	/// @func    __condition(_node, _state, _x)
	/// @desc    Whether an expression cannot throw and holds a number or a bool.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Struct.ASTNode} _node  : The expression
	/// @param   {Struct}         _state : The pass's state
	/// @param   {Struct}         _x     : The variables kept in temporaries and the array reads inside the array
	/// @returns {Bool}
	#endregion
	static __condition = function(_node, _state, _x) {
		return __gmlc_opt_safe_value(_node, _state.kinds, _state.cx, _x) && (__gmlc_opt_value_kind(_node, _state.kinds, _state.cx, _x) != 0);
	};
	
	#region jsDoc
	/// @func    __effect(_node, _state, _x)
	/// @desc    Whether an expression statement cannot throw: an assignment to a local, to a variable kept in a
	///          temporary or, with `=`, to any other variable; an increment or decrement of a local; a pure call.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Struct.ASTNode} _node  : The expression
	/// @param   {Struct}         _state : The pass's state
	/// @param   {Struct}         _x     : The variables kept in temporaries and the array reads inside the array
	/// @returns {Bool}
	#endregion
	static __effect = function(_node, _state, _x) {
		var _kinds = _state.kinds;
		var _cx = _state.cx;
		switch (_node.kind) {
			case __GMLC_NodeKind_Call: return __gmlc_opt_safe_value(_node, _kinds, _cx, _x);
			case __GMLC_NodeKind_Update: return __gmlc_opt_is_local(_node.argument) && (__gmlc_opt_value_kind(_node.argument, _kinds, _cx, _x) != 0);
			case __GMLC_NodeKind_Assign: {
				var _target = _node.target;
				if (_target.kind != __GMLC_NodeKind_Identifier) || (_target.symbol == undefined) return false;
				if (!__gmlc_opt_safe_value(_node.value, _kinds, _cx, _x)) return false;
				if (_node.op == "=") return true;
				if (_node.op == "??=") return false;
				var _held = __gmlc_opt_is_local(_target) || (struct_exists(_x.kept, _target.symbol.kind + ":" + _target.name));
				return _held && (__gmlc_opt_value_kind(_target, _kinds, _cx, _x) != 0) && (__gmlc_opt_value_kind(_node.value, _kinds, _cx, _x) != 0);
			}
		}
		return false;
	};
	
	#region jsDoc
	/// @func    __replace(_node, _acc, _name)
	/// @desc    Puts a local in the place of every name of a variable under a node, nested functions left out, without
	///          changing the node.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _acc  : The variable
	/// @param   {String}         _name : The local
	/// @returns {Struct.ASTNode|Undefined} The new node, undefined when nothing changed
	#endregion
	static __replace = function(_node, _acc, _name) {
		if (__gmlc_opt_is_function(_node)) return undefined;
		if (_node.kind == __GMLC_NodeKind_Identifier) {
			return __names(_node, _acc.kind, _acc.name) ? __gmlc_opt_local(_name, _node.span) : undefined;
		}
		var _slots = _node.childSlots();
		var _edits = [];
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new = __replace(_slot.node, _acc, _name);
			if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
		_i++}
		if (array_length(_edits) == 0) return undefined;
		return __gmlc_opt_rebuild_children(_node, _edits);
	};
	#endregion
	
	#region Counting
	#region jsDoc
	/// @func    __uses(_node, _name)
	/// @desc    How many times a local is named under a node, nested functions left out.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The local
	/// @returns {Real}
	#endregion
	static __uses = function(_node, _name) {
		if (__gmlc_opt_is_function(_node)) return 0;
		if (_node.kind == __GMLC_NodeKind_Identifier) return (__gmlc_opt_is_local(_node) && (_node.name == _name)) ? 1 : 0;
		var _n = 0;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					_n += __uses(_child, _name);
				}
			_i++}
		_field_index++}
		return _n;
	};
	
	#region jsDoc
	/// @func    __writes(_node, _name, [_isRoot])
	/// @desc    How many times a local is written under a node: assigned, declared, incremented or decremented, or
	///          written through an element or a member, nested functions left out.
	/// @self    GMLC_Opt_ReductionRecognize
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {String}         _name   : The local
	/// @param   {Bool}           [_isRoot] : Whether the node is the function itself
	/// @returns {Real}
	#endregion
	static __writes = function(_node, _name, _isRoot = false) {
		if (!_isRoot) && (__gmlc_opt_is_function(_node)) return 0;
		var _n = 0;
		var _target = undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Assign: _target = _node.target; break;
			case __GMLC_NodeKind_Update: _target = _node.argument; break;
			case __GMLC_NodeKind_VarDecl: if (_node.target.name == _name) _n++; break;
		}
		if (_target != undefined) {
			while (_target.kind == __GMLC_NodeKind_Index) {
				_target = _target.object;
			}
			if (__gmlc_opt_is_local(_target)) && (_target.name == _name) _n++;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					_n += __writes(_child, _name);
				}
			_i++}
		_field_index++}
		return _n;
	};
	
	#endregion
	
}
