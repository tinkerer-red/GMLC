/// @description Start Framework
/// This is the entry point for the frameowork execution.
testFramework = new TestFrameworkRun();

gmlc = new GMLC_Env();
//sprites
gmlc.exposeConstants({
	"sprTileset": sprTileset,
	"sprTilesetReplacement": sprTilesetReplacement,
})
//audio groups
gmlc.exposeConstants({
	"audiogroup_default": audiogroup_default,
	"audiogroup_MP3": audiogroup_MP3,
	"audiogroup_OGG": audiogroup_OGG,
	"audiogroup_WAV": audiogroup_WAV,
})
//shaders
gmlc.exposeConstants({
	"sh_ambient_colour_glsl": sh_ambient_colour_glsl,
	"sh_ambient_colour_glsles": sh_ambient_colour_glsles,
	"sh_ambient_colour_hlsl": sh_ambient_colour_hlsl,
	"sh_fog_colour_glsl": sh_fog_colour_glsl,
	"sh_fog_colour_glsles": sh_fog_colour_glsles,
	"sh_fog_colour_hlsl": sh_fog_colour_hlsl,
	"sh_fog_start_glsl": sh_fog_start_glsl,
	"sh_fog_start_glsles": sh_fog_start_glsles,
	"sh_fog_start_hlsl": sh_fog_start_hlsl,
	"sh_frag_coord_glsl": sh_frag_coord_glsl,
	"sh_frag_coord_glsles": sh_frag_coord_glsles,
	"sh_frag_data_glsl": sh_frag_data_glsl,
	"sh_frag_data_glsles": sh_frag_data_glsles,
	"sh_front_facing_glsl": sh_front_facing_glsl,
	"sh_front_facing_glsles": sh_front_facing_glsles,
	"sh_is_front_face_hlsl": sh_is_front_face_hlsl,
	"sh_lighting_enabled_glsl": sh_lighting_enabled_glsl,
	"sh_lighting_enabled_glsles": sh_lighting_enabled_glsles,
	"sh_lighting_enabled_hlsl": sh_lighting_enabled_hlsl,
	"sh_lights_colour_glsl": sh_lights_colour_glsl,
	"sh_lights_colour_glsles": sh_lights_colour_glsles,
	"sh_lights_colour_hlsl": sh_lights_colour_hlsl,
	"sh_lights_direction_glsl": sh_lights_direction_glsl,
	"sh_lights_direction_glsles": sh_lights_direction_glsles,
	"sh_lights_direction_hlsl": sh_lights_direction_hlsl,
	"sh_lights_pos_range_glsl": sh_lights_pos_range_glsl,
	"sh_lights_pos_range_glsles": sh_lights_pos_range_glsles,
	"sh_lights_pos_range_hlsl": sh_lights_pos_range_hlsl,
	"sh_matrix_max_glsl": sh_matrix_max_glsl,
	"sh_matrix_max_glsles": sh_matrix_max_glsles,
	"sh_matrix_max_hlsl": sh_matrix_max_hlsl,
	"sh_matrix_projection_glsl": sh_matrix_projection_glsl,
	"sh_matrix_projection_glsles": sh_matrix_projection_glsles,
	"sh_matrix_projection_hlsl": sh_matrix_projection_hlsl,
	"sh_matrix_view_glsl": sh_matrix_view_glsl,
	"sh_matrix_view_glsles": sh_matrix_view_glsles,
	"sh_matrix_view_hlsl": sh_matrix_view_hlsl,
	"sh_matrix_world_glsl": sh_matrix_world_glsl,
	"sh_matrix_world_glsles": sh_matrix_world_glsles,
	"sh_matrix_world_hlsl": sh_matrix_world_hlsl,
	"sh_matrix_world_view_glsl": sh_matrix_world_view_glsl,
	"sh_matrix_world_view_glsles": sh_matrix_world_view_glsles,
	"sh_matrix_world_view_hlsl": sh_matrix_world_view_hlsl,
	"sh_matrix_world_view_projection_glsl": sh_matrix_world_view_projection_glsl,
	"sh_matrix_world_view_projection_glsles": sh_matrix_world_view_projection_glsles,
	"sh_matrix_world_view_projection_hlsl": sh_matrix_world_view_projection_hlsl,
	"sh_max_draw_buffers_glsl": sh_max_draw_buffers_glsl,
	"sh_max_draw_buffers_glsles": sh_max_draw_buffers_glsles,
	"sh_max_vs_lights_glsl": sh_max_vs_lights_glsl,
	"sh_max_vs_lights_glsles": sh_max_vs_lights_glsles,
	"sh_max_vs_lights_hlsl": sh_max_vs_lights_hlsl,
	"sh_normals_glsl": sh_normals_glsl,
	"sh_normals_glsles": sh_normals_glsles,
	"sh_normals_hlsl": sh_normals_hlsl,
	"sh_passthrough_glsl": sh_passthrough_glsl,
	"sh_passthrough_glsles": sh_passthrough_glsles,
	"sh_passthrough_hlsl": sh_passthrough_hlsl,
	"sh_ps_fog_enabled_glsl": sh_ps_fog_enabled_glsl,
	"sh_ps_fog_enabled_glsles": sh_ps_fog_enabled_glsles,
	"sh_ps_fog_enabled_hlsl": sh_ps_fog_enabled_hlsl,
	"sh_rcp_fog_range_glsl": sh_rcp_fog_range_glsl,
	"sh_rcp_fog_range_glsles": sh_rcp_fog_range_glsles,
	"sh_rcp_fog_range_hlsl": sh_rcp_fog_range_hlsl,
	"sh_sampler_glsl": sh_sampler_glsl,
	"sh_sampler_glsles": sh_sampler_glsles,
	"sh_sampler_hlsl": sh_sampler_hlsl,
	"sh_sv_position_hlsl": sh_sv_position_hlsl,
	"sh_sv_target_hlsl": sh_sv_target_hlsl,
	"sh_uniform_f_array_glsl": sh_uniform_f_array_glsl,
	"sh_uniform_f_array_glsles": sh_uniform_f_array_glsles,
	"sh_uniform_f_array_hlsl": sh_uniform_f_array_hlsl,
	"sh_uniform_f_glsl": sh_uniform_f_glsl,
	"sh_uniform_f_glsles": sh_uniform_f_glsles,
	"sh_uniform_f_hlsl": sh_uniform_f_hlsl,
	"sh_uniform_i_array_glsl": sh_uniform_i_array_glsl,
	"sh_uniform_i_array_glsles": sh_uniform_i_array_glsles,
	"sh_uniform_i_array_hlsl": sh_uniform_i_array_hlsl,
	"sh_uniform_i_glsl": sh_uniform_i_glsl,
	"sh_uniform_i_glsles": sh_uniform_i_glsles,
	"sh_uniform_i_hlsl": sh_uniform_i_hlsl,
	"sh_uniform_matrix_glsl": sh_uniform_matrix_glsl,
	"sh_uniform_matrix_glsles": sh_uniform_matrix_glsles,
	"sh_uniform_matrix_hlsl": sh_uniform_matrix_hlsl,
	"sh_vs_fog_enabled_glsl": sh_vs_fog_enabled_glsl,
	"sh_vs_fog_enabled_glsles": sh_vs_fog_enabled_glsles,
	"sh_vs_fog_enabled_hlsl": sh_vs_fog_enabled_hlsl,
})

