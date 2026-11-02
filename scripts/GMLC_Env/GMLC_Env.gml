#region jsDoc
/// @func	GMLC_Env()
/// @desc	Constructs a new GMLC compiler/evaluator environment. Sets up keyword/operator/variable exposure, wires the full pipeline
///			(tokenizer -> preprocessor -> parser -> resolver -> lower -> optional optimizer -> compiler),
///			and provides methods to configure exposure tiers and compile source text.
/// @returns {Struct.GMLC_Env}
#endregion
function GMLC_Env() : GMLC_EnvironmentClass() constructor {
	
	
	#region Init
	should_optimize = false;
	preserve_lines = false;
	emit_for_vm = false; // the emitted GML is built for the VM, not YYC: the passes that run slower on the VM do not run
	infer_project = false; // compile_project also infers the project's parameter and field types and reports its type diagnostics: for an IDE, slower, never needed by the emitted code
	copy_on_write = undefined; // the project's Copy on Write game option for arrays; undefined when unknown, which counts as on
	__batch_epsilon = false; // a file of the batch calls math_set_epsilon
	__batch = __gmlc_type_batch_empty(); // what the files of the batch tell each other's types (gmlc_type_batch)
	__batch_project = false; // the batch is a whole project
	__batch_external = []; // function names a resource calls by name
	test_mode = false;
	collect_statistics = false; // the optimizer records what each pass did (`optimizer.statistics`) and runs the analysis passes that only report
	debug = false;
	__struct_literal_statics = {}; // in place of GameMaker's static struct shared by every struct literal
	
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
		"#region": true,
		"#endregion": true,
		"#macro": true,
		"try": true,
		"catch": true,
		"finally": true,
		"throw": true,
		"delete": true,
	};
	
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
	_op_map[$ ":="] = true;
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
			get: method(undefined, function(){ return parent_node.arguments; }),
			set: method(undefined, function(value){ parent_node.arguments = value; }),
		},
		"argument0":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (0 < array_length(_a)) ? _a[0] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[0] = value; }),
		},
		"argument1":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (1 < array_length(_a)) ? _a[1] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[1] = value; }),
		},
		"argument2":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (2 < array_length(_a)) ? _a[2] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[2] = value; }),
		},
		"argument3":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (3 < array_length(_a)) ? _a[3] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[3] = value; }),
		},
		"argument4":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (4 < array_length(_a)) ? _a[4] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[4] = value; }),
		},
		"argument5":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (5 < array_length(_a)) ? _a[5] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[5] = value; }),
		},
		"argument6":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (6 < array_length(_a)) ? _a[6] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[6] = value; }),
		},
		"argument7":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (7 < array_length(_a)) ? _a[7] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[7] = value; }),
		},
		"argument8":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (8 < array_length(_a)) ? _a[8] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[8] = value; }),
		},
		"argument9":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (9 < array_length(_a)) ? _a[9] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[9] = value; }),
		},
		"argument10":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (10 < array_length(_a)) ? _a[10] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[10] = value; }),
		},
		"argument11":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (11 < array_length(_a)) ? _a[11] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[11] = value; }),
		},
		"argument12":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (12 < array_length(_a)) ? _a[12] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[12] = value; }),
		},
		"argument13":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (13 < array_length(_a)) ? _a[13] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[13] = value; }),
		},
		"argument14":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (14 < array_length(_a)) ? _a[14] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[14] = value; }),
		},
		"argument15":{
			get: method(undefined, function(){ var _a = parent_node.arguments; return (15 < array_length(_a)) ? _a[15] : undefined; }),
			set: method(undefined, function(value){ parent_node.arguments[15] = value; }),
		},
		"argument_count":{
			get: method(undefined, function(){ return array_length(parent_node.arguments); }),
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
		"_GMFILE_":{
			get: function(){ throw_gmlc_error($"_GMFILE_ must be resolved at compile time", struct_get(self, "line"), struct_get(self, "lineString")) },
			set: function(_value){ throw_gmlc_error($"Attempting to write to a read-only variable _GMFILE_", struct_get(self, "line"), struct_get(self, "lineString")) },
			compileTimeConstant: true,
			valueOfPlace: true, // the value is where the code is, so moving the code changes it
			compileTimeGet: function(_context){ return _context.fileName; },
		},
		"_GMFUNCTION_":{
			get: function(){ throw_gmlc_error($"_GMFUNCTION_ must be resolved at compile time", struct_get(self, "line"), struct_get(self, "lineString")) },
			set: function(_value){ throw_gmlc_error($"Attempting to write to a read-only variable _GMFUNCTION_", struct_get(self, "line"), struct_get(self, "lineString")) },
			compileTimeConstant: true,
			valueOfPlace: true,
			compileTimeGet: function(_context){ return _context.functionName; },
		},
		"_GMLINE_":{
			get: function(){ throw_gmlc_error($"_GMLINE_ must be resolved at compile time", struct_get(self, "line"), struct_get(self, "lineString")) },
			set: function(_value){ throw_gmlc_error($"Attempting to write to a read-only variable _GMLINE_", struct_get(self, "line"), struct_get(self, "lineString")) },
			compileTimeConstant: true,
			compileTimeGet: function(_context){ return _context.line; },
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
	
	lexer          = new GMLC_Gen_0_Lexer(self);
	pre_processor  = new GMLC_Gen_1_PreProcessor(self);
	parser         = new GMLC_Gen_2_Parser(self);
	resolver       = new GMLC_Gen_3_Resolver(self);
	lower = new GMLC_Gen_4_Lower(self);
	optimizer      = new GMLC_Gen_5_Optimizer(self);
	compiler       = new GMLC_Gen_6_Compiler(self);
	emitter        = new GMLC_Gen_6_Emitter(self);
	
	anonymous_function_count = 0;
	extensions = [];       // in the order their rewrites run
	diagnostics = [];
	sources = undefined;
	__unit_file = 0;
	
	config_chain = ["Default"]; // nearest configuration first
	build_scoped = false; // the output belongs to one build, not to source any configuration compiles later
	config_unknown = false; // the configuration is not known: `*`
	__scoped_macros = {}; // the names of the macros that have a `Config:` definition in the batch, as keys
	__host_unit = undefined;
	__host_files = []; // always the first files of a compile's source table
	
	set_exposure(GMLC_EXPOSURE.SAFE);
	
	#endregion

	#region Public

	#region jsDoc
	/// @func    foldableFunctions
	/// @desc    The built-in functions a compile-time fold may run when every argument is a constant: name to
	///          [GameMaker's function, fewest, most arguments], -1 for any number. A name folds only while the
	///          environment exposes GameMaker's own function under it, so a host's replacement never runs while
	///          compiling. Left out: `sqrt` (depends on math_set_epsilon), `choose` (random), `is_callable`, `object_*`
	///          and `script_*` (depend on the running game), `string_last_pos_ext` (a start past the end reads past the
	///          string), sin, cos, tan, arctan2, their inverses and degree forms and exp (the C runtime's last bit is
	///          not always correctly rounded), lengthdir_x and lengthdir_y (a result close to a whole number is
	///          snapped). `power` folds only on whole numbers with an exact whole result; `max`, `min`, `mean` and
	///          `median` need an argument.
	#endregion
	static foldableFunctions = {
		abs: [abs, 1, 1], angle_difference: [angle_difference, 2, 2], ansi_char: [ansi_char, 1, 1],
		base64_decode: [base64_decode, 1, 1], base64_encode: [base64_encode, 1, 1],
		buffer_sizeof: [buffer_sizeof, 1, 1], ceil: [ceil, 1, 1], chr: [chr, 1, 1], clamp: [clamp, 3, 3],
		code_is_compiled: [code_is_compiled, 0, 0], color_get_blue: [color_get_blue, 1, 1],
		color_get_green: [color_get_green, 1, 1], color_get_hue: [color_get_hue, 1, 1],
		color_get_red: [color_get_red, 1, 1], color_get_saturation: [color_get_saturation, 1, 1],
		color_get_value: [color_get_value, 1, 1], colour_get_blue: [colour_get_blue, 1, 1],
		colour_get_green: [colour_get_green, 1, 1], colour_get_hue: [colour_get_hue, 1, 1],
		colour_get_red: [colour_get_red, 1, 1], colour_get_saturation: [colour_get_saturation, 1, 1],
		colour_get_value: [colour_get_value, 1, 1], degtorad: [degtorad, 1, 1], dot_product: [dot_product, 4, 4],
		dot_product_3d: [dot_product_3d, 6, 6], dot_product_3d_normalised: [dot_product_3d_normalised, 6, 6],
		dot_product_normalised: [dot_product_normalised, 4, 4], floor: [floor, 1, 1], frac: [frac, 1, 1],
		int64: [int64, 1, 1], is_array: [is_array, 1, 1], is_bool: [is_bool, 1, 1], is_handle: [is_handle, 1, 1],
		is_infinity: [is_infinity, 1, 1], is_int32: [is_int32, 1, 1], is_method: [is_method, 1, 1],
		is_nan: [is_nan, 1, 1], is_numeric: [is_numeric, 1, 1], is_ptr: [is_ptr, 1, 1], is_string: [is_string, 1, 1],
		is_struct: [is_struct, 1, 1], is_undefined: [is_undefined, 1, 1], lerp: [lerp, 3, 3], ln: [ln, 1, 1],
		log10: [log10, 1, 1], log2: [log2, 1, 1], logn: [logn, 2, 2], make_color_hsv: [make_color_hsv, 3, 3],
		make_color_rgb: [make_color_rgb, 3, 3], make_colour_hsv: [make_colour_hsv, 3, 3],
		make_colour_rgb: [make_colour_rgb, 3, 3], max: [max, 1, -1], md5_string_unicode: [md5_string_unicode, 1, 1],
		md5_string_utf8: [md5_string_utf8, 1, 1], mean: [mean, 1, -1], median: [median, 1, -1], min: [min, 1, -1],
		ord: [ord, 1, 1], os_get_config: [os_get_config, 0, 0], point_direction: [point_direction, 4, 4],
		point_distance: [point_distance, 4, 4], point_distance_3d: [point_distance_3d, 6, 6], power: [power, 2, 2],
		radtodeg: [radtodeg, 1, 1], real: [real, 1, 1], round: [round, 1, 1],
		sha1_string_unicode: [sha1_string_unicode, 1, 1], sha1_string_utf8: [sha1_string_utf8, 1, 1],
		sign: [sign, 1, 1], sqr: [sqr, 1, 1], string: [string, 0, -1], string_byte_length: [string_byte_length, 1, 1],
		string_char_at: [string_char_at, 2, 2], string_concat: [string_concat, 1, -1],
		string_concat_ext: [string_concat_ext, 1, 3], string_copy: [string_copy, 3, 3],
		string_count: [string_count, 2, 2], string_delete: [string_delete, 3, 3], string_digits: [string_digits, 1, 1],
		string_ends_with: [string_ends_with, 2, 2], string_ext: [string_ext, 2, 2],
		string_format: [string_format, 3, 3], string_hash_to_newline: [string_hash_to_newline, 1, 1],
		string_insert: [string_insert, 3, 3], string_join: [string_join, 1, -1],
		string_join_ext: [string_join_ext, 2, 4], string_last_pos: [string_last_pos, 2, 2],
		string_length: [string_length, 1, 1], string_letters: [string_letters, 1, 1],
		string_lower: [string_lower, 1, 1], string_ord_at: [string_ord_at, 2, 2], string_pos: [string_pos, 2, 2],
		string_pos_ext: [string_pos_ext, 3, 3], string_repeat: [string_repeat, 2, 2],
		string_replace: [string_replace, 3, 3], string_replace_all: [string_replace_all, 3, 3],
		string_set_byte_at: [string_set_byte_at, 3, 3], string_starts_with: [string_starts_with, 2, 2],
		string_trim: [string_trim, 1, 2], string_trim_end: [string_trim_end, 1, 2],
		string_trim_start: [string_trim_start, 1, 2], string_upper: [string_upper, 1, 1]
	};
	
	#region jsDoc
	/// @func    foldableArity(_name)
	/// @desc    The [fewest, most] arguments of a foldable built-in this environment exposes as GameMaker's own
	///          function, undefined otherwise.
	/// @self    GMLC_Env
	/// @param   {String} _name : The function name
	/// @returns {Array<Real>|Undefined}
	#endregion
	static foldableArity = function(_name) {
		if (!__gmlc_struct_has(foldableFunctions, _name)) return undefined;
		var _data = getFunction(_name);
		if (_data == undefined) return undefined;
		var _entry = foldableFunctions[$ _name];
		if ((_data[$ "raw"] ?? _data.value) != _entry[0]) return undefined;
		return [_entry[1], _entry[2]];
	};
	
	#region jsDoc
	/// @func    compile()
	/// @desc    Runs the complete compilation pipeline on the given source text. Its warnings are in `diagnostics`
	///          afterwards; an error stops it with the error struct GMLC throws (message, line, ... and every
	///          diagnostic under `diagnostics`).
	/// @self    GMLC_Env
	/// @param   {String} sourceCode : Source text to compile
	/// @param   {String} [name]     : Name of the file, for errors
	/// @param   {String} [kind]     : "script" (default) or "event": an object event's top-level functions are methods
	///                                of the instance running it, not global functions
	/// @returns {Any} Compiled program artifact produced by GMLC_Gen_6_Compiler
	#endregion
	static compile = function(_sourceCode = "", _name = "", _kind = "script") {
		var _job = compile_begin(_sourceCode, _name, _kind);
		while (_job.step()) {}
		return _job.program;
	}
	
	#region jsDoc
	/// @func    check()
	/// @desc    Finds the problems of a source without compiling or running it: lexer, preprocessor, parser, resolver
	///          and lowering run, and their diagnostics (warnings and errors) come back sorted. Nothing is thrown for
	///          a problem in the source.
	/// @self    GMLC_Env
	/// @param   {String} sourceCode : Source text to check
	/// @param   {String} [name]     : Name of the file, for positions
	/// @param   {String} [kind]     : "script" (default) or "event", as for compile
	/// @returns {Array<Struct.GMLC_Diagnostic>}
	#endregion
	static check = function(_sourceCode = "", _name = "", _kind = "script") {
		diagnostics = [];
		var _job = new GMLC_CompileJob(self, _sourceCode, _name, _kind, false, false);
		try {
			while (_job.step()) {}
		}
		catch (_e) {
		}
		return diagnostics;
	}
	
	#region jsDoc
	/// @func    emit()
	/// @desc    The source as GML text written again by GMLC: comments, macros, enums and regions where they were,
	///          every statement in one layout. With the optimizer on (enable_optimizer) the optimized code is
	///          written. A source with an error comes back as it was; the problems are in `diagnostics`, and
	///          nothing is thrown for a problem in the source.
	/// @self    GMLC_Env
	/// @param   {String} sourceCode : Source text
	/// @param   {String} [name]     : Name of the file, for positions
	/// @param   {String} [kind]     : "script" (default) or "event", as for compile
	/// @returns {String}
	#endregion
	static emit = function(_sourceCode = "", _name = "", _kind = "script") {
		diagnostics = [];
		var _job = new GMLC_CompileJob(self, _sourceCode, _name, _kind, true, true);
		try {
			while (_job.step()) {}
		}
		catch (_e) {
		}
		return (_job.program == undefined) || __gmlc_has_errors(diagnostics) ? _sourceCode : _job.program;
	}
	
	#region jsDoc
	/// @func    compile_begin()
	/// @desc    Starts a compile that runs one stage per call of the job's step(), for a host that spreads a compile
	///          over frames: `var _job = env.compile_begin(src, "a.gml"); ... if (!_job.step()) run(_job.program);`.
	///          Gives the same program as compile(); a stage's error is thrown by the step that runs it, with the
	///          diagnostics in `diagnostics`. One job at a time per environment.
	/// @self    GMLC_Env
	/// @param   {String} sourceCode : Source text to compile
	/// @param   {String} [name]     : Name of the file, for positions
	/// @param   {String} [kind]     : "script" (default) or "event", as for compile
	/// @returns {Struct.GMLC_CompileJob}
	#endregion
	static compile_begin = function(_sourceCode = "", _name = "", _kind = "script") {
		diagnostics = [];
		return new GMLC_CompileJob(self, _sourceCode, _name, _kind, true, false);
	}
	
	#region jsDoc
	/// @func    compile_ast(_json)
	/// @desc    Compiles a syntax tree given in its JSON form (as gmlc_ast_to_json writes it):
	///          the tree is read back into nodes and the pipeline continues at the stage after the dump's
	///          (parsed, resolved, lowered or optimized), as for source text.
	/// @self    GMLC_Env
	/// @param   {String} json : The dump
	/// @returns {Any} Compiled program artifact produced by GMLC_Gen_6_Compiler
	#endregion
	static compile_ast = function(_json) {
		diagnostics = [];
		var _dump = gmlc_ast_from_json(_json);
		var _ast = _dump.root;
		var _sources = _dump.sources;
		sources = _sources;
		__unit_file = _ast.span.file;
		// a dump of stage S continues at the job stage after S
		var _job = new GMLC_CompileJob(self, "", "", _ast[$ "unit_kind"] ?? "script", true, false);
		_job.ast = _ast;
		_job.sources = _sources;
		switch (_dump.stage) {
			case "parsed": _job.stage = 3; break;
			case "resolved": _job.stage = 4; break;
			case "optimized": _job.stage = 6; break;
			default: _job.stage = 5; break;
		}
		try {
			while ((_job.stage < 5) && __compile_step(_job)) {}
		}
		catch (_e) {
			throw __withDiagnostics(_e, diagnostics);
		}
		while (__compile_step(_job)) {}
		return _job.program;
	}
	
	#region jsDoc
	/// @func    get()
	/// @desc    Fetch a function from the global struct
	/// @self    GMLC_Env
	/// @param   {String} func : The name of the function to get from the global struct
	/// @returns {Any} Compiled function artifact produced by GMLC_Gen_6_Compiler
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
	/// @func    enable_test_mode()
	/// @desc    Turns test mode on or off: on, constants that fail when they run are warnings instead of compile errors.
	/// @self    GMLC_Env
	/// @param   {Bool} shouldEnable : True to enable test mode, false to disable
	/// @returns {Struct.GMLC_Env}
	#endregion
	static enable_test_mode = function(_bool) {
		test_mode = _bool;
		return self;
	}
	
	#region jsDoc
	/// @func    foldsConfigMacros()
	/// @desc    Whether the macros that depend on the configuration may fold: the configuration is known and the
	///          output belongs to one build. Otherwise their uses stay opaque.
	/// @self    GMLC_Env
	/// @returns {Bool}
	#endregion
	static foldsConfigMacros = function() {
		return build_scoped && !config_unknown;
	}
	
	#region jsDoc
	/// @func    enableExtension(_name)
	/// @desc    Switches a language extension on: GMLC then accepts its construct (`?.`, `let`, ...) and turns it into
	///          plain GML. The built-in ones are nullish-chaining, macro-params, const, let and closure.
	/// @self    GMLC_Env
	/// @param   {String} _name : The extension's name
	/// @returns {Struct.GMLC_Env}
	#endregion
	static enableExtension = function(_name) {
		// the extensions switched on stay in registration order, the order their rewrites must run in
		var _registry = __gmlc_extension_registry();
		var _known = false;
		var _on = [];
		var _i = 0; repeat (array_length(_registry)) {
			var _extension = _registry[_i];
			if (_extension.name == _name) _known = true;
			if (_extension.name == _name) || array_contains(extensions, _extension) array_push(_on, _extension);
		_i++}
		if (!_known) {
			__gmlc_throw_diagnostics([new GMLC_Diagnostic("GMLC5008", new GMLC_Span(0, 0, 0), [_name])], undefined);
		}
		extensions = _on;
		return self;
	};
	
	#region jsDoc
	/// @func    disableExtension(_name)
	/// @desc    Switches a language extension off.
	/// @self    GMLC_Env
	/// @param   {String} _name : The extension's name
	/// @returns {Struct.GMLC_Env}
	#endregion
	static disableExtension = function(_name) {
		var _i = 0; repeat (array_length(extensions)) {
			if (extensions[_i].name == _name) {
				array_delete(extensions, _i, 1);
				break;
			}
		_i++}
		return self;
	};
	
	#region jsDoc
	/// @func    isExtensionEnabled(_name)
	/// @desc    Whether a language extension is switched on.
	/// @self    GMLC_Env
	/// @param   {String} _name : The extension's name
	/// @returns {Bool}
	#endregion
	static isExtensionEnabled = function(_name) {
		var _i = 0; repeat (array_length(extensions)) {
			if (extensions[_i].name == _name) return true;
		_i++}
		return false;
	};
	
	#region jsDoc
	/// @func    set_debug()
	/// @desc    Switches the debug executors on or off for the programs compiled from now on. A function whose body has
	///          `gml_pragma("gmlc_release_mode")` always runs the fast ones.
	/// @self    GMLC_Env
	/// @param   {Bool} [_on] : Whether debug executors are used (default true)
	/// @returns {Struct.GMLC_Env}
	#endregion
	static set_debug = function(_on=true) {
		debug = _on;
		return self;
	};
	
	#region jsDoc
	/// @func    set_exposure()
	/// @desc    Convenience method that applies the selected exposure tier by invoking expose_constants(), expose_user_assets(), and expose_functions() accordingly.
	///          The functions, constants and enums exposed before are removed first, so the exposed set depends only on
	///          the tier, never on the tiers set before. Call it before exposing the host's own functions and
	///          constants, which it would remove too.
	/// @self    GMLC_Env
	/// @param   {GMLC_EXPOSURE} exposureLevel : Exposure tier (NONE, SAFE, MODERATE, ALL, FULL, NATIVE)
	/// @returns {Struct.GMLC_Env}
	#endregion
	static set_exposure = function(_expose_level=GMLC_EXPOSURE.SAFE) {
		clearFunctions();
		clearConstants();
		clearEnums();
		expose_constants(_expose_level);
		expose_user_assets(_expose_level);
		expose_functions(_expose_level);
		
		return self;
	}
	
	#region Specific Exposures
	
	#region jsDoc
	/// @func    expose_constants()
	/// @desc    Exposes core engine constants from the spec and selected build metadata. When exposureLevel is FULL, also exposes the real global object as a constant named "global"; otherwise exposes an empty struct.
	///          NONE exposes nothing; the project's enums are exposed where its assets are.
	/// @self    GMLC_Env
	/// @param   {GMLC_EXPOSURE} exposureLevel : Exposure tier used
	/// @returns {Struct.GMLC_Env}
	#endregion
	static expose_constants = function(_expose_level=GMLC_EXPOSURE.SAFE) {
		if (_expose_level == GMLC_EXPOSURE.NONE) return self;
		var _spec = __gmlc_built_ins();
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
		if (__exposesUser(_expose_level)) exposeEnums(__GmlcDataEnums());
		
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
		if (!__exposesUser(_expose_level)) return self;
		
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
	///          - PURE: pure built-ins that pass safety filter, plus overwrite shims
	///          - SAFE: pure built-ins that pass safety filter, plus overwrite shims
	///          - MODERATE: currently same as SAFE (pending spec/policy expansion), plus overwrite shims
	///          - ALL: all native built-ins, plus overwrite shims
	///          - NATIVE: all native built-ins, plus overwrite shims
	///          - FULL: all native built-ins, user scripts, plus overwrite shims
	/// @self    GMLC_Env
	/// @param   {GMLC_EXPOSURE} exposureLevel : Exposure tier controlling function availability
	/// @returns {Struct.GMLC_Env}
	#endregion
	static expose_functions = function(_expose_level = GMLC_EXPOSURE.SAFE) {
		switch (_expose_level) {
			case GMLC_EXPOSURE.NONE: break;
			case GMLC_EXPOSURE.PURE:
			case GMLC_EXPOSURE.SAFE:
			case GMLC_EXPOSURE.MODERATE:
				expose_pure_functions();
				expose_overwrite_functions();
			break;
			case GMLC_EXPOSURE.ALL:
			case GMLC_EXPOSURE.NATIVE:
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
		var _spec = __gmlc_built_ins();
		var _map = struct_filter(_spec, function(_key, _val) {
			return (_val[$ "type"] == "envFunctions")
				&& (_val[$ "feather"][$ "pure"])
				&& __is_safe_function(_key, _val);
		});
		
		//var _arr = struct_get_names(_map)
		//array_sort(_arr, true)
		//pprint(_arr)
		
		importSymbolMap(_map);
		
		return self;
	}
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
			"nameof":             __gmlc_nameof, // `nameof(name)` is replaced by the name at compile time
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
		var _spec = __gmlc_built_ins();
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
	current_script_name = "";

	__log_path = "log.json"
	__log_tokenizer_results      = false;
	__log_pre_processer_results  = false;
	__log_parser_results         = false;
	__log_lower_results          = false;
	__log_optimizer_results      = false;
	__log_compiler_results       = false;
	
	__log_step_times = false;
	__log_optimizations = 0; // 0 nothing, 1 one line per compile counting changes by kind, 2 each change
	
	
	#region jsDoc
	/// @func    __exposesUser(_expose_level)
	/// @desc    Whether a tier exposes the project's assets and enums.
	/// @ignore
	#endregion
	static __exposesUser = function(_expose_level) {
		return (_expose_level >= GMLC_EXPOSURE.SAFE) && (_expose_level <= GMLC_EXPOSURE.FULL);
	}
	
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
	/// @func    __hostMacroUnit()
	/// @desc    The exposed macros as a preprocessor unit, in name order. Each value is lexed on its own as
	///          the host gave it, so its tokens and line text are the host's own; a string is GML text, a number or
	///          bool is written as a literal; any other value is an error.
	/// @self    GMLC_Env
	/// @returns {Struct|Undefined} undefined when no macro is exposed
	/// @ignore
	#endregion
	static __hostMacroUnit = function() {
		var _macros = getAllMacros();
		var _names = struct_get_names(_macros);
		if (array_length(_names) == 0) return undefined;
		array_sort(_names, true);
		var _unit = { program: undefined, stream: [], macros: [], enums: [], regions: [], pragmas: [] };
		__host_files = [];
		var _i = 0; repeat (array_length(_names)) {
			var _name = _names[_i];
			var _value = _macros[$ _name].value;
			var _gml;
			if (is_string(_value)) {
				_gml = _value;
			}
			else if (is_int64(_value)) {
				_gml = string(_value);
			}
			else if (is_bool(_value)) {
				_gml = _value ? "true" : "false"; // a bool stays a bool (`string(true)` is "1")
			}
			else if (is_real(_value)) {
				_gml = __gmlc_real_text(_value);
			}
			else {
				__gmlc_throw_diagnostics([new GMLC_Diagnostic("GMLC5007", new GMLC_Span(array_length(__host_files), 0, 0), [_name, typeof(_value)])], undefined);
			}
			lexer.initialize(_gml, "<macro " + _name + ">", array_length(__host_files));
			var _program = lexer.parseAll();
			array_push(__host_files, _program.file);
			array_push(_unit.macros, pre_processor.hostMacro(_name, _program));
		_i++}
		return _unit;
	}
	
	#region jsDoc
	/// @func    __preprocess(_programs, _sources, _diagnostics)
	/// @desc    Runs the preprocessor over a batch of lexed files: collects every file, merges their definitions
	///          with the exposed macros (first) and the configuration chain, and expands every file. Every file is
	///          collected and expanded before an error stops the batch, so its errors do not depend on the file order.
	/// @self    GMLC_Env
	/// @param   {Array<Struct>}           programs : The lexer's program records, in batch order
	/// @param   {Struct.GMLC_SourceTable} sources  : The compile's files, for the positions of errors
	/// @param   {Array}                   diagnostics : Where the preprocessor's warnings go
	/// @returns {Array<Struct>} The same records, preprocessed
	/// @ignore
	#endregion
	static __preprocess = function(_programs, _sources, _diagnostics) {
		var _units = [];
		__updateHostMacros();
		pre_processor.sources = _sources;
		// tokens are never modified once made, so the exposed macros' definitions are reused by every compile
		if (__host_unit != undefined) array_push(_units, __host_unit);
		var _first = array_length(_units);
		var _i = 0; repeat (array_length(_programs)) {
			array_push(_units, pre_processor.collect(_programs[_i]));
			__gather(_diagnostics, pre_processor);
		_i++}
		if (__gmlc_has_errors(_diagnostics)) __gmlc_throw_diagnostics(_diagnostics, _sources);
		var _batch = pre_processor.merge(_units, config_chain);
		__gather(_diagnostics, pre_processor);
		_i = 0; repeat (array_length(_programs)) {
			pre_processor.expand(_units[_first + _i], _batch);
			__gather(_diagnostics, pre_processor);
		_i++}
		if (__gmlc_has_errors(_diagnostics)) __gmlc_throw_diagnostics(_diagnostics, _sources);
		return _programs;
	}
	
	#region jsDoc
	/// @func    __updateHostMacros()
	/// @desc    Rebuilds the exposed macros' definitions when they changed.
	/// @self    GMLC_Env
	/// @ignore
	#endregion
	static __updateHostMacros = function() {
		if (__host_macros_dirty) {
			__host_files = [];
			__host_unit = __hostMacroUnit();
			__host_macros_dirty = false;
		}
	}
	
	#region jsDoc
	/// @func    __newSourceTable()
	/// @desc    The source table of a new compile: the files of the exposed macros come first, so the files of the
	///          compile are numbered after them.
	/// @self    GMLC_Env
	/// @returns {Struct.GMLC_SourceTable}
	/// @ignore
	#endregion
	static __newSourceTable = function() {
		__updateHostMacros();
		var _sources = new GMLC_SourceTable();
		var _i = 0; repeat (array_length(__host_files)) {
			_sources.add(__host_files[_i]);
		_i++}
		return _sources;
	}
	
	#region Compile Steps
	#region jsDoc
	/// @func    __new_anonymous_script_name()
	/// @desc    The name of a source compiled without one: `gml_Script_anon@<n>`, numbered across environments.
	/// @self    GMLC_Env
	/// @returns {String}
	/// @ignore
	#endregion
	static __new_anonymous_script_name = function() {
		static __anonymous_script_id = 0;
		return $"gml_Script_anon@{__anonymous_script_id++}";
	}

	#region jsDoc
	/// @func    __resolve_compile_source_name(_name, [_fallback])
	/// @desc    The name a source is compiled as: its own, else the fallback, else a new anonymous name.
	/// @self    GMLC_Env
	/// @param   {String} _name       : The name given
	/// @param   {String} [_fallback] : The name to use when none is given
	/// @returns {String}
	/// @ignore
	#endregion
	static __resolve_compile_source_name = function(_name, _fallback = undefined) {
		if (is_string(_name) && _name != "") return _name;
		if (is_string(_fallback) && _fallback != "") return _fallback;
		return __new_anonymous_script_name();
	}
	
	#region jsDoc
	/// @func    __compile_step()
	/// @desc    Runs the next stage of a compile job; whether stages remain.
	/// @ignore
	#endregion
	static __compile_step = function(_job) {
		var _step_time = get_timer();
		var _sources = _job.sources;
		var _stage = _job.stage++;
		switch (_stage) {
			case 0: {
				current_script_name = __resolve_compile_source_name(_job.name);
				_sources = __newSourceTable();
				_job.sources = _sources;
				sources = _sources;
				__unit_file = array_length(_sources.files);
				lexer.initialize(_job.source, current_script_name, __unit_file);
				_sources.add(lexer.program.file); // before lexing, so a lexer error has its file
				_job.tokens = lexer.parseAll();
				__gather(diagnostics, lexer);
				_job.tokens.sources = _sources;
				if (__log_tokenizer_results) __gmlc_json_save("tokenizer.json", _job.tokens)
				if (__log_step_times) show_debug_message($"Tokenizer Time took : {(get_timer() - _step_time)/1000}ms")
			break;}
			case 1: {
				__preprocess([_job.tokens], _sources, diagnostics);
				if (__log_pre_processer_results) __gmlc_json_save("pre_processor.json", _job.tokens)
				if (__log_step_times) show_debug_message($"Pre Processor Time took : {(get_timer() - _step_time)/1000}ms")
			break;}
			case 2: {
				parser.initialize(_job.tokens, _job.kind);
				_job.ast = parser.parseAll();
				__gather(diagnostics, parser);
				_job.ast.unit_kind = _job.kind;
				if (__log_parser_results) __gmlc_json_save("parser.json", _job.ast)
				if (__log_step_times) show_debug_message($"Parser Time took : {(get_timer() - _step_time)/1000}ms")
			break;}
			case 3: {
				resolver.initialize(_job.ast, _sources);
				_job.ast = resolver.parseAll();
				__gather(diagnostics, resolver);
				if (__log_step_times) show_debug_message($"Resolver Time took : {(get_timer() - _step_time)/1000}ms")
			break;}
			case 4: {
				lower.initialize(_job.ast, _sources);
				_job.ast = lower.parseAll();
				__gather(diagnostics, lower);
				var _errors = __resolveEnums([_job.ast], _sources, [diagnostics]);
				var _error = _errors[0];
				if (_error != undefined) throw _error;
				if (__log_lower_results) __gmlc_json_save("lowered.json", _job.ast)
				if (__log_step_times) show_debug_message($"Lower Time took : {(get_timer() - _step_time)/1000}ms")
				if (!_job.compile) return false;
			break;}
			case 5: {
				if (_job.emit) {
					if (should_optimize) _job.ast = __optimize(_job.ast, _sources, diagnostics, "gml");
					_job.program = emitter.emit(_job.ast, _job.tokens);
					return false;
				}
				_job.ast = __optimize(_job.ast, _sources, diagnostics);
				if (__log_optimizer_results) __gmlc_json_save("optimizer.json", _job.ast)
				if (__log_step_times) show_debug_message($"{should_optimize ? "Optimizer" : "Constant folding"} Time took : {(get_timer() - _step_time)/1000}ms")
			break;}
			case 6: {
				var _global = getConstant("global");
				var _globals = (is_struct(_global)) ? _global.value : {};
				compiler.initialize(_job.ast, _globals, _sources);
				_job.program = compiler.parseAll();
				if (__log_compiler_results) __gmlc_json_save("compiled.json", _job.ast)
				if (__log_step_times) show_debug_message($"Compile Time took : {(get_timer() - _step_time)/1000}ms")
				return false;
			}
		}
		return true;
	}

	#region jsDoc
	/// @func    __gather()
	/// @desc    Adds a stage's diagnostics to a list.
	/// @ignore
	#endregion
	static __gather = function(_list, _stage) {
		var _found = _stage.diagnostics;
		array_copy(_list, array_length(_list), _found, 0, array_length(_found));
	}
	
	#region jsDoc
	/// @func    __optimize(_ast, _sources, _diagnostics, [_back_end])
	/// @desc    Constant folding runs in every compile, the other optimizations only when should_optimize is on; the
	///          target passes run for the back end the tree goes to.
	/// @ignore
	#endregion
	static __optimize = function(_ast, _sources, _diagnostics, _back_end = "runtime") {
		optimizer.mode = should_optimize ? GMLC_OPTIMIZE.ALL : GMLC_OPTIMIZE.FOLD;
		optimizer.back_end = _back_end;
		optimizer.initialize(_ast, _sources);
		_ast = optimizer.parseAll();
		__gatherOrThrow(_diagnostics, optimizer, _sources);
		return _ast;
	}
	
	#region jsDoc
	/// @func    __gatherOrThrow(_list, _stage, _sources)
	/// @desc    Adds a stage's diagnostics to a list, or throws them when one is an error.
	/// @self    GMLC_Env
	/// @param   {Array<Struct.GMLC_Diagnostic>} _list    : The list
	/// @param   {Struct}                        _stage   : The stage that ran
	/// @param   {Struct.GMLC_SourceTable}       _sources : The compile's files
	/// @ignore
	#endregion
	static __gatherOrThrow = function(_list, _stage, _sources) {
		var _found = _stage.diagnostics;
		if (__gmlc_has_errors(_found)) __gmlc_throw_diagnostics(_found, _sources);
		array_copy(_list, array_length(_list), _found, 0, array_length(_found));
	}
	
	#region jsDoc
	/// @func    __finishDiagnostics()
	/// @desc    Applies the suppression comments to the compile's diagnostics and sorts them.
	/// @self    GMLC_Env
	/// @ignore
	#endregion
	static __finishDiagnostics = function() {
		diagnostics = __gmlc_sort_diagnostics(__gmlc_suppress_diagnostics(diagnostics, sources));
	}

	#region jsDoc
	/// @func    __withDiagnostics()
	/// @desc    What a compile throws: a stage's error struct gets every diagnostic of the compile under `diagnostics`;
	///          anything else a stage threw is a fault of GMLC, kept as GMLC5901 at the start of the unit and thrown on.
	/// @ignore
	#endregion
	static __withDiagnostics = function(_error, _list) {
		if (is_struct(_error)) && is_array(_error[$ "diagnostics"]) {
			if (_error.diagnostics != _list) array_copy(_list, array_length(_list), _error.diagnostics, 0, array_length(_error.diagnostics));
			_error.diagnostics = __gmlc_sort_diagnostics(_list);
			return _error;
		}
		var _message = is_struct(_error) ? string(_error[$ "message"] ?? _error) : string(_error);
		array_push(_list, new GMLC_Diagnostic("GMLC5901", new GMLC_Span(__unit_file, 0, 0), [_message]));
		return _error;
	}
	#endregion
	
	#endregion
	
	#region Batch & Project Compilation
	
	#region jsDoc
	/// @func    __lower_unit(_program, _log_name, _ast, _batchGlobals, _diagnostics)
	/// @desc    Resolves and lowers one parsed file of a batch.
	/// @self    GMLC_Env
	/// @param   {Struct}                        _program      : The file's lexer record
	/// @param   {String}                        _log_name     : The file's name
	/// @param   {Struct.ASTScript}              _ast          : Its tree
	/// @param   {Struct}                        _batchGlobals : The batch's global names
	/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics  : Where the stages' warnings go
	/// @returns {Struct.ASTScript}
	/// @ignore
	#endregion
	static __lower_unit = function(_program, _log_name, _ast, _batchGlobals, _diagnostics) {
		current_script_name = __resolve_compile_source_name(_log_name, _program.file_name);
		var _sources = _program[$ "sources"];
		resolver.initialize(_ast, _sources, _batchGlobals);
		_ast = resolver.parseAll();
		__gather(_diagnostics, resolver);
		lower.initialize(_ast, _sources);
		_ast = lower.parseAll();
		__gather(_diagnostics, lower);
		return _ast;
	}
	
	#region jsDoc
	/// @func    __compile_unit(_program, _log_name, _ast, _diagnostics)
	/// @desc    Optimizes and compiles one lowered file of a batch.
	/// @self    GMLC_Env
	/// @param   {Struct}                        _program     : The file's lexer record
	/// @param   {String}                        _log_name    : The file's name
	/// @param   {Struct.ASTScript}              _ast         : Its tree
	/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : Where the stages' warnings go
	/// @returns {Struct.ASTScript}
	/// @ignore
	#endregion
	static __compile_unit = function(_program, _log_name, _ast, _diagnostics) {
		current_script_name = __resolve_compile_source_name(_log_name, _program.file_name);
		var _sources = _program[$ "sources"];
		_ast = __optimize(_ast, _sources, _diagnostics);
		var _global  = getConstant("global");
		var _globals = is_struct(_global) ? _global.value : {};
		compiler.initialize(_ast, _globals, _sources);
		compiler.parseAll();
		return _ast;
	}

	#region jsDoc
	/// @func    __logUnits(_units, _field, _suffix)
	/// @desc    Saves one field of every file of a batch that has no error to a JSON file, for debugging.
	/// @self    GMLC_Env
	/// @param   {Array<Struct>} _units  : The batch's files
	/// @param   {String}        _field  : The field to save
	/// @param   {String}        _suffix : The end of each file's name
	/// @ignore
	#endregion
	static __logUnits = function(_units, _field, _suffix) {
		var _i = 0; repeat (array_length(_units)) {
			var _value = _units[_i][$ _field];
			if (_value != undefined) && (_units[_i].error == undefined) __gmlc_json_save(filename_name(_units[_i].name) + _suffix, _value);
		_i++}
	}
	
	#region jsDoc
	/// @func    __resolveEnums(_asts, _sources, _lists)
	/// @desc    Gives the enums of lowered files their values; each file's diagnostics
	///          go to its list, or, when one is an error, into the error that stops that file.
	/// @returns {Array} The error of each file, undefined for a file without one
	/// @ignore
	#endregion
	static __resolveEnums = function(_asts, _sources, _lists) {
		var _found = lower.resolveEnums(_asts, _sources);
		var _errors = array_create(array_length(_found), undefined);
		var _i = 0; repeat (array_length(_found)) {
			var _list = _found[_i];
			if (__gmlc_has_errors(_list)) {
				_errors[_i] = __gmlc_diagnostics_error(_list, _sources);
			}
			else {
				array_copy(_lists[_i], array_length(_lists[_i]), _list, 0, array_length(_list));
			}
		_i++}
		return _errors;
	};
	
	#region jsDoc
	/// @func    __compile_units()
	/// @desc    Compiles files as one batch: lexes each, preprocesses them together (macros and enums of every file),
	///          parses each, collects the global names of all of them, then resolves, lowers and compiles each. A file
	///          that fails is recorded with its error and diagnostics and the others go on; a preprocessor error fails
	///          every file, as the batch's definitions are shared.
	/// @ignore
	#endregion
	static __compile_units = function(_entries, _project) {
		var _count = array_length(_entries);
		var _result = new GMLC_BatchResult();
		diagnostics = [];
		var _table;
		try {
			_table = __newSourceTable();
		}
		catch (_e) {
			// the exposed macros do not lex: no file of the batch can be compiled
			var _error = __withDiagnostics(_e, diagnostics);
			__finishDiagnostics();
			var _f = 0; repeat (_count) {
				_result.add(_entries[_f].name, false, _error, diagnostics);
			_f++}
			return _result;
		}
		sources = _table;
		var _units = []; // {name, program, ast, diagnostics, error}
		
		var _i = 0; repeat (_count) {
			var _unit = { name: _entries[_i].name, kind: _entries[_i][$ "kind"] ?? "script", program: undefined, ast: undefined, diagnostics: [], error: undefined, file: array_length(_table.files) };
			current_script_name = _unit.name;
			__unit_file = _unit.file;
			try {
				lexer.initialize(_entries[_i].source, current_script_name, __unit_file);
				// added before lexing: a file that does not lex keeps its number, so the other files' spans stay right
				lexer.program.file.project = _project;
				_table.add(lexer.program.file);
				_unit.program = lexer.parseAll();
				__gather(_unit.diagnostics, lexer);
				_unit.program.sources = _table;
			}
			catch (_e) {
				_unit.error = __withDiagnostics(_e, _unit.diagnostics);
			}
			array_push(_units, _unit);
		_i++}
		if (__log_tokenizer_results) __logUnits(_units, "program", "_tokenizer.json");
		
		var _programs = [];
		var _live = [];
		_i = 0; repeat (_count) {
			if (_units[_i].error == undefined) {
				array_push(_programs, _units[_i].program);
				array_push(_live, _units[_i]);
			}
		_i++}
		var _batchDiagnostics = [];
		// a fault of GMLC here belongs to the batch, not to the last file lexed
		__unit_file = array_length(_table.files);
		try {
			__preprocess(_programs, _table, _batchDiagnostics);
		}
		catch (_e) {
			var _error = __withDiagnostics(_e, _batchDiagnostics);
			_i = 0; repeat (array_length(_live)) {
				_live[_i].error = _error;
			_i++}
			_live = [];
		}
		// each preprocessor diagnostic goes to the file it is in; one in an exposed macro's text belongs to no file of
		// the batch and is kept with the batch's own
		var _unrouted = [];
		_i = 0; repeat (array_length(_batchDiagnostics)) {
			var _d = _batchDiagnostics[_i];
			var _routed = false;
			var _j = 0; repeat (array_length(_units)) {
				var _program = _units[_j].program;
				if (_program != undefined) && (_program.file.file_id == _d.span.file) {
					array_push(_units[_j].diagnostics, _d);
					_routed = true;
				}
			_j++}
			if (!_routed) array_push(_unrouted, _d);
		_i++}
		
		var _parsed = [];
		_i = 0; repeat (array_length(_live)) {
			var _unit = _live[_i];
			current_script_name = _unit.name;
			__unit_file = _unit.program.file.file_id;
			try {
				parser.initialize(_unit.program, _unit.kind);
				_unit.ast = parser.parseAll();
				__gather(_unit.diagnostics, parser);
				// an object event's top-level functions are methods of the instance, not global functions
				_unit.ast.unit_kind = _unit.kind;
				array_push(_parsed, _unit.ast);
			}
			catch (_e) {
				_unit.error = __withDiagnostics(_e, _unit.diagnostics);
			}
		_i++}
		if (__log_parser_results) __logUnits(_live, "ast", "_parser.json");
		var _globals = undefined;
		__unit_file = array_length(_table.files);
		try {
			_globals = resolver.collectGlobals(_parsed);
		}
		catch (_e) {
			var _error = __withDiagnostics(_e, _unrouted);
			_i = 0; repeat (array_length(_live)) {
				_live[_i].error ??= _error;
			_i++}
		}
		_i = 0; repeat (array_length(_live)) {
			var _unit = _live[_i];
			if (_unit.error == undefined) {
				__unit_file = _unit.program.file.file_id;
				try {
					_unit.ast = __lower_unit(_unit.program, _unit.name, _unit.ast, _globals, _unit.diagnostics);
				}
				catch (_e) {
					_unit.error = __withDiagnostics(_e, _unit.diagnostics);
				}
			}
		_i++}
		if (__log_lower_results) __logUnits(_live, "ast", "_lowered.json");
		
		// the enums of every file get their values together: a file may use the enum of another
		var _lowered = [];
		var _owners = [];
		var _lists = [];
		_i = 0; repeat (array_length(_live)) {
			var _unit = _live[_i];
			if (_unit.error == undefined) {
				array_push(_lowered, _unit.ast);
				array_push(_owners, _unit);
				array_push(_lists, _unit.diagnostics);
			}
		_i++}
		var _errors = __resolveEnums(_lowered, _table, _lists);
		__prepareBatch(_lowered, _table, __batch_project, __batch_external, _lists);
		_i = 0; repeat (array_length(_owners)) {
			if (_errors[_i] != undefined) _owners[_i].error = __withDiagnostics(_errors[_i], _owners[_i].diagnostics);
		_i++}
		
		_i = 0; repeat (array_length(_live)) {
			var _unit = _live[_i];
			if (_unit.error == undefined) {
				__unit_file = _unit.program.file.file_id;
				try {
					_unit.ast = __compile_unit(_unit.program, _unit.name, _unit.ast, _unit.diagnostics);
				}
				catch (_e) {
					_unit.error = __withDiagnostics(_e, _unit.diagnostics);
				}
			}
		_i++}
		if (__log_optimizer_results) __logUnits(_live, "ast", "_optimizer.json");
		
		_i = 0; repeat (_count) {
			var _unit = _units[_i];
			_unit.diagnostics = __gmlc_sort_diagnostics(__gmlc_suppress_diagnostics(_unit.diagnostics, sources, _unit.file));
			array_copy(diagnostics, array_length(diagnostics), _unit.diagnostics, 0, array_length(_unit.diagnostics));
			_result.add(_unit.name, _unit.error == undefined, _unit.error, _unit.diagnostics);
		_i++}
		array_copy(diagnostics, array_length(diagnostics), _unrouted, 0, array_length(_unrouted));
		diagnostics = __gmlc_sort_diagnostics(diagnostics);
		__endBatch();
		return _result;
	}
	
	#region jsDoc
	/// @func    __prepareBatch(_lowered, _sources, _project, _external, _lists)
	/// @desc    Works out what the files of a batch tell each other before any of them is optimized: whether any calls
	///          math_set_epsilon (then no file folds comparisons of reals), the macros with a definition per
	///          configuration, and the types of the batch's functions (gmlc_type_batch). In a whole project a JSDoc
	///          type that does not take what the project passes and a return type its JSDoc does not take are
	///          warnings, an operation that always throws an error; each goes into the list of its file.
	/// @self    GMLC_Env
	/// @param   {Array<Struct.ASTScript>} _lowered  : The lowered scripts
	/// @param   {Struct.GMLC_SourceTable} _sources  : Their files
	/// @param   {Bool}                    _project  : Whether the batch is a whole project
	/// @param   {Array<String>}           _external : Function names resources call by name
	/// @param   {Array<Array>}            _lists    : The diagnostics list of each lowered script
	#endregion
	static __prepareBatch = function(_lowered, _sources, _project, _external, _lists) {
		var _epsilon = [];
		var _i = 0; repeat (array_length(_lowered)) {
			optimizer.__epsilonCalls(_lowered[_i], _epsilon);
		_i++}
		__batch_epsilon = (array_length(_epsilon) > 0);
		__scoped_macros = optimizer.scopedMacros(_lowered);
		__batch = gmlc_type_batch(_lowered, _sources, _project, _external);
		if (!_project) return;
		var _found = [];
		var _mismatches = gmlc_type_jsdoc_mismatches(_lowered, _sources, __batch);
		_i = 0; repeat (array_length(_mismatches)) {
			array_push(_found, { code: "GMLC3018", span: _mismatches[_i].span, args: _mismatches[_i].args });
		_i++}
		var _typed = gmlc_type_diagnostics(_lowered, _sources, __batch);
		array_copy(_found, array_length(_found), _typed, 0, array_length(_typed));
		_i = 0; repeat (array_length(_found)) {
			var _d = _found[_i];
			var _k = 0; repeat (array_length(_lowered)) {
				if (_lowered[_k].span.file == _d.span.file) array_push(_lists[_k], new GMLC_Diagnostic(_d.code, _d.span, _d.args));
			_k++}
		_i++}
	};
	
	#region jsDoc
	/// @func    __endBatch()
	/// @desc    Forgets what __prepareBatch worked out.
	/// @self    GMLC_Env
	#endregion
	static __endBatch = function() {
		__batch_epsilon = false;
		__scoped_macros = {};
		__batch = __gmlc_type_batch_empty();
	};
	
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
		var _entries = array_create(array_length(_sources), undefined);
		var _i = 0; repeat (array_length(_sources)) {
			var _entry = _sources[_i];
			var _name = is_string(_entry) ? undefined : _entry[$ "name"];
			_entries[_i] = { name: __resolve_compile_source_name(_name), source: is_string(_entry) ? _entry : _entry.source };
		_i++}
		return __compile_units(_entries, undefined);
	}

	#region jsDoc
	/// @func    __compile_script_asset(_yy, _asset_dir, _result)
	/// @desc    Compiles a script asset's .gml into a batch result.
	/// @self    GMLC_Env
	/// @param   {Struct}                  _yy        : The asset's .yy
	/// @param   {String}                  _asset_dir : Its folder
	/// @param   {Struct.GMLC_BatchResult} _result    : Receives the outcome
	/// @ignore
	#endregion
	static __compile_script_asset = function(_yy, _asset_dir, _result) {
		var _name     = _yy.name;
		var _gml_path = _asset_dir + _name + ".gml";
		var _source   = __gmlc_file_read_text(_gml_path);
		if (_source == undefined) {
			_result.add(_name, false, { message: $"Could not read file: {_gml_path}" });
			return;
		}
		__merge_result(_result, __compile_units([{ name: _name, source: _source }], undefined));
	}

	#region jsDoc
	/// @func    __compile_object_asset(_yy, _asset_dir, _result)
	/// @desc    Compiles every event of an object asset as one batch into a batch result.
	/// @self    GMLC_Env
	/// @param   {Struct}                  _yy        : The asset's .yy
	/// @param   {String}                  _asset_dir : Its folder
	/// @param   {Struct.GMLC_BatchResult} _result    : Receives the outcome
	/// @ignore
	#endregion
	static __compile_object_asset = function(_yy, _asset_dir, _result) {
		var _obj_name = _yy.name;
		var _files    = __gmlc_find_files(_asset_dir, "gml");
		var _entries  = [];
		var _i = 0; repeat(array_length(_files)) {
			var _gml_path = _files[_i];
			array_push(_entries, { name: _obj_name + "::" + filename_name(_gml_path), source: __gmlc_file_read_text(_gml_path), kind: "event" });
		_i++;}
		__merge_result(_result, __compile_units(_entries, undefined));
	}
	
	#region jsDoc
	/// @func    __merge_result(_into, _from)
	/// @desc    Adds every entry of one batch result to another.
	/// @self    GMLC_Env
	/// @param   {Struct.GMLC_BatchResult} _into : Receives the entries
	/// @param   {Struct.GMLC_BatchResult} _from : Gives them
	/// @ignore
	#endregion
	static __merge_result = function(_into, _from) {
		var _i = 0; repeat (array_length(_from.entries)) {
			var _e = _from.entries[_i];
			_into.add(_e.name, _e.success, _e.error, _e.diagnostics);
		_i++}
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
		var _yy     = __gmlc_json_parse_loose(_yy_string);
		var _type   = _yy.resourceType;
		var _result = new GMLC_BatchResult();
		if (_type == "GMScript") {
			__compile_script_asset(_yy, _asset_dir, _result);
		}
		else if (_type == "GMObject") {
			__compile_object_asset(_yy, _asset_dir, _result);
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
	/// @func    __resourceCallNames(_text, _into, _seen)
	/// @desc    Adds every string of a resource's .yy text that is an identifier and no key of the format: the names the
	///          resource may call a function by.
	/// @self    GMLC_Env
	/// @param   {String}        _text : The .yy text
	/// @param   {Array<String>} _into : Receives the names not in it yet
	/// @param   {Struct}        _seen : The names in `_into`, as keys
	/// @ignore
	#endregion
	static __resourceCallNames = function(_text, _into, _seen) {
		var _parts = string_split(_text, "\"");
		var _i = 1; repeat (array_length(_parts) div 2) {
			var _part = _parts[_i];
			if (_part != "") && (!struct_exists(_seen, _part)) {
				var _bare = string_replace_all(_part, "_", "");
				var _next = (_i + 1 < array_length(_parts)) ? string_trim_start(_parts[_i + 1]) : "";
				if (string_digits(string_char_at(_part, 1)) == "") && (string_lettersdigits(_bare) == _bare) && (string_char_at(_next, 1) != ":") {
					_seen[$ _part] = true;
					array_push(_into, _part);
				}
			}
		_i += 2}
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
		var _yyp       = __gmlc_json_parse_loose(_yyp_string);
		var _resources = _yyp.resources;
		var _count     = array_length(_resources);
		var _entries   = []; // {source, name} for every code file in the project
		var _external  = []; // function names a resource calls by name (sequence moments, broadcasts, ...)
		var _external_seen = {};

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
			var _yy_str    = __gmlc_file_read_text(_root_path + _rel_path);
			if (_yy_str == undefined) { _i++; continue; }
			var _yy   = __gmlc_json_parse_loose(_yy_str);
			var _type = _yy.resourceType;

			if (_type == "GMScript") {
				var _source = __gmlc_file_read_text(_asset_dir + _yy.name + ".gml");
				if (_source != undefined) array_push(_entries, { source: _source, name: _yy.name });
			}
			else if (_type == "GMObject") {
				var _files = __gmlc_find_files(_asset_dir, "gml");
				var _j = 0; repeat(array_length(_files)) {
					var _source = __gmlc_file_read_text(_files[_j]);
					if (_source != undefined) array_push(_entries, { source: _source, name: _yy.name + "::" + filename_name(_files[_j]), kind: "event" });
				_j++;}
			}
			else if (variable_struct_exists(_yy, "name") && is_string(_yy.name)) {
				var _sym = {};
				_sym[$ _yy.name] = 0;
				exposeConstants(_sym);
			}
			if (infer_project) && (_type != "GMScript") __resourceCallNames(_yy_str, _external, _external_seen);
		_i++;}

		var _project = (struct_exists(_yyp, "name") && is_string(_yyp.name)) ? _yyp.name : undefined;
		__batch_project = infer_project;
		__batch_external = _external;
		var _result = __compile_units(_entries, _project);
		__batch_project = false;
		__batch_external = [];
		return _result;
	}

	#endregion

}

#region jsDoc
/// @func    GMLC_CompileJob(_env, _source, _name, _kind, _compile, _emit)
/// @desc    A compile that runs one stage per step() (GMLC_Env.compile_begin). `program` holds the compiled program
///          once step() has returned false.
/// @param   {Struct.GMLC_Env} _env     : The environment that compiles
/// @param   {String}          _source  : Source text
/// @param   {String}          _name    : Name of the file
/// @param   {String}          _kind    : "script" or "event"
/// @param   {Bool}            _compile : false: stop after lowering
/// @param   {Bool}            _emit    : true: `program` is the emitted text
#endregion
function GMLC_CompileJob(_env, _source, _name, _kind, _compile, _emit) constructor {
	#region Init
	env = _env;
	source = _source;
	name = _name;
	kind = _kind;
	compile = _compile;
	emit = _emit;
	stage = 0;
	done = false;
	sources = undefined;
	tokens = undefined;
	ast = undefined;
	program = undefined;
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    step()
	/// @desc    Runs the next stage; false once `program` is ready, or after a stage threw.
	/// @returns {Bool}
	#endregion
	static step = function() {
		if (done) return false;
		try {
			done = !env.__compile_step(self);
		}
		catch (_e) {
			done = true;
			var _error = env.__withDiagnostics(_e, env.diagnostics);
			env.__finishDiagnostics();
			throw _error;
		}
		if (done) env.__finishDiagnostics();
		return !done;
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
        No assets, no constants and no functions (built-in or user-defined) are available.
    */

    PURE,
    /*
        Exposes native constants and built-in pure functions only: no side effects, no logging/UI,
        no engine state, time or global RNG (math helpers, deterministic string/array/struct transforms).
    */

    SAFE,
    /*
        Extends PURE with sandboxed side effects: show_debug_message, data structures and buffers created
        inside the sandbox, mutating caller-provided arrays/structs. No filesystem, networking, OS/environment,
        external_*, asset enumeration/reflection or access outside the sandbox registry. No user scripts.
    */

    MODERATE,
    /*
        Extends SAFE with random/time and access to assets and instances only through host-supplied
        allow-lists, sandbox-registered instances and sandbox-created resources. Still no filesystem,
        networking, OS/environment, external_* or global reflection/enumeration. No user scripts.
    */

    ALL,
    /*
        Exposes the entire native GML runtime, including file access, buffers, networking and system
        operations. A trusted runtime with full engine access, but user scripts are still excluded.
    */

    FULL,
    /*
        Unrestricted access to the entire engine plus automatic inclusion of all
        user-defined scripts, assets, and constants. No safety restrictions.
        Intended only for fully trusted environments.
    */

    NATIVE,
    /*
        The full native GML runtime with all built-in functions and constants, but no user assets,
        constants or scripts: a fully trusted GML environment kept isolated from global where possible.
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

