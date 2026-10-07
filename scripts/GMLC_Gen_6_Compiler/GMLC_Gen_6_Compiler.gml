#region Compiler.gml
	#region Compiler Module
	/*
	Purpose: To build the AST into a set of callable functions.
	
	Methods:
	
	optimize(ast): Entry function that takes an AST and returns an optimized AST.
	constantFolding(ast): Traverses the AST and evaluates expressions that can be determined at compile-time.
	deadCodeElimination(ast): Removes parts of the AST that do not affect the program outcome, such as unreachable code.
	*/
	#endregion
	function GMLC_Gen_6_Compiler(_env) constructor  {
		env = _env;
		
		//init variables:
		
		ast     = undefined;
		globals = undefined;
		sources = undefined;
		
		static initialize = function(_ast, _globalsStruct={}, _sources=undefined) {
			ast = _ast;
			globals = _globalsStruct;
			sources = _sources;
		}
		
		static cleanup = function() {
		
		}
		
		static parseAll = function() {
			return __GMLCcompileProgram(ast, globals, env, sources);
		}
		
		static nextNode = function() {
			//This is intended to one day allow for async compiling but until that day this is a place holder.
		};
		
	}
#endregion

// Private //////////////////////////

#region Config
// keep the compiler's call stack on every node it makes, for debugging GMLC itself: only in the Debug configuration,
// as it costs one call stack per node
#macro GMLC_DEBUG_CALLSTACK false
#macro Debug:GMLC_DEBUG_CALLSTACK true
#endregion

#region Macros
#region Globals for `self` and `other`
#macro __GMLC_DEFAULT_SELF_AND_OTHER	var _entered_on_this_function = false;\
										if (global.gmlc_other_instance == undefined)\
										&& (global.gmlc_self_instance == undefined) {\
											_entered_on_this_function = true;\
											global.gmlc_other_instance = global.gmlc_self_instance ?? (self[$ "rootNode"] ? rootNode[$ "globals"] : other) ?? other;\
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
										global.gmlc_other_instance = _pre_self ?? rootNode.globals;\
										global.gmlc_self_instance = _desired_self;\
									}
#macro __GMLC_RESET_SELF_AND_OTHER	global.gmlc_other_instance = _pre_other;\
									global.gmlc_self_instance = _pre_self
#endregion

#region Locals
#macro __GMLC_STASH_LOCALS	array_copy(backupLocals, array_length(backupLocals), locals, 0, localCount);\
							array_resize(locals, 0);\
							array_resize(locals, localCount);\
						    array_copy(backupLocalsWrittenTo, array_length(backupLocalsWrittenTo), localsWrittenTo, 0, localCount);\
							array_resize(localsWrittenTo, 0);\
							array_resize(localsWrittenTo, localCount)
							
#macro __GMLC_UNSTASH_LOCALS	var _local_offset = array_length(backupLocals)-localCount\
						        array_copy(locals, 0, backupLocals, _local_offset, localCount);\
						        array_resize(backupLocals, _local_offset);\
								var _local_offset = array_length(backupLocalsWrittenTo)-localCount\
						        array_copy(localsWrittenTo, 0, backupLocalsWrittenTo, _local_offset, localCount);\
						        array_resize(backupLocalsWrittenTo, _local_offset)

#macro __GMLC_RESET_LOCALS	array_resize(locals, 0);\
							array_resize(localsWrittenTo, 0);\
							array_resize(locals, localCount);\
							array_resize(localsWrittenTo, localCount)
#endregion

#region Arguments
#macro __GMLC_STASH_ARGUMENTS	array_copy(backupArguments, array_length(backupArguments), arguments, 0, prevArgCount);\
								array_resize(arguments, 0);\
								array_resize(arguments, _arg_count);\
								array_push(argCountMemory, _arg_count)
								
#macro __GMLC_UNSTASH_ARGUMENTS var _prev_arg_count = array_pop(argCountMemory)\
								var _arg_offset = array_length(backupArguments)-_prev_arg_count\
						        array_copy(arguments, 0, backupArguments, _arg_offset, _prev_arg_count);\
						        array_resize(backupArguments, _arg_offset)

#macro __GMLC_RESET_ARGUMENTS	array_resize(arguments, 0);

#macro __GMLC_INIT_ARGUMENT_COUNT	var _arg_count = max(argument_count, argumentCount)

#macro __GMLC_POPULATE_ARGUMENTS	prevArgCount = _arg_count;\
									array_resize(arguments, argument_count)\
									var _i=argument_count-1; repeat(argument_count) {\
										arguments[_i] = argument[_i];\
									_i--}\
									if (struct_exists(self, "argumentsDefault")) {\
										argumentsDefault();\
									}
#endregion

#region Constructors
#macro __GMLC_CALL_PARENT_CONSTRUCTOR	if (self[$ "hasParentConstructor"]) {\
											if (is_handle(parentConstructorCall) && is_callable(parentConstructorCall)) {\
												parentConstructorCall(arguments)\
											}\
										}

#endregion

#region Statics
#macro __GMLC_INIT_STATICS	if (struct_exists(self, "staticsExecuted") && !staticsExecuted) {\
								staticsExecuted = true;\
								staticsBlock();\
							}

#endregion

#macro __GMLC_PRE_FUNC	__GMLC_DEFAULT_SELF_AND_OTHER\
						array_push(global.__gmlc_active_functions, self);\
						__GMLC_INIT_ARGUMENT_COUNT\
						if (recursionCount++) {\
						    __GMLC_STASH_LOCALS\
							__GMLC_STASH_ARGUMENTS\
						}\
						__GMLC_POPULATE_ARGUMENTS\
						__GMLC_INIT_STATICS
						

