#macro GMLC_RESOURCE_VERSION "1.0"

function __GMLC_Module() constructor {
	animcurves = {};
	datafiles  = {};
	extensions = {};
	fonts      = {};
	notes      = {};
	objects    = {};
	options    = {};
	rooms      = {};
	scripts    = {};
	sequences  = {};
	shaders    = {};
	sounds     = {};
	sprites    = {};
	tilesets   = {};
	
	// Internally Used
	MacroVar   = {};
	EnumVar    = {};
	GlobalVar  = {};
}

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


function __GMLC_Module_Datafile() : __GMLC_Module() constructor {
	
}

function __GMLC_Module_Font() : __GMLC_Module() constructor {
	
}
function __GMLC_Module_Note() : __GMLC_Module() constructor {
	
}



function __GMLC_Module_Option() : __GMLC_Module() constructor {
	
}
function __GMLC_Module_Room() : __GMLC_Module() constructor {
	
}
function __GMLC_Module_Script() : __GMLC_Module() constructor {
	
}
function __GMLC_Module_Sequence() : __GMLC_Module() constructor {
	
}
function __GMLC_Module_Shader() : __GMLC_Module() constructor {
	
}
function __GMLC_Module_Sound() : __GMLC_Module() constructor {
	
}
function __GMLC_Module_Sprite() : __GMLC_Module() constructor {
	
}
function __GMLC_Module_Tileset() : __GMLC_Module() constructor {
	
}
