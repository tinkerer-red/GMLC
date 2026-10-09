#region Resolver.gml
// GMLC_Gen_3_Resolver: binds every name of a parsed file, filling `symbol`, `fn_id` and the `functions` table without
// changing nodes. Pass one records declarations: the file's global functions and `globalvar` names (every file's in a
// batch) and each function's parameters, `var` locals (numbered after the parameters) and statics. Pass two binds each
// Identifier, first match wins as in GameMaker:
//   local or static of the function > global name of the batch > exposed function or constant > exposed variable
//   > instance variable (Self).
// Locals belong to the whole function wherever the `var` is, and a nested function does not see the locals around
// it. A function declared inside a function is a method of `self`, not a global. A write to a global function's or
// game script's name writes the instance variable of that name. What GameMaker refuses is an error, what it compiles
// is a warning; every problem of the file is reported before an error stops it.

function GMLC_Gen_3_Resolver(_env) constructor {
	env = _env;
	
	ast = undefined;
	sources = undefined;
	diagnostics = [];     // GMLC_Diagnostic records of this file
	frames = [];          // one per function, by fn_id; 0 is the file's body
	globalNames = {};     // global names of the batch: name to its shared Global symbol
	functionNodes = {};   // global function name to its declaration node
	enumNames = {};       // the enums of the batch (a bare enum name is an error)
	nextFnId = 0;
	__shared = {};        // symbols that do not depend on the function, by kind then name, shared by every use
	__collectingEvent = false; // collectGlobals is in an object event's file
	
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
		diagnostics = [];
		frames = [];
		nextFnId = 0;
		__shared = {};
		if (_globals != undefined) {
			globalNames = _globals.names;
			functionNodes = _globals.nodes;
			enumNames = _globals.enums;
		}
		else {
			globalNames = {};
			functionNodes = {};
			enumNames = {};
			__collectingEvent = (_ast[$ "unitKind"] == "event");
			__collectTop(_ast);
			__collectingEvent = false;
		}
	};
	
	#region jsDoc
	/// @func    collectGlobals(_asts)
	/// @desc    The global names of a batch: the functions and `globalvar` names at the top level of every file, so a
	///          file can call a function another file of the batch declares, and the enums of every file.
	/// @self    GMLC_Gen_3_Resolver
	/// @param   {Array<Struct.ASTScript>} _asts : The parsed files of the batch
	/// @returns {Struct} {names, nodes, enums}, to pass to initialize
	#endregion
	static collectGlobals = function(_asts) {
		globalNames = {};
		functionNodes = {};
		enumNames = {};
		__shared = {};
		var _i = 0; repeat (array_length(_asts)) {
			// an object event's functions are methods of the instance, not global names
			__collectingEvent = (_asts[_i][$ "unitKind"] == "event");
			__collectTop(_asts[_i]);
		_i++}
		__collectingEvent = false;
		return { names: globalNames, nodes: functionNodes, enums: enumNames };
	};
	
	#region jsDoc
	/// @func    parseAll()
	/// @desc    Resolves the whole file. Throws when one of its diagnostics is an error.
	/// @self    GMLC_Gen_3_Resolver
	/// @returns {Struct.ASTScript} The same tree, resolved
	#endregion
	static parseAll = function() {
		var _body = __newFrame(0, ast, undefined);
		var _i = 0; repeat (array_length(ast.body)) {
			__declare(ast.body[_i], _body);
		_i++}
		_i = 0; repeat (array_length(ast.body)) {
			__resolve(ast.body[_i], _body);
		_i++}
		// enum values read names as the file's body does
		_i = 0; repeat (array_length(ast.enums)) {
			var _members = ast.enums[_i].members;
			var _m = 0; repeat (array_length(_members)) {
				if (_members[_m].init != undefined) __resolve(_members[_m].init, _body);
			_m++}
		_i++}
		
		// the functions table, by fn_id
		var _functions = array_create(array_length(frames), undefined);
		_i = 0; repeat (array_length(frames)) {
			var _frame = frames[_i];
			var _parent = (_frame.parent != undefined) ? _frame.parent.fn_id : undefined;
			_functions[_i] = new GMLC_FunctionInfo(_frame.fn_id, (_i == 0) ? undefined : _frame.node.name, _parent,
				_frame.params, _frame.locals, _frame.staticNames);
		_i++}
		ast.functions = _functions;
		
		if (__gmlc_has_errors(diagnostics)) __gmlc_throw_diagnostics(diagnostics, sources);
		return ast;
	};
	
	static cleanup = function() {};
	#endregion
	
	#region Declare
	// the global names declared at the top level of a file (the body outside functions, blocks included), and the
	// file's enums
	static __collectTop = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Script: {
				var _e = 0; repeat (array_length(_node.enums)) {
					enumNames[$ _node.enums[_e].name] = true;
				_e++}
			break;}
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl: {
				if (__collectingEvent) return;
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
	
	static __newFrame = function(_fnId, _node, _parent) {
		var _frame = {
			fn_id: _fnId, node: _node, parent: _parent,
			params: [], locals: [], staticNames: [],
			slots: {}, statics: {},
			varAt: {}, // the start of the first `var` of each local, for a use before it
			boundKeys: undefined, // the keys of the struct literal `method(<struct>, <this function>)` binds it to
		};
		frames[_fnId] = _frame;
		return _frame;
	};
	
	// a local: its slot is its number in declaration order, parameters first; the symbol is shared by every use
	static __declareLocal = function(_frame, _name) {
		if (__gmlc_struct_has(_frame.slots, _name)) return false;
		_frame.slots[$ _name] = new GMLC_Symbol("Local", _name, array_length(_frame.params) + array_length(_frame.locals));
		array_push(_frame.locals, _name);
		return true;
	};
	
	#region jsDoc
	/// @func    __declare(_node, _frame)
	/// @desc    Records the declarations of a node and its children: function ids and names, and the parameters,
	///          locals and statics of the function they are in.
	/// @self    GMLC_Gen_3_Resolver
	#endregion
	static __declare = function(_node, _frame) {
		switch (_node.kind) {
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr: {
				_node.fn_id = ++nextFnId;
				if (_frame.fn_id == 0) && (_node.kind != __GMLC_NodeKind_FunctionExpr) && (ast[$ "unitKind"] != "event") {
					if (__isBuiltinFunction(_node.name)) {
						__report("GMLC2011", _node, [_node.name]);
					}
					else if (env.isFunction(_node.name)) {
						// a script of the game: this declaration is used in its place
						__report("GMLC2006", _node, [_node.name]);
					}
					else if (__gmlc_struct_get(functionNodes, _node.name) != _node) {
						// another declaration of the name is the one the batch registers last
						var _sameFile = (functionNodes[$ _node.name].span.file == _node.span.file);
						__report("GMLC2015", _node, [_node.name], _sameFile ? "GMLC2015.same-file" : "GMLC2015");
					}
				}
				if (_node.name == undefined) {
					// numbered across the environment, as GameMaker names its own `anon@N`
					_node.name = "GMLC@anon@" + string(env.anonFunctionCount++);
				}
				var _inner = __newFrame(_node.fn_id, _node, _frame);
				var _sawDefault = undefined;
				var _p = 0; repeat (array_length(_node.params)) {
					var _param = _node.params[_p];
					var _name = _param.target.name;
					if (__gmlc_struct_has(_inner.slots, _name)) {
						__report("GMLC2001", _param.target, [_name]);
					}
					else {
						_inner.slots[$ _name] = new GMLC_Symbol("Local", _name, array_length(_inner.params));
						array_push(_inner.params, _name);
					}
					if (_param[$ "default"] != undefined) {
						_sawDefault ??= _param;
					}
					else if (_sawDefault != undefined) {
						__report("GMLC2008", _sawDefault.target, [_sawDefault.target.name]);
						_sawDefault = undefined;
					}
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
					var _name = _target.name;
					if (env.isVariable(_name)) {
						__report("GMLC2002", _target, [_name]);
					}
					else if (__isBuiltinFunction(_name)) {
						__report("GMLC2003", _target, [_name]);
					}
					if (array_get_index(_frame.params, _name) >= 0) {
						// GameMaker refuses it: "cannot use argument name for a variable"
						__report("GMLC2017", _target, [_name]);
					}
					else {
						if (__gmlc_struct_has(_frame.varAt, _name)) {
							__report("GMLC2005", _target, [_name]);
						}
						else {
							_frame.varAt[$ _name] = _target.span.start;
						}
						__declareLocal(_frame, _name);
					}
				_d++}
			break;}
			case __GMLC_NodeKind_StaticDecl: {
				if (_frame.fn_id == 0) {
					__report("GMLC2007", _node);
				}
				var _d = 0; repeat (array_length(_node.declarations)) {
					var _name = _node.declarations[_d].target.name;
					if (!__gmlc_struct_has(_frame.statics, _name)) array_push(_frame.staticNames, _name);
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
	/// @desc    Gives every Identifier in a node a symbol, and checks names, calls and writes.
	/// @self    GMLC_Gen_3_Resolver
	#endregion
	static __resolve = function(_node, _frame) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier: {
				_node.symbol = __lookup(_node, _frame);
				__checkName(_node, _frame);
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
					// the parent call runs on the struct `new` made, so it is not checked as a call
					__resolve(_parent.callee, _inner);
					var _a = 0; repeat (array_length(_parent.args)) {
						__resolve(_parent.args[_a], _inner);
					_a++}
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
				// `E.M` of an enum of the batch (the preprocessor checked its member) or of one the environment exposes
				if (_node.accessor == "Dot") && (_node.object.kind == __GMLC_NodeKind_Identifier) {
					var _symbol = __lookup(_node.object, _frame);
					if (_symbol.kind != "Local") && (_symbol.kind != "Static") {
						if (__gmlc_struct_has(enumNames, _node.object.name)) {
							_symbol = __symbol("Enum", _node.object.name);
						}
						else {
							var _enum = env.getEnum(_node.object.name);
							if (_enum != undefined) && is_struct(_enum.value) && __gmlc_struct_has(_enum.value, _node.member) {
								_symbol = __symbol("Enum", _node.object.name);
							}
						}
					}
					_node.object.symbol = _symbol;
					if (_symbol.kind != "Enum") __checkName(_node.object, _frame);
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
			case __GMLC_NodeKind_Call: {
				__resolve(_node.callee, _frame);
				__noteMethodBinding(_node);
				var _a = 0; repeat (array_length(_node.args)) {
					__resolve(_node.args[_a], _frame);
				_a++}
				__checkCall(_node);
			return;}
			case __GMLC_NodeKind_New: {
				__resolve(_node.callee, _frame);
				var _a = 0; repeat (array_length(_node.args)) {
					__resolve(_node.args[_a], _frame);
				_a++}
				__checkNew(_node);
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
		// a function a language extension's rewrite calls: GameMaker's or GMLC's own, whatever the exposure
		var _origin = _identifier.origin;
		if (_origin != undefined) && (_origin.kind == "extension") && __gmlc_struct_has(__GMLC_InternalFunctions(), _name) {
			return __symbol("BuiltinFunction", _name);
		}
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
				case "envVariable": return __symbol("BuiltinVar", _name);
			}
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
	
	// whether a name is a built-in function the environment exposes (a game script is not one)
	static __isBuiltinFunction = function(_name) {
		var _entry = __gmlc_struct_get(env.envSymbols, _name);
		return (_entry != undefined) && (_entry[$ "type"] == "envFunctions") && !is_script(_entry[$ "raw"]);
	};
	#endregion
	
	#region Checks
	#region jsDoc
	/// @func    __noteMethodBinding(_call)
	/// @desc    For `method(<struct literal>, <function expression>)`: records the struct's keys on the function's frame,
	///          since the function then reads those names from the struct, its `self`.
	/// @self    GMLC_Gen_3_Resolver
	#endregion
	static __noteMethodBinding = function(_call) {
		var _callee = _call.callee;
		if (_callee.kind != __GMLC_NodeKind_Identifier) || (_callee.name != "method") || (_callee.symbol.kind != "BuiltinFunction") return;
		if (array_length(_call.args) != 2) return;
		var _struct = _call.args[0];
		var _function = _call.args[1];
		if (_struct.kind != __GMLC_NodeKind_StructLiteral) || (_function.kind != __GMLC_NodeKind_FunctionExpr) return;
		var _keys = {};
		var _e = 0; repeat (array_length(_struct.entries)) {
			_keys[$ _struct.entries[_e].key] = true;
		_e++}
		frames[_function.fn_id].boundKeys = _keys;
	};
	
	#region jsDoc
	/// @func    __checkName(_identifier, _frame)
	/// @desc    The checks of a name where it is used: an enum without a member, `argument` forms in the wrong place, a
	///          local used before its `var`, a local of an enclosing function.
	/// @self    GMLC_Gen_3_Resolver
	#endregion
	static __checkName = function(_identifier, _frame) {
		var _name = _identifier.name;
		var _kind = _identifier.symbol.kind;
		switch (_kind) {
			case "Local": {
				var _varAt = __gmlc_struct_get(_frame.varAt, _name);
				if (_varAt != undefined) && (_identifier.span.start < _varAt) {
					__report("GMLC2102", _identifier, [_name]);
				}
			break;}
			case "Self": {
				if (__gmlc_struct_has(enumNames, _name)) || env.isEnum(_name) {
					__report("GMLC2101", _identifier, [_name]);
					break;
				}
				// a local of a function around this one, which GML functions do not capture; a function bound by
				// `method({name: ...}, function() {})` reads the struct's own copy
				if (_frame.boundKeys != undefined) && __gmlc_struct_has(_frame.boundKeys, _name) break;
				var _outer = _frame.parent;
				while (_outer != undefined) {
					if (__gmlc_struct_has(_outer.slots, _name)) {
						__report("GMLC2110", _identifier, [_name]);
						break;
					}
					_outer = _outer.parent;
				}
			break;}
			case "BuiltinVar": {
				// `argument[i]` with named parameters is the usual way to take more arguments, so only argumentN counts
				if (__gmlc_argument_index(_name) >= 0) {
					if (_frame.fn_id == 0) {
						__report("GMLC2010", _identifier, [_name]);
					}
					else if (array_length(_frame.params) > 0) {
						__report("GMLC2009", _identifier, [_name]);
					}
				}
			break;}
		}
	};
	
	// the parent of a constructor must be a constructor when the batch declares it
	static __checkParent = function(_parent) {
		var _callee = _parent.callee;
		if (_callee.kind != __GMLC_NodeKind_Identifier) || (_callee.symbol == undefined) || (_callee.symbol.kind != "Global") return;
		var _declaration = __gmlc_struct_get(functionNodes, _callee.name);
		if (_declaration == undefined) return;
		if (_declaration.kind != __GMLC_NodeKind_ConstructorDecl) {
			__report("GMLC2107", _parent, [_callee.name]);
		}
	};
	
	#region jsDoc
	/// @func    __checkCall(_call)
	/// @desc    A call of a built-in function with an argument count its signature does not take, and a call of a
	///          known constructor without `new`.
	/// @self    GMLC_Gen_3_Resolver
	#endregion
	static __checkCall = function(_call) {
		var _callee = _call.callee;
		if (_callee.kind != __GMLC_NodeKind_Identifier) return;
		switch (_callee.symbol.kind) {
			case "BuiltinFunction": {
				// only built-ins with GameMaker's signature data are checked
				var _entry = __gmlc_struct_get(env.envSymbols, _callee.name);
				var _feather = (_entry != undefined) ? _entry[$ "feather"] : undefined;
				var _parameters = is_struct(_feather) ? _feather[$ "parameters"] : undefined;
				if (!is_array(_parameters)) return;
				var _required = 0;
				var _variadic = false;
				var _p = 0; repeat (array_length(_parameters)) {
					var _parameter = _parameters[_p];
					if (_parameter.name == "...") {
						_variadic = true;
					}
					else if (!_parameter.optional) {
						_required = _p + 1;
					}
				_p++}
				var _count = array_length(_call.args);
				// a function that takes any number of arguments is not held to its listed ones (`max()` compiles)
				if (_variadic) return;
				if (_count < _required) {
					__report("GMLC3003", _call, [_callee.name, string(_required), string(_count)]);
				}
				else if (_count > array_length(_parameters)) {
					__report("GMLC3002", _call, [_callee.name, string(array_length(_parameters)), string(_count)]);
				}
			break;}
			case "Global": {
				var _declaration = __gmlc_struct_get(functionNodes, _callee.name);
				if (_declaration != undefined) && (_declaration.kind == __GMLC_NodeKind_ConstructorDecl) {
					__report("GMLC2109", _call, [_callee.name]);
				}
			break;}
		}
	};
	
	// `new` on a known function that is not a constructor
	static __checkNew = function(_new) {
		var _callee = _new.callee;
		if (_callee.kind != __GMLC_NodeKind_Identifier) return;
		var _known = false;
		switch (_callee.symbol.kind) {
			case "BuiltinFunction": _known = __isBuiltinFunction(_callee.name); break;
			case "Global": {
				var _declaration = __gmlc_struct_get(functionNodes, _callee.name);
				_known = (_declaration != undefined) && (_declaration.kind == __GMLC_NodeKind_FunctionDecl);
			break;}
		}
		if (_known) __report("GMLC2108", _new, [_callee.name]);
	};
	
	#region jsDoc
	/// @func    __checkWrite(_target, _isUpdate)
	/// @desc    Reports an assignment (`=`, `+=`, ...) or a `++`/`--` of what cannot change, with GameMaker's
	///          verdicts; a write to a global function's name becomes a write to the instance variable.
	/// @self    GMLC_Gen_3_Resolver
	/// @param   {Struct.ASTNode} _target   : The target
	/// @param   {Bool}           _isUpdate : Whether it is `++`/`--`
	#endregion
	static __checkWrite = function(_target, _isUpdate) {
		if (_target.kind == __GMLC_NodeKind_Literal) {
			// a macro's or enum member's value: the message names what was written, not the value
			var _origin = _target.origin;
			var _written = _target.lexeme;
			if (_origin != undefined) {
				_written = (_origin.kind == "enum") ? (_origin.name + "." + _origin.member) : _origin.name;
			}
			if (_origin != undefined) && (_origin.kind == "enum") {
				__report("GMLC2205", _target, [_written]);
			}
			else if (_isUpdate) {
				__report("GMLC2206", _target, [_written]);
			}
			else {
				__report("GMLC2201", _target, [_written]);
			}
			return;
		}
		if (_target.kind == __GMLC_NodeKind_Index) {
			// an enum member is a constant
			if (_target.accessor == "Dot") && (_target.object.kind == __GMLC_NodeKind_Identifier)
			&& (_target.object.symbol != undefined) && (_target.object.symbol.kind == "Enum") {
				__report("GMLC2205", _target, [_target.object.name + "." + _target.member]);
				return;
			}
			// a write through an accessor of a name known when compiling (`_GMFILE_[0] = 1`) is refused too
			var _base = _target.object;
			while (_base.kind == __GMLC_NodeKind_Index) _base = _base.object;
			if (_base.kind == __GMLC_NodeKind_Identifier) && (_base.symbol != undefined) && (_base.symbol.kind == "BuiltinVar")
			&& __isCompileTime(env.envSymbols[$ _base.name]) {
				__report("GMLC2203", _base, [_base.name]);
			}
			return;
		}
		if (_target.kind != __GMLC_NodeKind_Identifier) return;
		var _symbol = _target.symbol;
		switch (_symbol.kind) {
			case "BuiltinConstant": {
				__report(_isUpdate ? "GMLC2206" : "GMLC2201", _target, [_target.name]);
			break;}
			case "BuiltinFunction": {
				// a script of the game is like a global function of the batch; a built-in function is read-only, and
				// `++`/`--` on one compile in GameMaker but fail when they run
				if (__isBuiltinFunction(_target.name)) {
					__report(_isUpdate ? "GMLC2207" : "GMLC2204", _target, [_target.name]);
				}
				else {
					_target.symbol = __symbol("Self", _target.name);
				}
			break;}
			case "Enum": {
				__report("GMLC2205", _target, [_target.name]);
			break;}
			case "BuiltinVar": {
				if (__isCompileTime(env.envSymbols[$ _target.name])) {
					__report("GMLC2203", _target, [_target.name]);
					break;
				}
				// read-only in GameMaker's data (the exposed variables are global ones, which GameMaker refuses to set)
				var _spec = __gmlc_struct_get(__GmlSpec(), _target.name);
				var _feather = (_spec != undefined) ? _spec[$ "feather"] : undefined;
				if (_feather != undefined) && (_feather[$ "canWrite"] == false) {
					__report("GMLC2202", _target, [_target.name]);
				}
			break;}
			case "Global": {
				// a function's name: GameMaker writes the instance variable and the name still reads the function
				if (__gmlc_struct_has(functionNodes, _target.name)) _target.symbol = __symbol("Self", _target.name);
			break;}
		}
	};
	
	// a diagnostic at a node; its severity is the catalogue's
	static __report = function(_code, _at, _args = undefined, _messageId = _code) {
		array_push(diagnostics, new GMLC_Diagnostic(_code, _at.span, _args, _messageId));
	};
	#endregion
}
#endregion

#region jsDoc
/// @func    __gmlc_argument_index(_name)
/// @desc    The number of `argument0` to `argument15`, or -1 for any other name.
/// @param   {String} _name : The name
/// @returns {Real}
#endregion
function __gmlc_argument_index(_name) {
	var _length = string_length(_name);
	if (_length < 9) || (_length > 10) || (string_copy(_name, 1, 8) != "argument") return -1;
	var _digits = string_delete(_name, 1, 8);
	if (_digits == "") || (string_length(_digits) > 2) || (string_digits(_digits) != _digits) return -1;
	var _index = real(_digits);
	return (_index <= 15) ? _index : -1;
}
