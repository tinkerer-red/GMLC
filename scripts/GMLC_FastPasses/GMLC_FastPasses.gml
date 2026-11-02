#region Macros
//check each static parent
#macro __GMLC_FIND_OWNER	if (is_gmlc_function(_target)) {\
								_target = __gmlc_static_get(_target)\
							}\
							var _owner = _target;\
							if (!struct_exists(_owner, key)) {\
								_owner = __gmlc_static_get(_target);\
								while (_owner != undefined) && (!struct_exists(_owner, key)) {\
									_owner = __gmlc_static_get(_owner);\
								}\
								if (_owner == undefined) throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it.");\
							}

// a write through an object (asset or its number) sets the variable on every instance, as GameMaker does
#macro __GMLC_TARGET_IS_OBJECT	(!is_struct(_target) && (is_handle(_target) || is_numeric(_target)) && (_target >= 0) && object_exists(_target))

#macro __GMLC_COMPOUND_APPLY	switch (op) {\
									case GMLC_COMPOUND_OP.PLUS:         _value = _value + _right; break;\
									case GMLC_COMPOUND_OP.MINUS:        _value = _value - _right; break;\
									case GMLC_COMPOUND_OP.MULTIPLY:     _value = _value * _right; break;\
									case GMLC_COMPOUND_OP.DIVIDE:       _value = _value / _right; break;\
									case GMLC_COMPOUND_OP.MODULO:       _value = _value % _right; break;\
									case GMLC_COMPOUND_OP.BITWISE_XOR:  _value = _value ^ _right; break;\
									case GMLC_COMPOUND_OP.BITWISE_AND:  _value = _value & _right; break;\
									case GMLC_COMPOUND_OP.BITWISE_OR:   _value = _value | _right; break;\
								}
#endregion

#region Scope Getters/Setters
#region Get Property
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetPropertySelf() {
    var _target = global.gmlc_self_instance;
	__GMLC_FIND_OWNER
	return _owner[$ key];
}
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetPropertyGlobal() {
    return globals[$ key];
}
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetPropertyVarLocal() {
	if (!locals_written_to[local_index]) throw_gmlc_error($"local variable {key}({local_index}) not set before reading it.")
	return locals[local_index];
}
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetPropertyVarStatic() {
    return parent_node.statics[$ key];
}
#region //{
//    key: <expression>
//}
#endregion
// called through a local so they run with this executor's self, not the key's
#region jsDoc
/// @func    __GMLCexecuteGetPropertyUnique()
/// @desc    Returns the value of a variable the environment exposes.
/// @returns {Any}
#endregion
function __GMLCexecuteGetPropertyUnique() {
	var _get = key.get;
	return _get();
}
#endregion

