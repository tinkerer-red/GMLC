#macro GM_RESOURCE_VERSION "1.0"

//Base Asset
function GMAsset() constructor {
	
	static importString = function(_string){
		var _struct = json_parse(_string);
		
		if (_struct.resourceType != resourceType) {
			throw $"\nImported string is not a valid {resourceType} json!\nType was :: {_struct.resourceType} ::"
		}
		
		__import(_struct);
		
	}
	static exportString = function(){
		//cache our old 
		var _struct = __export();
		
		var _str = json_stringify(_struct, true);
		
		return _str;
	}
}

//Project
function GMProject() : GMAsset() constructor {
	self[$ "$GMProject"] = "";
	self[$ "%Name"] = ""; //GameName
	resourceType = "GMProject";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //GameName
	
	AudioGroups = [ /* GMAudioGroup */ ];
	configs = {
		children: [ /* {"children":[],"name":"NewConfig1",} */ ],
		name: "Default",
	};
	defaultScriptType = 1;
	Folders = [ /* GMFolder */ ];
	IncludedFiles = [ /* GMIncludedFile */ ];
	isEcma = false;
	LibraryEmitters = [];
	MetaData = {
		IDEVersion: "2024.4.1.152",
	};
	resources = [ /* {id: {name: "obj_gml_compiler_new", path: "objects/obj_gml_compiler_new/obj_gml_compiler_new.yy"} }, */ ];
	RoomOrderNodes = [ /* {roomId: {name: "Room1", path: "rooms/Room1/Room1.yy"} }, */ ];
	templateType = "game";
	TextureGroups = [ /* GMTextureGroup */ ];
	
	//the following does not get exported
	Imports = []; /* {id: "Multiprocessing", namespace: "MP", loadGlobally: false, dependencies: ["Scribble"]} */
	GlobalVar = {};
	MacroVar  = {};
	EnumVar   = {};
	
	static __import = function(_struct){
		
	}
	static __export = function(){
		
	}
	static importAsset = function(_asset){
		
	}
	static exportAsset = function(){
		
	}
	
}

//Anim Curves
function GMAnimCurve() : GMAsset() constructor {
	resourceType = "GMAnimCurve";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = "AnimationCurve1"; //name
	channels = []; //array of channels
	self[$ "function"] = animcurvetype_linear; //the smoothing type
	
	static __import = function(_struct){
		
		name = _struct.name;
		self[$ "function"] = _struct[$ "function"];
		
		array_resize(channels, array_length(_struct.channels));
		var _i=0; repeat(array_length(channels)) {
			var _channel = channels[_i] ?? new GMAnimCurveChannel();
			
			_channel.__import(_struct.channels[_i]);
			
			channels[_i] = _channel;
			
		_i+=1;}//end repeat loop
		
	}
	static __export = function(){
		var _struct = {};
		
		_struct.name = name;
		_struct[$ "function"] = self[$ "function"];
		
		_struct.channels = array_create(array_length(channels), undefined);
		var _i=0; repeat(array_length(channels)) {
			
			_struct.channels[_i] = channels[_i].__export();
			
		_i+=1;}//end repeat loop
		
		return _struct;
	}
	static importAsset = function(_asset){
		var _struct = animcurve_get(_asset);
		
		name = _struct.name;
		self[$ "function"] = _struct.channels[0].type;
		
		array_resize(channels, array_length(_struct.channels));
		var _i=0; repeat(array_length(channels)) {
			var _channel = channels[_i] ?? new GMAnimCurveChannel();
			_channel.importAsset(_struct.channels[_i]);
			channels[_i] = _channel;
		_i+=1;}//end repeat loop
	}
	static exportAsset = function(){
		if (myAsset != undefined) {
			cleanUp();
		}
		
		var _ac = animcurve_create();
		_ac.name = name;
		
		array_resize(_ac.channels, array_length(channels));
		var _i=0; repeat(array_length(channels)) {
			_ac.channels[_i] = channels[_i].exportAsset();
			_ac.channels[_i].type = self[$ "function"];
			//_ac.channels[_i].iterations = 16; //this is not a value saved in the project directory so we'll default to 16, a newly created anim curve defaults to 8 though.
		_i+=1;}//end repeat loop
		
		myAsset = _ac;
		
		return _ac;
	}
}
function GMAnimCurveChannel() : GMAsset() constructor {
	resourceType = "GMAnimCurveChannel";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name    = "curve1";
	colour  = 4290799884;
	points  = [];
	visible = true;
	
	static __import = function(_struct){
		
		name = _struct.name;
		colour = _struct.colour;
		visible = _struct.visible;
		
		array_resize(points, array_length(_struct.points));
		var _i=0; repeat(array_length(points)) {
			var _point = points[_i] ?? new GMAnimCurveChannelPoint();
			
			_point.__import(_struct.points[_i]);
			
		_i+=1;}//end repeat loop
		
	}
	static __export = function(){
		var _struct = {};
		
		_struct.name = name;
		_struct.colour = colour;
		_struct.visible = visible;
		
		_struct.points = array_create(array_length(points), undefined);
		var _i=0; repeat(array_length(channels)) {
			
			_struct.points[_i] = points[_i].__export();
			
		_i+=1;}//end repeat loop
		
		return _struct;
	}
	static importAsset = function(_asset){
		var _struct = animcurve_get(_asset);
		
		name = _struct.name;
		
		array_resize(points, array_length(_struct.points));
		var _i=0; repeat(array_length(points)) {
			var _point = points[_i] ?? new GMAnimCurveChannelPoint();
			_point.importAsset(_struct.points[_i]);
			points[_i] = _point;
		_i+=1;}//end repeat loop
	}
	static exportAsset = function(){
		var _channel = animcurve_channel_new();
		_channel.name = name;
		_channel.type = animcurvetype_linear; // this actually gets set by GMAnimCurve because thats where the smoothing function is stored, we just default to linear.
		_channel.iterations = 16; //this is not a value saved in the project directory so we'll default to 16, a newly created anim curve defaults to 8 though.
		
		array_resize(_channel.points, array_length(points))
		var _i=0; repeat(array_length(points)) {
			_channel.points[_i] = points[_i].exportAsset();
			
		_i+=1;}//end repeat loop
		
	}
}
function GMAnimCurveChannelPoint() : GMAsset() constructor {
	resourceType = "GMAnimCurveChannelPoint";
	resourceVersion = GM_RESOURCE_VERSION;
	
	th0 = 0;
	th1 = 0;
	tv0 = 0;
	tv1 = 0;
	x = 0;
	y = 0;
	
	static __import = function(_struct){
		
		th0 = _struct.th0;
		th1 = _struct.th1;
		tv0 = _struct.tv0;
		tv1 = _struct.tv1;
		x = _struct.x;
		y = _struct.y;
		
	}
	static __export = function(){
		var _struct = {};
		
		_struct.th0 = th0;
		_struct.th1 = th1;
		_struct.tv0 = tv0;
		_struct.tv1 = tv1;
		_struct.x = x;
		_struct.y = y;
		
		return _struct;
	}
	static importAsset = function(_asset){
		
		x = _asset.posx;
		y = _asset.value;
		
	}
	static exportAsset = function(){
		var _point = animcurve_point_new();
		
		_point.posx  = x;
		_point.value = y;
		
		//these dont acctually appear to be needed
		_point.th0 = th0;
		_point.th1 = th1;
		_point.tv0 = tv0;
		_point.tv1 = tv1;
		
		return _point;
	}
}

