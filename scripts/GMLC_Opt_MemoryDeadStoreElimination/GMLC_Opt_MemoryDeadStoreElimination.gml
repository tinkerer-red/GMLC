#region jsDoc
/// @func    GMLC_Opt_MemoryDeadStoreElimination()
/// @desc    Removes a store to an instance variable that the same variable overwrites before anything can read it:
///          `state = ST_IDLE; timer = 0; state = ST_ATTACK;` becomes `timer = 0; state = ST_ATTACK;`. Both stores
///          must be plain assignments of values that cannot throw or have effects, and between them only assignments
///          of such values to locals or to other instance variables may stand; a call, a read of an instance
///          variable or any control flow ends the search.
/// @returns {Struct.GMLC_Opt_MemoryDeadStoreElimination}
#endregion
function GMLC_Opt_MemoryDeadStoreElimination() : GMLC_OptimizerPass("memory-dead-store-elimination") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The node to put in the place of _node, or undefined to keep it.
	/// @self    GMLC_Opt_MemoryDeadStoreElimination
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		return __gmlc_opt_rewrite_lists(_node, _cx, true, method(self, __list));
	};
	#endregion

	#region Private
	#region Rewrite
	#region jsDoc
	/// @func    __list(_stmts, _cx)
	/// @desc    Drops every store to an instance variable that a later store to the same variable overwrites with
	///          nothing but harmless statements between them.
	/// @self    GMLC_Opt_MemoryDeadStoreElimination
	/// @param   {Array<Struct.ASTNode>} _stmts : A statement list
	/// @param   {Struct}                _cx    : The pass context
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list
	#endregion
	static __list = function(_stmts, _cx) {
		var _count = array_length(_stmts);
		var _dead = undefined;
		var _i = 0; repeat (_count) {
			var _name = __storeName(_stmts[_i], _cx);
			if (_name != undefined) {
				var _j = _i + 1;
				while (_j < _count) {
					var _next = _stmts[_j];
					var _other = __storeName(_next, _cx);
					if (_other == _name) {
						if (_dead == undefined) _dead = array_create(_count, false);
						_dead[_i] = true;
						_cx.stats[$ "stores_removed"]++;
						break;
					}
					if (_other == undefined) && (!__simple(_next, _cx)) break;
					// a built-in's setter can change others: `speed = 4; hspeed = 3; speed = 6;` needs the first store
					if (_other != undefined) && (__gmlc_opt_builtin_variable(_other) != undefined) break;
					_j++;
				}
			}
		_i++}
		if (_dead == undefined) return undefined;
		var _out = [];
		var _k = 0; repeat (_count) {
			if (!_dead[_k]) array_push(_out, _stmts[_k]);
		_k++}
		return _out;
	};
	#endregion

	#region Questions
	#region jsDoc
	/// @func    __storeName(_stmt, _cx)
	/// @desc    The instance variable a statement stores to with a plain assignment of a harmless value, or undefined.
	/// @self    GMLC_Opt_MemoryDeadStoreElimination
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {String|Undefined}
	#endregion
	static __storeName = function(_stmt, _cx) {
		if (_stmt.kind != __GMLC_NodeKind_ExprStmt) return undefined;
		var _assign = _stmt.expression;
		if (_assign.kind != __GMLC_NodeKind_Assign) || (_assign.op != "=") return undefined;
		var _target = _assign.target;
		var _name = undefined;
		if (_target.kind == __GMLC_NodeKind_Identifier) {
			if (_target.symbol != undefined) && (_target.symbol.kind == "Self") _name = _target.name;
		}
		else if (_target.kind == __GMLC_NodeKind_Index) && (_target.accessor == "Dot") && (_target.object.kind == __GMLC_NodeKind_Identifier) && (_target.object.name == "self") {
			_name = _target.member;
		}
		if (_name == undefined) || (!__harmless(_assign.value)) || (_cx.optimizer.__isNoOp(_stmt)) return undefined;
		return _name;
	};

	#region jsDoc
	/// @func    __simple(_stmt, _cx)
	/// @desc    Whether a statement only assigns harmless values to locals: it cannot read or change an instance
	///          variable, throw or call anything.
	/// @self    GMLC_Opt_MemoryDeadStoreElimination
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Bool}
	#endregion
	static __simple = function(_stmt, _cx) {
		if (_cx.optimizer.__isNoOp(_stmt)) return false;
		switch (_stmt.kind) {
			case __GMLC_NodeKind_ExprStmt: {
				var _assign = _stmt.expression;
				return (_assign.kind == __GMLC_NodeKind_Assign) && (_assign.op == "=") && (__gmlc_opt_is_local(_assign.target)) && (__harmless(_assign.value));
			}
			case __GMLC_NodeKind_VarDeclList: {
				var _i = 0; repeat (array_length(_stmt.declarations)) {
					var _init = _stmt.declarations[_i].init;
					if (_init != undefined) && (!__harmless(_init)) return false;
				_i++}
				return true;
			}
		}
		return false;
	};

	#region jsDoc
	/// @func    __harmless(_node)
	/// @desc    Whether evaluating an expression neither throws nor has effects nor reads an instance variable, and it
	///          names no asset.
	/// @self    GMLC_Opt_MemoryDeadStoreElimination
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __harmless = function(_node) {
		return (!__gmlc_opt_may_throw(_node)) && (!__gmlc_opt_has_effects(_node)) && (!__gmlc_opt_has_asset_symbol(_node));
	};

	#endregion
	#endregion
}
