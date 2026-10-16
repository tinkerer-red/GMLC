#region jsDoc
/// @func    GMLC_Gen_6_Compiler(_env)
/// @desc    Compiler stage: builds the AST into a tree of callable methods. Each node kind has a __GMLCcompile*
///          function that returns a method bound to its __GMLCexecute* executor.
/// @param   {Struct.GMLC_Env} _env : The environment
/// @returns {Struct.GMLC_Gen_6_Compiler}
#endregion
function GMLC_Gen_6_Compiler(_env) constructor  {
	env = _env;
	
	//init variables:
	
	ast     = undefined;
	globals = undefined;
	sources = undefined;
	
	#region jsDoc
	/// @func    initialize(_ast, [_globalsStruct], [_sources])
	/// @desc    Sets the AST to compile, the struct its named functions go into, and the sources for error positions.
	/// @self    GMLC_Gen_6_Compiler
	/// @param   {Struct} _ast           : The Script node
	/// @param   {Struct} _globalsStruct : The program's globals
	/// @param   {Any}    _sources       : The source files, or undefined
	#endregion
	static initialize = function(_ast, _globalsStruct={}, _sources=undefined) {
		ast = _ast;
		globals = _globalsStruct;
		sources = _sources;
	}
	
	#region jsDoc
	/// @func    cleanup()
	/// @desc    Nothing to free; kept so every stage has the same methods.
	/// @self    GMLC_Gen_6_Compiler
	#endregion
	static cleanup = function() {
	
	}
	
	#region jsDoc
	/// @func    parseAll()
	/// @desc    Compiles the whole AST and returns the program, a method that runs it.
	/// @self    GMLC_Gen_6_Compiler
	/// @returns {Function}
	#endregion
	static parseAll = function() {
		return __GMLCcompileProgram(ast, globals, env, sources);
	}
	
	#region jsDoc
	/// @func    nextNode()
	/// @desc    Does nothing yet: a place for compiling one node at a time.
	/// @self    GMLC_Gen_6_Compiler
	#endregion
	static nextNode = function() {
		//This is intended to one day allow for async compiling but until that day this is a place holder.
	};
	
}

// Private //////////////////////////

#region Config
// Debug configuration only: it costs one call stack per node
#macro GMLC_DEBUG_CALLSTACK false
#macro Debug:GMLC_DEBUG_CALLSTACK true
#endregion

#region Macros
#region Globals for `self` and `other`
#macro __GMLC_DEFAULT_SELF_AND_OTHER	var _entered_on_this_function = false;\
										if (global.gmlc_other_instance == undefined)\
										&& (global.gmlc_self_instance == undefined) {\
											_entered_on_this_function = true;\
											global.gmlc_other_instance = global.gmlc_self_instance ?? (self[$ "root_node"] ? root_node[$ "globals"] : other) ?? other;\
											global.gmlc_self_instance = other\
										}

#macro __GMLC_RESET_DEFAULT_SELF_AND_OTHER	if (_entered_on_this_function) {\
												global.gmlc_other_instance = undefined;\
												global.gmlc_self_instance = undefined;\
											}

#macro __GMLC_UPDATE_SELF_AND_OTHER	var _pre_other = global.gmlc_other_instance;\
									var _pre_self = global.gmlc_self_instance;\
									var _desired_self = other;\
									;\ //dont update scope if we are already on the correct scope,
									;\ // and dont update scope if it's an unbound method
									if (_desired_self != undefined) {\
										global.gmlc_other_instance = _pre_self ?? root_node.globals;\
										global.gmlc_self_instance = _desired_self;\
									}
#macro __GMLC_RESET_SELF_AND_OTHER	global.gmlc_other_instance = _pre_other;\
									global.gmlc_self_instance = _pre_self
#endregion

#region Locals
#macro __GMLC_STASH_LOCALS	array_copy(backup_locals, array_length(backup_locals), locals, 0, local_count);\
							array_resize(locals, 0);\
							array_resize(locals, local_count);\
						    array_copy(backup_locals_written_to, array_length(backup_locals_written_to), locals_written_to, 0, local_count);\
							array_resize(locals_written_to, 0);\
							array_resize(locals_written_to, local_count)
							
#macro __GMLC_UNSTASH_LOCALS	var _local_offset = array_length(backup_locals)-local_count\
						        array_copy(locals, 0, backup_locals, _local_offset, local_count);\
						        array_resize(backup_locals, _local_offset);\
								var _local_offset = array_length(backup_locals_written_to)-local_count\
						        array_copy(locals_written_to, 0, backup_locals_written_to, _local_offset, local_count);\
						        array_resize(backup_locals_written_to, _local_offset)

#macro __GMLC_RESET_LOCALS	if (local_count) {\
								array_copy(locals, 0, blank_locals, 0, local_count);\
								array_copy(locals_written_to, 0, blank_locals_written_to, 0, local_count);\
							}
#endregion

#region Arguments
#macro __GMLC_STASH_ARGUMENTS	array_copy(backup_arguments, array_length(backup_arguments), arguments, 0, previous_argument_count);\
								array_resize(arguments, 0);\
								array_resize(arguments, _arg_count);\
								array_push(argument_count_memory, _arg_count)
								
#macro __GMLC_UNSTASH_ARGUMENTS var _prev_arg_count = array_pop(argument_count_memory)\
								var _arg_offset = array_length(backup_arguments)-_prev_arg_count\
						        array_copy(arguments, 0, backup_arguments, _arg_offset, _prev_arg_count);\
						        array_resize(backup_arguments, _arg_offset)

#macro __GMLC_RESET_ARGUMENTS	array_resize(arguments, 0);

#macro __GMLC_INIT_ARGUMENT_COUNT	var _arg_count = max(argument_count, arguments_length)

#macro __GMLC_POPULATE_ARGUMENTS	previous_argument_count = _arg_count;\
									array_resize(arguments, argument_count)\
									var _i=argument_count-1; repeat(argument_count) {\
										arguments[_i] = argument[_i];\
									_i--}\
									arguments_default();
#endregion

#region Constructors
#macro __GMLC_CALL_PARENT_CONSTRUCTOR	if (self[$ "has_parent_constructor"]) {\
											if (is_handle(parent_constructor_call) && is_callable(parent_constructor_call)) {\
												parent_constructor_call(arguments)\
											}\
										}

#endregion

#region Statics
#macro __GMLC_INIT_STATICS	if (!statics_executed) {\
								statics_executed = true;\
								statics_block();\
							}

#endregion

#macro __GMLC_PRE_FUNC	__GMLC_DEFAULT_SELF_AND_OTHER\
						array_push(global.__gmlc_active_functions, self);\
						__GMLC_INIT_ARGUMENT_COUNT\
						if (recursion_count++) {\
						    __GMLC_STASH_LOCALS\
							__GMLC_STASH_ARGUMENTS\
						}\
						__GMLC_POPULATE_ARGUMENTS\
						__GMLC_INIT_STATICS
						

#macro __GMLC_POST_FUNC	array_pop(global.__gmlc_active_functions);\
						return_value = undefined;\
						flow_mask = FLOW_MASK.EMPTY;\
						if (--recursion_count) {\
							__GMLC_UNSTASH_LOCALS\
							__GMLC_UNSTASH_ARGUMENTS\
					    }\
						else {\
							__GMLC_RESET_LOCALS;\
							__GMLC_RESET_ARGUMENTS;\
						}\
						__GMLC_RESET_DEFAULT_SELF_AND_OTHER
#endregion

#region Compiler Functions

///NOTE: all of these should be build into the parent programs struct, and all children should
// have a reference to that struct to access the locals and arguments when ever needed

enum FLOW_MASK {
    EMPTY    = 0, // 0b000
	BREAK    = 1, // 0b001
    CONTINUE = 2, // 0b010
    RETURN   = 4, // 0b100
}

global.gmlc_self_instance = undefined;
global.gmlc_other_instance = undefined;
// the compiled functions that are running, innermost last; an error caught by a compiled `try` (or leaving the
// program) unwinds the ones it left, so their locals, arguments and recursion counts are as before the call
global.__gmlc_active_functions = [];

