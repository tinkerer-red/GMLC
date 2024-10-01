function log(_str) {
	show_debug_message(_str);
}

#region jsDoc
/// @func    trace()
/// @desc    This function will create a custom debug message  that is shown in the compiler window at runtime.
///
///          .
///
///          output: `<file>/<function>:<line>: <string>`
/// @param   {string} str : The string you wish to log
/// @returns {undefined}
#endregion
#macro __show_debug_message show_debug_message
#macro trace __trace(_GMFILE_+"/"+_GMFUNCTION_+":"+string(_GMLINE_)+": ")
#macro do_trace __trace(_GMFILE_+"/"+_GMFUNCTION_+":"+string(_GMLINE_)+": ")
function __trace(_location) {
		static __struct = {};
		__struct.__location = _location;
		return method(__struct, function(_str)
    {
        show_debug_message(__location + ": " + string(_str));
    });
}