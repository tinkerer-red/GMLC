#region Extension: const
// `const NAME = value`: a local constant of the enclosing function (or of the file's body), not seen by the functions
// inside it except a `closure`, which sees the locals around it. When the value is a number or string literal (a sign allowed), every read of the name in that function
// becomes the literal and the declaration goes; otherwise the declaration is the `var` it was parsed as. Assigning to
// the name, `++`/`--` on it, or declaring it again in the same function is GMLC2012.

#region jsDoc
/// @func    GMLC_Ext_Const()
/// @desc    The `const` extension.
/// @returns {Struct.GMLC_Ext_Const}
#endregion
function GMLC_Ext_Const() : GMLC_Extension("const") constructor {
	static statementWords = ["const"];
	
	#region jsDoc
	/// @func    parseStatement(_parser)
	/// @desc    `const NAME = value`, parsed as a `var` declaration the rewrite then treats as a constant. `const` not
	///          followed by a name is an ordinary name.
	/// @self    GMLC_Ext_Const
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser : The parser, on `const`
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static parseStatement = function(_parser) {
		var _next = _parser.peek();
		if (_next == undefined) || (_next.type != __GMLC_TokenType_Identifier) return undefined;
		var _first = _parser.currentToken;
		_parser.advance(); // const
		var _declFirst = _parser.currentToken;
		var _target = _parser.__parseName("a constant name");
		if (!_parser.isOperator("=")) _parser.__fail("GMLC1032", _target.span, [_target.name]);
		_parser.advance();
		var _init = _parser.parseExpression();
		var _decl = _parser.finish(new ASTVarDecl(undefined, _target, _init), _declFirst);
		var _node = _parser.finish(new ASTVarDeclList(undefined, [_decl]), _first);
		var _state = _parser.extensionState[$ name];
		if (!struct_exists(_state, "decls")) _state.decls = [];
		array_push(_state.decls, _node);
		return _node;
	};
	
	#region jsDoc
	/// @func    rewrite(_script, _parser, _state)
	/// @desc    Puts literal constants in place of their reads, function by function, and reports changes to constants.
	/// @self    GMLC_Ext_Const
	/// @param   {Struct.ASTScript}         _script : The parsed file
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser : The parser, for diagnostics
	/// @param   {Struct}                   _state  : What parseStatement recorded
	#endregion
	static rewrite = function(_script, _parser, _state) {
		var _decls = _state[$ "decls"];
		if (_decls == undefined) return;
		var _closures = _parser.extensionState[$ "closure"];
		_closures = (_closures != undefined) ? (_closures[$ "functions"] ?? []) : [];
		__function(_script, _parser, _decls, _closures, undefined);
	};
	
	// the constants of one function (or the file's body), then the functions inside it; a closure also has the
	// constants of the function around it that its own names do not hide
	static __function = function(_function, _parser, _decls, _closures, _outer) {
		var _scope = { constants: {}, others: {}, parser: _parser, decls: _decls, closures: _closures };
		if (_outer != undefined) {
			var _own = __GMLC_ExtLocals(_function);
			var _names = struct_get_names(_outer);
			var _n = 0; repeat (array_length(_names)) {
				if (!struct_exists(_own, _names[_n])) _scope.constants[$ _names[_n]] = _outer[$ _names[_n]];
			_n++}
		}
		var _params = _function[$ "params"] ?? [];
		var _p = 0; repeat (array_length(_params)) {
			_scope.others[$ _params[_p].target.name] = true;
		_p++}
		var _body = (_function.kind == __GMLC_NodeKind_Script) ? _function : _function.body;
		__collect(_body, _scope);
		__replace(_body, undefined, undefined, undefined, _scope);
		// the file's enum values read the constants of the file's body
		if (_function.kind == __GMLC_NodeKind_Script) {
			var _e = 0; repeat (array_length(_function.enums)) {
				var _members = _function.enums[_e].members;
				var _m = 0; repeat (array_length(_members)) {
					if (_members[_m].init != undefined) __replace(_members[_m].init, _members[_m], "init", undefined, _scope);
				_m++}
			_e++}
		}
	};
	
	// the constants of a function and its other declared names, the functions inside it left out
	static __collect = function(_node, _scope) {
		if (__GMLC_ExtIsFunction(_node)) return;
		if (_node.kind == __GMLC_NodeKind_VarDeclList) {
			var _isConst = array_contains(_scope.decls, _node);
			var _d = 0; repeat (array_length(_node.declarations)) {
				var _decl = _node.declarations[_d];
				var _name = _decl.target.name;
				if (_isConst) {
					if (struct_exists(_scope.constants, _name) || struct_exists(_scope.others, _name)) {
						_scope.parser.__report("GMLC2012", _decl.target.span, [_name]);
					}
					_scope.constants[$ _name] = __isLiteral(_decl.init) ? _decl.init : undefined;
				}
				else {
					if (struct_exists(_scope.constants, _name)) _scope.parser.__report("GMLC2012", _decl.target.span, [_name]);
					_scope.others[$ _name] = true;
				}
			_d++}
		}
		var _children = _node.children();
		var _c = 0; repeat (array_length(_children)) {
			__collect(_children[_c], _scope);
		_c++}
	};
	
	// reads of literal constants become the literal, literal declarations go, changes to a constant are reported
	static __replace = function(_node, _parent, _field, _index, _scope) {
		if (__GMLC_ExtIsFunction(_node)) {
			var _isClosure = array_contains(_scope.closures, _node);
			__function(_node, _scope.parser, _scope.decls, _scope.closures, _isClosure ? _scope.constants : undefined);
			return;
		}
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier: {
				if (!struct_exists(_scope.constants, _node.name)) return;
				var _literal = _scope.constants[$ _node.name];
				if (_literal == undefined) return;
				var _copy = __copyLiteral(_literal, _node.span);
				// `{N}` would now have no name to read: write the key out
				if (_parent.kind == __GMLC_NodeKind_StructEntry) _parent.shorthand = false;
				if (_index != undefined) {
					_parent[$ _field][_index] = _copy;
				}
				else {
					_parent[$ _field] = _copy;
				}
			return;}
			case __GMLC_NodeKind_Assign: {
				__checkChange(_node.target, _scope);
			break;}
			case __GMLC_NodeKind_Update: {
				__checkChange(_node[$ "argument"], _scope);
			break;}
			case __GMLC_NodeKind_VarDeclList: {
				// a constant's own name is a declaration, not a read
				if (array_contains(_scope.decls, _node)) {
					var _d = 0; repeat (array_length(_node.declarations)) {
						var _init = _node.declarations[_d].init;
						if (_init != undefined) __replace(_init, _node.declarations[_d], "init", undefined, _scope);
					_d++}
					return;
				}
			break;}
		}
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _key = _fields[_f];
			var _value = _node[$ _key];
			if (is_array(_value)) {
				if (__GMLC_ExtIsStatementList(_node, _key)) {
					_value = __dropLiteralDecls(_value, _scope);
					_node[$ _key] = _value;
				}
				var _c = 0; repeat (array_length(_value)) {
					if (_value[_c] != undefined) __replace(_value[_c], _node, _key, _c, _scope);
				_c++}
			}
			else if (_value != undefined) {
				__replace(_value, _node, _key, undefined, _scope);
			}
		_f++}
	};
	
	// a statement list without the declarations of literal constants
	static __dropLiteralDecls = function(_list, _scope) {
		var _out = [];
		var _i = 0; repeat (array_length(_list)) {
			var _s = _list[_i];
			if (!array_contains(_scope.decls, _s)) || !__isLiteral(_s.declarations[0].init) array_push(_out, _s);
		_i++}
		return _out;
	};
	
	static __checkChange = function(_target, _scope) {
		if (_target.kind == __GMLC_NodeKind_Identifier) && struct_exists(_scope.constants, _target.name) {
			_scope.parser.__report("GMLC2012", _target.span, [_target.name]);
		}
	};
	
	// a number or string literal, with a sign allowed before a number
	static __isLiteral = function(_node) {
		if (_node == undefined) return false;
		if (_node.kind == __GMLC_NodeKind_Unary) && ((_node.op == "-") || (_node.op == "+")) {
			_node = _node[$ "argument"];
			return (_node.kind == __GMLC_NodeKind_Literal) && ((_node.ty == "real") || (_node.ty == "int64"));
		}
		return (_node.kind == __GMLC_NodeKind_Literal) && (_node.ty != "undefined");
	};
	
	static __copyLiteral = function(_node, _span) {
		if (_node.kind == __GMLC_NodeKind_Unary) return new ASTUnary(_span, _node.op, __copyLiteral(_node[$ "argument"], _span));
		return new ASTLiteral(_span, _node.ty, _node.lexeme, _node.value);
	};
}
#endregion