#region Set Property
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetPropertySelf() {
    global.gmlc_self_instance[$ key] = expression()
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetPropertyGlobal() {
    globals[$ key] = expression()
}
#region //{
//    key: <stringLiteral>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetPropertyVarLocal() {
	locals[local_index] = expression();
	locals_written_to[local_index] = true;
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetPropertyVarStatic() {
    parent_node.statics[$ key] = expression()
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetPropertyUnique() {
	var _set = key.set;
	_set(expression());
}
#endregion

#region Accessor Getters/Setters

#region Evaluation order
// GameMaker evaluates an accessor like a call get(target, keys...) / set(target, keys..., value), right to left.
// Arrays rooted at a variable or `x.member` path are the exception: the path, then each index left to right.
// ++ and -- evaluate a dot target or rooted array path once; other accessors are read, then written with their keys
// and target evaluated again. Compound assignment evaluates the target and keys of every accessor once.
#region jsDoc
/// @func    __GMLCarrayTargetIsRooted(_target)
/// @desc    Whether an array access is rooted at a variable or `x.member` path, which GameMaker evaluates left to right.
/// @param   {Struct} _target : The node indexed
/// @returns {Bool}
#endregion
function __GMLCarrayTargetIsRooted(_target) {
	_target = __GMLCdesugarIndex(_target);
	while (_target.kind == __GMLC_NodeKind_Index)
	&& (_target.accessor == "Array") {
		_target = __GMLCdesugarIndex(_target.object);
	}
	if (_target.kind == __GMLC_NodeKind_Identifier) {
		return true;
	}
	return (_target.kind == __GMLC_NodeKind_Index)
		&& (_target.accessor == "Dot");
}
#endregion
#region Array
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteArrayGet(){
	var _key = key();
	var _target = target();
	return _target[_key];
}
#region jsDoc
/// @func    __GMLCexecuteArrayGetRooted()
/// @desc    Returns `target()[key()]`, the target evaluated first.
/// @returns {Any}
#endregion
function __GMLCexecuteArrayGetRooted(){
	var _target = target();
	return _target[key()];
}
#region jsDoc
/// @func    __GMLCcompileArrayGet(_rootNode, _parentNode, _target, _key, _span)
/// @desc    Compiles a read of `a[i]`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {Struct} _key        : The key's node
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileArrayGet(_rootNode, _parentNode, _target, _key, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileArrayGet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = __GMLCcompileExpression(_rootNode, _parentNode, _key);
	
	return method(_output, __GMLCarrayTargetIsRooted(_target) ? __GMLCexecuteArrayGetRooted : __GMLCexecuteArrayGet)
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteArraySet(){
	var _value = expression();
	var _key = key();
	var _target = target();
	_target[_key] = _value;
}
#region jsDoc
/// @func    __GMLCexecuteArraySetRooted()
/// @desc    Writes `target()[key()] = expression()`: the value, then the target, then the key.
#endregion
function __GMLCexecuteArraySetRooted(){
	var _value = expression();
	var _target = target();
	_target[key()] = _value;
}
#region jsDoc
/// @func    __GMLCexecuteArrayCreateAndSetSelf()
/// @desc    Writes `name[index()] = expression()` on self, making the variable an array first when it is not one.
#endregion
function __GMLCexecuteArrayCreateAndSetSelf(){
	var _value = expression();
	var _index = index();
	var _self = global.gmlc_self_instance;
	var _target = _self[$ key];
	
	if (!is_array(_target)) {
		_target = array_create(_index+1);
		_self[$ key] = _target;
	}
	
	_target[_index] = _value;
}
#region jsDoc
/// @func    __GMLCexecuteArrayCreateAndSetLocal()
/// @desc    Writes `name[index()] = expression()` to a local, making it an array first when it is not one.
#endregion
function __GMLCexecuteArrayCreateAndSetLocal(){
	var _value = expression();
	var _index = index();
	var _target = locals[local_index];
	
	if (!is_array(_target)) {
		_target = array_create(_index+1);
		locals[local_index] = _target;
		locals_written_to[local_index] = true;
	}
	
	_target[_index] = _value;
}
#region jsDoc
/// @func    __GMLCexecuteArrayGetForWrite()
/// @desc    Returns the element `target()[key()]` of a nested array write `a[i][j] = v`, storing a new empty array
///          there when it is missing or not an array, as GameMaker does (`a = [0, 0]; a[1][0] = 5` gives [0, [5]]).
///          The root must already be an array: GameMaker would create it, GMLC throws.
/// @self    __GMLC_Function
/// @returns {Array}
#endregion
function __GMLCexecuteArrayGetForWrite(){
	var _key = key();
	var _target = target();
	if (!is_array(_target)) {
		throw_gmlc_error("trying to index a variable which is not an array");
	}
	var _element = (_key < array_length(_target)) ? _target[_key] : undefined;
	if (!is_array(_element)) {
		_element = [];
		_target[_key] = _element;
	}
	return _element;
}
#region jsDoc
/// @func    __GMLCexecuteArrayGetForWriteRooted()
/// @desc    As the array element read for a nested write, with the target evaluated before the key.
/// @returns {Array}
#endregion
function __GMLCexecuteArrayGetForWriteRooted(){
	var _target = target();
	var _key = key();
	if (!is_array(_target)) {
		throw_gmlc_error("trying to index a variable which is not an array");
	}
	var _element = (_key < array_length(_target)) ? _target[_key] : undefined;
	if (!is_array(_element)) {
		_element = [];
		_target[_key] = _element;
	}
	return _element;
}
#region jsDoc
/// @func    __GMLCcompileArrayTargetForWrite(_rootNode, _parentNode, _target, _span)
/// @desc    Compiles the target of an array write; an inner `a[i]` makes its element an array when it is not one.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileArrayTargetForWrite(_rootNode, _parentNode, _target, _span) {
	_target = __GMLCdesugarIndex(_target);
	if (_target.kind != __GMLC_NodeKind_Index)
	|| (_target.accessor != "Array") {
		return __GMLCcompileExpression(_rootNode, _parentNode, _target);
	}
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileArrayGetForWrite", "<Missing Error Message>", _span);
	_output.target = __GMLCcompileArrayTargetForWrite(_rootNode, _parentNode, _target.object, _span);
	_output.key    = __GMLCcompileExpression(_rootNode, _parentNode, _target.keys[0]);
	return method(_output, __GMLCarrayTargetIsRooted(_target.object) ? __GMLCexecuteArrayGetForWriteRooted : __GMLCexecuteArrayGetForWrite);
}
#region jsDoc
/// @func    __GMLCcompileArraySet(_rootNode, _parentNode, _target, _key, _expression, _span)
/// @desc    Compiles `a[i] = v`; a local or self variable that is not an array yet becomes one.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {Struct} _key        : The key's node
/// @param   {Struct} _expression : The value's node
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileArraySet(_rootNode, _parentNode, _target, _key, _expression, _span) {
	if (_target.kind == __GMLC_NodeKind_Identifier) {
		if (_target.symbol.kind == "Local") {
			var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Getter", "<Missing Error Message>", _span);	
			
			_output.locals          = _parentNode.locals;
			_output.local_index      = _parentNode.local_look_ups[$ _target.name];
			_output.locals_written_to = _parentNode.locals_written_to;
			
			_output.index = __GMLCcompileExpression(_rootNode, _parentNode, _key);
			_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);;
			
			return __vanilla_method(_output, __GMLCexecuteArrayCreateAndSetLocal);
		}
		if (_target.symbol.kind == "Self") {
			var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Getter", "<Missing Error Message>", _span);	
			
			_output.key = _target.name;
			
			_output.index = __GMLCcompileExpression(_rootNode, _parentNode, _key);
			_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);;
			
			return __vanilla_method(_output, __GMLCexecuteArrayCreateAndSetSelf);
		}
		
	}
	
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileArraySet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileArrayTargetForWrite(_rootNode, _parentNode, _target, _span);
	_output.key        = __GMLCcompileExpression(_rootNode, _parentNode, _key);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);
	
	return method(_output, __GMLCarrayTargetIsRooted(_target) ? __GMLCexecuteArraySetRooted : __GMLCexecuteArraySet)
}
#endregion
#region List
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteListGet(){
	var _key = key();
	var _target = target();
	return _target[| _key];
}
#region jsDoc
/// @func    __GMLCcompileListGet(_rootNode, _parentNode, _target, _key, _span)
/// @desc    Compiles a read of `l[| i]`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {Struct} _key        : The key's node
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileListGet(_rootNode, _parentNode, _target, _key, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileListGet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = __GMLCcompileExpression(_rootNode, _parentNode, _key);
	
    return method(_output, __GMLCexecuteListGet)
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteListSet(){
	var _value = expression();
	var _key = key();
	var _target = target();
	_target[| _key] = _value;
}
#region jsDoc
/// @func    __GMLCcompileListSet(_rootNode, _parentNode, _target, _key, _expression, _span)
/// @desc    Compiles `l[| i] = v`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {Struct} _key        : The key's node
/// @param   {Struct} _expression : The value's node
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileListSet(_rootNode, _parentNode, _target, _key, _expression, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileListSet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = __GMLCcompileExpression(_rootNode, _parentNode, _key);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);
	
    return method(_output, __GMLCexecuteListSet)
}
#endregion
#region Map
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteMapGet(){
	var _key = key();
	var _target = target();
	return _target[? _key];
}
#region jsDoc
/// @func    __GMLCcompileMapGet(_rootNode, _parentNode, _target, _key, _span)
/// @desc    Compiles a read of `m[? k]`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {Struct} _key        : The key's node
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileMapGet(_rootNode, _parentNode, _target, _key, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileMapGet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = __GMLCcompileExpression(_rootNode, _parentNode, _key);
	
    return method(_output, __GMLCexecuteMapGet)
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteMapSet(){
	var _value = expression();
	var _key = key();
	var _target = target();
	_target[? _key] = _value;
}
#region jsDoc
/// @func    __GMLCcompileMapSet(_rootNode, _parentNode, _target, _key, _expression, _span)
/// @desc    Compiles `m[? k] = v`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {Struct} _key        : The key's node
/// @param   {Struct} _expression : The value's node
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileMapSet(_rootNode, _parentNode, _target, _key, _expression, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileMapSet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = __GMLCcompileExpression(_rootNode, _parentNode, _key);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);
	
    return method(_output, __GMLCexecuteMapSet)
}
#endregion

