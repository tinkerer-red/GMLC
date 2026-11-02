#region jsDoc
/// @func    GMLC_Opt_SimplifyCfgBlocks()
/// @desc    Flattens a block that sits directly in a statement list and drops empty statements:
///          `if (hp <= 0) { { instance_destroy(); }; }` becomes `if (hp <= 0) { instance_destroy(); }`.
///          Code under `@NoOp` stays as written.
/// @returns {Struct.GMLC_Opt_SimplifyCfgBlocks}
#endregion
function GMLC_Opt_SimplifyCfgBlocks() : GMLC_OptimizerPass("simplify-cfg-blocks") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The statement list with its nested blocks flattened and its empty statements dropped, or undefined
	///          when it has none.
	/// @self    GMLC_Opt_SimplifyCfgBlocks
	/// @param   {Struct.ASTNode} _node : The statement list
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _flat = [];
		if (!__flatten(_node.body, _flat, _cx)) return undefined;
		var _copy = variable_clone(_node, 0);
		_copy.body = _flat;
		return _copy;
	};
	#endregion

	#region Private
	#region jsDoc
	/// @func    __flatten(_statements, _out, _cx)
	/// @desc    Adds the statements to a list, a block in place of its own statements and no empty statement; a
	///          block inside such a block is flattened the same way.
	/// @self    GMLC_Opt_SimplifyCfgBlocks
	/// @param   {Array<Struct.ASTNode>} _statements : The statements
	/// @param   {Array<Struct.ASTNode>} _out        : The list that receives them
	/// @param   {Struct}                _cx         : The pass context
	/// @returns {Bool} Whether anything was flattened or dropped
	#endregion
	static __flatten = function(_statements, _out, _cx) {
		var _changed = false;
		var _optimizer = _cx.optimizer;
		var _i = 0; repeat (array_length(_statements)) {
			var _statement = _statements[_i];
			var _kind = _statement.kind;
			if ((_kind == __GMLC_NodeKind_Empty) || (_kind == __GMLC_NodeKind_Block)) && (!_optimizer.__isNoOp(_statement)) {
				_changed = true;
				if (_kind == __GMLC_NodeKind_Block) {
					_cx.stats[$ "blocks_flattened"]++;
					__flatten(_statement.body, _out, _cx);
				}
				else {
					_cx.stats[$ "empties_removed"]++;
				}
			}
			else {
				array_push(_out, _statement);
			}
		_i++}
		return _changed;
	};
	#endregion
}
