#macro GMLC_RESOURCE_VERSION "1.0"

//Base Asset
function GMLCAsset() constructor {
	
}

//Project
function GMLCProject() : GMLCAsset() constructor {
	self[$ "$GMLCProject"] = "";
	self[$ "%Name"] = ""; //GameName
	resourceType = "GMLCProject";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = ""; //GameName
	
	AudioGroups = [ /* GMLCAudioGroup */ ];
	configs = {
		children: [ /* {"children":[],"name":"NewConfig1",} */ ],
		name: "Default",
	};
	defaultScriptType = 1;
	Folders = [ /* GMLCFolder */ ];
	IncludedFiles = [ /* GMLCIncludedFile */ ];
	isEcma = false;
	LibraryEmitters = [];
	MetaData = {
		IDEVersion: "2024.4.1.152",
	};
	resources = [ /* {id: {name: "obj_gml_compiler_new", path: "objects/obj_gml_compiler_new/obj_gml_compiler_new.yy"} }, */ ];
	RoomOrderNodes = [ /* {roomId: {name: "Room1", path: "rooms/Room1/Room1.yy"} }, */ ];
	templateType = "game";
	TextureGroups = [ /* GMLCTextureGroup */ ];
	
	//the following does not get exported
	Imports = []; /* {id: "Multiprocessing", namespace: "MP", loadGlobally: false, dependencies: ["Scribble"]} */
	GlobalVar = {};
	MacroVar  = {};
	EnumVar   = {};
	
}

//Anim Curves
function GMLCAnimCurve(_name, _function=0, _channels=[]) : GMLCAsset() constructor {
	resourceType = "GMLCAnimCurve";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = "acAcceptDecline"; //name
	channels = _channels; //array of channels
	self[$ "function"] = _function; //the smoothing type
}
function GMLCAnimCurveChannel(_name, _colour=4290799884, _points=[], _visible=true) : GMLCAsset() constructor {
	resourceType = "GMLCAnimCurveChannel";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name    = _name;
	colour  = _colour;
	points  = _points;
	visible = _visible;
  
}
function GMLCAnimCurveChannelPoint(_th0, _th1, _tv0, _tv1, _x, _y) : GMLCAsset() constructor {
	resourceType = "GMLCAnimCurveChannelPoint";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	th0 = _th0;
	th1 = _th1;
	tv0 = _tv0;
	tv1 = _tv1;
	x = _x;
	y = _y;
}

