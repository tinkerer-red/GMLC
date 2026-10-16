#region jsDoc
/// @func    GMLC_Ext_Closure()
/// @desc    `closure(function(...) { ... })`: the function keeps copies of the enclosing function's locals its body
///          names and runs with the `self` and `other` it was made with.
/// @returns {Struct.GMLC_Ext_Closure}
#endregion
function GMLC_Ext_Closure() : GMLC_Extension("closure") constructor {
	#region Config
	static primaryWords = ["closure"];
	static functions = { method: __gmlc_method, __gmlc_closure_method: __gmlc_closure_method, __gmlc_closure_method_get_self: __gmlc_closure_method_get_self };
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    parsePrimary(_parser)
	/// @desc    `closure(<function expression>)`: the function, recorded for the rewrite. `closure` not followed by `(`
	///          is an ordinary name.
	/// @self    GMLC_Ext_Closure
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser : The parser, on `closure`
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static parsePrimary = function(_parser) {
		var _next = _parser.peekToken();
		if (_next == undefined) || (_next.value != "(") return undefined;
		_parser.nextToken();
		var _open = _parser.current_token;
		_parser.nextToken();
		var _function = _parser.parseExpression();
		_parser.expectToken(__GMLC_TokenType_Punctuation, ")", _open);
		if (_function.kind != __GMLC_NodeKind_FunctionExpr) _parser.__fail("GMLC1031", _function.span);
		if (_function.is_constructor) _parser.__fail("GMLC1031", _function.span, undefined, "GMLC1031.constructor");
		_function.__extension = name;
		_parser.extension_state[$ name].used = true;
		return _function;
	};
	
	#region jsDoc
	/// @func    rewrite(_script, _parser, _state)
	/// @desc    Turns every recorded function into its method, outermost first, so a closure inside a closure sees the
	///          copies the outer one made as its locals.
	/// @self    GMLC_Ext_Closure
	/// @param   {Struct.ASTScript}         _script : The parsed file
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser : The parser, for the numbering of names
	/// @param   {Struct}                   _state  : What parsePrimary recorded
	#endregion
	static rewrite = function(_script, _parser, _state) {
		// before the early return: a closure of another file may be given another `self` here
		__gmlc_ext_route_methods(name, _script);
		if (_state[$ "used"] == undefined) return;
		var _walk = { parser: _parser, scopes: [__gmlc_ext_locals(_script)], list: undefined, statement: undefined, preludes: [], in_head: false };
		__visit(_script, undefined, undefined, undefined, _walk);
		var _i = 0; repeat (array_length(_walk.preludes)) {
			var _p = _walk.preludes[_i];
			array_insert(_p.list, array_get_index(_p.list, _p.statement), _p.node);
		_i++}
	};
	#endregion
	
	#region Private
	#region jsDoc
	/// @func    __visit(_node, _parent, _field, _index, _walk)
	/// @desc    Wraps every recorded function under a node into its method, outermost first, and notes the
	///          statement its prelude goes before; one in a function's parameters or parent call gets GMLC1031.
	/// @self    GMLC_Ext_Closure
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct.ASTNode} _parent : Its parent
	/// @param   {String}         _field  : The parent's field
	/// @param   {Real}           _index  : The index in that field, undefined for a single node
	/// @param   {Struct}         _walk   : The walk
	#endregion
	static __visit = function(_node, _parent, _field, _index, _walk) {
		var _isFunction = __gmlc_ext_is_function(_node);
		var _isClosure = (_node[$ "__extension"] == name);
		if (_isClosure) && _walk.in_head {
			// a default or a parent call runs in the called function, where no statement can take the prelude
			_walk.parser.__report("GMLC1031", _node.span, undefined, "GMLC1031.head");
		}
		else if (_isClosure) {
			var _own = __gmlc_ext_locals(_node);
			var _used = __namesUsed(_node);
			var _around = _walk.scopes[array_length(_walk.scopes) - 1];
			var _captures = [];
			var _u = 0; repeat (array_length(_used)) {
				var _name = _used[_u];
				if (!struct_exists(_own, _name)) && struct_exists(_around, _name) array_push(_captures, _name);
			_u++}
			var _wrapped = __gmlc_ext_wrap_closure(name, _node, _captures, _walk.parser.__extension_id++);
			__gmlc_ext_set_child(_parent, _field, _index, _wrapped.call);
			array_push(_walk.preludes, { list: _walk.list, statement: _walk.statement, node: _wrapped.prelude });
		}
		var _inHead = _walk.in_head;
		if (_isFunction) array_push(_walk.scopes, __gmlc_ext_locals(_node));
		
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _key = _fields[_f];
			var _value = _node[$ _key];
			if (_isFunction) _walk.in_head = (_key != "body");
			if (is_array(_value)) {
				var _isList = __gmlc_ext_is_statement_list(_node, _key);
				var _list = _walk.list;
				var _statement = _walk.statement;
				var _c = 0; repeat (array_length(_value)) {
					if (_isList) {
						_walk.list = _value;
						_walk.statement = _value[_c];
					}
					if (_value[_c] != undefined) __visit(_value[_c], _node, _key, _c, _walk);
				_c++}
				_walk.list = _list;
				_walk.statement = _statement;
			}
			else if (_value != undefined) {
				__visit(_value, _node, _key, undefined, _walk);
			}
		_f++}
		
		_walk.in_head = _inHead;
		if (_isFunction) array_pop(_walk.scopes);
	};
	
	#region jsDoc
	/// @func    __namesUsed(_function)
	/// @desc    The names a closure's body uses, with those the closures inside it use and do not declare.
	/// @self    GMLC_Ext_Closure
	/// @param   {Struct.ASTNode} _function : The closure's function
	/// @returns {Array<String>}
	#endregion
	static __namesUsed = function(_function) {
		var _seen = {};
		var _out = [];
		__collectNames(_function.body, _seen, _out);
		return _out;
	};
	
	#region jsDoc
	/// @func    __collectNames(_node, _seen, _out)
	/// @desc    Adds each name read under a node to _out once; a closure inside adds the names it reads and does
	///          not declare, any other function nothing.
	/// @self    GMLC_Ext_Closure
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _seen : Name to true
	/// @param   {Array<String>}  _out  : The names
	#endregion
	static __collectNames = function(_node, _seen, _out) {
		if (_node.kind == __GMLC_NodeKind_Identifier) {
			if (!struct_exists(_seen, _node.name)) {
				_seen[$ _node.name] = true;
				array_push(_out, _node.name);
			}
			return;
		}
		if (__gmlc_ext_is_function(_node)) {
			if (_node[$ "__extension"] != name) return;
			var _own = __gmlc_ext_locals(_node);
			var _inner = __namesUsed(_node);
			var _i = 0; repeat (array_length(_inner)) {
				var _name = _inner[_i];
				if (!struct_exists(_own, _name)) && !struct_exists(_seen, _name) {
					_seen[$ _name] = true;
					array_push(_out, _name);
				}
			_i++}
			return;
		}
		var _children = _node.children();
		var _c = 0; repeat (array_length(_children)) {
			__collectNames(_children[_c], _seen, _out);
		_c++}
	};
	#endregion
}