#macro __GMLC_POST_FUNC	array_pop(global.__gmlc_active_functions);\
						returnValue = undefined;\
						flowMask = FLOW_MASK.EMPTY;\
						if (--recursionCount) {\
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
			returnValue = undefined;
			flowMask = FLOW_MASK.EMPTY;
			if (--recursionCount) {
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

function executeProgram(_program) {
	//this function should never be called inside a prgroam, for that use `__executeProgram`
	var _depth = array_length(global.__gmlc_active_functions);
	global.gmlc_self_instance = self;
    global.gmlc_other_instance = other;
	
	try {
		return _program();
	}
	catch (_e) {
		// the functions the error left must not count as still running at the next call
		__GMLCunwindTo(_depth);
		global.gmlc_self_instance = undefined;
		global.gmlc_other_instance = undefined;
		throw _e;
	}
}

#region Structural Nodes

#region //{
// used to start the initial entry into the compiled program, mostly just to init variables like 
//    program: <expression>,
//    varStatics: {},
//    locals: {},
//}
#endregion
function __GMLCexecuteProgram() {
	static globals = function(){ return method_get_self(self).globals }
	
	__GMLC_DEFAULT_SELF_AND_OTHER
	__GMLC_PRE_FUNC
	
	////////////////EXECUTE////////////////////////
	var _return = program();
	///////////////////////////////////////////////
	
	__GMLC_POST_FUNC
	
	return _return;
}
function __GMLCcompileProgram(_node, _globalsStruct, _env=undefined, _sources=undefined) {
	var _output = new __GMLC_Function(undefined, undefined, "__GMLCcompileProgram", "<Missing Error Message>", _node.span);
	_output.rootNode = _output;
	_output.env = _env; // calls through a plain function number are checked against what it exposes
	_output.sources = _sources; // the compile's files: node spans give the lines of errors
	_output.globals = _globalsStruct; // these are optional inputs for future use with compiling a full project folder.
	_output.scopeStack = ["Global"]; // how a function expression is bound where it appears (see __GMLCcompileFunctionExpr)
	_output.functions = _node.functions; // what the resolver found about each function (its locals), by fn_id
	
	// the declared functions are compiled where they are met and registered in the globals; the body of the file is a
	// function without parameters
	_output.program = __GMLCcompileFunction(_output, _output, _node);
	
	// the file's body is the function above, which holds its locals; the program itself has none
	_output.localLookUps = {};
	_output.localCount = 0;
	_output.locals = [];
	_output.localsWrittenTo = [];
	_output.backupLocals = [];
	_output.backupLocalsWrittenTo = [];
	
	_output.recursionCount = 0;
	_output.prevArgCount = 0;
	_output.argumentCount = 0;
	_output.arguments = [];
	_output.backupArguments = [];
	_output.argCountMemory = [];
	
	return __vanilla_method(_output, __GMLCexecuteProgram)
}

#region jsDoc
/// @func    __GMLClocalLookUps(_rootNode, _node)
/// @desc    The parameters and locals of a function as name to slot, from what the resolver found (the file's
///          `functions`), with their count.
/// @param   {Struct} _rootNode : The program node
/// @param   {Struct} _node     : A function node or the Script
/// @returns {Struct} {lookUps, count}
#endregion
function __GMLClocalLookUps(_rootNode, _node) {
	var _info = _rootNode.functions[(_node.kind == __GMLC_NodeKind_Script) ? 0 : _node.fn_id];
	var _lookUps = {};
	// the parameters take slots 0 to n-1, the locals the slots after them
	var _i = 0; repeat (array_length(_info.params)) {
		_lookUps[$ _info.params[_i]] = _i;
	_i++}
	var _n = array_length(_info.params);
	_i = 0; repeat (array_length(_info.locals)) {
		_lookUps[$ _info.locals[_i]] = _n + _i;
	_i++}
	return { lookUps: _lookUps, count: _n + array_length(_info.locals) };
}

function __GMLCexecuteExpression() {};
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

function __GMLCexecuteFunction() {
	__GMLC_DEFAULT_SELF_AND_OTHER
	__GMLC_PRE_FUNC
	
	////////////////EXECUTE////////////////////////
	method_call(program, arguments);
	var _return = returnValue;
	///////////////////////////////////////////////
	
	__GMLC_POST_FUNC
	
	return _return;
}
function __GMLCcompileFunction(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, undefined, "__GMLCcompileFunction", "<Missing Error Message>", _node.span);
	_output[$ "__@@is_gmlc_function@@__"] = true;
	
	_output.parentNode = _output;
	
	_output.recursionCount = 0; 
	
	// the body of the file (a Script) is a function without parameters
	_output.isScriptBody = (_node.kind == __GMLC_NodeKind_Script);
	// an object event's top-level functions become methods of the instance
	_output.isEventBody = _output.isScriptBody && (_node[$ "unitKind"] == "event");
	var _params = _node[$ "params"] ?? [];
	
	//this assists with converting locals from struct accessors to an array write
	var _locals = __GMLClocalLookUps(_rootNode, _node);
	_output.localLookUps = _locals.lookUps;
	var _i = _locals.count;
	_output.localCount = _i;
	_output.locals = array_create(_i, undefined);
	_output.localsWrittenTo = array_create(_i, false); //remember if we ever wrote to those locals, this is used to throw errors incase we are reading from an unwritten local
	_output.backupLocals = [];//if the function is recursive stash the locals back into this array, to<->from
	_output.backupLocalsWrittenTo = [];//if the function is recursive stash the locals back into this array, to<->from
	
	//arguments
	_output.argumentsDefault = __GMLCcompileArgumentList(_rootNode, _output, _params, _node);
	_output.argumentCount = array_length(_params);
	_output.prevArgCount = 0;
	_output.arguments = [];
	_output.backupArguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argCountMemory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	//statics, collected while the body compiles
	_output.staticsExecuted = false;
	_output.statics = new __GMLC_Statics(_node[$ "name"]);
	_output.staticDeclarations = [];
	static_set(_output, _output.statics)
	
	//block statement; function expressions in a function's body are methods of its `self`, as in GameMaker
	if (!_output.isScriptBody) array_push(_rootNode.scopeStack, "Self");
	_output.program = __GMLCcompileBlockStatement(_rootNode, _output, (_output.isScriptBody) ? _node : _node.body);
	if (!_output.isScriptBody) array_pop(_rootNode.scopeStack);
	_output.staticsBlock = __GMLCcompileStatics(_rootNode, _output, _node);
	
	_output.returnValue = undefined;
	_output.flowMask = FLOW_MASK.EMPTY;
	
	
	return __vanilla_method(_output, __GMLCexecuteFunction)
}

function __GMLCexecuteConstructor() constructor {
	//check to see if this is a `new` expression, or some `script_execute` equivalent using `method_call`
	var _self_is_gmlc  = self[$ "__@@is_gmlc_function@@__"];
	var _is_new_expression = !_self_is_gmlc;
	
	var _program_data = (_is_new_expression) ? other : self;
	with _program_data {
		var _program = program;
		var _arguments = arguments;
		var _statics = statics;
		
		__GMLC_DEFAULT_SELF_AND_OTHER
		
		if (_is_new_expression) {
			__GMLC_UPDATE_SELF_AND_OTHER
		}
		
		array_push(global.__gmlc_active_functions, self);
		__GMLC_INIT_ARGUMENT_COUNT
		if (recursionCount++) {
			__GMLC_STASH_LOCALS
			__GMLC_STASH_ARGUMENTS
		}
		
		prevArgCount = _arg_count;
		var _i=argument_count-1; repeat(argument_count) {
			arguments[_i] = argument[_i];
		_i--}
		if (struct_exists(self, "argumentsDefault")) {
			argumentsDefault();
		}
										
		if (_program_data[$ "hasParentConstructor"]) {
			parentConstructorCall(arguments)
			var _obj_statics = static_get(global.gmlc_self_instance);
			static_set(_statics, _obj_statics);
		}
		__GMLC_INIT_STATICS
	}
	
	static_set(global.gmlc_self_instance, _statics);
	method_call(_program, _arguments);
	
	if (_is_new_expression) {
		__GMLC_RESET_SELF_AND_OTHER
	}
	
	if (_is_new_expression) {
		with other {
			var _return = returnValue;
			__GMLC_POST_FUNC
			__GMLC_RESET_DEFAULT_SELF_AND_OTHER
		}
	}
	else {
		var _return = returnValue;
		__GMLC_POST_FUNC
		__GMLC_RESET_DEFAULT_SELF_AND_OTHER
	}
	
	return _return;
}
function __GMLCcompileConstructor(_rootNode, _parentNode, _node) {
	static __waitingForParent = {}; // parent constructor name to the children compiled before it: {statics, globals}
	
	var _output = new __GMLC_Function(_rootNode, undefined, "__GMLCcompileConstructor", "<Missing Error Message>", _node.span);
	_output[$ "__@@is_gmlc_function@@__"] = true;
	
	_output.parentNode = _output;
	
	//parent constructor
	_output.hasParentConstructor = false;
	_output.parentConstructorName = undefined;
	_output.parentConstructorCall = undefined;
	
	_output.recursionCount = 0; 
	
	//locals
	var _locals = __GMLClocalLookUps(_rootNode, _node);
	_output.localLookUps = _locals.lookUps;
	var _i = _locals.count;
	_output.localCount = _i;
	_output.locals = array_create(_i, undefined);
	_output.localsWrittenTo = array_create(_i, false); //remember if we ever wrote to those locals, this is used to throw errors incase we are reading from an unwritten local
	_output.backupLocals = [];//if the function is recursive stash the locals back into this array, to<->from
	_output.backupLocalsWrittenTo = [];//if the function is recursive stash the locals back into this array, to<->from
	
	//arguments
	_output.argumentsDefault = __GMLCcompileArgumentList(_rootNode, _output, _node.params, _node);
	_output.argumentCount = method_get_self(_output.argumentsDefault).size;
	_output.prevArgCount = 0;
	_output.arguments = [];
	_output.backupArguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argCountMemory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	//statics, collected while the body compiles
	_output.staticsExecuted = false;
	_output.statics = new __GMLC_Constructor_Statics(_node.name);
	_output.staticDeclarations = [];
	static_set(_output, _output.statics)
	
	//block statement; the body of a constructor binds the function expressions in it to the new struct
	array_push(_rootNode.scopeStack, "Self");
	_output.program = __GMLCcompileBlockStatement(_rootNode, _output, _node.body);
	array_pop(_rootNode.scopeStack);
	_output.staticsBlock = __GMLCcompileStatics(_rootNode, _output, _node);
	
	_output.returnValue = undefined;
	_output.flowMask = FLOW_MASK.EMPTY;
	
	if (_node.parent != undefined) {
		var _parentCallee = _node.parent.callee;
		var _parentName = (_parentCallee.kind == __GMLC_NodeKind_Identifier) ? _parentCallee.name : undefined;
		_output.hasParentConstructor = true;
		_output.parentConstructorName = _parentName;
		_output.parentConstructorCall = __GMLCcompileCallExpression(_rootNode, _output, _node.parent);
		
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
		
		
		//_output.parentConstructor = rootNode.globals[$ parentName];
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

function __GMLCexecuteArgumentList() {
	var _inputArguments = parentNode.arguments
	var _inputLength = array_length(_inputArguments);
	
	var _i=0; repeat(size) {
		var _arg = statements[_i]
		if (_arg.index != _i) throw_gmlc_error("Why does our index not match our arguments index?")
		
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
		parentNode.locals[_arg.localIndex] = _inputArguments[_i];
		parentNode.localsWrittenTo[_arg.localIndex] = true;
		
	_i++}
}
function __GMLCcompileArgumentList(_rootNode, _parentNode, _params, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileArgumentList", "<Missing Error Message>", _node.span);
	_output.statements = [];
	_output.size = undefined;
	
	//_output.varStatics = {};
	//_output.locals = {};
	
	
	var _arr = _params;
	var _i=0; repeat(array_length(_arr)) {
		_output.statements[_i] = __GMLCcompileArgument(_rootNode, _parentNode, _arr[_i], _i);
	_i++}
	
	_output.size = array_length(_output.statements);
	
	return __vanilla_method(_output, __GMLCexecuteArgumentList)
}

function __GMLCcompileArgument(_rootNode, _parentNode, _node, _index) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileArgument", "<Missing Error Message>", _node.span);
	_output.index = _index;
	_output.localIndex = _parentNode.localLookUps[$ _node.target.name];
	_output.identifier = _node.target.name;
	// a parameter without a default is undefined when its argument is missing
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
	var _declarations = _parentNode.staticDeclarations;
	if (array_length(_declarations) == 0) return function(){};
	// function expressions in a static's value are unbound methods
	array_push(_rootNode.scopeStack, "Static");
	var _compiled = [];
	var _i = 0; repeat (array_length(_declarations)) {
		var _decl = _declarations[_i];
		if (_decl.init != undefined) {
			array_push(_compiled, __GMLCcompilePropertySet(_rootNode, _parentNode, "Static", _decl.target.name, _decl.init, _decl.span));
		}
	_i++}
	array_pop(_rootNode.scopeStack);
	return __GMLCblockOf(_rootNode, _parentNode, _node, _compiled);
}
// the declarators of a `static` statement, for __GMLCcompileStatics of the function it is in
function __GMLCaddStatics(_parentNode, _node) {
	var _out = _parentNode.staticDeclarations;
	array_copy(_out, array_length(_out), _node.declarations, 0, array_length(_node.declarations));
}

#region jsDoc
/// @func    __GMLCcompileFunctionNode(_rootNode, _node)
/// @desc    Compiles a function or constructor declaration, or a function expression, into its function.
/// @param   {Struct} _rootNode : The program node
/// @param   {Struct} _node     : A FunctionDecl, ConstructorDecl or FunctionExpr
/// @returns {Function}
#endregion
function __GMLCcompileFunctionNode(_rootNode, _node) {
	var _isConstructor = (_node.kind == __GMLC_NodeKind_ConstructorDecl) || (_node[$ "is_constructor"] == true);
	return _isConstructor ? __GMLCcompileConstructor(_rootNode, undefined, _node) : __GMLCcompileFunction(_rootNode, undefined, _node);
}

#region jsDoc
/// @func    __GMLCcompileSelfMethod(_rootNode, _parentNode, _node)
/// @desc    A function declared inside a function: running the statement makes it a method of `self` under its name,
///          as GameMaker does.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _parentNode : The enclosing function node
/// @param   {Struct} _node       : A FunctionDecl or ConstructorDecl
/// @returns {Function}
#endregion
function __GMLCcompileSelfMethod(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileSelfMethod", "<Missing Error Message>", _node.span);
	_output.key = _node.name;
	_output.expression = __vanilla_method({ func: __GMLCcompileFunctionNode(_rootNode, _node) }, __GMLCexecuteMethodOfSelf);
	return __vanilla_method(_output, __GMLCexecuteSetPropertySelf);
}

#region jsDoc
/// @func    __GMLCcompileDeclaredFunction(_rootNode, _node)
/// @desc    Compiles a `function name() {}` statement and registers it in the globals under its name.
/// @param   {Struct} _rootNode : The program node
/// @param   {Struct} _node     : A FunctionDecl or ConstructorDecl
/// @returns {Function}
#endregion
function __GMLCcompileDeclaredFunction(_rootNode, _node) {
	var _compiled = __GMLCcompileFunctionNode(_rootNode, _node);
	_rootNode.globals[$ _node.name] = _compiled;
	return _compiled;
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
function __GMLCexecuteMethodOfSelf() {
	return __gmlc_method(global.gmlc_self_instance, func);
}
function __GMLCexecuteMethodUnbound() {
	return __gmlc_method(undefined, func);
}
function __GMLCcompileFunctionExpr(_rootNode, _parentNode, _node) {
	var _scope = _rootNode.scopeStack[array_length(_rootNode.scopeStack) - 1];
	var _compiled = __GMLCcompileFunctionValue(_rootNode, _node);
	switch (_scope) {
		case "Self":   return __vanilla_method({ func: _compiled }, __GMLCexecuteMethodOfSelf);
		case "Static": return __vanilla_method({ func: _compiled }, __GMLCexecuteMethodUnbound);
	}
	return __vanilla_method({ value: _compiled }, __GMLCexecuteLiteralExpression);
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
	var _compiled = __GMLCcompileFunctionNode(_rootNode, _node);
	if (!string_starts_with(_node.name, "GMLC@anon@")) {
		_rootNode.globals[$ _node.name] = _compiled;
	}
	return _compiled;
}

#endregion

#region Statements

#region Block Statements

function __GMLCexecuteBlockStatement() {
    var i = 0;
    repeat(size) {
        blockStatements[i]();
		// Check for jump conditions.
		if (parentNode.flowMask) {
			return;
		}
	i++;}
}
function __GMLCcompileBlockStatement(_rootNode, _parentNode, _node) {
	if (_node == undefined) {
		return function(){};
	}
	
	// If the node is not a block, simply compile it as an expression.
	if (_node.kind != __GMLC_NodeKind_Block) && (_node.kind != __GMLC_NodeKind_Script) {
		return __GMLCcompileExpression(_rootNode, _parentNode, _node);
	}
	
	// the statements, nested blocks and declaration lists opened into this one
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
				// nothing to run here
			break;}
			case __GMLC_NodeKind_StaticDecl: {
				// run once, before the body (see __GMLCcompileStatics)
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
				if (_parentNode[$ "isScriptBody"] == true) && (_parentNode[$ "isEventBody"] != true) {
					// at the top level of a script: a global, compiled before the program runs
					__GMLCcompileDeclaredFunction(_rootNode, _statement);
				}
				else {
					array_push(_out, __GMLCcompileSelfMethod(_rootNode, _parentNode, _statement));
				}
			break;}
			default: {
				array_push(_out, __GMLCcompileExpression(_rootNode, _parentNode, _statement));
			break;}
		}
	_i++}
}
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
	_output.blockStatements = _compiled;
	_output.size = _size;
	return __vanilla_method(_output, __GMLCexecuteBlockStatement);
}

