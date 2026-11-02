#region jsDoc
/// @func    GMLC_Opt_LoopFuse()
/// @desc    Merges two adjacent `for` loops with the same header into one. Both bodies may only store to arrays that
///          the function makes itself with `array_create` and only returns, from values that are pure, and the arrays
///          the two bodies share must be touched at the same index. At least one body must be unable to throw.
///          `for (i) { xs[i] = 0; } for (i) { ys[i] = 1; }` becomes `for (i) { xs[i] = 0; ys[i] = 1; }`.
/// @returns {Struct.GMLC_Opt_LoopFuse}
#endregion
function GMLC_Opt_LoopFuse() : GMLC_OptimizerPass("loop-fuse") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The node to put in the place of _node, or undefined to keep it.
	/// @self    GMLC_Opt_LoopFuse
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		return __rewrite(_node, _node, _cx, true, false);
	};
	#endregion

	#region Private
	#region Walk
	#region jsDoc
	/// @func    __rewrite(_node, _fn, _cx, _is_root, _in_try)
	/// @desc    Rewrites the statement lists under a node, inner ones first, nested functions left out.
	/// @self    GMLC_Opt_LoopFuse
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {Struct.ASTNode} _fn      : The function the pass runs on
	/// @param   {Struct}         _cx      : The pass context
	/// @param   {Bool}           _is_root : Whether the node is the function itself
	/// @param   {Bool}           _in_try  : Whether the node is inside a `try`
	/// @returns {Struct.ASTNode|Undefined} A changed copy, or undefined
	#endregion
	static __rewrite = function(_node, _fn, _cx, _is_root, _in_try) {
		if (!_is_root) && (__gmlc_opt_is_function(_node)) return undefined;
		var _kind = _node.kind;
		var _try = _in_try || (_kind == __GMLC_NodeKind_Try);
		var _copy = undefined;
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _key = _fields[_f];
			var _value = _node[$ _key];
			if (is_array(_value)) {
				var _count = array_length(_value);
				var _items = undefined;
				var _j = 0; repeat (_count) {
					if (_value[_j] != undefined) {
						var _item = __rewrite(_value[_j], _fn, _cx, false, _try);
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
				var _child = __rewrite(_value, _fn, _cx, false, _try);
				if (_child != undefined) {
					_copy ??= variable_clone(_node, 0);
					_copy[$ _key] = _child;
				}
			}
		_f++}
		if (_kind == __GMLC_NodeKind_Script) || (_kind == __GMLC_NodeKind_Block) || (_kind == __GMLC_NodeKind_Case) || (_kind == __GMLC_NodeKind_Default) {
			var _new_body = __list((_copy ?? _node).body, _fn, _cx, _try);
			if (_new_body != undefined) {
				_copy ??= variable_clone(_node, 0);
				_copy.body = _new_body;
			}
		}
		return _copy;
	};

	#region jsDoc
	/// @func    __list(_body, _fn, _cx, _in_try)
	/// @desc    Fuses the adjacent loops of a statement list.
	/// @self    GMLC_Opt_LoopFuse
	/// @param   {Array<Struct.ASTNode>} _body   : The statements
	/// @param   {Struct.ASTNode}        _fn     : The function the pass runs on
	/// @param   {Struct}                _cx     : The pass context
	/// @param   {Bool}                  _in_try : Whether the list is inside a `try`
	/// @returns {Array<Struct.ASTNode>|Undefined} The new statements, or undefined
	#endregion
	static __list = function(_body, _fn, _cx, _in_try) {
		if (_in_try) return undefined;
		var _out = [];
		var _changed = false;
		var _i = 0; repeat (array_length(_body)) {
			var _statement = _body[_i];
			var _last = array_length(_out) - 1;
			var _fused = undefined;
			if (_statement.kind == __GMLC_NodeKind_For) && (_last >= 0) && (_out[_last].kind == __GMLC_NodeKind_For) {
				_fused = __fuse(_out[_last], _statement, _fn, _cx);
			}
			if (_fused != undefined) {
				_out[_last] = _fused;
				_changed = true;
			}
			else {
				array_push(_out, _statement);
			}
		_i++}
		return _changed ? _out : undefined;
	};
	#endregion

	#region Loops
	#region jsDoc
	/// @func    __fuse(_a, _b, _fn, _cx)
	/// @desc    The loop that does the work of two adjacent loops, or undefined when they cannot be merged.
	/// @self    GMLC_Opt_LoopFuse
	/// @param   {Struct.ASTFor}  _a  : The first loop
	/// @param   {Struct.ASTFor}  _b  : The loop after it
	/// @param   {Struct.ASTNode} _fn : The function the pass runs on
	/// @param   {Struct}         _cx : The pass context
	/// @returns {Struct.ASTFor|Undefined}
	#endregion
	static __fuse = function(_a, _b, _fn, _cx) {
		if (_cx.optimizer.__containsNoOp(_a)) || (_cx.optimizer.__containsNoOp(_b)) return undefined;
		var _ha = __gmlc_opt_counted_header(_a);
		var _hb = __gmlc_opt_counted_header(_b);
		if (_ha == undefined) || (_hb == undefined) || (!_ha.declared) || (!_hb.declared) return undefined;
		if (!__gmlc_opt_same(_a.init, _b.init)) || (!__gmlc_opt_same(_a.test, _b.test)) || (!__gmlc_opt_same(_a.update, _b.update)) return undefined;
		var _from = __gmlc_opt_real_literal(_ha.start);
		if (_from == undefined) || (_from < 0) || (_ha.step <= 0) return undefined;
		if (__gmlc_opt_real_literal(_ha.bound) == undefined) && (!__gmlc_opt_is_local(_ha.bound)) return undefined;
		if (_a.body.kind != __GMLC_NodeKind_Block) || (_b.body.kind != __GMLC_NodeKind_Block) return undefined;
		var _ctx = { name: _ha.name, fn: _fn, owned: {}, instance: __gmlc_opt_self_is_instance(_cx, _a) };
		var _sa = __summary(_a.body.body, _ctx);
		if (!_sa.ok) return undefined;
		var _sb = __summary(_b.body.body, _ctx);
		if (!_sb.ok) return undefined;
		if (!_sa.quiet) && (!_sb.quiet) return undefined;
		var _x = 0; repeat (array_length(_sa.accesses)) {
			var _p = _sa.accesses[_x];
			var _y = 0; repeat (array_length(_sb.accesses)) {
				var _q = _sb.accesses[_y];
				if (_p.array == _q.array) && (_p.write || _q.write) && (_p.offset != _q.offset) return undefined;
			_y++}
		_x++}
		if (__names_written(_sa, _sb)) return undefined;
		_cx.stats[$ "fused"]++;
		var _body = array_concat(_a.body.body, _b.body.body);
		return new ASTFor(_a.span, _a.init, _a.test, _a.update, new ASTBlock(_a.body.span, _body, _a.body.origin), _a.origin);
	};

	#region jsDoc
	/// @func    __names_written(_sa, _sb)
	/// @desc    Whether a body names, as a value, an array that either body stores to.
	/// @self    GMLC_Opt_LoopFuse
	/// @param   {Struct} _sa : The summary of the first body
	/// @param   {Struct} _sb : The summary of the second body
	/// @returns {Bool}
	#endregion
	static __names_written = function(_sa, _sb) {
		var _bare = array_concat(_sa.bare, _sb.bare);
		var _accesses = array_concat(_sa.accesses, _sb.accesses);
		var _i = 0; repeat (array_length(_accesses)) {
			if (_accesses[_i].write) && (array_contains(_bare, _accesses[_i].array)) return true;
		_i++}
		return false;
	};

	#region jsDoc
	/// @func    __summary(_statements, _ctx)
	/// @desc    What a loop body does: whether it is made of statements this pass understands, whether it cannot
	///          throw, the array elements it touches and the locals it names as values.
	/// @self    GMLC_Opt_LoopFuse
	/// @param   {Array<Struct.ASTNode>} _statements : The body
	/// @param   {Struct}                _ctx        : {name, fn, owned, instance}
	/// @returns {Struct} {ok, quiet, accesses: [{array, offset, write}], bare: [names]}
	#endregion
	static __summary = function(_statements, _ctx) {
		var _s = { ok: true, quiet: true, accesses: [], bare: [] };
		var _i = 0; repeat (array_length(_statements)) {
			__statement(_statements[_i], _s, _ctx);
			if (!_s.ok) return _s;
		_i++}
		return _s;
	};

	#region jsDoc
	/// @func    __statement(_node, _s, _ctx)
	/// @desc    Adds a statement to a summary: it must store to an element of an array the function owns.
	/// @self    GMLC_Opt_LoopFuse
	/// @param   {Struct.ASTNode} _node : The statement
	/// @param   {Struct}         _s    : The summary
	/// @param   {Struct}         _ctx  : {name, fn, owned, instance}
	#endregion
	static __statement = function(_node, _s, _ctx) {
		if (_node.kind != __GMLC_NodeKind_ExprStmt) || (_node.expression.kind != __GMLC_NodeKind_Assign) {
			_s.ok = false;
			return;
		}
		var _assign = _node.expression;
		var _target = _assign.target;
		if (_target.kind != __GMLC_NodeKind_Index) || (_target.accessor != "Array") || (array_length(_target.keys) != 1) || (!__gmlc_opt_is_local(_target.object)) {
			_s.ok = false;
			return;
		}
		var _array = _target.object.name;
		var _offset = __gmlc_opt_offset_of(_target.keys[0], _ctx.name);
		if (_offset == undefined) || (!__gmlc_opt_owned_locals(_array, _ctx)) {
			_s.ok = false;
			return;
		}
		array_push(_s.accesses, { array: _array, offset: _offset, write: true });
		if (_assign.op != "=") {
			array_push(_s.accesses, { array: _array, offset: _offset, write: false });
			_s.quiet = false;
		}
		if (_offset < 0) || (_offset != floor(_offset)) _s.quiet = false;
		__expression(_assign.value, _s, _ctx);
		if (_s.ok) && (!__quiet(_assign.value, _ctx)) _s.quiet = false;
	};

	#region jsDoc
	/// @func    __expression(_node, _s, _ctx)
	/// @desc    Adds the reads of an expression to a summary: literals, locals, variables, pure calls, operators and
	///          elements of arrays; anything else clears `ok`.
	/// @self    GMLC_Opt_LoopFuse
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _s    : The summary
	/// @param   {Struct}         _ctx  : {name, fn, owned, instance}
	#endregion
	static __expression = function(_node, _s, _ctx) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal:
			return;
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				if (_symbol == undefined) {
					_s.ok = false;
					return;
				}
				switch (_symbol.kind) {
					case "Local":
						if (_node.name != _ctx.name) array_push(_s.bare, _node.name);
					return;
					case "Self": case "Global": case "Static": case "BuiltinVar": case "BuiltinConstant": case "Enum": case "Macro": case "Asset":
					return;
				}
				_s.ok = false;
				return;
			}
			case __GMLC_NodeKind_Index: {
				if (_node.accessor != "Array") || (array_length(_node.keys) != 1) || (!__gmlc_opt_is_local(_node.object)) {
					_s.ok = false;
					return;
				}
				__expression(_node.keys[0], _s, _ctx);
				if (!_s.ok) return;
				var _array = _node.object.name;
				if (__gmlc_opt_owned_locals(_array, _ctx)) {
					var _offset = __gmlc_opt_offset_of(_node.keys[0], _ctx.name);
					if (_offset == undefined) {
						_s.ok = false;
						return;
					}
					array_push(_s.accesses, { array: _array, offset: _offset, write: false });
				}
				return;
			}
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) || (__gmlc_opt_call_class(_name) != "pure") {
					_s.ok = false;
					return;
				}
				var _a = 0; repeat (array_length(_node.args)) {
					__expression(_node.args[_a], _s, _ctx);
				_a++}
				return;
			}
			case __GMLC_NodeKind_Binary:
			case __GMLC_NodeKind_Logical:
			case __GMLC_NodeKind_Nullish:
			case __GMLC_NodeKind_Unary:
			case __GMLC_NodeKind_Conditional: {
				var _children = _node.children();
				var _c = 0; repeat (array_length(_children)) {
					__expression(_children[_c], _s, _ctx);
				_c++}
				return;
			}
		}
		_s.ok = false;
	};
	#endregion

	#region Facts
	#region jsDoc
	/// @func    __quiet(_node, _ctx)
	/// @desc    Whether evaluating an expression cannot throw: literals, locals, built-in names and variables,
	///          arithmetic and comparisons of numbers, and calls the effect table lists as not throwing. Element reads
	///          are not.
	/// @self    GMLC_Opt_LoopFuse
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _ctx  : {name, fn, owned, instance}
	/// @returns {Bool}
	#endregion
	static __quiet = function(_node, _ctx) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal:
			return true;
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				switch (_symbol.kind) {
					case "Local": case "BuiltinConstant": case "Enum": case "Macro": case "Asset":
					return true;
					case "Self":
					return __instance_variable(_node.name, false, _ctx);
				}
				return false;
			}
			case __GMLC_NodeKind_Binary:
				switch (_node.op) {
					case "+": case "-": case "*": case "/": case "<": case "<=": case ">": case ">=": case "==": case "!=":
					return __numeric(_node.left, _ctx) && __numeric(_node.right, _ctx);
				}
			return false;
			case __GMLC_NodeKind_Unary:
			return ((_node.op == "-") || (_node.op == "+")) && __numeric(_node[$ "argument"], _ctx);
			case __GMLC_NodeKind_Call:
			return !__gmlc_opt_may_throw(_node);
		}
		return false;
	};

	#region jsDoc
	/// @func    __numeric(_node, _ctx)
	/// @desc    Whether an expression is a number: a real literal, the counter or a local that holds a number, a
	///          built-in instance variable that holds a real, or arithmetic of those.
	/// @self    GMLC_Opt_LoopFuse
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _ctx  : {name, fn, owned, instance}
	/// @returns {Bool}
	#endregion
	static __numeric = function(_node, _ctx) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal:
			return (_node.ty == "real") || (_node.ty == "int64");
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				if (_symbol == undefined) return false;
				if (_symbol.kind == "Local") return (_node.name == _ctx.name) || (__gmlc_opt_value_type(_node) == "Real") || (__gmlc_opt_value_type(_node) == "Int64");
				return (_symbol.kind == "Self") && __instance_variable(_node.name, true, _ctx);
			}
			case __GMLC_NodeKind_Binary:
				switch (_node.op) {
					case "+": case "-": case "*": case "/":
					return __numeric(_node.left, _ctx) && __numeric(_node.right, _ctx);
				}
			return false;
			case __GMLC_NodeKind_Unary:
			return (_node.op == "-") && __numeric(_node[$ "argument"], _ctx);
		}
		return false;
	};

	#region jsDoc
	/// @func    __instance_variable(_name, _real, _ctx)
	/// @desc    Whether reading a name cannot throw because it is a built-in instance variable and `self` is sure to be
	///          an instance; with _real, also that it holds a real.
	/// @self    GMLC_Opt_LoopFuse
	/// @param   {String} _name : The variable
	/// @param   {Bool}   _real : Whether it has to hold a real
	/// @param   {Struct} _ctx  : {name, fn, owned, instance}
	/// @returns {Bool}
	#endregion
	static __instance_variable = function(_name, _real, _ctx) {
		var _entry = __gmlc_opt_builtin_variable(_name);
		return _ctx.instance && (_entry != undefined) && _entry.instance && ((!_real) || (_entry.type == "Real"));
	};
	
	#endregion

	#endregion
}
