#region Extensions
// Language extensions: constructs GameMaker does not have (`?.`, function-like macros, `const`, `closure(...)`,
// `let`), each off unless the environment switches it on (GMLC_Env.enableExtension). An extension is a struct made by
// a constructor that inherits GMLC_Extension; the preprocessor and the parser call its hooks, and its rewrite turns
// what it parsed into plain GML before the resolver runs, so no later stage knows extensions exist. Each extension
// keeps all of its code in its own script (GMLC_Ext_<Name>); this script holds what they share: the base constructor,
// the registry, AST builders and the closure wrapping that `closure` and `let` both use.

#region jsDoc
/// @func    GMLC_Extension(_name)
/// @desc    The base of a language extension. A child constructor sets the hooks it uses as statics:
///          `collectMacro(pre, tokens, i, nameToken)` and `expandMacro(pre, batch, tokens, i, def, depth, out, use)`
///          in the preprocessor; `parseStatement(parser)` for the words in `statementWords`, `parsePrimary(parser)` for
///          those in `primaryWords`, `parsePostfix(parser, expression, first)` for the operators in
///          `postfixOperators`, and `rewrite(script, parser, state)` once the file is parsed. `functions` names the
///          helpers its rewritten code calls.
/// @param   {String} _name : The name the environment switches it on by
/// @returns {Struct.GMLC_Extension}
#endregion
function GMLC_Extension(_name) constructor {
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
	
	name = _name;
}

#region jsDoc
/// @func    GMLC_RegisterExtension(_extension)
/// @desc    Makes an extension known, so an environment can switch it on by its name; a second extension of the same
///          name replaces the first. Its helper functions become callable from the code it rewrites.
/// @param   {Struct.GMLC_Extension} _extension : The extension
/// @returns {Struct.GMLC_Extension}
#endregion
function GMLC_RegisterExtension(_extension) {
	var _registry = __GMLC_ExtensionRegistry();
	var _old = _registry.byName[$ _extension.name];
	if (_old != undefined) {
		_registry.order[array_get_index(_registry.order, _old)] = _extension;
	}
	else {
		array_push(_registry.order, _extension);
	}
	_registry.byName[$ _extension.name] = _extension;
	var _internal = __GMLC_InternalFunctions();
	var _names = struct_get_names(_extension.functions);
	var _i = 0; repeat (array_length(_names)) {
		_internal[$ _names[_i]] = _extension.functions[$ _names[_i]];
	_i++}
	return _extension;
}

#region jsDoc
/// @func    __GMLC_ExtensionRegistry()
/// @desc    The known extensions, by name and in the order their rewrites run. The built-in ones are registered on
///          first use: `let` before `closure`, so a `closure` captures the boxes `let` makes.
/// @returns {Struct} {byName, order}
#endregion
function __GMLC_ExtensionRegistry() {
	static __registry = undefined;
	if (__registry == undefined) {
		__registry = { byName: {}, order: [] };
		GMLC_RegisterExtension(new GMLC_Ext_NullishChaining());
		GMLC_RegisterExtension(new GMLC_Ext_MacroParams());
		GMLC_RegisterExtension(new GMLC_Ext_Const());
		GMLC_RegisterExtension(new GMLC_Ext_Let());
		GMLC_RegisterExtension(new GMLC_Ext_Closure());
	}
	return __registry;
}
#endregion

#region AST builders
// Nodes an extension makes. A name it introduces carries an origin of kind "extension", which the resolver binds to
// the GameMaker function or GMLC helper of that name whatever the exposure.

function __GMLC_ExtOrigin(_extension, _span) {
	return new GMLC_Origin("extension", _extension, undefined, undefined, undefined, _span);
}

// a GameMaker function or GMLC helper an extension calls
function __GMLC_ExtFunctionName(_extension, _name, _span) {
	return new ASTIdentifier(_span, _name, __GMLC_ExtOrigin(_extension, _span));
}

// a name of the program, such as a local an extension made
function __GMLC_ExtName(_name, _span) {
	return new ASTIdentifier(_span, _name);
}

function __GMLC_ExtString(_text, _span) {
	return new ASTLiteral(_span, "string", json_stringify(_text), _text);
}

function __GMLC_ExtUndefined(_span) {
	return new ASTLiteral(_span, "undefined", "undefined", undefined);
}

function __GMLC_ExtCall(_extension, _name, _args, _span) {
	return new ASTCall(_span, __GMLC_ExtFunctionName(_extension, _name, _span), _args);
}

// `var name = init;` of one name
function __GMLC_ExtVar(_name, _init, _span) {
	return new ASTVarDeclList(_span, [new ASTVarDecl(_span, __GMLC_ExtName(_name, _span), _init)]);
}

