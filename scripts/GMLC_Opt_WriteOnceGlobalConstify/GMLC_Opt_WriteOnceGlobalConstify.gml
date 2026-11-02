#region jsDoc
/// @func    GMLC_Opt_WriteOnceGlobalConstify()
/// @desc    The `write-once-global-constify` optimizer pass: a static set once to a literal and never written is
///          replaced by the literal where it is read. Any other file can reach a global variable or the statics of a
///          function the file declares by name or by reflection, so only the statics of a function literal held in
///          a local that is only ever called can be proven constant from this file alone.
///          `var f = function() { static n = 32; return n * 2; };` becomes
///          `var f = function() { static n = 32; return 32 * 2; };`.
/// @returns {Struct.GMLC_Opt_WriteOnceGlobalConstify}
#endregion
function GMLC_Opt_WriteOnceGlobalConstify() : GMLC_OptimizerPass("write-once-global-constify") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    A copy of the file with the constant statics replaced where they are read, or undefined when there
	///          are none.
	/// @self    GMLC_Opt_WriteOnceGlobalConstify
	/// @param   {Struct.ASTNode} _node : The function; the file's Script for fn_id 0
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (_cx.unit.fn_id != 0) || (_node.kind != __GMLC_NodeKind_Script) return undefined;
		var _owners = __gmlc_opt_function_owners(_node);
		var _found = false;
		var _o = 0; repeat (array_length(_owners)) {
			if (array_length(__plan(_owners[_o], _cx)) > 0) {
				_found = true;
				break;
			}
		_o++}
		if (!_found) return undefined;
		var _copy = __gmlc_opt_clone(_node);
		_owners = __gmlc_opt_function_owners(_copy);
		var _p = array_length(_owners) - 1; repeat (array_length(_owners)) {
			var _plans = __plan(_owners[_p], _cx);
			if (array_length(_plans) > 0) __rewrite(_plans, _cx);
		_p--}
		return _copy;
	};
	#endregion
	
	#region Private
	#region Planning
	#region jsDoc
	/// @func    __plan(_owner, _cx)
	/// @desc    The constant statics of the functions a unit holds in locals.
	/// @self    GMLC_Opt_WriteOnceGlobalConstify
	/// @param   {Struct.ASTNode} _owner : The Script or a function node
	/// @param   {Struct}         _cx    : The pass context
	/// @returns {Array<Struct>}
	#endregion
	static __plan = function(_owner, _cx) {
		var _state = __gmlc_opt_candidate_scan(_owner, _cx, {}, false);
		var _plans = [];
		var _c = 0; repeat (array_length(_state.order)) {
			var _candidate = _state.order[_c];
			if (__gmlc_opt_candidate_calls_only(_candidate)) && (!_cx.optimizer.__isNoOp(_candidate.declarator.init)) {
				var _statics = __constantStatics(_candidate.declarator.init, _cx);
				if (array_length(_statics) > 0) array_push(_plans, { fn: _candidate.declarator.init, statics: _statics });
			}
		_c++}
		return _plans;
	};
	
	#region jsDoc
	/// @func    __constantStatics(_fn, _cx)
	/// @desc    The statics of a function that are declared once with a literal, never written, and read where the
	///          literal can stand.
	/// @self    GMLC_Opt_WriteOnceGlobalConstify
	/// @param   {Struct.ASTFunctionExpr} _fn : The function
	/// @param   {Struct}                 _cx : The pass context
	/// @returns {Array<Struct>} {name, value}
	#endregion
	static __constantStatics = function(_fn, _cx) {
		var _found = [];
		__collectStatics(_fn.body, _cx, _found);
		var _out = [];
		var _s = 0; repeat (array_length(_found)) {
			var _static = _found[_s];
			if (_static.count == 1) && (_static.value != undefined) && (!_static.frozen) {
				var _walk = { name: _static.name, reads: 0, ok: true, cx: _cx };
				var _p = 0; repeat (array_length(_fn.params)) {
					var _default = _fn.params[_p][$ "default"];
					if (_default != undefined) __roles(_default, _fn.params[_p], _walk);
				_p++}
				__roles(_fn.body, _fn, _walk);
				if (_walk.ok) && (_walk.reads > 0) array_push(_out, { name: _static.name, value: _static.value });
			}
		_s++}
		return _out;
	};
	
	#region jsDoc
	/// @func    __collectStatics(_node, _cx, _out)
	/// @desc    Lists the statics declared under a node with how many times each is declared and the literal it
	///          starts as, nested functions left out.
	/// @self    GMLC_Opt_WriteOnceGlobalConstify
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _cx   : The pass context
	/// @param   {Array<Struct>}  _out  : {name, count, value, frozen}
	#endregion
	static __collectStatics = function(_node, _cx, _out) {
		if (__gmlc_opt_is_function(_node)) return;
		if (_node.kind == __GMLC_NodeKind_StaticDecl) {
			var _d = 0; repeat (array_length(_node.declarations)) {
				var _decl = _node.declarations[_d];
				var _name = _decl.target.name;
				var _entry = undefined;
				var _e = 0; repeat (array_length(_out)) {
					if (_out[_e].name == _name) _entry = _out[_e];
				_e++}
				if (_entry == undefined) {
					_entry = { name: _name, count: 0, value: undefined, frozen: false };
					array_push(_out, _entry);
				}
				_entry.count++;
				if (_entry.count == 1) && (_decl.init != undefined) && (_decl.init.kind == __GMLC_NodeKind_Literal) && (_decl.init.origin == undefined) _entry.value = _decl.init;
				if (_cx.optimizer.__isNoOp(_decl)) _entry.frozen = true;
			_d++}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__collectStatics(_child, _cx, _out);
				}
			_i++}
		_field_index++}
	};
	
	#region jsDoc
	/// @func    __roles(_node, _parent, _walk)
	/// @desc    Counts the reads of a static under a node and clears ok when one is where a literal cannot stand:
	///          written, frozen, called, the object of an accessor or method call. A declaration's name is not a
	///          read.
	/// @self    GMLC_Opt_WriteOnceGlobalConstify
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct.ASTNode} _parent : Its parent
	/// @param   {Struct}         _walk   : {name, reads, ok, cx}
	#endregion
	static __roles = function(_node, _parent, _walk) {
		if (__gmlc_opt_is_function(_node)) return;
		if (_node.kind == __GMLC_NodeKind_StaticDecl) {
			var _d = 0; repeat (array_length(_node.declarations)) {
				var _init = _node.declarations[_d].init;
				if (_init != undefined) __roles(_init, _node.declarations[_d], _walk);
			_d++}
			return;
		}
		if (_node.kind == __GMLC_NodeKind_Identifier) {
			if (_node.symbol != undefined) && (_node.symbol.kind == "Static") && (_node.name == _walk.name) {
				_walk.reads++;
				if (_walk.cx.optimizer.__isNoOp(_node)) _walk.ok = false;
				switch (_parent.kind) {
					case __GMLC_NodeKind_Assign: if (_parent.target == _node) _walk.ok = false; break;
					case __GMLC_NodeKind_Call: if (_parent.callee == _node) _walk.ok = false; break;
					case __GMLC_NodeKind_New: if (_parent.callee == _node) _walk.ok = false; break;
					case __GMLC_NodeKind_MethodCall: if (_parent.object == _node) _walk.ok = false; break;
					case __GMLC_NodeKind_Index: if (_parent.object == _node) _walk.ok = false; break;
					case __GMLC_NodeKind_Update:
					case __GMLC_NodeKind_Delete:
						_walk.ok = false;
					break;
				}
			}
			return;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__roles(_child, _node, _walk);
				}
			_i++}
		_field_index++}
	};
	#endregion
	
	#region Rewriting
	#region jsDoc
	/// @func    __rewrite(_plans, _cx)
	/// @desc    Puts the literals in the place of the reads of the planned statics. The declarations stay.
	/// @self    GMLC_Opt_WriteOnceGlobalConstify
	/// @param   {Array<Struct>} _plans : What __plan found
	/// @param   {Struct}        _cx    : The pass context
	#endregion
	static __rewrite = function(_plans, _cx) {
		var _p = 0; repeat (array_length(_plans)) {
			var _plan = _plans[_p];
			var _s = 0; repeat (array_length(_plan.statics)) {
				__substitute(_plan.fn, _plan.statics[_s].name, _plan.statics[_s].value, _cx);
			_s++}
		_p++}
	};
	
	#region jsDoc
	/// @func    __substitute(_node, _name, _value, _cx)
	/// @desc    Puts a copy of a literal in the place of every read of a static under a node, nested functions and
	///          declared names left out.
	/// @self    GMLC_Opt_WriteOnceGlobalConstify
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {String}         _name  : The static
	/// @param   {Struct.ASTNode} _value : The literal
	/// @param   {Struct}         _cx    : The pass context
	#endregion
	static __substitute = function(_node, _name, _value, _cx) {
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _child = _slot.node;
			if (!__gmlc_opt_is_function(_child)) && ((_node.kind != __GMLC_NodeKind_VarDecl) || (_slot.key != "target")) {
				if (_child.kind == __GMLC_NodeKind_Identifier) {
					if (_child.symbol != undefined) && (_child.symbol.kind == "Static") && (_child.name == _name) {
						var _copy = __gmlc_opt_clone(_value);
						_copy.span = _child.span;
						_cx.stats[$ "reads_replaced"]++;
						if (_slot.index == undefined) {
							_slot.parent[$ _slot.key] = _copy;
						}
						else {
							_slot.parent[$ _slot.key][_slot.index] = _copy;
						}
					}
				}
				else {
					__substitute(_child, _name, _value, _cx);
				}
			}
		_i++}
	};
	#endregion
	
	#endregion
}
