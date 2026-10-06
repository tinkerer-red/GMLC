
#region AST Module
// The nodes of the syntax tree, one constructor per node kind. Each constructor holds the fields of its kind under the
// names the JSON form uses, plus `span` (where the node is in the source) and `origin` (the macro or enum use it came
// from, or undefined). The statics of each constructor say what it is: `kind` (its number), `kindName` (its name in
// the JSON form), `fields` (its fields in order) and `childFields` (the fields that hold child nodes, in the order
// `children()` returns them).
// Every stage reads and writes these nodes, and a tree read from JSON is made of the same constructors.
#endregion

#region Source positions
#region jsDoc
/// @func    GMLC_Span(_file, _start, _end)
/// @desc    A range of a source file: the file's number and the byte offsets of the first byte and of the byte after the
///          last.
/// @param   {Real} _file  : Number of the file in the compile's source table
/// @param   {Real} _start : First byte
/// @param   {Real} _end   : Byte after the last
/// @returns {Struct.GMLC_Span}
#endregion
function GMLC_Span(_file, _start, _end) constructor {
	file = _file;
	start = _start;
	self[$ "end"] = _end; // `end` is a keyword outside of `[$ ]` and `.`
}

#region jsDoc
/// @func    GMLC_SourceFile(_id, _name, _source, [_lineStarts], [_project])
/// @desc    One file of a compile: its number, name, project and text, so that a span can be turned into a line, a
///          column and the text of the line when an error needs them.
/// @param   {Real}        _id           : Number of the file in the source table
/// @param   {String}      _name         : Name of the file
/// @param   {String}      _source       : The file's text, line breaks normalised to LF
/// @param   {Array<Real>} [_lineStarts] : Byte offset of the start of every line, found from the text when undefined
/// @param   {String}      [_project]    : Name of the project the file belongs to, undefined when there is none
/// @returns {Struct.GMLC_SourceFile}
#endregion
function GMLC_SourceFile(_id, _name, _source, _lineStarts = undefined, _project = undefined) constructor {
	fileId = _id; // written as `id`; `id` is a built-in variable
	name = _name;
	project = _project;
	source = _source;
	lineStarts = _lineStarts ?? __GMLC_lineStarts(_source);
	__lineTexts = []; // text of each line, made on first use
	
	#region jsDoc
	/// @func    lineOf(_offset)
	/// @desc    The 1-based line of a byte offset.
	/// @self    GMLC_SourceFile
	/// @param   {Real} _offset : Byte offset
	/// @returns {Real}
	#endregion
	static lineOf = function(_offset) {
		var _lo = 0;
		var _hi = array_length(lineStarts) - 1;
		while (_lo < _hi) {
			var _mid = (_lo + _hi + 1) >> 1;
			if (lineStarts[_mid] <= _offset) {
				_lo = _mid;
			}
			else {
				_hi = _mid - 1;
			}
		}
		return _lo + 1;
	};
	
	#region jsDoc
	/// @func    lineText(_line)
	/// @desc    The text of a 1-based line without its line break, "" past the end.
	/// @self    GMLC_SourceFile
	/// @param   {Real} _line : Line
	/// @returns {String}
	#endregion
	static lineText = function(_line) {
		var _count = array_length(lineStarts);
		if (_line < 1) || (_line > _count) return "";
		var _text = (_line <= array_length(__lineTexts)) ? __lineTexts[_line - 1] : undefined;
		if (_text == undefined) {
			var _start = lineStarts[_line - 1];
			var _end = (_line < _count) ? lineStarts[_line] - 1 : byteLength();
			_text = __GMLC_byteCopy(source, _start, _end);
			__lineTexts[_line - 1] = _text;
		}
		return _text;
	};
	
	#region jsDoc
	/// @func    columnOf(_offset)
	/// @desc    The 1-based column of a byte offset, counted in characters.
	/// @self    GMLC_SourceFile
	/// @param   {Real} _offset : Byte offset
	/// @returns {Real}
	#endregion
	static columnOf = function(_offset) {
		var _start = lineStarts[lineOf(_offset) - 1];
		return string_length(__GMLC_byteCopy(source, _start, _offset)) + 1;
	};
	
	#region jsDoc
	/// @func    position(_offset)
	/// @desc    Where a byte offset is: file name, line, column and the text of the line.
	/// @self    GMLC_SourceFile
	/// @param   {Real} _offset : Byte offset
	/// @returns {Struct} {fileName, line, column, lineString}
	#endregion
	static position = function(_offset) {
		var _line = lineOf(_offset);
		return {
			fileName: name,
			line: _line,
			column: columnOf(_offset),
			lineString: lineText(_line),
		};
	};
	
	#region jsDoc
	/// @func    byteLength()
	/// @desc    The length of the file in bytes.
	/// @self    GMLC_SourceFile
	/// @returns {Real}
	#endregion
	static byteLength = function() {
		return string_byte_length(source);
	};
	
	#region jsDoc
	/// @func    text(_start, _end)
	/// @desc    The source text between two byte offsets.
	/// @self    GMLC_SourceFile
	/// @param   {Real} _start : First byte
	/// @param   {Real} _end   : Byte after the last
	/// @returns {String}
	#endregion
	static text = function(_start, _end) {
		return __GMLC_byteCopy(source, _start, _end);
	};
}

