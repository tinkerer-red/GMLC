#region jsDoc
/// @func    GMLC_Opt_NullishHoist()
/// @desc    The `nullish-hoist` optimizer pass: a `?.` chain read in a statement is read hop by hop into locals before
///          the statement, each hop tested for undefined, instead of inside the expression:
///          `x = a?.b?.c;` becomes `var t = undefined; if (!is_undefined(a)) { var u = struct_get(a, "b"); if (!is_undefined(u)) { t = struct_get(u, "c"); } } x = t;`.
///          A chain is moved only where everything the statement evaluates before it only reads.
/// @returns {Struct.GMLC_Opt_NullishHoist}
#endregion
function GMLC_Opt_NullishHoist() : GMLC_OptimizerPass("nullish-hoist") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Reads every `?.` chain of one function that may move before its statement into locals, hop by hop.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _state = { cx: _cx, unsure_self: false };
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
	
	#region Chains
	#region jsDoc
	/// @func    __extCall(_node, _name)
	/// @desc    The call of an extension-made function of the given name, or undefined.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The function
	/// @returns {Struct.ASTCall|Undefined}
	#endregion
	static __extCall = function(_node, _name) {
		if (_node.kind != __GMLC_NodeKind_Call) return undefined;
		var _callee = _node.callee;
		if (_callee.kind != __GMLC_NodeKind_Identifier) || (_callee.origin == undefined) return undefined;
		var _origin = _callee.origin;
		if (_callee.name == _name) && (_origin.kind == "extension") && (_origin.name == "nullish-chaining") return _node;
		return undefined;
	};
	
	#region jsDoc
	/// @func    __peel(_node)
	/// @desc    The base, the key nodes and the path to the base of the hops of a chain: `struct_get(struct_get(b,
	///          "k") ?? static_get(global), "m")` gives `b` and `["k", "m"]`.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct.ASTNode} _node : The outermost hop
	/// @returns {Struct|Undefined} {base, keys, path}
	#endregion
	static __peel = function(_node) {
		var _call = __extCall(_node, "struct_get");
		if (_call == undefined) || (array_length(_call.args) != 2) return undefined;
		var _key = _call.args[1];
		if (_key.kind != __GMLC_NodeKind_Literal) || (_key.ty != "string") return undefined;
		var _inner = _call.args[0];
		if (_inner.kind == __GMLC_NodeKind_Nullish) {
			var _empty = __extCall(_inner.right, "static_get");
			if (_empty != undefined) && (array_length(_empty.args) == 1) {
				var _sub = __peel(_inner.left);
				var _peeled;
				if (_sub != undefined) {
					_peeled = { base: _sub.base, keys: _sub.keys, path: array_concat([1, 0], _sub.path) };
				}
				else {
					_peeled = { base: _inner.left, keys: [], path: [1, 0] };
				}
				array_push(_peeled.keys, _key);
				return _peeled;
			}
		}
		return { base: _inner, keys: [_key], path: [1] };
	};
	
	#region jsDoc
	/// @func    __parseChain(_node)
	/// @desc    The chain a node is, or undefined.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Struct|Undefined} {base, keys, plain, base_path, callee}
	#endregion
	static __parseChain = function(_node) {
		if (_node.kind == __GMLC_NodeKind_Conditional) {
			var _test = __extCall(_node.test, "is_undefined");
			if (_test == undefined) || (array_length(_test.args) != 1) return undefined;
			if (_node.consequent.kind != __GMLC_NodeKind_Literal) || (_node.consequent.ty != "undefined") return undefined;
			var _peeled = __peel(_node.alternate);
			if (_peeled == undefined) return undefined;
			if (!__gmlc_opt_same(_peeled.base, _test.args[0])) return undefined;
			var _outer = __extCall(_node.alternate, "struct_get");
			if (_outer == undefined) return undefined;
			return { base: _peeled.base, keys: _peeled.keys, plain: true, base_path: array_concat([2], _peeled.path), callee: _outer.callee };
		}
		if (_node.kind == __GMLC_NodeKind_Call) {
			var _hops = __peel(_node);
			if (_hops == undefined) return undefined;
			var _call = __extCall(_node, "struct_get");
			if (_call == undefined) return undefined;
			return { base: _hops.base, keys: _hops.keys, plain: false, base_path: _hops.path, callee: _call.callee };
		}
		return undefined;
	};
	
	#region jsDoc
	/// @func    __readsBuiltin(_state, _node)
	/// @desc    Whether a node reads a built-in instance variable of an instance `self`, so the read cannot throw.
	///          Inside the body of a `with` whose target may be a struct, `self` may not be an instance.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _node  : The node
	/// @returns {Bool}
	#endregion
	static __readsBuiltin = function(_state, _node) {
		return (!_state.unsure_self) && __gmlc_opt_reads_instance_builtin(_state.cx, _node);
	};
	
	#region jsDoc
	/// @func    __allAllowed(_state, _node)
	/// @desc    Whether an expression only reads what cannot throw: literals and names.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _node  : The expression
	/// @returns {Bool}
	#endregion
	static __allAllowed = function(_state, _node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal:
			case __GMLC_NodeKind_Nameof:
			case __GMLC_NodeKind_FunctionExpr:
			return true;
			case __GMLC_NodeKind_Identifier:
			return (!__gmlc_opt_may_throw(_node)) || __readsBuiltin(_state, _node);
		}
		return false;
	};
	#endregion
	
	#region Tree
	#region jsDoc
	/// @func    __nodeAt(_node, _path)
	/// @desc    The node at a path of child numbers, or undefined.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct.ASTNode} _node : The root
	/// @param   {Array<Real>}    _path : The child numbers
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __nodeAt = function(_node, _path) {
		var _at = _node;
		var _i = 0; repeat (array_length(_path)) {
			var _children = _at.children();
			if (_path[_i] >= array_length(_children)) return undefined;
			_at = _children[_path[_i]];
		_i++}
		return _at;
	};
	
	#region jsDoc
	/// @func    __replaceAt(_node, _path, _depth, _new)
	/// @desc    The node with the node at a path of child numbers replaced. Only the nodes on the path are copied.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct.ASTNode} _node  : The root
	/// @param   {Array<Real>}    _path  : The child numbers
	/// @param   {Real}           _depth : How far down the path _node is
	/// @param   {Struct.ASTNode} _new   : The replacement
	/// @returns {Struct.ASTNode}
	#endregion
	static __replaceAt = function(_node, _path, _depth, _new) {
		if (_depth == array_length(_path)) return _new;
		var _slots = _node.childSlots();
		if (_path[_depth] >= array_length(_slots)) return _node;
		var _slot = _slots[_path[_depth]];
		var _child = __replaceAt(_slot.node, _path, _depth + 1, _new);
		var _copy = variable_clone(_node, 0);
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			if (is_array(_copy[$ _fields[_f]])) _copy[$ _fields[_f]] = variable_clone(_copy[$ _fields[_f]], 0);
		_f++}
		if (_slot.index == undefined) {
			_copy[$ _slot.key] = _child;
		}
		else {
			_copy[$ _slot.key][_slot.index] = _child;
		}
		return _copy;
	};
	
	#region jsDoc
	/// @func    __call(_template, _name, _args, _span)
	/// @desc    A call of an extension-made function, its callee copied from the chain's own.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct.ASTNode}        _template : A callee of the chain
	/// @param   {String}                _name     : The function
	/// @param   {Array<Struct.ASTNode>} _args     : The arguments
	/// @param   {Struct.GMLC_Span}      _span     : The span
	/// @returns {Struct.ASTCall}
	#endregion
	static __call = function(_template, _name, _args, _span) {
		var _callee = new ASTIdentifier(_span, _name, _template.origin);
		_callee.symbol = new GMLC_Symbol("BuiltinFunction", _name, undefined);
		return new ASTCall(_span, _callee, _args);
	};
	
	#endregion
	
	#region Sites
	#region jsDoc
	/// @func    __find(_state, _node, _walk, _cond, _path)
	/// @desc    The path to the first chain in evaluation order that may move before its statement, or undefined.
	///          _walk.ok says that everything evaluated so far only reads; _cond that the node is evaluated only
	///          sometimes.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Struct}         _walk  : {ok}
	/// @param   {Bool}           _cond  : Whether the node is evaluated only sometimes
	/// @param   {Array<Real>}    _path  : The path to the node
	/// @returns {Array<Real>|Undefined}
	#endregion
	static __find = function(_state, _node, _walk, _cond, _path) {
		if (_state.cx.optimizer.__isNoOp(_node)) {
			_walk.ok = false;
			return undefined;
		}
		var _chain = __parseChain(_node);
		if (_chain != undefined) {
			var _before = _walk.ok;
			if (!_chain.plain) {
				var _base = __nodeAt(_node, _chain.base_path);
				if (_base != undefined) {
					var _depth = array_length(_path);
					array_copy(_path, array_length(_path), _chain.base_path, 0, array_length(_chain.base_path));
					var _inner = __find(_state, _base, _walk, _cond, _path);
					array_resize(_path, _depth);
					if (_inner != undefined) return _inner;
				}
			}
			if (!_cond) && (_before) return variable_clone(_path, 0);
			_walk.ok = false;
			return undefined;
		}
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier:
				if (__gmlc_opt_may_throw(_node)) && (!__readsBuiltin(_state, _node)) _walk.ok = false;
			return undefined;
			case __GMLC_NodeKind_Literal:
			case __GMLC_NodeKind_Nameof:
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr:
			return undefined;
			case __GMLC_NodeKind_Index:
			return __findChildren(_state, _node, _walk, _cond, _path, true);
			case __GMLC_NodeKind_Logical:
			case __GMLC_NodeKind_Nullish: {
				var _left = __findChild(_state, 0, _node.left, _walk, _cond, _path);
				if (_left != undefined) return _left;
				var _right = __findChild(_state, 1, _node.right, _walk, true, _path);
				_walk.ok = false;
			return _right;}
			case __GMLC_NodeKind_Conditional: {
				var _test = __findChild(_state, 0, _node.test, _walk, _cond, _path);
				if (_test != undefined) return _test;
				var _consequent = __findChild(_state, 1, _node.consequent, _walk, true, _path);
				if (_consequent != undefined) return _consequent;
				var _alternate = __findChild(_state, 2, _node.alternate, _walk, true, _path);
				_walk.ok = false;
			return _alternate;}
			case __GMLC_NodeKind_Assign: {
				var _sealed = _cond || (!__allAllowed(_state, _node.value));
				var _target = undefined;
				if (_node.target.kind != __GMLC_NodeKind_Identifier) {
					_target = __findChild(_state, 0, _node.target, _walk, _sealed, _path);
				}
				if (_target != undefined) return _target;
				var _value = __findChild(_state, 1, _node.value, _walk, _cond, _path);
				_walk.ok = false;
			return _value;}
		}
		return __findChildren(_state, _node, _walk, _cond, _path, true);
	};
	
	#region jsDoc
	/// @func    __findChild(_state, _index, _child, _walk, _cond, _path)
	/// @desc    `__find` on the child of a node that is the _index-th in its children.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct}         _state : The pass state
	/// @param   {Real}           _index : The child's number
	/// @param   {Struct.ASTNode} _child : The child
	/// @param   {Struct}         _walk  : {ok}
	/// @param   {Bool}           _cond  : Whether the child is evaluated only sometimes
	/// @param   {Array<Real>}    _path  : The path to the parent
	/// @returns {Array<Real>|Undefined}
	#endregion
	static __findChild = function(_state, _index, _child, _walk, _cond, _path) {
		array_push(_path, _index);
		var _found = __find(_state, _child, _walk, _cond, _path);
		array_pop(_path);
		return _found;
	};
	
	#region jsDoc
	/// @func    __findChildren(_state, _node, _walk, _cond, _path, _closes)
	/// @desc    The first chain among the children of a node; _closes says the node itself is an operation that is no
	///          plain read.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct}         _state  : The pass state
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct}         _walk   : {ok}
	/// @param   {Bool}           _cond   : Whether the node is evaluated only sometimes
	/// @param   {Array<Real>}    _path   : The path to the node
	/// @param   {Bool}           _closes : Whether the node is an operation
	/// @returns {Array<Real>|Undefined}
	#endregion
	static __findChildren = function(_state, _node, _walk, _cond, _path, _closes) {
		var _children = _node.children();
		var _i = 0; repeat (array_length(_children)) {
			var _found = __findChild(_state, _i, _children[_i], _walk, _cond, _path);
			if (_found != undefined) return _found;
		_i++}
		if (_closes) _walk.ok = false;
		return undefined;
	};
	
	#region jsDoc
	/// @func    __site(_state, _stmt)
	/// @desc    The path, from a statement, to the first chain it may hoist, or undefined.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _stmt  : The statement
	/// @returns {Array<Real>|Undefined}
	#endregion
	static __site = function(_state, _stmt) {
		var _walk = { ok: true };
		var _path = [];
		switch (_stmt.kind) {
			case __GMLC_NodeKind_ExprStmt: return __findChild(_state, 0, _stmt.expression, _walk, false, _path);
			case __GMLC_NodeKind_Return:
				if (_stmt.argument == undefined) return undefined;
			return __findChild(_state, 0, _stmt.argument, _walk, false, _path);
			case __GMLC_NodeKind_Throw: return __findChild(_state, 0, _stmt.argument, _walk, false, _path);
			case __GMLC_NodeKind_If: return __findChild(_state, 0, _stmt.test, _walk, false, _path);
			case __GMLC_NodeKind_Switch: return __findChild(_state, 0, _stmt.discriminant, _walk, false, _path);
			case __GMLC_NodeKind_Repeat: return __findChild(_state, 0, _stmt.count, _walk, false, _path);
			case __GMLC_NodeKind_VarDeclList: {
				var _d = 0; repeat (array_length(_stmt.declarations)) {
					var _decl = _stmt.declarations[_d];
					if (_decl.kind != __GMLC_NodeKind_VarDecl) return undefined;
					if (_decl.init != undefined) {
						array_push(_path, _d);
						var _found = __findChild(_state, 1, _decl.init, _walk, false, _path);
						array_pop(_path);
						if (_found != undefined) return _found;
						_walk.ok = false;
					}
				_d++}
			return undefined;}
		}
		return undefined;
	};
	#endregion
	
	#region Rewriting
	#region jsDoc
	/// @func    __hoist(_state, _chainNode, _chain, _span)
	/// @desc    The statements that read a chain hop by hop into a local, and the read of that local that takes the
	///          chain's place.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct}           _state     : The pass state
	/// @param   {Struct.ASTNode}   _chainNode : The chain
	/// @param   {Struct}           _chain     : The parsed chain
	/// @param   {Struct.GMLC_Span} _span      : The span of the statement
	/// @returns {Struct} {statements, stand_in}
	#endregion
	static __hoist = function(_state, _chainNode, _chain, _span) {
		var _cx = _state.cx;
		var _result = _cx.optimizer.newTemporary(_cx);
		var _statements = [__gmlc_opt_var(_result, __gmlc_opt_undefined_literal(_span), _span)];
		var _first = __gmlc_opt_clone(_chain.base);
		__gmlc_opt_retag_span(_first, _span);
		if (!_chain.plain) {
			var _holder = _cx.optimizer.newTemporary(_cx);
			array_push(_statements, __gmlc_opt_var(_holder, _first, _span));
			_first = __gmlc_opt_local(_holder, _span);
		}
		var _hops = array_length(_chain.keys);
		var _values = [_first];
		var _holders = [];
		repeat (_hops - 1) {
			var _name = _cx.optimizer.newTemporary(_cx);
			array_push(_values, __gmlc_opt_local(_name, _span));
			array_push(_holders, _name);
		}
		var _inner = undefined;
		var _level = _hops;
		while (_level > 0) {
			_level--;
			var _key = __gmlc_opt_clone(_chain.keys[_level]);
			__gmlc_opt_retag_span(_key, _span);
			var _read = __call(_chain.callee, "struct_get", [__gmlc_opt_clone(_values[_level]), _key], _span);
			var _body = [];
			if (_inner == undefined) {
				var _assign = new ASTAssign(_span, "=", __gmlc_opt_local(_result, _span), _read);
				array_push(_body, new ASTExprStmt(_span, _assign));
			}
			else {
				array_push(_body, __gmlc_opt_var(_holders[_level], _read, _span));
				array_push(_body, _inner);
			}
			var _test = new ASTUnary(_span, "!", __call(_chain.callee, "is_undefined", [__gmlc_opt_clone(_values[_level])], _span));
			_inner = new ASTIf(_span, _test, new ASTBlock(_span, _body), undefined);
		}
		if (_inner != undefined) array_push(_statements, _inner);
		return { statements: _statements, stand_in: __gmlc_opt_local(_result, _chainNode.span) };
	};
	#endregion
	
	#region Lists
	#region jsDoc
	/// @func    __list(_state, _stmts)
	/// @desc    A statement list with its chains hoisted, or undefined when nothing changes.
	/// @self    GMLC_Opt_NullishHoist
	/// @param   {Struct}        _state : The pass state
	/// @param   {Array<Struct>} _stmts : The statements
	/// @returns {Array<Struct>|Undefined}
	#endregion
	static __list = function(_state, _stmts) {
		var _out = [];
		var _changed = false;
		var _s = 0; repeat (array_length(_stmts)) {
			var _statement = _stmts[_s];
			if (!_state.cx.optimizer.__isNoOp(_statement)) {
				while (true) {
					var _path = __site(_state, _statement);
					if (_path == undefined) break;
					var _chainNode = __nodeAt(_statement, _path);
					if (_chainNode == undefined) break;
					var _chain = __parseChain(_chainNode);
					if (_chain == undefined) break;
					var _hoisted = __hoist(_state, _chainNode, _chain, __gmlc_opt_span_point(_statement.span));
					array_copy(_out, array_length(_out), _hoisted.statements, 0, array_length(_hoisted.statements));
					_statement = __replaceAt(_statement, _path, 0, _hoisted.stand_in);
					_state.cx.stats[$ "chains_hoisted"]++;
					_changed = true;
				}
			}
			var _nested = __nested(_state, _statement);
			if (_nested != undefined) {
				_statement = _nested;
				_changed = true;
			}
			array_push(_out, _statement);
		_s++}
		return _changed ? _out : undefined;
	};
	
	#region jsDoc
	/// @func    __block(_state, _node)
	/// @desc    A block with its chains hoisted, or undefined when nothing changes.
	/// @self    GMLC_Opt_NullishHoist
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
	/// @desc    A statement with the lists inside it hoisted, or undefined when nothing changes.
	/// @self    GMLC_Opt_NullishHoist
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
			case __GMLC_NodeKind_With: {
				var _target = _stmt.target;
				var _sure = (_target.kind == __GMLC_NodeKind_Identifier) && (_target.symbol != undefined)
					&& ((_target.symbol.kind == "Asset") || ((_target.symbol.kind == "BuiltinConstant") && ((_target.name == "all") || (_target.name == "noone"))));
				var _before = _state.unsure_self;
				_state.unsure_self = _before || (!_sure);
				var _withBody = __block(_state, _stmt.body);
				_state.unsure_self = _before;
				if (_withBody == undefined) return undefined;
				var _with = variable_clone(_stmt, 0);
				_with.body = _withBody;
			return _with;}
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
