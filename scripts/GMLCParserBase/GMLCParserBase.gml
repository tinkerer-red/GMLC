#region ParserBase.gml
	#region ParserBase
	/*
	Purpose: The base constructor for all parsers to abide by, helps to standardize function names, and allow for easy logging, debugging, and async execution.
	
	Methods:
	
	initialize  :: initialize the parser with it's input data, this will also execute the custom initialize function supplied
	cleanup     :: cleans up any active time source, this will also execute the custom cleanup function supplied
	isFinished :: returns if the parsing is finished
	finalize    :: should not be called externally, it's called as soon as the parsing is finished, this will also execute the custom finalize function supplied
	parseAll    :: forcibly parse all, regardless of time or cpu usage.
	parseAsync  :: creates a time source which will parse passively until it's finished then execute the callback with the supplied data from your custom finalize function
	nextToken   :: this will execute your custom nextToken function with the input being the current token.

	*/
	#endregion
	/// @ignore
	function GMLCParserBase() constructor {
		//init variables:
		target = undefined;
		stack = [];
		finished = false;
		
		logEnabled = false;
		should_catch_errors = true;
		error_handler = function(_error){ show_debug_message("[ERROR] " + instanceof(self) + " :: " + string(_error)); }
		
		async_active = false;
		async_max_time = (1/gamespeed_fps * 1_000) * (1/8) //the max time to spend parsing, default is 1/8th of a frame time.
		async_start_time = undefined;
		async_time_source = undefined;
		async_callback = undefined;
		
		parserSteps = [];  // List to store the indevidual parse operations, order important
		
		#region Basic
		#region jsDoc
		/// @func    initialize()
		/// @desc    Initializes the parser with its input data. Executes the custom initialize function.
		///
		///          New stack is resized, and the custom initialization logic is applied.
		/// @self    ParserBase
		/// @param   {any} _input : The input data to initialize the parser with
		/// @returns {undefined}
		#endregion
		static initialize = function(_input) {
			array_resize(stack, 0);
			__initialize(_input);
			currentTarget = undefined;
		};
		
		#region jsDoc
		/// @func    cleanup()
		/// @desc    Cleans up any active time source. Also executes the custom cleanup function.
		/// @self    ParserBase
		/// @returns {undefined}
		#endregion
		static cleanup = function() {
			if (async_time_source != undefined) {
				time_source_destroy(async_time_source);
			}
			__cleanup();
		}
		
		#region jsDoc
		/// @func    isFinished()
		/// @desc    Checks if the parsing is finished.
		/// @self    ParserBase
		/// @returns {boolean}
		#endregion
		static isFinished = function() {
			return __isFinished();
		}
		
		#region jsDoc
		/// @func    finalize()
		/// @desc    Finalizes the parsing process. Executes the custom finalize function.
		/// @self    ParserBase
		/// @returns {any}
		#endregion
		static finalize = function() {
			return __finalize()
		}
		
		#region jsDoc
		/// @func    parseAll()
		/// @desc    Parses all tokens in the stack regardless of CPU usage or time. Calls nextToken for every token until finished.
		/// @self    ParserBase
		/// @returns {any} : The result of the finalize function after parsing all tokens
		#endregion
		static parseAll = function() {
			while (!isFinished()) {
				var _token = nextToken();
			}
			return finalize();
		}
		
		#region jsDoc
		/// @func    print()
		/// @desc    Logs a message to the console if logging is enabled.
		/// @self    ParserBase
		/// @param   {string} _str : The message to log
		/// @returns {undefined}
		#endregion
		static print = function(_str) {
		    if (logEnabled) {
		        show_debug_message("[INFO] Logger :: " + _str);
		    }
		};
		
		#endregion
		
		#region Async
		#region jsDoc
		/// @func    parseAsync()
		/// @desc    Asynchronously parses the tokens in the stack. Parses until it's finished or until time runs out.
		///
		///          If the parsing is completed, the callback is executed. Optionally accepts an error callback.
		/// @self    ParserBase
		/// @param   {function} _callback  : The callback to execute when parsing is complete
		/// @param   {function} [_errback] : Optional error callback to handle parsing errors
		/// @returns {any} : The time source reference for the async execution
		#endregion
		static parseAsync = function(_callback, _errback=undefined) {
			async_active = true;
			async_callback = _callback;
			error_handler  = _errback ?? error_handler;
			
			var _asyncParse = method(self, function() {
				async_start_time = current_time;
				while (current_time-async_start_time < async_max_time) {
					nextToken();
					
					if (isFinished()) {
						async_active = false;
						async_callback(finalize());
						time_source_destroy(async_time_source);
						async_time_source = undefined;
						break;
					}
				}
			})
			
			//execute the time source
			async_time_source = time_source_create(time_source_game, 1, time_source_units_frames, _asyncParse, [], -1)
			time_source_start(async_time_source)
			
			return async_time_source
		}
		
		#region jsDoc
		/// @func    asyncPause()
		/// @desc    Pauses the asynchronous parsing process.
		/// @self    ParserBase
		/// @returns {undefined}
		#endregion
		static asyncPause = function() {
			if (async_time_source != undefined) {
				time_source_pause(async_time_source);
				async_active = false;
			}
		};
		
		#region jsDoc
		/// @func    asyncResume()
		/// @desc    Resumes the asynchronous parsing process.
		/// @self    ParserBase
		/// @returns {undefined}
		#endregion
		static asyncResume = function() {
			if (async_time_source != undefined) {
				time_source_start(async_time_source);
				async_active = true;
			}
		};
		
		#region jsDoc
		/// @func    asyncCancel()
		/// @desc    Cancels the asynchronous parsing process and destroys the active time source.
		/// @self    ParserBase
		/// @returns {undefined}
		#endregion
		static asyncCancel = function() {
			if (async_time_source != undefined) {
				time_source_destroy(async_time_source);
				async_time_source = undefined;
				async_active = false;
			}
		};
		
		#endregion
		
		#region Parsing Steps
		#region jsDoc
		/// @func    nextToken()
		/// @desc    Processes the next token using the added parser steps. If errors are to be caught, they will be handled via the error handler.
		/// @self    ParserBase
		/// @returns {void}
		#endregion
		static nextToken = function() {
			if (should_catch_errors) {
				try {
					var _token = __nextToken();
					parseNext(_token);
				} catch (e) {
					error_handler(e);
				}
			}
			else {
				var _token = __nextToken();
				parseNext(_token);
			}
		};
		
		#region jsDoc
		/// @func    addParserStep()
		/// @desc    Adds a parser step (function) to the list of steps to be executed during parsing.
		/// @self    ParserBase
		/// @param   {function} step : The parser function to be added to the list
		/// @returns {void}
		#endregion
		static addParserStep = function(step) {
			array_push(parserSteps, step);
		};
		
		#region jsDoc
		/// @func    parseNext()
		/// @desc    Runs each parser step function on the current token in sequence.
		/// @self    ParserBase
		/// @param   {any} currentToken : The token to be parsed by the registered parser steps
		/// @returns {any} : The potentially modified token after all steps
		#endregion
		static parseNext = function(_inputToken) {
			var _outputToken = _inputToken
			for (var i = 0; i < array_length(parserSteps); i++) {
				
				_outputToken = parserSteps[i](_inputToken);  // Pass the token through each parser step
				
				if (shouldBreakParserSteps(_inputToken, _outputToken)) {
					break;
				}
			}
			return _outputToken;
		};
		
		#region jsDoc
		/// @func    clearParserSteps()
		/// @desc    Clears all parser steps from the list. Useful for resetting or changing the parsing process.
		/// @self    ParserBase
		/// @returns {void}
		#endregion
		static clearParserSteps = function() {
			array_resize(parserSteps, 0);
		};
		
		#region jsDoc
		/// @func    shouldBreakParserSteps()
		/// @desc    Returns if the parser should stop iterating through the parser steps
		/// @self    ParserBase
		/// @param   {any} inputToken : The token to be parsed by the registered parser steps
		/// @param   {any} outputToken : The token produced after parsing steps
		/// @returns {bool}
		#endregion
		static shouldBreakParserSteps = function(_inputToken, _outputToken) {
			return __shouldBreakParserSteps(_inputToken, _outputToken);
		};
		
		#endregion
		
		#region Builders
		#region jsDoc
		/// @func    setErrorHandler()
		/// @desc    Sets a custom error handler function to handle errors during parsing.
		/// @self    ParserBase
		/// @param   {function} _handler : The custom error handler function
		/// @returns {undefined}
		#endregion
		static setErrorHandler = function(_handler) {
			error_handler = _handler;
		}
		
		#region jsDoc
		/// @func    setAsyncMaxTime()
		/// @desc    Sets the maximum time allowed for async parsing within one frame.
		/// @self    ParserBase
		/// @param   {number} _max_time : The maximum time (in ms) allowed for async parsing
		/// @returns {undefined}
		#endregion
		static setAsyncMaxTime = function(_max_time) {
			async_max_time = _max_time;
		};
		
		#region jsDoc
		/// @func    setCustomInitialize()
		/// @desc    Sets the custom initialize function to be used by the parser.
		/// @self    ParserBase
		/// @param   {function} _func : The custom initialization function
		/// @returns {undefined}
		#endregion
		static setCustomInitialize = function(_func) {
			__initialize = _func;
		}
		
		#region jsDoc
		/// @func    setCustomCleanup()
		/// @desc    Sets the custom cleanup function to be used by the parser.
		/// @self    ParserBase
		/// @param   {function} _func : The custom cleanup function
		/// @returns {undefined}
		#endregion
		static setCustomCleanup = function(_func) {
			__cleanup = _func;
		}
		
		#region jsDoc
		/// @func    setCustomFinalize()
		/// @desc    Sets the custom finalize function to be used by the parser.
		/// @self    ParserBase
		/// @param   {function} _func : The custom finalize function
		/// @returns {undefined}
		#endregion
		static setCustomFinalize = function(_func) {
			__finalize = _func;
		}
		
		#region jsDoc
		/// @func    setCustomIsFinished()
		/// @desc    Sets the custom isFinished function to check if parsing is completed.
		/// @self    ParserBase
		/// @param   {function} _func : The custom isFinished function
		/// @returns {undefined}
		#endregion
		static setCustomIsFinished = function(_func) {
			__isFinished = _func;
		}
		
		#region jsDoc
		/// @func    setCustomNextToken()
		/// @desc    Sets the custom nextToken function to process tokens in the stack.
		/// @self    ParserBase
		/// @param   {function} _func : The custom nextToken function
		/// @returns {undefined}
		#endregion
		static setCustomNextToken = function(_func) {
			__nextToken = _func;
		}
		
		#region jsDoc
		/// @func    setLogEnabled()
		/// @desc    Enables or disables logging for the parser.
		/// @self    ParserBase
		/// @param   {boolean} enabled : Whether logging should be enabled
		/// @returns {undefined}
		#endregion
		static setLogEnabled = function(enabled) {
		    logEnabled = enabled;
		};
		
		#region jsDoc
		/// @func    setErrorHandler()
		/// @desc    Sets whether errors should be caught during parsing and handled by the error handler.
		/// @self    ParserBase
		/// @param   {boolean} _enabled : Whether error catching should be enabled
		/// @returns {undefined}
		#endregion
		static setErrorHandler = function(_enabled) {
			should_catch_errors = _enabled;
		}
		
		#endregion
		
	}
#endregion



