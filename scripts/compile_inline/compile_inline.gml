
///NOTE: all of these should be build into the parent program's struct, and all children should
// have a reference to that struct to access the locals and arguments when ever needed

global.selfInstance = undefined;
global.otherInstance = undefined;
global.callStack = [];

///////////////////////////////////////////////////////////////////////////////////////////////


function compileInLineProgram(_AST) {
	return __compileInLineProgram(_AST);
}
function executeInLineProgram(_program)  {
	//this function should never be called inside a prgroam, for that use `__executeInLineProgram`
    global.selfInstance = self;
    global.otherInstance = other;
    return _program();
}

#region //{
// used to start the initial entry into the compiled program, mostly just to init variables like 
//    program: <expression>,
//    varStatics: {},
//    locals: {},
//}
#endregion
function __executeInLineProgram(_struct) {
	//incase the program/script/function is recursive we need to stash the arguments
	var _pre_args = arguments;
	
	//edit our local array
	arguments  = [];
	//var _i=0; repeat(argument_count) {
	//	array_push(arguments, argument[_i]);
	//_i++}
	
	var _return = __inline_execute(program, arguments);
	
	arguments = _pre_args;
	activeFunction = undefined;
	//reset variables
	//locals = {};
	//var _return = _struct.parentNode.returnValue;
	//_struct.parentNode.returnValue = undefined;
	//_struct.parentNode.shouldReturn = false;
	//_struct.parentNode.shouldBreak = false;
	//_struct.parentNode.shouldContinue = false;
	
	return _return;
}
function __compileInLineProgram(_AST, _globalsStruct={"__@@ASSETS@@__":{}}) {
	var _output = {
		exeFunc: __executeInLineProgram,
		errorMessage: "<Missing Error Message>",
		
		globals: _globalsStruct, // these are optional inputs for future use with compiling a full project folder.
		//statics: {},
		//locals: {},
		
		arguments: [],
		program: undefined,
		
		//_struct.parentNode.returnValue: undefined,
		//_struct.parentNode.shouldReturn: false,
		//_struct.parentNode.shouldBreak: false,
		//_struct.parentNode.shouldContinue: false,
		
	}
	_output.program = __compileInLineFunction(_output, _output, _AST);
	
	//compile all of the global variable functions
	var _names = struct_get_names(_AST.GlobalVar)
	var _i=0; repeat(array_length(_names)) {
		var _name = _names[_i];
		var _node = _AST.GlobalVar[$ _name];
		_output.globals[$ _name] = __compileInLineFunction(_output, _output, _node);
	_i++}
	
	return method(_output, __executeInLineProgram)
}

function __executeInLineFunction(_struct, _args=[]) {
	//incase the program/script/function is recursive we need to stash the arguments
	var _pre_args = _struct.arguments;
	var _pre_locals = _struct.locals;
	_struct.arguments = _args;
	_struct.locals = {};
	
	
	__inline_execute(_struct.argumentsDefault);
	__inline_execute(_struct.program, _struct.arguments);
	
	//method_call(_struct.program, _struct.arguments);
	var _return = _struct.parentNode.returnValue;
	
	_struct.parentNode.shouldReturn = false;
	_struct.parentNode.returnValue = undefined;
	//_struct.parentNode.shouldBreak = false;
	//_struct.parentNode.shouldContinue = false;
	
	_struct.arguments = _pre_args;
	_struct.locals = _pre_locals;
	
	return _return;
}
function __compileInLineFunction(_rootNode, _parentNode, _AST) {
	var _output = {
		exeFunc: __executeInLineFunction,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: undefined, //entering a function call resets the parent node, as this is used for fetching locals
		
		statics: {},
		locals: undefined,
		
		arguments: undefined,
		argumentsDefault: undefined,
		
		program: undefined,
		
		returnValue: undefined,
		shouldReturn: false,
		shouldBreak: false,
		shouldContinue: false,
		
	}
	_output.parentNode = _output;
	_output.argumentsDefault = __compileInLineArgumentList(_rootNode, _output, _AST.arguments);
	_output.program = __compileInLineBlockStatement(_rootNode, _output, _AST.statements);
	
	return _output
}

function __executeInLineArgumentList(_struct) {
	var _inputArguments = _struct.parentNode.arguments;
	var _inputLength = array_length(_inputArguments);
	
	var _length = array_length(_struct.statements)
	var _i=0; repeat(_length) {
		var _arg = _struct.statements[_i]
		if (_arg.index != _i) throw "Why does our index not match our argument's index?"
		
		if (_i < _inputLength) {
			if (_inputArguments[_i] == undefined) {
				var _val = __inline_execute(_arg.expression);
				_inputArguments[_i] = _val;
			}
		}
		else {
			var _val = __inline_execute(_arg.expression);
			_inputArguments[_i] = _val;
		}
		
		//apply to the local struct
		_struct.parentNode.locals[$ _arg.identifier] = _inputArguments[_i]
		
	_i++}
}
function __compileInLineArgumentList(_rootNode, _parentNode, _node) {
	var _output = {
		exeFunc: __executeInLineArgumentList,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		statements: [],
	}
	
	var _arr = _node.statements;
	var _i=0; repeat(array_length(_arr)) {
		_output.statements[_i] = __compileInLineArgument(_rootNode, _parentNode, _arr[_i]);
	_i++}
	
	return _output
}

function __executeInLineArgument(_struct) {
	throw "ERROR :: __executeInLineArgument should never actually be run, this should be handled by ArgumentList"
}
function __compileInLineArgument(_rootNode, _parentNode, _node) {
	var _output = {
		exeFunc: __executeInLineArgument,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		index: _node.argument_index,
		identifier: _node.identifier,
		expression: __compileInLineExpression(_rootNode, _parentNode, _node.expr)
	}
	
	return _output;
}