//Sprite
function GMSprite() : GMAsset() constructor {
	resourceType = "GMSprite";
	resourceVersion = GM_RESOURCE_VERSION;
	
	bboxMode = 2; // bboxmode_automatic || bboxmode_fullimage || bboxmode_manual
	bbox_bottom = 63;
	bbox_left   = -64;
	bbox_right  = 63;
	bbox_top    = -64;
	collisionKind = 2; // bboxkind_rectangular || bboxkind_ellipse || bboxkind_diamond || bboxkind_precise
	collisionTolerance = 0; // 0 <-> 255
	DynamicTexturePage = false;
	edgeFiltering = false;
	For3D = false;
	frames = [ /* GMSpriteFrame */ ];
	gridX = 0;
	gridY = 0;
	height = 64;
	HTile = false;
	layers = [ /* GMImageLayer */ ];
	name = ""; //Sprite1
	nineSlice = new GMNineSliceData();
	origin = 0;
	preMultiplyAlpha = false;
	sequence = new GMSequence();
	swatchColours = undefined;
	swfPrecision = 2.525;
	textureGroupId = {
		name: "Default",
		path: "texturegroups/Default",
	};
	type = 0;
	VTile = false;
	width = 64;
	
	static __import = function(_struct){
		bboxMode = _struct.bboxModel;
		bbox_bottom = _struct.bbox_bottom;
		bbox_left = _struct.bbox_left;
		bbox_right = _struct.bbox_right;
		bbox_top = _struct.bbox_top;
		collisionKind = _struct.collisionKind;
		collisionTolerance = _struct.collisionTolerance;
		DynamicTexturePage = _struct.DynamicTexturePage;
		edgeFiltering = _struct.edgeFiltering;
		For3D = _struct.For3D;
		frames = _struct.frames;
		gridX = _struct.gridX;
		gridY = _struct.gridY;
		height = _struct.height;
		HTile = _struct.HTile;
		layers = _struct.layers;
		name = _struct.name;
		origin = _struct.origin;
		preMultiplyAlpha = _struct.preMultiplyAlpha;
		swatchColours = _struct.swatchColours;
		swfPrecision = _struct.swfPrecision;
		
		textureGroupId.name = _struct.textureGroupId.name;
		textureGroupId.path = _struct.textureGroupId.path;
		
		type = _struct.type;
		VTile = _struct.VTile;
		width = _struct.width;
		
		//import frames
		array_resize(frames, array_length(_struct.frames));
		var _i=0; repeat(array_length(frames)) {
			var _frame = frames[_i];
			
			if (_frame == undefined) {
				_frame = new GMSpriteFrame();
			}
			
			_frame.__import(_struct.frames[_i]);
			
			frames[_i] = _frame;
		_i+=1};
		
		nineSlice.__import(_struct.nineSlice);
		sequence.__import(_struct.sequence);
	}
	static __export = function(){
		var _struct = {};
		
		_struct.bboxMode = bboxModel;
		_struct.bbox_bottom = bbox_bottom;
		_struct.bbox_left = bbox_left;
		_struct.bbox_right = bbox_right;
		_struct.bbox_top = bbox_top;
		_struct.collisionKind = collisionKind;
		_struct.collisionTolerance = collisionTolerance;
		_struct.DynamicTexturePage = DynamicTexturePage;
		_struct.edgeFiltering = edgeFiltering;
		_struct.For3D = For3D;
		_struct.gridX = gridX;
		_struct.gridY = gridY;
		_struct.height = height;
		_struct.HTile = HTile;
		_struct.layers = layers;
		_struct.name = name;
		_struct.origin = origin;
		_struct.preMultiplyAlpha = preMultiplyAlpha;
		_struct.swatchColours = swatchColours;
		_struct.swfPrecision = swfPrecision;
		
		_struct.textureGroupId.name = textureGroupId.name;
		_struct.textureGroupId.path = textureGroupId.path;
		
		_struct.type = type;
		_struct.VTile = VTile;
		_struct.width = width;
		
		_struct.frames = array_create(array_length(frames), undefined);
		var _i=0; repeat(array_length(frames)) {
			_struct.frames[_i] = frames[_i].__export();
			
		_i+=1};
		
		_struct.nineSlice = nineSlice.__export();
		_struct.sequence  = sequence.__export();
		
		return _struct;
	}
	static importAsset = function(_sprite){
		var _struct = sprite_get_info(_sprite)
		
		bboxMode = sprite_get_bbox_mode(_sprite); // bboxmode_automatic || bboxmode_fullimage || bboxmode_manual
		bbox_bottom = _struct.bbox_bottom;
		bbox_left   = _struct.bbox_left;
		bbox_right  = _struct.bbox_right;
		bbox_top    = _struct.bbox_top;
		edgeFiltering = _struct.smooth;
		type = _struct.type;
		width = _struct.width;
		height = _struct.height;
		
		sequence.xorigin = _struct.xoffset;
		sequence.yorigin = _struct.yoffset;
		sequence.playbackSpeed     = _struct.frame_speed;
		sequence.playbackSpeedType = _struct.frame_type;
		
		var _arr = _struct.messages;
		var _keyframe_arr = sequence.events.Keyframes;
		
		array_resize(_keyframe_arr, array_length(_arr))
		var _i=0; repeat(array_length(_arr)) {
			
			var _keyframe = new GMKeyframe();
			var _message = new GMMessageEventKeyframe();
			
			_message.Events[0] = _arr[_i].message;
			_keyframe.Channels[$ _i] = _message
			
			_keyframe_arr[_i] = _keyframe
			
		_i+=1};
		
		array_resize(frames, _struct.num_subimages);
		var _i=0; repeat(array_length(frames)) {
			var _frame = frames[_i];
			if (_frame == undefined) {
				_frame = new GMSpriteFrame()
			}
			
			_frame.importAsset(_sprite, _i);
			
			frames[_i] = _frame;
			
		_i+=1};
		
		
		nineSlice.__import(_struct.nineslice);
		
		myAsset = _sprite;
		
		#region things which can not be found at runtime
		//collisionKind = 2; // bboxkind_rectangular || bboxkind_ellipse || bboxkind_diamond || bboxkind_precise
		//collisionTolerance = 0; // 0 <-> 255
		//DynamicTexturePage = false;
		//For3D = false;
		//frames = [ /* GMSpriteFrame */ ];
		//gridX = 0;
		//gridY = 0;
		//HTile = false;
		//layers = [ /* GMImageLayer */ ];
		//name = ""; //Sprite1
		//nineSlice = new GMNineSliceData();
		//origin = 0;
		//preMultiplyAlpha = false;
		//swatchColours = undefined;
		//swfPrecision = 2.525;
		//textureGroupId = {
		//	name: "Default",
		//	path: "texturegroups/Default",
		//};
		//VTile = false;
		#endregion
	}
	static exportAsset = function(){
		if (myAsset != undefined) {
			cleanUp();
		}
		
		var _frameCount = array_length(frames);
		
		//add first image
		var _spr = sprite_add(frames[0].name+".png", _frameCount, false, edgeFiltering, sequence.xorigin, sequence.yorigin);
		
		//add sub images
		var _i=1 repeat(_frameCount-1) {
			var _temp_spr = sprite_add(frames[_i].name+".png", _frameCount, false, edgeFiltering, sequence.xorigin, sequence.yorigin)
			sprite_merge(_spr, _temp_spr);
			sprite_delete(_temp_spr);
		_i+=1;} //end repeat loop
		
		//sprite_merge()
		sprite_collision_mask(_spr, false, bboxMode, bbox_left, bbox_top, bbox_right, bbox_bottom, collisionKind, collisionTolerance)
		sprite_set_speed(_spr, sequence.playbackSpeed, sequence.playbackSpeedType)
		sprite_set_nineslice(_spr, nineSlice.exportAsset())
		
		//cache it
		myAsset = _spr;
		
		return _spr;
	}
	
}
function GMSpriteFrame() : GMAsset() constructor {
	self[$ "$GMSpriteFrame"] = "";
	self[$ "%Name"] = ""; //Script1
	resourceType = "GMSpriteFrame";
	resourceVersion = GM_RESOURCE_VERSION;
	
	Name = "993f0b95-6cf9-429e-8839-74d842fbe984";
	name = "993f0b95-6cf9-429e-8839-74d842fbe984";
	
	static __import = function(_struct){
		Name = _struct.Name;
		name = _struct.name;
	}
	static __export = function(){
		var _struct = {};
		
		_struct.bboxMode = bboxModel;
		_struct.bbox_bottom = bbox_bottom;
		_struct.bbox_left = bbox_left;
		_struct.bbox_right = bbox_right;
		_struct.bbox_top = bbox_top;
		_struct.collisionKind = collisionKind;
		_struct.collisionTolerance = collisionTolerance;
		_struct.DynamicTexturePage = DynamicTexturePage;
		_struct.edgeFiltering = edgeFiltering;
		_struct.For3D = For3D;
		_struct.frames = frames;
		_struct.gridX = gridX;
		_struct.gridY = gridY;
		_struct.height = height;
		_struct.HTile = HTile;
		_struct.layers = layers;
		_struct.name = name;
		_struct.origin = origin;
		_struct.preMultiplyAlpha = preMultiplyAlpha;
		_struct.swatchColours = swatchColours;
		_struct.swfPrecision = swfPrecision;
		
		_struct.textureGroupId.name = textureGroupId.name;
		_struct.textureGroupId.path = textureGroupId.path;
		
		_struct.type = type;
		_struct.VTile = VTile;
		_struct.width = width;
		
		_struct.nineSlice = nineSlice.__export();
		_struct.sequence  = sequence.__export();
		
		return _struct;
	}
	static importAsset = function(_sprite, _img_num) {
		var _struct = sprite_get_info(_sprite)
		
		var _x = sprite_get_xoffset(_sprite);
		var _y = sprite_get_yoffset(_sprite);
		var _w = sprite_get_width(_sprite);
		var _h = sprite_get_height(_sprite);
		
		//save the sprite frame as it's own sprite
		var _surf = surface_create(_w, _h);
		surface_set_target(_surf);
		draw_clear_alpha(c_black, 0);
		draw_sprite(_sprite, _img_num, _x, _y);
		surface_reset_target();
		var _spr = sprite_create_from_surface(_surf, 0, 0, _w, _h, false, false, _x, _y);
		
		myAsset = _spr;
		
		//generate a uuid for the file
		if (name == undefined) && (Name != undefined) {
			name = Name;
		}
		else if (Name == undefined) && (name != undefined) {
			Name = name;
		}
		else if (Name == undefined) && (name == undefined) {
			//generate new ID for this image
		}
	}
	static exportAsset = function() {
		throw $"This exportAsset method should not be manually called.\nGMSpriteFrame will be properly exported by GMSprite";
		
		//if (myAsset != undefined) {
		//	cleanUp();
		//}
		
		//var _spr = sprite_add(frames[0].name+".png", 1, false, false, 0, 0);
		
		////cache it
		//myAsset = _spr;
		
		//return _spr;
	}
}
function GMImageLayer() : GMAsset() constructor {
	self[$ "$GMImageLayer"] = "";
	self[$ "%Name"] = ""; //Script1
	resourceType = "GMImageLayer";
	resourceVersion = GM_RESOURCE_VERSION;
	
	Name = "5d1733a2-fbe0-484c-ab83-793ae81a09d2";
	name = "5d1733a2-fbe0-484c-ab83-793ae81a09d2";
	blendMode = 0;
	displayName = "default";
	isLocked = false;
	opacity = 100.0;
	visible = true;
	
	static __import = function(_struct){
		
		Name = _struct.Name;
		name = _struct.name;
		blendMode = _struct.blendMode;
		displayName = _struct.displayName;
		isLocked = _struct.isLocked;
		opacity = _struct.opacity;
		visible = _struct.visible;
		
	}
	static __export = function(){
		var _struct = {};
		
		_struct.Name = Name;
		_struct.name = name;
		_struct.blendMode = blendMode;
		_struct.displayName = displayName;
		_struct.isLocked = isLocked;
		_struct.opacity = opacity;
		_struct.visible = visible;
		
		return _struct;
	}
	static importAsset = function(_sprite){
		
	}
	static exportAsset = function(){
		throw $"This exportAsset method should not be manually called.\nGMImageLayer will be properly exported by GMSprite";
		
		if (myAsset != undefined) {
			cleanUp();
		}
		
		
	}
	
}
function GMNineSliceData() : GMAsset() constructor {
	self[$ "$GMNineSliceData"] = "";
	self[$ "%Name"] = ""; //Script1
	resourceType = "GMNineSliceData";
	resourceVersion = GM_RESOURCE_VERSION;
	
	// RUNTIME
	enabled = false;
	top = 0
	left = 0;
	bottom = 0;
	right = 0;
	tileMode = [ //https://manual.gamemaker.io/monthly/en/#t=GameMaker_Language%2FGML_Reference%2FAsset_Management%2FSprites%2FNine_Slice_Struct.htm
		0, 
		0, 
		0, 
		0, 
		0  
	];
	
	//IDE ONLY
	highlightColour = 1728023040;
	highlightStyle = 0;
	guideColour = [
		4294902015,
		4294902015,
		4294902015,
		4294902015
	];
	
	
	static __import = function(_struct){
		
		enabled = _struct.enabled;
		top = _struct.top;
		left = _struct.left;
		bottom = _struct.bottom;
		right = _struct.right;
		tileMode[0] = _struct.tileMode[0];
		tileMode[1] = _struct.tileMode[1];
		tileMode[2] = _struct.tileMode[2];
		tileMode[3] = _struct.tileMode[3];
		tileMode[4] = _struct.tileMode[4];
		highlightColour = _struct.highlightColour;
		highlightStyle = _struct.highlightStyle;
		guideColour[0] = _struct.guideColour[0];
		guideColour[1] = _struct.guideColour[1];
		guideColour[2] = _struct.guideColour[2];
		guideColour[3] = _struct.guideColour[3];
		
	}
	static __export = function(){
		var _struct = {};
		
		_struct.enabled = enabled;
		_struct.top = top;
		_struct.left = left;
		_struct.bottom = bottom;
		_struct.right = right;
		_struct.tileMode = variable_clone(tileMode);
		_struct.highlightColour = highlightColour;
		_struct.highlightStyle = highlightStyle;
		_struct.guideColour = variable_clone(guideColour);
		
		return _struct;
	}
	static importAsset = function(_sprite){
		var _9slice = sprite_get_nineslice(_sprite);
		enabled  = _9slice.enabled 
		top      = _9slice.top;
		left     = _9slice.left;
		bottom   = _9slice.bottom;
		right    = _9slice.right;
		tileMode[0] = _9slice.tileMode[0];
		tileMode[1] = _9slice.tileMode[1];
		tileMode[2] = _9slice.tileMode[2];
		tileMode[3] = _9slice.tileMode[3];
		tileMode[4] = _9slice.tileMode[4];
	}
	static exportAsset = function(){
		var _struct = {};
		
		_struct.enabled = enabled;
		_struct.top = top;
		_struct.left = left;
		_struct.bottom = bottom;
		_struct.right = right;
		_struct.tileMode = variable_clone(tileMode);
		
		return _struct;
	}
}

