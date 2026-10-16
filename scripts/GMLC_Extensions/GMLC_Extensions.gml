#region jsDoc
/// @func    GMLC_Extension(_name)
/// @desc    The base of a language extension; a child sets the hooks it uses as statics. `functions` names the
///          helpers its rewritten code calls. Each is off unless GMLC_Env.enableExtension switches it on; its
///          rewrite turns its constructs into plain GML before the resolver runs.
/// @param   {String} _name : The name the environment switches it on by
/// @returns {Struct.GMLC_Extension}
#endregion
function GMLC_Extension(_name) constructor {
	#region Config
	static statementWords = [];
	static primaryWords = [];
	static postfixOperators = [];
	static functions = {};
	static collectMacro = undefined;
	static expandMacro = undefined;
	static parseStatement = undefined;
	static parsePrimary = undefined;
	static parsePostfix = undefined;
	static rewrite = undefined;
	#endregion
	
	#region Init
	name = _name;
	#endregion
}

#region jsDoc
/// @func    gmlc_register_extension(_extension)
/// @desc    Makes an extension known by its name, replacing one of the same name, and its helper functions callable
///          from the code it rewrites.
/// @param   {Struct.GMLC_Extension} _extension : The extension
/// @returns {Struct.GMLC_Extension}
#endregion
function gmlc_register_extension(_extension) {
	var _registry = __gmlc_extension_registry();
	var _i = 0; repeat (array_length(_registry)) {
		if (_registry[_i].name == _extension.name) break;
	_i++}
	_registry[_i] = _extension;
	var _internal = __gmlc_internal_functions();
	var _names = struct_get_names(_extension.functions);
	_i = 0; repeat (array_length(_names)) {
		_internal[$ _names[_i]] = _extension.functions[$ _names[_i]];
	_i++}
	return _extension;
}

#region jsDoc
/// @func    __gmlc_extension_registry()
/// @desc    The known extensions in the order their rewrites run: `let` before `closure`, so a `closure` captures the
///          boxes `let` makes.
/// @returns {Array<Struct.GMLC_Extension>}
#endregion
function __gmlc_extension_registry() {
	static __registry = undefined;
	if (__registry == undefined) {
		__registry = [];
		gmlc_register_extension(new GMLC_Ext_NullishChaining());
		gmlc_register_extension(new GMLC_Ext_MacroParams());
		gmlc_register_extension(new GMLC_Ext_Const());
		gmlc_register_extension(new GMLC_Ext_Let());
		gmlc_register_extension(new GMLC_Ext_Closure());
	}
	return __registry;
}

#region AST builders
#region jsDoc
/// @func    __gmlc_ext_function_name(_extension, _name, _span)
/// @desc    A GameMaker function or GMLC helper an extension calls; its "extension" origin makes the resolver bind it
///          whatever the exposure.
/// @param   {String}           _extension : The extension
/// @param   {String}           _name      : The function
/// @param   {Struct.GMLC_Span} _span      : The span
/// @returns {Struct.ASTIdentifier}
#endregion
function __gmlc_ext_function_name(_extension, _name, _span) {
	return new ASTIdentifier(_span, _name, new GMLC_Origin("extension", _extension, undefined, undefined, undefined, _span));
}

#region jsDoc
/// @func    __gmlc_ext_string(_text, _span)
/// @desc    A string Literal node.
/// @param   {String}           _text : The string
/// @param   {Struct.GMLC_Span} _span : The span
/// @returns {Struct.ASTLiteral}
#endregion
function __gmlc_ext_string(_text, _span) {
	return new ASTLiteral(_span, "string", json_stringify(_text), _text);
}

#region jsDoc
/// @func    __gmlc_ext_undefined(_span)
/// @desc    An `undefined` Literal node.
/// @param   {Struct.GMLC_Span} _span : The span
/// @returns {Struct.ASTLiteral}
#endregion
function __gmlc_ext_undefined(_span) {
	return new ASTLiteral(_span, "undefined", "undefined", undefined);
}

#region jsDoc
/// @func    __gmlc_ext_call(_extension, _name, _args, _span)
/// @desc    A call to a GameMaker function or GMLC helper an extension uses.
/// @param   {String}                _extension : The extension
/// @param   {String}                _name      : The function
/// @param   {Array<Struct.ASTNode>} _args      : The arguments
/// @param   {Struct.GMLC_Span}      _span      : The span
/// @returns {Struct.ASTCall}
#endregion
function __gmlc_ext_call(_extension, _name, _args, _span) {
	return new ASTCall(_span, __gmlc_ext_function_name(_extension, _name, _span), _args);
}

