
///NOTE: all of these should be build into the parent programs struct, and all children should
// have a reference to that struct to access the locals and arguments when ever needed

global.selfInstance = undefined;
global.otherInstance = undefined;
//global.callStack = [];

///////////////////////////////////////////////////////////////////////////////////////////////

function compileProgram(_AST) {
	return __GMLCcompileProgram(_AST);
}
function executeProgram(_program) {
	//this function should never be called inside a prgroam, for that use `__executeProgram`
	global.selfInstance = self;
    global.otherInstance = other;
    
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
	//edit our local array
	if (recursionCount++) {
        // stash the arguments
        array_copy(backupArguments, array_length(backupArguments), arguments, 0, prevArgCount);
		array_resize(arguments, 0);
		array_resize(arguments, argument_count);
		array_push(argCountMemory, argument_count)
    }
	
	//remember how many the function had
	prevArgCount = argument_count;
	
	
	// populate argument array
	var _i=argument_count-1; repeat(argument_count) {
		arguments[_i] = argument[_i];
	_i--}
	
	
	////////////////EXECUTE////////////////////////
	var _return = program();
	///////////////////////////////////////////////
	
	if (--recursionCount) {
        // Un-stash the arguments
		var _prev_arg_count = array_pop(argCountMemory)
		var _arg_offset = array_length(backupArguments)-argument_count
        array_copy(arguments, 0, backupArguments, _arg_offset, _prev_arg_count);
        array_resize(backupArguments, _arg_offset);
    }
	else {
		array_resize(arguments, 0);
	}
	
	return _return;
}
function __GMLCcompileProgram(_node, _globalsStruct={"__@@ASSETS@@__":{}}) {
	var _output = new __GMLC_Function(undefined, undefined, "__GMLCcompileProgram", "<Missing Error Message>", _node.line, _node.lineString);
	_output.globals = _globalsStruct; // these are optional inputs for future use with compiling a full project folder.
	_output.program = __GMLCcompileFunction(_output, _output, _node);
	
	_output.recursionCount = 0; 
	_output.prevArgCount = 0; 
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
	
	return method(_output, __GMLCexecuteProgram)
}

function __GMLCexecuteFunction() {
	//mostly just used in recursion code
	var _arg_count = max(argument_count, argumentCount)
	
	if (recursionCount++) {
        // stash the locals
        array_copy(backupLocals, array_length(backupLocals), locals, 0, localCount);
		array_resize(locals, 0);
		array_resize(locals, localCount);
        array_copy(backupLocalsWrittenTo, array_length(backupLocalsWrittenTo), localsWrittenTo, 0, localCount);
		array_resize(localsWrittenTo, 0);
		array_resize(localsWrittenTo, localCount);
        // stash the arguments
        array_copy(backupArguments, array_length(backupArguments), arguments, 0, prevArgCount);
		array_resize(arguments, 0);
		array_resize(arguments, _arg_count);
		array_push(argCountMemory, _arg_count)
    }
	
	//remember how many the function had
	prevArgCount = _arg_count;
	
	
	// populate argument array
	var _i=argument_count-1; repeat(argument_count) {
		arguments[_i] = argument[_i];
	_i--}
	if (argumentCount) {
		argumentsDefault();
	}
	
	//run our statics
	if (!staticsExecuted) {
		staticsExecuted = true;
		staticsBlock();
		static_set(self, statics);
	}
	
	method_call(program, arguments);
	var _return = returnValue;
	
	shouldReturn = false;
	returnValue = undefined;
	//shouldBreak = false;
	//shouldContinue = false;
	
	if (--recursionCount) {
        // Un-stash the locals
		var _local_offset = array_length(backupLocals)-localCount
        array_copy(locals, 0, backupLocals, _local_offset, localCount);
        array_resize(backupLocals, _local_offset);
		var _local_offset = array_length(backupLocalsWrittenTo)-localCount
        array_copy(localsWrittenTo, 0, backupLocalsWrittenTo, _local_offset, localCount);
        array_resize(backupLocalsWrittenTo, _local_offset);
		// Un-stash the arguments
		var _prev_arg_count = array_pop(argCountMemory)
		var _arg_offset = array_length(backupArguments)-_prev_arg_count
        array_copy(arguments, 0, backupArguments, _arg_offset, _prev_arg_count);
        array_resize(backupArguments, _arg_offset);
    }
	else {
		array_resize(locals, 0);
		array_resize(localsWrittenTo, 0);
        array_resize(arguments, 0);
		if (array_length(backupArguments))
		|| (array_length(backupLocals))
		|| (array_length(backupLocalsWrittenTo)) {
			throw_gmlc_error($"huh... the array sizes aren't correct\narray_length(backupArguments) == {array_length(backupArguments)}\narray_length(backupArguments) == {array_length(backupArguments)}")
		}
	}
	
	return _return;
}
function __GMLCcompileFunction(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, undefined, "__GMLCcompileFunction", "<Missing Error Message>", _node.line, _node.lineString);
	_output[$ "__@@is_gmlc_function@@__"] = true;
	
	_output.parentNode = _output;
	
	//statics
	_output.staticsExecuted = false;
	_output.statics = new __GMLC_Statics();
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
	_output.arguments = array_create(_output.argumentCount);
	_output.backupArguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argCountMemory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	_output.program = __GMLCcompileBlockStatement(_rootNode, _output, _node.statements);
		
	_output.returnValue = undefined;
	_output.shouldReturn = false;
	_output.shouldBreak = false;
	_output.shouldContinue = false;
	
	
	return method(_output, __GMLCexecuteFunction)
}

