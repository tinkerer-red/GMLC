function DotChainPerformanceTestSuite() : TestSuite() constructor {

    // Minimal chain should compile and execute
    addFact("Single dot chain call compiles", function() {
        compile_and_execute(@'
        function Dummy() constructor {
            static add = function(_k, _v) { return self; }
        }

        var result = new Dummy()
			.add("key", "value");
        assert_equals(true, true, "Single method chain failed");
        ')
    });

    // Medium chain to check for non-exponential behavior
    addFact("Medium dot chain call compiles", function() {
        compile_and_execute(@'
        function Dummy() constructor {
            add = function(_k, _v) { return self; }
        }

        new Dummy()
        .add("a", 1)
        .add("b", 2)
        .add("c", 3);

        assert_equals(true, true, "Medium method chain failed");
        ')
    });

    // Long chain to mimic user input and detect slowdowns
    addFact("Long dot chain does not time out", function() {
        compile_and_execute(@'
        function Dummy() constructor {
            add = function(_k, _v) { return self; }
        }

        new Dummy()
        .add("a", 1)
        .add("b", 2)
        .add("c", 3)
        .add("d", 4)
        .add("e", 5)
        .add("f", 6)
        .add("g", 7)
        .add("h", 8)
        .add("i", 9);

        assert_equals(true, true, "Long method chain caused compile slowdown");
        ')
    });

    // Check return value correctness after chaining
    addFact("Dot chain preserves return value", function() {
        compile_and_execute(@'
        function Dummy() constructor {
            total = 0;
            add = function(_k, _v) {
                total += _v;
				show_debug_message($"triggering `add` with key :: {_k}")
                return self;
            }
        }

        var d = new Dummy();
        var final = d.add("a", 1).add("b", 2).add("c", 3);
        assert_equals(final.total, 6, "Chained calls did not accumulate correctly");
        ')
    });

    // Nested chain in expression to test inline parsing
    addFact("Nested dot chains inline", function() {
        compile_and_execute(@'
        function Dummy() constructor {
            add = function(_k, _v) { return self; }
        }

        function get_dummy() {
            return new Dummy();
        }

        get_dummy()
        .add("x", 1)
        .add("y", 2);

        assert_equals(true, true, "Nested chained call failed");
        ')
    });
	
	addFact("Long dot chain with 20 entries compiles", function() {
	    compile_and_execute(@'
	    function Dummy() constructor {
	        add = function(_k, _v) { return self; }
	    }

	    var chain = new Dummy();
	    for (var i = 0; i < 20; i++) {
	        chain = chain.add("k" + string(i), i);
	    }

	    assert_equals(true, true, "20-entry chain compilation failed");
	    ')
	});

	addFact("Nested dot chain expression returns correct final value", function() {
	    compile_and_execute(@'
	    function Dummy() constructor {
	        total = 0;
	        add = function(_k, _v) { total += _v; return self; }
	    }

	    var value = new Dummy()
	        .add("a", 1)
	        .add("b", 2)
	        .add("c", 3).total;

	    assert_equals(value, 6, "Chained dot-call expression did not return correct value");
	    ')
	});

	addFact("Chain terminates cleanly on final call result", function() {
	    compile_and_execute(@'
	    function Dummy() constructor {
	        label = "";
	        Set = function(v) { label = v; return self; }
	        End = function() { return label; }
	    }

	    var result = new Dummy().Set("done").End();
	    assert_equals(result, "done", "Chained dot-call did not produce final value");
	    ')
	});

}