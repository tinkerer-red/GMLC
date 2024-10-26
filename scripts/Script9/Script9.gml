#region GC Timer Internals
	//Beta IDE v2023.600.0.368 Beta Runtime v2023.600.0.387
	// as of now, this number is 2 but might change in the future so best to calculate it on build, note this is not needed just increases accuracy
	
	//forget the initial count as it builds new internals on first call
	gc_get_stats().num_objects_in_generation[0]
	//find out the offset from simply running the function
	var __gc_start = gc_get_stats().num_objects_in_generation[0]
	global.__gc_log_offset = gc_get_stats().num_objects_in_generation[0]-__gc_start;
#endregion
#macro GC_START var __gc_start = gc_get_stats().num_objects_in_generation[0]
#macro GC_LOG show_debug_message("::GC_LOG:: Newly Created Garbage : "+string(gc_get_stats().num_objects_in_generation[0] -__gc_start - global.__gc_log_offset))
