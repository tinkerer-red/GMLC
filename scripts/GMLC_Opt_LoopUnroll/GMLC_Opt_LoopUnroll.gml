#region jsDoc
/// @func    GMLC_Opt_LoopUnroll()
/// @desc    Fully unrolls a `for` loop with a literal start, bound and step that runs at most four times, when writing
///          the counter as a literal in every copy gives a part of the body that folds. A loop whose copies would
///          not fold, or whose body has a `break`, a `continue`, a `static`, a nested declaration or a function, stays.
///          `for (var i = 0; i < 2; i++) { draw(i == 0 ? a : b); }` becomes `draw(0 == 0 ? a : b); draw(1 == 0 ? a : b);`.
/// @returns {Struct.GMLC_Opt_LoopUnroll}
#endregion
function GMLC_Opt_LoopUnroll() : GMLC_OptimizerPass("loop-unroll") constructor {
	#region Config
	static __limit = 4;
	#endregion

	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The node to put in the place of _node, or undefined to keep it.
	/// @self    GMLC_Opt_LoopUnroll
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		return __rewrite(_node, _node, _cx, true);
	};
	#endregion

	#region Private
	#region Walk
	#region jsDoc
	/// @func    __rewrite(_node, _fn, _cx, _is_root)
	/// @desc    Rewrites the statement lists under a node, outer ones first, nested functions left out.
	/// @self    GMLC_Opt_LoopUnroll
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {Struct.ASTNode} _fn      : The function the pass runs on
	/// @param   {Struct}         _cx      : The pass context
	/// @param   {Bool}           _is_root : Whether the node is the function itself
	/// @returns {Struct.ASTNode|Undefined} A changed copy, or undefined
	#endregion
	static __rewrite = function(_node, _fn, _cx, _is_root) {
		if (!_is_root) && (__gmlc_opt_is_function(_node)) return undefined;
		var _copy = undefined;
		var _kind = _node.kind;
		if (_kind == __GMLC_NodeKind_Script) || (_kind == __GMLC_NodeKind_Block) || (_kind == __GMLC_NodeKind_Case) || (_kind == __GMLC_NodeKind_Default) {
			var _new_body = __list(_node.body, _fn, _cx);
			if (_new_body != undefined) {
				_copy = variable_clone(_node, 0);
				_copy.body = _new_body;
			}
		}
		var _source = _copy ?? _node;
		var _fields = _source.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _key = _fields[_f];
			var _value = _source[$ _key];
			if (is_array(_value)) {
				var _count = array_length(_value);
				var _items = undefined;
				var _j = 0; repeat (_count) {
					if (_value[_j] != undefined) {
						var _item = __rewrite(_value[_j], _fn, _cx, false);
						if (_item != undefined) {
							if (_items == undefined) {
								_items = array_create(_count);
								array_copy(_items, 0, _value, 0, _count);
							}
							_items[_j] = _item;
						}
					}
				_j++}
				if (_items != undefined) {
					_copy ??= variable_clone(_node, 0);
					_copy[$ _key] = _items;
				}
			}
			else if (_value != undefined) {
				var _child = __rewrite(_value, _fn, _cx, false);
				if (_child != undefined) {
					_copy ??= variable_clone(_node, 0);
					_copy[$ _key] = _child;
				}
			}
		_f++}
		return _copy;
	};

	#region jsDoc
	/// @func    __list(_body, _fn, _cx)
	/// @desc    Unrolls the loops of a statement list.
	/// @self    GMLC_Opt_LoopUnroll
	/// @param   {Array<Struct.ASTNode>} _body : The statements
	/// @param   {Struct.ASTNode}        _fn   : The function the pass runs on
	/// @param   {Struct}                _cx   : The pass context
	/// @returns {Array<Struct.ASTNode>|Undefined} The new statements, or undefined
	#endregion
	static __list = function(_body, _fn, _cx) {
		var _out = undefined;
		var _count = array_length(_body);
		var _i = 0; repeat (_count) {
			var _statement = _body[_i];
			var _copies = (_statement.kind == __GMLC_NodeKind_For) ? __unroll(_statement, _fn, _cx) : undefined;
			if (_copies != undefined) {
				if (_out == undefined) {
					_out = array_create(_i);
					array_copy(_out, 0, _body, 0, _i);
				}
				array_copy(_out, array_length(_out), _copies, 0, array_length(_copies));
			}
			else if (_out != undefined) {
				array_push(_out, _statement);
			}
		_i++}
		return _out;
	};
	#endregion

	#region Loops
	#region jsDoc
	/// @func    __unroll(_for, _fn, _cx)
	/// @desc    The statements that replace a `for` loop of at most four literal trips, or undefined.
	/// @self    GMLC_Opt_LoopUnroll
	/// @param   {Struct.ASTFor}  _for : The loop
	/// @param   {Struct.ASTNode} _fn  : The function the pass runs on
	/// @param   {Struct}         _cx  : The pass context
	/// @returns {Array<Struct.ASTNode>|Undefined}
	#endregion
	static __unroll = function(_for, _fn, _cx) {
		if (_cx.optimizer.__containsNoOp(_for)) return undefined;
		var _loop = __gmlc_opt_counted_header(_for);
		if (_loop == undefined) return undefined;
		var _from = __gmlc_opt_real_literal(_loop.start);
		var _to = __gmlc_opt_real_literal(_loop.bound);
		if (_from == undefined) || (_to == undefined) return undefined;
		var _values = [];
		var _value = _from;
		while (__holds(_loop.cmp, _value, _to)) {
			if (array_length(_values) >= __limit) return undefined;
			array_push(_values, _value);
			_value += _loop.step;
		}
		var _trips = array_length(_values);
		if (_trips == 0) return undefined;
		var _name = _loop.name;
		var _block = _for.body;
		var _statements = (_block.kind == __GMLC_NodeKind_Block) ? _block.body : [_block];
		if (__body_blocked(_statements, _name)) return undefined;
		var _literals = array_create(_trips);
		var _t = 0; repeat (_trips) {
			_literals[_t] = _cx.optimizer.__literal(_values[_t], _for.span);
			if (_literals[_t] == undefined) return undefined;
		_t++}
		var _last = undefined;
		if (__gmlc_opt_reads(_fn, _name) - __gmlc_opt_reads(_for, _name) > 0) {
			_last = _cx.optimizer.__literal(_value, _for.span);
			if (_last == undefined) return undefined;
		}
		if (!__profitable(_statements, _name)) {
			_cx.stats[$ "skipped_unprofitable"]++;
			return undefined;
		}
		var _out = [];
		var _m = 0; repeat (_trips) {
			var _s = 0; repeat (array_length(_statements)) {
				var _copy = __substitute(__gmlc_opt_clone(_statements[_s]), _name, _literals[_m]);
				if (_m > 0) && (_copy.kind == __GMLC_NodeKind_VarDeclList) {
					var _d = 0; repeat (array_length(_copy.declarations)) {
						var _decl = _copy.declarations[_d];
						if (_decl.init != undefined) {
							array_push(_out, new ASTExprStmt(_decl.span, new ASTAssign(_decl.span, "=", _decl.target, _decl.init)));
						}
					_d++}
				}
				else {
					array_push(_out, _copy);
				}
			_s++}
		_m++}
		if (_last != undefined) {
			if (_loop.declared) {
				array_push(_out, __gmlc_opt_var(_name, _last, _for.span));
			}
			else {
				array_push(_out, new ASTExprStmt(_for.span, new ASTAssign(_for.span, "=", __gmlc_opt_clone(_for.test.left), _last)));
			}
		}
		_cx.stats[$ "unrolled"]++;
		return _out;
	};

	#region jsDoc
	/// @func    __holds(_cmp, _a, _b)
	/// @desc    Whether a comparison holds.
	/// @self    GMLC_Opt_LoopUnroll
	/// @param   {String} _cmp : The operator
	/// @param   {Real}   _a   : The left value
	/// @param   {Real}   _b   : The right value
	/// @returns {Bool}
	#endregion
	static __holds = function(_cmp, _a, _b) {
		switch (_cmp) {
			case "<":  return _a < _b;
			case "<=": return _a <= _b;
			case ">":  return _a > _b;
			case ">=": return _a >= _b;
		}
		return _a != _b;
	};

	#endregion

	#region Tree
	#region jsDoc
	/// @func    __blocked(_node)
	/// @desc    Whether a node holds anything that cannot be written twice: a `break`, a `continue`, an `exit`, a
	///          declaration or a function.
	/// @self    GMLC_Opt_LoopUnroll
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __blocked = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Break:
			case __GMLC_NodeKind_Continue:
			case __GMLC_NodeKind_Exit:
			case __GMLC_NodeKind_VarDeclList:
			case __GMLC_NodeKind_StaticDecl:
			case __GMLC_NodeKind_GlobalVarDecl:
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr:
			return true;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__blocked(_child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};

	#region jsDoc
	/// @func    __body_blocked(_statements, _name)
	/// @desc    Whether a loop body cannot be copied: it writes the counter, or holds a blocked node. A `var` directly
	///          in the body is fine, it is written as an assignment after the first copy.
	/// @self    GMLC_Opt_LoopUnroll
	/// @param   {Array<Struct.ASTNode>} _statements : The body
	/// @param   {String}                _name       : The counter
	/// @returns {Bool}
	#endregion
	static __body_blocked = function(_statements, _name) {
		var _i = 0; repeat (array_length(_statements)) {
			var _statement = _statements[_i];
			if (_statement.kind == __GMLC_NodeKind_VarDeclList) {
				var _j = 0; repeat (array_length(_statement.declarations)) {
					var _decl = _statement.declarations[_j];
					if (_decl.target.name == _name) return true;
					if (_decl.init != undefined) && ((__blocked(_decl.init)) || (__gmlc_opt_writes(_decl.init, _name))) return true;
				_j++}
			}
			else if (__blocked(_statement)) || (__gmlc_opt_writes(_statement, _name)) {
				return true;
			}
		_i++}
		return false;
	};

	#region jsDoc
	/// @func    __profitable(_statements, _name)
	/// @desc    Whether some operator expression of a body is made of literals and the counter alone, so that it folds
	///          once the counter is a literal.
	/// @self    GMLC_Opt_LoopUnroll
	/// @param   {Array<Struct.ASTNode>} _statements : The body
	/// @param   {String}                _name       : The counter
	/// @returns {Bool}
	#endregion
	static __profitable = function(_statements, _name) {
		var _i = 0; repeat (array_length(_statements)) {
			if (__shaped(_statements[_i], _name)) return true;
		_i++}
		return false;
	};

	#region jsDoc
	/// @func    __shaped(_node, _name)
	/// @desc    Whether a node or something under it is an operator expression of literals and the counter that reads
	///          the counter.
	/// @self    GMLC_Opt_LoopUnroll
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The counter
	/// @returns {Bool}
	#endregion
	static __shaped = function(_node, _name) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Binary:
			case __GMLC_NodeKind_Logical:
			case __GMLC_NodeKind_Nullish:
			case __GMLC_NodeKind_Unary:
			case __GMLC_NodeKind_Conditional:
				if (__constant(_node, _name) == 2) return true;
			break;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__shaped(_child, _name)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};

	#region jsDoc
	/// @func    __constant(_node, _name)
	/// @desc    Whether an expression is known once the counter is: 0 when it is not, 1 when it is made of literals,
	///          2 when it also reads the counter.
	/// @self    GMLC_Opt_LoopUnroll
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {String}         _name : The counter
	/// @returns {Real}
	#endregion
	static __constant = function(_node, _name) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal:
			return 1;
			case __GMLC_NodeKind_Identifier:
			return (__gmlc_opt_is_local(_node) && (_node.name == _name)) ? 2 : 0;
			case __GMLC_NodeKind_Unary:
			return __constant(_node[$ "argument"], _name);
			case __GMLC_NodeKind_Binary:
			case __GMLC_NodeKind_Logical:
			case __GMLC_NodeKind_Nullish: {
				var _left = __constant(_node.left, _name);
				if (_left == 0) return 0;
				var _right = __constant(_node.right, _name);
				if (_right == 0) return 0;
				return max(_left, _right);
			}
			case __GMLC_NodeKind_Conditional: {
				if (_node.alternate == undefined) return 0;
				var _test =__constant(_node.test, _name);
				if (_test == 0) return 0;
				var _yes = __constant(_node.consequent, _name);
				if (_yes == 0) return 0;
				var _no = __constant(_node.alternate, _name);
				if (_no == 0) return 0;
				return max(_test, _yes, _no);
			}
		}
		return 0;
	};

	#region jsDoc
	/// @func    __substitute(_node, _name, _literal)
	/// @desc    Writes a literal for every read of a local under a node, in place (the node is a copy).
	/// @self    GMLC_Opt_LoopUnroll
	/// @param   {Struct.ASTNode}    _node    : The node
	/// @param   {String}            _name    : The local
	/// @param   {Struct.ASTLiteral} _literal : The literal
	/// @returns {Struct.ASTNode} The node to hold in its place
	#endregion
	static __substitute = function(_node, _name, _literal) {
		if (__gmlc_opt_is_local(_node)) {
			return (_node.name == _name) ? __gmlc_opt_clone(_literal) : _node;
		}
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new = __substitute(_slot.node, _name, _literal);
			if (_new != _slot.node) {
				if (_slot.index == undefined) {
					_slot.parent[$ _slot.key] = _new;
				}
				else {
					_slot.parent[$ _slot.key][_slot.index] = _new;
				}
			}
		_i++}
		return _node;
	};
	#endregion
	#endregion
}
