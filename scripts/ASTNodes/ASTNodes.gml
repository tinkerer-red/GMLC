
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
	
	skipOptimization = false; // for use with `/// @NoOp` programs, typically used for internal testing.
	
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
				var _j=array_length(node)-1; repeat(array_length(node)) {
					if (is_instanceof(node[_j], ASTNode)) {
						array_push(_nodestack, {node: node[_j], parent: parent, key: key, index: _j});
					}
				_j--}
			}
			
		_i+=1;}//end repeat loop
	}
	
	static get_children = function(){ throw_gmlc_error($"{instanceof(self)}.get_children method does not exist and needs to manually be added to the constructor") }
}

#region Structural Nodes

function ASTEmpty(_line="<EmptyNode>", _lineString="<EmptyNode>") : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.EmptyNode;
	static get_children = function(){ return []; };
}

function ASTBlockStatement(_statements, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.BlockStatement;
	statements = _statements
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			var _i=0; repeat(array_length(statements)) {
				array_push(_arr, {node: statements[_i], parent: _parent, key: "statements", index: _i});
			_i++}
		}
		else {
			var _i=array_length(statements)-1; repeat(array_length(statements)) {
				array_push(_arr, {node: statements[_i], parent: _parent, key: "statements", index: _i});
			_i--}
		}
		
		return _arr;
	}
}


function ASTScript() : ASTNode(0, "") constructor {
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
	arguments = new ASTArgumentList([], 0, "")
	
	statements = new ASTBlockStatement([], 0, "");
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: arguments,  parent: _parent, key: "arguments",  index: undefined});
			array_push(_arr, {node: statements, parent: _parent, key: "statements", index: undefined});
		}
		else {
			array_push(_arr, {node: statements, parent: _parent, key: "statements", index: undefined});
			array_push(_arr, {node: arguments,  parent: _parent, key: "arguments",  index: undefined});
		}
		
		return _arr;
	}
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
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: arguments,  parent: _parent, key: "arguments",  index: undefined});
			array_push(_arr, {node: statements, parent: _parent, key: "statements", index: undefined});
		}
		else {
			array_push(_arr, {node: statements, parent: _parent, key: "statements", index: undefined});
			array_push(_arr, {node: arguments,  parent: _parent, key: "arguments",  index: undefined});
		}
		
		return _arr;
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
	
	statements = _statements;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: arguments,  parent: _parent, key: "arguments",  index: undefined});
			array_push(_arr, {node: parentCall,  parent: parentCall, key: "parentCall",  index: undefined});
			array_push(_arr, {node: statements, parent: _parent, key: "statements", index: undefined});
		}
		else {
			array_push(_arr, {node: statements, parent: _parent, key: "statements", index: undefined});
			array_push(_arr, {node: parentCall,  parent: _parent, key: "parentCall",  index: undefined});
			array_push(_arr, {node: arguments,  parent: _parent, key: "arguments",  index: undefined});
		}
		
		return _arr;
	}
}
function ASTArgumentList(_statements, _line, _lineString) : ASTBlockStatement(_statements, _line, _lineString) constructor {
	type = __GMLC_NodeType.ArgumentList;
	statements = _statements;
	
	
	//static get_children :: inheritade from block statement parent constructor
}
function ASTArgument(_identifier, _expr, _arg_index, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.Argument;
	identifier = _identifier;
	expr = _expr;
	argument_index = _arg_index
	scope = ScopeType.LOCAL;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		array_push(_arr, {node: expr, parent: _parent, key: "expr", index: undefined});
		
		return _arr;
	}
}


#endregion

#region Statements
function ASTDoUntilStatement(_condition, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.DoUntilStatement;
	condition = _condition;
	codeBlock = _codeBlock;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
			array_push(_arr, {node: condition, parent: _parent, key: "condition", index: undefined});
		}
		else {
			array_push(_arr, {node: condition, parent: _parent, key: "condition", index: undefined});
			array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
		}
		
		return _arr;
	}
}

