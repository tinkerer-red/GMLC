#region jsDoc
/// @func    GMLC_BatchResult()
/// @desc    Result returned by compile_batch() and compile_project(). Holds per-entry compile
///          outcomes with helpers for querying success counts, rates, and failures.
/// @returns {Struct.GMLC_BatchResult}
#endregion
function GMLC_BatchResult() constructor {

	entries = [];

	#region jsDoc
	/// @func    add()
	/// @desc    Appends a compile result entry.
	/// @param   {String} name     : Identifier for this entry (filename, asset name, etc.)
	/// @param   {Bool}   success  : Whether compilation succeeded
	/// @param   {Any}    [error]  : Error struct if compilation failed
	/// @returns {Struct.GMLC_BatchResult} self
	#endregion
	static add = function(_name, _success, _error = undefined) {
		array_push(entries, {
			name    : _name,
			success : _success,
			error   : _error,
		});
		return self;
	}

	#region jsDoc
	/// @func    get_success_count()
	/// @returns {Real}
	#endregion
	static get_success_count = function() {
		var _count = 0;
		var _i = 0; repeat(array_length(entries)) {
			if (entries[_i].success) _count++;
		_i++;}
		return _count;
	}

	#region jsDoc
	/// @func    get_total_count()
	/// @returns {Real}
	#endregion
	static get_total_count = function() {
		return array_length(entries);
	}

	#region jsDoc
	/// @func    get_success_rate()
	/// @desc    Returns a value between 0 and 1.
	/// @returns {Real}
	#endregion
	static get_success_rate = function() {
		var _total = get_total_count();
		if (_total == 0) return 1;
		return get_success_count() / _total;
	}

	#region jsDoc
	/// @func    get_failures()
	/// @desc    Returns only the entries where success == false.
	/// @returns {Array<Struct>}
	#endregion
	static get_failures = function() {
		var _failures = [];
		var _i = 0; repeat(array_length(entries)) {
			if (!entries[_i].success) array_push(_failures, entries[_i]);
		_i++;}
		return _failures;
	}

}
