#region jsDoc
/// @func    GMLC_Opt_WithInvariantMotion()
/// @desc    A call of a pure built-in that cannot fail, on literals and locals the `with` body does not write, is
///          computed once before the `with` and not once per instance: `with (obj_enemy) { d = abs(_dx); }` becomes
///          `var __gmlc_t0 = abs(_dx); with (obj_enemy) { d = __gmlc_t0; }`. The body must be quiet: no call but a
///          pure, observer or draw built-in, no method call, `new`, nested function, or write into an array or struct,
///          so nothing it does can change what a hoisted call reads.
/// @returns {Struct.GMLC_Opt_WithInvariantMotion}
#endregion
function GMLC_Opt_WithInvariantMotion() : GMLC_OptimizerPass("with-invariant-motion") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Moves the invariant calls out of the `with` statements of a function.
	/// @self    GMLC_Opt_WithInvariantMotion
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
	/// @desc    How many `with` statements of a node have a call to move, nested functions left out.
	/// @self    GMLC_Opt_WithInvariantMotion
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Real}
	#endregion
	static __count = function(_node, _cx) {
		var _n = 0;
		if (_node.kind == __GMLC_NodeKind_With) && (array_length(__found(_node, _cx)) > 0) _n++;
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
	/// @desc    Moves the invariant calls out of the `with` statements of a copy, in place, outer ones first, nested
	///          functions left out. A `with` that is not in a statement list becomes a block holding the new locals
	///          and itself.
	/// @self    GMLC_Opt_WithInvariantMotion
	/// @param   {Struct.ASTNode} _node : The node, a copy this pass owns
	/// @param   {Struct}         _cx   : The pass context
	#endregion
	static __rewrite = function(_node, _cx) {
		if (__gmlc_opt_is_statement_list(_node)) {
			var _old = _node.body;
			var _body = [];
			var _s = 0; repeat (array_length(_old)) {
				if (_old[_s].kind == __GMLC_NodeKind_With) {
					var _declarations = __hoist(_old[_s], _cx);
					array_copy(_body, array_length(_body), _declarations, 0, array_length(_declarations));
				}
				array_push(_body, _old[_s]);
			_s++}
			_node.body = _body;
		}
		else {
			var _slots = _node.childSlots();
			var _k = 0; repeat (array_length(_slots)) {
				var _slot = _slots[_k];
				if (_slot.node.kind == __GMLC_NodeKind_With) {
					var _hoisted = __hoist(_slot.node, _cx);
					if (array_length(_hoisted) > 0) {
						array_push(_hoisted, _slot.node);
						var _block = new ASTBlock(_slot.node.span, _hoisted);
						if (_slot.index == undefined) {
							_slot.parent[$ _slot.key] = _block;
						}
						else {
							_slot.parent[$ _slot.key][_slot.index] = _block;
						}
					}
				}
			_k++}
		}
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
	};

	#region jsDoc
	/// @func    __hoist(_with, _cx)
	/// @desc    Replaces the invariant calls in the body of a `with` (a copy this pass owns) by new locals and returns
	///          the declarations of those locals, in the order the calls first appear; empty when there is nothing
	///          to move.
	/// @self    GMLC_Opt_WithInvariantMotion
	/// @param   {Struct.ASTWith} _with : The statement
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Array<Struct.ASTNode>}
	#endregion
	static __hoist = function(_with, _cx) {
		var _found = __found(_with, _cx);
		var _declarations = [];
		if (array_length(_found) == 0) return _declarations;
		var _written = [];
		__written(_with, _written);
		var _names = [];
		var _f = 0; repeat (array_length(_found)) {
			array_push(_names, _cx.optimizer.newTemporary(_cx));
			_cx.stats[$ "hoisted"]++;
		_f++}
		__replace(_with.body, _found, _names, _written, _cx);
		_f = 0; repeat (array_length(_found)) {
			array_push(_declarations, __gmlc_opt_var(_names[_f], _found[_f], _found[_f].span));
		_f++}
		return _declarations;
	};

	#region jsDoc
	/// @func    __found(_with, _cx)
	/// @desc    The distinct calls in the body of a `with` that can move before it, in the order they first appear;
	///          none when the statement is frozen or its body is not quiet.
	/// @self    GMLC_Opt_WithInvariantMotion
	/// @param   {Struct.ASTWith} _with : The statement
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Array<Struct.ASTNode>}
	#endregion
	static __found = function(_with, _cx) {
		var _found = [];
		if (_cx.optimizer.__isNoOp(_with)) || (!__quiet(_with.body)) return _found;
		var _written = [];
		__written(_with, _written);
		__collect(_with.body, _written, _cx, _found);
		return _found;
	};

	#region jsDoc
	/// @func    __collect(_node, _written, _cx, _found)
	/// @desc    Adds the calls that can move to a list, each once, not looking inside one that moves.
	/// @self    GMLC_Opt_WithInvariantMotion
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {Array<String>}  _written : The locals the statement writes
	/// @param   {Struct}         _cx      : The pass context
	/// @param   {Array}          _found   : The calls so far, added to
	#endregion
	static __collect = function(_node, _written, _cx, _found) {
		if (__gmlc_opt_is_function(_node)) || (__is_dead_call(_node, _written, _cx)) return;
		if (__invariant(_node, _written, _cx)) {
			var _f = 0; repeat (array_length(_found)) {
				if (__gmlc_opt_same(_found[_f], _node)) return;
			_f++}
			array_push(_found, _node);
			return;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__collect(_child, _written, _cx, _found);
				}
			_i++}
		_field_index++}
	};

	#region jsDoc
	/// @func    __replace(_node, _found, _names, _written, _cx)
	/// @desc    Puts the new local of each moved call in its place, in place, nested functions left out.
	/// @self    GMLC_Opt_WithInvariantMotion
	/// @param   {Struct.ASTNode} _node    : The node, a copy this pass owns
	/// @param   {Array}          _found   : The calls that move
	/// @param   {Array<String>}  _names   : Their locals
	/// @param   {Array<String>}  _written : The locals the statement writes
	/// @param   {Struct}         _cx      : The pass context
	#endregion
	static __replace = function(_node, _found, _names, _written, _cx) {
		if (__is_dead_call(_node, _written, _cx)) return;
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _child = _slot.node;
			if (!__gmlc_opt_is_function(_child)) {
				if (__invariant(_child, _written, _cx)) {
					var _f = 0; repeat (array_length(_found)) {
						if (__gmlc_opt_same(_found[_f], _child)) {
							var _use = __gmlc_opt_local(_names[_f], _child.span);
							if (_slot.index == undefined) {
								_slot.parent[$ _slot.key] = _use;
							}
							else {
								_slot.parent[$ _slot.key][_slot.index] = _use;
							}
							break;
						}
					_f++}
				}
				else {
					__replace(_child, _found, _names, _written, _cx);
				}
			}
		_i++}
	};

	#region jsDoc
	/// @func    __invariant(_node, _written, _cx)
	/// @desc    Whether a node is a call that can move before a `with`: a pure built-in that cannot throw, on literals,
	///          locals and such calls, none of the locals written by the statement, outside frozen code.
	/// @self    GMLC_Opt_WithInvariantMotion
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {Array<String>}  _written : The locals the statement writes
	/// @param   {Struct}         _cx      : The pass context
	/// @returns {Bool}
	#endregion
	static __invariant = function(_node, _written, _cx) {
		if (_node.kind != __GMLC_NodeKind_Call) || (!__gmlc_opt_is_trivial(_node)) || (_cx.optimizer.__isNoOp(_node)) return false;
		return __free(_node, _written);
	};

	#region jsDoc
	/// @func    __is_dead_call(_node, _written, _cx)
	/// @desc    Whether a node is a statement that is only a call that could move; a statement cannot become a name.
	/// @self    GMLC_Opt_WithInvariantMotion
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {Array<String>}  _written : The locals the statement writes
	/// @param   {Struct}         _cx      : The pass context
	/// @returns {Bool}
	#endregion
	static __is_dead_call = function(_node, _written, _cx) {
		return (_node.kind == __GMLC_NodeKind_ExprStmt) && __invariant(_node.expression, _written, _cx);
	};
	
	#region jsDoc
	/// @func    __free(_node, _written)
	/// @desc    Whether none of the locals under a node is in a list.
	/// @self    GMLC_Opt_WithInvariantMotion
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {Array<String>}  _written : The locals
	/// @returns {Bool}
	#endregion
	static __free = function(_node, _written) {
		if (_node.kind == __GMLC_NodeKind_Identifier) return !(__gmlc_opt_is_local(_node) && array_contains(_written, _node.name));
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__free(_child, _written)) return false;
				}
			_i++}
		_field_index++}
		return true;
	};

	#region jsDoc
	/// @func    __written(_node, _written)
	/// @desc    Adds the locals written under a node (assigned, incremented, declared with a value, or caught) to a
	///          list, nested functions left out.
	/// @self    GMLC_Opt_WithInvariantMotion
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {Array<String>}  _written : The locals so far, added to
	#endregion
	static __written = function(_node, _written) {
		var _name = undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Assign: if (__gmlc_opt_is_local(_node.target)) _name = _node.target.name; break;
			case __GMLC_NodeKind_Update: if (__gmlc_opt_is_local(_node.argument)) _name = _node.argument.name; break;
			case __GMLC_NodeKind_VarDecl: if (_node.init != undefined) _name = _node.target.name; break;
			case __GMLC_NodeKind_Try: if (_node.catch_param != undefined) _name = _node.catch_param.name; break;
		}
		if (_name != undefined) && (!array_contains(_written, _name)) array_push(_written, _name);
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__gmlc_opt_is_function(_child)) __written(_child, _written);
				}
			_i++}
		_field_index++}
	};

	#region jsDoc
	/// @func    __quiet(_node)
	/// @desc    Whether nothing under a node can change what a pure call on locals reads: it calls only pure, observer
	///          and draw built-ins, and has no method call, `new`, function, or write into an array, struct or other
	///          object.
	/// @self    GMLC_Opt_WithInvariantMotion
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __quiet = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_FunctionExpr: case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_New: case __GMLC_NodeKind_MethodCall: case __GMLC_NodeKind_Delete:
			return false;
			case __GMLC_NodeKind_Call: {
				var _builtin = __gmlc_opt_builtin_call(_node);
				if (_builtin == undefined) return false;
				var _class = __gmlc_opt_call_class(_builtin);
				if (_class != "pure") && (_class != "observer") && (_class != "render") return false;
			break;}
			case __GMLC_NodeKind_Assign:
				if (_node.target.kind == __GMLC_NodeKind_Index) return false;
			break;
			case __GMLC_NodeKind_Update:
				if (_node.argument.kind == __GMLC_NodeKind_Index) return false;
			break;
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
	#endregion
}
