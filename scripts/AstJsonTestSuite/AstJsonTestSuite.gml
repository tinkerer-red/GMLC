// The JSON form of the syntax tree: a tree written, read back and written again gives the same text, the tree read
// back is made of the node constructors, and a program compiled from the JSON runs like the one compiled from source.

#region jsDoc
/// @func    ast_json_round_trip(_source)
/// @desc    Parses and resolves a source, writes its tree as JSON, reads it back and writes it again.
/// @param   {String} _source : GML source
/// @returns {Struct} {env, json, again, tree}
#endregion
function ast_json_round_trip(_source) {
	static __env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
	var _env = __env;
	var _sources = _env.__newSourceTable();
	_env.lexer.initialize(_source, "round_trip", array_length(_sources.files));
	var _program = _env.lexer.parseAll();
	_sources.add(_program.file);
	_program.sources = _sources;
	_env.__preprocess([_program], _sources);
	_env.parser.initialize(_program);
	var _ast = _env.parser.parseAll();
	_env.resolver.initialize(_ast, _sources);
	_ast = _env.resolver.parseAll();
	var _json = GMLC_AstToJson(_ast, _sources, "resolved");
	var _tree = GMLC_AstFromJson(_json).root;
	return { env: _env, json: _json, again: GMLC_AstToJson(_tree, _sources, "resolved"), tree: _tree };
}

