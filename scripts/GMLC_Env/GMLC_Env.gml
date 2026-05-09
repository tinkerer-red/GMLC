#region jsDoc
/// @func	GMLC_Env()
/// @desc	Constructs a new GMLC compiler/evaluator environment. Sets up keyword/operator/variable exposure, wires the full pipeline
///			(tokenizer -> preprocessor -> parser -> post-processor -> optional optimizer -> compiler),
///			and provides methods to configure exposure tiers and compile source text.
/// @returns {Struct.GMLC_Env}
#endregion
function GMLC_Env() : __EnvironmentClass() constructor {
	
	should_optimize = false;
	
	#region Init
	
	#region Expose Keywords
	var _keyword_map = {
		"globalvar": true,
		"var": true,
		"if": true,
		"then": true,
		"else": true,
		"begin": true,
		"end": true,
		"for": true,
		"while": true,
		"do": true,
		"until": true,
		"repeat": true,
		"switch": true,
		"case": true,
		"default": true,
		"break": true,
		"continue": true,
		"with": true,
		"exit": true,
		"return": true,
		"mod": true,
		"div": true,
		"not": true,
		"and": true,
		"or": true,
		"xor": true,
		"enum": true,
		"function": true,
		"new": true,
		"constructor": true,
		"static": true,
		//"#region": true,
		//"#endregion": true,
		"macro": true,
		"try": true,
		"catch": true,
		"finally": true,
		"throw": true,
		"delete": true,
		"_GMLINE_": true,
		"_GMFUNCTION_": true,
	};
	_keyword_map[$ "#region"] = true;
	_keyword_map[$ "#endregion"] = true;
	
	exposeKeywords(_keyword_map);
	#endregion
	#region Expose Operators
	var _op_map = {};
	_op_map[$ "!"] = true;
	_op_map[$ "!="] = true;
	_op_map[$ "#"] = true;
	_op_map[$ "$"] = true;
	_op_map[$ "%"] = true;
	_op_map[$ "%="] = true;
	_op_map[$ "&"] = true;
	_op_map[$ "&&"] = true;
	_op_map[$ "&="] = true;
	_op_map[$ "*"] = true;
	_op_map[$ "*="] = true;
	_op_map[$ "+"] = true;
	_op_map[$ "+="] = true;
	_op_map[$ "++"] = true;
	_op_map[$ "-"] = true;
	_op_map[$ "-="] = true;
	_op_map[$ "--"] = true;
	_op_map[$ "/"] = true;
	_op_map[$ "<"] = true;
	_op_map[$ "<>"] = true;
	_op_map[$ "!="] = true;
	_op_map[$ "<="] = true;
	_op_map[$ "<<"] = true;
	_op_map[$ "="] = true;
	_op_map[$ ">"] = true;
	_op_map[$ "?"] = true;
	_op_map[$ "??"] = true;
	_op_map[$ "??="] = true;
	_op_map[$ "@"] = true;
	_op_map[$ "^"] = true;
	_op_map[$ "^^"] = true;
	_op_map[$ "^="] = true;
	_op_map[$ "~"] = true;
	_op_map[$ "|"] = true;
	_op_map[$ "||"] = true;
	_op_map[$ "|="] = true;
	exposeOperators(_op_map)
	#endregion
	#region Expose Functions
	//exposeFunctions(_func_map);
	#endregion
	#region Expose Variables
	var _var_map = {
		"visible":{
			get: function(){ with (global.gmlc_self_instance) return visible; },
			set: function(value){ with (global.gmlc_self_instance) visible = value; },
		},
		"managed":{
			get: function(){ with (global.gmlc_self_instance) return managed; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable managed", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"path_index":{
			get: function(){ with (global.gmlc_self_instance) return path_index; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable path_index", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"async_load":{
			get: function(){ return async_load; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable async_load", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"event_data":{
			get: function(){ return event_data; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable event_data", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"iap_data":{
			get: function(){ return iap_data; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable iap_data", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"display_aa":{
			get: function(){ return display_aa; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable display_aa", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"delta_time":{
			get: function(){ return delta_time; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable delta_time", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"webgl_enabled":{
			get: function(){ return webgl_enabled; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable webgl_enabled", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		//"argument_relative":{
		//	get: function(){ return argument_relative; },
		//	set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable argument_relative", struct_get(self, "line"), struct_get(self, "lineString")) },
		//},
		"argument":{
			get: method(undefined, function(){ return parentNode.arguments; }),
			set: method(undefined, function(value){ parentNode.arguments = value; }),
		},
		"argument0":{
			get: method(undefined, function(){ return parentNode.arguments[0]; }),
			set: method(undefined, function(value){ parentNode.arguments[0] = value; }),
		},
		"argument1":{
			get: method(undefined, function(){ return parentNode.arguments[1]; }),
			set: method(undefined, function(value){ parentNode.arguments[1] = value; }),
		},
		"argument2":{
			get: method(undefined, function(){ return parentNode.arguments[0]; }),
			set: method(undefined, function(value){ parentNode.arguments[0] = value; }),
		},
		"argument3":{
			get: method(undefined, function(){ return parentNode.arguments[3]; }),
			set: method(undefined, function(value){ parentNode.arguments[3] = value; }),
		},
		"argument4":{
			get: method(undefined, function(){ return parentNode.arguments[4]; }),
			set: method(undefined, function(value){ parentNode.arguments[4] = value; }),
		},
		"argument5":{
			get: method(undefined, function(){ return parentNode.arguments[5]; }),
			set: method(undefined, function(value){ parentNode.arguments[5] = value; }),
		},
		"argument6":{
			get: method(undefined, function(){ return parentNode.arguments[6]; }),
			set: method(undefined, function(value){ parentNode.arguments[6] = value; }),
		},
		"argument7":{
			get: method(undefined, function(){ return parentNode.arguments[7]; }),
			set: method(undefined, function(value){ parentNode.arguments[7] = value; }),
		},
		"argument8":{
			get: method(undefined, function(){ return parentNode.arguments[8]; }),
			set: method(undefined, function(value){ parentNode.arguments[8] = value; }),
		},
		"argument9":{
			get: method(undefined, function(){ return parentNode.arguments[9]; }),
			set: method(undefined, function(value){ parentNode.arguments[9] = value; }),
		},
		"argument10":{
			get: method(undefined, function(){ return parentNode.arguments[10]; }),
			set: method(undefined, function(value){ parentNode.arguments[10] = value; }),
		},
		"argument11":{
			get: method(undefined, function(){ return parentNode.arguments[11]; }),
			set: method(undefined, function(value){ parentNode.arguments[11] = value; }),
		},
		"argument12":{
			get: method(undefined, function(){ return parentNode.arguments[12]; }),
			set: method(undefined, function(value){ parentNode.arguments[12] = value; }),
		},
		"argument13":{
			get: method(undefined, function(){ return parentNode.arguments[13]; }),
			set: method(undefined, function(value){ parentNode.arguments[13] = value; }),
		},
		"argument14":{
			get: method(undefined, function(){ return parentNode.arguments[14]; }),
			set: method(undefined, function(value){ parentNode.arguments[14] = value; }),
		},
		"argument15":{
			get: method(undefined, function(){ return parentNode.arguments[15]; }),
			set: method(undefined, function(value){ parentNode.arguments[15] = value; }),
		},
		"argument_count":{
			get: method(undefined, function(){ return array_length(parentNode.arguments); }),
			set: method(undefined, function(value){ throw_gmlc_error($"Attempting to write to a read-only variable argument_count", struct_get(self, "line"), struct_get(self, "lineString")) }),
		},
		"debug_mode":{
			get: function(){ return debug_mode; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable debug_mode", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"room":{
			get: function(){ return room; },
			set: function(value){ room = value; },
		},
		"room_first":{
			get: function(){ return room_first; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable room_first", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"room_last":{
			get: function(){ return room_last; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable room_last", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"score":{
			get: function(){ return score; },
			set: function(value){ score = value; },
		},
		"lives":{
			get: function(){ return lives; },
			set: function(value){ lives = value; },
		},
		"health":{
			get: function(){ return health; },
			set: function(value){ health = value; },
		},
		"game_id":{
			get: function(){ return game_id; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable game_id", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"game_display_name":{
			get: function(){ return game_display_name; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable game_display_name", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"game_project_name":{
			get: function(){ return game_project_name; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable game_project_name", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"game_save_id":{
			get: function(){ return game_save_id; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable game_save_id", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"working_directory":{
			get: function(){ return working_directory; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable working_directory", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"temp_directory":{
			get: function(){ return temp_directory; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable temp_directory", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"cache_directory":{
			get: function(){ return cache_directory; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable cache_directory", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"program_directory":{
			get: function(){ return program_directory; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable program_directory", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"instance_count":{
			get: function(){ with (global.gmlc_self_instance) return instance_count; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable instance_count", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"instance_id":{
			get: function(){ with (global.gmlc_self_instance) return instance_id; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable instance_id", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"room_width":{
			get: function(){ return room_width; },
			set: function(value){ room_width = value; },
		},
		"room_height":{
			get: function(){ return room_height; },
			set: function(value){ room_height = value; },
		},
		"room_caption":{
			get: function(){ return room_caption; },
			set: function(value){ room_caption = value; },
		},
		"room_speed":{
			get: function(){ return room_speed; },
			set: function(value){ room_speed = value; },
		},
		"room_persistent":{
			get: function(){ return room_persistent; },
			set: function(value){ room_persistent = value; },
		},
		"view_enabled":{
			get: function(){ return view_enabled; },
			set: function(value){ view_enabled = value; },
		},
		"view_current":{
			get: function(){ return view_current; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable view_current", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"view_visible":{
			get: function(){ return view_visible; },
			set: function(value){ view_visible = value; },
		},
		"view_xport":{
			get: function(){ return view_xport; },
			set: function(value){ view_xport = value; },
		},
		"view_yport":{
			get: function(){ return view_yport; },
			set: function(value){ view_yport = value; },
		},
		"view_wport":{
			get: function(){ return view_wport; },
			set: function(value){ view_wport = value; },
		},
		"view_hport":{
			get: function(){ return view_hport; },
			set: function(value){ view_hport = value; },
		},
		"view_surface_id":{
			get: function(){ return view_surface_id; },
			set: function(value){ view_surface_id = value; },
		},
		"view_camera":{
			get: function(){ return view_camera; },
			set: function(value){ view_camera = value; },
		},
		"mouse_x":{
			get: function(){ return mouse_x; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable mouse_x", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"mouse_y":{
			get: function(){ return mouse_y; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable mouse_y", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"mouse_button":{
			get: function(){ return mouse_button; },
			set: function(value){ mouse_button = value; },
		},
		"mouse_lastbutton":{
			get: function(){ return mouse_lastbutton; },
			set: function(value){ mouse_lastbutton = value; },
		},
		"keyboard_key":{
			get: function(){ return keyboard_key; },
			set: function(value){ keyboard_key = value; },
		},
		"keyboard_lastkey":{
			get: function(){ return keyboard_lastkey; },
			set: function(value){ keyboard_lastkey = value; },
		},
		"keyboard_lastchar":{
			get: function(){ return keyboard_lastchar; },
			set: function(value){ keyboard_lastchar = value; },
		},
		"keyboard_string":{
			get: function(){ return keyboard_string; },
			set: function(value){ keyboard_string = value; },
		},
		"cursor_sprite":{
			get: function(){ return cursor_sprite; },
			set: function(value){ cursor_sprite = value; },
		},
		"show_score":{
			get: function(){ return show_score; },
			set: function(value){ show_score = value; },
		},
		"show_lives":{
			get: function(){ return show_lives; },
			set: function(value){ show_lives = value; },
		},
		"show_health":{
			get: function(){ return show_health; },
			set: function(value){ show_health = value; },
		},
		"caption_score":{
			get: function(){ return caption_score; },
			set: function(value){ caption_score = value; },
		},
		"caption_lives":{
			get: function(){ return caption_lives; },
			set: function(value){ caption_lives = value; },
		},
		"caption_health":{
			get: function(){ return caption_health; },
			set: function(value){ caption_health = value; },
		},
		"fps":{
			get: function(){ return fps; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable fps", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"fps_real":{
			get: function(){ return fps_real; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable fps_real", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"current_time":{
			get: function(){ return current_time; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_time", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"current_year":{
			get: function(){ return current_year; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_year", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"current_month":{
			get: function(){ return current_month; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_month", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"current_day":{
			get: function(){ return current_day; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_day", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"current_weekday":{
			get: function(){ return current_weekday; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_weekday", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"current_hour":{
			get: function(){ return current_hour; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_time", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"current_minute":{
			get: function(){ return current_minute; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_minute", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"current_second":{
			get: function(){ return current_second; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_second", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"event_action":{
			get: function(){ return event_action; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable event_action", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"error_occurred":{
			get: function(){ return error_occurred; },
			set: function(value){ error_occurred = value; },
		},
		"error_last":{
			get: function(){ return error_last; },
			set: function(value){ error_last = value; },
		},
		"gamemaker_registered":{
			get: function(){ return gamemaker_registered; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable gamemaker_registered", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"gamemaker_pro":{
			get: function(){ return gamemaker_pro; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable gamemaker_pro", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"application_surface":{
			get: function(){ return application_surface; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable application_surface", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"font_texture_page_size":{
			get: function(){ return font_texture_page_size; },
			set: function(value){ font_texture_page_size = value; },
		},
		"os_type":{
			get: function(){ return os_type; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable os_type", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"os_device":{
			get: function(){ return os_device; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable os_device", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"os_version":{
			get: function(){ return os_version; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable os_version", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"os_browser":{
			get: function(){ return os_browser; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable os_browser", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"browser_width":{
			get: function(){ return browser_width; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable bwoser_width", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"browser_height":{
			get: function(){ return browser_height; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable browser_height", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"rollback_current_frame":{
			get: function(){ return rollback_current_frame; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable rollback_current_frame", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"rollback_confirmed_frame":{
			get: function(){ return rollback_confirmed_frame; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable rollback_confirmed_frame", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"rollback_event_id":{
			get: function(){ return rollback_event_id; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable rollback_event_id", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"rollback_event_param":{
			get: function(){ return rollback_event_param; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable rollback_event_param", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"rollback_game_running":{
			get: function(){ return rollback_game_running; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable rollback_game_running", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"rollback_api_server":{
			get: function(){ return rollback_api_server; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable rollback_api_server", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"wallpaper_config":{
			get: function(){ return wallpaper_config; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable wallpaper_config", struct_get(self, "line"), struct_get(self, "lineString")) },
		},
		"background_showcolor":{
			get: function(){ return background_showcolor; },
			set: function(value){ background_showcolor = value; },
		},
		"background_color":{
			get: function(){ return background_color; },
			set: function(value){ background_color = value; },
		},
		"background_colour":{
			get: function(){ return background_colour; },
			set: function(value){ background_colour = value; },
		},
		"background_showcolour":{
			get: function(){ return background_showcolour; },
			set: function(value){ background_showcolour = value; },
		},
		
	}
	_var_map[$ "self"] = {
		get: function(){ return global.gmlc_self_instance; },
		set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable self", struct_get(self, "line"), struct_get(self, "lineString")) },
	};
	_var_map[$ "other"] = {
		get: function(){ return global.gmlc_other_instance; },
		set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable other", struct_get(self, "line"), struct_get(self, "lineString")) },
	};
	
	exposeVariables(_var_map);
	#endregion
	
	tokenizer      = new GMLC_Gen_0_Tokenizer(self);
	pre_processor  = new GMLC_Gen_1_PreProcessor(self);
	parser         = new GMLC_Gen_2_Parser(self);
	post_processor = new GMLC_Gen_3_PostProcessor(self);
	optimizer      = new GMLC_Gen_4_Optimizer(self);
	compiler       = new GMLC_Gen_5_Compiler(self);
	
	set_exposure(GMLC_EXPOSURE.SAFE);
	
	#endregion
	
	#region Public
	
	#region jsDoc
	/// @func    compile()
	/// @desc    Runs the complete compilation pipeline on the given source text.
	/// @self    GMLC_Env
	/// @param   {String} sourceCode : Source text to compile
	/// @returns {Any} Compiled program artifact produced by GMLC_Gen_5_Compiler
	#endregion
	static compile = function(_sourceCode, _name = "") {
		currentScriptName = _name;
		//append the macros to the end of the source code.
		_sourceCode = __appendMacros(_sourceCode);
		
		var _time = get_timer();
		var _step_time = _time;
		
		tokenizer.initialize(_sourceCode);
		var tokens = tokenizer.parseAll();
		if (__log_tokenizer_results) json_save("tokenizer.json", tokens)
		if (__log_step_times) {
			show_debug_message($"Tokenizer Time took : {(get_timer() - _step_time)/1000}ms")
			_step_time = get_timer();
		}
		
		pre_processor.initialize(tokens);
		var preprocessedTokens = pre_processor.parseAll();
		if (__log_pre_processer_results) json_save("pre_processor.json", preprocessedTokens)
		if (__log_step_times) {
			show_debug_message($"Pre Processor Time took : {(get_timer() - _step_time)/1000}ms")
			_step_time = get_timer();
		}
		
		parser.initialize(preprocessedTokens);
		var ast = parser.parseAll();
		if (__log_parser_results) json_save("parser.json", ast)
		if (__log_step_times) {
			show_debug_message($"Parser Time took : {(get_timer() - _step_time)/1000}ms")
			_step_time = get_timer();
		}
		
		post_processor.initialize(ast);
		var ast = post_processor.parseAll();
		if (__log_post_processer_results) json_save("post_processor.json", ast)
		if (__log_step_times) {
			show_debug_message($"Post Processor Time took : {(get_timer() - _step_time)/1000}ms")
			_step_time = get_timer();
		}
		
		if (should_optimize) {
			optimizer.initialize(ast);
			var ast = optimizer.parseAll();
			if (__log_optimizer_results) json_save("optimizer.json", ast)
		}
		
		var _global = getConstant("global");
		var _globals = (is_struct(_global)) ? _global.value : {};
		compiler.initialize(ast, _globals);
		var program = compiler.parseAll();
		if (__log_compiler_results) json_save("post_processor.json", ast)
		if (__log_step_times) {
			show_debug_message($"Compile Time took : {(get_timer() - _step_time)/1000}ms")
			_step_time = get_timer();
		}
		
		
		return program;
	}
	
	#region jsDoc
	/// @func    get()
	/// @desc    Fetch a function from the global struct
	/// @self    GMLC_Env
	/// @param   {String} func : The name of the function to get from the global struct
	/// @returns {Any} Compiled function artifact produced by GMLC_Gen_5_Compiler
	#endregion
	static get = function(_func) {
		var _globals = getConstant("global").value;
		
		return struct_get(_globals, _func);
	}
	
	#region jsDoc
	/// @func    enable_optimizer()
	/// @desc    Enables or disables the optimizer pass between post-processing and compilation.
	/// @self    GMLC_Env
	/// @param   {Bool} shouldEnable : True to enable optimizer, false to disable
	/// @returns {Struct.GMLC_Env}
	#endregion
	static enable_optimizer = function(_bool) {
		should_optimize = _bool;
		return self;
	}
	
	#region jsDoc
	/// @func    set_exposure()
	/// @desc    Convenience method that applies the selected exposure tier by invoking expose_constants(), expose_user_assets(), and expose_functions() accordingly.
	/// @self    GMLC_Env
	/// @param   {GMLC_EXPOSURE} exposureLevel : Exposure tier (NONE, SAFE, MODERATE, ALL, FULL, NATIVE)
	/// @returns {Struct.GMLC_Env}
	#endregion
	static set_exposure = function(_expose_level=GMLC_EXPOSURE.SAFE) {
		expose_constants(_expose_level);
		expose_user_assets(_expose_level);
		expose_functions(_expose_level);
		
		return self;
	}
	
	#region Specific Exposures
	
	#region jsDoc
	/// @func    expose_constants()
	/// @desc    Exposes core engine constants from the spec and selected build metadata. When exposureLevel is FULL, also exposes the real global object as a constant named "global"; otherwise exposes an empty struct.
	/// @self    GMLC_Env
	/// @param   {GMLC_EXPOSURE} exposureLevel : Exposure tier used
	/// @returns {Struct.GMLC_Env}
	#endregion
	static expose_constants = function(_expose_level=GMLC_EXPOSURE.SAFE) {
		var _spec = __GmlSpec();
		var _map = struct_filter(_spec, function(_key, _val) {
			return _val[$ "type"] == "envConstants";
		});
		importSymbolMap(_map);
		
		exposeConstants({
			"all": all,
			"noone": noone,
			"GM_build_date": GM_build_date,
			"GM_build_type": GM_build_type,
			"GM_version": GM_version,
			"GM_runtime_version": GM_runtime_version,
			"GM_project_filename": GM_project_filename,
			"GM_is_sandboxed": GM_is_sandboxed,
		});
		//expose globl depending on exposure level
		exposeConstants({
			"global": (_expose_level == GMLC_EXPOSURE.FULL) ? global : {},
		});
		//expose enums
		exposeEnums(__ExistingEnums());
		
		return self;
	}
	#region jsDoc
	/// @func    expose_user_assets()
	/// @desc    Exposes all user assets by name as read-only constants mapping to their asset IDs. Skips exposure when exposureLevel is below SAFE or equals NATIVE.
	/// @self    GMLC_Env
	/// @param   {GMLC_EXPOSURE} exposureLevel : Exposure tier controlling whether assets are exposed
	/// @returns {Struct.GMLC_Env}
	#endregion
	static expose_user_assets = function(_expose_level=GMLC_EXPOSURE.SAFE) {
		if (_expose_level < GMLC_EXPOSURE.SAFE) 
		|| (_expose_level == GMLC_EXPOSURE.NATIVE) {
			return;
		}
		
		var _arr_obje = asset_get_ids(asset_object),        
		var _arr_spri = asset_get_ids(asset_sprite),
		var _arr_soun = asset_get_ids(asset_sound),
		var _arr_room = asset_get_ids(asset_room),
		var _arr_tile = asset_get_ids(asset_tiles),
		var _arr_path = asset_get_ids(asset_path),
		var _arr_font = asset_get_ids(asset_font),
		var _arr_time = asset_get_ids(asset_timeline),
		var _arr_shad = asset_get_ids(asset_shader),
		var _arr_anim = asset_get_ids(asset_animationcurve),
		var _arr_sequ = asset_get_ids(asset_sequence),
		var _arr_part = asset_get_ids(asset_particlesystem)
		
		//var _test_arr = [];
		//var _i=0; repeat(array_length(_arr_shad)) {
		//	var _asset = _arr_shad[_i];
		//	var _name = shader_get_name(_asset);
		//	_test_arr[_i] = _name;
		//_i++};
		
		var _arr = array_concat(
			_arr_obje,	_arr_spri,	_arr_soun,
			_arr_room,	_arr_tile,	_arr_path,
			_arr_font,	_arr_time,	_arr_shad,
			_arr_anim,	_arr_sequ,	_arr_part
		)
		
		var _cont_map = {};
		var _i=0; repeat(array_length(_arr)) {
			var _asset = _arr[_i];
			var _name = asset_get_name(_asset);
		
			_cont_map[$ _name] = _asset;
		_i++};
		exposeConstants(_cont_map);
		return self;
	}
	#region jsDoc
	/// @func    expose_functions()
	/// @desc    Exposes functions according to the selected exposure tier:
	///          - NONE: no functions
	///          - SAFE: pure built-ins that pass safety filter, plus overwrite shims
	///          - MODERATE: currently same as SAFE (pending spec/policy expansion), plus overwrite shims
	///          - ALL: all native built-ins, plus overwrite shims
	///          - FULL: all native built-ins, user scripts, plus overwrite shims
	/// @self    GMLC_Env
	/// @param   {GMLC_EXPOSURE} exposureLevel : Exposure tier controlling function availability
	/// @returns {Struct.GMLC_Env}
	#endregion
	static expose_functions = function(_expose_level = GMLC_EXPOSURE.SAFE) {
		switch (_expose_level) {
			case GMLC_EXPOSURE.NONE: break;
			case GMLC_EXPOSURE.SAFE:
				expose_pure_functions();
				expose_overwrite_functions();
			break;
			case GMLC_EXPOSURE.MODERATE:
				expose_safe_functions();
				expose_overwrite_functions();
			break;
			case GMLC_EXPOSURE.ALL:
				expose_native_functions();
				expose_overwrite_functions();
			break;
			case GMLC_EXPOSURE.FULL:
				expose_native_functions(); // Includes all built-in functions
				expose_overwrite_functions();
				expose_user_functions();   // And also user scripts
			break;
		}
		return self;
	};
	
	#region jsDoc
	/// @func    expose_pure_functions()
	/// @desc    Exposes only built-in functions marked pure in the spec and passing the safety filter. Intended for SAFE-tier sandboxes.
	/// @self    GMLC_Env
	/// @returns {Struct.GMLC_Env}
	#endregion
	static expose_pure_functions = function() {
		var _spec = __GmlSpec();
		var _map = struct_filter(_spec, function(_key, _val) {
			return (_val[$ "type"] == "envFunctions")
				&& (!_val[$ "feather"][$ "pure"])
				&& __is_safe_function(_key, _val);
		});
		
		//var _arr = struct_get_names(_map)
		//array_sort(_arr, true)
		//pprint(_arr)
		
		importSymbolMap(_map);
		
		return self;
	}
	#region jsDoc
	/// @func    expose_safe_functions()
	/// @desc    Exposes a vetted set of built-in functions for moderate trust contexts. As currently implemented, this filters to spec-marked pure functions that pass the safety filter.
	/// @self    GMLC_Env
	/// @returns {Struct.GMLC_Env}
	#endregion
	static expose_safe_functions = function() {
		var _spec = __GmlSpec();
		
		var _map = struct_filter(_spec, function(_key, _val) {
			if (!__is_safe_function(_key, _val)) return false;
			return _val[$ "feather"][$ "pure"]; // Only allow pure built-ins
		});
		
		//var _arr = struct_get_names(_map)
		//array_sort(_arr, true)
		//pprint(_arr)
		
		importSymbolMap(_map);
		
		return self;
	};
	#region jsDoc
	/// @func    expose_overwrite_functions()
	/// @desc    Installs GMLC shims that replace native behaviors for reflection and script dispatch:
	///          method, typeof, instanceof, is_instanceof, static_get, static_set,
	///          method_get_index, method_get_self, script_get_name, script_execute, script_execute_ext.
	///          These route through the sandbox for control and auditing.
	/// @self    GMLC_Env
	/// @returns {Struct.GMLC_Env}
	#endregion
	static expose_overwrite_functions = function(){
		//This will overwrite the existing functions.
		var _env = self;
		exposeFunctions({
			"method":             __gmlc_method,
			"typeof":             __gmlc_typeof,
			"instanceof":         __gmlc_instanceof,
			"is_instanceof":      __gmlc_is_instanceof,
			"static_get":         __gmlc_static_get,
			"static_set":         __gmlc_static_set,
			"method_get_index":   __gmlc_method_get_index,
			"method_get_self":    __gmlc_method_get_self,
			"script_get_name":    __gmlc_script_get_name,
			"script_execute":     __gmlc_script_execute,
			"script_execute_ext": __gmlc_script_execute_ext,
			"variable_global_exists" : __vanilla_method(_env, __gmlc_variable_global_exists),
			"variable_global_get" : __vanilla_method(_env, __gmlc_variable_global_get),
			"variable_global_set" : __vanilla_method(_env, __gmlc_variable_global_set),
		})
		return self;
	}
	#region jsDoc
	/// @func    expose_native_functions()
	/// @desc    Exposes all built-in engine functions described in the spec, without purity or safety filtering. Use in ALL or FULL tiers.
	/// @self    GMLC_Env
	/// @returns {Struct.GMLC_Env}
	#endregion
	static expose_native_functions = function() {
		var _spec = __GmlSpec();
		var _map = struct_filter(_spec, function(_key, _val) {
			return (_val[$ "type"] == "envFunctions");
		});
		importSymbolMap(_map);
		return self;
	}
	#region jsDoc
	/// @func    expose_user_functions()
	/// @desc    Exposes all user scripts by name, mapping each script name to its script asset ID. Use in FULL tier or when explicitly desired.
	/// @self    GMLC_Env
	/// @returns {Struct.GMLC_Env}
	#endregion
	static expose_user_functions = function() {
		var _scripts = asset_get_ids(asset_script);
		var _func_map = {};
		var _i=0; repeat(array_length(_scripts)) {
			var _func = _scripts[_i];
			var _name = script_get_name(_func);
			_func_map[$ _name] = _func;
		_i++};
		exposeFunctions(_func_map);
		return self;
	}
	
	#endregion
	
	#endregion
	
	#region Private
	//used to print the outputs for debugging
	currentScriptName = "";

	__log_path = "log.json"
	__log_tokenizer_results      = true;
	__log_pre_processer_results  = true;
	__log_parser_results         = true;
	__log_post_processer_results = true;
	__log_optimizer_results      = true;
	__log_compiler_results       = false;
	
	__log_step_times = true;
	
	__keyword_lookup  = undefined;
	__function_lookup = undefined;
	__constant_lookup = undefined;
	__variable_lookup = undefined;
	
	#region jsDoc
	/// @func    __is_safe_function()
	/// @desc    Internal predicate that returns true when a spec entry represents a built-in function permitted in SAFE-like tiers. Rejects disallowed names and names containing banned substrings.
	/// @self    GMLC_Env
	/// @param   {String} funcName : Candidate function name
	/// @param   {Struct} specEntry : Corresponding spec entry (must have type and feather fields as expected)
	/// @returns {Bool}
	/// @ignore
	#endregion
	static __is_safe_function = function(_key, _val) {
		if (_val[$ "type"] != "envFunctions") return false;
		
		static bannedFunctions = [
			"game_restart", "game_end", "environment_get_variable", "room_restart", "room_goto",
			"room_goto_next", "room_goto_previous", "room_add", "room_assign", "room_instance_add",
			"room_duplicate", "room_instance_clear", "method", "method_get_index", "method_get_self",
			"os_get_info", "asset_get_index", "asset_get_ids", "event_perform_async", "static_set",
			"static_get", "gc_enable", "wallpaper_set_config", "wallpaper_set_subscriptions",
			"parameter_string", "parameter_count", "buffer_load",  "buffer_save", "buffer_save_async", 
			"buffer_load_async",
		];
		
		static bannedFunctionCharacters = [
			"@@", "$", "anon", "<unknown>", "rollback",
			"xbox", "psn", "switch", "uwp", "win8", "ps4", "ps5",
			"gxc", "external_", "matchmaking", "file_", "ini_",
			"winphone", "ERROR", "testFailed", "achievement", "extension",
			"ms_iap", "analytics"
		];
		
		if (array_contains(bannedFunctions, _key)) return false;
		
		var _length = array_length(bannedFunctionCharacters);
		for (var i = 0; i < _length; i++) {
			if (string_pos(bannedFunctionCharacters[i], _key) > 0) {
				return false;
			}
		}
		
		return true;
	}
	
	#region jsDoc
	/// @func    __appendMacros()
	/// @desc    Appends exposed macros on new lines at the bottom of the source code provided.
	/// @self    GMLC_Env
	/// @param   {String} sourceCode : Source code to append exposed macros to.
	/// @returns {String}
	/// @ignore
	#endregion
	static __appendMacros = function(_sourceCode) {
		//tokenize exposed macros
		var _exposed_macro_str = "\n// Start of appended macros which were exposed\n\n";
		var _macros = getAllMacros();
		var _names = struct_get_names(_macros);
		var _i=0; repeat(array_length(_names)) {
			var _name = _names[_i];
			var _macro_struct = _macros[$ _name];
			_exposed_macro_str += $"#macro {_name} {_macro_struct.value}\n";
		_i++;}
		
		return _sourceCode + _exposed_macro_str;
	}
	
	#endregion

	#region Batch & Project Compilation

	#region jsDoc
	/// @func    __inject_batch_context()
	/// @desc    Merges batch-level macros and enums into a program without overwriting
	///          locally-defined symbols.
	/// @ignore
	#endregion
	/// @func    __cross_expand_macro_bodies()
	/// @desc    Expands macro-referencing tokens within each macro body in the global pool so
	///          that macro A = macro_B and macro_B = 5 results in A's body being [5] before
	///          any file compilation begins. Mutates the body arrays in place.
	/// @ignore
	static __cross_expand_macro_bodies = function(_globalMacros, _globalMacroNames) {
		var _hasChanged = true;
		var _loop_count = 0;
		while (_hasChanged) {
			_hasChanged = false;
			var _i = 0; repeat(array_length(_globalMacroNames)) {
				var _name = _globalMacroNames[_i];
				var _body = _globalMacros[$ _name];
				var _j = 0;
				while (_j < array_length(_body)) {
					var _token = _body[_j];
					if ((_token.type == __GMLC_TokenType_Identifier)
					&&  (_token.name != _name)
					&&  (variable_struct_exists(_globalMacros, _token.name))) {
						var _expansion = _globalMacros[$ _token.name];
						array_delete(_body, _j, 1);
						var _elen = array_length(_expansion);
						var _k = _elen - 1;
						repeat(_elen) {
							array_insert(_body, _j, _expansion[_k]);
						_k--;}
						_hasChanged = true;
					}
					else {
						_j++;
					}
				}
			_i++;}
			if (++_loop_count > 10000) {
				throw_gmlc_error("Circular macro reference detected during batch cross-expansion");
			}
		}
	}

	static __inject_batch_context = function(_program, _batchMacros, _batchMacroNames, _batchEnums, _batchEnumNames) {
		var _i = 0; repeat(array_length(_batchMacroNames)) {
			var _name = _batchMacroNames[_i];
			if (!variable_struct_exists(_program.MacroVar, _name)) {
				_program.MacroVar[$ _name] = _batchMacros[$ _name];
				array_push(_program.MacroVarNames, _name);
			}
		_i++;}
		var _headers = struct_get_names(_batchEnums);
		var _j = 0; repeat(array_length(_headers)) {
			var _header = _headers[_j];
			if (!variable_struct_exists(_program.EnumVar, _header)) {
				_program.EnumVar[$ _header]      = _batchEnums[$ _header];
				_program.EnumVarNames[$ _header] = _batchEnumNames[$ _header];
			}
		_j++;}
	}

	#region jsDoc
	/// @func    __compile_pipeline()
	/// @desc    Runs the full pipeline from pre-processed program through to compiled output.
	/// @ignore
	#endregion
	static __compile_pipeline = function(_source) {
		_source = __appendMacros(_source);
		tokenizer.initialize(_source);
		var _program = tokenizer.parseAll();
		pre_processor.initialize(_program);
		pre_processor.parseAll();
		return _program;
	}

	#region jsDoc
	/// @func    __finish_compile()
	/// @desc    Runs parser → post-processor → (optimizer) → compiler on an already-preprocessed program.
	/// @ignore
	#endregion
	static __finish_compile = function(_program, _log_name = undefined) {
		currentScriptName = _log_name ?? "";
		var _prefix = (_log_name != undefined) ? (filename_name(_log_name) + "_") : undefined;
		parser.initialize(_program);
		var _ast = parser.parseAll();
		if (_prefix != undefined && __log_parser_results) json_save(_prefix + "parser.json", _ast);
		post_processor.initialize(_ast);
		_ast = post_processor.parseAll();
		if (_prefix != undefined && __log_post_processer_results) json_save(_prefix + "post_processor.json", _ast);
		if (should_optimize) {
			optimizer.initialize(_ast);
			_ast = optimizer.parseAll();
			if (_prefix != undefined && __log_optimizer_results) json_save(_prefix + "optimizer.json", _ast);
		}
		var _global  = getConstant("global");
		var _globals = is_struct(_global) ? _global.value : {};
		compiler.initialize(_ast, _globals);
		compiler.parseAll();
	}

	#region jsDoc
	/// @func    compile_batch()
	/// @desc    Compiles an array of source strings (or {source, name} structs) as a single
	///          logical unit. A two-phase approach is used: all sources are first scanned for
	///          #macro and enum declarations which are then made available to every file during
	///          the full compile pass. Local definitions always take priority over batch-level ones.
	/// @self    GMLC_Env
	/// @param   {Array<String|Struct>} sources : Array of source strings or {source, name} structs
	/// @returns {Struct.GMLC_BatchResult}
	#endregion
	static compile_batch = function(_sources) {
		var _count = array_length(_sources);
		var _globalMacros     = {};
		var _globalMacroNames = [];
		var _globalEnums      = {};
		var _globalEnumNames  = {};
		var _programs = array_create(_count, undefined);
		var _names    = array_create(_count, "");

		// Phase 1 — Tokenize + preprocess each file ONCE; collect global symbol table
		var _i = 0; repeat(_count) {
			var _entry  = _sources[_i];
			var _source = is_string(_entry) ? _entry : _entry.source;
			_names[_i]  = is_string(_entry) ? $"source_{_i}" : _entry.name;
			currentScriptName = _names[_i];
			_source = __appendMacros(_source);
			tokenizer.initialize(_source);
			var _program = tokenizer.parseAll();
			if (__log_tokenizer_results) json_save(filename_name(_names[_i]) + "_tokenizer.json", _program);
			pre_processor.initialize(_program);
			pre_processor.parseAll();
			if (__log_pre_processer_results) json_save(filename_name(_names[_i]) + "_pre_processor.json", _program);
			_programs[_i] = _program;
			var _j = 0; repeat(array_length(_program.MacroVarNames)) {
				var _mname = _program.MacroVarNames[_j];
				if (!variable_struct_exists(_globalMacros, _mname)) {
					_globalMacros[$ _mname] = _program.MacroVar[$ _mname];
					array_push(_globalMacroNames, _mname);
				}
			_j++;}
			var _headers = struct_get_names(_program.EnumVar);
			var _k = 0; repeat(array_length(_headers)) {
				var _header = _headers[_k];
				if (!variable_struct_exists(_globalEnums, _header)) {
					_globalEnums[$ _header]     = _program.EnumVar[$ _header];
					_globalEnumNames[$ _header] = _program.EnumVarNames[$ _header];
				}
			_k++;}
		_i++;}

		// Phase 2 — Cross-expand macro bodies in global pool
		__cross_expand_macro_bodies(_globalMacros, _globalMacroNames);

		// Phase 3 — Compile each saved (already preprocessed) program with global context
		var _result = new GMLC_BatchResult();
		_i = 0; repeat(_count) {
			var _success = false;
			var _error   = undefined;
			//try {
				__inject_batch_context(_programs[_i], _globalMacros, _globalMacroNames, _globalEnums, _globalEnumNames);
				__finish_compile(_programs[_i], _names[_i]);
				_success = true;
			//}
			//catch (_err) { _error = _err; }
			_result.add(_names[_i], _success, _error);
		_i++;}
		return _result;
	}

	/// @ignore
	static __compile_script_asset = function(_yy, _asset_dir, _result, _batchMacros, _batchMacroNames, _batchEnums, _batchEnumNames) {
		var _name     = _yy.name;
		var _gml_path = _asset_dir + _name + ".gml";
		var _source   = gmlc_file_read_all_text(_gml_path);
		if (_source == undefined) {
			_result.add(_name, false, { message: $"Could not read file: {_gml_path}" });
			return;
		}
		var _success = false;
		var _error   = undefined;
		//try {
			var _program = __compile_pipeline(_source);
			__inject_batch_context(_program, _batchMacros, _batchMacroNames, _batchEnums, _batchEnumNames);
			__finish_compile(_program);
			_success = true;
		//}
		//catch (_err) { _error = _err; }
		_result.add(_name, _success, _error);
	}

	/// @ignore
	static __compile_object_asset = function(_yy, _asset_dir, _result, _batchMacros, _batchMacroNames, _batchEnums, _batchEnumNames) {
		var _obj_name = _yy.name;
		var _files    = gumshoe(_asset_dir, "gml", false);
		var _i = 0; repeat(array_length(_files)) {
			var _gml_path   = _files[_i];
			var _entry_name = _obj_name + "::" + filename_name(_gml_path);
			var _source     = gmlc_file_read_all_text(_gml_path);
			var _success    = false;
			var _error      = undefined;
			//try {
				var _program = __compile_pipeline(_source);
				__inject_batch_context(_program, _batchMacros, _batchMacroNames, _batchEnums, _batchEnumNames);
				__finish_compile(_program);
				_success = true;
			//}
			//catch (_err) { _error = _err; }
			_result.add(_entry_name, _success, _error);
		_i++;}
	}

	#region jsDoc
	/// @func    compile_asset()
	/// @desc    Compiles a single GMS2 asset from its .yy file content. The resourceType field
	///          determines dispatch: GMScript compiles the adjacent .gml, GMObject compiles each
	///          event, all others register the asset name as a known identifier. For cross-asset
	///          macro sharing, prefer compile_project() instead.
	/// @self    GMLC_Env
	/// @param   {String} yyString  : Content of the asset's .yy file
	/// @param   {String} assetDir  : Directory containing the .yy and its sibling source files
	/// @returns {Struct.GMLC_BatchResult}
	#endregion
	static compile_asset = function(_yy_string, _asset_dir) {
		if (string_char_at(_asset_dir, string_length(_asset_dir)) != "/") _asset_dir += "/";
		var _yy     = snap_from_json(_yy_string);
		var _type   = _yy.resourceType;
		var _result = new GMLC_BatchResult();
		var _empty  = {};
		var _emptyA = [];
		if (_type == "GMScript") {
			__compile_script_asset(_yy, _asset_dir, _result, _empty, _emptyA, _empty, _empty);
		}
		else if (_type == "GMObject") {
			__compile_object_asset(_yy, _asset_dir, _result, _empty, _emptyA, _empty, _empty);
		}
		else if (variable_struct_exists(_yy, "name") && is_string(_yy.name)) {
			var _sym = {};
			_sym[$ _yy.name] = 0;
			exposeConstants(_sym);
			_result.add(_yy.name, true);
		}
		return _result;
	}

	#region jsDoc
	/// @func    compile_project()
	/// @desc    Compiles an entire GMS2 project from its .yyp file content. All script and
	///          object events are compiled together with a shared symbol pool so macros defined
	///          in one asset are available in all others. Non-code assets have their names
	///          registered as known identifiers.
	/// @self    GMLC_Env
	/// @param   {String} yypString : Content of the project's .yyp file
	/// @param   {String} rootPath  : Absolute path to the directory containing the .yyp
	/// @returns {Struct.GMLC_BatchResult}
	#endregion
	static compile_project = function(_yyp_string, _root_path) {
		if (string_char_at(_root_path, string_length(_root_path)) != "/") _root_path += "/";
		var _yyp       = snap_from_json(_yyp_string);
		var _resources = _yyp.resources;
		var _count     = array_length(_resources);
		var _entries   = []; // {source, name} for every code file in the project

		// Enumerate resources; collect code files and register non-code assets as constants
		var _i = 0; repeat(_count) {
			var _resource = _resources[_i];
			var _rel_path = _resource.id.path;
			var _slash = 0;
			var _c = string_length(_rel_path);
			repeat(_c) {
				if (string_char_at(_rel_path, _c) == "/") { _slash = _c; break; }
			_c--;}
			var _asset_dir = _root_path + string_copy(_rel_path, 1, _slash);
			var _yy_str    = gmlc_file_read_all_text(_root_path + _rel_path);
			if (_yy_str == undefined) { _i++; continue; }
			var _yy   = snap_from_json(_yy_str);
			var _type = _yy.resourceType;

			if (_type == "GMScript") {
				var _source = gmlc_file_read_all_text(_asset_dir + _yy.name + ".gml");
				if (_source != undefined) array_push(_entries, { source: _source, name: _yy.name });
			}
			else if (_type == "GMObject") {
				var _files = gumshoe(_asset_dir, "gml", false);
				var _j = 0; repeat(array_length(_files)) {
					var _source = gmlc_file_read_all_text(_files[_j]);
					if (_source != undefined) array_push(_entries, { source: _source, name: _yy.name + "::" + filename_name(_files[_j]) });
				_j++;}
			}
			else if (variable_struct_exists(_yy, "name") && is_string(_yy.name)) {
				var _sym = {};
				_sym[$ _yy.name] = 0;
				exposeConstants(_sym);
			}
		_i++;}

		var _file_count      = array_length(_entries);
		var _programs        = array_create(_file_count, undefined);
		var _globalMacros     = {};
		var _globalMacroNames = [];
		var _globalEnums      = {};
		var _globalEnumNames  = {};

		// Phase 1 — Tokenize + preprocess each file ONCE; collect global symbol table
		_i = 0; repeat(_file_count) {
			var _source = __appendMacros(_entries[_i].source);
			tokenizer.initialize(_source);
			var _program = tokenizer.parseAll();
			pre_processor.initialize(_program);
			pre_processor.parseAll();
			_programs[_i] = _program;
			var _j = 0; repeat(array_length(_program.MacroVarNames)) {
				var _mname = _program.MacroVarNames[_j];
				if (!variable_struct_exists(_globalMacros, _mname)) {
					_globalMacros[$ _mname] = _program.MacroVar[$ _mname];
					array_push(_globalMacroNames, _mname);
				}
			_j++;}
			var _headers = struct_get_names(_program.EnumVar);
			var _k = 0; repeat(array_length(_headers)) {
				var _header = _headers[_k];
				if (!variable_struct_exists(_globalEnums, _header)) {
					_globalEnums[$ _header]     = _program.EnumVar[$ _header];
					_globalEnumNames[$ _header] = _program.EnumVarNames[$ _header];
				}
			_k++;}
		_i++;}

		// Phase 2 — Cross-expand macro bodies across the unified global pool
		__cross_expand_macro_bodies(_globalMacros, _globalMacroNames);

		// Phase 3 — Compile each saved program with global context
		var _result = new GMLC_BatchResult();
		_i = 0; repeat(_file_count) {
			var _name    = _entries[_i].name;
			var _success = false;
			var _error   = undefined;
			//try {
				__inject_batch_context(_programs[_i], _globalMacros, _globalMacroNames, _globalEnums, _globalEnumNames);
				__finish_compile(_programs[_i]);
				_success = true;
			//}
			//catch (_err) { _error = _err; }
			_result.add(_name, _success, _error);
		_i++;}
		return _result;
	}

	#endregion

}

#region jsDoc
/// GMLC_EXPOSURE
/// @desc    Exposure tiers that control symbol visibility and function availability within the GMLC environment:
///          NONE, SAFE, MODERATE, ALL, FULL, NATIVE, __SIZE__.
/// @returns {Enum.GMLC_EXPOSURE}
#endregion
enum GMLC_EXPOSURE {
    NONE,
    /*
        Nothing is exposed.
        No assets, no constants, no functions — built-in or user-defined — are available.
    */

    PURE,
    /*
        Exposes native constants and built-in pure functions only.
        Pure means: no side effects, no logging/UI, no access to engine state, time, or global RNG.
        Examples: math helpers, deterministic string/array/struct transforms.
        Excludes: show_debug_message, random/time, draw/UI, instance/asset/buffer/surface ops.
    */

    SAFE,
    /*
        Extends PURE with tightly sandboxed side-effecting intrinsics.
        Allowed: show_debug_message; data-structure and buffer operations on resources
        created inside the sandbox; mutations of caller-provided arrays/structs.
        Not allowed: filesystem, networking/web, OS/environment, external_*,
        asset enumeration/reflection, and any instance/asset access outside the sandbox registry.
        User-defined scripts are not included.
    */

    MODERATE,
    /*
        Extends SAFE by allowing controlled access to engine assets and instances
        strictly via allow-lists supplied by the host (no global enumeration).
        Allowed: random/time; getters on sprites/fonts/tilesets/objects only when the id
        comes from the allow-list; instance operations only on sandbox-registered instances;
        buffer/surface/texture ops only on sandbox-created resources.
        Still not allowed: filesystem, networking/web, OS/environment, external_*, global
        reflection/enumeration (e.g., handle_parse, asset_* listings, texturegroup_get_* listings).
        User-defined scripts are not included.
    */

    ALL,
    /*
        Exposes the entire native GML runtime — including all built-in functions for file access,
        buffer manipulation, networking, and system-level operations.
        However, user-defined scripts and functions are still excluded in this mode.
        This is a trusted runtime with full engine access but without user script inclusion.
    */

    FULL,
    /*
        Unrestricted access to the entire engine plus automatic inclusion of all
        user-defined scripts, assets, and constants. No safety restrictions.
        Intended only for fully trusted environments.
    */

    NATIVE,
    /*
        Grants access to the full native GML runtime, including all built-in functions and constants.
        Unlike ALL or FULL, this level excludes all user-defined assets, constants, and scripts.
        Primarily intended for emulating a fully trusted GML environment without sandbox restrictions,
        while keeping the user runtime completely isolated from global where possible
    */

    __SIZE__,
}

/*
static __EventType = {
	"ev_create": 0,
	"ev_destroy": 1,
	"ev_cleanup": 12,
	"ev_step": 3,
	"ev_alarm": 2,
	"ev_keyboard": 5,
	"ev_mouse": 6,
	"ev_gesture": 13,
	"ev_collision": 4,
	"ev_other": 7,
	"ev_draw": 8,
	"ev_keypress": 9,
	"ev_keyrelease": 10,
	"ev_trigger": 11,
}
static __EventNumber = {
	"ev_step_normal": 0,
	"ev_step_begin": 1,
	"ev_step_end": 2,
	"ev_left_button": 0,
	"ev_right_button": 1,
	"ev_middle_button": 2,
	"ev_no_button": 3,
	"ev_left_press": 4,
	"ev_right_press": 5,
	"ev_middle_press": 6,
	"ev_left_release": 7,
	"ev_right_release": 8,
	"ev_middle_release": 9,
	"ev_mouse_enter": 10,
	"ev_mouse_leave": 11,
	"ev_mouse_wheel_up": 60,
	"ev_mouse_wheel_down": 61,
	"ev_global_left_button": 50,
	"ev_global_right_button": 51,
	"ev_global_middle_button": 52,
	"ev_global_left_press": 53,
	"ev_global_right_press": 54,
	"ev_global_middle_press": 55,
	"ev_global_left_release": 56,
	"ev_global_right_release": 57,
	"ev_global_middle_release": 58,
	"ev_gesture_tap": 0,
	"ev_gesture_double_tap": 1,
	"ev_gesture_drag_start": 2,
	"ev_gesture_dragging": 3,
	"ev_gesture_drag_end": 4,
	"ev_gesture_flick": 5,
	"ev_gesture_pinch_start": 6,
	"ev_gesture_pinch_in": 7,
	"ev_gesture_pinch_out": 8,
	"ev_gesture_pinch_end": 9,
	"ev_gesture_rotate_start": 10,
	"ev_gesture_rotating": 11,
	"ev_gesture_rotate_end": 12,
	"ev_global_gesture_tap": 64,
	"ev_global_gesture_double_tap": 65,
	"ev_global_gesture_drag_start": 66,
	"ev_global_gesture_dragging": 67,
	"ev_global_gesture_drag_end": 68,
	"ev_global_gesture_flick": 69,
	"ev_global_gesture_pinch_start": 70,
	"ev_global_gesture_pinch_in": 71,
	"ev_global_gesture_pinch_out": 72,
	"ev_global_gesture_pinch_end": 73,
	"ev_global_gesture_rotate_start": 74,
	"ev_global_gesture_rotating": 75,
	"ev_global_gesture_rotate_end": 76,
	"ev_outside": 0,
	"ev_boundary": 1,
	"ev_outside_view0": 40,
	"ev_boundary_view0": 50,
	"ev_game_start": 2,
	"ev_game_end": 3,
	"ev_room_start": 4,
	"ev_room_end": 5,
	"ev_animation_end": 7,
	"ev_animation_update": 58,
	"ev_animation_event": 59,
	"ev_end_of_path": 8,
	"ev_user0": 10,
	"ev_broadcast_message": 76,
	"ev_draw_begin": 72,
	"ev_draw_end": 73,
	"ev_draw_pre": 76,
	"ev_draw_normal": 0,
	"ev_draw_post": 77,
	"ev_gui": 64,
	"ev_gui_begin": 74,
	"ev_gui_end": 75,
	"ev_joystick1_left": 16,
	"ev_joystick1_right": 17,
	"ev_joystick1_up": 18,
	"ev_joystick1_down": 19,
	"ev_joystick1_button1": 21,
	"ev_joystick1_button2": 22,
	"ev_joystick1_button3": 23,
	"ev_joystick1_button4": 24,
	"ev_joystick1_button5": 25,
	"ev_joystick1_button6": 26,
	"ev_joystick1_button7": 27,
	"ev_joystick1_button8": 28,
	"ev_joystick2_left": 31,
	"ev_joystick2_right": 32,
	"ev_joystick2_up": 33,
	"ev_joystick2_down": 34,
	"ev_joystick2_button1": 36,
	"ev_joystick2_button2": 37,
	"ev_joystick2_button3": 38,
	"ev_joystick2_button4": 39,
	"ev_joystick2_button5": 40,
	"ev_joystick2_button6": 41,
	"ev_joystick2_button7": 42,
	"ev_joystick2_button8": 43,
	"ev_no_more_lives": 6,
	"ev_no_more_health": 9,
	"ev_user1": 11,
	"ev_user2": 12,
	"ev_user3": 13,
	"ev_user4": 14,
	"ev_user5": 15,
	"ev_user6": 16,
	"ev_user7": 17,
	"ev_user8": 18,
	"ev_user9": 19,
	"ev_user10": 20,
	"ev_user11": 21,
	"ev_user12": 22,
	"ev_user13": 23,
	"ev_user14": 24,
	"ev_user15": 25,
	"ev_outside_view1": 41,
	"ev_outside_view2": 42,
	"ev_outside_view3": 43,
	"ev_outside_view4": 44,
	"ev_outside_view5": 45,
	"ev_outside_view6": 46,
	"ev_outside_view7": 47,
	"ev_boundary_view1": 51,
	"ev_boundary_view2": 52,
	"ev_boundary_view3": 53,
	"ev_boundary_view4": 54,
	"ev_boundary_view5": 55,
	"ev_boundary_view6": 56,
	"ev_boundary_view7": 57,
	"ev_web_image_load": 60,
	"ev_web_sound_load": 61,
	"ev_web_async": 62,
	"ev_dialog_async": 63,
	"ev_web_iap": 66,
	"ev_web_cloud": 67,
	"ev_web_networking": 68,
	"ev_web_steam": 69,
	"ev_social": 70,
	"ev_push_notification": 71,
	"ev_audio_recording": 73,
	"ev_audio_playback": 74,
	"ev_audio_playback_ended": 80,
	"ev_system_event": 75,
}