#endregion

#region //{
// used for gmlc compiled repeat blocks
//    condition: <expression>,
//    trueBlock: <expression>,
//}
#endregion
function __GMLCexecuteIf() {
    if (condition())
		trueBlock();
}
#region //{
// used for gmlc compiled repeat blocks
//    condition: <expression>,
//    trueBlock: <expression>,
//    elseBlock: <expression>,
//}
#endregion
function __GMLCexecuteIfElse() {
    ///NOTE: it might be faster to use a ternary operation here,
    // it is worth investigating with a benchmark
	if (condition()) {
		trueBlock()
    }
    else {
		elseBlock();
    }
}
function __GMLCcompileIf(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileIf", "<Missing Error Message>", _node.span);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.test);
	_output.trueBlock = __GMLCcompileExpression(_rootNode, _parentNode, _node.consequent);
	
	//if there is no 'else', or an empty one
	if (_node.alternate == undefined)
	|| (array_length(_node.alternate.body) == 0) {
		return __vanilla_method(_output, __GMLCexecuteIf);
    }
	else {
		_output.elseBlock = __GMLCcompileExpression(_rootNode, _parentNode, _node.alternate);
		return __vanilla_method(_output, __GMLCexecuteIfElse);
    }
}

#region //{
// used for gmlc compiled repeat blocks
//    expression: <expression>,
//    blockStatement: {},
//}
#endregion
function __GMLCexecuteRepeat() {
    repeat(condition()) {
		blockStatement();
		if (parentNode.flowMask) {
			if (parentNode.flowMask & FLOW_MASK.CONTINUE) {
				// Clear the continue bit so that subsequent iterations or parent blocks see it as cleared.
				parentNode.flowMask &= ~FLOW_MASK.CONTINUE;
			}
			if (parentNode.flowMask & FLOW_MASK.BREAK) {
				// Clear the break bit so that subsequent iterations or parent blocks see it as cleared.
				parentNode.flowMask &= ~FLOW_MASK.BREAK;
				return undefined;
			}
			if (parentNode.flowMask & FLOW_MASK.RETURN) {
				return undefined;
			}
		}
    }
}
function __GMLCcompileRepeat(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileRepeat", "<Missing Error Message>", _node.span);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.count);
	_output.blockStatement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.body);
    
    return __vanilla_method(_output, __GMLCexecuteRepeat);
}

#region //{
// used for gmlc compiled while blocks
//    expression: <expression>,
//    blockStatement: {},
//}
#endregion
function __GMLCexecuteWhile() {
    while(condition()) {
		blockStatement();
		if (parentNode.flowMask) {
			if (parentNode.flowMask & FLOW_MASK.CONTINUE) {
				// Clear the continue bit so that subsequent iterations or parent blocks see it as cleared.
				parentNode.flowMask &= ~FLOW_MASK.CONTINUE;
			}
			if (parentNode.flowMask & FLOW_MASK.BREAK) {
				// Clear the break bit so that subsequent iterations or parent blocks see it as cleared.
				parentNode.flowMask &= ~FLOW_MASK.BREAK;
				return undefined;
			}
			if (parentNode.flowMask & FLOW_MASK.RETURN) {
				return undefined;
			}
		}
    }
}
function __GMLCcompileWhile(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileWhile", "<Missing Error Message>", _node.span);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.test);
	_output.blockStatement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.body);
    
    return __vanilla_method(_output, __GMLCexecuteWhile);
}

#region //{
// used for gmlc compiled do/until blocks
//    expression: <expression>,
//    blockStatement: {},
//}
#endregion
function __GMLCexecuteDoUntil() {
    do {
		blockStatement();
		if (parentNode.flowMask) {
			if (parentNode.flowMask & FLOW_MASK.CONTINUE) {
				// Clear the continue bit so that subsequent iterations or parent blocks see it as cleared.
				parentNode.flowMask &= ~FLOW_MASK.CONTINUE;
			}
			if (parentNode.flowMask & FLOW_MASK.BREAK) {
				// Clear the break bit so that subsequent iterations or parent blocks see it as cleared.
				parentNode.flowMask &= ~FLOW_MASK.BREAK;
				return undefined;
			}
			if (parentNode.flowMask & FLOW_MASK.RETURN) {
				return undefined;
			}
		}
    }
    until condition()
}
function __GMLCcompileDoUntil(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileDoUntil", "<Missing Error Message>", _node.span);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.test);
	_output.blockStatement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.body);
    
    return __vanilla_method(_output, __GMLCexecuteDoUntil);
}

