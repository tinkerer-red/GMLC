#region jsDoc
/// @func    GMLC_Opt_CommonSubexpression()
/// @desc    The `common-subexpression` optimizer pass. An expression that is computed again with the same value
///          is read from a local that already holds it, or from a new temporary declared before the statement
///          that first computes it. `draw_a(x + f(r)); draw_b(x + f(r), 1);` becomes
///          `var __gmlc_t0 = x + f(r); draw_a(__gmlc_t0); draw_b(__gmlc_t0, 1);` for a pure `f`. The operands of
///          `+`, `*`, `&`, `|`, `^`, `==` and `!=` and the two sides of a comparison are matched in either order
///          when both are provably numbers.
/// @returns {Struct.GMLC_Opt_CommonSubexpression}
#endregion
function GMLC_Opt_CommonSubexpression() : GMLC_OptimizerPass("common-subexpression") constructor {
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with its repeated expressions reused, or undefined when none is.
	/// @self    GMLC_Opt_CommonSubexpression
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		return __gmlc_reuse_unit(_node, _cx, { calls_only: false, user_pure: undefined, eliminated: "eliminated", temps: "temps_introduced" });
	};
}

#region Entry
#region jsDoc
/// @func    __gmlc_reuse_unit(_node, _cx, _options)
/// @desc    Reuses the repeated expressions of one function (or of a file's body, nested functions left out), one
///          expression at a time, until none is left: each round scans the function, picks the repetition that
///          saves the most and rewrites it. Shared by the passes that reuse values.
/// @param   {Struct.ASTNode} _node    : The function node, or the Script
/// @param   {Struct}         _cx      : The pass context
/// @param   {Struct}         _options : {calls_only, user_pure, eliminated, temps}: whether only calls count, the user
///                                      functions known to be pure (name to true) or undefined, and the statistics
///                                      keys (temps may be undefined)
/// @returns {Struct.ASTNode|Undefined} The new function, or undefined when nothing was reused
#endregion
function __gmlc_reuse_unit(_node, _cx, _options) {
	var _body_path = __gmlc_reuse_body_path(_node);
	if (_body_path == undefined) return undefined;
	var _root = _node;
	var _changed = false;
	repeat (64) {
		var _s = __gmlc_reuse_state(_root, _cx, _options);
		if (_s == undefined) break;
		_s.path = variable_clone(_body_path);
		__gmlc_reuse_scan_list(_s, __gmlc_reuse_at(_root, _body_path));
		var _best = __gmlc_reuse_best(_s);
		if (_best == undefined) break;
		_root = __gmlc_reuse_apply(_s, _root, _best);
		_changed = true;
	}
	return _changed ? _root : undefined;
}

#region jsDoc
/// @func    __gmlc_reuse_state(_root, _cx, _options)
/// @desc    The state of one scan. Undefined when the function writes through `argument`, which aliases its
///          parameters.
/// @param   {Struct.ASTNode} _root    : The function node, or the Script
/// @param   {Struct}         _cx      : The pass context
/// @param   {Struct}         _options : The options
/// @returns {Struct|Undefined}
#endregion
function __gmlc_reuse_state(_root, _cx, _options) {
	if (__gmlc_reuse_writes_argument(_root)) return undefined;
	var _s = {
		cx: _cx,
		optimizer: _cx.optimizer,
		options: _options,
		versions: {},
		serial: 0,
		scope: [],
		next_scope: 0,
		groups: [],
		events: 0,
		throws: 0,
		withs: [],
		loops: 0, // how many loops the statement being scanned is inside
		path: [],
		numeric: {},
		stmt: undefined,
		root_value: undefined,
		root_group: undefined,
	};
	__gmlc_reuse_numeric_locals(_s, _root);
	return _s;
}

#region jsDoc
/// @func    __gmlc_reuse_body_path(_node)
/// @desc    The path to the statement list of a function node, or [] for the Script itself.
/// @param   {Struct.ASTNode} _node : The function node, or the Script
/// @returns {Array<Real>|Undefined}
#endregion
function __gmlc_reuse_body_path(_node) {
	if (_node.kind == __GMLC_NodeKind_Script) return [];
	if (!__gmlc_opt_is_function(_node)) || (_node.body == undefined) return undefined;
	return [__gmlc_opt_child_index(_node, _node.body)];
}

#region jsDoc
/// @func    __gmlc_reuse_writes_argument(_node)
/// @desc    Whether a node writes `argument` or `argumentN`, nested functions left out.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_reuse_writes_argument(_node) {
	var _target = undefined;
	if (_node.kind == __GMLC_NodeKind_Assign) {
		_target = _node.target;
	}
	else if (_node.kind == __GMLC_NodeKind_Update) {
		_target = _node[$ "argument"];
	}
	if (_target != undefined) {
		while (_target.kind == __GMLC_NodeKind_Index) _target = _target.object;
		if (_target.kind == __GMLC_NodeKind_Identifier) && (_target.symbol != undefined) && ((_target.symbol.kind == "BuiltinVar") || (_target.symbol.kind == "Self"))
		&& ((_target.name == "argument") || (__gmlc_argument_index(_target.name) >= 0)) return true;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (!__gmlc_opt_is_function(_child)) && (__gmlc_reuse_writes_argument(_child)) return true;
			}
		_i++}
	_field_index++}
	return false;
}
#endregion

#region Tree access
#region jsDoc
/// @func    __gmlc_reuse_at(_root, _path)
/// @desc    The node at a path of child places.
/// @param   {Struct.ASTNode} _root : The root
/// @param   {Array<Real>}    _path : The path
/// @returns {Struct.ASTNode}
#endregion
function __gmlc_reuse_at(_root, _path) {
	var _node = _root;
	var _i = 0; repeat (array_length(_path)) {
		var _children = _node.children();
		_node = _children[_path[_i]];
	_i++}
	return _node;
}

#region jsDoc
/// @func    __gmlc_reuse_replace_at(_node, _path, _depth, _new)
/// @desc    A copy of a tree with the node at a path replaced; only the nodes along the path are copied.
/// @param   {Struct.ASTNode} _node  : The tree
/// @param   {Array<Real>}    _path  : The path
/// @param   {Real}           _depth : How much of the path is done
/// @param   {Struct.ASTNode} _new   : The node to put there
/// @returns {Struct.ASTNode}
#endregion
function __gmlc_reuse_replace_at(_node, _path, _depth, _new) {
	if (_depth == array_length(_path)) return _new;
	var _slots = _node.childSlots();
	var _slot = _slots[_path[_depth]];
	var _child = __gmlc_reuse_replace_at(_slot.node, _path, _depth + 1, _new);
	var _copy = variable_clone(_node, 0);
	if (_slot.index == undefined) {
		_copy[$ _slot.key] = _child;
	}
	else {
		var _list = variable_clone(_node[$ _slot.key], 0);
		_list[_slot.index] = _child;
		_copy[$ _slot.key] = _list;
	}
	return _copy;
}
#endregion

#region Numbers and equality
#region jsDoc
/// @func    __gmlc_reuse_numeric_locals(_s, _root)
/// @desc    Records the locals that are provably numbers: declared once, at the top of the function, with a value
///          that is a number.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _root : The function node, or the Script
#endregion
function __gmlc_reuse_numeric_locals(_s, _root) {
	var _list = (_root.kind == __GMLC_NodeKind_Script) ? _root : _root.body;
	var _params = _root[$ "params"] ?? [];
	var _body = _list.body;
	var _i = 0; repeat (array_length(_body)) {
		var _stmt = _body[_i];
		if (_stmt.kind == __GMLC_NodeKind_VarDeclList) {
			var _d = 0; repeat (array_length(_stmt.declarations)) {
				var _decl = _stmt.declarations[_d];
				var _name = _decl.target.name;
				if (_decl.init != undefined) && (!__gmlc_reuse_is_param(_params, _name)) && (__gmlc_reuse_count_writes(_root, _name) == 1) && (__gmlc_reuse_numeric(_s, _decl.init)) {
					_s.numeric[$ _name] = true;
				}
			_d++}
		}
	_i++}
}

