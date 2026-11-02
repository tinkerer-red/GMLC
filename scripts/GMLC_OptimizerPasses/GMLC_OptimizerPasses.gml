#region jsDoc
/// @func    GMLC_OptimizerPass(_name)
/// @desc    The base of an optimizer pass; a child sets `run` as a static. The optimizer finds a pass by the name
///          the pass list (`__GmlcDataPasses`) gives it, and applies it where the schedule names it, with the granularity the pass
///          list gives: `run(_node, _cx)` gets an expression, a statement list or a whole function and returns the
///          node to put in its place, or undefined to keep it. It never changes the node it is given.
///          `_cx` is {stats, unit, optimizer, script, sources, env, new_locals, preserve_lines, epsilon_set,
///          condition, assigned, flags}. For an expression, `condition` tells whether it is only asked whether it
///          is true, `assigned` names the `var` local it is the value of, and `flags` is for the pass to keep what
///          it computed once for the function.
///          A pass that works in place on one node at a time sets `sweep(_node_data, _o)` instead of `run`
///          (constant-fold, constant-propagate, dead-code, library-call-rewrite): the optimizer runs the sweeps of a
///          step together over the tree, inner nodes first, with `_node_data` {node, parent, key, index} and itself as
///          `_o`, and the sweep returns the node to put in the place of the one it was given.
/// @param   {String} _name : The pass's name in the pass list
/// @returns {Struct.GMLC_OptimizerPass}
#endregion
function GMLC_OptimizerPass(_name) constructor {
	#region Config
	static run = undefined;
	static sweep = undefined; // set instead of `run` by a pass the optimizer runs as one sweep over the tree (see GMLC_Gen_5_Optimizer)
	#endregion

	#region Init
	name = _name;
	#endregion
}

#region jsDoc
/// @func    gmlc_register_optimizer_pass(_pass)
/// @desc    Makes an optimizer pass known by its name, replacing one of the same name. Its `run` is bound to the pass,
///          so its own statics are reachable from it.
/// @param   {Struct.GMLC_OptimizerPass} _pass : The pass
/// @returns {Struct.GMLC_OptimizerPass}
#endregion
function gmlc_register_optimizer_pass(_pass) {
	if (_pass.run != undefined) _pass.run = method(_pass, _pass.run);
	if (_pass.sweep != undefined) _pass.sweep = method(_pass, _pass.sweep);
	var _registry = __gmlc_optimizer_pass_registry();
	_registry[$ _pass.name] = _pass;
	return _pass;
}

#region jsDoc
/// @func    __gmlc_optimizer_pass_registry()
/// @desc    The known optimizer passes by name, in the order of the pass list.
/// @returns {Struct} name to Struct.GMLC_OptimizerPass
#endregion
function __gmlc_optimizer_pass_registry() {
	static __registry = undefined;
	if (__registry == undefined) {
		__registry = {};
		#region Registered passes
		gmlc_register_optimizer_pass(new GMLC_Opt_SimplifyCfgBlocks());
		gmlc_register_optimizer_pass(new GMLC_Opt_ConstantFold());
		gmlc_register_optimizer_pass(new GMLC_Opt_ConstantPropagate());
		gmlc_register_optimizer_pass(new GMLC_Opt_CopyPropagate());
		gmlc_register_optimizer_pass(new GMLC_Opt_AlgebraicSimplify());
		gmlc_register_optimizer_pass(new GMLC_Opt_BooleanSimplify());
		gmlc_register_optimizer_pass(new GMLC_Opt_ComparisonSimplify());
		gmlc_register_optimizer_pass(new GMLC_Opt_BranchFold());
		gmlc_register_optimizer_pass(new GMLC_Opt_UnreachableCode());
		gmlc_register_optimizer_pass(new GMLC_Opt_DeadStore());
		gmlc_register_optimizer_pass(new GMLC_Opt_DeadCode());
		gmlc_register_optimizer_pass(new GMLC_Opt_CommonSubexpression());
		gmlc_register_optimizer_pass(new GMLC_Opt_RedundantCallElim());
		gmlc_register_optimizer_pass(new GMLC_Opt_ConstantFunctionEval());
		gmlc_register_optimizer_pass(new GMLC_Opt_LoopInvariantMotion());
		gmlc_register_optimizer_pass(new GMLC_Opt_InductionVariableSimplify());
		gmlc_register_optimizer_pass(new GMLC_Opt_StrengthReduce());
		gmlc_register_optimizer_pass(new GMLC_Opt_LoopUnroll());
		gmlc_register_optimizer_pass(new GMLC_Opt_LoopFuse());
		gmlc_register_optimizer_pass(new GMLC_Opt_LoopInterchange());
		gmlc_register_optimizer_pass(new GMLC_Opt_LoopReroll());
		gmlc_register_optimizer_pass(new GMLC_Opt_ReductionRecognize());
		gmlc_register_optimizer_pass(new GMLC_Opt_InlineSmallFunctions());
		gmlc_register_optimizer_pass(new GMLC_Opt_StructAccessCache());
		gmlc_register_optimizer_pass(new GMLC_Opt_ArrayAccessCache());
		gmlc_register_optimizer_pass(new GMLC_Opt_AliasAnalysis());
		gmlc_register_optimizer_pass(new GMLC_Opt_BranchMerge());
		gmlc_register_optimizer_pass(new GMLC_Opt_NullishHoist());
		gmlc_register_optimizer_pass(new GMLC_Opt_LibraryCallRewrite());
		gmlc_register_optimizer_pass(new GMLC_Opt_ConstantAggregateHoist());
		gmlc_register_optimizer_pass(new GMLC_Opt_NoncapturingClosureHoist());
		gmlc_register_optimizer_pass(new GMLC_Opt_ScalarReplaceAggregates());
		gmlc_register_optimizer_pass(new GMLC_Opt_CallbackInline());
		gmlc_register_optimizer_pass(new GMLC_Opt_WithInvariantMotion());
		gmlc_register_optimizer_pass(new GMLC_Opt_IndirectCallResolve());
		gmlc_register_optimizer_pass(new GMLC_Opt_CodeSinking());
		gmlc_register_optimizer_pass(new GMLC_Opt_LoopUnswitch());
		gmlc_register_optimizer_pass(new GMLC_Opt_WriteOnceGlobalConstify());
		gmlc_register_optimizer_pass(new GMLC_Opt_JumpThreading());
		gmlc_register_optimizer_pass(new GMLC_Opt_CorrelatedFactPropagation());
		gmlc_register_optimizer_pass(new GMLC_Opt_SparseConditionalConstantPropagation());
		gmlc_register_optimizer_pass(new GMLC_Opt_LoopStoreSinking());
		gmlc_register_optimizer_pass(new GMLC_Opt_MemoryDeadStoreElimination());
		gmlc_register_optimizer_pass(new GMLC_Opt_IdempotentSearchLoopBreak());
		gmlc_register_optimizer_pass(new GMLC_Opt_StructKeyHashHoist());
		gmlc_register_optimizer_pass(new GMLC_Opt_UnusedFieldElimination());
		gmlc_register_optimizer_pass(new GMLC_Opt_WithFuse());
		gmlc_register_optimizer_pass(new GMLC_Opt_ArrayPipelineFuse());
		gmlc_register_optimizer_pass(new GMLC_Opt_StringAccumulateToBuffer());
		gmlc_register_optimizer_pass(new GMLC_Opt_ArrayPresize());
		gmlc_register_optimizer_pass(new GMLC_Opt_RenderStateRedundancy());
		gmlc_register_optimizer_pass(new GMLC_Opt_CountedLoopToRepeat());
		gmlc_register_optimizer_pass(new GMLC_Opt_BuiltinGetterToAccessor());
		gmlc_register_optimizer_pass(new GMLC_Opt_SingleUseForwardSubstitution());
		gmlc_register_optimizer_pass(new GMLC_Opt_LoopCarriedLoadReuse());
		gmlc_register_optimizer_pass(new GMLC_Opt_FunctionSpecialization());
		gmlc_register_optimizer_pass(new GMLC_Opt_PartialRedundancyElimination());
		gmlc_register_optimizer_pass(new GMLC_Opt_LoopPeelAndSplit());
		gmlc_register_optimizer_pass(new GMLC_Opt_ClosedFormLoopEvaluation());
		gmlc_register_optimizer_pass(new GMLC_Opt_DeadArgumentAndReturnElimination());
		gmlc_register_optimizer_pass(new GMLC_Opt_ValueRangeSimplify());
		gmlc_register_optimizer_pass(new GMLC_Opt_RedundantConversionElim());
		gmlc_register_optimizer_pass(new GMLC_Opt_FloorDivToDiv());
		#endregion
	}
	return __registry;
}

#region Pass helpers
#region jsDoc
/// @func    __gmlc_opt_call_class(_name)
/// @desc    The effect class of a built-in function: pure, observer, render or mutator; unknown for one the effect
///          table does not list and for every other function.
/// @param   {String} _name : The function's name
/// @returns {String}
#endregion
function __gmlc_opt_call_class(_name) {
	var _effects = __GmlcDataEffects();
	var _entry = _effects[$ _name];
	return (_entry != undefined) ? _entry.class : "unknown";
}

#region jsDoc
/// @func    __gmlc_opt_builtin_call(_node)
/// @desc    The name of the built-in function a Call node calls directly, or undefined.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {String|Undefined}
#endregion
function __gmlc_opt_builtin_call(_node) {
	if (_node.kind != __GMLC_NodeKind_Call) return undefined;
	var _callee = _node.callee;
	if (_callee.kind != __GMLC_NodeKind_Identifier) || (_callee.symbol == undefined) || (_callee.symbol.kind != "BuiltinFunction") return undefined;
	return _callee.name;
}

#region jsDoc
/// @func    __gmlc_opt_is_local(_node)
/// @desc    Whether a node reads a `var` local or a parameter.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_is_local(_node) {
	return (_node != undefined) && (_node.kind == __GMLC_NodeKind_Identifier) && (_node.symbol != undefined) && (_node.symbol.kind == "Local");
}

#region jsDoc
/// @func    __gmlc_opt_child_index(_parent, _child)
/// @desc    The place of a child among the children of its parent, or -1 when it is not one.
/// @param   {Struct.ASTNode} _parent : The parent
/// @param   {Struct.ASTNode} _child  : The child
/// @returns {Real}
#endregion
function __gmlc_opt_child_index(_parent, _child) {
	return array_get_index(_parent.children(), _child);
}

#region jsDoc
/// @func    __gmlc_opt_local(_name, _span)
/// @desc    An Identifier that names a local.
/// @param   {String}           _name : The local
/// @param   {Struct.GMLC_Span} _span : The span
/// @returns {Struct.ASTIdentifier}
#endregion
function __gmlc_opt_local(_name, _span) {
	var _node = new ASTIdentifier(_span, _name);
	_node.symbol = new GMLC_Symbol("Local", _name, undefined);
	return _node;
}

#region jsDoc
/// @func    __gmlc_opt_var(_name, _init, _span)
/// @desc    `var _name = _init;` for a temporary.
/// @param   {String}           _name : The local
/// @param   {Struct.ASTNode}   _init : Its value
/// @param   {Struct.GMLC_Span} _span : The span
/// @returns {Struct.ASTVarDeclList}
#endregion
function __gmlc_opt_var(_name, _init, _span) {
	return new ASTVarDeclList(_span, [new ASTVarDecl(_span, __gmlc_opt_local(_name, _span), _init)]);
}

#region jsDoc
/// @func    __gmlc_opt_declares(_node)
/// @desc    Whether a node declares anything outside the function expressions in it: a `var`, a `static`, a
///          `globalvar`, an enum, a function or a caught value.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_declares(_node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_VarDeclList:
		case __GMLC_NodeKind_StaticDecl:
		case __GMLC_NodeKind_GlobalVarDecl:
		case __GMLC_NodeKind_EnumDecl:
		case __GMLC_NodeKind_FunctionDecl:
		case __GMLC_NodeKind_ConstructorDecl:
		return true;
		case __GMLC_NodeKind_FunctionExpr:
		return false;
		case __GMLC_NodeKind_Try:
		if (_node.catch_param != undefined) return true;
		break;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_opt_declares(_child)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_yyc_slow_operand(_op, _literal)
/// @desc    Whether YYC runs operator `_op` slower with the literal as an operand than with a local that holds it: a
///          real of `+ - * / div mod` (`_i + 1` is slower than `_i + _m` with `var _m = 1`), unless the literal is one
///          the simplifications remove (`x + 0`, `x - 0`, `x * 0`, `x * 1`, `x / 1`, `x div 1`).
/// @param   {String}            _op      : The operator
/// @param   {Struct.ASTLiteral} _literal : The literal
/// @returns {Bool}
#endregion
function __gmlc_opt_yyc_slow_operand(_op, _literal) {
	if (_literal.ty != "real") || (!is_numeric(_literal.value)) return false;
	var _v = _literal.value;
	if (is_infinity(_v)) || (is_nan(_v)) return false;
	switch (_op) {
		case "+": case "-": return (_v != 0);
		case "*": return (_v != 0) && (_v != 1);
		case "/": case "div": return (_v != 1);
		case "mod": return true;
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_yyc_slow_argument(_call, _arg, _literal, _known)
/// @desc    Whether YYC runs a built-in call slower with a number literal as argument `_arg` than with a local that
///          holds it: a finite real beside another argument that is neither a literal nor a name of `_known`
///          (`max(_t, 2)` is slower than `max(_t, _k)` with `var _k = 2`; a call of literals only is folded instead).
/// @param   {Struct.ASTNode} _call    : The call
/// @param   {Real}           _arg     : The argument's index
/// @param   {Struct.ASTNode} _literal : The literal
/// @param   {Struct}         _known   : Names whose value is a literal
/// @returns {Bool}
#endregion
function __gmlc_opt_yyc_slow_argument(_call, _arg, _literal, _known) {
	if (_call.kind != __GMLC_NodeKind_Call) || (__gmlc_opt_builtin_call(_call) == undefined) return false;
	if (_literal.ty != "real") || (!is_numeric(_literal.value)) return false;
	if (is_infinity(_literal.value)) || (is_nan(_literal.value)) return false;
	var _args = _call.args;
	var _k = 0; repeat (array_length(_args)) {
		if (_k != _arg) && (!__gmlc_opt_constant_tree(_args[_k], _known)) return true;
	_k++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_constant_tree(_node, _known)
/// @desc    Whether an expression is made only of literals and locals `_known` holds a value for, through unary, binary
///          and logical operators: it folds to a literal once they are put in, so the YYC operand rule does not keep a
///          local beside it.
/// @param   {Struct.ASTNode} _node  : The expression
/// @param   {Struct}         _known : Local name to its value (or true)
/// @returns {Bool}
#endregion
function __gmlc_opt_constant_tree(_node, _known) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal:    return true;
		case __GMLC_NodeKind_Identifier: return __gmlc_opt_is_local(_node) && (_known[$ _node.name] != undefined);
		case __GMLC_NodeKind_Unary:      return __gmlc_opt_constant_tree(_node.argument, _known);
		case __GMLC_NodeKind_Binary:
		case __GMLC_NodeKind_Logical:    return __gmlc_opt_constant_tree(_node.left, _known) && __gmlc_opt_constant_tree(_node.right, _known);
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_is_function(_node)
/// @desc    Whether a node is a function or constructor declaration or a function expression.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_is_function(_node) {
	var _kind = _node.kind;
	return (_kind == __GMLC_NodeKind_FunctionDecl) || (_kind == __GMLC_NodeKind_ConstructorDecl) || (_kind == __GMLC_NodeKind_FunctionExpr);
}

#region jsDoc
/// @func    __gmlc_opt_is_loop(_node)
/// @desc    Whether a node is a `for`, `while`, `repeat` or `do until` loop.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_is_loop(_node) {
	var _kind = _node.kind;
	return (_kind == __GMLC_NodeKind_For) || (_kind == __GMLC_NodeKind_While) || (_kind == __GMLC_NodeKind_Repeat) || (_kind == __GMLC_NodeKind_DoUntil);
}

#region jsDoc
/// @func    __gmlc_opt_same(_a, _b)
/// @desc    Whether two nodes are the same code, wherever they are written.
/// @param   {Struct.ASTNode} _a : A node
/// @param   {Struct.ASTNode} _b : Another node
/// @returns {Bool}
#endregion
function __gmlc_opt_same(_a, _b) {
	if (_a == undefined) || (_b == undefined) return (_a == _b);
	if (_a.kind != _b.kind) return false;
	var _fields = _a.fields;
	var _i = 0; repeat (array_length(_fields)) {
		var _x = _a[$ _fields[_i]];
		var _y = _b[$ _fields[_i]];
		if (is_array(_x)) {
			if (!is_array(_y)) || (array_length(_x) != array_length(_y)) return false;
			var _j = 0; repeat (array_length(_x)) {
				if (!__gmlc_opt_same_value(_x[_j], _y[_j])) return false;
			_j++}
		}
		else if (!__gmlc_opt_same_value(_x, _y)) {
			return false;
		}
	_i++}
	return true;
}

#region jsDoc
/// @func    __gmlc_opt_same_value(_x, _y)
/// @desc    Whether two field values of nodes are the same: nodes as code, symbols by kind, name and slot, other
///          values by type and value.
/// @param   {Any} _x : A value
/// @param   {Any} _y : Another value
/// @returns {Bool}
#endregion
function __gmlc_opt_same_value(_x, _y) {
	if (is_struct(_x)) {
		if (!is_struct(_y)) return false;
		if (struct_exists(_x, "kind")) && (is_real(_x.kind)) return __gmlc_opt_same(_x, _y);
		if (is_instanceof(_x, GMLC_Symbol)) return is_instanceof(_y, GMLC_Symbol) && (_x.kind == _y.kind) && (_x.name == _y.name) && (_x.slot == _y.slot);
		return (_x == _y);
	}
	if (typeof(_x) != typeof(_y)) return false;
	return (_x == _y);
}

#region jsDoc
/// @func    __gmlc_opt_shallow(_node)
/// @desc    A copy of a node whose fields hold the same values (child nodes, arrays and spans are shared), for a
///          pass that replaces some of its fields.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Struct.ASTNode}
#endregion
function __gmlc_opt_shallow(_node) {
	var _copy = {};
	var _names = struct_get_names(_node);
	var _i = 0; repeat (array_length(_names)) {
		_copy[$ _names[_i]] = _node[$ _names[_i]];
	_i++}
	static_set(_copy, static_get(_node));
	return _copy;
}

#region jsDoc
/// @func    __gmlc_opt_clone(_node)
/// @desc    A copy of a node and of every node under it, for a pass that writes the same code twice; spans and
///          origins are shared, symbols copied.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Struct.ASTNode}
#endregion
function __gmlc_opt_clone(_node) {
	var _copy = __gmlc_opt_shallow(_node);
	var _symbol = _node[$ "symbol"];
	if (_symbol != undefined) _copy.symbol = new GMLC_Symbol(_symbol.kind, _symbol.name, _symbol.slot);
	var _fields = _node.childFields;
	var _i = 0; repeat (array_length(_fields)) {
		var _value = _node[$ _fields[_i]];
		if (is_array(_value)) {
			var _n = array_length(_value);
			var _out = array_create(_n, undefined);
			var _j = 0; repeat (_n) {
				if (_value[_j] != undefined) _out[_j] = __gmlc_opt_clone(_value[_j]);
			_j++}
			_copy[$ _fields[_i]] = _out;
		}
		else if (_value != undefined) {
			_copy[$ _fields[_i]] = __gmlc_opt_clone(_value);
		}
	_i++}
	return _copy;
}

#region jsDoc
/// @func    __gmlc_opt_reads(_node, _name)
/// @desc    How many times a local is read under a node, nested functions left out (their names are their own).
/// @param   {Struct.ASTNode} _node : The node
/// @param   {String}         _name : The local
/// @returns {Real}
#endregion
function __gmlc_opt_reads(_node, _name) {
	if (_node.kind == __GMLC_NodeKind_Identifier) return (__gmlc_opt_is_local(_node) && (_node.name == _name)) ? 1 : 0;
	var _n = 0;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (!__gmlc_opt_is_function(_child)) _n += __gmlc_opt_reads(_child, _name);
			}
		_i++}
	_field_index++}
	// the target of a plain assignment is written, not read
	if (_node.kind == __GMLC_NodeKind_Assign) && (_node.op == "=") && __gmlc_opt_is_local(_node.target) && (_node.target.name == _name) _n--;
	if (_node.kind == __GMLC_NodeKind_VarDecl) && (_node.target.name == _name) _n--;
	return _n;
}

