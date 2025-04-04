gmlc = new GMLC_Env();

show_debug_overlay(true)

log("\n\n\n")

#region Interpreter Unit Tests
function run_interpreter_test(description, input, expectedReturn=undefined) {
	
	with (gmlc) {
		var tokenizer = new GMLC_Gen_0_Tokenizer();
		tokenizer.initialize(input);
		tokenizer.parseAsync(method(
		{description, expectedReturn},
		function(tokens) {
		
			pprint(tokens)
		
			var preprocessor = new GMLC_Gen_1_PreProcessor();
			preprocessor.initialize(tokens);
			preprocessor.parseAsync(method(
			self,
			function(preprocessedTokens) {
			
				log($"Attempting Interpreter Test :: {description}")
			
				var parser = new GMLC_Gen_2_Parser();
				parser.initialize(preprocessedTokens);
				var ast = parser.parseAll();
			
				var postprocessor = new GMLC_Gen_3_PostProcessor();
				postprocessor.initialize(ast);
				var ast = postprocessor.parseAll();
			
				log("\n\n\n")
				log(" :: Default AST :: ")
				pprint(ast)
				log("\n\n\n")
			
				//var optimizer = new GMLC_Gen_4_Optimizer();
				//optimizer.initialize(ast);
				//var ast = optimizer.parseAll();
			
				//log("\n\n\n")
				//log(" :: Optimized AST :: ")
				//pprint(ast)
				//log("\n\n\n")
			
				var _program = compileProgram(ast);
				var outputReturn = executeProgram(_program)
			
				expectedReturn = (is_callable(expectedReturn)) ? expectedReturn() : expectedReturn;
			
				var _same = __compare_results(description, outputReturn, expectedReturn);
				if (!_same) {
					log($"AST ::\n{json_stringify(ast, true)}\n")
				}
			
			}));
		}));
	}
	
	
	//var _program = undefined;
	////try {
	//	//log($"AST ::\n{json_stringify(ast, true)}\n")
	//	var _program = compileProgram(ast);
	//	var outputReturn = executeProgram(_program)
	////}catch(e) {
	////	log($"AST ::\n{json_stringify(ast, true)}\n")
	////	log(e)
	////	return;
	////}
	//
	//expectedReturn = (is_callable(expectedReturn)) ? expectedReturn() : expectedReturn;
	//
	////if (expectedModule != undefined) __compare_results(description, outputModule, expectedModule);
	////log(json_stringify(outputReturn, true))
	////log(json_stringify(expectedReturn, true))
	//var _same = __compare_results(description, outputReturn, expectedReturn);
	//if (!_same) {
	//	log($"AST ::\n{json_stringify(ast, true)}\n")
	//}
}
function run_all_interpreter_tests() {
log("~~~~~ Interpreter Unit Tests ~~~~~\n");
var _s = get_timer()

run_interpreter_test("Boop",
@'
#macro defer for (;; {
#macro after ; break; })

log("me zeroth")
defer {
  log("me second")
} after {
  log("me first")
}
',
function(){
	return undefined;
}
);

return;

#region HIDE

run_interpreter_test("Boop",
@'
var _func = function(){ static __struct = { x: 0 } }
_func()
_func.__struct.x = 0
assert_equals(_func.__struct.x,   0, "Static external variable get failed.");
assert_equals(_func.__struct.x++, 0, "Static external variable PlusPlus Suffix failed.");
assert_equals(++_func.__struct.x, 2, "Static external variable PlusPlus Prefix failed.");
assert_equals(_func.__struct.x--, 2, "Static external variable MinusMinus Suffix failed.");
assert_equals(--_func.__struct.x, 0, "Static external variable MinusMinus Prefix failed.");
assert_equals(_func.__struct.x,   0, "Static external variable get failed.");
assert_struct_equals(static_get(_func), { __struct: {x : 0} }, "Static handles are not the same")
assert_equals(static_get(_func).__struct, _func.__struct, "Static handles are not the same")
',
function(){
	foo = function() constructor {
		bar = {}
	}
	
	var a0 = new foo();
	
	delete a0.bar;
	
	return a0.bar // should equal undefined
}
);
run_interpreter_test("Boop",
@'
foo = function() constructor {
	bar = {}
}

var a0 = new foo();

delete a0.bar;

return a0.bar // should equal undefined
',
function(){
	foo = function() constructor {
		bar = {}
	}
	
	var a0 = new foo();
	
	delete a0.bar;
	
	return a0.bar // should equal undefined
}
);
run_interpreter_test("Parenting Constructors inherited arguments and Static structs",
@'
function __GMLC_a(arg0) constructor {
	static overwrite = "A Overwrite"
	static aStatic = "This is A`s Static"
	aInstance = "This is A`s Instance"
	argumentChain = arg0;
	localChain = 0;
}
function __GMLC_b(arg0) : __GMLC_a(arg0+1) constructor {
	static overwrite = "B Overwrite"
	static bStatic = "This is B`s Static"
	bInstance = "This is B`s Instance"
	localChain++;
}
function __GMLC_c(arg0) : __GMLC_b(arg0+1) constructor {
	static overwrite = "C Overwrite"
	static cStatic = "This is C`s Static"
	cInstance = "This is C`s Instance"
	localChain++;
}
	
var _a = new a(1);
var _b = new b(2);
var _c = new c(3);
	
return string(_c);
',
function(){
	function __GML_a(arg0) constructor {
		static overwrite = "A Overwrite"
		static aStatic = "This is A`s Static"
		aInstance = "This is A`s Instance"
		argumentChain = arg0;
		localChain = 0;
	}
	function __GML_b(arg0) : __GML_a(arg0+1) constructor {
		static overwrite = "B Overwrite"
		static bStatic = "This is B`s Static"
		bInstance = "This is B`s Instance"
		localChain++;
	}
	function __GML_c(arg0) : __GML_b(arg0+1) constructor {
		static overwrite = "C Overwrite"
		static cStatic = "This is C`s Static"
		cInstance = "This is C`s Instance"
		localChain++;
	}
	
	var _a = new __GML_a(1);
	var _b = new __GML_b(2);
	var _c = new __GML_c(3);
	
	return string(_c);
}
);


//*
run_interpreter_test("Boop",
@'
var _constructor = function() constructor { }

var _result = array_create_ext(10, method( { const: _constructor }, function() { return new const(); }));
assert_array_length(_result, 10, "array_create_ext should create array with correct size (constructor)");
',
function(){
	var _constructor = function() constructor { }
	
	var _result = array_create_ext(10, method( { const: _constructor }, function() { return new const(); }));
	assert_array_length(_result, 10, "array_create_ext should create array with correct size (constructor)");
}
);


#region complex expression evaluation
run_interpreter_test("complex expression evaluation", 
@'x = 2;
y = 4;
var result = ((x + y) * (x - y)) / 2;
return result',
function(){
	x = 2;
	y = 4;
	var result = ((x + y) * (x - y)) / 2;
	return result	
}
)
#endregion

#region Varriable Apply With Postfix
run_interpreter_test("Varriable Apply With Postfix", 
@'x=1;
x++
return x;',
function(){
	x=1;
	x++
	return x;
}
)
#endregion
#region Instance Var Apply
run_interpreter_test("Instance Var Apply", 
@'y = 1;
return y',
function(){
	y = 1;
	return y	
}
)
#endregion
#region Optimize simple constant expressions
run_interpreter_test("1 + 1;", 
@'x = 1+1
return x',
function(){
	x = 1+1
	return x
}
)
#endregion
#region parseAssignmentExpression
run_interpreter_test("parseAssignmentExpression", 
@'y = 1;
x = y + 1;
return x;',
function(){
	y = 1;
	x = y + 1;
	return x;
}
)
#endregion
#region parseLogicalOrExpression
run_interpreter_test("parseLogicalOrExpression", 
@'var _x = 2,
_y = 4,
_z = _x || _y;
return _z;',
function(){
	var _x = 2,
	_y = 4,
	_z = _x || _y;
	return _z;
}
)
#endregion
#region parseLogicalAndExpression
run_interpreter_test("parseLogicalAndExpression", 
@'var _x = 2,
_y = 4,
_z = _x && _y;
return _z;',
function(){
	var _x = 2,
	_y = 4,
	_z = _x && _y;
	return _z;
}
)
#endregion
#region parseBitwsieOrExpression
run_interpreter_test("parseBitwsieOrExpression", 
@'var _x = 2,
_y = 4,
_z = _x | _y;
return _z;',
function(){
	var _x = 2,
	_y = 4,
	_z = _x | _y;
	return _z;
}
)
#endregion
#region parseBitwsieXorExpression
run_interpreter_test("parseBitwsieXorExpression", 
@'var _x = 2,
_y = 4,
_z = _x ^ _y;
return _z;',
function(){
	var _x = 2,
	_y = 4,
	_z = _x ^ _y;
	return _z;
}
)
#endregion
#region parseBitwsieAndExpression
run_interpreter_test("parseBitwsieAndExpression", 
@'var _x = 2,
_y = 4,
_z = _x & _y;
return _z;',
function(){
	var _x = 2,
	_y = 4,
	_z = _x & _y;
	return _z;
}
)
#endregion
#region parseEqualityExpression
run_interpreter_test("parseEqualityExpression", 
@'var _x = 2,
_y = 4,
_z = _x == _y;
return _z;',
function(){
	var _x = 2,
	_y = 4,
	_z = _x == _y;
	return _z;
}
)
#endregion
#region parseRelationalExpression
run_interpreter_test("parseRelationalExpression", 
@'var _x = 2,
_y = 4,
_z = _x < _y;
return _z;',
function(){
	var _x = 2,
	_y = 4,
	_z = _x < _y;
	return _z;
}
)
#endregion
#region parseShiftExpression
run_interpreter_test("parseShiftExpression", 
@'var _x = 2,
_y = 4,
_z = _x >> _y;
return _z;',
function(){
	var _x = 2,
	_y = 4,
	_z = _x >> _y;
	return _z;
}
)
#endregion
#region parseAdditiveExpression
run_interpreter_test("parseAdditiveExpression", 
@'var _x = 2,
_y = 4,
_z = _x + _y;
return _z;',
function(){
	var _x = 2,
	_y = 4,
	_z = _x + _y;
	return _z;
}
)
#endregion
#region parseMultiplicativeExpression
run_interpreter_test("parseMultiplicativeExpression", 
@'var _x = 2,
_y = 4,
_z = _x * _y;
return _z;',
function(){
	var _x = 2,
	_y = 4,
	_z = _x * _y;
	return _z;
}
)
#endregion
#region parseUnaryExpression
run_interpreter_test("parseUnaryExpression", 
@'var _x = 1;
var _y = !_x;
return _y',
function(){
	var _x = 1;
	var _y = !_x;
	return _y
}
)
#endregion
#region parsePostfixExpression
run_interpreter_test("parsePostfixExpression", 
@'var _x=0;
	_x++;
	return _x++;',
function(){
	var _x=0;
	_x++;
	return _x++;
}
)
#endregion
#region Advanced Expression
run_interpreter_test("Advanced Expression", 
@'var a = 1,
b = a++,
c = a++,
d = a++,
e = a++,
f = a++,
g = a++,
h = a + b * c - (d & e % f div g)
return h',
function(){
	var a = 1,
	b = a++,
	c = a++,
	d = a++,
	e = a++,
	f = a++,
	g = a++,
	h = a + b * c - (d & e % f div g)
	return h
}
)
#endregion
#region confusingPostfixExpression
run_interpreter_test("confusingPostfixExpression", 
@'var _a = 0
var _b = 1
var _c = _a+++_b;
return _a; //should be 1',
function(){
	var _a = 0
	var _b = 1
	var _c = _a+++_b;
	return _a; //should be 1
}
)
#endregion

#region Arrays
#region 1. Array Creation and Direct Assignment
run_interpreter_test("Array Creation and Direct Assignment",
@'var arr = [1, 2, 3];
arr[0] = 10;
return arr[0];',
function(){
  var arr = [1, 2, 3];
  arr[0] = 10;
  return arr[0];
}
)

#endregion
#region 2. Array Modification Through Function
run_interpreter_test("Array Modification Through Function",
@'var arr = [1, 7, 5, 6];
array_sort(arr, true);
return arr[1];',
function(){
	var arr = [1, 7, 5, 6];
	array_sort(arr, true);
	return arr[1];
}
)

#endregion
#region 3. Array Element Increment
//run_interpreter_test("Array Element Increment",
//@'var arr = [10, 20, 30];
//arr[2]++;
//return arr[2];',
//function(){
//  var arr = [10, 20, 30];
//  arr[2]++;
//  return arr[2];
//}
//)
#endregion
#region 4. Dynamic Array Creation with Loop
run_interpreter_test("Dynamic Array Creation with Loop",
@'var arr = [];
for (var i = 0; i < 5; i++) {
  arr[i] = i * 2;
}
return arr[3];',
function() {
	var arr = [];
	for (var i = 0; i < 5; i++) {
		arr[i] = i * 2;
	}
	return arr[3];
}
)
#endregion
#region 5. Array Access and Function Call
run_interpreter_test("Array Access and Function Call",
@'var arr = [100, 200, 300];
var result = string(arr[1]);
return result;',
function(){
	var arr = [100, 200, 300];
	var result = string(arr[1]);
	return result;
}
)
#endregion
#endregion


//*/
#endregion
//*
#region Factorial Test
run_interpreter_test("Factorial Test",
@'// compute the factorial of n
function factorial(n) {
  if (n <= 1) {
	return 1;
  }
  return n * factorial(n - 1)
}

factorial(1) // result: 1
factorial(2) // result: 2
factorial(3) // result: 6
factorial(4) // result: 24
factorial(5) // result: 120
return factorial(6) // result: 720',
function(){
	// compute the factorial of n
	factorial = function (n) {
	  if (n <= 1) {
		return 1;
	  }
	  return n * factorial(n - 1)
	}
	
	factorial(1) // result: 1
	factorial(2) // result: 2
	factorial(3) // result: 6
	factorial(4) // result: 24
	factorial(5) // result: 120
	return factorial(6) // result: 720
})
#endregion


#region parsePreffixExpression
run_interpreter_test("parsePreffixExpression", 
@'var _x=0;
--_x;
return --_x;',
function(){
	var _x=0;
	--_x;
	return --_x
}
)
#endregion

log($"Finished compiling and executing tests in {(get_timer() - _s)/1_000}")
//*/
}
run_all_interpreter_tests();
#endregion