#region Grid
#region //{
//    target: <expression>,
//    key_x: <expression>,
//    key_y: <expression>,
//}
#endregion
function __GMLCexecuteGridGet(){
	var _keyY = key_y();
	var _keyX = key_x();
	var _target = target();
	return _target[# _keyX, _keyY];
}
#region jsDoc
/// @func    __GMLCcompileGridGet(_rootNode, _parentNode, _target, _keyX, _keyY, _span)
/// @desc    Compiles a read of `g[# x, y]`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {Struct} _keyX       : The column's node
/// @param   {Struct} _keyY       : The row's node
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileGridGet(_rootNode, _parentNode, _target, _keyX, _keyY, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileGridGet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key_x       = __GMLCcompileExpression(_rootNode, _parentNode, _keyX);
	_output.key_y       = __GMLCcompileExpression(_rootNode, _parentNode, _keyY);
	
    return method(_output, __GMLCexecuteGridGet)
}
#region //{
//    target: <expression>,
//    key_x: <expression>,
//    key_y: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteGridSet(){
	var _value = expression();
	var _keyY = key_y();
	var _keyX = key_x();
	var _target = target();
	_target[# _keyX, _keyY] = _value;
}
#region jsDoc
/// @func    __GMLCcompileGridSet(_rootNode, _parentNode, _target, _keyX, _keyY, _expression, _span)
/// @desc    Compiles `g[# x, y] = v`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {Struct} _keyX       : The column's node
/// @param   {Struct} _keyY       : The row's node
/// @param   {Struct} _expression : The value's node
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileGridSet(_rootNode, _parentNode, _target, _keyX, _keyY, _expression, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileGridSet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key_x       = __GMLCcompileExpression(_rootNode, _parentNode, _keyX);
	_output.key_y       = __GMLCcompileExpression(_rootNode, _parentNode, _keyY);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);
	
    return method(_output, __GMLCexecuteGridSet)
}
#endregion
#region Struct
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteStructGet(){
	var _key = key();
	var _target = target();
	return _target[$ _key];
}
#region jsDoc
/// @func    __GMLCcompileStructGet(_rootNode, _parentNode, _target, _key, _span)
/// @desc    Compiles a read of `s[$ k]`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {Struct} _key        : The key's node
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileStructGet(_rootNode, _parentNode, _target, _key, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructGet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = __GMLCcompileExpression(_rootNode, _parentNode, _key);
	
    return method(_output, __GMLCexecuteStructGet)
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteStructSet(){
	var _value = expression();
	var _key = key();
	var _target = target();
	if (is_numeric(_target) && !is_handle(_target) && !(_target == -2 || _target == -1)) { // -5 is global, -4 is all, -3 is noone, throw error by default
		throw_gmlc_error($"struct_get argument 1 incorrect type ({typeof(_target)}>) expecting a Number.")
	}
	_target[$ _key] = _value;
}
#region jsDoc
/// @func    __GMLCcompileStructSet(_rootNode, _parentNode, _target, _key, _expression, _span)
/// @desc    Compiles `s[$ k] = v`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {Struct} _key        : The key's node
/// @param   {Struct} _expression : The value's node
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileStructSet(_rootNode, _parentNode, _target, _key, _expression, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructSet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = __GMLCcompileExpression(_rootNode, _parentNode, _key);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);
	
    return method(_output, __GMLCexecuteStructSet)
}
#endregion
#region Dot
#region //{
//    target: <expression>,
//    key: <stringLiteral>,
//}
#endregion
function __GMLCexecuteStructDotAccGet(){
	var _target = target();
	__GMLC_FIND_OWNER
	return _owner[$ key];
}
#region jsDoc
/// @func    __GMLCcompileStructDotAccGet(_rootNode, _parentNode, _target, _key, _span)
/// @desc    Compiles a read of `x.member`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {String} _key        : The member name
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileStructDotAccGet(_rootNode, _parentNode, _target, _key, _span) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructDotAccGet", "<Missing Error Message>", _span);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key    = _key;
	
	return method(_output, __GMLCexecuteStructDotAccGet)
}
#region //{
//    target: <expression>,
//    key: <stringLiteral>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteStructDotAccSet(){
	var _value = expression();
	var _target = target();
	
	if (__GMLC_TARGET_IS_OBJECT) {
		__GMLCsetObjectVariable(_target, key, _value);
		return;
	}
	
	if (is_gmlc_function(_target)) {
		_target = __gmlc_static_get(_target)
	}
	
	if (struct_exists(_target, key)) {
		_target[$ key] = _value;
		return
	}
	
	// this is a safety check for a bug in GML
	// https://github.com/YoYoGames/GameMaker-Bugs/issues/8048
	var _inst_of = instanceof(_target);
	if (_inst_of == "Object")
	|| (_inst_of == undefined) {
		_target[$ key] = _value;
		return
	}	
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			_static[$ key] = _value;
			return
		}
		_static = __gmlc_static_get(_static)
	}
	
	//last resort if no statics contain the key write to target
	_target[$ key] = _value;
	return
}
#region jsDoc
/// @func    __GMLCexecuteCompoundDot()
/// @desc    Executes a compound assignment (`+=`, `??=`, ...) on a dot accessor, evaluating the target once.
/// @self    __GMLC_Function
#endregion
function __GMLCexecuteCompoundDot(){
	var _target = target();
	if (__GMLC_TARGET_IS_OBJECT) {
		var _value = _target[$ key];
		if (op == GMLC_COMPOUND_OP.NULLISH) {
			_value ??= right();
		}
		else {
			var _right = right();
			__GMLC_COMPOUND_APPLY
		}
		__GMLCsetObjectVariable(_target, key, _value);
		return;
	}
	__GMLC_FIND_OWNER
	if (op == GMLC_COMPOUND_OP.NULLISH) {
		_owner[$ key] ??= right();
		return;
	}
	var _right = right();
	var _value = _owner[$ key];
	__GMLC_COMPOUND_APPLY
	_owner[$ key] = _value;
}
#region jsDoc
/// @func    __GMLCexecuteCompoundArray()
/// @desc    Executes a compound assignment (`+=`, `??=`, ...) on an array accessor, evaluating target and index once.
/// @self    __GMLC_Function
#endregion
function __GMLCexecuteCompoundArray(){
	var _target = target();
	var _key = key();
	if (op == GMLC_COMPOUND_OP.NULLISH) {
		_target[_key] ??= right();
		return;
	}
	var _right = right();
	var _value = _target[_key];
	__GMLC_COMPOUND_APPLY
	_target[_key] = _value;
}
#region jsDoc
/// @func    __GMLCexecuteCompoundList()
/// @desc    Executes a compound assignment (`+=`, `??=`, ...) on a list accessor `[| ]`, evaluating target and keys once.
#endregion
function __GMLCexecuteCompoundList(){
	var _target = target();
	var _key = key();
	if (op == GMLC_COMPOUND_OP.NULLISH) {
		_target[| _key] ??= right();
		return;
	}
	var _right = right();
	var _value = _target[| _key];
	__GMLC_COMPOUND_APPLY
	_target[| _key] = _value;
}
#region jsDoc
/// @func    __GMLCexecuteCompoundMap()
/// @desc    Executes a compound assignment (`+=`, `??=`, ...) on a map accessor `[? ]`, evaluating target and keys once.
#endregion
function __GMLCexecuteCompoundMap(){
	var _target = target();
	var _key = key();
	if (op == GMLC_COMPOUND_OP.NULLISH) {
		_target[? _key] ??= right();
		return;
	}
	var _right = right();
	var _value = _target[? _key];
	__GMLC_COMPOUND_APPLY
	_target[? _key] = _value;
}
#region jsDoc
/// @func    __GMLCexecuteCompoundStruct()
/// @desc    Executes a compound assignment (`+=`, `??=`, ...) on a struct accessor `[$ ]`, target and key evaluated once.
#endregion
function __GMLCexecuteCompoundStruct(){
	var _target = target();
	var _key = key();
	if (op == GMLC_COMPOUND_OP.NULLISH) {
		_target[$ _key] ??= right();
		return;
	}
	var _right = right();
	var _value = _target[$ _key];
	__GMLC_COMPOUND_APPLY
	_target[$ _key] = _value;
}
#region jsDoc
/// @func    __GMLCexecuteCompoundGrid()
/// @desc    Executes a compound assignment (`+=`, `??=`, ...) on a grid accessor `[# ]`, evaluating target and keys once.
#endregion
function __GMLCexecuteCompoundGrid(){
	var _target = target();
	var _x = key_x();
	var _y = key_y();
	if (op == GMLC_COMPOUND_OP.NULLISH) {
		_target[# _x, _y] ??= right();
		return;
	}
	var _right = right();
	var _value = _target[# _x, _y];
	__GMLC_COMPOUND_APPLY
	_target[# _x, _y] = _value;
}
// GameMaker's `object.variable = value` sets every instance; `_o[$ _k] = value` sets only the first
#region jsDoc
/// @func    __GMLCsetObjectVariable(_object, _key, _value)
/// @desc    Sets a variable on every instance of an object.
/// @param   {Asset.GMObject} _object : The object
/// @param   {String}         _key    : The variable name
/// @param   {Any}            _value  : The value
#endregion
function __GMLCsetObjectVariable(_object, _key, _value) {
	with (_object) self[$ _key] = _value;
}
#region jsDoc
/// @func    __GMLCcompileStructDotAccSet(_rootNode, _parentNode, _target, _key, _expression, _span)
/// @desc    Compiles `x.member = v`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _target     : The accessed value's node
/// @param   {String} _key        : The member name
/// @param   {Struct} _expression : The value's node
/// @param   {Struct} _span       : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompileStructDotAccSet(_rootNode, _parentNode, _target, _key, _expression, _span) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructDotAccSet", "<Missing Error Message>", _span);
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = _key;
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);
	
    return method(_output, __GMLCexecuteStructDotAccSet)
}
#endregion

#endregion
#endregion

#region Scope Updatters (++ and --)

// YYC leaks memory when the value of `++` or `--` on an accessor is returned directly, so each executor updates
// first and returns in a second statement

#region Self
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertySelfPlusPlusPrefix()
/// @desc    Executes `++name` on self and returns the new value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertySelfPlusPlusPrefix() {
    ++global.gmlc_self_instance[$ key];
    return global.gmlc_self_instance[$ key];
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertySelfPlusPlusPostfix()
/// @desc    Executes `name++` on self and returns the old value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertySelfPlusPlusPostfix() {
	var _old = global.gmlc_self_instance[$ key];
	global.gmlc_self_instance[$ key]++;
	return _old;
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertySelfMinusMinusPrefix()
/// @desc    Executes `--name` on self and returns the new value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertySelfMinusMinusPrefix() {
    --global.gmlc_self_instance[$ key];
    return global.gmlc_self_instance[$ key];
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertySelfMinusMinusPostfix()
/// @desc    Executes `name--` on self and returns the old value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertySelfMinusMinusPostfix() {
    var _old = global.gmlc_self_instance[$ key];
    global.gmlc_self_instance[$ key]--;
    return _old;
}
#endregion
#region Global
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyGlobalPlusPlusPrefix()
/// @desc    Executes `++name` on the globals and returns the new value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyGlobalPlusPlusPrefix() {
    ++root_node.globals[$ key];
    return root_node.globals[$ key];
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyGlobalPlusPlusPostfix()
/// @desc    Executes `name++` on the globals and returns the old value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyGlobalPlusPlusPostfix() {
    var _old = root_node.globals[$ key];
    root_node.globals[$ key]++;
    return _old;
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyGlobalMinusMinusPrefix()
/// @desc    Executes `--name` on the globals and returns the new value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyGlobalMinusMinusPrefix() {
    --root_node.globals[$ key];
    return root_node.globals[$ key];
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyGlobalMinusMinusPostfix()
/// @desc    Executes `name--` on the globals and returns the old value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyGlobalMinusMinusPostfix() {
    var _old = root_node.globals[$ key];
    root_node.globals[$ key]--;
    return _old;
}
#endregion
#region Local
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyLocalPlusPlusPrefix()
/// @desc    Executes `++name` on a local and returns the new value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyLocalPlusPlusPrefix() {
	if (!locals_written_to[local_index]) throw_gmlc_error($"local variable {key}({local_index}) not set before reading it.")
    ++locals[local_index];
    return locals[local_index];
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyLocalPlusPlusPostfix()
/// @desc    Executes `name++` on a local and returns the old value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyLocalPlusPlusPostfix() {
	if (!locals_written_to[local_index]) throw_gmlc_error($"local variable {key}({local_index}) not set before reading it.")
    var _old = locals[local_index];
    locals[local_index]++;
    return _old;
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyLocalMinusMinusPrefix()
/// @desc    Executes `--name` on a local and returns the new value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyLocalMinusMinusPrefix() {
	if (!locals_written_to[local_index]) throw_gmlc_error($"local variable {key}({local_index}) not set before reading it.")
    --locals[local_index];
    return locals[local_index];
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyLocalMinusMinusPostfix()
/// @desc    Executes `name--` on a local and returns the old value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyLocalMinusMinusPostfix() {
	if (!locals_written_to[local_index]) throw_gmlc_error($"local variable {key}({local_index}) not set before reading it.")
    var _old = locals[local_index];
    locals[local_index]--;
    return _old;
}
#endregion
#region Static
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyStaticPlusPlusPrefix()
/// @desc    Executes `++name` on the function's statics and returns the new value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyStaticPlusPlusPrefix() {
    ++parent_node.statics[$ key];
    return parent_node.statics[$ key];
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyStaticPlusPlusPostfix()
/// @desc    Executes `name++` on the function's statics and returns the old value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyStaticPlusPlusPostfix() {
    var _old = parent_node.statics[$ key];
    parent_node.statics[$ key]++;
    return _old;
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyStaticMinusMinusPrefix()
/// @desc    Executes `--name` on the function's statics and returns the new value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyStaticMinusMinusPrefix() {
    --parent_node.statics[$ key];
    return parent_node.statics[$ key];
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyStaticMinusMinusPostfix()
/// @desc    Executes `name--` on the function's statics and returns the old value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyStaticMinusMinusPostfix() {
    var _old = parent_node.statics[$ key];
    parent_node.statics[$ key]--;
    return _old;
}
#endregion
#region Unique
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyUniquePlusPlusPrefix()
/// @desc    Executes `++name` on a variable the environment exposes and returns the new value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyUniquePlusPlusPrefix() {
	var _get = key.get;
	var _set = key.set;
	var _val = _get() + 1;
	_set(_val);
	return _val;
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyUniquePlusPlusPostfix()
/// @desc    Executes `name++` on a variable the environment exposes and returns the old value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyUniquePlusPlusPostfix() {
	var _get = key.get;
	var _set = key.set;
	var _val = _get();
	_set(_val + 1);
	return _val;
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyUniqueMinusMinusPrefix()
/// @desc    Executes `--name` on a variable the environment exposes and returns the new value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyUniqueMinusMinusPrefix() {
	var _get = key.get;
	var _set = key.set;
	var _val = _get() - 1;
	_set(_val);
	return _val;
}
#region jsDoc
/// @func    __GMLCexecuteUpdatePropertyUniqueMinusMinusPostfix()
/// @desc    Executes `name--` on a variable the environment exposes and returns the old value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdatePropertyUniqueMinusMinusPostfix() {
	var _get = key.get;
	var _set = key.set;
	var _val = _get();
	_set(_val - 1);
	return _val;
}
#endregion