#region jsDoc
/// @func    __gmlc_ext_var(_name, _init, _span)
/// @desc    `var _name = _init`.
/// @param   {String}           _name : The local
/// @param   {Struct.ASTNode}   _init : Its value
/// @param   {Struct.GMLC_Span} _span : The span
/// @returns {Struct.ASTVarDeclList}
#endregion
function __gmlc_ext_var(_name, _init, _span) {
	return new ASTVarDeclList(_span, [new ASTVarDecl(_span, new ASTIdentifier(_span, _name), _init)]);
}

#region jsDoc
/// @func    __gmlc_ext_dot(_object, _member, _span)
/// @desc    `_object._member`.
/// @param   {Struct.ASTNode}   _object : The struct
/// @param   {String}           _member : The key
/// @param   {Struct.GMLC_Span} _span   : The span
/// @returns {Struct.ASTIndex}
#endregion
function __gmlc_ext_dot(_object, _member, _span) {
	return new ASTIndex(_span, "Dot", _object, [], _member);
}
#endregion

#region Tree helpers
#region jsDoc
/// @func    __gmlc_ext_is_function(_node)
/// @desc    Whether a node is a function of any form (a declaration, a constructor or an expression).
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __gmlc_ext_is_function(_node) {
	return (_node.kind == __GMLC_NodeKind_FunctionDecl) || (_node.kind == __GMLC_NodeKind_ConstructorDecl)
		|| (_node.kind == __GMLC_NodeKind_FunctionExpr);
}

