#region Source positions
#region jsDoc
/// @func    GMLC_Span(_file, _start, _end)
/// @desc    A byte range of a source file.
/// @param   {Real} _file  : Number of the file in the compile's source table
/// @param   {Real} _start : First byte
/// @param   {Real} _end   : Byte after the last
/// @returns {Struct.GMLC_Span}
#endregion
function GMLC_Span(_file, _start, _end) constructor {
	file = _file;
	start = _start;
	self[$ "end"] = _end; // `end` is a keyword
}

#region jsDoc
/// @func    GMLC_SourceFile(_id, _name, _source, [_lineStarts], [_project])
/// @desc    One file of a compile, so a span can be turned into a line, a column and the line's text.
/// @param   {Real}        _id           : Number of the file in the source table
/// @param   {String}      _name         : Name of the file
/// @param   {String}      _source       : The file's text, line breaks normalized to LF
/// @param   {Array<Real>} [_lineStarts] : Byte offset of the start of every line, found from the text when undefined
/// @param   {String}      [_project]    : Name of the project the file belongs to, undefined when there is none
/// @returns {Struct.GMLC_SourceFile}
#endregion
function GMLC_SourceFile(_id, _name, _source, _lineStarts = undefined, _project = undefined) constructor {
	#region Init
	file_id = _id; // `id` is a built-in variable
	name = _name;
	project = _project;
	source = _source;
	line_starts = _lineStarts;
	if (line_starts == undefined) {
		// the byte offset of the start of every line
		var _lines = string_split(_source, "\n");
		line_starts = array_create(max(1, array_length(_lines)), 0);
		var _i = 1; repeat (array_length(_lines) - 1) {
			line_starts[_i] = line_starts[_i - 1] + string_byte_length(_lines[_i - 1]) + 1;
		_i++}
	}
	invalid_utf8 = false; // set by the lexer
	__line_texts = [];
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    lineOf(_offset)
	/// @desc    The 1-based line of a byte offset.
	/// @self    GMLC_SourceFile
	/// @param   {Real} _offset : Byte offset
	/// @returns {Real}
	#endregion
	static lineOf = function(_offset) {
		var _lo = 0;
		var _hi = array_length(line_starts) - 1;
		while (_lo < _hi) {
			var _mid = floor((_lo + _hi + 1) / 2); // `>>` would give an int64
			if (line_starts[_mid] <= _offset) {
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
		var _count = array_length(line_starts);
		if (_line < 1) || (_line > _count) return "";
		var _text = (_line <= array_length(__line_texts)) ? __line_texts[_line - 1] : undefined;
		// growing the array fills skipped places with 0
		if (!is_string(_text)) {
			var _start = line_starts[_line - 1];
			var _end = (_line < _count) ? line_starts[_line] - 1 : byteLength();
			_text = textBetween(_start, _end);
			__line_texts[_line - 1] = _text;
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
		var _start = line_starts[lineOf(_offset) - 1];
		return string_length(textBetween(_start, _offset)) + 1;
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
	/// @func    textBetween(_start, _end)
	/// @desc    The source text between two byte offsets.
	/// @self    GMLC_SourceFile
	/// @param   {Real} _start : First byte
	/// @param   {Real} _end   : Byte after the last
	/// @returns {String}
	#endregion
	static textBetween = function(_start, _end) {
		// one buffer shared by every file, holding the file read last
		static __buffer = buffer_create(256, buffer_grow, 1);
		static __holder = undefined;
		if (__holder != self) {
			buffer_seek(__buffer, buffer_seek_start, 0);
			buffer_write(__buffer, buffer_text, source);
			buffer_write(__buffer, buffer_u8, 0);
			__holder = self;
		}
		return __gmlc_buffer_text(__buffer, _start, _end);
	};
	#endregion
}

#region jsDoc
/// @func    GMLC_SourceTable([_file])
/// @desc    The files of one compile, by number. Spans name their file by its number here.
/// @param   {Struct.GMLC_SourceFile} [_file] : A first file, for a table of that file alone
/// @returns {Struct.GMLC_SourceTable}
#endregion
function GMLC_SourceTable(_file = undefined) constructor {
	#region Init
	files = [];
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    add(_file)
	/// @desc    Adds a file under its number.
	/// @self    GMLC_SourceTable
	/// @param   {Struct.GMLC_SourceFile} _file : The file
	/// @returns {Struct.GMLC_SourceFile}
	#endregion
	static add = function(_file) {
		// gaps hold undefined, not the 0 GameMaker would fill them with
		while (array_length(files) < _file.file_id) array_push(files, undefined);
		files[_file.file_id] = _file;
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
	#endregion
	
	if (_file != undefined) add(_file);
}

#region jsDoc
/// @func    __gmlc_byte_copy(_text, _from, _to)
/// @desc    The part of a string between two byte offsets.
/// @param   {String} _text : The string
/// @param   {Real}   _from : First byte
/// @param   {Real}   _to   : Byte after the last
/// @returns {String}
#endregion
function __gmlc_byte_copy(_text, _from, _to) {
	if (_to <= _from) return "";
	static __buffer = buffer_create(256, buffer_grow, 1);
	buffer_seek(__buffer, buffer_seek_start, 0);
	buffer_write(__buffer, buffer_text, _text);
	buffer_write(__buffer, buffer_u8, 0);
	return __gmlc_buffer_text(__buffer, _from, _to);
}

#region jsDoc
/// @func    __gmlc_buffer_text(_buffer, _from, _to)
/// @desc    The text of a buffer between two byte offsets; the buffer must hold a byte at _to.
/// @param   {Id.Buffer} _buffer : The buffer
/// @param   {Real}      _from   : First byte
/// @param   {Real}      _to     : Byte after the last
/// @returns {String}
#endregion
function __gmlc_buffer_text(_buffer, _from, _to) {
	if (_to <= _from) return "";
	// a 0 at _to ends the string while it is read
	var _byte = buffer_peek(_buffer, _to, buffer_u8);
	buffer_poke(_buffer, _to, buffer_u8, 0);
	buffer_seek(_buffer, buffer_seek_start, _from);
	var _text = buffer_read(_buffer, buffer_string);
	buffer_poke(_buffer, _to, buffer_u8, _byte);
	return _text;
}
#endregion

#region Records
#region jsDoc
/// @func    GMLC_Symbol(_kind, _name, [_slot])
/// @desc    What a name means, written on an Identifier by the resolver.
/// @param   {String} _kind : "Global", "BuiltinFunction", "Enum", "Local", "Static", "Self", ...
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
/// @desc    The macro use or enum reference that made a node's tokens; kind is "macro", "enum" or "compile_time".
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
/// @desc    A `#region` or `#endregion` line of a file.
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
/// @desc    A pragma comment of a file (`// @NoOp`).
/// @param   {String}           _pragma : The pragma's name
/// @param   {Struct.GMLC_Span} _span   : The comment
/// @param   {Struct.GMLC_Span} _target : The first statement after it, undefined when none follows
/// @returns {Struct.GMLC_Pragma}
#endregion
function GMLC_Pragma(_pragma, _span, _target) constructor {
	pragma = _pragma;
	span = _span;
	target = _target;
}

#region jsDoc
/// @func    GMLC_FunctionInfo(_fnId, _name, _parentFn, _params, _locals, _statics)
/// @desc    One function of a file, kept in the file's `functions` by fn_id (0 is the file's body). The resolver
///          fills the arguments; lowering fills fn_kind, registration, binding and facts.
/// @param   {Real}          _fnId     : The function's fn_id
/// @param   {String}        _name     : Its name, undefined for the file's body
/// @param   {Real}          _parentFn : fn_id of the function around it, undefined for the file's body
/// @param   {Array<String>} _params   : Its parameters, slots 0 to n-1
/// @param   {Array<String>} _locals   : Its `var` and catch names, slots n onwards
/// @param   {Array<String>} _statics  : Its static names in source order, which is initialization order
/// @returns {Struct.GMLC_FunctionInfo}
#endregion
function GMLC_FunctionInfo(_fnId, _name, _parentFn, _params, _locals, _statics) constructor {
	fn_id = _fnId;
	name = _name;
	fn_kind = undefined;      // "unit_body", "script_function", "method" or "constructor"
	registration = undefined; // "none", "global", "instance" or "value"
	binding = undefined;      // "none", "creator_self" or "new_struct"
	parent_fn = _parentFn;
	params = _params;
	locals = _locals;
	statics = _statics;
	facts = undefined;
}

#region jsDoc
/// @func    GMLC_PreprocessedUnit(_tokens, _macros, _enums, _regions, _pragmas)
/// @desc    One file after preprocessing: the expanded tokens (no trivia, ending with Eof) and its declarations.
/// @param   {Array<Struct>}               _tokens  : The tokens
/// @param   {Array<Struct.ASTMacroDecl>}  _macros  : The file's macro definitions
/// @param   {Array<Struct.ASTEnumDecl>}   _enums   : The file's enum declarations
/// @param   {Array<Struct.GMLC_Region>}   _regions : The file's regions
/// @param   {Array<Struct.GMLC_Pragma>}   _pragmas : The file's pragmas
/// @returns {Struct.GMLC_PreprocessedUnit}
#endregion
function GMLC_PreprocessedUnit(_tokens, _macros, _enums, _regions, _pragmas) constructor {
	tokens = _tokens;
	macros = _macros;
	enums = _enums;
	regions = _regions;
	pragmas = _pragmas;
}

#region jsDoc
/// @func    GMLC_FunctionFacts()
/// @desc    What lowering finds in one function's body, nested functions left out.
/// @returns {Struct.GMLC_FunctionFacts}
#endregion
function GMLC_FunctionFacts() constructor {
	statement_count = 0;
	node_count = 0;
	uses_argument_array = false;
	uses_argument_count = false;
	max_argument_index = -1;
	has_statics = false;
	has_nested_functions = false;
	contains_with = false;
	contains_exit = false;
	contains_try = false;
	reads_other = false;
	uses_compile_time_names = false;
	direct_recursion = false;
	single_trailing_return = false;
}
#endregion

#region Node base
#region jsDoc
/// @func    ASTNode(_span, [_origin])
/// @desc    The base of every node kind. Each kind has one constructor; its statics kind, kindName, fields and
///          childFields (in children() order) describe it.
/// @param   {Struct} _span     : Where the node is in the source
/// @param   {Struct} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTNode}
#endregion
function ASTNode(_span = undefined, _origin = undefined) constructor {
	#region Config
	static kind = undefined;
	static kindName = "";
	static fields = [];
	static childFields = [];
	#endregion
	
	#region Init
	span = _span;
	origin = _origin;
	#endregion
	
	#region Public
	#region jsDoc
	/// @func    children()
	/// @desc    The child nodes in `childFields` order, arrays flattened, empty fields left out.
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
	/// @desc    The child nodes with where each is held, so a stage can replace them; index is undefined for a
	///          field that holds one node.
	/// @self    ASTNode
	/// @returns {Array<Struct>}
	#endregion
	static childSlots = function() {
		var _out = [];
		// inside a struct literal `self` is the new struct
		var _self = self;
		var _fields = childFields;
		var _i = 0; repeat (array_length(_fields)) {
			var _key = _fields[_i];
			var _value = self[$ _key];
			if (is_array(_value)) {
				var _j = 0; repeat (array_length(_value)) {
					if (_value[_j] != undefined) array_push(_out, { node: _value[_j], parent: _self, key: _key, index: _j });
				_j++}
			}
			else if (_value != undefined) {
				array_push(_out, { node: _value, parent: _self, key: _key, index: undefined });
			}
		_i++}
		return _out;
	};
	#endregion
}
#endregion

#region Root and declarations
#region jsDoc
/// @func    ASTScript([_span], [_body], [_origin])
/// @desc    The root: a file's statements, declarations, regions, pragmas and (from the resolver) its functions.
/// @param   {Struct.GMLC_Span}      [_span]   : Where the node is in the source
/// @param   {Array<Struct.ASTNode>} [_body]   : The statements
/// @param   {Struct.GMLC_Origin}    [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTScript}
#endregion
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

#region jsDoc
/// @func    ASTBlock([_span], [_body], [_origin])
/// @desc    `{ statements }`.
/// @param   {Struct.GMLC_Span}      [_span]   : Where the node is in the source
/// @param   {Array<Struct.ASTNode>} [_body]   : The statements
/// @param   {Struct.GMLC_Origin}    [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTBlock}
#endregion
function ASTBlock(_span = undefined, _body = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Block;
	static kindName = "Block";
	static fields = ["body"];
	static childFields = ["body"];
	body = _body;
}

#region jsDoc
/// @func    ASTFunctionDecl([_span], [_name], [_params], [_body], [_origin])
/// @desc    `function name(params) { body }` as a statement.
/// @param   {Struct.GMLC_Span}       [_span]   : Where the node is in the source
/// @param   {String}                 [_name]   : The name
/// @param   {Array<Struct.ASTParam>} [_params] : The parameters
/// @param   {Struct.ASTBlock}        [_body]   : The body
/// @param   {Struct.GMLC_Origin}     [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTFunctionDecl}
#endregion
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

#region jsDoc
/// @func    ASTConstructorDecl([_span], [_name], [_params], [_parent], [_body], [_origin])
/// @desc    `function name(params) [: Parent(args)] constructor { body }` as a statement.
/// @param   {Struct.GMLC_Span}       [_span]   : Where the node is in the source
/// @param   {String}                 [_name]   : The name
/// @param   {Array<Struct.ASTParam>} [_params] : The parameters
/// @param   {Struct.ASTCall}         [_parent] : The parent constructor's call, undefined for none
/// @param   {Struct.ASTBlock}        [_body]   : The body
/// @param   {Struct.GMLC_Origin}     [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTConstructorDecl}
#endregion
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

#region jsDoc
/// @func    ASTParam([_span], [_target], [_default], [_origin])
/// @desc    A function parameter and its default value.
/// @param   {Struct.GMLC_Span}   [_span]    : Where the node is in the source
/// @param   {Struct.ASTNode}     [_target]  : The target
/// @param   {Struct.ASTNode}     [_default] : The default value, undefined for none
/// @param   {Struct.GMLC_Origin} [_origin]  : The macro or enum use the node came from
/// @returns {Struct.ASTParam}
#endregion
function ASTParam(_span = undefined, _target = undefined, _default = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Param;
	static kindName = "Param";
	static fields = ["target", "default"];
	static childFields = ["target", "default"];
	target = _target;
	self[$ "default"] = _default; // `default` is a keyword
}

#region jsDoc
/// @func    ASTStaticDecl([_span], [_declarations], [_origin])
/// @desc    `static a = 1, b = 2`.
/// @param   {Struct.GMLC_Span}         [_span]         : Where the node is in the source
/// @param   {Array<Struct.ASTVarDecl>} [_declarations] : The declarators
/// @param   {Struct.GMLC_Origin}       [_origin]       : The macro or enum use the node came from
/// @returns {Struct.ASTStaticDecl}
#endregion
function ASTStaticDecl(_span = undefined, _declarations = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_StaticDecl;
	static kindName = "StaticDecl";
	static fields = ["declarations"];
	static childFields = ["declarations"];
	declarations = _declarations;
}

#region jsDoc
/// @func    ASTVarDecl([_span], [_target], [_init], [_origin])
/// @desc    One declarator of `var` or `static`: a name and its value.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {Struct.ASTNode}     [_target] : The target
/// @param   {Struct.ASTNode}     [_init]   : The value, undefined for none
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTVarDecl}
#endregion
function ASTVarDecl(_span = undefined, _target = undefined, _init = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_VarDecl;
	static kindName = "VarDecl";
	static fields = ["target", "init"];
	static childFields = ["target", "init"];
	target = _target;
	init = _init;
}

#region jsDoc
/// @func    ASTVarDeclList([_span], [_declarations], [_origin])
/// @desc    `var a = 1, b`.
/// @param   {Struct.GMLC_Span}         [_span]         : Where the node is in the source
/// @param   {Array<Struct.ASTVarDecl>} [_declarations] : The declarators
/// @param   {Struct.GMLC_Origin}       [_origin]       : The macro or enum use the node came from
/// @returns {Struct.ASTVarDeclList}
#endregion
function ASTVarDeclList(_span = undefined, _declarations = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_VarDeclList;
	static kindName = "VarDeclList";
	static fields = ["declarations"];
	static childFields = ["declarations"];
	declarations = _declarations;
}

#region jsDoc
/// @func    ASTGlobalVarDecl([_span], [_names], [_origin])
/// @desc    `globalvar a, b`.
/// @param   {Struct.GMLC_Span}            [_span]   : Where the node is in the source
/// @param   {Array<Struct.ASTIdentifier>} [_names]  : The names
/// @param   {Struct.GMLC_Origin}          [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTGlobalVarDecl}
#endregion
function ASTGlobalVarDecl(_span = undefined, _names = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_GlobalVarDecl;
	static kindName = "GlobalVarDecl";
	static fields = ["names"];
	static childFields = ["names"];
	names = _names;
}

#region jsDoc
/// @func    ASTEnumDecl([_span], [_name], [_members], [_origin])
/// @desc    `enum Name { members }`; the preprocessor makes it.
/// @param   {Struct.GMLC_Span}            [_span]    : Where the node is in the source
/// @param   {String}                      [_name]    : The name
/// @param   {Array<Struct.ASTEnumMember>} [_members] : The members
/// @param   {Struct.GMLC_Origin}          [_origin]  : The macro or enum use the node came from
/// @returns {Struct.ASTEnumDecl}
#endregion
function ASTEnumDecl(_span = undefined, _name = undefined, _members = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_EnumDecl;
	static kindName = "EnumDecl";
	static fields = ["name", "members"];
	static childFields = ["members"];
	name = _name;
	members = _members;
}

#region jsDoc
/// @func    ASTEnumMember([_span], [_name], [_value], [_explicit], [_init], [_origin])
/// @desc    One member of an enum; the parser gives it its value expression, lowering its int64 value.
/// @param   {Struct.GMLC_Span}   [_span]     : Where the node is in the source
/// @param   {String}             [_name]     : The name
/// @param   {Int64}              [_value]    : Its value, given in lowering
/// @param   {Bool}               [_explicit] : Whether the member's value is written
/// @param   {Struct.ASTNode}     [_init]     : The value expression, undefined for none
/// @param   {Struct.GMLC_Origin} [_origin]   : The macro or enum use the node came from
/// @returns {Struct.ASTEnumMember}
#endregion
function ASTEnumMember(_span = undefined, _name = undefined, _value = undefined, _explicit = false, _init = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_EnumMember;
	static kindName = "EnumMember";
	static fields = ["name", "value", "explicit", "init"];
	static childFields = ["init"];
	name = _name;
	value = _value;       // int64, given in lowering
	explicit = _explicit;
	init = _init;
}

#region jsDoc
/// @func    ASTMacroDecl([_span], [_name], [_config], [_body], [_origin])
/// @desc    `#macro [Config:]NAME value`; the preprocessor makes it.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {String}             [_name]   : The name
/// @param   {String}             [_config] : The configuration, undefined for Default
/// @param   {String}             [_body]   : The value as written
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTMacroDecl}
#endregion
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
#region jsDoc
/// @func    ASTIf([_span], [_test], [_consequent], [_alternate], [_origin])
/// @desc    `if test consequent [else alternate]`.
/// @param   {Struct.GMLC_Span}   [_span]       : Where the node is in the source
/// @param   {Struct.ASTNode}     [_test]       : The condition
/// @param   {Struct.ASTBlock}    [_consequent] : The body run when the test holds
/// @param   {Struct.ASTBlock}    [_alternate]  : The `else` body, undefined for none
/// @param   {Struct.GMLC_Origin} [_origin]     : The macro or enum use the node came from
/// @returns {Struct.ASTIf}
#endregion
function ASTIf(_span = undefined, _test = undefined, _consequent = undefined, _alternate = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_If;
	static kindName = "If";
	static fields = ["test", "consequent", "alternate"];
	static childFields = ["test", "consequent", "alternate"];
	test = _test;
	consequent = _consequent;
	alternate = _alternate;
}

#region jsDoc
/// @func    ASTFor([_span], [_init], [_test], [_update], [_body], [_origin])
/// @desc    `for (init; test; update) body`.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {Struct.ASTNode}     [_init]   : The first statement, undefined for none
/// @param   {Struct.ASTNode}     [_test]   : The condition, undefined for none
/// @param   {Struct.ASTNode}     [_update] : The update, undefined for none
/// @param   {Struct.ASTBlock}    [_body]   : The body
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTFor}
#endregion
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

#region jsDoc
/// @func    ASTWhile([_span], [_test], [_body], [_origin])
/// @desc    `while test body`.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {Struct.ASTNode}     [_test]   : The condition
/// @param   {Struct.ASTBlock}    [_body]   : The body
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTWhile}
#endregion
function ASTWhile(_span = undefined, _test = undefined, _body = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_While;
	static kindName = "While";
	static fields = ["test", "body"];
	static childFields = ["test", "body"];
	test = _test;
	body = _body;
}

#region jsDoc
/// @func    ASTRepeat([_span], [_count], [_body], [_origin])
/// @desc    `repeat count body`.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {Struct.ASTNode}     [_count]  : The number of times
/// @param   {Struct.ASTBlock}    [_body]   : The body
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTRepeat}
#endregion
function ASTRepeat(_span = undefined, _count = undefined, _body = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Repeat;
	static kindName = "Repeat";
	static fields = ["count", "body"];
	static childFields = ["count", "body"];
	count = _count;
	body = _body;
}