// `object.member`
function __GMLC_ExtDot(_object, _member, _span) {
	return new ASTIndex(_span, "Dot", _object, [], _member);
}
#endregion

#region Tree helpers
#region jsDoc
/// @func    __GMLC_ExtIsFunction(_node)
/// @desc    Whether a node is a function of any form (a declaration, a constructor or an expression).
/// @param   {Struct.ASTNode} _node : The node
/// @returns {Bool}
#endregion
function __GMLC_ExtIsFunction(_node) {
	return (_node.kind == __GMLC_NodeKind_FunctionDecl) || (_node.kind == __GMLC_NodeKind_ConstructorDecl)
		|| (_node.kind == __GMLC_NodeKind_FunctionExpr);
}

#region jsDoc
/// @func    __GMLC_ExtIsStatementList(_node, _field)
/// @desc    Whether a field of a node holds a list of statements, where a statement can be put before another.
/// @param   {Struct.ASTNode} _node  : The node
/// @param   {String}         _field : The field
/// @returns {Bool}
#endregion
function __GMLC_ExtIsStatementList(_node, _field) {
	if (_field != "body") return false;
	switch (_node.kind) {
		case __GMLC_NodeKind_Script: case __GMLC_NodeKind_Block: case __GMLC_NodeKind_Case: case __GMLC_NodeKind_Default:
		return true;
	}
	return false;
}

#region jsDoc
/// @func    __GMLC_ExtLocals(_function)
/// @desc    The names a function declares for itself: its parameters, its `var` names and caught names, not those of
///          the functions inside it.
/// @param   {Struct.ASTNode} _function : A function node, or the Script for the file's body
/// @returns {Struct} name to true
#endregion
function __GMLC_ExtLocals(_function) {
	var _out = {};
	var _params = _function[$ "params"] ?? [];
	var _p = 0; repeat (array_length(_params)) {
		_out[$ _params[_p].target.name] = true;
	_p++}
	var _body = (_function.kind == __GMLC_NodeKind_Script) ? _function : _function.body;
	__GMLC_ExtCollectLocals(_body, _out);
	return _out;
}
function __GMLC_ExtCollectLocals(_node, _out) {
	switch (_node.kind) {
		case __GMLC_NodeKind_VarDeclList: {
			var _d = 0; repeat (array_length(_node.declarations)) {
				_out[$ _node.declarations[_d].target.name] = true;
			_d++}
		break;}
		case __GMLC_NodeKind_Try: {
			if (_node.catch_param != undefined) _out[$ _node.catch_param.name] = true;
		break;}
	}
	if (__GMLC_ExtIsFunction(_node)) return;
	var _children = _node.children();
	var _c = 0; repeat (array_length(_children)) {
		__GMLC_ExtCollectLocals(_children[_c], _out);
	_c++}
}
#endregion