gmlc.exposeConstants({
	"pprint": function(){
	    var _str = "";
		var _i=0; repeat(argument_count) {
			_str += json_stringify(__reStruct(argument[_i]), true)+"\n";
		_i++}
		show_debug_message(_str)
	},
})

gmlc.set_exposure(GMLC_EXPOSURE.FULL)

// ################# TEST SUITE REGISTRATION #################
var _string = @'
function test() : TestSuite() constructor {
	static func_static = true;
	func_local = true;
	pprint(static_get(self))
	pprint(static_get(self))
	pprint(static_get(static_get(self)))
	show_debug_message(addFact)
}
'

var _program = gmlc.compile(_string);
var _self = method_get_self(_program)
var t = new _self.globals.test();
log(instanceof(t));
log(t);
var t = constructor_call_ext(_self.globals.test);
log(instanceof(t));
log(t);

//// Register your test suites here...
//testFramework.addSuite(OptimizerConstantFoldingTestSuite);
//testFramework.addSuite(OptimizerConstantPropagationTestSuite);
//testFramework.addSuite(OptimizerUnreachableCodeTestSuite);
//testFramework.addSuite(BasicEscapeCharacterTestSuite);
//testFramework.addSuite(BasicCompoundAssignmentAccessorsTestSuite);
//testFramework.addSuite(BasicConstructorTestSuit);
testFramework.addSuite(EmptyBlockAcceptanceTestSuite);


/*
// Add all of the official test suites from their .gml files in included folder \__TEST\*.gml
var _file_names = file_find_all("__TESTS/*gml");
for(var i=0; i<array_length(_file_names); i++) {
	//log(_file_names[i]);
	var _script_str = file_read_all_text("__TESTS/"+_file_names[i]);
	//log(string_replace_all(string_replace_all(string_copy(_script_str, 0, 200), "\t", ""), "\n", ""));
	var _program = gmlc.compile(_script_str);
	//pprint(_program)
	var _program_data = method_get_self(_program);
	var _global_names = struct_get_names(_program_data.globals);
	
	for(var j=0; j<array_length(_global_names); j++) {
		var _global_name = _global_names[j];
		
		if (!string_starts_with(_global_name, "GMLC"))
		&& (string_pos("TestSuite", _global_name))
		{
			show_debug_message(_global_name);
			var _func = _program_data.globals[$ _global_name];
			testFramework.addSuite(_func);
		}
	}
}
//*/

// ###########################################################

testFramework.run(undefined, {});