#region jsDoc
/// @func    ASTDoUntil([_span], [_body], [_test], [_origin])
/// @desc    `do body until test`.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {Struct.ASTBlock}    [_body]   : The body
/// @param   {Struct.ASTNode}     [_test]   : The condition
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTDoUntil}
#endregion
function ASTDoUntil(_span = undefined, _body = undefined, _test = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_DoUntil;
	static kindName = "DoUntil";
	static fields = ["body", "test"];
	static childFields = ["body", "test"];
	body = _body;
	test = _test;
}

#region jsDoc
/// @func    ASTWith([_span], [_target], [_body], [_origin])
/// @desc    `with target body`.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {Struct.ASTNode}     [_target] : The instance, object or struct
/// @param   {Struct.ASTBlock}    [_body]   : The body
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTWith}
#endregion
function ASTWith(_span = undefined, _target = undefined, _body = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_With;
	static kindName = "With";
	static fields = ["target", "body"];
	static childFields = ["target", "body"];
	target = _target;
	body = _body;
}

#region jsDoc
/// @func    ASTSwitch([_span], [_discriminant], [_cases], [_origin])
/// @desc    `switch discriminant { cases }`.
/// @param   {Struct.GMLC_Span}      [_span]         : Where the node is in the source
/// @param   {Struct.ASTNode}        [_discriminant] : The value switched on
/// @param   {Array<Struct.ASTNode>} [_cases]        : The Case and Default clauses
/// @param   {Struct.GMLC_Origin}    [_origin]       : The macro or enum use the node came from
/// @returns {Struct.ASTSwitch}
#endregion
function ASTSwitch(_span = undefined, _discriminant = undefined, _cases = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Switch;
	static kindName = "Switch";
	static fields = ["discriminant", "cases"];
	static childFields = ["discriminant", "cases"];
	discriminant = _discriminant;
	cases = _cases;
}