//Extensions
function GMExtension() : GMAsset() constructor {
	resourceType = "GMExtension";
	resourceVersion = GM_RESOURCE_VERSION;
	name = "";
	androidactivityinject = "";
	androidclassname = "";
	androidcodeinjection = "";
	androidinject = "";
	androidmanifestinject = "";
	androidPermissions = [];
	androidProps = false;
	androidsourcedir = "";
	author = "";
	classname = "";
	ConfigValues = { /* ConfigName : {copyToTargets : "17179869216"}, */ };
	copyToTargets = 17179869216;
	date = "2022-02-12T13 =42 =59.9877202-06 =00";
	description = "";
	exportToGame = true;
	extensionVersion = "0.0.1";
	files = [/* GMExtensionFile */];
	gradleinject = "";
	hasConvertedCodeInjection = true;
	helpfile = "";
	HTML5CodeInjection = "";
	html5Props = false;
	IncludedResources = [];
	installdir = "";
	iosCocoaPodDependencies = "";
	iosCocoaPods = "";
	ioscodeinjection = "";
	iosdelegatename = "";
	iosplistinject = "";
	iosProps = false;
	iosSystemFrameworkEntries = [];
	iosThirdPartyFrameworkEntries = [];
	license = "";
	maccompilerflags = "";
	maclinkerflags = "";
	macsourcedir = "";
	options = [];
	optionsFile = "options.json";
	packageId = "";
	productId = "";
	sourcedir = "";
	supportedTargets = -1;
	tvosclassname = undefined;
	tvosCocoaPodDependencies = "";
	tvosCocoaPods = "";
	tvoscodeinjection = "";
	tvosdelegatename = undefined;
	tvosmaccompilerflags = "";
	tvosmaclinkerflags = "";
	tvosplistinject = "";
	tvosProps = false;
	tvosSystemFrameworkEntries = [];
	tvosThirdPartyFrameworkEntries = [];
}
function GMExtensionFile() : GMAsset() constructor {
	resourceType = "GMExtensionFile";
	resourceVersion = GM_RESOURCE_VERSION;
	name = "";
	constants = [];
	copyToTargets = -1;
	filename ="extWallet.js";
	final = "";
	functions =[ /* GMExtensionFunction */ ]
	init = "";
	kind = 5;
	order =[ /* {name ="funcName",path ="extensions/extensionName/extensionName.yy",}, */ ];
	origname = "";
	ProxyFiles = [];
	uncompress = false;
	usesRunnerInterface = false;
}
function GMExtensionFunction() : GMAsset() constructor {
	resourceType = "GMExtensionFunction";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //name of the function in editor
	argCount = 0;
	args = []; // array of GMExtensionFunction_ValueType
	documentation = "";
	externalName = ""; //the function's name in the extension
	help = ""; //funcName(argument0, argument1)
	hidden = false;
	kind = 5;
	returnType = GMExtensionFunction_ValueType.String;
	
	enum GMExtensionFunction_ValueType {
		String = 1,
		Double = 2,
	}
}

