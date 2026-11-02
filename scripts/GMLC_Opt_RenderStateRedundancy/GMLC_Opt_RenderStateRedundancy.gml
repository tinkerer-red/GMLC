#region jsDoc
/// @func    GMLC_Opt_RenderStateRedundancy()
/// @desc    Removes a draw or GPU state setter that repeats the call before it with the same arguments while nothing
///          between the two can change the state: `draw_set_alpha(1); draw_text(8, 8, a); draw_set_alpha(1);` loses
///          the second call. Arguments must be literals, constants, assets, locals nobody writes between the calls and
///          pure functions of those; between the calls only pure and observer functions and drawing functions that
///          take their colors as arguments may be called.
/// @returns {Struct.GMLC_Opt_RenderStateRedundancy}
#endregion
function GMLC_Opt_RenderStateRedundancy() : GMLC_OptimizerPass("render-state-redundancy") constructor {
	#region Config
	static __setters = {
		draw_set_colour: { attribute: "color", arguments: 1 },
		draw_set_color: { attribute: "color", arguments: 1 },
		draw_set_alpha: { attribute: "alpha", arguments: 1 },
		draw_set_font: { attribute: "font", arguments: 1 },
		draw_set_halign: { attribute: "halign", arguments: 1 },
		draw_set_valign: { attribute: "valign", arguments: 1 },
		gpu_set_blendenable: { attribute: "blendenable", arguments: 1 },
		gpu_set_blendmode: { attribute: "blendmode", arguments: 1 },
		gpu_set_blendmode_ext: { attribute: "blendmode", arguments: 2 },
		gpu_set_blendmode_ext_sepalpha: { attribute: "blendmode", arguments: 4 },
		gpu_set_ztestenable: { attribute: "ztest", arguments: 1 },
		gpu_set_zwriteenable: { attribute: "zwrite", arguments: 1 },
		gpu_set_cullmode: { attribute: "cullmode", arguments: 1 },
		gpu_set_fog: { attribute: "fog", arguments: 4 },
		gpu_set_texfilter: { attribute: "texfilter", arguments: 1 },
		gpu_set_tex_filter: { attribute: "texfilter", arguments: 1 },
		gpu_set_tex_repeat: { attribute: "texrepeat", arguments: 1 },
		gpu_set_colorwriteenable: { attribute: "colorwrite", arguments: 4 },
		shader_set: { attribute: "shader", arguments: 1 },
		shader_reset: { attribute: "shader", arguments: 0 },
	};
	#endregion

	#region Public
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    The node to put in the place of _node, or undefined to keep it.
	/// @self    GMLC_Opt_RenderStateRedundancy
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		return __gmlc_opt_rewrite_lists(_node, _cx, true, method(self, __list));
	};
	#endregion

	#region Private
	#region Rewrite
	#region jsDoc
	/// @func    __list(_stmts, _cx)
	/// @desc    Follows the state setters of a statement list and drops each one that repeats the setter before it.
	///          A statement that is not a setter, a harmless call or an assignment forgets everything known; an
	///          assignment forgets the setters whose arguments read the local it writes.
	/// @self    GMLC_Opt_RenderStateRedundancy
	/// @param   {Array<Struct.ASTNode>} _stmts : A statement list
	/// @param   {Struct}                _cx    : The pass context
	/// @returns {Array<Struct.ASTNode>|Undefined} The new list
	#endregion
	static __list = function(_stmts, _cx) {
		var _known = {};
		var _drop = undefined;
		var _count = array_length(_stmts);
		var _i = 0; repeat (_count) {
			var _stmt = _stmts[_i];
			var _call = __setterCall(_stmt, _cx);
			if (_call != undefined) {
				var _setter = __setters[$ _call.callee.name];
				var _prior = _known[$ _setter.attribute];
				if (_prior != undefined) && (_prior.name == _call.callee.name) && (__sameArguments(_prior.args, _call.args)) {
					if (_drop == undefined) _drop = array_create(_count, false);
					_drop[_i] = true;
					_cx.stats[$ "setters_removed"]++;
				}
				else {
					var _stable = true;
					var _a = 0; repeat (array_length(_call.args)) {
						if (!__stable(_call.args[_a])) _stable = false;
					_a++}
					if (_stable) {
						_known[$ _setter.attribute] = { name: _call.callee.name, args: _call.args };
					}
					else {
						struct_remove(_known, _setter.attribute);
					}
				}
			}
			else if (__clean(_stmt, _cx)) {
				var _attributes = struct_get_names(_known);
				var _k = 0; repeat (array_length(_attributes)) {
					if (__writesArguments(_stmt, _known[$ _attributes[_k]].args)) struct_remove(_known, _attributes[_k]);
				_k++}
			}
			else {
				_known = {};
			}
		_i++}
		if (_drop == undefined) return undefined;
		var _out = [];
		var _j = 0; repeat (_count) {
			if (!_drop[_j]) array_push(_out, _stmts[_j]);
		_j++}
		return _out;
	};
	#endregion

	#region Questions
	#region jsDoc
	/// @func    __setterCall(_stmt, _cx)
	/// @desc    The call of a statement that is only a call of a state setter with its full arguments, or undefined.
	/// @self    GMLC_Opt_RenderStateRedundancy
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTCall|Undefined}
	#endregion
	static __setterCall = function(_stmt, _cx) {
		if (_stmt.kind != __GMLC_NodeKind_ExprStmt) return undefined;
		var _call = _stmt.expression;
		var _name = __gmlc_opt_builtin_call(_call);
		if (_name == undefined) return undefined;
		var _setter = __setters[$ _name];
		if (_setter == undefined) || (array_length(_call.args) != _setter.arguments) return undefined;
		var _i = 0; repeat (array_length(_call.args)) {
			if (_call.args[_i].kind == __GMLC_NodeKind_Empty) return undefined;
		_i++}
		if (_cx.optimizer.__isNoOp(_stmt)) return undefined;
		return _call;
	};

	#region jsDoc
	/// @func    __sameArguments(_a, _b)
	/// @desc    Whether two argument lists are the same code.
	/// @self    GMLC_Opt_RenderStateRedundancy
	/// @param   {Array<Struct.ASTNode>} _a : An argument list
	/// @param   {Array<Struct.ASTNode>} _b : Another
	/// @returns {Bool}
	#endregion
	static __sameArguments = function(_a, _b) {
		if (array_length(_a) != array_length(_b)) return false;
		var _i = 0; repeat (array_length(_a)) {
			if (!__gmlc_opt_same(_a[_i], _b[_i])) return false;
		_i++}
		return true;
	};

	#region jsDoc
	/// @func    __stable(_node)
	/// @desc    Whether an expression has the same value each time it is evaluated while the locals it reads are
	///          unchanged: literals, constants, assets, locals, operators on those and calls of deterministic pure
	///          functions on those.
	/// @self    GMLC_Opt_RenderStateRedundancy
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __stable = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal:
			return true;
			case __GMLC_NodeKind_Identifier: {
				var _symbol = _node.symbol;
				return (_symbol != undefined) && ((_symbol.kind == "Local") || (_symbol.kind == "BuiltinConstant") || (_symbol.kind == "Asset"));
			}
			case __GMLC_NodeKind_Unary:
			return __stable(_node.argument);
			case __GMLC_NodeKind_Binary:
			return __stable(_node.left) && __stable(_node.right);
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) || (__gmlc_opt_call_class(_name) != "pure") return false;
				var _effects = __GmlcDataEffects();
				if (_effects[$ _name].nondeterministic) return false;
				var _i = 0; repeat (array_length(_node.args)) {
					if (!__stable(_node.args[_i])) return false;
				_i++}
				return true;
			}
		}
		return false;
	};

	#region jsDoc
	/// @func    __clean(_stmt, _cx)
	/// @desc    Whether a statement is an expression or declaration statement that cannot change draw or GPU state.
	/// @self    GMLC_Opt_RenderStateRedundancy
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Bool}
	#endregion
	static __clean = function(_stmt, _cx) {
		if (_stmt.kind != __GMLC_NodeKind_ExprStmt) && (_stmt.kind != __GMLC_NodeKind_VarDeclList) return false;
		return !_cx.optimizer.__isNoOp(_stmt) && __cleanNode(_stmt);
	};

	#region jsDoc
	/// @func    __cleanNode(_node)
	/// @desc    Whether nothing under a node can change draw or GPU state: it calls only pure and observer functions
	///          and drawing functions that set no state.
	/// @self    GMLC_Opt_RenderStateRedundancy
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __cleanNode = function(_node) {
		switch (_node.kind) {
			case __GMLC_NodeKind_FunctionExpr:
			return true;
			case __GMLC_NodeKind_MethodCall: case __GMLC_NodeKind_New:
			return false;
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) return false;
				var _class = __gmlc_opt_call_class(_name);
				if (_class != "pure") && (_class != "observer") {
					if (_class != "render") || (string_copy(_name, 1, 5) != "draw_") || (string_copy(_name, 1, 9) == "draw_set_") || (string_copy(_name, 1, 12) == "draw_enable_") return false;
				}
			break;}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (!__cleanNode(_child)) return false;
				}
			_i++}
		_field_index++}
		return true;
	};

	#region jsDoc
	/// @func    __writesArguments(_stmt, _args)
	/// @desc    Whether a statement writes a local that an argument list reads.
	/// @self    GMLC_Opt_RenderStateRedundancy
	/// @param   {Struct.ASTNode}        _stmt : The statement
	/// @param   {Array<Struct.ASTNode>} _args : The arguments
	/// @returns {Bool}
	#endregion
	static __writesArguments = function(_stmt, _args) {
		var _i = 0; repeat (array_length(_args)) {
			if (__writesLocalOf(_stmt, _args[_i])) return true;
		_i++}
		return false;
	};

	#region jsDoc
	/// @func    __writesLocalOf(_stmt, _node)
	/// @desc    Whether a statement writes a local that an expression reads.
	/// @self    GMLC_Opt_RenderStateRedundancy
	/// @param   {Struct.ASTNode} _stmt : The statement
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __writesLocalOf = function(_stmt, _node) {
		if (_node.kind == __GMLC_NodeKind_Identifier) return __gmlc_opt_is_local(_node) && __gmlc_opt_writes(_stmt, _node.name);
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__writesLocalOf(_stmt, _child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};
	#endregion
	#endregion
}