#region Accessors
#region Arrays
#region //{
//    target: <expression>,
//    key: <expression>,
//    delta: 1 or -1,
//    prefix: <bool>,
//}
#endregion
function __GMLCexecuteUpdateArray() {
	var _key = key();
	var _target = target();
	var _old = _target[_key];
	_key = key();
	_target = target();
	_target[_key] = _old + delta;
	return prefix ? _old + delta : _old;
}
#region jsDoc
/// @func    __GMLCexecuteUpdateArrayRooted()
/// @desc    Executes `++` or `--` on a rooted array element (target and key evaluated once); returns its value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdateArrayRooted() {
	var _target = target();
	var _key = key();
	var _old = _target[_key];
	_target[_key] = _old + delta;
	return prefix ? _old + delta : _old;
}
#endregion
#region List
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteUpdateList() {
	var _key = key();
	var _target = target();
	var _old = _target[| _key];
	_key = key();
	_target = target();
	_target[| _key] = _old + delta;
	return prefix ? _old + delta : _old;
}
#endregion
#region Map
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteUpdateMap() {
	var _key = key();
	var _target = target();
	var _old = _target[? _key];
	_key = key();
	_target = target();
	_target[? _key] = _old + delta;
	return prefix ? _old + delta : _old;
}
#endregion
#region Grid
#region //{
//    target: <expression>,
//    key_x: <expression>,
//    key_y: <expression>,
//}
#endregion
function __GMLCexecuteUpdateGrid() {
	var _keyY = key_y();
	var _keyX = key_x();
	var _target = target();
	var _old = _target[# _keyX, _keyY];
	_keyY = key_y();
	_keyX = key_x();
	_target = target();
	_target[# _keyX, _keyY] = _old + delta;
	return prefix ? _old + delta : _old;
}
#endregion
#region Struct
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteUpdateStruct() {
	var _key = key();
	var _target = target();
	var _old = _target[$ _key];
	_key = key();
	_target = target();
	_target[$ _key] = _old + delta;
	return prefix ? _old + delta : _old;
}
#endregion
#region jsDoc
/// @func    __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, _argument, _executor)
/// @desc    Compiles `++` or `--` on an array, list, map, grid or struct accessor with the given executor.
/// @param   {Struct}   _rootNode   : The program node
/// @param   {Struct}   _parentNode : The enclosing function node
/// @param   {Struct}   _node       : The Update node
/// @param   {Struct}   _argument   : Its Index node
/// @param   {Function} _executor   : The update executor
/// @returns {Function}
#endregion
function __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, _argument, _executor) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUpdateAccessor", "<Missing Error Message>", _node.span);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _argument.object);
	if (_argument.accessor == "Grid") {
		_output.key_x = __GMLCcompileExpression(_rootNode, _parentNode, _argument.keys[0]);
		_output.key_y = __GMLCcompileExpression(_rootNode, _parentNode, _argument.keys[1]);
	}
	else {
		_output.key = __GMLCcompileExpression(_rootNode, _parentNode, _argument.keys[0]);
	}
	_output.delta  = (_node.op == "++") ? 1 : -1;
	_output.prefix = _node.prefix;
	return method(_output, _executor);
}
#endregion
#region Dot
#region jsDoc
/// @func    __GMLCexecuteUpdateStructDotAccPlusPlusPrefix()
/// @desc    Executes `++x.member`, the target evaluated once, and returns the new value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdateStructDotAccPlusPlusPrefix() {
	var _target = target();
	
	if (__GMLC_TARGET_IS_OBJECT) {
		var _new = _target[$ key] + 1;
		__GMLCsetObjectVariable(_target, key, _new);
		return _new;
	}
	
	__GMLC_FIND_OWNER
	++_owner[$ key];
	return _owner[$ key];
}
#region jsDoc
/// @func    __GMLCexecuteUpdateStructDotAccPlusPlusPostfix()
/// @desc    Executes `x.member++`, the target evaluated once, and returns the old value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdateStructDotAccPlusPlusPostfix() {
	var _target = target();
	
	if (__GMLC_TARGET_IS_OBJECT) {
		var _old = _target[$ key];
		__GMLCsetObjectVariable(_target, key, _old + 1);
		return _old;
	}
	
	__GMLC_FIND_OWNER
	var _old = _owner[$ key];
	_owner[$ key]++;
	return _old;
}
#region jsDoc
/// @func    __GMLCexecuteUpdateStructDotAccMinusMinusPrefix()
/// @desc    Executes `--x.member`, the target evaluated once, and returns the new value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdateStructDotAccMinusMinusPrefix() {
	var _target = target();
	
	if (__GMLC_TARGET_IS_OBJECT) {
		var _new = _target[$ key] - 1;
		__GMLCsetObjectVariable(_target, key, _new);
		return _new;
	}
	
	__GMLC_FIND_OWNER
	--_owner[$ key];
	return _owner[$ key];
}
#region jsDoc
/// @func    __GMLCexecuteUpdateStructDotAccMinusMinusPostfix()
/// @desc    Executes `x.member--`, the target evaluated once, and returns the old value.
/// @returns {Any}
#endregion
function __GMLCexecuteUpdateStructDotAccMinusMinusPostfix() {
	var _target = target();
	
	if (__GMLC_TARGET_IS_OBJECT) {
		var _old = _target[$ key];
		__GMLCsetObjectVariable(_target, key, _old - 1);
		return _old;
	}
	
	__GMLC_FIND_OWNER
	var _old = _owner[$ key];
	_owner[$ key]--;
	return _old;
}
#region jsDoc
/// @func    __GMLCcompileUpdateStructDotAcc(_rootNode, _parentNode, _node)
/// @desc    Compiles `++` or `--` on `x.member`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : The Update node
/// @returns {Function}
#endregion
function __GMLCcompileUpdateStructDotAcc(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUpdateStructDotAcc", "<Missing Error Message>", _node.span);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _node[$ "argument"].object);
	_output.key    = _node[$ "argument"].member
	
    var _increment = (_node.op == "++") ? true : false;
	var _prefix = _node.prefix;
	
	if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateStructDotAccPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateStructDotAccPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateStructDotAccMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateStructDotAccMinusMinusPostfix);
}
#endregion

#endregion

#region Helpers
#region jsDoc
/// @func    struct_get_chained(_struct, ...keys)
/// @desc    Reads a path of keys through nested structs; undefined when a step is missing.
/// @param   {Struct} _struct : The struct to start from
/// @param   {String} ...keys : The keys, outermost first
/// @returns {Any}
#endregion
function struct_get_chained(_struct) {
	if !is_struct(_struct) return undefined;
    var _current = _struct
	for(var i = 1; i < argument_count; i++) {
        if (_current == undefined) return undefined;
        _current = _current[$ argument[i]]
    }
    return _current
}
#endregion

