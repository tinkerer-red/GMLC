// What GMLC's own stages promise where GameMaker has nothing to measure against: which declaration a name means in a
// file and across a batch, the errors for writes to what cannot change, where errors say they are (compile time, run
// time, code from a macro, a program compiled from JSON), the parser's nesting limit, and the origins and pragma
// targets it writes.

#region jsDoc
/// @func    gmlc_pipeline_error(_source)
/// @desc    Compiles and runs a source; the error it throws, undefined when it throws none.
/// @param   {String} _source : GML source
/// @returns {Struct|Undefined}
#endregion
function gmlc_pipeline_error(_source) {
	static __env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
	try {
		executeProgram(__env.compile(_source, "pipeline.gml"));
	}
	catch (_e) {
		return _e;
	}
	return undefined;
}

#region jsDoc
/// @func    gmlc_pipeline_message(_error)
/// @desc    The message of an error, "" when there is none.
/// @param   {Any} _error : What was thrown
/// @returns {String}
#endregion
function gmlc_pipeline_message(_error) {
	if (_error == undefined) return "";
	return is_struct(_error) ? string(_error[$ "message"]) : string(_error);
}

#region jsDoc
/// @func    gmlc_pipeline_nodes(_node, _kind, [_out])
/// @desc    Every node of a kind in a tree, in order.
/// @param   {Struct.ASTNode} _node : The tree
/// @param   {Real}           _kind : __GMLC_NodeKind_* of the nodes wanted
/// @param   {Array}          [_out] : Where to add them
/// @returns {Array<Struct.ASTNode>}
#endregion
function gmlc_pipeline_nodes(_node, _kind, _out = []) {
	if (_node.kind == _kind) array_push(_out, _node);
	var _children = _node.children();
	var _i = 0; repeat (array_length(_children)) {
		gmlc_pipeline_nodes(_children[_i], _kind, _out);
	_i++}
	return _out;
}

#region jsDoc
/// @func    gmlc_pipeline_codes(_diagnostics)
/// @desc    The codes of a list of diagnostics in report order, joined by commas.
/// @param   {Array<Struct.GMLC_Diagnostic>} _diagnostics : The diagnostics
/// @returns {String}
#endregion
function gmlc_pipeline_codes(_diagnostics) {
	var _list = GMLC_SortDiagnostics(_diagnostics ?? []);
	var _codes = array_create(array_length(_list));
	var _i = 0; repeat (array_length(_list)) {
		_codes[_i] = _list[_i].code;
	_i++}
	return string_join_ext(",", _codes);
}

#region jsDoc
/// @func    gmlc_pipeline_check(_source)
/// @desc    The codes GMLC's check reports for a source.
/// @param   {String} _source : GML source
/// @returns {String}
#endregion
function gmlc_pipeline_check(_source) {
	static __env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
	return gmlc_pipeline_codes(__env.check(_source, "check.gml"));
}

#region jsDoc
/// @func    gmlc_pipeline_lowered(_source)
/// @desc    The tree of a source after lowering.
/// @param   {String} _source : GML source
/// @returns {Struct.ASTScript}
#endregion
function gmlc_pipeline_lowered(_source) {
	static __env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
	var _sources = __env.__newSourceTable();
	__env.lexer.initialize(_source, "lowered.gml", array_length(_sources.files));
	var _program = __env.lexer.parseAll();
	_sources.add(_program.file);
	_program.sources = _sources;
	__env.__preprocess([_program], _sources, []);
	__env.parser.initialize(_program);
	var _ast = __env.parser.parseAll();
	__env.resolver.initialize(_ast, _sources);
	_ast = __env.resolver.parseAll();
	__env.lower.initialize(_ast, _sources);
	return __env.lower.parseAll();
}

// what a function is, how it is reachable and its binding: "fn_kind registration binding"
function gmlc_pipeline_kind(_info) {
	return _info.fn_kind + " " + _info.registration + " " + _info.binding;
}

// gmlc_pipeline_kind, the enclosing function and the two counts: "... parent_fn | statements nodes"
function gmlc_pipeline_info(_info) {
	return gmlc_pipeline_kind(_info) + " " + string(_info.parent_fn) + " | " + string(_info.facts.statement_count) + " " + string(_info.facts.node_count);
}