#region jsDoc
/// @func    ASTCase([_span], [_test], [_body], [_origin])
/// @desc    `case test: body` of a switch.
/// @param   {Struct.GMLC_Span}      [_span]   : Where the node is in the source
/// @param   {Struct.ASTNode}        [_test]   : The value compared
/// @param   {Array<Struct.ASTNode>} [_body]   : The statements
/// @param   {Struct.GMLC_Origin}    [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTCase}
#endregion
function ASTCase(_span = undefined, _test = undefined, _body = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Case;
	static kindName = "Case";
	static fields = ["test", "body"];
	static childFields = ["test", "body"];
	test = _test;
	body = _body;
}

#region jsDoc
/// @func    ASTDefault([_span], [_body], [_origin])
/// @desc    `default: body` of a switch.
/// @param   {Struct.GMLC_Span}      [_span]   : Where the node is in the source
/// @param   {Array<Struct.ASTNode>} [_body]   : The statements
/// @param   {Struct.GMLC_Origin}    [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTDefault}
#endregion
function ASTDefault(_span = undefined, _body = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Default;
	static kindName = "Default";
	static fields = ["body"];
	static childFields = ["body"];
	body = _body;
}

#region jsDoc
/// @func    ASTTry([_span], [_block], [_catchParam], [_catchBody], [_finallyBody], [_origin])
/// @desc    `try block [catch (param) catch_body] [finally finally_body]`.
/// @param   {Struct.GMLC_Span}     [_span]        : Where the node is in the source
/// @param   {Struct.ASTBlock}      [_block]       : The block tried
/// @param   {Struct.ASTIdentifier} [_catchParam]  : The caught value's name, undefined for none
/// @param   {Struct.ASTBlock}      [_catchBody]   : The catch body, undefined for none
/// @param   {Struct.ASTBlock}      [_finallyBody] : The finally body, undefined for none
/// @param   {Struct.GMLC_Origin}   [_origin]      : The macro or enum use the node came from
/// @returns {Struct.ASTTry}
#endregion
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