function __GMLCexecuteConstructor() {
	//mostly just used in recursion code
	var _arg_count = max(argument_count, argumentCount)
	
	if (recursionCount++) {
        // stash the locals
        array_copy(backupLocals, array_length(backupLocals), locals, 0, localCount);
		array_resize(locals, 0);
		array_resize(locals, localCount);
        array_copy(backupLocalsWrittenTo, array_length(backupLocalsWrittenTo), localsWrittenTo, 0, localCount);
		array_resize(localsWrittenTo, 0);
		array_resize(localsWrittenTo, localCount);
        // stash the arguments
        array_copy(backupArguments, array_length(backupArguments), arguments, 0, prevArgCount);
		array_resize(arguments, 0);
		array_resize(arguments, _arg_count);
		array_push(argCountMemory, _arg_count)
    }
	
	//remember how many the function had
	prevArgCount = _arg_count;
	
	
	// populate argument array
	var _i=argument_count-1; repeat(argument_count) {
		arguments[_i] = argument[_i];
	_i--}
	if (argumentCount) {
		argumentsDefault();
	}
	
	if (hasParentConstructor) {
		//run the parent 
		method_call(parentConstructorCall, arguments);
	}
	
	//run our statics
	if (!staticsExecuted) {
		staticsExecuted = true;
		staticsBlock();
		
		if (hasParentConstructor) {
			var _parent_constuct = rootNode.globals[$ parentConstructorName]
			static_set(statics, static_get(method_get_self(_parent_constuct)))
		}
		else {
			//set it to the default struct's statics
			static_set(statics, static_get({}))
		}
		
		static_set(self, statics);
	}
	
	//set the new object's statics to our statics
	static_set(global.selfInstance, static_get(self));
	
	//run the body
	method_call(program, arguments);
	var _return = returnValue;
	
	shouldReturn = false;
	returnValue = undefined;
	//shouldBreak = false;
	//shouldContinue = false;
	
	if (--recursionCount) {
        // Un-stash the locals
		var _local_offset = array_length(backupLocals)-localCount
        array_copy(locals, 0, backupLocals, _local_offset, localCount);
        array_resize(backupLocals, _local_offset);
		var _local_offset = array_length(backupLocalsWrittenTo)-localCount
        array_copy(localsWrittenTo, 0, backupLocalsWrittenTo, _local_offset, localCount);
        array_resize(backupLocalsWrittenTo, _local_offset);
		// Un-stash the arguments
		var _prev_arg_count = array_pop(argCountMemory)
		var _arg_offset = array_length(backupArguments)-_prev_arg_count
        array_copy(arguments, 0, backupArguments, _arg_offset, _prev_arg_count);
        array_resize(backupArguments, _arg_offset);
    }
	else {
		array_resize(locals, 0);
		array_resize(localsWrittenTo, 0);
        array_resize(arguments, 0);
		if (array_length(backupArguments))
		|| (array_length(backupLocals))
		|| (array_length(backupLocalsWrittenTo)) {
			throw_gmlc_error($"huh... the array sizes aren't correct\narray_length(backupArguments) == {array_length(backupArguments)}\narray_length(backupArguments) == {array_length(backupArguments)}")
		}
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
	_output.arguments = array_create(_output.argumentCount);
	_output.backupArguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argCountMemory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	_output.program = __GMLCcompileBlockStatement(_rootNode, _output, _node.statements);
	
	_output.returnValue = undefined;
	_output.shouldReturn = false;
	_output.shouldBreak = false;
	_output.shouldContinue = false;
	
	if (_node.parentCall != undefined) {
		_output.hasParentConstructor = true;
		_output.parentConstructorName = _node.parentName;
		_output.parentConstructorCall = __GMLCcompileCallExpression(_rootNode, _output, _node.parentCall);
		
		//_output.parentConstructor = rootNode.globals[$ parentName];
	}
	
	return method(_output, __GMLCexecuteConstructor)
}

function __GMLCexecuteArgumentList() {
	var _inputArguments = parentNode.arguments
	var _inputLength = parentNode.prevArgCount; //at this current stage these are actually our current arguments, hopefully this does cause issues in the furst.. :/
	
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
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileArgumentList", "<Missing Error Message>", _node.line, _node.lineString);
	_output.statements = [];
	_output.size = undefined;
	
	//_output.varStatics = {};
	//_output.locals = {};
	
	
	var _arr = _node.statements;
	var _i=0; repeat(array_length(_arr)) {
		_output.statements[_i] = __GMLCcompileArgument(_rootNode, _parentNode, _arr[_i]);
	_i++}
	
	_output.size = array_length(_output.statements);
	
	return method(_output, __GMLCexecuteArgumentList)
}

function __GMLCexecuteArgument() {
	throw_gmlc_error("ERROR :: __GMLCexecuteArgument should never actually be run, this should be handled by ArgumentList")
}
function __GMLCcompileArgument(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileArgument", "<Missing Error Message>", _node.line, _node.lineString);
	_output.index = _node.argument_index;
	_output.localIndex = _parentNode.localLookUps[$ _node.identifier];
	_output.identifier = _node.identifier;
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr)
	
	return _output;
}

