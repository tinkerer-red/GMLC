#region jsDoc
/// @func    GMLC_Opt_DeadStore()
/// @desc    Removes the assignments to a local that nothing reads before the next assignment (or the end of the
///          function). A store whose value has no effect goes: `var _best = noone; _best = nearest();` becomes
///          `var _best = nearest();`. A store of a call keeps the call: `var _fx = spawn();` becomes `spawn();`.
///          An initializer that is overwritten leaves a bare `var _best;`. An element store to a local array that
///          the next store to the same element overwrites goes too. Liveness follows loops, `switch`, `try` and
///          the jumps out of them; code under `@NoOp` reads everything.
/// @returns {Struct.GMLC_Opt_DeadStore}
#endregion
function GMLC_Opt_DeadStore() : GMLC_OptimizerPass("dead-store") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with its dead stores removed, or undefined when it has none.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _node : The function, or the whole script for the file's own code
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _ctx = __context(_node, _cx);
		var _copy = undefined;
		var _removed = 0;
		var _reduced = 0;
		if (_node.kind == __GMLC_NodeKind_Script) {
			var _list = __list(_node.body, {}, _ctx);
			if (_list.changed) {
				_copy = variable_clone(_node, 0);
				_copy.body = _list.statements;
			}
			_removed = _list.removed;
			_reduced = _list.reduced;
		}
		else {
			var _body = __statement(_node.body, {}, _ctx, false);
			if (_body.items != undefined) {
				_copy = variable_clone(_node, 0);
				_copy.body = _body.items[0];
			}
			_removed = _body.removed;
			_reduced = _body.reduced;
		}
		if (_copy == undefined) return undefined;
		_cx.stats[$ "stores_removed"] += _removed;
		_cx.stats[$ "stores_reduced_to_call"] += _reduced;
		return _copy;
	};
	#endregion

	#region Private
	#region Context
	#region jsDoc
	/// @func    __context(_root, _cx)
	/// @desc    What the walk over a function knows: the locals it may change, how often each is mentioned, the
	///          local arrays nothing else can reach, and the sets that are live where control leaves.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _root : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct}
	#endregion
	static __context = function(_root, _cx) {
		var _mentions = {};
		__count(_root, _mentions);
		var _pinned = {};
		if (__gmlc_opt_is_function(_root)) && (__usesArguments(_root)) {
			var _params = _root.params;
			var _p = 0; repeat (array_length(_params)) {
				_pinned[$ _params[_p].target.name] = true;
			_p++}
		}
		var _candidates = {};
		var _names = struct_get_names(_mentions);
		var _n = 0; repeat (array_length(_names)) {
			if (!struct_exists(_pinned, _names[_n])) _candidates[$ _names[_n]] = true;
		_n++}
		var _arrays = {};
		if (!__copyOnWrite(_cx)) {
			var _info = {};
			__classify(_root, undefined, "", false, _info);
			var _kept = struct_get_names(_info);
			var _k = 0; repeat (array_length(_kept)) {
				var _entry = _info[$ _kept[_k]];
				if (_entry.ok) && (_entry.declared) && (struct_exists(_candidates, _kept[_k])) _arrays[$ _kept[_k]] = true;
			_k++}
		}
		return { cx: _cx, candidates: _candidates, mentions: _mentions, arrays: _arrays, has_try: __hasTry(_root), with_unsafe: false, exit: {}, handler: {}, brk: {}, cont: {} };
	};

	#region jsDoc
	/// @func    __copyOnWrite(_cx)
	/// @desc    Whether the project may have Copy on Write on: unless the environment knows it is off.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct} _cx : The pass context
	/// @returns {Bool}
	#endregion
	static __copyOnWrite = function(_cx) {
		return (_cx.env.copy_on_write != false);
	};

	#region jsDoc
	/// @func    __count(_node, _counts)
	/// @desc    Counts the mentions of each local under a node, nested functions included.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct}         _counts : Name to count
	#endregion
	static __count = function(_node, _counts) {
		if (_node.kind == __GMLC_NodeKind_Identifier) {
			if (__gmlc_opt_is_local(_node)) {
				_counts[$ _node.name] = (_counts[$ _node.name] ?? 0) + 1;
			}
			return;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__count(_child, _counts);
				}
			_i++}
		_field_index++}
	};

	#region jsDoc
	/// @func    __mentions(_node, _name)
	/// @desc    How many identifiers of that name are under a node, nested functions included.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The name
	/// @returns {Real}
	#endregion
	static __mentions = function(_node, _name) {
		if (_node.kind == __GMLC_NodeKind_Identifier) return (_node.name == _name) ? 1 : 0;
		var _n = 0;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					_n += __mentions(_child, _name);
				}
			_i++}
		_field_index++}
		return _n;
	};

	#region jsDoc
	/// @func    __usesArguments(_node)
	/// @desc    Whether the function reads `argument`, `argument0` and the like, which share their values with the
	///          parameters.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __usesArguments = function(_node) {
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (_child.kind == __GMLC_NodeKind_Identifier) {
						if (string_pos("argument", _child.name) == 1) && (!__gmlc_opt_is_local(_child)) return true;
					}
					else if (!__gmlc_opt_is_function(_child)) && (__usesArguments(_child)) {
						return true;
					}
				}
			_i++}
		_field_index++}
		return false;
	};

	#region jsDoc
	/// @func    __hasTry(_node)
	/// @desc    Whether a `try` is under a node, nested functions left out.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __hasTry = function(_node) {
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (_child.kind == __GMLC_NodeKind_Try) return true;
					if (!__gmlc_opt_is_function(_child)) && (__hasTry(_child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};

	#region jsDoc
	/// @func    __classify(_node, _parent, _key, _nested, _info)
	/// @desc    Finds the locals that only ever hold a new array and are used only to index it, so no other
	///          variable can reach the array.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode}           _node   : The node
	/// @param   {Struct.ASTNode|Undefined} _parent : The node that holds it
	/// @param   {String}                   _key    : The field of the parent that holds it
	/// @param   {Bool}                     _nested : Whether a nested function holds it
	/// @param   {Struct}                   _info   : Name to {ok, declared}
	#endregion
	static __classify = function(_node, _parent, _key, _nested, _info) {
		if (_node.kind == __GMLC_NodeKind_Identifier) {
			if (__gmlc_opt_is_local(_node)) {
				var _entry = _info[$ _node.name];
				if (_entry == undefined) {
					_entry = { ok: true, declared: false };
					_info[$ _node.name] = _entry;
				}
				if (!__arrayUse(_node, _parent, _key, _nested, _entry)) _entry.ok = false;
			}
			return;
		}
		var _inner = _nested || ((_parent != undefined) && (__gmlc_opt_is_function(_node)));
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			__classify(_slots[_i].node, _node, _slots[_i].key, _inner, _info);
		_i++}
	};

	#region jsDoc
	/// @func    __arrayUse(_node, _parent, _key, _nested, _entry)
	/// @desc    Whether a mention of a local leaves it a private array: indexing it, declaring it with a new array,
	///          assigning it a new array, or returning it.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode}           _node   : The mention
	/// @param   {Struct.ASTNode|Undefined} _parent : The node that holds it
	/// @param   {String}                   _key    : The field of the parent that holds it
	/// @param   {Bool}                     _nested : Whether a nested function holds it
	/// @param   {Struct}                   _entry  : {ok, declared} of the local
	/// @returns {Bool}
	#endregion
	static __arrayUse = function(_node, _parent, _key, _nested, _entry) {
		if (_nested) || (_parent == undefined) return false;
		switch (_parent.kind) {
			case __GMLC_NodeKind_Index:
			return (_key == "object") && (_parent.accessor == "Array");
			case __GMLC_NodeKind_VarDecl:
			if (_key != "target") return false;
			_entry.declared = true;
			return (_parent.init == undefined) || (__fresh(_parent.init));
			case __GMLC_NodeKind_Assign:
			return (_key == "target") && (_parent.op == "=") && (__fresh(_parent.value));
			case __GMLC_NodeKind_Return:
			return true;
		}
		return false;
	};

	#region jsDoc
	/// @func    __fresh(_value)
	/// @desc    Whether an expression makes a new array: `[...]` or `array_create(...)`.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _value : The expression
	/// @returns {Bool}
	#endregion
	static __fresh = function(_value) {
		return (_value.kind == __GMLC_NodeKind_ArrayLiteral) || (__gmlc_opt_builtin_call(_value) == "array_create");
	};
	#endregion

	#region Sets
	#region jsDoc
	/// @func    __union(_a, _b)
	/// @desc    The union of two sets of names; a set is never changed, the first is returned when it already holds
	///          the second.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct} _a : A set
	/// @param   {Struct} _b : Another set
	/// @returns {Struct}
	#endregion
	static __union = function(_a, _b) {
		var _names = struct_get_names(_b);
		var _out = undefined;
		var _i = 0; repeat (array_length(_names)) {
			if (!struct_exists(_a, _names[_i])) {
				if (_out == undefined) _out = variable_clone(_a, 0);
				_out[$ _names[_i]] = true;
			}
		_i++}
		return (_out != undefined) ? _out : _a;
	};

	#region jsDoc
	/// @func    __without(_set, _name)
	/// @desc    A set without one name.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct} _set  : The set
	/// @param   {String} _name : The name
	/// @returns {Struct}
	#endregion
	static __without = function(_set, _name) {
		if (!struct_exists(_set, _name)) return _set;
		var _out = variable_clone(_set, 0);
		struct_remove(_out, _name);
		return _out;
	};

	#region jsDoc
	/// @func    __sameSet(_a, _b)
	/// @desc    Whether two sets hold the same names.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct} _a : A set
	/// @param   {Struct} _b : Another set
	/// @returns {Bool}
	#endregion
	static __sameSet = function(_a, _b) {
		if (_a == _b) return true;
		var _names = struct_get_names(_a);
		if (array_length(_names) != struct_names_count(_b)) return false;
		var _i = 0; repeat (array_length(_names)) {
			if (!struct_exists(_b, _names[_i])) return false;
		_i++}
		return true;
	};

	#region jsDoc
	/// @func    __uses(_node)
	/// @desc    The locals a node reads.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Struct}
	#endregion
	static __uses = function(_node) {
		var _set = {};
		__collect(_node, _set);
		return _set;
	};

	#region jsDoc
	/// @func    __collect(_node, _set)
	/// @desc    Adds the locals a node reads to a set: the target of a plain assignment and of a declaration is not
	///          read, a nested function reads none of them.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _set  : The set
	#endregion
	static __collect = function(_node, _set) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier:
			if (__gmlc_opt_is_local(_node)) _set[$ _node.name] = true;
			return;
			case __GMLC_NodeKind_FunctionExpr:
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			return;
			case __GMLC_NodeKind_Assign:
			if (_node.op == "=") && (__gmlc_opt_is_local(_node.target)) {
				__collect(_node.value, _set);
				return;
			}
			break;
			case __GMLC_NodeKind_VarDecl:
			if (_node.init != undefined) __collect(_node.init, _set);
			return;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__collect(_child, _set);
				}
			_i++}
		_field_index++}
	};
	#endregion

	#region Statements
	#region jsDoc
	/// @func    __result(_live)
	/// @desc    What the walk reports for a statement: the locals live before it, the statements that replace it
	///          (undefined to keep it) with the bare declarations among them, and what it removed.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct} _live : The locals live before the statement
	/// @returns {Struct}
	#endregion
	static __result = function(_live) {
		return { live: _live, items: undefined, phs: undefined, removed: 0, reduced: 0 };
	};

	#region jsDoc
	/// @func    __statement(_statement, _out, _ctx, _in_list)
	/// @desc    Walks a statement backward: the locals live before it, given the locals live after it, and its
	///          dead stores removed. A statement outside a statement list is only walked, never replaced.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {Struct}         _out       : The locals live after it
	/// @param   {Struct}         _ctx       : The function's context
	/// @param   {Bool}           _in_list   : Whether a statement list holds it
	/// @returns {Struct}
	#endregion
	static __statement = function(_statement, _out, _ctx, _in_list) {
		var _result;
		if (_ctx.cx.optimizer.__isNoOp(_statement)) {
			_result = __result(__union(_out, _ctx.candidates));
		}
		else {
			switch (_statement.kind) {
				case __GMLC_NodeKind_ExprStmt:    _result = __exprStmt(_statement, _out, _ctx, _in_list); break;
				case __GMLC_NodeKind_VarDeclList: _result = __varDecls(_statement, _out, _ctx, _in_list); break;
				case __GMLC_NodeKind_Block:       _result = __block(_statement, _out, _ctx); break;
				case __GMLC_NodeKind_If:          _result = __if(_statement, _out, _ctx); break;
				case __GMLC_NodeKind_While:       _result = __while(_statement, _out, _ctx); break;
				case __GMLC_NodeKind_For:         _result = __for(_statement, _out, _ctx); break;
				case __GMLC_NodeKind_Repeat:      _result = __repeat(_statement, _out, _ctx); break;
				case __GMLC_NodeKind_DoUntil:     _result = __doUntil(_statement, _out, _ctx); break;
				case __GMLC_NodeKind_With:        _result = __with(_statement, _out, _ctx); break;
				case __GMLC_NodeKind_Switch:      _result = __switch(_statement, _out, _ctx); break;
				case __GMLC_NodeKind_Try:         _result = __try(_statement, _out, _ctx); break;
				case __GMLC_NodeKind_Return:      _result = __result(__union((_statement.argument != undefined) ? __uses(_statement.argument) : {}, _ctx.exit)); break;
				case __GMLC_NodeKind_Exit:        _result = __result(_ctx.exit); break;
				case __GMLC_NodeKind_Throw:       _result = __result(__union(__uses(_statement.argument), _ctx.handler)); break;
				case __GMLC_NodeKind_Break:       _result = __result(_ctx.brk); break;
				case __GMLC_NodeKind_Continue:    _result = __result(_ctx.cont); break;
				default:                          _result = __result(__union(_out, __uses(_statement))); break;
			}
		}
		// inside a `try` any statement may throw into its handler
		_result.live = __union(_result.live, _ctx.handler);
		return _result;
	};

	#region jsDoc
	/// @func    __exprStmt(_statement, _out, _ctx, _in_list)
	/// @desc    An expression statement: `x = value;` to a local is a store.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {Struct}         _out       : The locals live after it
	/// @param   {Struct}         _ctx       : The function's context
	/// @param   {Bool}           _in_list   : Whether a statement list holds it
	/// @returns {Struct}
	#endregion
	static __exprStmt = function(_statement, _out, _ctx, _in_list) {
		var _expression = _statement.expression;
		var _result;
		if (_expression.kind == __GMLC_NodeKind_Assign) && (_expression.op == "=") && (__gmlc_opt_is_local(_expression.target)) {
			var _name = _expression.target.name;
			var _value = _expression.value;
			if (struct_exists(_ctx.candidates, _name)) {
				if (_in_list) && (!struct_exists(_out, _name)) {
					if (__removable(_value, _ctx.cx, _ctx.with_unsafe)) {
						_result = __result(_out);
						_result.items = [];
						_result.removed = 1;
						return _result;
					}
					if (_value.kind == __GMLC_NodeKind_Call) || (_value.kind == __GMLC_NodeKind_MethodCall) {
						_result = __result(__union(_out, __uses(_value)));
						_result.items = [new ASTExprStmt(_statement.span, _value, _statement.origin)];
						_result.reduced = 1;
						return _result;
					}
				}
				return __result(__union(__without(_out, _name), __uses(_value)));
			}
			return __result(__union(_out, __uses(_value)));
		}
		return __result(__union(_out, __uses(_expression)));
	};

	#region jsDoc
	/// @func    __varDecls(_statement, _out, _ctx, _in_list)
	/// @desc    A `var` statement: a declarator with a value is a store.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {Struct}         _out       : The locals live after it
	/// @param   {Struct}         _ctx       : The function's context
	/// @param   {Bool}           _in_list   : Whether a statement list holds it
	/// @returns {Struct}
	#endregion
	static __varDecls = function(_statement, _out, _ctx, _in_list) {
		var _decls = _statement.declarations;
		var _count = array_length(_decls);
		var _cx = _ctx.cx;
		var _result;
		if (_count == 1) && (_in_list) {
			var _decl = _decls[0];
			var _init = _decl.init;
			var _name = _decl.target.name;
			if (_init == undefined) return __result(_out);
			if (struct_exists(_ctx.candidates, _name)) {
				if (!struct_exists(_out, _name)) {
					var _alone = (_ctx.mentions[$ _name] == 1);
					if (__removable(_init, _cx, _ctx.with_unsafe)) {
						_result = __result(_out);
						_result.removed = 1;
						if (_alone) {
							_result.items = [];
						}
						else {
							_result.items = [__bare(_statement, _decl)];
							_result.phs = [_name];
						}
						return _result;
					}
					if (_init.kind == __GMLC_NodeKind_Call) || (_init.kind == __GMLC_NodeKind_MethodCall) {
						_result = __result(__union(_out, __uses(_init)));
						_result.reduced = 1;
						_result.items = [new ASTExprStmt(_decl.span, _init, _decl.origin)];
						_result.phs = [undefined];
						if (!_alone) {
							array_push(_result.items, __bare(_statement, _decl));
							array_push(_result.phs, _name);
						}
						return _result;
					}
				}
				return __result(__union(__without(_out, _name), __uses(_init)));
			}
			return __result(__union(_out, __uses(_init)));
		}
		var _live = _out;
		var _new = undefined;
		var _removed = 0;
		var _i = _count - 1; repeat (_count) {
			var _declarator = _decls[_i];
			var _value = _declarator.init;
			if (_value != undefined) {
				var _local = _declarator.target.name;
				if (struct_exists(_ctx.candidates, _local)) {
					if (_in_list) && (!struct_exists(_live, _local)) && (__removable(_value, _cx, _ctx.with_unsafe)) {
						if (_new == undefined) {
							_new = array_create(_count);
							array_copy(_new, 0, _decls, 0, _count);
						}
						_new[_i] = new ASTVarDecl(_declarator.span, _declarator.target, undefined, _declarator.origin);
						_removed++;
					}
					else {
						_live = __union(__without(_live, _local), __uses(_value));
					}
				}
				else {
					_live = __union(_live, __uses(_value));
				}
			}
		_i--}
		_result = __result(_live);
		if (_new != undefined) {
			var _copy = variable_clone(_statement, 0);
			_copy.declarations = _new;
			_result.items = [_copy];
			_result.removed = _removed;
		}
		return _result;
	};

	#region jsDoc
	/// @func    __bare(_statement, _decl)
	/// @desc    `var name;` for a declarator whose value was removed.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The `var` statement
	/// @param   {Struct.ASTNode} _decl      : The declarator
	/// @returns {Struct.ASTVarDeclList}
	#endregion
	static __bare = function(_statement, _decl) {
		return new ASTVarDeclList(_statement.span, [new ASTVarDecl(_decl.span, _decl.target, undefined, _decl.origin)], _statement.origin);
	};

	#region jsDoc
	/// @func    __block(_statement, _out, _ctx)
	/// @desc    A block.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The block
	/// @param   {Struct}         _out       : The locals live after it
	/// @param   {Struct}         _ctx       : The function's context
	/// @returns {Struct}
	#endregion
	static __block = function(_statement, _out, _ctx) {
		var _list = __list(_statement.body, _out, _ctx);
		var _result = __result(_list.live);
		_result.removed = _list.removed;
		_result.reduced = _list.reduced;
		if (_list.changed) {
			var _copy = variable_clone(_statement, 0);
			_copy.body = _list.statements;
			_result.items = [_copy];
		}
		return _result;
	};

	#region jsDoc
	/// @func    __if(_statement, _out, _ctx)
	/// @desc    An `if`: live before it is what its test reads and what either branch needs.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The `if`
	/// @param   {Struct}         _out       : The locals live after it
	/// @param   {Struct}         _ctx       : The function's context
	/// @returns {Struct}
	#endregion
	static __if = function(_statement, _out, _ctx) {
		var _consequent = __statement(_statement.consequent, _out, _ctx, false);
		var _alternate = undefined;
		var _live = _consequent.live;
		if (_statement.alternate != undefined) {
			_alternate = __statement(_statement.alternate, _out, _ctx, false);
			_live = __union(_live, _alternate.live);
		}
		else {
			_live = __union(_live, _out);
		}
		var _result = __result(__union(_live, __uses(_statement.test)));
		_result.removed = _consequent.removed;
		_result.reduced = _consequent.reduced;
		var _changed = (_consequent.items != undefined);
		if (_alternate != undefined) {
			_result.removed += _alternate.removed;
			_result.reduced += _alternate.reduced;
			if (_alternate.items != undefined) _changed = true;
		}
		if (_changed) {
			var _copy = variable_clone(_statement, 0);
			if (_consequent.items != undefined) _copy.consequent = _consequent.items[0];
			if (_alternate != undefined) && (_alternate.items != undefined) _copy.alternate = _alternate.items[0];
			_result.items = [_copy];
		}
		return _result;
	};

	#region jsDoc
	/// @func    __loopContext(_ctx, _break, _continue)
	/// @desc    The context inside a loop: what is live after a `break` and after a `continue`.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct} _ctx      : The function's context
	/// @param   {Struct} _break    : The locals live after a `break`
	/// @param   {Struct} _continue : The locals live after a `continue`
	/// @returns {Struct}
	#endregion
	static __loopContext = function(_ctx, _break, _continue) {
		var _inner = variable_clone(_ctx, 0);
		_inner.brk = _break;
		_inner.cont = _continue;
		return _inner;
	};

	#region jsDoc
	/// @func    __loop(_statement, _body, _live)
	/// @desc    The result for a loop: the locals live before it, the removals of its body and, when the body
	///          changed, the loop with the new body.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The loop
	/// @param   {Struct}         _body      : The result for its body
	/// @param   {Struct}         _live      : The locals live before the loop
	/// @returns {Struct}
	#endregion
	static __loop = function(_statement, _body, _live) {
		var _result = __result(_live);
		_result.removed = _body.removed;
		_result.reduced = _body.reduced;
		if (_body.items != undefined) {
			var _copy = variable_clone(_statement, 0);
			_copy.body = _body.items[0];
			_result.items = [_copy];
		}
		return _result;
	};

	#region jsDoc
	/// @func    __while(_statement, _out, _ctx)
	/// @desc    A `while`: the body runs any number of times, the test before each.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The `while`
	/// @param   {Struct}         _out       : The locals live after it
	/// @param   {Struct}         _ctx       : The function's context
	/// @returns {Struct}
	#endregion
	static __while = function(_statement, _out, _ctx) {
		var _head = __union(_out, __uses(_statement.test));
		var _body;
		while (true) {
			_body = __statement(_statement.body, _head, __loopContext(_ctx, _out, _head), false);
			var _next = __union(_head, _body.live);
			if (__sameSet(_next, _head)) break;
			_head = _next;
		}
		return __loop(_statement, _body, _head);
	};

	#region jsDoc
	/// @func    __repeat(_statement, _out, _ctx)
	/// @desc    A `repeat`: the count is read once, the body runs any number of times.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The `repeat`
	/// @param   {Struct}         _out       : The locals live after it
	/// @param   {Struct}         _ctx       : The function's context
	/// @returns {Struct}
	#endregion
	static __repeat = function(_statement, _out, _ctx) {
		var _head = _out;
		var _body;
		while (true) {
			_body = __statement(_statement.body, _head, __loopContext(_ctx, _out, _head), false);
			var _next = __union(_head, _body.live);
			if (__sameSet(_next, _head)) break;
			_head = _next;
		}
		return __loop(_statement, _body, __union(_head, __uses(_statement.count)));
	};

	#region jsDoc
	/// @func    __with(_statement, _out, _ctx)
	/// @desc    A `with`: the body runs for any number of instances.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The `with`
	/// @param   {Struct}         _out       : The locals live after it
	/// @param   {Struct}         _ctx       : The function's context
	/// @returns {Struct}
	#endregion
	static __with = function(_statement, _out, _ctx) {
		var _head = _out;
		var _body;
		var _target = _statement.target;
		var _safe = (_target.kind == __GMLC_NodeKind_Identifier) && (_target.symbol != undefined) && ((_target.symbol.kind == "Asset") || ((_target.symbol.kind == "BuiltinConstant") && ((_target.name == "all") || (_target.name == "noone"))));
		while (true) {
			var _inner = __loopContext(_ctx, _out, _head);
			_inner.with_unsafe = !_safe;
			_body = __statement(_statement.body, _head, _inner, false);
			var _next = __union(_head, _body.live);
			if (__sameSet(_next, _head)) break;
			_head = _next;
		}
		return __loop(_statement, _body, __union(_head, __uses(_target)));
	};

	#region jsDoc
	/// @func    __doUntil(_statement, _out, _ctx)
	/// @desc    A `do until`: the body runs first, then the test decides whether it runs again.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The `do until`
	/// @param   {Struct}         _out       : The locals live after it
	/// @param   {Struct}         _ctx       : The function's context
	/// @returns {Struct}
	#endregion
	static __doUntil = function(_statement, _out, _ctx) {
		var _tail = __union(_out, __uses(_statement.test));
		var _body;
		while (true) {
			_body = __statement(_statement.body, _tail, __loopContext(_ctx, _out, _tail), false);
			var _next = __union(_tail, _body.live);
			if (__sameSet(_next, _tail)) break;
			_tail = _next;
		}
		return __loop(_statement, _body, _body.live);
	};

	#region jsDoc
	/// @func    __for(_statement, _out, _ctx)
	/// @desc    A `for`: the first statement runs once, then the test, the body and the update repeat.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The `for`
	/// @param   {Struct}         _out       : The locals live after it
	/// @param   {Struct}         _ctx       : The function's context
	/// @returns {Struct}
	#endregion
	static __for = function(_statement, _out, _ctx) {
		var _head = (_statement.test != undefined) ? __union(_out, __uses(_statement.test)) : _out;
		var _update;
		var _body;
		while (true) {
			var _continue = _head;
			_update = undefined;
			if (_statement.update != undefined) {
				_update = __statement(_statement.update, _head, _ctx, false);
				_continue = _update.live;
			}
			_body = __statement(_statement.body, _continue, __loopContext(_ctx, _out, _continue), false);
			var _next = __union(_head, _body.live);
			if (__sameSet(_next, _head)) break;
			_head = _next;
		}
		var _init = undefined;
		var _live = _head;
		if (_statement.init != undefined) {
			_init = __statement(_statement.init, _head, _ctx, false);
			_live = _init.live;
		}
		var _result = __loop(_statement, _body, _live);
		if (_update != undefined) {
			_result.removed += _update.removed;
			_result.reduced += _update.reduced;
		}
		if (_init != undefined) {
			_result.removed += _init.removed;
			_result.reduced += _init.reduced;
		}
		var _changed = (_body.items != undefined) || ((_update != undefined) && (_update.items != undefined)) || ((_init != undefined) && (_init.items != undefined));
		if (_changed) {
			var _copy = variable_clone(_statement, 0);
			if (_body.items != undefined) _copy.body = _body.items[0];
			if (_update != undefined) && (_update.items != undefined) _copy.update = _update.items[0];
			if (_init != undefined) && (_init.items != undefined) _copy.init = _init.items[0];
			_result.items = [_copy];
		}
		return _result;
	};

	#region jsDoc
	/// @func    __switch(_statement, _out, _ctx)
	/// @desc    A `switch`: control enters at any case, runs on into the next one unless a `break` leaves.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The `switch`
	/// @param   {Struct}         _out       : The locals live after it
	/// @param   {Struct}         _ctx       : The function's context
	/// @returns {Struct}
	#endregion
	static __switch = function(_statement, _out, _ctx) {
		var _inner = variable_clone(_ctx, 0);
		_inner.brk = _out;
		var _cases = _statement.cases;
		var _count = array_length(_cases);
		var _lists = array_create(_count);
		var _live = {};
		var _has_default = false;
		var _next = _out;
		var _removed = 0;
		var _reduced = 0;
		var _changed = false;
		var _i = _count - 1; repeat (_count) {
			var _case = _cases[_i];
			var _list = __list(_case.body, _next, _inner);
			_lists[_i] = _list;
			_next = _list.live;
			_live = __union(_live, _list.live);
			_removed += _list.removed;
			_reduced += _list.reduced;
			if (_list.changed) _changed = true;
			if (_case.kind == __GMLC_NodeKind_Default) {
				_has_default = true;
			}
			else {
				_live = __union(_live, __uses(_case.test));
			}
		_i--}
		if (!_has_default) _live = __union(_live, _out);
		var _result = __result(__union(_live, __uses(_statement.discriminant)));
		_result.removed = _removed;
		_result.reduced = _reduced;
		if (_changed) {
			var _new_cases = array_create(_count);
			var _k = 0; repeat (_count) {
				if (_lists[_k].changed) {
					_new_cases[_k] = variable_clone(_cases[_k], 0);
					_new_cases[_k].body = _lists[_k].statements;
				}
				else {
					_new_cases[_k] = _cases[_k];
				}
			_k++}
			var _copy = variable_clone(_statement, 0);
			_copy.cases = _new_cases;
			_result.items = [_copy];
		}
		return _result;
	};

	#region jsDoc
	/// @func    __try(_statement, _out, _ctx)
	/// @desc    A `try`: a throw in its body goes to the `catch`, or to the `finally` when there is none; a
	///          jump out of it runs the `finally` first.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The `try`
	/// @param   {Struct}         _out       : The locals live after it
	/// @param   {Struct}         _ctx       : The function's context
	/// @returns {Struct}
	#endregion
	static __try = function(_statement, _out, _ctx) {
		var _finally = _statement.finally_body;
		var _catch = _statement.catch_body;
		var _after = _out;
		var _fin = undefined;
		var _fin_in = undefined;
		if (_finally != undefined) {
			var _fin_out = __union(__union(__union(__union(_out, _ctx.exit), _ctx.brk), _ctx.cont), _ctx.handler);
			_fin = __statement(_finally, _fin_out, _ctx, false);
			_fin_in = _fin.live;
			_after = _fin_in;
		}
		var _body_ctx = variable_clone(_ctx, 0);
		var _catch_ctx = variable_clone(_ctx, 0);
		if (_finally != undefined) {
			_body_ctx.exit = _fin_in;
			_body_ctx.brk = _fin_in;
			_body_ctx.cont = _fin_in;
			_catch_ctx.exit = _fin_in;
			_catch_ctx.brk = _fin_in;
			_catch_ctx.cont = _fin_in;
			_catch_ctx.handler = _fin_in;
		}
		var _caught = undefined;
		if (_catch != undefined) {
			_caught = __statement(_catch, _after, _catch_ctx, false);
			var _catch_in = _caught.live;
			var _param = _statement.catch_param;
			if (_param != undefined) && (_param.kind == __GMLC_NodeKind_Identifier) _catch_in = __without(_catch_in, _param.name);
			_body_ctx.handler = _catch_in;
		}
		else if (_finally != undefined) {
			_body_ctx.handler = _fin_in;
		}
		var _block = __statement(_statement.block, _after, _body_ctx, false);
		var _result = __result(_block.live);
		_result.removed = _block.removed;
		_result.reduced = _block.reduced;
		var _changed = (_block.items != undefined);
		if (_caught != undefined) {
			_result.removed += _caught.removed;
			_result.reduced += _caught.reduced;
			if (_caught.items != undefined) _changed = true;
		}
		if (_fin != undefined) {
			_result.removed += _fin.removed;
			_result.reduced += _fin.reduced;
			if (_fin.items != undefined) _changed = true;
		}
		if (_changed) {
			var _copy = variable_clone(_statement, 0);
			if (_block.items != undefined) _copy.block = _block.items[0];
			if (_caught != undefined) && (_caught.items != undefined) _copy.catch_body = _caught.items[0];
			if (_fin != undefined) && (_fin.items != undefined) _copy.finally_body = _fin.items[0];
			_result.items = [_copy];
		}
		return _result;
	};
	#endregion

	#region Lists
	#region jsDoc
	/// @func    __list(_statements, _out, _ctx)
	/// @desc    Walks a statement list backward, then joins each bare `var` left by a removed initializer to the
	///          plain assignment that follows it and drops overwritten element stores of local arrays.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Array<Struct.ASTNode>} _statements : The statements
	/// @param   {Struct}                _out        : The locals live after the list
	/// @param   {Struct}                _ctx        : The function's context
	/// @returns {Struct} {live, statements, changed, removed, reduced}
	#endregion
	static __list = function(_statements, _out, _ctx) {
		var _count = array_length(_statements);
		var _results = array_create(_count);
		var _live = _out;
		var _removed = 0;
		var _reduced = 0;
		var _any = false;
		var _i = _count - 1; repeat (_count) {
			var _r = __statement(_statements[_i], _live, _ctx, true);
			_results[_i] = _r;
			_live = _r.live;
			_removed += _r.removed;
			_reduced += _r.reduced;
			if (_r.items != undefined) _any = true;
		_i--}
		var _list = { live: _live, statements: _statements, changed: false, removed: _removed, reduced: _reduced };
		if (_any) {
			var _flat = [];
			var _phs = [];
			var _s = 0; repeat (_count) {
				var _items = _results[_s].items;
				if (_items == undefined) {
					array_push(_flat, _statements[_s]);
					array_push(_phs, undefined);
				}
				else {
					var _k = 0; repeat (array_length(_items)) {
						array_push(_flat, _items[_k]);
						array_push(_phs, (_results[_s].phs != undefined) ? _results[_s].phs[_k] : undefined);
					_k++}
				}
			_s++}
			_list.statements = __merge(_flat, _phs, _ctx);
			_list.changed = true;
		}
		var _stores = __arrayStores(_list.statements, _ctx, _list);
		if (_stores != undefined) {
			_list.statements = _stores;
			_list.changed = true;
		}
		return _list;
	};

	#region jsDoc
	/// @func    __merge(_flat, _phs, _ctx)
	/// @desc    Turns the plain assignment that follows a bare `var x;` into `var x = value;` and drops the bare
	///          declaration, when no statement between them mentions `x`.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Array<Struct.ASTNode>} _flat : The statements
	/// @param   {Array<String>}         _phs  : The name a statement declares bare, undefined for the others
	/// @param   {Struct}                _ctx  : The function's context
	/// @returns {Array<Struct.ASTNode>}
	#endregion
	static __merge = function(_flat, _phs, _ctx) {
		var _count = array_length(_flat);
		var _optimizer = _ctx.cx.optimizer;
		var _deleted = array_create(_count, false);
		var _any = false;
		var _a = 0; repeat (_count) {
			var _name = _phs[_a];
			if (_name != undefined) {
				var _j = _a + 1;
				while (_j < _count) {
					var _s = _flat[_j];
					if (_s.kind == __GMLC_NodeKind_ExprStmt) && (_s.expression.kind == __GMLC_NodeKind_Assign) && (_s.expression.op == "=") && (__gmlc_opt_is_local(_s.expression.target)) && (_s.expression.target.name == _name) {
						if (!_optimizer.__isNoOp(_s)) && (__mentions(_s.expression.value, _name) == 0) {
							var _assign = _s.expression;
							_flat[_j] = new ASTVarDeclList(_s.span, [new ASTVarDecl(_assign.span, _assign.target, _assign.value, _s.origin)], _s.origin);
							_deleted[_a] = true;
							_any = true;
						}
						break;
					}
					if (__mentions(_s, _name) > 0) break;
					_j++;
				}
			}
		_a++}
		if (!_any) return _flat;
		var _out = [];
		var _i = 0; repeat (_count) {
			if (!_deleted[_i]) array_push(_out, _flat[_i]);
		_i++}
		return _out;
	};

	#region jsDoc
	/// @func    __arrayStores(_statements, _ctx, _list)
	/// @desc    Drops `a[k] = v;` when `a[k] = w;` follows with nothing between that touches the array or changes
	///          `k`, for a private local array.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Array<Struct.ASTNode>} _statements : The statements
	/// @param   {Struct}                _ctx        : The function's context
	/// @param   {Struct}                _list       : The list result; its removed count grows
	/// @returns {Array<Struct.ASTNode>|Undefined} The statements without the dead stores, undefined for none
	#endregion
	static __arrayStores = function(_statements, _ctx, _list) {
		if (struct_names_count(_ctx.arrays) == 0) return undefined;
		var _count = array_length(_statements);
		var _optimizer = _ctx.cx.optimizer;
		var _deleted = undefined;
		var _i = 0; repeat (_count - 1) {
			var _store = __arrayStore(_statements[_i], _ctx);
			if (_store != undefined) && (!_optimizer.__isNoOp(_statements[_i])) && (__gmlc_opt_is_trivial(_store.key)) && (__removable(_store.value, _ctx.cx, _ctx.with_unsafe)) {
				var _j = _i + 1;
				while (_j < _count) {
					var _next = _statements[_j];
					var _second = __arrayStore(_next, _ctx);
					if (_second != undefined) && (_second.name == _store.name) && (__gmlc_opt_same(_second.key, _store.key)) && (!_optimizer.__isNoOp(_next)) && (!__throws(_ctx.cx, _second.value, _ctx.with_unsafe)) && (__mentions(_second.value, _store.name) == 0) {
						if (_deleted == undefined) _deleted = array_create(_count, false);
						_deleted[_i] = true;
						_list.removed++;
						break;
					}
					if (!__between(_next, _store, _ctx)) break;
					_j++;
				}
			}
		_i++}
		if (_deleted == undefined) return undefined;
		var _out = [];
		var _k = 0; repeat (_count) {
			if (!_deleted[_k]) array_push(_out, _statements[_k]);
		_k++}
		return _out;
	};

	#region jsDoc
	/// @func    __arrayStore(_statement, _ctx)
	/// @desc    The array, the key and the value of `a[k] = v;` for a private local array.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {Struct}         _ctx       : The function's context
	/// @returns {Struct|Undefined} {name, key, value}
	#endregion
	static __arrayStore = function(_statement, _ctx) {
		if (_statement.kind != __GMLC_NodeKind_ExprStmt) return undefined;
		var _expression = _statement.expression;
		if (_expression.kind != __GMLC_NodeKind_Assign) || (_expression.op != "=") return undefined;
		var _target = _expression.target;
		if (_target.kind != __GMLC_NodeKind_Index) || (_target.accessor != "Array") || (array_length(_target.keys) != 1) return undefined;
		if (!__gmlc_opt_is_local(_target.object)) || (!struct_exists(_ctx.arrays, _target.object.name)) return undefined;
		return { name: _target.object.name, key: _target.keys[0], value: _expression.value };
	};

	#region jsDoc
	/// @func    __between(_statement, _store, _ctx)
	/// @desc    Whether a statement may sit between two stores to the same element: no `try` in the function, a
	///          plain statement that does not mention the array and does not change the local variables of the key.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {Struct}         _store     : The first store
	/// @param   {Struct}         _ctx       : The function's context
	/// @returns {Bool}
	#endregion
	static __between = function(_statement, _store, _ctx) {
		if (_ctx.has_try) return false;
		if (_statement.kind != __GMLC_NodeKind_ExprStmt) && (_statement.kind != __GMLC_NodeKind_VarDeclList) return false;
		if (_ctx.cx.optimizer.__isNoOp(_statement)) || (__mentions(_statement, _store.name) > 0) return false;
		var _names = struct_get_names(__uses(_store.key));
		var _i = 0; repeat (array_length(_names)) {
			if (__gmlc_opt_writes(_statement, _names[_i])) return false;
		_i++}
		return true;
	};
	#endregion

	#region Values
	#region jsDoc
	/// @func    __removable(_value, _cx, _unsafe)
	/// @desc    Whether the value of a dead store can go with it: it has no effect, cannot throw and is neither frozen nor an asset reference.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct.ASTNode} _value : The value
	/// @param   {Struct}         _cx    : The pass context
	/// @returns {Bool}
	#endregion
	static __removable = function(_value, _cx, _unsafe) {
		return (!__gmlc_opt_has_effects(_value)) && (!__throws(_cx, _value, _unsafe)) && (!_cx.optimizer.__keepsCode(_value));
	};

	#region jsDoc
	/// @func    __throws(_cx, _node, _unsafe)
	/// @desc    Whether evaluating an expression may throw: only literals, locals, constants, built-in instance
	///          variables of an instance, names, function literals, array and struct literals and calls of built-ins that cannot throw, with arguments
	///          that cannot, never do.
	/// @self    GMLC_Opt_DeadStore
	/// @param   {Struct}         _cx   : The pass context
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Bool}           _unsafe : Whether `self` may be a struct, inside a `with`
	/// @returns {Bool}
	#endregion
	static __throws = function(_cx, _node, _unsafe) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal:
			case __GMLC_NodeKind_FunctionExpr:
			return false;
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				if (_symbol == undefined) return true;
				if (!_unsafe) && (__gmlc_opt_reads_instance_builtin(_cx, _node)) return false;
				switch (_symbol.kind) {
					case "Local": case "BuiltinConstant": case "Enum": case "Asset": case "Macro": case "BuiltinFunction":
					return false;
				}
				return true;
			}
			case __GMLC_NodeKind_ArrayLiteral: {
				var _elements = _node.elements;
				var _e = 0; repeat (array_length(_elements)) {
					if (__throws(_cx, _elements[_e], _unsafe)) return true;
				_e++}
				return false;
			}
			case __GMLC_NodeKind_StructLiteral: {
				var _entries = _node.entries;
				var _s = 0; repeat (array_length(_entries)) {
					if (__throws(_cx, _entries[_s].value, _unsafe)) return true;
				_s++}
				return false;
			}
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) return true;
				var _effects = __GmlcDataEffects();
				var _entry = _effects[$ _name];
				if (_entry == undefined) || (_entry.may_throw) return true;
				var _args = _node.args;
				var _a = 0; repeat (array_length(_args)) {
					if (_args[_a] == undefined) || (__throws(_cx, _args[_a], _unsafe)) return true;
				_a++}
				return !__gmlc_opt_args_accepted(_name, _args, __gmlc_opt_value_type);
			}
		}
		return true;
	};
	#endregion
	#endregion
}
