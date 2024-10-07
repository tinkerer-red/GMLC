function compile_and_execute(_string) {
	static tokenizer = new GML_Tokenizer();
	tokenizer.initialize(_string);
	var tokens = tokenizer.parseAll();
	
	static preprocessor = new GML_PreProcessor();
	preprocessor.initialize(tokens);
	var preprocessedTokens = preprocessor.parseAll();
	
	static parser = new GML_Parser();
	parser.initialize(preprocessedTokens);
	var ast = parser.parseAll();
	
	static postprocessor = new GML_PostProcessor();
	postprocessor.initialize(ast);
	var ast = postprocessor.parseAll();
	
	//static optimizer = new GML_Optimizer();
	//optimizer.initialize(ast);
	//var ast = optimizer.parseAll();
	
	//log(json(ast))
	
	var _program = compileProgram(ast);
	//pprint(_program)
	
	//GC_START
	var _r = executeProgram(_program);
	//GC_LOG
	
	return _r;
}