function __GMLCexecuteExpression() {};
function __GMLCcompileExpression(_rootNode, _parentNode, _node) {
	//log("\n\n")
	//pprint(_node)
	//log($"TYPE :: {_node.type}\nLINE :: {struct_exists(_node, "lineString") ? _node.lineString : "<undefined>"}\nNODE :: {json_stringify(_node, true)}")
	
	if (_parentNode=undefined && _node==undefined) {
		throw_gmlc_error("Red forgot to add the `rootNode` and `parentNode` when calling `__GMLCcompileExpression`!")
	}
	if (!is_instanceof(_node, ASTNode)) {
		throw_gmlc_error($"Supplied Node is not a valid AST - Red's fault\ninstanceof(_node) == {instanceof(_node)}\nlineString == {method_get_self(_node).lineString}")
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
			return __GMLCcompileUniqueIdentifier(_rootNode, _parentNode, _node)
		break;}
				
		case __GMLC_NodeType.AccessorExpression:{
			return __GMLCcompileAccessor(_rootNode, _parentNode, _node)
		break;}
		
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
			
			do_trace(json_stringify(_node, true))
			throw_gmlc_error($"Current Node does not have a valid type for the optimizer,\ntype: {_node.type}\ncurrentNode: {json_stringify(_node, true)}")
		break;
				
		// Add cases for other types of nodes
	}
	
};

#endregion

#region Statements

#region Block Statements

#region //{
// used for gmlc compiled block statements, these are non-breakable, typically used
// for if/else statements, functions bodies, etc
//    blockStatements: [],
//    size: undefined,
//}
#endregion
function __GMLCexecuteBlockStatement() {
	var _i=0 repeat(size) {
		blockStatements[_i]();
		if (parentNode.shouldReturn) {
			return undefined;
		}
	_i++}
}
function __GMLCcompileBlockStatement(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileBlockStatement", "<Missing Error Message>", _node.line, _node.lineString);
	_output.blockStatements = [];
	_output.size = undefined;
    
	//this happens when a block statement consists of a single expression
	if (_node.type != __GMLC_NodeType.BlockStatement) {
		return __GMLCcompileExpression(_rootNode, _parentNode, _node)
	}
	
	
	var _blockStatements = _node.statements
	var _i=0; repeat(array_length(_blockStatements)) {
		var _expression = __GMLCcompileExpression(_rootNode, _parentNode, _blockStatements[_i])
		
		//prevent pushing a block statement into a block statement
		var _expr_struct = method_get_self(_expression)
		if (_expr_struct.compilerBase == "__compileBlockStatement") {
			array_copy(_output.blockStatements, array_length(_output.blockStatements), _expr_struct.blockStatements, 0, array_length(_expr_struct.blockStatements))
		}
		else {
			array_push(_output.blockStatements, _expression)
		}
		
    _i++}
	
	_output.size = array_length(_output.blockStatements)
    
	if (_output.size == 1) {
		//directly return the single statement if there is only one.
		return _output.blockStatements[0];
	}
	
	return method(_output, __GMLCexecuteBlockStatement);
}