#region Closure wrapping
#region jsDoc
/// @func    __GMLC_ExtWrapClosure(_extension, _function, _captures, _id)
/// @desc    The plain GML of a function that keeps copies of some locals of the code around it and the `self` (and,
///          when its body names `other`, the `other`) it was made with:
///          `method({ __gmlc__closure__self: s, __gmlc__closure__other: o, __gmlc__closure__<name>: <name>, ... },
///              function() { var <name> = __gmlc__closure__<name>; ...; var __gmlc__closure__target = __gmlc__closure__self;
///              with (__gmlc__closure__other) { with (__gmlc__closure__target) { <body> } } })`.
///          `self` and `other` are read into the locals __gmlc__closure<id>__self and __gmlc__closure<id>__other by the
///          statements returned as `prelude`, which go just before the statement that makes the function: inside a
///          struct literal a `self` entry is the new struct. The bound values are copied into locals before the first
///          `with`, because inside `with (other)` a name is read from the new `self`. Without `other` in the body there
///          is one `with`, so an `other` that is no instance cannot skip the body. `method(s, f)` in the program goes
///          through __gmlc_closure_method (__GMLC_ExtRouteMethods), which gives such a function the `self` s and keeps
///          its copies.
/// @param   {String}                   _extension : The extension wrapping it, for the origin of `method`
/// @param   {Struct.ASTFunctionExpr}   _function  : The function, whose body is changed in place
/// @param   {Array<String>}            _captures  : The locals it keeps copies of
/// @param   {Real}                     _id        : A number unique in the file, for the names of the prelude
/// @returns {Struct} {call, prelude}: the node that replaces the function and the statements to put before
#endregion
function __GMLC_ExtWrapClosure(_extension, _function, _captures, _id) {
	var _span = _function.span;
	var _selfLocal = "__gmlc__closure" + string(_id) + "__self";
	var _otherLocal = "__gmlc__closure" + string(_id) + "__other";
	var _usesOther = __GMLC_ExtUsesName(_function.body, "other");
	var _entries = [new ASTStructEntry(_span, "__gmlc__closure__self", false, false, __GMLC_ExtName(_selfLocal, _span))];
	if (_usesOther) array_push(_entries, new ASTStructEntry(_span, "__gmlc__closure__other", false, false, __GMLC_ExtName(_otherLocal, _span)));
	var _unpack = [];
	var _c = 0; repeat (array_length(_captures)) {
		var _name = _captures[_c];
		array_push(_entries, new ASTStructEntry(_span, "__gmlc__closure__" + _name, false, false, __GMLC_ExtName(_name, _span)));
		array_push(_unpack, __GMLC_ExtVar(_name, __GMLC_ExtName("__gmlc__closure__" + _name, _span), _span));
	_c++}
	array_push(_unpack, __GMLC_ExtVar("__gmlc__closure__target", __GMLC_ExtName("__gmlc__closure__self", _span), _span));
	
	var _restore = new ASTWith(_span, __GMLC_ExtName("__gmlc__closure__target", _span), new ASTBlock(_span, _function.body.body));
	if (_usesOther) _restore = new ASTWith(_span, __GMLC_ExtName("__gmlc__closure__other", _span), new ASTBlock(_span, [_restore]));
	array_push(_unpack, _restore);
	_function.body = new ASTBlock(_function.body.span, _unpack);
	
	var _call = __GMLC_ExtCall(_extension, "method", [new ASTStructLiteral(_span, _entries), _function], _span);
	var _reads = [new ASTVarDecl(_span, __GMLC_ExtName(_selfLocal, _span), __GMLC_ExtName("self", _span))];
	if (_usesOther) array_push(_reads, new ASTVarDecl(_span, __GMLC_ExtName(_otherLocal, _span), __GMLC_ExtName("other", _span)));
	return { call: _call, prelude: new ASTVarDeclList(_span, _reads) };
}

#region jsDoc
/// @func    __GMLC_ExtRouteMethods(_extension, _script)
/// @desc    Sends the program's own calls of `method` and `method_get_self` (not a local of that name, not a call an
///          extension made) to __gmlc_closure_method and __gmlc_closure_method_get_self, so a function a `closure` or
///          a `let` wrapped can be given another `self` and still keep its copies, and reports the `self` it runs with.
///          Running it twice changes nothing.
/// @param   {String}           _extension : The extension routing them, for the origin of the helpers
/// @param   {Struct.ASTScript} _script    : The parsed file
#endregion
function __GMLC_ExtRouteMethods(_extension, _script) {
	__GMLC_ExtRouteIn(_extension, _script, [__GMLC_ExtLocals(_script)]);
}
function __GMLC_ExtRouteIn(_extension, _node, _scopes) {
	if (_node.kind == __GMLC_NodeKind_Call) {
		var _callee = _node.callee;
		if (_callee.kind == __GMLC_NodeKind_Identifier) && (_callee.origin == undefined)
		&& ((_callee.name == "method") || (_callee.name == "method_get_self"))
		&& !struct_exists(_scopes[array_length(_scopes) - 1], _callee.name) {
			var _helper = (_callee.name == "method") ? "__gmlc_closure_method" : "__gmlc_closure_method_get_self";
			_node.callee = __GMLC_ExtFunctionName(_extension, _helper, _callee.span);
		}
	}
	var _isFunction = __GMLC_ExtIsFunction(_node);
	if (_isFunction) array_push(_scopes, __GMLC_ExtLocals(_node));
	var _children = _node.children();
	var _c = 0; repeat (array_length(_children)) {
		__GMLC_ExtRouteIn(_extension, _children[_c], _scopes);
	_c++}
	if (_isFunction) array_pop(_scopes);
}

// whether a name appears anywhere in a tree
function __GMLC_ExtUsesName(_node, _name) {
	if (_node.kind == __GMLC_NodeKind_Identifier) return (_node.name == _name);
	var _children = _node.children();
	var _c = 0; repeat (array_length(_children)) {
		if (__GMLC_ExtUsesName(_children[_c], _name)) return true;
	_c++}
	return false;
}
#endregion
#endregion

#region Run-time helpers of closure and let
#region jsDoc
/// @func    __gmlc_closure_method(_self, _function)
/// @desc    `method(_self, _function)` of a program with `closure` or `let` on. A function they wrapped keeps its copies
///          in the struct it is bound to: it gets a copy of that struct whose `self` is _self. Any other function is
///          bound as `method` binds it. An undefined _self leaves a wrapped function as it is.
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