function AstJsonTestSuite() : TestSuite() constructor {
	
	addFact("Statements and expressions survive the round trip", function() {
		var _r = ast_json_round_trip(@'
			var a = 1, b;
			static_value = [1, 2.5, "text", true, undefined];
			if (a = 1) { b = 2; } else if (a > 2) b = 3; else { b = 4; }
			for (var i = 0; i < 3; i++) { a += i; continue; }
			while (a < 10) a *= 2;
			do { a--; } until (a < 5);
			repeat (2) { a = a ?? 0; }
			with (self) { b = a; }
			switch (a) { case 1: b = 1; break; default: b = 0; }
			try { throw "x"; } catch (e) { b = e; } finally { a = 0; }
			delete b;
			return a;
		');
		assert_equals(_r.again, _r.json, "the JSON read back and written again differs");
		assert_true(is_instanceof(_r.tree, ASTScript), "the root read back is not an ASTScript");
	});
	
	addFact("Functions, constructors and accessors survive the round trip", function() {
		var _r = ast_json_round_trip(@'
			function Parent(_a) constructor { value = _a; static count = 0; }
			function Child(_a, _b = 2) : Parent(_a) constructor { other_value = _b; }
			var f = function(x) { return x * 2; };
			var s = { name: "s", go: function() { return name; }, shorthand };
			var arr = [[1, 2], [3, 4]];
			arr[0][1] = arr[1, 0];
			s[$ "name"] = $"pre {arr[0][0]} post";
			s.go();
			new Child(1).value += 1;
			global.counter++;
			--arr[@ 0][0];
			return f(3);
		');
		assert_equals(_r.again, _r.json, "the JSON read back and written again differs");
	});
	
	addFact("Literal values read back exactly", function() {
		var _r = ast_json_round_trip(@'return [0.1, 2147483648, $FFFFFFFFFFFFFFFF, #ff8000, 0b101, "a\tb\né", 9223372036854775807];');
		assert_equals(_r.again, _r.json, "the JSON read back and written again differs");
		var _elements = _r.tree.body[0][$ "argument"].elements;
		assert_equals(_elements[0].value, 0.1, "0.1 changed");
		assert_true(is_int64(_elements[1].value), "2147483648 is no longer an int64");
		assert_equals(_elements[6].value, int64("9223372036854775807"), "the largest int64 changed");
	});
	
	addFact("Macro and enum origins survive the round trip", function() {
		var _r = ast_json_round_trip(@'
			#macro AST_JSON_SPEED 4
			enum AstJsonDir { Left = -1, Right = 1 }
			return AstJsonDir.Right * AST_JSON_SPEED;
		');
		assert_equals(_r.again, _r.json, "the JSON read back and written again differs");
		var _binary = _r.tree.body[0][$ "argument"];
		assert_equals(_binary.left.origin.kind, "enum", "the enum origin was lost");
		assert_equals(_binary.right.origin.name, "AST_JSON_SPEED", "the macro origin was lost");
		assert_equals(array_length(_r.tree.macros), 1, "the macro declaration was lost");
		assert_equals(_r.tree.enums[0].members[0].value, int64(-1), "the enum member value was lost");
	});
	
	addFact("A program compiled from the JSON runs like the source", function() {
		var _source = @'
			function ast_json_add(_a, _b) { return _a + _b; }
			var total = 0;
			for (var i = 1; i <= 4; i++) total = ast_json_add(total, i);
			var s = { n: total, twice: function() { return n * 2; } };
			return [total, s.twice(), $"{total}!", 7 & 3 == 3];
		';
		var _r = ast_json_round_trip(_source);
		var _fromSource = executeProgram(_r.env.compile(_source));
		var _fromJson = executeProgram(_r.env.compile_ast(_r.json));
		assert_equals(json_stringify(_fromJson), json_stringify(_fromSource), "the program compiled from the JSON gives another result");
	});
	
	addFact("Every node kind the parser makes survives the round trip", function() {
		var _r = ast_json_round_trip(@'
			#region kinds
			#macro AST_JSON_KINDS 1
			enum AstJsonKinds { A, B = 2 }
			globalvar ast_json_kinds_g;
			function ast_json_kinds_f(_a = 1) { static s = 0; return _a; }
			function AstJsonKindsC() constructor { v = 1; }
			var a = (AST_JSON_KINDS > 0) ? 1 : 2, b;
			b = a ?? 0;
			b = (a && b) || !a;
			b++;
			ast_json_kinds_f(1, , 2);
			var s = { k: 1, a };
			s.f = function() { return 0; };
			s.f();
			new AstJsonKindsC();
			b = [s[$ "k"], $"t{a}"];
			if (a) { exit; }
			// @NoOp
			for (var i = 0; i < 1; i++) { continue; }
			while (false) { break; }
			repeat (1) {}
			do {} until (true);
			with (self) {}
			switch (a) { case 1: break; default: break; }
			try { throw 1; } catch (e) {} finally {}
			delete b;
			;
			return AstJsonKinds.B;
			#endregion
		');
		assert_equals(_r.again, _r.json, "the JSON read back and written again differs");
		var _names = __GMLC_NodeKinds().names;
		var _i = 0; repeat (array_length(_names)) {
			// Nameof is folded by the preprocessor
			if (_names[_i] != "Nameof") {
				assert_true(string_pos("\"kind\":\"" + _names[_i] + "\"", _r.json) > 0, $"no {_names[_i]} node in the dump");
			}
		_i++}
		assert_equals(array_length(_r.tree.regions), 2, "the regions were lost");
		assert_equals(array_length(_r.tree.pragmas), 1, "the pragma was lost");
		assert_true(_r.tree.pragmas[0].target != undefined, "the pragma's target was lost");
	});
	
	addFact("Reals JSON has no number for read back exactly", function() {
		var _values = [NaN, infinity, -infinity, -0, 0.1 + 0.2, power(10, 300)];
		var _i = 0; repeat (array_length(_values)) {
			var _literal = new ASTLiteral(new GMLC_Span(0, 0, 0), "real", "x", _values[_i]);
			var _back = GMLC_AstFromJson(GMLC_AstToJson(_literal, undefined)).root.value;
			var _same = (is_nan(_values[_i]) && is_nan(_back)) || ((_back == _values[_i]) && (sign(1 / _back) == sign(1 / _values[_i])));
			assert_true(_same, $"real {_i} read back as {_back}");
		_i++}
	});
	
	addFact("A dump with another contract version, an unknown kind or a missing field is refused", function() {
		var _json = ast_json_round_trip("return 1;").json;
		var _broken = [
			string_replace(_json, "\"contract_version\":1", "\"contract_version\":2"),
			string_replace(_json, "\"kind\":\"Literal\"", "\"kind\":\"Literally\""),
			string_replace(_json, ",\"lexeme\":\"1\"", ""),
		];
		var _i = 0; repeat (array_length(_broken)) {
			var _message = "";
			try {
				GMLC_AstFromJson(_broken[_i]);
			}
			catch (_e) {
				_message = is_struct(_e) ? string(_e[$ "message"]) : string(_e);
			}
			assert_true(string_pos("GMLC5901", _message) > 0, $"broken dump {_i} was read: {_message}");
		_i++}
	});
}