#region jsDoc
/// @func    __gmlc_opt_writes(_node, _name)
/// @desc    Whether a local is written under a node (assigned, declared with a value, incremented or decremented),
///          nested functions left out.
/// @param   {Struct.ASTNode} _node : The node
/// @param   {String}         _name : The local
/// @returns {Bool}
#endregion
function __gmlc_opt_writes(_node, _name) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Assign:  if (__gmlc_opt_is_local(_node.target) && (_node.target.name == _name)) return true; break;
		case __GMLC_NodeKind_Update:  if (__gmlc_opt_is_local(_node[$ "argument"]) && (_node[$ "argument"].name == _name)) return true; break;
		case __GMLC_NodeKind_VarDecl: if (_node.target.name == _name) && (_node.init != undefined) return true; break;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (!__gmlc_opt_is_function(_child)) && (__gmlc_opt_writes(_child, _name)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_may_throw(_node)
/// @desc    Whether evaluating an expression may throw, without type facts: only literals, locals, built-in
///          constants, enum and asset names, function literals and calls of built-ins the effect table lists as not
///          throwing, with arguments that cannot throw, never do.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_opt_may_throw(_node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal:
		case __GMLC_NodeKind_FunctionExpr:
		return false;
		case __GMLC_NodeKind_Identifier: {
			var _symbol = _node.symbol;
			if (_symbol == undefined) return true;
			switch (_symbol.kind) {
				case "Local": case "BuiltinConstant": case "Enum": case "Asset": case "Macro": case "BuiltinFunction":
				return false;
			}
			return true;
		}
		case __GMLC_NodeKind_Call: {
			var _name = __gmlc_opt_builtin_call(_node);
			if (_name == undefined) return true;
			var _effects = __GmlcDataEffects();
			var _entry = _effects[$ _name];
			if (_entry == undefined) || (_entry.may_throw) return true;
			var _i = 0; repeat (array_length(_node.args)) {
				if (_node.args[_i] == undefined) || (__gmlc_opt_may_throw(_node.args[_i])) return true;
			_i++}
			return !__gmlc_opt_args_accepted(_name, _node.args, __gmlc_opt_value_type);
		}
	}
	return true;
}

#region jsDoc
/// @func    __gmlc_opt_builtin_function(_name)
/// @desc    What the built-in data says of a built-in function: {parameters: [{name, type, optional}], returnType}, or
///          undefined for a name that is none.
/// @param   {String} _name : The function
/// @returns {Struct|Undefined}
#endregion
function __gmlc_opt_builtin_function(_name) {
	static __table = undefined;
	if (__table == undefined) {
		__table = {};
		var _functions = __GmlcDataSpec().functions;
		var _i = 0; repeat (array_length(_functions)) {
			var _entry = _functions[_i];
			var _params = [];
			var _j = 0; repeat (array_length(_entry.parameters)) {
				var _p = _entry.parameters[_j];
				array_push(_params, { name: _p.name, type: _p.type, optional: _p.optional });
			_j++}
			__table[$ _entry.name] = { parameters: _params, returnType: _entry.returnType };
		_i++}
	}
	return __table[$ _name];
}

#region jsDoc
/// @func    __gmlc_opt_args_accepted(_name, _args, _typeOf)
/// @desc    Whether a built-in's signature accepts the arguments of a call: each argument's type, as `_typeOf` knows
///          it, is one its parameter takes, and no required parameter is left out. The effect table's may-throw flag
///          holds only for such calls: `array_length(_v)` throws when `_v` is not an array.
/// @param   {String}                _name   : The built-in
/// @param   {Array<Struct.ASTNode>} _args   : The arguments
/// @param   {Function}              _typeOf : Gives the type of an argument (`__gmlc_opt_value_type` names), undefined
///                                            when not known
/// @returns {Bool}
#endregion
function __gmlc_opt_args_accepted(_name, _args, _typeOf) {
	var _signature = __gmlc_opt_builtin_function(_name);
	if (_signature == undefined) return false;
	var _params = _signature.parameters;
	var _count = array_length(_params);
	var _variadic = ((_count > 0) && (_params[_count - 1].name == "...")) ? _params[_count - 1] : undefined;
	var _i = 0; repeat (max(_count, array_length(_args))) {
		var _arg = (_i < array_length(_args)) ? _args[_i] : undefined;
		var _param = (_i < _count) ? _params[_i] : _variadic;
		if (_arg == undefined) {
			if (_param != undefined) && (!_param.optional) && (_param.name != "...") return false;
		}
		else if (_param == undefined) || (!__gmlc_opt_accepts(_param.type, _typeOf(_arg))) {
			return false;
		}
	_i++}
	return true;
}

