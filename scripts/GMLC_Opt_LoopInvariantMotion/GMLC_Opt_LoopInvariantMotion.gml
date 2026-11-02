#region jsDoc
/// @func    GMLC_Opt_LoopInvariantMotion()
/// @desc    The `loop-invariant-motion` optimizer pass: an expression a loop evaluates to the same value on every trip,
///          that cannot throw, is computed once in a temporary before the loop.
///          `for (...) { f(sprite_width * 2 + _i); }` becomes `var _t = sprite_width * 2; for (...) { f(_t + _i); }`.
/// @returns {Struct.GMLC_Opt_LoopInvariantMotion}
#endregion
function GMLC_Opt_LoopInvariantMotion() : GMLC_OptimizerPass("loop-invariant-motion") constructor {
	#region Init
	#endregion
	
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with the invariant expressions of its loops moved out, or undefined when none moves.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _state = { cx: _cx, optimizer: _cx.optimizer, root: _node, kinds: undefined, in_with: 0 };
		return __walk(_node, _state, true);
	};
	#endregion
	
	#region Walk
	#region jsDoc
	/// @func    __walk(_node, _state, _isRoot)
	/// @desc    Moves the invariant code out of every loop under a node, outer loops first, nested functions and
	///          frozen code left out, without changing the node.
	/// @self    GMLC_Opt_LoopInvariantMotion
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
			// the body of a `with` runs with another `self`
			var _inside = (_current.kind == __GMLC_NodeKind_With) && (_slot.key == "body") && (__gmlc_opt_self_unknown(_current));
			if (_inside) _state.in_with++;
			var _new = __walk(_slot.node, _state, false);
			if (_inside) _state.in_with--;
			if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
		_i++}
		if (array_length(_edits) == 0) return (_current == _node) ? undefined : _current;
		return __gmlc_opt_rebuild_children(_current, _edits);
	};
	
	#region jsDoc
	/// @func    __list(_body, _state)
	/// @desc    Puts the temporaries of each loop of a statement list in front of the loop.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {Array<Struct.ASTNode>} _body  : The statements
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list, undefined when nothing changed
	#endregion
	static __list = function(_body, _state) {
		var _out = undefined;
		var _i = 0; repeat (array_length(_body)) {
			var _statement = _body[_i];
			var _hit = __gmlc_opt_is_loop(_statement) ? __hoist(_statement, _state) : undefined;
			if (_hit == undefined) {
				if (_out != undefined) array_push(_out, _statement);
			}
			else {
				if (_out == undefined) {
					_out = array_create(_i);
					array_copy(_out, 0, _body, 0, _i);
				}
				array_copy(_out, array_length(_out), _hit.decls, 0, array_length(_hit.decls));
				array_push(_out, _hit.loop);
			}
		_i++}
		return _out;
	};
	#endregion
	
	#region Hoisting
	#region jsDoc
	/// @func    __hoist(_loop, _state)
	/// @desc    The loop with its invariant expressions replaced by temporaries, and the declarations of the
	///          temporaries.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {Struct.ASTNode} _loop  : The loop
	/// @param   {Struct}         _state : The pass's state
	/// @returns {Struct|Undefined} {decls, loop}, undefined when nothing moves
	#endregion
	static __hoist = function(_loop, _state) {
		var _cx = _state.cx;
		var _optimizer = _state.optimizer;
		var _facts = { written: {}, has_with: false, has_unknown: false, has_render: false, writes_state: false, writes_index: false, frozen: false };
		__facts(_loop, _facts, _optimizer);
		if (_facts.frozen) return undefined;
		if (_state.kinds == undefined) _state.kinds = __gmlc_opt_local_value_kinds(_state.root, _cx);
		var _clean = (!_facts.has_with) && (!_facts.has_unknown) && (!_facts.writes_state);
		var _scan = { cx: _cx, optimizer: _optimizer, facts: _facts, kinds: _state.kinds, builtins_ok: _clean, observers_ok: _clean && (!_facts.has_render) && (!_facts.writes_index), exprs: [], names: [], extra: { kept: {}, range: undefined, in_with: (_state.in_with > 0) } };
		var _slots = _loop.childSlots();
		var _edits = [];
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			// `init` runs once and `repeat` evaluates its count once
			if (_slot.key != "init") && (_slot.key != "count") {
				var _new = __scan(_slot.node, _scan);
				if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
			}
		_i++}
		if (array_length(_edits) == 0) return undefined;
		var _span = new GMLC_Span(_loop.span.file, _loop.span.start, _loop.span.start);
		var _decls = [];
		var _t = 0; repeat (array_length(_scan.exprs)) {
			var _expr = _scan.exprs[_t];
			if (_cx.preserve_lines) {
				_expr = __gmlc_opt_clone(_expr);
				__respan(_expr, _span);
			}
			array_push(_decls, __gmlc_opt_var(_scan.names[_t], _expr, _span));
			_cx.stats[$ "hoisted"]++;
		_t++}
		return { decls: _decls, loop: __gmlc_opt_rebuild_children(_loop, _edits) };
	};
	
	#region jsDoc
	/// @func    __respan(_node, _span)
	/// @desc    Puts a span on a node and everything under it, so the emitter prints it on one line.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {Struct.ASTNode}   _node : The node
	/// @param   {Struct.GMLC_Span} _span : The span
	#endregion
	static __respan = function(_node, _span) {
		_node.span = _span;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__respan(_child, _span);
				}
			_i++}
		_field_index++}
	};
	
	#region jsDoc
	/// @func    __scan(_node, _scan)
	/// @desc    Replaces the invariant expressions under a node by temporaries, largest first, without changing the
	///          node. A statement's own expression and the body of a `with` stay.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _scan : The loop's facts and the temporaries so far
	/// @returns {Struct.ASTNode|Undefined} The new node, undefined when nothing changed
	#endregion
	static __scan = function(_node, _scan) {
		if (__gmlc_opt_is_function(_node)) return undefined;
		if (_node.kind == __GMLC_NodeKind_ExprStmt) {
			var _inner = __scanChildren(_node.expression, _scan);
			if (_inner == undefined) return undefined;
			return __gmlc_opt_rebuild_children(_node, [{ key: "expression", index: undefined, node: _inner }]);
		}
		if (__candidate(_node, _scan)) return __temp(_node, _scan);
		return __scanChildren(_node, _scan);
	};
	
	#region jsDoc
	/// @func    __scanChildren(_node, _scan)
	/// @desc    Runs __scan on the children of a node and rebuilds the node when one changed.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _scan : The loop's facts and the temporaries so far
	/// @returns {Struct.ASTNode|Undefined} The new node, undefined when nothing changed
	#endregion
	static __scanChildren = function(_node, _scan) {
		var _slots = _node.childSlots();
		var _edits = [];
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			if (_node.kind != __GMLC_NodeKind_With) || (_slot.key != "body") {
				var _new = __scan(_slot.node, _scan);
				if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
			}
		_i++}
		if (array_length(_edits) == 0) return undefined;
		return __gmlc_opt_rebuild_children(_node, _edits);
	};
	
	#region jsDoc
	/// @func    __temp(_node, _scan)
	/// @desc    The temporary that holds an expression: the one made for the same code before, else a new one.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _scan : The loop's facts and the temporaries so far
	/// @returns {Struct.ASTIdentifier}
	#endregion
	static __temp = function(_node, _scan) {
		var _t = 0; repeat (array_length(_scan.exprs)) {
			if (__gmlc_opt_same(_scan.exprs[_t], _node)) return __gmlc_opt_local(_scan.names[_t], _node.span);
		_t++}
		var _name = _scan.optimizer.newTemporary(_scan.cx);
		_scan.kinds[$ _name] = __gmlc_opt_value_kind(_node, _scan.kinds, _scan.cx);
		array_push(_scan.exprs, _node);
		array_push(_scan.names, _name);
		return __gmlc_opt_local(_name, _node.span);
	};
	
	#region jsDoc
	/// @func    __candidate(_node, _scan)
	/// @desc    Whether an expression is worth a temporary: an operator or a call with a variable in it, or a built-in
	///          variable of the engine (each read calls into the runner), the same on every trip, that cannot throw
	///          and whose value a statement can hold.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _scan : The loop's facts and the temporaries so far
	/// @returns {Bool}
	#endregion
	static __candidate = function(_node, _scan) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Binary:
			case __GMLC_NodeKind_Logical:
			case __GMLC_NodeKind_Conditional:
			break;
			case __GMLC_NodeKind_Unary: {
				var _argument = _node.argument;
				if (_argument.kind == __GMLC_NodeKind_Literal) || (_argument.kind == __GMLC_NodeKind_Identifier) return false;
			break;}
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) || ((__gmlc_opt_builtin_code(_name) & 4) != 0) return false;
			break;}
			case __GMLC_NodeKind_Identifier: {
				if (_node.symbol == undefined) || (_node.symbol.kind != "BuiltinVar") return false;
			break;}
			default: return false;
		}
		if (!__varies(_node)) return false;
		if (!__invariant(_node, _scan)) return false;
		return __gmlc_opt_safe_value(_node, _scan.kinds, _scan.cx, _scan.extra);
	};
	
	#region jsDoc
	/// @func    __varies(_node)
	/// @desc    Whether an expression reads a local or a built-in variable, so it is not a constant to fold.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __varies = function(_node) {
		if (_node.kind == __GMLC_NodeKind_Identifier) {
			if (_node.symbol == undefined) return false;
			return (_node.symbol.kind == "Local") || (_node.symbol.kind == "BuiltinVar") || ((_node.symbol.kind == "Self") && (__gmlc_opt_builtin_variable(_node.name) != undefined));
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__varies(_child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};
	
	#region jsDoc
	/// @func    __invariant(_node, _scan)
	/// @desc    Whether an expression has the same value on every trip of the loop: its locals are not written in the
	///          loop, its built-in variables need a loop that cannot change instance state, and a built-in that reads
	///          engine state needs a loop that cannot change that either.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _scan : The loop's facts and the temporaries so far
	/// @returns {Bool}
	#endregion
	static __invariant = function(_node, _scan) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: return true;
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				if (_symbol == undefined) return false;
				switch (_symbol.kind) {
					case "Local": return !struct_exists(_scan.facts.written, _node.name);
					case "BuiltinConstant": case "Enum": case "Asset": case "Macro": return true;
					case "BuiltinVar": return _scan.builtins_ok && __stable(_node.name);
					case "Self": return _scan.builtins_ok && (!_scan.extra.in_with) && __gmlc_opt_reads_instance_builtin(_scan.cx, _node) && __stable(_node.name);
				}
				return false;
			}
			case __GMLC_NodeKind_Binary:
			case __GMLC_NodeKind_Logical:
			return __invariant(_node.left, _scan) && __invariant(_node.right, _scan);
			case __GMLC_NodeKind_Unary: return __invariant(_node.argument, _scan);
			case __GMLC_NodeKind_Conditional: return __invariant(_node.test, _scan) && __invariant(_node.consequent, _scan) && __invariant(_node.alternate, _scan);
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) return false;
				var _effects = __GmlcDataEffects();
				var _entry = _effects[$ _name];
				if (_entry == undefined) || (_entry.nondeterministic) return false;
				if (_entry.class == "observer") {
					if (!_scan.observers_ok) return false;
				}
				else if (_entry.class != "pure") {
					return false;
				}
				var _i = 0; repeat (array_length(_node.args)) {
					if (_node.args[_i] == undefined) || (!__invariant(_node.args[_i], _scan)) return false;
				_i++}
				return true;
			}
		}
		return false;
	};
	
	#region jsDoc
	/// @func    __stable(_name)
	/// @desc    Whether a built-in variable keeps its value while the code runs, unless the code writes it: the real
	///          instance variables and the size and speed of the room.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {String} _name : The variable
	/// @returns {Bool}
	#endregion
	static __stable = function(_name) {
		return __gmlc_opt_is_real_instance(_name) || (_name == "room_width") || (_name == "room_height") || (_name == "room_speed");
	};
	#endregion
	
	#region Loop facts
	#region jsDoc
	/// @func    __facts(_node, _facts, _optimizer)
	/// @desc    Collects what a loop does: the locals it writes, and whether it has a `with`, a call that could change
	///          anything, a draw call, a write to instance, global or array state, or frozen code.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {Struct.ASTNode} _node      : The loop or a part of it
	/// @param   {Struct}         _facts     : The facts so far
	/// @param   {Struct}         _optimizer : The optimizer
	#endregion
	static __facts = function(_node, _facts, _optimizer) {
		if (__gmlc_opt_is_function(_node)) return;
		if (_optimizer.has_no_op_targets) && (_optimizer.__isNoOp(_node)) _facts.frozen = true;
		switch (_node.kind) {
			case __GMLC_NodeKind_With: _facts.has_with = true; break;
			case __GMLC_NodeKind_MethodCall:
			case __GMLC_NodeKind_New:
			_facts.has_unknown = true;
			break;
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) {
					_facts.has_unknown = true;
				}
				else {
					var _class = __gmlc_opt_call_class(_name);
					if (_class == "render") {
						_facts.has_render = true;
					}
					else if (_class != "pure") && (_class != "observer") {
						_facts.has_unknown = true;
					}
				}
			break;}
			case __GMLC_NodeKind_Assign: __target(_node.target, _facts); break;
			case __GMLC_NodeKind_Update: __target(_node.argument, _facts); break;
			case __GMLC_NodeKind_VarDecl: _facts.written[$ _node.target.name] = true; break;
			case __GMLC_NodeKind_Try: {
				if (_node.catch_param != undefined) _facts.written[$ _node.catch_param.name] = true;
			break;}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__facts(_child, _facts, _optimizer);
				}
			_i++}
		_field_index++}
	};
	
	#region jsDoc
	/// @func    __target(_target, _facts)
	/// @desc    Records what a write to a target changes: a local, the array or data structure a local holds, or
	///          instance, global and member state.
	/// @self    GMLC_Opt_LoopInvariantMotion
	/// @param   {Struct.ASTNode} _target : The target of an assignment, an increment or a decrement
	/// @param   {Struct}         _facts  : The facts so far
	#endregion
	static __target = function(_target, _facts) {
		var _bracket = true;
		while (_target.kind == __GMLC_NodeKind_Index) {
			_facts.writes_index = true;
			if (_target.accessor == "Dot") || (_target.accessor == "Struct") _bracket = false;
			_target = _target.object;
		}
		if (__gmlc_opt_is_local(_target)) {
			_facts.written[$ _target.name] = true;
			if (!_bracket) _facts.writes_state = true;
		}
		else {
			_facts.writes_state = true;
		}
	};
	#endregion
	
}