//Objects
function GMObject() : GMAsset() constructor {
	self[$ "$GMObject"] = "";
	self[$ "%Name"] = "Object4";
	resourceType = "GMObject";
	resourceVersion = GM_RESOURCE_VERSION;
	
	eventList = [];
	self[$ "mana"+"ged"] = true;
	name = ""; // Object4
	overriddenProperties = [];
	parentObjectId = {
		name : "Object3",
		path : "objects/Object3/Object3.yy",
	};
	persistent = false;
	physicsAngularDamping = 0.1;
	physicsDensity = 0.5;
	physicsFriction = 0.2;
	physicsGroup = 1;
	physicsKinematic = false;
	physicsLinearDamping = 0.1;
	physicsObject = false;
	physicsRestitution = 0.1;
	physicsSensor = false;
	physicsShape = 1;
	physicsShapePoints = [];
	physicsStartAwake = true;
	properties = [ /* GMObjectProperty */ ];
	solid = false;
	spriteId = undefined;
	spriteMaskId = undefined;
	visible = true;
}
function GMObjectProperty() : GMAsset() constructor {
	self[$ "$GMObjectProperty"] = "v1";
	self[$ "%Name"] = "variable_name"; //variable_name
	resourceType = "GMObjectProperty";
	resourceVersion = GM_RESOURCE_VERSION;
	
	filters = [];
	listItems = [];
	multiselect = false;
	name = ""; //variable_name
	rangeEnabled = false;
	rangeMax = 10.0;
	rangeMin = 0.0;
	value = "0";
	varType = 0;
	
	enum GMObjectProperty_VarType {
		Real = 0,
		Integer = 1,
		String = 2,
		Boolean = 3,
		Expression = 4,
		Asset = 5,
		List = 6,
		Colour = 7,
		Color = 7,
	}
}

