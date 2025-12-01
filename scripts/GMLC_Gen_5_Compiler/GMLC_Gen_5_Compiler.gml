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
	function GMLC_Gen_5_Compiler(_env) constructor  {
		env = _env;
		
		//init variables:
		
		ast     = undefined;
		globals = undefined;
		
		static initialize = function(_ast, _globalsStruct={}) {
			ast = _ast;
			globals = _globalsStruct;
		}
		
		static cleanup = function() {
		
		}
		
		static parseAll = function() {
			return __GMLCcompileProgram(ast, globals);
		}
		
		static nextNode = function() {
			//This is intended to one day allow for async compiling but until that day this is a place holder.
		};
		
	}
#endregion

// Private //////////////////////////

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
											parentConstructorCall(arguments)\
										}

#endregion

#region Statics
#macro __GMLC_INIT_STATICS	if (struct_exists(self, "staticsExecuted") && !staticsExecuted) {\
								staticsExecuted = true;\
								staticsBlock();\
							}

#endregion

#macro __GMLC_PRE_FUNC	__GMLC_DEFAULT_SELF_AND_OTHER\
						__GMLC_INIT_ARGUMENT_COUNT\
						if (recursionCount++) {\
						    __GMLC_STASH_LOCALS\
							__GMLC_STASH_ARGUMENTS\
						}\
						__GMLC_POPULATE_ARGUMENTS\
						__GMLC_INIT_STATICS
						

#macro __GMLC_POST_FUNC	returnValue = undefined;\
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
//global.callStack = [];

///////////////////////////////////////////////////////////////////////////////////////////////

