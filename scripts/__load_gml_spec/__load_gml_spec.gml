function __GmlSpec() {
	static GmlSpec = undefined;
	static __parseFunctions = function(_arr, _config) {
		for (var _i = 0; _i < array_length(_arr); _i++) {
			var _node = _arr[_i];
			var _attr = _node[$ "attributes"];
			var _name = _attr[$ "Name"];
			if (!is_string(_name)) continue;

			var _description = "";
			var _parameters = [];

			var _children = _node[$ "children"];
			for (var j = 0; j < array_length(_children); j++) {
				var _child = _children[j];
				switch (_child[$ "type"]) {
					case "Description":
						_description = _child[$ "text"] ?? "";
						break;
					case "Parameter":
						var _paramAttr = _child[$ "attributes"];
						_parameters[array_length(_parameters)] = {
							name: _paramAttr[$ "Name"],
							type: _paramAttr[$ "Type"],
							optional: (_paramAttr[$ "Optional"] == "true"),
							description: _child[$ "text"] ?? ""
						};
						break;
				}
			}

			var _isDeprecated = (_attr[$ "Deprecated"] == "true");
			
			_config[$ _name] = {
				value: script_get_index(_name),
				type: "envFunctions",
				highlight: _isDeprecated ? "highlight.function.deprecated" : "highlight.function",
				feather: {
					description: _description,
					returnType: _attr[$ "ReturnType"],
					pure: (_attr[$ "Pure"] == "true"),
					deprecated: _isDeprecated,
					parameters: _parameters
				}
			};
		}
	};
	static __parseVariables = function(_arr, _config) {
		for (var _i = 0; _i < array_length(_arr); _i++) {
			var _node = _arr[_i];
			var _attr = _node[$ "attributes"];
			var _name = _attr[$ "Name"];
			if (!is_string(_name)) continue;

			var _description = _node[$ "text"] ?? "";
			var _isDeprecated = (_attr[$ "Deprecated"] == "true");
			var _isInstance = (_attr[$ "Instance"] == "true");
			var _type = _isInstance ? "envDynamicVar" : "envBuiltInVars";
			var _canRead = (_attr[$ "Get"] == "true");
			var _canWrite = (_attr[$ "Set"] == "true");

			var _getter = undefined;
			var _setter = undefined;

			if (_isInstance) {
				_getter = _canRead
					? method({ key: _name }, function() { return other[$ key]; })
					: method({ key: _name }, function() { throw "Symbol `" + key + "` is not readable"; });

				_setter = _canWrite
					? method({ key: _name }, function(v) { other[$ key] = v; })
					: method({ key: _name }, function() { throw "Can't set read-only symbol :: " + key; });
			}

			_config[$ _name] = {
				value: undefined,
				type: _type,
				getter: _getter,
				setter: _setter,
				highlight: _isDeprecated
					? (_isInstance ? "highlight.dynamic.deprecated" : "highlight.builtin.deprecated")
					: (_isInstance ? "highlight.dynamic" : "highlight.builtin"),
				feather: {
					description: _description,
					returnType: _attr[$ "Type"],
					deprecated: _isDeprecated,
					instance: _isInstance,
					canRead: _canRead,
					canWrite: _canWrite
				}
			};
		}
	};
	static __parseConstants = function(_arr, _config) {
		var _lookup_table = __ExistingConstants();

		for (var _i = 0; _i < array_length(_arr); _i++) {
			var _node = _arr[_i];
			var _attr = _node[$ "attributes"];
			var _name = _attr[$ "Name"];
			if (!is_string(_name)) continue;

			var _description = _node[$ "text"] ?? "";
			var _isDeprecated = (_attr[$ "Deprecated"] == "true");

			_config[$ _name] = {
				value: _lookup_table[$ _name],
				type: "envConstants",
				highlight: _isDeprecated ? "highlight.constant.deprecated" : "highlight.constant",
				feather: {
					description: _description,
					returnType: _attr[$ "Type"],
					class: _attr[$ "Class"] ?? undefined,
					deprecated: _isDeprecated
				}
			};
		}
	};
	static __parseEnumerations = function(_arr, _config) {
		for (var _i = 0; _i < array_length(_arr); _i++) {
			var _node = _arr[_i];
			var _enumName = _node[$ "attributes"][$ "Name"];
			if (!is_string(_enumName)) continue;

			var _members = {};
			var _children = _node[$ "children"];

			for (var j = 0; j < array_length(_children); j++) {
				var _child = _children[j];
				if (_child[$ "type"] != "Member") continue;

				var _attr = _child[$ "attributes"];
				var _name = _attr[$ "Name"];
				var _value = real(_attr[$ "Value"]);
				var _isDeprecated = (_attr[$ "Deprecated"] == "true");
				var _description = _child[$ "text"] ?? "";

				if (!is_string(_name)) continue;

				_members[$ _name] = {
					value: _value,
					highlight: _isDeprecated ? "highlight.enum.deprecated" : "highlight.enum",
					feather: {
						description: _description,
						deprecated: _isDeprecated
					}
				};
			}

			_config[$ _enumName] = {
				value: _members,
				type: "envEnums",
				highlight: "highlight.enum"
			};
		}
	};

	if (GmlSpec = undefined) {
		var _xml = file_read_all_text("GmlSpec.xml")
		var _spec = SnapFromXML(_xml)
		
		var _config = {};
		
		var _functions = undefined;
		var _variables = undefined;
		var _constants = undefined;
		var _enumerations = undefined;
		var _structures = undefined;
		
		var _children = _spec.children;
		for (var i = 0; i < array_length(_children); i++) {
			var child = _children[i];
			if (child[$ "type"] != "GameMakerLanguageSpec") continue;
			
			var grandChildren = child[$ "children"];
			for (var j = 0; j < array_length(grandChildren); j++) {
				var sub = grandChildren[j];
				switch(sub[$ "type"]) {
					case "Functions":    __parseFunctions(sub[$ "children"], _config); break;
					case "Variables":    __parseVariables(sub[$ "children"], _config); break;
					case "Constants":    __parseConstants(sub[$ "children"], _config); break;
					case "Enumerations": __parseEnumerations(sub[$ "children"], _config); break;
					
					case "Structures":
					default:
						continue;
				}
			}
		}
		
		GmlSpec = _config;
	}
	
	return GmlSpec;
}
__GmlSpec();
