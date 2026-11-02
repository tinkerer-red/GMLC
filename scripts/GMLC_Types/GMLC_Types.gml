// types as canonical type strings, and the readers of the signature database's type text and of JSDoc and Feather
// annotations.
// a type is a union of atoms: members sorted by rank and then by text, duplicates removed, a member another member
// contains removed (`Int|Double` is `Double`, `Bool|Real` is `Real`, `Enum.Dir|Int64` is `Int64`), more than 8
// members `Unknown`, and any union holding `Unknown` or `Any` that element (`Any` first).

#macro __GMLC_TYPE_UNION_CAP 8

#region Type strings
#region jsDoc
/// @func    gmlc_type_string(_text, _mode)
/// @desc    The canonical string of type text, or undefined when it does not parse (GMLC3201 for an annotation).
/// @param   {String} _text : Type text
/// @param   {String} _mode : "spec-param" or "spec-return" (the signature database), or "jsdoc"
/// @returns {String}
#endregion
function gmlc_type_string(_text, _mode) {
	// raw: inside the generic argument of Id, where a bare name is an object or asset name kept as written
	var _r = { text: _text, pos: 1, len: string_length(_text), mode: _mode, raw: false };
	var _members = __gmlc_type_union(_r);
	if (_members == undefined) return undefined;
	__gmlc_type_skip(_r);
	if (_r.pos <= _r.len) return undefined;
	return __gmlc_type_normalize(_members);
}

#region jsDoc
/// @func    __gmlc_type_rank(_atom)
/// @desc    The place of an atom in a union: Never first, Any last.
/// @param   {String} _atom : The atom
/// @returns {Real}
#endregion
function __gmlc_type_rank(_atom) {
	switch (_atom) {
		case "Never": return 0;
		case "Undefined": return 1;
		case "Bool": return 2;
		case "Int": return 3;
		case "Double": return 4;
		case "Int64": return 6;
		case "Real": return 8;
		case "String": return 9;
		case "Struct": return 11;
		case "Pointer": return 14;
		case "Unknown": return 18;
		case "Any": return 19;
	}
	static __named = [["Enum.", 5], ["Constant.", 7], ["Array<", 10], ["Struct.", 12], ["Function(", 13], ["Pointer.", 15], ["Id.", 16], ["Asset", 17]];
	var _i = 0; repeat (array_length(__named)) {
		if (string_starts_with(_atom, __named[_i][0])) return __named[_i][1];
	_i++}
	return 18;
}

