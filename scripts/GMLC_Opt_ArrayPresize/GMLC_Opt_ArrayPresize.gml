#region jsDoc
/// @func    GMLC_Opt_ArrayPresize()
/// @desc    Gives an array that a counted loop fills with one `array_push` per iteration its size up front and
///          stores by index: `var _a = []; for (var _i = 0; _i < 100; _i++) array_push(_a, _i * 2);` becomes
///          `var _a = array_create(100); for (var _i = 0; _i < 100; _i++) _a[_i] = _i * 2;`. It applies only when
///          the array is not used anywhere else in the loop, nothing leaves the loop early, the function has no
///          `try`, and the count is a literal or `array_length` of a local the loop cannot change.
/// @returns {Struct.GMLC_Opt_ArrayPresize}
#endregion
function GMLC_Opt_ArrayPresize() : GMLC_OptimizerPass("array-presize") constructor {
	#region Config
	static __minimum_count = 4;
	static __maximum_count = 65536;
	#endregion

	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The node to put in the place of _node, or undefined to keep it.
	/// @self    GMLC_Opt_ArrayPresize
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (!_cx.env.isFunction("array_create")) || (!_cx.env.isFunction("array_push")) return undefined;
		if (__gmlc_opt_contains_kind(_node, __GMLC_NodeKind_Try, true)) return undefined;
		return __gmlc_opt_rewrite_lists(_node, _cx, true, method(self, __list));
	};
	#endregion

	#region Private
	#region Rewrite
	#region jsDoc
	/// @func    __list(_stmts, _cx)
	/// @desc    Presizes the array of every `var _a = [];` that a counted loop right after it fills.
	/// @self    GMLC_Opt_ArrayPresize
	/// @param   {Array<Struct.ASTNode>} _stmts : A statement list
	/// @param   {Struct}                _cx    : The pass context
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list
	#endregion
	static __list = function(_stmts, _cx) {
		var _out = undefined;
		var _count = array_length(_stmts);
		var _i = 0; repeat (_count - 1) {
			var _result = __presize(_stmts[_i], _stmts[_i + 1], _cx);
			if (_result != undefined) {
				if (_out == undefined) {
					_out = [];
					array_copy(_out, 0, _stmts, 0, _count);
				}
				_out[_i] = _result[0];
				_out[_i + 1] = _result[1];
				_cx.stats[$ "arrays_presized"]++;
			}
		_i++}
		return _out;
	};

	#region jsDoc
	/// @func    __presize(_decl, _loop, _cx)
	/// @desc    The declaration and the loop rewritten, or undefined when the pair does not qualify: the declaration is
	///          `var _a = [];` alone, the loop counts an index from 0 below the count, `_a` appears in the loop only as
	///          the one `array_push(_a, value)` statement of the body, nothing in the loop jumps out, and the count is
	///          a whole literal between the minimum and the maximum or `array_length` of a local the loop leaves alone
	///          in a loop whose other statements have no effects.
	/// @self    GMLC_Opt_ArrayPresize
	/// @param   {Struct.ASTNode} _decl : The statement before the loop
	/// @param   {Struct.ASTNode} _loop : The loop
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Array<Struct.ASTNode>|Undefined} [declaration, loop]
	#endregion
	static __presize = function(_decl, _loop, _cx) {
		if (_decl.kind != __GMLC_NodeKind_VarDeclList) || (_loop.kind != __GMLC_NodeKind_For) return undefined;
		if (array_length(_decl.declarations) != 1) return undefined;
		var _var = _decl.declarations[0];
		if (_var.init == undefined) || (_var.init.kind != __GMLC_NodeKind_ArrayLiteral) || (array_length(_var.init.elements) != 0) return undefined;
		if (_cx.optimizer.__isNoOp(_decl)) || (_cx.optimizer.__isNoOp(_loop)) return undefined;
		var _name = _var.target.name;
		var _counted = __gmlc_opt_counted_for(_loop);
		if (_counted == undefined) return undefined;
		var _bound = _counted.bound;
		var _body = _loop.body;
		var _stmts = _body.body;
		var _push = -1;
		var _k = 0; repeat (array_length(_stmts)) {
			if (__isPush(_stmts[_k], _name)) {
				if (_push != -1) return undefined;
				_push = _k;
			}
		_k++}
		if (_push == -1) || (_cx.optimizer.__isNoOp(_stmts[_push])) return undefined;
		if (__gmlc_opt_count_mentions(_loop, _name) != 1) || (__gmlc_opt_has_jump_out(_body)) return undefined;
		var _call = _stmts[_push].expression;
		var _value = _call.args[1];
		var _n = __gmlc_opt_number_value(_bound);
		if (_n != undefined) {
			if (_n != floor(_n)) || (_n < __minimum_count) || (_n > __maximum_count) return undefined;
		}
		else {
			if (__gmlc_opt_builtin_call(_bound) != "array_length") || (array_length(_bound.args) != 1) return undefined;
			var _source = _bound.args[0];
			if (!__gmlc_opt_is_local(_source)) || (_source.name == _name) || (__gmlc_opt_count_mentions(_loop, _source.name) != 1) return undefined;
			if (__gmlc_opt_has_effects(_value)) return undefined;
			var _j = 0; repeat (array_length(_stmts)) {
				if (_j != _push) && (__gmlc_opt_has_effects(_stmts[_j])) return undefined;
			_j++}
		}
		var _optimizer = _cx.optimizer;
		var _init = _var.init;
		var _create = new ASTCall(_init.span, _optimizer.__builtin("array_create", _init.span), [__gmlc_opt_clone(_bound)]);
		var _new_var = variable_clone(_var, 0);
		_new_var.init = _create;
		var _new_decl = variable_clone(_decl, 0);
		_new_decl.declarations = [_new_var];
		var _target = new ASTIndex(_call.span, "Array", _call.args[0], [__gmlc_opt_clone(_loop.test.left)]);
		var _new_push = variable_clone(_stmts[_push], 0);
		_new_push.expression = new ASTAssign(_call.span, "=", _target, _value);
		var _new_stmts = [];
		array_copy(_new_stmts, 0, _stmts, 0, array_length(_stmts));
		_new_stmts[_push] = _new_push;
		var _new_body = variable_clone(_body, 0);
		_new_body.body = _new_stmts;
		var _new_loop = variable_clone(_loop, 0);
		_new_loop.body = _new_body;
		return [_new_decl, _new_loop];
	};
	#endregion

	#region Questions
	#region jsDoc
	/// @func    __isPush(_stmt, _name)
	/// @desc    Whether a statement is `array_push(_name, value);` with one value.
	/// @self    GMLC_Opt_ArrayPresize
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @param   {String}         _name : The local
	/// @returns {Bool}
	#endregion
	static __isPush = function(_stmt, _name) {
		if (_stmt.kind != __GMLC_NodeKind_ExprStmt) return false;
		var _call = _stmt.expression;
		if (__gmlc_opt_builtin_call(_call) != "array_push") || (array_length(_call.args) != 2) return false;
		return __gmlc_opt_is_local(_call.args[0]) && (_call.args[0].name == _name) && (_call.args[1].kind != __GMLC_NodeKind_Empty);
	};

	#endregion
	#endregion
}
