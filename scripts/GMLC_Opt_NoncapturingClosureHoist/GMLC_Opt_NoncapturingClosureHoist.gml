#region jsDoc
/// @func    GMLC_Opt_NoncapturingClosureHoist()
/// @desc    A function literal that uses nothing of the code around it, passed straight to a built-in that applies it
///          and keeps no reference, becomes one function made once: `array_sort(_list, function(_a, _b) { return
///          _a.z - _b.z; });` becomes `static __gmlc_t0 = function(_a, _b) { return _a.z - _b.z; };` before the
///          statement and `array_sort(_list, __gmlc_t0);`. Only functions declared with `function name() {}` are
///          changed; the literal must not use `self`, `other`, instance variables, statics, `with`, or any call that
///          could read them.
/// @returns {Struct.GMLC_Opt_NoncapturingClosureHoist}
#endregion
function GMLC_Opt_NoncapturingClosureHoist() : GMLC_OptimizerPass("noncapturing-closure-hoist") constructor {
	#region Config
	// built-ins that call the function given as their second argument and keep no reference to it
	static callbacks = ["array_foreach", "array_map", "array_filter", "array_reduce", "array_any", "array_all", "array_find_index", "array_sort", "array_create_ext", "struct_foreach"];
	#endregion

	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Moves each literal that captures nothing into a static declared before the statement that holds it.
	/// @self    GMLC_Opt_NoncapturingClosureHoist
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		if (_node.kind != __GMLC_NodeKind_FunctionDecl) return undefined;
		var _state = { apply: false, cx: _cx, statement: 0, count: 0, inserts: [] };
		var _statements = _node.body.body;
		var _i = 0; repeat (array_length(_statements)) {
			_state.statement = _i;
			__walk(_statements[_i], _state, false);
		_i++}
		if (_state.count == 0) return undefined;
		var _new = __gmlc_opt_clone(_node);
		_state.apply = true;
		_statements = _new.body.body;
		_i = 0; repeat (array_length(_statements)) {
			_state.statement = _i;
			__walk(_statements[_i], _state, false);
		_i++}
		var _body = [];
		var _inserts = _state.inserts;
		_i = 0; repeat (array_length(_statements)) {
			var _j = 0; repeat (array_length(_inserts)) {
				if (_inserts[_j].statement == _i) array_push(_body, _inserts[_j].declaration);
			_j++}
			array_push(_body, _statements[_i]);
		_i++}
		_new.body.body = _body;
		return _new;
	};
	#endregion

	#region Private
	#region jsDoc
	/// @func    __walk(_node, _state, _in_with)
	/// @desc    Finds the literals to hoist under a statement, nested functions left out; when the state applies, the
	///          node is a copy this pass owns, and each literal found is replaced by its static's name.
	/// @self    GMLC_Opt_NoncapturingClosureHoist
	/// @param   {Struct.ASTNode} _node    : The node
	/// @param   {Struct}         _state   : {apply, cx, statement, count, inserts}
	/// @param   {Bool}           _in_with : Whether the node is inside a `with`
	#endregion
	static __walk = function(_node, _state, _in_with) {
		if (__gmlc_opt_is_function(_node)) return;
		var _cx = _state.cx;
		if (_node.kind == __GMLC_NodeKind_Call) && (!_in_with) && (array_length(_node.args) >= 2) {
			var _builtin = __gmlc_opt_builtin_call(_node);
			var _literal = _node.args[1];
			if (_builtin != undefined) && array_contains(callbacks, _builtin) && (_literal.kind == __GMLC_NodeKind_FunctionExpr)
			&& (!_literal.is_constructor) && (_literal.parent == undefined) && (!_cx.optimizer.__isNoOp(_literal)) && (!_cx.optimizer.__isNoOp(_node)) && __closed(_literal) {
				_state.count++;
				if (_state.apply) {
					var _name = _cx.optimizer.newTemporary(_cx);
					_cx.stats[$ "hoisted"]++;
					var _use = new ASTIdentifier(_literal.span, _name);
					_use.symbol = new GMLC_Symbol("Static", _name, undefined);
					var _target = new ASTIdentifier(_literal.span, _name);
					_target.symbol = new GMLC_Symbol("Static", _name, undefined);
					_node.args[1] = _use;
					array_push(_state.inserts, { statement: _state.statement, declaration: new ASTStaticDecl(_literal.span, [new ASTVarDecl(_literal.span, _target, _literal)]) });
				}
			}
		}
		var _inside = _in_with || (_node.kind == __GMLC_NodeKind_With);
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__walk(_child, _state, _inside);
				}
			_i++}
		_field_index++}
	};

	#region jsDoc
	/// @func    __closed(_node)
	/// @desc    Whether nothing under a function literal depends on the code around it: every name is a local of its
	///          own, or a global, built-in, enum, macro or asset name; no call can read `self` (only pure built-ins,
	///          `new` of a constructor, and calls on a value); no `with` and no `static`.
	/// @self    GMLC_Opt_NoncapturingClosureHoist
	/// @param   {Struct.ASTNode} _node : The literal, or a node under it
	/// @returns {Bool}
	#endregion
	static __closed = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				if (_symbol == undefined) return false;
				switch (_symbol.kind) {
					case "Local": case "Global": case "BuiltinFunction": case "BuiltinConstant": case "Enum": case "Macro": case "Asset":
					return true;
				}
				return false;
			}
			case __GMLC_NodeKind_With:
			case __GMLC_NodeKind_StaticDecl:
			case __GMLC_NodeKind_GlobalVarDecl:
			return false;
			case __GMLC_NodeKind_Call: {
				var _builtin = __gmlc_opt_builtin_call(_node);
				if (_builtin == undefined) || (__gmlc_opt_call_class(_builtin) != "pure") return false;
				var _a = 0; repeat (array_length(_node.args)) {
					if (!__closed(_node.args[_a])) return false;
				_a++}
				return true;
			}
			case __GMLC_NodeKind_New: {
				var _callee = _node.callee;
				if (_callee.kind != __GMLC_NodeKind_Identifier) || (_callee.symbol == undefined) || (_callee.symbol.kind != "Global") return false;
				var _b = 0; repeat (array_length(_node.args)) {
					if (!__closed(_node.args[_b])) return false;
				_b++}
				return true;
			}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__closed(_child)) return false;
				}
			_i++}
		_field_index++}
		return true;
	};
	#endregion
}
