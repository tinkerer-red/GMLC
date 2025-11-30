function __GmlSpec() {
	static GmlSpec = undefined;
	static __parseFunctions = function(_arr, _config) {
		for (var _i = 0; _i < array_length(_arr); _i++) {
			var _node = _arr[_i];
			var _attr = _node[$ "attributes"];
			var _name = _attr[$ "Name"];
			if (!is_string(_name)) continue;

			var _description = "";
			var _parameters = [];

			var _children = _node[$ "children"];
			for (var j = 0; j < array_length(_children); j++) {
				var _child = _children[j];
				switch (_child[$ "type"]) {
					case "Description":
						_description = _child[$ "text"] ?? "";
						break;
					case "Parameter":
						var _paramAttr = _child[$ "attributes"];
						_parameters[array_length(_parameters)] = {
							name: _paramAttr[$ "Name"],
							type: _paramAttr[$ "Type"],
							optional: (_paramAttr[$ "Optional"] == "true"),
							description: _child[$ "text"] ?? ""
						};
						break;
				}
			}

			var _isDeprecated = (_attr[$ "Deprecated"] == "true");
			
			_config[$ _name] = {
				value: script_get_index(_name),
				type: "envFunctions",
				highlight: _isDeprecated ? "highlight.function.deprecated" : "highlight.function",
				feather: {
					description: _description,
					returnType: _attr[$ "ReturnType"],
					pure: (_attr[$ "Pure"] == "true"),
					deprecated: _isDeprecated,
					parameters: _parameters
				}
			};
		}
	};
	static __parseVariables = function(_arr, _config) {
		for (var _i = 0; _i < array_length(_arr); _i++) {
			var _node = _arr[_i];
			var _attr = _node[$ "attributes"];
			var _name = _attr[$ "Name"];
			if (!is_string(_name)) continue;

			var _description = _node[$ "text"] ?? "";
			var _isDeprecated = (_attr[$ "Deprecated"] == "true");
			var _isInstance = (_attr[$ "Instance"] == "true");
			var _type = _isInstance ? "envDynamicVar" : "envBuiltInVars";
			var _canRead = (_attr[$ "Get"] == "true");
			var _canWrite = (_attr[$ "Set"] == "true");

			var _getter = undefined;
			var _setter = undefined;

			if (_isInstance) {
				_getter = _canRead
					? method({ key: _name }, function() { return other[$ key]; })
					: method({ key: _name }, function() { throw "Symbol `" + key + "` is not readable"; });

				_setter = _canWrite
					? method({ key: _name }, function(v) { other[$ key] = v; })
					: method({ key: _name }, function() { throw "Can't set read-only symbol :: " + key; });
			}

			_config[$ _name] = {
				value: undefined,
				type: _type,
				getter: _getter,
				setter: _setter,
				highlight: _isDeprecated
					? (_isInstance ? "highlight.dynamic.deprecated" : "highlight.builtin.deprecated")
					: (_isInstance ? "highlight.dynamic" : "highlight.builtin"),
				feather: {
					description: _description,
					returnType: _attr[$ "Type"],
					deprecated: _isDeprecated,
					instance: _isInstance,
					canRead: _canRead,
					canWrite: _canWrite
				}
			};
		}
	};
	static __parseConstants = function(_arr, _config) {
		var _lookup_table = __ExistingConstants();

		for (var _i = 0; _i < array_length(_arr); _i++) {
			var _node = _arr[_i];
			var _attr = _node[$ "attributes"];
			var _name = _attr[$ "Name"];
			if (!is_string(_name)) continue;

			var _description = _node[$ "text"] ?? "";
			var _isDeprecated = (_attr[$ "Deprecated"] == "true");

			_config[$ _name] = {
				value: _lookup_table[$ _name],
				type: "envConstants",
				highlight: _isDeprecated ? "highlight.constant.deprecated" : "highlight.constant",
				feather: {
					description: _description,
					returnType: _attr[$ "Type"],
					class: _attr[$ "Class"] ?? undefined,
					deprecated: _isDeprecated
				}
			};
		}
	};
	static __parseEnumerations = function(_arr, _config) {
		for (var _i = 0; _i < array_length(_arr); _i++) {
			var _node = _arr[_i];
			var _enumName = _node[$ "attributes"][$ "Name"];
			if (!is_string(_enumName)) continue;

			var _members = {};
			var _children = _node[$ "children"];

			for (var j = 0; j < array_length(_children); j++) {
				var _child = _children[j];
				if (_child[$ "type"] != "Member") continue;

				var _attr = _child[$ "attributes"];
				var _name = _attr[$ "Name"];
				var _value = real(_attr[$ "Value"]);
				var _isDeprecated = (_attr[$ "Deprecated"] == "true");
				var _description = _child[$ "text"] ?? "";

				if (!is_string(_name)) continue;

				_members[$ _name] = {
					value: _value,
					highlight: _isDeprecated ? "highlight.enum.deprecated" : "highlight.enum",
					feather: {
						description: _description,
						deprecated: _isDeprecated
					}
				};
			}

			_config[$ _enumName] = {
				value: _members,
				type: "envEnums",
				highlight: "highlight.enum"
			};
		}
	};

	if (GmlSpec = undefined) {
		var _xml = file_read_all_text("GmlSpec.xml")
		var _spec = SnapFromXML(_xml)
		
		var _config = {};
		
		var _functions = undefined;
		var _variables = undefined;
		var _constants = undefined;
		var _enumerations = undefined;
		var _structures = undefined;
		
		var _children = _spec.children;
		for (var i = 0; i < array_length(_children); i++) {
			var child = _children[i];
			if (child[$ "type"] != "GameMakerLanguageSpec") continue;
			
			var grandChildren = child[$ "children"];
			for (var j = 0; j < array_length(grandChildren); j++) {
				var sub = grandChildren[j];
				switch(sub[$ "type"]) {
					case "Functions":    __parseFunctions(sub[$ "children"], _config); break;
					case "Variables":    __parseVariables(sub[$ "children"], _config); break;
					case "Constants":    __parseConstants(sub[$ "children"], _config); break;
					case "Enumerations": __parseEnumerations(sub[$ "children"], _config); break;
					
					case "Structures":
					default:
						continue;
				}
			}
		}
		
		GmlSpec = _config;
	}
	
	return GmlSpec;
}
__GmlSpec();
/*
function _type_contains(_str) {
	static __types = [
		"Id.AudioEmitter",
		"Id.AudioListener",
		"Id.AudioSyncGroup",
		"Id.BackgroundElement",
		"Id.BinaryFile",
		"Id.Buffer",
		"Id.Camera",
		"Id.DbgRef",
		"Id.DsList",
		"Id.DsMap",
		"Id.DsPriority",
		"Id.DsQueue",
		"Id.DsStack",
		"Id.EmitterIndex",
		"Id.ExternalCall",
		"Id.Gif",
		"Id.Instance",
		"Id.Layer",
		"Id.MpGrid",
		"Id.ParticleElement",
		"Id.ParticleEmitter",
		"Id.ParticleSystem",
		"Id.ParticleType",
		"Id.PhysicsIndex",
		"Id.PhysicsParticleGroup",
		"Id.Sampler",
		"Id.SequenceElement",
		"Id.Socket",
		"Id.Sound",
		"Id.Sound",
		"Id.SpriteElement",
		"Id.Surface",
		"Id.TextElement",
		"Id.TextFile",
		"Id.Texture",
		"Id.TileElementId",
		"Id.TileMapElement",
		"Id.TimeSource",
		"Id.Uniform",
		"Id.VertexBuffer",
		"Id.VertexFormat",
		"Function",
		"Asset",
		"Pointer.Texture",
		"Pointer.",
		"Id."
	]
	static __len = array_length(__types);
	var _types = __types;
	
	var _i=0; repeat(__len) {
		var _key = _types[_i];
		if (string_pos(_key, _str)) {
			return true
		}
	_i++}
	
	return false;
}

// Place holder code i frequently use to parse gml spec for information.
// this is not actually a part of gmlc for any real reason, feel free to leave commented or remove
//*
var _struct = __GmlSpec();
struct_foreach(_struct, function(_key, _value) {
	static __keywords = ["sound", "audio"];
	
	if (_value.type == "envFunctions") {
		var _name = _key;
		if (_name == "draw_primitive_begin_texture") {
			log("hold")
		}
		
		var _desc = _value.feather.description;
		var _return_type = _value.feather.returnType;
		
		static __closure = {};
		__closure.should_print = false;
		
		var _args = array_map(_value.feather.parameters, method(__closure, function(_elem, _index) {
			var _name = _elem.name;
			var _desc = _elem.description;
			var _type = _elem.type;
			
			if (_type_contains(_type)) {
				should_print = true;
			}
			
			return {
				name: _name,
				desc: _desc,
				type: _type
			}
		}))
		
		if (__closure.should_print || _type_contains(_return_type)) {
			show_debug_message(_name);
		}
		
	}
})
//*
var _handles = [
"ads_set_reward_callback",
"animcurve_exists",
"animcurve_get",
"animcurve_get_channel",
"array_all",
"array_any",
"array_copy_while",
"array_create_ext",
"array_filter",
"array_filter_ext",
"array_find_index",
"array_foreach",
"array_map",
"array_map_ext",
"array_reduce",
"asset_add_tags",
"asset_clear_tags",
"asset_get_tags",
"asset_has_any_tag",
"asset_has_tags",
"asset_remove_tags",
"audio_destroy_stream",
"audio_destroy_sync_group",
"audio_emitter_bus",
"audio_emitter_exists",
"audio_emitter_falloff",
"audio_emitter_free",
"audio_emitter_gain",
"audio_emitter_get_bus",
"audio_emitter_get_gain",
"audio_emitter_get_listener_mask",
"audio_emitter_get_pitch",
"audio_emitter_get_vx",
"audio_emitter_get_vy",
"audio_emitter_get_vz",
"audio_emitter_get_x",
"audio_emitter_get_y",
"audio_emitter_get_z",
"audio_emitter_pitch",
"audio_emitter_position",
"audio_emitter_set_listener_mask",
"audio_emitter_velocity",
"audio_exists",
"audio_free_buffer_sound",
"audio_get_master_gain",
"audio_get_name",
"audio_get_type",
"audio_group_get_gain",
"audio_group_is_loaded",
"audio_group_load",
"audio_group_load_progress",
"audio_group_name",
"audio_group_set_gain",
"audio_group_stop_all",
"audio_group_unload",
"audio_is_paused",
"audio_is_playing",
"audio_music_gain",
"audio_pause_sound",
"audio_pause_sync_group",
"audio_play_music",
"audio_queue_sound",
"audio_resume_sound",
"audio_resume_sync_group",
"audio_set_master_gain",
"audio_sound_gain",
"audio_sound_get_gain",
"audio_sound_get_listener_mask",
"audio_sound_get_loop",
"audio_sound_get_loop_end",
"audio_sound_get_loop_start",
"audio_sound_get_pitch",
"audio_sound_get_track_position",
"audio_sound_is_playable",
"audio_sound_length",
"audio_sound_loop",
"audio_sound_loop_end",
"audio_sound_loop_start",
"audio_sound_pitch",
"audio_sound_set_listener_mask",
"audio_sound_set_track_position",
"audio_start_sync_group",
"audio_stop_sound",
"audio_stop_sync_group",
"audio_sync_group_debug",
"audio_sync_group_get_track_pos",
"audio_sync_group_is_paused",
"audio_sync_group_is_playing",
"buffer_base64_decode_ext",
"buffer_base64_encode",
"buffer_compress",
"buffer_copy",
"buffer_copy_from_vertex_buffer",
"buffer_copy_stride",
"buffer_crc32",
"buffer_delete",
"buffer_exists",
"buffer_fill",
"buffer_get_address",
"buffer_get_alignment",
"buffer_get_size",
"buffer_get_surface",
"buffer_get_surface_depth",
"buffer_get_type",
"buffer_get_used_size",
"buffer_load_async",
"buffer_load_ext",
"buffer_load_partial",
"buffer_md5",
"buffer_peek",
"buffer_poke",
"buffer_read",
"buffer_resize",
"buffer_save",
"buffer_save_async",
"buffer_save_ext",
"buffer_seek",
"buffer_set_surface",
"buffer_set_surface_depth",
"buffer_set_used_size",
"buffer_sha1",
"buffer_tell",
"buffer_write",
"call_cancel",
"camera_apply",
"camera_copy_transforms",
"camera_destroy",
"camera_get_proj_mat",
"camera_get_view_angle",
"camera_get_view_border_x",
"camera_get_view_border_y",
"camera_get_view_height",
"camera_get_view_mat",
"camera_get_view_speed_x",
"camera_get_view_speed_y",
"camera_get_view_width",
"camera_get_view_x",
"camera_get_view_y",
"camera_set_begin_script",
"camera_set_default",
"camera_set_end_script",
"camera_set_proj_mat",
"camera_set_update_script",
"camera_set_view_angle",
"camera_set_view_border",
"camera_set_view_mat",
"camera_set_view_pos",
"camera_set_view_size",
"camera_set_view_speed",
"camera_set_view_target",
"collision_circle_list",
"collision_ellipse_list",
"collision_line_list",
"collision_point_list",
"collision_rectangle_list",
"dbg_button",
"dbg_checkbox",
"dbg_color",
"dbg_colour",
"dbg_drop_down",
"dbg_slider",
"dbg_slider_int",
"dbg_sprite",
"dbg_sprite_button",
"dbg_text",
"dbg_text_input",
"dbg_text_separator",
"dbg_watch",
"distance_to_object",
"draw_set_font",
"draw_skeleton",
"draw_skeleton_collision",
"draw_skeleton_instance",
"draw_skeleton_time",
"draw_sprite",
"draw_sprite_ext",
"draw_sprite_general",
"draw_sprite_part",
"draw_sprite_part_ext",
"draw_sprite_pos",
"draw_sprite_stretched",
"draw_sprite_stretched_ext",
"draw_sprite_tiled",
"draw_sprite_tiled_ext",
"draw_surface",
"draw_surface_ext",
"draw_surface_general",
"draw_surface_part",
"draw_surface_part_ext",
"draw_surface_stretched",
"draw_surface_stretched_ext",
"draw_surface_tiled",
"draw_surface_tiled_ext",
"draw_tile",
"draw_tilemap",
"ds_grid_to_mp_grid",
"ds_list_add",
"ds_list_clear",
"ds_list_copy",
"ds_list_delete",
"ds_list_destroy",
"ds_list_empty",
"ds_list_find_index",
"ds_list_find_value",
"ds_list_insert",
"ds_list_is_list",
"ds_list_is_map",
"ds_list_mark_as_list",
"ds_list_mark_as_map",
"ds_list_read",
"ds_list_replace",
"ds_list_set",
"ds_list_shuffle",
"ds_list_size",
"ds_list_sort",
"ds_list_write",
"ds_map_add",
"ds_map_add_list",
"ds_map_add_map",
"ds_map_clear",
"ds_map_copy",
"ds_map_delete",
"ds_map_destroy",
"ds_map_empty",
"ds_map_exists",
"ds_map_find_first",
"ds_map_find_last",
"ds_map_find_next",
"ds_map_find_previous",
"ds_map_find_value",
"ds_map_is_list",
"ds_map_is_map",
"ds_map_keys_to_array",
"ds_map_read",
"ds_map_replace",
"ds_map_replace_list",
"ds_map_replace_map",
"ds_map_secure_save",
"ds_map_secure_save_buffer",
"ds_map_set",
"ds_map_size",
"ds_map_values_to_array",
"ds_map_write",
"ds_priority_add",
"ds_priority_change_priority",
"ds_priority_clear",
"ds_priority_copy",
"ds_priority_delete_max",
"ds_priority_delete_min",
"ds_priority_delete_value",
"ds_priority_destroy",
"ds_priority_empty",
"ds_priority_find_max",
"ds_priority_find_min",
"ds_priority_find_priority",
"ds_priority_read",
"ds_priority_size",
"ds_priority_write",
"ds_queue_clear",
"ds_queue_copy",
"ds_queue_dequeue",
"ds_queue_destroy",
"ds_queue_empty",
"ds_queue_enqueue",
"ds_queue_head",
"ds_queue_read",
"ds_queue_size",
"ds_queue_tail",
"ds_queue_write",
"ds_stack_clear",
"ds_stack_copy",
"ds_stack_destroy",
"ds_stack_empty",
"ds_stack_pop",
"ds_stack_push",
"ds_stack_read",
"ds_stack_size",
"ds_stack_top",
"ds_stack_write",
"effect_create_layer",
"event_perform",
"event_perform_async",
"event_perform_object",
"external_call",
"file_bin_close",
"file_bin_position",
"file_bin_read_byte",
"file_bin_rewrite",
"file_bin_seek",
"file_bin_size",
"file_bin_write_byte",
"file_text_close",
"file_text_eof",
"file_text_eoln",
"file_text_read_real",
"file_text_read_string",
"file_text_readln",
"file_text_write_real",
"file_text_write_string",
"file_text_writeln",
"flexpanel_node_set_measure_function",
"font_cache_glyph",
"font_delete",
"font_enable_effects",
"font_enable_sdf",
"font_exists",
"font_get_bold",
"font_get_first",
"font_get_fontname",
"font_get_info",
"font_get_italic",
"font_get_last",
"font_get_name",
"font_get_sdf_enabled",
"font_get_sdf_spread",
"font_get_size",
"font_get_texture",
"font_get_uvs",
"font_replace_sprite",
"font_replace_sprite_ext",
"font_sdf_spread",
"font_set_cache_size",
"game_load_buffer",
"game_save_buffer",
"gif_add_surface",
"gif_save",
"gif_save_buffer",
"gpu_get_tex_filter_ext",
"gpu_get_tex_max_aniso_ext",
"gpu_get_tex_max_mip_ext",
"gpu_get_tex_min_mip_ext",
"gpu_get_tex_mip_bias_ext",
"gpu_get_tex_mip_enable_ext",
"gpu_get_tex_mip_filter_ext",
"gpu_get_tex_repeat_ext",
"gpu_get_texfilter_ext",
"gpu_get_texrepeat_ext",
"gpu_set_state",
"gpu_set_stencil_func",
"gpu_set_tex_filter_ext",
"gpu_set_tex_max_aniso_ext",
"gpu_set_tex_max_mip_ext",
"gpu_set_tex_min_mip_ext",
"gpu_set_tex_mip_bias_ext",
"gpu_set_tex_mip_enable_ext",
"gpu_set_tex_mip_filter_ext",
"gpu_set_tex_repeat_ext",
"gpu_set_texfilter_ext",
"gpu_set_texrepeat_ext",
"gpu_set_zfunc",
"http_request",
"iap_activate",
"iap_enumerate_products",
"iap_product_details",
"instance_activate_layer",
"instance_activate_object",
"instance_change",
"instance_deactivate_layer",
"instance_deactivate_object",
"instance_destroy",
"instance_exists",
"instance_id_get",
"instance_number",
"instance_place_list",
"instance_position_list",
"is_instanceof",
"json_encode",
"json_parse",
"json_stringify",
"layer_add_instance",
"layer_background_alpha",
"layer_background_blend",
"layer_background_change",
"layer_background_destroy",
"layer_background_exists",
"layer_background_get_alpha",
"layer_background_get_blend",
"layer_background_get_htiled",
"layer_background_get_index",
"layer_background_get_speed",
"layer_background_get_stretch",
"layer_background_get_visible",
"layer_background_get_vtiled",
"layer_background_get_xscale",
"layer_background_get_yscale",
"layer_background_htiled",
"layer_background_index",
"layer_background_speed",
"layer_background_sprite",
"layer_background_stretch",
"layer_background_visible",
"layer_background_vtiled",
"layer_background_xscale",
"layer_background_yscale",
"layer_clear_fx",
"layer_depth",
"layer_destroy",
"layer_destroy_instances",
"layer_element_move",
"layer_enable_fx",
"layer_exists",
"layer_fx_is_enabled",
"layer_get_all_elements",
"layer_get_depth",
"layer_get_fx",
"layer_get_hspeed",
"layer_get_name",
"layer_get_type",
"layer_get_visible",
"layer_get_vspeed",
"layer_get_x",
"layer_get_y",
"layer_has_instance",
"layer_hspeed",
"layer_particle_alpha",
"layer_particle_angle",
"layer_particle_blend",
"layer_particle_get_alpha",
"layer_particle_get_angle",
"layer_particle_get_blend",
"layer_particle_get_x",
"layer_particle_get_xscale",
"layer_particle_get_y",
"layer_particle_get_yscale",
"layer_particle_x",
"layer_particle_xscale",
"layer_particle_y",
"layer_particle_yscale",
"layer_script_begin",
"layer_script_end",
"layer_sequence_angle",
"layer_sequence_destroy",
"layer_sequence_exists",
"layer_sequence_get_angle",
"layer_sequence_get_headdir",
"layer_sequence_get_headpos",
"layer_sequence_get_instance",
"layer_sequence_get_length",
"layer_sequence_get_sequence",
"layer_sequence_get_speedscale",
"layer_sequence_get_x",
"layer_sequence_get_xscale",
"layer_sequence_get_y",
"layer_sequence_get_yscale",
"layer_sequence_headdir",
"layer_sequence_headpos",
"layer_sequence_is_finished",
"layer_sequence_is_paused",
"layer_sequence_pause",
"layer_sequence_play",
"layer_sequence_speedscale",
"layer_sequence_x",
"layer_sequence_xscale",
"layer_sequence_y",
"layer_sequence_yscale",
"layer_set_fx",
"layer_set_target_room",
"layer_set_visible",
"layer_shader",
"layer_sprite_alpha",
"layer_sprite_angle",
"layer_sprite_blend",
"layer_sprite_change",
"layer_sprite_destroy",
"layer_sprite_exists",
"layer_sprite_get_alpha",
"layer_sprite_get_angle",
"layer_sprite_get_blend",
"layer_sprite_get_index",
"layer_sprite_get_speed",
"layer_sprite_get_x",
"layer_sprite_get_xscale",
"layer_sprite_get_y",
"layer_sprite_get_yscale",
"layer_sprite_index",
"layer_sprite_speed",
"layer_sprite_x",
"layer_sprite_xscale",
"layer_sprite_y",
"layer_sprite_yscale",
"layer_text_alpha",
"layer_text_angle",
"layer_text_blend",
"layer_text_charspacing",
"layer_text_destroy",
"layer_text_exists",
"layer_text_font",
"layer_text_frameh",
"layer_text_framew",
"layer_text_get_alpha",
"layer_text_get_angle",
"layer_text_get_blend",
"layer_text_get_charspacing",
"layer_text_get_frameh",
"layer_text_get_framew",
"layer_text_get_halign",
"layer_text_get_linespacing",
"layer_text_get_origin",
"layer_text_get_paragraphspacing",
"layer_text_get_text",
"layer_text_get_valign",
"layer_text_get_wrap",
"layer_text_get_wrapmode",
"layer_text_get_x",
"layer_text_get_xorigin",
"layer_text_get_xscale",
"layer_text_get_y",
"layer_text_get_yorigin",
"layer_text_get_yscale",
"layer_text_halign",
"layer_text_linespacing",
"layer_text_origin",
"layer_text_paragraphspacing",
"layer_text_text",
"layer_text_valign",
"layer_text_wrap",
"layer_text_wrapmode",
"layer_text_x",
"layer_text_xorigin",
"layer_text_xscale",
"layer_text_y",
"layer_text_yorigin",
"layer_text_yscale",
"layer_tile_alpha",
"layer_tile_blend",
"layer_tile_change",
"layer_tile_destroy",
"layer_tile_exists",
"layer_tile_get_alpha",
"layer_tile_get_blend",
"layer_tile_get_region",
"layer_tile_get_visible",
"layer_tile_get_x",
"layer_tile_get_xscale",
"layer_tile_get_y",
"layer_tile_get_yscale",
"layer_tile_region",
"layer_tile_visible",
"layer_tile_x",
"layer_tile_xscale",
"layer_tile_y",
"layer_tile_yscale",
"layer_tilemap_destroy",
"layer_tilemap_exists",
"layer_tilemap_set_colmask",
"layer_vspeed",
"layer_x",
"layer_y",
"method_call",
"move_and_collide",
"mp_grid_add_cell",
"mp_grid_add_instances",
"mp_grid_add_rectangle",
"mp_grid_clear_all",
"mp_grid_clear_cell",
"mp_grid_clear_rectangle",
"mp_grid_destroy",
"mp_grid_draw",
"mp_grid_get_cell",
"mp_grid_path",
"mp_grid_to_ds_grid",
"mp_linear_path",
"mp_linear_path_object",
"mp_linear_step_object",
"mp_potential_path",
"mp_potential_path_object",
"mp_potential_step_object",
"network_connect",
"network_connect_async",
"network_connect_raw",
"network_connect_raw_async",
"network_destroy",
"network_send_broadcast",
"network_send_packet",
"network_send_raw",
"network_send_udp",
"network_send_udp_raw",
"network_set_timeout",
"object_exists",
"object_get_name",
"object_get_persistent",
"object_get_physics",
"object_get_solid",
"object_get_visible",
"object_is_ancestor",
"object_set_mask",
"object_set_persistent",
"object_set_solid",
"object_set_sprite",
"object_set_visible",
"part_emitter_burst",
"part_emitter_clear",
"part_emitter_delay",
"part_emitter_destroy",
"part_emitter_destroy_all",
"part_emitter_enable",
"part_emitter_exists",
"part_emitter_interval",
"part_emitter_region",
"part_emitter_relative",
"part_emitter_stream",
"part_particles_burst",
"part_particles_clear",
"part_particles_count",
"part_particles_create",
"part_particles_create_color",
"part_particles_create_colour",
"part_system_angle",
"part_system_automatic_draw",
"part_system_automatic_update",
"part_system_clear",
"part_system_color",
"part_system_colour",
"part_system_depth",
"part_system_destroy",
"part_system_draw_order",
"part_system_drawit",
"part_system_exists",
"part_system_get_info",
"part_system_global_space",
"part_system_layer",
"part_system_position",
"part_system_update",
"part_type_alpha1",
"part_type_alpha2",
"part_type_alpha3",
"part_type_blend",
"part_type_clear",
"part_type_color1",
"part_type_color2",
"part_type_color3",
"part_type_color_hsv",
"part_type_color_mix",
"part_type_color_rgb",
"part_type_colour1",
"part_type_colour2",
"part_type_colour3",
"part_type_colour_hsv",
"part_type_colour_mix",
"part_type_colour_rgb",
"part_type_death",
"part_type_destroy",
"part_type_direction",
"part_type_exists",
"part_type_gravity",
"part_type_life",
"part_type_orientation",
"part_type_scale",
"part_type_shape",
"part_type_size",
"part_type_size_x",
"part_type_size_y",
"part_type_speed",
"part_type_sprite",
"part_type_step",
"part_type_subimage",
"particle_exists",
"particle_get_info",
"path_add_point",
"path_append",
"path_assign",
"path_change_point",
"path_clear_points",
"path_delete",
"path_delete_point",
"path_exists",
"path_flip",
"path_get_closed",
"path_get_kind",
"path_get_length",
"path_get_name",
"path_get_number",
"path_get_point_speed",
"path_get_point_x",
"path_get_point_y",
"path_get_precision",
"path_get_speed",
"path_get_x",
"path_get_y",
"path_insert_point",
"path_mirror",
"path_rescale",
"path_reverse",
"path_rotate",
"path_set_closed",
"path_set_kind",
"path_set_precision",
"path_shift",
"path_start",
"physics_fixture_add_point",
"physics_fixture_bind",
"physics_fixture_bind_ext",
"physics_fixture_delete",
"physics_fixture_set_angular_damping",
"physics_fixture_set_awake",
"physics_fixture_set_box_shape",
"physics_fixture_set_chain_shape",
"physics_fixture_set_circle_shape",
"physics_fixture_set_collision_group",
"physics_fixture_set_density",
"physics_fixture_set_edge_shape",
"physics_fixture_set_friction",
"physics_fixture_set_kinematic",
"physics_fixture_set_linear_damping",
"physics_fixture_set_polygon_shape",
"physics_fixture_set_restitution",
"physics_fixture_set_sensor",
"physics_get_density",
"physics_get_friction",
"physics_get_restitution",
"physics_joint_delete",
"physics_joint_enable_motor",
"physics_joint_get_value",
"physics_joint_set_value",
"physics_particle_delete",
"physics_particle_delete_region_poly",
"physics_particle_draw",
"physics_particle_draw_ext",
"physics_particle_group_get_ang_vel",
"physics_particle_group_get_angle",
"physics_particle_group_get_centre_x",
"physics_particle_group_get_centre_y",
"physics_particle_group_get_inertia",
"physics_particle_group_get_mass",
"physics_particle_group_get_vel_x",
"physics_particle_group_get_vel_y",
"physics_particle_group_get_x",
"physics_particle_group_get_y",
"physics_particle_group_join",
"physics_raycast",
"physics_remove_fixture",
"physics_set_density",
"physics_set_friction",
"physics_set_restitution",
"physics_test_overlap",
"place_empty",
"place_meeting",
"position_change",
"position_meeting",
"rollback_define_player",
"room_assign",
"room_exists",
"room_get_info",
"room_get_name",
"room_get_viewport",
"room_goto",
"room_instance_clear",
"room_set_background_color",
"room_set_background_colour",
"room_set_camera",
"room_set_height",
"room_set_persistent",
"room_set_view_enabled",
"room_set_viewport",
"room_set_width",
"script_execute",
"script_execute_ext",
"script_exists",
"script_get_name",
"sequence_exists",
"sequence_get",
"sequence_instance_override_object",
"shader_get_name",
"shader_is_compiled",
"shader_set",
"shader_set_uniform_f",
"shader_set_uniform_f_array",
"shader_set_uniform_f_buffer",
"shader_set_uniform_i",
"shader_set_uniform_i_array",
"shader_set_uniform_matrix",
"shader_set_uniform_matrix_array",
"skeleton_animation_list",
"skeleton_attachment_create",
"skeleton_attachment_create_color",
"skeleton_attachment_create_colour",
"skeleton_attachment_replace",
"skeleton_attachment_replace_colour",
"skeleton_attachment_set",
"skeleton_bone_data_get",
"skeleton_bone_data_set",
"skeleton_bone_list",
"skeleton_bone_state_get",
"skeleton_bone_state_set",
"skeleton_find_slot",
"skeleton_skin_list",
"skeleton_slot_data",
"skeleton_slot_data_instance",
"skeleton_slot_list",
"sprite_add_from_surface",
"sprite_assign",
"sprite_collision_mask",
"sprite_delete",
"sprite_exists",
"sprite_flush",
"sprite_flush_multi",
"sprite_get_bbox_bottom",
"sprite_get_bbox_left",
"sprite_get_bbox_mode",
"sprite_get_bbox_right",
"sprite_get_bbox_top",
"sprite_get_convex_hull",
"sprite_get_height",
"sprite_get_info",
"sprite_get_name",
"sprite_get_nineslice",
"sprite_get_number",
"sprite_get_speed",
"sprite_get_speed_type",
"sprite_get_texture",
"sprite_get_tpe",
"sprite_get_uvs",
"sprite_get_width",
"sprite_get_xoffset",
"sprite_get_yoffset",
"sprite_merge",
"sprite_prefetch",
"sprite_prefetch_multi",
"sprite_replace",
"sprite_save",
"sprite_save_strip",
"sprite_set_alpha_from_sprite",
"sprite_set_bbox",
"sprite_set_bbox_mode",
"sprite_set_cache_size",
"sprite_set_cache_size_ext",
"sprite_set_nineslice",
"sprite_set_offset",
"sprite_set_speed",
"static_get",
"string_foreach",
"struct_foreach",
"surface_copy",
"surface_copy_part",
"surface_exists",
"surface_free",
"surface_get_format",
"surface_get_height",
"surface_get_texture",
"surface_get_texture_depth",
"surface_get_width",
"surface_getpixel",
"surface_getpixel_ext",
"surface_has_depth",
"surface_resize",
"surface_save",
"surface_save_part",
"surface_set_target",
"surface_set_target_ext",
"texture_set_stage",
"texturegroup_set_mode",
"tilemap_clear",
"tilemap_get",
"tilemap_get_at_pixel",
"tilemap_get_cell_x_at_pixel",
"tilemap_get_cell_y_at_pixel",
"tilemap_get_frame",
"tilemap_get_height",
"tilemap_get_mask",
"tilemap_get_tile_height",
"tilemap_get_tile_width",
"tilemap_get_tileset",
"tilemap_get_width",
"tilemap_get_x",
"tilemap_get_y",
"tilemap_set",
"tilemap_set_at_pixel",
"tilemap_set_height",
"tilemap_set_mask",
"tilemap_set_width",
"tilemap_tileset",
"tilemap_x",
"tilemap_y",
"tileset_get_info",
"tileset_get_name",
"tileset_get_texture",
"tileset_get_uvs",
"time_source_destroy",
"time_source_exists",
"time_source_get_period",
"time_source_get_reps_completed",
"time_source_get_reps_remaining",
"time_source_get_state",
"time_source_get_time_remaining",
"time_source_get_units",
"time_source_pause",
"time_source_reconfigure",
"time_source_reset",
"time_source_resume",
"time_source_start",
"time_source_stop",
"timeline_clear",
"timeline_delete",
"timeline_exists",
"timeline_get_name",
"timeline_max_moment",
"timeline_moment_add_script",
"timeline_moment_clear",
"timeline_size",
"variable_instance_exists",
"variable_instance_get",
"variable_instance_get_names",
"variable_instance_names_count",
"variable_instance_set",
"vertex_argb",
"vertex_begin",
"vertex_buffer_exists",
"vertex_color",
"vertex_colour",
"vertex_delete_buffer",
"vertex_end",
"vertex_float1",
"vertex_float2",
"vertex_float3",
"vertex_float4",
"vertex_format_delete",
"vertex_format_exists",
"vertex_format_get_info",
"vertex_freeze",
"vertex_get_buffer_size",
"vertex_get_number",
"vertex_normal",
"vertex_position",
"vertex_position_3d",
"vertex_submit",
"vertex_submit_ext",
"vertex_texcoord",
"vertex_ubyte4",
"vertex_update_buffer_from_buffer",
"vertex_update_buffer_from_vertex",
"view_set_camera",
"view_set_surface_id",
"audio_bus_get_emitters",
"audio_create_stream",
"audio_create_sync_group",
"audio_emitter_create",
"audio_get_listener_info",
"audio_listener_get_data",
"audio_play_sound_ext",
"buffer_base64_decode",
"buffer_create",
"buffer_load",
"camera_create",
"camera_get_active",
"camera_get_default",
"draw_get_font",
"ds_list_create",
"ds_map_create",
"ds_map_secure_load",
"ds_priority_create",
"ds_queue_create",
"ds_stack_create",
"external_define",
"file_bin_open",
"file_text_open_append",
"file_text_open_from_string",
"file_text_open_read",
"file_text_open_write",
"flexpanel_node_get_measure_function",
"font_add",
"gif_open",
"gpu_get_state",
"gpu_get_stencil_func",
"gpu_get_zfunc",
"handle_parse",
"instance_copy",
"layer_create",
"layer_get_all",
"layer_get_element_layer",
"layer_get_id",
"layer_get_id_at_depth",
"layer_get_target_room",
"layer_instance_get_instance",
"mp_grid_create",
"network_create_socket",
"network_create_socket_ext",
"os_get_info",
"part_type_create",
"path_add",
"physics_fixture_create",
"physics_particle_create",
"physics_particle_group_end",
"room_add",
"shader_current",
"sprite_add",
"sprite_add_ext",
"surface_create",
"surface_create_ext",
"surface_get_target",
"surface_get_target_depth",
"surface_get_target_ext",
"texturegroup_get_fonts",
"texturegroup_get_sprites",
"texturegroup_get_textures",
"texturegroup_get_tilesets",
"timeline_add",
"vertex_create_buffer",
"vertex_create_buffer_ext",
"vertex_format_end",
"view_get_surface_id",
"asset_get_ids",
"asset_get_index",
"asset_get_type",
"audio_create_buffer_sound",
"audio_group_get_assets",
"audio_play_in_sync_group",
"audio_play_sound",
"audio_play_sound_at",
"audio_play_sound_on",
"audio_sound_get_asset",
"audio_sound_get_audio_group",
"buffer_create_from_vertex_buffer",
"buffer_create_from_vertex_buffer_ext",
"buffer_decompress",
"call_later",
"camera_create_view",
"camera_get_begin_script",
"camera_get_end_script",
"camera_get_update_script",
"camera_get_view_target",
"collision_circle",
"collision_ellipse",
"collision_line",
"collision_point",
"collision_rectangle",
"ds_map_secure_load_buffer",
"exception_unhandled_handler",
"font_add_sprite",
"font_add_sprite_ext",
"instance_create_depth",
"instance_create_layer",
"instance_find",
"instance_furthest",
"instance_nearest",
"instance_place",
"instance_position",
"layer_background_create",
"layer_background_get_id",
"layer_background_get_sprite",
"layer_get_script_begin",
"layer_get_script_end",
"layer_get_shader",
"layer_particle_get_id",
"layer_particle_get_instance",
"layer_particle_get_system",
"layer_sequence_create",
"layer_sprite_create",
"layer_sprite_get_id",
"layer_sprite_get_sprite",
"layer_text_create",
"layer_text_get_font",
"layer_text_get_id",
"layer_tile_create",
"layer_tile_get_sprite",
"layer_tilemap_create",
"layer_tilemap_get_colmask",
"layer_tilemap_get_id",
"method",
"method_get_index",
"method_get_self",
"object_get_mask",
"object_get_parent",
"object_get_sprite",
"part_emitter_create",
"part_system_create",
"part_system_create_layer",
"part_system_get_layer",
"path_duplicate",
"physics_joint_distance_create",
"physics_joint_friction_create",
"physics_joint_gear_create",
"physics_joint_prismatic_create",
"physics_joint_pulley_create",
"physics_joint_revolute_create",
"physics_joint_rope_create",
"physics_joint_weld_create",
"physics_joint_wheel_create",
"physics_particle_get_data",
"physics_particle_get_data_particle",
"physics_particle_group_get_data",
"ref_create",
"room_duplicate",
"room_get_camera",
"room_instance_add",
"room_next",
"room_previous",
"sequence_get_objects",
"shader_get_sampler_index",
"shader_get_uniform",
"sprite_create_from_surface",
"sprite_duplicate",
"tag_get_asset_ids",
"time_source_create",
"time_source_get_children",
"time_source_get_parent",
"vertex_create_buffer_from_buffer",
"vertex_create_buffer_from_buffer_ext",
"flexpanel_create_node",
"layer_get_flexpanel_node",
"tileset_get_texture",
"sprite_get_texture",
"font_get_texture",
"surface_get_texture",
"surface_get_texture_depth",
"dbg_view",
"dbg_section",
"dbg_slider",
"dbg_drop_down",
"dbg_watch",
"dbg_same_line",
"dbg_button",
"dbg_text_input",
"dbg_checkbox",
"dbg_colour",
"dbg_color",
"dbg_text",
"dbg_text_separator",
"dbg_sprite",
"dbg_slider_int",
"dbg_sprite_button",
];
array_sort(_handles, true);

log("\n\n\n\n\n")

array_foreach(_handles, function(_elem, _ind) {
	
	var _spec = __GmlSpec();
	var _data = _spec[$ _elem];
	var _func_name = _elem;
	//_data.feather.description;
	var _func_type = _data.feather.returnType;
	
	var _str = $"function __{_func_name}(\{1})\{\n";
	var _arg_str = ""
	
	var map_arguments = false;
	
	var _args = _data.feather.parameters;
	
	// ----- normalize duplicate argument names for float / byte -----
	var _name_counts = {};
	var _arg_count = array_length(_args);
	for (var _idx_arg = 0; _idx_arg < _arg_count; _idx_arg++) {
		var _raw_name = _args[_idx_arg].name;
		var _clean_name = string_replace_all(_raw_name, " ", "");
		_clean_name = string_replace_all(_clean_name, "(optional)", "");

		if (_clean_name == "float" || _clean_name == "byte") {
			if (!struct_exists(_name_counts, _clean_name)) {
				_name_counts[$ _clean_name] = 1;
			} else {
				var _next_val = _name_counts[$ _clean_name] + 1;
				_name_counts[$ _clean_name] = _next_val;
				_clean_name = _clean_name + string(_next_val);
			}
		}

		_args[_idx_arg].name = _clean_name;
	}

	
	var _length = array_length(_args);
	var _i=0; repeat(_length) {
		var _arg = _args[_i];
		var _name = _arg.name;
		var _type = _arg.type;
		
		_name = string_replace_all(_name, " ", "");
		_name = string_replace_all(_name, "(optional)", "");
		if (string_pos("...", _name)) { map_arguments = true; }
		_name = string_replace_all(_name, "...", "value");
		_name = string_replace_all(_name, "instance_id/object_id", "_id");
		_name = string_replace_all(_name, "instance_id/global", "_id");
		
		_arg_str += $"_{_name},"
		
		if (_type_contains(_type)) {
			
			if (string_pos("Constant.EventNumber", _type)) {
				_str += $"\t\t//_{_name} : \{{_type}}\n";
				_str += $"\t\tif (_{_name} == ev_collision && !is_handle(_{_name}) && is_numeric(_{_name})) throw \"This project doesnt support arbitrary handle access, please provide a handle instead of a number.\"\n";
			}
			else {
				_str += $"\t//_{_name} : \{{_type}}\n";
				_str += $"\tif (!is_handle(_{_name}) && is_numeric(_{_name})) throw \"This project doesnt support arbitrary handle access, please provide a handle instead of a number.\"\n";
			}
		}
	_i++}
	
	_arg_str = string_trim_end(_arg_str, [","])
	
	_str = string(_str, undefined, _arg_str) //append arguments
	
	if (map_arguments) {
		_str += 
		"\tstatic __arr = []; var _arr = __arr;\n"
		+ "\tfor (var _i=0; _i<argument_count; _i++) { _arr[_i] = argument[_i]; }\n"
		+ "\tvar _ret = script_execute_ext("+_func_name+", _arr);\n"
		+ "\tarray_resize(_arr, 0);\n"
		+ "\treturn _ret;\n}"
		
	}
	else {
		_str += $"\treturn {_func_name}({_arg_str});\n}"
	}
	
	show_debug_message(_str);
})

log("\n\n\n\n\n")

var _struct = __GmlSpec();
struct_foreach(_struct, function(_key, _value) {
	static __keywords = ["sound", "audio"];
	
	if (_value.type == "envFunctions") {
		var _name = _key;
		var _desc = _value.feather.description;
		var _return_type = _value.feather.returnType;
		
		static __closure = {};
		__closure.should_print = false;
		
		var _args = array_map(_value.feather.parameters, method(__closure, function(_elem, _index) {
			var _name = _elem.name;
			var _desc = _elem.description;
			var _type = _elem.type;
			
			if (_type_contains(_type)) {
				should_print = true;
			}
			
			return {
				name: _name,
				desc: _desc,
				type: _type
			}
		}))
		
		if (!__closure.should_print && _type_contains(_return_type)) {
			show_debug_message(_name);
		}
		
	}
})


