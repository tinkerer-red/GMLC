#region jsDoc
/// @func    GMLC_Ext_NullishChaining()
/// @desc    `a?.b?.c`: a struct read that stops at undefined or a missing key; other values read as `struct_get`
///          reads them.
/// @returns {Struct.GMLC_Ext_NullishChaining}
#endregion
function GMLC_Ext_NullishChaining() : GMLC_Extension("nullish-chaining") constructor {
	#region Config
	static postfixOperators = ["?"];
	static functions = { is_undefined: is_undefined, struct_get: struct_get, static_get: static_get, __gmlc_nullish_get: __gmlc_nullish_get };
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    parsePostfix(_parser, _expression, _first)
	/// @desc    At a `?` directly followed by `.`: reads every `?.name` that follows and returns the chain as plain GML.
	///          Any other `?` (a conditional) is left to the parser.
	/// @self    GMLC_Ext_NullishChaining
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser     : The parser, on the `?`
	/// @param   {Struct.ASTNode}           _expression : The operand before it
	/// @param   {Struct}                   _first      : The operand's first token
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static parsePostfix = function(_parser, _expression, _first) {
		if (!__startsHop(_parser)) return undefined;
		var _keys = [];
		while (__startsHop(_parser)) {
			_parser.nextToken();
			_parser.nextToken();
			array_push(_keys, _parser.__parseMemberName());
		}
		var _node = _parser.finish(new ASTEmpty(), _first);
		var _span = _node.span;
		var _result;
		if (array_get_index(_keys, "toString") >= 0) {
			var _args = [_expression];
			var _k = 0; repeat (array_length(_keys)) {
				array_push(_args, __gmlc_ext_string(_keys[_k], _span));
			_k++}
			_result = __gmlc_ext_call(name, "__gmlc_nullish_get", _args, _span);
		}
		else if (__isPlainBase(_expression)) {
			var _test = __gmlc_ext_call(name, "is_undefined", [_expression], _span);
			var _read = __hops(__get(__copy(_expression), _keys[0], _span), _keys, 1, _span);
			_result = new ASTConditional(_span, _test, __gmlc_ext_undefined(_span), _read);
		}
		else {
			_result = __hops(_expression, _keys, 0, _span);
		}
		_result.span = _span;
		return _result;
	};
	#endregion
	
	#region Private
	#region jsDoc
	/// @func    __startsHop(_parser)
	/// @desc    Whether the parser is on a `?` with a `.` right after it; `?.5` is a `?` and a number, so a
	///          conditional.
	/// @self    GMLC_Ext_NullishChaining
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser : The parser
	/// @returns {Bool}
	#endregion
	static __startsHop = function(_parser) {
		if (!_parser.isOperator("?")) return false;
		var _dot = _parser.peekToken();
		return (_dot != undefined) && (_dot.type == __GMLC_TokenType_Punctuation) && (_dot.value == ".")
			&& (_dot.start == _parser.current_token[$ "end"]);
	};
	
	#region jsDoc
	/// @func    __isPlainBase(_node)
	/// @desc    Whether a base may be read twice: a name, or names joined by dots.
	/// @self    GMLC_Ext_NullishChaining
	/// @param   {Struct.ASTNode} _node : The base
	/// @returns {Bool}
	#endregion
	static __isPlainBase = function(_node) {
		while (_node.kind == __GMLC_NodeKind_Index) && (_node.accessor == "Dot") {
			_node = _node.object;
		}
		return (_node.kind == __GMLC_NodeKind_Identifier);
	};
	
	#region jsDoc
	/// @func    __hops(_value, _keys, _from, _span)
	/// @desc    `struct_get(v ?? static_get(global), "k")` per key: static_get(global) has no keys but `toString`, so a
	///          broken chain ends undefined (a key `toString` goes through __gmlc_nullish_get instead).
	/// @self    GMLC_Ext_NullishChaining
	/// @param   {Struct.ASTNode}   _value : The base
	/// @param   {Array<String>}   _keys  : The keys
	/// @param   {Real}            _from  : The first key to read
	/// @param   {Struct.GMLC_Span} _span  : The span
	/// @returns {Struct.ASTNode}
	#endregion
	static __hops = function(_value, _keys, _from, _span) {
		var _k = _from; repeat (array_length(_keys) - _from) {
			var _empty = __gmlc_ext_call(name, "static_get", [new ASTIdentifier(_span, "global")], _span);
			_value = __get(new ASTNullish(_span, _value, _empty), _keys[_k], _span);
		_k++}
		return _value;
	};
	
	#region jsDoc
	/// @func    __get(_value, _key, _span)
	/// @desc    `struct_get(_value, "_key")`.
	/// @self    GMLC_Ext_NullishChaining
	/// @param   {Struct.ASTNode}   _value : The struct
	/// @param   {String}           _key   : The key
	/// @param   {Struct.GMLC_Span} _span  : The span
	/// @returns {Struct.ASTCall}
	#endregion
	static __get = function(_value, _key, _span) {
		return __gmlc_ext_call(name, "struct_get", [_value, __gmlc_ext_string(_key, _span)], _span);
	};
	
	#region jsDoc
	/// @func    __copy(_node)
	/// @desc    A copy of a plain base (names joined by dots), so the base can be read twice.
	/// @self    GMLC_Ext_NullishChaining
	/// @param   {Struct.ASTNode} _node : The base
	/// @returns {Struct.ASTNode}
	#endregion
	static __copy = function(_node) {
		if (_node.kind == __GMLC_NodeKind_Identifier) return new ASTIdentifier(_node.span, _node.name, _node.origin);
		return new ASTIndex(_node.span, "Dot", __copy(_node.object), [], _node.member, _node.origin);
	};
	#endregion
}

#region jsDoc
/// @func    __gmlc_nullish_get(_value, ...keys)
/// @desc    The value read through each key in turn, undefined as soon as a value on the way is not a struct (a missing
///          key reads as undefined). A `?.` chain with a key `toString` comes here.
/// @param   {Any}    _value : The base
/// @param   {String} keys   : The keys, in order
/// @returns {Any}
#endregion
function __gmlc_nullish_get(_value) {
	var _i = 1; repeat (argument_count - 1) {
		if (!is_struct(_value)) return undefined;
		_value = _value[$ argument[_i]];
	_i++}
	return _value;
}