log("\n\n\n")

function attempt_file_parsing(_fname) {
	log($"Attempting to execute file: {_fname}")
	var _str = file_read_all_text(_fname);
	
	//log(_str)
	
	var tokenizer = new GMLC_Gen_0_Tokenizer();
	tokenizer.initialize(_str);
	var tokens = tokenizer.parseAll();
	tokenizer.cleanup();
	
	var _success = true;
	var _i=0; repeat(array_length(tokens)){
		if (tokens[_i].type == "Illegal") {
			log($"Token error: {tokens[_i]}");
			_success = false;
		}
	}
	if (!_success) {
		log("Tokenizer Failed")
		return;
	}
	log("Tokenizer Completed")
	//*
	var preprocessor = new GMLC_Gen_1_PreProcessor();
	preprocessor.initialize(tokens);
	var tokens = preprocessor.parseAll();
	
	log("PreProcessor Completed")
	
	var parser = new GMLC_Gen_2_Parser();
	parser.initialize(tokens);
	var ast = parser.parseAll();
	
	log("Parser Completed")
	
	var postprocessor = new GMLC_Gen_3_PostProcessor();
	postprocessor.initialize(ast);
	var optimizedAST = postprocessor.parseAll();
	
	log("Post Processor Completed")
	
	var interpreter = new GML_Interpreter();
	interpreter.initialize(optimizedAST);
	var outputModule = interpreter.parseAll();
	
	log("Interpreter Completed")
	log(json_stringify(outputModule, true))
	log(string_repeat("\n", 5))
	
	var outputReturn = outputModule.execute();
	
	log("Execution Completed")
	
	log("Successfully Completed")
	//*/
	
}
function compile_file(_fname) {
	log($"Attempting to execute file: {_fname}")
	var _str = file_read_all_text(_fname);
	
	//log(_str)
	
	var tokenizer = new GMLC_Gen_0_Tokenizer();
	tokenizer.initialize(_str);
	var tokens = tokenizer.parseAll();
	tokenizer.cleanup();
	
	var _success = true;
	var _i=0; repeat(array_length(tokens)){
		if (tokens[_i].type == "Illegal") {
			log($"Token error: {tokens[_i]}");
			_success = false;
		}
	}
	if (!_success) {
		log("Tokenizer Failed")
		return;
	}
	log("Tokenizer Completed")
	//*
	var preprocessor = new GMLC_Gen_1_PreProcessor();
	preprocessor.initialize(tokens);
	var tokens = preprocessor.parseAll();
	
	log("PreProcessor Completed")
	
	var parser = new GMLC_Gen_2_Parser();
	parser.initialize(tokens);
	var ast = parser.parseAll();
	
	log("Parser Completed")
	
	var converter = new GMLC_GM1_4_Converter();
	converter.initialize(ast);
	var ast = converter.parseAll();
	
	log("Converter Completed")
	
	var postprocessor = new GMLC_Gen_3_PostProcessor();
	postprocessor.initialize(ast);
	var optimizedAST = postprocessor.parseAll();
	
	log("Post Processor Completed")
	
	var interpreter = new GML_Interpreter();
	interpreter.initialize(optimizedAST);
	var outputModule = interpreter.parseAll();
	
	log("Interpreter Completed")
	log(json_stringify(outputModule, true))
	log(string_repeat("\n", 5))
	
	
	return method(outputModule.GlobalVar[$ "GMLC@'osg"], outputModule.GlobalVar[$ "GMLC@'osg"].execute);
	
	
	var outputReturn = outputModule.execute();
	
	log("Execution Completed")
	
	log("Successfully Completed")
	//*/
	
}
//!sorted by file size!
//attempt_file_parsing("test.gml")
//attempt_file_parsing("PsychoDelph.gml")
//attempt_file_parsing("Chance.gml")
//attempt_file_parsing("Surgeon_.gml")
//attempt_file_parsing("Nallebeorn.gml")
//attempt_file_parsing("Threef - Flappy Souls.gml")
//attempt_file_parsing("Coded Games.gml")
//attempt_file_parsing("Matthew Brown.gml")
//attempt_file_parsing("Galladhan.gml")
//attempt_file_parsing("shadowspear1 - shadowspear1s One-Script Tower Defense Game.gml")
//attempt_file_parsing("Nocturne - OSG Asteroids.gml")
//attempt_file_parsing("YellowAfterLife - Pool of Doom.gml")
//attempt_file_parsing("JimmyBG - Forest Fox.gml")
//attempt_file_parsing("Alice - juegOS.gml")
//attempt_file_parsing("Mike - Mega Super Smash Track Buggy Racer.gml")

