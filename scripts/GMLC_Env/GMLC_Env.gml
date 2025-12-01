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
			get: method(undefined, function(){
				return parentNode.arguments;
			}),
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
			get: method(undefined, function(){
				return array_length(parentNode.arguments);
			}),
			set: method(undefined, function(value){ throw_gmlc_error($"Attempting to write to a read-only variable argument_count"+$"\n(line {line}) -\t{lineString}") }),
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
		get: function(){ return global.gmlc_self_instance; },
		set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable self"+$"\n(line {line}) -\t{lineString}") },
	};
	_var_map[$ "other"] = {
		get: function(){ return global.gmlc_other_instance; },
		set: function(value){ throw_gmlc_error($"Attempting to write to a read-only variable other"+$"\n(line {line}) -\t{lineString}") },
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
	static compile = function(_sourceCode) {
		//append the macros to the end of the source code.
		_sourceCode = __appendMacros(_sourceCode);
		
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
		
		var _global = getConstant("global");
		var _globals = (is_struct(_global)) ? _global.value : {};
		compiler.initialize(ast, _globals);
		var program = compiler.parseAll();
		if (__log_compiler_results) json_save("post_processor.json", ast)
		
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
	
	#region Private
	//used to print the outputs for debugging
	__log_path = "log.json"
	__log_tokenizer_results      = true;
	__log_pre_processer_results  = true;
	__log_parser_results         = true;
	__log_post_processer_results = true;
	__log_optimizer_results      = true;
	__log_compiler_results       = false;
	
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