function __executeInLineExpression(_struct) {};
function __compileInLineExpression(_rootNode, _parentNode, _node, _isCondtion=false) {
	
	//log($"TYPE :: {_node.type}\nLINE :: {struct_exists(_node, "lineString") ? _node.lineString : "<undefined>"}\nNODE :: {json_stringify(_node, true)}")
	
	//check every different ast node, and see how it should be compiled,
    // this is essentially our lookup table for that
	
	switch (_node.type) {
		case __GMLC_NodeType.FunctionDeclaration:{
			throw "not done yet"
		break;}
		case __GMLC_NodeType.ArgumentList:{
			throw "not done yet"
		break;}
		case __GMLC_NodeType.Argument:{
			throw "not done yet"
		break;}
		
		case __GMLC_NodeType.BlockStatement:{
			return __compileInLineBlockStatement(_rootNode, _parentNode, _node);
		break;}
		case __GMLC_NodeType.IfStatement:{
			return __compileInLineIf(_rootNode, _parentNode, _node.condition, _node.consequent, _node.alternate);
		break;}
		case __GMLC_NodeType.ForStatement:{
			return __compileInLineFor(_rootNode, _parentNode, _node.initialization, _node.condition, _node.increment, _node.codeBlock);
		break;}
		case __GMLC_NodeType.WhileStatement:{
			return __compileInLineWhile(_rootNode, _parentNode, _node.condition, _node.codeBlock);
		break;}
		case __GMLC_NodeType.RepeatStatement:{
			return __compileInLineRepeat(_rootNode, _parentNode, _node.condition, _node.codeBlock);
		break;}
		case __GMLC_NodeType.DoUntillStatement:{
			return __compileInLineDoUntil(_rootNode, _parentNode, _node.condition, _node.codeBlock);
		break;}
		case __GMLC_NodeType.WithStatement:{
			return __compileInLineWith(_rootNode, _parentNode, _node.condition, _node.codeBlock);
		break;}
		case __GMLC_NodeType.TryStatement:{
			return __compileInLineTryCatchFinally(_rootNode, _parentNode, _node.tryBlock, _node.catchBlock, _node.finallyBlock, _node.exceptionVar);
		break;}
		case __GMLC_NodeType.SwitchStatement:{
			return __compileInLineSwitch(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeType.CaseExpression:
		case __GMLC_NodeType.CaseDefault:{
			return __compileInLineCase(_rootNode, _parentNode, _node)
		break;}
		
		case __GMLC_NodeType.ThrowStatement: {
			return __compileInLineThrow(_rootNode, _parentNode, _node.error)
		break;}
		
		case __GMLC_NodeType.BreakStatement:{
			return __compileInLineBreak(_rootNode, _parentNode);
		break;}
		case __GMLC_NodeType.ContinueStatement:{
			return __compileInLineContinue(_rootNode, _parentNode);
		break;}
		case __GMLC_NodeType.ExitStatement:{
			return __compileInLineExit(_rootNode, _parentNode)
		break;}
		case __GMLC_NodeType.ReturnStatement:{
			return __compileInLineReturn(_rootNode, _parentNode, _node.expr)
		break;}
		
		case __GMLC_NodeType.VariableDeclarationList:{
			return __compileInLineVariableDeclarationList(_rootNode, _parentNode, _node)
		break;}
		case __GMLC_NodeType.VariableDeclaration:{
			return __compileInLineVariableDeclaration(_rootNode, _parentNode, _node.scope, _node.identifier, _node.expr);
		break;}
		
		case __GMLC_NodeType.CallExpression:{
			return __compileInLineCallExpression(_rootNode, _parentNode, _node.callee, _node.arguments)
		break;}
		case __GMLC_NodeType.NewExpression:{
			throw "not done yet"
			//return __compileInLineThrow(_rootNode, _parentNode, _node.error)
		break;}
		
		case __GMLC_NodeType.ExpressionStatement:{
			//NOTE: Logging this incase we are generating unneeded AST nodes.
			return __compileInLineExpression(_rootNode, _parentNode, _node.expr);
		break;}
		case __GMLC_NodeType.AssignmentExpression:{
			return __compileInLineAssignmentExpression(_rootNode, _parentNode, _node.left.scope, _node.operator, _node.left, _node.right)
		break;}
		case __GMLC_NodeType.BinaryExpression:{
			return __compileInLineBinaryExpression(_rootNode, _parentNode, _node.operator, _node.left, _node.right)
		break;}
		case __GMLC_NodeType.LogicalExpression:{
			return __compileInLineLogicalExpression(_rootNode, _parentNode, _node.operator, _node.left, _node.right)
		break;}
		case __GMLC_NodeType.NullishExpression:{
			return __compileInLineNullishExpression(_rootNode, _parentNode, _node.operator, _node.left, _node.right)
		break;}
		case __GMLC_NodeType.UnaryExpression:{
			return __compileInLineUnaryExpression(_rootNode, _parentNode, _node.operator, _node.expr)
		break;}
		case __GMLC_NodeType.UpdateExpression:{
			return __compileInLineUpdateExpression(_rootNode, _parentNode, _node)
		break;}
				
		case __GMLC_NodeType.ConditionalExpression:{
			return __compileInLineConditionalExpression(_rootNode, _parentNode, _node.condition, _node.trueExpr, _node.falseExpr);
		break;}
				
		case __GMLC_NodeType.ArrayPattern:{
			return __compileInLineNewArray(_rootNode, _parentNode, _node.elements)
		break;}
		case __GMLC_NodeType.StructPattern:{
			return __compileInLineNewStruct(_rootNode, _parentNode, _node.arguments.statements)
		break;}
		case __GMLC_NodeType.Literal:{
			return __compileInLineLiteralExpression(_rootNode, _parentNode, _node.value);
		break;}
		case __GMLC_NodeType.Identifier:{
			return __compileInLineIdentifier(_rootNode, _parentNode, _node.scope, _node.value)
		break;}
				
		case __GMLC_NodeType.UniqueIdentifier:{
			return __compileInLineUniqueIdentifier(_rootNode, _parentNode, _node.scope, _node.value)
		break;}
				
		case __GMLC_NodeType.AccessorExpression:{
			return __compileInLineAccessor(_rootNode, _parentNode, _node)
		break;}
				
		case __GMLC_NodeType.Function:{
			return __compileInLineLiteralExpression(_rootNode, _parentNode, _node.value);
		break;}
		/*
		case __GMLC_NodeType.PropertyAccessor:{
			throw $"\n{currentNode.type} :: Not implimented yet"
		break;}
		case __GMLC_NodeType.AccessorExpression:{
			throw $"\n{currentNode.type} :: Not implimented yet"
		break;}
		case __GMLC_NodeType.ConstructorFunction:{
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
			
			show_debug_message(json_stringify(_node, true))
			throw $"\nCurrent Node does not have a valid type for the optimizer,\ntype: {_node.type}\ncurrentNode: {json_stringify(_node, true)}"
		break;
				
		// Add cases for other types of nodes
	}
	
};


#region Statements

#region //{
// used for gmlc compiled repeat blocks
//    condition: <expression>,
//    trueBlock: <expression>,
//}
#endregion
function __executeInLineIf(_struct) {
    if (__inline_execute(_struct.condition)) __inline_execute(_struct.trueBlock);
}
#region //{
// used for gmlc compiled repeat blocks
//    condition: <expression>,
//    trueBlock: <expression>,
//    elseBlock: <expression>,
//}
#endregion
function __executeInLineIfElse(_struct) {
    ///NOTE: it might be faster to use a ternary operation here,
    // it is worth investigating with a benchmark
	if (__inline_execute(_struct.condition)) {
		__inline_execute(_struct.trueBlock)
    }
    else {
		__inline_execute(_struct.elseBlock);
    }
}
function __compileInLineIf(_rootNode, _parentNode, _condition, _trueBlock, _elseBlock=undefined) {
    var _output = {
		exeFunc: __executeInLineIf,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		condition: __compileInLineExpression(_rootNode, _parentNode, _condition),
		trueBlock: __compileInLineExpression(_rootNode, _parentNode, _trueBlock),
    }
    
	if (_elseBlock == undefined) {
		return _output
    }
    else {
		_output.elseBlock = __compileInLineExpression(_rootNode, _parentNode, _elseBlock);
		return _output
    }
}


#region //{
// used for gmlc compiled block statements, these are non-breakable, typically used
// for if/else statements, function's bodies, etc
//    blockStatements: [],
//    size: undefined,
//}
#endregion
function __executeInLineBlockStatement(_struct) {
	
	var _i=0 repeat(_struct.size) {
		__inline_execute(_struct.blockStatements[_i]);
		
		if (_struct.parentNode.shouldReturn) {
			return undefined;
		}
	_i++}
}
function __compileInLineBlockStatement(_rootNode, _parentNode, _node) {
    var _output = {
		exeFunc: __executeInLineBlockStatement,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		blockStatements: [],
		size: undefined,
    }
	
	var _blockStatements = _node.statements
	var _i=0; repeat(array_length(_blockStatements)) {
		var _expression = __compileInLineExpression(_rootNode, _parentNode, _blockStatements[_i])
		var _expr_struct = _expression
		
		//prevent pushing a block statement into a block statement
		if (_expr_struct.exeFunc == __executeInLineBlockStatement) {
			array_copy(_output.blockStatements, array_length(_output.blockStatements), _expr_struct.blockStatements, 0, array_length(_expr_struct.blockStatements))
		}
		else {
			array_push(_output.blockStatements, _expression)
		}
    _i++}
	
	_output.size = array_length(_output.blockStatements)
    
	return _output
}

#region //{
// used for gmlc compiled switch statement's blocks, as they can be broken, and returned from, but can not be used with continue
//    blockStatements: [],
//}
#endregion
function __executeInLineBlockStatementBreakable(_struct) {
	var _i=0 repeat(array_length(_struct.blockStatements)) {
		__inline_execute(_struct.blockStatements[_i]);
		if (_struct.parentNode.shouldReturn) return undefined;
		if (_struct.parentNode.shouldBreak) return undefined;
	_i++}
}
function __compileInLineBlockStatementBreakable(_rootNode, _parentNode, _node) {
    var _output = {
		exeFunc: __executeInLineBlockStatementBreakable,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		blockStatements: [],
		size: undefined,
    }
	
    var _i=0; repeat(array_length(_node.statements)) {
		_output.blockStatements[_i] = __compileInLineExpression(_rootNode, _parentNode, _node.statements[_i])
    _i++}
    
    _output.size = array_length(_output.blockStatements)
    
    return _output
}

#region //{
// used for gmlc compiled loops which have no exit condition except break or return
// for instance `repeat(infinity)` or `while(true)`
//    blockStatements: [],
//}
#endregion
function __executeInLineLoopStatementEndless(_struct) {
    //NOTE: Benchmark the different ways for this `repeat(infinity)` `do{ }until(false)` `while(true)`
    while(true){
		__inline_execute(_struct.blockStatements);
		if (_struct.parentNode.shouldReturn) return undefined;
		if (_struct.parentNode.shouldBreak) {
		    _struct.parentNode.shouldBreak = false;
		    return undefined;
		}
    }
}
function __compileInLineLoopStatementEndless(_rootNode, _parentNode, _node) {
    var _output = {
		exeFunc: __executeInLineLoopStatementEndless,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		blockStatements: __compileInLineExpression(_rootNode, _parentNode, _blockStatement),
    }
    
    return _output
}

#region //{
// used for gmlc compiled block statements, these are non-breakable, typically used
// for if/else statements, function's bodies, etc
//    blockStatements: {},
//}
#endregion
function __executeInLineLoopStatement(_struct) {
	var _i=0 repeat(_struct.size) {
		__inline_execute(_struct.blockStatements[_i]);
		if (_struct.parentNode.shouldReturn) return undefined;
		if (_struct.parentNode.shouldBreak) return undefined;
		if (_struct.parentNode.shouldContinue) {
		    _struct.parentNode.shouldContinue = false;
		    return undefined;
		}
	_i++}
}
function __compileInLineLoopStatement(_rootNode, _parentNode, _node) {
    var _output = {
		exeFunc: __executeInLineLoopStatement,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		blockStatements: [],
		size: undefined,
    }
    var _i=0; repeat(array_length(_node.statements)) {
		_output.blockStatements[_i] = __compileInLineExpression(_rootNode, _parentNode, _node.statements[_i])
    _i++}
	
    _output.size = array_length(_output.blockStatements)
    
    return _output
}

#region //{
// used for gmlc compiled repeat blocks
//    expression: <expression>,
//    blockStatement: {},
//}
#endregion
function __executeInLineRepeat(_struct) {
    repeat(__inline_execute(_struct.condition)) {
		__inline_execute(_struct.blockStatement);
		if (_struct.parentNode.shouldReturn) return undefined
		if (_struct.parentNode.shouldBreak) {
		    _struct.parentNode.shouldBreak = false;
		    return undefined;
		}
		if (_struct.parentNode.shouldContinue) {
		    _struct.parentNode.shouldContinue = false;
		    return undefined;
		}
    }
}
function __compileInLineRepeat(_rootNode, _parentNode, _condition, _blockStatement) {
    var _output = {
		exeFunc: __executeInLineRepeat,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		condition: __compileInLineExpression(_rootNode, _parentNode, _condition),
		blockStatement: __compileInLineLoopStatement(_rootNode, _parentNode, _blockStatement),
    }
    return _output
}

#region //{
// used for gmlc compiled while blocks
//    expression: <expression>,
//    blockStatement: {},
//}
#endregion
function __executeInLineWhile(_struct) {
    while(__inline_execute(_struct.condition)) {
		__inline_execute(_struct.blockStatement);
		if (_struct.parentNode.shouldReturn) return undefined
		if (_struct.parentNode.shouldBreak) {
		    _struct.parentNode.shouldBreak = false;
		    return undefined;
		}
		if (_struct.parentNode.shouldContinue) {
		    _struct.parentNode.shouldContinue = false;
		    //no need to break or continue we will already be doing that
		}
    }
}
function __compileInLineWhile(_rootNode, _parentNode, _condition, _blockStatement) {
    var _output = {
		exeFunc: __executeInLineWhile,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		condition: __compileInLineExpression(_rootNode, _parentNode, _condition),
		blockStatement: __compileInLineLoopStatement(_rootNode, _parentNode, _blockStatement),
    }
    return _output
}

#region //{
// used for gmlc compiled do/until blocks
//    expression: <expression>,
//    blockStatement: {},
//}
#endregion
function __executeInLineDoUntil(_struct) {
    do {
		__inline_execute(_struct.blockStatement);
		if (_struct.parentNode.shouldReturn) return undefined
		if (_struct.parentNode.shouldBreak) {
		    _struct.parentNode.shouldBreak = false;
		    return undefined;
		}
		if (_struct.parentNode.shouldContinue) {
		    _struct.parentNode.shouldContinue = false;
		    //no need to break or continue we will already be doing that
		}
    }
    until __inline_execute(_struct.condition)
}
function __compileInLineDoUntil(_rootNode, _parentNode, _condition, _blockStatement) {
    var _output = {
		exeFunc: __executeInLineDoUntil,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		condition: __compileInLineExpression(_rootNode, _parentNode, _condition),
		blockStatement: __compileInLineLoopStatement(_rootNode, _parentNode, _blockStatement),
    }
    return _output
}

#region //{
// used for gmlc compiled for statements
//    assignment: <expression>,
//    expression: <expression>,
//    operation: <expression>,
//    blockStatement: <blockStatement>,
//}
#endregion
function __executeInLineFor(_struct) {
    for (__inline_execute(_struct.assignment); __inline_execute(_struct.condition); __inline_execute(_struct.operation)) {
		__inline_execute(_struct.blockStatement);
		if (_struct.parentNode.shouldReturn) return undefined
		if (_struct.parentNode.shouldBreak) {
		    _struct.parentNode.shouldBreak = false;
		    return undefined;
		}
		if (_struct.parentNode.shouldContinue) {
		    _struct.parentNode.shouldContinue = false;
		    //no need to break or continue we will already be doing that
		}
    }
}
function __compileInLineFor(_rootNode, _parentNode, _assignment, _condition, _operation, _blockStatement) {
    var _output = {
		exeFunc: __executeInLineFor,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		assignment: __compileInLineExpression(_rootNode, _parentNode, _assignment),
		condition: __compileInLineExpression(_rootNode, _parentNode, _condition),
		operation: __compileInLineExpression(_rootNode, _parentNode, _operation),
		blockStatement: __compileInLineLoopStatement(_rootNode, _parentNode, _blockStatement),
    }
    return _output
}

#region //{
// used for gmlc compiled switch/case statements
//    expression: <expression>,
//    cases: struct<blockStatementsBreakable>
//    size: array_length(cases)
//}
#endregion
function __executeInLineSwitch(_struct) {
    var _value = __inline_execute(_struct.expression);
    var _passing = false;
    
    var _i=0; repeat(_struct.size) {
		var _case = _struct.cases[_i];
		if (_passing)
		|| (__inline_execute(_case.expression) == _value) {
		    _passing = true
		    __inline_execute(_case.blockStatement)
		    if (_struct.parentNode.shouldReturn) return undefined
		    if (_struct.parentNode.shouldBreak) break;
		}
    _i++}
	
	if (!_struct.parentNode.shouldBreak)
	&& (_struct.caseDefault != undefined) {
		__inline_execute(_struct.caseDefault.blockStatement)
	}
	
	_struct.parentNode.shouldBreak = false;
}
function __compileInLineSwitch(_rootNode, _parentNode, _node) {
	var _output = {
		exeFunc: __executeInLineSwitch,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		expression: __compileInLineExpression(_rootNode, _parentNode, _node.switchExpression),
		cases: [],
		caseDefault: undefined,
		size: 0,
    }
    
    var _i=0; repeat(array_length(_node.cases)) {
		var _case = _node.cases[_i];
		var _struct = __compileInLineCase(_rootNode, _parentNode, _case);
		
		//set the case as default or push to cases
		if (_struct.isDefault) _output.caseDefault = _struct;
		else _output.cases[_i] = _struct;
		
    _i++}
    
    _output.size = array_length(_output.cases);
    
    return _output
}
#region //{
// used for gmlc compiled switch/case statements
//    expression: <expression>,
//    blockStatements: array<blockStatementsBreakable>
//}
#endregion
function __executeInLineCase(_struct) {
    //this is only here for consistancy sake, this function shouldnt ever run
    throw "This code should be unreachable"
}
function __compileInLineCase(_rootNode, _parentNode, _node) {
    var _output = {
		exeFunc: __executeInLineCase,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		isDefault: (_node.label == undefined),
		expression: (_node.label == undefined) ? undefined : __compileInLineExpression(_rootNode, _parentNode, _node.label),
		blockStatement: __compileInLineBlockStatementBreakable(_rootNode, _parentNode, _node.codeBlock),
    }
    
    return _output;
}

#region //{
// used to execute gmlc compiled `with` statements
//    expression: <expression>
//    blockStatement: <blockStatementBreakable>
//}
#endregion
function __executeInLineWith(_struct) {
    //early out
    var _inst = __inline_execute(_struct.expression)
	if (_inst == undefined) return undefined
    
    var _self = global.selfInstance;
    var _other = global.otherInstance;
    
    //this mimics a with statement, but ultimately it's not actually need to use `with`
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
		
		__inline_execute(_struct.blockStatement);
		
		//we break on all three cases here because we would like to run the
		// rest of the function to return to our previous self/other
		if (_struct.parentNode.shouldReturn) break;
		if (_struct.parentNode.shouldBreak) {
		    _struct.parentNode.shouldBreak = false;
		    break;
		}
		if (_struct.parentNode.shouldContinue) {
		    _struct.parentNode.shouldContinue = false;
		    //no need to break or continue we will already be doing that
		}
    _i++}
    
    
    
    //reset
    global.selfInstance = _self;
    global.otherInstance = _other;
}
function __compileInLineWith(_rootNode, _parentNode, _expression, _blockStatement) {
    var _output = {
		exeFunc: __executeInLineWith,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		expression: __compileInLineExpression(_rootNode, _parentNode, _expression),
		blockStatement: __compileInLineLoopStatement(_rootNode, _parentNode, _blockStatement),
    }
    return _output
}

#region //{
// used to execute gmlc compiled `try/catch/finally` statements
//    tryBlock: <block>
//    catchBlock: <block>
//    finallyBlock: <block>
//    catchVariable: <string>
//}
#endregion
function __executeInLineTryCatchFinally(_struct) {
	
	try {
		__inline_execute(_struct.tryBlock)
    }
    catch(_e) {
		if (_struct.parentNode.shouldReturn) return;
		if (_struct.catchBlock != undefined) {
			//locals = variable_clone(locals, 1)
			_struct.parentNode.locals[$ _struct.catchVariableName] = _e
			__inline_execute(_struct.catchBlock)
		}
    }
    
	if (_struct.finallyBlock != undefined) {
		__inline_execute(_struct.finallyBlock);
	}
}
function __compileInLineTryCatchFinally(_rootNode, _parentNode, _tryBlock, _catchBlock, _finallyBlock, _catchVariableName) {
    var _output = {
		exeFunc: __executeInLineTryCatchFinally,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		tryBlock: __compileInLineLoopStatement(_rootNode, _parentNode, _tryBlock),
		catchVariableName: _catchVariableName,
		catchBlock: undefined,
		finallyBlock: undefined,
    }
	
	if (_catchBlock != undefined)   _output.catchBlock   = __compileInLineBlockStatement(_rootNode, _parentNode, _catchBlock)
	if (_finallyBlock != undefined) _output.finallyBlock = __compileInLineBlockStatement(_rootNode, _parentNode, _finallyBlock)
	
    return _output
}


#endregion

#region Keyword Statements

#region //{
// used to inform gmlc that a break has occured
//    no data needed
//}
#endregion
function __executeInLineBreak(_struct) {
    _struct.parentNode.shouldBreak = true;
}
function __compileInLineBreak(_rootNode, _parentNode) {
    var _output = {
		exeFunc: __executeInLineBreak,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
    }
    
    return _output
}
#region //{
// used to inform gmlc that a continue has occured
//    no data needed
//}
#endregion
function __executeInLineContinue(_struct) {
    _struct.parentNode.shouldContinue = true;
}
function __compileInLineContinue(_rootNode, _parentNode) {
    var _output = {
		exeFunc: __executeInLineContinue,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
    }
    
    return _output
}
#region //{
// used to inform gmlc that an exit has occured
//    no data needed
//}
#endregion
function __executeInLineExit(_struct) {
    _struct.parentNode.shouldReturn = true;
    _struct.parentNode.returnValue = undefined;
}
function __compileInLineExit(_rootNode, _parentNode) {
    var _output = {
		exeFunc: __executeInLineExit,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
    }
    
    return _output
}
#region //{
// used to inform gmlc that an exit has occured
//    expression: <expression>
//}
#endregion
function __executeInLineReturn(_struct) {
    _struct.parentNode.returnValue = __inline_execute(_struct.expression);
	_struct.parentNode.shouldReturn = true;
}
function __compileInLineReturn(_rootNode, _parentNode, _expression) {
	var _output = {
		exeFunc: __executeInLineReturn,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		expression: __compileInLineExpression(_rootNode, _parentNode, _expression),
    }
    
    return _output
}

#region //{
// used to execute gmlc compiled `throw` statement
//    expression: <exprettion> // expects a string as result
//}
#endregion
function __executeInLineThrow(_struct) {
	throw __inline_execute(_struct.expression);
}
function __compileInLineThrow(_rootNode, _parentNode, _expression) {
    var _output = {
		exeFunc: __executeInLineThrow,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		expression: __compileInLineExpression(_rootNode, _parentNode, _expression),
    }
    
    return _output
}

//NOTE: TODO
//VariableDeclarationList
//VariableDeclaration
//MacroDeclaration
//MacroIdentifier
//EnumDeclaration
//EnumIdentifier

#endregion

#region Targeters / Getter / Setters

#region //{
// used for natively compiled functions
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __executeInLinePropertyGet(_struct) {
	return struct_get(__inline_execute(_struct.target), __inline_execute(_struct.key));
}
function __compileInLinePropertyGet(_rootNode, _parentNode, _scope, _leftKey){
	if (_scope == ScopeType.UNIQUE) {
		var _output = {
			exeFunc: __executeInLinePropertyGet,
			errorMessage: "<Missing Error Message>",
			
			rootNode: _rootNode,
		parentNode: _parentNode,
		
			key: _leftKey,
			expression: _rightExpression,
		}
		
		return _output
	}
	
	var _output = {
		exeFunc: __executeInLinePropertyGet,
		errorMessage: "<Missing Error Message>",
	    
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: __getScopeTargetInLine(_scope, _rootNode, _parentNode),
		key: _leftKey,
	}
	
	return _output
}

#region //{
// used for natively compiled functions
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __executeInLinePropertySet(_struct) {
	struct_set(
		__inline_execute(_struct.target),
		__inline_execute(_struct.key),
		__inline_execute(_struct.expression)
	);
}
function __compileInLinePropertySet(_rootNode, _parentNode, _scope, _leftKey, _rightExpression){
	if (_scope == ScopeType.UNIQUE) {
		var _output = {
			exeFunc: __executeInLinePropertySet,
			errorMessage: "<Missing Error Message>",
			
			rootNode: _rootNode,
			parentNode: _parentNode,
		
			key: _leftKey,
			expression: _rightExpression,
		}
		
		return _output
	}
	
	var _output = {
		exeFunc: __executeInLinePropertySet,
		errorMessage: "<Missing Error Message>",
	    
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: __getScopeTargetInLine(_scope, _rootNode, _parentNode),
		key: _leftKey,
		expression: _rightExpression,
	}
	
	return _output
}

#region Scope Getters/Setters
function __getScopeTargetInLine(_scopeType, _rootNode, _parentNode) {
	var _output = {
		exeFunc: undefined,
		
		rootNode: _rootNode,
		parentNode: _parentNode,
	};
	switch (_scopeType) {
		case ScopeType.GLOBAL:   _output.exeFunc = __executeInLineTargetGlobal    break;
		case ScopeType.LOCAL:    _output.exeFunc = __executeInLineTargetVarLocal  break;
		case ScopeType.STATIC:   _output.exeFunc = __executeInLineTargetVarStatic break;
		case ScopeType.INSTANCE: _output.exeFunc = __executeInLineTargetSelf      break;
		case ScopeType.CONST:    _output.exeFunc = __executeInLineTargetConstant  break;
		case ScopeType.UNIQUE:   _output.exeFunc = __executeInLineTargetUnique    break;
		default: throw $"Unsupported scope to be written to :: {_scopeType}";
	}
	return _output;
}

#region //{
//}
#endregion
function __executeInLineTargetSelf(_struct) {
    return global.selfInstance;
}
#region //{
//}
#endregion
function __executeInLineTargetOther(_struct) {
    return global.otherInstance;
}
#region //{
//}
#endregion
function __executeInLineTargetGlobal(_struct) {
    return _struct.rootNode.globals;
}
#region //{
//}
#endregion
function __executeInLineTargetVarLocal(_struct) {
	return _struct.parentNode.locals;
}
#region //{
//}
#endregion
function __executeInLineTargetVarStatic(_struct) {
    return _struct.parentNode.statics;
}
#region //{
//}
#endregion
function __executeInLineTargetUnique(_struct) {
    throw $"Shouldn't be trying to target Unique Scope"
}

#region //{
//    key: <expression>
//}
#endregion
function __executeInLineGetSelf(_struct) {
    return global.selfInstance;
}
#region //{
//    key: <expression>
//}
#endregion
function __executeInLineGetOther(_struct) {
    return global.otherInstance;
}
#region //{
//    key: <expression>
//}
#endregion
function __executeInLineGetGlobal(_struct) {
    return rootNode.globals;
}
#region //{
//    key: <expression>
//}
#endregion
function __executeInLineGetVarLocal(_struct) {
    return _struct.parentNode.locals;
}
#region //{
//    key: <expression>
//}
#endregion
function __executeInLineGetVarStatic(_struct) {
    return statics;
}
#region //{
//    key: <expression>
//}
#endregion
function __executeInLineGetUnique(_struct) {
    switch (_struct.key) {
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
		case "argument":				 return _struct.parentNode.arguments    ;  break;
		case "argument0":				return _struct.parentNode.arguments[0] ;  break;
		case "argument1":				return _struct.parentNode.arguments[1] ;  break;
		case "argument2":				return _struct.parentNode.arguments[2] ;  break;
		case "argument3":				return _struct.parentNode.arguments[3] ;  break;
		case "argument4":				return _struct.parentNode.arguments[4] ;  break;
		case "argument5":				return _struct.parentNode.arguments[5] ;  break;
		case "argument6":				return _struct.parentNode.arguments[6] ;  break;
		case "argument7":				return _struct.parentNode.arguments[7] ;  break;
		case "argument8":				return _struct.parentNode.arguments[8] ;  break;
		case "argument9":				return _struct.parentNode.arguments[9] ;  break;
		case "argument10":		       return _struct.parentNode.arguments[10];  break;
		case "argument11":		       return _struct.parentNode.arguments[11];  break;
		case "argument12":		       return _struct.parentNode.arguments[12];  break;
		case "argument13":		       return _struct.parentNode.arguments[13];  break;
		case "argument14":		       return _struct.parentNode.arguments[14];  break;
		case "argument15":		       return _struct.parentNode.arguments[15];  break;
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
		case "argument_count":		   return array_length(_struct.parentNode.arguments);		    break;
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
		case "argument_relative":		return argument_relative;		 break;
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
function __compileInLineGetUnique(_rootNode, _parentNode, _key) {
	var _output = {
		exeFunc: __executeInLineGetUnique,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		key: _key,
    }
    
    return _output
}


#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __executeInLineSetSelf(_struct) {
    return struct_set(global.selfInstance, key, __inline_execute(_struct.expression))
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __executeInLineSetOther(_struct) {
    return struct_set(global.otherInstance, key, __inline_execute(_struct.expression))
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __executeInLineSetGlobal(_struct) {
    return struct_set(globals, key, __inline_execute(_struct.expression))
}
#region //{
//    key: <stringLiteral>
//    expression: <expression>
//}
#endregion
function __executeInLineSetVarLocal(_struct) {
    return struct_set(_struct.parentNode.locals, key, __inline_execute(_struct.expression))
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __executeInLineSetVarStatic(_struct) {
    return struct_set(statics, key, __inline_execute(_struct.expression))
}
#region //{
//    key: <expression>
//    expression: <expression>
//}
#endregion
function __executeInLineSetUnique(_struct) {
	switch (key) {
		//all write protected errors are at the bottom
		case "room":				     room				      = __inline_execute(_struct.expression); break;
		case "lives":				    lives				     = __inline_execute(_struct.expression); break;
		case "score":				    score				     = __inline_execute(_struct.expression); break;
		case "health":				   health				    = __inline_execute(_struct.expression); break;
		case "visible":				  visible				   = __inline_execute(_struct.expression); break;
		case "argument":				 arguments      = __inline_execute(_struct.expression); break;
		case "argument0":				arguments[0]   = __inline_execute(_struct.expression); break;
		case "argument1":				arguments[1]   = __inline_execute(_struct.expression); break;
		case "argument2":				arguments[2]   = __inline_execute(_struct.expression); break;
		case "argument3":				arguments[3]   = __inline_execute(_struct.expression); break;
		case "argument4":				arguments[4]   = __inline_execute(_struct.expression); break;
		case "argument5":				arguments[5]   = __inline_execute(_struct.expression); break;
		case "argument6":				arguments[6]   = __inline_execute(_struct.expression); break;
		case "argument7":				arguments[7]   = __inline_execute(_struct.expression); break;
		case "argument8":				arguments[8]   = __inline_execute(_struct.expression); break;
		case "argument9":				arguments[9]   = __inline_execute(_struct.expression); break;
		case "argument10":		       arguments[10]  = __inline_execute(_struct.expression); break;
		case "argument11":		       arguments[11]  = __inline_execute(_struct.expression); break;
		case "argument12":		       arguments[12]  = __inline_execute(_struct.expression); break;
		case "argument13":		       arguments[13]  = __inline_execute(_struct.expression); break;
		case "argument14":		       arguments[14]  = __inline_execute(_struct.expression); break;
		case "argument15":		       arguments[15]  = __inline_execute(_struct.expression); break;
		case "show_lives":		       show_lives				= __inline_execute(_struct.expression); break;
		case "room_width":		       room_width				= __inline_execute(_struct.expression); break;
		case "view_hport":		       view_hport				= __inline_execute(_struct.expression); break;
		case "view_xport":		       view_xport				= __inline_execute(_struct.expression); break;
		case "view_yport":		       view_yport				= __inline_execute(_struct.expression); break;
		case "view_wport":		       view_wport				= __inline_execute(_struct.expression); break;
		case "room_speed":		       room_speed				= __inline_execute(_struct.expression); break;
		case "show_score":		       show_score				= __inline_execute(_struct.expression); break;
		case "error_last":		       error_last				= __inline_execute(_struct.expression); break;
		case "view_camera":		      view_camera		       = __inline_execute(_struct.expression); break;
		case "room_height":		      room_height		       = __inline_execute(_struct.expression); break;
		case "show_health":		      show_health		       = __inline_execute(_struct.expression); break;
		case "mouse_button":		     mouse_button		      = __inline_execute(_struct.expression); break;
		case "keyboard_key":		     keyboard_key		      = __inline_execute(_struct.expression); break;
		case "view_visible":		     view_visible		      = __inline_execute(_struct.expression); break;
		case "room_caption":		     room_caption		      = __inline_execute(_struct.expression); break;
		case "view_enabled":		     view_enabled		      = __inline_execute(_struct.expression); break;
		case "caption_score":		    caption_score		     = __inline_execute(_struct.expression); break;
		case "caption_lives":		    caption_lives		     = __inline_execute(_struct.expression); break;
		case "cursor_sprite":		    cursor_sprite		     = __inline_execute(_struct.expression); break;
		case "caption_health":		   caption_health		    = __inline_execute(_struct.expression); break;
		case "error_occurred":		   error_occurred		    = __inline_execute(_struct.expression); break;
		case "view_surface_id":		  view_surface_id		   = __inline_execute(_struct.expression); break;
		case "room_persistent":		  room_persistent		   = __inline_execute(_struct.expression); break;
		case "keyboard_string":		  keyboard_string		   = __inline_execute(_struct.expression); break;
		case "mouse_lastbutton":		 mouse_lastbutton		  = __inline_execute(_struct.expression); break;
		case "keyboard_lastkey":		 keyboard_lastkey		  = __inline_execute(_struct.expression); break;
		case "background_color":		 background_color		  = __inline_execute(_struct.expression); break;
		case "keyboard_lastchar":		keyboard_lastchar		 = __inline_execute(_struct.expression); break;
		case "background_colour":		background_colour		 = __inline_execute(_struct.expression); break;
		case "font_texture_page_size":   font_texture_page_size    = __inline_execute(_struct.expression); break;
		case "background_showcolor":     background_showcolor      = __inline_execute(_struct.expression); break;
		case "background_showcolour":    background_showcolour     = __inline_execute(_struct.expression); break;
		
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
		case "os_device": throw $"Attempting to write to a read-only variable {key}";
	}
}
function __compileInLineSetUnique(_rootNode, _parentNode, _key, _value) {
	var _output = {
		exeFunc: __executeInLineSetUnique,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		key: _key,
		value: _value,
    }
    
    return _output
}
#endregion

function __compileInLineAccessor(_rootNode, _parentNode, _accessorNode) {
	
	var _target = __compileInLineExpression(_rootNode, _parentNode, _accessorNode.expr)
	var _key = __compileInLineExpression(_rootNode, _parentNode, _accessorNode.val1)
	
	switch (_accessorNode.accessorType) {
		case __GMLC_AccessorType.Array:  return __compileInLineArrayGet       (_rootNode, _parentNode, _target, _key)
		case __GMLC_AccessorType.Grid:   return __compileInLineGridGet		(_rootNode, _parentNode, _target, _key, __compileInLineExpression(_rootNode, _parentNode, _accessorNode.val1))
		case __GMLC_AccessorType.List:   return __compileInLineListGet		(_rootNode, _parentNode, _target, _key)
		case __GMLC_AccessorType.Map:    return __compileInLineMapGet		 (_rootNode, _parentNode, _target, _key)
		case __GMLC_AccessorType.Struct: return __compileInLineStructGet      (_rootNode, _parentNode, _target, _key)
		case __GMLC_AccessorType.Dot:    return __compileInLineStructDotAccGet(_rootNode, _parentNode, _target, _key)
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
function __executeInLineArrayGet(_struct){
	var _target = __inline_execute(_struct.target);
	return _target[__inline_execute(_struct.key)]
}
function __compileInLineArrayGet(_rootNode, _parentNode, _target, _key) {
    var _output = {
		exeFunc: __executeInLineArrayGet,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
    }
	
	return _output
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __executeInLineArraySet(_struct){
	var _target = __inline_execute(_struct.target);
	_target[__inline_execute(_struct.key)] = __inline_execute(_struct.expression)
}
function __compileInLineArraySet(_rootNode, _parentNode, _target, _key, _expression) {
    var _output = {
		exeFunc: __executeInLineArraySet,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
		expression: _expression,
    }
    return _output
}
#endregion
#region List
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __executeInLineListGet(_struct){
	var _target = __inline_execute(_struct.target);
	return _target[| __inline_execute(_struct.key)]
}
function __compileInLineListGet(_rootNode, _parentNode, _target, _key) {
    var _output = {
		exeFunc: __executeInLineListGet,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
    }
    return _output
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __executeInLineListSet(_struct){
	var _target = __inline_execute(_struct.target);
	_target[| __inline_execute(_struct.key)] = __inline_execute(_struct.expression)
}
function __compileInLineListSet(_rootNode, _parentNode, _target, _key, _expression) {
    var _output = {
		exeFunc: __executeInLineListSet,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
		expression: _expression,
    }
    return _output
}
#endregion
#region Map
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __executeInLineMapGet(_struct){
	var _target = __inline_execute(_struct.target);
	return _target[? __inline_execute(_struct.key)]
}
function __compileInLineMapGet(_rootNode, _parentNode, _target, _key) {
    var _output = {
		exeFunc: __executeInLineMapGet,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
    }
    return _output
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __executeInLineMapSet(_struct){
	var _target = __inline_execute(_struct.target);
	_target[? __inline_execute(_struct.key)] = __inline_execute(_struct.expression)
}
function __compileInLineMapSet(_rootNode, _parentNode, _target, _key, _expression) {
    var _output = {
		exeFunc: __executeInLineMapSet,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
		expression: _expression,
    }
    return _output
}
#endregion

#region Grid
#region //{
//    target: <expression>,
//    keyX: <expression>,
//    keyY: <expression>,
//}
#endregion
function __executeInLineGridGet(_struct){
	var _target = __inline_execute(_struct.target);
	return _target[# __inline_execute(_struct.keyX), __inline_execute(_struct.keyY)]
}
function __compileInLineGridGet(_rootNode, _parentNode, _target, _keyX, _keyY) {
    var _output = {
		exeFunc: __executeInLineGridGet,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		keyX: _keyX,
		keyY: _keyY,
    }
    return _output
}
#region //{
//    target: <expression>,
//    keyX: <expression>,
//    keyY: <expression>,
//    expression: <expression>,
//}
#endregion
function __executeInLineGridSet(_struct){
	var _target = __inline_execute(_struct.target);
	_target[# __inline_execute(_struct.keyX), __inline_execute(_struct.keyY)] = __inline_execute(_struct.expression)
}
function __compileInLineGridSet(_rootNode, _parentNode, _target, _keyX, _keyY, _expression) {
    var _output = {
		exeFunc: __executeInLineGridSet,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		keyX: _keyX,
		keyY: _keyY,
		expression: _expression,
    }
    return _output
}
#endregion
#region Struct
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __executeInLineStructGet(_struct){
	var _target = __inline_execute(_struct.target);
	return _target[$ __inline_execute(_struct.key)]
}
function __compileInLineStructGet(_rootNode, _parentNode, _target, _key) {
    var _output = {
		exeFunc: __executeInLineStructGet,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
    }
    return _output
}
#region //{
//    target: <expression>,
//    key: <expression>,
//    expression: <expression>,
//}
#endregion
function __executeInLineStructSet(_struct){
	var _target = __inline_execute(_struct.target);
	_target[$ __inline_execute(_struct.key)] = __inline_execute(_struct.expression)
}
function __compileInLineStructSet(_rootNode, _parentNode, _target, _key, _expression) {
    var _output = {
		exeFunc: __executeInLineStructSet,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
		expression: _expression,
    }
    return _output
}
#endregion
#region Struct w/ Error
#region //{
//    target: <expression>,
//    key: <stringLiteral>,
//}
#endregion
function __executeInLineStructDotAccGet(_struct){
	var _target = __inline_execute(_struct.target);
	var _key = __inline_execute(_struct.key);
	if (!struct_exists(_target, _key)) throw $"\nVariable <unknown_object>.{_key} not set before reading it."
	return _target[$ _key];
}
function __compileInLineStructDotAccGet(_rootNode, _parentNode, _target, _key) {
	var _output = {
		exeFunc: __executeInLineStructDotAccGet,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
    }
	
	return _output
}
#region //{
//    target: <expression>,
//    key: <stringLiteral>,
//    expression: <expression>,
//}
#endregion
function __executeInLineStructDotAccSet(_struct){
	var _target = __inline_execute(_struct.target);
	var _target = _target;
    if (!struct_exists(_target, key)) throw $"\nVariable <unknown_object>.{name} not set before reading it."
	_target[$ key] = __inline_execute(_struct.expression);
}
function __compileInLineStructDotAccSet(_rootNode, _parentNode, _target, _key, _expression) {
    var _output = {
		exeFunc: __executeInLineStructDotAccSet,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _target,
		key: _key,
		expression: _expression,
    }
    return _output
}
#endregion

#endregion

#endregion

#region Math Expressions
function __compileInLineAssignmentExpression(_rootNode, _parentNode, _scope, _operator, _leftNode, _rightNode) {
	
	if (_leftNode.type == __GMLC_NodeType.AccessorExpression) {
		var _target = __compileInLineExpression(_rootNode, _parentNode, _leftNode.expr);
		var _key = __compileInLineExpression(_rootNode, _parentNode, _leftNode.val1);
		var _expression = __compileInLineExpression(_rootNode, _parentNode, _rightNode);
		
		if (_operator == "=") {
			switch (_leftNode.accessorType) {
				case __GMLC_AccessorType.Array:  return __compileInLineArraySet       (_rootNode, _parentNode, _target, _key, _expression);
				case __GMLC_AccessorType.Grid:   return __compileInLineGridSet		(_rootNode, _parentNode, _target, _key, __compileInLineExpression(_rootNode, _parentNode, _leftNode.val2), _expression);
				case __GMLC_AccessorType.List:   return __compileInLineListSet		(_rootNode, _parentNode, _target, _key, _expression);
				case __GMLC_AccessorType.Map:    return __compileInLineMapSet		 (_rootNode, _parentNode, _target, _key, _expression);
				case __GMLC_AccessorType.Struct: return __compileInLineStructSet      (_rootNode, _parentNode, _target, _key, _expression);
				case __GMLC_AccessorType.Dot:    return __compileInLineStructDotAccSet(_rootNode, _parentNode, _target, _key, _expression);
			}
		}
		else {
			var _opToCompile = undefined
			switch (_operator) {
				case "+=":  _opToCompile = __compileInLineOpPlus;
				case "-=":  _opToCompile = __compileInLineOpMinus;
				case "*=":  _opToCompile = __compileInLineOpMultiply;
				case "/=":  _opToCompile = __compileInLineOpDivide;
				case "^=":  _opToCompile = __compileInLineOpBitwiseXOR;
				case "&=":  _opToCompile = __compileInLineOpBitwiseAND;
				case "|=":  _opToCompile = __compileInLineOpBitwiseOR;
				case "??=": _opToCompile = __compileInLineOpNullish;
			}
			
			switch (_leftNode.accessorType) {
				case __GMLC_AccessorType.Array:  return __compileInLineArraySet       (_rootNode, _parentNode, _target, _key, _opToCompile(_rootNode, _parentNode, __compileInLineArrayGet       (_rootNode, _parentNode, _target, _key), _expression))
				case __GMLC_AccessorType.Grid:   return __compileInLineGridSet		(_rootNode, _parentNode, _target, _key, __compileInLineExpression(_rootNode, _parentNode, _leftNode.val2), _opToCompile(_rootNode, _parentNode, __compileInLineGridGet		(_rootNode, _parentNode, _target, _key, __compileInLineExpression(_rootNode, _parentNode, _leftNode.val2)), _expression))
				case __GMLC_AccessorType.List:   return __compileInLineListSet		(_rootNode, _parentNode, _target, _key, _opToCompile(_rootNode, _parentNode, __compileInLineListGet		(_rootNode, _parentNode, _target, _key), _expression))
				case __GMLC_AccessorType.Map:    return __compileInLineMapSet		 (_rootNode, _parentNode, _target, _key, _opToCompile(_rootNode, _parentNode, __compileInLineMapGet		 (_rootNode, _parentNode, _target, _key), _expression))
				case __GMLC_AccessorType.Struct: return __compileInLineStructSet      (_rootNode, _parentNode, _target, _key, _opToCompile(_rootNode, _parentNode, __compileInLineStructGet      (_rootNode, _parentNode, _target, _key), _expression))
				case __GMLC_AccessorType.Dot:    return __compileInLineStructDotAccSet(_rootNode, _parentNode, _target, _key, _opToCompile(_rootNode, _parentNode, __compileInLineStructDotAccGet(_rootNode, _parentNode, _target, _key), _expression))
			}
		}
	}
	
	if (_leftNode.type == __GMLC_NodeType.Identifier) {
		var _key = __compileInLineLiteralExpression(_rootNode, _parentNode, _leftNode.value);
		var _expression = __compileInLineExpression(_rootNode, _parentNode, _rightNode);
	
		switch (_operator) {
			case "=":   return __compileInLinePropertySet		   (_rootNode, _parentNode, _scope, _key, _expression); break;
			case "+=":  return __compileInLineOpAssignmentPlus      (_rootNode, _parentNode, _scope, _key, _expression); break;
			case "-=":  return __compileInLineOpAssignmentMinus     (_rootNode, _parentNode, _scope, _key, _expression); break;
			case "*=":  return __compileInLineOpAssignmentMultiply  (_rootNode, _parentNode, _scope, _key, _expression); break;
			case "/=":  return __compileInLineOpAssignmentDivide    (_rootNode, _parentNode, _scope, _key, _expression); break;
			case "^=":  return __compileInLineOpAssignmentBitwiseXOR(_rootNode, _parentNode, _scope, _key, _expression); break;
			case "&=":  return __compileInLineOpAssignmentBitwiseAND(_rootNode, _parentNode, _scope, _key, _expression); break;
			case "|=":  return __compileInLineOpAssignmentBitwiseOR (_rootNode, _parentNode, _scope, _key, _expression); break;
			case "??=": return __compileInLineOpAssignmentNullish   (_rootNode, _parentNode, _scope, _key, _expression); break;
		}
	}
	
	throw $"Couldn't find a proper assignment op for the node type :: {_leftNode.type}"
}
#region Assignment Expressions
function __compileInLineOpAssignmentPlus(_rootNode, _parentNode, _scope, _leftKey, _rightExpression) {
	return __compileInLinePropertySet(_rootNode, _parentNode, _scope, _leftKey, __compileInLineOpPlus(_rootNode, _parentNode, __compileInLinePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression))
}
function __compileInLineOpAssignmentMinus(_rootNode, _parentNode, _scope, _leftKey, _rightExpression) {
	return __compileInLinePropertySet(_rootNode, _parentNode, _scope, _leftKey, __compileInLineOpMinus(_rootNode, _parentNode, __compileInLinePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression))
}
function __compileInLineOpAssignmentMultiply(_rootNode, _parentNode, _scope, _leftKey, _rightExpression) {
	return __compileInLinePropertySet(_rootNode, _parentNode, _scope, _leftKey, __compileInLineOpMultiply(_rootNode, _parentNode, __compileInLinePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression))
}
function __compileInLineOpAssignmentDivide(_rootNode, _parentNode, _scope, _leftKey, _rightExpression){
	return __compileInLinePropertySet(_rootNode, _parentNode, _scope, _leftKey, __compileInLineOpDivide(_rootNode, _parentNode, __compileInLinePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression))
}
function __compileInLineOpAssignmentBitwiseXOR(_rootNode, _parentNode, _scope, _leftKey, _rightExpression){
	return __compileInLinePropertySet(_rootNode, _parentNode, _scope, _leftKey, __compileInLineOpBitwiseXOR(_rootNode, _parentNode, __compileInLinePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression))
}
function __compileInLineOpAssignmentBitwiseAND(_rootNode, _parentNode, _scope, _leftKey, _rightExpression){
	return __compileInLinePropertySet(_rootNode, _parentNode, _scope, _leftKey, __compileInLineOpBitwiseAND(_rootNode, _parentNode, __compileInLinePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression))
}
function __compileInLineOpAssignmentBitwiseOR(_rootNode, _parentNode, _scope, _leftKey, _rightExpression){
	return __compileInLinePropertySet(_rootNode, _parentNode, _scope, _leftKey, __compileInLineOpBitwiseOR(_rootNode, _parentNode, __compileInLinePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression))
}
function __compileInLineOpAssignmentNullish(_rootNode, _parentNode, _scope, _leftKey, _rightExpression){
	return __compileInLinePropertySet(_rootNode, _parentNode, _scope, _leftKey, __compileInLineOpNullish(_rootNode, _parentNode, __compileInLinePropertyGet(_rootNode, _parentNode, _scope, _leftKey), _rightExpression))
}

#endregion

function __compileInLineBinaryExpression(_rootNode, _parentNode, _operator, _leftNode, _rightNode) {
	var _leftExpression = __compileInLineExpression(_rootNode, _parentNode, _leftNode);
	var _rightExpression = __compileInLineExpression(_rootNode, _parentNode, _rightNode);
	
	switch (_operator) {
		case "==":  return __compileInLineOpEqualsEquals(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "!=":  return __compileInLineOpNotEquals(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "<":   return __compileInLineOpLess(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "<=":  return __compileInLineOpLessEquals(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case ">":   return __compileInLineOpGreater(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case ">=":  return __compileInLineOpGreaterEquals(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "+":   return __compileInLineOpPlus(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "-":   return __compileInLineOpMinus(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "*":   return __compileInLineOpMultiply(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "/":   return __compileInLineOpDivide(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "mod": return __compileInLineOpMod(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "div": return __compileInLineOpDiv(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "|":   return __compileInLineOpBitwiseOR(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "^":   return __compileInLineOpBitwiseXOR(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "&":   return __compileInLineOpBitwiseAND(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case "<<":  return __compileInLineOpBitwiseShiftLeft(_rootNode, _parentNode, _leftExpression, _rightExpression);
		case ">>":  return __compileInLineOpBitwiseShiftRight(_rootNode, _parentNode, _leftExpression, _rightExpression);
	}
}
#region Binary Expressions
#region Equality Ops
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpEqualsEquals(_struct) {
    return __inline_execute(_struct.left) == __inline_execute(_struct.right);
}
function __compileInLineOpEqualsEquals(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpEqualsEquals,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpNotEquals(_struct) {
    return __inline_execute(_struct.left) != __inline_execute(_struct.right);
}
function __compileInLineOpNotEquals(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpNotEquals,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpLess(_struct) {
    return __inline_execute(_struct.left) < __inline_execute(_struct.right);
}
function __compileInLineOpLess(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpLess,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpLessEquals(_struct) {
    return __inline_execute(_struct.left) <= __inline_execute(_struct.right);
}
function __compileInLineOpLessEquals(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpLessEquals,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpGreater(_struct) {
    return __inline_execute(_struct.left) > __inline_execute(_struct.right);
}
function __compileInLineOpGreater(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpGreater,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpGreaterEquals(_struct) {
    return __inline_execute(_struct.left) >= __inline_execute(_struct.right);
}
function __compileInLineOpGreaterEquals(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpGreaterEquals,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#endregion
#region Basic Ops
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpPlus(_struct) {
	return __inline_execute(_struct.left) + __inline_execute(_struct.right);
}
function __compileInLineOpPlus(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpPlus,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
	return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpMinus(_struct) {
    return __inline_execute(_struct.left) - __inline_execute(_struct.right);
}
function __compileInLineOpMinus(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpMinus,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpMultiply(_struct) {
	return __inline_execute(_struct.left) * __inline_execute(_struct.right);
}
function __compileInLineOpMultiply(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpMultiply,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpDivide(_struct) {
    return __inline_execute(_struct.left) / __inline_execute(_struct.right);
}
function __compileInLineOpDivide(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpDivide,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}

#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpDiv(_struct) {
    return __inline_execute(_struct.left) div __inline_execute(_struct.right);
}
function __compileInLineOpDiv(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpDiv,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpMod(_struct) {
    return __inline_execute(_struct.left) mod __inline_execute(_struct.right);
}
function __compileInLineOpMod(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpMod,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#endregion
#region Bitwise Ops
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpBitwiseOR(_struct) {
    return __inline_execute(_struct.left) | __inline_execute(_struct.right);
}
function __compileInLineOpBitwiseOR(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpBitwiseOR,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpBitwiseAND(_struct) {
    return __inline_execute(_struct.left) & __inline_execute(_struct.right);
}
function __compileInLineOpBitwiseAND(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpBitwiseAND,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpBitwiseXOR(_struct) {
    return __inline_execute(_struct.left) ^ __inline_execute(_struct.right);
}
function __compileInLineOpBitwiseXOR(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpBitwiseXOR,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpBitwiseShiftLeft(_struct) {
    return __inline_execute(_struct.left) << __inline_execute(_struct.right);
}
function __compileInLineOpBitwiseShiftLeft(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpBitwiseShiftLeft,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpBitwiseShiftRight(_struct) {
    return __inline_execute(_struct.left) >> __inline_execute(_struct.right);
}
function __compileInLineOpBitwiseShiftRight(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpBitwiseShiftRight,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#endregion
#endregion

function __compileInLineLogicalExpression(_rootNode, _parentNode, _operator, _leftNode, _rightNode) {
	var _leftExpression = __compileInLineExpression(_rootNode, _parentNode, _leftNode);
	var _rightExpression = __compileInLineExpression(_rootNode, _parentNode, _rightNode);
	
	switch (_operator) {
		case "&&": return __compileInLineOpAND(_rootNode, _parentNode, _leftExpression, _rightExpression); break;
		case "||": return __compileInLineOpOR(_rootNode, _parentNode, _leftExpression, _rightExpression); break;
		case "^^": return __compileInLineOpXOR(_rootNode, _parentNode, _leftExpression, _rightExpression); break;
	}
}
#region Logical Expressions
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpAND(_struct) {
    return __inline_execute(_struct.left) && __inline_execute(_struct.right);
}
function __compileInLineOpAND(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpAND,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpOR(_struct) {
    return __inline_execute(_struct.left) || __inline_execute(_struct.right);
}
function __compileInLineOpOR(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpOR,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpXOR(_struct) {
    return __inline_execute(_struct.left) ^^ __inline_execute(_struct.right);
}
function __compileInLineOpXOR(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpXOR,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}

#endregion

function __compileInLineNullishExpression(_rootNode, _parentNode, _operator, _leftNode, _rightNode) {
	var _leftExpression = __compileInLineExpression(_rootNode, _parentNode, _leftNode);
	var _rightExpression = __compileInLineExpression(_rootNode, _parentNode, _rightNode);
	
	return __compileInLineOpNullish(_rootNode, _parentNode, _leftExpression, _rightExpression);
}
#region Nullish Expressions
#region //{
//    left: <expression>,
//    right: <expression>,
//}
#endregion
function __executeInLineOpNullish(_struct) {
    return __inline_execute(_struct.left) ?? __inline_execute(_struct.right);
}
function __compileInLineOpNullish(_rootNode, _parentNode, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpNullish,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		left: _leftExpression,
		right: _rightExpression,
    }
    
    return _output
}

#endregion

function __compileInLineUnaryExpression(_rootNode, _parentNode, _operator, _exprNode) {
	var _expression = __compileInLineExpression(_rootNode, _parentNode, _exprNode);
	
	switch (_operator) {
		case "!": return __compileInLineOpNot(_rootNode, _parentNode, _expression) break;
		case "+": return _expression break;
		case "-": return __compileInLineOpNegate(_rootNode, _parentNode, _expression) break;
		case "~": return __compileInLineOpBitwiseNegate(_rootNode, _parentNode, _expression) break;
		//case "++": ___ break;
		//case "--": ___ break;
	}
}
#region Unary Expressions
#region //{
//    left: <expression>,
//}
#endregion
function __executeInLineOpNot(_struct) {
    return !__inline_execute(_struct.right);
}
function __compileInLineOpNot(_rootNode, _parentNode, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpNot,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//}
#endregion
function __executeInLineOpNegate(_struct) {
    return -__inline_execute(_struct.right);
}
function __compileInLineOpNegate(_rootNode, _parentNode, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpNegate,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		right: _rightExpression,
    }
    
    return _output
}
#region //{
//    left: <expression>,
//}
#endregion
function __executeInLineOpBitwiseNegate(_struct) {
    return ~__inline_execute(_struct.right);
}
function __compileInLineOpBitwiseNegate(_rootNode, _parentNode, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineOpBitwiseNegate,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		right: _rightExpression,
    }
    
    return _output
}
#endregion

function __compileInLineConditionalExpression(_rootNode, _parentNode, _conditionNode, _leftNode, _rightNode) {
	var _conditionExpression = __compileInLineExpression(_rootNode, _parentNode, _conditionNode);
	var _leftExpression = __compileInLineExpression(_rootNode, _parentNode, _leftNode);
	var _rightExpression = __compileInLineExpression(_rootNode, _parentNode, _rightNode);
	
	return __compileInLineTernaryExpression(_rootNode, _parentNode, _conditionExpression, _leftExpression, _rightExpression);
}
#region Conditional Expressions
#region //{
//    condition: <expression>,
//    trueExpression: <expression>,
//    falseExpression: <expression>,
//}
#endregion
function __executeInLineTernaryExpression(_struct) {
    return __inline_execute(_struct.condition) ? __inline_execute(_struct.left) : __inline_execute(_struct.right);
}
function __compileInLineTernaryExpression(_rootNode, _parentNode, _conditionExpression, _leftExpression, _rightExpression) {
    var _output = {
		exeFunc: __executeInLineTernaryExpression,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		condition: __compileInLineExpression(_rootNode, _parentNode, _conditionExpression),
		left: __compileInLineExpression(_rootNode, _parentNode, _leftExpression),
		right: __compileInLineExpression(_rootNode, _parentNode, _rightExpression),
    }
    
    return _output
}

#endregion

function __compileInLineUpdateExpression(_rootNode, _parentNode, _node) {
	if (_node.expr.type == __GMLC_NodeType.Identifier) {
		
		var _target = __getScopeTargetInLine(_node.expr.scope, _rootNode, _parentNode)
		var _key = _node.expr.value;
		var _increment = (_node.operator == "++") ? true : false;
		var _prefix = _node.prefix;
		
		return __compileInLineUpdateStructDotAcc(_rootNode, _parentNode, _target, _key, _increment, _prefix)
	}
	else if (_node.expr.type == __GMLC_NodeType.AccessorExpression) {
		
		var _target = __compileInLineExpression(_rootNode, _parentNode, _node.expr)
		var _key = __compileInLineExpression(_rootNode, _parentNode, _node.val1)
		var _increment = (_node.operator == "++") ? true : false;
		var _prefix = _node.prefix;
		
		switch (_node.expr.accessorType) {
			case __GMLC_AccessorType.Array:  return __compileInLineUpdateArray       (_rootNode, _parentNode, _target, _key, _increment, _prefix);
			case __GMLC_AccessorType.Grid:   return __compileInLineUpdateGrid		(_rootNode, _parentNode, _target, _key, __compileInLineExpression(_rootNode, _parentNode, _node.val2), _increment, _prefix);
			case __GMLC_AccessorType.List:   return __compileInLineUpdateList		(_rootNode, _parentNode, _target, _key, _increment, _prefix);
			case __GMLC_AccessorType.Map:    return __compileInLineUpdateMap		 (_rootNode, _parentNode, _target, _key, _increment, _prefix);
			case __GMLC_AccessorType.Struct: return __compileInLineUpdateStruct      (_rootNode, _parentNode, _target, _key, _increment, _prefix);
			case __GMLC_AccessorType.Dot:    return __compileInLineUpdateStructDotAcc(_rootNode, _parentNode, _target, _key, _increment, _prefix);
		}
		
	}
	
	throw $"how did we get here?\nwhat expression are we working with?\n{_node.expr}"
	
}
#region Updaters (++ and --)

#region Arrays
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __executeInLineUpdateArrayPlusPlusPrefix(_struct) {
	var _target = __inline_execute(_struct.target);
	return ++_target[__inline_execute(_struct.key)];
}
function __executeInLineUpdateArrayPlusPlusPostfix(_struct) {
	var _target = __inline_execute(_struct.target);
	return _target[__inline_execute(_struct.key)]++;
}
function __executeInLineUpdateArrayMinusMinusPrefix(_struct) {
	var _target = __inline_execute(_struct.target);
	return --_target[__inline_execute(_struct.key)];
}
function __executeInLineUpdateArrayMinusMinusPostfix(_struct) {
	var _target = __inline_execute(_struct.target);
	return _target[__inline_execute(_struct.key)]--;
}
function __compileInLineUpdateArray(_rootNode, _parentNode, _targetExpression, _keyExpression, _increment, _prefix) {
    var _output = {
		exeFunc: __executeInLineUpdateArray,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _targetExpression,
		key: _keyExpression,
    }
    
	if (_increment  &&  _prefix) _output.exeFunc = __executeInLineUpdateArrayPlusPlusPrefix;
	if (_increment  && !_prefix) _output.exeFunc = __executeInLineUpdateArrayPlusPlusPostfix;
	if (!_increment &&  _prefix) _output.exeFunc = __executeInLineUpdateArrayMinusMinusPrefix;
	if (!_increment && !_prefix) _output.exeFunc = __executeInLineUpdateArrayMinusMinusPostfix;
	
	return _output;
}
#endregion
#region List
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __executeInLineUpdateListPlusPlusPrefix(_struct) {
	var _target = __inline_execute(_struct.target);
	return ++_target[| __inline_execute(_struct.key)];
}
function __executeInLineUpdateListPlusPlusPostfix(_struct) {
	var _target = __inline_execute(_struct.target);
	return _target[| __inline_execute(_struct.key)]++;
}
function __executeInLineUpdateListMinusMinusPrefix(_struct) {
	var _target = __inline_execute(_struct.target);
	return --_target[| __inline_execute(_struct.key)];
}
function __executeInLineUpdateListMinusMinusPostfix(_struct) {
	var _target = __inline_execute(_struct.target);
	return _target[| __inline_execute(_struct.key)]--;
}
function __compileInLineUpdateList(_rootNode, _parentNode, _targetExpression, _keyExpression, _increment, _prefix) {
    var _output = {
		exeFunc: __executeInLineUpdateList,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _targetExpression,
		key: _keyExpression,
    }
    
	if (_increment  &&  _prefix) _output.exeFunc = __executeInLineUpdateListPlusPlusPrefix;
	if (_increment  && !_prefix) _output.exeFunc = __executeInLineUpdateListPlusPlusPostfix;
	if (!_increment &&  _prefix) _output.exeFunc = __executeInLineUpdateListMinusMinusPrefix;
	if (!_increment && !_prefix) _output.exeFunc = __executeInLineUpdateListMinusMinusPostfix;
	
	return _output;
}
#endregion
#region Map
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __executeInLineUpdateMapPlusPlusPrefix(_struct) {
	var _target = __inline_execute(_struct.target);
	return ++_target[? __inline_execute(_struct.key)];
}
function __executeInLineUpdateMapPlusPlusPostfix(_struct) {
	var _target = __inline_execute(_struct.target);
	return _target[? __inline_execute(_struct.key)]++;
}
function __executeInLineUpdateMapMinusMinusPrefix(_struct) {
	var _target = __inline_execute(_struct.target);
	return --_target[? __inline_execute(_struct.key)];
}
function __executeInLineUpdateMapMinusMinusPostfix(_struct) {
	var _target = __inline_execute(_struct.target);
	return _target[? __inline_execute(_struct.key)]--;
}
function __compileInLineUpdateMap(_rootNode, _parentNode, _targetExpression, _keyExpression, _increment, _prefix) {
    var _output = {
		exeFunc: __executeInLineUpdateMap,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _targetExpression,
		key: _keyExpression,
    }
    
	if (_increment  &&  _prefix) _output.exeFunc = __executeInLineUpdateMapPlusPlusPrefix;
	if (_increment  && !_prefix) _output.exeFunc = __executeInLineUpdateMapPlusPlusPostfix;
	if (!_increment &&  _prefix) _output.exeFunc = __executeInLineUpdateMapMinusMinusPrefix;
	if (!_increment && !_prefix) _output.exeFunc = __executeInLineUpdateMapMinusMinusPostfix;
	
	return _output;
}
#endregion
#region Grid
#region //{
//    target: <expression>,
//    keyX: <expression>,
//    keyY: <expression>,
//}
#endregion
function __executeInLineUpdateGridPlusPlusPrefix(_struct) {
	var _target = __inline_execute(_struct.target);
	return ++_target[# __inline_execute(_struct.keyX), __inline_execute(_struct.keyY)];
}
function __executeInLineUpdateGridPlusPlusPostfix(_struct) {
	var _target = __inline_execute(_struct.target);
	return _target[# __inline_execute(_struct.keyX), __inline_execute(_struct.keyY)]++;
}
function __executeInLineUpdateGridMinusMinusPrefix(_struct) {
	var _target = __inline_execute(_struct.target);
	return --_target[# __inline_execute(_struct.keyX), __inline_execute(_struct.keyY)];
}
function __executeInLineUpdateGridMinusMinusPostfix(_struct) {
	var _target = __inline_execute(_struct.target);
	return _target[# __inline_execute(_struct.keyX), __inline_execute(_struct.keyY)]--;
}
function __compileInLineUpdateGrid(_rootNode, _parentNode, _targetExpression, _keyXExpression, _keyYExpression, _increment, _prefix) {
    var _output = {
		exeFunc: __executeInLineUpdateGrid,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _targetExpression,
		keyX: _keyXExpression,
		keyY: _keyYExpression,
    }
    
    if (_increment  &&  _prefix) _output.exeFunc = __executeInLineUpdateGridPlusPlusPrefix;
	if (_increment  && !_prefix) _output.exeFunc = __executeInLineUpdateGridPlusPlusPostfix;
	if (!_increment &&  _prefix) _output.exeFunc = __executeInLineUpdateGridMinusMinusPrefix;
	if (!_increment && !_prefix) _output.exeFunc = __executeInLineUpdateGridMinusMinusPostfix;
	
	return _output;
}
#endregion
#region Struct
#region //{
//    target: <expression>,
//    key: <expression>,
//}
#endregion
function __executeInLineUpdateStructPlusPlusPrefix(_struct) {
	var _target = __inline_execute(_struct.target);
	return ++_target[$ __inline_execute(_struct.key)];
}
function __executeInLineUpdateStructPlusPlusPostfix(_struct) {
	var _target = __inline_execute(_struct.target);
	return _target[$ __inline_execute(_struct.key)]++;
}
function __executeInLineUpdateStructMinusMinusPrefix(_struct) {
	var _target = __inline_execute(_struct.target);
	return --_target[$ __inline_execute(_struct.key)];
}
function __executeInLineUpdateStructMinusMinusPostfix(_struct) {
	var _target = __inline_execute(_struct.target);
	return _target[$ __inline_execute(_struct.key)]--;
}
function __compileInLineUpdateStruct(_rootNode, _parentNode, _targetExpression, _keyExpression, _increment, _prefix) {
    var _output = {
		exeFunc: __executeInLineUpdateStruct,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _targetExpression,
		key: _keyExpression,
    }
    
	if (_increment  &&  _prefix) _output.exeFunc = __executeInLineUpdateStructPlusPlusPrefix;
	if (_increment  && !_prefix) _output.exeFunc = __executeInLineUpdateStructPlusPlusPostfix;
	if (!_increment &&  _prefix) _output.exeFunc = __executeInLineUpdateStructMinusMinusPrefix;
	if (!_increment && !_prefix) _output.exeFunc = __executeInLineUpdateStructMinusMinusPostfix;
	
	return _output;
}
#endregion
#region Struct w/ Errors
#region //{
//    target: <expression>,
//    key: <stringLiteral>,
//}
#endregion
function __executeInLineUpdateStructDotAccPlusPlusPrefix(_struct) {
    var _target = __inline_execute(_struct.target);
    if (!struct_exists(_target, _struct.key)) throw $"\nVariable <unknown_object>.{_struct.name} not set before reading it."
	return ++_target[$ _struct.key];
}
function __executeInLineUpdateStructDotAccPlusPlusPostfix(_struct) {
    var _target = __inline_execute(_struct.target);
    if (!struct_exists(_target, _struct.key)) throw $"\nVariable <unknown_object>.{_struct.name} not set before reading it."
	return _target[$ _struct.key]++;
}
function __executeInLineUpdateStructDotAccMinusMinusPrefix(_struct) {
    var _target = __inline_execute(_struct.target);
    if (!struct_exists(_target, _struct.key)) throw $"\nVariable <unknown_object>.{_struct.name} not set before reading it."
	return --_target[$ _struct.key];
}
function __executeInLineUpdateStructDotAccMinusMinusPostfix(_struct) {
    var _target = __inline_execute(_struct.target);
    if (!struct_exists(_target, _struct.key)) throw $"\nVariable <unknown_object>.{_struct.name} not set before reading it."
	return _target[$ _struct.key]--;
}
function __compileInLineUpdateStructDotAcc(_rootNode, _parentNode, _targetExpression, _keyExpression, _increment, _prefix) {
    var _output = {
		exeFunc: __compileInLineUpdateStructDotAcc,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		target: _targetExpression,
		key: _keyExpression,
    }
    
	if (_increment  &&  _prefix) _output.exeFunc = __executeInLineUpdateStructDotAccPlusPlusPrefix
	if (_increment  && !_prefix) _output.exeFunc = __executeInLineUpdateStructDotAccPlusPlusPostfix
	if (!_increment &&  _prefix) _output.exeFunc = __executeInLineUpdateStructDotAccMinusMinusPrefix
	if (!_increment && !_prefix) _output.exeFunc = __executeInLineUpdateStructDotAccMinusMinusPostfix
	
	return _output;
}
#endregion

#endregion

#endregion

#region //{
// used for natively compiled functions
//    func: <function>,
//    argArr: [],
//}
#endregion
function __executeInLineNativeFunction(_struct) {
	static __arr = []
	
	var _i=0; repeat(_struct.size) {
		__arr[_i] = __inline_execute(_struct.argArr[_i]);
	_i++}
	
	var _r = undefined;
    ///NOTE: find out which of these two are actually faster
    with (global.otherInstance) { with (global.selfInstance) {
		_r = script_execute_ext(__inline_execute(_struct.func), __arr);
    break; } break; }
    
	//reset array after to clear GC
	array_resize(__arr, 0);
	
	return _r;
	
    ///alternate version
    //var _func = func();
    //if (method_get_self(_func) != undefined) script_execute_ext(func(), argArr)
    
}
function __compileInLineNativeFunction(_rootNode, _parentNode, _func, _args=[]) {
    var _output = {
		exeFunc: __executeInLineNativeFunction,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		func: undefined,
		argArr: [],
		size: undefined,
    }
    _output.func = __compileInLineExpression(_rootNode, _parentNode, _func);
    var _i=0; repeat(array_length(_args)) {
		_output.argArr[_i] = __compileInLineExpression(_rootNode, _parentNode, _args[_i]);
    _i++}
    
    _output.size = array_length(_output.argArr)
    
    return _output
}

#region //{
// used for gmlc compiled functions
//    func: <function>,
//    argArr: [],
//    varStatic: {},
//    varLocal: {},
//}
#endregion
function __executeInLineGMLCFunction(_struct) {
    //update teh callstack
    var _func = __inline_execute(_struct.func)
    array_push(rootNode.callStack, _func);
    script_execute_ext(_func, argArr)
    //need to add check support for gmlc methods, as this would change the current self and other
}
function __compileInLineGMLCFunction(_rootNode, _parentNode, _func, _args=[]) {
    var _output = {
		exeFunc: __executeInLineGMLCFunction,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		func: undefined,
		argArr: [],
		size: undefined,
		varStatic: {},
		varLocal: {},
    }
    _output.func = __compileInLineExpression(_rootNode, _parentNode, _func);
    var _i=0; repeat(array_length(_args)) {
		_output.argArr[_i] = __compileInLineExpression(_rootNode, _parentNode, _args[_i]);
    _i++}
    
    _output.size = array_length(_output.argArr)
    
    return _output
}

#region //{
// used to build a new array
//    expressionsArray: array<expressions>
//    size: array_length(expressionsArray),
//}
#endregion
function __executeInLineNewArray(_struct) {
    var _arr = array_create(_struct.size);
    var _i=0; repeat(_struct.size) {
		_arr[_i] = __inline_execute(_struct.expressionsArray[_i]);
    _i++}
    return _arr;
}
function __compileInLineNewArray(_rootNode, _parentNode, _expressionsArray) {
    var _output = {
		exeFunc: __executeInLineNewArray,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		expressionsArray: [],
		size: undefined,
    }
    
    var _i=0; repeat(array_length(_expressionsArray)) {
		_output.expressionsArray[_i] = __compileInLineExpression(_rootNode, _parentNode, _expressionsArray[_i]);
    _i++}
    
    _output.size = array_length(_output.expressionsArray)
    
    return _output
}

#region //{
// used to build a new array
//    array: array<expressions>
//    size: array_length(expressionsArray) / 2,
//}
#endregion
function __executeInLineNewStruct(_input) {
    var _struct = {}
    var _i=0; repeat(_input.size/2) {
		var _key = _input.array[_i];
		var _value = _input.array[_i+1];
		struct_set(_struct, __inline_execute(_key), __inline_execute(_value))
    _i+=2}
    return _struct;
}
function __compileInLineNewStruct(_rootNode, _parentNode, _arr) {
    var _output = {
		exeFunc: __executeInLineNewStruct,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		array: [],
		size: undefined,
    }
    
    var _i=0; repeat(array_length(_arr)) {
		//should probably all be literal strings, but i dont care otherwise
		_output.array[_i] = __compileInLineExpression(_rootNode, _parentNode, _arr[_i])
    _i++}
    
    _output.size = array_length(_output.array)
    
    return _output
}

/// Expressions

/// NOTE: there are roughly 20 operators currently in gml, if we handled 1 op at a time
// we would have 20 unique functions, however if we generated this code 2 ops in a single
// function call would produce 400 functions, ^3 would produce 8,000, and ^4 would produce
// 160,000. All of which are possible, but would it really be worth it?

#region //{
// used to fetch Literal values
//    value: <any>,
//}
#endregion
function __executeInLineLiteralExpression(_struct) {
    return _struct.value;
}
function __compileInLineLiteralExpression(_rootNode, _parentNode, _value) {
    var _output = {
		exeFunc: __executeInLineLiteralExpression,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		value: _value,
    }
    
    return _output
}

function __compileInLineIdentifier(_rootNode, _parentNode, _scope, _name) {
	var _target = __getScopeTargetInLine(_scope, _rootNode, _parentNode)
	var _key = __compileInLineLiteralExpression(_rootNode, _parentNode, _name)
	
	return __compileInLineStructDotAccGet(_rootNode, _parentNode, _target, _key)
}

function __compileInLineUniqueIdentifier(_rootNode, _parentNode, _scope, _name) {
	var _key = _name
	return __compileInLineGetUnique(_rootNode, _parentNode, _key);
}


#region //{
// used to call functions
//    callee: <method, function, or program>,
//    argArr: array<expression>,
//}
#endregion
function __executeInLineCallExpression(_struct) {
	var _func = __inline_execute(_struct.callee)
	
	var _length = array_length(_struct.argArr);
	var _argArray = array_create(_length);
	
	var _i=0; repeat(_length) {
		_argArray[_i] = __inline_execute(_struct.argArr[_i]);
	_i++}
	
	//var _argArray = array_map(_struct.argArr, function(_elem, _index){
	//	return __inline_execute(_elem);
	//});
	
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
		
			var _return = method_call(_func, _argArray);
		
			global.otherInstance = _prevOther;
			global.selfInstance  = _prevSelf;
		}
	}
	else if (script_exists(_func)) {
		var _return = script_execute_ext(_func, _argArray);
	}
	else {
		var _return = __inline_execute(_func, _argArray)
	}
	
	return _return;
}
function __compileInLineCallExpression(_rootNode, _parentNode, _calleeNode, _argArr) {
    var _output = {
		exeFunc: __executeInLineCallExpression,
		errorMessage: "<Missing Error Message>",
		
		rootNode: _rootNode,
		parentNode: _parentNode,
		
		callee: __compileInLineExpression(_rootNode, _parentNode, _calleeNode),
		calleeName: _calleeNode.name,// this is actually unneeded, but we would still like to have it for debugging
		argArr: [],
		size: 0,
    }
	
	var _i=0; repeat(array_length(_argArr)) {
		_output.argArr[_i] = __compileInLineExpression(_rootNode, _parentNode, _argArr[_i])
		_output.size++;
	_i++}
    
    return _output
}


function __compileInLineVariableDeclaration(_rootNode, _parentNode, _scope, _key, _expr) {
	return __compileInLinePropertySet(_rootNode, _parentNode, _scope, __compileInLineLiteralExpression(_rootNode, _parentNode, _key), __compileInLineExpression(_rootNode, _parentNode, _expr));
}
function __compileInLineVariableDeclarationList(_rootNode, _parentNode, _node) {
	return __compileInLineBlockStatement(_rootNode, _parentNode, _node.statements)
}


function __inline_execute(_struct, _args=[]) {
	gml_pragma("forceinline")
	
	//log(json(__structMethodAST(_struct)))
	
	var _func = _struct.exeFunc;
	return _func(_struct, _args);
}