#region jsDoc
/// @func    ASTBreak([_span], [_origin])
/// @desc    `break`.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTBreak}
#endregion
function ASTBreak(_span = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Break;
	static kindName = "Break";
	static fields = [];
	static childFields = [];
}

#region jsDoc
/// @func    ASTContinue([_span], [_origin])
/// @desc    `continue`.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTContinue}
#endregion
function ASTContinue(_span = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Continue;
	static kindName = "Continue";
	static fields = [];
	static childFields = [];
}

#region jsDoc
/// @func    ASTExit([_span], [_origin])
/// @desc    `exit`.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTExit}
#endregion
function ASTExit(_span = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Exit;
	static kindName = "Exit";
	static fields = [];
	static childFields = [];
}

#region jsDoc
/// @func    ASTReturn([_span], [_argument], [_origin])
/// @desc    `return [argument]`.
/// @param   {Struct.GMLC_Span}   [_span]     : Where the node is in the source
/// @param   {Struct.ASTNode}     [_argument] : The value, undefined for none
/// @param   {Struct.GMLC_Origin} [_origin]   : The macro or enum use the node came from
/// @returns {Struct.ASTReturn}
#endregion
function ASTReturn(_span = undefined, _argument = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Return;
	static kindName = "Return";
	static fields = ["argument"];
	static childFields = ["argument"];
	self[$ "argument"] = _argument; // `argument` is a built-in variable
}