//Particle Systems
function GMParticleSystem() : GMAsset() constructor {
	self[$ "$GMParticleSystem"] = "";
	self[$ "%Name"] = ""; //ParticleSystem1
	resourceType = "GMParticleSystem";
	resourceVersion = GM_RESOURCE_VERSION;
	
	backdropHeight = 768;
	backdropImageOpacity = 0.5;
	backdropImagePath = "";
	backdropWidth = 1366;
	backdropXOffset = 0.0;
	backdropYOffset = 0.0;
	drawOrder = 0;
	emitters = [ /* GMPSEmitter */ ];
	name = ""; //ParticleSystem1
	showBackdrop = true;
	showBackdropImage = false;
	xorigin = 0;
	yorigin = 0;
}
function GMPSEmitter() : GMAsset() constructor {
	self[$ "$GMPSEmitter"] = "";
	self[$ "%Name"] = ""; //Emitter
	resourceType = "GMPSEmitter";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Emitter
	additiveBlend = false;
	directionIncrease = 0.0;
	directionMax = 100.0;
	directionMin = 80.0;
	directionWiggle = 0.0;
	distribution = 0;
	editorColour = 1090519039;
	editorDrawShape = true;
	emitCount = 1;
	emitDelayMax = 0.0;
	emitDelayMin = 0.0;
	emitDelayUnits = 0;
	emitIntervalMax = 0.0;
	emitIntervalMin = 0.0;
	emitIntervalUnits = 0;
	enabled = true;
	endColour = 4294967295;
	GMPresetName = undefined;
	gravityDirection = 270.0;
	gravityForce = 0.0;
	headPosition = 0.0;
	lifetimeMax = 80.0;
	lifetimeMin = 80.0;
	linkedEmitter = undefined;
	locked = false;
	midColour = 4294967295;
	mode = 0;
	orientationIncrease = 0.0;
	orientationMax = 0.0;
	orientationMin = 0.0;
	orientationRelative = false;
	orientationWiggle = 0.0;
	regionH = 64.0;
	regionW = 64.0;
	regionX = 0.0;
	regionY = 0.0;
	scaleX = 1.0;
	scaleY = 1.0;
	shape = 0;
	sizeIncrease = 0.0;
	sizeMax = 1.0;
	sizeMin = 1.0;
	sizeWiggle = 0.0;
	spawnOnDeathCount = 1;
	spawnOnDeathGMPreset = undefined;
	spawnOnDeathId = undefined;
	spawnOnUpdateCount = 1;
	spawnOnUpdateGMPreset = undefined;
	spawnOnUpdateId = undefined;
	speedIncrease = 0.0;
	speedMax = 5.0;
	speedMin = 5.0;
	speedWiggle = 0.0;
	spriteAnimate = false;
	spriteId = undefined;
	spriteRandom = false;
	spriteStretch = true;
	startColour = 4294967295;
	texture = 7;
}

