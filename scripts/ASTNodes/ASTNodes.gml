#region NodeType
/*
	enum __GMLC_NodeType {
		Base,
		
		AccessorExpression,
		AssignmentExpression,
		BinaryExpression,
		BlockStatement,
		BreakStatement,
		CaseDefault,
		CaseExpression,
		ConditionalExpression,
		ContinueStatement,
		DoUntillStatement,
		ExitStatement,
		ExpressionStatement,
		ForStatement,
		Function,
		FunctionDeclaration,
		Identifier,
		IfStatement,
		Literal,
		UniqueIdentifier, 
		LogicalExpression,
		NewExpression,
		NullishExpression,
		PostfixExpression,
		RepeatStatement,
		ReturnStatement,
		Script,
		SwitchStatement,
		ThrowStatement,
		TryStatement,
		UnaryExpression,
		VariableDeclaration,
		VariableDeclarationList,
		WhileStatement,
		WithStatement,
		
		
		BlockStatement,
		DoUntillStatement,
		ForStatement,
		IfStatement,
		RepeatStatement,
		SwitchStatement,
		CaseDefault,
		CaseExpression,
		TryStatement,
		WhileStatement,
		WithStatement,
		BreakStatement,
		ContinueStatement,
		ExitStatement,
		NewExpression,
		ReturnStatement,
		ThrowStatement,
		VariableDeclarationList,
		VariableDeclaration,
		AssignmentExpression,
		BinaryExpression,
		LogicalExpression,
		NullishExpression,
		UnaryExpression,
		ConditionalExpression,
		UpdateExpression,
		Script,
		Object,
		FunctionDeclaration,
		ConstructorDeclaration,
		FunctionDeclaration,
		ImportDeclaration,
		ImportDeclaration,
		Function,
		CallExpression,
		Identifier,
		Literal,
		Identifier,
		ArrayPattern,
		StructPattern,
		Super,
		
		__SIZE__
	}
/*/
	function __GMLC_NodeType() {
		static ArrayPattern = "__GMLC_NodeType.ArrayPattern"
		static AccessorExpression = "__GMLC_NodeType.AccessorExpression"
		static AssignmentExpression = "__GMLC_NodeType.AssignmentExpression"
		static Base = "__GMLC_NodeType.Base"
		static BinaryExpression = "__GMLC_NodeType.BinaryExpression"
		static BlockStatement = "__GMLC_NodeType.BlockStatement"
		static BreakStatement = "__GMLC_NodeType.BreakStatement"
		static CallExpression = "__GMLC_NodeType.CallExpression"
		static CaseDefault = "__GMLC_NodeType.CaseDefault"
		static CaseExpression = "__GMLC_NodeType.CaseExpression"
		static ConditionalExpression = "__GMLC_NodeType.ConditionalExpression"
		static ConstructorDeclaration = "__GMLC_NodeType.ConstructorDeclaration"
		static ContinueStatement = "__GMLC_NodeType.ContinueStatement"
		static DoUntillStatement = "__GMLC_NodeType.DoUntillStatement"
		static ExitStatement = "__GMLC_NodeType.ExitStatement"
		static ExpressionStatement = "__GMLC_NodeType.ExpressionStatement"
		static ForStatement = "__GMLC_NodeType.ForStatement"
		static Function = "__GMLC_NodeType.Function"
		static FunctionDeclaration = "__GMLC_NodeType.FunctionDeclaration"
		static ArgumentList = "__GMLC_NodeType.ArgumentList"
		static Argument = "__GMLC_NodeType.Argument"
		static Identifier = "__GMLC_NodeType.Identifier"
		static IfStatement = "__GMLC_NodeType.IfStatement"
		static ImportDeclaration = "__GMLC_NodeType.ImportDeclaration"
		static Literal = "__GMLC_NodeType.Literal"
		static UniqueIdentifier = "__GMLC_NodeType.UniqueIdentifier"
		static LogicalExpression = "__GMLC_NodeType.LogicalExpression"
		static NewExpression = "__GMLC_NodeType.NewExpression"
		static NullishExpression = "__GMLC_NodeType.NullishExpression"
		static Object = "__GMLC_NodeType.Object"
		static PostfixExpression = "__GMLC_NodeType.PostfixExpression"
		static RepeatStatement = "__GMLC_NodeType.RepeatStatement"
		static ReturnStatement = "__GMLC_NodeType.ReturnStatement"
		static Script = "__GMLC_NodeType.Script"
		static StructPattern = "__GMLC_NodeType.StructPattern"
		static Super = "__GMLC_NodeType.Super"
		static SwitchStatement = "__GMLC_NodeType.SwitchStatement"
		static ThrowStatement = "__GMLC_NodeType.ThrowStatement"
		static TryStatement = "__GMLC_NodeType.TryStatement"
		static UnaryExpression = "__GMLC_NodeType.UnaryExpression"
		static UpdateExpression = "__GMLC_NodeType.UpdateExpression"
		static VariableDeclaration = "__GMLC_NodeType.VariableDeclaration"
		static VariableDeclarationList = "__GMLC_NodeType.VariableDeclarationList"
		static WhileStatement = "__GMLC_NodeType.WhileStatement"
		static WithStatement = "__GMLC_NodeType.WithStatement"
		
	}
	__GMLC_NodeType();
