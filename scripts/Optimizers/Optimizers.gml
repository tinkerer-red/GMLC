#region Clean

#region jsDoc
/// @function optimizer_unary_expression_simplify(_ast_node)
/// @description
/// Simplifies unary expressions (constant folding, identity rules) when the result can be proven.
/// Only rewrites when the operand has no side effects or the evaluation behavior is kept.
///
/// Example:
/// Before: var _value = -5;
/// After:  var _value = -5;
///
/// Example:
/// Before: var _value = !true;
/// After:  var _value = false;
///
/// Example:
/// Before: var _value = ~0;
/// After:  var _value = -1;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_unary_expression_simplify(_ast_node) {
}

#region jsDoc
/// @function optimizer_binary_expression_simplify(_ast_node)
/// @description
/// Simplifies arithmetic, comparison, boolean, bitwise and nullish binary expressions: constant folding,
/// identity, absorbing and short-circuit rules. Never removes, reorders or skips an operand with side effects
/// unless the original operator would also skip it.
///
/// Example:
/// Before: var _value = 2 + 3 * 4;
/// After:  var _value = 14;
///
/// Example:
/// Before: var _value = _count + 0;
/// After:  var _value = _count;
///
/// Example:
/// Before: if (_is_ready == true) { run(); }
/// After:  if (_is_ready) { run(); }
///
/// Example:
/// Before: if (false && expensive_check()) { run(); }
/// After:  if (false) { run(); }
///
/// Example:
/// Before: var _value = undefined ?? _fallback;
/// After:  var _value = _fallback;
///
/// Example:
/// Before: var _flags = 4 | 2;
/// After:  var _flags = 6;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_binary_expression_simplify(_ast_node) {
}

#region jsDoc
/// @function optimizer_ternary_expression_simplify(_ast_node)
/// @description
/// Simplifies ternary expressions with known or redundant branches.
/// Must keep branch laziness: the unused branch is never evaluated, moved or exposed.
///
/// Example:
/// Before: var _value = true ? 10 : 20;
/// After:  var _value = 10;
///
/// Example:
/// Before: var _value = _enabled ? true : false;
/// After:  var _value = _enabled;
///
/// Example:
/// Before: var _value = _enabled ? false : true;
/// After:  var _value = !_enabled;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_ternary_expression_simplify(_ast_node) {
}

#region jsDoc
/// @function optimizer_compile_time_variable(_ast_node)
/// @description
/// Replaces identifiers the environment marks compileTimeConstant with the value of their compileTimeGet
/// resolver in the current compile context. Never guesses from variable names.
///
/// Example:
/// Before: var _file_name = _GMFILE_;
/// After:  var _file_name = "scr_player_init.gml";
///
/// Example:
/// Before: var _line_number = _GMLINE_;
/// After:  var _line_number = 42;
///
/// Example:
/// Before: var _function_name = _GMFUNCTION_;
/// After:  var _function_name = "player_init";
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_compile_time_variable(_ast_node) {
}

#region jsDoc
/// @function optimizer_compile_time_function(_ast_node)
/// @description
/// Folds or rewrites calls whose resolved callable declares compile-time metadata, producing a literal or a
/// replacement node. Never assumes a name refers to a native GameMaker built-in.
///
/// Example:
/// Before: var _hash_value = compile_time_hash("health");
/// After:  var _hash_value = 123456;
///
/// Example:
/// Before: var _name = compile_time_resource_name(obj_player);
/// After:  var _name = "obj_player";
///
/// Example:
/// Before: struct_get(_data, "health");
/// After:  struct_get_from_hash(_data, 123456);
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_compile_time_function(_ast_node) {
}

#region jsDoc
/// @function optimizer_string_literal_merge(_ast_node)
/// @description
/// Merges directly concatenated string literals.
/// Mixed values are only folded once GameMaker's exact conversion is modeled.
///
/// Example:
/// Before: var _text = "Hello, " + "world";
/// After:  var _text = "Hello, world";
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_string_literal_merge(_ast_node) {
}

#region jsDoc
/// @function optimizer_dead_branch_remove(_ast_node)
/// @description
/// Removes if, else-if, ternary and switch branches whose path is known at compile time.
/// A condition with side effects is still kept in the output.
///
/// Example:
/// Before: if (false) { run(); } else { idle(); }
/// After:  idle();
///
/// Example:
/// Before: if (DEBUG_ENABLED) { show_debug_message("debug"); }
/// After:  // removed when DEBUG_ENABLED is known false
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_dead_branch_remove(_ast_node) {
}

#region jsDoc
/// @function optimizer_unreachable_code_remove(_ast_node)
/// @description
/// Removes statements after return, break, continue, exit and other terminators.
/// Never crosses function, method, constructor or event boundaries.
///
/// Example:
/// Before: return _value; show_debug_message("never runs");
/// After:  return _value;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_unreachable_code_remove(_ast_node) {
}

