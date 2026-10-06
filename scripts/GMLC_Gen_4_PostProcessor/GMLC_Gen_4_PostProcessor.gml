#region PostProcessor.gml
	#region PostProcessor Module
	/*
	Purpose: To replace the names whose value is known when compiling (`_GMLINE_`, `_GMFILE_`, `_GMFUNCTION_` and the
	other compile-time variables the environment exposes) by their value, after the resolver has bound every name.
	Writes to them are refused by the resolver.
	*/
	#endregion
	function GMLC_Gen_4_PostProcessor(_env) constructor {
		env = _env;
		
		ast = undefined;
		sources = undefined;
		fileName = "";
		needed = true; // false when the resolver found no compile-time name, so there is nothing to walk
		
		#region jsDoc
		/// @func    initialize(_ast, [_sources], [_needed])
		/// @desc    Prepares the replacement for one resolved file.
		/// @self    GMLC_Gen_4_PostProcessor
		/// @param   {Struct.ASTScript}        _ast      : The resolved tree
		/// @param   {Struct.GMLC_SourceTable} [_sources] : The compile's files, for the positions given to the names
		/// @param   {Bool}                    [_needed]  : Whether the file uses a compile-time name (unknown: true)
		#endregion
		static initialize = function(_ast, _sources = undefined, _needed = true) {
			ast = _ast;
			sources = _sources;
			needed = _needed;
			var _file = (sources != undefined) && (ast.span.file < array_length(sources.files)) ? sources.files[ast.span.file] : undefined;
			fileName = (_file != undefined) ? _file.name : "";
		};
		
		static cleanup = function() {
		
		}
		
		static parseAll = function() {
			if (needed) __visit(ast, undefined, undefined);
			return ast;
		}
		
		#region jsDoc
		/// @func    __visit(_node, _slot, _function)
		/// @desc    Replaces the compile-time names in a node and its children.
		/// @self    GMLC_Gen_4_PostProcessor
		/// @param   {Struct.ASTNode} _node     : The node
		/// @param   {Struct}         _slot     : Where the node is held ({parent, key, index}), undefined at the root
		/// @param   {Struct.ASTNode} _function : The function the node is in, undefined in the file's body
		#endregion
		static __visit = function(_node, _slot, _function) {
			if (_node.kind == __GMLC_NodeKind_Identifier) {
				var _symbol = _node.symbol;
				if (_symbol != undefined) && (_symbol.kind == "BuiltinVar") {
					var _variable = env.getVariable(_node.name);
					if (_variable != undefined) && isCompileTimeConstantVariable(_variable.value) {
						var _value = _variable.value.compileTimeGet(compileTimeContext(_node, _slot, _function));
						var _literal = new ASTLiteral(_node.span, __literalType(_value), __literalLexeme(_value), _value,
							new GMLC_Origin("compile_time", _node.name, undefined, undefined, undefined, _node.span));
						if (_slot.index != undefined) {
							_slot.parent[$ _slot.key][_slot.index] = _literal;
						}
						else {
							_slot.parent[$ _slot.key] = _literal;
						}
					}
				}
				return;
			}

			switch (_node.kind) {
				case __GMLC_NodeKind_FunctionDecl:
				case __GMLC_NodeKind_ConstructorDecl:
				case __GMLC_NodeKind_FunctionExpr: {
					_function = _node;
				break;}
			}
			
			var _slots = _node.childSlots();
			var _i = 0; repeat (array_length(_slots)) {
				__visit(_slots[_i].node, _slots[_i], _function);
			_i++}
		};
		
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
		
		static compileTimeContext = function(_node, _slot, _function) {
			var _at = __position(_node);
			var _span = _node.span;
			var _functionName = (_function != undefined) ? _function.name : _at.fileName;
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
