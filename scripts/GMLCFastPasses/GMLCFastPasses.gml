#region Scope Getters/Setters
#region Get Property
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetPropertySelf() {
    return global.selfInstance[$ key];
}
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetPropertyOther() {
    return global.otherInstance[$ key];
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
    switch (key) {
		case "self": return global.selfInstance;
		case "other": return global.otherInstance;
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
    global.selfInstance[$ key] = expression()
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetPropertyOther() {
    global.otherInstance[$ key] = expression()
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
#endregion

#region Scope Updatters (++ and --)
#region Self
function __GMLCexecuteUpdatePropertySelfPlusPlusPrefix() {
    return ++global.selfInstance[$ key];
}
function __GMLCexecuteUpdatePropertySelfPlusPlusPostfix() {
	return global.selfInstance[$ key]++;
}
function __GMLCexecuteUpdatePropertySelfMinusMinusPrefix() {
    return --global.selfInstance[$ key];
}
function __GMLCexecuteUpdatePropertySelfMinusMinusPostfix() {
    return global.selfInstance[$ key]--;
}
#endregion
#region Other
function __GMLCexecuteUpdatePropertyOtherPlusPlusPrefix() {
    return ++global.otherInstance[$ key];
}
function __GMLCexecuteUpdatePropertyOtherPlusPlusPostfix() {
    return global.otherInstance[$ key]++;
}
function __GMLCexecuteUpdatePropertyOtherMinusMinusPrefix() {
    return --global.otherInstance[$ key];
}
function __GMLCexecuteUpdatePropertyOtherMinusMinusPostfix() {
    return global.otherInstance[$ key]--;
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
#endregion

#region Call Expressions

#endregion