#region jsDoc
/// @func    __gmlc_opt_takes_function(_name)
/// @desc    Whether a built-in has a parameter that takes a function, which it may call: `array_map_ext`.
/// @param   {String} _name : The built-in
/// @returns {Bool}
#endregion
function __gmlc_opt_takes_function(_name) {
	var _signature = __gmlc_opt_builtin_function(_name);
	if (_signature == undefined) return false;
	var _params = _signature.parameters;
	var _i = 0; repeat (array_length(_params)) {
		if (array_contains(string_split(_params[_i].type, ","), "Function")) return true;
	_i++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_value_type(_node)
/// @desc    The type of the value of an expression when it is known without running it: the type names of the
///          built-in data (`Real`, `String`, `Bool`, `Int64`, `Undefined`, `Array`, `Struct`, `Function`).
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {String|Undefined} undefined when the type is not known
#endregion
function __gmlc_opt_value_type(_node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal:
		switch (_node.ty) {
			case "real": case "inf": case "nan": return "Real";
			case "int64": return "Int64";
			case "bool": return "Bool";
			case "string": return "String";
			case "undefined": return "Undefined";
		}
		return undefined;
		case __GMLC_NodeKind_ArrayLiteral: return "Array";
		case __GMLC_NodeKind_StructLiteral: return "Struct";
		case __GMLC_NodeKind_FunctionExpr: return "Function";
		case __GMLC_NodeKind_TemplateString: return "String";
		case __GMLC_NodeKind_Identifier: {
			var _symbol = _node.symbol;
			if (_symbol == undefined) return undefined;
			switch (_symbol.kind) {
				case "Enum": return "Real";
				case "BuiltinFunction": return "Function";
				case "BuiltinConstant": return __gmlc_opt_builtin_constant_type(_node.name);
				case "Local": {
					var _held = __gmlc_opt_local_type(_node);
					return (_held == undefined) ? undefined : __gmlc_opt_coarse_type(_held);
				}
				case "Self": case "Static": {
					var _field = __gmlc_opt_field_type(_node);
					return (_field == undefined) ? undefined : __gmlc_opt_coarse_type(_field);
				}
			}
			return undefined;
		}
		case __GMLC_NodeKind_Index: {
			var _member = __gmlc_opt_element_type(_node) ?? __gmlc_opt_field_type(_node);
			return (_member == undefined) ? undefined : __gmlc_opt_coarse_type(_member);
		}
		case __GMLC_NodeKind_Call: {
			var _name = __gmlc_opt_builtin_call(_node);
			if (_name == undefined) return undefined;
			var _signature = __gmlc_opt_builtin_function(_name);
			if (_signature == undefined) return undefined;
			var _type = _signature.returnType;
			if (string_pos(",", _type) > 0) || (_type == "Any") || (_type == "ArgumentIdentity") return undefined;
			return _type;
		}
		// what an operation gives when it finishes: it is only reached when it did not throw
		case __GMLC_NodeKind_Binary: {
			var _l = __gmlc_opt_value_type(_node.left);
			if (_l == undefined) return undefined;
			var _r = __gmlc_opt_value_type(_node.right);
			if (_r == undefined) return undefined;
			switch (_node.op) {
				case "==": case "!=": case "<": case "<=": case ">": case ">=":
				return "Bool";
				case "+":
				if (_l == "String") && (_r == "String") return "String";
				return ((_l == "Real") && (_r == "Real")) ? "Real" : undefined;
				case "-": case "*": case "/": case "div": case "mod": case "&": case "|": case "^": case "<<": case ">>":
				return ((_l == "Real") && (_r == "Real")) ? "Real" : undefined;
			}
			return undefined;
		}
		case __GMLC_NodeKind_Unary: {
			if (_node.op == "!") return "Bool";
			if (_node.op == "-") || (_node.op == "~") return (__gmlc_opt_value_type(_node.argument) == "Real") ? "Real" : undefined;
			return undefined;
		}
		case __GMLC_NodeKind_Logical: return "Bool";
		// `a ?? b` is `a` where `a` is not undefined, else `b`
		case __GMLC_NodeKind_Nullish: {
			var _right = __gmlc_opt_value_type(_node.right);
			if (_right == undefined) return undefined;
			var _left = __gmlc_opt_value_type(_node.left);
			if (_left == "Undefined") return _right;
			if (_left == undefined) {
				var _held = __gmlc_opt_held_type(_node.left);
				if (_held == undefined) return undefined;
				var _defined = "Never";
				var _members = __gmlc_type_members(_held);
				var _m = 0; repeat (array_length(_members)) {
					if (_members[_m] != "Undefined") _defined = gmlc_type_join(_defined, _members[_m]);
				_m++}
				_left = __gmlc_opt_coarse_type(_defined);
				if (_left == undefined) return undefined;
			}
			return (_left == _right) ? _right : undefined;
		}
		case __GMLC_NodeKind_Conditional: {
			var _a = __gmlc_opt_value_type(_node.consequent);
			if (_a == undefined) return undefined;
			return (__gmlc_opt_value_type(_node.alternate) == _a) ? _a : undefined;
		}
	}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_opt_local_types_holder()
/// @desc    Holds the types of the locals of the file a pass runs on (__gmlc_opt_local_types), which
///          __gmlc_opt_value_type reads; the pass manager sets them before each pass.
/// @returns {Struct} {types}
#endregion
function __gmlc_opt_local_types_holder() {
	static __holder = { types: {}, fields: {}, structs_open: false };
	return __holder;
}

#region jsDoc
/// @func    __gmlc_opt_set_local_types(_types)
/// @desc    Sets the local types __gmlc_opt_value_type reads.
/// @param   {Struct} _types : A type name per local name
#endregion
function __gmlc_opt_set_local_types(_types) {
	__gmlc_opt_local_types_holder().types = _types;
}

#region jsDoc
/// @func    __gmlc_opt_forget_local_types(_names)
/// @desc    Leaves names out of the local types __gmlc_opt_value_type reads: a pass's new locals, whose name another
///          function's local may already have.
/// @param   {Array<String>} _names : The names
#endregion
function __gmlc_opt_forget_local_types(_names) {
	var _types = __gmlc_opt_local_types_holder().types;
	var _i = 0; repeat (array_length(_names)) {
		if (struct_exists(_types, _names[_i])) struct_remove(_types, _names[_i]);
		if (struct_exists(_types, "[]" + _names[_i])) struct_remove(_types, "[]" + _names[_i]);
		var _prefix = "[.]" + _names[_i] + "#";
		var _keys = struct_get_names(_types);
		var _k = 0; repeat (array_length(_keys)) {
			if (string_starts_with(_keys[_k], _prefix)) struct_remove(_types, _keys[_k]);
		_k++}
	_i++}
}

#region jsDoc
/// @func    __gmlc_opt_element_type(_node)
/// @desc    What an element read (`a[i]`) holds: the element type of the arrays a local name (`[]<name>`) or a field
///          name (`[f]<name>`) holds in a whole project, or undefined.
/// @param   {Struct.ASTNode} _node : The read
/// @returns {String|Undefined}
#endregion
function __gmlc_opt_element_type(_node) {
	if (_node.kind != __GMLC_NodeKind_Index) || ((_node.accessor != "Array") && (_node.accessor != "ArrayAt")) return undefined;
	var _holder = __gmlc_opt_local_types_holder();
	var _object = _node.object;
	var _key = undefined;
	if (_object.kind == __GMLC_NodeKind_Identifier) && (_object.symbol != undefined) {
		switch (_object.symbol.kind) {
			case "Local": _key = "[]" + _object.name; break;
			case "Static": _key = "[f]" + _object.name; break;
			// where parsed structs are made, `self` may be one
			case "Self": if (!_holder.structs_open) && (__gmlc_opt_builtin_variable(_object.name) == undefined) _key = "[f]" + _object.name; break;
		}
	}
	else if (_object.kind == __GMLC_NodeKind_Index) && (_object.accessor == "Dot") && (_object.member != undefined)
		&& ((!_holder.structs_open) || (__gmlc_opt_made_by_code(_object.object))) {
		_key = "[f]" + _object.member;
	}
	return (_key == undefined) ? undefined : _holder.types[$ _key];
}

#region jsDoc
/// @func    __gmlc_opt_local_types(_root, _sources, _batch)
/// @desc    The canonical type each local name of a file holds wherever it is read, from the flow facts of the
///          type engine joined over every function that has the name; a name that may hold more than one type, or
///          one the facts do not know, is left out.
/// @param   {Struct.ASTNode}          _root    : The file
/// @param   {Struct.GMLC_SourceTable} _sources : The compile's files, or undefined
/// @param   {Struct}                  _batch   : {returns, params, fields} of the batch (gmlc_type_batch)
/// @returns {Struct} A canonical type per local name
#endregion
function __gmlc_opt_local_types(_root, _sources, _batch) {
	var _held = gmlc_type_held(_root, _sources, _batch);
	var _elements = gmlc_type_held_elements(_root, _batch);
	var _types = {};
	var _names = struct_get_names(_held);
	var _i = 0; repeat (array_length(_names)) {
		var _type = _held[$ _names[_i]];
		if (__gmlc_opt_coarse_type(_type) != undefined) _types[$ _names[_i]] = _type;
	_i++}
	_names = struct_get_names(_elements);
	_i = 0; repeat (array_length(_names)) {
		var _element = _elements[$ _names[_i]];
		if (__gmlc_opt_coarse_type(_element) != undefined) _types[$ _names[_i]] = _element;
	_i++}
	return _types;
}

#region jsDoc
/// @func    __gmlc_opt_refresh_argument_facts(_ast)
/// @desc    Sets the facts of every function about `argument`, `argument_count`, `argument0` to `argument15` and
///          `other` from the tree as it is now. Lowering found them before any pass ran: once a pass removes the only
///          `argument[0]` of a function, the passes that read the facts (inlining, specialization) see that it takes
///          only its parameters.
/// @param   {Struct.ASTScript} _ast : The file
#endregion
function __gmlc_opt_refresh_argument_facts(_ast) {
	var _found = {};
	__gmlc_opt_argument_facts(_ast, 0, _found);
	var _i = 0; repeat (array_length(_ast.functions)) {
		var _info = _ast.functions[_i];
		if (_info != undefined) && (_info.facts != undefined) {
			var _a = _found[$ string(_info.fn_id)];
			_info.facts.uses_argument_array = (_a != undefined) && _a.array;
			_info.facts.uses_argument_count = (_a != undefined) && _a.count;
			_info.facts.max_argument_index = (_a != undefined) ? _a.max : -1;
			_info.facts.reads_other = (_a != undefined) && _a.other;
		}
	_i++}
}

#region jsDoc
/// @func    __gmlc_opt_argument_facts(_node, _fn_id, _found)
/// @desc    Adds what each function under a node reads of its arguments and of `other`, a nested function's reads to
///          its own facts.
/// @param   {Struct.ASTNode} _node  : The node
/// @param   {Real}           _fn_id : The function the node is in
/// @param   {Struct}         _found : Function id to {array, count, max, other}, added to
#endregion
function __gmlc_opt_argument_facts(_node, _fn_id, _found) {
	switch (_node.kind) {
		case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl: case __GMLC_NodeKind_FunctionExpr:
			if (_node.fn_id != undefined) _fn_id = _node.fn_id;
		break;
		case __GMLC_NodeKind_Identifier:
			if (_node.symbol != undefined) && (_node.symbol.kind == "BuiltinVar") {
				var _key = string(_fn_id);
				var _entry = _found[$ _key];
				if (_entry == undefined) {
					_entry = { array: false, count: false, max: -1, other: false };
					_found[$ _key] = _entry;
				}
				switch (_node.name) {
					case "argument":       _entry.array = true; break;
					case "argument_count": _entry.count = true; break;
					case "other":          _entry.other = true; break;
					default: _entry.max = max(_entry.max, __gmlc_argument_index(_node.name)); break;
				}
			}
		break;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_opt_argument_facts(_child, _fn_id, _found);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_number_level(_node)
/// @desc    1 when a local holds a number or a boolean wherever it is read, else 0: the level of the passes that
///          rank what an expression holds (2 a whole number that stays exact, 1 a number or boolean, 0 anything).
/// @param   {Struct.ASTNode} _node : The local
/// @returns {Real}
#endregion
function __gmlc_opt_number_level(_node) {
	var _type = __gmlc_opt_value_type(_node);
	return ((_type == "Real") || (_type == "Int64") || (_type == "Bool")) ? 1 : 0;
}

#region jsDoc
/// @func    __gmlc_opt_double_level(_node)
/// @desc    What a local or field read holds wherever it is read, from the type facts: 2 a double, 1 an int64 or a
///          bool, 0 anything else.
/// @param   {Struct.ASTNode} _node : The read
/// @returns {Real}
#endregion
function __gmlc_opt_double_level(_node) {
	var _type = __gmlc_opt_local_type(_node) ?? __gmlc_opt_field_type(_node);
	if (_type == undefined) return 0;
	if (_type == "Int") || (_type == "Double") || (_type == "Real") return 2;
	if (_type == "Int64") || (_type == "Bool") || (string_starts_with(_type, "Enum.")) return 1;
	return 0;
}

#region jsDoc
/// @func    __gmlc_opt_set_field_types(_types, _structs_open)
/// @desc    Sets the field types __gmlc_opt_field_type reads, and whether structs with any fields are made.
/// @param   {Struct} _types        : A canonical type per field name
/// @param   {Bool}   _structs_open : Structs with any fields are made (`json_parse`): a field read has its type only
///                                   on an owner made by code
#endregion
function __gmlc_opt_set_field_types(_types, _structs_open) {
	var _holder = __gmlc_opt_local_types_holder();
	_holder.fields = _types;
	_holder.structs_open = _structs_open;
}

#region jsDoc
/// @func    __gmlc_opt_made_by_code(_node)
/// @desc    Whether a value is surely an instance or a struct a constructor made, never a parsed struct: an object's
///          name, or a local that holds a `Struct.<constructor>`.
/// @param   {Struct.ASTNode} _node : The value
/// @returns {Bool}
#endregion
function __gmlc_opt_made_by_code(_node) {
	if (_node.kind == __GMLC_NodeKind_Identifier) && (_node.symbol != undefined) && (_node.symbol.kind == "Asset") return true;
	var _type = __gmlc_opt_local_type(_node);
	if (_type == undefined) || (!string_starts_with(_type, "Struct.")) return false;
	var _name = string_delete(_type, 1, 7);
	return (!__gmlc_type_builtin_struct_type(_name)) && (!__gmlc_opt_builtin_structure(_name));
}

#region jsDoc
/// @func    __gmlc_opt_field_type(_node)
/// @desc    The canonical type a field read holds in a whole project (an instance variable, a static, `x.name`,
///          `x[$ "name"]`), when it is one known type; undefined otherwise.
/// @param   {Struct.ASTNode} _node : The read
/// @returns {String|Undefined}
#endregion
function __gmlc_opt_field_type(_node) {
	var _holder = __gmlc_opt_local_types_holder();
	// a field of the structs a local holds, by the local's group
	if (_node.kind == __GMLC_NodeKind_Index) && (_node.accessor == "Dot") && (_node.member != undefined) && (__gmlc_opt_is_local(_node.object)) {
		var _grouped = _holder.types[$ "[.]" + _node.object.name + "#" + _node.member];
		if (_grouped != undefined) return _grouped;
	}
	var _name = undefined;
	var _class = "";
	if (_node.kind == __GMLC_NodeKind_Identifier) {
		if (_node.symbol == undefined) || ((_node.symbol.kind != "Self") && (_node.symbol.kind != "Static")) return undefined;
		if (__gmlc_opt_builtin_variable(_node.name) != undefined) return undefined;
		// an instance variable or a static, by what the type engine reads it as in this file
		var _read = _holder.types[$ "[s]" + _node.name];
		if (_read != undefined) return _read;
		// where parsed structs are made, `self` may be one; a static is the function's own
		if (_node.symbol.kind == "Self") && (_holder.structs_open) return undefined;
		_name = _node.name;
	}
	else if (_node.kind == __GMLC_NodeKind_Index) {
		if (_node.accessor == "Dot") && ((!_holder.structs_open) || (__gmlc_opt_made_by_code(_node.object))) {
			_name = _node.member;
			_class = __gmlc_opt_owner_class(_node.object);
		}
		// `s[$ "name"]` gives undefined where the struct has no such field
		else if (_node.accessor == "Struct") return undefined;
	}
	if (_name == undefined) return undefined;
	var _type = _holder.fields[$ _name];
	if (_type == undefined) return undefined;
	// what is written by the name, and what the writes by a computed name write to the owner's class
	var _names = struct_get_names(_holder.fields);
	var _i = 0; repeat (array_length(_names)) {
		if (string_char_at(_names[_i], 1) == "*") {
			var _key = string_delete(_names[_i], 1, 1);
			if (_class == "") || (_key == "") || (_key == _class) _type = gmlc_type_join(_type, _holder.fields[$ _names[_i]]);
		}
	_i++}
	return (__gmlc_opt_coarse_type(_type) != undefined) ? _type : undefined;
}

#region jsDoc
/// @func    __gmlc_opt_held_type(_node)
/// @desc    What a read of a ds container holds in a whole project, undefined included (a key or cell that is not
///          there): `m[? "key"]` and `ds_map_find_value(m, "key")` by key, else what the container a local holds
///          holds by its group (`[]<name>`), else a list or grid cell and the reads of stacks, queues and priority
///          queues by kind; undefined for any other expression.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {String|Undefined}
#endregion
function __gmlc_opt_held_type(_node) {
	var _container = undefined;
	if (_node.kind == __GMLC_NodeKind_Index) _container = _node.object;
	else if (_node.kind == __GMLC_NodeKind_Call) && (array_length(_node.args) > 0) _container = _node.args[0];
	var _grouped = undefined;
	if (_container != undefined) && (__gmlc_opt_is_local(_container)) {
		_grouped = __gmlc_opt_local_types_holder().types[$ "[]" + _container.name];
		if (_grouped == "Unknown") _grouped = undefined;
	}
	var _name = undefined;
	if (_node.kind == __GMLC_NodeKind_Index) {
		switch (_node.accessor) {
			case "Map": _name = __gmlc_type_map_key((array_length(_node.keys) > 0) ? _node.keys[0] : undefined); break;
			case "List": _name = "|list"; break;
			case "Grid": _name = "|grid"; break;
		}
	}
	else if (_node.kind == __GMLC_NodeKind_Call) {
		var _builtin = __gmlc_opt_builtin_call(_node);
		if (_builtin == "ds_map_find_value") {
			if (array_length(_node.args) == 2) _name = __gmlc_type_map_key(_node.args[1]);
		}
		else if (_builtin != undefined) _name = __gmlc_type_ds_reader(_builtin);
	}
	if (_name == undefined) return undefined;
	var _fields = __gmlc_opt_local_types_holder().fields;
	var _keyed = ((string_char_at(_name, 1) == "?") && (_name != "?")) ? _fields[$ _name] : undefined;
	var _kind = (string_char_at(_name, 1) == "|") ? _fields[$ _name] : undefined;
	var _type = _keyed ?? _grouped ?? _kind;
	return (_type == undefined) ? undefined : gmlc_type_join(_type, "Undefined");
}

#region jsDoc
/// @func    __gmlc_opt_owner_class(_owner)
/// @desc    Which structs or instances a field read may reach (__gmlc_type_owner_class): `inst` an object's instance,
///          `lit` a struct a literal made, `C:<name>` a constructor's struct, an empty name any.
/// @param   {Struct.ASTNode} _owner : The owner
/// @returns {String}
#endregion
function __gmlc_opt_owner_class(_owner) {
	if (_owner.kind == __GMLC_NodeKind_Identifier) && (_owner.symbol != undefined) && (_owner.symbol.kind == "Asset") return "inst";
	var _type = __gmlc_opt_local_type(_owner);
	if (_type == undefined) return "";
	if (_type == "Struct") return "lit";
	if (!string_starts_with(_type, "Struct.")) return "";
	var _name = string_delete(_type, 1, 7);
	return ((!__gmlc_type_builtin_struct_type(_name)) && (!__gmlc_opt_builtin_structure(_name))) ? "C:" + _name : "";
}

#region jsDoc
/// @func    __gmlc_opt_local_type(_node)
/// @desc    The canonical type a local holds wherever it is read (Int, Double, Int64, String, ...), or undefined
///          when the node is no local or its type is not one known type.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {String|Undefined}
#endregion
function __gmlc_opt_local_type(_node) {
	if (!__gmlc_opt_is_local(_node)) return undefined;
	return __gmlc_opt_local_types_holder().types[$ _node.name];
}

#region jsDoc
/// @func    __gmlc_opt_coarse_type(_type)
/// @desc    The type name of __gmlc_opt_value_type for a canonical type of one member, else undefined.
/// @param   {String} _type : A canonical type
/// @returns {String|Undefined}
#endregion
function __gmlc_opt_coarse_type(_type) {
	if (array_length(__gmlc_type_members(_type)) != 1) return undefined;
	switch (_type) {
		case "Int": case "Double": case "Real": return "Real";
		case "Int64": return "Int64";
		case "Bool": return "Bool";
		case "String": return "String";
		case "Undefined": return "Undefined";
	}
	if (string_starts_with(_type, "Enum.")) return "Int64";
	if (string_starts_with(_type, "Constant.")) return "Real";
	if (_type == "Struct") || (string_starts_with(_type, "Struct.")) return "Struct";
	if (string_starts_with(_type, "Array<")) return "Array";
	if (string_starts_with(_type, "Function")) return "Function";
	return undefined;
}

#region jsDoc
/// @func    __gmlc_opt_builtin_constant_type(_name)
/// @desc    The type the built-in data gives a built-in constant, or undefined for a name that is none.
/// @param   {String} _name : The constant
/// @returns {String|Undefined}
#endregion
function __gmlc_opt_builtin_constant_type(_name) {
	static __table = undefined;
	if (__table == undefined) {
		__table = {};
		var _constants = __GmlcDataSpec().constants;
		var _i = 0; repeat (array_length(_constants)) {
			__table[$ _constants[_i].name] = _constants[_i].type;
		_i++}
	}
	return __table[$ _name];
}

#region jsDoc
/// @func    __gmlc_opt_accepts(_param, _type)
/// @desc    Whether a parameter type of the built-in data accepts a value of a known type: `Real` and the
///          `Constant.*` kinds take reals, bools and int64s; `Any` takes everything, an unknown type nothing else.
/// @param   {String}           _param : The parameter type, alternatives separated by commas
/// @param   {String|Undefined} _type  : The value type, undefined when not known
/// @returns {Bool}
#endregion
function __gmlc_opt_accepts(_param, _type) {
	var _alternatives = string_split(_param, ",");
	var _i = 0; repeat (array_length(_alternatives)) {
		var _alt = _alternatives[_i];
		if (_alt == "Any") || (_alt == "ArgumentIdentity") return true;
		if (_type != undefined) {
			if (_alt == _type) return true;
			if ((_alt == "Real") || (string_starts_with(_alt, "Constant."))) && ((_type == "Real") || (_type == "Bool") || (_type == "Int64")) return true;
			if (_alt == "Bool") && ((_type == "Real") || (_type == "Int64")) return true;
			if (string_starts_with(_alt, "Array")) && (_type == "Array") return true;
		}
	_i++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_has_effects(_node)
/// @desc    Whether evaluating an expression may change anything a program can see: an assignment, an increment, a
///          `new`, a method call, or a call of anything but a pure or observer built-in. A throw is not counted
///          here (see __gmlc_opt_may_throw); function literals are left out.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_opt_has_effects(_node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Assign:
		case __GMLC_NodeKind_Update:
		case __GMLC_NodeKind_New:
		case __GMLC_NodeKind_MethodCall:
		return true;
		case __GMLC_NodeKind_FunctionExpr:
		return false;
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
				if (__gmlc_opt_has_effects(_child)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_is_trivial(_node)
/// @desc    Whether an expression is trivial: a literal, a local, or a call of a pure built-in that cannot throw
///          on trivial arguments.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_opt_is_trivial(_node) {
	if (_node.kind == __GMLC_NodeKind_Literal) || (__gmlc_opt_is_local(_node)) return true;
	var _name = __gmlc_opt_builtin_call(_node);
	if (_name == undefined) || (__gmlc_opt_call_class(_name) != "pure") || (__gmlc_opt_may_throw(_node)) return false;
	var _i = 0; repeat (array_length(_node.args)) {
		if (!__gmlc_opt_is_trivial(_node.args[_i])) return false;
	_i++}
	return true;
}

#region jsDoc
/// @func    __gmlc_opt_builtin_variable(_name)
/// @desc    What the built-in data says of a built-in variable: {type, instance}, or undefined for a name that is
///          none.
/// @param   {String} _name : The variable
/// @returns {Struct|Undefined}
#endregion
function __gmlc_opt_builtin_variable(_name) {
	static __table = undefined;
	if (__table == undefined) {
		__table = {};
		var _variables = __GmlcDataSpec().variables;
		var _i = 0; repeat (array_length(_variables)) {
			var _entry = _variables[_i];
			__table[$ _entry.name] = { type: _entry.type, instance: _entry.instance, set: _entry[$ "set"] ?? true };
		_i++}
	}
	return __table[$ _name];
}

#region jsDoc
/// @func    __gmlc_opt_self_is_instance(_cx, _node)
/// @desc    Whether `self` is an instance wherever a node of the pass's function runs: only the code of an object
///          event is sure of it. A function, even one written in an event, can run with a struct as `self`, where
///          reading a built-in instance variable such as `x` that was never set throws.
/// @param   {Struct}         _cx   : The pass context
/// @param   {Struct.ASTNode} _node : A node of the function
/// @returns {Bool}
#endregion
function __gmlc_opt_self_is_instance(_cx, _node) {
	if (_cx.unit.fn_id != 0) || (_cx.sources == undefined) || (_node.span == undefined) return false;
	var _files = _cx.sources.files;
	if (_node.span.file >= array_length(_files)) || (_files[_node.span.file] == undefined) return false;
	return __gmlc_opt_is_event_file(_files[_node.span.file].name);
}

#region jsDoc
/// @func    __gmlc_opt_is_event_file(_name)
/// @desc    Whether a file is an object's event: its path ends in `objects/<object>/<event>.gml`.
/// @param   {String} _name : The file's name
/// @returns {Bool}
#endregion
function __gmlc_opt_is_event_file(_name) {
	var _parts = string_split(string_replace_all(_name, "\\", "/"), "/");
	var _n = array_length(_parts);
	return (_n >= 3) && (_parts[_n - 3] == "objects");
}

#region jsDoc
/// @func    __gmlc_opt_builtin_structure(_name)
/// @desc    Whether the built-in data lists the fields of a built-in struct type (`SpriteInfo` is not listed,
///          `FontInfo` is).
/// @param   {String} _name : The struct type
/// @returns {Bool}
#endregion
function __gmlc_opt_builtin_structure(_name) {
	var _structures = __GmlcDataSpec().structures;
	var _i = 0; repeat (array_length(_structures)) {
		if (_structures[_i].name == _name) return true;
	_i++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_builtin_struct_field(_name)
/// @desc    Whether a name is a field of a built-in struct type the built-in data lists.
/// @param   {String} _name : The name
/// @returns {Bool}
#endregion
function __gmlc_opt_builtin_struct_field(_name) {
	static __fields = undefined;
	if (__fields == undefined) {
		__fields = {};
		var _structures = __GmlcDataSpec().structures;
		var _i = 0; repeat (array_length(_structures)) {
			var _list = _structures[_i].fields;
			var _f = 0; repeat (array_length(_list)) {
				__fields[$ _list[_f].name] = true;
			_f++}
		_i++}
	}
	return struct_exists(__fields, _name);
}

#region jsDoc
/// @func    __gmlc_opt_reads_instance_builtin(_cx, _node)
/// @desc    Whether a node reads a built-in instance variable of `self` (`x`, `image_angle`) where `self` is sure to
///          be an instance, so the read cannot throw.
/// @param   {Struct}         _cx   : The pass context
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_reads_instance_builtin(_cx, _node) {
	if (_node.kind != __GMLC_NodeKind_Identifier) || (_node.symbol == undefined) || (_node.symbol.kind != "Self") return false;
	var _entry = __gmlc_opt_builtin_variable(_node.name);
	return (_entry != undefined) && (_entry.instance) && (__gmlc_opt_self_is_instance(_cx, _node));
}
#endregion

#region YYC int64 positions
#region jsDoc
/// @func    __gmlc_opt_static_int64(_node)
/// @desc    Whether an expression is an int64 the YYC compiler knows while compiling: an int64 literal, `int64(...)`,
///          a bitwise operator, or `+ - * div mod` with such an operand.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_opt_static_int64(_node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal: return (_node.ty == "int64");
		case __GMLC_NodeKind_Call:    return (__gmlc_opt_builtin_call(_node) == "int64");
		case __GMLC_NodeKind_Unary:   return (_node.op == "~");
		case __GMLC_NodeKind_Binary: {
			switch (_node.op) {
				case "&": case "|": case "^": case "<<": case ">>":
				return true;
				case "+": case "-": case "*": case "div": case "mod": case "%":
				return __gmlc_opt_static_int64(_node.left) || __gmlc_opt_static_int64(_node.right);
			}
		break;}
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_has_static_int64(_node)
/// @desc    Whether any expression under a node is an int64 the YYC compiler knows while compiling.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_has_static_int64(_node) {
	if (__gmlc_opt_static_int64(_node)) return true;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_opt_has_static_int64(_child)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_int64_positions(_root)
/// @desc    Counts the locals next to an int64 (either operand of `mod`, the right operand of `+ - *` and of
///          `+= -= *=`) that no assignment sets to an int64: the VM gives a real for `_wide + _one` where `_wide + 1`
///          stays an int64. A pass that changes the count changes a result's type.
/// @param   {Struct.ASTNode} _root : The function
/// @returns {Struct} {beside}
#endregion
function __gmlc_opt_int64_positions(_root) {
	var _defs = {};
	__gmlc_opt_int64_defs(_root, _defs);
	var _out = { beside: 0 };
	__gmlc_opt_int64_count(_root, _defs, _out);
	return _out;
}

#region jsDoc
/// @func    __gmlc_opt_int64_defs(_node, _defs)
/// @desc    Collects the locals an assignment or a declaration sets to a known int64.
/// @param   {Struct.ASTNode} _node : The node
/// @param   {Struct}         _defs : Name to true
#endregion
function __gmlc_opt_int64_defs(_node, _defs) {
	if (_node.kind == __GMLC_NodeKind_VarDecl) && (_node.init != undefined) && (__gmlc_opt_static_int64(_node.init)) {
		_defs[$ _node.target.name] = true;
	}
	else if (_node.kind == __GMLC_NodeKind_Assign) && (_node.op == "=") && (__gmlc_opt_is_local(_node.target)) && (__gmlc_opt_static_int64(_node.value)) {
		_defs[$ _node.target.name] = true;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_opt_int64_defs(_child, _defs);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_int64_count(_node, _defs, _out)
/// @desc    Adds the int64-sensitive operands under a node to _out.
/// @param   {Struct.ASTNode} _node : The node
/// @param   {Struct}         _defs : The locals set to a known int64
/// @param   {Struct}         _out  : {beside}
#endregion
function __gmlc_opt_int64_count(_node, _defs, _out) {
	if (_node.kind == __GMLC_NodeKind_Binary) {
		switch (_node.op) {
			case "mod": case "%":
				__gmlc_opt_int64_operand(_node.left, _node.right, _defs, _out);
				__gmlc_opt_int64_operand(_node.right, _node.left, _defs, _out);
			break;
			case "+": case "-": case "*":
				__gmlc_opt_int64_operand(_node.right, _node.left, _defs, _out);
			break;
		}
	}
	else if (_node.kind == __GMLC_NodeKind_Assign) && ((_node.op == "+=") || (_node.op == "-=") || (_node.op == "*=")) {
		__gmlc_opt_int64_operand(_node.value, _node.target, _defs, _out);
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_opt_int64_count(_child, _defs, _out);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_int64_beside(_parent, _key)
/// @desc    Whether a node's child is an operand where the VM gives a real for a local next to an int64 but an int64 for
///          a literal (either operand of `mod`, the right operand of `+ - *` and of `+= -= *=`), with an int64 or a
///          local, which may hold one, as the other operand.
/// @param   {Struct.ASTNode} _parent : The node
/// @param   {String}         _key    : The child's field
/// @returns {Bool}
#endregion
function __gmlc_opt_int64_beside(_parent, _key) {
	var _other = undefined;
	if (_parent.kind == __GMLC_NodeKind_Binary) {
		switch (_parent.op) {
			case "mod": case "%":
				_other = (_key == "left") ? _parent.right : _parent.left;
			break;
			case "+": case "-": case "*":
				if (_key == "right") _other = _parent.left;
			break;
		}
	}
	else if (_parent.kind == __GMLC_NodeKind_Assign) && ((_parent.op == "+=") || (_parent.op == "-=") || (_parent.op == "*=")) && (_key == "value") {
		_other = _parent.target;
	}
	if (_other == undefined) return false;
	return __gmlc_opt_static_int64(_other) || __gmlc_opt_is_local(_other);
}

#region jsDoc
/// @func    __gmlc_opt_int64_operand(_node, _other, _defs, _out)
/// @desc    Counts one int64-sensitive operand: a local, not set to an int64, whose other operand is an int64.
/// @param   {Struct.ASTNode} _node  : The operand
/// @param   {Struct.ASTNode} _other : The other operand
/// @param   {Struct}         _defs  : The locals set to a known int64
/// @param   {Struct}         _out   : {beside}
#endregion
function __gmlc_opt_int64_operand(_node, _other, _defs, _out) {
	if (__gmlc_opt_is_local(_node)) && (!struct_exists(_defs, _node.name))
	&& ((__gmlc_opt_static_int64(_other)) || ((__gmlc_opt_is_local(_other)) && (struct_exists(_defs, _other.name)))) {
		_out.beside++;
	}
}
#endregion

#region Local kinds
#region jsDoc
/// @func    __gmlc_opt_writes_record(_writes, _name)
/// @desc    The record of the writes to a local, made when it is not there yet.
/// @param   {Struct} _writes : Local name to {values, bad}
/// @param   {String} _name   : The local
/// @returns {Struct}
#endregion
function __gmlc_opt_writes_record(_writes, _name) {
	var _entry = _writes[$ _name];
	if (_entry == undefined) {
		_entry = { values: [], bad: false };
		_writes[$ _name] = _entry;
	}
	return _entry;
}

#region jsDoc
/// @func    __gmlc_opt_collect_writes(_node, _writes, _isRoot)
/// @desc    Records the values written to each local under a node, nested functions left out.
/// @param   {Struct.ASTNode} _node    : The node
/// @param   {Struct}         _writes  : Local name to {values, bad}
/// @param   {Bool}           _isRoot  : Whether the node is the function itself
#endregion
function __gmlc_opt_collect_writes(_node, _writes, _isRoot) {
	if (!_isRoot) && (__gmlc_opt_is_function(_node)) return;
	switch (_node.kind) {
		case __GMLC_NodeKind_VarDecl: {
			var _declared = __gmlc_opt_writes_record(_writes, _node.target.name);
			if (_node.init != undefined) array_push(_declared.values, { op: "=", value: _node.init });
		break;}
		case __GMLC_NodeKind_Assign: {
			if (__gmlc_opt_is_local(_node.target)) {
				var _assigned = __gmlc_opt_writes_record(_writes, _node.target.name);
				if (_node.op == "??=") {
					_assigned.bad = true;
				}
				else {
					array_push(_assigned.values, { op: _node.op, value: _node.value });
				}
			}
		break;}
		case __GMLC_NodeKind_Try: {
			if (_node.catch_param != undefined) {
				var _caught = __gmlc_opt_writes_record(_writes, _node.catch_param.name);
				_caught.bad = true;
			}
		break;}
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_opt_collect_writes(_child, _writes, false);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_constant_level(_node, _cx)
/// @desc    What an expression known while compiling is: 1 a number or boolean, 0 any other value, -1 an
///          expression that is not known while compiling. A built-in constant counts for what the environment
///          gives it.
/// @param   {Struct.ASTNode} _node : The expression
/// @param   {Struct}         _cx   : The pass context
/// @returns {Real}
#endregion
function __gmlc_opt_constant_level(_node, _cx) {
	if (_node.kind == __GMLC_NodeKind_Literal) return ((_node.ty == "real") || (_node.ty == "int64") || (_node.ty == "bool")) ? 1 : 0;
	var _known = _cx.optimizer.__constantValue(_node);
	if (!_known[0]) return -1;
	return (is_bool(_known[1]) || is_real(_known[1])) ? 1 : 0;
}

#region jsDoc
/// @func    __gmlc_opt_whole_text(_text)
/// @desc    Whether a number is written as plain digits of at most 15, so it is a whole number that stays exact.
/// @param   {String} _text : The number as written
/// @returns {Bool}
#endregion
function __gmlc_opt_whole_text(_text) {
	return (string_length(_text) > 0) && (string_length(_text) <= 15) && (string_digits(_text) == _text);
}

#region jsDoc
/// @func    __gmlc_opt_level_of(_node, _kinds, _cx)
/// @desc    What an expression holds when it finishes: 2 a whole number, 1 a number or boolean, 0 anything.
/// @param   {Struct.ASTNode} _node  : The expression
/// @param   {Struct}         _kinds : Local name to 0, 1 or 2
/// @param   {Struct}         _cx    : The pass context
/// @returns {Real}
#endregion
function __gmlc_opt_level_of(_node, _kinds, _cx) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal: {
			if (_node.ty == "real") return __gmlc_opt_whole_text(_node.lexeme) ? 2 : 1;
			return ((_node.ty == "int64") || (_node.ty == "bool")) ? 1 : 0;
		}
		case __GMLC_NodeKind_Identifier: return __gmlc_opt_is_local(_node) ? max(_kinds[$ _node.name] ?? 0, __gmlc_opt_number_level(_node)) : max(0, __gmlc_opt_constant_level(_node, _cx));
		case __GMLC_NodeKind_Unary: {
			if (_node.op == "-") || (_node.op == "+") return __gmlc_opt_level_of(_node[$ "argument"], _kinds, _cx);
			return ((_node.op == "!") || (_node.op == "~")) ? 1 : 0;
		}
		case __GMLC_NodeKind_Binary: {
			var _l = __gmlc_opt_level_of(_node.left, _kinds, _cx);
			var _r = __gmlc_opt_level_of(_node.right, _kinds, _cx);
			switch (_node.op) {
				case "+": case "-": case "*": case "div": case "mod": return min(_l, _r);
				case "==": case "!=": case "<": case "<=": case ">": case ">=": return 1;
			}
			return (min(_l, _r) >= 1) ? 1 : 0;
		}
		case __GMLC_NodeKind_Logical: return 1;
		case __GMLC_NodeKind_Conditional: return min(__gmlc_opt_level_of(_node.consequent, _kinds, _cx), __gmlc_opt_level_of(_node.alternate, _kinds, _cx));
		case __GMLC_NodeKind_Call: {
			var _name = __gmlc_opt_builtin_call(_node);
			switch (_name) {
				case "array_length": case "string_length": case "floor": case "ceil": case "round": case "sign":
				case "instance_number": case "irandom": case "irandom_range":
				return 2;
				case "abs": case "min": case "max": {
					var _lowest = (array_length(_node.args) > 0) ? 2 : 0;
					var _a = 0; repeat (array_length(_node.args)) {
						_lowest = min(_lowest, __gmlc_opt_level_of(_node.args[_a], _kinds, _cx));
					_a++}
					return _lowest;
				}
			}
			return 0;
		}
	}
	return 0;
}

#region jsDoc
/// @func    __gmlc_opt_local_kinds(_root, _cx)
/// @desc    What each local of a function holds, from every write to it: 2 when only whole numbers, 1 when only
///          numbers and booleans, 0 otherwise. Parameters and catch variables are 0.
/// @param   {Struct.ASTNode} _root : The function, or the Script
/// @param   {Struct}         _cx   : The pass context
/// @returns {Struct} Local name to 0, 1 or 2
#endregion
function __gmlc_opt_local_kinds(_root, _cx) {
	var _writes = {};
	var _params = _root[$ "params"];
	if (_params != undefined) {
		var _p = 0; repeat (array_length(_params)) {
			var _flagged = __gmlc_opt_writes_record(_writes, _params[_p].target.name);
			_flagged.bad = true;
		_p++}
	}
	__gmlc_opt_collect_writes(_root, _writes, true);
	var _names = struct_get_names(_writes);
	var _kinds = {};
	var _n = 0; repeat (array_length(_names)) {
		_kinds[$ _names[_n]] = _writes[$ _names[_n]].bad ? 0 : 2;
	_n++}
	var _changed = true;
	while (_changed) {
		_changed = false;
		var _m = 0; repeat (array_length(_names)) {
			var _entry = _writes[$ _names[_m]];
			var _level = _kinds[$ _names[_m]];
			var _v = 0; repeat (array_length(_entry.values)) {
				var _write = _entry.values[_v];
				var _l = __gmlc_opt_level_of(_write.value, _kinds, _cx);
				if (_write.op == "/=") || (_write.op == "&=") || (_write.op == "|=") || (_write.op == "^=") _l = min(_l, 1);
				_level = min(_level, _l);
			_v++}
			if (_level != _kinds[$ _names[_m]]) {
				_kinds[$ _names[_m]] = _level;
				_changed = true;
			}
		_m++}
	}
	return _kinds;
}
#endregion

#region Loop helpers
#region jsDoc
/// @func    __gmlc_opt_reinits(_for, _name)
/// @desc    Whether a `for` loop starts by giving a local a value that does not read it.
/// @param   {Struct.ASTNode} _for  : The loop
/// @param   {String}         _name : The local
/// @returns {Bool}
#endregion
function __gmlc_opt_reinits(_for, _name) {
	var _init = _for.init;
	if (_init == undefined) return false;
	if (_init.kind == __GMLC_NodeKind_VarDeclList) {
		var _d = 0; repeat (array_length(_init.declarations)) {
			var _decl = _init.declarations[_d];
			if (_decl.target.name == _name) && (_decl.init != undefined) && (__gmlc_opt_count_mentions(_decl.init, _name) == 0) return true;
		_d++}
		return false;
	}
	if (_init.kind == __GMLC_NodeKind_ExprStmt) && (_init.expression.kind == __GMLC_NodeKind_Assign) {
		var _assign = _init.expression;
		return (_assign.op == "=") && (__gmlc_opt_is_local(_assign.target)) && (_assign.target.name == _name) && (__gmlc_opt_count_mentions(_assign.value, _name) == 0);
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_live_refs(_node, _name)
/// @desc    How many times a local is named under a node outside the `for` loops that give it a new value first,
///          nested functions left out. A local no such mention follows has a value nothing reads.
/// @param   {Struct.ASTNode} _node : The node
/// @param   {String}         _name : The local
/// @returns {Real}
#endregion
function __gmlc_opt_live_refs(_node, _name) {
	if (_node.kind == __GMLC_NodeKind_For) && (__gmlc_opt_reinits(_node, _name)) return 0;
	if (_node.kind == __GMLC_NodeKind_Identifier) return (__gmlc_opt_is_local(_node) && (_node.name == _name)) ? 1 : 0;
	var _n = 0;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (!__gmlc_opt_is_function(_child)) _n += __gmlc_opt_live_refs(_child, _name);
			}
		_i++}
	_field_index++}
	return _n;
}

#region jsDoc
/// @func    __gmlc_opt_has_function(_node)
/// @desc    Whether a function is written anywhere under a node.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_has_function(_node) {
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_opt_is_function(_child)) || (__gmlc_opt_has_function(_child)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_has_try(_node, _isRoot)
/// @desc    Whether a `try` is written anywhere in a function, nested functions left out.
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {Bool}           _isRoot : Whether the node is the function itself
/// @returns {Bool}
#endregion
function __gmlc_opt_has_try(_node, _isRoot) {
	if (!_isRoot) && (__gmlc_opt_is_function(_node)) return false;
	if (_node.kind == __GMLC_NodeKind_Try) return true;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_opt_has_try(_child, false)) return true;
			}
		_i++}
	_field_index++}
	return false;
}
#endregion

#region Asset references
#region jsDoc
/// @func    __gmlc_opt_has_asset_symbol(_node)
/// @desc    Whether an asset is named anywhere under a node.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_has_asset_symbol(_node) {
	if (_node.kind == __GMLC_NodeKind_Identifier) return (_node.symbol != undefined) && (_node.symbol.kind == "Asset");
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_opt_has_asset_symbol(_child)) return true;
			}
		_i++}
	_field_index++}
	return false;
}
#endregion

#region Candidate locals
#region jsDoc
/// @func    __gmlc_opt_candidate_scan(_owner, _cx, _names, _constants)
/// @desc    Finds the locals a unit declares at its top level with a value of a kind a pass cares about (a function
///          literal, the name of a function the file declares, a struct literal) and records every use of each: its
///          kind (call, execute, write, member, store or read) and, for a call, what its arguments are. A use before
///          the declaration marks the local early; a second declaration marks it dup.
/// @param   {Struct.ASTNode} _owner : The Script or a function node
/// @param   {Struct}         _cx    : The pass context
/// @param   {Struct}         _names : The functions of the file (see __functionNames)
/// @param   {Bool}           _constants : Whether a compile-time constant argument counts as a constant
/// @returns {Struct} {candidates, order, declared, stmt_call, cx, names, constants}
#endregion
function __gmlc_opt_candidate_scan(_owner, _cx, _names, _constants) {
	var _state = { candidates: {}, order: [], declared: {}, stmt_call: undefined, cx: _cx, names: _names, constants: _constants };
	var _list = __gmlc_opt_owner_statements(_owner);
	var _params = __gmlc_opt_param_names(_owner);
	var _i = 0; repeat (array_length(_list)) {
		var _statement = _list[_i];
		if (_statement.kind == __GMLC_NodeKind_VarDeclList) {
			var _d = 0; repeat (array_length(_statement.declarations)) {
				var _decl = _statement.declarations[_d];
				if (__gmlc_opt_is_local(_decl.target)) && (_decl.init != undefined) && (!array_contains(_params, _decl.target.name)) {
					var _name = _decl.target.name;
					if (struct_exists(_state.candidates, _name)) {
						_state.candidates[$ _name].dup = true;
					}
					else {
						var _kind = __gmlc_opt_candidate_kind(_decl.init, _names);
						if (_kind != undefined) {
							var _candidate = { name: _name, kind: _kind, declarator: _decl, dup: false, early: false, uses: [] };
							_state.candidates[$ _name] = _candidate;
							array_push(_state.order, _candidate);
						}
					}
				}
			_d++}
		}
	_i++}
	if (array_length(_state.order) == 0) return _state;
	var _holder = (_owner.kind == __GMLC_NodeKind_Script) ? _owner : _owner.body;
	var _s = 0; repeat (array_length(_list)) {
		__gmlc_opt_candidate_scan_node(_list[_s], _holder, _state);
	_s++}
	return _state;
}

#region jsDoc
/// @func    __gmlc_opt_candidate_kind(_init, _names)
/// @desc    What a declared local holds, when a pass can follow it: "function" for a plain function literal, "alias"
///          for the name of a function the file declares, "struct" for a struct literal.
/// @param   {Struct.ASTNode} _init  : The value
/// @param   {Struct}         _names : The functions of the file
/// @returns {String|Undefined}
#endregion
function __gmlc_opt_candidate_kind(_init, _names) {
	switch (_init.kind) {
		case __GMLC_NodeKind_FunctionExpr:
		return (_init.is_constructor || (_init.parent != undefined)) ? undefined : "function";
		case __GMLC_NodeKind_Identifier:
		return ((_init.symbol != undefined) && (_init.symbol.kind == "Global") && (_names[$ _init.name] == true)) ? "alias" : undefined;
		case __GMLC_NodeKind_StructLiteral:
		return "struct";
	}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_opt_candidate_scan_node(_node, _parent, _state)
/// @desc    Records the uses of the candidate locals under a node in source order, leaving out nested functions
///          (their names are their own).
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {Struct.ASTNode} _parent : Its parent
/// @param   {Struct}         _state  : What __scan builds
#endregion
function __gmlc_opt_candidate_scan_node(_node, _parent, _state) {
	switch (_node.kind) {
		case __GMLC_NodeKind_FunctionDecl:
		case __GMLC_NodeKind_ConstructorDecl:
		case __GMLC_NodeKind_FunctionExpr:
		return;
		case __GMLC_NodeKind_VarDecl: {
			var _target = _node.target;
			if (__gmlc_opt_is_local(_target)) && (struct_exists(_state.candidates, _target.name)) {
				var _candidate = _state.candidates[$ _target.name];
				if (_candidate.declarator != _node) _candidate.dup = true;
				if (_node.init != undefined) __gmlc_opt_candidate_scan_node(_node.init, _node, _state);
				if (_candidate.declarator == _node) _state.declared[$ _target.name] = true;
				return;
			}
		break;}
		case __GMLC_NodeKind_ExprStmt: {
			_state.stmt_call = _node.expression;
			if (__gmlc_opt_candidate_scan_store(_node, _parent, _state)) return;
		break;}
		case __GMLC_NodeKind_Identifier: {
			if (__gmlc_opt_is_local(_node)) && (struct_exists(_state.candidates, _node.name)) __gmlc_opt_candidate_record_use(_node, _parent, _state);
		return;}
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_opt_candidate_scan_node(_child, _node, _state);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_candidate_scan_store(_node, _parent, _state)
/// @desc    Records `name.member = value;` as a statement on a struct local as a store, and visits the value.
/// @param   {Struct.ASTNode} _node   : The statement
/// @param   {Struct.ASTNode} _parent : Its parent
/// @param   {Struct}         _state  : What __scan builds
/// @returns {Bool} Whether the statement was one
#endregion
function __gmlc_opt_candidate_scan_store(_node, _parent, _state) {
	var _expr = _node.expression;
	if (_expr.kind != __GMLC_NodeKind_Assign) || (_expr.op != "=") return false;
	var _target = _expr.target;
	if (_target.kind != __GMLC_NodeKind_Index) || (_target.accessor != "Dot") || (!__gmlc_opt_is_local(_target.object)) return false;
	if (!struct_exists(_state.candidates, _target.object.name)) return false;
	var _candidate = _state.candidates[$ _target.object.name];
	if (_candidate.kind != "struct") return false;
	var _holder = _parent.kind;
	if (_holder != __GMLC_NodeKind_Script) && (_holder != __GMLC_NodeKind_Block) && (_holder != __GMLC_NodeKind_Case) && (_holder != __GMLC_NodeKind_Default) return false;
	if (_state.declared[$ _candidate.name] != true) {
		_candidate.early = true;
		return true;
	}
	array_push(_candidate.uses, {
		kind: "store", member: _target.member, droppable: __gmlc_opt_droppable(_expr.value),
		frozen: _state.cx.optimizer.__isNoOp(_node), args: [], has_empty: false, stmt: false,
	});
	__gmlc_opt_candidate_scan_node(_expr.value, _expr, _state);
	return true;
}

#region jsDoc
/// @func    __gmlc_opt_candidate_record_use(_node, _parent, _state)
/// @desc    Adds one use of a candidate local to its record, or marks the local early when the declaration has not
///          run yet.
/// @param   {Struct.ASTNode} _node   : The identifier
/// @param   {Struct.ASTNode} _parent : Its parent
/// @param   {Struct}         _state  : What __scan builds
#endregion
function __gmlc_opt_candidate_record_use(_node, _parent, _state) {
	var _candidate = _state.candidates[$ _node.name];
	if (_state.declared[$ _node.name] != true) {
		_candidate.early = true;
		return;
	}
	var _use = { kind: "read", member: "", droppable: false, frozen: false, args: [], has_empty: false, stmt: false };
	switch (_parent.kind) {
		case __GMLC_NodeKind_Call: {
			if (_parent.callee == _node) {
				_use.kind = "call";
				_use.frozen = _state.cx.optimizer.__isNoOp(_parent);
				_use.stmt = (_parent == _state.stmt_call);
				__gmlc_opt_candidate_call_args(_parent, _use, _state.names, _state.constants ? _state.cx : undefined);
			}
			else if (_parent.args[0] == _node) && (__gmlc_opt_builtin_call(_parent) == "script_execute") {
				_use.kind = "execute";
			}
		break;}
		case __GMLC_NodeKind_Assign: {
			if (_parent.target == _node) _use.kind = "write";
		break;}
		case __GMLC_NodeKind_Update:
		case __GMLC_NodeKind_Delete:
		case __GMLC_NodeKind_Try:
			_use.kind = "write";
		break;
		case __GMLC_NodeKind_Index: {
			if (_parent.accessor == "Dot") && (_parent.object == _node) {
				_use.kind = "member";
				_use.member = _parent.member;
				_use.frozen = _state.cx.optimizer.__isNoOp(_parent);
			}
		break;}
	}
	array_push(_candidate.uses, _use);
}

#region jsDoc
/// @func    __gmlc_opt_candidate_call_args(_call, _use, _names, _cx)
/// @desc    Records what each argument of a call is: whether it can be left out (no effect, cannot throw) and the
///          constant it is, if any.
/// @param   {Struct.ASTCall} _call  : The call
/// @param   {Struct}         _use   : The use record
/// @param   {Struct}         _names : The functions of the file
/// @param   {Struct|Undefined} _cx  : The pass context, when a compile-time constant argument counts
#endregion
function __gmlc_opt_candidate_call_args(_call, _use, _names, _cx) {
	var _args = _call.args;
	var _i = 0; repeat (array_length(_args)) {
		var _arg = _args[_i];
		if (_arg.kind == __GMLC_NodeKind_Empty) {
			_use.has_empty = true;
			array_push(_use.args, { droppable: false, constant: undefined });
		}
		else {
			array_push(_use.args, { droppable: __gmlc_opt_droppable(_arg), constant: __gmlc_opt_candidate_constant(_arg, _names, _cx) });
		}
	_i++}
}

#region jsDoc
/// @func    __gmlc_opt_candidate_constant(_arg, _names, _cx)
/// @desc    The argument itself when it is a literal, a built-in constant of a plain value (`true`, `undefined`,
///          `c_red`) or the name of a function the file declares, with no macro behind it; otherwise undefined.
/// @param   {Struct.ASTNode} _arg   : The argument
/// @param   {Struct}         _names : The functions of the file
/// @param   {Struct|Undefined} _cx  : The pass context, when a compile-time constant argument counts
/// @returns {Struct.ASTNode|Undefined}
#endregion
function __gmlc_opt_candidate_constant(_arg, _names, _cx) {
	if (_arg.origin != undefined) return undefined;
	if (_arg.kind == __GMLC_NodeKind_Literal) return _arg;
	if (_arg.kind == __GMLC_NodeKind_Identifier) && (_cx != undefined) && (_cx.optimizer.__constantValue(_arg)[0]) return _arg;
	if (_arg.kind == __GMLC_NodeKind_Identifier) && (_arg.symbol != undefined) && (_arg.symbol.kind == "Global") && (_names[$ _arg.name] == true) return _arg;
	return undefined;
}

#region jsDoc
/// @func    __gmlc_opt_droppable(_node)
/// @desc    Whether an expression can be left out without anyone noticing: no effect, cannot throw, no asset named.
///          Array and struct literals count when what they hold does.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_opt_droppable(_node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_ArrayLiteral: {
			var _i = 0; repeat (array_length(_node.elements)) {
				if (!__gmlc_opt_droppable(_node.elements[_i])) return false;
			_i++}
		return true;}
		case __GMLC_NodeKind_StructLiteral: {
			var _i = 0; repeat (array_length(_node.entries)) {
				if (!__gmlc_opt_droppable(_node.entries[_i].value)) return false;
			_i++}
		return true;}
	}
	return !__gmlc_opt_has_effects(_node) && !__gmlc_opt_may_throw(_node) && !__gmlc_opt_has_asset_symbol(_node);
}

#region jsDoc
/// @func    __gmlc_opt_candidate_calls_only(_candidate)
/// @desc    Whether a local holding a function literal is only ever called directly, after its declaration, and
///          never in code a pragma freezes: the function cannot be reached any other way.
/// @param   {Struct} _candidate : The candidate
/// @returns {Bool}
#endregion
function __gmlc_opt_candidate_calls_only(_candidate) {
	if (_candidate.kind != "function") || (_candidate.dup) || (_candidate.early) return false;
	var _i = 0; repeat (array_length(_candidate.uses)) {
		var _use = _candidate.uses[_i];
		if (_use.kind != "call") || (_use.frozen) || (_use.has_empty) return false;
	_i++}
	return true;
}

#region jsDoc
/// @func    __gmlc_opt_drop_written(_node, _names)
/// @desc    Takes out of a set of names every name the code under a node assigns or increments.
/// @param   {Struct.ASTNode} _node  : The node
/// @param   {Struct}         _names : name to true
#endregion
function __gmlc_opt_drop_written(_node, _names) {
	var _target = undefined;
	if (_node.kind == __GMLC_NodeKind_Assign) {
		_target = _node.target;
	}
	else if (_node.kind == __GMLC_NodeKind_Update) {
		_target = _node.argument;
	}
	if (_target != undefined) && (_target.kind == __GMLC_NodeKind_Identifier) && (_names[$ _target.name] == true) {
		_names[$ _target.name] = false;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_opt_drop_written(_child, _names);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_function_entry(_fn, _script)
/// @desc    The function table entry of a function literal when nothing in it reads its arguments by position or
///          count, so its parameters can change; otherwise undefined.
/// @param   {Struct.ASTFunctionExpr} _fn     : The function
/// @param   {Struct.ASTScript}       _script : The file
/// @returns {Struct|Undefined}
#endregion
function __gmlc_opt_function_entry(_fn, _script) {
	if (_fn.fn_id == undefined) || (_fn.fn_id >= array_length(_script.functions)) return undefined;
	var _info = _script.functions[_fn.fn_id];
	if (_info == undefined) || (_info.facts == undefined) return undefined;
	var _facts = _info.facts;
	if (_facts.uses_argument_array) || (_facts.uses_argument_count) || (_facts.max_argument_index >= 0) return undefined;
	return _info;
}

#region jsDoc
/// @func    __gmlc_opt_function_names(_script)
/// @desc    The functions a file declares at its top level that a script registers globally and the file never
///          assigns: the names that only ever mean that function.
/// @param   {Struct.ASTScript} _script : The file
/// @returns {Struct} name to true
#endregion
function __gmlc_opt_function_names(_script) {
	var _names = {};
	var _body = _script.body;
	var _i = 0; repeat (array_length(_body)) {
		var _statement = _body[_i];
		if (_statement.kind == __GMLC_NodeKind_FunctionDecl) && (_statement.fn_id != undefined) && (_statement.fn_id < array_length(_script.functions)) && (_script.functions[_statement.fn_id].registration == "global") {
			_names[$ _statement.name] = true;
		}
	_i++}
	__gmlc_opt_drop_written(_script, _names);
	return _names;
}

#region jsDoc
/// @func    __gmlc_opt_param_names(_owner)
/// @desc    The names of a unit's parameters.
/// @param   {Struct.ASTNode} _owner : The Script or a function node
/// @returns {Array<String>}
#endregion
function __gmlc_opt_param_names(_owner) {
	var _out = [];
	if (_owner.kind == __GMLC_NodeKind_Script) return _out;
	var _i = 0; repeat (array_length(_owner.params)) {
		array_push(_out, _owner.params[_i].target.name);
	_i++}
	return _out;
}

#region jsDoc
/// @func    __gmlc_opt_function_owners(_script)
/// @desc    The units a pass looks at: the file's body, then every function node under it in source order. A local
///          of one unit is never seen from another.
/// @param   {Struct.ASTScript} _script : The file
/// @returns {Array<Struct.ASTNode>}
#endregion
function __gmlc_opt_function_owners(_script) {
	var _out = [_script];
	__gmlc_opt_collect_function_owners(_script, _out);
	return _out;
}

#region jsDoc
/// @func    __gmlc_opt_collect_function_owners(_node, _out)
/// @desc    Adds every function node under a node to a list.
/// @param   {Struct.ASTNode}        _node : The node
/// @param   {Array<Struct.ASTNode>} _out  : The list
#endregion
function __gmlc_opt_collect_function_owners(_node, _out) {
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_opt_is_function(_child)) array_push(_out, _child);
				__gmlc_opt_collect_function_owners(_child, _out);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_owner_statements(_owner)
/// @desc    The statements a unit's body holds directly.
/// @param   {Struct.ASTNode} _owner : The Script or a function node
/// @returns {Array<Struct.ASTNode>}
#endregion
function __gmlc_opt_owner_statements(_owner) {
	return (_owner.kind == __GMLC_NodeKind_Script) ? _owner.body : _owner.body.body;
}

#region jsDoc
/// @func    __gmlc_opt_shift_slots(_node, _index)
/// @desc    Gives the locals of a function after a removed parameter the slot before theirs, nested functions
///          left out.
/// @param   {Struct.ASTNode} _node  : The node
/// @param   {Real}           _index : The removed parameter's position
#endregion
function __gmlc_opt_shift_slots(_node, _index) {
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (!__gmlc_opt_is_function(_child)) {
					if (__gmlc_opt_is_local(_child)) {
						if (_child.symbol.slot != undefined) && (_child.symbol.slot > _index) {
							_child.symbol = new GMLC_Symbol("Local", _child.name, _child.symbol.slot - 1);
						}
					}
					else {
						__gmlc_opt_shift_slots(_child, _index);
					}
				}
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_edit_calls(_node, _name, _remove)
/// @desc    Takes the arguments of the removed parameters out of the calls of a local under a node, nested
///          functions left out.
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {String}         _name   : The local that holds the function
/// @param   {Array<Real>}    _remove : The positions, highest first
#endregion
function __gmlc_opt_edit_calls(_node, _name, _remove) {
	if (__gmlc_opt_is_function(_node)) return;
	if (_node.kind == __GMLC_NodeKind_Call) && (__gmlc_opt_is_local(_node.callee)) && (_node.callee.name == _name) {
		var _k = 0; repeat (array_length(_remove)) {
			if (array_length(_node.args) > _remove[_k]) array_delete(_node.args, _remove[_k], 1);
		_k++}
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_opt_edit_calls(_child, _name, _remove);
			}
		_i++}
	_field_index++}
}
#endregion

#region Value kinds
#region jsDoc
/// @func    __gmlc_opt_builtin_code(_name)
/// @desc    What the built-in data says of a built-in function, as bits: 1 when it returns a real or a bool, 2 when
///          every parameter is a real, 4 when it returns nothing.
/// @param   {String} _name : The function
/// @returns {Real}
#endregion
function __gmlc_opt_builtin_code(_name) {
	static __codes = undefined;
	if (__codes == undefined) {
		__codes = {};
		var _functions = __GmlcDataSpec().functions;
		var _i = 0; repeat (array_length(_functions)) {
			var _entry = _functions[_i];
			var _returns = _entry[$ "returnType"] ?? "";
			var _code = 0;
			if (_returns == "Real") || (_returns == "Bool") {
				_code = 1;
			}
			else if (_returns == "Undefined") {
				_code = 4;
			}
			var _parameters = _entry[$ "parameters"] ?? [];
			var _real = true;
			var _p = 0; repeat (array_length(_parameters)) {
				if (_parameters[_p].type != "Real") _real = false;
			_p++}
			if (_real) _code += 2;
			__codes[$ _entry.name] = _code;
		_i++}
	}
	return __codes[$ _name] ?? 0;
}

#region jsDoc
/// @func    __gmlc_opt_is_real_instance(_name)
/// @desc    Whether a name is a built-in instance variable that holds a real.
/// @param   {String} _name : The name
/// @returns {Bool}
#endregion
function __gmlc_opt_is_real_instance(_name) {
	var _entry = __gmlc_opt_builtin_variable(_name);
	return (_entry != undefined) && (_entry.instance) && (_entry.type == "Real");
}

#region jsDoc
/// @func    __gmlc_opt_index_proved(_node, _range)
/// @desc    Whether an array read is inside the array: `a[i]` where the loop counts `i` from a whole number
///          below the length of `a`, which the loop does not change.
/// @param   {Struct.ASTNode} _node  : The read
/// @param   {Struct}         _range : {array, index}: the local array and the loop's counter
/// @returns {Bool}
#endregion
function __gmlc_opt_index_proved(_node, _range) {
	if (_node.accessor != "Array") || (array_length(_node.keys) != 1) return false;
	var _object = _node.object;
	var _key = _node.keys[0];
	return (__gmlc_opt_is_local(_object)) && (__gmlc_opt_is_local(_key)) && (_object.name == _range.array) && (_key.name == _range.index);
}

#region jsDoc
/// @func    __gmlc_opt_value_write_kind(_write, _current, _kinds, _cx)
/// @desc    What a local holds after one write, given what it held before.
/// @param   {Struct} _write   : {name, op, value}
/// @param   {Real}   _current : The kind of the local so far
/// @param   {Struct} _kinds   : The kinds so far
/// @param   {Struct} _cx      : The pass context
/// @returns {Real}
#endregion
function __gmlc_opt_value_write_kind(_write, _current, _kinds, _cx) {
	var _op = _write.op;
	if (_op == "?") return 0;
	if (_op == "++") return _current;
	if (_op == "=") return __gmlc_opt_value_kind(_write.value, _kinds, _cx);
	if (_op == "&=") || (_op == "|=") || (_op == "^=") return 1;
	if (_op == "+=") || (_op == "-=") || (_op == "*=") || (_op == "/=") || (_op == "%=") {
		return ((_current == 2) && (__gmlc_opt_value_kind(_write.value, _kinds, _cx) == 2)) ? 2 : 1;
	}
	return 0;
}

#region jsDoc
/// @func    __gmlc_opt_value_kind(_node, _kinds, _cx, [_x])
/// @desc    What an expression holds when it finishes without an error: 2 a double, 1 a number or a bool, 0
///          anything else. Arithmetic on a value of unknown type either throws or gives a number.
/// @param   {Struct.ASTNode} _node  : The expression
/// @param   {Struct}         _kinds : The kinds of the locals
/// @param   {Struct}         _cx    : The pass context
/// @param   {Struct}         [_x]   : {kept, range, in_with}: names that hold a number for the pass's own reasons
/// @returns {Real}
#endregion
function __gmlc_opt_value_kind(_node, _kinds, _cx, _x = undefined) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal: {
			switch (_node.ty) {
				case "real": return 2;
				case "int64": case "bool": case "color": return 1;
			}
			return 0;
		}
		case __GMLC_NodeKind_Identifier: {
			var _symbol = _node.symbol;
			if (_symbol == undefined) return 0;
			switch (_symbol.kind) {
				case "Local": return max(_kinds[$ _node.name] ?? 0, __gmlc_opt_double_level(_node));
				case "Self": {
					var _own = __gmlc_opt_builtin_variable(_node.name);
					if (_own != undefined) return (_own.type == "Real") ? 2 : 0;
					return max((_x != undefined) ? (_x.kept[$ _symbol.kind + ":" + _node.name] ?? 0) : 0, __gmlc_opt_double_level(_node));
				}
				case "Global": return (_x != undefined) ? (_x.kept[$ _symbol.kind + ":" + _node.name] ?? 0) : 0;
				case "BuiltinVar": {
					var _builtin = __gmlc_opt_builtin_variable(_node.name);
					return ((_builtin != undefined) && (_builtin.type == "Real")) ? 2 : 0;
				}
				case "BuiltinConstant": {
					var _data = _cx.env.getConstant(_node.name);
					if (_data == undefined) return 0;
					if (is_bool(_data.value)) || (is_int64(_data.value)) return 1;
					return is_real(_data.value) ? 2 : 0;
				}
			}
			return 0;
		}
		case __GMLC_NodeKind_Index: {
			var _object = _node.object;
			if (_x != undefined) && (_x.range != undefined) && (__gmlc_opt_index_proved(_node, _x.range)) return 1;
			if (_node.accessor == "Dot") && (_object.kind == __GMLC_NodeKind_Identifier) && (_object.name == "other") && (_object.symbol != undefined) && (_object.symbol.kind == "BuiltinVar") && (__gmlc_opt_is_real_instance(_node.member)) && (__gmlc_opt_self_is_instance(_cx, _node)) return 2;
			return __gmlc_opt_double_level(_node);
		}
		case __GMLC_NodeKind_Binary: {
			var _a = __gmlc_opt_value_kind(_node.left, _kinds, _cx, _x);
			var _b = __gmlc_opt_value_kind(_node.right, _kinds, _cx, _x);
			switch (_node.op) {
				case "+": {
					if (_a == 0) && (_b == 0) return 0;
					return ((_a == 2) && (_b == 2)) ? 2 : 1;
				}
				case "-": case "*": case "/": case "div": case "mod": return ((_a == 2) && (_b == 2)) ? 2 : 1;
			}
			return 1;
		}
		case __GMLC_NodeKind_Logical: return 1;
		case __GMLC_NodeKind_Unary: {
			switch (_node.op) {
				case "-": case "+": return (__gmlc_opt_value_kind(_node.argument, _kinds, _cx, _x) == 2) ? 2 : 1;
				case "!": case "~": return 1;
			}
			return 0;
		}
		case __GMLC_NodeKind_Conditional: return min(__gmlc_opt_value_kind(_node.consequent, _kinds, _cx, _x), __gmlc_opt_value_kind(_node.alternate, _kinds, _cx, _x));
		case __GMLC_NodeKind_Call: {
			var _name = __gmlc_opt_builtin_call(_node);
			if (_name == undefined) return 0;
			var _code = __gmlc_opt_builtin_code(_name);
			if ((_code & 1) == 0) return 0;
			if ((_code & 2) == 0) return 1;
			var _i = 0; repeat (array_length(_node.args)) {
				if (_node.args[_i] == undefined) || (__gmlc_opt_value_kind(_node.args[_i], _kinds, _cx, _x) != 2) return 1;
			_i++}
			return 2;
		}
	}
	return 0;
}

#region jsDoc
/// @func    __gmlc_opt_collect_value_writes(_node, _writes, _kinds, _isRoot)
/// @desc    Lists the writes of the locals under a node, nested functions left out, and starts each declared
///          local as a double.
/// @param   {Struct.ASTNode} _node    : The node
/// @param   {Array<Struct>}  _writes  : {name, op, value} for each write
/// @param   {Struct}         _kinds   : The kinds so far
/// @param   {Bool}           _isRoot  : Whether the node is the function itself
#endregion
function __gmlc_opt_collect_value_writes(_node, _writes, _kinds, _isRoot) {
	if (!_isRoot) && (__gmlc_opt_is_function(_node)) return;
	switch (_node.kind) {
		case __GMLC_NodeKind_Param: _kinds[$ _node.target.name] = 0; break;
		case __GMLC_NodeKind_VarDecl: {
			if (__gmlc_opt_is_local(_node.target)) {
				var _name = _node.target.name;
				if (!struct_exists(_kinds, _name)) _kinds[$ _name] = 2;
				array_push(_writes, { name: _name, op: (_node.init == undefined) ? "?" : "=", value: _node.init });
			}
		break;}
		case __GMLC_NodeKind_Assign: {
			if (__gmlc_opt_is_local(_node.target)) array_push(_writes, { name: _node.target.name, op: _node.op, value: _node.value });
		break;}
		case __GMLC_NodeKind_Update: {
			if (__gmlc_opt_is_local(_node.argument)) array_push(_writes, { name: _node.argument.name, op: "++", value: undefined });
		break;}
		case __GMLC_NodeKind_Try: {
			if (_node.catch_param != undefined) _kinds[$ _node.catch_param.name] = 0;
		break;}
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_opt_collect_value_writes(_child, _writes, _kinds, false);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_local_value_kinds(_root, _cx)
/// @desc    What each `var` local of a function holds wherever it is written: 2 a double, 1 a number or a bool,
///          0 anything else (parameters, catch variables and locals written with something unknown).
/// @param   {Struct.ASTNode} _root : The function
/// @param   {Struct}         _cx   : The pass context
/// @returns {Struct} local name to kind
#endregion
function __gmlc_opt_local_value_kinds(_root, _cx) {
	var _writes = [];
	var _kinds = {};
	__gmlc_opt_collect_value_writes(_root, _writes, _kinds, true);
	var _changed = true;
	while (_changed) {
		_changed = false;
		var _w = 0; repeat (array_length(_writes)) {
			var _write = _writes[_w];
			var _current = _kinds[$ _write.name];
			if (_current != undefined) && (_current > 0) {
				var _kind = __gmlc_opt_value_write_kind(_write, _current, _kinds, _cx);
				if (_kind < _current) {
					_kinds[$ _write.name] = _kind;
					_changed = true;
				}
			}
		_w++}
	}
	return _kinds;
}

#region jsDoc
/// @func    __gmlc_opt_self_unknown(_with)
/// @desc    Whether the body of a `with` may run with a struct as `self`: unless its target is an object, `all` or
///          `noone`.
/// @param   {Struct.ASTNode} _with : The `with` statement
/// @returns {Bool}
#endregion
function __gmlc_opt_self_unknown(_with) {
	var _target = _with.target;
	if (_target.kind != __GMLC_NodeKind_Identifier) return true;
	return ((_target.symbol == undefined) || (_target.symbol.kind != "Asset")) && (_target.name != "all") && (_target.name != "noone");
}

#region jsDoc
/// @func    __gmlc_opt_safe_value(_node, _kinds, _cx, [_x])
/// @desc    Whether evaluating an expression cannot throw: operators need operands that are numbers, a built-in
///          that checks its arguments needs numbers for parameters that are reals, and reads of instance or global
///          variables, members and array elements are never safe.
/// @param   {Struct.ASTNode} _node  : The expression
/// @param   {Struct}         _kinds : The kinds of the locals
/// @param   {Struct}         _cx    : The pass context
/// @param   {Struct}         [_x]   : {kept, range, in_with}: names that hold a number for the pass's own reasons
/// @returns {Bool}
#endregion
function __gmlc_opt_safe_value(_node, _kinds, _cx, _x = undefined) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal: return true;
		case __GMLC_NodeKind_Identifier: {
			var _symbol = _node.symbol;
			if (_symbol == undefined) return false;
			switch (_symbol.kind) {
				case "Local": case "BuiltinConstant": case "Enum": case "Asset": case "Macro": case "BuiltinVar": return true;
				case "Self": {
					if (__gmlc_opt_builtin_variable(_node.name) != undefined) return ((_x == undefined) || (!_x.in_with)) && __gmlc_opt_reads_instance_builtin(_cx, _node);
					return (_x != undefined) && (struct_exists(_x.kept, _symbol.kind + ":" + _node.name));
				}
				case "Global": return (_x != undefined) && (struct_exists(_x.kept, _symbol.kind + ":" + _node.name));
			}
			return false;
		}
		case __GMLC_NodeKind_Index: {
			if (_x != undefined) && (_x.range != undefined) && (__gmlc_opt_index_proved(_node, _x.range)) return true;
			var _object = _node.object;
			return (_node.accessor == "Dot") && (_object.kind == __GMLC_NodeKind_Identifier) && (_object.name == "other") && (_object.symbol != undefined) && (_object.symbol.kind == "BuiltinVar") && (__gmlc_opt_is_real_instance(_node.member)) && (__gmlc_opt_self_is_instance(_cx, _node));
		}
		case __GMLC_NodeKind_Binary: {
			var _left = _node.left;
			var _right = _node.right;
			if (!__gmlc_opt_safe_value(_left, _kinds, _cx, _x)) || (!__gmlc_opt_safe_value(_right, _kinds, _cx, _x)) return false;
			if (__gmlc_opt_value_kind(_left, _kinds, _cx, _x) == 0) || (__gmlc_opt_value_kind(_right, _kinds, _cx, _x) == 0) return false;
			if (_node.op == "div") || (_node.op == "mod") {
				return (_right.kind == __GMLC_NodeKind_Literal) && ((_right.ty == "real") || (_right.ty == "int64")) && (_right.value != 0);
			}
			return true;
		}
		case __GMLC_NodeKind_Logical: {
			if (!__gmlc_opt_safe_value(_node.left, _kinds, _cx, _x)) || (!__gmlc_opt_safe_value(_node.right, _kinds, _cx, _x)) return false;
			return (__gmlc_opt_value_kind(_node.left, _kinds, _cx, _x) != 0) && (__gmlc_opt_value_kind(_node.right, _kinds, _cx, _x) != 0);
		}
		case __GMLC_NodeKind_Unary: {
			if (!__gmlc_opt_safe_value(_node.argument, _kinds, _cx, _x)) return false;
			return (__gmlc_opt_value_kind(_node.argument, _kinds, _cx, _x) != 0);
		}
		case __GMLC_NodeKind_Conditional: {
			if (!__gmlc_opt_safe_value(_node.test, _kinds, _cx, _x)) || (!__gmlc_opt_safe_value(_node.consequent, _kinds, _cx, _x)) || (!__gmlc_opt_safe_value(_node.alternate, _kinds, _cx, _x)) return false;
			return (__gmlc_opt_value_kind(_node.test, _kinds, _cx, _x) != 0);
		}
		case __GMLC_NodeKind_Call: {
			var _name = __gmlc_opt_builtin_call(_node);
			if (_name == undefined) return false;
			var _effects = __GmlcDataEffects();
			var _entry = _effects[$ _name];
			if (_entry == undefined) return false;
			var _i = 0; repeat (array_length(_node.args)) {
				if (_node.args[_i] == undefined) || (!__gmlc_opt_safe_value(_node.args[_i], _kinds, _cx, _x)) return false;
			_i++}
			if (!_entry.may_throw) {
				// the flag holds only for arguments the signature takes; a number by __kind passes for a real
				var _typeOf = method({ kinds: _kinds, cx: _cx, extra: _x }, function(_arg) {
					return (__gmlc_opt_value_kind(_arg, kinds, cx, extra) != 0) ? "Real" : __gmlc_opt_value_type(_arg);
				});
				return __gmlc_opt_args_accepted(_name, _node.args, _typeOf);
			}
			if ((__gmlc_opt_builtin_code(_name) & 2) == 0) return false;
			_i = 0; repeat (array_length(_node.args)) {
				if (__gmlc_opt_value_kind(_node.args[_i], _kinds, _cx, _x) == 0) return false;
			_i++}
			return true;
		}
	}
	return false;
}
#endregion

#region Shared helpers of the rewriting passes
#region jsDoc
/// @func    __gmlc_opt_retag_span(_node, _span)
/// @desc    Gives a node and everything under it one span.
/// @param   {Struct.ASTNode}   _node : The node
/// @param   {Struct.GMLC_Span} _span : The span
#endregion
function __gmlc_opt_retag_span(_node, _span) {
	_node.span = _span;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_opt_retag_span(_child, _span);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_span_point(_span)
/// @desc    The empty span at the start of a span: code made for a statement belongs to the line the statement
///          starts on.
/// @param   {Struct.GMLC_Span} _span : The span
/// @returns {Struct.GMLC_Span}
#endregion
function __gmlc_opt_span_point(_span) {
	return new GMLC_Span(_span.file, _span.start, _span.start);
}

#region jsDoc
/// @func    __gmlc_opt_count_writes_under(_node, _name, _isRoot)
/// @desc    How many writes of a local are under a node, nested functions left out.
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {String}         _name   : The local
/// @param   {Bool}           _isRoot : Whether the node is the function itself
/// @returns {Real}
#endregion
function __gmlc_opt_count_writes_under(_node, _name, _isRoot) {
	if (!_isRoot) && (__gmlc_opt_is_function(_node)) return 0;
	var _n = 0;
	switch (_node.kind) {
		case __GMLC_NodeKind_Assign:  if (__gmlc_opt_is_local(_node.target)) && (_node.target.name == _name) _n++; break;
		case __GMLC_NodeKind_Update:  if (__gmlc_opt_is_local(_node.argument)) && (_node.argument.name == _name) _n++; break;
		case __GMLC_NodeKind_VarDecl: if (_node.target.name == _name) && (_node.init != undefined) _n++; break;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				_n += __gmlc_opt_count_writes_under(_child, _name, false);
			}
		_i++}
	_field_index++}
	return _n;
}

