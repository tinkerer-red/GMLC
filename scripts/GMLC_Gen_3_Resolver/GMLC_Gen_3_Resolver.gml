#region Resolver.gml
// GMLC_Gen_3_Resolver: binds every name of a parsed file to what it means, the step between the parser and the
// later stages. It changes no node; it fills the fields the parser leaves empty: `symbol` on every Identifier,
// `fn_id` and the name of anonymous functions on function nodes, and the file's `functions` table (each function's
// locals, so the compiler sizes their slots without walking the body again).
// It runs in two passes. The first records what is declared: the functions and `globalvar` names of the file's top
// level (global names; in a batch, those of every file, see collectGlobals) and for each function its parameters and
// `var` names (locals, numbered by first declaration) and its `static` names. The second gives each Identifier its
// symbol, first match wins, as GameMaker does (measured):
//   a local or static of the function (of the file's body outside functions) > a global name of the batch
//   > a function or constant the environment exposes > a variable it exposes > an instance variable (Self).
// Locals belong to the whole function, wherever the `var` is; a nested function does not see the locals of the one
// around it. A function declared inside a function is a method of `self` there, not a global. `E.M` of an enum the
// environment exposes binds `E` to the enum. Writes to what cannot be written are errors here; a write to a global
// function's name writes the instance variable of that name, as in GameMaker.

