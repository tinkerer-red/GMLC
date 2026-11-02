#region jsDoc
/// @func    GMLC_Opt_ClosedFormLoopEvaluation()
/// @desc    `closed-form-loop-evaluation`: a loop that only counts and accumulates in locals whose values are known
///          before it, with exact whole-number arithmetic, is replaced by the final value of each local it changes.
///          `var _t = 0; for (var _i = 0; _i < 4; _i++) { _t += 3; }` becomes `var _t = 0; _t = 12;`. Every value
///          stays below 2^53, so each step is exact and the result is the one the loop gives.
/// @returns {Struct.GMLC_Opt_ClosedFormLoopEvaluation}
#endregion
function GMLC_Opt_ClosedFormLoopEvaluation() : GMLC_OptimizerPass("closed-form-loop-evaluation") constructor {
	#region Config
	static max_trips = 2048;
	static exact_limit = 9007199254740992;
	#endregion

	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    A copy of the function with its evaluable loops replaced by assignments of their results, or
	///          undefined when there is none.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (_cx.epsilon_set) return undefined;
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
	/// @desc    The assignments that take the place of a loop whose result is known, or undefined when the loop
	///          does not qualify. Without `_st.apply` an array says it qualifies.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Struct.ASTNode}        _loop : The loop
	/// @param   {Struct}                _st   : The walk state
	/// @param   {Array<Struct.ASTNode>} _body : The statement list the loop is in
	/// @param   {Real}                  _i    : The loop's place in it
	/// @returns {Array<Struct.ASTNode>|Undefined}
	#endregion
	static __rewrite = function(_loop, _st, _body, _i) {
		if (_st.cx.optimizer.__containsNoOp(_loop)) return undefined;
		var _known = __known(_body, _i, _st);
		var _env = variable_clone(_known.values);
		var _order = [];
		if (!__simulate(_loop, _env, _order)) return undefined;
		var _span = _loop.span;
		var _out = [];
		var _n = 0; repeat (array_length(_order)) {
			var _name = _order[_n];
			var _before = 0;
			var _k = _known.first; repeat (_i - _known.first) {
				_before += __gmlc_opt_live_refs(_body[_k], _name);
			_k++}
			if (__gmlc_opt_live_refs(_st.root, _name) != __gmlc_opt_live_refs(_loop, _name) + _before) {
				var _literal = _st.cx.optimizer.__literal(_env[$ _name], _span);
				if (_literal == undefined) return undefined;
				if (__declares(_loop, _name)) && (!array_contains(_known.declared, _name)) {
					array_push(_out, __gmlc_opt_var(_name, _literal, _span));
				}
				else {
					array_push(_out, new ASTExprStmt(_span, new ASTAssign(_span, "=", __gmlc_opt_local(_name, _span), _literal)));
				}
			}
		_n++}
		if (_st.apply) _st.cx.stats[$ "loops_evaluated"]++;
		return _out;
	};

	#region jsDoc
	/// @func    __known(_body, _i, _st)
	/// @desc    The locals given a whole-number literal by the statements right before a loop, with the statement
	///          they start at and the ones a `var` declares. The latest value of a local wins.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Array<Struct.ASTNode>} _body : The statement list
	/// @param   {Real}                  _i    : The loop's place in it
	/// @param   {Struct}                _st   : The walk state
	/// @returns {Struct} {values, declared, first}
	#endregion
	static __known = function(_body, _i, _st) {
		var _result = { values: {}, declared: [], first: _i };
		var _k = _i - 1;
		while (_k >= 0) {
			var _stmt = _body[_k];
			var _pairs = _st.cx.optimizer.__isNoOp(_stmt) ? undefined : __initPairs(_stmt);
			if (_pairs == undefined) break;
			var _p = array_length(_pairs) - 1; repeat (array_length(_pairs)) {
				var _pair = _pairs[_p];
				if (!struct_exists(_result.values, _pair.name)) _result.values[$ _pair.name] = _pair.value;
				if (_pair.is_var) && (!array_contains(_result.declared, _pair.name)) array_push(_result.declared, _pair.name);
			_p--}
			_result.first = _k;
			_k--;
		}
		return _result;
	};

	#region jsDoc
	/// @func    __initPairs(_stmt)
	/// @desc    The locals a statement gives a whole-number literal, or undefined when it is any other statement.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @returns {Array<Struct>|Undefined} {name, value, is_var} for each
	#endregion
	static __initPairs = function(_stmt) {
		var _pairs = [];
		if (_stmt.kind == __GMLC_NodeKind_VarDeclList) {
			var _d = 0; repeat (array_length(_stmt.declarations)) {
				var _decl = _stmt.declarations[_d];
				var _value = (_decl.init == undefined) ? undefined : __const(_decl.init);
				if (_value == undefined) return undefined;
				array_push(_pairs, { name: _decl.target.name, value: _value, is_var: true });
			_d++}
			return _pairs;
		}
		if (_stmt.kind == __GMLC_NodeKind_ExprStmt) && (_stmt.expression.kind == __GMLC_NodeKind_Assign) {
			var _assign = _stmt.expression;
			if (_assign.op != "=") || (!__gmlc_opt_is_local(_assign.target)) return undefined;
			var _assigned = __const(_assign.value);
			if (_assigned == undefined) return undefined;
			return [{ name: _assign.target.name, value: _assigned, is_var: false }];
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __const(_node)
	/// @desc    The value of a whole-number literal, with a minus sign or without, or undefined.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Real|Undefined}
	#endregion
	static __const = function(_node) {
		if (_node.kind == __GMLC_NodeKind_Literal) return ((_node.ty == "real") && (__gmlc_opt_whole_text(_node.lexeme))) ? real(_node.lexeme) : undefined;
		if (_node.kind == __GMLC_NodeKind_Unary) && (_node.op == "-") {
			var _value = __const(_node[$ "argument"]);
			return (_value == undefined) ? undefined : -_value;
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __declares(_node, _name)
	/// @desc    Whether a `var` declares a local anywhere under a node, nested functions left out.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The local
	/// @returns {Bool}
	#endregion
	static __declares = function(_node, _name) {
		if (_node.kind == __GMLC_NodeKind_VarDecl) && (_node.target.name == _name) return true;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__gmlc_opt_is_function(_child)) && (__declares(_child, _name)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};
	#endregion

	#region Evaluation
	#region jsDoc
	/// @func    __simulate(_loop, _env, _order)
	/// @desc    Runs a loop on whole numbers, at most `max_trips` times around, and leaves the values it gives the
	///          locals in `_env`. False when anything in it is not exact whole-number arithmetic on known locals.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Struct.ASTNode} _loop  : The loop
	/// @param   {Struct}         _env   : Local name to its value
	/// @param   {Array<String>}  _order : The locals written, in the order they first are
	/// @returns {Bool}
	#endregion
	static __simulate = function(_loop, _env, _order) {
		var _trips = 0;
		switch (_loop.kind) {
			case __GMLC_NodeKind_For: {
				if (_loop.test == undefined) return false;
				if (_loop.init != undefined) && (!__exec(_loop.init, _env, _order)) return false;
				while (true) {
					var _go = __cond(_loop.test, _env);
					if (_go == undefined) return false;
					if (!_go) break;
					if (_trips >= max_trips) return false;
					_trips++;
					if (!__execBody(_loop.body, _env, _order)) return false;
					if (_loop.update != undefined) && (!__exec(_loop.update, _env, _order)) return false;
				}
				return true;
			}
			case __GMLC_NodeKind_While: {
				while (true) {
					var _again = __cond(_loop.test, _env);
					if (_again == undefined) return false;
					if (!_again) break;
					if (_trips >= max_trips) return false;
					_trips++;
					if (!__execBody(_loop.body, _env, _order)) return false;
				}
				return true;
			}
			case __GMLC_NodeKind_DoUntil: {
				while (true) {
					if (_trips >= max_trips) return false;
					_trips++;
					if (!__execBody(_loop.body, _env, _order)) return false;
					var _done = __cond(_loop.test, _env);
					if (_done == undefined) return false;
					if (_done) break;
				}
				return true;
			}
			case __GMLC_NodeKind_Repeat: {
				var _count = __eval(_loop.count, _env);
				if (_count == undefined) || (_count < 0) || (_count > max_trips) return false;
				var _r = 0; repeat (_count) {
					if (!__execBody(_loop.body, _env, _order)) return false;
				_r++}
				return true;
			}
		}
		return false;
	};

	#region jsDoc
	/// @func    __execBody(_block, _env, _order)
	/// @desc    Runs the statements of a loop body.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Struct.ASTNode} _block : The body
	/// @param   {Struct}         _env   : Local name to its value
	/// @param   {Array<String>}  _order : The locals written, in the order they first are
	/// @returns {Bool}
	#endregion
	static __execBody = function(_block, _env, _order) {
		var _s = 0; repeat (array_length(_block.body)) {
			if (!__exec(_block.body[_s], _env, _order)) return false;
		_s++}
		return true;
	};

	#region jsDoc
	/// @func    __exec(_stmt, _env, _order)
	/// @desc    Runs one statement: `var` declarations with values, and assignments (`=`, `+=`, `-=`, `*=`) and
	///          increments of locals. False for anything else or a result that is not exact.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Struct.ASTNode} _stmt  : The statement
	/// @param   {Struct}         _env   : Local name to its value
	/// @param   {Array<String>}  _order : The locals written, in the order they first are
	/// @returns {Bool}
	#endregion
	static __exec = function(_stmt, _env, _order) {
		if (_stmt.kind == __GMLC_NodeKind_VarDeclList) {
			var _d = 0; repeat (array_length(_stmt.declarations)) {
				var _decl = _stmt.declarations[_d];
				if (_decl.init == undefined) return false;
				var _value = __eval(_decl.init, _env);
				if (_value == undefined) return false;
				__set(_env, _order, _decl.target.name, _value);
			_d++}
			return true;
		}
		if (_stmt.kind != __GMLC_NodeKind_ExprStmt) return false;
		var _expr = _stmt.expression;
		if (_expr.kind == __GMLC_NodeKind_Assign) {
			if (!__gmlc_opt_is_local(_expr.target)) return false;
			var _target = _expr.target.name;
			var _amount = __eval(_expr.value, _env);
			if (_amount == undefined) return false;
			if (_expr.op != "=") {
				var _held = _env[$ _target];
				if (_held == undefined) return false;
				switch (_expr.op) {
					case "+=": _amount = __bounded(_held + _amount); break;
					case "-=": _amount = __bounded(_held - _amount); break;
					case "*=": _amount = __bounded(_held * _amount); break;
					default: return false;
				}
				if (_amount == undefined) return false;
			}
			__set(_env, _order, _target, _amount);
			return true;
		}
		if (_expr.kind == __GMLC_NodeKind_Update) && (__gmlc_opt_is_local(_expr[$ "argument"])) {
			var _counter = _expr[$ "argument"].name;
			var _now = _env[$ _counter];
			if (_now == undefined) return false;
			var _next = __bounded((_expr.op == "++") ? _now + 1 : _now - 1);
			if (_next == undefined) return false;
			__set(_env, _order, _counter, _next);
			return true;
		}
		return false;
	};

	#region jsDoc
	/// @func    __set(_env, _order, _name, _value)
	/// @desc    Gives a local a value and notes it as written.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Struct}        _env   : Local name to its value
	/// @param   {Array<String>} _order : The locals written, in the order they first are
	/// @param   {String}        _name  : The local
	/// @param   {Real}          _value : The value
	#endregion
	static __set = function(_env, _order, _name, _value) {
		if (!array_contains(_order, _name)) array_push(_order, _name);
		_env[$ _name] = _value;
	};

	#region jsDoc
	/// @func    __bounded(_value)
	/// @desc    A result of whole-number arithmetic, or undefined when it reaches 2^53 and may have been rounded.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Real} _value : The result
	/// @returns {Real|Undefined}
	#endregion
	static __bounded = function(_value) {
		return (abs(_value) < exact_limit) ? _value : undefined;
	};

	#region jsDoc
	/// @func    __eval(_node, _env)
	/// @desc    The value of an expression of whole-number literals, known locals, `+`, `-`, `*` and a minus sign,
	///          or undefined.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _env  : Local name to its value
	/// @returns {Real|Undefined}
	#endregion
	static __eval = function(_node, _env) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: return ((_node.ty == "real") && (__gmlc_opt_whole_text(_node.lexeme))) ? real(_node.lexeme) : undefined;
			case __GMLC_NodeKind_Identifier: return __gmlc_opt_is_local(_node) ? _env[$ _node.name] : undefined;
			case __GMLC_NodeKind_Unary: {
				if (_node.op != "-") return undefined;
				var _value = __eval(_node[$ "argument"], _env);
				return (_value == undefined) ? undefined : -_value;
			}
			case __GMLC_NodeKind_Binary: {
				var _left = __eval(_node.left, _env);
				var _right = __eval(_node.right, _env);
				if (_left == undefined) || (_right == undefined) return undefined;
				switch (_node.op) {
					case "+": return __bounded(_left + _right);
					case "-": return __bounded(_left - _right);
					case "*": return __bounded(_left * _right);
				}
				return undefined;
			}
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __cond(_node, _env)
	/// @desc    Whether a loop condition holds: comparisons of values, `&&`, `||`, `!`, `true` and `false`, or a
	///          value read as a condition. Undefined when it cannot be told.
	/// @self    GMLC_Opt_ClosedFormLoopEvaluation
	/// @param   {Struct.ASTNode} _node : The condition
	/// @param   {Struct}         _env  : Local name to its value
	/// @returns {Bool|Undefined}
	#endregion
	static __cond = function(_node, _env) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: {
				if (_node.ty == "bool") return _node.value;
			break;}
			case __GMLC_NodeKind_Unary: {
				if (_node.op == "!") {
					var _inner = __cond(_node[$ "argument"], _env);
					return (_inner == undefined) ? undefined : !_inner;
				}
			break;}
			case __GMLC_NodeKind_Logical: {
				var _left = __cond(_node.left, _env);
				if (_left == undefined) return undefined;
				if (_node.op == "&&") return _left ? __cond(_node.right, _env) : false;
				if (_node.op == "||") return _left ? true : __cond(_node.right, _env);
				return undefined;
			}
			case __GMLC_NodeKind_Binary: {
				switch (_node.op) {
					case "<": case "<=": case ">": case ">=": case "==": case "!=": {
						var _a = __eval(_node.left, _env);
						var _b = __eval(_node.right, _env);
						if (_a == undefined) || (_b == undefined) return undefined;
						switch (_node.op) {
							case "<": return _a < _b;
							case "<=": return _a <= _b;
							case ">": return _a > _b;
							case ">=": return _a >= _b;
							case "==": return _a == _b;
						}
						return _a != _b;
					}
				}
			break;}
		}
		var _value = __eval(_node, _env);
		return (_value == undefined) ? undefined : (_value > 0.5);
	};
	#endregion

}
