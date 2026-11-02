#region jsDoc
/// @func    GMLC_Opt_ScalarReplaceAggregates()
/// @desc    A struct or array literal held in a local that is only read and written through constant keys becomes one
///          local per field, so nothing is allocated: `var _d = {x: tx - x, y: ty - y}; var _n = _d.x * _d.x + _d.y
///          * _d.y;` becomes `var __gmlc_t0 = tx - x; var __gmlc_t1 = ty - y;` and a sum of those. The local must be
///          declared once, mentioned only after its declaration in the same statement list, and never passed,
///          stored, returned, compared, indexed with a non-constant or read at a key the literal does not have.
/// @returns {Struct.GMLC_Opt_ScalarReplaceAggregates}
#endregion
function GMLC_Opt_ScalarReplaceAggregates() : GMLC_OptimizerPass("scalar-replace-aggregates") constructor {
	#region Config
	// more fields than this are not worth as many locals
	static max_fields = 8;
	#endregion

	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Splits the literals of a function that nothing but constant-key reads and writes use.
	/// @self    GMLC_Opt_ScalarReplaceAggregates
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _plans = [];
		__find(_node, _node, _plans, _cx);
		if (array_length(_plans) == 0) return undefined;
		var _by_name = {};
		var _p = 0; repeat (array_length(_plans)) {
			var _plan = _plans[_p];
			_cx.stats[$ "split"]++;
			_cx.stats[$ "locals_created"] += _plan.size;
			var _f = 0; repeat (_plan.size) {
				array_push(_plan.temps, _cx.optimizer.newTemporary(_cx));
			_f++}
			_by_name[$ _plan.name] = _plan;
		_p++}
		var _new = __gmlc_opt_clone(_node);
		__rewrite(_new, _by_name);
		return _new;
	};
	#endregion

	#region Private
	#region jsDoc
	/// @func    __find(_node, _root, _plans, _cx)
	/// @desc    Collects the declarations to split, in statement order, nested functions left out.
	/// @self    GMLC_Opt_ScalarReplaceAggregates
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Struct.ASTNode} _root  : The function
	/// @param   {Array<Struct>}  _plans : The plans so far, added to
	/// @param   {Struct}         _cx    : The pass context
	#endregion
	static __find = function(_node, _root, _plans, _cx) {
		if (_node != _root) && (__gmlc_opt_is_function(_node)) return;
		if (__gmlc_opt_is_statement_list(_node)) {
			var _body = _node.body;
			var _p = 0; repeat (array_length(_body)) {
				var _plan = __plan(_root, _body, _p, _cx);
				if (_plan != undefined) array_push(_plans, _plan);
			_p++}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__find(_child, _root, _plans, _cx);
				}
			_i++}
		_field_index++}
	};

	#region jsDoc
	/// @func    __plan(_root, _body, _p, _cx)
	/// @desc    The plan for the statement at a position of a statement list, or undefined: `var name = literal;` of a
	///          local declared once, whose every other mention lies in the statements after it and is a read or write
	///          at a key (or index) the literal has.
	/// @self    GMLC_Opt_ScalarReplaceAggregates
	/// @param   {Struct.ASTNode}        _root : The function
	/// @param   {Array<Struct.ASTNode>} _body : The statement list
	/// @param   {Real}                  _p    : The position
	/// @param   {Struct}                _cx   : The pass context
	/// @returns {Struct|Undefined} {name, array, keys, size, temps, length}
	#endregion
	static __plan = function(_root, _body, _p, _cx) {
		var _statement = _body[_p];
		if (_statement.kind != __GMLC_NodeKind_VarDeclList) || (array_length(_statement.declarations) != 1) return undefined;
		var _declaration = _statement.declarations[0];
		var _init = _declaration.init;
		if (_init == undefined) || (_declaration.target.kind != __GMLC_NodeKind_Identifier) return undefined;
		var _name = _declaration.target.name;
		var _shape = __shape(_init);
		if (_shape == undefined) return undefined;
		if (_cx.optimizer.__isNoOp(_statement)) return undefined;
		var _params = _root[$ "params"];
		var _q = 0;
		if (_params != undefined) {
			repeat (array_length(_params)) {
				if (_params[_q].target.name == _name) return undefined;
			_q++}
		}
		if (__gmlc_opt_var_declarations(_root, _name) != 1) return undefined;
		var _later = 0;
		_q = _p + 1; repeat (array_length(_body) - _p - 1) {
			_later += __gmlc_opt_count_mentions(_body[_q], _name);
		_q++}
		if (_later == 0) || (__gmlc_opt_count_mentions(_root, _name) - 1 != _later) return undefined;
		_q = _p + 1; repeat (array_length(_body) - _p - 1) {
			if (!__uses(_body[_q], _name, _shape, _cx)) return undefined;
		_q++}
		var _length = undefined;
		if (_shape.array) {
			_length = _cx.optimizer.__literal(_shape.size, _statement.span);
			if (_length == undefined) return undefined;
		}
		return { name: _name, array: _shape.array, keys: _shape.keys, size: _shape.size, temps: [], length: _length };
	};

	#region jsDoc
	/// @func    __shape(_init)
	/// @desc    What a literal can be split into, or undefined: a struct of distinct keys (array false, keys, size) or an
	///          array (array true, size), with no function literal inside, and at least one and at most `max_fields`
	///          fields.
	/// @self    GMLC_Opt_ScalarReplaceAggregates
	/// @param   {Struct.ASTNode} _init : The literal
	/// @returns {Struct|Undefined} {array, keys, size}
	#endregion
	static __shape = function(_init) {
		if (_init.kind == __GMLC_NodeKind_ArrayLiteral) {
			var _elements = _init.elements;
			var _n = array_length(_elements);
			if (_n == 0) || (_n > max_fields) return undefined;
			var _i = 0; repeat (_n) {
				if (__gmlc_opt_is_or_holds_function(_elements[_i])) return undefined;
			_i++}
			return { array: true, keys: [], size: _n };
		}
		if (_init.kind != __GMLC_NodeKind_StructLiteral) return undefined;
		var _entries = _init.entries;
		var _count = array_length(_entries);
		if (_count == 0) || (_count > max_fields) return undefined;
		var _keys = [];
		var _e = 0; repeat (_count) {
			var _key = _entries[_e].key;
			if (array_contains(_keys, _key)) || (__gmlc_opt_is_or_holds_function(_entries[_e].value)) return undefined;
			array_push(_keys, _key);
		_e++}
		return { array: false, keys: _keys, size: _count };
	};

	#region jsDoc
	/// @func    __slot(_index, _array, _keys, _size)
	/// @desc    Which field an Index node reads or writes: the position of its key in a struct literal (`.key` or
	///          `[$ "key"]`), or its constant index in an array literal; -1 when it has no such field.
	/// @self    GMLC_Opt_ScalarReplaceAggregates
	/// @param   {Struct.ASTIndex} _index : The node
	/// @param   {Bool}            _array : Whether the literal is an array
	/// @param   {Array<String>}   _keys  : The keys of a struct literal
	/// @param   {Real}            _size  : The number of fields
	/// @returns {Real}
	#endregion
	static __slot = function(_index, _array, _keys, _size) {
		if (_array) {
			if (_index.accessor != "Array") || (array_length(_index.keys) != 1) return -1;
			var _key = _index.keys[0];
			if (_key.kind != __GMLC_NodeKind_Literal) || (_key.ty != "real") return -1;
			var _value = _key.value;
			return ((_value >= 0) && (_value < _size) && (floor(_value) == _value)) ? floor(_value) : -1;
		}
		if (_index.accessor == "Dot") return array_get_index(_keys, _index.member);
		if (_index.accessor != "Struct") || (array_length(_index.keys) != 1) return -1;
		var _text = _index.keys[0];
		return ((_text.kind == __GMLC_NodeKind_Literal) && (_text.ty == "string")) ? array_get_index(_keys, _text.value) : -1;
	};

	#region jsDoc
	/// @func    __is_the(_node, _name)
	/// @desc    Whether a node reads the local.
	/// @self    GMLC_Opt_ScalarReplaceAggregates
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The local
	/// @returns {Bool}
	#endregion
	static __is_the = function(_node, _name) {
		return __gmlc_opt_is_local(_node) && (_node.name == _name);
	};

	#region jsDoc
	/// @func    __uses(_node, _name, _shape, _cx)
	/// @desc    Whether every mention of the local under a node is a read or write at a field the literal has, or the
	///          `array_length` of an array literal's local, outside frozen code.
	/// @self    GMLC_Opt_ScalarReplaceAggregates
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {String}         _name  : The local
	/// @param   {Struct}         _shape : The literal's shape {array, keys, size}
	/// @param   {Struct}         _cx    : The pass context
	/// @returns {Bool}
	#endregion
	static __uses = function(_node, _name, _shape, _cx) {
		if (__gmlc_opt_is_function(_node)) return true;
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier:
				return !__is_the(_node, _name);
			case __GMLC_NodeKind_Index:
				if (__is_the(_node.object, _name)) {
					return (__slot(_node, _shape.array, _shape.keys, _shape.size) >= 0) && (!_cx.optimizer.__isNoOp(_node.object));
				}
			break;
			case __GMLC_NodeKind_Call:
				if (_shape.array) && (__gmlc_opt_builtin_call(_node) == "array_length") && (array_length(_node.args) == 1) && __is_the(_node.args[0], _name) {
					return !_cx.optimizer.__isNoOp(_node.args[0]);
				}
			break;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__uses(_child, _name, _shape, _cx)) return false;
				}
			_i++}
		_field_index++}
		return true;
	};

	#region jsDoc
	/// @func    __replacement(_node, _by_name)
	/// @desc    The node that stands for a read or write of a split literal's field, or undefined: the field's local, or
	///          the number of fields for `array_length`.
	/// @self    GMLC_Opt_ScalarReplaceAggregates
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {Struct}         _by_name : Local name to plan
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __replacement = function(_node, _by_name) {
		if (_node.kind == __GMLC_NodeKind_Index) && (_node.object.kind == __GMLC_NodeKind_Identifier) && __gmlc_opt_is_local(_node.object) {
			var _plan = _by_name[$ _node.object.name];
			if (_plan != undefined) {
				var _slot = __slot(_node, _plan.array, _plan.keys, _plan.size);
				if (_slot >= 0) return __gmlc_opt_local(_plan.temps[_slot], _node.span);
			}
		}
		else if (_node.kind == __GMLC_NodeKind_Call) && (array_length(_node.args) == 1) && (__gmlc_opt_builtin_call(_node) == "array_length") && __gmlc_opt_is_local(_node.args[0]) {
			var _listed = _by_name[$ _node.args[0].name];
			if (_listed != undefined) && (_listed.array) {
				var _length = __gmlc_opt_clone(_listed.length);
				_length.span = _node.span;
				return _length;
			}
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __rewrite(_node, _by_name)
	/// @desc    Rewrites a copy in place, nested functions left out: each field access becomes its local, and each
	///          split declaration becomes one declaration per field, in the order the fields were written.
	/// @self    GMLC_Opt_ScalarReplaceAggregates
	/// @param   {Struct.ASTNode} _node    : The node, a copy this pass owns
	/// @param   {Struct}         _by_name : Local name to plan
	#endregion
	static __rewrite = function(_node, _by_name) {
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			if (!__gmlc_opt_is_function(_slot.node)) {
				__rewrite(_slot.node, _by_name);
				var _new = __replacement(_slot.node, _by_name);
				if (_new != undefined) {
					if (_slot.index == undefined) {
						_slot.parent[$ _slot.key] = _new;
					}
					else {
						_slot.parent[$ _slot.key][_slot.index] = _new;
					}
				}
			}
		_i++}
		if (!__gmlc_opt_is_statement_list(_node)) return;
		var _body = [];
		var _old = _node.body;
		var _s = 0; repeat (array_length(_old)) {
			var _statement = _old[_s];
			var _plan = undefined;
			if (_statement.kind == __GMLC_NodeKind_VarDeclList) && (array_length(_statement.declarations) == 1) && (_statement.declarations[0].target.kind == __GMLC_NodeKind_Identifier) {
				_plan = _by_name[$ _statement.declarations[0].target.name];
			}
			if (_plan == undefined) {
				array_push(_body, _statement);
			}
			else {
				var _init = _statement.declarations[0].init;
				var _values = _plan.array ? _init.elements : array_create(0);
				if (!_plan.array) {
					var _e = 0; repeat (_plan.size) {
						array_push(_values, _init.entries[_e].value);
					_e++}
				}
				var _f = 0; repeat (_plan.size) {
					array_push(_body, __gmlc_opt_var(_plan.temps[_f], _values[_f], _statement.span));
				_f++}
			}
		_s++}
		_node.body = _body;
	};
	#endregion
}