#region jsDoc
/// @func    ASTThrow([_span], [_argument], [_origin])
/// @desc    `throw argument`.
/// @param   {Struct.GMLC_Span}   [_span]     : Where the node is in the source
/// @param   {Struct.ASTNode}     [_argument] : The value thrown
/// @param   {Struct.GMLC_Origin} [_origin]   : The macro or enum use the node came from
/// @returns {Struct.ASTThrow}
#endregion
function ASTThrow(_span = undefined, _argument = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Throw;
	static kindName = "Throw";
	static fields = ["argument"];
	static childFields = ["argument"];
	self[$ "argument"] = _argument; // `argument` is a built-in variable
}

#region jsDoc
/// @func    ASTDelete([_span], [_target], [_origin])
/// @desc    `delete target`.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {Struct.ASTNode}     [_target] : The target
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTDelete}
#endregion
function ASTDelete(_span = undefined, _target = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Delete;
	static kindName = "Delete";
	static fields = ["target"];
	static childFields = ["target"];
	target = _target;
}

#region jsDoc
/// @func    ASTExprStmt([_span], [_expression], [_origin])
/// @desc    An expression used as a statement: an assignment, a call, `new` or `++`/`--`.
/// @param   {Struct.GMLC_Span}   [_span]       : Where the node is in the source
/// @param   {Struct.ASTNode}     [_expression] : The expression
/// @param   {Struct.GMLC_Origin} [_origin]     : The macro or enum use the node came from
/// @returns {Struct.ASTExprStmt}
#endregion
function ASTExprStmt(_span = undefined, _expression = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_ExprStmt;
	static kindName = "ExprStmt";
	static fields = ["expression"];
	static childFields = ["expression"];
	expression = _expression;
}

