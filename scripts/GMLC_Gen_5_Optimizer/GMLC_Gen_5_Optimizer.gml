enum GMLC_OPTIMIZE {
	ALL,
	FOLD,
	CONSTANT, // an enum member's value: every fold is taken
}

#region jsDoc
/// @func    GMLC_Gen_5_Optimizer(_env)
/// @desc    Optimizer stage: refines the AST for faster execution. `initialize(ast, sources)` then `parseAll()`
///          returns the optimized tree. Folds constants in every compile; with should_optimize it also runs the
///          scheduled passes in schedule order.
/// @param   {Struct.GMLC_Env} _env : The environment
/// @returns {Struct.GMLC_Gen_5_Optimizer}
#endregion
function GMLC_Gen_5_Optimizer(_env) constructor  {
	#region Init
	env = _env;
	
	//init variables:
	
	ast = undefined;
	sources = undefined;
	no_op_targets = [];
	has_no_op_targets = false;
	has_int64 = false; // the file holds an int64 YYC knows while compiling: passes are checked against the YYC int64 rule
	__constant_propagate_constants = {}; // constant-propagate: the locals of the list it sweeps that a literal sets (the YYC operand rule)
	optimization_occured = false; //used so all optimizers can register if a change has occured and we should re attempt optimizers
	mode = GMLC_OPTIMIZE.ALL;
	back_end = "gml"; // the back end the tree goes to: "gml" (the GML text emitter; "gml-vm" when env.emit_for_vm) or "runtime" (the closure compiler)
	diagnostics = [];
	passes = [];
	fixpoint_cap = 8;
	schedule_cap = 4; // the whole schedule repeats until a run changes nothing, at most this many runs
	folds_constants = false;
	registry = {}; // passes that take the place of the known passes of the same name
	steps = [];
	statistics = undefined;
	preserve_lines = false;
	epsilon_set = false; // comparisons of reals are not folded
	__records = [];
	__undo = [];
	__notes = [];
	__local_types_set = false; // whether the types of the file's locals were found this run (__gmlc_opt_set_local_types)
	__pass_cx = undefined; // the context every pass application gets (__apply)
	__temporary_next = {};
	__temporaries_made = {};
	__temporary_names = {}; // the temporary names the files of `__temporary_names_sources` use (__temporaryTaken)
	__temporary_names_sources = undefined;
	__temporary_names_count = 0;
	__enum_values = false; // an enum member's value is never printed: any real is kept
	__failing = [];
	var _registry = __gmlc_optimizer_pass_registry();
	__fold = _registry[$ "constant-fold"].sweep; // the folding sweep, also used by the walks that fold alone
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    initialize(_ast, [_sources])
	/// @desc    Takes one file's lowered tree: collects its `@NoOp` targets (a function frozen by
	///          `gml_pragma` leaves the functions inside it free), reports math_set_epsilon uses and builds the pass
	///          schedule.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTScript}        _ast       : The lowered tree
	/// @param   {Struct.GMLC_SourceTable} [_sources] : The compile's files
	#endregion
	static initialize = function(_ast, _sources = undefined) {
		ast = _ast;
		sources = _sources;
		diagnostics = [];
		__failing = [];
		no_op_targets = [];
		var _units = undefined;
		var _i = 0; repeat (array_length(_ast.pragmas)) {
			var _pragma = _ast.pragmas[_i];
			var _target = _pragma.target;
			if (_target != undefined) {
				// a `gml_pragma` stands inside the function it freezes, whose own functions stay free
				var _holes = [];
				if (_pragma.span.start >= _target.start) && (_pragma.span.start < _target[$ "end"]) {
					_units ??= __units();
					var _u = 1; repeat (array_length(_units) - 1) {
						var _s = _units[_u].root.span;
						if (_s != undefined) && (_s.file == _target.file) && (_s.start >= _target.start) && (_s[$ "end"] <= _target[$ "end"])
						&& ((_s.start != _target.start) || (_s[$ "end"] != _target[$ "end"])) {
							array_push(_holes, _s);
						}
					_u++}
				}
				array_push(no_op_targets, { target: _target, holes: _holes });
			}
		_i++}
		has_no_op_targets = (array_length(no_op_targets) > 0);
		has_int64 = __gmlc_opt_has_static_int64(_ast);
		preserve_lines = env.preserve_lines;
		statistics = undefined;
		__temporary_next = {};
		__temporaries_made = {};
		var _calls = [];
		__epsilonCalls(_ast, _calls);
		_i = 0; repeat (array_length(_calls)) {
			array_push(diagnostics, new GMLC_Diagnostic("GMLC4004", _calls[_i].span));
		_i++}
		epsilon_set = (array_length(_calls) > 0) || env.__batch_epsilon;
		__schedulePasses();
	};
	
	#region jsDoc
	/// @func    cleanup()
	/// @desc    Nothing to release.
	/// @self    GMLC_Gen_5_Optimizer
	#endregion
	static cleanup = function() {
	
	}
	
	#region jsDoc
	/// @func    parseAll()
	/// @desc    Optimizes the tree and reports the constants that always fail.
	/// @self    GMLC_Gen_5_Optimizer
	/// @returns {Struct.ASTScript}
	#endregion
	static parseAll = function() {
		if (env.__log_optimizations) return __parseAllLogged();
		__foldGuarded(undefined);
		__reportFailing();
		return ast;
	}
	
	#region jsDoc
	/// @func    fileName()
	/// @desc    The name of the file being optimized, or "".
	/// @self    GMLC_Gen_5_Optimizer
	/// @returns {String}
	#endregion
	static fileName = function() {
		var _file = (sources != undefined) && (ast.span.file < array_length(sources.files)) ? sources.files[ast.span.file] : undefined;
		return (_file != undefined) ? _file.name : "";
	};
	
	#region jsDoc
	/// @func    newTemporary(_cx)
	/// @desc    A new temporary of the function a pass runs on: `__gmlc_t<N>` with the next provisional number of
	///          that function, added to its locals. After the schedule they are numbered again from 0 in source
	///          order.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct} _cx : The pass context
	/// @returns {String} The name
	#endregion
	static newTemporary = function(_cx) {
		var _fn = _cx.unit.fn_id;
		var _key = string(_fn);
		var _n = __temporary_next[$ _key] ?? 0;
		// a name the program already uses is never taken, nor renamed later
		while (__temporaryTaken("__gmlc_t" + string(_n))) _n++;
		__temporary_next[$ _key] = _n + 1;
		var _name = "__gmlc_t" + string(_n);
		__temporaries_made[$ _name] = true;
		array_push(_cx.new_locals, _name);
		return _name;
	};
	
	#region jsDoc
	/// @func    forgetLocal(_cx, _name)
	/// @desc    Tells the optimizer that a pass changed what a local holds: the type the facts know for that name is
	///          dropped.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct} _cx   : The pass context
	/// @param   {String} _name : The local
	#endregion
	static forgetLocal = function(_cx, _name) {
		if (!array_contains(_cx.new_locals, _name)) array_push(_cx.new_locals, _name);
	};
	
	#region jsDoc
	/// @func    foldExpression(_node, [_sources])
	/// @desc    Folds an expression whose parts are all known while compiling, for a value that exists only while
	///          compiling (an enum member's): every fold is taken. Call it between foldBegin and foldEnd, inside
	///          the caller's one try.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode}          _node      : The expression
	/// @param   {Struct.GMLC_SourceTable} [_sources] : The compile's files, for the positions of errors
	/// @returns {Struct.ASTNode}
	#endregion
	static foldExpression = function(_node, _sources = undefined) {
		var _sources0 = sources;
		var _noOp0 = has_no_op_targets;
		sources = _sources;
		has_no_op_targets = false;
		var _mode0 = mode;
		mode = GMLC_OPTIMIZE.CONSTANT;
		var _holder = new ASTExprStmt(_node.span, _node);
		var _enumValues0 = __enum_values;
		__enum_values = true;
		// an enum member's value takes the macros as they stand
		var _saved_macros = __gmlc_opt_set_opaque_macros(true, {});
		__walk(_holder);
		__gmlc_opt_set_opaque_macros(_saved_macros.folds, _saved_macros.scoped);
		__enum_values = _enumValues0;
		mode = _mode0;
		sources = _sources0;
		has_no_op_targets = _noOp0;
		return _holder.expression;
	};
	
	#region jsDoc
	/// @func    foldBegin()
	/// @desc    Call before one try around a whole run of folding: a constant whose computation throws records its
	///          node, foldCaught keeps that node as failing and the caller runs again, with what is already folded
	///          staying folded.
	/// @self    GMLC_Gen_5_Optimizer
	#endregion
	static foldBegin = function() {
		var _fold = global.__gmlc_fold;
		_fold.node = undefined;
		_fold.epsilon = false;
		_fold.failed = [];
		_fold.messages = [];
	};
	
	#region jsDoc
	/// @func    foldCaught(_e)
	/// @desc    Called in the catch of the try around folding: keeps the failing constant's node and message;
	///          an error that is not a constant's failure is thrown again.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Any} _e : The caught error
	#endregion
	static foldCaught = function(_e) {
		var _fold = global.__gmlc_fold;
		var _node = _fold.node;
		_fold.node = undefined;
		if (_node == undefined) || (__GMLCfoldFailure(_node) != undefined) throw _e;
		array_push(_fold.failed, _node);
		var _message = is_struct(_e) ? _e.message : string(_e);
		// a built-in runs through script_execute_ext, whose name GameMaker puts in its error: the call names the
		// function, as the same call in the program does
		if (_node.kind == __GMLC_NodeKind_Call) && (_node.callee.kind == __GMLC_NodeKind_Identifier)
		&& (string_starts_with(_message, "script_execute_ext")) {
			_message = _node.callee.name + string_delete(_message, 1, string_length("script_execute_ext"));
		}
		// GameMaker cuts its message to 1023 bytes, which can end inside a character: kept as valid UTF-8
		_message = __gmlc_lossy_utf8(_message);
		array_push(_fold.messages, _message);
	};
	
	#region jsDoc
	/// @func    foldEnd()
	/// @desc    Call after the run of folding: clears what foldBegin set up.
	/// @self    GMLC_Gen_5_Optimizer
	#endregion
	static foldEnd = function() {
		__enum_values = false;
		var _fold = global.__gmlc_fold;
		_fold.failed = [];
		_fold.messages = [];
	};
	#endregion
	
	#region Private
	#region Pass Schedule
	#region jsDoc
	/// @func    outputName()
	/// @desc    The output the tree goes to: GML source for YYC or the VM, or the closure compiler on the runtime that
	///          runs it.
	/// @self    GMLC_Gen_5_Optimizer
	/// @returns {String}
	#endregion
	static outputName = function() {
		if (back_end == "runtime") return code_is_compiled() ? "gml-runtime-yyc" : "gml-runtime-vm";
		return env.emit_for_vm ? "gml-source-vm" : "gml-source-yyc";
	};
	
	#region jsDoc
	/// @func    __schedulePasses()
	/// @desc    The passes of the schedule this optimizer implements, in schedule order; constant folding alone in
	///          a compile without should_optimize, and an analysis that only reports only when statistics are
	///          collected.
	/// @self    GMLC_Gen_5_Optimizer
	#endregion
	static __schedulePasses = function() {
		var _data = __GmlcDataPasses();
		fixpoint_cap = _data.fixpoint_cap;
		schedule_cap = _data.schedule_cap;
		passes = [];
		steps = [];
		__records = [];
		folds_constants = false;
		// the output's profile: GML source is built with YYC unless it is built for the VM
		var _output = outputName();
		var _profile = undefined;
		var _o = 0; repeat (array_length(_data.outputs)) {
			if (_data.outputs[_o].name == _output) _profile = _data.outputs[_o];
		_o++}
		// the catalog by name, and one counter struct every pass shares while statistics are not collected
		static __entries = undefined;
		static __uncounted = undefined;
		if (__entries == undefined) {
			__entries = {};
			__uncounted = {};
			var _p = 0; repeat (array_length(_data.passes)) {
				var _pass = _data.passes[_p];
				__entries[$ _pass.name] = _pass;
				var _k = 0; repeat (array_length(_pass.stats)) {
					__uncounted[$ _pass.stats[_k]] = 0;
				_k++}
			_p++}
		}
		var _entries = __entries;
		var _counted = env.collect_statistics;
		var _registry = __gmlc_optimizer_pass_registry();
		var _recorded = {};
		var _schedule = _data.schedule;
		var _s = 0; repeat (array_length(_schedule)) {
			var _names = _schedule[_s].passes;
			var _step = { kind: _schedule[_s].step, names: string_join_ext(",", _names), legacy: [], passes: [] };
			var _i = 0; repeat (array_length(_names)) {
				var _name = _names[_i];
				var _entry = _entries[$ _name];
				if (_entry != undefined) && ((mode == GMLC_OPTIMIZE.ALL) || (_name == "constant-fold"))
				&& ((!preserve_lines) || (_entry.preserve_lines != "disabled"))
				&& ((_entry.layer != "target") || ((_profile != undefined) && (array_contains(_profile.run, _name))))
				&& ((_profile == undefined) || (!array_contains(_profile.refuse, _name)))
				&& ((_entry.kind != "analysis") || (_counted)) {
					var _known = _registry[$ _name];
					var _run = (_known != undefined) ? _known.sweep : undefined;
					var _managed = registry[$ _name] ?? _known;
					if (_run != undefined) || (_managed != undefined) {
						var _record = _recorded[$ _name];
						if (_record == undefined) {
							var _stats = __uncounted;
							if (_counted) {
								_stats = {};
								var _k = 0; repeat (array_length(_entry.stats)) {
									_stats[$ _entry.stats[_k]] = 0;
								_k++}
							}
							_record = { name: _name, applications: 0, changed_functions: 0, stats: _stats, keys: _counted ? _entry.stats : [] };
							_recorded[$ _name] = _record;
							array_push(__records, _record);
						}
						if (_run != undefined) {
							array_push(_step.legacy, { name: _name, run: _run, record: _record });
							if (_name == "constant-fold") folds_constants = true;
						}
						else {
							array_push(_step.passes, { name: _name, run: _managed.run, granularity: _entry.granularity, record: _record });
						}
					}
				}
			_i++}
			if (array_length(_step.legacy) + array_length(_step.passes) > 0) array_push(steps, _step);
		_s++}
	};
	
	#region jsDoc
	/// @func    __runSchedule()
	/// @desc    Runs the scheduled steps in order. A `fixpoint` step repeats until no pass changes anything or
	///          fixpoint_cap rounds have run; it is skipped when the same group reached its fixed point and nothing
	///          changed since. `once` and `each` steps apply each pass once. The whole schedule runs again while a
	///          run changes anything, at most schedule_cap runs, so a later pass never leaves work for an earlier one.
	/// @self    GMLC_Gen_5_Optimizer
	#endregion
	static __runSchedule = function() {
		__notes = [];
		// the types a local holds are facts about the values it takes, which no pass changes: they are found once a
		// run (a pass's new locals are new names, of unknown type)
		__local_types_set = false;
		var _r = 0; repeat (array_length(__records)) {
			var _record = __records[_r];
			_record.applications = 0;
			_record.changed_functions = 0;
			var _k = 0; repeat (array_length(_record.keys)) {
				_record.stats[$ _record.keys[_k]] = 0;
			_k++}
		_r++}
		var _rounds = 0;
		var _reached = true;
		var _converged = undefined;
		var _runs = 0;
		var _any = false;
		do {
			// only the last run's notes stand: an earlier run that hit the cap is finished by the next one
			__notes = [];
			_reached = true;
			_any = false;
			var _s = 0; repeat (array_length(steps)) {
				var _step = steps[_s];
				if (_step.kind == "fixpoint") {
					if (_converged != _step.names) {
						var _n = 0;
						var _changed = false;
						do {
							_changed = __round(_step);
							if (_changed) _any = true;
							_n++;
						}
						until (!_changed) || (_n >= fixpoint_cap);
						_rounds += _n;
						if (_changed) {
							_reached = false;
							_converged = undefined;
							array_push(__notes, new GMLC_Diagnostic("GMLC4002", ast.span, [fileName(), string(_n)]));
						}
						else {
							_converged = _step.names;
						}
					}
				}
				else {
					var _p = 0; repeat (array_length(_step.passes)) {
						if (__apply(_step.passes[_p])) {
							_converged = undefined;
							_any = true;
						}
					_p++}
				}
			_s++}
			_runs++;
		}
		until (!_any) || (_runs >= schedule_cap);
		__renumberTemporaries();
		if (env.collect_statistics) {
			var _passes = array_create(array_length(__records));
			_r = 0; repeat (array_length(__records)) {
				var _record = __records[_r];
				_passes[_r] = { name: _record.name, applications: _record.applications, changed_functions: _record.changed_functions, stats: variable_clone(_record.stats, 0) };
			_r++}
			statistics = { unit: fileName(), rounds: _rounds, fixpoint_reached: _reached, passes: _passes };
		}
		array_copy(diagnostics, array_length(diagnostics), __notes, 0, array_length(__notes));
		__notes = [];
	};
	
	#region jsDoc
	/// @func    __round(_step)
	/// @desc    One round of a fixpoint step: the tree sweep of the built-in passes, then each managed pass.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct} _step : The step
	/// @returns {Bool} Whether anything changed
	#endregion
	static __round = function(_step) {
		var _changed = false;
		if (array_length(_step.legacy) > 0) {
			passes = _step.legacy;
			optimization_occured = false;
			ast = __visit(ast, undefined);
			var _l = 0; repeat (array_length(passes)) {
				passes[_l].record.applications++;
			_l++}
			if (optimization_occured) {
				_changed = true;
				// what the sweep removed leaves empty statements and blocks inside blocks
				var _units = __units();
				var _u = 0; repeat (array_length(_units)) {
					__tidy(_units[_u].root);
				_u++}
				__gmlc_opt_refresh_argument_facts(ast);
			}
		}
		var _p = 0; repeat (array_length(_step.passes)) {
			if (__apply(_step.passes[_p])) _changed = true;
		_p++}
		return _changed;
	};
	
	#region jsDoc
	/// @func    __apply(_pass)
	/// @desc    Applies a managed pass to every function of the file, each on its own: a pass that throws leaves
	///          that function as it was, and with lines preserved a result that prints code above its line is
	///          undone. A constant that fails while computed still restarts the run.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct} _pass : {name, run, granularity, record}
	/// @returns {Bool} Whether any function changed
	#endregion
	static __apply = function(_pass) {
		var _changed = false;
		var _record = _pass.record;
		var _done = -1;
		var _units = undefined;
		while (true) {
			// the functions are found again after a pass changes one, in fn_id order: a change may move or drop them
			_units ??= __units();
			var _unit = undefined;
			var _u = 0; repeat (array_length(_units)) {
				if (_units[_u].fn_id > _done) {
					_unit = _units[_u];
					break;
				}
			_u++}
			if (_unit == undefined) break;
			_done = _unit.fn_id;
			if (has_no_op_targets) && (__isNoOp(_unit.root)) continue;
			_record.applications++;
			__undo = [];
			var _root = _unit.root;
			var _int64 = has_int64 ? __gmlc_opt_int64_positions(_root) : undefined;
			var _bare = __bareStatements(_root);
			// the uses of macros that depend on the configuration: a pass may remove them, not move or copy them
			var _opaque = undefined;
			if (!env.foldsConfigMacros()) && (array_length(struct_get_names(env.__scoped_macros)) > 0) {
				_opaque = {};
				__opaqueUses(_root, _opaque);
			}
			// inside a struct literal `self` is the new struct
			var _optimizer = self;
			// one context for every application, every field set again: a struct and two arrays an application made garbage
			__pass_cx ??= { new_locals: [], nested_locals: [] };
			var _cx = __pass_cx;
			_cx.stats = _record.stats;
			_cx.unit = _unit;
			_cx.optimizer = _optimizer;
			_cx.script = ast;
			_cx.sources = sources;
			_cx.env = env;
			array_resize(_cx.new_locals, 0);
			array_resize(_cx.nested_locals, 0);
			_cx.preserve_lines = preserve_lines;
			_cx.epsilon_set = epsilon_set;
			_cx.condition = false;
			_cx.assigned = undefined;
			_cx.flags = undefined;
			var _did = false;
			if (!__local_types_set) {
				__gmlc_opt_set_local_types(__gmlc_opt_local_types(ast, sources, env.__batch));
				__local_types_set = true;
			}
			try {
				switch (_pass.granularity) {
					case "function": {
						var _new = _pass.run(_unit.root, _cx);
						if (_new != undefined) {
							__replaceUnit(_unit, _new);
							_did = true;
						}
					break;}
					case "block": _did = __eachBlock(_unit.root, undefined, undefined, undefined, _pass, _cx, true); break;
					default:      _did = __eachExpression(_unit.root, _pass, _cx, true); break;
				}
			}
			catch (_e) {
				if (global.__gmlc_fold.node != undefined) throw _e;
				__rollback();
				_unit.root = _root;
				_did = false;
				_units = undefined;
				array_push(__notes, new GMLC_Diagnostic("GMLC4001", _root.span, [_pass.name, _unit.name]));
			}
			if (_did) _units = undefined;
			// GameMaker refuses a statement that is only an operator or a value, whatever pass made it
			if (_did) && (__bareStatements(_unit.root) > _bare) {
				__rollback();
				_unit.root = _root;
				_did = false;
			}
			if (_did) && (_opaque != undefined) {
				var _after = {};
				__opaqueUses(_unit.root, _after);
				var _keys = struct_get_names(_after);
				var _k = 0; repeat (array_length(_keys)) {
					if ((_opaque[$ _keys[_k]] ?? 0) < _after[$ _keys[_k]]) {
						__rollback();
						_unit.root = _root;
						_did = false;
						break;
					}
				_k++}
			}
			if (_did) && (_int64 != undefined) {
				// the VM gives a real for a whole-number local next to an int64 where the literal keeps the int64
				var _now = __gmlc_opt_int64_positions(_unit.root);
				if (_now.beside != _int64.beside) {
					__rollback();
					_unit.root = _root;
					_did = false;
				}
			}
			if (_did) && (preserve_lines) {
				var _lines = { line: 0, kept: true };
				__linesFrom(_unit.root, _lines, true);
				if (!_lines.kept) {
					__rollback();
					_unit.root = _root;
					_did = false;
					array_push(__notes, new GMLC_Diagnostic("GMLC4003", _root.span, [_pass.name, _unit.name]));
				}
			}
			if (_did) {
				__tidy(_unit.root);
				_record.changed_functions++;
				_changed = true;
				// a new local may take a name another function's local has: the name's type is no longer known
				__gmlc_opt_forget_local_types(_cx.new_locals);
				// the temporaries the pass made become locals of the function only when its result is kept
				if (_unit.fn_id < array_length(ast.functions)) && (ast.functions[_unit.fn_id] != undefined) {
					var _locals = ast.functions[_unit.fn_id].locals;
					var _l = 0; repeat (array_length(_cx.new_locals)) {
						if (!array_contains(_locals, _cx.new_locals[_l])) array_push(_locals, _cx.new_locals[_l]);
					_l++}
				}
				// and those it made inside other functions of the unit ({fn_id, name}), of those functions
				var _n = 0; repeat (array_length(_cx.nested_locals)) {
					var _nested = _cx.nested_locals[_n];
					if (_nested.fn_id < array_length(ast.functions)) && (ast.functions[_nested.fn_id] != undefined) && (!array_contains(ast.functions[_nested.fn_id].locals, _nested.name)) {
						array_push(ast.functions[_nested.fn_id].locals, _nested.name);
					}
				_n++}
				__gmlc_opt_refresh_argument_facts(ast);
			}
		}
		__undo = [];
		return _changed;
	};
	
	#region jsDoc
	/// @func    __replaceUnit(_unit, _new)
	/// @desc    Puts a new node in the place of a function's root, recorded for undo.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct}         _unit : The function
	/// @param   {Struct.ASTNode} _new  : The new root
	#endregion
	static __replaceUnit = function(_unit, _new) {
		if (_unit.holder == undefined) {
			array_push(__undo, [self, "ast", undefined, ast]);
			ast = _new;
		}
		else {
			__set(_unit.holder, _unit.key, _unit.index, _new);
		}
		_unit.root = _new;
	};
	
	#region jsDoc
	/// @func    __set(_holder, _key, _index, _new)
	/// @desc    Puts a node into a field or array slot of its holder, recorded for undo.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct}         _holder : The holding node
	/// @param   {String}         _key    : The field
	/// @param   {Real|Undefined} _index  : The array index, undefined for a field
	/// @param   {Struct.ASTNode} _new    : The node
	#endregion
	static __set = function(_holder, _key, _index, _new) {
		if (_index == undefined) {
			array_push(__undo, [_holder, _key, undefined, _holder[$ _key]]);
			_holder[$ _key] = _new;
		}
		else {
			array_push(__undo, [_holder, _key, _index, _holder[$ _key][_index]]);
			_holder[$ _key][_index] = _new;
		}
	};
	
	#region jsDoc
	/// @func    __rollback()
	/// @desc    Undoes every replacement recorded since the last pass started, newest first.
	/// @self    GMLC_Gen_5_Optimizer
	#endregion
	static __rollback = function() {
		var _i = array_length(__undo) - 1;
		repeat (array_length(__undo)) {
			var _entry = __undo[_i];
			if (_entry[2] == undefined) _entry[0][$ _entry[1]] = _entry[3];
			else _entry[0][$ _entry[1]][_entry[2]] = _entry[3];
		_i--}
		__undo = [];
	};
	
	#region jsDoc
	/// @func    __units()
	/// @desc    The functions of the file, in fn_id order: the file's body (fn_id 0) and every function node, each
	///          as {fn_id, name, root, holder, key, index} with the slot that holds its node.
	/// @self    GMLC_Gen_5_Optimizer
	/// @returns {Array<Struct>}
	#endregion
	static __units = function() {
		var _out = [{ fn_id: 0, name: fileName(), root: ast, holder: undefined, key: undefined, index: undefined }];
		__collectUnits(ast, _out);
		array_sort(_out, __gmlc_compare_fn_id);
		return _out;
	};
	
	#region jsDoc
	/// @func    __collectUnits(_node, _out)
	/// @desc    Adds every function node under a node to a list of units, with the slot that holds it.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Array<Struct>}  _out  : The units
	#endregion
	static __collectUnits = function(_node, _out) {
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _key = _fields[_f];
			var _value = _node[$ _key];
			if (is_array(_value)) {
				var _j = 0; repeat (array_length(_value)) {
					if (_value[_j] != undefined) __collectUnit(_node, _key, _j, _value[_j], _out);
				_j++}
			}
			else if (_value != undefined) {
				__collectUnit(_node, _key, undefined, _value, _out);
			}
		_f++}
	};
	#region jsDoc
	/// @func    __collectUnit(_parent, _key, _index, _child, _out)
	/// @desc    Adds a child to a list of units when it is a function node, then the function nodes under it.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode}  _parent : The node that holds it
	/// @param   {String}          _key    : The field
	/// @param   {Real|Undefined}  _index  : The array index, undefined for a field that holds one node
	/// @param   {Struct.ASTNode}  _child  : The child
	/// @param   {Array<Struct>}   _out    : The units
	#endregion
	static __collectUnit = function(_parent, _key, _index, _child, _out) {
		if (__isFunctionNode(_child)) {
			var _info = (_child[$ "fn_id"] != undefined) && (_child.fn_id < array_length(ast.functions)) ? ast.functions[_child.fn_id] : undefined;
			var _name = (_info != undefined) && (_info.name != undefined) ? _info.name : "a function";
			array_push(_out, { fn_id: _child[$ "fn_id"] ?? array_length(_out), name: _name, root: _child, holder: _parent, key: _key, index: _index });
		}
		__collectUnits(_child, _out);
	};
	
	#region jsDoc
	/// @func    __isFunctionNode(_node)
	/// @desc    Whether a node is a function or constructor declaration or a function expression.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __isFunctionNode = function(_node) {
		var _kind = _node.kind;
		return (_kind == __GMLC_NodeKind_FunctionDecl) || (_kind == __GMLC_NodeKind_ConstructorDecl) || (_kind == __GMLC_NodeKind_FunctionExpr);
	};
	
	#region jsDoc
	/// @func    __isStatementList(_node)
	/// @desc    Whether a node holds a statement list: the script, a block, a case or a default.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __isStatementList = function(_node) {
		var _kind = _node.kind;
		return (_kind == __GMLC_NodeKind_Script) || (_kind == __GMLC_NodeKind_Block) || (_kind == __GMLC_NodeKind_Case) || (_kind == __GMLC_NodeKind_Default);
	};
	
	#region jsDoc
	/// @func    __eachExpression(_node, _pass, _cx, _isRoot)
	/// @desc    Runs an expression pass on every expression of a function, inner ones first.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct}         _pass   : The pass
	/// @param   {Struct}         _cx     : The pass context
	/// @param   {Bool}           _isRoot : Whether the node is the function itself
	/// @returns {Bool} Whether anything changed
	#endregion
	static __eachExpression = function(_node, _pass, _cx, _isRoot) {
		if (!_isRoot) && (__isFunctionNode(_node)) return false;
		var _changed = false;
		// each array's length is taken before its children run, as the slots would have it
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _key = _fields[_f];
			var _value = _node[$ _key];
			if (is_array(_value)) {
				var _j = 0; repeat (array_length(_value)) {
					if (_j < array_length(_value)) && (_value[_j] != undefined) && (__eachExpressionSlot(_node, _key, _j, _value[_j], _pass, _cx)) _changed = true;
				_j++}
			}
			else if (_value != undefined) {
				if (__eachExpressionSlot(_node, _key, undefined, _value, _pass, _cx)) _changed = true;
			}
		_f++}
		return _changed;
	};
	#region jsDoc
	/// @func    __eachExpressionSlot(_node, _key, _index, _child, _pass, _cx)
	/// @desc    Runs an expression pass on one child of a node and the expressions inside it, inner ones first.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node  : The parent
	/// @param   {String}         _key   : The field that holds the child
	/// @param   {Real|Undefined} _index : The array index, undefined for a field that holds one node
	/// @param   {Struct.ASTNode} _child : The child
	/// @param   {Struct}         _pass  : The pass
	/// @param   {Struct}         _cx    : The pass context
	/// @returns {Bool} Whether anything changed
	#endregion
	static __eachExpressionSlot = function(_node, _key, _index, _child, _pass, _cx) {
		var _changed = __eachExpression(_child, _pass, _cx, false);
		// the child may have been replaced inside: read it again from its slot
		_child = (_index == undefined) ? _node[$ _key] : _node[$ _key][_index];
		var _kind = _child.kind;
		var _isExpression = (_kind >= __GMLC_NodeKind_Assign) && (_kind <= __GMLC_NodeKind_Nameof) && (_kind != __GMLC_NodeKind_StructEntry);
		if (_isExpression) && ((!has_no_op_targets) || (!__isNoOp(_child))) {
			__slotContext(_node, _key, _cx);
			var _new = _pass.run(_child, _cx);
			// GameMaker refuses a statement that is only an operator or a value
			if (_new != undefined) && (_node.kind == __GMLC_NodeKind_ExprStmt) && (!__isStatementExpression(_new)) _new = undefined;
			if (_new != undefined) {
				__set(_node, _key, _index, _new);
				_changed = true;
			}
		}
		return _changed;
	};
	
	#region jsDoc
	/// @func    __slotContext(_node, _key, _cx)
	/// @desc    Sets in the pass context what the expression in a slot is used for: `condition` when it is only
	///          asked whether it is true (the test of `if`, `while`, `do until`, `for` and `?:`, an operand of `&&`,
	///          `||` and `!`), and `assigned` to the `var` local it is the value of (`var a = expr;` or `a = expr;`),
	///          undefined when none.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The parent
	/// @param   {String}         _key  : The field of the parent that holds the expression
	/// @param   {Struct}         _cx   : The pass context
	#endregion
	static __slotContext = function(_node, _key, _cx) {
		_cx.condition = false;
		_cx.assigned = undefined;
		switch (_node.kind) {
			case __GMLC_NodeKind_If: case __GMLC_NodeKind_While: case __GMLC_NodeKind_DoUntil: case __GMLC_NodeKind_For: case __GMLC_NodeKind_Conditional: _cx.condition = (_key == "test"); break;
			case __GMLC_NodeKind_Logical: _cx.condition = (_node.op == "&&") || (_node.op == "||"); break;
			case __GMLC_NodeKind_Unary: _cx.condition = (_node.op == "!"); break;
			case __GMLC_NodeKind_VarDecl: if (_key == "init") && (__gmlc_opt_is_local(_node.target)) _cx.assigned = _node.target.name; break;
			case __GMLC_NodeKind_Assign: if (_key == "value") && (_node.op == "=") && (__gmlc_opt_is_local(_node.target)) _cx.assigned = _node.target.name; break;
		}
	};
	
	#region jsDoc
	/// @func    __bareStatements(_node)
	/// @desc    Counts the expression statements under a node whose expression may not stand as a statement.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Real}
	#endregion
	static __bareStatements = function(_node) {
		var _n = ((_node.kind == __GMLC_NodeKind_ExprStmt) && (!__isStatementExpression(_node.expression))) ? 1 : 0;
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _value = _node[$ _fields[_f]];
			if (is_array(_value)) {
				var _j = 0; repeat (array_length(_value)) {
					if (_value[_j] != undefined) _n += __bareStatements(_value[_j]);
				_j++}
			}
			else if (_value != undefined) {
				_n += __bareStatements(_value);
			}
		_f++}
		return _n;
	};
	
	#region jsDoc
	/// @func    __isStatementExpression(_node)
	/// @desc    Whether an expression may stand as a statement: a call, a method call, `new`, an assignment, `++` or
	///          `--`.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __isStatementExpression = function(_node) {
		var _kind = _node.kind;
		return (_kind == __GMLC_NodeKind_Call) || (_kind == __GMLC_NodeKind_MethodCall) || (_kind == __GMLC_NodeKind_New)
			|| (_kind == __GMLC_NodeKind_Assign) || (_kind == __GMLC_NodeKind_Update);
	};
	
	#region jsDoc
	/// @func    __eachBlock(_node, _holder, _key, _index, _pass, _cx, _isRoot)
	/// @desc    Runs a block pass on every statement list of a function, outer ones first.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct}         _holder : Its holder, undefined at the root
	/// @param   {String}         _key    : The holder's field
	/// @param   {Real|Undefined} _index  : The array index
	/// @param   {Struct}         _pass   : The pass
	/// @param   {Struct}         _cx     : The pass context
	/// @param   {Bool}           _isRoot : Whether the node is the function itself
	/// @returns {Bool} Whether anything changed
	#endregion
	static __eachBlock = function(_node, _holder, _key, _index, _pass, _cx, _isRoot) {
		if (!_isRoot) && (__isFunctionNode(_node)) return false;
		var _changed = false;
		if (__isStatementList(_node)) && ((!has_no_op_targets) || (!__isNoOp(_node))) {
			var _new = _pass.run(_node, _cx);
			if (_new != undefined) {
				if (_holder == undefined) {
					__replaceUnit(_cx.unit, _new);
				}
				else {
					__set(_holder, _key, _index, _new);
				}
				_node = _new;
				_changed = true;
			}
		}
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _field = _fields[_f];
			var _value = _node[$ _field];
			if (is_array(_value)) {
				var _j = 0; repeat (array_length(_value)) {
					if (_j < array_length(_value)) && (_value[_j] != undefined) && (__eachBlock(_value[_j], _node, _field, _j, _pass, _cx, false)) _changed = true;
				_j++}
			}
			else if (_value != undefined) {
				if (__eachBlock(_value, _node, _field, undefined, _pass, _cx, false)) _changed = true;
			}
		_f++}
		return _changed;
	};
	
	#region jsDoc
	/// @func    __linesFrom(_node, _state, _isRoot)
	/// @desc    Checks that a function's nodes keep source lines in order; clears _state.kept when one goes back.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct}         _state  : {line, kept}
	/// @param   {Bool}           _isRoot : Whether the node is the function itself
	#endregion
	static __linesFrom = function(_node, _state, _isRoot) {
		if (!_state.kept) return;
		if (!_isRoot) && (__isFunctionNode(_node)) return;
		if (_node.span != undefined) && (sources != undefined) {
			var _line = sources.position(_node.span).line;
			if (_line < _state.line) {
				_state.kept = false;
				return;
			}
			_state.line = _line;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__linesFrom(_child, _state, false);
				}
			_i++}
		_field_index++}
	};
	
	#region jsDoc
	/// @func    __tidy(_node)
	/// @desc    Drops empty statements and flattens blocks nested directly in statement lists, inside a function;
	///          `@NoOp` code stays as written.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The node
	#endregion
	static __tidy = function(_node) {
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _child = _slots[_i].node;
			if (!__isFunctionNode(_child)) __tidy(_child);
		_i++}
		if (!__isStatementList(_node)) || (__isNoOp(_node)) return;
		var _body = _node.body;
		var _flat = undefined;
		var _b = 0; repeat (array_length(_body)) {
			var _statement = _body[_b];
			var _kind = _statement.kind;
			if ((_kind == __GMLC_NodeKind_Empty) || (_kind == __GMLC_NodeKind_Block)) && (!__isNoOp(_statement)) {
				if (_flat == undefined) {
					_flat = array_create(_b);
					array_copy(_flat, 0, _body, 0, _b);
				}
				if (_kind == __GMLC_NodeKind_Block) array_copy(_flat, array_length(_flat), _statement.body, 0, array_length(_statement.body));
			}
			else if (_flat != undefined) {
				array_push(_flat, _statement);
			}
		_b++}
		if (_flat != undefined) _node.body = _flat;
	};
	
	#region jsDoc
	/// @func    __renumberTemporaries()
	/// @desc    Gives every function's surviving temporaries the numbers 0, 1, ... in source order, skipping a
	///          number whose name already appears in a file of the compile or that the environment knows.
	/// @self    GMLC_Gen_5_Optimizer
	#endregion
	static __renumberTemporaries = function() {
		if (struct_names_count(__temporary_next) == 0) return;
		var _units = __units();
		var _u = 0; repeat (array_length(_units)) {
			var _unit = _units[_u];
			var _found = [];
			__temporaryNodes(_unit.root, _found, true);
			if (array_length(_found) > 0) {
				// new names in the order the names first appear; a node held in two places is renamed once
				var _map = {};
				var _n = 0;
				var _i = 0; repeat (array_length(_found)) {
					var _name = _found[_i].name;
					if (_map[$ _name] == undefined) {
						while (__temporaryTaken("__gmlc_t" + string(_n))) _n++;
						_map[$ _name] = "__gmlc_t" + string(_n);
						_n++;
					}
				_i++}
				_i = 0; repeat (array_length(_found)) {
					var _id = _found[_i];
					_id.name = _map[$ _id.name];
					if (_id.symbol != undefined) _id.symbol.name = _id.name;
				_i++}
				if (_unit.fn_id < array_length(ast.functions)) {
					var _info = ast.functions[_unit.fn_id];
					if (_info != undefined) {
						var _l = 0; repeat (array_length(_info.locals)) {
							var _new = _map[$ _info.locals[_l]];
							if (_new != undefined) _info.locals[_l] = _new;
						_l++}
					}
				}
			}
		_u++}
	};
	
	#region jsDoc
	/// @func    __temporaryTaken(_name)
	/// @desc    Whether a temporary's name already appears in a file of the compile or the environment knows it.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {String} _name : The name
	/// @returns {Bool}
	#endregion
	static __temporaryTaken = function(_name) {
		if (struct_exists(env.env_symbols, _name)) return true;
		if (sources == undefined) return false;
		// the names in the files are found again only when the table or its file count changed
		if (__temporary_names_sources != sources) || (__temporary_names_count != array_length(sources.files)) {
			__temporary_names_sources = sources;
			__temporary_names_count = array_length(sources.files);
			__temporary_names = __gmlc_temporary_names(sources);
		}
		return struct_exists(__temporary_names, _name);
	};
	
	#region jsDoc
	/// @func    __temporaryNodes(_node, _found, _isRoot)
	/// @desc    Collects the identifiers of a function that name a temporary this run made, in source order.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode}              _node   : The node
	/// @param   {Array<Struct.ASTIdentifier>} _found  : The identifiers
	/// @param   {Bool}                        _isRoot : Whether the node is the function itself
	#endregion
	static __temporaryNodes = function(_node, _found, _isRoot) {
		if (!_isRoot) && (__isFunctionNode(_node)) return;
		if (_node.kind == __GMLC_NodeKind_Identifier) && (struct_exists(__temporaries_made, _node.name)) && (!array_contains(_found, _node)) {
			array_push(_found, _node);
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__temporaryNodes(_child, _found, false);
				}
			_i++}
		_field_index++}
	};
	#endregion
	#region Tree Walks
	#region jsDoc
	/// @func    __visit(_node, _slot)
	/// @desc    Optimizes the children of a node, then the node itself (post-order). Returns the node to put in its
	///          place.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _slot : Where it is held ({parent, key, index}), undefined at the root
	/// @returns {Struct.ASTNode}
	#endregion
	static __visit = function(_node, _slot) {
		//skip nodes from optimization
		var _frozen = __isNoOp(_node);
		if (_frozen) && (!__holdsFreeFunction(_node)) return _node;
		
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _child = _slots[_i];
			var _new = __visit(_child.node, _child);
			if (_new != _child.node) {
				if (_child.index != undefined) {
					_node[$ _child.key][_child.index] = _new;
				}
				else {
					_node[$ _child.key] = _new;
				}
			}
		_i++}
		if (_frozen) return _node;
		
		return optimize({
			node: _node,
			parent: (_slot != undefined) ? _slot.parent : undefined,
			key: (_slot != undefined) ? _slot.key : undefined,
			index: (_slot != undefined) ? _slot.index : undefined,
		});
	};
	
	#region jsDoc
	/// @func    optimize(_node_data)
	/// @desc    Runs the sweep's passes on one node until none changes it.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct} _node_data : {node, parent, key, index}
	/// @returns {Struct.ASTNode} The node to put in its place
	#endregion
	static optimize = function(_node_data) {
		var _start_node = undefined;
		
		//keep optimizing until there are no optimizers which change the node.
		while (_node_data.node != _start_node) {
			var _start_node = _node_data.node;
			
			var _p = 0; repeat (array_length(passes)) {
				var _pass = passes[_p];
				_node_data.node = _pass.run(_node_data, self);
				if (_pass.name == "constant-fold") && (array_length(__failing) > 0) __dropFailing(_start_node, _node_data.node);
			_p++}
			
			if (_start_node != _node_data.node) {
				optimization_occured = true
			}
		}
		
		return _node_data.node;
	};
	
	static __foldKinds = (function() {
		var _kinds = array_create(__GMLC_NodeKind_SIZE, false);
		var _list = [
			__GMLC_NodeKind_Binary, __GMLC_NodeKind_Logical, __GMLC_NodeKind_Nullish, __GMLC_NodeKind_Unary,
			__GMLC_NodeKind_Conditional, __GMLC_NodeKind_Call,
		];
		var _i = 0; repeat (array_length(_list)) {
			_kinds[_list[_i]] = true;
		_i++}
		return _kinds;
	})();
	
	#region jsDoc
	/// @func    __foldWalk(_node, _parent, _key, _index)
	/// @desc    Constant folding alone (a compile without should_optimize): folds the children of a node, then the
	///          node when its kind can fold. Returns the node to put in its place.
	/// @self    GMLC_Gen_5_Optimizer
	#endregion
	static __foldWalk = function(_node, _parent, _key, _index) {
		var _frozen = (has_no_op_targets) && (__isNoOp(_node));
		if (_frozen) && (!__holdsFreeFunction(_node)) return _node;
		var _fields = _node.childFields;
		var _f = 0; repeat (array_length(_fields)) {
			var _field = _fields[_f];
			var _value = _node[$ _field];
			if (is_array(_value)) {
				var _c = 0; repeat (array_length(_value)) {
					var _child = _value[_c];
					if (_child != undefined) {
						var _new = __foldWalk(_child, _node, _field, _c);
						if (_new != _child) _value[_c] = _new;
					}
				_c++}
			}
			else if (_value != undefined) {
				var _new = __foldWalk(_value, _node, _field, undefined);
				if (_new != _value) _node[$ _field] = _new;
			}
		_f++}
		if (_frozen) || (!__foldKinds[_node.kind]) return _node;
		// a folded node may fold again (a collapsed ternary whose branch folds)
		var _data = { node: _node, parent: _parent, key: _key, index: _index };
		var _start = undefined;
		while (_data.node != _start) {
			_start = _data.node;
			_data.node = __fold(_data, self);
			if (array_length(__failing) > 0) __dropFailing(_start, _data.node);
		}
		return _data.node;
	};
	
	#region jsDoc
	/// @func    __foldGuarded(_holder)
	/// @desc    Runs the optimizer's walk again after each constant that fails while computed, until it finishes.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTExprStmt} _holder : An expression to fold alone, undefined for the whole tree
	#endregion
	static __foldGuarded = function(_holder) {
		foldBegin();
		global.__gmlc_fold.epsilon = epsilon_set;
		var _saved_macros = (_holder == undefined) ? __gmlc_opt_set_opaque_macros(env.foldsConfigMacros(), env.__scoped_macros) : undefined;
		var _done = false;
		while (!_done) {
			try {
				__walk(_holder);
				_done = true;
			}
			catch (_e) {
				foldCaught(_e);
			}
		}
		if (_saved_macros != undefined) __gmlc_opt_set_opaque_macros(_saved_macros.folds, _saved_macros.scoped);
		foldEnd();
	};
	
	#region jsDoc
	/// @func    __walk(_holder)
	/// @desc    Folds an expression alone, or the whole tree: folding only, or the pass schedule.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTExprStmt} _holder : An expression to fold alone, undefined for the whole tree
	#endregion
	static __walk = function(_holder) {
		if (_holder != undefined) {
			do {
				optimization_occured = false;
				__foldTree(_holder, undefined);
			}
			until (!optimization_occured);
		}
		else if (mode == GMLC_OPTIMIZE.FOLD) {
			if (folds_constants) ast = __foldWalk(ast, undefined, undefined, undefined);
		}
		else if (array_length(steps) > 0) {
			__gmlc_opt_set_field_types(env.__batch.fields, env.__batch.structs_open);
			__runSchedule();
			__gmlc_opt_set_field_types({}, false);
			__gmlc_opt_set_local_types({});
		}
	};
	
	#region jsDoc
	/// @func    __foldTree(_node, _slot)
	/// @desc    Folds the children of a node, then the node.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Struct}         _slot : Where it is held ({parent, key, index}), undefined at the root
	/// @returns {Struct.ASTNode} The node to put in its place
	#endregion
	static __foldTree = function(_node, _slot) {
		var _slots = _node.childSlots();
		var _i = 0; repeat (array_length(_slots)) {
			var _child = _slots[_i];
			var _new = __foldTree(_child.node, _child);
			if (_new != _child.node) {
				if (_child.index != undefined) {
					_node[$ _child.key][_child.index] = _new;
				}
				else {
					_node[$ _child.key] = _new;
				}
			}
		_i++}
		if (_slot == undefined) return _node;
		var _data = { node: _node, parent: _slot.parent, key: _slot.key, index: _slot.index };
		var _folded = __fold(_data, self);
		if (_folded != _node) optimization_occured = true;
		return _folded;
	};
	#endregion
	#region Scans
	#region jsDoc
	/// @func    __epsilonCalls(_node, _out)
	/// @desc    Every reference to math_set_epsilon in a tree, in source order.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The tree
	/// @param   {Array}          _out  : Where the Identifier nodes go
	#endregion
	static __epsilonCalls = function(_node, _out) {
		if (_node.kind == __GMLC_NodeKind_Identifier) && (_node.name == "math_set_epsilon") {
			array_push(_out, _node);
			return;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__epsilonCalls(_child, _out);
				}
			_i++}
		_field_index++}
	};
	
	#region jsDoc
	/// @func    __opaqueUses(_node, _out)
	/// @desc    Counts the nodes under a node that come from a macro use that must stay a name, by the use and the
	///          span the node stands at. A node a pass moved or copied has another count or span: the emitter could
	///          no longer print the name.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The tree
	/// @param   {Struct}         _out  : The counts by key
	#endregion
	static __opaqueUses = function(_node, _out) {
		if (__gmlc_opt_is_opaque(_node)) {
			var _span = _node.span;
			var _key = string(_node.origin.use_span.start) + ":" + string(_span.file) + ":" + string(_span.start) + ":" + string(_span.end);
			_out[$ _key] = (_out[$ _key] ?? 0) + 1;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__opaqueUses(_child, _out);
				}
			_i++}
		_field_index++}
	};
	
	#region jsDoc
	/// @func    scopedMacros(_asts)
	/// @desc    The names of the macros that have a definition with a `Config:` prefix in any file of a batch.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Array<Struct.ASTNode>} _asts : The files' trees
	/// @returns {Struct} The names as keys
	#endregion
	static scopedMacros = function(_asts) {
		var _out = {};
		var _i = 0; repeat (array_length(_asts)) {
			var _macros = _asts[_i].macros;
			var _m = 0; repeat (array_length(_macros)) {
				if (_macros[_m].config != undefined) _out[$ _macros[_m].name] = true;
			_m++}
		_i++}
		return _out;
	};
	
	#region jsDoc
	/// @func    __isNoOp(_node)
	/// @desc    Whether a node lies inside a `@NoOp` target and outside the functions that target leaves free.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __isNoOp = function(_node) {
		if (!has_no_op_targets) || (_node.span == undefined) return false;
		var _span = _node.span;
		var _i = 0; repeat (array_length(no_op_targets)) {
			var _target = no_op_targets[_i].target;
			if (_span.file == _target.file) && (_span.start >= _target.start) && (_span[$ "end"] <= _target[$ "end"]) {
				var _holes = no_op_targets[_i].holes;
				var _free = false;
				var _h = 0; repeat (array_length(_holes)) {
					var _hole = _holes[_h];
					if (_span.start >= _hole.start) && (_span[$ "end"] <= _hole[$ "end"]) {
						_free = true;
						break;
					}
				_h++}
				if (!_free) return true;
			}
		_i++}
		return false;
	};
	
	#region jsDoc
	/// @func    __holdsFreeFunction(_node)
	/// @desc    Whether a node holds a function that a `gml_pragma` NoOp around it leaves free, so a walk has to go
	///          into the frozen node to reach it.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __holdsFreeFunction = function(_node) {
		var _span = _node.span;
		var _i = 0; repeat (array_length(no_op_targets)) {
			var _holes = no_op_targets[_i].holes;
			var _h = 0; repeat (array_length(_holes)) {
				var _hole = _holes[_h];
				if (_hole.file == _span.file) && (_hole.start >= _span.start) && (_hole[$ "end"] <= _span[$ "end"]) return true;
			_h++}
		_i++}
		return false;
	};
	
	#region jsDoc
	/// @func    __containsNoOp(_node)
	/// @desc    Whether a node or anything inside it lies inside a `@NoOp` target.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __containsNoOp = function(_node) {
		if (!has_no_op_targets) return false;
		if (__isNoOp(_node)) return true;
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__containsNoOp(_child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};
	
	#region jsDoc
	/// @func    __keepsCode(_node)
	/// @desc    Whether code a fold would drop has to stay: a `// @NoOp` target, or an asset reference, which
	///          GameMaker's unused-asset stripping would otherwise delete.
	/// @self    GMLC_Gen_5_Optimizer
	/// @returns {Bool}
	#endregion
	static __keepsCode = function(_node) {
		return __containsNoOp(_node) || __referencesAsset(_node);
	};
	
	#region jsDoc
	/// @func    __keepsStatements(_node)
	/// @desc    Whether statements a fold would drop have to stay: code __keepsCode keeps, or a declaration: a `var` in
	///          a dead branch or loop still makes the name a local for the code after it.
	/// @self    GMLC_Gen_5_Optimizer
	/// @returns {Bool}
	#endregion
	static __keepsStatements = function(_node) {
		return __keepsCode(_node) || __gmlc_opt_declares(_node);
	};
	
	#region jsDoc
	/// @func    __referencesAsset(_node)
	/// @desc    Whether a node or anything inside it names an asset.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __referencesAsset = function(_node) {
		if (_node.kind == __GMLC_NodeKind_Identifier) && (_node.symbol != undefined) && (_node.symbol.kind == "BuiltinConstant") {
			var _data = env.getConstant(_node.name);
			if (_data != undefined) && (typeof(_data.value) == "ref") return true;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__referencesAsset(_child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};
	#endregion
	#region Logging
	#region jsDoc
	/// @func    __parseAllLogged()
	/// @desc    With GMLC_Env.__log_optimizations at 1, prints the changed nodes by kind per compile; at 2, each
	///          change too.
	/// @self    GMLC_Gen_5_Optimizer
	#endregion
	static __parseAllLogged = function() {
		var _before = json_parse(gmlc_ast_to_json(ast, sources, "lowered")).root;
		__foldGuarded(undefined);
		__reportFailing();
		var _after = json_parse(gmlc_ast_to_json(ast, sources, "optimized")).root;
		var _changes = [];
		__changesBetween(_before, _after, _before, _changes);
		if (array_length(_changes) == 0) return ast;
		var _counts = {};
		var _i = 0; repeat (array_length(_changes)) {
			var _from = _changes[_i][0];
			var _kind = (is_struct(_from)) && (_from[$ "kind"] != undefined) ? _from.kind : _changes[_i][2].kind;
			_changes[_i][3] = _kind;
			_counts[$ _kind] = (_counts[$ _kind] ?? 0) + 1;
		_i++}
		if (env.__log_optimizations >= 2) {
			_i = 0; repeat (array_length(_changes)) {
				var _change = _changes[_i];
				var _at = (is_struct(_change[0])) && (_change[0][$ "span"] != undefined) ? _change[0] : _change[2];
				show_debug_message($"Optimizer :: line {__line(_at)} :: {_change[3]} `{__spanText(_change[0])}` -> `{__spanText(_change[1])}`");
			_i++}
		}
		var _names = struct_get_names(_counts);
		array_sort(_names, true);
		var _text = "Optimizer ::";
		_i = 0; repeat (array_length(_names)) {
			_text += " " + _names[_i] + " " + string(_counts[$ _names[_i]]);
		_i++}
		show_debug_message(_text + " (" + fileName() + ")");
		return ast;
	};
	
	#region jsDoc
	/// @func    __changesBetween(_a, _b, _around, _out)
	/// @desc    Collects the smallest differing parts of two JSON trees as [before, after, around].
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Any}    _a      : Before
	/// @param   {Any}    _b      : After
	/// @param   {Struct} _around : The node holding them
	/// @param   {Array}  _out    : The changes
	#endregion
	static __changesBetween = function(_a, _b, _around, _out) {
		if (json_stringify(_a) == json_stringify(_b)) return;
		if (is_array(_a)) && (is_array(_b)) && (array_length(_a) == array_length(_b)) {
			var _i = 0; repeat (array_length(_a)) {
				__changesBetween(_a[_i], _b[_i], _around, _out);
			_i++}
			return;
		}
		if (is_struct(_a)) && (is_struct(_b)) && (_a[$ "kind"] != undefined) && (_a[$ "kind"] == _b[$ "kind"]) {
			var _names = struct_get_names(_a);
			var _inside = true;
			var _i = 0; repeat (array_length(_names)) {
				var _x = _a[$ _names[_i]];
				if (_names[_i] != "span") && (_names[_i] != "origin") && (!is_struct(_x)) && (!is_array(_x))
				&& (json_stringify(_x) != json_stringify(_b[$ _names[_i]])) {
					_inside = false;
				}
			_i++}
			if (_inside) {
				_i = 0; repeat (array_length(_names)) {
					if (_names[_i] != "span") && (_names[_i] != "origin") {
						__changesBetween(_a[$ _names[_i]], _b[$ _names[_i]], _a, _out);
					}
				_i++}
				return;
			}
		}
		array_push(_out, [_a, _b, _around]);
	};
	
	#region jsDoc
	/// @func    __spanText(_node)
	/// @desc    The source text of a JSON node, for the change log.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Any} _node : A JSON node or value
	/// @returns {String}
	#endregion
	static __spanText = function(_node) {
		if (!is_struct(_node)) return (_node == undefined) ? "(nothing)" : json_stringify(_node);
		if (_node[$ "kind"] == "Literal") && (_node[$ "lexeme"] != undefined) return _node.lexeme;
		var _span = _node[$ "span"];
		if (sources == undefined) || (!is_struct(_span)) || (_span.file >= array_length(sources.files)) return _node[$ "kind"] ?? "";
		var _file = sources.files[_span.file];
		return (_file != undefined) ? _file.textBetween(_span.start, _span[$ "end"]) : "";
	};
	#endregion
	#endregion
	
	#region Optimizers
	
	
	
	#region JSDocs
	/// @function    removeRedundantTypeChecks(_node)
	/// @description This function removes redundant type checks from code. If we can determine with certainty that a variable will never be of a particular type, 
	///              we remove the unnecessary check (e.g., `is_string()` when it’s known the value cannot be a string).
	/// @param       {ASTNode}    _astNode    The AST node to check for type redundancies.
	/// @return      {ASTNode}    _astNode    The optimized AST node without unnecessary type checks.
	#endregion
	static removeRedundantTypeChecks = function(_node) {
	    // Pseudocode:
	    // 1. Traverse the AST tree to identify any type checks like is_string(), is_method(), etc.
	    // 2. Analyze the variable or expression to determine if the type check is needed.
	    // 3. Remove the check if it's redundant. 
	    //    Example: 
	    //      Before: if (is_string(value)) { ... }
	    //      After: Removed if it's known value is never a string.
	    // 4. Return the optimized AST node.
	}
	
	#region JSDocs
	/// @function    simplifyIncrementExpressions(_node)
	/// @description Simplifies expressions like `arr[0] = arr[0] + 1` to `arr[0]++` to save cycles and improve readability.
	/// @param       {ASTNode}    _astNode    The AST node containing an expression to simplify.
	/// @return      {ASTNode}    _astNode    The optimized AST node with simplified increment/decrement expressions.
	#endregion
	static simplifyIncrementExpressions = function(_node) {
	    // Pseudocode:
	    // 1. Look for patterns where a value is being assigned to itself with an increment/decrement operation.
	    // 2. Replace the expression with the more concise increment (++) or decrement (--) operator.
	    //    Example:
	    //      Before: arr[0] = arr[0] + 1;
	    //      After: arr[0]++;
	    // 3. Handle both prefix and postfix cases, ensuring side effects are preserved.
	    // 4. Return the updated AST node.
	}
	
	#region JSDocs
	/// @function    optimizeInfinityExpressions(_node)
	/// @description Optimizes mathematical expressions involving `infinity`, as the results can be deduced without computation. 
	///              For example, any multiplication by infinity results in infinity, and division by infinity results in 0.
	/// @param       {ASTNode}    _astNode    The AST node containing math expressions to optimize.
	/// @return      {ASTNode}    _astNode    The optimized AST node with simplified infinity operations.
	#endregion
	static optimizeInfinityExpressions = function(_node) {
	    // Pseudocode:
	    // 1. Traverse the AST to locate any expressions containing the keyword 'infinity'.
	    // 2. Apply the following transformations:
	    //    - Any number multiplied by infinity is infinity.
	    //    - Any number divided by infinity is 0.
	    //    Example:
	    //      Before: result = 5 * infinity;
	    //      After: result = infinity;
	    // 3. Ensure the changes reflect in the bytecode for execution efficiency.
	    // 4. Return the updated AST node.
	}
	
	#region JSDocs
	/// @function    inlineSimpleFunctions(_node)
	/// @description Inlines simple functions into the code when they are short and frequently called to avoid the overhead of function calls.
	/// @param       {ASTNode}    _astNode    The AST node representing the function call.
	/// @return      {ASTNode}    _astNode    The optimized AST node with inlined function bodies.
	#endregion
	static inlineSimpleFunctions = function(_node) {
	    // Pseudocode:
	    // 1. Identify functions that meet the criteria for inlining (e.g., short, no side effects, frequent calls).
	    // 2. Replace the function call in the AST with the body of the function.
	    //    Example:
	    //      Before: result = simpleFunction();
	    //      After: result = <inlined function body>;
	    // 3. Ensure that inlining respects variable scope and context.
	    // 4. Return the updated AST node.
	}
	
	#region JSDocs
	/// @function    simplifyConditionalExpressions(_node)
	/// @description Simplifies conditional expressions. For instance, `if (true && condition)` becomes `if (condition)`.
	/// @param       {ASTNode}    _astNode    The AST node representing the conditional expression.
	/// @return      {ASTNode}    _astNode    The simplified AST node.
	#endregion
	static simplifyConditionalExpressions = function(_node) {
	    // Pseudocode:
	    // 1. Traverse the AST and locate conditional expressions (`if`, `else`, `ternary operators`).
	    // 2. Simplify expressions where possible, removing constant conditions.
	    //    Example:
	    //      Before: if (true && condition)
	    //      After: if (condition)
	    // 3. Return the optimized AST node.
	}
	
	#region JSDocs
	/// @function    improveLoopIterations(_node)
	/// @description Optimizes loop iterations by removing unnecessary computations and using efficient constructs.
	/// @param       {ASTNode}    _astNode    The AST node representing a loop.
	/// @return      {ASTNode}    _astNode    The optimized AST node with improved iteration performance.
	#endregion
	static improveLoopIterations = function(_node) {
	    // Pseudocode:
	    // 1. Traverse loops (`for`, `repeat`, `while`, `doUntil`) and check for opportunities to improve iteration efficiency.
	    // 2. Ensure minimal work is done inside the loop, e.g., precompute values outside the loop.
	    //    Example: move constant expressions or variables that don't change outside the loop.
	    //    Before: for (var i = 0; i < expensiveCalculation(); i++) { ... }
	    //    After: var limit = expensiveCalculation(); for (var i = 0; i < limit; i++) { ... }
	    // 3. Return the optimized AST node.
	}
	
	#region JSDocs
	/// @function    loopInvariantCodeMotion(_node)
	/// @description Hoists loop-invariant code outside loops to reduce unnecessary computations during iterations.
	/// @param       {ASTNode}    _astNode    The AST node representing a loop.
	/// @return      {ASTNode}    _astNode    The optimized AST node with loop-invariant code moved out.
	#endregion
	static loopInvariantCodeMotion = function(_node) {
	    // Pseudocode:
	    // 1. Traverse the loop and identify expressions or variables that don't change during loop execution.
	    // 2. Move these expressions outside the loop to avoid repeated calculations.
	    //    Example:
	    //      Before: for (var i = 0; i < n; i++) { var x = constantCalculation(); ... }
	    //      After: var x = constantCalculation(); for (var i = 0; i < n; i++) { ... }
	    // 3. Return the updated AST node.
	}
	
	#region JSDocs
	/// @function    shortCircuitBooleanEvaluation(_node)
	/// @description Optimizes boolean expressions by short-circuiting them. If the result of a boolean expression is already known, the rest is not evaluated.
	/// @param       {ASTNode}    _astNode    The AST node representing a boolean expression.
	/// @return      {ASTNode}    _astNode    The optimized AST node with short-circuiting applied.
	#endregion
	static shortCircuitBooleanEvaluation = function(_node) {
	    // Pseudocode:
	    // 1. Identify boolean expressions involving `&&` or `||`.
	    // 2. Apply short-circuiting logic. If the first operand determines the result, remove the rest of the expression.
	    //    Example:
	    //      Before: if (expensiveFunction() && true) { ... }
	    //      After: if (expensiveFunction()) { ... }
	    // 3. Return the optimized AST node.
	}
	
	#region JSDocs
	/// @function    removeNullEmptyCheck(_node)
	/// @description Simplifies checks for null or empty values. For instance, replace `if (thing != undefined)` with `if (thing)`.
	/// @param       {ASTNode}    _astNode    The AST node representing a null/empty check.
	/// @return      {ASTNode}    _astNode    The optimized AST node with simplified checks.
	#endregion
	static removeNullEmptyCheck = function(_node) {
	    // Pseudocode:
	    // 1. Identify checks for null, empty, or undefined values.
	    // 2. Simplify them where appropriate. 
	    //    Example:
	    //      Before: if (thing != undefined)
	    //      After: if (thing)
	    // 3. Return the optimized AST node.
	}
	
	#region JSDocs
	/// @function    foldLogicalExpressions(_node)
	/// @description Optimizes logical expressions like `a && false` by folding them to `false` at compile time.
	/// @param       {ASTNode}    _astNode    The AST node representing a logical expression.
	/// @return      {ASTNode}    _astNode    The optimized AST node with logical expressions folded.
	#endregion
	static foldLogicalExpressions = function(_node) {
	    // Pseudocode:
	    // 1. Identify logical expressions where one of the operands makes the result obvious.
	    //    Example:
	    //      Before: a && false
	    //      After: false
	    // 2. Apply folding for both `&&` and `||` cases.
	    // 3. Return the optimized AST node.
	}
	
	#region JSDocs
	/// @function    foldAssignments(_node)
	/// @description Optimizes assignments like `a = a + 1` to use more efficient operators like `a++`.
	/// @param       {ASTNode}    _astNode    The AST node representing an assignment.
	/// @return      {ASTNode}    _astNode    The optimized AST node with folded assignments.
	#endregion
	static foldAssignments = function(_node) {
	    // Pseudocode:
	    // 1. Identify assignment patterns like `a = a + 1` or `b = b * a`.
	    // 2. Replace them with more efficient operators:
	    //    - `a = a + 1` becomes `a++`
	    //    - `b = b * a` becomes `b *= a`
	    // 3. Return the optimized AST node.
	}
	
	#region JSDocs
	/// @function    loopUnrolling(_node)
	/// @description Unrolls loops if the number of iterations is small and known at compile time, improving performance by reducing loop overhead.
	/// @param       {ASTNode}    _astNode    The AST node representing a loop.
	/// @return      {ASTNode}    _astNode    The optimized AST node with loop unrolling applied.
	#endregion
	static loopUnrolling = function(_node) {
	    // Pseudocode:
	    // 1. Check if the loop has a small, fixed iteration count.
	    // 2. Unroll the loop by manually duplicating the body of the loop.
	    //    Example:
	    //      Before: for (var i = 0; i < 4; i++) { ... }
	    //      After: (body of the loop repeated 4 times)
	    // 3. Ensure that the total expression size remains within reasonable limits (e.g., 1024 bytes).
	    // 4. Return the unrolled AST node.
	}
	
	#region JSDocs
	/// @function    commonSubexpressionElimination(_astNode)
	/// @description Eliminates repeated subexpressions by calculating them once and reusing the result.
	/// @param       {ASTNode}    _astNode    The AST node containing common subexpressions.
	/// @return      {ASTNode}    _astNode    The optimized AST node with common subexpressions eliminated.
	#endregion
	static commonSubexpressionElimination = function(_node) {
	    // Pseudocode:
	    // 1. Identify repeated expressions within the same scope.
	    //    Example:
	    //      Before: c = (a - b) + 1; d = (a - b) + 2;
	    //      After: var _temp = (a - b); c = _temp + 1; d = _temp + 2;
	    // 2. Store the result of the first evaluation and reuse it for subsequent calculations.
	    // 3. Return the optimized AST node.
	}
	
	#region JSDocs
	/// @function    peepholeOptimizations(_astNode)
	/// @description Performs small, localized optimizations that can be found by looking at a few adjacent instructions.
	/// @param       {ASTNode}    _astNode    The AST node representing a small code block.
	/// @return      {ASTNode}    _astNode    The optimized AST node after peephole optimizations.
	#endregion
	static peepholeOptimizations = function(_node) {
	    // Pseudocode:
	    // 1. Look for small, low-level optimizations by examining adjacent instructions or expressions.
	    // 2. Examples include:
	    //    - Removing redundant loads and stores.
	    //    - Merging adjacent operations (e.g., a = b; b = a can be optimized away).
	    // 3. Return the optimized AST node.
	}
	
	
	//array_push(parserSteps, constantFolding);
	
	//array_push(parserSteps, removeRedundantTypeChecks);
	//array_push(parserSteps, simplifyIncrementExpressions);
	//array_push(parserSteps, optimizeInfinityExpressions);
	//array_push(parserSteps, inlineSimpleFunctions);
	//array_push(parserSteps, simplifyConditionalExpressions);
	//array_push(parserSteps, optimizeVariableScope);
	//array_push(parserSteps, optimizePickOneFunctions);
	//array_push(parserSteps, improveLoopIterations);
	//array_push(parserSteps, loopInvariantCodeMotion);
	//array_push(parserSteps, constantPropagation);
	//array_push(parserSteps, shortCircuitBooleanEvaluation);
	//array_push(parserSteps, removeNullEmptyCheck);
	//array_push(parserSteps, foldLogicalExpressions);
	//array_push(parserSteps, foldAssignments);
	//array_push(parserSteps, strengthReduction);
	//array_push(parserSteps, loopUnrolling);
	//array_push(parserSteps, commonSubexpressionElimination);
	//array_push(parserSteps, peepholeOptimizations);
	//array_push(parserSteps, optimizeAlternateFunctions);
	
	
	
	#endregion
	
	#region Helper Functions
	#region jsDoc
	/// @func    __line(_node)
	/// @desc    The source line of a node, 0 without the compile's files.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct} _node : A node with a span
	/// @returns {Real}
	#endregion
	static __line = function(_node) {
		return (sources != undefined) ? sources.position(_node.span).line : 0;
	};
	
	#region jsDoc
	/// @func    __literal(_value, _span)
	/// @desc    A Literal of a computed value, or undefined when no literal reads back with the same type and
	///          value: a small int64 is written int64(n), and a whole real past 32 bits (outside an enum's value),
	///          -0 and a real whose text needs an exponent are not folded.
	/// @self    GMLC_Gen_5_Optimizer
	/// @returns {Struct.ASTLiteral|Undefined}
	#endregion
	static __literal = function(_value, _span) {
		var _ty = "real";
		var _lexeme;
		if (is_string(_value)) {
			_ty = "string";
			_lexeme = json_stringify(_value);
		}
		else if (is_bool(_value)) {
			_ty = "bool";
			_lexeme = (_value) ? "true" : "false";
		}
		else if (is_int64(_value)) {
			_ty = "int64";
			_lexeme = string(_value);
			if (_value >= -2147483648) && (_value <= 2147483647) _lexeme = "int64(" + _lexeme + ")";
			else if (_value == -9223372036854775807 - 1) _lexeme = "0x8000000000000000";
		}
		else if (is_undefined(_value)) {
			_ty = "undefined";
			_lexeme = "undefined";
		}
		else {
			if (_value == 0) && (1 / _value < 0) return undefined;
			if (!__enum_values) && (__gmlc_is_whole(_value)) && (abs(_value) >= 2147483648) return undefined;
			_lexeme = (__gmlc_is_whole(_value)) && (abs(_value) < 9007199254740992) ? string(int64(_value)) : __gmlc_real_text(_value);
			if (string_pos("e", _lexeme) > 0) return undefined;
		}
		return new ASTLiteral(_span, _ty, _lexeme, _value);
	};
	
	#region jsDoc
	/// @func    __constantValue(_node)
	/// @desc    The value of a node known while compiling: a literal or a built-in constant of a plain type.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Array} [true, value] for a literal or a built-in constant, else [false]
	#endregion
	static __constantValue = function(_node) {
		if (__gmlc_opt_is_opaque(_node)) return [false];
		if (_node.kind == __GMLC_NodeKind_Literal) {
			return [true, _node.value];
		}
		if (_node.kind == __GMLC_NodeKind_Identifier) && (_node.symbol != undefined) && (_node.symbol.kind == "BuiltinConstant") {
			var _data = env.getConstant(_node.name);
			if (_data != undefined) {
				var _value = _data.value;
				if (is_bool(_value)) || (is_real(_value)) || (is_undefined(_value)) || (is_string(_value)) {
					return [true, _value];
				}
			}
		}
		return [false];
	};
	
	#region jsDoc
	/// @func    __keepsValue(_node_data)
	/// @desc    Whether a constant may take the place of a node where it is held.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct} _node_data : {node, parent, key, index}
	/// @returns {Bool}
	#endregion
	static __keepsValue = function(_node_data) {
		if (mode == GMLC_OPTIMIZE.CONSTANT) || (_node_data.parent == undefined) return true;
		return __canReplaceIn(_node_data.parent, _node_data.key);
	};
	
	#region jsDoc
	/// @func    __canReplaceIn(_parent, _key)
	/// @desc    Whether a constant may take the place of an expression held there: only the object of `a.b` and
	///          `a.b()` keeps its expression.
	/// @self    GMLC_Gen_5_Optimizer
	/// @returns {Bool}
	#endregion
	static __canReplaceIn = function(_parent, _key) {
		switch (_parent.kind) {
			case __GMLC_NodeKind_Index:
			case __GMLC_NodeKind_MethodCall: {
				return (_key != "object");
			}
		}
		return true;
	};
	
	#region jsDoc
	/// @func    __alwaysFails(_node, _code, _args)
	/// @desc    Records a constant that fails when the code runs (`real("ab")`): a compile error, or under
	///          test_mode a warning with the expression kept. An enum's value reports its own.
	/// @self    GMLC_Gen_5_Optimizer
	#endregion
	static __alwaysFails = function(_node, _code, _args) {
		if (mode == GMLC_OPTIMIZE.CONSTANT) return;
		var _i = 0; repeat (array_length(__failing)) {
			if (__failing[_i].node == _node) return;
		_i++}
		var _diagnostic = new GMLC_Diagnostic(_code, _node.span, _args);
		if (env.test_mode) _diagnostic.severity = "warning";
		// kept until the tree is done: a later fold may drop the expression (`false && real("ab")`)
		array_push(__failing, { node: _node, diagnostic: _diagnostic, dropped: false });
	};
	
	#region jsDoc
	/// @func    __dropFailing(_old, _new)
	/// @desc    A fold put _new in the place of _old: the failures in what it left out are dropped. Code that dead
	///          code elimination removes keeps its failures, so a compile reports the same with or without
	///          should_optimize.
	/// @self    GMLC_Gen_5_Optimizer
	#endregion
	static __dropFailing = function(_old, _new) {
		if (_old == _new) return;
		var _i = 0; repeat (array_length(__failing)) {
			var _failure = __failing[_i];
			if (!_failure.dropped) && __holds(_old, _failure.node) && !__holds(_new, _failure.node) _failure.dropped = true;
		_i++}
	};
	
	#region jsDoc
	/// @func    __holds(_root, _node)
	/// @desc    Whether a node is a tree's root or lies inside it.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _root : The tree
	/// @param   {Struct.ASTNode} _node : The node
	/// @returns {Bool}
	#endregion
	static __holds = function(_root, _node) {
		if (_root == _node) return true;
		var _children = _root.children();
		var _c = 0; repeat (array_length(_children)) {
			if (__holds(_children[_c], _node)) return true;
		_c++}
		return false;
	};
	
	#region jsDoc
	/// @func    __reportFailing()
	/// @desc    Adds the failures of constants still in the tree to the diagnostics.
	/// @self    GMLC_Gen_5_Optimizer
	#endregion
	static __reportFailing = function() {
		var _i = 0; repeat (array_length(__failing)) {
			if (!__failing[_i].dropped) array_push(diagnostics, __failing[_i].diagnostic);
		_i++}
		__failing = [];
	};
	
	#region jsDoc
	/// @func    __foldConditional(_node_data)
	/// @desc    Folds `c ? a : b` with a known test to the branch it takes.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct} _node_data : {node, parent, key, index}
	/// @returns {Struct.ASTNode}
	#endregion
	static __foldConditional = function(_node_data) {
		var _node = _node_data.node;
		var _test = __constantValue(_node.test);
		if (!_test[0]) || (!is_numeric(_test[1])) return _node;
		
		var _taken   = (_test[1]) ? _node.consequent : _node.alternate;
		var _dropped = (_test[1]) ? _node.alternate : _node.consequent;
		if (__keepsCode(_dropped)) return _node;
		
		var _value = __constantValue(_taken);
		if (_value[0]) && (!__keepsValue(_node_data)) return _node;
		if (__selfIntoStructEntry(_node_data, _taken)) return _node;
		
		return _taken;
	};
	
	#region jsDoc
	/// @func    __selfIntoStructEntry(_node_data, _node)
	/// @desc    Whether a node would become a struct literal entry's whole value `self`: there GameMaker's `self`
	///          is the new struct, while inside `c ? self : x` or `x ?? self` it is the creator.
	/// @self    GMLC_Gen_5_Optimizer
	/// @returns {Bool}
	#endregion
	static __selfIntoStructEntry = function(_node_data, _node) {
		return (_node_data.parent != undefined) && (_node_data.parent.kind == __GMLC_NodeKind_StructEntry)
			&& (_node.kind == __GMLC_NodeKind_Identifier) && (_node.name == "self");
	};
	
	#region jsDoc
	/// @func    __calleeFunction(_node)
	/// @desc    The built-in function a call names, or undefined.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Struct.ASTNode} _node : A Call node
	/// @returns {Function|Undefined}
	#endregion
	static __calleeFunction = function(_node) {
		var _callee = _node.callee;
		if (_callee.kind != __GMLC_NodeKind_Identifier) || (_callee.symbol == undefined) || (_callee.symbol.kind != "BuiltinFunction") return undefined;
		var _data = env.getFunction(_callee.name);
		return (_data != undefined) ? (_data[$ "raw"] ?? _data.value) : undefined;
	};
	
	#region jsDoc
	/// @func    __builtin(_name, _span)
	/// @desc    An identifier that names a built-in function.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {String} _name : The function's name
	/// @param   {Struct} _span : The span to give it
	/// @returns {Struct.ASTIdentifier}
	#endregion
	static __builtin = function(_name, _span) {
		var _identifier = new ASTIdentifier(_span, _name);
		_identifier.symbol = new GMLC_Symbol("BuiltinFunction", _name);
		return _identifier;
	};
	
	#region jsDoc
	/// @func    __argumentsAreLiteral(_arguments)
	/// @desc    Whether every argument is a literal.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Array<Struct.ASTNode>} _arguments : The arguments
	/// @returns {Bool}
	#endregion
	static __argumentsAreLiteral = function(_arguments) {
		var _i=0; repeat(array_length(_arguments)) {
			if (_arguments[_i].kind != __GMLC_NodeKind_Literal) {
				return false;
			}
		_i+=1;}//end repeat loop
		return true;
	}
	
	#region jsDoc
	/// @func    __build_literal_from_function_call_constant_folding(_script, _node_data)
	/// @desc    Folds a call of a pure built-in on literal arguments by running it: its literal, or the call when it cannot fold.
	/// @self    GMLC_Gen_5_Optimizer
	/// @param   {Function} _script    : The built-in
	/// @param   {Struct}   _node_data : {node, parent, key, index}
	/// @returns {Struct.ASTNode}
	#endregion
	static __build_literal_from_function_call_constant_folding = function(_script, _node_data) {
		var _node = _node_data.node;
		if (!__argumentsAreLiteral(_node.args)) return _node;
		
		//remap the arguments
		var _arr = _node.args;
		var _new_arr = [];
		var _i=0; repeat(array_length(_arr)) {
			_new_arr[_i] = _arr[_i].value;
		_i+=1;}//end repeat loop
		
		// the project's Game Options decide how int64() converts a string
		if (_script == int64) && (is_string(_new_arr[0])) return _node;
		
		if (_script == string_repeat) {
			// a string_repeat whose length passes int32 fails whenever it runs
			var _repeatFails = __gmlc_string_repeat_failure(_new_arr);
			if (_repeatFails != undefined) {
				__alwaysFails(_node, _repeatFails[0] ? "GMLC4101" : "GMLC4102", [_repeatFails[1]]);
				return _node;
			}
			// a string too long to become a literal is not built at all; a count outside int32 is read as its low 32
			// bits, which can be a count so large that it ends GameMaker's runner
			if (is_string(_new_arr[0])) && (is_numeric(_new_arr[1]))
			&& ((string_byte_length(_new_arr[0]) * _new_arr[1] > __GMLC_FOLD_STRING_LIMIT)
			|| (_new_arr[1] < -2147483648) || (_new_arr[1] >= 2147483648)) return _node;
		}
		
		// a text so long that it ends GameMaker's runner is not built at all
		if (_script == string_format) && (!__gmlc_string_format_folds(_new_arr)) return _node;
		
		var _failed = __GMLCfoldFailure(_node);
		if (_failed != undefined) {
			__alwaysFails(_node, "GMLC4102", [_failed]);
			return _node;
		}
		var _fold = global.__gmlc_fold;
		_fold.node = _node;
		var _value = script_execute_ext(_script, _new_arr);
		_fold.node = undefined;
		if (_script == power) && (!__gmlc_power_folds(_new_arr[0], _new_arr[1], _value)) return _node;
		
		if (!is_string(_value)) && (!is_numeric(_value)) && (!is_undefined(_value)) return _node;
		if (is_string(_value)) && (string_byte_length(_value) > __GMLC_FOLD_STRING_LIMIT) return _node;
		// a literal holds UTF-8 text: `ansi_char(167)` stays a call
		if (is_string(_value)) && (__gmlc_lossy_utf8(_value) != _value) return _node;
		if (!__keepsValue(_node_data)) return _node;
		
		return __literal(_value, _node.span) ?? _node;
	}
	
	#endregion
}

