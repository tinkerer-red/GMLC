#region jsDoc
/// @func    GMLC_Opt_BranchMerge()
/// @desc    The `branch-merge` optimizer pass. `if (a) { if (b) { s; } }` with no `else` on either `if` becomes
///          `if (a && b) { s; }`, and statements that end both arms of an `if`/`else` the same way are written
///          once after it: `if (c) { x(); end(); } else { y(); end(); }` becomes
///          `if (c) { x(); } else { y(); } end();`.
/// @returns {Struct.GMLC_Opt_BranchMerge}
#endregion
function GMLC_Opt_BranchMerge() : GMLC_OptimizerPass("branch-merge") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The statement list with its `if` statements merged, or undefined when none is.
	/// @self    GMLC_Opt_BranchMerge
	/// @param   {Struct.ASTNode} _node : The statement list
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _body = _node.body;
		var _out = [];
		var _changed = false;
		var _i = 0; repeat (array_length(_body)) {
			var _stmt = _body[_i];
			var _tail = undefined;
			if (_stmt.kind == __GMLC_NodeKind_If) && (!_cx.optimizer.__isNoOp(_stmt)) {
				var _merged = __mergeChain(_stmt, _cx);
				if (_merged != undefined) {
					_stmt = _merged;
					_changed = true;
				}
				var _tails = __mergeTails(_stmt, _cx);
				if (_tails != undefined) {
					_stmt = _tails.stmt;
					_tail = _tails.tail;
					_changed = true;
				}
			}
			array_push(_out, _stmt);
			if (_tail != undefined) {
				array_copy(_out, array_length(_out), _tail, 0, array_length(_tail));
			}
		_i++}
		if (!_changed) return undefined;
		var _copy = variable_clone(_node, 0);
		_copy.body = _out;
		return _copy;
	};
	#endregion

	#region Private
	#region jsDoc
	/// @func    __mergeChain(_if, _cx)
	/// @desc    An `if` with the nested `if` statements of its body merged into its condition, and the same for
	///          the `else if` that follows it; undefined when nothing merges.
	/// @self    GMLC_Opt_BranchMerge
	/// @param   {Struct.ASTIf} _if : The statement
	/// @param   {Struct}       _cx : The pass context
	/// @returns {Struct.ASTIf|Undefined}
	#endregion
	static __mergeChain = function(_if, _cx) {
		var _node = _if;
		var _changed = false;
		while (true) {
			var _inner = __nestedIf(_node, _cx);
			if (_inner == undefined) break;
			_cx.stats[$ "merged"]++;
			var _test = new ASTLogical(_node.test.span, "&&", _node.test, _inner.test);
			_node = new ASTIf(_node.span, _test, _inner.consequent, undefined, _node.origin);
			_changed = true;
		}
		var _else = _node.alternate;
		if (_else != undefined) && (_else.kind == __GMLC_NodeKind_If) && (!_cx.optimizer.__isNoOp(_else)) {
			var _merged = __mergeChain(_else, _cx);
			if (_merged != undefined) {
				_node = new ASTIf(_node.span, _node.test, _node.consequent, _merged, _node.origin);
				_changed = true;
			}
		}
		return _changed ? _node : undefined;
	};

	#region jsDoc
	/// @func    __nestedIf(_node, _cx)
	/// @desc    The `if` that is all of the body of an `if` that has no `else`, when that one has none either.
	/// @self    GMLC_Opt_BranchMerge
	/// @param   {Struct.ASTIf} _node : The outer statement
	/// @param   {Struct}       _cx   : The pass context
	/// @returns {Struct.ASTIf|Undefined}
	#endregion
	static __nestedIf = function(_node, _cx) {
		if (_node.alternate != undefined) return undefined;
		var _body = _node.consequent;
		var _inner = _body;
		if (_body.kind == __GMLC_NodeKind_Block) {
			if (array_length(_body.body) != 1) return undefined;
			_inner = _body.body[0];
		}
		if (_inner.kind != __GMLC_NodeKind_If) || (_inner.alternate != undefined) return undefined;
		if (_cx.optimizer.__isNoOp(_node)) || (_cx.optimizer.__isNoOp(_inner)) return undefined;
		return _inner;
	};

	#region jsDoc
	/// @func    __mergeTails(_if, _cx)
	/// @desc    An `if`/`else` without the statements that end both arms the same way, and those statements to
	///          write after it. The copies of the `else` arm are the ones kept, so the lines stay in order. Nothing
	///          happens when both arms would be empty.
	/// @self    GMLC_Opt_BranchMerge
	/// @param   {Struct.ASTIf} _if : The statement
	/// @param   {Struct}       _cx : The pass context
	/// @returns {Struct|Undefined} {stmt, tail}
	#endregion
	static __mergeTails = function(_if, _cx) {
		var _then = _if.consequent;
		var _else = _if.alternate;
		if (_else == undefined) || (_then.kind != __GMLC_NodeKind_Block) || (_else.kind != __GMLC_NodeKind_Block) return undefined;
		var _a = _then.body;
		var _b = _else.body;
		var _na = array_length(_a);
		var _nb = array_length(_b);
		var _k = 0;
		while ((_k < _na) && (_k < _nb)) {
			var _x = _a[_na - 1 - _k];
			var _y = _b[_nb - 1 - _k];
			if (!__hoistable(_x)) || (!__gmlc_opt_same(_x, _y)) || (_cx.optimizer.__isNoOp(_x)) || (_cx.optimizer.__isNoOp(_y)) break;
			_k++;
		}
		if (_k == 0) || ((_k == _na) && (_k == _nb)) return undefined;
		var _head_then = array_create(_na - _k);
		array_copy(_head_then, 0, _a, 0, _na - _k);
		var _head_else = array_create(_nb - _k);
		array_copy(_head_else, 0, _b, 0, _nb - _k);
		var _tail = array_create(_k);
		array_copy(_tail, 0, _b, _nb - _k, _k);
		var _new_else = (_nb - _k > 0) ? new ASTBlock(_else.span, _head_else, _else.origin) : undefined;
		var _stmt = new ASTIf(_if.span, _if.test, new ASTBlock(_then.span, _head_then, _then.origin), _new_else, _if.origin);
		_cx.stats[$ "tails_merged"] += _k;
		return { stmt: _stmt, tail: _tail };
	};

	#region jsDoc
	/// @func    __hoistable(_stmt)
	/// @desc    Whether a statement may move out of an arm of an `if`: a declaration that runs once, or that is
	///          known to the whole file, may not.
	/// @self    GMLC_Opt_BranchMerge
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @returns {Bool}
	#endregion
	static __hoistable = function(_stmt) {
		switch (_stmt.kind) {
			case __GMLC_NodeKind_StaticDecl: case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl:
			case __GMLC_NodeKind_GlobalVarDecl: case __GMLC_NodeKind_EnumDecl: case __GMLC_NodeKind_MacroDecl:
			return false;
		}
		return true;
	};
	#endregion
}
