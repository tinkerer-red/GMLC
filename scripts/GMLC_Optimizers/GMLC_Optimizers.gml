#region Clean

#region jsDoc
/// @function optimizer_unary_expression_simplify(_ast_node)
/// @description
/// Simplifies unary expressions when the result or a smaller equivalent form can
/// be proven from the operator and operand.
///
/// This pass handles unary constant folding and unary identity rules. It should
/// only replace the expression when evaluating the operand has no side effects,
/// or when the replacement preserves the same evaluation behavior.
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
/// Simplifies binary expressions when the result or a smaller equivalent form
/// can be proven from the operator and operands.
///
/// This pass handles arithmetic, comparison, boolean, bitwise, and nullish
/// operators. It includes constant folding, identity rules, absorbing rules,
/// redundant boolean comparisons, and short-circuit simplifications.
///
/// This pass must preserve evaluation behavior. It should not remove, reorder,
/// or skip an operand if evaluating that operand may produce side effects,
/// unless the original operator would also skip that operand.
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
///
/// This pass is separate from binary expression simplification because a ternary
/// has three expression parts: condition, true branch, and false branch. Only
/// one branch is evaluated at runtime.
///
/// This pass must preserve branch laziness. It should not evaluate, move, or
/// expose the unused branch unless the original expression would also evaluate
/// it.
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
/// Resolves variables that are explicitly marked as compile-time constants.
///
/// This pass handles identifier reads where the compiler environment marks the
/// variable as compileTimeConstant and provides a compileTimeGet resolver. The
/// optimizer should replace the identifier with the value returned by that
/// resolver using the current compile context.
///
/// This pass should not guess based on variable names. A variable is eligible
/// only when its exposed symbol metadata explicitly declares that it must be
/// resolved at compile time.
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
/// Resolves function calls that are explicitly marked as compile-time viable.
///
/// This pass handles call expressions where the compiler environment resolves
/// the callee to a function with compile-time metadata. The function may either
/// produce a compile-time literal value or return a replacement AST node,
/// depending on how the exposed symbol is defined.
///
/// This pass should not assume that any function name refers to a native
/// GameMaker built-in. A function call is eligible only when the resolved
/// callable explicitly declares that it can be evaluated or rewritten at compile
/// time.
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
/// Merges string literals that are directly concatenated.
///
/// This pass combines string parts that are already known at compile time. It
/// should avoid folding mixed values unless the compiler has modeled the exact
/// GameMaker conversion behavior.
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
/// Removes branches that cannot run.
///
/// This pass removes if, else-if, ternary, and switch branches when the selected
/// path is known at compile time. If the condition has side effects, the
/// condition must still be preserved somewhere in the output.
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
/// Removes statements that cannot execute after a terminating statement.
///
/// This pass handles code after return, break, continue, exit, and other
/// statements that always stop the current control path. It should not cross
/// function, method, constructor, or event boundaries.
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
/// Removes empty blocks when the block itself no longer contributes anything.
///
/// This pass removes empty statement groups and empty branches, but it must
/// preserve any expression that still needs to run. The important distinction is
/// that an empty body can disappear only when removing it does not also remove
/// required evaluation behavior.
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
/// Removes else blocks after a branch that always exits.
///
/// This pass turns nested else flow into sequential flow when the if branch
/// always returns, breaks, continues, exits, or otherwise terminates.
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
/// Flattens nested blocks that do not change meaning.
///
/// This pass removes unnecessary block nesting where the inner block has no
/// special control-flow or scope role. It should avoid crossing function,
/// method, constructor, with, switch, loop, or event boundaries unless those
/// cases are explicitly supported. This is because non-evaluated block
/// statements are allowed in gm, though they dont practically do anything
/// this optimization is mostly for the executable compiled output.
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
/// Merges nested if statements into one short-circuit condition.
///
/// This pass reduces nesting when an outer if only contains another if. It
/// preserves the original order by using short-circuit logic, so the second
/// condition still runs only if the first condition passes.
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
/// Swaps if and else branches by negating the condition.
///
/// This pass is useful when the swapped version has simpler control flow, such
/// as putting an early return first. It should not reorder side effects or
/// apply when the result is harder to reason about.
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
/// Replaces local variable reads with known constant values.
///
/// This pass tracks locals assigned from literals or compile-time constants,
/// then substitutes those values into later reads. It should stop tracking a
/// value as soon as the local is reassigned or control flow becomes unclear.
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
/// Replaces simple local aliases with their original local value.
///
/// This pass handles cases where one local only points to another local. It
/// should only apply when neither local changes between the assignment and the
/// later read. Goes well with `optimizer_dead_local_remove`
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
/// Removes local variables that are never read.
///
/// This pass removes unused local declarations only when the initializer is
/// missing or side-effect-free. It should not remove instance variables,
/// globals, statics, struct fields, array elements, or accessor targets.
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
/// Removes local assignments whose value is overwritten before it is read.
///
/// This pass applies to local variables by default. If the right-hand expression
/// has side effects, the value assignment can be removed only if the expression
/// is still preserved as a standalone expression.
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
/// Removes conditionals where every branch does the same thing.
///
/// This pass detects identical branch bodies and replaces the whole conditional
/// with the shared body. It should compare normalized AST structure rather than
/// raw source text, so formatting differences do not matter.
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
/// Removes condition checks that are already guaranteed by an outer condition.
///
/// This pass tracks simple condition facts while walking nested branches. If an
/// outer branch already proves that a condition is true or false, an inner
/// branch can sometimes remove or simplify repeated checks against that same
/// condition.
///
/// This is different from merging nested branches. Instead of combining two
/// conditions together, this pass removes condition terms that have already
/// been proven by the surrounding control flow.
///
/// This pass should only remove repeated condition terms that are pure and
/// stable. It should not remove function calls, accessors, globals, instance
/// fields, struct fields, or other expressions unless another analysis proves
/// they cannot change and have no side effects.
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
/// Moves identical trailing statements out of conditional branches.
///
/// This pass finds matching statements at the end of both branches and emits
/// them once after the conditional. This reduces duplicate code without changing
/// which branch-specific work happens first.
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
/// Simplifies switch statements using known selector or case data.
///
/// This pass can collapse a switch when the selector is known, remove unreachable
/// statements after break-like terminators, and remove impossible cases. It must
/// preserve fallthrough behavior unless fallthrough is explicitly modeled.
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
/// Simplifies loops whose controlling expression is known.
///
/// This pass removes loops that cannot run or simplifies loop counts that are
/// known at compile time. It must preserve setup expressions when those
/// expressions may have side effects.
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
/// Removes type checks whose result is already known.
///
/// This pass detects calls such as is_string, is_numeric, is_array, or
/// is_undefined when the checked expression has a proven compile-time type. If
/// the result is known, the type check can be replaced with a boolean literal,
/// which may allow later branch removal.
///
/// This pass should not assume that a function named is_string is the native
/// GameMaker function. The check is eligible only when the callable is resolved
/// through the environment as a known type-check function or when the compiler
/// has direct type facts for the expression.
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
/// Moves repeated loop work outside the loop when the value cannot change.
///
/// This pass finds pure expressions inside a loop that compute the same value
/// every iteration, then stores them before the loop. The expression must depend
/// only on values not modified by the loop body.
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
///
/// This pass avoids checking the same condition every iteration. It increases
/// source size because it creates two versions of the loop, so it should be
/// limited to aggressive output and only used when the condition cannot change
/// inside the loop.
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
///
/// This pass removes loop overhead when the iteration count is known and small.
/// It can make source much larger and harder to read, so it should be limited
/// to aggressive or unsafe output.
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
/// Reuses repeated pure expressions inside a local block.
///
/// This pass detects the same pure expression being calculated more than once,
/// stores it in a local, and reuses that local. CSE means common subexpression
/// elimination. It should only run when the expression has no side effects and
/// all involved values are stable.
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
/// Caches repeated stable lookups into local variables.
///
/// This pass replaces repeated lookup paths with one local read. It is useful
/// when the same static namespace, global constant, or stable struct path is
/// read many times. It should not cache mutable or side-effect-capable reads
/// unless the selected optimizer level allows that assumption.
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
/// Inlines tiny functions where the call is more expensive or noisier than the
/// function body itself.
///
/// This pass targets very small functions, usually functions that only return a
/// simple expression. The function may have multiple call sites, but each inline
/// replacement should remain small and readable enough to justify removing the
/// call.
///
/// This pass should avoid recursive functions, dynamic calls, public functions,
/// methods that depend on instance context, and cases where argument evaluation
/// order would change.
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
/// Inlines private functions that have exactly one known call site.
///
/// This pass removes a function and places its body where it is called. Unlike
/// trivial inlining, the function body does not need to be tiny. The reason this
/// is still worthwhile is that the function only exists for one call, so keeping
/// it separate may add more overhead and structure than value.
///
/// This pass is most useful for compiler-generated helpers, private local
/// helpers, and setup functions that are not referenced dynamically.
///
/// This pass should avoid recursive functions, dynamic calls, public functions,
/// methods that depend on instance context, and cases where argument evaluation
/// order would change.
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
/// Inlines functions explicitly marked by the user with forceinline.
///
/// This pass handles functions where the user has requested inlining through
/// gml_pragma("forceinline"). Unlike trivial or single-use inlining, this pass
/// is driven by an explicit source annotation rather than by the optimizer's
/// size or usage heuristics.
///
/// The optimizer should still reject impossible or unsafe cases, such as
/// recursion, dynamic call targets, missing function bodies, or argument
/// evaluation changes. The pragma is a request to inline, not permission to
/// emit incorrect code.
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
/// Rewrites self-referential assignments into compound assignments or update
/// expressions.
///
/// This pass detects assignments where the target is read, modified, and written
/// back to the same target. The simpler operator form can be easier for later
/// compiler stages to understand and may reduce emitted work.
///
/// This pass should start with local variables only. Accessors, struct fields,
/// instance variables, and global variables should be avoided unless the
/// compiler can prove that the read target and write target are the same and
/// that evaluation order is preserved.
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
/// Hoists repeated array or struct literals into static storage.
///
/// This pass reduces repeated allocation by creating a literal once and reusing
/// it. This is unsafe unless mutation behavior is proven irrelevant, because
/// arrays and structs are reference values in GML.
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
/// Reorders condition operands by estimated cost or likelihood.
///
/// This pass moves cheaper or more likely-to-fail checks earlier in a short
/// circuit expression. It is unsafe unless every moved expression is proven
/// pure and the original evaluation order has no observable behavior.
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
///
/// This pass reduces the number of generated temporary variables. Two locals can
/// share one name only when the first value is never needed again before the
/// second value is assigned. This is considered unsafe, and will only save AT BEST
/// a fex cpu cycles.
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
/// Marks the AST for compact or minified source emission.
///
/// This pass removes nonessential formatting metadata and may strip comments
/// depending on the selected output mode. It should not change runtime behavior,
/// but it can make emitted source difficult to inspect. Generally used for
/// specific purposes and will have no effect on compile.
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


