/// @ignore
function __PromiseNamespace__() {
	//used to help evacuate the global struct so the variables are not easily accessed by users
	static __global = {
		promises_time_source : time_source_create(time_source_game, 1, time_source_units_frames, function() {
			static __global = __PromiseNamespace__()
			//handle all of the currently active processes
			__global.postpone_task_removal = false; //reset just incase someone is calling this outside of a promise function.
			__global.time_to_live = get_timer() + PROMISE_MAX_TIME;
			
			var _i=0; repeat(array_length(__global.active_promises)) {
				var _promise = __global.active_promises[_i];
				
				if (_promise.state == PROMISE_STATE.CANCELED) {
					array_delete(__global.active_promises, _i, 1);
					continue;
				}
				
				_promise.Execute(__global.time_to_live);
				
				if (__global.postpone_task_removal) {
					__global.postpone_task_removal = false;
				}
				else if (_promise.state == PROMISE_STATE.RESOLVED)
				|| (_promise.state == PROMISE_STATE.REJECTED)
				|| (_promise.state == PROMISE_STATE.CANCELED)
				{
					array_delete(__global.active_promises, _i, 1);
					_i-=1;
				}
				
				//early out
				if (get_timer() >= __global.time_to_live) {
					break;
				}
				
			_i+=1;}//end repeat loop
			
			//if we have completed all promises
			if (array_length(__global.active_promises) == 0) {
				time_source_pause(__global.promises_time_source)
			}
			
		}, [], -1),
		async_obj_spawn_time_source : time_source_create(time_source_game, 1, time_source_units_frames, function() {
			static __global = __PromiseNamespace__();
			if (!instance_exists(__obj_promise)) instance_create_depth(0,0,0,__obj_promise);
			time_source_destroy(__global.async_obj_spawn_time_source, true);
		}, [], 1),
		active_promises : [],
		async_promises: {},
		async_listeners: {},
		time_to_live: get_timer() + PROMISE_MAX_TIME,
		postpone_task_removal: false,
	};
	
	return __global;
}

/// @ignore
function __handleAsyncEvent(_async_type, _async_load) {
	static __global = __PromiseNamespace__();
	
	var _type_struct = __global.async_promises[$ _async_type];
	if (_type_struct != undefined) {
		
		var _async_id = _async_load[? "id"];
		var _handler = _type_struct[$ _async_id];
		
		if (_handler != undefined) {
			if (_async_load[? "status"] < 0) {
				_handler.reject_callback(_async_load[? "http_status"] ?? ":: Unknown Error occurred in async operation, ID = "+string(_async_id)+" ::");
				// Remove the handler
				struct_remove(_type_struct, _async_id);
			}
			else if (_async_load[? "status"] == 0 || _async_load[? "status"] == undefined) {
				_handler.resolve_callback(_async_load);
				// Remove the handler
				struct_remove(_type_struct, _async_id);
			}
		}
		
	}
	
	var _type_struct = __global.async_listeners[$ _async_type];
	if (_type_struct != undefined) {
		
		var _async_id = _async_load[? "id"];
		var _listeners = _type_struct[$ _async_id];
		
		if (_listeners != undefined) {
			
			var _i=0; repeat(array_length(_listeners)) {
				var _listener = _listeners[_i];
				
				if (_async_load[? "status"] < 0) {
					_listener.reject_callback(_async_load[? "http_status"] ?? ":: Unknown Error occurred in async operation, ID = "+string(_async_id)+" ::");
					// Remove the handler
					struct_remove(_type_struct, _async_id);
				}
				else if (_async_load[? "status"] == 0) {
					_listener.resolve_callback(_async_load);
					// Remove the handler
					struct_remove(_type_struct, _async_id);
				}
				
			_i++}
		}
	}
	
	
}

//Use this function if you would like to add promises to your library.
/// @ignore
function __registerAsyncHandler(_async_type, _async_id, _resolve_callback, _reject_callback) {
	static __global = __PromiseNamespace__();
	
	if (_resolve_callback == undefined) _resolve_callback = function(){};
	
	var _promise = Promise.Finally(_resolve_callback).Catch(_reject_callback);
	_promise.state = PROMISE_STATE.PAUSED;
	
	var _resolve = method(_promise, function(_async_load){
		state = PROMISE_STATE.PENDING;
		value = json_parse(json_encode(_async_load));
	});
	
	var _reject = method(_promise, function(_error){
		state = PROMISE_STATE.REJECTED;
		reason = _error;
	});
	
	var handler = {
		type: _async_type,
		async_id: _async_id,
		resolve_callback: _resolve,
		reject_callback: _reject,
	};
	
	//add a new reference
	if (!struct_exists(__global.async_promises, _async_type)) __global.async_promises[$ _async_type] = {};
	
	//add handler
	if (!struct_exists(__global.async_promises[$ _async_type], _async_id)) __global.async_promises[$ _async_type][$ _async_id] = handler;
	
	return _promise;
}

//ev_async_web_image_load // Image Loaded event
//ev_async_web // HTTP event
//ev_async_dialog // Dialog event
//ev_async_web_iap // In-App Purchase event
//ev_async_web_cloud // Cloud event
//ev_async_web_networking // Networking event
//ev_async_web_steam // Steam event
//ev_async_social // Social event
//ev_async_push_notification // Push Notification event
//ev_async_save_load // Save/Load Event
//ev_async_audio_recording // Audio Recording event
//ev_async_audio_playback // Audio Playback event
//ev_async_audio_playback_ended // Audio Playback Ended event
//ev_async_system_event // System event

/// @ignore
enum ASYNC_EVENT {
	AUDIO_PLAYBACK,
	AUDIO_PLAYBACK_ENDED,
	AUDIO_RECORDING,
	CLOUD,
	DIALOG,
	HTTP,
	IN_APP_PURCHASE,
	IMAGE_LOADED,
	NETWORKING,
	PUSH_NOTIFICATIONS,
	SAVE_LOAD,
	SOCIAL,
	STEAM,
	SYSTEM,
	__SIZE__,
}