#region jsDoc
/// @func    GMLC_SourceTable()
/// @desc    The files of one compile, by number. Spans name their file by its number here.
/// @returns {Struct.GMLC_SourceTable}
#endregion
function GMLC_SourceTable() constructor {
	files = [];
	
	#region jsDoc
	/// @func    add(_file)
	/// @desc    Adds a file under its number.
	/// @self    GMLC_SourceTable
	/// @param   {Struct.GMLC_SourceFile} _file : The file
	/// @returns {Struct.GMLC_SourceFile}
	#endregion
	static add = function(_file) {
		// numbers past the end leave empty places, never the 0 GameMaker fills them with
		while (array_length(files) < _file.fileId) array_push(files, undefined);
		files[_file.fileId] = _file;
		return _file;
	};
	
	#region jsDoc
	/// @func    position(_span)
	/// @desc    Where a span (or anything with `file` and `start`, such as a token) starts: file name, line, column and
	///          the text of the line. Unknown files give an empty position.
	/// @self    GMLC_SourceTable
	/// @param   {Struct} _span : A span
	/// @returns {Struct} {fileName, line, column, lineString}
	#endregion
	static position = function(_span) {
		var _file = (_span != undefined) && (_span.file < array_length(files)) ? files[_span.file] : undefined;
		if (_file == undefined) return { fileName: "", line: 0, column: 0, lineString: "" };
		return _file.position(_span.start);
	};
}

#region jsDoc
/// @func    __GMLC_lineStarts(_source)
/// @desc    The byte offset of the start of every line of a text whose line breaks are LF.
/// @param   {String} _source : The text
/// @returns {Array<Real>}
#endregion
function __GMLC_lineStarts(_source) {
	var _starts = [0];
	var _length = string_byte_length(_source);
	var _buffer = buffer_create(_length + 1, buffer_fixed, 1);
	buffer_write(_buffer, buffer_text, _source);
	var _i = 0; repeat (_length) {
		if (buffer_peek(_buffer, _i, buffer_u8) == 10) array_push(_starts, _i + 1);
	_i++}
	buffer_delete(_buffer);
	return _starts;
}

#region jsDoc
/// @func    __GMLC_byteCopy(_text, _from, _to)
/// @desc    The part of a string between two byte offsets.
/// @param   {String} _text : The string
/// @param   {Real}   _from : First byte
/// @param   {Real}   _to   : Byte after the last
/// @returns {String}
#endregion
function __GMLC_byteCopy(_text, _from, _to) {
	if (_to <= _from) return "";
	static __buffer = buffer_create(256, buffer_grow, 1);
	buffer_seek(__buffer, buffer_seek_start, 0);
	buffer_write(__buffer, buffer_text, _text);
	buffer_write(__buffer, buffer_u8, 0);
	buffer_poke(__buffer, _to, buffer_u8, 0);
	buffer_seek(__buffer, buffer_seek_start, _from);
	return buffer_read(__buffer, buffer_string);
}
#endregion

