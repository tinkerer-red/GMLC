#region jsDoc
/// @func    GMLC_Opt_DeadArgumentAndReturnElimination()
/// @desc    The `dead-argument-and-return-elimination` optimizer pass: a parameter a function never mentions is taken
///          out of the function and out of every call, and a return value nobody uses becomes a plain `return;`.
///          It only follows a function literal held in a local that is only ever called, since nothing else in the
///          file can name it: a function the file declares is reachable from other files.
///          `var f = function(a, b) { return a; }; f(1, 2);` becomes `var f = function(a) { return; }; f(1);`.
/// @returns {Struct.GMLC_Opt_DeadArgumentAndReturnElimination}
#endregion
function GMLC_Opt_DeadArgumentAndReturnElimination() : GMLC_OptimizerPass("dead-argument-and-return-elimination") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    A copy of the file with the dead parameters and return values taken out, or undefined when there
	///          are none. A parameter goes only when every call leaves its argument out without anyone noticing.
	/// @self    GMLC_Opt_DeadArgumentAndReturnElimination
	/// @param   {Struct.ASTNode} _node : The function; the file's Script for fn_id 0
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (_cx.unit.fn_id != 0) || (_node.kind != __GMLC_NodeKind_Script) return undefined;
		var _owners = __gmlc_opt_function_owners(_node);
		var _found = false;
		var _o = 0; repeat (array_length(_owners)) {
			if (array_length(__plan(_owners[_o], _node, _cx)) > 0) {
				_found = true;
				break;
			}
		_o++}
		if (!_found) return undefined;
		var _copy = __gmlc_opt_clone(_node);
		_owners = __gmlc_opt_function_owners(_copy);
		var _p = array_length(_owners) - 1; repeat (array_length(_owners)) {
			var _plans = __plan(_owners[_p], _copy, _cx);
			if (array_length(_plans) > 0) __rewrite(_owners[_p], _plans, _cx);
		_p--}
		return _copy;
	};
	#endregion
	
	#region Private
	#region Planning
	#region jsDoc
	/// @func    __plan(_owner, _script, _cx)
	/// @desc    What can be taken out of the functions a unit holds in locals.
	/// @self    GMLC_Opt_DeadArgumentAndReturnElimination
	/// @param   {Struct.ASTNode}   _owner  : The Script or a function node
	/// @param   {Struct.ASTScript} _script : The file
	/// @param   {Struct}           _cx     : The pass context
	/// @returns {Array<Struct>}
	#endregion
	static __plan = function(_owner, _script, _cx) {
		var _state = __gmlc_opt_candidate_scan(_owner, _cx, {}, false);
		var _plans = [];
		var _c = 0; repeat (array_length(_state.order)) {
			var _plan = __planFunction(_state.order[_c], _script, _cx);
			if (_plan != undefined) array_push(_plans, _plan);
		_c++}
		return _plans;
	};
	
	#region jsDoc
	/// @func    __planFunction(_candidate, _script, _cx)
	/// @desc    The parameters, highest first, and whether the return values of one function can go.
	/// @self    GMLC_Opt_DeadArgumentAndReturnElimination
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
		var _statements = true;
		var _i = 0; repeat (array_length(_candidate.uses)) {
			if (!_candidate.uses[_i].stmt) _statements = false;
		_i++}
		var _remove = [];
		var _k = array_length(_fn.params) - 1; repeat (array_length(_fn.params)) {
			if (__removable(_fn, _k, _candidate.uses)) array_push(_remove, _k);
		_k--}
		var _returns = _statements && (__returns(_fn.body, _cx, false) > 0);
		if (array_length(_remove) == 0) && (!_returns) return undefined;
		return { candidate: _candidate, fn: _fn, info: _info, remove: _remove, returns: _returns };
	};
	
	#region jsDoc
	/// @func    __removable(_fn, _k, _uses)
	/// @desc    Whether a parameter can go: no default, never mentioned, and every call that passes it passes
	///          something that can be left out.
	/// @self    GMLC_Opt_DeadArgumentAndReturnElimination
	/// @param   {Struct.ASTFunctionExpr} _fn   : The function
	/// @param   {Real}                   _k    : The parameter's position
	/// @param   {Array<Struct>}          _uses : The calls
	/// @returns {Bool}
	#endregion
	static __removable = function(_fn, _k, _uses) {
		var _param = _fn.params[_k];
		if (_param[$ "default"] != undefined) return false;
		if (__mentions(_fn, _param.target.name) > 0) return false;
		var _i = 0; repeat (array_length(_uses)) {
			var _args = _uses[_i].args;
			if (array_length(_args) > _k) && (!_args[_k].droppable) return false;
		_i++}
		return true;
	};
	
	#region jsDoc
	/// @func    __mentions(_fn, _name)
	/// @desc    How many times a function's defaults and body name a local.
	/// @self    GMLC_Opt_DeadArgumentAndReturnElimination
	/// @param   {Struct.ASTFunctionExpr} _fn   : The function
	/// @param   {String}                 _name : The local
	/// @returns {Real}
	#endregion
	static __mentions = function(_fn, _name) {
		var _n = 0;
		var _i = 0; repeat (array_length(_fn.params)) {
			var _default = _fn.params[_i][$ "default"];
			if (_default != undefined) _n += __count(_default, _name);
		_i++}
		return _n + __count(_fn.body, _name);
	};
	
	#region jsDoc
	/// @func    __count(_node, _name)
	/// @desc    How many times the code under a node names a local, nested functions left out.
	/// @self    GMLC_Opt_DeadArgumentAndReturnElimination
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The local
	/// @returns {Real}
	#endregion
	static __count = function(_node, _name) {
		if (__gmlc_opt_is_function(_node)) return 0;
		if (_node.kind == __GMLC_NodeKind_Identifier) return (__gmlc_opt_is_local(_node) && (_node.name == _name)) ? 1 : 0;
		var _n = 0;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					_n += __count(_child, _name);
				}
			_i++}
		_field_index++}
		return _n;
	};
	
	#region jsDoc
	/// @func    __returns(_node, _cx, _apply)
	/// @desc    Counts, and with _apply changes to a plain `return;`, the returns under a node whose value can be
	///          left out, nested functions left out.
	/// @self    GMLC_Opt_DeadArgumentAndReturnElimination
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Struct}         _cx    : The pass context
	/// @param   {Bool}           _apply : Whether to change them
	/// @returns {Real}
	#endregion
	static __returns = function(_node, _cx, _apply) {
		if (__gmlc_opt_is_function(_node)) return 0;
		if (_node.kind == __GMLC_NodeKind_Return) {
			var _value = _node.argument;
			if (_value != undefined) && ((_value.kind != __GMLC_NodeKind_Literal) || (_value.ty != "undefined")) && (__gmlc_opt_droppable(_value)) && (!_cx.optimizer.__isNoOp(_node)) {
				if (_apply) {
					_node.argument = undefined;
					_cx.stats[$ "returns_dropped"]++;
				}
				return 1;
			}
		}
		var _n = 0;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					_n += __returns(_child, _cx, _apply);
				}
			_i++}
		_field_index++}
		return _n;
	};
	#endregion
	
	#region Rewriting
	#region jsDoc
	/// @func    __rewrite(_owner, _plans, _cx)
	/// @desc    Takes the planned parameters out of their functions and calls, and the planned return values out of
	///          their functions.
	/// @self    GMLC_Opt_DeadArgumentAndReturnElimination
	/// @param   {Struct.ASTNode} _owner : The Script or a function node
	/// @param   {Array<Struct>}  _plans : What __plan found
	/// @param   {Struct}         _cx    : The pass context
	#endregion
	static __rewrite = function(_owner, _plans, _cx) {
		var _list = __gmlc_opt_owner_statements(_owner);
		var _p = 0; repeat (array_length(_plans)) {
			var _plan = _plans[_p];
			var _fn = _plan.fn;
			var _k = 0; repeat (array_length(_plan.remove)) {
				var _index = _plan.remove[_k];
				array_delete(_fn.params, _index, 1);
				array_delete(_plan.info.params, _index, 1);
				_cx.stats[$ "parameters_removed"]++;
				__gmlc_opt_shift_slots(_fn, _index);
			_k++}
			if (_plan.returns) __returns(_fn.body, _cx, true);
			var _i = 0; repeat (array_length(_list)) {
				__gmlc_opt_edit_calls(_list[_i], _plan.candidate.name, _plan.remove);
			_i++}
		_p++}
	};
	
	#endregion
	
	#endregion
}
