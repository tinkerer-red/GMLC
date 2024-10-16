
#region 3. AST Module
/*
Purpose: To define the structure of the nodes in the AST that the parser will use.
	
Structures:
	
General nodes like Expression, Statement, and FunctionDeclaration.
Each node type will have specific properties relevant to their type, like body, parameters, operator, etc.
*/
#endregion
function ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.Base;
	visited = false; //used by the post processor
	line = _line; //used for debugging
	lineString = _lineString; //used for debugging
	//creationCallstack = debug_get_callstack()
	
	static get_children = function() {
		var _arr = []
		var _keys = struct_get_names(self);
		var _i=0; repeat(array_length(_keys)) {
			var key = _keys[_i];
			var node = self[$ key];
			
			if (is_instanceof(node, ASTNode)) {
				array_push(_arr, node);
			}
			
			if (is_array(node)) {
				var _j=0; repeat(array_length(node)) {
					array_push(_arr, node[_j]);
				_j++}
			}
			
		_i+=1;}//end repeat loop
		
		return _arr;
	}
	static push_children_to_node_stack = function(_nodestack) {
		var parent = self;
		var _keys = struct_get_names(self);
		var _i=0; repeat(array_length(_keys)) {
			var key = _keys[_i];
			var node = self[$ key];
			
			if (is_instanceof(node, ASTNode)) {
				array_push(_nodestack, {node, parent, key, index: undefined});
			}
			
			if (is_array(node)) {
				var _j=0; repeat(array_length(node)) {
					if (is_instanceof(node[_j], ASTNode)) {
						array_push(_nodestack, {node: node[_j], parent, key, index: _j});
					}
				_j++}
			}
			
		_i+=1;}//end repeat loop
	}
}

#region Structural Nodes

function ASTBlockStatement(_statements, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.BlockStatement;
	statements = _statements
	
}


function ASTScript(_line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.Script;
	GlobalVar = {};
	
	// temporarily used during parser
	GlobalVarNames = [];
	MacroVar = {};
	MacroVarNames = [];
	EnumVar = {};
	EnumVarNames   = {}; //structure is {HEADER1: [TAIL1, TAIL2, TAIL3], HEADER2: [TAIL1, TAIL2, TAIL3]}
	LocalVarNames = [];
	//////////////////////////////////
	
	//use a blank argument array for consistancy sake
	arguments = new ASTArgumentList([], _line, _lineString)
	
	statements = new ASTBlockStatement([], _line, _lineString);
	
}

function ASTObject(_line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.Object;
	
	GlobalVar = {};
	
	// temporarily used during parser
	GlobalVarNames = [];
	MacroVar = {};
	MacroVarNames = [];
	EnumVar = {};
	EnumVarNames   = {}; //structure is {HEADER1: [TAIL1, TAIL2, TAIL3], HEADER2: [TAIL1, TAIL2, TAIL3]}
	LocalVarNames = [];
	//////////////////////////////////
	
	statements = [];
	
}

