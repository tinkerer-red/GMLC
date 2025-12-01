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
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n(line {self.line}) -\t{self.lineString}\n{json(callstack)}")
	
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
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.\nin line ({line}) `{lineString}`")
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
	throw "STOP USING THIS FUNCTION!!!!"
    switch (key) {
		case "self": return global.gmlc_self_instance;
		case "other": return global.gmlc_other_instance;
		case "all": return all;
		case "noone": return noone;
		
		case "fps": return fps;
		case "room": return room;
		case "lives": return lives;
		case "score": return score;
		case "health": return health;
		case "mouse_x": return mouse_x;
		case "visible": return visible;
		case "managed": return managed;
		case "mouse_y": return mouse_y;
		case "os_type": return os_type;
		case "game_id": return game_id;
		case "iap_data": return iap_data;
		case "argument": return parentNode.arguments;
		case "argument0": return parentNode.arguments[0];
		case "argument1": return parentNode.arguments[1];
		case "argument2": return parentNode.arguments[2];
		case "argument3": return parentNode.arguments[3];
		case "argument4": return parentNode.arguments[4];
		case "argument5": return parentNode.arguments[5];
		case "argument6": return parentNode.arguments[6];
		case "argument7": return parentNode.arguments[7];
		case "argument8": return parentNode.arguments[8];
		case "argument9": return parentNode.arguments[9];
		case "argument10": return parentNode.arguments[10];
		case "argument11": return parentNode.arguments[11];
		case "argument12": return parentNode.arguments[12];
		case "argument13": return parentNode.arguments[13];
		case "argument14": return parentNode.arguments[14];
		case "argument15": return parentNode.arguments[15];
		case "fps_real": return fps_real;
		case "room_last": return room_last;
		case "os_device": return os_device;
		case "delta_time": return delta_time;break;
		case "show_lives": return show_lives;break;
		case "path_index": return path_index;break;
		case "room_first": return room_first;break;
		case "room_width": return room_width;break;
		case "view_hport": return view_hport;break;
		case "view_xport": return view_xport;break;
		case "view_yport": return view_yport;break;
		case "debug_mode": return debug_mode;break;
		case "event_data": return event_data;break;
		case "view_wport": return view_wport;break;
		case "os_browser": return os_browser;break;
		case "os_version": return os_version;break;
		case "room_speed": return room_speed;break;
		case "show_score": return show_score;break;
		case "error_last": return error_last;break;
		case "display_aa": return display_aa;break;
		case "async_load": return async_load;break;
		case "instance_id": return instance_id;
		case "current_day": return current_day;
		case "view_camera": return view_camera;
		case "room_height": return room_height;
		case "show_health": return show_health;
		case "mouse_button": return mouse_button;
		case "keyboard_key": return keyboard_key;
		case "view_visible": return view_visible;
		case "game_save_id": return game_save_id;
		case "current_hour": return current_hour;
		case "room_caption": return room_caption;
		case "view_enabled": return view_enabled;
		case "event_action": return event_action;
		case "view_current": return view_current;
		case "current_time": return current_time;
		case "current_year": return current_year;
		case "browser_width": return browser_width;
		case "webgl_enabled": return webgl_enabled;
		case "current_month": return current_month;
		case "caption_score": return caption_score;
		case "caption_lives": return caption_lives;
		case "gamemaker_pro": return gamemaker_pro;
		case "cursor_sprite": return cursor_sprite;
		case "caption_health": return caption_health;
		case "instance_count": return instance_count;
		case "argument_count": return array_length(parentNode.arguments);
		case "error_occurred": return error_occurred;
		case "current_minute": return current_minute;
		case "current_second": return current_second;
		case "temp_directory": return temp_directory;
		case "browser_height": return browser_height;
		case "view_surface_id": return view_surface_id;
		case "room_persistent": return room_persistent;
		case "current_weekday": return current_weekday;
		case "keyboard_string": return keyboard_string;
		case "cache_directory": return cache_directory;
		case "mouse_lastbutton": return mouse_lastbutton;
		case "keyboard_lastkey": return keyboard_lastkey;
		case "wallpaper_config": return wallpaper_config;
		case "background_color": return background_color;
		case "program_directory": return program_directory;
		case "game_project_name": return game_project_name;
		case "game_display_name": return game_display_name;
		//case "argument_relative": return argument_relative;
		case "keyboard_lastchar": return keyboard_lastchar;
		case "working_directory": return working_directory;
		case "rollback_event_id": return rollback_event_id;
		case "background_colour": return background_colour;
		case "font_texture_page_size": return font_texture_page_size;
		case "application_surface": return application_surface;
		case "rollback_api_server": return rollback_api_server;
		case "gamemaker_registered": return gamemaker_registered;
		case "background_showcolor": return background_showcolor;
		case "rollback_event_param": return rollback_event_param;
		case "background_showcolour": return background_showcolour;
		case "rollback_game_running": return rollback_game_running;
		case "rollback_current_frame": return rollback_current_frame;
		case "rollback_confirmed_frame": return rollback_confirmed_frame;
		
	}
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
	switch (key) {
		//all write protected errors are at the bottom
		case "room":				     room				      = expression(); break;
		case "lives":				    lives				     = expression(); break;
		case "score":				    score				     = expression(); break;
		case "health":				   health				    = expression(); break;
		case "visible":				  visible				   = expression(); break;
		case "argument":				 parentNode.arguments      = expression(); break;
		case "argument0":				parentNode.arguments[0]   = expression(); break;
		case "argument1":				parentNode.arguments[1]   = expression(); break;
		case "argument2":				parentNode.arguments[2]   = expression(); break;
		case "argument3":				parentNode.arguments[3]   = expression(); break;
		case "argument4":				parentNode.arguments[4]   = expression(); break;
		case "argument5":				parentNode.arguments[5]   = expression(); break;
		case "argument6":				parentNode.arguments[6]   = expression(); break;
		case "argument7":				parentNode.arguments[7]   = expression(); break;
		case "argument8":				parentNode.arguments[8]   = expression(); break;
		case "argument9":				parentNode.arguments[9]   = expression(); break;
		case "argument10":		       parentNode.arguments[10]  = expression(); break;
		case "argument11":		       parentNode.arguments[11]  = expression(); break;
		case "argument12":		       parentNode.arguments[12]  = expression(); break;
		case "argument13":		       parentNode.arguments[13]  = expression(); break;
		case "argument14":		       parentNode.arguments[14]  = expression(); break;
		case "argument15":		       parentNode.arguments[15]  = expression(); break;
		case "show_lives":		       show_lives				= expression(); break;
		case "room_width":		       room_width				= expression(); break;
		case "view_hport":		       view_hport				= expression(); break;
		case "view_xport":		       view_xport				= expression(); break;
		case "view_yport":		       view_yport				= expression(); break;
		case "view_wport":		       view_wport				= expression(); break;
		case "room_speed":		       room_speed				= expression(); break;
		case "show_score":		       show_score				= expression(); break;
		case "error_last":		       error_last				= expression(); break;
		case "view_camera":		      view_camera		       = expression(); break;
		case "room_height":		      room_height		       = expression(); break;
		case "show_health":		      show_health		       = expression(); break;
		case "mouse_button":		     mouse_button		      = expression(); break;
		case "keyboard_key":		     keyboard_key		      = expression(); break;
		case "view_visible":		     view_visible		      = expression(); break;
		case "room_caption":		     room_caption		      = expression(); break;
		case "view_enabled":		     view_enabled		      = expression(); break;
		case "caption_score":		    caption_score		     = expression(); break;
		case "caption_lives":		    caption_lives		     = expression(); break;
		case "cursor_sprite":		    cursor_sprite		     = expression(); break;
		case "caption_health":		   caption_health		    = expression(); break;
		case "error_occurred":		   error_occurred		    = expression(); break;
		case "view_surface_id":		  view_surface_id		   = expression(); break;
		case "room_persistent":		  room_persistent		   = expression(); break;
		case "keyboard_string":		  keyboard_string		   = expression(); break;
		case "mouse_lastbutton":		 mouse_lastbutton		  = expression(); break;
		case "keyboard_lastkey":		 keyboard_lastkey		  = expression(); break;
		case "background_color":		 background_color		  = expression(); break;
		case "keyboard_lastchar":		keyboard_lastchar		 = expression(); break;
		case "background_colour":		background_colour		 = expression(); break;
		case "font_texture_page_size":   font_texture_page_size    = expression(); break;
		case "background_showcolor":     background_showcolor      = expression(); break;
		case "background_showcolour":    background_showcolour     = expression(); break;
		
		//begining of write errors
		case "self":
		case "other":
		case "all":
		case "noone":
		case "delta_time":
		case "path_index":
		case "room_first":
		case "debug_mode":
		case "event_data":
		case "os_browser":
		case "os_version":
		case "display_aa":
		case "async_load":
		case "instance_id":
		case "current_day":
		case "game_save_id":
		case "current_hour":
		case "event_action":
		case "view_current":
		case "current_time":
		case "current_year":
		case "browser_width":
		case "webgl_enabled":
		case "current_month":
		case "gamemaker_pro":
		case "instance_count":
		case "argument_count":
		case "current_minute":
		case "current_second":
		case "temp_directory":
		case "browser_height":
		case "current_weekday":
		case "cache_directory":
		case "wallpaper_config":
		case "program_directory":
		case "game_project_name":
		case "game_display_name":
		case "argument_relative":
		case "working_directory":
		case "rollback_event_id":
		case "application_surface":
		case "rollback_api_server":
		case "gamemaker_registered":
		case "rollback_event_param":
		case "rollback_game_running":
		case "rollback_current_frame":
		case "rollback_confirmed_frame":
		case "fps":
		case "mouse_x":
		case "managed":
		case "mouse_y":
		case "os_type":
		case "game_id":
		case "iap_data":
		case "fps_real":
		case "room_last":
		case "os_device":
			throw_gmlc_error($"Attempting to write to a read-only variable {key}"+$"\n(line {line}) -\t{lineString}")
	}
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
	if (_target.type == __GMLC_NodeType.Identifier) {
		if (_target.scope == ScopeType.LOCAL) {
			var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Getter", "<Missing Error Message>", _line, _lineString);	
			
			_output.locals          = _parentNode.locals;
			_output.localIndex      = _parentNode.localLookUps[$ _target.name];
			_output.localsWrittenTo = _parentNode.localsWrittenTo;
			
			_output.index = __GMLCcompileExpression(_rootNode, _parentNode, _key);
			_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);;
			
			return __vanilla_method(_output, __GMLCexecuteArrayCreateAndSetLocal);
		}
		if (_target.scope == ScopeType.SELF) {
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
	//	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n(line {self.line}) -\t{self.lineString}\n{json(callstack)}")
	//}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return _static[$ key];
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n(line {self.line}) -\t{self.lineString}\n{json(callstack)}")
	
}
function __GMLCcompileStructDotAccGet(_rootNode, _parentNode, _target, _key, _line, _lineString) {
	
	//incase it's a valid scope, lets hoist it to a better fitted function
	//if (_target.type == __GMLC_NodeType.Identifier) {
	//	var _getter = __GMLCGetScopeGetter(_target.scope)
		
	//	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructDotAccSet", "<Missing Error Message>", _line, _lineString);
	//	_output.key        = _key.value;
		
	//	if (_target.scope == ScopeType.GLOBAL) {
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
	if (_target.type == __GMLC_NodeType.Identifier) {
		var _setter = __GMLCGetScopeSetter(_target.scope)
		
		var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileStructDotAccSet", "<Missing Error Message>", _line, _lineString);
		_output.key        = _key.value;
		_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _expression);
		
		if (_target.scope == ScopeType.GLOBAL) {
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
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.\nin line ({line}) `{lineString}`")
    return ++locals[localIndex];
}
function __GMLCexecuteUpdatePropertyLocalPlusPlusPostfix() {
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.\nin line ({line}) `{lineString}`")
    return locals[localIndex]++;
}
function __GMLCexecuteUpdatePropertyLocalMinusMinusPrefix() {
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.\nin line ({line}) `{lineString}`")
    return --locals[localIndex];
}
function __GMLCexecuteUpdatePropertyLocalMinusMinusPostfix() {
	if (!localsWrittenTo[localIndex]) throw_gmlc_error($"local variable {key}({localIndex}) not set before reading it.\nin line ({line}) `{lineString}`")
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
    switch (key) {
		case "room": return ++room;
		case "lives": return ++lives;
		case "score": return ++score;
		case "health": return ++health;
		case "visible": return ++visible;
		case "argument": return ++parentNode.arguments;
		case "argument0": return ++parentNode.arguments[0];
		case "argument1": return ++parentNode.arguments[1];
		case "argument2": return ++parentNode.arguments[2];
		case "argument3": return ++parentNode.arguments[3];
		case "argument4": return ++parentNode.arguments[4];
		case "argument5": return ++parentNode.arguments[5];
		case "argument6": return ++parentNode.arguments[6];
		case "argument7": return ++parentNode.arguments[7];
		case "argument8": return ++parentNode.arguments[8];
		case "argument9": return ++parentNode.arguments[9];
		case "argument10": return ++parentNode.arguments[10];
		case "argument11": return ++parentNode.arguments[11];
		case "argument12": return ++parentNode.arguments[12];
		case "argument13": return ++parentNode.arguments[13];
		case "argument14": return ++parentNode.arguments[14];
		case "argument15": return ++parentNode.arguments[15];
		case "show_lives": return ++show_lives;
		case "room_width": return ++room_width;
		case "view_hport": return ++view_hport;
		case "view_xport": return ++view_xport;
		case "view_yport": return ++view_yport;
		case "view_wport": return ++view_wport;
		case "room_speed": return ++room_speed;
		case "show_score": return ++show_score;
		case "error_last": return ++error_last;
		case "view_camera": return ++view_camera;
		case "room_height": return ++room_height;
		case "show_health": return ++show_health;
		case "mouse_button": return ++mouse_button;
		case "keyboard_key": return ++keyboard_key;
		case "view_visible": return ++view_visible;
		case "room_caption": return ++room_caption;
		case "view_enabled": return ++view_enabled;
		case "caption_score": return ++caption_score;
		case "caption_lives": return ++caption_lives;
		case "cursor_sprite": return ++cursor_sprite;
		case "caption_health": return ++caption_health;
		case "error_occurred": return ++error_occurred;
		case "view_surface_id": return ++view_surface_id;
		case "room_persistent": return ++room_persistent;
		case "keyboard_string": return ++keyboard_string;
		case "mouse_lastbutton": return ++mouse_lastbutton;
		case "keyboard_lastkey": return ++keyboard_lastkey;
		case "background_color": return ++background_color;
		case "keyboard_lastchar": return ++keyboard_lastchar;
		case "background_colour": return ++background_colour;
		case "font_texture_page_size": return ++font_texture_page_size;
		case "background_showcolor": return ++background_showcolor;
		case "background_showcolour": return ++background_showcolour;
		
		case "self":
		case "other":
		case "all":
		case "noone":
		case "delta_time":
		case "path_index":
		case "room_first":
		case "debug_mode":
		case "event_data":
		case "os_browser":
		case "os_version":
		case "display_aa":
		case "async_load":
		case "instance_id":
		case "current_day":
		case "game_save_id":
		case "current_hour":
		case "event_action":
		case "view_current":
		case "current_time":
		case "current_year":
		case "browser_width":
		case "webgl_enabled":
		case "current_month":
		case "gamemaker_pro":
		case "instance_count":
		case "argument_count":
		case "current_minute":
		case "current_second":
		case "temp_directory":
		case "browser_height":
		case "current_weekday":
		case "cache_directory":
		case "wallpaper_config":
		case "program_directory":
		case "game_project_name":
		case "game_display_name":
		case "argument_relative":
		case "working_directory":
		case "rollback_event_id":
		case "application_surface":
		case "rollback_api_server":
		case "gamemaker_registered":
		case "rollback_event_param":
		case "rollback_game_running":
		case "rollback_current_frame":
		case "rollback_confirmed_frame":
		case "fps":
		case "mouse_x":
		case "managed":
		case "mouse_y":
		case "os_type":
		case "game_id":
		case "iap_data":
		case "fps_real":
		case "room_last":
		case "os_device":
			throw_gmlc_error($"Attempting to write to a read-only variable {key}"+$"\n(line {line}) -\t{lineString}")
	}
}
function __GMLCexecuteUpdatePropertyUniquePlusPlusPostfix() {
    switch (key) {
		case "room": return room++;
		case "lives": return lives++;
		case "score": return score++;
		case "health": return health++;
		case "visible": return visible++;
		case "argument": return parentNode.arguments++;
		case "argument0": return parentNode.arguments[0]++;
		case "argument1": return parentNode.arguments[1]++;
		case "argument2": return parentNode.arguments[2]++;
		case "argument3": return parentNode.arguments[3]++;
		case "argument4": return parentNode.arguments[4]++;
		case "argument5": return parentNode.arguments[5]++;
		case "argument6": return parentNode.arguments[6]++;
		case "argument7": return parentNode.arguments[7]++;
		case "argument8": return parentNode.arguments[8]++;
		case "argument9": return parentNode.arguments[9]++;
		case "argument10": return parentNode.arguments[10]++;
		case "argument11": return parentNode.arguments[11]++;
		case "argument12": return parentNode.arguments[12]++;
		case "argument13": return parentNode.arguments[13]++;
		case "argument14": return parentNode.arguments[14]++;
		case "argument15": return parentNode.arguments[15]++;
		case "show_lives": return show_lives++;
		case "room_width": return room_width++;
		case "view_hport": return view_hport++;
		case "view_xport": return view_xport++;
		case "view_yport": return view_yport++;
		case "view_wport": return view_wport++;
		case "room_speed": return room_speed++;
		case "show_score": return show_score++;
		case "error_last": return error_last++;
		case "view_camera": return view_camera++;
		case "room_height": return room_height++;
		case "show_health": return show_health++;
		case "mouse_button": return mouse_button++;
		case "keyboard_key": return keyboard_key++;
		case "view_visible": return view_visible++;
		case "room_caption": return room_caption++;
		case "view_enabled": return view_enabled++;
		case "caption_score": return caption_score++;
		case "caption_lives": return caption_lives++;
		case "cursor_sprite": return cursor_sprite++;
		case "caption_health": return caption_health++;
		case "error_occurred": return error_occurred++;
		case "view_surface_id": return view_surface_id++;
		case "room_persistent": return room_persistent++;
		case "keyboard_string": return keyboard_string++;
		case "mouse_lastbutton": return mouse_lastbutton++;
		case "keyboard_lastkey": return keyboard_lastkey++;
		case "background_color": return background_color++;
		case "keyboard_lastchar": return keyboard_lastchar++;
		case "background_colour": return background_colour++;
		case "font_texture_page_size": return font_texture_page_size++;
		case "background_showcolor": return background_showcolor++;
		case "background_showcolour": return background_showcolour++;
		
		case "self":
		case "other":
		case "all":
		case "noone":
		case "delta_time":
		case "path_index":
		case "room_first":
		case "debug_mode":
		case "event_data":
		case "os_browser":
		case "os_version":
		case "display_aa":
		case "async_load":
		case "instance_id":
		case "current_day":
		case "game_save_id":
		case "current_hour":
		case "event_action":
		case "view_current":
		case "current_time":
		case "current_year":
		case "browser_width":
		case "webgl_enabled":
		case "current_month":
		case "gamemaker_pro":
		case "instance_count":
		case "argument_count":
		case "current_minute":
		case "current_second":
		case "temp_directory":
		case "browser_height":
		case "current_weekday":
		case "cache_directory":
		case "wallpaper_config":
		case "program_directory":
		case "game_project_name":
		case "game_display_name":
		case "argument_relative":
		case "working_directory":
		case "rollback_event_id":
		case "application_surface":
		case "rollback_api_server":
		case "gamemaker_registered":
		case "rollback_event_param":
		case "rollback_game_running":
		case "rollback_current_frame":
		case "rollback_confirmed_frame":
		case "fps":
		case "mouse_x":
		case "managed":
		case "mouse_y":
		case "os_type":
		case "game_id":
		case "iap_data":
		case "fps_real":
		case "room_last":
		case "os_device":
			throw_gmlc_error($"Attempting to write to a read-only variable {key}"+$"\n(line {line}) -\t{lineString}")
	}
}
function __GMLCexecuteUpdatePropertyUniqueMinusMinusPrefix() {
    switch (key) {
		case "room": return --room;
		case "lives": return --lives;
		case "score": return --score;
		case "health": return --health;
		case "visible": return --visible;
		case "argument": return --parentNode.arguments;
		case "argument0": return --parentNode.arguments[0];
		case "argument1": return --parentNode.arguments[1];
		case "argument2": return --parentNode.arguments[2];
		case "argument3": return --parentNode.arguments[3];
		case "argument4": return --parentNode.arguments[4];
		case "argument5": return --parentNode.arguments[5];
		case "argument6": return --parentNode.arguments[6];
		case "argument7": return --parentNode.arguments[7];
		case "argument8": return --parentNode.arguments[8];
		case "argument9": return --parentNode.arguments[9];
		case "argument10": return --parentNode.arguments[10];
		case "argument11": return --parentNode.arguments[11];
		case "argument12": return --parentNode.arguments[12];
		case "argument13": return --parentNode.arguments[13];
		case "argument14": return --parentNode.arguments[14];
		case "argument15": return --parentNode.arguments[15];
		case "show_lives": return --show_lives;
		case "room_width": return --room_width;
		case "view_hport": return --view_hport;
		case "view_xport": return --view_xport;
		case "view_yport": return --view_yport;
		case "view_wport": return --view_wport;
		case "room_speed": return --room_speed;
		case "show_score": return --show_score;
		case "error_last": return --error_last;
		case "view_camera": return --view_camera;
		case "room_height": return --room_height;
		case "show_health": return --show_health;
		case "mouse_button": return --mouse_button;
		case "keyboard_key": return --keyboard_key;
		case "view_visible": return --view_visible;
		case "room_caption": return --room_caption;
		case "view_enabled": return --view_enabled;
		case "caption_score": return --caption_score;
		case "caption_lives": return --caption_lives;
		case "cursor_sprite": return --cursor_sprite;
		case "caption_health": return --caption_health;
		case "error_occurred": return --error_occurred;
		case "view_surface_id": return --view_surface_id;
		case "room_persistent": return --room_persistent;
		case "keyboard_string": return --keyboard_string;
		case "mouse_lastbutton": return --mouse_lastbutton;
		case "keyboard_lastkey": return --keyboard_lastkey;
		case "background_color": return --background_color;
		case "keyboard_lastchar": return --keyboard_lastchar;
		case "background_colour": return --background_colour;
		case "font_texture_page_size": return --font_texture_page_size;
		case "background_showcolor": return --background_showcolor;
		case "background_showcolour": return --background_showcolour;
		
		case "self":
		case "other":
		case "all":
		case "noone":
		case "delta_time":
		case "path_index":
		case "room_first":
		case "debug_mode":
		case "event_data":
		case "os_browser":
		case "os_version":
		case "display_aa":
		case "async_load":
		case "instance_id":
		case "current_day":
		case "game_save_id":
		case "current_hour":
		case "event_action":
		case "view_current":
		case "current_time":
		case "current_year":
		case "browser_width":
		case "webgl_enabled":
		case "current_month":
		case "gamemaker_pro":
		case "instance_count":
		case "argument_count":
		case "current_minute":
		case "current_second":
		case "temp_directory":
		case "browser_height":
		case "current_weekday":
		case "cache_directory":
		case "wallpaper_config":
		case "program_directory":
		case "game_project_name":
		case "game_display_name":
		case "argument_relative":
		case "working_directory":
		case "rollback_event_id":
		case "application_surface":
		case "rollback_api_server":
		case "gamemaker_registered":
		case "rollback_event_param":
		case "rollback_game_running":
		case "rollback_current_frame":
		case "rollback_confirmed_frame":
		case "fps":
		case "mouse_x":
		case "managed":
		case "mouse_y":
		case "os_type":
		case "game_id":
		case "iap_data":
		case "fps_real":
		case "room_last":
		case "os_device":
			throw_gmlc_error($"Attempting to write to a read-only variable {key}"+$"\n(line {line}) -\t{lineString}")
	}
}
function __GMLCexecuteUpdatePropertyUniqueMinusMinusPostfix() {
    switch (key) {
		case "room": return room--;
		case "lives": return lives--;
		case "score": return score--;
		case "health": return health--;
		case "visible": return visible--;
		case "argument": return parentNode.arguments--;
		case "argument0": return parentNode.arguments[0]--;
		case "argument1": return parentNode.arguments[1]--;
		case "argument2": return parentNode.arguments[2]--;
		case "argument3": return parentNode.arguments[3]--;
		case "argument4": return parentNode.arguments[4]--;
		case "argument5": return parentNode.arguments[5]--;
		case "argument6": return parentNode.arguments[6]--;
		case "argument7": return parentNode.arguments[7]--;
		case "argument8": return parentNode.arguments[8]--;
		case "argument9": return parentNode.arguments[9]--;
		case "argument10": return parentNode.arguments[10]--;
		case "argument11": return parentNode.arguments[11]--;
		case "argument12": return parentNode.arguments[12]--;
		case "argument13": return parentNode.arguments[13]--;
		case "argument14": return parentNode.arguments[14]--;
		case "argument15": return parentNode.arguments[15]--;
		case "show_lives": return show_lives--;
		case "room_width": return room_width--;
		case "view_hport": return view_hport--;
		case "view_xport": return view_xport--;
		case "view_yport": return view_yport--;
		case "view_wport": return view_wport--;
		case "room_speed": return room_speed--;
		case "show_score": return show_score--;
		case "error_last": return error_last--;
		case "view_camera": return view_camera--;
		case "room_height": return room_height--;
		case "show_health": return show_health--;
		case "mouse_button": return mouse_button--;
		case "keyboard_key": return keyboard_key--;
		case "view_visible": return view_visible--;
		case "room_caption": return room_caption--;
		case "view_enabled": return view_enabled--;
		case "caption_score": return caption_score--;
		case "caption_lives": return caption_lives--;
		case "cursor_sprite": return cursor_sprite--;
		case "caption_health": return caption_health--;
		case "error_occurred": return error_occurred--;
		case "view_surface_id": return view_surface_id--;
		case "room_persistent": return room_persistent--;
		case "keyboard_string": return keyboard_string--;
		case "mouse_lastbutton": return mouse_lastbutton--;
		case "keyboard_lastkey": return keyboard_lastkey--;
		case "background_color": return background_color--;
		case "keyboard_lastchar": return keyboard_lastchar--;
		case "background_colour": return background_colour--;
		case "font_texture_page_size": return font_texture_page_size--;
		case "background_showcolor": return background_showcolor--;
		case "background_showcolour": return background_showcolour--;
		
		case "self":
		case "other":
		case "all":
		case "noone":
		case "delta_time":
		case "path_index":
		case "room_first":
		case "debug_mode":
		case "event_data":
		case "os_browser":
		case "os_version":
		case "display_aa":
		case "async_load":
		case "instance_id":
		case "current_day":
		case "game_save_id":
		case "current_hour":
		case "event_action":
		case "view_current":
		case "current_time":
		case "current_year":
		case "browser_width":
		case "webgl_enabled":
		case "current_month":
		case "gamemaker_pro":
		case "instance_count":
		case "argument_count":
		case "current_minute":
		case "current_second":
		case "temp_directory":
		case "browser_height":
		case "current_weekday":
		case "cache_directory":
		case "wallpaper_config":
		case "program_directory":
		case "game_project_name":
		case "game_display_name":
		case "argument_relative":
		case "working_directory":
		case "rollback_event_id":
		case "application_surface":
		case "rollback_api_server":
		case "gamemaker_registered":
		case "rollback_event_param":
		case "rollback_game_running":
		case "rollback_current_frame":
		case "rollback_confirmed_frame":
		case "fps":
		case "mouse_x":
		case "managed":
		case "mouse_y":
		case "os_type":
		case "game_id":
		case "iap_data":
		case "fps_real":
		case "room_last":
		case "os_device":
			throw_gmlc_error($"Attempting to write to a read-only variable {key}"+$"\n(line {line}) -\t{lineString}")
	}
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
	//	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n(line {self.line}) -\t{self.lineString}\n{json(callstack)}")
	//}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return ++_static[$ key];
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n(line {self.line}) -\t{self.lineString}\n{json(callstack)}")
	
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
	//	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n(line {self.line}) -\t{self.lineString}\n{json(callstack)}")
	//}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return _static[$ key]++;
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n(line {self.line}) -\t{self.lineString}\n{json(callstack)}")
	
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
	//	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n(line {self.line}) -\t{self.lineString}\n{json(callstack)}")
	//}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return --_static[$ key];
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n(line {self.line}) -\t{self.lineString}\n{json(callstack)}")
	
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
	//	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n(line {self.line}) -\t{self.lineString}\n{json(callstack)}")
	//}
	
	var _static = __gmlc_static_get(_target)
	
	//check each static parent
	while (_static != undefined) {
		if struct_exists(_static, key) {
			return _static[$ key]--;
		}
		_static = __gmlc_static_get(_static)
	}
	
	throw_gmlc_error($"Variable <{typeof(_target)}>.{key} not set before reading it."+$"\n(line {self.line}) -\t{self.lineString}\n{json(callstack)}")
	
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
    if (_scope == ScopeType.LOCAL) {
		_output.locals = _parentNode.locals;
		_output.localsWrittenTo = _parentNode.localsWrittenTo;
		_output.localIndex = _parentNode.localLookUps[$ _output.key];
	}
	else if (_scope == ScopeType.GLOBAL) {
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