#region jsDoc
/// @func    __gmlc_opt_collect_local_names(_node, _out)
/// @desc    Collects the locals an expression mentions, each once, nested functions left out.
/// @param   {Struct.ASTNode} _node : The expression
/// @param   {Array<String>}  _out  : Gets the names
#endregion
function __gmlc_opt_collect_local_names(_node, _out) {
	if (__gmlc_opt_is_local(_node)) {
		if (!array_contains(_out, _node.name)) array_push(_out, _node.name);
		return;
	}
	if (__gmlc_opt_is_function(_node)) return;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_opt_collect_local_names(_child, _out);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_function_param_names(_root)
/// @desc    The names of the parameters of a function, none for a script's own code.
/// @param   {Struct.ASTNode} _root : The function
/// @returns {Array<String>}
#endregion
function __gmlc_opt_function_param_names(_root) {
	var _out = [];
	var _params = _root[$ "params"];
	if (_params == undefined) return _out;
	var _i = 0; repeat (array_length(_params)) {
		array_push(_out, _params[_i].target.name);
	_i++}
	return _out;
}

#region jsDoc
/// @func    __gmlc_opt_opaque_macros_holder()
/// @desc    Holds what __gmlc_opt_is_opaque reads: whether the configuration macros fold (the configuration is known
///          and the output belongs to one build), and the names that have a definition for a configuration in the
///          batch; the optimizer sets them around a run.
/// @returns {Struct} {folds, scoped}
#endregion
function __gmlc_opt_opaque_macros_holder() {
	static __holder = { folds: false, scoped: {} };
	return __holder;
}

#region jsDoc
/// @func    __gmlc_opt_set_opaque_macros(_folds, _scoped)
/// @desc    Sets what __gmlc_opt_is_opaque reads and returns what it read before.
/// @param   {Bool}   _folds  : Whether the macros that have a `Config:` definition may fold
/// @param   {Struct} _scoped : The names of the macros that have a `Config:` definition in the batch, as keys
/// @returns {Struct} {folds, scoped}
#endregion
function __gmlc_opt_set_opaque_macros(_folds, _scoped) {
	var _holder = __gmlc_opt_opaque_macros_holder();
	var _before = { folds: _holder.folds, scoped: _holder.scoped };
	_holder.folds = _folds;
	_holder.scoped = _scoped;
	return _before;
}

#region jsDoc
/// @func    __gmlc_opt_is_opaque(_node)
/// @desc    Whether a node comes from a macro that depends on the build configuration, which no pass reads
///          through: a macro whose active definition has a `Config:` prefix, or one that has a definition for
///          another configuration. When the configuration is known and the output belongs to one build none is
///          opaque.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_is_opaque(_node) {
	var _origin = _node.origin;
	if (_origin == undefined) return false;
	var _state = __gmlc_opt_opaque_macros_holder();
	if (_state.folds) return false;
	return (_origin.config != undefined) || ((_origin.kind == "macro") && (_state.scoped[$ _origin.name] != undefined));
}