function ASTForStatement(_initialization, _condition, _increment, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ForStatement;
	initialization = _initialization;
	condition = _condition;
	increment = _increment;
	codeBlock = _codeBlock;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: initialization, parent: _parent, key: "initialization", index: undefined});
			array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
			array_push(_arr, {node: increment, parent: _parent, key: "increment", index: undefined});
			array_push(_arr, {node: condition, parent: _parent, key: "condition", index: undefined});
		}
		else {
			array_push(_arr, {node: condition, parent: _parent, key: "condition", index: undefined});
			array_push(_arr, {node: increment, parent: _parent, key: "increment", index: undefined});
			array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
			array_push(_arr, {node: initialization, parent: _parent, key: "initialization", index: undefined});
		}
		
		return _arr;
	}
}

function ASTIfStatement(_condition, _consequent, _alternate, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.IfStatement;
	condition = _condition;
	consequent = _consequent;
	alternate = _alternate;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: condition, parent: _parent, key: "condition", index: undefined});
			array_push(_arr, {node: consequent, parent: _parent, key: "consequent", index: undefined});
			if (alternate != undefined) array_push(_arr, {node: alternate, parent: _parent, key: "alternate", index: undefined});
		}
		else {
			if (alternate != undefined) array_push(_arr, {node: alternate, parent: _parent, key: "alternate", index: undefined});
			array_push(_arr, {node: consequent, parent: _parent, key: "consequent", index: undefined});
			array_push(_arr, {node: condition, parent: _parent, key: "condition", index: undefined});
		}
		
		return _arr;
	}
}

function ASTRepeatStatement(_condition, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.RepeatStatement;
	condition = _condition;
	codeBlock = _codeBlock;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: condition, parent: _parent, key: "condition", index: undefined});
			array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
		}
		else {
			array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
			array_push(_arr, {node: condition, parent: _parent, key: "condition", index: undefined});
		}
		
		return _arr;
	}
}

function ASTSwitchStatement(_switchExpression, _cases, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.SwitchStatement;
	switchExpression = _switchExpression;
	cases = _cases;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: switchExpression, parent: _parent, key: "switchExpression", index: undefined});
			var _i=0; repeat(array_length(cases)) {
				array_push(_arr, {node: cases[_i], parent: _parent, key: "cases", index: _i});
			_i++}
			
		}
		else {
			var _i=array_length(cases)-1; repeat(array_length(statements)) {
				array_push(_arr, {node: cases[_i], parent: _parent, key: "cases", index: _i});
			_i--}
			array_push(_arr, {node: switchExpression, parent: _parent, key: "switchExpression", index: undefined});
		}
		
		return _arr;
	}
}
function ASTCaseDefault(_codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.CaseDefault;
	label = undefined;
	codeBlock = new ASTBlockStatement(_codeBlock, _line, _lineString);
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
		
		return _arr;
	}
}
function ASTCaseExpression(_label, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.CaseExpression;
	label = _label;
	codeBlock = new ASTBlockStatement(_codeBlock, _line, _lineString);
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: label, parent: _parent, key: "label", index: undefined});
			array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
		}
		else {
			array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
			array_push(_arr, {node: label, parent: _parent, key: "label", index: undefined});
		}
		
		
		return _arr;
	}
}

function ASTTryStatement(_tryBlock, _catchBlock, _exceptionVar, _finallyBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.TryStatement;
	tryBlock = _tryBlock;
	exceptionVar = _exceptionVar;
	catchBlock = _catchBlock;
	finallyBlock = _finallyBlock;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: tryBlock, parent: _parent, key: "tryBlock", index: undefined});
			if (catchBlock != undefined) array_push(_arr, {node: catchBlock, parent: _parent, key: "catchBlock", index: undefined});
			if (finallyBlock != undefined) array_push(_arr, {node: finallyBlock, parent: _parent, key: "finallyBlock", index: undefined});
		}
		else {
			if (finallyBlock != undefined) array_push(_arr, {node: finallyBlock, parent: _parent, key: "finallyBlock", index: undefined});
			if (catchBlock != undefined) array_push(_arr, {node: catchBlock, parent: _parent, key: "catchBlock", index: undefined});
			array_push(_arr, {node: tryBlock, parent: _parent, key: "tryBlock", index: undefined});
		}
		
		return _arr;
	}
}