#region //{
// used for gmlc compiled for statements
//    assignment: <expression>,
//    expression: <expression>,
//    operation: <expression>,
//    blockStatement: <blockStatement>,
//}
#endregion
function __GMLCexecuteFor() {
    for (
		assignment();
		condition();
		{operation();
			if (parentNode.flowMask) {
				if (parentNode.flowMask & FLOW_MASK.CONTINUE) {
					// Clear the continue bit so that subsequent iterations or parent blocks see it as cleared.
					parentNode.flowMask &= ~FLOW_MASK.CONTINUE;
				}
				if (parentNode.flowMask & FLOW_MASK.BREAK) {
					// Clear the break bit so that subsequent iterations or parent blocks see it as cleared.
					parentNode.flowMask &= ~FLOW_MASK.BREAK;
					return undefined;
				}
				if (parentNode.flowMask & FLOW_MASK.RETURN) {
					return undefined;
				}
			}
		}
	) {
		blockStatement();
		if (parentNode.flowMask) {
			if (parentNode.flowMask & FLOW_MASK.CONTINUE) {
				// Clear the continue bit so that subsequent iterations or parent blocks see it as cleared.
				parentNode.flowMask &= ~FLOW_MASK.CONTINUE;
			}
			if (parentNode.flowMask & FLOW_MASK.BREAK) {
				// Clear the break bit so that subsequent iterations or parent blocks see it as cleared.
				parentNode.flowMask &= ~FLOW_MASK.BREAK;
				return undefined;
			}
			if (parentNode.flowMask & FLOW_MASK.RETURN) {
				return undefined;
			}
		}
    }
}
function __GMLCcompileFor(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileFor", "<Missing Error Message>", _node.span);
	_output.assignment     = (_node.init   == undefined) ? function(){}            : __GMLCcompileBlockStatement(_rootNode, _parentNode, new ASTBlock(_node.init.span, [_node.init]));
	_output.condition      = (_node.test   == undefined) ? function(){return true} : __GMLCcompileExpression(_rootNode, _parentNode, _node.test);
	_output.operation      = (_node.update == undefined) ? function(){}            : __GMLCcompileBlockStatement(_rootNode, _parentNode, new ASTBlock(_node.update.span, [_node.update]));
	_output.blockStatement = (_node.body   == undefined) ? function(){}            : __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.body);
    
	return __vanilla_method(_output, __GMLCexecuteFor);
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
	var _start = defaultIndex;
	var _i=0; repeat(labelCount) {
		if (labels[_i]() == _value) {
			_start = labelCases[_i];
			break;
		}
	_i++}
	if (_start < 0) return undefined;
	
	var _i=_start; repeat(size - _start) {
		cases[_i].blockStatement()
		if (parentNode.flowMask) {
			if (parentNode.flowMask & FLOW_MASK.RETURN) return undefined;
			// a break ends the switch; a continue leaves it for the loop around it
			break;
		}
	_i++}
	
	parentNode.flowMask &= ~FLOW_MASK.BREAK;
}
function __GMLCcompileSwitch(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileSwitch", "<Missing Error Message>", _node.span);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.discriminant);
	_output.cases = [];
	_output.labels = [];     // the labels of the cases, in source order, `default` left out
	_output.labelCases = []; // the case each label starts
	_output.defaultIndex = -1;
	_output.size = 0;
    
    
    var _i=0; repeat(array_length(_node.cases)) {
		var _case = _node.cases[_i];
		var _struct = __GMLCcompileCase(_rootNode, _parentNode, _case);
		
		//the cases stay in source order; remember where `default` is
		if (_struct.isDefault) {
			_output.defaultIndex = _i;
		}
		else {
			array_push(_output.labels, _struct.expression);
			array_push(_output.labelCases, _i);
		}
		array_push(_output.cases, _struct);
    
    _i++}
    
    _output.size = array_length(_output.cases);
    _output.labelCount = array_length(_output.labels);
    
    return __vanilla_method(_output, __GMLCexecuteSwitch);
}
function __GMLCcompileCase(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileCase", "<Missing Error Message>", _node.span);
	_output.isDefault = (_node.kind == __GMLC_NodeKind_Default);
	_output.expression = (_output.isDefault) ? undefined : __GMLCcompileExpression(_rootNode, _parentNode, _node.test);
	_output.blockStatement = __GMLCcompileBlockStatement(_rootNode, _parentNode, new ASTBlock(_node.span, _node.body));
    
    
    return _output;
}

#region //{
// used to execute gmlc compiled `with` statements
//    expression: <expression>
//    blockStatement: <blockStatementBreakable>
//}
#endregion
function __GMLCexecuteWith() {
    //early out
    var _inst = expression()
	if (_inst == undefined) return undefined
	if (_inst == -5) { _inst = rootNode.globals}// safety check for `-5` equalling `global`
    
    var _self = global.gmlc_self_instance;
    var _other = global.gmlc_other_instance;
    
    //this mimics a with statement, but ultimately its not actually need to use `with`
    // until we hit a natively compiled function, as all glmc functions will directly
    // handle the instance
    global.gmlc_other_instance = global.gmlc_self_instance
    
	var _methodself   = self;
	var _parentNode   = parentNode;
	
	static __empty_arr = [];
	with (_inst) {
		global.gmlc_self_instance = self;
		
		method_call(_methodself.blockStatement, __empty_arr);
		
		//we break on all three cases here because we would like to run the
		// rest of the function to return to our previous self/other
		if (_parentNode.flowMask) {
			if (_parentNode.flowMask & FLOW_MASK.CONTINUE) {
				// Clear the continue bit so that subsequent iterations or parent blocks see it as cleared.
				_parentNode.flowMask &= ~FLOW_MASK.CONTINUE;
			}
			if (_parentNode.flowMask & FLOW_MASK.BREAK) {
				// Clear the break bit so that subsequent iterations or parent blocks see it as cleared.
				_parentNode.flowMask &= ~FLOW_MASK.BREAK;
				break;
			}
			if (_parentNode.flowMask & FLOW_MASK.RETURN) {
				// Clear the return bit so that subsequent iterations or parent blocks see it as cleared.
				break;
			}
		}
		
	}
    
    //reset
    global.gmlc_self_instance = _self;
    global.gmlc_other_instance = _other;
}
function __GMLCcompileWith(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileWith", "<Missing Error Message>", _node.span);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.target);
	_output.blockStatement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.body);
    //_output.mySelf  = _output;
    //_output.myIndex = __GMLCexecuteWith;
    //_output.myMethod = __vanilla_method(_output, __GMLCexecuteWith);
	
	return __vanilla_method(_output, __GMLCexecuteWith);
}

#region //{
// used to execute gmlc compiled `try/catch/finally` statements
//    tryBlock: <block>
//    catchBlock: <block>
//    finallyBlock: <block>
//    catchVariable: <string>
//}
#endregion
function __GMLCexecuteTryCatchFinally() {
	// one GML try per compiled try, so GameMaker's own rules apply: finally runs
	// after the try and after a catch that handles the error, and before an error leaves a try that has no catch;
	// it does not run when the catch block itself throws.
	// An error unwinds the compiled functions it left and the `with` it left (self and other), before the catch or
	// finally runs.
	var _depth = array_length(global.__gmlc_active_functions);
	var _self = global.gmlc_self_instance;
	var _other = global.gmlc_other_instance;
	if (catchBlock == undefined) {
		try {
			tryBlock()
		}
		finally {
			__GMLCunwindTo(_depth);
			global.gmlc_self_instance = _self;
			global.gmlc_other_instance = _other;
			if (finallyBlock != undefined) finallyBlock();
		}
		return;
	}
	try {
		tryBlock()
	}
	catch (_e) {
		__GMLCunwindTo(_depth);
		global.gmlc_self_instance = _self;
		global.gmlc_other_instance = _other;
		if (parentNode.flowMask & FLOW_MASK.RETURN) return;
		parentNode.locals[catchVariableIndex] = _e;
		parentNode.localsWrittenTo[catchVariableIndex] = true;
		catchBlock()
	}
	finally {
		if (finallyBlock != undefined) finallyBlock();
	}
}
function __GMLCcompileTryCatchFinally(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileTryCatchFinally", "<Missing Error Message>", _node.span);
	_output.tryBlock = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.block);
	_output.catchVariableIndex = (_node.catch_param != undefined) ? _parentNode.localLookUps[$ _node.catch_param.name] : undefined;
	_output.catchBlock = undefined;
	_output.finallyBlock = undefined;
	
	
	if (_node.catch_body != undefined)   _output.catchBlock   = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.catch_body)
	if (_node.finally_body != undefined) _output.finallyBlock = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.finally_body)
	
	if (_node.catch_body == undefined)
	&& (_node.finally_body == undefined) {
		return _output.tryBlock;
	}
	
    return __vanilla_method(_output, __GMLCexecuteTryCatchFinally);
}

#endregion

#region Keyword Statements