#region jsDoc
/// @func    ASTEmpty([_span], [_origin])
/// @desc    A `;` alone, or an argument left out of a call.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTEmpty}
#endregion
function ASTEmpty(_span = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Empty;
	static kindName = "Empty";
	static fields = [];
	static childFields = [];
}
#endregion

#region Expressions
#region jsDoc
/// @func    ASTAssign([_span], [_op], [_target], [_value], [_origin])
/// @desc    `target op value`, op being `=` or a compound assignment.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {String}             [_op]     : The operator
/// @param   {Struct.ASTNode}     [_target] : The target
/// @param   {Struct.ASTNode}     [_value]  : The value
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTAssign}
#endregion
function ASTAssign(_span = undefined, _op = undefined, _target = undefined, _value = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Assign;
	static kindName = "Assign";
	static fields = ["op", "target", "value"];
	static childFields = ["target", "value"];
	op = _op;
	target = _target;
	value = _value;
}

#region jsDoc
/// @func    ASTBinary([_span], [_op], [_left], [_right], [_origin])
/// @desc    `left op right` for an arithmetic, bitwise or comparison operator.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {String}             [_op]     : The operator
/// @param   {Struct.ASTNode}     [_left]   : The left operand
/// @param   {Struct.ASTNode}     [_right]  : The right operand
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTBinary}
#endregion
function ASTBinary(_span = undefined, _op = undefined, _left = undefined, _right = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Binary;
	static kindName = "Binary";
	static fields = ["op", "left", "right"];
	static childFields = ["left", "right"];
	op = _op;
	left = _left;
	right = _right;
}

#region jsDoc
/// @func    ASTLogical([_span], [_op], [_left], [_right], [_origin])
/// @desc    `left op right` for `&&`, `||` or `^^`.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {String}             [_op]     : The operator
/// @param   {Struct.ASTNode}     [_left]   : The left operand
/// @param   {Struct.ASTNode}     [_right]  : The right operand
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTLogical}
#endregion
function ASTLogical(_span = undefined, _op = undefined, _left = undefined, _right = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Logical;
	static kindName = "Logical";
	static fields = ["op", "left", "right"];
	static childFields = ["left", "right"];
	op = _op;
	left = _left;
	right = _right;
}

#region jsDoc
/// @func    ASTNullish([_span], [_left], [_right], [_origin])
/// @desc    `left ?? right`.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {Struct.ASTNode}     [_left]   : The left operand
/// @param   {Struct.ASTNode}     [_right]  : The right operand
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTNullish}
#endregion
function ASTNullish(_span = undefined, _left = undefined, _right = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Nullish;
	static kindName = "Nullish";
	static fields = ["left", "right"];
	static childFields = ["left", "right"];
	left = _left;
	right = _right;
}

#region jsDoc
/// @func    ASTUnary([_span], [_op], [_argument], [_origin])
/// @desc    `op argument` for `!`, `-`, `+` or `~`.
/// @param   {Struct.GMLC_Span}   [_span]     : Where the node is in the source
/// @param   {String}             [_op]       : The operator
/// @param   {Struct.ASTNode}     [_argument] : The operand
/// @param   {Struct.GMLC_Origin} [_origin]   : The macro or enum use the node came from
/// @returns {Struct.ASTUnary}
#endregion
function ASTUnary(_span = undefined, _op = undefined, _argument = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Unary;
	static kindName = "Unary";
	static fields = ["op", "argument"];
	static childFields = ["argument"];
	op = _op;
	self[$ "argument"] = _argument; // `argument` is a built-in variable
}