#region jsDoc
/// @func    __gmlc_reuse_is_param(_params, _name)
/// @desc    Whether a name is a parameter.
/// @param   {Array<Struct.ASTParam>} _params : The parameters
/// @param   {String}                 _name   : The name
/// @returns {Bool}
#endregion
function __gmlc_reuse_is_param(_params, _name) {
	var _p = 0; repeat (array_length(_params)) {
		if (_params[_p].target.name == _name) return true;
	_p++}
	return false;
}

#region jsDoc
/// @func    __gmlc_reuse_count_writes(_root, _name)
/// @desc    How many times a local is declared or written in a function, nested functions left out.
/// @param   {Struct.ASTNode} _root : The function node, or the Script
/// @param   {String}         _name : The local
/// @returns {Real}
#endregion
function __gmlc_reuse_count_writes(_root, _name) {
	var _n = 0;
	var _child_fields = _root.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _root[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				_n += __gmlc_reuse_count_in(_child, _name);
			}
		_i++}
	_field_index++}
	return _n;
}

#region jsDoc
/// @func    __gmlc_reuse_count_in(_node, _name)
/// @desc    How many times a local is declared or written under a node, nested functions left out.
/// @param   {Struct.ASTNode} _node : The node
/// @param   {String}         _name : The local
/// @returns {Real}
#endregion
function __gmlc_reuse_count_in(_node, _name) {
	if (__gmlc_opt_is_function(_node)) return 0;
	var _n = 0;
	switch (_node.kind) {
		case __GMLC_NodeKind_Assign: if (__gmlc_opt_is_local(_node.target)) && (_node.target.name == _name) _n++; break;
		case __GMLC_NodeKind_Update: if (__gmlc_opt_is_local(_node[$ "argument"])) && (_node[$ "argument"].name == _name) _n++; break;
		case __GMLC_NodeKind_VarDecl: if (_node.target.name == _name) _n++; break;
		case __GMLC_NodeKind_Try: if (_node.catch_param != undefined) && (_node.catch_param.name == _name) _n++; break;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				_n += __gmlc_reuse_count_in(_child, _name);
			}
		_i++}
	_field_index++}
	return _n;
}

