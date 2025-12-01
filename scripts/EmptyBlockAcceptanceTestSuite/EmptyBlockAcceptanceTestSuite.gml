function EmptyBlockAcceptanceTestSuite() : TestSuite() constructor {

    addFact("Empty else block is allowed", function() {
        compile_and_execute(@'
        var condition = true;
        if (condition) {
            var result = 1;
        } else {}
        assert_equals(result, 1, "Empty else block should not error");
        ')
    });

    addFact("Empty if block is allowed", function() {
        compile_and_execute(@'
        var condition = false;
        if (condition) {}
        else {
            var result = 42;
        }
        assert_equals(result, 42, "Empty if block should not error");
        ')
    });

    addFact("Empty for loop body is allowed", function() {
        compile_and_execute(@'
        var result = 5;
        for (var i = 0; i < 3; i++) {}
        assert_equals(result, 5, "Empty for loop body should not error");
        ')
    });

    addFact("Empty while loop body is allowed", function() {
        compile_and_execute(@'
        var count = 0;
        while (count < 0) {}
        assert_equals(count, 0, "Empty while loop body should not error");
        ')
    });

    addFact("Empty repeat block is allowed", function() {
        compile_and_execute(@'
        var result = 10;
        repeat (3) {}
        assert_equals(result, 10, "Empty repeat block should not error");
        ')
    });

    addFact("Empty do-until block is allowed", function() {
        compile_and_execute(@'
        var value = 123;
        do {} until (true);
        assert_equals(value, 123, "Empty do-until block should not error");
        ')
    });

    addFact("Switch case with empty block is allowed", function() {
        compile_and_execute(@'
        var input = 2;
        var result = 0;
        switch (input) {
            case 1: result = 1; break;
            case 2: {} break;
            default: result = -1;
        }
        assert_equals(result, 0, "Empty case block should not error");
        ')
    });

    addFact("Empty with block is allowed", function() {
        compile_and_execute(@'
        var obj = { x: 1 };
        with (obj) {}
        assert_equals(obj.x, 1, "Empty with block should not error");
        ')
    });

    addFact("Nested empty blocks are allowed", function() {
        compile_and_execute(@'
        var result = 1;
        if (true) {
            if (false) {}
            else {}
        }
        assert_equals(result, 1, "Nested empty blocks should not error");
        ')
    });
}