#region Program Entry
#region jsDoc
/// @func    __GMLCunwindTo(_depth)
/// @desc    Ends the compiled functions an error left, innermost first, as their return would have: their locals and
///          arguments of the call before are put back.
/// @param   {Real} _depth : How many functions were running where the error is caught
#endregion
function __GMLCunwindTo(_depth) {
	var _stack = global.__gmlc_active_functions;
	while (array_length(_stack) > _depth) {
		with (array_pop(_stack)) {
			return_value = undefined;
			flow_mask = FLOW_MASK.EMPTY;
			if (--recursion_count) {
				__GMLC_UNSTASH_LOCALS
				__GMLC_UNSTASH_ARGUMENTS
			}
			else {
				__GMLC_RESET_LOCALS;
				__GMLC_RESET_ARGUMENTS;
			}
		}
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////

#region jsDoc
/// @func    executeProgram(_program)
/// @desc    Runs a compiled program from outside any program, with the caller as self and other, and returns its result.
///          An error leaves no compiled function or scope behind before it is thrown on.
/// @param   {Function} _program : A compiled program
/// @returns {Any}
#endregion
function executeProgram(_program) {
	//this function should never be called inside a prgroam, for that use `__executeProgram`
	var _depth = array_length(global.__gmlc_active_functions);
	global.gmlc_self_instance = self;
    global.gmlc_other_instance = other;
	
	try {
		return _program();
	}
	catch (_e) {
		__GMLCunwindTo(_depth);
		global.gmlc_self_instance = undefined;
		global.gmlc_other_instance = undefined;
		throw _e;
	}
}
#endregion

#region Structural Nodes

#region //{
// used to start the initial entry into the compiled program, mostly just to init variables like 
//    program: <expression>,
//    varStatics: {},
//    locals: {},
//}
#endregion
function __GMLCexecuteNothing() {
}
#region jsDoc
/// @func    __GMLCexecuteProgram()
/// @desc    Runs the compiled program with fresh locals and arguments and returns what its body returns.
/// @returns {Any}
#endregion
function __GMLCexecuteProgram() {
	#region jsDoc
	/// @func    globals()
	/// @desc    Returns the globals of the program this method is bound to.
	/// @returns {Struct}
	#endregion
	static globals = function(){ return method_get_self(self).globals }
	
	__GMLC_PRE_FUNC
	
	////////////////EXECUTE////////////////////////
	var _return = program();
	///////////////////////////////////////////////
	
	__GMLC_POST_FUNC
	
	return _return;
}
#region jsDoc
/// @func    __GMLCcompileProgram(_node, _globalsStruct, [_env], [_sources])
/// @desc    Compiles a Script node into the program: a method that runs it.
/// @param   {Struct} _node          : The Script node
/// @param   {Struct} _globalsStruct : Where named functions and globals go
/// @param   {Struct} _env           : The environment, or undefined
/// @param   {Any}    _sources       : The source files, or undefined
/// @returns {Function}
#endregion
function __GMLCcompileProgram(_node, _globalsStruct, _env=undefined, _sources=undefined) {
	var _output = new __GMLC_Function(undefined, undefined, "__GMLCcompileProgram", "<Missing Error Message>", _node.span);
	_output.root_node = _output;
	_output.env = _env;
	_output.sources = _sources;
	_output.debug = (_env != undefined) && (_env[$ "debug"] == true);
	_output.globals = _globalsStruct; // these are optional inputs for future use with compiling a full project folder.
	_output.scope_stack = ["Global"]; // how a function expression is bound where it appears
	_output.functions = _node.functions;
	
	_output.program = __GMLCcompileFunction(_output, _output, _node);
	
	_output.local_look_ups = {};
	_output.local_count = 0;
	_output.locals = [];
	_output.locals_written_to = [];
	_output.backup_locals = [];
	_output.backup_locals_written_to = [];
	
	_output.recursion_count = 0;
	_output.previous_argument_count = 0;
	_output.arguments_length = 0;
	_output.arguments = [];
	_output.backup_arguments = [];
	_output.argument_count_memory = [];
	_output.arguments_default = __GMLCexecuteNothing;
	_output.statics_executed = true;
	
	return __vanilla_method(_output, __GMLCexecuteProgram)
}

#region jsDoc
/// @func    __GMLClocalLookUps(_rootNode, _node)
/// @desc    The parameters and locals of a function as name to slot, from what the resolver found, with their count.
/// @param   {Struct} _rootNode : The program node
/// @param   {Struct} _node     : A function node or the Script
/// @returns {Struct} {look_ups, count}
#endregion
function __GMLClocalLookUps(_rootNode, _node) {
	var _info = _rootNode.functions[(_node.kind == __GMLC_NodeKind_Script) ? 0 : _node.fn_id];
	var _lookUps = {};
	var _i = 0; repeat (array_length(_info.params)) {
		_lookUps[$ _info.params[_i]] = _i;
	_i++}
	var _n = array_length(_info.params);
	_i = 0; repeat (array_length(_info.locals)) {
		_lookUps[$ _info.locals[_i]] = _n + _i;
	_i++}
	return { look_ups: _lookUps, count: _n + array_length(_info.locals) };
}

#region jsDoc
/// @func    __GMLCexecuteExpression()
/// @desc    Does nothing.
#endregion
function __GMLCexecuteExpression() {};
#region jsDoc
/// @func    __GMLCcompileExpression(_rootNode, _parentNode, _node)
/// @desc    Compiles any statement or expression by its node kind and returns its executor.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : The node to compile
/// @returns {Function}
#endregion
function __GMLCcompileExpression(_rootNode, _parentNode, _node) {
	if (_parentNode=undefined && _node==undefined) {
		__gmlc_internal_error("__GMLCcompileExpression was called without its root and parent nodes")
	}
	if (!is_instanceof(_node, ASTNode)) {
		__gmlc_internal_error($"__GMLCcompileExpression was given a {instanceof(_node)}, not a node")
	}
	
	//check every different ast node, and see how it should be compiled,
    // this is essentially our lookup table for that
	
	switch (_node.kind) {
		case __GMLC_NodeKind_FunctionExpr:{
			return __GMLCcompileFunctionExpr(_rootNode, _parentNode, _node);
		break;}
		
		case __GMLC_NodeKind_Block:{
			return __GMLCcompileBlockStatement(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeKind_If:{
			return __GMLCcompileIf(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeKind_For:{
			return __GMLCcompileFor(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeKind_While:{
			return __GMLCcompileWhile(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeKind_Repeat:{
			return __GMLCcompileRepeat(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeKind_DoUntil:{
			return __GMLCcompileDoUntil(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeKind_With:{
			return __GMLCcompileWith(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeKind_Try:{
			return __GMLCcompileTryCatchFinally(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeKind_Switch:{
			return __GMLCcompileSwitch(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_Case:
		case __GMLC_NodeKind_Default:{
			return __GMLCcompileCase(_rootNode, _parentNode, _node)
		break;}
		
		case __GMLC_NodeKind_Break:{
			return __GMLCcompileBreak(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeKind_Continue:{
			return __GMLCcompileContinue(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeKind_Exit:{
			return __GMLCcompileExit(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_Return:{
			return __GMLCcompileReturn(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_Throw:{
			return __GMLCcompileThrow(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_Delete:{
			// `delete x` writes undefined to x
			var _undefined = new ASTLiteral(_node.span, "undefined", "undefined", undefined);
			return __GMLCcompileAssignmentExpression(_rootNode, _parentNode, new ASTAssign(_node.span, "=", _node.target, _undefined));
		break;}
		
		case __GMLC_NodeKind_ExprStmt:{
			return __GMLCcompileExpression(_rootNode, _parentNode, _node.expression);
		break;}
		case __GMLC_NodeKind_Call:{
			return __GMLCcompileCallExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_MethodCall:{
			return __GMLCcompileCallMethodExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_New:{
			return __GMLCcompileNewExpression(_rootNode, _parentNode, _node)
		break;}
		
		case __GMLC_NodeKind_Assign:{
			return __GMLCcompileAssignmentExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_Binary:{
			return __GMLCcompileBinaryExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_Logical:{
			return __GMLCcompileLogicalExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_Nullish:{
			return __GMLCcompileNullishExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_Unary:{
			return __GMLCcompileUnaryExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_Update:{
			return __GMLCcompileUpdateExpression(_rootNode, _parentNode, _node)
		break;}
		
		case __GMLC_NodeKind_Conditional:{
			return __GMLCcompileTernaryExpression(_rootNode, _parentNode, _node);
		break;}
		
		case __GMLC_NodeKind_Literal:{
			return __GMLCcompileLiteralExpression(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeKind_Identifier:{
			return __GMLCcompileIdentifier(_rootNode, _parentNode, _node)
		break;}
		
		case __GMLC_NodeKind_Index:{
			return __GMLCcompileAccessor(_rootNode, _parentNode, _node)
		break;}
		
		case __GMLC_NodeKind_ArrayLiteral:{
			return __GMLCcompileArrayLiteral(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_StructLiteral:{
			return __GMLCcompileStructLiteral(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeKind_TemplateString:{
			return __GMLCcompileTemplateString(_rootNode, _parentNode, _node)
		break;}
		
		case __GMLC_NodeKind_Empty:{
			// a hole in an argument list is undefined; an empty statement does nothing
			return __vanilla_method({ value: undefined }, __GMLCexecuteLiteralExpression);
		}
		
		default:
			
			__gmlc_internal_error($"the compiler has no case for node kind {_node.kind}", _node.span)
		break;
				
		// Add cases for other types of nodes
	}
	
};

#region jsDoc
/// @func    __GMLCexecuteFunction()
/// @desc    Calls a compiled function: sets up its locals, arguments and statics, runs its body, returns its result.
/// @returns {Any}
#endregion
function __GMLCexecuteFunction() {
	__GMLC_PRE_FUNC
	
	////////////////EXECUTE////////////////////////
	program();
	var _return = return_value;
	///////////////////////////////////////////////
	
	__GMLC_POST_FUNC
	
	return _return;
}
#region jsDoc
/// @func    __GMLCexecuteFunctionWithArray(_args)
/// @desc    Calls a compiled function with its arguments in an array and returns its return value.
/// @param   {Array} _args : The call's arguments
/// @returns {Any}
#endregion
function __GMLCexecuteFunctionWithArray(_args) {
	__GMLC_DEFAULT_SELF_AND_OTHER
	array_push(global.__gmlc_active_functions, self);
	var _count = array_length(_args);
	var _arg_count = max(_count, arguments_length);
	if (recursion_count++) {
		__GMLC_STASH_LOCALS
		__GMLC_STASH_ARGUMENTS
	}
	previous_argument_count = _arg_count;
	array_resize(arguments, _count);
	array_copy(arguments, 0, _args, 0, _count);
	arguments_default();
	__GMLC_INIT_STATICS

	program();
	var _return = return_value;

	__GMLC_POST_FUNC

	return _return;
}
#region jsDoc
/// @func    __GMLCcompileFunction(_rootNode, _parentNode, _node)
/// @desc    Compiles a function or a script body into a method that calls it.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A function node or the Script
/// @returns {Function}
#endregion
function __GMLCcompileFunction(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, undefined, "__GMLCcompileFunction", "<Missing Error Message>", _node.span);
	_output[$ "__@@is_gmlc_function@@__"] = true;
	
	_output.parent_node = _output;
	
	_output.recursion_count = 0; 
	
	_output.is_script_body = (_node.kind == __GMLC_NodeKind_Script);
	// an object event's top-level functions become methods of the instance
	_output.is_event_body = _output.is_script_body && (_node[$ "unit_kind"] == "event");
	__GMLCdebugFrame(_rootNode, _output, _node, (_output.is_script_body) ? _node : _node.body);
	var _params = _node[$ "params"] ?? [];
	
	//this assists with converting locals from struct accessors to an array write
	var _locals = __GMLClocalLookUps(_rootNode, _node);
	_output.local_look_ups = _locals.look_ups;
	var _i = _locals.count;
	_output.local_count = _i;
	_output.locals = array_create(_i, undefined);
	_output.blank_locals = array_create(_i, undefined);
	_output.blank_locals_written_to = array_create(_i, false);
	_output.locals_written_to = array_create(_i, false); //remember if we ever wrote to those locals, this is used to throw errors incase we are reading from an unwritten local
	_output.backup_locals = [];//if the function is recursive stash the locals back into this array, to<->from
	_output.backup_locals_written_to = [];//if the function is recursive stash the locals back into this array, to<->from
	
	//arguments
	_output.arguments_default = __GMLCcompileArgumentList(_rootNode, _output, _params, _node);
	_output.arguments_length = array_length(_params);
	_output.previous_argument_count = 0;
	_output.arguments = [];
	_output.backup_arguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argument_count_memory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	//statics
	_output.statics_executed = false;
	_output.statics = new __GMLC_Statics(_node[$ "name"]);
	_output.static_declarations = [];
	static_set(_output, _output.statics)
	
	//block statement
	if (!_output.is_script_body) array_push(_rootNode.scope_stack, "Self");
	_output.program = __GMLCcompileBlockStatement(_rootNode, _output, (_output.is_script_body) ? _node : _node.body);
	if (!_output.is_script_body) array_pop(_rootNode.scope_stack);
	_output.statics_block = __GMLCcompileStatics(_rootNode, _output, _node);
	
	_output.return_value = undefined;
	_output.flow_mask = FLOW_MASK.EMPTY;
	_output.invoke_with_array = __vanilla_method(_output, __GMLCexecuteFunctionWithArray);
	
	return __vanilla_method(_output, __GMLCexecuteFunction)
}

#region jsDoc
/// @func    __GMLCexecuteConstructor()
/// @desc    Runs a compiled constructor on the new struct (`new`) or on self (script_execute, method_call): its parent
///          constructor, its statics, then its body. Returns the body's return value.
/// @returns {Any}
#endregion
function __GMLCexecuteConstructor() constructor {
	//check to see if this is a `new` expression, or some `script_execute` equivalent using `method_call`
	var _self_is_gmlc  = self[$ "__@@is_gmlc_function@@__"];
	var _is_new_expression = !_self_is_gmlc;
	
	var _program_data = (_is_new_expression) ? other : self;
	with _program_data {
		var _program = program;
		var _statics = statics;
		
		__GMLC_DEFAULT_SELF_AND_OTHER
		
		if (_is_new_expression) {
			__GMLC_UPDATE_SELF_AND_OTHER
		}
		
		array_push(global.__gmlc_active_functions, self);
		__GMLC_INIT_ARGUMENT_COUNT
		if (recursion_count++) {
			__GMLC_STASH_LOCALS
			__GMLC_STASH_ARGUMENTS
		}
		
		previous_argument_count = _arg_count;
		var _i=argument_count-1; repeat(argument_count) {
			arguments[_i] = argument[_i];
		_i--}
		arguments_default();
										
		if (_program_data[$ "has_parent_constructor"]) {
			parent_constructor_call(arguments)
			var _obj_statics = static_get(global.gmlc_self_instance);
			static_set(_statics, _obj_statics);
		}
		__GMLC_INIT_STATICS
	}
	
	static_set(global.gmlc_self_instance, _statics);
	_program();
	
	if (_is_new_expression) {
		__GMLC_RESET_SELF_AND_OTHER
		with other {
			var _return = return_value;
			__GMLC_POST_FUNC
		}
	}
	else {
		var _return = return_value;
		__GMLC_POST_FUNC
	}
	
	return _return;
}
#region jsDoc
/// @func    __GMLCcompileConstructor(_rootNode, _parentNode, _node)
/// @desc    Compiles a constructor into a method that runs it. Its statics are chained to its parent's, now or when
///          that parent is compiled later.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A constructor node
/// @returns {Function}
#endregion
function __GMLCcompileConstructor(_rootNode, _parentNode, _node) {
	static __waitingForParent = {};
	
	var _output = new __GMLC_Function(_rootNode, undefined, "__GMLCcompileConstructor", "<Missing Error Message>", _node.span);
	_output[$ "__@@is_gmlc_function@@__"] = true;
	
	_output.parent_node = _output;
	__GMLCdebugFrame(_rootNode, _output, _node, _node.body);
	
	//parent constructor
	_output.has_parent_constructor = false;
	_output.parent_constructor_name = undefined;
	_output.parent_constructor_call = undefined;
	
	_output.recursion_count = 0; 
	
	//locals
	var _locals = __GMLClocalLookUps(_rootNode, _node);
	_output.local_look_ups = _locals.look_ups;
	var _i = _locals.count;
	_output.local_count = _i;
	_output.locals = array_create(_i, undefined);
	_output.blank_locals = array_create(_i, undefined);
	_output.blank_locals_written_to = array_create(_i, false);
	_output.locals_written_to = array_create(_i, false); //remember if we ever wrote to those locals, this is used to throw errors incase we are reading from an unwritten local
	_output.backup_locals = [];//if the function is recursive stash the locals back into this array, to<->from
	_output.backup_locals_written_to = [];//if the function is recursive stash the locals back into this array, to<->from
	
	//arguments
	_output.arguments_default = __GMLCcompileArgumentList(_rootNode, _output, _node.params, _node);
	_output.arguments_length = method_get_self(_output.arguments_default).size;
	_output.previous_argument_count = 0;
	_output.arguments = [];
	_output.backup_arguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argument_count_memory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	//statics
	_output.statics_executed = false;
	_output.statics = new __GMLC_Constructor_Statics(_node.name);
	_output.static_declarations = [];
	static_set(_output, _output.statics)
	
	//block statement
	array_push(_rootNode.scope_stack, "Self");
	_output.program = __GMLCcompileBlockStatement(_rootNode, _output, _node.body);
	array_pop(_rootNode.scope_stack);
	_output.statics_block = __GMLCcompileStatics(_rootNode, _output, _node);
	
	_output.return_value = undefined;
	_output.flow_mask = FLOW_MASK.EMPTY;
	
	if (_node.parent != undefined) {
		var _parentCallee = _node.parent.callee;
		var _parentName = (_parentCallee.kind == __GMLC_NodeKind_Identifier) ? _parentCallee.name : undefined;
		_output.has_parent_constructor = true;
		_output.parent_constructor_name = _parentName;
		_output.parent_constructor_call = __GMLCcompileCallExpression(_rootNode, _output, _node.parent);
		method_get_self(_output.parent_constructor_call).parent_call = true;
		
		//there is probably a better way to check if what we have is indeed a gmlc program or a real script
		var _parent_constuct = (_parentName != undefined) ? _rootNode.globals[$ _parentName] : undefined;
		if (is_gmlc_program(_parent_constuct)) {
			var _our_static = _output.statics
			var _parent_static = method_get_self(_parent_constuct).statics
			static_set(_our_static, _parent_static)
		}
		else if (_parent_constuct != undefined) {
			static_set(_output.statics, static_get(__GMLCidentifierValue(_rootNode, _parentCallee)))
		}
		else if (_parentName != undefined) {
			//the parent is a gmlc program which has yet to be compiled. statics will be set when parent is compiled
			var _waiting = __gmlc_struct_get(__waitingForParent, _parentName);
			if (_waiting == undefined) {
				_waiting = [];
				__waitingForParent[$ _parentName] = _waiting;
			}
			array_push(_waiting, { statics: _output.statics, globals: _rootNode.globals });
		}
		
	}
	else {
		//no parent? just have an empty static
		static_set(_output.statics, static_get({}))
	}
	
	//the children compiled before this constructor (with the same globals) get their statics now,
	// this ensures we're able to compile a child then a parent regardless of order.
	var _waiting = __gmlc_struct_get(__waitingForParent, _node.name);
	if (_waiting != undefined) {
		var _i = array_length(_waiting) - 1; repeat (array_length(_waiting)) {
			if (_waiting[_i].globals == _rootNode.globals) {
				static_set(_waiting[_i].statics, _output.statics);
				array_delete(_waiting, _i, 1);
			}
		_i--}
	}
	
	return __vanilla_method(_output, __GMLCexecuteConstructor)
}

#region jsDoc
/// @func    __GMLCexecuteArgumentList()
/// @desc    Gives the arguments left out or passed as undefined their default value, and copies each into its local.
#endregion
function __GMLCexecuteArgumentList() {
	var _inputArguments = parent_node.arguments
	var _inputLength = array_length(_inputArguments);
	
	var _i=0; repeat(size) {
		var _arg = statements[_i]
		
		if (_i < _inputLength) {
			if (_inputArguments[_i] == undefined) {
				var _val = _arg.expression();
				_inputArguments[_i] = _val;
			}
		}
		else {
			var _val = _arg.expression();
			_inputArguments[_i] = _val;
		}
		
		//apply to the local array
		parent_node.locals[_arg.local_index] = _inputArguments[_i];
		parent_node.locals_written_to[_arg.local_index] = true;
		
	_i++}
}
#region jsDoc
/// @func    __GMLCcompileArgumentList(_rootNode, _parentNode, _params, _node)
/// @desc    Compiles a function's parameters into the executor that applies their defaults.
/// @param   {Struct}        _rootNode   : The program node
/// @param   {Struct}        _parentNode : The function node
/// @param   {Array<Struct>} _params     : The parameter nodes
/// @param   {Struct}        _node       : The function's AST node
/// @returns {Function}
#endregion
function __GMLCcompileArgumentList(_rootNode, _parentNode, _params, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileArgumentList", "<Missing Error Message>", _node.span);
	_output.statements = [];
	_output.size = undefined;
	
	
	var _arr = _params;
	var _i=0; repeat(array_length(_arr)) {
		_output.statements[_i] = __GMLCcompileArgument(_rootNode, _parentNode, _arr[_i], _i);
	_i++}
	
	_output.size = array_length(_output.statements);
	
	return __vanilla_method(_output, __GMLCexecuteArgumentList)
}

#region jsDoc
/// @func    __GMLCcompileArgument(_rootNode, _parentNode, _node, _index)
/// @desc    One parameter as its index, local slot and default value.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The function node
/// @param   {Struct} _node       : The parameter node
/// @param   {Real}   _index      : Its position
/// @returns {Struct}
#endregion
function __GMLCcompileArgument(_rootNode, _parentNode, _node, _index) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileArgument", "<Missing Error Message>", _node.span);
	_output.index = _index;
	_output.local_index = _parentNode.local_look_ups[$ _node.target.name];
	_output.identifier = _node.target.name;
	var _default = _node[$ "default"];
	_output.expression = (_default != undefined) ? __GMLCcompileExpression(_rootNode, _parentNode, _default) : __vanilla_method({ value: undefined }, __GMLCexecuteLiteralExpression);
	
	return _output;
}

#region jsDoc
/// @func    __GMLCcompileStatics(_rootNode, _parentNode, _node)
/// @desc    Compiles the `static` declarations met in a function body (in source order) into the block that runs once,
///          at the first call.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The function node
/// @param   {Struct} _node       : The function's AST node
/// @returns {Function}
#endregion
function __GMLCcompileStatics(_rootNode, _parentNode, _node) {
	var _declarations = _parentNode.static_declarations;
	if (array_length(_declarations) == 0) return function(){};
	// function expressions in a static's value are unbound methods
	array_push(_rootNode.scope_stack, "Static");
	var _compiled = [];
	var _i = 0; repeat (array_length(_declarations)) {
		var _decl = _declarations[_i];
		if (_decl.init != undefined) {
			array_push(_compiled, __GMLCcompilePropertySet(_rootNode, _parentNode, "Static", _decl.target.name, _decl.init, _decl.span));
		}
	_i++}
	array_pop(_rootNode.scope_stack);
	return __GMLCblockOf(_rootNode, _parentNode, _node, _compiled);
}
#region jsDoc
/// @func    __GMLCaddStatics(_parentNode, _node)
/// @desc    Adds the declarations of a `static` statement to the ones its function runs once, at its first call.
/// @param   {Struct} _parentNode : The function node
/// @param   {Struct} _node       : A StaticDecl node
#endregion
function __GMLCaddStatics(_parentNode, _node) {
	var _out = _parentNode.static_declarations;
	array_copy(_out, array_length(_out), _node.declarations, 0, array_length(_node.declarations));
}

#region jsDoc
/// @func    __GMLCcompileFunctionExpr(_rootNode, _parentNode, _node)
/// @desc    Compiles a function expression. Its value depends on where it is: in a constructor body or a struct
///          literal it is a method bound to `self`, in a `static` value an unbound method, elsewhere the function
///          itself. A named one is also registered in the globals.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A FunctionExpr
/// @returns {Function}
#endregion
function __GMLCcompileFunctionExpr(_rootNode, _parentNode, _node) {
	var _scope = _rootNode.scope_stack[array_length(_rootNode.scope_stack) - 1];
	var _compiled = __GMLCcompileFunctionValue(_rootNode, _node);
	switch (_scope) {
		case "Self":   return __vanilla_method({ func: _compiled }, __GMLCexecuteMethodOfSelf);
		case "Static": return __vanilla_method({ func: _compiled }, __GMLCexecuteMethodUnbound);
	}
	return __vanilla_method({ value: _compiled }, __GMLCexecuteLiteralExpression);
}
#region jsDoc
/// @func    __GMLCexecuteMethodOfSelf()
/// @desc    Returns func as a method bound to the current self.
/// @returns {Function}
#endregion
function __GMLCexecuteMethodOfSelf() {
	return __gmlc_method(global.gmlc_self_instance, func);
}
#region jsDoc
/// @func    __GMLCexecuteMethodUnbound()
/// @desc    Returns func as an unbound method.
/// @returns {Function}
#endregion
function __GMLCexecuteMethodUnbound() {
	return __gmlc_method(undefined, func);
}
#region jsDoc
/// @func    __GMLCcompileFunctionValue(_rootNode, _node)
/// @desc    Compiles the function of a function expression (a constructor when it has `constructor`) and registers a
///          named one in the globals.
/// @param   {Struct} _rootNode : The program node
/// @param   {Struct} _node     : A FunctionExpr
/// @returns {Function}
#endregion
function __GMLCcompileFunctionValue(_rootNode, _node) {
	var _compiled = (_node[$ "is_constructor"] == true) ? __GMLCcompileConstructor(_rootNode, undefined, _node) : __GMLCcompileFunction(_rootNode, undefined, _node);
	if (!string_starts_with(_node.name, "GMLC@anon@")) {
		_rootNode.globals[$ _node.name] = _compiled;
	}
	return _compiled;
}

#endregion

#region Statements

#region Block Statements

#region jsDoc
/// @func    __GMLCexecuteBlockStatement()
/// @desc    Runs the block's statements in order, stopping at a break, continue, return or exit.
#endregion
function __GMLCexecuteBlockStatement() {
    var i = 0;
    repeat(size) {
        block_statements[i]();
		// Check for jump conditions.
		if (parent_node.flow_mask) {
			return;
		}
	i++;}
}
// a block with no break, continue, return or exit in it: nothing to check between its statements
#region jsDoc
/// @func    __GMLCexecuteBlockStatementPlain()
/// @desc    Runs the block's statements in order.
#endregion
function __GMLCexecuteBlockStatementPlain() {
	var i = 0;
	repeat(size) {
		block_statements[i]();
	i++;}
}
#region jsDoc
/// @func    __GMLCcompileBlockStatement(_rootNode, _parentNode, _node)
/// @desc    Compiles a block, or a single statement, into one executor.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Block, the Script or a statement
/// @returns {Function}
#endregion
function __GMLCcompileBlockStatement(_rootNode, _parentNode, _node) {
	if (_node == undefined) {
		return function(){};
	}
	
	// If the node is not a block, simply compile it as an expression.
	if (_node.kind != __GMLC_NodeKind_Block) && (_node.kind != __GMLC_NodeKind_Script) {
		return __GMLCcompileExpression(_rootNode, _parentNode, _node);
	}
	
	var _compiled = [];
	__GMLCcompileStatements(_rootNode, _parentNode, _node.body, _compiled);
	return __GMLCblockOf(_rootNode, _parentNode, _node, _compiled);
}
#region jsDoc
/// @func    __GMLCcompileStatements(_rootNode, _parentNode, _statements, _out)
/// @desc    Compiles a list of statements into _out, opening nested blocks and `var` lists into it and leaving out the
///          statements that do nothing at run time.
/// @param   {Struct}        _rootNode   : The program node
/// @param   {Struct}        _parentNode : The enclosing function node
/// @param   {Array<Struct>} _statements : The statements
/// @param   {Array}         _out        : The compiled statements so far
#endregion
function __GMLCcompileStatements(_rootNode, _parentNode, _statements, _out) {
	var _i = 0; repeat(array_length(_statements)) {
		var _statement = _statements[_i];
		switch (_statement.kind) {
			case __GMLC_NodeKind_Empty:
			case __GMLC_NodeKind_GlobalVarDecl: {
			break;}
			case __GMLC_NodeKind_StaticDecl: {
				__GMLCaddStatics(_parentNode, _statement);
			break;}
			case __GMLC_NodeKind_Block: {
				__GMLCcompileStatements(_rootNode, _parentNode, _statement.body, _out);
			break;}
			case __GMLC_NodeKind_VarDeclList: {
				var _d = 0; repeat (array_length(_statement.declarations)) {
					var _decl = _statement.declarations[_d];
					if (_decl.init != undefined) array_push(_out, __GMLCcompileVariableDeclaration(_rootNode, _parentNode, _decl));
				_d++}
			break;}
			case __GMLC_NodeKind_FunctionDecl:
			case __GMLC_NodeKind_ConstructorDecl: {
				var _function = (_statement.kind == __GMLC_NodeKind_ConstructorDecl) ? __GMLCcompileConstructor(_rootNode, undefined, _statement) : __GMLCcompileFunction(_rootNode, undefined, _statement);
				if (_parentNode[$ "is_script_body"] == true) && (_parentNode[$ "is_event_body"] != true) {
					_rootNode.globals[$ _statement.name] = _function;
				}
				else {
					// a function declared inside a function: running the statement makes it a method of `self` under its
					// name, as GameMaker does
					var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileSelfMethod", "<Missing Error Message>", _statement.span);
					_output.key = _statement.name;
					_output.expression = __vanilla_method({ func: _function }, __GMLCexecuteMethodOfSelf);
					array_push(_out, __vanilla_method(_output, __GMLCexecuteSetPropertySelf));
				}
			break;}
			default: {
				if (__GMLCisReleasePragma(_statement)) break;
				var _compiled = __GMLCcompileExpression(_rootNode, _parentNode, _statement);
				array_push(_out, (_parentNode[$ "debug"] == true) ? __GMLCdebugStatement(_rootNode, _parentNode, _statement, _compiled) : _compiled);
			break;}
		}
	_i++}
}

#region Debug executors
#region jsDoc
/// @func    __GMLCdebugFrame(_rootNode, _output, _node, _body)
/// @desc    Sets up a function node for the debug executors: on when the program is compiled in debug and the
///          function's own body has no `gml_pragma("gmlc_release_mode")`, with its name and file for stack traces.
#endregion
function __GMLCdebugFrame(_rootNode, _output, _node, _body) {
	_output.debug = _rootNode.debug;
	if (!_output.debug) return;
	var _statements = (_body == undefined) ? [] : (_body[$ "body"] ?? []);
	var _i = 0; repeat (array_length(_statements)) {
		if (__GMLCisReleasePragma(_statements[_i])) {
			_output.debug = false;
			return;
		}
	_i++}
	var _at = __gmlc_node_position({ span: _node.span, root_node: _rootNode });
	_output.debug_name = _node[$ "name"] ?? ((_node.kind == __GMLC_NodeKind_Script) ? "<script>" : "<anonymous>");
	_output.debug_file = (_at != undefined) ? _at.fileName : "";
	_output.debug_line = (_at != undefined) ? _at.line : 0;
}
#region jsDoc
/// @func    __GMLCisReleasePragma(_statement)
/// @desc    Whether a statement is `gml_pragma("gmlc_release_mode")`: its function runs with the fast executors.
/// @returns {Bool}
#endregion
function __GMLCisReleasePragma(_statement) {
	if (_statement.kind == __GMLC_NodeKind_ExprStmt) _statement = _statement.expression;
	if (_statement.kind != __GMLC_NodeKind_Call) || (_statement.callee.kind != __GMLC_NodeKind_Identifier) return false;
	if (_statement.callee.name != "gml_pragma") || (array_length(_statement.args) != 1) return false;
	var _arg = _statement.args[0];
	return (_arg.kind == __GMLC_NodeKind_Literal) && (_arg.value == "gmlc_release_mode");
}
#region jsDoc
/// @func    __GMLCdebugStatement(_rootNode, _parentNode, _statement, _compiled)
/// @desc    Wraps a statement of a debug function so its line is recorded on the function before it runs.
/// @param   {Struct}   _rootNode   : The program node
/// @param   {Struct}   _parentNode : The enclosing function node
/// @param   {Struct}   _statement  : The statement node
/// @param   {Function} _compiled   : The compiled statement
/// @returns {Function}
#endregion
function __GMLCdebugStatement(_rootNode, _parentNode, _statement, _compiled) {
	var _at = __gmlc_node_position({ span: _statement.span, root_node: _rootNode });
	return __vanilla_method({ parent_node: _parentNode, statement: _compiled, line: (_at != undefined) ? _at.line : 0 }, __GMLCexecuteDebugStatement);
}
#region jsDoc
/// @func    __GMLCexecuteDebugStatement()
/// @desc    Records the statement's line on its function, then runs it.
#endregion
function __GMLCexecuteDebugStatement() {
	parent_node.debug_line = line;
	statement();
}
#region jsDoc
/// @func    __GMLCdebugStacktrace()
/// @desc    The compiled frames running now, innermost first, as "name (file:line)"; frames of fast functions are
///          left out. Empty when no debug function runs.
/// @returns {Array<String>}
#endregion
function __GMLCdebugStacktrace() {
	var _stack = global.__gmlc_active_functions;
	var _out = [];
	var _i = array_length(_stack) - 1; repeat (array_length(_stack)) {
		var _f = _stack[_i];
		if (_f[$ "debug_name"] != undefined) array_push(_out, $"{_f.debug_name} ({_f.debug_file}:{_f.debug_line})");
	_i--}
	return _out;
}
#endregion
#region jsDoc
/// @func    __GMLCblockOf(_rootNode, _parentNode, _node, _compiled)
/// @desc    The compiled statements as one: nothing, the only one, or a block that runs them in order.
/// @returns {Function}
#endregion
function __GMLCblockOf(_rootNode, _parentNode, _node, _compiled) {
	var _size = array_length(_compiled);
	if (_size == 0) {
		return function(){};
	}
	if (_size == 1) {
		return _compiled[0];
	}
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileBlockStatement", "<Missing Error Message>", _node.span);
	_output.block_statements = _compiled;
	_output.size = _size;
	return __vanilla_method(_output, __GMLCcontainsJump(_node) ? __GMLCexecuteBlockStatement : __GMLCexecuteBlockStatementPlain);
}
#region jsDoc
/// @func    __GMLCcontainsJump(_node)
/// @desc    Whether a statement has a break, continue, return or exit in it (not counting the functions declared in
///          it), which the executors of its blocks and loops must look for; kept on the node once found.
/// @param   {Struct} _node : A node
/// @returns {Bool}
#endregion
function __GMLCcontainsJump(_node) {
	if (!is_struct(_node)) return false;
	var _known = _node[$ "__gmlcJump"];
	if (_known != undefined) return _known;
	var _found = false;
	switch (_node[$ "kind"]) {
		case __GMLC_NodeKind_Break:
		case __GMLC_NodeKind_Continue:
		case __GMLC_NodeKind_Return:
		case __GMLC_NodeKind_Exit: {
			_found = true;
		break;}
		case __GMLC_NodeKind_FunctionExpr:
		case __GMLC_NodeKind_FunctionDecl:
		case __GMLC_NodeKind_ConstructorDecl: {
		break;}
		default: {
			var _names = _node[$ "childFields"] ?? [];
			var _i = 0; repeat (array_length(_names)) {
				var _value = _node[$ _names[_i]];
				if (is_array(_value)) {
					var _j = 0; repeat (array_length(_value)) {
						if (is_struct(_value[_j])) && __GMLCcontainsJump(_value[_j]) {
							_found = true;
							break;
						}
					_j++}
				}
				else if (is_struct(_value)) && __GMLCcontainsJump(_value) {
					_found = true;
				}
				if (_found) break;
			_i++}
		break;}
	}
	_node[$ "__gmlcJump"] = _found;
	return _found;
}

#endregion

#region //{
// used for gmlc compiled repeat blocks
//    condition: <expression>,
//    true_block: <expression>,
//}
#endregion
function __GMLCexecuteIf() {
    if (condition())
		true_block();
}
#region //{
// used for gmlc compiled if/else statements
//    condition: <expression>,
//    true_block: <expression>,
//    else_block: <expression>,
//}
#endregion
function __GMLCexecuteIfElse() {
    ///NOTE: it might be faster to use a ternary operation here,
    // it is worth investigating with a benchmark
	if (condition()) {
		true_block()
    }
    else {
		else_block();
    }
}
#region jsDoc
/// @func    __GMLCcompileIf(_rootNode, _parentNode, _node)
/// @desc    Compiles an if statement; an empty or missing else is left out.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : An If node
/// @returns {Function}
#endregion
function __GMLCcompileIf(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileIf", "<Missing Error Message>", _node.span);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.test);
	_output.true_block = __GMLCcompileExpression(_rootNode, _parentNode, _node.consequent);
	
	//if there is no 'else', or an empty one
	if (_node.alternate == undefined)
	|| (array_length(_node.alternate.body) == 0) {
		return __vanilla_method(_output, __GMLCexecuteIf);
    }
	else {
		_output.else_block = __GMLCcompileExpression(_rootNode, _parentNode, _node.alternate);
		return __vanilla_method(_output, __GMLCexecuteIfElse);
    }
}

#region //{
// used for gmlc compiled repeat blocks
//    expression: <expression>,
//    block_statement: {},
//}
#endregion
function __GMLCexecuteRepeat() {
    repeat(condition()) {
		block_statement();
		if (parent_node.flow_mask) {
			if (parent_node.flow_mask & FLOW_MASK.CONTINUE) {
				// Clear the continue bit so that subsequent iterations or parent blocks see it as cleared.
				parent_node.flow_mask &= ~FLOW_MASK.CONTINUE;
			}
			if (parent_node.flow_mask & FLOW_MASK.BREAK) {
				// Clear the break bit so that subsequent iterations or parent blocks see it as cleared.
				parent_node.flow_mask &= ~FLOW_MASK.BREAK;
				return undefined;
			}
			if (parent_node.flow_mask & FLOW_MASK.RETURN) {
				return undefined;
			}
		}
    }
}
#region jsDoc
/// @func    __GMLCexecuteRepeatPlain()
/// @desc    Runs the body the counted number of times (a body with no jump in it).
#endregion
function __GMLCexecuteRepeatPlain() {
	repeat (condition()) {
		block_statement();
	}
}
#region jsDoc
/// @func    __GMLCcompileRepeat(_rootNode, _parentNode, _node)
/// @desc    Compiles a repeat loop.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Repeat node
/// @returns {Function}
#endregion
function __GMLCcompileRepeat(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileRepeat", "<Missing Error Message>", _node.span);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.count);
	_output.block_statement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.body);
    
    return __vanilla_method(_output, __GMLCcontainsJump(_node.body) ? __GMLCexecuteRepeat : __GMLCexecuteRepeatPlain);
}

#region //{
// used for gmlc compiled while blocks
//    expression: <expression>,
//    block_statement: {},
//}
#endregion
function __GMLCexecuteWhile() {
    while(condition()) {
		block_statement();
		if (parent_node.flow_mask) {
			if (parent_node.flow_mask & FLOW_MASK.CONTINUE) {
				// Clear the continue bit so that subsequent iterations or parent blocks see it as cleared.
				parent_node.flow_mask &= ~FLOW_MASK.CONTINUE;
			}
			if (parent_node.flow_mask & FLOW_MASK.BREAK) {
				// Clear the break bit so that subsequent iterations or parent blocks see it as cleared.
				parent_node.flow_mask &= ~FLOW_MASK.BREAK;
				return undefined;
			}
			if (parent_node.flow_mask & FLOW_MASK.RETURN) {
				return undefined;
			}
		}
    }
}
#region jsDoc
/// @func    __GMLCexecuteWhilePlain()
/// @desc    Runs the body while the condition holds (a body with no jump in it).
#endregion
function __GMLCexecuteWhilePlain() {
	while (condition()) {
		block_statement();
	}
}
#region jsDoc
/// @func    __GMLCcompileWhile(_rootNode, _parentNode, _node)
/// @desc    Compiles a while loop.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A While node
/// @returns {Function}
#endregion
function __GMLCcompileWhile(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileWhile", "<Missing Error Message>", _node.span);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.test);
	_output.block_statement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.body);
    
    return __vanilla_method(_output, __GMLCcontainsJump(_node.body) ? __GMLCexecuteWhile : __GMLCexecuteWhilePlain);
}

#region //{
// used for gmlc compiled do/until blocks
//    expression: <expression>,
//    block_statement: {},
//}
#endregion
function __GMLCexecuteDoUntil() {
    do {
		block_statement();
		if (parent_node.flow_mask) {
			if (parent_node.flow_mask & FLOW_MASK.CONTINUE) {
				// Clear the continue bit so that subsequent iterations or parent blocks see it as cleared.
				parent_node.flow_mask &= ~FLOW_MASK.CONTINUE;
			}
			if (parent_node.flow_mask & FLOW_MASK.BREAK) {
				// Clear the break bit so that subsequent iterations or parent blocks see it as cleared.
				parent_node.flow_mask &= ~FLOW_MASK.BREAK;
				return undefined;
			}
			if (parent_node.flow_mask & FLOW_MASK.RETURN) {
				return undefined;
			}
		}
    }
    until condition()
}
#region jsDoc
/// @func    __GMLCexecuteDoUntilPlain()
/// @desc    Runs the body until the condition holds (a body with no jump in it).
#endregion
function __GMLCexecuteDoUntilPlain() {
	do {
		block_statement();
	}
	until condition()
}
#region jsDoc
/// @func    __GMLCcompileDoUntil(_rootNode, _parentNode, _node)
/// @desc    Compiles a do/until loop.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A DoUntil node
/// @returns {Function}
#endregion
function __GMLCcompileDoUntil(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileDoUntil", "<Missing Error Message>", _node.span);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.test);
	_output.block_statement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.body);
    
    return __vanilla_method(_output, __GMLCcontainsJump(_node.body) ? __GMLCexecuteDoUntil : __GMLCexecuteDoUntilPlain);
}

#region //{
// used for gmlc compiled for statements
//    assignment: <expression>,
//    expression: <expression>,
//    operation: <expression>,
//    block_statement: <block_statement>,
//}
#endregion
function __GMLCexecuteFor() {
    for (
		assignment();
		condition();
		{operation();
			if (parent_node.flow_mask) {
				if (parent_node.flow_mask & FLOW_MASK.CONTINUE) {
					// Clear the continue bit so that subsequent iterations or parent blocks see it as cleared.
					parent_node.flow_mask &= ~FLOW_MASK.CONTINUE;
				}
				if (parent_node.flow_mask & FLOW_MASK.BREAK) {
					// Clear the break bit so that subsequent iterations or parent blocks see it as cleared.
					parent_node.flow_mask &= ~FLOW_MASK.BREAK;
					return undefined;
				}
				if (parent_node.flow_mask & FLOW_MASK.RETURN) {
					return undefined;
				}
			}
		}
	) {
		block_statement();
		if (parent_node.flow_mask) {
			if (parent_node.flow_mask & FLOW_MASK.CONTINUE) {
				// Clear the continue bit so that subsequent iterations or parent blocks see it as cleared.
				parent_node.flow_mask &= ~FLOW_MASK.CONTINUE;
			}
			if (parent_node.flow_mask & FLOW_MASK.BREAK) {
				// Clear the break bit so that subsequent iterations or parent blocks see it as cleared.
				parent_node.flow_mask &= ~FLOW_MASK.BREAK;
				return undefined;
			}
			if (parent_node.flow_mask & FLOW_MASK.RETURN) {
				return undefined;
			}
		}
    }
}
#region jsDoc
/// @func    __GMLCexecuteForPlain()
/// @desc    Runs a for loop whose body has no jump in it.
#endregion
function __GMLCexecuteForPlain() {
	for (assignment(); condition(); operation()) {
		block_statement();
	}
}
#region jsDoc
/// @func    __GMLCcompileFor(_rootNode, _parentNode, _node)
/// @desc    Compiles a for loop; a missing part does nothing (a missing test is true).
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A For node
/// @returns {Function}
#endregion
function __GMLCcompileFor(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileFor", "<Missing Error Message>", _node.span);
	_output.assignment     = (_node.init   == undefined) ? function(){}            : __GMLCcompileBlockStatement(_rootNode, _parentNode, new ASTBlock(_node.init.span, [_node.init]));
	_output.condition      = (_node.test   == undefined) ? function(){return true} : __GMLCcompileExpression(_rootNode, _parentNode, _node.test);
	_output.operation      = (_node.update == undefined) ? function(){}            : __GMLCcompileBlockStatement(_rootNode, _parentNode, new ASTBlock(_node.update.span, [_node.update]));
	_output.block_statement = (_node.body   == undefined) ? function(){}            : __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.body);
    
	return __vanilla_method(_output, __GMLCcontainsJump(_node.body) ? __GMLCexecuteFor : __GMLCexecuteForPlain);
}

#region //{
// used for gmlc compiled switch/case statements
//    expression: <expression>,
//    cases: struct<blockStatementsBreakable>
//    size: array_length(cases)
//}
#endregion
function __GMLCexecuteSwitch() {
    var _value = expression();
	
	// the first case whose label equals the value, else `default`; from there the cases run in source order until
	// a break, so a `default` written before other cases falls through into them, as in GameMaker
	var _start = default_index;
	var _i=0; repeat(label_count) {
		if (labels[_i]() == _value) {
			_start = label_cases[_i];
			break;
		}
	_i++}
	if (_start < 0) return undefined;
	
	var _i=_start; repeat(size - _start) {
		cases[_i].block_statement()
		if (parent_node.flow_mask) {
			if (parent_node.flow_mask & FLOW_MASK.RETURN) return undefined;
			// a break ends the switch; a continue leaves it for the loop around it
			break;
		}
	_i++}
	
	parent_node.flow_mask &= ~FLOW_MASK.BREAK;
}
#region jsDoc
/// @func    __GMLCcompileSwitch(_rootNode, _parentNode, _node)
/// @desc    Compiles a switch: its value, its cases in source order and where `default` is.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Switch node
/// @returns {Function}
#endregion
function __GMLCcompileSwitch(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileSwitch", "<Missing Error Message>", _node.span);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.discriminant);
	_output.cases = [];
	_output.labels = [];     // `default` left out
	_output.label_cases = [];
	_output.default_index = -1;
	_output.size = 0;
    
    
    var _i=0; repeat(array_length(_node.cases)) {
		var _case = _node.cases[_i];
		var _struct = __GMLCcompileCase(_rootNode, _parentNode, _case);
		
		//set the case as default or push to cases
		if (_struct.is_default) {
			_output.default_index = _i;
		}
		else {
			array_push(_output.labels, _struct.expression);
			array_push(_output.label_cases, _i);
		}
		array_push(_output.cases, _struct);
    
    _i++}
    
    _output.size = array_length(_output.cases);
    _output.label_count = array_length(_output.labels);
    
    return __vanilla_method(_output, __GMLCexecuteSwitch);
}
#region jsDoc
/// @func    __GMLCcompileCase(_rootNode, _parentNode, _node)
/// @desc    Compiles one case or default into its label and its statements.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Case or Default node
/// @returns {Struct}
#endregion
function __GMLCcompileCase(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileCase", "<Missing Error Message>", _node.span);
	_output.is_default = (_node.kind == __GMLC_NodeKind_Default);
	_output.expression = (_output.is_default) ? undefined : __GMLCcompileExpression(_rootNode, _parentNode, _node.test);
	_output.block_statement = __GMLCcompileBlockStatement(_rootNode, _parentNode, new ASTBlock(_node.span, _node.body));
    
    
    return _output;
}

#region //{
// used to execute gmlc compiled `with` statements
//    expression: <expression>
//    block_statement: <blockStatementBreakable>
//}
#endregion
function __GMLCexecuteWith() {
    //early out
    var _inst = expression()
	if (_inst == undefined) return undefined
	if (_inst == -5) { _inst = root_node.globals}// safety check for `-5` equalling `global`
    
    var _self = global.gmlc_self_instance;
    var _other = global.gmlc_other_instance;
    
    //this mimics a with statement, but ultimately its not actually need to use `with`
    // until we hit a natively compiled function, as all glmc functions will directly
    // handle the instance
    global.gmlc_other_instance = global.gmlc_self_instance
    
	var _methodself   = self;
	var _parentNode   = parent_node;
	
	static __empty_arr = [];
	with (_inst) {
		global.gmlc_self_instance = self;
		
		method_call(_methodself.block_statement, __empty_arr);
		
		//we break on all three cases here because we would like to run the
		// rest of the function to return to our previous self/other
		if (_parentNode.flow_mask) {
			if (_parentNode.flow_mask & FLOW_MASK.CONTINUE) {
				// Clear the continue bit so that subsequent iterations or parent blocks see it as cleared.
				_parentNode.flow_mask &= ~FLOW_MASK.CONTINUE;
			}
			if (_parentNode.flow_mask & FLOW_MASK.BREAK) {
				// Clear the break bit so that subsequent iterations or parent blocks see it as cleared.
				_parentNode.flow_mask &= ~FLOW_MASK.BREAK;
				break;
			}
			if (_parentNode.flow_mask & FLOW_MASK.RETURN) {
				// Clear the return bit so that subsequent iterations or parent blocks see it as cleared.
				break;
			}
		}
		
	}
    
    //reset
    global.gmlc_self_instance = _self;
    global.gmlc_other_instance = _other;
}
#region jsDoc
/// @func    __GMLCcompileWith(_rootNode, _parentNode, _node)
/// @desc    Compiles a with statement.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A With node
/// @returns {Function}
#endregion
function __GMLCcompileWith(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileWith", "<Missing Error Message>", _node.span);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.target);
	_output.block_statement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.body);
	
	return __vanilla_method(_output, __GMLCexecuteWith);
}

#region //{
// used to execute gmlc compiled `try/catch/finally` statements
//    try_block: <block>
//    catch_block: <block>
//    finally_block: <block>
//    catchVariable: <string>
//}
#endregion
function __GMLCexecuteTryCatchFinally() {
	// one GML try per compiled try, so GameMaker's own rules for finally apply (it does not run when the catch
	// block itself throws). An error unwinds the compiled functions and the `with` it left (self and other) before
	// the catch or finally runs.
	var _depth = array_length(global.__gmlc_active_functions);
	var _self = global.gmlc_self_instance;
	var _other = global.gmlc_other_instance;
	try {
		try_block()
	}
	catch (_e) {
		__GMLCunwindTo(_depth);
		global.gmlc_self_instance = _self;
		global.gmlc_other_instance = _other;
		if (parent_node.flow_mask & FLOW_MASK.RETURN) return;
		parent_node.locals[catch_variable_index] = _e;
		parent_node.locals_written_to[catch_variable_index] = true;
		catch_block()
	}
	finally {
		if (finally_block != undefined) __GMLCrunFinally(parent_node, finally_block);
	}
}
#region jsDoc
/// @func    __GMLCexecuteTryFinally()
/// @desc    Runs a try with a finally and no catch: an error puts back the compiled functions and the self and
///          other it left, runs the finally, and goes on being thrown.
#endregion
function __GMLCexecuteTryFinally() {
	var _depth = array_length(global.__gmlc_active_functions);
	var _self = global.gmlc_self_instance;
	var _other = global.gmlc_other_instance;
	try {
		try_block()
	}
	finally {
		__GMLCunwindTo(_depth);
		global.gmlc_self_instance = _self;
		global.gmlc_other_instance = _other;
		__GMLCrunFinally(parent_node, finally_block);
	}
}

#region jsDoc
/// @func    __GMLCrunFinally(_parentNode, _finallyBlock)
/// @desc    Runs a finally block to its end after a return, break or continue left the try: the pending jump is set
///          aside while it runs, then goes on unless the finally made its own.
#endregion
function __GMLCrunFinally(_parentNode, _finallyBlock) {
	var _mask = _parentNode.flow_mask;
	_parentNode.flow_mask = FLOW_MASK.EMPTY;
	_finallyBlock();
	if (_parentNode.flow_mask == FLOW_MASK.EMPTY) _parentNode.flow_mask = _mask;
}
#region jsDoc
/// @func    __GMLCcompileTryCatchFinally(_rootNode, _parentNode, _node)
/// @desc    Compiles a try statement; with neither catch nor finally it is its block alone.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Try node
/// @returns {Function}
#endregion
function __GMLCcompileTryCatchFinally(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileTryCatchFinally", "<Missing Error Message>", _node.span);
	_output.try_block = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.block);
	_output.catch_variable_index = (_node.catch_param != undefined) ? _parentNode.local_look_ups[$ _node.catch_param.name] : undefined;
	_output.catch_block = undefined;
	_output.finally_block = undefined;
	
	
	if (_node.catch_body != undefined)   _output.catch_block   = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.catch_body)
	if (_node.finally_body != undefined) _output.finally_block = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.finally_body)
	
	if (_node.catch_body == undefined)
	&& (_node.finally_body == undefined) {
		return _output.try_block;
	}
	
    return __vanilla_method(_output, (_output.catch_block == undefined) ? __GMLCexecuteTryFinally : __GMLCexecuteTryCatchFinally);
}

#endregion

#region Keyword Statements

#region //{
// used for gmlc compiled `new` expressions
//    callee
//    callee_name
//    argArr
//    size
//}
#endregion
function __GMLCexecuteNewExpression() {
	var _func = callee();
	if (_func != last_function) {
		var _callable = _func;
		if (!is_method(_func)) {
			if (!is_callable(_func)) {
				throw $"Attempting to call new method on a non-callable value :: `{_func}`"
			}
			_callable = __GMLCcallableFromIndex(root_node, _func);
		}
		last_is_gmlc = is_gmlc_constructor(_callable);
		last_callable = _callable;
		last_function = _func;
	}
	_func = last_callable;

	//mostly just used in recursion code
	var _arg_count = max(argument_count, arguments_length)
	
	if (recursion_count++) {
        // stash the arguments
        __GMLC_STASH_ARGUMENTS
    }
	
	//remember how many the function had
	previous_argument_count = _arg_count;
	
	//avoids garbage collection lag spikes
	array_resize(arguments, arguments_length);
	var _i=arguments_length-1; repeat(arguments_length) {
		arguments[_i] = argument_expressions[_i]();
	_i--}
	
	// GMLC constructors need the program data as `other` (constructor_call_ext); native constructors get a real `new`
	var _struct;
	if (last_is_gmlc) {
		_struct = {};
		var _args = arguments;
		with (method_get_self(_func) ?? self) with (_struct) {
			script_execute_ext(_func, _args);
		}
	}
	else {
		_struct = __gmlc_new_native(_func, arguments);
	}
	
	if (--recursion_count) {
        // Un-stash the arguments
		__GMLC_UNSTASH_ARGUMENTS
    }
	else {
		array_resize(arguments, 0);
		if (array_length(backup_arguments)) {
			throw_gmlc_error($"huh... the array sizes aren't correct\narray_length(backup_arguments) == {array_length(backup_arguments)}")
		}
	}
	
	return _struct;
	
}
#region jsDoc
/// @func    __GMLCcompileNewExpression(_rootNode, _parentNode, _node)
/// @desc    Compiles a `new` expression.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A New node
/// @returns {Function}
#endregion
function __GMLCcompileNewExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileNewExpression", "<Missing Error Message>", _node.span);
	_output.last_function = undefined;
	_output.last_callable = undefined;
	_output.last_is_gmlc = false;
	
	var _argArr = _node.args;
	_output.callee = __GMLCcompileCallee(_rootNode, _parentNode, _node.callee);
	
	_output.recursion_count = 0; 
	_output.previous_argument_count = 0;
	_output.arguments_length = array_length(_argArr);
	_output.argument_expressions = array_create(_output.arguments_length);
	_output.arguments = array_create(_output.arguments_length);
	_output.backup_arguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argument_count_memory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	var _i=0; repeat(array_length(_argArr)) {
		_output.argument_expressions[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _argArr[_i])
	_i++}
    
    return __vanilla_method(_output, __GMLCexecuteNewExpression);
}
#region //{
// used to inform gmlc that a break has occured
//    no data needed
//}
#endregion
function __GMLCexecuteBreak() {
    parent_node.flow_mask |= FLOW_MASK.BREAK;
}
#region jsDoc
/// @func    __GMLCcompileBreak(_rootNode, _parentNode, _node)
/// @desc    Compiles a break statement.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Break node
/// @returns {Function}
#endregion
function __GMLCcompileBreak(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileBreak", "<Missing Error Message>", _node.span);
	
    return __vanilla_method(_output, __GMLCexecuteBreak);
}
#region //{
// used to inform gmlc that a continue has occured
//    no data needed
//}
#endregion
function __GMLCexecuteContinue() {
    parent_node.flow_mask |= FLOW_MASK.CONTINUE;
}
#region jsDoc
/// @func    __GMLCcompileContinue(_rootNode, _parentNode, _node)
/// @desc    Compiles a continue statement.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Continue node
/// @returns {Function}
#endregion
function __GMLCcompileContinue(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileContinue", "<Missing Error Message>", _node.span);
	
    return __vanilla_method(_output, __GMLCexecuteContinue);
}
#region //{
// used to inform gmlc that an exit has occured
//    no data needed
//}
#endregion
function __GMLCexecuteExit() {
    parent_node.flow_mask |= FLOW_MASK.RETURN;
    parent_node.return_value = undefined;
}
#region jsDoc
/// @func    __GMLCcompileExit(_rootNode, _parentNode, _node)
/// @desc    Compiles an exit statement (also a return without a value).
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : An Exit or Return node
/// @returns {Function}
#endregion
function __GMLCcompileExit(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileExit", "<Missing Error Message>", _node.span);
	
    return __vanilla_method(_output, __GMLCexecuteExit);
}
#region //{
// used to inform gmlc that an exit has occured
//    expression: <expression>
//}
#endregion
function __GMLCexecuteReturn() {
    parent_node.return_value = expression();
	parent_node.flow_mask |= FLOW_MASK.RETURN;
}
#region jsDoc
/// @func    __GMLCcompileReturn(_rootNode, _parentNode, _node)
/// @desc    Compiles a return statement.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Return node
/// @returns {Function}
#endregion
function __GMLCcompileReturn(_rootNode, _parentNode, _node) {
	if (_node[$ "argument"] == undefined) {
		return __GMLCcompileExit(_rootNode, _parentNode, _node);
	}
	
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileReturn", "<Missing Error Message>", _node.span);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node[$ "argument"])
    
    return __vanilla_method(_output, __GMLCexecuteReturn);
}
#region //{
// used to throw a value
//    expression: <expression>
//}
#endregion
function __GMLCexecuteThrow() {
	// `throw x` throws x itself (a string stays a string in the catch), as in GameMaker
	throw expression();
}
#region jsDoc
/// @func    __GMLCcompileThrow(_rootNode, _parentNode, _node)
/// @desc    Compiles a throw statement.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Throw node
/// @returns {Function}
#endregion
function __GMLCcompileThrow(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileThrow", "<Missing Error Message>", _node.span);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node[$ "argument"])
    
    return __vanilla_method(_output, __GMLCexecuteThrow);
}

#endregion

#region Expressions

#region //{
// used to fetch Literal values
//    value: <any>,
//}
#endregion
function __GMLCexecuteLiteralExpression() {
    return value;
}
#region jsDoc
/// @func    __GMLCcompileLiteralExpression(_rootNode, _parentNode, _node)
/// @desc    Compiles a literal into an executor returning its value.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Literal node
/// @returns {Function}
#endregion
function __GMLCcompileLiteralExpression(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileLiteralExpression", "<Missing Error Message>", _node.span);
	_output.value = _node.value;
    
    
    return __vanilla_method(_output, __GMLCexecuteLiteralExpression);
}

#region //{
// used to call a dot-accessor method: target.key(args)
//    target: <expression>,   the object before the dot (evaluated once)
//    key:    <string>,        the property name
//    argArr: array<expression>,
//}
#endregion
function __GMLCexecuteCallMethodExpression() {
	// GameMaker evaluates the target before the arguments (right to left); evaluate it once, used for both scoping
	// and function lookup
	var _raw_target = target();
	
	//mostly just used in recursion code
	var _arg_count = max(argument_count, arguments_length)
	
	if (recursion_count++) {
        // stash the arguments
        __GMLC_STASH_ARGUMENTS
    }
	
	//remember how many the function had
	previous_argument_count = _arg_count;
	
	
	//avoids garbage collection lag spikes
	array_resize(arguments, 0);
	
	var _prevOther = global.gmlc_other_instance;
	var _prevSelf  = global.gmlc_self_instance;
	var _return = undefined;
	var _i=arguments_length-1; repeat(arguments_length) {
		arguments[_i] = argument_expressions[_i]();
	_i--}
	
	var _scope_target = _raw_target;
	if (is_gmlc_function(_scope_target)) {
		_scope_target = __gmlc_static_get(_scope_target);
	}

	// Update scope to the object before the dot
	if (_scope_target != undefined)
	&& (_scope_target != _prevSelf) {
		global.gmlc_other_instance = _prevSelf;
		global.gmlc_self_instance  = _scope_target;
	}

	// Find function in target struct or its static chain
	var _func = undefined;
	if (struct_exists(_scope_target, key)) {
		_func = _scope_target[$ key];
	}
	else {
		var _static = __gmlc_static_get(_scope_target);
		while (_static != undefined) {
			if (struct_exists(_static, key)) {
				_func = _static[$ key];
				break;
			}
			_static = __gmlc_static_get(_static);
		}
	}

	if (_func == undefined) {
		throw_gmlc_error($"Variable <{typeof(_scope_target)}>.{key} not set before reading it." + ((callstack != undefined) ? "\n" + json_stringify(callstack, true) : ""))
	}

	// a constructor called directly throws as in GameMaker, once the call's state is restored below;
	// script_execute and method_call still run a constructor's body on self
	var _directConstructor = false;
	if (is_method(_func)) {
		if (_func != last_function) {
			last_kind = __GMLCcallKind(_func);
			last_callable = (last_kind == GMLC_CALL_KIND.FUNCTION) ? method_get_self(_func).invoke_with_array : _func;
			last_function = _func;
		}
		switch (last_kind) {
			case GMLC_CALL_KIND.FUNCTION: {
				_return = last_callable(arguments);
			break;}
			case GMLC_CALL_KIND.GMLC: {
				_return = method_call(_func, arguments);
			break;}
			case GMLC_CALL_KIND.CONSTRUCTOR:
			case GMLC_CALL_KIND.BOUND_CONSTRUCTOR: {
				_directConstructor = true;
			break;}
			default: {
				// an unbound method runs on the struct before the dot, as in GameMaker
				var _args = arguments;
				with (_scope_target ?? _prevSelf) {
					_return = method_call(_func, _args);
				}
			break;}
		}
	}
	else {
		var _args = arguments;
		var _callable = __GMLCcallableFromIndex(root_node, _func);
		with (global.gmlc_other_instance) with (global.gmlc_self_instance) {
			_return = method_call(_callable, _args);
		}
	}

	// Restore scope
	global.gmlc_other_instance = _prevOther;
	global.gmlc_self_instance  = _prevSelf;
	
	if (--recursion_count) {
		__GMLC_UNSTASH_ARGUMENTS
	}
	else {
		array_resize(arguments, 0);
		if (array_length(backup_arguments)) {
			throw_gmlc_error($"huh... the array sizes aren't correct\narray_length(backup_arguments) == {array_length(backup_arguments)}")
		}
	}

	if (_directConstructor) throw_gmlc_error("calling a constructor directly - constructors should only be called using new");
	return _return;
}
#region jsDoc
/// @func    __GMLCcompileCallMethodExpression(_rootNode, _parentNode, _node)
/// @desc    Compiles a call through a dot, `target.key(args)`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A MethodCall node
/// @returns {Function}
#endregion
function __GMLCcompileCallMethodExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileCallMethodExpression", "<Missing Error Message>", _node.span);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _node.object);
	_output.key    = _node.member;
	_output.last_function = undefined;
	_output.last_callable = undefined;
	_output.last_kind = GMLC_CALL_KIND.NATIVE;
	
	_output.recursion_count  = 0;
	_output.previous_argument_count    = 0;
	_output.arguments_length   = array_length(_node.args);
	_output.argument_expressions = array_create(_output.arguments_length);
	_output.arguments       = array_create(_output.arguments_length);
	_output.backup_arguments = [];
	_output.argument_count_memory  = [];

	var _argArr = _node.args;
	var _i=0; repeat(array_length(_argArr)) {
		_output.argument_expressions[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _argArr[_i])
	_i++}

	return __vanilla_method(_output, __GMLCexecuteCallMethodExpression);
}

#region //{
// used to call functions
//    callee: <method, function, or program>,
//    argArr: array<expression>,
//}
#endregion
#region jsDoc
/// @func    __GMLCcallbackArgs(_name)
/// @desc    Returns the parameters of a built-in that take a function or script, as [index, alsoTakesReal] pairs, or
///          undefined when it has none.
/// @param   {String} _name : Built-in function name
/// @returns {Array<Array>|Undefined}
#endregion
function __GMLCcallbackArgs(_name) {
	static __cache = {};
	if (struct_exists(__cache, _name)) return __cache[$ _name];
	
	// GmlSpec types array_sort's sort function as Any (it also takes a Bool)
	if (_name == "array_sort") {
		__cache[$ _name] = [[1, true]];
		return __cache[$ _name];
	}
	var _result = undefined;
	var _entry = __gmlc_built_ins()[$ _name];
	if (_entry != undefined) && (_entry.type == "envFunctions") {
		var _params = _entry.feather.parameters;
		var _i=0; repeat(array_length(_params)) {
			var _types = string_split(_params[_i].type ?? "", ",");
			var _callable = false;
			var _real = false;
			var _j=0; repeat(array_length(_types)) {
				switch (_types[_j]) {
					case "Function": case "Asset.GMScript": case "Asset.Script": case "Id.Script": _callable = true; break;
					case "Real": _real = true; break;
				}
			_j++}
			if (_callable) {
				_result ??= [];
				array_push(_result, [_i, _real]);
			}
		_i++}
	}
	__cache[$ _name] = _result;
	return _result;
}
#region jsDoc
/// @func    __GMLCcheckCallbackArgs(_node)
/// @desc    Checks the function and script arguments of a call to a built-in: a plain function number must be one the
///          program's environment exposes. The last value checked per argument is kept on the node, so a loop that
///          passes the same one checks it once.
/// @param   {Struct} _node : The executing call node
#endregion
function __GMLCcheckCallbackArgs(_node) {
	var _list = _node.callback_arguments;
	var _args = _node.arguments;
	var _i=0; repeat(array_length(_list)) {
		var _index = _list[_i][0];
		if (_index < array_length(_args)) {
			var _value = _args[_index];
			// a negative number where the parameter also takes a Real is a "none" value (-1), not a function
			if (_value != _node.callback_checked[_i]) && (!is_method(_value)) && !is_bool(_value) && (is_callable(_value)) && !(_list[_i][1] && is_numeric(_value) && _value < 0) {
				__GMLCcallableFromIndex(_node.root_node, _value);
				_node.callback_checked[_i] = _value;
			}
		}
	_i++}
}
#region jsDoc
/// @func    __GMLCcallableFromIndex(_rootNode, _index)
/// @desc    Returns the function to call for a callable that is a plain number (a built-in or script function read as
///          a value, as in GameMaker): only one the program's environment exposes. A program compiled without an
///          environment calls any function, as GameMaker does.
/// @param   {Struct} _rootNode : The program node
/// @param   {Real}   _index    : The function number
/// @returns {Function}
#endregion
function __GMLCcallableFromIndex(_rootNode, _index) {
	var _env = _rootNode[$ "env"];
	if (_env == undefined) return method(undefined, _index);
	return _env.callableFromIndex(_index);
}
#region jsDoc
/// @func    __GMLCexecuteCallExpression()
/// @desc    Evaluates the arguments (right to left), then the callee, and calls it the way its kind of function needs.
///          Returns its result; a constructor called without `new` throws.
/// @returns {Any}
#endregion
function __GMLCexecuteCallExpression() {
	//mostly just used in recursion code
	var _arg_count = max(argument_count, arguments_length)
	
	if (recursion_count++) {
        // stash the arguments
        __GMLC_STASH_ARGUMENTS
    }
	
	//remember how many the function had
	previous_argument_count = _arg_count;
	
	//avoids garbage collection lag spikes
	array_resize(arguments, 0);
	
	var _return = undefined;
	// GameMaker evaluates the arguments right to left, then the callee
	var _i=arguments_length-1; repeat(arguments_length) {
		arguments[_i] = argument_expressions[_i]();
	_i--}
	if (callback_arguments != undefined) __GMLCcheckCallbackArgs(self);

	var _func = callee();
	// the kind of function is checked once per callee: the checks cost more than the call itself
	if (_func != last_function) {
		var _callable = _func;
		if (!is_method(_func)) {
			if (!is_callable(_func)) {
				throw $"Attempting to call method on a non-callable value :: `{_func}`"
			}
			// a function held as a plain number (a variable set to `get_timer`, as in GameMaker): only an exposed one
			_callable = __GMLCcallableFromIndex(root_node, _func);
		}
		last_kind = __GMLCcallKind(_callable);
		last_callable = (last_kind == GMLC_CALL_KIND.FUNCTION) ? method_get_self(_callable).invoke_with_array : _callable;
		last_function = _func;
	}
	_func = last_callable;

	// a constructor called directly throws as in GameMaker, once the call's state is restored below;
	// script_execute and method_call still run a constructor's body on self
	var _directConstructor = false;
	switch (last_kind) {
		case GMLC_CALL_KIND.FUNCTION: {
			_return = _func(arguments);
		break;}
		case GMLC_CALL_KIND.GMLC: {
			_return = method_call(_func, arguments);
		break;}
		case GMLC_CALL_KIND.CONSTRUCTOR: {
			if (!parent_call) {
				_directConstructor = true;
				break;
			}
			var _program_data = method_get_self(_func);
			var _program_func = method_get_index(_func);
			var _arguments = arguments;
			with (_program_data) {
				_return = script_execute_ext(_program_func, _arguments);
			}
		break;}
		case GMLC_CALL_KIND.BOUND_CONSTRUCTOR: {
			_directConstructor = true;
		break;}
		default: {
			var _self = method_get_self(_func);
			var _args = arguments;
			var _prevOther = global.gmlc_other_instance;
			var _prevSelf  = global.gmlc_self_instance;

			// a bound method runs on its own self; an unbound built-in keeps the caller's self, so a callback into
			// compiled code (script_execute inside `with`) still sees the right instance
			if (_self != undefined) {
				global.gmlc_other_instance = _prevSelf;
				global.gmlc_self_instance = _self;
			}
			with (_prevSelf) {
				_return = method_call(_func, _args);
			}

			global.gmlc_other_instance = _prevOther;
			global.gmlc_self_instance  = _prevSelf;
		break;}
	}

	if (--recursion_count) {
        // Un-stash the arguments
		__GMLC_UNSTASH_ARGUMENTS
    }
	else {
		array_resize(arguments, 0);
		if (array_length(backup_arguments)) {
			throw_gmlc_error($"huh... the array sizes aren't correct\narray_length(backup_arguments) == {array_length(backup_arguments)}")
		}
	}
	
	if (_directConstructor) throw_gmlc_error("calling a constructor directly - constructors should only be called using new");
	return _return;
}
#region jsDoc
/// @func    __GMLCcompileCallee(_rootNode, _parentNode, _callee)
/// @desc    Compiles the callee of a call. A built-in or script function named directly is a plain number (as GameMaker
///          has it when read as a value); a call needs a method, so it is wrapped once here instead of on every call.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _callee     : The callee's AST node
/// @returns {Function}
#endregion
function __GMLCcompileCallee(_rootNode, _parentNode, _callee) {
	if (_callee.kind == __GMLC_NodeKind_Identifier)
	&& (_callee.symbol != undefined) && (_callee.symbol.kind == "BuiltinFunction") {
		var _value = __GMLCidentifierValue(_rootNode, _callee);
		if (!is_method(_value)) && (is_callable(_value)) {
			return method({ value: method(undefined, _value) }, __GMLCexecuteLiteralExpression);
		}
	}
	return __GMLCcompileExpression(_rootNode, _parentNode, _callee);
}
#region jsDoc
/// @func    __GMLChashStructKey(_rootNode, _node)
/// @desc    A call of `struct_get` or `variable_struct_get` (two arguments), or of `struct_set` or
///          `variable_struct_set` (three), whose key is a constant string, as the matching `*_from_hash` call. Done
///          only here, while the methods are built: a hash depends on the game that runs (and on the order its mods
///          load), so no output that is kept may hold one. Any other call comes back as it is.
/// @param   {Struct} _rootNode : The program node
/// @param   {Struct} _node     : The Call node, whose callee is a built-in function's name
/// @returns {Struct}
#endregion
function __GMLChashStructKey(_rootNode, _node) {
	var _callee = _node.callee;
	var _args = _node.args;
	var _count = array_length(_args);
	if (_count < 2) || (_args[1].kind != __GMLC_NodeKind_Literal) || (!is_string(_args[1].value)) return _node;
	var _function = __GMLCidentifierValue(_rootNode, _callee);
	var _name = undefined;
	if ((_function == struct_get) || (_function == variable_struct_get)) && (_count == 2) {
		_name = "struct_get_from_hash";
	}
	else if ((_function == struct_set) || (_function == variable_struct_set)) && (_count == 3) {
		_name = "struct_set_from_hash";
	}
	if (_name == undefined) || (!_rootNode.env.isFunction(_name)) return _node;

	var _hash = variable_get_hash(_args[1].value);
	var _hashed = array_create(_count);
	array_copy(_hashed, 0, _args, 0, _count);
	_hashed[1] = new ASTLiteral(_args[1].span, "real", string(_hash), _hash);
	var _identifier = new ASTIdentifier(_callee.span, _name);
	_identifier.symbol = new GMLC_Symbol("BuiltinFunction", _name);
	return new ASTCall(_node.span, _identifier, _hashed, _node.origin);
}
#region jsDoc
/// @func    __GMLCcompileCallExpression(_rootNode, _parentNode, _node)
/// @desc    Compiles a call; a struct get or set with a constant key becomes its hashed form first.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Call node
/// @returns {Function}
#endregion
function __GMLCcompileCallExpression(_rootNode, _parentNode, _node) {
	var _isBuiltin = (_node.callee.kind == __GMLC_NodeKind_Identifier) && (_node.callee.symbol != undefined) && (_node.callee.symbol.kind == "BuiltinFunction");
	if (_isBuiltin) _node = __GMLChashStructKey(_rootNode, _node);
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileCallExpression", "<Missing Error Message>", _node.span);
	_output.callee = __GMLCcompileCallee(_rootNode, _parentNode, _node.callee);
	
	_output.callee_name = (_node.callee.kind == __GMLC_NodeKind_Identifier) ? _node.callee.name : "<Call Expression>"
	_output.callback_arguments = (_isBuiltin) ? __GMLCcallbackArgs(_output.callee_name) : undefined;
	_output.callback_checked = array_create(array_length(_output.callback_arguments ?? []), undefined);
	_output.parent_call = false; // the parent call of a constructor (`: P()`), which runs P's body on the new struct
	_output.last_function = undefined;
	_output.last_callable = undefined;
	_output.last_kind = GMLC_CALL_KIND.NATIVE;
	
	_output.recursion_count = 0; 
	_output.previous_argument_count = 0;
	_output.arguments_length = array_length(_node.args);
	_output.argument_expressions = array_create(_output.arguments_length);
	_output.arguments = array_create(_output.arguments_length);
	_output.backup_arguments = [];
	_output.argument_count_memory = [];

	var _argArr = _node.args
	var _i=0; repeat(array_length(_argArr)) {
		_output.argument_expressions[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _argArr[_i])
	_i++}
    
    return __vanilla_method(_output, __GMLCexecuteCallExpression);
}

#region jsDoc
/// @func    __GMLCcompileVariableDeclaration(_rootNode, _parentNode, _node)
/// @desc    Compiles one `var name = value` as a write of the local.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A VarDecl node
/// @returns {Function}
#endregion
function __GMLCcompileVariableDeclaration(_rootNode, _parentNode, _node) {
	var _output = __GMLCscopeNode(_rootNode, _parentNode, "Local", _node.target.name, _node.span);
	_output.expression = (_node.init != undefined) ? __GMLCcompileExpression(_rootNode, _parentNode, _node.init) : __vanilla_method({ value: undefined }, __GMLCexecuteLiteralExpression);
	
	return __vanilla_method(_output, __GMLCGetScopeSetter("Local"))
	
}

#region Call kinds
enum GMLC_CALL_KIND {
	GMLC,              // a GMLC method or program: it runs through its own executor
	FUNCTION,          // a compiled function: its node takes the call's argument array (invoke_with_array)
	CONSTRUCTOR,
	BOUND_CONSTRUCTOR, // a compiled constructor bound with method(), called without new
	NATIVE,
}

#region jsDoc
/// @func    __GMLCcallKind(_func)
/// @desc    How a compiled call runs a function: compiled function, GMLC method or program, constructor, bound
///          constructor or native.
/// @param   {Any} _func : The callee
/// @returns {Real}
#endregion
function __GMLCcallKind(_func) {
	if (is_gmlc_constructor(_func)) return GMLC_CALL_KIND.CONSTRUCTOR;
	if (is_gmlc_method(_func)) return is_gmlc_constructor(method_get_self(_func).func) ? GMLC_CALL_KIND.BOUND_CONSTRUCTOR : GMLC_CALL_KIND.GMLC;
	if (is_gmlc_program(_func)) {
		var _node = method_get_self(_func);
		return (_node[$ "__@@is_gmlc_function@@__"] == true) ? GMLC_CALL_KIND.FUNCTION : GMLC_CALL_KIND.GMLC;
	}
	return GMLC_CALL_KIND.NATIVE;
}
#endregion

#region Literals
#region //{
// used to make the array of an array literal
//    elements: array<expression>,
//    size: <real>,
//}
#endregion
function __GMLCexecuteArrayLiteral() {
	// GameMaker evaluates the elements right to left
	var _array = array_create(size);
	var _i = size - 1; repeat (size) {
		_array[_i] = elements[_i]();
	_i--}
	return _array;
}
#region jsDoc
/// @func    __GMLCcompileArrayLiteral(_rootNode, _parentNode, _node)
/// @desc    Compiles an array literal.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : An ArrayLiteral node
/// @returns {Function}
#endregion
function __GMLCcompileArrayLiteral(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileArrayLiteral", "<Missing Error Message>", _node.span);
	_output.size = array_length(_node.elements);
	_output.elements = array_create(_output.size);
	var _i = 0; repeat (_output.size) {
		_output.elements[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _node.elements[_i]);
	_i++}
	return __vanilla_method(_output, __GMLCexecuteArrayLiteral);
}

#region //{
// used to make the struct of a struct literal
//    keys: array<string>,
//    values: array<expression>,
//    bound: array<string>, the keys whose value is a function literal, bound to the new struct
//    self_keys: array<string>, the keys whose whole value is `self`, which GameMaker sets to the new struct
//    size: <real>,
//}
#endregion
function __GMLCexecuteStructLiteral() {
	// GameMaker evaluates the values right to left; the keys are distinct, so each value goes straight in
	var _struct = {};
	var _i = size - 1; repeat (size) {
		_struct[$ keys[_i]] = values[_i]();
	_i--}
	var _j = 0; repeat (array_length(bound)) {
		var _key = bound[_j];
		_struct[$ _key] = __gmlc_method(_struct, _struct[$ _key]);
	_j++}
	var _k = 0; repeat (array_length(self_keys)) {
		_struct[$ self_keys[_k]] = _struct;
	_k++}
	
	// the environment's own static struct, in place of GameMaker's shared one that would reach outside the sandbox
	static_set(_struct, literal_statics);
	
	return _struct;
}
#region jsDoc
/// @func    __GMLCexecuteStructLiteralRepeatedKeys()
/// @desc    Builds the struct of a literal that writes a key twice: values right to left, the last of a key kept.
/// @returns {Struct}
#endregion
function __GMLCexecuteStructLiteralRepeatedKeys() {
	// GameMaker evaluates the values right to left; a key written twice keeps its last value
	var _values = array_create(size);
	var _i = size - 1; repeat (size) {
		_values[_i] = values[_i]();
	_i--}
	var _struct = {};
	var _i = 0; repeat (size) {
		_struct[$ keys[_i]] = _values[_i];
	_i++}
	var _j = 0; repeat (array_length(bound)) {
		var _key = bound[_j];
		_struct[$ _key] = __gmlc_method(_struct, _struct[$ _key]);
	_j++}
	var _k = 0; repeat (array_length(self_keys)) {
		_struct[$ self_keys[_k]] = _struct;
	_k++}
	
	static_set(_struct, literal_statics);
	
	return _struct;
}
#region jsDoc
/// @func    __GMLCcompileStructLiteral(_rootNode, _parentNode, _node)
/// @desc    Compiles a struct literal; function literals among its values are bound to the new struct.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A StructLiteral node
/// @returns {Function}
#endregion
function __GMLCcompileStructLiteral(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileStructLiteral", "<Missing Error Message>", _node.span);
	_output.size = array_length(_node.entries);
	_output.keys = array_create(_output.size);
	_output.values = array_create(_output.size);
	_output.bound = [];
	_output.self_keys = [];
	_output.literal_statics = _rootNode.env.__struct_literal_statics;
	var _seen = {};
	var _repeated = false;
	// function expressions in the values are bound to `self`; a function literal that is a value itself is bound to
	// the new struct, as GameMaker does
	array_push(_rootNode.scope_stack, "Self");
	var _i = 0; repeat (_output.size) {
		var _entry = _node.entries[_i];
		_output.keys[_i] = _entry.key;
		if (__gmlc_struct_has(_seen, _entry.key)) {
			_repeated = true;
			// a later value of the key replaces an earlier `self`
			var _at = array_get_index(_output.self_keys, _entry.key);
			if (_at >= 0) array_delete(_output.self_keys, _at, 1);
		}
		_seen[$ _entry.key] = true;
		if (_entry.value.kind == __GMLC_NodeKind_FunctionExpr) {
			_output.values[_i] = __vanilla_method({ value: __GMLCcompileFunctionValue(_rootNode, _entry.value) }, __GMLCexecuteLiteralExpression);
			array_push(_output.bound, _entry.key);
		}
		else if (_entry.value.kind == __GMLC_NodeKind_Identifier) && (_entry.value.name == "self") {
			// `{ me: self }` stores the new struct in GameMaker, though `self` anywhere else in the value (`self.x`,
			// `[self]`, `f(self)`) is the creator
			_output.values[_i] = __vanilla_method({ value: undefined }, __GMLCexecuteLiteralExpression);
			array_push(_output.self_keys, _entry.key);
		}
		else {
			_output.values[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _entry.value);
		}
	_i++}
	array_pop(_rootNode.scope_stack);
	return __vanilla_method(_output, _repeated ? __GMLCexecuteStructLiteralRepeatedKeys : __GMLCexecuteStructLiteral);
}

#region //{
// used to make the string of a template string
//    strings: array<string>, the text parts
//    exprs: array<expression>, the expressions between them
//    count: <real>, the number of expressions
//}
#endregion
function __GMLCexecuteTemplateString() {
	// the expressions are evaluated right to left, as the arguments of a call, so the string is built from its end
	var _out = strings[count];
	var _i = count - 1; repeat (count) {
		_out = strings[_i] + string(exprs[_i]()) + _out;
	_i--}
	return _out;
}
#region jsDoc
/// @func    __GMLCcompileTemplateString(_rootNode, _parentNode, _node)
/// @desc    Compiles a template string.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A TemplateString node
/// @returns {Function}
#endregion
function __GMLCcompileTemplateString(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileTemplateString", "<Missing Error Message>", _node.span);
	_output.strings = _node.strings;
	_output.count = array_length(_node.exprs);
	_output.exprs = array_create(_output.count);
	var _i = 0; repeat (_output.count) {
		_output.exprs[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _node.exprs[_i]);
	_i++}
	return __vanilla_method(_output, __GMLCexecuteTemplateString);
}
#endregion

#endregion

#region Math Expressions

enum GMLC_COMPOUND_OP {
	PLUS,
	MINUS,
	MULTIPLY,
	DIVIDE,
	MODULO,
	BITWISE_XOR,
	BITWISE_AND,
	BITWISE_OR,
	NULLISH,
}

#region jsDoc
/// @func    __GMLCcompileAssignmentExpression(_rootNode, _parentNode, _node)
/// @desc    Compiles `=` and the compound assignments (`+=`, `??=`, ...) to a name or an accessor.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : An Assign node
/// @returns {Function}
#endregion
function __GMLCcompileAssignmentExpression(_rootNode, _parentNode, _node) {
	var _target = __GMLCdesugarIndex(_node.target);
	if (_node.op == "=") {
		if (_target.kind == __GMLC_NodeKind_Index) {
			var _keys = _target.keys;
			switch (_target.accessor) {
				case "Array":  return __GMLCcompileArraySet       (_rootNode, _parentNode, _target.object, _keys[0],           _node.value, _node.span);
				case "Grid":   return __GMLCcompileGridSet		  (_rootNode, _parentNode, _target.object, _keys[0], _keys[1], _node.value, _node.span);
				case "List":   return __GMLCcompileListSet		  (_rootNode, _parentNode, _target.object, _keys[0],           _node.value, _node.span);
				case "Map":    return __GMLCcompileMapSet		  (_rootNode, _parentNode, _target.object, _keys[0],           _node.value, _node.span);
				case "Struct": return __GMLCcompileStructSet      (_rootNode, _parentNode, _target.object, _keys[0],           _node.value, _node.span);
				case "Dot":    return __GMLCcompileStructDotAccSet(_rootNode, _parentNode, _target.object, _target.member,     _node.value, _node.span);
			}
		}
		else if (_target.kind == __GMLC_NodeKind_Identifier) {
			// the resolver refused writes to constants, functions and enums
			return __GMLCcompilePropertySet(_rootNode, _parentNode, _target.symbol.kind, __GMLCscopeKey(_rootNode, _target), _node.value, _node.span);
		}
		__gmlc_internal_error($"the compiler cannot assign to a node of kind {_target.kind}", _node.span)
	}
	
	//get the accurate opperator function
	var _func = undefined;
	var _op = undefined;
	switch (_node.op) {
		case "+=":  _func = __GMLCexecuteOpPlus;       _op = GMLC_COMPOUND_OP.PLUS;         break;
		case "-=":  _func = __GMLCexecuteOpMinus;      _op = GMLC_COMPOUND_OP.MINUS;        break;
		case "*=":  _func = __GMLCexecuteOpMultiply;   _op = GMLC_COMPOUND_OP.MULTIPLY;     break;
		case "/=":  _func = __GMLCexecuteOpDivide;     _op = GMLC_COMPOUND_OP.DIVIDE;       break;
		case "^=":  _func = __GMLCexecuteOpBitwiseXOR; _op = GMLC_COMPOUND_OP.BITWISE_XOR;  break;
		case "&=":  _func = __GMLCexecuteOpBitwiseAND; _op = GMLC_COMPOUND_OP.BITWISE_AND;  break;
		case "|=":  _func = __GMLCexecuteOpBitwiseOR;  _op = GMLC_COMPOUND_OP.BITWISE_OR;   break;
		case "%=":  _func = __GMLCexecuteOpMod;        _op = GMLC_COMPOUND_OP.MODULO;       break;
		case "??=": _func = __GMLCexecuteOpNullish;    _op = GMLC_COMPOUND_OP.NULLISH;      break;
	}
	
	if (_target.kind == __GMLC_NodeKind_Index) {
		var _keys = _target.keys;
		var _once = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Compound", "<Missing Error Message>", _node.span);
		_once.target = __GMLCcompileExpression(_rootNode, _parentNode, _target.object);
		_once.right  = __GMLCcompileExpression(_rootNode, _parentNode, _node.value);
		_once.op     = _op;
		switch (_target.accessor) {
			case "Dot":
				_once.key = _target.member;
				return __vanilla_method(_once, __GMLCexecuteCompoundDot);
			case "Grid":
				_once.key_x = __GMLCcompileExpression(_rootNode, _parentNode, _keys[0]);
				_once.key_y = __GMLCcompileExpression(_rootNode, _parentNode, _keys[1]);
				return __vanilla_method(_once, __GMLCexecuteCompoundGrid);
		}
		_once.key = __GMLCcompileExpression(_rootNode, _parentNode, _keys[0]);
		switch (_target.accessor) {
			case "List":   return __vanilla_method(_once, __GMLCexecuteCompoundList);
			case "Map":    return __vanilla_method(_once, __GMLCexecuteCompoundMap);
			case "Struct": return __vanilla_method(_once, __GMLCexecuteCompoundStruct);
		}
		return __vanilla_method(_once, __GMLCexecuteCompoundArray);
	}
	
	if (_target.kind == __GMLC_NodeKind_Identifier) {
		var _scope = _target.symbol.kind;
		var _key = __GMLCscopeKey(_rootNode, _target);
		
		//compile the additive method
		var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Operator", "<Missing Error Message>", _node.span);
		_output.left  = __vanilla_method(__GMLCscopeNode(_rootNode, _parentNode, _scope, _key, _node.span), __GMLCGetScopeGetter(_scope));
		_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.value);
		
		//compile the actual method we will be calling
		var _setter = __GMLCscopeNode(_rootNode, _parentNode, _scope, _key, _node.span);
		_setter.expression = __vanilla_method(_output, _func);
		return __vanilla_method(_setter, __GMLCGetScopeSetter(_scope));
	}
	
	__gmlc_internal_error($"the compiler cannot assign to a node of kind {_target.kind}", _node.span)
}
#region jsDoc
/// @func    __GMLCdesugarIndex(_node)
/// @desc    The accessor forms the runtime compiles as others: `[@ i]` is `[i]`, and `a[i, j]` (also with `[@`) is
///          `a[i][j]`. Any other node is returned as it is.
/// @param   {Struct} _node : An AST node
/// @returns {Struct}
#endregion
function __GMLCdesugarIndex(_node) {
	if (_node.kind != __GMLC_NodeKind_Index) return _node;
	switch (_node.accessor) {
		case "ArrayAt": {
			return new ASTIndex(_node.span, "Array", _node.object, _node.keys, undefined);
		}
		case "Array2D":
		case "Array2DAt": {
			var _row = new ASTIndex(_node.span, "Array", _node.object, [_node.keys[0]], undefined);
			return new ASTIndex(_node.span, "Array", _row, [_node.keys[1]], undefined);
		}
	}
	return _node;
}

#region jsDoc
/// @func    __GMLCcompileBinaryExpression(_rootNode, _parentNode, _node)
/// @desc    Compiles a binary operator; a constant right operand of a comparison, + or - is read without a call.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Binary node
/// @returns {Function}
#endregion
function __GMLCcompileBinaryExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileBinaryExpression", "<Missing Error Message>", _node.span);
	_output.left  = __GMLCcompileExpression(_rootNode, _parentNode, _node.left);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);

	if (_node.right.kind == __GMLC_NodeKind_Literal) {
		_output.value = _node.right.value;
		switch (_node.op) {
			case "==":  return __vanilla_method(_output, __GMLCexecuteOpEqualsEqualsConst);
			case "!=":  return __vanilla_method(_output, __GMLCexecuteOpNotEqualsConst);
			case "<":   return __vanilla_method(_output, __GMLCexecuteOpLessConst);
			case "<=":  return __vanilla_method(_output, __GMLCexecuteOpLessEqualsConst);
			case ">":   return __vanilla_method(_output, __GMLCexecuteOpGreaterConst);
			case ">=":  return __vanilla_method(_output, __GMLCexecuteOpGreaterEqualsConst);
			case "+":   return __vanilla_method(_output, __GMLCexecuteOpPlusConst);
			case "-":   return __vanilla_method(_output, __GMLCexecuteOpMinusConst);
		}
	}

    switch (_node.op) {
		case "==":  return __vanilla_method(_output, __GMLCexecuteOpEqualsEquals     );
		case "!=":  return __vanilla_method(_output, __GMLCexecuteOpNotEquals        );
		case "<":   return __vanilla_method(_output, __GMLCexecuteOpLess             );
		case "<=":  return __vanilla_method(_output, __GMLCexecuteOpLessEquals       );
		case ">":   return __vanilla_method(_output, __GMLCexecuteOpGreater          );
		case ">=":  return __vanilla_method(_output, __GMLCexecuteOpGreaterEquals    );
		case "+":   return __vanilla_method(_output, __GMLCexecuteOpPlus             );
		case "-":   return __vanilla_method(_output, __GMLCexecuteOpMinus            );
		case "*":   return __vanilla_method(_output, (_parentNode[$ "debug"] == true) ? __GMLCexecuteOpMultiplyDebug : __GMLCexecuteOpMultiply);
		case "/":   return __vanilla_method(_output, __GMLCexecuteOpDivide           );
		case "mod": return __vanilla_method(_output, (_parentNode[$ "debug"] == true) ? __GMLCexecuteOpModDebug : __GMLCexecuteOpMod);
		case "div": return __vanilla_method(_output, __GMLCexecuteOpDiv              );
		case "|":   return __vanilla_method(_output, __GMLCexecuteOpBitwiseOR        );
		case "^":   return __vanilla_method(_output, __GMLCexecuteOpBitwiseXOR       );
		case "&":   return __vanilla_method(_output, __GMLCexecuteOpBitwiseAND       );
		case "<<":  return __vanilla_method(_output, __GMLCexecuteOpBitwiseShiftLeft );
		case ">>":  return __vanilla_method(_output, __GMLCexecuteOpBitwiseShiftRight);
	}
}
#region Binary Expressions
#region jsDoc
/// @func    __GMLCexecuteOpEqualsEqualsConst()
/// @desc    Returns `left() == value`, value being the constant right operand.
/// @returns {Any}
#endregion
function __GMLCexecuteOpEqualsEqualsConst() {
	return left() == value;
}
#region jsDoc
/// @func    __GMLCexecuteOpNotEqualsConst()
/// @desc    Returns `left() != value`, value being the constant right operand.
/// @returns {Any}
#endregion
function __GMLCexecuteOpNotEqualsConst() {
	return left() != value;
}
#region jsDoc
/// @func    __GMLCexecuteOpLessConst()
/// @desc    Returns `left() < value`, value being the constant right operand.
/// @returns {Any}
#endregion
function __GMLCexecuteOpLessConst() {
	return left() < value;
}
#region jsDoc
/// @func    __GMLCexecuteOpLessEqualsConst()
/// @desc    Returns `left() <= value`, value being the constant right operand.
/// @returns {Any}
#endregion
function __GMLCexecuteOpLessEqualsConst() {
	return left() <= value;
}
#region jsDoc
/// @func    __GMLCexecuteOpGreaterConst()
/// @desc    Returns `left() > value`, value being the constant right operand.
/// @returns {Any}
#endregion
function __GMLCexecuteOpGreaterConst() {
	return left() > value;
}
#region jsDoc
/// @func    __GMLCexecuteOpGreaterEqualsConst()
/// @desc    Returns `left() >= value`, value being the constant right operand.
/// @returns {Any}
#endregion
function __GMLCexecuteOpGreaterEqualsConst() {
	return left() >= value;
}
#region jsDoc
/// @func    __GMLCexecuteOpPlusConst()
/// @desc    Returns `left() + value`, value being the constant right operand.
/// @returns {Any}
#endregion
function __GMLCexecuteOpPlusConst() {
	return left() + value;
}
#region jsDoc
/// @func    __GMLCexecuteOpMinusConst()
/// @desc    Returns `left() - value`, value being the constant right operand.
/// @returns {Any}
#endregion
function __GMLCexecuteOpMinusConst() {
	return left() - value;
}
#region Equality Ops
#region jsDoc
/// @func    __GMLCexecuteOpEqualsEquals()
/// @desc    Returns `left() == right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpEqualsEquals() {
    return left() == right();
}
#region jsDoc
/// @func    __GMLCexecuteOpNotEquals()
/// @desc    Returns `left() != right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpNotEquals() {
    return left() != right();
}
#region jsDoc
/// @func    __GMLCexecuteOpLess()
/// @desc    Returns `left() < right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpLess() {
    return left() < right();
}
#region jsDoc
/// @func    __GMLCexecuteOpLessEquals()
/// @desc    Returns `left() <= right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpLessEquals() {
    return left() <= right();
}
#region jsDoc
/// @func    __GMLCexecuteOpGreater()
/// @desc    Returns `left() > right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpGreater() {
    return left() > right();
}
#region jsDoc
/// @func    __GMLCexecuteOpGreaterEquals()
/// @desc    Returns `left() >= right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpGreaterEquals() {
    return left() >= right();
}
#endregion
#region Basic Ops
#region jsDoc
/// @func    __GMLCexecuteOpPlus()
/// @desc    Returns `left() + right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpPlus() {
	return left() + right();
}
#region jsDoc
/// @func    __GMLCexecuteOpMinus()
/// @desc    Returns `left() - right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpMinus() {
    return left() - right();
}
#region jsDoc
/// @func    __GMLCexecuteOpMultiply()
/// @desc    Returns `left() * right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpMultiply() {
	return left() * right();
}
#region jsDoc
/// @func    __GMLCexecuteOpDivide()
/// @desc    Returns `left() / right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpDivide() {
    return left() / right();
}
#region jsDoc
/// @func    __GMLCexecuteOpDiv()
/// @desc    Returns `left() div right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpDiv() {
    return left() div right();
}
#region jsDoc
/// @func    __GMLCexecuteOpMod()
/// @desc    Returns `left() mod right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpMod() {
    return left() mod right();
}
// the debug executors of `*` and `mod` throw where GameMaker's runner ends: a string repeated a negative number of
// times, an int64 zero divisor
#region jsDoc
/// @func    __GMLCexecuteOpMultiplyDebug()
/// @desc    Returns `left() * right()`; throws for a string repeated a negative number of times.
/// @returns {Any}
#endregion
function __GMLCexecuteOpMultiplyDebug() {
	var _a = left();
	var _b = right();
	if (is_string(_a) && is_numeric(_b) && _b < 0) || (is_string(_b) && is_numeric(_a) && _a < 0) {
		throw_gmlc_error("DoMul :: a string repeated a negative number of times");
	}
	return _a * _b;
}
#region jsDoc
/// @func    __GMLCexecuteOpModDebug()
/// @desc    Returns `left() mod right()`; throws for an int64 zero divisor.
/// @returns {Any}
#endregion
function __GMLCexecuteOpModDebug() {
	var _a = left();
	var _b = right();
	if (is_int64(_b) && _b == 0) throw_gmlc_error("DoMod :: Divide by zero");
	return _a mod _b;
}
#endregion
#region Bitwise Ops
#region jsDoc
/// @func    __GMLCexecuteOpBitwiseOR()
/// @desc    Returns `left() | right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpBitwiseOR() {
    return left() | right();
}
#region jsDoc
/// @func    __GMLCexecuteOpBitwiseAND()
/// @desc    Returns `left() & right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpBitwiseAND() {
    return left() & right();
}
#region jsDoc
/// @func    __GMLCexecuteOpBitwiseXOR()
/// @desc    Returns `left() ^ right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpBitwiseXOR() {
    return left() ^ right();
}
#region jsDoc
/// @func    __GMLCexecuteOpBitwiseShiftLeft()
/// @desc    Returns `left() << right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpBitwiseShiftLeft() {
    return left() << right();
}
#region jsDoc
/// @func    __GMLCexecuteOpBitwiseShiftRight()
/// @desc    Returns `left() >> right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpBitwiseShiftRight() {
    return left() >> right();
}
#endregion
#endregion

#region Constant folding
// an operator on constant operands is computed with GameMaker's own operators, so a fold gives the runtime's value
// even where GameMaker's compiler folds differently (`!0`, `~1.5`, `167 != NaN`); operands that throw or end the
// game are compile errors

// a folded string becomes a literal in the output, so a fold that would make a longer string is left to run
#macro __GMLC_FOLD_STRING_LIMIT 4096
#macro __GMLC_INT64_MIN 0x8000000000000000

// the optimizer folds inside one try: when a computation throws, the node being computed is recorded here, the walk
// starts again, and from then on that node reads as failing without being computed again
global.__gmlc_fold = { node: undefined, failed: [], messages: [], epsilon: false };

#region jsDoc
/// @func    __GMLCfoldFailure(_node)
/// @desc    The message of a node whose constant folding failed before, or undefined.
/// @param   {Struct} _node : An operator node
/// @returns {String|Undefined}
#endregion
function __GMLCfoldFailure(_node) {
	var _fold = global.__gmlc_fold;
	var _i = 0; repeat (array_length(_fold.failed)) {
		if (_fold.failed[_i] == _node) return _fold.messages[_i];
	_i++}
	return undefined;
}

#region jsDoc
/// @func    __GMLCconstantValue(_rootNode, _node)
/// @desc    Evaluates an expression whose operands are all constants, as the runtime would; `&&` and `||` stop at a
///          deciding left operand. Called inside the optimizer's try: an operator that throws records itself in
///          global.__gmlc_fold first.
/// @returns {Array} [true, value]; [false] when not constant; [false, undefined, message, node, fatal] when it fails
#endregion
function __GMLCconstantValue(_rootNode, _node) {
	var _v;
	switch (_node.kind) {
		case __GMLC_NodeKind_Identifier: {
			if (_node.symbol == undefined) || (_node.symbol.kind != "BuiltinConstant") return [false];
			_v = __GMLCidentifierValue(_rootNode, _node);
		break;}
		case __GMLC_NodeKind_Index: {
			if (_node.accessor != "Dot") || (_node.object.kind != __GMLC_NodeKind_Identifier) || (_node.object.symbol == undefined) || (_node.object.symbol.kind != "Enum") return [false];
			_v = __GMLCenumValue(_rootNode, _node);
		break;}
		case __GMLC_NodeKind_Literal: {
			// a literal is a constant whatever its length
			return [true, _node.value];
		}
		case __GMLC_NodeKind_Unary: {
			var _e = __GMLCconstantValue(_rootNode, _node[$ "argument"]);
			if (!_e[0]) return _e;
			// `-true` is a bool that holds -1 at run time (it writes "false", prints "1" and is -1 in arithmetic): no
			// literal holds it, so it stays an expression
			if (_node.op == "-") && (is_bool(_e[1])) return [false];
			// the project's Game Options decide how a string converts to an int64
			if (__GMLCconvertsStringToInt64(_node.op, _e[1], undefined)) return [false];
			var _failed = __GMLCfoldFailure(_node);
			if (_failed != undefined) return [false, undefined, _failed, _node, false];
			var _fold = global.__gmlc_fold;
			_fold.node = _node;
			_v = __GMLCunaryValue(_node.op, _e[1]);
			_fold.node = undefined;
			if (is_undefined(_v)) return [false];
		break;}
		case __GMLC_NodeKind_Logical:
		case __GMLC_NodeKind_Binary: {
			var _l = __GMLCconstantValue(_rootNode, _node.left);
			if (!_l[0]) return _l;
			var _a = _l[1];
			var _failed = __GMLCfoldFailure(_node);
			if (_failed != undefined) return [false, undefined, _failed, _node, false];
			var _fold = global.__gmlc_fold;
			// the right operand is not evaluated when the left decides (the left's truth may throw, so the node is recorded)
			_fold.node = _node;
			var _decided = ((_node.op == "&&") && (!_a)) || ((_node.op == "||") && (_a));
			_fold.node = undefined;
			if (_decided) return [true, (_node.op == "||")];
			var _r = __GMLCconstantValue(_rootNode, _node.right);
			if (!_r[0]) return _r;
			var _b = _r[1];
			// a whole-number constant next to an int64 is an integer at run time
			var _whole_a = __GMLCintegerConstant(_node.op, _a, _b, false);
			_b = __GMLCintegerConstant(_node.op, _b, _a, true);
			_a = _whole_a;
			if (__GMLCconvertsStringToInt64(_node.op, _a, _b)) return [false];
			// math_set_epsilon is called somewhere in the compile: a comparison with a real operand depends on it (two
			// int64 values compare exactly)
			if (_fold.epsilon) && (is_real(_a) || is_real(_b)) {
				switch (_node.op) {
					case "==": case "!=": case "<": case "<=": case ">": case ">=": return [false];
				}
			}
			var _unsafe = __GMLCconstantFoldUnsafe(_node.op, _a, _b);
			if (_unsafe != undefined) return [false, undefined, _unsafe, _node, true];
			if (_node.op == "*") && (is_string(_b)) && (is_numeric(_a)) && (_a * string_byte_length(_b) > __GMLC_FOLD_STRING_LIMIT) return [false];
			_fold.node = _node;
			_v = __GMLCbinaryValue(_node.op, _a, _b);
			_fold.node = undefined;
			if (is_undefined(_v)) return [false];
		break;}
		default: return [false];
	}
	if (is_bool(_v) || is_real(_v) || is_int64(_v) || is_int32(_v) || is_undefined(_v)) return [true, _v];
	if (is_string(_v)) && (string_byte_length(_v) <= __GMLC_FOLD_STRING_LIMIT) return [true, _v];
	return [false];
}

#region jsDoc
/// @func    __GMLCbinaryValue(_op, _a, _b)
/// @desc    `_a _op _b` computed by GameMaker's own operator; it throws what the operator throws. Operations that end
///          the runner are refused before it is called.
/// @param   {String} _op : The operator (undefined is returned for one constant folding does not compute)
/// @param   {Any} _a : The left operand
/// @param   {Any} _b : The right operand
/// @returns {Any}
#endregion
function __GMLCbinaryValue(_op, _a, _b) {
	switch (_op) {
		case "&&":  return _a && _b;
		case "||":  return _a || _b;
		case "^^":  return _a ^^ _b;
		case "==":  return _a == _b;
		case "!=":  return _a != _b;
		case "<":   return _a < _b;
		case "<=":  return _a <= _b;
		case ">":   return _a > _b;
		case ">=":  return _a >= _b;
		case "+":   return _a + _b;
		case "-":   return _a - _b;
		case "*":   return _a * _b;
		case "/":   return _a / _b;
		case "div": return _a div _b;
		case "mod": return _a mod _b;
		case "%":   return _a % _b;
		case "&":   return _a & _b;
		case "|":   return _a | _b;
		case "^":   return _a ^ _b;
		case "<<":  return _a << _b;
		case ">>":  return _a >> _b;
	}
	return undefined;
}

#region jsDoc
/// @func    __GMLCunaryValue(_op, _a)
/// @desc    `_op _a` for `!`, `-` and `~` computed by GameMaker's own operator.
/// @param   {String} _op : The operator
/// @param   {Any} _a : The operand
/// @returns {Any}
#endregion
function __GMLCunaryValue(_op, _a) {
	switch (_op) {
		case "!": return !_a;
		case "-": return -_a;
		case "~": return ~_a;
	}
	return undefined;
}

#region jsDoc
/// @func    __GMLCintegerConstant(_op, _v, _other, _right)
/// @desc    The constant operand _v as GameMaker's runtime takes it next to _other: a whole-number constant or a bool
///          next to an int64 is an int64 there, so +, -, *, div, mod, % and the comparisons compute in int64
///          (`int64 min < 1` is false); `/`, the logical operators and a zero divisor take it as it is (an int64
///          zero divisor would end the runner). A variable holding the same number is a real.
/// @param   {String} _op : The operator
/// @param   {Any} _v : The operand
/// @param   {Any} _other : The other operand
/// @param   {Bool} _right : Whether _v is the right operand
/// @returns {Any}
#endregion
function __GMLCintegerConstant(_op, _v, _other, _right) {
	if (!is_int64(_other)) return _v;
	switch (_op) {
		case "+": case "-": case "*": case "div": case "mod": case "%":
		case "==": case "!=": case "<": case "<=": case ">": case ">=": break;
		default: return _v;
	}
	if (_right) && ((_op == "div") || (_op == "mod") || (_op == "%")) && (is_numeric(_v)) && (_v == 0) return _v;
	if (is_bool(_v)) return int64(_v);
	if (is_real(_v)) && (__gmlc_is_whole(_v)) && (abs(_v) < 0x7FFFFFFFFFFFFFFF) return int64(_v);
	return _v;
}

#region jsDoc
/// @func    __GMLCconvertsStringToInt64(_op, _a, _b)
/// @desc    Whether `_a _op _b` (or `_op _a`) converts a string operand to an int64: the bitwise operators do, and the
///          "Legacy Number Conversion" Game Option decides how ("0.5" is 0 with it and an error without), so such an
///          operation is never folded.
/// @param   {String} _op : The operator
/// @param   {Any} _a : The left (or only) operand
/// @param   {Any} _b : The right operand, or undefined
/// @returns {Bool}
#endregion
function __GMLCconvertsStringToInt64(_op, _a, _b) {
	switch (_op) {
		case "&": case "|": case "^": case "<<": case ">>": case "~":
			return is_string(_a) || is_string(_b);
	}
	return false;
}

#region jsDoc
/// @func    __GMLCconstantFoldUnsafe(_op, _a, _b)
/// @desc    Why computing _a _op _b while compiling is unsafe, or undefined when it is safe: an operation that ends
///          GameMaker's runner outright (not a catchable error) is never run, and is an error while compiling.
#endregion
function __GMLCconstantFoldUnsafe(_op, _a, _b) {
	// only a count that cuts to an int32 from -1 down to above -2^31 ends the runner: -0.5 cuts to 0 (""), and NaN,
	// the infinities and -2^31 fail with a catchable error
	if (_op == "*") && is_string(_b) && is_numeric(_a) && (_a < 0) && (int64(_a) != 0) && (_a > -2147483648) {
		return "a string repeated a negative number of times";
	}
	// an int64 remainder by an int64 zero, and the smallest int64 divided by -1 in int64, end the runner
	if ((_op == "mod") || (_op == "%")) && is_int64(_b) && (_b == 0) return "an int64 remainder by zero";
	// the left operand is the smallest int64 once cut to an int64 as those operators cut it: an int64 that is the
	// smallest, or a real that is NaN, an infinity or out of the int64 range (unlike int64(), which makes NaN 0 and
	// infinity the largest int64)
	if ((_op == "div") || (_op == "mod") || (_op == "%") || (_op == "/")) && is_int64(_b) && (_b == -1)
	&& ((is_int64(_a) && (_a == __GMLC_INT64_MIN))
	|| (is_real(_a) && (is_nan(_a) || is_infinity(_a) || (_a < -9223372036854775807) || (_a > 9223372036854775807) || (int64(_a) == __GMLC_INT64_MIN)))) {
		return "the smallest int64 divided by -1";
	}
	if (_op == "div") && is_int64(_a) && (_a == __GMLC_INT64_MIN) && is_real(_b) && (_b == -1) {
		return "the smallest int64 divided by -1";
	}
	return undefined;
}
#endregion

#region jsDoc
/// @func    __GMLCcompileLogicalExpression(_rootNode, _parentNode, _node)
/// @desc    Compiles `&&`, `||` or `^^`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Logical node
/// @returns {Function}
#endregion
function __GMLCcompileLogicalExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileLogicalExpression", "<Missing Error Message>", _node.span);
	_output.left  = __GMLCcompileExpression(_rootNode, _parentNode, _node.left);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
    
	switch (_node.op) {
		case "&&": return __vanilla_method(_output, __GMLCexecuteOpAND);
		case "||": return __vanilla_method(_output, __GMLCexecuteOpOR );
		case "^^": return __vanilla_method(_output, __GMLCexecuteOpXOR);
	}
}
#region Logical Expressions
#region jsDoc
/// @func    __GMLCexecuteOpAND()
/// @desc    Returns `left() && right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpAND() {
    return left() && right();
}
#region jsDoc
/// @func    __GMLCexecuteOpOR()
/// @desc    Returns `left() || right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpOR() {
    return left() || right();
}
#region jsDoc
/// @func    __GMLCexecuteOpXOR()
/// @desc    Returns `left() ^^ right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpXOR() {
    return left() ^^ right();
}
#endregion

#region jsDoc
/// @func    __GMLCcompileNullishExpression(_rootNode, _parentNode, _node)
/// @desc    Compiles `??`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Nullish node
/// @returns {Function}
#endregion
function __GMLCcompileNullishExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileNullishExpression", "<Missing Error Message>", _node.span);
	_output.left  = __GMLCcompileExpression(_rootNode, _parentNode, _node.left);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
    
    
    return __vanilla_method(_output, __GMLCexecuteOpNullish);
}
#region Nullish Expressions
#region jsDoc
/// @func    __GMLCexecuteOpNullish()
/// @desc    Returns `left() ?? right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpNullish() {
    return left() ?? right();
}
#endregion

#region jsDoc
/// @func    __GMLCcompileUnaryExpression(_rootNode, _parentNode, _node)
/// @desc    Compiles `!`, `-`, `~` or `+` (which is its operand).
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Unary node
/// @returns {Function}
#endregion
function __GMLCcompileUnaryExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUnaryExpression", "<Missing Error Message>", _node.span);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node[$ "argument"]);
	
	switch (_node.op) {
		case "!": return __vanilla_method(_output, __GMLCexecuteOpNot          )
		case "-": return __vanilla_method(_output, __GMLCexecuteOpNegate       )
		case "~": return __vanilla_method(_output, __GMLCexecuteOpBitwiseNegate)
		case "+": return _output.right;
	}
}
#region Unary Expressions
#region jsDoc
/// @func    __GMLCexecuteOpNot()
/// @desc    Returns `!right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpNot() {
    return !right();
}
#region jsDoc
/// @func    __GMLCexecuteOpNegate()
/// @desc    Returns `-right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpNegate() {
    return -right();
}
#region jsDoc
/// @func    __GMLCexecuteOpBitwiseNegate()
/// @desc    Returns `~right()`.
/// @returns {Any}
#endregion
function __GMLCexecuteOpBitwiseNegate() {
    return ~right();
}
#endregion

#region //{
//    condition: <expression>,
//    trueExpression: <expression>,
//    falseExpression: <expression>,
//}
#endregion
function __GMLCexecuteTernaryExpression() {
    return condition() ? left() : right();
}
#region jsDoc
/// @func    __GMLCcompileTernaryExpression(_rootNode, _parentNode, _node)
/// @desc    Compiles `test ? a : b`.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A Conditional node
/// @returns {Function}
#endregion
function __GMLCcompileTernaryExpression(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileTernaryExpression", "<Missing Error Message>", _node.span);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.test);
	_output.left = __GMLCcompileExpression(_rootNode, _parentNode, _node.consequent);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.alternate);
    
    
    return __vanilla_method(_output, __GMLCexecuteTernaryExpression);
}

#region jsDoc
/// @func    __GMLCcompileUpdateExpression(_rootNode, _parentNode, _node)
/// @desc    Compiles `++` or `--`, prefix or postfix, on a name or an accessor.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : An Update node
/// @returns {Function}
#endregion
function __GMLCcompileUpdateExpression(_rootNode, _parentNode, _node) {
	var _argument = __GMLCdesugarIndex(_node[$ "argument"]);
	if (_argument.kind == __GMLC_NodeKind_Identifier) {
		
		var _scope = _argument.symbol.kind;
		var _increment = (_node.op == "++") ? true : false;
		var _prefix = _node.prefix;
		
		return __vanilla_method(__GMLCscopeNode(_rootNode, _parentNode, _scope, __GMLCscopeKey(_rootNode, _argument), _node.span), __GMLCGetScopeUpdater(_scope, _increment, _prefix));
	}
	else if (_argument.kind == __GMLC_NodeKind_Index) {
		
		switch (_argument.accessor) {
			case "Array":  return __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, _argument, __GMLCarrayTargetIsRooted(_argument.object) ? __GMLCexecuteUpdateArrayRooted : __GMLCexecuteUpdateArray);
			case "Grid":   return __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, _argument, __GMLCexecuteUpdateGrid);
			case "List":   return __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, _argument, __GMLCexecuteUpdateList);
			case "Map":    return __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, _argument, __GMLCexecuteUpdateMap);
			case "Struct": return __GMLCcompileUpdateAccessor(_rootNode, _parentNode, _node, _argument, __GMLCexecuteUpdateStruct);
			case "Dot":    return __GMLCcompileUpdateStructDotAcc(_rootNode, _parentNode, _node);
		}
		
	}
	
	__gmlc_internal_error("malformed assignment", _node.span)
}