#region jsDoc
/// @func    __gmlc_opt_is_stable(_node)
/// @desc    Whether an expression gives the same value every time its locals hold the same values: literals,
///          locals, built-in constants, enum names and pure built-ins of those, with the operators.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_opt_is_stable(_node) {
	if (__gmlc_opt_is_opaque(_node)) return false;
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal: return true;
		case __GMLC_NodeKind_Identifier: {
			var _symbol = _node.symbol;
			return (_symbol != undefined) && ((_symbol.kind == "Local") || (_symbol.kind == "BuiltinConstant") || (_symbol.kind == "Enum"));
		}
		case __GMLC_NodeKind_Unary: return __gmlc_opt_is_stable(_node.argument);
		case __GMLC_NodeKind_Binary:
		case __GMLC_NodeKind_Logical: return __gmlc_opt_is_stable(_node.left) && __gmlc_opt_is_stable(_node.right);
		case __GMLC_NodeKind_Call: {
			var _name = __gmlc_opt_builtin_call(_node);
			if (_name == undefined) || (__gmlc_opt_call_class(_name) != "pure") return false;
			var _i = 0; repeat (array_length(_node.args)) {
				if (!__gmlc_opt_is_stable(_node.args[_i])) return false;
			_i++}
			return true;
		}
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_has_comparison(_node)
/// @desc    Whether a comparison is written under a node.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_has_comparison(_node) {
	if (_node.kind == __GMLC_NodeKind_Binary) {
		switch (_node.op) {
			case "==": case "!=": case "<": case "<=": case ">": case ">=": return true;
		}
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_opt_has_comparison(_child)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_terminates(_node)
/// @desc    Whether a statement always leaves: it ends in `return`, `exit`, `throw`, `break` or `continue`, or is an
///          `if` whose two branches do.
/// @param   {Struct.ASTNode} _node : The statement
/// @returns {Bool}
#endregion
function __gmlc_opt_terminates(_node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Return:
		case __GMLC_NodeKind_Exit:
		case __GMLC_NodeKind_Throw:
		case __GMLC_NodeKind_Break:
		case __GMLC_NodeKind_Continue:
		return true;
		case __GMLC_NodeKind_Block: {
			var _n = array_length(_node.body);
			return (_n > 0) && __gmlc_opt_terminates(_node.body[_n - 1]);
		}
		case __GMLC_NodeKind_If:
		return (_node.alternate != undefined) && __gmlc_opt_terminates(_node.consequent) && __gmlc_opt_terminates(_node.alternate);
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_uses_arguments(_node, _isRoot)
/// @desc    Whether the function reads or writes `argument`, `argument0` and the like, which share their places
///          with the parameters, nested functions left out.
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {Bool}           _isRoot : Whether the node is the function itself
/// @returns {Bool}
#endregion
function __gmlc_opt_uses_arguments(_node, _isRoot) {
	if (!_isRoot) && (__gmlc_opt_is_function(_node)) return false;
	if (_node.kind == __GMLC_NodeKind_Identifier) return (string_pos("argument", _node.name) == 1);
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_opt_uses_arguments(_child, false)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_has_try_jump(_node, _isRoot)
/// @desc    Whether a `break` or `continue` is written inside a `try` under a node, nested functions left out.
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {Bool}           _isRoot : Whether the node is the function itself
/// @returns {Bool}
#endregion
function __gmlc_opt_has_try_jump(_node, _isRoot) {
	if (!_isRoot) && (__gmlc_opt_is_function(_node)) return false;
	if (_node.kind == __GMLC_NodeKind_Try) && (__gmlc_opt_has_jump(_node)) return true;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_opt_has_try_jump(_child, false)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_has_jump(_node)
/// @desc    Whether a `break` or `continue` is written under a node, nested functions left out.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_has_jump(_node) {
	if (_node.kind == __GMLC_NodeKind_Break) || (_node.kind == __GMLC_NodeKind_Continue) return true;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (!__gmlc_opt_is_function(_child)) && (__gmlc_opt_has_jump(_child)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_rebuild_children(_node, _edits)
/// @desc    A copy of a node with some of its children replaced; arrays are copied before they are written.
/// @param   {Struct.ASTNode} _node  : The node
/// @param   {Array<Struct>}  _edits : {key, index, node} for each child to replace
/// @returns {Struct.ASTNode}
#endregion
function __gmlc_opt_rebuild_children(_node, _edits) {
	var _copy = variable_clone(_node, 0);
	var _fresh = {};
	var _i = 0; repeat (array_length(_edits)) {
		var _edit = _edits[_i];
		if (_edit.index == undefined) {
			_copy[$ _edit.key] = _edit.node;
		}
		else {
			if (!struct_exists(_fresh, _edit.key)) {
				_copy[$ _edit.key] = variable_clone(_copy[$ _edit.key], 0);
				_fresh[$ _edit.key] = true;
			}
			_copy[$ _edit.key][_edit.index] = _edit.node;
		}
	_i++}
	return _copy;
}
#endregion

#region Counting loops
#region jsDoc
/// @func    __gmlc_opt_counted_header(_for)
/// @desc    The header of a counting loop: `for (var i = start; i < bound; i++)`, with `<`, `<=`, `>`, `>=` or `!=`,
///          and a step of `++`, `--`, `+= literal` or `-= literal`; undefined for any other header.
/// @param   {Struct.ASTFor} _for : The loop
/// @returns {Struct|Undefined} {name, declared, start, cmp, bound, step}
#endregion
function __gmlc_opt_counted_header(_for) {
	var _init = _for.init;
	var _test = _for.test;
	var _update = _for.update;
	if (_init == undefined) || (_test == undefined) || (_update == undefined) return undefined;
	var _name;
	var _start;
	var _declared = false;
	if (_init.kind == __GMLC_NodeKind_VarDeclList) {
		if (array_length(_init.declarations) != 1) || (_init.declarations[0].init == undefined) return undefined;
		_name = _init.declarations[0].target.name;
		_start = _init.declarations[0].init;
		_declared = true;
	}
	else if (_init.kind == __GMLC_NodeKind_ExprStmt) && (_init.expression.kind == __GMLC_NodeKind_Assign) && (_init.expression.op == "=") && (__gmlc_opt_is_local(_init.expression.target)) {
		_name = _init.expression.target.name;
		_start = _init.expression.value;
	}
	else {
		return undefined;
	}
	if (_test.kind != __GMLC_NodeKind_Binary) return undefined;
	var _cmp = _test.op;
	if (_cmp != "<") && (_cmp != "<=") && (_cmp != ">") && (_cmp != ">=") && (_cmp != "!=") return undefined;
	if (!__gmlc_opt_is_local(_test.left)) || (_test.left.name != _name) return undefined;
	if (_update.kind != __GMLC_NodeKind_ExprStmt) return undefined;
	var _expr = _update.expression;
	var _step;
	if (_expr.kind == __GMLC_NodeKind_Update) {
		if (!__gmlc_opt_is_local(_expr[$ "argument"])) || (_expr[$ "argument"].name != _name) return undefined;
		_step = (_expr.op == "++") ? 1 : -1;
	}
	else if (_expr.kind == __GMLC_NodeKind_Assign) && ((_expr.op == "+=") || (_expr.op == "-=")) && (__gmlc_opt_is_local(_expr.target)) && (_expr.target.name == _name) {
		var _amount = __gmlc_opt_real_literal(_expr.value);
		if (_amount == undefined) || (_amount == 0) return undefined;
		_step = (_expr.op == "+=") ? _amount : -_amount;
	}
	else {
		return undefined;
	}
	return { name: _name, declared: _declared, start: _start, cmp: _cmp, bound: _test.right, step: _step };
}

#region jsDoc
/// @func    __gmlc_opt_real_literal(_node)
/// @desc    The value of a finite real literal, undefined for any other node.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Real|Undefined}
#endregion
function __gmlc_opt_real_literal(_node) {
	if (_node.kind != __GMLC_NodeKind_Literal) || (_node.ty != "real") || (typeof(_node.value) != "number") return undefined;
	var _value = _node.value;
	if (_value != _value) || (abs(_value) >= infinity) return undefined;
	return _value;
}

#region jsDoc
/// @func    __gmlc_opt_count_defs(_node, _name, _defs, _is_root)
/// @desc    Counts the declarations and the other writes of a local under a node, nested functions left out.
/// @param   {Struct.ASTNode} _node    : The node
/// @param   {String}         _name    : The local
/// @param   {Struct}         _defs    : {decls, writes, init}, counted into
/// @param   {Bool}           _is_root : Whether the node is the function itself
#endregion
function __gmlc_opt_count_defs(_node, _name, _defs, _is_root) {
	if (!_is_root) && (__gmlc_opt_is_function(_node)) return;
	switch (_node.kind) {
		case __GMLC_NodeKind_VarDecl:
			if (_node.target.name == _name) {
				_defs.decls++;
				_defs.init = _node.init;
			}
		break;
		case __GMLC_NodeKind_Assign:
			if (__gmlc_opt_is_local(_node.target)) && (_node.target.name == _name) _defs.writes++;
		break;
		case __GMLC_NodeKind_Update:
			if (__gmlc_opt_is_local(_node[$ "argument"])) && (_node[$ "argument"].name == _name) _defs.writes++;
		break;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_opt_count_defs(_child, _name, _defs, false);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_contained_in(_node, _name, _returned)
/// @desc    Whether a local is only ever named as the array of an element access, as its own declaration, or
///          inside a `return`: no copy of the array is made and none is handed to anything else.
/// @param   {Struct.ASTNode} _node     : The node
/// @param   {String}         _name     : The local
/// @param   {Bool}           _returned : Whether the node is under a `return`
/// @returns {Bool}
#endregion
function __gmlc_opt_contained_in(_node, _name, _returned) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Identifier:
		return _returned || (!__gmlc_opt_is_local(_node)) || (_node.name != _name);
		case __GMLC_NodeKind_VarDecl:
		return (_node.init == undefined) || (__gmlc_opt_contained_in(_node.init, _name, _returned));
		case __GMLC_NodeKind_Return:
		_returned = true;
		break;
		case __GMLC_NodeKind_Index:
			if (_node.accessor == "Array") && (__gmlc_opt_is_local(_node.object)) && (_node.object.name == _name) {
				var _k = 0; repeat (array_length(_node.keys)) {
					if (!__gmlc_opt_contained_in(_node.keys[_k], _name, _returned)) return false;
				_k++}
				return true;
			}
		break;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (!__gmlc_opt_is_function(_child)) && (!__gmlc_opt_contained_in(_child, _name, _returned)) return false;
			}
		_i++}
	_field_index++}
	return true;
}

#region jsDoc
/// @func    __gmlc_opt_offset_of(_node, _name)
/// @desc    The offset of an index from the counter: `i`, `i + n`, `n + i` or `i - n` with a real literal n.
/// @param   {Struct.ASTNode} _node : The index expression
/// @param   {String}         _name : The counter
/// @returns {Real|Undefined}
#endregion
function __gmlc_opt_offset_of(_node, _name) {
	if (__gmlc_opt_is_local(_node)) return (_node.name == _name) ? 0 : undefined;
	if (_node.kind != __GMLC_NodeKind_Binary) return undefined;
	if (_node.op == "+") {
		if (__gmlc_opt_is_local(_node.left)) && (_node.left.name == _name) return __gmlc_opt_real_literal(_node.right);
		if (__gmlc_opt_is_local(_node.right)) && (_node.right.name == _name) return __gmlc_opt_real_literal(_node.left);
	}
	else if (_node.op == "-") && (__gmlc_opt_is_local(_node.left)) && (_node.left.name == _name) {
		var _amount = __gmlc_opt_real_literal(_node.right);
		return (_amount == undefined) ? undefined : -_amount;
	}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_opt_owned_locals(_name, _ctx)
/// @desc    Whether a local is an array the function makes itself and never hands out: its one definition is
///          `array_create(...)` or `[]`, and it is named only as the array of an element access, in its
///          declaration, or inside a `return`.
/// @param   {String} _name : The local
/// @param   {Struct} _ctx  : {name, fn, owned, head, instance, outer}
/// @returns {Bool}
#endregion
function __gmlc_opt_owned_locals(_name, _ctx) {
	var _known = _ctx.owned[$ _name];
	if (_known != undefined) return _known;
	var _defs = { decls: 0, writes: 0, init: undefined };
	__gmlc_opt_count_defs(_ctx.fn, _name, _defs, true);
	var _init = _defs.init;
	var _fresh = (_defs.decls == 1) && (_defs.writes == 0) && (_init != undefined);
	if (_fresh) {
		_fresh = (__gmlc_opt_builtin_call(_init) == "array_create") || ((_init.kind == __GMLC_NodeKind_ArrayLiteral) && (array_length(_init.elements) == 0));
	}
	_known = _fresh && __gmlc_opt_contained_in(_ctx.fn, _name, false);
	_ctx.owned[$ _name] = _known;
	return _known;
}
#endregion

#region String kinds
#region jsDoc
/// @func    __gmlc_opt_string_functions()
/// @desc    The built-in functions that always return a string, as a set.
/// @returns {Struct} Function name to true
#endregion
function __gmlc_opt_string_functions() {
	static __set = {
		string: true, string_copy: true, string_delete: true, string_insert: true, string_lower: true, string_upper: true,
		string_replace: true, string_replace_all: true, string_repeat: true, string_char_at: true, string_concat: true,
		string_join: true, string_format: true, string_digits: true, string_letters: true, string_lettersdigits: true,
		chr: true, ansi_char: true, string_ext: true,
	};
	return __set;
}
#endregion

#region String kind scan
#region jsDoc
/// @func    __gmlc_opt_classify_string(_node)
/// @desc    The type an expression always has: "string" for a string literal, a template string and a call of a
///          built-in that always returns a string, "struct" for a struct literal and `new`, else "".
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {String}
#endregion
function __gmlc_opt_classify_string(_node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal:
		return (_node.ty == "string") ? "string" : "";
		case __GMLC_NodeKind_TemplateString:
		return "string";
		case __GMLC_NodeKind_StructLiteral: case __GMLC_NodeKind_New:
		return "struct";
		case __GMLC_NodeKind_Call: {
			var _name = __gmlc_opt_builtin_call(_node);
			if (_name == undefined) return "";
			var _strings = __gmlc_opt_string_functions();
			return (_strings[$ _name] == true) ? "string" : "";
		}
	}
	return "";
}

#region jsDoc
/// @func    __gmlc_opt_note_string_kind(_kinds, _name, _type)
/// @desc    Adds one write to what is known about a local: a write of another type makes it unknown.
/// @param   {Struct} _kinds : The notes
/// @param   {String} _name  : The local
/// @param   {String} _type  : "string", "struct", "+" for an append of a string or "" for anything else
#endregion
function __gmlc_opt_note_string_kind(_kinds, _name, _type) {
	var _current = _kinds[$ _name];
	if (_type == "") {
		_kinds[$ _name] = "";
	}
	else if (_current == undefined) {
		_kinds[$ _name] = _type;
	}
	else if (_current == "") {
		_kinds[$ _name] = "";
	}
	else if (_type == "+") {
		_kinds[$ _name] = (_current == "struct") ? "" : _current;
	}
	else if (_current == "+") {
		_kinds[$ _name] = (_type == "string") ? "string" : "";
	}
	else {
		_kinds[$ _name] = (_current == _type) ? _current : "";
	}
}

#region jsDoc
/// @func    __gmlc_opt_scan_string_kinds(_node, _kinds, _isRoot)
/// @desc    Notes every write to a local under a node, nested functions left out.
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {Struct}         _kinds  : The notes
/// @param   {Bool}           _isRoot : Whether the node is the function itself
#endregion
function __gmlc_opt_scan_string_kinds(_node, _kinds, _isRoot) {
	if (!_isRoot) && (__gmlc_opt_is_function(_node)) return;
	switch (_node.kind) {
		case __GMLC_NodeKind_VarDecl:
			if (_node.init != undefined) __gmlc_opt_note_string_kind(_kinds, _node.target.name, __gmlc_opt_classify_string(_node.init));
		break;
		case __GMLC_NodeKind_Assign:
			if (__gmlc_opt_is_local(_node.target)) {
				var _type = "";
				if (_node.op == "=") {
					_type = __gmlc_opt_classify_string(_node.value);
				}
				else if (_node.op == "+=") && (__gmlc_opt_classify_string(_node.value) == "string") {
					_type = "+";
				}
				__gmlc_opt_note_string_kind(_kinds, _node.target.name, _type);
			}
		break;
		case __GMLC_NodeKind_Update:
			if (__gmlc_opt_is_local(_node.argument)) __gmlc_opt_note_string_kind(_kinds, _node.argument.name, "");
		break;
		case __GMLC_NodeKind_Try:
			if (_node.catch_param != undefined) __gmlc_opt_note_string_kind(_kinds, _node.catch_param.name, "");
		break;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_opt_scan_string_kinds(_child, _kinds, false);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_opt_string_kinds(_root)
/// @desc    What is proven about the locals of a function from everything written to them: "string" for a local
///          whose every write is a string or an append of a string, "struct" for one whose every write is a struct.
///          Parameters, catch variables and locals with a write of another kind are unknown.
/// @param   {Struct.ASTNode} _root : The function
/// @returns {Struct} Local name to "string", "struct", "+" (appends only) or "" (unknown)
#endregion
function __gmlc_opt_string_kinds(_root) {
	var _kinds = {};
	if (__gmlc_opt_is_function(_root)) {
		var _i = 0; repeat (array_length(_root.params)) {
			_kinds[$ _root.params[_i].target.name] = "";
		_i++}
	}
	__gmlc_opt_scan_string_kinds(_root, _kinds, true);
	return _kinds;
}
#endregion

#region Counted loop helpers
#region jsDoc
/// @func    __gmlc_opt_counted_for(_loop)
/// @desc    The index and the bound of a `for` loop of the form `for (var i = 0; i < bound; i++)` whose body does
///          not write the index, or undefined.
/// @param   {Struct.ASTNode} _loop : The loop
/// @returns {Struct|Undefined} {index, bound}
#endregion
function __gmlc_opt_counted_for(_loop) {
	var _header = __gmlc_opt_counted_header(_loop);
	if (_header == undefined) || (_header.cmp != "<") || (_header.step != 1) || (__gmlc_opt_number_value(_header.start) != 0) return undefined;
	if (__gmlc_opt_writes(_loop.body, _header.name)) return undefined;
	return { index: _header.name, bound: _header.bound };
}

#region jsDoc
/// @func    __gmlc_opt_number_value(_node)
/// @desc    The value of a number literal, or undefined for any other node.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Real|Undefined}
#endregion
function __gmlc_opt_number_value(_node) {
	if (_node.kind != __GMLC_NodeKind_Literal) || ((_node.ty != "real") && (_node.ty != "int64")) return undefined;
	return _node.value;
}

#region jsDoc
/// @func    __gmlc_opt_loop_trips(_loop)
/// @desc    The literal trip count of a `repeat` loop or of a counting `for` loop, or -1 for any other loop.
/// @param   {Struct.ASTNode} _loop : The statement
/// @returns {Real}
#endregion
function __gmlc_opt_loop_trips(_loop) {
	var _bound = undefined;
	if (_loop.kind == __GMLC_NodeKind_Repeat) {
		_bound = _loop.count;
	}
	else if (_loop.kind == __GMLC_NodeKind_For) {
		var _counted = __gmlc_opt_counted_for(_loop);
		if (_counted != undefined) _bound = _counted.bound;
	}
	if (_bound == undefined) return -1;
	var _n = __gmlc_opt_number_value(_bound);
	return ((_n == undefined) || (_n != floor(_n))) ? -1 : _n;
}

#region jsDoc
/// @func    __gmlc_opt_string_initialized(_stmts, _at, _name)
/// @desc    Whether a statement before an index of a list sets a local to a string.
/// @param   {Array<Struct.ASTNode>} _stmts : The statement list
/// @param   {Real}                  _at    : The index
/// @param   {String}                _name  : The local
/// @returns {Bool}
#endregion
function __gmlc_opt_string_initialized(_stmts, _at, _name) {
	var _i = 0; repeat (_at) {
		var _stmt = _stmts[_i];
		if (_stmt.kind == __GMLC_NodeKind_VarDeclList) {
			var _d = 0; repeat (array_length(_stmt.declarations)) {
				var _decl = _stmt.declarations[_d];
				if (_decl.target.name == _name) && (_decl.init != undefined) && (__gmlc_opt_classify_string(_decl.init) == "string") return true;
			_d++}
		}
		else if (_stmt.kind == __GMLC_NodeKind_ExprStmt) && (_stmt.expression.kind == __GMLC_NodeKind_Assign) {
			var _assign = _stmt.expression;
			if (_assign.op == "=") && (__gmlc_opt_is_local(_assign.target)) && (_assign.target.name == _name) && (__gmlc_opt_classify_string(_assign.value) == "string") return true;
		}
	_i++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_has_jump_out(_node)
/// @desc    Whether `break`, `continue`, `exit`, `return` or `throw` appears under a node, nested functions left out.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_has_jump_out(_node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Break: case __GMLC_NodeKind_Continue: case __GMLC_NodeKind_Exit: case __GMLC_NodeKind_Return: case __GMLC_NodeKind_Throw:
		return true;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (!__gmlc_opt_is_function(_child)) && (__gmlc_opt_has_jump_out(_child)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_contains_kind(_node, _kind, _isRoot)
/// @desc    Whether a node of a kind appears under a node, nested functions left out.
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {Real}           _kind   : The node kind
/// @param   {Bool}           _isRoot : Whether the node is the function itself
/// @returns {Bool}
#endregion
function __gmlc_opt_contains_kind(_node, _kind, _isRoot) {
	if (!_isRoot) && (__gmlc_opt_is_function(_node)) return false;
	if (_node.kind == _kind) return true;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_opt_contains_kind(_child, _kind, false)) return true;
			}
		_i++}
	_field_index++}
	return false;
}
#endregion

#region Rebuilding nodes
#region jsDoc
/// @func    __gmlc_opt_rebuilt(_node, _slots, _news)
/// @desc    A copy of a node with some of its children replaced.
/// @param   {Struct.ASTNode} _node  : The node
/// @param   {Array<Struct>}  _slots : Its child slots
/// @param   {Array}          _news  : For each slot the new child, or undefined to keep it
/// @returns {Struct.ASTNode}
#endregion
function __gmlc_opt_rebuilt(_node, _slots, _news) {
	var _copy = variable_clone(_node, 0);
	var _copied = {};
	var _i = 0; repeat (array_length(_slots)) {
		var _new = _news[_i];
		if (_new != undefined) {
			var _slot = _slots[_i];
			var _key = _slot.key;
			if (_slot.index == undefined) {
				_copy[$ _key] = _new;
			}
			else {
				if (!struct_exists(_copied, _key)) {
					var _list = [];
					array_copy(_list, 0, _node[$ _key], 0, array_length(_node[$ _key]));
					_copy[$ _key] = _list;
					_copied[$ _key] = true;
				}
				_copy[$ _key][_slot.index] = _new;
			}
		}
	_i++}
	return _copy;
}
#endregion

#region Statement lists
#region jsDoc
/// @func    __gmlc_opt_is_statement_list(_node)
/// @desc    Whether a node holds a statement list in `body`.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_is_statement_list(_node) {
	var _kind = _node.kind;
	return (_kind == __GMLC_NodeKind_Script) || (_kind == __GMLC_NodeKind_Block) || (_kind == __GMLC_NodeKind_Case) || (_kind == __GMLC_NodeKind_Default);
}
#endregion

#region Pipeline helpers
#region jsDoc
/// @func    __gmlc_opt_count_mentions(_node, _name)
/// @desc    How many times a local is named under a node, nested functions left out.
/// @param   {Struct.ASTNode} _node : The node
/// @param   {String}         _name : The local
/// @returns {Real}
#endregion
function __gmlc_opt_count_mentions(_node, _name) {
	if (_node.kind == __GMLC_NodeKind_Identifier) return (__gmlc_opt_is_local(_node) && (_node.name == _name)) ? 1 : 0;
	var _n = 0;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (!__gmlc_opt_is_function(_child)) _n += __gmlc_opt_count_mentions(_child, _name);
			}
		_i++}
	_field_index++}
	return _n;
}