//Paths
function GMPath() : GMAsset() constructor {
	self[$ "$GMPath"] = "";
	self[$ "%Name"] = ""; //Path1
	resourceType = "GMPath";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Path1
	closed = false;
	kind = 0;
	points = [ /* { speed: 100.0, x: 154.0, y: 153.0,}, */ ];
	precision = 4;
	
	static __import = function(_struct){
		name = _struct.name;
		closed = _struct.closed;
		kind = _struct.kind;
		precision = _struct.precision;
		
		array_resize(points, array_length(_struct.points))
		var _i=0; repeat(array_length(points)) {
			var _import_point = _struct.points[_i]
			var _point = points[_i] ?? { speed: 100.0, x: 0, y: 0 };
			
			_point.speed = _import_point.speed;
			_point.x = _import_point.x;
			_point.y = _import_point.y;
			
			points[_i] = _point;
		_i+=1;}//end repeat loop
	}
	static __export = function(){
		var _struct = {};
		
		_struct.name = name;
		_struct.closed = closed;
		_struct.kind = kind;
		_struct.precision = precision;
		
		_struct.points = variable_clone(points);
		
		return _struct;
	}
	static importAsset = function(_asset){
		name = path_get_name(_asset);
		closed = path_get_closed(_asset);
		kind = path_get_kind(_asset);
		precision = path_get_precision(_asset);
		
		var _point_length = path_get_number(_asset)
		array_resize(points, _point_length)
		var _i=0; repeat(_point_length) {
			var _point = points[_i] ?? { speed: 100.0, x: 0, y: 0 };
			
			_point.speed = path_get_point_speed(_asset, _i);
			_point.x = path_get_point_x(_asset, _i);
			_point.y = path_get_point_y(_asset, _i);
			
			points[_i] = _point;
			
		_i+=1;}//end repeat loop
		
	}
	static exportAsset = function(){
		if (myAsset != undefined) {
			cleanUp();
		}
		
		var _path = path_add()
		path_set_closed(_path, closed)
		path_set_kind(_path, kind)
		path_set_precision(_path, precision)
		
		var _i=0; repeat(array_length(points)) {
			var _point = points[_i];
			path_add_point(_path, _point.x, _point.y, _point.speed);
		_i+=1;}//end repeat loop
		
		
		myAsset = _path;
		
		return _path;
	}
	
}

