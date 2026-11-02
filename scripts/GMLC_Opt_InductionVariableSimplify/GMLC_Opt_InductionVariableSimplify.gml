#region jsDoc
/// @func    GMLC_Opt_InductionVariableSimplify()
/// @desc    The `induction-variable-simplify` optimizer pass: a local that gains the loop counter's step on every trip of
///          a `for` loop, and is not read after the loop, is replaced by the counter plus a constant, and its
///          declaration and step are removed.
///          `var _slot = 0; for (var _i = 0; _i < 8; _i++) { f(_slot); _slot += 1; }` becomes
///          `for (var _i = 0; _i < 8; _i++) { f(_i); }`.
/// @returns {Struct.GMLC_Opt_InductionVariableSimplify}
#endregion
function GMLC_Opt_InductionVariableSimplify() : GMLC_OptimizerPass("induction-variable-simplify") constructor {
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with its derived counters removed, or undefined when it has none.
	/// @self    GMLC_Opt_InductionVariableSimplify
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _state = { cx: _cx, optimizer: _cx.optimizer, root: _node };
		return __walk(_node, _state, true);
	};
	#endregion
	
	#region Walk
	#region jsDoc
	/// @func    __walk(_node, _state, _isRoot)
	/// @desc    Simplifies the `for` loops under a node, outer loops first, nested functions and frozen code left out,
	///          without changing the node.
	/// @self    GMLC_Opt_InductionVariableSimplify
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
			var _new = __walk(_slot.node, _state, false);
			if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
		_i++}
		if (array_length(_edits) == 0) return (_current == _node) ? undefined : _current;
		return __gmlc_opt_rebuild_children(_current, _edits);
	};
	
	#region jsDoc
	/// @func    __list(_body, _state)
	/// @desc    Removes the derived counters of the `for` loops of a statement list, with their declarations.
	/// @self    GMLC_Opt_InductionVariableSimplify
	/// @param   {Array<Struct.ASTNode>} _body  : The statements
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list, undefined when nothing changed
	#endregion
	static __list = function(_body, _state) {
		var _work = _body;
		var _changed = false;
		var _k = 0; repeat (array_length(_body)) {
			if (_body[_k].kind == __GMLC_NodeKind_For) {
				var _again = true;
				while (_again) {
					var _hit = __induction(_work, _k, _state);
					if (_hit == undefined) {
						_again = false;
					}
					else {
						if (!_changed) {
							_work = variable_clone(_body, 0);
							_changed = true;
						}
						_work[_k] = _hit.loop;
						_work[_hit.drop] = undefined;
					}
				}
			}
		_k++}
		if (!_changed) return undefined;
		var _out = [];
		var _i = 0; repeat (array_length(_work)) {
			if (_work[_i] != undefined) array_push(_out, _work[_i]);
		_i++}
		return _out;
	};
	#endregion
	
	#region Induction
	#region jsDoc
	/// @func    __induction(_list, _k, _state)
	/// @desc    Removes one derived counter of the `for` loop at an index of a statement list: a local that gains the
	///          counter's step in a statement of the loop body.
	/// @self    GMLC_Opt_InductionVariableSimplify
	/// @param   {Array<Struct.ASTNode>} _list  : The statements, with undefined for the ones already removed
	/// @param   {Real}                  _k     : The loop's place
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Struct|Undefined} {loop, drop}: the new loop and the place of the statement to remove, undefined when
	///                             no counter goes
	#endregion
	static __induction = function(_list, _k, _state) {
		var _loop = _list[_k];
		var _optimizer = _state.optimizer;
		if (_optimizer.has_no_op_targets) && (_optimizer.__containsNoOp(_loop)) return undefined;
		var _counter = __counter(_loop);
		if (_counter == undefined) return undefined;
		if (__writes(_loop.body, _counter.name) > 0) return undefined;
		if (_loop.test != undefined) && (__writes(_loop.test, _counter.name) > 0) return undefined;
		var _statements = _loop.body.body;
		var _p = 0; repeat (array_length(_statements)) {
			var _step = __step(_statements[_p]);
			if (_step != undefined) && (_step.name != _counter.name) && (_step.delta == _counter.step) {
				var _hit = __derive(_list, _k, _counter, _step, _p, _state);
				if (_hit != undefined) return _hit;
			}
		_p++}
		return undefined;
	};
	
	#region jsDoc
	/// @func    __derive(_list, _k, _counter, _step, _p, _state)
	/// @desc    Replaces a local that gains the counter's step with the counter plus a constant, when it can be
	///          proven to move in lock-step and nothing else uses it.
	/// @self    GMLC_Opt_InductionVariableSimplify
	/// @param   {Array<Struct.ASTNode>} _list    : The statements around the loop
	/// @param   {Real}                  _k       : The loop's place
	/// @param   {Struct}                _counter : {name, start, step} of the loop counter
	/// @param   {Struct}                _step    : {name, delta} of the local
	/// @param   {Real}                  _p       : The place of the local's step in the loop body
	/// @param   {Struct}                _state   : The pass's state
	/// @returns {Struct|Undefined} {loop, drop}
	#endregion
	static __derive = function(_list, _k, _counter, _step, _p, _state) {
		var _loop = _list[_k];
		var _name = _step.name;
		var _optimizer = _state.optimizer;
		// the one write in the loop is the step; outside it the local has only its first value
		if (__writes(_loop, _name) != 1) return undefined;
		if (__uses(_state.root, _name, true) - __uses(_loop, _name) != 1) return undefined;
		var _found = -1;
		var _j = _k - 1;
		while (_j >= 0) {
			if (_list[_j] != undefined) && (__uses(_list[_j], _name) > 0) {
				_found = _j;
				break;
			}
			_j--;
		}
		if (_found < 0) return undefined;
		var _first = __first(_list[_found], _name);
		if (_first == undefined) return undefined;
		if (_optimizer.has_no_op_targets) && (_optimizer.__containsNoOp(_list[_found])) return undefined;
		if (__uses(_loop.init, _name) > 0) || (__uses(_loop.update, _name) > 0) return undefined;
		var _statements = _loop.body.body;
		var _i = 0; repeat (_p) {
			if (__continues(_statements[_i])) return undefined;
		_i++}
		var _before = _first - _counter.start;
		var _after = _before + _step.delta;
		var _moved = 0;
		if (_before != 0) {
			_moved += (_loop.test != undefined) ? __uses(_loop.test, _name) : 0;
			_i = 0; repeat (_p) {
				_moved += __uses(_statements[_i], _name);
			_i++}
		}
		if (_after != 0) {
			_i = _p + 1; repeat (array_length(_statements) - _p - 1) {
				_moved += __uses(_statements[_i], _name);
			_i++}
		}
		if (_moved > 1) return undefined;
		if (_before != 0) && (_optimizer.__literal(abs(_before), _loop.span) == undefined) return undefined;
		if (_after != 0) && (_optimizer.__literal(abs(_after), _loop.span) == undefined) return undefined;
		var _plan = { optimizer: _optimizer, name: _name, counter: _counter.name, offset: _before };
		var _edits = [];
		if (_loop.test != undefined) {
			var _test = __replace(_loop.test, _plan);
			if (_test != undefined) array_push(_edits, { key: "test", index: undefined, node: _test });
		}
		var _body = [];
		_i = 0; repeat (array_length(_statements)) {
			if (_i != _p) {
				_plan.offset = (_i < _p) ? _before : _after;
				var _new = __replace(_statements[_i], _plan);
				array_push(_body, (_new != undefined) ? _new : _statements[_i]);
			}
		_i++}
		array_push(_edits, { key: "body", index: undefined, node: __gmlc_opt_rebuild_children(_loop.body, [{ key: "body", index: undefined, node: _body }]) });
		_state.cx.stats[$ "ivs_removed"]++;
		return { loop: __gmlc_opt_rebuild_children(_loop, _edits), drop: _found };
	};
	
	#region jsDoc
	/// @func    __replace(_node, _plan)
	/// @desc    Puts the counter plus the offset in the place of every read of the derived local under a node, nested
	///          functions left out, without changing the node.
	/// @self    GMLC_Opt_InductionVariableSimplify
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _plan : {optimizer, name, counter, offset}
	/// @returns {Struct.ASTNode|Undefined} The new node, undefined when nothing changed
	#endregion
	static __replace = function(_node, _plan) {
		if (__gmlc_opt_is_function(_node)) return undefined;
		if (__gmlc_opt_is_local(_node)) {
			if (_node.name != _plan.name) return undefined;
			var _counter = __gmlc_opt_local(_plan.counter, _node.span);
			if (_plan.offset == 0) return _counter;
			var _offset = _plan.optimizer.__literal(abs(_plan.offset), _node.span);
			return new ASTBinary(_node.span, (_plan.offset > 0) ? "+" : "-", _counter, _offset);
		}
		var _slots = _node.childSlots();
		var _edits = [];
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new = __replace(_slot.node, _plan);
			if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
		_i++}
		if (array_length(_edits) == 0) return undefined;
		return __gmlc_opt_rebuild_children(_node, _edits);
	};
	#endregion
	
	#region Shapes
	#region jsDoc
	/// @func    __counter(_loop)
	/// @desc    The counter of a `for` loop that starts at a whole number and moves by a whole number on every trip:
	///          `for (var _i = 0; ...; _i++)`, `_i += 2`, `_i -= 1`.
	/// @self    GMLC_Opt_InductionVariableSimplify
	/// @param   {Struct.ASTNode} _loop : The loop
	/// @returns {Struct|Undefined} {name, start, step}
	#endregion
	static __counter = function(_loop) {
		var _init = _loop.init;
		var _update = _loop.update;
		if (_init == undefined) || (_update == undefined) return undefined;
		var _name;
		var _start;
		if (_init.kind == __GMLC_NodeKind_VarDeclList) {
			if (array_length(_init.declarations) != 1) return undefined;
			var _declaration = _init.declarations[0];
			if (_declaration.init == undefined) return undefined;
			_name = _declaration.target.name;
			_start = __whole(_declaration.init);
		}
		else if (_init.kind == __GMLC_NodeKind_ExprStmt) && (_init.expression.kind == __GMLC_NodeKind_Assign) && (_init.expression.op == "=") && (__gmlc_opt_is_local(_init.expression.target)) {
			_name = _init.expression.target.name;
			_start = __whole(_init.expression.value);
		}
		else {
			return undefined;
		}
		if (_start == undefined) return undefined;
		var _step = __step(_update);
		if (_step == undefined) || (_step.name != _name) return undefined;
		return { name: _name, start: _start, step: _step.delta };
	};
	
	#region jsDoc
	/// @func    __step(_statement)
	/// @desc    The local and the whole number a statement adds to it: `_i++`, `--_i`, `_i += 2`, `_i -= 1`.
	/// @self    GMLC_Opt_InductionVariableSimplify
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @returns {Struct|Undefined} {name, delta}
	#endregion
	static __step = function(_statement) {
		if (_statement.kind != __GMLC_NodeKind_ExprStmt) return undefined;
		var _expression = _statement.expression;
		if (_expression.kind == __GMLC_NodeKind_Update) && (__gmlc_opt_is_local(_expression.argument)) {
			return { name: _expression.argument.name, delta: (_expression.op == "++") ? 1 : -1 };
		}
		if (_expression.kind == __GMLC_NodeKind_Assign) && (__gmlc_opt_is_local(_expression.target)) && ((_expression.op == "+=") || (_expression.op == "-=")) {
			var _value = __whole(_expression.value);
			if (_value == undefined) || (_value == 0) return undefined;
			return { name: _expression.target.name, delta: (_expression.op == "+=") ? _value : -_value };
		}
		return undefined;
	};
	
	#region jsDoc
	/// @func    __whole(_node)
	/// @desc    The value of a real literal that is a whole number below 2^31 in size.
	/// @self    GMLC_Opt_InductionVariableSimplify
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Real|Undefined}
	#endregion
	static __whole = function(_node) {
		if (_node.kind != __GMLC_NodeKind_Literal) || (_node.ty != "real") return undefined;
		var _value = _node.value;
		if (_value != floor(_value)) || (abs(_value) >= 2147483648) return undefined;
		return _value;
	};
	
	#region jsDoc
	/// @func    __first(_statement, _name)
	/// @desc    The whole number a statement gives a local: `var _slot = 0;` or `_slot = 0;`.
	/// @self    GMLC_Opt_InductionVariableSimplify
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {String}         _name      : The local
	/// @returns {Real|Undefined}
	#endregion
	static __first = function(_statement, _name) {
		if (_statement.kind == __GMLC_NodeKind_VarDeclList) {
			if (array_length(_statement.declarations) != 1) return undefined;
			var _declaration = _statement.declarations[0];
			if (_declaration.target.name != _name) || (_declaration.init == undefined) return undefined;
			return __whole(_declaration.init);
		}
		if (_statement.kind == __GMLC_NodeKind_ExprStmt) && (_statement.expression.kind == __GMLC_NodeKind_Assign) {
			var _assign = _statement.expression;
			if (_assign.op == "=") && (__gmlc_opt_is_local(_assign.target)) && (_assign.target.name == _name) return __whole(_assign.value);
		}
		return undefined;
	};
	#endregion
	
	#region Counting
	#region jsDoc
	/// @func    __uses(_node, _name, [_isRoot])
	/// @desc    How many times a local is named under a node, as a read, a write or a declaration, nested functions
	///          left out.
	/// @self    GMLC_Opt_InductionVariableSimplify
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {String}         _name   : The local
	/// @param   {Bool}           [_isRoot] : Whether the node is the function itself
	/// @returns {Real}
	#endregion
	static __uses = function(_node, _name, _isRoot = false) {
		if (!_isRoot) && (__gmlc_opt_is_function(_node)) return 0;
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
	/// @func    __writes(_node, _name)
	/// @desc    How many times a local is written under a node: assigned, declared, incremented or decremented,
	///          nested functions left out.
	/// @self    GMLC_Opt_InductionVariableSimplify
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The local
	/// @returns {Real}
	#endregion
	static __writes = function(_node, _name) {
		if (__gmlc_opt_is_function(_node)) return 0;
		var _n = 0;
		switch (_node.kind) {
			case __GMLC_NodeKind_Assign: if (__gmlc_opt_is_local(_node.target)) && (_node.target.name == _name) _n++; break;
			case __GMLC_NodeKind_Update: if (__gmlc_opt_is_local(_node.argument)) && (_node.argument.name == _name) _n++; break;
			case __GMLC_NodeKind_VarDecl: if (_node.target.name == _name) _n++; break;
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
	
	#region jsDoc
	/// @func    __continues(_node)
	/// @desc    Whether a `continue` under a node ends a trip of the loop around it: the ones inside a loop of their
	///          own do not.
	/// @self    GMLC_Opt_InductionVariableSimplify
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __continues = function(_node) {
		if (_node.kind == __GMLC_NodeKind_Continue) return true;
		if (__gmlc_opt_is_function(_node)) || (__gmlc_opt_is_loop(_node)) return false;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__continues(_child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};
	
	#endregion
}
