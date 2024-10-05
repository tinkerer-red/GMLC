
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
	//incase the program/script/function is recursive we need to stash the arguments
	var _pre_args = arguments;
	
	//edit our local array
	arguments = array_create(argument_count, undefined);
	var _i=argument_count-1; repeat(argument_count) {
		arguments[_i] = argument[_i];
	_i--}
	
	var _return = program();
	
	arguments = _pre_args;
	//reset variables
	//locals = {};
	//var _return = returnValue;
	//returnValue = undefined;
	//shouldReturn = false;
	//shouldBreak = false;
	//shouldContinue = false;
	
	return _return;
}
function __GMLCcompileProgram(_node, _globalsStruct={"__@@ASSETS@@__":{}}) {
	var _output = {
		compilerBase: "__compileProgram",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		globals: _globalsStruct, // these are optional inputs for future use with compiling a full project folder.
		//statics: {},
		//locals: {},
		
		arguments: [],
		program: undefined,
		
		//returnValue: undefined,
		//shouldReturn: false,
		//shouldBreak: false,
		//shouldContinue: false,
		
	}
	_output.program = __GMLCcompileFunction(_output, _output, _node);
	
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
	
	//incase the program/script/function is recursive we need to stash the arguments
	var _pre_args = arguments;
	var _pre_locals = locals;
	locals = {};
	arguments = array_create(max(argument_count, named_arg_size), undefined);
	
	//edit our local array
	// writing the array backwards is the fastest way to do this apparently.
	var _i=argument_count-1; repeat(argument_count) {
		arguments[_i] = argument[_i];
	_i--}
	
	argumentsDefault();
	
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
	
	arguments = _pre_args;
	locals = _pre_locals;
	
	return _return;
}
function __GMLCcompileFunction(_rootNode, _parentNode, _node) {
	var _output = {
		compilerBase: "__compileFunction",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: undefined, //entering a function call resets the parent node, as this is used for fetching locals
		
		//statics
		staticsExecuted: false,
		statics: {},
		staticsBlock: function(){},
		
		locals: undefined,
		
		arguments: undefined,
		argumentsDefault: undefined,
		named_arg_size: 0,
		
		program: undefined,
		
		returnValue: undefined,
		shouldReturn: false,
		shouldBreak: false,
		shouldContinue: false,
		
	}
	
	_output.parentNode = _output;
	_output.argumentsDefault = __GMLCcompileArgumentList(_rootNode, _output, _node.arguments);
	_output.program = __GMLCcompileBlockStatement(_rootNode, _output, _node.statements);
	_output.named_arg_size = method_get_self(_output.argumentsDefault).size;
	
	
	//ensure it's not a script and actually a function
	if (struct_exists(_node, "StaticVarArray")) {
		//compile all of the static variable functions
		_output.staticsBlock = __GMLCcompileBlockStatement(_rootNode, _output, 
				new ASTBlockStatement(_node.StaticVarArray, undefined, undefined)
		);
	}
	
	return method(_output, __GMLCexecuteFunction)
}

function __GMLCexecuteConstructor() {
	
	//incase the program/script/function is recursive we need to stash the arguments
	var _pre_args = arguments;
	var _pre_locals = locals;
	locals = {};
	arguments = array_create(max(argument_count, named_arg_size), undefined);
	
	//edit our local array
	// writing the array backwards is the fastest way to do this apparently.
	var _i=argument_count-1; repeat(argument_count) {
		arguments[_i] = argument[_i];
	_i--}
	
	argumentsDefault();
	
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
	
	arguments = _pre_args;
	locals = _pre_locals;
	
	return _return;
}
function __GMLCcompileConstructor(_rootNode, _parentNode, _node) {
	var _output = {
		compilerBase: "__compileConstructor",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: undefined, //entering a function call resets the parent node, as this is used for fetching locals
		
		//parent constructor
		hasParentConstructor: false,
		parentConstructorName: undefined,
		parentConstructorCall: undefined,
		
		//statics
		staticsExecuted: false,
		statics: {},
		staticsBlock: undefined,
		
		locals: undefined,
		
		
		arguments: undefined,
		argumentsDefault: undefined,
		named_arg_size: 0,
		
		program: undefined,
		
		returnValue: undefined,
		shouldReturn: false,
		shouldBreak: false,
		shouldContinue: false,
		
	}
	
	_output.parentNode = _output;
	_output.argumentsDefault = __GMLCcompileArgumentList(_rootNode, _output, _node.arguments);
	_output.program = __GMLCcompileBlockStatement(_rootNode, _output, _node.statements);
	_output.named_arg_size = method_get_self(_output.argumentsDefault).size;
	
	//compile all of the static variable functions
	_output.staticsBlock = __GMLCcompileBlockStatement(_rootNode, _output, 
			new ASTBlockStatement(_node.StaticVarArray, undefined, undefined)
	);
	
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
	var _inputLength = array_length(_inputArguments);
	
	var _length = array_length(statements)
	var _i=0; repeat(_length) {
		var _arg = statements[_i]
		if (_arg.index != _i) throw "Why does our index not match our arguments index?"+$"\n(line {line}) -\t{lineString}"
		
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
		
		//apply to the local struct
		parentNode.locals[$ _arg.identifier] = _inputArguments[_i]
		
	_i++}
}
function __GMLCcompileArgumentList(_rootNode, _parentNode, _node) {
	var _output = {
		compilerBase: "__compileArgumentList",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		statements: [],
		size: undefined,
		
		varStatics: {},
		locals: {},
	}
	
	var _arr = _node.statements;
	var _i=0; repeat(array_length(_arr)) {
		_output.statements[_i] = __GMLCcompileArgument(_rootNode, _parentNode, _arr[_i]);
	_i++}
	
	_output.size = array_length(_output.statements);
	
	return method(_output, __GMLCexecuteArgumentList)
}

function __GMLCexecuteArgument() {
	throw "ERROR :: __GMLCexecuteArgument should never actually be run, this should be handled by ArgumentList"
}
function __GMLCcompileArgument(_rootNode, _parentNode, _node) {
	var _output = {
		compilerBase: "__compileArgument",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		index: _node.argument_index,
		identifier: _node.identifier,
		expression: __GMLCcompileExpression(_rootNode, _parentNode, _node.expr)
	}
	
	return _output;
}