#region Records
#region jsDoc
/// @func    GMLC_Symbol(_kind, _name, [_slot])
/// @desc    What a name means, written on an Identifier by the resolver: its kind ("Global", "BuiltinFunction",
///          "BuiltinConstant", "BuiltinVar", "Enum", "Local", "Static", "Self", ...), the name, and the local slot.
/// @param   {String} _kind : Symbol kind
/// @param   {String} _name : The name
/// @param   {Real}   [_slot] : Slot of a local, undefined otherwise
/// @returns {Struct.GMLC_Symbol}
#endregion
function GMLC_Symbol(_kind, _name, _slot = undefined) constructor {
	kind = _kind;
	name = _name;
	slot = _slot;
}

#region jsDoc
/// @func    GMLC_Origin(_kind, _name, _member, _config, _defSpan, _useSpan)
/// @desc    Where the tokens of a node came from when a macro use or an enum reference made them: the kind ("macro",
///          "enum" or "compile_time"), the macro or enum name, the enum member, the macro's configuration, the span of
///          the definition and the span of the use.
/// @returns {Struct.GMLC_Origin}
#endregion
function GMLC_Origin(_kind, _name, _member, _config, _defSpan, _useSpan) constructor {
	kind = _kind;
	name = _name;
	member = _member;
	config = _config;
	def_span = _defSpan;
	use_span = _useSpan;
}

#region jsDoc
/// @func    GMLC_Region(_span, _isEnd, _title)
/// @desc    A `#region` or `#endregion` line of a file: where it is, which of the two it is, and its title.
/// @param   {Struct.GMLC_Span} _span  : The line
/// @param   {Bool}             _isEnd : Whether it is `#endregion`
/// @param   {String}           _title : The text after the directive
/// @returns {Struct.GMLC_Region}
#endregion
function GMLC_Region(_span, _isEnd, _title) constructor {
	span = _span;
	is_end = _isEnd;
	title = _title;
}

#region jsDoc
/// @func    GMLC_Pragma(_pragma, _span, _target)
/// @desc    A pragma comment of a file (`// @NoOp`): its name, where it is, and the span of the statement it applies
///          to (the first one after it), undefined when none follows.
/// @param   {String}           _pragma : The pragma's name
/// @param   {Struct.GMLC_Span} _span   : The comment
/// @param   {Struct.GMLC_Span} _target : The statement it applies to
/// @returns {Struct.GMLC_Pragma}
#endregion
function GMLC_Pragma(_pragma, _span, _target) constructor {
	pragma = _pragma;
	span = _span;
	target = _target;
}

#region jsDoc
/// @func    GMLC_FunctionInfo(_fnId, _name, _locals)
/// @desc    What the resolver found about one function, kept in the file's `functions` by fn_id (0 is the file's body):
///          its number, its name and its locals in slot order (parameters first).
/// @param   {Real}          _fnId   : The function's fn_id
/// @param   {String}        _name   : Its name, undefined for the file's body
/// @param   {Array<String>} _locals : The names of its locals, by slot
/// @returns {Struct.GMLC_FunctionInfo}
#endregion
function GMLC_FunctionInfo(_fnId, _name, _locals) constructor {
	fn_id = _fnId;
	name = _name;
	locals = _locals;
}
#endregion

