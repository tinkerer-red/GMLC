/// @title Core Promise

#macro PROMISE_MAX_TIME (1/game_get_speed(gamespeed_fps) * 1_000_000) * (1/8) //the max time in milli seconds to spend on the promises, default is 1/16 of frame time of a 60 fps game

enum PROMISE_STATE {
	PENDING,
	RESOLVED,
	REJECTED,
	PAUSED,
	CANCELED,
};

#region jsDoc
/// @func    Promise()
/// @constructor
/// @desc    The Promise() constructor creates Promise objects. It is primarily used to wrap callback-based APIs that do not already support promises.
/// @param   {Function} task : A function to asynchronously execute after the previous step. Its return value becomes the fulfillment value of the promise returned by then().
/// @returns {Struct.Promise}
#endregion
function Promise(_executor) constructor {
	
	// State and value of the promise
	executors = (_executor == undefined) ? [] : [_executor];
	state = PROMISE_STATE.PENDING;
	value = undefined;
	reason = undefined;
	on_resolved = undefined;
	on_rejected = function(_reason){ show_debug_message("Promise Failed with error : "+_reason) };
	
	#region jsDoc
	/// @method    Then()
	/// @desc    The Then() method of Promise instances takes a callback function for the fulfilled case of the Promise. It immediately returns another Promise object, allowing you to chain calls to other promise methods.
	/// @self    Promise
	/// @param   {Function} task : A function to asynchronously execute after the previous step. Its return value becomes the fulfillment value of the promise returned by then().
	/// @returns {Struct.Promise}
	#endregion
	static Then = function(_executor) {
		var _this_promise = (is_instanceof(self, Promise)) ? self : new Promise();
		
		array_push(_this_promise.executors, _executor);
		
		return _this_promise;
	};
	#region jsDoc
	/// @method    Catch()
	/// @desc    The Catch() method of Promise instances schedules a function to be called when the promise is rejected. It immediately returns another Promise object, allowing you to chain calls to other promise methods.
	/// @self    Promise
	/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
	/// @returns {Struct.Promise}
	#endregion
	static Catch = function(_rejected_callback) {
		var _this_promise = (is_instanceof(self, Promise)) ? self : new Promise();
		
		_this_promise.on_rejected = _rejected_callback;
		
		return _this_promise;
	};
	#region jsDoc
	/// @method    Finally()
	/// @desc    The Finally() method of Promise instances schedules a function to be called when the promise is settled (either fulfilled or rejected). It immediately returns another Promise object, allowing you to chain calls to other promise methods.
	/// @self    Promise
	/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
	/// @returns {Struct.Promise}
	#endregion
	static Finally = function(_resolved_callback) {
		var _this_promise = (is_instanceof(self, Promise)) ? self : new Promise();
		
		_this_promise.on_resolved = _resolved_callback;
		
		return _this_promise;
	};
	
	#region jsDoc
	/// @method    Resolve()
	/// @desc    The Promise.Resolve() static method "resolves" a given value to a Promise. If the value is a promise, that promise is returned; if the value is a thenable, Promise.Resolve() will call the then() method with two callbacks it prepared; otherwise the returned promise will be fulfilled with the value.
	/// @self    Promise
	/// @param   {Any} value : Argument to be resolved by this Promise. Can also be a Promise or a thenable to resolve.
	/// @returns {Struct.Promise}
	#endregion
	static Resolve = function(_value) {
		var _this_promise = (is_instanceof(self, Promise)) ? self : new Promise();
		
		_this_promise.state = PROMISE_STATE.PENDING;
		_this_promise.value = _value;
			
		return _this_promise;
	};
	#region jsDoc
	/// @method    Reject()
	/// @desc    The Promise.reject() static method returns a Promise object that is rejected with a given reason.
	/// @self    Promise
	/// @param   {Any} reason : Reason why this Promise rejected.
	/// @returns {Struct.Promise}
	#endregion
	static Reject = function(_reason) {
		var _this_promise = (is_instanceof(self, Promise)) ? self : new Promise();
		
		_this_promise.state = PROMISE_STATE.REJECTED;
		_this_promise.reason = _reason;
		
		return _this_promise;
	};
	
	
	#region jsDoc
	/// @method    Pause()
	/// @desc    Pauses the Promise from any execution.
	/// @self    Promise
	/// @param   {Function} task : A function to asynchronously execute after the previous step. Its return value becomes the fulfillment value of the promise returned by then().
	/// @returns {Struct.Promise}
	#endregion
	static Pause = function() {
		var _this_promise = (is_instanceof(self, Promise)) ? self : new Promise();
		
		state = PROMISE_STATE.PAUSED;
		
		return _this_promise;
	};
	#region jsDoc
	/// @method    Resume()
	/// @desc    Resumes the execution of the Promise.
	/// @self    Promise
	/// @param   {Function} errback : A function to asynchronously execute when this promise becomes rejected. Its return value becomes the fulfillment value of the promise returned by catch().
	/// @returns {Struct.Promise}
	#endregion
	static Resume = function() {
		var _this_promise = (is_instanceof(self, Promise)) ? self : new Promise();
		
		state = PROMISE_STATE.PENDING;
		
		return _this_promise;
	};
	#region jsDoc
	/// @method    Cancel()
	/// @desc    Cancel All execution of the promise, this includes prevention of callbacks and errorbacks
	/// @self    Promise
	/// @param   {Function} callback : A function to asynchronously execute when this promise becomes settled. Its return value is ignored unless the returned value is a rejected promise.
	/// @returns {Struct.Promise}
	#endregion
	static Cancel = function(_reason="Canceled manually.") {
		var _this_promise = (is_instanceof(self, Promise)) ? self : new Promise();
		
		_this_promise.state = PROMISE_STATE.CANCELED;
		_this_promise.reason = _reason;
		
		return _this_promise;
	};
	
	
	
	#region Promise Parenting
	
	#region jsDoc
	/// @method    All()
	/// @desc    The Promise.All() static method takes an iterable of promises as input and returns a single Promise. This returned promise fulfills when all of the input's promises fulfill (including when an empty iterable is passed), with an array of the fulfillment values. It rejects when any of the input's promises rejects, with this first rejection reason.
	/// @self    Promise
	/// @param   {Array<Struct.Promise>} arr_of_promises : Array of Promises to be used as children
	/// @returns {Struct.Promise}
	#endregion
	static All = function(_arr_of_promises) {
		var _parent_promise = new Promise();
		
		_parent_promise.state = PROMISE_STATE.PAUSED;
		_parent_promise.sub_promises = _arr_of_promises;
		_parent_promise.resolved_count = 0;
		_parent_promise.value = [];
		
		var _i=0; repeat(array_length(_arr_of_promises)) {
			var _promise = _arr_of_promises[_i];
			_promise.parent = _parent_promise;
			_promise.index_in_parent = _i;
			
			_promise.Then(method(_promise, function(_value){
				parent.value[index_in_parent] = _value;
				parent.resolved_count += 1;
					
				if (parent.resolved_count == array_length(parent.sub_promises)) {
					parent.state = PROMISE_STATE.PENDING;
				}
					
				return _value;
			}))
			.Catch(method(_parent_promise, function(_reason) {
				if (state != PROMISE_STATE.REJECTED) {
					state = PROMISE_STATE.REJECTED;
					reason = _reason;
				}
			}));
			
		_i+=1;}//end repeat loop
		
		return _parent_promise;
	};
	
	//wait for all to finish, then get reports
	#region jsDoc
	/// @method    AllSettled()
	/// @desc    The Promise.AllSettled() static method takes an iterable of promises as input and returns a single Promise. This returned promise fulfills when all of the input's promises settle (including when an empty iterable is passed), with an array of objects that describe the outcome of each promise.
	/// @self    Promise
	/// @param   {Array<Struct.Promise>} arr_of_promises : Array of Promises to be used as children
	/// @returns {Struct.Promise}
	#endregion
	static AllSettled = function(_arr_of_promises) {
		var _parent_promise = new Promise();
		
		_parent_promise.state = PROMISE_STATE.PAUSED;
		_parent_promise.sub_promises = _arr_of_promises;
		_parent_promise.resolved_count = 0;
		_parent_promise.value = [];
		
		var _i=0; repeat(array_length(_arr_of_promises)) {
			var _promise = _arr_of_promises[_i];
			_promise.parent = _parent_promise;
			_promise.index_in_parent = _i;
			
			_promise.Then(method(_promise, function(_value){
				parent.value[index_in_parent] = { status: "RESOLVED", value: _value };
				parent.resolved_count += 1;
					
				if (parent.resolved_count == array_length(parent.sub_promises)) {
					parent.state = PROMISE_STATE.PENDING;
				}
					
				return _value;
			}))
			.Catch(method(_promise, function(_reason) {
				var _error = (is_struct(_reason)) ? _reason.message : _reason;
				parent.value[index_in_parent] = { status: "rejected", reason: _error };
				parent.resolved_count += 1;
				
				if (parent.resolved_count == array_length(parent.sub_promises)) {
					parent.state = PROMISE_STATE.PENDING;
				}
			}));
			
		_i+=1;}//end repeat loop
		
		return _parent_promise;
	};
	
	//if any succeed
	#region jsDoc
	/// @method    Any()
	/// @desc    The Promise.any() static method takes an iterable of promises as input and returns a single Promise. This returned promise fulfills when any of the input's promises fulfills, with this first fulfillment value. It rejects when all of the input's promises reject (including when an empty iterable is passed), with an AggregateError containing an array of rejection reasons.
	/// @self    Promise
	/// @param   {Array<Struct.Promise>} arr_of_promises : Array of Promises to be used as children
	/// @returns {Struct.Promise}
	#endregion
	static Any = function(_arr_of_promises) {
		var _parent_promise = new Promise();
		
		_parent_promise.state = PROMISE_STATE.PAUSED;
		_parent_promise.sub_promises = _arr_of_promises;
		_parent_promise.resolved_count = 0;
		_parent_promise.value = [];
		
		var _i=0; repeat(array_length(_arr_of_promises)) {
			var _promise = _arr_of_promises[_i];
			_promise.parent = _parent_promise;
			_promise.index_in_parent = _i;
			
			_promise.Then(method(_parent_promise, function(_value) {
				state = PROMISE_STATE.PENDING;
				value = _value;
				
				return _value;
			}))
			.Catch(method(_parent_promise, function(_reason){
				resolved_count += 1;
				if (resolved_count == array_length(sub_promises)) {
					state = PROMISE_STATE.REJECTED;
					reason = _reason;
				}
			}));
			
		_i+=1;}//end repeat loop
		
		return _parent_promise;
	};
	
	//first come first server
	#region jsDoc
	/// @method    Race()
	/// @desc    The Promise.Race() static method takes an iterable of promises as input and returns a single Promise. This returned promise settles with the eventual state of the first promise that settles.
	/// @self    Promise
	/// @param   {Array<Struct.Promise>} arr_of_promises : Array of Promises to be used as children
	/// @returns {Struct.Promise}
	#endregion
	static Race = function(_arr_of_promises) {
		var _parent_promise = new Promise();
		
		_parent_promise.state = PROMISE_STATE.PAUSED;
		_parent_promise.sub_promises = _arr_of_promises;
		_parent_promise.resolved_count = 0;
		_parent_promise.value = [];
		
		var _i=0; repeat(array_length(_arr_of_promises)) {
			var _promise = _arr_of_promises[_i];
			_promise.parent = _parent_promise;
			_promise.index_in_parent = _i;
			
			_promise.Then(method(_parent_promise, function(_value) {
				if (state == PROMISE_STATE.PAUSED) {
					state = PROMISE_STATE.RESOLVED;
					value = _value;
				}
				
				return _value;
			}))
			.Catch(method(_parent_promise, function(_reason) {
				if (state == PROMISE_STATE.PAUSED) {
					state = PROMISE_STATE.REJECTED;
					reason = _reason;
				}
			}));
			
		_i+=1;}//end repeat loop
		
		return _parent_promise;
	};
	
	#endregion
	
	//note providing no start time will force the promise to execute all sub processes
	static Execute = function(_time_to_live=infinity) {
		static __global = __PromiseNamespace__.__global;
		
		if (state == PROMISE_STATE.PAUSED) {
			return;
		}
			
		if (state == PROMISE_STATE.PENDING) {
			if (array_length(executors)) {
				try {
					var _j=0; repeat(array_length(executors)) {
						var _executor = executors[0];
						var _val = _executor(value);
						
						if (__global.postpone_task_removal) {
							__global.postpone_task_removal = false;
						}
						else {
							array_delete(executors, 0, 1);
							value = (is_undefined(_val)) ? value : _val;
						}
						
						//early out
						if (state == PROMISE_STATE.PAUSED)
						|| (state == PROMISE_STATE.CANCELED)
						|| (get_timer() >= _time_to_live)
						{
							break;
						}
						
						if (array_length(executors) == 0) {
							state = PROMISE_STATE.RESOLVED;
							break;
						}
						
					_j+=1;}//end repeat loop
				}
				catch (_error) {
					state = PROMISE_STATE.REJECTED;
					reason = _error;
				}
			}
			else {
				state = PROMISE_STATE.RESOLVED;
			}
		}
				
		if (state == PROMISE_STATE.RESOLVED) {
			if (on_resolved != undefined) {
				on_resolved(value);
			}
		}
				
		if (state == PROMISE_STATE.REJECTED) {
			if (on_rejected != undefined) {
				var _error = (is_struct(reason)) ? reason.message : reason;
				on_rejected(_error);
			}
		}
			
		return true;
	}
	
	var _promise = self;
	
	#region Private
		
		static __promise_id = 0;
		__promise_id+=1;
		_promise.promise_id = __promise_id;
		
		static __global = __PromiseNamespace__();
		time_source_start(__global.promises_time_source);
		
		array_push(__global.active_promises, _promise);
		
	#endregion
	
	return _promise;
}


/////////////////////////////////
/// For Library and Tool creators
/////////////////////////////////

#region jsDoc
/// @func    PromiseExceededFrameBudget()
/// @desc    A helper function to assist library creators in knowing if the frame budget has been exceeded so they can exit their task.
/// @returns {Bool}
#endregion
function PromiseExceededFrameBudget() {
	static __global = __PromiseNamespace__.__global
	return (get_timer() >= __global.time_to_live);
}

#region jsDoc
/// @func    PromisePostponeTaskRemoval()
/// @desc    A helper function to assist library creators to have better control of when to remove a currently active task/executor. This is commonly used when you have a single function which can execute across multiple frames, but it's not finished and you wish to keep the currently running task in the queue to be executred next frame.
/// @returns {Bool}
#endregion
function PromisePostponeTaskRemoval() {
	static __global = __PromiseNamespace__.__global
	__global.postpone_task_removal = true;
}



#region init statics and start timers
new Promise();
time_source_start(__PromiseNamespace__.__global.async_obj_spawn_time_source);
#endregion