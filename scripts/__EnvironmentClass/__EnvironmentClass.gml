function __EnvironmentClass() constructor {
	// === Internal Stores ===
	envSymbols = {};
	
	#region Public
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
	static importFrom = function(_env) {
		__mergeStruct(envSymbols, _env.envSymbols);
		return self;
	};
	static clone = function() {
		var newEnv = new __EnvironmentClass();
		newEnv.envSymbols = variable_clone(envSymbols, 1);
		return newEnv;
	};
	static resolve = function(name, context=undefined) {
		if (is_undefined(envSymbols[$ name])) return undefined;
		
		var entry = envSymbols[$ name];
		entry.context = context;
		return entry;
	};
	static addSymbol = function(_struct, _type) {
		__populateSymbols(_struct, _type);
		return self;
	};
	
	#region === Keywords ===
	static addKeywords     = function(conf) { __addType("envKeywords", conf);  return self; };
	static removeKeywords  = function(keys) { __removeType("envKeywords", keys); return self; };
	static clearKeywords   = function()     { __clearType("envKeywords"); return self; };
	static getKeyword      = function(name) { return __getType("envKeywords", name); };
	static isKeyword       = function(name) { return __isType("envKeywords", name); };
	static getAllKeywords  = function()     { return __getAllType("envKeywords"); };
	#endregion
	#region === Constants ===
	static addConstants     = function(conf) { __addType("envConstants", conf);  return self; };
	static removeConstants  = function(keys) { __removeType("envConstants", keys); return self; };
	static clearConstants   = function()     { __clearType("envConstants"); return self; };
	static getConstant      = function(name) { return __getType("envConstants", name); };
	static isConstant       = function(name) { return __isType("envConstants", name); };
	static getAllConstants  = function()     { return __getAllType("envConstants"); };
	#endregion
	#region === Enums ===
	static addEnums     = function(conf) { __addType("envEnums", conf);  return self; };
	static removeEnums  = function(keys) { __removeType("envEnums", keys); return self; };
	static clearEnums   = function()     { __clearType("envEnums"); return self; };
	static getEnum      = function(name) { return __getType("envEnums", name); };
	static isEnum       = function(name) { return __isType("envEnums", name); };
	static getAllEnums  = function()     { return __getAllType("envEnums"); };
	#endregion
	#region === Functions ===
	static addFunctions     = function(conf) { __addType("envFunctions", conf);  return self; };
	static removeFunctions  = function(keys) { __removeType("envFunctions", keys); return self; };
	static clearFunctions   = function()     { __clearType("envFunctions"); return self; };
	static getFunction      = function(name) { return __getType("envFunctions", name); };
	static isFunction       = function(name) { return __isType("envFunctions", name); };
	static getAllFunctions  = function()     { return __getAllType("envFunctions"); };
	#endregion
	#region === Dynamic Variables (with getter/setter) ===
	static addDynamicVars     = function(conf) { __addType("envDynamicVar", conf);  return self; };
	static removeDynamicVars  = function(keys) { __removeType("envDynamicVar", keys); return self; };
	static clearDynamicVars   = function()     { __clearType("envDynamicVar"); return self; };
	static getDynamicVar      = function(name) { return __getType("envDynamicVar", name); };
	static isDynamicVar       = function(name) { return __isType("envDynamicVar", name); };
	static getAllDynamicVars  = function()     { return __getAllType("envDynamicVar"); };
	#endregion
	#region === Builtin Variables ===
	static addBuiltinVars     = function(conf) { __addType("envBuiltInVars", conf);  return self; };
	static removeBuiltinVars  = function(keys) { __removeType("envBuiltInVars", keys); return self; };
	static clearBuiltinVars   = function()     { __clearType("envBuiltInVars"); return self; };
	static getBuiltinVar      = function(name) { return __getType("envBuiltInVars", name); };
	static isBuiltinVar       = function(name) { return __isType("envBuiltInVars", name); };
	static getAllBuiltinVars  = function()     { return __getAllType("envBuiltInVars"); };
	#endregion
	#region === Macros ===
	static addMacros     = function(conf) { __addType("envMacros", conf);  return self; };
	static removeMacros  = function(keys) { __removeType("envMacros", keys); return self; };
	static clearMacros   = function()     { __clearType("envMacros"); return self; };
	static getMacro      = function(name) { return __getType("envMacros", name); };
	static isMacro       = function(name) { return __isType("envMacros", name); };
	static getAllMacros  = function()     { return __getAllType("envMacros"); };
	#endregion
	#region === Accessors ===
	//static addAccessors     = function(conf) { __defineSymbols(envAccessors, conf, "envAccessors");  return self; };
	//static removeAccessors  = function(keys) { __removeType(envAccessors, keys); return self; };
	//static clearAccessors   = function()     { __clearType("envAccessors"); return self; };
	//static getAccessor      = function(name) { return envAccessors[$ name]; };
	//static isAccessor       = function(name) { return struct_exists(envAccessors, name); };
	//static getAllAccessors  = function()     { return envAccessors; };
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
			
			if (!struct_exists(sym, "value")) sym.value = val;
			if (!struct_exists(sym, "type")) sym.type = _type;
			if (!struct_exists(sym, "getter")) sym.getter = __defaultSymbolGetter(_type, key, val);
			if (!struct_exists(sym, "setter")) sym.setter = __defaultSymbolSetter(_type, key, val);
			if (!struct_exists(sym, "highlight")) sym.highlight = defaultHighlight;
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
			case "envDynamicVar":   return "highlight.dynamic";
			case "envBuiltInVars":  return "highlight.builtin";
			default:                return "highlight.identifier";
		}
	};
	
	#region Types
	static __addType = function(type, conf) {
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
		return (struct_exists(sym, "type") && sym.type == type) ? sym : undefined;
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


var env = new __EnvironmentClass();
env.addConstants({ "pi": 3.14 });

var _pi = env.getConstant("pi");
show_debug_message($"pi.type == {_pi.type}, expecting result :: envConstants");
show_debug_message($"pi.highlight == {_pi.highlight}, expecting result :: highlight.constant");
show_debug_message($"pi.getter() == {_pi.getter()}, expecting result :: 3.14");


var env = new __EnvironmentClass();
env.addConstants({ "pi": 3.14 });

var _pi = env.getConstant("pi");
var caught = false;
try {
	_pi.setter(4);
} catch (e) {
	caught = true;
}
show_debug_message($"caught == {caught}, expecting result :: true");


var env = new __EnvironmentClass();
env.addDynamicVars({ "score": 0 });

var _score = env.getDynamicVar("score");
show_debug_message($"score.getter() == {score.getter()}, expecting result :: 0");
_score.setter(42);
show_debug_message($"score.getter() == {score.getter()}, expecting result :: 42");


var env = new __EnvironmentClass();
env.addConstants({ "pi": 3.14 });
env.setHighlight({ "pi": "highlight.special" });

var _pi = env.getConstant("pi");
show_debug_message($"pi.highlight == {_pi.highlight}, expecting result :: highlight.special");


var env = new __EnvironmentClass();
env.addFunctions({ "myFunc": function() {} });

show_debug_message($"env.isFunction('myFunc') == {env.isFunction("myFunc")}, expecting result :: true");

var funcs = env.getAllFunctions();
show_debug_message($"funcs['myFunc'].type == {funcs[$ "myFunc"].type}, expecting result :: envFunctions");


var env = new __EnvironmentClass();
env.addFunctions({ "myFunc": function() {} });
env.clearFunctions();

show_debug_message($"env.isFunction('myFunc') == {env.isFunction("myFunc")}, expecting result :: false");
