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
	
	return __GmlSpec;
	
}