#region //{
// used for gmlc compiled switch statements blocks, as they can be broken, and returned from, but can not be used with continue
//    blockStatements: [],
//}
#endregion
function __GMLCexecuteBlockStatementBreakable() {
	var _i=0 repeat(array_length(blockStatements)) {
		blockStatements[_i]();
		if (parentNode.shouldReturn) return undefined;
		if (parentNode.shouldBreak) return undefined;
	_i++}
}
function __GMLCcompileBlockStatementBreakable(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileBlockStatementBreakable", "<Missing Error Message>", _node.line, _node.lineString);
	_output.blockStatements = [];
	_output.size = undefined;
    
	
    var _i=0; repeat(array_length(_node.statements)) {
		_output.blockStatements[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _node.statements[_i])
    _i++}
    
    _output.size = array_length(_output.blockStatements)
    
    return method(_output, __GMLCexecuteBlockStatementBreakable);
}

#region //{
// used for gmlc compiled loops which have no exit condition except break or return
// for instance `repeat(infinity)` or `while(true)`
//    blockStatements: [],
//}
#endregion
function __GMLCexecuteLoopStatementEndless() {
    //NOTE: Benchmark the different ways for this `repeat(infinity)` `do{ }until(false)` `while(true)`
    while(true){
		blockStatements();
		if (parentNode.shouldReturn) return undefined;
		if (parentNode.shouldBreak) {
		    parentNode.shouldBreak = false;
		    return undefined;
		}
    }
}
function __GMLCcompileLoopStatementEndless(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileLoopStatementEndless", "<Missing Error Message>", _node.line, _node.lineString);
	_output.blockStatements = __GMLCcompileExpression(_rootNode, _parentNode, _blockStatement);
    
    
    return method(_output, __GMLCexecuteEndlessLoop);
}

#region //{
// used for gmlc compiled block statements, these are non-breakable, typically used
// for if/else statements, functions bodies, etc
//    blockStatements: {},
//}
#endregion
function __GMLCexecuteLoopStatement() {
	var _i=0 repeat(size) {
		blockStatements[_i]();
		if (parentNode.shouldReturn) return undefined;
		if (parentNode.shouldBreak) return undefined;
		if (parentNode.shouldContinue) {
		    parentNode.shouldContinue = false;
		    return undefined;
		}
	_i++}
}
function __GMLCcompileLoopStatement(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileLoopStatement", "<Missing Error Message>", _node.line, _node.lineString);
	_output.blockStatements = [];
	_output.size = undefined;
    
	
	//this happens when a block statement consists of a single expression
	if (_node.type != __GMLC_NodeType.BlockStatement) {
		return __GMLCcompileExpression(_rootNode, _parentNode, _node)
	}
	
	var _i=0; repeat(array_length(_node.statements)) {
		_output.blockStatements[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _node.statements[_i])
    _i++}
    
    _output.size = array_length(_output.blockStatements)
    
	if (_output.size == 0) {
		//return an empty function so we dont need to enter a method
		return function(){}
	}
	if (_output.size == 1) {
		//return an empty function so we dont need to enter a method
		return _output.blockStatements[0];
	}
	
    return method(_output, __GMLCexecuteLoopStatement);
}

#endregion

