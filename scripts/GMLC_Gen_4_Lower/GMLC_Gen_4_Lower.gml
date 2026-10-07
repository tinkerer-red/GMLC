#region Lower.gml
	#region Lower Module
	/*
	Purpose: lowering, the stage after the resolver. One walk over the resolved tree:
	- completes the file's `functions` table: what each function is (`fn_kind`), how it becomes reachable
	  (`registration`), which `self` a call runs with (`binding`), decided by where it is declared, and the facts the
	  optimizer and the backends read instead of walking bodies again;
	- replaces the names whose value is known when compiling (`_GMLINE_`, `_GMFILE_`, `_GMFUNCTION_` and the other
	  compile-time variables the environment exposes) by their value; writes to them are refused by the resolver;
	- reports a static whose initialiser reads a local of its own function (GMLC2301): statics initialise when the
	  function is entered, before the body has set any local.
	Once every file of a batch is lowered, resolveEnums gives each enum member its value and puts the values in place
	of every `E.M` (enums exist only while compiling).
	The tree keeps every statement where the user wrote it: lowering never moves, adds or removes one.
	*/
	#endregion
	function GMLC_Gen_4_Lower(_env) constructor {
		env = _env;
		
		ast = undefined;
		sources = undefined;
		fileName = "";
		diagnostics = []; // GMLC_Diagnostic records of this file
		__fnNodes = [];   // the function nodes by fn_id, for the context of a compile-time name
		__gmNames = [];   // GameMaker's name of each function by fn_id, the value of `_GMFUNCTION_`
		__gmChains = [];  // what each function adds to the names of the functions inside it
		__structs = [];   // the numbers of the struct literals being visited, innermost last
		__structCount = 0;
		__scriptName = "";
		__enumDecls = {}; // resolveEnums: the batch's enum declarations by name

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
			__fnNodes = array_create(array_length(_ast.functions), undefined);
			var _file = (sources != undefined) && (ast.span.file < array_length(sources.files)) ? sources.files[ast.span.file] : undefined;
			fileName = (_file != undefined) ? _file.name : "";
			__gmNames = array_create(array_length(_ast.functions), undefined);
			__gmChains = array_create(array_length(_ast.functions), undefined);
			__structs = [];
			__structCount = 0;
			// the script's name: the file name without folders or extension
			__scriptName = filename_name(string_replace_all(fileName, "\\", "/"));
			var _dot = string_last_pos(".", __scriptName);
			if (_dot > 0) __scriptName = string_copy(__scriptName, 1, _dot - 1);
			__gmChains[0] = __scriptName;
		};
		
		static cleanup = function() {
		
		}
		
		static parseAll = function() {
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
		/// @func    __visit(_node, _parent, _key, _index, _info, _role, _static)
		/// @desc    Lowers a node and its children, counting them into the facts of the function they are in.
		/// @self    GMLC_Gen_4_Lower
		/// @param   {Struct.ASTNode}          _node   : The node
		/// @param   {Struct.ASTNode}          _parent : The node that holds it
		/// @param   {String}                  _key    : The field of _parent that holds it
		/// @param   {Real}                    _index  : Its index in that field, undefined for a field of one node
		/// @param   {Struct.GMLC_FunctionInfo} _info  : The function the node is in
		/// @param   {String}                  _role   : "struct_value" or "static_value" when the node is that, else undefined
		/// @param   {String}                  _static : The static whose initialiser the node is in, else undefined
		#endregion
		static __visit = function(_node, _parent, _key, _index, _info, _role, _static) {
			var _facts = _info.facts;
			_facts.node_count++;
			if (__isStatement(_node, _key)) _facts.statement_count++;
			
			switch (_node.kind) {
				case __GMLC_NodeKind_FunctionDecl:
				case __GMLC_NodeKind_ConstructorDecl:
				case __GMLC_NodeKind_FunctionExpr: {
					// a nested function counts as one node of the function around it; its own body has its own facts
					_facts.has_nested_functions = true;
					var _inner = ast.functions[_node.fn_id];
					__fnNodes[_node.fn_id] = _node;
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
					__useFacts(_inner.facts, _head.facts);
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
				case __GMLC_NodeKind_StructLiteral: array_push(__structs, __structCount++); break;
				case __GMLC_NodeKind_With: _facts.contains_with = true; break;
				case __GMLC_NodeKind_Exit: _facts.contains_exit = true; break;
				case __GMLC_NodeKind_Try: _facts.contains_try = true; break;
				case __GMLC_NodeKind_Call: {
					var _callee = _node.callee;
					// only a global function is reached by its own name
					if (_callee.kind == __GMLC_NodeKind_Identifier) && (_callee.symbol != undefined) && (_callee.symbol.kind == "Global")
					&& (_info[$ "registration"] == "global") && (_callee.name == _info.name) {
						_facts.direct_recursion = true;
					}
				break;}
			}
			
			// the children, through the fields that hold them, so a replaced name goes back into its place
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
		/// @desc    GameMaker's name of a function, the value of `_GMFUNCTION_` in it (measured):
		///          `gml_Script_<name>` for a global function; otherwise
		///          `gml_Script_<own part>@<the parts of the functions around it>@<script>`, where a named function's part
		///          is its name, a function expression's is `anon@<byte offset of function>`, followed by
		///          `@___struct___<n>` (the n-th struct literal of the file) for a struct literal's method, and preceded by
		///          `<name>@` for a static's function. The parts of a global function around it are its name.
		/// @self    GMLC_Gen_4_Lower
		#endregion
		static __nameFunction = function(_inner, _node, _outer, _role, _static) {
			if (_inner.registration == "global") {
				__gmNames[_inner.fn_id] = "gml_Script_" + _node.name;
				__gmChains[_inner.fn_id] = _node.name + "@" + __scriptName;
				return;
			}
			var _own = (_node.kind == __GMLC_NodeKind_FunctionExpr) ? "anon@" + string(_node.span.start) : _node.name;
			if (_role == "struct_value") && (array_length(__structs) > 0) _own += "@___struct___" + string(__structs[array_length(__structs) - 1]);
			if (_role == "static_value") && (_static != undefined) _own = _static + "@" + _own;
			var _chain = _own + "@" + (__gmChains[_outer.fn_id] ?? __scriptName);
			__gmNames[_inner.fn_id] = "gml_Script_" + _chain;
			__gmChains[_inner.fn_id] = _chain;
		};
		
		// the facts of what an expression uses, without its counts, added to a function's
		static __useFacts = function(_to, _from) {
			_to.uses_argument_array = _to.uses_argument_array || _from.uses_argument_array;
			_to.uses_argument_count = _to.uses_argument_count || _from.uses_argument_count;
			_to.max_argument_index = max(_to.max_argument_index, _from.max_argument_index);
			_to.has_nested_functions = _to.has_nested_functions || _from.has_nested_functions;
			_to.reads_other = _to.reads_other || _from.reads_other;
			_to.uses_compile_time_names = _to.uses_compile_time_names || _from.uses_compile_time_names;
		};
		
		// whether a node is a statement of a body (an Empty is one only in a statement list, not as an argument hole)
		static __isStatement = function(_node, _key) {
			switch (_node.kind) {
				case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl: case __GMLC_NodeKind_StaticDecl:
				case __GMLC_NodeKind_VarDeclList: case __GMLC_NodeKind_GlobalVarDecl: case __GMLC_NodeKind_If:
				case __GMLC_NodeKind_For: case __GMLC_NodeKind_While: case __GMLC_NodeKind_Repeat: case __GMLC_NodeKind_DoUntil:
				case __GMLC_NodeKind_With: case __GMLC_NodeKind_Switch: case __GMLC_NodeKind_Try: case __GMLC_NodeKind_Break:
				case __GMLC_NodeKind_Continue: case __GMLC_NodeKind_Exit: case __GMLC_NodeKind_Return: case __GMLC_NodeKind_Throw:
				case __GMLC_NodeKind_Delete: case __GMLC_NodeKind_ExprStmt:
				return true;
				case __GMLC_NodeKind_Empty: return (_key == "body");
			}
			return false;
		};
		
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
			
			// statics initialise at entry: a local other than a parameter is not set yet
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
			var _literal = new ASTLiteral(_node.span, __literalType(_value), __literalLexeme(_value), _value,
				new GMLC_Origin("compile_time", _name, undefined, undefined, undefined, _node.span));
			if (_index != undefined) {
				_parent[$ _key][_index] = _literal;
			}
			else {
				_parent[$ _key] = _literal;
			}
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
					if (_outer.fn_id == 0) && (ast[$ "unitKind"] != "event") {
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
		
		// the facts that need the whole body
		static __finishFacts = function(_info, _body) {
			var _facts = _info.facts;
			_facts.has_statics = (array_length(_info.statics) > 0);
			var _count = array_length(_body);
			if (_count > 0) && (_body[_count - 1].kind == __GMLC_NodeKind_Return) {
				_facts.single_trailing_return = (__countReturns(_body) == 1);
			}
		};
		
		// the return statements of a body, nested functions left out
		static __countReturns = function(_nodes) {
			var _count = 0;
			var _i = 0; repeat (array_length(_nodes)) {
				var _node = _nodes[_i];
				switch (_node.kind) {
					case __GMLC_NodeKind_FunctionDecl:
					case __GMLC_NodeKind_ConstructorDecl:
					case __GMLC_NodeKind_FunctionExpr: break;
					case __GMLC_NodeKind_Return: _count += 1 + __countReturns(_node.children()); break;
					default: _count += __countReturns(_node.children()); break;
				}
			_i++}
			return _count;
		};
		
		#region Enums
		#region jsDoc
		/// @func    resolveEnums(_asts, [_sources])
		/// @desc    Gives every enum member of a batch its int64 value and puts the values in place of every `E.M` of
		///          those enums, once every stage before has seen them (a macro, a `const` or a `let` setting in a value
		///          is already a literal). Each value is folded as the optimizer folds constants, with the members known
		///          so far, exposed enums and built-in constants put in first, and this repeats until nothing changes,
		///          so a member may use one declared after it or in another file. A member without a value is the one
		///          before it plus one (0 for the first). A fractional value is truncated toward zero, as in GameMaker.
		///          A value that is still not known is GMLC0316, one of another type GMLC0313, members that need each
		///          other GMLC0315; such a member counts as 0.
		/// @self    GMLC_Gen_4_Lower
		/// @param   {Array<Struct.ASTScript>} _asts      : The lowered files of the batch
		/// @param   {Struct.GMLC_SourceTable} [_sources] : The compile's files, for the positions of errors
		/// @returns {Array<Array<Struct.GMLC_Diagnostic>>} The diagnostics of each file, in the order of _asts
		#endregion
		static resolveEnums = function(_asts, _sources = undefined) {
			var _count = array_length(_asts);
			var _diagnostics = array_create(_count);
			var _values = {};  // enum name to {member name: int64}
			var _entries = []; // every member of the batch, in declaration order
			__enumDecls = {};
			var _a = 0; repeat (_count) {
				_diagnostics[_a] = [];
				var _enums = _asts[_a].enums;
				var _e = 0; repeat (array_length(_enums)) {
					var _decl = _enums[_e];
					// a second enum of a name was reported by the preprocessor; the first one counts
					if (!__gmlc_struct_has(_values, _decl.name)) {
						_values[$ _decl.name] = {};
						__enumDecls[$ _decl.name] = _decl;
						var _m = 0; repeat (array_length(_decl.members)) {
							array_push(_entries, {
								file: _a, decl: _decl, member: _decl.members[_m],
								previous: (_m > 0) ? _decl.members[_m - 1] : undefined, done: false,
							});
						_m++}
					}
				_e++}
			_a++}
			
			var _left = array_length(_entries);
			while (_left > 0) {
				// every member whose value can be found now, again until none can
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
				var _code = _cycle ? "GMLC0315" : ((_pick[$ "notInteger"] == true) ? "GMLC0313" : "GMLC0316");
				var _args = (_code == "GMLC0313") ? undefined : [_pick.decl.name, _pick.member.name];
				// said at the member's name
				var _span = _pick.member.span;
				array_push(_diagnostics[_pick.file], new GMLC_Diagnostic(_code, new GMLC_Span(_span.file, _span.start, _span.start + string_byte_length(_pick.member.name)), _args));
				_values[$ _pick.decl.name][$ _pick.member.name] = int64(0);
				_pick.member.value = int64(0);
				_pick.done = true;
				_left--;
			}
			
			// the values in place of the references, in every file
			var _a = 0; repeat (_count) {
				__placeEnumValues(_asts[_a], _values);
			_a++}
			return _diagnostics;
		};
		
		// finds a member's value when it can be found now; true when it was
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
				try {
					_member.init = env.optimizer.foldExpression(_member.init, _sources);
				}
				catch (_e) {
					// a call that cannot run (a wrong number of arguments) leaves the value unknown
				}
				var _constant = __constantOf(_member.init);
				if (!_constant[0]) return false;
				_value = __enumInteger(_constant[1]);
				if (_value == undefined) {
					_entry.notInteger = true;
					return false;
				}
			}
			_member.value = _value;
			_values[$ _entry.decl.name][$ _member.name] = _value;
			return true;
		};
		
		// whether an expression uses a member of the batch whose value is not known yet
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
		
		// [true, value] for a Literal or a built-in constant (not the `GM_` facts of a build), else [false]
		static __constantOf = function(_node) {
			if (_node.kind == __GMLC_NodeKind_Literal) return [true, _node.value];
			if (_node.kind == __GMLC_NodeKind_Identifier) && (_node.symbol != undefined) && (_node.symbol.kind == "BuiltinConstant")
			&& (string_copy(_node.name, 1, 3) != "GM_") {
				var _data = env.getConstant(_node.name);
				if (_data != undefined) return [true, _data.value];
			}
			return [false];
		};
		
		// a member's int64 from a folded value: a number or a bool, a fraction truncated toward zero; undefined otherwise
		static __enumInteger = function(_value) {
			if (is_bool(_value)) return int64(_value ? 1 : 0);
			if (is_int64(_value)) return _value;
			if (!is_numeric(_value)) || is_nan(_value) || is_infinity(_value) || (abs(_value) >= 9223372036854775807) return undefined;
			return int64((_value < 0) ? ceil(_value) : floor(_value));
		};
		
		// the node, or the Literal of its value, with every known `E.M` below it put in place
		static __placeEnumValues = function(_node, _values) {
			var _literal = __enumLiteral(_node, _values);
			if (_literal != undefined) return _literal;
			var _slots = _node.childSlots();
			var _i = 0; repeat (array_length(_slots)) {
				var _slot = _slots[_i];
				var _new = __placeEnumValues(_slot.node, _values);
				if (_new != _slot.node) {
					if (_slot.index != undefined) {
						_node[$ _slot.key][_slot.index] = _new;
					}
					else {
						_node[$ _slot.key] = _new;
					}
				}
			_i++}
			// the values of the file's enums themselves
			if (_node.kind == __GMLC_NodeKind_Script) {
				var _e = 0; repeat (array_length(_node.enums)) {
					var _members = _node.enums[_e].members;
					var _m = 0; repeat (array_length(_members)) {
						if (_members[_m].init != undefined) _members[_m].init = __placeEnumValues(_members[_m].init, _values);
					_m++}
				_e++}
			}
			return _node;
		};
		
		// the Literal of an `E.M` whose value is known (of the batch, or of an enum the environment exposes)
		static __enumLiteral = function(_node, _values) {
			if (_node.kind != __GMLC_NodeKind_Index) || (_node.accessor != "Dot") || (_node.object.kind != __GMLC_NodeKind_Identifier) return undefined;
			var _symbol = _node.object.symbol;
			if (_symbol == undefined) || (_symbol.kind != "Enum") return undefined;
			var _name = _node.object.name;
			var _value;
			var _defSpan = undefined;
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
			var _text = _name + "." + _node.member;
			return new ASTLiteral(_node.span, "int64", _text, _value, new GMLC_Origin("enum", _name, _node.member, undefined, __memberSpan(_name, _node.member), _node.span));
		};
		
		// where a member of the batch is declared, undefined for an exposed enum
		static __memberSpan = function(_name, _member) {
			var _decl = __gmlc_struct_get(__enumDecls, _name);
			if (_decl == undefined) return undefined;
			var _m = 0; repeat (array_length(_decl.members)) {
				if (_decl.members[_m].name == _member) return _decl.members[_m].span;
			_m++}
			return undefined;
		};
		#endregion
		
		#region Helper Functions
		static __position = function(_node) {
			return (sources != undefined) ? sources.position(_node.span) : { fileName: fileName, line: 0, column: 0, lineString: "" };
		};
		
		static __literalType = function(_value) {
			if (is_string(_value)) return "string";
			if (is_bool(_value)) return "bool";
			if (is_int64(_value)) return "int64";
			if (is_undefined(_value)) return "undefined";
			return "real";
		};
		
		static __literalLexeme = function(_value) {
			if (is_string(_value)) return json_stringify(_value);
			return string(_value);
		};
		
		static compileTimeContext = function(_node, _slot, _info) {
			var _at = __position(_node);
			var _span = _node.span;
			var _function = __fnNodes[_info.fn_id];
			// a script's own code outside functions is `gml_GlobalScript_<script>`, as in GameMaker (measured)
			var _functionName = (_function != undefined) ? (__gmNames[_info.fn_id] ?? _function.name)
				: ((ast[$ "unitKind"] != "event") ? "gml_GlobalScript_" + __scriptName : _at.fileName);
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
		
		
		static isCompileTimeConstantVariable = function(_value) {
			return is_struct(_value)
			&& struct_exists(_value, "compileTimeConstant")
			&& _value.compileTimeConstant
			&& struct_exists(_value, "compileTimeGet");
		}
		#endregion
	}
#endregion