#region jsDoc
/// @func    __gmlc_opt_is_boolean_expr(_node)
/// @desc    Whether an expression is always true or false: a comparison, a `!`, a boolean literal, an `is_` test, or
///          `&&` and `||` of those.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_opt_is_boolean_expr(_node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Binary:
			return (_node.op == "==") || (_node.op == "!=") || (_node.op == "<") || (_node.op == ">") || (_node.op == "<=") || (_node.op == ">=");
		case __GMLC_NodeKind_Logical:
			return __gmlc_opt_is_boolean_expr(_node.left) && __gmlc_opt_is_boolean_expr(_node.right);
		case __GMLC_NodeKind_Unary:
			return (_node.op == "!");
		case __GMLC_NodeKind_Literal:
			return (_node.ty == "bool");
		case __GMLC_NodeKind_Call: {
			var _name = __gmlc_opt_builtin_call(_node);
			return (_name != undefined) && (string_pos("is_", _name) == 1);
		}
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_opt_builtin_call_node(_name, _args, _span)
/// @desc    A call of a built-in function.
/// @param   {String}           _name : The function
/// @param   {Array}            _args : The arguments
/// @param   {Struct.GMLC_Span} _span : The span
/// @returns {Struct.ASTCall}
#endregion
function __gmlc_opt_builtin_call_node(_name, _args, _span) {
	var _callee = new ASTIdentifier(_span, _name);
	_callee.symbol = new GMLC_Symbol("BuiltinFunction", _name, undefined);
	return new ASTCall(_span, _callee, _args);
}

