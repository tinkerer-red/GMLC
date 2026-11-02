#region Enums
// the kinds of value a fact allows, as bits
enum GMLC_RANGE_KIND {
	UNDEFINED = 1,
	BOOL = 2,
	REAL = 4,
	INT64 = 8,
	STRING = 16,
	ARRAY = 32,
	STRUCT = 64,
	OTHER = 128,
	NUMERIC = 6,
	ALL = 255,
}

// how a value relates to the length of an array local
enum GMLC_RANGE_REL {
	NONE,
	LE,
	LT,
}
#endregion

#region jsDoc
/// @func    GMLC_Opt_ValueRangeSimplify()
/// @desc    The `value-range-simplify` optimizer pass, and the range analysis the type-driven passes share. It
///          walks a function once, keeping for each `var` local the kinds of value it can hold and an interval with
///          not-NaN, integral and negative-zero flags, and removes the calls and comparisons those facts decide:
///          `clamp(_i, 0, 9)` with `_i` in [0, 9] becomes `_i`, `max(_i, 0)` becomes `_i`, `abs(_x)` of a negative
///          `_x` becomes `-_x`, and `_i >= 0` for a counter that starts at 0 and only counts up becomes `true`.
///          Only facts read from the tree gate a rewrite, and a comparison on reals is decided only where the
///          default epsilon cannot change the answer.
/// @returns {Struct.GMLC_Opt_ValueRangeSimplify}
#endregion
function GMLC_Opt_ValueRangeSimplify() : GMLC_OptimizerPass("value-range-simplify") constructor {
	#region Config
	static __margin = 0.0001;
	static __lenMax = 2147483647;
	static __bound = 1000000000;
	static __exact = 9007199254740992;
	#endregion

	#region Pass
	#region jsDoc
	/// @func    run(_node, _cx)
	/// @desc    Removes the `min`, `max`, `clamp`, `abs` and `sign` calls and the comparisons that the value ranges
	///          of the function decide. An operand that is dropped must be free of effects and unable to throw.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct.ASTNode} _node : The function
	/// @param   {Struct}         _cx   : The pass context
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static run = function(_node, _cx) {
		var _w = analyze(_node, _cx, [__GMLC_NodeKind_Call, __GMLC_NodeKind_Binary]);
		var _edits = [];
		var _events = _w.events;
		var _i = 0; repeat (array_length(_events)) {
			var _e = _events[_i];
			var _edit = undefined;
			var _is_call = (_e.node.kind == __GMLC_NodeKind_Call);
			if (_is_call) {
				_edit = __decideCall(_e, _cx);
			}
			else if (!_cx.epsilon_set) {
				_edit = __decideCompare(_e, _cx);
			}
			if (_edit != undefined) && (!_cx.optimizer.__containsNoOp(_e.node)) {
				_edit.path = _e.path;
				array_push(_edits, _edit);
				_cx.stats[$ _is_call ? "calls_simplified" : "comparisons_decided"]++;
			}
		_i++}
		return applyEdits(_node, _edits);
	};

	#region jsDoc
	/// @func    __decideCall(_event, _cx)
	/// @desc    The rewrite of a `min`, `max`, `clamp`, `abs` or `sign` call, or undefined.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _event : The call and the facts of its arguments
	/// @param   {Struct} _cx    : The pass context
	/// @returns {Struct|Undefined}
	#endregion
	static __decideCall = function(_event, _cx) {
		var _name = __gmlc_opt_builtin_call(_event.node);
		if (_name == undefined) return undefined;
		var _operands = _event.operands;
		var _n = array_length(_operands);
		switch (_name) {
			case "min": case "max": {
				if (_n != 2) || (_cx.epsilon_set) return undefined;
				var _a = _operands[0];
				var _b = _operands[1];
				if (_a.f.k != GMLC_RANGE_KIND.REAL) || (_b.f.k != GMLC_RANGE_KIND.REAL) || (_a.f.nan) || (_b.f.nan) return undefined;
				var _a_first = (_name == "min") ? __orderedLe(_a.f, _b.f) : __orderedLe(_b.f, _a.f);
				var _b_first = (_name == "min") ? __orderedLe(_b.f, _a.f) : __orderedLe(_a.f, _b.f);
				if (_a_first) && (_b.safe) return { op: "child", i: 1 };
				if (_b_first) && (_a.safe) return { op: "child", i: 2 };
				return undefined;
			}
			case "clamp": {
				if (_n != 3) || (_cx.epsilon_set) return undefined;
				var _x = _operands[0];
				var _lo = _operands[1];
				var _hi = _operands[2];
				var _j = 0; repeat (3) {
					if (_operands[_j].f.k != GMLC_RANGE_KIND.REAL) || (_operands[_j].f.nan) return undefined;
				_j++}
				if (!_lo.safe) || (!_hi.safe) return undefined;
				if (__orderedLe(_lo.f, _x.f)) && (__orderedLe(_x.f, _hi.f)) return { op: "child", i: 1 };
				return undefined;
			}
			case "floor": case "ceil": case "round": {
				// a whole number, an infinity or NaN is its own floor, ceiling and rounding
				if (_n != 1) return undefined;
				var _w = _operands[0].f;
				if (_w.k == GMLC_RANGE_KIND.REAL) && (_w.whole) return { op: "child", i: 1 };
				return undefined;
			}
			case "abs": {
				if (_n != 1) return undefined;
				var _a = _operands[0].f;
				if (_a.k != GMLC_RANGE_KIND.REAL) return undefined;
				if (_a.lo >= 0) && (!_a.nz) return { op: "child", i: 1 };
				if (_a.hi < 0) return { op: "negate", i: 1 };
				return undefined;
			}
			case "sign": {
				if (_n != 1) return undefined;
				var _a = _operands[0];
				if (_a.f.k != GMLC_RANGE_KIND.REAL) || (_a.f.nan) || (!_a.safe) return undefined;
				var _value = undefined;
				if (_a.f.lo > 0) {
					_value = 1;
				}
				else if (_a.f.hi < 0) {
					_value = -1;
				}
				else if (_a.f.lo == 0) && (_a.f.hi == 0) && (!_a.f.nz) {
					_value = 0;
				}
				if (_value == undefined) return undefined;
				var _literal = _cx.optimizer.__literal(_value, _event.node.span);
				if (_literal == undefined) return undefined;
				return { op: "literal", node: _literal };
			}
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __decideCompare(_event, _cx)
	/// @desc    The `true` or `false` a comparison always gives, or undefined.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _event : The comparison and the facts of its operands
	/// @param   {Struct} _cx    : The pass context
	/// @returns {Struct|Undefined}
	#endregion
	static __decideCompare = function(_event, _cx) {
		var _op = _event.node.op;
		if (!__isCompare(_op)) return undefined;
		var _a = _event.operands[0];
		var _b = _event.operands[1];
		if (!_a.safe) || (!_b.safe) return undefined;
		var _decided = __decide(_op, _a.f, _b.f);
		if (_decided == -1) return undefined;
		var _literal = _cx.optimizer.__literal(_decided == 1, _event.node.span);
		if (_literal == undefined) return undefined;
		return { op: "literal", node: _literal };
	};

	#region jsDoc
	/// @func    __orderedLe(_a, _b)
	/// @desc    Whether _a is surely not above _b in a way that picking either one gives the same answer under the
	///          epsilon: both integral and non-negative-zero with _a at most _b, or _a below _b by more than the
	///          margin.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _a : A fact
	/// @param   {Struct} _b : A fact
	/// @returns {Bool}
	#endregion
	static __orderedLe = function(_a, _b) {
		if (_a.whole) && (_b.whole) && (!_a.nz) && (!_b.nz) return _a.hi <= _b.lo;
		return __sepLt(_a, _b);
	};
	#endregion

	#region Edits
	#region jsDoc
	/// @func    applyEdits(_root, _edits)
	/// @desc    A copy of a function with the edits made, or undefined when there are none. An edit is the path of a
	///          node (child positions from the function) and what takes its place: `child` (its own child `i`),
	///          `negate` (the minus of its child `i`), `literal` (a node), or `div` (the `div` of the operands of
	///          its child `i`). Edits come inner ones first, so a replacement is built from the copy as edited.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct.ASTNode} _root  : The function
	/// @param   {Array<Struct>}  _edits : The edits, inner ones first
	/// @returns {Struct.ASTNode|Undefined}
	#endregion
	static applyEdits = function(_root, _edits) {
		if (array_length(_edits) == 0) return undefined;
		var _copy = __gmlc_opt_clone(_root);
		var _changed = false;
		var _i = 0; repeat (array_length(_edits)) {
			var _edit = _edits[_i];
			var _slot = __slotAt(_copy, _edit.path);
			if (_slot != undefined) {
				var _old = _slot.node;
				var _children = _old.children();
				var _new = undefined;
				switch (_edit.op) {
					case "child": _new = _children[_edit.i]; break;
					case "negate": _new = new ASTUnary(_old.span, "-", _children[_edit.i]); break;
					case "literal": _new = _edit.node; break;
					case "div": {
						var _inner = _children[_edit.i];
						_new = new ASTBinary(_old.span, "div", _inner.left, _inner.right);
					break;}
				}
				if (_new != undefined) {
					if (_slot.index == undefined) {
						_slot.parent[$ _slot.key] = _new;
					}
					else {
						_slot.parent[$ _slot.key][_slot.index] = _new;
					}
					_changed = true;
				}
			}
		_i++}
		return _changed ? _copy : undefined;
	};

	#region jsDoc
	/// @func    __slotAt(_root, _path)
	/// @desc    The slot that holds the node at a path of child positions below a node.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct.ASTNode} _root : The node the path starts at
	/// @param   {Array<Real>}    _path : Child positions
	/// @returns {Struct|Undefined} {node, parent, key, index}
	#endregion
	static __slotAt = function(_root, _path) {
		var _cur = _root;
		var _slot = undefined;
		var _i = 0; repeat (array_length(_path)) {
			var _slots = _cur.childSlots();
			if (_path[_i] >= array_length(_slots)) return undefined;
			_slot = _slots[_path[_i]];
			_cur = _slot.node;
		_i++}
		return _slot;
	};
	#endregion

	#region Facts
	#region jsDoc
	/// @func    __fact(_k, _lo, _hi, _whole, _nan, _nz)
	/// @desc    A fact about a value: the kinds it can have and, for its Real and Bool part, an interval with flags
	///          for integral, may be NaN and may be negative zero. A fact is never changed after it is made.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Real} _k     : Kinds, a GMLC_RANGE_KIND mask
	/// @param   {Real} _lo    : Lowest value
	/// @param   {Real} _hi    : Highest value
	/// @param   {Bool} _whole : Whether every value is integral
	/// @param   {Bool} _nan   : Whether the value may be NaN
	/// @param   {Bool} _nz    : Whether the value may be negative zero
	/// @returns {Struct}
	#endregion
	static __fact = function(_k, _lo, _hi, _whole, _nan, _nz) {
		return { k: _k, lo: _lo, hi: _hi, whole: _whole, nan: _nan, nz: _nz, rel: GMLC_RANGE_REL.NONE, rel_of: "", len_lo: 0 };
	};

	static __top = __fact(GMLC_RANGE_KIND.ALL, -infinity, infinity, false, true, true);

	#region jsDoc
	/// @func    __kindFact(_k)
	/// @desc    A fact that only limits the kinds.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Real} _k : Kinds
	/// @returns {Struct}
	#endregion
	static __kindFact = function(_k) {
		return __fact(_k, -infinity, infinity, false, true, true);
	};

	#region jsDoc
	/// @func    __real(_lo, _hi, _whole, _nan, _nz)
	/// @desc    A fact about a Real.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __real = function(_lo, _hi, _whole, _nan, _nz) {
		return __fact(GMLC_RANGE_KIND.REAL, _lo, _hi, _whole, _nan, _nz && (_lo <= 0) && (_hi >= 0));
	};

	#region jsDoc
	/// @func    __heldFact(_node)
	/// @desc    The fact of a local the walk has no fact for: the type it holds wherever it is read
	///          (__gmlc_opt_local_type), as kinds (`Int` also whole and never NaN).
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct.ASTNode} _node : The local
	/// @returns {Struct}
	#endregion
	static __heldFact = function(_node) {
		var _type = __gmlc_opt_local_type(_node);
		if (_type == undefined) return __top;
		switch (_type) {
			case "Int":       return __real(-infinity, infinity, true, false, true);
			case "Double":    return __kindFact(GMLC_RANGE_KIND.REAL);
			case "Real":      return __kindFact(GMLC_RANGE_KIND.REAL | GMLC_RANGE_KIND.INT64);
			case "Int64":     return __kindFact(GMLC_RANGE_KIND.INT64);
			case "Bool":      return __kindFact(GMLC_RANGE_KIND.BOOL);
			case "String":    return __kindFact(GMLC_RANGE_KIND.STRING);
			case "Undefined": return __kindFact(GMLC_RANGE_KIND.UNDEFINED);
		}
		if (string_starts_with(_type, "Enum.")) return __kindFact(GMLC_RANGE_KIND.INT64);
		if (string_starts_with(_type, "Constant.")) return __kindFact(GMLC_RANGE_KIND.REAL);
		if (string_starts_with(_type, "Array<")) return __kindFact(GMLC_RANGE_KIND.ARRAY);
		if (_type == "Struct") || (string_starts_with(_type, "Struct.")) return __kindFact(GMLC_RANGE_KIND.STRUCT);
		return __top;
	};

	#region jsDoc
	/// @func    __point(_v)
	/// @desc    A fact about one Real value.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Real} _v : The value
	/// @returns {Struct}
	#endregion
	static __point = function(_v) {
		return __fact(GMLC_RANGE_KIND.REAL, _v, _v, _v == floor(_v), false, false);
	};

	#region jsDoc
	/// @func    __bool(_lo, _hi)
	/// @desc    A fact about a Bool, 0 for false and 1 for true.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __bool = function(_lo, _hi) {
		return __fact(GMLC_RANGE_KIND.BOOL, _lo, _hi, true, false, false);
	};

	#region jsDoc
	/// @func    __res(_f, _safe)
	/// @desc    What evaluating an expression gives: its fact, and whether evaluating it again or not at all changes
	///          nothing (no effects, cannot throw).
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _f    : The fact
	/// @param   {Bool}   _safe : Whether the expression can be dropped
	/// @returns {Struct}
	#endregion
	static __res = function(_f, _safe) {
		return { f: _f, safe: _safe };
	};

	#region jsDoc
	/// @func    __copy(_f)
	/// @desc    A copy of a fact.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _f : The fact
	/// @returns {Struct}
	#endregion
	static __copy = function(_f) {
		return { k: _f.k, lo: _f.lo, hi: _f.hi, whole: _f.whole, nan: _f.nan, nz: _f.nz, rel: _f.rel, rel_of: _f.rel_of, len_lo: _f.len_lo };
	};

	#region jsDoc
	/// @func    __noRel(_f)
	/// @desc    A fact without its relation to an array length.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _f : The fact
	/// @returns {Struct}
	#endregion
	static __noRel = function(_f) {
		var _c = __copy(_f);
		_c.rel = GMLC_RANGE_REL.NONE;
		_c.rel_of = "";
		return _c;
	};

	#region jsDoc
	/// @func    __num(_f)
	/// @desc    Whether a fact allows only Real and Bool, which compare and calculate by their numbers.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _f : The fact
	/// @returns {Bool}
	#endregion
	static __num = function(_f) {
		return (_f.k != 0) && ((_f.k & ~6) == 0);
	};

	#region jsDoc
	/// @func    __truthSafe(_f)
	/// @desc    Whether using a value as a condition cannot throw: Real, Bool and undefined.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _f : The fact
	/// @returns {Bool}
	#endregion
	static __truthSafe = function(_f) {
		return (_f.k != 0) && ((_f.k & ~7) == 0);
	};

	#region jsDoc
	/// @func    __isFinite(_f)
	/// @desc    Whether both bounds of a fact are finite.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _f : The fact
	/// @returns {Bool}
	#endregion
	static __isFinite = function(_f) {
		return (_f.lo > -infinity) && (_f.hi < infinity);
	};

	#region jsDoc
	/// @func    __join(_a, _b)
	/// @desc    A fact that holds every value either fact holds.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _a : A fact
	/// @param   {Struct} _b : A fact
	/// @returns {Struct}
	#endregion
	static __join = function(_a, _b) {
		if (_a == _b) return _a;
		var _k = _a.k | _b.k;
		var _an = (_a.k & 6) != 0;
		var _bn = (_b.k & 6) != 0;
		var _r;
		if (_an) && (_bn) {
			_r = __fact(_k, min(_a.lo, _b.lo), max(_a.hi, _b.hi), _a.whole && _b.whole, _a.nan || _b.nan, _a.nz || _b.nz);
		}
		else if (_an) {
			_r = __fact(_k, _a.lo, _a.hi, _a.whole, _a.nan, _a.nz);
		}
		else if (_bn) {
			_r = __fact(_k, _b.lo, _b.hi, _b.whole, _b.nan, _b.nz);
		}
		else {
			_r = __fact(_k, -infinity, infinity, false, true, true);
		}
		if (_a.rel != GMLC_RANGE_REL.NONE) && (_b.rel != GMLC_RANGE_REL.NONE) && (_a.rel_of == _b.rel_of) {
			_r.rel = (_a.rel == _b.rel) ? _a.rel : GMLC_RANGE_REL.LE;
			_r.rel_of = _a.rel_of;
		}
		if ((_a.k & GMLC_RANGE_KIND.ARRAY) != 0) && ((_b.k & GMLC_RANGE_KIND.ARRAY) != 0) {
			_r.len_lo = min(_a.len_lo, _b.len_lo);
		}
		else if ((_a.k & GMLC_RANGE_KIND.ARRAY) != 0) {
			_r.len_lo = _a.len_lo;
		}
		else if ((_b.k & GMLC_RANGE_KIND.ARRAY) != 0) {
			_r.len_lo = _b.len_lo;
		}
		return _r;
	};

	#region jsDoc
	/// @func    __truth(_f)
	/// @desc    What a value is as a condition: 1 for always true (above 0.5), 0 for always false, -1 for not known.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _f : The fact
	/// @returns {Real}
	#endregion
	static __truth = function(_f) {
		if (_f.k == GMLC_RANGE_KIND.UNDEFINED) return 0;
		if (!__num(_f)) return -1;
		if (_f.lo > 0.5) && (!_f.nan) return 1;
		if (_f.hi <= 0.5) return 0;
		return -1;
	};
	#endregion

	#region Interval arithmetic
	#region jsDoc
	/// @func    __fixInf(_lo, _hi)
	/// @desc    Bounds with a NaN (an infinity taken from itself) widened to the infinities.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Array<Real>} [lo, hi]
	#endregion
	static __fixInf = function(_lo, _hi) {
		return [is_nan(_lo) ? -infinity : _lo, is_nan(_hi) ? infinity : _hi];
	};

	#region jsDoc
	/// @func    __addF(_a, _b)
	/// @desc    The fact of `a + b` for two facts that only allow Real and Bool.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __addF = function(_a, _b) {
		var _bounds = __fixInf(_a.lo + _b.lo, _a.hi + _b.hi);
		var _nan = _a.nan || _b.nan || !(__isFinite(_a) && __isFinite(_b));
		var _r = __real(_bounds[0], _bounds[1], _a.whole && _b.whole, _nan, _a.nz && _b.nz);
		if (_b.lo == 1) && (_b.hi == 1) && (_a.whole) && (_a.rel == GMLC_RANGE_REL.LT) {
			_r.rel = GMLC_RANGE_REL.LE;
			_r.rel_of = _a.rel_of;
		}
		return _r;
	};

	#region jsDoc
	/// @func    __subF(_a, _b)
	/// @desc    The fact of `a - b` for two facts that only allow Real and Bool.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __subF = function(_a, _b) {
		var _bounds = __fixInf(_a.lo - _b.hi, _a.hi - _b.lo);
		var _nan = _a.nan || _b.nan || !(__isFinite(_a) && __isFinite(_b));
		var _r = __real(_bounds[0], _bounds[1], _a.whole && _b.whole, _nan, _a.nz && (_b.lo <= 0) && (_b.hi >= 0));
		if (_a.rel != GMLC_RANGE_REL.NONE) && (_b.lo >= 0) {
			if (_b.lo >= 1) {
				_r.rel = GMLC_RANGE_REL.LT;
				_r.rel_of = _a.rel_of;
			}
			else if (_a.rel == GMLC_RANGE_REL.LT) {
				_r.rel = GMLC_RANGE_REL.LT;
				_r.rel_of = _a.rel_of;
			}
		}
		return _r;
	};

	#region jsDoc
	/// @func    __mul0(_x, _y)
	/// @desc    A product where zero times an infinity is zero.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Real}
	#endregion
	static __mul0 = function(_x, _y) {
		return ((_x == 0) || (_y == 0)) ? 0 : _x * _y;
	};

	#region jsDoc
	/// @func    __mulF(_a, _b)
	/// @desc    The fact of `a * b` for two facts that only allow Real and Bool.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __mulF = function(_a, _b) {
		var _p1 = __mul0(_a.lo, _b.lo);
		var _p2 = __mul0(_a.lo, _b.hi);
		var _p3 = __mul0(_a.hi, _b.lo);
		var _p4 = __mul0(_a.hi, _b.hi);
		var _lo = min(_p1, _p2, _p3, _p4);
		var _hi = max(_p1, _p2, _p3, _p4);
		var _nan = _a.nan || _b.nan || !(__isFinite(_a) && __isFinite(_b));
		var _signs = (_a.lo < 0) || (_b.lo < 0) || _a.nz || _b.nz;
		return __real(_lo, _hi, _a.whole && _b.whole, _nan, _signs);
	};

	#region jsDoc
	/// @func    __divF(_a, _b)
	/// @desc    The fact of `a / b` for two facts that only allow Real and Bool.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __divF = function(_a, _b) {
		var _lo = -infinity;
		var _hi = infinity;
		var _both = __isFinite(_a) && __isFinite(_b);
		if (_both) && ((_b.lo > 0) || (_b.hi < 0)) {
			var _q1 = _a.lo / _b.lo;
			var _q2 = _a.lo / _b.hi;
			var _q3 = _a.hi / _b.lo;
			var _q4 = _a.hi / _b.hi;
			_lo = min(_q1, _q2, _q3, _q4);
			_hi = max(_q1, _q2, _q3, _q4);
		}
		var _zero_b = (_b.lo <= 0) && (_b.hi >= 0);
		var _zero_a = (_a.lo <= 0) && (_a.hi >= 0);
		var _nan = _a.nan || _b.nan || !_both || (_zero_b && _zero_a);
		var _signs = (_a.lo < 0) || (_b.lo < 0) || _a.nz || _b.nz;
		return __real(_lo, _hi, false, _nan, _signs);
	};

	#region jsDoc
	/// @func    __idivF(_a, _b)
	/// @desc    The fact of `a div b` for two facts that only allow Real and Bool: the operands are cut toward zero,
	///          so the quotient never has more magnitude than the dividend.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __idivF = function(_a, _b) {
		if (!__isFinite(_a)) return __fact(GMLC_RANGE_KIND.REAL, -infinity, infinity, true, true, true);
		var _m = max(abs(_a.lo), abs(_a.hi));
		var _lo = -_m;
		var _hi = _m;
		if (_b.lo > 0) {
			if (_a.lo >= 0) {
				_lo = 0;
			}
			else if (_a.hi <= 0) {
				_hi = 0;
			}
		}
		return __real(_lo, _hi, true, _a.nan || _b.nan, (_a.lo < 0) || _a.nz);
	};

	#region jsDoc
	/// @func    __modF(_a, _b)
	/// @desc    The fact of `a mod b` for two facts that only allow Real and Bool: the sign follows the dividend and
	///          the magnitude stays below the divisor.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __modF = function(_a, _b) {
		var _bm = max(abs(_b.lo), abs(_b.hi));
		var _lo;
		var _hi;
		if (_a.lo >= 0) {
			_lo = 0;
			_hi = min(_a.hi, _bm);
		}
		else if (_a.hi <= 0) {
			_lo = max(_a.lo, -_bm);
			_hi = 0;
		}
		else {
			_lo = max(_a.lo, -_bm);
			_hi = min(_a.hi, _bm);
		}
		return __real(_lo, _hi, _a.whole && _b.whole, _a.nan || _b.nan || !__isFinite(_a), (_a.lo < 0) || _a.nz);
	};

	#region jsDoc
	/// @func    __negF(_a)
	/// @desc    The fact of `-a` for a fact that only allows Real.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __negF = function(_a) {
		return __real(-_a.hi, -_a.lo, _a.whole, _a.nan, true);
	};

	#region jsDoc
	/// @func    __roundF(_name, _a)
	/// @desc    The fact of `floor`, `ceil` or `round` of a fact that only allows Real and Bool. `round` is bounded by
	///          the floor and the ceiling whichever way it breaks ties.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {String} _name : The function
	/// @param   {Struct} _a    : The argument
	/// @returns {Struct}
	#endregion
	static __roundF = function(_name, _a) {
		var _lo;
		var _hi;
		switch (_name) {
			case "floor": _lo = floor(_a.lo); _hi = floor(_a.hi); break;
			case "ceil": _lo = ceil(_a.lo); _hi = ceil(_a.hi); break;
			default: _lo = floor(_a.lo); _hi = ceil(_a.hi); break;
		}
		var _nz = (_name == "floor") ? _a.nz : (_a.nz || (_a.lo < 0));
		return __real(_lo, _hi, true, _a.nan, _nz);
	};

	#region jsDoc
	/// @func    __absF(_a)
	/// @desc    The fact of `abs(a)` for a fact that only allows Real.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __absF = function(_a) {
		var _lo = (_a.lo >= 0) ? _a.lo : ((_a.hi <= 0) ? -_a.hi : 0);
		var _hi = max(abs(_a.lo), abs(_a.hi));
		return __real(_lo, _hi, _a.whole, _a.nan, false);
	};

	#region jsDoc
	/// @func    __signF(_a)
	/// @desc    The fact of `sign(a)` for a fact that only allows Real.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __signF = function(_a) {
		var _lo = (_a.lo > 0) ? 1 : ((_a.lo >= 0) ? 0 : -1);
		var _hi = (_a.hi < 0) ? -1 : ((_a.hi <= 0) ? 0 : 1);
		return __real(_lo, _hi, true, _a.nan, false);
	};

	#region jsDoc
	/// @func    __sqrF(_a)
	/// @desc    The fact of `sqr(a)` for a fact that only allows Real.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __sqrF = function(_a) {
		var _p = _a.lo * _a.lo;
		var _q = _a.hi * _a.hi;
		var _lo = ((_a.lo <= 0) && (_a.hi >= 0)) ? 0 : min(_p, _q);
		return __real(_lo, max(_p, _q), _a.whole, _a.nan, false);
	};
	#endregion

	#region Comparisons
	#region jsDoc
	/// @func    __isCompare(_op)
	/// @desc    Whether an operator is a comparison.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {String} _op : The operator
	/// @returns {Bool}
	#endregion
	static __isCompare = function(_op) {
		return (_op == "==") || (_op == "!=") || (_op == "<") || (_op == "<=") || (_op == ">") || (_op == ">=");
	};

	#region jsDoc
	/// @func    __flip(_op)
	/// @desc    The comparison with its operands swapped.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {String} _op : The operator
	/// @returns {String}
	#endregion
	static __flip = function(_op) {
		switch (_op) {
			case "<": return ">";
			case "<=": return ">=";
			case ">": return "<";
			case ">=": return "<=";
		}
		return _op;
	};

	#region jsDoc
	/// @func    __sepLt(_a, _b)
	/// @desc    Whether _a is below _b by more than the epsilon can blur: both integral and _a below _b, or the
	///          gap wider than the margin between bounds of moderate size.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _a : A fact
	/// @param   {Struct} _b : A fact
	/// @returns {Bool}
	#endregion
	static __sepLt = function(_a, _b) {
		if (_a.whole) && (_b.whole) return _a.hi < _b.lo;
		if (abs(_a.hi) > __bound) || (abs(_b.lo) > __bound) return false;
		return _b.lo - _a.hi > __margin;
	};

	#region jsDoc
	/// @func    __decide(_op, _a, _b)
	/// @desc    What a comparison of two numbers always gives under the default epsilon: 1 for true, 0 for false,
	///          -1 when the facts do not decide it. `a <= b` is true whenever a is at most b, and `a < b` is false
	///          whenever a is at least b, since no epsilon turns those around.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {String} _op : The comparison
	/// @param   {Struct} _a  : The left fact
	/// @param   {Struct} _b  : The right fact
	/// @returns {Real}
	#endregion
	static __decide = function(_op, _a, _b) {
		if (!__num(_a)) || (!__num(_b)) || (_a.nan) || (_b.nan) return -1;
		switch (_op) {
			case "<":
				if (__sepLt(_a, _b)) return 1;
				if (_a.lo >= _b.hi) return 0;
				return -1;
			case "<=":
				if (_a.hi <= _b.lo) return 1;
				if (__sepLt(_b, _a)) return 0;
				return -1;
			case ">":
				if (__sepLt(_b, _a)) return 1;
				if (_a.hi <= _b.lo) return 0;
				return -1;
			case ">=":
				if (_b.hi <= _a.lo) return 1;
				if (__sepLt(_a, _b)) return 0;
				return -1;
			case "==":
				if (_a.lo == _a.hi) && (_b.lo == _b.hi) && (_a.lo == _b.lo) return 1;
				if (__sepLt(_a, _b)) || (__sepLt(_b, _a)) return 0;
				return -1;
			case "!=": {
				var _eq = __decide("==", _a, _b);
				return (_eq == -1) ? -1 : 1 - _eq;
			}
		}
		return -1;
	};

	#region jsDoc
	/// @func    __compareFact(_op, _a, _b, _epsilon_set)
	/// @desc    The fact of a comparison: a Bool, decided when the facts decide it.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __compareFact = function(_op, _a, _b, _epsilon_set) {
		var _d = _epsilon_set ? -1 : __decide(_op, _a, _b);
		return (_d == -1) ? __bool(0, 1) : __bool(_d, _d);
	};

	#region jsDoc
	/// @func    __binaryFact(_op, _a, _b, _epsilon_set)
	/// @desc    The fact of `a op b`: arithmetic on two Real or Bool values by their intervals, text joined from two
	///          strings, int64 from two int64 values or a bitwise operator, a Bool from a comparison, else nothing
	///          is known.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {String} _op          : The operator
	/// @param   {Struct} _a           : The left fact
	/// @param   {Struct} _b           : The right fact
	/// @param   {Bool}   _epsilon_set : Whether the batch sets the epsilon
	/// @returns {Struct}
	#endregion
	static __binaryFact = function(_op, _a, _b, _epsilon_set) {
		if (__isCompare(_op)) return __compareFact(_op, _a, _b, _epsilon_set);
		switch (_op) {
			case "&": case "|": case "^": case "<<": case ">>":
				return __kindFact(GMLC_RANGE_KIND.INT64);
		}
		var _numeric = __num(_a) && __num(_b);
		var _int64 = (_a.k == GMLC_RANGE_KIND.INT64) && (_b.k == GMLC_RANGE_KIND.INT64);
		switch (_op) {
			case "+":
				if (_numeric) return __addF(_a, _b);
				if (_a.k == GMLC_RANGE_KIND.STRING) && (_b.k == GMLC_RANGE_KIND.STRING) return __kindFact(GMLC_RANGE_KIND.STRING);
				if (_int64) return __kindFact(GMLC_RANGE_KIND.INT64);
			break;
			case "-":
				if (_numeric) return __subF(_a, _b);
				if (_int64) return __kindFact(GMLC_RANGE_KIND.INT64);
			break;
			case "*":
				if (_numeric) return __mulF(_a, _b);
				if (_int64) return __kindFact(GMLC_RANGE_KIND.INT64);
			break;
			case "/":
				if (_numeric) return __divF(_a, _b);
				if (_int64) return __kindFact(GMLC_RANGE_KIND.INT64);
			break;
			case "div":
				if (_numeric) return __idivF(_a, _b);
				if (_int64) return __kindFact(GMLC_RANGE_KIND.INT64);
			break;
			case "mod": case "%":
				if (_numeric) return __modF(_a, _b);
				if (_int64) return __kindFact(GMLC_RANGE_KIND.INT64);
			break;
		}
		return __top;
	};

	#region jsDoc
	/// @func    __binarySafe(_op, _a, _b)
	/// @desc    Whether `a op b` cannot throw for operands of these facts: arithmetic and comparison of Real and
	///          Bool values, and text joined or compared from two strings.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool}
	#endregion
	static __binarySafe = function(_op, _a, _b) {
		if (__num(_a)) && (__num(_b)) {
			return (_op == "+") || (_op == "-") || (_op == "*") || (_op == "/") || __isCompare(_op);
		}
		if (_a.k == GMLC_RANGE_KIND.STRING) && (_b.k == GMLC_RANGE_KIND.STRING) {
			return (_op == "+") || (_op == "==") || (_op == "!=");
		}
		return false;
	};
	#endregion

	#region Built-in functions
	#region jsDoc
	/// @func    __isCheck(_name)
	/// @desc    Whether a built-in is one of the `is_` tests the analysis decides from kinds.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {String} _name : The function
	/// @returns {Bool}
	#endregion
	static __isCheck = function(_name) {
		switch (_name) {
			case "is_real": case "is_numeric": case "is_string": case "is_array": case "is_struct": case "is_bool":
			case "is_int64": case "is_undefined": case "is_nan": case "is_infinity": case "is_method": case "is_ptr":
			case "is_int32":
			return true;
		}
		return false;
	};

	#region jsDoc
	/// @func    isDecided(_name, _f)
	/// @desc    What an `is_` test gives for a value of a fact: 1 for true, 0 for false, -1 when not known.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {String} _name : The test
	/// @param   {Struct} _f    : The fact of the argument
	/// @returns {Real}
	#endregion
	static isDecided = function(_name, _f) {
		var _k = _f.k;
		switch (_name) {
			case "is_real":
				if (_k == GMLC_RANGE_KIND.REAL) return 1;
				if ((_k & ~113) == 0) return 0;
			break;
			case "is_numeric":
				if ((_k & ~14) == 0) return 1;
				if ((_k & ~113) == 0) return 0;
			break;
			case "is_string": return (_k == GMLC_RANGE_KIND.STRING) ? 1 : (((_k & GMLC_RANGE_KIND.STRING) == 0) ? 0 : -1);
			case "is_array": return (_k == GMLC_RANGE_KIND.ARRAY) ? 1 : (((_k & GMLC_RANGE_KIND.ARRAY) == 0) ? 0 : -1);
			case "is_struct": return (_k == GMLC_RANGE_KIND.STRUCT) ? 1 : (((_k & GMLC_RANGE_KIND.STRUCT) == 0) ? 0 : -1);
			case "is_bool": return (_k == GMLC_RANGE_KIND.BOOL) ? 1 : (((_k & GMLC_RANGE_KIND.BOOL) == 0) ? 0 : -1);
			case "is_int64": return (_k == GMLC_RANGE_KIND.INT64) ? 1 : (((_k & GMLC_RANGE_KIND.INT64) == 0) ? 0 : -1);
			case "is_undefined": return (_k == GMLC_RANGE_KIND.UNDEFINED) ? 1 : (((_k & GMLC_RANGE_KIND.UNDEFINED) == 0) ? 0 : -1);
		}
		return -1;
	};

	#region jsDoc
	/// @func    typeName(_f)
	/// @desc    What `typeof` gives for a value of a fact, or undefined when the fact allows more than one kind.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _f : The fact
	/// @returns {String|Undefined}
	#endregion
	static typeName = function(_f) {
		switch (_f.k) {
			case GMLC_RANGE_KIND.REAL: return "number";
			case GMLC_RANGE_KIND.BOOL: return "bool";
			case GMLC_RANGE_KIND.INT64: return "int64";
			case GMLC_RANGE_KIND.STRING: return "string";
			case GMLC_RANGE_KIND.UNDEFINED: return "undefined";
			case GMLC_RANGE_KIND.ARRAY: return "array";
			case GMLC_RANGE_KIND.STRUCT: return "struct";
		}
		return undefined;
	};

	#region jsDoc
	/// @func    __returnsString(_name)
	/// @desc    Whether a built-in always returns a string.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {String} _name : The function
	/// @returns {Bool}
	#endregion
	static __returnsString = function(_name) {
		switch (_name) {
			case "string": case "string_upper": case "string_lower": case "string_copy": case "string_char_at":
			case "string_delete": case "string_insert": case "string_replace": case "string_replace_all":
			case "string_repeat": case "string_format": case "string_digits": case "string_letters":
			case "string_lettersdigits": case "chr": case "string_concat": case "string_join": case "typeof":
			return true;
		}
		return false;
	};

	#region jsDoc
	/// @func    __builtinFact(_w, _node, _name, _rs)
	/// @desc    The fact of a call of a built-in from the facts of its arguments.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w    : The walker
	/// @param   {Struct.ASTNode} _node : The call
	/// @param   {String}         _name : The built-in
	/// @param   {Array<Struct>}  _rs   : What evaluating the arguments gave
	/// @returns {Struct}
	#endregion
	static __builtinFact = function(_w, _node, _name, _rs) {
		var _n = array_length(_rs);
		if (__isCheck(_name)) {
			if (_n != 1) return __bool(0, 1);
			var _d = isDecided(_name, _rs[0].f);
			return (_d == -1) ? __bool(0, 1) : __bool(_d, _d);
		}
		if (__returnsString(_name)) return __kindFact(GMLC_RANGE_KIND.STRING);
		switch (_name) {
			case "floor": case "ceil": case "round":
				if (_n == 1) && (__num(_rs[0].f)) return __roundF(_name, _rs[0].f);
			break;
			case "abs":
				if (_n == 1) && (__num(_rs[0].f)) return __absF(_rs[0].f);
			break;
			case "sign":
				if (_n == 1) && (__num(_rs[0].f)) return __signF(_rs[0].f);
			break;
			case "sqr":
				if (_n == 1) && (__num(_rs[0].f)) return __sqrF(_rs[0].f);
			break;
			case "min": case "max": {
				if (_n < 1) break;
				var _all = true;
				var _i = 0; repeat (_n) {
					if (_rs[_i].f.k != GMLC_RANGE_KIND.REAL) _all = false;
				_i++}
				if (!_all) break;
				var _f = _rs[0].f;
				_i = 1; repeat (_n - 1) {
					var _g = _rs[_i].f;
					if (_name == "min") {
						_f = __real(min(_f.lo, _g.lo), min(_f.hi, _g.hi), _f.whole && _g.whole, _f.nan || _g.nan, _f.nz || _g.nz);
					}
					else {
						_f = __real(max(_f.lo, _g.lo), max(_f.hi, _g.hi), _f.whole && _g.whole, _f.nan || _g.nan, _f.nz || _g.nz);
					}
				_i++}
				return _f;
			}
			case "clamp": {
				if (_n != 3) break;
				var _all = true;
				var _i = 0; repeat (3) {
					if (_rs[_i].f.k != GMLC_RANGE_KIND.REAL) _all = false;
				_i++}
				if (!_all) break;
				var _x = _rs[0].f;
				var _l = _rs[1].f;
				var _h = _rs[2].f;
				var _lo = min(max(_x.lo, _l.lo), _h.lo);
				var _hi = min(max(_x.hi, _l.hi), _h.hi);
				return __real(_lo, _hi, _x.whole && _l.whole && _h.whole, _x.nan || _l.nan || _h.nan, _x.nz || _l.nz || _h.nz);
			}
			case "array_length": {
				if (_n != 1) break;
				var _f = __real(0, __lenMax, true, false, false);
				var _arg = _node.args[0];
				if (__gmlc_opt_is_local(_arg)) {
					_f.rel = GMLC_RANGE_REL.LE;
					_f.rel_of = _arg.name;
					_w.related[$ _arg.name] = true;
				}
				return _f;
			}
			case "string_length":
				if (_n == 1) return __real(0, __lenMax, true, false, false);
			break;
			case "irandom": {
				if (_n != 1) break;
				var _a = _rs[0].f;
				if (_a.k == GMLC_RANGE_KIND.REAL) && (!_a.nan) && (_a.lo >= 0) && (_a.hi < infinity) {
					return __real(0, floor(_a.hi), true, false, false);
				}
				return __real(-infinity, infinity, true, false, false);
			}
			case "irandom_range": {
				if (_n != 2) break;
				var _a = _rs[0].f;
				var _b = _rs[1].f;
				if (_a.k == GMLC_RANGE_KIND.REAL) && (_b.k == GMLC_RANGE_KIND.REAL) && (!_a.nan) && (!_b.nan) {
					return __real(floor(min(_a.lo, _b.lo)), ceil(max(_a.hi, _b.hi)), true, false, false);
				}
				return __real(-infinity, infinity, true, false, false);
			}
			case "real":
				if (_n == 1) {
					if (_rs[0].f.k == GMLC_RANGE_KIND.REAL) return _rs[0].f;
					return __kindFact(GMLC_RANGE_KIND.REAL);
				}
			break;
			case "bool":
				if (_n == 1) {
					var _t = __truth(_rs[0].f);
					return (_t == -1) ? __bool(0, 1) : __bool(_t, _t);
				}
			break;
			case "int64":
				if (_n == 1) return __kindFact(GMLC_RANGE_KIND.INT64);
			break;
			case "array_create": {
				if (_n < 1) break;
				var _f = __kindFact(GMLC_RANGE_KIND.ARRAY);
				var _a = _rs[0].f;
				if (_a.k == GMLC_RANGE_KIND.REAL) && (!_a.nan) && (_a.lo >= 0) && (_a.lo < __lenMax) {
					_f.len_lo = floor(_a.lo);
				}
				return _f;
			}
		}
		return __top;
	};

	#region jsDoc
	/// @func    __builtinSafe(_name, _args, _rs)
	/// @desc    Whether a call of a built-in can be dropped: it neither changes anything nor throws for arguments of
	///          these facts, and the arguments can be dropped too.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {String}                _name : The built-in
	/// @param   {Array<Struct.ASTNode>} _args : The arguments
	/// @param   {Array<Struct>}         _rs   : What evaluating the arguments gave
	/// @returns {Bool}
	#endregion
	static __builtinSafe = function(_name, _args, _rs) {
		var _i = 0; repeat (array_length(_rs)) {
			if (!_rs[_i].safe) return false;
		_i++}
		if (__isCheck(_name)) || (_name == "typeof") return true;
		switch (_name) {
			case "floor": case "ceil": case "round": case "abs": case "sign": case "min": case "max": case "clamp":
			case "sqr": {
				_i = 0; repeat (array_length(_rs)) {
					if (_rs[_i].f.k != GMLC_RANGE_KIND.REAL) return false;
				_i++}
				return true;
			}
		}
		var _effects = __GmlcDataEffects();
		var _entry = _effects[$ _name];
		if (_entry == undefined) || ((_entry.class != "pure") && (_entry.class != "observer")) || (_entry.may_throw) return false;
		// the effect table's flag holds only for arguments the signature takes, by the kinds the facts give
		var _pass = self; // inside a struct literal `self` is the new struct
		var _typeOf = method({ pass: _pass, args: _args, rs: _rs }, function(_arg) {
			var _i = array_get_index(args, _arg);
			return (_i < 0) ? undefined : pass.__kindType(rs[_i].f.k);
		});
		return __gmlc_opt_args_accepted(_name, _args, _typeOf);
	};

	#region jsDoc
	/// @func    __kindType(_k)
	/// @desc    The built-in data's type name of a value of exactly one kind, undefined for a mix.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Real} _k : The kinds
	/// @returns {String|Undefined}
	#endregion
	static __kindType = function(_k) {
		switch (_k) {
			case GMLC_RANGE_KIND.UNDEFINED: return "Undefined";
			case GMLC_RANGE_KIND.BOOL: return "Bool";
			case GMLC_RANGE_KIND.REAL: return "Real";
			case GMLC_RANGE_KIND.INT64: return "Int64";
			case GMLC_RANGE_KIND.STRING: return "String";
			case GMLC_RANGE_KIND.ARRAY: return "Array";
			case GMLC_RANGE_KIND.STRUCT: return "Struct";
		}
		return undefined;
	};
	#endregion

	#region Walker
	#region jsDoc
	/// @func    analyze(_root, _cx, _kinds)
	/// @desc    Walks a function in execution order and records, for every node of the given kinds, what its
	///          operands were worth. Statements are followed with the facts of the `var` locals at that point; a
	///          branch adds what its test says, a loop forgets every local it writes except a counter that only
	///          steps by a constant, and a call that may run other code forgets that an index is below an array's
	///          length. A statement frozen by `@NoOp` forgets everything.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct.ASTNode} _root  : The function, or the script
	/// @param   {Struct}         _cx    : The pass context
	/// @param   {Array<Real>}    _kinds : The node kinds to record
	/// @returns {Struct} The walker: events (node, path, operands, result, info), contained (locals that hold only arrays that never escape)
	#endregion
	static analyze = function(_root, _cx, _kinds) {
		var _watch = array_create(__GMLC_NodeKind_SIZE, false);
		var _k = 0; repeat (array_length(_kinds)) {
			_watch[_kinds[_k]] = true;
		_k++}
		var _w = {
			cx: _cx,
			watch: _watch,
			events: [],
			path: [],
			state: {},
			mute: 0,
			noop: _cx.optimizer.has_no_op_targets,
			epsilon: _cx.epsilon_set,
			contained: {},
			related: {},
			params: {},
			root: _root,
		};
		var _body = undefined;
		var _list = undefined;
		if (_root.kind == __GMLC_NodeKind_Script) {
			_list = _root.body;
		}
		else {
			_body = _root.body;
			_list = _body.body;
			var _bad_arguments = __usesArguments(_root);
			var _p = 0; repeat (array_length(_root.params)) {
				var _target = _root.params[_p].target;
				_w.params[$ _target.name] = true;
				if (!_bad_arguments) _w.state[$ _target.name] = __heldFact(_target);
			_p++}
		}
		__containment(_w, _root);
		if (_body != undefined) {
			array_push(_w.path, array_length(_root.children()) - 1);
		}
		__walkList(_w, _list);
		if (_body != undefined) array_pop(_w.path);
		return _w;
	};

	#region jsDoc
	/// @func    kindName(_f)
	/// @desc    The name of the one kind a fact allows, or "Mixed" when it allows several.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _f : The fact
	/// @returns {String}
	#endregion
	static kindName = function(_f) {
		switch (_f.k) {
			case GMLC_RANGE_KIND.REAL: return "Real";
			case GMLC_RANGE_KIND.BOOL: return "Bool";
			case GMLC_RANGE_KIND.INT64: return "Int64";
			case GMLC_RANGE_KIND.STRING: return "String";
			case GMLC_RANGE_KIND.UNDEFINED: return "Undefined";
			case GMLC_RANGE_KIND.ARRAY: return "Array";
			case GMLC_RANGE_KIND.STRUCT: return "Struct";
		}
		return "Mixed";
	};

	#region jsDoc
	/// @func    pathKey(_path)
	/// @desc    A path of child positions as text, to look events up by.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Array<Real>} _path : The path
	/// @returns {String}
	#endregion
	static pathKey = function(_path) {
		var _key = "";
		var _i = 0; repeat (array_length(_path)) {
			_key += string(_path[_i]) + ",";
		_i++}
		return _key;
	};

	#region jsDoc
	/// @func    __collectFunctions(_node, _out)
	/// @desc    Adds every function node under a node to a list, outer ones first.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Array}          _out  : The list
	#endregion
	static __collectFunctions = function(_node, _out) {
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__gmlc_opt_is_function(_child)) array_push(_out, _child);
					__collectFunctions(_child, _out);
				}
			_i++}
		_field_index++}
	};

	#region jsDoc
	/// @func    __usesArguments(_root)
	/// @desc    Whether a function reads `argument` or `argument0` and the like, which can change its parameters.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct.ASTNode} _root : The function
	/// @returns {Bool}
	#endregion
	static __usesArguments = function(_root) {
		var _child_fields = _root.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _root[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					var _c = _child;
					if (_c.kind == __GMLC_NodeKind_Identifier) {
						if (_c.symbol != undefined) && (_c.symbol.kind == "BuiltinVar") && (string_starts_with(_c.name, "argument")) && (_c.name != "argument_count") return true;
					}
					else if (!__gmlc_opt_is_function(_c)) && (__usesArguments(_c)) {
						return true;
					}
				}
			_i++}
		_field_index++}
		return false;
	};

	#region jsDoc
	/// @func    __emit(_w, _node, _operands, _r, [_info])
	/// @desc    Records a node of a watched kind with its operands' results.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w    : The walker
	/// @param   {Struct.ASTNode} _node : The node
	/// @param   {Array<Struct>}  _operands : What evaluating its operands gave
	/// @param   {Struct}         _r    : What evaluating it gave
	/// @param   {Struct}         [_info] : More the analysis knows
	#endregion
	static __emit = function(_w, _node, _operands, _r, _info = undefined) {
		if (_w.mute != 0) || (!_w.watch[_node.kind]) return;
		array_push(_w.events, { node: _node, path: array_concat(_w.path, []), operands: _operands, result: _r, info: _info });
	};

	#region jsDoc
	/// @func    __sub(_w, _i, _node)
	/// @desc    Evaluates the child of the current node at position _i.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w    : The walker
	/// @param   {Real}           _i    : The child's position
	/// @param   {Struct.ASTNode} _node : The child
	/// @returns {Struct}
	#endregion
	static __sub = function(_w, _i, _node) {
		array_push(_w.path, _i);
		var _r = __eval(_w, _node);
		array_pop(_w.path);
		return _r;
	};

	#region jsDoc
	/// @func    __peek(_w, _s, _node)
	/// @desc    What an expression is worth in a state, without recording it or changing the state.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w    : The walker
	/// @param   {Struct}         _s    : The state
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Struct}
	#endregion
	static __peek = function(_w, _s, _node) {
		var _saved = _w.state;
		_w.state = __stateCopy(_s);
		_w.mute++;
		var _r = __eval(_w, _node);
		_w.mute--;
		_w.state = _saved;
		return _r;
	};

	#region jsDoc
	/// @func    __opaque(_origin)
	/// @desc    Whether a node made from a macro that depends on the configuration or from a compile-time value is
	///          an unknown value.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct.GMLC_Origin} _origin : The node's origin
	/// @returns {Bool}
	#endregion
	static __opaque = function(_origin) {
		return (_origin.kind == "compile_time") || ((_origin.kind == "macro") && (_origin.config != undefined));
	};
	#endregion

	#region State
	#region jsDoc
	/// @func    __stateCopy(_s)
	/// @desc    A copy of a state (facts are never changed, so they are shared).
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _s : The state, local name to fact
	/// @returns {Struct}
	#endregion
	static __stateCopy = function(_s) {
		var _out = {};
		var _names = struct_get_names(_s);
		var _i = 0; repeat (array_length(_names)) {
			_out[$ _names[_i]] = _s[$ _names[_i]];
		_i++}
		return _out;
	};

	#region jsDoc
	/// @func    __stateJoin(_a, _b)
	/// @desc    The state where two flows meet: the locals both know, each as the join of its facts.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __stateJoin = function(_a, _b) {
		var _out = {};
		var _names = struct_get_names(_a);
		var _i = 0; repeat (array_length(_names)) {
			var _fb = _b[$ _names[_i]];
			if (_fb != undefined) _out[$ _names[_i]] = __join(_a[$ _names[_i]], _fb);
		_i++}
		return _out;
	};

	#region jsDoc
	/// @func    __stateHavoc(_w, _s, _acc)
	/// @desc    A copy of a state without the locals a part of the code writes, and without the relations to arrays
	///          of those names.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _w   : The walker
	/// @param   {Struct} _s   : The state
	/// @param   {Struct} _acc : {all, names} from __written
	/// @returns {Struct}
	#endregion
	static __stateHavoc = function(_w, _s, _acc) {
		if (_acc.all) return {};
		var _out = {};
		var _names = struct_get_names(_s);
		var _i = 0; repeat (array_length(_names)) {
			var _f = _s[$ _names[_i]];
			if (!struct_exists(_acc.names, _names[_i])) {
				if (_f.rel != GMLC_RANGE_REL.NONE) && (struct_exists(_acc.names, _f.rel_of)) _f = __noRel(_f);
				_out[$ _names[_i]] = _f;
			}
		_i++}
		return _out;
	};

	#region jsDoc
	/// @func    __stateClean(_w, _s)
	/// @desc    Forgets, in a state, every relation to the length of an array that other code could change.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _w : The walker
	/// @param   {Struct} _s : The state, changed in place
	#endregion
	static __stateClean = function(_w, _s) {
		var _names = struct_get_names(_s);
		var _i = 0; repeat (array_length(_names)) {
			var _f = _s[$ _names[_i]];
			if (_f.rel != GMLC_RANGE_REL.NONE) && (!struct_exists(_w.contained, _f.rel_of)) _s[$ _names[_i]] = __noRel(_f);
		_i++}
	};

	#region jsDoc
	/// @func    __setLocal(_w, _name, _f)
	/// @desc    A write of a local: its new fact, and no fact keeps a relation to its old value.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct} _w    : The walker
	/// @param   {String} _name : The local
	/// @param   {Struct} _f    : Its new fact
	#endregion
	static __setLocal = function(_w, _name, _f) {
		if (struct_exists(_w.related, _name)) {
			var _names = struct_get_names(_w.state);
			var _i = 0; repeat (array_length(_names)) {
				var _g = _w.state[$ _names[_i]];
				if (_g.rel != GMLC_RANGE_REL.NONE) && (_g.rel_of == _name) _w.state[$ _names[_i]] = __noRel(_g);
			_i++}
		}
		if (_f.rel != GMLC_RANGE_REL.NONE) && (_f.rel_of == _name) _f = __noRel(_f);
		_w.state[$ _name] = _f;
	};

	#region jsDoc
	/// @func    __written(_w, _node, _acc)
	/// @desc    Adds to _acc the locals a part of the code writes: assigned, declared, stepped or caught. Code frozen
	///          by `@NoOp` counts as writing everything. Nested functions are left out.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w    : The walker
	/// @param   {Struct.ASTNode} _node : The code
	/// @param   {Struct}         _acc  : {all, names}, changed in place
	#endregion
	static __written = function(_w, _node, _acc) {
		if (_acc.all) return;
		if (_w.noop) && (_w.cx.optimizer.__isNoOp(_node)) {
			_acc.all = true;
			return;
		}
		switch (_node.kind) {
			case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl: case __GMLC_NodeKind_FunctionExpr:
			return;
			case __GMLC_NodeKind_Assign:
				if (__gmlc_opt_is_local(_node.target)) _acc.names[$ _node.target.name] = true;
			break;
			case __GMLC_NodeKind_Update:
				if (__gmlc_opt_is_local(_node.argument)) _acc.names[$ _node.argument.name] = true;
			break;
			case __GMLC_NodeKind_VarDecl:
				if (__gmlc_opt_is_local(_node.target)) _acc.names[$ _node.target.name] = true;
			break;
			case __GMLC_NodeKind_Try:
				if (_node.catch_param != undefined) && (__gmlc_opt_is_local(_node.catch_param)) _acc.names[$ _node.catch_param.name] = true;
			break;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__written(_w, _child, _acc);
				}
			_i++}
		_field_index++}
	};

	#region jsDoc
	/// @func    __hasUnclean(_w, _node)
	/// @desc    Whether a part of the code runs something that could change an array it does not own: a call of a
	///          function that is not a pure, observer or render built-in, a method call, `new`, or frozen code.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w    : The walker
	/// @param   {Struct.ASTNode} _node : The code
	/// @returns {Bool}
	#endregion
	static __hasUnclean = function(_w, _node) {
		if (_w.noop) && (_w.cx.optimizer.__isNoOp(_node)) return true;
		switch (_node.kind) {
			case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl: case __GMLC_NodeKind_FunctionExpr:
			return false;
			case __GMLC_NodeKind_MethodCall: case __GMLC_NodeKind_New:
			return true;
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name == undefined) return true;
				if (!__cleanCall(_name)) return true;
			break;}
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (__hasUnclean(_w, _child)) return true;
				}
			_i++}
		_field_index++}
		return false;
	};

	#region jsDoc
	/// @func    __cleanCall(_name)
	/// @desc    Whether a built-in cannot run code of the game: its effect class is pure, observer or render.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {String} _name : The built-in
	/// @returns {Bool}
	#endregion
	static __cleanCall = function(_name) {
		var _class = __gmlc_opt_call_class(_name);
		return (_class == "pure") || (_class == "observer") || (_class == "render");
	};
	#endregion

	#region Containment
	#region jsDoc
	/// @func    __containment(_w, _root)
	/// @desc    Finds the locals that hold only arrays made in the function and that are only indexed or measured
	///          with `array_length`, so no other code can change their length. Such an array only ever grows.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w    : The walker, its `contained` is set
	/// @param   {Struct.ASTNode} _root : The function
	#endregion
	static __containment = function(_w, _root) {
		var _acc = { bad: {}, fresh: {} };
		var _child_fields = _root.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _root[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					if (_child.kind != __GMLC_NodeKind_Param) __scanUse(_child, _root, _acc);
				}
			_i++}
		_field_index++}
		var _names = struct_get_names(_acc.fresh);
		_i = 0; repeat (array_length(_names)) {
			if (!struct_exists(_acc.bad, _names[_i])) && (!struct_exists(_w.params, _names[_i])) _w.contained[$ _names[_i]] = true;
		_i++}
	};

	#region jsDoc
	/// @func    __isFresh(_node)
	/// @desc    Whether an expression makes a new array: an array literal or `array_create`.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Bool}
	#endregion
	static __isFresh = function(_node) {
		return (_node.kind == __GMLC_NodeKind_ArrayLiteral) || (__gmlc_opt_builtin_call(_node) == "array_create");
	};

	#region jsDoc
	/// @func    __scanUse(_node, _parent, _acc)
	/// @desc    Marks every use of a local that is more than indexing it, measuring it, or giving it a new array.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct.ASTNode} _node   : The node
	/// @param   {Struct.ASTNode} _parent : Its parent
	/// @param   {Struct}         _acc    : {bad, fresh}
	#endregion
	static __scanUse = function(_node, _parent, _acc) {
		if (__gmlc_opt_is_function(_node)) return;
		if (_node.kind == __GMLC_NodeKind_Identifier) {
			if (!__gmlc_opt_is_local(_node)) return;
			var _name = _node.name;
			var _ok = false;
			switch (_parent.kind) {
				case __GMLC_NodeKind_Index:
					_ok = (_parent.object == _node) && ((_parent.accessor == "Array") || (_parent.accessor == "ArrayAt") || (_parent.accessor == "Array2D") || (_parent.accessor == "Array2DAt"));
				break;
				case __GMLC_NodeKind_Call:
					_ok = (__gmlc_opt_builtin_call(_parent) == "array_length") && (array_length(_parent.args) == 1) && (_parent.args[0] == _node);
				break;
				case __GMLC_NodeKind_Assign:
					if (_parent.target == _node) && (_parent.op == "=") && (__isFresh(_parent.value)) {
						_ok = true;
						_acc.fresh[$ _name] = true;
					}
				break;
				case __GMLC_NodeKind_VarDecl:
					if (_parent.target == _node) && ((_parent.init == undefined) || (__isFresh(_parent.init))) {
						_ok = true;
						if (_parent.init != undefined) _acc.fresh[$ _name] = true;
					}
				break;
			}
			if (!_ok) _acc.bad[$ _name] = true;
			return;
		}
		var _child_fields = _node.childFields;
		var _field_index = 0; repeat (array_length(_child_fields)) {
			var _child_value = _node[$ _child_fields[_field_index]];
			var _child_many = is_array(_child_value);
			var _i = 0; repeat (_child_many ? array_length(_child_value) : 1) {
				var _child = _child_many ? _child_value[_i] : _child_value;
				if (_child != undefined) {
					__scanUse(_child, _node, _acc);
				}
			_i++}
		_field_index++}
	};
	#endregion

	#region Statements
	#region jsDoc
	/// @func    __walkList(_w, _list)
	/// @desc    Walks statements in order; stops at the first one that never completes.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}                 _w    : The walker
	/// @param   {Array<Struct.ASTNode>} _list : The statements
	/// @returns {Bool} Whether the end of the list can be reached
	#endregion
	static __walkList = function(_w, _list) {
		var _i = 0; repeat (array_length(_list)) {
			array_push(_w.path, _i);
			var _alive = __stmt(_w, _list[_i]);
			array_pop(_w.path);
			if (!_alive) return false;
		_i++}
		return true;
	};

	#region jsDoc
	/// @func    __stmtAt(_w, _i, _node)
	/// @desc    Walks the child statement or expression at position _i of the current node.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the end of it can be reached
	#endregion
	static __stmtAt = function(_w, _i, _node) {
		array_push(_w.path, _i);
		var _alive = true;
		if (_node.kind >= __GMLC_NodeKind_Assign) && (_node.kind <= __GMLC_NodeKind_Nameof) {
			__eval(_w, _node);
		}
		else {
			_alive = __stmt(_w, _node);
		}
		array_pop(_w.path);
		return _alive;
	};

	#region jsDoc
	/// @func    __stmt(_w, _node)
	/// @desc    Walks one statement.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w    : The walker
	/// @param   {Struct.ASTNode} _node : The statement
	/// @returns {Bool} Whether the end of it can be reached
	#endregion
	static __stmt = function(_w, _node) {
		if (_w.noop) && (_w.cx.optimizer.__isNoOp(_node)) {
			_w.state = {};
			return true;
		}
		switch (_node.kind) {
			case __GMLC_NodeKind_ExprStmt:
				__sub(_w, 0, _node.expression);
			return true;
			case __GMLC_NodeKind_VarDeclList: {
				var _i = 0; repeat (array_length(_node.declarations)) {
					array_push(_w.path, _i);
					__varDecl(_w, _node.declarations[_i]);
					array_pop(_w.path);
				_i++}
			return true;}
			case __GMLC_NodeKind_StaticDecl: {
				var _i = 0; repeat (array_length(_node.declarations)) {
					var _d = _node.declarations[_i];
					if (_d.init != undefined) {
						array_push(_w.path, _i);
						__sub(_w, 1, _d.init);
						array_pop(_w.path);
					}
				_i++}
			return true;}
			case __GMLC_NodeKind_GlobalVarDecl: case __GMLC_NodeKind_EnumDecl: case __GMLC_NodeKind_MacroDecl:
			case __GMLC_NodeKind_Empty: case __GMLC_NodeKind_FunctionDecl: case __GMLC_NodeKind_ConstructorDecl:
			return true;
			case __GMLC_NodeKind_Block: return __walkList(_w, _node.body);
			case __GMLC_NodeKind_If: return __stmtIf(_w, _node);
			case __GMLC_NodeKind_For: return __stmtFor(_w, _node);
			case __GMLC_NodeKind_While: return __stmtWhile(_w, _node);
			case __GMLC_NodeKind_DoUntil: return __stmtDoUntil(_w, _node);
			case __GMLC_NodeKind_Repeat: return __stmtRepeat(_w, _node);
			case __GMLC_NodeKind_With: return __stmtWith(_w, _node);
			case __GMLC_NodeKind_Switch: return __stmtSwitch(_w, _node);
			case __GMLC_NodeKind_Try: return __stmtTry(_w, _node);
			case __GMLC_NodeKind_Return: case __GMLC_NodeKind_Throw:
				if (_node.argument != undefined) __sub(_w, 0, _node.argument);
			return false;
			case __GMLC_NodeKind_Exit: case __GMLC_NodeKind_Break: case __GMLC_NodeKind_Continue:
			return false;
			case __GMLC_NodeKind_Delete:
				__sub(_w, 0, _node.target);
			return true;
		}
		_w.state = {};
		return true;
	};

	#region jsDoc
	/// @func    __varDecl(_w, _d)
	/// @desc    A declarator of a `var`: the local takes the fact of its value, or may be undefined without one.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}            _w : The walker
	/// @param   {Struct.ASTVarDecl} _d : The declarator
	#endregion
	static __varDecl = function(_w, _d) {
		if (!__gmlc_opt_is_local(_d.target)) {
			if (_d.init != undefined) __sub(_w, 1, _d.init);
			return;
		}
		var _name = _d.target.name;
		if (_d.init != undefined) {
			var _r = __sub(_w, 1, _d.init);
			__setLocal(_w, _name, _r.f);
			__emit(_w, _d, [_r], _r);
		}
		else {
			var _old = _w.state[$ _name];
			var _undefined = __kindFact(GMLC_RANGE_KIND.UNDEFINED);
			if (_old != undefined) __setLocal(_w, _name, __join(_old, _undefined));
			__emit(_w, _d, [], __res(_undefined, false));
		}
	};

	#region jsDoc
	/// @func    __stmtIf(_w, _node)
	/// @desc    Walks an `if`: each branch with what the test says, and the join of the branches that complete.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the end of it can be reached
	#endregion
	static __stmtIf = function(_w, _node) {
		var _t = __sub(_w, 0, _node.test);
		var _st = __stateCopy(_w.state);
		var _sf = __stateCopy(_w.state);
		var _pt = __refine(_w, _st, _node.test, 1, _t.f);
		var _pf = __refine(_w, _sf, _node.test, 0, _t.f);
		var _end_t = undefined;
		var _end_f = _pf ? _sf : undefined;
		if (_pt) {
			_w.state = _st;
			array_push(_w.path, 1);
			if (__stmt(_w, _node.consequent)) _end_t = _w.state;
			array_pop(_w.path);
		}
		if (_node.alternate != undefined) {
			_end_f = undefined;
			if (_pf) {
				_w.state = _sf;
				array_push(_w.path, 2);
				if (__stmt(_w, _node.alternate)) _end_f = _w.state;
				array_pop(_w.path);
			}
		}
		if (_end_t != undefined) && (_end_f != undefined) {
			_w.state = __stateJoin(_end_t, _end_f);
			return true;
		}
		if (_end_t != undefined) {
			_w.state = _end_t;
			return true;
		}
		if (_end_f != undefined) {
			_w.state = _end_f;
			return true;
		}
		_w.state = {};
		return false;
	};

	#region jsDoc
	/// @func    __loopHead(_w, _s0, _acc, _parts)
	/// @desc    The state at the top of a loop that holds on every pass: what the code before it knew, without the
	///          locals the loop writes, and without relations to arrays other code could change.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w     : The walker
	/// @param   {Struct}         _s0    : The state before the loop
	/// @param   {Struct}         _acc   : The locals the loop writes
	/// @param   {Array<Struct.ASTNode>} _parts : The test, the update and the body
	/// @returns {Struct}
	#endregion
	static __loopHead = function(_w, _s0, _acc, _parts) {
		var _head = __stateHavoc(_w, _s0, _acc);
		var _i = 0; repeat (array_length(_parts)) {
			if (__hasUnclean(_w, _parts[_i])) {
				__stateClean(_w, _head);
				break;
			}
		_i++}
		return _head;
	};

	#region jsDoc
	/// @func    __writtenIn(_w, _parts)
	/// @desc    The locals written in several parts of a loop.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct} {all, names}
	#endregion
	static __writtenIn = function(_w, _parts) {
		var _acc = { all: false, names: {} };
		var _i = 0; repeat (array_length(_parts)) {
			__written(_w, _parts[_i], _acc);
		_i++}
		return _acc;
	};

	#region jsDoc
	/// @func    __stmtFor(_w, _node)
	/// @desc    Walks a `for`. A counter that only the update steps, by a constant, starting from a known whole
	///          number, is known inside the loop: from its start up, or down, and as far as the test lets it go.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the end of it can be reached
	#endregion
	static __stmtFor = function(_w, _node) {
		if (_node.init != undefined) __stmtAt(_w, __gmlc_opt_child_index(_node, _node.init), _node.init);
		var _s0 = _w.state;
		var _parts = [];
		if (_node.test != undefined) array_push(_parts, _node.test);
		if (_node.update != undefined) array_push(_parts, _node.update);
		array_push(_parts, _node.body);
		var _acc = __writtenIn(_w, _parts);
		var _head = __loopHead(_w, _s0, _acc, _parts);
		var _counter = __counter(_w, _s0, _node);
		if (_counter != undefined) {
			_head[$ _counter.name] = __counterFact(_w, _head, _node, _counter);
		}
		var _s_body = __stateCopy(_head);
		if (_node.test != undefined) {
			_w.state = __stateCopy(_head);
			var _t = __sub(_w, __gmlc_opt_child_index(_node, _node.test), _node.test);
			_s_body = _w.state;
			if (!__refine(_w, _s_body, _node.test, 1, _t.f)) _s_body = undefined;
		}
		if (_s_body != undefined) {
			_w.state = _s_body;
			__stmtAt(_w, __gmlc_opt_child_index(_node, _node.body), _node.body);
		}
		if (_node.update != undefined) {
			_w.state = __stateCopy(_head);
			__stmtAt(_w, __gmlc_opt_child_index(_node, _node.update), _node.update);
		}
		_w.state = __stateHavoc(_w, _s0, _acc);
		return true;
	};

	#region jsDoc
	/// @func    __counter(_w, _s0, _node)
	/// @desc    The counter of a `for`, when there is one: a local stepped by `++`, `--`, `+= c` or `-= c` (c a whole
	///          literal) in the update, never written in the test or the body, that starts as a finite whole Real.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w    : The walker
	/// @param   {Struct}         _s0   : The state before the loop
	/// @param   {Struct.ASTNode} _node : The loop
	/// @returns {Struct|Undefined} {name, step, entry}
	#endregion
	static __counter = function(_w, _s0, _node) {
		var _update = _node.update;
		if (_update == undefined) return undefined;
		if (_update.kind == __GMLC_NodeKind_ExprStmt) _update = _update.expression;
		var _name = undefined;
		var _step = 0;
		if (_update.kind == __GMLC_NodeKind_Update) && (__gmlc_opt_is_local(_update.argument)) {
			_name = _update.argument.name;
			_step = (_update.op == "++") ? 1 : -1;
		}
		else if (_update.kind == __GMLC_NodeKind_Assign) && (__gmlc_opt_is_local(_update.target)) && ((_update.op == "+=") || (_update.op == "-=")) {
			var _v = _update.value;
			if (_v.kind == __GMLC_NodeKind_Literal) && (_v.ty == "real") && (is_real(_v.value)) && (_v.value == floor(_v.value)) && (_v.value > 0) {
				_name = _update.target.name;
				_step = (_update.op == "+=") ? _v.value : -_v.value;
			}
		}
		if (_name == undefined) return undefined;
		var _other = { all: false, names: {} };
		if (_node.test != undefined) __written(_w, _node.test, _other);
		__written(_w, _node.body, _other);
		if (_other.all) || (struct_exists(_other.names, _name)) return undefined;
		var _entry = _s0[$ _name];
		if (_entry == undefined) || (_entry.k != GMLC_RANGE_KIND.REAL) || (!_entry.whole) || (_entry.nan) || (!__isFinite(_entry)) return undefined;
		return { name: _name, step: _step, entry: _entry };
	};

	#region jsDoc
	/// @func    __counterFact(_w, _head, _node, _counter)
	/// @desc    The fact of a counter at the test of its loop, on every pass: from its start in the direction it
	///          steps, and as far as the test lets it be before it fails, plus one more step.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __counterFact = function(_w, _head, _node, _counter) {
		var _entry = _counter.entry;
		var _lo = _entry.lo;
		var _hi = _entry.hi;
		var _up = _counter.step > 0;
		if (_up) {
			_hi = infinity;
		}
		else {
			_lo = -infinity;
		}
		var _wide = __fact(GMLC_RANGE_KIND.REAL, _lo, _hi, true, false, _entry.nz);
		var _test = _node.test;
		if (_test != undefined) && (_test.kind == __GMLC_NodeKind_Binary) && (!_w.epsilon) {
			var _op = _test.op;
			var _other = undefined;
			if (__gmlc_opt_is_local(_test.left)) && (_test.left.name == _counter.name) {
				_other = _test.right;
			}
			else if (__gmlc_opt_is_local(_test.right)) && (_test.right.name == _counter.name) {
				_other = _test.left;
				_op = __flip(_op);
			}
			if (_other != undefined) && (__isCompare(_op)) {
				var _acc = { all: false, names: {} };
				__written(_w, _other, _acc);
				if (!_acc.all) && (array_length(struct_get_names(_acc.names)) == 0) {
					var _s = __stateCopy(_head);
					_s[$ _counter.name] = _wide;
					var _y = __peek(_w, _s, _other).f;
					if (__num(_y)) && (!_y.nan) {
						if (_up) {
							if (_op == "<") _hi = max(_entry.hi, ceil(_y.hi) - 1 + _counter.step);
							if (_op == "<=") _hi = max(_entry.hi, floor(_y.hi + __margin) + _counter.step);
						}
						else {
							if (_op == ">") _lo = min(_entry.lo, floor(_y.lo) + 1 + _counter.step);
							if (_op == ">=") _lo = min(_entry.lo, ceil(_y.lo - __margin) + _counter.step);
						}
					}
				}
			}
		}
		if (_up) {
			return __fact(GMLC_RANGE_KIND.REAL, _entry.lo, _hi, true, false, _entry.nz);
		}
		return __fact(GMLC_RANGE_KIND.REAL, _lo, _entry.hi, true, false, _entry.nz);
	};

	#region jsDoc
	/// @func    __stmtWhile(_w, _node)
	/// @desc    Walks a `while`: the body with the test true, on a state that holds on every pass.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the end of it can be reached
	#endregion
	static __stmtWhile = function(_w, _node) {
		var _s0 = _w.state;
		var _parts = [_node.test, _node.body];
		var _acc = __writtenIn(_w, _parts);
		var _head = __loopHead(_w, _s0, _acc, _parts);
		_w.state = __stateCopy(_head);
		var _t = __sub(_w, 0, _node.test);
		var _s_body = _w.state;
		if (__refine(_w, _s_body, _node.test, 1, _t.f)) {
			_w.state = _s_body;
			__stmtAt(_w, 1, _node.body);
		}
		_w.state = __stateHavoc(_w, _s0, _acc);
		return true;
	};

	#region jsDoc
	/// @func    __stmtDoUntil(_w, _node)
	/// @desc    Walks a `do until`: the body, then the test, on a state that holds on every pass.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the end of it can be reached
	#endregion
	static __stmtDoUntil = function(_w, _node) {
		var _s0 = _w.state;
		var _parts = [_node.body, _node.test];
		var _acc = __writtenIn(_w, _parts);
		var _head = __loopHead(_w, _s0, _acc, _parts);
		_w.state = __stateCopy(_head);
		__stmtAt(_w, 0, _node.body);
		_w.state = __stateCopy(_head);
		__sub(_w, 1, _node.test);
		_w.state = __stateHavoc(_w, _s0, _acc);
		return true;
	};

	#region jsDoc
	/// @func    __stmtRepeat(_w, _node)
	/// @desc    Walks a `repeat`: the count, then the body on a state that holds on every pass.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the end of it can be reached
	#endregion
	static __stmtRepeat = function(_w, _node) {
		__sub(_w, 0, _node.count);
		var _s0 = _w.state;
		var _parts = [_node.body];
		var _acc = __writtenIn(_w, _parts);
		_w.state = __loopHead(_w, _s0, _acc, _parts);
		__stmtAt(_w, 1, _node.body);
		_w.state = __stateHavoc(_w, _s0, _acc);
		return true;
	};

	#region jsDoc
	/// @func    __stmtWith(_w, _node)
	/// @desc    Walks a `with`: the target, then the body as a loop that may run no time.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the end of it can be reached
	#endregion
	static __stmtWith = function(_w, _node) {
		__sub(_w, 0, _node.target);
		var _s0 = _w.state;
		var _parts = [_node.body];
		var _acc = __writtenIn(_w, _parts);
		_w.state = __loopHead(_w, _s0, _acc, _parts);
		__stmtAt(_w, 1, _node.body);
		_w.state = __stateHavoc(_w, _s0, _acc);
		return true;
	};

	#region jsDoc
	/// @func    __stmtSwitch(_w, _node)
	/// @desc    Walks a `switch`: every case on a state without the locals any case writes, since a case can be
	///          entered by falling from the one before.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the end of it can be reached
	#endregion
	static __stmtSwitch = function(_w, _node) {
		__sub(_w, 0, _node.discriminant);
		var _s0 = _w.state;
		var _acc = __writtenIn(_w, _node.cases);
		var _head = __loopHead(_w, _s0, _acc, _node.cases);
		var _c = 0; repeat (array_length(_node.cases)) {
			var _case = _node.cases[_c];
			array_push(_w.path, 1 + _c);
			_w.state = __stateCopy(_head);
			if (_case.kind == __GMLC_NodeKind_Case) {
				__sub(_w, 0, _case.test);
				__walkCaseBody(_w, _case.body, 1);
			}
			else {
				__walkCaseBody(_w, _case.body, 0);
			}
			array_pop(_w.path);
		_c++}
		_w.state = __stateHavoc(_w, _s0, _acc);
		return true;
	};

	#region jsDoc
	/// @func    __walkCaseBody(_w, _list, _first)
	/// @desc    Walks the statements of a case, which start at child position _first.
	/// @self    GMLC_Opt_ValueRangeSimplify
	#endregion
	static __walkCaseBody = function(_w, _list, _first) {
		var _i = 0; repeat (array_length(_list)) {
			array_push(_w.path, _first + _i);
			var _alive = __stmt(_w, _list[_i]);
			array_pop(_w.path);
			if (!_alive) return;
		_i++}
	};

	#region jsDoc
	/// @func    __stmtTry(_w, _node)
	/// @desc    Walks a `try`: the block on the state before it, the handlers on a state without what the block
	///          writes, and the state after it without what any part writes.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the end of it can be reached
	#endregion
	static __stmtTry = function(_w, _node) {
		var _s0 = _w.state;
		var _acc_block = __writtenIn(_w, [_node.block]);
		var _all = [_node.block];
		if (_node.catch_param != undefined) array_push(_all, _node.catch_param);
		if (_node.catch_body != undefined) array_push(_all, _node.catch_body);
		if (_node.finally_body != undefined) array_push(_all, _node.finally_body);
		var _acc = __writtenIn(_w, _all);
		_w.state = __stateCopy(_s0);
		__stmtAt(_w, __gmlc_opt_child_index(_node, _node.block), _node.block);
		var _handler = __stateHavoc(_w, _s0, _acc_block);
		if (_node.catch_body != undefined) {
			_w.state = __stateCopy(_handler);
			if (_node.catch_param != undefined) && (__gmlc_opt_is_local(_node.catch_param)) {
				_w.state[$ _node.catch_param.name] = __top;
			}
			__stmtAt(_w, __gmlc_opt_child_index(_node, _node.catch_body), _node.catch_body);
		}
		if (_node.finally_body != undefined) {
			_w.state = __stateHavoc(_w, _s0, _acc);
			__stmtAt(_w, __gmlc_opt_child_index(_node, _node.finally_body), _node.finally_body);
		}
		_w.state = __stateHavoc(_w, _s0, _acc);
		return true;
	};
	#endregion

	#region Refinement
	#region jsDoc
	/// @func    __refine(_w, _s, _node, _truth, _f)
	/// @desc    Narrows a state by a test being true (1) or false (0): comparisons of a local with a number, `!`,
	///          `&&` when true and `||` when false, the truth of a local, and the `is_` tests. Returns false when the
	///          test cannot have that value.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w     : The walker
	/// @param   {Struct}         _s     : The state, changed in place
	/// @param   {Struct.ASTNode} _node  : The test
	/// @param   {Real}           _truth : 1 or 0
	/// @param   {Struct}         _f     : The fact of the test, undefined to work it out
	/// @returns {Bool} Whether the state is possible
	#endregion
	static __refine = function(_w, _s, _node, _truth, _f) {
		// `&&`, `||` and `!` are not evaluated again here: their operands are refined one by one, and evaluating every
		// left part of a chain `a && b && c ...` again at each level takes time exponential in its length
		if (_f == undefined) && (_node.kind != __GMLC_NodeKind_Logical) && ((_node.kind != __GMLC_NodeKind_Unary) || (_node.op != "!")) {
			_f = __peek(_w, _s, _node).f;
		}
		var _t = (_f == undefined) ? -1 : __truth(_f);
		if (_t != -1) && (_t != _truth) return false;
		switch (_node.kind) {
			case __GMLC_NodeKind_Unary:
				if (_node.op == "!") return __refine(_w, _s, _node.argument, 1 - _truth, undefined);
			break;
			case __GMLC_NodeKind_Logical:
				if (_node.op == "&&") && (_truth == 1) {
					return __refine(_w, _s, _node.left, 1, undefined) && __refine(_w, _s, _node.right, 1, undefined);
				}
				if (_node.op == "||") && (_truth == 0) {
					return __refine(_w, _s, _node.left, 0, undefined) && __refine(_w, _s, _node.right, 0, undefined);
				}
			break;
			case __GMLC_NodeKind_Binary:
				if (__isCompare(_node.op)) return __refineCompare(_w, _s, _node, _truth);
			break;
			case __GMLC_NodeKind_Identifier:
				if (__gmlc_opt_is_local(_node)) return __narrowTruth(_s, _node.name, _truth);
			break;
			case __GMLC_NodeKind_Call: {
				var _name = __gmlc_opt_builtin_call(_node);
				if (_name != undefined) && (__isCheck(_name)) && (array_length(_node.args) == 1) && (__gmlc_opt_is_local(_node.args[0])) {
					return __narrowKind(_s, _node.args[0].name, _name, _truth);
				}
			break;}
		}
		return true;
	};

	#region jsDoc
	/// @func    __narrowTruth(_s, _name, _truth)
	/// @desc    A local used as a condition: true removes undefined and puts a number above one half, false puts a
	///          number at one half or below.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the state is possible
	#endregion
	static __narrowTruth = function(_s, _name, _truth) {
		var _x = _s[$ _name];
		if (_x == undefined) return true;
		var _k = _x.k;
		var _lo = _x.lo;
		var _hi = _x.hi;
		var _nan = _x.nan;
		if (_truth == 1) {
			_k = _k & ~GMLC_RANGE_KIND.UNDEFINED;
			if (_k == 0) return false;
			if (__num(_x)) {
				_lo = max(_lo, _x.whole ? 1 : 0.5);
				_nan = false;
			}
		}
		else if (__num(_x)) {
			_hi = min(_hi, _x.whole ? 0 : 0.5);
		}
		if (_lo > _hi) return false;
		if (_k == _x.k) && (_lo == _x.lo) && (_hi == _x.hi) && (_nan == _x.nan) return true;
		var _n = __fact(_k, _lo, _hi, _x.whole, _nan, _x.nz && (_lo <= 0) && (_hi >= 0));
		_n.rel = _x.rel;
		_n.rel_of = _x.rel_of;
		_n.len_lo = _x.len_lo;
		_s[$ _name] = _n;
		return true;
	};

	#region jsDoc
	/// @func    __narrowKind(_s, _name, _check, _truth)
	/// @desc    A local passed to an `is_` test: the kinds the test allows when true, or rules out when false.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the state is possible
	#endregion
	static __narrowKind = function(_s, _name, _check, _truth) {
		var _x = _s[$ _name];
		if (_x == undefined) return true;
		var _keep = GMLC_RANGE_KIND.ALL;
		var _single = 0;
		switch (_check) {
			case "is_string": _single = GMLC_RANGE_KIND.STRING; break;
			case "is_array": _single = GMLC_RANGE_KIND.ARRAY; break;
			case "is_struct": _single = GMLC_RANGE_KIND.STRUCT; break;
			case "is_bool": _single = GMLC_RANGE_KIND.BOOL; break;
			case "is_int64": _single = GMLC_RANGE_KIND.INT64; break;
			case "is_undefined": _single = GMLC_RANGE_KIND.UNDEFINED; break;
			case "is_real": case "is_numeric":
				if (_truth == 1) {
					_keep = GMLC_RANGE_KIND.ALL & ~113;
				}
				else {
					_keep = GMLC_RANGE_KIND.ALL & ~GMLC_RANGE_KIND.REAL;
				}
			break;
			default: return true;
		}
		if (_single != 0) {
			_keep = (_truth == 1) ? _single : (GMLC_RANGE_KIND.ALL & ~_single);
		}
		var _k = _x.k & _keep;
		if (_k == 0) return false;
		if (_k == _x.k) return true;
		var _n = __fact(_k, _x.lo, _x.hi, _x.whole, _x.nan, _x.nz);
		_n.rel = _x.rel;
		_n.rel_of = _x.rel_of;
		_n.len_lo = _x.len_lo;
		_s[$ _name] = _n;
		return true;
	};

	#region jsDoc
	/// @func    __refineCompare(_w, _s, _node, _truth)
	/// @desc    Narrows the locals a comparison names by the comparison being true or false.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the state is possible
	#endregion
	static __refineCompare = function(_w, _s, _node, _truth) {
		if (_w.epsilon) return true;
		var _lf = __peek(_w, _s, _node.left).f;
		var _rf = __peek(_w, _s, _node.right).f;
		var _d = __decide(_node.op, _lf, _rf);
		if (_d != -1) && (_d != _truth) return false;
		var _ok = true;
		if (__gmlc_opt_is_local(_node.left)) _ok = __narrow(_w, _s, _node.left.name, _node.op, _truth, _rf);
		if (_ok) && (__gmlc_opt_is_local(_node.right)) _ok = __narrow(_w, _s, _node.right.name, __flip(_node.op), _truth, _lf);
		return _ok;
	};

	#region jsDoc
	/// @func    __narrow(_w, _s, _name, _op, _truth, _y)
	/// @desc    Narrows a local `x` by `x op y` being true or false, with the fact of `y`. The epsilon makes a test
	///          that is true only mean `x` is within the margin of the bound, and one that is false only mean `x` is
	///          not past it, so the bounds are widened by the margin, and for a whole `x` rounded inwards.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool} Whether the state is possible
	#endregion
	static __narrow = function(_w, _s, _name, _op, _truth, _y) {
		var _x = _s[$ _name];
		if (_x == undefined) || (!__num(_x)) || (!__num(_y)) || (_y.nan) return true;
		if (_op == "!=") {
			_op = "==";
			_truth = 1 - _truth;
		}
		var _lo = _x.lo;
		var _hi = _x.hi;
		var _nan = _x.nan;
		var _whole = _x.whole;
		var _m = __margin;
		switch (_op) {
			case "<":
				if (_truth == 1) {
					_hi = min(_hi, _whole ? ceil(_y.hi) - 1 : _y.hi);
					_nan = false;
				}
				else {
					_lo = max(_lo, _whole ? ceil(_y.lo - _m) : _y.lo - _m);
				}
			break;
			case "<=":
				if (_truth == 1) {
					_hi = min(_hi, _whole ? floor(_y.hi + _m) : _y.hi + _m);
					_nan = false;
				}
				else {
					_lo = max(_lo, _whole ? floor(_y.lo) + 1 : _y.lo);
				}
			break;
			case ">":
				if (_truth == 1) {
					_lo = max(_lo, _whole ? floor(_y.lo) + 1 : _y.lo);
					_nan = false;
				}
				else {
					_hi = min(_hi, _whole ? floor(_y.hi + _m) : _y.hi + _m);
				}
			break;
			case ">=":
				if (_truth == 1) {
					_lo = max(_lo, _whole ? ceil(_y.lo - _m) : _y.lo - _m);
					_nan = false;
				}
				else {
					_hi = min(_hi, _whole ? ceil(_y.hi) - 1 : _y.hi);
				}
			break;
			case "==":
				if (_truth == 1) {
					_lo = max(_lo, _whole ? ceil(_y.lo - _m) : _y.lo - _m);
					_hi = min(_hi, _whole ? floor(_y.hi + _m) : _y.hi + _m);
					_nan = false;
				}
			break;
		}
		if (_lo > _hi) return false;
		var _n = __fact(_x.k, _lo, _hi, _whole, _nan, _x.nz && (_lo <= 0) && (_hi >= 0));
		_n.rel = _x.rel;
		_n.rel_of = _x.rel_of;
		_n.len_lo = _x.len_lo;
		if (_truth == 1) && (_y.rel != GMLC_RANGE_REL.NONE) {
			if (_op == "<") {
				_n.rel = GMLC_RANGE_REL.LT;
				_n.rel_of = _y.rel_of;
			}
			else if (_op == "<=") && (_whole) {
				_n.rel = _y.rel;
				_n.rel_of = _y.rel_of;
			}
			_w.related[$ _y.rel_of] = true;
		}
		_s[$ _name] = _n;
		return true;
	};
	#endregion

	#region Expressions
	#region jsDoc
	/// @func    __eval(_w, _node)
	/// @desc    Evaluates an expression: its fact and whether it can be dropped, and what it does to the state.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w    : The walker
	/// @param   {Struct.ASTNode} _node : The expression
	/// @returns {Struct} {f, safe}
	#endregion
	static __eval = function(_w, _node) {
		if (_node.origin != undefined) && (__opaque(_node.origin)) return __res(__top, false);
		switch (_node.kind) {
			case __GMLC_NodeKind_Literal: return __evalLiteral(_node);
			case __GMLC_NodeKind_Identifier: return __evalIdentifier(_w, _node);
			case __GMLC_NodeKind_Binary: return __evalBinary(_w, _node);
			case __GMLC_NodeKind_Logical: return __evalLogical(_w, _node);
			case __GMLC_NodeKind_Nullish: return __evalNullish(_w, _node);
			case __GMLC_NodeKind_Unary: return __evalUnary(_w, _node);
			case __GMLC_NodeKind_Update: return __evalUpdate(_w, _node);
			case __GMLC_NodeKind_Conditional: return __evalConditional(_w, _node);
			case __GMLC_NodeKind_Assign: return __evalAssign(_w, _node);
			case __GMLC_NodeKind_Call: return __evalCall(_w, _node);
			case __GMLC_NodeKind_Index: return __evalIndex(_w, _node, false);
			case __GMLC_NodeKind_MethodCall: case __GMLC_NodeKind_New: return __evalConstruct(_w, _node);
			case __GMLC_NodeKind_ArrayLiteral: return __evalArrayLiteral(_w, _node);
			case __GMLC_NodeKind_StructLiteral: return __evalStructLiteral(_w, _node);
			case __GMLC_NodeKind_TemplateString: {
				var _i = 0; repeat (array_length(_node.exprs)) {
					__sub(_w, _i, _node.exprs[_i]);
				_i++}
				return __res(__kindFact(GMLC_RANGE_KIND.STRING), false);
			}
			case __GMLC_NodeKind_Nameof: return __res(__kindFact(GMLC_RANGE_KIND.STRING), true);
			case __GMLC_NodeKind_FunctionExpr: return __res(__kindFact(GMLC_RANGE_KIND.OTHER), true);
		}
		var _acc = { all: false, names: {} };
		__written(_w, _node, _acc);
		_w.state = __stateHavoc(_w, _w.state, _acc);
		__stateClean(_w, _w.state);
		return __res(__top, false);
	};

	#region jsDoc
	/// @func    __evalLiteral(_node)
	/// @desc    The fact of a literal.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalLiteral = function(_node) {
		switch (_node.ty) {
			case "real": case "color": {
				var _v = _node.value;
				if (is_real(_v) || is_int64(_v)) return __res(__point(real(_v)), true);
			break;}
			case "int64": return __res(__kindFact(GMLC_RANGE_KIND.INT64), true);
			case "string": return __res(__kindFact(GMLC_RANGE_KIND.STRING), true);
			case "bool": return __res((_node.value) ? __bool(1, 1) : __bool(0, 0), true);
			case "undefined": return __res(__kindFact(GMLC_RANGE_KIND.UNDEFINED), true);
		}
		return __res(__top, true);
	};

	#region jsDoc
	/// @func    __evalIdentifier(_w, _node)
	/// @desc    The fact of a name: a local with a fact is its fact and can be dropped; built-in constants, enums and
	///          macros are unknown but harmless; any other name may be unset or an asset.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalIdentifier = function(_w, _node) {
		var _symbol = _node.symbol;
		if (_symbol == undefined) return __res(__top, false);
		switch (_symbol.kind) {
			case "Local": {
				var _f = _w.state[$ _node.name];
				if (_f == undefined) return __res(__heldFact(_node), false);
				return __res(_f, true);
			}
			case "BuiltinConstant": case "Enum": case "Macro":
			return __res(__top, true);
		}
		return __res(__top, false);
	};

	#region jsDoc
	/// @func    __evalBinary(_w, _node)
	/// @desc    Evaluates `a op b`.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalBinary = function(_w, _node) {
		var _a = __sub(_w, 0, _node.left);
		var _b = __sub(_w, 1, _node.right);
		var _f = __binaryFact(_node.op, _a.f, _b.f, _w.epsilon);
		var _r = __res(_f, _a.safe && _b.safe && __binarySafe(_node.op, _a.f, _b.f));
		__emit(_w, _node, [_a, _b], _r);
		return _r;
	};

	#region jsDoc
	/// @func    __evalLogical(_w, _node)
	/// @desc    Evaluates `a && b`, `a || b` or `a ^^ b`. The right operand of the first two is evaluated on the
	///          state where the left one lets it run, and skipped when it never does.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalLogical = function(_w, _node) {
		var _a = __sub(_w, 0, _node.left);
		var _op = _node.op;
		if (_op == "^^") {
			var _b = __sub(_w, 1, _node.right);
			var _r = __res(__bool(0, 1), _a.safe && _b.safe && __truthSafe(_a.f) && __truthSafe(_b.f));
			__emit(_w, _node, [_a, _b], _r);
			return _r;
		}
		var _runs = (_op == "&&") ? 1 : 0;
		var _s_run = __stateCopy(_w.state);
		var _s_skip = __stateCopy(_w.state);
		var _p_run = __refine(_w, _s_run, _node.left, _runs, _a.f);
		var _p_skip = __refine(_w, _s_skip, _node.left, 1 - _runs, _a.f);
		var _b = undefined;
		var _operands = [_a];
		if (_p_run) {
			_w.state = _s_run;
			_b = __sub(_w, 1, _node.right);
			_operands = [_a, _b];
			_w.state = _p_skip ? __stateJoin(_w.state, _s_skip) : _w.state;
		}
		else {
			_w.state = _s_skip;
		}
		var _ta = __truth(_a.f);
		var _tb = (_b == undefined) ? -1 : __truth(_b.f);
		var _f = __bool(0, 1);
		if (_op == "&&") {
			if (_ta == 0) || (_tb == 0) {
				_f = __bool(0, 0);
			}
			else if (_ta == 1) && (_tb == 1) {
				_f = __bool(1, 1);
			}
		}
		else if (_ta == 1) || (_tb == 1) {
			_f = __bool(1, 1);
		}
		else if (_ta == 0) && (_tb == 0) {
			_f = __bool(0, 0);
		}
		var _safe = _a.safe && __truthSafe(_a.f) && ((_b == undefined) || (_b.safe && __truthSafe(_b.f)));
		var _res = __res(_f, _safe);
		__emit(_w, _node, _operands, _res);
		return _res;
	};

	#region jsDoc
	/// @func    __evalNullish(_w, _node)
	/// @desc    Evaluates `a ?? b`; `b` is skipped when `a` cannot be undefined or `pointer_null`.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalNullish = function(_w, _node) {
		var _a = __sub(_w, 0, _node.left);
		var _nullish = GMLC_RANGE_KIND.UNDEFINED | GMLC_RANGE_KIND.OTHER;
		if ((_a.f.k & _nullish) == 0) {
			var _r = __res(_a.f, _a.safe);
			__emit(_w, _node, [_a], _r);
			return _r;
		}
		var _skip = __stateCopy(_w.state);
		var _b = __sub(_w, 1, _node.right);
		_w.state = __stateJoin(_w.state, _skip);
		var _left = _a.f;
		if ((_left.k & ~GMLC_RANGE_KIND.UNDEFINED) != 0) {
			_left = __fact(_left.k & ~GMLC_RANGE_KIND.UNDEFINED, _left.lo, _left.hi, _left.whole, _left.nan, _left.nz);
			_left.len_lo = _a.f.len_lo;
		}
		var _res = __res(__join(_left, _b.f), _a.safe && _b.safe);
		__emit(_w, _node, [_a, _b], _res);
		return _res;
	};

	#region jsDoc
	/// @func    __evalUnary(_w, _node)
	/// @desc    Evaluates `-a`, `!a`, `+a` or `~a`.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalUnary = function(_w, _node) {
		var _a = __sub(_w, 0, _node.argument);
		var _f = __top;
		var _safe = false;
		switch (_node.op) {
			case "-":
				if (_a.f.k == GMLC_RANGE_KIND.REAL) {
					_f = __negF(_a.f);
					_safe = _a.safe;
				}
				else if (_a.f.k == GMLC_RANGE_KIND.INT64) {
					_f = _a.f;
				}
			break;
			case "!": {
				var _t = __truth(_a.f);
				_f = (_t == -1) ? __bool(0, 1) : __bool(1 - _t, 1 - _t);
				_safe = _a.safe && __truthSafe(_a.f);
			break;}
			case "~":
				_f = __kindFact(GMLC_RANGE_KIND.INT64);
			break;
		}
		var _r = __res(_f, _safe);
		__emit(_w, _node, [_a], _r);
		return _r;
	};

	#region jsDoc
	/// @func    __evalTarget(_w, _i, _target, _read)
	/// @desc    Evaluates the parts of something assigned to: the object and keys of an accessor. A name is not read
	///          unless _read.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct|Undefined} What reading the target gave, when _read
	#endregion
	static __evalTarget = function(_w, _i, _target, _read) {
		if (_target.kind == __GMLC_NodeKind_Index) {
			array_push(_w.path, _i);
			__evalIndex(_w, _target, true);
			array_pop(_w.path);
			return undefined;
		}
		if (_target.kind == __GMLC_NodeKind_Identifier) {
			return _read ? __evalIdentifier(_w, _target) : undefined;
		}
		return __sub(_w, _i, _target);
	};

	#region jsDoc
	/// @func    __evalUpdate(_w, _node)
	/// @desc    Evaluates `a++`, `++a`, `a--` or `--a`.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalUpdate = function(_w, _node) {
		var _arg = _node.argument;
		var _op = string_char_at(_node.op, 1);
		var _one = __point(1);
		var _r;
		if (__gmlc_opt_is_local(_arg)) {
			var _cur = _w.state[$ _arg.name] ?? __top;
			var _new = __binaryFact(_op, _cur, _one, _w.epsilon);
			__setLocal(_w, _arg.name, _new);
			_r = __res(_node.prefix ? _new : _cur, false);
			__emit(_w, _node, [__res(_cur, true)], _r, { after: _new });
			return _r;
		}
		__evalTarget(_w, 0, _arg, false);
		_r = __res(__top, false);
		__emit(_w, _node, [], _r, { after: __top });
		return _r;
	};

	#region jsDoc
	/// @func    __evalConditional(_w, _node)
	/// @desc    Evaluates `c ? a : b`: each branch on the state its test gives, skipped when it never runs.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalConditional = function(_w, _node) {
		var _t = __sub(_w, 0, _node.test);
		var _st = __stateCopy(_w.state);
		var _sf = __stateCopy(_w.state);
		var _pt = __refine(_w, _st, _node.test, 1, _t.f);
		var _pf = __refine(_w, _sf, _node.test, 0, _t.f);
		var _a = undefined;
		var _b = undefined;
		var _end_t = undefined;
		var _end_f = undefined;
		if (_pt) {
			_w.state = _st;
			_a = __sub(_w, 1, _node.consequent);
			_end_t = _w.state;
		}
		if (_pf) {
			_w.state = _sf;
			_b = __sub(_w, 2, _node.alternate);
			_end_f = _w.state;
		}
		if (_end_t != undefined) && (_end_f != undefined) {
			_w.state = __stateJoin(_end_t, _end_f);
		}
		else if (_end_t != undefined) {
			_w.state = _end_t;
		}
		else if (_end_f != undefined) {
			_w.state = _end_f;
		}
		var _f = __top;
		if (_a != undefined) && (_b != undefined) {
			_f = __join(_a.f, _b.f);
		}
		else if (_a != undefined) {
			_f = _a.f;
		}
		else if (_b != undefined) {
			_f = _b.f;
		}
		var _safe = _t.safe && __truthSafe(_t.f) && ((_a == undefined) || _a.safe) && ((_b == undefined) || _b.safe);
		var _r = __res(_f, _safe);
		__emit(_w, _node, [_t], _r);
		return _r;
	};

	#region jsDoc
	/// @func    __evalAssign(_w, _node)
	/// @desc    Evaluates an assignment: a local takes the fact of its new value, `a op= b` the fact of `a op b`,
	///          and `a ??= b` evaluates `b` only when `a` can be undefined.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalAssign = function(_w, _node) {
		var _target = _node.target;
		var _op = _node.op;
		var _local = __gmlc_opt_is_local(_target);
		var _name = _local ? _target.name : "";
		var _fact;
		var _operands;
		if (_op == "=") {
			if (!_local) __evalTarget(_w, 0, _target, false);
			var _v = __sub(_w, 1, _node.value);
			_fact = _v.f;
			_operands = [_v];
			if (_local) __setLocal(_w, _name, _fact);
		}
		else if (_op == "??=") {
			var _cur = __top;
			if (_local) {
				_cur = _w.state[$ _name] ?? __top;
			}
			else {
				__evalTarget(_w, 0, _target, false);
			}
			var _nullish = GMLC_RANGE_KIND.UNDEFINED | GMLC_RANGE_KIND.OTHER;
			if ((_cur.k & _nullish) == 0) {
				_fact = _cur;
				_operands = [];
			}
			else {
				var _skip = __stateCopy(_w.state);
				var _v = __sub(_w, 1, _node.value);
				_w.state = __stateJoin(_w.state, _skip);
				_fact = __join(_cur, _v.f);
				_operands = [_v];
				if (_local) __setLocal(_w, _name, _fact);
			}
		}
		else {
			var _cur = __top;
			if (_local) {
				_cur = _w.state[$ _name] ?? __top;
			}
			else {
				__evalTarget(_w, 0, _target, true);
			}
			var _v = __sub(_w, 1, _node.value);
			_fact = __binaryFact(string_copy(_op, 1, string_length(_op) - 1), _cur, _v.f, _w.epsilon);
			_operands = [_v];
			if (_local) __setLocal(_w, _name, _fact);
		}
		var _r = __res(_fact, false);
		__emit(_w, _node, _operands, _r);
		return _r;
	};

	#region jsDoc
	/// @func    __evalCall(_w, _node)
	/// @desc    Evaluates a call. A built-in gets the fact of its result; anything else is unknown, and a function
	///          that may run other code forgets the relations to array lengths.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalCall = function(_w, _node) {
		var _args = _node.args;
		var _n = array_length(_args);
		var _i = 0; repeat (_n) {
			if (_args[_i] == undefined) {
				var _acc = { all: false, names: {} };
				__written(_w, _node, _acc);
				_w.state = __stateHavoc(_w, _w.state, _acc);
				__stateClean(_w, _w.state);
				return __res(__top, false);
			}
		_i++}
		var _name = __gmlc_opt_builtin_call(_node);
		if (_node.callee.kind != __GMLC_NodeKind_Identifier) __sub(_w, 0, _node.callee);
		var _rs = [];
		_i = 0; repeat (_n) {
			array_push(_rs, __sub(_w, 1 + _i, _args[_i]));
		_i++}
		var _r;
		var _clean = false;
		if (_name != undefined) {
			_r = __res(__builtinFact(_w, _node, _name, _rs), __builtinSafe(_name, _node.args, _rs));
			_clean = __cleanCall(_name);
		}
		else {
			_r = __res(__top, false);
		}
		__emit(_w, _node, _rs, _r);
		if (!_clean) __stateClean(_w, _w.state);
		return _r;
	};

	#region jsDoc
	/// @func    __evalConstruct(_w, _node)
	/// @desc    Evaluates a method call or `new`: the object and arguments, an unknown result (a struct for `new`),
	///          and other code that may run.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalConstruct = function(_w, _node) {
		var _args = _node.args;
		var _operands = [];
		var _first = 0;
		if (_node.kind == __GMLC_NodeKind_MethodCall) {
			array_push(_operands, __sub(_w, 0, _node.object));
			_first = 1;
		}
		else if (_node.callee.kind != __GMLC_NodeKind_Identifier) {
			array_push(_operands, __sub(_w, 0, _node.callee));
			_first = 1;
		}
		else {
			_first = 1;
		}
		var _i = 0; repeat (array_length(_args)) {
			if (_args[_i] != undefined) array_push(_operands, __sub(_w, _first + _i, _args[_i]));
		_i++}
		var _r = __res((_node.kind == __GMLC_NodeKind_New) ? __kindFact(GMLC_RANGE_KIND.STRUCT) : __top, false);
		__emit(_w, _node, _operands, _r);
		__stateClean(_w, _w.state);
		return _r;
	};

	#region jsDoc
	/// @func    __evalArrayLiteral(_w, _node)
	/// @desc    Evaluates `[a, b, ...]`: an array with that many elements at least.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalArrayLiteral = function(_w, _node) {
		var _operands = [];
		var _safe = true;
		var _i = 0; repeat (array_length(_node.elements)) {
			var _e = __sub(_w, _i, _node.elements[_i]);
			array_push(_operands, _e);
			if (!_e.safe) _safe = false;
		_i++}
		var _f = __kindFact(GMLC_RANGE_KIND.ARRAY);
		_f.len_lo = array_length(_node.elements);
		var _r = __res(_f, _safe);
		__emit(_w, _node, _operands, _r);
		return _r;
	};

	#region jsDoc
	/// @func    __evalStructLiteral(_w, _node)
	/// @desc    Evaluates `{a: x, ...}`: the values, in order, and a struct.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Struct}
	#endregion
	static __evalStructLiteral = function(_w, _node) {
		var _operands = [];
		var _safe = true;
		var _i = 0; repeat (array_length(_node.entries)) {
			var _entry = _node.entries[_i];
			array_push(_w.path, _i);
			var _e = (_entry.value != undefined) ? __sub(_w, 0, _entry.value) : __res(__top, false);
			array_pop(_w.path);
			array_push(_operands, _e);
			if (!_e.safe) _safe = false;
		_i++}
		var _r = __res(__kindFact(GMLC_RANGE_KIND.STRUCT), _safe);
		__emit(_w, _node, _operands, _r);
		return _r;
	};

	#region jsDoc
	/// @func    __evalIndex(_w, _node, _write)
	/// @desc    Evaluates an accessor. For `a[i]` and `a[@ i]` of a local array, the event says whether the index is
	///          proven to be inside the array: a whole number from zero up that is below the length the array has
	///          for sure, or below its length by a test.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @param   {Struct}         _w     : The walker
	/// @param   {Struct.ASTNode} _node  : The accessor
	/// @param   {Bool}           _write : Whether it is assigned to
	/// @returns {Struct}
	#endregion
	static __evalIndex = function(_w, _node, _write) {
		var _o = __sub(_w, 0, _node.object);
		var _operands = [_o];
		var _keys = _node.keys;
		var _i = 0; repeat (array_length(_keys)) {
			array_push(_operands, __sub(_w, 1 + _i, _keys[_i]));
		_i++}
		var _proven = __indexProof(_w, _node, _operands);
		var _r = __res(__top, _proven && _o.safe && !_write);
		__emit(_w, _node, _operands, _r, { proven: _proven, write: _write });
		return _r;
	};

	#region jsDoc
	/// @func    __indexProof(_w, _node, _operands)
	/// @desc    Whether an accessor on a local array has an index inside the array.
	/// @self    GMLC_Opt_ValueRangeSimplify
	/// @returns {Bool}
	#endregion
	static __indexProof = function(_w, _node, _operands) {
		if (_node.accessor != "Array") && (_node.accessor != "ArrayAt") return false;
		if (array_length(_operands) != 2) || (!__gmlc_opt_is_local(_node.object)) return false;
		var _of = _operands[0].f;
		var _ix = _operands[1].f;
		if (_of.k != GMLC_RANGE_KIND.ARRAY) return false;
		if (_ix.k != GMLC_RANGE_KIND.REAL) || (!_ix.whole) || (_ix.nan) || (_ix.lo < 0) return false;
		var _name = _node.object.name;
		var _owned = struct_exists(_w.contained, _name);
		if (_owned) && (_ix.hi < _of.len_lo) return true;
		return (_ix.rel == GMLC_RANGE_REL.LT) && (_ix.rel_of == _name);
	};
	#endregion
}