#region //{
// used to inform gmlc that a break has occured
//    callee
//    calleeName
//    argArr
//    size
//}
#endregion
function __GMLCexecuteNewExpression() {
	var _func = callee()
	
	if (!is_method(_func)) {
		if (!is_callable(_func)) {
			throw $"Attempting to call new method on a non-callable value :: `{_func}`"
		}
		_func = __GMLCcallableFromIndex(rootNode, _func);
	}
	
	//mostly just used in recursion code
	var _arg_count = max(argument_count, argumentCount)
	
	if (recursionCount++) {
        // stash the arguments
        array_copy(backupArguments, array_length(backupArguments), arguments, 0, prevArgCount);
		array_resize(arguments, 0);
		array_resize(arguments, _arg_count);
		array_push(argCountMemory, _arg_count);
    }
	
	//remember how many the function had
	prevArgCount = _arg_count;
	
	//avoids garbage collection lag spikes
	array_resize(arguments, argumentCount);
	var _prevOther = global.gmlc_other_instance;
	var _prevSelf  = global.gmlc_self_instance;
	var _i=argumentCount-1; repeat(argumentCount) {
		arguments[_i] = argumentExpressions[_i]();
	_i--}
	
	// GMLC constructors need the program data as `other` (constructor_call_ext); native constructors get a real `new`
	var _struct = (is_gmlc_constructor(_func)) ? constructor_call_ext(_func, arguments) : __gmlc_new_native(_func, arguments);
	
	if (--recursionCount) {
        // Un-stash the arguments
		var _prev_arg_count = array_pop(argCountMemory)
		var _arg_offset = array_length(backupArguments)-_prev_arg_count
        array_copy(arguments, 0, backupArguments, _arg_offset, _prev_arg_count);
        array_resize(backupArguments, _arg_offset);
    }
	else {
		array_resize(arguments, 0);
		if (array_length(backupArguments)) {
			throw_gmlc_error($"huh... the array sizes aren't correct\narray_length(backupArguments) == {array_length(backupArguments)}\narray_length(backupArguments) == {array_length(backupArguments)}")
		}
	}
	
	return _struct;
	
}
function __GMLCcompileNewExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileNewExpression", "<Missing Error Message>", _node.span);
	
	var _argArr = _node.args;
	_output.callee = __GMLCcompileCallee(_rootNode, _parentNode, _node.callee);
	
	_output.recursionCount = 0; 
	_output.prevArgCount = 0;
	_output.argumentCount = array_length(_argArr);
	_output.argumentExpressions = array_create(_output.argumentCount);
	_output.arguments = array_create(_output.argumentCount);
	_output.backupArguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argCountMemory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	var _i=0; repeat(array_length(_argArr)) {
		_output.argumentExpressions[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _argArr[_i])
	_i++}
    
    return __vanilla_method(_output, __GMLCexecuteNewExpression);
}
#region //{
// used to inform gmlc that a break has occured
//    no data needed
//}
#endregion
function __GMLCexecuteBreak() {
    parentNode.flowMask |= FLOW_MASK.BREAK;
}
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
    parentNode.flowMask |= FLOW_MASK.CONTINUE;
}
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
    parentNode.flowMask |= FLOW_MASK.RETURN;
    parentNode.returnValue = undefined;
}
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
    parentNode.returnValue = expression();
	parentNode.flowMask |= FLOW_MASK.RETURN;
}
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
	var _arg_count = max(argument_count, argumentCount)
	
	if (recursionCount++) {
        // stash the arguments
        array_copy(backupArguments, array_length(backupArguments), arguments, 0, prevArgCount);
		array_resize(arguments, 0);
		array_resize(arguments, _arg_count);
		array_push(argCountMemory, _arg_count)
    }
	
	//remember how many the function had
	prevArgCount = _arg_count;
	
	
	//avoids garbage collection lag spikes
	array_resize(arguments, 0);
	
	var _prevOther = global.gmlc_other_instance;
	var _prevSelf  = global.gmlc_self_instance;
	var _return = undefined;
	var _i=argumentCount-1; repeat(argumentCount) {
		arguments[_i] = argumentExpressions[_i]();
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

	if (is_method(_func)) {
		if (is_gmlc_constructor(_func)) {
			var _program_data = method_get_self(_func);
			var _program_func = method_get_index(_func);
			var _arguments = arguments;
			with (_program_data) {
				_return = script_execute_ext(_program_func, _arguments);
			}
		}
		else if (is_gmlc_program(_func))
		|| (is_gmlc_method(_func)) {
			_return = method_call(_func, arguments);
		}
		else {
			var _self = method_get_self(_func);
			var _args = arguments;
			with (_prevSelf) {
				_return = method_call(_func, _args);
			}
		}
	}
	else {
		var _args = arguments;
		var _callable = __GMLCcallableFromIndex(rootNode, _func);
		with (global.gmlc_other_instance) with (global.gmlc_self_instance) {
			_return = method_call(_callable, _args);
		}
	}
	
	// Restore scope
	global.gmlc_other_instance = _prevOther;
	global.gmlc_self_instance  = _prevSelf;
	
	if (--recursionCount) {
		var _prev_arg_count = array_pop(argCountMemory)
		var _arg_offset = array_length(backupArguments)-_prev_arg_count
		array_copy(arguments, 0, backupArguments, _arg_offset, _prev_arg_count);
		array_resize(backupArguments, _arg_offset);
	}
	else {
		array_resize(arguments, 0);
		if (array_length(backupArguments)) {
			throw_gmlc_error($"huh... the array sizes aren't correct\narray_length(backupArguments) == {array_length(backupArguments)}")
		}
	}

	return _return;
}
function __GMLCcompileCallMethodExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileCallMethodExpression", "<Missing Error Message>", _node.span);
	_output.target = __GMLCcompileExpression(_rootNode, _parentNode, _node.object);
	_output.key    = _node.member;
	
	_output.recursionCount  = 0;
	_output.prevArgCount    = 0;
	_output.argumentCount   = array_length(_node.args);
	_output.argumentExpressions = array_create(_output.argumentCount);
	_output.arguments       = array_create(_output.argumentCount);
	_output.backupArguments = [];
	_output.argCountMemory  = [];

	var _argArr = _node.args;
	var _i=0; repeat(array_length(_argArr)) {
		_output.argumentExpressions[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _argArr[_i])
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
/// @desc    Returns the parameters of a built-in that take a function or script (GmlSpec types `Function`,
///          `Asset.GMScript`, `Asset.Script`, `Id.Script`), as [index, alsoTakesReal] pairs, or undefined when it has
///          none. Cached per name.
/// @param   {String} _name : Built-in function name
/// @returns {Array<Array>|Undefined}
#endregion
function __GMLCcallbackArgs(_name) {
	static __cache = {};
	if (struct_exists(__cache, _name)) return __cache[$ _name];
	
	var _result = undefined;
	var _entry = __GmlSpec()[$ _name];
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
/// @desc    Checks the function and script arguments of a call to a built-in (see __GMLCcallbackArgs): a plain
///          function number must be one the program's environment exposes. The arguments are passed on unchanged.
/// @param   {Struct} _node : The executing call node
#endregion
function __GMLCcheckCallbackArgs(_node) {
	var _list = _node.callbackArgs;
	var _args = _node.arguments;
	var _i=0; repeat(array_length(_list)) {
		var _index = _list[_i][0];
		if (_index < array_length(_args)) {
			var _value = _args[_index];
			// a negative number where the parameter also takes a Real is a "none" value (-1), not a function
			if (!is_method(_value)) && (is_callable(_value)) && !(_list[_i][1] && is_numeric(_value) && _value < 0) {
				__GMLCcallableFromIndex(_node.rootNode, _value);
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
function __GMLCexecuteCallExpression() {
	//mostly just used in recursion code
	var _arg_count = max(argument_count, argumentCount)
	
	if (recursionCount++) {
        // stash the arguments
        array_copy(backupArguments, array_length(backupArguments), arguments, 0, prevArgCount);
		array_resize(arguments, 0);
		array_resize(arguments, _arg_count);
		array_push(argCountMemory, _arg_count)
    }
	
	//remember how many the function had
	prevArgCount = _arg_count;
	
	//avoids garbage collection lag spikes
	array_resize(arguments, 0);
	
	var _return = undefined;
	// GameMaker evaluates the arguments right to left, then the callee
	var _i=argumentCount-1; repeat(argumentCount) {
		arguments[_i] = argumentExpressions[_i]();
	_i--}
	if (callbackArgs != undefined) __GMLCcheckCallbackArgs(self);

	var _func = callee()
	
	if (!is_method(_func)) {
		if (!is_callable(_func)) {
			throw $"Attempting to call method on a non-callable value :: `{_func}`"
		}
		// a function held as a plain number (a variable set to `get_timer`, as in GameMaker): only an exposed one
		_func = __GMLCcallableFromIndex(rootNode, _func);
	}
	
	if is_gmlc_constructor(_func) {
		//this is just method_call, but it works on constructors
		var _program_data = method_get_self(_func);
		var _program_func = method_get_index(_func);
		var _arguments = arguments
		with (_program_data) {
			_return = script_execute_ext(_program_func, _arguments);
		}
	}
	else if (is_gmlc_program(_func))
	|| (is_gmlc_method(_func)) {
		_return = method_call(_func, arguments);
	}
	else {
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
			
		//why am i doing this?
		with (_prevSelf) {
			_return = method_call(_func, _args);
		}
		
		global.gmlc_other_instance = _prevOther;
		global.gmlc_self_instance  = _prevSelf;
	}
	
	if (--recursionCount) {
        // Un-stash the arguments
		var _prev_arg_count = array_pop(argCountMemory)
		var _arg_offset = array_length(backupArguments)-_prev_arg_count
        array_copy(arguments, 0, backupArguments, _arg_offset, _prev_arg_count);
        array_resize(backupArguments, _arg_offset);
    }
	else {
		array_resize(arguments, 0);
		if (array_length(backupArguments)) {
			throw_gmlc_error($"huh... the array sizes aren't correct\narray_length(backupArguments) == {array_length(backupArguments)}\narray_length(backupArguments) == {array_length(backupArguments)}")
		}
	}
	
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
	&& (_callee.symbol.kind == "BuiltinFunction") {
		var _value = __GMLCidentifierValue(_rootNode, _callee);
		if (!is_method(_value)) && (is_callable(_value)) {
			return method({ value: method(undefined, _value) }, __GMLCexecuteLiteralExpression);
		}
	}
	return __GMLCcompileExpression(_rootNode, _parentNode, _callee);
}
function __GMLCcompileCallExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileCallExpression", "<Missing Error Message>", _node.span);
	_output.callee = __GMLCcompileCallee(_rootNode, _parentNode, _node.callee);
	
	var _isBuiltin = (_node.callee.kind == __GMLC_NodeKind_Identifier) && (_node.callee.symbol.kind == "BuiltinFunction");
	_output.calleeName = (_node.callee.kind == __GMLC_NodeKind_Identifier) ? _node.callee.name : "<Call Expression>"
	_output.callbackArgs = (_isBuiltin) ? __GMLCcallbackArgs(_output.calleeName) : undefined;
	
	_output.recursionCount = 0; 
	_output.prevArgCount = 0;
	_output.argumentCount = array_length(_node.args);
	_output.argumentExpressions = array_create(_output.argumentCount);
	_output.arguments = array_create(_output.argumentCount);
	_output.backupArguments = [];
	_output.argCountMemory = [];

	var _argArr = _node.args
	var _i=0; repeat(array_length(_argArr)) {
		_output.argumentExpressions[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _argArr[_i])
	_i++}
    
    return __vanilla_method(_output, __GMLCexecuteCallExpression);
}

function __GMLCcompileVariableDeclaration(_rootNode, _parentNode, _node) {
	// a `var` declarator: a write to the local
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileVariableDeclaration", "<Missing Error Message>", _node.span);
	_output.key = _node.target.name;
	_output.locals = _parentNode.locals;
	_output.localsWrittenTo = _parentNode.localsWrittenTo;
	_output.localIndex = _parentNode.localLookUps[$ _output.key];
	_output.expression = (_node.init != undefined) ? __GMLCcompileExpression(_rootNode, _parentNode, _node.init) : __vanilla_method({ value: undefined }, __GMLCexecuteLiteralExpression);
	
	return __vanilla_method(_output, __GMLCGetScopeSetter("Local"))
	
}

#endregion

#region Math Expressions

function __GMLCcompileAssignmentExpression(_rootNode, _parentNode, _node) {
	var _target = __GMLCdesugarIndex(_node.target);
	if (_target.kind == __GMLC_NodeKind_Index) {
		var _accessor = _target.accessor;
		var _keys = _target.keys;
		
		if (_node.op == "=") {
			switch (_accessor) {
				case "Array":  return __GMLCcompileArraySet       (_rootNode, _parentNode, _target.object, _keys[0],           _node.value, _node.span);
				case "Grid":   return __GMLCcompileGridSet		  (_rootNode, _parentNode, _target.object, _keys[0], _keys[1], _node.value, _node.span);
				case "List":   return __GMLCcompileListSet		  (_rootNode, _parentNode, _target.object, _keys[0],           _node.value, _node.span);
				case "Map":    return __GMLCcompileMapSet		  (_rootNode, _parentNode, _target.object, _keys[0],           _node.value, _node.span);
				case "Struct": return __GMLCcompileStructSet      (_rootNode, _parentNode, _target.object, _keys[0],           _node.value, _node.span);
				case "Dot":    return __GMLCcompileStructDotAccSet(_rootNode, _parentNode, _target.object, _target.member,     _node.value, _node.span);
			}
		}
		else {
			
			// A dot target or a rooted array path is evaluated once (GameMaker evaluation order, see
			// __GMLCarrayTargetIsRooted); every other accessor is read and then written, evaluating keys and
			// target again for the write.
			var _isDot = (_accessor == "Dot");
			if (_isDot)
			|| ((_accessor == "Array") && __GMLCarrayTargetIsRooted(_target.object)) {
				var _apply = undefined; // ??= is handled by the executor
				switch (_node.op) {
					case "+=": _apply = __GMLCcompoundPlus;       break;
					case "-=": _apply = __GMLCcompoundMinus;      break;
					case "*=": _apply = __GMLCcompoundMultiply;   break;
					case "/=": _apply = __GMLCcompoundDivide;     break;
					case "^=": _apply = __GMLCcompoundBitwiseXOR; break;
					case "&=": _apply = __GMLCcompoundBitwiseAND; break;
					case "|=": _apply = __GMLCcompoundBitwiseOR;  break;
					case "%=": _apply = __GMLCcompoundMod;        break;
				}
				var _once = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Compound", "<Missing Error Message>", _node.span);
				_once.target = __GMLCcompileExpression(_rootNode, _parentNode, _target.object);
				_once.key    = (_isDot) ? _target.member : __GMLCcompileExpression(_rootNode, _parentNode, _keys[0]);
				_once.right  = __GMLCcompileExpression(_rootNode, _parentNode, _node.value);
				_once.apply  = _apply;
				return __vanilla_method(_once, (_isDot) ? __GMLCexecuteCompoundDot : __GMLCexecuteCompoundArrayRooted);
			}
			
			//get the accurate opperator function
			var _func = __GMLCcompoundExecutor(_node.op);
			
			var _getter = undefined;
			var _setter = undefined;
			switch (_accessor) {
				case "Array":  _getter = __GMLCexecuteArrayGet       ; _setter = __GMLCexecuteArraySet       ; break;
				case "Grid":   _getter = __GMLCexecuteGridGet        ; _setter = __GMLCexecuteGridSet        ; break;
				case "List":   _getter = __GMLCexecuteListGet		 ; _setter = __GMLCexecuteListSet		 ; break;
				case "Map":    _getter = __GMLCexecuteMapGet		 ; _setter = __GMLCexecuteMapSet		 ; break;
				case "Struct": _getter = __GMLCexecuteStructGet      ; _setter = __GMLCexecuteStructSet      ; break;
			}
			
			
			//compile the getter
			var _output0 = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Getter", "<Missing Error Message>", _node.span);
			_output0.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target.object);
			_output0.rooted     = false;
			if (_accessor == "Grid") {
				_output0.keyX = __GMLCcompileExpression(_rootNode, _parentNode, _keys[0]);
				_output0.keyY = __GMLCcompileExpression(_rootNode, _parentNode, _keys[1]);
			}
			else {
				_output0.key = __GMLCcompileExpression(_rootNode, _parentNode, _keys[0]);
			}
			var _getter_expression = __vanilla_method(_output0, _getter);
			
			
			
			//compile the additive method
			var _output1 = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Operator", "<Missing Error Message>", _node.span);
			_output1.left  = _getter_expression;
			_output1.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.value);
			var _expression = __vanilla_method(_output1, _func);
			
			
			//compile the actual method we will be calling
			//compile the setter
			var _output2 = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Setter", "<Missing Error Message>", _node.span);
			_output2.target     = __GMLCcompileExpression(_rootNode, _parentNode, _target.object);
			_output2.expression = _expression;
			_output2.rooted     = false;
			if (_accessor == "Grid") {
				_output2.keyX = __GMLCcompileExpression(_rootNode, _parentNode, _keys[0]);
				_output2.keyY = __GMLCcompileExpression(_rootNode, _parentNode, _keys[1]);
			}
			else {
				_output2.key = __GMLCcompileExpression(_rootNode, _parentNode, _keys[0]);
			}
			
			return __vanilla_method(_output2, _setter);
			
		}
	}
	
	if (_target.kind == __GMLC_NodeKind_Identifier) {
		// the resolver refused writes to constants, functions and enums
		var _scope = _target.symbol.kind;
		var _key = __GMLCscopeKey(_rootNode, _target);
		if (_node.op == "=") {
			return __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _key, _node.value, _node.span);
		}
		var _func = __GMLCcompoundExecutor(_node.op);
		
		var _getter = __GMLCGetScopeGetter(_scope);
		var _setter = __GMLCGetScopeSetter(_scope);
		
		//compile the getter
		var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Getter", "<Missing Error Message>", _node.span);
		if (_scope == "BuiltinVar") {
			_output.getter = _key.get;
			var _getter_expression = __vanilla_method(_output, __GMLCexecuteUniqueGet);
		}
		else {
			_output.key = _key; // every scope's getter reads `key` (self, other and static included)
			if (_scope == "Local") {
				_output.locals     = _parentNode.locals;
				_output.localsWrittenTo = _parentNode.localsWrittenTo;
				_output.localIndex = _parentNode.localLookUps[$ _output.key];
			}
			else if (_scope == "Global") {
				_output.globals = _rootNode.globals;
			}
			var _getter_expression = __vanilla_method(_output, _getter);
		}
		
		//compile the additive method
		var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Operator", "<Missing Error Message>", _node.span);
		_output.left  = _getter_expression;
		_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.value);
		var _expression = __vanilla_method(_output, _func);
		
		//compile the actual method we will be calling
		var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Setter", "<Missing Error Message>", _node.span);
		
		if (_scope == "BuiltinVar") {
			_output.setter = _key.set;
			_output.expression = _expression;
			return __vanilla_method(_output, __GMLCexecuteUniqueSet);
		}
		_output.key = _key; // every scope's setter reads `key` (self, other and static included)
		if (_scope == "Local") {
			_output.locals     = _parentNode.locals;
			_output.localsWrittenTo = _parentNode.localsWrittenTo;
			_output.localIndex = _parentNode.localLookUps[$ _output.key];
		}
		else if (_scope == "Global") {
			_output.globals = _rootNode.globals;
		}
		_output.expression = _expression;
		return __vanilla_method(_output, _setter);
	}
	
	__gmlc_internal_error($"the compiler cannot assign to a node of kind {_target.kind}", _node.span)
}
#region jsDoc
/// @func    __GMLCcompoundExecutor(_op)
/// @desc    The executor of the operator of a compound assignment (`+=` is __GMLCexecuteOpPlus, ...).
/// @param   {String} _op : The assignment operator
/// @returns {Function}
#endregion
function __GMLCcompoundExecutor(_op) {
	switch (_op) {
		case "+=":  return __GMLCexecuteOpPlus;
		case "-=":  return __GMLCexecuteOpMinus;
		case "*=":  return __GMLCexecuteOpMultiply;
		case "/=":  return __GMLCexecuteOpDivide;
		case "^=":  return __GMLCexecuteOpBitwiseXOR;
		case "&=":  return __GMLCexecuteOpBitwiseAND;
		case "|=":  return __GMLCexecuteOpBitwiseOR;
		case "%=":  return __GMLCexecuteOpMod;
		case "??=": return __GMLCexecuteOpNullish;
	}
	return undefined;
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

function __GMLCcompileBinaryExpression(_rootNode, _parentNode, _node) {
	var _folded = __GMLCcompileConstantFold(_rootNode, _node);
	if (_folded != undefined) return _folded;
	
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileBinaryExpression", "<Missing Error Message>", _node.span);
	_output.left  = __GMLCcompileExpression(_rootNode, _parentNode, _node.left);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
    
    switch (_node.op) {
		case "==":  return __vanilla_method(_output, __GMLCexecuteOpEqualsEquals     );
		case "!=":  return __vanilla_method(_output, __GMLCexecuteOpNotEquals        );
		case "<":   return __vanilla_method(_output, __GMLCexecuteOpLess             );
		case "<=":  return __vanilla_method(_output, __GMLCexecuteOpLessEquals       );
		case ">":   return __vanilla_method(_output, __GMLCexecuteOpGreater          );
		case ">=":  return __vanilla_method(_output, __GMLCexecuteOpGreaterEquals    );
		case "+":   return __vanilla_method(_output, __GMLCexecuteOpPlus             );
		case "-":   return __vanilla_method(_output, __GMLCexecuteOpMinus            );
		case "*":   return __vanilla_method(_output, __GMLCexecuteOpMultiply         );
		case "/":   return __vanilla_method(_output, __GMLCexecuteOpDivide           );
		case "mod": return __vanilla_method(_output, __GMLCexecuteOpMod              );
		case "div": return __vanilla_method(_output, __GMLCexecuteOpDiv              );
		case "|":   return __vanilla_method(_output, __GMLCexecuteOpBitwiseOR        );
		case "^":   return __vanilla_method(_output, __GMLCexecuteOpBitwiseXOR       );
		case "&":   return __vanilla_method(_output, __GMLCexecuteOpBitwiseAND       );
		case "<<":  return __vanilla_method(_output, __GMLCexecuteOpBitwiseShiftLeft );
		case ">>":  return __vanilla_method(_output, __GMLCexecuteOpBitwiseShiftRight);
	}
}
#region Binary Expressions
#region Equality Ops
function __GMLCexecuteOpEqualsEquals() {
    return left() == right();
}
function __GMLCexecuteOpNotEquals() {
    return left() != right();
}
function __GMLCexecuteOpLess() {
    return left() < right();
}
function __GMLCexecuteOpLessEquals() {
    return left() <= right();
}
function __GMLCexecuteOpGreater() {
    return left() > right();
}
function __GMLCexecuteOpGreaterEquals() {
    return left() >= right();
}
#endregion
#region Basic Ops
function __GMLCexecuteOpPlus() {
	return left() + right();
}
function __GMLCexecuteOpMinus() {
    return left() - right();
}
function __GMLCexecuteOpMultiply() {
	return left() * right();
}
function __GMLCexecuteOpDivide() {
    return left() / right();
}
function __GMLCexecuteOpDiv() {
    return left() div right();
}
function __GMLCexecuteOpMod() {
    return left() mod right();
}
#endregion
#region Bitwise Ops
function __GMLCexecuteOpBitwiseOR() {
    return left() | right();
}
function __GMLCexecuteOpBitwiseAND() {
    return left() & right();
}
function __GMLCexecuteOpBitwiseXOR() {
    return left() ^ right();
}
function __GMLCexecuteOpBitwiseShiftLeft() {
    return left() << right();
}
function __GMLCexecuteOpBitwiseShiftRight() {
    return left() >> right();
}
#endregion
#endregion

#region Constant folding
// GameMaker computes operators whose operands are all constants at compile time, and the folded value can have a
// different type from the same operation at run time (measured on 2024.14.4):
//   - `!`, `&&`, `||`, `^^` fold to a number (`!false` is 1, `true && false` is 0); at run time they give a bool.
//   - arithmetic and bitwise operators fold to an int64 when an operand is a hex or binary literal of 2^31 or more
//     (an int64 to the compiler); otherwise to a number, except that a whole result outside the 32-bit range is an
//     int64. At run time bitwise operators always give an int64 (`5 & 3` folds to the number 1, `a & b` is int64).
//     A shift by 64 or more folds to 0 (`11 << 64` is 0; at run time the count wraps, `a << 64` is 11).
//   - comparisons give a bool either way.
// GMLC folds the same expressions to the same values and types.

#region jsDoc
/// @func    __GMLCconstantValue(_rootNode, _node)
/// @desc    Evaluates an expression whose operands are all constants (literals, built-in constants, enum members), as
///          GameMaker's compiler does.
/// @param   {Struct} _rootNode : The program node (its environment gives the values of built-in constants)
/// @param   {Struct} _node     : AST node
/// @returns {Array} [true, value, int64Typed] when _node is a compile-time constant number or bool, else [false]
#endregion
function __GMLCconstantValue(_rootNode, _node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Identifier: {
			if (_node.symbol == undefined) || (_node.symbol.kind != "BuiltinConstant") return [false];
			var _v = __GMLCidentifierValue(_rootNode, _node);
			if (is_bool(_v)) return [true, _v, false];
			if (is_int64(_v)) return [true, real(_v), false];
			if (is_real(_v) || is_int32(_v)) return [true, real(_v), false];
			return [false];
		}
		case __GMLC_NodeKind_Index: {
			if (_node.accessor != "Dot") || (_node.object.kind != __GMLC_NodeKind_Identifier) || (_node.object.symbol == undefined) || (_node.object.symbol.kind != "Enum") return [false];
			var _v = __GMLCenumValue(_rootNode, _node);
			if (is_real(_v) || is_int64(_v) || is_int32(_v)) return [true, real(_v), false];
			return [false];
		}
		case __GMLC_NodeKind_Literal: {
			var _v = _node.value;
			if (is_bool(_v)) return [true, _v, false];
			if (is_int64(_v)) {
				// a decimal literal of 2^31 or more is a double to the compiler; hex and binary ones are int64
				var _raw = string_lower(_node.lexeme ?? "");
				var _typed = string_starts_with(_raw, "$") || string_starts_with(_raw, "0x") || string_starts_with(_raw, "0b");
				return [true, _typed ? _v : real(_v), _typed];
			}
			if (is_real(_v) || is_int32(_v)) return [true, real(_v), false];
			return [false];
		}
		case __GMLC_NodeKind_Unary: {
			var _e = __GMLCconstantValue(_rootNode, _node[$ "argument"]);
			if (!_e[0]) return [false];
			try {
				switch (_node.op) {
					case "!": return [true, real(!_e[1]), false];
					case "-": return [true, -_e[1], _e[2]];
					case "~": return [true, _e[2] ? ~_e[1] : real(~_e[1]), _e[2]];
				}
			}
			catch (_err) {}
			return [false];
		}
		case __GMLC_NodeKind_Logical:
		case __GMLC_NodeKind_Binary: {
			var _l = __GMLCconstantValue(_rootNode, _node.left);
			if (!_l[0]) return [false];
			var _r = __GMLCconstantValue(_rootNode, _node.right);
			if (!_r[0]) return [false];
			var _a = _l[1];
			var _b = _r[1];
			var _typed = _l[2] || _r[2];
			if (_typed) {
				_a = int64(_a);
				_b = int64(_b);
			}
			try {
				var _v;
				switch (_node.op) {
					case "&&":  return [true, real(_a && _b), false];
					case "||":  return [true, real(_a || _b), false];
					case "^^":  return [true, real(_a ^^ _b), false];
					case "==":  return [true, _a == _b, false];
					case "!=":  return [true, _a != _b, false];
					case "<":   return [true, _a < _b, false];
					case "<=":  return [true, _a <= _b, false];
					case ">":   return [true, _a > _b, false];
					case ">=":  return [true, _a >= _b, false];
					case "+":   _v = _a + _b; break;
					case "-":   _v = _a - _b; break;
					case "*":   _v = _a * _b; break;
					case "/":   if (_b == 0) return [false]; _v = _a / _b; break;
					case "div": if (_b == 0) return [false]; _v = _a div _b; break;
					case "mod":
					case "%":   if (_b == 0) return [false]; _v = _a mod _b; break;
					case "&":   _v = _a & _b; break;
					case "|":   _v = _a | _b; break;
					case "^":   _v = _a ^ _b; break;
					// the compiler gives 0 for a shift by 64 or more (at run time the count wraps modulo 64)
					case "<<":  _v = (_b >= 64) ? 0 : _a << _b; break;
					case ">>":  _v = (_b >= 64) ? 0 : _a >> _b; break;
					default: return [false];
				}
				return _typed ? [true, int64(_v), true] : [true, real(_v), false];
			}
			catch (_err) {}
			return [false];
		}
	}
	return [false];
}
#region jsDoc
/// @func    __GMLCconstantEmit(_c)
/// @desc    Returns the value GameMaker emits for a folded constant: int64-typed values stay int64, a whole double
///          outside the 32-bit range becomes an int64, bools stay bools, everything else is a real.
/// @param   {Array} _c : A result of __GMLCconstantValue
/// @returns {Any}
#endregion
function __GMLCconstantEmit(_c) {
	var _v = _c[1];
	if (is_bool(_v)) return _v;
	if (_c[2]) return int64(_v);
	if (!is_nan(_v)) && (!is_infinity(_v)) && (frac(_v) == 0) && ((_v > 2147483647) || (_v < -2147483648)) return int64(_v);
	return real(_v);
}
#region jsDoc
/// @func    __GMLCcompileConstantFold(_rootNode, _node)
/// @desc    Compiles an operator whose operands are all constants into its folded value.
/// @param   {Struct} _rootNode : The program node
/// @param   {Struct} _node     : AST node of the operator
/// @returns {Function|Undefined} the compiled literal, or undefined when _node does not fold
#endregion
function __GMLCcompileConstantFold(_rootNode, _node) {
	var _c = __GMLCconstantValue(_rootNode, _node);
	if (!_c[0]) return undefined;
	return method({ value: __GMLCconstantEmit(_c) }, __GMLCexecuteLiteralExpression);
}
#endregion

function __GMLCcompileLogicalExpression(_rootNode, _parentNode, _node) {
	var _folded = __GMLCcompileConstantFold(_rootNode, _node);
	if (_folded != undefined) return _folded;
	
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
function __GMLCexecuteOpAND() {
    return left() && right();
}
function __GMLCexecuteOpOR() {
    return left() || right();
}
function __GMLCexecuteOpXOR() {
    return left() ^^ right();
}
#endregion

function __GMLCcompileNullishExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileNullishExpression", "<Missing Error Message>", _node.span);
	_output.left  = __GMLCcompileExpression(_rootNode, _parentNode, _node.left);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
    
    
    return __vanilla_method(_output, __GMLCexecuteOpNullish);
}
#region Nullish Expressions
function __GMLCexecuteOpNullish() {
    return left() ?? right();
}
#endregion

function __GMLCcompileUnaryExpression(_rootNode, _parentNode, _node) {
	if (_node.op == "!") || (_node.op == "~") || (_node.op == "-") {
		var _folded = __GMLCcompileConstantFold(_rootNode, _node);
		if (_folded != undefined) return _folded;
	}
	
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
function __GMLCexecuteOpNot() {
    return !right();
}
function __GMLCexecuteOpNegate() {
    return -right();
}
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
function __GMLCcompileTernaryExpression(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileTernaryExpression", "<Missing Error Message>", _node.span);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.test);
	_output.left = __GMLCcompileExpression(_rootNode, _parentNode, _node.consequent);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.alternate);
    
    
    return __vanilla_method(_output, __GMLCexecuteTernaryExpression);
}

function __GMLCcompileUpdateExpression(_rootNode, _parentNode, _node) {
	var _argument = __GMLCdesugarIndex(_node[$ "argument"]);
	if (_argument.kind == __GMLC_NodeKind_Identifier) {
		
		var _key = __GMLCscopeKey(_rootNode, _argument);
		var _increment = (_node.op == "++") ? true : false;
		var _prefix = _node.prefix;
		
		return __GMLCcompileUpdateVariable(_rootNode, _parentNode, _argument.symbol.kind, _key, _increment, _prefix, _node.span)
	}
	else if (_argument.kind == __GMLC_NodeKind_Index) {
		
		var _update = new ASTUpdate(_node.span, _node.op, _node.prefix, _argument);
		switch (_argument.accessor) {
			case "Array":  return __GMLCcompileUpdateArray  (_rootNode, _parentNode, _update);
			case "Grid":   return __GMLCcompileUpdateGrid   (_rootNode, _parentNode, _update);
			case "List":   return __GMLCcompileUpdateList   (_rootNode, _parentNode, _update);
			case "Map":    return __GMLCcompileUpdateMap    (_rootNode, _parentNode, _update);
			case "Struct": return __GMLCcompileUpdateStruct (_rootNode, _parentNode, _update);
			case "Dot":    return __GMLCcompileUpdateStructDotAcc(_rootNode, _parentNode, _update);
		}
		
	}
	
	__gmlc_internal_error("malformed assignment", _node.span)
}

#endregion

#region Identifiers

#region Targeters / Getter / Setters

//these are used when the target is an expected result, self, other, global, static, var, or a known unique variabke like `room` or `fps`
// the scope is the symbol kind of the name: "Global", "Local", "Static", "Self" or "BuiltinVar" (a variable the
// environment exposes, read and written through its get and set functions)
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

#region Generic Getter    -    (These will use expressions instead of literal keys written to the method, for those see fast pass script)
function __GMLCcompilePropertyGet(_rootNode, _parentNode, _scope, _leftKey, _span){
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompilePropertyGet", "<Missing Error Message>", _span);	
	_output.key      = _leftKey;
	if (_scope == "Local") {
		_output.locals = _parentNode.locals;
		_output.localsWrittenTo = _parentNode.localsWrittenTo;
		_output.localIndex = _parentNode.localLookUps[$ _output.key];
	}
	else if (_scope == "Global") {
		_output.globals = _rootNode.globals;
	}
	return __vanilla_method(_output, __GMLCGetScopeGetter(_scope))
}
#endregion

#region Generic Setter    -    (These will use expressions instead of literal keys written to the method, for those see fast pass script)
function __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _key, _rightExpression, _span){
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompilePropertySet", "<Missing Error Message>", _span);
	_output.key = _key;
	if (_scope == "Local") {
		_output.locals = _parentNode.locals;
		_output.localsWrittenTo = _parentNode.localsWrittenTo;
		_output.localIndex = _parentNode.localLookUps[$ _output.key];
	}
	else if (_scope == "Global") {
		_output.globals = _rootNode.globals;
	}
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _rightExpression);
	
	return __vanilla_method(_output, __GMLCGetScopeSetter(_scope))
}
#endregion

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
			// `E.M` of an enum the environment exposes is the member's value
			if (_node.object.kind == __GMLC_NodeKind_Identifier) && (_node.object.symbol != undefined) && (_node.object.symbol.kind == "Enum") {
				return __vanilla_method({ value: __GMLCenumValue(_rootNode, _node) }, __GMLCexecuteLiteralExpression);
			}
			return __GMLCcompileStructDotAccGet(_rootNode, _parentNode, _node.object, _node.member, _node.span)
		}
		default: __gmlc_internal_error($"the compiler has no case for accessor {_node.accessor}", _node.span);
	}
}

