// this script contains a bunch of functions which imitate native functions,
// but to allow for us to work better with gmlc

/// @ignore
function __method(_struct, _func) {
	
	static __executeMethod = function() {
		var argArr = array_create(argument_count, undefined);
		var _i=0; repeat(argument_count) {
			argArr[_i] = argument[_i];
		_i++}
	
		var _prevOther = global.otherInstance;
		var _prevSelf  = global.selfInstance;
		global.otherInstance = global.selfInstance;
		global.selfInstance = target;
	
		var _return = method_call(func, argArr);
	
		global.otherInstance = _prevOther;
		global.selfInstance  = _prevSelf;
	
		return _return;
	}
	
	
	
	if (is_method(_func))
	&& (is_gmlc_progam(_func)) {
		if (is_gmlc_method(_func)) {
			//a gmlc method
			throw "Red needs to support methoding a method, what ever that does"
		}
		else {
			//a gmlc function
			return method({
				"__@@GMLC_is_method@@__": true,
				target: _struct,
				func: _func,
			}, __executeMethod)
		}
	}
	else {
		//a native gml function/method
		with (global.otherInstance) with (global.selfInstance) {
			return method(_struct, _func);
		}
	}
}
