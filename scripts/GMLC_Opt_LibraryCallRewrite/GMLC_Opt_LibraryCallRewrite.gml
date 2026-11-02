#region jsDoc
/// @func    GMLC_Opt_LibraryCallRewrite()
/// @desc    `library-call-rewrite`: replaces a call of a library function by the faster one for the task: `string(x)`
///          of a value known to be a string, not a literal, becomes `string_concat(x)`, which skips the extra checks
///          `string` makes; for a number `string` is the faster one. The optimizer's sweep calls `sweep` on each node,
///          inner ones first.
/// @returns {Struct.GMLC_Opt_LibraryCallRewrite}
#endregion
function GMLC_Opt_LibraryCallRewrite() : GMLC_OptimizerPass("library-call-rewrite") constructor {
	#region Sweep
	#region jsDoc
	/// @func    sweep(_node_data, _o)
	/// @desc    Rewrites the library call a node is. Returns the node to put in its place, the one it was given when
	///          nothing changes.
	/// @self    GMLC_Opt_LibraryCallRewrite
	/// @param   {Struct}                      _node_data : {node, parent, key, index}
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _o         : The optimizer
	/// @returns {Struct.ASTNode}
	#endregion
	static sweep = function(_node_data, _o) {
		var _node   = _node_data.node;
		var _parent = _node_data.parent;
		var _key    = _node_data.key;
		var _index  = _node_data.index;
		
		// GameMaker hashes a constant struct key itself, so `struct_get(s, "k")` is left as written
		if (_node.kind == __GMLC_NodeKind_Call) {
			switch (_o.__calleeFunction(_node)) {
				case string:{
					// string_concat is faster than string only for a string; for a number it is slower
					if (array_length(_node.args) == 1) && (_o.env.isFunction("string_concat")) {
						var _arg = _node.args[0]
						if (_arg.kind != __GMLC_NodeKind_Literal) && (__gmlc_opt_value_type(_arg) == "String") {
							return new ASTCall(_node.span, _o.__builtin("string_concat", _node.span), _node.args);
						}
					}
				break;}
			}
		}
		
		return _node;
	};
	#endregion

}