#region //{
// used for gmlc compiled repeat blocks
//    condition: <expression>,
//    trueBlock: <expression>,
//}
#endregion
function __GMLCexecuteIf() {
    if (condition()) trueBlock();
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
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileIf", "<Missing Error Message>", _node.line, _node.lineString);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.trueBlock = __GMLCcompileExpression(_rootNode, _parentNode, _node.consequent);
    
	if (_node.alternate == undefined) {
		return method(_output, __GMLCexecuteIf);
    }
    else {
		_output.elseBlock = __GMLCcompileExpression(_rootNode, _parentNode, _node.alternate);
		return method(_output, __GMLCexecuteIfElse);
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
		if (parentNode.shouldReturn) return undefined
		if (parentNode.shouldBreak) {
		    parentNode.shouldBreak = false;
		    return undefined;
		}
		if (parentNode.shouldContinue) {
		    parentNode.shouldContinue = false;
		}
    }
}
function __GMLCcompileRepeat(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileRepeat", "<Missing Error Message>", _node.line, _node.lineString);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.blockStatement = __GMLCcompileLoopStatement(_rootNode, _parentNode, _node.codeBlock);
    
    return method(_output, __GMLCexecuteRepeat);
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
		if (parentNode.shouldReturn) return undefined
		if (parentNode.shouldBreak) {
		    parentNode.shouldBreak = false;
		    return undefined;
		}
		if (parentNode.shouldContinue) {
		    parentNode.shouldContinue = false;
		    //no need to break or continue we will already be doing that
		}
    }
}
function __GMLCcompileWhile(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileWhile", "<Missing Error Message>", _node.line, _node.lineString);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.blockStatement = __GMLCcompileLoopStatement(_rootNode, _parentNode, _node.codeBlock);
    
    return method(_output, __GMLCexecuteWhile);
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
		if (parentNode.shouldReturn) return undefined
		if (parentNode.shouldBreak) {
		    parentNode.shouldBreak = false;
		    return undefined;
		}
		if (parentNode.shouldContinue) {
		    parentNode.shouldContinue = false;
		    //no need to break or continue we will already be doing that
		}
    }
    until condition()
}
function __GMLCcompileDoUntil(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileDoUntil", "<Missing Error Message>", _node.line, _node.lineString);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.blockStatement = __GMLCcompileLoopStatement(_rootNode, _parentNode, _node.codeBlock);
    
    return method(_output, __GMLCexecuteDoUntil);
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
    for (assignment(); condition(); operation()) {
		blockStatement();
		if (parentNode.shouldReturn) return undefined
		if (parentNode.shouldBreak) {
		    parentNode.shouldBreak = false;
		    return undefined;
		}
		if (parentNode.shouldContinue) {
		    parentNode.shouldContinue = false;
		    //no need to break or continue we will already be doing that
		}
    }
}
function __GMLCcompileFor(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileFor", "<Missing Error Message>", _node.line, _node.lineString);
	_output.assignment = __GMLCcompileExpression(_rootNode, _parentNode, _node.initialization);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.operation = __GMLCcompileExpression(_rootNode, _parentNode, _node.increment);
	_output.blockStatement = __GMLCcompileLoopStatement(_rootNode, _parentNode, _node.codeBlock);
    
    return method(_output, __GMLCexecuteFor);
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
		    if (parentNode.shouldReturn) return undefined
		    if (parentNode.shouldBreak) break;
		}
    _i++}
	
	if (!parentNode.shouldBreak)
	&& (caseDefault != undefined) {
		caseDefault.blockStatement()
	}
	
	parentNode.shouldBreak = false;
}
function __GMLCcompileSwitch(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileSwitch", "<Missing Error Message>", _node.line, _node.lineString);
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
    
    return method(_output, __GMLCexecuteSwitch);
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileCase", "<Missing Error Message>", _node.line, _node.lineString);
	_output.isDefault = (_node.label == undefined);
	_output.expression = (_node.label == undefined) ? undefined : __GMLCcompileExpression(_rootNode, _parentNode, _node.label);
	_output.blockStatement = __GMLCcompileBlockStatementBreakable(_rootNode, _parentNode, _node.codeBlock);
    
    
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
    
    var _self = global.selfInstance;
    var _other = global.otherInstance;
    
    //this mimics a with statement, but ultimately its not actually need to use `with`
    // until we hit a natively compiled function, as all glmc functions will directly
    // handle the instance
    global.otherInstance = global.selfInstance
    
	var _methodself   = self;
	//var _index  = myIndex;
	//var _method = myMethod;
	static __empty_arr = [];
    with (_inst) {
		global.selfInstance = self;
		
		method_call(_methodself.blockStatement, __empty_arr);
		
		//we break on all three cases here because we would like to run the
		// rest of the function to return to our previous self/other
		if (_methodself.parentNode.shouldReturn) break;
		if (_methodself.parentNode.shouldBreak) {
		    _methodself.parentNode.shouldBreak = false;
		    break;
		}
		if (_methodself.parentNode.shouldContinue) {
		    _methodself.parentNode.shouldContinue = false;
		    //no need to break or continue we will already be doing that
		}
	}
	
    
    //reset
    global.selfInstance = _self;
    global.otherInstance = _other;
}
function __GMLCcompileWith(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileWith", "<Missing Error Message>", _node.line, _node.lineString);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.blockStatement = __GMLCcompileLoopStatement(_rootNode, _parentNode, _node.codeBlock);
    //_output.mySelf  = _output;
    //_output.myIndex = __GMLCexecuteWith;
    //_output.myMethod = method(_output, __GMLCexecuteWith);
	
	return method(_output, __GMLCexecuteWith);
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
		if (parentNode.shouldReturn) return;
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileTryCatchFinally", "<Missing Error Message>", _node.line, _node.lineString);
	_output.tryBlock = __GMLCcompileLoopStatement(_rootNode, _parentNode, _node.tryBlock);
	_output.catchVariableName = _node.exceptionVar;
	_output.catchVariableIndex = _parentNode.localLookUps[$ _node.exceptionVar];
	_output.catchBlock = undefined;
	_output.finallyBlock = undefined;
    
	
	if (_node.catchBlock != undefined)   _output.catchBlock   = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.catchBlock)
	if (_node.finallyBlock != undefined) _output.finallyBlock = __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.finallyBlock)
	
    return method(_output, __GMLCexecuteTryCatchFinally);
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
		array_push(argCountMemory, _arg_count)
    }
	
	//remember how many the function had
	prevArgCount = _arg_count;
	
	//avoids garbage collection lag spikes
	array_resize(arguments, argumentCount);
	var _i=argumentCount-1; repeat(argumentCount) {
		arguments[_i] = argumentExpressions[_i]();
	_i--}
	
	var _return = undefined;
	if (is_method(_func)) {
		if (is_gmlc_program(_func))
		|| (is_gmlc_method(_func)) {
			var _struct = {};
			var _args = arguments;
			
			var _prevOther = global.otherInstance;
			var _prevSelf  = global.selfInstance;
			global.otherInstance = (is_gmlc_method(_func)) ? (__method_get_self(_func) ?? global.selfInstance) : global.selfInstance;
			global.selfInstance = _struct;
			
			//this with statement isn't needed, in the future we will already know if the constructor will have a parent
			// to a native function, in which case we can simply if/else into a with statement if needed,
			// we shouldnt need to do this
			//with (_struct) {
				var _return = method_call(_func, _args)
			//}
			
			global.otherInstance = _prevOther;
			global.selfInstance  = _prevSelf;
		}
		else {
			var _args = arguments;
			with (global.otherInstance) with (global.selfInstance) {
				var _struct = constructor_call_ext(_func, _args);
			}
		}
	}
	else {
		var _args = arguments;
		with (global.otherInstance) with (global.selfInstance) {
			var _struct = constructor_call_ext(_func, _args);
		}
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
	
	return _struct;
	
}
function __GMLCcompileNewExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileNewExpression", "<Missing Error Message>", _node.line, _node.lineString);
	_output.callee = __GMLCcompileExpression(_rootNode, _parentNode, _node.expression.callee);
	_output.calleeName = _node.expression.callee.name; // this is actually unneeded, but we would still like to have it for debugging
	
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
    
    return method(_output, __GMLCexecuteNewExpression);
}
#region //{
// used to inform gmlc that a break has occured
//    no data needed
//}
#endregion
function __GMLCexecuteBreak() {
    parentNode.shouldBreak = true;
}
function __GMLCcompileBreak(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileBreak", "<Missing Error Message>", _node.line, _node.lineString);
	
    return method(_output, __GMLCexecuteBreak);
}
#region //{
// used to inform gmlc that a continue has occured
//    no data needed
//}
#endregion
function __GMLCexecuteContinue() {
    parentNode.shouldContinue = true;
}
function __GMLCcompileContinue(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileContinue", "<Missing Error Message>", _node.line, _node.lineString);
	
    return method(_output, __GMLCexecuteContinue);
}
#region //{
// used to inform gmlc that an exit has occured
//    no data needed
//}
#endregion
function __GMLCexecuteExit() {
    parentNode.shouldReturn = true;
    parentNode.returnValue = undefined;
}
function __GMLCcompileExit(_rootNode, _parentNode, _node) {
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileExit", "<Missing Error Message>", _node.line, _node.lineString);
	
    return method(_output, __GMLCexecuteExit);
}
#region //{
// used to inform gmlc that an exit has occured
//    expression: <expression>
//}
#endregion
function __GMLCexecuteReturn() {
    parentNode.returnValue = expression();
	parentNode.shouldReturn = true;
}
function __GMLCcompileReturn(_rootNode, _parentNode, _node) {
	if (_node.expr == undefined) {
		return __GMLCcompileExit(_rootNode, _parentNode, _node);
	}
	
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileReturn", "<Missing Error Message>", _node.line, _node.lineString);
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr)
	
    return method(_output, __GMLCexecuteReturn);
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileLiteralExpression", "<Missing Error Message>", _node.line, _node.lineString);
	_output.value = _node.value;
    
    
    return method(_output, __GMLCexecuteLiteralExpression);
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
	
	var _return = undefined;
	if (is_method(_func)) {
		if (is_gmlc_program(_func))
		|| (is_gmlc_method(_func)) {
			_return = method_call(_func, arguments);
		}
		else {
			
			var _self = method_get_self(_func);
			var _args = arguments;
			
			var _prevOther = global.otherInstance;
			var _prevSelf  = global.selfInstance;
			global.otherInstance = _prevSelf;
			global.selfInstance = _self;
			
			with (_prevSelf) {
				_return = method_call(_func, _args);
			}
		
			global.otherInstance = _prevOther;
			global.selfInstance  = _prevSelf;
		}
	}
	else {
		//try {
			var _args = arguments;
			with (global.otherInstance) with (global.selfInstance) {
				_return = script_execute_ext(_func, _args);
			}
		//}
		//catch(e) {
		//	pprint(e)
		//	var _wait = current_time
		//	while(current_time-_wait < 1_000) {}
		//	throw "fuck you"
		//}
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
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileCallExpression", "<Missing Error Message>", _node.line, _node.lineString);
	_output.callee = __GMLCcompileExpression(_rootNode, _parentNode, _node.callee);
	
	_output.calleeName = (struct_exists(_node.callee, "name")) ? _node.callee.name : "<Call Expression>"
	
	_output.recursionCount = 0; 
	_output.prevArgCount = 0;
	_output.argumentCount = array_length(_node.arguments);
	_output.argumentExpressions = array_create(_output.argumentCount);
	_output.arguments = array_create(_output.argumentCount);
	_output.backupArguments = [];//if the function is recursive stash the arguments back into this array, to<->from
	_output.argCountMemory = [];//this is used to remember how much to pop out of the stashed arguments incase we recurse with differing argument counts
	
	var _argArr = _node.arguments
	var _i=0; repeat(array_length(_argArr)) {
		_output.argumentExpressions[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _argArr[_i])
	_i++}
    
    return method(_output, __GMLCexecuteCallExpression);
}