#endregion

#region Identifiers

#region Targeters / Getter / Setters

//these are used when the target is an expected result, self, other, global, static, var, or a known unique variabke like `room` or `fps`
#region jsDoc
/// @func    __GMLCGetScopeGetter(_scopeType)
/// @desc    The executor that reads a name of the given kind.
/// @param   {String} _scopeType : The symbol kind of the name (Global, Local, Static, Self, BuiltinVar)
/// @returns {Function}
#endregion
function __GMLCGetScopeGetter(_scopeType) {
	switch (_scopeType) {
		case "Global":     return __GMLCexecuteGetPropertyGlobal    break;
		case "Local":      return __GMLCexecuteGetPropertyVarLocal  break;
		case "Static":     return __GMLCexecuteGetPropertyVarStatic break;
		case "Self":       return __GMLCexecuteGetPropertySelf      break;
		case "BuiltinVar": return __GMLCexecuteGetPropertyUnique    break;
		default: __gmlc_internal_error($"the compiler cannot read a {_scopeType} name");
	}
}
#region jsDoc
/// @func    __GMLCGetScopeSetter(_scopeType)
/// @desc    The executor that writes a name of the given kind.
/// @param   {String} _scopeType : The symbol kind of the name (Global, Local, Static, Self, BuiltinVar)
/// @returns {Function}
#endregion
function __GMLCGetScopeSetter(_scopeType) {
	switch (_scopeType) {
		case "Global":     return __GMLCexecuteSetPropertyGlobal    break;
		case "Local":      return __GMLCexecuteSetPropertyVarLocal  break;
		case "Static":     return __GMLCexecuteSetPropertyVarStatic break;
		case "Self":       return __GMLCexecuteSetPropertySelf      break;
		case "BuiltinVar": return __GMLCexecuteSetPropertyUnique    break;
		default: __gmlc_internal_error($"the compiler cannot write a {_scopeType} name");
	}
}
#region jsDoc
/// @func    __GMLCGetScopeUpdater(_scopeType, _increment, _prefix)
/// @desc    The executor of `++` or `--` on a name of the given kind.
/// @param   {String} _scopeType : The symbol kind of the name (Global, Local, Static, Self, BuiltinVar)
/// @param   {Bool}   _increment : true for ++, false for --
/// @param   {Bool}   _prefix    : Whether it is written before the name
/// @returns {Function}
#endregion
function __GMLCGetScopeUpdater(_scopeType, _increment, _prefix) {
	switch (_scopeType){
		case "Self":{
			if (_increment  &&  _prefix) return __GMLCexecuteUpdatePropertySelfPlusPlusPrefix;
			if (_increment  && !_prefix) return __GMLCexecuteUpdatePropertySelfPlusPlusPostfix;
			if (!_increment &&  _prefix) return __GMLCexecuteUpdatePropertySelfMinusMinusPrefix;
			if (!_increment && !_prefix) return __GMLCexecuteUpdatePropertySelfMinusMinusPostfix;
		break;}
		case "Global":{
			if (_increment  &&  _prefix) return __GMLCexecuteUpdatePropertyGlobalPlusPlusPrefix;
			if (_increment  && !_prefix) return __GMLCexecuteUpdatePropertyGlobalPlusPlusPostfix;
			if (!_increment &&  _prefix) return __GMLCexecuteUpdatePropertyGlobalMinusMinusPrefix;
			if (!_increment && !_prefix) return __GMLCexecuteUpdatePropertyGlobalMinusMinusPostfix;
		break;}
		case "Local":{
			if (_increment  &&  _prefix) return __GMLCexecuteUpdatePropertyLocalPlusPlusPrefix;
			if (_increment  && !_prefix) return __GMLCexecuteUpdatePropertyLocalPlusPlusPostfix;
			if (!_increment &&  _prefix) return __GMLCexecuteUpdatePropertyLocalMinusMinusPrefix;
			if (!_increment && !_prefix) return __GMLCexecuteUpdatePropertyLocalMinusMinusPostfix;
		break;}
		case "Static":{
			if (_increment  &&  _prefix) return __GMLCexecuteUpdatePropertyStaticPlusPlusPrefix;
			if (_increment  && !_prefix) return __GMLCexecuteUpdatePropertyStaticPlusPlusPostfix;
			if (!_increment &&  _prefix) return __GMLCexecuteUpdatePropertyStaticMinusMinusPrefix;
			if (!_increment && !_prefix) return __GMLCexecuteUpdatePropertyStaticMinusMinusPostfix;
		break;}
		case "BuiltinVar":{
			if (_increment  &&  _prefix) return __GMLCexecuteUpdatePropertyUniquePlusPlusPrefix;
			if (_increment  && !_prefix) return __GMLCexecuteUpdatePropertyUniquePlusPlusPostfix;
			if (!_increment &&  _prefix) return __GMLCexecuteUpdatePropertyUniqueMinusMinusPrefix;
			if (!_increment && !_prefix) return __GMLCexecuteUpdatePropertyUniqueMinusMinusPostfix;
		break;}
	}
}