#region jsDoc
/// @func    ASTUpdate([_span], [_op], [_prefix], [_argument], [_origin])
/// @desc    `++` or `--`, before or after its argument.
/// @param   {Struct.GMLC_Span}   [_span]     : Where the node is in the source
/// @param   {String}             [_op]       : The operator
/// @param   {Bool}               [_prefix]   : Whether the operator comes first
/// @param   {Struct.ASTNode}     [_argument] : The operand
/// @param   {Struct.GMLC_Origin} [_origin]   : The macro or enum use the node came from
/// @returns {Struct.ASTUpdate}
#endregion
function ASTUpdate(_span = undefined, _op = undefined, _prefix = false, _argument = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	//   thing++    thing--    ++thing    or    --thing
	static kind = __GMLC_NodeKind_Update;
	static kindName = "Update";
	static fields = ["op", "prefix", "argument"];
	static childFields = ["argument"];
	op = _op;
	prefix = _prefix;
	self[$ "argument"] = _argument; // `argument` is a built-in variable
}

#region jsDoc
/// @func    ASTConditional([_span], [_test], [_consequent], [_alternate], [_origin])
/// @desc    `test ? consequent : alternate`.
/// @param   {Struct.GMLC_Span}   [_span]       : Where the node is in the source
/// @param   {Struct.ASTNode}     [_test]       : The condition
/// @param   {Struct.ASTNode}     [_consequent] : The branch taken when the condition holds
/// @param   {Struct.ASTNode}     [_alternate]  : The other branch, undefined for none
/// @param   {Struct.GMLC_Origin} [_origin]     : The macro or enum use the node came from
/// @returns {Struct.ASTConditional}
#endregion
function ASTConditional(_span = undefined, _test = undefined, _consequent = undefined, _alternate = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Conditional;
	static kindName = "Conditional";
	static fields = ["test", "consequent", "alternate"];
	static childFields = ["test", "consequent", "alternate"];
	test = _test;
	consequent = _consequent;
	alternate = _alternate;
}

#region jsDoc
/// @func    ASTCall([_span], [_callee], [_args], [_origin])
/// @desc    `callee(args)`.
/// @param   {Struct.GMLC_Span}      [_span]   : Where the node is in the source
/// @param   {Struct.ASTNode}        [_callee] : The function called
/// @param   {Array<Struct.ASTNode>} [_args]   : The arguments
/// @param   {Struct.GMLC_Origin}    [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTCall}
#endregion
function ASTCall(_span = undefined, _callee = undefined, _args = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Call;
	static kindName = "Call";
	static fields = ["callee", "args"];
	static childFields = ["callee", "args"];
	callee = _callee;
	args = _args;
}

#region jsDoc
/// @func    ASTMethodCall([_span], [_object], [_member], [_args], [_origin])
/// @desc    `object.member(args)`.
/// @param   {Struct.GMLC_Span}      [_span]   : Where the node is in the source
/// @param   {Struct.ASTNode}        [_object] : The value the method is read from
/// @param   {String}                [_member] : The member's name
/// @param   {Array<Struct.ASTNode>} [_args]   : The arguments
/// @param   {Struct.GMLC_Origin}    [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTMethodCall}
#endregion
function ASTMethodCall(_span = undefined, _object = undefined, _member = undefined, _args = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_MethodCall;
	static kindName = "MethodCall";
	static fields = ["object", "member", "args"];
	static childFields = ["object", "args"];
	object = _object;
	member = _member;
	args = _args;
}

#region jsDoc
/// @func    ASTNew([_span], [_callee], [_args], [_origin])
/// @desc    `new callee(args)`.
/// @param   {Struct.GMLC_Span}      [_span]   : Where the node is in the source
/// @param   {Struct.ASTNode}        [_callee] : The constructor
/// @param   {Array<Struct.ASTNode>} [_args]   : The arguments
/// @param   {Struct.GMLC_Origin}    [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTNew}
#endregion
function ASTNew(_span = undefined, _callee = undefined, _args = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_New;
	static kindName = "New";
	static fields = ["callee", "args"];
	static childFields = ["callee", "args"];
	callee = _callee;
	args = _args;
}

#region jsDoc
/// @func    ASTIndex([_span], [_accessor], [_object], [_keys], [_member], [_origin])
/// @desc    An accessor: `.member` (accessor "Dot") or a bracket accessor with its keys.
/// @param   {Struct.GMLC_Span}      [_span]     : Where the node is in the source
/// @param   {String}                [_accessor] : "Dot", "Array", "Array2D", "ArrayAt", "Array2DAt", "List", "Map", "Grid" or "Struct"
/// @param   {Struct.ASTNode}        [_object]   : The value accessed
/// @param   {Array<Struct.ASTNode>} [_keys]     : The keys in the brackets
/// @param   {String}                [_member]   : The name after `.`, undefined for a bracket accessor
/// @param   {Struct.GMLC_Origin}    [_origin]   : The macro or enum use the node came from
/// @returns {Struct.ASTIndex}
#endregion
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

#region jsDoc
/// @func    ASTIdentifier([_span], [_name], [_origin])
/// @desc    A name; the resolver gives it its symbol.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {String}             [_name]   : The name
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTIdentifier}
#endregion
function ASTIdentifier(_span = undefined, _name = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Identifier;
	static kindName = "Identifier";
	static fields = ["name", "symbol"];
	static childFields = [];
	name = _name;
	symbol = undefined;
}

