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
	var _list = [];
	var _i = 0; repeat (array_length(_members)) {
		if (!array_contains(_list, _members[_i])) array_push(_list, _members[_i]);
	_i++}
	var _kept = [];
	_i = 0; repeat (array_length(_list)) {
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
	var _units = [{ fn_id: 0, params: [], body: _ast.body, node: undefined }];
	__gmlc_analysis_units(_ast, _units);
	array_sort(_units, function(_a, _b) { return _a.fn_id - _b.fn_id; });
	var _named = {};
	var _u = 0; repeat (array_length(_units)) {
		var _node = _units[_u].node;
		if (_node != undefined) && ((_node.kind == __GMLC_NodeKind_FunctionDecl) || (_node.kind == __GMLC_NodeKind_ConstructorDecl)) {
			_named[$ _node.name] = _units[_u].fn_id;
		}
	_u++}
	var _cx = { named: _named, returns: {}, builtins: __gmlc_type_builtins() };
	var _out = [];
	var _round = 0; repeat (2) {
		_out = [];
		var _returns = {};
		_u = 0; repeat (array_length(_units)) {
			var _unit = _units[_u];
			var _info = (_unit.fn_id < array_length(_ast.functions)) ? _ast.functions[_unit.fn_id] : undefined;
			var _name = ((_info != undefined) && (_info.name != undefined)) ? _info.name : "";
			var _facts = __gmlc_type_function_facts(_unit, _name, _sources, _cx);
			_returns[$ string(_unit.fn_id)] = { type: _facts.returns, provenance: _facts.returns_provenance };
			array_push(_out, _facts);
		_u++}
		_cx.returns = _returns;
	_round++}
	return { functions: _out };
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
/// @func    __gmlc_type_jsdoc(_node, _sources)
/// @desc    The JSDoc @param types above a function: name to {type, optional}.
#endregion
function __gmlc_type_jsdoc(_node, _sources) {
	var _out = {};
	if (_node == undefined) || (_sources == undefined) || (_node.span.file >= array_length(_sources.files)) return _out;
	var _file = _sources.files[_node.span.file];
	if (_file == undefined) return _out;
	var _line = _file.lineOf(_node.span.start) - 1;
	var _lines = [];
	while (_line >= 1) {
		var _text = __gmlc_type_trim(_file.lineText(_line));
		if (!string_starts_with(_text, "///")) break;
		array_insert(_lines, 0, __gmlc_type_trim(string_delete(_text, 1, 3)));
		_line--;
	}
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
/// @func    __gmlc_type_function_facts(_unit, _name, _sources, _cx)
/// @desc    The flow facts of one function: its locals' facts where it ends and its return type.
/// @param   {Struct}                  _unit    : The function, {fn_id, params, body, node}
/// @param   {String}                  _name    : Its name
/// @param   {Struct.GMLC_SourceTable} _sources : The files, for its JSDoc
/// @param   {Struct}                  _cx      : {named, returns, builtins} of the script
/// @returns {Struct} {fn_id, name, returns, returns_provenance, locals}
#endregion
function __gmlc_type_function_facts(_unit, _name, _sources, _cx) {
	var _g = __gmlc_cfg_build(_unit);
	var _n = array_length(_g.nodes);
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
		if (__gmlc_is_local(_param)) {
			var _doc = _jsdoc[$ _param.name];
			if (_doc != undefined) {
				_start[$ _param.name] = { type: _doc.optional ? gmlc_type_join(_doc.type, "Undefined") : _doc.type, provenance: "annotated", assigned: "yes" };
			}
			else _start[$ _param.name] = { type: "Unknown", provenance: "proven", assigned: "yes" };
		}
	_p++}
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
	// the return type: every return value, and Undefined when the function can end without one
	var _returns = "Never";
	var _provenance = "proven";
	var _q = 0; repeat (array_length(_preds[1])) {
		var _node = _g.nodes[_preds[1][_q]];
		var _stmt = _node.stmt;
		if (_node.kind == "Return") && (_stmt.argument != undefined) {
			var _t = __gmlc_type_of(_stmt.argument, __gmlc_type_copy(_in[_preds[1][_q]]), _cx);
			_returns = gmlc_type_join(_returns, _t.type);
			if (_t.provenance == "annotated") _provenance = "annotated";
		}
		else if (_node.kind != "Throw") _returns = gmlc_type_join(_returns, "Undefined");
	_q++}
	var _locals = [];
	var _end = _in[1];
	var _names = struct_get_names(_end);
	array_sort(_names, function(_a, _b) { return __gmlc_type_bytes_compare(_a, _b); });
	var _k = 0; repeat (array_length(_names)) {
		var _f = _end[$ _names[_k]];
		array_push(_locals, { name: _names[_k], type: _f.type, provenance: _f.provenance, assigned: _f.assigned });
	_k++}
	return { fn_id: _unit.fn_id, name: _name, returns: _returns, returns_provenance: _provenance, locals: _locals };
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
			if (_stmt.catch_param != undefined) && (__gmlc_is_local(_stmt.catch_param)) {
				__gmlc_type_set(_state, _stmt.catch_param.name, { type: "Unknown", provenance: "proven" }, false);
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
	switch (_node.kind) {
		case __GMLC_NodeKind_FunctionExpr: case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl:
			return;
		case __GMLC_NodeKind_VarDecl:
			__gmlc_type_walk(_node.init, _state, _cx, _maybe);
			if (__gmlc_is_local(_node.target)) {
				var _t = (_node.init != undefined) ? __gmlc_type_of(_node.init, _state, _cx) : { type: "Undefined", provenance: "proven" };
				__gmlc_type_set(_state, _node.target.name, _t, _maybe);
			}
			return;
		case __GMLC_NodeKind_Assign:
			if (__gmlc_is_local(_node.target)) {
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
			__gmlc_type_walk(_node.target, _state, _cx, _maybe);
			__gmlc_type_walk(_node.value, _state, _cx, _maybe);
			return;
		case __GMLC_NodeKind_Update:
			__gmlc_type_walk(_node.argument, _state, _cx, _maybe);
			if (__gmlc_is_local(_node.argument)) {
				var _cur = __gmlc_type_of(_node.argument, _state, _cx);
				__gmlc_type_set(_state, _node.argument.name, { type: __gmlc_type_binary(string_char_at(_node.op, 1), _cur.type, "Int"), provenance: _cur.provenance }, _maybe);
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
	var _children = _node.children();
	var _i = 0; repeat (array_length(_children)) {
		__gmlc_type_walk(_children[_i], _state, _cx, _maybe);
	_i++}
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
/// @func    __gmlc_type_binary(_op, _a, _b)
/// @desc    The type of a binary operation: Bool for a comparison, a number type for two numbers, String for `+` of
///          two strings, else Unknown.
/// @param   {String} _op : The operator
/// @param   {String} _a  : The left type
/// @param   {String} _b  : The right type
/// @returns {String}
#endregion
function __gmlc_type_binary(_op, _a, _b) {
	switch (_op) {
		case "==": case "!=": case "<": case "<=": case ">": case ">=": return "Bool";
		case "+":
			if (_a == "String") && (_b == "String") return "String";
		case "-": case "*": case "/":
			var _numericA = (_a == "Int") || (_a == "Double");
			var _numericB = (_b == "Int") || (_b == "Double");
			if (!_numericA) || (!_numericB) return "Unknown";
			if (_op == "/") || (_op == "*") return "Double";
			return ((_a == "Int") && (_b == "Int")) ? "Int" : "Double";
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
		case __GMLC_NodeKind_Identifier:
			if (__gmlc_is_local(_node)) {
				var _f = _state[$ _node.name];
				if (_f != undefined) return { type: _f.type, provenance: _f.provenance };
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
			if (_node.op == "!") _t = "Bool";
			else if ((_node.op == "-") || (_node.op == "+")) && ((_a.type == "Int") || (_a.type == "Double")) _t = _a.type;
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
		case __GMLC_NodeKind_New:
			return { type: (_node.callee.kind == __GMLC_NodeKind_Identifier) ? "Struct." + _node.callee.name : "Struct", provenance: "proven" };
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
						case "floor": case "ceil": case "round":
							if (array_length(_node.args) == 1) {
								var _a = __gmlc_type_of(_node.args[0], _state, _cx);
								if (_a.type == "Int") return { type: "Int", provenance: _a.provenance };
							}
							break;
					}
					return { type: _cx.builtins[$ _name] ?? "Unknown", provenance: "proven" };
				}
				var _fn = _cx.named[$ _name];
				if (_fn != undefined) {
					var _r = _cx.returns[$ string(_fn)];
					if (_r != undefined) return { type: _r.type, provenance: _r.provenance };
				}
			}
			return { type: "Unknown", provenance: "proven" };
	}
	return { type: "Unknown", provenance: "proven" };
}
#endregion
