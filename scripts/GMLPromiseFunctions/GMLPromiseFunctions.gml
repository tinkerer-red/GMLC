/// @title Built in Async Promises

#region jsDoc
/// @func    audio_free_play_queue_promise()
/// @desc    This function is used to free up the memory associated with the given audio queue. The queue index is the value returned when you created the queue using the function audio_create_play_queue(), and this function should be called when the queue is no longer required to prevent memory leaks. Freeing the queue will stop any sound that is be playing, and you cannot delete the buffer that a sound is being streamed from until the queue it is assigned to has been freed. This function will trigger an Audio Playback Asynchronous Event, and in this event a special DS map will be created in the variable async_load with the following key/value pairs:
/// @param   {Real} queueindex : The index of the queue to free.
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function audio_free_play_queue_promise(
	queueId,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: audio_free_play_queue_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.AUDIO_PLAYBACK;
	var _async_id = audio_free_play_queue(queueId);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    audio_group_load_promise()
/// @desc    This function will load all the sounds that are flagged as belonging to the given Audio Group into memory. The function will return true if loading is initiated and false if the group ID is invalid, or it has already been flagged for loading. The function is asynchronous so your game will continue to run while the audio is loaded in the background. This means that it will also trigger an Asynchronous Load/Save Event to inform you that the whole group has been loaded into memory and the sounds can now be used.
/// @param   {Asset.GMAudioGroup} groupid : The index of the audio group to load (as defined in the Audio Groups Window)
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function audio_group_load_promise( 
	groupid ,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: audio_group_load_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.SAVE_LOAD;
	var _async_id = audio_group_load( groupid );
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    audio_start_recording_promise()
/// @desc    This function will start recording audio from the recorder source indexed. You can get the number of recorder sources using the function audio_get_recorder_count(), and once you start recording the audio will be stored in a temporary buffer and start triggering an Audio Recording Asynchronous Event. This event is triggered every step that recording takes place and will create the special DS map in the variable async_load with the following key/value pairs:
/// @param   {Real} recorder_index : The index of the recorder source to use.
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function audio_start_recording_promise(
	recorder_num,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: audio_start_recording_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.AUDIO_RECORDING;
	var _async_id = audio_start_recording(recorder_num);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    audio_stop_recording_promise()
/// @desc    This function will stop recording on the given recorder channel (the channel index is returned when you call the function audio_start_recording()). When you stop recording, no further Audio Recording Asynchronous Events will be triggered for the given recorder channel, so you would normally use this function in the actual asynchronous event to ensure that you have captured all the data.
/// @param   {Real} channel_index : The index of the recorder channel to stop.
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function audio_stop_recording_promise(channel_index){
	//these dont actually generate an async event id, so they are only here for consistency sake
	audio_stop_recording(channel_index);
}
#region jsDoc
/// @func    buffer_async_group_begin_promise()
/// @desc    This function is called when you want to begin the saving out of multiple buffers to multiple files. The "groupname" is a string and will be used as the directory name for where the files will be saved, and should be used as part of the file path when loading the files back into the IDE later (using any of the buffer_load() functions). This function is only for use with the buffer_save_async() function and you must also finish the save definition by calling buffer_async_group_end() function otherwise the files will not be saved out.
/// @param   {String} groupname : The name of the group (as a string).
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function buffer_async_group_begin_promise(groupname){
	//these dont actually generate an async event id, so they are only here for consistency sake
	buffer_async_group_begin(groupname);
}
#region jsDoc
/// @func    buffer_async_group_end_promise()
/// @desc    This function finishes the definition of a buffer save group. You must have previously called the function buffer_async_group_begin() to initiate the group, then call the function buffer_save_async() for each file that you wish to save out. Finally you call this function, which will start the saving of the files. The function will return a unique ID value for the save, which can then be used in the Asynchronous Save / Load event to parse the results from the async_load DS map.
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function buffer_async_group_end_promise(
	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: buffer_async_group_end_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.SAVE_LOAD;
	var _async_id = buffer_async_group_end();
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    buffer_async_group_option_promise()
/// @desc    With this function you can set some platform specific options for the buffer group being saved. The options available are as follows:
/// @param   {String} option : The option to set.
/// @param   {Any} value : The value to set (can be string or real, depending on the option).
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function buffer_async_group_option_promise(
	optionname,optionvalue){
	//these dont actually generate an async event id, so they are only here for consistency sake
	buffer_async_group_option(optionname,optionvalue);
}
#region jsDoc
/// @func    buffer_load_async_promise()
/// @desc    With this function you can load a file that you have created previously using the buffer_save() function (or any of the other functions for saving buffers) into a buffer. The "offset" defines the start position within the buffer for loading (in bytes), and the "size" is the size of the buffer area to be loaded from that offset onwards (also in bytes). You can supply a value of -1 for the size argument and the entire buffer will be loaded. Note that the function will load from a "default" folder, which does not need to be included as part of the file path you provide. This folder will be created if it doesn't exist or when you save a file using buffer_save_async().
/// @param   {Id.Buffer} buffer : The index of the buffer to load.
/// @param   {String} filename : The name of the file to load.
/// @param   {Real} offset : The offset within the buffer to load to (in bytes).
/// @param   {Real} size : The size of the buffer area to load (in bytes).
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function buffer_load_async_promise(
	bufferid,
	filename,
	offset,
	size,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: buffer_load_async_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.SAVE_LOAD;
	var _async_id = buffer_load_async(bufferid,filename,offset,size);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    buffer_save_async_promise()
/// @desc    With this function you can save part of the contents of a buffer to a file, ready to be read back into memory using the buffer_load() function (or any of the other functions for loading buffers). The "offset" defines the start position within the buffer for saving (in bytes), and the "size" is the size of the buffer area to be saved from that offset onwards (also in bytes). This function works asynchronously, and so the game will continue running while being saved, and all files saved using this function will be placed in a "default" folder. This folder does not need to be included in the filename as it is added automatically by GameMaker. For example the filename path "Data\Player_Save.sav" would actually be saved to "default\Data\Player_Save.sav". However, if you then load the file using the function buffer_load_async(), you do not need to supply the "default" part of the path either (but any other file function will require it, except on consoles Xbox One, PS4 and Nintendo Switch).
/// @param   {Id.Buffer} buffer : The index of the buffer to save.
/// @param   {String} filename : The name of the file to save as.
/// @param   {Real} offset : The offset within the buffer to save from (in bytes).
/// @param   {Real} size : The size of the buffer area to save (in bytes).
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function buffer_save_async_promise(
	bufferid,
	filename,
	offset,
	size,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: buffer_save_async_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.SAVE_LOAD;
	var _async_id = buffer_save_async(bufferid,filename,offset,size);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    get_integer_async_promise()
/// @desc    This function opens a window and displays message as well as a space for the user to input a value (which will contain the supplied default value to start with). This is an asynchronous function, and as such GameMaker does not block the device it is being run on while waiting for an answer, but rather keeps on running events as normal. Once the user has typed out their string and pressed the "Okay" button, an asynchronous Dialog event is triggered which, for the duration of that event only, will have a DS map stored in the variable async_load.
/// @param   {String} string : The message to show in the dialog.
/// @param   {Real} default : The default value.
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function get_integer_async_promise(
	str,
	def,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: get_integer_async_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.DIALOG;
	var _async_id = get_integer_async(str,def);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    get_login_async_promise()
/// @desc    This function opens a window that asks the user to input a username and password. These arguments can be set as an empty string or you can store previously entered values to use if you wish. This is an asynchronous function, and as such GameMaker does not block the device it is being run on while waiting for an answer, but rather keeps on running events as normal. Once the user has input the details and pressed the "Okay" button, an asynchronous User Interaction event is triggered which, for the duration of that event only, will have a DS map stored in the variable async_load.
/// @param   {String} username : The default user name
/// @param   {String} password : The default password
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function get_login_async_promise(
	username,
	password,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: get_login_async_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.DIALOG;
	var _async_id = get_login_async(username,password);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    get_string_async_promise()
/// @desc    This function opens a window and displays message as well as a space for the user to input a string (which will contain the supplied default string to start with). This is an asynchronous function, and as such GameMaker does not block the device it is being run on while waiting for an answer, but rather keeps on running events as normal. Once the user has typed out their string and pressed the "Okay" button, an asynchronous Dialog event is triggered which, for the duration of that event only, will have a DS map stored in the variable async_load.
/// @param   {String} string : The message to show in the dialog.
/// @param   {String} default : The default string.
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function get_string_async_promise(
	str,
	def,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: get_string_async_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.DIALOG;
	var _async_id = get_string_async(str,def);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    http_get_promise()
/// @desc    With this function, you connect to the specified URL in order to retrieve information. As this is an asynchronous function, GameMaker will not block while waiting for a reply, but will keep on running unless it gets callback information. This information will be in the form of a string and will trigger an Async Event in any instance that has one defined in their object properties. You should also note that HTTP request parameters (the bits sometimes "tacked on" to the end of a URL when you submit a form on a web page) are perfectly acceptable when using this function, for example:
/// @param   {String} url : The web address of the server that you wish to get information from
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function http_get_promise(
	url,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: http_get_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.HTTP;
	var _async_id = http_get(url);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    http_get_file_promise()
/// @desc    With this function, you can connect to the specified URL in order to retrieve information in the form of a file. As this is an asynchronous function, GameMaker will not block while waiting for a reply, but will keep on running unless it gets callback information. This information will be in the form of a string and will trigger an Async Event in any instance that has one defined in their object properties.
/// @param   {String} url : The web address of the server that you wish to get file from
/// @param   {String} local_target : The local storage path to save the file to
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function http_get_file_promise(
	url, 
	dest,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: http_get_file_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.HTTP;
	var _async_id = http_get_file(url, dest);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    http_post_string_promise()
/// @desc    In computing, a post request is used when the client needs to send data to the server as part of the retrieval request, such as when uploading a file or submitting a completed form, and the same is true of this function in GameMaker. In contrast to the http_get() request method where only a URL is sent to the server, http_post_string() also includes a string that is sent to the server and may result in the creation of a new resource or the update of an existing resource or both. It should be noted that HTTP request parameters (the bits sometimes "tacked on" to the end of a URL when you submit a form on a web page) are perfectly acceptable when using this function too.
/// @param   {String} url : The web address of the server that you wish to get information from
/// @param   {String} string : The string you wish to send to the specified URL
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function http_post_string_promise(
	url, 
	str,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: http_post_string_promise :: Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.HTTP;
	var _async_id = http_post_string(url, str);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    http_request_promise()
/// @desc    With this function, you can create an HTTP header request to define the operating parameters of an HTTP transaction, which can be used for many things like (for example) authentication via HTTP headers if you use RESTful APIs. The function requires the full IP address of the server to request from as well as the type of request to make (as a string, see the note below): "GET", "HEAD", "POST", "PUT", "DELETE", "TRACE", "OPTIONS", or "CONNECT". You will also need to supply a DS map of key/value pairs (as strings, where the key is the header field and the value is the required data for the header), and the final argument is an optional data string that you can add to the request, and if it's not needed then it can be either 0 or an empty string "". Note that you can also send a buffer (see the section on Buffers for more details), in which case the last argument would be the "handle" of the buffer to send.
/// @param   {String} url : The web address of the server that you wish to get information from
/// @param   {String} method : The request method (normally "POST" or "GET", but all methods are supported)
/// @param   {Id.DsMap} header_map : A ds_map with the required header fields
/// @param   {Real,String,Id.Buffer} body : The data to be transmitted following the headers (can be a binary buffer handle)
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function http_request_promise(
	url, 
	_method, 
	header_map, 
	body,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: http_request_promise :: Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.HTTP;
	var _async_id = http_request(url, _method, header_map, body);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    http_set_request_crossorigin_promise()
/// @desc    With this function you can set the cross origin type to use when loading images from a file. The function is exclusively for the HTML5 platform and is only useful when loading sprites from a file using the sprite_add() function. Note that when set to "use-credentials" you no longer need to give an absolute path to the sprite being loaded, but instead would give a relative path (as shown in the example below). By default the cross origin type is set to "anonymous".
/// @param   {String} origin_type : The cross origin type to use (a string)
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function http_set_request_crossorigin_promise(
	crossorigin_type,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: http_set_request_crossorigin_promise :: Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.HTTP;
	var _async_id = http_set_request_crossorigin(crossorigin_type);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    keyboard_virtual_hide_promise()
/// @desc    This function can be used to hide the virtual keyboard on the device running the game. Calling this function will generate a System Asynchronous Event, in which the async_load DS map will be populated with the following key/value pairs:
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function keyboard_virtual_hide_promise(
	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: keyboard_virtual_hide_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.SYSTEM;
	var _async_id = keyboard_virtual_hide();
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    network_connect_async_promise()
/// @desc    With this function you can send a request to connect to a server. The function takes the socket id to connect through (see network_create_socket()) and requires you to give the IP address to connect to (a string) as well as the port to connect through, and if the connection fails a value of less than 0 will be returned. The connection uses a special protocol that ensures only GameMaker games connect to each other, however if you need to connect to a server that is not a GameMaker game, you can use network_connect_async_raw(). Note that this function is asynchronous, generating an Asynchronous Networking event of the type network_type_non_blocking_connect.
/// @param   {Id.Socket} socket : The id of the socket to use.
/// @param   {String} url : The URL or IP to connect to (a string).
/// @param   {Real} port : The port to connect to.
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function network_connect_async_promise(
	socket, 
	url, 
	port,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: network_connect_async_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.NETWORKING;
	var _async_id = network_connect_async(socket, url, port);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    network_connect_raw_async_promise()
/// @desc    With this function you can send a request to connect to a server. The function takes the socket id to connect through (see network_create_socket()) and requires you to give the IP address to connect to (a string) as well as the port to connect through, and if the connection fails a value of less than 0 will be returned. The difference between this function and network_connect_async()is that this function can connect to any server and does nothing to the raw data, meaning that you have to implement the protocols yourself at the server end. Note that this function is asynchronous, generating an Asynchronous Networking event of the type network_type_non_blocking_connect.
/// @param   {Id.Socket} socket : The id of the socket to use.
/// @param   {String} url : The URL or IP to connect to (a string).
/// @param   {Real} port : The port to connect to.
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function network_connect_raw_async_promise(
	socket, 
	url, 
	port,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: network_connect_raw_async_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.NETWORKING;
	var _async_id = network_connect_raw_async(socket, url, port);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    show_message_async_promise()
/// @desc    This function opens a window and displays the message you define in the function to the user. This is an asynchronous function, and as such GameMaker does not block the device it is being run on while waiting for an answer, but rather keeps on running events as normal. Once the user has pressed the "Okay" button, an asynchronous Dialog event is triggered which, for the duration of that event only, will have a ds_map stored in the variable async_load.
/// @param   {Any} string : The message to show to the user.
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function show_message_async_promise(
	str,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: show_message_async_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.DIALOG;
	var _async_id = show_message_async(str);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    show_question_async_promise()
/// @desc    This function opens a window and displays the question you define in the function to the user. This is an asynchronous function, and as such GameMaker does not block the device it is being run on while waiting for an answer, but rather keeps on running events as normal. The function has two buttons that show "Yes" and "No", and once the user has pressed one, an asynchronous Dialog event is triggered which, for the duration of that event only, will have a DS map stored in the variable async_load.
/// @param   {String} string : The question to ask to the user.
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function show_question_async_promise(
	str,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: show_question_async_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.DIALOG;
	var _async_id = show_question_async(str);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    sprite_add_promise()
/// @desc    With this function you can add an image as a sprite, loading it from an external source where the image file to be loaded should always be in either *.png, *.gif, *.jpg/jpeg or *.json format (*json files are used for loading skeleton animation sprites made with Spine). The function returns the new sprite index which must then be used in all further code that relates to the sprite. If you use this function with HTML5 or are getting an image from a URL, this function will also generate an Image Loaded asynchronous event. See this page for more information.
/// @param   {String} fname : The name (a string file path) of the file to add.
/// @param   {Real} imgnum : Use to indicate the number of sub-images (1 for a single image or for a *.gif).
/// @param   {Bool} removeback : Indicates whether to make all pixels with the background colour (left-bottom pixel) transparent.
/// @param   {Bool} smooth : Indicates whether to smooth the edges if transparent.
/// @param   {Real} xorig : Indicate the x position of the origin in the sprite.
/// @param   {Real} yorig : Indicate the y position of the origin in the sprite.
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function sprite_add_promise(
	fname,
	imgnumb,
	removeback,
	smooth,
	xorg,
	yorig,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: sprite_add_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.IMAGE_LOADED;
	var _async_id = sprite_add(fname,imgnumb,removeback,smooth,xorg,yorig);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    sprite_add_ext_promise()
/// @desc    With this function you can asynchronously add an image as a sprite, loading it from an external source where the image file to be loaded should always be in either *.png, *.gif, *.jpg/jpeg or *.json format (*json files are used for loading skeleton animation sprites made with Spine). The function returns the new sprite index which must then be used in all further code that relates to the sprite. This function will generate an Image Loaded asynchronous event when the sprite has been loaded. See this page for more information.
/// @param   {String} fname : The name (a string file path) of the file to add.
/// @param   {Real} imgnum : Use to indicate the number of sub-images (1 for a single image or for a *.gif).
/// @param   {Real} xorig : Indicate the x position of the origin in the sprite.
/// @param   {Real} yorig : Indicate the y position of the origin in the sprite.
/// @param   {Bool} prefetch : Indicates whether the sprite should be loaded to GPU memory.
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function sprite_add_ext_promise(
	fname,
	imgnumb,
	xorg,
	yorig,
	prefetch,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: sprite_add_ext_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.IMAGE_LOADED;
	var _async_id = sprite_add_ext(fname,imgnumb,xorg,yorig,prefetch);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
#region jsDoc
/// @func    zip_unzip_async_promise()
/// @desc    This function will open a stored zip file and extract its contents to the given directory asynchronously. Note that if you do not supply a full path to the ZIP directory then the current drive root will be used, and if you want to place it in a relative path to the game bundle working directory then you should use the working_directory variable as part of the path (relative paths using "." or ".." will not work as expected so should be avoided). Note too that the zip must be either part of the game bundle (ie: an Included File) or have been downloaded to the storage area using http_get_file().
/// @param   {String} zip_file : The zip file to open
/// @param   {String} target_directory : The target directory to extract the files to
/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
/// @returns {Struct.Promise}
#endregion
function zip_unzip_async_promise(
	file, 
	destPath,
 	_resolve_callback=undefined,
	_reject_callback=function(_reason){ show_debug_message("Promise :: zip_unzip_async_promise :: Promise Failed with error : "+_reason) }
)
{
	var _async_type = ASYNC_EVENT.SAVE_LOAD;
	var _async_id = zip_unzip_async(file, destPath);
	return __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback);
}
