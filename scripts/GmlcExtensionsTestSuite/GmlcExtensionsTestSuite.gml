// GMLC's language extensions: what each construct does once its
// extension is switched on, the errors it reports, and that the construct means what GameMaker makes of it when the
// extension is off.

#region jsDoc
/// @func    gmlc_ext_run(_source, _extensions)
/// @desc    Compiles and runs a source with some extensions switched on; its result, or "error " and the codes of the
///          diagnostics when the compile or the run throws.
/// @param   {String}        _source     : GML source
/// @param   {Array<String>} _extensions : The extensions to switch on
/// @returns {Any}
#endregion
function gmlc_ext_run(_source, _extensions) {
	var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
	var _i = 0; repeat (array_length(_extensions)) {
		_env.enableExtension(_extensions[_i]);
	_i++}
	try {
		return executeProgram(_env.compile(_source, "extension.gml"));
	}
	catch (_e) {
		var _codes = is_struct(_e) && is_array(_e[$ "diagnostics"]) ? gmlc_pipeline_codes(_e.diagnostics) : string(_e);
		return "error " + _codes;
	}
}

#region jsDoc
/// @func    gmlc_ext_check(_source, _extensions)
/// @desc    The codes of the diagnostics of a source checked with some extensions switched on, joined by commas.
/// @param   {String}        _source     : GML source
/// @param   {Array<String>} _extensions : The extensions to switch on
/// @returns {String}
#endregion
function gmlc_ext_check(_source, _extensions) {
	var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
	var _i = 0; repeat (array_length(_extensions)) {
		_env.enableExtension(_extensions[_i]);
	_i++}
	return gmlc_pipeline_codes(_env.check(_source, "extension.gml"));
}

#region jsDoc
/// @func    __gmlc_ext_parsed(_env, _source)
/// @desc    The parsed tree of a source in an environment, extensions rewritten.
/// @param   {Struct.GMLC_Env} _env    : The environment
/// @param   {String}          _source : GML source
/// @returns {Struct.ASTScript}
#endregion
function __gmlc_ext_parsed(_env, _source) {
	var _sources = _env.__newSourceTable();
	_env.lexer.initialize(_source, "extension.gml", array_length(_sources.files));
	var _program = _env.lexer.parseAll();
	_sources.add(_program.file);
	_program.sources = _sources;
	_env.__preprocess([_program], _sources, []);
	_env.parser.initialize(_program);
	return _env.parser.parseAll();
}

