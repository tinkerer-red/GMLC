#region jsDoc
/// @func    GMLC_Ext_Let()
/// @desc    `let x = 1, y;`: block-scoped locals. A `let` that a function inside its block reads lives in a box
///          struct the function captures as `closure` does; it uses the `closure` extension's helpers, so that one
///          stays registered.
/// @returns {Struct.GMLC_Ext_Let}
#endregion
function GMLC_Ext_Let() : GMLC_Extension("let") constructor {
	#region Config
	static statementWords = ["let"];
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    parseStatement(_parser)
	/// @desc    `let a = 1, b`, parsed as a `var` declaration the rewrite then scopes to its block. `let` not followed
	///          by a name is an ordinary name.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser : The parser, on `let`
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static parseStatement = function(_parser) {
		var _next = _parser.peekToken();
		if (_next == undefined) || (_next.type != __GMLC_TokenType_Identifier) return undefined;
		var _first = _parser.current_token;
		_parser.nextToken();
		var _declarations = [];
		do {
			var _declFirst = _parser.current_token;
			var _target = _parser.__parseName("a variable name");
			var _init = undefined;
			if (_parser.isOperator("=")) {
				_parser.nextToken();
				_init = _parser.parseExpression();
			}
			array_push(_declarations, _parser.finish(new ASTVarDecl(undefined, _target, _init), _declFirst));
		}
		until (!_parser.optionalToken(__GMLC_TokenType_Punctuation, ",")
			|| (_parser.current_token == undefined) || (_parser.current_token.type != __GMLC_TokenType_Identifier));
		var _node = _parser.finish(new ASTVarDeclList(undefined, _declarations), _first);
		_node.__extension = name;
		_parser.extension_state[$ name].used = true;
		return _node;
	};
	
	#region jsDoc
	/// @func    rewrite(_script, _parser, _state)
	/// @desc    Scopes every `let` to its block: renames them, boxes those a function reads and wraps those functions.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct.ASTScript}         _script : The parsed file
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser : The parser, for diagnostics and the numbering of names
	/// @param   {Struct}                   _state  : What parseStatement recorded
	#endregion
	static rewrite = function(_script, _parser, _state) {
		// before the early return: a function a `let` of another file wrapped may be given another `self` here
		__gmlc_ext_route_methods(name, _script);
		if (_state[$ "used"] == undefined) return;
		var _walk = {
			parser: _parser, script: _script, scopes: [], functions: [], refs: [], lets: [], made: [],
			list: undefined, statement: undefined, in_head: false,
		};
		__enterFunction(_script, undefined, undefined, undefined, _walk);
		__scope(_script, _script.body, undefined, _walk, _script.enums);
		array_pop(_walk.functions);
		__box(_walk);
	};
	#endregion
	
	#region Private
	#region Names
	#region jsDoc
	/// @func    __enterFunction(_node, _parent, _field, _index, _walk)
	/// @desc    Starts the frame of a function: where it sits, the statement it is in and the names it declares
	///          itself.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct.ASTNode} _node   : The function, or the Script
	/// @param   {Struct.ASTNode} _parent : Its parent
	/// @param   {String}         _field  : The parent's field
	/// @param   {Real}           _index  : The index in that field, undefined for a single node
	/// @param   {Struct}         _walk   : The walk
	/// @returns {Struct}
	#endregion
	static __enterFunction = function(_node, _parent, _field, _index, _walk) {
		var _frame = {
			node: _node, parent: _parent, field: _field, index: _index,
			list: _walk.list, statement: _walk.statement, in_head: _walk.in_head,
			outer: (array_length(_walk.functions) > 0) ? _walk.functions[array_length(_walk.functions) - 1] : undefined,
			own: __gmlc_ext_locals(_node, true), boxes: [],
		};
		array_push(_walk.functions, _frame);
		array_push(_walk.made, _frame);
		return _frame;
	};
	
	#region jsDoc
	/// @func    __scope(_owner, _list, _extra, _walk, [_enums])
	/// @desc    Visits a statement list, or the listed fields of a `for` header, in a new scope; for the Script also
	///          its enum values.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct.ASTNode}            _owner   : The node that owns the scope
	/// @param   {Array<Struct.ASTNode>}     _list    : Its statements, or undefined
	/// @param   {Array<String>}             _extra   : Fields of _owner to visit in the scope, or undefined
	/// @param   {Struct}                    _walk    : The walk
	/// @param   {Array<Struct.ASTEnumDecl>} [_enums] : The file's enums
	#endregion
	static __scope = function(_owner, _list, _extra, _walk, _enums = undefined) {
		var _scope = {
			owner: _owner, list: _list, names: {}, frame: _walk.functions[array_length(_walk.functions) - 1],
			outer_list: _walk.list, outer_statement: _walk.statement,
		};
		array_push(_walk.scopes, _scope);
		if (_extra != undefined) {
			var _f = 0; repeat (array_length(_extra)) {
				var _child = _owner[$ _extra[_f]];
				if (_child != undefined) __visit(_child, _owner, _extra[_f], undefined, _walk);
			_f++}
		}
		if (_list != undefined) {
			var _list0 = _walk.list;
			var _statement0 = _walk.statement;
			var _i = 0; repeat (array_length(_list)) {
				_walk.list = _list;
				_walk.statement = _list[_i];
				__visit(_list[_i], _owner, "body", _i, _walk);
			_i++}
			_walk.list = _list0;
			_walk.statement = _statement0;
		}
		if (_enums != undefined) {
			var _e = 0; repeat (array_length(_enums)) {
				var _members = _enums[_e].members;
				var _m = 0; repeat (array_length(_members)) {
					if (_members[_m].init != undefined) __visit(_members[_m].init, _members[_m], "init", undefined, _walk);
				_m++}
			_e++}
		}
		array_pop(_walk.scopes);
	};
	
	#region jsDoc
	/// @func    __visit(_node, _parent, _field, _index, _walk)
	/// @desc    Renames every `let` and its reads, notes the reads made from another function, and walks into blocks,
	///          functions and catch bodies with their scopes. A `var` of a `let`'s name in its function gets GMLC2013.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct.ASTNode} _parent : Its parent
	/// @param   {String}         _field  : The parent's field
	/// @param   {Real}           _index  : The index in that field, undefined for a single node
	/// @param   {Struct}         _walk   : The walk
	#endregion
	static __visit = function(_node, _parent, _field, _index, _walk) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Block:
			case __GMLC_NodeKind_Case:
			case __GMLC_NodeKind_Default: {
				// a case's test is outside its body's scope
				if (_node.kind == __GMLC_NodeKind_Case) __visit(_node.test, _node, "test", undefined, _walk);
				__scope(_node, _node.body, undefined, _walk);
			return;}
			case __GMLC_NodeKind_For: {
				__scope(_node, undefined, ["init", "test", "update", "body"], _walk);
			return;}
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr: {
				var _frame = __enterFunction(_node, _parent, _field, _index, _walk);
				_frame.role = (_parent != undefined) ? _parent.kind : undefined;
				var _inHead = _walk.in_head;
				_walk.in_head = true;
				var _params = _node.params;
				var _p = 0; repeat (array_length(_params)) {
					if (_params[_p][$ "default"] != undefined) __visit(_params[_p][$ "default"], _params[_p], "default", undefined, _walk);
				_p++}
				if (_node[$ "parent"] != undefined) __visit(_node[$ "parent"], _node, "parent", undefined, _walk);
				_walk.in_head = false;
				__visit(_node.body, _node, "body", undefined, _walk);
				_walk.in_head = _inHead;
				array_pop(_walk.functions);
			return;}
			case __GMLC_NodeKind_StaticDecl: {
				// a static's own name is a declaration, not a read
				var _d = 0; repeat (array_length(_node.declarations)) {
					var _init = _node.declarations[_d].init;
					if (_init != undefined) __visit(_init, _node.declarations[_d], "init", undefined, _walk);
				_d++}
			return;}
			case __GMLC_NodeKind_Try: {
				// the caught name belongs to the catch body and hides a `let` of its name there
				__visit(_node.block, _node, "block", undefined, _walk);
				if (_node.catch_body != undefined) {
					var _caught = { owner: _node, list: undefined, names: {}, frame: _walk.functions[array_length(_walk.functions) - 1] };
					if (_node.catch_param != undefined) _caught.names[$ _node.catch_param.name] = { hides: true };
					array_push(_walk.scopes, _caught);
					__visit(_node.catch_body, _node, "catch_body", undefined, _walk);
					array_pop(_walk.scopes);
				}
				if (_node.finally_body != undefined) __visit(_node.finally_body, _node, "finally_body", undefined, _walk);
			return;}
			case __GMLC_NodeKind_VarDeclList: {
				var _isLet = (_node[$ "__extension"] == name);
				var _d = 0; repeat (array_length(_node.declarations)) {
					var _decl = _node.declarations[_d];
					var _name = _decl.target.name;
					if (_isLet) {
						// declared before its value is visited, so `let g = function() { g(); }` reaches itself
						__declare(_decl, _node, _walk);
					}
					else if (__isLet(__find(_name, _walk, true))) {
						_walk.parser.__report("GMLC2013", _decl.target.span, [_name]);
					}
					if (_decl.init != undefined) __visit(_decl.init, _decl, "init", undefined, _walk);
				_d++}
			return;}
			case __GMLC_NodeKind_Identifier: {
				var _let = __find(_node.name, _walk, false);
				if (!__isLet(_let)) return;
				_node.name = _let.unique;
				// `{x}` would now read another name: write the key out
				if (_parent != undefined) && (_parent.kind == __GMLC_NodeKind_StructEntry) _parent.shorthand = false;
				var _frame = _walk.functions[array_length(_walk.functions) - 1];
				if (_frame != _let.frame) _let.captured = true;
				array_push(_walk.refs, { node: _node, parent: _parent, field: _field, index: _index, frame: _frame, let: _let });
			return;}
		}
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _key = _fields[_f];
			var _value = _node[$ _key];
			if (is_array(_value)) {
				var _c = 0; repeat (array_length(_value)) {
					if (_value[_c] != undefined) __visit(_value[_c], _node, _key, _c, _walk);
				_c++}
			}
			else if (_value != undefined) {
				__visit(_value, _node, _key, undefined, _walk);
			}
		_f++}
	};
	
	#region jsDoc
	/// @func    __declare(_decl, _list, _walk)
	/// @desc    Declares a `let` in the current scope under a unique name; declared again in its block it is the
	///          same variable and gets GMLC2016.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct.ASTVarDecl}     _decl : The declarator
	/// @param   {Struct.ASTVarDeclList} _list : Its declaration
	/// @param   {Struct}                _walk : The walk
	#endregion
	static __declare = function(_decl, _list, _walk) {
		var _scope = _walk.scopes[array_length(_walk.scopes) - 1];
		var _name = _decl.target.name;
		var _frame = _walk.functions[array_length(_walk.functions) - 1];
		var _existing = __gmlc_struct_get(_scope.names, _name);
		if (__isLet(_existing)) {
			// declared again in its block: the same variable, as a `var` declared twice is
			_walk.parser.__report("GMLC2016", _decl.target.span, [_name]);
			_decl.target.name = _existing.unique;
			_decl.__let = _existing;
			array_push(_existing.again, _list);
			return;
		}
		var _let = {
			name: _name, unique: "__gmlc__let" + string(_walk.parser.__extension_id++) + "__" + _name, scope: _scope, frame: _frame,
			decl: _decl, decl_list: _list, again: [], captured: false, box: undefined,
		};
		_decl.__let = _let;
		_decl.target.name = _let.unique;
		_scope.names[$ _name] = _let;
		array_push(_walk.lets, _let);
	};
	
	#region jsDoc
	/// @func    __isLet(_found)
	/// @desc    Whether a scope entry is a `let`, not a name that hides one.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct} _found : The entry, or undefined
	/// @returns {Bool}
	#endregion
	static __isLet = function(_found) {
		return (_found != undefined) && !struct_exists(_found, "hides");
	};
	
	#region jsDoc
	/// @func    __find(_name, _walk, _sameFunction)
	/// @desc    The `let` a name means here, searching the scopes outward. A function's own name of that spelling hides
	///          the `let`s outside it.
	/// @self    GMLC_Ext_Let
	/// @param   {String} _name : The name
	/// @param   {Struct} _walk : The walk
	/// @param   {Bool}   _sameFunction : Only the current function's scopes count
	/// @returns {Struct|Undefined}
	#endregion
	static __find = function(_name, _walk, _sameFunction) {
		var _current = _walk.functions[array_length(_walk.functions) - 1];
		var _frame = _current;
		var _s = array_length(_walk.scopes) - 1;
		while (_s >= 0) {
			var _scope = _walk.scopes[_s];
			if (_scope.frame != _frame) {
				if (_sameFunction) return undefined;
				if (struct_exists(_frame.own, _name)) return undefined;
				_frame = _scope.frame;
			}
			if (struct_exists(_scope.names, _name)) return _scope.names[$ _name];
			_s--;
		}
		return undefined;
	};
	#endregion
	
	#region Boxes
	#region jsDoc
	/// @func    __box(_walk)
	/// @desc    A `let` at a script's top set to a literal and never written becomes that literal. Captured `let`s live in a
	///          box per scope, a global one for a script's top that a function which cannot capture reads. A `for` header's
	///          box is renewed each iteration, as in JavaScript.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct} _walk : The walk
	#endregion
	static __box = function(_walk) {
		var _parser = _walk.parser;
		var _l, _r, _b;
		
		_l = 0; repeat (array_length(_walk.lets)) {
			var _let = _walk.lets[_l];
			if (__isScriptTop(_let.scope, _walk)) && (array_length(_let.again) == 0) && __isConstant(_let.decl.init) _let.constant = _let.decl.init;
		_l++}
		_r = 0; repeat (array_length(_walk.refs)) {
			var _ref = _walk.refs[_r];
			if (__isWrite(_ref)) _ref.let.constant = undefined;
		_r++}
		_r = 0; repeat (array_length(_walk.refs)) {
			var _ref = _walk.refs[_r];
			if (_ref.let[$ "constant"] != undefined) {
				__gmlc_ext_set_child(_ref.parent, _ref.field, _ref.index, __gmlc_ext_copy_literal(_ref.let.constant, _ref.node.span));
				_ref.let.captured = false;
			}
		_r++}
		
		_r = 0; repeat (array_length(_walk.refs)) {
			var _ref = _walk.refs[_r];
			if (_ref.let.captured) && (__blocker(_ref.frame, _ref.let, _walk) != undefined) && __isScriptTop(_ref.let.scope, _walk) {
				_ref.let.scope.is_global = true;
			}
		_r++}
		
		var _boxes = [];
		_l = 0; repeat (array_length(_walk.lets)) {
			var _let = _walk.lets[_l];
			if (_let.captured) {
				var _scope = _let.scope;
				if (_scope[$ "box"] == undefined) {
					_scope.box = (_scope[$ "is_global"] == true)
						? "__gmlc__filebox__" + __scriptName(_parser)
						: "__gmlc__letbox" + string(_parser.__extension_id++);
					array_push(_boxes, _scope);
				}
				_let.box = _scope.box;
			}
		_l++}
		
		_r = 0; repeat (array_length(_walk.refs)) {
			var _ref = _walk.refs[_r];
			var _let = _ref.let;
			if (_let.box != undefined) {
				var _span = _ref.node.span;
				__gmlc_ext_set_child(_ref.parent, _ref.field, _ref.index, __gmlc_ext_dot(__boxRef(_let.scope, _span), _let.name, _span));
				if (_let.scope[$ "is_global"] != true) __reach(_ref.frame, _let, _walk);
			}
		_r++}
		
		_b = 0; repeat (array_length(_boxes)) {
			var _scope = _boxes[_b];
			var _span = _scope.owner.span;
			var _make = (_scope[$ "is_global"] == true)
				? new ASTExprStmt(_span, new ASTAssign(_span, "=", __boxRef(_scope, _span), new ASTStructLiteral(_span, [])))
				: __gmlc_ext_var(_scope.box, new ASTStructLiteral(_span, []), _span);
			if (_scope.list != undefined) {
				array_insert(_scope.list, 0, _make);
			}
			else {
				array_insert(_scope.outer_list, array_get_index(_scope.outer_list, _scope.outer_statement), _make);
			}
		_b++}
		
		var _f = array_length(_walk.made) - 1;
		while (_f >= 1) {
			var _frame = _walk.made[_f];
			if (array_length(_frame.boxes) > 0) {
				var _wrapped = __gmlc_ext_wrap_closure(name, _frame.node, _frame.boxes, _parser.__extension_id++);
				__gmlc_ext_set_child(_frame.parent, _frame.field, _frame.index, _wrapped.call);
				array_insert(_frame.list, array_get_index(_frame.list, _frame.statement), _wrapped.prelude);
			}
			_f--;
		}
		
		var _done = [];
		_l = 0; repeat (array_length(_walk.lets)) {
			var _let = _walk.lets[_l];
			if (_let.box != undefined) && !array_contains(_done, _let.decl_list) {
				array_push(_done, _let.decl_list);
				__boxDeclarations(_let.decl_list, _let.scope);
			}
			var _a = 0; repeat (array_length(_let.again)) {
				if (!array_contains(_done, _let.again[_a])) {
					array_push(_done, _let.again[_a]);
					__boxDeclarations(_let.again[_a], _let.scope);
				}
			_a++}
		_l++}
		
		_b = 0; repeat (array_length(_boxes)) {
			var _scope = _boxes[_b];
			if (_scope.list == undefined) && (_scope.owner.kind == __GMLC_NodeKind_For) __perIteration(_scope, _walk);
		_b++}
	};
	
	#region jsDoc
	/// @func    __perIteration(_scope, _walk)
	/// @desc    `for (; test; update) body` with a header box becomes
	///          `for (var next = 0; ; next = 1) { if (next) { box = { <name>: box.<name>, ... }; update } if (!(test)) break; body }`
	/// @self    GMLC_Ext_Let
	/// @param   {Struct} _scope : The `for` header's scope
	/// @param   {Struct} _walk  : The walk
	#endregion
	static __perIteration = function(_scope, _walk) {
		var _for = _scope.owner;
		var _span = _for.span;
		var _next = "__gmlc__letnext" + string(_walk.parser.__extension_id++);
		var _entries = [];
		var _l = 0; repeat (array_length(_walk.lets)) {
			var _let = _walk.lets[_l];
			if (_let.scope == _scope) && (_let.box != undefined) {
				array_push(_entries, new ASTStructEntry(_span, _let.name, false, false, __gmlc_ext_dot(__boxRef(_scope, _span), _let.name, _span)));
			}
		_l++}
		var _copy = [new ASTExprStmt(_span, new ASTAssign(_span, "=", __boxRef(_scope, _span), new ASTStructLiteral(_span, _entries)))];
		if (_for.update != undefined) array_push(_copy, _for.update);
		var _body = [new ASTIf(_span, new ASTIdentifier(_span, _next), new ASTBlock(_span, _copy), undefined)];
		if (_for.test != undefined) {
			array_push(_body, new ASTIf(_span, new ASTUnary(_span, "!", _for.test), new ASTBlock(_span, [new ASTBreak(_span)]), undefined));
		}
		array_push(_body, _for.body);
		_for.init = __gmlc_ext_var(_next, new ASTLiteral(_span, "real", "0", 0), _span);
		_for.test = undefined;
		_for.update = new ASTExprStmt(_span, new ASTAssign(_span, "=", new ASTIdentifier(_span, _next), new ASTLiteral(_span, "real", "1", 1)));
		_for.body = new ASTBlock(_span, _body);
	};
	
	#region jsDoc
	/// @func    __isConstant(_node)
	/// @desc    Whether a value is a literal or a negated number literal.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct.ASTNode} _node : The value, undefined for none
	/// @returns {Bool}
	#endregion
	static __isConstant = function(_node) {
		if (_node == undefined) return false;
		if (_node.kind == __GMLC_NodeKind_Literal) return true;
		return (_node.kind == __GMLC_NodeKind_Unary) && (_node.op == "-")
			&& (_node[$ "argument"].kind == __GMLC_NodeKind_Literal) && is_numeric(_node[$ "argument"].value);
	};
	
	#region jsDoc
	/// @func    __isWrite(_ref)
	/// @desc    Whether a read of a `let` is the target of an assignment, `++` or `--`.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct} _ref : The read
	/// @returns {Bool}
	#endregion
	static __isWrite = function(_ref) {
		if (_ref.parent == undefined) return false;
		if (_ref.parent.kind == __GMLC_NodeKind_Assign) return (_ref.field == "target");
		return (_ref.parent.kind == __GMLC_NodeKind_Update);
	};
	
	#region jsDoc
	/// @func    __boxRef(_scope, _span)
	/// @desc    The box of a scope: its local, or `global.<box>` for a script's top.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct}           _scope : The scope
	/// @param   {Struct.GMLC_Span} _span  : The span
	/// @returns {Struct.ASTNode}
	#endregion
	static __boxRef = function(_scope, _span) {
		if (_scope[$ "is_global"] == true) return __gmlc_ext_dot(new ASTIdentifier(_span, "global"), _scope.box, _span);
		return new ASTIdentifier(_span, _scope.box);
	};
	
	#region jsDoc
	/// @func    __isScriptTop(_scope, _walk)
	/// @desc    Whether a scope is a script's own statements; an object's event is not, as its functions are methods of the
	///          instance.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct} _scope : The scope
	/// @param   {Struct} _walk  : The walk
	/// @returns {Bool}
	#endregion
	static __isScriptTop = function(_scope, _walk) {
		return (_scope.owner == _walk.script) && (_walk.script[$ "unit_kind"] != "event");
	};
	
	#region jsDoc
	/// @func    __scriptName(_parser)
	/// @desc    The file's whole path without the extension, as a name: two files of one name in different folders get
	///          different boxes.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser : The parser
	/// @returns {String}
	#endregion
	static __scriptName = function(_parser) {
		var _file = _parser.program.file.name;
		var _dot = string_last_pos(".", _file);
		if (_dot > 0) _file = string_copy(_file, 1, _dot - 1);
		var _out = "";
		var _i = 1; repeat (string_length(_file)) {
			var _c = string_char_at(_file, _i);
			var _o = ord(_c);
			_out += ((_o >= 48 && _o <= 57) || (_o >= 65 && _o <= 90) || (_o >= 97 && _o <= 122) || (_c == "_")) ? _c : "_";
		_i++}
		return _out;
	};
	
	#region jsDoc
	/// @func    __blocker(_frame, _let, _walk)
	/// @desc    The first function between a read and the `let`'s own function that cannot capture, as its `self` would
	///          change.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct} _frame : The reading function
	/// @param   {Struct} _let   : The `let`
	/// @param   {Struct} _walk  : The walk
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static __blocker = function(_frame, _let, _walk) {
		while (_frame != undefined) && (_frame != _let.frame) {
			var _node = _frame.node;
			if (_node[$ "__extension"] != "closure") {
				var _named = (_node.kind != __GMLC_NodeKind_FunctionExpr) || _node.is_constructor;
				var _method = (_frame.role == __GMLC_NodeKind_StructEntry) || ((_frame.role == __GMLC_NodeKind_VarDecl) && __isStatic(_frame));
				if (_named || _method || _frame.in_head) return _node;
			}
			_frame = _frame.outer;
		}
		return undefined;
	};
	
	#region jsDoc
	/// @func    __reach(_frame, _let, _walk)
	/// @desc    Every function from the reader out to the `let`'s own function passes its box on; one inside
	///          `closure(...)` is left to that extension, which captures the box with its other locals.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct} _frame : The reading function
	/// @param   {Struct} _let   : The `let`
	/// @param   {Struct} _walk  : The walk
	#endregion
	static __reach = function(_frame, _let, _walk) {
		var _blocker = __blocker(_frame, _let, _walk);
		if (_blocker != undefined) {
			_walk.parser.__report("GMLC2014", _blocker.span, [_let.name]);
			return;
		}
		while (_frame != undefined) && (_frame != _let.frame) {
			if (_frame.node[$ "__extension"] != "closure") && !array_contains(_frame.boxes, _let.box) array_push(_frame.boxes, _let.box);
			_frame = _frame.outer;
		}
	};
	
	#region jsDoc
	/// @func    __isStatic(_frame)
	/// @desc    Whether a function is the value of a `static`.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct} _frame : The function's frame
	/// @returns {Bool}
	#endregion
	static __isStatic = function(_frame) {
		var _statement = _frame.statement;
		return (_statement != undefined) && (_statement.kind == __GMLC_NodeKind_StaticDecl);
	};
	
	#region jsDoc
	/// @func    __boxDeclarations(_list, _scope)
	/// @desc    A boxed `let` becomes `box.name = value;`, one declared again a write of its value (nothing without one),
	///          the others stay `var`s.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct.ASTVarDeclList} _list  : The declaration
	/// @param   {Struct}                _scope : Its scope
	#endregion
	static __boxDeclarations = function(_list, _scope) {
		var _out = [];
		var _d = 0; repeat (array_length(_list.declarations)) {
			var _decl = _list.declarations[_d];
			var _let = _decl[$ "__let"];
			var _again = (_let != undefined) && (_let.decl != _decl);
			var _span = _decl.span;
			if (_let != undefined) && ((_let.box != undefined) || _again) {
				if (!_again) || (_decl.init != undefined) {
					var _target = (_let.box != undefined) ? __gmlc_ext_dot(__boxRef(_let.scope, _span), _let.name, _span) : new ASTIdentifier(_span, _let.unique);
					var _value = _decl.init ?? __gmlc_ext_undefined(_span);
					array_push(_out, new ASTExprStmt(_span, new ASTAssign(_span, "=", _target, _value)));
				}
			}
			else {
				array_push(_out, new ASTVarDeclList(_span, [_decl]));
			}
		_d++}
		var _host = (_scope.list != undefined) ? _scope.list : _scope.outer_list;
		var _at = array_get_index(_host, _list);
		if (_at >= 0) {
			array_delete(_host, _at, 1);
			var _i = 0; repeat (array_length(_out)) {
				array_insert(_host, _at + _i, _out[_i]);
			_i++}
		}
		else if (_scope.owner.kind == __GMLC_NodeKind_For) && (_scope.owner.init == _list) {
			// a `for` header runs once, so its writes can go before the loop
			_scope.owner.init = undefined;
			var _at = array_get_index(_scope.outer_list, _scope.outer_statement);
			var _i = 0; repeat (array_length(_out)) {
				array_insert(_scope.outer_list, _at + _i, _out[_i]);
			_i++}
		}
	};
	#endregion
	#endregion
}