function __GMLCcompileVariableDeclaration(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileVariableDeclaration", "<Missing Error Message>", _node.line, _node.lineString);
	_output.key = _node.identifier; //this is now unused but we keep it around for crash reports and debugging purposes
	if (_node.scope == ScopeType.LOCAL) {
		_output.locals = _parentNode.locals;
		_output.localsWrittenTo = _parentNode.localsWrittenTo;
		_output.localIndex = _parentNode.localLookUps[$ _output.key];
	}
	else if (_node.scope == ScopeType.GLOBAL) {
		_output.globals = _rootNode.globals;
	}
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr);
	
	return method(_output, __GMLCGetScopeSetter(_node.scope))
	
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
			else {
				_output0.key = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val1);
			}
			var _getter_expression = method(_output0, _getter);
			
			
			
			//compile the additive method
			var _output1 = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Operator", "<Missing Error Message>", _node.line, _node.lineString);
			_output1.left  = _getter_expression;
			_output1.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
			var _expression = method(_output1, _func);
			
			
			//compile the actual method we will be calling
			//compile the getter
			var _output2 = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Setter", "<Missing Error Message>", _node.line, _node.lineString);
			_output2.target     = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.expr);
			_output2.expression = _expression;
			if (_node.left.accessorType == __GMLC_AccessorType.Grid) {
				_output2.keyX = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val1);
				_output2.keyY = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val2);
			}
			else {
				_output2.key = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val1);
			}
			return method(_output2, _setter);
			
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
		var _getter_expression = method(_output, _getter);
		
		//compile the additive method
		var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileAssignmentExpression::Operator", "<Missing Error Message>", _node.line, _node.lineString);
		_output.left  = _getter_expression;
		_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
		var _expression = method(_output, _func);
		
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
		return method(_output, _setter);
	}
	
	throw_gmlc_error($"Couldnt find a proper assignment op for the node type :: {_node.left.type}"+$"\n(line {_node.line}) -\t{_node.lineString}")
}

