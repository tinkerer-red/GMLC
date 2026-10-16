#region jsDoc
/// @func    GMLC_Gen_4_Lower(_env)
/// @desc    The lowering stage, one walk over the resolved tree: completes the functions table (fn_kind,
///          registration, binding), replaces compile-time names (`_GMLINE_`, `_GMFILE_`, `_GMFUNCTION_`, ...)
///          with their values and reports statics that read their own function's locals; resolveEnums then
///          gives every enum member its value. Lowering never moves, adds or removes a statement.
/// @param   {Struct.GMLC_Env} _env : The environment whose exposed variables are read
/// @returns {Struct.GMLC_Gen_4_Lower}
#endregion
function GMLC_Gen_4_Lower(_env) constructor {
	#region Init
	env = _env;
	
	ast = undefined;
	sources = undefined;
	file_name = "";
	diagnostics = [];
	__function_nodes = [];
	__gm_names = [];   // `_GMFUNCTION_` of each function, by fn_id
	__gm_chains = [];  // what each function adds to the names of the functions inside it
	__returns = [];   // return statements of each function, nested functions left out
	__structs = [];   // innermost last
	__struct_count = 0;
	__script_name = undefined;
	__member_spans = {};
	#endregion

	#region Public
	#region jsDoc
	/// @func    initialize(_ast, [_sources])
	/// @desc    Prepares the lowering of one resolved file.
	/// @self    GMLC_Gen_4_Lower
	/// @param   {Struct.ASTScript}        _ast      : The resolved tree
	/// @param   {Struct.GMLC_SourceTable} [_sources] : The compile's files, for the positions given to the names
	#endregion
	static initialize = function(_ast, _sources = undefined) {
		ast = _ast;
		sources = _sources;
		diagnostics = [];
		__function_nodes = array_create(array_length(_ast.functions), undefined);
		var _file = (sources != undefined) && (ast.span.file < array_length(sources.files)) ? sources.files[ast.span.file] : undefined;
		file_name = (_file != undefined) ? _file.name : "";
		__gm_names = array_create(array_length(_ast.functions), undefined);
		__gm_chains = array_create(array_length(_ast.functions), undefined);
		__returns = array_create(array_length(_ast.functions), 0);
		__structs = [];
		__struct_count = 0;
		__script_name = undefined;
	};

	#region jsDoc
	/// @func    parseAll()
	/// @desc    Lowers the whole file: classifies and names its functions, counts their facts and replaces compile-time
	///          names.
	/// @self    GMLC_Gen_4_Lower
	/// @returns {Struct.ASTScript} The same tree, lowered
	#endregion
	static parseAll = function() {
		ast.enum_refs = [];
		ast.switches = []; // their labels are checked once enum values are known
		var _body = ast.functions[0];
		__classify(_body, ast, undefined, "none");
		_body.facts = new GMLC_FunctionFacts();
		var _i = 0; repeat (array_length(ast.body)) {
			__visit(ast.body[_i], ast, "body", _i, _body, undefined, undefined);
		_i++}
		__finishFacts(_body, ast.body);
		return ast;
	}
	
	#region jsDoc
	/// @func    cleanup()
	/// @desc    Nothing to release; every stage has the same steps.
	/// @self    GMLC_Gen_4_Lower
	#endregion
	static cleanup = function() {
	
	}
	
	#region jsDoc
	/// @func    resolveEnums(_asts, [_sources])
	/// @desc    Gives every enum member of a batch its int64 value and puts it in place of every `E.M`. Values are
	///          folded repeatedly until nothing changes, so a member may use one declared later or in another file;
	///          a missing value is the previous plus one, a fraction truncates toward zero. Unknown (GMLC0316),
	///          wrongly typed (GMLC0313) and cyclic (GMLC0315) members count as 0.
	/// @self    GMLC_Gen_4_Lower
	/// @param   {Array<Struct.ASTScript>} _asts      : The lowered files of the batch
	/// @param   {Struct.GMLC_SourceTable} [_sources] : The compile's files, for the positions of errors
	/// @returns {Array<Array<Struct.GMLC_Diagnostic>>} The diagnostics of each file, in the order of _asts
	#endregion
	static resolveEnums = function(_asts, _sources = undefined) {
		var _count = array_length(_asts);
		var _diagnostics = array_create(_count);
		var _values = {};  // enum name to {member name: int64}
		var _entries = [];
		__member_spans = {};
		var _a = 0; repeat (_count) {
			_diagnostics[_a] = [];
			var _enums = _asts[_a].enums;
			var _e = 0; repeat (array_length(_enums)) {
				var _decl = _enums[_e];
				// a second enum of a name was reported by the preprocessor; the first one counts
				if (!__gmlc_struct_has(_values, _decl.name)) {
					_values[$ _decl.name] = {};
					var _spans = {};
					__member_spans[$ _decl.name] = _spans;
					var _m = 0; repeat (array_length(_decl.members)) {
						if (!__gmlc_struct_has(_spans, _decl.members[_m].name)) _spans[$ _decl.members[_m].name] = _decl.members[_m].span;
						array_push(_entries, {
							file: _a, decl: _decl, member: _decl.members[_m],
							previous: (_m > 0) ? _decl.members[_m - 1] : undefined, done: false,
						});
					_m++}
				}
			_e++}
		_a++}
		
		var _left = array_length(_entries);
		// one try around all the folding: a member that throws is kept as failing and the loop resumes from its
		// locals, so the try is entered again only then
		env.optimizer.foldBegin();
		var _resolved = false;
		while (!_resolved) {
			try {
				while (_left > 0) {
					var _changed = true;
					while (_changed) {
						_changed = false;
						var _i = 0; repeat (array_length(_entries)) {
							var _entry = _entries[_i];
							if (!_entry.done) && __enumValue(_entry, _values, _sources) {
								_entry.done = true;
								_left--;
								_changed = true;
							}
						_i++}
					}
					if (_left == 0) break;
					
					// the first member that does not wait for another one has a value that is not known; when every one
					// left waits for another, they need each other
					var _pick = undefined;
					var _cycle = true;
					var _i = 0; repeat (array_length(_entries)) {
						var _entry = _entries[_i];
						if (!_entry.done) {
							var _waits = (_entry.member.init == undefined) || __waitsForMember(_entry.member.init, _values);
							if (!_waits) {
								_pick = _entry;
								_cycle = false;
								break;
							}
							_pick ??= _entry;
						}
					_i++}
					var _code = _cycle ? "GMLC0315" : ((_pick[$ "not_integer"] == true) ? "GMLC0313" : "GMLC0316");
					var _args = (_code == "GMLC0313") ? undefined : [_pick.decl.name, _pick.member.name];
					var _span = _pick.member.span;
					array_push(_diagnostics[_pick.file], new GMLC_Diagnostic(_code, new GMLC_Span(_span.file, _span.start, _span.start + string_byte_length(_pick.member.name)), _args));
					_values[$ _pick.decl.name][$ _pick.member.name] = int64(0);
					_pick.member.value = int64(0);
					_pick.done = true;
					_left--;
				}
				_resolved = true;
			}
			catch (_e) {
				env.optimizer.foldCaught(_e);
			}
		}
		env.optimizer.foldEnd();
		
		// a tree lowered elsewhere has no recorded references, so it is walked
		var _a = 0; repeat (_count) {
			var _refs = _asts[_a][$ "enum_refs"];
			if (_refs == undefined) {
				__placeEnumValues(_asts[_a], _values);
			}
			else {
				var _r = 0; repeat (array_length(_refs)) {
					var _ref = _refs[_r];
					var _literal = __enumLiteral(_ref.node, _values);
					if (_literal != undefined) __gmlc_ext_set_child(_ref.parent, _ref.key, _ref.index, _literal);
				_r++}
				__checkCaseLabels(_asts[_a], _diagnostics[_a]);
			}
			var _enums = _asts[_a].enums;
			var _e = 0; repeat (array_length(_enums)) {
				var _members = _enums[_e].members;
				var _m = 0; repeat (array_length(_members)) {
					if (_members[_m].init != undefined) _members[_m].init = __placeEnumValues(_members[_m].init, _values);
				_m++}
			_e++}
		_a++}
		return _diagnostics;
	};
	
	#region jsDoc
	/// @func    compileTimeContext(_node, _slot, _info)
	/// @desc    The context a compile-time variable's compileTimeGet reads: where the name is (file, function, line) and
	///          the nodes around it.
	/// @self    GMLC_Gen_4_Lower
	/// @param   {Struct.ASTNode}           _node : The name
	/// @param   {Struct}                   _slot : {parent, key, index} where the name sits, or undefined
	/// @param   {Struct.GMLC_FunctionInfo} _info : The function the name is in
	/// @returns {Struct}
	#endregion
	static compileTimeContext = function(_node, _slot, _info) {
		var _at = (sources != undefined) ? sources.position(_node.span) : { fileName: file_name, line: 0, column: 0, lineString: "" };
		var _span = _node.span;
		var _function = __function_nodes[_info.fn_id];
		// a script's own code outside functions is `gml_GlobalScript_<script>`, an object event's
		// `gml_Object_<object>_<event>`
		var _functionName = (_function != undefined) ? (__gm_names[_info.fn_id] ?? _function.name)
			: ((ast[$ "unit_kind"] != "event") ? "gml_GlobalScript_" + __scriptNameOf() : "gml_Object_" + __eventName());
		var _sourceInfo = {
			fileName: _at.fileName,
			functionName: _functionName,
			lineString: _at.lineString,
			line: _at.line,
			column: _at.column,
			byteStart: _span.start,
			byteEnd: _span[$ "end"],
		};
		return {
			env: env,
			program: ast,
			ast: ast,
			scriptAST: ast,
			currentScript: ast,
			currentFunction: _function,
			currentNode: _node,
			parentNode: (_slot != undefined) ? _slot.parent : undefined,
			parentKey: (_slot != undefined) ? _slot.key : undefined,
			parentIndex: (_slot != undefined) ? _slot.index : undefined,
			sourceInfo: _sourceInfo,
			currentSourceName: _at.fileName,
			currentLine: _at.line,
			currentColumn: _at.column,
			currentByteStart: _span.start,
			currentByteEnd: _span[$ "end"],
			currentLineString: _at.lineString,
			fileName: _at.fileName,
			functionName: _functionName,
			line: _at.line,
			column: _at.column,
			byteStart: _span.start,
			byteEnd: _span[$ "end"],
			lineString: _at.lineString,
			scope: _node.symbol.kind,
		};
	}
	
	#region jsDoc
	/// @func    isCompileTimeConstantVariable(_value)
	/// @desc    Whether an exposed variable is replaced by its value at compile time (`_GMLINE_`, `_GMFILE_`, ...).
	/// @self    GMLC_Gen_4_Lower
	/// @param   {Any} _value : The variable's exposed value
	/// @returns {Bool}
	#endregion
	static isCompileTimeConstantVariable = function(_value) {
		return is_struct(_value)
		&& struct_exists(_value, "compileTimeConstant")
		&& _value.compileTimeConstant
		&& struct_exists(_value, "compileTimeGet");
	}
	#endregion

	#region Private
	#region Functions
	#region jsDoc
	/// @func    __visit(_node, _parent, _key, _index, _info, _role, _static)
	/// @desc    Lowers a node and its children, counting them into the facts of the function they are in.
	/// @self    GMLC_Gen_4_Lower
	/// @param   {Struct.ASTNode}          _node   : The node
	/// @param   {Struct.ASTNode}          _parent : The node that holds it
	/// @param   {String}                  _key    : The field of _parent that holds it
	/// @param   {Real}                    _index  : Its index in that field, undefined for a field of one node
	/// @param   {Struct.GMLC_FunctionInfo} _info  : The function the node is in
	/// @param   {String}                  _role   : "struct_value" or "static_value" when the node is that, else undefined
	/// @param   {String}                  _static : The static whose initializer the node is in, else undefined
	#endregion
	static __visit = function(_node, _parent, _key, _index, _info, _role, _static) {
		var _facts = _info.facts;
		_facts.node_count++;
		// an Empty is a statement only in a statement list, not as an argument hole
		if (__statementKinds[_node.kind]) || ((_node.kind == __GMLC_NodeKind_Empty) && (_key == "body")) _facts.statement_count++;
		
		switch (_node.kind) {
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_FunctionExpr: {
				// a nested function counts as one node of the function around it; its own body has its own facts
				_facts.has_nested_functions = true;
				var _inner = ast.functions[_node.fn_id];
				__function_nodes[_node.fn_id] = _node;
				__classify(_inner, _node, _info, _role);
				__nameFunction(_inner, _node, _info, _role, _static);
				_inner.facts = new GMLC_FunctionFacts();
				// defaults and the parent call are outside the body: what they use is the function's, but they are
				// not counted into the body's statements and nodes
				var _head = { fn_id: _inner.fn_id, facts: new GMLC_FunctionFacts() };
				var _p = 0; repeat (array_length(_node.params)) {
					var _default = _node.params[_p][$ "default"];
					if (_default != undefined) __visit(_default, _node.params[_p], "default", undefined, _head, undefined, undefined);
				_p++}
				var _parentCall = _node[$ "parent"];
				if (_parentCall != undefined) __visit(_parentCall, _node, "parent", undefined, _head, undefined, undefined);
				var _to = _inner.facts;
				var _from = _head.facts;
				_to.uses_argument_array = _to.uses_argument_array || _from.uses_argument_array;
				_to.uses_argument_count = _to.uses_argument_count || _from.uses_argument_count;
				_to.max_argument_index = max(_to.max_argument_index, _from.max_argument_index);
				_to.has_nested_functions = _to.has_nested_functions || _from.has_nested_functions;
				_to.reads_other = _to.reads_other || _from.reads_other;
				_to.uses_compile_time_names = _to.uses_compile_time_names || _from.uses_compile_time_names;
				var _body = _node.body.body;
				var _s = 0; repeat (array_length(_body)) {
					__visit(_body[_s], _node.body, "body", _s, _inner, undefined, undefined);
				_s++}
				__finishFacts(_inner, _body);
			return;}
			case __GMLC_NodeKind_Identifier: {
				__identifier(_node, _parent, _key, _index, _info, _static);
			return;}
			case __GMLC_NodeKind_StructEntry: {
				__visit(_node.value, _node, "value", undefined, _info, "struct_value", _static);
			return;}
			case __GMLC_NodeKind_StaticDecl: {
				var _d = 0; repeat (array_length(_node.declarations)) {
					var _decl = _node.declarations[_d];
					_facts.node_count++;
					__visit(_decl.target, _decl, "target", undefined, _info, undefined, undefined);
					if (_decl.init != undefined) __visit(_decl.init, _decl, "init", undefined, _info, "static_value", _decl.target.name);
				_d++}
			return;}
			case __GMLC_NodeKind_StructLiteral: array_push(__structs, __struct_count++); break;
			case __GMLC_NodeKind_Switch: array_push(ast.switches, _node); break;
			case __GMLC_NodeKind_Index: {
				if (_node.accessor == "Dot") && (_node.object.kind == __GMLC_NodeKind_Identifier)
				&& (_node.object.symbol != undefined) && (_node.object.symbol.kind == "Enum") {
					array_push(ast.enum_refs, { parent: _parent, key: _key, index: _index, node: _node });
				}
			break;}
			case __GMLC_NodeKind_With: _facts.contains_with = true; break;
			case __GMLC_NodeKind_Exit: _facts.contains_exit = true; break;
			case __GMLC_NodeKind_Try: _facts.contains_try = true; break;
			case __GMLC_NodeKind_Return: __returns[_info.fn_id]++; break;
			case __GMLC_NodeKind_Call: {
				var _callee = _node.callee;
				// only a global function is reached by its own name
				if (_callee.kind == __GMLC_NodeKind_Identifier) && (_callee.symbol != undefined) && (_callee.symbol.kind == "Global")
				&& (_info[$ "registration"] == "global") && (_callee.name == _info.name) {
					_facts.direct_recursion = true;
				}
			break;}
		}
		
		// through the fields, so a replaced name goes back into its place
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _field = _fields[_f];
			var _value = _node[$ _field];
			if (is_array(_value)) {
				var _c = 0; repeat (array_length(_value)) {
					if (_value[_c] != undefined) __visit(_value[_c], _node, _field, _c, _info, undefined, _static);
				_c++}
			}
			else if (_value != undefined) {
				__visit(_value, _node, _field, undefined, _info, undefined, _static);
			}
		_f++}
		if (_node.kind == __GMLC_NodeKind_StructLiteral) array_pop(__structs);
	};
	
	#region jsDoc
	/// @func    __nameFunction(_inner, _node, _outer, _role, _static)
	/// @desc    GameMaker's name of a function, the value of `_GMFUNCTION_` in it: `gml_Script_<name>` for a
	///          global function, else `gml_Script_<own part>@<outer parts>@<script>`. A part is the name, or
	///          `anon@<byte offset>` for a function expression, plus `@___struct___<n>` for a struct literal's
	///          method and a `<name>@` prefix for a static's function.
	/// @self    GMLC_Gen_4_Lower
	#endregion
	static __nameFunction = function(_inner, _node, _outer, _role, _static) {
		// the function around it is always named first; the file's body adds the script's name
		if (_inner.registration == "global") {
			__gm_names[_inner.fn_id] = "gml_Script_" + _node.name;
			__gm_chains[_inner.fn_id] = _node.name + "@" + __scriptNameOf();
			return;
		}
		var _own = (_node.kind == __GMLC_NodeKind_FunctionExpr) ? "anon@" + string(_node.span.start) : _node.name;
		if (_role == "struct_value") && (array_length(__structs) > 0) _own += "@___struct___" + string(__structs[array_length(__structs) - 1]);
		if (_role == "static_value") && (_static != undefined) _own = _static + "@" + _own;
		__gm_chains[_inner.fn_id] = _own + "@" + (__gm_chains[_outer.fn_id] ?? __scriptNameOf());
		__gm_names[_inner.fn_id] = "gml_Script_" + __gm_chains[_inner.fn_id];
	};

	static __statementKinds = (function() {
		var _kinds = array_create(__GMLC_NodeKind_SIZE, false);
		var _list = [
			__GMLC_NodeKind_FunctionDecl, __GMLC_NodeKind_ConstructorDecl, __GMLC_NodeKind_StaticDecl,
			__GMLC_NodeKind_VarDeclList, __GMLC_NodeKind_GlobalVarDecl, __GMLC_NodeKind_If,
			__GMLC_NodeKind_For, __GMLC_NodeKind_While, __GMLC_NodeKind_Repeat, __GMLC_NodeKind_DoUntil,
			__GMLC_NodeKind_With, __GMLC_NodeKind_Switch, __GMLC_NodeKind_Try, __GMLC_NodeKind_Break,
			__GMLC_NodeKind_Continue, __GMLC_NodeKind_Exit, __GMLC_NodeKind_Return, __GMLC_NodeKind_Throw,
			__GMLC_NodeKind_Delete, __GMLC_NodeKind_ExprStmt,
		];
		var _i = 0; repeat (array_length(_list)) {
			_kinds[_list[_i]] = true;
		_i++}
		return _kinds;
	})();
	
	#region jsDoc
	/// @func    __identifier(_node, _parent, _key, _index, _info, _static)
	/// @desc    The facts a name gives, a static reading a local, and the replacement of a compile-time name.
	/// @self    GMLC_Gen_4_Lower
	#endregion
	static __identifier = function(_node, _parent, _key, _index, _info, _static) {
		var _facts = _info.facts;
		var _name = _node.name;
		var _symbol = _node.symbol;
		if (_symbol == undefined) return;
		if (_symbol.kind == "BuiltinVar") {
			switch (_name) {
				case "argument": _facts.uses_argument_array = true; break;
				case "argument_count": _facts.uses_argument_count = true; break;
				case "other": _facts.reads_other = true; break;
				default: _facts.max_argument_index = max(_facts.max_argument_index, __gmlc_argument_index(_name)); break;
			}
		}
		
		// statics initialize at entry: a local other than a parameter is not set yet
		if (_static != undefined) && (_symbol.kind == "Local") && (_symbol.slot >= array_length(_info.params)) {
			array_push(diagnostics, new GMLC_Diagnostic("GMLC2301", _node.span, [_static, _name]));
		}
		
		if (_symbol.kind != "BuiltinVar") return;
		var _variable = env.getVariable(_name);
		if (_variable == undefined) || !isCompileTimeConstantVariable(_variable.value) return;
		// a name whose value is the function's own place (its file or name) would change if the code moved
		if (_variable.value[$ "valueOfPlace"] == true) _facts.uses_compile_time_names = true;
		var _slot = { parent: _parent, key: _key, index: _index };
		var _value = _variable.value.compileTimeGet(compileTimeContext(_node, _slot, _info));
		var _type = "real";
		if (is_string(_value)) _type = "string";
		else if (is_bool(_value)) _type = "bool";
		else if (is_int64(_value)) _type = "int64";
		else if (is_undefined(_value)) _type = "undefined";
		var _lexeme = is_string(_value) ? json_stringify(_value) : string(_value);
		__gmlc_ext_set_child(_parent, _key, _index, new ASTLiteral(_node.span, _type, _lexeme, _value,
			new GMLC_Origin("compile_time", _name, undefined, undefined, undefined, _node.span)));
	};
	
	#region jsDoc
	/// @func    __classify(_info, _node, _outer, _role)
	/// @desc    What a function is, how it becomes reachable and which `self` it runs with, from where it is declared
	///          (units are scripts).
	/// @self    GMLC_Gen_4_Lower
	/// @param   {Struct.GMLC_FunctionInfo} _info  : The function's entry
	/// @param   {Struct.ASTNode}           _node  : Its node (the Script for the file's body)
	/// @param   {Struct.GMLC_FunctionInfo} _outer : The function around it, undefined for the file's body
	/// @param   {String}                   _role  : "struct_value" or "static_value" when the function is that
	#endregion
	static __classify = function(_info, _node, _outer, _role) {
		var _kind = "method";
		var _registration = "value";
		var _binding = "creator_self";
		switch (_node.kind) {
			case __GMLC_NodeKind_Script: {
				_kind = "unit_body";
				_registration = "none";
				_binding = "none";
			break;}
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl: {
				var _constructor = (_node.kind == __GMLC_NodeKind_ConstructorDecl);
				if (_outer.fn_id == 0) && (ast[$ "unit_kind"] != "event") {
					_kind = _constructor ? "constructor" : "script_function";
					_registration = "global";
					_binding = "none";
				}
				else {
					// declared inside a function or at the top of an object event: a method of `self` there
					_kind = _constructor ? "constructor" : "method";
					_registration = "instance";
					_binding = _constructor ? "none" : "creator_self";
				}
			break;}
			case __GMLC_NodeKind_FunctionExpr: {
				if (_node.is_constructor) {
					_kind = "constructor";
					_binding = "none";
				}
				else if (_role == "struct_value") {
					_binding = "new_struct";
				}
				else if (_role == "static_value") || (_outer.fn_id == 0) {
					_binding = "none";
				}
			break;}
		}
		_info.fn_kind = _kind;
		_info.registration = _registration;
		_info.binding = _binding;
	};
	
	#region jsDoc
	/// @func    __finishFacts(_info, _body)
	/// @desc    The facts of a function known only once its body was walked: statics and a single trailing return.
	/// @self    GMLC_Gen_4_Lower
	/// @param   {Struct.GMLC_FunctionInfo} _info : The function
	/// @param   {Array<Struct.ASTNode>}    _body : Its statements
	#endregion
	static __finishFacts = function(_info, _body) {
		var _facts = _info.facts;
		_facts.has_statics = (array_length(_info.statics) > 0);
		var _count = array_length(_body);
		if (_count > 0) && (_body[_count - 1].kind == __GMLC_NodeKind_Return) {
			_facts.single_trailing_return = (__returns[_info.fn_id] == 1);
		}
	};
	
	#region jsDoc
	/// @func    __scriptNameOf()
	/// @desc    The script's name: the file's name without folders or extension.
	/// @self    GMLC_Gen_4_Lower
	/// @returns {String}
	#endregion
	static __scriptNameOf = function() {
		if (__script_name == undefined) {
			__script_name = filename_name(string_replace_all(file_name, "\\", "/"));
			var _dot = string_last_pos(".", __script_name);
			if (_dot > 0) __script_name = string_copy(__script_name, 1, _dot - 1);
		}
		return __script_name;
	};
	
	#region jsDoc
	/// @func    __eventName()
	/// @desc    An object event's file as GameMaker names it, `<object>_<event>`: the object is the folder
	///          the file is in (`objects/Object1/Create_0.gml`) or the part before `::` (`Object1::Create_0.gml`).
	/// @self    GMLC_Gen_4_Lower
	#endregion
	static __eventName = function() {
		var _parts = string_split(string_replace_all(string_replace_all(file_name, "\\", "/"), "::", "/"), "/", true);
		var _count = array_length(_parts);
		var _event = _parts[_count - 1];
		var _dot = string_last_pos(".", _event);
		if (_dot > 0) _event = string_copy(_event, 1, _dot - 1);
		return (_count >= 2) ? _parts[_count - 2] + "_" + _event : _event;
	};
	#endregion
	
	#region Enums
	#region jsDoc
	/// @func    __enumValue(_entry, _values, _sources)
	/// @desc    Finds a member's value when every member it uses is known.
	/// @self    GMLC_Gen_4_Lower
	/// @returns {Bool} Whether it was found
	#endregion
	static __enumValue = function(_entry, _values, _sources) {
		var _member = _entry.member;
		var _value;
		if (_member.init == undefined) {
			if (_entry.previous == undefined) {
				_value = int64(0);
			}
			else {
				var _previous = __gmlc_struct_get(_values[$ _entry.decl.name], _entry.previous.name);
				if (_previous == undefined) return false;
				_value = int64(_previous + 1);
			}
		}
		else {
			if (__waitsForMember(_member.init, _values)) return false;
			_member.init = __placeEnumValues(_member.init, _values);
			_member.init = env.optimizer.foldExpression(_member.init, _sources);
			// a Literal or a built-in constant (not the `GM_` facts of a build)
			var _init = _member.init;
			if (_init.kind == __GMLC_NodeKind_Literal) {
				_value = _init.value;
			}
			else if (_init.kind == __GMLC_NodeKind_Identifier) && (_init.symbol != undefined) && (_init.symbol.kind == "BuiltinConstant")
			&& (string_copy(_init.name, 1, 3) != "GM_") {
				var _data = env.getConstant(_init.name);
				if (_data == undefined) return false;
				_value = _data.value;
			}
			else return false;
			_value = __enumInteger(_value);
			if (_value == undefined) {
				_entry.not_integer = true;
				return false;
			}
		}
		_member.value = _value;
		_values[$ _entry.decl.name][$ _member.name] = _value;
		return true;
	};
	
	#region jsDoc
	/// @func    __waitsForMember(_node, _values)
	/// @desc    Whether an expression uses an enum member of the batch whose value is not known yet.
	/// @self    GMLC_Gen_4_Lower
	/// @param   {Struct.ASTNode} _node   : The expression
	/// @param   {Struct}         _values : Enum name to {member name: value} found so far
	/// @returns {Bool}
	#endregion
	static __waitsForMember = function(_node, _values) {
		if (_node.kind == __GMLC_NodeKind_Index) && (_node.accessor == "Dot") && (_node.object.kind == __GMLC_NodeKind_Identifier)
		&& (_node.object.symbol != undefined) && (_node.object.symbol.kind == "Enum") && __gmlc_struct_has(_values, _node.object.name) {
			return !__gmlc_struct_has(_values[$ _node.object.name], _node.member);
		}
		var _children = _node.children();
		var _i = 0; repeat (array_length(_children)) {
			if (__waitsForMember(_children[_i], _values)) return true;
		_i++}
		return false;
	};
	
	#region jsDoc
	/// @func    __enumInteger(_value)
	/// @desc    A member's int64 from a folded number or bool, a fraction truncated toward zero; undefined
	///          for any other value.
	/// @self    GMLC_Gen_4_Lower
	#endregion
	static __enumInteger = function(_value) {
		if (is_bool(_value)) return int64(_value ? 1 : 0);
		if (is_int64(_value)) return _value;
		if (!is_numeric(_value)) || is_nan(_value) || is_infinity(_value) || (abs(_value) >= 9223372036854775807) return undefined;
		return int64((_value < 0) ? ceil(_value) : floor(_value));
	};
	
	#region jsDoc
	/// @func    __placeEnumValues(_node, _values)
	/// @desc    Puts the value of every known `E.M` in an expression in its place.
	/// @self    GMLC_Gen_4_Lower
	/// @param   {Struct.ASTNode} _node   : The expression
	/// @param   {Struct}         _values : Enum name to {member name: value} found so far
	/// @returns {Struct.ASTNode} The expression, or the Literal that replaces it
	#endregion
	static __placeEnumValues = function(_node, _values) {
		var _literal = __enumLiteral(_node, _values);
		if (_literal != undefined) return _literal;
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _slot = _slots[_i];
			var _new = __placeEnumValues(_slot.node, _values);
			if (_new != _slot.node) __gmlc_ext_set_child(_node, _slot.key, _slot.index, _new);
		_i++}
		return _node;
	};
	
	#region jsDoc
	/// @func    __enumLiteral(_node, _values)
	/// @desc    The int64 Literal of an `E.M`, of the batch or exposed, whose value is known; else undefined.
	/// @self    GMLC_Gen_4_Lower
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct}         _values : Enum name to {member name: value} found so far
	/// @returns {Struct.ASTLiteral}
	#endregion
	static __enumLiteral = function(_node, _values) {
		if (_node.kind != __GMLC_NodeKind_Index) || (_node.accessor != "Dot") || (_node.object.kind != __GMLC_NodeKind_Identifier) return undefined;
		var _symbol = _node.object.symbol;
		if (_symbol == undefined) || (_symbol.kind != "Enum") return undefined;
		var _name = _node.object.name;
		var _value;
		if (__gmlc_struct_has(_values, _name)) {
			_value = __gmlc_struct_get(_values[$ _name], _node.member);
			if (_value == undefined) return undefined;
		}
		else {
			var _enum = env.getEnum(_name);
			if (_enum == undefined) || !is_struct(_enum.value) return undefined;
			_value = _enum.value[$ _node.member];
			if (!is_numeric(_value)) return undefined;
			_value = int64(_value);
		}
		// undefined for an exposed enum
		var _spans = __gmlc_struct_get(__member_spans, _name);
		var _defSpan = (_spans != undefined) ? __gmlc_struct_get(_spans, _node.member) : undefined;
		return new ASTLiteral(_node.span, "int64", _name + "." + _node.member, _value, new GMLC_Origin("enum", _name, _node.member, undefined, _defSpan, _node.span));
	};
	
	#region jsDoc
	/// @func    __checkCaseLabels(_ast, _list)
	/// @desc    Reports switch labels of the same value; as in GameMaker, only constant labels are compared.
	/// @self    GMLC_Gen_4_Lower
	#endregion
	static __checkCaseLabels = function(_ast, _list) {
		var _switches = _ast[$ "switches"] ?? [];
		var _s = 0; repeat (array_length(_switches)) {
			var _seen = {};
			var _cases = _switches[_s].cases;
			var _c = 0; repeat (array_length(_cases)) {
				var _test = _cases[_c][$ "test"];
				if (_test != undefined) && (_test.kind == __GMLC_NodeKind_Literal) {
					var _value = _test.value;
					var _key = is_string(_value) ? "s:" + _value : (is_numeric(_value) ? "n:" + string_format(real(_value), 0, 17) : undefined);
					if (_key != undefined) {
						if (struct_exists(_seen, _key)) {
							array_push(_list, new GMLC_Diagnostic("GMLC2302", _test.span, [_test.lexeme]));
						}
						_seen[$ _key] = true;
					}
				}
			_c++}
		_s++}
	};
	#endregion
	#endregion
}