//Rooms
function GMRoom() : GMAsset() constructor {
	self[$ "$GMRoom"] = "";
	self[$ "%Name"] = ""; //Room1
	resourceType = "GMRoom";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Room1
	creationCodeFile = "";
	inheritCode = false;
	inheritCreationOrder = false;
	inheritLayers = false;
	instanceCreationOrder = [];
	isDnd = false;
	layers = [ /* GMR* (room layers) */ ];
	parentRoom = undefined;
	physicsSettings = {
		inheritPhysicsSettings : false,
		PhysicsWorld : false,
		PhysicsWorldGravityX : 0.0,
		PhysicsWorldGravityY : 10.0,
		PhysicsWorldPixToMetres : 0.1,
	};
	roomSettings = {
		Height : 768,
		inheritRoomSettings : false,
		persistent : false,
		Width : 1366,
	};
	sequenceId = undefined;
	views = [
		{hborder: 32, hport: 768, hspeed: -1, hview: 768, inherit: false, objectId: null, vborder: 32, visible: false, vspeed: -1, wport: 1366, wview: 1366, xport: 0, xview: 0, yport: 0, yview: 0, },
		{hborder: 32, hport: 768, hspeed: -1, hview: 768, inherit: false, objectId: null, vborder: 32, visible: false, vspeed: -1, wport: 1366, wview: 1366, xport: 0, xview: 0, yport: 0, yview: 0, },
		{hborder: 32, hport: 768, hspeed: -1, hview: 768, inherit: false, objectId: null, vborder: 32, visible: false, vspeed: -1, wport: 1366, wview: 1366, xport: 0, xview: 0, yport: 0, yview: 0, },
		{hborder: 32, hport: 768, hspeed: -1, hview: 768, inherit: false, objectId: null, vborder: 32, visible: false, vspeed: -1, wport: 1366, wview: 1366, xport: 0, xview: 0, yport: 0, yview: 0, },
		{hborder: 32, hport: 768, hspeed: -1, hview: 768, inherit: false, objectId: null, vborder: 32, visible: false, vspeed: -1, wport: 1366, wview: 1366, xport: 0, xview: 0, yport: 0, yview: 0, },
		{hborder: 32, hport: 768, hspeed: -1, hview: 768, inherit: false, objectId: null, vborder: 32, visible: false, vspeed: -1, wport: 1366, wview: 1366, xport: 0, xview: 0, yport: 0, yview: 0, },
		{hborder: 32, hport: 768, hspeed: -1, hview: 768, inherit: false, objectId: null, vborder: 32, visible: false, vspeed: -1, wport: 1366, wview: 1366, xport: 0, xview: 0, yport: 0, yview: 0, },
		{hborder: 32, hport: 768, hspeed: -1, hview: 768, inherit: false, objectId: null, vborder: 32, visible: false, vspeed: -1, wport: 1366, wview: 1366, xport: 0, xview: 0, yport: 0, yview: 0, },
	];
	viewSettings = {
		clearDisplayBuffer: true,
		clearViewBackground: false,
		enableViews: false,
		inheritViewSettings: false,
	};
	volume = 1.0;
}
//Room Layers
function GMRLayer() : GMAsset() constructor {
	self[$ "$GMRLayer"] = "";
	self[$ "%Name"] = ""; //Folder_1
	resourceType = "GMRLayer";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Folder_1
	effectEnabled = true;
	effectType = undefined;
	gridX = 32;
	gridY = 32;
	hierarchyFrozen = false;
	inheritLayerDepth = false;
	inheritLayerSettings = false;
	inheritSubLayers = true;
	inheritVisibility = true;
	layers = [];
	properties = [];
	userdefinedDepth = false;
	visible = true;
	
};
function GMREffectLayer() : GMRLayer() constructor {
	self[$ "$GMREffectLayer"] = "";
	self[$ "%Name"] = ""; //Effect_1
	resourceType = "GMREffectLayer";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Effect_1
	
};
function GMRAssetLayer() : GMRLayer() constructor {
	self[$ "$GMRAssetLayer"] = "";
	self[$ "%Name"] = ""; //Assets_1
	resourceType = "GMRAssetLayer";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; // Assets_1
	assets = [];
	
};
function GMRPathLayer() : GMRLayer() constructor {
	self[$ "$GMRPathLayer"] = "";
	self[$ "%Name"] = ""; //Path1
	resourceType = "GMRPathLayer";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Path_1
	colour = 4278190335;
	pathId = undefined;
	
};	
function GMRTileLayer() : GMRLayer() constructor { /////////////////////////// check `tiles`
	self[$ "$GMRTileLayer"] = "";
	self[$ "%Name"] = ""; //Path1
	resourceType = "GMRTileLayer";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Tiles_1
	tiles = {
		SerialiseHeight : 0,
		SerialiseWidth : 0,
		TileSerialiseData : [],
	};
	tilesetId = undefined;
	x = 0;
	y = 0;
	
};
function GMRInstanceLayer() : GMRLayer() constructor {
	self[$ "$GMRInstanceLayer"] = "";
	self[$ "%Name"] = ""; //Instances
	resourceType = "GMRInstanceLayer";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = "Instances";
	instances = [];
	
};
function GMRBackgroundLayer() : GMRLayer() constructor {
	self[$ "$GMRBackgroundLayer"] = "";
	self[$ "%Name"] = ""; //Background
	resourceType = "GMRBackgroundLayer";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Background
	animationFPS = 15.0;
	animationSpeedType = 0;
	colour = 4278190080;
	hspeed = 0.0;
	htiled = false;
	spriteId = undefined;
	stretch = false;
	userdefinedAnimFPS = false;
	vspeed = 0.0;
	vtiled = false;
	x = 0;
	y = 0;
	
};

//Scripts
function GMScript() : GMAsset() constructor {
	self[$ "$GMScript"] = "";
	self[$ "%Name"] = ""; //Script1
	resourceType = "GMScript";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Script1
	isCompatibility = false;
	isDnD = false;
	
}

//Tileset
function GMTileSet() : GMAsset() constructor {
	self[$ "$GMTileSet"] = "";
	self[$ "%Name"] = ""; //TileSet1
	resourceType = "GMTileSet";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //TileSet1
	
	autoTileSets = [];
	macroPageTiles = {
		SerialiseHeight: 0,
		SerialiseWidth: 0,
		TileSerialiseData: [],
	};
	out_columns = 0;
	out_tilehborder = 2;
	out_tilevborder = 2;
	spriteId = undefined;
	spriteNoExport = false;
	textureGroupId = {
		name: "Default",
		path: "texturegroups/Default",
	};
	tileAnimation = {
		FrameData: [],
		SerialiseFrameCount: 0,
	};
	tileAnimationFrames = [];
	tileAnimationSpeed = 15.0;
	tileHeight = 16;
	tilehsep = 0;
	tilevsep = 0;
	tileWidth = 16;
	tilexoff = 0;
	tileyoff = 0;
	tile_count = 0;
	
}


