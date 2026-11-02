#region jsDoc
/// @func    GMLC_Opt_UnusedFieldElimination()
/// @desc    The `unused-field-elimination` optimizer pass: a member that is stored but never read is taken out, with
///          its stores. Any other file can read the members of a global struct, an instance or a constructor, or
///          reach them by reflection, so it only follows two things the file alone can see: a struct literal held
///          in a local that is only used through its member names, and a static of a function literal held in a
///          local that is only ever called, that nothing mentions.
///          `var s = { a: 1, debug: 0 }; s.debug = 2; x = s.a;` becomes `var s = { a: 1 }; x = s.a;`.
/// @returns {Struct.GMLC_Opt_UnusedFieldElimination}
#endregion
function GMLC_Opt_UnusedFieldElimination() : GMLC_OptimizerPass("unused-field-elimination") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    A copy of the file with the unused members taken out, or undefined when there are none. A member
	///          goes only when what is stored in it can be left out without anyone noticing.
	/// @self    GMLC_Opt_UnusedFieldElimination
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
	/// @desc    The unused members of the struct locals a unit declares, and the unused statics of the functions it
	///          holds in locals.
	/// @self    GMLC_Opt_UnusedFieldElimination
	/// @param   {Struct.ASTNode}   _owner  : The Script or a function node
	/// @param   {Struct.ASTScript} _script : The file
	/// @param   {Struct}           _cx     : The pass context
	/// @returns {Array<Struct>}
	#endregion
	static __plan = function(_owner, _script, _cx) {
		var _state = __gmlc_opt_candidate_scan(_owner, _cx, {}, false);
		var _plans = [];
		var _c = 0; repeat (array_length(_state.order)) {
			var _candidate = _state.order[_c];
			var _plan = (_candidate.kind == "struct") ? __planStruct(_candidate, _cx) : __planStatics(_candidate, _script, _cx);
			if (_plan != undefined) array_push(_plans, _plan);
		_c++}
		return _plans;
	};
	
	#region jsDoc
	/// @func    __planStruct(_candidate, _cx)
	/// @desc    The members of a struct local that are never read, when the local is only used through its member
	///          names. A member goes when its literal value and every store to it can be left out.
	/// @self    GMLC_Opt_UnusedFieldElimination
	/// @param   {Struct} _candidate : The candidate
	/// @param   {Struct} _cx   : The pass context
	/// @returns {Struct|Undefined}
	#endregion
	static __planStruct = function(_candidate, _cx) {
		if (_candidate.dup) || (_candidate.early) return undefined;
		var _read = {};
		var _stored = {};
		var _order = [];
		var _i = 0; repeat (array_length(_candidate.uses)) {
			var _use = _candidate.uses[_i];
			if (_use.kind == "member") {
				_read[$ _use.member] = true;
			}
			else if (_use.kind == "store") {
				if (_stored[$ _use.member] == undefined) {
					_stored[$ _use.member] = true;
					array_push(_order, _use.member);
				}
				if (!_use.droppable) || (_use.frozen) _stored[$ _use.member] = false;
			}
			else {
				return undefined;
			}
		_i++}
		var _entries = _candidate.declarator.init.entries;
		var _members = [];
		var _e = 0; repeat (array_length(_entries)) {
			var _entry = _entries[_e];
			var _key = _entry.key;
			if (_read[$ _key] != true) && (_stored[$ _key] != false) && (__gmlc_opt_droppable(_entry.value)) && (!_cx.optimizer.__isNoOp(_entry)) && (!array_contains(_members, _key)) {
				array_push(_members, _key);
			}
		_e++}
		var _s = 0; repeat (array_length(_order)) {
			var _key = _order[_s];
			if (_read[$ _key] != true) && (_stored[$ _key] == true) && (!array_contains(_members, _key)) && (!__declared(_entries, _key)) {
				array_push(_members, _key);
			}
		_s++}
		if (array_length(_members) == 0) return undefined;
		return { kind: "struct", name: _candidate.name, literal: _candidate.declarator.init, members: _members };
	};
	
	#region jsDoc
	/// @func    __declared(_entries, _key)
	/// @desc    Whether a struct literal has an entry with a key.
	/// @self    GMLC_Opt_UnusedFieldElimination
	/// @param   {Array<Struct.ASTStructEntry>} _entries : The entries
	/// @param   {String}                       _key     : The key
	/// @returns {Bool}
	#endregion
	static __declared = function(_entries, _key) {
		var _i = 0; repeat (array_length(_entries)) {
			if (_entries[_i].key == _key) return true;
		_i++}
		return false;
	};
	
	#region jsDoc
	/// @func    __planStatics(_candidate, _script, _cx)
	/// @desc    The statics of a function literal held in a local that nothing in the function mentions.
	/// @self    GMLC_Opt_UnusedFieldElimination
	/// @param   {Struct}           _candidate   : The candidate
	/// @param   {Struct.ASTScript} _script : The file
	/// @param   {Struct}           _cx     : The pass context
	/// @returns {Struct|Undefined}
	#endregion
	static __planStatics = function(_candidate, _script, _cx) {
		if (!__gmlc_opt_candidate_calls_only(_candidate)) return undefined;
		var _fn = _candidate.declarator.init;
		if (_cx.optimizer.__isNoOp(_fn)) || (_fn.fn_id == undefined) || (_fn.fn_id >= array_length(_script.functions)) return undefined;
		var _found = [];
		__collectStatics(_fn.body, _found);
		var _drops = [];
		var _s = 0; repeat (array_length(_found)) {
			var _static = _found[_s];
			var _decl = _static.decl;
			if (_static.count == 1) && ((_decl.init == undefined) || (__gmlc_opt_droppable(_decl.init))) && (!_cx.optimizer.__isNoOp(_decl)) {
				var _mentions = 0;
				var _p = 0; repeat (array_length(_fn.params)) {
					var _default = _fn.params[_p][$ "default"];
					if (_default != undefined) _mentions += __mentions(_default, _static.name);
				_p++}
				_mentions += __mentions(_fn.body, _static.name);
				if (_mentions == 0) array_push(_drops, _static.name);
			}
		_s++}
		if (array_length(_drops) == 0) return undefined;
		return { kind: "statics", fn: _fn, info: _script.functions[_fn.fn_id], drops: _drops };
	};
	
	#region jsDoc
	/// @func    __collectStatics(_node, _out)
	/// @desc    Lists the statics declared under a node with how many times each is declared and the first
	///          declarator, nested functions left out.
	/// @self    GMLC_Opt_UnusedFieldElimination
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Array<Struct>}  _out  : {name, count, decl}
	#endregion
	static __collectStatics = function(_node, _out) {
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
					array_push(_out, { name: _name, count: 1, decl: _decl });
				}
				else {
					_entry.count++;
				}
			_d++}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__collectStatics(_child, _out);
				}
			_i++}
		_field_index++}
	};
	
	#region jsDoc
	/// @func    __mentions(_node, _name)
	/// @desc    How many times the code under a node names a static, nested functions left out. A declaration's
	///          name is not a mention.
	/// @self    GMLC_Opt_UnusedFieldElimination
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {String}         _name : The static
	/// @returns {Real}
	#endregion
	static __mentions = function(_node, _name) {
		if (__gmlc_opt_is_function(_node)) return 0;
		var _n = 0;
		if (_node.kind == __GMLC_NodeKind_StaticDecl) {
			var _d = 0; repeat (array_length(_node.declarations)) {
				var _init = _node.declarations[_d].init;
				if (_init != undefined) _n += __mentions(_init, _name);
			_d++}
			return _n;
		}
		if (_node.kind == __GMLC_NodeKind_Identifier) return ((_node.symbol != undefined) && (_node.symbol.kind == "Static") && (_node.name == _name)) ? 1 : 0;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					_n += __mentions(_child, _name);
				}
			_i++}
		_field_index++}
		return _n;
	};
	#endregion
	
	#region Rewriting
	#region jsDoc
	/// @func    __rewrite(_owner, _plans, _cx)
	/// @desc    Takes the planned members out of their struct literals and stores, and the planned statics out of
	///          their functions.
	/// @self    GMLC_Opt_UnusedFieldElimination
	/// @param   {Struct.ASTNode} _owner : The Script or a function node
	/// @param   {Array<Struct>}  _plans : What __plan found
	/// @param   {Struct}         _cx    : The pass context
	#endregion
	static __rewrite = function(_owner, _plans, _cx) {
		var _list = __gmlc_opt_owner_statements(_owner);
		var _p = 0; repeat (array_length(_plans)) {
			var _plan = _plans[_p];
			if (_plan.kind == "struct") {
				repeat (array_length(_plan.members)) {
					_cx.stats[$ "members_removed"]++;
				}
				var _entries = _plan.literal.entries;
				var _e = array_length(_entries) - 1; repeat (array_length(_entries)) {
					if (array_contains(_plan.members, _entries[_e].key)) array_delete(_entries, _e, 1);
				_e--}
				var _i = 0; repeat (array_length(_list)) {
					__dropStores(_list[_i], _plan.name, _plan.members);
				_i++}
			}
			else {
				repeat (array_length(_plan.drops)) {
					_cx.stats[$ "statics_removed"]++;
				}
				__dropStatics(_plan.fn, _plan.drops);
				var _s = 0; repeat (array_length(_plan.drops)) {
					var _at = array_get_index(_plan.info.statics, _plan.drops[_s]);
					if (_at >= 0) array_delete(_plan.info.statics, _at, 1);
				_s++}
			}
		_p++}
	};
	
	#region jsDoc
	/// @func    __dropStores(_node, _name, _members)
	/// @desc    Replaces the statements under a node that store into the listed members of a struct local by empty
	///          statements, nested functions left out.
	/// @self    GMLC_Opt_UnusedFieldElimination
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {String}         _name    : The local
	/// @param   {Array<String>}  _members : The members
	#endregion
	static __dropStores = function(_node, _name, _members) {
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _child = _slot.node;
			if (!__gmlc_opt_is_function(_child)) {
				if (__isStore(_child, _name, _members)) {
					var _empty = new ASTEmpty(_child.span);
					if (_slot.index == undefined) {
						_slot.parent[$ _slot.key] = _empty;
					}
					else {
						_slot.parent[$ _slot.key][_slot.index] = _empty;
					}
				}
				else {
					__dropStores(_child, _name, _members);
				}
			}
		_i++}
	};
	
	#region jsDoc
	/// @func    __isStore(_node, _name, _members)
	/// @desc    Whether a node is the statement `name.member = value;` for one of the members.
	/// @self    GMLC_Opt_UnusedFieldElimination
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {String}         _name    : The local
	/// @param   {Array<String>}  _members : The members
	/// @returns {Bool}
	#endregion
	static __isStore = function(_node, _name, _members) {
		if (_node.kind != __GMLC_NodeKind_ExprStmt) return false;
		var _expr = _node.expression;
		if (_expr.kind != __GMLC_NodeKind_Assign) || (_expr.op != "=") return false;
		var _target = _expr.target;
		if (_target.kind != __GMLC_NodeKind_Index) || (_target.accessor != "Dot") || (!__gmlc_opt_is_local(_target.object)) return false;
		return (_target.object.name == _name) && array_contains(_members, _target.member);
	};
	
	#region jsDoc
	/// @func    __dropStatics(_node, _drops)
	/// @desc    Takes the listed statics out of the declarations under a node, and a declaration left with none
	///          becomes an empty statement, nested functions left out.
	/// @self    GMLC_Opt_UnusedFieldElimination
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Array<String>}  _drops : The statics
	#endregion
	static __dropStatics = function(_node, _drops) {
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _child = _slot.node;
			if (!__gmlc_opt_is_function(_child)) {
				if (_child.kind == __GMLC_NodeKind_StaticDecl) {
					var _declarations = _child.declarations;
					var _d = array_length(_declarations) - 1; repeat (array_length(_declarations)) {
						if (array_contains(_drops, _declarations[_d].target.name)) array_delete(_declarations, _d, 1);
					_d--}
					if (array_length(_declarations) == 0) {
						var _empty = new ASTEmpty(_child.span);
						if (_slot.index == undefined) {
							_slot.parent[$ _slot.key] = _empty;
						}
						else {
							_slot.parent[$ _slot.key][_slot.index] = _empty;
						}
					}
				}
				else {
					__dropStatics(_child, _drops);
				}
			}
		_i++}
	};
	#endregion
	
	#endregion
}