function __GMLCexecuteExpression() {};
function __GMLCcompileExpression(_rootNode, _parentNode, _node, _isCondtion=false) {
	//log("\n\n")
	//pprint(_node)
	//log($"TYPE :: {_node.type}\nLINE :: {struct_exists(_node, "lineString") ? _node.lineString : "<undefined>"}\nNODE :: {json_stringify(_node, true)}")
	
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
			throw "not done yet"
		break;}
		case __GMLC_NodeType.Argument:{
			throw "not done yet"
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
		case __GMLC_NodeType.DoUntillStatement:{
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
		
		case __GMLC_NodeType.ThrowExpression: {
			return __GMLCcompileThrow(_rootNode, _parentNode, _node)
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
			throw "There shouldnt be any of these"
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
				
		case __GMLC_NodeType.ArrayPattern:{
			return __GMLCcompileNewArray(_rootNode, _parentNode, _node.elements)
		break;}
		case __GMLC_NodeType.StructPattern:{
			return __GMLCcompileNewStruct(_rootNode, _parentNode, _node.arguments.statements)
		break;}
		case __GMLC_NodeType.Literal:{
			return __GMLCcompileLiteralExpression(_rootNode, _parentNode, _node.value);
		break;}
		case __GMLC_NodeType.Identifier:{
			return __GMLCcompileIdentifier(_rootNode, _parentNode, _node.scope, _node.value, _node.line, _node.lineString)
		break;}
				
		case __GMLC_NodeType.UniqueIdentifier:{
			return __GMLCcompileUniqueIdentifier(_rootNode, _parentNode, _node.scope, _node.value)
		break;}
				
		case __GMLC_NodeType.AccessorExpression:{
			return __GMLCcompileAccessor(_rootNode, _parentNode, _node)
		break;}
				
		case __GMLC_NodeType.Function:{
			return __GMLCcompileLiteralExpression(_rootNode, _parentNode, _node.value);
		break;}
		/*
		case __GMLC_NodeType.PropertyAccessor:{
			throw $"\n{currentNode.type} :: Not implimented yet"
		break;}
		case __GMLC_NodeType.AccessorExpression:{
			throw $"\n{currentNode.type} :: Not implimented yet"
		break;}
		case __GMLC_NodeType.MethodVariableConstructor:{
			throw $"\n{currentNode.type} :: Not implimented yet"
		break;}
		case __GMLC_NodeType.MethodVariableFunction:{
			throw $"\n{currentNode.type} :: Not implimented yet"
		break;}
		//*/
		default:
			
			do_trace(json_stringify(_node, true))
			throw $"\nCurrent Node does not have a valid type for the optimizer,\ntype: {_node.type}\ncurrentNode: {json_stringify(_node, true)}"
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
    var _output = {
		compilerBase: "__compileBlockStatement",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		blockStatements: [],
		size: undefined,
    }
	
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
		//return an empty function so we dont need to enter a method
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
    var _output = {
		compilerBase: "__compileBlockStatementBreakable",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		blockStatements: [],
		size: undefined,
    }
	
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
    var _output = {
		compilerBase: "__compileLoopStatementEndless",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		blockStatements: __GMLCcompileExpression(_rootNode, _parentNode, _blockStatement),
    }
    
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
    var _output = {
		compilerBase: "__compileLoopStatement",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		blockStatements: [],
		size: undefined,
    }
	
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
	var _output = {
		compilerBase: "__compileIf",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		condition: __GMLCcompileExpression(_rootNode, _parentNode, _node.condition),
		trueBlock: __GMLCcompileExpression(_rootNode, _parentNode, _node.consequent),
    }
    
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
    var _output = {
		compilerBase: "__compileRepeat",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		condition: __GMLCcompileExpression(_rootNode, _parentNode, _node.condition),
		blockStatement: __GMLCcompileLoopStatement(_rootNode, _parentNode, _node.codeBlock),
    }
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
    var _output = {
		compilerBase: "__compileWhile",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		condition: __GMLCcompileExpression(_rootNode, _parentNode, _node.condition),
		blockStatement: __GMLCcompileLoopStatement(_rootNode, _parentNode, _node.codeBlock),
    }
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
    var _output = {
		compilerBase: "__compileDoUntil",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		condition: __GMLCcompileExpression(_rootNode, _parentNode, _node.condition),
		blockStatement: __GMLCcompileLoopStatement(_rootNode, _parentNode, _node.codeBlock),
    }
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
    var _output = {
		compilerBase: "__compileFor",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		assignment: __GMLCcompileExpression(_rootNode, _parentNode, _node.initialization),
		condition: __GMLCcompileExpression(_rootNode, _parentNode, _node.condition),
		operation: __GMLCcompileExpression(_rootNode, _parentNode, _node.increment),
		blockStatement: __GMLCcompileLoopStatement(_rootNode, _parentNode, _node.codeBlock),
    }
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
	var _output = {
		compilerBase: "__compileSwitch",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		expression: __GMLCcompileExpression(_rootNode, _parentNode, _node.switchExpression),
		cases: [],
		caseDefault: undefined,
		size: 0,
    }
    
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
    throw "This code should be unreachable"
}
function __GMLCcompileCase(_rootNode, _parentNode, _node) {
    var _output = {
		compilerBase: "__compileCase",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		isDefault: (_node.label == undefined),
		expression: (_node.label == undefined) ? undefined : __GMLCcompileExpression(_rootNode, _parentNode, _node.label),
		blockStatement: __GMLCcompileBlockStatementBreakable(_rootNode, _parentNode, _node.codeBlock),
    }
    
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
    
    ///NOTE: count how many objects, or valid `with` instances there are, then itterate through them all
    var _validInstances = [];
    with (_inst) {
		array_push(_validInstances, self);
	}
	
    var _i=0; repeat(array_length(_validInstances)) {
		global.selfInstance = _validInstances[_i];
		
		blockStatement();
		
		//we break on all three cases here because we would like to run the
		// rest of the function to return to our previous self/other
		if (parentNode.shouldReturn) break;
		if (parentNode.shouldBreak) {
		    parentNode.shouldBreak = false;
		    break;
		}
		if (parentNode.shouldContinue) {
		    parentNode.shouldContinue = false;
		    //no need to break or continue we will already be doing that
		}
    _i++}
    
    
    
    //reset
    global.selfInstance = _self;
    global.otherInstance = _other;
}
function __GMLCcompileWith(_rootNode, _parentNode, _node) {
    var _output = {
		compilerBase: "__compileWith",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		expression: __GMLCcompileExpression(_rootNode, _parentNode, _node.condition),
		blockStatement: __GMLCcompileLoopStatement(_rootNode, _parentNode, _node.codeBlock),
    }
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
			parentNode.locals[$ catchVariableName] = _e
			catchBlock()
		}
    }
    
	if (finallyBlock != undefined) {
		finallyBlock();
	}
}
function __GMLCcompileTryCatchFinally(_rootNode, _parentNode, _node) {
    var _output = {
		compilerBase: "__compileTryCatchFinally",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		tryBlock: __GMLCcompileLoopStatement(_rootNode, _parentNode, _node.tryBlock),
		catchVariableName: _node.exceptionVar,
		catchBlock: undefined,
		finallyBlock: undefined,
    }
	
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
	
	var _argArray = array_map(argArr, function(_elem, _index){
		return _elem();
	});
	
	if (is_method(_func)) {
		if (is_gmlc_progam(_func)) {
			if (is_gmlc_method(_func)) {
				throw "target function for 'new' must be a constructor, this one is a gmlc method"+$"\n(line {line}) -\t{lineString}"
			}
			
			var _struct = {};
			
			var _prevOther = global.otherInstance;
			var _prevSelf  = global.selfInstance;
			global.otherInstance = global.selfInstance;
			global.selfInstance = _struct;
			
			var _return = method_call(_func, _argArray);
		
			global.otherInstance = _prevOther;
			global.selfInstance  = _prevSelf;
		}
		else {
			throw "target function for 'new' must be a constructor, this one is a method"+$"\n(line {line}) -\t{lineString}"
		}
	}
	else {
		with (global.otherInstance) with (global.selfInstance) {
			var _struct = constructor_call_ext(_func, _argArray);
		}
	}
	
	return _struct;
	
}
function __GMLCcompileNewExpression(_rootNode, _parentNode, _node) {
	var _output = {
		compilerBase: "__compileNewExpression",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		callee: __GMLCcompileExpression(_rootNode, _parentNode, _node.expression.callee),
		calleeName: _node.expression.callee.name,// this is actually unneeded, but we would still like to have it for debugging
		argArr: [],
		size: 0,
    }
	
	var _argArr = _node.expression.arguments
	var _i=0; repeat(array_length(_argArr)) {
		_output.argArr[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _argArr[_i])
		_output.size++;
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
    var _output = {
		compilerBase: "__compileBreak",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
    }
    
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
    var _output = {
		compilerBase: "__compileContinue",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
    }
    
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
    var _output = {
		compilerBase: "__compileExit",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
    }
    
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
	
	var _output = {
		compilerBase: "__compileReturn",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		expression: undefined, //defined below
    }
	
	_output.expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr)
	
    return method(_output, __GMLCexecuteReturn);
}
#region //{
// used to execute gmlc compiled `throw` statement
//    expression: <exprettion> // expects a string as result
//}
#endregion
function __GMLCexecuteThrow() {
	throw expression()+$"\n(line {line}) -\t{lineString}"
}
function __GMLCcompileThrow(_rootNode, _parentNode, _node) {
    var _output = {
		compilerBase: "__compileThrow",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		expression: __GMLCcompileExpression(_rootNode, _parentNode, _node.error),
    }
    
    return method(_output, __GMLCexecuteThrow);
}


#endregion

#region Expressions

#region //{
// used to build a new array
//    expressionsArray: array<expressions>
//    size: array_length(expressionsArray),
//}
#endregion
function __GMLCexecuteNewArray() {
    var _arr = array_create(size);
    var _i=0; repeat(size) {
		_arr[_i] = expressionsArray[_i]();
    _i++}
    return _arr;
}
function __GMLCcompileNewArray(_rootNode, _parentNode, _expressionsArray, _line, _lineString) {
    var _output = {
		compilerBase: "__compileNewArray",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		expressionsArray: [],
		size: undefined,
    }
    
    var _i=0; repeat(array_length(_expressionsArray)) {
		_output.expressionsArray[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _expressionsArray[_i]);
    _i++}
    
    _output.size = array_length(_output.expressionsArray)
    
    return method(_output, __GMLCexecuteNewArray);
}

#region //{
// used to build a new array
//    array: array<expressions>
//    size: array_length(expressionsArray) / 2,
//}
#endregion
function __GMLCexecuteNewStruct() {
    var _struct = {}
    var _i=0; repeat(size/2) {
		var _key = array[_i];
		var _value = array[_i+1];
		struct_set(_struct, _key(), _value())
    _i+=2}
    return _struct;
}
function __GMLCcompileNewStruct(_rootNode, _parentNode, _arr, _line, _lineString) {
    var _output = {
		compilerBase: "__compileNewStruct",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		array: [],
		size: undefined,
    }
    
    var _i=0; repeat(array_length(_arr)) {
		//should probably all be literal strings, but i dont care otherwise
		_output.array[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _arr[_i])
    _i++}
    
    _output.size = array_length(_output.array)
    
    return method(_output, __GMLCexecuteNewStruct);
}

