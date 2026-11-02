#region jsDoc
/// @func    GMLC_Opt_StructAccessCache()
/// @desc    The `struct-access-cache` optimizer pass: a field, a `self` variable or a `global` member read three
///          times or more in a stretch of statements that cannot change it is read once into a local. The first read
///          goes into the local, placed before its statement, and the others read the local:
///          `a = s.hp; b = s.hp * 2; c = s.hp - 1;` becomes `var t = s.hp; a = t; b = t * 2; c = t - 1;`.
/// @returns {Struct.GMLC_Opt_StructAccessCache}
#endregion
function GMLC_Opt_StructAccessCache() : GMLC_OptimizerPass("struct-access-cache") constructor {
	#region Config
	static min_reads = 3;
	static max_rounds = 16;
	static __safeNames = ["irandom", "irandom_range", "random", "random_range", "choose", "randomize", "random_set_seed"];
	static __safePrefixes = ["draw_", "gpu_", "shader_", "surface_", "matrix_", "ds_", "array_"];
	static __callbacks = [
		"array_map", "array_foreach", "array_filter", "array_reduce", "array_sort", "array_find_index", "array_any",
		"array_all", "array_create_ext"
	];
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Caches the repeated reads of one function, again on its own result until nothing changes: a read
	///          cached in a statement lets the next one in it move too. The alias facts are found once: a round
	///          only adds temporaries that hold member reads, which the facts do not know and so treat as possibly
	///          anything, and changes no other local's sources.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _shared = { facts: undefined };
		var _current = __once(_node, _cx, _shared);
		if (_current == undefined) return undefined;
		var _round = 1; repeat (max_rounds - 1) {
			var _next = __once(_current, _cx, _shared);
			if (_next == undefined) break;
			_current = _next;
		_round++}
		return _current;
	};
	
	#region jsDoc
	/// @func    __once(_node, _cx, _shared)
	/// @desc    Caches the repeated reads of one function once.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct.ASTNode} _node   : The function
	/// @param   {Struct}         _cx     : The pass context
	/// @param   {Struct}         _shared : {facts}: the alias facts, kept between rounds
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __once = function(_node, _cx, _shared) {
		var _registry = __gmlc_optimizer_pass_registry();
		var _state = {
			cx: _cx,
			root: _node,
			alias: _registry[$ "alias-analysis"],
			shared: _shared,
			keys: {},
		};
		var _out;
		switch (_node.kind) {
			case __GMLC_NodeKind_Script: {
				var _body = __list(_state, _node.body);
				if (_body == undefined) return undefined;
				_out = variable_clone(_node, 0);
				_out.body = _body;
			break;}
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr: {
				var _block = __block(_state, _node.body);
				if (_block == undefined) return undefined;
				_out = variable_clone(_node, 0);
				_out.body = _block;
			break;}
			default:
			return undefined;
		}
		return _out;
	};
	#endregion
	
	#region Keys
	#region jsDoc
	/// @func    __derive(_node)
	/// @desc    Where a read starts and the members it goes through: a local, `global`, an implicit `self` variable or
	///          a built-in instance variable, then dot accesses. Anything else has no path.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct.ASTNode} _node : The read
	/// @returns {Struct|Undefined} {root: "L", "G", "S" or "B", name, members}
	#endregion
	static __derive = function(_node) {
		if (_node.origin != undefined) return undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				if (_symbol == undefined) return undefined;
				switch (_symbol.kind) {
					case "Local": return { root: "L", name: _node.name, members: [] };
					case "Self": {
						var _entry = __gmlc_opt_builtin_variable(_node.name);
						if (_entry == undefined) return { root: "S", name: "", members: [_node.name] };
						if (_entry.instance) return { root: "B", name: "", members: [_node.name] };
					return undefined;}
					case "BuiltinConstant":
						if (_node.name == "global") return { root: "G", name: "", members: [] };
					break;
				}
			return undefined;}
			case __GMLC_NodeKind_Index: {
				if (_node.accessor != "Dot") || (_node.member == undefined) return undefined;
				var _base = __derive(_node.object);
				if (_base == undefined) || (_base.root == "B") return undefined;
				_base.members = array_concat(_base.members, [_node.member]);
			return _base;}
		}
		return undefined;
	};
	
	#region jsDoc
	/// @func    __chainKey(_node)
	/// @desc    The key of a read worth caching: a chain of dot accesses from a local or `global`, an implicit `self`
	///          variable or a built-in instance variable. A bare local or `global` is not one.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct.ASTNode} _node : The read
	/// @returns {Struct|Undefined} {id, root, name, members}
	#endregion
	static __chainKey = function(_node) {
		var _key = __derive(_node);
		if (_key == undefined) return undefined;
		if ((_key.root == "L") || (_key.root == "G")) && (array_length(_key.members) == 0) return undefined;
		var _path = string_join_ext(".", _key.members);
		switch (_key.root) {
			case "L": _key.id = "L:" + _key.name + "." + _path; break;
			case "G": _key.id = "G:" + _path; break;
			case "S": _key.id = "S:" + _path; break;
			default:  _key.id = "B:" + _path; break;
		}
		return _key;
	};
	
	#region jsDoc
	/// @func    __readInLoop(_node, _id, _looped)
	/// @desc    Whether a key is read inside a loop under a node, nested functions left out.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {String}         _id     : The key's id
	/// @param   {Bool}           _looped : Whether the node is inside a loop
	/// @returns {Bool}
	#endregion
	static __readInLoop = function(_node, _id, _looped) {
		if (__gmlc_opt_is_function(_node)) return false;
		if (_looped) {
			var _key = __chainKey(_node);
			if (_key != undefined) && (_key.id == _id) return true;
		}
		var _inner = _looped || __gmlc_opt_is_loop(_node);
		var _children = _node.children();
		var _c = 0; repeat (array_length(_children)) {
			if (__readInLoop(_children[_c], _id, _inner)) return true;
		_c++}
		return false;
	};

	#region jsDoc
	/// @func    __safeBuiltin(_name)
	/// @desc    Whether a call of a built-in changes no variable of the program and runs none of its code.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {String} _name : The built-in
	/// @returns {Bool}
	#endregion
	static __safeBuiltin = function(_name) {
		switch (__gmlc_opt_call_class(_name)) {
			case "pure": case "observer": case "render":
			return true;
			case "mutator": {
				if (array_contains(__safeNames, _name)) return true;
				if (array_contains(__callbacks, _name)) || (__gmlc_opt_takes_function(_name)) return false;
				var _i = 0; repeat (array_length(__safePrefixes)) {
					if (string_starts_with(_name, __safePrefixes[_i])) return true;
				_i++}
			return false;}
		}
		return false;
	};
	
	#region jsDoc
	/// @func    __baseOf(_node)
	/// @desc    The name of the local a written object is, or undefined when it is anything else.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct.ASTNode} _node : The object
	/// @returns {String|Undefined}
	#endregion
	static __baseOf = function(_node) {
		return __gmlc_opt_is_local(_node) ? _node.name : undefined;
	};
	#endregion
	
	#region Tree
	#region jsDoc
	/// @func    __mapChildren(_state, _node, _id, _name)
	/// @desc    The node with every read of the key _id in its children replaced by a read of the local _name, or
	///          undefined when it holds none. Only the changed nodes and the ones above them are copied.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {String}         _id    : The key
	/// @param   {String}         _name  : The local
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __mapChildren = function(_state, _node, _id, _name) {
		var _copy = undefined;
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new = __substitute(_state, _slot.node, _id, _name);
			if (_new != undefined) {
				if (_copy == undefined) {
					_copy = variable_clone(_node, 0);
					var _fields = _node.childFields;
					var _f = 0; repeat (array_length(_fields)) {
						if (is_array(_copy[$ _fields[_f]])) _copy[$ _fields[_f]] = variable_clone(_copy[$ _fields[_f]], 0);
					_f++}
				}
				if (_slot.index == undefined) {
					_copy[$ _slot.key] = _new;
				}
				else {
					_copy[$ _slot.key][_slot.index] = _new;
				}
			}
		_i++}
		return _copy;
	};
	
	#region jsDoc
	/// @func    __substitute(_state, _node, _id, _name)
	/// @desc    The node with every read of the key _id replaced by a read of the local _name, or undefined when it
	///          holds none.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {String}         _id    : The key
	/// @param   {String}         _name  : The local
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __substitute = function(_state, _node, _id, _name) {
		if (_state.cx.optimizer.__isNoOp(_node)) return undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr:
			case __GMLC_NodeKind_With:
			return undefined;
			case __GMLC_NodeKind_StructEntry:
				if (_node.shorthand) return undefined;
			break;
			case __GMLC_NodeKind_Identifier: {
				var _key = __chainKey(_node);
				if (_key != undefined) && (_key.id == _id) return __gmlc_opt_local(_name, _node.span);
			return undefined;}
			case __GMLC_NodeKind_Index: {
				if (_node.accessor == "Dot") {
					var _dotKey = __chainKey(_node);
					if (_dotKey != undefined) {
						return (_dotKey.id == _id) ? __gmlc_opt_local(_name, _node.span) : undefined;
					}
				}
			break;}
		}
		return __mapChildren(_state, _node, _id, _name);
	};
	#endregion
	
	#region Scanning
	#region jsDoc
	/// @func    __facts(_state)
	/// @desc    The alias facts of the function, found when first needed.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct} _state : The pass state
	/// @returns {Struct}
	#endregion
	static __facts = function(_state) {
		if (_state.shared.facts == undefined) _state.shared.facts = _state.alias.analyze(_state.root, _state.cx.unit.fn_id);
		return _state.shared.facts;
	};
	
	#region jsDoc
	/// @func    __kills(_state, _write, _key)
	/// @desc    Whether a write may change what a key reads.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct} _state : The pass state
	/// @param   {Struct} _write : {kind, name, base}
	/// @param   {Struct} _key   : The key
	/// @returns {Bool}
	#endregion
	static __kills = function(_state, _write, _key) {
		switch (_write.kind) {
			case "all": return true;
			case "local": return (_key.root == "L") && (_key.name == _write.name);
			case "self": return (_key.root == "S") && (_key.members[0] == _write.name);
			case "builtin": return (_key.root == "B");
			case "member": {
				var _members = _key.members;
				if (array_length(_members) > 1) return array_contains(_members, _write.name);
				if (_members[0] != _write.name) return false;
				if (_write.base == undefined) return true;
				if (_key.root == "L") return _state.alias.mayAlias(__facts(_state), _write.base, _key.name);
				return !_state.alias.isKnown(__facts(_state), _write.base);
			}
			case "dynamic": {
				if (_write.base == undefined) return true;
				if (!_state.alias.isKnown(__facts(_state), _write.base)) return true;
				if (_key.root == "L") return (array_length(_key.members) > 1) || _state.alias.mayAlias(__facts(_state), _write.base, _key.name);
				return false;
			}
		}
		return true;
	};
	
	#region jsDoc
	/// @func    __barrier(_state, _info, _key)
	/// @desc    Whether a statement ends a region of a key: it runs unknown code or may write what the key reads.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct} _state : The pass state
	/// @param   {Struct} _info  : The statement's info
	/// @param   {Struct} _key   : The key
	/// @returns {Bool}
	#endregion
	static __barrier = function(_state, _info, _key) {
		if (_info.clobber) return true;
		var _i = 0; repeat (array_length(_info.writes)) {
			if (__kills(_state, _info.writes[_i], _key)) return true;
		_i++}
		return false;
	};
	
	#region jsDoc
	/// @func    __record(_state, _key, _info)
	/// @desc    Counts a read of a key in a statement.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct} _state : The pass state
	/// @param   {Struct} _key   : The key
	/// @param   {Struct} _info  : The statement's info
	#endregion
	static __record = function(_state, _key, _info) {
		var _id = _key.id;
		var _count = _info.counts[$ _id] ?? 0;
		if (_count == 0) array_push(_info.order, _id);
		_info.counts[$ _id] = _count + 1;
		if (_state.keys[$ _id] == undefined) _state.keys[$ _id] = _key;
	};
	
	#region jsDoc
	/// @func    __writeIdentifier(_node, _info)
	/// @desc    Records the write of a name.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct.ASTNode} _node : The name
	/// @param   {Struct}         _info : The statement's info
	#endregion
	static __writeIdentifier = function(_node, _info) {
		if (_node.kind != __GMLC_NodeKind_Identifier) || (_node.symbol == undefined) return;
		switch (_node.symbol.kind) {
			case "Local": array_push(_info.writes, { kind: "local", name: _node.name, base: undefined }); break;
			case "Self":
				if (__gmlc_opt_builtin_variable(_node.name) != undefined) {
					array_push(_info.writes, { kind: "builtin", name: "", base: undefined });
				}
				else {
					array_push(_info.writes, { kind: "self", name: _node.name, base: undefined });
				}
			break;
		}
	};
	
	#region jsDoc
	/// @func    __scanTarget(_state, _target, _info)
	/// @desc    Records the write of an assignment or increment target and the reads inside it.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct}         _state  : The pass state
	/// @param   {Struct.ASTNode} _target : The target
	/// @param   {Struct}         _info   : The statement's info
	#endregion
	static __scanTarget = function(_state, _target, _info) {
		if (_target.kind == __GMLC_NodeKind_Identifier) {
			__writeIdentifier(_target, _info);
		}
		else if (_target.kind == __GMLC_NodeKind_Index) {
			switch (_target.accessor) {
				case "Dot":
					array_push(_info.writes, { kind: "member", name: _target.member, base: __baseOf(_target.object) });
					__scan(_state, _target.object, _info);
				break;
				case "Array": case "Array2D": case "ArrayAt": case "Array2DAt": {
					var _k = 0; repeat (array_length(_target.keys)) {
						__scan(_state, _target.keys[_k], _info);
					_k++}
					__elemWrite(_state, _target.object, _info);
				break;}
				case "Struct": {
					array_push(_info.writes, { kind: "dynamic", name: "", base: __baseOf(_target.object) });
					__scan(_state, _target.object, _info);
					var _s = 0; repeat (array_length(_target.keys)) {
						__scan(_state, _target.keys[_s], _info);
					_s++}
				break;}
				default: {
					__scan(_state, _target.object, _info);
					var _d = 0; repeat (array_length(_target.keys)) {
						__scan(_state, _target.keys[_d], _info);
					_d++}
				break;}
			}
		}
		else {
			array_push(_info.writes, { kind: "all", name: "", base: undefined });
			__scan(_state, _target, _info);
		}
	};
	
	#region jsDoc
	/// @func    __elemWrite(_state, _object, _info)
	/// @desc    An element written into an array rebinds the array's holder (copy on write): records that write.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct}         _state  : The pass state
	/// @param   {Struct.ASTNode} _object : The array's holder
	/// @param   {Struct}         _info   : The statement's info
	#endregion
	static __elemWrite = function(_state, _object, _info) {
		if (_object.kind == __GMLC_NodeKind_Identifier) {
			__writeIdentifier(_object, _info);
			return;
		}
		if (_object.kind == __GMLC_NodeKind_Index) {
			switch (_object.accessor) {
				case "Dot":
					array_push(_info.writes, { kind: "member", name: _object.member, base: __baseOf(_object.object) });
					__scan(_state, _object.object, _info);
				return;
				case "Array": case "Array2D": case "ArrayAt": case "Array2DAt": {
					var _k = 0; repeat (array_length(_object.keys)) {
						__scan(_state, _object.keys[_k], _info);
					_k++}
					__elemWrite(_state, _object.object, _info);
				return;}
			}
		}
		array_push(_info.writes, { kind: "all", name: "", base: undefined });
		__scan(_state, _object, _info);
	};
	
	#region jsDoc
	/// @func    __scan(_state, _node, _info)
	/// @desc    What a node does: the unknown code it runs, the writes it makes and the cacheable reads it holds.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Struct}         _info  : The statement's info
	#endregion
	static __scan = function(_state, _node, _info) {
		if (_state.cx.optimizer.__isNoOp(_node)) {
			_info.clobber = true;
			return;
		}
		switch (_node.kind) {
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr:
			return;
			case __GMLC_NodeKind_With:
			case __GMLC_NodeKind_Delete:
			case __GMLC_NodeKind_New:
			case __GMLC_NodeKind_MethodCall:
				_info.clobber = true;
			return;
			case __GMLC_NodeKind_Call: {
				var _builtin = __gmlc_opt_builtin_call(_node);
				if (_builtin != undefined) {
					if (!__safeBuiltin(_builtin)) _info.clobber = true;
				}
				else {
					_info.clobber = true;
					__scan(_state, _node.callee, _info);
				}
				var _a = 0; repeat (array_length(_node.args)) {
					__scan(_state, _node.args[_a], _info);
				_a++}
			return;}
			case __GMLC_NodeKind_Assign:
				__scanTarget(_state, _node.target, _info);
				__scan(_state, _node.value, _info);
			return;
			case __GMLC_NodeKind_Update:
				__scanTarget(_state, _node.argument, _info);
			return;
			case __GMLC_NodeKind_VarDecl:
				if (_node.init != undefined) __scan(_state, _node.init, _info);
				__writeIdentifier(_node.target, _info);
			return;
			case __GMLC_NodeKind_Try:
				__scan(_state, _node.block, _info);
				if (_node.catch_param != undefined) __writeIdentifier(_node.catch_param, _info);
				if (_node.catch_body != undefined) __scan(_state, _node.catch_body, _info);
				if (_node.finally_body != undefined) __scan(_state, _node.finally_body, _info);
			return;
			case __GMLC_NodeKind_StructEntry:
				if (_node.shorthand) return;
			break;
			case __GMLC_NodeKind_Index: {
				if (_node.accessor == "Dot") {
					var _key = __chainKey(_node);
					if (_key != undefined) {
						__record(_state, _key, _info);
					}
					else {
						__scan(_state, _node.object, _info);
					}
				}
				else {
					__scan(_state, _node.object, _info);
					var _k = 0; repeat (array_length(_node.keys)) {
						__scan(_state, _node.keys[_k], _info);
					_k++}
				}
			return;}
			case __GMLC_NodeKind_Identifier: {
				var _identKey = __chainKey(_node);
				if (_identKey != undefined) __record(_state, _identKey, _info);
			return;}
		}
		var _children = _node.children();
		var _c = 0; repeat (array_length(_children)) {
			__scan(_state, _children[_c], _info);
		_c++}
	};
	
	#region jsDoc
	/// @func    __headsExpr(_state, _e, _out, _walk)
	/// @desc    The cacheable reads an expression always makes, in evaluation order, that nothing evaluated before
	///          them in the statement can throw ahead of. _walk.ok says that nothing evaluated so far can throw.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _e     : The expression
	/// @param   {Array<Struct>}  _out   : {id, node} per read
	/// @param   {Struct}         _walk  : {ok}
	#endregion
	static __headsExpr = function(_state, _e, _out, _walk) {
		switch (_e.kind) {
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr:
			case __GMLC_NodeKind_Literal:
			case __GMLC_NodeKind_Nameof:
			return;
			case __GMLC_NodeKind_Logical:
			case __GMLC_NodeKind_Nullish:
				__headsExpr(_state, _e.left, _out, _walk);
				_walk.ok = false;
			return;
			case __GMLC_NodeKind_Conditional:
				__headsExpr(_state, _e.test, _out, _walk);
				_walk.ok = false;
			return;
			case __GMLC_NodeKind_Assign:
				if (_e.target.kind != __GMLC_NodeKind_Identifier) _walk.ok = false;
				__headsExpr(_state, _e.value, _out, _walk);
				_walk.ok = false;
			return;
			case __GMLC_NodeKind_Update:
			case __GMLC_NodeKind_MethodCall:
			case __GMLC_NodeKind_New:
			case __GMLC_NodeKind_With:
			case __GMLC_NodeKind_Delete:
				_walk.ok = false;
			return;
			case __GMLC_NodeKind_Call: {
				var _a = 0; repeat (array_length(_e.args)) {
					__headsExpr(_state, _e.args[_a], _out, _walk);
				_a++}
				if (__gmlc_opt_may_throw(_e)) _walk.ok = false;
			return;}
			case __GMLC_NodeKind_StructEntry:
				if (_e.shorthand) {
					_walk.ok = false;
					return;
				}
			break;
			case __GMLC_NodeKind_Index: {
				var _key = __chainKey(_e);
				if (_key != undefined) {
					if (_walk.ok) array_push(_out, { id: _key.id, node: _e });
				}
				else {
					__headsExpr(_state, _e.object, _out, _walk);
					if (_e.accessor != "Dot") {
						var _k = 0; repeat (array_length(_e.keys)) {
							__headsExpr(_state, _e.keys[_k], _out, _walk);
						_k++}
					}
				}
				_walk.ok = false;
			return;}
			case __GMLC_NodeKind_Identifier: {
				var _identKey = __chainKey(_e);
				if (_identKey != undefined) && (_walk.ok) array_push(_out, { id: _identKey.id, node: _e });
				if (__gmlc_opt_may_throw(_e)) && (!__gmlc_opt_reads_instance_builtin(_state.cx, _e)) _walk.ok = false;
			return;}
		}
		var _children = _e.children();
		var _c = 0; repeat (array_length(_children)) {
			__headsExpr(_state, _children[_c], _out, _walk);
		_c++}
		_walk.ok = false;
	};
	
	#region jsDoc
	/// @func    __headsStmt(_state, _stmt, _out)
	/// @desc    The cacheable reads a statement makes before it does anything else, in evaluation order.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _stmt  : The statement
	/// @param   {Array<Struct>}  _out   : {id, node} per read
	#endregion
	static __headsStmt = function(_state, _stmt, _out) {
		__headsIn(_state, _stmt, _out, { ok: true });
	};
	
	#region jsDoc
	/// @func    __headsIn(_state, _stmt, _out, _walk)
	/// @desc    `__headsStmt` continuing a walk: the start of a `for` is part of the same evaluation as its test.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _stmt  : The statement
	/// @param   {Array<Struct>}  _out   : {id, node} per read
	/// @param   {Struct}         _walk  : {ok}
	#endregion
	static __headsIn = function(_state, _stmt, _out, _walk) {
		switch (_stmt.kind) {
			case __GMLC_NodeKind_ExprStmt: __headsExpr(_state, _stmt.expression, _out, _walk); break;
			case __GMLC_NodeKind_Return:
				if (_stmt.argument != undefined) __headsExpr(_state, _stmt.argument, _out, _walk);
			break;
			case __GMLC_NodeKind_Throw: __headsExpr(_state, _stmt.argument, _out, _walk); break;
			case __GMLC_NodeKind_VarDeclList: {
				var _d = 0; repeat (array_length(_stmt.declarations)) {
					var _init = _stmt.declarations[_d].init;
					if (_init != undefined) __headsExpr(_state, _init, _out, _walk);
				_d++}
			break;}
			case __GMLC_NodeKind_If: __headsExpr(_state, _stmt.test, _out, _walk); break;
			case __GMLC_NodeKind_While: __headsExpr(_state, _stmt.test, _out, _walk); break;
			case __GMLC_NodeKind_Repeat: __headsExpr(_state, _stmt.count, _out, _walk); break;
			case __GMLC_NodeKind_Switch: __headsExpr(_state, _stmt.discriminant, _out, _walk); break;
			case __GMLC_NodeKind_For:
				if (_stmt.init != undefined) __headsIn(_state, _stmt.init, _out, _walk);
				if (_stmt.test != undefined) __headsExpr(_state, _stmt.test, _out, _walk);
			break;
		}
	};
	
	#region jsDoc
	/// @func    __statementInfo(_state, _stmt)
	/// @desc    What a statement does: whether it runs unknown code, its writes, the reads it holds and the reads it
	///          makes before anything else.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _stmt  : The statement
	/// @returns {Struct} {clobber, writes, order, counts, heads}
	#endregion
	static __statementInfo = function(_state, _stmt) {
		var _info = { clobber: false, writes: [], order: [], counts: {}, heads: [] };
		__scan(_state, _stmt, _info);
		var _heads = [];
		__headsStmt(_state, _stmt, _heads);
		var _i = 0; repeat (array_length(_heads)) {
			array_push(_info.heads, _heads[_i].id);
		_i++}
		return _info;
	};
	#endregion
	
	#region Lists
	#region jsDoc
	/// @func    __list(_state, _stmts)
	/// @desc    A statement list with its regions cached, or undefined when nothing changes. A region of a key starts
	///          at the first statement that reads the key before anything else and runs up to the next statement that
	///          may change it; it is cached when it holds at least `min_reads` reads.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct}        _state : The pass state
	/// @param   {Array<Struct>} _stmts : The statements
	/// @returns {Array<Struct>|Undefined}
	#endregion
	static __list = function(_state, _stmts) {
		var _cur = array_create(array_length(_stmts));
		array_copy(_cur, 0, _stmts, 0, array_length(_stmts));
		var _infos = [];
		var _s = 0; repeat (array_length(_cur)) {
			array_push(_infos, __statementInfo(_state, _cur[_s]));
		_s++}
		var _order = [];
		_s = 0; repeat (array_length(_infos)) {
			var _heads = _infos[_s].heads;
			array_copy(_order, array_length(_order), _heads, 0, array_length(_heads));
		_s++}
		_order = array_unique(_order);
		var _changed = false;
		var _o = 0; repeat (array_length(_order)) {
			var _id = _order[_o];
			var _key = _state.keys[$ _id];
			if (_key != undefined) {
				var _i = 0;
				while (_i < array_length(_cur)) {
					if (!array_contains(_infos[_i].heads, _id)) || (__barrier(_state, _infos[_i], _key)) {
						_i++;
						continue;
					}
					var _e = _i;
					var _count = _infos[_i].counts[$ _id] ?? 0;
					var _j = _i + 1;
					while (_j < array_length(_cur)) && (!__barrier(_state, _infos[_j], _key)) {
						_count += _infos[_j].counts[$ _id] ?? 0;
						_e = _j;
						_j++;
					}
					if (_count < min_reads) {
						_i = _e + 1;
						continue;
					}
					// an instance variable is cached only for reads inside a loop: otherwise the local's write costs more
					// than the reads it saves
					if ((_key.root == "S") || (_key.root == "B")) && (array_length(_key.members) == 1) {
						var _looped = false;
						var _r = _i; repeat (_e - _i + 1) {
							if (__readInLoop(_cur[_r], _id, false)) _looped = true;
						_r++}
						if (!_looped) {
							_i = _e + 1;
							continue;
						}
					}
					var _found = [];
					__headsStmt(_state, _cur[_i], _found);
					var _first = undefined;
					var _f = 0; repeat (array_length(_found)) {
						if (_found[_f].id == _id) {
							_first = _found[_f].node;
							break;
						}
					_f++}
					if (_first == undefined) {
						_i = _e + 1;
						continue;
					}
					var _span = __gmlc_opt_span_point(_cur[_i].span);
					var _name = _state.cx.optimizer.newTemporary(_state.cx);
					var _k = _i; repeat (_e - _i + 1) {
						var _new = __substitute(_state, _cur[_k], _id, _name);
						if (_new != undefined) _cur[_k] = _new;
					_k++}
					var _init = __gmlc_opt_clone(_first);
					__gmlc_opt_retag_span(_init, _span);
					array_insert(_cur, _i, __gmlc_opt_var(_name, _init, _span));
					array_insert(_infos, _i, { clobber: false, writes: [], order: [], counts: {}, heads: [] });
					repeat (_count - 1) {
						_state.cx.stats[$ "reads_cached"]++;
					}
					_changed = true;
					_i = _e + 2;
				}
			}
		_o++}
		_s = 0; repeat (array_length(_cur)) {
			var _nested = __nested(_state, _cur[_s]);
			if (_nested != undefined) {
				_cur[_s] = _nested;
				_changed = true;
			}
		_s++}
		return _changed ? _cur : undefined;
	};
	
	#region jsDoc
	/// @func    __block(_state, _node)
	/// @desc    A block with its statement list cached, or undefined when nothing changes.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _node  : The block
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __block = function(_state, _node) {
		if (_node.kind != __GMLC_NodeKind_Block) return undefined;
		var _body = __list(_state, _node.body);
		if (_body == undefined) return undefined;
		var _out = variable_clone(_node, 0);
		_out.body = _body;
		return _out;
	};
	
	#region jsDoc
	/// @func    __nested(_state, _stmt)
	/// @desc    A statement with the lists inside it cached, or undefined when nothing changes. The body of a
	///          `with` is left alone: `self` is another instance there.
	/// @self    GMLC_Opt_StructAccessCache
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _stmt  : The statement
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __nested = function(_state, _stmt) {
		if (_state.cx.optimizer.__isNoOp(_stmt)) return undefined;
		switch (_stmt.kind) {
			case __GMLC_NodeKind_If: {
				var _consequent = __block(_state, _stmt.consequent);
				var _alternate = (_stmt.alternate != undefined) ? __block(_state, _stmt.alternate) : undefined;
				if (_consequent == undefined) && (_alternate == undefined) return undefined;
				var _if = variable_clone(_stmt, 0);
				if (_consequent != undefined) _if.consequent = _consequent;
				if (_alternate != undefined) _if.alternate = _alternate;
			return _if;}
			case __GMLC_NodeKind_For:
			case __GMLC_NodeKind_While:
			case __GMLC_NodeKind_Repeat:
			case __GMLC_NodeKind_DoUntil: {
				var _body = __block(_state, _stmt.body);
				if (_body == undefined) return undefined;
				var _loop = variable_clone(_stmt, 0);
				_loop.body = _body;
			return _loop;}
			case __GMLC_NodeKind_Block:
			return __block(_state, _stmt);
			case __GMLC_NodeKind_Switch: {
				var _switch = undefined;
				var _k = 0; repeat (array_length(_stmt.cases)) {
					var _case = _stmt.cases[_k];
					var _list = __list(_state, _case.body);
					if (_list != undefined) {
						if (_switch == undefined) {
							_switch = variable_clone(_stmt, 0);
							_switch.cases = variable_clone(_stmt.cases, 0);
						}
						var _newCase = variable_clone(_case, 0);
						_newCase.body = _list;
						_switch.cases[_k] = _newCase;
					}
				_k++}
			return _switch;}
			case __GMLC_NodeKind_Try: {
				var _try = __block(_state, _stmt.block);
				var _catch = (_stmt.catch_body != undefined) ? __block(_state, _stmt.catch_body) : undefined;
				var _finally = (_stmt.finally_body != undefined) ? __block(_state, _stmt.finally_body) : undefined;
				if (_try == undefined) && (_catch == undefined) && (_finally == undefined) return undefined;
				var _out = variable_clone(_stmt, 0);
				if (_try != undefined) _out.block = _try;
				if (_catch != undefined) _out.catch_body = _catch;
				if (_finally != undefined) _out.finally_body = _finally;
			return _out;}
		}
		return undefined;
	};
	#endregion
}
