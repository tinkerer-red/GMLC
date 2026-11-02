#region jsDoc
/// @func    GMLC_Opt_RedundantCallElim()
/// @desc    The `redundant-call-elim` optimizer pass. A call of a pure built-in, of a built-in that only reads state,
///          or of a function of the file that only reads its parameters, made again with the same arguments while
///          nothing it reads has changed, takes the result of the first call from a local that holds it or from a
///          new temporary: `var _n = string_length(s); if (string_length(s) > 9) { ... }` becomes
///          `if (_n > 9) { ... }`. A call that makes a new array or struct, or that is random, is never merged.
///          The pass looks at the whole file at once, because the purity of a function of the file is a fact
///          about the file.
/// @returns {Struct.GMLC_Opt_RedundantCallElim}
#endregion
function GMLC_Opt_RedundantCallElim() : GMLC_OptimizerPass("redundant-call-elim") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The file with its repeated calls reused, or undefined when none is. It acts on the file's own unit
	///          only and then covers every function in it.
	/// @self    GMLC_Opt_RedundantCallElim
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (_cx.unit.fn_id != 0) return undefined;
		var _options = { calls_only: true, user_pure: __pureFunctions(_node), eliminated: "calls_eliminated", temps: undefined };
		var _paths = [];
		__functionPaths(_node, [], _paths);
		var _root = _node;
		var _changed = false;
		// the temporaries made inside a function belong to that function: they are its locals, numbered as its own
		var _made = [];
		var _own = _cx.unit;
		// the functions inside others first, so that the paths to the rest stay as they were found
		var _i = array_length(_paths) - 1; repeat (array_length(_paths)) {
			var _function = __gmlc_reuse_at(_root, _paths[_i]);
			if (!_cx.optimizer.__isNoOp(_function)) && (_function.fn_id != undefined) {
				var _before = array_length(_cx.new_locals);
				_cx.unit = { fn_id: _function.fn_id, name: _own.name, root: _own.root };
				var _new = __gmlc_reuse_unit(_function, _cx, _options);
				_cx.unit = _own;
				var _l = _before; repeat (array_length(_cx.new_locals) - _before) {
					array_push(_made, { fn_id: _function.fn_id, name: _cx.new_locals[_l] });
				_l++}
				array_resize(_cx.new_locals, _before);
				if (_new != undefined) {
					_root = __gmlc_reuse_replace_at(_root, _paths[_i], 0, _new);
					_changed = true;
				}
			}
		_i--}
		// the manager lists them among their functions' locals when the result is kept
		_cx.nested_locals = array_concat(_cx.nested_locals, _made);
		var _script = __gmlc_reuse_unit(_root, _cx, _options);
		if (_script != undefined) {
			_root = _script;
			_changed = true;
		}
		return _changed ? _root : undefined;
	};
	#endregion

	#region Private
	#region jsDoc
	/// @func    __functionPaths(_node, _path, _out)
	/// @desc    The paths to every function node under a node, in the order the nodes are met.
	/// @self    GMLC_Opt_RedundantCallElim
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Array<Real>}    _path : The path to the node
	/// @param   {Array<Array>}   _out  : The paths found
	#endregion
	static __functionPaths = function(_node, _path, _out) {
		var _children = _node.children();
		var _i = 0; repeat (array_length(_children)) {
			var _child = _children[_i];
			array_push(_path, _i);
			if (__gmlc_opt_is_function(_child)) array_push(_out, variable_clone(_path));
			__functionPaths(_child, _path, _out);
			array_pop(_path);
		_i++}
	};

	#region jsDoc
	/// @func    __pureFunctions(_script)
	/// @desc    The functions declared once at the top of a file that are pure: they read only their parameters and
	///          locals, call only pure built-ins and pure functions found before them, make no array or struct and
	///          write nothing but their locals. A function that calls itself, directly or not, is not found.
	/// @self    GMLC_Opt_RedundantCallElim
	/// @param   {Struct.ASTScript} _script : The file
	/// @returns {Struct} Name to true
	#endregion
	static __pureFunctions = function(_script) {
		var _decls = {};
		var _seen = {};
		var _body = _script.body;
		var _i = 0; repeat (array_length(_body)) {
			var _stmt = _body[_i];
			if (_stmt.kind == __GMLC_NodeKind_FunctionDecl) {
				if (_seen[$ _stmt.name] == true) {
					struct_remove(_decls, _stmt.name);
				}
				else {
					_seen[$ _stmt.name] = true;
					_decls[$ _stmt.name] = _stmt;
				}
			}
		_i++}
		var _pure = {};
		var _grown = true;
		while (_grown) {
			_grown = false;
			var _names = struct_get_names(_decls);
			var _n = 0; repeat (array_length(_names)) {
				if (_pure[$ _names[_n]] != true) && (__pureFunction(_decls[$ _names[_n]], _pure)) {
					_pure[$ _names[_n]] = true;
					_grown = true;
				}
			_n++}
		}
		return _pure;
	};

	#region jsDoc
	/// @func    __pureFunction(_function, _pure)
	/// @desc    Whether a function is pure, given the functions already known to be.
	/// @self    GMLC_Opt_RedundantCallElim
	/// @param   {Struct.ASTFunctionDecl} _function : The function
	/// @param   {Struct}                 _pure     : Name to true for the pure functions found so far
	/// @returns {Bool}
	#endregion
	static __pureFunction = function(_function, _pure) {
		var _params = _function.params;
		var _p = 0; repeat (array_length(_params)) {
			if (_params[_p][$ "default"] != undefined) return false;
		_p++}
		return __pureNode(_function.body, _pure);
	};

	#region jsDoc
	/// @func    __pureNode(_node, _pure)
	/// @desc    Whether everything under a node is allowed in a pure function.
	/// @self    GMLC_Opt_RedundantCallElim
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _pure : Name to true for the pure functions found so far
	/// @returns {Bool}
	#endregion
	static __pureNode = function(_node, _pure) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: case __GMLC_NodeKind_Break: case __GMLC_NodeKind_Continue: case __GMLC_NodeKind_Exit:
			case __GMLC_NodeKind_Empty:
			return true;
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				if (_symbol == undefined) return false;
				switch (_symbol.kind) {
					case "Local": case "BuiltinConstant": case "Enum": case "Macro":
					return true;
				}
				return false;
			}
			case __GMLC_NodeKind_Call: {
				var _callee = _node.callee;
				if (_callee.kind != __GMLC_NodeKind_Identifier) || (_callee.symbol == undefined) || (_callee.symbol.kind == "Local") return false;
				if (_pure[$ _callee.name] != true) {
					if (_callee.symbol.kind != "BuiltinFunction") return false;
					var _effects = __GmlcDataEffects();
					var _entry = _effects[$ _callee.name];
					if (_entry == undefined) || (_entry.class != "pure") || (_entry.allocates) || (_entry.nondeterministic) return false;
				}
				var _a = 0; repeat (array_length(_node.args)) {
					if (!__pureNode(_node.args[_a], _pure)) return false;
				_a++}
				return true;
			}
			case __GMLC_NodeKind_Assign:
			if (!__gmlc_opt_is_local(_node.target)) return false;
			break;
			case __GMLC_NodeKind_Update:
			if (!__gmlc_opt_is_local(_node[$ "argument"])) return false;
			break;
			case __GMLC_NodeKind_Binary: case __GMLC_NodeKind_Unary: case __GMLC_NodeKind_Logical: case __GMLC_NodeKind_Nullish:
			case __GMLC_NodeKind_Conditional: case __GMLC_NodeKind_ExprStmt: case __GMLC_NodeKind_Return: case __GMLC_NodeKind_VarDeclList:
			case __GMLC_NodeKind_VarDecl: case __GMLC_NodeKind_Block: case __GMLC_NodeKind_If: case __GMLC_NodeKind_For:
			case __GMLC_NodeKind_While: case __GMLC_NodeKind_Repeat: case __GMLC_NodeKind_DoUntil:
			break;
			default:
			return false;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__pureNode(_child, _pure)) return false;
				}
			_i++}
		_field_index++}
		return true;
	};
	#endregion
}
