#region jsDoc
/// @func    GMLC_Opt_ConstantFold()
/// @desc    `constant-fold`: evaluates the constant expressions of the code while compiling: `2 + 2` becomes `4`,
///          `string_concat("a", "b")` becomes `"ab"`, `true || x` becomes `true` when `x` does nothing. A fold whose
///          computation throws leaves the expression as written and reports the failure. The optimizer's sweep calls
///          `sweep` on each node, inner ones first.
/// @returns {Struct.GMLC_Opt_ConstantFold}
#endregion
function GMLC_Opt_ConstantFold() : GMLC_OptimizerPass("constant-fold") constructor {
	#region Sweep
	#region jsDoc
	/// @func    sweep(_node_data, _o)
	/// @desc    Folds the constant expression a node is. Returns the node to put in its place, the one it was given when
	///          nothing folds.
	/// @self    GMLC_Opt_ConstantFold
	/// @param   {Struct}                      _node_data : {node, parent, key, index}
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _o         : The optimizer
	/// @returns {Struct.ASTNode}
	#endregion
	static sweep = function(_node_data, _o) {
		var _node   = _node_data.node;
		var _parent = _node_data.parent;
		var _key    = _node_data.key;
		var _index  = _node_data.index;
	    
		
		switch (_node.kind) {
			case __GMLC_NodeKind_Binary:
			case __GMLC_NodeKind_Logical:{
				var _folded = __foldOperator(_node, _o);
				if (_folded != undefined) {
					return _folded;
				}
				
				if (_node.kind == __GMLC_NodeKind_Logical)
				&& ((_node.op == "&&") || (_node.op == "||"))
				{
					var _left = _o.__constantValue(_node.left);
					if (_left[0]) && (is_numeric(_left[1])) {
						var _truthy = (_left[1]) ? true : false;
						if (_truthy == (_node.op == "||"))
						&& (!_o.__keepsCode(_node.right))
						&& (_o.__keepsValue(_node_data))
						{
							return _o.__literal(_truthy, _node.span);
						}
					}
				}
			break;}
			case __GMLC_NodeKind_Nullish:{
				var _left = _o.__constantValue(_node.left);
				if (_left[0]) {
					if (_left[1] == undefined) {
						var _right = _o.__constantValue(_node.right);
						if ((!_right[0]) || (_o.__keepsValue(_node_data))) && (!_o.__selfIntoStructEntry(_node_data, _node.right)) {
							return _node.right;
						}
					}
					else if (!_o.__keepsCode(_node.right)) && (_o.__keepsValue(_node_data)) && (!_o.__selfIntoStructEntry(_node_data, _node.left)) {
						return _node.left;
					}
				}
			break;}
			case __GMLC_NodeKind_Unary:{
				if (_node.op == "+") {
					// GameMaker's compiler compiles `+x` as `x`
					var _argument = _o.__constantValue(_node[$ "argument"]);
					if (_argument[0]) && (_o.__keepsValue(_node_data)) {
						return _node[$ "argument"];
					}
				}
				else {
					var _folded = __foldOperator(_node, _o);
					if (_folded != undefined) {
						return _folded;
					}
				}
			break;}
			case __GMLC_NodeKind_Conditional:{
				return _o.__foldConditional(_node_data);
			break;}
			case __GMLC_NodeKind_Call:{
				var _callee = _o.__calleeFunction(_node);
				if (_callee != undefined) {
					switch (_callee) {
						case choose:{
							if (array_length(_node.args) == 1) {
								var _argument = _o.__constantValue(_node.args[0]);
								if (!_argument[0]) || (_o.__keepsValue(_node_data)) {
									return _node.args[0];
								}
							}
							
						break;}
						case sqrt:{
							/// ==================================================
							/// NOTE:
							/// This is the only math operation that is affected by `math_set_epsilon`
							/// avoid optimizing this at compile time
							/// ==================================================
							return _node
						break;}
						case string:{
							//Remove these if the request for change has been approved
							// This exists because of an oddity in the language
							/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8088
							if (array_length(_node.args) < 1) {
								/// Re add this if the oddity gets fixed
								//throw_gmlc_error($"Argument count for string is incorrect!\nArgument Count : {array_length(_node.args)}\nline ({__line(_node)})")
								
								//this is also an odd variable as its different depending on the situation
								/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8090
								return _o.__literal("", _node.span);
							}
							if (_o.__argumentsAreLiteral(_node.args)) {
								return _o.__build_literal_from_function_call_constant_folding(string, _node_data);
							}
							else if (_node.args[0].kind == __GMLC_NodeKind_Literal) {
								var _arr = _node.args;
								var _exec_arr = [_arr[0].value]; //the execution array
								var _new_arr = []; // the new arg array
								var _holder_index = 0;
								var _changed = false;
							
								var _i=1; repeat(array_length(_arr)-1) {
									var _sub_node = _arr[_i]
									if (_sub_node.kind == __GMLC_NodeKind_Literal) {
										_changed = true;
										array_push(_exec_arr, _sub_node.value);
									}
									else {
										array_push(_new_arr, _sub_node);
										array_push(_exec_arr, $"\{{_holder_index}\}");
										_holder_index++
									}
								_i+=1;}//end repeat loop
							
								if (_changed) {
									array_insert(_new_arr, 0, _o.__literal(script_execute_ext(string, _exec_arr), _node.span))
									return new ASTCall(_node.span, _node.callee, _new_arr);
								}
							}
						break;}
						case string_concat:{
							if (array_length(_node.args) < 1) {
								return _node; // a wrong argument count is the resolver's error
							}
						
							if (_o.__argumentsAreLiteral(_node.args)) {
								return _o.__build_literal_from_function_call_constant_folding(string_concat, _node_data);
							}
							else {
								var _arr = _node.args;
								var _changed = false;
						
								var _i=0; repeat(array_length(_arr)-1) {
									if (_arr[_i].kind == __GMLC_NodeKind_Literal)
									&& (_arr[_i+1].kind == __GMLC_NodeKind_Literal) {
										_changed = true;
										
										var _value = string_concat(_arr[_i].value, _arr[_i+1].value);
										var _struct = _o.__literal(_value, _arr[_i].span)
										
										array_delete(_arr, _i, 2)
										array_insert(_arr, _i, _struct);
										continue;
									}
								_i+=1;}//end repeat loop
							
								if (_changed) {
									return new ASTCall(_node.span, _node.callee, _arr);
								}
							}
						
						break;}
						case string_join:{
							if (array_length(_node.args) < 1) {
								return _node;
							}
						
							if (_o.__argumentsAreLiteral(_node.args)) {
								return _o.__build_literal_from_function_call_constant_folding(string_join, _node_data);
							}
							else if (_node.args[0].kind == __GMLC_NodeKind_Literal) { // delimiter is literal
								var _arr = _node.args;
								var _changed = false;
								
								var _i=1; repeat(array_length(_arr)-2) {
									
									if (_arr[_i].kind == __GMLC_NodeKind_Literal)
									&& (_arr[_i+1].kind == __GMLC_NodeKind_Literal) {
										_changed = true;
										
										var _value = string_join(_arr[0].value, _arr[_i].value, _arr[_i+1].value);
										var _struct = _o.__literal(_value, _arr[_i].span);
										
										array_delete(_arr, _i, 2)
										array_insert(_arr, _i, _struct);
										continue;
									}
									
								_i+=1;}//end repeat loop
							
								if (_changed) {
									return new ASTCall(_node.span, _node.callee, _arr);
								}
							}
						
						break;}
						case chr:
						case ansi_char:{
							// a character code that is not a whole number the function can make is an error: GameMaker's
							// compiler rounds `chr(65.5)` to "B" where its runtime cuts it to "A"
							if (array_length(_node.args) != 1) return _node;
							var _code = _o.__constantValue(_node.args[0]);
							if (!_code[0]) || (!is_numeric(_code[1])) break;
							var _most = (_callee == chr) ? 0x10FFFF : 255;
							if (!__gmlc_is_whole(_code[1])) || (_code[1] < 0) || (_code[1] > _most) {
								_o.__alwaysFails(_node, "GMLC4103", [_node.callee.name, string(_most), is_real(_code[1]) ? __gmlc_real_text(_code[1]) : string(_code[1])]);
								return _node;
							}
							return _o.__build_literal_from_function_call_constant_folding(_callee, _node_data);
						break;}
						case string_join_ext:{
							// GameMaker gives "" for fewer than two arguments
							/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8088
							if (array_length(_node.args) < 2) {
								return _o.__literal("", _node.span)
							}
							if (array_length(_node.args) > 4) {
								return _node;
							}
							return _o.__build_literal_from_function_call_constant_folding(string_join_ext, _node_data);
						break;}
						default:{
							var _arity = _o.env.foldableArity(_node.callee.name);
							if (_arity == undefined) break;
							var _count = array_length(_node.args);
							if (_count < _arity[0]) || ((_arity[1] >= 0) && (_count > _arity[1])) {
								return _node;
							}
							return _o.__build_literal_from_function_call_constant_folding(_callee, _node_data);
						break;}
					}
					//end switch
				}
			break;}
			// Add more cases as needed for different _node types
		}
		
		return _node;
		
	};
	#endregion

	#region Helpers
	#region jsDoc
	/// @func    __foldOperator(_node, _o)
	/// @desc    Folds an operator expression whose operands are known: its literal, or undefined.
	/// @self    GMLC_Opt_ConstantFold
	/// @param   {Struct.ASTNode}              _node : A Binary or Logical node
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _o    : The optimizer
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __foldOperator = function(_node, _o) {
		var _constant = __GMLCconstantValue(_o, _node);
		if (!_constant[0]) {
			// constant operands that fail: reported where the operator is, not again for the operators around it
			if (array_length(_constant) > 2) && (_constant[2] != undefined) && (_constant[3] == _node) _o.__alwaysFails(_node, _constant[4] ? "GMLC4101" : "GMLC4102", [_constant[2]]);
			return undefined;
		}
		var _value = _constant[1];
		// `true || spr_x`: the operand the left decides is dropped, and with it the asset reference
		if (_o.__referencesAsset(_node)) return _node;

		// an enum member's own value is an int64 in GameMaker whatever its expression: it keeps the run time result
		if (!_o.__enum_values) {
			if (__sourceConstant(_node.span, _o)) {
				var _compiled = __compileTime(_node, _o);
				if (_compiled != undefined) _value = _compiled;
			}
			_value = __sourceNumber(_node, _value, _o);
		}
		return _o.__literal(_value, _node.span) ?? _node;
	};

	#region jsDoc
	/// @func    __compileTime(_node, _o)
	/// @desc    The value GameMaker's compiler gives arithmetic of enum members written in the source, for the GML source
	///          outputs, or undefined where the run time result stands on the VM and YYC: an enum
	///          member is a whole number; whole numbers with each other stay whole (an int64 at run time; `/` drops the
	///          fraction too), `+`, `-` and `*` with a real give a real while the result fits 32 bits and a whole number
	///          past them, `/` with a real gives a real, and `-` and `!` of a whole number give one; a result of exactly
	///          -2^31 is a real on the VM and a whole number on YYC. An int64 written in the source, a string and anything
	///          without an enum member are left to the run time result.
	/// @self    GMLC_Opt_ConstantFold
	/// @param   {Struct.ASTNode}              _node : The folded node
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _o    : The optimizer
	/// @returns {Any}
	#endregion
	static __compileTime = function(_node, _o) {
		var _output = _o.outputName();
		if (_output != "gml-source-vm") && (_output != "gml-source-yyc") return undefined;
		var _c = __compileTimeValue(_node, _o);
		if (_c == undefined) || (!_c.e) return undefined;
		return _c.whole ? int64(_c.v) : _c.v;
	};

	#region jsDoc
	/// @func    __compileTimeValue(_node, _o)
	/// @desc    The compile time value of an expression (`__compileTime`) as {whole, v, e}, `e` whether an enum member is
	///          in it, or undefined.
	/// @self    GMLC_Opt_ConstantFold
	/// @param   {Struct.ASTNode}              _node : The node
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _o    : The optimizer
	/// @returns {Struct|Undefined}
	#endregion
	static __compileTimeValue = function(_node, _o) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: {
				if (_node.ty == "real") return { whole: false, v: _node.value, e: false };
				if (_node.ty == "bool") return { whole: false, v: _node.value ? 1 : 0, e: false };
				if (_node.ty == "int64") {
					// a whole number an earlier fold of enum members wrote (its source text names one, `NAME.MEMBER`); an
					// int64 written in the source, `int64(n)` or a number past 32 bits, stays one
					var _file = (_o.sources != undefined) && (_node.span.file < array_length(_o.sources.files)) ? _o.sources.files[_node.span.file] : undefined;
					if (_file == undefined) return undefined;
					var _end = _node.span[$ "end"];
					if (_end > string_byte_length(_file.source)) return undefined;
					if (!__namesEnumMember(__byteText(_file.source, _node.span.start, _end))) return undefined;
					var _w = real(_node.value);
					if (abs(_w) >= 9007199254740992) return undefined;
					return { whole: true, v: _w, e: true };
				}
				return undefined;
			}
			case __GMLC_NodeKind_Identifier: {
				// `true` and `false` as the built-in constants they resolve to
				if (_node.name == "true") return { whole: false, v: 1, e: false };
				if (_node.name == "false") return { whole: false, v: 0, e: false };
				return undefined;
			}
			case __GMLC_NodeKind_Index: {
				if (_node.object.kind != __GMLC_NodeKind_Identifier) || (!_o.env.isEnum(_node.object.name)) return undefined;
				var _member = _o.env.getEnum(_node.object.name).value[$ _node.member];
				if (!is_numeric(_member)) return undefined;
				var _m = real(_member);
				if (frac(_m) != 0) || (abs(_m) >= 9007199254740992) return undefined;
				return { whole: true, v: _m, e: true };
			}
			case __GMLC_NodeKind_Unary: {
				var _a = __compileTimeValue(_node.argument, _o);
				if (_a == undefined) return undefined;
				if (_node.op == "-") {
					if (_a.whole) && (abs(_a.v) >= 9007199254740992) return undefined;
					return { whole: _a.whole, v: -_a.v, e: _a.e };
				}
				if (_node.op == "!") && (_a.whole) return { whole: true, v: (_a.v < 1) ? 1 : 0, e: _a.e };
				if (_node.op == "~") && (!_a.whole) {
					if (frac(_a.v) != 0) || (abs(_a.v) >= 9007199254740992) return undefined;
					return __integerResult(real(~int64(_a.v)));
				}
				return undefined;
			}
			case __GMLC_NodeKind_Binary: {
				var _x = __compileTimeValue(_node.left, _o);
				if (_x == undefined) return undefined;
				var _y = __compileTimeValue(_node.right, _o);
				if (_y == undefined) return undefined;
				var _e = _x.e || _y.e;
				var _p = _x.v;
				var _q = _y.v;
				if (_x.whole) && (_y.whole) {
					var _r;
					switch (_node.op) {
						case "+": _r = _p + _q; break;
						case "-": _r = _p - _q; break;
						case "*": _r = _p * _q; break;
						case "/": case "div": if (_q == 0) return undefined; _r = _p div _q; break;
						case "mod": case "%": if (_q == 0) return undefined; _r = _p mod _q; break;
						case "&": _r = real(int64(_p) & int64(_q)); break;
						case "|": _r = real(int64(_p) | int64(_q)); break;
						case "^": _r = real(int64(_p) ^ int64(_q)); break;
						case "<<": if (_q < 0) || (_q >= 64) return undefined; _r = real(int64(_p) << int64(_q)); break;
						case ">>": if (_q < 0) || (_q >= 64) return undefined; _r = real(int64(_p) >> int64(_q)); break;
						default: return undefined;
					}
					// a double holds it exactly only below 2^53
					if (abs(_r) >= 9007199254740992) return undefined;
					return { whole: true, v: _r, e: _e };
				}
				// the integer operators of whole numbers written as numbers: a real while the result fits 32 bits
				if (!_x.whole) && (!_y.whole) {
					if (frac(_p) != 0) || (frac(_q) != 0) || (abs(_p) >= 9007199254740992) || (abs(_q) >= 9007199254740992) return undefined;
					var _r;
					switch (_node.op) {
						case "div": if (_q == 0) return undefined; _r = _p div _q; break;
						case "mod": case "%": if (_q == 0) return undefined; _r = _p mod _q; break;
						case "&": _r = real(int64(_p) & int64(_q)); break;
						case "|": _r = real(int64(_p) | int64(_q)); break;
						case "^": _r = real(int64(_p) ^ int64(_q)); break;
						case "<<": if (_q < 0) || (_q >= 64) return undefined; _r = real(int64(_p) << int64(_q)); break;
						case ">>": if (_q < 0) || (_q >= 64) return undefined; _r = real(int64(_p) >> int64(_q)); break;
						default: return undefined;
					}
					return __integerResult(_r);
				}
				switch (_node.op) {
					case "+": case "-": case "*": {
						var _r = (_node.op == "+") ? (_p + _q) : ((_node.op == "-") ? (_p - _q) : (_p * _q));
						if (is_infinity(_r)) || (is_nan(_r)) return undefined;
						// -2^31 is a real on the VM and an int64 on YYC
						if (_r == -2147483648) return { whole: (_o.outputName() != "gml-source-vm"), v: _r, e: _e };
						if (_r > -2147483648) && (_r <= 2147483647) return { whole: false, v: _r, e: _e };
						if (frac(_r) == 0) && (abs(_r) < 9007199254740992) return { whole: true, v: _r, e: _e };
						return undefined;
					}
					case "/": {
						if (_q == 0) return undefined;
						return { whole: false, v: _p / _q, e: _e };
					}
				}
				return undefined;
			}
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __integerResult(_r)
	/// @desc    What GameMaker's compiler makes of an integer operator's result on numbers, as {whole, v, e}: a real while
	///          it fits 32 bits, an int64 past them (`5 | 2` and `1 << 4` are reals, `1 << 40` an
	///          int64); -2^31 and anything a double cannot hold exactly are left to the run time result (undefined).
	/// @self    GMLC_Opt_ConstantFold
	/// @param   {Real} _r : The result
	/// @returns {Struct|Undefined}
	#endregion
	static __integerResult = function(_r) {
		if (_r == -2147483648) || (abs(_r) >= 9007199254740992) return undefined;
		if (_r > -2147483648) && (_r <= 2147483647) return { whole: false, v: _r, e: true };
		return { whole: true, v: _r, e: true };
	};

	#region jsDoc
	/// @func    __namesEnumMember(_text)
	/// @desc    Whether a source text holds `NAME.MEMBER` (a name, a dot, a name), not counting `int64`.
	/// @self    GMLC_Opt_ConstantFold
	/// @param   {String} _text : The text
	/// @returns {Bool}
	#endregion
	static __namesEnumMember = function(_text) {
		var _len = string_length(_text);
		var _i = 1;
		while (_i <= _len) {
			var _c = ord(string_char_at(_text, _i));
			if ((_c >= ord("a")) && (_c <= ord("z"))) || ((_c >= ord("A")) && (_c <= ord("Z"))) || (_c == ord("_")) {
				var _from = _i;
				while (_i <= _len) && (__wordByte(ord(string_char_at(_text, _i)))) _i++;
				if (string_copy(_text, _from, _i - _from) != "int64") && (_i + 1 <= _len) && (string_char_at(_text, _i) == ".") {
					var _n = ord(string_char_at(_text, _i + 1));
					if ((_n >= ord("a")) && (_n <= ord("z"))) || ((_n >= ord("A")) && (_n <= ord("Z"))) || (_n == ord("_")) return true;
				}
			}
			else if (_c >= ord("0")) && (_c <= ord("9")) {
				while (_i <= _len) && (__wordByte(ord(string_char_at(_text, _i))) || (string_char_at(_text, _i) == ".")) _i++;
			}
			else {
				_i++;
			}
		}
		return false;
	};

	#region jsDoc
	/// @func    __byteText(_text, _start, _end)
	/// @desc    The text between two byte offsets of a string (ASCII bytes kept, others as `?`).
	/// @self    GMLC_Opt_ConstantFold
	/// @param   {String} _text  : The string
	/// @param   {Real}   _start : The first byte
	/// @param   {Real}   _end   : The byte after the last
	/// @returns {String}
	#endregion
	static __byteText = function(_text, _start, _end) {
		var _out = "";
		var _i = _start; repeat (_end - _start) {
			var _c = string_byte_at(_text, _i + 1);
			_out += (_c < 128) ? chr(_c) : "?";
		_i++}
		return _out;
	};

	#region jsDoc
	/// @func    __fileEnum(_text, _name)
	/// @desc    Whether a file's text declares an enum of the name (`enum NAME {`).
	/// @self    GMLC_Opt_ConstantFold
	/// @param   {String} _text : The file's text
	/// @param   {String} _name : The name
	/// @returns {Bool}
	#endregion
	static __fileEnum = function(_text, _name) {
		var _len = string_length(_text);
		var _at = string_pos("enum", _text);
		while (_at > 0) {
			var _i = _at + 4;
			var _before = (_at > 1) ? string_char_at(_text, _at - 1) : " ";
			if (!__wordByte(ord(_before))) && (_i <= _len) && (ord(string_char_at(_text, _i)) <= 32) {
				while (_i <= _len) && (ord(string_char_at(_text, _i)) <= 32) _i++;
				var _from = _i;
				while (_i <= _len) && (__wordByte(ord(string_char_at(_text, _i)))) _i++;
				if (string_copy(_text, _from, _i - _from) == _name) return true;
			}
			_at = string_pos_ext("enum", _text, _at + 4);
		}
		return false;
	};

	#region jsDoc
	/// @func    __sourceNumber(_node, _value, _o)
	/// @desc    The value a fold gives where GameMaker's compiler works out the expression itself: `!`, `&&`, `||` and
	///          `^^` of constants written in the source give a number, 0 or 1, on the VM and YYC, and a comparison of
	///          them a number on YYC (a bool where GameMaker stores 0 is slower on YYC wherever it is later added to a
	///          number). Where an operand only became a constant here (a local's
	///          value put in), the run time result stays: a bool. The outputs of GMLC's own compiler keep the bool too.
	/// @self    GMLC_Opt_ConstantFold
	/// @param   {Struct.ASTNode}              _node  : The folded node
	/// @param   {Any}                         _value : Its value
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _o     : The optimizer
	/// @returns {Any}
	#endregion
	static __sourceNumber = function(_node, _value, _o) {
		if (!is_bool(_value)) return _value;
		var _kind = _node.kind;
		if (_kind != __GMLC_NodeKind_Unary) && (_kind != __GMLC_NodeKind_Logical) && (_kind != __GMLC_NodeKind_Binary) return _value;
		var _op = _node.op;
		var _output = _o.outputName();
		var _logic = (_op == "!") || (_op == "&&") || (_op == "||") || (_op == "^^");
		var _compare = (_op == "==") || (_op == "!=") || (_op == "<") || (_op == "<=") || (_op == ">") || (_op == ">=");
		if (!(_logic && ((_output == "gml-source-vm") || (_output == "gml-source-yyc")))) && (!(_compare && (_output == "gml-source-yyc"))) return _value;
		if (!__sourceConstant(_node.span, _o)) return _value;
		return _value ? 1 : 0;
	};

	#region jsDoc
	/// @func    __sourceConstant(_span, _o)
	/// @desc    Whether the source text of a span is only constants: number and string literals, `true`, `false`, the
	///          names of macros (the file's own and the environment's) and of enums with their members, operators and
	///          parentheses. A local's name in it means a value the optimizer put in.
	/// @self    GMLC_Opt_ConstantFold
	/// @param   {Struct.GMLC_Span}            _span : The span
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _o    : The optimizer
	/// @returns {Bool}
	#endregion
	static __sourceConstant = function(_span, _o) {
		if (_o.sources == undefined) || (_span.file >= array_length(_o.sources.files)) return false;
		var _file = _o.sources.files[_span.file];
		if (_file == undefined) return false;
		var _text = _file.source;
		var _end = _span[$ "end"];
		if (_end <= _span.start) || (_end > string_byte_length(_text)) return false;
		var _i = _span.start;
		while (_i < _end) {
			var _c = string_byte_at(_text, _i + 1);
			if (_c <= 32) || (_c == ord("(")) || (_c == ord(")")) || (_c == ord("!")) || (_c == ord("&")) || (_c == ord("|")) || (_c == ord("^"))
			|| (_c == ord("<")) || (_c == ord(">")) || (_c == ord("=")) || (_c == ord("+")) || (_c == ord("-")) || (_c == ord("*")) || (_c == ord("/"))
			|| (_c == ord("%")) || (_c == ord("~")) {
				_i++;
			}
			else if (_c == ord("\"")) {
				_i++;
				while (_i < _end) && (string_byte_at(_text, _i + 1) != ord("\"")) {
					_i += (string_byte_at(_text, _i + 1) == ord("\\")) ? 2 : 1;
				}
				_i++;
			}
			else if ((_c >= ord("0")) && (_c <= ord("9"))) || (_c == ord(".")) || (_c == ord("$")) {
				_i++;
				while (_i < _end) && (__wordByte(string_byte_at(_text, _i + 1)) || (string_byte_at(_text, _i + 1) == ord("."))) _i++;
			}
			else if (__wordByte(_c)) {
				var _from = _i;
				while (_i < _end) && (__wordByte(string_byte_at(_text, _i + 1))) _i++;
				var _name = "";
				var _k = _from; repeat (_i - _from) {
					_name += chr(string_byte_at(_text, _k + 1));
				_k++}
				if (_name != "true") && (_name != "false") && (_name != "and") && (_name != "or") && (_name != "xor") && (_name != "not")
				&& (_name != "div") && (_name != "mod") && (!_o.env.isMacro(_name)) && (!_o.env.isEnum(_name))
				&& (!__fileMacro(_text, _name)) && (!__fileEnum(_text, _name)) {
					return false;
				}
			}
			else {
				return false;
			}
		}
		return true;
	};

	#region jsDoc
	/// @func    __wordByte(_c)
	/// @desc    Whether a byte belongs to a name or a number: a letter, a digit or `_`.
	/// @self    GMLC_Opt_ConstantFold
	/// @param   {Real} _c : The byte
	/// @returns {Bool}
	#endregion
	static __wordByte = function(_c) {
		return ((_c >= ord("a")) && (_c <= ord("z"))) || ((_c >= ord("A")) && (_c <= ord("Z"))) || ((_c >= ord("0")) && (_c <= ord("9"))) || (_c == ord("_"));
	};

	#region jsDoc
	/// @func    __fileMacro(_text, _name)
	/// @desc    Whether a file's text defines a macro of the name (`#macro NAME`, or `#macro Config:NAME`).
	/// @self    GMLC_Opt_ConstantFold
	/// @param   {String} _text : The file's text
	/// @param   {String} _name : The name
	/// @returns {Bool}
	#endregion
	static __fileMacro = function(_text, _name) {
		var _at = string_pos("#macro", _text);
		while (_at > 0) {
			var _i = _at + 6;
			var _len = string_length(_text);
			while (_i <= _len) && ((string_char_at(_text, _i) == " ") || (string_char_at(_text, _i) == "\t")) _i++;
			var _from = _i;
			while (_i <= _len) && (__wordByte(ord(string_char_at(_text, _i))) || (string_char_at(_text, _i) == ":")) _i++;
			var _word = string_copy(_text, _from, _i - _from);
			var _parts = string_split(_word, ":");
			if (_parts[array_length(_parts) - 1] == _name) return true;
			_at = string_pos_ext("#macro", _text, _i);
		}
		return false;
	};

	#endregion
}