#region Node base
#region jsDoc
/// @func    ASTNode(_span, [_origin])
/// @desc    What every node has: a span and an origin. The kind's constructor adds its own fields.
/// @param   {Struct} _span     : Where the node is in the source
/// @param   {Struct} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTNode}
#endregion
function ASTNode(_span = undefined, _origin = undefined) constructor {
	static kind = undefined;
	static kindName = "";
	static fields = [];
	static childFields = [];
	
	span = _span;
	origin = _origin;
	
	#region jsDoc
	/// @func    children()
	/// @desc    The child nodes, in the order of the kind's `childFields`; arrays are flattened and empty fields left
	///          out.
	/// @self    ASTNode
	/// @returns {Array<Struct.ASTNode>}
	#endregion
	static children = function() {
		var _out = [];
		var _fields = childFields;
		var _i = 0; repeat (array_length(_fields)) {
			var _value = self[$ _fields[_i]];
			if (is_array(_value)) {
				var _j = 0; repeat (array_length(_value)) {
					if (_value[_j] != undefined) array_push(_out, _value[_j]);
				_j++}
			}
			else if (_value != undefined) {
				array_push(_out, _value);
			}
		_i++}
		return _out;
	};
	
	#region jsDoc
	/// @func    childSlots()
	/// @desc    The child nodes with where each one is held, so a stage can put another node in its place:
	///          {node, parent, key, index}, index undefined for a field that holds one node.
	/// @self    ASTNode
	/// @returns {Array<Struct>}
	#endregion
	static childSlots = function() {
		var _out = [];
		var _fields = childFields;
		var _i = 0; repeat (array_length(_fields)) {
			var _key = _fields[_i];
			var _value = self[$ _key];
			if (is_array(_value)) {
				var _j = 0; repeat (array_length(_value)) {
					if (_value[_j] != undefined) array_push(_out, { node: _value[_j], parent: self, key: _key, index: _j });
				_j++}
			}
			else if (_value != undefined) {
				array_push(_out, { node: _value, parent: self, key: _key, index: undefined });
			}
		_i++}
		return _out;
	};
}
#endregion

#region Root and declarations
function ASTScript(_span = undefined, _body = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Script;
	static kindName = "Script";
	static fields = ["body", "macros", "enums", "regions", "pragmas", "functions"];
	static childFields = ["body"];
	body = _body;
	macros = [];
	enums = [];
	regions = [];
	pragmas = [];
	functions = [];
}
function ASTBlock(_span = undefined, _body = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Block;
	static kindName = "Block";
	static fields = ["body"];
	static childFields = ["body"];
	body = _body;
}
function ASTFunctionDecl(_span = undefined, _name = undefined, _params = [], _body = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_FunctionDecl;
	static kindName = "FunctionDecl";
	static fields = ["name", "fn_id", "params", "body"];
	static childFields = ["params", "body"];
	name = _name;
	fn_id = undefined;
	params = _params;
	body = _body;
}
function ASTConstructorDecl(_span = undefined, _name = undefined, _params = [], _parent = undefined, _body = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_ConstructorDecl;
	static kindName = "ConstructorDecl";
	static fields = ["name", "fn_id", "params", "parent", "body"];
	static childFields = ["params", "parent", "body"];
	name = _name;
	fn_id = undefined;
	params = _params;
	parent = _parent;
	body = _body;
}
function ASTParam(_span = undefined, _target = undefined, _default = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Param;
	static kindName = "Param";
	static fields = ["target", "default"];
	static childFields = ["target", "default"];
	target = _target;
	self[$ "default"] = _default; // `default` is a keyword outside of `[$ ]` and `.`
}
function ASTStaticDecl(_span = undefined, _declarations = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_StaticDecl;
	static kindName = "StaticDecl";
	static fields = ["declarations"];
	static childFields = ["declarations"];
	declarations = _declarations;
}
function ASTVarDecl(_span = undefined, _target = undefined, _init = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_VarDecl;
	static kindName = "VarDecl";
	static fields = ["target", "init"];
	static childFields = ["target", "init"];
	target = _target;
	init = _init;
}
function ASTVarDeclList(_span = undefined, _declarations = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_VarDeclList;
	static kindName = "VarDeclList";
	static fields = ["declarations"];
	static childFields = ["declarations"];
	declarations = _declarations;
}
function ASTGlobalVarDecl(_span = undefined, _names = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_GlobalVarDecl;
	static kindName = "GlobalVarDecl";
	static fields = ["names"];
	static childFields = ["names"];
	names = _names;
}
function ASTEnumDecl(_span = undefined, _name = undefined, _members = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_EnumDecl;
	static kindName = "EnumDecl";
	static fields = ["name", "members"];
	static childFields = ["members"];
	name = _name;
	members = _members;
}
function ASTEnumMember(_span = undefined, _name = undefined, _value = undefined, _explicit = false, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_EnumMember;
	static kindName = "EnumMember";
	static fields = ["name", "value", "explicit"];
	static childFields = [];
	name = _name;
	value = _value;
	explicit = _explicit;
}
function ASTMacroDecl(_span = undefined, _name = undefined, _config = undefined, _body = "", _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_MacroDecl;
	static kindName = "MacroDecl";
	static fields = ["name", "config", "body"];
	static childFields = [];
	name = _name;
	config = _config;
	body = _body;
}
#endregion