#region //{
// used to fetch Literal values
//    value: <any>,
//}
#endregion
function __GMLCexecuteLiteralExpression() {
    return value;
}
function __GMLCcompileLiteralExpression(_rootNode, _parentNode, _value, _line, _lineString) {
    var _output = {
		compilerBase: "__compileLiteralExpression",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		value: _value,
    }
    
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
	
	var _argArray = array_map(argArr, function(_elem, _index){
		return _elem();
	});
	
	if (is_method(_func)) {
		if (is_gmlc_progam(_func)) {
			var _return = method_call(_func, _argArray);
		}
		else {
			
			var _self = method_get_self(_func);
		
			var _prevOther = global.otherInstance;
			var _prevSelf  = global.selfInstance;
			global.otherInstance = global.selfInstance;
			global.selfInstance = _self;
			
			with (global.otherInstance) {
				var _return = method_call(_func, _argArray);
			}
		
			global.otherInstance = _prevOther;
			global.selfInstance  = _prevSelf;
		}
	}
	else {
		with (global.otherInstance) with (global.selfInstance) {
			var _return = script_execute_ext(_func, _argArray);
		}
	}
	
	return _return;
}
function __GMLCcompileCallExpression(_rootNode, _parentNode, _node) {
	var _output = {
		compilerBase: "__compileCallExpression",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		callee: __GMLCcompileExpression(_rootNode, _parentNode, _node.callee),
		calleeName: _node.callee.name,// this is actually unneeded, but we would still like to have it for debugging
		argArr: [],
		size: 0,
    }
	
	var _argArr = _node.arguments
	var _i=0; repeat(array_length(_argArr)) {
		_output.argArr[_i] = __GMLCcompileExpression(_rootNode, _parentNode, _argArr[_i])
		_output.size++;
	_i++}
    
    return method(_output, __GMLCexecuteCallExpression);
}

function __GMLCcompileVariableDeclaration(_rootNode, _parentNode, _node) {
	var _identifier = __GMLCcompileLiteralExpression(_rootNode, _parentNode, _node.identifier);
	var _expr = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr)
	return __GMLCcompilePropertySet(_rootNode, _parentNode, _node.scope, _identifier, _expr, _node.line, _node.lineString);
}
function __GMLCcompileVariableDeclarationList(_rootNode, _parentNode, _node) {
	return __GMLCcompileBlockStatement(_rootNode, _parentNode, _node.statements)
}

#endregion

#region Math Expressions

function __GMLCcompileAssignmentExpression(_rootNode, _parentNode, _node) {
	if (_node.left.type == __GMLC_NodeType.AccessorExpression) {
		var _target = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.expr);
		var _key = __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val1);
		var _expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
		
		if (_node.operator == "=") {
			switch (_node.left.accessorType) {
				case __GMLC_AccessorType.Array:  return __GMLCcompileArraySet       (_rootNode, _parentNode, _target, _key, _expression, _node.line, _node.lineString);
				case __GMLC_AccessorType.Grid:   return __GMLCcompileGridSet		(_rootNode, _parentNode, _target, _key, __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val2), _expression, _node.line, _node.lineString);
				case __GMLC_AccessorType.List:   return __GMLCcompileListSet		(_rootNode, _parentNode, _target, _key, _expression, _node.line, _node.lineString);
				case __GMLC_AccessorType.Map:    return __GMLCcompileMapSet		    (_rootNode, _parentNode, _target, _key, _expression, _node.line, _node.lineString);
				case __GMLC_AccessorType.Struct: return __GMLCcompileStructSet      (_rootNode, _parentNode, _target, _key, _expression, _node.line, _node.lineString);
				case __GMLC_AccessorType.Dot:    return __GMLCcompileStructDotAccSet(_rootNode, _parentNode, _target, _key, _expression, _node.line, _node.lineString);
			}
		}
		else {
			var _opToCompile = undefined
			switch (_node.operator) {
				case "+=":  _opToCompile = __GMLCcompileOpPlus;
				case "-=":  _opToCompile = __GMLCcompileOpMinus;
				case "*=":  _opToCompile = __GMLCcompileOpMultiply;
				case "/=":  _opToCompile = __GMLCcompileOpDivide;
				case "^=":  _opToCompile = __GMLCcompileOpBitwiseXOR;
				case "&=":  _opToCompile = __GMLCcompileOpBitwiseAND;
				case "|=":  _opToCompile = __GMLCcompileOpBitwiseOR;
				case "??=": _opToCompile = __GMLCcompileOpNullish;
			}
			
			switch (_node.left.accessorType) {
				case __GMLC_AccessorType.Array:  return __GMLCcompileArraySet       (_rootNode, _parentNode, _target, _key, _opToCompile(_rootNode, _parentNode, __GMLCcompileArrayGet       (_rootNode, _parentNode, _target, _key), _expression))
				case __GMLC_AccessorType.Grid:   return __GMLCcompileGridSet		(_rootNode, _parentNode, _target, _key, __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val2), _opToCompile(_rootNode, _parentNode, __GMLCcompileGridGet		(_rootNode, _parentNode, _target, _key, __GMLCcompileExpression(_rootNode, _parentNode, _node.left.val2)), _expression))
				case __GMLC_AccessorType.List:   return __GMLCcompileListSet		(_rootNode, _parentNode, _target, _key, _opToCompile(_rootNode, _parentNode, __GMLCcompileListGet		(_rootNode, _parentNode, _target, _key), _expression))
				case __GMLC_AccessorType.Map:    return __GMLCcompileMapSet		 (_rootNode, _parentNode, _target, _key, _opToCompile(_rootNode, _parentNode, __GMLCcompileMapGet		 (_rootNode, _parentNode, _target, _key), _expression))
				case __GMLC_AccessorType.Struct: return __GMLCcompileStructSet      (_rootNode, _parentNode, _target, _key, _opToCompile(_rootNode, _parentNode, __GMLCcompileStructGet      (_rootNode, _parentNode, _target, _key), _expression))
				case __GMLC_AccessorType.Dot:    return __GMLCcompileStructDotAccSet(_rootNode, _parentNode, _target, _key, _opToCompile(_rootNode, _parentNode, __GMLCcompileStructDotAccGet(_rootNode, _parentNode, _target, _key), _expression))
			}
		}
	}
	
	if (_node.left.type == __GMLC_NodeType.Identifier) {
		var _key = __GMLCcompileLiteralExpression(_rootNode, _parentNode, _node.left.value);
		var _expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
		switch (_node.operator) {
			case "=":   return __GMLCcompilePropertySet           (_rootNode, _parentNode, _node.left.scope, _key, _expression, _node.line, _node.lineString); break;
			case "+=":  return __GMLCcompileOpAssignmentPlus      (_rootNode, _parentNode, _node.left.scope, _key, _expression, _node.line, _node.lineString); break;
			case "-=":  return __GMLCcompileOpAssignmentMinus     (_rootNode, _parentNode, _node.left.scope, _key, _expression, _node.line, _node.lineString); break;
			case "*=":  return __GMLCcompileOpAssignmentMultiply  (_rootNode, _parentNode, _node.left.scope, _key, _expression, _node.line, _node.lineString); break;
			case "/=":  return __GMLCcompileOpAssignmentDivide    (_rootNode, _parentNode, _node.left.scope, _key, _expression, _node.line, _node.lineString); break;
			case "^=":  return __GMLCcompileOpAssignmentBitwiseXOR(_rootNode, _parentNode, _node.left.scope, _key, _expression, _node.line, _node.lineString); break;
			case "&=":  return __GMLCcompileOpAssignmentBitwiseAND(_rootNode, _parentNode, _node.left.scope, _key, _expression, _node.line, _node.lineString); break;
			case "|=":  return __GMLCcompileOpAssignmentBitwiseOR (_rootNode, _parentNode, _node.left.scope, _key, _expression, _node.line, _node.lineString); break;
			case "??=": return __GMLCcompileOpAssignmentNullish   (_rootNode, _parentNode, _node.left.scope, _key, _expression, _node.line, _node.lineString); break;
		}
	}
	
	throw $"Couldnt find a proper assignment op for the node type :: {_node.left.type}"+$"\n(line {line}) -\t{lineString}"
}
#region Assignment Expressions
function __GMLCcompileOpAssignmentPlus(_rootNode, _parentNode, _scope, _leftKey, _rightExpression, _line, _lineString) {
	return __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _leftKey, __GMLCcompileOpPlus(_rootNode, _parentNode, __GMLCcompilePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression), _line, _lineString)
}
function __GMLCcompileOpAssignmentMinus(_rootNode, _parentNode, _scope, _leftKey, _rightExpression, _line, _lineString) {
	return __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _leftKey, __GMLCcompileOpMinus(_rootNode, _parentNode, __GMLCcompilePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression), _line, _lineString)
}
function __GMLCcompileOpAssignmentMultiply(_rootNode, _parentNode, _scope, _leftKey, _rightExpression, _line, _lineString) {
	return __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _leftKey, __GMLCcompileOpMultiply(_rootNode, _parentNode, __GMLCcompilePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression), _line, _lineString)
}
function __GMLCcompileOpAssignmentDivide(_rootNode, _parentNode, _scope, _leftKey, _rightExpression, _line, _lineString){
	return __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _leftKey, __GMLCcompileOpDivide(_rootNode, _parentNode, __GMLCcompilePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression), _line, _lineString)
}
function __GMLCcompileOpAssignmentBitwiseXOR(_rootNode, _parentNode, _scope, _leftKey, _rightExpression, _line, _lineString){
	return __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _leftKey, __GMLCcompileOpBitwiseXOR(_rootNode, _parentNode, __GMLCcompilePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression), _line, _lineString)
}
function __GMLCcompileOpAssignmentBitwiseAND(_rootNode, _parentNode, _scope, _leftKey, _rightExpression, _line, _lineString){
	return __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _leftKey, __GMLCcompileOpBitwiseAND(_rootNode, _parentNode, __GMLCcompilePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression), _line, _lineString)
}
function __GMLCcompileOpAssignmentBitwiseOR(_rootNode, _parentNode, _scope, _leftKey, _rightExpression, _line, _lineString){
	return __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _leftKey, __GMLCcompileOpBitwiseOR(_rootNode, _parentNode, __GMLCcompilePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression), _line, _lineString)
}
function __GMLCcompileOpAssignmentNullish(_rootNode, _parentNode, _scope, _leftKey, _rightExpression, _line, _lineString){
	return __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _leftKey, __GMLCcompileOpNullish(_rootNode, _parentNode, __GMLCcompilePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression), _line, _lineString)
}

