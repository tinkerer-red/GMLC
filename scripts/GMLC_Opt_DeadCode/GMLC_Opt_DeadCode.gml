#region jsDoc
/// @func    GMLC_Opt_DeadCode()
/// @desc    `dead-code`: removes code that never runs because a constant decides it: a branch a constant condition
///          never takes, a loop that never runs, a call whose folded value does nothing. The optimizer's sweep calls
///          `sweep` on each node, inner ones first.
/// @returns {Struct.GMLC_Opt_DeadCode}
#endregion
function GMLC_Opt_DeadCode() : GMLC_OptimizerPass("dead-code") constructor {
	#region Sweep
	#region jsDoc
	/// @func    sweep(_node_data, _o)
	/// @desc    Removes the code a node holds that never runs. Returns the node to put in its place, the one it was
	///          given when nothing goes.
	/// @self    GMLC_Opt_DeadCode
	/// @param   {Struct}                      _node_data : {node, parent, key, index}
	/// @param   {Struct.GMLC_Gen_5_Optimizer} _o         : The optimizer
	/// @returns {Struct.ASTNode}
	#endregion
	static sweep = function(_node_data, _o) {
		var _node   = _node_data.node;
		var _parent = _node_data.parent;
		var _key    = _node_data.key;
		var _index  = _node_data.index;
	    
		switch (_node.kind) {
			case __GMLC_NodeKind_If:{
				var _test = _o.__constantValue(_node.test);
				if (_test[0]) && (is_numeric(_test[1])) {
					if (_test[1]) {
						if (_node.alternate == undefined) || (!_o.__keepsStatements(_node.alternate)) {
							return _node.consequent;
						}
					}
					else if (!_o.__keepsStatements(_node.consequent)) {
						if (_node.alternate != undefined) {
							return _node.alternate;
						}
						else {
							return new ASTEmpty(_node.span);
						}
					}
				}
			break;}
			case __GMLC_NodeKind_For:{
				if (_node.test != undefined) {
					var _test = _o.__constantValue(_node.test);
					if (_test[0]) && (is_numeric(_test[1])) && (!_test[1])
					&& (!_o.__keepsStatements(_node.body)) && ((_node.update == undefined) || (!_o.__keepsStatements(_node.update)))
					{
						// the init still runs once
						return _node.init ?? new ASTEmpty(_node.span);
					}
				}
			break;}
			case __GMLC_NodeKind_While:{
				if (_node.test != undefined) {
					var _test = _o.__constantValue(_node.test);
					if (_test[0]) && (is_numeric(_test[1])) && (!_test[1]) && (!_o.__keepsStatements(_node.body)) {
						return new ASTEmpty(_node.span);
					}
				}
			break;}
			case __GMLC_NodeKind_Repeat:{
				if (_node.count != undefined) {
					var _count = _o.__constantValue(_node.count);
					if (_count[0]) && (is_numeric(_count[1])) && (_count[1] <= 0) && (!_o.__keepsStatements(_node.body)) {
						return new ASTEmpty(_node.span);
					}
				}
			break;}
			case __GMLC_NodeKind_DoUntil:{
				/// There isnt really a way to optimizer this on the AST level, we can convert this into a breakable block statement on compile level, however if we want to re export as a string we dont want to mess with this on the AST optimization level.
			break;}
			case __GMLC_NodeKind_With:{
				var _target = _o.__constantValue(_node.target);
				if (_target[0]) && (is_numeric(_target[1])) && (!_o.__keepsStatements(_node.body)) {
					if (_target[1] == noone) {
						return new ASTEmpty(_node.span);
					}
				}
			break;}
			case __GMLC_NodeKind_Switch:{
				/// this was trash and doesnt account for inner statements breaking out, additionally it complicates break statements, and re exporting the code.
			break;}
			case __GMLC_NodeKind_Conditional:{
				return _o.__foldConditional(_node_data);
			break;}
			case __GMLC_NodeKind_ExprStmt:{
				// a call folded to its value does nothing, and a value on its own is not a statement GameMaker accepts
				var _value = _o.__constantValue(_node.expression);
				if (_value[0]) && (!_o.__keepsCode(_node.expression)) {
					return new ASTEmpty(_node.span);
				}
			break;}
		}

		return _node;
	};
	#endregion
}