//*/
#endregion
#region AccessorType
/*
	enum __GMLC_AccessorType {
		Array,
		Grid,
		List,
		Map,
		Struct,
		Dot,
		
		__SIZE__
	}
/*/
	function __GMLC_AccessorType() {
		static Array = "__GMLC_AccessorType.Array";
		static Grid = "__GMLC_AccessorType.Grid";
		static List = "__GMLC_AccessorType.List";
		static Map = "__GMLC_AccessorType.Map";
		static Struct = "__GMLC_AccessorType.Struct";
		static Dot = "__GMLC_AccessorType.Dot";
	}
	__GMLC_AccessorType();
//*/
#endregion

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
		var _arr = [];
		var _keys = struct_get_names(self);
		var _i=0; repeat(array_length(_keys)) {
			var _key = _keys[_i];
			var _node = self[$ _key];
			
			if (is_instanceof(_node, ASTNode)) {
				array_push(_arr, _node)
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
		_i+=1;}//end repeat loop
	}
}

#region Structural Nodes

function ASTBlockStatement(_statements, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.BlockStatement;
	statements = _statements
	
	static get_children = function() {
		return statements;
	}
	static push_children_to_node_stack = function(_nodestack) {
		var parent = self;
		var _i=0; repeat(array_length(statements)) {
			var node = statements[_i];
			array_push(_nodestack, {node, parent, key: "statements", index: _i});
		_i+=1;}//end repeat loop
	}
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
	
	static push_children_to_node_stack = function(_nodestack) {
		var parent = self;
		var _i=0; repeat(array_length(statements)) {
			var node = statements[_i];
			array_push(_nodestack, {node, parent, key: "statements", index: _i});
		_i+=1;}//end repeat loop
	}
}

function ASTFunctionDeclaration(_name, _arguments, _local_var_names, _statements, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	StaticVar = {};
	GlobalVar = {};
	
	// temporarily used during parser
	GlobalVarNames = [];
	MacroVar = {};
	MacroVarNames = [];
	EnumVar = {};
	EnumVarNames   = {}; //structure is {HEADER1: [TAIL1, TAIL2, TAIL3], HEADER2: [TAIL1, TAIL2, TAIL3]}
	StaticVarNames = [];
	LocalVarNames = _local_var_names;
	//////////////////////////////////
	
	type = __GMLC_NodeType.FunctionDeclaration;
	name = _name;
	arguments = _arguments
	
	if (_statements != undefined) { //extremely common to create the function prior to parsing the body
		statements = is_instanceof(_statements, ASTBlockStatement) ? _statements : new ASTBlockStatement(_statements, _line, _lineString);
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
		_i+=1;}//end repeat loop
	}
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

