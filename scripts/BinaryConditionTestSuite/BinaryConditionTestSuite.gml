function BinaryConditionTestSuite() : TestSuite() constructor {
    
    addFact("Modulo in conditional binary expression", function() {
        compile_and_execute(@'
        var tick_count = 10;
        var r = 5;
        var result = 0;
        if (tick_count % r = 0) {
            result = 1;
        }
        assert_equals(result, 1, "Modulo binary expression in if condition failed");
        //')
    });

    addFact("Binary comparison in condition works with addition", function() {
        compile_and_execute(@'
        var xx = 2;
        var yy = 3;
        var result = 0;
        if (xx + yy = 5) {
            result = 1;
        }
        assert_equals(result, 1, "Addition binary expression in if condition failed");
        //')
    });

    addFact("Binary comparison in condition works with multiplication", function() {
        compile_and_execute(@'
        var a = 4;
        var b = 2;
        var result = 0;
        if (a * b = 8) {
            result = 1;
        }
        assert_equals(result, 1, "Multiplication binary expression in if condition failed");
        //')
    });

    addFact("Logical binary condition works with &&", function() {
        compile_and_execute(@'
        var xx = true;
        var yy = true;
        var result = 0;
        if (xx && yy) {
            result = 1;
        }
        assert_equals(result, 1, "Logical AND condition failed");
        //')
    });

    addFact("Nested binary expressions in condition", function() {
        compile_and_execute(@'
        var xx = 5;
        var yy = 2;
        var z = 1;
        var result = 0;
        if ((xx % yy) + z = 2) {
            result = 1;
        }
        assert_equals(result, 1, "Nested binary expression in condition failed");
        //')
    });
} 