#region jsDoc
/// @func    __gmlc_reuse_numeric(_s, _node)
/// @desc    Whether an expression is a number whenever it does not throw, with no facts but its own shape: a
///          number literal, a local known to be a number, `-x`, `~x`, an arithmetic or bitwise operator other
///          than `+`, a `+` of two numbers, or a call of a built-in that returns a number.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_reuse_numeric(_s, _node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal:
		return (_node.ty == "real") || (_node.ty == "int64") || (_node.ty == "color");
		case __GMLC_NodeKind_Identifier: {
			if (__gmlc_opt_is_local(_node)) return (_s.numeric[$ _node.name] == true) || (__gmlc_opt_value_type(_node) == "Real") || (__gmlc_opt_value_type(_node) == "Int64");
			if (_node.symbol == undefined) || ((_node.symbol.kind != "Self") && (_node.symbol.kind != "BuiltinVar")) return false;
			var _entry = __gmlc_opt_builtin_variable(_node.name);
			return (_entry != undefined) && (_entry.type == "Real");
		}
		case __GMLC_NodeKind_Unary: {
			if (_node.op == "-") || (_node.op == "~") return true;
			if (_node.op == "+") return __gmlc_reuse_numeric(_s, _node[$ "argument"]);
			return false;
		}
		case __GMLC_NodeKind_Binary: {
			switch (_node.op) {
				case "-": case "*": case "/": case "div": case "mod": case "%": case "&": case "|": case "^": case "<<": case ">>":
				return true;
				case "+":
				return __gmlc_reuse_numeric(_s, _node.left) && __gmlc_reuse_numeric(_s, _node.right);
			}
			return false;
		}
		case __GMLC_NodeKind_Conditional:
		return __gmlc_reuse_numeric(_s, _node.consequent) && __gmlc_reuse_numeric(_s, _node.alternate);
		case __GMLC_NodeKind_Call: {
			var _name = __gmlc_opt_builtin_call(_node);
			if (_name == undefined) return false;
			var _builtins = __gmlc_type_builtins();
			var _type = _builtins[$ _name];
			return (_type == "Double") || (_type == "Int") || (_type == "Int64");
		}
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_reuse_commutes(_op)
/// @desc    Whether the operands of an operator may be swapped when both are numbers.
/// @param   {String} _op : The operator
/// @returns {Bool}
#endregion
function __gmlc_reuse_commutes(_op) {
	switch (_op) {
		case "+": case "*": case "&": case "|": case "^": case "==": case "!=":
		return true;
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_reuse_mirror(_op)
/// @desc    The comparison that holds with the operands swapped, or undefined.
/// @param   {String} _op : The operator
/// @returns {String|Undefined}
#endregion
function __gmlc_reuse_mirror(_op) {
	switch (_op) {
		case "<":  return ">";
		case ">":  return "<";
		case "<=": return ">=";
		case ">=": return "<=";
	}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_reuse_same(_s, _a, _b)
/// @desc    Whether two reusable expressions have the same value: the same code, or the same code with the operands
///          of a commutative operator or a comparison swapped where both are numbers.
/// @param   {Struct}         _s : The scan state
/// @param   {Struct.ASTNode} _a : An expression
/// @param   {Struct.ASTNode} _b : Another expression
/// @returns {Bool}
#endregion
function __gmlc_reuse_same(_s, _a, _b) {
	if (_a.kind != _b.kind) return false;
	switch (_a.kind) {
		case __GMLC_NodeKind_Binary: {
			if (_a.op == _b.op) {
				if (__gmlc_reuse_same(_s, _a.left, _b.left)) && (__gmlc_reuse_same(_s, _a.right, _b.right)) return true;
				return __gmlc_reuse_commutes(_a.op) && __gmlc_reuse_numeric(_s, _a.left) && __gmlc_reuse_numeric(_s, _a.right)
					&& __gmlc_reuse_same(_s, _a.left, _b.right) && __gmlc_reuse_same(_s, _a.right, _b.left);
			}
			var _mirror = __gmlc_reuse_mirror(_a.op);
			return (_mirror != undefined) && (_mirror == _b.op) && __gmlc_reuse_numeric(_s, _a.left) && __gmlc_reuse_numeric(_s, _a.right)
				&& __gmlc_reuse_same(_s, _a.left, _b.right) && __gmlc_reuse_same(_s, _a.right, _b.left);
		}
		case __GMLC_NodeKind_Literal:
		return (_a.ty == _b.ty) && (_a.lexeme == _b.lexeme) && __gmlc_opt_same_value(_a.value, _b.value);
		case __GMLC_NodeKind_Identifier:
		return (_a.name == _b.name) && (_a.symbol != undefined) && (_b.symbol != undefined) && (_a.symbol.kind == _b.symbol.kind);
		case __GMLC_NodeKind_Unary:
		case __GMLC_NodeKind_Logical:
		if (_a.op != _b.op) return false;
		break;
		case __GMLC_NodeKind_Index:
		if (_a.accessor != _b.accessor) || (_a.member != _b.member) return false;
		break;
		case __GMLC_NodeKind_Nullish:
		case __GMLC_NodeKind_Conditional:
		case __GMLC_NodeKind_Call:
		break;
		default:
		return false;
	}
	var _x = _a.children();
	var _y = _b.children();
	if (array_length(_x) != array_length(_y)) return false;
	var _i = 0; repeat (array_length(_x)) {
		if (!__gmlc_reuse_same(_s, _x[_i], _y[_i])) return false;
	_i++}
	return true;
}
#endregion

#region Candidates
#region jsDoc
/// @func    __gmlc_reuse_is_builtin(_kind, _name)
/// @desc    Whether a name is a built-in variable.
/// @param   {String} _kind : The symbol kind
/// @param   {String} _name : The name
/// @returns {Bool}
#endregion
function __gmlc_reuse_is_builtin(_kind, _name) {
	return (_kind == "BuiltinVar") || ((_kind == "Self") && (__gmlc_opt_builtin_variable(_name) != undefined));
}

#region jsDoc
/// @func    __gmlc_reuse_pure_call(_s, _node)
/// @desc    Whether a call returns the same value for the same arguments and the same state, and is not a call that
///          makes a new array or struct each time: a pure user function, or a built-in that is pure or only reads
///          state, is deterministic and allocates nothing.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The call
/// @returns {Bool}
#endregion
function __gmlc_reuse_pure_call(_s, _node) {
	var _callee = _node.callee;
	if (_callee.kind != __GMLC_NodeKind_Identifier) || (_callee.symbol == undefined) return false;
	var _user = _s.options.user_pure;
	if (_user != undefined) && (_user[$ _callee.name] == true) && (_callee.symbol.kind != "Local") return true;
	if (_callee.symbol.kind != "BuiltinFunction") return false;
	var _effects = __GmlcDataEffects();
	var _entry = _effects[$ _callee.name];
	if (_entry == undefined) return false;
	return ((_entry.class == "pure") || (_entry.class == "observer")) && (!_entry.allocates) && (!_entry.nondeterministic);
}

#region jsDoc
/// @func    __gmlc_reuse_candidate(_s, _node)
/// @desc    Whether an expression may be computed once instead of twice: only literals, names, operators,
///          accessors and the calls of __gmlc_reuse_pure_call, and no asset name.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_reuse_candidate(_s, _node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal:
		return true;
		case __GMLC_NodeKind_Identifier: {
			var _symbol = _node.symbol;
			if (_symbol == undefined) return false;
			switch (_symbol.kind) {
				case "Local": case "Static": case "Global": case "BuiltinConstant": case "Enum": case "Macro":
				return true;
				case "Self": case "BuiltinVar": {
					// the built-in variables of the instance are stable; the others change with time or input
					var _entry = __gmlc_opt_builtin_variable(_node.name);
					if (_entry != undefined) return _entry.instance;
					return (_symbol.kind == "Self");
				}
			}
			return false;
		}
		case __GMLC_NodeKind_Binary:
		case __GMLC_NodeKind_Logical:
		case __GMLC_NodeKind_Nullish:
		return __gmlc_reuse_candidate(_s, _node.left) && __gmlc_reuse_candidate(_s, _node.right);
		case __GMLC_NodeKind_Unary:
		return __gmlc_reuse_candidate(_s, _node[$ "argument"]);
		case __GMLC_NodeKind_Conditional:
		return __gmlc_reuse_candidate(_s, _node.test) && __gmlc_reuse_candidate(_s, _node.consequent) && __gmlc_reuse_candidate(_s, _node.alternate);
		case __GMLC_NodeKind_Index: {
			if (!__gmlc_reuse_candidate(_s, _node.object)) return false;
			var _i = 0; repeat (array_length(_node.keys)) {
				if (!__gmlc_reuse_candidate(_s, _node.keys[_i])) return false;
			_i++}
			return true;
		}
		case __GMLC_NodeKind_Call: {
			if (!__gmlc_reuse_pure_call(_s, _node)) return false;
			var _i = 0; repeat (array_length(_node.args)) {
				if (!__gmlc_reuse_candidate(_s, _node.args[_i])) return false;
			_i++}
			return true;
		}
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_reuse_cost(_node)
/// @desc    What computing an expression costs, in operations: an operator or accessor counts 1, a call 2.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Real}
#endregion
function __gmlc_reuse_cost(_node) {
	var _n = 0;
	switch (_node.kind) {
		case __GMLC_NodeKind_Binary: case __GMLC_NodeKind_Logical: case __GMLC_NodeKind_Nullish: case __GMLC_NodeKind_Unary:
		case __GMLC_NodeKind_Conditional: case __GMLC_NodeKind_Index:
		_n = 1;
		break;
		case __GMLC_NodeKind_Call:
		_n = 2;
		break;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				_n += __gmlc_reuse_cost(_child);
			}
		_i++}
	_field_index++}
	return _n;
}

#region jsDoc
/// @func    __gmlc_reuse_dependencies(_s, _node, _keys)
/// @desc    Adds to a list the keys of the state an expression reads: `l:name` for a local, `n:name` for a
///          variable or the member of an accessor, and the groups `l`, `n`, `bv` (a built-in variable), `any`
///          (array and struct contents) and `eng` (engine state).
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The expression
/// @param   {Array<String>}  _keys : The list
#endregion
function __gmlc_reuse_dependencies(_s, _node, _keys) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Identifier: {
			var _symbol = _node.symbol;
			if (_symbol != undefined) {
				switch (_symbol.kind) {
					case "Local":
					array_push(_keys, "l:" + _node.name);
					array_push(_keys, "l");
					break;
					case "BuiltinVar": case "Self": case "Static": case "Global":
					if (__gmlc_reuse_is_builtin(_symbol.kind, _node.name)) array_push(_keys, "bv");
					array_push(_keys, "n:" + _node.name);
					array_push(_keys, "n");
					break;
				}
			}
		break;}
		case __GMLC_NodeKind_Index: {
			array_push(_keys, "any");
			if (_node.accessor == "Dot") && (_node.member != undefined) array_push(_keys, "n:" + _node.member);
		break;}
		case __GMLC_NodeKind_Call: {
			if (__gmlc_reuse_call_class(_s, _node) == "observer") {
				array_push(_keys, "eng");
				array_push(_keys, "any");
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
				__gmlc_reuse_dependencies(_s, _child, _keys);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_reuse_value_signature(_s, _node)
/// @desc    The versions of everything an expression reads, now, as one text: two evaluations of the same code
///          with the same text see the same state.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {String}
#endregion
function __gmlc_reuse_value_signature(_s, _node) {
	var _keys = [];
	__gmlc_reuse_dependencies(_s, _node, _keys);
	array_sort(_keys, true);
	var _sig = "";
	var _last = "";
	var _i = 0; repeat (array_length(_keys)) {
		if (_keys[_i] != _last) {
			_last = _keys[_i];
			_sig += _last + "=" + string(_s.versions[$ _last] ?? 0) + ";";
		}
	_i++}
	return _sig;
}
#endregion

#region Effects and versions
#region jsDoc
/// @func    __gmlc_reuse_call_class(_s, _node)
/// @desc    The effect class of a call: pure for a pure user function, the built-in's class, else unknown.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The call
/// @returns {String}
#endregion
function __gmlc_reuse_call_class(_s, _node) {
	var _callee = _node.callee;
	if (_callee.kind == __GMLC_NodeKind_Identifier) && (_callee.symbol != undefined) && (_callee.symbol.kind != "Local") {
		var _user = _s.options.user_pure;
		if (_user != undefined) && (_user[$ _callee.name] == true) return "pure";
		if (_callee.symbol.kind == "BuiltinFunction") return __gmlc_opt_call_class(_callee.name);
	}
	return "unknown";
}

#region jsDoc
/// @func    __gmlc_reuse_engine_only(_name)
/// @desc    Whether a built-in belongs to a family that writes engine state (drawing, the GPU, shaders, matrices,
///          audio, windows, surfaces, cameras) and never a variable, an array or a struct.
/// @param   {String} _name : The built-in
/// @returns {Bool}
#endregion
function __gmlc_reuse_engine_only(_name) {
	static __prefixes = ["draw_", "gpu_", "shader_", "matrix_", "audio_", "window_", "display_", "surface_", "camera_", "texture_"];
	var _i = 0; repeat (array_length(__prefixes)) {
		if (string_starts_with(_name, __prefixes[_i])) return true;
	_i++}
	return false;
}

#region jsDoc
/// @func    __gmlc_reuse_effect(_s, _node)
/// @desc    What running a call does to the state a reused value reads: "none" for a pure or reading call,
///          "render" for a call that only draws, "engine" for a mutator of engine state, "any" for the rest.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The call
/// @returns {String}
#endregion
function __gmlc_reuse_effect(_s, _node) {
	var _class = __gmlc_reuse_call_class(_s, _node);
	if (_class == "pure") || (_class == "observer") return "none";
	if (_class == "render") return "render";
	if (_class == "mutator") && (__gmlc_reuse_engine_only(_node.callee.name)) return "engine";
	return "any";
}

#region jsDoc
/// @func    __gmlc_reuse_has_effects(_s, _node)
/// @desc    Whether evaluating an expression writes state a reused value may read: an assignment, an increment, a
///          `new`, a method call or a call that mutates. Function literals are left out.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_reuse_has_effects(_s, _node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Assign: case __GMLC_NodeKind_Update: case __GMLC_NodeKind_New: case __GMLC_NodeKind_MethodCall:
		case __GMLC_NodeKind_Delete:
		return true;
		case __GMLC_NodeKind_FunctionExpr:
		return false;
		case __GMLC_NodeKind_Call: {
			var _effect = __gmlc_reuse_effect(_s, _node);
			if (_effect == "engine") || (_effect == "any") return true;
		break;}
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_reuse_has_effects(_s, _child)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_reuse_is_effect(_s, _node)
/// @desc    Whether a node itself, not what is inside it, writes state a reused value may read.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_reuse_is_effect(_s, _node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Assign: case __GMLC_NodeKind_Update: case __GMLC_NodeKind_New: case __GMLC_NodeKind_MethodCall:
		case __GMLC_NodeKind_Delete:
		return true;
		case __GMLC_NodeKind_Call: {
			var _effect = __gmlc_reuse_effect(_s, _node);
			return (_effect == "engine") || (_effect == "any");
		}
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_reuse_bump(_s, _key)
/// @desc    Gives a part of the state a version nothing has seen.
/// @param   {Struct} _s   : The scan state
/// @param   {String} _key : The key
#endregion
function __gmlc_reuse_bump(_s, _key) {
	_s.serial++;
	_s.versions[$ _key] = _s.serial;
}

#region jsDoc
/// @func    __gmlc_reuse_kill_local(_s, _name)
/// @desc    A local is written.
/// @param   {Struct} _s    : The scan state
/// @param   {String} _name : The local
#endregion
function __gmlc_reuse_kill_local(_s, _name) {
	__gmlc_reuse_bump(_s, "l:" + _name);
	_s.events++;
}

#region jsDoc
/// @func    __gmlc_reuse_kill_ident(_s, _name, _builtin)
/// @desc    A variable of the instance, a global or a static is written; a write to a built-in variable also
///          changes the ones that follow it.
/// @param   {Struct} _s       : The scan state
/// @param   {String} _name    : The variable
/// @param   {Bool}   _builtin : Whether it is a built-in variable
#endregion
function __gmlc_reuse_kill_ident(_s, _name, _builtin) {
	__gmlc_reuse_bump(_s, "n:" + _name);
	__gmlc_reuse_bump(_s, "eng");
	if (_builtin) __gmlc_reuse_bump(_s, "bv");
	_s.events++;
}

#region jsDoc
/// @func    __gmlc_reuse_kill_engine(_s)
/// @desc    Engine state is written.
/// @param   {Struct} _s : The scan state
#endregion
function __gmlc_reuse_kill_engine(_s) {
	__gmlc_reuse_bump(_s, "eng");
	_s.events++;
}

#region jsDoc
/// @func    __gmlc_reuse_kill_any(_s)
/// @desc    Anything but a local may be written.
/// @param   {Struct} _s : The scan state
#endregion
function __gmlc_reuse_kill_any(_s) {
	__gmlc_reuse_bump(_s, "any");
	__gmlc_reuse_bump(_s, "eng");
	__gmlc_reuse_bump(_s, "n");
	__gmlc_reuse_bump(_s, "bv");
	_s.events++;
}

#region jsDoc
/// @func    __gmlc_reuse_kill_all(_s)
/// @desc    Anything may be written, locals too: what code the pass must not touch can do.
/// @param   {Struct} _s : The scan state
#endregion
function __gmlc_reuse_kill_all(_s) {
	__gmlc_reuse_kill_any(_s);
	__gmlc_reuse_bump(_s, "l");
}

#region jsDoc
/// @func    __gmlc_reuse_kill_target(_s, _target)
/// @desc    The target of an assignment or an increment is written.
/// @param   {Struct}         _s      : The scan state
/// @param   {Struct.ASTNode} _target : The target
#endregion
function __gmlc_reuse_kill_target(_s, _target) {
	if (_target.kind == __GMLC_NodeKind_Identifier) && (_target.symbol != undefined) {
		switch (_target.symbol.kind) {
			case "Local":
			__gmlc_reuse_kill_local(_s, _target.name);
			return;
			default:
			__gmlc_reuse_kill_ident(_s, _target.name, __gmlc_reuse_is_builtin(_target.symbol.kind, _target.name));
			return;
		}
	}
	__gmlc_reuse_kill_any(_s);
}

#region jsDoc
/// @func    __gmlc_reuse_apply_effect(_s, _node)
/// @desc    Applies what a node itself writes to the versions.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The node
#endregion
function __gmlc_reuse_apply_effect(_s, _node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Assign:
		__gmlc_reuse_kill_target(_s, _node.target);
		break;
		case __GMLC_NodeKind_Update:
		__gmlc_reuse_kill_target(_s, _node[$ "argument"]);
		break;
		case __GMLC_NodeKind_New: case __GMLC_NodeKind_MethodCall: case __GMLC_NodeKind_Delete:
		__gmlc_reuse_kill_any(_s);
		break;
		case __GMLC_NodeKind_Call: {
			var _effect = __gmlc_reuse_effect(_s, _node);
			if (_effect == "render") {
				_s.events++;
			}
			else if (_effect == "engine") {
				__gmlc_reuse_kill_engine(_s);
			}
			else if (_effect == "any") {
				__gmlc_reuse_kill_any(_s);
			}
		break;}
	}
}

#region jsDoc
/// @func    __gmlc_reuse_kill_walk(_s, _node)
/// @desc    Applies every write under an expression, for one that is not scanned for reuse.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The expression
#endregion
function __gmlc_reuse_kill_walk(_s, _node) {
	if (_node.kind == __GMLC_NodeKind_FunctionExpr) return;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_reuse_kill_walk(_s, _child);
			}
		_i++}
	_field_index++}
	__gmlc_reuse_apply_effect(_s, _node);
}