function ASTWhileStatement(_condition, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.WhileStatement;
	condition = _condition;
	codeBlock = _codeBlock;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: condition, parent: _parent, key: "condition", index: undefined});
			array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
		}
		else {
			array_push(_arr, {node: finallyBlock, parent: _parent, key: "finallyBlock", index: undefined});
			array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
		}
		
		return _arr;
	}
}

function ASTWithStatement(_condition, _codeBlock, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.WithStatement;
	condition = _condition;
	codeBlock = _codeBlock;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: condition, parent: _parent, key: "condition", index: undefined});
			array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
		}
		else {
			array_push(_arr, {node: finallyBlock, parent: _parent, key: "finallyBlock", index: undefined});
			array_push(_arr, {node: codeBlock, parent: _parent, key: "codeBlock", index: undefined});
		}
		
		return _arr;
	}
}
#endregion

#region Keyword Statements
function ASTBreakStatement(_line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.BreakStatement;
	static get_children = function(){}
}

function ASTContinueStatement(_line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ContinueStatement;
	static get_children = function(){}
}

function ASTExitStatement(_line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ExitStatement;
	static get_children = function(){}
}

function ASTNewExpression(_expression, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.NewExpression;
	expression = _expression;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		array_push(_arr, {node: expression, parent: _parent, key: "expression", index: undefined});
		
		return _arr;
	}
}

function ASTReturnStatement(_expr, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ReturnStatement;
	expr = _expr;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (expr != undefined) {
			array_push(_arr, {node: expr, parent: _parent, key: "expr", index: undefined});
		}
		
		return _arr;
	}
}

function ASTVariableDeclarationList(_statements, _scope, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.VariableDeclarationList;
	statements = new ASTBlockStatement(_statements, _line, _lineString);
	scope = _scope;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		array_push(_arr, {node: statements, parent: _parent, key: "statements", index: undefined});
		
		return _arr;
	}
}
function ASTVariableDeclaration(_identifier, _expr, _scope, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.VariableDeclaration;
	identifier = _identifier;
	expr = _expr;
	scope = _scope;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		array_push(_arr, {node: expr, parent: _parent, key: "expr", index: undefined});
		
		return _arr;
	}
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
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: callee, parent: _parent, key: "callee", index: undefined});
			var _i=0; repeat(array_length(arguments)) {
				array_push(_arr, {node: arguments[_i], parent: _parent, key: "arguments", index: _i});
			_i++}
		}
		else {
			var _i=array_length(arguments)-1; repeat(array_length(arguments)) {
				array_push(_arr, {node: arguments[_i], parent: _parent, key: "arguments", index: _i});
			_i--}
			array_push(_arr, {node: callee, parent: _parent, key: "callee", index: undefined});
		}
		
		return _arr;
	}
}

function ASTAccessorExpression(_expr, _val1, _val2, _accessorType, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.AccessorExpression;
	expr = _expr;
	val1 = _val1;
	val2 = _val2;
	accessorType = _accessorType;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: expr, parent: _parent, key: "expr", index: undefined});
			array_push(_arr, {node: val1, parent: _parent, key: "val1", index: undefined});
			if (val2 != undefined) array_push(_arr, {node: val2, parent: _parent, key: "val2", index: undefined});
		}
		else {
			if (val2 != undefined) array_push(_arr, {node: val2, parent: _parent, key: "val2", index: undefined});
			array_push(_arr, {node: val1, parent: _parent, key: "val1", index: undefined});
			array_push(_arr, {node: expr, parent: _parent, key: "expr", index: undefined});
		}
		
		return _arr;
	}
}

#endregion

#region Math Expressions
function ASTAssignmentExpression(_operator, _left, _right, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.AssignmentExpression;
	operator = _operator;
	left = _left;
	right = _right;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: left, parent: _parent, key: "left", index: undefined});
			array_push(_arr, {node: right, parent: _parent, key: "right", index: undefined});
		}
		else {
			array_push(_arr, {node: right, parent: _parent, key: "right", index: undefined});
			array_push(_arr, {node: left, parent: _parent, key: "left", index: undefined});
		}
		
		return _arr;
	}
}