function GmlcPipelineTestSuite() : TestSuite() constructor {
	
	#region Names in a file
	addFact("A constant struct key is read and written by its hash when the program is built [GMLC]", function() {
		var _result = compile_and_execute(@'
			var s = { a: 5, b: 1 };
			struct_set(s, "b", struct_get(s, "a") + 2);
			variable_struct_set(s, "c", variable_struct_get(s, "b") * 10);
			return [struct_get(s, "a"), s.b, s.c, struct_get(s, "missing")];
		');
		assert_equals(array_equals(_result, [5, 7, 70, undefined]), true, "the hashed reads and writes gave other values");
	});

	addFact("A struct_get with a constant key becomes struct_get_from_hash only while methods are built [GMLC]", function() {
		var _env = new GMLC_Env();
		var _callee = new ASTIdentifier(undefined, "struct_get");
		_callee.symbol = new GMLC_Symbol("BuiltinFunction", "struct_get");
		var _call = new ASTCall(undefined, _callee, [new ASTIdentifier(undefined, "s"), new ASTLiteral(undefined, "string", "\"a\"", "a")]);
		var _hashed = __GMLChashStructKey({ env: _env }, _call);
		assert_equals(_hashed.callee.name, "struct_get_from_hash", "the call was not hashed");
		assert_equals(_hashed.args[1].value, variable_get_hash("a"), "the key's hash is not the game's");
		assert_equals(_call.args[1].value, "a", "the original call was changed");
	});

	addFact("A struct_get with a key that is not a constant string stays as written [GMLC]", function() {
		var _env = new GMLC_Env();
		var _callee = new ASTIdentifier(undefined, "struct_get");
		_callee.symbol = new GMLC_Symbol("BuiltinFunction", "struct_get");
		var _call = new ASTCall(undefined, _callee, [new ASTIdentifier(undefined, "s"), new ASTLiteral(undefined, "real", "3", 3)]);
		assert_equals(__GMLChashStructKey({ env: _env }, _call), _call, "a number key was hashed");
	});

	addFact("An argument named like a function of the file is the argument [GMLC]", function() {
		assert_equals(compile_and_execute(@'
			function rp_hp() { return "function"; }
			function rp_arg(rp_hp) { return rp_hp; }
			return rp_arg(7);
		'), 7, "the argument was read as the function");
	});
	
	addFact("A local named like a function of the file is the local [GMLC]", function() {
		assert_equals(compile_and_execute(@'
			function rp_hp2() { return "function"; }
			function rp_local() { var rp_hp2 = 3; return rp_hp2; }
			return rp_local();
		'), 3, "the local was read as the function");
	});
	
	addFact("A static named like a function of the file is the static [GMLC]", function() {
		assert_equals(compile_and_execute(@'
			function rp_hp3() { return "function"; }
			function rp_static() { static rp_hp3 = 9; return rp_hp3; }
			return rp_static();
		'), 9, "the static was read as the function");
	});
	
	addFact("Assigning to a function's name leaves the name reading the function [GMLC]", function() {
		assert_equals(compile_and_execute(@'
			function rp_written() { return 1; }
			rp_written = 5;
			return is_callable(rp_written);
		'), true, "the name no longer reads the function");
	});
	#endregion
	
	#region Names across a batch
	addFact("A file calls a function another file of the batch declares [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		_env.compile_batch([
			{ name: "rp_batch_a.gml", source: "function rp_batch_a() { return rp_batch_b() + 1; }" },
			{ name: "rp_batch_b.gml", source: "function rp_batch_b() { return 41; }" },
		]);
		var _a = variable_global_get("rp_batch_a");
		assert_equals(executeProgram(_a), 42, "the call to the other file's function failed");
	});
	
	addFact("A constructor's parent may be declared by a later file of the batch [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		_env.compile_batch([
			{ name: "rp_child.gml", source: "function RpChild() : RpParent() constructor { w = 2; }" },
			{ name: "rp_parent.gml", source: "function RpParent() constructor { v = 5; static kind = \"parent\"; }" },
		]);
		var _child = variable_global_get("RpChild");
		var _made = new _child();
		assert_equals(string(_made.v) + ":" + string(_made.w) + ":" + _made.kind, "5:2:parent", "the parent of the other file did not run");
	});
	
	addFact("A function of another file of the batch is a value too [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		_env.compile_batch([
			{ name: "rp_value_a.gml", source: "function rp_value_a() { return rp_value_b; }" },
			{ name: "rp_value_b.gml", source: "function rp_value_b() { return 6; }" },
		]);
		var _a = variable_global_get("rp_value_a");
		var _b = executeProgram(_a);
		assert_equals(executeProgram(_b), 6, "the other file's function was not its value");
	});
	#endregion
	
	#region Writes to what cannot change
	addFact("Assigning to a macro's number is refused as setting a constant [GMLC]", function() {
		var _message = gmlc_pipeline_message(gmlc_pipeline_error("#macro RP_LIMIT 10\nRP_LIMIT = 5;"));
		assert_true(string_pos("GMLC2201", _message) > 0, $"unexpected error: {_message}");
	});
	
	addFact("Assigning to a built-in constant is refused as setting a constant [GMLC]", function() {
		var _message = gmlc_pipeline_message(gmlc_pipeline_error("c_red = 5;"));
		assert_true(string_pos("GMLC2201", _message) > 0, $"unexpected error: {_message}");
	});
	
	addFact("Assigning to a built-in function is refused [GMLC]", function() {
		var _message = gmlc_pipeline_message(gmlc_pipeline_error("abs = 5;"));
		assert_true(string_pos("GMLC2204", _message) > 0, $"unexpected error: {_message}");
	});
	
	addFact("Assigning to a compile-time name is refused [GMLC]", function() {
		var _message = gmlc_pipeline_message(gmlc_pipeline_error("_GMLINE_ = 1;"));
		assert_true(string_pos("GMLC2203", _message) > 0, $"unexpected error: {_message}");
	});
	
	addFact("Incrementing a macro's number is refused as incrementing a constant [GMLC]", function() {
		var _message = gmlc_pipeline_message(gmlc_pipeline_error("#macro RP_STEP 10\nRP_STEP++;"));
		assert_true(string_pos("GMLC2206", _message) > 0, $"unexpected error: {_message}");
	});
	#endregion
	
	#region Where errors are
	addFact("An error at run time names the line and its text [GMLC]", function() {
		var _error = gmlc_pipeline_error("var a = 1;\nvar s = {};\nreturn s.missing;");
		assert_equals(_error[$ "line"], 3, "wrong line");
		assert_true(string_pos("s.missing", string(_error[$ "lineString"])) > 0, "wrong line text");
	});
	
	addFact("A syntax error names the line [GMLC]", function() {
		var _error = gmlc_pipeline_error("var a = 1;\nvar b = (;\n");
		assert_equals(_error[$ "line"], 2, "wrong line");
	});
	
	addFact("A resolver error names the line [GMLC]", function() {
		var _error = gmlc_pipeline_error("var a = 1;\n\nc_red = 2;");
		assert_equals(_error[$ "line"], 3, "wrong line");
	});
	
	addFact("An error in code from a macro names the line of the macro's use [GMLC]", function() {
		var _error = gmlc_pipeline_error("#macro RP_BAD rp_s.missing\nvar rp_s = {};\nvar a = 1;\nreturn RP_BAD;");
		assert_equals(_error[$ "line"], 4, "wrong line");
		assert_true(string_pos("RP_BAD", string(_error[$ "lineString"])) > 0, "wrong line text");
	});
	
	addFact("A program compiled from JSON names the line of an error [GMLC]", function() {
		var _r = ast_json_round_trip("var s = {};\n\nreturn s.missing;");
		var _error = undefined;
		try {
			executeProgram(_r.env.compile_ast(_r.json));
		}
		catch (_e) {
			_error = _e;
		}
		assert_equals(_error[$ "line"], 3, "wrong line");
		assert_true(string_pos("s.missing", string(_error[$ "lineString"])) > 0, "wrong line text");
	});
	
	addFact("Updating a missing struct member names the member [GMLC]", function() {
		var _message = gmlc_pipeline_message(gmlc_pipeline_error("var s = {};\ns.missing += 1;"));
		assert_true(string_pos("missing", _message) > 0, $"unexpected error: {_message}");
		assert_true(string_pos("_rootNode", _message) == 0, $"unexpected error: {_message}");
	});
	#endregion
	
	#region Parser limits
	addFact("A long chain of prefix minus is refused, not a crash [GMLC]", function() {
		var _source = "return " + string_repeat("- ", 400) + "1;";
		var _message = gmlc_pipeline_message(gmlc_pipeline_error(_source));
		assert_true(string_pos("GMLC1030", _message) > 0, $"unexpected error: {_message}");
	});
	
	addFact("A long chain of ! is refused, not a crash [GMLC]", function() {
		var _source = "return " + string_repeat("!", 400) + "1;";
		var _message = gmlc_pipeline_message(gmlc_pipeline_error(_source));
		assert_true(string_pos("GMLC1030", _message) > 0, $"unexpected error: {_message}");
	});
	
	addFact("A long chain of ternaries is refused, not a crash [GMLC]", function() {
		var _source = "return " + string_repeat("false ? 0 : ", 300) + "1;";
		var _message = gmlc_pipeline_message(gmlc_pipeline_error(_source));
		assert_true(string_pos("GMLC1030", _message) > 0, $"unexpected error: {_message}");
	});
	#endregion
	
	#region Origins and pragmas
	addFact("A node made by one macro use has that origin [GMLC]", function() {
		var _r = ast_json_round_trip("#macro RP_TWO 1 + 1\nreturn RP_TWO;");
		var _binary = gmlc_pipeline_nodes(_r.tree, __GMLC_NodeKind_Binary)[0];
		assert_equals(_binary.origin.name, "RP_TWO", "wrong origin");
	});
	
	addFact("A node spanning two uses of an inner macro does not take the inner macro as its origin [GMLC]", function() {
		var _r = ast_json_round_trip("#macro RP_ONE 1\n#macro RP_SUM RP_ONE + RP_ONE\nreturn RP_SUM;");
		var _binary = gmlc_pipeline_nodes(_r.tree, __GMLC_NodeKind_Binary)[0];
		assert_true((_binary.origin == undefined) || (_binary.origin.name != "RP_ONE"), "the + took the inner macro as its origin");
	});
	
	addFact("An enum reference keeps its text, other literals keep theirs [GMLC]", function() {
		var _r = ast_json_round_trip("enum RpE { A = 3, B = 1 + 1 }\nreturn [RpE.A, RpE.B, 7];", "lowered");
		var _literals = gmlc_pipeline_nodes(_r.tree, __GMLC_NodeKind_Literal);
		var _texts = "";
		var _i = 0; repeat (array_length(_literals)) {
			_texts += _literals[_i].lexeme + ",";
		_i++}
		assert_equals(_texts, "RpE.A,RpE.B,7,", "wrong literal texts");
	});
	
	addFact("A @NoOp pragma targets the next statement, and none at the end of a block [GMLC]", function() {
		var _r = ast_json_round_trip("var a = 1;\n// @NoOp\na = 2;\nif (a) {\n\ta = 3;\n\t// @NoOp\n}\n");
		var _pragmas = _r.tree.pragmas;
		assert_equals(array_length(_pragmas), 2, "wrong number of pragmas");
		assert_equals(_pragmas[0].target.start, _r.tree.body[1].span.start, "the first pragma does not target `a = 2;`");
		assert_equals(_pragmas[1].target, undefined, "the pragma at the end of a block targets something");
	});
	
	addFact("A @NoOp pragma covers the whole next line and no more [GMLC]", function() {
		var _r = ast_json_round_trip("var a = 1, b = 0, c = 0;\n// @NoOp\na = 2; b = 3;\nc = 4;\n");
		var _target = _r.tree.pragmas[0].target;
		assert_equals(_target.start, _r.tree.body[1].span.start, "the target does not start at `a = 2;`");
		assert_equals(_target[$ "end"], _r.tree.body[2].span[$ "end"], "the target does not end with `b = 3;`");
		assert_true(_r.tree.body[3].span.start >= _target[$ "end"], "the target reaches the line after");
	});
	
	addFact("A @NoOp pragma above a function covers its whole body [GMLC]", function() {
		var _r = ast_json_round_trip("// @NoOp\nfunction rp_noop_f() {\n\tvar x1 = 1 + 1;\n\treturn x1;\n}\nvar after = 1;\n");
		var _target = _r.tree.pragmas[0].target;
		var _function = _r.tree.body[0];
		assert_equals(_target.start, _function.span.start, "the target does not start at the function");
		assert_equals(_target[$ "end"], _function.span[$ "end"], "the target does not cover the function's body");
	});
	
	addFact("gml_pragma(\"@NoOp\") as a statement is the @NoOp pragma and leaves no call [GMLC]", function() {
		var _r = ast_json_round_trip("var a = 1;\ngml_pragma(\"@NoOp\");\na = 2; a = 3;\na = 4;\n");
		var _pragmas = _r.tree.pragmas;
		assert_equals(array_length(_pragmas), 1, "the statement did not become one pragma");
		assert_equals(array_length(_r.tree.body), 4, "the call was kept as a statement");
		assert_equals(_pragmas[0].target.start, _r.tree.body[1].span.start, "the pragma does not target the next line");
		assert_equals(_pragmas[0].target[$ "end"], _r.tree.body[2].span[$ "end"], "the pragma does not cover the whole next line");
	});
	
	addFact("gml_pragma(\"@NoOp\") as the body of an if, or another gml_pragma, stays a call [GMLC]", function() {
		var _r = ast_json_round_trip("var a = 1;\nif (a) gml_pragma(\"@NoOp\");\ngml_pragma(\"forceinline\");\n");
		assert_equals(array_length(_r.tree.pragmas), 0, "a pragma was made");
		assert_equals(array_length(_r.tree.body), 3, "a statement was lost");
	});
	
	addFact("An enum value never runs a function the host put in place of a foldable built-in [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		var _calls = { n: 0 };
		_env.exposeFunctions({ floor: method(_calls, function(_x) { n++; return 7; }) });
		var _codes = gmlc_pipeline_codes(_env.check("enum GmlcFoldOv { A = floor(1.5) }\nvar a = GmlcFoldOv.A;", "fold.gml"));
		assert_equals(_codes + ":" + string(_calls.n), "GMLC0316:0", "the host's function ran while compiling");
	});

	addFact("The optimizer never runs a function the host put in place of a foldable built-in [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		_env.should_optimize = true;
		var _calls = { n: 0 };
		_env.exposeFunctions({ floor: method(_calls, function(_x) { n++; return 7; }) });
		var _program = _env.compile("return floor(1.5);", "fold.gml");
		var _compiled = _calls.n;
		var _result = executeProgram(_program);
		assert_equals(string(_compiled) + ":" + string(_result), "0:7", "the host's function ran while compiling, or was not called");
	});

	addFact("The optimizer still folds GameMaker's own foldable built-in [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		_env.should_optimize = true;
		assert_equals(executeProgram(_env.compile("return floor(1.5) + sqr(3);", "fold.gml")), 10, "the fold changed the result");
	});

	addFact("The optimizer folds a string built-in through compile [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		_env.should_optimize = true;
		assert_equals(executeProgram(_env.compile("return string_upper(\"ab\") + string(string_length(\"abc\"));", "fold.gml")), "AB3", "the fold changed the result");
	});
	
	addFact("A child slot's parent is the node that holds the child [GMLC]", function() {
		var _node = new ASTReturn(undefined, new ASTLiteral(undefined, "real", "1", 1));
		var _slots = _node.childSlots();
		assert_true((array_length(_slots) == 1) && (_slots[0].parent == _node), "the slot's parent is not the node");
	});
	
	addFact("_GMFUNCTION_: a script's own code outside functions is gml_GlobalScript_<script>, as GameMaker names it [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		assert_equals(executeProgram(_env.compile("return _GMFUNCTION_;", "Script1.gml")), "gml_GlobalScript_Script1", "GameMaker gives another name");
	});
	
	addFact("GameMaker's project JSON reads with its trailing commas, commas in strings kept [GMLC]", function() {
		var _value = __gmlc_json_parse_loose(@'{"a":[1,2,],"b":{"c":"x, ]",},}');
		assert_equals(json_stringify(_value), json_stringify({ a: [1, 2], b: { c: "x, ]" } }), "the project JSON was read wrong");
	});
	
	addFact("Files of a folder are found without a library, in order [GMLC]", function() {
		var _dir = game_save_id + "gmlc_find_files/";
		directory_create(_dir + "inner");
		var _paths = [_dir + "b.gml", _dir + "a.gml", _dir + "c.txt", _dir + "inner/d.gml"];
		var _i = 0; repeat (array_length(_paths)) {
			var _buffer = buffer_create(1, buffer_fixed, 1);
			buffer_write(_buffer, buffer_u8, 32);
			buffer_save(_buffer, _paths[_i]);
			buffer_delete(_buffer);
		_i++}
		var _flat = __gmlc_find_files(_dir, "gml");
		var _deep = __gmlc_find_files(_dir, "gml", true);
		var _names = function(_list) {
			var _out = [];
			var _j = 0; repeat (array_length(_list)) { array_push(_out, filename_name(_list[_j])); _j++ }
			return string_join_ext(",", _out);
		};
		assert_equals(_names(_flat) + "|" + _names(_deep), "a.gml,b.gml|a.gml,b.gml,d.gml", "the files found are wrong");
	});
	
	addFact("__gmlc_json_save and __gmlc_json_load give back the value; a missing or broken file loads as undefined [GMLC]", function() {
		var _path = game_save_id + "gmlc_json_load.json";
		__gmlc_json_save(_path, { a: [1, 2], b: "x" });
		var _value = __gmlc_json_load(_path);
		__gmlc_file_write_text(_path, "{ not json");
		var _broken = __gmlc_json_load(_path);
		file_delete(_path);
		assert_equals(json_stringify(_value), json_stringify({ a: [1, 2], b: "x" }), "the loaded value differs");
		assert_equals(_broken, undefined, "a broken file should load as undefined");
		assert_equals(__gmlc_json_load(_path), undefined, "a missing file should load as undefined");
	});
	
	addFact("_GMFUNCTION_: an object event's own code is gml_Object_<object>_<event>, as GameMaker names it [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		assert_equals(executeProgram(_env.compile("return _GMFUNCTION_;", "objects/Object1/Create_0.gml", "event")), "gml_Object_Object1_Create_0", "GameMaker gives another name");
	});
	
	addFact("_GMFUNCTION_: a global function is gml_Script_<name>, as GameMaker names it [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		assert_equals(executeProgram(_env.compile("function gml_gf_a() { return _GMFUNCTION_; }\nreturn gml_gf_a();", "scr_names.gml")), "gml_Script_gml_gf_a", "GameMaker gives another name");
	});
	
	addFact("_GMFUNCTION_: a function declared in a constructor is <name>@<constructor>@<script>, as GameMaker names it [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		assert_equals(executeProgram(_env.compile("function GmlGfD() constructor { function step() { return _GMFUNCTION_; } }\nreturn new GmlGfD().step();", "scr_names.gml")), "gml_Script_step@GmlGfD@scr_names", "GameMaker gives another name");
	});
	
	addFact("_GMFUNCTION_: a function expression is anon@<offset>@<outer>@<script>, as GameMaker names it [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		assert_equals(executeProgram(_env.compile("function gml_gf_b() { var f = function() { return _GMFUNCTION_; }; return f(); }\nreturn gml_gf_b();", "scr_names.gml")), "gml_Script_anon@30@gml_gf_b@scr_names", "GameMaker gives another name");
	});
	
	addFact("_GMFUNCTION_: a struct literal's method adds ___struct___<n>, as GameMaker names it [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		assert_equals(executeProgram(_env.compile("function gml_gf_s() { var s = { m: function() { return _GMFUNCTION_; } }; return s.m(); }\nreturn gml_gf_s();", "scr_names.gml")), "gml_Script_anon@35@___struct___0@gml_gf_s@scr_names", "GameMaker gives another name");
	});
	
	addFact("_GMFUNCTION_: a static's function starts with the static's name, as GameMaker names it [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		assert_equals(executeProgram(_env.compile("function GmlGfE() constructor { static m = function() { return _GMFUNCTION_; }; }\nreturn new GmlGfE().m();", "scr_names.gml")), "gml_Script_m@anon@43@GmlGfE@scr_names", "GameMaker gives another name");
	});
	
	addFact("_GMFUNCTION_: a function declared in a function is <name>@<outer>@<script>, as GameMaker names it [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		assert_equals(executeProgram(_env.compile("function gml_gf_f() { function gml_gf_g() { return _GMFUNCTION_; } return gml_gf_g(); }\nreturn gml_gf_f();", "scr_names.gml")), "gml_Script_gml_gf_g@gml_gf_f@scr_names", "GameMaker gives another name");
	});
	
	addFact("A static at the top of an object event is GMLC2007, as at the top of a script [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		assert_equals(gmlc_pipeline_codes(_env.check("static fx_hits = 0;", "Create_0.gml", "event")), "GMLC2007", "the event's static was accepted");
	});

	addFact("A parser warning reaches the diagnostics of a check: a second default is GMLC1008 [GMLC]", function() {
		assert_equals(gmlc_pipeline_check("var n = 1;\nswitch (n) {\n\tdefault: break;\n\tdefault: break;\n}"), "GMLC1008", "the parser's warning was lost");
	});

	addFact("A parser warning reaches the diagnostics of a compile [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		_env.compile("var n = 1;\nswitch (n) {\n\tdefault: break;\n\tdefault: break;\n}", "warn.gml");
		assert_equals(gmlc_pipeline_codes(_env.diagnostics), "GMLC1008", "the parser's warning was lost");
	});

	addFact("A program with gml_pragma(\"@NoOp\") runs as if it were not there [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		var _result = executeProgram(_env.compile("var a = 1;\ngml_pragma(\"@NoOp\");\na += 2;\nreturn a;", "noop.gml"));
		assert_equals(_result, 3, "the program gave a wrong result");
	});
	
	addFact("var static is a static whose value lasts between calls, as in GameMaker [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		var _result = executeProgram(_env.compile("var f = function() { var static n = 0; n += 1; return n; };\nf();\nreturn f();", "var-static.gml"));
		assert_equals(_result, 2, "the static was reset between calls");
	});
	#endregion
	
	#region Diagnostics
	addFact("check reports warnings without compiling [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		var _list = _env.check("var a = 1;\nvar a = 2;\nreturn a;", "check.gml");
		assert_equals(array_length(_list), 1, "wrong number of diagnostics");
		assert_equals(_list[0].code, "GMLC2005", "wrong code");
		assert_equals(_list[0].severity, "warning", "wrong severity");
		assert_equals(_env.sources.position(_list[0].span).line, 2, "wrong line");
	});
	
	addFact("A compile keeps its warnings and returns the program [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		var _program = _env.compile("var a = 1;\nvar a = 2;\nreturn a;");
		assert_equals(executeProgram(_program), 2, "the program did not run");
		assert_equals(gmlc_pipeline_codes(_env.diagnostics), "GMLC2005", "the warning was not kept");
	});
	
	addFact("Constants that fail when they run are compile errors, and warnings in test mode [GMLC]", function() {
		// "error GMLC...", "warning GMLC..." or "" for each source
		var _codes = function(_src, _optimize, _testMode = false) {
			var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL).enable_test_mode(_testMode);
			_env.should_optimize = _optimize;
			try {
				_env.compile(_src);
			}
			catch (_e) {
				return "error " + gmlc_pipeline_codes(_e[$ "diagnostics"]);
			}
			var _found = gmlc_pipeline_codes(_env.diagnostics);
			return (_found == "") ? "" : "warning " + _found;
		};
		assert_equals(_codes("return real(\"ab\");", false), "error GMLC4102", "real of a word throws when it runs");
		assert_equals(_codes("return \"ab\" * 2;", true), "error GMLC4102", "a string times a number throws when it runs");
		assert_equals(_codes("return -3 * \"ab\";", false), "error GMLC4101", "a negative string repeat ends the game");
		assert_equals(_codes("return 1 + (int64(1) div 0);", false), "error GMLC4102", "only the failing operator is reported");
		assert_equals(_codes("return chr(65.5);", false), "error GMLC4103", "a character code with a fraction");
		assert_equals(_codes("return ansi_char(256);", false), "error GMLC4103", "a character code out of range");
		assert_equals(_codes("return chr(66);", false), "", "a whole character code folds");
		assert_equals(_codes("return false && real(\"ab\");", false), "", "&& does not run its right side here");
		assert_equals(_codes("return true ? 1 : real(\"ab\");", true), "", "a branch the ternary does not take");
		assert_equals(_codes("if (false) return real(\"ab\");", false), "error GMLC4102", "dead code, without the optimizer");
		assert_equals(_codes("if (false) return real(\"ab\");", true), "error GMLC4102", "dead code, with the optimizer");
		assert_equals(_codes("// @NoOp\nreturn real(\"ab\");", false), "", "a @NoOp line is left alone");
		assert_equals(_codes("return real(\"ab\");", false, true), "warning GMLC4102", "test mode");
		assert_equals(_codes("return -3 * \"ab\";", true, true), "warning GMLC4101", "test mode, with the optimizer");
		assert_equals(_codes("return chr(65.5);", false, true), "warning GMLC4103", "test mode, a character code");
	});
	
	addFact("A constructor called directly throws GameMaker's error; a parent call and script_execute still run [GMLC]", function() {
		var _run = function(_src) {
			try {
				return executeProgram(new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL).compile(_src));
			}
			catch (_e) {
				return "error:" + (is_struct(_e) ? _e.message : string(_e));
			}
		};
		var _direct = "error:calling a constructor directly - constructors should only be called using new";
		var _decl = "function CtorRuleC(_n) constructor { n = _n; }\n";
		assert_equals(_run(_decl + "var h = {}; with (h) CtorRuleC(4); return 1;"), _direct, "a direct call");
		assert_equals(_run(_decl + "var b = method({}, CtorRuleC); b(4); return 1;"), _direct, "a bound constructor called directly");
		assert_equals(_run(_decl + "var s = { make: CtorRuleC }; s.make(4); return 1;"), _direct, "a constructor called as a method");
		assert_equals(_run(_decl + "var h = {}; with (h) script_execute(CtorRuleC, 4); return h.n;"), 4, "script_execute runs the body on self");
		assert_equals(_run("function CtorRuleP() constructor { a = 1; }\nfunction CtorRuleQ() : CtorRuleP() constructor { b = 2; }\nvar q = new CtorRuleQ(); return q.a + q.b;"), 3, "a parent constructor call");
		// a caught error leaves the call able to run again
		assert_equals(_run(_decl + "var r = 0; repeat (2) { try { CtorRuleC(1); } catch (_e) { r++; } } return r;"), 2, "the call after a caught error");
	});

	addFact("Test mode leaves a failing constant to fail when it runs [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL).enable_test_mode(true);
		var _program = _env.compile("try { return real(\"ab\"); } catch (_e) { return \"caught\"; }");
		assert_equals(executeProgram(_program), "caught", "the error was not thrown when the code ran");
		var _program = _env.compile("return chr(65.9);");
		assert_equals(executeProgram(_program), "A", "chr did not run as GameMaker's runtime runs it (it cuts the fraction)");
	});

	addFact("Constant folding runs in every compile and gives the runtime's result [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		_env.__log_optimizer_results = false;
		var _program = _env.compile("return [!0, 5 & 3, \"ab\" + \"cd\", 3 * \"ab\", undefined ?? 4, 167 != NaN];");
		var _r = executeProgram(_program);
		assert_equals(typeof(_r[0]) + typeof(_r[1]), "boolint64", "the folded types are not the runtime's");
		assert_equals(_r[2] + _r[3], "abcdababab", "strings did not fold");
		assert_equals(_r[4], 4, "?? did not fold");
		assert_equals(_r[5], true, "x != NaN is true at run time");
	});

	addFact("An error carries every diagnostic of the compile [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		var _error = undefined;
		try {
			_env.compile("var a = 1;\nvar a = 2;\nc_red = 1;\nabs = 2;");
		}
		catch (_e) {
			_error = _e;
		}
		assert_equals(gmlc_pipeline_codes(_error[$ "diagnostics"]), "GMLC2005,GMLC2201,GMLC2204", "wrong diagnostics");
		assert_equals(_error.line, 3, "the error is not the first one");
	});
	
	addFact("A file of a batch that fails does not stop the others [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		var _result = _env.compile_batch([
			{ name: "rp_iso_a.gml", source: "function rp_iso_a() { return 1; }" },
			{ name: "rp_iso_b.gml", source: "function rp_iso_b() {\n\treturn (;\n}" },
			{ name: "rp_iso_c.gml", source: "function rp_iso_c() { return 3; }" },
		]);
		var _entries = _result.entries;
		assert_equals(string(_entries[0].success) + string(_entries[1].success) + string(_entries[2].success), "101", "wrong successes");
		assert_equals(_entries[1].error.line, 2, "the failure has no position");
		assert_equals(executeProgram(variable_global_get("rp_iso_c")), 3, "the file after the failure was not compiled");
	});
	
	addFact("The text form names the place and marks it [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		// call arguments are evaluated right to left: check first, then read its sources
		var _list = _env.check("var a = 1;\nvar a = 2;", "text.gml");
		var _text = GMLC_DiagnosticsToText(_list, _env.sources);
		assert_true(string_pos("warning[GMLC2005]: a is already declared with var in this function", _text) > 0, _text);
		assert_true(string_pos("text.gml:2:5", _text) > 0, _text);
		assert_true(string_pos("    ^", _text) > 0, _text);
		assert_true(string_pos("Feather GM2044", _text) > 0, _text);
	});
	
	addFact("The JSON form is the diagnostics stage [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		var _list = _env.check("var a = 1;\nvar a = 2;", "json.gml");
		var _json = GMLC_DiagnosticsToJson(_list, _env.sources);
		assert_true(string_pos("\"stage\":\"diagnostics\"", _json) > 0, _json);
		assert_true(string_pos("{\"code\":\"GMLC2005\",\"feather_code\":\"GM2044\",\"severity\":\"warning\"", _json) > 0, _json);
	});
	
	addFact("A message argument that looks like a placeholder is kept as written [GMLC]", function() {
		var _d = new GMLC_Diagnostic("GMLC1002", new GMLC_Span(0, 0, 0), ["{1}", "x"]);
		assert_equals(GMLC_DiagnosticMessage(_d), "expected {1}, found x", "wrong message");
	});
	
	addFact("An unclosed bracket is labelled where it opens [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		var _list = _env.check("var a = [1, 2;");
		assert_equals(_list[0].code, "GMLC1016", "wrong code");
		_list = _env.check("var a = [1, 2");
		assert_equals(_list[0].code, "GMLC1002", "wrong code");
		assert_equals(_list[0].labels[0].span.start, 8, "the label is not at the [");
	});
	
	addFact("Warnings for what GameMaker compiles but likely is a mistake [GMLC]", function() {
		assert_equals(gmlc_pipeline_check("function rp_w1(a = 1, b) { return b; }"), "GMLC2008", "optional before required");
		assert_equals(gmlc_pipeline_check("function rp_w2(a) { return argument0 + a; }"), "GMLC2009", "argument with parameters");
		assert_equals(gmlc_pipeline_check("return argument0;"), "GMLC2010", "argument outside a function");
		assert_equals(gmlc_pipeline_check("function rp_w3() { rp_late = 1; var rp_late = 2; return rp_late; }"), "GMLC2102", "used before var");
		assert_equals(gmlc_pipeline_check("function rp_w4() {}\nvar s = new rp_w4();"), "GMLC2108", "new on a function");
		assert_equals(gmlc_pipeline_check("function RpW5() constructor {}\nvar s = RpW5();"), "GMLC2109", "constructor without new");
		assert_equals(gmlc_pipeline_check("function rp_w6() { var k = 3; var f = function() { return k; }; return f(); }"), "GMLC2110", "enclosing local");
		assert_equals(gmlc_pipeline_check("function rp_w7() { var t = 5; static s = t; return s; }"), "GMLC2301", "static reads a local");
		assert_equals(gmlc_pipeline_check("static s = 1;"), "GMLC2007", "static outside a function");
		assert_equals(gmlc_pipeline_check("function rp_w8() {}\nfunction rp_w8() {}"), "GMLC2015", "a function declared twice");
	});
	
	addFact("A function bound by method to a struct literal reads the struct's keys without GMLC2110 [GMLC]", function() {
		assert_equals(gmlc_pipeline_check("function rp_m1() { var k = 3; var f = method({ k: k }, function() { return k; }); return f(); }"), "", "a bound key warned");
		assert_equals(gmlc_pipeline_check("function rp_m2() { var k = 3; var f = method({ k }, function() { return k; }); return f(); }"), "", "a shorthand key warned");
		assert_equals(gmlc_pipeline_check("function rp_m3() { var k = 3, j = 4; var f = method({ k: k }, function() { return j; }); return f(); }"), "GMLC2110", "a key the struct lacks did not warn");
		assert_equals(gmlc_pipeline_check("function rp_m4() { var k = 3; var f = method({ k: k }, function() { return function() { return k; }; }); return f(); }"), "GMLC2110", "a function nested in the bound one did not warn");
	});

	addFact("A function declared at the top of an object event is a method of the instance, not a global [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		var _holder = {};
		var _program = _env.compile("function rp_ev_step() { return 5; }\nreturn rp_ev_step();", "obj_rp::Step_0.gml", "event");
		var _result = method(_holder, executeProgram)(_program);
		assert_equals(_result, 5, "the event's function did not run");
	});
	
	addFact("Two object events may declare functions of the same name without GMLC2015, two scripts may not [GMLC]", function() {
		var _env = new GMLC_Env().set_exposure(GMLC_EXPOSURE.FULL);
		var _events = _env.__compile_units([
			{ source: "function rp_ev_dup() { return 1; }", name: "obj_a::Step_0.gml", kind: "event" },
			{ source: "function rp_ev_dup() { return 2; }", name: "obj_b::Step_0.gml", kind: "event" },
		], undefined);
		var _scripts = _env.__compile_units([
			{ source: "function rp_sc_dup() { return 1; }", name: "scr_a" },
			{ source: "function rp_sc_dup() { return 2; }", name: "scr_b" },
		], undefined);
		var _eventCodes = gmlc_pipeline_codes(_events.entries[0].diagnostics) + gmlc_pipeline_codes(_events.entries[1].diagnostics);
		var _scriptCodes = gmlc_pipeline_codes(_scripts.entries[0].diagnostics) + gmlc_pipeline_codes(_scripts.entries[1].diagnostics);
		assert_equals(_eventCodes, "", "the events' functions were taken for globals");
		assert_true(string_pos("GMLC2015", _scriptCodes) > 0, "two scripts declaring one function were accepted");
	});
	
	addFact("Errors for what GameMaker refuses [GMLC]", function() {
		assert_equals(gmlc_pipeline_check("function rp_e1(a, a) { return a; }"), "GMLC2001", "duplicate parameter");
		assert_equals(gmlc_pipeline_check("var sprite_get_width = 1;"), "GMLC2003", "var named like a built-in function");
		assert_equals(gmlc_pipeline_check("enum RpE1 { A }\nvar v = RpE1;"), "GMLC2101", "bare enum");
		assert_equals(gmlc_pipeline_check("function rp_e2() {}\nfunction RpE3() : rp_e2() constructor {}"), "GMLC2107", "parent not a constructor");
		assert_equals(gmlc_pipeline_check("instance_count = 0;"), "GMLC2202", "read-only variable");
		assert_equals(gmlc_pipeline_check("return string_length();"), "GMLC3003", "too few arguments");
		assert_equals(gmlc_pipeline_check("return string_length(\"a\", \"b\");"), "GMLC3002", "too many arguments");
		assert_equals(gmlc_pipeline_check("return max();"), "", "a function of any number of arguments");
		assert_equals(gmlc_pipeline_check("function abs() { return 1; }"), "GMLC2011", "a function named like a built-in");
	});
	#endregion
	
	#region Lowering
	addFact("The function table of the lowering design's worked example [GMLC]", function() {
		var _ast = gmlc_pipeline_lowered("function Button(_label) constructor {\n    label = _label;\n    static padding = 4;\n    on_click = function() { show_debug_message(_GMLINE_); };\n}\n");
		var _f = _ast.functions;
		assert_equals(array_length(_f), 3, "wrong number of functions");
		assert_equals(gmlc_pipeline_info(_f[0]), "unit_body none none undefined | 1 1", "the file's body");
		assert_equals(gmlc_pipeline_info(_f[1]), "constructor global none 0 | 3 12", "Button");
		assert_equals(gmlc_pipeline_info(_f[2]), "method value creator_self 1 | 1 4", "on_click");
		assert_equals(_f[1].statics[0], "padding", "the static was not listed");
		assert_true(_f[1].facts.has_statics && _f[1].facts.has_nested_functions, "Button's facts");
		assert_true(_f[0].facts.has_nested_functions, "the body's facts");
	});
	
	addFact("Where a function is declared decides its binding [GMLC]", function() {
		var _ast = gmlc_pipeline_lowered(@'
			function rp_b1() {
				function rp_b2() {}
				var g = function() {};
				var s = { m: function() {} };
				static st = function() {};
			}
			var top = function() {};
			var V = function() constructor {};
		');
		var _f = _ast.functions;
		assert_equals(gmlc_pipeline_kind(_f[1]), "script_function global none", "a top-level function");
		assert_equals(gmlc_pipeline_kind(_f[2]), "method instance creator_self", "a function declared in a function");
		assert_equals(gmlc_pipeline_kind(_f[3]), "method value creator_self", "a function expression in a function");
		assert_equals(gmlc_pipeline_kind(_f[4]), "method value new_struct", "a struct literal's function");
		assert_equals(gmlc_pipeline_kind(_f[5]), "method value none", "a static function");
		assert_equals(gmlc_pipeline_kind(_f[6]), "method value none", "a function expression in the file's body");
		assert_equals(gmlc_pipeline_kind(_f[7]), "constructor value none", "a constructor expression");
	});
	
	addFact("The facts of a function's body [GMLC]", function() {
		var _ast = gmlc_pipeline_lowered(@'
			function rp_f1(a) {
				with (other) { exit; }
				try { throw argument[0]; } catch (e) {}
				if (argument_count > 2) return argument2;
				return rp_f1(a - 1);
			}
		');
		var _facts = _ast.functions[1].facts;
		assert_true(_facts.contains_with && _facts.contains_exit && _facts.contains_try, "with, exit, try");
		assert_true(_facts.reads_other && _facts.uses_argument_array && _facts.uses_argument_count, "other, argument, argument_count");
		assert_equals(_facts.max_argument_index, 2, "argument2");
		assert_true(_facts.direct_recursion, "the call of itself");
		assert_false(_facts.single_trailing_return, "two returns");
		_ast = gmlc_pipeline_lowered("function rp_f2(a) { var b = a + 1; return b; }");
		assert_true(_ast.functions[1].facts.single_trailing_return, "one return, last");
	});
	
	addFact("Lowering keeps a function's parameters and locals apart [GMLC]", function() {
		var _ast = gmlc_pipeline_lowered("function rp_l1(a, b) { var c = 1; try {} catch (e) {} return a + b + c; }");
		var _info = _ast.functions[1];
		assert_equals(string(_info.params) + string(_info.locals), "[ \"a\",\"b\" ][ \"c\",\"e\" ]", "wrong slots");
		assert_equals(compile_and_execute("function rp_l2(a, b) { var c = 1; return a + b + c; }\nreturn rp_l2(1, 2);"), 4, "the slots do not run");
	});
	#endregion
}
