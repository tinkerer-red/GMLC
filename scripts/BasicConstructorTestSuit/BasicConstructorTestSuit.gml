function BasicConstructorTestSuit() : TestSuite() constructor {
	
	addFact("constructor test #1", function() {
		var _r = compile_and_execute(@'
		return { aInstance : "This is A`s Instance", cInstance : "This is C`s Instance", argumentChain : 3, localChain : 2, bInstance : "This is B`s Instance" }
		')
		assert_struct_equals(_r, { aInstance : "This is A`s Instance", cInstance : "This is C`s Instance", argumentChain : 3, localChain : 2, bInstance : "This is B`s Instance" })
	})
	
	addFact("constructor test #2", function() {
		compile_and_execute(@'
		function a(arg0) constructor {
			static overwrite = "A Overwrite"
			static aStatic = "This is A`s Static"
			aInstance = "This is A`s Instance"
			argumentChain = arg0;
			localChain = 0;
		}
		function b(arg0) : a(arg0+1) constructor {
			static overwrite = "B Overwrite"
			static bStatic = "This is B`s Static"
			bInstance = "This is B`s Instance"
			localChain++;
		}
		function c(arg0) : b(arg0+1) constructor {
			static overwrite = "C Overwrite"
			static cStatic = "This is C`s Static"
			cInstance = "This is C`s Instance"
			localChain++;
		}
		
		function abc() constructor {}
		
		var _a = new a(1);
		
		//self
		var _struct = _a;
		var _expected = { aInstance : "This is A`s Instance", argumentChain : 1, localChain : 0 }
		assert_struct_equals(_struct, _expected, "A`s Structs are not equal")
		assert_equals(instanceof(_a), script_get_name(a), "Object A is not instanceof() constructor A")
		//A`s statics
		var _struct = static_get(_a)
		var _expected = static_get(a)
		assert_equals(_struct, _expected, "A`s Static Structs are not equal")
		assert_true(is_instanceof(_a, a), "Object A not is_instanceof() constructor A")
		
		var _b = new b(1);
		
		//self
		var _struct = _b;
		var _expected = { aInstance : "This is A`s Instance", bInstance : "This is B`s Instance", argumentChain : 2, localChain : 1, }
		assert_struct_equals(_struct, _expected, "B`s Structs are not equal")
		assert_equals(instanceof(_b), script_get_name(b), "Object B is not instanceof() constructor B")
		//B`s statics
		var _struct = static_get(_b)
		var _expected = static_get(b)
		assert_equals(_struct, _expected, "B`s Static Structs are not equal")
		assert_true(is_instanceof(_b, b), "Object B not is_instanceof() constructor B")
		//A`s statics
		var _struct = static_get(static_get(_b))
		var _expected = static_get(a)
		assert_equals(_struct, _expected, "B`s 2xStatic`s Structs are not equal to construct A`s")
		assert_true(is_instanceof(_b, a), "Object B not is_instanceof() constructor A")
		
		var _c = new c(1);
		
		//self
		var _struct = _c;
		var _expected = {aInstance:"This is A`s Instance", bInstance:"This is B`s Instance", cInstance:"This is C`s Instance", argumentChain:3, localChain:2}
		assert_struct_equals(_struct, _expected, "C`s Structs are not equal")
		assert_equals(instanceof(_c), script_get_name(c), "Object C is not instanceof() constructor C")
		//C`s statics
		var _struct = static_get(_c)
		var _expected = static_get(c)
		assert_equals(_struct, _expected, "C`s Static Structs are not equal")
		assert_true(is_instanceof(_c, c), "Object C not is_instanceof() constructor C")
		//B`s statics
		var _struct = static_get(static_get(_c))
		var _expected = static_get(b)
		assert_equals(_struct, _expected, "C`s 2xStatic`s Structs are not equal to construct B`s")
		assert_true(is_instanceof(_c, b), "Object C not is_instanceof() constructor B")
		//A`s statics
		var _struct = static_get(static_get(static_get(_c)))
		var _expected = static_get(a)
		assert_equals(_struct, _expected, "C`s 3xStatic`s Structs are not equal to construct A`s")
		assert_true(is_instanceof(_c, a), "Object C not is_instanceof() constructor A")
		
		assert_false(is_instanceof(_c, abc), "Object C should not ba an instance of ABC")
		//')
	});
	
	addFact("constructor test #3", function() {
		compile_and_execute(@'
		function __TestSuitFunctionConstructorChildA() constructor {
			static child_a_static_exist = true;
			child_a_local_exist = true;
		}
		function __TestSuitFunctionConstructorChildB() : __TestSuitFunctionConstructorParent() constructor {
			static child_b_static_exist = true;
			child_b_local_exist = true;
		}
		function __TestSuitFunctionConstructorChildC() : __TestSuitFunctionConstructorChildB() constructor {
			static child_c_static_exist = true;
			child_c_local_exist = true;
		}
		
		var _struct_a = {struct_a : "struct_a"}; static_set(_struct_a, {struct_a_static: "struct_a_static"});
		var _struct_b = {struct_b : "struct_b"}; static_set(_struct_b, {struct_b_static: "struct_b_static"});
		var _struct_c = {struct_c : "struct_c"}; static_set(_struct_c, {struct_c_static: "struct_c_static"});
		var _struct_parent = {struct_parent : "struct_parent"}; static_set(_struct_parent, {struct_parent_static: "struct_parent_static"});
		
		var _method_a = method(_struct_a, __TestSuitFunctionConstructorChildA);
		var _method_b = method(_struct_b, __TestSuitFunctionConstructorChildB);
		var _method_c = method(_struct_c, __TestSuitFunctionConstructorChildC);
		var _method_parent = method(_struct_parent, __TestSuitFunctionConstructorParent);
		
		var _new_static = {new_static : "new_static"};
		
		
		
		var _global_output_a = new __TestSuitFunctionConstructorChildA();
		var _global_output_b = new __TestSuitFunctionConstructorChildB();
		var _global_output_c = new __TestSuitFunctionConstructorChildC();
		var _global_output_parent = new __TestSuitFunctionConstructorParent();
		
		#region GMLC Global A
		assert_equals(
			instanceof(_global_output_a),
			"__TestSuitFunctionConstructorChildA",
			"instanceof() failing on _global_output_a"
		)
		assert_true(
			is_instanceof(_global_output_a, __TestSuitFunctionConstructorChildA),
			"is_instanceof() failing on _global_output_a"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorChildA),
			"__TestSuitFunctionConstructorChildA",
			"script_get_name() not accurately getting the name for global __TestSuitFunctionConstructorChildA"
		)
		assert_equals(
			static_get(_global_output_a),
			static_get(__TestSuitFunctionConstructorChildA),
			"Static of _global_output_a != global __TestSuitFunctionConstructorChildA"
		)
		//check static write is working
		static_set(_global_output_a, _new_static);
		assert_equals(
			static_get(_global_output_a),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		#region GMLC Global B
		assert_equals(
			instanceof(_global_output_b),
			"__TestSuitFunctionConstructorChildB",
			"instanceof() failing on _global_output_b"
		)
		assert_true(
			is_instanceof(_global_output_c, __TestSuitFunctionConstructorChildB),
			"is_instanceof() failing on _global_output_b for B"
		)
		assert_true(
			is_instanceof(_global_output_c, __TestSuitFunctionConstructorParent),
			"is_instanceof() failing on _global_output_b for parent"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorChildB),
			"__TestSuitFunctionConstructorChildB",
			"script_get_name() not accurately getting the name for global __TestSuitFunctionConstructorChildB"
		)
		assert_equals(
			static_get(_global_output_b),
			static_get(__TestSuitFunctionConstructorChildB),
			"Static of _global_output_a != global __TestSuitFunctionConstructorChildB"
		)
		//check static write is working
		static_set(_global_output_b, _new_static);
		assert_equals(
			static_get(_global_output_b),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		#region GMLC Global C
		assert_equals(
			instanceof(_global_output_c),
			"__TestSuitFunctionConstructorChildC",
			"instanceof() failing on _global_output_c"
		)
		assert_true(
			is_instanceof(_global_output_c, __TestSuitFunctionConstructorChildC),
			"is_instanceof() failing on _global_output_c for C"
		)
		assert_true(
			is_instanceof(_global_output_c, __TestSuitFunctionConstructorChildB),
			"is_instanceof() failing on _global_output_c for B"
		)
		assert_true(
			is_instanceof(_global_output_c, __TestSuitFunctionConstructorParent),
			"is_instanceof() failing on _global_output_c for parent"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorChildC),
			"__TestSuitFunctionConstructorChildC",
			"script_get_name() not accurately getting the name for global __TestSuitFunctionConstructorChildC"
		)
		assert_equals(
			static_get(_global_output_c),
			static_get(__TestSuitFunctionConstructorChildC),
			"Static of _global_output_a != global __TestSuitFunctionConstructorChildC"
		)
		//check static write is working
		static_set(_global_output_c, _new_static);
		assert_equals(
			static_get(_global_output_c),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		#region GMLC Global Parent
		assert_equals(
			instanceof(_global_output_parent),
			"__TestSuitFunctionConstructorParent",
			"instanceof() failing on _global_output_parent"
		)
		assert_true(
			is_instanceof(_global_output_parent, __TestSuitFunctionConstructorParent),
			"is_instanceof() failing on _global_output_parent"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorParent),
			"__TestSuitFunctionConstructorParent",
			"script_get_name() not accurately getting the name for global __TestSuitFunctionConstructorParent"
		)
		assert_equals(
			static_get(_global_output_parent),
			static_get(__TestSuitFunctionConstructorParent),
			"Static of _global_output_a != global __TestSuitFunctionConstructorParent"
		)
		//check static write is working
		static_set(_global_output_parent, _new_static);
		assert_equals(
			static_get(_global_output_parent),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		var _method_output_a = new _method_a();
		var _method_output_b = new _method_b();
		var _method_output_c = new _method_c();
		var _method_output_parent = new _method_parent();
		
		#region GMLC Method Single A
		assert_equals(
			instanceof(_method_output_a),
			"__TestSuitFunctionConstructorChildA",
			"instanceof() failing on _method_output_a"
		)
		assert_true(
			is_instanceof(_method_output_a, __TestSuitFunctionConstructorChildA),
			"is_instanceof() failing on _method_output_a"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorChildA),
			"__TestSuitFunctionConstructorChildA",
			"script_get_name() not accurately getting the name for method __TestSuitFunctionConstructorChildA"
		)
		assert_equals(
			static_get(_method_output_a),
			static_get(__TestSuitFunctionConstructorChildA),
			"Static of _method_output_a != method __TestSuitFunctionConstructorChildA"
		)
		//check static write is working
		static_set(_method_output_a, _new_static);
		assert_equals(
			static_get(_method_output_a),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		#region GMLC Method Single B
		assert_equals(
			instanceof(_method_output_b),
			"__TestSuitFunctionConstructorChildB",
			"instanceof() failing on _method_output_b"
		)
		assert_true(
			is_instanceof(_method_output_c, __TestSuitFunctionConstructorChildB),
			"is_instanceof() failing on _method_output_b for B"
		)
		assert_true(
			is_instanceof(_method_output_c, __TestSuitFunctionConstructorParent),
			"is_instanceof() failing on _method_output_b for parent"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorChildB),
			"__TestSuitFunctionConstructorChildB",
			"script_get_name() not accurately getting the name for method __TestSuitFunctionConstructorChildB"
		)
		assert_equals(
			static_get(_method_output_b),
			static_get(__TestSuitFunctionConstructorChildB),
			"Static of _method_output_a != method __TestSuitFunctionConstructorChildB"
		)
		//check static write is working
		static_set(_method_output_b, _new_static);
		assert_equals(
			static_get(_method_output_b),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		#region GMLC Method Single C
		assert_equals(
			instanceof(_method_output_c),
			"__TestSuitFunctionConstructorChildC",
			"instanceof() failing on _method_output_c"
		)
		assert_true(
			is_instanceof(_method_output_c, __TestSuitFunctionConstructorChildC),
			"is_instanceof() failing on _method_output_c for C"
		)
		assert_true(
			is_instanceof(_method_output_c, __TestSuitFunctionConstructorChildB),
			"is_instanceof() failing on _method_output_c for B"
		)
		assert_true(
			is_instanceof(_method_output_c, __TestSuitFunctionConstructorParent),
			"is_instanceof() failing on _method_output_c for parent"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorChildC),
			"__TestSuitFunctionConstructorChildC",
			"script_get_name() not accurately getting the name for method __TestSuitFunctionConstructorChildC"
		)
		assert_equals(
			static_get(_method_output_c),
			static_get(__TestSuitFunctionConstructorChildC),
			"Static of _method_output_a != method __TestSuitFunctionConstructorChildC"
		)
		//check static write is working
		static_set(_method_output_c, _new_static);
		assert_equals(
			static_get(_method_output_c),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		#region GMLC Method Single Parent
		assert_equals(
			instanceof(_method_output_parent),
			"__TestSuitFunctionConstructorParent",
			"instanceof() failing on _method_output_parent"
		)
		assert_true(
			is_instanceof(_method_output_parent, __TestSuitFunctionConstructorParent),
			"is_instanceof() failing on _method_output_parent"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorParent),
			"__TestSuitFunctionConstructorParent",
			"script_get_name() not accurately getting the name for method __TestSuitFunctionConstructorParent"
		)
		assert_equals(
			static_get(_method_output_parent),
			static_get(__TestSuitFunctionConstructorParent),
			"Static of _method_output_a != method __TestSuitFunctionConstructorParent"
		)
		//check static write is working
		static_set(_method_output_parent, _new_static);
		assert_equals(
			static_get(_method_output_parent),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		var _global_output_a = {}
			with _global_output_a script_execute(__TestSuitFunctionConstructorChildA);
		var _global_output_b = {}
			with _global_output_b script_execute(__TestSuitFunctionConstructorChildB);
		var _global_output_c = {}
			with _global_output_c script_execute(__TestSuitFunctionConstructorChildC);
		var _global_output_parent = {}
			with _global_output_parent script_execute(__TestSuitFunctionConstructorParent);
		
		#region GMLC Global A
		assert_equals(
			instanceof(_global_output_a),
			"__TestSuitFunctionConstructorChildA",
			"instanceof() failing on _global_output_a"
		)
		assert_true(
			is_instanceof(_global_output_a, __TestSuitFunctionConstructorChildA),
			"is_instanceof() failing on _global_output_a"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorChildA),
			"__TestSuitFunctionConstructorChildA",
			"script_get_name() not accurately getting the name for global __TestSuitFunctionConstructorChildA"
		)
		assert_equals(
			static_get(_global_output_a),
			static_get(__TestSuitFunctionConstructorChildA),
			"Static of _global_output_a != global __TestSuitFunctionConstructorChildA"
		)
		//check static write is working
		static_set(_global_output_a, _new_static);
		assert_equals(
			static_get(_global_output_a),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		#region GMLC Global B
		assert_equals(
			instanceof(_global_output_b),
			"__TestSuitFunctionConstructorChildB",
			"instanceof() failing on _global_output_b"
		)
		assert_true(
			is_instanceof(_global_output_c, __TestSuitFunctionConstructorChildB),
			"is_instanceof() failing on _global_output_b for B"
		)
		assert_true(
			is_instanceof(_global_output_c, __TestSuitFunctionConstructorParent),
			"is_instanceof() failing on _global_output_b for parent"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorChildB),
			"__TestSuitFunctionConstructorChildB",
			"script_get_name() not accurately getting the name for global __TestSuitFunctionConstructorChildB"
		)
		assert_equals(
			static_get(_global_output_b),
			static_get(__TestSuitFunctionConstructorChildB),
			"Static of _global_output_a != global __TestSuitFunctionConstructorChildB"
		)
		//check static write is working
		static_set(_global_output_b, _new_static);
		assert_equals(
			static_get(_global_output_b),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		#region GMLC Global C
		assert_equals(
			instanceof(_global_output_c),
			"__TestSuitFunctionConstructorChildC",
			"instanceof() failing on _global_output_c"
		)
		assert_true(
			is_instanceof(_global_output_c, __TestSuitFunctionConstructorChildC),
			"is_instanceof() failing on _global_output_c for C"
		)
		assert_true(
			is_instanceof(_global_output_c, __TestSuitFunctionConstructorChildB),
			"is_instanceof() failing on _global_output_c for B"
		)
		assert_true(
			is_instanceof(_global_output_c, __TestSuitFunctionConstructorParent),
			"is_instanceof() failing on _global_output_c for parent"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorChildC),
			"__TestSuitFunctionConstructorChildC",
			"script_get_name() not accurately getting the name for global __TestSuitFunctionConstructorChildC"
		)
		assert_equals(
			static_get(_global_output_c),
			static_get(__TestSuitFunctionConstructorChildC),
			"Static of _global_output_a != global __TestSuitFunctionConstructorChildC"
		)
		//check static write is working
		static_set(_global_output_c, _new_static);
		assert_equals(
			static_get(_global_output_c),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		#region GMLC Global Parent
		assert_equals(
			instanceof(_global_output_parent),
			"__TestSuitFunctionConstructorParent",
			"instanceof() failing on _global_output_parent"
		)
		assert_true(
			is_instanceof(_global_output_parent, __TestSuitFunctionConstructorParent),
			"is_instanceof() failing on _global_output_parent"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorParent),
			"__TestSuitFunctionConstructorParent",
			"script_get_name() not accurately getting the name for global __TestSuitFunctionConstructorParent"
		)
		assert_equals(
			static_get(_global_output_parent),
			static_get(__TestSuitFunctionConstructorParent),
			"Static of _global_output_a != global __TestSuitFunctionConstructorParent"
		)
		//check static write is working
		static_set(_global_output_parent, _new_static);
		assert_equals(
			static_get(_global_output_parent),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		var _method_output_a = {}
			with _method_output_a script_execute(_method_a);
		var _method_output_b = {}
			with _method_output_b script_execute(_method_b);
		var _method_output_c = {}
			with _method_output_c script_execute(_method_c);
		var _method_output_parent = {}
			with _method_output_parent script_execute(_method_parent);
		
		#region GMLC Method Single A
		assert_equals(
			instanceof(_method_output_a),
			"__TestSuitFunctionConstructorChildA",
			"instanceof() failing on _method_output_a"
		)
		assert_true(
			is_instanceof(_method_output_a, __TestSuitFunctionConstructorChildA),
			"is_instanceof() failing on _method_output_a"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorChildA),
			"__TestSuitFunctionConstructorChildA",
			"script_get_name() not accurately getting the name for method __TestSuitFunctionConstructorChildA"
		)
		assert_equals(
			static_get(_method_output_a),
			static_get(__TestSuitFunctionConstructorChildA),
			"Static of _method_output_a != method __TestSuitFunctionConstructorChildA"
		)
		//check static write is working
		static_set(_method_output_a, _new_static);
		assert_equals(
			static_get(_method_output_a),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		#region GMLC Method Single B
		assert_equals(
			instanceof(_method_output_b),
			"__TestSuitFunctionConstructorChildB",
			"instanceof() failing on _method_output_b"
		)
		assert_true(
			is_instanceof(_method_output_c, __TestSuitFunctionConstructorChildB),
			"is_instanceof() failing on _method_output_b for B"
		)
		assert_true(
			is_instanceof(_method_output_c, __TestSuitFunctionConstructorParent),
			"is_instanceof() failing on _method_output_b for parent"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorChildB),
			"__TestSuitFunctionConstructorChildB",
			"script_get_name() not accurately getting the name for method __TestSuitFunctionConstructorChildB"
		)
		assert_equals(
			static_get(_method_output_b),
			static_get(__TestSuitFunctionConstructorChildB),
			"Static of _method_output_a != method __TestSuitFunctionConstructorChildB"
		)
		//check static write is working
		static_set(_method_output_b, _new_static);
		assert_equals(
			static_get(_method_output_b),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		#region GMLC Method Single C
		assert_equals(
			instanceof(_method_output_c),
			"__TestSuitFunctionConstructorChildC",
			"instanceof() failing on _method_output_c"
		)
		assert_true(
			is_instanceof(_method_output_c, __TestSuitFunctionConstructorChildC),
			"is_instanceof() failing on _method_output_c for C"
		)
		assert_true(
			is_instanceof(_method_output_c, __TestSuitFunctionConstructorChildB),
			"is_instanceof() failing on _method_output_c for B"
		)
		assert_true(
			is_instanceof(_method_output_c, __TestSuitFunctionConstructorParent),
			"is_instanceof() failing on _method_output_c for parent"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorChildC),
			"__TestSuitFunctionConstructorChildC",
			"script_get_name() not accurately getting the name for method __TestSuitFunctionConstructorChildC"
		)
		assert_equals(
			static_get(_method_output_c),
			static_get(__TestSuitFunctionConstructorChildC),
			"Static of _method_output_a != method __TestSuitFunctionConstructorChildC"
		)
		//check static write is working
		static_set(_method_output_c, _new_static);
		assert_equals(
			static_get(_method_output_c),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		
		#region GMLC Method Single Parent
		assert_equals(
			instanceof(_method_output_parent),
			"__TestSuitFunctionConstructorParent",
			"instanceof() failing on _method_output_parent"
		)
		assert_true(
			is_instanceof(_method_output_parent, __TestSuitFunctionConstructorParent),
			"is_instanceof() failing on _method_output_parent"
		)
		assert_equals(
			script_get_name(__TestSuitFunctionConstructorParent),
			"__TestSuitFunctionConstructorParent",
			"script_get_name() not accurately getting the name for method __TestSuitFunctionConstructorParent"
		)
		assert_equals(
			static_get(_method_output_parent),
			static_get(__TestSuitFunctionConstructorParent),
			"Static of _method_output_a != method __TestSuitFunctionConstructorParent"
		)
		//check static write is working
		static_set(_method_output_parent, _new_static);
		assert_equals(
			static_get(_method_output_parent),
			_new_static,
			"static_set or static_get improperly handling static handling."
		)
		#endregion
		//')
	});
	
}

function __TestSuitFunctionConstructorParent() constructor {
	static parent_static_exist = true;
	parent_local_exist = true;
}