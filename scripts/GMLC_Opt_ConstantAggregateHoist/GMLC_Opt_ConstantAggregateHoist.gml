#region jsDoc
/// @func    GMLC_Opt_ConstantAggregateHoist()
/// @desc    An array or struct literal of constants that a function only reads becomes a `static`, so it is built once
///          and not on every call: `var _dirs = [[1, 0], [0, 1]];` becomes `static __gmlc_t0 = [[1, 0], [0, 1]];`
///          and each read of `_dirs` reads the static. Only a `var` at the top level of a function declaration is
///          hoisted, and only when every mention reads an element, or passes the array to a built-in that keeps no
///          reference.
/// @returns {Struct.GMLC_Opt_ConstantAggregateHoist}
#endregion
function GMLC_Opt_ConstantAggregateHoist() : GMLC_OptimizerPass("constant-aggregate-hoist") constructor {
	#region Config
	// built-ins that only read their array argument and return no reference into it
	static readers = ["array_length", "array_contains", "array_get_index"];
	#endregion

	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Moves the read-only constant literals a function declares at its top level into statics.
	/// @self    GMLC_Opt_ConstantAggregateHoist
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (_node.kind != __GMLC_NodeKind_FunctionDecl) return undefined;
		var _statements = _node.body.body;
		var _found = [];
		var _s = 0; repeat (array_length(_statements)) {
			var _statement = _statements[_s];
			if (_statement.kind == __GMLC_NodeKind_VarDeclList) {
				var _declarations = _statement.declarations;
				var _d = 0; repeat (array_length(_declarations)) {
					var _plan = __plan(_node, _statement, _declarations[_d], _cx);
					if (_plan != undefined) array_push(_found, _plan);
				_d++}
			}
		_s++}
		if (array_length(_found) == 0) return undefined;
		var _map = {};
		var _f = 0; repeat (array_length(_found)) {
			_found[_f].temporary = _cx.optimizer.newTemporary(_cx);
			_map[$ _found[_f].name] = _found[_f].temporary;
			_cx.stats[$ "hoisted"]++;
		_f++}
		var _new = __gmlc_opt_clone(_node);
		var _old = _new.body.body;
		var _body = [];
		var _o = 0; repeat (array_length(_old)) {
			var _current = _old[_o];
			var _statics = [];
			var _rest = [];
			if (_current.kind == __GMLC_NodeKind_VarDeclList) {
				var _k = 0; repeat (array_length(_current.declarations)) {
					var _declaration = _current.declarations[_k];
					var _temporary = _map[$ _declaration.target.name];
					if (_temporary != undefined) {
						var _target = new ASTIdentifier(_declaration.target.span, _temporary);
						_target.symbol = new GMLC_Symbol("Static", _temporary, undefined);
						array_push(_statics, new ASTVarDecl(_declaration.span, _target, _declaration.init));
						// the local stays and holds the static: reading a static is slower than reading a local
						var _read = new ASTIdentifier(_declaration.span, _temporary);
						_read.symbol = new GMLC_Symbol("Static", _temporary, undefined);
						array_push(_rest, new ASTVarDecl(_declaration.span, _declaration.target, _read));
					}
					else {
						array_push(_rest, _declaration);
					}
				_k++}
			}
			if (array_length(_statics) == 0) {
				array_push(_body, _current);
			}
			else {
				array_push(_body, new ASTStaticDecl(_current.span, _statics));
				if (array_length(_rest) > 0) array_push(_body, new ASTVarDeclList(_current.span, _rest));
			}
		_o++}
		_new.body.body = _body;
		return _new;
	};
	#endregion

	#region Private
	#region jsDoc
	/// @func    __plan(_fn, _statement, _declaration, _cx)
	/// @desc    The shape and name of a declarator that can be hoisted, or undefined: a literal of constants, declared
	///          once, and mentioned only by reads of the shape the literal has.
	/// @self    GMLC_Opt_ConstantAggregateHoist
	/// @param   {Struct.ASTFunctionDecl} _fn          : The function
	/// @param   {Struct.ASTNode}         _statement   : The `var` statement holding the declarator
	/// @param   {Struct.ASTVarDecl}      _declaration : The declarator
	/// @param   {Struct}                 _cx          : The pass context
	/// @returns {Struct|Undefined} {name, shape, temporary}
	#endregion
	static __plan = function(_fn, _statement, _declaration, _cx) {
		var _target = _declaration.target;
		var _init = _declaration.init;
		if (_init == undefined) || (_target.kind != __GMLC_NodeKind_Identifier) return undefined;
		if (_init.kind != __GMLC_NodeKind_ArrayLiteral) && (_init.kind != __GMLC_NodeKind_StructLiteral) return undefined;
		var _name = _target.name;
		var _shape = __shape(_init);
		if (_shape == undefined) return undefined;
		if (_cx.optimizer.__isNoOp(_statement)) return undefined;
		// a parameter of the same name has the same slot
		var _p = 0; repeat (array_length(_fn.params)) {
			if (_fn.params[_p].target.name == _name) return undefined;
		_p++}
		if (__gmlc_opt_var_declarations(_fn.body, _name) != 1) return undefined;
		if (!__uses(_fn.body, _name, _shape, _declaration, _cx)) return undefined;
		return { name: _name, shape: _shape, temporary: undefined };
	};

	#region jsDoc
	/// @func    __shape(_init)
	/// @desc    What a literal of constants is, or undefined when it is not one a read-only proof covers: a struct of
	///          constants (kind "struct", its keys), or an array whose elements are all constants or all arrays of the
	///          same depth (kind "array", the depth at which the constants lie). Fewer than two constants are not
	///          worth a static.
	/// @self    GMLC_Opt_ConstantAggregateHoist
	/// @param   {Struct.ASTNode} _init : The literal
	/// @returns {Struct|Undefined} {kind, depth, keys}
	#endregion
	static __shape = function(_init) {
		if (_init.kind == __GMLC_NodeKind_StructLiteral) {
			var _entries = _init.entries;
			if (array_length(_entries) < 2) return undefined;
			var _keys = [];
			var _e = 0; repeat (array_length(_entries)) {
				if (!__is_constant(_entries[_e].value)) return undefined;
				array_push(_keys, _entries[_e].key);
			_e++}
			return { kind: "struct", depth: 1, keys: _keys };
		}
		var _depth = __array_depth(_init);
		if (_depth < 0) || (__leaves(_init) < 2) return undefined;
		return { kind: "array", depth: _depth, keys: undefined };
	};

	#region jsDoc
	/// @func    __is_constant(_node)
	/// @desc    Whether a node is a literal, or a sign in front of a number literal.
	/// @self    GMLC_Opt_ConstantAggregateHoist
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __is_constant = function(_node) {
		if (_node.kind == __GMLC_NodeKind_Literal) return true;
		if (_node.kind != __GMLC_NodeKind_Unary) || ((_node.op != "-") && (_node.op != "+")) return false;
		var _argument = _node.argument;
		return (_argument.kind == __GMLC_NodeKind_Literal) && ((_argument.ty == "real") || (_argument.ty == "int64"));
	};

	#region jsDoc
	/// @func    __array_depth(_literal)
	/// @desc    How many index steps reach the constants of an array literal, or -1 when its elements are not all
	///          constants, or all arrays of one depth, or when one is empty.
	/// @self    GMLC_Opt_ConstantAggregateHoist
	/// @param   {Struct.ASTArrayLiteral} _literal : The literal
	/// @returns {Real}
	#endregion
	static __array_depth = function(_literal) {
		var _elements = _literal.elements;
		if (array_length(_elements) == 0) return -1;
		var _depth = -1;
		var _i = 0; repeat (array_length(_elements)) {
			var _element = _elements[_i];
			var _d;
			if (_element.kind == __GMLC_NodeKind_ArrayLiteral) {
				_d = __array_depth(_element);
				if (_d < 0) return -1;
				_d++;
			}
			else if (__is_constant(_element)) {
				_d = 1;
			}
			else {
				return -1;
			}
			if (_depth >= 0) && (_d != _depth) return -1;
			_depth = _d;
		_i++}
		return _depth;
	};

	#region jsDoc
	/// @func    __leaves(_literal)
	/// @desc    How many constants an array literal holds, nested arrays included.
	/// @self    GMLC_Opt_ConstantAggregateHoist
	/// @param   {Struct.ASTArrayLiteral} _literal : The literal
	/// @returns {Real}
	#endregion
	static __leaves = function(_literal) {
		var _n = 0;
		var _elements = _literal.elements;
		var _i = 0; repeat (array_length(_elements)) {
			_n += (_elements[_i].kind == __GMLC_NodeKind_ArrayLiteral) ? __leaves(_elements[_i]) : 1;
		_i++}
		return _n;
	};

	#region jsDoc
	/// @func    __depth(_node, _name, _shape)
	/// @desc    How many reads of the literal's shape lead from the local down to a node: 0 for the local itself, one
	///          per `[i]` of an array and one `.key` of a struct; -1 when the node is not such a chain on the local.
	/// @self    GMLC_Opt_ConstantAggregateHoist
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {String}         _name  : The local
	/// @param   {Struct}         _shape : The literal's shape
	/// @returns {Real}
	#endregion
	static __depth = function(_node, _name, _shape) {
		var _depth = 0;
		while (_node.kind == __GMLC_NodeKind_Index) {
			if (_shape.kind == "array") {
				if (_node.accessor != "Array") || (array_length(_node.keys) != 1) return -1;
			}
			else if (!__struct_key(_node, _shape)) {
				return -1;
			}
			_depth++;
			_node = _node.object;
		}
		return (__gmlc_opt_is_local(_node) && (_node.name == _name)) ? _depth : -1;
	};

	#region jsDoc
	/// @func    __struct_key(_node, _shape)
	/// @desc    Whether an Index node reads a key the struct literal has, by `.key` or `[$ "key"]`.
	/// @self    GMLC_Opt_ConstantAggregateHoist
	/// @param   {Struct.ASTIndex} _node  : The node
	/// @param   {Struct}          _shape : The literal's shape
	/// @returns {Bool}
	#endregion
	static __struct_key = function(_node, _shape) {
		if (_node.accessor == "Dot") return array_contains(_shape.keys, _node.member);
		if (_node.accessor != "Struct") || (array_length(_node.keys) != 1) return false;
		var _key = _node.keys[0];
		return (_key.kind == __GMLC_NodeKind_Literal) && (_key.ty == "string") && array_contains(_shape.keys, _key.value);
	};

	#region jsDoc
	/// @func    __keys(_node, _name, _shape, _skip, _cx)
	/// @desc    Whether the key expressions of an index chain are fine, and its base is not frozen.
	/// @self    GMLC_Opt_ConstantAggregateHoist
	/// @param   {Struct.ASTNode}    _node  : The chain
	/// @param   {String}            _name  : The local
	/// @param   {Struct}            _shape : The literal's shape
	/// @param   {Struct.ASTVarDecl} _skip  : The declarator being hoisted
	/// @param   {Struct}            _cx    : The pass context
	/// @returns {Bool}
	#endregion
	static __keys = function(_node, _name, _shape, _skip, _cx) {
		while (_node.kind == __GMLC_NodeKind_Index) {
			var _keys = _node.keys;
			var _k = 0; repeat (array_length(_keys)) {
				if (!__uses(_keys[_k], _name, _shape, _skip, _cx)) return false;
			_k++}
			_node = _node.object;
		}
		return !_cx.optimizer.__isNoOp(_node);
	};

	#region jsDoc
	/// @func    __uses(_node, _name, _shape, _skip, _cx)
	/// @desc    Whether every mention of the local under a node only reads the literal: an element or key read that
	///          reaches a constant, or the array (or an inner array) as the first argument of a reader built-in.
	///          A write, an assignment of the array elsewhere, a mention inside `with` or in frozen code refuses.
	/// @self    GMLC_Opt_ConstantAggregateHoist
	/// @param   {Struct.ASTNode}    _node  : The node
	/// @param   {String}            _name  : The local
	/// @param   {Struct}            _shape : The literal's shape
	/// @param   {Struct.ASTVarDecl} _skip  : The declarator being hoisted
	/// @param   {Struct}            _cx    : The pass context
	/// @returns {Bool}
	#endregion
	static __uses = function(_node, _name, _shape, _skip, _cx) {
		if (_node == _skip) || (__gmlc_opt_is_function(_node)) return true;
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier:
				return !(__gmlc_opt_is_local(_node) && (_node.name == _name));
			case __GMLC_NodeKind_With:
				return (__gmlc_opt_count_mentions(_node, _name) == 0);
			case __GMLC_NodeKind_Index: {
				var _reach = __depth(_node, _name, _shape);
				if (_reach >= 0) return (_reach == _shape.depth) && __keys(_node, _name, _shape, _skip, _cx);
			break;}
			case __GMLC_NodeKind_Assign:
				if (__depth(_node.target, _name, _shape) >= 0) return false;
			break;
			case __GMLC_NodeKind_Update:
				if (__depth(_node.argument, _name, _shape) >= 0) return false;
			break;
			case __GMLC_NodeKind_Delete:
				if (__depth(_node.target, _name, _shape) >= 0) return false;
			break;
			case __GMLC_NodeKind_Call: {
				var _builtin = __gmlc_opt_builtin_call(_node);
				if (_shape.kind == "array") && (_builtin != undefined) && array_contains(readers, _builtin) && (array_length(_node.args) > 0) {
					var _depth = __depth(_node.args[0], _name, _shape);
					if (_depth >= 0) && (_depth < _shape.depth) {
						if (!__keys(_node.args[0], _name, _shape, _skip, _cx)) return false;
						var _a = 1; repeat (array_length(_node.args) - 1) {
							if (!__uses(_node.args[_a], _name, _shape, _skip, _cx)) return false;
						_a++}
						return true;
					}
				}
			break;}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__uses(_child, _name, _shape, _skip, _cx)) return false;
				}
			_i++}
		_field_index++}
		return true;
	};

#endregion
}