#region Analyses
#region jsDoc
/// @func    gmlc_analyses(_ast)
/// @desc    The analyses of every function of a lowered script, in fn_id order: the statement control-flow graph
///          with exception edges (a statement inside a try body may throw to its catch, or to its finally when there
///          is no catch), reaching definitions and liveness of locals, and alias classes of the references locals
///          hold. Node 0 is the entry and node 1 the exit; the other nodes are statements in source order, a
///          compound statement's node standing for its test, with `catch` and `finally` nodes of their own.
/// @param   {Struct.ASTScript} _ast : A lowered script
/// @returns {Struct} {functions: [{fn_id, name, nodes: [{id, kind, start, succ, exc}], defs: [{id, node, name}],
///          reaching: [[def id]], live: [[name]], alias: [{name, sites}]}]}
#endregion
function gmlc_analyses(_ast) {
	var _units = [{ fn_id: 0, params: [], body: _ast.body, node: undefined }];
	__gmlc_analysis_units(_ast, _units);
	array_sort(_units, __gmlc_compare_fn_id);
	var _out = [];
	var _u = 0; repeat (array_length(_units)) {
		var _unit = _units[_u];
		var _info = (_unit.fn_id < array_length(_ast.functions)) ? _ast.functions[_unit.fn_id] : undefined;
		var _name = ((_info != undefined) && (_info.name != undefined)) ? _info.name : "";
		array_push(_out, __gmlc_analyze(_unit, _name));
	_u++}
	return { functions: _out };
}

