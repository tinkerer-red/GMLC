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

function GmlcPipelineTestSuite() : TestSuite() constructor {
	
	#region Names in a file
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
		var _r = ast_json_round_trip("enum RpE { A = 3, B = 1 + 1 }\nreturn [RpE.A, RpE.B, 7];");
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
	#endregion
}