#region jsDoc
/// @function optimizer_empty_block_remove(_ast_node)
/// @description
/// Removes empty blocks and branches, keeping any expression that still needs to run.
///
/// Example:
/// Before: if (false) { }
/// After:  // removed
///
/// Example:
/// Before: if (foo_bar) { }
/// After:  // removed
///
/// Example:
/// Before: if (check_ready()) { }
/// After:  check_ready();
///
/// Example:
/// Before: if (_is_ready) { } else { run(); }
/// After:  if (!_is_ready) { run(); }
///
/// Example:
/// Before: repeat (0) { }
/// After:  // removed
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_empty_block_remove(_ast_node) {
}

#region jsDoc
/// @function optimizer_redundant_else_remove(_ast_node)
/// @description
/// Removes the else block after an if branch that always exits, turning it into sequential flow.
///
/// Example:
/// Before: if (_failed) { return false; } else { run(); }
/// After:  if (_failed) { return false; } run();
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_redundant_else_remove(_ast_node) {
}

#region jsDoc
/// @function optimizer_block_flatten(_ast_node)
/// @description
/// Flattens nested blocks with no control-flow or scope role, mostly for the compiled executable output.
/// Avoids function, method, constructor, with, switch, loop and event boundaries unless supported.
///
/// Example:
/// Before: { { var _value = 10; } }
/// After:  { var _value = 10; }
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_block_flatten(_ast_node) {
}

#region jsDoc
/// @function optimizer_condition_merge(_ast_node)
/// @description
/// Merges an outer if that only contains another if into one short-circuit condition.
///
/// Example:
/// Before: if (_ready) { if (_visible) { draw_self(); } }
/// After:  if (_ready && _visible) { draw_self(); }
///
/// Example:
/// Before: if (_a) { if (_b) { if (_c) { run(); } } }
/// After:  if (_a && _b && _c) { run(); }
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_condition_merge(_ast_node) {
}

#region jsDoc
/// @function optimizer_branch_invert(_ast_node)
/// @description
/// Swaps if and else branches by negating the condition when that simplifies control flow,
/// such as an early return first. Never reorders side effects.
///
/// Example:
/// Before: if (!_ready) { return; } else { run(); }
/// After:  if (_ready) { run(); } else { return; }
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_branch_invert(_ast_node) {
}

#endregion

#region Safe

#region jsDoc
/// @function optimizer_constant_propagate(_ast_node)
/// @description
/// Replaces local reads with known constant values assigned from literals or compile-time constants.
/// Stops tracking once the local is reassigned or control flow becomes unclear.
///
/// Example:
/// Before: var _size = 8; var _area = _size * _size;
/// After:  var _size = 8; var _area = 8 * 8;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_constant_propagate(_ast_node) {
}

#region jsDoc
/// @function optimizer_copy_propagate(_ast_node)
/// @description
/// Replaces reads of a local alias with the original local when neither changes in between.
/// Goes well with `optimizer_dead_local_remove`.
///
/// Example:
/// Before: var _next_value = _current_value; return _next_value;
/// After:  var _next_value = _current_value; return _current_value;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_copy_propagate(_ast_node) {
}

#region jsDoc
/// @function optimizer_dead_local_remove(_ast_node)
/// @description
/// Removes local declarations that are never read when the initializer is missing or side-effect-free.
/// Never touches instance variables, globals, statics, struct fields, array elements or accessor targets.
///
/// Example:
/// Before: var _unused_value = 10; return _result;
/// After:  return _result;
///
/// Example:
/// Before: var _unused_value = get_value(); return _result;
/// After:  get_value(); return _result;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_dead_local_remove(_ast_node) {
}

#region jsDoc
/// @function optimizer_dead_assignment_remove(_ast_node)
/// @description
/// Removes local assignments overwritten before being read.
/// A right-hand side with side effects is kept as a standalone expression.
///
/// Example:
/// Before: _value = 1; _value = 2; return _value;
/// After:  _value = 2; return _value;
///
/// Example:
/// Before: _value = get_value(); _value = 2;
/// After:  get_value(); _value = 2;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_dead_assignment_remove(_ast_node) {
}

#region jsDoc
/// @function optimizer_duplicate_branch_merge(_ast_node)
/// @description
/// Replaces a conditional whose branches are identical (compared as normalized AST) with the shared body.
///
/// Example:
/// Before: if (_condition) { run(); } else { run(); }
/// After:  run();
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_duplicate_branch_merge(_ast_node) {
}