#region jsDoc
/// @func    __GMLCscopeNode(_rootNode, _parentNode, _scope, _key, _span)
/// @desc    The node of a scope getter, setter or updater of a name: its `key`, and the locals or globals it reads
///          and writes.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {String} _scope      : The symbol kind of the name
/// @param   {Any}    _key        : The name, or the get and set functions of a variable the environment exposes
/// @param   {Struct} _span       : Where the name is
/// @returns {Struct}
#endregion
function __GMLCscopeNode(_rootNode, _parentNode, _scope, _key, _span) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCscopeNode", "<Missing Error Message>", _span);
	_output.key = _key;
	if (_scope == "Local") {
		_output.locals = _parentNode.locals;
		_output.locals_written_to = _parentNode.locals_written_to;
		_output.local_index = _parentNode.local_look_ups[$ _output.key];
	}
	else if (_scope == "Global") {
		_output.globals = _rootNode.globals;
	}
	return _output;
}

#region Generic Setter    -    (These will use expressions instead of literal keys written to the method, for those see fast pass script)
#region jsDoc
/// @func    __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _key, _rightExpression, _span)
/// @desc    Compiles a write of an expression to a name of the given kind; a static toString is set apart.
/// @param   {Struct} _rootNode        : The program node
/// @param   {Struct} _parentNode      : The enclosing function node
/// @param   {String} _scope           : The symbol kind of the name
/// @param   {Any}    _key             : The name, or the get and set functions of an exposed variable
/// @param   {Struct} _rightExpression : The value's node
/// @param   {Struct} _span            : Where the node is in the source
/// @returns {Function}
#endregion
function __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _key, _rightExpression, _span){
	var _output = __GMLCscopeNode(_rootNode, _parentNode, _scope, _key, _span);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _rightExpression);

	if (_scope == "Static") && (_key == "toString") return __vanilla_method(_output, __GMLCexecuteSetStaticToString);
	return __vanilla_method(_output, __GMLCGetScopeSetter(_scope))
}
#endregion

