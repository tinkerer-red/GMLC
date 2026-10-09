#region Scope Getters/Setters
#region Get Property
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetPropertySelf() {
    var _target = global.gmlc_self_instance;
	
	if (is_gmlc_function(_target)) {
		_target = __gmlc_static_get(_target)
	}
	
	if (struct_exists(_target, key)) {
		return _target[$ key];
	}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return _static[$ key];
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it.")
	
}
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetPropertyOther() {
    return global.gmlc_other_instance[$ key];
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
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.")
	return locals[localIndex];
}
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetPropertyVarStatic() {
    return parentNode.statics[$ key];
}
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetPropertyUnique() {
	return key.get()
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
function __GMLCexecuteSetPropertyOther() {
    global.gmlc_other_instance[$ key] = expression()
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
	locals[localIndex] = expression();
	localsWrittenTo[localIndex] = true;
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetPropertyVarStatic() {
    parentNode.statics[$ key] = expression()
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetPropertyUnique() {
	key.set(expression());
}
#endregion

#region Accessor Getters/Setters

#region Evaluation order
// GameMaker evaluates an accessor like a call get(target, keys...) / set(target, keys..., value), right to left.
// Arrays rooted at a variable or `x.member` path are the exception: the path, then each index left to right.
// Compound assignment and ++/-- evaluate a dot target or rooted array path once; other accessors are read, then
// written with their keys and target evaluated again.
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
//    rooted: <bool>, see __GMLCarrayTargetIsRooted
//}
#endregion
function __GMLCexecuteArrayGet(){
	if (rooted) {
		var _target = target();
		return _target[key()];
	}
	var _key = key();
	var _target = target();
	return _target[_key];
}
function __GMLCcompileArrayGet(_rootNode, _parentNode, _target, _key, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileArrayGet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = __GMLCcompileExpression(_rootNode, _parentNode, _key);
	_output.rooted     = __GMLCarrayTargetIsRooted(_target);
	
	return method(_output, __GMLCexecuteArrayGet)
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//    rooted: <bool>, see __GMLCarrayTargetIsRooted
//}
#endregion
function __GMLCexecuteArraySet(){
	var _value = expression();
	if (rooted) {
		var _target = target();
		_target[key()] = _value;
		return;
	}
	var _key = key();
	var _target = target();
	_target[_key] = _value;
}
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
function __GMLCexecuteArrayCreateAndSetLocal(){
	var _value = expression();
	var _index = index();
	var _target = locals[localIndex];
	
	if (!is_array(_target)) {
		_target = array_create(_index+1);
		locals[localIndex] = _target;
		localsWrittenTo[localIndex] = true;
	}
	
	_target[_index] = _value;
}
#region jsDoc
/// @func    __GMLCexecuteArrayGetForWrite()
/// @desc    Executes one inner level of a nested array write `a[i][j] = v` (node fields: target, key, rooted): returns
///          the element `target()[key()]`, after storing a new empty array there when it is missing or not an array.
/// @self    __GMLC_Function
/// @returns {Array}
#endregion
function __GMLCexecuteArrayGetForWrite(){
	// GameMaker: `a = []; a[1][2] = 3` gives [0, [0, 0, 3]], and `a = [0, 0]; a[1][0] = 5` gives [0, [5]]
	if (rooted) {
		var _target = target();
		var _key = key();
	}
	else {
		var _key = key();
		var _target = target();
	}
	// the root of a nested write must already be an array (GameMaker would create it; GMLC refuses)
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
function __GMLCcompileArrayTargetForWrite(_rootNode, _parentNode, _target, _span) {
	_target = __GMLCdesugarIndex(_target);
	if (_target.kind != __GMLC_NodeKind_Index)
	|| (_target.accessor != "Array") {
		return __GMLCcompileExpression(_rootNode, _parentNode, _target);
	}
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileArrayGetForWrite", "<Missing Error Message>", _span);
	_output.target = __GMLCcompileArrayTargetForWrite(_rootNode, _parentNode, _target.object, _span);
	_output.key    = __GMLCcompileExpression(_rootNode, _parentNode, _target.keys[0]);
	_output.rooted = __GMLCarrayTargetIsRooted(_target.object);
	return method(_output, __GMLCexecuteArrayGetForWrite);
}
function __GMLCcompileArraySet(_rootNode, _parentNode, _target, _key, _expression, _span) {
	if (_target.kind == __GMLC_NodeKind_Identifier) {
		if (_target.symbol.kind == "Local") {
			var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Getter", "<Missing Error Message>", _span);	
			
			_output.locals          = _parentNode.locals;
			_output.localIndex      = _parentNode.localLookUps[$ _target.name];
			_output.localsWrittenTo = _parentNode.localsWrittenTo;
			
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
	_output.rooted     = __GMLCarrayTargetIsRooted(_target);
	
	return method(_output, __GMLCexecuteArraySet)
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
//    keyX: <expression>,
//    keyY: <expression>,
//}
#endregion
function __GMLCexecuteGridGet(){
	var _keyY = keyY();
	var _keyX = keyX();
	var _target = target();
	return _target[# _keyX, _keyY];
}
function __GMLCcompileGridGet(_rootNode, _parentNode, _target, _keyX, _keyY, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileGridGet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.keyX       = __GMLCcompileExpression(_rootNode, _parentNode, _keyX);
	_output.keyY       = __GMLCcompileExpression(_rootNode, _parentNode, _keyY);
	
    return method(_output, __GMLCexecuteGridGet)
}
#region //{
//    target: <expression>,
//    keyX: <expression>,
//    keyY: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteGridSet(){
	var _value = expression();
	var _keyY = keyY();
	var _keyX = keyX();
	var _target = target();
	_target[# _keyX, _keyY] = _value;
}
function __GMLCcompileGridSet(_rootNode, _parentNode, _target, _keyX, _keyY, _expression, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileGridSet", "<Missing Error Message>", _span);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.keyX       = __GMLCcompileExpression(_rootNode, _parentNode, _keyX);
	_output.keyY       = __GMLCcompileExpression(_rootNode, _parentNode, _keyY);
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
	
	var _t = method_get_self(target)
	
	if (is_gmlc_function(_target)) {
		_target = __gmlc_static_get(_target)
	}
	
	if (struct_exists(_target, key)) {
		return _target[$ key];
	}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return _static[$ key];
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it.")
	
}
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
/// @desc    Executes a compound assignment (`+=`, `??=`, ...) on a dot accessor, evaluating the target once (node
///          fields: target, key (the member name), right, apply: function(current, right), undefined for `??=`).
/// @self    __GMLC_Function
#endregion
function __GMLCexecuteCompoundDot(){
	var _target = target();
	var _owner = __GMLCdotOwner(_target, key, self);
	if (apply == undefined) {
		_owner[$ key] ??= right();
		return;
	}
	_owner[$ key] = apply(_owner[$ key], right());
}
#region jsDoc
/// @func    __GMLCexecuteCompoundArrayRooted()
/// @desc    Executes a compound assignment (`+=`, `??=`, ...) on an array accessor rooted at a variable or a member,
///          evaluating its path and index once (node fields: target, key, right, apply as in __GMLCexecuteCompoundDot).
/// @self    __GMLC_Function
#endregion
function __GMLCexecuteCompoundArrayRooted(){
	var _target = target();
	var _key = key();
	if (apply == undefined) {
		_target[_key] ??= right();
		return;
	}
	_target[_key] = apply(_target[_key], right());
}
#region jsDoc
/// @func    __GMLCdotOwner(_target, _key, _node)
/// @desc    Returns the struct that holds `_key` for a dot access on `_target`: the target itself or the first static
///          parent that has it. Throws like a read of a missing variable when none does.
/// @param   {Any}    _target : The value before the dot
/// @param   {String} _key    : The member name
/// @param   {Struct} _node   : The executing node, for the error's line
/// @returns {Struct}
#endregion
function __GMLCdotOwner(_target, _key, _node) {
	if (is_gmlc_function(_target)) {
		_target = __gmlc_static_get(_target)
	}
	if (struct_exists(_target, _key)) {
		return _target;
	}
	var _static = __gmlc_static_get(_target)
	while (_static != undefined) {
		if struct_exists(_static, _key) {
			return _static;
		}
		_static = __gmlc_static_get(_static)
	}
	var _at = __gmlc_node_position(_node);
	throw_gmlc_error($"Variable <{typeof(_target)}>.{_key} not set before reading it.", _at.line, _at.lineString, _at.column, _at.fileName)
}
function __GMLCcompoundPlus(_a, _b)       { return _a + _b; }
function __GMLCcompoundMinus(_a, _b)      { return _a - _b; }
function __GMLCcompoundMultiply(_a, _b)   { return _a * _b; }
function __GMLCcompoundDivide(_a, _b)     { return _a / _b; }
function __GMLCcompoundMod(_a, _b)        { return _a % _b; }
function __GMLCcompoundBitwiseXOR(_a, _b) { return _a ^ _b; }
function __GMLCcompoundBitwiseAND(_a, _b) { return _a & _b; }
function __GMLCcompoundBitwiseOR(_a, _b)  { return _a | _b; }
function __GMLCcompileStructDotAccSet(_rootNode, _parentNode, _target, _key, _expression, _span) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructDotAccSet", "<Missing Error Message>", _span);
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = _key;
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);
	
    return method(_output, __GMLCexecuteStructDotAccSet)
}
#endregion

#endregion

function __GMLCexecuteUpdatePlusPlusPrefix() {
    // Prefix ++
	var _val = getter();
	setter(_val + 1);
	return _val + 1;
}
function __GMLCexecuteUpdatePlusPlusPostfix() {
	// Postfix ++
	var _val = getter();
	setter(_val + 1);
	return _val;
}
function __GMLCexecuteUpdateMinusMinusPrefix() {
    // Prefix --
	var _val = getter();
	setter(_val - 1);
	return _val - 1;
}
function __GMLCexecuteUpdateMinusMinusPostfix() {
    // Postfix --
	var _val = getter();
	setter(_val - 1);
	return _val;
}


#endregion

#region Scope Updatters (++ and --)

#region Self
function __GMLCexecuteUpdatePropertySelfPlusPlusPrefix() {
    return ++global.gmlc_self_instance[$ key];
}
function __GMLCexecuteUpdatePropertySelfPlusPlusPostfix() {
	return global.gmlc_self_instance[$ key]++;
}
function __GMLCexecuteUpdatePropertySelfMinusMinusPrefix() {
    return --global.gmlc_self_instance[$ key];
}
function __GMLCexecuteUpdatePropertySelfMinusMinusPostfix() {
    return global.gmlc_self_instance[$ key]--;
}
#endregion
#region Other
function __GMLCexecuteUpdatePropertyOtherPlusPlusPrefix() {
    return ++global.gmlc_other_instance[$ key];
}
function __GMLCexecuteUpdatePropertyOtherPlusPlusPostfix() {
    return global.gmlc_other_instance[$ key]++;
}
function __GMLCexecuteUpdatePropertyOtherMinusMinusPrefix() {
    return --global.gmlc_other_instance[$ key];
}
function __GMLCexecuteUpdatePropertyOtherMinusMinusPostfix() {
    return global.gmlc_other_instance[$ key]--;
}
#endregion
#region Global
function __GMLCexecuteUpdatePropertyGlobalPlusPlusPrefix() {
    return ++rootNode.globals[$ key];
}
function __GMLCexecuteUpdatePropertyGlobalPlusPlusPostfix() {
    return rootNode.globals[$ key]++;
}
function __GMLCexecuteUpdatePropertyGlobalMinusMinusPrefix() {
    return --rootNode.globals[$ key];
}
function __GMLCexecuteUpdatePropertyGlobalMinusMinusPostfix() {
    return rootNode.globals[$ key]--;
}
#endregion
#region Local
function __GMLCexecuteUpdatePropertyLocalPlusPlusPrefix() {
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.")
    return ++locals[localIndex];
}
function __GMLCexecuteUpdatePropertyLocalPlusPlusPostfix() {
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.")
    return locals[localIndex]++;
}
function __GMLCexecuteUpdatePropertyLocalMinusMinusPrefix() {
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.")
    return --locals[localIndex];
}
function __GMLCexecuteUpdatePropertyLocalMinusMinusPostfix() {
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.")
    return locals[localIndex]--;
}
#endregion
#region Static
function __GMLCexecuteUpdatePropertyStaticPlusPlusPrefix() {
    return ++parentNode.statics[$ key];
}
function __GMLCexecuteUpdatePropertyStaticPlusPlusPostfix() {
    return parentNode.statics[$ key]++;
}
function __GMLCexecuteUpdatePropertyStaticMinusMinusPrefix() {
    return --parentNode.statics[$ key];
}
function __GMLCexecuteUpdatePropertyStaticMinusMinusPostfix() {
    return parentNode.statics[$ key]--;
}
#endregion
#region Unique
function __GMLCexecuteUpdatePropertyUniquePlusPlusPrefix() {
	var _val = key.get() + 1;
	key.set(_val);
	return _val;
}
function __GMLCexecuteUpdatePropertyUniquePlusPlusPostfix() {
	var _val = key.get();
	key.set(_val + 1);
	return _val;
}
function __GMLCexecuteUpdatePropertyUniqueMinusMinusPrefix() {
	var _val = key.get() - 1;
	key.set(_val);
	return _val;
}
function __GMLCexecuteUpdatePropertyUniqueMinusMinusPostfix() {
    var _val = key.get();
	key.set(_val - 1);
	return _val;
}
#endregion

#region Accessors
// ++ and -- on accessors (see "Evaluation order" above): a rooted array evaluates its path and index once; every
// other accessor reads with keys then target, and writes evaluating its keys and target again.
#region //{
//    target: <expression>,
//    key: <expression>, (keyX, keyY for grids)
//    delta: 1 or -1,
//    prefix: <bool>,
//    rooted: <bool>, arrays only
//}
#endregion
function __GMLCexecuteUpdateArray() {
	if (rooted) {
		var _target = target();
		var _key = key();
		var _old = _target[_key];
		_target[_key] = _old + delta;
		return prefix ? _old + delta : _old;
	}
	var _key = key();
	var _target = target();
	var _old = _target[_key];
	_key = key();
	_target = target();
	_target[_key] = _old + delta;
	return prefix ? _old + delta : _old;
}
function __GMLCexecuteUpdateList() {
	var _key = key();
	var _target = target();
	var _old = _target[| _key];
	_key = key();
	_target = target();
	_target[| _key] = _old + delta;
	return prefix ? _old + delta : _old;
}
function __GMLCexecuteUpdateMap() {
	var _key = key();
	var _target = target();
	var _old = _target[? _key];
	_key = key();
	_target = target();
	_target[? _key] = _old + delta;
	return prefix ? _old + delta : _old;
}
function __GMLCexecuteUpdateGrid() {
	var _keyY = keyY();
	var _keyX = keyX();
	var _target = target();
	var _old = _target[# _keyX, _keyY];
	_keyY = keyY();
	_keyX = keyX();
	_target = target();
	_target[# _keyX, _keyY] = _old + delta;
	return prefix ? _old + delta : _old;
}
function __GMLCexecuteUpdateStruct() {
	var _key = key();
	var _target = target();
	var _old = _target[$ _key];
	_key = key();
	_target = target();
	_target[$ _key] = _old + delta;
	return prefix ? _old + delta : _old;
}
function __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, _executor) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUpdateAccessor", "<Missing Error Message>", _node.span);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _node[$ "argument"].object);
	if (_executor == __GMLCexecuteUpdateGrid) {
		_output.keyX = __GMLCcompileExpression(_rootNode, _parentNode, _node[$ "argument"].keys[0]);
		_output.keyY = __GMLCcompileExpression(_rootNode, _parentNode, _node[$ "argument"].keys[1]);
	}
	else {
		_output.key = __GMLCcompileExpression(_rootNode, _parentNode, _node[$ "argument"].keys[0]);
	}
	_output.rooted = (_executor == __GMLCexecuteUpdateArray) && __GMLCarrayTargetIsRooted(_node[$ "argument"].object);
	_output.delta  = (_node.op == "++") ? 1 : -1;
	_output.prefix = _node.prefix;
	return method(_output, _executor);
}
function __GMLCcompileUpdateArray(_rootNode, _parentNode, _node)  { return __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, __GMLCexecuteUpdateArray);  }
function __GMLCcompileUpdateList(_rootNode, _parentNode, _node)   { return __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, __GMLCexecuteUpdateList);   }
function __GMLCcompileUpdateMap(_rootNode, _parentNode, _node)    { return __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, __GMLCexecuteUpdateMap);    }
function __GMLCcompileUpdateGrid(_rootNode, _parentNode, _node)   { return __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, __GMLCexecuteUpdateGrid);   }
function __GMLCcompileUpdateStruct(_rootNode, _parentNode, _node) { return __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, __GMLCexecuteUpdateStruct); }
#endregion
#region Dot
function __GMLCexecuteUpdateStructDotAccPlusPlusPrefix() {
	var _target = target();
	
	if (is_gmlc_function(_target)) {
		_target = __gmlc_static_get(_target)
	}
	
	if (struct_exists(_target, key)) {
		return ++_target[$ key];
	}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return ++_static[$ key];
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it.")
	
}
function __GMLCexecuteUpdateStructDotAccPlusPlusPostfix() {
	var _target = target();
	
	if (is_gmlc_function(_target)) {
		_target = __gmlc_static_get(_target)
	}
	
	if (struct_exists(_target, key)) {
		return _target[$ key]++;
	}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return _static[$ key]++;
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it.")
	
	var _target = target();
	return _target[$ key]++;
}
function __GMLCexecuteUpdateStructDotAccMinusMinusPrefix() {
	var _target = target();
	
	if (is_gmlc_function(_target)) {
		_target = __gmlc_static_get(_target)
	}
	
	if (struct_exists(_target, key)) {
		return --_target[$ key];
	}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return --_static[$ key];
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it.")
	
}
function __GMLCexecuteUpdateStructDotAccMinusMinusPostfix() {
	var _target = target();
	
	if (is_gmlc_function(_target)) {
		_target = __gmlc_static_get(_target)
	}
	
	if (struct_exists(_target, key)) {
		return _target[$ key]--;
	}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return _static[$ key]--;
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it.")
	
}
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
#region Variable
function __GMLCcompileUpdateVariable(_rootNode, _parentNode, _scope, _key, _increment, _prefix, _span) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUpdateVariable", "<Missing Error Message>", _span);
	_output.key = _key;
    if (_scope == "Local") {
		_output.locals = _parentNode.locals;
		_output.localsWrittenTo = _parentNode.localsWrittenTo;
		_output.localIndex = _parentNode.localLookUps[$ _output.key];
	}
	else if (_scope == "Global") {
		_output.globals = _rootNode.globals;
	}
	
	return method(_output, __GMLCGetScopeUpdater(_scope, _increment, _prefix));
}
#endregion

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

