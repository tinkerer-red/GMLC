#region jsDoc
/// @func    GMLC_Opt_LoopStoreSinking()
/// @desc    `loop-store-sinking`: an instance variable a loop updates (`hp -= 1`, `hp *= 0.5`, `hp++`) lives in a
///          local while the loop runs and is stored back once after it.
///          `repeat (4) { hp -= _dmg; if (hp <= 0) { break; } }` becomes
///          `var __t = hp; repeat (4) { __t -= _dmg; if (__t <= 0) { break; } } hp = __t;`.
///          The loop holds no call, no `return`, no `exit` and nothing that can throw once the variable has been
///          written, and the variable is read first thing, so reading it ahead of the loop throws exactly when the
///          loop would have.
/// @returns {Struct.GMLC_Opt_LoopStoreSinking}
#endregion
function GMLC_Opt_LoopStoreSinking() : GMLC_OptimizerPass("loop-store-sinking") constructor {
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    A copy of the function with the instance variables of its loops kept in locals, or undefined when
	///          there is none.
	/// @self    GMLC_Opt_LoopStoreSinking
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _st = { cx: _cx, apply: false, root: _node, defs: [], kinds: undefined };
		if (!__gmlc_opt_walk_statement_lists(_node, _st, true, method(self, __rewrite))) return undefined;
		var _copy = __gmlc_opt_clone(_node);
		_st.apply = true;
		array_resize(_st.defs, 0);
		__gmlc_opt_walk_statement_lists(_copy, _st, true, method(self, __rewrite));
		return _copy;
	};
	#endregion

	#region Loops
	#region jsDoc
	/// @func    __rewrite(_loop, _st, _body, _i)
	/// @desc    The statements that load an instance variable into a local, run the loop on the local and store it
	///          back, or undefined when the loop does not qualify. Without `_st.apply` an array says it qualifies.
	/// @self    GMLC_Opt_LoopStoreSinking
	/// @param   {Struct.ASTNode}        _loop : The loop
	/// @param   {Struct}                _st   : The walk state
	/// @param   {Array<Struct.ASTNode>} _body : The statement list the loop is in
	/// @param   {Real}                  _i    : The loop's place in it
	/// @returns {Array<Struct.ASTNode>|Undefined}
	#endregion
	static __rewrite = function(_loop, _st, _body, _i) {
		var _kind = _loop.kind;
		if (_kind != __GMLC_NodeKind_For) && (_kind != __GMLC_NodeKind_While) && (_kind != __GMLC_NodeKind_Repeat) && (_kind != __GMLC_NodeKind_DoUntil) return undefined;
		var _names = [];
		__selfVars(_loop, _names);
		if (array_length(_names) != 1) return undefined;
		if (__gmlc_opt_has_function(_loop)) || (_st.cx.optimizer.__containsNoOp(_loop)) || (__gmlc_opt_has_try(_st.root, true)) return undefined;
		if (_st.kinds == undefined) _st.kinds = __gmlc_opt_local_kinds(_st.root, _st.cx);
		var _ctx = { t: _names[0], extra: [], writes: 0 };
		if (!__shapeOk(_loop, _st, _ctx)) || (_ctx.writes == 0) || (!__enters(_loop, _ctx.t)) return undefined;
		if (!_st.apply) return [];
		_st.cx.stats[$ "sunk"]++;
		var _span = _loop.span;
		var _temp = _st.cx.optimizer.newTemporary(_st.cx);
		var _field = __firstSelf(_loop, _ctx.t);
		var _load = __gmlc_opt_var(_temp, __gmlc_opt_clone(_field), _span);
		var _store = new ASTExprStmt(_span, new ASTAssign(_span, "=", __gmlc_opt_clone(_field), __gmlc_opt_local(_temp, _span)));
		__replaceSelf(_loop, _ctx.t, _temp);
		return [_load, _loop, _store];
	};

	#region jsDoc
	/// @func    __shapeOk(_loop, _st, _ctx)
	/// @desc    Whether the header and the body of a loop hold nothing but what the pass can reason about: updates
	///          of locals and of the one instance variable, and `if`, `break` and `continue`, with values that cannot
	///          throw. Counts the writes to the instance variable in `_ctx.writes`.
	/// @self    GMLC_Opt_LoopStoreSinking
	/// @param   {Struct.ASTNode} _loop : The loop
	/// @param   {Struct}         _st   : The walk state
	/// @param   {Struct}         _ctx  : {t, extra, writes}
	/// @returns {Bool}
	#endregion
	static __shapeOk = function(_loop, _st, _ctx) {
		switch (_loop.kind) {
			case __GMLC_NodeKind_For: {
				if (_loop.init != undefined) && (!__stmtOk(_loop.init, _st, _ctx)) return false;
				if (_loop.test == undefined) || (!__safe(_loop.test, _st, _ctx)) return false;
				if (_loop.update != undefined) && (!__stmtOk(_loop.update, _st, _ctx)) return false;
			break;}
			case __GMLC_NodeKind_While: if (!__safe(_loop.test, _st, _ctx)) return false; break;
			case __GMLC_NodeKind_Repeat: if (!__safe(_loop.count, _st, _ctx)) return false; break;
		}
		if (!__blockOk(_loop.body, _st, _ctx, true)) return false;
		return (_loop.kind != __GMLC_NodeKind_DoUntil) || (__safe(_loop.test, _st, _ctx));
	};

	#region jsDoc
	/// @func    __blockOk(_block, _st, _ctx, _top)
	/// @desc    Whether every statement of a block is one the pass can reason about. The locals a statement of the
	///          loop body itself gives a value can be read by the ones after it.
	/// @self    GMLC_Opt_LoopStoreSinking
	/// @param   {Struct.ASTNode} _block : The block
	/// @param   {Struct}         _st    : The walk state
	/// @param   {Struct}         _ctx   : {t, extra, writes}
	/// @param   {Bool}           _top   : Whether the block is the loop body
	/// @returns {Bool}
	#endregion
	static __blockOk = function(_block, _st, _ctx, _top) {
		var _mark = array_length(_ctx.extra);
		var _s = 0; repeat (array_length(_block.body)) {
			if (!__stmtOk(_block.body[_s], _st, _ctx)) return false;
		_s++}
		if (!_top) array_resize(_ctx.extra, _mark);
		return true;
	};

	#region jsDoc
	/// @func    __stmtOk(_stmt, _st, _ctx)
	/// @desc    Whether a statement is one the pass can reason about; a local it gives a value is added to
	///          `_ctx.extra`.
	/// @self    GMLC_Opt_LoopStoreSinking
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @param   {Struct}         _st   : The walk state
	/// @param   {Struct}         _ctx  : {t, extra, writes}
	/// @returns {Bool}
	#endregion
	static __stmtOk = function(_stmt, _st, _ctx) {
		switch (_stmt.kind) {
			case __GMLC_NodeKind_Break:
			case __GMLC_NodeKind_Continue:
			return true;
			case __GMLC_NodeKind_Block: return __blockOk(_stmt, _st, _ctx, false);
			case __GMLC_NodeKind_If: {
				if (!__safe(_stmt.test, _st, _ctx)) || (!__blockOk(_stmt.consequent, _st, _ctx, false)) return false;
				return (_stmt.alternate == undefined) || (__blockOk(_stmt.alternate, _st, _ctx, false));
			}
			case __GMLC_NodeKind_VarDeclList: {
				var _d = 0; repeat (array_length(_stmt.declarations)) {
					var _decl = _stmt.declarations[_d];
					if (_decl.init == undefined) || (!__safe(_decl.init, _st, _ctx)) return false;
					array_push(_ctx.extra, _decl.target.name);
				_d++}
				return true;
			}
			case __GMLC_NodeKind_ExprStmt: {
				var _expr = _stmt.expression;
				if (_expr.kind == __GMLC_NodeKind_Assign) {
					if (!__safe(_expr.value, _st, _ctx)) return false;
					if (__isSelf(_expr.target, _ctx.t)) {
						if (_expr.op == "=") || (_expr.op == "??=") || (_expr.op == "%=") || (_expr.op == "&=") || (_expr.op == "|=") || (_expr.op == "^=") return false;
						_ctx.writes++;
						return true;
					}
					if (!__gmlc_opt_is_local(_expr.target)) return false;
					if (_expr.op == "=") {
						array_push(_ctx.extra, _expr.target.name);
						return true;
					}
					if (_expr.op == "??=") || (_expr.op == "%=") || (_expr.op == "&=") || (_expr.op == "|=") || (_expr.op == "^=") return false;
					return __readable(_expr.target, _st, _ctx);
				}
				if (_expr.kind == __GMLC_NodeKind_Update) {
					var _arg = _expr[$ "argument"];
					if (__isSelf(_arg, _ctx.t)) {
						_ctx.writes++;
						return true;
					}
					return __gmlc_opt_is_local(_arg) && __readable(_arg, _st, _ctx);
				}
				return false;
			}
		}
		return false;
	};

	#region jsDoc
	/// @func    __readable(_node, _st, _ctx)
	/// @desc    Whether a local holds a number or boolean and has a value when it is read.
	/// @self    GMLC_Opt_LoopStoreSinking
	/// @param   {Struct.ASTNode} _node : The local
	/// @param   {Struct}         _st   : The walk state
	/// @param   {Struct}         _ctx  : {t, extra, writes}
	/// @returns {Bool}
	#endregion
	static __readable = function(_node, _st, _ctx) {
		return ((_st.kinds[$ _node.name] ?? 0) >= 1) && (array_contains(_st.defs, _node.name) || array_contains(_ctx.extra, _node.name));
	};

	#region jsDoc
	/// @func    __safe(_node, _st, _ctx)
	/// @desc    Whether nothing in an expression can throw once the instance variable holds a number: literals,
	///          the instance variable, readable locals, arithmetic, comparisons and logic of those, and calls of a few
	///          numeric built-ins.
	/// @self    GMLC_Opt_LoopStoreSinking
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _st   : The walk state
	/// @param   {Struct}         _ctx  : {t, extra, writes}
	/// @returns {Bool}
	#endregion
	static __safe = function(_node, _st, _ctx) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: return (_node.ty == "real") || (_node.ty == "int64") || (_node.ty == "bool");
			case __GMLC_NodeKind_Identifier: return __isSelf(_node, _ctx.t) || (__gmlc_opt_is_local(_node) ? __readable(_node, _st, _ctx) : (__gmlc_opt_constant_level(_node, _st.cx) == 1));
			case __GMLC_NodeKind_Unary: return __safe(_node[$ "argument"], _st, _ctx);
			case __GMLC_NodeKind_Binary: {
				switch (_node.op) {
					case "+": case "-": case "*": case "/": case "==": case "!=": case "<": case "<=": case ">": case ">=":
					return __safe(_node.left, _st, _ctx) && __safe(_node.right, _st, _ctx);
				}
				return false;
			}
			case __GMLC_NodeKind_Logical: return __safe(_node.left, _st, _ctx) && __safe(_node.right, _st, _ctx);
			case __GMLC_NodeKind_Call: {
				switch (__gmlc_opt_builtin_call(_node)) {
					case "abs": case "sign": case "floor": case "ceil": case "round": case "clamp": case "sqr": case "frac": {
						var _a = 0; repeat (array_length(_node.args)) {
							if (!__safe(_node.args[_a], _st, _ctx)) return false;
						_a++}
						return true;
					}
				}
				return false;
			}
		}
		return false;
	};

	#region jsDoc
	/// @func    __enters(_loop, _t)
	/// @desc    Whether the instance variable is read before anything else can end the loop, and the loop is sure to
	///          start: its test reads the variable first, or the loop runs at least once and its first statement
	///          updates the variable.
	/// @self    GMLC_Opt_LoopStoreSinking
	/// @param   {Struct.ASTNode} _loop : The loop
	/// @param   {String}         _t    : The instance variable
	/// @returns {Bool}
	#endregion
	static __enters = function(_loop, _t) {
		var _kind = _loop.kind;
		if (_kind == __GMLC_NodeKind_For) || (_kind == __GMLC_NodeKind_While) {
			var _test = _loop.test;
			if (_test.kind == __GMLC_NodeKind_Binary) {
				switch (_test.op) {
					case "<": case "<=": case ">": case ">=": case "==": case "!=":
					if (__isSelf(_test.left, _t)) || (__isSelf(_test.right, _t)) return true;
				}
			}
		}
		var _stmts = _loop.body.body;
		if (array_length(_stmts) == 0) || (_stmts[0].kind != __GMLC_NodeKind_ExprStmt) return false;
		var _first = _stmts[0].expression;
		var _touches = false;
		if (_first.kind == __GMLC_NodeKind_Assign) {
			_touches = __isSelf(_first.target, _t);
		}
		else if (_first.kind == __GMLC_NodeKind_Update) {
			_touches = __isSelf(_first[$ "argument"], _t);
		}
		if (!_touches) return false;
		switch (_kind) {
			case __GMLC_NodeKind_DoUntil: return true;
			case __GMLC_NodeKind_Repeat: return (_loop.count.kind == __GMLC_NodeKind_Literal) && (_loop.count.ty == "real") && (__gmlc_opt_whole_text(_loop.count.lexeme)) && (real(_loop.count.lexeme) >= 1);
			case __GMLC_NodeKind_For: {
				var _init = _loop.init;
				if (_init == undefined) || (_init.kind != __GMLC_NodeKind_VarDeclList) || (array_length(_init.declarations) != 1) return false;
				var _start = _init.declarations[0].init;
				var _forTest = _loop.test;
				if (_start == undefined) || (_start.kind != __GMLC_NodeKind_Literal) || (_start.ty != "real") || (!__gmlc_opt_whole_text(_start.lexeme)) return false;
				if (_forTest.kind != __GMLC_NodeKind_Binary) || (_forTest.right.kind != __GMLC_NodeKind_Literal) || (_forTest.right.ty != "real") || (!__gmlc_opt_whole_text(_forTest.right.lexeme)) return false;
				if (!__gmlc_opt_is_local(_forTest.left)) || (_forTest.left.name != _init.declarations[0].target.name) return false;
				if (_forTest.op == "<") return real(_start.lexeme) < real(_forTest.right.lexeme);
				if (_forTest.op == "<=") return real(_start.lexeme) <= real(_forTest.right.lexeme);
				return false;
			}
		}
		return false;
	};

	#region jsDoc
	/// @func    __isSelf(_node, _t)
	/// @desc    Whether a node is the instance variable.
	/// @self    GMLC_Opt_LoopStoreSinking
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _t    : The instance variable
	/// @returns {Bool}
	#endregion
	static __isSelf = function(_node, _t) {
		return (_node.kind == __GMLC_NodeKind_Identifier) && (_node.name == _t) && (_node.symbol != undefined) && (_node.symbol.kind == "Self");
	};

	#region jsDoc
	/// @func    __selfVars(_node, _names)
	/// @desc    Collects the names of the instance variables named under a node, nested functions left out.
	/// @self    GMLC_Opt_LoopStoreSinking
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Array<String>}  _names : The names so far
	#endregion
	static __selfVars = function(_node, _names) {
		if (_node.kind == __GMLC_NodeKind_Identifier) {
			if (_node.symbol != undefined) && (_node.symbol.kind == "Self") && (!array_contains(_names, _node.name)) array_push(_names, _node.name);
			return;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__gmlc_opt_is_function(_child)) __selfVars(_child, _names);
				}
			_i++}
		_field_index++}
	};

	#region jsDoc
	/// @func    __firstSelf(_node, _t)
	/// @desc    The first mention of the instance variable under a node.
	/// @self    GMLC_Opt_LoopStoreSinking
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _t    : The instance variable
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __firstSelf = function(_node, _t) {
		if (__isSelf(_node, _t)) return _node;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					var _found = __firstSelf(_child, _t);
					if (_found != undefined) return _found;
				}
			_i++}
		_field_index++}
		return undefined;
	};

	#region jsDoc
	/// @func    __replaceSelf(_node, _t, _temp)
	/// @desc    Puts a local in place of every mention of the instance variable under a node.
	/// @self    GMLC_Opt_LoopStoreSinking
	/// @param   {Struct.ASTNode} _node : The node, changed in place
	/// @param   {String}         _t    : The instance variable
	/// @param   {String}         _temp : The local
	#endregion
	static __replaceSelf = function(_node, _t, _temp) {
		var _slots = _node.childSlots();
		var _s = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_s];
			if (__isSelf(_slot.node, _t)) {
				var _local = __gmlc_opt_local(_temp, _slot.node.span);
				if (_slot.index == undefined) {
					_node[$ _slot.key] = _local;
				}
				else {
					_node[$ _slot.key][_slot.index] = _local;
				}
			}
			else {
				__replaceSelf(_slot.node, _t, _temp);
			}
		_s++}
	};

	#endregion

}