#region Static toString
// GameMaker calls a struct's toString itself (string(), $"{}") with self and other set to the struct, which GMLC's
// own self does not follow. A static toString is kept under a hidden key and GameMaker gets an unbound function
// that runs it with GMLC's self and other set to the struct it was called on.
#macro __GMLC_STATIC_TO_STRING "__@@gmlc_static_toString@@__"
#region jsDoc
/// @func    __GMLCexecuteSetStaticToString()
/// @desc    Sets the static toString: a GMLC method is kept under a hidden key; GameMaker gets a function running it.
#endregion
function __GMLCexecuteSetStaticToString() {
	var _value = expression();
	if (is_gmlc_method(_value)) {
		parent_node.statics[$ __GMLC_STATIC_TO_STRING] = _value;
		parent_node.statics[$ key] = __vanilla_method(undefined, __GMLCexecuteStaticToString);
	}
	else {
		parent_node.statics[$ key] = _value;
	}
}
#region jsDoc
/// @func    __GMLCexecuteStaticToString()
/// @desc    Called by GameMaker with self the struct: runs its hidden toString with GMLC's self and other set to
///          that struct and returns the result.
/// @returns {Any}
#endregion
function __GMLCexecuteStaticToString() {
	var _prevOther = global.gmlc_other_instance;
	var _prevSelf  = global.gmlc_self_instance;
	global.gmlc_other_instance = self;
	global.gmlc_self_instance  = self;
	var _args = array_create(argument_count);
	var _i = 0; repeat (argument_count) {
		_args[_i] = argument[_i];
	_i++}
	var _return = method_call(self[$ __GMLC_STATIC_TO_STRING], _args);
	global.gmlc_other_instance = _prevOther;
	global.gmlc_self_instance  = _prevSelf;
	return _return;
}
#endregion

