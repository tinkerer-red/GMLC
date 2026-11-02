#region jsDoc
/// @func    GMLC_Opt_ComparisonSimplify()
/// @desc    The `comparison-simplify` optimizer pass: `!(a < b)` reads `a >= b` (and the other three orderings), and
///          `x == x` reads `true`, when both sides are proven integers: a real may be NaN, where every ordering is
///          false, and an epsilon set in the program lets reals that differ compare equal. The pass does nothing in a
///          batch that sets the epsilon.
/// @returns {Struct.GMLC_Opt_ComparisonSimplify}
#endregion
function GMLC_Opt_ComparisonSimplify() : GMLC_OptimizerPass("comparison-simplify") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The simpler comparison, or undefined when the node stays.
	/// @self    GMLC_Opt_ComparisonSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (_cx.epsilon_set) return undefined;
		var _result = undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Unary:  _result = __negated(_node);   break;
			case __GMLC_NodeKind_Binary: _result = __same(_node, _cx); break;
		}
		if (_result != undefined) _cx.stats[$ "simplified"]++;
		return _result;
	};
	#endregion

	#region Rules
	#region jsDoc
	/// @func    __negated(_node)
	/// @desc    `!(a < b)` is `a >= b` when both sides are integers of one kind: no NaN, and the epsilon cannot make
	///          two different integers equal.
	/// @self    GMLC_Opt_ComparisonSimplify
	/// @param   {Struct.ASTNode} _node : The negation
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __negated = function(_node) {
		if (_node.op != "!") return undefined;
		var _inner = _node.argument;
		if (_inner.kind != __GMLC_NodeKind_Binary) return undefined;
		var _op;
		switch (_inner.op) {
			case "<":  _op = ">="; break;
			case "<=": _op = ">";  break;
			case ">":  _op = "<="; break;
			case ">=": _op = "<";  break;
			default: return undefined;
		}
		var _type = __type(_inner.left);
		if (_type != "Int") && (_type != "Int64") return undefined;
		if (__type(_inner.right) != _type) return undefined;
		if (__gmlc_opt_is_opaque(_node)) || (__gmlc_opt_is_opaque(_inner)) || (__gmlc_opt_is_opaque(_inner.left)) || (__gmlc_opt_is_opaque(_inner.right)) return undefined;
		return new ASTBinary(_node.span, _op, _inner.left, _inner.right);
	};

	#region jsDoc
	/// @func    __same(_node, _cx)
	/// @desc    `x == x` is `true` and `x != x` is `false` for an integer or a string that can be left out: a literal,
	///          a local or a pure call that cannot throw.
	/// @self    GMLC_Opt_ComparisonSimplify
	/// @param   {Struct.ASTNode} _node : The comparison
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __same = function(_node, _cx) {
		var _op = _node.op;
		if (_op != "==") && (_op != "!=") return undefined;
		var _left = _node.left;
		if (!__gmlc_opt_same(_left, _node.right)) || (!__gmlc_opt_is_trivial(_left)) return undefined;
		var _type = __type(_left);
		if (_type != "Int") && (_type != "Int64") && (_type != "String") return undefined;
		if (__gmlc_opt_is_opaque(_node)) || (__gmlc_opt_is_opaque(_left)) || (__gmlc_opt_is_opaque(_node.right)) return undefined;
		return _cx.optimizer.__literal(_op == "==", _node.span);
	};
	#endregion

	#region Facts
	#region jsDoc
	/// @func    __type(_node)
	/// @desc    The type of an expression that its tree and the type a local holds wherever it is read prove: Int (a
	///          finite whole number), Int64, String, or Unknown.
	/// @self    GMLC_Opt_ComparisonSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {String}
	#endregion
	static __type = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier: case __GMLC_NodeKind_Index: {
				var _held = __gmlc_opt_local_type(_node) ?? __gmlc_opt_field_type(_node) ?? "";
				if (_held == "Int") return "Int";
				if (_held == "Int64") || (string_starts_with(_held, "Enum.")) return "Int64";
				if (_held == "String") return "String";
			break;}
			case __GMLC_NodeKind_Literal: {
				switch (_node.ty) {
					case "real": {
						var _value = _node.value;
						return (is_numeric(_value) && (_value == floor(_value)) && (abs(_value) < infinity)) ? "Int" : "Unknown";
					}
					case "int64":  return "Int64";
					case "string": return "String";
				}
			break;}
			case __GMLC_NodeKind_Unary: {
				if (_node.op == "-") && (__type(_node.argument) == "Int") return "Int";
			break;}
			case __GMLC_NodeKind_Binary: {
				if (_node.op == "+") || (_node.op == "-") {
					if (__type(_node.left) == "Int") && (__type(_node.right) == "Int") return "Int";
				}
			break;}
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				switch (_name) {
					case "array_length": case "string_length": case "ds_list_size": case "irandom": return "Int";
					case "int64": return "Int64";
					case "floor": case "ceil": case "round":
						if (array_length(_node.args) == 1) && (__type(_node.args[0]) == "Int") return "Int";
					break;
				}
			break;}
		}
		return "Unknown";
	};

	#endregion
}
