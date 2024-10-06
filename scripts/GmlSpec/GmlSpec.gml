function GmlSpec() {
	//This struct was created by taking `GmlSpec.xml` from the path `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-<Runtime>`
	//Then running it through the following webpage converting tool. `https://jsonformatter.org/xml-to-json`
	
	static __GmlSpec = undefined;
	
	if (__GmlSpec == undefined) {
		var _buf = buffer_load("GmlSpec.json");
		var _str = buffer_read(_buf, buffer_string);
		buffer_delete(_buf);
		
		__GmlSpec = json_parse(_str);
	}
	
	/*
	repeat (10) log("\n")
	var _arr = __GmlSpec.GameMakerLanguageSpec.Variables.Variable;
	var _i=0; repeat(array_length(_arr)) {
		var _func = _arr[_i];
		
		if (!_func.Instance) {
			log(_func.Name)
		}
		
	_i+=1;}//end repeat loop
	repeat (10) log("\n")
	//*/
	
	return __GmlSpec;
	
}
//GmlSpec();


