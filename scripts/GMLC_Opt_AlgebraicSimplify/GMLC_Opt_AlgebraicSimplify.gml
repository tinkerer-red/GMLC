#region jsDoc
/// @func    GMLC_Opt_AlgebraicSimplify()
/// @desc    The `algebraic-simplify` optimizer pass: identities that hold for every value of the operand's proven
///          type, so `x * 1`, `(y - 0) / 1` and `-(-x)` on built-in variables read `x`, `y` and `x`, and `s + ""` on a
///          string reads `s`. Doubles keep `x + 0` (it turns -0 into 0), `x * 0` and `x - x` (NaN and infinity), and
///          an operand of unknown type keeps every operation (a string must still throw).
/// @returns {Struct.GMLC_Opt_AlgebraicSimplify}
#endregion
function GMLC_Opt_AlgebraicSimplify() : GMLC_OptimizerPass("algebraic-simplify") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The operand an operation reduces to, `-x` for `x * -1`, or undefined when the node stays.
	/// @self    GMLC_Opt_AlgebraicSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _result = undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_Binary: _result = __binary(_node); break;
			case __GMLC_NodeKind_Unary:  _result = __unary(_node);  break;
		}
		if (_result != undefined) _cx.stats[$ "simplified"]++;
		return _result;
	};
	#endregion

	#region Rules
	#region jsDoc
	/// @func    __binary(_node)
	/// @desc    The rule for a binary operation with a neutral number or empty string on one side. Bool and
	///          unknown operands are refused: `true * 1` is the real 1, `"a" * 1` repeats a string and `"a" - 0`
	///          throws. A whole-number literal next to an int64 acts as an int64, so the int64 rules hold for it.
	/// @self    GMLC_Opt_AlgebraicSimplify
	/// @param   {Struct.ASTNode} _node : The operation
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __binary = function(_node) {
		var _op = _node.op;
		var _left = _node.left;
		var _right = _node.right;
		var _cl = __number(_left);
		var _cr = __number(_right);
		var _empty_left = (_op == "+") && (__isEmptyString(_left));
		var _empty_right = (_op == "+") && (__isEmptyString(_right));
		if (_cl == undefined) && (_cr == undefined) && (!_empty_left) && (!_empty_right) return undefined;
		if (__gmlc_opt_is_opaque(_node)) || (__gmlc_opt_is_opaque(_left)) || (__gmlc_opt_is_opaque(_right)) return undefined;
		switch (_op) {
			case "*": {
				if (_cr == 1) && (__isNumber(_left)) return _left;
				if (_cl == 1) && (__isNumber(_right)) return _right;
				if (_cr == -1) && (__type(_left) == "Double") return new ASTUnary(_node.span, "-", _left);
				if (_cl == -1) && (__type(_right) == "Double") return new ASTUnary(_node.span, "-", _right);
			break;}
			case "/": {
				if (_cr == 1) && (__type(_left) == "Double") return _left;
			break;}
			case "-": {
				if (_cr == 0) && (__isNumber(_left)) return _left;
			break;}
			case "+": {
				if (_cr == 0) && (__type(_left) == "Int64") return _left;
				if (_cl == 0) && (__type(_right) == "Int64") return _right;
				if (_empty_right) && (__type(_left) == "String") return _left;
				if (_empty_left) && (__type(_right) == "String") return _right;
			break;}
			case "|":
			case "^": {
				if (_cr == 0) && (__type(_left) == "Int64") return _left;
				if (_cl == 0) && (__type(_right) == "Int64") return _right;
			break;}
			case "&": {
				if (_cr == -1) && (__type(_left) == "Int64") return _left;
				if (_cl == -1) && (__type(_right) == "Int64") return _right;
			break;}
			case "<<":
			case ">>": {
				if (_cr == 0) && (__type(_left) == "Int64") return _left;
			break;}
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __unary(_node)
	/// @desc    `-(-x)` is `x` for a double or an int64 `x` (a negation wraps back at the smallest int64).
	/// @self    GMLC_Opt_AlgebraicSimplify
	/// @param   {Struct.ASTNode} _node : The negation
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __unary = function(_node) {
		if (_node.op != "-") return undefined;
		var _inner = _node.argument;
		if (_inner.kind != __GMLC_NodeKind_Unary) || (_inner.op != "-") return undefined;
		if (__gmlc_opt_is_opaque(_node)) || (__gmlc_opt_is_opaque(_inner)) return undefined;
		return __isNumber(_inner.argument) ? _inner.argument : undefined;
	};
	#endregion

	#region Facts
	#region jsDoc
	/// @func    __held(_node)
	/// @desc    The type a local or a field holds wherever it is read, as Double, Int64, String or Unknown.
	/// @self    GMLC_Opt_AlgebraicSimplify
	/// @param   {Struct.ASTNode} _node : The read
	/// @returns {String}
	#endregion
	static __held = function(_node) {
		switch (__gmlc_opt_value_type(_node)) {
			case "Real":   return "Double";
			case "Int64":  return "Int64";
			case "String": return "String";
		}
		return "Unknown";
	};

	#region jsDoc
	/// @func    __type(_node)
	/// @desc    The type of an expression that its tree and the type a local holds wherever it is read prove: Double,
	///          Int64, String, or Unknown.
	/// @self    GMLC_Opt_AlgebraicSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {String}
	#endregion
	static __type = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: {
				switch (_node.ty) {
					case "real":   return "Double";
					case "int64":  return "Int64";
					case "string": return "String";
				}
			break;}
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				if (_symbol != undefined) && (_symbol.kind == "BuiltinVar") return __variableType(_node.name);
				if (_symbol != undefined) && ((_symbol.kind == "Local") || (_symbol.kind == "Self") || (_symbol.kind == "Static")) return __held(_node);
			break;}
			case __GMLC_NodeKind_Index: case __GMLC_NodeKind_Nullish: return __held(_node);
			case __GMLC_NodeKind_Unary: {
				if (_node.op == "~") return "Int64";
				if (_node.op == "-") {
					var _type = __type(_node.argument);
					if (_type == "Double") || (_type == "Int64") return _type;
				}
			break;}
			case __GMLC_NodeKind_Binary: {
				var _op = _node.op;
				switch (_op) {
					case "&": case "|": case "^": case "<<": case ">>": return "Int64";
					case "+": case "-": case "*": case "/": {
						var _left = _node.left;
						var _right = _node.right;
						var _a = __type(_left);
						var _b = __type(_right);
						if (_a == "Double") && (_b == "Double") return "Double";
						if (_op == "+") && (_a == "String") && (_b == "String") return "String";
						if (_op != "/") {
							if (_a == "Int64") && ((_b == "Int64") || (__isWhole(_right))) return "Int64";
							if (_b == "Int64") && (__isWhole(_left)) return "Int64";
						}
					break;}
				}
			break;}
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) break;
				if (_name == "int64") return "Int64";
				var _builtins = __gmlc_type_builtins();
				var _returned = _builtins[$ _name];
				if (_returned == "String") return "String";
				if (_returned == "Double") {
					// an int64 argument can make a built-in answer with an int64
					var _args = _node.args;
					var _i = 0; repeat (array_length(_args)) {
						var _arg = __type(_args[_i]);
						if (_arg != "Double") && (_arg != "String") return "Unknown";
					_i++}
					return "Double";
				}
			break;}
		}
		return "Unknown";
	};

	#region jsDoc
	/// @func    __variableType(_name)
	/// @desc    The type of a built-in variable the signature data lists as a readable real or string.
	/// @self    GMLC_Opt_AlgebraicSimplify
	/// @param   {String} _name : The variable
	/// @returns {String} Double, String or Unknown
	#endregion
	static __variableType = function(_name) {
		static __types = undefined;
		if (__types == undefined) {
			__types = {};
			var _list = __GmlcDataSpec().variables;
			var _i = 0; repeat (array_length(_list)) {
				var _entry = _list[_i];
				if (_entry.get) {
					if (_entry.type == "Real") __types[$ _entry.name] = "Double";
					else if (_entry.type == "String") __types[$ _entry.name] = "String";
				}
			_i++}
		}
		return __types[$ _name] ?? "Unknown";
	};

	#region jsDoc
	/// @func    __isNumber(_node)
	/// @desc    Whether an expression is proven a double or an int64.
	/// @self    GMLC_Opt_AlgebraicSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __isNumber = function(_node) {
		var _type = __type(_node);
		return (_type == "Double") || (_type == "Int64");
	};

	#region jsDoc
	/// @func    __number(_node)
	/// @desc    The value of a number literal, or of a negated one; undefined for anything else and for a negated
	///          zero.
	/// @self    GMLC_Opt_AlgebraicSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Real|Undefined}
	#endregion
	static __number = function(_node) {
		var _negative = false;
		if (_node.kind == __GMLC_NodeKind_Unary) && (_node.op == "-") {
			_negative = true;
			_node = _node.argument;
		}
		if (_node.kind != __GMLC_NodeKind_Literal) || ((_node.ty != "real") && (_node.ty != "int64")) return undefined;
		var _value = _node.value;
		if (!is_numeric(_value)) return undefined;
		if (_negative) {
			if (_value == 0) return undefined;
			return -_value;
		}
		return _value;
	};

	#region jsDoc
	/// @func    __isWhole(_node)
	/// @desc    Whether an expression is a whole-number literal that fits 32 bits, which acts as an int64 next to one.
	/// @self    GMLC_Opt_AlgebraicSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __isWhole = function(_node) {
		if (_node.kind != __GMLC_NodeKind_Literal) || (_node.ty != "real") return false;
		var _value = _node.value;
		return is_numeric(_value) && (_value == floor(_value)) && (abs(_value) < 2147483648);
	};

	#region jsDoc
	/// @func    __isEmptyString(_node)
	/// @desc    Whether an expression is the literal `""`.
	/// @self    GMLC_Opt_AlgebraicSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __isEmptyString = function(_node) {
		return (_node.kind == __GMLC_NodeKind_Literal) && (_node.ty == "string") && (_node.value == "");
	};

	#endregion
}
