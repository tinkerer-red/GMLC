#region jsDoc
/// @func    GMLC_Opt_BuiltinGetterToAccessor()
/// @desc    Writes a call of a long-form struct built-in as the accessor that does the same thing:
///          `variable_struct_get(_s, "hp")` becomes `_s[$ "hp"]` and the statement `variable_struct_set(_s, "hp", 5);`
///          becomes `_s[$ "hp"] = 5;`. Both only for a struct local that is proven to hold a struct and a key that is
///          a string literal or a local that is proven to hold a string. Rewrites:
///          `variable_struct_get(struct, key)` to `struct[$ key]`: for a struct and a string both give the field's
///          value or `undefined` when the struct has no such field, and the accessor with a literal key is hashed
///          when compiling;
///          `variable_struct_set(struct, key, value);` as a statement to `struct[$ key] = value;`: both create the
///          field or overwrite it, the statement discards the result, and the struct and the key are locals or
///          literals, so only the value can have effects and its order against them does not matter.
///          Left alone, because their results or errors for a missing key, an invalid handle or an index out of range
///          may differ: `ds_map_find_value`, `ds_list_find_value`, `ds_grid_get` and `array_get`.
/// @returns {Struct.GMLC_Opt_BuiltinGetterToAccessor}
#endregion
function GMLC_Opt_BuiltinGetterToAccessor() : GMLC_OptimizerPass("builtin-getter-to-accessor") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The node to put in the place of _node, or undefined to keep it.
	/// @self    GMLC_Opt_BuiltinGetterToAccessor
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _kinds = __gmlc_opt_string_kinds(_node);
		if (!__anyStruct(_kinds)) return undefined;
		return __rewrite(_node, _kinds, _cx, true);
	};
	#endregion

	#region Private
	#region Rewrite
	#region jsDoc
	/// @func    __rewrite(_node, _kinds, _cx, _isRoot)
	/// @desc    A node with every call that has an accessor written as the accessor, inner ones first, or undefined
	///          when it holds none. Nested functions are left alone.
	/// @self    GMLC_Opt_BuiltinGetterToAccessor
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct}         _kinds  : What is proven about the function's locals
	/// @param   {Struct}         _cx     : The pass context
	/// @param   {Bool}           _isRoot : Whether the node is the function itself
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __rewrite = function(_node, _kinds, _cx, _isRoot) {
		if (!_isRoot) && ((__gmlc_opt_is_function(_node)) || (_cx.optimizer.__isNoOp(_node))) return undefined;
		var _slots = _node.childSlots();
		var _news = undefined;
		var _i = 0; repeat (array_length(_slots)) {
			var _new = __rewrite(_slots[_i].node, _kinds, _cx, false);
			if (_new != undefined) {
				if (_news == undefined) _news = array_create(array_length(_slots), undefined);
				_news[_i] = _new;
			}
		_i++}
		var _result = (_news != undefined) ? __gmlc_opt_rebuilt(_node, _slots, _news) : undefined;
		var _accessor = __accessor(_result ?? _node, _kinds);
		if (_accessor != undefined) {
			if (_accessor.kind == __GMLC_NodeKind_ExprStmt) {
				_cx.stats[$ "setters_rewritten"]++;
			}
			else {
				_cx.stats[$ "getters_rewritten"]++;
			}
		}
		return _accessor ?? _result;
	};

	#region jsDoc
	/// @func    __accessor(_node, _kinds)
	/// @desc    The accessor that does what a call does, or undefined when the node is not a call that has one or the
	///          struct or the key is not proven.
	/// @self    GMLC_Opt_BuiltinGetterToAccessor
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Struct}         _kinds : What is proven about the function's locals
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __accessor = function(_node, _kinds) {
		if (_node.kind == __GMLC_NodeKind_ExprStmt) {
			var _call = _node.expression;
			if (__gmlc_opt_builtin_call(_call) == "variable_struct_set") && (array_length(_call.args) == 3) && (__proven(_call.args[0], _call.args[1], _kinds)) && (_call.args[2].kind != __GMLC_NodeKind_Empty) {
				var _target = new ASTIndex(_call.span, "Struct", _call.args[0], [_call.args[1]]);
				var _stmt = variable_clone(_node, 0);
				_stmt.expression = new ASTAssign(_call.span, "=", _target, _call.args[2]);
				return _stmt;
			}
			return undefined;
		}
		if (__gmlc_opt_builtin_call(_node) == "variable_struct_get") && (array_length(_node.args) == 2) && (__proven(_node.args[0], _node.args[1], _kinds)) {
			return new ASTIndex(_node.span, "Struct", _node.args[0], [_node.args[1]]);
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __proven(_struct, _key, _kinds)
	/// @desc    Whether an argument is a local proven to hold a struct and another is a string literal or a local
	///          proven to hold a string.
	/// @self    GMLC_Opt_BuiltinGetterToAccessor
	/// @param   {Struct.ASTNode} _struct : The struct argument
	/// @param   {Struct.ASTNode} _key    : The key argument
	/// @param   {Struct}         _kinds  : What is proven about the function's locals
	/// @returns {Bool}
	#endregion
	static __proven = function(_struct, _key, _kinds) {
		if (!__gmlc_opt_is_local(_struct)) || (_kinds[$ _struct.name] != "struct") return false;
		if (_key.kind == __GMLC_NodeKind_Literal) return _key.ty == "string";
		return __gmlc_opt_is_local(_key) && (_kinds[$ _key.name] == "string");
	};

	#endregion

	#region Proven types
	#region jsDoc
	/// @func    __anyStruct(_kinds)
	/// @desc    Whether any local is proven to hold a struct.
	/// @self    GMLC_Opt_BuiltinGetterToAccessor
	/// @param   {Struct} _kinds : What is proven about the locals
	/// @returns {Bool}
	#endregion
	static __anyStruct = function(_kinds) {
		var _names = struct_get_names(_kinds);
		var _i = 0; repeat (array_length(_names)) {
			if (_kinds[$ _names[_i]] == "struct") return true;
		_i++}
		return false;
	};
	#endregion
	#endregion
}
