#region jsDoc
/// @func    GMLC_Opt_BooleanSimplify()
/// @desc    The `boolean-simplify` optimizer pass: `!(a == b)` reads `a != b`, `!c ? x : y` reads `c ? y : x`, and for
///          an operand proven to be a bool `b == true` and `b != false` read `b`, `b == false` reads `!b`, `!!b` reads
///          `b` and `b ? true : false` reads `b`. A real is truthy above 0.5 and `!!` makes a bool of it, so nothing is
///          done to `r == true` or `!!r` when `r` may be a real.
///          `!!x` asked only whether it is true reads `x` for any type: a real, a string, an array or a struct is
///          truthy or throws the same way with or without the `!!` (the test of `if`, `while`, `do until`, `for` and
///          `?:`, an operand of `&&`, `||` and `!`). A `var` local that is only assigned `!!x` and only read in such
///          places is assigned `x` instead, when `x` is known to have a truthiness that cannot throw, since the throw
///          would move from the assignment to the read.
/// @returns {Struct.GMLC_Opt_BooleanSimplify}
#endregion
function GMLC_Opt_BooleanSimplify() : GMLC_OptimizerPass("boolean-simplify") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The simpler expression, or undefined when the node stays.
	/// @self    GMLC_Opt_BooleanSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _result = undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Unary:       _result = __not(_node, _cx);    break;
			case __GMLC_NodeKind_Binary:      _result = __equals(_node, _cx); break;
			case __GMLC_NodeKind_Conditional: return __conditional(_node, _cx);
		}
		if (_result != undefined) _cx.stats[$ "simplified"]++;
		return _result;
	};
	#endregion

	#region Rules
	#region jsDoc
	/// @func    __not(_node, _cx)
	/// @desc    `!(a == b)` is `a != b` and `!(a != b)` is `a == b` for any operands, since both forms ask the same
	///          question of the same values. `!!b` is `b` for a bool, and `!!x` is `x` for any `x` where only its truth
	///          is asked, or where it is assigned to a local that is only read that way.
	/// @self    GMLC_Opt_BooleanSimplify
	/// @param   {Struct.ASTNode} _node : The negation
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __not = function(_node, _cx) {
		if (_node.op != "!") return undefined;
		var _inner = _node.argument;
		if (__gmlc_opt_is_opaque(_node)) || (__gmlc_opt_is_opaque(_inner)) return undefined;
		if (_inner.kind == __GMLC_NodeKind_Binary) {
			if (_inner.op == "==") return new ASTBinary(_node.span, "!=", _inner.left, _inner.right);
			if (_inner.op == "!=") return new ASTBinary(_node.span, "==", _inner.left, _inner.right);
			return undefined;
		}
		if (_inner.kind == __GMLC_NodeKind_Unary) && (_inner.op == "!") {
			if (__isBool(_inner.argument, _cx)) || (_cx.condition) || (__assignedToFlag(_cx, _inner.argument)) return _inner.argument;
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __equals(_node, _cx)
	/// @desc    A comparison of a proven bool with `true` or `false`: the bool itself, or its negation.
	/// @self    GMLC_Opt_BooleanSimplify
	/// @param   {Struct.ASTNode} _node : The comparison
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __equals = function(_node, _cx) {
		var _op = _node.op;
		if (_op != "==") && (_op != "!=") return undefined;
		var _left = _node.left;
		var _right = _node.right;
		var _value = __boolValue(_right, _cx);
		var _operand = _left;
		if (_value == undefined) {
			_value = __boolValue(_left, _cx);
			_operand = _right;
		}
		if (_value == undefined) || (!__isBool(_operand, _cx)) return undefined;
		if (__gmlc_opt_is_opaque(_node)) || (__gmlc_opt_is_opaque(_left)) || (__gmlc_opt_is_opaque(_right)) return undefined;
		return ((_op == "==") == _value) ? _operand : new ASTUnary(_node.span, "!", _operand);
	};

	#region jsDoc
	/// @func    __conditional(_node, _cx)
	/// @desc    `c ? true : false` is `c` and `c ? false : true` is `!c` for a proven bool `c`; `!c ? x : y` is
	///          `c ? y : x` for any `c`, since `!c` and `c` fail and pass together.
	/// @self    GMLC_Opt_BooleanSimplify
	/// @param   {Struct.ASTNode} _node : The conditional
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __conditional = function(_node, _cx) {
		var _test = _node.test;
		var _then = _node.consequent;
		var _else = _node.alternate;
		if (__gmlc_opt_is_opaque(_node)) || (__gmlc_opt_is_opaque(_test)) || (__gmlc_opt_is_opaque(_then)) || (__gmlc_opt_is_opaque(_else)) return undefined;
		var _a = __boolValue(_then, _cx);
		var _b = __boolValue(_else, _cx);
		if (_a != undefined) && (_b != undefined) && (_a != _b) && (__isBool(_test, _cx)) {
			_cx.stats[$ "simplified"]++;
			return _a ? _test : new ASTUnary(_node.span, "!", _test);
		}
		if (_test.kind == __GMLC_NodeKind_Unary) && (_test.op == "!") {
			_cx.stats[$ "branches_swapped"]++;
			return new ASTConditional(_node.span, _test.argument, _else, _then);
		}
		return undefined;
	};
	#endregion

	#region Facts
	#region jsDoc
	/// @func    __isBool(_node, _cx)
	/// @desc    Whether an expression is proven a bool by its tree: a bool literal or constant, a comparison, a
	///          logical operation, a negation, a built-in the signature data says returns a bool, or a conditional of
	///          such. A local is not proven here, since its type depends on the code before the expression.
	/// @self    GMLC_Opt_BooleanSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Bool}
	#endregion
	static __isBool = function(_node, _cx) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: return (_node.ty == "bool");
			case __GMLC_NodeKind_Identifier: return (__boolValue(_node, _cx) != undefined);
			case __GMLC_NodeKind_Logical: return true;
			case __GMLC_NodeKind_Unary:   return (_node.op == "!");
			case __GMLC_NodeKind_Binary: {
				switch (_node.op) {
					case "==": case "!=": case "<": case "<=": case ">": case ">=": return true;
				}
			break;}
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) return false;
				var _builtins = __gmlc_type_builtins();
				return (_builtins[$ _name] == "Bool");
			}
			case __GMLC_NodeKind_Conditional: return __isBool(_node.consequent, _cx) && __isBool(_node.alternate, _cx);
		}
		return false;
	};

	#region jsDoc
	/// @func    __boolValue(_node, _cx)
	/// @desc    The value of a bool literal or of a bool built-in constant (`true` written in source is one), or
	///          undefined for anything else.
	/// @self    GMLC_Opt_BooleanSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Bool|Undefined}
	#endregion
	static __boolValue = function(_node, _cx) {
		var _known = _cx.optimizer.__constantValue(_node);
		if (_known[0]) && (is_bool(_known[1])) return _known[1];
		return undefined;
	};

	#endregion

	#region Flags
	#region jsDoc
	/// @func    __assignedToFlag(_cx, _operand)
	/// @desc    Whether `!!x` is the value assigned to a local that is only read as a condition, and `x` is known not
	///          to throw when asked whether it is true.
	/// @self    GMLC_Opt_BooleanSimplify
	/// @param   {Struct}         _cx      : The pass context
	/// @param   {Struct.ASTNode} _operand : The `x`
	/// @returns {Bool}
	#endregion
	static __assignedToFlag = function(_cx, _operand) {
		var _name = _cx.assigned;
		if (_name == undefined) return false;
		switch (__gmlc_opt_value_type(_operand)) {
			case "Real": case "Int64": case "Bool": case "Undefined": case "Struct": case "Function": break;
			default: return false;
		}
		if (_cx.flags == undefined) _cx.flags = __flagLocals(_cx.unit.root);
		if (!struct_exists(_cx.flags, _name)) return false;
		_cx.optimizer.forgetLocal(_cx, _name);
		return true;
	};

	#region jsDoc
	/// @func    __flagLocals(_unit)
	/// @desc    The `var` locals of a function that are assigned only `!!x` and read only where their truth is asked.
	///          A function that reaches its parameters through `argument` is left alone, and so is a name a nested
	///          function mentions.
	/// @self    GMLC_Opt_BooleanSimplify
	/// @param   {Struct.ASTNode} _unit : The function
	/// @returns {Struct} The names as keys
	#endregion
	static __flagLocals = function(_unit) {
		var _flags = {};
		if (__gmlc_opt_uses_arguments(_unit, true)) return _flags;
		var _ok = {};
		var _bad = {};
		var _child_fields = _unit.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _unit[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__scan(_child, false, _ok, _bad);
				}
			_i++}
		_field_index++}
		var _names = struct_get_names(_ok);
		_i = 0; repeat (array_length(_names)) {
			if (!struct_exists(_bad, _names[_i])) _flags[$ _names[_i]] = true;
		_i++}
		return _flags;
	};

	#region jsDoc
	/// @func    __scan(_node, _nested, _ok, _bad)
	/// @desc    Sorts the names under a node: `_ok` for a local assigned `!!x`, `_bad` for any name used in another
	///          way. A name read as a value, written by another form, declared without a value or seen inside a
	///          nested function is bad.
	/// @self    GMLC_Opt_BooleanSimplify
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Bool}           _nested : Whether the node is inside a nested function
	/// @param   {Struct}         _ok     : The names assigned `!!x`
	/// @param   {Struct}         _bad    : The names used in another way
	#endregion
	static __scan = function(_node, _nested, _ok, _bad) {
		if (_node.kind == __GMLC_NodeKind_Identifier) {
			_bad[$ _node.name] = true;
			return;
		}
		_nested = _nested || __gmlc_opt_is_function(_node);
		if (!_nested) {
			var _target = undefined;
			var _value = undefined;
			if (_node.kind == __GMLC_NodeKind_VarDecl) && (__gmlc_opt_is_local(_node.target)) {
				_target = _node.target;
				_value = _node.init;
			}
			else if (_node.kind == __GMLC_NodeKind_ExprStmt) && (_node.expression.kind == __GMLC_NodeKind_Assign) && (_node.expression.op == "=") && (__gmlc_opt_is_local(_node.expression.target)) {
				_target = _node.expression.target;
				_value = _node.expression.value;
			}
			if (_target != undefined) {
				var _operand = (_value == undefined) ? undefined : __notNot(_value);
				if (_operand != undefined) {
					_ok[$ _target.name] = true;
					__scanCondition(_operand, _ok, _bad);
				}
				else {
					_bad[$ _target.name] = true;
					if (_value != undefined) __scan(_value, false, _ok, _bad);
				}
				return;
			}
		}
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			if (!_nested) && (__isCondition(_node, _slot.key)) __scanCondition(_slot.node, _ok, _bad);
			else __scan(_slot.node, _nested, _ok, _bad);
		_i++}
	};

	#region jsDoc
	/// @func    __scanCondition(_node, _ok, _bad)
	/// @desc    Scans an expression that is only asked whether it is true: a local read as the whole of it is a
	///          condition read, any other expression is scanned as it is.
	/// @self    GMLC_Opt_BooleanSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _ok   : The names assigned `!!x`
	/// @param   {Struct}         _bad  : The names used in another way
	#endregion
	static __scanCondition = function(_node, _ok, _bad) {
		if (__gmlc_opt_is_local(_node)) return;
		__scan(_node, false, _ok, _bad);
	};

	#region jsDoc
	/// @func    __isCondition(_node, _key)
	/// @desc    Whether the child in a field of a node is only asked whether it is true: the test of `if`, `while`,
	///          `do until`, `for` and `?:`, an operand of `&&`, `||` and `!`.
	/// @self    GMLC_Opt_BooleanSimplify
	/// @param   {Struct.ASTNode} _node : The parent
	/// @param   {String}         _key  : The field
	/// @returns {Bool}
	#endregion
	static __isCondition = function(_node, _key) {
		switch (_node.kind) {
			case __GMLC_NodeKind_If: case __GMLC_NodeKind_While: case __GMLC_NodeKind_DoUntil: case __GMLC_NodeKind_For: case __GMLC_NodeKind_Conditional: return (_key == "test");
			case __GMLC_NodeKind_Logical: return (_node.op == "&&") || (_node.op == "||");
			case __GMLC_NodeKind_Unary: return (_node.op == "!");
		}
		return false;
	};

	#region jsDoc
	/// @func    __notNot(_node)
	/// @desc    The `x` of `!!x`, or undefined for any other expression.
	/// @self    GMLC_Opt_BooleanSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __notNot = function(_node) {
		if (_node.kind == __GMLC_NodeKind_Unary) && (_node.op == "!") {
			var _inner = _node.argument;
			if (_inner.kind == __GMLC_NodeKind_Unary) && (_inner.op == "!") return _inner.argument;
		}
		return undefined;
	};

	#endregion
}