#endregion

#region jsDoc
/// @func    __GMLCcompileAccessor(_rootNode, _parentNode, _node)
/// @desc    Compiles a read through an accessor (`[ ]`, `[| ]`, `[? ]`, `[# ]`, `[$ ]`, `.`); `E.M` is its value.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : An Index node
/// @returns {Function}
#endregion
function __GMLCcompileAccessor(_rootNode, _parentNode, _node) {
	_node = __GMLCdesugarIndex(_node);
	var _keys = _node.keys;
	switch (_node.accessor) {
		case "Array":  return __GMLCcompileArrayGet       (_rootNode, _parentNode, _node.object, _keys[0],           _node.span)
		case "Grid":   return __GMLCcompileGridGet        (_rootNode, _parentNode, _node.object, _keys[0], _keys[1], _node.span)
		case "List":   return __GMLCcompileListGet        (_rootNode, _parentNode, _node.object, _keys[0],           _node.span)
		case "Map":    return __GMLCcompileMapGet         (_rootNode, _parentNode, _node.object, _keys[0],           _node.span)
		case "Struct": return __GMLCcompileStructGet      (_rootNode, _parentNode, _node.object, _keys[0],           _node.span)
		case "Dot": {
			if (_node.object.kind == __GMLC_NodeKind_Identifier) && (_node.object.symbol != undefined) && (_node.object.symbol.kind == "Enum") {
				return __vanilla_method({ value: __GMLCenumValue(_rootNode, _node) }, __GMLCexecuteLiteralExpression);
			}
			return __GMLCcompileStructDotAccGet(_rootNode, _parentNode, _node.object, _node.member, _node.span)
		}
		default: __gmlc_internal_error($"the compiler has no case for accessor {_node.accessor}", _node.span);
	}
}

