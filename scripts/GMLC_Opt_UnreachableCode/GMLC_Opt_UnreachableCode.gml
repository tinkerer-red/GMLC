#region jsDoc
/// @func    GMLC_Opt_UnreachableCode()
/// @desc    Deletes the statements that follow a `return`, `exit`, `throw`, `break` or `continue` in the same
///          statement list: `return true; audio_play_sound(snd_hit, 1, false);` becomes `return true;`. A `case`
///          label starts a new list, so it is never cut. Declarations in the dead tail stay: a `static`, a function
///          and a `var` (it binds later uses of its name). Code under `@NoOp` stays as written.
/// @returns {Struct.GMLC_Opt_UnreachableCode}
#endregion
function GMLC_Opt_UnreachableCode() : GMLC_OptimizerPass("unreachable-code") constructor {
	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The statement list without the statements after its first unconditional exit, or undefined when
	///          nothing can go.
	/// @self    GMLC_Opt_UnreachableCode
	/// @param   {Struct.ASTNode} _node : The statement list
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _body = _node.body;
		var _count = array_length(_body);
		var _cut = __terminator(_body, _cx);
		if (_cut < 0) return undefined;
		var _kept = array_create(_cut + 1);
		array_copy(_kept, 0, _body, 0, _cut + 1);
		var _removed = 0;
		var _i = _cut + 1; repeat (_count - _cut - 1) {
			var _statement = _body[_i];
			if (__keeps(_statement, _cx)) {
				array_push(_kept, _statement);
			}
			else {
				_removed++;
			}
		_i++}
		if (_removed == 0) return undefined;
		_cx.stats[$ "statements_removed"] += _removed;
		var _copy = variable_clone(_node, 0);
		_copy.body = _kept;
		return _copy;
	};
	#endregion

	#region Private
	#region jsDoc
	/// @func    __terminator(_statements, _cx)
	/// @desc    The index of the first statement of a list that always leaves it.
	/// @self    GMLC_Opt_UnreachableCode
	/// @param   {Array<Struct.ASTNode>} _statements : The statements
	/// @param   {Struct}                _cx         : The pass context
	/// @returns {Real} The index, -1 for none
	#endregion
	static __terminator = function(_statements, _cx) {
		var _i = 0; repeat (array_length(_statements)) {
			if (__terminates(_statements[_i], _cx)) return _i;
		_i++}
		return -1;
	};

	#region jsDoc
	/// @func    __terminates(_statement, _cx)
	/// @desc    Whether control never continues past a statement: a jump, a block that holds one, or an `if` whose
	///          two branches both end in one.
	/// @self    GMLC_Opt_UnreachableCode
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {Struct}         _cx        : The pass context
	/// @returns {Bool}
	#endregion
	static __terminates = function(_statement, _cx) {
		if (_cx.optimizer.__isNoOp(_statement)) return false;
		switch (_statement.kind) {
			case __GMLC_NodeKind_Return:
			case __GMLC_NodeKind_Exit:
			case __GMLC_NodeKind_Throw:
			case __GMLC_NodeKind_Break:
			case __GMLC_NodeKind_Continue:
			return true;
			case __GMLC_NodeKind_Block:
			return (__terminator(_statement.body, _cx) >= 0);
			case __GMLC_NodeKind_If:
			return (_statement.alternate != undefined) && __terminates(_statement.consequent, _cx) && __terminates(_statement.alternate, _cx);
		}
		return false;
	};

	#region jsDoc
	/// @func    __keeps(_statement, _cx)
	/// @desc    Whether a dead statement has to stay: frozen or referencing an asset, or declaring something.
	/// @self    GMLC_Opt_UnreachableCode
	/// @param   {Struct.ASTNode} _statement : The statement
	/// @param   {Struct}         _cx        : The pass context
	/// @returns {Bool}
	#endregion
	static __keeps = function(_statement, _cx) {
		if (_cx.optimizer.__isNoOp(_statement)) || (_cx.optimizer.__keepsCode(_statement)) return true;
		return __gmlc_opt_declares(_statement);
	};

	#endregion
}