function __GMLCcompileIdentifier(_rootNode, _parentNode, _node) {
	var _scope = _node.symbol.kind;
	switch (_scope) {
		case "BuiltinConstant":
		case "BuiltinFunction": {
			// the value, as GameMaker has it (a built-in function read as a value is a plain number)
			return __vanilla_method({ value: __GMLCidentifierValue(_rootNode, _node) }, __GMLCexecuteLiteralExpression);
		}
		case "BuiltinVar": {
			var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUniqueIdentifier", "<Missing Error Message>", _node.span);
			_output.getter = __GMLCscopeKey(_rootNode, _node).get;
			return __vanilla_method(_output, __GMLCexecuteUniqueGet);
		}
		case "Enum": {
			__gmlc_internal_error($"the enum {_node.name} reached the compiler as a value", _node.span);
		}
	}
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileIdentifier", "<Missing Error Message>", _node.span);
	_output.key = _node.name;
	if (_scope == "Local") {
		_output.locals = _parentNode.locals;
		_output.localsWrittenTo = _parentNode.localsWrittenTo;
		_output.localIndex = _parentNode.localLookUps[$ _output.key];
	}
	else if (_scope == "Global") {
		_output.globals = _rootNode.globals;
	}
	return __vanilla_method(_output, __GMLCGetScopeGetter(_scope))
}

