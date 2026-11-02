#region jsDoc
/// @func    GMLC_Opt_FunctionSpecialization()
/// @desc    The `function-specialization` optimizer pass: a parameter that every call passes the same constant (a
///          literal, or the name of a function the file declares) is replaced by that constant in the function and
///          taken out of the calls, so the body can fold on it and a callback parameter becomes a direct call.
///          It only follows a function literal held in a local that is only ever called, since nothing else in
///          the file can name it; a function that is called with different constants is not cloned.
///          `var f = function(a, mode) { return mode ? a : -a; }; f(1, true); f(2, true);` becomes
///          `var f = function(a) { return true ? a : -a; }; f(1); f(2);`.
/// @returns {Struct.GMLC_Opt_FunctionSpecialization}
#endregion
function GMLC_Opt_FunctionSpecialization() : GMLC_OptimizerPass("function-specialization") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    A copy of the file with the constant parameters replaced, or undefined when there are none.
	/// @self    GMLC_Opt_FunctionSpecialization
	/// @param   {Struct.ASTNode} _node : The function; the file's Script for fn_id 0
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (_cx.unit.fn_id != 0) || (_node.kind != __GMLC_NodeKind_Script) return undefined;
		var _names = __gmlc_opt_function_names(_node);
		var _owners = __gmlc_opt_function_owners(_node);
		var _found = false;
		var _o = 0; repeat (array_length(_owners)) {
			if (array_length(__plan(_owners[_o], _node, _cx, _names)) > 0) {
				_found = true;
				break;
			}
		_o++}
		if (!_found) return undefined;
		var _copy = __gmlc_opt_clone(_node);
		_owners = __gmlc_opt_function_owners(_copy);
		var _p = array_length(_owners) - 1; repeat (array_length(_owners)) {
			var _plans = __plan(_owners[_p], _copy, _cx, _names);
			if (array_length(_plans) > 0) __rewrite(_owners[_p], _plans, _cx);
		_p--}
		return _copy;
	};
	#endregion
	
	#region Private
	#region Planning
	#region jsDoc
	/// @func    __plan(_owner, _script, _cx, _names)
	/// @desc    The constant parameters of the functions a unit holds in locals.
	/// @self    GMLC_Opt_FunctionSpecialization
	/// @param   {Struct.ASTNode}   _owner  : The Script or a function node
	/// @param   {Struct.ASTScript} _script : The file
	/// @param   {Struct}           _cx     : The pass context
	/// @param   {Struct}           _names  : The functions of the file
	/// @returns {Array<Struct>}
	#endregion
	static __plan = function(_owner, _script, _cx, _names) {
		var _state = __gmlc_opt_candidate_scan(_owner, _cx, _names, true);
		var _plans = [];
		var _c = 0; repeat (array_length(_state.order)) {
			var _plan = __planFunction(_state.order[_c], _script, _cx);
			if (_plan != undefined) array_push(_plans, _plan);
		_c++}
		return _plans;
	};
	
	#region jsDoc
	/// @func    __planFunction(_candidate, _script, _cx)
	/// @desc    The parameters of one function that every call gives the same constant, highest first.
	/// @self    GMLC_Opt_FunctionSpecialization
	/// @param   {Struct}           _candidate   : The candidate
	/// @param   {Struct.ASTScript} _script : The file
	/// @param   {Struct}           _cx     : The pass context
	/// @returns {Struct|Undefined}
	#endregion
	static __planFunction = function(_candidate, _script, _cx) {
		if (!__gmlc_opt_candidate_calls_only(_candidate)) || (array_length(_candidate.uses) == 0) return undefined;
		var _fn = _candidate.declarator.init;
		var _info = __gmlc_opt_function_entry(_fn, _script);
		if (_info == undefined) || (_cx.optimizer.__isNoOp(_fn)) return undefined;
		var _subs = [];
		var _k = array_length(_fn.params) - 1; repeat (array_length(_fn.params)) {
			var _value = __uniform(_fn, _k, _candidate.uses, _cx);
			if (_value != undefined) array_push(_subs, { index: _k, name: _fn.params[_k].target.name, value: _value });
		_k--}
		if (array_length(_subs) == 0) return undefined;
		return { candidate: _candidate, fn: _fn, info: _info, subs: _subs };
	};
	
	#region jsDoc
	/// @func    __uniform(_fn, _k, _uses, _cx)
	/// @desc    The constant every call passes for a parameter, when the function only reads the parameter where
	///          the constant can stand; otherwise undefined.
	/// @self    GMLC_Opt_FunctionSpecialization
	/// @param   {Struct.ASTFunctionExpr} _fn   : The function
	/// @param   {Real}                   _k    : The parameter's position
	/// @param   {Array<Struct>}          _uses : The calls
	/// @param   {Struct}                 _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __uniform = function(_fn, _k, _uses, _cx) {
		var _param = _fn.params[_k];
		if (_param[$ "default"] != undefined) return undefined;
		var _first = undefined;
		var _i = 0; repeat (array_length(_uses)) {
			var _args = _uses[_i].args;
			if (array_length(_args) <= _k) return undefined;
			var _constant = _args[_k].constant;
			if (_constant == undefined) return undefined;
			if (_first == undefined) {
				_first = _constant;
			}
			else if (!__gmlc_opt_same(_first, _constant)) {
				return undefined;
			}
		_i++}
		var _walk = { name: _param.target.name, literal: (_first.kind != __GMLC_NodeKind_Identifier) || (_first.symbol.kind != "Global"), reads: 0, ok: true, cx: _cx };
		var _p = 0; repeat (array_length(_fn.params)) {
			var _default = _fn.params[_p][$ "default"];
			if (_default != undefined) __roles(_default, _fn.params[_p], _walk);
		_p++}
		__roles(_fn.body, _fn, _walk);
		return (_walk.ok && (_walk.reads > 0)) ? _first : undefined;
	};
	
	#region jsDoc
	/// @func    __roles(_node, _parent, _walk)
	/// @desc    Counts the reads of a local under a node and clears ok when one is where the constant cannot
	///          stand: written, declared again, frozen, the object of an accessor or method call, or called when
	///          the constant is a literal.
	/// @self    GMLC_Opt_FunctionSpecialization
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct.ASTNode} _parent : Its parent
	/// @param   {Struct}         _walk   : {name, literal, reads, ok, cx}
	#endregion
	static __roles = function(_node, _parent, _walk) {
		if (__gmlc_opt_is_function(_node)) return;
		if (__gmlc_opt_is_local(_node)) {
			if (_node.name == _walk.name) {
				_walk.reads++;
				if (_walk.cx.optimizer.__isNoOp(_node)) _walk.ok = false;
				switch (_parent.kind) {
					case __GMLC_NodeKind_Assign: if (_parent.target == _node) _walk.ok = false; break;
					case __GMLC_NodeKind_Call: if (_parent.callee == _node) && (_walk.literal) _walk.ok = false; break;
					case __GMLC_NodeKind_New: if (_parent.callee == _node) _walk.ok = false; break;
					case __GMLC_NodeKind_MethodCall: if (_parent.object == _node) _walk.ok = false; break;
					case __GMLC_NodeKind_Index: if (_parent.object == _node) _walk.ok = false; break;
					case __GMLC_NodeKind_Update:
					case __GMLC_NodeKind_Delete:
					case __GMLC_NodeKind_Try:
					case __GMLC_NodeKind_VarDecl:
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
	/// @func    __rewrite(_owner, _plans, _cx)
	/// @desc    Puts the constants into their functions, and takes the parameters out of the functions and calls.
	/// @self    GMLC_Opt_FunctionSpecialization
	/// @param   {Struct.ASTNode} _owner : The Script or a function node
	/// @param   {Array<Struct>}  _plans : What __plan found
	/// @param   {Struct}         _cx    : The pass context
	#endregion
	static __rewrite = function(_owner, _plans, _cx) {
		var _list = __gmlc_opt_owner_statements(_owner);
		var _p = 0; repeat (array_length(_plans)) {
			var _plan = _plans[_p];
			var _fn = _plan.fn;
			var _remove = [];
			var _k = 0; repeat (array_length(_plan.subs)) {
				var _sub = _plan.subs[_k];
				array_delete(_fn.params, _sub.index, 1);
				array_delete(_plan.info.params, _sub.index, 1);
				__substitute(_fn, _sub.name, _sub.value);
				_cx.stats[$ "parameters_specialized"]++;
				__gmlc_opt_shift_slots(_fn, _sub.index);
				array_push(_remove, _sub.index);
			_k++}
			var _i = 0; repeat (array_length(_list)) {
				__gmlc_opt_edit_calls(_list[_i], _plan.candidate.name, _remove);
			_i++}
		_p++}
	};
	
	#region jsDoc
	/// @func    __substitute(_node, _name, _value)
	/// @desc    Puts a copy of a constant in the place of every read of a local under a node, nested functions left
	///          out.
	/// @self    GMLC_Opt_FunctionSpecialization
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {String}         _name  : The local
	/// @param   {Struct.ASTNode} _value : The constant
	#endregion
	static __substitute = function(_node, _name, _value) {
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _child = _slot.node;
			if (!__gmlc_opt_is_function(_child)) {
				if (__gmlc_opt_is_local(_child)) {
					if (_child.name == _name) {
						var _copy = __gmlc_opt_clone(_value);
						_copy.span = _child.span;
						if (_slot.index == undefined) {
							_slot.parent[$ _slot.key] = _copy;
						}
						else {
							_slot.parent[$ _slot.key][_slot.index] = _copy;
						}
					}
				}
				else {
					__substitute(_child, _name, _value);
				}
			}
		_i++}
	};
	
	#endregion
	
	#endregion
}