#region jsDoc
/// @function optimizer_redundant_condition_remove(_ast_node)
/// @description
/// Removes condition terms already proven true or false by an outer condition.
/// Only pure, stable terms qualify: no calls, accessors, globals or fields unless proven unchanging.
///
/// Example:
/// Before: if (_ready) { if (_ready && _visible) { run(); } }
/// After:  if (_ready) { if (_visible) { run(); } }
///
/// Example:
/// Before: if (_ready && _active) { if (_ready) { run(); } }
/// After:  if (_ready && _active) { run(); }
///
/// Example:
/// Before: if (_ready) { if (!_ready) { fail(); } }
/// After:  if (_ready) { }
///
/// Example:
/// Before: if (!_ready) { if (_ready) { fail(); } }
/// After:  if (!_ready) { }
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_redundant_condition_remove(_ast_node) {
}

#region jsDoc
/// @function optimizer_common_tail_merge(_ast_node)
/// @description
/// Moves identical trailing statements of both branches after the conditional.
///
/// Example:
/// Before: if (_a) { left(); finish(); } else { right(); finish(); }
/// After:  if (_a) { left(); } else { right(); } finish();
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_common_tail_merge(_ast_node) {
}

#region jsDoc
/// @function optimizer_switch_simplify(_ast_node)
/// @description
/// Collapses switches with a known selector and removes unreachable statements and impossible cases.
/// Must keep fallthrough behavior unless fallthrough is modeled.
///
/// Example:
/// Before: switch (2) { case 1: a(); break; case 2: b(); break; }
/// After:  b();
///
/// Example:
/// Before: case 1: return; run();
/// After:  case 1: return;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_switch_simplify(_ast_node) {
}

#region jsDoc
/// @function optimizer_loop_constant_simplify(_ast_node)
/// @description
/// Removes loops that cannot run and folds known loop counts, keeping setup expressions with side effects.
///
/// Example:
/// Before: repeat (0) { run(); }
/// After:  // removed
///
/// Example:
/// Before: repeat (2 + 2) { run(); }
/// After:  repeat (4) { run(); }
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_loop_constant_simplify(_ast_node) {
}

#region jsDoc
/// @function optimizer_redundant_type_check_remove(_ast_node)
/// @description
/// Replaces type checks (is_string, is_numeric, ...) with a boolean literal when the checked type is proven.
/// Only applies when the callable resolves through the environment as a known type check.
///
/// Example:
/// Before: if (is_string("hello")) { run(); }
/// After:  if (true) { run(); }
///
/// Example:
/// Before: if (is_numeric("hello")) { run(); }
/// After:  if (false) { run(); }
///
/// Example:
/// Before: if (is_undefined(undefined)) { run(); }
/// After:  if (true) { run(); }
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_redundant_type_check_remove(_ast_node) {
}

#endregion

#region Aggressive

#region jsDoc
/// @function optimizer_loop_invariant_hoist(_ast_node)
/// @description
/// Moves pure expressions that compute the same value every iteration to before the loop.
/// They may only depend on values the loop body does not modify.
///
/// Example:
/// Before: repeat (_count) { var _area = _width * _height; run(_area); }
/// After:  var _area = _width * _height; repeat (_count) { run(_area); }
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_loop_invariant_hoist(_ast_node) {
}

#region jsDoc
/// @function optimizer_loop_unswitch(_ast_node)
/// @description
/// Moves a loop-invariant branch outside the loop by duplicating the loop.
/// Increases source size, so it is limited to aggressive output.
///
/// Example:
/// Before: repeat (_count) { if (_debug) { debug_draw(); } run(); }
/// After:  if (_debug) { repeat (_count) { debug_draw(); run(); } } else { repeat (_count) { run(); } }
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_loop_unswitch(_ast_node) {
}

#region jsDoc
/// @function optimizer_loop_unroll_small(_ast_node)
/// @description
/// Replaces very small constant-count loops with repeated statements.
/// Can make source much larger, so it is limited to aggressive or unsafe output.
///
/// Example:
/// Before: repeat (3) { run(); }
/// After:  run(); run(); run();
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_loop_unroll_small(_ast_node) {
}

#region jsDoc
/// @function optimizer_local_cse(_ast_node)
/// @description
/// Common subexpression elimination: stores a repeated pure expression in a local and reuses it.
/// Only when the expression has no side effects and all involved values are stable.
///
/// Example:
/// Before: var _value = (_width * _height) + (_width * _height);
/// After:  var _area = _width * _height; var _value = _area + _area;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_local_cse(_ast_node) {
}

#region jsDoc
/// @function optimizer_lookup_cache(_ast_node)
/// @description
/// Caches repeated stable lookups (static namespaces, global constants, stable struct paths) in a local.
/// Mutable or side-effect-capable reads are only cached when the optimizer level allows it.
///
/// Example:
/// Before: _total = Config.scale + Config.scale + Config.scale;
/// After:  var _scale = Config.scale; _total = _scale + _scale + _scale;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_lookup_cache(_ast_node) {
}

