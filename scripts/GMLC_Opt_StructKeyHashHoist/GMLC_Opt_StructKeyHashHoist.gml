#region jsDoc
/// @func    GMLC_Opt_StructKeyHashHoist()
/// @desc    Hashes a struct key once before a long loop that reads a field by that key on every pass:
///          `repeat (100) { total += _s[$ _key]; }` becomes `var __gmlc_t0 = variable_get_hash(_key); repeat (100) {
///          total += struct_get_from_hash(_s, __gmlc_t0); }`. It applies only to a `repeat` or counting `for` loop with a
///          literal trip count of at least `__minimum_trips`, to reads of a local that is proven to hold a struct by a
///          key local that is proven to hold a string, was set to one before the loop and is not written in it.
/// @returns {Struct.GMLC_Opt_StructKeyHashHoist}
#endregion
function GMLC_Opt_StructKeyHashHoist() : GMLC_OptimizerPass("struct-key-hash-hoist") constructor {
	#region Config
	static __minimum_trips = 64;
	#endregion

	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The node to put in the place of _node, or undefined to keep it.
	/// @self    GMLC_Opt_StructKeyHashHoist
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (!_cx.env.isFunction("variable_get_hash")) || (!_cx.env.isFunction("struct_get_from_hash")) return undefined;
		var _kinds = __gmlc_opt_string_kinds(_node);
		if (!__any(_kinds, "string")) || (!__any(_kinds, "struct")) return undefined;
		return __gmlc_opt_rewrite_lists(_node, _cx, true, method(self, __list), _kinds);
	};
	#endregion

	#region Private
	#region Rewrite
	#region jsDoc
	/// @func    __list(_stmts, _cx, _kinds)
	/// @desc    Puts the hash of the key before every loop of a statement list that qualifies and reads its fields by
	///          the hash.
	/// @self    GMLC_Opt_StructKeyHashHoist
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
				array_push(_out, _plan[0]);
				array_push(_out, _plan[1]);
			}
			else if (_out != undefined) {
				array_push(_out, _stmts[_i]);
			}
		_i++}
		return _out;
	};

	#region jsDoc
	/// @func    __plan(_stmts, _at, _cx, _kinds)
	/// @desc    The declaration of the hash and the loop rewritten, or undefined when the loop does not qualify: a
	///          `repeat` or `for` loop with a literal trip count of at least the minimum that reads a field of a struct
	///          local by a string local which an earlier statement of the list set to a string and the loop does not
	///          write. Every such read in the loop by that key becomes `struct_get_from_hash(struct, hash)`.
	/// @self    GMLC_Opt_StructKeyHashHoist
	/// @param   {Array<Struct.ASTNode>} _stmts : The statement list
	/// @param   {Real}                  _at    : The index of the loop
	/// @param   {Struct}                _cx    : The pass context
	/// @param   {Struct}                _kinds : What is proven about the function's locals
	/// @returns {Array<Struct.ASTNode>|Undefined} [declaration, loop]
	#endregion
	static __plan = function(_stmts, _at, _cx, _kinds) {
		var _loop = _stmts[_at];
		if (__gmlc_opt_loop_trips(_loop) < __minimum_trips) || (_cx.optimizer.__isNoOp(_loop)) return undefined;
		var _found = __find(_loop, undefined, _kinds, _cx, false);
		if (_found == undefined) return undefined;
		var _key = _found.keys[0].name;
		if (__gmlc_opt_writes(_loop, _key)) || (!__gmlc_opt_string_initialized(_stmts, _at, _key)) return undefined;
		var _span = _loop.span;
		var _hash = _cx.optimizer.newTemporary(_cx);
		var _call = new ASTCall(_span, _cx.optimizer.__builtin("variable_get_hash", _span), [__gmlc_opt_clone(_found.keys[0])]);
		var _new_loop = __reads(_loop, _key, _hash, _kinds, _cx, false);
		_cx.stats[$ "hoisted"]++;
		return [__gmlc_opt_var(_hash, _call, _span), _new_loop];
	};

	#region jsDoc
	/// @func    __reads(_node, _key, _hash, _kinds, _cx, _write)
	/// @desc    A node with every read of a field of a struct local by a key local turned into a read by the hash
	///          temporary, or undefined when it holds none. Targets of assignments, increments and `delete` stay.
	/// @self    GMLC_Opt_StructKeyHashHoist
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {String}         _key   : The key local
	/// @param   {String}         _hash  : The temporary that holds the hash
	/// @param   {Struct}         _kinds : What is proven about the function's locals
	/// @param   {Struct}         _cx    : The pass context
	/// @param   {Bool}           _write : Whether the node is written, not read
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __reads = function(_node, _key, _hash, _kinds, _cx, _write) {
		if (__gmlc_opt_is_function(_node)) || (_cx.optimizer.__isNoOp(_node)) return undefined;
		if (!_write) && (__matches(_node, _key, _kinds)) {
			return new ASTCall(_node.span, _cx.optimizer.__builtin("struct_get_from_hash", _node.span), [_node.object, __gmlc_opt_local(_hash, _node.span)]);
		}
		var _slots = _node.childSlots();
		var _news = undefined;
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _target = ((_node.kind == __GMLC_NodeKind_Assign) && (_slot.key == "target")) || ((_node.kind == __GMLC_NodeKind_Update) && (_slot.key == "argument")) || ((_node.kind == __GMLC_NodeKind_Delete) && (_slot.key == "target"));
			var _new = __reads(_slot.node, _key, _hash, _kinds, _cx, _target);
			if (_new != undefined) {
				if (_news == undefined) _news = array_create(array_length(_slots), undefined);
				_news[_i] = _new;
			}
		_i++}
		return (_news != undefined) ? __gmlc_opt_rebuilt(_node, _slots, _news) : undefined;
	};
	#endregion

	#region Questions
	#region jsDoc
	/// @func    __find(_node, _key, _kinds, _cx, _write)
	/// @desc    The first read under a node of a field of a struct local by a string local, or of one by the given key.
	/// @self    GMLC_Opt_StructKeyHashHoist
	/// @param   {Struct.ASTNode}  _node  : The node
	/// @param   {String|Undefined} _key  : The key local, undefined for any
	/// @param   {Struct}          _kinds : What is proven about the function's locals
	/// @param   {Struct}          _cx    : The pass context
	/// @param   {Bool}            _write : Whether the node is written, not read
	/// @returns {Struct.ASTIndex|Undefined}
	#endregion
	static __find = function(_node, _key, _kinds, _cx, _write) {
		if (__gmlc_opt_is_function(_node)) || (_cx.optimizer.__isNoOp(_node)) return undefined;
		if (!_write) && (__matches(_node, _key, _kinds)) return _node;
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _target = ((_node.kind == __GMLC_NodeKind_Assign) && (_slot.key == "target")) || ((_node.kind == __GMLC_NodeKind_Update) && (_slot.key == "argument")) || ((_node.kind == __GMLC_NodeKind_Delete) && (_slot.key == "target"));
			var _found = __find(_slot.node, _key, _kinds, _cx, _target);
			if (_found != undefined) return _found;
		_i++}
		return undefined;
	};

	#region jsDoc
	/// @func    __matches(_node, _key, _kinds)
	/// @desc    Whether a node is `struct[$ key]` for a struct local and a string local, by the given key when there is
	///          one.
	/// @self    GMLC_Opt_StructKeyHashHoist
	/// @param   {Struct.ASTNode}   _node  : The node
	/// @param   {String|Undefined} _key   : The key local, undefined for any
	/// @param   {Struct}           _kinds : What is proven about the function's locals
	/// @returns {Bool}
	#endregion
	static __matches = function(_node, _key, _kinds) {
		if (_node.kind != __GMLC_NodeKind_Index) || (_node.accessor != "Struct") || (array_length(_node.keys) != 1) return false;
		var _object = _node.object;
		var _name = _node.keys[0];
		if (!__gmlc_opt_is_local(_object)) || (_kinds[$ _object.name] != "struct") return false;
		if (!__gmlc_opt_is_local(_name)) || (_kinds[$ _name.name] != "string") return false;
		return (_key == undefined) || (_name.name == _key);
	};

	#endregion

	#region Proven types
	#region jsDoc
	/// @func    __any(_kinds, _type)
	/// @desc    Whether any local is proven to hold a type.
	/// @self    GMLC_Opt_StructKeyHashHoist
	/// @param   {Struct} _kinds : What is proven about the locals
	/// @param   {String} _type  : "string" or "struct"
	/// @returns {Bool}
	#endregion
	static __any = function(_kinds, _type) {
		var _names = struct_get_names(_kinds);
		var _i = 0; repeat (array_length(_names)) {
			if (_kinds[$ _names[_i]] == _type) return true;
		_i++}
		return false;
	};
	#endregion
	#endregion
}