function executeProgram(_program) {
	//this function should never be called inside a prgroam, for that use `__executeProgram`
	global.gmlc_self_instance = self;
    global.gmlc_other_instance = other;
    
	return _program();
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
function __GMLCcompileProgram(_node, _globalsStruct) {
	var _output = new __GMLC_Function(undefined, undefined, "__GMLCcompileProgram", "<Missing Error Message>", _node.line, _node.lineString);
	_output.rootNode = _output;
	_output.globals = _globalsStruct; // these are optional inputs for future use with compiling a full project folder.
	_output.program = __GMLCcompileFunction(_output, _output, _node);
	
	//this assists with converting locals from struct accessors to an array write
	_output.localLookUps = {};
	var _i=0; repeat(array_length(_node.LocalVarNames)) {
		_output.localLookUps[$ _node.LocalVarNames[_i]] = _i;
	_i++}
	_output.localCount = _i;
	_output.locals = array_create(_i, undefined);
	_output.localsWrittenTo = array_create(_i, false); //remember if we ever wrote to those locals, this is used to throw errors incase we are reading from an unwritten local
	_output.backupLocals = [];//if the function is recursive stash the locals back into this array, to<->from
	_output.backupLocalsWrittenTo = [];//if the function is recursive stash the locals back into this array, to<->from
	
	_output.recursionCount = 0;
	_output.prevArgCount = 0;
	_output.argumentCount = 0;
	_output.arguments = [];
	_output.backupArguments = [];
	_output.argCountMemory = [];
	
	//compile all of the global variable functions
	var _names = struct_get_names(_node.GlobalVar)
	var _i=0; repeat(array_length(_names)) {
		var _name = _names[_i];
		var _sub_node = _node.GlobalVar[$ _name];
		
		if (_sub_node.type == __GMLC_NodeType.FunctionDeclaration) {
			_output.globals[$ _name] = __GMLCcompileFunction(_output, undefined, _sub_node);
		}
		else if (_sub_node.type == __GMLC_NodeType.ConstructorDeclaration) {
			_output.globals[$ _name] = __GMLCcompileConstructor(_output, undefined, _sub_node);
		}
		
	_i++}
	
	return __vanilla_method(_output, __GMLCexecuteProgram)
}

function __GMLCexecuteExpression() {};
function __GMLCcompileExpression(_rootNode, _parentNode, _node) {
	if (_parentNode=undefined && _node==undefined) {
		throw_gmlc_error("Red forgot to add the `rootNode` and `parentNode` when calling `__GMLCcompileExpression`!")
	}
	if (!is_instanceof(_node, ASTNode)) {
		throw_gmlc_error($"Supplied Node is not a valid AST - Red's fault\ninstanceof(_node) == {instanceof(_node)}")
	}
	
	//check every different ast node, and see how it should be compiled,
    // this is essentially our lookup table for that
	
	switch (_node.type) {
		case __GMLC_NodeType.FunctionDeclaration:{
			return __GMLCcompileFunction(_rootNode, undefined, _node);
		break;}
		case __GMLC_NodeType.ConstructorDeclaration:{
			return __GMLCcompileConstructor(_rootNode, undefined, _node);
		break;}
		case __GMLC_NodeType.ArgumentList:{
			throw_gmlc_error("not done yet")
		break;}
		case __GMLC_NodeType.Argument:{
			throw_gmlc_error("not done yet")
		break;}
		
		case __GMLC_NodeType.BlockStatement:{
			return __GMLCcompileBlockStatement(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeType.IfStatement:{
			return __GMLCcompileIf(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeType.ForStatement:{
			return __GMLCcompileFor(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeType.WhileStatement:{
			return __GMLCcompileWhile(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeType.RepeatStatement:{
			return __GMLCcompileRepeat(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeType.DoUntilStatement:{
			return __GMLCcompileDoUntil(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeType.WithStatement:{
			return __GMLCcompileWith(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeType.TryStatement:{
			return __GMLCcompileTryCatchFinally(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeType.SwitchStatement:{
			return __GMLCcompileSwitch(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeType.CaseExpression:
		case __GMLC_NodeType.CaseDefault:{
			return __GMLCcompileCase(_rootNode, _parentNode, _node)
		break;}
		
		case __GMLC_NodeType.BreakStatement:{
			return __GMLCcompileBreak(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeType.ContinueStatement:{
			return __GMLCcompileContinue(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeType.ExitStatement:{
			return __GMLCcompileExit(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeType.ReturnStatement:{
			return __GMLCcompileReturn(_rootNode, _parentNode, _node)
		break;}
		
		case __GMLC_NodeType.VariableDeclarationList:{
			return __GMLCcompileVariableDeclarationList(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeType.VariableDeclaration:{
			return __GMLCcompileVariableDeclaration(_rootNode, _parentNode, _node);
		break;}
		
		case __GMLC_NodeType.CallExpression:{
			return __GMLCcompileCallExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeType.NewExpression:{
			return __GMLCcompileNewExpression(_rootNode, _parentNode, _node)
		break;}
		
		case __GMLC_NodeType.ExpressionStatement:{
			//NOTE: Logging this incase we are generating unneeded AST nodes.
			throw_gmlc_error("There shouldnt be any of these")
			return __GMLCcompileExpression(_rootNode, _parentNode, _node.expr);
		break;}
		case __GMLC_NodeType.AssignmentExpression:{
			return __GMLCcompileAssignmentExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeType.BinaryExpression:{
			return __GMLCcompileBinaryExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeType.LogicalExpression:{
			return __GMLCcompileLogicalExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeType.NullishExpression:{
			return __GMLCcompileNullishExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeType.UnaryExpression:{
			return __GMLCcompileUnaryExpression(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeType.UpdateExpression:{
			return __GMLCcompileUpdateExpression(_rootNode, _parentNode, _node)
		break;}
				
		case __GMLC_NodeType.ConditionalExpression:{
			return __GMLCcompileTernaryExpression(_rootNode, _parentNode, _node);
		break;}
		
		case __GMLC_NodeType.Literal:{
			return __GMLCcompileLiteralExpression(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeType.Identifier:{
			return __GMLCcompileIdentifier(_rootNode, _parentNode, _node)
		break;}
				
		case __GMLC_NodeType.UniqueIdentifier:{
			//we should only ever make it here if we are `getting` the unique identifier.
			return __GMLCcompileUniqueIdentifier(_rootNode, _parentNode, _node)
		break;}
				
		case __GMLC_NodeType.AccessorExpression:{
			return __GMLCcompileAccessor(_rootNode, _parentNode, _node)
		break;}
		
		case __GMLC_NodeType.EmptyNode:{
			//return a completely empty function, ideally we would not even enter a function but thats for a future task for the optimizer and fast passes to deal with.
			return function(){};
		}
		
		/*
		case __GMLC_NodeType.PropertyAccessor:{
			throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
		break;}
		case __GMLC_NodeType.AccessorExpression:{
			throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
		break;}
		case __GMLC_NodeType.MethodVariableConstructor:{
			throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
		break;}
		case __GMLC_NodeType.MethodVariableFunction:{
			throw_gmlc_error($"{currentNode.type} :: Not implimented yet")
		break;}
		//*/
		default:
			
			trace(json_stringify(_node, true))
			throw_gmlc_error($"Current Node does not have a valid type for the optimizer,\ntype: {_node.type}\ncurrentNode: {json_stringify(_node, true)}")
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
	var _output = new __GMLC_Function(_rootNode, undefined, "__GMLCcompileFunction", "<Missing Error Message>", _node.line, _node.lineString);
	_output[$ "__@@is_gmlc_function@@__"] = true;
	
	_output.parentNode = _output;
	
	//statics
	_output.staticsExecuted = false;
	_output.statics = new __GMLC_Statics(_node[$ "name"]);
	_output.staticsBlock = (struct_exists(_node, "StaticVarArray")) ? __GMLCcompileBlockStatement(_rootNode, _output, new ASTBlockStatement(_node.StaticVarArray, undefined, undefined)) : function(){};
	static_set(_output, _output.statics)
	
	_output.recursionCount = 0; 
	
	//this assists with converting locals from struct accessors to an array write
	_output.localLookUps = {};
	var _i=0; repeat(array_length(_node.LocalVarNames)) {
		_output.localLookUps[$ _node.LocalVarNames[_i]] = _i;
	_i++}
	_output.localCount = _i;
	_output.locals = array_create(_i, undefined);
	_output.localsWrittenTo = array_create(_i, false); //remember if we ever wrote to those locals, this is used to throw errors incase we are reading from an unwritten local
	_output.backupLocals = [];//if the function is recursive stash the locals back into this array, to<->from
	_output.backupLocalsWrittenTo = [];//if the function is recursive stash the locals back into this array, to<->from
	
	_output.argumentsDefault = __GMLCcompileArgumentList(_rootNode, _output, _node.arguments);
	_output.argumentCount = array_length(_node.arguments.statements);
	_output.prevArgCount = 0;
	_output.arguments = [];
	_output.backupArguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argCountMemory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	_output.program = __GMLCcompileBlockStatement(_rootNode, _output, _node.statements);
		
	_output.returnValue = undefined;
	_output.flowMask = FLOW_MASK.EMPTY;
	
	
	return __vanilla_method(_output, __GMLCexecuteFunction)
}

function __GMLCexecuteConstructor() constructor {
	//check to see if this is a `new` expression, or some `script_execute` equivalent using `method_call`
	var _self_is_gmlc  = self[$ "__@@is_gmlc_function@@__"];
	var _is_new_expression = !_self_is_gmlc;
	
	var dcs = debug_get_callstack()
	
	var _program_data = (_is_new_expression) ? other : self;
	with _program_data {
		var _program = program;
		var _arguments = arguments;
		var _statics = statics;
		
		__GMLC_DEFAULT_SELF_AND_OTHER
		
		if (_is_new_expression) {
			__GMLC_UPDATE_SELF_AND_OTHER
		}
		
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
	var _output = new __GMLC_Function(_rootNode, undefined, "__GMLCcompileConstructor", "<Missing Error Message>", _node.line, _node.lineString);
	_output[$ "__@@is_gmlc_function@@__"] = true;
	
	_output.parentNode = _output;
	
	//parent constructor
	_output.hasParentConstructor = false;
	_output.parentConstructorName = undefined;
	_output.parentConstructorCall = undefined;
	
	//statics
	_output.staticsExecuted = false;
	_output.statics = new __GMLC_Constructor_Statics(_node.name);
	_output.staticsBlock = (struct_exists(_node, "StaticVarArray")) ? __GMLCcompileBlockStatement(_rootNode, _output, new ASTBlockStatement(_node.StaticVarArray, undefined, undefined)) : function(){};
	static_set(_output, _output.statics)
	
	_output.recursionCount = 0; 
	
	//locals
	_output.localLookUps = {};
	var _i=0; repeat(array_length(_node.LocalVarNames)){
		_output.localLookUps[$ _node.LocalVarNames[_i]] = _i;
	_i++}
	_output.localCount = _i;
	_output.locals = array_create(_i, undefined);
	_output.localsWrittenTo = array_create(_i, false); //remember if we ever wrote to those locals, this is used to throw errors incase we are reading from an unwritten local
	_output.backupLocals = [];//if the function is recursive stash the locals back into this array, to<->from
	_output.backupLocalsWrittenTo = [];//if the function is recursive stash the locals back into this array, to<->from
	
	//arguments
	_output.argumentsDefault = __GMLCcompileArgumentList(_rootNode, _output, _node.arguments);
	_output.argumentCount = method_get_self(_output.argumentsDefault).size;
	_output.prevArgCount = 0;
	_output.arguments = [];
	_output.backupArguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argCountMemory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	_output.program = __GMLCcompileBlockStatement(_rootNode, _output, _node.statements);
	
	_output.returnValue = undefined;
	_output.flowMask = FLOW_MASK.EMPTY;
	
	if (_node.parentCall != undefined) {
		_output.hasParentConstructor = true;
		_output.parentConstructorName = _node.parentName;
		_output.parentConstructorCall = __GMLCcompileCallExpression(_rootNode, _output, _node.parentCall);
		
		//there is probably a better way to check if what we have is indeed a gmlc program or a real script
		var _parent_constuct = _rootNode.globals[$ _node.parentName]
		if (is_gmlc_program(_parent_constuct)) {
			var _our_static = _output.statics
			var _parent_static = method_get_self(_parent_constuct).statics
			static_set(_our_static, _parent_static)
		}
		else if (_parent_constuct != undefined) {
			static_set(_output.statics, static_get(_node.parentCall.callee.value))
		}
		else {
			//the parent is a gmlc program which has yet to be compiled. statics will be set when parent is compiled
		}
		
		
		//_output.parentConstructor = rootNode.globals[$ parentName];
	}
	else {
		//no parent? just have an empty static
		static_set(_output.statics, static_get({}))
	}
	
	//after initializing we need to check all constructors in the global space
	// and if their callee is our global reference we need to update their statics,
	// this ensures we're able to compile a child then a parent regardless of order.
	var _globals = _rootNode.globals;
	var _names = struct_get_names(_rootNode.globals);
	var _i=0; repeat(array_length(_names)) {
		var _global = _globals[$ _names[_i]];
		
		if (is_gmlc_constructor(_global)) {
			var _data = method_get_self(_global);
			if (_data != undefined) {
				if (_data.parentConstructorName == _node.name) {
					static_set(static_get(_data), _output.statics)
				}
			}
		}
	_i++};
	
	return __vanilla_method(_output, __GMLCexecuteConstructor)
}

function __GMLCexecuteArgumentList() {
	var _inputArguments = parentNode.arguments
	var _inputLength = array_length(_inputArguments);
	
	var _i=0; repeat(size) {
		var _arg = statements[_i]
		if (_arg.index != _i) throw_gmlc_error("Why does our index not match our arguments index?"+$"\n(line {line}) -\t{lineString}")
		
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
function __GMLCcompileArgumentList(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileArgumentList", "<Missing Error Message>", _node.line, _node.lineString);
	_output.statements = [];
	_output.size = undefined;
	
	//_output.varStatics = {};
	//_output.locals = {};
	
	
	var _arr = _node.statements;
	var _i=0; repeat(array_length(_arr)) {
		_output.statements[_i] = __GMLCcompileArgument(_rootNode, _parentNode, _arr[_i]);
	_i++}
	
	_output.size = array_length(_output.statements);
	
	return __vanilla_method(_output, __GMLCexecuteArgumentList)
}

function __GMLCexecuteArgument() {
	throw_gmlc_error("ERROR :: __GMLCexecuteArgument should never actually be run, this should be handled by ArgumentList")
}
function __GMLCcompileArgument(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileArgument", "<Missing Error Message>", _node.line, _node.lineString);
	_output.index = _node.argument_index;
	_output.localIndex = _parentNode.localLookUps[$ _node.identifier];
	_output.identifier = _node.identifier;
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr)
	
	return _output;
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
    if (_node.type == __GMLC_NodeType.EmptyNode) {
		return function(){};
	}
	
	// If the node is not a block, simply compile it as an expression.
    if (_node.type != __GMLC_NodeType.BlockStatement) {
        return __GMLCcompileExpression(_rootNode, _parentNode, _node);
    }
    
    // First, compile all children into a temporary output.
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileBlockStatement", "<Missing Error Message>", _node.line, _node.lineString);
    _output.blockStatements = [];
    var _statements = _node.statements;
    
	var _i = 0; repeat(array_length(_statements)) {
		var _statement = _statements[_i];
		if (_statement.type == __GMLC_NodeType.EmptyNode) {
			//dont compile and continue on
		}
        
		if (_statement.type == __GMLC_NodeType.BlockStatement) {
			//compile but take out the statements and inject them in this one.
			var _compiled_child_block = __GMLCcompileBlockStatement(_rootNode, _parentNode, _statement);
			var _child_block = method_get_self(_compiled_child_block)
			_output.blockStatements = array_concat(_output.blockStatements, _child_block.blockStatements)
		}
        
		var _expr = __GMLCcompileExpression(_rootNode, _parentNode, _statement);
        if (_expr != undefined) {
            var _exprStruct = method_get_self(_expr);
            array_push(_output.blockStatements, _expr);
        }
    _i++}
    
    _output.size = array_length(_output.blockStatements);
    
    // If there’s only one statement, return that single statement.
    if (_output.size == 0) {
        return function(){};
    }
    
	if (_output.size == 1) {
        return _output.blockStatements[0];
    }
    
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
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileIf", "<Missing Error Message>", _node.line, _node.lineString);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.trueBlock = __GMLCcompileExpression(_rootNode, _parentNode, _node.consequent);
    
	//if it's an empty `else` block statement
	if (_node.alternate != undefined)
	&& (_node.alternate.type == __GMLC_NodeType.BlockStatement)
	&& (array_length(_node.alternate.statements) == 0) {
		_node.alternate = undefined;
	}
	
	//if there is no 'else'
	if (_node.alternate == undefined) {
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileRepeat", "<Missing Error Message>", _node.line, _node.lineString);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.blockStatement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.codeBlock);
    
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileWhile", "<Missing Error Message>", _node.line, _node.lineString);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.blockStatement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.codeBlock);
    
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileDoUntil", "<Missing Error Message>", _node.line, _node.lineString);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.blockStatement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.codeBlock);
    
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileFor", "<Missing Error Message>", _node.line, _node.lineString);
	_output.assignment     = (_node.initialization == undefined) ? function(){}            : __GMLCcompileExpression(_rootNode, _parentNode, _node.initialization);
	_output.condition      = (_node.condition      == undefined) ? function(){return true} : __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.operation      = (_node.increment      == undefined) ? function(){}            : __GMLCcompileExpression(_rootNode, _parentNode, _node.increment);
	_output.blockStatement = (_node.codeBlock      == undefined) ? function(){}            : __GMLCcompileExpression(_rootNode, _parentNode, _node.codeBlock);
    
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
    var _passing = false;
    
    var _i=0; repeat(size) {
		var _case = cases[_i];
		if (_passing)
		|| (_case.expression() == _value) {
		    _passing = true
		    _case.blockStatement()
		    if (parentNode.flowMask) {
				if (parentNode.flowMask & FLOW_MASK.RETURN) return undefined;
				if (parentNode.flowMask & FLOW_MASK.BREAK) break;
			}
		}
    _i++}
	
	if (!(parentNode.flowMask & FLOW_MASK.BREAK))
	&& (caseDefault != undefined) {
		caseDefault.blockStatement()
	}
	
	parentNode.flowMask &= ~FLOW_MASK.BREAK;
}
function __GMLCcompileSwitch(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileSwitch", "<Missing Error Message>", _node.line, _node.lineString);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.switchExpression);
	_output.cases = [];
	_output.caseDefault = undefined;
	_output.size = 0;
    
    
    var _i=0; repeat(array_length(_node.cases)) {
		var _case = _node.cases[_i];
		var _struct = __GMLCcompileCase(_rootNode, _parentNode, _case);
		
		//set the case as default or push to cases
		if (_struct.isDefault) _output.caseDefault = _struct;
		else _output.cases[_i] = _struct;
		
    _i++}
    
    _output.size = array_length(_output.cases);
    
    return __vanilla_method(_output, __GMLCexecuteSwitch);
}
#region //{
// used for gmlc compiled switch/case statements
//    expression: <expression>,
//    blockStatements: array<blockStatementsBreakable>
//}
#endregion
function __GMLCexecuteCase() {
    //this is only here for consistancy sake, this function shouldnt ever run
    throw_gmlc_error("This code should be unreachable")
}
function __GMLCcompileCase(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileCase", "<Missing Error Message>", _node.line, _node.lineString);
	_output.isDefault = (_node.label == undefined);
	_output.expression = (_node.label == undefined) ? undefined : __GMLCcompileExpression(_rootNode, _parentNode, _node.label);
	_output.blockStatement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.codeBlock);
    
    
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileWith", "<Missing Error Message>", _node.line, _node.lineString);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.blockStatement = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.codeBlock);
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
	
	try {
		tryBlock()
    }
    catch(_e) {
		if (parentNode.flowMask & FLOW_MASK.RETURN) return;
		if (catchBlock != undefined) {
			//locals = variable_clone(parentNode.locals, 1)
			parentNode.locals[catchVariableIndex] = _e;
			parentNode.localsWrittenTo[catchVariableIndex] = true;
			catchBlock()
		}
    }
    
	if (finallyBlock != undefined) {
		finallyBlock();
	}
}
function __GMLCcompileTryCatchFinally(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileTryCatchFinally", "<Missing Error Message>", _node.line, _node.lineString);
	_output.tryBlock = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.tryBlock);
	_output.catchVariableName = _node.exceptionVar;
	_output.catchVariableIndex = _parentNode.localLookUps[$ _node.exceptionVar];
	_output.catchBlock = undefined;
	_output.finallyBlock = undefined;
    
	
	if (_node.catchBlock != undefined)   _output.catchBlock   = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.catchBlock)
	if (_node.finallyBlock != undefined) _output.finallyBlock = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.finallyBlock)
	
	if (_node.catchBlock = undefined)
	&& (_node.finallyBlock = undefined) {
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
	var _i=argumentCount-1; repeat(argumentCount) {
		arguments[_i] = argumentExpressions[_i]();
	_i--}
	
	var _struct = constructor_call_ext(_func, arguments);
	var t = static_get(_struct);
	
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
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileNewExpression", "<Missing Error Message>", _node.line, _node.lineString);
	_output.callee = __GMLCcompileExpression(_rootNode, _parentNode, _node.expression.callee);
	_output.calleeName = _node.expression.callee[$ "name"]; // this is actually unneeded, but we would still like to have it for debugging
	
	_output.recursionCount = 0; 
	_output.prevArgCount = 0;
	_output.argumentCount = array_length(_node.expression.arguments);
	_output.argumentExpressions = array_create(_output.argumentCount);
	_output.arguments = array_create(_output.argumentCount);
	_output.backupArguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argCountMemory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	var _argArr = _node.expression.arguments
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileBreak", "<Missing Error Message>", _node.line, _node.lineString);
	
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileContinue", "<Missing Error Message>", _node.line, _node.lineString);
	
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileExit", "<Missing Error Message>", _node.line, _node.lineString);
	
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
	if (_node.expr == undefined) {
		return __GMLCcompileExit(_rootNode, _parentNode, _node);
	}
	
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileReturn", "<Missing Error Message>", _node.line, _node.lineString);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr)
	
    return __vanilla_method(_output, __GMLCexecuteReturn);
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileLiteralExpression", "<Missing Error Message>", _node.line, _node.lineString);
	_output.value = _node.value;
    
    
    return __vanilla_method(_output, __GMLCexecuteLiteralExpression);
}

#region //{
// used to call functions
//    callee: <method, function, or program>,
//    argArr: array<expression>,
//}
#endregion
function __GMLCexecuteCallExpression() {
	var _func = callee()
	
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
	var _i=argumentCount-1; repeat(argumentCount) {
		arguments[_i] = argumentExpressions[_i]();
	_i--}
	
	if (shouldUpdateInstanceScoping) {
		var _prevUpdateOther = global.gmlc_other_instance;
		var _prevUpdateSelf  = global.gmlc_self_instance;
		
		var _target = updateScopingTarget();
		if (_target != undefined)
		&& (_target != _prevUpdateSelf) {
			global.gmlc_other_instance = _prevUpdateSelf;
			global.gmlc_self_instance = _target;
		}
	}
	
	var _return = undefined;
	if (is_method(_func)) {
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
			global.gmlc_other_instance = _prevSelf;
			global.gmlc_self_instance = _self;
			
			//why am i doing this?
			with (_prevSelf) {
				_return = method_call(_func, _args);
			}
		
			global.gmlc_other_instance = _prevOther;
			global.gmlc_self_instance  = _prevSelf;
		}
	}
	else {
		var _args = arguments;
		with (global.gmlc_other_instance) with (global.gmlc_self_instance) {
			//try {
				_return = script_execute_ext(_func, _args);
			//}
			//catch(e) {
			//	log(_func);
			//	log(script_get_name(_func));
			//	log(_args);
			//	log(e);
			//	log("\n\n\n");
			//}
		}
	}
	
	if (shouldUpdateInstanceScoping) {
		global.gmlc_other_instance = _prevUpdateOther;
		global.gmlc_self_instance  = _prevUpdateSelf;
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
function __GMLCcompileCallExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileCallExpression", "<Missing Error Message>", _node.line, _node.lineString);
	_output.callee = __GMLCcompileExpression(_rootNode, _parentNode, _node.callee);
	
	_output.calleeName = (struct_exists(_node.callee, "name")) ? _node.callee.name : "<Call Expression>"
	
	_output.recursionCount = 0; 
	_output.prevArgCount = 0;
	_output.argumentCount = array_length(_node.arguments);
	_output.argumentExpressions = array_create(_output.argumentCount);
	_output.arguments = array_create(_output.argumentCount);
	_output.backupArguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argCountMemory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	
	//handle dot accessor scoping
	_output.shouldUpdateInstanceScoping = false;
	var _callee = method_get_self(_output.callee)
	if (_callee.compilerBase == "__compileStructDotAccGet") {
		var _target = method_get_self(_callee.target)
		if (_target.compilerBase == "__GMLCcompileIdentifier") {
			_output.shouldUpdateInstanceScoping = true;
			_output.updateScopingTarget = _callee.target;
		}
	}
	
	var _argArr = _node.arguments
	var _i=0; repeat(array_length(_argArr)) {
		_output.argumentExpressions[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _argArr[_i])
	_i++}
    
    return __vanilla_method(_output, __GMLCexecuteCallExpression);
}

function __GMLCcompileVariableDeclaration(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileVariableDeclaration", "<Missing Error Message>", _node.line, _node.lineString);
	_output.key = _node.identifier.value;
	if (_node.scope == ScopeType.LOCAL) {
		_output.locals = _parentNode.locals;
		_output.localsWrittenTo = _parentNode.localsWrittenTo;
		_output.localIndex = _parentNode.localLookUps[$ _output.key];
	}
	else if (_node.scope == ScopeType.GLOBAL) {
		_output.globals = _rootNode.globals;
	}
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr);
	
	return __vanilla_method(_output, __GMLCGetScopeSetter(_node.scope))
	
}
function __GMLCcompileVariableDeclarationList(_rootNode, _parentNode, _node) {
	return __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.statements)
}

#endregion

#region Math Expressions

function __GMLCcompileAssignmentExpression(_rootNode, _parentNode, _node) {
	if (_node.left.type == __GMLC_NodeType.AccessorExpression) {
		
		if (_node.operator == "=") {
			switch (_node.left.accessorType) {
				case __GMLC_AccessorType.Array:  return __GMLCcompileArraySet       (_rootNode, _parentNode, _node.left.expr, _node.left.val1,                  _node.right, _node.line, _node.lineString);
				case __GMLC_AccessorType.Grid:   return __GMLCcompileGridSet		(_rootNode, _parentNode, _node.left.expr, _node.left.val1, _node.left.val2, _node.right, _node.line, _node.lineString);
				case __GMLC_AccessorType.List:   return __GMLCcompileListSet		(_rootNode, _parentNode, _node.left.expr, _node.left.val1,                  _node.right, _node.line, _node.lineString);
				case __GMLC_AccessorType.Map:    return __GMLCcompileMapSet		    (_rootNode, _parentNode, _node.left.expr, _node.left.val1,                  _node.right, _node.line, _node.lineString);
				case __GMLC_AccessorType.Struct: return __GMLCcompileStructSet      (_rootNode, _parentNode, _node.left.expr, _node.left.val1,                  _node.right, _node.line, _node.lineString);
				case __GMLC_AccessorType.Dot:    return __GMLCcompileStructDotAccSet(_rootNode, _parentNode, _node.left.expr, _node.left.val1,                  _node.right, _node.line, _node.lineString);
			}
		}
		else {
			
			//get the accurate opperator function
			var _func = undefined;
			switch (_node.operator) {
				case "+=":  _func = __GMLCexecuteOpPlus;	   break;
				case "-=":  _func = __GMLCexecuteOpMinus;	   break;
				case "*=":  _func = __GMLCexecuteOpMultiply;   break;
				case "/=":  _func = __GMLCexecuteOpDivide;	   break;
				case "^=":  _func = __GMLCexecuteOpBitwiseXOR; break;
				case "&=":  _func = __GMLCexecuteOpBitwiseAND; break;
				case "|=":  _func = __GMLCexecuteOpBitwiseOR;  break;
				case "%=":  _func = __GMLCexecuteOpMod;        break;
				case "??=": _func = __GMLCexecuteOpNullish;	   break;
			}
			
			var _getter = undefined;
			var _setter = undefined;
			switch (_node.left.accessorType) {
				case __GMLC_AccessorType.Array:  _getter = __GMLCexecuteArrayGet       ; _setter = __GMLCexecuteArraySet       ; break;
				case __GMLC_AccessorType.Grid:   _getter = __GMLCexecuteGridGet        ; _setter = __GMLCexecuteGridSet        ; break;
				case __GMLC_AccessorType.List:   _getter = __GMLCexecuteListGet		   ; _setter = __GMLCexecuteListSet		   ; break;
				case __GMLC_AccessorType.Map:    _getter = __GMLCexecuteMapGet		   ; _setter = __GMLCexecuteMapSet		   ; break;
				case __GMLC_AccessorType.Struct: _getter = __GMLCexecuteStructGet      ; _setter = __GMLCexecuteStructSet      ; break;
				case __GMLC_AccessorType.Dot:    _getter = __GMLCexecuteStructDotAccGet; _setter = __GMLCexecuteStructDotAccSet; break;
			}
			
			
			//compile the getter
			var _output0 = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Getter", "<Missing Error Message>", _node.line, _node.lineString);
			_output0.target     = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.expr);
			if (_node.left.accessorType = __GMLC_AccessorType.Grid) {
				_output0.keyX = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val1);
				_output0.keyY = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val2);
			}
			else if (_node.left.accessorType = __GMLC_AccessorType.Dot) {
				_output0.key = _node.left.val1.value;
			}
			else {
				_output0.key = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val1);
			}
			var _getter_expression = __vanilla_method(_output0, _getter);
			
			
			
			//compile the additive method
			var _output1 = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Operator", "<Missing Error Message>", _node.line, _node.lineString);
			_output1.left  = _getter_expression;
			_output1.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
			var _expression = __vanilla_method(_output1, _func);
			
			
			//compile the actual method we will be calling
			//compile the setter
			var _output2 = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Setter", "<Missing Error Message>", _node.line, _node.lineString);
			_output2.target     = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.expr);
			_output2.expression = _expression;
			if (_node.left.accessorType == __GMLC_AccessorType.Grid) {
				_output2.keyX = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val1);
				_output2.keyY = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val2);
			}
			else if (_node.left.accessorType = __GMLC_AccessorType.Dot) {
				_output2.key = _node.left.val1.value;
			}
			else {
				_output2.key = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val1);
			}
			
			return __vanilla_method(_output2, _setter);
			
		}
	}
	
	if (_node.left.type == __GMLC_NodeType.Identifier)
	|| (_node.left.type == __GMLC_NodeType.UniqueIdentifier) {
		
		//var _name = undefined;
		//if (_node.left.type == __GMLC_NodeType.Identifier) {
		//	_name = _node.left.name
		//}
		//if (_node.left.type == __GMLC_NodeType.UniqueIdentifier) {
		//	_name = 
		//}
		
		var _func = undefined;
		switch (_node.operator) {
			case "=": return __GMLCcompilePropertySet(_rootNode, _parentNode, _node.left.scope, _node.left.value, _node.right, _node.line, _node.lineString); break;
			
			case "+=":  _func = __GMLCexecuteOpPlus;	   break;
			case "-=":  _func = __GMLCexecuteOpMinus;	   break;
			case "*=":  _func = __GMLCexecuteOpMultiply;   break;
			case "/=":  _func = __GMLCexecuteOpDivide;	   break;
			case "^=":  _func = __GMLCexecuteOpBitwiseXOR; break;
			case "&=":  _func = __GMLCexecuteOpBitwiseAND; break;
			case "|=":  _func = __GMLCexecuteOpBitwiseOR;  break;
			case "%=":  _func = __GMLCexecuteOpMod;        break;
			case "??=": _func = __GMLCexecuteOpNullish;	   break;
		}
		
		var _getter = __GMLCGetScopeGetter(_node.left.scope);
		var _setter = __GMLCGetScopeSetter(_node.left.scope);
		
		
		//compile the getter
		var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Getter", "<Missing Error Message>", _node.line, _node.lineString);	
		_output.key = _node.left.name;
		if (_node.left.scope == ScopeType.LOCAL) {
			_output.locals     = _parentNode.locals;
			_output.localsWrittenTo = _parentNode.localsWrittenTo;
			_output.localIndex = _parentNode.localLookUps[$ _output.key];
		}
		else if (_node.left.scope == ScopeType.GLOBAL) {
			_output.globals = _rootNode.globals;
		}
		var _getter_expression = __vanilla_method(_output, _getter);
		
		//compile the additive method
		var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Operator", "<Missing Error Message>", _node.line, _node.lineString);
		_output.left  = _getter_expression;
		_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
		var _expression = __vanilla_method(_output, _func);
		
		//compile the actual method we will be calling
		var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Setter", "<Missing Error Message>", _node.line, _node.lineString);
		_output.key        = _node.left.name;
		if (_node.left.scope == ScopeType.LOCAL) {
			_output.locals     = _parentNode.locals;
			_output.localsWrittenTo = _parentNode.localsWrittenTo;
			_output.localIndex = _parentNode.localLookUps[$ _output.key];
		}
		else if (_node.left.scope == ScopeType.GLOBAL) {
			_output.globals = _rootNode.globals;
		}
		_output.expression = _expression;
		return __vanilla_method(_output, _setter);
	}
	
	throw_gmlc_error($"Couldnt find a proper assignment op for the node type :: {_node.left.type}"+$"\n(line {_node.line}) -\t{_node.lineString}")
}

function __GMLCcompileBinaryExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileBinaryExpression", "<Missing Error Message>", _node.line, _node.lineString);
	_output.left  = __GMLCcompileExpression(_rootNode, _parentNode, _node.left);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
    
    switch (_node.operator) {
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
		
		case "=":   
			throw "Should this be accessible here?"
			return __vanilla_method(_output, __GMLCexecuteOpEqualsEquals     );
		break;
		
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

function __GMLCcompileLogicalExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileLogicalExpression", "<Missing Error Message>", _node.line, _node.lineString);
	_output.left  = __GMLCcompileExpression(_rootNode, _parentNode, _node.left);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
    
	switch (_node.operator) {
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
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileNullishExpression", "<Missing Error Message>", _node.line, _node.lineString);
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
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUnaryExpression", "<Missing Error Message>", _node.line, _node.lineString);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr);
    
	switch (_node.operator) {
		case "!": return __vanilla_method(_output, __GMLCexecuteOpNot          )
		case "-": return __vanilla_method(_output, __GMLCexecuteOpNegate       )
		case "~": return __vanilla_method(_output, __GMLCexecuteOpBitwiseNegate)
		case "+": return _output.expr;
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileTernaryExpression", "<Missing Error Message>", _node.line, _node.lineString);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.left = __GMLCcompileExpression(_rootNode, _parentNode, _node.trueExpr);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.falseExpr);
    
    
    return __vanilla_method(_output, __GMLCexecuteTernaryExpression);
}

function __GMLCcompileUpdateExpression(_rootNode, _parentNode, _node) {
	if (_node.expr.type == __GMLC_NodeType.Identifier)
	|| (_node.expr.type == __GMLC_NodeType.UniqueIdentifier) {
		
		var _key = _node.expr.value;
		var _increment = (_node.operator == "++") ? true : false;
		var _prefix = _node.prefix;
		
		return __GMLCcompileUpdateVariable(_rootNode, _parentNode, _node.expr.scope, _key, _increment, _prefix, _node.line, _node.lineString)
	}
	else if (_node.expr.type == __GMLC_NodeType.AccessorExpression) {
		
		switch (_node.expr.accessorType) {
			case __GMLC_AccessorType.Array:  return __GMLCcompileUpdateArray  (_rootNode, _parentNode, _node);
			case __GMLC_AccessorType.Grid:   return __GMLCcompileUpdateGrid   (_rootNode, _parentNode, _node);
			case __GMLC_AccessorType.List:   return __GMLCcompileUpdateList   (_rootNode, _parentNode, _node);
			case __GMLC_AccessorType.Map:    return __GMLCcompileUpdateMap    (_rootNode, _parentNode, _node);
			case __GMLC_AccessorType.Struct: return __GMLCcompileUpdateStruct (_rootNode, _parentNode, _node);
			case __GMLC_AccessorType.Dot:    return __GMLCcompileUpdateStructDotAcc(_rootNode, _parentNode, _node);
		}
		
	}
	
	throw_gmlc_error("Malformed assignment"+$"\n(line {_node.line}) -\t{_node.lineString}")
}

#endregion

#region Identifiers

#region Targeters / Getter / Setters

//these are used when the target is an expected result, self, other, global, static, var, or a known unique variabke like `room` or `fps`
function __GMLCGetScopeGetter(_scopeType) {
	switch (_scopeType) {
		case ScopeType.GLOBAL:   return __GMLCexecuteGetPropertyGlobal    break;
		case ScopeType.LOCAL:    return __GMLCexecuteGetPropertyVarLocal  break;
		case ScopeType.STATIC:   return __GMLCexecuteGetPropertyVarStatic break;
		case ScopeType.SELF:     return __GMLCexecuteGetPropertySelf      break;
		case ScopeType.CONST:    return __GMLCexecuteGetPropertyConstant  break;
		case ScopeType.UNIQUE:   return __GMLCexecuteGetPropertyUnique    break;
		default: throw_gmlc_error($"Unsupported scope to be written to :: {_scopeType}");
	}
}
function __GMLCGetScopeSetter(_scopeType) {
	switch (_scopeType) {
		case ScopeType.GLOBAL:   return __GMLCexecuteSetPropertyGlobal    break;
		case ScopeType.LOCAL:    return __GMLCexecuteSetPropertyVarLocal  break;
		case ScopeType.STATIC:   return __GMLCexecuteSetPropertyVarStatic break;
		case ScopeType.SELF:     return __GMLCexecuteSetPropertySelf      break;
		case ScopeType.CONST:    return __GMLCexecuteSetPropertyConstant  break;
		case ScopeType.UNIQUE:   return __GMLCexecuteSetPropertyUnique    break;
		default: throw_gmlc_error($"Unsupported scope to be written to :: {_scopeType}");
	}
}
function __GMLCGetScopeUpdater(_scopeType, _increment, _prefix) {
	switch (_scopeType){
		case ScopeType.SELF:{
			if (_increment  &&  _prefix) return __GMLCexecuteUpdatePropertySelfPlusPlusPrefix;
			if (_increment  && !_prefix) return __GMLCexecuteUpdatePropertySelfPlusPlusPostfix;
			if (!_increment &&  _prefix) return __GMLCexecuteUpdatePropertySelfMinusMinusPrefix;
			if (!_increment && !_prefix) return __GMLCexecuteUpdatePropertySelfMinusMinusPostfix;
		break;}
		case ScopeType.OTHER:{
			if (_increment  &&  _prefix) return __GMLCexecuteUpdatePropertyOtherPlusPlusPrefix;
			if (_increment  && !_prefix) return __GMLCexecuteUpdatePropertyOtherPlusPlusPostfix;
			if (!_increment &&  _prefix) return __GMLCexecuteUpdatePropertyOtherMinusMinusPrefix;
			if (!_increment && !_prefix) return __GMLCexecuteUpdatePropertyOtherMinusMinusPostfix;
		break;}
		case ScopeType.GLOBAL:{
			if (_increment  &&  _prefix) return __GMLCexecuteUpdatePropertyGlobalPlusPlusPrefix;
			if (_increment  && !_prefix) return __GMLCexecuteUpdatePropertyGlobalPlusPlusPostfix;
			if (!_increment &&  _prefix) return __GMLCexecuteUpdatePropertyGlobalMinusMinusPrefix;
			if (!_increment && !_prefix) return __GMLCexecuteUpdatePropertyGlobalMinusMinusPostfix;
		break;}
		case ScopeType.LOCAL:{
			if (_increment  &&  _prefix) return __GMLCexecuteUpdatePropertyLocalPlusPlusPrefix;
			if (_increment  && !_prefix) return __GMLCexecuteUpdatePropertyLocalPlusPlusPostfix;
			if (!_increment &&  _prefix) return __GMLCexecuteUpdatePropertyLocalMinusMinusPrefix;
			if (!_increment && !_prefix) return __GMLCexecuteUpdatePropertyLocalMinusMinusPostfix;
		break;}
		case ScopeType.STATIC:{
			if (_increment  &&  _prefix) return __GMLCexecuteUpdatePropertyStaticPlusPlusPrefix;
			if (_increment  && !_prefix) return __GMLCexecuteUpdatePropertyStaticPlusPlusPostfix;
			if (!_increment &&  _prefix) return __GMLCexecuteUpdatePropertyStaticMinusMinusPrefix;
			if (!_increment && !_prefix) return __GMLCexecuteUpdatePropertyStaticMinusMinusPostfix;
		break;}
		case ScopeType.UNIQUE:{
			if (_increment  &&  _prefix) return __GMLCexecuteUpdatePropertyUniquePlusPlusPrefix;
			if (_increment  && !_prefix) return __GMLCexecuteUpdatePropertyUniquePlusPlusPostfix;
			if (!_increment &&  _prefix) return __GMLCexecuteUpdatePropertyUniqueMinusMinusPrefix;
			if (!_increment && !_prefix) return __GMLCexecuteUpdatePropertyUniqueMinusMinusPostfix;
		break;}
	}
}

#region Generic Getter    -    (These will use expressions instead of literal keys written to the method, for those see fast pass script)
function __GMLCcompilePropertyGet(_rootNode, _parentNode, _scope, _leftKey, _line, _lineString){
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompilePropertyGet", "<Missing Error Message>", _line, _lineString);	
	_output.key      = _leftKey;
	if (_scope == ScopeType.LOCAL) {
		_output.locals = _parentNode.locals;
		_output.localsWrittenTo = _parentNode.localsWrittenTo;
		_output.localIndex = _parentNode.localLookUps[$ _output.key];
	}
	else if (_scope == ScopeType.GLOBAL) {
		_output.globals = _rootNode.globals;
	}
	return __vanilla_method(_output, __GMLCGetScopeGetter(_scope))
}
#endregion

#region Generic Setter    -    (These will use expressions instead of literal keys written to the method, for those see fast pass script)
function __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _key, _rightExpression, _line, _lineString){
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompilePropertySet", "<Missing Error Message>", _line, _lineString);
	_output.key = _key;
	if (_scope == ScopeType.LOCAL) {
		_output.locals = _parentNode.locals;
		_output.localsWrittenTo = _parentNode.localsWrittenTo;
		_output.localIndex = _parentNode.localLookUps[$ _output.key];
	}
	else if (_scope == ScopeType.GLOBAL) {
		_output.globals = _rootNode.globals;
	}
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _rightExpression);
	
	return __vanilla_method(_output, __GMLCGetScopeSetter(_scope))
}
#endregion

#endregion

function __GMLCcompileAccessor(_rootNode, _parentNode, _node) {
	switch (_node.accessorType) {
		case __GMLC_AccessorType.Array:  return __GMLCcompileArrayGet       (_rootNode, _parentNode, _node.expr, _node.val1,             _node.line, _node.lineString)
		case __GMLC_AccessorType.Grid:   return __GMLCcompileGridGet        (_rootNode, _parentNode, _node.expr, _node.val1, _node.val2, _node.line, _node.lineString)
		case __GMLC_AccessorType.List:   return __GMLCcompileListGet        (_rootNode, _parentNode, _node.expr, _node.val1,             _node.line, _node.lineString)
		case __GMLC_AccessorType.Map:    return __GMLCcompileMapGet         (_rootNode, _parentNode, _node.expr, _node.val1,             _node.line, _node.lineString)
		case __GMLC_AccessorType.Struct: return __GMLCcompileStructGet      (_rootNode, _parentNode, _node.expr, _node.val1,             _node.line, _node.lineString)
		case __GMLC_AccessorType.Dot:    return __GMLCcompileStructDotAccGet(_rootNode, _parentNode, _node.expr, _node.val1,             _node.line, _node.lineString)
		default: throw_gmlc_error($"Unsupported accessor type: {_node.accessorType}\n{_node}");
	}
}

function __GMLCcompileIdentifier(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileIdentifier", "<Missing Error Message>", _node.line, _node.lineString);
	_output.key = _node.value;
	if (_node.scope == ScopeType.LOCAL) {
		_output.locals = _parentNode.locals;
		_output.localsWrittenTo = _parentNode.localsWrittenTo;
		_output.localIndex = _parentNode.localLookUps[$ _output.key];
	}
	else if (_node.scope == ScopeType.GLOBAL) {
		_output.globals = _rootNode.globals;
	}
	else if (_node.scope == ScopeType.CONST) {
		show_debug_message("wait")
	}
	return __vanilla_method(_output, __GMLCGetScopeGetter(_node.scope))
}

function __GMLCcompileUniqueIdentifier(_rootNode, _parentNode, _node) {
	//var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUniqueIdentifier", "<Missing Error Message>", _node.line, _node.lineString);
	
	return _node.value.get;
}


#endregion

#region Util
function __GMLC_Function(_rootNode, _parentNode, _base, _error, _line, _lineString) constructor {
	self[$ "__@@is_gmlc_program@@__"] = true;
	
	compilerBase = _base;
	errorMessage = _error;
	line = _line; //used for debugging
	lineString = _lineString; //used for debugging
	
	
	rootNode = _rootNode;
	parentNode = _parentNode;
	
	callstack = debug_get_callstack()
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