// Used for both `=` and compound ops on a variable the environment exposes.
// setter: the user-registered set closure (takes one GML argument)
// expression: compiled expression that produces the value to write
function __GMLCexecuteUniqueGet() {
	return getter();
}
function __GMLCexecuteUniqueSet() {
	var _val = expression()
	setter(_val);
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
/// @desc    The value of a built-in constant or function name, as the environment exposes it (a function read as a value
///          is its plain number), or of one of GMLC's own helpers.
/// @param   {Struct} _rootNode   : The program node
/// @param   {Struct} _identifier : An Identifier
/// @returns {Any}
#endregion
function __GMLCidentifierValue(_rootNode, _identifier) {
	// a function a language extension's rewrite calls is GMLC's own, whatever the environment exposes
	var _origin = _identifier.origin;
	if (_origin != undefined) && (_origin.kind == "extension") {
		var _own = __GMLC_InternalFunctions()[$ _identifier.name];
		if (_own != undefined) return _own;
	}
	var _env = _rootNode.env;
	var _data = (_identifier.symbol.kind == "BuiltinConstant") ? _env.getConstant(_identifier.name) : _env.getFunction(_identifier.name);
	if (_data == undefined) {
		return __GMLC_InternalFunctions()[$ _identifier.name];
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
//    selfKeys: array<string>, the keys whose whole value is `self`, which GameMaker sets to the new struct
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
	var _k = 0; repeat (array_length(selfKeys)) {
		_struct[$ selfKeys[_k]] = _struct;
	_k++}
	
	//set the statics so they are unique
	static_set(_struct, {});
	
	return _struct;
}
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
	var _k = 0; repeat (array_length(selfKeys)) {
		_struct[$ selfKeys[_k]] = _struct;
	_k++}
	
	//set the statics so they are unique
	static_set(_struct, {});
	
	return _struct;
}
function __GMLCcompileStructLiteral(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileStructLiteral", "<Missing Error Message>", _node.span);
	_output.size = array_length(_node.entries);
	_output.keys = array_create(_output.size);
	_output.values = array_create(_output.size);
	_output.bound = [];
	_output.selfKeys = [];
	var _seen = {};
	var _repeated = false;
	// function expressions in the values are bound to `self`; a function literal that is a value itself is bound to
	// the new struct, as GameMaker does
	array_push(_rootNode.scopeStack, "Self");
	var _i = 0; repeat (_output.size) {
		var _entry = _node.entries[_i];
		_output.keys[_i] = _entry.key;
		if (__gmlc_struct_has(_seen, _entry.key)) {
			_repeated = true;
			// a later value of the key replaces an earlier `self`
			var _at = array_get_index(_output.selfKeys, _entry.key);
			if (_at >= 0) array_delete(_output.selfKeys, _at, 1);
		}
		_seen[$ _entry.key] = true;
		if (_entry.value.kind == __GMLC_NodeKind_FunctionExpr) {
			_output.values[_i] = __vanilla_method({ value: __GMLCcompileFunctionValue(_rootNode, _entry.value) }, __GMLCexecuteLiteralExpression);
			array_push(_output.bound, _entry.key);
		}
		else if (_entry.value.kind == __GMLC_NodeKind_Identifier) && (_entry.value.name == "self") {
			// `{ me: self }` stores the new struct in GameMaker, though `self` anywhere else in the value (`self.x`,
			// `[self]`, `f(self)`) is the creator (measured)
			_output.values[_i] = __vanilla_method({ value: undefined }, __GMLCexecuteLiteralExpression);
			array_push(_output.selfKeys, _entry.key);
		}
		else {
			_output.values[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _entry.value);
		}
	_i++}
	array_pop(_rootNode.scopeStack);
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

#region Util
function __GMLC_Function(_rootNode, _parentNode, _base, _error, _span) constructor {
	self[$ "__@@is_gmlc_program@@__"] = true;
	
	compilerBase = _base;
	errorMessage = _error;
	span = _span; // where the node is: errors at run time turn it into a file, line and line text
	
	
	rootNode = _rootNode;
	parentNode = _parentNode;
	
	// where the compiler was when it made this node, only when debugging GMLC itself (the Debug configuration)
	callstack = GMLC_DEBUG_CALLSTACK ? debug_get_callstack() : undefined;
}
static_get(__GMLC_Function)[$ "__@@is_gmlc_program@@__"] = true;

function __GMLC_Statics(_program_name) constructor {
	self[$ "__@@gmlc_script_name@@__"] = _program_name;
}
function __GMLC_Constructor_Statics(_construct_name) : __GMLC_Statics(_construct_name) constructor {
	self[$ "__@@is_gmlc_constructed@@__"] = true;
}

#endregion


#endregion
