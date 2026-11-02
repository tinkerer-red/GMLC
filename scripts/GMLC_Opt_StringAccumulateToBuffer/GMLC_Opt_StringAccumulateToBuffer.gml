#region jsDoc
/// @func    GMLC_Opt_StringAccumulateToBuffer()
/// @desc    Builds a string that a long counted loop grows with `s += piece;` in a buffer and reads it back once after
///          the loop: `for (var _i = 0; _i < 100; _i++) { s += "ab"; }` writes `"ab"` into a `buffer_grow` buffer in the
///          loop and sets `s` from the buffer afterwards. It applies only to a loop with a literal trip count of at
///          least `__minimum_trips` and no way out, to a local that is proven to hold a string and that the loop
///          touches only with those appends, in a function without `try`.
/// @returns {Struct.GMLC_Opt_StringAccumulateToBuffer}
#endregion
function GMLC_Opt_StringAccumulateToBuffer() : GMLC_OptimizerPass("string-accumulate-to-buffer") constructor {
	#region Config
	static __minimum_trips = 64;
	#endregion

	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The node to put in the place of _node, or undefined to keep it.
	/// @self    GMLC_Opt_StringAccumulateToBuffer
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _env = _cx.env;
		if (!_env.isFunction("buffer_create")) || (!_env.isFunction("buffer_write")) || (!_env.isFunction("buffer_seek")) || (!_env.isFunction("buffer_read")) || (!_env.isFunction("buffer_delete")) return undefined;
		if (!_env.isConstant("buffer_grow")) || (!_env.isConstant("buffer_text")) || (!_env.isConstant("buffer_u8")) || (!_env.isConstant("buffer_seek_start")) || (!_env.isConstant("buffer_string")) return undefined;
		if (__gmlc_opt_contains_kind(_node, __GMLC_NodeKind_Try, true)) return undefined;
		var _kinds = __gmlc_opt_string_kinds(_node);
		if (!__anyString(_kinds)) return undefined;
		return __gmlc_opt_rewrite_lists(_node, _cx, true, method(self, __list), _kinds);
	};
	#endregion

	#region Private
	#region Rewrite
	#region jsDoc
	/// @func    __list(_stmts, _cx, _kinds)
	/// @desc    Replaces every loop of a statement list that qualifies with the statements that build its string in a
	///          buffer.
	/// @self    GMLC_Opt_StringAccumulateToBuffer
	/// @param   {Array<Struct.ASTNode>} _stmts : A statement list
	/// @param   {Struct}                _cx    : The pass context
	/// @param   {Struct}                _kinds : What is proven about the function's locals
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list
	#endregion
	static __list = function(_stmts, _cx, _kinds) {
		var _out = undefined;
		var _i = 0; repeat (array_length(_stmts)) {
			var _plan = __plan(_stmts, _i, _cx, _kinds);
			if (_plan != undefined) {
				if (_out == undefined) {
					_out = [];
					array_copy(_out, 0, _stmts, 0, _i);
				}
				array_copy(_out, array_length(_out), _plan, 0, array_length(_plan));
			}
			else if (_out != undefined) {
				array_push(_out, _stmts[_i]);
			}
		_i++}
		return _out;
	};

	#region jsDoc
	/// @func    __plan(_stmts, _at, _cx, _kinds)
	/// @desc    The statements that take the place of a loop, or undefined when it does not qualify: a `repeat` or
	///          `for` loop with a literal trip count of at least the minimum and nothing that leaves it, whose body
	///          appends to a local that holds a string, that an earlier statement of the list set to a string and that
	///          the loop names nowhere else. They create a buffer, write the local's string into it, run the loop
	///          with each append written to the buffer, then read the string back into the local and delete the
	///          buffer.
	/// @self    GMLC_Opt_StringAccumulateToBuffer
	/// @param   {Array<Struct.ASTNode>} _stmts : The statement list
	/// @param   {Real}                  _at    : The index of the loop
	/// @param   {Struct}                _cx    : The pass context
	/// @param   {Struct}                _kinds : What is proven about the function's locals
	/// @returns {Array<Struct.ASTNode>|Undefined}
	#endregion
	static __plan = function(_stmts, _at, _cx, _kinds) {
		var _loop = _stmts[_at];
		if (__gmlc_opt_loop_trips(_loop) < __minimum_trips) || (_cx.optimizer.__isNoOp(_loop)) || (__gmlc_opt_has_jump_out(_loop)) return undefined;
		var _body = _loop.body;
		var _target = undefined;
		var _i = 0; repeat (array_length(_body.body)) {
			if (_target == undefined) && (__appendTarget(_body.body[_i], _cx) != undefined) _target = _body.body[_i].expression.target;
		_i++}
		if (_target == undefined) return undefined;
		var _local = _target.name;
		if (_kinds[$ _local] != "string") || (!__gmlc_opt_string_initialized(_stmts, _at, _local)) return undefined;
		if (__gmlc_opt_count_mentions(_loop, _local) != __countAppends(_body, _local, _cx)) return undefined;
		var _span = _loop.span;
		var _buffer = _cx.optimizer.newTemporary(_cx);
		var _create = __call("buffer_create", [_cx.optimizer.__literal(256, _span), __constant("buffer_grow", _span), _cx.optimizer.__literal(1, _span)], _span, _cx);
		var _zero = _cx.optimizer.__literal(0, _span);
		var _new_loop = variable_clone(_loop, 0);
		_new_loop.body = __replace(_body, _local, _buffer, _cx) ?? _body;
		var _plan = [];
		array_push(_plan, __gmlc_opt_var(_buffer, _create, _span));
		array_push(_plan, new ASTExprStmt(_span, __call("buffer_write", [__gmlc_opt_local(_buffer, _span), __constant("buffer_text", _span), __gmlc_opt_clone(_target)], _span, _cx)));
		array_push(_plan, _new_loop);
		array_push(_plan, new ASTExprStmt(_span, __call("buffer_write", [__gmlc_opt_local(_buffer, _span), __constant("buffer_u8", _span), _zero], _span, _cx)));
		array_push(_plan, new ASTExprStmt(_span, __call("buffer_seek", [__gmlc_opt_local(_buffer, _span), __constant("buffer_seek_start", _span), __gmlc_opt_clone(_zero)], _span, _cx)));
		var _read = __call("buffer_read", [__gmlc_opt_local(_buffer, _span), __constant("buffer_string", _span)], _span, _cx);
		array_push(_plan, new ASTExprStmt(_span, new ASTAssign(_span, "=", __gmlc_opt_clone(_target), _read)));
		array_push(_plan, new ASTExprStmt(_span, __call("buffer_delete", [__gmlc_opt_local(_buffer, _span)], _span, _cx)));
		_cx.stats[$ "loops_converted"]++;
		return _plan;
	};

	#region jsDoc
	/// @func    __replace(_node, _name, _buffer, _cx)
	/// @desc    A statement with every append to a local turned into a write of the piece to a buffer, or undefined
	///          when it holds none.
	/// @self    GMLC_Opt_StringAccumulateToBuffer
	/// @param   {Struct.ASTNode} _node   : The statement
	/// @param   {String}         _name   : The local
	/// @param   {String}         _buffer : The temporary that holds the buffer
	/// @param   {Struct}         _cx     : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __replace = function(_node, _name, _buffer, _cx) {
		if (__gmlc_opt_is_function(_node)) || ((_node.kind >= __GMLC_NodeKind_Assign) && (_node.kind <= __GMLC_NodeKind_Nameof)) return undefined;
		if (__appendTarget(_node, _cx) == _name) {
			var _span = _node.span;
			var _stmt = variable_clone(_node, 0);
			_stmt.expression = __call("buffer_write", [__gmlc_opt_local(_buffer, _span), __constant("buffer_text", _span), _node.expression.value], _span, _cx);
			return _stmt;
		}
		var _slots = _node.childSlots();
		var _news = undefined;
		var _i = 0; repeat (array_length(_slots)) {
			var _new = __replace(_slots[_i].node, _name, _buffer, _cx);
			if (_new != undefined) {
				if (_news == undefined) _news = array_create(array_length(_slots), undefined);
				_news[_i] = _new;
			}
		_i++}
		return (_news != undefined) ? __gmlc_opt_rebuilt(_node, _slots, _news) : undefined;
	};

	#region jsDoc
	/// @func    __call(_name, _args, _span, _cx)
	/// @desc    A call of a built-in function.
	/// @self    GMLC_Opt_StringAccumulateToBuffer
	/// @param   {String}                _name : The function
	/// @param   {Array<Struct.ASTNode>} _args : The arguments
	/// @param   {Struct.GMLC_Span}      _span : The span
	/// @param   {Struct}                _cx   : The pass context
	/// @returns {Struct.ASTCall}
	#endregion
	static __call = function(_name, _args, _span, _cx) {
		return new ASTCall(_span, _cx.optimizer.__builtin(_name, _span), _args);
	};

	#region jsDoc
	/// @func    __constant(_name, _span)
	/// @desc    An identifier that names a built-in constant.
	/// @self    GMLC_Opt_StringAccumulateToBuffer
	/// @param   {String}           _name : The constant
	/// @param   {Struct.GMLC_Span} _span : The span
	/// @returns {Struct.ASTIdentifier}
	#endregion
	static __constant = function(_name, _span) {
		var _node = new ASTIdentifier(_span, _name);
		_node.symbol = new GMLC_Symbol("BuiltinConstant", _name);
		return _node;
	};
	#endregion

	#region Questions
	#region jsDoc
	/// @func    __appendTarget(_stmt, _cx)
	/// @desc    The local a statement appends to with `+=`, or undefined for any other statement and for a frozen one.
	/// @self    GMLC_Opt_StringAccumulateToBuffer
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {String|Undefined}
	#endregion
	static __appendTarget = function(_stmt, _cx) {
		if (_stmt.kind != __GMLC_NodeKind_ExprStmt) return undefined;
		var _assign = _stmt.expression;
		if (_assign.kind != __GMLC_NodeKind_Assign) || (_assign.op != "+=") || (!__gmlc_opt_is_local(_assign.target)) || (_cx.optimizer.__isNoOp(_stmt)) return undefined;
		return _assign.target.name;
	};

	#region jsDoc
	/// @func    __countAppends(_node, _name, _cx)
	/// @desc    How many statements under a node append to a local, nested functions left out.
	/// @self    GMLC_Opt_StringAccumulateToBuffer
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The local
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Real}
	#endregion
	static __countAppends = function(_node, _name, _cx) {
		if (__gmlc_opt_is_function(_node)) || ((_node.kind >= __GMLC_NodeKind_Assign) && (_node.kind <= __GMLC_NodeKind_Nameof)) return 0;
		var _n = (__appendTarget(_node, _cx) == _name) ? 1 : 0;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					_n += __countAppends(_child, _name, _cx);
				}
			_i++}
		_field_index++}
		return _n;
	};

	#endregion

	#region Proven types
	#region jsDoc
	/// @func    __anyString(_kinds)
	/// @desc    Whether any local is proven to hold a string.
	/// @self    GMLC_Opt_StringAccumulateToBuffer
	/// @param   {Struct} _kinds : What is proven about the locals
	/// @returns {Bool}
	#endregion
	static __anyString = function(_kinds) {
		var _names = struct_get_names(_kinds);
		var _i = 0; repeat (array_length(_names)) {
			if (_kinds[$ _names[_i]] == "string") return true;
		_i++}
		return false;
	};
	#endregion
	#endregion
}