//Extensions
function GMLCExtension() : GMLCAsset() constructor {
	resourceType = "GMLCExtension";
	resourceVersion = GMLC_RESOURCE_VERSION;
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
	files = [/* GMLCExtensionFile */];
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
	tvosclassname = null;
	tvosCocoaPodDependencies = "";
	tvosCocoaPods = "";
	tvoscodeinjection = "";
	tvosdelegatename = null;
	tvosmaccompilerflags = "";
	tvosmaclinkerflags = "";
	tvosplistinject = "";
	tvosProps = false;
	tvosSystemFrameworkEntries = [];
	tvosThirdPartyFrameworkEntries = [];
}
function GMLCExtensionFile() : GMLCAsset() constructor {
	resourceType = "GMLCExtensionFile";
	resourceVersion = GMLC_RESOURCE_VERSION;
	name = "";
	constants = [];
	copyToTargets = -1;
	filename ="extWallet.js";
	final = "";
	functions =[ /* GMLCExtensionFunction */ ]
	init = "";
	kind = 5;
	order =[ /* {name ="funcName",path ="extensions/extensionName/extensionName.yy",}, */ ];
	origname = "";
	ProxyFiles = [];
	uncompress = false;
	usesRunnerInterface = false;
}
function GMLCExtensionFunction() : GMLCAsset() constructor {
	resourceType = "GMLCExtensionFunction";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
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
function GMLCObject() : GMLCAsset() constructor {
	self[$ "$GMObject"] = "";
	self[$ "%Name"] = "Object4";
	resourceType = "GMLCObject";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
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
	properties = [ /* GMLCObjectProperty */ ];
	solid = false;
	spriteId = null;
	spriteMaskId = null;
	visible = true;
}
function GMLCObjectProperty() : GMLCAsset() constructor {
	self[$ "$GMLCObjectProperty"] = "v1";
	self[$ "%Name"] = "variable_name"; //variable_name
	resourceType = "GMLCObjectProperty";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	filters = [];
	listItems = [];
	multiselect = false;
	name = ""; //variable_name
	rangeEnabled = false;
	rangeMax = 10.0;
	rangeMin = 0.0;
	value = "0";
	varType = 0;
	
	enum GMLCObjectProperty_VarType {
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
function GMLCParticleSystem() : GMLCAsset() constructor {
	self[$ "$GMParticleSystem"] = "";
	self[$ "%Name"] = ""; //ParticleSystem1
	resourceType = "GMLCParticleSystem";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	backdropHeight = 768;
	backdropImageOpacity = 0.5;
	backdropImagePath = "";
	backdropWidth = 1366;
	backdropXOffset = 0.0;
	backdropYOffset = 0.0;
	drawOrder = 0;
	emitters = [ /* GMLCPSEmitter */ ];
	name = ""; //ParticleSystem1
	showBackdrop = true;
	showBackdropImage = false;
	xorigin = 0;
	yorigin = 0;
}
function GMLCPSEmitter() : GMLCAsset() constructor {
	self[$ "$GMLCPSEmitter"] = "";
	self[$ "%Name"] = ""; //Emitter
	resourceType = "GMLCPSEmitter";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
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
	GMPresetName = null;
	gravityDirection = 270.0;
	gravityForce = 0.0;
	headPosition = 0.0;
	lifetimeMax = 80.0;
	lifetimeMin = 80.0;
	linkedEmitter = null;
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
	spawnOnDeathGMPreset = null;
	spawnOnDeathId = null;
	spawnOnUpdateCount = 1;
	spawnOnUpdateGMPreset = null;
	spawnOnUpdateId = null;
	speedIncrease = 0.0;
	speedMax = 5.0;
	speedMin = 5.0;
	speedWiggle = 0.0;
	spriteAnimate = false;
	spriteId = null;
	spriteRandom = false;
	spriteStretch = true;
	startColour = 4294967295;
	texture = 7;
}

//Paths
function GMLCPath() : GMLCAsset() constructor {
	self[$ "$GMLCPath"] = "";
	self[$ "%Name"] = ""; //Path1
	resourceType = "GMLCPath";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = ""; //Path1
	closed = false;
	kind = 0;
	points = [ /* { speed: 100.0, x: 154.0, y: 153.0,}, */ ];
	precision = 4;
}

//Rooms
function GMLCRoom() : GMLCAsset() constructor {
	self[$ "$GMLCRoom"] = "";
	self[$ "%Name"] = ""; //Room1
	resourceType = "GMLCRoom";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = ""; //Room1
	creationCodeFile = "";
	inheritCode = false;
	inheritCreationOrder = false;
	inheritLayers = false;
	instanceCreationOrder = [];
	isDnd = false;
	layers = [ /* GMLCR* (room layers) */ ];
	parentRoom = null;
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
	sequenceId = null;
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
function GMLCRLayer() : GMLCAsset() constructor {
	self[$ "$GMLCRLayer"] = "";
	self[$ "%Name"] = ""; //Folder_1
	resourceType = "GMLCRLayer";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = ""; //Folder_1
	effectEnabled = true;
	effectType = null;
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
function GMLCREffectLayer() : GMLCRLayer() constructor {
	self[$ "$GMLCREffectLayer"] = "";
	self[$ "%Name"] = ""; //Effect_1
	resourceType = "GMLCREffectLayer";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = ""; //Effect_1
	
};
function GMLCRAssetLayer() : GMLCRLayer() constructor {
	self[$ "$GMLCRAssetLayer"] = "";
	self[$ "%Name"] = ""; //Assets_1
	resourceType = "GMLCRAssetLayer";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = ""; // Assets_1
	assets = [];
	
};
function GMLCRPathLayer() : GMLCRLayer() constructor {
	self[$ "$GMLCRPathLayer"] = "";
	self[$ "%Name"] = ""; //Path1
	resourceType = "GMLCRPathLayer";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = ""; //Path_1
	colour = 4278190335;
	pathId = null;
	
};	
function GMLCRTileLayer() : GMLCRLayer() constructor { /////////////////////////// check `tiles`
	self[$ "$GMLCRTileLayer"] = "";
	self[$ "%Name"] = ""; //Path1
	resourceType = "GMLCRTileLayer";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = ""; //Tiles_1
	tiles = {
		SerialiseHeight : 0,
		SerialiseWidth : 0,
		TileSerialiseData : [],
	};
	tilesetId = null;
	x = 0;
	y = 0;
	
};
function GMLCRInstanceLayer() : GMLCRLayer() constructor {
	self[$ "$GMLCRInstanceLayer"] = "";
	self[$ "%Name"] = ""; //Instances
	resourceType = "GMLCRInstanceLayer";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = "Instances";
	instances = [];
	
};
function GMLCRBackgroundLayer() : GMLCRLayer() constructor {
	self[$ "$GMLCRBackgroundLayer"] = "";
	self[$ "%Name"] = ""; //Background
	resourceType = "GMLCRBackgroundLayer";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = ""; //Background
	animationFPS = 15.0;
	animationSpeedType = 0;
	colour = 4278190080;
	hspeed = 0.0;
	htiled = false;
	spriteId = null;
	stretch = false;
	userdefinedAnimFPS = false;
	vspeed = 0.0;
	vtiled = false;
	x = 0;
	y = 0;
	
};

//Scripts
function GMLCScript() : GMLCAsset() constructor {
	self[$ "$GMLCScript"] = "";
	self[$ "%Name"] = ""; //Script1
	resourceType = "GMLCScript";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = ""; //Script1
	isCompatibility = false;
	isDnD = false;
	
}

//Tileset
function GMLCTileSet() : GMLCAsset() constructor {
	self[$ "$GMLCTileSet"] = "";
	self[$ "%Name"] = ""; //TileSet1
	resourceType = "GMLCTileSet";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
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
	spriteId = null;
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

//Sprite
function GMLCSprite() : GMLCAsset() constructor {
	self[$ "$GMLCSprite"] = "";
	self[$ "%Name"] = ""; //Sprite2
	resourceType = "GMLCSprite";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	bboxMode = 2;
	bbox_bottom = 63;
	bbox_left = -64;
	bbox_right = 63;
	bbox_top = -64;
	collisionKind = 2;
	collisionTolerance = 0;
	DynamicTexturePage = false;
	edgeFiltering = false;
	For3D = false;
	frames = [ /* GMLCSpriteFrame */ ];
	gridX = 0;
	gridY = 0;
	height = 64;
	HTile = false;
	layers = [ /* GMLCImageLayer */ ];
	name = ""; //Sprite1
	nineSlice = new GMLCNineSliceData();
	origin = 0;
	preMultiplyAlpha = false;
	sequence = new GMLCSequence();
	swatchColours = null;
	swfPrecision = 2.525;
	textureGroupId = {
		name: "Default",
		path: "texturegroups/Default",
	};
	type = 0;
	VTile = false;
	width = 64
}
function GMLCSpriteFrame() : GMLCAsset() constructor {
	self[$ "$GMLCSpriteFrame"] = "";
	self[$ "%Name"] = ""; //Script1
	resourceType = "GMLCSpriteFrame";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	Name = "993f0b95-6cf9-429e-8839-74d842fbe984";
	name = "993f0b95-6cf9-429e-8839-74d842fbe984";
	
}
function GMLCImageLayer() : GMLCAsset() constructor {
	self[$ "$GMLCImageLayer"] = "";
	self[$ "%Name"] = ""; //Script1
	resourceType = "GMLCImageLayer";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	Name = "5d1733a2-fbe0-484c-ab83-793ae81a09d2";
	name = "5d1733a2-fbe0-484c-ab83-793ae81a09d2";
	blendMode = 0;
	displayName = "default";
	isLocked = false;
	opacity = 100.0;
	visible = true;
	
}
function GMLCNineSliceData() : GMLCAsset() constructor {
	self[$ "$GMLCNineSliceData"] = "";
	self[$ "%Name"] = ""; //Script1
	resourceType = "GMLCNineSliceData";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	enabled = false;
	highlightColour = 1728023040;
	highlightStyle = 0;
	top = 0
	left = 0;
	bottom = 0;
	right = 0;
	guideColour = [
		4294902015,
		4294902015,
		4294902015,
		4294902015
	];
	tileMode = [
		0,
		0,
		0,
		0,
		0
	];
	
}

//Sequence
function GMLCSequence() : GMLCAsset() constructor {
	self[$ "$GMLCSequence"] = "";
	self[$ "%Name"] = ""; //Sequence1
	resourceType = "GMLCSequence";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = ""; //Sequence1
	autoRecord = true;
	backdropHeight = 768;
	backdropImageOpacity = 0.5;
	backdropImagePath = "";
	backdropWidth = 1366;
	backdropXOffset = 0.0;
	backdropYOffset = 0.0;
	events = new GMLCKeyframeMessageEventKeyframe();
	eventStubScript = null;
	eventToFunction = {};
	length = 60.0;
	lockOrigin = false;
	moments = {
		//"$KeyframeStore<MomentsEventKeyfram> = "";
		//Keyframes = [];
		//resourceType = "KeyframeStore<MomentsEventKeyframe>";
		//resourceVersion = "2.0";
	};
	playback = 0;
	playbackSpeed = 60.0;
	playbackSpeedType = 0;
	showBackdrop = true;
	showBackdropImage = false;
	spriteId = null;
	timeUnits = 1;
	tracks = [];
	visibleRange = null;
	volume = 1.0;
	xorigin = 0;
	yorigin = 0;
}
function GMLCKeyframeMessageEventKeyframe() : GMLCAsset() constructor {
	//this is the original name of the class
	self[$ "$Keyframe<MessageEventKeyframe>"] = "";
	
	self[$ "$GMLCKeyframeMessageEventKeyframe"] = "";
	self[$ "%Name"] = ""; //Sequence1
	resourceType = "GMLCKeyframeMessageEventKeyframe";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	Channels = { /* "0": new GMLCMessageEventKeyframe() */ };
	Disabled = false;
	id = "2922f5f8-1e4e-4331-8d4e-4b094cae90f8";
	IsCreationKey = false;
	Key = 0.0;
	Length = 1.0;
	Stretch = false;
	
}
function GMLCMessageEventKeyframe() : GMLCAsset() constructor {
	self[$ "$GMLCMessageEventKeyframe"] = "";
	self[$ "%Name"] = ""; //Sequence1
	resourceType = "GMLCMessageEventKeyframe";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	Events = [ /* string */ ];
}
function GMLCKeyframeMomentsEventKeyframe() : GMLCAsset() constructor { ////////////////////////////////// no examples yet
	////this is the original name of the class
	//self[$ "$Keyframe<MomentsEventKeyframe>"] = "";
	
	//self[$ "$GMLCKeyframeMomentsEventKeyframe"] = "";
	//self[$ "%Name"] = ""; //Sequence1
	//resourceType = "GMLCKeyframeMomentsEventKeyframe";
	//resourceVersion = GMLC_RESOURCE_VERSION;
	
	//Channels = { /* "0": new MomentsEventKeyframe() */ };
	//Disabled = false;
	//id = "2922f5f8-1e4e-4331-8d4e-4b094cae90f8";
	//IsCreationKey = false;
	//Key = 0.0;
	//Length = 1.0;
	//Stretch = false;
	
}
function GMLCMomentsEventKeyframe() : GMLCAsset() constructor { ////////////////////////////////// no examples yet
	//self[$ "$GMLCMomentsEventKeyframe"] = "";
	//self[$ "%Name"] = ""; //Sequence1
	//resourceType = "GMLCMomentsEventKeyframe";
	//resourceVersion = GMLC_RESOURCE_VERSION;
	
	//Events = [ /* string */ ];
}

//Sound
function GMLCSound() : GMLCAsset() constructor {
	self[$ "$GMLCSound"] = "";
	self[$ "%Name"] = ""; //Script1
	resourceType = "GMLCSound";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
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
function GMLCTimeline() : GMLCAsset() constructor {
	self[$ "$GMLCTimeline"] = "";
	self[$ "%Name"] = ""; //Timeline
	resourceType = "GMLCTimeline";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = "Timeline1";
	momentList = [ /* GMLCMoment */ ];
}
function GMLCMoment() : GMLCAsset() constructor {
	self[$ "$GMLCMoment"] = "";
	self[$ "%Name"] = ""; //Timeline
	resourceType = "GMLCMoment";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = "";
	evnt = new GMLCEvent();
	moment = 0;
}
function GMLCEvent() : GMLCAsset() constructor {
	self[$ "$GMLCEvent"] = "";
	self[$ "%Name"] = ""; //Timeline
	resourceType = "GMLCEvent";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = "";
	collisionObjectId = null;
	eventNum = 0;
	eventType = 0;
	isDnD = false;
}

//Shader
function GMLCShader() : GMLCAsset() constructor {
	self[$ "$GMLCShader"] = "";
	self[$ "%Name"] = ""; //Script1
	resourceType = "GMLCShader";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = "Shader1";
	type = 1;
}

//Note
function GMLCNotes() : GMLCAsset() constructor {
	self[$ "$GMLCNotes"] = "";
	self[$ "%Name"] = ""; //Note1
	resourceType = "GMLCNotes";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
	name = ""; //Note1
}

//Font
function GMLCFont() : GMLCAsset() constructor {
	self[$ "$GMLCFont"] = "";
	self[$ "%Name"] = ""; //Font1
	resourceType = "GMLCFont";
	resourceVersion = GMLC_RESOURCE_VERSION;
	
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