//Sequence
function GMSequence() : GMAsset() constructor {
	self[$ "$GMSequence"] = "";
	self[$ "%Name"] = ""; //Sequence1
	resourceType = "GMSequence";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Sequence1
	autoRecord = true;
	backdropHeight = 768;
	backdropImageOpacity = 0.5;
	backdropImagePath = "";
	backdropWidth = 1366;
	backdropXOffset = 0.0;
	backdropYOffset = 0.0;
	events = new GMKeyframeStore();
	eventStubScript = undefined;
	eventToFunction = {};
	length = 60.0;
	lockOrigin = false;
	moments = new GMKeyframeStore();
	playback = 0;
	playbackSpeed = 60.0;
	playbackSpeedType = 0;
	showBackdrop = true;
	showBackdropImage = false;
	spriteId = undefined;
	timeUnits = 1;
	tracks = [];
	visibleRange = undefined;
	volume = 1.0;
	xorigin = 0;
	yorigin = 0;
}
function GMKeyframeStore() : GMAsset() constructor {
	//this is the original name of the class
	self[$ "$KeyframeStore<MessageEventKeyframe>"] = "";
	self[$ "$KeyframeStore<MessageEventKeyframe>"] = "";
	
	self[$ "$GMKeyframeStore"] = "";
	self[$ "%Name"] = ""; //Sequence1
	resourceType = "GMKeyframeStore";
	resourceVersion = GM_RESOURCE_VERSION;
	
	
	Keyframes = [ /* GMKeyframe */ ];
	
}
function GMKeyframe() : GMAsset() constructor {
	//this is the original name of the class
	self[$ "$GMKeyframe<MessageEventKeyframe>"] = "";
	self[$ "$GMKeyframe<MomentEventKeyframe>"] = "";
	
	self[$ "$GMKeyframe"] = "";
	self[$ "%Name"] = ""; //Sequence1
	resourceType = "GMKeyframe";
	resourceVersion = GM_RESOURCE_VERSION;
	
	Channels = { /* GMMessageEventKeyframe || GMMomentsEventKeyframe */ }
	Disabled = false;
	id = "806a87cb-3589-4221-9f8d-e54f3698fef5"; ///idk a random id i guess?
	IsCreationKey = false;
	Key = 0.0;
	Length = 1.0;
	resourceType = "Keyframe<SpriteFrameKeyframe>";
	resourceVersion = "2.0";
	Stretch = false;
	
}
function GMMessageEventKeyframe() : GMAsset() constructor {
	self[$ "$GMMessageEventKeyframe"] = "";
	self[$ "%Name"] = ""; //Sequence1
	resourceType = "GMMessageEventKeyframe";
	resourceVersion = GM_RESOURCE_VERSION;
	
	Events = [ /* string */ ];
}
function GMMomentsEventKeyframe() : GMAsset() constructor {
	self[$ "$GMMomentsEventKeyframe"] = "";
	self[$ "%Name"] = ""; //Sequence1
	resourceType = "GMMomentsEventKeyframe";
	resourceVersion = GM_RESOURCE_VERSION;
	
	Events = [ /* string of a script file */ ];
}

//Sound
function GMSound() : GMAsset() constructor {
	self[$ "$GMSound"] = "";
	self[$ "%Name"] = ""; //Script1
	resourceType = "GMSound";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Sound1
	audioGroupId = {
		name: "audiogroup_default",
		path: "audiogroups/audiogroup_default",
	};
	bitDepth = 1;
	bitRate = 128;
	compression = 0;
	conversionMode = 0;
	duration = 0.0;
	preload = false;
	sampleRate = 44100;
	soundFile = "";
	type = 0;
	volume = 1.0;
}

//Timeline
function GMTimeline() : GMAsset() constructor {
	self[$ "$GMTimeline"] = "";
	self[$ "%Name"] = ""; //Timeline
	resourceType = "GMTimeline";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = "Timeline1";
	momentList = [ /* GMMoment */ ];
}
function GMMoment() : GMAsset() constructor {
	self[$ "$GMMoment"] = "";
	self[$ "%Name"] = ""; //Timeline
	resourceType = "GMMoment";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = "";
	evnt = new GMEvent();
	moment = 0;
}
function GMEvent() : GMAsset() constructor {
	self[$ "$GMEvent"] = "";
	self[$ "%Name"] = ""; //Timeline
	resourceType = "GMEvent";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = "";
	collisionObjectId = undefined;
	eventNum = 0;
	eventType = 0;
	isDnD = false;
}

//Shader
function GMShader() : GMAsset() constructor {
	self[$ "$GMShader"] = "";
	self[$ "%Name"] = ""; //Script1
	resourceType = "GMShader";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = "Shader1";
	type = 1;
}

//Note
function GMNotes() : GMAsset() constructor {
	self[$ "$GMNotes"] = "";
	self[$ "%Name"] = ""; //Note1
	resourceType = "GMNotes";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Note1
}

//Font
function GMFont() : GMAsset() constructor {
	self[$ "$GMFont"] = "";
	self[$ "%Name"] = ""; //Font1
	resourceType = "GMFont";
	resourceVersion = GM_RESOURCE_VERSION;
	
	name = ""; //Font1
	AntiAlias = 1;
	applyKerning = 0;
	ascender = 0;
	ascenderOffset = 0;
	bold = false;
	canGenerateBitmap = true;
	charset = 0;
	first = 0;
	fontName = ""; //"Arial"
	glyphOperations = 0;
	glyphs = {};
	hinting = 0;
	includeTTF = false;
	interpreter = 0;
	italic = false;
	kerningPairs = [];
	last = 0;
	lineHeight = 0;
	maintainGms1Font = false;
	pointRounding = 0;
	ranges = [
		{lower: 32,   upper: 127,},
		{lower: 9647, upper: 9647,},
	];
	regenerateBitmap = false;
	sampleText = "abcdef ABCDEF\n0123456789 .,<>\"'&!?\nthe quick brown fox jumps over the lazy dog\nTHE QUICK BROWN FOX JUMPS OVER THE LAZY DOG\nDefault character: ▯ (9647)";
	sdfSpread = 8;
	size = 12.0;
	styleName = "Regular";
	textureGroupId = {
		name: "Default",
		path: "texturegroups/Default",
	};
	TTFName = "";
	usesSDF = false;
}


