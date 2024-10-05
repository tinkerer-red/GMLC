function BasicConstructorTestSuit() : TestSuite() constructor {
	
	//addFact("constructor test #1", function() {
	//	var _r = compile_and_execute(@'
	//	return { aInstance : "This is A`s Instance", cInstance : "This is C`s Instance", argumentChain : 3, localChain : 2, bInstance : "This is B`s Instance" }
	//	')
	//	assert_struct_equals(_r, { aInstance : "This is A`s Instance", cInstance : "This is C`s Instance", argumentChain : 3, localChain : 2, bInstance : "This is B`s Instance" })
	//})
	
	addFact("constructor test #1", function() {
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
		
		log("Newing A")
		var _a = new a(1);
		
		//self
		var _struct = _a;
		var _expected = { aInstance : "This is A`s Instance", argumentChain : 1, localChain : 0 }
		assert_struct_equals(_struct, _expected, "A`s Structs are not equal")
		//A`s statics
		var _struct = static_get(_a)
		var _expected = { overwrite : "A Overwrite", aStatic : "This is A`s Static" }
		assert_struct_equals(_struct, _expected, "A`s Static Structs are not equal")
		
		log("Newing B")
		var _b = new b(1);
		
		//self
		var _struct = _b;
		var _expected = { aInstance : "This is A`s Instance", argumentChain : 2, localChain : 1, bInstance : "This is B`s Instance" }
		assert_struct_equals(_struct, _expected, "B`s Structs are not equal")
		//B`s statics
		var _struct = static_get(_b)
		var _expected = { overwrite : "B Overwrite", bStatic : "This is B`s Static" }
		assert_struct_equals(_struct, _expected, "B`s Static Structs are not equal")
		//A`s statics
		var _struct = static_get(static_get(_b))
		var _expected = { overwrite : "A Overwrite", aStatic : "This is A`s Static" }
		assert_struct_equals(_struct, _expected, "B`s 2xStatic`s Structs are not equal to A`s")
		
		log("Newing C")
		var _c = new c(1);
		log(_c)
		log(static_get(_c))
		
		//self
		var _struct = _c;
		var _expected = { aInstance : "This is A`s Instance", cInstance : "This is C`s Instance", argumentChain : 3, localChain : 2, bInstance : "This is B`s Instance" }
		assert_struct_equals(_struct, _expected, "C`s Structs are not equal")
		//C`s statics
		var _struct = static_get(_c)
		var _expected = { overwrite : "C Overwrite", cStatic : "This is C`s Static" }
		assert_struct_equals(_struct, _expected, "C`s Static Structs are not equal")
		//B`s statics
		var _struct = static_get(static_get(_c))
		var _expected = { overwrite : "B Overwrite", bStatic : "This is B`s Static" }
		assert_struct_equals(_struct, _expected, "C`s 2xStatic`s Structs are not equal to B`s")
		//A`s statics
		var _struct = static_get(static_get(static_get(_c)))
		var _expected = { overwrite : "A Overwrite", aStatic : "This is A`s Static" }
		assert_struct_equals(_struct, _expected, "C`s 3xStatic`s Structs are not equal to A`s")
		')
	});
	
	
}