function __GMLCcompileBinaryExpression(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileBinaryExpression", "<Missing Error Message>", _node.line, _node.lineString);
	_output.left  = __GMLCcompileExpression(_rootNode, _parentNode, _node.left);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
    
    switch (_node.operator) {
		case "==":  return method(_output, __GMLCexecuteOpEqualsEquals     );
		case "!=":  return method(_output, __GMLCexecuteOpNotEquals        );
		case "<":   return method(_output, __GMLCexecuteOpLess             );
		case "<=":  return method(_output, __GMLCexecuteOpLessEquals       );
		case ">":   return method(_output, __GMLCexecuteOpGreater          );
		case ">=":  return method(_output, __GMLCexecuteOpGreaterEquals    );
		case "+":   return method(_output, __GMLCexecuteOpPlus             );
		case "-":   return method(_output, __GMLCexecuteOpMinus            );
		case "*":   return method(_output, __GMLCexecuteOpMultiply         );
		case "/":   return method(_output, __GMLCexecuteOpDivide           );
		case "mod": return method(_output, __GMLCexecuteOpMod              );
		case "div": return method(_output, __GMLCexecuteOpDiv              );
		case "|":   return method(_output, __GMLCexecuteOpBitwiseOR        );
		case "^":   return method(_output, __GMLCexecuteOpBitwiseXOR       );
		case "&":   return method(_output, __GMLCexecuteOpBitwiseAND       );
		case "<<":  return method(_output, __GMLCexecuteOpBitwiseShiftLeft );
		case ">>":  return method(_output, __GMLCexecuteOpBitwiseShiftRight);
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
		case "&&": return method(_output, __GMLCexecuteOpAND);
		case "||": return method(_output, __GMLCexecuteOpOR );
		case "^^": return method(_output, __GMLCexecuteOpXOR);
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
	_output.left  = __GMLCcompileExpression(_rootNode, _parentNode, _left);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _right);
    
    
    return method(_output, __GMLCexecuteOpNullish);
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
		case "!": return method(_output, __GMLCexecuteOpNot          )
		case "-": return method(_output, __GMLCexecuteOpNegate       )
		case "~": return method(_output, __GMLCexecuteOpBitwiseNegate)
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
    var _output = new __GMLC_Function(_rootNode, _parentNode, "__compileTernaryExpression", "<Missing Error Message>", _node.line, _node.lineString);
	_output.condition = __GMLCcompileExpression(_rootNode, _parentNode, _node.condition);
	_output.left = __GMLCcompileExpression(_rootNode, _parentNode, _node.trueExpr);
	_output.right = __GMLCcompileExpression(_rootNode, _parentNode, _node.falseExpr);
    
    
    return method(_output, __GMLCexecuteTernaryExpression);
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
#region Get Target
function __GMLCGetScopeTarget(_scopeType) {
	switch (_scopeType) {
		case ScopeType.GLOBAL:   return __GMLCexecuteTargetGlobal    break;
		case ScopeType.LOCAL:    return __GMLCexecuteTargetVarLocal  break;
		case ScopeType.STATIC:   return __GMLCexecuteTargetVarStatic break;
		case ScopeType.SELF:     return __GMLCexecuteTargetSelf      break;
		case ScopeType.OTHER:    return __GMLCexecuteTargetOther     break;
		case ScopeType.CONST:    return __GMLCexecuteTargetConstant  break;
		case ScopeType.UNIQUE:   return __GMLCexecuteTargetUnique    break;
		default: throw_gmlc_error($"Unsupported scope to be written to :: {_scopeType}");
	}
}
#endregion

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

#region Targeters
#region //{
//}
#endregion
function __GMLCexecuteTargetSelf() {
    return global.selfInstance;
}
#region //{
//}
#endregion
function __GMLCexecuteTargetOther() {
    return global.otherInstance;
}
#region //{
//}
#endregion
function __GMLCexecuteTargetGlobal() {
    return rootNode.globals;
}
#region //{
//}
#endregion
function __GMLCexecuteTargetVarLocal() {
    return parentNode.locals;
}
#region //{
//}
#endregion
function __GMLCexecuteTargetVarStatic() {
    return parentNode.statics;
}
#region //{
//}
#endregion
function __GMLCexecuteTargetUnique() {
    throw_gmlc_error($"Shouldnt be trying to target Unique Scope")
}

#endregion

#region Genaric Getter    -    (These will use expressions instead of literal keys written to the method, for those see fast pass script)
#region //{
// used for natively compiled functions
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecutePropertyGet() {
	return struct_get(target(), key());
}
function __GMLCcompilePropertyGet(_rootNode, _parentNode, _scope, _leftKey, _line, _lineString){
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compilePropertyGet", "<Missing Error Message>", _line, _lineString);	
	_output.key      = _leftKey;
	if (_scope == ScopeType.LOCAL) {
		_output.locals = _parentNode.locals;
		_output.localsWrittenTo = _parentNode.localsWrittenTo;
		_output.localIndex = _parentNode.localLookUps[$ _output.key];
	}
	else if (_scope == ScopeType.GLOBAL) {
		_output.globals = _rootNode.globals;
	}
	return method(_output, __GMLCGetScopeGetter(_scope))
}
#endregion

#region Genaric Setter    -    (These will use expressions instead of literal keys written to the method, for those see fast pass script)
#region //{
// used for natively compiled functions
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecutePropertySet() {
	struct_set(target(), key(), expression());
}
function __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _key, _rightExpression, _line, _lineString){
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__compilePropertySet", "<Missing Error Message>", _line, _lineString);
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
	
	return method(_output, __GMLCGetScopeSetter(_scope))
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
	return method(_output, __GMLCGetScopeGetter(_node.scope))
}

function __GMLCcompileUniqueIdentifier(_rootNode, _parentNode, _node) {
	var _output = new __GMLC_Function(_rootNode, _parentNode, "__GMLCcompileUniqueIdentifier", "<Missing Error Message>", _node.line, _node.lineString);
	_output.key = _node.value
	
	return method(_output, __GMLCexecuteGetPropertyUnique)
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

function __GMLC_Statics() constructor {
	
}
function __GMLC_Constructor_Statics(_construct_name) : __GMLC_Statics() constructor {
	__ = {
		"__@@is_gmlc_constructed@@__": true,
		"__@@gmlc_constructor_name@@__": _construct_name,
	};
	
}

#endregion