#region jsDoc
/// @func    __gmlc_opt_source_or_local(_plain, _source, _name, _span)
/// @desc    A new read of the array the chain starts from: a copy of the local it named, or the temporary that
///          holds it.
/// @param   {Bool}             _plain  : Whether the chain started from a local
/// @param   {Struct.ASTNode}   _source : The first argument of the innermost call
/// @param   {String}           _name   : The temporary
/// @param   {Struct.GMLC_Span} _span   : The span
/// @returns {Struct.ASTNode}
#endregion
function __gmlc_opt_source_or_local(_plain, _source, _name, _span) {
	return _plain ? __gmlc_opt_clone(_source) : __gmlc_opt_local(_name, _span);
}

#region jsDoc
/// @func    __gmlc_opt_var_declarations(_node, _name)
/// @desc    How many times a local is declared with `var` under a node, nested functions left out.
/// @param   {Struct.ASTNode} _node : The node
/// @param   {String}         _name : The local
/// @returns {Real}
#endregion
function __gmlc_opt_var_declarations(_node, _name) {
	var _n = 0;
	if (_node.kind == __GMLC_NodeKind_VarDecl) && (_node.target.name == _name) _n++;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (!__gmlc_opt_is_function(_child)) _n += __gmlc_opt_var_declarations(_child, _name);
			}
		_i++}
	_field_index++}
	return _n;
}