#region jsDoc
/// @func    __GMLCcompileIdentifier(_rootNode, _parentNode, _node)
/// @desc    Compiles a name read: a built-in constant or function is its value, any other name a scope getter.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : An Identifier
/// @returns {Function}
#endregion
function __GMLCcompileIdentifier(_rootNode, _parentNode, _node) {
	var _scope = _node.symbol.kind;
	switch (_scope) {
		case "BuiltinConstant":
		case "BuiltinFunction": {
			// the value, as GameMaker has it (a built-in function read as a value is a plain number)
			return __vanilla_method({ value: __GMLCidentifierValue(_rootNode, _node) }, __GMLCexecuteLiteralExpression);
		}
		case "Enum": {
			__gmlc_internal_error($"the enum {_node.name} reached the compiler as a value", _node.span);
		}
	}
	return __vanilla_method(__GMLCscopeNode(_rootNode, _parentNode, _scope, __GMLCscopeKey(_rootNode, _node), _node.span), __GMLCGetScopeGetter(_scope))
}

#region jsDoc
/// @func    __GMLCscopeKey(_rootNode, _identifier)
/// @desc    What the scope executors read as `key` for a name: the get and set functions of a variable the environment
///          exposes, the name otherwise.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _identifier : An Identifier
/// @returns {Any}
#endregion
function __GMLCscopeKey(_rootNode, _identifier) {
	if (_identifier.symbol.kind == "BuiltinVar") {
		return _rootNode.env.getVariable(_identifier.name).value;
	}
	return _identifier.name;
}
#region jsDoc
/// @func    __GMLCidentifierValue(_rootNode, _identifier)
/// @desc    The value of a built-in constant or function name, as the environment exposes it (a function read as a
///          value is its plain number), or of one of GMLC's own helpers.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _identifier : An Identifier
/// @returns {Any}
#endregion
function __GMLCidentifierValue(_rootNode, _identifier) {
	// a function a language extension's rewrite calls is GMLC's own, whatever the environment exposes
	var _origin = _identifier.origin;
	if (_origin != undefined) && (_origin.kind == "extension") {
		var _own = __gmlc_internal_functions()[$ _identifier.name];
		if (_own != undefined) return _own;
	}
	var _env = _rootNode.env;
	var _data = (_identifier.symbol.kind == "BuiltinConstant") ? _env.getConstant(_identifier.name) : _env.getFunction(_identifier.name);
	if (_data == undefined) {
		return __gmlc_internal_functions()[$ _identifier.name];
	}
	return _data[$ "raw"] ?? _data.value;
}
#region jsDoc
/// @func    __GMLCenumValue(_rootNode, _node)
/// @desc    The value of `E.M` for an enum the environment exposes.
/// @param   {Struct} _rootNode : The program node
/// @param   {Struct} _node     : The Index node (Dot accessor)
/// @returns {Any}
#endregion
function __GMLCenumValue(_rootNode, _node) {
	return _rootNode.env.getEnum(_node.object.name).value[$ _node.member];
}

