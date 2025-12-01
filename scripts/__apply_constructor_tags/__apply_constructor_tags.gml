// Namespace style constructors will not recieve any constructor tags.
// This is intended, but this is a work around for such a thing.
// https://github.com/YoYoGames/GameMaker-Bugs/issues/10317#issuecomment-2816652022

// Additionally this allows for us to very quickly add the same tags to LTS
// so it will make back porting easier in the future.

var _func_arr = asset_get_ids(asset_script);
var _i=0; repeat(array_length(_func_arr)) {
	var _func = _func_arr[_i];
	
	//if tags were already applied to functions then the runtime is updated to support that feature and we dont need to do this.
	if (asset_has_tags(_func, "@@constructor")) {
		_i++;
		continue;
	}
	
	var _is_constructor = true;
	try {
		new _func();
	}
	catch(err) {
		//normally we wouldnt string compare error messages,
		// but LTS and monthly wont be getting updates which change error messages
		// before the beta tags update comes out
		if (err.message == "target function for 'new' must be a constructor") {
			_is_constructor = false;
		}
	}
	
	if (_is_constructor) {
		//show_debug_message($"Adding \"@@constructor\" tag to :: {script_get_name(_func)}")
		asset_add_tags(_func, "@@constructor");
	}
	
_i++}

