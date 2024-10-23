

function OptimizerUnreachableCodeTestSuite() : TestSuite() constructor {

	// Test 1: Code after return statement should be removed
	addFact("Remove code after return", function() {
		compile_and_execute(@'
		var result = 0;

		if (true) {
			return 5;
			result = 10; // This should be unreachable and removed
		}
		
		assert_equals(result, 0, "Code after return should not be executed.");
		')
	});
	
	// Test 2: Code after break in loop should be removed
	addFact("Remove code after break in loop", function() {
		compile_and_execute(@'
		var sum = 0;
		
		for (var i = 0; i < 10; i++) {
			if (i == 5) {
				break;
				sum += i; // This should be unreachable and removed
			}
		}
		
		assert_equals(sum, 0, "Code after break in the loop should not be executed.");
		')
	});

	// Test 3: Code after exit statement should be removed
	addFact("Remove code after exit", function() {
		compile_and_execute(@'
		var value = 1;
		
		exit;
		value = 2;  // This should be unreachable and removed
		
		assert_equals(value, 1, "Code after exit should not be executed.");
		')
	});

	// Test 4: Nested block with return should remove unreachable code
	addFact("Remove unreachable code in nested block", function() {
		compile_and_execute(@'
		var num = 0;
		
		if (true) {
			if (true) {
				return;
				num += 10; // Unreachable code
			}
		}
		
		assert_equals(num, 0, "Nested block code after return should be removed.");
		')
	});

	// Test 5: Code after a return in a function call should be removed
	addFact("Remove unreachable code in function", function() {
		compile_and_execute(@'
		function earlyReturn() {
			return 1;
			var unused = 2; // This should be removed
		}

		var result = earlyReturn();
		assert_equals(result, 1, "The function should return immediately, ignoring unreachable code.");
		')
	});

	// Test 6: Unreachable code in conditional block
	addFact("Remove unreachable code in conditional block", function() {
		compile_and_execute(@'
		var value = 10;
		
		if (false) {
			value = 20; // This is unreachable
		}

		assert_equals(value, 10, "Code in the false branch should be unreachable.");
		')
	});

	// Test 7: Unreachable code after a while loop with a break
	addFact("Remove unreachable code after while loop", function() {
		compile_and_execute(@'
		var counter = 0;

		while (true) {
			counter++;
			break;
			counter++;  // This code should be unreachable and removed
		}

		assert_equals(counter, 1, "Code after break in while loop should not execute.");
		')
	});

	// Test 8: Code after exception handling should not be removed
	addFact("Exception handling shouldn't remove reachable code", function() {
		compile_and_execute(@'
		var reached = false;
		
		try {
			// Do something
		} catch (e) {
			reached = true;
		}

		assert_true(reached == false, "Code inside the try-catch block should not be removed.");
		')
	});

	// Test 9: Code after return inside try block should be removed
	addFact("Remove unreachable code after return in try block", function() {
		compile_and_execute(@'
		var _x = 10;

		try {
			return _x;
			_x = 20; // This should be unreachable and removed
		} catch (e) {
			_x = 30;
		}

		assert_equals(_x, 10, "Code after return in try block should be unreachable.");
		')
	});

	// Test 10: Unreachable code after continue in loop
	addFact("Remove unreachable code after continue", function() {
		compile_and_execute(@'
		var sum = 0;
		
		for (var i = 0; i < 5; i++) {
			if (i == 2) {
				continue;
				sum += i; // This should be unreachable and removed
			}
			sum += i;
		}

		assert_equals(sum, 10, "Code after continue should not be executed.");
		')
	});

	// Test 11: Code after return in switch case should be removed
	addFact("Remove unreachable code in switch case", function() {
		compile_and_execute(@'
		var result = 0;
		
		switch (1) {
			case 1:
				return;
				result = 10;  // This should be unreachable and removed
		}

		assert_equals(result, 0, "Code after return in switch case should not be executed.");
		')
	});

	// Test 12: Code after a break in switch case should be removed
	addFact("Remove unreachable code after break in switch case", function() {
		compile_and_execute(@'
		var result = 0;
		
		switch (1) {
			case 1:
				result = 5;
				break;
				result = 10;  // This should be unreachable and removed
		}

		assert_equals(result, 5, "Code after break in switch case should not be executed.");
		')
	});

	// Test 13: Code after a break in a nested loop should be removed
	addFact("Remove unreachable code after break in nested loop", function() {
		compile_and_execute(@'
		var count = 0;
		
		for (var i = 0; i < 3; i++) {
			for (var j = 0; j < 3; j++) {
				if (j == 1) {
					break;
					count += 1;  // This should be unreachable and removed
				}
			}
		}

		assert_equals(count, 0, "Code after break in nested loop should not be executed.");
		')
	});
	
	// Test 14: Code after return in do-while loop should be removed
	addFact("Remove unreachable code in do-while loop", function() {
		compile_and_execute(@'
		var i = 0;
		
		do {
			return;
			i++;  // This should be unreachable and removed
		} until (i < 5);

		assert_equals(i, 0, "Code after return in do-while loop should not be executed.");
		')
	});
}
