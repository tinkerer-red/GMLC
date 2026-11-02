#region jsDoc
/// @func    GMLC_Opt_SingleUseForwardSubstitution()
/// @desc    The `single-use-forward-substitution` optimizer pass: a local that is assigned once and read once, in a
///          later statement of the same list, is replaced by its value at the read, when nothing between the two
///          statements can tell the difference. `var _d = f(_x); g(_d);` becomes `g(f(_x));`.
/// @returns {Struct.GMLC_Opt_SingleUseForwardSubstitution}
#endregion
function GMLC_Opt_SingleUseForwardSubstitution() : GMLC_OptimizerPass("single-use-forward-substitution") constructor {
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with every eligible single-use local substituted, or undefined when none is.
	/// @self    GMLC_Opt_SingleUseForwardSubstitution
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _state = { optimizer: _cx.optimizer, cx: _cx, root: _node, reads: {}, writes: {}, params: __gmlc_opt_function_param_names(_node) };
		return __gmlc_opt_rewritten_lists(_node, _state, true, method(self, __list));
	};
	#endregion

	#region Candidates
	#region jsDoc
	/// @func    __list(_body, _state)
	/// @desc    Substitutes the eligible locals of one statement list, first to last, so a chain collapses.
	/// @self    GMLC_Opt_SingleUseForwardSubstitution
	/// @param   {Array<Struct.ASTNode>} _body  : The statements
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list, undefined when nothing changed
	#endregion
	static __list = function(_body, _state) {
		var _list = _body;
		var _changed = false;
		var _i = 0;
		while (_i < array_length(_list)) {
			var _hit = __candidate(_list, _i, _state);
			if (_hit == undefined) {
				_i++;
			}
			else {
				if (!_changed) {
					_list = variable_clone(_body, 0);
					_changed = true;
				}
				_list[_hit.use] = _hit.statement;
				array_delete(_list, _i, 1);
				_state.cx.stats[$ "substituted"]++;
			}
		}
		return _changed ? _list : undefined;
	};

	#region jsDoc
	/// @func    __candidate(_list, _index, _state)
	/// @desc    Whether the statement at an index defines a local that can be put into its one read.
	/// @self    GMLC_Opt_SingleUseForwardSubstitution
	/// @param   {Array<Struct.ASTNode>} _list  : The statements
	/// @param   {Real}                  _index : The definition's place
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Struct|Undefined} {use, statement}: the place of the reading statement and what replaces it
	#endregion
	static __candidate = function(_list, _index, _state) {
		var _stmt = _list[_index];
		var _name;
		var _init;
		if (_stmt.kind == __GMLC_NodeKind_VarDeclList) {
			if (array_length(_stmt.declarations) != 1) return undefined;
			var _decl = _stmt.declarations[0];
			if (_decl.init == undefined) || (!__gmlc_opt_is_local(_decl.target)) return undefined;
			_name = _decl.target.name;
			_init = _decl.init;
		}
		else if (_stmt.kind == __GMLC_NodeKind_ExprStmt) && (_stmt.expression.kind == __GMLC_NodeKind_Assign) && (_stmt.expression.op == "=") && (__gmlc_opt_is_local(_stmt.expression.target)) {
			_name = _stmt.expression.target.name;
			_init = _stmt.expression.value;
		}
		else {
			return undefined;
		}
		var _optimizer = _state.optimizer;
		if (array_contains(_state.params, _name)) || (_optimizer.__containsNoOp(_stmt)) return undefined;
		if (__gmlc_opt_count_reads(_state.root, _state.reads, _name) != 1) || (__gmlc_opt_count_writes(_state.root, _state.writes, _name) != 1) return undefined;
		if (__gmlc_opt_is_or_holds_function(_init)) return undefined;

		var _trivial = __gmlc_opt_is_trivial(_init);
		var _names = [];
		__gmlc_opt_collect_local_names(_init, _names);
		if (!_trivial) {
			var _n = 0; repeat (array_length(_names)) {
				if (__gmlc_opt_writes(_init, _names[_n])) return undefined;
			_n++}
		}

		// the statements between the definition and the read
		var _use = -1;
		var _k = _index + 1; repeat (array_length(_list) - _index - 1) {
			var _between = _list[_k];
			if (__gmlc_opt_reads(_between, _name) > 0) {
				_use = _k;
				break;
			}
			if (_optimizer.__containsNoOp(_between)) return undefined;
			if (_trivial) {
				var _n = 0; repeat (array_length(_names)) {
					if (__gmlc_opt_writes(_between, _names[_n])) return undefined;
				_n++}
			}
			else if (!__transparent(_between, _names)) {
				return undefined;
			}
		_k++}
		if (_use < 0) return undefined;

		var _reader = _list[_use];
		if (_optimizer.__containsNoOp(_reader)) return undefined;
		if (_trivial) {
			var _n = 0; repeat (array_length(_names)) {
				if (__gmlc_opt_writes(_reader, _names[_n])) return undefined;
			_n++}
		}
		var _steps = [];
		if (!__find(_reader, _name, _steps)) return undefined;
		if (!__allowed(_steps, _trivial)) return undefined;
		var _last = _steps[array_length(_steps) - 1];
		if (_state.optimizer.outputName() == "gml-source-yyc") && (__yycSlowPlace(_last, _init)) return undefined;
		// the value takes the place of the read, so the line breaks of the read are the ones printed
		var _read = (_last.index == undefined) ? _last.node[$ _last.key] : _last.node[$ _last.key][_last.index];
		var _moved = __gmlc_opt_clone(_init);
		__gmlc_opt_retag_span(_moved, _read.span);
		return { use: _use, statement: __replace(_steps, 0, _moved) };
	};

	#region jsDoc
	/// @func    __yycSlowPlace(_step, _value)
	/// @desc    Whether YYC runs the place of a step slower as the number literal `_value` (or its negation) than as the
	///          local that holds it: an arithmetic operand beside a non-literal (`__gmlc_opt_yyc_slow_operand`) or an
	///          argument of a built-in beside a non-literal one (`__gmlc_opt_yyc_slow_argument`).
	/// @self    GMLC_Opt_SingleUseForwardSubstitution
	/// @param   {Struct}         _step  : {node, key, index} of the read
	/// @param   {Struct.ASTNode} _value : The value
	/// @returns {Bool}
	#endregion
	static __yycSlowPlace = function(_step, _value) {
		var _literal = _value;
		if (_value.kind == __GMLC_NodeKind_Unary) && (_value.op == "-") _literal = _value.argument;
		if (_literal.kind != __GMLC_NodeKind_Literal) return false;
		var _parent = _step.node;
		switch (_parent.kind) {
			case __GMLC_NodeKind_Call: return (_step.key == "args") && __gmlc_opt_yyc_slow_argument(_parent, _step.index, _literal, {});
			case __GMLC_NodeKind_Binary: {
				var _other = (_step.key == "left") ? _parent.right : _parent.left;
				return __gmlc_opt_yyc_slow_operand(_parent.op, _literal) && (!__gmlc_opt_constant_tree(_other, {}));
			}
		}
		return false;
	};

	#region jsDoc
	/// @func    __transparent(_stmt, _names)
	/// @desc    Whether a statement can run before or after an expression that is not trivial without either one
	///          noticing: it only stores a trivial value in a local the expression does not mention.
	/// @self    GMLC_Opt_SingleUseForwardSubstitution
	/// @param   {Struct.ASTNode} _stmt  : The statement
	/// @param   {Array<String>}  _names : The locals the expression mentions
	/// @returns {Bool}
	#endregion
	static __transparent = function(_stmt, _names) {
		if (_stmt.kind == __GMLC_NodeKind_VarDeclList) {
			var _decls = _stmt.declarations;
			var _i = 0; repeat (array_length(_decls)) {
				var _decl = _decls[_i];
				if (!__gmlc_opt_is_local(_decl.target)) || (array_contains(_names, _decl.target.name)) return false;
				if (_decl.init != undefined) && (!__gmlc_opt_is_trivial(_decl.init)) return false;
			_i++}
			return true;
		}
		if (_stmt.kind == __GMLC_NodeKind_ExprStmt) && (_stmt.expression.kind == __GMLC_NodeKind_Assign) {
			var _assign = _stmt.expression;
			if (_assign.op != "=") || (!__gmlc_opt_is_local(_assign.target)) || (array_contains(_names, _assign.target.name)) return false;
			return __gmlc_opt_is_trivial(_assign.value);
		}
		return false;
	};
	#endregion

	#region Placement
	#region jsDoc
	/// @func    __find(_node, _name, _steps)
	/// @desc    Finds the read of a local under a node and records the way down to it.
	/// @self    GMLC_Opt_SingleUseForwardSubstitution
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {String}         _name  : The local
	/// @param   {Array<Struct>}  _steps : Gets {node, key, index} for each node on the way, outermost first
	/// @returns {Bool} Whether the read was found
	#endregion
	static __find = function(_node, _name, _steps) {
		if (__gmlc_opt_is_local(_node)) return (_node.name == _name);
		if (__gmlc_opt_is_function(_node)) return false;
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			if (_node.kind != __GMLC_NodeKind_VarDecl) || (_slot.key != "target") {
				array_push(_steps, { node: _node, key: _slot.key, index: _slot.index });
				if (__find(_slot.node, _name, _steps)) return true;
				array_pop(_steps);
			}
		_i++}
		return false;
	};

	#region jsDoc
	/// @func    __allowed(_steps, _trivial)
	/// @desc    Whether a value may take the place of the read at the end of a way down: the statement runs it once,
	///          and for a value that is not trivial nothing that is not trivial runs before it.
	/// @self    GMLC_Opt_SingleUseForwardSubstitution
	/// @param   {Array<Struct>} _steps   : The way down, outermost first
	/// @param   {Bool}          _trivial : Whether the value is trivial
	/// @returns {Bool}
	#endregion
	static __allowed = function(_steps, _trivial) {
		var _head = _steps[0];
		switch (_head.node.kind) {
			case __GMLC_NodeKind_ExprStmt:    if (_head.key != "expression") return false; break;
			case __GMLC_NodeKind_Return:      if (_head.key != "argument") return false; break;
			case __GMLC_NodeKind_Throw:       if (_head.key != "argument") return false; break;
			case __GMLC_NodeKind_If:          if (_head.key != "test") return false; break;
			case __GMLC_NodeKind_Switch:      if (_head.key != "discriminant") return false; break;
			case __GMLC_NodeKind_Repeat:      if (_head.key != "count") return false; break;
			case __GMLC_NodeKind_VarDeclList: if (array_length(_head.node.declarations) != 1) return false; break;
			default: return false;
		}
		var _i = 1; repeat (array_length(_steps) - 1) {
			var _step = _steps[_i];
			var _parent = _step.node;
			var _key = _step.key;
			if (_trivial) {
				switch (_parent.kind) {
					case __GMLC_NodeKind_Assign:     if (_key == "target") return false; break;
					case __GMLC_NodeKind_Update:
					case __GMLC_NodeKind_Delete:
					return false;
					case __GMLC_NodeKind_Index:      if (_key == "object") return false; break;
					case __GMLC_NodeKind_MethodCall: if (_key == "object") return false; break;
					case __GMLC_NodeKind_Call:       if (_key == "callee") return false; break;
				}
			}
			else {
				switch (_parent.kind) {
					case __GMLC_NodeKind_Unary:
					case __GMLC_NodeKind_VarDecl:
					break;
					case __GMLC_NodeKind_Binary:
					case __GMLC_NodeKind_ArrayLiteral: {
						if (!__siblingsTrivial(_parent, _step)) return false;
					break;}
					case __GMLC_NodeKind_Logical:
					case __GMLC_NodeKind_Nullish:    if (_key != "left") return false; break;
					case __GMLC_NodeKind_Conditional: if (_key != "test") return false; break;
					case __GMLC_NodeKind_Call: {
						if (_key != "args") || (_parent.callee.kind != __GMLC_NodeKind_Identifier) return false;
						// `sqr(_d)` and `power(_d, 2)` become `_d * _d` (strength-reduce) only on a name
						var _square = __gmlc_opt_builtin_call(_parent);
						if (_step.index == 0) && ((_square == "sqr") || (_square == "power")) return false;
						if (!__siblingsTrivial(_parent, _step)) return false;
					break;}
					case __GMLC_NodeKind_Assign: {
						if (_key != "value") || (_parent.op != "=") return false;
						var _target = _parent.target;
						if (_target.kind == __GMLC_NodeKind_Index) {
							if (_target.object.kind != __GMLC_NodeKind_Identifier) return false;
							var _t = 0; repeat (array_length(_target.keys)) {
								if (!__gmlc_opt_is_trivial(_target.keys[_t])) return false;
							_t++}
						}
						else if (_target.kind != __GMLC_NodeKind_Identifier) {
							return false;
						}
					break;}
					case __GMLC_NodeKind_Index: {
						if (_key != "keys") || (!__gmlc_opt_is_trivial(_parent.object)) return false;
						if (!__siblingsTrivial(_parent, _step)) return false;
					break;}
					default: return false;
				}
			}
		_i++}
		return true;
	};

	#region jsDoc
	/// @func    __siblingsTrivial(_parent, _step)
	/// @desc    Whether every child of a node but the one on the way down is trivial, the callee of a call left out.
	/// @self    GMLC_Opt_SingleUseForwardSubstitution
	/// @param   {Struct.ASTNode} _parent : The node
	/// @param   {Struct}         _step   : The step of the way down that leaves the node
	/// @returns {Bool}
	#endregion
	static __siblingsTrivial = function(_parent, _step) {
		var _slots = _parent.childSlots();
		var _s = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_s];
			var _isWay = (_slot.key == _step.key) && (_slot.index == _step.index);
			if (!_isWay) {
				var _isCallee = (_parent.kind == __GMLC_NodeKind_Call) && (_slot.key == "callee");
				if (!_isCallee) && (!__gmlc_opt_is_trivial(_slot.node)) return false;
			}
		_s++}
		return true;
	};

	#region jsDoc
	/// @func    __replace(_steps, _i, _value)
	/// @desc    The statement with the read at the end of the way down replaced by a value.
	/// @self    GMLC_Opt_SingleUseForwardSubstitution
	/// @param   {Array<Struct>}  _steps : The way down, outermost first
	/// @param   {Real}           _i     : The step to rebuild
	/// @param   {Struct.ASTNode} _value : The value
	/// @returns {Struct.ASTNode}
	#endregion
	static __replace = function(_steps, _i, _value) {
		var _step = _steps[_i];
		var _inner = (_i + 1 < array_length(_steps)) ? __replace(_steps, _i + 1, _value) : _value;
		return __gmlc_opt_rebuild_children(_step.node, [{ key: _step.key, index: _step.index, node: _inner }]);
	};
	#endregion

}