#region Statements
function ASTIf(_span = undefined, _test = undefined, _consequent = undefined, _alternate = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_If;
	static kindName = "If";
	static fields = ["test", "consequent", "alternate"];
	static childFields = ["test", "consequent", "alternate"];
	test = _test;
	consequent = _consequent;
	alternate = _alternate;
}
function ASTFor(_span = undefined, _init = undefined, _test = undefined, _update = undefined, _body = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_For;
	static kindName = "For";
	static fields = ["init", "test", "update", "body"];
	static childFields = ["init", "test", "update", "body"];
	init = _init;
	test = _test;
	update = _update;
	body = _body;
}
function ASTWhile(_span = undefined, _test = undefined, _body = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_While;
	static kindName = "While";
	static fields = ["test", "body"];
	static childFields = ["test", "body"];
	test = _test;
	body = _body;
}
function ASTRepeat(_span = undefined, _count = undefined, _body = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Repeat;
	static kindName = "Repeat";
	static fields = ["count", "body"];
	static childFields = ["count", "body"];
	count = _count;
	body = _body;
}
function ASTDoUntil(_span = undefined, _body = undefined, _test = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_DoUntil;
	static kindName = "DoUntil";
	static fields = ["body", "test"];
	static childFields = ["body", "test"];
	body = _body;
	test = _test;
}
function ASTWith(_span = undefined, _target = undefined, _body = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_With;
	static kindName = "With";
	static fields = ["target", "body"];
	static childFields = ["target", "body"];
	target = _target;
	body = _body;
}
function ASTSwitch(_span = undefined, _discriminant = undefined, _cases = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Switch;
	static kindName = "Switch";
	static fields = ["discriminant", "cases"];
	static childFields = ["discriminant", "cases"];
	discriminant = _discriminant;
	cases = _cases;
}
function ASTCase(_span = undefined, _test = undefined, _body = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Case;
	static kindName = "Case";
	static fields = ["test", "body"];
	static childFields = ["test", "body"];
	test = _test;
	body = _body;
}
function ASTDefault(_span = undefined, _body = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Default;
	static kindName = "Default";
	static fields = ["body"];
	static childFields = ["body"];
	body = _body;
}
function ASTTry(_span = undefined, _block = undefined, _catchParam = undefined, _catchBody = undefined, _finallyBody = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Try;
	static kindName = "Try";
	static fields = ["block", "catch_param", "catch_body", "finally_body"];
	static childFields = ["block", "catch_param", "catch_body", "finally_body"];
	block = _block;
	catch_param = _catchParam;
	catch_body = _catchBody;
	finally_body = _finallyBody;
}
function ASTBreak(_span = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Break;
	static kindName = "Break";
	static fields = [];
	static childFields = [];
}
function ASTContinue(_span = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Continue;
	static kindName = "Continue";
	static fields = [];
	static childFields = [];
}
function ASTExit(_span = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Exit;
	static kindName = "Exit";
	static fields = [];
	static childFields = [];
}
function ASTReturn(_span = undefined, _argument = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Return;
	static kindName = "Return";
	static fields = ["argument"];
	static childFields = ["argument"];
	self[$ "argument"] = _argument; // `argument` is a built-in variable outside of `[$ ]`
}
function ASTThrow(_span = undefined, _argument = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Throw;
	static kindName = "Throw";
	static fields = ["argument"];
	static childFields = ["argument"];
	self[$ "argument"] = _argument; // `argument` is a built-in variable outside of `[$ ]`
}
function ASTDelete(_span = undefined, _target = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Delete;
	static kindName = "Delete";
	static fields = ["target"];
	static childFields = ["target"];
	target = _target;
}
function ASTExprStmt(_span = undefined, _expression = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_ExprStmt;
	static kindName = "ExprStmt";
	static fields = ["expression"];
	static childFields = ["expression"];
	expression = _expression;
}
function ASTEmpty(_span = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Empty;
	static kindName = "Empty";
	static fields = [];
	static childFields = [];
}
#endregion

