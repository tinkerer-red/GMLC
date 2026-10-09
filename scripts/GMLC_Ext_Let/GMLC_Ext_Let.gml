#region Extension: let
// `let x = 1, y;`: locals seen from the declaration's block on, each renamed to its own local (`__gmlc__let0__x`).
// A `let` read by a function inside its block lives in a box struct made at the block's start (fresh each loop
// iteration) that the function captures like a `closure`; in a `for` header each iteration gets its own copy, as in
// JavaScript. At the top of a script the box is `global.__gmlc__filebox__<file path>`; a `let` there that is never
// written and holds a literal is a setting whose reads become the literal.
// Diagnostics: a `let` declared again in its block is the same variable (GMLC2016, warning); a `var` of the same
// name where the `let` is seen is GMLC2013. A named function, a constructor, a struct literal's or static's function,
// and a function in a parameter default or parent call cannot capture a `let` (its `self` would change): GMLC2014.

#region jsDoc
/// @func    GMLC_Ext_Let()
/// @desc    The `let` extension.
/// @returns {Struct.GMLC_Ext_Let}
#endregion
function GMLC_Ext_Let() : GMLC_Extension("let") constructor {
	static statementWords = ["let"];
	static functions = { method: __gmlc_method, __gmlc_closure_method: __gmlc_closure_method, __gmlc_closure_method_get_self: __gmlc_closure_method_get_self };
	
	#region jsDoc
	/// @func    parseStatement(_parser)
	/// @desc    `let a = 1, b`, parsed as a `var` declaration the rewrite then scopes to its block. `let` not followed
	///          by a name is an ordinary name.
	/// @self    GMLC_Ext_Let
	/// @param   {Struct.GMLC_Gen_2_Parser} _parser : The parser, on `let`
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static parseStatement = function(_parser) {
		var _next = _parser.peek();
		if (_next == undefined) || (_next.type != __GMLC_TokenType_Identifier) return undefined;
		var _first = _parser.currentToken;
		_parser.advance(); // let
		var _declarations = [];
		do {
			var _declFirst = _parser.currentToken;
			var _target = _parser.__parseName("a variable name");
			var _init = undefined;
			if (_parser.isOperator("=")) {
				_parser.advance();
				_init = _parser.parseExpression();
			}
			array_push(_declarations, _parser.finish(new ASTVarDecl(undefined, _target, _init), _declFirst));
		}
		until (!_parser.optional(__GMLC_TokenType_Punctuation, ",")
			|| (_parser.currentToken == undefined) || (_parser.currentToken.type != __GMLC_TokenType_Identifier));
		var _node = _parser.finish(new ASTVarDeclList(undefined, _declarations), _first);
		var _state = _parser.extensionState[$ name];
		if (!struct_exists(_state, "decls")) _state.decls = [];
		array_push(_state.decls, _node);
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
		// a function a `let` wrapped, from any file, may be given another `self` here
		__GMLC_ExtRouteMethods(name, _script);
		var _decls = _state[$ "decls"];
		if (_decls == undefined) return;
		var _closures = _parser.extensionState[$ "closure"];
		var _walk = {
			parser: _parser, decls: _decls, script: _script,
			closures: (_closures != undefined) ? (_closures[$ "functions"] ?? []) : [],
			scopes: [], functions: [], refs: [], lets: [], made: [],
			list: undefined, statement: undefined, inHead: false,
		};
		__enterFunction(_script, undefined, undefined, undefined, _walk);
		__scope(_script, _script.body, undefined, _walk, _script.enums);
		__leaveFunction(_walk);
		__box(_walk);
	};
	
	#region Names
	// a function's frame: its own names (parameters, `var`s, caught names; not its `let`s) and where it is
	static __enterFunction = function(_node, _parent, _field, _index, _walk) {
		var _frame = {
			node: _node, parent: _parent, field: _field, index: _index,
			list: _walk.list, statement: _walk.statement, inHead: _walk.inHead,
			outer: (array_length(_walk.functions) > 0) ? _walk.functions[array_length(_walk.functions) - 1] : undefined,
			own: __ownNames(_node, _walk.decls), boxes: [],
		};
		array_push(_walk.functions, _frame);
		array_push(_walk.made, _frame);
		return _frame;
	};
	static __leaveFunction = function(_walk) {
		array_pop(_walk.functions);
	};
	static __ownNames = function(_function, _decls) {
		var _out = {};
		var _params = _function[$ "params"] ?? [];
		var _p = 0; repeat (array_length(_params)) {
			_out[$ _params[_p].target.name] = true;
		_p++}
		__collectOwn((_function.kind == __GMLC_NodeKind_Script) ? _function : _function.body, _decls, _out);
		return _out;
	};
	static __collectOwn = function(_node, _decls, _out) {
		if ((_node.kind == __GMLC_NodeKind_VarDeclList) && !array_contains(_decls, _node)) || (_node.kind == __GMLC_NodeKind_StaticDecl) {
			var _d = 0; repeat (array_length(_node.declarations)) {
				_out[$ _node.declarations[_d].target.name] = true;
			_d++}
		}
		else if (_node.kind == __GMLC_NodeKind_Try) && (_node.catch_param != undefined) {
			_out[$ _node.catch_param.name] = true;
		}
		if (__GMLC_ExtIsFunction(_node)) return;
		var _children = _node.children();
		var _c = 0; repeat (array_length(_children)) {
			__collectOwn(_children[_c], _decls, _out);
		_c++}
	};
	
	// a block scope: the statements of _list, the `let`s declared in it from the declaration on
	static __scope = function(_owner, _list, _extra, _walk, _enums = undefined) {
		var _scope = {
			owner: _owner, list: _list, names: {}, frame: _walk.functions[array_length(_walk.functions) - 1],
			outerList: _walk.list, outerStatement: _walk.statement,
		};
		array_push(_walk.scopes, _scope);
		if (_extra != undefined) {
			// a `for`: its header belongs to this scope
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
		// the file's enum values read the `let`s of the file's top
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
				var _inHead = _walk.inHead;
				// its defaults and parent call run when it is called, its head
				_walk.inHead = true;
				var _params = _node.params;
				var _p = 0; repeat (array_length(_params)) {
					if (_params[_p][$ "default"] != undefined) __visit(_params[_p][$ "default"], _params[_p], "default", undefined, _walk);
				_p++}
				if (_node[$ "parent"] != undefined) __visit(_node[$ "parent"], _node, "parent", undefined, _walk);
				_walk.inHead = false;
				__visit(_node.body, _node, "body", undefined, _walk);
				_walk.inHead = _inHead;
				__leaveFunction(_walk);
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
				var _isLet = array_contains(_walk.decls, _node);
				var _d = 0; repeat (array_length(_node.declarations)) {
					var _decl = _node.declarations[_d];
					var _name = _decl.target.name;
					if (_isLet) {
						// declared before its value is read, so a function in the value reaches the `let` (`let g =
						// function() { g(); }`), as the binding covers its whole block
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
	
	// a `let` declarator: renamed, and visible from here on in the current scope
	static __declare = function(_decl, _list, _walk) {
		var _scope = _walk.scopes[array_length(_walk.scopes) - 1];
		var _name = _decl.target.name;
		var _frame = _walk.functions[array_length(_walk.functions) - 1];
		var _existing = __gmlc_struct_get(_scope.names, _name);
		if (__isLet(_existing)) {
			// declared again in its block: the same variable, as a `var` declared twice is
			_walk.parser.__report("GMLC2016", _decl.target.span, [_name]);
			_decl.target.name = _existing.unique;
			array_push(_existing.again, { decl: _decl, list: _list });
			return;
		}
		var _let = {
			name: _name, unique: "__gmlc__let" + string(_walk.parser.__extensionId++) + "__" + _name, scope: _scope, frame: _frame,
			decl: _decl, declList: _list, again: [], captured: false, box: undefined,
		};
		_decl.target.name = _let.unique;
		_scope.names[$ _name] = _let;
		array_push(_walk.lets, _let);
	};
	
	// whether what __find found is a `let` (and not a caught name that hides one)
	static __isLet = function(_found) {
		return (_found != undefined) && !struct_exists(_found, "hides");
	};
	
	// the `let` a name means here, through the scopes outward; a function's own name of that spelling hides the `let`s
	// outside it. With _sameFunction, only the current function's scopes count.
	static __find = function(_name, _walk, _sameFunction) {
		var _current = _walk.functions[array_length(_walk.functions) - 1];
		var _frame = _current;
		var _s = array_length(_walk.scopes) - 1;
		while (_s >= 0) {
			var _scope = _walk.scopes[_s];
			if (_scope.frame != _frame) {
				if (_sameFunction) return undefined;
				// leaving a function: its own names hide outer `let`s
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
	static __box = function(_walk) {
		var _parser = _walk.parser;
		
		// a setting at the top of a script, a literal never written again, is propagated: its reads become the literal
		var _l = 0; repeat (array_length(_walk.lets)) {
			var _let = _walk.lets[_l];
			if (__isScriptTop(_let.scope, _walk)) && (array_length(_let.again) == 0) && __isConstant(_let.decl.init) {
				_let.constant = _let.decl.init;
				_let.captured = false;
			}
		_l++}
		var _r = 0; repeat (array_length(_walk.refs)) {
			var _ref = _walk.refs[_r];
			if (__isWrite(_ref)) && (_ref.let[$ "constant"] != undefined) {
				_ref.let.constant = undefined;
				_ref.let.captured = __readElsewhere(_ref.let, _walk);
			}
		_r++}
		var _r = 0; repeat (array_length(_walk.refs)) {
			var _ref = _walk.refs[_r];
			if (_ref.let[$ "constant"] != undefined) __replace(_ref, __copyConstant(_ref.let.constant, _ref.node.span));
		_r++}
		
		// the file's box holds the other `let`s at the top of a script that a function without a capture reads
		var _r = 0; repeat (array_length(_walk.refs)) {
			var _ref = _walk.refs[_r];
			if (_ref.let.captured) && (__blocker(_ref.frame, _ref.let, _walk) != undefined) && __isScriptTop(_ref.let.scope, _walk) {
				_ref.let.scope.isGlobal = true;
			}
		_r++}
		
		// one box per scope that has a captured `let`
		var _boxes = [];
		var _l = 0; repeat (array_length(_walk.lets)) {
			var _let = _walk.lets[_l];
			if (_let.captured) {
				var _scope = _let.scope;
				if (_scope[$ "box"] == undefined) {
					_scope.box = (_scope[$ "isGlobal"] == true)
						? "__gmlc__filebox__" + __scriptName(_parser)
						: "__gmlc__letbox" + string(_parser.__extensionId++);
					array_push(_boxes, _scope);
				}
				_let.box = _scope.box;
			}
		_l++}
		
		// reads and writes of a boxed `let` go through the box
		var _r = 0; repeat (array_length(_walk.refs)) {
			var _ref = _walk.refs[_r];
			var _let = _ref.let;
			if (_let.box != undefined) {
				var _span = _ref.node.span;
				__replace(_ref, __GMLC_ExtDot(__boxRef(_let.scope, _span), _let.name, _span));
				// the file's box needs no capture
				if (_let.scope[$ "isGlobal"] != true) __reach(_ref.frame, _let, _walk);
			}
		_r++}
		
		// the box starts its scope; functions that reach a box get it; declarations of boxed `let`s become writes to it
		var _b = 0; repeat (array_length(_boxes)) {
			var _scope = _boxes[_b];
			var _span = _scope.owner.span;
			var _make = (_scope[$ "isGlobal"] == true)
				? new ASTExprStmt(_span, new ASTAssign(_span, "=", __boxRef(_scope, _span), new ASTStructLiteral(_span, [])))
				: __GMLC_ExtVar(_scope.box, new ASTStructLiteral(_span, []), _span);
			if (_scope.list != undefined) {
				array_insert(_scope.list, 0, _make);
			}
			else {
				// a `for` header: the box is made before the loop
				array_insert(_scope.outerList, array_get_index(_scope.outerList, _scope.outerStatement), _make);
			}
		_b++}
		
		// each function that reaches a box gets it like a closure
		var _f = array_length(_walk.made) - 1;
		while (_f >= 1) {
			var _frame = _walk.made[_f];
			if (array_length(_frame.boxes) > 0) {
				var _wrapped = __GMLC_ExtWrapClosure(name, _frame.node, _frame.boxes, _parser.__extensionId++);
				if (_frame.index != undefined) {
					_frame.parent[$ _frame.field][_frame.index] = _wrapped.call;
				}
				else {
					_frame.parent[$ _frame.field] = _wrapped.call;
				}
				array_insert(_frame.list, array_get_index(_frame.list, _frame.statement), _wrapped.prelude);
			}
			_f--;
		}
		
		// declarations of boxed `let`s become writes to the box, and a `let` declared again becomes a write
		var _done = [];
		var _l = 0; repeat (array_length(_walk.lets)) {
			var _let = _walk.lets[_l];
			if (_let.box != undefined) && !array_contains(_done, _let.declList) {
				array_push(_done, _let.declList);
				__boxDeclarations(_let.declList, _let.scope, _walk);
			}
			var _a = 0; repeat (array_length(_let.again)) {
				var _list = _let.again[_a].list;
				if (!array_contains(_done, _list)) {
					array_push(_done, _list);
					__boxDeclarations(_list, _let.scope, _walk);
				}
			_a++}
		_l++}
		
		// a boxed `let` of a `for` header: a fresh copy of the box each iteration
		var _b = 0; repeat (array_length(_boxes)) {
			var _scope = _boxes[_b];
			if (_scope.list == undefined) && (_scope.owner.kind == __GMLC_NodeKind_For) __perIteration(_scope, _walk);
		_b++}
	};
	
	// `for (; test; update) body` with a header box becomes
	// `for (var next = 0; ; next = 1) { if (next) { box = { <name>: box.<name>, ... }; update } if (!(test)) break; body }`
	static __perIteration = function(_scope, _walk) {
		var _for = _scope.owner;
		var _span = _for.span;
		var _next = "__gmlc__letnext" + string(_walk.parser.__extensionId++);
		var _entries = [];
		var _l = 0; repeat (array_length(_walk.lets)) {
			var _let = _walk.lets[_l];
			if (_let.scope == _scope) && (_let.box != undefined) {
				array_push(_entries, new ASTStructEntry(_span, _let.name, false, false, __GMLC_ExtDot(__boxRef(_scope, _span), _let.name, _span)));
			}
		_l++}
		var _copy = [new ASTExprStmt(_span, new ASTAssign(_span, "=", __boxRef(_scope, _span), new ASTStructLiteral(_span, _entries)))];
		if (_for.update != undefined) array_push(_copy, _for.update);
		var _body = [new ASTIf(_span, __GMLC_ExtName(_next, _span), new ASTBlock(_span, _copy), undefined)];
		if (_for.test != undefined) {
			array_push(_body, new ASTIf(_span, new ASTUnary(_span, "!", _for.test), new ASTBlock(_span, [new ASTBreak(_span)]), undefined));
		}
		array_push(_body, _for.body);
		_for.init = __GMLC_ExtVar(_next, new ASTLiteral(_span, "real", "0", 0), _span);
		_for.test = undefined;
		_for.update = new ASTExprStmt(_span, new ASTAssign(_span, "=", __GMLC_ExtName(_next, _span), new ASTLiteral(_span, "real", "1", 1)));
		_for.body = new ASTBlock(_span, _body);
	};
	
	// puts a node where a reference was
	static __replace = function(_ref, _node) {
		if (_ref.index != undefined) {
			_ref.parent[$ _ref.field][_ref.index] = _node;
		}
		else {
			_ref.parent[$ _ref.field] = _node;
		}
	};
	
	// a literal, or `-` of a number literal
	static __isConstant = function(_node) {
		if (_node == undefined) return false;
		if (_node.kind == __GMLC_NodeKind_Literal) return true;
		return (_node.kind == __GMLC_NodeKind_Unary) && (_node.op == "-")
			&& (_node[$ "argument"].kind == __GMLC_NodeKind_Literal) && is_numeric(_node[$ "argument"].value);
	};
	static __copyConstant = function(_node, _span) {
		if (_node.kind == __GMLC_NodeKind_Unary) return new ASTUnary(_span, "-", __copyConstant(_node[$ "argument"], _span));
		return new ASTLiteral(_span, _node.ty, _node.lexeme, _node.value);
	};
	
	// whether a reference is written: the target of an assignment or of `++`/`--`
	static __isWrite = function(_ref) {
		if (_ref.parent == undefined) return false;
		if (_ref.parent.kind == __GMLC_NodeKind_Assign) return (_ref.field == "target");
		return (_ref.parent.kind == __GMLC_NodeKind_Update);
	};
	
	// whether a function other than the `let`'s own reads it
	static __readElsewhere = function(_let, _walk) {
		var _r = 0; repeat (array_length(_walk.refs)) {
			if (_walk.refs[_r].let == _let) && (_walk.refs[_r].frame != _let.frame) return true;
		_r++}
		return false;
	};
	
	// the box of a scope: a local, or `global.<box>` for a script's top
	static __boxRef = function(_scope, _span) {
		if (_scope[$ "isGlobal"] == true) return __GMLC_ExtDot(__GMLC_ExtName("global", _span), _scope.box, _span);
		return __GMLC_ExtName(_scope.box, _span);
	};
	
	// the scope of a script's own statements, not of an object's event (whose functions are methods of the instance)
	static __isScriptTop = function(_scope, _walk) {
		return (_scope.owner == _walk.script) && (_walk.script[$ "unitKind"] != "event");
	};
	
	// the file as part of a global name: its whole path without the extension, so two files of one name in different
	// folders get different boxes; other characters as `_`
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
	
	// the first function between a read and the `let`'s own function that cannot capture, undefined when none
	static __blocker = function(_frame, _let, _walk) {
		while (_frame != undefined) && (_frame != _let.frame) {
			var _node = _frame.node;
			if (!array_contains(_walk.closures, _node)) {
				var _named = (_node.kind != __GMLC_NodeKind_FunctionExpr) || _node.is_constructor;
				var _method = (_frame.role == __GMLC_NodeKind_StructEntry) || ((_frame.role == __GMLC_NodeKind_VarDecl) && __isStatic(_frame));
				if (_named || _method || _frame.inHead) return _node;
			}
			_frame = _frame.outer;
		}
		return undefined;
	};
	
	// every function from the one that reads a boxed `let` out to the `let`'s own function passes its box on; a
	// function inside `closure(...)` is left to that extension, which captures the box with its other locals
	static __reach = function(_frame, _let, _walk) {
		var _blocker = __blocker(_frame, _let, _walk);
		if (_blocker != undefined) {
			_walk.parser.__report("GMLC2014", _blocker.span, [_let.name]);
			return;
		}
		while (_frame != undefined) && (_frame != _let.frame) {
			if (!array_contains(_walk.closures, _frame.node)) && !array_contains(_frame.boxes, _let.box) array_push(_frame.boxes, _let.box);
			_frame = _frame.outer;
		}
	};
	
	// whether a function is the value of a `static`
	static __isStatic = function(_frame) {
		var _statement = _frame.statement;
		return (_statement != undefined) && (_statement.kind == __GMLC_NodeKind_StaticDecl);
	};
	
	// a declaration list with boxed or repeated `let`s: a boxed one becomes `box.name = value;`, a repeated one a write
	// of its value (nothing without one), the others stay `var`s
	static __boxDeclarations = function(_list, _scope, _walk) {
		var _out = [];
		var _d = 0; repeat (array_length(_list.declarations)) {
			var _decl = _list.declarations[_d];
			var _let = __letOf(_decl, _walk);
			var _again = (_let != undefined) && (_let.decl != _decl);
			var _span = _decl.span;
			if (_let != undefined) && ((_let.box != undefined) || _again) {
				if (!_again) || (_decl.init != undefined) {
					var _target = (_let.box != undefined) ? __GMLC_ExtDot(__boxRef(_let.scope, _span), _let.name, _span) : __GMLC_ExtName(_let.unique, _span);
					var _value = _decl.init ?? __GMLC_ExtUndefined(_span);
					array_push(_out, new ASTExprStmt(_span, new ASTAssign(_span, "=", _target, _value)));
				}
			}
			else {
				array_push(_out, new ASTVarDeclList(_span, [_decl]));
			}
		_d++}
		var _host = (_scope.list != undefined) ? _scope.list : _scope.outerList;
		var _at = array_get_index(_host, _list);
		if (_at >= 0) {
			array_delete(_host, _at, 1);
			var _i = 0; repeat (array_length(_out)) {
				array_insert(_host, _at + _i, _out[_i]);
			_i++}
		}
		else if (_scope.owner.kind == __GMLC_NodeKind_For) && (_scope.owner.init == _list) {
			// a `for` header: the writes go before the loop, which runs them once as its header would
			_scope.owner.init = undefined;
			var _at = array_get_index(_scope.outerList, _scope.outerStatement);
			var _i = 0; repeat (array_length(_out)) {
				array_insert(_scope.outerList, _at + _i, _out[_i]);
			_i++}
		}
	};
	
	// the `let` a declarator made
	static __letOf = function(_decl, _walk) {
		var _l = 0; repeat (array_length(_walk.lets)) {
			var _let = _walk.lets[_l];
			if (_let.decl == _decl) return _let;
			var _a = 0; repeat (array_length(_let.again)) {
				if (_let.again[_a].decl == _decl) return _let;
			_a++}
		_l++}
		return undefined;
	};
	#endregion
}
#endregion