#region jsDoc
/// @func    __gmlc_ext_is_statement_list(_node, _field)
/// @desc    Whether a field of a node holds a list of statements, where a statement can be put before another.
/// @param   {Struct.ASTNode} _node  : The node
/// @param   {String}         _field : The field
/// @returns {Bool}
#endregion
function __gmlc_ext_is_statement_list(_node, _field) {
	if (_field != "body") return false;
	switch (_node.kind) {
		case __GMLC_NodeKind_Script: case __GMLC_NodeKind_Block: case __GMLC_NodeKind_Case: case __GMLC_NodeKind_Default:
		return true;
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_ext_locals(_function, [_forLet])
/// @desc    The names a function declares for itself (parameters, `var` and caught names), not those of nested
///          functions. For `let`, statics count too and `let`s, scoped to their blocks, do not.
/// @param   {Struct.ASTNode} _function : A function node, or the Script for the file's body
/// @param   {Bool}           [_forLet] : The names that hide a `let` outside the function
/// @returns {Struct} name to true
#endregion
function __gmlc_ext_locals(_function, _forLet = false) {
	var _out = {};
	var _params = _function[$ "params"] ?? [];
	var _p = 0; repeat (array_length(_params)) {
		_out[$ _params[_p].target.name] = true;
	_p++}
	var _body = (_function.kind == __GMLC_NodeKind_Script) ? _function : _function.body;
	__gmlc_ext_collect_locals(_body, _out, _forLet);
	return _out;
}

#region jsDoc
/// @func    __gmlc_ext_collect_locals(_node, _out, _forLet)
/// @desc    Adds the names a node and the nodes under it declare to _out, without going into
///          nested functions.
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {Struct}         _out    : Name to true
/// @param   {Bool}           _forLet : Whether statics count and `let`s do not
#endregion
function __gmlc_ext_collect_locals(_node, _out, _forLet) {
	switch (_node.kind) {
		case __GMLC_NodeKind_StaticDecl:
		case __GMLC_NodeKind_VarDeclList: {
			if (_node.kind == __GMLC_NodeKind_StaticDecl) && !_forLet break;
			if (_forLet) && (_node[$ "__extension"] == "let") break;
			var _d = 0; repeat (array_length(_node.declarations)) {
				_out[$ _node.declarations[_d].target.name] = true;
			_d++}
		break;}
		case __GMLC_NodeKind_Try: {
			if (_node.catch_param != undefined) _out[$ _node.catch_param.name] = true;
		break;}
	}
	if (__gmlc_ext_is_function(_node)) return;
	var _children = _node.children();
	var _c = 0; repeat (array_length(_children)) {
		__gmlc_ext_collect_locals(_children[_c], _out, _forLet);
	_c++}
}

#region jsDoc
/// @func    __gmlc_ext_copy_literal(_node, _span)
/// @desc    A copy of a literal, or of a signed literal, at another place.
/// @param   {Struct.ASTNode}   _node : The literal
/// @param   {Struct.GMLC_Span} _span : The span of the copy
/// @returns {Struct.ASTNode}
#endregion
function __gmlc_ext_copy_literal(_node, _span) {
	if (_node.kind == __GMLC_NodeKind_Unary) return new ASTUnary(_span, _node.op, __gmlc_ext_copy_literal(_node[$ "argument"], _span));
	return new ASTLiteral(_span, _node.ty, _node.lexeme, _node.value);
}

#region jsDoc
/// @func    __gmlc_ext_set_child(_parent, _field, _index, _node)
/// @desc    Puts a node in a field of its parent, at _index when the field holds an array.
/// @param   {Struct.ASTNode} _parent : The parent
/// @param   {String}         _field  : The field
/// @param   {Real}           _index  : The index in the array, undefined for a field that holds one node
/// @param   {Struct.ASTNode} _node   : The new child
#endregion
function __gmlc_ext_set_child(_parent, _field, _index, _node) {
	if (_index != undefined) {
		_parent[$ _field][_index] = _node;
	}
	else {
		_parent[$ _field] = _node;
	}
}
#endregion

#region Closure wrapping
#region jsDoc
/// @func    __gmlc_ext_wrap_closure(_extension, _function, _captures, _id)
/// @desc    The plain GML of a function that keeps copies of some outer locals and of the `self` (and `other`, when
///          named) it was made with: a method over those copies whose body runs inside `with (other) with (self)`.
/// @param   {String}                   _extension : The extension wrapping it, for the origin of `method`
/// @param   {Struct.ASTFunctionExpr}   _function  : The function, whose body is changed in place
/// @param   {Array<String>}            _captures  : The locals it keeps copies of
/// @param   {Real}                     _id        : A number unique in the file, for the names of the prelude
/// @returns {Struct} {call, prelude}: the node that replaces the function and the statements to put before
#endregion
function __gmlc_ext_wrap_closure(_extension, _function, _captures, _id) {
	var _span = _function.span;
	var _selfLocal = "__gmlc__closure" + string(_id) + "__self";
	var _otherLocal = "__gmlc__closure" + string(_id) + "__other";
	var _usesOther = __gmlc_ext_uses_name(_function.body, "other");
	var _entries = [new ASTStructEntry(_span, "__gmlc__closure__self", false, false, new ASTIdentifier(_span, _selfLocal))];
	if (_usesOther) array_push(_entries, new ASTStructEntry(_span, "__gmlc__closure__other", false, false, new ASTIdentifier(_span, _otherLocal)));
	var _unpack = [];
	var _c = 0; repeat (array_length(_captures)) {
		var _name = _captures[_c];
		array_push(_entries, new ASTStructEntry(_span, "__gmlc__closure__" + _name, false, false, new ASTIdentifier(_span, _name)));
		array_push(_unpack, __gmlc_ext_var(_name, new ASTIdentifier(_span, "__gmlc__closure__" + _name), _span));
	_c++}
	array_push(_unpack, __gmlc_ext_var("__gmlc__closure__target", new ASTIdentifier(_span, "__gmlc__closure__self"), _span));
	
	var _restore = new ASTWith(_span, new ASTIdentifier(_span, "__gmlc__closure__target"), new ASTBlock(_span, _function.body.body));
	if (_usesOther) _restore = new ASTWith(_span, new ASTIdentifier(_span, "__gmlc__closure__other"), new ASTBlock(_span, [_restore]));
	array_push(_unpack, _restore);
	_function.body = new ASTBlock(_function.body.span, _unpack);
	
	var _call = __gmlc_ext_call(_extension, "method", [new ASTStructLiteral(_span, _entries), _function], _span);
	var _reads = [new ASTVarDecl(_span, new ASTIdentifier(_span, _selfLocal), new ASTIdentifier(_span, "self"))];
	if (_usesOther) array_push(_reads, new ASTVarDecl(_span, new ASTIdentifier(_span, _otherLocal), new ASTIdentifier(_span, "other")));
	return { call: _call, prelude: new ASTVarDeclList(_span, _reads) };
}

#region jsDoc
/// @func    __gmlc_ext_route_methods(_extension, _script)
/// @desc    Sends the program's own `method` and `method_get_self` calls to their closure-aware helpers, so a function
///          `closure` or `let` wrapped can be given another `self` and still keep its copies. Running it twice changes
///          nothing.
/// @param   {String}           _extension : The extension routing them, for the origin of the helpers
/// @param   {Struct.ASTScript} _script    : The parsed file
#endregion
function __gmlc_ext_route_methods(_extension, _script) {
	__gmlc_ext_route_in(_extension, _script, [__gmlc_ext_locals(_script)]);
}

#region jsDoc
/// @func    __gmlc_ext_route_in(_extension, _node, _scopes)
/// @desc    Routes the `method` and `method_get_self` calls under a node that no local of their name
///          hides.
/// @param   {String}         _extension : The extension routing them
/// @param   {Struct.ASTNode} _node      : The node
/// @param   {Array<Struct>}  _scopes    : The locals of each function around the node, innermost last
#endregion
function __gmlc_ext_route_in(_extension, _node, _scopes) {
	if (_node.kind == __GMLC_NodeKind_Call) {
		var _callee = _node.callee;
		if (_callee.kind == __GMLC_NodeKind_Identifier) && (_callee.origin == undefined)
		&& ((_callee.name == "method") || (_callee.name == "method_get_self"))
		&& !struct_exists(_scopes[array_length(_scopes) - 1], _callee.name) {
			var _helper = (_callee.name == "method") ? "__gmlc_closure_method" : "__gmlc_closure_method_get_self";
			_node.callee = __gmlc_ext_function_name(_extension, _helper, _callee.span);
		}
	}
	var _isFunction = __gmlc_ext_is_function(_node);
	if (_isFunction) array_push(_scopes, __gmlc_ext_locals(_node));
	var _children = _node.children();
	var _c = 0; repeat (array_length(_children)) {
		__gmlc_ext_route_in(_extension, _children[_c], _scopes);
	_c++}
	if (_isFunction) array_pop(_scopes);
}

#region jsDoc
/// @func    __gmlc_ext_uses_name(_node, _name)
/// @desc    Whether a name is read anywhere under a node, nested functions included.
/// @param   {Struct.ASTNode} _node : The node
/// @param   {String}         _name : The name
/// @returns {Bool}
#endregion
function __gmlc_ext_uses_name(_node, _name) {
	if (_node.kind == __GMLC_NodeKind_Identifier) return (_node.name == _name);
	var _children = _node.children();
	var _c = 0; repeat (array_length(_children)) {
		if (__gmlc_ext_uses_name(_children[_c], _name)) return true;
	_c++}
	return false;
}
#endregion

#region Run-time helpers of closure and let
#region jsDoc
/// @func    __gmlc_closure_method(_self, _function)
/// @desc    `method(_self, _function)` with `closure` or `let` on: a function they wrapped keeps its copies in the
///          struct it is bound to, so it gets a copy of that struct whose `self` is _self. An undefined _self leaves
///          it as it is.
/// @param   {Any}      _self     : The struct or instance to run with
/// @param   {Function} _function : The function or method
/// @returns {Function}
#endregion
function __gmlc_closure_method(_self, _function) {
	var _bound = __gmlc_method_get_self(_function);
	if (is_struct(_bound) && struct_exists(_bound, "__gmlc__closure__self")) {
		if (_self == undefined) return _function;
		var _copy = {};
		var _names = struct_get_names(_bound);
		var _i = 0; repeat (array_length(_names)) {
			_copy[$ _names[_i]] = _bound[$ _names[_i]];
		_i++}
		_copy.__gmlc__closure__self = _self;
		return __gmlc_method(_copy, _function);
	}
	return __gmlc_method(_self, _function);
}

#region jsDoc
/// @func    __gmlc_closure_method_get_self(_function)
/// @desc    `method_get_self(_function)` of a program with `closure` or `let` on: for a function they wrapped, the
///          `self` it runs with, not the struct of its copies.
/// @param   {Function} _function : The function or method
/// @returns {Any}
#endregion
function __gmlc_closure_method_get_self(_function) {
	var _bound = __gmlc_method_get_self(_function);
	if (is_struct(_bound) && struct_exists(_bound, "__gmlc__closure__self")) return _bound.__gmlc__closure__self;
	return _bound;
}
#endregion