#region Expressions
function ASTAssign(_span = undefined, _op = undefined, _target = undefined, _value = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Assign;
	static kindName = "Assign";
	static fields = ["op", "target", "value"];
	static childFields = ["target", "value"];
	op = _op;
	target = _target;
	value = _value;
}
function ASTBinary(_span = undefined, _op = undefined, _left = undefined, _right = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Binary;
	static kindName = "Binary";
	static fields = ["op", "left", "right"];
	static childFields = ["left", "right"];
	op = _op;
	left = _left;
	right = _right;
}
function ASTLogical(_span = undefined, _op = undefined, _left = undefined, _right = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Logical;
	static kindName = "Logical";
	static fields = ["op", "left", "right"];
	static childFields = ["left", "right"];
	op = _op;
	left = _left;
	right = _right;
}
function ASTNullish(_span = undefined, _left = undefined, _right = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Nullish;
	static kindName = "Nullish";
	static fields = ["left", "right"];
	static childFields = ["left", "right"];
	left = _left;
	right = _right;
}
function ASTUnary(_span = undefined, _op = undefined, _argument = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Unary;
	static kindName = "Unary";
	static fields = ["op", "argument"];
	static childFields = ["argument"];
	op = _op;
	self[$ "argument"] = _argument; // `argument` is a built-in variable outside of `[$ ]`
}
function ASTUpdate(_span = undefined, _op = undefined, _prefix = false, _argument = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Update;
	static kindName = "Update";
	static fields = ["op", "prefix", "argument"];
	static childFields = ["argument"];
	op = _op;
	prefix = _prefix;
	self[$ "argument"] = _argument; // `argument` is a built-in variable outside of `[$ ]`
}
function ASTConditional(_span = undefined, _test = undefined, _consequent = undefined, _alternate = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Conditional;
	static kindName = "Conditional";
	static fields = ["test", "consequent", "alternate"];
	static childFields = ["test", "consequent", "alternate"];
	test = _test;
	consequent = _consequent;
	alternate = _alternate;
}
function ASTCall(_span = undefined, _callee = undefined, _args = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Call;
	static kindName = "Call";
	static fields = ["callee", "args"];
	static childFields = ["callee", "args"];
	callee = _callee;
	args = _args;
}
function ASTMethodCall(_span = undefined, _object = undefined, _member = undefined, _args = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_MethodCall;
	static kindName = "MethodCall";
	static fields = ["object", "member", "args"];
	static childFields = ["object", "args"];
	object = _object;
	member = _member;
	args = _args;
}
function ASTNew(_span = undefined, _callee = undefined, _args = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_New;
	static kindName = "New";
	static fields = ["callee", "args"];
	static childFields = ["callee", "args"];
	callee = _callee;
	args = _args;
}
function ASTIndex(_span = undefined, _accessor = undefined, _object = undefined, _keys = [], _member = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Index;
	static kindName = "Index";
	static fields = ["accessor", "object", "keys", "member"];
	static childFields = ["object", "keys"];
	accessor = _accessor;
	object = _object;
	keys = _keys;
	member = _member;
}
function ASTIdentifier(_span = undefined, _name = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Identifier;
	static kindName = "Identifier";
	static fields = ["name", "symbol"];
	static childFields = [];
	name = _name;
	symbol = undefined;
}
function ASTLiteral(_span = undefined, _ty = undefined, _lexeme = "", _value = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Literal;
	static kindName = "Literal";
	static fields = ["ty", "lexeme", "value"];
	static childFields = [];
	ty = _ty;
	lexeme = _lexeme;
	value = _value;
}
function ASTArrayLiteral(_span = undefined, _elements = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_ArrayLiteral;
	static kindName = "ArrayLiteral";
	static fields = ["elements"];
	static childFields = ["elements"];
	elements = _elements;
}
function ASTStructLiteral(_span = undefined, _entries = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_StructLiteral;
	static kindName = "StructLiteral";
	static fields = ["entries"];
	static childFields = ["entries"];
	entries = _entries;
}
function ASTStructEntry(_span = undefined, _key = undefined, _quoted = false, _shorthand = false, _value = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_StructEntry;
	static kindName = "StructEntry";
	static fields = ["key", "quoted", "shorthand", "value"];
	static childFields = ["value"];
	key = _key;
	quoted = _quoted;
	shorthand = _shorthand;
	value = _value;
}
function ASTTemplateString(_span = undefined, _strings = [], _exprs = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_TemplateString;
	static kindName = "TemplateString";
	static fields = ["strings", "exprs"];
	static childFields = ["exprs"];
	strings = _strings;
	exprs = _exprs;
}
function ASTFunctionExpr(_span = undefined, _name = undefined, _isConstructor = false, _params = [], _parent = undefined, _body = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_FunctionExpr;
	static kindName = "FunctionExpr";
	static fields = ["name", "fn_id", "is_constructor", "params", "parent", "body"];
	static childFields = ["params", "parent", "body"];
	name = _name;
	fn_id = undefined;
	is_constructor = _isConstructor;
	params = _params;
	parent = _parent;
	body = _body;
}
function ASTNameof(_span = undefined, _name = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Nameof;
	static kindName = "Nameof";
	static fields = ["name"];
	static childFields = [];
	name = _name;
}
#endregion

