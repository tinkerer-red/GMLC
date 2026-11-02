#region jsDoc
/// @func    GMLC_Opt_LoopInterchange()
/// @desc    Swaps the two loops of a perfect nest that walks an array of arrays the wrong way round: the inner loop
///          counts the rows (`h[y][x]`) and the outer one the cells of a row. It only acts when the tree proves the
///          rows: the array is made by `array_create(rows)`, the loop right before the nest fills every row with
///          `array_create(columns, literal)`, the nest counts exactly those ranges from 0, touches only its own
///          cell, and the array is used nowhere else but returned.
///          `for (x) { for (y) { h[y][x] *= 2; } }` becomes `for (y) { for (x) { h[y][x] *= 2; } }`.
/// @returns {Struct.GMLC_Opt_LoopInterchange}
#endregion
function GMLC_Opt_LoopInterchange() : GMLC_OptimizerPass("loop-interchange") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The node to put in the place of _node, or undefined to keep it.
	/// @self    GMLC_Opt_LoopInterchange
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
	/// @self    GMLC_Opt_LoopInterchange
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
	/// @desc    Interchanges the nests of a statement list.
	/// @self    GMLC_Opt_LoopInterchange
	/// @param   {Array<Struct.ASTNode>} _body   : The statements
	/// @param   {Struct.ASTNode}        _fn     : The function the pass runs on
	/// @param   {Struct}                _cx     : The pass context
	/// @param   {Bool}                  _in_try : Whether the list is inside a `try`
	/// @returns {Array<Struct.ASTNode>|Undefined} The new statements, or undefined
	#endregion
	static __list = function(_body, _fn, _cx, _in_try) {
		if (_in_try) return undefined;
		var _out = undefined;
		var _count = array_length(_body);
		var _i = 1; repeat (_count - 1) {
			if (_body[_i].kind == __GMLC_NodeKind_For) && (_body[_i - 1].kind == __GMLC_NodeKind_For) {
				var _new = __interchange(_body[_i], _body[_i - 1], _fn, _cx);
				if (_new != undefined) {
					if (_out == undefined) {
						_out = array_create(_count);
						array_copy(_out, 0, _body, 0, _count);
					}
					_out[_i] = _new;
				}
			}
		_i++}
		return _out;
	};
	#endregion

	#region Nests
	#region jsDoc
	/// @func    __interchange(_outer, _before, _fn, _cx)
	/// @desc    The nest with its two loops swapped, or undefined when the tree does not prove the swap.
	/// @self    GMLC_Opt_LoopInterchange
	/// @param   {Struct.ASTFor}  _outer  : The outer loop
	/// @param   {Struct.ASTFor}  _before : The statement before it
	/// @param   {Struct.ASTNode} _fn     : The function the pass runs on
	/// @param   {Struct}         _cx     : The pass context
	/// @returns {Struct.ASTFor|Undefined}
	#endregion
	static __interchange = function(_outer, _before, _fn, _cx) {
		if (_cx.optimizer.__containsNoOp(_outer)) return undefined;
		var _o = __gmlc_opt_counted_header(_outer);
		if (_o == undefined) || (!__from_zero(_o)) return undefined;
		if (_outer.body.kind != __GMLC_NodeKind_Block) || (array_length(_outer.body.body) != 1) return undefined;
		var _inner = _outer.body.body[0];
		if (_inner.kind != __GMLC_NodeKind_For) return undefined;
		var _i = __gmlc_opt_counted_header(_inner);
		if (_i == undefined) || (!__from_zero(_i)) || (_i.name == _o.name) return undefined;
		var _fill = __gmlc_opt_counted_header(_before);
		if (_fill == undefined) || (!__from_zero(_fill)) return undefined;
		if (_inner.body.kind != __GMLC_NodeKind_Block) || (array_length(_inner.body.body) == 0) return undefined;
		var _statements = _inner.body.body;
		var _first = _statements[0];
		if (_first.kind != __GMLC_NodeKind_ExprStmt) || (_first.expression.kind != __GMLC_NodeKind_Assign) return undefined;
		var _cell = __cell(_first.expression.target);
		if (_cell == undefined) || (_cell.row != _i.name) || (_cell.col != _o.name) return undefined;
		var _rows = _cell.array;
		var _s = 0; repeat (array_length(_statements)) {
			if (!__statement_ok(_statements[_s], _cell)) return undefined;
		_s++}
		var _made = __fresh(_fn, _rows);
		if (_made == undefined) || (array_length(_made.args) < 1) || (array_length(_made.args) > 2) return undefined;
		if (array_length(_made.args) == 2) && (__gmlc_opt_real_literal(_made.args[1]) == undefined) return undefined;
		var _row_count = _made.args[0];
		var _filled = __fill(_before, _fill, _rows);
		if (_filled == undefined) return undefined;
		if (!__stable(_fn, _row_count)) || (!__stable(_fn, _filled)) return undefined;
		if (!__gmlc_opt_same(_fill.bound, _row_count)) || (!__gmlc_opt_same(_i.bound, _row_count)) || (!__gmlc_opt_same(_o.bound, _filled)) return undefined;
		if (!__gmlc_opt_contained_in(_fn, _rows, false)) return undefined;
		if (__element_uses(_fn, _rows) != __element_uses(_before, _rows) + __element_uses(_outer, _rows)) return undefined;
		_cx.stats[$ "interchanged"]++;
		var _swapped = new ASTFor(_inner.span, _outer.init, _outer.test, _outer.update, _inner.body, _inner.origin);
		return new ASTFor(_outer.span, _inner.init, _inner.test, _inner.update, new ASTBlock(_outer.body.span, [_swapped], _outer.body.origin), _outer.origin);
	};

	#region jsDoc
	/// @func    __fill(_before, _fill, _rows)
	/// @desc    The number of columns a loop gives every row of an array: the loop is `for (var r = 0; r < n; r++)`
	///          with the body `rows[r] = array_create(columns, literal);`. Undefined for any other loop.
	/// @self    GMLC_Opt_LoopInterchange
	/// @param   {Struct.ASTFor} _before : The loop
	/// @param   {Struct}        _fill   : Its header
	/// @param   {String}        _rows   : The array
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __fill = function(_before, _fill, _rows) {
		if (_before.body.kind != __GMLC_NodeKind_Block) || (array_length(_before.body.body) != 1) return undefined;
		var _statement = _before.body.body[0];
		if (_statement.kind != __GMLC_NodeKind_ExprStmt) || (_statement.expression.kind != __GMLC_NodeKind_Assign) return undefined;
		var _assign = _statement.expression;
		if (_assign.op != "=") return undefined;
		var _target = _assign.target;
		if (_target.kind != __GMLC_NodeKind_Index) || (_target.accessor != "Array") || (array_length(_target.keys) != 1) return undefined;
		if (!__gmlc_opt_is_local(_target.object)) || (_target.object.name != _rows) return undefined;
		if (!__gmlc_opt_is_local(_target.keys[0])) || (_target.keys[0].name != _fill.name) return undefined;
		if (__gmlc_opt_builtin_call(_assign.value) != "array_create") return undefined;
		var _args = _assign.value.args;
		if (array_length(_args) < 1) || (array_length(_args) > 2) return undefined;
		if (array_length(_args) == 2) && (__gmlc_opt_real_literal(_args[1]) == undefined) return undefined;
		return _args[0];
	};

	#region jsDoc
	/// @func    __cell(_node)
	/// @desc    The parts of `rows[row][col]` with a local array and two local counters, or undefined.
	/// @self    GMLC_Opt_LoopInterchange
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Struct|Undefined} {array, row, col}
	#endregion
	static __cell = function(_node) {
		if (_node.kind != __GMLC_NodeKind_Index) || (_node.accessor != "Array") || (array_length(_node.keys) != 1) return undefined;
		var _row = _node.object;
		if (_row.kind != __GMLC_NodeKind_Index) || (_row.accessor != "Array") || (array_length(_row.keys) != 1) return undefined;
		if (!__gmlc_opt_is_local(_row.object)) || (!__gmlc_opt_is_local(_row.keys[0])) || (!__gmlc_opt_is_local(_node.keys[0])) return undefined;
		return { array: _row.object.name, row: _row.keys[0].name, col: _node.keys[0].name };
	};

	#region jsDoc
	/// @func    __statement_ok(_statement, _cell)
	/// @desc    Whether a statement of the inner loop only writes its own cell, from literals, locals and pure calls.
	/// @self    GMLC_Opt_LoopInterchange
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {Struct}         _cell      : The cell {array, row, col}
	/// @returns {Bool}
	#endregion
	static __statement_ok = function(_statement, _cell) {
		if (_statement.kind != __GMLC_NodeKind_ExprStmt) || (_statement.expression.kind != __GMLC_NodeKind_Assign) return false;
		var _assign = _statement.expression;
		var _target = __cell(_assign.target);
		if (_target == undefined) || (_target.array != _cell.array) || (_target.row != _cell.row) || (_target.col != _cell.col) return false;
		return __value_ok(_assign.value, _cell);
	};

	#region jsDoc
	/// @func    __value_ok(_node, _cell)
	/// @desc    Whether an expression reads nothing but literals, locals other than the array, its own cell and pure
	///          calls.
	/// @self    GMLC_Opt_LoopInterchange
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _cell : The cell {array, row, col}
	/// @returns {Bool}
	#endregion
	static __value_ok = function(_node, _cell) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal:
			return true;
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				if (_symbol == undefined) return false;
				if (_symbol.kind == "Local") return (_node.name != _cell.array);
				return (_symbol.kind == "BuiltinConstant") || (_symbol.kind == "Enum") || (_symbol.kind == "Macro") || (_symbol.kind == "Asset");
			}
			case __GMLC_NodeKind_Index: {
				var _own = __cell(_node);
				return (_own != undefined) && (_own.array == _cell.array) && (_own.row == _cell.row) && (_own.col == _cell.col);
			}
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) || (__gmlc_opt_call_class(_name) != "pure") return false;
				var _a = 0; repeat (array_length(_node.args)) {
					if (!__value_ok(_node.args[_a], _cell)) return false;
				_a++}
				return true;
			}
			case __GMLC_NodeKind_Binary:
			case __GMLC_NodeKind_Logical:
			case __GMLC_NodeKind_Nullish:
			case __GMLC_NodeKind_Unary:
			case __GMLC_NodeKind_Conditional: {
				var _children = _node.children();
				var _c = 0; repeat (array_length(_children)) {
					if (!__value_ok(_children[_c], _cell)) return false;
				_c++}
				return true;
			}
		}
		return false;
	};
	#endregion

	#region Facts
	#region jsDoc
	/// @func    __from_zero(_loop)
	/// @desc    Whether a loop header is `for (var i = 0; i < bound; i++)`.
	/// @self    GMLC_Opt_LoopInterchange
	/// @param   {Struct} _loop : The header
	/// @returns {Bool}
	#endregion
	static __from_zero = function(_loop) {
		return _loop.declared && (_loop.cmp == "<") && (_loop.step == 1) && (__gmlc_opt_real_literal(_loop.start) == 0);
	};

	#region jsDoc
	/// @func    __stable(_fn, _node)
	/// @desc    Whether an expression has one value in the whole function: a real literal, or a parameter that is never
	///          written.
	/// @self    GMLC_Opt_LoopInterchange
	/// @param   {Struct.ASTNode} _fn   : The function
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __stable = function(_fn, _node) {
		if (__gmlc_opt_real_literal(_node) != undefined) return true;
		if (!__gmlc_opt_is_local(_node)) return false;
		var _defs = { decls: 0, writes: 0, init: undefined };
		__gmlc_opt_count_defs(_fn, _node.name, _defs, true);
		return (_defs.decls == 0) && (_defs.writes == 0);
	};

	#region jsDoc
	/// @func    __fresh(_fn, _name)
	/// @desc    The `array_create` call that is the only definition of a local, or undefined when it has another
	///          definition or none.
	/// @self    GMLC_Opt_LoopInterchange
	/// @param   {Struct.ASTNode} _fn   : The function
	/// @param   {String}         _name : The local
	/// @returns {Struct.ASTCall|Undefined}
	#endregion
	static __fresh = function(_fn, _name) {
		var _defs = { decls: 0, writes: 0, init: undefined };
		__gmlc_opt_count_defs(_fn, _name, _defs, true);
		if (_defs.decls != 1) || (_defs.writes != 0) || (_defs.init == undefined) return undefined;
		if (__gmlc_opt_builtin_call(_defs.init) != "array_create") return undefined;
		return _defs.init;
	};

	#region jsDoc
	/// @func    __element_uses(_node, _name)
	/// @desc    How many element accesses of a local array there are under a node, nested functions left out.
	/// @self    GMLC_Opt_LoopInterchange
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The local
	/// @returns {Real}
	#endregion
	static __element_uses = function(_node, _name) {
		var _n = 0;
		if (_node.kind == __GMLC_NodeKind_Index) && (_node.accessor == "Array") && (__gmlc_opt_is_local(_node.object)) && (_node.object.name == _name) _n = 1;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__gmlc_opt_is_function(_child)) _n += __element_uses(_child, _name);
				}
			_i++}
		_field_index++}
		return _n;
	};
	#endregion

	#endregion
}
