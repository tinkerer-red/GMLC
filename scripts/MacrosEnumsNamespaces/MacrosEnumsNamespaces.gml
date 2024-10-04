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
		ThrowExpression,
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
		ThrowExpression,
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
		static SwitchStatement = "__GMLC_NodeType.SwitchStatement"
		static ThrowExpression = "__GMLC_NodeType.ThrowExpression"
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
#region ByteOp Enum
// add or remove a slash here to toggle between enums and string lookups
/*
enum ByteOp {
	OPERATOR, //any mathmatical or logical operation
	CALL, // function call
	INC, // Increment
	DEC, // Decrement
	JUMP, // Jump
	JUMP_IF_TRUE, // Jump if true
	JUMP_IF_FALSE, // Jump if false
	RETURN, // Return a value
	DUP, // Duplicate the top of the stack
	POP, // Pop the top of the stack
		
		
	// Loading from a variable location
	LOAD,
	STORE,
		
	// try-catch-finally specific ops
	TRY_START,
	TRY_END,
	CATCH_START,
	CATCH_END,
	FINALLY_START,
	FINALLY_END,
		
	END, // end of file OR Exit statement
		
	__SIZE__,
}
enum ScopeType {
	GLOBAL,
	LOCAL,
	STATIC,
	INSTANCE,
	CONST,
	UNIQUE,
		
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
function ByteOp() {
	static OPERATOR = "ByteOp.OPERATOR";
	static CALL = "ByteOp.CALL";
	static INC = "ByteOp.INC";
	static DEC = "ByteOp.DEC";
	static JUMP = "ByteOp.JUMP";
	static JUMP_IF_TRUE = "ByteOp.JUMP_IF_TRUE";
	static JUMP_IF_FALSE = "ByteOp.JUMP_IF_FALSE";
	static RETURN = "ByteOp.RETURN";
	static DUP = "ByteOp.DUP";
	static POP = "ByteOp.POP";
		
	static JUMP_EXPECT = "ByteOp.JUMP_EXPECT"
		
			// Loading from a variable location
	static LOAD = "ByteOp.LOAD";
	static STORE = "ByteOp.STORE";
		
			// try-catch-finally specific ops
	static TRY_START = "ByteOp.TRY_START";
	static TRY_END = "ByteOp.TRY_END";
	static CATCH_START = "ByteOp.CATCH_START";
	static CATCH_END = "ByteOp.CATCH_END";
	static FINALLY_START = "ByteOp.FINALLY_START";
	static FINALLY_END = "ByteOp.FINALLY_END";
		
	static WITH_START = "ByteOp.WITH_START";
	static WITH_END =   "ByteOp.WITH_END";
		
	static END = "ByteOp.END";
		
	static THROW = "ByteOp.THROW";
		
	static __SIZE__ = "__SIZE__";
}
function ScopeType() {
	static MACRO = "ScopeType.MACRO";
	static GLOBAL = "ScopeType.GLOBAL";
	static ENUM = "ScopeType.ENUM";
	static UNIQUE = "ScopeType.UNIQUE";
	static LOCAL = "ScopeType.LOCAL";
	static STATIC = "ScopeType.STATIC";
	static INSTANCE = "ScopeType.INSTANCE";
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
ByteOp()
ScopeType()
OpCode()
//*/
#endregion
#region Token Enum
enum tok {
	eAnd, // &&
	eArrayClose, // ]
	eArrayOpen, // [
	eAssign, // =
	eAssignMinus, // -=
	eAssignOr, // |=
	eAssignPlus, // +=
	eBegin, // {
	eBinary, // 
	eBitAnd, // &
	eBitNegate, // ~
	eBitOr, // |
	eBitShiftLeft, // <<
	eBitXor, // ^
	eBlock, // used to declare a block statement, an array of statements
	eBreak, // break keyword
	eCase, // case keyword
	eCatch, // catch keyword
	eClose, // )
	eConditional, // ?
	eConstant, // any constant variable
	eContinue, // continue keyword
	eDefault, // default keyword
	eDiv, // div keyword
	eDivide, // /
	eDot, // .
	eEOF, // marks the end of a file
	eElse, // else keyword
	eEnd, // }
	eEnum, // enum keyword
	eEqual, // =
	eFinally, // finally keyword
	eFor, // for keyworf
	eFunction, // function; as in just a function its self
	eFunctionDecl, // `function` keyword
	eGreater, // >
	eGreaterEqual, // >=
	eGridArrayOpen, // [#
	eIf, // if keyword
	eLabel, // :
	eLess, // <
	eLessEqual, // <=
	eMinus, // -
	eMod, // % or mod
	eName, // any unidentified text thus far
	eNew, // new keyword
	eNot, // !
	eNotEqual, // !=
	eNullCoalesce, // ??
	eNullCoalesceAssign, // ??=
	eNumber, // any number declaration `1` `$FF` `0xFF` `0b1111`
	eOpen, // (
	eOr, // ||
	ePlus, // +
	ePlusPlus, // ++
	ePost, // ++ (also) but used for the second pass
	eRepeat, // repeat keyword
	eReturn, // return keyword
	eSepArgument, // ,
	eSepStatement, // ;
	eStatic, // static keyword
	eString, // any string literal @"example", @example, "example"
	eStructArrayOpen, // [$
	eSwitch, // switch keyword
	eTemplateString, // the mark of a template string
	eThrow, // throw keyword
	eTime, // *
	eTry, // try keyword
	eUnary, // ~ ! - +, this is only applied on second pass when building the ast
	eVar, // var keyword
	eVariable, // 
	eVariableSimple, // 
	eWhile, // while keyword
	eWith, // with keyword
	eXor, // ^^
}
//enum __GMLC_TokenType {
//	Whitespace,
//	Identifier,
//	Number,
//	Operator,
//	Keyword,
//	Function,
//	Punctuation,
//
//	UniqueVariable, //things like `argument`, `argument0`, `current_day`, etc.
//	
//	String,
//	TemplateString,
//	
//	EscapeOperator,
//	
//	Comment,
//	
//	Macro,
//	Region,
//	Enum,
//	
//	Illegal,
//	SIZE
//}

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
	
	static Illegal = "__GMLC_TokenType.Illegal";
	
	static SIZE = "SIZE"
}
__GMLC_TokenType();

#endregion
