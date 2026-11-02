#region jsDoc
/// @func    GMLC_Opt_AliasAnalysis()
/// @desc    The `alias-analysis` optimizer pass: an analysis that never rewrites. It finds the allocation sites each
///          local of a function may hold (`var _b = _a;` gives `_b` the sites of `_a`, a parameter or a call result
///          gives `unknown`), and offers them to the passes that need to know whether two references may be the same
///          object: `analyze` once per function, then `isKnown` and `mayAlias` per local.
/// @returns {Struct.GMLC_Opt_AliasAnalysis}
#endregion
function GMLC_Opt_AliasAnalysis() : GMLC_OptimizerPass("alias-analysis") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Counts the alias classes (distinct allocation sites) and the unknown references (locals that may hold
	///          an unknown one) of the function; returns undefined, it never rewrites.
	/// @self    GMLC_Opt_AliasAnalysis
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _facts = analyze(_node, _cx.unit.fn_id);
		var _names = struct_get_names(_facts.sites);
		array_sort(_names, true);
		var _seen = {};
		var _n = 0; repeat (array_length(_names)) {
			var _sites = _facts.sites[$ _names[_n]];
			var _unknown = false;
			var _s = 0; repeat (array_length(_sites)) {
				var _site = _sites[_s];
				if (_site == "unknown") {
					_unknown = true;
				}
				else if (!struct_exists(_seen, _site)) {
					_seen[$ _site] = true;
					_cx.stats[$ "alias_classes"]++;
				}
			_s++}
			if (_unknown) _cx.stats[$ "unknown_refs"]++;
		_n++}
		return undefined;
	};
	
	#region jsDoc
	/// @func    analyze(_root, _fn_id)
	/// @desc    The alias facts of one function: `sites` holds, for each local that may hold a reference, the
	///          allocation sites it may be (`array@12`, `struct@40`, `new@7`, `array_create@3`, `json_parse@9`, or
	///          `unknown` for a parameter, a call result and anything read from outside a local). The analysis is
	///          the one `gmlc_analyses` runs.
	/// @self    GMLC_Opt_AliasAnalysis
	/// @param   {Struct.ASTNode} _root  : The function node, or the script for the file's own body
	/// @param   {Real}           _fn_id : The function's fn_id, 0 for the script
	/// @returns {Struct} {sites: {name: Array<String>}}
	#endregion
	static analyze = function(_root, _fn_id) {
		var _facts = { sites: {} };
		var _unit;
		if (_root.kind == __GMLC_NodeKind_Script) {
			_unit = { fn_id: 0, params: [], body: _root.body, node: undefined };
		}
		else {
			var _params = [];
			var _p = 0; repeat (array_length(_root.params)) {
				array_push(_params, _root.params[_p].target);
			_p++}
			_unit = { fn_id: _fn_id, params: _params, body: _root.body.body, node: _root };
		}
		var _alias = __gmlc_analyze_alias(_unit);
		var _i = 0; repeat (array_length(_alias)) {
			_facts.sites[$ _alias[_i].name] = _alias[_i].sites;
		_i++}
		return _facts;
	};
	
	#region jsDoc
	/// @func    isKnown(_facts, _name)
	/// @desc    Whether the sites of a local are all known allocation sites: it holds some reference and never an
	///          unknown one.
	/// @self    GMLC_Opt_AliasAnalysis
	/// @param   {Struct} _facts : The facts of `analyze`
	/// @param   {String} _name  : The local
	/// @returns {Bool}
	#endregion
	static isKnown = function(_facts, _name) {
		var _sites = _facts.sites[$ _name];
		return (_sites != undefined) && (array_length(_sites) > 0) && (!array_contains(_sites, "unknown"));
	};
	
	#region jsDoc
	/// @func    mayAlias(_facts, _a, _b)
	/// @desc    Whether two locals may hold the same object: their sites intersect, or either is not fully known.
	/// @self    GMLC_Opt_AliasAnalysis
	/// @param   {Struct} _facts : The facts of `analyze`
	/// @param   {String} _a     : A local
	/// @param   {String} _b     : Another local
	/// @returns {Bool}
	#endregion
	static mayAlias = function(_facts, _a, _b) {
		if (!isKnown(_facts, _a)) || (!isKnown(_facts, _b)) return true;
		var _sites_a = _facts.sites[$ _a];
		var _sites_b = _facts.sites[$ _b];
		var _i = 0; repeat (array_length(_sites_a)) {
			if (array_contains(_sites_b, _sites_a[_i])) return true;
		_i++}
		return false;
	};
	#endregion
}
