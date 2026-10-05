// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-04.
function GmlMethodBindingTestSuite() : TestSuite() constructor {

	addFact("function literal in a struct literal updates the struct (v += n) [GameMaker]", function() {
		assert_equals(case_run(case_method_binding_literal_method_compound), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("function literal in a struct literal updates the struct (v += n) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var o = { v: 0, inc: function(n) { v += n; } };
o.inc(5);
return o.v;'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("function literal in a struct literal reads the struct [GameMaker]", function() {
		assert_equals(case_run(case_method_binding_literal_method_read), "number:7", "GameMaker no longer gives the measured result");
	});
	addFact("function literal in a struct literal reads the struct [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var o = { v: 7, get: function() { return v; } };
return o.get();'); }), "number:7", "GMLC differs from GameMaker");
	});

	addFact("function literal in a struct literal updates self.v [GameMaker]", function() {
		assert_equals(case_run(case_method_binding_literal_method_self_dot), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("function literal in a struct literal updates self.v [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var o = { v: 1, inc: function(n) { self.v += n; } };
o.inc(4);
return o.v;'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("function literal taken out of its struct still runs on the struct [GameMaker]", function() {
		assert_equals(case_run(case_method_binding_literal_method_extracted), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("function literal taken out of its struct still runs on the struct [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var o = { v: 0, inc: function(n) { v += n; } };
var f = o.inc;
f(5);
return o.v;'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("self inside a function literal of a struct literal is that struct [GameMaker]", function() {
		assert_equals(case_run(case_method_binding_literal_method_self_is_struct), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("self inside a function literal of a struct literal is that struct [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var o = { me: function() { return self; } };
return o.me() == o;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("method_get_self of a function literal in a struct literal [GameMaker]", function() {
		assert_equals(case_run(case_method_binding_literal_method_get_self), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("method_get_self of a function literal in a struct literal [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var o = { g: function() { return 1; } };
return method_get_self(o.g) == o;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("function literal in a nested struct literal binds to the inner struct [GameMaker]", function() {
		assert_equals(case_run(case_method_binding_literal_method_nested), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("function literal in a nested struct literal binds to the inner struct [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var o = { v: 1, inner: { v: 3, get: function() { return v; } } };
return o.inner.get();'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("function literal under a string key [GameMaker]", function() {
		assert_equals(case_run(case_method_binding_literal_method_string_key), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("function literal under a string key [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var o = { "v": 2, "get": function() { return v; } };
return o.get();'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("two function literals in one struct literal [GameMaker]", function() {
		assert_equals(case_run(case_method_binding_literal_method_two), "number:12", "GameMaker no longer gives the measured result");
	});
	addFact("two function literals in one struct literal [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var o = { a: 1, b: 2, fa: function() { return a; }, fb: function() { return b; } };
return o.fa() * 10 + o.fb();'); }), "number:12", "GMLC differs from GameMaker");
	});

	addFact("a function stored in a variable first keeps its own binding [GameMaker]", function() {
		assert_equals(case_run(case_method_binding_variable_method_not_rebound), "bool:0", "GameMaker no longer gives the measured result");
	});
	addFact("a function stored in a variable first keeps its own binding [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var f = function() { return 1; };
var o = { g: f };
return method_get_self(o.g) == o;'); }), "bool:0", "GMLC differs from GameMaker");
	});
}

function case_method_binding_literal_method_compound() {
var o = { v: 0, inc: function(n) { v += n; } };
o.inc(5);
return o.v;
}

function case_method_binding_literal_method_read() {
var o = { v: 7, get: function() { return v; } };
return o.get();
}

function case_method_binding_literal_method_self_dot() {
var o = { v: 1, inc: function(n) { self.v += n; } };
o.inc(4);
return o.v;
}

function case_method_binding_literal_method_extracted() {
var o = { v: 0, inc: function(n) { v += n; } };
var f = o.inc;
f(5);
return o.v;
}

function case_method_binding_literal_method_self_is_struct() {
var o = { me: function() { return self; } };
return o.me() == o;
}

function case_method_binding_literal_method_get_self() {
var o = { g: function() { return 1; } };
return method_get_self(o.g) == o;
}

function case_method_binding_literal_method_nested() {
var o = { v: 1, inner: { v: 3, get: function() { return v; } } };
return o.inner.get();
}

function case_method_binding_literal_method_string_key() {
var o = { "v": 2, "get": function() { return v; } };
return o.get();
}

function case_method_binding_literal_method_two() {
var o = { a: 1, b: 2, fa: function() { return a; }, fb: function() { return b; } };
return o.fa() * 10 + o.fb();
}

function case_method_binding_variable_method_not_rebound() {
var f = function() { return 1; };
var o = { g: f };
return method_get_self(o.g) == o;
}
