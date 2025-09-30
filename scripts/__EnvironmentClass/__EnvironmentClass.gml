#region jsDoc
/// @func    __EnvironmentClass()
/// @desc    Core symbol environment. Stores an indexed table of named symbols with value, type, getter, setter, and highlight metadata. Provides typed expose/remove/clear/get APIs for keywords, constants, enums, functions, variables, macros, and operators. Also supports cloning, importing, resolving in context, and bulk symbol population.
/// @returns {Struct.__EnvironmentClass}
#endregion
function __EnvironmentClass() constructor {
	// === Internal Stores ===
	envSymbols = {};
	
	#region Public
	#region jsDoc
	/// @func    importSymbolMap()
	/// @desc    Bulk-imports a spec-shaped map of symbols into the environment, optionally overwriting existing entries. Each entry should include at minimum a string `type` and a `value`. Optional `getter`, `setter`, and `highlight` fields are respected; otherwise defaults are synthesized based on `type`. Optional `feather` metadata is preserved.
	/// @self    __EnvironmentClass
	/// @param   {Struct} symbolMap  : Map of symbolName -> { value, type, getter?, setter?, highlight?, feather? }
	/// @param   {Bool}   overwrite  : If true, replace existing entries with the same name (default: false)
	/// @returns {Struct.__EnvironmentClass}
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
			
			if (!overwrite && struct_exists(envSymbols, key)) {
				continue; // Skip if already exists and overwrite is false
			}
			
			if (!struct_exists(envSymbols, key)) {
				envSymbols[$ key] = {};
			}
			
			var sym = envSymbols[$ key];
			
			sym.value     = entry.value;
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
	/// @self    __EnvironmentClass
	/// @param   {Struct} conf : Map of symbolName -> highlightTag
	/// @returns {Struct.__EnvironmentClass}
	#endregion
	static setHighlight = function(conf) {
		if (!is_struct(conf)) throw "env.setHighlight() expects a struct as an input"
		
		var keys = struct_get_names(conf);
		var i = 0;
		repeat(array_length(keys)) {
			var key = keys[i];
			var val = conf[$ key];
			
			if (!struct_exists(envSymbols, key)) {
				envSymbols[$ key] = {};
			}
			
			envSymbols[$ key].highlight = val;
			i++;
		}
		return self;
	};
	#region jsDoc
	/// @func    importFrom()
	/// @desc    Merges the contents of another environment instance into this one. Existing keys in the target are overwritten by the source.
	/// @self    __EnvironmentClass
	/// @param   {Struct.__EnvironmentClass} envOther : Environment to import from
	/// @returns {Struct.__EnvironmentClass}
	#endregion
	static importFrom = function(_env) {
		__mergeStruct(envSymbols, _env.envSymbols);
		return self;
	};
	#region jsDoc
	/// @func    clone()
	/// @desc    Creates a deep clone of the environment, including all symbol entries and metadata.
	/// @self    __EnvironmentClass
	/// @returns {Struct.__EnvironmentClass}
	#endregion
	static clone = function() {
		var newEnv = new __EnvironmentClass();
		newEnv.envSymbols = variable_clone(envSymbols, 1);
		return newEnv;
	};
	#region jsDoc
	/// @func    resolve()
	/// @desc    Looks up a symbol entry by name. If found, attaches the given context to the entry and returns it. Returns undefined if the symbol is not present.
	/// @self    __EnvironmentClass
	/// @param   {String} name    : Symbol name to resolve
	/// @param   {Any}    context : Optional context object stored on the returned entry (default: undefined)
	/// @returns {Struct|Undefined} Returns the symbol struct { value, type, getter, setter, highlight, feather?, context? } or undefined
	#endregion
	static resolve = function(name, context=undefined) {
		if (is_undefined(envSymbols[$ name])) return undefined;
		
		var entry = envSymbols[$ name];
		entry.context = context;
		return entry;
	};
	#region jsDoc
	/// @func    addSymbol()
	/// @desc    Adds all fields from the given struct into the environment as symbols of the provided type, using default getter, setter, and highlight rules for that type.
	/// @self    __EnvironmentClass
	/// @param   {Struct} sourceStruct : Struct whose fields will be added as symbols
	/// @param   {String} symbolType   : Type tag to assign (e.g., "envConstants", "envFunctions", etc.)
	/// @returns {Struct.__EnvironmentClass}
	#endregion
	static addSymbol = function(_struct, _type) {
		__populateSymbols(_struct, _type);
		return self;
	};
	
	#region === Keywords ===
	static exposeKeywords  = function(conf) { __exposeType("envKeywords", conf);  return self; };
	static removeKeywords  = function(keys) { __removeType("envKeywords", keys); return self; };
	static clearKeywords   = function()     { __clearType("envKeywords"); return self; };
	static getKeyword      = function(name) { return __getType("envKeywords", name); };
	static isKeyword       = function(name) { return __isType("envKeywords", name); };
	static getAllKeywords  = function()     { return __getAllType("envKeywords"); };
	#endregion
	#region === Constants ===
	static exposeConstants  = function(conf) { __exposeType("envConstants", conf);  return self; };
	static removeConstants  = function(keys) { __removeType("envConstants", keys); return self; };
	static clearConstants   = function()     { __clearType("envConstants"); return self; };
	static getConstant      = function(name) { return __getType("envConstants", name); };
	static isConstant       = function(name) { return __isType("envConstants", name); };
	static getAllConstants  = function()     { return __getAllType("envConstants"); };
	#endregion
	#region === Enums ===
	static exposeEnums     = function(conf) { __exposeType("envEnums", conf);  return self; };
	static removeEnums  = function(keys) { __removeType("envEnums", keys); return self; };
	static clearEnums   = function()     { __clearType("envEnums"); return self; };
	static getEnum      = function(name) { return __getType("envEnums", name); };
	static isEnum       = function(name) { return __isType("envEnums", name); };
	static getAllEnums  = function()     { return __getAllType("envEnums"); };
	#endregion
	#region === Functions ===
	static exposeFunctions     = function(conf) { __exposeType("envFunctions", conf);  return self; };
	static removeFunctions  = function(keys) { __removeType("envFunctions", keys); return self; };
	static clearFunctions   = function()     { __clearType("envFunctions"); return self; };
	static getFunction      = function(name) { return __getType("envFunctions", name); };
	static isFunction       = function(name) { return __isType("envFunctions", name); };
	static getAllFunctions  = function()     { return __getAllType("envFunctions"); };
	#endregion
	#region === Variables ===
	static exposeVariables  = function(conf) { __exposeType("envVariable", conf);  return self; };
	static removeVariables  = function(keys) { __removeType("envVariable", keys); return self; };
	static clearVariables   = function()     { __clearType("envVariable"); return self; };
	static getVariable      = function(name) { return __getType("envVariable", name); };
	static isVariable       = function(name) { return __isType("envVariable", name); };
	static getAllVariables  = function()     { return __getAllType("envVariable"); };
	#endregion
	#region === Macros ===
	static exposeMacros     = function(conf) { __exposeType("envMacros", conf);  return self; };
	static removeMacros  = function(keys) { __removeType("envMacros", keys); return self; };
	static clearMacros   = function()     { __clearType("envMacros"); return self; };
	static getMacro      = function(name) { return __getType("envMacros", name); };
	static isMacro       = function(name) { return __isType("envMacros", name); };
	static getAllMacros  = function()     { return __getAllType("envMacros"); };
	#endregion
	#region === Operators ===
	static exposeOperators  = function(conf) { __exposeType("envOperators", conf);  return self; };
	static removeOperators  = function(keys) { __removeType("envOperators", keys); return self; };
	static clearOperators   = function()     { __clearType("envOperators"); return self; };
	static getOperator      = function(name) { return __getType("envOperators", name); };
	static isOperator       = function(name) { return __isType("envOperators", name); };
	static getAllOperators  = function()     { return __getAllType("envOperators"); };
	#endregion
	
	#endregion
	
	#region Private
	static __populateSymbols = function(_source, _type) {
		if (!is_struct(_source)) return;
		
		var defaultHighlight = __defaultSymbolHighlight(_type);
		var keys = struct_get_names(_source);
		for (var i = 0; i < array_length(keys); i++) {
			var key = keys[i];
			var val = _source[$ key];
			
			if (!struct_exists(envSymbols, key)) {
				envSymbols[$ key] = {};
			}
			
			var sym = envSymbols[$ key];
			
			sym.value = val;
			sym.type = _type;
			sym.highlight = defaultHighlight;
			sym.getter = __defaultSymbolGetter(_type, key, val);
			sym.setter = __defaultSymbolSetter(_type, key, val);
		}
	};
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
	
	static __defaultSymbolSetter = function(type, key, value) {
		switch (type) {
			case "envKeywords":
			case "envConstants":
			case "envFunctions":
			case "envEnums":
			case "envMacros":
				return function() {
					throw "Can't set read-only symbol :: " + string(key);
				};
			default:
				return method({key: key}, function(v) {
					other[$ key] = v;
				});
		}
	};
	static __defaultSymbolGetter = function(type, key, value) {
		switch (type) {
			case "envKeywords":
				return function() {
					throw "Symbol `" + key + "` is not readable (keyword)";
				};
			case "envConstants":
			case "envFunctions":
			case "envEnums":
				return method({value: value}, function() {
					return value;
				});
			default:
				return method({key: key}, function() {
					return other[$ key];
				});
		}
	};
	
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
	static __exposeType = function(type, conf) {
		__populateSymbols(conf, type);
		return self;
	};
	
	static __removeType = function(type, keys) {
		var _names = struct_get_names(envSymbols);
		for (var i = 0; i < array_length(_names); i++) {
			var key = _names[i];
			if (envSymbols[$ key].type == type) && (is_array(keys) ? array_contains(keys, key) : keys == key) {
				struct_remove(envSymbols, key);
			}
		}
		return self;
	};
	
	static __getType = function(type, name) {
		var sym = envSymbols[$ name];
		return (sym != undefined && struct_exists(sym, "type") && sym.type == type) ? sym : undefined;
	};
	
	static __isType = function(type, name) {
		var _data = envSymbols[$ name];
		return _data && _data.type == type;
	};
	
	static __clearType = function(type) {
		var _names = struct_get_names(envSymbols);
		for (var i = 0; i < array_length(_names); i++) {
			var key = _names[i];
			if (envSymbols[$ key].type == type) {
				struct_remove(envSymbols, key);
			}
		}
		return self;
	};
	
	static __getAllType = function(type) {
		var out = {};
		var _names = struct_get_names(envSymbols);
		for (var i = 0; i < array_length(_names); i++) {
			var key = _names[i];
			if (envSymbols[$ key].type == type) {
				out[$ key] = envSymbols[$ key];
			}
		}
		return out;
	};
	
	#endregion
	#endregion
	
}

/*