#region jsDoc
/// @func    __gmlc_analysis_units(_node, _out)
/// @desc    Adds every function under a node to the list of units to analyze.
/// @param   {Struct.ASTNode} _node : The node
/// @param   {Array<Struct>}  _out  : The units {fn_id, params, body, node}
#endregion
function __gmlc_analysis_units(_node, _out) {
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				var _kind = _child.kind;
				if (_kind == __GMLC_NodeKind_FunctionDecl) || (_kind == __GMLC_NodeKind_ConstructorDecl) || (_kind == __GMLC_NodeKind_FunctionExpr) {
					var _params = [];
					var _p = 0; repeat (array_length(_child.params)) {
						array_push(_params, _child.params[_p].target);
					_p++}
					array_push(_out, { fn_id: _child[$ "fn_id"] ?? (1000000 + array_length(_out)), params: _params, body: _child.body.body, node: _child });
				}
				__gmlc_analysis_units(_child, _out);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_analyze(_unit, _name)
/// @desc    The analyses of one function: graph, reaching definitions, liveness and alias classes.
/// @param   {Struct} _unit : {fn_id, params, body, node}
/// @param   {String} _name : The function's name
/// @returns {Struct}
#endregion
function __gmlc_analyze(_unit, _name) {
	var _g = __gmlc_analysis_graph(_unit);
	var _n = array_length(_g.nodes);
	var _i;
	var _nodes = [];
	var _preds = array_create(_n);
	var _excPreds = array_create(_n);
	_i = 0; repeat (_n) {
		_preds[_i] = [];
		_excPreds[_i] = [];
	_i++}
	_i = 0; repeat (_n) {
		var _node = _g.nodes[_i];
		var _s = 0; repeat (array_length(_node.succ)) { array_push(_preds[_node.succ[_s]], _i); _s++ }
		_s = 0; repeat (array_length(_node.exc)) { array_push(_excPreds[_node.exc[_s]], _i); _s++ }
		array_push(_nodes, { id: _i, kind: _node.kind, start: _node.start, succ: _node.succ, exc: _node.exc });
	_i++}
	var _defs = [];
	var _gen = array_create(_n);
	var _killed = array_create(_n);
	_i = 0; repeat (_n) {
		var _events = _g.events[_i];
		var _list = []; // the definitions of the node that no later certain one of the same name replaces
		var _names = [];
		var _e = 0; repeat (array_length(_events)) {
			var _ev = _events[_e];
			if (_ev.def) {
				var _id = array_length(_defs);
				array_push(_defs, { id: _id, node: _i, name: _ev.name });
				if (!_ev.maybe) {
					var _kept = [];
					var _k = 0; repeat (array_length(_list)) {
						if (_defs[_list[_k]].name != _ev.name) array_push(_kept, _list[_k]);
					_k++}
					_list = _kept;
					if (!array_contains(_names, _ev.name)) array_push(_names, _ev.name);
				}
				array_push(_list, _id);
			}
		_e++}
		_gen[_i] = __gmlc_sorted_set(_list);
		_killed[_i] = _names;
	_i++}
	var _in = array_create(_n);
	var _outs = array_create(_n);
	_i = 0; repeat (_n) {
		_in[_i] = [];
		_outs[_i] = _gen[_i];
	_i++}
	var _changed = true;
	while (_changed) {
		_changed = false;
		_i = 0; repeat (_n) {
			var _set = [];
			var _q = 0; repeat (array_length(_preds[_i])) {
				_set = __gmlc_sorted_union(_set, _outs[_preds[_i][_q]]);
			_q++}
			// a statement that throws may have run any part of itself: what reaches it and what leaves it
			_q = 0; repeat (array_length(_excPreds[_i])) {
				var _from = _excPreds[_i][_q];
				_set = __gmlc_sorted_union(_set, __gmlc_sorted_union(_in[_from], _outs[_from]));
			_q++}
			var _kept = [];
			var _d = 0; repeat (array_length(_set)) {
				if (!array_contains(_killed[_i], _defs[_set[_d]].name)) array_push(_kept, _set[_d]);
			_d++}
			var _o = __gmlc_sorted_union(_gen[_i], _kept);
			if (!array_equals(_set, _in[_i])) || (!array_equals(_o, _outs[_i])) {
				_in[_i] = _set;
				_outs[_i] = _o;
				_changed = true;
			}
		_i++}
	}
	var _use = array_create(_n);
	_i = 0; repeat (_n) {
		var _events = _g.events[_i];
		var _written = [];
		var _read = [];
		var _e = 0; repeat (array_length(_events)) {
			var _ev = _events[_e];
			if (_ev.def) {
				if (!_ev.maybe) && (!array_contains(_written, _ev.name)) array_push(_written, _ev.name);
			}
			else if (!array_contains(_written, _ev.name)) && (!array_contains(_read, _ev.name)) {
				array_push(_read, _ev.name);
			}
		_e++}
		_use[_i] = _read;
	_i++}
	var _live = array_create(_n);
	_i = 0; repeat (_n) {
		_live[_i] = [];
	_i++}
	_changed = true;
	while (_changed) {
		_changed = false;
		_i = _n - 1; repeat (_n) {
			var _node = _g.nodes[_i];
			var _outSet = [];
			var _s = 0; repeat (array_length(_node.succ)) { _outSet = __gmlc_sorted_union(_outSet, _live[_node.succ[_s]]); _s++ }
			// what a handler reads is live before the statement that may throw to it, whatever that statement writes
			var _set = __gmlc_sorted_union([], _use[_i]);
			_s = 0; repeat (array_length(_node.exc)) { _set = __gmlc_sorted_union(_set, _live[_node.exc[_s]]); _s++ }
			var _k = 0; repeat (array_length(_outSet)) {
				if (!array_contains(_killed[_i], _outSet[_k])) _set = __gmlc_sorted_union(_set, [_outSet[_k]]);
			_k++}
			if (!array_equals(_set, _live[_i])) {
				_live[_i] = _set;
				_changed = true;
			}
		_i--}
	}
	return { fn_id: _unit.fn_id, name: _name, nodes: _nodes, defs: _defs, reaching: _in, live: _live, alias: __gmlc_alias_classes(_g) };
}

#region jsDoc
/// @func    __gmlc_analyze_alias(_unit)
/// @desc    Only the alias classes of one function, as __gmlc_analyze gives them, without its reaching definitions
///          and liveness.
/// @param   {Struct} _unit : {fn_id, params, body, node}
/// @returns {Array<Struct>} {name, sites} per local that may hold a reference, by name
#endregion
function __gmlc_analyze_alias(_unit) {
	return __gmlc_alias_classes(__gmlc_analysis_graph(_unit));
}

#region jsDoc
/// @func    __gmlc_analysis_graph(_unit)
/// @desc    The control-flow graph of one function with the definitions and reads of each node and the alias pairs.
/// @param   {Struct} _unit : {fn_id, params, body, node}
/// @returns {Struct} {nodes, frames, tries, finals, events, pairs}
#endregion
function __gmlc_analysis_graph(_unit) {
	var _g = __gmlc_cfg_build(_unit);
	var _n = array_length(_g.nodes);
	var _i = 0; repeat (_n) {
		_g.events[_i] = [];
	_i++}
	var _p = 0; repeat (array_length(_unit.params)) {
		__gmlc_event_def(_g, 0, _unit.params[_p]);
		__gmlc_alias_pair(_g, _unit.params[_p], undefined);
	_p++}
	_i = 2; repeat (_n - 2) {
		__gmlc_node_events(_g, _i);
	_i++}
	return _g;
}

#region jsDoc
/// @func    __gmlc_alias_classes(_g)
/// @desc    The allocation sites each local of a graph's alias pairs may hold, by name, locals with none left out.
/// @param   {Struct} _g : The graph (__gmlc_analysis_graph)
/// @returns {Array<Struct>} {name, sites}
#endregion
function __gmlc_alias_classes(_g) {
	var _sites = {};
	var _changed = true;
	while (_changed) {
		_changed = false;
		var _q = 0; repeat (array_length(_g.pairs)) {
			var _pair = _g.pairs[_q];
			var _now = _sites[$ _pair.name] ?? [];
			var _add = __gmlc_sorted_union(_now, __gmlc_alias_sites(_pair.value, _sites));
			if (!array_equals(_add, _now)) {
				_sites[$ _pair.name] = _add;
				_changed = true;
			}
		_q++}
	}
	var _alias = [];
	var _names = struct_get_names(_sites);
	array_sort(_names, true);
	var _k = 0; repeat (array_length(_names)) {
		if (array_length(_sites[$ _names[_k]]) > 0) array_push(_alias, { name: _names[_k], sites: _sites[$ _names[_k]] });
	_k++}
	return _alias;
}

#region Control-Flow Graph
#region jsDoc
/// @func    __gmlc_cfg_build(_unit)
/// @desc    The statement control-flow graph of one function, with entry node 0 and exit node 1.
/// @param   {Struct} _unit : {fn_id, params, body, node}
/// @returns {Struct} {nodes, frames, tries, finals, events, pairs}
#endregion
function __gmlc_cfg_build(_unit) {
	var _g = { nodes: [], frames: [], tries: [], finals: [], events: [], pairs: [] };
	var _entry = __gmlc_cfg_node(_g, "entry", -1, undefined);
	var _exit = __gmlc_cfg_node(_g, "exit", -1, undefined);
	var _body = __gmlc_cfg_list(_g, _unit.body);
	__gmlc_cfg_link(_g, [_entry], (_body.entry >= 0) ? _body.entry : _exit);
	__gmlc_cfg_link(_g, (_body.entry >= 0) ? _body.exits : [], _exit);
	var _i = 0; repeat (array_length(_g.nodes)) {
		var _node = _g.nodes[_i];
		_node.succ = __gmlc_sorted_set(_node.succ);
		_node.exc = __gmlc_sorted_set(_node.exc);
	_i++}
	return _g;
}

#region jsDoc
/// @func    __gmlc_cfg_node(_g, _kind, _start, _stmt)
/// @desc    A new graph node; inside a try body it may throw to that try's handler, linked when the
///          handler's node exists.
/// @param   {Struct}         _g     : The graph being built
/// @param   {String}         _kind  : The node's kind
/// @param   {Real}           _start : Source offset, -1 for entry and exit
/// @param   {Struct.ASTNode} _stmt  : The statement, undefined for entry and exit
/// @returns {Real} The node's id
#endregion
function __gmlc_cfg_node(_g, _kind, _start, _stmt) {
	var _id = array_length(_g.nodes);
	array_push(_g.nodes, { kind: _kind, start: _start, stmt: _stmt, succ: [], exc: [] });
	var _t = array_length(_g.tries);
	if (_t > 0) array_push(_g.tries[_t - 1], _id);
	return _id;
}

#region jsDoc
/// @func    __gmlc_cfg_link(_g, _from, _to)
/// @desc    Adds an edge from each of some nodes to one node.
/// @param   {Struct}      _g    : The graph being built
/// @param   {Array<Real>} _from : The nodes
/// @param   {Real}        _to   : The target
#endregion
function __gmlc_cfg_link(_g, _from, _to) {
	var _i = 0; repeat (array_length(_from)) {
		array_push(_g.nodes[_from[_i]].succ, _to);
	_i++}
}

#region jsDoc
/// @func    __gmlc_cfg_leave(_g, _from)
/// @desc    Links nodes that leave the function: to the innermost finally, else to the exit.
/// @param   {Struct}      _g    : The graph being built
/// @param   {Array<Real>} _from : The nodes
#endregion
function __gmlc_cfg_leave(_g, _from) {
	var _f = array_length(_g.finals);
	if (_f > 0) _g.finals[_f - 1].jumps = array_concat(_g.finals[_f - 1].jumps, _from);
	else __gmlc_cfg_link(_g, _from, 1);
}

#region jsDoc
/// @func    __gmlc_cfg_list(_g, _stmts)
/// @desc    Adds the nodes of a statement list, each statement's exits linked to the next statement.
/// @param   {Struct}                _g     : The graph being built
/// @param   {Array<Struct.ASTNode>} _stmts : The statements
/// @returns {Struct} {entry, exits}, entry -1 when the list has no statement
#endregion
function __gmlc_cfg_list(_g, _stmts) {
	var _entry = -1;
	var _exits = [];
	var _i = 0; repeat (array_length(_stmts)) {
		var _part = __gmlc_cfg_stmt(_g, _stmts[_i]);
		if (_part.entry >= 0) {
			if (_entry < 0) _entry = _part.entry;
			else __gmlc_cfg_link(_g, _exits, _part.entry);
			_exits = _part.exits;
		}
	_i++}
	return { entry: _entry, exits: _exits };
}

#region jsDoc
/// @func    __gmlc_cfg_into(_part, _otherwise)
/// @desc    The entry of a part, or another node when the part is empty.
/// @param   {Struct} _part      : {entry, exits}
/// @param   {Real}   _otherwise : The node
/// @returns {Real}
#endregion
function __gmlc_cfg_into(_part, _otherwise) {
	return (_part.entry >= 0) ? _part.entry : _otherwise;
}

#region jsDoc
/// @func    __gmlc_cfg_loop(_g, _kind)
/// @desc    Opens a frame that collects break (and for a loop continue) nodes.
/// @param   {Struct} _g    : The graph being built
/// @param   {Bool}   _kind : True for a loop, false for a switch
/// @returns {Struct} {loop, breaks, continues}
#endregion
function __gmlc_cfg_loop(_g, _kind) {
	var _frame = { loop: _kind, breaks: [], continues: [] };
	array_push(_g.frames, _frame);
	return _frame;
}

#region jsDoc
/// @func    __gmlc_cfg_stmt(_g, _stmt)
/// @desc    Adds the nodes of one statement and its parts.
/// @param   {Struct}         _g    : The graph being built
/// @param   {Struct.ASTNode} _stmt : The statement
/// @returns {Struct} {entry, exits}, entry -1 for an empty block
#endregion
function __gmlc_cfg_stmt(_g, _stmt) {
	switch (_stmt.kind) {
		case __GMLC_NodeKind_Block:
			return __gmlc_cfg_list(_g, _stmt.body);
		case __GMLC_NodeKind_If: {
			var _n = __gmlc_cfg_node(_g, _stmt.kindName, _stmt.span.start, _stmt);
			var _then = __gmlc_cfg_list(_g, _stmt.consequent.body);
			var _else = (_stmt.alternate != undefined) ? __gmlc_cfg_list(_g, _stmt.alternate.body) : { entry: -1, exits: [] };
			var _exits = [];
			if (_then.entry >= 0) {
				__gmlc_cfg_link(_g, [_n], _then.entry);
				_exits = _then.exits;
			}
			else array_push(_exits, _n);
			if (_else.entry >= 0) {
				__gmlc_cfg_link(_g, [_n], _else.entry);
				_exits = array_concat(_exits, _else.exits);
			}
			else if (!array_contains(_exits, _n)) array_push(_exits, _n);
			return { entry: _n, exits: _exits };
		}
		case __GMLC_NodeKind_While:
		case __GMLC_NodeKind_Repeat:
		case __GMLC_NodeKind_With: {
			var _n = __gmlc_cfg_node(_g, _stmt.kindName, _stmt.span.start, _stmt);
			var _frame = __gmlc_cfg_loop(_g, true);
			var _b = __gmlc_cfg_list(_g, _stmt.body.body);
			array_pop(_g.frames);
			__gmlc_cfg_link(_g, [_n], __gmlc_cfg_into(_b, _n));
			__gmlc_cfg_link(_g, _b.exits, _n);
			__gmlc_cfg_link(_g, _frame.continues, _n);
			return { entry: _n, exits: array_concat([_n], _frame.breaks) };
		}
		case __GMLC_NodeKind_DoUntil: {
			var _n = __gmlc_cfg_node(_g, _stmt.kindName, _stmt.span.start, _stmt);
			var _frame = __gmlc_cfg_loop(_g, true);
			var _b = __gmlc_cfg_list(_g, _stmt.body.body);
			array_pop(_g.frames);
			__gmlc_cfg_link(_g, [_n], __gmlc_cfg_into(_b, _n));
			__gmlc_cfg_link(_g, _b.exits, _n);
			__gmlc_cfg_link(_g, _frame.continues, _n);
			return { entry: __gmlc_cfg_into(_b, _n), exits: array_concat([_n], _frame.breaks) };
		}
		case __GMLC_NodeKind_For: {
			var _n = __gmlc_cfg_node(_g, _stmt.kindName, _stmt.span.start, _stmt);
			var _init = (_stmt.init != undefined) ? __gmlc_cfg_stmt(_g, _stmt.init) : { entry: -1, exits: [] };
			var _frame = __gmlc_cfg_loop(_g, true);
			var _b = __gmlc_cfg_list(_g, _stmt.body.body);
			array_pop(_g.frames);
			var _update = (_stmt.update != undefined) ? __gmlc_cfg_stmt(_g, _stmt.update) : { entry: -1, exits: [] };
			var _step = __gmlc_cfg_into(_update, _n);
			__gmlc_cfg_link(_g, _init.exits, _n);
			__gmlc_cfg_link(_g, [_n], __gmlc_cfg_into(_b, _step));
			__gmlc_cfg_link(_g, _b.exits, _step);
			__gmlc_cfg_link(_g, _frame.continues, _step);
			__gmlc_cfg_link(_g, _update.exits, _n);
			return { entry: __gmlc_cfg_into(_init, _n), exits: array_concat([_n], _frame.breaks) };
		}
		case __GMLC_NodeKind_Switch: {
			var _n = __gmlc_cfg_node(_g, _stmt.kindName, _stmt.span.start, _stmt);
			var _frame = __gmlc_cfg_loop(_g, false);
			var _tail = [];
			var _default = false;
			var _c = 0; repeat (array_length(_stmt.cases)) {
				var _case = _stmt.cases[_c];
				if (_case.kind == __GMLC_NodeKind_Default) _default = true;
				var _label = __gmlc_cfg_node(_g, _case.kindName, _case.span.start, _case);
				__gmlc_cfg_link(_g, [_n], _label);
				__gmlc_cfg_link(_g, _tail, _label);
				var _b = __gmlc_cfg_list(_g, _case.body);
				if (_b.entry >= 0) {
					__gmlc_cfg_link(_g, [_label], _b.entry);
					_tail = _b.exits;
				}
				else _tail = [_label];
			_c++}
			array_pop(_g.frames);
			var _exits = array_concat(_tail, _frame.breaks);
			if (!_default) array_push(_exits, _n);
			// continue inside a switch belongs to the loop around it
			var _f = array_length(_g.frames) - 1;
			while (_f >= 0) && (!_g.frames[_f].loop) _f--;
			if (_f >= 0) _g.frames[_f].continues = array_concat(_g.frames[_f].continues, _frame.continues);
			return { entry: _n, exits: _exits };
		}
		case __GMLC_NodeKind_Try: {
			var _n = __gmlc_cfg_node(_g, _stmt.kindName, _stmt.span.start, _stmt);
			var _final = (_stmt.finally_body != undefined) ? { jumps: [] } : undefined;
			if (_final != undefined) array_push(_g.finals, _final);
			array_push(_g.tries, []);
			var _b = __gmlc_cfg_list(_g, _stmt.block.body);
			var _throwing = array_pop(_g.tries);
			if (_b.entry >= 0) __gmlc_cfg_link(_g, [_n], _b.entry);
			var _exits = (_b.entry >= 0) ? _b.exits : [_n];
			var _handler = -1;
			var _catchThrowing = [];
			if (_stmt.catch_body != undefined) {
				var _k = __gmlc_cfg_node(_g, "catch", _stmt.catch_body.span.start, _stmt);
				_handler = _k;
				// with a finally, what the catch body throws goes there first
				if (_final != undefined) array_push(_g.tries, []);
				var _kb = __gmlc_cfg_list(_g, _stmt.catch_body.body);
				if (_final != undefined) _catchThrowing = array_pop(_g.tries);
				if (_kb.entry >= 0) __gmlc_cfg_link(_g, [_k], _kb.entry);
				_exits = array_concat(_exits, (_kb.entry >= 0) ? _kb.exits : [_k]);
			}
			if (_final != undefined) {
				array_pop(_g.finals);
				var _f = __gmlc_cfg_node(_g, "finally", _stmt.finally_body.span.start, _stmt);
				if (_handler < 0) _handler = _f;
				__gmlc_cfg_link(_g, _exits, _f);
				__gmlc_cfg_link(_g, _final.jumps, _f);
				var _c = 0; repeat (array_length(_catchThrowing)) {
					array_push(_g.nodes[_catchThrowing[_c]].exc, _f);
				_c++}
				var _fb = __gmlc_cfg_list(_g, _stmt.finally_body.body);
				if (_fb.entry >= 0) __gmlc_cfg_link(_g, [_f], _fb.entry);
				_exits = (_fb.entry >= 0) ? _fb.exits : [_f];
				// a return through the finally leaves the function after it
				if (array_length(_final.jumps) > 0) __gmlc_cfg_leave(_g, _exits);
			}
			if (_handler >= 0) {
				var _t = 0; repeat (array_length(_throwing)) {
					array_push(_g.nodes[_throwing[_t]].exc, _handler);
				_t++}
			}
			return { entry: _n, exits: _exits };
		}
		case __GMLC_NodeKind_Break:
		case __GMLC_NodeKind_Continue: {
			var _n = __gmlc_cfg_node(_g, _stmt.kindName, _stmt.span.start, _stmt);
			var _f = array_length(_g.frames) - 1;
			if (_stmt.kind == __GMLC_NodeKind_Continue) {
				if (_f >= 0) array_push(_g.frames[_f].continues, _n);
			}
			else if (_f >= 0) array_push(_g.frames[_f].breaks, _n);
			return { entry: _n, exits: [] };
		}
		case __GMLC_NodeKind_Return:
		case __GMLC_NodeKind_Exit:
		case __GMLC_NodeKind_Throw: {
			var _n = __gmlc_cfg_node(_g, _stmt.kindName, _stmt.span.start, _stmt);
			// a throw inside a try goes to its handler only
			if (_stmt.kind != __GMLC_NodeKind_Throw) || (array_length(_g.tries) == 0) __gmlc_cfg_leave(_g, [_n]);
			return { entry: _n, exits: [] };
		}
	}
	var _n = __gmlc_cfg_node(_g, _stmt.kindName, _stmt.span.start, _stmt);
	return { entry: _n, exits: [_n] };
}
#endregion

#region Reads and Writes
#region jsDoc
/// @func    __gmlc_node_events(_g, _id)
/// @desc    Records the locals a node's own expressions read and write (a compound statement's test, never its
///          statements).
/// @param   {Struct} _g  : The graph
/// @param   {Real}   _id : The node
#endregion
function __gmlc_node_events(_g, _id) {
	var _node = _g.nodes[_id];
	var _stmt = _node.stmt;
	if (_stmt == undefined) return;
	switch (_node.kind) {
		case "catch":
			if (_stmt.catch_param != undefined) {
				__gmlc_event_def(_g, _id, _stmt.catch_param);
				__gmlc_alias_pair(_g, _stmt.catch_param, undefined);
			}
			return;
		case "finally": return;
	}
	switch (_stmt.kind) {
		case __GMLC_NodeKind_If: case __GMLC_NodeKind_While: case __GMLC_NodeKind_DoUntil: case __GMLC_NodeKind_Case:
			__gmlc_walk_events(_g, _id, _stmt.test); return;
		case __GMLC_NodeKind_For:
			if (_stmt.test != undefined) __gmlc_walk_events(_g, _id, _stmt.test);
			return;
		case __GMLC_NodeKind_Repeat: __gmlc_walk_events(_g, _id, _stmt.count); return;
		case __GMLC_NodeKind_With: __gmlc_walk_events(_g, _id, _stmt.target); return;
		case __GMLC_NodeKind_Switch: __gmlc_walk_events(_g, _id, _stmt.discriminant); return;
		case __GMLC_NodeKind_Try: case __GMLC_NodeKind_Default: return;
		case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl: return;
	}
	__gmlc_walk_events(_g, _id, _stmt);
}

#region jsDoc
/// @func    __gmlc_event_def(_g, _id, _target, [_maybe])
/// @desc    Records a write of a node's local target.
/// @param   {Struct}         _g       : The graph
/// @param   {Real}           _id      : The node that writes
/// @param   {Struct.ASTNode} _target  : The written expression (only a local is recorded)
/// @param   {Bool}           [_maybe] : The write may not happen (the right of && and ||, a branch of ?:, ??=)
#endregion
function __gmlc_event_def(_g, _id, _target, _maybe = false) {
	if (__gmlc_opt_is_local(_target)) array_push(_g.events[_id], { def: true, name: _target.name, maybe: _maybe });
}

#region jsDoc
/// @func    __gmlc_alias_pair(_g, _target, _value)
/// @desc    Records that a local target takes a value, for the alias classes.
/// @param   {Struct}         _g      : The graph
/// @param   {Struct.ASTNode} _target : The written expression (only a local is recorded)
/// @param   {Struct.ASTNode} _value  : The value, undefined for a parameter
#endregion
function __gmlc_alias_pair(_g, _target, _value) {
	if (__gmlc_opt_is_local(_target)) array_push(_g.pairs, { name: _target.name, value: _value });
}

#region jsDoc
/// @func    __gmlc_walk_events(_g, _id, _node, [_maybe])
/// @desc    Records the locals an expression reads and writes, in evaluation order.
/// @param   {Struct}         _g       : The graph
/// @param   {Real}           _id      : The node
/// @param   {Struct.ASTNode} _node    : The expression
/// @param   {Bool}           [_maybe] : The writes may not happen
#endregion
function __gmlc_walk_events(_g, _id, _node, _maybe = false) {
	if (_node == undefined) return;
	switch (_node.kind) {
		case __GMLC_NodeKind_FunctionExpr: case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl:
			return;
		case __GMLC_NodeKind_Identifier:
			if (__gmlc_opt_is_local(_node)) array_push(_g.events[_id], { def: false, name: _node.name, maybe: _maybe });
			return;
		case __GMLC_NodeKind_VarDecl:
			__gmlc_walk_events(_g, _id, _node.init, _maybe);
			__gmlc_event_def(_g, _id, _node.target, _maybe);
			__gmlc_alias_pair(_g, _node.target, _node.init);
			return;
		case __GMLC_NodeKind_Assign:
			if (__gmlc_opt_is_local(_node.target)) {
				if (_node.op != "=") __gmlc_walk_events(_g, _id, _node.target, _maybe);
				__gmlc_walk_events(_g, _id, _node.value, _maybe || (_node.op == "??="));
				__gmlc_event_def(_g, _id, _node.target, _maybe || (_node.op == "??="));
				if (_node.op == "=") || (_node.op == "??=") __gmlc_alias_pair(_g, _node.target, _node.value);
				return;
			}
			__gmlc_walk_events(_g, _id, _node.target, _maybe);
			__gmlc_walk_events(_g, _id, _node.value, _maybe);
			return;
		case __GMLC_NodeKind_Update:
			__gmlc_walk_events(_g, _id, _node.argument, _maybe);
			__gmlc_event_def(_g, _id, _node.argument, _maybe);
			return;
		case __GMLC_NodeKind_Logical:
			__gmlc_walk_events(_g, _id, _node.left, _maybe);
			__gmlc_walk_events(_g, _id, _node.right, _maybe || (_node.op != "^^"));
			return;
		case __GMLC_NodeKind_Nullish:
			__gmlc_walk_events(_g, _id, _node.left, _maybe);
			__gmlc_walk_events(_g, _id, _node.right, true);
			return;
		case __GMLC_NodeKind_Conditional:
			__gmlc_walk_events(_g, _id, _node.test, _maybe);
			__gmlc_walk_events(_g, _id, _node.consequent, true);
			__gmlc_walk_events(_g, _id, _node.alternate, true);
			return;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_walk_events(_g, _id, _child, _maybe);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_alias_sites(_node, _sites)
/// @desc    The allocation sites a value may hold, from the sites found so far for each local.
/// @param   {Struct.ASTNode} _node  : The value, undefined for a parameter
/// @param   {Struct}         _sites : The sites per local name
/// @returns {Array<String>} The allocation sites a value may be: "unknown" for parameters, calls and non-local reads
#endregion
function __gmlc_alias_sites(_node, _sites) {
	if (_node == undefined) return ["unknown"];
	switch (_node.kind) {
		case __GMLC_NodeKind_ArrayLiteral: return ["array@" + string(_node.span.start)];
		case __GMLC_NodeKind_StructLiteral: return ["struct@" + string(_node.span.start)];
		case __GMLC_NodeKind_New: return ["new@" + string(_node.span.start)];
		case __GMLC_NodeKind_Call:
			if (_node.callee.kind == __GMLC_NodeKind_Identifier) && ((_node.callee.name == "array_create") || (_node.callee.name == "json_parse")) {
				return [_node.callee.name + "@" + string(_node.span.start)];
			}
			return ["unknown"];
		case __GMLC_NodeKind_Identifier:
			if (__gmlc_opt_is_local(_node)) return _sites[$ _node.name] ?? [];
			return ["unknown"];
		case __GMLC_NodeKind_Conditional:
			return __gmlc_sorted_union(__gmlc_alias_sites(_node.consequent, _sites), __gmlc_alias_sites(_node.alternate, _sites));
		case __GMLC_NodeKind_Nullish:
			return __gmlc_sorted_union(__gmlc_alias_sites(_node.left, _sites), __gmlc_alias_sites(_node.right, _sites));
		case __GMLC_NodeKind_Literal: case __GMLC_NodeKind_Binary: case __GMLC_NodeKind_Unary: case __GMLC_NodeKind_Update:
		case __GMLC_NodeKind_Logical: case __GMLC_NodeKind_TemplateString: case __GMLC_NodeKind_FunctionExpr:
			return [];
	}
	return ["unknown"];
}
#endregion

#region Sets
#region jsDoc
/// @func    __gmlc_sorted_set(_values)
/// @desc    The values of an array, each once, sorted.
/// @param   {Array<Real>|Array<String>} _values : The values
/// @returns {Array}
#endregion
function __gmlc_sorted_set(_values) {
	var _out = array_unique(_values);
	array_sort(_out, true);
	return _out;
}

#region jsDoc
/// @func    __gmlc_sorted_union(_a, _b)
/// @desc    The sorted union of two sets of ids or names.
/// @param   {Array<Real>|Array<String>} _a : A set
/// @param   {Array<Real>|Array<String>} _b : A set
/// @returns {Array}
#endregion
function __gmlc_sorted_union(_a, _b) {
	return __gmlc_sorted_set(array_concat(_a, _b));
}
#endregion
#endregion

#region jsDoc
/// @func    __gmlc_temporary_names(_sources)
/// @desc    The names of the form `__gmlc_t<digits>` anywhere in the text of a compile's files, as keys.
/// @param   {Struct.GMLC_SourceTable} _sources : The files
/// @returns {Struct}
#endregion
function __gmlc_temporary_names(_sources) {
	var _names = {};
	var _f = 0; repeat (array_length(_sources.files)) {
		var _file = _sources.files[_f];
		if (_file != undefined) {
			var _text = _file.source;
			var _length = string_length(_text);
			var _at = string_pos("__gmlc_t", _text);
			while (_at > 0) {
				var _end = _at + 8;
				while (_end <= _length) && (string_digits(string_char_at(_text, _end)) != "") _end++;
				if (_end > _at + 8) _names[$ string_copy(_text, _at, _end - _at)] = true;
				_at = string_pos_ext("__gmlc_t", _text, _end - 1);
			}
		}
	_f++}
	return _names;
}
