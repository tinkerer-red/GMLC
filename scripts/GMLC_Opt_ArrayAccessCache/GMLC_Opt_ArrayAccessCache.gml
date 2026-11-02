#region jsDoc
/// @func    GMLC_Opt_ArrayAccessCache()
/// @desc    The `array-access-cache` optimizer pass: `array_length(a)` and `ds_list_size(l)` in the test of a loop
///          that cannot change the array or the list are read once before the loop, and the row `a[i]` of an inner
///          loop over `a[i][j]` is read once before it:
///          `for (var i = 0; i < array_length(a); i++) {}` becomes `var n = array_length(a); for (var i = 0; i < n; i++) {}`.
/// @returns {Struct.GMLC_Opt_ArrayAccessCache}
#endregion
function GMLC_Opt_ArrayAccessCache() : GMLC_OptimizerPass("array-access-cache") constructor {
	#region Config
	static __safeNames = ["irandom", "irandom_range", "random", "random_range", "choose", "randomize", "random_set_seed"];
	static __safePrefixes = ["draw_", "gpu_", "shader_", "surface_", "matrix_"];
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Hoists the lengths and rows the loops of one function ask for again and again into temporaries placed
	///          before the loop.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _registry = __gmlc_optimizer_pass_registry();
		var _state = {
			cx: _cx,
			root: _node,
			alias: _registry[$ "alias-analysis"],
			facts: undefined,
		};
		var _out;
		switch (_node.kind) {
			case __GMLC_NodeKind_Script: {
				var _body = __list(_state, _node.body);
				if (_body == undefined) return undefined;
				_out = variable_clone(_node, 0);
				_out.body = _body;
			break;}
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr: {
				var _block = __block(_state, _node.body);
				if (_block == undefined) return undefined;
				_out = variable_clone(_node, 0);
				_out.body = _block;
			break;}
			default:
			return undefined;
		}
		return _out;
	};
	#endregion
	
	#region Paths
	#region jsDoc
	/// @func    __derive(_node)
	/// @desc    Where a path starts and the members it goes through: a local, `global` or an implicit `self` variable,
	///          then dot accesses. Anything else has no path.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct.ASTNode} _node : The path
	/// @returns {Struct|Undefined} {root: "L", "G" or "S", name, members}
	#endregion
	static __derive = function(_node) {
		if (_node.origin != undefined) return undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				if (_symbol == undefined) return undefined;
				switch (_symbol.kind) {
					case "Local": return { root: "L", name: _node.name, members: [] };
					case "Self": return { root: "S", name: "", members: [_node.name] };
					case "BuiltinConstant":
						if (_node.name == "global") return { root: "G", name: "", members: [] };
					break;
				}
			return undefined;}
			case __GMLC_NodeKind_Index: {
				if (_node.accessor != "Dot") || (_node.member == undefined) return undefined;
				var _base = __derive(_node.object);
				if (_base == undefined) return undefined;
				_base.members = array_concat(_base.members, [_node.member]);
			return _base;}
		}
		return undefined;
	};
	
	#region jsDoc
	/// @func    __plainPath(_node)
	/// @desc    The root and members of a path that names an array or a list: a local, an implicit `self` variable,
	///          or a member chain from either or from `global`.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct.ASTNode} _node : The path
	/// @returns {Struct|Undefined}
	#endregion
	static __plainPath = function(_node) {
		var _path = __derive(_node);
		if (_path == undefined) return undefined;
		if (_path.root == "G") && (array_length(_path.members) == 0) return undefined;
		return _path;
	};
	
	#region jsDoc
	/// @func    __target(_arg)
	/// @desc    What the argument of a length call is: the path of the array or list, or a row of one (`a[i]` with a
	///          local or a literal for `i`). Anything else is undefined.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct.ASTNode} _arg : The argument
	/// @returns {Struct|Undefined} {root, name, members, row, base}: row is undefined or {index}, base the node of the array
	#endregion
	static __target = function(_arg) {
		var _plain = __plainPath(_arg);
		if (_plain != undefined) {
			return { root: _plain.root, name: _plain.name, members: _plain.members, row: undefined, base: _arg };
		}
		if (_arg.kind != __GMLC_NodeKind_Index) return undefined;
		if (_arg.accessor != "Array") || (array_length(_arg.keys) != 1) || (_arg.origin != undefined) return undefined;
		var _base = __plainPath(_arg.object);
		if (_base == undefined) return undefined;
		var _key = _arg.keys[0];
		var _index = undefined;
		if (_key.kind != __GMLC_NodeKind_Literal) {
			if (!__gmlc_opt_is_local(_key)) return undefined;
			_index = _key.name;
		}
		return { root: _base.root, name: _base.name, members: _base.members, row: { index: _index }, base: _arg.object };
	};
	
	#region jsDoc
	/// @func    __safeBuiltin(_name)
	/// @desc    Whether a call of a built-in changes no variable, array or list of the program and runs none of its
	///          code.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {String} _name : The built-in
	/// @returns {Bool}
	#endregion
	static __safeBuiltin = function(_name) {
		switch (__gmlc_opt_call_class(_name)) {
			case "pure": case "observer": case "render":
			return true;
			case "mutator": {
				if (array_contains(__safeNames, _name)) return true;
				var _i = 0; repeat (array_length(__safePrefixes)) {
					if (string_starts_with(_name, __safePrefixes[_i])) return true;
				_i++}
			return false;}
		}
		return false;
	};
	#endregion
	
	#region Tree
	#region jsDoc
	/// @func    __countSame(_node, _target)
	/// @desc    How many times the code _target is written under a node, nested functions left out.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct.ASTNode} _target : The code
	/// @returns {Real}
	#endregion
	static __countSame = function(_node, _target) {
		if (__gmlc_opt_is_function(_node)) return 0;
		if (__gmlc_opt_same(_node, _target)) return 1;
		var _n = 0;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					_n += __countSame(_child, _target);
				}
			_i++}
		_field_index++}
		return _n;
	};
	
	#region jsDoc
	/// @func    __mapChildren(_node, _target, _name)
	/// @desc    The node with every copy of the code _target in its children replaced by a read of the local _name, or
	///          undefined when it holds none. Only the changed nodes and the ones above them are copied.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct.ASTNode} _target : The code
	/// @param   {String}         _name   : The local
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __mapChildren = function(_node, _target, _name) {
		var _copy = undefined;
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new = __replaceSame(_slot.node, _target, _name);
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
	/// @func    __replaceSame(_node, _target, _name)
	/// @desc    The node with every copy of the code _target replaced by a read of the local _name, or undefined when
	///          it holds none.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct.ASTNode} _target : The code
	/// @param   {String}         _name   : The local
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __replaceSame = function(_node, _target, _name) {
		if (__gmlc_opt_is_function(_node)) return undefined;
		if (__gmlc_opt_same(_node, _target)) return __gmlc_opt_local(_name, _node.span);
		return __mapChildren(_node, _target, _name);
	};
	
	#region jsDoc
	/// @func    __loopParts(_loop)
	/// @desc    The test, the step and the body of a loop: what its iterations repeat.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct.ASTNode} _loop : The loop
	/// @returns {Array<Struct.ASTNode>}
	#endregion
	static __loopParts = function(_loop) {
		var _parts = [];
		if (_loop.kind == __GMLC_NodeKind_For) {
			if (_loop.test != undefined) array_push(_parts, _loop.test);
			if (_loop.update != undefined) array_push(_parts, _loop.update);
			array_push(_parts, _loop.body);
		}
		else if (_loop.kind == __GMLC_NodeKind_While) {
			array_push(_parts, _loop.test);
			array_push(_parts, _loop.body);
		}
		return _parts;
	};
	
	#region jsDoc
	/// @func    __replaceInLoop(_loop, _target, _name)
	/// @desc    A loop with every copy of the code _target in its test, step and body replaced by a read of the local
	///          _name.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct.ASTNode} _loop   : The loop
	/// @param   {Struct.ASTNode} _target : The code
	/// @param   {String}         _name   : The local
	/// @returns {Struct.ASTNode}
	#endregion
	static __replaceInLoop = function(_loop, _target, _name) {
		var _out = variable_clone(_loop, 0);
		if (_loop.kind == __GMLC_NodeKind_For) {
			if (_loop.test != undefined) {
				var _test = __replaceSame(_loop.test, _target, _name);
				if (_test != undefined) _out.test = _test;
			}
			if (_loop.update != undefined) {
				var _update = __replaceSame(_loop.update, _target, _name);
				if (_update != undefined) _out.update = _update;
			}
		}
		else if (_loop.kind == __GMLC_NodeKind_While) {
			var _whileTest = __replaceSame(_loop.test, _target, _name);
			if (_whileTest != undefined) _out.test = _whileTest;
		}
		var _body = __replaceSame(_loop.body, _target, _name);
		if (_body != undefined) _out.body = _body;
		return _out;
	};
	#endregion
	
	#region Scanning
	#region jsDoc
	/// @func    __facts(_state)
	/// @desc    The alias facts of the function, found when first needed.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct} _state : The pass state
	/// @returns {Struct}
	#endregion
	static __facts = function(_state) {
		if (_state.facts == undefined) _state.facts = _state.alias.analyze(_state.root, _state.cx.unit.fn_id);
		return _state.facts;
	};
	
	#region jsDoc
	/// @func    __writeIdentifier(_node, _region)
	/// @desc    Records the write of a name.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct.ASTNode} _node   : The name
	/// @param   {Struct}         _region : What the loop does
	#endregion
	static __writeIdentifier = function(_node, _region) {
		if (_node.kind != __GMLC_NodeKind_Identifier) || (_node.symbol == undefined) return;
		switch (_node.symbol.kind) {
			case "Local": array_push(_region.writes, { kind: "local", name: _node.name, object: undefined, index: undefined }); break;
			case "Self": array_push(_region.writes, { kind: "self", name: _node.name, object: undefined, index: undefined }); break;
		}
	};
	
	#region jsDoc
	/// @func    __scanTarget(_state, _target, _region)
	/// @desc    Records the write of an assignment or increment target and what runs inside it.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct}         _state  : The pass state
	/// @param   {Struct.ASTNode} _target : The target
	/// @param   {Struct}         _region : What the loop does
	#endregion
	static __scanTarget = function(_state, _target, _region) {
		if (_target.kind == __GMLC_NodeKind_Identifier) {
			__writeIdentifier(_target, _region);
		}
		else if (_target.kind == __GMLC_NodeKind_Index) {
			switch (_target.accessor) {
				case "Dot":
					array_push(_region.writes, { kind: "member", name: _target.member, object: undefined, index: undefined });
					__scan(_state, _target.object, _region);
				break;
				case "Array": case "Array2D": case "ArrayAt": case "Array2DAt": {
					var _plain = ((_target.accessor == "Array") || (_target.accessor == "ArrayAt")) && (array_length(_target.keys) == 1);
					array_push(_region.writes, { kind: "elem", name: "", object: _target.object, index: _plain ? _target.keys[0] : undefined });
					__scan(_state, _target.object, _region);
					var _k = 0; repeat (array_length(_target.keys)) {
						__scan(_state, _target.keys[_k], _region);
					_k++}
				break;}
				case "Struct": {
					array_push(_region.writes, { kind: "dynamic", name: "", object: undefined, index: undefined });
					__scan(_state, _target.object, _region);
					var _s = 0; repeat (array_length(_target.keys)) {
						__scan(_state, _target.keys[_s], _region);
					_s++}
				break;}
				default: {
					__scan(_state, _target.object, _region);
					var _d = 0; repeat (array_length(_target.keys)) {
						__scan(_state, _target.keys[_d], _region);
					_d++}
				break;}
			}
		}
		else {
			array_push(_region.writes, { kind: "all", name: "", object: undefined, index: undefined });
			__scan(_state, _target, _region);
		}
	};
	
	#region jsDoc
	/// @func    __scan(_state, _node, _region)
	/// @desc    What a node does: the unknown code it runs and the writes it makes.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct}         _state  : The pass state
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct}         _region : What the loop does
	#endregion
	static __scan = function(_state, _node, _region) {
		if (_state.cx.optimizer.__isNoOp(_node)) {
			_region.clobber = true;
			return;
		}
		switch (_node.kind) {
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr:
			return;
			case __GMLC_NodeKind_With:
			case __GMLC_NodeKind_Delete:
			case __GMLC_NodeKind_New:
			case __GMLC_NodeKind_MethodCall:
				_region.clobber = true;
			return;
			case __GMLC_NodeKind_Call: {
				var _builtin = __gmlc_opt_builtin_call(_node);
				if (_builtin != undefined) {
					if (!__safeBuiltin(_builtin)) _region.clobber = true;
				}
				else {
					_region.clobber = true;
					__scan(_state, _node.callee, _region);
				}
				var _a = 0; repeat (array_length(_node.args)) {
					__scan(_state, _node.args[_a], _region);
				_a++}
			return;}
			case __GMLC_NodeKind_Assign:
				__scanTarget(_state, _node.target, _region);
				__scan(_state, _node.value, _region);
			return;
			case __GMLC_NodeKind_Update:
				__scanTarget(_state, _node.argument, _region);
			return;
			case __GMLC_NodeKind_VarDecl:
				if (_node.init != undefined) __scan(_state, _node.init, _region);
				__writeIdentifier(_node.target, _region);
			return;
			case __GMLC_NodeKind_Try:
				__scan(_state, _node.block, _region);
				if (_node.catch_param != undefined) __writeIdentifier(_node.catch_param, _region);
				if (_node.catch_body != undefined) __scan(_state, _node.catch_body, _region);
				if (_node.finally_body != undefined) __scan(_state, _node.finally_body, _region);
			return;
		}
		var _children = _node.children();
		var _c = 0; repeat (array_length(_children)) {
			__scan(_state, _children[_c], _region);
		_c++}
	};
	
	#region jsDoc
	/// @func    __refuses(_state, _write, _target, _counter)
	/// @desc    Whether a write may change the length of the array a target reads, or its row. _counter is the loop
	///          variable of a test `i < array_length(a)` that the loop never writes: an element written at that index
	///          is inside the array.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct}        _state   : The pass state
	/// @param   {Struct}        _write   : {kind, name, object, index}
	/// @param   {Struct}        _target  : The target of the length call
	/// @param   {String|Undefined} _counter : The loop variable
	/// @returns {Bool}
	#endregion
	static __refuses = function(_state, _write, _target, _counter) {
		switch (_write.kind) {
			case "all": return true;
			case "local":
				return ((_target.root == "L") && (_target.name == _write.name))
					|| ((_target.row != undefined) && (_target.row.index == _write.name));
			case "self": return (_target.root == "S") && (_target.members[0] == _write.name);
			case "member": return array_contains(_target.members, _write.name);
			case "dynamic": return !((_target.root == "L") && (array_length(_target.members) == 0));
			case "elem": {
				if (_target.row != undefined) return true;
				if (__gmlc_opt_same(_write.object, _target.base)) {
					var _proven = (_counter != undefined) && (_write.index != undefined) && __gmlc_opt_is_local(_write.index) && (_write.index.name == _counter);
					return !_proven;
				}
				if (_target.root == "L") && (array_length(_target.members) == 0) && __gmlc_opt_is_local(_write.object) {
					return _state.alias.mayAlias(__facts(_state), _target.name, _write.object.name);
				}
				return true;
			}
		}
		return true;
	};
	#endregion
	
	#region Loops
	#region jsDoc
	/// @func    __collectCalls(_e, _out)
	/// @desc    The length calls an expression always makes, in evaluation order.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct.ASTNode}        _e   : The expression
	/// @param   {Array<Struct.ASTNode>} _out : The calls
	#endregion
	static __collectCalls = function(_e, _out) {
		switch (_e.kind) {
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr:
			case __GMLC_NodeKind_Assign:
			case __GMLC_NodeKind_Update:
			return;
			case __GMLC_NodeKind_Logical:
			case __GMLC_NodeKind_Nullish:
				__collectCalls(_e.left, _out);
			return;
			case __GMLC_NodeKind_Conditional:
				__collectCalls(_e.test, _out);
			return;
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_e);
				if ((_name == "array_length") || (_name == "ds_list_size")) && (array_length(_e.args) == 1) && (__target(_e.args[0]) != undefined) {
					var _seen = false;
					var _o = 0; repeat (array_length(_out)) {
						if (__gmlc_opt_same(_out[_o], _e)) _seen = true;
					_o++}
					if (!_seen) array_push(_out, _e);
				}
				else {
					var _a = 0; repeat (array_length(_e.args)) {
						__collectCalls(_e.args[_a], _out);
					_a++}
				}
			return;}
		}
		var _children = _e.children();
		var _c = 0; repeat (array_length(_children)) {
			__collectCalls(_children[_c], _out);
		_c++}
	};
	
	#region jsDoc
	/// @func    __initOk(_init)
	/// @desc    Whether the initializer of a `for` only sets its own locals from trivial values.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct.ASTNode|Undefined} _init : The initializer
	/// @returns {Bool}
	#endregion
	static __initOk = function(_init) {
		if (_init == undefined) return true;
		if (_init.kind == __GMLC_NodeKind_VarDeclList) {
			var _i = 0; repeat (array_length(_init.declarations)) {
				var _value = _init.declarations[_i].init;
				if (_value != undefined) && (!__gmlc_opt_is_trivial(_value)) return false;
			_i++}
			return true;
		}
		if (_init.kind == __GMLC_NodeKind_ExprStmt) {
			var _e = _init.expression;
			return (_e.kind == __GMLC_NodeKind_Assign) && (_e.op == "=") && __gmlc_opt_is_local(_e.target) && __gmlc_opt_is_trivial(_e.value);
		}
		return false;
	};
	
	#region jsDoc
	/// @func    __hoist(_state, _stmt)
	/// @desc    The statements that read the lengths and rows a loop keeps asking for, and the loop reading them, or
	///          undefined when nothing is hoisted.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _stmt  : The statement
	/// @returns {Struct|Undefined} {decls, node}
	#endregion
	static __hoist = function(_state, _stmt) {
		if (_state.cx.optimizer.__isNoOp(_stmt)) return undefined;
		var _init = undefined;
		var _update = undefined;
		var _test, _body;
		switch (_stmt.kind) {
			case __GMLC_NodeKind_For:
				if (_stmt.test == undefined) return undefined;
				_init = _stmt.init;
				_test = _stmt.test;
				_update = _stmt.update;
				_body = _stmt.body;
			break;
			case __GMLC_NodeKind_While:
				_test = _stmt.test;
				_body = _stmt.body;
			break;
			default:
			return undefined;
		}
		if (!__initOk(_init)) return undefined;
		var _calls = [];
		__collectCalls(_test, _calls);
		if (array_length(_calls) == 0) return undefined;
		var _region = { clobber: false, writes: [] };
		var _counterRegion = { clobber: false, writes: [] };
		if (_init != undefined) __scan(_state, _init, _region);
		__scan(_state, _test, _region);
		__scan(_state, _test, _counterRegion);
		if (_update != undefined) __scan(_state, _update, _region);
		__scan(_state, _body, _region);
		__scan(_state, _body, _counterRegion);
		if (_region.clobber) return undefined;
		var _span = __gmlc_opt_span_point(_stmt.span);
		var _decls = [];
		var _current = _stmt;
		var _c = 0; repeat (array_length(_calls)) {
			var _call = _calls[_c];
			var _target = __target(_call.args[0]);
			if (_target != undefined) {
				var _counter = undefined;
				if (_test.kind == __GMLC_NodeKind_Binary) && (_test.op == "<") && __gmlc_opt_same(_test.right, _call) && __gmlc_opt_is_local(_test.left) {
					_counter = _test.left.name;
				}
				if (_counter != undefined) {
					var _cw = 0; repeat (array_length(_counterRegion.writes)) {
						var _written = _counterRegion.writes[_cw];
						if (_written.kind == "local") && (_written.name == _counter) _counter = undefined;
					_cw++}
				}
				var _refused = false;
				var _w = 0; repeat (array_length(_region.writes)) {
					if (__refuses(_state, _region.writes[_w], _target, _counter)) {
						_refused = true;
						break;
					}
				_w++}
				if (!_refused) {
					var _parts = __loopParts(_current);
					var _present = 0;
					var _rows = 0;
					var _p = 0; repeat (array_length(_parts)) {
						_present += __countSame(_parts[_p], _call);
						_rows += __countSame(_parts[_p], _call.args[0]);
					_p++}
					if (_present > 0) {
						var _lengthCall = _call;
						if (_target.row != undefined) && (_rows >= 2) {
							var _rowName = _state.cx.optimizer.newTemporary(_state.cx);
							var _initRow = __gmlc_opt_clone(_call.args[0]);
							__gmlc_opt_retag_span(_initRow, _span);
							array_push(_decls, __gmlc_opt_var(_rowName, _initRow, _span));
							_current = __replaceInLoop(_current, _call.args[0], _rowName);
							_lengthCall = __gmlc_opt_clone(_call);
							_lengthCall.args[0] = __gmlc_opt_local(_rowName, _call.args[0].span);
							_state.cx.stats[$ "rows_hoisted"]++;
						}
						var _lengthName = _state.cx.optimizer.newTemporary(_state.cx);
						var _initLength = __gmlc_opt_clone(_lengthCall);
						__gmlc_opt_retag_span(_initLength, _span);
						array_push(_decls, __gmlc_opt_var(_lengthName, _initLength, _span));
						_current = __replaceInLoop(_current, _lengthCall, _lengthName);
						_state.cx.stats[$ "lengths_hoisted"]++;
					}
				}
			}
		_c++}
		if (array_length(_decls) == 0) return undefined;
		return { decls: _decls, node: _current };
	};
	#endregion
	
	#region Lists
	#region jsDoc
	/// @func    __list(_state, _stmts)
	/// @desc    A statement list with its loops hoisted, or undefined when nothing changes.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct}        _state : The pass state
	/// @param   {Array<Struct>} _stmts : The statements
	/// @returns {Array<Struct>|Undefined}
	#endregion
	static __list = function(_state, _stmts) {
		var _out = [];
		var _changed = false;
		var _s = 0; repeat (array_length(_stmts)) {
			var _statement = _stmts[_s];
			var _hoisted = __hoist(_state, _statement);
			if (_hoisted != undefined) {
				array_copy(_out, array_length(_out), _hoisted.decls, 0, array_length(_hoisted.decls));
				_statement = _hoisted.node;
				_changed = true;
			}
			var _nested = __nested(_state, _statement);
			if (_nested != undefined) {
				_statement = _nested;
				_changed = true;
			}
			array_push(_out, _statement);
		_s++}
		return _changed ? _out : undefined;
	};
	
	#region jsDoc
	/// @func    __block(_state, _node)
	/// @desc    A block with its loops hoisted, or undefined when nothing changes.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _node  : The block
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __block = function(_state, _node) {
		if (_node.kind != __GMLC_NodeKind_Block) return undefined;
		var _body = __list(_state, _node.body);
		if (_body == undefined) return undefined;
		var _out = variable_clone(_node, 0);
		_out.body = _body;
		return _out;
	};
	
	#region jsDoc
	/// @func    __nested(_state, _stmt)
	/// @desc    A statement with the lists inside it hoisted, or undefined when nothing changes.
	/// @self    GMLC_Opt_ArrayAccessCache
	/// @param   {Struct}         _state : The pass state
	/// @param   {Struct.ASTNode} _stmt  : The statement
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __nested = function(_state, _stmt) {
		if (_state.cx.optimizer.__isNoOp(_stmt)) return undefined;
		switch (_stmt.kind) {
			case __GMLC_NodeKind_If: {
				var _consequent = __block(_state, _stmt.consequent);
				var _alternate = (_stmt.alternate != undefined) ? __block(_state, _stmt.alternate) : undefined;
				if (_consequent == undefined) && (_alternate == undefined) return undefined;
				var _if = variable_clone(_stmt, 0);
				if (_consequent != undefined) _if.consequent = _consequent;
				if (_alternate != undefined) _if.alternate = _alternate;
			return _if;}
			case __GMLC_NodeKind_For:
			case __GMLC_NodeKind_While:
			case __GMLC_NodeKind_Repeat:
			case __GMLC_NodeKind_DoUntil: {
				var _body = __block(_state, _stmt.body);
				if (_body == undefined) return undefined;
				var _loop = variable_clone(_stmt, 0);
				_loop.body = _body;
			return _loop;}
			case __GMLC_NodeKind_Block:
			return __block(_state, _stmt);
			case __GMLC_NodeKind_Switch: {
				var _switch = undefined;
				var _k = 0; repeat (array_length(_stmt.cases)) {
					var _case = _stmt.cases[_k];
					var _list = __list(_state, _case.body);
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
				var _try = __block(_state, _stmt.block);
				var _catch = (_stmt.catch_body != undefined) ? __block(_state, _stmt.catch_body) : undefined;
				var _finally = (_stmt.finally_body != undefined) ? __block(_state, _stmt.finally_body) : undefined;
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
}