#region jsDoc
/// @func    ASTLiteral([_span], [_ty], [_lexeme], [_value], [_origin])
/// @desc    A number, string or constant literal.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {String}             [_ty]     : The literal's type: "real", "int64", "string", "bool", "undefined", ...
/// @param   {String}             [_lexeme] : The literal as written
/// @param   {Any}                [_value]  : The value
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTLiteral}
#endregion
function ASTLiteral(_span = undefined, _ty = undefined, _lexeme = "", _value = undefined, _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_Literal;
	static kindName = "Literal";
	static fields = ["ty", "lexeme", "value"];
	static childFields = [];
	ty = _ty;
	lexeme = _lexeme;
	value = _value;
}

#region jsDoc
/// @func    ASTArrayLiteral([_span], [_elements], [_origin])
/// @desc    `[elements]`.
/// @param   {Struct.GMLC_Span}      [_span]     : Where the node is in the source
/// @param   {Array<Struct.ASTNode>} [_elements] : The elements
/// @param   {Struct.GMLC_Origin}    [_origin]   : The macro or enum use the node came from
/// @returns {Struct.ASTArrayLiteral}
#endregion
function ASTArrayLiteral(_span = undefined, _elements = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_ArrayLiteral;
	static kindName = "ArrayLiteral";
	static fields = ["elements"];
	static childFields = ["elements"];
	elements = _elements;
}

#region jsDoc
/// @func    ASTStructLiteral([_span], [_entries], [_origin])
/// @desc    `{entries}`.
/// @param   {Struct.GMLC_Span}             [_span]    : Where the node is in the source
/// @param   {Array<Struct.ASTStructEntry>} [_entries] : The entries
/// @param   {Struct.GMLC_Origin}           [_origin]  : The macro or enum use the node came from
/// @returns {Struct.ASTStructLiteral}
#endregion
function ASTStructLiteral(_span = undefined, _entries = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_StructLiteral;
	static kindName = "StructLiteral";
	static fields = ["entries"];
	static childFields = ["entries"];
	entries = _entries;
}

#region jsDoc
/// @func    ASTStructEntry([_span], [_key], [_quoted], [_shorthand], [_value], [_origin])
/// @desc    `key: value` of a struct literal; a shorthand `{a}` has the name as its value.
/// @param   {Struct.GMLC_Span}   [_span]      : Where the node is in the source
/// @param   {String}             [_key]       : The key
/// @param   {Bool}               [_quoted]    : Whether the key is written as a string
/// @param   {Bool}               [_shorthand] : Whether it is written `{a}`
/// @param   {Struct.ASTNode}     [_value]     : The value
/// @param   {Struct.GMLC_Origin} [_origin]    : The macro or enum use the node came from
/// @returns {Struct.ASTStructEntry}
#endregion
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

#region jsDoc
/// @func    ASTTemplateString([_span], [_strings], [_exprs], [_origin])
/// @desc    `$"text {expression} text"`: the text parts and the expressions between them.
/// @param   {Struct.GMLC_Span}      [_span]    : Where the node is in the source
/// @param   {Array<String>}         [_strings] : The text parts, unescaped
/// @param   {Array<Struct.ASTNode>} [_exprs]   : The expressions between them
/// @param   {Struct.GMLC_Origin}    [_origin]  : The macro or enum use the node came from
/// @returns {Struct.ASTTemplateString}
#endregion
function ASTTemplateString(_span = undefined, _strings = [], _exprs = [], _origin = undefined) : ASTNode(_span, _origin) constructor {
	static kind = __GMLC_NodeKind_TemplateString;
	static kindName = "TemplateString";
	static fields = ["strings", "exprs"];
	static childFields = ["exprs"];
	strings = _strings;
	exprs = _exprs;
}

#region jsDoc
/// @func    ASTFunctionExpr([_span], [_name], [_isConstructor], [_params], [_parent], [_body], [_origin])
/// @desc    `function [name](params) [: Parent(args)] [constructor] { body }` in an expression.
/// @param   {Struct.GMLC_Span}       [_span]          : Where the node is in the source
/// @param   {String}                 [_name]          : The name, undefined for none
/// @param   {Bool}                   [_isConstructor] : Whether it is a constructor
/// @param   {Array<Struct.ASTParam>} [_params]        : The parameters
/// @param   {Struct.ASTCall}         [_parent]        : The parent constructor's call, undefined for none
/// @param   {Struct.ASTBlock}        [_body]          : The body
/// @param   {Struct.GMLC_Origin}     [_origin]        : The macro or enum use the node came from
/// @returns {Struct.ASTFunctionExpr}
#endregion
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

#region jsDoc
/// @func    ASTNameof([_span], [_name], [_origin])
/// @desc    `nameof(name)`.
/// @param   {Struct.GMLC_Span}   [_span]   : Where the node is in the source
/// @param   {String}             [_name]   : The name written
/// @param   {Struct.GMLC_Origin} [_origin] : The macro or enum use the node came from
/// @returns {Struct.ASTNameof}
#endregion
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
/// @func    __gmlc_node_kinds()
/// @desc    The node kinds in kind-number order.
/// @returns {Struct} {names, constructors, by_name}
#endregion
function __gmlc_node_kinds() {
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
	__table = { names: _names, constructors: _constructors, by_name: _byName };
	return __table;
}
#endregion
