// Generated from measured GameMaker behaviour; do not edit by hand.
// Expected values are what GameMaker 2024.14.4.268 (VM) did on 2026-10-06.
function GmlExtensionLoweringTestSuite() : TestSuite() constructor {

	addFact("struct_exists on undefined [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_exists_undefined), "error", "GameMaker no longer gives the measured result");
	});
	addFact("struct_exists on undefined [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return struct_exists(undefined, "b");'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("struct_exists on a number [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_exists_number), "bool:0", "GameMaker no longer gives the measured result");
	});
	addFact("struct_exists on a number [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return struct_exists(5, "b");'); }), "bool:0", "GMLC differs from GameMaker");
	});

	addFact("struct_exists on an array [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_exists_array), "error", "GameMaker no longer gives the measured result");
	});
	addFact("struct_exists on an array [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return struct_exists([1, 2], "b");'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("struct_exists on a string [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_exists_string), "error", "GameMaker no longer gives the measured result");
	});
	addFact("struct_exists on a string [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return struct_exists("text", "b");'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("struct_exists on a member set to undefined [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_exists_member_undefined), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("struct_exists on a member set to undefined [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = { b: undefined };
return struct_exists(a, "b");'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("the nested struct_exists chain reaches a value [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_nullish_chain_shape_hit), "number:7", "GameMaker no longer gives the measured result");
	});
	addFact("the nested struct_exists chain reaches a value [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = { b: { c: 7 } };
return struct_exists(a, "b") ? (struct_exists(a.b, "c") ? a.b.c : undefined) : undefined;'); }), "number:7", "GMLC differs from GameMaker");
	});

	addFact("the nested struct_exists chain with a missing middle key [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_nullish_chain_shape_missing_middle), "string:undefined", "GameMaker no longer gives the measured result");
	});
	addFact("the nested struct_exists chain with a missing middle key [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = { x: 1 };
var v = struct_exists(a, "b") ? (struct_exists(a.b, "c") ? a.b.c : undefined) : undefined;
return typeof(v);'); }), "string:undefined", "GMLC differs from GameMaker");
	});

	addFact("the nested struct_exists chain through a number [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_nullish_chain_shape_number_middle), "string:undefined", "GameMaker no longer gives the measured result");
	});
	addFact("the nested struct_exists chain through a number [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = { b: 4 };
var v = struct_exists(a, "b") ? (struct_exists(a.b, "c") ? a.b.c : undefined) : undefined;
return typeof(v);'); }), "string:undefined", "GMLC differs from GameMaker");
	});

	addFact("the nested struct_exists chain on an undefined base [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_nullish_chain_shape_undefined_base), "error", "GameMaker no longer gives the measured result");
	});
	addFact("the nested struct_exists chain on an undefined base [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = undefined;
var v = struct_exists(a, "b") ? a.b : undefined;
return typeof(v);'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("a method bound to a struct of copied locals reads them [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_closure_shape_copy), "number:6", "GameMaker no longer gives the measured result");
	});
	addFact("a method bound to a struct of copied locals reads them [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var n = 3;
var f = method({ n: n }, function() { return n * 2; });
n = 10;
return f();'); }), "number:6", "GMLC differs from GameMaker");
	});

	addFact("a method bound to a struct of locals reaches the creator through a kept self [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_closure_shape_self_kept), "error", "GameMaker no longer gives the measured result");
	});
	addFact("a method bound to a struct of locals reaches the creator through a kept self [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { hp: 5 };
with (s) {
	var k = 2;
	var f = method({ k: k, __gmlc_self: self }, function() { return __gmlc_self.hp + k; });
	return f();
}'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("a struct box shares a variable between a block and its methods [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_let_shape_box_shared), "number:2", "GameMaker no longer gives the measured result");
	});
	addFact("a struct box shares a variable between a block and its methods [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var __let0 = { count: 0 };
var inc = method({ __let0: __let0 }, function() { __let0.count += 1; });
inc();
inc();
return __let0.count;'); }), "number:2", "GMLC differs from GameMaker");
	});

	addFact("a box made in a loop body gives each iteration its own variable [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_let_shape_box_per_iteration), "string:012", "GameMaker no longer gives the measured result");
	});
	addFact("a box made in a loop body gives each iteration its own variable [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var fs = [];
for (var i = 0; i < 3; i++) {
	var __let0 = { v: i };
	array_push(fs, method({ __let0: __let0 }, function() { return __let0.v; }));
}
return string(fs[0]()) + string(fs[1]()) + string(fs[2]());'); }), "string:012", "GMLC differs from GameMaker");
	});

	addFact("an is_struct guarded struct accessor hop [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_nullish_hop_is_struct_index), "string:undefined", "GameMaker no longer gives the measured result");
	});
	addFact("an is_struct guarded struct accessor hop [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = { b: undefined };
var v = is_struct(a) ? (is_struct(a[$ "b"]) ? a[$ "b"][$ "c"] : undefined) : undefined;
return typeof(v);'); }), "string:undefined", "GMLC differs from GameMaker");
	});

	addFact("an is_struct guarded chain reaches a value [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_nullish_hop_is_struct_hit), "number:7", "GameMaker no longer gives the measured result");
	});
	addFact("an is_struct guarded chain reaches a value [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = { b: { c: 7 } };
return is_struct(a) ? (is_struct(a[$ "b"]) ? a[$ "b"][$ "c"] : undefined) : undefined;'); }), "number:7", "GMLC differs from GameMaker");
	});

	addFact("a method bound to a struct reaches the creator's instance variable through a kept self [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_closure_self_plain), "error", "GameMaker no longer gives the measured result");
	});
	addFact("a method bound to a struct reaches the creator's instance variable through a kept self [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'hp_probe = 5;
var k = 2;
var f = method({ k: k, __gmlc_self: self }, function() { return __gmlc_self.hp_probe + k; });
return f();'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("a method bound to a struct reaches a struct creator through a kept self [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_closure_self_struct), "number:7", "GameMaker no longer gives the measured result");
	});
	addFact("a method bound to a struct reaches a struct creator through a kept self [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { hp: 5 };
var f = method({ k: 2, __gmlc_self: s }, function() { return __gmlc_self.hp + k; });
return f();'); }), "number:7", "GMLC differs from GameMaker");
	});

	addFact("a kept self made inside with on a struct [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_closure_self_with_no_return), "error", "GameMaker no longer gives the measured result");
	});
	addFact("a kept self made inside with on a struct [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { hp: 5 };
var r = 0;
with (s) {
	var f = method({ k: 2, __gmlc_self: self }, function() { return __gmlc_self.hp + k; });
	r = f();
}
return r;'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("self inside a struct literal is the new struct [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_literal_self), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("self inside a struct literal is the new struct [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { me: self };
return s.me == s;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("a closure restores its creator's self with with, and its copied locals [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_closure_with_restore_self), "number:7", "GameMaker no longer gives the measured result");
	});
	addFact("a closure restores its creator's self with with, and its copied locals [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'hp_probe = 5;
var k = 2;
var _self = self;
var _other = other;
var f = method({ __closure__self: _self, __closure__other: _other, __closure__k: k }, function() {
	var k = __closure__k;
	var _s = __closure__self;
	with (__closure__other) {
		with (_s) {
			return hp_probe + k;
		}
	}
});
return f();'); }), "number:7", "GMLC differs from GameMaker");
	});

	addFact("a closure restores its creator's other with with [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_closure_with_restore_other), "string:inner/outer", "GameMaker no longer gives the measured result");
	});
	addFact("a closure restores its creator's other with with [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var outer = { name: "outer" };
var inner = { name: "inner" };
var f = undefined;
with (outer) {
	with (inner) {
		var _self = self;
		var _other = other;
		f = method({ __closure__self: _self, __closure__other: _other }, function() {
			var _s = __closure__self;
			with (__closure__other) {
				with (_s) {
					return self.name + "/" + other.name;
				}
			}
		});
	}
}
return f();'); }), "string:inner/outer", "GMLC differs from GameMaker");
	});

	addFact("a closure writes its creator's instance variable after with restores self [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_closure_with_restore_write), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("a closure writes its creator's instance variable after with restores self [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { hp: 5 };
var f = undefined;
with (s) {
	var _self = self;
	var _other = other;
	f = method({ __closure__self: _self, __closure__other: _other }, function() {
		var _s = __closure__self;
		with (__closure__other) {
			with (_s) {
				hp -= 2;
			}
		}
	});
}
f();
return s.hp;'); }), "number:3", "GMLC differs from GameMaker");
	});

	addFact("a closure's arguments are still read inside the with blocks [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_closure_with_restore_args), "number:36", "GameMaker no longer gives the measured result");
	});
	addFact("a closure's arguments are still read inside the with blocks [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var _self = self;
var _other = other;
var f = method({ __closure__self: _self, __closure__other: _other }, function(a, b) {
	var _s = __closure__self;
	with (__closure__other) {
		with (_s) {
			return a * 10 + b + argument_count;
		}
	}
});
return f(3, 4);'); }), "number:36", "GMLC differs from GameMaker");
	});

	addFact("a let box shared with a closure that restores self [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_let_box_with_restore), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("a let box shared with a closure that restores self [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var _self = self;
var _other = other;
var __let0 = { hp: 10 };
var hit = method({ __closure__self: _self, __closure__other: _other, __let0: __let0 }, function(d) {
	var __let0 = self.__let0;
	var _s = __closure__self;
	with (__closure__other) {
		with (_s) {
			__let0.hp -= d;
		}
	}
});
hit(3);
hit(2);
return __let0.hp;'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("static_get(global) is a struct whose only key is toString [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_static_get_global_keys), "string:struct:[ \"toString\" ]", "GameMaker no longer gives the measured result");
	});
	addFact("static_get(global) is a struct whose only key is toString [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = static_get(global);
return typeof(s) + ":" + string(struct_get_names(s));'); }), "string:struct:[ \"toString\" ]", "GMLC differs from GameMaker");
	});

	addFact("static_get(global) gives the same struct each time [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_static_get_global_same), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("static_get(global) gives the same struct each time [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return static_get(global) == static_get(global);'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("a global variable is not a key of static_get(global) [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_static_get_global_not_globals), "string:undefined", "GameMaker no longer gives the measured result");
	});
	addFact("a global variable is not a key of static_get(global) [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'global.ext_lowering_probe = 5;
return typeof(struct_get(static_get(global), "ext_lowering_probe"));'); }), "string:undefined", "GMLC differs from GameMaker");
	});

	addFact("struct_get on undefined [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_get_undefined), "error", "GameMaker no longer gives the measured result");
	});
	addFact("struct_get on undefined [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return struct_get(undefined, "b");'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("struct_get on a number [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_get_number), "string:undefined", "GameMaker no longer gives the measured result");
	});
	addFact("struct_get on a number [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return typeof(struct_get(4, "b"));'); }), "string:undefined", "GMLC differs from GameMaker");
	});

	addFact("struct_get on a bool [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_get_bool), "string:undefined", "GameMaker no longer gives the measured result");
	});
	addFact("struct_get on a bool [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return typeof(struct_get(true, "b"));'); }), "string:undefined", "GMLC differs from GameMaker");
	});

	addFact("struct_get on a string [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_get_string), "error", "GameMaker no longer gives the measured result");
	});
	addFact("struct_get on a string [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return struct_get("text", "b");'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("struct_get on an array [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_get_array), "error", "GameMaker no longer gives the measured result");
	});
	addFact("struct_get on an array [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'return struct_get([1, 2], "b");'); }), "error", "GMLC differs from GameMaker");
	});

	// a struct accessor after a parenthesised expression: GameMaker 2024.14.4.268 refuses to compile this (measured 2026-10-06):
	//   unexpected symbol "[$" in expression
	// The GameMaker fact stays commented out so this case is not written again; GMLC may accept it.
	// addFact("a struct accessor after a parenthesised expression [GameMaker]", function() {
	//   var a = { b: 1 };
	//   return (a)[$ "b"];
	// });

	addFact("the sentinel chain reaches a value [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_sentinel_chain_hit), "number:7", "GameMaker no longer gives the measured result");
	});
	addFact("the sentinel chain reaches a value [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = { b: { c: { d: 7 } } };
return is_undefined(a) ? undefined : struct_get(struct_get(struct_get(a, "b") ?? static_get(global), "c") ?? static_get(global), "d");'); }), "number:7", "GMLC differs from GameMaker");
	});

	addFact("the sentinel chain with a missing middle key [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_sentinel_chain_missing_middle), "string:undefined", "GameMaker no longer gives the measured result");
	});
	addFact("the sentinel chain with a missing middle key [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = { b: { x: 1 } };
var v = is_undefined(a) ? undefined : struct_get(struct_get(struct_get(a, "b") ?? static_get(global), "c") ?? static_get(global), "d");
return typeof(v);'); }), "string:undefined", "GMLC differs from GameMaker");
	});

	addFact("the sentinel chain with a number in the middle [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_sentinel_chain_number_middle), "string:undefined", "GameMaker no longer gives the measured result");
	});
	addFact("the sentinel chain with a number in the middle [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = { b: 4 };
var v = is_undefined(a) ? undefined : struct_get(struct_get(a, "b") ?? static_get(global), "c");
return typeof(v);'); }), "string:undefined", "GMLC differs from GameMaker");
	});

	addFact("the sentinel chain with an undefined base [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_sentinel_chain_undefined_base), "string:undefined", "GameMaker no longer gives the measured result");
	});
	addFact("the sentinel chain with an undefined base [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = undefined;
var v = is_undefined(a) ? undefined : struct_get(struct_get(a, "b") ?? static_get(global), "c");
return typeof(v);'); }), "string:undefined", "GMLC differs from GameMaker");
	});

	addFact("the sentinel chain reads toString from the empty struct after a break [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_sentinel_chain_tostring_after_break), "string:method", "GameMaker no longer gives the measured result");
	});
	addFact("the sentinel chain reads toString from the empty struct after a break [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = {};
var v = struct_get(struct_get(a, "b") ?? static_get(global), "toString");
return typeof(v);'); }), "string:method", "GMLC differs from GameMaker");
	});

	addFact("the sentinel chain with a string base throws [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_sentinel_chain_string_base), "error", "GameMaker no longer gives the measured result");
	});
	addFact("the sentinel chain with a string base throws [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var a = "text";
return is_undefined(a) ? undefined : struct_get(a, "b");'); }), "error", "GMLC differs from GameMaker");
	});

	addFact("self.name inside a struct literal reads the creator [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_literal_self_dot), "number:5", "GameMaker no longer gives the measured result");
	});
	addFact("self.name inside a struct literal reads the creator [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'hp_probe = 5;
var s = { a: self.hp_probe };
return s.a;'); }), "number:5", "GMLC differs from GameMaker");
	});

	addFact("a parenthesised self entry is the new struct [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_literal_self_parenthesised), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("a parenthesised self entry is the new struct [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { me: (self) };
return s.me == s;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("self inside an array in a struct literal is the creator [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_literal_self_in_array), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("self inside an array in a struct literal is the creator [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var c = self;
var s = { me: [self] };
return s.me[0] == c;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("self as a call argument in a struct literal is the creator [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_literal_self_call_argument), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("self as a call argument in a struct literal is the creator [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var c = self;
var f = function(v) { return v; };
var s = { me: f(self) };
return s.me == c;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("self in a ternary in a struct literal is the creator [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_literal_self_ternary), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("self in a ternary in a struct literal is the creator [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var c = self;
var s = { me: true ? self : undefined };
return s.me == c;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("a self entry of a nested struct literal is the inner struct [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_literal_self_nested), "bool:1", "GameMaker no longer gives the measured result");
	});
	addFact("a self entry of a nested struct literal is the inner struct [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { inner: { me: self } };
return s.inner.me == s.inner;'); }), "bool:1", "GMLC differs from GameMaker");
	});

	addFact("a self entry reads the struct's own keys [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_literal_self_with_key), "number:4", "GameMaker no longer gives the measured result");
	});
	addFact("a self entry reads the struct's own keys [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { me: self, x1: 4 };
return s.me.x1;'); }), "number:4", "GMLC differs from GameMaker");
	});

	addFact("a later value of the key replaces a self entry [GameMaker]", function() {
		assert_equals(case_run(case_extension_lowering_struct_literal_self_repeated_key), "number:3", "GameMaker no longer gives the measured result");
	});
	addFact("a later value of the key replaces a self entry [GMLC]", function() {
		assert_equals(case_run(function() { return compile_and_execute(@'var s = { me: self, me: 3 };
return s.me;'); }), "number:3", "GMLC differs from GameMaker");
	});
}

function case_extension_lowering_struct_exists_undefined() {
return struct_exists(undefined, "b");
}

function case_extension_lowering_struct_exists_number() {
return struct_exists(5, "b");
}

function case_extension_lowering_struct_exists_array() {
return struct_exists([1, 2], "b");
}

function case_extension_lowering_struct_exists_string() {
return struct_exists("text", "b");
}

function case_extension_lowering_struct_exists_member_undefined() {
var a = { b: undefined };
return struct_exists(a, "b");
}

function case_extension_lowering_nullish_chain_shape_hit() {
var a = { b: { c: 7 } };
return struct_exists(a, "b") ? (struct_exists(a.b, "c") ? a.b.c : undefined) : undefined;
}

function case_extension_lowering_nullish_chain_shape_missing_middle() {
var a = { x: 1 };
var v = struct_exists(a, "b") ? (struct_exists(a.b, "c") ? a.b.c : undefined) : undefined;
return typeof(v);
}

function case_extension_lowering_nullish_chain_shape_number_middle() {
var a = { b: 4 };
var v = struct_exists(a, "b") ? (struct_exists(a.b, "c") ? a.b.c : undefined) : undefined;
return typeof(v);
}

function case_extension_lowering_nullish_chain_shape_undefined_base() {
var a = undefined;
var v = struct_exists(a, "b") ? a.b : undefined;
return typeof(v);
}

function case_extension_lowering_closure_shape_copy() {
var n = 3;
var f = method({ n: n }, function() { return n * 2; });
n = 10;
return f();
}

function case_extension_lowering_closure_shape_self_kept() {
var s = { hp: 5 };
with (s) {
	var k = 2;
	var f = method({ k: k, __gmlc_self: self }, function() { return __gmlc_self.hp + k; });
	return f();
}
}

function case_extension_lowering_let_shape_box_shared() {
var __let0 = { count: 0 };
var inc = method({ __let0: __let0 }, function() { __let0.count += 1; });
inc();
inc();
return __let0.count;
}

function case_extension_lowering_let_shape_box_per_iteration() {
var fs = [];
for (var i = 0; i < 3; i++) {
	var __let0 = { v: i };
	array_push(fs, method({ __let0: __let0 }, function() { return __let0.v; }));
}
return string(fs[0]()) + string(fs[1]()) + string(fs[2]());
}

function case_extension_lowering_nullish_hop_is_struct_index() {
var a = { b: undefined };
var v = is_struct(a) ? (is_struct(a[$ "b"]) ? a[$ "b"][$ "c"] : undefined) : undefined;
return typeof(v);
}

function case_extension_lowering_nullish_hop_is_struct_hit() {
var a = { b: { c: 7 } };
return is_struct(a) ? (is_struct(a[$ "b"]) ? a[$ "b"][$ "c"] : undefined) : undefined;
}

function case_extension_lowering_closure_self_plain() {
hp_probe = 5;
var k = 2;
var f = method({ k: k, __gmlc_self: self }, function() { return __gmlc_self.hp_probe + k; });
return f();
}

function case_extension_lowering_closure_self_struct() {
var s = { hp: 5 };
var f = method({ k: 2, __gmlc_self: s }, function() { return __gmlc_self.hp + k; });
return f();
}

function case_extension_lowering_closure_self_with_no_return() {
var s = { hp: 5 };
var r = 0;
with (s) {
	var f = method({ k: 2, __gmlc_self: self }, function() { return __gmlc_self.hp + k; });
	r = f();
}
return r;
}

function case_extension_lowering_struct_literal_self() {
var s = { me: self };
return s.me == s;
}

function case_extension_lowering_closure_with_restore_self() {
hp_probe = 5;
var k = 2;
var _self = self;
var _other = other;
var f = method({ __closure__self: _self, __closure__other: _other, __closure__k: k }, function() {
	var k = __closure__k;
	var _s = __closure__self;
	with (__closure__other) {
		with (_s) {
			return hp_probe + k;
		}
	}
});
return f();
}

function case_extension_lowering_closure_with_restore_other() {
var outer = { name: "outer" };
var inner = { name: "inner" };
var f = undefined;
with (outer) {
	with (inner) {
		var _self = self;
		var _other = other;
		f = method({ __closure__self: _self, __closure__other: _other }, function() {
			var _s = __closure__self;
			with (__closure__other) {
				with (_s) {
					return self.name + "/" + other.name;
				}
			}
		});
	}
}
return f();
}

function case_extension_lowering_closure_with_restore_write() {
var s = { hp: 5 };
var f = undefined;
with (s) {
	var _self = self;
	var _other = other;
	f = method({ __closure__self: _self, __closure__other: _other }, function() {
		var _s = __closure__self;
		with (__closure__other) {
			with (_s) {
				hp -= 2;
			}
		}
	});
}
f();
return s.hp;
}

function case_extension_lowering_closure_with_restore_args() {
var _self = self;
var _other = other;
var f = method({ __closure__self: _self, __closure__other: _other }, function(a, b) {
	var _s = __closure__self;
	with (__closure__other) {
		with (_s) {
			return a * 10 + b + argument_count;
		}
	}
});
return f(3, 4);
}

function case_extension_lowering_let_box_with_restore() {
var _self = self;
var _other = other;
var __let0 = { hp: 10 };
var hit = method({ __closure__self: _self, __closure__other: _other, __let0: __let0 }, function(d) {
	var __let0 = self.__let0;
	var _s = __closure__self;
	with (__closure__other) {
		with (_s) {
			__let0.hp -= d;
		}
	}
});
hit(3);
hit(2);
return __let0.hp;
}

function case_extension_lowering_static_get_global_keys() {
var s = static_get(global);
return typeof(s) + ":" + string(struct_get_names(s));
}

function case_extension_lowering_static_get_global_same() {
return static_get(global) == static_get(global);
}

function case_extension_lowering_static_get_global_not_globals() {
global.ext_lowering_probe = 5;
return typeof(struct_get(static_get(global), "ext_lowering_probe"));
}

function case_extension_lowering_struct_get_undefined() {
return struct_get(undefined, "b");
}

function case_extension_lowering_struct_get_number() {
return typeof(struct_get(4, "b"));
}

function case_extension_lowering_struct_get_bool() {
return typeof(struct_get(true, "b"));
}

function case_extension_lowering_struct_get_string() {
return struct_get("text", "b");
}

function case_extension_lowering_struct_get_array() {
return struct_get([1, 2], "b");
}

function case_extension_lowering_sentinel_chain_hit() {
var a = { b: { c: { d: 7 } } };
return is_undefined(a) ? undefined : struct_get(struct_get(struct_get(a, "b") ?? static_get(global), "c") ?? static_get(global), "d");
}

function case_extension_lowering_sentinel_chain_missing_middle() {
var a = { b: { x: 1 } };
var v = is_undefined(a) ? undefined : struct_get(struct_get(struct_get(a, "b") ?? static_get(global), "c") ?? static_get(global), "d");
return typeof(v);
}

function case_extension_lowering_sentinel_chain_number_middle() {
var a = { b: 4 };
var v = is_undefined(a) ? undefined : struct_get(struct_get(a, "b") ?? static_get(global), "c");
return typeof(v);
}

function case_extension_lowering_sentinel_chain_undefined_base() {
var a = undefined;
var v = is_undefined(a) ? undefined : struct_get(struct_get(a, "b") ?? static_get(global), "c");
return typeof(v);
}

function case_extension_lowering_sentinel_chain_tostring_after_break() {
var a = {};
var v = struct_get(struct_get(a, "b") ?? static_get(global), "toString");
return typeof(v);
}

function case_extension_lowering_sentinel_chain_string_base() {
var a = "text";
return is_undefined(a) ? undefined : struct_get(a, "b");
}

function case_extension_lowering_struct_literal_self_dot() {
hp_probe = 5;
var s = { a: self.hp_probe };
return s.a;
}

function case_extension_lowering_struct_literal_self_parenthesised() {
var s = { me: (self) };
return s.me == s;
}

function case_extension_lowering_struct_literal_self_in_array() {
var c = self;
var s = { me: [self] };
return s.me[0] == c;
}

function case_extension_lowering_struct_literal_self_call_argument() {
var c = self;
var f = function(v) { return v; };
var s = { me: f(self) };
return s.me == c;
}

function case_extension_lowering_struct_literal_self_ternary() {
var c = self;
var s = { me: true ? self : undefined };
return s.me == c;
}

function case_extension_lowering_struct_literal_self_nested() {
var s = { inner: { me: self } };
return s.inner.me == s.inner;
}

function case_extension_lowering_struct_literal_self_with_key() {
var s = { me: self, x1: 4 };
return s.me.x1;
}

function case_extension_lowering_struct_literal_self_repeated_key() {
var s = { me: self, me: 3 };
return s.me;
}
