#region jsDoc
/// @func    GMLC_Opt_CodeSinking()
/// @desc    The `code-sinking` optimizer pass: a trivial local definition that only one branch of a later `if`
///          reads moves into that branch, so the other paths skip it. `var _a = _b; if (_c) { f(_a); }` becomes
///          `if (_c) { var _a = _b; f(_a); }`; a value that can throw or has effects stays where it is.
/// @returns {Struct.GMLC_Opt_CodeSinking}
#endregion
function GMLC_Opt_CodeSinking() : GMLC_OptimizerPass("code-sinking") constructor {
	#region Run
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The function with every sinkable definition moved into its branch, or undefined when none is.
	/// @self    GMLC_Opt_CodeSinking
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _state = { optimizer: _cx.optimizer, cx: _cx, root: _node, reads: {}, writes: {}, params: __gmlc_opt_function_param_names(_node) };
		return __gmlc_opt_rewritten_lists(_node, _state, true, method(self, __list));
	};
	#endregion
	
	#region Candidates
	#region jsDoc
	/// @func    __list(_body, _state)
	/// @desc    Sinks the definitions of one statement list, last to first, so definitions that depend on each other
	///          keep their order inside the branch.
	/// @self    GMLC_Opt_CodeSinking
	/// @param   {Array<Struct.ASTNode>} _body  : The statements
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list, undefined when nothing changed
	#endregion
	static __list = function(_body, _state) {
		var _list = _body;
		var _changed = false;
		var _i = array_length(_body) - 1; repeat (array_length(_body)) {
			var _hit = __candidate(_list, _i, _state);
			if (_hit != undefined) {
				if (!_changed) {
					_list = variable_clone(_body, 0);
					_changed = true;
				}
				_list[_hit.target] = _hit.statement;
				array_delete(_list, _i, 1);
				_state.cx.stats[$ "sunk"]++;
			}
		_i--}
		return _changed ? _list : undefined;
	};
	
	#region jsDoc
	/// @func    __candidate(_list, _index, _state)
	/// @desc    Whether the statement at an index is a definition that moves into the one branch that reads it.
	/// @self    GMLC_Opt_CodeSinking
	/// @param   {Array<Struct.ASTNode>} _list  : The statements
	/// @param   {Real}                  _index : The definition's place
	/// @param   {Struct}                _state : The pass's state
	/// @returns {Struct|Undefined} {target, statement}: the place of the `if` and what replaces it
	#endregion
	static __candidate = function(_list, _index, _state) {
		var _stmt = _list[_index];
		if (_stmt.kind != __GMLC_NodeKind_VarDeclList) || (array_length(_stmt.declarations) != 1) return undefined;
		var _decl = _stmt.declarations[0];
		if (_decl.init == undefined) || (!__gmlc_opt_is_local(_decl.target)) return undefined;
		var _name = _decl.target.name;
		var _optimizer = _state.optimizer;
		if (array_contains(_state.params, _name)) || (_optimizer.__containsNoOp(_stmt)) return undefined;
		// only a value that cannot throw, has no effects and reads nothing but locals may be skipped
		if (!__gmlc_opt_is_trivial(_decl.init)) return undefined;
		var _reads = __gmlc_opt_count_reads(_state.root, _state.reads, _name);
		if (_reads < 1) || (__gmlc_opt_count_writes(_state.root, _state.writes, _name) != 1) return undefined;
		
		var _names = [];
		__gmlc_opt_collect_local_names(_decl.init, _names);
		var _target = -1;
		var _k = _index + 1; repeat (array_length(_list) - _index - 1) {
			var _between = _list[_k];
			if (__gmlc_opt_reads(_between, _name) > 0) {
				_target = _k;
				break;
			}
			if (_optimizer.__containsNoOp(_between)) return undefined;
			var _n = 0; repeat (array_length(_names)) {
				if (__gmlc_opt_writes(_between, _names[_n])) return undefined;
			_n++}
		_k++}
		if (_target < 0) return undefined;
		
		var _branch = _list[_target];
		if (_branch.kind != __GMLC_NodeKind_If) || (_optimizer.__containsNoOp(_branch)) return undefined;
		if (__gmlc_opt_reads(_branch.test, _name) > 0) return undefined;
		var _n = 0; repeat (array_length(_names)) {
			if (__gmlc_opt_writes(_branch.test, _names[_n])) return undefined;
		_n++}
		
		var _key;
		var _then_reads = __gmlc_opt_reads(_branch.consequent, _name);
		var _else_reads = (_branch.alternate == undefined) ? 0 : __gmlc_opt_reads(_branch.alternate, _name);
		if (_then_reads == _reads) {
			_key = "consequent";
		}
		else if (_else_reads == _reads) {
			_key = "alternate";
		}
		else {
			return undefined;
		}
		var _block = _branch[$ _key];
		if (_block.kind != __GMLC_NodeKind_Block) return undefined;
		
		var _body = variable_clone(_block.body, 0);
		var _moved = __gmlc_opt_clone(_stmt);
		__gmlc_opt_retag_span(_moved, __gmlc_opt_span_point((array_length(_block.body) > 0) ? _block.body[0].span : _block.span));
		array_insert(_body, 0, _moved);
		var _new_block = __gmlc_opt_rebuild_children(_block, [{ key: "body", index: undefined, node: _body }]);
		return { target: _target, statement: __gmlc_opt_rebuild_children(_branch, [{ key: _key, index: undefined, node: _new_block }]) };
	};
	#endregion
	
	#region Facts about locals
	#endregion
}
