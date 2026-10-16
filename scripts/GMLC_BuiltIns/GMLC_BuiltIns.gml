#region jsDoc
/// @func    __gmlc_built_ins()
/// @desc    Returns the built-in symbols of GameMaker as GMLC environment entries, built once from __GmlcDataSpec()
///          (generated from GmlSpec.xml and GML-Function-DB).
/// @returns {Struct}
#endregion
function __gmlc_built_ins() {
	static __table = undefined;
	#region jsDoc
	/// @func    __parseFunctions(_arr, _config)
	/// @desc    Adds the functions of the spec data to the table as envFunctions entries.
	/// @param   {Array<Struct>} _arr    : The functions of __GmlcDataSpec()
	/// @param   {Struct}        _config : The table being built, name to entry
	#endregion
	static __parseFunctions = function(_arr, _config) {
		var _i = 0; repeat (array_length(_arr)) {
			var _fn = _arr[_i];
			var _name = _fn.name;
			
			var _parameters = [];
			var _params = _fn.parameters;
			var _j = 0; repeat (array_length(_params)) {
				var _param = _params[_j];
				_parameters[_j] = {
					name: _param.name,
					type: _param.type,
					optional: _param.optional,
					description: _param.description
				};
			_j++}
			
			var _isDeprecated = _fn.deprecated;
			
			_config[$ _name] = {
				value: script_get_index(_name),
				type: "envFunctions",
				highlight: _isDeprecated ? "highlight.function.deprecated" : "highlight.function",
				feather: {
					description: _fn.description,
					returnType: _fn.returnType,
					pure: _fn.pure,
					deprecated: _isDeprecated,
					parameters: _parameters
				},
				db: _fn[$ "db"]
			};
		_i++}
	};
	#region jsDoc
	/// @func    __parseVariables(_arr, _config)
	/// @desc    Adds the variables of the spec data to the table as envDynamicVar (instance) or envBuiltInVars entries.
	/// @param   {Array<Struct>} _arr    : The variables of __GmlcDataSpec()
	/// @param   {Struct}        _config : The table being built, name to entry
	#endregion
	static __parseVariables = function(_arr, _config) {
		var _i = 0; repeat (array_length(_arr)) {
			var _var = _arr[_i];
			var _name = _var.name;
			
			var _isDeprecated = _var.deprecated;
			var _isInstance = _var.instance;
			var _type = _isInstance ? "envDynamicVar" : "envBuiltInVars";
			var _canRead = _var.get;
			var _canWrite = _var.set;
			
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
					description: _var.description,
					returnType: _var.type,
					deprecated: _isDeprecated,
					instance: _isInstance,
					canRead: _canRead,
					canWrite: _canWrite
				}
			};
		_i++}
	};
	#region jsDoc
	/// @func    __parseConstants(_arr, _config)
	/// @desc    Adds the constants of the spec data to the table as envConstants entries.
	/// @param   {Array<Struct>} _arr    : The constants of __GmlcDataSpec()
	/// @param   {Struct}        _config : The table being built, name to entry
	#endregion
	static __parseConstants = function(_arr, _config) {
		var _lookup_table = __GmlcDataConstants();
		
		var _i = 0; repeat (array_length(_arr)) {
			var _const = _arr[_i];
			var _name = _const.name;
			// a constant this runtime does not have is left out
			if (struct_exists(_lookup_table, _name)) {
				var _isDeprecated = _const.deprecated;
				_config[$ _name] = {
					value: _lookup_table[$ _name],
					type: "envConstants",
					highlight: _isDeprecated ? "highlight.constant.deprecated" : "highlight.constant",
					feather: {
						description: _const.description,
						returnType: _const.type,
						class: _const[$ "class"],
						deprecated: _isDeprecated
					}
				};
			}
		_i++}
	};
	#region jsDoc
	/// @func    __parseEnumerations(_arr, _config)
	/// @desc    Adds the enums of the spec data to the table as envEnums entries.
	/// @param   {Array<Struct>} _arr    : The enums of __GmlcDataSpec()
	/// @param   {Struct}        _config : The table being built, name to entry
	#endregion
	static __parseEnumerations = function(_arr, _config) {
		var _i = 0; repeat (array_length(_arr)) {
			var _enum = _arr[_i];
			var _members = {};
			var _list = _enum.members;
			
			var _j = 0; repeat (array_length(_list)) {
				var _member = _list[_j];
				var _isDeprecated = _member.deprecated;
				
				_members[$ _member.name] = {
					value: _member.value,
					highlight: _isDeprecated ? "highlight.enum.deprecated" : "highlight.enum",
					feather: {
						description: _member.description,
						deprecated: _isDeprecated
					}
				};
			_j++}
			
			_config[$ _enum.name] = {
				value: _members,
				type: "envEnums",
				highlight: "highlight.enum"
			};
		_i++}
	};
	
	if (__table == undefined) {
		var _data = __GmlcDataSpec();
		var _config = {};
		__parseFunctions(_data.functions, _config);
		__parseVariables(_data.variables, _config);
		__parseConstants(_data.constants, _config);
		__parseEnumerations(_data.enumerations, _config);
		__table = _config;
	}
	
	return __table;
}
__gmlc_built_ins();