function ASTConstructorDeclaration(_name, _parentName, _parameters, _local_var_names, _statements, _line, _lineString) : ASTNode(_line, _lineString) constructor {
    type = __GMLC_NodeType.ConstructorDeclaration;
    StaticVar = {};
	StaticVarNames = [];
	GlobalVar = {};
	
	// temporarily used during parser
	GlobalVarNames = [];
	MacroVar = {};
	MacroVarNames = [];
	EnumVar = {};
	EnumVarNames   = {}; //structure is {HEADER1: [TAIL1, TAIL2, TAIL3], HEADER2: [TAIL1, TAIL2, TAIL3]}
	LocalVarNames = _local_var_names;
	//////////////////////////////////
	
	type = __GMLC_NodeType.FunctionDeclaration;
	name = _name;
	parentName = _parentName;
	parameters = _parameters;
	
	statements = _statements; //will be set after body is parsed
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

function ASTNewExpression(_callee, _arg_block, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.NewExpression;
	callee = _callee;
	arg_block = _arg_block;
}

function ASTReturnStatement(_expr, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ReturnStatement;
	expr = _expr;
}

function ASTThrowStatement(_error, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ThrowStatement;
	error = _error;
}

function ASTVariableDeclarationList(_statements, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.VariableDeclarationList;
	statements = new ASTBlockStatement(_statements, _line, _lineString);
	
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

#region Math Expressions
function ASTAssignmentExpression(_operator, _left, _right, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.AssignmentExpression;
	operator = _operator;
	left = _left;
	right = _right;
	
	static push_children_to_node_stack = function(_nodestack) {
		var parent = self;
		
		array_push(_nodestack, {node: left, parent, key: "left", index: undefined})
		array_push(_nodestack, {node: right, parent, key: "right", index: undefined})
		
	}
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
	
	static push_children_to_node_stack = function(_nodestack) {
		//dont push any children onto the stack, these will be parsed on their own
	}
}
#endregion

#region Identifiers
function ASTFunction(_func, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.Function;
	value = _func;
	name = script_get_name(_func);
}
function ASTCallExpression(_callee, _arguments, _line, _lineString) : ASTNode(_line, _lineString) constructor {
    type = __GMLC_NodeType.CallExpression;
    callee = _callee;
    arguments = _arguments;
	
	static push_children_to_node_stack = function(_nodestack) {
		var parent = self;
		
		//push callee
		array_push(_nodestack, {node: callee, parent, key: "callee", index: undefined})
		
		//push arguments
		var _i=0; repeat(array_length(arguments)) {
			var node = arguments[_i];
			array_push(_nodestack, {node, parent, key: "arguments", index: _i});
		_i+=1;}//end repeat loop
	}
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


function ASTAccessorExpression(_expr, _val1, _val2, _accessorType, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.AccessorExpression;
	expr = _expr;
	val1 = _val1;
	val2 = _val2;
	accessorType = _accessorType;

	static push_children_to_node_stack = function(_nodestack) {
		var parent = self;
		
		array_push(_nodestack, {node: expr, parent, key: "expr", index: undefined})
		array_push(_nodestack, {node: val1, parent, key: "val1", index: undefined})
		
		if (val2 != undefined) array_push(_nodestack, {node: val2, parent, key: "val2", index: undefined})
		
	}
}

function ASTArrayPattern(_elements, _line, _lineString) : ASTNode(_line, _lineString) constructor {
    type = __GMLC_NodeType.ArrayPattern;
    elements = _elements;
	length = array_length(_elements);

	static push_children_to_node_stack = function(_nodestack) {
		var parent = self;
		var _i=0; repeat(array_length(elements)) {
			var node = elements[_i];
			array_push(_nodestack, {node, parent, key: "elements", index: _i});
		_i+=1;}//end repeat loop
	}
}
function ASTStructPattern(_keys, _exprs, _line, _lineString) : ASTNode(_line, _lineString) constructor {
    type = __GMLC_NodeType.StructPattern;
	
	var _arr = []
	var _i=0; repeat(array_length(_keys)) {
		var _key = _keys[_i];
		var _expr = _exprs[_i];
		array_push(_arr, _key, _expr);
	_i+=1;}//end repeat loop
	arguments = new ASTBlockStatement(_arr, _line, _lineString)
	length = array_length(_arr);
	
}

#endregion



// Super; Not sure if im going to officially support this yet
function ASTSuper(_line, _lineString) : ASTNode(_line, _lineString) constructor {
    type = __GMLC_NodeType.Super;
}