#region Kind table
#region jsDoc
/// @func    __GMLC_NodeKinds()
/// @desc    The node kinds in kind-number order: their names, their constructors, and the number of each name.
/// @returns {Struct} {names, constructors, byName}
#endregion
function __GMLC_NodeKinds() {
	static __table = undefined;
	if (__table != undefined) return __table;
	var _constructors = [
		ASTScript, ASTBlock, ASTFunctionDecl, ASTConstructorDecl, ASTParam, ASTStaticDecl, ASTVarDecl, ASTVarDeclList,
		ASTGlobalVarDecl, ASTEnumDecl, ASTEnumMember, ASTMacroDecl, ASTIf, ASTFor, ASTWhile, ASTRepeat, ASTDoUntil,
		ASTWith, ASTSwitch, ASTCase, ASTDefault, ASTTry, ASTBreak, ASTContinue, ASTExit, ASTReturn, ASTThrow, ASTDelete,
		ASTExprStmt, ASTAssign, ASTBinary, ASTLogical, ASTNullish, ASTUnary, ASTUpdate, ASTConditional, ASTCall,
		ASTMethodCall, ASTNew, ASTIndex, ASTIdentifier, ASTLiteral, ASTArrayLiteral, ASTStructLiteral, ASTStructEntry,
		ASTTemplateString, ASTFunctionExpr, ASTNameof, ASTEmpty,
	];
	var _names = [
		"Script", "Block", "FunctionDecl", "ConstructorDecl", "Param", "StaticDecl", "VarDecl", "VarDeclList",
		"GlobalVarDecl", "EnumDecl", "EnumMember", "MacroDecl", "If", "For", "While", "Repeat", "DoUntil", "With",
		"Switch", "Case", "Default", "Try", "Break", "Continue", "Exit", "Return", "Throw", "Delete", "ExprStmt",
		"Assign", "Binary", "Logical", "Nullish", "Unary", "Update", "Conditional", "Call", "MethodCall", "New",
		"Index", "Identifier", "Literal", "ArrayLiteral", "StructLiteral", "StructEntry", "TemplateString",
		"FunctionExpr", "Nameof", "Empty",
	];
	var _byName = {};
	var _i = 0; repeat (array_length(_names)) {
		_byName[$ _names[_i]] = _i;
	_i++}
	__table = { names: _names, constructors: _constructors, byName: _byName };
	return __table;
}
#endregion
