// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-07.
function GmlConstructorTestSuite() : TestSuite() constructor {

	addFact("a constructor called through script_execute [GameMaker]", function() {
		assert_equals(case_run(case_constructors_ctor_script_execute), "string:undefined:1:", "GameMaker no longer gives the measured result");
	});
	addFact("a constructor called through script_execute [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function(_n) constructor { n = _n; };
var h = { tag: "h" };
var r = "none";
try {
	with (h) r = script_execute(C, 4);
}
catch (_e) {
	return "error:" + _e.message;
}
return typeof(r) + ":" + string(struct_exists(h, "n")) + ":" + (is_struct(r) ? string(r[$ "n"]) : "");'); }), "string:undefined:1:", "GMLC differs from GameMaker");
	});

	addFact("a constructor called through script_execute_ext [GameMaker]", function() {
		assert_equals(case_run(case_constructors_ctor_script_execute_ext), "string:undefined:1:", "GameMaker no longer gives the measured result");
	});
	addFact("a constructor called through script_execute_ext [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function(_n) constructor { n = _n; };
var h = { tag: "h" };
var r = "none";
try {
	with (h) r = script_execute_ext(C, [4]);
}
catch (_e) {
	return "error:" + _e.message;
}
return typeof(r) + ":" + string(struct_exists(h, "n")) + ":" + (is_struct(r) ? string(r[$ "n"]) : "");'); }), "string:undefined:1:", "GMLC differs from GameMaker");
	});

	addFact("a constructor called through method_call [GameMaker]", function() {
		assert_equals(case_run(case_constructors_ctor_method_call), "string:undefined:1:", "GameMaker no longer gives the measured result");
	});
	addFact("a constructor called through method_call [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function(_n) constructor { n = _n; };
var h = { tag: "h" };
var r = "none";
try {
	with (h) r = method_call(C, [4]);
}
catch (_e) {
	return "error:" + _e.message;
}
return typeof(r) + ":" + string(struct_exists(h, "n")) + ":" + (is_struct(r) ? string(r[$ "n"]) : "");'); }), "string:undefined:1:", "GMLC differs from GameMaker");
	});

	addFact("new on a constructor bound with method() [GameMaker]", function() {
		assert_equals(case_run(case_constructors_ctor_bound_new), "string:struct:4:0", "GameMaker no longer gives the measured result");
	});
	addFact("new on a constructor bound with method() [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function(_n) constructor { n = _n; };
var h = { tag: "h" };
var B = method(h, C);
var r = "none";
try {
	r = new B(4);
}
catch (_e) {
	return "error:" + _e.message;
}
return typeof(r) + ":" + string(r[$ "n"]) + ":" + string(struct_exists(h, "n"));'); }), "string:struct:4:0", "GMLC differs from GameMaker");
	});

	addFact("new on a function that is not a constructor [GameMaker]", function() {
		assert_equals(case_run(case_constructors_new_on_plain_function), "string:error:target function for 'new' must be a constructor", "GameMaker no longer gives the measured result");
	});
	addFact("new on a function that is not a constructor [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var F = function() { v = 5; return 7; };
var r = "none";
try {
	r = new F();
}
catch (_e) {
	return "error:" + _e.message;
}
return typeof(r) + ":" + string(r);'); }), "string:error:target function for 'new' must be a constructor", "GMLC differs from GameMaker");
	});

	addFact("self and other inside a static toString that string() calls [GameMaker]", function() {
		assert_equals(case_run(case_constructors_static_tostring_string), "string:self.n=4,other=struct n=4 tag=undefined", "GameMaker no longer gives the measured result");
	});
	addFact("self and other inside a static toString that string() calls [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function(_n) constructor {
	n = _n;
	static toString = function() {
		return "self.n=" + string(self[$ "n"]) + ",other=" + (is_struct(other) ? ("struct n=" + string(other[$ "n"]) + " tag=" + string(other[$ "tag"])) : typeof(other));
	};
};
var c = new C(4);
var h = { tag: "h", n: 9 };
var r = "";
with (h) r = string(c);
return r;'); }), "string:self.n=4,other=struct n=4 tag=undefined", "GMLC differs from GameMaker");
	});

	addFact("a static toString through a template string [GameMaker]", function() {
		assert_equals(case_run(case_constructors_static_tostring_template), "string:<C4>", "GameMaker no longer gives the measured result");
	});
	addFact("a static toString through a template string [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function(_n) constructor {
	n = _n;
	static toString = function() { return "C" + string(n); };
};
var c = new C(4);
return $"<{c}>";'); }), "string:<C4>", "GMLC differs from GameMaker");
	});

	addFact("a static toString of a struct inside an array given to string() [GameMaker]", function() {
		assert_equals(case_run(case_constructors_static_tostring_in_array), "string:[ C4,C5 ]", "GameMaker no longer gives the measured result");
	});
	addFact("a static toString of a struct inside an array given to string() [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function(_n) constructor {
	n = _n;
	static toString = function() { return "C" + string(n); };
};
return string([new C(4), new C(5)]);'); }), "string:[ C4,C5 ]", "GMLC differs from GameMaker");
	});

	addFact("method_get_self of a static method [GameMaker]", function() {
		assert_equals(case_run(case_constructors_static_tostring_method_get_self), "string:undefined:undefined", "GameMaker no longer gives the measured result");
	});
	addFact("method_get_self of a static method [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function(_n) constructor {
	n = _n;
	static toString = function() { return "C" + string(n); };
};
var c = new C(4);
return typeof(method_get_self(static_get(C).toString)) + ":" + typeof(method_get_self(c.toString));'); }), "string:undefined:undefined", "GMLC differs from GameMaker");
	});

	addFact("a static method passed to array_map [GameMaker]", function() {
		assert_equals(case_run(case_constructors_static_method_as_callback), "string:[ 101,102 ]", "GameMaker no longer gives the measured result");
	});
	addFact("a static method passed to array_map [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function(_n) constructor {
	n = _n;
	static add = function(_x) { return _x + n; };
};
var c = new C(4);
var h = { n: 100 };
var r = undefined;
with (h) r = array_map([1, 2], c.add);
return string(r);'); }), "string:[ 101,102 ]", "GMLC differs from GameMaker");
	});

	addFact("a toString set in the constructor body (not static) [GameMaker]", function() {
		assert_equals(case_run(case_constructors_instance_tostring_string), "string:C4", "GameMaker no longer gives the measured result");
	});
	addFact("a toString set in the constructor body (not static) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function(_n) constructor {
	n = _n;
	toString = function() { return "C" + string(n); };
};
return string(new C(4));'); }), "string:C4", "GMLC differs from GameMaker");
	});

	addFact("static_get of self after script_execute runs a constructor [GameMaker]", function() {
		assert_equals(case_run(case_constructors_ctor_statics_after_script_execute), "string:undefined:1:3:1", "GameMaker no longer gives the measured result");
	});
	addFact("static_get of self after script_execute runs a constructor [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var C = function() constructor { static k = 3; v = 1; };
var h = { tag: "h" };
var r = "none";
try {
	with (h) r = script_execute(C);
}
catch (_e) {
	return "error:" + _e.message;
}
var s = static_get(h);
return typeof(r) + ":" + string(h[$ "v"]) + ":" + string(h[$ "k"]) + ":" + string(is_struct(s) && struct_exists(s, "k"));'); }), "string:undefined:1:3:1", "GMLC differs from GameMaker");
	});
}

