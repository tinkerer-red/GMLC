
var env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
program = env.compile(@'
function TestAudioEffectMembers(audioEffectType, membersArray) {
	
	// Loop through all members of audio effect and check if it exists
	for (var i = 0; i < array_length(membersArray); i++) {
		
		var output = variable_struct_exists(audioEffectType, membersArray[i]);
		assert_true(output, string(audioEffectType) + " should contain " + string(membersArray[i]) + " as a member");
		
	}
	
}

var members = ["type", "bypass", "gain", "factor", "resolution", "mix"];

var effect = audio_effect_create(AudioEffectType.Bitcrusher);

TestAudioEffectMembers(effect, members);
');

show_debug_message(program())

/*

gmlc = new GMLC_Env().set_exposure(GMLC_EXPOSURE.NATIVE);

gmlc.__log_tokenizer_results      = true;
gmlc.__log_pre_processer_results  = true;
gmlc.__log_parser_results         = true;
gmlc.__log_post_processer_results = true;
gmlc.__log_optimizer_results      = true;

gmlc.compile(@'
    #macro test "abc";
	
	foo = 123;
	bar = test;
	
	var foo;
')


// Save full JSON result
log("!!!compiling complete!!!")

gmlc = undefined;


