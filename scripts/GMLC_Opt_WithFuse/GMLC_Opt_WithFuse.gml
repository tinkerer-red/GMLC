#region jsDoc
/// @func    GMLC_Opt_WithFuse()
/// @desc    Two `with` statements in a row on the same target become one, so the instances are walked once:
///          `with (obj_enemy) { alert = true; } with (obj_enemy) { timer = 0; }` becomes `with (obj_enemy) { alert =
///          true; timer = 0; }`. Both bodies may only set instance variables and locals from values that cannot fail
///          and have no effect (literals, locals, pure built-ins), so running them one instance at a time cannot differ
///          from running one body on all instances and then the other, and neither can throw halfway.
/// @returns {Struct.GMLC_Opt_WithFuse}
#endregion
function GMLC_Opt_WithFuse() : GMLC_OptimizerPass("with-fuse") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Joins the pairs of `with` statements of a function that can be one.
	/// @self    GMLC_Opt_WithFuse
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (!__has_pair(_node, _cx)) return undefined;
		var _new = __gmlc_opt_clone(_node);
		__rewrite(_new, _cx);
		return _new;
	};
	#endregion

	#region Private
	#region jsDoc
	/// @func    __has_pair(_node, _cx)
	/// @desc    Whether a statement list under a node has two `with` statements in a row that can be one, nested
	///          functions left out.
	/// @self    GMLC_Opt_WithFuse
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Bool}
	#endregion
	static __has_pair = function(_node, _cx) {
		if (__gmlc_opt_is_statement_list(_node)) {
			var _body = _node.body;
			var _s = 1; repeat (array_length(_body) - 1) {
				if (_body[_s - 1].kind == __GMLC_NodeKind_With) && (_body[_s].kind == __GMLC_NodeKind_With) && __fusable(_body[_s - 1], _body[_s], _cx) return true;
			_s++}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__gmlc_opt_is_function(_child)) && (__has_pair(_child, _cx)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};

	#region jsDoc
	/// @func    __rewrite(_node, _cx)
	/// @desc    Joins the pairs of `with` statements of a copy, in place, left to right, nested functions left out.
	/// @self    GMLC_Opt_WithFuse
	/// @param   {Struct.ASTNode} _node : The node, a copy this pass owns
	/// @param   {Struct}         _cx   : The pass context
	#endregion
	static __rewrite = function(_node, _cx) {
		if (__gmlc_opt_is_statement_list(_node)) {
			var _old = _node.body;
			var _body = [];
			var _s = 0; repeat (array_length(_old)) {
				var _count = array_length(_body);
				if (_old[_s].kind == __GMLC_NodeKind_With) && (_count > 0) && (_body[_count - 1].kind == __GMLC_NodeKind_With) && __fusable(_body[_count - 1], _old[_s], _cx) {
					_cx.stats[$ "fused"]++;
					_body[_count - 1] = __merge(_body[_count - 1], _old[_s]);
				}
				else {
					array_push(_body, _old[_s]);
				}
			_s++}
			_node.body = _body;
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
	/// @func    __statements(_body)
	/// @desc    The statements of a `with` body: its list when it is a block, else the one statement.
	/// @self    GMLC_Opt_WithFuse
	/// @param   {Struct.ASTNode} _body : The body
	/// @returns {Array<Struct.ASTNode>}
	#endregion
	static __statements = function(_body) {
		return (_body.kind == __GMLC_NodeKind_Block) ? _body.body : [_body];
	};

	#region jsDoc
	/// @func    __merge(_first, _second)
	/// @desc    One `with` that runs the first body and then the second on each instance.
	/// @self    GMLC_Opt_WithFuse
	/// @param   {Struct.ASTWith} _first  : The first statement
	/// @param   {Struct.ASTWith} _second : The second statement
	/// @returns {Struct.ASTWith}
	#endregion
	static __merge = function(_first, _second) {
		var _body = new ASTBlock(_first.body.span, array_concat(__statements(_first.body), __statements(_second.body)));
		return new ASTWith(_first.span, _first.target, _body);
	};

	#region jsDoc
	/// @func    __fusable(_first, _second, _cx)
	/// @desc    Whether two `with` statements in a row can be one: the same target that nothing in either body changes,
	///          and two bodies `__body_ok` accepts that share no local either of them writes.
	/// @self    GMLC_Opt_WithFuse
	/// @param   {Struct.ASTWith} _first  : The first statement
	/// @param   {Struct.ASTWith} _second : The second statement
	/// @param   {Struct}         _cx     : The pass context
	/// @returns {Bool}
	#endregion
	static __fusable = function(_first, _second, _cx) {
		if (_cx.optimizer.__isNoOp(_first)) || (_cx.optimizer.__isNoOp(_second)) return false;
		if (!__gmlc_opt_same(_first.target, _second.target)) return false;
		if (!__body_ok(_first.body, _cx)) || (!__body_ok(_second.body, _cx)) return false;
		var _written = [];
		__written(_first.body, _written);
		__written(_second.body, _written);
		if (!__stable(_first.target, _written, _first.body, _second.body)) return false;
		var _in_first = [];
		var _in_second = [];
		__locals(_first.body, _in_first);
		__locals(_second.body, _in_second);
		var _w = 0; repeat (array_length(_written)) {
			if (array_contains(_in_first, _written[_w])) && (array_contains(_in_second, _written[_w])) return false;
		_w++}
		return true;
	};

	#region jsDoc
	/// @func    __stable(_target, _written, _first, _second)
	/// @desc    Whether a `with` target reads the same in both statements: an asset, built-in constant or enum name,
	///          a local neither body writes, or an instance variable neither body sets.
	/// @self    GMLC_Opt_WithFuse
	/// @param   {Struct.ASTNode} _target  : The target
	/// @param   {Array<String>}  _written : The locals either body writes
	/// @param   {Struct.ASTNode} _first   : The first body
	/// @param   {Struct.ASTNode} _second  : The second body
	/// @returns {Bool}
	#endregion
	static __stable = function(_target, _written, _first, _second) {
		if (_target.kind != __GMLC_NodeKind_Identifier) || (_target.symbol == undefined) return false;
		switch (_target.symbol.kind) {
			case "Asset": case "BuiltinConstant": case "Enum":
			return true;
			case "Local":
			return !array_contains(_written, _target.name);
			case "Self":
			return (!__sets(_first, _target.name)) && (!__sets(_second, _target.name));
		}
		return false;
	};

	#region jsDoc
	/// @func    __sets(_node, _name)
	/// @desc    Whether a name is assigned or incremented under a node.
	/// @self    GMLC_Opt_WithFuse
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The name
	/// @returns {Bool}
	#endregion
	static __sets = function(_node, _name) {
		var _target = undefined;
		if (_node.kind == __GMLC_NodeKind_Assign) _target = _node.target;
		else if (_node.kind == __GMLC_NodeKind_Update) _target = _node.argument;
		if (_target != undefined) && (_target.kind == __GMLC_NodeKind_Identifier) && (_target.name == _name) return true;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__sets(_child, _name)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};

	#region jsDoc
	/// @func    __body_ok(_node, _cx)
	/// @desc    Whether a `with` body is only blocks, `if`s on a value that cannot fail, and statements that set an
	///          instance variable or local from such a value or declare a local with one; none frozen.
	/// @self    GMLC_Opt_WithFuse
	/// @param   {Struct.ASTNode} _node : The body
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Bool}
	#endregion
	static __body_ok = function(_node, _cx) {
		if (_cx.optimizer.__isNoOp(_node)) return false;
		switch (_node.kind) {
			case __GMLC_NodeKind_Empty:
			return true;
			case __GMLC_NodeKind_Block: {
				var _i = 0; repeat (array_length(_node.body)) {
					if (!__body_ok(_node.body[_i], _cx)) return false;
				_i++}
				return true;
			}
			case __GMLC_NodeKind_ExprStmt: {
				var _expression = _node.expression;
				if (_expression.kind != __GMLC_NodeKind_Assign) || (_expression.op != "=") || (_expression.target.kind != __GMLC_NodeKind_Identifier) || (_expression.target.symbol == undefined) return false;
				var _kind = _expression.target.symbol.kind;
				return ((_kind == "Self") || (_kind == "Local")) && __quiet(_expression.value);
			}
			case __GMLC_NodeKind_VarDeclList: {
				var _d = 0; repeat (array_length(_node.declarations)) {
					var _declaration = _node.declarations[_d];
					if (_declaration.init == undefined) || (!__quiet(_declaration.init)) return false;
				_d++}
				return true;
			}
			case __GMLC_NodeKind_If:
				return __quiet(_node.test) && __body_ok(_node.consequent, _cx) && ((_node.alternate == undefined) || __body_ok(_node.alternate, _cx));
		}
		return false;
	};

	#region jsDoc
	/// @func    __quiet(_node)
	/// @desc    Whether an expression has no effect and cannot throw.
	/// @self    GMLC_Opt_WithFuse
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __quiet = function(_node) {
		return (!__gmlc_opt_may_throw(_node)) && (!__gmlc_opt_has_effects(_node));
	};

	#region jsDoc
	/// @func    __written(_node, _written)
	/// @desc    Adds the locals written under a node (assigned, incremented, or declared with a value) to a list.
	/// @self    GMLC_Opt_WithFuse
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {Array<String>}  _written : The locals so far, added to
	#endregion
	static __written = function(_node, _written) {
		var _name = undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Assign: if (__gmlc_opt_is_local(_node.target)) _name = _node.target.name; break;
			case __GMLC_NodeKind_Update: if (__gmlc_opt_is_local(_node.argument)) _name = _node.argument.name; break;
			case __GMLC_NodeKind_VarDecl: if (_node.init != undefined) _name = _node.target.name; break;
		}
		if (_name != undefined) && (!array_contains(_written, _name)) array_push(_written, _name);
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__written(_child, _written);
				}
			_i++}
		_field_index++}
	};

	#region jsDoc
	/// @func    __locals(_node, _names)
	/// @desc    Adds the locals named under a node to a list.
	/// @self    GMLC_Opt_WithFuse
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Array<String>}  _names : The names so far, added to
	#endregion
	static __locals = function(_node, _names) {
		if (_node.kind == __GMLC_NodeKind_Identifier) {
			if (__gmlc_opt_is_local(_node)) && (!array_contains(_names, _node.name)) array_push(_names, _node.name);
			return;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__locals(_child, _names);
				}
			_i++}
		_field_index++}
	};
	#endregion
}
