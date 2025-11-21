//window_set_size(sprite_get_width(sprGMLCLogo), sprite_get_height(sprGMLCLogo));
//window_set_position(display_get_width()/2-128, display_get_height()/2-128);
//instance_create_depth(0, 0, 0, objLogoRenderer);

#macro RefuseTest return __RefuseTest
function __RefuseTest(_desc="Red Manually refused this test") {
	assert_true(false, _desc)
}

#macro ShouldTryCatch false



// some of the internal tests require us to include these somewhere.
var _unused = [
//fx_create("_filter_colourise"),
//fx_create("_filter_edgedetect"),
//fx_create("_filter_greyscale"),
//fx_create("_filter_large_blur"),
//fx_create("_filter_pixelate"),
//fx_create("_filter_posterise"),
//fx_create("_filter_screenshake"),
//fx_create("_filter_tintfilter"),

////These go unused in the test suites, just leaving them here incase they get added in.
//fx_create("_filter_blocks"),
//fx_create("_filter_boxes"),
//fx_create("_filter_clouds"),
//fx_create("_filter_colour_balance"),
//fx_create("_filter_contrast"),
//fx_create("_filter_distort"),
//fx_create("_filter_dots"),
//fx_create("_filter_fractal_noise"),
//fx_create("_filter_gradient"),
//fx_create("_filter_hard_drop_shadow"),
//fx_create("_filter_heathaze"),
//fx_create("_filter_hue"),
//fx_create("_filter_linear_blur"),
//fx_create("_filter_lut_colour"),
//fx_create("_filter_mask"),
//fx_create("_filter_old_film"),
//fx_create("_filter_outline"),
//fx_create("_filter_panorama"),
//fx_create("_filter_parallax"),
//fx_create("_filter_rgbnoise"),
//fx_create("_filter_ripples"),
//fx_create("_filter_stripes"),
//fx_create("_filter_twirl_distort"),
//fx_create("_filter_twist_blur"),
//fx_create("_filter_underwater"),
//fx_create("_filter_vignette"),
//fx_create("_filter_whitenoise"),
//fx_create("_filter_zoom_blur"),
//fx_create("_effect_blend"),
//fx_create("_effect_blend_ext"),
//fx_create("_effect_gaussian_blur"),
//fx_create("_effect_glow"),
//fx_create("_effect_recursive_blur"),
//fx_create("_effect_windblown_particles"),
]