#endregion

function __GMLCcompileBinaryExpression(_rootNode, _parentNode, _node) {
	var _leftExpression = __GMLCcompileExpression(_rootNode, _parentNode, _node.left);
	var _rightExpression = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
	
	switch (_node.operator) {
		case "==":  return __GMLCcompileOpEqualsEquals     (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "!=":  return __GMLCcompileOpNotEquals        (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "<":   return __GMLCcompileOpLess             (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "<=":  return __GMLCcompileOpLessEquals       (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case ">":   return __GMLCcompileOpGreater          (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case ">=":  return __GMLCcompileOpGreaterEquals    (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "+":   return __GMLCcompileOpPlus             (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "-":   return __GMLCcompileOpMinus            (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "*":   return __GMLCcompileOpMultiply         (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "/":   return __GMLCcompileOpDivide           (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "mod": return __GMLCcompileOpMod              (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "div": return __GMLCcompileOpDiv              (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "|":   return __GMLCcompileOpBitwiseOR        (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "^":   return __GMLCcompileOpBitwiseXOR       (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "&":   return __GMLCcompileOpBitwiseAND       (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "<<":  return __GMLCcompileOpBitwiseShiftLeft (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case ">>":  return __GMLCcompileOpBitwiseShiftRight(_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
	}
}
#region Binary Expressions
#region Equality Ops
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpEqualsEquals() {
    return left() == right();
}
function __GMLCcompileOpEqualsEquals(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpEqualsEquals",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpEqualsEquals);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpNotEquals() {
    return left() != right();
}
function __GMLCcompileOpNotEquals(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpNotEquals",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpNotEquals);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpLess() {
    return left() < right();
}
function __GMLCcompileOpLess(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpLess",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpLess);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpLessEquals() {
    return left() <= right();
}
function __GMLCcompileOpLessEquals(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpLessEquals",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpLessEquals);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpGreater() {
    return left() > right();
}
function __GMLCcompileOpGreater(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpGreater",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpGreater);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpGreaterEquals() {
    return left() >= right();
}
function __GMLCcompileOpGreaterEquals(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpGreaterEquals",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpGreaterEquals);
}
#endregion
#region Basic Ops
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpPlus() {
	return left() + right();
}
function __GMLCcompileOpPlus(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpPlus",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
	return method(_output, __GMLCexecuteOpPlus);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpMinus() {
    var _left = left();
	var _right = right();
	return left() - right();
}
function __GMLCcompileOpMinus(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpMinus",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpMinus);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpMultiply() {
	return left() * right();
}
function __GMLCcompileOpMultiply(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpMultiply",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpMultiply);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpDivide() {
    return left() / right();
}
function __GMLCcompileOpDivide(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpDivide",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpDivide);
}

#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpDiv() {
    return left() div right();
}
function __GMLCcompileOpDiv(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpDiv",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpDiv);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpMod() {
    return left() mod right();
}
function __GMLCcompileOpMod(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpMod",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpMod);
}
#endregion
#region Bitwise Ops
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpBitwiseOR() {
    return left() | right();
}
function __GMLCcompileOpBitwiseOR(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpBitwiseOR",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpBitwiseOR);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpBitwiseAND() {
    return left() & right();
}
function __GMLCcompileOpBitwiseAND(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpBitwiseAND",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpBitwiseAND);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpBitwiseXOR() {
    return left() ^ right();
}
function __GMLCcompileOpBitwiseXOR(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpBitwiseXOR",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpBitwiseXOR);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpBitwiseShiftLeft() {
    return left() << right();
}
function __GMLCcompileOpBitwiseShiftLeft(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpBitwiseShiftLeft",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpBitwiseShiftLeft);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpBitwiseShiftRight() {
    return left() >> right();
}
function __GMLCcompileOpBitwiseShiftRight(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpBitwiseShiftRight",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpBitwiseShiftRight);
}
#endregion
#endregion

function __GMLCcompileLogicalExpression(_rootNode, _parentNode, _node) {
	var _leftExpression = __GMLCcompileExpression(_rootNode, _parentNode, _node.left);
	var _rightExpression = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
	
	switch (_node.operator) {
		case "&&": return __GMLCcompileOpAND(_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "||": return __GMLCcompileOpOR (_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
		case "^^": return __GMLCcompileOpXOR(_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
	}
}
#region Logical Expressions
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpAND() {
    return left() && right();
}
function __GMLCcompileOpAND(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpAND",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpAND);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpOR() {
    return left() || right();
}
function __GMLCcompileOpOR(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpOR",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpOR);
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpXOR() {
    return left() ^^ right();
}
function __GMLCcompileOpXOR(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpXOR",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpXOR);
}

#endregion

function __GMLCcompileNullishExpression(_rootNode, _parentNode, _node) {
	var _leftExpression = __GMLCcompileExpression(_rootNode, _parentNode, _node.left);
	var _rightExpression = __GMLCcompileExpression(_rootNode, _parentNode, _node.right);
	
	
	return __GMLCcompileOpNullish(_rootNode, _parentNode, _leftExpression, _rightExpression, _node.line, _node.lineString);
}
#region Nullish Expressions
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __GMLCexecuteOpNullish() {
    return left() ?? right();
}
function __GMLCcompileOpNullish(_rootNode, _parentNode, _leftExpression, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpNullish",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpNullish);
}

#endregion

function __GMLCcompileUnaryExpression(_rootNode, _parentNode, _node) {
	var _expression = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr);
	
	switch (_node.operator) {
		case "!": return __GMLCcompileOpNot          (_rootNode, _parentNode, _expression, _node.line, _node.lineString)
		case "-": return __GMLCcompileOpNegate       (_rootNode, _parentNode, _expression, _node.line, _node.lineString)
		case "~": return __GMLCcompileOpBitwiseNegate(_rootNode, _parentNode, _expression, _node.line, _node.lineString)
		case "+": return _expression;
		//case "++": __GMLC_ break;
		//case "--": __GMLC_ break;
	}
}
#region Unary Expressions
#region //{
//    left: <expression>,
//}
#endregion
function __GMLCexecuteOpNot() {
    return !right();
}
function __GMLCcompileOpNot(_rootNode, _parentNode, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpNot",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpNot);
}
#region //{
//    left: <expression>,
//}
#endregion
function __GMLCexecuteOpNegate() {
    return -right();
}
function __GMLCcompileOpNegate(_rootNode, _parentNode, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpNegate",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpNegate);
}
#region //{
//    left: <expression>,
//}
#endregion
function __GMLCexecuteOpBitwiseNegate() {
    return ~right();
}
function __GMLCcompileOpBitwiseNegate(_rootNode, _parentNode, _rightExpression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileOpBitwiseNegate",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		right: _rightExpression,
    }
    
    return method(_output, __GMLCexecuteOpBitwiseNegate);
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
    var _output = {
		compilerBase: "__compileTernaryExpression",
		errorMessage: "<Missing Error Message>",
		line: _node.line, //used for debugging
		lineString: _node.lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		condition: __GMLCcompileExpression(_rootNode, _parentNode, _node.condition),
		left: __GMLCcompileExpression(_rootNode, _parentNode, _node.trueExpr),
		right: __GMLCcompileExpression(_rootNode, _parentNode, _node.falseExpr),
    }
    
    return method(_output, __GMLCexecuteTernaryExpression);
}

function __GMLCcompileUpdateExpression(_rootNode, _parentNode, _node) {
	if (_node.expr.type == __GMLC_NodeType.Identifier) {
		
		var _target = __GMLCgetScopeTarget(_node.expr.scope)
		var _key = _node.expr.value;
		var _increment = (_node.operator == "++") ? true : false;
		var _prefix = _node.prefix;
		
		return __GMLCcompileUpdateStructDotAcc(_rootNode, _parentNode, _target, _key, _increment, _prefix, _node.line, _node.lineString)
	}
	else if (_node.expr.type == __GMLC_NodeType.AccessorExpression) {
		
		var _target = __GMLCcompileExpression(_rootNode, _parentNode, _node.expr)
		var _key = __GMLCcompileExpression(_rootNode, _parentNode, _node.val1)
		var _increment = (_node.operator == "++") ? true : false;
		var _prefix = _node.prefix;
		
		switch (_node.expr.accessorType) {
			case __GMLC_AccessorType.Array:  return __GMLCcompileUpdateArray       (_rootNode, _parentNode, _target, _key, _increment, _prefix, _node.line, _node.lineString);
			case __GMLC_AccessorType.Grid:   return __GMLCcompileUpdateGrid		(_rootNode, _parentNode, _target, _key, __GMLCcompileExpression(_rootNode, _parentNode, _node.val2), _increment, _prefix, _node.line, _node.lineString);
			case __GMLC_AccessorType.List:   return __GMLCcompileUpdateList		(_rootNode, _parentNode, _target, _key, _increment, _prefix, _node.line, _node.lineString);
			case __GMLC_AccessorType.Map:    return __GMLCcompileUpdateMap		 (_rootNode, _parentNode, _target, _key, _increment, _prefix, _node.line, _node.lineString);
			case __GMLC_AccessorType.Struct: return __GMLCcompileUpdateStruct      (_rootNode, _parentNode, _target, _key, _increment, _prefix, _node.line, _node.lineString);
			case __GMLC_AccessorType.Dot:    return __GMLCcompileUpdateStructDotAcc(_rootNode, _parentNode, _target, _key, _increment, _prefix, _node.line, _node.lineString);
		}
		
	}
	
	throw $"how did we get here?\nwhat expression are we working with?\n{_node.expr}"+$"\n(line {line}) -\t{lineString}"
	
}
#region Updaters (++ and --)
#region //{
//    getter: <expression>,
//    setter: <expression>,
//}
#endregion
function __GMLCexecuteOpPlusPlusPrefix() {
	var _val = getter()+1;
	setter(_val);
	return _val;
}
#region //{
//    getter: <expression>,
//    setter: <expression>,
//}
#endregion
function __GMLCexecuteOpMinusMinusPrefix() {
	var _val = getter()-1;
	setter(_val);
	return _val;
}
#region //{
//    getter: <expression>,
//    setter: <expression>,
//}
#endregion
function __GMLCexecuteOpPlusPlusPostfix() {
	var _val = getter();
	setter(_val+1);
	return _val;
}
#region //{
//    getter: <expression>,
//    setter: <expression>,
//}
#endregion
function __GMLCexecuteOpMinusMinusPostfix() {
	var _val = getter();
	setter(_val-1);
	return _val;
}

#region Arrays
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteUpdateArrayPlusPlusPrefix() {
	var _target = target();
	return ++_target[key()];
}
function __GMLCexecuteUpdateArrayPlusPlusPostfix() {
	var _target = target();
	return _target[key()]++;
}
function __GMLCexecuteUpdateArrayMinusMinusPrefix() {
	var _target = target();
	return --_target[key()];
}
function __GMLCexecuteUpdateArrayMinusMinusPostfix() {
	var _target = target();
	return _target[key()]--;
}
function __GMLCcompileUpdateArray(_rootNode, _parentNode, _targetExpression, _keyExpression, _increment, _prefix, _line, _lineString) {
    var _output = {
		compilerBase: "__compileUpdateArray",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _targetExpression,
		key: _keyExpression,
    }
    
	if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateArrayPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateArrayPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateArrayMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateArrayMinusMinusPostfix);
}
#endregion
#region List
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteUpdateListPlusPlusPrefix() {
	var _target = target();
	return ++_target[| key()];
}
function __GMLCexecuteUpdateListPlusPlusPostfix() {
	var _target = target();
	return _target[| key()]++;
}
function __GMLCexecuteUpdateListMinusMinusPrefix() {
	var _target = target();
	return --_target[| key()];
}
function __GMLCexecuteUpdateListMinusMinusPostfix() {
	var _target = target();
	return _target[| key()]--;
}
function __GMLCcompileUpdateList(_rootNode, _parentNode, _targetExpression, _keyExpression, _increment, _prefix, _line, _lineString) {
    var _output = {
		compilerBase: "__compileUpdateList",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _targetExpression,
		key: _keyExpression,
    }
    
	if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateListPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateListPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateListMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateListMinusMinusPostfix);
}
#endregion
#region Map
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteUpdateMapPlusPlusPrefix() {
	var _target = target();
	return ++_target[? key()];
}
function __GMLCexecuteUpdateMapPlusPlusPostfix() {
	var _target = target();
	return _target[? key()]++;
}
function __GMLCexecuteUpdateMapMinusMinusPrefix() {
	var _target = target();
	return --_target[? key()];
}
function __GMLCexecuteUpdateMapMinusMinusPostfix() {
	var _target = target();
	return _target[? key()]--;
}
function __GMLCcompileUpdateMap(_rootNode, _parentNode, _targetExpression, _keyExpression, _increment, _prefix, _line, _lineString) {
    var _output = {
		compilerBase: "__compileUpdateMap",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _targetExpression,
		key: _keyExpression,
    }
    
	if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateMapPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateMapPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateMapMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateMapMinusMinusPostfix);
}
#endregion
#region Grid
#region //{
//    target: <expression>,
//    keyX: <expression>,
//    keyY: <expression>,
//}
#endregion
function __GMLCexecuteUpdateGridPlusPlusPrefix() {
	var _target = target();
	return ++_target[# keyX(), keyY()];
}
function __GMLCexecuteUpdateGridPlusPlusPostfix() {
	var _target = target();
	return _target[# keyX(), keyY()]++;
}
function __GMLCexecuteUpdateGridMinusMinusPrefix() {
	var _target = target();
	return --_target[# keyX(), keyY()];
}
function __GMLCexecuteUpdateGridMinusMinusPostfix() {
	var _target = target();
	return _target[# keyX(), keyY()]--;
}
function __GMLCcompileUpdateGrid(_rootNode, _parentNode, _targetExpression, _keyXExpression, _keyYExpression, _increment, _prefix, _line, _lineString) {
    var _output = {
		compilerBase: "__compileUpdateGrid",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _targetExpression,
		keyX: _keyXExpression,
		keyY: _keyYExpression,
    }
    
    if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateGridPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateGridPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateGridMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateGridMinusMinusPostfix);
}
#endregion
#region Struct
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteUpdateStructPlusPlusPrefix() {
	var _target = target();
	return ++_target[$ key()];
}
function __GMLCexecuteUpdateStructPlusPlusPostfix() {
	var _target = target();
	return _target[$ key()]++;
}
function __GMLCexecuteUpdateStructMinusMinusPrefix() {
	var _target = target();
	return --_target[$ key()];
}
function __GMLCexecuteUpdateStructMinusMinusPostfix() {
	var _target = target();
	return _target[$ key()]--;
}
function __GMLCcompileUpdateStruct(_rootNode, _parentNode, _targetExpression, _keyExpression, _increment, _prefix, _line, _lineString) {
    var _output = {
		compilerBase: "__compileUpdateStruct",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _targetExpression,
		key: _keyExpression,
    }
    
	if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateStructPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateStructPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateStructMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateStructMinusMinusPostfix);
}
#endregion
#region Struct w/ Errors
#region //{
//    target: <expression>,
//    key: <stringLiteral>,
//}
#endregion
function __GMLCexecuteUpdateStructDotAccPlusPlusPrefix() {
    var _target = target();
    if (!struct_exists(_target, key)) throw $"\nVariable <unknown_object>.{key} not set before reading it."+$"\n(line {line}) -\t{lineString}"
	return ++_target[$ key];
}
function __GMLCexecuteUpdateStructDotAccPlusPlusPostfix() {
    var _target = target();
	if (!struct_exists(_target, key)) throw $"\nVariable <unknown_object>.{key} not set before reading it."+$"\n(line {line}) -\t{lineString}"
	return _target[$ key]++;
}
function __GMLCexecuteUpdateStructDotAccMinusMinusPrefix() {
    var _target = target();
    if (!struct_exists(_target, key)) throw $"\nVariable <unknown_object>.{key} not set before reading it."+$"\n(line {line}) -\t{lineString}"
	return --_target[$ key];
}
function __GMLCexecuteUpdateStructDotAccMinusMinusPostfix() {
    var _target = target();
    if (!struct_exists(_target, key)) throw $"\nVariable <unknown_object>.{key} not set before reading it."+$"\n(line {line}) -\t{lineString}"
	return _target[$ key]--;
}
function __GMLCcompileUpdateStructDotAcc(_rootNode, _parentNode, _targetExpression, _keyExpression, _increment, _prefix, _line, _lineString) {
    var _output = {
		compilerBase: "__compileUpdateStructDotAcc",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _targetExpression,
		key: _keyExpression,
    }
    
	if (_increment  &&  _prefix) return method(_output, __GMLCexecuteUpdateStructDotAccPlusPlusPrefix);
	if (_increment  && !_prefix) return method(_output, __GMLCexecuteUpdateStructDotAccPlusPlusPostfix);
	if (!_increment &&  _prefix) return method(_output, __GMLCexecuteUpdateStructDotAccMinusMinusPrefix);
	if (!_increment && !_prefix) return method(_output, __GMLCexecuteUpdateStructDotAccMinusMinusPostfix);
}
#endregion

#endregion

#endregion

#region Identifiers

#region Targeters / Getter / Setters

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
	if (_scope == ScopeType.UNIQUE) {
		var _output = {
			compilerBase: "__compilePropertyGet",
			errorMessage: "<Missing Error Message>",
			line: _line, //used for debugging
			lineString: _lineString, //used for debugging
			
			rootNode: _rootNode,
			parentNode: _parentNode,
			
			key: _leftKey,
		}
		
		return method(_output, __GMLCexecuteGetUnique)
	}
	
	var _output = {
		compilerBase: "__compilePropertyGet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: __GMLCgetScopeTarget(_scope),
		key: _leftKey,
	}
	
	return method(_output, __GMLCexecutePropertyGet)
}

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
function __GMLCcompilePropertySet(_rootNode, _parentNode, _scope, _leftKey, _rightExpression, _line, _lineString){
	if (_scope == ScopeType.UNIQUE) {
		var _output = {
			compilerBase: "__compilePropertySet",
			errorMessage: "<Missing Error Message>",
			line: _line, //used for debugging
			lineString: _lineString, //used for debugging
		
			
			rootNode: _rootNode,
			parentNode: _parentNode,
			
			key: _leftKey,
			expression: _rightExpression,
		}
		
		return method(_output, __GMLCexecuteSetUnique)
	}
	
	var _output = {
		compilerBase: "__compilePropertySet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
	    
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: __GMLCgetScopeTarget(_scope),
		key: _leftKey,
		expression: _rightExpression,
	}
	
	return method(_output, __GMLCexecutePropertySet)
}

#region Scope Getters/Setters
function __GMLCgetScopeTarget(_scopeType) {
	switch (_scopeType) {
		case ScopeType.GLOBAL:   return __GMLCexecuteTargetGlobal    break;
		case ScopeType.LOCAL:    return __GMLCexecuteTargetVarLocal  break;
		case ScopeType.STATIC:   return __GMLCexecuteTargetVarStatic break;
		case ScopeType.INSTANCE: return __GMLCexecuteTargetSelf      break;
		case ScopeType.CONST:    return __GMLCexecuteTargetConstant  break;
		case ScopeType.UNIQUE:   return __GMLCexecuteTargetUnique    break;
		default: throw $"Unsupported scope to be written to :: {_scopeType}";
	}
}
function __GMLCgetScopeGetter(_scopeType) {
	switch (_scopeType) {
		case ScopeType.GLOBAL:   return __GMLCexecuteGetGlobal    break;
		case ScopeType.LOCAL:    return __GMLCexecuteGetVarLocal  break;
		case ScopeType.STATIC:   return __GMLCexecuteGetVarStatic break;
		case ScopeType.INSTANCE: return __GMLCexecuteGetInstance  break;
		case ScopeType.CONST:    return __GMLCexecuteGetConstant  break;
		case ScopeType.UNIQUE:   return __GMLCexecuteGetUnique    break;
		default: throw $"Unsupported scope to be written to :: {_scopeType}";
	}
}
function __GMLCgetScopeSetter(_scopeType) {
	switch (_scopeType) {
		case ScopeType.GLOBAL:   return __GMLCexecuteSetGlobal    break;
		case ScopeType.LOCAL:    return __GMLCexecuteSetVarLocal  break;
		case ScopeType.STATIC:   return __GMLCexecuteSetVarStatic break;
		case ScopeType.INSTANCE: return __GMLCexecuteSetInstance  break;
		case ScopeType.CONST:    return __GMLCexecuteSetConstant  break;
		case ScopeType.UNIQUE:   return __GMLCexecuteSetUnique    break;
		default: throw $"Unsupported scope to be written to :: {_scopeType}";
	}
}

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
    throw $"Shouldnt be trying to target Unique Scope"
}

#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetSelf() {
    return global.selfInstance;
}
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetOther() {
    return global.otherInstance;
}
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetGlobal() {
    return rootNode.globals;
}
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetVarLocal() {
    return parentNode.locals;
}
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetVarStatic() {
    return parentNode.statics;
}
#region //{
//    key: <expression>
//}
#endregion
function __GMLCexecuteGetUnique() {
    switch (key) {
		case "self":				     return global.selfInstance;       break;
		case "other":				    return global.otherInstance;      break;
		case "all":				      return all;				       break;
		case "noone":				    return noone;				     break;
								
		case "fps":				      return fps;				       break;
		case "room":				     return room;				      break;
		case "lives":				    return lives;				     break;
		case "score":				    return score;				     break;
		case "health":				   return health;				    break;
		case "mouse_x":				  return mouse_x;				   break;
		case "visible":				  return visible;				   break;
		case "managed":				  return managed;				   break;
		case "mouse_y":				  return mouse_y;				   break;
		case "os_type":				  return os_type;				   break;
		case "game_id":				  return game_id;				   break;
		case "iap_data":				 return iap_data;				  break;
		case "argument":				 return parentNode.arguments    ;  break;
		case "argument0":				return parentNode.arguments[0] ;  break;
		case "argument1":				return parentNode.arguments[1] ;  break;
		case "argument2":				return parentNode.arguments[2] ;  break;
		case "argument3":				return parentNode.arguments[3] ;  break;
		case "argument4":				return parentNode.arguments[4] ;  break;
		case "argument5":				return parentNode.arguments[5] ;  break;
		case "argument6":				return parentNode.arguments[6] ;  break;
		case "argument7":				return parentNode.arguments[7] ;  break;
		case "argument8":				return parentNode.arguments[8] ;  break;
		case "argument9":				return parentNode.arguments[9] ;  break;
		case "argument10":		       return parentNode.arguments[10];  break;
		case "argument11":		       return parentNode.arguments[11];  break;
		case "argument12":		       return parentNode.arguments[12];  break;
		case "argument13":		       return parentNode.arguments[13];  break;
		case "argument14":		       return parentNode.arguments[14];  break;
		case "argument15":		       return parentNode.arguments[15];  break;
		case "fps_real":				 return fps_real;				  break;
		case "room_last":				return room_last;				 break;
		case "os_device":				return os_device;				 break;
		case "delta_time":		       return delta_time;				break;
		case "show_lives":		       return show_lives;				break;
		case "path_index":		       return path_index;				break;
		case "room_first":		       return room_first;				break;
		case "room_width":		       return room_width;				break;
		case "view_hport":		       return view_hport;				break;
		case "view_xport":		       return view_xport;				break;
		case "view_yport":		       return view_yport;				break;
		case "debug_mode":		       return debug_mode;				break;
		case "event_data":		       return event_data;				break;
		case "view_wport":		       return view_wport;				break;
		case "os_browser":		       return os_browser;				break;
		case "os_version":		       return os_version;				break;
		case "room_speed":		       return room_speed;				break;
		case "show_score":		       return show_score;				break;
		case "error_last":		       return error_last;				break;
		case "display_aa":		       return display_aa;				break;
		case "async_load":		       return async_load;				break;
		case "instance_id":		      return instance_id;		       break;
		case "current_day":		      return current_day;		       break;
		case "view_camera":		      return view_camera;		       break;
		case "room_height":		      return room_height;		       break;
		case "show_health":		      return show_health;		       break;
		case "mouse_button":		     return mouse_button;		      break;
		case "keyboard_key":		     return keyboard_key;		      break;
		case "view_visible":		     return view_visible;		      break;
		case "game_save_id":		     return game_save_id;		      break;
		case "current_hour":		     return current_hour;		      break;
		case "room_caption":		     return room_caption;		      break;
		case "view_enabled":		     return view_enabled;		      break;
		case "event_action":		     return event_action;		      break;
		case "view_current":		     return view_current;		      break;
		case "current_time":		     return current_time;		      break;
		case "current_year":		     return current_year;		      break;
		case "browser_width":		    return browser_width;		     break;
		case "webgl_enabled":		    return webgl_enabled;		     break;
		case "current_month":		    return current_month;		     break;
		case "caption_score":		    return caption_score;		     break;
		case "caption_lives":		    return caption_lives;		     break;
		case "gamemaker_pro":		    return gamemaker_pro;		     break;
		case "cursor_sprite":		    return cursor_sprite;		     break;
		case "caption_health":		   return caption_health;		    break;
		case "instance_count":		   return instance_count;		    break;
		case "argument_count":		   return array_length(parentNode.arguments);		    break;
		case "error_occurred":		   return error_occurred;		    break;
		case "current_minute":		   return current_minute;		    break;
		case "current_second":		   return current_second;		    break;
		case "temp_directory":		   return temp_directory;		    break;
		case "browser_height":		   return browser_height;		    break;
		case "view_surface_id":		  return view_surface_id;		   break;
		case "room_persistent":		  return room_persistent;		   break;
		case "current_weekday":		  return current_weekday;		   break;
		case "keyboard_string":		  return keyboard_string;		   break;
		case "cache_directory":		  return cache_directory;		   break;
		case "mouse_lastbutton":		 return mouse_lastbutton;		  break;
		case "keyboard_lastkey":		 return keyboard_lastkey;		  break;
		case "wallpaper_config":		 return wallpaper_config;		  break;
		case "background_color":		 return background_color;		  break;
		case "program_directory":		return program_directory;		 break;
		case "game_project_name":		return game_project_name;		 break;
		case "game_display_name":		return game_display_name;		 break;
		//case "argument_relative":		return argument_relative;		 break;
		case "keyboard_lastchar":		return keyboard_lastchar;		 break;
		case "working_directory":		return working_directory;		 break;
		case "rollback_event_id":		return rollback_event_id;		 break;
		case "background_colour":		return background_colour;		 break;
		case "font_texture_page_size":   return font_texture_page_size;    break;
		case "application_surface":      return application_surface;       break;
		case "rollback_api_server":      return rollback_api_server;       break;
		case "gamemaker_registered":     return gamemaker_registered;      break;
		case "background_showcolor":     return background_showcolor;      break;
		case "rollback_event_param":     return rollback_event_param;      break;
		case "background_showcolour":    return background_showcolour;     break;
		case "rollback_game_running":    return rollback_game_running;     break;
		case "rollback_current_frame":   return rollback_current_frame;    break;
		case "rollback_confirmed_frame": return rollback_confirmed_frame;  break;
								
	}
}
function __GMLCcompileGetUnique(_rootNode, _parentNode, _key, _line, _lineString) {
	var _output = {
		compilerBase: "__compileGetUnique",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		key: _key,
    }
    
    return method(_output, __GMLCexecuteGetUnique);
}


#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetSelf() {
    return struct_set(global.selfInstance, key, expression())
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetOther() {
    return struct_set(global.otherInstance, key, expression())
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetGlobal() {
    return struct_set(globals, key, expression())
}
#region //{
//    key: <stringLiteral>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetVarLocal() {
    return struct_set(locals, key, expression())
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetVarStatic() {
    return struct_set(statics, key, expression())
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __GMLCexecuteSetUnique() {
	switch (key) {
		//all write protected errors are at the bottom
		case "room":				     room				      = expression(); break;
		case "lives":				    lives				     = expression(); break;
		case "score":				    score				     = expression(); break;
		case "health":				   health				    = expression(); break;
		case "visible":				  visible				   = expression(); break;
		case "argument":				 parentNode.arguments      = expression(); break;
		case "argument0":				parentNode.arguments[0]   = expression(); break;
		case "argument1":				parentNode.arguments[1]   = expression(); break;
		case "argument2":				parentNode.arguments[2]   = expression(); break;
		case "argument3":				parentNode.arguments[3]   = expression(); break;
		case "argument4":				parentNode.arguments[4]   = expression(); break;
		case "argument5":				parentNode.arguments[5]   = expression(); break;
		case "argument6":				parentNode.arguments[6]   = expression(); break;
		case "argument7":				parentNode.arguments[7]   = expression(); break;
		case "argument8":				parentNode.arguments[8]   = expression(); break;
		case "argument9":				parentNode.arguments[9]   = expression(); break;
		case "argument10":		       parentNode.arguments[10]  = expression(); break;
		case "argument11":		       parentNode.arguments[11]  = expression(); break;
		case "argument12":		       parentNode.arguments[12]  = expression(); break;
		case "argument13":		       parentNode.arguments[13]  = expression(); break;
		case "argument14":		       parentNode.arguments[14]  = expression(); break;
		case "argument15":		       parentNode.arguments[15]  = expression(); break;
		case "show_lives":		       show_lives				= expression(); break;
		case "room_width":		       room_width				= expression(); break;
		case "view_hport":		       view_hport				= expression(); break;
		case "view_xport":		       view_xport				= expression(); break;
		case "view_yport":		       view_yport				= expression(); break;
		case "view_wport":		       view_wport				= expression(); break;
		case "room_speed":		       room_speed				= expression(); break;
		case "show_score":		       show_score				= expression(); break;
		case "error_last":		       error_last				= expression(); break;
		case "view_camera":		      view_camera		       = expression(); break;
		case "room_height":		      room_height		       = expression(); break;
		case "show_health":		      show_health		       = expression(); break;
		case "mouse_button":		     mouse_button		      = expression(); break;
		case "keyboard_key":		     keyboard_key		      = expression(); break;
		case "view_visible":		     view_visible		      = expression(); break;
		case "room_caption":		     room_caption		      = expression(); break;
		case "view_enabled":		     view_enabled		      = expression(); break;
		case "caption_score":		    caption_score		     = expression(); break;
		case "caption_lives":		    caption_lives		     = expression(); break;
		case "cursor_sprite":		    cursor_sprite		     = expression(); break;
		case "caption_health":		   caption_health		    = expression(); break;
		case "error_occurred":		   error_occurred		    = expression(); break;
		case "view_surface_id":		  view_surface_id		   = expression(); break;
		case "room_persistent":		  room_persistent		   = expression(); break;
		case "keyboard_string":		  keyboard_string		   = expression(); break;
		case "mouse_lastbutton":		 mouse_lastbutton		  = expression(); break;
		case "keyboard_lastkey":		 keyboard_lastkey		  = expression(); break;
		case "background_color":		 background_color		  = expression(); break;
		case "keyboard_lastchar":		keyboard_lastchar		 = expression(); break;
		case "background_colour":		background_colour		 = expression(); break;
		case "font_texture_page_size":   font_texture_page_size    = expression(); break;
		case "background_showcolor":     background_showcolor      = expression(); break;
		case "background_showcolour":    background_showcolour     = expression(); break;
		
		//begining of write errors
		case "self":
		case "other":
		case "all":
		case "noone":
		case "delta_time":
		case "path_index":
		case "room_first":
		case "debug_mode":
		case "event_data":
		case "os_browser":
		case "os_version":
		case "display_aa":
		case "async_load":
		case "instance_id":
		case "current_day":
		case "game_save_id":
		case "current_hour":
		case "event_action":
		case "view_current":
		case "current_time":
		case "current_year":
		case "browser_width":
		case "webgl_enabled":
		case "current_month":
		case "gamemaker_pro":
		case "instance_count":
		case "argument_count":
		case "current_minute":
		case "current_second":
		case "temp_directory":
		case "browser_height":
		case "current_weekday":
		case "cache_directory":
		case "wallpaper_config":
		case "program_directory":
		case "game_project_name":
		case "game_display_name":
		case "argument_relative":
		case "working_directory":
		case "rollback_event_id":
		case "application_surface":
		case "rollback_api_server":
		case "gamemaker_registered":
		case "rollback_event_param":
		case "rollback_game_running":
		case "rollback_current_frame":
		case "rollback_confirmed_frame":
		case "fps":
		case "mouse_x":
		case "managed":
		case "mouse_y":
		case "os_type":
		case "game_id":
		case "iap_data":
		case "fps_real":
		case "room_last":
		case "os_device": throw $"Attempting to write to a read-only variable {key}"+$"\n(line {line}) -\t{lineString}"
	}
}
function __GMLCcompileSetUnique(_rootNode, _parentNode, _key, _value, _line, _lineString) {
	var _output = {
		compilerBase: "__compileSetUnique",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		key: _key,
		value: _value,
    }
    
    return method(_output, __GMLCexecuteSetUnique);
}
#endregion

function __GMLCcompileAccessor(_rootNode, _parentNode, _accessorNode, _line, _lineString) {
	
	var _target = __GMLCcompileExpression(_rootNode, _parentNode, _accessorNode.expr)
	var _key = __GMLCcompileExpression(_rootNode, _parentNode, _accessorNode.val1)
	
	switch (_accessorNode.accessorType) {
		case __GMLC_AccessorType.Array:  return __GMLCcompileArrayGet       (_rootNode, _parentNode, _target, _key, _line, _lineString)
		case __GMLC_AccessorType.Grid:   return __GMLCcompileGridGet        (_rootNode, _parentNode, _target, _key, __GMLCcompileExpression(_rootNode, _parentNode, _accessorNode.val1), _line, _lineString)
		case __GMLC_AccessorType.List:   return __GMLCcompileListGet        (_rootNode, _parentNode, _target, _key, _line, _lineString)
		case __GMLC_AccessorType.Map:    return __GMLCcompileMapGet         (_rootNode, _parentNode, _target, _key, _line, _lineString)
		case __GMLC_AccessorType.Struct: return __GMLCcompileStructGet      (_rootNode, _parentNode, _target, _key, _line, _lineString)
		case __GMLC_AccessorType.Dot:    return __GMLCcompileStructDotAccGet(_rootNode, _parentNode, _target, _key, _line, _lineString)
		default: throw $"\nUnsupported accessor type: {_accessorNode.accessorType}\n{_accessorNode}";
	}
	
	
}
#region Accessor Getters/Setters
#region Array
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteArrayGet(){
	var _target = target();
	return _target[key()]
}
function __GMLCcompileArrayGet(_rootNode, _parentNode, _target, _key, _line, _lineString) {
    var _output = {
		compilerBase: "__compileArrayGet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
    }
	
	return method(_output, __GMLCexecuteArrayGet)
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteArraySet(){
	var _target = target();
	_target[key()] = expression()
}
function __GMLCcompileArraySet(_rootNode, _parentNode, _target, _key, _expression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileArraySet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
		expression: _expression,
    }
    return method(_output, __GMLCexecuteArraySet)
}
#endregion
#region List
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteListGet(){
	var _target = target();
	return _target[| key()]
}
function __GMLCcompileListGet(_rootNode, _parentNode, _target, _key, _line, _lineString) {
    var _output = {
		compilerBase: "__compileListGet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
    }
    return method(_output, __GMLCexecuteListGet)
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteListSet(){
	var _target = target();
	_target[| key()] = expression()
}
function __GMLCcompileListSet(_rootNode, _parentNode, _target, _key, _expression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileListSet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
		expression: _expression,
    }
    return method(_output, __GMLCexecuteListSet)
}
#endregion
#region Map
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteMapGet(){
	var _target = target();
	return _target[? key()]
}
function __GMLCcompileMapGet(_rootNode, _parentNode, _target, _key, _line, _lineString) {
    var _output = {
		compilerBase: "__compileMapGet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
    }
    return method(_output, __GMLCexecuteMapGet)
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteMapSet(){
	var _target = target();
	_target[? key()] = expression()
}
function __GMLCcompileMapSet(_rootNode, _parentNode, _target, _key, _expression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileMapSet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
		expression: _expression,
    }
    return method(_output, __GMLCexecuteMapSet)
}
#endregion

#region Grid
#region //{
//    target: <expression>,
//    keyX: <expression>,
//    keyY: <expression>,
//}
#endregion
function __GMLCexecuteGridGet(){
	var _target = target();
	return _target[# keyX(), keyY()]
}
function __GMLCcompileGridGet(_rootNode, _parentNode, _target, _keyX, _keyY, _line, _lineString) {
    var _output = {
		compilerBase: "__compileGridGet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		keyX: _keyX,
		keyY: _keyY,
    }
    return method(_output, __GMLCexecuteGridGet)
}
#region //{
//    target: <expression>,
//    keyX: <expression>,
//    keyY: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteGridSet(){
	var _target = target();
	_target[# keyX(), keyY()] = expression()
}
function __GMLCcompileGridSet(_rootNode, _parentNode, _target, _keyX, _keyY, _expression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileGridSet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		keyX: _keyX,
		keyY: _keyY,
		expression: _expression,
    }
    return method(_output, __GMLCexecuteGridSet)
}
#endregion
#region Struct
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __GMLCexecuteStructGet(){
	var _target = target();
	return _target[$ key()]
}
function __GMLCcompileStructGet(_rootNode, _parentNode, _target, _key, _line, _lineString) {
    var _output = {
		compilerBase: "__compileStructGet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
    }
    return method(_output, __GMLCexecuteStructGet)
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteStructSet(){
	var _target = target();
	_target[$ key()] = expression()
}
function __GMLCcompileStructSet(_rootNode, _parentNode, _target, _key, _expression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileStructSet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
		expression: _expression,
    }
    return method(_output, __GMLCexecuteStructSet)
}
#endregion
#region Struct w/ Error
#region //{
//    target: <expression>,
//    key: <stringLiteral>,
//}
#endregion
function __GMLCexecuteStructDotAccGet(){
	var _target = target();
	var _key = key();
	
	if (!struct_exists(_target, _key)) {
		throw $"\nVariable <unknown_object>.{_key} not set before reading it."+$"\n(line {self.line}) -\t{self.lineString}\n{callstack}"
	}
	
	return _target[$ _key];
}
function __GMLCcompileStructDotAccGet(_rootNode, _parentNode, _target, _key, _line, _lineString) {
	var _output = {
		compilerBase: "__compileStructDotAccGet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
		callstack: debug_get_callstack(6)
    }
	
	return method(_output, __GMLCexecuteStructDotAccGet)
}
#region //{
//    target: <expression>,
//    key: <stringLiteral>,
//    expression: <expression>,
//}
#endregion
function __GMLCexecuteStructDotAccSet(){
	var _target = target();
    if (!struct_exists(_target, key)) throw $"\nVariable <unknown_object>.{name} not set before reading it."+$"\n(line {line}) -\t{lineString}"
	_target[$ key] = expression();
}
function __GMLCcompileStructDotAccSet(_rootNode, _parentNode, _target, _key, _expression, _line, _lineString) {
    var _output = {
		compilerBase: "__compileStructDotAccSet",
		errorMessage: "<Missing Error Message>",
		line: _line, //used for debugging
		lineString: _lineString, //used for debugging
		
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
		expression: _expression,
    }
    return method(_output, __GMLCexecuteStructDotAccSet)
}
#endregion

#endregion

#endregion

function __GMLCcompileIdentifier(_rootNode, _parentNode, _scope, _name, _line, _lineString) {
	var _target = __GMLCgetScopeTarget(_scope)
	var _key = __GMLCcompileLiteralExpression(_rootNode, _parentNode, _name, _line, _lineString)
	
	return __GMLCcompileStructDotAccGet(_rootNode, _parentNode, _target, _key, _line, _lineString)
}

function __GMLCcompileUniqueIdentifier(_rootNode, _parentNode, _scope, _name, _line, _lineString) {
	var _key = _name
	return __GMLCcompileGetUnique(_rootNode, _parentNode, _key, _line, _lineString);
}


#endregion




















