
//for debugging purposes I make use of strings,
// if you would like to make use of Enums instead
// please add an additional `/` to the first `/*`
// making this a `//*` will toggle this for you

#region NodeType
/*
	enum __GMLC_NodeType {
		EmptyNode,
		AccessorExpression,
		AssignmentExpression,
		Base,
		BinaryExpression,
		BlockStatement,
		BreakStatement,
		CallExpression,
		CaseDefault,
		CaseExpression,
		ConditionalExpression,
		ConstructorDeclaration,
		ContinueStatement,
		DoUntilStatement,
		ExitStatement,
		ExpressionStatement,
		ForStatement,
		FunctionDeclaration,
		ArgumentList,
		Argument,
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
		TryStatement,
		UnaryExpression,
		UpdateExpression,
		VariableDeclaration,
		VariableDeclarationList,
		WhileStatement,
		WithStatement,
		
		__SIZE__
	}
/*/
	function __GMLC_NodeType() {
		static EmptyNode = "__GMLC_NodeType.EmptyNode"
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
		static DoUntilStatement = "__GMLC_NodeType.DoUntilStatement"
		static ExitStatement = "__GMLC_NodeType.ExitStatement"
		static ExpressionStatement = "__GMLC_NodeType.ExpressionStatement"
		static ForStatement = "__GMLC_NodeType.ForStatement"
		static FunctionDeclaration = "__GMLC_NodeType.FunctionDeclaration"
		static ArgumentList = "__GMLC_NodeType.ArgumentList"
		static Argument = "__GMLC_NodeType.Argument"
		static Identifier = "__GMLC_NodeType.Identifier"
		static IfStatement = "__GMLC_NodeType.IfStatement"
		static Literal = "__GMLC_NodeType.Literal"
		static UniqueIdentifier = "__GMLC_NodeType.UniqueIdentifier"
		static LogicalExpression = "__GMLC_NodeType.LogicalExpression"
		static NewExpression = "__GMLC_NodeType.NewExpression"
		static NullishExpression = "__GMLC_NodeType.NullishExpression"
		static PostfixExpression = "__GMLC_NodeType.PostfixExpression"
		static RepeatStatement = "__GMLC_NodeType.RepeatStatement"
		static ReturnStatement = "__GMLC_NodeType.ReturnStatement"
		static Script = "__GMLC_NodeType.Script"
		static SwitchStatement = "__GMLC_NodeType.SwitchStatement"
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
#region ScopeType
// add or remove a slash here to toggle between enums and string lookups
/*
enum ScopeType {
	MACRO,
	GLOBAL,
	ENUM,
	UNIQUE,
	LOCAL,
	STATIC,
	SELF,
	OTHER,
	CONST,
		
	__SIZE__
}
enum OpCode {
	REMAINDER,    // The remainder `%` operator.
	MULTIPLY,    // The `*` operator.
	DIVIDE,    // The `/` operator.
	DIVIDE_INT,    // The integer division `//` operator.
	SUBTRACT,    // The `-` operator.
	PLUS,    // The `+` operator.
	EQUAL,    // The `==` operator.
	NOT_EQUAL,    // The `!=` operator.
	GREATER,    // The `>` operator.
	GREATER_EQUAL,    // The `>=` operator.
	LESS,    // The `<` operator.
	LESS_EQUAL,    // The `<=` operator.
	NOT,    // The logical negation `!` operator.
	BITWISE_NOT,    // The bitwise negation `~` operator.
	SHIFT_RIGHT,    // The bitwise right shift `>>` operator.
	SHIFT_LEFT,    // The bitwise left shift `<<` operator.
	BITWISE_AND,    // The bitwise AND `&` operator.
	BITWISE_XOR,    // The bitwise XOR `^` operator.
	BITWISE_OR,    // The bitwise OR `|` operator.
	OR,    // The logical OR operator.
	AND,    // The logical AND operator.
	XOR,    // The logical XOR operator.
	NEGATE,    // The negation prefix.
	INC,    // increment.
	DEC,    // decrement.
		
	__SIZE__
}
/*/
function ScopeType() {
	static MACRO = "ScopeType.MACRO";
	static GLOBAL = "ScopeType.GLOBAL";
	static ENUM = "ScopeType.ENUM";
	static UNIQUE = "ScopeType.UNIQUE";
	static LOCAL = "ScopeType.LOCAL";
	static STATIC = "ScopeType.STATIC";
	static SELF = "ScopeType.SELF";
	static OTHER = "ScopeType.OTHER";
	static CONST = "ScopeType.CONST";
		
	static __SIZE__ = "__SIZE__";
}
function OpCode() {
	static REMAINDER = "OpCode.REMAINDER";
	static MULTIPLY = "OpCode.MULTIPLY";
	static DIVIDE = "OpCode.DIVIDE";
	static DIVIDE_INT = "OpCode.DIVIDE_INT";
	static SUBTRACT = "OpCode.SUBTRACT";
	static PLUS = "OpCode.PLUS";
	static EQUAL = "OpCode.EQUAL";
	static NOT_EQUAL = "OpCode.NOT_EQUAL";
	static GREATER = "OpCode.GREATER";
	static GREATER_EQUAL = "OpCode.GREATER_EQUAL";
	static LESS = "OpCode.LESS";
	static LESS_EQUAL = "OpCode.LESS_EQUAL";
	static NOT = "OpCode.NOT";
	static BITWISE_NOT = "OpCode.BITWISE_NOT";
	static SHIFT_RIGHT = "OpCode.SHIFT_RIGHT";
	static SHIFT_LEFT = "OpCode.SHIFT_LEFT";
	static BITWISE_AND = "OpCode.BITWISE_AND";
	static BITWISE_XOR = "OpCode.BITWISE_XOR";
	static BITWISE_OR = "OpCode.BITWISE_OR";
	static OR = "OpCode.OR";
	static AND = "OpCode.AND";
	static XOR = "OpCode.XOR";
	static NEGATE = "OpCode.NEGATE";
	static INC = "OpCode.INC";
	static DEC = "OpCode.DEC";
	static NULLISH = "OpCode.NULLISH";
		
	static __SIZE__ = "__SIZE__";
}
ScopeType()
OpCode()
//*/
#endregion
#region TokenType
/*
enum __GMLC_TokenType {
	Whitespace,
	Identifier,
	Number,
	Operator,
	Keyword,
	Function,
	Punctuation,
	
	UniqueVariable,
	
	String,
	
	TemplateStringBegin,
	TemplateStringMiddle,
	TemplateStringEnd,
	
	EscapeOperator,
	
	Comment,
	
	Macro,
	Region,
	Enum,
	Define,
	
	NoOpPragma,
	
	Illegal,
	
	SIZE
}
/*/
//used for debugging
function __GMLC_TokenType() {
	static Whitespace = "__GMLC_TokenType.Whitespace";
	static Identifier = "__GMLC_TokenType.Identifier";
	static Number = "__GMLC_TokenType.Number";
	static Operator = "__GMLC_TokenType.Operator";
	static Keyword = "__GMLC_TokenType.Keyword";
	static Function = "__GMLC_TokenType.Function";
	static Punctuation = "__GMLC_TokenType.Punctuation";
	
	static UniqueVariable = "__GMLC_TokenType.UniqueVariable";
	
	static String = "__GMLC_TokenType.String";
	
	static TemplateStringBegin = "__GMLC_TokenType.TemplateStringBegin";
	static TemplateStringMiddle = "__GMLC_TokenType.TemplateStringMiddle";
	static TemplateStringEnd = "__GMLC_TokenType.TemplateStringEnd";
	
	static EscapeOperator = "__GMLC_TokenType.EscapeOperator";
	
	static Comment = "__GMLC_TokenType.Comment";
	
	static Macro = "__GMLC_TokenType.Macro";
	static Region = "__GMLC_TokenType.Region";
	static Enum = "__GMLC_TokenType.Enum";
	static Define = "__GMLC_TokenType.Define";
	
	static NoOpPragma = "__GMLC_TokenType.NoOpPragma";
	
	static Illegal = "__GMLC_TokenType.Illegal";
	
	static SIZE = "SIZE"
}
__GMLC_TokenType();
//*/
#endregion
