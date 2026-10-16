#region jsDoc
/// @func    GMLC_Ext_Const()
/// @desc    `const NAME = value`: a local constant. A literal value replaces every read and the declaration goes;
///          any other value stays the `var` it was parsed as.
/// @returns {Struct.GMLC_Ext_Const}
#endregion
function GMLC_Ext_Const() : GMLC_Extension("const") constructor {
	#region Config
	static statementWords = ["const"];
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    parseStatement(_parser)
	/// @desc    `const NAME = value`, parsed as a `var` declaration the rewrite then treats as a constant. `const` not
	///          followed by a name is an ordinary name.
	/// @self    GMLC_Ext_Const
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser : The parser, on `const`
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static parseStatement = function(_parser) {
		var _next = _parser.peekToken();
		if (_next == undefined) || (_next.type != __GMLC_TokenType_Identifier) return undefined;
		var _first = _parser.current_token;
		_parser.nextToken();
		var _declFirst = _parser.current_token;
		var _target = _parser.__parseName("a constant name");
		if (!_parser.isOperator("=")) _parser.__fail("GMLC1032", _target.span, [_target.name]);
		_parser.nextToken();
		var _init = _parser.parseExpression();
		var _decl = _parser.finish(new ASTVarDecl(undefined, _target, _init), _declFirst);
		var _node = _parser.finish(new ASTVarDeclList(undefined, [_decl]), _first);
		_node.__extension = name;
		_parser.extension_state[$ name].used = true;
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
		if (_state[$ "used"] == undefined) return;
		__function(_script, _parser, undefined);
	};
	#endregion
	
	#region Private
	#region jsDoc
	/// @func    __function(_function, _parser, _outer)
	/// @desc    Replaces the constants of one function (or the file's body), then those of the functions inside it. A
	///          closure also sees the outer function's constants its own names do not hide.
	/// @self    GMLC_Ext_Const
	/// @param   {Struct.ASTNode}           _function : The function, or the Script
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser   : The parser
	/// @param   {Struct}                   [_outer]  : The outer constants, for a closure
	#endregion
	static __function = function(_function, _parser, _outer) {
		var _scope = { constants: {}, others: {}, parser: _parser };
		if (_outer != undefined) {
			var _own = __gmlc_ext_locals(_function);
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
		if (_function.kind == __GMLC_NodeKind_Script) {
			var _e = 0; repeat (array_length(_function.enums)) {
				var _members = _function.enums[_e].members;
				var _m = 0; repeat (array_length(_members)) {
					if (_members[_m].init != undefined) __replace(_members[_m].init, _members[_m], "init", undefined, _scope);
				_m++}
			_e++}
		}
	};
	
	#region jsDoc
	/// @func    __collect(_node, _scope)
	/// @desc    Records the constants and the other locals a function's body declares, nested functions left out.
	///          A name declared both ways gets GMLC2012.
	/// @self    GMLC_Ext_Const
	/// @param   {Struct.ASTNode} _node  : The node
	/// @param   {Struct}         _scope : The function's constants and other names
	#endregion
	static __collect = function(_node, _scope) {
		if (__gmlc_ext_is_function(_node)) return;
		if (_node.kind == __GMLC_NodeKind_VarDeclList) {
			var _isConst = (_node[$ "__extension"] == name);
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
	
	#region jsDoc
	/// @func    __replace(_node, _parent, _field, _index, _scope)
	/// @desc    Puts literal constants in place of their reads under a node, drops the declarations of literal
	///          constants and reports writes to constants; a function inside gets its own scope.
	/// @self    GMLC_Ext_Const
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct.ASTNode} _parent : Its parent
	/// @param   {String}         _field  : The parent's field
	/// @param   {Real}           _index  : The index in that field, undefined for a single node
	/// @param   {Struct}         _scope  : The function's constants and other names
	#endregion
	static __replace = function(_node, _parent, _field, _index, _scope) {
		if (__gmlc_ext_is_function(_node)) {
			__function(_node, _scope.parser, (_node[$ "__extension"] == "closure") ? _scope.constants : undefined);
			return;
		}
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier: {
				if (!struct_exists(_scope.constants, _node.name)) return;
				var _literal = _scope.constants[$ _node.name];
				if (_literal == undefined) return;
				// `{N}` would now have no name to read: write the key out
				if (_parent.kind == __GMLC_NodeKind_StructEntry) _parent.shorthand = false;
				__gmlc_ext_set_child(_parent, _field, _index, __gmlc_ext_copy_literal(_literal, _node.span));
			return;}
			case __GMLC_NodeKind_Assign:
			case __GMLC_NodeKind_Update: {
				var _target = (_node.kind == __GMLC_NodeKind_Assign) ? _node.target : _node[$ "argument"];
				if (_target.kind == __GMLC_NodeKind_Identifier) && struct_exists(_scope.constants, _target.name) {
					_scope.parser.__report("GMLC2012", _target.span, [_target.name]);
				}
			break;}
			case __GMLC_NodeKind_VarDeclList: {
				// a constant's own name is a declaration, not a read
				if (_node[$ "__extension"] == name) {
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
				if (__gmlc_ext_is_statement_list(_node, _key)) {
					var _kept = [];
					var _s = 0; repeat (array_length(_value)) {
						if (_value[_s][$ "__extension"] != name) || !__isLiteral(_value[_s].declarations[0].init) array_push(_kept, _value[_s]);
					_s++}
					_value = _kept;
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
	
	#region jsDoc
	/// @func    __isLiteral(_node)
	/// @desc    Whether a value is a literal other than `undefined`, or a signed number literal.
	/// @self    GMLC_Ext_Const
	/// @param   {Struct.ASTNode} _node : The value, undefined for none
	/// @returns {Bool}
	#endregion
	static __isLiteral = function(_node) {
		if (_node == undefined) return false;
		if (_node.kind == __GMLC_NodeKind_Unary) && ((_node.op == "-") || (_node.op == "+")) {
			_node = _node[$ "argument"];
			return (_node.kind == __GMLC_NodeKind_Literal) && ((_node.ty == "real") || (_node.ty == "int64"));
		}
		return (_node.kind == __GMLC_NodeKind_Literal) && (_node.ty != "undefined");
	};
	#endregion
}
