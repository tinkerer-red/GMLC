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
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n{json_stringify(callstack, true)}", self.line, self.lineString)
	
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
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.", line, lineString)
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

#region Array
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteArrayGet(){
	var _target = target();
	return _target[key()]
}
function __GMLCcompileArrayGet(_rootNode, _parentNode, _target, _key, _line, _lineString) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileArrayGet", "<Missing Error Message>", _line, _lineString);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = __GMLCcompileExpression(_rootNode, _parentNode, _key);
	
	return method(_output, __GMLCexecuteArrayGet)
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteArraySet(){
	var _target = target();
	_target[key()] = expression()
}
function __GMLCexecuteArrayCreateAndSetSelf(){
	var _self = global.gmlc_self_instance;
	var _target = _self[$ key];
	var _index = index();
	
	if (!is_array(_target)) {
		_target = array_create(_index+1);
		_self[$ key] = _target;
	}
	
	_target[_index] = expression();
}
function __GMLCexecuteArrayCreateAndSetLocal(){
	var _target = locals[localIndex];
	var _index = index();
	
	if (!is_array(_target)) {
		_target = array_create(_index+1);
		locals[localIndex] = _target;
		localsWrittenTo[localIndex] = true;
	}
	
	_target[_index] = expression();
}
function __GMLCcompileArraySet(_rootNode, _parentNode, _target, _key, _expression, _line, _lineString) {
	if (_target.type == __GMLC_NodeType_Identifier) {
		if (_target.scope == ScopeType_LOCAL) {
			var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Getter", "<Missing Error Message>", _line, _lineString);	
			
			_output.locals          = _parentNode.locals;
			_output.localIndex      = _parentNode.localLookUps[$ _target.name];
			_output.localsWrittenTo = _parentNode.localsWrittenTo;
			
			_output.index = __GMLCcompileExpression(_rootNode, _parentNode, _key);
			_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);;
			
			return __vanilla_method(_output, __GMLCexecuteArrayCreateAndSetLocal);
		}
		if (_target.scope == ScopeType_SELF) {
			var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Getter", "<Missing Error Message>", _line, _lineString);	
			
			_output.key = _target.name;
			
			_output.index = __GMLCcompileExpression(_rootNode, _parentNode, _key);
			_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);;
			
			return __vanilla_method(_output, __GMLCexecuteArrayCreateAndSetSelf);
		}
		
	}
	
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileArraySet", "<Missing Error Message>", _line, _lineString);
	
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = __GMLCcompileExpression(_rootNode, _parentNode, _key);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);
	
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
	var _target = target();
	return _target[| key()]
}
function __GMLCcompileListGet(_rootNode, _parentNode, _target, _key, _line, _lineString) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileListGet", "<Missing Error Message>", _line, _lineString);
	
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
	var _target = target();
	_target[| key()] = expression()
}
function __GMLCcompileListSet(_rootNode, _parentNode, _target, _key, _expression, _line, _lineString) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileListSet", "<Missing Error Message>", _line, _lineString);
	
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
	var _target = target();
	return _target[? key()]
}
function __GMLCcompileMapGet(_rootNode, _parentNode, _target, _key, _line, _lineString) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileMapGet", "<Missing Error Message>", _line, _lineString);
	
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
	var _target = target();
	var _key = key();
	var _exp = expression();
	_target[? key()] = expression()
}
function __GMLCcompileMapSet(_rootNode, _parentNode, _target, _key, _expression, _line, _lineString) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileMapSet", "<Missing Error Message>", _line, _lineString);
	
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
	var _target = target();
	return _target[# keyX(), keyY()]
}
function __GMLCcompileGridGet(_rootNode, _parentNode, _target, _keyX, _keyY, _line, _lineString) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileGridGet", "<Missing Error Message>", _line, _lineString);
	
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
	var _target = target();
	_target[# keyX(), keyY()] = expression()
}
function __GMLCcompileGridSet(_rootNode, _parentNode, _target, _keyX, _keyY, _expression, _line, _lineString) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileGridSet", "<Missing Error Message>", _line, _lineString);
	
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
	var _target = target();
	return _target[$ key()]
}
function __GMLCcompileStructGet(_rootNode, _parentNode, _target, _key, _line, _lineString) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructGet", "<Missing Error Message>", _line, _lineString);
	
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
	var _target = target();
	_target[$ key()] = expression()
}
function __GMLCcompileStructSet(_rootNode, _parentNode, _target, _key, _expression, _line, _lineString) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructSet", "<Missing Error Message>", _line, _lineString);
	
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
	
	
	// this is a safety check for a bug in GML
	// https://github.com/YoYoGames/GameMaker-Bugs/issues/8048
	//var _inst_of = instanceof(_target);
	//if (_inst_of == "Object")
	//|| (_inst_of == undefined) {
	//	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n{json_stringify(callstack, true)}", self.line, self.lineString)
	//}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return _static[$ key];
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n{json_stringify(callstack, true)}", self.line, self.lineString)
	
}
function __GMLCcompileStructDotAccGet(_rootNode, _parentNode, _target, _key, _line, _lineString) {
	
	//incase it's a valid scope, lets hoist it to a better fitted function
	//if (_target.type == __GMLC_NodeType_Identifier) {
	//	var _getter = __GMLCGetScopeGetter(_target.scope)
		
	//	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructDotAccSet", "<Missing Error Message>", _line, _lineString);
	//	_output.key        = _key.value;
		
	//	if (_target.scope == ScopeType_GLOBAL) {
	//		_output.globals = _rootNode.globals;
	//	}
		
	//	method(_output, _getter)
	//}
	
	//leave the following to allow for thing.thing.thing() to be a valid call
	
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructDotAccGet", "<Missing Error Message>", _line, _lineString);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key    = _key.value;
	
	return method(_output, __GMLCexecuteStructDotAccGet)
}
#region //{
//    target: <expression>,
//    key: <stringLiteral>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteStructDotAccSet(){
	var _target = target();
	
	if (is_gmlc_function(_target)) {
		_target = __gmlc_static_get(_target)
	}
	
	if (struct_exists(_target, key)) {
		_target[$ key] = expression();
		return
	}
	
	// this is a safety check for a bug in GML
	// https://github.com/YoYoGames/GameMaker-Bugs/issues/8048
	var _inst_of = instanceof(_target);
	if (_inst_of == "Object")
	|| (_inst_of == undefined) {
		_target[$ key] = expression();
		return
	}	
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			_static[$ key] = expression();
			return
		}
		_static = __gmlc_static_get(_static)
	}
	
	//last resort if no statics contain the key write to target
	_target[$ key] = expression();
	return
}
function __GMLCcompileStructDotAccSet(_rootNode, _parentNode, _target, _key, _expression, _line, _lineString) {
    
	//incase it's a valid scope, lets hoist it to a better fitted function
	if (_target.type == __GMLC_NodeType_Identifier) {
		var _setter = __GMLCGetScopeSetter(_target.scope)
		
		var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructDotAccSet", "<Missing Error Message>", _line, _lineString);
		_output.key        = _key.value;
		_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);
		
		if (_target.scope == ScopeType_GLOBAL) {
			_output.globals = _rootNode.globals;
		}
		
		method(_output, _setter)
	}
	
	//leave the following to allow for thing.thing.thing() to be a valid call
	
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructDotAccSet", "<Missing Error Message>", _line, _lineString);
	_output.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target);
	_output.key        = _key.value;
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
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.", line, lineString)
    return ++locals[localIndex];
}
function __GMLCexecuteUpdatePropertyLocalPlusPlusPostfix() {
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.", line, lineString)
    return locals[localIndex]++;
}
function __GMLCexecuteUpdatePropertyLocalMinusMinusPrefix() {
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.", line, lineString)
    return --locals[localIndex];
}
function __GMLCexecuteUpdatePropertyLocalMinusMinusPostfix() {
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.", line, lineString)
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

#region Arrays
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteUpdateArrayPlusPlusPrefix() {
	var _target = target();
	return ++_target[key()];
}
function __GMLCexecuteUpdateArrayPlusPlusPostfix() {
	var _target = target();
	return _target[key()]++;
}
function __GMLCexecuteUpdateArrayMinusMinusPrefix() {
	var _target = target();
	return --_target[key()];
}
function __GMLCexecuteUpdateArrayMinusMinusPostfix() {
	var _target = target();
	return _target[key()]--;
}
function __GMLCcompileUpdateArray(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUpdateArray", "<Missing Error Message>", _node.line, _node.lineString);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr.expr);
	_output.key    = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr.val1);
    
    var _increment = (_node.operator == "++") ? true : false;
	var _prefix = _node.prefix;
	
	if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateArrayPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateArrayPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateArrayMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateArrayMinusMinusPostfix);
}
#endregion
#region List
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteUpdateListPlusPlusPrefix() {
	var _target = target();
	return ++_target[| key()];
}
function __GMLCexecuteUpdateListPlusPlusPostfix() {
	var _target = target();
	return _target[| key()]++;
}
function __GMLCexecuteUpdateListMinusMinusPrefix() {
	var _target = target();
	return --_target[| key()];
}
function __GMLCexecuteUpdateListMinusMinusPostfix() {
	var _target = target();
	return _target[| key()]--;
}
function __GMLCcompileUpdateList(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUpdateList", "<Missing Error Message>", _node.line, _node.lineString);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr.expr);
	_output.key    = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr.val1);
    
    var _increment = (_node.operator == "++") ? true : false;
	var _prefix = _node.prefix;
	
	if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateListPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateListPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateListMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateListMinusMinusPostfix);
}
#endregion
#region Map
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteUpdateMapPlusPlusPrefix() {
	var _target = target();
	return ++_target[? key()];
}
function __GMLCexecuteUpdateMapPlusPlusPostfix() {
	var _target = target();
	return _target[? key()]++;
}
function __GMLCexecuteUpdateMapMinusMinusPrefix() {
	var _target = target();
	return --_target[? key()];
}
function __GMLCexecuteUpdateMapMinusMinusPostfix() {
	var _target = target();
	return _target[? key()]--;
}
function __GMLCcompileUpdateMap(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUpdateMap", "<Missing Error Message>", _node.line, _node.lineString);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr.expr);
	_output.key    = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr.val1);
    
    var _increment = (_node.operator == "++") ? true : false;
	var _prefix = _node.prefix;
	
	if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateMapPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateMapPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateMapMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateMapMinusMinusPostfix);
}
#endregion
#region Grid
#region //{
//    target: <expression>,
//    keyX: <expression>,
//    keyY: <expression>,
//}
#endregion
function __GMLCexecuteUpdateGridPlusPlusPrefix() {
	var _target = target();
	return ++_target[# keyX(), keyY()];
}
function __GMLCexecuteUpdateGridPlusPlusPostfix() {
	var _target = target();
	return _target[# keyX(), keyY()]++;
}
function __GMLCexecuteUpdateGridMinusMinusPrefix() {
	var _target = target();
	return --_target[# keyX(), keyY()];
}
function __GMLCexecuteUpdateGridMinusMinusPostfix() {
	var _target = target();
	return _target[# keyX(), keyY()]--;
}
function __GMLCcompileUpdateGrid(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUpdateGrid", "<Missing Error Message>", _node.line, _node.lineString);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr.expr);
	_output.keyX   = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr.val1);
	_output.keyY   = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr.val2);
    
    var _increment = (_node.operator == "++") ? true : false;
	var _prefix = _node.prefix;
	
	if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateGridPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateGridPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateGridMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateGridMinusMinusPostfix);
}
#endregion
#region Struct
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteUpdateStructPlusPlusPrefix() {
	var _target = target();
	return ++_target[$ key()];
}
function __GMLCexecuteUpdateStructPlusPlusPostfix() {
	var _target = target();
	return _target[$ key()]++;
}
function __GMLCexecuteUpdateStructMinusMinusPrefix() {
	var _target = target();
	return --_target[$ key()];
}
function __GMLCexecuteUpdateStructMinusMinusPostfix() {
	var _target = target();
	return _target[$ key()]--;
}
function __GMLCcompileUpdateStruct(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUpdateStruct", "<Missing Error Message>", _node.line, _node.lineString);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr.expr);
	_output.key    = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr.val1);
    
    var _increment = (_node.operator == "++") ? true : false;
	var _prefix = _node.prefix;
	
	if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateStructPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateStructPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateStructMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateStructMinusMinusPostfix);
}
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
	
	// this is a safety check for a bug in GML
	// https://github.com/YoYoGames/GameMaker-Bugs/issues/8048
	//var _inst_of = instanceof(_target);
	//if (_inst_of == "Object")
	//|| (_inst_of == undefined) {
	//	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n{json_stringify(callstack, true)}", self.line, self.lineString)
	//}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return ++_static[$ key];
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n{json_stringify(callstack, true)}", self.line, self.lineString)
	
}
function __GMLCexecuteUpdateStructDotAccPlusPlusPostfix() {
	var _target = target();
	
	if (is_gmlc_function(_target)) {
		_target = __gmlc_static_get(_target)
	}
	
	if (struct_exists(_target, key)) {
		return _target[$ key]++;
	}
	
	// this is a safety check for a bug in GML
	// https://github.com/YoYoGames/GameMaker-Bugs/issues/8048
	//var _inst_of = instanceof(_target);
	//if (_inst_of == "Object")
	//|| (_inst_of == undefined) {
	//	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n{json_stringify(callstack, true)}", self.line, self.lineString)
	//}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return _static[$ key]++;
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n{json_stringify(callstack, true)}", self.line, self.lineString)
	
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
	
	// this is a safety check for a bug in GML
	// https://github.com/YoYoGames/GameMaker-Bugs/issues/8048
	//var _inst_of = instanceof(_target);
	//if (_inst_of == "Object")
	//|| (_inst_of == undefined) {
	//	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n{json_stringify(callstack, true)}", self.line, self.lineString)
	//}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return --_static[$ key];
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n{json_stringify(callstack, true)}", self.line, self.lineString)
	
}
function __GMLCexecuteUpdateStructDotAccMinusMinusPostfix() {
	var _target = target();
	
	if (is_gmlc_function(_target)) {
		_target = __gmlc_static_get(_target)
	}
	
	if (struct_exists(_target, key)) {
		return _target[$ key]--;
	}
	
	// this is a safety check for a bug in GML
	// https://github.com/YoYoGames/GameMaker-Bugs/issues/8048
	//var _inst_of = instanceof(_target);
	//if (_inst_of == "Object")
	//|| (_inst_of == undefined) {
	//	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n{json_stringify(callstack, true)}", self.line, self.lineString)
	//}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return _static[$ key]--;
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n{json_stringify(callstack, true)}", self.line, self.lineString)
	
}
function __GMLCcompileUpdateStructDotAcc(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUpdateStructDotAcc", "<Missing Error Message>", _node.line, _node.lineString);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr.expr);
	_output.key    = _node.expr.val1.value
    
    var _increment = (_node.operator == "++") ? true : false;
	var _prefix = _node.prefix;
	
	if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateStructDotAccPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateStructDotAccPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateStructDotAccMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateStructDotAccMinusMinusPostfix);
}
#endregion
#region Variable
function __GMLCcompileUpdateVariable(_rootNode, _parentNode, _scope, _key, _increment, _prefix, _line, _lineString) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUpdateVariable", "<Missing Error Message>", _line, _lineString);
	_output.key = _key;
    if (_scope == ScopeType_LOCAL) {
		_output.locals = _parentNode.locals;
		_output.localsWrittenTo = _parentNode.localsWrittenTo;
		_output.localIndex = _parentNode.localLookUps[$ _output.key];
	}
	else if (_scope == ScopeType_GLOBAL) {
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

