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
		"define": true,
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
	#region Expose Variables
	var _var_map = {
		"visible":{
			get: function(){ return visible; },
			set: function(value){ visible = value; },
		},
		"managed":{
			get: function(){ return managed; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable managed"+$"\n(line {line}) -\t{lineString}") },
		},
		"path_index":{
			get: function(){ return path_index; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable path_index"+$"\n(line {line}) -\t{lineString}") },
		},
		"async_load":{
			get: function(){ return async_load; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable async_load"+$"\n(line {line}) -\t{lineString}") },
		},
		"event_data":{
			get: function(){ return event_data; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable event_data"+$"\n(line {line}) -\t{lineString}") },
		},
		"iap_data":{
			get: function(){ return iap_data; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable iap_data"+$"\n(line {line}) -\t{lineString}") },
		},
		"display_aa":{
			get: function(){ return display_aa; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable display_aa"+$"\n(line {line}) -\t{lineString}") },
		},
		"delta_time":{
			get: function(){ return delta_time; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable delta_time"+$"\n(line {line}) -\t{lineString}") },
		},
		"webgl_enabled":{
			get: function(){ return webgl_enabled; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable webgl_enabled"+$"\n(line {line}) -\t{lineString}") },
		},
		//"argument_relative":{
		//	get: function(){ return argument_relative; },
		//	set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable argument_relative"+$"\n(line {line}) -\t{lineString}") },
		//},
		"argument":{
			get: function(){ return parentNode.arguments; },
			set: function(value){ parentNode.arguments = value; },
		},
		"argument0":{
			get: function(){ return parentNode.arguments[0]; },
			set: function(value){ parentNode.arguments[0] = value; },
		},
		"argument1":{
			get: function(){ return parentNode.arguments[1]; },
			set: function(value){ parentNode.arguments[1] = value; },
		},
		"argument2":{
			get: function(){ return parentNode.arguments[0]; },
			set: function(value){ parentNode.arguments[0] = value; },
		},
		"argument3":{
			get: function(){ return parentNode.arguments[3]; },
			set: function(value){ parentNode.arguments[3] = value; },
		},
		"argument4":{
			get: function(){ return parentNode.arguments[4]; },
			set: function(value){ parentNode.arguments[4] = value; },
		},
		"argument5":{
			get: function(){ return parentNode.arguments[5]; },
			set: function(value){ parentNode.arguments[5] = value; },
		},
		"argument6":{
			get: function(){ return parentNode.arguments[6]; },
			set: function(value){ parentNode.arguments[6] = value; },
		},
		"argument7":{
			get: function(){ return parentNode.arguments[7]; },
			set: function(value){ parentNode.arguments[7] = value; },
		},
		"argument8":{
			get: function(){ return parentNode.arguments[8]; },
			set: function(value){ parentNode.arguments[8] = value; },
		},
		"argument9":{
			get: function(){ return parentNode.arguments[9]; },
			set: function(value){ parentNode.arguments[9] = value; },
		},
		"argument10":{
			get: function(){ return parentNode.arguments[10]; },
			set: function(value){ parentNode.arguments[10] = value; },
		},
		"argument11":{
			get: function(){ return parentNode.arguments[11]; },
			set: function(value){ parentNode.arguments[11] = value; },
		},
		"argument12":{
			get: function(){ return parentNode.arguments[12]; },
			set: function(value){ parentNode.arguments[12] = value; },
		},
		"argument13":{
			get: function(){ return parentNode.arguments[13]; },
			set: function(value){ parentNode.arguments[13] = value; },
		},
		"argument14":{
			get: function(){ return parentNode.arguments[14]; },
			set: function(value){ parentNode.arguments[14] = value; },
		},
		"argument15":{
			get: function(){ return parentNode.arguments[15]; },
			set: function(value){ parentNode.arguments[15] = value; },
		},
		"argument_count":{
			get: function(){ return array_length(parentNode.arguments); },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable argument_count"+$"\n(line {line}) -\t{lineString}") },
		},
		"debug_mode":{
			get: function(){ return debug_mode; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable debug_mode"+$"\n(line {line}) -\t{lineString}") },
		},
		"room":{
			get: function(){ return room; },
			set: function(value){ room = value; },
		},
		"room_first":{
			get: function(){ return room_first; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable room_first"+$"\n(line {line}) -\t{lineString}") },
		},
		"room_last":{
			get: function(){ return room_last; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable room_last"+$"\n(line {line}) -\t{lineString}") },
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
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable game_id"+$"\n(line {line}) -\t{lineString}") },
		},
		"game_display_name":{
			get: function(){ return game_display_name; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable game_display_name"+$"\n(line {line}) -\t{lineString}") },
		},
		"game_project_name":{
			get: function(){ return game_project_name; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable game_project_name"+$"\n(line {line}) -\t{lineString}") },
		},
		"game_save_id":{
			get: function(){ return game_save_id; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable game_save_id"+$"\n(line {line}) -\t{lineString}") },
		},
		"working_directory":{
			get: function(){ return working_directory; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable working_directory"+$"\n(line {line}) -\t{lineString}") },
		},
		"temp_directory":{
			get: function(){ return temp_directory; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable temp_directory"+$"\n(line {line}) -\t{lineString}") },
		},
		"cache_directory":{
			get: function(){ return cache_directory; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable cache_directory"+$"\n(line {line}) -\t{lineString}") },
		},
		"program_directory":{
			get: function(){ return program_directory; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable program_directory"+$"\n(line {line}) -\t{lineString}") },
		},
		"instance_count":{
			get: function(){ return instance_count; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable instance_count"+$"\n(line {line}) -\t{lineString}") },
		},
		"instance_id":{
			get: function(){ return instance_id; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable instance_id"+$"\n(line {line}) -\t{lineString}") },
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
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable view_current"+$"\n(line {line}) -\t{lineString}") },
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
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable mouse_x"+$"\n(line {line}) -\t{lineString}") },
		},
		"mouse_y":{
			get: function(){ return mouse_y; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable mouse_y"+$"\n(line {line}) -\t{lineString}") },
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
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable fps"+$"\n(line {line}) -\t{lineString}") },
		},
		"fps_real":{
			get: function(){ return fps_real; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable fps_real"+$"\n(line {line}) -\t{lineString}") },
		},
		"current_time":{
			get: function(){ return current_time; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_time"+$"\n(line {line}) -\t{lineString}") },
		},
		"current_year":{
			get: function(){ return current_year; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_year"+$"\n(line {line}) -\t{lineString}") },
		},
		"current_month":{
			get: function(){ return current_month; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_month"+$"\n(line {line}) -\t{lineString}") },
		},
		"current_day":{
			get: function(){ return current_day; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_day"+$"\n(line {line}) -\t{lineString}") },
		},
		"current_weekday":{
			get: function(){ return current_weekday; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_weekday"+$"\n(line {line}) -\t{lineString}") },
		},
		"current_hour":{
			get: function(){ return current_hour; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_time"+$"\n(line {line}) -\t{lineString}") },
		},
		"current_minute":{
			get: function(){ return current_minute; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_minute"+$"\n(line {line}) -\t{lineString}") },
		},
		"current_second":{
			get: function(){ return current_second; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable current_second"+$"\n(line {line}) -\t{lineString}") },
		},
		"event_action":{
			get: function(){ return event_action; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable event_action"+$"\n(line {line}) -\t{lineString}") },
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
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable gamemaker_registered"+$"\n(line {line}) -\t{lineString}") },
		},
		"gamemaker_pro":{
			get: function(){ return gamemaker_pro; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable gamemaker_pro"+$"\n(line {line}) -\t{lineString}") },
		},
		"application_surface":{
			get: function(){ return application_surface; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable application_surface"+$"\n(line {line}) -\t{lineString}") },
		},
		"font_texture_page_size":{
			get: function(){ return font_texture_page_size; },
			set: function(value){ font_texture_page_size = value; },
		},
		"os_type":{
			get: function(){ return os_type; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable os_type"+$"\n(line {line}) -\t{lineString}") },
		},
		"os_device":{
			get: function(){ return os_device; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable os_device"+$"\n(line {line}) -\t{lineString}") },
		},
		"os_version":{
			get: function(){ return os_version; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable os_version"+$"\n(line {line}) -\t{lineString}") },
		},
		"os_browser":{
			get: function(){ return os_browser; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable os_browser"+$"\n(line {line}) -\t{lineString}") },
		},
		"browser_width":{
			get: function(){ return browser_width; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable bwoser_width"+$"\n(line {line}) -\t{lineString}") },
		},
		"browser_height":{
			get: function(){ return browser_height; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable browser_height"+$"\n(line {line}) -\t{lineString}") },
		},
		"rollback_current_frame":{
			get: function(){ return rollback_current_frame; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable rollback_current_frame"+$"\n(line {line}) -\t{lineString}") },
		},
		"rollback_confirmed_frame":{
			get: function(){ return rollback_confirmed_frame; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable rollback_confirmed_frame"+$"\n(line {line}) -\t{lineString}") },
		},
		"rollback_event_id":{
			get: function(){ return rollback_event_id; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable rollback_event_id"+$"\n(line {line}) -\t{lineString}") },
		},
		"rollback_event_param":{
			get: function(){ return rollback_event_param; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable rollback_event_param"+$"\n(line {line}) -\t{lineString}") },
		},
		"rollback_game_running":{
			get: function(){ return rollback_game_running; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable rollback_game_running"+$"\n(line {line}) -\t{lineString}") },
		},
		"rollback_api_server":{
			get: function(){ return rollback_api_server; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable rollback_api_server"+$"\n(line {line}) -\t{lineString}") },
		},
		"wallpaper_config":{
			get: function(){ return wallpaper_config; },
			set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable wallpaper_config"+$"\n(line {line}) -\t{lineString}") },
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
		get: function(){ return global.selfInstance; },
		set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable self"+$"\n(line {line}) -\t{lineString}") },
	};
	_var_map[$ "other"] = {
		get: function(){ return global.otherInstance; },
		set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable other"+$"\n(line {line}) -\t{lineString}") },
	};
	exposeVariables(_var_map);
	#endregion
	
	tokenizer      = new GMLC_Gen_0_Tokenizer(self);
	pre_processor  = new GMLC_Gen_1_PreProcessor(self);
	parser         = new GMLC_Gen_2_Parser(self);
	post_processor = new GMLC_Gen_3_PostProcessor(self);
	optimizer      = new GMLC_Gen_4_Optimizer(self);
	
	#endregion
	
	#region Public
	static compile = function(_sourceCode) {
		tokenizer.initialize(_sourceCode);
		var tokens = tokenizer.parseAll();
		if (__log_tokenizer_results) json_save("tokenizer.json", tokens)
		
		pre_processor.initialize(tokens);
		var preprocessedTokens = pre_processor.parseAll();
		if (__log_pre_processer_results) json_save("pre_processor.json", preprocessedTokens)
		
		parser.initialize(preprocessedTokens);
		var ast = parser.parseAll();
		if (__log_parser_results) json_save("parser.json", ast)
		
		post_processor.initialize(ast);
		var ast = post_processor.parseAll();
		if (__log_post_processer_results) json_save("post_processor.json", ast)
		
		if (should_optimize) {
			optimizer.initialize(ast);
			var ast = optimizer.parseAll();
			if (__log_optimizer_results) json_save("optimizer.json", ast)
		}
		
		return compileProgram(ast);
	}
	static enable_optimizer = function(_bool) {
		should_optimize = _bool;
		return self;
	}
	
	static set_exposure = function(_expose_level=GMLC_EXPOSURE.SAFE) {
		expose_constants(_expose_level);
		expose_user_assets(_expose_level);
		expose_functions(_expose_level);
		
		return self;
	}
	
	static expose_constants = function(_expose_level=GMLC_EXPOSURE.SAFE) {
		var _spec = __GmlSpec();
		var _map = struct_filter(_spec, function(_key, _val) {
			return _val[$ "type"] == "envConstants";
		});
		importSymbolMap(_map);
		
		exposeConstants({
			"all": all,
			"noone": noone,
		});
		//expose globl depending on exposure level
		exposeConstants({
			"global": (_expose_level == GMLC_EXPOSURE.FULL) ? global : {},
		});
		return self;
	}
	static expose_user_assets = function(_expose_level=GMLC_EXPOSURE.SAFE) {
		if (_expose_level < GMLC_EXPOSURE.SAFE) 
		|| (_expose_level == GMLC_EXPOSURE.NATIVE) {
			return;
		}
		
		var _arr = array_concat(
			asset_get_ids(asset_object),         asset_get_ids(asset_sprite),   asset_get_ids(asset_sound),
			asset_get_ids(asset_room),           asset_get_ids(asset_tiles),    asset_get_ids(asset_path),
			asset_get_ids(asset_font),           asset_get_ids(asset_timeline), asset_get_ids(asset_shader),
			asset_get_ids(asset_animationcurve), asset_get_ids(asset_sequence), asset_get_ids(asset_particlesystem)
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
				expose_user_functions();   // And also user scripts
			break;
		}
		return self;
	};

	
	static expose_pure_functions = function() {
		var _spec = __GmlSpec();
		var _map = struct_filter(_spec, function(_key, _val) {
			return (_val[$ "type"] == "envFunctions")
				&& (_val[$ "feather"][$ "pure"])
				&& __is_safe_function(_key, _val);
		});
		importSymbolMap(_map);
		
		return self;
	}
	static expose_safe_functions = function() {
		var _spec = __GmlSpec();
		
		var _map = struct_filter(_spec, function(_key, _val) {
			if (!__is_safe_function(_key, _val)) return false;
			return _val[$ "feather"][$ "pure"]; // Only allow pure built-ins
		});
		
		importSymbolMap(_map);
		
		return self;
	};
	static expose_overwrite_functions = function(){
		//This will overwrite the existing functions.
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
		})
		return self;
	}
	static expose_native_functions = function() {
		var _spec = __GmlSpec();
		var _map = struct_filter(_spec, function(_key, _val) {
			return (_val[$ "type"] == "envFunctions");
		});
		importSymbolMap(_map);
		return self;
	}
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
	
	#region Private
	//used to print the outputs for debugging
	__log_path = "log.json"
	__log_tokenizer_results      = true;
	__log_pre_processer_results  = true;
	__log_parser_results         = true;
	__log_post_processer_results = true;
	__log_optimizer_results      = true;
	
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
	
	#endregion
}

/*
	GMLC_EXPOSURE defines progressive tiers of symbol visibility and function access for code evaluation.
	Use this to enforce sandboxing, restrict access to sensitive APIs, or expose just enough for trusted scripts.
*/
enum GMLC_EXPOSURE {
	NONE,
	/*
		Nothing is exposed by default.
		No assets, no constants, no functions — built-in or user-defined — are available.
	*/
	SAFE,
	/*
		Exposes only native constants, built-in *pure* functions (no side effects),
		and user assets such as sprites, objects, fonts, rooms, etc.
		User-defined scripts are not included.
	*/
	MODERATE,
	/*
		Extends SAFE by allowing built-in *non-pure* functions such as random, instance creation,
		and timeline manipulation — as long as they do not access external systems.
		Still excludes functions that touch local files, networking, extensions, or raw buffers.
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
		Unrestricted access: includes all built-in constants and functions, including those for
		file I/O, networking, extensions, and buffer operations.
		Also includes **all user-defined scripts automatically**.
		This mode disables all safety restrictions and assumes a trusted environment.
	*/
	NATIVE,
	/*
		Grants access to the full native GML runtime, including all built-in functions and constants.
		Unlike ALL or FULL, this level excludes all user-defined assets, constants, and scripts.
		Primarily intended for emulating a fully trusted GML environment without sandbox restrictions,
		while keeping the user runtime completely isolated.
	*/
	__SIZE__,
}