function GMLC_Gen_3_Resolver(_env) constructor {
	env = _env;
	
	ast = undefined;
	sources = undefined;
	frames = [];          // one per function, by fn_id; 0 is the file's body
	globalNames = {};     // global names of the batch: name to its shared Global symbol
	functionNodes = {};   // global function name to its declaration node
	nextFnId = 0;
	compileTimeUses = 0;  // Identifiers bound to a compile-time variable (the post-processor has work when above 0)
	__shared = {};        // symbols that do not depend on the function, by kind then name, shared by every use
	
	#region Public
	#region jsDoc
	/// @func    initialize(_ast, [_sources], [_globals])
	/// @desc    Prepares resolving of one parsed file.
	/// @self    GMLC_Gen_3_Resolver
	/// @param   {Struct.ASTScript}        _ast       : The parser's tree
	/// @param   {Struct.GMLC_SourceTable} [_sources] : The compile's files, for the positions of errors
	/// @param   {Struct}                  [_globals] : The batch's global names (collectGlobals), undefined for a file
	///                                                 compiled on its own
	#endregion
	static initialize = function(_ast, _sources = undefined, _globals = undefined) {
		ast = _ast;
		sources = _sources;
		frames = [];
		nextFnId = 0;
		compileTimeUses = 0;
		__shared = {};
		if (_globals != undefined) {
			globalNames = _globals.names;
			functionNodes = _globals.nodes;
		}
		else {
			globalNames = {};
			functionNodes = {};
			__collectTop(_ast);
		}
	};
	
	#region jsDoc
	/// @func    collectGlobals(_asts)
	/// @desc    The global names of a batch: the functions and `globalvar` names at the top level of every file, so a
	///          file can call a function another file of the batch declares.
	/// @self    GMLC_Gen_3_Resolver
	/// @param   {Array<Struct.ASTScript>} _asts : The parsed files of the batch
	/// @returns {Struct} {names, nodes}, to pass to initialize
	#endregion
	static collectGlobals = function(_asts) {
		globalNames = {};
		functionNodes = {};
		__shared = {};
		var _i = 0; repeat (array_length(_asts)) {
			__collectTop(_asts[_i]);
		_i++}
		return { names: globalNames, nodes: functionNodes };
	};
	
	#region jsDoc
	/// @func    parseAll()
	/// @desc    Resolves the whole file. Throws the first error.
	/// @self    GMLC_Gen_3_Resolver
	/// @returns {Struct.ASTScript} The same tree, resolved
	#endregion
	static parseAll = function() {
		var _body = __newFrame(0, ast);
		var _i = 0; repeat (array_length(ast.body)) {
			__declare(ast.body[_i], _body);
		_i++}
		_i = 0; repeat (array_length(ast.body)) {
			__resolve(ast.body[_i], _body);
		_i++}
		
		// the functions table: the locals of every function, by fn_id
		var _functions = array_create(array_length(frames), undefined);
		_i = 0; repeat (array_length(frames)) {
			var _frame = frames[_i];
			_functions[_i] = new GMLC_FunctionInfo(_frame.fn_id, (_i == 0) ? undefined : _frame.node.name, _frame.locals);
		_i++}
		ast.functions = _functions;
		return ast;
	};
	
	static cleanup = function() {};
	#endregion
	
	#region Declare
	// the global names declared at the top level of a file (the body outside functions, blocks included)
	static __collectTop = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl: {
				globalNames[$ _node.name] = __symbol("Global", _node.name);
				functionNodes[$ _node.name] = _node;
			return;}
			case __GMLC_NodeKind_FunctionExpr: return;
			case __GMLC_NodeKind_GlobalVarDecl: {
				var _n = 0; repeat (array_length(_node.names)) {
					globalNames[$ _node.names[_n].name] = __symbol("Global", _node.names[_n].name);
				_n++}
			return;}
		}
		var _children = _node.children();
		var _c = 0; repeat (array_length(_children)) {
			__collectTop(_children[_c]);
		_c++}
	};
	
	static __newFrame = function(_fnId, _node) {
		var _frame = { fn_id: _fnId, node: _node, locals: [], slots: {}, statics: {} };
		frames[_fnId] = _frame;
		return _frame;
	};
	
	// a local: its slot is its number in the order of first declaration; the symbol is shared by every use
	static __declareLocal = function(_frame, _name) {
		if (!__gmlc_struct_has(_frame.slots, _name)) {
			_frame.slots[$ _name] = new GMLC_Symbol("Local", _name, array_length(_frame.locals));
			array_push(_frame.locals, _name);
		}
	};
	
	#region jsDoc
	/// @func    __declare(_node, _frame)
	/// @desc    Records the declarations of a node and its children: function ids and names, and the locals and
	///          statics of the function they are in.
	/// @self    GMLC_Gen_3_Resolver
	#endregion
	static __declare = function(_node, _frame) {
		switch (_node.kind) {
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr: {
				_node.fn_id = ++nextFnId;
				if (_frame.fn_id == 0) && (_node.kind != __GMLC_NodeKind_FunctionExpr) && env.isFunction(_node.name) {
					__error("GMLC2006", $"a function named {_node.name} already exists", _node);
				}
				if (_node.name == undefined) {
					// numbered across the environment, as GameMaker names its own `anon@N`
					_node.name = "GMLC@anon@" + string(env.anonFunctionCount++);
				}
				var _inner = __newFrame(_node.fn_id, _node);
				var _p = 0; repeat (array_length(_node.params)) {
					__declareLocal(_inner, _node.params[_p].target.name);
				_p++}
				var _children = _node.children();
				var _c = 0; repeat (array_length(_children)) {
					__declare(_children[_c], _inner);
				_c++}
				return;
			}
			case __GMLC_NodeKind_VarDeclList: {
				var _d = 0; repeat (array_length(_node.declarations)) {
					var _target = _node.declarations[_d].target;
					if (env.isVariable(_target.name)) {
						__error("GMLC2002", $"cannot redeclare the built-in variable {_target.name}", _target);
					}
					__declareLocal(_frame, _target.name);
				_d++}
			break;}
			case __GMLC_NodeKind_StaticDecl: {
				if (_frame.fn_id == 0) {
					__error("GMLC2007", "static can only be declared inside a function", _node);
				}
				var _d = 0; repeat (array_length(_node.declarations)) {
					var _name = _node.declarations[_d].target.name;
					_frame.statics[$ _name] = __symbol("Static", _name);
				_d++}
			break;}
			case __GMLC_NodeKind_Try: {
				if (_node.catch_param != undefined) __declareLocal(_frame, _node.catch_param.name);
			break;}
		}
		var _children = _node.children();
		var _c = 0; repeat (array_length(_children)) {
			__declare(_children[_c], _frame);
		_c++}
	};
	#endregion
	
	#region Resolve
	#region jsDoc
	/// @func    __resolve(_node, _frame)
	/// @desc    Gives every Identifier in a node a symbol, and checks writes to things that cannot be written.
	/// @self    GMLC_Gen_3_Resolver
	#endregion
	static __resolve = function(_node, _frame) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier: {
				_node.symbol = __lookup(_node, _frame);
			return;}
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr: {
				var _inner = frames[_node.fn_id];
				var _p = 0; repeat (array_length(_node.params)) {
					var _param = _node.params[_p];
					_param.target.symbol = _inner.slots[$ _param.target.name];
					// a default is evaluated in the function's own frame
					if (_param[$ "default"] != undefined) __resolve(_param[$ "default"], _inner);
				_p++}
				var _parent = _node[$ "parent"]; // a FunctionDecl has none
				if (_parent != undefined) {
					__resolve(_parent, _inner);
					__checkParent(_parent);
				}
				__resolve(_node.body, _inner);
			return;}
			case __GMLC_NodeKind_VarDeclList: {
				var _d = 0; repeat (array_length(_node.declarations)) {
					var _decl = _node.declarations[_d];
					_decl.target.symbol = _frame.slots[$ _decl.target.name];
					if (_decl.init != undefined) __resolve(_decl.init, _frame);
				_d++}
			return;}
			case __GMLC_NodeKind_StaticDecl: {
				var _d = 0; repeat (array_length(_node.declarations)) {
					var _decl = _node.declarations[_d];
					_decl.target.symbol = _frame.statics[$ _decl.target.name];
					if (_decl.init != undefined) __resolve(_decl.init, _frame);
				_d++}
			return;}
			case __GMLC_NodeKind_GlobalVarDecl: {
				var _n = 0; repeat (array_length(_node.names)) {
					_node.names[_n].symbol = __symbol("Global", _node.names[_n].name);
				_n++}
			return;}
			case __GMLC_NodeKind_Try: {
				__resolve(_node.block, _frame);
				if (_node.catch_param != undefined) _node.catch_param.symbol = _frame.slots[$ _node.catch_param.name];
				if (_node.catch_body != undefined) __resolve(_node.catch_body, _frame);
				if (_node.finally_body != undefined) __resolve(_node.finally_body, _frame);
			return;}
			case __GMLC_NodeKind_Index: {
				// `E.M` of an enum the environment exposes
				if (_node.accessor == "Dot") && (_node.object.kind == __GMLC_NodeKind_Identifier) {
					var _symbol = __lookup(_node.object, _frame);
					if (_symbol.kind != "Local") && (_symbol.kind != "Static") {
						var _enum = env.getEnum(_node.object.name);
						if (_enum != undefined) && is_struct(_enum.value) && __gmlc_struct_has(_enum.value, _node.member) {
							_symbol = __symbol("Enum", _node.object.name);
						}
					}
					_node.object.symbol = _symbol;
					return;
				}
			break;}
			case __GMLC_NodeKind_Assign: {
				__resolve(_node.target, _frame);
				__resolve(_node.value, _frame);
				__checkWrite(_node.target, false);
			return;}
			case __GMLC_NodeKind_Update: {
				__resolve(_node[$ "argument"], _frame);
				__checkWrite(_node[$ "argument"], true);
			return;}
		}
		var _children = _node.children();
		var _c = 0; repeat (array_length(_children)) {
			__resolve(_children[_c], _frame);
		_c++}
	};
	
	#region jsDoc
	/// @func    __lookup(_identifier, _frame)
	/// @desc    The symbol of a name used in a function: first match of local, static, global name, exposed function or
	///          constant, exposed variable, instance variable.
	/// @self    GMLC_Gen_3_Resolver
	/// @returns {Struct.GMLC_Symbol}
	#endregion
	static __lookup = function(_identifier, _frame) {
		var _name = _identifier.name;
		var _symbol = __gmlc_struct_get(_frame.slots, _name)
			?? __gmlc_struct_get(_frame.statics, _name)
			?? __gmlc_struct_get(globalNames, _name);
		if (_symbol != undefined) return _symbol;
		
		// one look in the environment's table, whose entries know their kind
		var _entry = __gmlc_struct_get(env.envSymbols, _name);
		if (_entry != undefined) {
			switch (_entry[$ "type"]) {
				case "envFunctions": return __symbol("BuiltinFunction", _name);
				case "envConstants": return __symbol("BuiltinConstant", _name);
				case "envVariable": {
					if (__isCompileTime(_entry)) compileTimeUses++;
					return __symbol("BuiltinVar", _name);
				}
			}
		}
		// GMLC's own run-time helper, only where the preprocessor wrote it for an enum value
		if (_identifier.origin != undefined) && (_identifier.origin.kind == "enum") && __gmlc_struct_has(__GMLC_InternalFunctions(), _name) {
			return __symbol("BuiltinFunction", _name);
		}
		return __symbol("Self", _name);
	};
	
	// the one symbol of a kind and name that does not depend on the function
	static __symbol = function(_kind, _name) {
		var _byName = __shared[$ _kind];
		if (_byName == undefined) {
			_byName = {};
			__shared[$ _kind] = _byName;
		}
		var _symbol = __gmlc_struct_get(_byName, _name);
		if (_symbol == undefined) {
			_symbol = new GMLC_Symbol(_kind, _name);
			_byName[$ _name] = _symbol;
		}
		return _symbol;
	};
	
	// whether an exposed variable's value is known when compiling (`_GMLINE_`, ...)
	static __isCompileTime = function(_entry) {
		var _value = _entry[$ "value"];
		return is_struct(_value) && (_value[$ "compileTimeConstant"] == true);
	};
	#endregion
	
	#region Checks
	// the parent of a constructor must be a constructor when the batch declares it
	static __checkParent = function(_parent) {
		var _callee = _parent.callee;
		if (_callee.kind != __GMLC_NodeKind_Identifier) || (_callee.symbol == undefined) || (_callee.symbol.kind != "Global") return;
		var _declaration = __gmlc_struct_get(functionNodes, _callee.name);
		if (_declaration == undefined) return;
		if (_declaration.kind != __GMLC_NodeKind_ConstructorDecl) {
			__error("GMLC2107", $"the parent {_callee.name} is not a constructor", _parent);
		}
	};
	
	#region jsDoc
	/// @func    __checkWrite(_target, _isUpdate)
	/// @desc    Refuses an assignment (`=`, `+=`, ...) or a `++`/`--` of what cannot change, with GameMaker's verdicts
	///          (measured); a write to a global function's name becomes a write to the instance variable.
	/// @self    GMLC_Gen_3_Resolver
	/// @param   {Struct.ASTNode} _target   : The target
	/// @param   {Bool}           _isUpdate : Whether it is `++`/`--`
	#endregion
	static __checkWrite = function(_target, _isUpdate) {
		if (_target.kind == __GMLC_NodeKind_Literal) {
			if (_target.origin != undefined) && (_target.origin.kind == "enum") {
				__error("GMLC2205", $"the enum member {_target.lexeme} cannot be assigned to", _target);
			}
			if (_isUpdate) __error("GMLC2206", "a constant cannot be incremented or decremented", _target);
			__error("GMLC2201", $"cannot set the constant {_target.lexeme} to a value", _target);
		}
		if (_target.kind != __GMLC_NodeKind_Identifier) return;
		var _symbol = _target.symbol;
		switch (_symbol.kind) {
			case "BuiltinConstant": {
				if (_isUpdate) __error("GMLC2206", $"the constant {_target.name} cannot be incremented or decremented", _target);
				__error("GMLC2201", $"cannot set the constant {_target.name} to a value", _target);
			break;}
			case "BuiltinFunction": {
				// a script of the game is like a global function of the batch; a built-in function is read-only
				var _entry = __gmlc_struct_get(env.envSymbols, _target.name);
				if (_entry != undefined) && is_script(_entry[$ "raw"]) {
					_target.symbol = __symbol("Self", _target.name);
				}
				else {
					__error("GMLC2204", $"{_target.name} is a read-only function", _target);
				}
			break;}
			case "Enum": {
				__error("GMLC2205", $"the enum {_target.name} cannot be assigned to", _target);
			break;}
			case "BuiltinVar": {
				if (__isCompileTime(env.envSymbols[$ _target.name])) {
					__error("GMLC2203", $"{_target.name} is known when compiling and cannot be assigned to", _target);
				}
			break;}
			case "Global": {
				// a function's name: GameMaker writes the instance variable and the name still reads the function
				if (__gmlc_struct_has(functionNodes, _target.name)) _target.symbol = __symbol("Self", _target.name);
			break;}
		}
	};
	
	static __error = function(_code, _message, _node) {
		var _at = (sources != undefined) ? sources.position(_node.span) : { fileName: "", line: 0, column: 0, lineString: "" };
		throw_gmlc_error(_code + ": " + _message, _at.line, _at.lineString, _at.column, _at.fileName);
	};
	#endregion
}
#endregion