function GmlcExtensionsTestSuite() : TestSuite() constructor {
	#region Switching extensions on
	addFact("An unknown extension name is GMLC5008 [GMLC]", function() {
		var _env = new GMLC_Env();
		var _codes = "";
		try {
			_env.enableExtension("no-such-extension");
		}
		catch (_e) {
			_codes = gmlc_pipeline_codes(_e.diagnostics);
		}
		assert_equals(_codes, "GMLC5008", "an unknown extension was accepted");
	});
	
	addFact("An extension switched off again no longer applies [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		_env.enableExtension("let").disableExtension("let");
		assert_false(_env.isExtensionEnabled("let"), "let is still on");
		assert_equals(gmlc_pipeline_codes(_env.check("var let = 4;", "extension.gml")), "", "let as a name was refused");
	});
	#endregion
	
	#region nullish-chaining
	addFact("?. reads through a chain of structs [GMLC]", function() {
		assert_equals(gmlc_ext_run("var a = { b: { c: 7 } }; return a?.b?.c;", ["nullish-chaining"]), 7, "the chain did not reach the value");
	});
	
	addFact("?. gives undefined for a missing key in the middle of a chain [GMLC]", function() {
		assert_equals(gmlc_ext_run("var a = { x: 1 }; return typeof(a?.b?.c);", ["nullish-chaining"]), "undefined", "a missing key did not give undefined");
	});
	
	addFact("?. gives undefined for a middle value that is undefined, a number or a bool [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var r = "";
			r += typeof({ b: undefined }?.b?.c);
			var n = { b: 4 };
			r += "," + typeof(n?.b?.c);
			var t = { b: true };
			r += "," + typeof(t?.b?.c);
			return r;
		', ["nullish-chaining"]);
		assert_equals(_result, "undefined,undefined,undefined", "a value that is not a struct broke the chain");
	});
	
	addFact("?. throws for a middle value that is a string or an array, as struct_get does [GMLC]", function() {
		var _string = gmlc_ext_run(@'var s = { b: "text" }; return s?.b?.c;', ["nullish-chaining"]);
		var _array = gmlc_ext_run("var s = { b: [1, 2] }; return s?.b?.c;", ["nullish-chaining"]);
		assert_equals(string_copy(_string, 1, 5) + "," + string_copy(_array, 1, 5), "error,error", "a string or an array in the chain did not throw");
	});
	
	addFact("?. reads a base that is not undefined as struct_get does: a number gives undefined, a string or an array throws [GMLC]", function() {
		var _number = gmlc_ext_run("var a = 5; return typeof(a?.b?.c);", ["nullish-chaining"]);
		var _string = gmlc_ext_run(@'var a = "text"; return a?.b;', ["nullish-chaining"]);
		var _array = gmlc_ext_run("var a = [1, 2]; return a?.b;", ["nullish-chaining"]);
		assert_equals(_number + "," + string_copy(_string, 1, 5) + "," + string_copy(_array, 1, 5), "undefined,error,error", "the base was not read as struct_get reads it");
	});
	
	addFact("?. reads through and breaks anywhere in a long chain [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var a = { b: { c: { d: { e: { f: 6 } } } } };
			var r = string(a?.b?.c?.d?.e?.f);
			a = { b: { c: { x: 1 } } };
			r += "," + typeof(a?.b?.c?.d?.e?.f);
			a = { b: { c: { d: { e: { g: 1 } } } } };
			r += "," + typeof(a?.b?.c?.d?.e?.f);
			return r;
		', ["nullish-chaining"]);
		assert_equals(_result, "6,undefined,undefined", "the long chain gave a wrong value");
	});
	
	addFact("?. gives undefined for toString after a break, and reads a real toString [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var a = {};
			var r = typeof(a?.b?.toString);
			var f = function() { return "x"; };
			a = { b: { toString: f } };
			r += "," + string(a?.b?.toString());
			return r;
		', ["nullish-chaining"]);
		assert_equals(_result, "undefined,x", "toString was read from the empty struct, or the real one was lost");
	});
	
	addFact("?. on a base that is a call gives undefined when the call gives undefined [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var mk = function() { return undefined; };
			return typeof(mk()?.b?.c);
		', ["nullish-chaining"]);
		assert_equals(_result, "undefined", "an undefined call result broke the chain");
	});
	
	addFact("?. lowers to one struct_get per key after an undefined test of the base [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL).enableExtension("nullish-chaining");
		var _script = __gmlc_ext_parsed(_env, "var a, v = a?.b?.c;");
		var _value = _script.body[0].declarations[1].init;
		var _hop = _value.alternate;
		var _ok = (_value.kind == __GMLC_NodeKind_Conditional) && (_value.test.callee.name == "is_undefined")
			&& (_hop.callee.name == "struct_get") && (_hop.args[0].kind == __GMLC_NodeKind_Nullish)
			&& (_hop.args[0].right.callee.name == "static_get") && (_hop.args[0].left.callee.name == "struct_get")
			&& (_hop.args[0].left.args[0].kind == __GMLC_NodeKind_Identifier);
		assert_true(_ok, "the chain did not lower to the guarded struct_get form");
	});
	
	addFact("?. gives undefined for an undefined base [GMLC]", function() {
		assert_equals(gmlc_ext_run("var a = undefined; return typeof(a?.b);", ["nullish-chaining"]), "undefined", "an undefined base threw");
	});
	
	addFact("?. with ?? picks the fallback for a missing key [GMLC]", function() {
		assert_equals(gmlc_ext_run("var a = {}; return a?.b ?? 5;", ["nullish-chaining"]), 5, "the fallback was not taken");
	});
	
	addFact("?. reads a base that is a call only once [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			calls_probe = 0;
			var mk = function() { calls_probe += 1; return { b: { c: 3 } }; };
			var v = mk()?.b?.c;
			return string(v) + ":" + string(calls_probe);
		', ["nullish-chaining"]);
		assert_equals(_result, "3:1", "the call ran more than once");
	});
	
	addFact("A plain dot after a ?. chain reads the chain's result [GMLC]", function() {
		assert_equals(gmlc_ext_run("var a = { b: { c: { d: 1 } } }; return a?.b.c.d;", ["nullish-chaining"]), 1, "the dot after the chain failed");
	});
	
	addFact("A ? followed by a number is still a conditional with ?. switched on [GMLC]", function() {
		assert_equals(gmlc_ext_run("var a = 1; return a ?.5 : 2;", ["nullish-chaining"]), 0.5, "the conditional was read as a chain");
	});
	
	addFact("Assigning to a ?. chain is GMLC1004 [GMLC]", function() {
		assert_equals(gmlc_ext_check("var a = {}; a?.b = 1;", ["nullish-chaining"]), "GMLC1004", "the assignment was accepted");
	});
	
	addFact("?. is GMLC1013 when nullish-chaining is off [GMLC]", function() {
		assert_equals(gmlc_ext_check("var a = {}; var v = a?.b;", []), "GMLC1013", "?. was accepted without the extension");
	});
	#endregion
	
	#region macro-params
	addFact("A macro with a parameter can pass it on to another macro with a parameter [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			#macro DOUBLE(x) ((x) * 2)
			#macro CALL(x) DOUBLE(x)
			return CALL(5) + CALL(1 + 1);
		', ["macro-params"]);
		assert_equals(_result, 14, "the macro did not pass its argument on");
	});
	
	addFact("A macro with a parameter is expanded with its argument [GMLC]", function() {
		assert_equals(gmlc_ext_run("#macro SQ(X) ((X) * (X))\nreturn SQ(3);", ["macro-params"]), 9, "the argument was not put in");
	});
	
	addFact("A macro with two parameters splits its arguments at top-level commas [GMLC]", function() {
		assert_equals(gmlc_ext_run("#macro ADD(A, B) ((A) + (B))\nreturn ADD(max(1, 4), 2);", ["macro-params"]), 6, "the arguments were split inside the call");
	});
	
	addFact("Macros in the arguments of a macro with parameters expand too [GMLC]", function() {
		var _source = "#macro SQ(X) ((X) * (X))\n#macro ADD(A, B) ((A) + (B))\nreturn SQ(ADD(1, 2));";
		assert_equals(gmlc_ext_run(_source, ["macro-params"]), 9, "the inner macro did not expand");
	});
	
	addFact("A macro with an empty parameter list takes no arguments [GMLC]", function() {
		assert_equals(gmlc_ext_run("#macro ZERO() 40\nreturn ZERO() + 2;", ["macro-params"]), 42, "the empty list was not read");
	});
	
	addFact("A parameter name after a dot in the body is a member, not the parameter [GMLC]", function() {
		var _source = "#macro PICK(S, X) S.X\nvar s = { X: 4 };\nreturn PICK(s, 9);";
		assert_equals(gmlc_ext_run(_source, ["macro-params"]), 4, "the member name was replaced");
	});
	
	addFact("A wrong argument count is GMLC0318 and a malformed parameter list GMLC0319 [GMLC]", function() {
		assert_equals(gmlc_ext_check("#macro SQ(X) ((X) * (X))\nvar v = SQ(1, 2);", ["macro-params"]), "GMLC0318", "the count was not checked");
		assert_equals(gmlc_ext_check("#macro BAD(1) 0\nvar v = 1;", ["macro-params"]), "GMLC0319", "the list was not checked");
	});
	
	addFact("Without macro-params a parameter list is the start of the body, as in GameMaker [GMLC]", function() {
		// GameMaker reads `#macro WRAP(X) + 1` as the macro WRAP with the body `(X) + 1`
		assert_equals(gmlc_ext_run("#macro WRAP(X) + 1\nvar X = 4;\nreturn WRAP;", []), 5, "the parameter list was not body text");
	});
	#endregion
	
	#region const
	addFact("A literal const is read as its value [GMLC]", function() {
		assert_equals(gmlc_ext_run("const LIMIT = 10;\nreturn LIMIT * 2;", ["const"]), 20, "the constant was not read");
	});
	
	addFact("A negative literal const keeps its sign [GMLC]", function() {
		assert_equals(gmlc_ext_run("const N = -2;\nreturn N;", ["const"]), -2, "the sign was lost");
	});
	
	addFact("A const of any other value is a local [GMLC]", function() {
		assert_equals(gmlc_ext_run("const ARR = [1, 2];\nreturn ARR[1];", ["const"]), 2, "the value was lost");
	});
	
	addFact("Changing a const is GMLC2012 [GMLC]", function() {
		assert_equals(gmlc_ext_check("const A = 1;\nA = 2;", ["const"]), "GMLC2012", "an assignment was accepted");
		assert_equals(gmlc_ext_check("const B = [1];\nB++;", ["const"]), "GMLC2012", "++ was accepted");
		assert_equals(gmlc_ext_check("const C = 1;\nvar C = 2;", ["const"]), "GMLC2012", "a second declaration was accepted");
	});
	
	addFact("A const is not seen by a function inside its function [GMLC]", function() {
		assert_equals(gmlc_ext_run("const K = 3;\nvar f = function() { var K = 7; return K; };\nreturn f();", ["const"]), 7, "the nested function's own K was replaced");
	});
	
	addFact("const without a value is GMLC1032 [GMLC]", function() {
		assert_equals(gmlc_ext_check("const Z;", ["const"]), "GMLC1032", "the missing value was accepted");
	});
	
	addFact("const not followed by a name stays a name [GMLC]", function() {
		assert_equals(gmlc_ext_run("var const = 5;\nreturn const;", ["const"]), 5, "const as a name was refused");
	});
	#endregion
	
	#region closure
	addFact("A closure keeps a copy of a local of the code around it [GMLC]", function() {
		assert_equals(gmlc_ext_run("var k = 2;\nvar f = closure(function(x) { return x * k; });\nk = 10;\nreturn f(3);", ["closure"]), 6, "the copy was not kept");
	});
	
	addFact("A closure runs with the self it was made with [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var s = { hp: 5 };
			var f = undefined;
			with (s) {
				var add = 2;
				f = closure(function() { return hp + add; });
			}
			return f();
		', ["closure"]);
		assert_equals(_result, 7, "the closure did not read its creator's variable");
	});
	
	addFact("A closure writes its creator's instance variable [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var s = { hp: 5 };
			var f = undefined;
			with (s) {
				f = closure(function() { hp -= 2; });
			}
			f();
			return s.hp;
		', ["closure"]);
		assert_equals(_result, 3, "the write went elsewhere");
	});
	
	addFact("A closure reads its arguments [GMLC]", function() {
		assert_equals(gmlc_ext_run("var f = closure(function(a, b) { return a * 10 + b + argument_count; });\nreturn f(3, 4);", ["closure"]), 36, "the arguments were lost");
	});
	
	addFact("A closure inside a closure sees the outer one's copies [GMLC]", function() {
		var _source = "var a = 1;\nvar f = closure(function() { var b = 2; return closure(function() { return a + b; }); });\nvar g = f();\nreturn g();";
		assert_equals(gmlc_ext_run(_source, ["closure"]), 3, "the inner closure lost a copy");
	});
	
	addFact("closure of something that is not a function expression is GMLC1031 [GMLC]", function() {
		assert_equals(gmlc_ext_check("var f = closure(5);", ["closure"]), "GMLC1031", "a number was accepted");
	});
	
	addFact("Without the closure extension closure is an ordinary function name [GMLC]", function() {
		assert_equals(gmlc_ext_run("function closure(f) { return 5; }\nreturn closure(function() {});", []), 5, "the call was not to the script's function");
	});
	addFact("method gives a closure another self and the closure keeps its copies [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			armor = 10;
			var hp = 5;
			var f = closure(function() { return hp + armor; });
			var g = method({ armor: 2 }, f);
			return string(f()) + "," + string(g());
		', ["closure"]);
		assert_equals(_result, "15,7", "the closure lost its copies or its self");
	});
	
	addFact("method_get_self of a rebound closure is the struct it was given [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var hp = 5;
			var s = { armor: 2 };
			var g = method(s, closure(function() { return hp; }));
			return method_get_self(g) == s;
		', ["closure"]);
		assert_true(_result, "method_get_self gave the struct of copies");
	});
	
	addFact("method still binds a plain function with closure on [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var h = function() { return armor; };
			return method({ armor: 3 }, h)();
		', ["closure"]);
		assert_equals(_result, 3, "a plain function was not bound");
	});
	
	addFact("method gives a function a let wrapped another self and keeps the let [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var f;
			{
				let hp = 5;
				f = function() { return hp + armor; };
			}
			var g = method({ armor: 2 }, f);
			return g();
		', ["let"]);
		assert_equals(_result, 7, "the let function lost its box or its self");
	});
	
	addFact("Names an extension makes start with __gmlc__ and keep a leading underscore of the name [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL).enableExtension("let");
		var _script = __gmlc_ext_parsed(_env, "{ let _hp = 1; let __priv = 2; }");
		var _block = _script.body[0].body;
		var _a = _block[0].declarations[0].target.name;
		var _b = _block[1].declarations[0].target.name;
		var _ok = (string_copy(_a, 1, 11) == "__gmlc__let") && (string_copy(_a, string_length(_a) - 4, 5) == "___hp")
			&& (string_copy(_b, 1, 11) == "__gmlc__let") && (string_copy(_b, string_length(_b) - 7, 8) == "____priv");
		assert_true(_ok, "the names were " + _a + " and " + _b);
	});
	
	#endregion
	
	#region let
	addFact("Two blocks each have their own let of one name [GMLC]", function() {
		assert_equals(gmlc_ext_run("var r = \"\";\n{ let x = 1; r += string(x); }\n{ let x = 2; r += string(x); }\nreturn r;", ["let"]), "12", "the lets were mixed up");
	});
	
	addFact("A let in a block leaves a var of the same name outside it alone [GMLC]", function() {
		assert_equals(gmlc_ext_run("var x = 5;\n{ let x = 1; }\nreturn x;", ["let"]), 5, "the let changed the var");
	});
	
	addFact("Functions made in a loop body each keep that iteration's let [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var fs = [];
			for (var i = 0; i < 3; i++) {
				let v = i;
				array_push(fs, function() { return v; });
			}
			return string(fs[0]()) + string(fs[1]()) + string(fs[2]());
		', ["let"]);
		assert_equals(_result, "012", "the iterations shared one variable");
	});
	
	addFact("Functions made in a for loop each keep that iteration's copy of a header let, as in JavaScript [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var fs = [];
			for (let i = 0; i < 3; i++) {
				array_push(fs, function() { return i; });
			}
			return string(fs[0]()) + string(fs[1]()) + string(fs[2]());
		', ["let"]);
		assert_equals(_result, "012", "the iterations shared one variable");
	});
	
	addFact("continue in a for loop with a header let still runs the update on a fresh copy [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var fs = [];
			for (let i = 0; i < 4; i++) {
				if (i == 1) continue;
				array_push(fs, function() { return i; });
			}
			return string(fs[0]()) + string(fs[1]()) + string(fs[2]());
		', ["let"]);
		assert_equals(_result, "023", "continue skipped the update or shared the variable");
	});
	
	addFact("A write in the body changes that iteration's copy; the update changes the next one [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var fs = [];
			for (let i = 0; i < 6; i++) {
				array_push(fs, function() { return i; });
				i++;
			}
			return string(fs[0]()) + string(fs[1]()) + string(fs[2]());
		', ["let"]);
		assert_equals(_result, "135", "the copies were not per iteration");
	});
	
	addFact("A function shares a let with its block, writes included [GMLC]", function() {
		assert_equals(gmlc_ext_run("let count = 0;\nvar inc = function() { count += 1; };\ninc();\ninc();\nreturn count;", ["let"]), 2, "the writes did not reach the block");
	});
	
	addFact("A function that reaches a let runs with the self it was made with [GMLC]", function() {
		var _result = gmlc_ext_run(@'
			var s = { hp: 5 };
			var f = undefined;
			with (s) {
				let k = 2;
				f = function() { return hp + k; };
			}
			return f();
		', ["let"]);
		assert_equals(_result, 7, "the function lost its self");
	});
	
	addFact("A var is not passed into a function a let made a closure [GMLC]", function() {
		assert_equals(gmlc_ext_check("var a = 3;\nlet b = 4;\nvar f = function() { return a + b; };", ["let"]), "GMLC2110", "the var was passed on, or the warning is missing");
	});
	
	addFact("closure passes both the vars and the lets on [GMLC]", function() {
		var _result = gmlc_ext_run("var a = 3;\nlet b = 4;\nvar f = closure(function() { return a + b; });\nb = 10;\nreturn f();", ["let", "closure"]);
		assert_equals(_result, 13, "the var copy or the shared let was lost");
	});
	
	addFact("A let declared twice in a block is one variable, with warning GMLC2016 [GMLC]", function() {
		assert_equals(gmlc_ext_check("{ let q = 1; let q = 2; }", ["let"]), "GMLC2016", "the second declaration was not a warning");
		assert_equals(gmlc_ext_run("let q = 1;\nvar f = function() { return q; };\nlet q = 2;\nreturn f();", ["let"]), 2, "the second declaration made another variable");
	});

	addFact("A named function reads a let at the top of its script, through the file's box [GMLC]", function() {
		assert_equals(gmlc_ext_run("let z = 3;\nfunction ext_named() { return z; }\nz += 1;\nreturn ext_named();", ["let"]), 4, "the named function did not see the script's let");
	});

	addFact("A setting at the top of a script reaches a named function as its literal [GMLC]", function() {
		assert_equals(gmlc_ext_run("let speed = 5;\nfunction ext_speed() { return speed; }\nreturn ext_speed();", ["let"]), 5, "the setting did not reach the named function");
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		_env.enableExtension("let");
		var _tree = __gmlc_ext_parsed(_env, "let speed = 5;\nfunction ext_speed() { return speed; }");
		assert_equals(string_pos("__gmlc__filebox", json_stringify(_tree)), 0, "the setting was boxed instead of propagated");
	});

	addFact("A named function cannot reach a captured let inside a block: GMLC2014 [GMLC]", function() {
		assert_equals(gmlc_ext_check("if (true) {\n\tlet z = 1;\n\tfunction ext_named() { return z; }\n}", ["let"]), "GMLC2014", "the named function was accepted");
	});
	
	addFact("Without the let extension let is an ordinary name [GMLC]", function() {
		assert_equals(gmlc_ext_run("var let = 4;\nreturn let;", []), 4, "let as a name was refused");
	});
	#endregion
	
	#region Review fixes
	addFact("A ? followed by the string \".\" is a conditional, with or without nullish-chaining [GMLC]", function() {
		assert_equals(gmlc_ext_run("var a = true;\nreturn a?\".\":\"x\";", []), ".", "off: the string was read as ?.");
		assert_equals(gmlc_ext_run("var a = false;\nreturn a?\".\":\"y\";", ["nullish-chaining"]), "y", "on: the string was read as ?.");
		assert_equals(gmlc_ext_run("var a = true;\nreturn a?\".\" + \"z\":\"\";", ["nullish-chaining"]), ".z", "on: the string after ? was lost");
	});
	
	addFact("A function made in its own let declaration reaches the let [GMLC]", function() {
		assert_equals(gmlc_ext_run("let n = 0, inc = function() { n++; };\ninc();\ninc();\nreturn n;", ["let"]), 2, "the function in the list lost the let");
		assert_equals(gmlc_ext_run("let g = function(k) { return (k <= 0) ? 0 : g(k - 1) + 1; };\nreturn g(3);", ["let"]), 3, "the recursive let failed");
	});
	
	addFact("A caught name and a static hide a let of their name [GMLC]", function() {
		assert_equals(gmlc_ext_run("var r = 0;\n{ let e = 1; try { throw 2; } catch (e) { } r = e; }\nreturn r;", ["let"]), 1, "the catch wrote into the let");
		assert_equals(gmlc_ext_run("var r = 0;\n{ let n = 0; var f = function() { static n = 5; return n; }; r = f(); }\nreturn r;", ["let"]), 5, "the static was read as the let");
	});
	
	addFact("A closure copies only locals of the function directly around it [GMLC]", function() {
		var _source = "var cfg = 1;\nfunction ext_cfg() { return closure(function() { cfg = 2; }); }\nvar f = ext_cfg();\nf();\nreturn self.cfg;";
		assert_equals(gmlc_ext_run(_source, ["closure"]), 2, "the instance variable was copied as a local");
	});
	
	addFact("A macro argument that is a string with a bracket or comma stays whole [GMLC]", function() {
		assert_equals(gmlc_ext_run("#macro ID(X) X\nreturn ID(\")\");", ["macro-params"]), ")", "a string closed the arguments");
		assert_equals(gmlc_ext_run("#macro ID(X) X\nreturn ID(\",\");", ["macro-params"]), ",", "a string split the arguments");
	});
	
	addFact("A closure sees the literal constants around it, and cannot change them [GMLC]", function() {
		assert_equals(gmlc_ext_run("const N = 5;\nvar f = closure(function() { return N; });\nreturn f();", ["const", "closure"]), 5, "the constant was lost in the closure");
		assert_equals(gmlc_ext_check("const N = 5;\nvar f = closure(function() { N = 1; });", ["const", "closure"]), "GMLC2012", "the write in the closure was accepted");
	});
	
	addFact("A literal const in struct shorthand keeps its key [GMLC]", function() {
		assert_equals(gmlc_ext_run("const N = 5;\nvar s = {N};\nreturn s.N;", ["const"]), 5, "the key was lost");
	});
	
	addFact("A closure in a parameter default or of a constructor is GMLC1031 [GMLC]", function() {
		assert_equals(gmlc_ext_check("function ext_d(f = closure(function() {})) { return f; }", ["closure"]), "GMLC1031", "the default was accepted");
		assert_equals(gmlc_ext_check("var C = closure(function() constructor {});", ["closure"]), "GMLC1031", "the constructor was accepted");
	});
	
	addFact("A closure whose body does not name other does not need a valid other [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL).enableExtension("closure");
		var _ast = __gmlc_ext_parsed(_env, "var k = 2;\nvar f = closure(function() { return k; });");
		assert_equals(array_length(gmlc_pipeline_nodes(_ast, __GMLC_NodeKind_With)), 1, "other was restored without being named");
	});
	#endregion
}
