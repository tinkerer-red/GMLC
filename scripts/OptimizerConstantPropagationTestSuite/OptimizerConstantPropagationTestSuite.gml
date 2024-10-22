

function OptimizerConstantPropagationTestSuite() : TestSuite() constructor {

    // Test 1: Basic constant propagation
    addFact("Basic Constant Propagation", function() {
        var PI = 3.14;
        /// @NoOp
        var r = 2;
        var area = PI * r * r;
        
        assert_equals(area, 12.56, "The area should be calculated with the constant PI.");
    });
    
    // Test 2: Multiple occurrences of a constant
    addFact("Multiple Occurrences of Constant", function() {
        var GRAVITY = 9.8;
        /// @NoOp
        var time = 10;
        var fallTime = GRAVITY * time;
        var force = 5 * GRAVITY;

        assert_equals(fallTime, 98, "Fall time should be calculated with the constant GRAVITY.");
        assert_equals(force, 49, "Force should be calculated with the constant GRAVITY.");
    });

    // Test 3: Constant used in a loop
    addFact("Constant in Loop", function() {
        var MAX_ITERATIONS = 3;
        var sum = 0;
        for (var i = 0; i < MAX_ITERATIONS; i++) {
            sum += i;
        }

        assert_equals(sum, 3, "Sum should be the result of adding all loop iterations with a constant MAX_ITERATIONS.");
    });

    // Test 4: Propagation across multiple statements
    addFact("Constant Propagation Across Statements", function() {
        var THRESHOLD = 50;
        /// @NoOp
        var value = 60;
        var result;
        if (value > THRESHOLD) {
            result = THRESHOLD + 10;
        }

        assert_equals(result, 60, "Result should be calculated based on THRESHOLD constant.");
    });

    // Test 5: Constant with function calls
    addFact("Constant Propagation with Function Call", function() {
        var SPEED = 5;
        /// @NoOp
        var _direction = 90;
        var result = move_object(SPEED, _direction);

        assert_true(is_function_executed(result), "Constant SPEED should be propagated in the function call.");
    });

    // Test 6: No Optimization for dynamic values
    addFact("No Constant Propagation for Dynamic Values", function() {
        /// @NoOp
        var value = get_random_value();
        var result = value * 10;

        assert_true(is_dynamic(result), "Dynamic values should not be propagated.");
    });

    // Test 7: No Optimization for Shadowed Variables
    addFact("No Constant Propagation for Shadowed Variables", function() {
        var MAX_SPEED = 100;
        /// @NoOp
        var MAX_SPEED = 50;  // Shadowing the constant
        var currentSpeed = MAX_SPEED;

        assert_equals(currentSpeed, 50, "Shadowed local variable should prevent constant propagation.");
    });

    // Test 8: No Optimization for Function Parameters
    addFact("No Constant Propagation for Function Parameters", function() {
        var LIMIT = 10;
        function check_limit(LIMIT) {
            return LIMIT + 1;
        }
        
        /// @NoOp
        var result = check_limit(5);

        assert_equals(result, 6, "Function parameter should prevent constant propagation.");
    });

    // Test 9: No Optimization for Mutable Variables
    addFact("No Constant Propagation for Mutable Variables", function() {
        var INITIAL_HEALTH = 100;
        /// @NoOp
        var _health = INITIAL_HEALTH;
        _health -= 20;

        assert_equals(_health, 80, "Mutable variables should not be affected by constant propagation.");
    });

    // Test 10: @NoOp example for constant propagation on complex cases
    addFact("NoOp Test Case", function() {
        var PI = 3.14;
        /// @NoOp
        var r = 2;
        /// @NoOp
        var area = PI * r * r;  // This node should not be optimized

        assert_true(is_expression_executed(area), "The expression should still be executed even with @NoOp and not just folded.");
    });

    // Test 11: Function not optimized due to dynamic parameter
    addFact("No Constant Propagation for Dynamic Function Arguments", function() {
        var SPEED = 5;
        function dynamicMove(_speed, dir) {
            return _speed * dir;
        }
        
        /// @NoOp
        var _direction = 90;
        var result = dynamicMove(SPEED, _direction);

        assert_equals(result, 450, "Dynamic function arguments should prevent constant propagation.");
    });

    // Test 12: Constant Folding in Complex Expressions
    addFact("Constant Propagation with Folding", function() {
        var A = 5;
        var B = 3;
        var result = (A + B) * 2;

        assert_equals(result, 16, "Result should be calculated using constant propagation and folding.");
    });

}