#region jsDoc
/// @func    __gmlc_type_contains(_outer, _inner)
/// @desc    Whether one atom holds another, so a union keeps only the outer one (`Real` holds `Int`).
/// @param   {String} _outer : The atom that may hold
/// @param   {String} _inner : The atom that may be held
/// @returns {Bool}
#endregion
function __gmlc_type_contains(_outer, _inner) {
	switch (_outer) {
		case "Real":
			return (_inner == "Int") || (_inner == "Double") || (_inner == "Int64") || (_inner == "Bool")
				|| string_starts_with(_inner, "Enum.") || string_starts_with(_inner, "Constant.");
		case "Double": return _inner == "Int";
		case "Int64": return string_starts_with(_inner, "Enum.");
		case "Struct": return string_starts_with(_inner, "Struct.");
		case "Pointer": return string_starts_with(_inner, "Pointer.");
		case "Asset": return string_starts_with(_inner, "Asset.");
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_type_normalize(_members)
/// @desc    The canonical string of a union's atoms: sorted, duplicates and held atoms removed, Unknown above 8
///          members.
/// @param   {Array<String>} _members : The atoms
/// @returns {String}
#endregion
function __gmlc_type_normalize(_members) {
	if (array_contains(_members, "Any")) return "Any";
	if (array_contains(_members, "Unknown")) return "Unknown";
	var _list = array_unique(_members);
	var _kept = [];
	var _i = 0; repeat (array_length(_list)) {
		var _m = _list[_i];
		var _absorbed = false;
		var _j = 0; repeat (array_length(_list)) {
			if (_list[_j] != _m) && (__gmlc_type_contains(_list[_j], _m)) {
				_absorbed = true;
				break;
			}
		_j++}
		if (!_absorbed) array_push(_kept, _m);
	_i++}
	array_sort(_kept, function(_a, _b) {
		var _d = __gmlc_type_rank(_a) - __gmlc_type_rank(_b);
		if (_d != 0) return _d;
		return __gmlc_type_bytes_compare(_a, _b);
	});
	if (array_length(_kept) > __GMLC_TYPE_UNION_CAP) return "Unknown";
	if (array_length(_kept) == 0) return "Never";
	return string_join_ext("|", _kept);
}

#region jsDoc
/// @func    __gmlc_compare_fn_id(_a, _b)
/// @desc    Orders two function units by their function id.
/// @param   {Struct} _a : A unit
/// @param   {Struct} _b : A unit
/// @returns {Real}
#endregion
function __gmlc_compare_fn_id(_a, _b) {
	return _a.fn_id - _b.fn_id;
}

#region jsDoc
/// @func    __gmlc_type_bytes_compare(_a, _b)
/// @desc    Compares two strings byte by byte: negative, zero or positive.
/// @param   {String} _a : A string
/// @param   {String} _b : A string
/// @returns {Real}
#endregion
function __gmlc_type_bytes_compare(_a, _b) {
	var _n = min(string_byte_length(_a), string_byte_length(_b));
	var _i = 1; repeat (_n) {
		var _d = string_byte_at(_a, _i) - string_byte_at(_b, _i);
		if (_d != 0) return _d;
	_i++}
	return string_byte_length(_a) - string_byte_length(_b);
}

#region jsDoc
/// @func    __gmlc_type_skip(_r)
/// @desc    Moves the reader past blanks.
/// @param   {Struct} _r : The reader, {text, pos, len, mode, raw}
#endregion
function __gmlc_type_skip(_r) {
	while (_r.pos <= _r.len) {
		var _c = string_char_at(_r.text, _r.pos);
		if (_c != " ") && (_c != "	") && (_c != "\n") && (_c != "\r") break;
		_r.pos++;
	}
}

#region jsDoc
/// @func    __gmlc_type_eat(_r, _s)
/// @desc    Moves the reader past _s, after blanks, when the text goes on with it.
/// @param   {Struct} _r : The reader, {text, pos, len, mode, raw}
/// @param   {String} _s : The expected text
/// @returns {Bool}
#endregion
function __gmlc_type_eat(_r, _s) {
	__gmlc_type_skip(_r);
	if (string_copy(_r.text, _r.pos, string_length(_s)) == _s) {
		_r.pos += string_length(_s);
		return true;
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_type_union(_r, [_commas])
/// @desc    Members separated by |, or by , too unless _commas is false (a comma ends a parameter or return
///          type).
#endregion
function __gmlc_type_union(_r, _commas = true) {
	var _out = __gmlc_type_member(_r);
	if (_out == undefined) return undefined;
	while (__gmlc_type_eat(_r, "|") || (_commas && __gmlc_type_eat(_r, ","))) {
		var _more = __gmlc_type_member(_r);
		if (_more == undefined) return undefined;
		_out = array_concat(_out, _more);
	}
	return _out;
}

#region jsDoc
/// @func    __gmlc_type_name(_r)
/// @desc    Reads a dotted name (`Id.Instance`); undefined when there is none.
/// @param   {Struct} _r : The reader, {text, pos, len, mode, raw}
/// @returns {String}
#endregion
function __gmlc_type_name(_r) {
	__gmlc_type_skip(_r);
	var _start = _r.pos;
	while (_r.pos <= _r.len) {
		var _c = string_char_at(_r.text, _r.pos);
		var _o = ord(_c);
		if ((_o >= ord("a")) && (_o <= ord("z"))) || ((_o >= ord("A")) && (_o <= ord("Z"))) || ((_o >= ord("0")) && (_o <= ord("9")))
		|| (_c == "_") || ((_c == ".") && (_r.pos > _start)) {
			_r.pos++;
		}
		else break;
	}
	if (_r.pos == _start) || (string_char_at(_r.text, _r.pos - 1) == ".") return undefined;
	return string_copy(_r.text, _start, _r.pos - _start);
}

#region jsDoc
/// @func    __gmlc_type_member(_r)
/// @desc    Reads one member of a union, a bracketed union or a name with its generic argument, as atoms; undefined
///          when it does not parse.
/// @param   {Struct} _r : The reader, {text, pos, len, mode, raw}
/// @returns {Array<String>}
#endregion
function __gmlc_type_member(_r) {
	if (__gmlc_type_eat(_r, "[")) {
		var _inner = __gmlc_type_union(_r);
		if (_inner == undefined) || (!__gmlc_type_eat(_r, "]")) return undefined;
		return _inner;
	}
	var _name = __gmlc_type_name(_r);
	if (_name == undefined) return undefined;
	var _dot = string_pos(".", _name);
	var _base = (_dot > 0) ? string_copy(_name, 1, _dot - 1) : _name;
	var _spec = (_dot > 0) ? string_delete(_name, 1, _dot) : undefined;
	var _lower = string_lower(_base);
	// a generic argument: <T>, or [T] as the signature database writes it
	var _arg = undefined;
	__gmlc_type_skip(_r);
	var _next = (_r.pos <= _r.len) ? string_char_at(_r.text, _r.pos) : "";
	if (_next == "<") || ((_next == "[") && ((_lower == "array") || (_lower == "id"))) {
		var _close = (_next == "<") ? ">" : "]";
		_r.pos++;
		var _raw = _r.raw;
		_r.raw = (_lower == "id");
		var _inner = __gmlc_type_union(_r);
		_r.raw = _raw;
		if (_inner == undefined) || (!__gmlc_type_eat(_r, _close)) return undefined;
		_arg = __gmlc_type_normalize(_inner);
	}
	if (_lower == "function") || (_lower == "method") {
		var _fn = __gmlc_type_function(_r);
		return (_fn == undefined) ? undefined : [_fn];
	}
	var _atom;
	switch (_lower) {
		case "never": _atom = "Never"; break;
		case "undefined": _atom = "Undefined"; break;
		case "bool": case "boolean": _atom = "Bool"; break;
		case "int": _atom = "Int"; break;
		case "double": _atom = "Double"; break;
		case "int64": _atom = "Int64"; break;
		case "real": case "number": case "rela":
			_atom = (_r.mode == "spec-return") ? "Double" : "Real";
			break;
		case "string": _atom = "String"; break;
		case "array": {
			// Array.String is the signature database's spelling of Array<String>
			var _element = _arg;
			if (_element == undefined) {
				if (_spec != undefined) {
					_element = gmlc_type_string(_spec, _r.mode);
					if (_element == undefined) return undefined;
				}
				else _element = "Any";
			}
			_atom = "Array<" + _element + ">";
			break;
		}
		case "struct": _atom = (_spec != undefined) ? "Struct." + _spec : "Struct"; break;
		case "pointer": _atom = (_spec != undefined) ? "Pointer." + _spec : "Pointer"; break;
		case "id":
			if (_spec == undefined) _atom = "Unknown";
			else if (_arg != undefined) _atom = "Id." + _spec + "<" + _arg + ">";
			else {
				// Id.Instance.obj_player is Id.Instance<obj_player>
				var _d = string_pos(".", _spec);
				_atom = (_d > 0) ? "Id." + string_copy(_spec, 1, _d - 1) + "<" + string_delete(_spec, 1, _d) + ">" : "Id." + _spec;
			}
			break;
		case "asset": case "resource": _atom = (_spec != undefined) ? "Asset." + _spec : "Asset"; break;
		case "constant":
			if (_spec == undefined) return undefined;
			_atom = (_spec == "Colour") ? "Constant.Color" : "Constant." + _spec;
			break;
		case "enum":
			if (_spec == undefined) return undefined;
			_atom = "Enum." + _spec;
			break;
		case "any": case "mixed": _atom = (_r.mode == "spec-return") ? "Unknown" : "Any"; break;
		case "unknown": case "argumentidentity": _atom = "Unknown"; break;
		default:
			if (_r.raw) && (_arg == undefined) return [_name];
			// the signature database names an enum by its bare name (colspace)
			if (_r.mode == "jsdoc") || (_spec != undefined) || (_arg != undefined) return undefined;
			_atom = "Enum." + _base;
			break;
	}
	if (_arg != undefined) && (_lower != "array") && (_lower != "id") return undefined;
	return [_atom];
}

#region jsDoc
/// @func    __gmlc_type_function(_r)
/// @desc    Function(params)->T after its name; a bare Function takes anything and returns Unknown.
#endregion
function __gmlc_type_function(_r) {
	if (!__gmlc_type_eat(_r, "(")) return "Function(...Any)->Unknown";
	var _params = [];
	if (!__gmlc_type_eat(_r, ")")) {
		while (true) {
			var _rest = __gmlc_type_eat(_r, "...");
			var _members = __gmlc_type_union(_r, false);
			if (_members == undefined) return undefined;
			var _t = __gmlc_type_normalize(_members);
			var _optional = __gmlc_type_eat(_r, "?");
			array_push(_params, (_rest ? "..." : "") + _t + (_optional ? "?" : ""));
			if (__gmlc_type_eat(_r, ")")) break;
			if (!__gmlc_type_eat(_r, ",")) return undefined;
		}
	}
	var _ret = "Unknown";
	if (__gmlc_type_eat(_r, "->")) {
		var _members = __gmlc_type_union(_r, false);
		if (_members == undefined) return undefined;
		_ret = __gmlc_type_normalize(_members);
	}
	return "Function(" + string_join_ext(",", _params) + ")->" + _ret;
}
#endregion

#region Joins
#region jsDoc
/// @func    __gmlc_type_members(_type)
/// @desc    The atoms of a canonical type string, split at its outer `|`.
/// @param   {String} _type : The type
/// @returns {Array<String>}
#endregion
function __gmlc_type_members(_type) {
	var _out = [];
	var _depth = 0;
	var _start = 1;
	var _n = string_length(_type);
	var _i = 1; repeat (_n) {
		var _c = string_char_at(_type, _i);
		if (_c == "<") || (_c == "(") _depth++;
		else if (_c == ")") _depth--;
		else if (_c == ">") && (string_char_at(_type, _i - 1) != "-") _depth--;
		else if (_c == "|") && (_depth == 0) {
			array_push(_out, string_copy(_type, _start, _i - _start));
			_start = _i + 1;
		}
	_i++}
	array_push(_out, string_copy(_type, _start, _n - _start + 1));
	return _out;
}

#region jsDoc
/// @func    gmlc_type_join(_a, _b)
/// @desc    The union of two canonical type strings, normalized.
/// @param   {String} _a : A type
/// @param   {String} _b : A type
/// @returns {String}
#endregion
function gmlc_type_join(_a, _b) {
	if (_a == "Never") return _b;
	if (_b == "Never") return _a;
	return __gmlc_type_normalize(array_concat(__gmlc_type_members(_a), __gmlc_type_members(_b)));
}

#region jsDoc
/// @func    __gmlc_type_remove(_type, _atom)
/// @desc    A type without one atom (Never when nothing is left); Unknown and Any keep it.
#endregion
function __gmlc_type_remove(_type, _atom) {
	var _members = __gmlc_type_members(_type);
	var _kept = [];
	var _i = 0; repeat (array_length(_members)) {
		if (_members[_i] != _atom) array_push(_kept, _members[_i]);
	_i++}
	return __gmlc_type_normalize(_kept);
}
#endregion

#region Flow typing
// A holder (a place a value lives in the points-to analysis) is a string key:
//   l:<file>:<fn_id>:<name>   a local                       i                 the instances
//   <holder>#<name>           a field of a holder's values  <holder>#*        a field by a computed name
//   e:<holder>                the elements of a holder      gl                the global struct
//   n:<file>:<offset>         an array or struct made there c:<name>          a constructor's structs
//   st:<file>:<fn_id>         a function's statics          aa:<key>          a function's argument array
//   r:<name>                  a closed function's returns   g:<name>          a closed function's `self`
//   fn:<name>                 a global function             fb:<name>         a built-in function
//   fl:<file>:<fn_id>         another function literal      m:<name>          a static method
//   mp:<method>:<n>           a method's parameter n        fa:=<name>        the asset a written-out name gives
//   fa:<start>                the assets a computed name starting with <start> may give
//   ?                         anything
#region jsDoc
/// @func    gmlc_type_facts(_ast, _sources)
/// @desc    Assignment-based flow typing of a lowered script: per function, the facts of its `var` locals and
///          parameters where it ends, and its return type, each with its provenance (`annotated` when a JSDoc
///          `@param` type took part, else `proven`). Calls of the script's own functions use their return types, the
///          whole script being typed twice; built-in calls use the signature database.
/// @param   {Struct.ASTScript}        _ast     : A lowered script
/// @param   {Struct.GMLC_SourceTable} _sources : Its files, for the JSDoc comments above functions
/// @returns {Struct} {functions: [{fn_id, name, returns, returns_provenance, locals: [{name, type, provenance, assigned}]}]}
#endregion
function gmlc_type_facts(_ast, _sources) {
	var _run = __gmlc_type_run(_ast, _sources, true, __gmlc_type_batch_empty(), undefined);
	return (_run == undefined) ? undefined : { functions: _run.functions };
}

#region jsDoc
/// @func    gmlc_type_held(_ast, _sources, _batch)
/// @desc    The type each local name of a lowered script holds wherever it is read: its facts joined over every
///          program point of every function that has the name. JSDoc is not read (only proven facts gate an
///          optimization), so a parameter is Unknown, unless the batch types it; a call of a global function of
///          the batch and a field of a whole project have the types the batch gives them.
/// @param   {Struct.ASTScript}        _ast     : A lowered script
/// @param   {Struct.GMLC_SourceTable} _sources : Its files, which tell object event code, or undefined
/// @param   {Struct}                  _batch   : {returns, params, fields} (gmlc_type_batch)
/// @returns {Struct} Local name to its canonical type
#endregion
function gmlc_type_held(_ast, _sources, _batch) {
	var _run = __gmlc_type_run(_ast, _sources, false, _batch, undefined);
	return (_run == undefined) ? {} : _run.held;
}

#region jsDoc
/// @func    gmlc_type_held_elements(_ast, _batch)
/// @desc    What the elements of the arrays each local name of a script (`[]<name>`) and each field name
///          (`[f]<name>`) holds, and what each field of the structs a local holds (`[.]<name>#<field>`), from the
///          objects of a whole project (__gmlc_type_points_to); a name whose arrays' elements are not known is left
///          out.
/// @param   {Struct.ASTScript} _ast   : A lowered script
/// @param   {Struct}           _batch : {arrays, elements, escaped} (gmlc_type_batch)
/// @returns {Struct} Name to its element type
#endregion
function gmlc_type_held_elements(_ast, _batch) {
	var _arrays = _batch.arrays;
	var _elements = _batch.elements;
	var _escaped = _batch.escaped;
	var _prefix = "l:" + string(_ast.span.file) + ":";
	var _out = {};
	// the places of each object
	var _fieldsOf = {};
	var _places = struct_get_names(_elements);
	var _i = 0; repeat (array_length(_places)) {
		var _split = __gmlc_type_split_hash(_places[_i]);
		if (_split != undefined) && (__gmlc_type_is_object(_split[0])) {
			if (!struct_exists(_fieldsOf, _split[0])) _fieldsOf[$ _split[0]] = [];
			array_push(_fieldsOf[$ _split[0]], [_split[1], _elements[$ _places[_i]]]);
		}
	_i++}
	var _holders = struct_get_names(_arrays);
	_i = 0; repeat (array_length(_holders)) {
		var _holder = _holders[_i];
		if (string_starts_with(_holder, _prefix)) {
			var _rest = string_delete(_holder, 1, string_length(_prefix));
			var _colon = string_pos(":", _rest);
			if (_colon > 0) {
				var _name = string_delete(_rest, 1, _colon);
				var _type = __gmlc_type_place_type("e:" + _holder, _arrays, _elements, _escaped) ?? "Unknown";
				_out[$ "[]" + _name] = gmlc_type_join(_out[$ "[]" + _name] ?? "Never", _type);
				// the fields of the structs the local may hold
				var _key = _arrays[$ _holder];
				if (_key != "?") && (_key != "") {
					var _objects = string_split(_key, "|");
					var _o = 0; repeat (array_length(_objects)) {
						// a write by a computed name may be to any field
						var _any = _elements[$ _objects[_o] + "#*"];
						var _fields = _fieldsOf[$ _objects[_o]] ?? [];
						var _f = 0; repeat (array_length(_fields)) {
							var _field = _fields[_f][0];
							if (_field != "*") && (_field != "[]") {
								var _fieldType = struct_exists(_escaped, _objects[_o]) ? "Unknown"
									: ((_any != undefined) ? gmlc_type_join(_fields[_f][1], _any) : _fields[_f][1]);
								var _fieldKey = "[.]" + _name + "#" + _field;
								_out[$ _fieldKey] = gmlc_type_join(_out[$ _fieldKey] ?? "Never", _fieldType);
							}
						_f++}
					_o++}
				}
			}
		}
		else {
			var _hash = __gmlc_type_split_hash(_holder);
			if (_hash != undefined) && (__gmlc_type_is_object(_hash[0])) && (_hash[1] != "*") && (_hash[1] != "[]") {
				var _placeType = __gmlc_type_place_type("e:" + _holder, _arrays, _elements, _escaped) ?? "Unknown";
				_out[$ "[f]" + _hash[1]] = gmlc_type_join(_out[$ "[f]" + _hash[1]] ?? "Never", _placeType);
			}
		}
	_i++}
	return _out;
}

#region jsDoc
/// @func    gmlc_type_batch_returns(_asts)
/// @desc    The return type of every global function of a batch of lowered scripts, a call of one in another file
///          typed by it. A file's types use the map of the round before, so a chain of calls across files gains a
///          link per round; any round's map holds, as a function's return type follows from its own body.
/// @param   {Array<Struct.ASTScript>} _asts : The lowered scripts
/// @returns {Struct} Global function name to its return type
#endregion
function gmlc_type_batch_returns(_asts) {
	var _map = {};
	repeat (4) {
		var _next = {};
		var _a = 0; repeat (array_length(_asts)) {
			var _ast = _asts[_a];
			var _run = __gmlc_type_run(_ast, undefined, false, __gmlc_type_batch_empty(_map), undefined);
			if (_run != undefined) {
				var _f = 0; repeat (array_length(_run.functions)) {
					var _facts = _run.functions[_f];
					var _info = (_facts.fn_id < array_length(_ast.functions)) ? _ast.functions[_facts.fn_id] : undefined;
					if (_info != undefined) && (_info.registration == "global") && (_info.name != undefined) {
						_next[$ _info.name] = _facts.returns;
					}
				_f++}
			}
		_a++}
		if (__gmlc_type_same_names(_map, _next)) break;
		_map = _next;
	}
	return _map;
}

#region jsDoc
/// @func    __gmlc_type_batch_empty([_returns])
/// @desc    A batch that tells the files nothing about each other but, optionally, the return types of its functions.
/// @param   {Struct} [_returns] : Global function name to its return type
/// @returns {Struct} The fields of gmlc_type_batch
#endregion
function __gmlc_type_batch_empty(_returns = {}) {
	return { returns: _returns, params: {}, fields: {}, structs_open: false, arrays: {}, elements: {}, param_holders: {}, methods: {}, self_users: {}, escaped: {} };
}

#region jsDoc
/// @func    gmlc_type_batch(_asts, _sources, _closed, _external)
/// @desc    The return types of the global functions of a batch and, when the batch is a whole project (`_closed`),
///          the parameter types of those whose every call is in it: each parameter holds what its calls pass. The
///          project is typed from no type at all until the types stop changing; when they still change after 24
///          rounds, no parameter is typed and the return types are those of gmlc_type_batch_returns.
/// @param   {Array<Struct.ASTScript>} _asts     : The lowered scripts
/// @param   {Struct.GMLC_SourceTable} _sources  : Their files, or undefined
/// @param   {Bool}                    _closed   : Whether the batch is a whole project
/// @param   {Array<String>}           _external : Function names a resource calls by name
/// @returns {Struct} {returns, params, fields, structs_open, arrays, elements, param_holders, methods, self_users, escaped}:
///          global function name to its return type and to its parameter types, field name to its type, whether structs
///          with any fields are made, the array groups, the parameter holders, the methods, the global functions whose
///          `self` matters, the functions each holder group may hold
#endregion
function gmlc_type_batch(_asts, _sources, _closed, _external) {
	var _open = __gmlc_type_batch_empty(gmlc_type_batch_returns(_asts));
	if (!_closed) return _open;
	var _closedFns = __gmlc_type_closed_functions(_asts, _external, _sources) ?? {};
	var _scanned = __gmlc_type_field_names(_asts, _external);
	var _fieldNames = _scanned.names;
	var _structsOpen = _scanned.structs;
	if (struct_names_count(_closedFns) == 0) && (array_length(_fieldNames) == 0) return _open;
	var _scannedMethods = __gmlc_type_methods(_asts);
	var _methodDefs = _scannedMethods.defs;
	var _selfUsers = __gmlc_type_self_users(_asts);
	var _paramHolders = {};
	// every function literal that is no method, typed by the calls of it (`fl:<file>:<fn_id>`)
	var _la = 0; repeat (array_length(_asts)) {
		__gmlc_type_literal_functions(_asts[_la], _asts[_la].span.file, _methodDefs, _closedFns, _paramHolders);
	_la++}
	var _closedMethods = struct_get_names(_scannedMethods.closed);
	var _m = 0; repeat (array_length(_closedMethods)) {
		var _methodName = _closedMethods[_m];
		var _methodCount = _scannedMethods.closed[$ _methodName];
		_closedFns[$ _methodName] = _methodCount;
		var _methodHolders = [];
		var _mk = 0; repeat (_methodCount) {
			array_push(_methodHolders, "mp:" + string_delete(_methodName, 1, 2) + ":" + string(_mk));
		_mk++}
		_paramHolders[$ _methodName] = _methodHolders;
	_m++}
	var _names = struct_get_names(_closedFns);
	var _pa = 0; repeat (array_length(_asts)) {
		if (_asts[_pa].kind == __GMLC_NodeKind_Script) __gmlc_type_param_places(_asts[_pa], _asts[_pa].span.file, _asts[_pa].functions, _closedFns, _paramHolders);
	_pa++}
	var _batch = { returns: {}, params: {}, fields: {}, structs_open: _structsOpen, arrays: {}, elements: {}, param_holders: _paramHolders, methods: _methodDefs, self_users: _selfUsers, escaped: {} };
	var _n = 0; repeat (array_length(_names)) {
		_batch.params[$ _names[_n]] = array_create(_closedFns[$ _names[_n]], "Never");
	_n++}
	_n = 0; repeat (array_length(_fieldNames)) {
		_batch.fields[$ _fieldNames[_n]] = "Never";
	_n++}
	// the first 8 rounds start from no type and recompute everything from the round before, so what an early round did
	// not know yet does not stay; later rounds join with the round before, so types and groups only grow, and a type
	// that still grows is widened to Unknown: the rounds reach a fixed point
	var _baseFlows = {};
	var _openFlows = {};
	var _allFlows = {};
	var _allElems = {};
	var _e = 0; repeat (array_length(_external)) {
		__gmlc_type_flows_add(_baseFlows, "i#" + _external[_e], "?");
	_e++}
	// the argument array of a function (`aa:<key>`) holds its parameters too: `argument[i]` reads them
	var _aliased = {};
	var _al = 0; repeat (array_length(_asts)) {
		if (_asts[_al].kind == __GMLC_NodeKind_Script) __gmlc_type_argument_functions(_asts[_al], _asts[_al].functions, _aliased);
	_al++}
	var _aliasedNames = struct_get_names(_aliased);
	_al = 0; repeat (array_length(_aliasedNames)) {
		var _aliasedHolders = _paramHolders[$ _aliasedNames[_al]] ?? [];
		var _ah = 0; repeat (array_length(_aliasedHolders)) {
			__gmlc_type_flows_add(_baseFlows, "e:aa:" + _aliasedNames[_al], _aliasedHolders[_ah]);
		_ah++}
	_al++}
	// the functions an asset name may give
	var _assetFlows = __gmlc_type_asset_flows(_asts, _sources);
	_al = 0; repeat (array_length(_assetFlows)) {
		__gmlc_type_flows_add(_baseFlows, _assetFlows[_al][0], _assetFlows[_al][1]);
	_al++}
	_allFlows = {};
	__gmlc_type_flows_merge(_allFlows, _baseFlows);
	var _round = 0; repeat (24) {
		var _sinks = { calls: {}, writes: {}, flows: [], elems: {} };
		var _nextReturns = {};
		var _literalReturns = [];
		var _a = 0; repeat (array_length(_asts)) {
			var _ast = _asts[_a];
			var _run = __gmlc_type_run(_ast, _sources, false, _batch, _sinks);
			if (_run != undefined) {
				var _f = 0; repeat (array_length(_run.functions)) {
					var _facts = _run.functions[_f];
					// a method's return type joins those of the methods of its name
					var _method = _batch.methods[$ string(_ast.span.file) + ":" + string(_facts.fn_id)];
					var _literal = "fl:" + string(_ast.span.file) + ":" + string(_facts.fn_id);
					if (_method != undefined) {
						var _methodKey = "m:" + _method;
						_nextReturns[$ _methodKey] = gmlc_type_join(_nextReturns[$ _methodKey] ?? "Never", _facts.returns);
					}
					else if (struct_exists(_closedFns, _literal)) {
						array_push(_literalReturns, [_literal, _facts.returns]);
					}
					else {
						var _info = (_facts.fn_id < array_length(_ast.functions)) ? _ast.functions[_facts.fn_id] : undefined;
						if (_info != undefined) && (_info.registration == "global") && (_info.name != undefined) {
							_nextReturns[$ _info.name] = __gmlc_type_grow(_batch.returns[$ _info.name], _facts.returns, _round);
						}
					}
				_f++}
			}
		_a++}
		var _returned = struct_get_names(_nextReturns);
		_n = 0; repeat (array_length(_returned)) {
			if (string_starts_with(_returned[_n], "m:")) _nextReturns[$ _returned[_n]] = __gmlc_type_grow(_batch.returns[$ _returned[_n]], _nextReturns[$ _returned[_n]], _round);
		_n++}
		_n = 0; repeat (array_length(_literalReturns)) {
			_nextReturns[$ _literalReturns[_n][0]] = __gmlc_type_grow(_batch.returns[$ _literalReturns[_n][0]], _literalReturns[_n][1], _round);
		_n++}
		var _nextParams = {};
		_n = 0; repeat (array_length(_names)) {
			var _types = _sinks.calls[$ _names[_n]] ?? array_create(_closedFns[$ _names[_n]], "Never");
			var _prev = _batch.params[$ _names[_n]];
			var _grown = array_create(array_length(_types));
			var _k = 0; repeat (array_length(_types)) {
				_grown[_k] = __gmlc_type_grow(((_prev != undefined) && (_k < array_length(_prev))) ? _prev[_k] : undefined, _types[_k], _round);
			_k++}
			_nextParams[$ _names[_n]] = _grown;
		_n++}
		// the writes by a computed name are kept by owner class (`*`, `*inst`, `*lit`, `*C:<name>`): a read joins them
		var _nextFields = {};
		_n = 0; repeat (array_length(_fieldNames)) {
			if (string_char_at(_fieldNames[_n], 1) != "*") {
				_nextFields[$ _fieldNames[_n]] = __gmlc_type_grow(_batch.fields[$ _fieldNames[_n]], _sinks.writes[$ _fieldNames[_n]] ?? "Never", _round);
			}
		_n++}
		var _written = struct_get_names(_sinks.writes);
		_n = 0; repeat (array_length(_written)) {
			if (string_char_at(_written[_n], 1) == "*") _nextFields[$ _written[_n]] = __gmlc_type_grow(_batch.fields[$ _written[_n]], _sinks.writes[$ _written[_n]], _round);
		_n++}
		if (_round < 8) {
			_allFlows = {};
			__gmlc_type_flows_merge(_allFlows, _baseFlows);
			_allElems = {};
		}
		__gmlc_type_flows_merge(_allFlows, _openFlows);
		_n = 0; repeat (array_length(_sinks.flows)) {
			var _pair = _sinks.flows[_n];
			__gmlc_type_flows_add(_allFlows, _pair[0], _pair[1]);
		_n++}
		var _elemHolders = struct_get_names(_sinks.elems);
		_n = 0; repeat (array_length(_elemHolders)) {
			_allElems[$ _elemHolders[_n]] = __gmlc_type_grow(_allElems[$ _elemHolders[_n]], _sinks.elems[$ _elemHolders[_n]], _round);
		_n++}
		var _flowList = [];
		var _from = struct_get_names(_allFlows);
		_n = 0; repeat (array_length(_from)) {
			var _to = struct_get_names(_allFlows[$ _from[_n]]);
			var _t = 0; repeat (array_length(_to)) {
				array_push(_flowList, [_from[_n], _to[_t]]);
			_t++}
		_n++}
		var _nextGroups = __gmlc_type_points_to(_flowList, _allElems);
		// the functions whose value reaches code the typing does not follow: their parameters may be anything, their
		// `self` too for a global function, and what they return goes there
		var _openFns = {};
		var _escapedNames = struct_get_names(_nextGroups.escaped);
		var _gh = 0; repeat (array_length(_escapedNames)) {
			var _holder = _escapedNames[_gh];
			var _openKey = undefined;
			if (string_starts_with(_holder, "fn:")) _openKey = string_delete(_holder, 1, 3);
			else if (string_starts_with(_holder, "fl:")) {
				var _literalMethod = _methodDefs[$ string_delete(_holder, 1, 3)];
				_openKey = (_literalMethod != undefined) ? "m:" + _literalMethod : _holder;
			}
			if (_openKey != undefined) _openFns[$ _openKey] = true;
		_gh++}
		_openFlows = {};
		var _openKeys = struct_get_names(_openFns);
		_gh = 0; repeat (array_length(_openKeys)) {
			var _openFn = _openKeys[_gh];
			if (struct_exists(_closedFns, _openFn)) {
				var _openHolders = _paramHolders[$ _openFn] ?? [];
				var _oh = 0; repeat (array_length(_openHolders)) {
					__gmlc_type_flows_add(_openFlows, _openHolders[_oh], "?");
				_oh++}
				__gmlc_type_flows_add(_openFlows, "r:" + _openFn, "?");
				__gmlc_type_flows_add(_openFlows, "?", "r:" + _openFn);
				if (!string_starts_with(_openFn, "m:")) && (!string_starts_with(_openFn, "fl:")) && (struct_exists(_selfUsers, _openFn)) {
					__gmlc_type_flows_add(_openFlows, "g:" + _openFn, "?");
				}
			}
		_gh++}
		_n = 0; repeat (array_length(_names)) {
			if (struct_exists(_openFns, _names[_n])) _nextParams[$ _names[_n]] = array_create(array_length(_nextParams[$ _names[_n]]), "Unknown");
		_n++}
		if (__gmlc_type_same_names(_nextReturns, _batch.returns)) && (__gmlc_type_same_params(_nextParams, _batch.params))
			&& (__gmlc_type_same_names(_nextFields, _batch.fields)) && (__gmlc_type_same_names(_nextGroups.arrays, _batch.arrays))
			&& (__gmlc_type_same_names(_nextGroups.elements, _batch.elements)) && (__gmlc_type_same_names(_nextGroups.escaped, _batch.escaped)) {
			return _batch;
		}
		_batch = { returns: _nextReturns, params: _nextParams, fields: _nextFields, structs_open: _structsOpen,
			arrays: _nextGroups.arrays, elements: _nextGroups.elements, param_holders: _paramHolders, methods: _methodDefs, self_users: _selfUsers, escaped: _nextGroups.escaped };
	_round++}
	return _open;
}

#region jsDoc
/// @func    __gmlc_type_flows_add(_flows, _a, _b)
/// @desc    Adds a flow between two holders to a set of flows.
/// @param   {Struct} _flows : Holder to the holders it flows with, added to
/// @param   {String} _a     : A holder
/// @param   {String} _b     : A holder
#endregion
function __gmlc_type_flows_add(_flows, _a, _b) {
	if (!struct_exists(_flows, _a)) _flows[$ _a] = {};
	_flows[$ _a][$ _b] = true;
}

#region jsDoc
/// @func    __gmlc_type_flows_merge(_into, _from)
/// @desc    Adds the flows of a set of flows to another.
/// @param   {Struct} _into : The set added to
/// @param   {Struct} _from : The set added
#endregion
function __gmlc_type_flows_merge(_into, _from) {
	var _holders = struct_get_names(_from);
	var _i = 0; repeat (array_length(_holders)) {
		var _targets = struct_get_names(_from[$ _holders[_i]]);
		var _t = 0; repeat (array_length(_targets)) {
			__gmlc_type_flows_add(_into, _holders[_i], _targets[_t]);
		_t++}
	_i++}
}

#region jsDoc
/// @func    __gmlc_type_grow(_prev, _next, _round)
/// @desc    A type of a round: as the round found it in the first 8 rounds, then joined with the round before, and
///          Unknown where it still grows.
/// @param   {String|Undefined} _prev  : The type of the round before, or undefined for none
/// @param   {String}           _next  : The type of this round
/// @param   {Real}             _round : The round, counted from 0
/// @returns {String}
#endregion
function __gmlc_type_grow(_prev, _next, _round) {
	if (_prev == undefined) || (_round < 8) return _next;
	var _joined = gmlc_type_join(_prev, _next);
	return (_joined != _prev) ? "Unknown" : _joined;
}

#region jsDoc
/// @func    __gmlc_type_methods(_asts)
/// @desc    The methods of a whole project by name: every function literal stored in a field (`static m = function`,
///          `self.m = function`, `{m: function}`) under that name, `<file>:<fn_id>` to the name, and the names only the
///          project's own calls reach (`x.m(...)`, `m(...)` through `self`) with their most parameters.
/// @param   {Array<Struct.ASTScript>} _asts : The lowered scripts
/// @returns {Struct} {defs, closed}: `<file>:<fn_id>` to the name, `m:<name>` to the most parameters of its methods
#endregion
function __gmlc_type_methods(_asts) {
	var _scan = { defs: {}, counts: {}, escaped: {}, computed_reads: false, value_calls: false };
	var _a = 0; repeat (array_length(_asts)) {
		__gmlc_type_walk_methods(_asts[_a], _asts[_a].span.file, 0, _scan);
	_a++}
	// a method value read or called by value is followed like any function value (`__gmlc_type_call_targets`): a method is
	// open only where its value reaches code the typing does not follow
	var _closed = {};
	var _names = struct_get_names(_scan.counts);
	var _i = 0; repeat (array_length(_names)) {
		_closed[$ "m:" + _names[_i]] = _scan.counts[$ _names[_i]];
	_i++}
	return { defs: _scan.defs, closed: _closed };
}

#region jsDoc
/// @func    __gmlc_type_define_method(_name, _value, _file, _scan)
/// @desc    Records a function literal stored in a field.
/// @param   {String}         _name  : The field
/// @param   {Struct.ASTNode} _value : The stored value
/// @param   {Real}           _file  : The file's id
/// @param   {Struct}         _scan  : The scan of __gmlc_type_methods
#endregion
function __gmlc_type_define_method(_name, _value, _file, _scan) {
	if (_value.kind == __GMLC_NodeKind_FunctionExpr) && (!_value.is_constructor) && (_value.fn_id != undefined) {
		_scan.defs[$ string(_file) + ":" + string(_value.fn_id)] = _name;
		_scan.counts[$ _name] = max(_scan.counts[$ _name] ?? 0, array_length(_value.params));
	}
}

#region jsDoc
/// @func    __gmlc_type_walk_methods(_node, _file, _role, _scan)
/// @desc    Scans a node for the methods it defines and the names it lets escape.
/// @param   {Struct.ASTNode} _node : The node
/// @param   {Real}           _file : The file's id
/// @param   {Real}           _role : 0 a value, 1 a direct call's callee, 2 an assignment's target
/// @param   {Struct}         _scan : The scan of __gmlc_type_methods
#endregion
function __gmlc_type_walk_methods(_node, _file, _role, _scan) {
	switch (_node.kind) {
		case __GMLC_NodeKind_VarDecl:
			if (_node.target.kind == __GMLC_NodeKind_Identifier) && (_node.init != undefined) && (_node.target.symbol != undefined) && (_node.target.symbol.kind == "Static") {
				__gmlc_type_define_method(_node.target.name, _node.init, _file, _scan);
			}
			__gmlc_type_walk_methods(_node.target, _file, 2, _scan);
			if (_node.init != undefined) __gmlc_type_walk_methods(_node.init, _file, 0, _scan);
			return;
		case __GMLC_NodeKind_Assign:
			if (_node.op == "=") {
				var _target = _node.target;
				if (_target.kind == __GMLC_NodeKind_Identifier) {
					if (_target.symbol != undefined) && ((_target.symbol.kind == "Self") || (_target.symbol.kind == "Static")) __gmlc_type_define_method(_target.name, _node.value, _file, _scan);
				}
				else if (_target.kind == __GMLC_NodeKind_Index) && (_target.accessor == "Dot") {
					if (_target.member != undefined) __gmlc_type_define_method(_target.member, _node.value, _file, _scan);
				}
			}
			__gmlc_type_walk_methods(_node.target, _file, 2, _scan);
			__gmlc_type_walk_methods(_node.value, _file, 0, _scan);
			return;
		case __GMLC_NodeKind_StructEntry:
			__gmlc_type_define_method(_node.key, _node.value, _file, _scan);
			break;
		case __GMLC_NodeKind_Identifier:
			if (_role == 0) && (_node.symbol != undefined) && ((_node.symbol.kind == "Self") || (_node.symbol.kind == "Static")) _scan.escaped[$ _node.name] = true;
			return;
		case __GMLC_NodeKind_Index:
			if (_role == 0) {
				if (_node.accessor == "Dot") {
					if (_node.member != undefined) _scan.escaped[$ _node.member] = true;
				}
				else if (_node.accessor == "Struct") {
					var _field = __gmlc_type_field_of(_node);
					if (_field == undefined) || (_field.name == "*") _scan.computed_reads = true;
				}
			}
			__gmlc_type_walk_methods(_node.object, _file, 0, _scan);
			var _k = 0; repeat (array_length(_node.keys)) {
				__gmlc_type_walk_methods(_node.keys[_k], _file, 0, _scan);
			_k++}
			return;
		case __GMLC_NodeKind_Call:
			var _callee = _node.callee;
			if (_callee.kind == __GMLC_NodeKind_Identifier) {
				var _symbol = _callee.symbol;
				if (_symbol != undefined) && (_symbol.kind == "Local") _scan.value_calls = true;
				if (_symbol != undefined) && (_symbol.kind == "BuiltinFunction") {
					switch (_callee.name) {
						case "variable_struct_get": case "struct_get": case "variable_instance_get": case "struct_foreach":
						case "variable_struct_get_names": case "struct_get_names":
							_scan.computed_reads = true;
							break;
						case "script_execute": case "script_execute_ext": case "method_call":
							_scan.value_calls = true;
							break;
					}
				}
				__gmlc_type_walk_methods(_callee, _file, 1, _scan);
			}
			else {
				_scan.value_calls = true;
				__gmlc_type_walk_methods(_callee, _file, 0, _scan);
			}
			var _c = 0; repeat (array_length(_node.args)) {
				__gmlc_type_walk_methods(_node.args[_c], _file, 0, _scan);
			_c++}
			return;
		case __GMLC_NodeKind_MethodCall:
			__gmlc_type_walk_methods(_node.object, _file, 0, _scan);
			var _m = 0; repeat (array_length(_node.args)) {
				__gmlc_type_walk_methods(_node.args[_m], _file, 0, _scan);
			_m++}
			return;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_walk_methods(_child, _file, 0, _scan);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_field_names(_asts, _external)
/// @desc    The field names of a whole project whose every write is in its code: a name written as an instance
///          variable, a struct field, a static, through `global` or by `variable_*_set` with a written-out name, that
///          no name a resource calls by (`_external`, object variable definitions) and that is no built-in
///          variable; `*` stands for a write by a computed name. The keys of ds_maps are analyzed the same way, as
///          `?key`: none when a key may be written by a computed name or a built-in fills a map (`json_decode`,
///          `async_load`, ...). `structs` is true when structs with any fields are made (`json_parse`,
///          `struct_set_from_hash`, a built-in returning a struct whose fields its data does not list): a field read
///          then has the field's type only where it surely reads an instance or a constructor's struct.
/// @param   {Array<Struct.ASTScript>} _asts     : The lowered scripts
/// @param   {Array<String>}           _external : Names a resource that is no code mentions
/// @returns {Struct} {names, structs}: the names, sorted
#endregion
function __gmlc_type_field_names(_asts, _external) {
	var _scan = { names: {}, all: false, structs: false, builtin_structs: false, catches: false };
	var _a = 0; repeat (array_length(_asts)) {
		__gmlc_type_written_fields(_asts[_a], false, _scan);
	_a++}
	var _names = _scan.names;
	// a ds_map key is kept as `?key`; `?` alone stands for a key written by a computed name or by a built-in
	var _maps = !struct_exists(_names, "?");
	// the fields of a built-in's struct (`sprite_get_info(s).width`, a caught exception's `message`) are not the code's
	static __exception = ["message", "longMessage", "script", "line", "stacktrace"];
	if (_scan.catches) {
		var _x = 0; repeat (array_length(__exception)) {
			if (struct_exists(_names, __exception[_x])) struct_remove(_names, __exception[_x]);
		_x++}
	}
	var _e = 0; repeat (array_length(_external)) {
		if (struct_exists(_names, _external[_e])) struct_remove(_names, _external[_e]);
	_e++}
	// the values of the other ds containers are kept by kind; `<kind>!` stands for writes the typing does not see
	var _kinds = __gmlc_type_ds_kinds();
	var _unseen = {};
	var _d = 0; repeat (array_length(_kinds)) {
		if (struct_exists(_names, _kinds[_d] + "!")) {
			_unseen[$ _kinds[_d]] = true;
			struct_remove(_names, _kinds[_d] + "!");
		}
		if (struct_exists(_names, _kinds[_d])) struct_remove(_names, _kinds[_d]);
	_d++}
	_d = 0; repeat (array_length(_kinds)) {
		if (!struct_exists(_unseen, _kinds[_d])) _names[$ _kinds[_d]] = true;
	_d++}
	var _out = [];
	var _keys = struct_get_names(_names);
	array_sort(_keys, true);
	var _k = 0; repeat (array_length(_keys)) {
		if (string_char_at(_keys[_k], 1) == "?") {
			if (_maps) array_push(_out, _keys[_k]);
		}
		else if (string_char_at(_keys[_k], 1) == "|") {
			array_push(_out, _keys[_k]);
		}
		else if (!_scan.all) && (__gmlc_opt_builtin_variable(_keys[_k]) == undefined) && ((!_scan.builtin_structs) || (!__gmlc_opt_builtin_struct_field(_keys[_k]))) {
			array_push(_out, _keys[_k]);
		}
	_k++}
	return { names: _out, structs: _scan.structs };
}

#region jsDoc
/// @func    __gmlc_type_written_fields(_node, _callee, _scan)
/// @desc    Adds the field names a node writes to `_scan`; sets `_scan.all` when a setter is used other than as a
///          direct call, and `_scan.structs` when a struct with any fields is made (`json_parse`,
///          `struct_set_from_hash`, a built-in returning a struct whose fields its data does not list).
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {Bool}           _callee : Whether the node is a direct call's callee
/// @param   {Struct}         _scan   : {names, all, structs, builtin_structs, catches}
#endregion
function __gmlc_type_written_fields(_node, _callee, _scan) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Identifier:
			var _kind = (_node.symbol != undefined) ? _node.symbol.kind : undefined;
			if ((_kind == "BuiltinFunction") && (__gmlc_type_map_source(_node.name)))
			|| ((_kind == "BuiltinFunction") && (!_callee) && (__gmlc_type_map_setter(_node.name)))
			|| ((_kind == "BuiltinVar") && ((_node.name == "async_load") || (_node.name == "event_data"))) {
				_scan.names[$ "?"] = true;
			}
			if (!_callee) && (_kind == "BuiltinFunction") {
				switch (_node.name) {
					case "variable_instance_set": case "variable_struct_set": case "struct_set": case "variable_global_set":
						_scan.all = true;
						break;
				}
			}
			if (_kind == "BuiltinFunction") && ((_node.name == "json_parse") || (_node.name == "struct_set_from_hash")) _scan.structs = true;
			if (_kind == "BuiltinFunction") && (!_callee) {
				var _writer = __gmlc_type_ds_writer(_node.name);
				if (_writer != undefined) _scan.names[$ _writer.kind + "!"] = true;
			}
			return;
		case __GMLC_NodeKind_Assign: case __GMLC_NodeKind_Update:
			var _target = (_node.kind == __GMLC_NodeKind_Assign) ? _node.target : _node.argument;
			var _field = __gmlc_type_field_of(_target);
			if (_field != undefined) _scan.names[$ _field.name] = true;
			break;
		case __GMLC_NodeKind_VarDecl:
			var _decl = __gmlc_type_field_of(_node.target);
			if (_decl != undefined) _scan.names[$ _decl.name] = true;
			break;
		case __GMLC_NodeKind_StructEntry:
			_scan.names[$ _node.key] = true;
			break;
		case __GMLC_NodeKind_Try:
			if (_node.catch_param != undefined) _scan.catches = true;
			break;
		case __GMLC_NodeKind_Call:
			var _set = __gmlc_type_setter(_node);
			if (_set != undefined) _scan.names[$ _set.name] = true;
			var _fn = _node.callee;
			if (_fn.kind == __GMLC_NodeKind_Identifier) && (_fn.symbol != undefined) && (_fn.symbol.kind == "BuiltinFunction") {
				switch (_fn.name) {
					case "json_parse": case "struct_set_from_hash": _scan.structs = true; break;
					// these give back a struct the code made
					case "static_get": case "method_get_self": break;
					default:
						var _builtins = __gmlc_type_builtins();
						var _returns = _builtins[$ _fn.name] ?? "";
						if (_returns == "Struct") _scan.structs = true;
						else if (string_starts_with(_returns, "Struct.")) {
							if (__gmlc_opt_builtin_structure(string_delete(_returns, 1, 7))) _scan.builtin_structs = true;
							else _scan.structs = true;
						}
						break;
				}
			}
			__gmlc_type_written_fields(_fn, true, _scan);
			var _a = 0; repeat (array_length(_node.args)) {
				__gmlc_type_written_fields(_node.args[_a], false, _scan);
			_a++}
			return;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_written_fields(_child, false, _scan);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_field_of(_target)
/// @desc    The field a write target names: {name} for an instance variable, a static or a global variable by
///          name, `x.name` and `x[$ "name"]`; {name: "*"} for `x[$ key]` with a computed key; {name: "?key"}
///          for `m[? "key"]` and {name: "?"} for `m[? key]` with a key that is no string; undefined for a local or no
///          field.
/// @param   {Struct.ASTNode} _target : The target
/// @returns {Struct|Undefined}
#endregion
function __gmlc_type_field_of(_target) {
	switch (_target.kind) {
		case __GMLC_NodeKind_Identifier:
			var _kind = (_target.symbol != undefined) ? _target.symbol.kind : undefined;
			if (_kind == undefined) || (_kind == "Self") || (_kind == "Static") || (_kind == "Global") return { name: _target.name };
			return undefined;
		case __GMLC_NodeKind_Index:
			if (_target.accessor == "Dot") return (_target.member != undefined) ? { name: _target.member } : undefined;
			if (_target.accessor == "Struct") {
				var _key = (array_length(_target.keys) > 0) ? _target.keys[0] : undefined;
				if (_key != undefined) && (_key.kind == __GMLC_NodeKind_Literal) && (_key.ty == "string") return { name: _key.value };
				return { name: "*" };
			}
			if (_target.accessor == "Map") return { name: __gmlc_type_map_key((array_length(_target.keys) > 0) ? _target.keys[0] : undefined) };
			if (_target.accessor == "List") return { name: "|list" };
			if (_target.accessor == "Grid") return { name: "|grid" };
			return undefined;
	}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_type_buffer_type(_node)
/// @desc    The type `buffer_read` gives for a buffer type constant on the VM:
///          a number for the float types, a string for `buffer_string`
///          and `buffer_text`; undefined for the integer types, which give int32 values the type engine does not
///          model.
/// @param   {Struct.ASTNode} _node : The type argument
/// @returns {String|Undefined}
#endregion
function __gmlc_type_buffer_type(_node) {
	if (_node.kind != __GMLC_NodeKind_Identifier) || (_node.symbol == undefined) || (_node.symbol.kind != "BuiltinConstant") return undefined;
	switch (_node.name) {
		case "buffer_f16": case "buffer_f32": case "buffer_f64": return "Real";
		case "buffer_string": case "buffer_text": return "String";
	}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_type_made_by_code(_node, _state, _cx)
/// @desc    Whether a value is surely an instance or a struct a constructor made, never a parsed struct: an object's
///          name, `other` or `self` in object event code outside `with`, or a value of type `Struct.<constructor>`.
/// @param   {Struct.ASTNode} _node  : The value
/// @param   {Struct}         _state : The local facts
/// @param   {Struct}         _cx    : The typing context
/// @returns {Bool}
#endregion
function __gmlc_type_made_by_code(_node, _state, _cx) {
	if (_node.kind == __GMLC_NodeKind_Identifier) && (_node.symbol != undefined) {
		if (_node.symbol.kind == "Asset") return true;
		if ((_node.symbol.kind == "BuiltinVar") || (_node.symbol.kind == "BuiltinConstant")) && ((_node.name == "other") || (_node.name == "self")) return _cx.self_instance;
	}
	var _t = __gmlc_type_of(_node, _state, _cx);
	if (_t.provenance != "proven") || (!string_starts_with(_t.type, "Struct.")) return false;
	var _name = string_delete(_t.type, 1, 7);
	return (!__gmlc_type_builtin_struct_type(_name)) && (!__gmlc_opt_builtin_structure(_name));
}

#region jsDoc
/// @func    __gmlc_type_builtin_struct_type(_name)
/// @desc    Whether `Struct.<name>` is the type of a struct a built-in returns (`Struct.SpriteInfo`), not a
///          constructor's.
/// @param   {String} _name : The struct's name
/// @returns {Bool}
#endregion
function __gmlc_type_builtin_struct_type(_name) {
	static __names = undefined;
	if (__names == undefined) {
		__names = {};
		var _builtins = __gmlc_type_builtins();
		var _keys = struct_get_names(_builtins);
		var _i = 0; repeat (array_length(_keys)) {
			var _returns = _builtins[$ _keys[_i]];
			if (is_string(_returns)) && (string_starts_with(_returns, "Struct.")) __names[$ string_delete(_returns, 1, 7)] = true;
		_i++}
	}
	return struct_exists(__names, _name);
}

#region jsDoc
/// @func    __gmlc_type_map_key(_key)
/// @desc    The name a ds_map key is kept under: `?key` for a string literal, `?` for anything else.
/// @param   {Struct.ASTNode|Undefined} _key : The key
/// @returns {String}
#endregion
function __gmlc_type_map_key(_key) {
	if (_key != undefined) && (_key.kind == __GMLC_NodeKind_Literal) && (_key.ty == "string") return "?" + _key.value;
	return "?";
}

#region jsDoc
/// @func    __gmlc_type_ds_kinds()
/// @desc    The names the values of ds containers other than maps are kept under, one per kind.
/// @returns {Array<String>}
#endregion
function __gmlc_type_ds_kinds() {
	static __kinds = ["|list", "|grid", "|stack", "|queue", "|priority"];
	return __kinds;
}

#region jsDoc
/// @func    __gmlc_type_ds_writer(_name)
/// @desc    A built-in that writes values into a ds container other than a map: the kind's name, the index of the
///          first argument it writes and whether every argument after it is written too; undefined for any other.
/// @param   {String} _name : The built-in
/// @returns {Struct|Undefined}
#endregion
function __gmlc_type_ds_writer(_name) {
	switch (_name) {
		case "ds_list_add": return { kind: "|list", from: 1, more: true };
		case "ds_list_insert": case "ds_list_replace": return { kind: "|list", from: 2, more: false };
		case "ds_list_set": return { kind: "|list", from: 2, more: true };
		case "ds_grid_set": case "ds_grid_add": case "ds_grid_multiply": return { kind: "|grid", from: 3, more: false };
		case "ds_grid_set_disk": case "ds_grid_add_disk": case "ds_grid_multiply_disk": return { kind: "|grid", from: 4, more: false };
		case "ds_grid_set_region": case "ds_grid_add_region": case "ds_grid_multiply_region": return { kind: "|grid", from: 5, more: false };
		case "ds_grid_clear": return { kind: "|grid", from: 1, more: false };
		case "ds_stack_push": return { kind: "|stack", from: 1, more: true };
		case "ds_queue_enqueue": return { kind: "|queue", from: 1, more: true };
		case "ds_priority_add": return { kind: "|priority", from: 1, more: false };
	}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_type_ds_fill(_name)
/// @desc    A built-in that fills a ds container with values of a type of its own: the kind's name and the type,
///          Unknown for data the runtime reads (`json_decode` makes lists, `ds_grid_read`, `load_csv`).
/// @param   {String} _name : The built-in
/// @returns {Struct|Undefined}
#endregion
function __gmlc_type_ds_fill(_name) {
	switch (_name) {
		// the cells of a new or grown grid are 0, and so are the cells a list write past its end adds
		case "ds_grid_create": case "ds_grid_resize": case "mp_grid_to_ds_grid": return { kind: "|grid", type: "Real" };
		case "ds_list_set": return { kind: "|list", type: "Real" };
		case "instance_place_list": case "instance_position_list": case "collision_point_list": case "collision_line_list":
		case "collision_rectangle_list": case "collision_circle_list": case "collision_ellipse_list":
			return { kind: "|list", type: "Id.Instance" };
		case "json_decode": case "ds_list_read": case "ds_map_read": case "ds_map_secure_load": case "ds_map_secure_load_buffer":
		case "skeleton_animation_list": case "skeleton_skin_list": case "skeleton_slot_list": case "skeleton_slot_data":
		case "skeleton_slot_data_instance": case "skeleton_find_slot": case "iap_enumerate_products":
			return { kind: "|list", type: "Unknown" };
		case "ds_grid_read": case "load_csv": return { kind: "|grid", type: "Unknown" };
		case "ds_stack_read": return { kind: "|stack", type: "Unknown" };
		case "ds_queue_read": return { kind: "|queue", type: "Unknown" };
		case "ds_priority_read": return { kind: "|priority", type: "Unknown" };
	}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_type_ds_param(_name)
/// @desc    The index of the first parameter of a built-in that takes a ds container, from its data.
/// @param   {String} _name : The built-in
/// @returns {Real|Undefined}
#endregion
function __gmlc_type_ds_param(_name) {
	var _signature = __gmlc_opt_builtin_function(_name);
	if (_signature == undefined) return undefined;
	var _i = 0; repeat (array_length(_signature.parameters)) {
		if (string_starts_with(_signature.parameters[_i].type, "Id.Ds")) return _i;
	_i++}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_type_ds_copy(_name)
/// @desc    A built-in that copies the values of one ds container into another: the indices of the target and the
///          source.
/// @param   {String} _name : The built-in
/// @returns {Array<Real>|Undefined}
#endregion
function __gmlc_type_ds_copy(_name) {
	switch (_name) {
		case "ds_list_copy": case "ds_map_copy": case "ds_grid_copy": case "ds_stack_copy": case "ds_queue_copy": case "ds_priority_copy":
		case "ds_grid_set_grid_region": case "ds_grid_add_grid_region": case "ds_grid_multiply_grid_region":
			return [0, 1];
	}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_type_container(_args, _k, _state, _cx)
/// @desc    The elements of the ds container an argument holds: `e:<holder>`, `?` for a container of unknown holder.
/// @param   {Array<Struct.ASTNode>} _args  : The arguments
/// @param   {Real}                  _k     : The argument
/// @param   {Struct}                _state : The local facts
/// @param   {Struct}                _cx    : The typing context
/// @returns {String|Undefined}
#endregion
function __gmlc_type_container(_args, _k, _state, _cx) {
	if (_k >= array_length(_args)) return undefined;
	var _h = __gmlc_type_holder_of(_args[_k], _state, _cx);
	if (_h == undefined) return undefined;
	return (_h == "?") ? _h : "e:" + _h;
}

#region jsDoc
/// @func    __gmlc_type_ds_reader(_name)
/// @desc    A built-in that reads a value of a ds container other than a map: the kind's name; it gives undefined
///          where there is no such value.
/// @param   {String} _name : The built-in
/// @returns {String|Undefined}
#endregion
function __gmlc_type_ds_reader(_name) {
	switch (_name) {
		case "ds_list_find_value": return "|list";
		case "ds_grid_get": return "|grid";
		case "ds_stack_pop": case "ds_stack_top": return "|stack";
		case "ds_queue_dequeue": case "ds_queue_head": case "ds_queue_tail": return "|queue";
		case "ds_priority_find_max": case "ds_priority_find_min": case "ds_priority_delete_max": case "ds_priority_delete_min":
			return "|priority";
	}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_type_map_setter(_name)
/// @desc    Whether a built-in writes one key of a ds_map: its key is argument 1, its value argument 2.
/// @param   {String} _name : The built-in
/// @returns {Bool}
#endregion
function __gmlc_type_map_setter(_name) {
	switch (_name) {
		case "ds_map_add": case "ds_map_set": case "ds_map_replace": case "ds_map_add_list": case "ds_map_add_map":
		case "ds_map_replace_list": case "ds_map_replace_map":
			return true;
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_type_map_source(_name)
/// @desc    Whether a built-in makes or fills a ds_map with keys the code does not write.
/// @param   {String} _name : The built-in
/// @returns {Bool}
#endregion
function __gmlc_type_map_source(_name) {
	switch (_name) {
		case "json_decode": case "ds_map_read": case "ds_map_secure_load": case "ds_map_secure_load_buffer":
		case "os_get_info": case "gpu_get_state": case "audio_get_listener_info": case "audio_listener_get_data":
		case "skeleton_bone_data_get": case "skeleton_bone_state_get": case "skeleton_bone_list": case "iap_product_details":
			return true;
	}
	return false;
}

#region jsDoc
/// @func    __gmlc_type_setter(_node)
/// @desc    A call of `variable_instance_set`, `variable_struct_set`, `struct_set` or `variable_global_set`:
///          {name, value} (the value's argument index) when the name is written out, {name: "*", value} when it is
///          computed, undefined for any other call; a call that writes a ds_map key gives the key's
///          __gmlc_type_map_key.
/// @param   {Struct.ASTNode} _node : The call
/// @returns {Struct|Undefined}
#endregion
function __gmlc_type_setter(_node) {
	var _callee = _node.callee;
	if (_callee.kind != __GMLC_NodeKind_Identifier) || (_callee.symbol == undefined) || (_callee.symbol.kind != "BuiltinFunction") return undefined;
	if (__gmlc_type_map_setter(_callee.name)) return { name: __gmlc_type_map_key((array_length(_node.args) > 1) ? _node.args[1] : undefined), value: 2 };
	var _keyIndex, _valueIndex;
	switch (_callee.name) {
		case "variable_instance_set": case "variable_struct_set": case "struct_set": _keyIndex = 1; _valueIndex = 2; break;
		case "variable_global_set": _keyIndex = 0; _valueIndex = 1; break;
		default: return undefined;
	}
	var _key = (_keyIndex < array_length(_node.args)) ? _node.args[_keyIndex] : undefined;
	if (_key != undefined) && (_key.kind == __GMLC_NodeKind_Literal) && (_key.ty == "string") return { name: _key.value, value: _valueIndex };
	return { name: "*", value: _valueIndex };
}

#region jsDoc
/// @func    __gmlc_type_field_now(_name, _cx)
/// @desc    What a field holds before a compound write: its type, or for a write by a computed name (`*`) what any
///          field of a struct or instance holds.
/// @param   {String} _name : The field
/// @param   {Struct} _cx   : The typing context
/// @returns {String}
#endregion
function __gmlc_type_field_now(_name, _cx) {
	if (string_char_at(_name, 1) != "*") return __gmlc_type_field_read(_name, "", _cx);
	var _type = "Never";
	var _names = struct_get_names(_cx.fields);
	var _i = 0; repeat (array_length(_names)) {
		if (string_char_at(_names[_i], 1) != "?") _type = gmlc_type_join(_type, _cx.fields[$ _names[_i]]);
	_i++}
	return _type;
}

#region jsDoc
/// @func    __gmlc_type_owner_class(_owner, _state, _cx)
/// @desc    Which structs or instances a field access may reach, for the writes by a computed name: `inst` an
///          instance, `lit` a struct a literal made, `C:<name>` a struct the constructor `<name>` made, an empty name
///          any.
/// @param   {Struct.ASTNode} _owner : The owner
/// @param   {Struct}         _state : The local facts
/// @param   {Struct}         _cx    : The typing context
/// @returns {String}
#endregion
function __gmlc_type_owner_class(_owner, _state, _cx) {
	if (_owner.kind == __GMLC_NodeKind_Identifier) && (_owner.symbol != undefined) {
		if (_owner.symbol.kind == "Asset") return "inst";
		if ((_owner.symbol.kind == "BuiltinVar") || (_owner.symbol.kind == "BuiltinConstant")) && ((_owner.name == "other") || (_owner.name == "self")) {
			return _cx.self_instance ? "inst" : "";
		}
	}
	var _t = __gmlc_type_of(_owner, _state, _cx);
	if (_t.provenance != "proven") return "";
	if (_t.type == "Struct") return "lit";
	if (!string_starts_with(_t.type, "Struct.")) return "";
	var _name = string_delete(_t.type, 1, 7);
	if (string_pos("|", _name) > 0) || (__gmlc_type_builtin_struct_type(_name)) || (__gmlc_opt_builtin_structure(_name)) return "";
	return "C:" + _name;
}

#region jsDoc
/// @func    __gmlc_type_wildcard_key(_name, _target, _state, _cx)
/// @desc    The key a field write records under: its name, or for a write by a computed name `*<owner class>`.
/// @param   {String}         _name   : The field
/// @param   {Struct.ASTNode} _target : The write's target
/// @param   {Struct}         _state  : The local facts
/// @param   {Struct}         _cx     : The typing context
/// @returns {String}
#endregion
function __gmlc_type_wildcard_key(_name, _target, _state, _cx) {
	if (_name == "*") && (_target.kind == __GMLC_NodeKind_Index) return "*" + __gmlc_type_owner_class(_target.object, _state, _cx);
	return _name;
}

#region jsDoc
/// @func    __gmlc_type_field_read(_name, _class, _cx)
/// @desc    What a field read holds: what is written to the field by its name, and what the writes by a computed name
///          write to the structs or instances of the owner's class (__gmlc_type_owner_class; every class for an owner
///          of any class).
/// @param   {String} _name  : The field
/// @param   {String} _class : The owner's class
/// @param   {Struct} _cx    : The typing context
/// @returns {String}
#endregion
function __gmlc_type_field_read(_name, _class, _cx) {
	var _type = _cx.fields[$ _name] ?? "Unknown";
	var _names = struct_get_names(_cx.fields);
	var _i = 0; repeat (array_length(_names)) {
		var _k = _names[_i];
		if (string_char_at(_k, 1) == "*") {
			var _key = string_delete(_k, 1, 1);
			if (_class == "") || (_key == "") || (_key == _class) _type = gmlc_type_join(_type, _cx.fields[$ _k]);
		}
	_i++}
	return _type;
}

#region jsDoc
/// @func    __gmlc_type_record_field(_name, _t, _cx)
/// @desc    Joins the type written to a field into `_cx.writes`.
/// @param   {String} _name : The field
/// @param   {Struct} _t    : The type written, {type, provenance}
/// @param   {Struct} _cx   : The typing context
#endregion
function __gmlc_type_record_field(_name, _t, _cx) {
	if (_cx.writes == undefined) || ((!struct_exists(_cx.fields, _name)) && (string_char_at(_name, 1) != "*")) return;
	var _type = (_t.provenance == "proven") ? _t.type : "Unknown";
	_cx.writes[$ _name] = gmlc_type_join(_cx.writes[$ _name] ?? "Never", _type);
}

#region jsDoc
/// @func    __gmlc_type_same_params(_a, _b)
/// @desc    Whether two name-to-types maps are equal.
/// @param   {Struct} _a : A map
/// @param   {Struct} _b : A map
/// @returns {Bool}
#endregion
function __gmlc_type_same_params(_a, _b) {
	var _names = struct_get_names(_a);
	if (array_length(_names) != struct_names_count(_b)) return false;
	var _i = 0; repeat (array_length(_names)) {
		var _x = _a[$ _names[_i]];
		var _y = _b[$ _names[_i]];
		if (_y == undefined) || (!array_equals(_x, _y)) return false;
	_i++}
	return true;
}

#region jsDoc
/// @func    __gmlc_type_closed_functions(_asts, _external, _sources)
/// @desc    The global functions of a whole project that only its own direct calls reach, with their parameter
///          counts: no `argument` read, no parameter default, and no name a resource calls it by
///          (`_external`). A function used as a value or named by an asset name is followed to its calls
///          (__gmlc_type_call_targets).
/// @param   {Array<Struct.ASTScript>} _asts     : The lowered scripts
/// @param   {Array<String>}           _external : Function names a resource calls by name
/// @param   {Struct.GMLC_SourceTable} _sources  : Their files, or undefined
/// @returns {Struct} Function name to its parameter count
#endregion
function __gmlc_type_closed_functions(_asts, _external, _sources) {
	var _globals = {};
	var _a = 0; repeat (array_length(_asts)) {
		if (_asts[_a].kind == __GMLC_NodeKind_Script) __gmlc_type_global_functions(_asts[_a], _asts[_a].functions, _globals);
	_a++}
	var _escaped = {};
	var _e = 0; repeat (array_length(_external)) {
		_escaped[$ _external[_e]] = true;
	_e++}
	var _out = {};
	var _names = struct_get_names(_globals);
	var _i = 0; repeat (array_length(_names)) {
		var _count = _globals[$ _names[_i]];
		if (_count >= 0) && (!struct_exists(_escaped, _names[_i])) _out[$ _names[_i]] = _count;
	_i++}
	return _out;
}

#region jsDoc
/// @func    __gmlc_type_literal_prefix(_node)
/// @desc    The text a computed name surely starts with: the leading string literal of `"a" + x`,
///          `string_concat("a", x)` or `$"a{x}"`; undefined when it starts with a computed part.
/// @param   {Struct.ASTNode} _node : The name
/// @returns {String|Undefined}
#endregion
function __gmlc_type_literal_prefix(_node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal: return (_node.ty == "string") ? _node.value : undefined;
		case __GMLC_NodeKind_Binary: return (_node.op == "+") ? __gmlc_type_literal_prefix(_node.left) : undefined;
		case __GMLC_NodeKind_TemplateString: return (array_length(_node.strings) > 0) ? _node.strings[0] : undefined;
		case __GMLC_NodeKind_Call:
			var _fn = _node.callee;
			if (_fn.kind == __GMLC_NodeKind_Identifier) && (_fn.name == "string_concat") && (_fn.symbol != undefined) && (_fn.symbol.kind == "BuiltinFunction")
				&& (array_length(_node.args) > 0) return __gmlc_type_literal_prefix(_node.args[0]);
			return undefined;
	}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_type_global_functions(_node, _infos, _out)
/// @desc    Adds the global functions declared under a node: name to its parameter count when its calls alone set
///          its parameters (no `argument` read), else -1.
/// @param   {Struct.ASTNode}  _node  : The node
/// @param   {Array<Struct>}   _infos : The file's function table
/// @param   {Struct}          _out   : The functions so far, added to
#endregion
function __gmlc_type_global_functions(_node, _infos, _out) {
	if (_node.kind == __GMLC_NodeKind_FunctionDecl) || (_node.kind == __GMLC_NodeKind_ConstructorDecl) {
		var _info = ((_node.fn_id != undefined) && (_node.fn_id < array_length(_infos))) ? _infos[_node.fn_id] : undefined;
		if (_info != undefined) && (_info.registration == "global") && (_info.name != undefined) {
			// a function that writes its argument slots may change its parameters in ways calls do not show
			var _plain = (_info.facts != undefined) && (!__gmlc_type_writes_arguments(_node, true));
			_out[$ _info.name] = _plain ? array_length(_node.params) : -1;
		}
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_global_functions(_child, _infos, _out);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_self_users(_asts)
/// @desc    The global functions whose `self` matters: a constructor, or a function that reads or writes instance
///          variables, reads `self`, `other` or `id`, calls a method through `self`, or calls a function whose `self`
///          matters (nested functions count for the function they are in; a `with` body runs on its target, and
///          reads the caller's `self` only as `other`). A call of any other function
///          runs it with a `self` that nothing reads, so the caller's `self` does not flow to it.
/// @param   {Array<Struct.ASTNode>} _asts : The lowered scripts
/// @returns {Struct} The names, as keys
#endregion
function __gmlc_type_self_users(_asts) {
	var _graph = {};
	var _a = 0; repeat (array_length(_asts)) {
		if (_asts[_a].kind == __GMLC_NodeKind_Script) __gmlc_type_self_functions(_asts[_a], _asts[_a].functions, _graph);
	_a++}
	var _names = struct_get_names(_graph);
	array_sort(_names, true);
	var _users = {};
	var _n = 0; repeat (array_length(_names)) {
		if (_graph[$ _names[_n]].direct) _users[$ _names[_n]] = true;
	_n++}
	var _more = true;
	while (_more) {
		_more = false;
		_n = 0; repeat (array_length(_names)) {
			if (!struct_exists(_users, _names[_n])) {
				var _callees = _graph[$ _names[_n]].callees;
				var _c = 0; repeat (array_length(_callees)) {
					if (struct_exists(_users, _callees[_c])) {
						_users[$ _names[_n]] = true;
						_more = true;
						break;
					}
				_c++}
			}
		_n++}
	}
	return _users;
}

#region jsDoc
/// @func    __gmlc_type_self_functions(_node, _infos, _graph)
/// @desc    Adds each global function under a node to `_graph`: whether it uses `self` itself and the global functions
///          it calls by name.
/// @param   {Struct.ASTNode} _node  : The node
/// @param   {Array<Struct>}  _infos : The script's function infos
/// @param   {Struct}         _graph : name -> {direct, callees}, added to
#endregion
function __gmlc_type_self_functions(_node, _infos, _graph) {
	if (_node.kind == __GMLC_NodeKind_FunctionDecl) || (_node.kind == __GMLC_NodeKind_ConstructorDecl) {
		var _info = ((_node.fn_id != undefined) && (_node.fn_id < array_length(_infos))) ? _infos[_node.fn_id] : undefined;
		if (_info != undefined) && (_info.registration == "global") && (_info.name != undefined) {
			var _scan = { direct: (_node.kind == __GMLC_NodeKind_ConstructorDecl), callees: [] };
			var _child_fields = _node.childFields;
			var _field_index = 0; repeat (array_length(_child_fields)) {
				var _child_value = _node[$ _child_fields[_field_index]];
				var _child_many = is_array(_child_value);
				var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
					var _child = _child_many ? _child_value[_i] : _child_value;
					if (_child != undefined) {
						__gmlc_type_self_scan(_child, 0, _scan);
					}
				_i++}
			_field_index++}
			var _entry = _graph[$ _info.name];
			if (_entry == undefined) {
				_entry = { direct: false, callees: [] };
				_graph[$ _info.name] = _entry;
			}
			_entry.direct = _entry.direct || _scan.direct;
			array_copy(_entry.callees, array_length(_entry.callees), _scan.callees, 0, array_length(_scan.callees));
		}
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) __gmlc_type_self_functions(_child, _infos, _graph);
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_self_scan(_node, _depth, _scan)
/// @desc    Notes whether a node uses `self` and the global functions it calls by name (__gmlc_type_self_users).
/// @param   {Struct.ASTNode} _node  : The node
/// @param   {Real}           _depth : The `with` bodies the node is in: in one, only `other` is the function's `self`
/// @param   {Struct}         _scan  : {direct, callees}
#endregion
function __gmlc_type_self_scan(_node, _depth, _scan) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Identifier:
			var _kind = (_node.symbol != undefined) ? _node.symbol.kind : undefined;
			if (_kind == "Self") {
				if (_depth == 0) _scan.direct = true;
			}
			else if ((_kind == "BuiltinVar") || (_kind == "BuiltinConstant")) {
				if (_depth == 1) {
					if (_node.name == "other") _scan.direct = true;
				}
				else if (_depth == 0) {
					if (_node.name == "self") || (_node.name == "other") || (_node.name == "id") _scan.direct = true;
					else {
						var _variable = __gmlc_opt_builtin_variable(_node.name);
						if (_variable != undefined) && (_variable.instance) _scan.direct = true;
					}
				}
			}
			break;
		case __GMLC_NodeKind_With:
			__gmlc_type_self_scan(_node.target, _depth, _scan);
			__gmlc_type_self_scan(_node.body, _depth + 1, _scan);
			return;
		case __GMLC_NodeKind_Call:
			var _callee = _node.callee;
			if (_depth == 0) && (_callee.kind == __GMLC_NodeKind_Identifier) && (_callee.symbol != undefined) {
				if (_callee.symbol.kind == "Global") array_push(_scan.callees, _callee.name);
				else if (_callee.symbol.kind == "Self") || (_callee.symbol.kind == "Static") _scan.direct = true;
			}
			break;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_self_scan(_child, _depth, _scan);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_literal_functions(_node, _file, _methods, _counts, _holders)
/// @desc    Adds every function literal under a node that is no method and no constructor to the functions typed by their
///          calls: its key `fl:<file>:<fn_id>`, its parameter count, and its parameters' holders.
/// @param   {Struct.ASTNode} _node    : The node
/// @param   {Real}           _file    : The file's id
/// @param   {Struct}         _methods : `<file>:<fn_id>` to the field name, of the methods
/// @param   {Struct}         _counts  : Function key to its parameter count, added to
/// @param   {Struct}         _holders : Function key to the holders of its parameters, added to
#endregion
function __gmlc_type_literal_functions(_node, _file, _methods, _counts, _holders) {
	if (_node.kind == __GMLC_NodeKind_FunctionExpr) && (!_node.is_constructor) && (_node.fn_id != undefined) && (!struct_exists(_methods, string(_file) + ":" + string(_node.fn_id))) {
		var _key = "fl:" + string(_file) + ":" + string(_node.fn_id);
		_counts[$ _key] = array_length(_node.params);
		var _places = [];
		var _p = 0; repeat (array_length(_node.params)) {
			var _param = _node.params[_p];
			if (_param.kind == __GMLC_NodeKind_Param) && (__gmlc_opt_is_local(_param.target)) array_push(_places, "l:" + string(_file) + ":" + string(_node.fn_id) + ":" + _param.target.name);
			else array_push(_places, "?");
		_p++}
		_holders[$ _key] = _places;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_literal_functions(_child, _file, _methods, _counts, _holders);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_asset_flows(_asts, _sources)
/// @desc    The functions each asset name of the code may give (`fa:=<name>`, `fa:<start>`): a function named as its
///          script resource, as `asset_get_index` of a function a script declares otherwise is -1;
///          a computed name may give any of those whose name starts
///          with its written-out start, and `asset_get_ids` or `tag_get_asset_ids` any.
/// @param   {Array<Struct.ASTScript>} _asts    : The lowered scripts
/// @param   {Struct.GMLC_SourceTable} _sources : Their files, or undefined
/// @returns {Array<Array<String>>} The flows, [holder, holder]
#endregion
function __gmlc_type_asset_flows(_asts, _sources) {
	var _names = [];
	var _a = 0; repeat (array_length(_asts)) {
		__gmlc_type_asset_names(_asts[_a], _names);
	_a++}
	var _scripts = {};
	var _globals = {};
	_a = 0; repeat (array_length(_asts)) {
		if (_asts[_a].kind == __GMLC_NodeKind_Script) __gmlc_type_global_functions(_asts[_a], _asts[_a].functions, _globals);
		var _file = _asts[_a].span.file;
		if (_sources != undefined) && (_file < array_length(_sources.files)) && (_sources.files[_file] != undefined) {
			var _path = _sources.files[_file].name;
			if (string_starts_with(_path, "scripts/")) {
				var _rest = string_delete(_path, 1, 8);
				var _slash = string_pos("/", _rest);
				var _resource = (_slash > 0) ? string_copy(_rest, 1, _slash - 1) : _rest;
				if (_resource != "") _scripts[$ _resource] = true;
			}
		}
	_a++}
	var _functions = struct_get_names(_globals);
	array_sort(_functions, true);
	array_sort(_names, true);
	var _out = [];
	var _n = 0; repeat (array_length(_names)) {
		var _name = _names[_n];
		var _exact = string_starts_with(_name, "=");
		var _f = 0; repeat (array_length(_functions)) {
			var _function = _functions[_f];
			if (struct_exists(_scripts, _function)) {
				var _hit = _exact ? (_function == string_delete(_name, 1, 1)) : ((_name == "") || string_starts_with(_function, _name));
				if (_hit) array_push(_out, ["fa:" + _name, "fn:" + _function]);
			}
		_f++}
	_n++}
	return _out;
}

#region jsDoc
/// @func    __gmlc_type_asset_names(_node, _names)
/// @desc    Adds the asset names the code under a node gives to `asset_get_index` (`=<name>` for a written-out name, the
///          written-out start of a computed one), and the empty name for `asset_get_ids` and `tag_get_asset_ids`.
/// @param   {Struct.ASTNode} _node  : The node
/// @param   {Array<String>}  _names : The names so far, added to
#endregion
function __gmlc_type_asset_names(_node, _names) {
	if (_node.kind == __GMLC_NodeKind_Call) && (_node.callee.kind == __GMLC_NodeKind_Identifier) && (_node.callee.symbol != undefined) && (_node.callee.symbol.kind == "BuiltinFunction") {
		var _name = undefined;
		switch (_node.callee.name) {
			case "asset_get_index":
				var _first = (array_length(_node.args) > 0) ? _node.args[0] : undefined;
				if (_first != undefined) && (_first.kind == __GMLC_NodeKind_Literal) && (_first.ty == "string") _name = "=" + _first.value;
				else _name = ((_first != undefined) ? __gmlc_type_literal_prefix(_first) : undefined) ?? "";
				break;
			case "asset_get_ids": case "tag_get_asset_ids":
				_name = "";
				break;
		}
		if (_name != undefined) && (!array_contains(_names, _name)) array_push(_names, _name);
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_asset_names(_child, _names);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_writes_arguments(_node, _top)
/// @desc    Whether a function writes an argument slot (`argument[0] = v`, `argument1 = v`), nested functions left out.
/// @param   {Struct.ASTNode} _node : The node
/// @param   {Bool}           _top  : Whether the node is the function itself
/// @returns {Bool}
#endregion
function __gmlc_type_writes_arguments(_node, _top) {
	if (!_top) && ((_node.kind == __GMLC_NodeKind_FunctionDecl) || (_node.kind == __GMLC_NodeKind_ConstructorDecl) || (_node.kind == __GMLC_NodeKind_FunctionExpr)) return false;
	var _target = undefined;
	if (_node.kind == __GMLC_NodeKind_Assign) _target = _node.target;
	else if (_node.kind == __GMLC_NodeKind_Update) _target = _node.argument;
	if (_target != undefined) {
		var _base = ((_target.kind == __GMLC_NodeKind_Index) && ((_target.accessor == "Array") || (_target.accessor == "ArrayAt"))) ? _target.object : _target;
		if (_base.kind == __GMLC_NodeKind_Identifier) && (string_starts_with(_base.name, "argument")) && (_base.symbol != undefined) && (_base.symbol.kind == "BuiltinVar") return true;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_type_writes_arguments(_child, false)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_type_argument_functions(_node, _infos, _out)
/// @desc    Adds the global functions that read their arguments as an array (`argument[i]`, `argument0`): those names
///          alias the parameters and give the arguments past them.
/// @param   {Struct.ASTNode}       _node  : The node
/// @param   {Array<Struct>}        _infos : The script's function infos
/// @param   {Struct}               _out   : The names, added to
#endregion
function __gmlc_type_argument_functions(_node, _infos, _out) {
	if (_node.kind == __GMLC_NodeKind_FunctionDecl) || (_node.kind == __GMLC_NodeKind_ConstructorDecl) {
		var _info = ((_node.fn_id != undefined) && (_node.fn_id < array_length(_infos))) ? _infos[_node.fn_id] : undefined;
		if (_info != undefined) && (_info.registration == "global") && (_info.name != undefined) && (_info.facts != undefined)
		&& ((_info.facts.uses_argument_array) || (_info.facts.max_argument_index >= 0)) {
			_out[$ _info.name] = true;
		}
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_argument_functions(_child, _infos, _out);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_escapes(_node, _callee, _globals, _escaped, _state)
/// @desc    Adds the global functions a node lets other code reach: a name used other than as a direct call's
///          callee, or named to `asset_get_index`; sets `_state.all` when any function can be reached by a computed
///          name.
/// @param   {Struct.ASTNode} _node    : The node
/// @param   {Bool}           _callee  : Whether the node is a direct call's callee
/// @param   {Struct}         _globals : The global functions (__gmlc_type_global_functions)
/// @param   {Struct}         _escaped : The names reached from elsewhere so far, added to
/// @param   {Struct}         _state   : {all}
#endregion
function __gmlc_type_escapes(_node, _callee, _globals, _escaped, _state) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Identifier:
			if (_node.symbol != undefined) && (_node.symbol.kind == "Global") && (!_callee) && (struct_exists(_globals, _node.name)) _escaped[$ _node.name] = true;
			return;
		// `new C(...)` calls the constructor C
		case __GMLC_NodeKind_New:
			__gmlc_type_escapes(_node.callee, true, _globals, _escaped, _state);
			var _n = 0; repeat (array_length(_node.args)) {
				__gmlc_type_escapes(_node.args[_n], false, _globals, _escaped, _state);
			_n++}
			return;
		case __GMLC_NodeKind_Call:
			var _target = _node.callee;
			if (_target.kind == __GMLC_NodeKind_Identifier) && (_target.symbol != undefined) && (_target.symbol.kind == "BuiltinFunction") {
				switch (_target.name) {
					case "asset_get_index":
						var _first = (array_length(_node.args) > 0) ? _node.args[0] : undefined;
						if (_first != undefined) && (_first.kind == __GMLC_NodeKind_Literal) && (_first.ty == "string") _escaped[$ _first.value] = true;
						else {
							// `asset_get_index("spr_hud_" + string(i))` reaches only names with that start
							var _prefix = (_first != undefined) ? __gmlc_type_literal_prefix(_first) : undefined;
							if (_prefix == undefined) || (_prefix == "") _state.all = true;
							else {
								var _names = struct_get_names(_globals);
								var _g = 0; repeat (array_length(_names)) {
									if (string_starts_with(_names[_g], _prefix)) _escaped[$ _names[_g]] = true;
								_g++}
							}
						}
						break;
					// the ids of every asset of a type: only the script type reaches functions
					case "asset_get_ids": case "tag_get_asset_ids":
						var _at = (_target.name == "tag_get_asset_ids") ? 1 : 0;
						var _type = (_at < array_length(_node.args)) ? _node.args[_at] : undefined;
						var _otherType = (_type != undefined) && (_type.kind == __GMLC_NodeKind_Identifier) && (_type.symbol != undefined)
							&& (_type.symbol.kind == "BuiltinConstant") && (string_starts_with(_type.name, "asset_")) && (_type.name != "asset_script");
						if (!_otherType) _state.all = true;
						break;
				}
			}
			__gmlc_type_escapes(_target, true, _globals, _escaped, _state);
			var _k = 0; repeat (array_length(_node.args)) {
				__gmlc_type_escapes(_node.args[_k], false, _globals, _escaped, _state);
			_k++}
			return;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_escapes(_child, false, _globals, _escaped, _state);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_call_targets(_node, _state, _cx)
/// @desc    The functions a call of a value may call, as the keys of their parameters: a global function's name,
///          `m:<name>` for a method, `fl:<file>:<fn_id>` for another function literal. The callee is a local, a field
///          that holds no method, an element, a call's result, or the first argument of `script_execute`, or the field
///          of `x.f(...)` when no method has its name; undefined when the callee's group is unknown, holds no function,
///          or may hold a built-in or a function whose calls are not followed.
/// @param   {Struct.ASTNode} _node  : The call
/// @param   {Struct}         _state : The local facts
/// @param   {Struct}         _cx    : The typing context
/// @returns {Array<String>|Undefined}
#endregion
function __gmlc_type_call_targets(_node, _state, _cx) {
	// `x.f(...)` of a name no method has: the functions the field holds
	if (_node.kind == __GMLC_NodeKind_MethodCall) {
		if (struct_exists(_cx.params, "m:" + _node.member)) return undefined;
		var _owner = __gmlc_type_holder_of(_node.object, _state, _cx);
		if (_owner == undefined) return undefined;
		return __gmlc_type_holder_targets(_owner + "#" + _node.member, _cx);
	}
	if (_node.kind != __GMLC_NodeKind_Call) return undefined;
	var _callee = _node.callee;
	if (_callee.kind == __GMLC_NodeKind_Identifier) {
		var _kind = (_callee.symbol != undefined) ? _callee.symbol.kind : undefined;
		if (_kind == "Global") || (_kind == "Asset") return undefined;
		if (_kind == "BuiltinFunction") {
			if (_callee.name != "script_execute") || (array_length(_node.args) == 0) return undefined;
			_callee = _node.args[0];
		}
		else if ((_kind == "Self") || (_kind == "Static")) && (struct_exists(_cx.method_names, _callee.name)) return undefined;
	}
	return __gmlc_type_value_targets(_callee, _state, _cx);
}

#region jsDoc
/// @func    __gmlc_type_value_targets(_value, _state, _cx)
/// @desc    The functions a value may be, as the keys of their parameters (__gmlc_type_call_targets); undefined when its
///          group is unknown, holds no function, or may hold a built-in or a function whose calls are not followed.
/// @param   {Struct.ASTNode} _value : The value
/// @param   {Struct}         _state : The local facts
/// @param   {Struct}         _cx    : The typing context
/// @returns {Array<String>|Undefined}
#endregion
function __gmlc_type_value_targets(_value, _state, _cx) {
	// a function literal or a function's name is that function
	var _direct = undefined;
	if (_value.kind == __GMLC_NodeKind_FunctionExpr) {
		if (!_value.is_constructor) && (_value.fn_id != undefined) {
			var _at = string(_cx.file) + ":" + string(_value.fn_id);
			var _method = _cx.methods[$ _at];
			_direct = (_method != undefined) ? "m:" + _method : "fl:" + _at;
		}
	}
	else if (_value.kind == __GMLC_NodeKind_Identifier) && (_value.symbol != undefined) && (_value.symbol.kind == "Global") _direct = _value.name;
	if (_direct != undefined) return struct_exists(_cx.params, _direct) ? [_direct] : undefined;
	var _holder = __gmlc_type_holder_of(_value, _state, _cx);
	if (_holder == undefined) return undefined;
	return __gmlc_type_holder_targets(_holder, _cx);
}

#region jsDoc
/// @func    __gmlc_type_holder_targets(_holder, _cx)
/// @desc    The functions a holder may hold (__gmlc_type_value_targets).
/// @param   {String} _holder : The holder
/// @param   {Struct} _cx     : The typing context
/// @returns {Array<String>|Undefined}
#endregion
function __gmlc_type_holder_targets(_holder, _cx) {
	// in a whole project a value no function has reached yet calls none: the rounds start from nothing
	var _project = struct_names_count(_cx.params) > 0;
	var _objects = __gmlc_type_points(_holder, _cx.arrays, _cx.escaped);
	if (_objects == undefined) return _project ? [] : undefined;
	if (array_contains(_objects, "?")) return undefined;
	var _held = [];
	var _o = 0; repeat (array_length(_objects)) {
		if (string_starts_with(_objects[_o], "fn:")) || (string_starts_with(_objects[_o], "fl:")) || (string_starts_with(_objects[_o], "fb:")) array_push(_held, _objects[_o]);
	_o++}
	if (array_length(_held) == 0) && (!_project) return undefined;
	var _keys = [];
	var _i = 0; repeat (array_length(_held)) {
		var _function = _held[_i];
		var _key;
		if (string_starts_with(_function, "fn:")) _key = string_delete(_function, 1, 3);
		else if (string_starts_with(_function, "fl:")) {
			var _heldMethod = _cx.methods[$ string_delete(_function, 1, 3)];
			_key = (_heldMethod != undefined) ? "m:" + _heldMethod : _function;
		}
		else return undefined;
		if (!struct_exists(_cx.params, _key)) return undefined;
		if (!array_contains(_keys, _key)) array_push(_keys, _key);
	_i++}
	return _keys;
}

#region jsDoc
/// @func    __gmlc_type_rebind_targets(_value, _state, _cx)
/// @desc    The functions a value given to `method` may be, whether or not their calls are followed: a global function's
///          name, `m:<method>` or `fl:<file>:<fn_id>`; a built-in is left out (it has no `self`); undefined when the
///          value's group is unknown.
/// @param   {Struct.ASTNode} _value : The value
/// @param   {Struct}         _state : The local facts
/// @param   {Struct}         _cx    : The typing context
/// @returns {Array<String>|Undefined}
#endregion
function __gmlc_type_rebind_targets(_value, _state, _cx) {
	if (_value.kind == __GMLC_NodeKind_FunctionExpr) {
		if (_value.is_constructor) || (_value.fn_id == undefined) return undefined;
		var _at = string(_cx.file) + ":" + string(_value.fn_id);
		var _method = _cx.methods[$ _at];
		return [(_method != undefined) ? "m:" + _method : "fl:" + _at];
	}
	if (_value.kind == __GMLC_NodeKind_Identifier) && (_value.symbol != undefined) && (_value.symbol.kind == "Global") return [_value.name];
	var _holder = __gmlc_type_holder_of(_value, _state, _cx);
	if (_holder == undefined) return undefined;
	var _objects = __gmlc_type_points(_holder, _cx.arrays, _cx.escaped);
	if (_objects == undefined) return (struct_names_count(_cx.params) > 0) ? [] : undefined;
	if (array_contains(_objects, "?")) return undefined;
	var _keys = [];
	var _o = 0; repeat (array_length(_objects)) {
		var _object = _objects[_o];
		var _key = undefined;
		if (string_starts_with(_object, "fn:")) _key = string_delete(_object, 1, 3);
		else if (string_starts_with(_object, "fl:")) {
			var _heldMethod = _cx.methods[$ string_delete(_object, 1, 3)];
			_key = (_heldMethod != undefined) ? "m:" + _heldMethod : _object;
		}
		if (_key != undefined) && (!array_contains(_keys, _key)) array_push(_keys, _key);
	_o++}
	return _keys;
}

enum __GMLC_TypePassed {
	ELEMENT, // an element of its first argument
	INDEX, // an index or a position
	TEXT, // a string (a character, a field's name)
	FIELD, // the value of a field of its first argument
	RUNNING // `array_reduce`'s running value: its third argument or an element, then what the function returned
}

#region jsDoc
/// @func    __gmlc_type_callback(_name)
/// @desc    A built-in that calls a function it is given: the function's argument index and what it passes the function.
/// @param   {String} _name : The built-in
/// @returns {Struct|Undefined} {at, passed}: the function's argument index, the __GMLC_TypePassed of each of its parameters
#endregion
function __gmlc_type_callback(_name) {
	static __table = undefined;
	if (__table == undefined) {
		__table = {};
		var _each = { at: 1, passed: [__GMLC_TypePassed.ELEMENT, __GMLC_TypePassed.INDEX] };
		var _names = ["array_foreach", "array_map", "array_map_ext", "array_filter", "array_filter_ext", "array_find_index", "array_any", "array_all", "array_copy_while"];
		var _i = 0; repeat (array_length(_names)) {
			__table[$ _names[_i]] = _each;
		_i++}
		__table[$ "array_sort"] = { at: 1, passed: [__GMLC_TypePassed.ELEMENT, __GMLC_TypePassed.ELEMENT] };
		__table[$ "array_reduce"] = { at: 1, passed: [__GMLC_TypePassed.RUNNING, __GMLC_TypePassed.ELEMENT, __GMLC_TypePassed.INDEX] };
		__table[$ "array_create_ext"] = { at: 1, passed: [__GMLC_TypePassed.INDEX] };
		__table[$ "string_foreach"] = { at: 1, passed: [__GMLC_TypePassed.TEXT, __GMLC_TypePassed.INDEX] };
		__table[$ "struct_foreach"] = { at: 1, passed: [__GMLC_TypePassed.TEXT, __GMLC_TypePassed.FIELD] };
		__table[$ "call_later"] = { at: 2, passed: [] };
	}
	return __table[$ _name];
}

#region jsDoc
/// @func    __gmlc_type_call_args(_node)
/// @desc    The arguments a call passes to the functions it calls: `script_execute`'s after its first.
/// @param   {Struct.ASTNode} _node : The call, `new` or method call
/// @returns {Array<Struct.ASTNode>}
#endregion
function __gmlc_type_call_args(_node) {
	if (_node.kind == __GMLC_NodeKind_Call) {
		var _callee = _node.callee;
		if (_callee.kind == __GMLC_NodeKind_Identifier) && (_callee.name == "script_execute") && (_callee.symbol != undefined) && (_callee.symbol.kind == "BuiltinFunction") {
			var _rest = [];
			if (array_length(_node.args) > 1) array_copy(_rest, 0, _node.args, 1, array_length(_node.args) - 1);
			return _rest;
		}
		return _node.args;
	}
	if (_node.kind == __GMLC_NodeKind_New) || (_node.kind == __GMLC_NodeKind_MethodCall) return _node.args;
	return [];
}

#region jsDoc
/// @func    __gmlc_type_record_call(_node, _state, _cx)
/// @desc    Joins the argument types of a call of a global function, a constructor or a method whose calls set its
///          parameters into `_cx.calls`: an argument left out is undefined, and every argument is of unknown type when
///          one of them writes a local. The functions a built-in calls with each element or step and the functions a
///          call of a value may call get theirs too.
/// @param   {Struct.ASTNode} _node  : The node
/// @param   {Struct}         _state : The facts after its arguments
/// @param   {Struct}         _cx    : The typing context
#endregion
function __gmlc_type_record_call(_node, _state, _cx) {
	if (_cx.calls == undefined) return;
	// the function a built-in calls with each element or step
	if (_node.kind == __GMLC_NodeKind_Call) {
		var _builtin = __gmlc_type_builtin_name(_node);
		var _callback = (_builtin != undefined) ? __gmlc_type_callback(_builtin) : undefined;
		var _callbackKeys = ((_callback != undefined) && (_callback.at < array_length(_node.args))) ? __gmlc_type_value_targets(_node.args[_callback.at], __gmlc_type_copy(_state), _cx) : undefined;
		if (_callbackKeys != undefined) {
			var _baseHolder = (array_length(_node.args) > 0) ? __gmlc_type_holder_of(_node.args[0], __gmlc_type_copy(_state), _cx) : undefined;
			var _element = ((_baseHolder != undefined) ? __gmlc_type_place_type("e:" + _baseHolder, _cx.arrays, _cx.elements, _cx.escaped) : undefined) ?? __gmlc_type_no_elements(_cx);
			var _c = 0; repeat (array_length(_callbackKeys)) {
				var _callbackKey = _callbackKeys[_c];
				var _returned = _cx.batch[$ _callbackKey] ?? "Unknown";
				var _types = [];
				var _p = 0; repeat (array_length(_callback.passed)) {
					switch (_callback.passed[_p]) {
						case __GMLC_TypePassed.ELEMENT: array_push(_types, _element); break;
						case __GMLC_TypePassed.INDEX: array_push(_types, "Int"); break;
						case __GMLC_TypePassed.TEXT: array_push(_types, "String"); break;
						case __GMLC_TypePassed.FIELD: array_push(_types, "Unknown"); break;
						case __GMLC_TypePassed.RUNNING:
							var _start = _element;
							if (array_length(_node.args) > 2) {
								var _init = __gmlc_type_of(_node.args[2], __gmlc_type_copy(_state), _cx);
								_start = (_init.provenance == "proven") ? _init.type : "Unknown";
							}
							array_push(_types, gmlc_type_join(_start, _returned));
							break;
					}
				_p++}
				__gmlc_type_record_types(_callbackKey, _types, _cx);
			_c++}
			return;
		}
	}
	// the functions a call of a value may call
	var _targets = __gmlc_type_call_targets(_node, __gmlc_type_copy(_state), _cx);
	if (_targets != undefined) {
		var _t = 0; repeat (array_length(_targets)) {
			__gmlc_type_record_args(_targets[_t], __gmlc_type_call_args(_node), _state, _cx);
		_t++}
		return;
	}
	// a global function by name, a constructor by `new`, a method by `x.m(...)` or by its name through `self`
	var _key, _args;
	switch (_node.kind) {
		case __GMLC_NodeKind_Call:
			var _target = _node.callee;
			if (_target.kind != __GMLC_NodeKind_Identifier) || (_target.symbol == undefined) return;
			if (_target.symbol.kind == "Global") _key = _target.name;
			else if (_target.symbol.kind == "Self") || (_target.symbol.kind == "Static") _key = "m:" + _target.name;
			else return;
			_args = _node.args;
			break;
		case __GMLC_NodeKind_New:
			var _ctor = _node.callee;
			if (_ctor.kind != __GMLC_NodeKind_Identifier) || (_ctor.symbol == undefined) || (_ctor.symbol.kind != "Global") return;
			_key = _ctor.name;
			_args = _node.args;
			break;
		case __GMLC_NodeKind_MethodCall:
			_key = "m:" + _node.member;
			_args = _node.args;
			break;
		default: return;
	}
	__gmlc_type_record_args(_key, _args, _state, _cx);
}

#region jsDoc
/// @func    __gmlc_type_record_types(_key, _types, _cx)
/// @desc    Joins the types a call passes into the parameters of the function `_key` names; a parameter it passes nothing
///          to is undefined.
/// @param   {String}        _key   : The function's key
/// @param   {Array<String>} _types : The types passed
/// @param   {Struct}        _cx    : The typing context
#endregion
function __gmlc_type_record_types(_key, _types, _cx) {
	var _typed = _cx.params[$ _key];
	if (_typed == undefined) return;
	var _count = array_length(_typed);
	var _entry = _cx.calls[$ _key];
	if (_entry == undefined) {
		_entry = array_create(_count, "Never");
		_cx.calls[$ _key] = _entry;
	}
	var _k = 0; repeat (_count) {
		_entry[_k] = gmlc_type_join(_entry[_k], (_k < array_length(_types)) ? _types[_k] : "Undefined");
	_k++}
}

#region jsDoc
/// @func    __gmlc_type_record_args(_key, _args, _state, _cx)
/// @desc    Joins the types of the arguments of one call into the parameters of the function `_key` names.
/// @param   {String}                _key   : The function's key
/// @param   {Array<Struct.ASTNode>} _args  : The arguments
/// @param   {Struct}                _state : The facts after its arguments
/// @param   {Struct}                _cx    : The typing context
#endregion
function __gmlc_type_record_args(_key, _args, _state, _cx) {
	var _typed = _cx.params[$ _key];
	if (_typed == undefined) return;
	var _count = array_length(_typed);
	var _writes = false;
	var _k = 0; repeat (array_length(_args)) {
		if (__gmlc_type_writes_local(_args[_k])) _writes = true;
	_k++}
	var _types = array_create(_count);
	_k = 0; repeat (_count) {
		if (_k >= array_length(_args)) _types[_k] = "Undefined";
		else if (_writes) _types[_k] = "Unknown";
		else {
			var _t = __gmlc_type_of(_args[_k], __gmlc_type_copy(_state), _cx);
			_types[_k] = (_t.provenance == "proven") ? _t.type : "Unknown";
		}
	_k++}
	var _entry = _cx.calls[$ _key];
	if (_entry == undefined) {
		_entry = array_create(_count, "Never");
		_cx.calls[$ _key] = _entry;
	}
	_k = 0; repeat (_count) {
		_entry[_k] = gmlc_type_join(_entry[_k], _types[_k]);
	_k++}
}

#region jsDoc
/// @func    __gmlc_type_writes_local(_node)
/// @desc    Whether an expression assigns or updates a local, nested functions left out.
/// @param   {Struct.ASTNode} _node : The expression
/// @returns {Bool}
#endregion
function __gmlc_type_writes_local(_node) {
	switch (_node.kind) {
		case __GMLC_NodeKind_FunctionExpr: return false;
		case __GMLC_NodeKind_Assign: if (__gmlc_opt_is_local(_node.target)) return true; break;
		case __GMLC_NodeKind_Update: if (__gmlc_opt_is_local(_node.argument)) return true; break;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				if (__gmlc_type_writes_local(_child)) return true;
			}
		_i++}
	_field_index++}
	return false;
}

#region jsDoc
/// @func    __gmlc_type_same_names(_a, _b)
/// @desc    Whether two name-to-type maps are equal.
/// @param   {Struct} _a : A map
/// @param   {Struct} _b : A map
/// @returns {Bool}
#endregion
function __gmlc_type_same_names(_a, _b) {
	var _names = struct_get_names(_a);
	if (array_length(_names) != struct_names_count(_b)) return false;
	var _i = 0; repeat (array_length(_names)) {
		if (_b[$ _names[_i]] != _a[$ _names[_i]]) return false;
	_i++}
	return true;
}

#region jsDoc
/// @func    __gmlc_type_run(_ast, _sources, _docs, _batch, _sinks, _diagnostics)
/// @desc    The facts of every function of a lowered script, and the types held by every local name.
/// @param   {Struct.ASTScript}        _ast     : A lowered script
/// @param   {Struct.GMLC_SourceTable} _sources : Its files, or undefined
/// @param   {Bool}                    _docs    : Whether the JSDoc comments above functions type parameters
/// @param   {Struct}                  _batch   : {returns, params, fields, ...} of the batch (gmlc_type_batch)
/// @param   {Struct}                  _sinks   : {calls, writes, flows, elems} the types of a project's calls and field
///                                               writes and its array flows are joined into, or undefined
/// @param   {Struct}                  _diagnostics : {found, returns} the operations that always throw and the return
///                                               type of each function are collected into in the last round, or undefined
/// @returns {Struct|Undefined} {functions, held}, or undefined for a node that is no script
#endregion
function __gmlc_type_run(_ast, _sources, _docs, _batch, _sinks, _diagnostics = undefined) {
	if (_ast.kind != __GMLC_NodeKind_Script) return undefined;
	var _units = [{ fn_id: 0, params: [], body: _ast.body, node: undefined }];
	__gmlc_analysis_units(_ast, _units);
	array_sort(_units, __gmlc_compare_fn_id);
	// the file's own global functions, which a call of a global name reaches
	var _named = {};
	var _u = 0; repeat (array_length(_units)) {
		var _node = _units[_u].node;
		var _uid = _units[_u].fn_id;
		var _global = (_uid < array_length(_ast.functions)) && (_ast.functions[_uid] != undefined) && (_ast.functions[_uid].registration == "global");
		if (_global) && (_node != undefined) && ((_node.kind == __GMLC_NodeKind_FunctionDecl) || (_node.kind == __GMLC_NodeKind_ConstructorDecl)) {
			_named[$ _node.name] = _uid;
		}
	_u++}
	var _objectFile = false;
	// a script resource's top-level code runs with the global struct as `self`
	var _scriptFile = false;
	if (_sources != undefined) && (_ast.span != undefined) && (_ast.span.file < array_length(_sources.files)) && (_sources.files[_ast.span.file] != undefined) {
		_objectFile = __gmlc_opt_is_event_file(_sources.files[_ast.span.file].name);
		_scriptFile = string_starts_with(_sources.files[_ast.span.file].name, "scripts/");
	}
	// self_instance: `self` is sure to be an instance where the node being typed runs (an object event's own code outside `with`)
	// structs_open: structs with any fields are made, so a field read has its type only where it surely reads an instance or a constructor's struct
	var _cx = { named: _named, returns: {}, batch: _batch.returns, params: _batch.params, calls: undefined, fields: _batch.fields, writes: undefined,
		structs_open: _batch.structs_open,
		builtins: __gmlc_type_builtins(), object_file: _objectFile, script_file: _scriptFile, self_instance: false,
		// the array holders: the file, the function being typed, where its return values go, each holder's group,
		// each group's element type, the closed functions' parameter holders, and the sinks of a project's typing
		file: _ast.span.file, fn_id: 0, ret: "?", arrays: _batch.arrays, elements: _batch.elements,
		param_holders: _batch.param_holders, flows: undefined, elems: undefined, diags: undefined,
		// the holder `self` is where the statement being typed runs, the self holder of each function (`selfs`) and
		// of the statements of each `with` body (`with_selfs`), where each function's statics live, and the methods
		self_holder: "?", selfs: {}, with_selfs: { nodes: [], holders: [] }, statics: {}, methods: _batch.methods, method_names: {},
		self_users: _batch.self_users, escaped: _batch.escaped,
		// the type of every read of an instance variable or a static by name in the file, joined, in the last round
		self_reads: undefined };
	// the field names methods are stored under
	var _defs = struct_get_names(_cx.methods);
	var _d = 0; repeat (array_length(_defs)) {
		_cx.method_names[$ _cx.methods[$ _defs[_d]]] = true;
	_d++}
	__gmlc_type_self_holders(_ast, _ast.functions, _cx);
	var _out = [];
	var _held = {};
	var _round = 0; repeat (2) {
		_out = [];
		_held = {};
		var _returns = {};
		// the calls are recorded in the last round, which knows the file's own return types
		_cx.calls = (_round == 1) && (_sinks != undefined) ? _sinks.calls : undefined;
		_cx.writes = (_round == 1) && (_sinks != undefined) ? _sinks.writes : undefined;
		_cx.flows = (_round == 1) && (_sinks != undefined) ? _sinks.flows : undefined;
		_cx.elems = (_round == 1) && (_sinks != undefined) ? _sinks.elems : undefined;
		_cx.diags = (_round == 1) ? _diagnostics : undefined;
		_cx.self_reads = (_round == 1) ? {} : undefined;
		_u = 0; repeat (array_length(_units)) {
			var _unit = _units[_u];
			var _info = (_unit.fn_id < array_length(_ast.functions)) ? _ast.functions[_unit.fn_id] : undefined;
			var _name = ((_info != undefined) && (_info.name != undefined)) ? _info.name : "";
			var _method = _cx.methods[$ string(_cx.file) + ":" + string(_unit.fn_id)];
			var _literal = "fl:" + string(_cx.file) + ":" + string(_unit.fn_id);
			var _typed;
			if (_method != undefined) _typed = _cx.params[$ "m:" + _method];
			else if (struct_exists(_cx.params, _literal)) _typed = _cx.params[$ _literal];
			else _typed = ((_info != undefined) && (_info.registration == "global")) ? _cx.params[$ _name] : undefined;
			if (_method != undefined) _name = "m:" + _method;
			else if (struct_exists(_cx.params, _literal)) _name = _literal;
			var _facts = __gmlc_type_function_facts(_unit, _name, _docs ? _sources : undefined, _cx, _held, _typed);
			_returns[$ string(_unit.fn_id)] = { type: _facts.returns, provenance: _facts.returns_provenance };
			array_push(_out, _facts);
		_u++}
		_cx.returns = _returns;
	_round++}
	var _reads = struct_get_names(_cx.self_reads);
	var _r = 0; repeat (array_length(_reads)) {
		_held[$ "[s]" + _reads[_r]] = _cx.self_reads[$ _reads[_r]];
	_r++}
	_cx.self_reads = undefined;
	return { functions: _out, held: _held };
}

#region jsDoc
/// @func    __gmlc_type_builtins()
/// @desc    Built-in function name to its canonical return type, from the signature database; made once.
/// @returns {Struct}
#endregion
function __gmlc_type_builtins() {
	static __map = undefined;
	if (__map == undefined) {
		__map = {};
		var _functions = __GmlcDataSpec().functions;
		var _i = 0; repeat (array_length(_functions)) {
			var _f = _functions[_i];
			var _rt = _f[$ "returnType"] ?? "";
			__map[$ _f.name] = (_rt == "") ? "Unknown" : (gmlc_type_string(_rt, "spec-return") ?? "Unknown");
		_i++}
	}
	return __map;
}

#region jsDoc
/// @func    __gmlc_type_variable(_name)
/// @desc    The type of a readable built-in variable that is no instance variable (`room_width`, `current_time`),
///          from the built-in data: Real or String, else Unknown.
/// @param   {String} _name : The variable
/// @returns {String}
#endregion
function __gmlc_type_variable(_name) {
	// an instance variable (`x`, `image_angle`) has its type only on an instance: a struct's `x` is any field
	var _entry = __gmlc_opt_builtin_variable(_name);
	if (_entry != undefined) && (_entry.instance) return "Unknown";
	return __gmlc_type_held_variable(_entry);
}

#region jsDoc
/// @func    __gmlc_type_held_variable(_entry)
/// @desc    The type a built-in variable holds by its data: Real or String, or the data's type where code cannot
///          write it (a write of another kind of value could change what it reads back).
/// @param   {Struct|Undefined} _entry : The variable's data
/// @returns {String}
#endregion
function __gmlc_type_held_variable(_entry) {
	if (_entry == undefined) return "Unknown";
	if (_entry.type == "Real") || (_entry.type == "String") return _entry.type;
	if (!_entry.set) return gmlc_type_string(_entry.type, "spec-return") ?? "Unknown";
	return "Unknown";
}

#region jsDoc
/// @func    __gmlc_type_instance_variable(_name)
/// @desc    The type of a readable built-in instance variable (`x`, `image_angle`) read where `self` is sure to be an
///          instance, from the built-in data: Real or String, else Unknown.
/// @param   {String} _name : The variable
/// @returns {String}
#endregion
function __gmlc_type_instance_variable(_name) {
	var _entry = __gmlc_opt_builtin_variable(_name);
	if (_entry == undefined) || (!_entry.instance) return "Unknown";
	return __gmlc_type_held_variable(_entry);
}

#region jsDoc
/// @func    __gmlc_type_with_bodies(_node, _inside, _out)
/// @desc    Adds every node a `with` body runs under a statement, nested functions left out.
/// @param   {Struct.ASTNode}        _node   : The node
/// @param   {Bool}                  _inside : Whether the node is in a `with` body
/// @param   {Array<Struct.ASTNode>} _out    : The nodes so far, added to
#endregion
function __gmlc_type_with_bodies(_node, _inside, _out) {
	switch (_node.kind) {
		case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl: case __GMLC_NodeKind_FunctionExpr: return;
	}
	if (_inside) array_push(_out, _node);
	if (_node.kind == __GMLC_NodeKind_With) {
		__gmlc_type_with_bodies(_node.target, _inside, _out);
		__gmlc_type_with_bodies(_node.body, true, _out);
		return;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_with_bodies(_child, _inside, _out);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_constants()
/// @desc    Built-in constant name to its canonical type, from the built-in data; made once.
/// @returns {Struct}
#endregion
function __gmlc_type_constants() {
	static __map = undefined;
	if (__map == undefined) {
		__map = {};
		var _constants = __GmlcDataSpec().constants;
		var _i = 0; repeat (array_length(_constants)) {
			var _c = _constants[_i];
			var _type = _c[$ "type"] ?? "";
			if (_type != "") {
				var _canonical = gmlc_type_string(_type, "spec-return");
				if (_canonical != undefined) __map[$ _c.name] = _canonical;
			}
		_i++}
	}
	return __map;
}

#region jsDoc
/// @func    __gmlc_type_trim(_text)
/// @desc    The text without blanks at either end.
/// @param   {String} _text : The text
/// @returns {String}
#endregion
function __gmlc_type_trim(_text) {
	static __blanks = [" ", "\t", "\r", "\n"];
	return string_trim(_text, __blanks);
}

#region jsDoc
/// @func    gmlc_type_jsdoc_mismatches(_asts, _sources, _batch)
/// @desc    The parameters whose JSDoc type does not allow what a whole project's calls pass: for every function only
///          the project's own calls reach (`_batch.params`), each documented parameter whose calls pass a type the
///          JSDoc type does not take.
/// @param   {Array<Struct.ASTScript>} _asts    : The lowered scripts
/// @param   {Struct.GMLC_SourceTable} _sources : Their files
/// @param   {Struct}                  _batch   : {params} (gmlc_type_batch)
/// @returns {Array<Struct>} {span, args: [function, parameter, JSDoc type, passed type]}, the span the function's
#endregion
function gmlc_type_jsdoc_mismatches(_asts, _sources, _batch) {
	var _out = [];
	var _a = 0; repeat (array_length(_asts)) {
		var _ast = _asts[_a];
		if (_ast.kind == __GMLC_NodeKind_Script) {
			var _units = [{ fn_id: 0, params: [], body: _ast.body, node: undefined }];
			__gmlc_analysis_units(_ast, _units);
			array_sort(_units, __gmlc_compare_fn_id);
			var _u = 0; repeat (array_length(_units)) {
				var _unit = _units[_u];
				var _info = (_unit.node != undefined) && (_unit.fn_id < array_length(_ast.functions)) ? _ast.functions[_unit.fn_id] : undefined;
				var _passed = ((_info != undefined) && (_info.registration == "global") && (_info.name != undefined)) ? _batch.params[$ _info.name] : undefined;
				if (_passed != undefined) {
					var _docs = __gmlc_type_jsdoc(_unit.node, _sources);
					var _p = 0; repeat (array_length(_unit.params)) {
						var _param = _unit.params[_p];
						if (__gmlc_opt_is_local(_param)) && (_p < array_length(_passed)) {
							var _doc = _docs[$ _param.name];
							if (_doc != undefined) {
								var _allowed = _doc.optional ? gmlc_type_join(_doc.type, "Undefined") : _doc.type;
								// where the calls leave out a parameter with a default, the default is what it holds
								var _declared = (_p < array_length(_unit.node[$ "params"] ?? [])) ? _unit.node.params[_p] : undefined;
								var _given = ((_declared != undefined) && (_declared.kind == __GMLC_NodeKind_Param) && (_declared[$ "default"] != undefined)) ? __gmlc_type_remove(_passed[_p], "Undefined") : _passed[_p];
								if (!__gmlc_type_takes(_allowed, _given)) {
									array_push(_out, { span: _unit.node.span, args: [_info.name, _param.name, _doc.type, _given] });
								}
							}
						}
					_p++}
				}
			_u++}
		}
	_a++}
	return _out;
}

#region jsDoc
/// @func    __gmlc_type_handle(_type)
/// @desc    Whether a type names a handle: an id, an asset or a pointer.
/// @param   {String} _type : The type
/// @returns {Bool}
#endregion
function __gmlc_type_handle(_type) {
	return string_starts_with(_type, "Id.") || string_starts_with(_type, "Asset") || string_starts_with(_type, "Pointer");
}

#region jsDoc
/// @func    __gmlc_type_takes(_doc, _passed)
/// @desc    Whether a JSDoc type takes every member of a passed type: the member itself or a type that holds it
///          (`Real` any number kind, a bool, an int64, an enum or a constant; `Struct` any struct; `Array` any array;
///          `Function` any function); `Any` takes everything. A passed type of unknown members is not checked.
/// @param   {String} _doc    : The JSDoc type
/// @param   {String} _passed : The passed type
/// @returns {Bool}
#endregion
function __gmlc_type_takes(_doc, _passed) {
	var _allowed = __gmlc_type_members(_doc);
	if (array_contains(_allowed, "Any")) || (array_contains(_allowed, "Unknown")) return true;
	var _members = __gmlc_type_members(_passed);
	var _i = 0; repeat (array_length(_members)) {
		var _m = _members[_i];
		if (_m != "Never") && (_m != "Unknown") && (_m != "Any") {
			var _ok = false;
			var _j = 0; repeat (array_length(_allowed)) {
				var _a = _allowed[_j];
				var _numeric = (_m == "Int") || (_m == "Double") || (_m == "Bool") || (_m == "Int64") || string_starts_with(_m, "Enum.") || string_starts_with(_m, "Constant.");
				// a struct of another constructor may inherit from the one named; handles are named many ways
				if (_a == _m) || ((_a == "Real") && _numeric) || (string_starts_with(_a, "Struct") && string_starts_with(_m, "Struct"))
					|| (__gmlc_type_handle(_a) && __gmlc_type_handle(_m))
					|| (string_starts_with(_a, "Array") && string_starts_with(_m, "Array")) || (string_starts_with(_a, "Function") && string_starts_with(_m, "Function"))
					|| (string_starts_with(_a, "Constant.") && ((_m == "Int") || (_m == "Double") || (_m == "Real"))) {
					_ok = true;
				}
			_j++}
			if (!_ok) return false;
		}
	_i++}
	return true;
}

#region jsDoc
/// @func    __gmlc_type_jsdoc_lines(_node, _sources)
/// @desc    The `///` comment lines directly above a function, the marker cut off.
/// @param   {Struct}                  _node    : The function
/// @param   {Struct.GMLC_SourceTable} _sources : Its files
/// @returns {Array<String>}
#endregion
function __gmlc_type_jsdoc_lines(_node, _sources) {
	var _lines = [];
	if (_node == undefined) || (_sources == undefined) || (_node.span.file >= array_length(_sources.files)) return _lines;
	var _file = _sources.files[_node.span.file];
	if (_file == undefined) return _lines;
	var _line = _file.lineOf(_node.span.start) - 1;
	while (_line >= 1) {
		var _text = __gmlc_type_trim(_file.lineText(_line));
		if (!string_starts_with(_text, "///")) break;
		array_insert(_lines, 0, __gmlc_type_trim(string_delete(_text, 1, 3)));
		_line--;
	}
	return _lines;
}

#region jsDoc
/// @func    __gmlc_type_jsdoc_returns(_node, _sources)
/// @desc    The canonical type of the JSDoc `@returns` tag above a function, when it names a type.
/// @param   {Struct}                  _node    : The function
/// @param   {Struct.GMLC_SourceTable} _sources : Its files
/// @returns {String|Undefined}
#endregion
function __gmlc_type_jsdoc_returns(_node, _sources) {
	var _lines = __gmlc_type_jsdoc_lines(_node, _sources);
	var _i = 0; repeat (array_length(_lines)) {
		var _l = _lines[_i];
		var _space = string_pos(" ", _l);
		var _tag = (_space > 0) ? string_copy(_l, 1, _space - 1) : _l;
		var _after = (_space > 0) ? __gmlc_type_trim(string_delete(_l, 1, _space)) : "";
		if ((_tag == "@returns") || (_tag == "@return")) && (string_starts_with(_after, "{")) {
			var _close = string_pos("}", _after);
			if (_close > 0) return gmlc_type_string(string_copy(_after, 2, _close - 2), "jsdoc");
		}
	_i++}
	return undefined;
}

#region jsDoc
/// @func    __gmlc_type_jsdoc(_node, _sources)
/// @desc    The JSDoc @param types above a function: name to {type, optional}.
#endregion
function __gmlc_type_jsdoc(_node, _sources) {
	var _out = {};
	var _lines = __gmlc_type_jsdoc_lines(_node, _sources);
	var _i = 0; repeat (array_length(_lines)) {
		var _l = _lines[_i];
		var _space = string_pos(" ", _l);
		var _tag = (_space > 0) ? string_copy(_l, 1, _space - 1) : _l;
		if (_tag == "@param") || (_tag == "@parameter") || (_tag == "@arg") || (_tag == "@argument") {
			var _rest = __gmlc_type_trim(string_delete(_l, 1, _space));
			var _type = undefined;
			if (string_starts_with(_rest, "{")) {
				var _close = string_pos("}", _rest);
				if (_close > 0) {
					_type = string_copy(_rest, 2, _close - 2);
					_rest = __gmlc_type_trim(string_delete(_rest, 1, _close));
				}
			}
			var _end = string_pos(" ", _rest);
			var _name = (_end > 0) ? string_copy(_rest, 1, _end - 1) : _rest;
			var _optional = string_starts_with(_name, "[");
			if (_optional) {
				_name = string_replace(string_replace(_name, "[", ""), "]", "");
				var _eq = string_pos("=", _name);
				if (_eq > 0) _name = string_copy(_name, 1, _eq - 1);
			}
			if (_type != undefined) && (_name != "") {
				var _canonical = gmlc_type_string(_type, "jsdoc");
				if (_canonical != undefined) _out[$ _name] = { type: _canonical, optional: _optional };
			}
		}
	_i++}
	return _out;
}

#region jsDoc
/// @func    __gmlc_type_function_facts(_unit, _name, _sources, _cx, _held)
/// @desc    The flow facts of one function: its locals' facts where it ends and its return type. The type each
///          local holds, joined over every program point, is joined into `_held`.
/// @param   {Struct}                  _unit    : The function, {fn_id, params, body, node}
/// @param   {String}                  _name    : Its name
/// @param   {Struct.GMLC_SourceTable} _sources : The files, for its JSDoc, or undefined
/// @param   {Struct}                  _cx      : {named, returns, builtins} of the script
/// @param   {Struct}                  _held    : Local name to the type it holds, added to
/// @param   {Array<String>}           _typed   : The types its parameters hold (gmlc_type_batch), or undefined
/// @returns {Struct} {fn_id, name, returns, returns_provenance, locals}
#endregion
function __gmlc_type_function_facts(_unit, _name, _sources, _cx, _held, _typed) {
	var _g = __gmlc_cfg_build(_unit);
	var _n = array_length(_g.nodes);
	_cx.fn_id = _unit.fn_id;
	var _unitSelf = _cx.selfs[$ string(_unit.fn_id)] ?? "?";
	_cx.self_holder = _unitSelf;
	_cx.ret = (_typed != undefined) ? "r:" + _name : "?";
	// the parameters of a method are the parameters of the methods of its name
	if (_typed != undefined) && (string_starts_with(_name, "m:")) && (struct_exists(_cx.param_holders, _name)) {
		var _holders = _cx.param_holders[$ _name];
		var _hp = 0; repeat (array_length(_unit.params)) {
			if (__gmlc_opt_is_local(_unit.params[_hp])) && (_hp < array_length(_holders)) {
				__gmlc_type_add_flow("l:" + string(_cx.file) + ":" + string(_unit.fn_id) + ":" + _unit.params[_hp].name, _holders[_hp], _cx);
			}
		_hp++}
	}
	// the parameters of a function code outside the project's own calls may call hold any array
	if (_typed == undefined) && (_unit.node != undefined) {
		var _pp = 0; repeat (array_length(_unit.params)) {
			if (__gmlc_opt_is_local(_unit.params[_pp])) __gmlc_type_add_flow("l:" + string(_cx.file) + ":" + string(_unit.fn_id) + ":" + _unit.params[_pp].name, "?", _cx);
		_pp++}
	}
	// the statements a `with` runs with another `self`
	var _inWith = [];
	var _events = (_cx.object_file) && (_unit.fn_id == 0);
	if (_events) {
		var _b = 0; repeat (array_length(_unit.body)) { __gmlc_type_with_bodies(_unit.body[_b], false, _inWith); _b++ }
	}
	var _preds = array_create(_n);
	var _excPreds = array_create(_n);
	var _i = 0; repeat (_n) {
		_preds[_i] = [];
		_excPreds[_i] = [];
	_i++}
	_i = 0; repeat (_n) {
		var _node = _g.nodes[_i];
		var _s = 0; repeat (array_length(_node.succ)) { array_push(_preds[_node.succ[_s]], _i); _s++ }
		_s = 0; repeat (array_length(_node.exc)) { array_push(_excPreds[_node.exc[_s]], _i); _s++ }
	_i++}
	var _jsdoc = __gmlc_type_jsdoc(_unit.node, _sources);
	var _start = {};
	var _p = 0; repeat (array_length(_unit.params)) {
		var _param = _unit.params[_p];
		if (__gmlc_opt_is_local(_param)) {
			var _doc = _jsdoc[$ _param.name];
			// a parameter of a function only the project's own calls reach holds what they pass
			if (_typed != undefined) && (_p < array_length(_typed)) {
				var _passed = _typed[_p];
				// a typed parameter with a default holds the default where its calls leave it out
				var _declared = ((_unit.node != undefined) && ((_unit.node.kind == __GMLC_NodeKind_FunctionDecl) || (_unit.node.kind == __GMLC_NodeKind_ConstructorDecl) || (_unit.node.kind == __GMLC_NodeKind_FunctionExpr)) && (_p < array_length(_unit.node.params))) ? _unit.node.params[_p] : undefined;
				if (_declared != undefined) && (_declared.kind == __GMLC_NodeKind_Param) && (_declared[$ "default"] != undefined) && (array_contains(__gmlc_type_members(_passed), "Undefined")) {
					var _initial = __gmlc_type_of(_declared[$ "default"], __gmlc_type_copy(_start), _cx);
					_passed = gmlc_type_join(__gmlc_type_remove(_passed, "Undefined"), (_initial.provenance == "proven") ? _initial.type : "Unknown");
				}
				_start[$ _param.name] = { type: _passed, provenance: "proven", assigned: "yes" };
			}
			else if (_doc != undefined) {
				_start[$ _param.name] = { type: _doc.optional ? gmlc_type_join(_doc.type, "Undefined") : _doc.type, provenance: "annotated", assigned: "yes" };
			}
			else _start[$ _param.name] = { type: "Unknown", provenance: "proven", assigned: "yes" };
		}
	_p++}
	// the parameters' defaults and a constructor's parent call run before the body: their calls and field writes count
	if (_unit.node != undefined) {
		var _kind = _unit.node.kind;
		var _params = ((_kind == __GMLC_NodeKind_FunctionDecl) || (_kind == __GMLC_NodeKind_ConstructorDecl) || (_kind == __GMLC_NodeKind_FunctionExpr)) ? _unit.node.params : [];
		var _before = __gmlc_type_copy(_start);
		var _d = 0; repeat (array_length(_params)) {
			var _default = (_params[_d].kind == __GMLC_NodeKind_Param) ? _params[_d][$ "default"] : undefined;
			if (_default != undefined) __gmlc_type_walk(_default, _before, _cx, true);
		_d++}
		if (_kind == __GMLC_NodeKind_ConstructorDecl) && (_unit.node.parent != undefined) {
			__gmlc_type_walk(_unit.node.parent, _before, _cx, false);
			// the parent constructor runs on the child's struct
			var _parentCall = _unit.node.parent;
			if (_parentCall.kind == __GMLC_NodeKind_Call) && (_parentCall.callee.kind == __GMLC_NodeKind_Identifier) && (_parentCall.callee.symbol != undefined)
			&& (_parentCall.callee.symbol.kind == "Global") && (_cx.flows != undefined) {
				__gmlc_type_add_flow("c:" + _parentCall.callee.name, _cx.self_holder, _cx);
			}
		}
	}
	var _in = array_create(_n);
	var _out = array_create(_n);
	var _visits = array_create(_n, 0);
	_i = 0; repeat (_n) {
		_in[_i] = {};
		_out[_i] = undefined;
	_i++}
	var _changed = true;
	while (_changed) {
		_changed = false;
		_i = 0; repeat (_n) {
			var _state = (_i == 0) ? __gmlc_type_copy(_start) : undefined;
			var _q = 0; repeat (array_length(_preds[_i])) {
				var _o = _out[_preds[_i][_q]];
				if (_o != undefined) _state = (_state == undefined) ? __gmlc_type_copy(_o) : __gmlc_type_merge(_state, _o);
			_q++}
			// a statement that throws may have run any part of itself
			_q = 0; repeat (array_length(_excPreds[_i])) {
				var _from = _excPreds[_i][_q];
				if (_out[_from] != undefined) {
					var _both = __gmlc_type_merge(__gmlc_type_copy(_in[_from]), _out[_from]);
					_state = (_state == undefined) ? _both : __gmlc_type_merge(_state, _both);
				}
			_q++}
			if (_state != undefined) {
				_in[_i] = __gmlc_type_copy(_state);
				_cx.self_instance = _events && ((_g.nodes[_i].stmt == undefined) || (!array_contains(_inWith, _g.nodes[_i].stmt)));
				_cx.self_holder = ((_g.nodes[_i].stmt != undefined) ? __gmlc_type_with_self(_cx, _g.nodes[_i].stmt) : undefined) ?? _unitSelf;
				__gmlc_type_node(_g.nodes[_i], _state, _cx);
				if (_out[_i] == undefined) || (!__gmlc_type_same(_out[_i], _state)) {
					_visits[_i]++;
					// after 16 changes a fact that still changes widens to Unknown
					if (_visits[_i] > 16) && (_out[_i] != undefined) {
						var _names = struct_get_names(_state);
						var _k = 0; repeat (array_length(_names)) {
							var _old = _out[_i][$ _names[_k]];
							if (_old == undefined) || (_old.type != _state[$ _names[_k]].type) _state[$ _names[_k]].type = "Unknown";
						_k++}
					}
					if (_out[_i] == undefined) || (!__gmlc_type_same(_out[_i], _state)) {
						_out[_i] = _state;
						_changed = true;
					}
				}
			}
		_i++}
	}
	if (_cx.diags != undefined) {
		_i = 0; repeat (_n) {
			var _site = _g.nodes[_i];
			var _root = __gmlc_type_check_root(_site);
			if (_root != undefined) {
				_cx.self_instance = _events && ((_site.stmt == undefined) || (!array_contains(_inWith, _site.stmt)));
				__gmlc_type_check_operands(_root, _in[_i], _cx);
			}
		_i++}
	}
	// the return type: every return value, and Undefined when the function can end without one
	var _returns = "Never";
	var _provenance = "proven";
	var _q = 0; repeat (array_length(_preds[1])) {
		var _node = _g.nodes[_preds[1][_q]];
		var _stmt = _node.stmt;
		if (_node.kind == "Return") && (_stmt.argument != undefined) {
			_cx.self_instance = _events && (!array_contains(_inWith, _stmt));
			var _t = __gmlc_type_of(_stmt.argument, __gmlc_type_copy(_in[_preds[1][_q]]), _cx);
			_returns = gmlc_type_join(_returns, _t.type);
			if (_t.provenance == "annotated") _provenance = "annotated";
		}
		else if (_node.kind != "Throw") _returns = gmlc_type_join(_returns, "Undefined");
	_q++}
	if (_cx.diags != undefined) _cx.diags.returns[$ string(_cx.file) + ":" + string(_unit.fn_id)] = { type: _returns, provenance: _provenance };
	var _locals = [];
	var _end = _in[1];
	var _names = struct_get_names(_end);
	array_sort(_names, true);
	var _k = 0; repeat (array_length(_names)) {
		var _f = _end[$ _names[_k]];
		array_push(_locals, { name: _names[_k], type: _f.type, provenance: _f.provenance, assigned: _f.assigned });
	_k++}
	// a fact an annotation took part in is not proven, so it holds an unknown type here
	_i = 0; repeat (_n * 2) {
		var _st = (_i < _n) ? _in[_i] : _out[_i - _n];
		if (_st != undefined) {
			var _keys = struct_get_names(_st);
			_k = 0; repeat (array_length(_keys)) {
				var _fact = _st[$ _keys[_k]];
				var _ty = (_fact.provenance == "proven") ? _fact.type : "Unknown";
				_held[$ _keys[_k]] = gmlc_type_join(_held[$ _keys[_k]] ?? "Never", _ty);
			_k++}
		}
	_i++}
	return { fn_id: _unit.fn_id, name: _name, returns: _returns, returns_provenance: _provenance, locals: _locals };
}

#region jsDoc
/// @func    __gmlc_type_check_root(_site)
/// @desc    The expression of a flow node that is checked for operations that always throw: the test of a branch or
///          loop, the statement itself otherwise; undefined for a node that holds none.
/// @param   {Struct} _site : A node of the control flow graph
/// @returns {Struct|Undefined}
#endregion
function __gmlc_type_check_root(_site) {
	var _stmt = _site.stmt;
	if (_stmt == undefined) || (_site.kind == "catch") || (_site.kind == "finally") return undefined;
	switch (_stmt.kind) {
		case __GMLC_NodeKind_If: case __GMLC_NodeKind_While: case __GMLC_NodeKind_DoUntil: case __GMLC_NodeKind_Case: return _stmt.test;
		case __GMLC_NodeKind_For: return _stmt.test;
		case __GMLC_NodeKind_Repeat: return _stmt.count;
		case __GMLC_NodeKind_With: return _stmt.target;
		case __GMLC_NodeKind_Switch: return _stmt.discriminant;
		case __GMLC_NodeKind_Try: case __GMLC_NodeKind_Default: case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl: return undefined;
	}
	return _stmt;
}

#region jsDoc
/// @func    __gmlc_type_check_operands(_node, _state, _cx)
/// @desc    Reports, under a node (nested functions left out), each operator whose operands have proven types
///          GameMaker throws for, whatever the values are.
/// @param   {Struct} _node  : The node
/// @param   {Struct} _state : The facts where the node runs
/// @param   {Struct} _cx    : The typing context
#endregion
function __gmlc_type_check_operands(_node, _state, _cx) {
	switch (_node.kind) {
		case __GMLC_NodeKind_FunctionExpr: case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl: return;
		case __GMLC_NodeKind_Binary:
			__gmlc_type_report_throw(_node.op, __gmlc_type_of(_node.left, __gmlc_type_copy(_state), _cx), __gmlc_type_of(_node.right, __gmlc_type_copy(_state), _cx), _node.span, _cx);
			break;
		case __GMLC_NodeKind_Assign:
			if (_node.op != "=") && (_node.op != "??=") {
				var _op = string_copy(_node.op, 1, string_length(_node.op) - 1);
				__gmlc_type_report_throw(_op, __gmlc_type_of(_node.target, __gmlc_type_copy(_state), _cx), __gmlc_type_of(_node.value, __gmlc_type_copy(_state), _cx), _node.span, _cx);
			}
			break;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_check_operands(_child, _state, _cx);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_report_throw(_op, _a, _b, _span, _cx)
/// @desc    Records GMLC3020 when the operator throws for the operand types.
/// @param   {String} _op   : The operator
/// @param   {Struct} _a    : The left operand's {type, provenance}
/// @param   {Struct} _b    : The right operand's {type, provenance}
/// @param   {Struct} _span : Where it is reported
/// @param   {Struct} _cx   : The typing context
#endregion
function __gmlc_type_report_throw(_op, _a, _b, _span, _cx) {
	if (!__gmlc_type_always_throws(_op, _a, _b)) return;
	var _args = [_op, _a.type, _b.type];
	var _found = _cx.diags.found;
	var _i = 0; repeat (array_length(_found)) {
		var _old = _found[_i];
		if (_old.span.file == _span.file) && (_old.span.start == _span.start) && (_old.span.end == _span.end) && (_old.args[0] == _args[0]) && (_old.args[1] == _args[1]) && (_old.args[2] == _args[2]) return;
	_i++}
	array_push(_found, { code: "GMLC3020", span: _span, args: _args });
}

#region jsDoc
/// @func    __gmlc_type_always_throws(_op, _a, _b)
/// @desc    Whether an arithmetic or bitwise operator throws for every pair of members of two proven operand types
///          (`__gmlc_type_atom_binary` gives nothing). A member of a kind the model does
///          not settle (an id, a pointer, a function) is never reported.
/// @param   {String} _op : The operator
/// @param   {Struct} _a  : The left operand's {type, provenance}
/// @param   {Struct} _b  : The right operand's {type, provenance}
/// @returns {Bool}
#endregion
function __gmlc_type_always_throws(_op, _a, _b) {
	static __ops = ["+", "-", "*", "/", "mod", "div", "&", "|", "^", "<<", ">>"];
	if (!array_contains(__ops, _op)) return false;
	if (_a.provenance != "proven") || (_b.provenance != "proven") return false;
	var _xs = __gmlc_type_members(_a.type);
	var _ys = __gmlc_type_members(_b.type);
	if (array_length(_xs) == 0) || (array_length(_ys) == 0) return false;
	var _x = 0; repeat (array_length(_xs)) {
		if (!__gmlc_type_firm(_xs[_x])) return false;
	_x++}
	var _y = 0; repeat (array_length(_ys)) {
		if (!__gmlc_type_firm(_ys[_y])) return false;
	_y++}
	_x = 0; repeat (array_length(_xs)) {
		_y = 0; repeat (array_length(_ys)) {
			if (__gmlc_type_atom_binary(_op, _xs[_x], _ys[_y]) != undefined) return false;
		_y++}
	_x++}
	return true;
}

#region jsDoc
/// @func    __gmlc_type_firm(_atom)
/// @desc    Whether the value model settles what an operator does with an atom: a number, a string, `undefined`, a
///          struct or an array.
/// @param   {String} _atom : The atom
/// @returns {Bool}
#endregion
function __gmlc_type_firm(_atom) {
	if (_atom == "Never") || (_atom == "Unknown") || (_atom == "Any") return false;
	return (__gmlc_type_kind(_atom) != "o") || (_atom == "Undefined") || (string_starts_with(_atom, "Struct")) || (string_starts_with(_atom, "Array"));
}

#region jsDoc
/// @func    gmlc_type_diagnostics(_asts, _sources, _batch)
/// @desc    The type diagnostics of a whole project's lowered scripts: GMLC3019 for a function whose proven return
///          type shares no member with its JSDoc `@returns` type, and GMLC3020 for an operation that always throws.
/// @param   {Array<Struct.ASTScript>} _asts    : The lowered scripts
/// @param   {Struct.GMLC_SourceTable} _sources : Their files
/// @param   {Struct}                  _batch   : {returns, params, fields, ...} (gmlc_type_batch)
/// @returns {Array<Struct>} {code, span, args}; GMLC3019 args are [function, JSDoc type, returned type] with the
///          function's span, GMLC3020 args are [operator, left type, right type]
#endregion
function gmlc_type_diagnostics(_asts, _sources, _batch) {
	var _out = [];
	var _a = 0; repeat (array_length(_asts)) {
		var _ast = _asts[_a];
		if (_ast.kind == __GMLC_NodeKind_Script) {
			var _diagnostics = { found: [], returns: {} };
			__gmlc_type_run(_ast, _sources, false, _batch, undefined, _diagnostics);
			var _units = [{ fn_id: 0, params: [], body: _ast.body, node: undefined }];
			__gmlc_analysis_units(_ast, _units);
			array_sort(_units, __gmlc_compare_fn_id);
			// a constructor no code of the project calls makes no struct, so its body and methods never run: what they do
			// is not reported (they are typed with values no call gives them)
			var _unreached = [];
			var _r = 0; repeat (array_length(_units)) {
				var _unitNode = _units[_r].node;
				if (_unitNode != undefined) && (_unitNode.kind == __GMLC_NodeKind_ConstructorDecl) {
					var _unitParams = _batch.params[$ _unitNode.name];
					if (_unitParams != undefined) && (array_contains(_unitParams, "Never")) array_push(_unreached, _unitNode.span);
				}
			_r++}
			var _kept = [];
			var _f = 0; repeat (array_length(_diagnostics.found)) {
				var _span = _diagnostics.found[_f].span;
				var _inside = false;
				var _s = 0; repeat (array_length(_unreached)) {
					if (_unreached[_s].file == _span.file) && (_unreached[_s].start <= _span.start) && (_span.end <= _unreached[_s].end) _inside = true;
				_s++}
				if (!_inside) array_push(_kept, _diagnostics.found[_f]);
			_f++}
			_diagnostics.found = _kept;
			var _u = 0; repeat (array_length(_units)) {
				var _node = _units[_u].node;
				var _got = _diagnostics.returns[$ string(_ast.span.file) + ":" + string(_units[_u].fn_id)];
				if (_node != undefined) && (_node.kind == __GMLC_NodeKind_FunctionDecl) && (_got != undefined) && (_got.provenance == "proven") {
					var _doc = __gmlc_type_jsdoc_returns(_node, _sources);
					var _members = __gmlc_type_members(_got.type);
					var _reportable = (_doc != undefined) && (array_length(_members) > 0);
					// a function no call of the project reaches returns only what its typing could follow without values
					var _params = _batch.params[$ _node.name];
					if (_params != undefined) && (array_contains(_params, "Never")) _reportable = false;
					var _m = 0; repeat (array_length(_members)) {
						if (_members[_m] == "Never") || (_members[_m] == "Unknown") || (_members[_m] == "Any") || (_reportable && __gmlc_type_takes(_doc, _members[_m])) _reportable = false;
					_m++}
					if (_reportable) array_push(_out, { code: "GMLC3019", span: _node.span, args: [_node.name, _doc, _got.type] });
				}
			_u++}
			_out = array_concat(_out, _diagnostics.found);
		}
	_a++}
	return _out;
}

#region jsDoc
/// @func    __gmlc_type_copy(_state)
/// @desc    A copy of a state, each fact copied.
/// @param   {Struct} _state : Local name to {type, provenance, assigned}
/// @returns {Struct}
#endregion
function __gmlc_type_copy(_state) {
	var _out = {};
	var _names = struct_get_names(_state);
	var _i = 0; repeat (array_length(_names)) {
		var _f = _state[$ _names[_i]];
		_out[$ _names[_i]] = { type: _f.type, provenance: _f.provenance, assigned: _f.assigned };
	_i++}
	return _out;
}

#region jsDoc
/// @func    __gmlc_type_merge(_a, _b)
/// @desc    Two states joined where control meets: a fact on one side only may be unassigned.
#endregion
function __gmlc_type_merge(_a, _b) {
	var _names = array_concat(struct_get_names(_a), struct_get_names(_b));
	var _out = {};
	var _i = 0; repeat (array_length(_names)) {
		var _name = _names[_i];
		if (_out[$ _name] == undefined) {
			var _x = _a[$ _name];
			var _y = _b[$ _name];
			if (_x != undefined) && (_y != undefined) {
				_out[$ _name] = {
					type: gmlc_type_join(_x.type, _y.type),
					provenance: __gmlc_type_prov(_x, _y),
					assigned: ((_x.assigned == "yes") && (_y.assigned == "yes")) ? "yes" : "maybe",
				};
			}
			else {
				var _f = _x ?? _y;
				_out[$ _name] = { type: _f.type, provenance: _f.provenance, assigned: "maybe" };
			}
		}
	_i++}
	return _out;
}

#region jsDoc
/// @func    __gmlc_type_same(_a, _b)
/// @desc    Whether two states hold the same facts.
/// @param   {Struct} _a : A state
/// @param   {Struct} _b : A state
/// @returns {Bool}
#endregion
function __gmlc_type_same(_a, _b) {
	var _names = struct_get_names(_a);
	if (array_length(_names) != array_length(struct_get_names(_b))) return false;
	var _i = 0; repeat (array_length(_names)) {
		var _x = _a[$ _names[_i]];
		var _y = _b[$ _names[_i]];
		if (_y == undefined) || (_x.type != _y.type) || (_x.provenance != _y.provenance) || (_x.assigned != _y.assigned) return false;
	_i++}
	return true;
}

#region jsDoc
/// @func    __gmlc_type_set(_state, _name, _t, _maybe)
/// @desc    A write of a local into the state; _maybe when it may not happen.
#endregion
function __gmlc_type_set(_state, _name, _t, _maybe) {
	var _old = _state[$ _name];
	if (!_maybe) || (_old == undefined) {
		_state[$ _name] = { type: _t.type, provenance: _t.provenance, assigned: _maybe ? "maybe" : "yes" };
		return;
	}
	_state[$ _name] = {
		type: gmlc_type_join(_old.type, _t.type),
		provenance: __gmlc_type_prov(_old, _t),
		assigned: _old.assigned,
	};
}

#region jsDoc
/// @func    __gmlc_type_node(_node, _state, _cx)
/// @desc    What a node does to the state: the writes of the expressions it evaluates itself.
#endregion
function __gmlc_type_node(_node, _state, _cx) {
	var _stmt = _node.stmt;
	if (_stmt == undefined) return;
	switch (_node.kind) {
		case "catch":
			if (_stmt.catch_param != undefined) && (__gmlc_opt_is_local(_stmt.catch_param)) {
				__gmlc_type_set(_state, _stmt.catch_param.name, { type: "Unknown", provenance: "proven" }, false);
				__gmlc_type_add_flow("l:" + string(_cx.file) + ":" + string(_cx.fn_id) + ":" + _stmt.catch_param.name, "?", _cx);
			}
			return;
		case "finally": return;
	}
	switch (_stmt.kind) {
		case __GMLC_NodeKind_If: case __GMLC_NodeKind_While: case __GMLC_NodeKind_DoUntil: case __GMLC_NodeKind_Case:
			__gmlc_type_walk(_stmt.test, _state, _cx, false); return;
		case __GMLC_NodeKind_For:
			if (_stmt.test != undefined) __gmlc_type_walk(_stmt.test, _state, _cx, false);
			return;
		case __GMLC_NodeKind_Repeat: __gmlc_type_walk(_stmt.count, _state, _cx, false); return;
		case __GMLC_NodeKind_With: __gmlc_type_walk(_stmt.target, _state, _cx, false); return;
		case __GMLC_NodeKind_Switch: __gmlc_type_walk(_stmt.discriminant, _state, _cx, false); return;
		case __GMLC_NodeKind_Try: case __GMLC_NodeKind_Default: return;
		case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl: return;
	}
	__gmlc_type_walk(_stmt, _state, _cx, false);
}

#region jsDoc
/// @func    __gmlc_type_walk(_node, _state, _cx, _maybe)
/// @desc    The writes of locals in an expression or a simple statement, in evaluation order.
#endregion
function __gmlc_type_walk(_node, _state, _cx, _maybe) {
	if (_node == undefined) return;
	// what each instance variable and static is read as, for the optimizer
	if (_node.kind == __GMLC_NodeKind_Identifier) && (_cx.self_reads != undefined) && (_node.symbol != undefined)
	&& ((_node.symbol.kind == "Self") || (_node.symbol.kind == "Static")) {
		var _read = __gmlc_type_of(_node, __gmlc_type_copy(_state), _cx);
		_cx.self_reads[$ _node.name] = gmlc_type_join(_cx.self_reads[$ _node.name] ?? "Never", (_read.provenance == "proven") ? _read.type : "Unknown");
	}
	switch (_node.kind) {
		case __GMLC_NodeKind_FunctionExpr: case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl:
			return;
		case __GMLC_NodeKind_VarDecl:
			__gmlc_type_walk(_node.init, _state, _cx, _maybe);
			if (_node.init != undefined) __gmlc_type_flow(_node.target, _node.init, _state, _cx);
			if (__gmlc_opt_is_local(_node.target)) {
				var _t = (_node.init != undefined) ? __gmlc_type_of(_node.init, _state, _cx) : { type: "Undefined", provenance: "proven" };
				__gmlc_type_set(_state, _node.target.name, _t, _maybe);
			}
			else {
				// a static
				var _static = __gmlc_type_field_of(_node.target);
				if (_static != undefined) && (_static.name != undefined) {
					var _st = (_node.init != undefined) ? __gmlc_type_of(_node.init, _state, _cx) : { type: "Undefined", provenance: "proven" };
					__gmlc_type_content_write(__gmlc_type_holder_of(_node.target, _state, _cx), _st, _cx);
					__gmlc_type_record_field(_static.name, _st, _cx);
				}
			}
			return;
		case __GMLC_NodeKind_Assign:
			if (_node.op == "=") || (_node.op == "??=") __gmlc_type_flow(_node.target, _node.value, _state, _cx);
			__gmlc_type_element_write(_node.target, _node.value, _node.op, _state, _cx);
			if (__gmlc_opt_is_local(_node.target)) {
				var _cur = __gmlc_type_of(_node.target, _state, _cx);
				var _conditional = _maybe || (_node.op == "??=");
				__gmlc_type_walk(_node.value, _state, _cx, _conditional);
				var _v = __gmlc_type_of(_node.value, _state, _cx);
				var _t;
				if (_node.op == "=") _t = _v;
				else if (_node.op == "??=") _t = { type: gmlc_type_join(__gmlc_type_remove(_cur.type, "Undefined"), _v.type), provenance: __gmlc_type_prov(_cur, _v) };
				else _t = { type: __gmlc_type_binary(string_copy(_node.op, 1, string_length(_node.op) - 1), _cur.type, _v.type), provenance: __gmlc_type_prov(_cur, _v) };
				__gmlc_type_set(_state, _node.target.name, _t, _conditional);
				return;
			}
			// a name assigned is not read
			if (!((_node.op == "=") && (_node.target.kind == __GMLC_NodeKind_Identifier))) __gmlc_type_walk(_node.target, _state, _cx, _maybe);
			__gmlc_type_walk(_node.value, _state, _cx, _maybe);
			var _field = __gmlc_type_field_of(_node.target);
			if (_field != undefined) {
				var _fholder = __gmlc_type_holder_of(_node.target, _state, _cx);
				_field.name = __gmlc_type_wildcard_key(_field.name, _node.target, _state, _cx);
				var _fv = __gmlc_type_of(_node.value, _state, _cx);
				var _fcur = (_node.op == "=") ? { type: "Never", provenance: "proven" } : __gmlc_type_of(_node.target, _state, _cx);
				if (_fcur.type == "Never") && (_node.op != "=") _fcur = { type: __gmlc_type_field_now(_field.name, _cx), provenance: "proven" };
				var _ft;
				if (_node.op == "=") _ft = _fv;
				else if (_node.op == "??=") _ft = { type: gmlc_type_join(__gmlc_type_remove(_fcur.type, "Undefined"), _fv.type), provenance: _fv.provenance };
				else _ft = { type: __gmlc_type_binary(string_copy(_node.op, 1, string_length(_node.op) - 1), _fcur.type, _fv.type), provenance: _fv.provenance };
				__gmlc_type_content_write(_fholder, _ft, _cx);
				__gmlc_type_record_field(_field.name, _ft, _cx);
				if (_field.name == "|list") __gmlc_type_record_field(_field.name, { type: "Real", provenance: "proven" }, _cx);
			}
			return;
		case __GMLC_NodeKind_Update:
			__gmlc_type_walk(_node.argument, _state, _cx, _maybe);
			if (__gmlc_opt_is_local(_node.argument)) {
				var _cur = __gmlc_type_of(_node.argument, _state, _cx);
				__gmlc_type_set(_state, _node.argument.name, { type: __gmlc_type_binary(string_char_at(_node.op, 1), _cur.type, "Int"), provenance: _cur.provenance }, _maybe);
			}
			else {
				var _updated = __gmlc_type_field_of(_node.argument);
				if (_updated != undefined) {
					var _uholder = __gmlc_type_holder_of(_node.argument, _state, _cx);
					var _uread = __gmlc_type_of(_node.argument, _state, _cx).type;
					_updated.name = __gmlc_type_wildcard_key(_updated.name, _node.argument, _state, _cx);
					var _ucur = gmlc_type_join(_uread, __gmlc_type_field_now(_updated.name, _cx));
					var _ut = { type: __gmlc_type_binary(string_char_at(_node.op, 1), _ucur, "Int"), provenance: "proven" };
					__gmlc_type_content_write(_uholder, _ut, _cx);
					__gmlc_type_record_field(_updated.name, _ut, _cx);
				}
			}
			return;
		case __GMLC_NodeKind_Logical:
			__gmlc_type_walk(_node.left, _state, _cx, _maybe);
			__gmlc_type_walk(_node.right, _state, _cx, _maybe || (_node.op != "^^"));
			return;
		case __GMLC_NodeKind_Nullish:
			__gmlc_type_walk(_node.left, _state, _cx, _maybe);
			__gmlc_type_walk(_node.right, _state, _cx, true);
			return;
		case __GMLC_NodeKind_Conditional:
			__gmlc_type_walk(_node.test, _state, _cx, _maybe);
			__gmlc_type_walk(_node.consequent, _state, _cx, true);
			__gmlc_type_walk(_node.alternate, _state, _cx, true);
			return;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_walk(_child, _state, _cx, _maybe);
			}
		_i++}
	_field_index++}
	__gmlc_type_record_call(_node, _state, _cx);
	__gmlc_type_record_arrays(_node, _state, _cx);
	if (_node.kind == __GMLC_NodeKind_StructLiteral) {
		// the values are typed after the whole literal ran, so a local one of them writes is unknown
		var _writes = false;
		var _e = 0; repeat (array_length(_node.entries)) {
			if (__gmlc_type_writes_local(_node.entries[_e])) _writes = true;
		_e++}
		_e = 0; repeat (array_length(_node.entries)) {
			var _entry = _node.entries[_e];
			if (_entry.kind == __GMLC_NodeKind_StructEntry) {
				var _et = _writes ? { type: "Unknown", provenance: "proven" } : __gmlc_type_of(_entry.value, __gmlc_type_copy(_state), _cx);
				__gmlc_type_content_write("n:" + string(_cx.file) + ":" + string(_node.span.start) + "#" + _entry.key, _et, _cx);
				__gmlc_type_record_field(_entry.key, _et, _cx);
			}
		_e++}
	}
	else if (_node.kind == __GMLC_NodeKind_Call) {
		var _dsName = __gmlc_type_builtin_name(_node);
		if (_dsName != undefined) {
			var _dsWriter = __gmlc_type_ds_writer(_dsName);
			if (_dsWriter != undefined) {
				var _dsWrites = false;
				var _dw = 0; repeat (array_length(_node.args)) {
					if (__gmlc_type_writes_local(_node.args[_dw])) _dsWrites = true;
				_dw++}
				var _dsLast = _dsWriter.more ? array_length(_node.args) : min(_dsWriter.from + 1, array_length(_node.args));
				var _dv = _dsWriter.from; repeat (max(0, _dsLast - _dsWriter.from)) {
					var _dt = _dsWrites ? { type: "Unknown", provenance: "proven" } : __gmlc_type_of(_node.args[_dv], __gmlc_type_copy(_state), _cx);
					__gmlc_type_record_field(_dsWriter.kind, _dt, _cx);
				_dv++}
			}
			var _dsFill = __gmlc_type_ds_fill(_dsName);
			if (_dsFill != undefined) __gmlc_type_record_field(_dsFill.kind, { type: _dsFill.type, provenance: "proven" }, _cx);
		}
		var _set = __gmlc_type_setter(_node);
		if (_set != undefined) && (_set.name != undefined) {
			var _setName = _set.name;
			var _builtin = __gmlc_type_builtin_name(_node);
			if (_setName == "*") && (_builtin != "variable_global_set") && (array_length(_node.args) > 0) {
				_setName = "*" + __gmlc_type_owner_class(_node.args[0], __gmlc_type_copy(_state), _cx);
			}
			var _argWrites = false;
			var _w = 0; repeat (array_length(_node.args)) {
				if (__gmlc_type_writes_local(_node.args[_w])) _argWrites = true;
			_w++}
			var _sv;
			if (_set.value >= array_length(_node.args)) _sv = { type: "Undefined", provenance: "proven" };
			else if (_argWrites) _sv = { type: "Unknown", provenance: "proven" };
			else _sv = __gmlc_type_of(_node.args[_set.value], __gmlc_type_copy(_state), _cx);
			var _setOwner = (_builtin == "variable_global_set") ? "gl" : ((array_length(_node.args) > 0) ? __gmlc_type_holder_of(_node.args[0], __gmlc_type_copy(_state), _cx) : undefined);
			var _setField = (string_char_at(_setName, 1) == "*") ? "*" : _setName;
			__gmlc_type_content_write((_setOwner != undefined) ? _setOwner + "#" + _setField : undefined, _sv, _cx);
			__gmlc_type_record_field(_setName, _sv, _cx);
		}
	}
}

#region jsDoc
/// @func    __gmlc_type_prov(_a, _b)
/// @desc    The provenance of a fact made from two: annotated when either one is.
/// @param   {Struct} _a : A fact
/// @param   {Struct} _b : A fact
/// @returns {String}
#endregion
function __gmlc_type_prov(_a, _b) {
	return ((_a.provenance == "annotated") || (_b.provenance == "annotated")) ? "annotated" : "proven";
}

#region jsDoc
/// @func    __gmlc_type_self_holders(_ast, _infos, _cx)
/// @desc    Where `self` lives in each function of a file, in the statements of each `with` body, and where each
///          function's statics live, set into `_cx.selfs`, `_cx.with_selfs` and `_cx.statics`: an object event's own
///          code runs on an instance (`i`), a constructor on its struct (`c:<name>`), a global function only the
///          project's own calls reach on its callers' `self` (`g:<name>`), a static method on what it is called on
///          (`m:<name>`), any other function literal on the `self` it was made in, a `with` body on its target;
///          anything else `?`. `with_selfs` is {nodes, holders}: the nodes under `with` bodies and the holder of each.
/// @param   {Struct.ASTScript} _ast   : A lowered script
/// @param   {Array<Struct>}    _infos : The file's function table
/// @param   {Struct}           _cx    : The typing context
#endregion
function __gmlc_type_self_holders(_ast, _infos, _cx) {
	var _file = _ast.span.file;
	var _top = _cx.object_file ? "i" : (_cx.script_file ? "gl" : "?");
	_cx.selfs[$ "0"] = _top;
	_cx.statics[$ "0"] = "st:" + string(_file) + ":0";
	__gmlc_type_self_walk(_ast, _top, 0, _file, _infos, _cx, undefined);
}

#region jsDoc
/// @func    __gmlc_type_self_syntax(_node, _own, _file, _fn_id, _statics)
/// @desc    The holder a `with` target names, by its syntax.
/// @param   {Struct.ASTNode} _node    : The target
/// @param   {String}         _own     : The holder of `self` where the `with` is
/// @param   {Real}           _file    : The file's id
/// @param   {Real}           _fn_id   : The function the `with` is in
/// @param   {String}         _statics : The holder of that function's statics
/// @returns {String}
#endregion
function __gmlc_type_self_syntax(_node, _own, _file, _fn_id, _statics) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Identifier:
			if (_node.symbol == undefined) return "?";
			switch (_node.symbol.kind) {
				case "Asset": return "i";
				case "Local": return "l:" + string(_file) + ":" + string(_fn_id) + ":" + _node.name;
				case "Self": return _own + "#" + _node.name;
				case "Static": return _statics + "#" + _node.name;
				case "Global": return "gl#" + _node.name;
				case "BuiltinVar": case "BuiltinConstant":
					switch (_node.name) {
						case "all": return "i";
						case "global": return "gl";
						case "self": case "id": return _own;
						case "other": return (_own == "i") ? "i" : "?";
					}
					return "?";
			}
			return "?";
		case __GMLC_NodeKind_Index:
			if (_node.accessor == "Dot") && (_node.member != undefined) return __gmlc_type_self_syntax(_node.object, _own, _file, _fn_id, _statics) + "#" + _node.member;
			// an element of an array or a cell of a list
			if (_node.accessor == "Array") || (_node.accessor == "ArrayAt") || (_node.accessor == "List") {
				var _base = __gmlc_type_self_syntax(_node.object, _own, _file, _fn_id, _statics);
				return (_base == "?") ? _base : "e:" + _base;
			}
			return "?";
	}
	return "?";
}

#region jsDoc
/// @func    __gmlc_type_self_mark(_node, _holder, _cx)
/// @desc    Records the holder of `self` for every node under a `with` body, nested functions left out; a node marked
///          again (a `with` inside a `with`) takes the later holder.
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {String}         _holder : The holder
/// @param   {Struct}         _cx     : The typing context
#endregion
function __gmlc_type_self_mark(_node, _holder, _cx) {
	switch (_node.kind) {
		case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl: case __GMLC_NodeKind_FunctionExpr: return;
	}
	var _marks = _cx.with_selfs;
	var _at = array_get_index(_marks.nodes, _node);
	if (_at >= 0) _marks.holders[_at] = _holder;
	else {
		array_push(_marks.nodes, _node);
		array_push(_marks.holders, _holder);
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_self_mark(_child, _holder, _cx);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_with_self(_cx, _stmt)
/// @desc    The holder of `self` in a statement under a `with` body, or undefined for any other statement.
/// @param   {Struct}         _cx   : The typing context
/// @param   {Struct.ASTNode} _stmt : The statement
/// @returns {String|Undefined}
#endregion
function __gmlc_type_with_self(_cx, _stmt) {
	var _marks = _cx.with_selfs;
	if (array_length(_marks.nodes) == 0) return undefined;
	var _at = array_get_index(_marks.nodes, _stmt);
	return (_at >= 0) ? _marks.holders[_at] : undefined;
}

#region jsDoc
/// @func    __gmlc_type_self_enter(_id, _holder, _statics, _body, _file, _infos, _cx)
/// @desc    Records the holders of `self` and of the statics of a function and walks its body.
/// @param   {Real|Undefined} _id      : The function's id
/// @param   {String}         _holder  : Where its `self` lives
/// @param   {String}         _statics : Where its statics live
/// @param   {Struct.ASTNode} _body    : Its body
/// @param   {Real}           _file    : The file's id
/// @param   {Array<Struct>}  _infos   : The file's function table
/// @param   {Struct}         _cx      : The typing context
#endregion
function __gmlc_type_self_enter(_id, _holder, _statics, _body, _file, _infos, _cx) {
	if (_id == undefined) return;
	_cx.selfs[$ string(_id)] = _holder;
	_cx.statics[$ string(_id)] = _statics;
	__gmlc_type_self_walk(_body, _holder, _id, _file, _infos, _cx, undefined);
}

#region jsDoc
/// @func    __gmlc_type_self_walk(_node, _own, _fn_id, _file, _infos, _cx, _method)
/// @desc    Walks a node for the functions and `with` statements under it (__gmlc_type_self_holders).
/// @param   {Struct.ASTNode}   _node   : The node
/// @param   {String}           _own    : The holder of `self` where the node is
/// @param   {Real}             _fn_id  : The function the node is in
/// @param   {Real}             _file   : The file's id
/// @param   {Array<Struct>}    _infos  : The file's function table
/// @param   {Struct}           _cx     : The typing context
/// @param   {String|Undefined} _method : The static a function literal is stored in, or undefined
#endregion
function __gmlc_type_self_walk(_node, _own, _fn_id, _file, _infos, _cx, _method) {
	switch (_node.kind) {
		case __GMLC_NodeKind_FunctionDecl:
			var _info = ((_node.fn_id != undefined) && (_node.fn_id < array_length(_infos))) ? _infos[_node.fn_id] : undefined;
			var _closed = (_info != undefined) && (_info.registration == "global") && (struct_exists(_cx.param_holders, _node.name));
			var _p = 0; repeat (array_length(_node.params)) {
				__gmlc_type_self_walk(_node.params[_p], _own, _fn_id, _file, _infos, _cx, undefined);
			_p++}
			// a function declared in an event or a function is a method bound to the `self` it is made in
			var _instance = (_info != undefined) && (_info.registration == "instance");
			__gmlc_type_self_enter(_node.fn_id, _closed ? "g:" + _node.name : (_instance ? _own : "?"), "st:" + string(_file) + ":" + string(_node.fn_id ?? 0), _node.body, _file, _infos, _cx);
			return;
		case __GMLC_NodeKind_ConstructorDecl:
			var _holder = "c:" + _node.name;
			var _q = 0; repeat (array_length(_node.params)) {
				__gmlc_type_self_walk(_node.params[_q], _own, _fn_id, _file, _infos, _cx, undefined);
			_q++}
			__gmlc_type_self_enter(_node.fn_id, _holder, _holder, _node.body, _file, _infos, _cx);
			return;
		case __GMLC_NodeKind_FunctionExpr:
			var _self = _own;
			if (_node.is_constructor) _self = "?";
			else if (_method != undefined) _self = "m:" + _method;
			__gmlc_type_self_enter(_node.fn_id, _self, "st:" + string(_file) + ":" + string(_node.fn_id ?? 0), _node.body, _file, _infos, _cx);
			return;
		case __GMLC_NodeKind_VarDecl:
			// a static method runs on the struct it is called on
			var _stored = undefined;
			if (_node.target.kind == __GMLC_NodeKind_Identifier) && (_node.init != undefined) && (_node.init.kind == __GMLC_NodeKind_FunctionExpr)
				&& (_node.target.symbol != undefined) && (_node.target.symbol.kind == "Static") {
				_stored = _node.target.name;
			}
			if (_node.init != undefined) __gmlc_type_self_walk(_node.init, _own, _fn_id, _file, _infos, _cx, _stored);
			return;
		case __GMLC_NodeKind_With:
			__gmlc_type_self_walk(_node.target, _own, _fn_id, _file, _infos, _cx, undefined);
			var _target = __gmlc_type_self_syntax(_node.target, _own, _file, _fn_id, _cx.statics[$ string(_fn_id)] ?? "?");
			__gmlc_type_self_mark(_node.body, _target, _cx);
			__gmlc_type_self_walk(_node.body, _target, _fn_id, _file, _infos, _cx, undefined);
			return;
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_self_walk(_child, _own, _fn_id, _file, _infos, _cx, undefined);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_param_places(_node, _file, _infos, _closed, _out)
/// @desc    Adds the array holders of the parameters of each function only the project's own calls reach: the
///          holder of its local `l:<file>:<fn_id>:<name>`.
/// @param   {Struct.ASTNode} _node   : The node
/// @param   {Real}           _file   : The file's id
/// @param   {Array<Struct>}  _infos  : The file's function table
/// @param   {Struct}         _closed : The closed functions (__gmlc_type_closed_functions)
/// @param   {Struct}         _out    : Function name to its parameter holders, added to
#endregion
function __gmlc_type_param_places(_node, _file, _infos, _closed, _out) {
	if ((_node.kind == __GMLC_NodeKind_FunctionDecl) || (_node.kind == __GMLC_NodeKind_ConstructorDecl)) && (_node.fn_id != undefined) && (_node.fn_id < array_length(_infos)) {
		var _info = _infos[_node.fn_id];
		if (_info != undefined) && (_info.registration == "global") && (_info.name != undefined) && (struct_exists(_closed, _info.name)) {
			var _holders = [];
			var _p = 0; repeat (array_length(_node.params)) {
				var _param = _node.params[_p];
				if (_param.kind == __GMLC_NodeKind_Param) && (__gmlc_opt_is_local(_param.target)) array_push(_holders, "l:" + string(_file) + ":" + string(_node.fn_id) + ":" + _param.target.name);
				else array_push(_holders, "?");
			_p++}
			_out[$ _info.name] = _holders;
		}
	}
	var _child_fields = _node.childFields;
	var _field_index = 0; repeat (array_length(_child_fields)) {
		var _child_value = _node[$ _child_fields[_field_index]];
		var _child_many = is_array(_child_value);
		var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
			var _child = _child_many ? _child_value[_i] : _child_value;
			if (_child != undefined) {
				__gmlc_type_param_places(_child, _file, _infos, _closed, _out);
			}
		_i++}
	_field_index++}
}

#region jsDoc
/// @func    __gmlc_type_split_hash(_holder)
/// @desc    A holder split at its last `#` into its base and its field.
/// @param   {String} _holder : The holder
/// @returns {Array<String>|Undefined} [base, field], or undefined for a holder with no `#`
#endregion
function __gmlc_type_split_hash(_holder) {
	var _at = string_last_pos("#", _holder);
	if (_at == 0) return undefined;
	return [string_copy(_holder, 1, _at - 1), string_delete(_holder, 1, _at)];
}

#region jsDoc
/// @func    __gmlc_type_holder_of(_node, _state, _cx)
/// @desc    Where an array value lives, so that every name that may hold the same array shares its element type: a
///          local (`l:<file>:<fn_id>:<name>`), a field of any owner (`<owner>#<name>`, `<owner>#*` for a computed
///          name), the elements of another holder (`e:<holder>`), the return value of a function only the project's own
///          calls reach (`r:<name>`), an array a literal or a built-in makes there (`n:<file>:<offset>`), a function
///          (`fn:<name>`, `fb:<built-in>`, `fl:<file>:<fn_id>`), or anything else (`?`, whose elements are of unknown
///          type). Undefined for a value that is never an array.
/// @param   {Struct.ASTNode} _node  : The value
/// @param   {Struct}         _state : The local facts
/// @param   {Struct}         _cx    : The typing context
/// @returns {String|Undefined}
#endregion
function __gmlc_type_holder_of(_node, _state, _cx) {
	switch (_node.kind) {
		case __GMLC_NodeKind_Identifier:
			var _kind = (_node.symbol != undefined) ? _node.symbol.kind : undefined;
			switch (_kind) {
				case "Local": return "l:" + string(_cx.file) + ":" + string(_cx.fn_id) + ":" + _node.name;
				case "Static": return (_cx.statics[$ string(_cx.fn_id)] ?? "?") + "#" + _node.name;
				case "Self": return _cx.self_holder + "#" + _node.name;
				case "Global":
					if ((!struct_exists(_cx.named, _node.name)) && (!struct_exists(_cx.batch, _node.name))) return "gl#" + _node.name;
					// a function's name used as a value is that function, a built-in's a function no call of it is followed to
					return "fn:" + _node.name;
				case "BuiltinFunction": return "fb:" + _node.name;
				case "Asset": return "i";
				case "BuiltinConstant": case "BuiltinVar":
					if (_kind == "BuiltinConstant") && (_node.name == "global") return "gl";
					// `id` is the instance running the code: its `self`
					if (_node.name == "self") || (_node.name == "id") return _cx.self_holder;
					if (_node.name == "other") return _cx.self_instance ? "i" : "?";
					// the argument array of a function its project's own calls reach, and its slots
					if (_kind == "BuiltinVar") && (string_starts_with(_node.name, "argument")) && (string_starts_with(_cx.ret, "r:"))
						&& (string_digits(string_delete(_node.name, 1, 8)) == string_delete(_node.name, 1, 8)) {
						var _argumentKey = string_delete(_cx.ret, 1, 2);
						return ((string_length(_node.name) == 8) ? "aa:" : "e:aa:") + _argumentKey;
					}
					return (_kind == "BuiltinVar") ? "?" : undefined;
			}
			return undefined;
		case __GMLC_NodeKind_Index:
			switch (_node.accessor) {
				case "Dot": case "Struct":
					var _owner = __gmlc_type_holder_of(_node.object, _state, _cx) ?? "?";
					var _field = __gmlc_type_field_of(_node);
					return _owner + "#" + ((_field != undefined) ? _field.name : "*");
				case "Array": case "ArrayAt":
					var _base = __gmlc_type_holder_of(_node.object, _state, _cx);
					if (_base == undefined) return undefined;
					return (_base == "?") ? _base : "e:" + _base;
				case "Array2D":
					var _rows = __gmlc_type_holder_of(_node.object, _state, _cx);
					if (_rows == undefined) return undefined;
					return (_rows == "?") ? _rows : "e:e:" + _rows;
				case "Map": case "List": case "Grid":
					var _container = __gmlc_type_holder_of(_node.object, _state, _cx);
					if (_container == undefined) return undefined;
					return (_container == "?") ? _container : "e:" + _container;
			}
			return "?";
		case __GMLC_NodeKind_ArrayLiteral:
			return "n:" + string(_cx.file) + ":" + string(_node.span.start);
		case __GMLC_NodeKind_Call:
			if (__gmlc_type_call_targets(_node, _state, _cx) != undefined) return "n:" + string(_cx.file) + ":" + string(_node.span.start);
			var _fn = _node.callee;
			if (_fn.kind != __GMLC_NodeKind_Identifier) || (_fn.symbol == undefined) return "?";
			if (_fn.symbol.kind == "BuiltinFunction") return __gmlc_type_builtin_holder(_node, _fn.name, _state, _cx);
			if (_fn.symbol.kind == "Global") && (struct_exists(_cx.param_holders, _fn.name)) return "r:" + _fn.name;
			if ((_fn.symbol.kind == "Self") || (_fn.symbol.kind == "Static")) && (struct_exists(_cx.param_holders, "m:" + _fn.name)) return "r:m:" + _fn.name;
			return "?";
		case __GMLC_NodeKind_MethodCall:
			if (struct_exists(_cx.param_holders, "m:" + _node.member)) return "r:m:" + _node.member;
			if (__gmlc_type_call_targets(_node, _state, _cx) != undefined) return "n:" + string(_cx.file) + ":" + string(_node.span.start);
			return "?";
		case __GMLC_NodeKind_Conditional: case __GMLC_NodeKind_Nullish: case __GMLC_NodeKind_StructLiteral:
			return "n:" + string(_cx.file) + ":" + string(_node.span.start);
		// a constructor named by its global name makes its struct
		case __GMLC_NodeKind_New:
			if (_node.callee.kind == __GMLC_NodeKind_Identifier) && (_node.callee.symbol != undefined) && (_node.callee.symbol.kind == "Global") return "c:" + _node.callee.name;
			return "?";
		// a function literal is that function
		case __GMLC_NodeKind_FunctionExpr:
			return ((!_node.is_constructor) && (_node.fn_id != undefined)) ? "fl:" + string(_cx.file) + ":" + string(_node.fn_id) : undefined;
		// an omitted argument (`f(a,, b)`) is undefined
		case __GMLC_NodeKind_Literal: case __GMLC_NodeKind_Binary: case __GMLC_NodeKind_Unary: case __GMLC_NodeKind_Logical:
		case __GMLC_NodeKind_TemplateString: case __GMLC_NodeKind_Empty:
			return undefined;
	}
	return "?";
}

#region jsDoc
/// @func    __gmlc_type_builtin_holder(_node, _name, _state, _cx)
/// @desc    Where the value a built-in gives lives: an element of the array it reads (`array_get`, `array_pop`, ...),
///          a field it reads by name (`variable_struct_get`), the function `method` or `method_get_index` gives
///          (`fa:` for `asset_get_index`), a new array it makes (`n:<file>:<offset>`), anything (`?`) when its data says
///          it may give any value, or undefined when it never gives an array.
/// @param   {Struct.ASTNode} _node  : The call
/// @param   {String}         _name  : The built-in
/// @param   {Struct}         _state : The local facts
/// @param   {Struct}         _cx    : The typing context
/// @returns {String|Undefined}
#endregion
function __gmlc_type_builtin_holder(_node, _name, _state, _cx) {
	var _args = _node.args;
	switch (_name) {
		case "array_get": case "array_first": case "array_last": case "array_pop": case "array_shift":
			var _base = (array_length(_args) > 0) ? __gmlc_type_holder_of(_args[0], _state, _cx) : undefined;
			if (_base == undefined) return undefined;
			return (_base == "?") ? _base : "e:" + _base;
		case "variable_struct_get": case "struct_get": case "variable_instance_get": case "variable_global_get":
			var _owner = "gl";
			var _at = 0;
			if (_name != "variable_global_get") {
				_owner = ((array_length(_args) > 0) ? __gmlc_type_holder_of(_args[0], _state, _cx) : undefined) ?? "?";
				_at = 1;
			}
			var _key = (_at < array_length(_args)) ? _args[_at] : undefined;
			if (_key != undefined) && (_key.kind == __GMLC_NodeKind_Literal) && (_key.ty == "string") return _owner + "#" + _key.value;
			return _owner + "#*";
		// `method(s, f)` is `f` bound to `s`; `method_get_index(m)` is the function `m` binds
		case "method":
			return (array_length(_args) > 1) ? __gmlc_type_holder_of(_args[1], _state, _cx) : undefined;
		case "method_get_index":
			return (array_length(_args) > 0) ? __gmlc_type_holder_of(_args[0], _state, _cx) : undefined;
		// a clone counts as the value it copies: its fields and elements hold what the original's may
		case "variable_clone":
			return (array_length(_args) > 0) ? __gmlc_type_holder_of(_args[0], _state, _cx) : undefined;
		// the asset a name gives may be a script's function: `fa:=<name>` for a written-out name, `fa:<start>` for the
		// functions whose names start with a computed name's written-out start (every one for none)
		case "asset_get_index":
			var _assetName = (array_length(_args) > 0) ? _args[0] : undefined;
			if (_assetName != undefined) && (_assetName.kind == __GMLC_NodeKind_Literal) && (_assetName.ty == "string") return "fa:=" + _assetName.value;
			return "fa:" + (((_assetName != undefined) ? __gmlc_type_literal_prefix(_assetName) : undefined) ?? "");
	}
	if (_name == "ds_map_find_value") || (__gmlc_type_ds_reader(_name) != undefined) {
		var _container = (array_length(_args) > 0) ? __gmlc_type_holder_of(_args[0], _state, _cx) : undefined;
		if (_container == undefined) return undefined;
		return (_container == "?") ? _container : "e:" + _container;
	}
	var _returns = _cx.builtins[$ _name] ?? "Unknown";
	if (string_starts_with(_returns, "Id.Instance")) || (string_starts_with(_returns, "Asset.GMObject")) return "i";
	if (string_starts_with(_returns, "Array")) || ((string_starts_with(_returns, "Id.Ds")) && (string_ends_with(_name, "_create"))) return "n:" + string(_cx.file) + ":" + string(_node.span.start);
	if (__gmlc_type_may_array(_returns)) return "?";
	return undefined;
}

#region jsDoc
/// @func    __gmlc_type_grouped(_holder, _cx)
/// @desc    Whether a holder is in a known group other than the unknown one: no struct a built-in parsed reaches it, as
///          every such struct is in the unknown group.
/// @param   {String|Undefined} _holder : The holder
/// @param   {Struct}           _cx     : The typing context
/// @returns {Bool}
#endregion
function __gmlc_type_grouped(_holder, _cx) {
	if (_holder == undefined) return false;
	var _group = __gmlc_type_group_of(_holder, _cx);
	return (_group != undefined) && (_group != "?") && (_group != "");
}

#region jsDoc
/// @func    __gmlc_type_no_elements(_cx)
/// @desc    The type of an element of a holder no array or element write reaches: in a whole project nothing yet (its
///          rounds start from no type, and an array that reaches a holder joins its group), elsewhere anything.
/// @param   {Struct} _cx : The typing context
/// @returns {String}
#endregion
function __gmlc_type_no_elements(_cx) {
	return (struct_names_count(_cx.params) == 0) ? "Unknown" : "Never";
}

#region jsDoc
/// @func    __gmlc_type_held_element(_node, _state, _cx)
/// @desc    What a value read from a ds container holds by its container's group: the group's element type, when it
///          is known.
/// @param   {Struct.ASTNode} _node  : The read
/// @param   {Struct}         _state : The local facts
/// @param   {Struct}         _cx    : The typing context
/// @returns {String|Undefined}
#endregion
function __gmlc_type_held_element(_node, _state, _cx) {
	var _holder = __gmlc_type_holder_of(_node, _state, _cx);
	if (_holder == undefined) return undefined;
	var _type = __gmlc_type_place_type(_holder, _cx.arrays, _cx.elements, _cx.escaped);
	return ((_type == undefined) || (_type == "Unknown")) ? undefined : _type;
}


#region jsDoc
/// @func    __gmlc_type_held_content(_node, _state, _cx)
/// @desc    What a field read holds by its holder's group (`x.f`, `self.f`): what is written to that field of that
///          group of structs or instances, with what writes through an owner of unknown group put under the name;
///          undefined when the group is not known (it may be reached from outside the code) or holds no write, which
///          the name-based types answer.
/// @param   {Struct.ASTNode} _node  : The read
/// @param   {Struct}         _state : The local facts
/// @param   {Struct}         _cx    : The typing context
/// @returns {String|Undefined}
#endregion
function __gmlc_type_held_content(_node, _state, _cx) {
	var _holder = __gmlc_type_holder_of(_node, _state, _cx);
	if (_holder == undefined) return undefined;
	var _split = __gmlc_type_split_hash(_holder);
	if (_split == undefined) || (_split[0] == "?") return undefined;
	var _baseGroup = __gmlc_type_group_of(_split[0], _cx);
	if (_baseGroup == undefined) || (_baseGroup == "?") return undefined;
	var _group = __gmlc_type_group_of(_holder, _cx);
	if (_group == undefined) || (_group == "?") return undefined;
	var _type = __gmlc_type_place_type(_holder, _cx.arrays, _cx.elements, _cx.escaped);
	if (_type == undefined) || (_type == "Never") return undefined;
	// writes through an owner of unknown group may have reached this field
	var _keys = ["?#" + _split[1], "?#*"];
	var _i = 0; repeat (2) {
		var _written = _cx.elements[$ _keys[_i]];
		if (_written != undefined) _type = gmlc_type_join(_type, _written);
	_i++}
	return _type;
}

#region jsDoc
/// @func    __gmlc_type_may_array(_type)
/// @desc    Whether a value of a type may be an array, a struct, an instance, a ds container, a function or an asset: a
///          value that other names may share (a function value is followed to the calls of it).
/// @param   {String} _type : The type
/// @returns {Bool}
#endregion
function __gmlc_type_may_array(_type) {
	var _members = __gmlc_type_members(_type);
	var _i = 0; repeat (array_length(_members)) {
		if (string_starts_with(_members[_i], "Array")) || (string_starts_with(_members[_i], "Struct")) || (string_starts_with(_members[_i], "Id.Instance"))
			|| (string_starts_with(_members[_i], "Id.Ds")) || (string_starts_with(_members[_i], "Function")) || (__gmlc_type_asset_holder(_members[_i]))
			|| (_members[_i] == "Unknown") || (_members[_i] == "Any") return true;
	_i++}
	return false;
}

#region jsDoc
/// @func    __gmlc_type_asset_holder(_member)
/// @desc    Whether an asset type may hold what a holder follows: an object (its instances) or a script (its
///          function); a sprite, sound, room, ... is a number.
/// @param   {String} _member : A member of a type
/// @returns {Bool}
#endregion
function __gmlc_type_asset_holder(_member) {
	return (_member == "Asset") || (_member == "Asset.GMObject") || (_member == "Asset.GMScript");
}

#region jsDoc
/// @func    __gmlc_type_add_flow(_a, _b, _cx)
/// @desc    Records that two holders may hold the same array.
/// @param   {String} _a  : A holder
/// @param   {String} _b  : A holder
/// @param   {Struct} _cx : The typing context
#endregion
function __gmlc_type_add_flow(_a, _b, _cx) {
	if (_a != _b) && (_cx.flows != undefined) array_push(_cx.flows, [_a, _b]);
}

#region jsDoc
/// @func    __gmlc_type_add_element(_holder, _type, _cx)
/// @desc    Joins a type into the elements of a holder's arrays.
/// @param   {String} _holder : The holder
/// @param   {String} _type   : The type
/// @param   {Struct} _cx     : The typing context
#endregion
function __gmlc_type_add_element(_holder, _type, _cx) {
	if (_cx.elems == undefined) return;
	_cx.elems[$ _holder] = gmlc_type_join(_cx.elems[$ _holder] ?? "Never", _type);
}

#region jsDoc
/// @func    __gmlc_type_flow(_target, _value, _state, _cx)
/// @desc    A value stored into a target: when it may be an array, the target's holder may hold the same array.
/// @param   {Struct.ASTNode} _target : The target
/// @param   {Struct.ASTNode} _value  : The value
/// @param   {Struct}         _state  : The local facts
/// @param   {Struct}         _cx     : The typing context
#endregion
function __gmlc_type_flow(_target, _value, _state, _cx) {
	if (_cx.flows == undefined) return;
	var _t = __gmlc_type_of(_value, _state, _cx);
	if (_t.provenance == "proven") && (!__gmlc_type_may_array(_t.type)) return;
	var _a = __gmlc_type_holder_of(_target, _state, _cx);
	var _b = __gmlc_type_holder_of(_value, _state, _cx);
	if (_a != undefined) && (_b != undefined) __gmlc_type_add_flow(_a, _b, _cx);
}

#region jsDoc
/// @func    __gmlc_type_content_write(_holder, _type, _cx)
/// @desc    A write into a field (`x.f = v`, `x[$ "f"] += v`, a setter): the value's type joins the contents of the
///          field's holder.
/// @param   {String|Undefined} _holder : The field's holder, or undefined
/// @param   {Struct}           _type   : The type written, {type, provenance}
/// @param   {Struct}           _cx     : The typing context
#endregion
function __gmlc_type_content_write(_holder, _type, _cx) {
	if (_holder == undefined) return;
	__gmlc_type_add_element(_holder, (_type.provenance == "proven") ? _type.type : "Unknown", _cx);
}

#region jsDoc
/// @func    __gmlc_type_element_write(_target, _value, _op, _state, _cx)
/// @desc    A write into an element of an array (`a[i] = v`, `a[i] += v`): the value's type joins the elements, and
///          the real 0 a write past the end fills the gap with.
/// @param   {Struct.ASTNode} _target : The target
/// @param   {Struct.ASTNode} _value  : The value
/// @param   {String}         _op     : The assignment operator
/// @param   {Struct}         _state  : The local facts
/// @param   {Struct}         _cx     : The typing context
#endregion
function __gmlc_type_element_write(_target, _value, _op, _state, _cx) {
	if (_cx.elems == undefined) || (_target.kind != __GMLC_NodeKind_Index) return;
	if (_target.accessor != "Array") && (_target.accessor != "ArrayAt") && (_target.accessor != "Array2D")
	&& (_target.accessor != "Map") && (_target.accessor != "List") && (_target.accessor != "Grid") return;
	var _holder = __gmlc_type_holder_of(_target, _state, _cx);
	if (_holder == undefined) return;
	var _v = __gmlc_type_of(_value, _state, _cx);
	var _type;
	if (_v.provenance != "proven") _type = "Unknown";
	else if (_op == "=") _type = _v.type;
	else if (_op == "??=") _type = gmlc_type_join(__gmlc_type_of(_target, _state, _cx).type, _v.type);
	else _type = __gmlc_type_binary(string_copy(_op, 1, string_length(_op) - 1), __gmlc_type_of(_target, _state, _cx).type, _v.type);
	__gmlc_type_add_element(_holder, _type, _cx);
	// a write past the end fills the gap with 0; a map key or a grid cell leaves no gap
	if (_target.accessor != "Map") && (_target.accessor != "Grid") __gmlc_type_add_element(_holder, "Int", _cx);
	// a two-index write makes the missing rows
	if (_target.accessor == "Array2D") && (string_starts_with(_holder, "e:")) {
		var _rows = string_delete(_holder, 1, 2);
		__gmlc_type_add_element(_rows, "Array<Any>", _cx);
		__gmlc_type_add_element(_rows, "Int", _cx);
	}
}

#region jsDoc
/// @func    __gmlc_type_record_arrays(_node, _state, _cx)
/// @desc    The array flows and element writes of one node other than an assignment: a return value, the arguments of
///          a call, the values of a struct literal or an array literal, the array a built-in makes.
/// @param   {Struct.ASTNode} _node  : The node
/// @param   {Struct}         _state : The local facts
/// @param   {Struct}         _cx    : The typing context
#endregion
function __gmlc_type_record_arrays(_node, _state, _cx) {
	if (_cx.flows == undefined) return;
	_state = __gmlc_type_copy(_state);
	switch (_node.kind) {
		case __GMLC_NodeKind_Return:
			if (_node.argument != undefined) {
				var _rt = __gmlc_type_of(_node.argument, _state, _cx);
				if (_rt.provenance != "proven") || (__gmlc_type_may_array(_rt.type)) {
					var _rh = __gmlc_type_holder_of(_node.argument, _state, _cx);
					if (_rh != undefined) __gmlc_type_add_flow(_cx.ret, _rh, _cx);
				}
			}
			return;
		case __GMLC_NodeKind_Throw:
			var _th = __gmlc_type_holder_of(_node.argument, _state, _cx);
			if (_th != undefined) __gmlc_type_add_flow("?", _th, _cx);
			return;
		case __GMLC_NodeKind_StructLiteral:
			var _e = 0; repeat (array_length(_node.entries)) {
				var _entry = _node.entries[_e];
				if (_entry.kind == __GMLC_NodeKind_StructEntry) {
					var _et = __gmlc_type_of(_entry.value, _state, _cx);
					if (_et.provenance != "proven") || (__gmlc_type_may_array(_et.type)) {
						var _eh = __gmlc_type_holder_of(_entry.value, _state, _cx);
						if (_eh != undefined) __gmlc_type_add_flow("n:" + string(_cx.file) + ":" + string(_node.span.start) + "#" + _entry.key, _eh, _cx);
					}
				}
			_e++}
			return;
		case __GMLC_NodeKind_ArrayLiteral:
			var _own = "n:" + string(_cx.file) + ":" + string(_node.span.start);
			var _x = 0; repeat (array_length(_node.elements)) {
				var _xt = __gmlc_type_of(_node.elements[_x], _state, _cx);
				__gmlc_type_add_element("e:" + _own, (_xt.provenance == "proven") ? _xt.type : "Unknown", _cx);
				var _xh = __gmlc_type_holder_of(_node.elements[_x], _state, _cx);
				if (_xh != undefined) __gmlc_type_add_flow("e:" + _own, _xh, _cx);
			_x++}
			return;
		case __GMLC_NodeKind_Conditional: case __GMLC_NodeKind_Nullish:
			var _here = "n:" + string(_cx.file) + ":" + string(_node.span.start);
			var _branches = (_node.kind == __GMLC_NodeKind_Conditional) ? [_node.consequent, _node.alternate] : [_node.left, _node.right];
			var _b = 0; repeat (2) {
				var _bh = __gmlc_type_holder_of(_branches[_b], _state, _cx);
				if (_bh != undefined) __gmlc_type_add_flow(_here, _bh, _cx);
			_b++}
			return;
		case __GMLC_NodeKind_Call:
			__gmlc_type_record_call_arrays(_node, _state, _cx);
			return;
		case __GMLC_NodeKind_New:
			var _params = undefined;
			if (_node.callee.kind == __GMLC_NodeKind_Identifier) && (_node.callee.symbol != undefined) && (_node.callee.symbol.kind == "Global") _params = _cx.param_holders[$ _node.callee.name];
			__gmlc_type_flow_arguments(_node.args, _params, _state, _cx);
			return;
		case __GMLC_NodeKind_MethodCall:
			var _fieldTargets = __gmlc_type_call_targets(_node, _state, _cx);
			if (_fieldTargets != undefined) {
				__gmlc_type_target_flows(_node, _fieldTargets, _state, _cx);
				return;
			}
			// the method runs with the object as its `self`
			var _oh = __gmlc_type_holder_of(_node.object, _state, _cx);
			if (_oh != undefined) __gmlc_type_add_flow("m:" + _node.member, _oh, _cx);
			__gmlc_type_flow_arguments(_node.args, _cx.param_holders[$ "m:" + _node.member], _state, _cx);
			return;
		// a method read as a value is bound to its owner
		case __GMLC_NodeKind_Index:
			if (_node.accessor == "Dot") && (_node.member != undefined) && (struct_exists(_cx.method_names, _node.member)) {
				var _mt = __gmlc_type_of(_node, _state, _cx);
				var _function = _mt.provenance != "proven";
				if (!_function) {
					var _mm = __gmlc_type_members(_mt.type);
					var _y = 0; repeat (array_length(_mm)) {
						if (string_starts_with(_mm[_y], "Function")) || (_mm[_y] == "Unknown") || (_mm[_y] == "Any") _function = true;
					_y++}
				}
				if (_function) && (_node.member != undefined) {
					var _mh = __gmlc_type_holder_of(_node.object, _state, _cx);
					if (_mh != undefined) __gmlc_type_add_flow("m:" + _node.member, _mh, _cx);
				}
			}
			return;
	}
}

#region jsDoc
/// @func    __gmlc_type_flow_arguments(_args, _params, _state, _cx)
/// @desc    The arguments of a call flow to the holders of the parameters, or to `?` where the callee has none.
/// @param   {Array<Struct.ASTNode>} _args   : The arguments
/// @param   {Array<String>}         _params : The holders of the parameters, or undefined
/// @param   {Struct}                _state  : The local facts
/// @param   {Struct}                _cx     : The typing context
#endregion
function __gmlc_type_flow_arguments(_args, _params, _state, _cx) {
	var _k = 0; repeat (array_length(_args)) {
		var _h = __gmlc_type_holder_of(_args[_k], _state, _cx);
		if (_h != undefined) __gmlc_type_add_flow(((_params != undefined) && (_k < array_length(_params))) ? _params[_k] : "?", _h, _cx);
	_k++}
}

#region jsDoc
/// @func    __gmlc_type_elements_of(_args, _k, _state, _cx)
/// @desc    The holder of the elements of the array an argument holds.
/// @param   {Array<Struct.ASTNode>} _args  : The arguments
/// @param   {Real}                  _k     : The argument
/// @param   {Struct}                _state : The local facts
/// @param   {Struct}                _cx    : The typing context
/// @returns {String|Undefined}
#endregion
function __gmlc_type_elements_of(_args, _k, _state, _cx) {
	if (_k >= array_length(_args)) return undefined;
	var _h = __gmlc_type_holder_of(_args[_k], _state, _cx);
	return (_h != undefined) ? "e:" + _h : undefined;
}

#region jsDoc
/// @func    __gmlc_type_type_at(_args, _k, _state, _cx)
/// @desc    The type of an argument, Undefined when it is left out, Unknown when it is not proven.
/// @param   {Array<Struct.ASTNode>} _args  : The arguments
/// @param   {Real}                  _k     : The argument
/// @param   {Struct}                _state : The local facts
/// @param   {Struct}                _cx    : The typing context
/// @returns {String}
#endregion
function __gmlc_type_type_at(_args, _k, _state, _cx) {
	if (_k >= array_length(_args)) return "Undefined";
	var _t = __gmlc_type_of(_args[_k], _state, _cx);
	return (_t.provenance == "proven") ? _t.type : "Unknown";
}

#region jsDoc
/// @func    __gmlc_type_builtin_name(_call)
/// @desc    The name of the built-in a call calls by name.
/// @param   {Struct.ASTNode} _call : The call
/// @returns {String|Undefined}
#endregion
function __gmlc_type_builtin_name(_call) {
	var _callee = _call.callee;
	if (_callee.kind == __GMLC_NodeKind_Identifier) && (_callee.symbol != undefined) && (_callee.symbol.kind == "BuiltinFunction") return _callee.name;
	return undefined;
}

#region jsDoc
/// @func    __gmlc_type_target_flows(_node, _targets, _state, _cx)
/// @desc    The flows of a call of a value: its arguments go to the parameters of every function it may call, the
///          caller's `self` (the object of `x.f(...)`) to a global function's whose `self` matters, and what they
///          return to its result.
/// @param   {Struct.ASTNode} _node    : The call
/// @param   {Array<String>}  _targets : The functions it may call (__gmlc_type_call_targets)
/// @param   {Struct}         _state   : The local facts
/// @param   {Struct}         _cx      : The typing context
#endregion
function __gmlc_type_target_flows(_node, _targets, _state, _cx) {
	var _targetArgs = __gmlc_type_call_args(_node);
	var _targetOwn = "n:" + string(_cx.file) + ":" + string(_node.span.start);
	var _caller = (_node.kind == __GMLC_NodeKind_MethodCall) ? __gmlc_type_holder_of(_node.object, _state, _cx) : undefined;
	_caller ??= _cx.self_holder;
	var _tk = 0; repeat (array_length(_targets)) {
		var _targetKey = _targets[_tk];
		var _targetParams = _cx.param_holders[$ _targetKey];
		var _ta = 0; repeat (array_length(_targetArgs)) {
			var _targetHolder = __gmlc_type_holder_of(_targetArgs[_ta], _state, _cx);
			if (_targetHolder != undefined) {
				// an argument past the parameters is read only through the argument array
				var _targetTo = "?";
				if (_targetParams != undefined) _targetTo = (_ta < array_length(_targetParams)) ? _targetParams[_ta] : "e:aa:" + _targetKey;
				__gmlc_type_add_flow(_targetTo, _targetHolder, _cx);
			}
		_ta++}
		if (string_starts_with(_targetKey, "m:")) __gmlc_type_add_flow(_targetKey, _caller, _cx);
		else if (!string_starts_with(_targetKey, "fl:")) && (struct_exists(_cx.self_users, _targetKey)) __gmlc_type_add_flow("g:" + _targetKey, _caller, _cx);
		__gmlc_type_add_flow(_targetOwn, "r:" + _targetKey, _cx);
	_tk++}
}

#region jsDoc
/// @func    __gmlc_type_record_call_arrays(_node, _state, _cx)
/// @desc    The array flows of a call: an argument of a function only the project's own calls reach flows to its
///          parameter; the built-ins that write elements, copy them or call back with them say what they do; any
///          other call may keep or change an array it is given.
/// @param   {Struct.ASTNode} _node  : The call
/// @param   {Struct}         _state : The local facts
/// @param   {Struct}         _cx    : The typing context
#endregion
function __gmlc_type_record_call_arrays(_node, _state, _cx) {
	var _fn = _node.callee;
	var _args = _node.args;
	var _targets = __gmlc_type_call_targets(_node, _state, _cx);
	if (_targets != undefined) {
		__gmlc_type_target_flows(_node, _targets, _state, _cx);
		return;
	}
	if (_fn.kind != __GMLC_NodeKind_Identifier) {
		__gmlc_type_flow_arguments(_args, undefined, _state, _cx);
		return;
	}
	var _kind = (_fn.symbol != undefined) ? _fn.symbol.kind : undefined;
	// a global function called by name runs with the caller's `self`; a method called through `self` too
	if (_kind == "Global") && (struct_exists(_cx.param_holders, _fn.name)) && (struct_exists(_cx.self_users, _fn.name)) {
		__gmlc_type_add_flow("g:" + _fn.name, _cx.self_holder, _cx);
	}
	
	if (_kind == "Self") || (_kind == "Static") {
		__gmlc_type_add_flow("m:" + _fn.name, _cx.self_holder, _cx);
		__gmlc_type_flow_arguments(_args, _cx.param_holders[$ "m:" + _fn.name], _state, _cx);
		return;
	}
	if (_kind == "Global") && (struct_exists(_cx.param_holders, _fn.name)) {
		var _params = _cx.param_holders[$ _fn.name];
		var _k = 0; repeat (array_length(_args)) {
			var _ah = __gmlc_type_holder_of(_args[_k], _state, _cx);
			// an argument past the parameters is read only through the argument array
			if (_ah != undefined) __gmlc_type_add_flow((_k < array_length(_params)) ? _params[_k] : "e:aa:" + _fn.name, _ah, _cx);
		_k++}
		return;
	}
	if (_kind != "BuiltinFunction") {
		__gmlc_type_flow_arguments(_args, undefined, _state, _cx);
		return;
	}
	var _own = "n:" + string(_cx.file) + ":" + string(_node.span.start);
	// the function a built-in calls with each element or step: the elements go to its parameters, what it returns
	// to the built-in's result
	var _callback = __gmlc_type_callback(_fn.name);
	var _callbackKeys = ((_callback != undefined) && (_callback.at < array_length(_args))) ? __gmlc_type_value_targets(_args[_callback.at], _state, _cx) : undefined;
	if (_callbackKeys != undefined) {
		var _callbackBase = (array_length(_args) > 0) ? __gmlc_type_holder_of(_args[0], _state, _cx) : undefined;
		var _cb = 0; repeat (array_length(_callbackKeys)) {
			var _callbackKey = _callbackKeys[_cb];
			// a global function the built-in calls runs with a `self` the typing does not know
			if (!string_starts_with(_callbackKey, "m:")) && (!string_starts_with(_callbackKey, "fl:")) && (struct_exists(_cx.self_users, _callbackKey)) {
				__gmlc_type_add_flow("g:" + _callbackKey, "?", _cx);
			}
			var _callbackParams = _cx.param_holders[$ _callbackKey];
			var _cp = 0; repeat (array_length(_callback.passed)) {
				var _cbPassed = _callback.passed[_cp];
				var _cbFrom = undefined;
				switch (_cbPassed) {
					case __GMLC_TypePassed.ELEMENT:
						if (_callbackBase != undefined) _cbFrom = (_callbackBase == "?") ? _callbackBase : "e:" + _callbackBase;
						break;
					case __GMLC_TypePassed.FIELD:
						if (_callbackBase != undefined) _cbFrom = _callbackBase + "#*";
						break;
					case __GMLC_TypePassed.RUNNING:
						if (array_length(_args) > 2) _cbFrom = __gmlc_type_holder_of(_args[2], _state, _cx);
						break;
				}
				var _cbTo = ((_callbackParams != undefined) && (_cp < array_length(_callbackParams))) ? _callbackParams[_cp] : undefined;
				if (_cbTo != undefined) && (_cbFrom != undefined) __gmlc_type_add_flow(_cbTo, _cbFrom, _cx);
				if (_cbPassed == __GMLC_TypePassed.RUNNING) && (_cbTo != undefined) __gmlc_type_add_flow(_cbTo, "r:" + _callbackKey, _cx);
			_cp++}
			var _callbackReturned = _cx.batch[$ _callbackKey] ?? "Unknown";
			switch (_fn.name) {
				case "array_map": case "array_create_ext":
					__gmlc_type_add_element("e:" + _own, _callbackReturned, _cx);
					__gmlc_type_add_flow("e:" + _own, "r:" + _callbackKey, _cx);
					break;
				case "array_map_ext":
					if (_callbackBase != undefined) {
						__gmlc_type_add_element("e:" + _callbackBase, _callbackReturned, _cx);
						__gmlc_type_add_flow("e:" + _callbackBase, "r:" + _callbackKey, _cx);
					}
					break;
				case "array_reduce":
					__gmlc_type_add_flow(_own, "r:" + _callbackKey, _cx);
					break;
			}
		_cb++}
		// a filter's or a copy's new array holds the elements it keeps
		if ((_fn.name == "array_filter") || (_fn.name == "array_copy_while")) && (_callbackBase != undefined) {
			__gmlc_type_add_flow("e:" + _own, "e:" + _callbackBase, _cx);
		}
		if (_fn.name == "array_reduce") && (array_length(_args) > 2) {
			var _initHolder = __gmlc_type_holder_of(_args[2], _state, _cx);
			if (_initHolder != undefined) __gmlc_type_add_flow(_own, _initHolder, _cx);
		}
		return;
	}
	if (_fn.name == "method") && (array_length(_args) == 2) {
		// the function runs with the struct given as its `self`
		var _owner = __gmlc_type_holder_of(_args[0], _state, _cx) ?? "?";
		var _fnArg = _args[1];
		if (_fnArg.kind == __GMLC_NodeKind_FunctionExpr) {
			if (_fnArg.fn_id != undefined) __gmlc_type_add_flow(_cx.selfs[$ string(_fnArg.fn_id)] ?? "?", _owner, _cx);
		}
		else if (_fnArg.kind == __GMLC_NodeKind_Index) && (_fnArg.accessor == "Dot") && (_fnArg.member != undefined) {
			__gmlc_type_add_flow("m:" + _fnArg.member, _owner, _cx);
		}
		else if (_fnArg.kind == __GMLC_NodeKind_Identifier) && (_fnArg.symbol != undefined) && (_fnArg.symbol.kind == "Global") {
			__gmlc_type_add_flow("g:" + _fnArg.name, _owner, _cx);
		}
		else if (_fnArg.kind == __GMLC_NodeKind_Identifier) && (_fnArg.symbol != undefined) && ((_fnArg.symbol.kind == "Self") || (_fnArg.symbol.kind == "Static")) {
			__gmlc_type_add_flow("m:" + _fnArg.name, _owner, _cx);
		}
		else {
			// a function value: each function it may be runs on the struct
			var _bound = __gmlc_type_rebind_targets(_fnArg, _state, _cx);
			var _rebind = (_bound == undefined);
			if (!_rebind) {
				var _b = 0; repeat (array_length(_bound)) {
					var _boundKey = _bound[_b];
					var _boundSelf = undefined;
					if (string_starts_with(_boundKey, "fl:")) {
						var _at = string_split(string_delete(_boundKey, 1, 3), ":");
						if (_at[0] == string(_cx.file)) _boundSelf = _cx.selfs[$ _at[1]];
					}
					else _boundSelf = string_starts_with(_boundKey, "m:") ? _boundKey : "g:" + _boundKey;
					if (_boundSelf != undefined) __gmlc_type_add_flow(_boundSelf, _owner, _cx);
					else _rebind = true;
				_b++}
			}
			if (_rebind) {
				__gmlc_type_add_flow("?", _owner, _cx);
				__gmlc_type_add_flow("?", "rebind", _cx);
			}
		}
		return;
	}
	switch (_fn.name) {
		// the fields of the struct given become the new instance's
		case "instance_create_layer": case "instance_create_depth":
			var _ih = (array_length(_args) > 4) ? __gmlc_type_holder_of(_args[4], _state, _cx) : undefined;
			if (_ih != undefined) __gmlc_type_add_flow("i", _ih, _cx);
			return;
		case "array_push": case "array_insert":
			var _pe = __gmlc_type_elements_of(_args, 0, _state, _cx);
			if (_pe != undefined) {
				var _from = (_fn.name == "array_push") ? 1 : 2;
				var _v = _from; repeat (max(0, array_length(_args) - _from)) {
					__gmlc_type_add_element(_pe, __gmlc_type_type_at(_args, _v, _state, _cx), _cx);
					var _vh = __gmlc_type_holder_of(_args[_v], _state, _cx);
					if (_vh != undefined) __gmlc_type_add_flow(_pe, _vh, _cx);
				_v++}
			}
			return;
		case "array_set":
			var _se = __gmlc_type_elements_of(_args, 0, _state, _cx);
			if (_se != undefined) {
				__gmlc_type_add_element(_se, __gmlc_type_type_at(_args, 2, _state, _cx), _cx);
				__gmlc_type_add_element(_se, "Int", _cx);
				var _sh = (array_length(_args) > 2) ? __gmlc_type_holder_of(_args[2], _state, _cx) : undefined;
				if (_sh != undefined) __gmlc_type_add_flow(_se, _sh, _cx);
			}
			return;
		case "array_resize":
			var _re = __gmlc_type_elements_of(_args, 0, _state, _cx);
			if (_re != undefined) __gmlc_type_add_element(_re, "Int", _cx);
			return;
		case "array_copy":
			var _de = __gmlc_type_elements_of(_args, 0, _state, _cx);
			var _ce = __gmlc_type_elements_of(_args, 2, _state, _cx);
			if (_de != undefined) && (_ce != undefined) {
				__gmlc_type_add_element(_de, "Int", _cx);
				__gmlc_type_add_flow(_de, _ce, _cx);
			}
			return;
		case "array_create":
			var _ct = (array_length(_args) > 1) ? __gmlc_type_type_at(_args, 1, _state, _cx) : "Int";
			__gmlc_type_add_element("e:" + _own, _ct, _cx);
			var _ch = (array_length(_args) > 1) ? __gmlc_type_holder_of(_args[1], _state, _cx) : undefined;
			if (_ch != undefined) __gmlc_type_add_flow("e:" + _own, _ch, _cx);
			return;
		// a new array of the elements of the arrays given
		case "array_concat": case "array_union": case "array_intersection": case "array_filter": case "array_unique": case "array_copy_while":
			var _c = 0; repeat (array_length(_args)) {
				var _ke = __gmlc_type_elements_of(_args, _c, _state, _cx);
				if (_ke != undefined) __gmlc_type_add_flow("e:" + _own, _ke, _cx);
			_c++}
			return;
		// these call a function with each element
		case "array_foreach": case "array_map": case "array_reduce": case "array_any": case "array_all": case "array_find_index":
		case "array_sort": case "array_map_ext": case "array_filter_ext": case "array_count":
			var _fe = __gmlc_type_elements_of(_args, 0, _state, _cx);
			if (_fe != undefined) {
				var _r = 1; repeat (max(0, array_length(_args) - 1)) {
					var _rh = __gmlc_type_holder_of(_args[_r], _state, _cx);
					if (_rh != undefined) __gmlc_type_add_flow("?", _rh, _cx);
				_r++}
				// the callback may be any function, which may change the elements
				__gmlc_type_add_flow("?", _fe, _cx);
				if (_fn.name == "array_map") __gmlc_type_add_element("e:" + _own, "Unknown", _cx);
				else if (_fn.name == "array_map_ext") || (_fn.name == "array_filter_ext") __gmlc_type_add_element(_fe, "Unknown", _cx);
			}
			return;
	}
	// what the built-in's data says the new array holds
	var _returns = _cx.builtins[$ _fn.name] ?? "";
	if (string_starts_with(_returns, "Array<")) && (string_ends_with(_returns, ">")) __gmlc_type_add_element("e:" + _own, string_copy(_returns, 7, string_length(_returns) - 7), _cx);
	else if (string_starts_with(_returns, "Array")) __gmlc_type_add_element("e:" + _own, "Unknown", _cx);
	// a ds container keeps what is written into it in its elements
	var _written = [];
	if (__gmlc_type_map_setter(_fn.name)) _written = [2];
	else {
		var _writer = __gmlc_type_ds_writer(_fn.name);
		if (_writer != undefined) {
			if (_writer.more) {
				var _wk = _writer.from; repeat (max(0, array_length(_args) - _writer.from)) {
					array_push(_written, _wk);
				_wk++}
			}
			else _written = [_writer.from];
		}
	}
	if (array_length(_written) > 0) {
		var _we = __gmlc_type_container(_args, 0, _state, _cx) ?? "?";
		var _w = 0; repeat (array_length(_written)) {
			var _wi = _written[_w];
			if (_wi < array_length(_args)) {
				__gmlc_type_add_element(_we, __gmlc_type_type_at(_args, _wi, _state, _cx), _cx);
				var _wh = __gmlc_type_holder_of(_args[_wi], _state, _cx);
				if (_wh != undefined) __gmlc_type_add_flow(_we, _wh, _cx);
			}
		_w++}
	}
	var _fill = __gmlc_type_ds_fill(_fn.name);
	if (_fill != undefined) {
		// the container a built-in fills is the one it makes, or the one it is given
		var _fe2 = undefined;
		if (string_starts_with(_returns, "Id.Ds")) _fe2 = "e:" + _own;
		else {
			var _dp = __gmlc_type_ds_param(_fn.name);
			if (_dp != undefined) _fe2 = __gmlc_type_container(_args, _dp, _state, _cx);
		}
		if (_fe2 != undefined) __gmlc_type_add_element(_fe2, _fill.type, _cx);
	}
	var _copy = __gmlc_type_ds_copy(_fn.name);
	if (_copy != undefined) {
		var _cd = __gmlc_type_container(_args, _copy[0], _state, _cx);
		var _cs = __gmlc_type_container(_args, _copy[1], _state, _cx);
		if (_cd != undefined) && (_cs != undefined) __gmlc_type_add_flow(_cd, _cs, _cx);
	}
	// a built-in keeps what it is given only in a ds container or for a function it calls later; it changes an
	// array in place only as an array_* built-in above
	var _kept = 0; repeat (array_length(_args)) {
		if (__gmlc_type_keeps_argument(_fn.name, _kept)) {
			var _keptHolder = __gmlc_type_holder_of(_args[_kept], _state, _cx);
			if (_keptHolder != undefined) __gmlc_type_add_flow("?", _keptHolder, _cx);
		}
	_kept++}
	// a setter stores the value in a field
	var _set = __gmlc_type_setter(_node);
	if (_set != undefined) && (string_char_at(_set.name, 1) != "?") && (_set.value < array_length(_args)) {
		var _setHolder = __gmlc_type_holder_of(_args[_set.value], _state, _cx);
		if (_setHolder != undefined) {
			var _setOwner = (_fn.name == "variable_global_set") ? "gl" : (((array_length(_args) > 0) ? __gmlc_type_holder_of(_args[0], _state, _cx) : undefined) ?? "?");
			var _setField = (string_char_at(_set.name, 1) == "*") ? "*" : _set.name;
			__gmlc_type_add_flow(_setOwner + "#" + _setField, _setHolder, _cx);
		}
	}
}

#region jsDoc
/// @func    __gmlc_type_keeps_argument(_name, _k)
/// @desc    Whether a built-in may keep its argument `_k` where code reads it later other than in a ds container: a
///          function it calls later or with its arguments (a parameter of function type); a built-in GameMaker's data
///          does not describe keeps every argument.
/// @param   {String} _name : The built-in
/// @param   {Real}   _k    : The argument's index
/// @returns {Bool}
#endregion
function __gmlc_type_keeps_argument(_name, _k) {
	if (_name == "call_later") || (_name == "time_source_create") || (_name == "time_source_reconfigure") return true;
	// these only look at the function they are given
	switch (_name) {
		case "is_instanceof": case "script_exists": case "script_get_name": case "method_get_index": case "method_get_self": case "static_get":
			return false;
	}
	var _signature = __gmlc_opt_builtin_function(_name);
	if (_signature == undefined) return true;
	// the ds built-ins keep values only in the containers they write (`__gmlc_type_record_call_arrays`)
	if (string_starts_with(_name, "ds_")) return false;
	var _count = array_length(_signature.parameters);
	if (_count == 0) return false;
	var _type = _signature.parameters[min(_k, _count - 1)].type;
	return (string_pos("Function", _type) > 0) || (string_pos("Method", _type) > 0) || (string_pos("Script", _type) > 0);
}

#region jsDoc
/// @func    __gmlc_type_composite(_holder)
/// @desc    A holder that is the elements or a field of another holder, split into the other holder and the part:
///          `[]` for the elements.
/// @param   {String} _holder : The holder
/// @returns {Array<String>|Undefined} [base, part], or undefined for any other holder
#endregion
function __gmlc_type_composite(_holder) {
	if (string_starts_with(_holder, "e:")) return [string_delete(_holder, 1, 2), "[]"];
	return __gmlc_type_split_hash(_holder);
}

#region jsDoc
/// @func    __gmlc_type_is_object(_holder)
/// @desc    Whether a holder is a place values are made (an object of the points-to analysis): an array or struct a
///          literal or a built-in makes (`n:`), a constructor's structs (`c:`), the instances (`i`), the global struct
///          (`gl`), a function's statics (`st:`), a function (`fn:`, `fl:`, `fb:`), a function's argument array
///          (`aa:`).
/// @param   {String} _holder : The holder
/// @returns {Bool}
#endregion
function __gmlc_type_is_object(_holder) {
	if (_holder == "i") || (_holder == "gl") return true;
	if (string_pos("#", _holder) > 0) return false;
	return string_starts_with(_holder, "n:") || string_starts_with(_holder, "c:") || string_starts_with(_holder, "st:")
		|| string_starts_with(_holder, "fn:") || string_starts_with(_holder, "fl:") || string_starts_with(_holder, "fb:")
		|| string_starts_with(_holder, "aa:");
}

#region jsDoc
/// @func    __gmlc_type_is_unknown(_holder)
/// @desc    Whether a holder stands for code the typing does not follow.
/// @param   {String} _holder : The holder
/// @returns {Bool}
#endregion
function __gmlc_type_is_unknown(_holder) {
	return (_holder == "?") || string_starts_with(_holder, "?:");
}

#region jsDoc
/// @func    __gmlc_type_points_to(_flows, _elems)
/// @desc    The objects each holder may hold (an inclusion-based points-to analysis): a flow copies what its source
///          holds into its target, a field or an element of a holder is that field or element of each object it holds,
///          and a computed field name (`*`) is any field of its object. What comes from code the typing does not follow
///          is the object `?`; what goes to it escapes, and so does what an escaped object holds: unknown code may
///          write any field or element of an escaped object. A function whose `self` code may change to a struct no one
///          knows (`rebind`) runs on `?` too. A holder's set is written as its objects in order, joined by `|`, or `?`
///          when it holds `?`.
/// @param   {Array<Array<String>>} _flows : The flows, [target, source]
/// @param   {Struct}               _elems : Holder to the type written into it
/// @returns {Struct} {arrays, elements, escaped}: each holder's objects, what each place of an object holds
///          (`<object>#<field>`, `<object>#[]`), the objects code the typing does not follow reaches
#endregion
function __gmlc_type_points_to(_flows, _elems) {
	var _s = { nodes: {}, names: [], pts: [], succ: [], edges: {}, parts: [], places: {}, place_list: [], fields_of: {}, escaped: {}, widened: {}, work: [], sink: 0, unknown_place: 0 };
	_s.sink = __gmlc_type_pts_node(_s, "<sink>");
	_s.unknown_place = __gmlc_type_pts_node(_s, "<unknown>");
	__gmlc_type_pts_add(_s, _s.unknown_place, ["?"]);
	var _rebind = false;
	var _i = 0; repeat (array_length(_flows)) {
		var _to = _flows[_i][0];
		var _from = _flows[_i][1];
		if (_to == "?") && (_from == "rebind") _rebind = true;
		else __gmlc_type_pts_flow(_s, _to, __gmlc_type_pts_source(_s, _from));
	_i++}
	// a function whose `self` code may change to a struct no one knows runs on any struct
	if (_rebind) {
		_i = 0; repeat (array_length(_flows)) {
			var _k = 0; repeat (2) {
				var _h = _flows[_i][_k];
				if ((string_starts_with(_h, "m:")) || (string_starts_with(_h, "g:"))) && (__gmlc_type_composite(_h) == undefined) __gmlc_type_pts_edge(_s, _s.unknown_place, __gmlc_type_pts_node(_s, _h));
			_k++}
		_i++}
	}
	// the places element and field writes name
	var _written = struct_get_names(_elems);
	_i = 0; repeat (array_length(_written)) {
		if (!__gmlc_type_is_unknown(_written[_i])) __gmlc_type_pts_source(_s, _written[_i]);
	_i++}
	__gmlc_type_pts_solve(_s);
	var _arrays = { "?": "?" };
	_i = 0; repeat (array_length(_s.names)) {
		var _name = _s.names[_i];
		if (!string_starts_with(_name, "<")) _arrays[$ _name] = __gmlc_type_pts_key(_s.pts[_i]);
	_i++}
	// what each place holds: the writes to the holders that name it
	var _elements = {};
	_i = 0; repeat (array_length(_written)) {
		var _w = _written[_i];
		var _t = _elems[$ _w];
		// what code writes to the fields of structs or instances no one knows reaches those fields of every group
		if (string_starts_with(_w, "?#")) {
			_elements[$ _w] = _t;
		}
		else {
			var _part = __gmlc_type_composite(_w);
			if (_part != undefined) {
				var _objects = struct_get_names(_s.pts[__gmlc_type_pts_source(_s, _part[0])]);
				var _o = 0; repeat (array_length(_objects)) {
					if (_objects[_o] != "?") {
						var _place = _objects[_o] + "#" + _part[1];
						_elements[$ _place] = gmlc_type_join(_elements[$ _place] ?? "Never", _t);
					}
				_o++}
			}
		}
	_i++}
	// unknown code may write anything to an escaped object's places
	_i = 0; repeat (array_length(_s.place_list)) {
		var _entry = _s.place_list[_i];
		if (struct_exists(_s.escaped, _entry[0])) _elements[$ _entry[0] + "#" + _entry[1]] = "Unknown";
	_i++}
	return { arrays: _arrays, elements: _elements, escaped: _s.escaped };
}

#region jsDoc
/// @func    __gmlc_type_pts_key(_set)
/// @desc    A points-to set as one name: its objects in byte order joined by `|`, or `?` when it holds `?`.
/// @param   {Struct} _set : Object name to true
/// @returns {String}
#endregion
function __gmlc_type_pts_key(_set) {
	if (struct_exists(_set, "?")) return "?";
	var _names = struct_get_names(_set);
	array_sort(_names, true);
	var _key = "";
	var _i = 0; repeat (array_length(_names)) {
		_key += ((_i > 0) ? "|" : "") + _names[_i];
	_i++}
	return _key;
}

#region jsDoc
/// @func    __gmlc_type_pts_node(_s, _name)
/// @desc    The node of a holder in a points-to solve; an object's holder holds the object.
/// @param   {Struct} _s    : The solve
/// @param   {String} _name : The holder
/// @returns {Real}
#endregion
function __gmlc_type_pts_node(_s, _name) {
	var _n = _s.nodes[$ _name];
	if (_n != undefined) return _n;
	_n = array_length(_s.names);
	_s.nodes[$ _name] = _n;
	array_push(_s.names, _name);
	array_push(_s.pts, {});
	array_push(_s.succ, []);
	array_push(_s.parts, []);
	if (__gmlc_type_is_object(_name)) __gmlc_type_pts_add(_s, _n, [_name]);
	return _n;
}

#region jsDoc
/// @func    __gmlc_type_pts_add(_s, _n, _objects)
/// @desc    Adds objects to a node's set, and queues the node when its set grows. A set past 256 objects holds `?`
///          instead, and what reaches it from then on escapes.
/// @param   {Struct}        _s       : The solve
/// @param   {Real}          _n       : The node
/// @param   {Array<String>} _objects : The objects
#endregion
function __gmlc_type_pts_add(_s, _n, _objects) {
	var _set = _s.pts[_n];
	var _i;
	if (_n != _s.sink) && (struct_exists(_s.widened, string(_n))) {
		var _rest = [];
		_i = 0; repeat (array_length(_objects)) {
			if (_objects[_i] != "?") array_push(_rest, _objects[_i]);
		_i++}
		if (array_length(_rest) > 0) __gmlc_type_pts_add(_s, _s.sink, _rest);
		return;
	}
	var _grew = false;
	_i = 0; repeat (array_length(_objects)) {
		if (!struct_exists(_set, _objects[_i])) {
			_set[$ _objects[_i]] = true;
			_grew = true;
		}
	_i++}
	if (_grew) array_push(_s.work, _n);
	if (_n != _s.sink) && (struct_names_count(_set) > 256) {
		_s.widened[$ string(_n)] = true;
		var _all = struct_get_names(_set);
		var _escaping = [];
		_i = 0; repeat (array_length(_all)) {
			if (_all[_i] != "?") array_push(_escaping, _all[_i]);
		_i++}
		_s.pts[_n] = { "?": true };
		array_push(_s.work, _n);
		__gmlc_type_pts_add(_s, _s.sink, _escaping);
	}
}

#region jsDoc
/// @func    __gmlc_type_pts_edge(_s, _from, _to)
/// @desc    Makes everything one node holds flow into another.
/// @param   {Struct} _s    : The solve
/// @param   {Real}   _from : The source node
/// @param   {Real}   _to   : The target node
#endregion
function __gmlc_type_pts_edge(_s, _from, _to) {
	if (_from == _to) return;
	var _key = string(_from) + "," + string(_to);
	if (struct_exists(_s.edges, _key)) return;
	_s.edges[$ _key] = true;
	array_push(_s.succ[_from], _to);
	__gmlc_type_pts_add(_s, _to, struct_get_names(_s.pts[_from]));
}

#region jsDoc
/// @func    __gmlc_type_pts_place(_s, _object, _field)
/// @desc    The node of a place of an object: its field or its elements (`[]`); a computed field name (`*`) is any
///          field of its object, and every place of `?` is the one unknown place.
/// @param   {Struct} _s      : The solve
/// @param   {String} _object : The object
/// @param   {String} _field  : The field, `*` or `[]`
/// @returns {Real}
#endregion
function __gmlc_type_pts_place(_s, _object, _field) {
	if (_object == "?") return _s.unknown_place;
	var _name = _object + "#" + _field;
	var _n = _s.places[$ _name];
	if (_n != undefined) return _n;
	_n = __gmlc_type_pts_node(_s, _name);
	_s.places[$ _name] = _n;
	array_push(_s.place_list, [_object, _field]);
	var _fields = _s.fields_of[$ _object];
	if (_fields == undefined) {
		_fields = [];
		_s.fields_of[$ _object] = _fields;
	}
	if (_field != "[]") {
		var _i = 0; repeat (array_length(_fields)) {
			var _other = _fields[_i];
			if (_other != "[]") && ((_field == "*") || (_other == "*")) {
				var _m = _s.places[$ _object + "#" + _other];
				__gmlc_type_pts_edge(_s, _n, _m);
				__gmlc_type_pts_edge(_s, _m, _n);
			}
		_i++}
	}
	array_push(_fields, _field);
	if (struct_exists(_s.escaped, _object)) __gmlc_type_pts_escape_place(_s, _n);
	return _n;
}

#region jsDoc
/// @func    __gmlc_type_pts_store_place(_s, _object, _field)
/// @desc    The node a write to a place goes to: a place of `?` is code the typing does not follow.
/// @param   {Struct} _s      : The solve
/// @param   {String} _object : The object
/// @param   {String} _field  : The field, `*` or `[]`
/// @returns {Real}
#endregion
function __gmlc_type_pts_store_place(_s, _object, _field) {
	return (_object == "?") ? _s.sink : __gmlc_type_pts_place(_s, _object, _field);
}

#region jsDoc
/// @func    __gmlc_type_pts_escape_place(_s, _n)
/// @desc    A place of an escaped object: what it holds escapes, and unknown code may write anything to it.
/// @param   {Struct} _s : The solve
/// @param   {Real}   _n : The place's node
#endregion
function __gmlc_type_pts_escape_place(_s, _n) {
	__gmlc_type_pts_edge(_s, _n, _s.sink);
	__gmlc_type_pts_add(_s, _n, ["?"]);
}

#region jsDoc
/// @func    __gmlc_type_pts_source(_s, _holder)
/// @desc    The node a holder is read from: a part of another holder reads that part of each object it holds.
/// @param   {Struct} _s      : The solve
/// @param   {String} _holder : The holder
/// @returns {Real}
#endregion
function __gmlc_type_pts_source(_s, _holder) {
	if (__gmlc_type_is_unknown(_holder)) return _s.unknown_place;
	var _part = __gmlc_type_composite(_holder);
	if (_part == undefined) return __gmlc_type_pts_node(_s, _holder);
	var _n = _s.nodes[$ "<" + _holder];
	if (_n != undefined) return _n;
	var _b = __gmlc_type_pts_source(_s, _part[0]);
	_n = __gmlc_type_pts_node(_s, "<" + _holder);
	array_push(_s.parts[_b], [_part[1], _n, true]);
	var _objects = struct_get_names(_s.pts[_b]);
	var _i = 0; repeat (array_length(_objects)) {
		__gmlc_type_pts_edge(_s, __gmlc_type_pts_place(_s, _objects[_i], _part[1]), _n);
	_i++}
	return _n;
}

#region jsDoc
/// @func    __gmlc_type_pts_flow(_s, _to, _from)
/// @desc    A flow of what a node holds into a holder: code the typing does not follow, a part of each object another
///          holder holds, or the holder.
/// @param   {Struct} _s    : The solve
/// @param   {String} _to   : The target holder
/// @param   {Real}   _from : The source node
#endregion
function __gmlc_type_pts_flow(_s, _to, _from) {
	if (__gmlc_type_is_unknown(_to)) {
		__gmlc_type_pts_edge(_s, _from, _s.sink);
		return;
	}
	var _part = __gmlc_type_composite(_to);
	if (_part == undefined) {
		__gmlc_type_pts_edge(_s, _from, __gmlc_type_pts_node(_s, _to));
		return;
	}
	var _b = __gmlc_type_pts_source(_s, _part[0]);
	array_push(_s.parts[_b], [_part[1], _from, false]);
	var _objects = struct_get_names(_s.pts[_b]);
	var _i = 0; repeat (array_length(_objects)) {
		__gmlc_type_pts_edge(_s, _from, __gmlc_type_pts_store_place(_s, _objects[_i], _part[1]));
	_i++}
}

#region jsDoc
/// @func    __gmlc_type_pts_solve(_s)
/// @desc    Moves objects along the flows until no set grows: through each edge, into and out of the places of each
///          object a holder gains, and out of the places of each object that escapes.
/// @param   {Struct} _s : The solve
#endregion
function __gmlc_type_pts_solve(_s) {
	while (array_length(_s.work) > 0) {
		var _n = array_pop(_s.work);
		var _objects = struct_get_names(_s.pts[_n]);
		var _succ = _s.succ[_n];
		var _i = 0; repeat (array_length(_succ)) {
			__gmlc_type_pts_add(_s, _succ[_i], _objects);
		_i++}
		var _parts = _s.parts[_n];
		var _p = 0; repeat (array_length(_parts)) {
			var _field = _parts[_p][0];
			var _other = _parts[_p][1];
			var _load = _parts[_p][2];
			var _o = 0; repeat (array_length(_objects)) {
				if (_load) __gmlc_type_pts_edge(_s, __gmlc_type_pts_place(_s, _objects[_o], _field), _other);
				else __gmlc_type_pts_edge(_s, _other, __gmlc_type_pts_store_place(_s, _objects[_o], _field));
			_o++}
		_p++}
		if (_n == _s.sink) {
			var _e = 0; repeat (array_length(_objects)) {
				var _object = _objects[_e];
				if (_object != "?") && (!struct_exists(_s.escaped, _object)) {
					_s.escaped[$ _object] = true;
					var _fields = _s.fields_of[$ _object] ?? [];
					var _f = 0; repeat (array_length(_fields)) {
						__gmlc_type_pts_escape_place(_s, _s.places[$ _object + "#" + _fields[_f]]);
					_f++}
				}
			_e++}
		}
	}
}

#region jsDoc
/// @func    __gmlc_type_points(_holder, _arrays, _escaped)
/// @desc    The objects a holder may hold (__gmlc_type_points_to), `?` among them when it may hold what code the typing
///          does not follow made; undefined when no flow names it. A part of another holder holds that part of each of
///          its objects.
/// @param   {String} _holder  : The holder
/// @param   {Struct} _arrays  : Each holder's objects
/// @param   {Struct} _escaped : The objects code the typing does not follow reaches
/// @returns {Array<String>|Undefined}
#endregion
function __gmlc_type_points(_holder, _arrays, _escaped) {
	var _key = _arrays[$ _holder];
	if (_key != undefined) return (_key == "") ? [] : string_split(_key, "|");
	if (__gmlc_type_is_unknown(_holder)) return ["?"];
	if (__gmlc_type_is_object(_holder)) return [_holder];
	var _part = __gmlc_type_composite(_holder);
	if (_part == undefined) return undefined;
	var _objects = __gmlc_type_points(_part[0], _arrays, _escaped);
	if (_objects == undefined) return undefined;
	var _out = [];
	var _i = 0; repeat (array_length(_objects)) {
		var _o = _objects[_i];
		var _placeKey = _arrays[$ _o + "#" + _part[1]];
		var _held;
		if (_placeKey != undefined) _held = (_placeKey == "") ? [] : string_split(_placeKey, "|");
		else _held = ((_o == "?") || struct_exists(_escaped, _o)) ? ["?"] : [];
		array_copy(_out, array_length(_out), _held, 0, array_length(_held));
	_i++}
	_out = array_unique(_out);
	array_sort(_out, true);
	return _out;
}

#region jsDoc
/// @func    __gmlc_type_group_of(_holder, _cx)
/// @desc    The objects a holder may hold written as one name (__gmlc_type_points_to): `?` when they may be anything.
/// @param   {String} _holder : The holder
/// @param   {Struct} _cx     : The typing context
/// @returns {String|Undefined}
#endregion
function __gmlc_type_group_of(_holder, _cx) {
	var _objects = __gmlc_type_points(_holder, _cx.arrays, _cx.escaped);
	if (_objects == undefined) return undefined;
	if (array_contains(_objects, "?")) return "?";
	var _key = "";
	var _i = 0; repeat (array_length(_objects)) {
		_key += ((_i > 0) ? "|" : "") + _objects[_i];
	_i++}
	return _key;
}

#region jsDoc
/// @func    __gmlc_type_place_type(_holder, _arrays, _elements, _escaped)
/// @desc    What a part of a holder holds (its elements `e:<base>`, its field `<base>#<field>`): the join of what is
///          written to that place of each object the base may hold; Unknown when the base may be anything; undefined
///          when no write is known.
/// @param   {String} _holder   : The holder
/// @param   {Struct} _arrays   : Each holder's objects
/// @param   {Struct} _elements : What each place of an object holds
/// @param   {Struct} _escaped  : The objects code the typing does not follow reaches
/// @returns {String|Undefined}
#endregion
function __gmlc_type_place_type(_holder, _arrays, _elements, _escaped) {
	var _part = __gmlc_type_composite(_holder);
	if (_part == undefined) return undefined;
	var _objects = __gmlc_type_points(_part[0], _arrays, _escaped);
	if (_objects == undefined) return undefined;
	var _field = _part[1];
	var _type = undefined;
	var _i = 0; repeat (array_length(_objects)) {
		var _o = _objects[_i];
		var _found = [];
		// a function's argument array holds what its calls pass, whose types are not kept
		if (_o == "?") || (struct_exists(_escaped, _o)) || (string_starts_with(_o, "aa:")) array_push(_found, "Unknown");
		else if (_field == "*") {
			// a computed name reads any field of the object
			var _places = struct_get_names(_elements);
			var _start = _o + "#";
			var _p = 0; repeat (array_length(_places)) {
				if (string_starts_with(_places[_p], _start)) {
					var _rest = string_delete(_places[_p], 1, string_length(_start));
					if (_rest != "[]") && (string_pos("#", _rest) == 0) array_push(_found, _elements[$ _places[_p]]);
				}
			_p++}
		}
		else {
			var _own = _elements[$ _o + "#" + _field];
			if (_own != undefined) array_push(_found, _own);
			// a write by a computed name may be to any field
			if (_field != "[]") {
				var _any = _elements[$ _o + "#*"];
				if (_any != undefined) array_push(_found, _any);
			}
		}
		var _f = 0; repeat (array_length(_found)) {
			_type = (_type == undefined) ? _found[_f] : gmlc_type_join(_type, _found[_f]);
		_f++}
	_i++}
	return _type;
}


#region jsDoc
/// @func    __gmlc_type_group_find(_parent, _x)
/// @desc    The group of a holder in a union-find of holders.
/// @param   {Struct} _parent : Holder to its parent
/// @param   {String} _x      : The holder
/// @returns {String}
#endregion
function __gmlc_type_group_find(_parent, _x) {
	var _root = _x;
	while (struct_exists(_parent, _root)) && (_parent[$ _root] != _root) _root = _parent[$ _root];
	var _cur = _x;
	while (_cur != _root) {
		var _next = _parent[$ _cur] ?? _root;
		_parent[$ _cur] = _root;
		_cur = _next;
	}
	if (!struct_exists(_parent, _root)) _parent[$ _root] = _root;
	return _root;
}

#region jsDoc
/// @func    __gmlc_type_binary(_op, _a, _b)
/// @desc    The type an operator gives when it finishes: the join over every pair of member types of what
///          GameMaker's VM gives for them, a pair that throws giving nothing. A member of
///          unknown type may be anything, so `x + 1` is a real whatever `x` holds: a string, `undefined`, a struct or
///          an array would throw.
/// @param   {String} _op : The operator
/// @param   {String} _a  : The left type
/// @param   {String} _b  : The right type
/// @returns {String}
#endregion
function __gmlc_type_binary(_op, _a, _b) {
	switch (_op) {
		case "==": case "!=": case "<": case "<=": case ">": case ">=": return "Bool";
	}
	if (_a == "Never") || (_b == "Never") return "Never";
	var _out = "Never";
	var _xs = __gmlc_type_expand(_a);
	var _ys = __gmlc_type_expand(_b);
	var _i = 0; repeat (array_length(_xs)) {
		var _j = 0; repeat (array_length(_ys)) {
			var _t = __gmlc_type_atom_binary(_op, _xs[_i], _ys[_j]);
			if (_t != undefined) _out = gmlc_type_join(_out, _t);
		_j++}
	_i++}
	return _out;
}

#region jsDoc
/// @func    __gmlc_type_unary(_op, _type)
/// @desc    The type `-x` or `~x` gives when it finishes: `-` keeps a real, an
///          int64 and a bool and makes a number of a string, `~` gives an int64; anything else throws.
/// @param   {String} _op   : The operator
/// @param   {String} _type : The operand's type
/// @returns {String}
#endregion
function __gmlc_type_unary(_op, _type) {
	var _out = "Never";
	var _members = __gmlc_type_expand(_type);
	var _i = 0; repeat (array_length(_members)) {
		var _m = _members[_i];
		var _kind = __gmlc_type_kind(_m);
		var _t = undefined;
		if (_kind != "o") {
			if (_op == "~") _t = "Int64";
			else if (_kind == "s") _t = "Real";
			else if (_kind == "n") && (string_starts_with(_m, "Constant.")) _t = "Real";
			else if (_kind == "i") _t = "Int64";
			else _t = _m;
		}
		if (_t != undefined) _out = gmlc_type_join(_out, _t);
	_i++}
	return _out;
}

#region jsDoc
/// @func    __gmlc_type_expand(_type)
/// @desc    The member types of a type, an unknown one standing for one of each kind a value can have.
/// @param   {String} _type : The type
/// @returns {Array<String>}
#endregion
function __gmlc_type_expand(_type) {
	static __kinds = ["Real", "Int64", "Bool", "String", "Undefined", "Struct"];
	var _out = [];
	var _members = __gmlc_type_members(_type);
	var _i = 0; repeat (array_length(_members)) {
		if (_members[_i] == "Unknown") || (_members[_i] == "Any") {
			array_copy(_out, array_length(_out), __kinds, 0, array_length(__kinds));
		}
		else array_push(_out, _members[_i]);
	_i++}
	return _out;
}

#region jsDoc
/// @func    __gmlc_type_kind(_atom)
/// @desc    The kind of an atom for the operators: `n` a real, `i` an int64, `b` a bool, `s` a string, `o` anything
///          else.
/// @param   {String} _atom : The atom
/// @returns {String}
#endregion
function __gmlc_type_kind(_atom) {
	switch (_atom) {
		case "Int": case "Double": case "Real": return "n";
		case "Int64": return "i";
		case "Bool": return "b";
		case "String": return "s";
	}
	if (string_starts_with(_atom, "Constant.")) return "n";
	if (string_starts_with(_atom, "Enum.")) return "i";
	return "o";
}

#region jsDoc
/// @func    __gmlc_type_number_kind(_op, _a, _b)
/// @desc    The number two reals or bools give: whole for `+`, `-` and `mod` of whole numbers, `Real` when either may
///          be any real, else a double.
/// @param   {String} _op : The operator
/// @param   {String} _a  : The left atom
/// @param   {String} _b  : The right atom
/// @returns {String}
#endregion
function __gmlc_type_number_kind(_op, _a, _b) {
	var _x = ((_a == "Int") || (_a == "Bool")) ? 0 : ((_a == "Double") ? 1 : 2);
	var _y = ((_b == "Int") || (_b == "Bool")) ? 0 : ((_b == "Double") ? 1 : 2);
	if (_x == 2) || (_y == 2) return "Real";
	if (_x == 0) && (_y == 0) && ((_op == "+") || (_op == "-") || (_op == "mod")) return "Int";
	return "Double";
}

#region jsDoc
/// @func    __gmlc_type_atom_binary(_op, _a, _b)
/// @desc    What GameMaker's VM gives for an operator on two atoms, or undefined when it throws:
///          an int64 with a real gives a real, a string in `-`, `/` and `mod` must hold a
///          number, `number * string` repeats the string, bitwise operators give an int64.
/// @param   {String} _op : The operator
/// @param   {String} _a  : The left atom
/// @param   {String} _b  : The right atom
/// @returns {String|Undefined}
#endregion
function __gmlc_type_atom_binary(_op, _a, _b) {
	var _x = __gmlc_type_kind(_a);
	var _y = __gmlc_type_kind(_b);
	if (_x == "o") || (_y == "o") return undefined;
	switch (_op) {
		case "&": case "|": case "^": case "<<": case ">>": return "Int64";
		case "+":
			if (_x == "s") return (_y == "s") ? "String" : undefined;
			if (_y == "s") return (_x == "i") ? "Int64" : "Real";
			if (_x == "i") && (_y == "i") return "Int64";
			if (_x == "i") || (_y == "i") return "Real";
			return __gmlc_type_number_kind(_op, _a, _b);
		case "*":
			if (_x == "s") || ((_x == "i") && (_y == "s")) return undefined;
			if (_y == "s") return "String";
			if (_x == "i") && (_y == "i") return "Int64";
			if (_x == "i") || (_y == "i") return "Real";
			return __gmlc_type_number_kind(_op, _a, _b);
		case "-": case "/": case "mod":
			if (_x == "s") || (_y == "s") return "Real";
			if (_x == "i") && (_y == "i") return "Int64";
			if (_x == "i") || (_y == "i") return "Real";
			return __gmlc_type_number_kind(_op, _a, _b);
		case "div":
			if (_y == "i") return "Int64";
			if (_x == "s") || (_y == "s") || (_x == "i") return "Real";
			return "Int";
	}
	return "Unknown";
}

#region jsDoc
/// @func    __gmlc_type_of(_node, _state, _cx)
/// @desc    The type of an expression in a state.
#endregion
function __gmlc_type_of(_node, _state, _cx) {
	if (_node == undefined) return { type: "Unknown", provenance: "proven" };
	switch (_node.kind) {
		case __GMLC_NodeKind_Literal:
			switch (_node.ty) {
				case "real": case "color":
					var _v = _node.value;
					return { type: (is_real(_v) && __gmlc_is_whole(_v)) ? "Int" : "Double", provenance: "proven" };
				case "int64":
					var _origin = _node[$ "origin"];
					if (_origin != undefined) && (_origin.kind == "enum") return { type: "Enum." + _origin.name, provenance: "proven" };
					return { type: "Int64", provenance: "proven" };
				case "string": return { type: "String", provenance: "proven" };
				case "bool": return { type: "Bool", provenance: "proven" };
				case "undefined": return { type: "Undefined", provenance: "proven" };
			}
			return { type: "Unknown", provenance: "proven" };
		// an omitted argument (`f(a,, b)`) passes undefined
		case __GMLC_NodeKind_Empty: return { type: "Undefined", provenance: "proven" };
		case __GMLC_NodeKind_Identifier:
			if (__gmlc_opt_is_local(_node)) {
				var _f = _state[$ _node.name];
				if (_f != undefined) return { type: _f.type, provenance: _f.provenance };
			}
			if (_node.symbol != undefined) {
				// a field read by its holder's group, where the group is known
				var _isField = false;
				switch (_node.symbol.kind) {
					case "Self": case "Static": _isField = (__gmlc_opt_builtin_variable(_node.name) == undefined); break;
					case "Global": _isField = (!struct_exists(_cx.named, _node.name)) && (!struct_exists(_cx.batch, _node.name)); break;
				}
				if (_isField) {
					var _content = __gmlc_type_held_content(_node, _state, _cx);
					if (_content != undefined) return { type: _content, provenance: "proven" };
				}
				// `self` and `other` in object event code outside `with` (`self` in a `with` over instances) are instances;
				// elsewhere `self` may be a struct
				if ((_node.symbol.kind == "BuiltinVar") || (_node.symbol.kind == "BuiltinConstant")) && ((_node.name == "self") || (_node.name == "other")) {
					if (_node.name == "self") && (_cx.self_holder == "i") return { type: "Id.Instance", provenance: "proven" };
					if (_node.name == "other") && (_cx.self_instance) return { type: "Id.Instance", provenance: "proven" };
					return { type: "Unknown", provenance: "proven" };
				}
				switch (_node.symbol.kind) {
					case "BuiltinConstant": {
						var _constants = __gmlc_type_constants();
						return { type: _constants[$ _node.name] ?? "Unknown", provenance: "proven" };
					}
					case "BuiltinVar":      return { type: __gmlc_type_variable(_node.name), provenance: "proven" };
					// a function's name used as a value is the function
					case "BuiltinFunction": return { type: "Function(...Any)->Unknown", provenance: "proven" };
					case "Global":
						if (struct_exists(_cx.named, _node.name)) || (struct_exists(_cx.batch, _node.name)) return { type: "Function(...Any)->Unknown", provenance: "proven" };
						break;
					case "Self": case "Static":
						if (_node.symbol.kind == "Self") && (_cx.self_instance) && (__gmlc_opt_builtin_variable(_node.name) != undefined) {
							return { type: __gmlc_type_instance_variable(_node.name), provenance: "proven" };
						}
						// a static is the function's own; an instance variable read in object event code outside `with`
						// reads an instance, which no parsed struct is
						if (struct_exists(_cx.fields, _node.name)) && ((_node.symbol.kind == "Static") || (!_cx.structs_open) || (_cx.self_instance) || (__gmlc_type_grouped(_cx.self_holder, _cx))) {
							var _class = ((_node.symbol.kind == "Self") && (_cx.self_instance)) ? "inst" : "";
							return { type: __gmlc_type_field_read(_node.name, _class, _cx), provenance: "proven" };
						}
						break;
				}
			}
			return { type: "Unknown", provenance: "proven" };
		case __GMLC_NodeKind_Binary: {
			var _a = __gmlc_type_of(_node.left, _state, _cx);
			var _b = __gmlc_type_of(_node.right, _state, _cx);
			return { type: __gmlc_type_binary(_node.op, _a.type, _b.type), provenance: __gmlc_type_prov(_a, _b) };
		}
		case __GMLC_NodeKind_Logical: {
			var _a = __gmlc_type_of(_node.left, _state, _cx);
			var _b = __gmlc_type_of(_node.right, _state, _cx);
			return { type: "Bool", provenance: __gmlc_type_prov(_a, _b) };
		}
		case __GMLC_NodeKind_Unary: {
			var _a = __gmlc_type_of(_node.argument, _state, _cx);
			var _t = "Unknown";
			switch (_node.op) {
				case "!": _t = "Bool"; break;
				case "~": case "-": _t = __gmlc_type_unary(_node.op, _a.type); break;
				// `+x` gives `x` as it is
				case "+": _t = _a.type; break;
			}
			return { type: _t, provenance: _a.provenance };
		}
		case __GMLC_NodeKind_Update:
			return __gmlc_type_of(_node.argument, _state, _cx);
		case __GMLC_NodeKind_Conditional: {
			var _a = __gmlc_type_of(_node.consequent, _state, _cx);
			var _b = __gmlc_type_of(_node.alternate, _state, _cx);
			return { type: gmlc_type_join(_a.type, _b.type), provenance: __gmlc_type_prov(_a, _b) };
		}
		case __GMLC_NodeKind_Nullish: {
			var _a = __gmlc_type_of(_node.left, _state, _cx);
			var _b = __gmlc_type_of(_node.right, _state, _cx);
			return { type: gmlc_type_join(__gmlc_type_remove(_a.type, "Undefined"), _b.type), provenance: __gmlc_type_prov(_a, _b) };
		}
		case __GMLC_NodeKind_ArrayLiteral: {
			var _t = "Never";
			var _prov = { provenance: "proven" };
			var _i = 0; repeat (array_length(_node.elements)) {
				var _e = __gmlc_type_of(_node.elements[_i], _state, _cx);
				_t = gmlc_type_join(_t, _e.type);
				_prov = { provenance: __gmlc_type_prov(_prov, _e) };
			_i++}
			return { type: "Array<" + ((_t == "Never") ? "Any" : _t) + ">", provenance: _prov.provenance };
		}
		case __GMLC_NodeKind_StructLiteral: return { type: "Struct", provenance: "proven" };
		// a method only the project's own calls reach gives what the methods of its name return
		case __GMLC_NodeKind_MethodCall:
			var _methodKey = "m:" + _node.member;
			var _methodReturn = _cx.batch[$ _methodKey];
			if (_methodReturn != undefined) && (struct_exists(_cx.params, _methodKey)) return { type: _methodReturn, provenance: "proven" };
			// `x.f(...)` of a field that holds functions returns what they return
			var _fieldCalled = __gmlc_type_call_targets(_node, _state, _cx);
			if (_fieldCalled == undefined) return { type: "Unknown", provenance: "proven" };
			var _fieldReturn = "Never";
			var _fc = 0; repeat (array_length(_fieldCalled)) {
				var _fieldOne = _cx.batch[$ _fieldCalled[_fc]];
				if (_fieldOne == undefined) return { type: "Unknown", provenance: "proven" };
				_fieldReturn = gmlc_type_join(_fieldReturn, _fieldOne);
			_fc++}
			return { type: _fieldReturn, provenance: "proven" };
		case __GMLC_NodeKind_Index:
			// an element of an array: what its holder's group holds in its elements
			if (_node.accessor == "Array") || (_node.accessor == "ArrayAt") || (_node.accessor == "Array2D") {
				var _holder = __gmlc_type_holder_of(_node, _state, _cx);
				var _elements = (_holder != undefined) ? __gmlc_type_place_type(_holder, _cx.arrays, _cx.elements, _cx.escaped) : undefined;
				return { type: _elements ?? __gmlc_type_no_elements(_cx), provenance: "proven" };
			}
			// a list or grid cell: what its kind holds, or undefined past the end
			if (_node.accessor == "List") || (_node.accessor == "Grid") {
				var _cell = __gmlc_type_held_element(_node, _state, _cx);
				if (_cell != undefined) return { type: gmlc_type_join(_cell, "Undefined"), provenance: "proven" };
				var _held_cell = _cx.fields[$ (_node.accessor == "List") ? "|list" : "|grid"];
				return { type: (_held_cell != undefined) ? gmlc_type_join(_held_cell, "Undefined") : "Unknown", provenance: "proven" };
			}
			if (_node.accessor == "Dot") || (_node.accessor == "Struct") || (_node.accessor == "Map") {
				if (_node.accessor != "Map") {
					var _fieldContent = __gmlc_type_held_content(_node, _state, _cx);
					if (_fieldContent != undefined) return { type: (_node.accessor == "Struct") ? gmlc_type_join(_fieldContent, "Undefined") : _fieldContent, provenance: "proven" };
				}
				// a ds_map key is no struct field; a struct field read reads a parsed struct only when its owner may be one
				var _sure = (_node.accessor == "Map") || (!_cx.structs_open) || (__gmlc_type_made_by_code(_node.object, _state, _cx))
					|| (__gmlc_type_grouped(__gmlc_type_holder_of(_node.object, _state, _cx), _cx));
				var _read = __gmlc_type_field_of(_node);
				if (_sure) && (_read != undefined) && (_read.name != "*") && (struct_exists(_cx.fields, _read.name)) {
					// `s[$ "name"]` and `m[? "key"]` give undefined where there is no such key; `s.name` throws there
					var _held = (string_char_at(_read.name, 1) == "?") ? _cx.fields[$ _read.name]
						: __gmlc_type_field_read(_read.name, __gmlc_type_owner_class(_node.object, _state, _cx), _cx);
					return { type: (_node.accessor != "Dot") ? gmlc_type_join(_held, "Undefined") : _held, provenance: "proven" };
				}
				if (_node.accessor == "Map") {
					var _value = __gmlc_type_held_element(_node, _state, _cx);
					if (_value != undefined) return { type: gmlc_type_join(_value, "Undefined"), provenance: "proven" };
				}
			}
			return { type: "Unknown", provenance: "proven" };
		case __GMLC_NodeKind_New:
			// a constructor named by its global name makes its struct; `new` of another value may make any struct
			var _ctor = _node.callee;
			if (_ctor.kind == __GMLC_NodeKind_Identifier) && (_ctor.symbol != undefined) && (_ctor.symbol.kind == "Global") return { type: "Struct." + _ctor.name, provenance: "proven" };
			return { type: "Unknown", provenance: "proven" };
		case __GMLC_NodeKind_TemplateString: case __GMLC_NodeKind_Nameof:
			return { type: "String", provenance: "proven" };
		case __GMLC_NodeKind_FunctionExpr: return { type: "Function(...Any)->Unknown", provenance: "proven" };
		case __GMLC_NodeKind_Call:
			if (_node.callee.kind == __GMLC_NodeKind_Identifier) {
				var _name = _node.callee.name;
				var _symbol = _node.callee.symbol;
				if (_symbol != undefined) && (_symbol.kind == "BuiltinFunction") {
					switch (_name) {
						case "array_length": case "string_length": case "ds_list_size": case "irandom":
							return { type: "Int", provenance: "proven" };
						// one of its arguments, or a copy of its argument
						case "choose": case "variable_clone":
							if (array_length(_node.args) > 0) {
								var _count = (_name == "choose") ? array_length(_node.args) : 1;
								var _joined = { type: "Never", provenance: "proven" };
								var _c = 0; repeat (_count) {
									var _arg = __gmlc_type_of(_node.args[_c], _state, _cx);
									_joined = { type: gmlc_type_join(_joined.type, _arg.type), provenance: __gmlc_type_prov(_joined, _arg) };
								_c++}
								return _joined;
							}
							break;
						case "array_reduce":
							var _reduceKeys = (array_length(_node.args) > 1) ? __gmlc_type_value_targets(_node.args[1], _state, _cx) : undefined;
							if (_reduceKeys != undefined) {
								var _reduced = (array_length(_node.args) > 2) ? __gmlc_type_of(_node.args[2], _state, _cx).type : "Never";
								var _rk = 0; repeat (array_length(_reduceKeys)) {
									var _reduceReturn = _cx.batch[$ _reduceKeys[_rk]];
									if (_reduceReturn == undefined) return { type: "Unknown", provenance: "proven" };
									_reduced = gmlc_type_join(_reduced, _reduceReturn);
								_rk++}
								return { type: _reduced, provenance: "proven" };
							}
							break;
						case "buffer_read": case "buffer_peek":
							var _at = (_name == "buffer_read") ? 1 : 2;
							var _buffer_type = (_at < array_length(_node.args)) ? __gmlc_type_buffer_type(_node.args[_at]) : undefined;
							if (_buffer_type != undefined) return { type: _buffer_type, provenance: "proven" };
							break;
						case "ds_map_find_value":
							if (array_length(_node.args) == 2) {
								var _held_key = _cx.fields[$ __gmlc_type_map_key(_node.args[1])];
								if (_held_key != undefined) return { type: gmlc_type_join(_held_key, "Undefined"), provenance: "proven" };
								var _held_value = __gmlc_type_held_element(_node, _state, _cx);
								if (_held_value != undefined) return { type: gmlc_type_join(_held_value, "Undefined"), provenance: "proven" };
							}
							break;
						case "ds_list_find_value": case "ds_grid_get": case "ds_stack_pop": case "ds_stack_top":
						case "ds_queue_dequeue": case "ds_queue_head": case "ds_queue_tail":
						case "ds_priority_find_max": case "ds_priority_find_min": case "ds_priority_delete_max": case "ds_priority_delete_min":
							var _held_read = __gmlc_type_held_element(_node, _state, _cx);
							if (_held_read != undefined) return { type: gmlc_type_join(_held_read, "Undefined"), provenance: "proven" };
							var _held_ds = _cx.fields[$ __gmlc_type_ds_reader(_name)];
							if (_held_ds != undefined) return { type: gmlc_type_join(_held_ds, "Undefined"), provenance: "proven" };
							break;
						case "floor": case "ceil": case "round":
							if (array_length(_node.args) == 1) {
								var _a = __gmlc_type_of(_node.args[0], _state, _cx);
								if (_a.type == "Int") return { type: "Int", provenance: _a.provenance };
							}
							break;
					}
					// a struct a built-in gives may be any struct, a constructor's too: `Struct` alone is a literal's
					var _r = _cx.builtins[$ _name] ?? "Unknown";
					return { type: (_r == "Struct") ? "Unknown" : _r, provenance: "proven" };
				}
				var _fn = ((_symbol != undefined) && (_symbol.kind == "Global")) ? _cx.named[$ _name] : undefined;
				if (_fn != undefined) {
					var _r = _cx.returns[$ string(_fn)];
					if (_r != undefined) return { type: _r.type, provenance: _r.provenance };
				}
				if (_symbol != undefined) && (_symbol.kind == "Global") {
					var _batchReturn = _cx.batch[$ _name];
					if (_batchReturn != undefined) return { type: _batchReturn, provenance: "proven" };
				}
				// a method called by its name through `self`
				if (_symbol != undefined) && ((_symbol.kind == "Self") || (_symbol.kind == "Static")) && (struct_exists(_cx.params, "m:" + _name)) {
					var _selfReturn = _cx.batch[$ "m:" + _name];
					if (_selfReturn != undefined) return { type: _selfReturn, provenance: "proven" };
				}
			}
			// a call of a value returns what the functions it may call return
			var _called = __gmlc_type_call_targets(_node, _state, _cx);
			if (_called != undefined) {
				var _calledType = "Never";
				var _ck = 0; repeat (array_length(_called)) {
					var _calledReturn = _cx.batch[$ _called[_ck]];
					if (_calledReturn == undefined) return { type: "Unknown", provenance: "proven" };
					_calledType = gmlc_type_join(_calledType, _calledReturn);
				_ck++}
				return { type: _calledType, provenance: "proven" };
			}
			return { type: "Unknown", provenance: "proven" };
	}
	return { type: "Unknown", provenance: "proven" };
}
#endregion
