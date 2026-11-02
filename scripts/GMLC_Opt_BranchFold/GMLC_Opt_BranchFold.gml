#region jsDoc
/// @func    GMLC_Opt_BranchFold()
/// @desc    Folds a branch or loop whose condition is a known constant: `if (false) { a(); }` goes,
///          `if (true) { a(); } else { b(); }` becomes `a();`, `c ? x : x` becomes `x`, `for (var i = f(); false; i++)`
///          becomes `var i = f();`, `while (false)` and `repeat (0)` go, `do { a(); } until (true)` runs its body
///          once, and a `switch` on a constant becomes the body of the case it picks. A removed part keeps its
///          `static` and function declarations, and a part that declares a `var` is not removed unless the part
///          that runs declares the same names.
/// @returns {Struct.GMLC_Opt_BranchFold}
#endregion
function GMLC_Opt_BranchFold() : GMLC_OptimizerPass("branch-fold") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The statement list with the branches and loops of its statements folded, or undefined when none
	///          folds. Nested statement lists are folded when they are visited themselves.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _node : The statement list
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _body = _node.body;
		var _out = undefined;
		var _i = 0; repeat (array_length(_body)) {
			var _new = __fold(_body[_i], _cx, _node, 0);
			if (_new != undefined) {
				if (_out == undefined) {
					_out = array_create(array_length(_body));
					array_copy(_out, 0, _body, 0, array_length(_body));
				}
				_out[_i] = _new;
			}
		_i++}
		if (_out == undefined) return undefined;
		var _copy = variable_clone(_node, 0);
		_copy.body = _out;
		return _copy;
	};
	#endregion

	#region Private
	#region Walk
	#region jsDoc
	/// @func    __fold(_node, _cx, _parent, _index)
	/// @desc    Folds what can be folded in a statement or an expression, inner parts first. Statement lists and
	///          functions are left to their own visit.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct}         _cx     : The pass context
	/// @param   {Struct.ASTNode} _parent : The node that holds it
	/// @param   {Real}           _index  : Its place among the children of the parent
	/// @returns {Struct.ASTNode|Undefined} The node to put in its place, undefined for none
	#endregion
	static __fold = function(_node, _cx, _parent, _index) {
		if (_cx.optimizer.__isNoOp(_node)) return undefined;
		if (__isList(_node.kind)) || (__gmlc_opt_is_function(_node)) return undefined;
		var _current = _node;
		var _copied = undefined;
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new = __fold(_slot.node, _cx, _node, _i);
			if (_new != undefined) {
				if (_copied == undefined) {
					_copied = {};
					_current = variable_clone(_node, 0);
				}
				if (_slot.index == undefined) {
					_current[$ _slot.key] = _new;
				}
				else {
					if (!struct_exists(_copied, _slot.key)) {
						_current[$ _slot.key] = variable_clone(_node[$ _slot.key], 0);
						_copied[$ _slot.key] = true;
					}
					_current[$ _slot.key][_slot.index] = _new;
				}
			}
		_i++}
		var _folded = undefined;
		switch (_current.kind) {
			case __GMLC_NodeKind_If:          _folded = __foldIf(_current, _cx, _parent); break;
			case __GMLC_NodeKind_Conditional: _folded = __foldConditional(_current, _cx, _parent, _index); break;
			case __GMLC_NodeKind_For:         _folded = __foldFor(_current, _cx, _parent); break;
			case __GMLC_NodeKind_While:       _folded = __foldWhile(_current, _cx, _parent); break;
			case __GMLC_NodeKind_Repeat:      _folded = __foldRepeat(_current, _cx, _parent); break;
			case __GMLC_NodeKind_DoUntil:     _folded = __foldDoUntil(_current, _cx); break;
			case __GMLC_NodeKind_Switch:      _folded = __foldSwitch(_current, _cx, _parent); break;
		}
		if (_folded != undefined) return _folded;
		return (_copied != undefined) ? _current : undefined;
	};

	#region jsDoc
	/// @func    __isList(_kind)
	/// @desc    Whether a node kind holds a statement list.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Real} _kind : The node kind
	/// @returns {Bool}
	#endregion
	static __isList = function(_kind) {
		return (_kind == __GMLC_NodeKind_Script) || (_kind == __GMLC_NodeKind_Block) || (_kind == __GMLC_NodeKind_Case) || (_kind == __GMLC_NodeKind_Default);
	};
	#endregion

	#region Folds
	#region jsDoc
	/// @func    __foldIf(_node, _cx, _parent)
	/// @desc    `if` with a constant condition gives the branch it takes; `if (c) a else a` with a trivial `c`
	///          gives `a`.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _node   : The `if`
	/// @param   {Struct}         _cx     : The pass context
	/// @param   {Struct.ASTNode} _parent : The node that holds it
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __foldIf = function(_node, _cx, _parent) {
		var _optimizer = _cx.optimizer;
		var _test = _optimizer.__constantValue(_node.test);
		if (_test[0]) && (is_numeric(_test[1])) {
			var _truthy = false;
			if (_test[1]) _truthy = true;
			var _dropped = (_truthy) ? _node.alternate : _node.consequent;
			var _taken = (_truthy) ? _node.consequent : _node.alternate;
			var _salvage = [];
			if (_dropped != undefined) {
				_salvage = __drop([_dropped], _cx, _taken);
				if (_salvage == undefined) return undefined;
			}
			_cx.stats[$ "branches_folded"]++;
			return __assemble(_taken, _salvage, !_truthy, _node, _parent);
		}
		if (_node.alternate != undefined) && (__gmlc_opt_is_trivial(_node.test)) && (__gmlc_opt_same(_node.consequent, _node.alternate)) && (!_optimizer.__keepsCode(_node.alternate)) {
			_cx.stats[$ "branches_folded"]++;
			return _node.consequent;
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __foldConditional(_node, _cx, _parent, _index)
	/// @desc    `c ? a : b` with a constant condition gives the branch it takes; `c ? a : a` with a trivial `c`
	///          gives `a`.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _node   : The conditional
	/// @param   {Struct}         _cx     : The pass context
	/// @param   {Struct.ASTNode} _parent : The node that holds it
	/// @param   {Real}           _index  : Its place among the children of the parent
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __foldConditional = function(_node, _cx, _parent, _index) {
		var _optimizer = _cx.optimizer;
		var _taken;
		var _dropped;
		var _test = _optimizer.__constantValue(_node.test);
		if (_test[0]) && (is_numeric(_test[1])) {
			var _truthy = false;
			if (_test[1]) _truthy = true;
			_taken = (_truthy) ? _node.consequent : _node.alternate;
			_dropped = (_truthy) ? _node.alternate : _node.consequent;
		}
		else if (__gmlc_opt_is_trivial(_node.test)) && (__gmlc_opt_same(_node.consequent, _node.alternate)) {
			_taken = _node.consequent;
			_dropped = _node.alternate;
		}
		else {
			return undefined;
		}
		if (_optimizer.__keepsCode(_dropped)) return undefined;
		// only the object of `a.b` and `a.b()` keeps its expression, and `self` alone would be the new struct
		var _constant = _optimizer.__constantValue(_taken);
		if (_constant[0]) && (_index == 0) && ((_parent.kind == __GMLC_NodeKind_Index) || (_parent.kind == __GMLC_NodeKind_MethodCall)) return undefined;
		if (_parent.kind == __GMLC_NodeKind_StructEntry) && (_taken.kind == __GMLC_NodeKind_Identifier) && (_taken.name == "self") return undefined;
		_cx.stats[$ "branches_folded"]++;
		return _taken;
	};

	#region jsDoc
	/// @func    __foldFor(_node, _cx, _parent)
	/// @desc    `for` with a constant false condition gives its first statement.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _node   : The `for`
	/// @param   {Struct}         _cx     : The pass context
	/// @param   {Struct.ASTNode} _parent : The node that holds it
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __foldFor = function(_node, _cx, _parent) {
		if (_node.test == undefined) return undefined;
		var _test = _cx.optimizer.__constantValue(_node.test);
		if (!_test[0]) || (!is_numeric(_test[1])) || (_test[1]) return undefined;
		var _dropped = [_node.body];
		if (_node.update != undefined) array_push(_dropped, _node.update);
		var _salvage = __drop(_dropped, _cx);
		if (_salvage == undefined) return undefined;
		_cx.stats[$ "loops_removed"]++;
		return __assemble(_node.init, _salvage, false, _node, _parent);
	};

	#region jsDoc
	/// @func    __foldWhile(_node, _cx, _parent)
	/// @desc    `while` with a constant false condition goes.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _node   : The `while`
	/// @param   {Struct}         _cx     : The pass context
	/// @param   {Struct.ASTNode} _parent : The node that holds it
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __foldWhile = function(_node, _cx, _parent) {
		var _test = _cx.optimizer.__constantValue(_node.test);
		if (!_test[0]) || (!is_numeric(_test[1])) || (_test[1]) return undefined;
		var _salvage = __drop([_node.body], _cx);
		if (_salvage == undefined) return undefined;
		_cx.stats[$ "loops_removed"]++;
		return __assemble(undefined, _salvage, false, _node, _parent);
	};

	#region jsDoc
	/// @func    __foldRepeat(_node, _cx, _parent)
	/// @desc    `repeat` of a constant count of 0 or less goes.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _node   : The `repeat`
	/// @param   {Struct}         _cx     : The pass context
	/// @param   {Struct.ASTNode} _parent : The node that holds it
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __foldRepeat = function(_node, _cx, _parent) {
		var _count = _cx.optimizer.__constantValue(_node.count);
		if (!_count[0]) || (!is_numeric(_count[1])) || (_count[1] > 0) return undefined;
		var _salvage = __drop([_node.body], _cx);
		if (_salvage == undefined) return undefined;
		_cx.stats[$ "loops_removed"]++;
		return __assemble(undefined, _salvage, false, _node, _parent);
	};

	#region jsDoc
	/// @func    __foldDoUntil(_node, _cx)
	/// @desc    `do { body } until (true)` gives its body when no `break` or `continue` belongs to the loop.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _node : The `do until`
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __foldDoUntil = function(_node, _cx) {
		var _test = _cx.optimizer.__constantValue(_node.test);
		if (!_test[0]) || (!is_numeric(_test[1])) || (!_test[1]) return undefined;
		if (__jumps(_node.body, false, false, false)) return undefined;
		_cx.stats[$ "loops_removed"]++;
		return _node.body;
	};

	#region jsDoc
	/// @func    __foldSwitch(_node, _cx, _parent)
	/// @desc    `switch` on a constant gives the body of the case it picks, when that case ends in `break` and
	///          neither it nor any `continue` could leave the `switch` another way.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _node   : The `switch`
	/// @param   {Struct}         _cx     : The pass context
	/// @param   {Struct.ASTNode} _parent : The node that holds it
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __foldSwitch = function(_node, _cx, _parent) {
		var _optimizer = _cx.optimizer;
		var _discriminant = _optimizer.__constantValue(_node.discriminant);
		if (!_discriminant[0]) return undefined;
		var _cases = _node.cases;
		var _count = array_length(_cases);
		var _start = -1;
		var _default = -1;
		var _i = 0; repeat (_count) {
			var _case = _cases[_i];
			if (_case.kind == __GMLC_NodeKind_Default) {
				_default = _i;
			}
			else {
				var _value = _optimizer.__constantValue(_case.test);
				if (!_value[0]) return undefined;
				var _equal = __equals(_discriminant[1], _value[1], _cx);
				if (_equal == undefined) return undefined;
				if (_equal) {
					_start = _i;
					break;
				}
			}
		_i++}
		if (_start < 0) _start = _default;
		var _kept = [];
		if (_start >= 0) {
			var _body = _cases[_start].body;
			var _length = array_length(_body);
			if (_length == 0) return undefined;
			var _last = _body[_length - 1];
			if (_last.kind != __GMLC_NodeKind_Break) || (_optimizer.__isNoOp(_last)) return undefined;
			var _k = 0; repeat (_length - 1) {
				if (__jumps(_body[_k], false, false, true)) return undefined;
				array_push(_kept, _body[_k]);
			_k++}
		}
		var _dropped_before = [];
		var _dropped_after = [];
		var _j = 0; repeat (_count) {
			if (_j != _start) {
				array_push((_j < _start) ? _dropped_before : _dropped_after, _cases[_j]);
			}
		_j++}
		var _salvage_before = __drop(_dropped_before, _cx);
		if (_salvage_before == undefined) return undefined;
		var _salvage_after = __drop(_dropped_after, _cx);
		if (_salvage_after == undefined) return undefined;
		var _result = [];
		__append(_result, _salvage_before);
		__append(_result, _kept);
		__append(_result, _salvage_after);
		_cx.stats[$ "branches_folded"]++;
		if (array_length(_result) == 0) return __empty(_node.span, _parent);
		return new ASTBlock(_node.span, _result, _node.origin);
	};
	#endregion

	#region Dropped code
	#region jsDoc
	/// @func    __drop(_regions, _cx, _taken)
	/// @desc    What has to stay of code a fold removes: the `static` and function declarations among the direct
	///          statements of a block. Undefined when the code cannot go: it is frozen or references an asset, or
	///          it declares a `var` the part that runs (`_taken`) does not declare too, or anything deeper that
	///          would be lost.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Array<Struct.ASTNode>}    _regions : The removed statements, cases or expressions, in source order
	/// @param   {Struct}                   _cx      : The pass context
	/// @param   {Struct.ASTNode|Undefined} _taken   : The part that runs, undefined for none
	/// @returns {Array<Struct.ASTNode>|Undefined}
	#endregion
	static __drop = function(_regions, _cx, _taken = undefined) {
		var _kept_vars = {};
		if (_taken != undefined) __onlyVars(_taken, _kept_vars);
		var _keep = [];
		var _optimizer = _cx.optimizer;
		var _r = 0; repeat (array_length(_regions)) {
			var _region = _regions[_r];
			if (_optimizer.__keepsCode(_region)) return undefined;
			var _list = (__isList(_region.kind)) ? _region.body : [_region];
			var _s = 0; repeat (array_length(_list)) {
				var _statement = _list[_s];
				var _kind = _statement.kind;
				if (_kind == __GMLC_NodeKind_FunctionDecl) || (_kind == __GMLC_NodeKind_ConstructorDecl) {
					array_push(_keep, _statement);
				}
				else if (_kind == __GMLC_NodeKind_StaticDecl) && (!__mentionsLocal(_statement)) {
					array_push(_keep, _statement);
				}
				else if (__gmlc_opt_declares(_statement)) && (!__redeclared(_statement, _kept_vars)) {
					_cx.stats[$ "refused_declares"]++;
					return undefined;
				}
			_s++}
		_r++}
		return _keep;
	};

	#region jsDoc
	/// @func    __assemble(_taken, _salvage, _before, _node, _parent)
	/// @desc    The statement that takes the place of a folded one: the part it keeps, with the declarations that
	///          had to stay before or after it.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode|Undefined} _taken   : The part that runs, undefined for none
	/// @param   {Array<Struct.ASTNode>}    _salvage : The declarations that stay
	/// @param   {Bool}                     _before  : Whether the declarations come before the part
	/// @param   {Struct.ASTNode}           _node    : The folded statement
	/// @param   {Struct.ASTNode}           _parent  : The node that holds it
	/// @returns {Struct.ASTNode}
	#endregion
	static __assemble = function(_taken, _salvage, _before, _node, _parent) {
		var _count = array_length(_salvage);
		if (_count == 0) {
			if (_taken != undefined) return _taken;
			return __empty(_node.span, _parent);
		}
		var _body = [];
		if (_before) __append(_body, _salvage);
		if (_taken != undefined) array_push(_body, _taken);
		if (!_before) __append(_body, _salvage);
		return new ASTBlock(_node.span, _body, _node.origin);
	};

	#region jsDoc
	/// @func    __append(_out, _statements)
	/// @desc    Adds the statements to the end of a list.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Array<Struct.ASTNode>} _out        : The list
	/// @param   {Array<Struct.ASTNode>} _statements : The statements
	#endregion
	static __append = function(_out, _statements) {
		array_copy(_out, array_length(_out), _statements, 0, array_length(_statements));
	};
	
	#region jsDoc
	/// @func    __empty(_span, _parent)
	/// @desc    Nothing, as a statement: an empty statement in a statement list, an empty block anywhere else.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.GMLC_Span} _span   : The span
	/// @param   {Struct.ASTNode}   _parent : The node that holds it
	/// @returns {Struct.ASTNode}
	#endregion
	static __empty = function(_span, _parent) {
		if (__isList(_parent.kind)) return new ASTEmpty(_span);
		return new ASTBlock(_span, []);
	};

	#region jsDoc
	/// @func    __redeclared(_statement, _kept)
	/// @desc    Whether everything a statement declares is a `var` that code staying in the function declares too
	///          (`var` is function wide, so the dropped declaration changes nothing).
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {Struct}         _kept      : The `var` names the staying code declares, as keys
	/// @returns {Bool}
	#endregion
	static __redeclared = function(_statement, _kept) {
		var _names = {};
		if (!__onlyVars(_statement, _names)) return false;
		var _list = struct_get_names(_names);
		if (array_length(_list) == 0) return false;
		var _i = 0; repeat (array_length(_list)) {
			if (!struct_exists(_kept, _list[_i])) return false;
		_i++}
		return true;
	};

	#region jsDoc
	/// @func    __onlyVars(_node, _names)
	/// @desc    Adds the names of the `var` declarations under a node, outside the function expressions in it, to
	///          `_names`; whether the node declares nothing else.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Struct}         _names : The names so far, as keys
	/// @returns {Bool}
	#endregion
	static __onlyVars = function(_node, _names) {
		switch (_node.kind) {
			case __GMLC_NodeKind_VarDeclList: {
				var _plain = true;
				var _decls = _node.declarations;
				var _d = 0; repeat (array_length(_decls)) {
					var _decl = _decls[_d];
					if (_decl.kind == __GMLC_NodeKind_VarDecl) && (_decl.target.kind == __GMLC_NodeKind_Identifier) {
						_names[$ _decl.target.name] = true;
					}
					else {
						_plain = false;
					}
					var _children = _decl.children();
					var _c = 0; repeat (array_length(_children)) {
						if (!__onlyVars(_children[_c], _names)) _plain = false;
					_c++}
				_d++}
				return _plain;
			}
			case __GMLC_NodeKind_FunctionExpr:
			return true;
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_StaticDecl:
			case __GMLC_NodeKind_GlobalVarDecl:
			case __GMLC_NodeKind_EnumDecl:
			return false;
			case __GMLC_NodeKind_Try:
			if (_node.catch_param != undefined) return false;
			break;
		}
		var _plain = true;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__onlyVars(_child, _names)) _plain = false;
				}
			_i++}
		_field_index++}
		return _plain;
	};

	#region jsDoc
	/// @func    __mentionsLocal(_node)
	/// @desc    Whether a node reads or writes a `var` local or a parameter, outside the function expressions in it.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __mentionsLocal = function(_node) {
		if (_node.kind == __GMLC_NodeKind_Identifier) return __gmlc_opt_is_local(_node);
		if (_node.kind == __GMLC_NodeKind_FunctionExpr) return false;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__mentionsLocal(_child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};
	#endregion

	#region Switch and loop facts
	#region jsDoc
	/// @func    __jumps(_node, _bound_break, _bound_continue, _any_continue)
	/// @desc    Whether a `break` or a `continue` under a node would leave the loop or `switch` that holds the
	///          node: a `break` counts outside any loop, `switch` or `with` inside the node, a `continue` outside
	///          any loop or `with` (anywhere with _any_continue).
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Struct.ASTNode} _node           : The node
	/// @param   {Bool}           _bound_break    : Whether a loop, `switch` or `with` already holds the node
	/// @param   {Bool}           _bound_continue : Whether a loop or `with` already holds the node
	/// @param   {Bool}           _any_continue   : Whether every `continue` counts
	/// @returns {Bool}
	#endregion
	static __jumps = function(_node, _bound_break, _bound_continue, _any_continue) {
		var _kind = _node.kind;
		if (__gmlc_opt_is_function(_node)) return false;
		if (_kind == __GMLC_NodeKind_Break) return !_bound_break;
		if (_kind == __GMLC_NodeKind_Continue) return _any_continue || !_bound_continue;
		var _break = _bound_break;
		var _continue = _bound_continue;
		switch (_kind) {
			case __GMLC_NodeKind_For:
			case __GMLC_NodeKind_While:
			case __GMLC_NodeKind_Repeat:
			case __GMLC_NodeKind_DoUntil:
			case __GMLC_NodeKind_With:
			_break = true;
			_continue = true;
			break;
			case __GMLC_NodeKind_Switch:
			_break = true;
			break;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__jumps(_child, _break, _continue, _any_continue)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};

	#region jsDoc
	/// @func    __equals(_a, _b, _cx)
	/// @desc    Whether a `switch` value equals a case value, for two numbers or two strings; undefined when the
	///          comparison is not safe to decide while compiling.
	/// @self    GMLC_Opt_BranchFold
	/// @param   {Any}    _a  : The value switched on
	/// @param   {Any}    _b  : The case value
	/// @param   {Struct} _cx : The pass context
	/// @returns {Bool|Undefined}
	#endregion
	static __equals = function(_a, _b, _cx) {
		if (is_numeric(_a)) && (is_numeric(_b)) {
			if (_cx.epsilon_set) && ((typeof(_a) == "number") || (typeof(_b) == "number")) return undefined;
			return (_a == _b);
		}
		if (is_string(_a)) && (is_string(_b)) return (_a == _b);
		return undefined;
	};
	#endregion
	#endregion
}
