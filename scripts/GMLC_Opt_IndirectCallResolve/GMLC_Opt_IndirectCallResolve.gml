#region jsDoc
/// @func    GMLC_Opt_IndirectCallResolve()
/// @desc    The `indirect-call-resolve` optimizer pass: `script_execute(f, args)` and a call through a local that
///          holds the name of a function the file declares become a direct call, which later passes can inline.
///          Only a function the file declares at its top level and never assigns, a local that is assigned once
///          before every use, and an unbound function literal count as known.
///          `var cb = scr_hit; script_execute(cb, a); cb(b);` becomes `var cb = scr_hit; scr_hit(a); scr_hit(b);`.
/// @returns {Struct.GMLC_Opt_IndirectCallResolve}
#endregion
function GMLC_Opt_IndirectCallResolve() : GMLC_OptimizerPass("indirect-call-resolve") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    A copy of the file with the indirect calls turned into direct ones, or undefined when there are none.
	///          It only acts on the file as a whole, and leaves a call a pragma freezes alone.
	/// @self    GMLC_Opt_IndirectCallResolve
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
			if (__resolveOwner(_owners[_o], _node, _cx, _names, false) > 0) {
				_found = true;
				break;
			}
		_o++}
		if (!_found) return undefined;
		var _copy = __gmlc_opt_clone(_node);
		_owners = __gmlc_opt_function_owners(_copy);
		var _p = array_length(_owners) - 1; repeat (array_length(_owners)) {
			__resolveOwner(_owners[_p], _copy, _cx, _names, true);
		_p--}
		return _copy;
	};
	#endregion
	
	#region Private
	#region Resolving
	#region jsDoc
	/// @func    __resolveOwner(_owner, _script, _cx, _names, _apply)
	/// @desc    Counts, and with _apply makes, the indirect calls of a unit that can be direct.
	/// @self    GMLC_Opt_IndirectCallResolve
	/// @param   {Struct.ASTNode}   _owner  : The Script or a function node
	/// @param   {Struct.ASTScript} _script : The file
	/// @param   {Struct}           _cx     : The pass context
	/// @param   {Struct}           _names  : The functions of the file
	/// @param   {Bool}             _apply  : Whether to change the calls
	/// @returns {Real} How many calls
	#endregion
	static __resolveOwner = function(_owner, _script, _cx, _names, _apply) {
		var _state = __gmlc_opt_candidate_scan(_owner, _cx, _names, false);
		var _valid = {};
		var _c = 0; repeat (array_length(_state.order)) {
			var _candidate = _state.order[_c];
			if (__known(_candidate, _owner, _script)) _valid[$ _candidate.name] = _candidate;
		_c++}
		var _walk = { valid: _valid, names: _names, cx: _cx, apply: _apply, count: 0 };
		var _list = __gmlc_opt_owner_statements(_owner);
		var _i = 0; repeat (array_length(_list)) {
			__resolveNode(_list[_i], _walk);
		_i++}
		return _walk.count;
	};
	
	#region jsDoc
	/// @func    __known(_candidate, _owner, _script)
	/// @desc    Whether a local always holds the same function: it is assigned once before every use and holds the
	///          name of a function the file declares (that nothing in the unit declares again), or a function
	///          literal no `self` is bound to.
	/// @self    GMLC_Opt_IndirectCallResolve
	/// @param   {Struct}           _candidate   : The candidate
	/// @param   {Struct.ASTNode}   _owner  : The Script or a function node
	/// @param   {Struct.ASTScript} _script : The file
	/// @returns {Bool}
	#endregion
	static __known = function(_candidate, _owner, _script) {
		if (_candidate.kind == "struct") || (_candidate.dup) || (_candidate.early) return false;
		var _i = 0; repeat (array_length(_candidate.uses)) {
			if (_candidate.uses[_i].kind == "write") return false;
		_i++}
		if (_candidate.kind == "alias") {
			var _list = __gmlc_opt_owner_statements(_owner);
			var _s = 0; repeat (array_length(_list)) {
				if (__shadowed(_list[_s], _candidate.declarator.init.name)) return false;
			_s++}
			return true;
		}
		var _fn = _candidate.declarator.init;
		return (_fn.fn_id != undefined) && (_fn.fn_id < array_length(_script.functions)) && (_script.functions[_fn.fn_id].binding == "none");
	};
	
	#region jsDoc
	/// @func    __shadowed(_node, _name)
	/// @desc    Whether a name is anything but the file's function under a node, nested functions left out.
	/// @self    GMLC_Opt_IndirectCallResolve
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The name
	/// @returns {Bool}
	#endregion
	static __shadowed = function(_node, _name) {
		if (_node.kind == __GMLC_NodeKind_Identifier) return (_node.name == _name) && ((_node.symbol == undefined) || (_node.symbol.kind != "Global"));
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__gmlc_opt_is_function(_child)) && (__shadowed(_child, _name)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};
	
	#region jsDoc
	/// @func    __resolveNode(_node, _walk)
	/// @desc    Visits the calls under a node, nested functions left out.
	/// @self    GMLC_Opt_IndirectCallResolve
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _walk : The walk
	#endregion
	static __resolveNode = function(_node, _walk) {
		if (__gmlc_opt_is_function(_node)) return;
		if (_node.kind == __GMLC_NodeKind_Call) __resolveCall(_node, _walk);
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__resolveNode(_child, _walk);
				}
			_i++}
		_field_index++}
	};
	
	#region jsDoc
	/// @func    __resolveCall(_node, _walk)
	/// @desc    Makes a call through a local that holds a declared function a call of that function, and a
	///          `script_execute` of a known function a plain call.
	/// @self    GMLC_Opt_IndirectCallResolve
	/// @param   {Struct.ASTCall} _node : The call
	/// @param   {Struct}         _walk : The walk
	#endregion
	static __resolveCall = function(_node, _walk) {
		var _callee = _node.callee;
		if (__gmlc_opt_is_local(_callee)) {
			var _candidate = _walk.valid[$ _callee.name];
			if (_candidate != undefined) && (_candidate.kind == "alias") && (!_walk.cx.optimizer.__isNoOp(_node)) {
				_walk.count++;
				if (_walk.apply) {
					_walk.cx.stats[$ "calls_resolved"]++;
					_node.callee = __target(_candidate, _callee.span);
				}
			}
			return;
		}
		if (__gmlc_opt_builtin_call(_node) != "script_execute") || (array_length(_node.args) == 0) return;
		var _first = _node.args[0];
		if (_first.kind != __GMLC_NodeKind_Identifier) || (_first.symbol == undefined) return;
		var _function = undefined;
		if (_first.symbol.kind == "Global") {
			if (_walk.names[$ _first.name] == true) _function = _first;
		}
		else if (_first.symbol.kind == "Local") {
			var _known = _walk.valid[$ _first.name];
			if (_known != undefined) _function = (_known.kind == "alias") ? __target(_known, _first.span) : _first;
		}
		if (_function == undefined) || (__hasEmpty(_node.args)) || (_walk.cx.optimizer.__isNoOp(_node)) return;
		_walk.count++;
		if (_walk.apply) {
			_walk.cx.stats[$ "calls_resolved"]++;
			array_delete(_node.args, 0, 1);
			_node.callee = _function;
		}
	};
	
	#region jsDoc
	/// @func    __target(_candidate, _span)
	/// @desc    A new identifier that names the function a local holds.
	/// @self    GMLC_Opt_IndirectCallResolve
	/// @param   {Struct}           _candidate : The candidate
	/// @param   {Struct.GMLC_Span} _span : Where the new identifier is
	/// @returns {Struct.ASTIdentifier}
	#endregion
	static __target = function(_candidate, _span) {
		var _copy = __gmlc_opt_clone(_candidate.declarator.init);
		_copy.span = _span;
		return _copy;
	};
	
	#region jsDoc
	/// @func    __hasEmpty(_args)
	/// @desc    Whether an argument list leaves an argument out.
	/// @self    GMLC_Opt_IndirectCallResolve
	/// @param   {Array<Struct.ASTNode>} _args : The arguments
	/// @returns {Bool}
	#endregion
	static __hasEmpty = function(_args) {
		var _i = 0; repeat (array_length(_args)) {
			if (_args[_i].kind == __GMLC_NodeKind_Empty) return true;
		_i++}
		return false;
	};
	#endregion
	
	#endregion
}