function ASTBinaryExpression(_operator, _left, _right, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.BinaryExpression;
	operator = _operator;
	left = _left;
	right = _right;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: left, parent: _parent, key: "left", index: undefined});
			array_push(_arr, {node: right, parent: _parent, key: "right", index: undefined});
		}
		else {
			array_push(_arr, {node: right, parent: _parent, key: "right", index: undefined});
			array_push(_arr, {node: left, parent: _parent, key: "left", index: undefined});
		}
		
		return _arr;
	}
}

function ASTLogicalExpression(_operator, _left, _right, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.LogicalExpression;
	operator = _operator;
	left = _left;
	right = _right;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: left, parent: _parent, key: "left", index: undefined});
			array_push(_arr, {node: right, parent: _parent, key: "right", index: undefined});
		}
		else {
			array_push(_arr, {node: right, parent: _parent, key: "right", index: undefined});
			array_push(_arr, {node: left, parent: _parent, key: "left", index: undefined});
		}
		
		return _arr;
	}
}

function ASTNullishExpression(_operator, _left, _right, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.NullishExpression;
	operator = _operator;
	left = _left;
	right = _right;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: left, parent: _parent, key: "left", index: undefined});
			array_push(_arr, {node: right, parent: _parent, key: "right", index: undefined});
		}
		else {
			array_push(_arr, {node: right, parent: _parent, key: "right", index: undefined});
			array_push(_arr, {node: left, parent: _parent, key: "left", index: undefined});
		}
		
		return _arr;
	}
}

function ASTUnaryExpression(_operator, _expr, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.UnaryExpression;
	operator = _operator;
	expr = _expr;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		array_push(_arr, {node: expr, parent: _parent, key: "expr", index: undefined});
		
		return _arr;
	}
}

function ASTConditionalExpression(_condition, _trueExpr, _falseExpr, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.ConditionalExpression;
	condition = _condition;
	trueExpr = _trueExpr;
	falseExpr = _falseExpr;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		if (_top_down) {
			array_push(_arr, {node: condition, parent: _parent, key: "condition", index: undefined});
			array_push(_arr, {node: trueExpr, parent: _parent, key: "trueExpr", index: undefined});
			array_push(_arr, {node: falseExpr, parent: _parent, key: "falseExpr", index: undefined});
		}
		else {
			array_push(_arr, {node: falseExpr, parent: _parent, key: "falseExpr", index: undefined});
			array_push(_arr, {node: trueExpr, parent: _parent, key: "trueExpr", index: undefined});
			array_push(_arr, {node: condition, parent: _parent, key: "condition", index: undefined});
		}
		
		return _arr;
	}
}

function ASTUpdateExpression(_operator, _expr, _prefix, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	//   thing++    thing--    ++thing    or    --thing
	type = __GMLC_NodeType.UpdateExpression;
    operator = _operator;
    expr = _expr;
    prefix = _prefix;
	
	static get_children = function(_top_down) {
		var _arr = [];
		var _parent = self;
		
		array_push(_arr, {node: expr, parent: _parent, key: "expr", index: undefined});
		
		return _arr;
	}
}
#endregion

#region Identifiers
function ASTIdentifier(_value, _scope, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.Identifier;
	value = _value;
	hash = variable_get_hash(_value);
	name  = _value;
	scope = _scope;
	
	static get_children = function(_top_down) {}
}
function ASTLiteral(_value, _line, _lineString, _name=undefined) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.Literal;
	value = _value;
	scope = ScopeType.CONST;
	name = _name
	
	static get_children = function(_top_down) {}
}
function ASTUniqueIdentifier(_value, _line, _lineString) : ASTNode(_line, _lineString) constructor {
	type = __GMLC_NodeType.UniqueIdentifier;
	value = _value;
	scope = ScopeType.UNIQUE;
	
	static get_children = function(_top_down) {}
}

#endregion


