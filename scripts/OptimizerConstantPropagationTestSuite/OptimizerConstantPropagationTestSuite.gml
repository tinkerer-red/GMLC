

function OptimizerConstantPropagationTestSuite() : TestSuite() constructor {

    // Test 1: Basic constant propagation
    addFact("Variable Declaration Constant Propagation", function() {
        var PI = 3.14;
        /// @NoOp
        var r = 2;
        var area = PI * r * r;
        
        assert_equals(area, 12.56, "The area should be calculated with the constant PI.");
    });
    
	addFact("Assignmnet Constant Propagation", function() {
        var PI, r, area;
		PI = 3.14;
        /// @NoOp
        r = 2;
        area = PI * r * r;
        
        assert_equals(area, 12.56, "The area should be calculated with the constant PI.");
    });
    
	addFact("Variable Re-Declaration Constant Propagation", function() {
        var PI, r, area;
		var PI = 3.14;
        /// @NoOp
        var r = 2;
        var area = PI * r * r;
        
        assert_equals(area, 12.56, "The area should be calculated with the constant PI.");
    });
    
	#region Single Statements
	#region Do Until
	addFact("Do Until - Propagate all", function() {
	    var _x = 1;
		/// @NoOp
		var _i = 0;
		var _y;
		
		do {
			_y = _x * 2; // _x should propagate
		} until (_i++ >= 10);
		
		var _z = _x + 1; // _x should propagate
		
	    assert_equals(_y, 2, "Constant propagation failed");
	});
	addFact("Do Until - Propagate inside", function() {
	    var _x = 1;
		/// @NoOp
		var _i = 0;
		var _y;
		
		do {
			_y = _x * 2; // _x should propagate
		} until (_i++ >= 10);
		
		_x = irandom(1);
		var _z = _x + 1; // _x should not propagate
		
	    assert_equals(_y, 2, "Constant propagation failed");
	});
	addFact("Do Until - Propagate none", function() {
	    var _x = 1;
		/// @NoOp
		var _i = 0;
		var _y;
		
		do {
			_x = _i;
			_y = _x * 2; // _x should not propagate
		} until (_i++ >= 10);
		
		var _z = _x + 1; // _x should not propagate
		
	    assert_equals(_y, 20, "Constant propagation failed");
	});
	#endregion
    #region For
	addFact("For - Propagate all", function() {
        var _x = 1;
        var _y = 0;
        
		for (
			var _i = _x; // _x should propagate
			_i < _x+100; // _x should propagate
			_i += _x; // _x should propagate
		) {
		    _y += _x // _x should propagate
		}
		
		var _z = _x + 1; // _x should propagate
		
        assert_equals(_y, 100, "Constant propagation failed");
    });
    addFact("For - Propagate initializer", function() {
        var _x = 1;
        var _y = 0;
        
		for (
			var _i = _x; // _x should propagate
			_i < _x+100; // _x should not propagate
			_i += _x; // _x should not propagate
		) {
			_x += _i;
		    _y += _x; // _x should not propagate
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 376, "Constant propagation failed");
    });
    addFact("For - Propagate inside", function() {
        var _x = 1;
        var _y = 0;
        
		for (
			var _i = _x; // _x should propagate
			_i < _x+100; // _x should propagate
			_i += _x; // _x should propagate
		) {
		    _y += _x // _x should propagate
		}
		
		var _x = irandom(1)
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 100, "Constant propagation failed");
    });
    addFact("For - Propagate none", function() {
        var _x = 1;
        var _y = 0;
        
		/// @NoOp
		var _temp = 1;
		_x = _temp;
		
		for (
			var _i = _x; // _x should not propagate
			_i < _x+100; // _x should not propagate
			_i += _x; // _x should not propagate
		) {
		    _y += _x // _x should not propagate
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 100, "Constant propagation failed");
    });
    #endregion
	#region If
	addFact("If - Propagate all", function() {
        var _x = 1;
        var _y;
        /// @NoOp
        var _temp = 1;
        
		if (_x) { // _x should propagate
			_y = _x; // _x should propagate
		}
		else {
			_y = -_x; // _x should propagate
		}
		
		var _z = _x + 1; // _x should propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("If - Propagate inside 1", function() {
        var _x = 1;
        var _y;
        /// @NoOp
        var _temp = 1;
        
		if (_x) { // _x should propagate
			_y = _x; // _x should propagate
		}
		else {
			_y = -_x; // _x should propagate
		}
		
		_x = _temp
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("If - Propagate inside 2", function() {
        var _x = 1;
        var _y;
        /// @NoOp
        var _temp = 1;
        
		if (_x) { // _x should propagate
			_y = _x; // _x should propagate
			_x = _temp
		}
		else {
			_y = -_x; // _x should propagate
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("If - Propagate inside 3", function() {
        var _x = 1;
        var _y;
        /// @NoOp
        var _temp = 1;
        
		if (_x) { // _x should propagate
			_y = _x; // _x should propagate
		}
		else {
			_y = -_x; // _x should propagate
			_x = _temp
		}
		
		_x = _temp
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("If - Propagate inside 4", function() {
        var _x = 1;
        var _y;
        /// @NoOp
        var _temp = 1;
        
		if (_x) { // _x should propagate
			_x = _temp
			_y = _x; // _x should not propagate
		}
		else {
			_y = -_x; // _x should propagate
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("If - Propagate inside 5", function() {
        var _x = 1;
        var _y;
        /// @NoOp
        var _temp = 1;
        
		if (_x) { // _x should propagate
			_y = _x; // _x should propagate
		}
		else {
			_x = _temp
			_y = -_x; // _x should not propagate
		}
		
		_x = _temp
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("If - Propagate condition", function() {
        var _x = 1;
        var _y;
        /// @NoOp
        var _temp = 1;
        
		if (_x) { // _x should propagate
			_x = _temp
			_y = _x; // _x should not propagate
		}
		else {
			_x = _temp
			_y = -_x; // _x should not propagate
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("If - Propagate none", function() {
        var _x = 1;
        var _y;
        /// @NoOp
        var _temp = 1;
        _x = _temp;
		
		if (_x) { // _x should not propagate
			_y = _x; // _x should not propagate
		}
		else {
			_y = -_x; // _x should not propagate
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    #endregion
	#region Repeat
	addFact("Repeat - Propagate all", function() {
        var _x = 10;
        var _y = 0;
        /// @NoOp
        var _temp = 1;
        
		repeat(_x) { // _x should propagate
			_y += _x; // _x should propagate
		}
		
		var _z = _x + 1; // _x should propagate
		
        assert_equals(_y, 100, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
	addFact("Repeat - Propagate inside", function() {
        var _x = 10;
        var _y = 0;
        /// @NoOp
        var _temp = 1;
        
		repeat(_x) { // _x should propagate
			_y += _x; // _x should propagate
		}
		
		_x = _temp;
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 100, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
	addFact("Repeat - Propagate condition", function() {
        var _x = 10;
        var _y = 0;
        /// @NoOp
        var _temp = 1;
        
		repeat(_x) { // _x should propagate
			_x = _temp;
			_y += _x; // _x should not propagate
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 100, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
	addFact("Repeat - Propagate none", function() {
        var _x = 10;
        var _y = 0;
        /// @NoOp
        var _temp = 1;
        
		_x = _temp;
		
		repeat(_x) { // _x should not propagate
			_y += _x; // _x should not propagate
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 100, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
	#endregion
    #region Switch
	addFact("Switch - Propagate all", function() {
        var _x = 1;
        var _y = 0;
        /// @NoOp
        var _temp = 1;
        
		switch (_x) { // _x should propagate
		    case _x: // _x should propagate
		        _y = _x; // _x should propagate
		    break;
		    default:
		        _y = -_x; // _x should propagate
		    break;
		}
		
		var _z = _x + 1; // _x should propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("Switch - Propagate inside 1", function() {
        var _x = 1;
        var _y = 0;
        /// @NoOp
        var _temp = 1;
        
		switch (_x) { // _x should propagate
		    case _x: // _x should propagate
		        _y = _x; // _x should propagate
		    break;
		    default:
		        _y = -_x; // _x should propagate
		    break;
		}
		
		_x = _temp;
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("Switch - Propagate inside 2", function() {
        var _x = 1;
        var _y = 0;
        /// @NoOp
        var _temp = 1;
        
		switch (_x) { // _x should propagate
		    case _x: // _x should propagate
		        _y = _x; // _x should propagate
		    break;
		    default:
		        _y = -_x; // _x should propagate
				_x = _temp;
		    break;
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("Switch - Propagate inside 3", function() {
        var _x = 1;
        var _y = 0;
        /// @NoOp
        var _temp = 1;
        
		switch (_x) { // _x should propagate
		    case _x: // _x should propagate
		        _y = _x; // _x should propagate
				_x = _temp;
		    break;
		    default:
		        _y = -_x; // _x should not propagate
		    break;
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("Switch - Propagate inside 4", function() {
        var _x = 1;
        var _y = 0;
        /// @NoOp
        var _temp = 1;
        
		switch (_x) { // _x should propagate
		    case _x: // _x should propagate
		        _y = _x; // _x should propagate
		    break;
		    default:
				_x = _temp;
		        _y = -_x; // _x should not propagate
		    break;
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("Switch - Propagate case", function() {
        var _x = 1;
        var _y = 0;
        /// @NoOp
        var _temp = 1;
        
		switch (_x) { // _x should propagate
		    case _x: // _x should propagate
		        _x = _temp;
		        _y = _x; // _x should not propagate
		    break;
		    default:
				_y = -_x; // _x should not propagate
		    break;
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("Switch - Propagate condition", function() {
        var _x = 1;
        var _y = 0;
        /// @NoOp
        var _temp = 1;
        
		switch (_x) { // _x should propagate
		    case _temp:
		        _x = _temp;
		    break;
		    case _x: // _x should not propagate
		        _x = _temp;
		        _y = _x; // _x should not propagate
		    break;
		    default:
				_y = -_x; // _x should not propagate
		    break;
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    addFact("Switch - Propagate none", function() {
        var _x = 1;
        var _y = 0;
        /// @NoOp
        var _temp = 1;
        
		_x = _temp
		
		switch (_x) { // _x should not propagate
		    case _x: // _x should not propagate
				_y = _x; // _x should not propagate
		    break;
		    default:
		        _x = _temp
		        _y = -_x; // _x should not propagate
		    break;
		}
		
		var _z = _x + 1; // _x should not propagate
		
        assert_equals(_y, 1, "<ERROR MESSAGE HERE EXPLAINING WHY IT FAILED>");
    });
    #endregion
	
	#endregion
	
}