#endregion

#region Util
#region jsDoc
/// @func    __GMLC_Function(_rootNode, _parentNode, _base, _error, _span)
/// @desc    The node struct a compiled executor is bound to: its program, its function and where it is in the source.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {String} _base       : The compile function that made it
/// @param   {String} _error      : Its error message
/// @param   {Struct} _span       : Where the node is in the source
#endregion
function __GMLC_Function(_rootNode, _parentNode, _base, _error, _span) constructor {
	self[$ "__@@is_gmlc_program@@__"] = true;
	
	compiler_base = _base;
	error_message = _error;
	span = _span;
	
	
	root_node = _rootNode;
	parent_node = _parentNode;
	
	callstack = GMLC_DEBUG_CALLSTACK ? debug_get_callstack() : undefined;
}
static_get(__GMLC_Function)[$ "__@@is_gmlc_program@@__"] = true;

#region jsDoc
/// @func    __GMLC_Statics(_program_name)
/// @desc    The statics struct of a compiled function, named after it.
/// @param   {String} _program_name : The function's name
#endregion
function __GMLC_Statics(_program_name) constructor {
	self[$ "__@@gmlc_script_name@@__"] = _program_name;
}
#region jsDoc
/// @func    __GMLC_Constructor_Statics(_construct_name)
/// @desc    The statics struct of a compiled constructor.
/// @param   {String} _construct_name : The constructor's name
#endregion
function __GMLC_Constructor_Statics(_construct_name) : __GMLC_Statics(_construct_name) constructor {
	self[$ "__@@is_gmlc_constructed@@__"] = true;
}

#endregion


#endregion
