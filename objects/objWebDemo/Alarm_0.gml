/// @description Insert description here
// You can write your code in this editor

if (!compile_pending) {
	compile_pending = true;
	var _self = self;
	get_string_async_promise(
		"Insert Github gist link:",
		"https://gist.github.com/tinkerer-red/25585de0f685d14c83d2160ac7c8625a",
		method(_self, function(_async_load){
			
			var _self = self;
			var _url = _async_load.result;
			
			if (!is_string(_url) || _url == "") {
				compile_pending = false;
				return;
			}
			
			if (string_pos("https://gist.github.com/", _url)) {
				_url = string_replace(_url, "https://gist.github.com/", "https://gist.githubusercontent.com/")
				_url += "/raw";
			}
			
			if (string_pos("https://gist.githubusercontent.com/", _url)) {
				
				http_get_promise(
					_url,
					method(_self, function(_async_load) {
						pprint(_async_load.result)
				
						var _code   = _async_load.result;
						var _result = undefined;
						var _crash  = "";
						var _i;
				
						try {
							_result = execute_string(_code);
						}
						catch(err) {
							_crash += "\n########################################\n"
							_crash += err.longMessage
							_crash += "\n########################################"
							_i=0; repeat(array_length(err.stacktrace)) {
								_crash += "\n"+err.stacktrace[_i];
							_i++}
						}
				
						if (string_length(_crash)) {
							show_message("There was an error, please see console for details")
						}
						else {
							if (_result != undefined) {
								show_message(string(_result))
							}
							else {
								show_message("There was no return from the script")
							}
						}
				
						compile_pending = false;
					})
				)
				return;
			}
			else {
				show_message_async("Please provide a link to a github gist.")
			}
			
			compile_pending = false;
		}),
	)
	
}

alarm[0] = 1