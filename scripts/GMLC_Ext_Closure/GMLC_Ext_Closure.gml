#region Extension: closure
// `closure(function(...) { ... })`: the function keeps copies of the enclosing function's locals its body names and
// runs with the `self` and `other` it was made with; the plain GML is the method of __GMLC_ExtWrapClosure.
// Constructors cannot be closures, nor can closures be made in a parameter default or parent call (GMLC1031).
// `method` and `method_get_self` go through __gmlc_closure_method*, so a rebound closure keeps its copies.

#region jsDoc
/// @func    GMLC_Ext_Closure()
/// @desc    The `closure` extension.
/// @returns {Struct.GMLC_Ext_Closure}
#endregion
function GMLC_Ext_Closure() : GMLC_Extension("closure") constructor {
	static primaryWords = ["closure"];
	static functions = { method: __gmlc_method, __gmlc_closure_method: __gmlc_closure_method, __gmlc_closure_method_get_self: __gmlc_closure_method_get_self };
	
	#region jsDoc
	/// @func    parsePrimary(_parser)
	/// @desc    `closure(<function expression>)`: the function, recorded for the rewrite. `closure` not followed by `(`
	///          is an ordinary name.
	/// @self    GMLC_Ext_Closure
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser : The parser, on `closure`
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static parsePrimary = function(_parser) {
		var _next = _parser.peek();
		if (_next == undefined) || (_next.value != "(") return undefined;
		_parser.advance(); // closure
		var _open = _parser.currentToken;
		_parser.advance(); // (
		var _function = _parser.parseExpression();
		_parser.expect(__GMLC_TokenType_Punctuation, ")", _open);
		if (_function.kind != __GMLC_NodeKind_FunctionExpr) _parser.__fail("GMLC1031", _function.span);
		if (_function.is_constructor) _parser.__fail("GMLC1031", _function.span, undefined, "GMLC1031.constructor");
		var _state = _parser.extensionState[$ name];
		if (!struct_exists(_state, "functions")) _state.functions = [];
		array_push(_state.functions, _function);
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
		// a closure from any file may be given another `self` here
		__GMLC_ExtRouteMethods(name, _script);
		var _functions = _state[$ "functions"];
		if (_functions == undefined) return;
		var _walk = {
			parser: _parser, functions: _functions, scopes: [__GMLC_ExtLocals(_script)], list: undefined, statement: undefined,
			preludes: [], inHead: false,
		};
		__visit(_script, undefined, undefined, undefined, _walk);
		// the reads of `self` and `other` go just before the statement that makes each closure
		var _i = 0; repeat (array_length(_walk.preludes)) {
			var _p = _walk.preludes[_i];
			array_insert(_p.list, array_get_index(_p.list, _p.statement), _p.node);
		_i++}
	};
	
	static __visit = function(_node, _parent, _field, _index, _walk) {
		var _isFunction = __GMLC_ExtIsFunction(_node);
		if (_isFunction) && array_contains(_walk.functions, _node) && _walk.inHead {
			// a default or a parent call runs in the called function, where no statement can take the prelude
			_walk.parser.__report("GMLC1031", _node.span, undefined, "GMLC1031.head");
		}
		else if (_isFunction) && array_contains(_walk.functions, _node) {
			// the names its body uses that are locals of the function around it
			var _own = __GMLC_ExtLocals(_node);
			var _used = __namesUsed(_node, _walk.functions);
			var _around = _walk.scopes[array_length(_walk.scopes) - 1];
			var _captures = [];
			var _u = 0; repeat (array_length(_used)) {
				var _name = _used[_u];
				if (!struct_exists(_own, _name)) && struct_exists(_around, _name) array_push(_captures, _name);
			_u++}
			var _wrapped = __GMLC_ExtWrapClosure(name, _node, _captures, _walk.parser.__extensionId++);
			if (_index != undefined) {
				_parent[$ _field][_index] = _wrapped.call;
			}
			else {
				_parent[$ _field] = _wrapped.call;
			}
			array_push(_walk.preludes, { list: _walk.list, statement: _walk.statement, node: _wrapped.prelude });
		}
		var _inHead = _walk.inHead;
		if (_isFunction) array_push(_walk.scopes, __GMLC_ExtLocals(_node));
		
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _key = _fields[_f];
			var _value = _node[$ _key];
			// a function's defaults and parent call are its head; its body is not
			if (_isFunction) _walk.inHead = (_key != "body");
			if (is_array(_value)) {
				var _isList = __GMLC_ExtIsStatementList(_node, _key);
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
		
		_walk.inHead = _inHead;
		if (_isFunction) array_pop(_walk.scopes);
	};
	
	// the names a closure's body uses, with those the closures inside it use and do not declare themselves
	static __namesUsed = function(_function, _closures) {
		var _seen = {};
		var _out = [];
		__collectNames(_function.body, _closures, _seen, _out);
		return _out;
	};
	static __collectNames = function(_node, _closures, _seen, _out) {
		if (_node.kind == __GMLC_NodeKind_Identifier) {
			if (!struct_exists(_seen, _node.name)) {
				_seen[$ _node.name] = true;
				array_push(_out, _node.name);
			}
			return;
		}
		if (__GMLC_ExtIsFunction(_node)) {
			if (!array_contains(_closures, _node)) return;
			var _own = __GMLC_ExtLocals(_node);
			var _inner = __namesUsed(_node, _closures);
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
			__collectNames(_children[_c], _closures, _seen, _out);
		_c++}
	};
}
#endregion
