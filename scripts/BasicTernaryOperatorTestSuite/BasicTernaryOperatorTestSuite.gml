function BasicTernaryOperatorTestSuite() : TestSuite() constructor {

    // Simple ternary truthy
    addFact("Ternary true branch", function() {
        //compile_and_execute(@'
            var result = (true) ? "yes" : "no";
            assert_equals(result, "yes", "Ternary operator true branch failed.");
        //')
    });

    // Simple ternary falsy
    addFact("Ternary false branch", function() {
        //compile_and_execute(@'
            var result = (false) ? "yes" : "no";
            assert_equals(result, "no", "Ternary operator false branch failed.");
        //')
    });

    // Ternary with variable condition
    addFact("Ternary with dynamic variable", function() {
        //compile_and_execute(@'
            var flag = true;
            var result = (flag) ? 1 : 2;
            assert_equals(result, 1, "Ternary with dynamic true failed.");

            flag = false;
            result = (flag) ? 1 : 2;
            assert_equals(result, 2, "Ternary with dynamic false failed.");
        //')
    });

    // Ternary inside expression
    addFact("Ternary inside arithmetic expression", function() {
        //compile_and_execute(@'
            var _x = 3;
            var result = 10 + ((_x > 5) ? 100 : 5);
            assert_equals(result, 15, "Ternary with false condition in expression failed.");

            result = 10 + ((_x < 5) ? 2 : 50);
            assert_equals(result, 12, "Ternary with true condition in expression failed.");
        //')
    });

    // Nested ternary operator
    addFact("Nested ternary operator", function() {
        //compile_and_execute(@'
            var _x = 1;
            var result = (_x == 0) ? "zero" : ((_x == 1) ? "one" : "other");
            assert_equals(result, "one", "Nested ternary with middle match failed.");

            _x = 0;
            result = (_x == 0) ? "zero" : ((_x == 1) ? "one" : "other");
            assert_equals(result, "zero", "Nested ternary with first match failed.");

            _x = 10;
            result = (_x == 0) ? "zero" : ((_x == 1) ? "one" : "other");
            assert_equals(result, "other", "Nested ternary with fallback failed.");
        //')
    });

    // Ternary assigning to struct field
    addFact("Ternary assigning to struct field", function() {
        //compile_and_execute(@'
            var obj = { value: 0 };
            var condition = true;
            obj.value = condition ? 42 : -1;
            assert_equals(obj.value, 42, "Ternary assignment to struct (true) failed.");

            condition = false;
            obj.value = condition ? 42 : -1;
            assert_equals(obj.value, -1, "Ternary assignment to struct (false) failed.");
        //')
    });

    // Ternary result used in function argument
    addFact("Ternary as function argument", function() {
        //compile_and_execute(@'
            function label(value) {
                return "value is " + string(value);
            }

            var result = label(true ? 100 : 200);
            assert_equals(result, "value is 100", "Ternary in function argument (true) failed.");

            result = label(false ? 100 : 200);
            assert_equals(result, "value is 200", "Ternary in function argument (false) failed.");
        //')
    });

    // Ternary with logical short-circuit values
    addFact("Ternary with boolean logic", function() {
        //compile_and_execute(@'
            var a = true;
            var b = false;
            var result = (a && b) ? "yes" : "no";
            assert_equals(result, "no", "Ternary with logical AND failed.");

            result = (a || b) ? "yes" : "no";
            assert_equals(result, "yes", "Ternary with logical OR failed.");
        //')
    });

}