#region jsDoc
/// @func    __gmlc_reuse_written(_s, _node, _out)
/// @desc    Collects what a statement may write, nested functions left out: locals, variables (with whether they
///          are built-in), and whether engine state, anything, or everything (code the pass must not touch) is.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The statement
/// @param   {Struct}         _out  : {locals, idents, engine, any, all}
#endregion
function __gmlc_reuse_written(_s, _node, _out) {
	if (__gmlc_opt_is_function(_node)) return;
	if (_s.optimizer.__isNoOp(_node)) {
		_out.all = true;
		return;
	}
	switch (_node.kind) {
		case __GMLC_NodeKind_Assign:
		__gmlc_reuse_written_target(_node.target, _out);
		break;
		case __GMLC_NodeKind_Update:
		__gmlc_reuse_written_target(_node[$ "argument"], _out);
		break;
		case __GMLC_NodeKind_VarDecl:
		__gmlc_reuse_written_target(_node.target, _out);
		break;
		case __GMLC_NodeKind_Try:
		if (_node.catch_param != undefined) _out.locals[$ _node.catch_param.name] = true;
		break;
		case __GMLC_NodeKind_With: case __GMLC_NodeKind_New: case __GMLC_NodeKind_MethodCall: case __GMLC_NodeKind_Delete:
		_out.any = true;
		break;
		case __GMLC_NodeKind_Call: {
			var _effect = __gmlc_reuse_effect(_s, _node);
			if (_effect == "engine") {
				_out.engine = true;
			}
			else if (_effect == "any") {
				_out.any = true;
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
				__gmlc_reuse_written(_s, _child, _out);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_reuse_written_target(_target, _out)
/// @desc    Adds a written target to what a statement writes.
/// @param   {Struct.ASTNode} _target : The target
/// @param   {Struct}         _out    : What is written
#endregion
function __gmlc_reuse_written_target(_target, _out) {
	if (_target.kind == __GMLC_NodeKind_Identifier) && (_target.symbol != undefined) {
		switch (_target.symbol.kind) {
			case "Local":
			_out.locals[$ _target.name] = true;
			return;
			default:
			_out.idents[$ _target.name] = (_out.idents[$ _target.name] ?? false) || __gmlc_reuse_is_builtin(_target.symbol.kind, _target.name);
			return;
		}
	}
	_out.any = true;
}

#region jsDoc
/// @func    __gmlc_reuse_bump_written(_s, _stmt)
/// @desc    Gives everything a statement may write a new version: at the start of a loop, and after any statement
///          that runs only in part.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _stmt : The statement
#endregion
function __gmlc_reuse_bump_written(_s, _stmt) {
	var _out = { locals: {}, idents: {}, engine: false, any: false, all: false };
	__gmlc_reuse_written(_s, _stmt, _out);
	if (_out.all) __gmlc_reuse_kill_all(_s);
	if (_out.any) __gmlc_reuse_kill_any(_s);
	if (_out.engine) __gmlc_reuse_kill_engine(_s);
	var _names = struct_get_names(_out.locals);
	var _i = 0; repeat (array_length(_names)) {
		__gmlc_reuse_kill_local(_s, _names[_i]);
	_i++}
	_names = struct_get_names(_out.idents);
	_i = 0; repeat (array_length(_names)) {
		__gmlc_reuse_kill_ident(_s, _names[_i], _out.idents[$ _names[_i]]);
	_i++}
}
#endregion

#region Scan
#region jsDoc
/// @func    __gmlc_reuse_new_scope(_s)
/// @desc    A new scope number: each statement list, and each part of a statement that runs only sometimes, has one.
/// @param   {Struct} _s : The scan state
/// @returns {Real}
#endregion
function __gmlc_reuse_new_scope(_s) {
	_s.next_scope++;
	return _s.next_scope;
}

#region jsDoc
/// @func    __gmlc_reuse_prefix(_a, _b)
/// @desc    Whether a list starts with all of another: whether the code in scope _a runs whenever the code in scope _b does.
/// @param   {Array<Real>} _a : The shorter list
/// @param   {Array<Real>} _b : The longer list
/// @returns {Bool}
#endregion
function __gmlc_reuse_prefix(_a, _b) {
	if (array_length(_a) > array_length(_b)) return false;
	var _i = 0; repeat (array_length(_a)) {
		if (_a[_i] != _b[_i]) return false;
	_i++}
	return true;
}

#region jsDoc
/// @func    __gmlc_reuse_register(_s, _node)
/// @desc    Notes an expression the scan reaches: it joins the group of an expression with the same value that
///          came before and still holds, or starts a group.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The expression
#endregion
function __gmlc_reuse_register(_s, _node) {
	var _kind = _node.kind;
	if (_s.options.calls_only) {
		if (_kind != __GMLC_NodeKind_Call) return;
	}
	else if (_kind != __GMLC_NodeKind_Binary) && (_kind != __GMLC_NodeKind_Unary) && (_kind != __GMLC_NodeKind_Logical)
	&& (_kind != __GMLC_NodeKind_Nullish) && (_kind != __GMLC_NodeKind_Conditional) && (_kind != __GMLC_NodeKind_Index)
	&& (_kind != __GMLC_NodeKind_Call) {
		return;
	}
	if (!__gmlc_reuse_candidate(_s, _node)) return;
	var _sig = __gmlc_reuse_value_signature(_s, _node);
	if (_sig == "") return;
	var _group = undefined;
	var _g = 0; repeat (array_length(_s.groups)) {
		var _other = _s.groups[_g];
		if (_other.signature == _sig) && (__gmlc_reuse_prefix(_other.occurrences[0].chain, _s.scope)) && (__gmlc_reuse_same(_s, _other.expr, _node)) {
			_group = _other;
			break;
		}
	_g++}
	var _stmt = _s.stmt;
	var _hoist = undefined;
	if (_stmt != undefined) && (_stmt.list_path != undefined) && (array_length(_s.scope) == _stmt.scope_len) && (_s.events == _stmt.events) && (_s.throws == _stmt.throws) {
		_hoist = { list_path: _stmt.list_path, index: _stmt.index, span: _stmt.span };
	}
	var _occurrence = { path: variable_clone(_s.path), node: _node, chain: variable_clone(_s.scope), hoist: _hoist, whole: (_node == _s.root_value), holder_ok: false, in_loop: (_s.loops > 0) };
	if (_group == undefined) {
		_group = { expr: _node, cost: __gmlc_reuse_cost(_node), signature: _sig, occurrences: [_occurrence], holder: undefined, holder_version: 0 };
		array_push(_s.groups, _group);
	}
	else {
		_occurrence.holder_ok = (_group.holder != undefined) && ((_s.versions[$ "l:" + _group.holder] ?? 0) == _group.holder_version);
		array_push(_group.occurrences, _occurrence);
	}
	if (_node == _s.root_value) _s.root_group = _group;
}

#region jsDoc
/// @func    __gmlc_reuse_set_holder(_s, _name, _value)
/// @desc    After `name = value`: the local now holds the value of the group the value belongs to, unless it already
///          has a holder that still does, or the value reads the local itself.
/// @param   {Struct}         _s     : The scan state
/// @param   {String}         _name  : The local
/// @param   {Struct.ASTNode} _value : The value assigned
#endregion
function __gmlc_reuse_set_holder(_s, _name, _value) {
	var _group = _s.root_group;
	_s.root_value = undefined;
	_s.root_group = undefined;
	if (_group == undefined) return;
	if (__gmlc_opt_reads(_value, _name) > 0) return;
	if (_group.holder != undefined) && ((_s.versions[$ "l:" + _group.holder] ?? 0) == _group.holder_version) return;
	_group.holder = _name;
	_group.holder_version = _s.versions[$ "l:" + _name] ?? 0;
}

#region jsDoc
/// @func    __gmlc_reuse_may_throw(_s, _node)
/// @desc    Whether a node itself may throw when it runs, once what is inside it has: a name that is not a local, a
///          constant or a built-in instance variable of an instance, an operator on operands not known to be
///          numbers, an accessor, a call the effect table does not list as not throwing.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_reuse_may_throw(_s, _node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal: case __GMLC_NodeKind_FunctionExpr: case __GMLC_NodeKind_Nameof:
		return false;
		case __GMLC_NodeKind_Identifier: {
			if (_node.symbol == undefined) return true;
			switch (_node.symbol.kind) {
				case "Local": case "BuiltinConstant": case "Enum": case "Asset": case "Macro": case "BuiltinFunction":
				return false;
			}
			// inside `with (target)` self is the target: an object, `all` or `noone` is sure to be instances
			if (array_length(_s.withs) > 0) && (_node.symbol.kind == "Self") {
				var _entry = __gmlc_opt_builtin_variable(_node.name);
				if (_entry != undefined) && (_entry.instance) return !_s.withs[array_length(_s.withs) - 1];
				return true;
			}
			return !__gmlc_opt_reads_instance_builtin(_s.cx, _node);
		}
		case __GMLC_NodeKind_Unary:
		return !__gmlc_reuse_numeric(_s, _node[$ "argument"]);
		case __GMLC_NodeKind_Binary: {
			switch (_node.op) {
				case "+": case "-": case "*": case "<": case ">": case "<=": case ">=": case "==": case "!=":
				return !(__gmlc_reuse_numeric(_s, _node.left) && __gmlc_reuse_numeric(_s, _node.right));
			}
			return true;
		}
		case __GMLC_NodeKind_Call: {
			var _name = __gmlc_opt_builtin_call(_node);
			if (_name == undefined) return true;
			var _effects = __GmlcDataEffects();
			var _entry = _effects[$ _name];
			return (_entry == undefined) || (_entry.may_throw) || (!__gmlc_opt_args_accepted(_name, _node.args, __gmlc_opt_value_type));
		}
		case __GMLC_NodeKind_Assign:
		return (_node.op != "=") || (_node.target.kind != __GMLC_NodeKind_Identifier);
	}
	return true;
}

#region jsDoc
/// @func    __gmlc_reuse_visit(_s, _node)
/// @desc    Scans an expression that writes nothing, in the order it runs; the path of the node is on the scan's
///          path. The part of `a && b`, `a ?? b` and `c ? a : b` that runs only sometimes is a scope of its own.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _node : The expression
#endregion
function __gmlc_reuse_visit(_s, _node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal: case __GMLC_NodeKind_Nameof: case __GMLC_NodeKind_FunctionExpr:
		return;
		case __GMLC_NodeKind_Identifier:
		if (__gmlc_reuse_may_throw(_s, _node)) _s.throws++;
		return;
		case __GMLC_NodeKind_Logical:
		case __GMLC_NodeKind_Nullish: {
			__gmlc_reuse_register(_s, _node);
			var _children = _node.children();
			__gmlc_reuse_visit_child(_s, _children[0], 0, false);
			__gmlc_reuse_visit_child(_s, _children[1], 1, true);
			_s.throws++;
		return;}
		case __GMLC_NodeKind_Conditional: {
			__gmlc_reuse_register(_s, _node);
			var _children = _node.children();
			__gmlc_reuse_visit_child(_s, _children[0], 0, false);
			__gmlc_reuse_visit_child(_s, _children[1], 1, true);
			__gmlc_reuse_visit_child(_s, _children[2], 2, true);
			_s.throws++;
		return;}
	}
	__gmlc_reuse_register(_s, _node);
	var _children = _node.children();
	var _i = 0; repeat (array_length(_children)) {
		array_push(_s.path, _i);
		__gmlc_reuse_visit(_s, _children[_i]);
		array_pop(_s.path);
	_i++}
	if (_node.kind == __GMLC_NodeKind_Call) && (__gmlc_reuse_effect(_s, _node) == "render") _s.events++;
	if (__gmlc_reuse_may_throw(_s, _node)) _s.throws++;
}

#region jsDoc
/// @func    __gmlc_reuse_visit_child(_s, _child, _i, _own_scope)
/// @desc    Scans one child of an expression, in a scope of its own when it runs only sometimes.
/// @param   {Struct}         _s         : The scan state
/// @param   {Struct.ASTNode} _child     : The child
/// @param   {Real}           _i         : The child's place
/// @param   {Bool}           _own_scope : Whether the child runs only sometimes
#endregion
function __gmlc_reuse_visit_child(_s, _child, _i, _own_scope) {
	array_push(_s.path, _i);
	if (_own_scope) array_push(_s.scope, __gmlc_reuse_new_scope(_s));
	__gmlc_reuse_visit(_s, _child);
	if (_own_scope) array_pop(_s.scope);
	array_pop(_s.path);
}

#region jsDoc
/// @func    __gmlc_reuse_spine(_s, _target)
/// @desc    Scans the keys of an assignment's target, `a[i][j] = v`: the arrays and structs it writes into are not
///          scanned, because reading one into a temporary would copy it before it is written.
/// @param   {Struct}         _s      : The scan state
/// @param   {Struct.ASTNode} _target : The target
#endregion
function __gmlc_reuse_spine(_s, _target) {
	if (_target.kind != __GMLC_NodeKind_Index) return;
	var _children = _target.children();
	var _i = 1; repeat (array_length(_children) - 1) {
		array_push(_s.path, _i);
		__gmlc_reuse_visit(_s, _children[_i]);
		array_pop(_s.path);
	_i++}
	if (_children[0].kind == __GMLC_NodeKind_Index) {
		array_push(_s.path, 0);
		__gmlc_reuse_spine(_s, _children[0]);
		array_pop(_s.path);
	}
}

#region jsDoc
/// @func    __gmlc_reuse_top(_s, _expr)
/// @desc    Scans an expression a statement runs, whose path is on the scan's path. One that writes nothing is
///          scanned as it is. One that is a single write, an assignment or a call that mutates, with nothing that
///          writes inside it, has the parts it reads scanned and then the write applied. Any other is not scanned
///          for reuse: its writes are applied and nothing in it is matched, because the order its parts run in
///          is not known.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _expr : The expression
#endregion
function __gmlc_reuse_top(_s, _expr) {
	if (!__gmlc_reuse_has_effects(_s, _expr)) {
		__gmlc_reuse_visit(_s, _expr);
		return;
	}
	if (__gmlc_reuse_is_effect(_s, _expr)) {
		var _children = _expr.children();
		var _clean = true;
		var _i = 0; repeat (array_length(_children)) {
			if (__gmlc_reuse_has_effects(_s, _children[_i])) _clean = false;
		_i++}
		if (_clean) {
			if (_expr.kind == __GMLC_NodeKind_Assign) {
				array_push(_s.path, 0);
				__gmlc_reuse_spine(_s, _expr.target);
				array_pop(_s.path);
				array_push(_s.path, 1);
				__gmlc_reuse_visit(_s, _expr.value);
				array_pop(_s.path);
			}
			else if (_expr.kind == __GMLC_NodeKind_Update) {
				array_push(_s.path, 0);
				__gmlc_reuse_spine(_s, _expr[$ "argument"]);
				array_pop(_s.path);
			}
			else {
				_i = 0; repeat (array_length(_children)) {
					array_push(_s.path, _i);
					__gmlc_reuse_visit(_s, _children[_i]);
					array_pop(_s.path);
				_i++}
			}
			if (__gmlc_reuse_may_throw(_s, _expr)) _s.throws++;
			__gmlc_reuse_apply_effect(_s, _expr);
			return;
		}
	}
	__gmlc_reuse_kill_walk(_s, _expr);
}

#region jsDoc
/// @func    __gmlc_reuse_top_child(_s, _parent, _child)
/// @desc    Scans an expression of a statement, with its place among the statement's children on the path.
/// @param   {Struct}         _s      : The scan state
/// @param   {Struct.ASTNode} _parent : The statement
/// @param   {Struct.ASTNode} _child  : The expression
#endregion
function __gmlc_reuse_top_child(_s, _parent, _child) {
	array_push(_s.path, __gmlc_opt_child_index(_parent, _child));
	__gmlc_reuse_top(_s, _child);
	array_pop(_s.path);
}

#region jsDoc
/// @func    __gmlc_reuse_scan_list(_s, _list)
/// @desc    Scans a statement list, whose path is on the scan's path, in a scope of its own. A function declared in
///          it is not part of the scan.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _list : The Script, Block, Case or Default
#endregion
function __gmlc_reuse_scan_list(_s, _list) {
	var _list_path = variable_clone(_s.path);
	array_push(_s.scope, __gmlc_reuse_new_scope(_s));
	var _offset = (_list.kind == __GMLC_NodeKind_Case) ? 1 : 0;
	var _body = _list.body;
	var _i = 0; repeat (array_length(_body)) {
		var _stmt = _body[_i];
		if (!__gmlc_opt_is_function(_stmt)) {
			array_push(_s.path, _offset + _i);
			__gmlc_reuse_scan_statement(_s, _stmt, _list_path, _i);
			array_pop(_s.path);
		}
	_i++}
	array_pop(_s.scope);
}

#region jsDoc
/// @func    __gmlc_reuse_scan_body(_s, _parent, _body)
/// @desc    Scans the body of a compound statement: a block as a list, any other statement alone.
/// @param   {Struct}         _s      : The scan state
/// @param   {Struct.ASTNode} _parent : The compound statement
/// @param   {Struct.ASTNode} _body   : The body
#endregion
function __gmlc_reuse_scan_body(_s, _parent, _body) {
	array_push(_s.path, __gmlc_opt_child_index(_parent, _body));
	if (_body.kind == __GMLC_NodeKind_Block) {
		__gmlc_reuse_scan_list(_s, _body);
	}
	else {
		array_push(_s.scope, __gmlc_reuse_new_scope(_s));
		__gmlc_reuse_scan_statement(_s, _body, undefined, 0);
		array_pop(_s.scope);
	}
	array_pop(_s.path);
}

#region jsDoc
/// @func    __gmlc_reuse_scan_statement(_s, _stmt, _list_path, _index)
/// @desc    Scans a statement, whose path is on the scan's path. A statement the pass must not touch writes
///          anything. `_list_path` is undefined for a statement that is not in a list: a temporary cannot be
///          declared before it.
/// @param   {Struct}         _s         : The scan state
/// @param   {Struct.ASTNode} _stmt      : The statement
/// @param   {Array<Real>}    _list_path : The path of the list it is in, or undefined
/// @param   {Real}           _index     : Its place in the list
#endregion
function __gmlc_reuse_scan_statement(_s, _stmt, _list_path, _index) {
	if (_s.optimizer.__isNoOp(_stmt)) {
		__gmlc_reuse_kill_all(_s);
		return;
	}
	var _outer = _s.stmt;
	_s.stmt = { list_path: _list_path, index: _index, span: _stmt.span, scope_len: array_length(_s.scope), events: _s.events, throws: _s.throws };
	switch (_stmt.kind) {
		case __GMLC_NodeKind_ExprStmt: {
			var _expr = _stmt.expression;
			var _local = undefined;
			if (_expr.kind == __GMLC_NodeKind_Assign) && (_expr.op == "=") && (__gmlc_opt_is_local(_expr.target)) {
				_local = _expr.target.name;
				_s.root_value = _expr.value;
				_s.root_group = undefined;
			}
			__gmlc_reuse_top_child(_s, _stmt, _expr);
			if (_local != undefined) {
				__gmlc_reuse_set_holder(_s, _local, _expr.value);
			}
		break;}
		case __GMLC_NodeKind_VarDeclList: {
			var _d = 0; repeat (array_length(_stmt.declarations)) {
				var _decl = _stmt.declarations[_d];
				var _name = _decl.target.name;
				array_push(_s.path, _d);
				if (_decl.init != undefined) {
					_s.root_value = _decl.init;
					_s.root_group = undefined;
					__gmlc_reuse_top_child(_s, _decl, _decl.init);
					__gmlc_reuse_kill_local(_s, _name);
					__gmlc_reuse_set_holder(_s, _name, _decl.init);
				}
				else {
					__gmlc_reuse_kill_local(_s, _name);
				}
				array_pop(_s.path);
			_d++}
		break;}
		case __GMLC_NodeKind_Return:
		case __GMLC_NodeKind_Throw: {
			if (_stmt[$ "argument"] != undefined) __gmlc_reuse_top_child(_s, _stmt, _stmt[$ "argument"]);
		break;}
		case __GMLC_NodeKind_Block: {
			__gmlc_reuse_scan_list(_s, _stmt);
		break;}
		case __GMLC_NodeKind_StaticDecl:
		case __GMLC_NodeKind_Delete: {
			__gmlc_reuse_bump_written(_s, _stmt);
		break;}
		case __GMLC_NodeKind_If: {
			__gmlc_reuse_top_child(_s, _stmt, _stmt.test);
			var _snap = variable_clone(_s.versions);
			__gmlc_reuse_scan_body(_s, _stmt, _stmt.consequent);
			if (_stmt.alternate != undefined) {
				_s.versions = variable_clone(_snap);
				__gmlc_reuse_scan_body(_s, _stmt, _stmt.alternate);
			}
			__gmlc_reuse_bump_written(_s, _stmt);
		break;}
		case __GMLC_NodeKind_While: {
			__gmlc_reuse_bump_written(_s, _stmt);
			array_push(_s.scope, __gmlc_reuse_new_scope(_s));
			_s.loops++;
			__gmlc_reuse_top_child(_s, _stmt, _stmt.test);
			__gmlc_reuse_scan_body(_s, _stmt, _stmt.body);
			_s.loops--;
			array_pop(_s.scope);
			__gmlc_reuse_bump_written(_s, _stmt);
		break;}
		case __GMLC_NodeKind_DoUntil: {
			__gmlc_reuse_bump_written(_s, _stmt);
			array_push(_s.scope, __gmlc_reuse_new_scope(_s));
			_s.loops++;
			__gmlc_reuse_scan_body(_s, _stmt, _stmt.body);
			__gmlc_reuse_top_child(_s, _stmt, _stmt.test);
			_s.loops--;
			array_pop(_s.scope);
			__gmlc_reuse_bump_written(_s, _stmt);
		break;}
		case __GMLC_NodeKind_Repeat: {
			__gmlc_reuse_top_child(_s, _stmt, _stmt.count);
			__gmlc_reuse_bump_written(_s, _stmt);
			array_push(_s.scope, __gmlc_reuse_new_scope(_s));
			_s.loops++;
			__gmlc_reuse_scan_body(_s, _stmt, _stmt.body);
			_s.loops--;
			array_pop(_s.scope);
			__gmlc_reuse_bump_written(_s, _stmt);
		break;}
		case __GMLC_NodeKind_For: {
			if (_stmt.init != undefined) {
				array_push(_s.path, __gmlc_opt_child_index(_stmt, _stmt.init));
				__gmlc_reuse_scan_statement(_s, _stmt.init, undefined, 0);
				array_pop(_s.path);
			}
			__gmlc_reuse_bump_written(_s, _stmt);
			array_push(_s.scope, __gmlc_reuse_new_scope(_s));
			_s.loops++;
			if (_stmt.test != undefined) __gmlc_reuse_top_child(_s, _stmt, _stmt.test);
			__gmlc_reuse_scan_body(_s, _stmt, _stmt.body);
			if (_stmt.update != undefined) __gmlc_reuse_top_child(_s, _stmt, _stmt.update);
			_s.loops--;
			array_pop(_s.scope);
			__gmlc_reuse_bump_written(_s, _stmt);
		break;}
		case __GMLC_NodeKind_With: {
			__gmlc_reuse_top_child(_s, _stmt, _stmt.target);
			__gmlc_reuse_bump_written(_s, _stmt);
			array_push(_s.scope, __gmlc_reuse_new_scope(_s));
			var _target = _stmt.target;
			array_push(_s.withs, (_target.kind == __GMLC_NodeKind_Identifier) && (((_target.symbol != undefined) && (_target.symbol.kind == "Asset")) || (_target.name == "all") || (_target.name == "noone")));
			__gmlc_reuse_scan_body(_s, _stmt, _stmt.body);
			array_pop(_s.withs);
			array_pop(_s.scope);
			__gmlc_reuse_bump_written(_s, _stmt);
		break;}
		case __GMLC_NodeKind_Switch: {
			__gmlc_reuse_top_child(_s, _stmt, _stmt.discriminant);
			__gmlc_reuse_bump_written(_s, _stmt);
			var _cases = _stmt.cases;
			var _k = 0; repeat (array_length(_cases)) {
				var _case = _cases[_k];
				array_push(_s.path, __gmlc_opt_child_index(_stmt, _case));
				array_push(_s.scope, __gmlc_reuse_new_scope(_s));
				if (_case.kind == __GMLC_NodeKind_Case) __gmlc_reuse_top_child(_s, _case, _case.test);
				__gmlc_reuse_scan_list(_s, _case);
				array_pop(_s.scope);
				array_pop(_s.path);
			_k++}
			__gmlc_reuse_bump_written(_s, _stmt);
		break;}
		case __GMLC_NodeKind_Try: {
			__gmlc_reuse_scan_body(_s, _stmt, _stmt.block);
			__gmlc_reuse_bump_written(_s, _stmt);
			if (_stmt.catch_body != undefined) {
				if (_stmt.catch_param != undefined) __gmlc_reuse_kill_local(_s, _stmt.catch_param.name);
				__gmlc_reuse_scan_body(_s, _stmt, _stmt.catch_body);
			}
			if (_stmt.finally_body != undefined) {
				__gmlc_reuse_bump_written(_s, _stmt);
				__gmlc_reuse_scan_body(_s, _stmt, _stmt.finally_body);
			}
			__gmlc_reuse_bump_written(_s, _stmt);
		break;}
	}
	_s.stmt = _outer;
}
#endregion

#region Choosing and rewriting
#region jsDoc
/// @func    __gmlc_reuse_best(_s)
/// @desc    The repetition that saves the most operations: through a local that holds the value (each use saves
///          the expression's cost), or through a new temporary when the first use can be moved before its
///          statement and at least two operations are saved by the uses that run whenever the first does: a use only
///          some runs reach (`if (abs(v) > m) { m = abs(v); }`) saves nothing on the others, which still pay for the
///          temporary. The earlier group wins a tie, then the dearer one.
/// @param   {Struct} _s : The scan state
/// @returns {Struct|Undefined} {group, mode, saving, cost}
#endregion
function __gmlc_reuse_best(_s) {
	var _best = undefined;
	// YYC reads an array element or a field again faster than it stores it in a new local, and calls array_length a
	// second time faster than it writes and reads a new local for one use; the VM gains from the local
	var _yyc = (_s.cx.optimizer.outputName() == "gml-source-yyc");
	var _g = 0; repeat (array_length(_s.groups)) {
		var _group = _s.groups[_g];
		var _n = array_length(_group.occurrences);
		if (_n >= 2) {
			var _cost = _group.cost;
			var _first = _group.occurrences[0];
			var _held = 0;
			var _always = 0;
			var _o = 1; repeat (_n - 1) {
				if (_group.occurrences[_o].holder_ok) _held++;
				if (array_equals(_group.occurrences[_o].chain, _first.chain)) _always++;
			_o++}
			var _temp = ((_first.hoist != undefined) && (!_first.whole)) ? _always * _cost : 0;
			var _mode = "";
			var _saving = 0;
			if (_held > 0) && (_held * _cost >= _temp) {
				_mode = "holder";
				_saving = _held * _cost;
			}
			else if (_temp >= 2) && (!(_yyc && _first.in_loop && __gmlc_reuse_bare_access(_group.expr)))
			&& (!(_yyc && (_always == 1) && (__gmlc_opt_builtin_call(_group.expr) == "array_length"))) {
				_mode = "temp";
				_saving = _temp;
			}
			if (_mode != "") && ((_best == undefined) || (_saving > _best.saving) || ((_saving == _best.saving) && (_cost > _best.cost))) {
				_best = { group: _group, mode: _mode, saving: _saving, cost: _cost };
			}
		}
	_g++}
	return _best;
}

#region jsDoc
/// @func    __gmlc_reuse_bare_access(_node)
/// @desc    Whether an expression only reads a field: a chain of accesses on a name, each key a name or a literal, at
///          least one of them a field (`.` or `[$`).
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_reuse_bare_access(_node) {
	return __gmlc_reuse_bare_chain(_node) && __gmlc_reuse_reads_field(_node);
}

#region jsDoc
/// @func    __gmlc_reuse_reads_field(_node)
/// @desc    Whether an access chain reads a field at some level.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_reuse_reads_field(_node) {
	if (_node.kind != __GMLC_NodeKind_Index) return false;
	return (_node.accessor == "Dot") || (_node.accessor == "Struct") || __gmlc_reuse_reads_field(_node.object);
}