function ASTFunctionDeclaration(_name, _arguments, _local_var_names, _statements, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	GlobalVar = {};
	
	// temporarily used during parser
	GlobalVarNames = [];
	MacroVar = {};
	MacroVarNames = [];
	EnumVar = {};
	EnumVarNames   = {}; //structure is {HEADER1: [TAIL1, TAIL2, TAIL3], HEADER2: [TAIL1, TAIL2, TAIL3]}
	StaticVarArray = [];
	StaticVarNames = [];
	LocalVarNames = _local_var_names;
	//////////////////////////////////
	
	type = __GMLC_NodeType.FunctionDeclaration;
	name = _name;
	arguments = _arguments
	
	if (_statements != undefined) { //extremely common to create the function prior to parsing the body
		statements = is_instanceof(_statements, ASTBlockStatement) ? _statements : new ASTBlockStatement(_statements, _line, _lineString);
	}
	
}
function ASTConstructorDeclaration(_name, _parentName, _arguments, _parentCall, _local_var_names, _statements, _line, _lineString) : ASTNode(_line, _lineString) constructor {
    // temporarily used during parser
	GlobalVar = {};
	
	StaticVarArray = [];
	StaticVarNames = [];
	GlobalVarNames = [];
	MacroVar = {};
	MacroVarNames = [];
	EnumVar = {};
	EnumVarNames   = {}; //structure is {HEADER1: [TAIL1, TAIL2, TAIL3], HEADER2: [TAIL1, TAIL2, TAIL3]}
	LocalVarNames = _local_var_names;
	//////////////////////////////////
	
	type = __GMLC_NodeType.ConstructorDeclaration;
	name = _name;
	parentName = _parentName;
	arguments = _arguments;
	parentCall = _parentCall;
	
	statements = _statements; //will be set after body is parsed
}
function ASTArgumentList(_statements, _line, _lineString) : ASTBlockStatement(_statements, _line, _lineString) constructor {
	type = __GMLC_NodeType.ArgumentList;
	statements = _statements;
}
function ASTArgument(_identifier, _expr, _arg_index, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.Argument;
	identifier = _identifier;
	expr = _expr;
	argument_index = _arg_index
	scope = ScopeType.LOCAL;
}


//used for better modding support, not actually native gml
function ASTImportAs(_source, _structName, _line, _lineString) : ASTNode(_line, _lineString) constructor {
    type = __GMLC_NodeType.ImportDeclaration;
    structName = _structName;
    source = _source;
}
function ASTImport(_source, _line, _lineString) : ASTNode(_line, _lineString) constructor {
    type = __GMLC_NodeType.ImportDeclaration;
    source = _source;
}

#endregion

#region Statements
function ASTDoUntillStatement(_condition, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.DoUntillStatement;
	condition = _condition;
	codeBlock = _codeBlock;
}

function ASTForStatement(_initialization, _condition, _increment, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ForStatement;
	initialization = _initialization;
	condition = _condition;
	increment = _increment;
	codeBlock = _codeBlock;
}

function ASTIfStatement(_condition, _consequent, _alternate, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.IfStatement;
	condition = _condition;
	consequent = _consequent;
	alternate = _alternate;
}

function ASTRepeatStatement(_condition, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.RepeatStatement;
	condition = _condition;
	codeBlock = _codeBlock;
}

function ASTSwitchStatement(_switchExpression, _cases, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.SwitchStatement;
	switchExpression = _switchExpression;
	cases = _cases;
	
}
function ASTCaseDefault(_codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.CaseDefault;
	label = undefined;
	codeBlock = new ASTBlockStatement(_codeBlock, _line, _lineString);
}
function ASTCaseExpression(_label, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.CaseExpression;
	label = _label;
	codeBlock = new ASTBlockStatement(_codeBlock, _line, _lineString);
}

function ASTTryStatement(_tryBlock, _catchBlock, _exceptionVar, _finallyBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.TryStatement;
	tryBlock = _tryBlock;
	exceptionVar = _exceptionVar;
	catchBlock = _catchBlock;
	finallyBlock = _finallyBlock;
}

function ASTWhileStatement(_condition, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.WhileStatement;
	condition = _condition;
	codeBlock = _codeBlock;
}

function ASTWithStatement(_condition, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.WithStatement;
	condition = _condition;
	codeBlock = _codeBlock;
}
#endregion

#region Keyword Statements
function ASTBreakStatement(_line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.BreakStatement;
}

function ASTContinueStatement(_line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ContinueStatement;
	
}

function ASTExitStatement(_line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ExitStatement;
	
}

function ASTNewExpression(_expression, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.NewExpression;
	expression = _expression;
}

function ASTReturnStatement(_expr, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ReturnStatement;
	expr = _expr;
}

function ASTVariableDeclarationList(_statements, _scope, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.VariableDeclarationList;
	statements = new ASTBlockStatement(_statements, _line, _lineString);
	scope = _scope;
}
function ASTVariableDeclaration(_identifier, _expr, _scope, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.VariableDeclaration;
	identifier = _identifier;
	expr = _expr;
	scope = _scope;
}