#region jsDoc
/// @function optimizer_trivial_function_inline(_ast_node)
/// @description
/// Inlines tiny functions, usually ones that only return a simple expression.
/// Avoids recursion, dynamic calls, public functions, instance-dependent methods and argument order changes.
///
/// Example:
/// Before: function add_one(_value) { return _value + 1; } var _result = add_one(4);
/// After:  var _result = 4 + 1;
///
/// Example:
/// Before: function is_ready() { return _enabled && _loaded; } if (is_ready()) { run(); }
/// After:  if (_enabled && _loaded) { run(); }
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_trivial_function_inline(_ast_node) {
}

#region jsDoc
/// @function optimizer_single_use_function_inline(_ast_node)
/// @description
/// Inlines private functions that have exactly one known call site, whatever their size.
/// Avoids recursion, dynamic calls, public functions, instance-dependent methods and argument order changes.
///
/// Example:
/// Before: function __build_result(_value) { var _next_value = _value * 2; return _next_value; } var _result = __build_result(6);
/// After:  var _next_value = 6 * 2; var _result = _next_value;
///
/// Example:
/// Before: function __setup_once() { init_a(); init_b(); } __setup_once();
/// After:  init_a(); init_b();
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_single_use_function_inline(_ast_node) {
}

#region jsDoc
/// @function optimizer_declared_function_inline(_ast_node)
/// @description
/// Inlines functions the user marks with gml_pragma("forceinline").
/// Still rejects recursion, dynamic targets, missing bodies and argument evaluation changes.
///
/// Example:
/// Before: gml_pragma("forceinline"); function get_scaled(_value) { return _value * 4; } var _result = get_scaled(8);
/// After:  var _result = 8 * 4;
///
/// Example:
/// Before: gml_pragma("forceinline"); function __emit_pair(_left, _right) { emit(_left); emit(_right); } __emit_pair("a", "b");
/// After:  emit("a"); emit("b");
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_declared_function_inline(_ast_node) {
}

#region jsDoc
/// @function optimizer_assignment_operator_simplify(_ast_node)
/// @description
/// Rewrites self-referential assignments into compound assignments or update expressions.
/// Starts with locals only; other targets need proof that read and write target match and order is kept.
///
/// Example:
/// Before: _value = _value + 1;
/// After:  _value++;
///
/// Example:
/// Before: _value = _value - 1;
/// After:  _value--;
///
/// Example:
/// Before: _value = _value * _scale;
/// After:  _value *= _scale;
///
/// Example:
/// Before: _value = _value | _mask;
/// After:  _value |= _mask;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_assignment_operator_simplify(_ast_node) {
}

#endregion

#region Unsafe

#region jsDoc
/// @function optimizer_static_literal_hoist(_ast_node)
/// @description
/// Hoists repeated array or struct literals into static storage to avoid allocations.
/// Unsafe unless mutation is proven irrelevant, since arrays and structs are references.
///
/// Example:
/// Before: return { name: "sand", mass: 1 };
/// After:  static _sand_data = { name: "sand", mass: 1 }; return _sand_data;
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_static_literal_hoist(_ast_node) {
}

#region jsDoc
/// @function optimizer_condition_reorder(_ast_node)
/// @description
/// Reorders short-circuit operands so cheaper or likely-to-fail checks run first.
/// Unsafe unless every moved expression is proven pure.
///
/// Example:
/// Before: if (expensive_check() && _enabled) { run(); }
/// After:  if (_enabled && expensive_check()) { run(); }
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_condition_reorder(_ast_node) {
}

#region jsDoc
/// @function optimizer_temporary_coalesce(_ast_node)
/// @description
/// Reuses temporary locals whose lifetimes do not overlap.
/// Unsafe, and saves a few cpu cycles at best.
///
/// Example:
/// Before: var _temp_a = read_a(); use(_temp_a); var _temp_b = read_b(); use(_temp_b);
/// After:  var _temp = read_a(); use(_temp); _temp = read_b(); use(_temp);
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_temporary_coalesce(_ast_node) {
}

#endregion

#region Misc

#region jsDoc
/// @function optimizer_minify_format(_ast_node)
/// @description
/// Marks the AST for compact source emission, possibly stripping comments.
/// No effect on runtime behavior or compile.
///
/// Example:
/// Before: if (_ready) { run(); }
/// After:  if(_ready){run();}
///
/// @param {Struct.ASTNode} _ast_node The AST node to inspect and possibly rewrite.
/// @returns {Struct.ASTNode} The original or rewritten AST node.
#endregion
function optimizer_minify_format(_ast_node) {
}

#endregion


