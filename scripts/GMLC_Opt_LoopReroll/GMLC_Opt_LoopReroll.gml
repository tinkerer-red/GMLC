#region jsDoc
/// @func    GMLC_Opt_LoopReroll()
/// @desc    Turns a hand-unrolled loop back into a loop of step 1: a `for` with a literal range and step k whose body
///          is the same statement written for `i`, `i + 1`, ... `i + k - 1` becomes one statement run for every `i`.
///          Bodies that differ in anything but the offset, and ranges that are not a multiple of k, stay.
///          `for (var i = 0; i < 8; i += 2) { a[i] = 1; a[i + 1] = 1; }` becomes
///          `for (var i = 0; i < 8; i++) { a[i] = 1; }`.
/// @returns {Struct.GMLC_Opt_LoopReroll}
#endregion
function GMLC_Opt_LoopReroll() : GMLC_OptimizerPass("loop-reroll") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The node to put in the place of _node, or undefined to keep it.
	/// @self    GMLC_Opt_LoopReroll
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		return __rewrite(_node, _cx, true);
	};
	#endregion

	#region Private
	#region Walk
	#region jsDoc
	/// @func    __rewrite(_node, _cx, _is_root)
	/// @desc    Rewrites the statement lists under a node, inner ones first, nested functions left out.
	/// @self    GMLC_Opt_LoopReroll
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {Struct}         _cx      : The pass context
	/// @param   {Bool}           _is_root : Whether the node is the function itself
	/// @returns {Struct.ASTNode|Undefined} A changed copy, or undefined
	#endregion
	static __rewrite = function(_node, _cx, _is_root) {
		if (!_is_root) && (__gmlc_opt_is_function(_node)) return undefined;
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
						var _item = __rewrite(_value[_j], _cx, false);
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
				var _child = __rewrite(_value, _cx, false);
				if (_child != undefined) {
					_copy ??= variable_clone(_node, 0);
					_copy[$ _key] = _child;
				}
			}
		_f++}
		var _kind = _node.kind;
		if (_kind == __GMLC_NodeKind_Script) || (_kind == __GMLC_NodeKind_Block) || (_kind == __GMLC_NodeKind_Case) || (_kind == __GMLC_NodeKind_Default) {
			var _body = (_copy ?? _node).body;
			var _new_body = __list(_body, _cx);
			if (_new_body != undefined) {
				_copy ??= variable_clone(_node, 0);
				_copy.body = _new_body;
			}
		}
		return _copy;
	};

	#region jsDoc
	/// @func    __list(_body, _cx)
	/// @desc    Rerolls the loops of a statement list.
	/// @self    GMLC_Opt_LoopReroll
	/// @param   {Array<Struct.ASTNode>} _body : The statements
	/// @param   {Struct}                _cx   : The pass context
	/// @returns {Array<Struct.ASTNode>|Undefined} The new statements, or undefined
	#endregion
	static __list = function(_body, _cx) {
		var _out = undefined;
		var _count = array_length(_body);
		var _i = 0; repeat (_count) {
			if (_body[_i].kind == __GMLC_NodeKind_For) {
				var _new = __reroll(_body[_i], _cx);
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

	#region Loops
	#region jsDoc
	/// @func    __reroll(_for, _cx)
	/// @desc    The step-1 loop for a `for` whose body holds k copies of one statement, or undefined.
	/// @self    GMLC_Opt_LoopReroll
	/// @param   {Struct.ASTFor} _for : The loop
	/// @param   {Struct}        _cx  : The pass context
	/// @returns {Struct.ASTFor|Undefined}
	#endregion
	static __reroll = function(_for, _cx) {
		if (_cx.optimizer.__containsNoOp(_for)) return undefined;
		var _loop = __gmlc_opt_counted_header(_for);
		if (_loop == undefined) || (_loop.cmp != "<") return undefined;
		var _from = __gmlc_opt_real_literal(_loop.start);
		var _to = __gmlc_opt_real_literal(_loop.bound);
		var _k = _loop.step;
		if (_from == undefined) || (_to == undefined) return undefined;
		if (_k < 2) || (_k > 64) || (_k != floor(_k)) || (_from != floor(_from)) || (_to != floor(_to)) return undefined;
		if (_to <= _from) || (((_to - _from) mod _k) != 0) return undefined;
		var _block = _for.body;
		if (_block.kind != __GMLC_NodeKind_Block) || (array_length(_block.body) != _k) return undefined;
		var _first = _block.body[0];
		if (__blocked(_first)) || (__gmlc_opt_writes(_first, _loop.name)) || (__gmlc_opt_reads(_first, _loop.name) == 0) return undefined;
		var _m = 1; repeat (_k - 1) {
			var _template = __gmlc_opt_clone(_first);
			_template = __shift(_template, _loop.name, _m, _cx);
			if (_template == undefined) || (!__gmlc_opt_same(_block.body[_m], _template)) return undefined;
		_m++}
		var _update = _for.update;
		var _step = new ASTExprStmt(_update.span, new ASTUpdate(_update.span, "++", false, __gmlc_opt_clone(_for.test.left)));
		_cx.stats[$ "rerolled"]++;
		return new ASTFor(_for.span, _for.init, _for.test, _step, new ASTBlock(_block.span, [_first], _block.origin), _for.origin);
	};

	#endregion

	#region Tree
	#region jsDoc
	/// @func    __blocked(_node)
	/// @desc    Whether a statement holds anything that makes copies of it differ from one run to the next: a `break`,
	///          a `continue`, a declaration or a function.
	/// @self    GMLC_Opt_LoopReroll
	/// @param   {Struct.ASTNode} _node : The statement
	/// @returns {Bool}
	#endregion
	static __blocked = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Break:
			case __GMLC_NodeKind_Continue:
			case __GMLC_NodeKind_VarDeclList:
			case __GMLC_NodeKind_StaticDecl:
			case __GMLC_NodeKind_GlobalVarDecl:
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr:
			return true;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__blocked(_child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};

	#region jsDoc
	/// @func    __shift(_node, _name, _offset, _cx)
	/// @desc    Writes `_name + _offset` for every read of a local under a node, in place (the node is a copy).
	/// @self    GMLC_Opt_LoopReroll
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {String}         _name   : The local
	/// @param   {Real}           _offset : The offset
	/// @param   {Struct}         _cx     : The pass context
	/// @returns {Struct.ASTNode|Undefined} The node to hold in its place, undefined when a literal cannot be written
	#endregion
	static __shift = function(_node, _name, _offset, _cx) {
		if (__gmlc_opt_is_local(_node)) {
			if (_node.name != _name) return _node;
			var _literal = _cx.optimizer.__literal(_offset, _node.span);
			if (_literal == undefined) return undefined;
			return new ASTBinary(_node.span, "+", _node, _literal);
		}
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new = __shift(_slot.node, _name, _offset, _cx);
			if (_new == undefined) return undefined;
			if (_new != _slot.node) {
				if (_slot.index == undefined) {
					_slot.parent[$ _slot.key] = _new;
				}
				else {
					_slot.parent[$ _slot.key][_slot.index] = _new;
				}
			}
		_i++}
		return _node;
	};
	#endregion
	#endregion
}