function ASTMacroDeclaration(_identifier, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.VariableDeclaration;
	identifier = _identifier;
	codeBlock = _codeBlock;
	scope = ScopeType.MACRO;
}
function ASTMacroIdentifier(_identifier, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.VariableDeclaration;
	identifier = _identifier;
	scope = ScopeType.MACRO;
}

function ASTEnumDeclaration(_identifier, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.VariableDeclaration;
	identifier = _identifier;
	codeBlock = _codeBlock;
	scope = ScopeType.ENUM;
}
function ASTEnumIdentifier(_identifier, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.VariableDeclaration;
	identifier = _identifier;
	scope = ScopeType.ENUM;
}
#endregion

#region Expressions

function ASTCallExpression(_callee, _arguments, _line, _lineString) : ASTNode(_line, _lineString) constructor {
    type = __GMLC_NodeType.CallExpression;
    callee = _callee;
    arguments = _arguments;
	callstack = debug_get_callstack(3)
	
}

function ASTAccessorExpression(_expr, _val1, _val2, _accessorType, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.AccessorExpression;
	expr = _expr;
	val1 = _val1;
	val2 = _val2;
	accessorType = _accessorType;
	
}

function ASTTemplateString(_callee, _arguments, _line, _lineString) : ASTNode(_line, _lineString) constructor {
    type = __GMLC_NodeType.CallExpression;
    callee = _callee;
    arguments = _arguments;
	callstack = debug_get_callstack(3)
	
}

function ASTArrayPattern(_elements, _line, _lineString) : ASTNode(_line, _lineString) constructor {
    type = __GMLC_NodeType.ArrayPattern;
    elements = _elements;
	length = array_length(_elements);
	
}
function ASTStructPattern(_args, _line, _lineString) : ASTNode(_line, _lineString) constructor {
    type = __GMLC_NodeType.StructPattern;
	
	arguments = new ASTBlockStatement(_args, _line, _lineString)
	length = array_length(_args);
	
}

function ASTThrowExpression(_error, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ThrowExpression;
	error = _error;
}

#endregion

#region Math Expressions
function ASTAssignmentExpression(_operator, _left, _right, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.AssignmentExpression;
	operator = _operator;
	left = _left;
	right = _right;
	
}

function ASTBinaryExpression(_operator, _left, _right, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.BinaryExpression;
	operator = _operator;
	left = _left;
	right = _right;
}

function ASTLogicalExpression(_operator, _left, _right, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.LogicalExpression;
	operator = _operator;
	left = _left;
	right = _right;
}

function ASTNullishExpression(_operator, _left, _right, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.NullishExpression;
	operator = _operator;
	left = _left;
	right = _right;
}

function ASTUnaryExpression(_operator, _expr, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.UnaryExpression;
	operator = _operator;
	expr = _expr;
}

function ASTConditionalExpression(_condition, _trueExpr, _falseExpr, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ConditionalExpression;
	condition = _condition;
	trueExpr = _trueExpr;
	falseExpr = _falseExpr;
}

function ASTUpdateExpression(_operator, _expr, _prefix, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	//   thing++    thing--    ++thing    or    --thing
	type = __GMLC_NodeType.UpdateExpression;
    operator = _operator;
    expr = _expr;
    prefix = _prefix;
	
}
#endregion

#region Identifiers
function ASTFunction(_func, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.Function;
	value = _func;
	name = script_get_name(_func);
}
function ASTIdentifier(_value, _scope, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.Identifier;
	value = _value;
	name  = _value;
	scope = _scope;
}
function ASTLiteral(_value, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.Literal;
	value = _value;
	scope = ScopeType.CONST;
}
function ASTUniqueIdentifier(_value, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.UniqueIdentifier;
	value = _value;
	scope = ScopeType.UNIQUE;
}

#endregion


