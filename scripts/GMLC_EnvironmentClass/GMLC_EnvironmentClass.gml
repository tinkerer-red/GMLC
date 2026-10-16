#region jsDoc
/// @func    GMLC_EnvironmentClass()
/// @desc    Core symbol environment. Stores an indexed table of named symbols with value, type, getter, setter, and highlight metadata. Provides typed expose/remove/clear/get APIs for keywords, constants, enums, functions, variables, macros, and operators. Also supports cloning, importing, resolving in context, and bulk symbol population.
/// @returns {Struct.GMLC_EnvironmentClass}
#endregion
function GMLC_EnvironmentClass() constructor {
	#region Init
	// === Internal Stores ===
	env_symbols = {};
	__function_index_names = {};
	__host_macros_dirty = true;
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    importSymbolMap()
	/// @desc    Bulk-imports a spec-shaped map of symbols into the environment, optionally overwriting existing entries. Each entry should include at minimum a string `type` and a `value`. Optional `getter`, `setter`, and `highlight` fields are respected; otherwise defaults are synthesized based on `type`. Optional `feather` metadata is preserved.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct} symbolMap  : Map of symbolName -> { value, type, getter?, setter?, highlight?, feather? }
	/// @param   {Bool}   overwrite  : If true, replace existing entries with the same name (default: false)
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static importSymbolMap = function(symbolMap, overwrite = false) {
		if (!is_struct(symbolMap)) {
			throw "importSymbolMap() expects a struct as input.";
		}
		
		var keys = struct_get_names(symbolMap);
		for (var i = 0; i < array_length(keys); i++) {
			var key = keys[i];
			var entry = symbolMap[$ key];
			
			if (!is_struct(entry)) continue;
			if (!is_string(entry.type)) continue;
			if (entry.value == undefined) && (entry.type != "envConstants") continue; // nameof and missing functions; the constant `undefined` is kept
			if (entry.type == "envFunctions") && (entry.value == -1) continue; // compile-time only, like gml_pragma; a constant may be -1 (seqdir_left)
			
			if (!overwrite && struct_exists(env_symbols, key)) {
				continue; // Skip if already exists and overwrite is false
			}
			
			if (!struct_exists(env_symbols, key)) {
				env_symbols[$ key] = {};
			}
			
			var sym = env_symbols[$ key];
			
			// the value compiled code sees when it reads the name (a built-in function is a number, as in GameMaker)
			sym.raw = entry[$ "raw"] ?? entry.value;
			
			//for sandboxing purposes
			if (entry.type == "envFunctions")
			&& (!is_method(entry.value)) {
				entry.raw = entry.value;
				entry.value = method(undefined, entry.value);
			}
			
			sym.value     = entry.value;
			if (entry.type == "envMacros") || (sym[$ "type"] == "envMacros") __host_macros_dirty = true;
			sym.type      = entry.type;
			sym.getter    = entry[$ "getter"] ?? __defaultSymbolGetter(entry.type, key, entry.value);
			sym.setter    = entry[$ "setter"] ?? __defaultSymbolSetter(entry.type, key, entry.value);
			sym.highlight = entry.highlight ?? __defaultSymbolHighlight(entry.type);
			
			// Optional metadata preserved for external tooling or doc gen
			if (entry[$ "feather"] != undefined) {
				sym.feather = entry.feather;
			}
		}
		
		return self;
	};
	#region jsDoc
	/// @func    setHighlight()
	/// @desc    Assigns a custom highlight tag per symbol name. Creates placeholders when the symbol does not yet exist, so highlighters can be configured before population.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct} conf : Map of symbolName -> highlightTag
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static setHighlight = function(conf) {
		if (!is_struct(conf)) throw "env.setHighlight() expects a struct as an input"
		
		var keys = struct_get_names(conf);
		var i = 0;
		repeat(array_length(keys)) {
			var key = keys[i];
			var val = conf[$ key];
			
			if (!struct_exists(env_symbols, key)) {
				env_symbols[$ key] = {};
			}
			
			env_symbols[$ key].highlight = val;
			i++;
		}
		return self;
	};
	#region jsDoc
	/// @func    importFrom()
	/// @desc    Merges the contents of another environment instance into this one. Existing keys in the target are overwritten by the source.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct.GMLC_EnvironmentClass} envOther : Environment to import from
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static importFrom = function(_env) {
		__mergeStruct(env_symbols, _env.env_symbols);
		__host_macros_dirty = true; // the other environment may bring macros
		return self;
	};
	#region jsDoc
	/// @func    clone()
	/// @desc    Creates a deep clone of the environment, including all symbol entries and metadata.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static clone = function() {
		var newEnv = new GMLC_EnvironmentClass();
		newEnv.env_symbols = variable_clone(env_symbols, 1);
		return newEnv;
	};
	#region jsDoc
	/// @func    callableFromIndex()
	/// @desc    Returns the exposed function whose number is _index, for a call through a plain function number; throws
	///          when this environment does not expose it. A built-in function read as a value is a plain number, as in
	///          GameMaker, and any number is callable, so a call through a number may only reach an exposed function.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Real} _index : Function number (a built-in or script function read as a value)
	/// @returns {Function}
	#endregion
	static callableFromIndex = function(_index) {
		// a function reference (method_get_index gives one) and its plain number are the same function
		var _key = string(real(_index));
		var _sym = env_symbols[$ __function_index_names[$ _key] ?? ""];
		if (_sym == undefined) || (_sym.type != "envFunctions") || is_method(_sym.raw) || (real(_sym.raw) != real(_index)) {
			__function_index_names = {};
			var _names = struct_get_names(env_symbols);
			var _i=0; repeat(array_length(_names)) {
				var _entry = env_symbols[$ _names[_i]];
				if (_entry[$ "type"] == "envFunctions") && (!is_method(_entry[$ "raw"])) && (is_callable(_entry[$ "raw"])) {
					__function_index_names[$ string(real(_entry.raw))] = _names[_i];
				}
			_i++}
			_sym = env_symbols[$ __function_index_names[$ _key] ?? ""];
			if (_sym == undefined) {
				throw_gmlc_error($"Attempting to call a function that is not exposed :: `{_index}`");
			}
		}
		return _sym.value;
	};
	#region jsDoc
	/// @func    resolve()
	/// @desc    Looks up a symbol entry by name. If found, attaches the given context to the entry and returns it. Returns undefined if the symbol is not present.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name    : Symbol name to resolve
	/// @param   {Any}    context : Optional context object stored on the returned entry (default: undefined)
	/// @returns {Struct|Undefined} Returns the symbol struct { value, type, getter, setter, highlight, feather?, context? } or undefined
	#endregion
	static resolve = function(name, context=undefined) {
		if (!__gmlc_struct_has(env_symbols, name)) return undefined;
		
		var entry = env_symbols[$ name];
		entry.context = context;
		return entry;
	};
	#region jsDoc
	/// @func    addSymbol()
	/// @desc    Adds all fields from the given struct into the environment as symbols of the provided type, using default getter, setter, and highlight rules for that type.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct} sourceStruct : Struct whose fields will be added as symbols
	/// @param   {String} symbolType   : Type tag to assign (e.g., "envConstants", "envFunctions", etc.)
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static addSymbol = function(_struct, _type) {
		__populateSymbols(_struct, _type);
		return self;
	};
	
	#region === Keywords ===
	#region jsDoc
	/// @func    exposeKeywords(conf)
	/// @desc    Exposes keywords to compiled code: name to value (or entry).
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct} conf : Name to value
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static exposeKeywords  = function(conf) { __exposeType("envKeywords", conf);  return self; };
	#region jsDoc
	/// @func    removeKeywords(keys)
	/// @desc    Removes exposed keywords.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Array<String>|String} keys : The names
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static removeKeywords  = function(keys) { __removeType("envKeywords", keys); return self; };
	#region jsDoc
	/// @func    clearKeywords()
	/// @desc    Removes all exposed keywords.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static clearKeywords   = function()     { __clearType("envKeywords"); return self; };
	#region jsDoc
	/// @func    getKeyword(name)
	/// @desc    The entry of an exposed keyword; undefined when the name is not one.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Struct}
	#endregion
	static getKeyword      = function(name) { return __getType("envKeywords", name); };
	#region jsDoc
	/// @func    isKeyword(name)
	/// @desc    Whether a name is an exposed keyword.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Bool}
	#endregion
	static isKeyword       = function(name) { return __isType("envKeywords", name); };
	#region jsDoc
	/// @func    getAllKeywords()
	/// @desc    Every exposed keyword: name to entry.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct}
	#endregion
	static getAllKeywords  = function()     { return __getAllType("envKeywords"); };
	#endregion
	#region === Constants ===
	#region jsDoc
	/// @func    exposeConstants(conf)
	/// @desc    Exposes constants to compiled code: name to value (or entry).
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct} conf : Name to value
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static exposeConstants  = function(conf) { __exposeType("envConstants", conf);  return self; };
	#region jsDoc
	/// @func    removeConstants(keys)
	/// @desc    Removes exposed constants.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Array<String>|String} keys : The names
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static removeConstants  = function(keys) { __removeType("envConstants", keys); return self; };
	#region jsDoc
	/// @func    clearConstants()
	/// @desc    Removes all exposed constants.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static clearConstants   = function()     { __clearType("envConstants"); return self; };
	#region jsDoc
	/// @func    getConstant(name)
	/// @desc    The entry of an exposed constant; undefined when the name is not one.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Struct}
	#endregion
	static getConstant      = function(name) { return __getType("envConstants", name); };
	#region jsDoc
	/// @func    isConstant(name)
	/// @desc    Whether a name is an exposed constant.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Bool}
	#endregion
	static isConstant       = function(name) { return __isType("envConstants", name); };
	#region jsDoc
	/// @func    getAllConstants()
	/// @desc    Every exposed constant: name to entry.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct}
	#endregion
	static getAllConstants  = function()     { return __getAllType("envConstants"); };
	#endregion
	#region === Enums ===
	#region jsDoc
	/// @func    exposeEnums(conf)
	/// @desc    Exposes enums to compiled code: name to value (or entry).
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct} conf : Name to value
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static exposeEnums     = function(conf) { __exposeType("envEnums", conf);  return self; };
	#region jsDoc
	/// @func    removeEnums(keys)
	/// @desc    Removes exposed enums.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Array<String>|String} keys : The names
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static removeEnums  = function(keys) { __removeType("envEnums", keys); return self; };
	#region jsDoc
	/// @func    clearEnums()
	/// @desc    Removes all exposed enums.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static clearEnums   = function()     { __clearType("envEnums"); return self; };
	#region jsDoc
	/// @func    getEnum(name)
	/// @desc    The entry of an exposed enum; undefined when the name is not one.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Struct}
	#endregion
	static getEnum      = function(name) { return __getType("envEnums", name); };
	#region jsDoc
	/// @func    isEnum(name)
	/// @desc    Whether a name is an exposed enum.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Bool}
	#endregion
	static isEnum       = function(name) { return __isType("envEnums", name); };
	#region jsDoc
	/// @func    getAllEnums()
	/// @desc    Every exposed enum: name to entry.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct}
	#endregion
	static getAllEnums  = function()     { return __getAllType("envEnums"); };
	#endregion
	#region === Functions ===
	#region jsDoc
	/// @func    exposeFunctions(conf)
	/// @desc    Exposes functions to compiled code: name to value (or entry).
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct} conf : Name to value
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static exposeFunctions     = function(conf) { __exposeType("envFunctions", conf);  return self; };
	#region jsDoc
	/// @func    removeFunctions(keys)
	/// @desc    Removes exposed functions.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Array<String>|String} keys : The names
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static removeFunctions  = function(keys) { __removeType("envFunctions", keys); return self; };
	#region jsDoc
	/// @func    clearFunctions()
	/// @desc    Removes all exposed functions.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static clearFunctions   = function()     { __clearType("envFunctions"); return self; };
	#region jsDoc
	/// @func    getFunction(name)
	/// @desc    The entry of an exposed function; undefined when the name is not one.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Struct}
	#endregion
	static getFunction      = function(name) { return __getType("envFunctions", name); };
	#region jsDoc
	/// @func    isFunction(name)
	/// @desc    Whether a name is an exposed function.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Bool}
	#endregion
	static isFunction       = function(name) { return __isType("envFunctions", name); };
	#region jsDoc
	/// @func    getAllFunctions()
	/// @desc    Every exposed function: name to entry.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct}
	#endregion
	static getAllFunctions  = function()     { return __getAllType("envFunctions"); };
	#endregion
	#region === Variables ===
	#region jsDoc
	/// @func    exposeVariables(conf)
	/// @desc    Exposes variables to compiled code: name to value (or entry). Each is read through the compiler's
	///          identifier path.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct} conf : Name to value
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static exposeVariables  = function(conf) {
		struct_foreach(conf, function(_name, _value) {
			_value.compiler_base = "__GMLCcompileIdentifier";
		})
		__exposeType("envVariable", conf);  return self;
	};
	#region jsDoc
	/// @func    removeVariables(keys)
	/// @desc    Removes exposed variables.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Array<String>|String} keys : The names
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static removeVariables  = function(keys) { __removeType("envVariable", keys); return self; };
	#region jsDoc
	/// @func    clearVariables()
	/// @desc    Removes all exposed variables.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static clearVariables   = function()     { __clearType("envVariable"); return self; };
	#region jsDoc
	/// @func    getVariable(name)
	/// @desc    The entry of an exposed variable; undefined when the name is not one.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Struct}
	#endregion
	static getVariable      = function(name) { return __getType("envVariable", name); };
	#region jsDoc
	/// @func    isVariable(name)
	/// @desc    Whether a name is an exposed variable.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Bool}
	#endregion
	static isVariable       = function(name) { return __isType("envVariable", name); };
	#region jsDoc
	/// @func    getAllVariables()
	/// @desc    Every exposed variable: name to entry.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct}
	#endregion
	static getAllVariables  = function()     { return __getAllType("envVariable"); };
	#endregion
	#region === Macros ===
	#region jsDoc
	/// @func    exposeMacros(conf)
	/// @desc    Exposes macros to compiled code: name to value (or entry).
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct} conf : Name to value
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static exposeMacros     = function(conf) { __exposeType("envMacros", conf);  return self; };
	#region jsDoc
	/// @func    removeMacros(keys)
	/// @desc    Removes exposed macros.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Array<String>|String} keys : The names
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static removeMacros  = function(keys) { __removeType("envMacros", keys); return self; };
	#region jsDoc
	/// @func    clearMacros()
	/// @desc    Removes all exposed macros.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static clearMacros   = function()     { __clearType("envMacros"); return self; };
	#region jsDoc
	/// @func    getMacro(name)
	/// @desc    The entry of an exposed macro; undefined when the name is not one.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Struct}
	#endregion
	static getMacro      = function(name) { return __getType("envMacros", name); };
	#region jsDoc
	/// @func    isMacro(name)
	/// @desc    Whether a name is an exposed macro.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Bool}
	#endregion
	static isMacro       = function(name) { return __isType("envMacros", name); };
	#region jsDoc
	/// @func    getAllMacros()
	/// @desc    Every exposed macro: name to entry.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct}
	#endregion
	static getAllMacros  = function()     { return __getAllType("envMacros"); };
	#endregion
	#region === Operators ===
	#region jsDoc
	/// @func    exposeOperators(conf)
	/// @desc    Exposes operators to compiled code: name to value (or entry).
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct} conf : Name to value
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static exposeOperators  = function(conf) { __exposeType("envOperators", conf);  return self; };
	#region jsDoc
	/// @func    removeOperators(keys)
	/// @desc    Removes exposed operators.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Array<String>|String} keys : The names
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static removeOperators  = function(keys) { __removeType("envOperators", keys); return self; };
	#region jsDoc
	/// @func    clearOperators()
	/// @desc    Removes all exposed operators.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static clearOperators   = function()     { __clearType("envOperators"); return self; };
	#region jsDoc
	/// @func    getOperator(name)
	/// @desc    The entry of an exposed operator; undefined when the name is not one.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Struct}
	#endregion
	static getOperator      = function(name) { return __getType("envOperators", name); };
	#region jsDoc
	/// @func    isOperator(name)
	/// @desc    Whether a name is an exposed operator.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} name : The name
	/// @returns {Bool}
	#endregion
	static isOperator       = function(name) { return __isType("envOperators", name); };
	#region jsDoc
	/// @func    getAllOperators()
	/// @desc    Every exposed operator: name to entry.
	/// @self    GMLC_EnvironmentClass
	/// @returns {Struct}
	#endregion
	static getAllOperators  = function()     { return __getAllType("envOperators"); };
	#endregion
	
	#endregion
	
	#region Private
	#region jsDoc
	/// @func    __populateSymbols(_source, _type)
	/// @desc    Adds every entry of a struct as a symbol of a type, with the type's default getter, setter and
	///          highlight.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct} _source : Name to value
	/// @param   {String} _type   : The symbol type, envFunctions, envConstants, ...
	#endregion
	static __populateSymbols = function(_source, _type) {
		if (!is_struct(_source)) return;
		
		var defaultHighlight = __defaultSymbolHighlight(_type);
		var keys = struct_get_names(_source);
		for (var i = 0; i < array_length(keys); i++) {
			var key = keys[i];
			var val = _source[$ key];
			
			if (!struct_exists(env_symbols, key)) {
				env_symbols[$ key] = {};
			}
			var sym = env_symbols[$ key];
			
			// the value compiled code sees when it reads the name (a built-in function is a number, as in GameMaker)
			sym.raw = val;
			
			//for sandboxing purposes
			if (_type == "envFunctions")
			&& (!is_method(val)) {
				val = method(undefined, val);
			}
			
			sym.value = val;
			sym.type = _type;
			sym.highlight = defaultHighlight;
			sym.getter = __defaultSymbolGetter(_type, key, val);
			sym.setter = __defaultSymbolSetter(_type, key, val);
		}
	};
	#region jsDoc
	/// @func    __mergeStruct(_target, _source)
	/// @desc    Copies every entry of _source into _target.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct} _target : Receives the entries
	/// @param   {Struct} _source : Gives them
	#endregion
	static __mergeStruct  = function(_target, _source) {
		if (is_struct(_source)) {
			var _keys = struct_get_names(_source);
			var _i=0; repeat(array_length(_keys)) {
				var key = _keys[_i];
				var def = _source[$ key];
				_target[$ key] = def;
			_i++}
		}
	}
	#region jsDoc
	/// @func    __removeKeys(map, keys)
	/// @desc    Removes names from a struct.
	/// @self    GMLC_EnvironmentClass
	/// @param   {Struct}               map  : The struct
	/// @param   {Array<String>|String} keys : The names
	#endregion
	static __removeKeys = function(map, keys) {
		if (is_array(keys)) {
			for (var i = 0; i < array_length(keys); i++) {
				var key = keys[i];
				struct_remove(map, key);
			}
		}
		else if (is_string(keys)) {
			struct_remove(map, key);
		}
	};
	
	#region jsDoc
	/// @func    __defaultSymbolSetter(type, key, value)
	/// @desc    The setter of a symbol: read-only types throw, others write the name on `other`.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} type  : The symbol type
	/// @param   {String} key   : The name
	/// @param   {Any}    value : The value
	/// @returns {Function}
	#endregion
	static __defaultSymbolSetter = function(type, key, value) {
		switch (type) {
			case "envKeywords":
			case "envConstants":
			case "envFunctions":
			case "envEnums":
			case "envMacros":
				return method({key: key}, function() {
					throw "Can't set read-only symbol :: " + string(key);
				});
			default:
				return method({key: key}, function(v) {
					other[$ key] = v;
				});
		}
	};
	#region jsDoc
	/// @func    __defaultSymbolGetter(type, key, value)
	/// @desc    The getter of a symbol: keywords throw, constants, enums and functions give their value, others read the
	///          name on `other`.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} type  : The symbol type
	/// @param   {String} key   : The name
	/// @param   {Any}    value : The value
	/// @returns {Function}
	#endregion
	static __defaultSymbolGetter = function(type, key, value) {
		switch (type) {
			case "envKeywords":
				return method({key: key}, function() {
					throw "Symbol `" + key + "` is not readable (keyword)";
				});
			case "envConstants":
			case "envEnums":
			case "envFunctions":
				return method({value: value}, function() {
					return value;
				});
			default:
				return method({key: key}, function() {
					return other[$ key];
				});
		}
	};
	
	#region jsDoc
	/// @func    __defaultSymbolHighlight(type)
	/// @desc    The highlight tag of a symbol type.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} type : The symbol type
	/// @returns {String}
	#endregion
	static __defaultSymbolHighlight = function(type) {
		switch (type) {
			case "envConstants":    return "highlight.constant";
			case "envFunctions":    return "highlight.function";
			case "envMacros":       return "highlight.macro";
			case "envEnums":        return "highlight.enum";
			case "envKeywords":     return "highlight.keyword";
			case "envVariable":     return "highlight.variable";
			default:                return "highlight.identifier";
		}
	};
	
	#region Types
	#region jsDoc
	/// @func    __exposeType(type, conf)
	/// @desc    Exposes the entries of a struct as symbols of a type.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} type : The symbol type
	/// @param   {Struct} conf : Name to value
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static __exposeType = function(type, conf) {
		if (type == "envMacros") __host_macros_dirty = true;
		__populateSymbols(conf, type);
		return self;
	};
	
	#region jsDoc
	/// @func    __removeType(type, keys)
	/// @desc    Removes symbols of a type by name.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String}               type : The symbol type
	/// @param   {Array<String>|String} keys : The names
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static __removeType = function(type, keys) {
		if (type == "envMacros") __host_macros_dirty = true;
		var _names = struct_get_names(env_symbols);
		for (var i = 0; i < array_length(_names); i++) {
			var key = _names[i];
			if (env_symbols[$ key].type == type) && (is_array(keys) ? array_contains(keys, key) : keys == key) {
				struct_remove(env_symbols, key);
			}
		}
		return self;
	};
	
	#region jsDoc
	/// @func    __getType(type, name)
	/// @desc    The entry of a name when it is a symbol of the type, else undefined.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} type : The symbol type
	/// @param   {String} name : The name
	/// @returns {Struct}
	#endregion
	static __getType = function(type, name) {
		var sym = __gmlc_struct_get(env_symbols, name);
		return (sym != undefined && struct_exists(sym, "type") && sym.type == type) ? sym : undefined;
	};
	
	#region jsDoc
	/// @func    __isType(type, name)
	/// @desc    Whether a name is a symbol of the type.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} type : The symbol type
	/// @param   {String} name : The name
	/// @returns {Bool}
	#endregion
	static __isType = function(type, name) {
		var _data = __gmlc_struct_get(env_symbols, name);
		return _data && _data.type == type;
	};
	
	#region jsDoc
	/// @func    __clearType(type)
	/// @desc    Removes every symbol of a type.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} type : The symbol type
	/// @returns {Struct.GMLC_EnvironmentClass}
	#endregion
	static __clearType = function(type) {
		if (type == "envMacros") __host_macros_dirty = true;
		var _names = struct_get_names(env_symbols);
		for (var i = 0; i < array_length(_names); i++) {
			var key = _names[i];
			if (env_symbols[$ key].type == type) {
				struct_remove(env_symbols, key);
			}
		}
		return self;
	};
	
	#region jsDoc
	/// @func    __getAllType(type)
	/// @desc    Every symbol of a type: name to entry.
	/// @self    GMLC_EnvironmentClass
	/// @param   {String} type : The symbol type
	/// @returns {Struct}
	#endregion
	static __getAllType = function(type) {
		var out = {};
		var _names = struct_get_names(env_symbols);
		for (var i = 0; i < array_length(_names); i++) {
			var key = _names[i];
			if (env_symbols[$ key].type == type) {
				out[$ key] = env_symbols[$ key];
			}
		}
		return out;
	};
	
	#endregion
	#endregion
	
}

/*
