#region jsDoc
/// @func    GMLC_Opt_InlineSmallFunctions()
/// @desc    The `inline-small-functions` optimizer pass: a call of a small script function of the same file becomes
///          the function's body. The parameters and locals of the callee become locals of the caller named
///          `__gmlc_i<N>_<name>`, N numbering the inlined calls of the caller from 0 in source order:
///          `hsp = approach(hsp, a, b);` becomes `var __gmlc_i0_value = hsp; var __gmlc_i0_target = a; ... hsp = <the
///          returned expression>;`. A callee that is one `return` of an expression and gets trivial arguments is
///          written into the expression in place. The pass works on the whole file from the file's own unit.
/// @returns {Struct.GMLC_Opt_InlineSmallFunctions}
#endregion
function GMLC_Opt_InlineSmallFunctions() : GMLC_OptimizerPass("inline-small-functions") constructor {
	#region Config
	static max_statements = 8;
	static max_nodes = 40;
	static growth_floor = 40;
	static growth_divisor = 10;
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Inlines the calls of small script functions of the file into the functions that make them.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct.ASTNode} _node : The function; only the file's own unit (the script) does anything
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (_cx.unit.fn_id != 0) || (_node.kind != __GMLC_NodeKind_Script) return undefined;
		var _declared = [];
		var _counts = {};
		var _body = _node.body;
		var _s = 0; repeat (array_length(_body)) {
			var _statement = _body[_s];
			if (_statement.kind == __GMLC_NodeKind_FunctionDecl) {
				_counts[$ _statement.name] = (_counts[$ _statement.name] ?? 0) + 1;
				var _id = _statement.fn_id;
				if (_id != undefined) && (_id < array_length(_node.functions)) {
					var _info = _node.functions[_id];
					if (_info != undefined) && (_info.fn_kind == "script_function") {
						array_push(_declared, { decl: _statement, info: _info });
					}
				}
			}
			else if (_statement.kind == __GMLC_NodeKind_ConstructorDecl) {
				_counts[$ _statement.name] = (_counts[$ _statement.name] ?? 0) + 1;
			}
		_s++}
		var _known = {};
		_s = 0; repeat (array_length(_declared)) {
			var _name = _declared[_s].decl.name;
			if (_counts[$ _name] == 1) _known[$ _name] = true;
		_s++}
		var _edges = {};
		_s = 0; repeat (array_length(_declared)) {
			var _decl = _declared[_s].decl;
			if (struct_exists(_known, _decl.name)) {
				var _called = [];
				__calledNames(_decl.body, _known, _called);
				_edges[$ _decl.name] = _called;
			}
		_s++}
		var _state = {
			cx: _cx,
			callees: {},
			taken: __takenNumbers(_cx),
			new_locals: {},
		};
		_s = 0; repeat (array_length(_declared)) {
			var _entry = _declared[_s];
			var _verdict;
			if (struct_exists(_known, _entry.decl.name)) {
				_verdict = __classify(_state, _entry.decl, _entry.info, __isRecursive(_edges, _entry.decl.name));
			}
			else {
				_verdict = { kind: "facts", callee: undefined };
			}
			_state.callees[$ _entry.decl.name] = _verdict;
		_s++}
		var _out = __mapChildren(_node, 2, _state, undefined, undefined);
		if (_out == undefined) return undefined;
		var _ids = struct_get_names(_state.new_locals);
		if (array_length(_ids) > 0) {
			_out.functions = variable_clone(_node.functions, 0);
			var _i = 0; repeat (array_length(_ids)) {
				var _fn = real(_ids[_i]);
				var _names = _state.new_locals[$ _ids[_i]];
				if (_fn < array_length(_out.functions)) && (_out.functions[_fn] != undefined) {
					var _copy = variable_clone(_out.functions[_fn], 0);
					_copy.locals = variable_clone(_copy.locals, 0);
					var _n = 0; repeat (array_length(_names)) {
						if (!array_contains(_copy.locals, _names[_n])) array_push(_copy.locals, _names[_n]);
					_n++}
					_out.functions[_fn] = _copy;
				}
			_i++}
		}
		return _out;
	};
	#endregion
	
	#region Tree
	#region jsDoc
	/// @func    __mapChildren(_node, _mode, _state, _caller, _args)
	/// @desc    The node with its children replaced by what the walk of the mode gives for them, or undefined when
	///          it changes none: mode 0 inlines calls as expressions (`__expressions`), 1 replaces parameters by
	///          arguments (`__replaceParams`), 2 inlines in every function (`__rebuild`). Only the changed nodes and
	///          the ones above them are copied.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Real}           _mode   : The walk
	/// @param   {Struct}         _state  : The pass state
	/// @param   {Struct}         _caller : The function being rewritten, for mode 0
	/// @param   {Array<Struct>}  _args   : The arguments for the parameters, for mode 1
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __mapChildren = function(_node, _mode, _state, _caller, _args) {
		var _copy = undefined;
		var _isStatement = (_node.kind == __GMLC_NodeKind_ExprStmt);
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new;
			switch (_mode) {
				case 0: _new = __expressions(_state, _caller, _slot.node, _isStatement && (_slot.node.kind == __GMLC_NodeKind_Call)); break;
				case 1: _new = __replaceParams(_slot.node, _args); break;
				default: _new = __rebuild(_state, _slot.node); break;
			}
			if (_new != undefined) {
				if (_copy == undefined) {
					_copy = variable_clone(_node, 0);
					var _fields = _node.childFields;
					var _f = 0; repeat (array_length(_fields)) {
						if (is_array(_copy[$ _fields[_f]])) _copy[$ _fields[_f]] = variable_clone(_copy[$ _fields[_f]], 0);
					_f++}
				}
				if (_slot.index == undefined) {
					_copy[$ _slot.key] = _new;
				}
				else {
					_copy[$ _slot.key][_slot.index] = _new;
				}
			}
		_i++}
		return _copy;
	};
	
	#region jsDoc
	/// @func    __countNodes(_node)
	/// @desc    The nodes under a node and the node itself, nested functions left out.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Real}
	#endregion
	static __countNodes = function(_node) {
		if (__gmlc_opt_is_function(_node)) return 1;
		var _n = 1;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					_n += __countNodes(_child);
				}
			_i++}
		_field_index++}
		return _n;
	};
	
	#region jsDoc
	/// @func    __countReturns(_node)
	/// @desc    The `return` statements under a node, nested functions left out.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Real}
	#endregion
	static __countReturns = function(_node) {
		if (__gmlc_opt_is_function(_node)) return 0;
		var _n = (_node.kind == __GMLC_NodeKind_Return) ? 1 : 0;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					_n += __countReturns(_child);
				}
			_i++}
		_field_index++}
		return _n;
	};
	
	#region jsDoc
	/// @func    __declsOk(_node, _allowed)
	/// @desc    Whether every `var` under a node is one that always runs before its local is read: a statement of the
	///          body or the start of a `for`, with a value.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {Bool}           _allowed : Whether a `var` may stand here
	/// @returns {Bool}
	#endregion
	static __declsOk = function(_node, _allowed) {
		switch (_node.kind) {
			case __GMLC_NodeKind_VarDeclList: {
				if (!_allowed) return false;
				var _d = 0; repeat (array_length(_node.declarations)) {
					if (_node.declarations[_d].init == undefined) return false;
				_d++}
			return true;}
			case __GMLC_NodeKind_For:
				return ((_node.init == undefined) || __declsOk(_node.init, true))
					&& ((_node.test == undefined) || __declsOk(_node.test, false))
					&& ((_node.update == undefined) || __declsOk(_node.update, false))
					&& __declsOk(_node.body, false);
			case __GMLC_NodeKind_GlobalVarDecl:
			case __GMLC_NodeKind_StaticDecl:
			return false;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__declsOk(_child, false)) return false;
				}
			_i++}
		_field_index++}
		return true;
	};
	
	#region jsDoc
	/// @func    __localNames(_node, _out)
	/// @desc    Adds the names of the locals read or written under a node to a list, nested functions left out.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Array<String>}  _out  : The names
	#endregion
	static __localNames = function(_node, _out) {
		if (__gmlc_opt_is_function(_node)) return;
		if (__gmlc_opt_is_local(_node)) && (!array_contains(_out, _node.name)) array_push(_out, _node.name);
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__localNames(_child, _out);
				}
			_i++}
		_field_index++}
	};
	
	#region jsDoc
	/// @func    __writesState(_node)
	/// @desc    Whether a node writes anything but a local or runs code that might.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __writesState = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Assign:
				if (!__gmlc_opt_is_local(_node.target)) return true;
			break;
			case __GMLC_NodeKind_Update:
				if (!__gmlc_opt_is_local(_node.argument)) return true;
			break;
			case __GMLC_NodeKind_New:
			case __GMLC_NodeKind_MethodCall:
			case __GMLC_NodeKind_With:
			case __GMLC_NodeKind_Delete:
			return true;
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) return true;
				var _class = __gmlc_opt_call_class(_name);
				if (_class != "pure") && (_class != "observer") return true;
			break;}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__writesState(_child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};
	
	#region jsDoc
	/// @func    __hasAssign(_node)
	/// @desc    Whether an assignment or an increment is under a node.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __hasAssign = function(_node) {
		if (_node.kind == __GMLC_NodeKind_Assign) || (_node.kind == __GMLC_NodeKind_Update) return true;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__hasAssign(_child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};
	
	#region jsDoc
	/// @func    __rename(_node, _map)
	/// @desc    Gives the locals of a callee body, a copy, their names in the caller.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct.ASTNode} _node : The copy
	/// @param   {Struct}         _map  : The new name of each local
	#endregion
	static __rename = function(_node, _map) {
		if (__gmlc_opt_is_local(_node)) {
			var _new = _map[$ _node.name];
			if (_new != undefined) {
				_node.name = _new;
				// the symbol is shared with the callee's own identifiers
				_node.symbol = new GMLC_Symbol(_node.symbol.kind, _new, undefined);
			}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__rename(_child, _map);
				}
			_i++}
		_field_index++}
	};
	
	#region jsDoc
	/// @func    __replaceParams(_node, _args)
	/// @desc    A copy of an expression with each parameter read replaced by the argument that stands for it, or
	///          undefined when it reads none.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Array<Struct>}  _args : {name, value} per parameter
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __replaceParams = function(_node, _args) {
		if (__gmlc_opt_is_local(_node)) {
			var _i = 0; repeat (array_length(_args)) {
				if (_args[_i].name == _node.name) return __gmlc_opt_clone(_args[_i].value);
			_i++}
		}
		return __mapChildren(_node, 1, undefined, undefined, _args);
	};
	
	#region jsDoc
	/// @func    __simpleTarget(_node)
	/// @desc    Whether an assignment target is a name, or names and literals joined by accessors: evaluating it has
	///          no effect.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct.ASTNode} _node : The target
	/// @returns {Bool}
	#endregion
	static __simpleTarget = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier:
			case __GMLC_NodeKind_Literal:
			return true;
			case __GMLC_NodeKind_Index: {
				if (!__simpleTarget(_node.object)) return false;
				var _i = 0; repeat (array_length(_node.keys)) {
					if (!__simpleTarget(_node.keys[_i])) return false;
				_i++}
			return true;}
		}
		return false;
	};
	#endregion
	
	#region Callees
	#region jsDoc
	/// @func    __calledNames(_node, _known, _out)
	/// @desc    Adds the script functions of the file that a node calls to a list.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Struct}         _known : The functions of the file, by name
	/// @param   {Array<String>}  _out   : The names
	#endregion
	static __calledNames = function(_node, _known, _out) {
		if (_node.kind == __GMLC_NodeKind_Call) && (_node.callee.kind == __GMLC_NodeKind_Identifier) {
			var _callee = _node.callee;
			if (_callee.symbol != undefined) && (_callee.symbol.kind == "Global") && struct_exists(_known, _callee.name) && (!array_contains(_out, _callee.name)) {
				array_push(_out, _callee.name);
			}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__calledNames(_child, _known, _out);
				}
			_i++}
		_field_index++}
	};
	
	#region jsDoc
	/// @func    __isRecursive(_edges, _name)
	/// @desc    Whether a function calls itself, directly or through the other functions of the file.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct} _edges : The functions each function calls
	/// @param   {String} _name  : The function
	/// @returns {Bool}
	#endregion
	static __isRecursive = function(_edges, _name) {
		var _seen = [];
		var _stack = [];
		var _first = _edges[$ _name];
		if (_first != undefined) {
			array_copy(_stack, array_length(_stack), _first, 0, array_length(_first));
		}
		while (array_length(_stack) > 0) {
			var _next = array_pop(_stack);
			if (_next == _name) return true;
			if (array_contains(_seen, _next)) continue;
			array_push(_seen, _next);
			var _more = _edges[$ _next];
			if (_more != undefined) {
				array_copy(_stack, array_length(_stack), _more, 0, array_length(_more));
			}
		}
		return false;
	};
	
	#region jsDoc
	/// @func    __takenNumbers(_cx)
	/// @desc    The call site numbers some file of the compile already uses in an `__gmlc_i<N>_` name.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct} _cx : The pass context
	/// @returns {Struct} The numbers as strings
	#endregion
	static __takenNumbers = function(_cx) {
		var _taken = {};
		if (_cx.sources == undefined) return _taken;
		var _prefix = "__gmlc_i";
		var _files = _cx.sources.files;
		var _f = 0; repeat (array_length(_files)) {
			var _file = _files[_f];
			if (_file != undefined) {
				var _text = _file.source;
				var _at = string_pos(_prefix, _text);
				while (_at > 0) {
					var _end = _at + string_length(_prefix);
					var _digits = "";
					while (_end <= string_length(_text)) && (string_pos(string_char_at(_text, _end), "0123456789") > 0) {
						_digits += string_char_at(_text, _end);
						_end++;
					}
					if (_digits != "") && (string_char_at(_text, _end) == "_") _taken[$ string(real(_digits))] = true;
					_at = string_pos_ext(_prefix, _text, _end);
				}
			}
		_f++}
		return _taken;
	};
	
	#region jsDoc
	/// @func    __classify(_state, _decl, _info, _recursive)
	/// @desc    Whether a script function may be inlined, and what its inlining needs: a verdict of kind "facts"
	///          (a precondition fails), "size" (too big) or "ok" with the callee: its parameters with their defaults,
	///          the statements before its trailing return, the returned value, the names of its parameters and
	///          locals without leading underscores, and whether it is one `return`.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct}                 _state     : The pass state
	/// @param   {Struct.ASTFunctionDecl} _decl      : The function
	/// @param   {Struct.GMLC_FunctionInfo} _info    : Its entry in the file's functions
	/// @param   {Bool}                   _recursive : Whether it is in a cycle of calls
	/// @returns {Struct} {kind, callee}
	#endregion
	static __classify = function(_state, _decl, _info, _recursive) {
		var _facts = _info.facts;
		if (_facts == undefined) return { kind: "facts", callee: undefined };
		if (_facts.statement_count > max_statements) || (_facts.node_count > max_nodes) return { kind: "size", callee: undefined };
		if (_facts.uses_argument_array) || (_facts.uses_argument_count) || (_facts.max_argument_index >= 0)
		|| (_facts.has_statics) || (_facts.has_nested_functions) || (_facts.contains_exit) || (_facts.contains_with)
		|| (_facts.contains_try) || (_facts.reads_other) || (_facts.uses_compile_time_names) || (_facts.direct_recursion)
		|| (_recursive) || (_state.cx.optimizer.__isNoOp(_decl)) {
			return { kind: "facts", callee: undefined };
		}
		var _stmts = _decl.body.body;
		var _body = array_create(array_length(_stmts));
		array_copy(_body, 0, _stmts, 0, array_length(_stmts));
		var _ret = undefined;
		var _returns = 0;
		var _s = 0; repeat (array_length(_stmts)) {
			_returns += __countReturns(_stmts[_s]);
		_s++}
		if (array_length(_body) > 0) && (_body[array_length(_body) - 1].kind == __GMLC_NodeKind_Return) {
			_ret = _body[array_length(_body) - 1].argument;
			array_pop(_body);
			_returns--;
		}
		if (_returns != 0) return { kind: "facts", callee: undefined };
		_s = 0; repeat (array_length(_body)) {
			if (_state.cx.optimizer.__isNoOp(_body[_s])) || (!__declsOk(_body[_s], true)) return { kind: "facts", callee: undefined };
		_s++}
		var _params = [];
		var _names = [];
		var _p = 0; repeat (array_length(_decl.params)) {
			var _param = _decl.params[_p];
			if (!__gmlc_opt_is_local(_param.target)) return { kind: "facts", callee: undefined };
			array_push(_params, { name: _param.target.name, default_value: _param[$ "default"] });
			array_push(_names, _param.target.name);
		_p++}
		var _l = 0; repeat (array_length(_info.locals)) {
			if (!array_contains(_names, _info.locals[_l])) array_push(_names, _info.locals[_l]);
		_l++}
		var _used = [];
		_s = 0; repeat (array_length(_body)) {
			__localNames(_body[_s], _used);
		_s++}
		if (_ret != undefined) __localNames(_ret, _used);
		var _u = 0; repeat (array_length(_used)) {
			if (!array_contains(_names, _used[_u])) return { kind: "facts", callee: undefined };
		_u++}
		var _renames = [];
		var _stripped = [];
		var _n = 0; repeat (array_length(_names)) {
			var _short = _names[_n];
			while (string_starts_with(_short, "_")) {
				_short = string_delete(_short, 1, 1);
			}
			if (_short == "") || (array_contains(_stripped, _short)) return { kind: "facts", callee: undefined };
			array_push(_stripped, _short);
			array_push(_renames, { old_name: _names[_n], short_name: _short });
		_n++}
		var _exprForm = (array_length(_body) == 0) && (_ret != undefined) && (!__hasAssign(_ret));
		var _writes = (_ret != undefined) && __writesState(_ret);
		var _nodes = (_ret != undefined) ? __countNodes(_ret) : 0;
		_s = 0; repeat (array_length(_body)) {
			if (__writesState(_body[_s])) _writes = true;
			_nodes += __countNodes(_body[_s]);
		_s++}
		return { kind: "ok", callee: {
			params: _params,
			body: _body,
			ret: _ret,
			renames: _renames,
			expr_form: _exprForm,
			writes_state: _writes,
			nodes: _nodes,
		} };
	};
	
	#region jsDoc
	/// @func    __calleeOf(_state, _call)
	/// @desc    The verdict on the function a call names, or undefined when the call names no script function of the
	///          file.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTCall} _call  : The call
	/// @returns {Struct|Undefined}
	#endregion
	static __calleeOf = function(_state, _call) {
		if (_call.kind != __GMLC_NodeKind_Call) || (_call.callee.kind != __GMLC_NodeKind_Identifier) return undefined;
		var _callee = _call.callee;
		if (_call.origin != undefined) || (_callee.symbol == undefined) || (_callee.symbol.kind != "Global") return undefined;
		return _state.callees[$ _callee.name];
	};
	
	#region jsDoc
	/// @func    __shapeOk(_callee, _args)
	/// @desc    Whether a call passes what the callee takes: no more arguments than parameters, no empty argument,
	///          and a trivial default for each omitted one.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct}        _callee : The callee
	/// @param   {Array<Struct>} _args   : The arguments
	/// @returns {Bool}
	#endregion
	static __shapeOk = function(_callee, _args) {
		if (array_length(_args) > array_length(_callee.params)) return false;
		var _i = 0; repeat (array_length(_args)) {
			if (_args[_i].kind == __GMLC_NodeKind_Empty) return false;
		_i++}
		_i = array_length(_args); repeat (array_length(_callee.params) - array_length(_args)) {
			var _default = _callee.params[_i].default_value;
			if (_default != undefined) && (!__gmlc_opt_is_trivial(_default)) return false;
		_i++}
		return true;
	};
	
	#region jsDoc
	/// @func    __argument(_callee, _args, _k, _span)
	/// @desc    The value a parameter gets at a call: its argument, else its default, else undefined.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct}           _callee : The callee
	/// @param   {Array<Struct>}    _args   : The arguments
	/// @param   {Real}             _k      : The parameter's number
	/// @param   {Struct.GMLC_Span} _span   : The span of the call
	/// @returns {Struct.ASTNode}
	#endregion
	static __argument = function(_callee, _args, _k, _span) {
		if (_k < array_length(_args)) return _args[_k];
		var _default = _callee.params[_k].default_value;
		if (_default == undefined) return __gmlc_opt_undefined_literal(_span);
		var _value = __gmlc_opt_clone(_default);
		__gmlc_opt_retag_span(_value, _span);
		return _value;
	};
	#endregion
	
	#region Sites
	#region jsDoc
	/// @func    __expressionSite(_state, _caller, _call, _whole)
	/// @desc    The expression a call becomes when the callee is one `return` and every argument is trivial; undefined
	///          when it stays. A call that is a whole statement stays a call: an expression is no statement.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct}         _state  : The pass state
	/// @param   {Struct}         _caller : The function being rewritten
	/// @param   {Struct.ASTNode} _call   : The call
	/// @param   {Bool}           _whole  : Whether the call is a whole statement
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __expressionSite = function(_state, _caller, _call, _whole) {
		var _verdict = __calleeOf(_state, _call);
		if (_verdict == undefined) return undefined;
		if (_verdict.kind == "facts") {
			_state.cx.stats[$ "refused_facts"]++;
			return undefined;
		}
		if (_verdict.kind == "size") {
			_state.cx.stats[$ "refused_size"]++;
			return undefined;
		}
		var _callee = _verdict.callee;
		if (!__shapeOk(_callee, _call.args)) {
			_state.cx.stats[$ "refused_facts"]++;
			return undefined;
		}
		if (_whole) || (!_callee.expr_form) return undefined;
		var _span = _call.span;
		var _values = [];
		var _k = 0; repeat (array_length(_callee.params)) {
			var _value = __argument(_callee, _call.args, _k, _span);
			if (!__gmlc_opt_is_trivial(_value)) return undefined;
			var _simple = (_value.kind == __GMLC_NodeKind_Literal) || __gmlc_opt_is_local(_value);
			if (!_simple) && (__gmlc_opt_reads(_callee.ret, _callee.params[_k].name) > 1) return undefined;
			array_push(_values, { name: _callee.params[_k].name, value: _value });
		_k++}
		var _added = max(_callee.nodes - 2, 0);
		if (_caller.growth + _added > _caller.allowance) {
			_state.cx.stats[$ "refused_size"]++;
			return undefined;
		}
		var _body = __gmlc_opt_clone(_callee.ret);
		__gmlc_opt_retag_span(_body, _span);
		var _new = __replaceParams(_body, _values) ?? _body;
		_caller.growth += _added;
		_state.cx.stats[$ "inlined"]++;
		return _new;
	};
	
	#region jsDoc
	/// @func    __expressions(_state, _caller, _node, _whole)
	/// @desc    A node with the calls it makes inlined as expressions, inner ones first, or undefined when it holds
	///          none. Statement lists and functions inside it are left to their own turn.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct}         _state  : The pass state
	/// @param   {Struct}         _caller : The function being rewritten
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Bool}           _whole  : Whether the node is a call that is a whole statement
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __expressions = function(_state, _caller, _node, _whole) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Block:
			case __GMLC_NodeKind_Case:
			case __GMLC_NodeKind_Default:
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr:
			return undefined;
		}
		if (_state.cx.optimizer.__isNoOp(_node)) return undefined;
		var _rewritten = __mapChildren(_node, 0, _state, _caller, undefined);
		var _current = _rewritten ?? _node;
		var _new = __expressionSite(_state, _caller, _current, _whole);
		if (_new != undefined) return _new;
		return _rewritten;
	};
	
	#region jsDoc
	/// @func    __nextNumber(_state, _caller)
	/// @desc    The next call site number of a caller that no file of the compile uses.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct} _state  : The pass state
	/// @param   {Struct} _caller : The function being rewritten
	/// @returns {Real}
	#endregion
	static __nextNumber = function(_state, _caller) {
		while (true) {
			var _n = _caller.counter;
			_caller.counter++;
			if (_state.taken[$ string(_n)] == undefined) return _n;
		}
	};
	
	#region jsDoc
	/// @func    __valueName(_callee)
	/// @desc    The name the value of a discarded call is kept under: `value`, with underscores after it until no
	///          parameter or local of the callee has it.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct} _callee : The callee
	/// @returns {String}
	#endregion
	static __valueName = function(_callee) {
		var _name = "value";
		var _taken = true;
		while (_taken) {
			_taken = false;
			var _r = 0; repeat (array_length(_callee.renames)) {
				if (_callee.renames[_r].short_name == _name) {
					_taken = true;
					_name += "_";
					break;
				}
			_r++}
		}
		return _name;
	};

	#region jsDoc
	/// @func    __statementForm(_state, _caller, _stmt)
	/// @desc    The statements a call statement becomes when the callee is inlined as statements, or undefined. The
	///          call is the whole statement, the value of a `var`, of a plain or compound assignment or of a `return`;
	///          its arguments become locals, in order, and at most one of them may have an effect.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct}         _state  : The pass state
	/// @param   {Struct}         _caller : The function being rewritten
	/// @param   {Struct.ASTNode} _stmt   : The statement
	/// @returns {Array<Struct.ASTNode>|Undefined}
	#endregion
	static __statementForm = function(_state, _caller, _stmt) {
		var _call = undefined;
		var _use = "";
		switch (_stmt.kind) {
			case __GMLC_NodeKind_ExprStmt:
				if (_stmt.expression.kind == __GMLC_NodeKind_Call) {
					_call = _stmt.expression;
					_use = "discard";
				}
				else if (_stmt.expression.kind == __GMLC_NodeKind_Assign) && (_stmt.expression.value.kind == __GMLC_NodeKind_Call) {
					_call = _stmt.expression.value;
					_use = "assign";
				}
			break;
			case __GMLC_NodeKind_VarDeclList:
				if (array_length(_stmt.declarations) == 1) {
					var _init = _stmt.declarations[0].init;
					if (_init != undefined) && (_init.kind == __GMLC_NodeKind_Call) {
						_call = _init;
						_use = "decl";
					}
				}
			break;
			case __GMLC_NodeKind_Return:
				if (_stmt.argument != undefined) && (_stmt.argument.kind == __GMLC_NodeKind_Call) {
					_call = _stmt.argument;
					_use = "return";
				}
			break;
		}
		if (_call == undefined) return undefined;
		var _verdict = __calleeOf(_state, _call);
		if (_verdict == undefined) || (_verdict.kind != "ok") return undefined;
		var _callee = _verdict.callee;
		var _args = _call.args;
		if (!__shapeOk(_callee, _args)) return undefined;
		if (_use != "discard") && (_callee.ret == undefined) return undefined;
		if (_use == "assign") {
			var _target = _stmt.expression.target;
			if (!__gmlc_opt_is_local(_target)) && ((_callee.writes_state) || (!__simpleTarget(_target))) return undefined;
		}
		var _effectful = 0;
		var _a = 0; repeat (array_length(_args)) {
			if (__gmlc_opt_has_effects(_args[_a])) _effectful++;
		_a++}
		if (_effectful > 1) {
			_state.cx.stats[$ "refused_order"]++;
			return undefined;
		}
		var _added = max(3 * array_length(_callee.params) + _callee.nodes - 2, 0);
		if (_caller.growth + _added > _caller.allowance) {
			_state.cx.stats[$ "refused_size"]++;
			return undefined;
		}
		var _n = __nextNumber(_state, _caller);
		_caller.growth += _added;
		var _span = __gmlc_opt_span_point(_stmt.span);
		var _map = {};
		var _r = 0; repeat (array_length(_callee.renames)) {
			var _rename = _callee.renames[_r];
			var _new_name = "__gmlc_i" + string(_n) + "_" + _rename.short_name;
			_map[$ _rename.old_name] = _new_name;
			if (!array_contains(_caller.locals, _new_name)) array_push(_caller.locals, _new_name);
		_r++}
		var _out = [];
		var _k = 0; repeat (array_length(_callee.params)) {
			var _init_value = __argument(_callee, _args, _k, _span);
			array_push(_out, __gmlc_opt_var(_map[$ _callee.params[_k].name], _init_value, _span));
		_k++}
		var _b = 0; repeat (array_length(_callee.body)) {
			var _copy = __gmlc_opt_clone(_callee.body[_b]);
			__gmlc_opt_retag_span(_copy, _span);
			__rename(_copy, _map);
			array_push(_out, _copy);
		_b++}
		var _value = undefined;
		if (_callee.ret != undefined) {
			_value = __gmlc_opt_clone(_callee.ret);
			__gmlc_opt_retag_span(_value, _span);
			__rename(_value, _map);
		}
		switch (_use) {
			case "discard":
				if (_value != undefined) {
					if (_value.kind == __GMLC_NodeKind_Call) || (_value.kind == __GMLC_NodeKind_MethodCall) || (_value.kind == __GMLC_NodeKind_New) {
						array_push(_out, new ASTExprStmt(_span, _value));
					}
					else if (__gmlc_opt_may_throw(_value)) {
						// a value that may throw is no statement: it is kept as a local's value
						var _kept = "__gmlc_i" + string(_n) + "_" + __valueName(_callee);
						if (!array_contains(_caller.locals, _kept)) array_push(_caller.locals, _kept);
						array_push(_out, __gmlc_opt_var(_kept, _value, _span));
					}
				}
			break;
			case "assign": {
				var _assign = variable_clone(_stmt.expression, 0);
				_assign.value = _value;
				var _assignStmt = variable_clone(_stmt, 0);
				_assignStmt.expression = _assign;
				array_push(_out, _assignStmt);
			break;}
			case "decl": {
				var _decl = variable_clone(_stmt.declarations[0], 0);
				_decl.init = _value;
				var _list = variable_clone(_stmt, 0);
				_list.declarations = [_decl];
				array_push(_out, _list);
			break;}
			case "return":
				array_push(_out, new ASTReturn(_span, _value));
			break;
		}
		_state.cx.stats[$ "inlined"]++;
		return _out;
	};
	#endregion
	
	#region Lists
	#region jsDoc
	/// @func    __list(_state, _caller, _stmts)
	/// @desc    A statement list of a caller with its calls inlined, or undefined when nothing changes.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct}        _state  : The pass state
	/// @param   {Struct}        _caller : The function being rewritten
	/// @param   {Array<Struct>} _stmts  : The statements
	/// @returns {Array<Struct>|Undefined}
	#endregion
	static __list = function(_state, _caller, _stmts) {
		var _out = [];
		var _changed = false;
		var _s = 0; repeat (array_length(_stmts)) {
			var _statement = _stmts[_s];
			if (_state.cx.optimizer.__isNoOp(_statement)) {
				array_push(_out, _statement);
			}
			else {
				var _rewritten = __expressions(_state, _caller, _statement, false);
				if (_rewritten != undefined) {
					_statement = _rewritten;
					_changed = true;
				}
				var _replacement = __statementForm(_state, _caller, _statement);
				if (_replacement != undefined) {
					array_copy(_out, array_length(_out), _replacement, 0, array_length(_replacement));
					_changed = true;
				}
				else {
					var _nested = __nested(_state, _caller, _statement);
					if (_nested != undefined) {
						_statement = _nested;
						_changed = true;
					}
					array_push(_out, _statement);
				}
			}
		_s++}
		return _changed ? _out : undefined;
	};
	
	#region jsDoc
	/// @func    __block(_state, _caller, _node)
	/// @desc    A block with its calls inlined, or undefined when nothing changes.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct}         _state  : The pass state
	/// @param   {Struct}         _caller : The function being rewritten
	/// @param   {Struct.ASTNode} _node   : The block
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __block = function(_state, _caller, _node) {
		if (_node.kind != __GMLC_NodeKind_Block) return undefined;
		var _body = __list(_state, _caller, _node.body);
		if (_body == undefined) return undefined;
		var _out = variable_clone(_node, 0);
		_out.body = _body;
		return _out;
	};
	
	#region jsDoc
	/// @func    __nested(_state, _caller, _stmt)
	/// @desc    A statement with the lists inside it inlined, or undefined when nothing changes.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct}         _state  : The pass state
	/// @param   {Struct}         _caller : The function being rewritten
	/// @param   {Struct.ASTNode} _stmt   : The statement
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __nested = function(_state, _caller, _stmt) {
		switch (_stmt.kind) {
			case __GMLC_NodeKind_If: {
				var _consequent = __block(_state, _caller, _stmt.consequent);
				var _alternate = (_stmt.alternate != undefined) ? __block(_state, _caller, _stmt.alternate) : undefined;
				if (_consequent == undefined) && (_alternate == undefined) return undefined;
				var _if = variable_clone(_stmt, 0);
				if (_consequent != undefined) _if.consequent = _consequent;
				if (_alternate != undefined) _if.alternate = _alternate;
			return _if;}
			case __GMLC_NodeKind_For:
			case __GMLC_NodeKind_While:
			case __GMLC_NodeKind_Repeat:
			case __GMLC_NodeKind_DoUntil:
			case __GMLC_NodeKind_With: {
				var _body = __block(_state, _caller, _stmt.body);
				if (_body == undefined) return undefined;
				var _loop = variable_clone(_stmt, 0);
				_loop.body = _body;
			return _loop;}
			case __GMLC_NodeKind_Block:
			return __block(_state, _caller, _stmt);
			case __GMLC_NodeKind_Switch: {
				var _switch = undefined;
				var _k = 0; repeat (array_length(_stmt.cases)) {
					var _case = _stmt.cases[_k];
					var _list = __list(_state, _caller, _case.body);
					if (_list != undefined) {
						if (_switch == undefined) {
							_switch = variable_clone(_stmt, 0);
							_switch.cases = variable_clone(_stmt.cases, 0);
						}
						var _newCase = variable_clone(_case, 0);
						_newCase.body = _list;
						_switch.cases[_k] = _newCase;
					}
				_k++}
			return _switch;}
			case __GMLC_NodeKind_Try: {
				var _try = __block(_state, _caller, _stmt.block);
				var _catch = (_stmt.catch_body != undefined) ? __block(_state, _caller, _stmt.catch_body) : undefined;
				var _finally = (_stmt.finally_body != undefined) ? __block(_state, _caller, _stmt.finally_body) : undefined;
				if (_try == undefined) && (_catch == undefined) && (_finally == undefined) return undefined;
				var _out = variable_clone(_stmt, 0);
				if (_try != undefined) _out.block = _try;
				if (_catch != undefined) _out.catch_body = _catch;
				if (_finally != undefined) _out.finally_body = _finally;
			return _out;}
		}
		return undefined;
	};
	#endregion
	
	#region Functions
	#region jsDoc
	/// @func    __function(_state, _f)
	/// @desc    A function with the calls in its body inlined, or undefined when nothing changes.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _f     : The function
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __function = function(_state, _f) {
		if (_state.cx.optimizer.__isNoOp(_f)) return undefined;
		var _caller = {
			counter: 0,
			growth: 0,
			allowance: max(__countNodes(_f.body) div growth_divisor, growth_floor),
			locals: [],
		};
		var _out = _f;
		var _changed = false;
		var _block = __block(_state, _caller, _f.body);
		if (_block != undefined) {
			_out = variable_clone(_f, 0);
			_out.body = _block;
			_changed = true;
		}
		if (_f.fn_id != undefined) && (array_length(_caller.locals) > 0) {
			var _key = string(_f.fn_id);
			var _known = _state.new_locals[$ _key];
			if (_known == undefined) {
				_known = [];
				_state.new_locals[$ _key] = _known;
			}
			array_copy(_known, array_length(_known), _caller.locals, 0, array_length(_caller.locals));
		}
		var _rebuilt = __mapChildren(_out, 2, _state, undefined, undefined);
		if (_rebuilt != undefined) {
			_out = _rebuilt;
			_changed = true;
		}
		return _changed ? _out : undefined;
	};
	
	#region jsDoc
	/// @func    __rebuild(_state, _node)
	/// @desc    A node with every function inside it inlined, or undefined when nothing changes.
	/// @self    GMLC_Opt_InlineSmallFunctions
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _node  : The node
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __rebuild = function(_state, _node) {
		if (__gmlc_opt_is_function(_node)) return __function(_state, _node);
		return __mapChildren(_node, 2, _state, undefined, undefined);
	};
	#endregion
}