#region jsDoc
/// @func    __gmlc_opt_undefined_literal(_span)
/// @desc    The literal `undefined`.
/// @param   {Struct.GMLC_Span} _span : The span
/// @returns {Struct.ASTLiteral}
#endregion
function __gmlc_opt_undefined_literal(_span) {
	return new ASTLiteral(_span, "undefined", "undefined", undefined);
}
#endregion

#region Statement walks
#region jsDoc
/// @func    __gmlc_opt_note_defs(_stmt, _defs)
/// @desc    Records the locals a statement gives a value, so the statements after it can read them.
/// @param   {Struct.ASTNode} _stmt : The statement
/// @param   {Array<String>}  _defs : The names given a value so far
#endregion
function __gmlc_opt_note_defs(_stmt, _defs) {
	if (_stmt.kind == __GMLC_NodeKind_VarDeclList) {
		var _d = 0; repeat (array_length(_stmt.declarations)) {
			var _decl = _stmt.declarations[_d];
			if (_decl.init != undefined) array_push(_defs, _decl.target.name);
		_d++}
	}
	else if (_stmt.kind == __GMLC_NodeKind_ExprStmt) && (_stmt.expression.kind == __GMLC_NodeKind_Assign) {
		var _assign = _stmt.expression;
		if (_assign.op == "=") && (__gmlc_opt_is_local(_assign.target)) array_push(_defs, _assign.target.name);
	}
}

#region jsDoc
/// @func    __gmlc_opt_rename_locals(_node, _map)
/// @desc    Gives every local named in the map its new name, in place, nested functions left out.
/// @param   {Struct.ASTNode} _node : The node, a copy this pass owns
/// @param   {Struct}         _map  : Old name to new name
#endregion
function __gmlc_opt_rename_locals(_node, _map) {
	if (_node.kind == __GMLC_NodeKind_Identifier) {
		if (__gmlc_opt_is_local(_node)) {
			var _to = _map[$ _node.name];
			if (_to != undefined) {
				_node.name = _to;
				_node.symbol = new GMLC_Symbol("Local", _to, undefined);
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
				if (!__gmlc_opt_is_function(_child)) __gmlc_opt_rename_locals(_child, _map);
			}
		_i++}
	_field_index++}
}
#endregion

#region Statement list walks
#region jsDoc
/// @func    __gmlc_opt_walk_statement_lists(_node, _st, _isRoot, _rewrite)
/// @desc    Visits the statement lists of a function, nested functions left out. A loop that `_rewrite` takes is put
///          in its place as the statements it gives; without `_st.apply` the walk only tells whether there is one.
/// @param   {Struct.ASTNode} _node    : The node
/// @param   {Struct}         _st      : {cx, apply, defs}
/// @param   {Bool}           _isRoot  : Whether the node is the function itself
/// @param   {Function}       _rewrite : (_loop, _st, _body, _i) gives the statements that take the place of a loop, or undefined
/// @returns {Bool} Whether a loop was found
#endregion
function __gmlc_opt_walk_statement_lists(_node, _st, _isRoot, _rewrite) {
	if (!_isRoot) && (__gmlc_opt_is_function(_node)) return false;
	var _found = false;
	var _kind = _node.kind;
	if (_kind == __GMLC_NodeKind_Script) || (_kind == __GMLC_NodeKind_Block) || (_kind == __GMLC_NodeKind_Case) || (_kind == __GMLC_NodeKind_Default) {
		var _body = _node.body;
		var _mark = array_length(_st.defs);
		var _i = 0;
		while (_i < array_length(_body)) {
			var _stmt = _body[_i];
			if (_st.cx.optimizer.__isNoOp(_stmt)) {
				_i++;
			}
			else {
				var _new = __gmlc_opt_is_loop(_stmt) ? _rewrite(_stmt, _st, _body, _i) : undefined;
				if (_new != undefined) {
					_found = true;
					if (!_st.apply) return true;
					array_delete(_body, _i, 1);
					var _n = 0; repeat (array_length(_new)) {
						array_insert(_body, _i + _n, _new[_n]);
					_n++}
					_i += array_length(_new);
				}
				else {
					if (__gmlc_opt_walk_statement_lists(_stmt, _st, false, _rewrite)) {
						_found = true;
						if (!_st.apply) return true;
					}
					__gmlc_opt_note_defs(_stmt, _st.defs);
					_i++;
				}
			}
		}
		array_resize(_st.defs, _mark);
		return _found;
	}
	var _children = _node.children();
	var _c = 0; repeat (array_length(_children)) {
		if (__gmlc_opt_walk_statement_lists(_children[_c], _st, false, _rewrite)) {
			_found = true;
			if (!_st.apply) return true;
		}
	_c++}
	return _found;
}
#endregion

#region Rewriting statement lists
#region jsDoc
/// @func    __gmlc_opt_rewrite_lists(_node, _cx, _isRoot, _list, [_arg])
/// @desc    Rewrites the statement lists of a function, inner ones first, without changing the nodes it is given.
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {Struct}         _cx     : The pass context
/// @param   {Bool}           _isRoot : Whether the node is the function itself
/// @param   {Function}       _list   : (_body, _cx, _arg) gives the statements that take the place of a list, or undefined
/// @param   {Any}            [_arg]  : Handed on to _list
/// @returns {Struct.ASTNode|Undefined} The node's replacement
#endregion
function __gmlc_opt_rewrite_lists(_node, _cx, _isRoot, _list, _arg = undefined) {
	var _kind = _node.kind;
	switch (_kind) {
		case __GMLC_NodeKind_Script: case __GMLC_NodeKind_Block: case __GMLC_NodeKind_If: case __GMLC_NodeKind_For:
		case __GMLC_NodeKind_While: case __GMLC_NodeKind_Repeat: case __GMLC_NodeKind_DoUntil: case __GMLC_NodeKind_With:
		case __GMLC_NodeKind_Switch: case __GMLC_NodeKind_Case: case __GMLC_NodeKind_Default: case __GMLC_NodeKind_Try:
		break;
		case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl: case __GMLC_NodeKind_FunctionExpr:
		if (!_isRoot) return undefined;
		break;
		default:
		return undefined;
	}
	if (!_isRoot) && (_cx.optimizer.__isNoOp(_node)) return undefined;
	var _slots = _node.childSlots();
	var _news = undefined;
	var _i = 0; repeat (array_length(_slots)) {
		var _new = __gmlc_opt_rewrite_lists(_slots[_i].node, _cx, false, _list, _arg);
		if (_new != undefined) {
			if (_news == undefined) _news = array_create(array_length(_slots), undefined);
			_news[_i] = _new;
		}
	_i++}
	var _result = (_news != undefined) ? __gmlc_opt_rebuilt(_node, _slots, _news) : undefined;
	if (_kind == __GMLC_NodeKind_Script) || (_kind == __GMLC_NodeKind_Block) || (_kind == __GMLC_NodeKind_Case) || (_kind == __GMLC_NodeKind_Default) {
		var _new_body = _list((_result ?? _node).body, _cx, _arg);
		if (_new_body != undefined) {
			if (_result == undefined) _result = variable_clone(_node, 0);
			_result.body = _new_body;
		}
	}
	return _result;
}
#endregion

#region Rewriting copies
#region jsDoc
/// @func    __gmlc_opt_rewritten_lists(_node, _state, _isRoot, _list)
/// @desc    Rewrites every statement list under a node, nested functions and frozen code left
///          out, without changing the node.
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {Struct}         _state  : The pass's state
/// @param   {Bool}           _isRoot : Whether the node is the function itself
/// @param   {Function}       _list   : (_body, _state) gives the statements that take the place of a list, or undefined
/// @returns {Struct.ASTNode|Undefined} The new node, undefined when nothing changed
#endregion
function __gmlc_opt_rewritten_lists(_node, _state, _isRoot, _list) {
	if (!_isRoot) && ((__gmlc_opt_is_function(_node)) || (_state.optimizer.__isNoOp(_node))) return undefined;
	var _current = _node;
	switch (_node.kind) {
		case __GMLC_NodeKind_Script:
		case __GMLC_NodeKind_Block:
		case __GMLC_NodeKind_Case:
		case __GMLC_NodeKind_Default: {
			var _body = _list(_node.body, _state);
			if (_body != undefined) _current = __gmlc_opt_rebuild_children(_node, [{ key: "body", index: undefined, node: _body }]);
		break;}
		case __GMLC_NodeKind_If:
		case __GMLC_NodeKind_For:
		case __GMLC_NodeKind_While:
		case __GMLC_NodeKind_Repeat:
		case __GMLC_NodeKind_DoUntil:
		case __GMLC_NodeKind_With:
		case __GMLC_NodeKind_Switch:
		case __GMLC_NodeKind_Try:
		case __GMLC_NodeKind_FunctionDecl:
		case __GMLC_NodeKind_ConstructorDecl:
		case __GMLC_NodeKind_FunctionExpr:
		break;
		default: return undefined;
	}
	var _slots = _current.childSlots();
	var _edits = [];
	var _i = 0; repeat (array_length(_slots)) {
		var _slot = _slots[_i];
		var _new = __gmlc_opt_rewritten_lists(_slot.node, _state, false, _list);
		if (_new != undefined) array_push(_edits, { key: _slot.key, index: _slot.index, node: _new });
	_i++}
	if (array_length(_edits) == 0) return (_current == _node) ? undefined : _current;
	return __gmlc_opt_rebuild_children(_current, _edits);
}
#endregion

#region Cached counts
#region jsDoc
/// @func    __gmlc_opt_count_reads(_root, _cache, _name)
/// @desc    How many times a local is read under a root, from the cache or counted and kept there.
/// @param   {Struct.ASTNode} _root  : The function
/// @param   {Struct}         _cache : Local name to its count
/// @param   {String}         _name  : The local
/// @returns {Real}
#endregion
function __gmlc_opt_count_reads(_root, _cache, _name) {
	var _n = _cache[$ _name];
	if (_n == undefined) {
		_n = __gmlc_opt_reads(_root, _name);
		_cache[$ _name] = _n;
	}
	return _n;
}

#region jsDoc
/// @func    __gmlc_opt_count_writes(_root, _cache, _name)
/// @desc    How many times a local is written under a root, from the cache or counted and kept there.
/// @param   {Struct.ASTNode} _root  : The function
/// @param   {Struct}         _cache : Local name to its count
/// @param   {String}         _name  : The local
/// @returns {Real}
#endregion
function __gmlc_opt_count_writes(_root, _cache, _name) {
	var _n = _cache[$ _name];
	if (_n == undefined) {
		_n = __gmlc_opt_count_writes_under(_root, _name, true);
		_cache[$ _name] = _n;
	}
	return _n;
}
#endregion

#region Function nodes
#region jsDoc
/// @func    __gmlc_opt_is_or_holds_function(_node)
/// @desc    Whether a function literal or declaration lies under a node.
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_opt_is_or_holds_function(_node) {
	if (__gmlc_opt_is_function(_node)) return true;
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_opt_is_or_holds_function(_child)) return true;
			}
		_i++}
	_field_index++}
	return false;
}
#endregion