//game_end()


//PsychoDelph = compile_file("PsychoDelph.gml");
run_game = false;

/*
[]; // output: Constant array { value:[], type: __GMLC_NodeType.Literal, scope:"Const" }
[0, 1, 2]; // output: Constant array { value:[0,1,2], type: __GMLC_NodeType.Literal, scope:"Const" }
[identifier, "string", variable_get_hash("FunctionReturn")]; // output: NON-constant array which we will compile as a function call using __NewGMLArray(identifier, "string", variable_get_hash("FunctionReturn")) which can be optimized by the postprocessor

var _struct = {}; // output: { value:{}, type: __GMLC_NodeType.Literal, scope:"Const" }
var _struct = {one: 1, two: 2, three: 3}; // output: { value:{one: 1, two: 2, three: 3}, type: __GMLC_NodeType.Literal, scope:"Const" }
var _struct = {"one": 1, "two": 2, "three": 3}; // output: { value:{one: 1, two: 2, three: 3}, type: __GMLC_NodeType.Literal, scope:"Const" }
var _value = 1; var _struct = {val: _value}; // output: NON-constant Struct, which we will compile as a function call using __NewGMLStruct("val", _value)
var value = 2; var _struct = {value}; // output: NON-constant Struct, which we will compile as a function call using __NewGMLStruct("value", value)
var three = 3; var _struct = {one: 1, two: 2, three}; // output: NON-constant Struct, which we will compile as a function call using __NewGMLStruct("one", 1, "two", 2, "three", three)


