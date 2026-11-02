#region jsDoc
/// @func    GMLC_Opt_LoopCarriedLoadReuse()
/// @desc    `loop-carried-load-reuse`: a `for` loop that reads `a[i]` and `a[i - 1]` keeps the value it read in a
///          local for the next pass, so each element is read once. `for (var _i = 1; _i < _n; _i++) { _d[_i] =
///          _a[_i] - _a[_i - 1]; }` becomes `if (1 < _n) { var __p = _a[0]; for (var _i = 1; _i < _n; _i++) { var
///          __c = _a[_i]; _d[_i] = __c - __p; __p = __c; } }`. Nothing in the loop writes `a`: it only writes
///          locals and arrays made in the function that nothing else names, and the function has no `try`.
/// @returns {Struct.GMLC_Opt_LoopCarriedLoadReuse}
#endregion
function GMLC_Opt_LoopCarriedLoadReuse() : GMLC_OptimizerPass("loop-carried-load-reuse") constructor {
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    A copy of the function with the repeated reads of its loops kept in locals, or undefined when there
	///          is none.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _st = { cx: _cx, apply: false, root: _node, defs: [], kinds: undefined, fresh: undefined };
		if (!__gmlc_opt_walk_statement_lists(_node, _st, true, method(self, __rewrite))) return undefined;
		var _copy = __gmlc_opt_clone(_node);
		_st.apply = true;
		array_resize(_st.defs, 0);
		__gmlc_opt_walk_statement_lists(_copy, _st, true, method(self, __rewrite));
		return _copy;
	};
	#endregion

	#region Loops
	#region jsDoc
	/// @func    __rewrite(_loop, _st, _body, _i)
	/// @desc    The guarded loop that reads each element once, or undefined when the loop does not qualify.
	///          Without `_st.apply` an array says it qualifies.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode}        _loop : The loop
	/// @param   {Struct}                _st   : The walk state
	/// @param   {Array<Struct.ASTNode>} _body : The statement list the loop is in
	/// @param   {Real}                  _i    : The loop's place in it
	/// @returns {Array<Struct.ASTNode>|Undefined}
	#endregion
	static __rewrite = function(_loop, _st, _body, _i) {
		if (_loop.kind != __GMLC_NodeKind_For) return undefined;
		var _counter = __counter(_loop);
		if (_counter == undefined) return undefined;
		var _name = _counter.name;
		var _limit = _loop.test.right;
		var _limitOk = (_limit.kind == __GMLC_NodeKind_Literal) && (_limit.ty == "real");
		if (__gmlc_opt_is_local(_limit)) _limitOk = (_limit.name != _name) && (!__gmlc_opt_writes(_loop.body, _limit.name));
		if (!_limitOk) return undefined;
		var _stmts = _loop.body.body;
		if (array_length(_stmts) == 0) return undefined;
		if (__gmlc_opt_has_function(_loop)) || (_st.cx.optimizer.__containsNoOp(_loop)) || (__gmlc_opt_has_try(_st.root, true)) return undefined;
		if (_st.kinds == undefined) _st.kinds = __gmlc_opt_local_kinds(_st.root, _st.cx);
		if (_st.fresh == undefined) _st.fresh = __freshArrays(_st.root);
		var _form = { a: undefined, cur: 0, prev: 0 };
		if (!__firstOk(_stmts[0], _st, _name, _form)) || (_form.cur == 0) || (_form.prev == 0) return undefined;
		if (_form.a == _name) return undefined;
		var _s = 1; repeat (array_length(_stmts) - 1) {
			if (!__laterOk(_stmts[_s], _st, _name, _form.a)) return undefined;
		_s++}
		if (__gmlc_opt_live_refs(_st.root, _name) != 0) return undefined;
		var _span = _loop.span;
		var _start = real(_counter.start);
		if (_st.cx.optimizer.__literal(_start, _span) == undefined) || (_st.cx.optimizer.__literal(_start - 1, _span) == undefined) return undefined;
		if (!_st.apply) return [];
		_st.cx.stats[$ "loads_reused"]++;
		var _previous = _st.cx.optimizer.newTemporary(_st.cx);
		var _current = _st.cx.optimizer.newTemporary(_st.cx);
		var _read = __firstRead(_loop.body, _form.a, _name, 1);
		var _before = __gmlc_opt_clone(__firstRead(_loop.body, _form.a, _name, 2));
		_before.keys = [_st.cx.optimizer.__literal(_start - 1, _before.span)];
		var _load = __gmlc_opt_var(_current, __gmlc_opt_clone(_read), _span);
		var _carry = new ASTExprStmt(_span, new ASTAssign(_span, "=", __gmlc_opt_local(_previous, _span), __gmlc_opt_local(_current, _span)));
		__replaceReads(_loop.body, _form.a, _name, _previous, _current);
		array_insert(_stmts, 0, _load);
		array_push(_stmts, _carry);
		var _guard = new ASTIf(_span, new ASTBinary(_span, _loop.test.op, _st.cx.optimizer.__literal(_start, _span), __gmlc_opt_clone(_limit)),
			new ASTBlock(_span, [__gmlc_opt_var(_previous, _before, _span), _loop]), undefined);
		return [_guard];
	};

	#region jsDoc
	/// @func    __counter(_loop)
	/// @desc    The counter and the first value of a `for` loop written `for (var i = 1; i < limit; i++)` (`<=` or
	///          `+= 1` as well, or `i = 1` in place of the declaration), or undefined for any other loop. The first
	///          value is at least 1 so that the element before it exists.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _loop : The loop
	/// @returns {Struct|Undefined} {name, start} with the start as written
	#endregion
	static __counter = function(_loop) {
		var _header = __gmlc_opt_counted_header(_loop);
		if (_header == undefined) || (_header.step != 1) || ((_header.cmp != "<") && (_header.cmp != "<=")) return undefined;
		var _start = _header.start;
		if (_start.kind != __GMLC_NodeKind_Literal) || (_start.ty != "real") || (!__gmlc_opt_whole_text(_start.lexeme)) || (string_length(_start.lexeme) > 9) || (real(_start.lexeme) < 1) return undefined;
		return { name: _header.name, start: _start.lexeme };
	};
	#endregion

	#region First statement
	#region jsDoc
	/// @func    __firstOk(_stmt, _st, _name, _form)
	/// @desc    Whether the first statement of a loop body is an assignment or a declaration whose value reads
	///          `a[i]` and `a[i - 1]` and nothing else that can throw before both are read: the two reads joined by
	///          an operator, then operators with a literal or a local. Records the array and the reads in `_form`.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @param   {Struct}         _st   : The walk state
	/// @param   {String}         _name : The counter
	/// @param   {Struct}         _form : {a, cur, prev}
	/// @returns {Bool}
	#endregion
	static __firstOk = function(_stmt, _st, _name, _form) {
		if (_stmt.kind == __GMLC_NodeKind_VarDeclList) {
			if (array_length(_stmt.declarations) != 1) return false;
			var _decl = _stmt.declarations[0];
			if (_decl.init == undefined) || (_decl.target.name == _name) return false;
			return (__shape(_decl.init, _st, _name, _form) >= 0) && (_decl.target.name != _form.a);
		}
		if (_stmt.kind != __GMLC_NodeKind_ExprStmt) || (_stmt.expression.kind != __GMLC_NodeKind_Assign) return false;
		var _assign = _stmt.expression;
		if (_assign.op != "=") || (!__targetOk(_assign.target, _st, _name)) return false;
		if (__shape(_assign.value, _st, _name, _form) < 0) return false;
		var _written = __gmlc_opt_is_local(_assign.target) ? _assign.target.name : _assign.target.object.name;
		return _written != _form.a;
	};

	#region jsDoc
	/// @func    __shape(_node, _st, _name, _form)
	/// @desc    What an expression of the first statement is: 0 when it reads nothing from an array and cannot
	///          throw, 1 when it is one of the two reads, 2 when it combines reads with operators that only
	///          run after both are read, -1 when it is anything else.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _st   : The walk state
	/// @param   {String}         _name : The counter
	/// @param   {Struct}         _form : {a, cur, prev}
	/// @returns {Real}
	#endregion
	static __shape = function(_node, _st, _name, _form) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: return ((_node.ty == "real") || (_node.ty == "int64") || (_node.ty == "bool")) ? 0 : -1;
			case __GMLC_NodeKind_Identifier: {
				if (!__gmlc_opt_is_local(_node)) return (__gmlc_opt_constant_level(_node, _st.cx) == 1) ? 0 : -1;
				if (_node.name == _name) return 0;
				return (((_st.kinds[$ _node.name] ?? 0) >= 1) && (array_contains(_st.defs, _node.name))) ? 0 : -1;
			}
			case __GMLC_NodeKind_Index: {
				var _which = __readOf(_node, _name);
				if (_which < 0) return -1;
				if (_form.a == undefined) _form.a = _node.object.name;
				if (_form.a != _node.object.name) return -1;
				if (_which == 1) _form.cur++;
				else _form.prev++;
				return 1;
			}
			case __GMLC_NodeKind_Unary: {
				var _inner = __shape(_node[$ "argument"], _st, _name, _form);
				return (_inner < 0) ? -1 : ((_inner == 0) ? 0 : 2);
			}
			case __GMLC_NodeKind_Binary: {
				switch (_node.op) {
					case "+": case "-": case "*": case "/": {
						var _left = __shape(_node.left, _st, _name, _form);
						var _right = __shape(_node.right, _st, _name, _form);
						if (_left < 0) || (_right < 0) return -1;
						if (_left == 0) && (_right == 0) return 0;
						if (_left == 1) && (_right == 1) return 2;
						if (_left == 2) && (_right == 0) return 2;
						if (_left == 0) && (_right == 2) return 2;
						if (_left == 1) && (_right == 0) return 2;
						if (_left == 0) && (_right == 1) return 2;
					}
				}
				return -1;
			}
		}
		return -1;
	};

	#region jsDoc
	/// @func    __readOf(_node, _name)
	/// @desc    Which carried read an expression is: 1 for `a[i]`, 2 for `a[i - 1]`, -1 for anything else.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {String}         _name : The counter
	/// @returns {Real}
	#endregion
	static __readOf = function(_node, _name) {
		if (_node.kind != __GMLC_NodeKind_Index) || (_node.accessor != "Array") || (!__gmlc_opt_is_local(_node.object)) || (array_length(_node.keys) != 1) return -1;
		var _key = _node.keys[0];
		if (__gmlc_opt_is_local(_key)) return (_key.name == _name) ? 1 : -1;
		if (_key.kind == __GMLC_NodeKind_Binary) && (_key.op == "-") && (__gmlc_opt_is_local(_key.left)) && (_key.left.name == _name) {
			if (_key.right.kind == __GMLC_NodeKind_Literal) && (_key.right.ty == "real") && (_key.right.lexeme == "1") return 2;
		}
		return -1;
	};

	#region jsDoc
	/// @func    __targetOk(_node, _st, _name)
	/// @desc    Whether an assignment target is a local other than the counter, or an element of an array made in
	///          the function and named nowhere but in element accesses, at the counter or at a whole literal.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _node : The target
	/// @param   {Struct}         _st   : The walk state
	/// @param   {String}         _name : The counter
	/// @returns {Bool}
	#endregion
	static __targetOk = function(_node, _st, _name) {
		if (__gmlc_opt_is_local(_node)) return _node.name != _name;
		if (_node.kind != __GMLC_NodeKind_Index) || (_node.accessor != "Array") || (!__gmlc_opt_is_local(_node.object)) || (array_length(_node.keys) != 1) return false;
		var _array = _node.object.name;
		if (!(_st.fresh[$ _array] ?? false)) || (!array_contains(_st.defs, _array)) return false;
		var _key = _node.keys[0];
		if (__gmlc_opt_is_local(_key)) return _key.name == _name;
		return (_key.kind == __GMLC_NodeKind_Literal) && (_key.ty == "real") && (__gmlc_opt_whole_text(_key.lexeme));
	};
	#endregion

	#region Other statements
	#region jsDoc
	/// @func    __laterOk(_stmt, _st, _name, _a)
	/// @desc    Whether a statement after the first has no effect but giving a value to a local other than the
	///          counter or to an element of an array made in the function, which is not the one read.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @param   {Struct}         _st   : The walk state
	/// @param   {String}         _name : The counter
	/// @param   {String}         _a    : The array the loop reads
	/// @returns {Bool}
	#endregion
	static __laterOk = function(_stmt, _st, _name, _a) {
		if (_stmt.kind == __GMLC_NodeKind_VarDeclList) {
			var _d = 0; repeat (array_length(_stmt.declarations)) {
				var _decl = _stmt.declarations[_d];
				if (_decl.target.name == _name) || (_decl.target.name == _a) return false;
				if (_decl.init != undefined) && (!__effectFree(_decl.init)) return false;
			_d++}
			return true;
		}
		if (_stmt.kind != __GMLC_NodeKind_ExprStmt) return false;
		var _expr = _stmt.expression;
		if (_expr.kind == __GMLC_NodeKind_Update) {
			var _arg = _expr[$ "argument"];
			return __gmlc_opt_is_local(_arg) && (_arg.name != _name) && (_arg.name != _a);
		}
		if (_expr.kind != __GMLC_NodeKind_Assign) || (!__effectFree(_expr.value)) return false;
		if (__gmlc_opt_is_local(_expr.target)) {
			return (_expr.op != "??=") && (_expr.op != "%=") && (_expr.op != "&=") && (_expr.op != "|=") && (_expr.op != "^=") && (_expr.target.name != _name) && (_expr.target.name != _a);
		}
		return (_expr.op == "=") && (__targetOk(_expr.target, _st, _name)) && (_expr.target.object.name != _a);
	};

	#region jsDoc
	/// @func    __effectFree(_node)
	/// @desc    Whether evaluating an expression changes nothing: literals, locals, element reads and operators
	///          of those, and calls of pure built-ins.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __effectFree = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: return true;
			case __GMLC_NodeKind_Identifier: return __gmlc_opt_is_local(_node);
			case __GMLC_NodeKind_Unary: return __effectFree(_node[$ "argument"]);
			case __GMLC_NodeKind_Binary: case __GMLC_NodeKind_Logical: return __effectFree(_node.left) && __effectFree(_node.right);
			case __GMLC_NodeKind_Conditional: return __effectFree(_node.test) && __effectFree(_node.consequent) && __effectFree(_node.alternate);
			case __GMLC_NodeKind_Index: {
				if (_node.accessor != "Array") && (_node.accessor != "Array2D") return false;
				if (!__effectFree(_node.object)) return false;
				var _k = 0; repeat (array_length(_node.keys)) {
					if (!__effectFree(_node.keys[_k])) return false;
				_k++}
				return true;
			}
			case __GMLC_NodeKind_Call: {
				var _function = __gmlc_opt_builtin_call(_node);
				if (_function == undefined) || (__gmlc_opt_call_class(_function) != "pure") return false;
				var _a = 0; repeat (array_length(_node.args)) {
					if (!__effectFree(_node.args[_a])) return false;
				_a++}
				return true;
			}
		}
		return false;
	};
	#endregion

	#region Arrays
	#region jsDoc
	/// @func    __freshArrays(_root)
	/// @desc    The locals of a function that are given one new array, by `[...]` or `array_create`, and are named
	///          nowhere else except as the array of an element access, so no other name can reach their array.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _root : The function, or the Script
	/// @returns {Struct} Local name to true
	#endregion
	static __freshArrays = function(_root) {
		var _info = {};
		__freshScan(_root, undefined, _info, true);
		var _fresh = {};
		var _names = struct_get_names(_info);
		var _n = 0; repeat (array_length(_names)) {
			var _entry = _info[$ _names[_n]];
			if (!_entry.bad) && (_entry.creations == 1) && (_entry.valid) _fresh[$ _names[_n]] = true;
		_n++}
		return _fresh;
	};

	#region jsDoc
	/// @func    __freshScan(_node, _parent, _info, _isRoot)
	/// @desc    Records how each local is named under a node: as the array of an element access, as the target of
	///          its one creation, or in some other way that rules it out. Nested functions are left out.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct.ASTNode} _parent : Its parent, undefined at the root
	/// @param   {Struct}         _info   : Local name to {bad, creations, valid}
	/// @param   {Bool}           _isRoot : Whether the node is the function itself
	#endregion
	static __freshScan = function(_node, _parent, _info, _isRoot) {
		if (!_isRoot) && (__gmlc_opt_is_function(_node)) return;
		if (__gmlc_opt_is_local(_node)) {
			var _entry = _info[$ _node.name];
			if (_entry == undefined) {
				_entry = { bad: false, creations: 0, valid: true };
				_info[$ _node.name] = _entry;
			}
			var _ok = false;
			if (_parent != undefined) {
				switch (_parent.kind) {
					case __GMLC_NodeKind_Index: _ok = (_parent.object == _node) && (_parent.accessor == "Array"); break;
					case __GMLC_NodeKind_VarDecl: {
						if (_parent.target == _node) {
							_ok = true;
							if (_parent.init != undefined) {
								_entry.creations++;
								if (!__makesArray(_parent.init)) _entry.valid = false;
							}
						}
					break;}
					case __GMLC_NodeKind_Assign: {
						if (_parent.target == _node) && (_parent.op == "=") {
							_ok = true;
							_entry.creations++;
							if (!__makesArray(_parent.value)) _entry.valid = false;
						}
					break;}
				}
			}
			if (!_ok) _entry.bad = true;
			return;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__freshScan(_child, _node, _info, false);
				}
			_i++}
		_field_index++}
	};

	#region jsDoc
	/// @func    __makesArray(_node)
	/// @desc    Whether an expression makes a new array: `[...]` or a call of `array_create`.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __makesArray = function(_node) {
		return (_node.kind == __GMLC_NodeKind_ArrayLiteral) || (__gmlc_opt_builtin_call(_node) == "array_create");
	};

	#endregion

	#region Rewriting
	#region jsDoc
	/// @func    __firstRead(_node, _a, _name, _which)
	/// @desc    The first carried read of an array under a node.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {String}         _a     : The array
	/// @param   {String}         _name  : The counter
	/// @param   {Real}           _which : 1 for `a[i]`, 2 for `a[i - 1]`
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __firstRead = function(_node, _a, _name, _which) {
		if (__readOf(_node, _name) == _which) && (_node.object.name == _a) return _node;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					var _found = __firstRead(_child, _a, _name, _which);
					if (_found != undefined) return _found;
				}
			_i++}
		_field_index++}
		return undefined;
	};

	#region jsDoc
	/// @func    __replaceReads(_node, _a, _name, _previous, _current)
	/// @desc    Puts the locals that keep the two reads in place of every `a[i]` and `a[i - 1]` under a node.
	/// @self    GMLC_Opt_LoopCarriedLoadReuse
	/// @param   {Struct.ASTNode} _node     : The node, changed in place
	/// @param   {String}         _a        : The array
	/// @param   {String}         _name     : The counter
	/// @param   {String}         _previous : The local that keeps `a[i - 1]`
	/// @param   {String}         _current  : The local that keeps `a[i]`
	#endregion
	static __replaceReads = function(_node, _a, _name, _previous, _current) {
		var _slots = _node.childSlots();
		var _s = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_s];
			var _which = __readOf(_slot.node, _name);
			if (_which > 0) && (_slot.node.object.name == _a) {
				var _local = __gmlc_opt_local((_which == 1) ? _current : _previous, _slot.node.span);
				if (_slot.index == undefined) {
					_node[$ _slot.key] = _local;
				}
				else {
					_node[$ _slot.key][_slot.index] = _local;
				}
			}
			else {
				__replaceReads(_slot.node, _a, _name, _previous, _current);
			}
		_s++}
	};
	#endregion

}
