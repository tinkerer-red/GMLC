

/// @ignore
function FlexiParseBase() constructor {
	logEnabled = false;
	
	should_catch_errors = false;
	error_handler = function(_error){ show_debug_message("[ERROR] " + instanceof(self) + " :: " + string(_error)); }
	
	async_active = false;
	async_max_time = (1/game_get_speed(gamespeed_fps) * 1_000) * (1/8) //the max time to spend parsing, default is 1/8th of a frame time.
	async_promise = undefined;
	
	parserSteps = [];  // List to store the indevidual parse operations, order important
	
	#region Basic
	#region jsDoc
	/// @func    initialize()
	/// @desc    Initializes the parser with its input data. Executes the custom initialize function.
	///
	///          New stack is resized, and the custom initialization logic is applied.
	/// @self    FlexiParseBase
	/// @param   {any} _input : The input data to initialize the parser with
	/// @returns {undefined}
	#endregion
	static initialize = function(_input) {
		if (async_promise != undefined) {
			async_promise.Cancel();
			__cleanup();
		}
		__initialize(_input);
	};
	
	#region jsDoc
	/// @func    cleanup()
	/// @desc    Cleans up any active time source. Also executes the custom cleanup function.
	/// @self    FlexiParseBase
	/// @returns {undefined}
	#endregion
	static cleanup = function() {
		if (async_promise != undefined) {
			async_promise.Cancel()
		}
		__cleanup();
	}
	
	#region jsDoc
	/// @func    isFinished()
	/// @desc    Checks if the parsing is finished.
	/// @self    FlexiParseBase
	/// @returns {boolean}
	#endregion
	static isFinished = function() {
		return __isFinished();
	}
	
	#region jsDoc
	/// @func    finalize()
	/// @desc    Finalizes the parsing process. Executes the custom finalize function.
	/// @self    FlexiParseBase
	/// @returns {any}
	#endregion
	static finalize = function() {
		return __finalize()
	}
	
	#region jsDoc
	/// @func    print()
	/// @desc    Logs a message to the console if logging is enabled.
	/// @self    FlexiParseBase
	/// @param   {string} _str : The message to log
	/// @returns {undefined}
	#endregion
	static print = function(_str) {
		if (logEnabled) {
		    show_debug_message($"[INFO] Logger :: {instanceof(self)} :: " + _str);
		}
	};
	
	#endregion
		
	#region Async
	#region jsDoc
	/// @func    parseAsync()
	/// @desc    Asynchronously parses the tokens in the stack. Parses until it's finished or until time runs out.
	///
	///          If the parsing is completed, the callback is executed. Optionally accepts an error callback.
	/// @self    FlexiParseBase
	/// @param   {function} _callback  : The callback to execute when parsing is complete
	/// @param   {function} [_errback] : Optional error callback to handle parsing errors
	/// @returns {any} : The time source reference for the async execution
	#endregion
	static parseAsync = function(_callback, _errback=undefined) {
		async_active = true;
		
		async_promise = new Promise(method(self, function() {
			while (!PromiseExceededFrameBudget()) {
				parseNext();
				
				if (isFinished()) {
					async_active = false;
					return finalize();
				}
			}
			PromisePostponeTaskRemoval();
		}))
		
		if (_callback != undefined) {
			async_promise.Then(_callback);
		}
		
		if (_errback != undefined) {
			async_promise.Catch(_errback ?? error_handler);
		}
		
		return async_promise
	}
		
	#region jsDoc
	/// @func    asyncPause()
	/// @desc    Pauses the asynchronous parsing process.
	/// @self    FlexiParseBase
	/// @returns {undefined}
	#endregion
	static asyncPause = function() {
		if (async_promise != undefined) {
			async_promise.Pause()
		}
		async_active = false;
	};
		
	#region jsDoc
	/// @func    asyncResume()
	/// @desc    Resumes the asynchronous parsing process.
	/// @self    FlexiParseBase
	/// @returns {undefined}
	#endregion
	static asyncResume = function() {
		if (async_promise != undefined) {
			async_promise.Resume()
			async_active = true;
		}
	};
		
	#region jsDoc
	/// @func    asyncCancel()
	/// @desc    Cancels the asynchronous parsing process and destroys the active time source.
	/// @self    FlexiParseBase
	/// @returns {undefined}
	#endregion
	static asyncCancel = function() {
		if (async_promise != undefined) {
			async_promise.Cancel()
		}
		async_active = false;
	};
		
	#endregion
		
	#region Parsing Steps
	#region jsDoc
	/// @func    parseAll()
	/// @desc    Parses all tokens in the stack regardless of CPU usage or time. Calls nextToken for every token until finished.
	/// @self    FlexiParseBase
	/// @returns {any} : The result of the finalize function after parsing all tokens
	#endregion
	static parseAll = function() {
		while (!isFinished()) {
			parseNext();
		}
		return finalize();
	}
	
	#region jsDoc
	/// @func    nextToken()
	/// @desc    Processes the next token using the added parser steps. If errors are to be caught, they will be handled via the error handler.
	/// @self    FlexiParseBase
	/// @returns {undefined}
	#endregion
	static nextToken = function() {
		return __nextToken();
	};
		
	#region jsDoc
	/// @func    parseNext()
	/// @desc    Runs each parser step function on the current token in sequence.
	/// @self    FlexiParseBase
	/// @returns {undefined}
	#endregion
	static parseNext = function() {
		if (should_catch_errors) {
			try {
				for (var i = 0; i < array_length(parserSteps); i++) {
					var _shouldBreak = parserSteps[i]();  // Pass the token through each parser step
					if (_shouldBreak) {
						break;
					}
				}
			} catch (e) {
				error_handler(e);
			}
		}
		else {
			for (var i = 0; i < array_length(parserSteps); i++) {
				var _shouldBreak = parserSteps[i]();  // Pass the token through each parser step
				if (_shouldBreak) {
					break;
				}
			}
		}
	};
	
	#region jsDoc
	/// @func    addParserStep()
	/// @desc    Adds a parser step (function) to the list of steps to be executed during parsing.
	/// @self    FlexiParseBase
	/// @param   {function} step : The parser function to be added to the list
	/// @returns {undefined}
	#endregion
	static addParserStep = function(step) {
		array_push(parserSteps, step);
	};
		
	#region jsDoc
	/// @func    clearParserSteps()
	/// @desc    Clears all parser steps from the list. Useful for resetting or changing the parsing process.
	/// @self    FlexiParseBase
	/// @returns {undefined}
	#endregion
	static clearParserSteps = function() {
		array_resize(parserSteps, 0);
	};
	
	#endregion
	
	#region Builders
	#region jsDoc
	/// @func    setErrorHandler()
	/// @desc    Sets a custom error handler function to handle errors during parsing.
	/// @self    FlexiParseBase
	/// @param   {function} _handler : The custom error handler function
	/// @returns {undefined}
	#endregion
	static setErrorHandler = function(_handler) {
		error_handler = _handler;
	}
		
	#region jsDoc
	/// @func    setAsyncMaxTime()
	/// @desc    Sets the maximum time allowed for async parsing within one frame.
	/// @self    FlexiParseBase
	/// @param   {number} _max_time : The maximum time (in ms) allowed for async parsing
	/// @returns {undefined}
	#endregion
	static setAsyncMaxTime = function(_max_time) {
		async_max_time = _max_time;
	};
		
	#region jsDoc
	/// @func    setCustomInitialize()
	/// @desc    Sets the custom initialize function to be used by the parser.
	/// @self    FlexiParseBase
	/// @param   {function} _func : The custom initialization function
	/// @returns {undefined}
	#endregion
	static setCustomInitialize = function(_func) {
		__initialize = _func;
	}
		
	#region jsDoc
	/// @func    setCustomCleanup()
	/// @desc    Sets the custom cleanup function to be used by the parser.
	/// @self    FlexiParseBase
	/// @param   {function} _func : The custom cleanup function
	/// @returns {undefined}
	#endregion
	static setCustomCleanup = function(_func) {
		__cleanup = _func;
	}
		
	#region jsDoc
	/// @func    setCustomFinalize()
	/// @desc    Sets the custom finalize function to be used by the parser.
	/// @self    FlexiParseBase
	/// @param   {function} _func : The custom finalize function
	/// @returns {undefined}
	#endregion
	static setCustomFinalize = function(_func) {
		__finalize = _func;
	}
		
	#region jsDoc
	/// @func    setCustomIsFinished()
	/// @desc    Sets the custom isFinished function to check if parsing is completed.
	/// @self    FlexiParseBase
	/// @param   {function} _func : The custom isFinished function
	/// @returns {undefined}
	#endregion
	static setCustomIsFinished = function(_func) {
		__isFinished = _func;
	}
		
	#region jsDoc
	/// @func    setCustomNextToken()
	/// @desc    Sets the custom nextToken function to process tokens in the stack.
	/// @self    FlexiParseBase
	/// @param   {function} _func : The custom nextToken function
	/// @returns {undefined}
	#endregion
	static setCustomNextToken = function(_func) {
		__nextToken = _func;
	}
		
	#region jsDoc
	/// @func    setLogEnabled()
	/// @desc    Enables or disables logging for the parser.
	/// @self    FlexiParseBase
	/// @param   {boolean} enabled : Whether logging should be enabled
	/// @returns {undefined}
	#endregion
	static setLogEnabled = function(enabled) {
		logEnabled = enabled;
	};
		
	#region jsDoc
	/// @func    setErrorHandler()
	/// @desc    Sets whether errors should be caught during parsing and handled by the error handler.
	/// @self    FlexiParseBase
	/// @param   {boolean} _enabled : Whether error catching should be enabled
	/// @returns {undefined}
	#endregion
	static setErrorHandler = function(_enabled) {
		should_catch_errors = _enabled;
	}
		
	#endregion
	
}