function case_constructors_ctor_script_execute() {
var C = function(_n) constructor { n = _n; };
var h = { tag: "h" };
var r = "none";
try {
	with (h) r = script_execute(C, 4);
}
catch (_e) {
	return "error:" + _e.message;
}
return typeof(r) + ":" + string(struct_exists(h, "n")) + ":" + (is_struct(r) ? string(r[$ "n"]) : "");
}

function case_constructors_ctor_script_execute_ext() {
var C = function(_n) constructor { n = _n; };
var h = { tag: "h" };
var r = "none";
try {
	with (h) r = script_execute_ext(C, [4]);
}
catch (_e) {
	return "error:" + _e.message;
}
return typeof(r) + ":" + string(struct_exists(h, "n")) + ":" + (is_struct(r) ? string(r[$ "n"]) : "");
}

function case_constructors_ctor_method_call() {
var C = function(_n) constructor { n = _n; };
var h = { tag: "h" };
var r = "none";
try {
	with (h) r = method_call(C, [4]);
}
catch (_e) {
	return "error:" + _e.message;
}
return typeof(r) + ":" + string(struct_exists(h, "n")) + ":" + (is_struct(r) ? string(r[$ "n"]) : "");
}

function case_constructors_ctor_bound_new() {
var C = function(_n) constructor { n = _n; };
var h = { tag: "h" };
var B = method(h, C);
var r = "none";
try {
	r = new B(4);
}
catch (_e) {
	return "error:" + _e.message;
}
return typeof(r) + ":" + string(r[$ "n"]) + ":" + string(struct_exists(h, "n"));
}

function case_constructors_new_on_plain_function() {
var F = function() { v = 5; return 7; };
var r = "none";
try {
	r = new F();
}
catch (_e) {
	return "error:" + _e.message;
}
return typeof(r) + ":" + string(r);
}

function case_constructors_static_tostring_string() {
var C = function(_n) constructor {
	n = _n;
	static toString = function() {
		return "self.n=" + string(self[$ "n"]) + ",other=" + (is_struct(other) ? ("struct n=" + string(other[$ "n"]) + " tag=" + string(other[$ "tag"])) : typeof(other));
	};
};
var c = new C(4);
var h = { tag: "h", n: 9 };
var r = "";
with (h) r = string(c);
return r;
}

function case_constructors_static_tostring_template() {
var C = function(_n) constructor {
	n = _n;
	static toString = function() { return "C" + string(n); };
};
var c = new C(4);
return $"<{c}>";
}

function case_constructors_static_tostring_in_array() {
var C = function(_n) constructor {
	n = _n;
	static toString = function() { return "C" + string(n); };
};
return string([new C(4), new C(5)]);
}

function case_constructors_static_tostring_method_get_self() {
var C = function(_n) constructor {
	n = _n;
	static toString = function() { return "C" + string(n); };
};
var c = new C(4);
return typeof(method_get_self(static_get(C).toString)) + ":" + typeof(method_get_self(c.toString));
}

function case_constructors_static_method_as_callback() {
var C = function(_n) constructor {
	n = _n;
	static add = function(_x) { return _x + n; };
};
var c = new C(4);
var h = { n: 100 };
var r = undefined;
with (h) r = array_map([1, 2], c.add);
return string(r);
}

function case_constructors_instance_tostring_string() {
var C = function(_n) constructor {
	n = _n;
	toString = function() { return "C" + string(n); };
};
return string(new C(4));
}

function case_constructors_ctor_statics_after_script_execute() {
var C = function() constructor { static k = 3; v = 1; };
var h = { tag: "h" };
var r = "none";
try {
	with (h) r = script_execute(C);
}
catch (_e) {
	return "error:" + _e.message;
}
var s = static_get(h);
return typeof(r) + ":" + string(h[$ "v"]) + ":" + string(h[$ "k"]) + ":" + string(is_struct(s) && struct_exists(s, "k"));
}
