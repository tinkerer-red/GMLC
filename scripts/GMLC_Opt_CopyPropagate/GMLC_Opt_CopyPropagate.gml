#region jsDoc
/// @func    GMLC_Opt_CopyPropagate()
/// @desc    The `copy-propagate` optimizer pass: after `var b = a;` between two locals, a read of `b` reads `a` until
///          either is written, so `var _cells = _row; total += _cells[_x];` becomes `total += _row[_x];`. Merging
///          paths, loops, `try`, `switch` and `with` keep only the copies no path breaks, and a write through an
///          array index counts as a write of the array's name. The copy itself stays for the dead-store pass.
/// @returns {Struct.GMLC_Opt_CopyPropagate}
#endregion
function GMLC_Opt_CopyPropagate() : GMLC_OptimizerPass("copy-propagate") constructor {
	#region Config
	static vm_copy_reads = 12; // the reads of a parameter's local copy from which the VM output keeps the copy
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with every read of a copy replaced by its source, or undefined when nothing changed.
	///          A function that reaches its parameters through `argument` is left alone: those names alias them.
	/// @self    GMLC_Opt_CopyPropagate
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (__gmlc_opt_uses_arguments(_node, true)) return undefined;
		var _optimizer = _cx.optimizer;
		var _s = { copies: {}, cx: _cx, optimizer: _optimizer, no_op: _optimizer.has_no_op_targets, yyc_params: {}, builtin_args: {}, vm_kept: {} };
		// for the YYC output a local copy of a parameter that is passed to a built-in stays: YYC passes a parameter to a
		// built-in more slowly than a local
		if (_optimizer.outputName() == "gml-source-yyc") {
			var _params = __gmlc_opt_param_names(_node);
			var _p = 0; repeat (array_length(_params)) {
				_s.yyc_params[$ _params[_p]] = true;
			_p++}
			__builtinArgs(_node, _s.builtin_args);
		}
		// for the VM output a local copy of a parameter read `vm_copy_reads` times or more, or inside a loop, stays: the
		// VM reads a parameter slower than a local, so the copy pays for itself only past that many reads
		if (_optimizer.outputName() == "gml-source-vm") {
			var _params = {};
			var _names = __gmlc_opt_param_names(_node);
			var _p = 0; repeat (array_length(_names)) {
				_params[$ _names[_p]] = true;
			_p++}
			var _copies = {};
			__paramCopies(_node, _params, _copies);
			var _found = struct_get_names(_copies);
			var _c = 0; repeat (array_length(_found)) {
				if (__gmlc_opt_reads(_node, _found[_c]) >= vm_copy_reads) || (__readInLoop(_node, _found[_c], false)) _s.vm_kept[$ _found[_c]] = true;
			_c++}
		}
		if (_node.kind == __GMLC_NodeKind_Script) {
			var _body = __stmts(_s, _node.body);
			return (_body == undefined) ? undefined : __with(undefined, _node, "body", _body);
		}
		var _block = __stmt(_s, _node.body);
		return (_block == undefined) ? undefined : __with(undefined, _node, "body", _block);
	};
	#endregion

	#region Statements
	#region jsDoc
	/// @func    __stmts(_s, _list)
	/// @desc    Walks a statement list in order, each statement seeing the copies the ones before it leave.
	/// @self    GMLC_Opt_CopyPropagate
	/// @param   {Struct}                _s    : The walk state {copies, cx, optimizer, no_op}
	/// @param   {Array<Struct.ASTNode>} _list : The statements
	/// @returns {Array<Struct.ASTNode>|Undefined} The list with the changed statements, undefined when none changed
	#endregion
	static __stmts = function(_s, _list) {
		var _out = undefined;
		var _i = 0; repeat (array_length(_list)) {
			var _new = __stmt(_s, _list[_i]);
			if (_new != undefined) {
				if (_out == undefined) _out = variable_clone(_list, 0);
				_out[_i] = _new;
			}
		_i++}
		return _out;
	};

	#region jsDoc
	/// @func    __stmt(_s, _node)
	/// @desc    Walks a statement and leaves in the state the copies that hold after it. Code that runs a number of
	///          times, or not at all, starts from the copies none of its writes break, and the copies made inside it
	///          do not leave it.
	/// @self    GMLC_Opt_CopyPropagate
	/// @param   {Struct}         _s    : The walk state
	/// @param   {Struct.ASTNode} _node : The statement
	/// @returns {Struct.ASTNode|Undefined} The statement with its reads replaced, undefined when none was
	#endregion
	static __stmt = function(_s, _node) {
		if (_s.no_op) && (_s.optimizer.__isNoOp(_node)) {
			_s.copies = {};
			return undefined;
		}
		var _copy = undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Block: {
				var _body = __stmts(_s, _node.body);
				if (_body != undefined) _copy = __with(_copy, _node, "body", _body);
			break;}
			case __GMLC_NodeKind_VarDeclList: {
				var _list = _node.declarations;
				var _out = undefined;
				var _i = 0; repeat (array_length(_list)) {
					var _new = __decl(_s, _list[_i]);
					if (_new != undefined) {
						if (_out == undefined) _out = variable_clone(_list, 0);
						_out[_i] = _new;
					}
				_i++}
				if (_out != undefined) _copy = __with(_copy, _node, "declarations", _out);
			break;}
			case __GMLC_NodeKind_ExprStmt: {
				var _expression = _node.expression;
				var _new;
				if (_expression.kind == __GMLC_NodeKind_Assign) && (__gmlc_opt_is_local(_expression.target)) {
					// the value reads the target before the write
					_new = __root(_s, _expression.value);
					var _set = {};
					_set[$ _expression.target.name] = true;
					__kill(_s, _set);
					if (_new != undefined) _new = __with(undefined, _expression, "value", _new);
				}
				else {
					_new = __root(_s, _expression);
				}
				if (_new != undefined) _copy = __with(_copy, _node, "expression", _new);
			break;}
			case __GMLC_NodeKind_Return:
			case __GMLC_NodeKind_Throw:
			case __GMLC_NodeKind_Delete: {
				_copy = __root(_s, _node);
			break;}
			case __GMLC_NodeKind_If: {
				var _test = __root(_s, _node.test);
				var _entry = _s.copies;
				_s.copies = variable_clone(_entry, 0);
				var _then = __stmt(_s, _node.consequent);
				var _after_then = _s.copies;
				var _else = undefined;
				var _after_else = _entry;
				if (_node.alternate != undefined) {
					_s.copies = variable_clone(_entry, 0);
					_else = __stmt(_s, _node.alternate);
					_after_else = _s.copies;
				}
				_s.copies = __meet(_after_then, _after_else);
				if (_test != undefined) _copy = __with(_copy, _node, "test", _test);
				if (_then != undefined) _copy = __with(_copy, _node, "consequent", _then);
				if (_else != undefined) _copy = __with(_copy, _node, "alternate", _else);
			break;}
			case __GMLC_NodeKind_For: {
				var _init = (_node.init != undefined) ? __stmt(_s, _node.init) : undefined;
				var _set = {};
				if (_node.test != undefined) __writes(_node.test, _set);
				if (_node.update != undefined) __writes(_node.update, _set);
				__writes(_node.body, _set);
				__kill(_s, _set);
				var _base = _s.copies;
				var _test = undefined;
				if (_node.test != undefined) {
					_s.copies = variable_clone(_base, 0);
					_test = __root(_s, _node.test);
				}
				_s.copies = variable_clone(_base, 0);
				var _body = __stmt(_s, _node.body);
				var _update = undefined;
				if (_node.update != undefined) {
					_s.copies = variable_clone(_base, 0);
					_update = __stmt(_s, _node.update);
				}
				_s.copies = _base;
				if (_init != undefined) _copy = __with(_copy, _node, "init", _init);
				if (_test != undefined) _copy = __with(_copy, _node, "test", _test);
				if (_update != undefined) _copy = __with(_copy, _node, "update", _update);
				if (_body != undefined) _copy = __with(_copy, _node, "body", _body);
			break;}
			case __GMLC_NodeKind_While: {
				var _set = {};
				__writes(_node.test, _set);
				__writes(_node.body, _set);
				__kill(_s, _set);
				var _base = _s.copies;
				_s.copies = variable_clone(_base, 0);
				var _test = __root(_s, _node.test);
				_s.copies = variable_clone(_base, 0);
				var _body = __stmt(_s, _node.body);
				_s.copies = _base;
				if (_test != undefined) _copy = __with(_copy, _node, "test", _test);
				if (_body != undefined) _copy = __with(_copy, _node, "body", _body);
			break;}
			case __GMLC_NodeKind_DoUntil: {
				var _set = {};
				__writes(_node.test, _set);
				__writes(_node.body, _set);
				__kill(_s, _set);
				var _base = _s.copies;
				_s.copies = variable_clone(_base, 0);
				var _body = __stmt(_s, _node.body);
				_s.copies = variable_clone(_base, 0);
				var _test = __root(_s, _node.test);
				_s.copies = _base;
				if (_body != undefined) _copy = __with(_copy, _node, "body", _body);
				if (_test != undefined) _copy = __with(_copy, _node, "test", _test);
			break;}
			case __GMLC_NodeKind_Repeat: {
				var _count = __root(_s, _node.count);
				var _set = {};
				__writes(_node.body, _set);
				__kill(_s, _set);
				var _base = _s.copies;
				_s.copies = variable_clone(_base, 0);
				var _body = __stmt(_s, _node.body);
				_s.copies = _base;
				if (_count != undefined) _copy = __with(_copy, _node, "count", _count);
				if (_body != undefined) _copy = __with(_copy, _node, "body", _body);
			break;}
			case __GMLC_NodeKind_With: {
				var _target = __root(_s, _node.target);
				var _set = {};
				__writes(_node.body, _set);
				__kill(_s, _set);
				var _base = _s.copies;
				_s.copies = variable_clone(_base, 0);
				var _body = __stmt(_s, _node.body);
				_s.copies = _base;
				if (_target != undefined) _copy = __with(_copy, _node, "target", _target);
				if (_body != undefined) _copy = __with(_copy, _node, "body", _body);
			break;}
			case __GMLC_NodeKind_Switch: {
				var _discriminant = __root(_s, _node.discriminant);
				var _cases = _node.cases;
				var _set = {};
				var _c = 0; repeat (array_length(_cases)) {
					__writes(_cases[_c], _set);
				_c++}
				__kill(_s, _set);
				var _base = _s.copies;
				var _out = undefined;
				_c = 0; repeat (array_length(_cases)) {
					var _case = _cases[_c];
					_s.copies = variable_clone(_base, 0);
					var _case_copy = undefined;
					if (_case.kind == __GMLC_NodeKind_Case) {
						var _case_test = __root(_s, _case.test);
						if (_case_test != undefined) _case_copy = __with(_case_copy, _case, "test", _case_test);
					}
					var _case_body = __stmts(_s, _case.body);
					if (_case_body != undefined) _case_copy = __with(_case_copy, _case, "body", _case_body);
					if (_case_copy != undefined) {
						if (_out == undefined) _out = variable_clone(_cases, 0);
						_out[_c] = _case_copy;
					}
				_c++}
				_s.copies = _base;
				if (_discriminant != undefined) _copy = __with(_copy, _node, "discriminant", _discriminant);
				if (_out != undefined) _copy = __with(_copy, _node, "cases", _out);
			break;}
			case __GMLC_NodeKind_Try: {
				var _entry = _s.copies;
				_s.copies = variable_clone(_entry, 0);
				var _block = __stmt(_s, _node.block);
				// the catch block can start anywhere inside the try block
				var _set = {};
				__writes(_node.block, _set);
				_s.copies = _entry;
				__kill(_s, _set);
				var _caught = _s.copies;
				var _catch = undefined;
				var _written = {};
				if (_node.catch_param != undefined) _written[$ _node.catch_param.name] = true;
				if (_node.catch_body != undefined) {
					_s.copies = variable_clone(_caught, 0);
					__kill(_s, _written);
					_catch = __stmt(_s, _node.catch_body);
					__writes(_node.catch_body, _written);
				}
				_s.copies = _caught;
				__kill(_s, _written);
				var _finally = undefined;
				if (_node.finally_body != undefined) {
					var _before = _s.copies;
					_s.copies = variable_clone(_before, 0);
					_finally = __stmt(_s, _node.finally_body);
					_set = {};
					__writes(_node.finally_body, _set);
					_s.copies = _before;
					__kill(_s, _set);
				}
				if (_block != undefined) _copy = __with(_copy, _node, "block", _block);
				if (_catch != undefined) _copy = __with(_copy, _node, "catch_body", _catch);
				if (_finally != undefined) _copy = __with(_copy, _node, "finally_body", _finally);
			break;}
			case __GMLC_NodeKind_Break:
			case __GMLC_NodeKind_Continue:
			case __GMLC_NodeKind_Exit:
			case __GMLC_NodeKind_Empty:
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			break;
			default: {
				var _set = {};
				__writes(_node, _set);
				__kill(_s, _set);
			break;}
		}
		return _copy;
	};

	#region jsDoc
	/// @func    __decl(_s, _node)
	/// @desc    Walks a `var` declaration: its value is read first, the name loses its old copies, and a value that is
	///          another local makes the name a copy of it.
	/// @self    GMLC_Opt_CopyPropagate
	/// @param   {Struct}         _s    : The walk state
	/// @param   {Struct.ASTNode} _node : The declaration
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __decl = function(_s, _node) {
		var _init = _node.init;
		var _new = (_init != undefined) ? __root(_s, _init) : undefined;
		var _value = (_new != undefined) ? _new : _init;
		var _name = _node.target.name;
		var _set = {};
		_set[$ _name] = true;
		__kill(_s, _set);
		if (_value != undefined) && (__gmlc_opt_is_local(_value)) && (_value.origin == undefined) && (__gmlc_opt_is_local(_node.target)) && (_value.name != _name)
		&& (!(struct_exists(_s.yyc_params, _value.name) && struct_exists(_s.builtin_args, _name))) && (!struct_exists(_s.vm_kept, _name)) {
			_s.copies[$ _name] = _value.name;
		}
		return (_new != undefined) ? __with(undefined, _node, "init", _new) : undefined;
	};
	#endregion

	#region Expressions
	#region jsDoc
	/// @func    __paramCopies(_node, _params, _out)
	/// @desc    Collects the locals declared with a parameter as their value (`var _k = _key;`), nested functions left out.
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct}         _params : Parameter name to true
	/// @param   {Struct}         _out    : Name to true
	#endregion
	static __paramCopies = function(_node, _params, _out) {
		if (_node.kind == __GMLC_NodeKind_VarDecl) && (_node.init != undefined) && (__gmlc_opt_is_local(_node.init))
		&& (struct_exists(_params, _node.init.name)) && (__gmlc_opt_is_local(_node.target)) {
			_out[$ _node.target.name] = true;
		}
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _value = _node[$ _fields[_f]];
			var _many = is_array(_value);
			var _i = 0; repeat (_many ? array_length(_value) : 1) {
				var _child = _many ? _value[_i] : _value;
				if (_child != undefined) && (!__gmlc_opt_is_function(_child)) __paramCopies(_child, _params, _out);
			_i++}
		_f++}
	};

	#region jsDoc
	/// @func    __readInLoop(_node, _name, _looped)
	/// @desc    Whether a local is read inside a loop under a node (`_looped`: the node is inside one), nested functions
	///          left out.
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {String}         _name   : The local
	/// @param   {Bool}           _looped : Whether the node is inside a loop
	/// @returns {Bool}
	#endregion
	static __readInLoop = function(_node, _name, _looped) {
		if (_looped) && (__gmlc_opt_is_local(_node)) && (_node.name == _name) return true;
		var _inner = _looped || __gmlc_opt_is_loop(_node);
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _value = _node[$ _fields[_f]];
			var _many = is_array(_value);
			var _i = 0; repeat (_many ? array_length(_value) : 1) {
				var _child = _many ? _value[_i] : _value;
				if (_child != undefined) && (!__gmlc_opt_is_function(_child)) && (__readInLoop(_child, _name, _inner)) return true;
			_i++}
		_f++}
		return false;
	};

	#region jsDoc
	/// @func    __builtinArgs(_node, _out)
	/// @desc    Collects the locals passed as an argument to a built-in, nested functions left out.
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _out  : Name to true
	#endregion
	static __builtinArgs = function(_node, _out) {
		if (_node.kind == __GMLC_NodeKind_Call) && (__gmlc_opt_builtin_call(_node) != undefined) {
			var _a = 0; repeat (array_length(_node.args)) {
				var _arg = _node.args[_a];
				if (__gmlc_opt_is_local(_arg)) _out[$ _arg.name] = true;
			_a++}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__gmlc_opt_is_function(_child)) __builtinArgs(_child, _out);
				}
			_i++}
		_field_index++}
	};

	#region jsDoc
	/// @func    __root(_s, _node)
	/// @desc    Reads a statement's expression part: whatever it writes loses its copies first, since the order its
	///          parts run in is not fixed, then the remaining copies are put in place of reads.
	/// @self    GMLC_Opt_CopyPropagate
	/// @param   {Struct}         _s    : The walk state
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __root = function(_s, _node) {
		var _set = {};
		__writes(_node, _set);
		if (struct_names_count(_set) > 0) __kill(_s, _set);
		if (struct_names_count(_s.copies) == 0) return undefined;
		return __read(_s, _node);
	};

	#region jsDoc
	/// @func    __read(_s, _node)
	/// @desc    Puts the source of a copy in place of each read of it under a node, without touching the node.
	///          Code a macro or an enum made, shorthand struct entries and nested functions are left as they are.
	/// @self    GMLC_Opt_CopyPropagate
	/// @param   {Struct}         _s    : The walk state
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __read = function(_s, _node) {
		if (_node.origin != undefined) return undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier: {
				if (!__gmlc_opt_is_local(_node)) return undefined;
				var _source = _s.copies[$ _node.name];
				if (_source == undefined) return undefined;
				if (_s.no_op) && (_s.optimizer.__isNoOp(_node)) return undefined;
				_s.cx.stats[$ "propagated"]++;
				return __gmlc_opt_local(_source, _node.span);
			}
			case __GMLC_NodeKind_Literal:
			case __GMLC_NodeKind_Nameof:
			case __GMLC_NodeKind_Empty:
			case __GMLC_NodeKind_FunctionExpr:
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			return undefined;
			case __GMLC_NodeKind_StructEntry:
				if (_node.shorthand) return undefined;
			break;
		}
		var _copy = undefined;
		var _array_key = undefined;
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new = __read(_s, _slot.node);
			if (_new != undefined) {
				if (_copy == undefined) _copy = variable_clone(_node, 0);
				if (_slot.index == undefined) {
					_copy[$ _slot.key] = _new;
				}
				else {
					if (_array_key != _slot.key) {
						_copy[$ _slot.key] = variable_clone(_copy[$ _slot.key], 0);
						_array_key = _slot.key;
					}
					_copy[$ _slot.key][_slot.index] = _new;
				}
			}
		_i++}
		return _copy;
	};
	#endregion

	#region Facts
	#region jsDoc
	/// @func    __writes(_node, _out)
	/// @desc    Adds to a set the locals a node writes: assigned, incremented, declared, caught, deleted, or an array
	///          of them written at an index (which splits it from the other names that hold it). Nested functions are
	///          left out.
	/// @self    GMLC_Opt_CopyPropagate
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _out  : The set, name to true
	#endregion
	static __writes = function(_node, _out) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Assign: __writeTarget(_node.target, _out); break;
			case __GMLC_NodeKind_Update: __writeTarget(_node.argument, _out); break;
			case __GMLC_NodeKind_Delete: __writeTarget(_node.target, _out); break;
			case __GMLC_NodeKind_VarDecl: if (__gmlc_opt_is_local(_node.target)) _out[$ _node.target.name] = true; break;
			case __GMLC_NodeKind_Try: if (_node.catch_param != undefined) _out[$ _node.catch_param.name] = true; break;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__gmlc_opt_is_function(_child)) __writes(_child, _out);
				}
			_i++}
		_field_index++}
	};

	#region jsDoc
	/// @func    __writeTarget(_target, _out)
	/// @desc    Adds to a set the local a written expression changes: the local itself, or the one an array is read from
	///          through index accessors (`a[i][j]`). A struct field is changed in the struct, not in the local.
	/// @self    GMLC_Opt_CopyPropagate
	/// @param   {Struct.ASTNode} _target : The written expression
	/// @param   {Struct}         _out    : The set
	#endregion
	static __writeTarget = function(_target, _out) {
		var _root = _target;
		while (_root.kind == __GMLC_NodeKind_Index) {
			var _accessor = _root.accessor;
			if (_accessor != "Array") && (_accessor != "Array2D") && (_accessor != "ArrayAt") && (_accessor != "Array2DAt") return;
			_root = _root.object;
		}
		if (__gmlc_opt_is_local(_root)) _out[$ _root.name] = true;
	};

	#region jsDoc
	/// @func    __kill(_s, _set)
	/// @desc    Drops every copy that has a name of the set on either side.
	/// @self    GMLC_Opt_CopyPropagate
	/// @param   {Struct} _s   : The walk state
	/// @param   {Struct} _set : The names
	#endregion
	static __kill = function(_s, _set) {
		var _copies = _s.copies;
		var _names = struct_get_names(_copies);
		var _i = 0; repeat (array_length(_names)) {
			var _name = _names[_i];
			if (struct_exists(_set, _name)) || (struct_exists(_set, _copies[$ _name])) struct_remove(_copies, _name);
		_i++}
	};

	#region jsDoc
	/// @func    __meet(_a, _b)
	/// @desc    The copies both of two paths hold.
	/// @self    GMLC_Opt_CopyPropagate
	/// @param   {Struct} _a : The copies of a path
	/// @param   {Struct} _b : The copies of another path
	/// @returns {Struct}
	#endregion
	static __meet = function(_a, _b) {
		var _out = {};
		var _names = struct_get_names(_a);
		var _i = 0; repeat (array_length(_names)) {
			var _name = _names[_i];
			if (_b[$ _name] == _a[$ _name]) _out[$ _name] = _a[$ _name];
		_i++}
		return _out;
	};


	#region jsDoc
	/// @func    __with(_copy, _node, _key, _value)
	/// @desc    A shallow copy of a node with one field replaced; the copy a previous call made is reused.
	/// @self    GMLC_Opt_CopyPropagate
	/// @param   {Struct.ASTNode|Undefined} _copy  : The copy so far, undefined for the first change
	/// @param   {Struct.ASTNode}           _node  : The node
	/// @param   {String}                   _key   : The field
	/// @param   {Any}                      _value : Its new value
	/// @returns {Struct.ASTNode}
	#endregion
	static __with = function(_copy, _node, _key, _value) {
		if (_copy == undefined) _copy = variable_clone(_node, 0);
		_copy[$ _key] = _value;
		return _copy;
	};
	#endregion
}