#region jsDoc
/// @func    __gmlc_reuse_bare_chain(_node)
/// @desc    Whether an expression is a chain of accesses on a name, each key a name or a literal.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_reuse_bare_chain(_node) {
	if (_node.kind != __GMLC_NodeKind_Index) return false;
	var _keys = _node.keys;
	var _k = 0; repeat (array_length(_keys)) {
		var _kind = _keys[_k].kind;
		if (_kind != __GMLC_NodeKind_Identifier) && (_kind != __GMLC_NodeKind_Literal) return false;
	_k++}
	var _object = _node.object;
	return (_object.kind == __GMLC_NodeKind_Identifier) || __gmlc_reuse_bare_chain(_object);
}

#region jsDoc
/// @func    __gmlc_reuse_apply(_s, _root, _best)
/// @desc    Rewrites a function for one repetition: the uses are replaced by the holder or by a new temporary, and
///          the temporary is declared before the statement of the first use. Nothing under the old tree changes.
/// @param   {Struct}         _s    : The scan state
/// @param   {Struct.ASTNode} _root : The function node, or the Script
/// @param   {Struct}         _best : What __gmlc_reuse_best chose
/// @returns {Struct.ASTNode}
#endregion
function __gmlc_reuse_apply(_s, _root, _best) {
	var _group = _best.group;
	var _occurrence = _group.occurrences;
	var _temp = (_best.mode == "temp");
	var _name = _temp ? _s.optimizer.newTemporary(_s.cx) : _group.holder;
	var _count = 0;
	var _o = 0; repeat (array_length(_occurrence)) {
		var _item = _occurrence[_o];
		if (_temp) || ((_o > 0) && (_item.holder_ok)) {
			_root = __gmlc_reuse_replace_at(_root, _item.path, 0, __gmlc_opt_local(_name, _item.node.span));
			if (_o > 0) _count++;
		}
	_o++}
	if (_temp) {
		var _first = _occurrence[0];
		var _decl = __gmlc_opt_var(_name, _first.node, _first.hoist.span);
		var _list = __gmlc_reuse_at(_root, _first.hoist.list_path);
		var _copy = variable_clone(_list, 0);
		var _body = variable_clone(_list.body, 0);
		array_insert(_body, _first.hoist.index, _decl);
		_copy.body = _body;
		_root = __gmlc_reuse_replace_at(_root, _first.hoist.list_path, 0, _copy);
		if (_s.options.temps != undefined) _s.cx.stats[$ _s.options.temps]++;
	}
	_s.cx.stats[$ _s.options.eliminated] += _count;
	return _root;
}
#endregion
