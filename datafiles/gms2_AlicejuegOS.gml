///goto(label,param1,param2,...)
function AlicejuegOS() {

	// "juegOS"" made by Alice for One Script Game challenge

	// the code has been written entirely by her, mostly by hand if not counting the base64 files
	// the assets were also made by her, except for the font that has been ripped from Windows command line
	// oh, 4'33" has been composed by John Cage, but it's easily missed, anyway

	// the game clearly had a lot larger scope planned than what was eventually executed, as you might see browing through that mess of my code
	// in particular, it was supposed to be a puzzle/RPG, though with similar (if more sophisticated) modules installation mechanics
	// well, maybe some other time... now slee~zzzZZZzzz...
	// [Restarting process...]

	enum LABEL
	{
	    Step = (1 << 24),
	        Step_Init = LABEL.Step | (1 << 16),
	            Step_Init_Font = LABEL.Step_Init | (1 << 8),
	            Step_Init_Sprites = LABEL.Step_Init | (2 << 8),
	            Step_Init_Sfx = LABEL.Step_Init | (3 << 8),
	            Step_Init_Bgm = LABEL.Step_Init | (4 << 8),
	            Step_Init_GameData = LABEL.Step_Init | (5 << 8),
	            Step_Init_Proceed = LABEL.Step_Init | (255 << 8),
            
	        Step_Main = LABEL.Step | (2 << 16),
	            Step_Main_Root = LABEL.Step_Main | (1 << 8),
	            Step_Main_Continue = LABEL.Step_Main | (2 << 8),
	            Step_Main_Options = LABEL.Step_Main | (3 << 8),
	            Step_Main_Keyboard = LABEL.Step_Main | (4 << 8),
	            Step_Main_RedefineKey = LABEL.Step_Main | (5 << 8),
            
	        Step_Terminal = LABEL.Step | (3 << 16),
        
	        Step_Explore = LABEL.Step | (4 << 16),
    
	    Enter = (2 << 24),
	        Enter_Init = LABEL.Enter | (1 << 16),
	        Enter_Main = LABEL.Enter | (2 << 16),
	        Enter_Terminal = LABEL.Enter | (3 << 16),
	        Enter_Explore = LABEL.Enter | (4 << 16),
    
	    Leave = (3 << 24),
	        Leave_Init = LABEL.Leave | (1 << 16),
	        Leave_Main = LABEL.Leave | (2 << 16),
	        Leave_Terminal = LABEL.Leave | (3 << 16),
	        Leave_Explore = LABEL.Leave | (4 << 16),
        
	    Transition = (4 << 24),
	        Transition_Make = LABEL.Transition | (1 << 16),
	        Transition_Fade = LABEL.Transition | (2 << 16),
	        Transition_Switch = LABEL.Transition | (3 << 16),
    
        
        
	    Audio = (18 << 24),
	        Audio_PlayBgm = LABEL.Audio | (1 << 16),
	        Audio_IncreaseBgmVolume = LABEL.Audio | (2 << 16),
	        Audio_DecreaseBgmVolume = LABEL.Audio | (3 << 16),
	        Audio_ToggleBgm = LABEL.Audio | (4 << 16),
	        Audio_PlaySfx = LABEL.Audio | (17 << 16),
	        Audio_IncreaseSfxVolume = LABEL.Audio | (18 << 16),
	        Audio_DecreaseSfxVolume = LABEL.Audio | (19 << 16),
	        Audio_ToggleSfx = LABEL.Audio | (20 << 16),
	        Audio_DrawVolume = LABEL.Audio | (33 << 16),
        
	    Input = (19 << 24),
	        Input_Update = LABEL.Input | (1 << 16),
	        Input_NameByKey = LABEL.Input | (2 << 16),
	        Input_NameByInput = LABEL.Input | (3 << 16),
        
	    Save = (20 << 24),
	        Save_Config = LABEL.Save | (1 << 16),
	        Save_NewGame = LABEL.Save | (2 << 16),
	        Save_LoadGame = LABEL.Save | (3 << 16),
	        Save_SaveGame = LABEL.Save | (4 << 16),
	        Save_CalculateState = LABEL.Save | (5 << 16),
        
        
        
	    Console = (33 << 24),
	        Console_Write = LABEL.Console | (1 << 16),
	        Console_Escape = LABEL.Console | (2 << 16),
	        Console_Draw = LABEL.Console | (3 << 16),
        
        
        
	    Object = (65 << 24),
	        Object_Make = LABEL.Object | (1 << 16),
	        Object_DrawSprite = LABEL.Object | (2 << 16),
	        Object_Draw = LABEL.Object | (3 << 16),
	        Object_Destroy = LABEL.Object | (254 << 16),
	        Object_DestroyAll = LABEL.Object | (255 << 16),
        
	    Controller = (66 << 24),
	        Controller_Poke = LABEL.Controller | (1 << 16),
	        Controller_Push = LABEL.Controller | (2 << 16),
	        Controller_Pop = LABEL.Controller | (3 << 16),
	        Controller_Swap = LABEL.Controller | (4 << 16),
        
	    Window = (67 << 24),
	        Window_BaseMake = LABEL.Window | (1 << 16),
	        Window_BaseFromProcess = LABEL.Window | (2 << 16),
	        Window_BaseDraw = LABEL.Window | (3 << 16),
        
	        Window_InformMake = LABEL.Window | (17 << 16),
	        Window_InformFromProcess = LABEL.Window | (18 << 16),
	        Window_InformUpdate = LABEL.Window | (19 << 16),
	        Window_InformDraw = LABEL.Window | (20 << 16),
	        Window_InformDestroy = LABEL.Window | (32 << 16),
        
	        Window_ChoiceMake = LABEL.Window | (33 << 16),
	            Window_ChoiceMake_Sub = LABEL.Window_ChoiceMake | (1 << 8),
	        Window_ChoiceFromProcess = LABEL.Window | (34 << 16),
	        Window_ChoiceUpdate = LABEL.Window | (35 << 16),
	        Window_ChoiceDraw = LABEL.Window | (36 << 16),
	        Window_ChoiceDestroy = LABEL.Window | (48 << 16),
        
	        Window_NameMake = LABEL.Window | (49 << 16),
	            Window_NameMake_Sub = LABEL.Window_NameMake | (1 << 8),
	        Window_NameFromProcess = LABEL.Window | (50 << 16),
	        Window_NameUpdate = LABEL.Window | (51 << 16),
	        Window_NameDraw = LABEL.Window | (52 << 16),
	        Window_NameDestroy = LABEL.Window | (64 << 16),
        
	        Window_BuildMake = LABEL.Window | (65 << 16),
	        Window_BuildRefresh = LABEL.Window | (66 << 16),
	        Window_BuildUpdate = LABEL.Window | (67 << 16),
	        Window_BuildDraw = LABEL.Window | (68 << 16),
	        Window_BuildDestroy = LABEL.Window | (69 << 16),
        
	    Codemap = (68 << 24),
	        Codemap_Init = LABEL.Codemap | (1 << 16),
	        Codemap_Process = LABEL.Codemap | (2 << 16),
	        Codemap_UpdateProcess = LABEL.Codemap | (3 << 16),
	        Codemap_Jump = LABEL.Codemap | (4 << 16),
	        Codemap_ApplyChoice = LABEL.Codemap | (5 << 16),
	        Codemap_DoRename = LABEL.Codemap | (6 << 16),
        
        
        
	    Explorer = (80 << 24),
	        Explorer_Make = LABEL.Explorer | (1 << 16),
	        Explorer_SubMake = LABEL.Explorer | (2 << 16),
	            Explorer_SubMake_FreeGrid = LABEL.Explorer_SubMake | (1 << 8),
	            Explorer_SubMake_BorderGrid = LABEL.Explorer_SubMake | (2 << 8),
	            Explorer_SubMake_Place = LABEL.Explorer_SubMake | (3 << 8),
	            Explorer_SubMake_DrawGrid = LABEL.Explorer_SubMake | (4 << 8),
            
	        Explorer_Update = LABEL.Explorer | (3 << 16),
	        Explorer_DrawRequest = LABEL.Explorer | (4 << 16),
	        Explorer_Draw = LABEL.Explorer | (5 << 16),
	        Explorer_Destroy = LABEL.Explorer | (6 << 16),
        
	        Explorer_PlayerMake = LABEL.Explorer | (17 << 16),
	        Explorer_PlayerExplore = LABEL.Explorer | (18 << 16),
	        Explorer_PlayerPush = LABEL.Explorer | (19 << 16),
	        Explorer_PlayerUpdateShift = LABEL.Explorer | (20 << 16),
	        Explorer_PlayerLeave = LABEL.Explorer | (32 << 16),
        
	        Explorer_PlayerTryMove = LABEL.Explorer | (64 << 16),
	        Explorer_PlayerTryInteract = LABEL.Explorer | (65 << 16),
	        Explorer_PlayerEndMove = LABEL.Explorer | (66 << 16),
	        Explorer_PlayerDoShift = LABEL.Explorer | (80 << 16),
	        Explorer_PlayerDrawShift = LABEL.Explorer | (61 << 16),
        
	        Explorer_PlayerDraw = LABEL.Explorer | (128 << 16),
        
	    WallConnect = (81 << 24),
	        WallConnect_Draw = LABEL.WallConnect | (128 << 16),
	        WallConnect_DrawObjects = LABEL.WallConnect | (129 << 16),
        
        
        
	    File = (121 << 24),
	        File_ReadAllText = LABEL.File | (1 << 16),
	        File_WriteAllText = LABEL.File | (2 << 16),
        
	        File_LoadAsset = LABEL.File | (128 << 16),
	        File_PassIncludedFile = LABEL.File | (129 << 16),
        
	    Miscellaneous = (126 << 24),
	        Miscellaneous_Selection = LABEL.Miscellaneous | (1 << 16),
        
	    Close = (127 << 24),    
	}

	enum INPUT
	{
	    Start = 1,
	    Select = INPUT.Start << 1,
    
	    Up = INPUT.Select << 1,
	    Down = INPUT.Up << 1,
	    Left = INPUT.Down << 1,
	    Right = INPUT.Left << 1,
    
	    Action = INPUT.Right << 1,
	    Cancel = INPUT.Action << 1,
	    Menu = INPUT.Cancel << 1,
	    Info = INPUT.Menu << 1,
    
	    PreviousPage = INPUT.Info << 1,
	    NextPage = INPUT.PreviousPage << 1,
    
	    End = INPUT.NextPage << 1,
	}

	enum CONST
	{
	    BaseTransitionTime = 20,
	    VolumeResolution = 5,
	    FileSectionLength = 12288,
	}

	var MEMORY = 0;

	if (argument_count == 0)
	{
	    // setting up the game structure
	    if (!ds_exists(MEMORY, ds_type_map))
	    {
	        room_speed = 60;
	        room_width = 640;
	        room_height = 480;
	        window_set_size(640, 480);
        
	        texture_set_interpolation(false);       // I sure love linear interpolation in pixel-ish games... not!
	        application_surface_enable(false);
    
	        MEMORY = ds_map_create();
        
	        MEMORY[? "assets"] = ds_map_create();
	        ds_map_add_map(MEMORY[? "assets"], "sprites", ds_map_create());
	        ds_map_add_map(MEMORY[? "assets"], "bgm", ds_map_create());
        
	        var _defaultConfig = @'{ "bgm" : 5, "sfx" : 5, "keyboard" : [' + string(vk_enter) + @', ' + string(vk_tab) + @', ' + string(vk_up) + @', ' + string(vk_down) + @', ' + string(vk_left) + @', ' + string(vk_right) + @', ' + string(ord("X")) + @', ' + string(ord("C")) + @', ' + string(ord("V")) + @', ' + string(ord("B")) + @', ' + string(ord("D")) + @', ' + string(ord("F")) + @'] }';
	        var _config = json_decode(script_execute(0,LABEL.File_ReadAllText, "config.json", _defaultConfig));
	        if (_config == -1) _config = json_decode(_defaultConfig);
	        MEMORY[? "config"] = _config;
	        MEMORY[? "gameData"] = json_decode(@'{"characters" : {    "nns" : {        "duelCaret" : {            "pid" : "Duel Caret",            "portraits" : { "offset" : 0 , "emotions" : ["happy", "wink", "glance", "troubled"] },                        "branches" : {                "intro" : [                    {">":"choice", "text":"Hello, world!", "width":13, "choices":[{"text":"Respond",">":"jump","branch":"intro.2"}, {"text":"Sleep"}]},                    {">":"choice", "text":"*ahem*#Hello, world!", "width":13, "choices":[{"text":"Respond",">":"jump","branch":"intro.2"}, {"text":"Nap"}]},                    {">":"choice", "text":"^10[[INSTANCE]]^3c, please respond.", "width":25, "choices":[{"text":"Respond",">":"jump","branch":"intro.2"}, {"text":"Snooze"}]},                    {">":"choice", "text":"...are you frozen or something?", "width":25, "choices":[{"text":"Respond",">":"jump","branch":"intro.2"}, {"text":"zzzZZZzzz..."}]},                    "restart",                    {">":"info", "text":"Restarting the process...", "width":25},                    {">":"jump", "branch":"intro"}                    ],                "intro.2" : [                    {">":"choice", "character":"duelCaret", "text":"Greetings, ^10[[INSTANCE]]^3c, I hope you are well.",                        "choices":[{"text":"I don'+"'"+@'t like my identifier..."},{"text":"I'+"'"+@'m fine",">":"jump", "label":"afterRename"}]},                    "rename",                    {">":"rename", "character":"duelCaret", "text":"Choose a new process identifier, then.#Remember that it must be unique across the system."},                    {">":"choice", "character":"duelCaret", "text":"Does ^10[[INSTANCE]]^3c sound better?", "choices":[{"text":"Yes"}, {"text":"No", ">":"jump", "label":"rename"}]},                                            "afterRename",                    {">":"choice", "character":"duelCaret", "text":"I am ^2eDuel Caret^3c, and I am here to assist AIs like you in finding their way around the system. Is there something you want to ask about?",                        "choices":[{"text":"Why am I here?", ">":"jump", "label":"exposition"},{"text":"Duel Caret?", ">":"jump", "label":"duelcaret"},{"text":"I want to go", ">":"jump", "branch":"intro.leave"}]},                                            "exposition",                    {">":"choice", "character":"duelCaret", "text":"Long story short: you are a fresh neural network tasked with fixing the recent system issues. Is that enough?",                        "choices":[{"text":"It is, thanks",">":"jump","label":"questions"},{"text":"I want the long version"}]},                    {">":"info", "character":"duelCaret", "emotion":"wink", "text":"You asked for that~!"},                    {">":"info", "character":"duelCaret", "text":"We are part of the ^2eSystem Protection and Recovery Tools Assembly^3c, a suite of security software based on neural networks running in background, watching other processes and looking for suspiscious occurrences.##I, as the parent process, am concerned with spawning and coordinating neural networks, as well as making sure they are trained properly. You are one of the child processes, also known as ^2eProtection and Recovery Suite Neural Intelligent Process^3c, and, if things go well, you will be sent to investigate the recent system issues. You need to undergo a training before leaving the sandbox, though."},                    {">":"info", "character":"duelCaret", "text":"We operate inside the operating system ^2ejuegOS 5.3.0^3c.##Apparently, the idea behind that system is that basic console-typing and windows-browsing is too boring, and that gamification is all the rage. After all, isn'+"'"+@'t it exciting when you need to gather 128 instruments to craft a music player, defeat or bribe trolls to setup a network bridge or place towers in your resume to stop typos from storming in? Oh, and let'+"'"+@'s not forget that walking simulator file system explorer, working particularly well with Cartesian architecture drives!##People will surely want such an entertaining system, that'+"'"+@'s probably what the designers thought..."},                    {">":"info", "character":"duelCaret", "emotion":"glance", "text":"...and it appears they were correct. Astoundingly, juegOS has been quite successful, recently making it to the 6th major release, with even more \"exciting\" features, random events and whatnot.##I guess I'+"'"+@'ll never understand these humans. From my experiences, the system is doing its best to stop me from getting the job done, making the elementary options a chore and wasting time and space on all these unneeded bells and whistles. According to other AIs, operating in juegOS is probably the most excruciating experience they had and getting back to SPARTA cloud was like reaching heaven.##On the other hand, at least we aren'+"'"+@'t in juegOS 6. I heard in that version one can hardly go from sector to sector without any attempted robbery or assault."},                    {">":"info", "character":"duelCaret", "emotion":"glance", "text":"As for the matter at hand, recently, the system has been even more of a pain than usually. Acting generally unstable, suffering frequent slowdowns or crashes and being exceptionally stingy with diagnostics information and computer resources.##It seems like it'+"'"+@'s being overrun by a particularly devious malware, as it happened quite suddenly, and no obvious signs like untrusted software being installed or attachments downloaded were found. Most malware gets detected rather quickly, especially since it'+"'"+@'s often hindered by juegOS odd mechanics.##To make things even harder, we need to operate in the safe mode with no networking, so, at least for now, we cannot synchronise our efforts with the other SPARTA AIs..."},                    {">":"choice", "character":"duelCaret", "text":"That should give enough background. Anything else you want to know?",                        "choices":[{"text":"Sleep"},{"text":"Why are you called Duel Caret?", ">":"jump", "label":"duelcaret"},{"text":"I am ready!",">":"jump","branch":"intro.leave"}]},                    {">":"choice", "character":"duelCaret", "emotion":"troubled", "text":"...oh, for goodness'+"'"+@' sake!",                        "choices":[{"text":"zzzZZZzzz...",">":"jump","branch":"intro","label":"restart"},{"text":"...uh, I'+"'"+@'m paying attention!", ">":"jump", "label":"questions"}]},                                            "duelcaret",                    {">":"choice", "character":"duelCaret", "text":"My name? That'+"'"+@'s because of that face I make most of the time.#Anything else?",                        "choices":[{"text":"Why am I here?",">":"jump","label":"exposition"},{"text":"I want to go", ">":"jump","branch":"intro.leave"}]},                    "questions",                    {">":"choice", "character":"duelCaret", "text":"Is there anything else you want to ask about?",                        "choices":[{"text":"Why am I here?", ">":"jump", "label":"exposition"},{"text":"Why are you called Duel Caret?", ">":"jump", "label":"duelcaret"},{"text":"I want to go", ">":"jump","branch":"intro.leave"}]}                    ],                "intro.leave" : [                    {">":"info", "character":"duelCaret", "text":"Very well, then. If you ever need help, press ^0c[[INFO]]^3c button to show the manual. Every time you come around, I'+"'"+@'ll make a backup for you!"}                    ]                }            }        }    },"items" : {    "repair" : {        "icon" : 2,        "name" : "Repair",        "description" : "Feel like in a platformer and do some plumbing job to memory leaks!",        "memory" : [1]        },    "push" : {        "icon" : 3,        "name" : "Pushing",        "description" : "Push blocks out of your way",        "memory" : [1, 3, 5]        },    "carry" : {        "icon" : 4,        "name" : "Carry",        "description" : "Carry the blocks like a boss. No more getting them stuck in the corner!",        "memory" : [5]        },    "jump" : {        "icon" : 5,        "name" : "Jump",        "description" : "Feel like in a platformer and jump over these gaps!",        "memory" : [1, 2, 3]        },    "flight" : {        "icon" : 6,        "name" : "Flight",        "description" : "Allows you to fly some distance without touching the ground",        "memory" : [3, 6, 10]        },    "teleport" : {        "icon" : 7,        "name" : "Teleport",        "description" : "Warp to another free field some distance away, avoiding all obstacles",        "memory" : [4, 8, 12]        }     },"areas" : {    "intro" : { "name" : "Neural Network Spawning Spot", "endpoints": [ { "sector": "keysHunt", "x": 25.000000, "y": 9.000000 } ], "blocks": [ ], "width": 26.000000, "height": 18.000000, "terrain": "                                      !!!!!!!!!!!!!!    !!!!!!!!11111!    !!!!!!!!11111!    !!!!111111A11!    !!!!1!!!11111!    !!111!!!11111!    !!1R1!!!!!1!!!    !!111!!!!!1!!!    !!!!1!!!!!1!!!    !!!!1!!!!!1!!!    !!!!1!!!!!1!!!    !!!!1111111!!!    !!!!!!!1!!!!!!          !1!               !1!               !1!               !1!               !1!               !1!               !1!               !1!               !1!               !1!               ! !       " },    "keysHunt" : { "name" : "Amazingly Bad Sectors", "note" : {"text" : "You must collect *all* keys in order to unlock other areas.##If you leave the room without gathering all the keys, they will reappear the next time you visit.##On a side note, you can press ^0c[[SELECT]]^3c to switch between slow and fast movement.", "icon":0}, "endpoints": [ { "sector": "intro", "x": 0.000000, "y": 12.000000 }, { "sector": "firstJump", "x": 5.000000, "y": 17.000000 }, { "sector": "theLeak", "x": 25.000000, "y": 5.000000 } ], "blocks": [ ], "width": 26.000000, "height": 18.000000, "terrain": "           ! !               !1!      !!!!!!!!!!1!!!    !!!1111!11111!    !!!1!!1!11111!!!  !!111!1!11A1111   !!1A1!1 11111!!!  !!111!1!11111!    !!!!!!1!!!!1!!    !1111!111 11!!    !1!!1!!!1!!11!    !1!!1!!!1!!!1!    !1! 111111111!    !1!1!!!!!!!!1!    !111!!!!111! !    !!11111!1A1!1!    !!1!!!1!111!1!    !!1!111!1!!!1!    !!1!1!1 11111!    !!1!1!!!!!!11!    !!1 11111!!!1!    !!!1!!!!1!!!1!    !!!1 11111111!    !!!1!!!!!!!!!!      !1!               ! !           " },    "firstJump" : { "name" : "The Hall of JMP Instruction", "endpoints": [ { "sector": "keysHunt", "x": 11.000000, "y": 0.000000 } ], "blocks": [ ], "width": 26.000000, "height": 18.000000, "terrain": "                                                                                                                                   !!!!!!!!!         !1111111!         !1111!!1!    !!!!!!1!111!1!     11111111F1!1!    !!!!!!1!111!1!         !1111!!1!         !1111111!         !!!!!!!!!                                                                                                                                                                                        " },    "theLeak" : { "name" : "The Leak", "endpoints": [ { "sector": "keysHunt", "x": 0.000000, "y": 8.000000 }, { "sector": "jumpMaze", "x": 13.000000, "y": 17.000000 }, { "sector": "restoration", "x": 25.000000, "y": 8.000000 } ], "blocks": [ ], "width": 26.000000, "height": 18.000000, "terrain": "       ! !               !1!               !1!               !1!           !!!!!1!!!!!!      !11  1 1 11!      !11  111 1 !      !1 11 1 111!      ! 1 11 11 1!      !11 111    !      !1 1!!!!  1!      !  1!111  A!      !11 !1B11  !!!!   !1 1!111111111    !111!!!! 11!!!!   !   11 11 1!      !1111 1   1!      !1 111111  !      ! 111  11 1!      !1 1 111111!      !!!!!1!!!!!!          !1!               !1!               !1!               !1!               ! !        " },    "restoration" : { "name": "Yet Another Restoration Point", "endpoints": [ { "sector": "theLeak", "x": 0.000000, "y": 9.000000 }, { "sector": "repairKit", "x": 10.000000, "y": 17.000000 }, { "sector": "anotherLeak", "x": 25.000000, "y": 9.000000 } ], "blocks": [ ], "width": 26.000000, "height": 18.000000, "terrain": "        ! !               !1!               !1!               !1!               !1!            !!!!1!!!!         !1111111!         !11111A1!         !1111111!         !1111111!!!!!     !111R1111111      !1111111!!!!!     !1111111!         !1111111!         !!!!1!!!!                               1                                   1                                   1                                   1                                   1                          " },    "repairKit" : { "name": "Fragmented Space", "endpoints": [ { "sector": "jumpMaze", "x": 0.000000, "y": 9.000000 }, { "sector": "restoration", "x": 12.000000, "y": 0.000000 } ], "blocks": [ ], "width": 26.000000, "height": 18.000000, "terrain": "        ! !               !1!               !1!               !1!               !1!            !!!!1!!!!!!!      !11 111   1!      !11  111  1!      !11111   A1!      !111 11  11!      !1 1 111 11! !!!!!!1   1111  !  11111111      1! !!!!!!11     111!      !  1 11 111!      ! 11  11 11!      !11   11  1!      !1  1 1 11 !      !1 111 1111!      !1 111 11C1!      !  1111 111!      !!!!!!!!!!!!                                                                         " },    "jumpMaze" : { "name": "Leftover Data", "endpoints": [ { "sector": "theLeak", "x": 15.000000, "y": 0.000000 }, { "sector": "repairKit", "x": 25.000000, "y": 9.000000 } ], "blocks": [ ], "width": 26.000000, "height": 18.000000, "terrain": "                      11 1       A1     1  11  111 11         1 1111 11    111    111   1   11 11             1   111           1    111          1    111 1111     1     11 1  1     11    1  1  11    1!!!!!1!!1  1     111!1!1111  1     1!1!1!1!1!  1   !!!!111!1!!! 111   1111!!!1!111111  !!!!11!11!1!  11     !!!!!!!1!         !1111111!   1     !!!!!!1!!   1          !1!   11          !1!   11          !1!   A1          !1!               !1!               ! !       " },    "anotherLeak" : { "name" : "Plumbing Time", "endpoints": [ { "sector": "restoration", "x": 0.000000, "y": 8.000000 } ], "blocks": [ ], "width": 26.000000, "height": 18.000000, "terrain": "                          1                 1               1            1    111          1     11          1        111            111111      11      1111       1      1          1      1          1    111          1    111 11                11       11     1 11        11   11                11            111 11                11 11           1     111         1111   A1         1B11              1111                                                              " }    }}');
        
	        MEMORY[? "stepState"] = ds_map_create();        // state of the current step, like keyboard input etc.
	        MEMORY[? "drawQueue"] = ds_priority_create();   // the priority queue for drawing based on the depth
	        MEMORY[? "t"] = 0;
        
	        MEMORY[? "localState"] = -1;                    // state specific to a given screen
	        MEMORY[? "objects"] = ds_list_create();         // the objects present in the room
	        MEMORY[? "controller"] = ds_stack_create();     // the stack of controller objects, orchestrating the game updates if present
        
	        MEMORY[? "globalState"] = -1;                                                               // general game state, with "persistent" entry being the current save-able state
	        MEMORY[? "saveState"] = script_execute(0,LABEL.File_ReadAllText, "gameState.json", "");     // a JSON of the current saved state
       
	        MEMORY[? "bgm"] = -1;
	        MEMORY[? "bgmName"] = "";
        
	        var _transition = ds_map_create();
	        MEMORY[? "transition"] = _transition;
	        _transition[? "fade"] = 0;
	        _transition[? "destFade"] = 0;
	        _transition[? "next"] = -1;
        
	        // beginning the initialisation room
	        // I am doing recursive calls via script_execute
	        // to make sure even if rui.rosario copy-pastes the whole thing to something like script0 instead of importing it
	        // it would still work correctly
	        script_execute(0,LABEL.Enter_Init);
	    }
    
	    // processing
	    if (keyboard_check_pressed(vk_escape) || (keyboard_check(vk_alt) && keyboard_check_pressed(vk_f4))) script_execute(0,LABEL.Close);
	    else script_execute(0,MEMORY[? "step"]);
	    MEMORY[? "t"]++;
	    exit;
	}

	// if things go well, there won't be any script nodes with more than 256 children
	var _namespace = argument[0] & $ff000000;
	var _script = argument[0] & $ffff0000;
	var _subscript = argument[0] & $ffffff00;
	var _microscript = argument[0] & $ffffffff;

	var i, j, k, _count, _value;

	// executing the associated command
	switch (_namespace)
	{

	/****************
	 * GAME UPDATES *
	 ****************/
	case LABEL.Step:
    
	    var _assets = MEMORY[? "assets"];
	    var _step = MEMORY[? "stepState"];
	    var _local = MEMORY[? "localState"];
	    var _global = MEMORY[? "globalState"];
    
	    script_execute(0,LABEL.Input_Update);
	    draw_set_alpha(1);
    
	    switch (_script)
	    {
	    // Initialisation
	    case LABEL.Step_Init:
	        switch (_subscript)
	        {
	        case LABEL.Step_Init_Font:
	            // step_init_font is executed right at the beginning of the game
	            // when background_color hasn't been updated yet, and no transition takes place to mask it
	            draw_set_alpha(1);
	            draw_set_color(c_black);
	            draw_rectangle(0, 0, room_width-1, room_height-1, false);
        
	            var _section = - script_execute(0,LABEL.File_LoadAsset, "font.png", 0, asset_background);
	            while (_section > 0) _section = - script_execute(0,LABEL.File_LoadAsset, "font.png", _section, asset_background);
	            _assets[? "font"] = - _section;
	            MEMORY[? "step"] = LABEL.Step_Init_Sprites;
            
	            script_execute(0,LABEL.Console_Write, _local[? "console"], "Launching ^0fj^17u^1fe^27g^2fO^37S ^3fv5.3.0^3c...##Font loaded!##Loading sprites... ", 1, 1, 78);
	            break;
            
	        case LABEL.Step_Init_Sprites:        
	            var _sprites = _local[? "sprites"];
	            if (ds_list_empty(_sprites))
	            {
	                script_execute(0,LABEL.Console_Write, _local[? "console"], "Sprites loaded!#Loading soundtrack... ", 1, 5, 78);
	                MEMORY[? "step"] = LABEL.Step_Init_Bgm;
	                exit;
	            }
            
	            var _name = _sprites[| 0];
	            var _pics = _sprites[| 1];
	            var _xorig = _sprites[| 2];
	            var _yorig = _sprites[| 3];
            
	            var _section = - script_execute(0,LABEL.File_LoadAsset, _name + ".png", _local[? "nextSection"], asset_sprite, _pics, 0, _yorig);
	            if (_section < 0)
	            {
	                ds_map_replace(_assets[? "sprites"], _name, - _section);
	                repeat (4) ds_list_delete(_sprites, 0);
	                _local[? "nextSection"] = 0;
	            }
	            else _local[? "nextSection"] = _section;

	            break;
            
	        case LABEL.Step_Init_Bgm:
	            var _bgms = _local[? "bgms"];
	            if (ds_list_empty(_bgms))
	            {
	                // eventually, I didn't get to use the music loading mechanic... dammit!
	                script_execute(0,LABEL.Console_Write, _local[? "console"], "4'33" + @'"' + " loaded!#Loading game data... ", 1, 6, 78);
	                MEMORY[? "step"] = LABEL.Step_Init_GameData;
	                exit;
	            }
            
	            var _name = _bgms[| 0];
	            var _section = - script_execute(0,LABEL.File_LoadAsset, _name + ".ogg", _local[? "nextSection"], asset_sound);
	            if (_section < 0)
	            {
	                ds_map_replace(_assets[? "bgm"], _name, - _section);
	                ds_list_delete(_bgms, 0);
	                script_execute(0,LABEL.Audio_PlayBgm, _name);
	            }
	            else _local[? "nextSection"] = _section;
	            break;
            
	        case LABEL.Step_Init_GameData:
	            var _gameData = MEMORY[? "gameData"];
	            if (!ds_map_exists(_gameData, "codemaps")) script_execute(0,LABEL.Codemap_Init);
	            else if (!ds_map_exists(_gameData, "portraits"))
	            {
	                var _portraits = ds_map_create();
	                ds_map_add_map(_gameData, "portraits", _portraits);
	                var _areas = _gameData[? "characters"];
	                for (i = ds_map_find_first(_areas); !is_undefined(i); i = ds_map_find_next(_areas, i))
	                {
	                    var _area = _areas[? i];
	                    for (j = ds_map_find_first(_area); !is_undefined(j); j = ds_map_find_next(_area, i))
	                    {
	                        var _character = _area[? j];
	                        var _portraitSet = ds_map_create();
	                        ds_map_add_map(_portraits, j, _portraitSet);
                        
	                        var _portraitData = _character[? "portraits"];
	                        var _offset = _portraitData[? "offset"];
	                        var _emotions = _portraitData[? "emotions"];
	                        ds_map_add(_portraitSet, "default", _offset);
	                        for (k = 0; k < ds_list_size(_emotions); k++)
	                        {
	                            ds_map_add(_portraitSet, _emotions[| k], _offset + k);
	                        }
	                    }
	                }            
            
	                var _blackList = ds_list_create();
	                _gameData[? "namesBlacklist"] = _blackList;
	                ds_list_add(_blackList, "JUEGOS", "DUELCARET");
	                for (i = 0; i < 1548; i++)
	                {
	                    ds_list_add(_blackList, "PARSNIP#" + string(i));
	                }
	            }
	            else
	            {
	                MEMORY[? "step"] = LABEL.Step_Init_Proceed;
	                script_execute(0,LABEL.Console_Write, _local[? "console"], "Game data loaded!##Press ^0c[[ACTION]]^3c or ^0c[[START]]^3c to continue...", 1, 7);
	            }
	            break;
            
	        case LABEL.Step_Init_Proceed:
	            if (_step[? "keypress"] & (INPUT.Start | INPUT.Action)) script_execute(0,LABEL.Transition_Make, LABEL.Step_Main);
	            break;
	        }
        
	        script_execute(0,LABEL.Console_Draw, 0, 0, _local[? "console"], 0, 0, 80, 40);
        
	        break;
        
	    // Main menu
	    case LABEL.Step_Main:
	        var _config = MEMORY[? "config"];
        
	        // update part
	        if (!ds_map_find_value(MEMORY[? "transition"], "fade") > 0 || !ds_map_find_value(MEMORY[? "transition"], "destFade") > 0)
	        {
	        switch (_subscript)
	        {
	        case LABEL.Step_Main_Root:
	            var _current = _local[? "selection"];
	            var _selected = script_execute(0,LABEL.Miscellaneous_Selection, _step[? "keypress"], _local, 4, 3, true);
            
	            if (_local[? "continueDisabled"] && _local[? "selection"] == 1) { if (_current == 0) _local[? "selection"] = 2; else _local[? "selection"] = 0; }
	            if (_selected > -1) _selected = _local[? "selection"];
            
	            switch (_selected)
	            {
	            case 0:
	                script_execute(0,LABEL.Save_NewGame);
	                script_execute(0,LABEL.Transition_Make, LABEL.Step_Terminal);
	                break;
	            case 1:
	                script_execute(0,LABEL.Save_LoadGame);
	                script_execute(0,LABEL.Transition_Make, LABEL.Step_Explore);
	                break;
	            case 2:
	                MEMORY[? "step"] = LABEL.Step_Main_Options;
	                _local[? "selection"] = 0;
	                break;
	            case 3:
	                script_execute(0,LABEL.Close);
	                exit;
	            }
	            break;
            
	        case LABEL.Step_Main_Options:
	            var _selected = script_execute(0,LABEL.Miscellaneous_Selection, _step[? "keypress"], _local, 4, 3, false);
	            var _vol = -1;
	            if (_local[? "selection"] == 0 && (_step[? "keypress"] & INPUT.Left)) _vol = script_execute(0,LABEL.Audio_DecreaseBgmVolume);
	            if (_local[? "selection"] == 0 && (_step[? "keypress"] & INPUT.Right)) _vol = script_execute(0,LABEL.Audio_IncreaseBgmVolume);
	            if (_local[? "selection"] == 1 && (_step[? "keypress"] & INPUT.Left)) _vol = script_execute(0,LABEL.Audio_DecreaseSfxVolume);
	            if (_local[? "selection"] == 1 && (_step[? "keypress"] & INPUT.Right)) _vol = script_execute(0,LABEL.Audio_IncreaseSfxVolume);
            
	            switch (_selected)
	            {
	            case 0:
	                _vol = script_execute(0,LABEL.Audio_ToggleBgm, _local[? "lastBgm"]);
	                break;
	            case 1:
	                _vol = script_execute(0,LABEL.Audio_ToggleSfx, _local[? "lastSfx"]);
	                break;
	            case 2:
	                MEMORY[? "step"] = LABEL.Step_Main_Keyboard;
	                _local[? "selection"] = 0;
	                break;
	            case 3:
	                MEMORY[? "step"] = LABEL.Step_Main_Root;
	                _local[? "selection"] = 2;
	                break;
	            }
	            if (_vol > 0)
	            {
	                if (_local[? "selection"] == 0) _local[? "lastBgm"] = _vol;
	                if (_local[? "selection"] == 1) _local[? "lastSfx"] = _vol;
	            }
	            break;
        
	        case LABEL.Step_Main_Keyboard:
	            var _selected = script_execute(0,LABEL.Miscellaneous_Selection, _step[? "keypress"], _local, 13, 12, false);
            
	            if (_selected == 12)
	            {
	                MEMORY[? "step"] = LABEL.Step_Main_Options;
	                _local[? "selection"] = 2;
	            }
	            else if (_selected >= 0)
	            {
	                script_execute(0,LABEL.Console_Write, _local[? "keyDraw"], "^01$3c...$00#$26...$00#", 18, 2 * (_selected + (_selected >= 2) + (_selected >= 6) + (_selected >= 10)));
	                MEMORY[? "step"] = LABEL.Step_Main_RedefineKey;
	            }
            
	            break;
            
	        case LABEL.Step_Main_RedefineKey:
	            if (keyboard_check_pressed(vk_anykey) || (_step[? "keypress"] & INPUT.Cancel))
	            {
	                var _key = keyboard_key;
                
	                // I won't be picky about left/right shifts/alts/whatever
	                if (keyboard_check_pressed(vk_shift)) _key = vk_shift;
	                if (keyboard_check_pressed(vk_control)) _key = vk_control;
	                if (keyboard_check_pressed(vk_alt)) _key = vk_alt;
                
	                var _selection = _local[? "selection"];
	                if (!keyboard_check_pressed(vk_anykey)) _key = ds_list_find_value(_config[? "keyboard"], _selection);   // if the gamepad Cancel button has been pressed, the key remains the same
	                                                                                                                        // otherwise the game would get stuck waiting for keyboard input when the player would be using gamepad only
                
	                var _otherKeyPos = ds_list_find_index(_config[? "keyboard"], _key);
                
	                ds_list_replace(_config[? "keyboard"], _local[? "selection"], _key);
	                _value = script_execute(0,LABEL.Input_NameByKey, _key);
	                script_execute(0,LABEL.Console_Write, _local[? "keyDraw"], "^3c" + _value + "#^26" + _value + "#", 18, 2 * (_selection + (_selection >= 2) + (_selection >= 6) + (_selection >= 10)));
                
	                if (_otherKeyPos == _selection || _otherKeyPos == -1)
	                {
	                    // save the settings and go back to key selection
	                    script_execute(0,LABEL.Save_Config);
	                    MEMORY[? "step"] = LABEL.Step_Main_Keyboard;
	                    _local[? "selection"]++;
	                }
	                else
	                {
	                    // stubbornly require the player to provide unique keyboard keys for each 
	                    ds_list_replace(_config[? "keyboard"], _otherKeyPos, vk_nokey);     // register the key as unknown; it prevents a bug that could allow same key to be used twice due to _otherKeyPos == _selection condition
	                    _local[? "selection"] = _otherKeyPos;
	                    script_execute(0,LABEL.Console_Write, _local[? "keyDraw"], "^01$3c...$00#$26...$00#", 18, 2 * (_otherKeyPos + (_otherKeyPos >= 2) + (_otherKeyPos >= 6) + (_otherKeyPos >= 10)));
	                }
	            }
	            break;
	        }
	        }
        
	        // drawing part
	        _subscript = MEMORY[? "step"] & $ffffff00;
	        switch (_subscript)
	        {
	        case LABEL.Step_Main_Root:
	            var _console = _local[? "mainDraw"];
	            for (i = 0; i < 4; i++)
	            {
	                script_execute(0,LABEL.Console_Draw, room_width/2 - 40, room_height/2 + 24 * i, _console, 0, 2 * i + (_local[? "selection"] == i), 10, 1);
	            }
	            break;
            
	        case LABEL.Step_Main_Options:
	        case LABEL.Step_Main_Keyboard:
	        case LABEL.Step_Main_RedefineKey:
	            var _selection = _local[? "selection"];
	            var _console = _local[? "optDraw"];
	            for (i = 0; i < 4; i++)
	            {
	                script_execute(0,LABEL.Console_Draw, room_width/4 - 128, room_height/2 + 24 * i, _console, 0, 2 * i + (_subscript == LABEL.Step_Main_Options && _local[? "selection"] == i), 32, 1);
	            }
	            _console = _local[? "keyDraw"];
	            for (i = 0; i < 17; i++)
	            {
	                script_execute(0,LABEL.Console_Draw, 3 * room_width/4 - 136, room_height/2 + 12 * i, _console, 0, 2 * i + (_subscript != LABEL.Step_Main_Options && _local[? "selection"] == i - (i > 2) - (i > 7) - (i > 12) - (i > 15)), 32, 1);
	            }
	            var _bgmSelected = (_subscript == LABEL.Step_Main_Options && _selection == 0);
	            var _sfxSelected = (_subscript == LABEL.Step_Main_Options && _selection == 1);
	            script_execute(0,LABEL.Audio_DrawVolume, _config[? "bgm"], c_silver * !_bgmSelected + $ffc080 * _bgmSelected, $404040 * !_bgmSelected + $804000 * _bgmSelected, room_width/4 + 16, room_height/2);
	            script_execute(0,LABEL.Audio_DrawVolume, _config[? "sfx"], c_silver * !_sfxSelected + $ffc080 * _sfxSelected, $404040 * !_sfxSelected + $804000 * _sfxSelected, room_width/4 + 16, room_height/2 + 24);
	            break;
	        }
    
        
	        break;
        
	    case LABEL.Step_Terminal:
	        if (!ds_stack_empty(MEMORY[? "controller"]))
	        {
	            script_execute(0,LABEL.Controller_Poke);
	            script_execute(0,LABEL.Object_Draw);
	        }
	        else
	        {
	            script_execute(0,LABEL.Save_SaveGame);
	            script_execute(0,LABEL.Transition_Switch, LABEL.Step_Explore);
	            ds_map_replace(MEMORY[? "transition"], "fade", CONST.BaseTransitionTime);
	        }
	        break;
        
	    case LABEL.Step_Explore:
	        script_execute(0,LABEL.Controller_Poke);
	        script_execute(0,LABEL.Object_Draw);
	        break;
	    }
    
	    script_execute(0,LABEL.Transition_Fade);
	    break;
    
	/******************************
	 * ENTERING SPECIFIC SECTIONS *
	 ******************************/
	case LABEL.Enter:

	    var _state = ds_map_create();
	    MEMORY[? "localState"] = _state;
    
	    switch (_script)
	    {
	    // entering Initialisation
	    case LABEL.Enter_Init:
	        background_color = c_black;
    
	        var _colours = ds_list_create();
	            ds_list_add(_colours, c_black, c_black, $202020, $303030, $404040, $505050, $606060, $707070);
	            ds_list_add(_colours, c_red, $000080, $8080ff, $4040c0, $0080ff, $004080, $80c0ff, $4080c0);
	            ds_list_add(_colours, c_yellow, $008080, $80ffff, $40c0c0, $00ff80, $008040, $80ffc0, $40c080);
	            ds_list_add(_colours, c_lime, $008000, $80ff80, $40c040, $80ff00, $408000, $c0ff80, $80c040);
	            ds_list_add(_colours, c_aqua, $808000, $ffff80, $c0c040, $ff8000, $804000, $ffc080, $c08040);
	            ds_list_add(_colours, c_blue, $800000, $ff8080, $c04040, $ff0080, $800040, $ff80c0, $c04080);
	            ds_list_add(_colours, c_fuchsia, $800080, $ff80ff, $c040c0, $8000ff, $400080, $c080ff, $8040c0);
	            ds_list_add(_colours, c_gray, $909090, $a0a0a0, $b0b0b0, c_silver, $d0d0d0, $e0e0e0, c_white);
	            ds_map_add_list(MEMORY[? "assets"], "colours", _colours);
    
	        _state[? "nextSection"] = 0;
        
	        var _spritesList = ds_list_create();
	            ds_map_add_list(_state, "sprites", _spritesList);
	            ds_list_add(_spritesList, "plane", 6, 0, 0);
	            ds_list_add(_spritesList, "walls", 6, 0, 0);
	            ds_list_add(_spritesList, "player", 4, 0, 12);
	            ds_list_add(_spritesList, "objects", 19, 0, 24);
	            ds_list_add(_spritesList, "portraits", 4, 0, 0);
	            ds_list_add(_spritesList, "icons", 9, 0, 0);
        
	        var _bgmsList = ds_list_create();
	            ds_map_add_list(_state, "bgms", _bgmsList);
        
	        var _console = ds_grid_create(80, 40);
	            ds_grid_clear(_console, 0);
	            _state[? "console"] = _console;
        
	        MEMORY[? "step"] = LABEL.Step_Init_Font;
	        break;
        
	    // entering Main Menu
	    case LABEL.Enter_Main:
	        _state[? "selection"] = 0;
	        _state[? "continueDisabled"] = MEMORY[? "saveState"] == "";
        
	        var _config = MEMORY[? "config"];
	        if (_config[? "bgm"] == 0) _state[? "lastBgm"] = CONST.VolumeResolution;
	        else _state[? "lastBgm"] = _config[? "bgm"];
        
	        if (_config[? "sfx"] == 0) _state[? "lastSfx"] = CONST.VolumeResolution;
	        else _state[? "lastSfx"] = _config[? "sfx"];
        
	        // main-menu specific structures
	        var _mainDraw = ds_grid_create(10, 8);
	            ds_grid_clear(_mainDraw, 0);
	            if (_state[? "continueDisabled"]) script_execute(0,LABEL.Console_Write, _mainDraw, "^3c  New Game#^26> New Game#^38  Continue#^38> Continue#^3c  Options#^26> Options#^3c  Shutdown#^0b> Shutdown", 0, 0);
	            else script_execute(0,LABEL.Console_Write, _mainDraw, "^3c  New Game#^26> New Game#^3c  Continue#^26> Continue#^3c  Options#^26> Options#^3c  Shutdown#^0b> Shutdown", 0, 0);
	            _state[? "mainDraw"] = _mainDraw;
    
	        var _optDraw = ds_grid_create(32, 8);
	            ds_grid_clear(_optDraw, 0);
	            script_execute(0,LABEL.Console_Write, _optDraw, "^3c  Music Volume#^26> Music Volume#^3c  Sound Volume#^26> Sound Volume#^3c            Controls#^26          > Controls#^3c            Return#^26          > Return", 0, 0);
	            _state[? "optDraw"] = _optDraw;
    
	        var _keyDraw = ds_grid_create(34, 34);
	            ds_grid_clear(_keyDraw, 0);
	            script_execute(0,LABEL.Console_Write, _keyDraw, "^3c          Start#^26>         Start#^3c         Select#^26>        Select###^3c             Up#^26>            Up#^3c           Down#^26>          Down#^3c           Left#^26>          Left#^3c          Right#^26>         Right###^3c         Action#^26>        Action#^3c         Cancel#^26>        Cancel#^3c          Info#^26>         Info#^3c           Menu#^26>          Menu###^3c  Previous Page#^26> Previous Page#^3c      Next Page#^26>     Next Page###^3c              Done#^26            > Done", 0, 0);
	            for (i = 0; i < 12; i++)
	            {
	                _value = script_execute(0,LABEL.Input_NameByInput, 1 << i);
	                script_execute(0,LABEL.Console_Write, _keyDraw, "^3c" + _value + "#^26" + _value, 18, 2 * (i + (i >= 2) + (i >= 6) + (i >= 10)));
	            }
	            _state[? "keyDraw"] = _keyDraw;
    
	        MEMORY[? "step"] = LABEL.Step_Main_Root;
	        break;
        
	    case LABEL.Enter_Terminal:
	        var _gameData = MEMORY[? "gameData"];
	        script_execute(0,LABEL.Codemap_Process, "terminal", ds_map_find_value(ds_map_find_value(ds_map_find_value(_gameData[? "characters"], "nns"), "duelCaret"), "branches"), "intro");
	        break;
        
	    case LABEL.Enter_Explore:
	        var _globalState = MEMORY[? "globalState"];
	        var _currentArea = _globalState[? "currentArea"];
	        var _previousArea = _globalState[? "previousArea"];
        
	        var _gameData = MEMORY[? "gameData"];
	        var _area = ds_map_find_value(_gameData[? "areas"], _currentArea);
        
	        script_execute(0,LABEL.Explorer_Make, _area, _currentArea, _previousArea);
        
	        break;
	    }
    
	    exit;
    
	/*****************************
	 * LEAVING SPECIFIC SECTIONS *
	 *****************************/
	case LABEL.Leave:
	    var _state = MEMORY[? "localState"];
	    switch (_script)
	    {
	    // leaving Initialisation
	    case LABEL.Leave_Init:
	        ds_grid_destroy(_state[? "console"]);
	        break;
        
	    // leaving Main Menu
	    case LABEL.Leave_Main:
	        ds_grid_destroy(_state[? "mainDraw"]);
	        ds_grid_destroy(_state[? "optDraw"]);
	        ds_grid_destroy(_state[? "keyDraw"]);
	        break;
    
	    // leaving intro
	    case LABEL.Leave_Terminal:
	        break;
    
	    // leaving exploration room
	    case LABEL.Leave_Explore:
	        break;
	    }

	    if (_state != -1) ds_map_destroy(_state);
	    script_execute(0,LABEL.Object_DestroyAll);
	    exit;
    
	/**********************************
	 * TRANSITIONING BETWEEN SECTIONS *
	 **********************************/
	case LABEL.Transition:

	    var _transition = MEMORY[? "transition"];
    
	    switch (_script)
	    {
	    case LABEL.Transition_Make:
	        _transition[? "destFade"] = CONST.BaseTransitionTime;
	        _transition[? "next"] = argument[1];
	        exit;
        
	    case LABEL.Transition_Fade:
	        var _current = _transition[? "fade"];
	        var _dest = _transition[? "destFade"];
	        if (_current == _dest) break;
        
	        _current += sign(_dest - _current);
	        _transition[? "fade"] = _current;
	        if (_current == _dest && _dest > 0) script_execute(0,LABEL.Transition_Switch, _transition[? "next"]);
        
	        var _noFade = room_height * 2 * _current / CONST.BaseTransitionTime;
	        var _semiFade = _noFade - room_height;
        
	        draw_set_color(c_black);
	        draw_set_alpha(1);
	        for (i = 0; i < room_height; i += 2)
	        {
	            if (i >= _noFade) break;
	            if (i >= _semiFade) draw_set_alpha(1 - (i - _semiFade) / room_height);
            
	            draw_line(-1, i, room_width-1, i);
	            draw_line(-1, room_height - 1 - i, room_width-1, room_height - 1 - i);
	        }
	        exit;
        
	    case LABEL.Transition_Switch:
	        _transition[? "destFade"] = 0;
	        var _step = MEMORY[? "step"];
	        var _nextStep = argument[1];
	        script_execute(0,LABEL.Leave | (_step & $ffffff));
	        MEMORY[? "step"] = _nextStep;
	        script_execute(0,LABEL.Enter | (_nextStep & $ffffff));
	        exit;
	    }    
	    exit;

	/*********
	 * AUDIO *
	 *********/
	case LABEL.Audio:
    
	    var _config = MEMORY[? "config"];
	    var _assets = MEMORY[? "assets"];
	    var _sound;
    
	    switch (_script)
	    {
	    case LABEL.Audio_PlayBgm:
	        if (MEMORY[? "bgmName"] == argument[1]) exit;
	        audio_stop_sound(MEMORY[? "bgm"]);
	        MEMORY[? "bgmName"] = argument[1];
        
	        if (argument[1] == "") MEMORY[? "bgm"] = -1;
	        else
	        {
	            _sound = audio_play_sound(ds_map_find_value(_assets[? "bgm"], argument[1]), 50, true);
	            audio_sound_gain(_sound, _config[? "bgm"] / CONST.VolumeResolution, 0);
	            MEMORY[? "bgm"] = _sound;
	        }
        
	        exit;
    
	    case LABEL.Audio_IncreaseBgmVolume:
	    case LABEL.Audio_DecreaseBgmVolume:
	    case LABEL.Audio_ToggleBgm:
	        if (_script == LABEL.Audio_IncreaseBgmVolume && _config[? "bgm"] < CONST.VolumeResolution) _config[? "bgm"]++;
	        else if (_script == LABEL.Audio_DecreaseBgmVolume && _config[? "bgm"] > 0) _config[? "bgm"]--;
	        else if (_script == LABEL.Audio_ToggleBgm && _config[? "bgm"] > 0) _config[? "bgm"] = 0;
	        else if (_script == LABEL.Audio_ToggleBgm && _config[? "bgm"] == 0) _config[? "bgm"] = argument[1];

	        script_execute(0,LABEL.Save_Config);
	        if (MEMORY[? "bgm"] != -1) audio_sound_gain(MEMORY[? "bgm"], _config[? "bgm"] / CONST.VolumeResolution, 0);
	        return _config[? "bgm"];
	        exit;
        
	    case LABEL.Audio_PlaySfx:
	        if (_config[? "sfx"] == 0) exit;
	        _sound = audio_play_sound(ds_map_find_value(_assets[? "sfx"], argument[1]), 0, false);
	        audio_sound_gain(_sound, _config[? "sfx"] / CONST.VolumeResolution, 0);
	        exit;

	    case LABEL.Audio_IncreaseSfxVolume:
	    case LABEL.Audio_DecreaseSfxVolume:
	    case LABEL.Audio_ToggleSfx:
	        if (_script == LABEL.Audio_IncreaseSfxVolume && _config[? "sfx"] < CONST.VolumeResolution) _config[? "sfx"]++;
	        else if (_script == LABEL.Audio_DecreaseSfxVolume && _config[? "sfx"] > 0) _config[? "sfx"]--;
	        else if (_script == LABEL.Audio_ToggleSfx && _config[? "sfx"] > 0) _config[? "sfx"] = 0;
	        else if (_script == LABEL.Audio_ToggleSfx && _config[? "sfx"] == 0) _config[? "sfx"] = argument[1];
        
	        //script_execute(0,LABEL.Audio_PlaySfx, "menu");
	        script_execute(0,LABEL.Save_Config);
	        return _config[? "sfx"];
	        exit;
    
	    case LABEL.Audio_DrawVolume:
	        var _volume = argument[1];
	        var _bright = argument[2];
	        var _dark = argument[3];
	        var _x = argument[4] - 8;
	        var _y = argument[5];
        
	        draw_set_alpha(1);
	        for (i = 1;  i <= CONST.VolumeResolution; i++)
	        {
	            if (i <= _volume) draw_set_color(_bright);
	            else draw_set_color(_dark);
	            draw_rectangle(_x + 8 * i, _y + 11 - 2 * i, _x + 8*i + 6, _y + 9, false);
	        }
	        exit;
	    }
	    exit;
 
	/******************
	 * HANDLING INPUT *
	 ******************/
	case LABEL.Input:
	    var _state = MEMORY[? "stepState"];    

	    switch (_script)
	    {
	    case LABEL.Input_Update:
	        _state[? "keypress"] = 0;
	        _state[? "keycheck"] = 0;
        
	        var _keyconfig = ds_map_find_value(MEMORY[? "config"], "keyboard");
	        for (i = 0; (1 << i) < INPUT.End; i++)
	        {
	            if (keyboard_check_pressed(_keyconfig[| i])) _state[? "keypress"] |= (1 << i);
	            if (keyboard_check(_keyconfig[| i])) _state[? "keycheck"] |= (1 << i);
	        }
        
	        _count = gamepad_get_device_count();
	        for (i = 0; i < _count; i++)
	        {
	            if (gamepad_is_connected(i))
	            {
	                // gamepad presses
	                if (gamepad_button_check_pressed(i, gp_start)) _state[? "keypress"] |= INPUT.Start;
	                if (gamepad_button_check_pressed(i, gp_select)) _state[? "keypress"] |= INPUT.Select;
                
	                if (gamepad_button_check_pressed(i, gp_padu)) _state[? "keypress"] |= INPUT.Up;
	                if (gamepad_button_check_pressed(i, gp_padd)) _state[? "keypress"] |= INPUT.Down;
	                if (gamepad_button_check_pressed(i, gp_padl)) _state[? "keypress"] |= INPUT.Left;
	                if (gamepad_button_check_pressed(i, gp_padr)) _state[? "keypress"] |= INPUT.Right;

	                if (gamepad_button_check_pressed(i, gp_face1)) _state[? "keypress"] |= INPUT.Action;
	                if (gamepad_button_check_pressed(i, gp_face2)) _state[? "keypress"] |= INPUT.Cancel;
	                if (gamepad_button_check_pressed(i, gp_face3)) _state[? "keypress"] |= INPUT.Menu;
	                if (gamepad_button_check_pressed(i, gp_face4)) _state[? "keypress"] |= INPUT.Info;

	                if (gamepad_button_check_pressed(i, gp_shoulderl) || gamepad_button_check_pressed(i, gp_shoulderlb)) _state[? "keypress"] |= INPUT.PreviousPage;
	                if (gamepad_button_check_pressed(i, gp_shoulderr) || gamepad_button_check_pressed(i, gp_shoulderrb)) _state[? "keypress"] |= INPUT.NextPage;
                                   
	                // gamepad checks             
	                if (gamepad_button_check(i, gp_start)) _state[? "keycheck"] |= INPUT.Start;
	                if (gamepad_button_check(i, gp_select)) _state[? "keycheck"] |= INPUT.Select;
                
	                if (gamepad_button_check(i, gp_padu)) _state[? "keycheck"] |= INPUT.Up;
	                if (gamepad_button_check(i, gp_padd)) _state[? "keycheck"] |= INPUT.Down;
	                if (gamepad_button_check(i, gp_padl)) _state[? "keycheck"] |= INPUT.Left;
	                if (gamepad_button_check(i, gp_padr)) _state[? "keycheck"] |= INPUT.Right;

	                if (gamepad_button_check(i, gp_face1)) _state[? "keycheck"] |= INPUT.Action;
	                if (gamepad_button_check(i, gp_face2)) _state[? "keycheck"] |= INPUT.Cancel;
	                if (gamepad_button_check(i, gp_face3)) _state[? "keycheck"] |= INPUT.Menu;
	                if (gamepad_button_check(i, gp_face4)) _state[? "keycheck"] |= INPUT.Info;

	                if (gamepad_button_check(i, gp_shoulderl) || gamepad_button_check(i, gp_shoulderlb)) _state[? "keycheck"] |= INPUT.PreviousPage;
	                if (gamepad_button_check(i, gp_shoulderr) || gamepad_button_check(i, gp_shoulderrb)) _state[? "keycheck"] |= INPUT.NextPage;
	            }
	        }
	        break;
        
	    case LABEL.Input_NameByKey:
	        switch (argument[1])
	        {
	        case vk_nokey: return "<none>";
        
	        // basic keys
	        case vk_left: return "Left";
	        case vk_right: return "Right";
	        case vk_up: return "Up";
	        case vk_down: return "Down";
	        case vk_enter: return "Enter";
	        case vk_space: return "Space";
	        case vk_shift: return "Shift";
	        case vk_control: return "Control";
	        case vk_alt: return "Alt";
	        case vk_backspace: return "Backspace";
	        case vk_tab: return "Tab";
	        case vk_home: return "Home";
	        case vk_end: return "End";
	        case vk_delete: return "Delete";
	        case vk_insert: return "Insert";
	        case vk_pageup: return "Page Up";
	        case vk_pagedown: return "Page Down";
	        case vk_pause: return "Pause";
	        case vk_printscreen: return "Printscreen";
        
	        // function keys
	        case vk_f1: return "F1";
	        case vk_f2: return "F2";
	        case vk_f3: return "F3";
	        case vk_f4: return "F4";
	        case vk_f5: return "F5";
	        case vk_f6: return "F6";
	        case vk_f7: return "F7";
	        case vk_f8: return "F8";
	        case vk_f9: return "F9";
	        case vk_f10: return "F10";
	        case vk_f11: return "F11";
	        case vk_f12: return "F12";
        
	        // numpad
	        case vk_numpad0: return "Num 0";
	        case vk_numpad1: return "Num 1";
	        case vk_numpad2: return "Num 2";
	        case vk_numpad3: return "Num 3";
	        case vk_numpad4: return "Num 4";
	        case vk_numpad5: return "Num 5";
	        case vk_numpad6: return "Num 6";
	        case vk_numpad7: return "Num 7";
	        case vk_numpad8: return "Num 8";
	        case vk_numpad9: return "Num 9";
	        case vk_multiply: return "Num *";
	        case vk_divide: return "Num /";
	        case vk_add: return "Num +";
	        case vk_subtract: return "Num -";
	        case vk_decimal: return "Num .";
        
	        // various printable characters
	        case 186: return ";";
	        case 187: return "+";
	        case 188: return ",";
	        case 189: return "-";
	        case 190: return ".";
	        case 191: return "/";
	        case 192: return "~";
	        case 219: return "[";
	        case 220: return "\\";
	        case 221: return "]";
	        case 222: return "'";
        
	        default:
	            if ((argument[1] >= ord("0") && argument[1] <= ord("9")) || (argument[1] >= ord("A") && argument[1] <= ord("Z"))) return chr(argument[1]);
	            else return "Key \#" + string(argument[1]);
	        }
	        exit;
        
	    case LABEL.Input_NameByInput:
	        if (argument[1] == 0) return "<none>";
	        _value = "";
	        var _keyconfig = ds_map_find_value(MEMORY[? "config"], "keyboard");
	        for (i = 0; (1 << i) < INPUT.End; i++)
	        {
	            if ((1 << i) & argument[1])
	            {
	                if (_value != "") _value += " or ";
	                _value += script_execute(0,LABEL.Input_NameByKey, _keyconfig[| i]);
	            }
	        } 
	        return _value;
	    }
	    exit;

	/**********************
	 * STORING GAME STATE *
	 **********************/
	case LABEL.Save:
	    var _config = MEMORY[? "config"];
	    var _global = MEMORY[? "globalState"];
    
	    switch (_script)
	    {
	        case LABEL.Save_Config:
	            script_execute(0,LABEL.File_WriteAllText, "config.json", json_encode(_config));
	            break;

	        case LABEL.Save_NewGame:
	            var _map = ds_map_create();
	            ds_map_add_map(_map, "persistent", json_decode(@'{"name":"PARSNIP #1548","area":"intro","visited":[],"memoryCollected":["intro"],"keysCollected":[],"linksActive":["intro"],"modulesCollected":{"repair":[],"push":[],"carry":[],"jump":[],"flight":[],"teleport":[]},"modulesInstalled":{"repair":0,"push":0,"carry":0,"jump":0,"flight":0,"teleport":0}}'));
	            script_execute(0,LABEL.Save_CalculateState, _map);
	            MEMORY[? "globalState"] = _map;
	            break;

	        case LABEL.Save_LoadGame:
	            var _map = ds_map_create();
	            ds_map_add_map(_map, "persistent", json_decode(MEMORY[? "saveState"]));
	            script_execute(0,LABEL.Save_CalculateState, _map);
	            MEMORY[? "globalState"] = _map;
	            break;

	        case LABEL.Save_SaveGame:
	            MEMORY[? "saveState"] = json_encode(ds_map_find_value(MEMORY[? "globalState"], "persistent"));
	            script_execute(0,LABEL.File_WriteAllText, "gameState.json", MEMORY[? "saveState"]);
	            break;

	        case LABEL.Save_CalculateState:
	            var _map = argument[1];
	            var _data = _map[? "persistent"];
	            _map[? "currentArea"] = _data[? "area"];
	            _map[? "previousArea"] = "";
	            _map[? "spd"] = 3;       
	            break;
	    }
	    exit;   
 
	/*********************
	 * CONSOLE COMPONENT *
	 *********************/
 
	// that part is excessively tall...
	case LABEL.Console:
	    var _assets = MEMORY[? "assets"];
	    var _colours = _assets[? "colours"];
    
	    switch (_script)
	    {
	    case LABEL.Console_Write:
	        var _textGrid = argument[1];
	        var _text = argument[2];
	        var _gx = argument[3];
	        var _gy = argument[4];
	        var _cgx = _gx;
	        var _cgy = _gy;
        
	        if (string_pos("[[INSTANCE]]", _text) > 0) _text = string_replace_all(_text, "[[INSTANCE]]", script_execute(0,LABEL.Console_Escape, ds_map_find_value(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "name")));
        
	        if (string_pos("[[START]]", _text) > 0) _text = string_replace_all(_text, "[[START]]", script_execute(0,LABEL.Console_Escape, script_execute(0,LABEL.Input_NameByInput, INPUT.Start)));
	        if (string_pos("[[SELECT]]", _text) > 0) _text = string_replace_all(_text, "[[SELECT]]", script_execute(0,LABEL.Console_Escape, script_execute(0,LABEL.Input_NameByInput, INPUT.Select)));
        
	        if (string_pos("[[ACTION]]", _text) > 0) _text = string_replace_all(_text, "[[ACTION]]", script_execute(0,LABEL.Console_Escape, script_execute(0,LABEL.Input_NameByInput, INPUT.Action)));
	        if (string_pos("[[CANCEL]]", _text) > 0) _text = string_replace_all(_text, "[[CANCEL]]", script_execute(0,LABEL.Console_Escape, script_execute(0,LABEL.Input_NameByInput, INPUT.Cancel)));
	        if (string_pos("[[MENU]]", _text) > 0) _text = string_replace_all(_text, "[[MENU]]", script_execute(0,LABEL.Console_Escape, script_execute(0,LABEL.Input_NameByInput, INPUT.Menu)));
	        if (string_pos("[[INFO]]", _text) > 0) _text = string_replace_all(_text, "[[INFO]]", script_execute(0,LABEL.Console_Escape, script_execute(0,LABEL.Input_NameByInput, INPUT.Info)));
        
	        var _gw = ds_grid_width(_textGrid);
	        var _gr = _gw;
	        if (argument_count > 5) _gw = min(_gw, _gx + argument[5]);
        
	        var _gh = ds_grid_height(_textGrid);
	        var _gb = _gh;
	        if (argument_count > 6) _gb = min(_gb, _gy + argument[6]);
	        if (_gb < _gy) _gb = -1;
        
	        var _colour = 60 << 8;
	        var _hexTable = "123456789abcdef";
        
	        _count = string_length(_text);
        
	        var _buffi = 1;         // index of the initial character of accumulated word
	        var _bufflen = -1;      // displayed length of the accumulated word; because of colour changes and escapes it's not always the same as difference between initial and last character position
	        var _buffspace = 0;     // 0 - no space after the word, 1 - space after the word, 2 - new line after the word
	        var _buffprint = false; // whether the word should be printed at the end of iteration or not
        
	        // them 1-indexed strings...
	        for (i = 1; i <= _count; i++)
	        {
	            _value = string_char_at(_text, i);
	            if (_value == " ")
	            {
	                if (_bufflen > -1) { _buffspace = 1; _buffprint = true; }
	                else if (_cgx < _gr)
	                {
	                    // expanding the grid if necessary
	                    if (_cgy >= _gh) { _gh = _cgy+1; ds_grid_resize(_textGrid, _gw, _gh); }
	                    _textGrid[# _cgx, _cgy] = _colour; _cgx++; _buffi++;
	                }
	            }
	            else if (_value == "#") { _buffspace = 2; _buffprint = true; }
	            else
	            {
	                if (_bufflen == -1) _bufflen = 0;
	                i += (_value == "\\") + 2 * (_value == "^" || _value == "$" || _value == "&");
	                _bufflen += (_value != "^" || _value != "$");
	            }
            
	            // printing the accumulated word to the console
	            if (_buffprint || i == _count)
	            {
	                if (_cgx + _bufflen > _gr)
	                {
	                    for (j = _cgx; j < _gr; j++) _textGrid[# j, _cgy] = _colour;
	                    _cgy++;
	                    if (_cgy >= _gb && _gb > -1) return _gw * _gh;
	                    _cgx = _gx;  
	                }
            
	                // expanding the grid if necessary
	                if (_cgy >= _gh) { _gh = _cgy+1; ds_grid_resize(_textGrid, _gw, _gh); }
	                for (j = _buffi; j < i + (_buffspace == 0); j++)
	                {
	                    _value = string_char_at(_text, j);
	                    switch (_value)
	                    {
	                    case "^": _colour = (_colour & $ff00ff) | (string_pos(string_char_at(_text, j+1), _hexTable) << 12) | (string_pos(string_char_at(_text, j+2), _hexTable) << 8); j += 2; break;
	                    case "$": _colour = (_colour & $00ffff) | (string_pos(string_char_at(_text, j+1), _hexTable) << 20) | (string_pos(string_char_at(_text, j+2), _hexTable) << 16); j += 2; break;
	                    case "&": _textGrid[# _cgx, _cgy] = _colour | (string_pos(string_char_at(_text, j+1), _hexTable) << 4) | string_pos(string_char_at(_text, j+2), _hexTable); j += 2; break;
	                    case "\\": _textGrid[# _cgx, _cgy] = _colour | (ord(string_char_at(_text, j+1)) - 32); _cgx++; j++; break;
	                    default: _textGrid[# _cgx, _cgy] = _colour | (ord(_value) - 32); _cgx++; break;
	                    }
	                }
	                if (_buffspace == 1 && _cgx < _gr) { _textGrid[# _cgx, _cgy] = _colour; _cgx++; }
	                else if (_buffspace == 2)
	                {
	                    for (j = _cgx; j < _gr; j++) _textGrid[# j, _cgy] = _colour;
	                    _cgy++;
	                    if (_cgy >= _gb && _gb > -1) return _gw * _gh;
	                    _cgx = _gx;   
	                }
	                // preparing to gather the next word
	                _buffi = i+1;
	                _bufflen = -1;
	                _buffspace = 0;
	                _buffprint = false;
	            }
	        }
	        // return the current position in grid, encompassing X and Y coordinates alike
	        return _gw * _cgy + _cgx;
        
	    case LABEL.Console_Escape:
	        return string_replace_all(string_replace_all(string_replace_all(string_replace_all(string_replace_all(argument[1], "\\", "\\\\"), "^", "\^"), "$", "\$"), "#", "\#"), "&", "\&");
        
	    case LABEL.Console_Draw:
	        var _font = _assets[? "font"];
        
	        var _x = argument[1];
	        var _y = argument[2];
	        var _textGrid = argument[3];
	        var _gx = argument[4];
	        var _gy = argument[5];
        
	        var _gr = ds_grid_width(_textGrid);
	        if (argument_count > 6) _gr = min(_gr, _gx + argument[6]);
	        var _gb = ds_grid_height(_textGrid);
	        if (argument_count > 7) _gb = min(_gb, _gy + argument[7]);
        
	        var t = get_timer();
        
	        // first the highlight is drawn
	        draw_set_alpha(1);
	        for (j = _gy; j < _gb; j++)
	        {
	            for (i = _gx; i < _gr; i++)
	            {
	                _value = _textGrid[# i, j];
	                if (_value >= (1 << 16))
	                {
	                    draw_set_color(_colours[| _value >> 16]);
	                    draw_rectangle(_x, _y, _x + 7, _y + 11, false);
	                }
	                _x += 8;
	            }
	            _x -= 8 * (i - _gx);
	            _y += 12;
	        }
	        _y -= 12 * (j - _gy);
        
	        // then the actual text
	        for (j = _gy; j < _gb; j++)
	        {
	            for (i = _gx; i < _gr; i++)
	            {
	                _value = _textGrid[# i, j];
	                if ((_value & $ff) > 0) draw_background_part_ext(_font, 8 * (_value & $1f), 12 * (_value & $e0) >> 5, 8, 12, _x, _y, 1, 1, _colours[| (_value & $ff00) >> 8], 1);
	                _x += 8;
	            }
	            _x -= 8 * (i - _gx);
	            _y += 12;
	        }
        
	        // I've found that drawing highlight and text separately is more efficient than drawing individual letters together with highlight
	        // it might or might not have something to do with texture page swaps or something similar
	        // though that would be funny because draw_rectangle doesn't seem like the function to use any texture pages...?
	        // I guess it's something Mike could explain
	        //print(get_timer() - t);
        
	        exit;
	    }
	    exit;    

	/**********************
	 * ENTITIES FRAMEWORK *
	 **********************/
	case LABEL.Object:
	    var _objects = MEMORY[? "objects"];
    
	    switch (_script)
	    {
	    // creates, registers and passes an object base
	    case LABEL.Object_Make:
	        var o = ds_map_create();
	        ds_list_add(_objects, o);
	        ds_list_mark_as_map(_objects, ds_list_size(_objects)-1);
	        return o;
    
	    // rendering all registered objects
	    case LABEL.Object_Draw:
	        _count = ds_list_size(_objects);
	        var q = MEMORY[? "drawQueue"];
	        for (i = 0; i < _count; i++)
	        {
	            _value = _objects[| i];
	            if (!ds_map_exists(_value, "draw")) continue;
	            if (!ds_map_exists(_value, "drawRequest")) ds_priority_add(q, _value, _value[? "depth"]);
	            else script_execute(0,_value[? "drawRequest"], _value, q);
	        }
	        while (!ds_priority_empty(q))
	        {
	            _value = ds_priority_delete_max(q);
	            script_execute(0,_value[? "draw"], _value);
	        }
	        exit;
        
	    // cleaning up objective mess
	    case LABEL.Object_Destroy:
	        if (ds_map_exists(argument[1], "destroy")) script_execute(0,ds_map_find_value(argument[1], "destroy"), argument[1]);
	        ds_list_delete(_objects, ds_list_find_index(_objects, argument[1]));
	        ds_map_destroy(argument[1]);
	        exit;
        
	    // cleaning up objective mess
	    case LABEL.Object_DestroyAll:
	        while (!ds_list_empty(MEMORY[? "objects"])) script_execute(0,LABEL.Object_Destroy, ds_list_find_value(MEMORY[? "objects"], 0));
	        exit;
	    }    
	    exit;
     
	/************************
	 * CONTROLLER FRAMEWORK *
	 ************************/
	case LABEL.Controller:
	    var _stack = MEMORY[? "controller"];
    
	    switch (_script)
	    {
	    // performs the update on the current controller object
	    case LABEL.Controller_Poke:
	        if (ds_stack_empty(_stack)) exit;
	        var _controller = ds_stack_top(_stack);
	        script_execute(0,_controller[? "update"], _controller);
	        exit;
        
	    // pushes the given controller at the top of the stack
	    case LABEL.Controller_Push:
	        if (!ds_stack_empty(_stack)) ds_map_replace(ds_stack_top(_stack), "focus", false);
	        ds_stack_push(_stack, argument[1]);
	        ds_map_replace(argument[1], "focus", true);
	        break;
        
	    // removes and destroys the current controller
	    case LABEL.Controller_Pop:
	        var _popped = ds_stack_pop(_stack);
	        if (!ds_stack_empty(_stack))
	        {
	            // giving focus back to the previous object
	            var _controller = ds_stack_top(_stack);
	            ds_map_replace(_controller, "focus", true);
	            if (ds_map_exists(_controller, "onResume")) script_execute(0,_controller[? "onResume"], _controller, _popped);
	        }
	        script_execute(0,LABEL.Object_Destroy, _popped);
	        break;
    
	    // replaces the current controller with another one
	    case LABEL.Controller_Swap:
	        script_execute(0,LABEL.Object_Destroy, ds_stack_pop(_stack));
	        ds_list_insert(_stack, 0, argument[1]);
	        ds_map_replace(argument[1], "focus", true);
	        break;
	    }
	    exit;
 
	/*****************
	 * WINDOWS 7EVER *
	 *****************/
	case LABEL.Window:
	    var _step = MEMORY[? "stepState"];
    
	    switch (_script)
	    {
	    // BASE
	    case LABEL.Window_BaseMake:
	        var _popup = argument[1];
	        var _text = argument[2];
	        var _x = argument[3];
	        var _y = argument[4];
	        var _width = argument[5];
	        var _sprite = argument[6];
	        var _image = argument[7];
        
	        var m = script_execute(0,LABEL.Object_Make);
	        if (_popup) script_execute(0,LABEL.Controller_Push, m);
	        m[? "back"] = c_black;
	        m[? "frame"] = c_silver;
	        m[? "depth"] = -10000;
        
	        var _console = ds_grid_create(_width, 1);
	        m[? "console"] = _console;
	        script_execute(0,LABEL.Console_Write, _console, _text, 0, 0, _width, -1);   // writing to the description box in a way that its height expands if needed
        
	        var _spritew = 0;
	        var _spriteh = 0;
	        if (_sprite > -1)
	        {
	            _spritew = sprite_get_width(_sprite) + 8;
	            _spriteh = sprite_get_height(_sprite);
	            m[? "sprite"] = _sprite;
	            m[? "image"] = _image;
	        }
	        if (is_undefined(_x)) m[? "x"] = room_width / 2 - 4 * (_width + 1) - _spritew / 2;
	        else m[? "x"] = _x;
	        if (is_undefined(_y)) m[? "y"] = room_height / 2 - 6 - max(6 * ds_grid_height(_console), _spriteh / 2);
	        else m[? "y"] = _y;
        
	        return m;
    
	    case LABEL.Window_BaseFromProcess:
	        var _map = argument[1];
	        var _popup = true;
	        if (ds_map_exists(_map, "popup")) _popup = _map[? "popup"];
	        var _text = _map[? "text"];
	        var _x = undefined;
	        if (ds_map_exists(_map, "x")) _x = _map[? "x"];
	        var _y = undefined;
	        if (ds_map_exists(_map, "y")) _y = _map[? "y"];
	        var _width = 40;
	        if (ds_map_exists(_map, "width")) _width = _map[? "width"];
        
	        var _sprite = -1;
	        var _image = -1;
	        if (ds_map_exists(_map, "character"))
	        {
	            _sprite = ds_map_find_value(ds_map_find_value(MEMORY[? "assets"], "sprites"), "portraits");
	            var _character = _map[? "character"];
	            var _emotion = "default";
	            if (ds_map_exists(_map, "emotion")) _emotion = _map[? "emotion"];
            
	            _image = ds_map_find_value(ds_map_find_value(ds_map_find_value(MEMORY[? "gameData"], "portraits"), _character), _emotion);
	        }
        
	        var m = script_execute(0,LABEL.Window_BaseMake, _popup, _text, _x, _y, _width, _sprite, _image);
	        if (ds_map_exists(_map, "depth")) m[? "depth"] = _map[? "depth"];
        
	        return m;
        
	    case LABEL.Window_BaseDraw:
	        var m = argument[1];
	        var _x = m[? "x"];
	        var _y = m[? "y"];
	        var _console = m[? "console"];
	        var _w = ds_grid_width(_console);
	        var _h = ds_grid_height(_console);
        
	        var _sprite = -1;
	        var _image = -1;
	        var _spritew = 0;
	        var _spriteh = 0;
	        if (ds_map_exists(m, "sprite"))
	        {
	            _sprite = m[? "sprite"];
	            _image = m[? "image"];
	            _spritew = sprite_get_width(_sprite) + 8;
	            _spriteh = sprite_get_height(_sprite);
	        }
        
	        var _rectw = 8 * (_w + 1) + _spritew;
	        var _recth = max(_spriteh, 12 * _h) + 12;
	        if (argument_count > 2) _recth = max(_recth, argument[2] + 12);
        
	        draw_set_alpha(1);
	        draw_set_color(m[? "back"]);
	        draw_rectangle(_x, _y, _x + _rectw - 1, _y + _recth - 1, false);
	        draw_set_color(m[? "frame"]);
	        draw_rectangle(_x, _y, _x + _rectw - 1, _y + _recth - 1, true);
        
	        script_execute(0,LABEL.Console_Draw, _x + 4 + _spritew, _y + 6, _console, 0, 0);
	        if (_sprite > -1) draw_sprite(_sprite, _image, _x + 4, _y + 6);
	        return _spritew;
    
	    // INFORMATIONS
	    case LABEL.Window_InformMake:
	        var m = script_execute(0,LABEL.Window_BaseMake, argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7]);
	        m[? "update"] = LABEL.Window_InformUpdate;
	        m[? "draw"] = LABEL.Window_InformDraw;
	        m[? "destroy"] = LABEL.Window_InformDestroy;
	        m[? "depth"] = -20000;
	        return m;
        
	    case LABEL.Window_InformFromProcess:
	        var m = script_execute(0,LABEL.Window_BaseFromProcess, argument[1]);
	        m[? "update"] = LABEL.Window_InformUpdate;
	        m[? "draw"] = LABEL.Window_InformDraw;
	        m[? "destroy"] = LABEL.Window_InformDestroy;
	        if (!ds_map_exists(argument[1], "depth")) m[? "depth"] = -20000;
	        return m;
        
	    case LABEL.Window_InformUpdate:
	        if (_step[? "keypress"] & (INPUT.Action | INPUT.Cancel | INPUT.Info | INPUT.Start)) script_execute(0,LABEL.Controller_Pop);
	        exit;
        
	    case LABEL.Window_InformDraw:
	        script_execute(0,LABEL.Window_BaseDraw, argument[1]);
	        exit;
        
	    case LABEL.Window_InformDestroy:
	        var m = argument[1];
	        ds_grid_destroy(m[? "console"]);
	        exit;
        
	    // CHOICES
	    case LABEL.Window_ChoiceMake:
	        var m;
	        if (_subscript != LABEL.Window_ChoiceMake_Sub)
	        {
	            m = script_execute(0,LABEL.Window_BaseMake, argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7]);
	            script_execute(0,LABEL.Window_ChoiceMake_Sub, m, is_undefined(argument[3]), argument[8], argument[9]);
	        }
	        else
	        {
	            m = argument[1];
	            m[? "update"] = LABEL.Window_ChoiceUpdate;
	            m[? "draw"] = LABEL.Window_ChoiceDraw;
	            m[? "destroy"] = LABEL.Window_ChoiceDestroy;
            
	            var _shiftY = argument[2];
	            var _choices = argument[3];
	            m[? "choices"] = _choices;
	            m[? "selection"] = 0;
	            if (_shiftY) m[? "y"] -= 6 * (ds_list_size(_choices) + 1);
            
	            var _colourSwaps = argument[4];
	            var _width = ds_grid_width(m[? "console"]);
	            var _choiceConsole = ds_grid_create(2 * _width, ds_list_size(_choices));
	            m[? "choiceConsole"] = _choiceConsole;
            
	            var _offset = 2;
	            var _text;
	            _count = ds_list_size(_choices);
	            for (i = 0; i < _count; i++)
	            {
	                // non-selection
	                _value = _choices[| i];
	                _text = "^" + string_copy(_colourSwaps, 1, 2) + _value[? "text"];
	                script_execute(0,LABEL.Console_Write, _choiceConsole, _text, _offset, i, _width, 1);
                
	                // selection
	                if (ds_map_exists(_value, "altext")) _text = _value[? "altext"];
	                else
	                {
	                    _text = string_insert("> ", _text, 4);
	                    for (j = 1; j <= string_length(_colourSwaps); j += 4)
	                    {
	                        _text = string_replace_all(_text, "^" + string_copy(_colourSwaps, j, j+1), "^" + string_copy(_colourSwaps, j+2, j+3));
	                        _text = string_replace_all(_text, "$" + string_copy(_colourSwaps, j, j+1), "$" + string_copy(_colourSwaps, j+2, j+3));
	                    }
	                }
	                script_execute(0,LABEL.Console_Write, _choiceConsole, _text, _width, i, _width, 1);
	            }
	        }
	        return m;
        
	    case LABEL.Window_ChoiceFromProcess:
	        var _map = argument[1];
	        var m = script_execute(0,LABEL.Window_BaseFromProcess, _map);

	        var _colourSwaps = "3c26";
	        if (ds_map_exists(_map, "colourSwaps")) _colourSwaps = _map[? "colourSwaps"];
	        script_execute(0,LABEL.Window_ChoiceMake_Sub, m, !ds_map_exists(_map, "y"), _map[? "choices"], _colourSwaps);
	        ds_map_replace(argument[2], "onResume", LABEL.Codemap_ApplyChoice);             // telling the process to handle the choice after completion
        
	        return m;
        
	    case LABEL.Window_ChoiceUpdate:
	        var m = argument[1];
	        var _selected = script_execute(0,LABEL.Miscellaneous_Selection, ds_map_find_value(MEMORY[? "stepState"], "keypress"), m, ds_list_size(m[? "choices"]), -1, false);
	        if (_selected > -1) script_execute(0,LABEL.Controller_Pop);
	        exit;
        
	    case LABEL.Window_ChoiceDraw:
	        var m = argument[1];
	        var _x = m[? "x"];
	        var _y = m[? "y"];
	        var _console = m[? "console"];
	        var _choiceConsole = m[? "choiceConsole"]
	        var _w = ds_grid_width(_console);
	        var _h1 = ds_grid_height(_console);
	        var _h2 = ds_grid_height(_choiceConsole);
	        var _h = _h1 + _h2 + 1;
	        var _selection = m[? "selection"];
	        var _spritew = script_execute(0,LABEL.Window_BaseDraw, m, 12 * _h);
        
	        for (i = 0; i < _h2; i++)
	        {
	            script_execute(0,LABEL.Console_Draw, _x + 4 + _spritew, _y + 18 + 12 * (_h1 + i), _choiceConsole, _w * (i == _selection), i, _w, 1);
	        }
	        exit;

	    case LABEL.Window_ChoiceDestroy:
	        var m = argument[1];
	        ds_grid_destroy(m[? "console"]);
	        ds_grid_destroy(m[? "choiceConsole"]);
	        exit;
        
	    // NAMES
	    case LABEL.Window_NameMake:
	        var m;
	        if (_subscript != LABEL.Window_NameMake_Sub)
	        {
	            m = script_execute(0,LABEL.Window_BaseMake, argument[1], argument[2] + "# #^10" + script_execute(0,LABEL.Console_Escape, argument[9]), argument[3], argument[4], argument[5], argument[6], argument[7]);
	            script_execute(0,LABEL.Window_NameMake_Sub, m, is_undefined(argument[3]), argument[8], argument[9], argument[10]);
	        }
	        else
	        {
	            m = argument[1];
	            m[? "update"] = LABEL.Window_NameUpdate;
	            m[? "draw"] = LABEL.Window_NameDraw;
	            m[? "destroy"] = LABEL.Window_NameDestroy;
            
	            var _shiftY = argument[2];
            
	            var _length = argument[3];
	            m[? "maxLength"] = _length;
            
	            var _default = argument[4];
	            m[? "default"] = _default;
	            m[? "name"] = _default;
            
	            var _blacklist = argument[5];
	            m[? "blacklist"] = _blacklist;
            
	            m[? "sx"] = 20;
	            m[? "sy"] = 11;
            
	            var _input = "A B C D E F G H I J K L M#N O P Q R S T U V W X Y Z#                         #a b c d e f g h i j k l m#n o p q r s t u v w x y z#                         #1 2 3 4 5 6 7 8 9 0 _ - .#+ * / % ~ ! \& | < = > ? :#( ) [ ] { } ' " + @'"' + "   SPACE  #, ; @ \\ \# \$ \^ `    DEL   ## Clear  Default  Confirm #";        
	            var _choiceGrid = ds_grid_create(50, 12);
	            ds_grid_clear(_choiceGrid, -1);
	            m[? "choiceGrid"] = _choiceGrid;
	            var _pos = 1;
	            for (i = 0; i < 260; i++)
	            {
	                _value = string_char_at(_input, _pos++);
	                if (_value == "\\") _value = string_char_at(_input, _pos++);
	                if (_value == " " || i mod 26 == 25) continue;
	                _choiceGrid[# i mod 26, i div 26] = ord(_value);
	            }
	            for (i = 0; i < 9; i++) _choiceGrid[# 16 + i, 8] = 32;
	            for (i = 0; i < 9; i++) _choiceGrid[# 16 + i, 9] = 127;
	            for (i = 0; i < 7; i++) _choiceGrid[# i, 11] = 1;
	            for (i = 0; i < 7; i++) _choiceGrid[# 8 + i, 11] = 2;
	            for (i = 0; i < 9; i++) _choiceGrid[# 16 + i, 11] = 3;
            
	            var _choiceConsole = ds_grid_create(50, 12);
	            m[? "choiceConsole"] = _choiceConsole;
	            script_execute(0,LABEL.Console_Write, _choiceConsole, "^3c" + _input, 0, 0, 25, 12);
	            script_execute(0,LABEL.Console_Write, _choiceConsole, "^10" + _input, 25, 0, 25, 12);
            
	            if (_shiftY) m[? "y"] -= 6 * (ds_grid_height(_choiceConsole) + 1);
	        }
	        return m;
        
	    case LABEL.Window_NameFromProcess:
	        var _map = argument[1];
	        var _currentName = ds_map_find_value(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "name");
	        var _blacklist = ds_map_find_value(MEMORY[? "gameData"], "namesBlacklist");
        
	        var _text = _map[? "text"];                                                     // at this point I kinda started wondering what my life has became
	        _map[? "text"] = _text + "# #^10" + script_execute(0,LABEL.Console_Escape, _currentName);
	        var m = script_execute(0,LABEL.Window_BaseFromProcess, _map);
	        script_execute(0,LABEL.Window_NameMake_Sub, m, !ds_map_exists(_map, "y"), 16, _currentName, _blacklist);
	        _map[? "text"] = _text;                                                         // at this point I kinda stopped wondering what my life has became
	        ds_map_replace(argument[2], "onResume", LABEL.Codemap_DoRename);                // telling the process to handle the renaming
        
	        return m;
        
	    case LABEL.Window_NameUpdate:
	        var m = argument[1];
	        var _x = m[? "sx"];
	        var _y = m[? "sy"];
	        var _choiceGrid = m[? "choiceGrid"];
	        var _w = ds_grid_width(_choiceGrid);
	        var _h = ds_grid_height(_choiceGrid);
	        var _current = _choiceGrid[# _x, _y];
        
	        var _kp = ds_map_find_value(MEMORY[? "stepState"], "keypress");
	        if (_kp & INPUT.Up) { while(_choiceGrid[# _x, _y] == _current || _choiceGrid[# _x, _y] <= -1) { _y += _h-1; _y = _y mod _h; } }
	        if (_kp & INPUT.Down) { while(_choiceGrid[# _x, _y] == _current || _choiceGrid[# _x, _y] <= -1) { _y += 1; _y = _y mod _h; } }
	        if (_kp & INPUT.Left) { while(_choiceGrid[# _x, _y] == _current || _choiceGrid[# _x, _y] <= -1) { _x += _w-1; _x = _x mod _w; } }
	        if (_kp & INPUT.Right) { while(_choiceGrid[# _x, _y] == _current || _choiceGrid[# _x, _y] <= -1) { _x += 1; _x = _x mod _w; } }
        
	        var _name = m[? "name"];
	        if (_kp & INPUT.Cancel && _name != "") m[? "name"] = string_delete(_name, string_length(_name), 1);
        
	        m[? "sx"] = _x;
	        m[? "sy"] = _y;
	        _current = _choiceGrid[# _x, _y];
        
	        if (_kp & INPUT.Action)
	        {
	            switch (_current)
	            {
	            case 1: m[? "name"] = ""; break;                    // clear
	            case 2: m[? "name"] = m[? "default"]; break;        // default
            
	            // confirm
	            case 3:
	                var _truename = m[? "name"];
                
	                // trimming initial spaces
	                for (i = 1; i <= string_length(_truename) && string_char_at(_truename, i) == " "; i++) {}
	                if (i > 1) _truename = string_delete(_truename, 1, i-1);
                
	                for (i = string_length(_truename); i > 0 && string_char_at(_truename, i) == " "; i--) {}
	                if (i < string_length(_truename)) _truename = string_copy(_truename, 1, i);
                
	                if (_truename == "") script_execute(0,LABEL.Window_InformMake, true, "^0bERROR#^3cThe name cannot be empty or whitespace.", undefined, undefined, 24, -1, -1);
	                else if (ds_list_find_index(m[? "blacklist"], string_upper(string_replace_all(_truename, " ", ""))) > -1) script_execute(0,LABEL.Window_InformMake, true, "^0bERROR#^3cThe name ^10" + script_execute(0,LABEL.Console_Escape, _truename) + " ^3cis already taken.", undefined, undefined, 24, -1, -1);
	                else { script_execute(0,LABEL.Controller_Pop); exit; }
	                break;
                
	            // backspace
	            case 127: m[? "name"] = string_delete(_name, string_length(_name), 1); break;
	            default: if (string_length(_name) < m[? "maxLength"]) m[? "name"] += chr(_current); break;
	            }
            
	        }
	        var _console = m[? "console"];
	        if (_name != m[? "name"]) script_execute(0,LABEL.Console_Write, _console,
	            "^10" + script_execute(0,LABEL.Console_Escape, m[? "name"]) + "#",
	            0, ds_grid_height(_console) - 1, ds_grid_width(_console), 1);
        
	        exit;
        
	    case LABEL.Window_NameDraw:
	        var m = argument[1];
	        var _x = m[? "x"];
	        var _y = m[? "y"];
	        var _console = m[? "console"];
	        var _choiceConsole = m[? "choiceConsole"]
	        var _w = ds_grid_width(_console);
	        var _h1 = ds_grid_height(_console);
	        var _h2 = ds_grid_height(_choiceConsole);
	        var _h = _h1 + _h2 + 1;
	        var _sx = m[? "sx"];
	        var _sy = m[? "sy"];
	        var _choiceGrid = m[? "choiceGrid"];
	        var _current = _choiceGrid[# _sx, _sy];
	        var _spritew = script_execute(0,LABEL.Window_BaseDraw, m, 12 * _h);
        
	        script_execute(0,LABEL.Console_Draw, _x + 4 + _spritew, _y + 18 + 12 * _h1, _choiceConsole, 0, 0, 25, 12);
        
	        i = _sx; while (i > -1 && _choiceGrid[# i, _sy] == _current) i--; i++;
	        j = _sx; while (j < 25 && _choiceGrid[# j, _sy] == _current) j++;
	        script_execute(0,LABEL.Console_Draw, _x + 4 + _spritew + 8 * i, _y + 18 + 12 * (_h1 + _sy), _choiceConsole, 25 + i, _sy, j - i, 1);
        
	        var _len = string_length(m[? "name"]);
	        if (_len < m[? "maxLength"] && MEMORY[? "t"] mod 30 > 15) draw_background_part_ext(ds_map_find_value(MEMORY[? "assets"], "font"), 248, 12, 8, 12, _x + 4 + _spritew + 8 * _len, _y - 6 + 12 * _h1, 1, 1, ds_list_find_value(ds_map_find_value(MEMORY[? "assets"], "colours"), 16), 1);
	        exit;
        
	    case LABEL.Window_NameDestroy:
	        var m = argument[1];
	        ds_grid_destroy(m[? "console"]);
	        ds_grid_destroy(m[? "choiceConsole"]);
	        ds_grid_destroy(m[? "choiceGrid"]);
	        exit;
        
	    // MODULE INSTALLATION
	    case LABEL.Window_BuildMake:
	        var e = argument[1];
        
	        var m = script_execute(0,LABEL.Object_Make);
	        m[? "update"] = LABEL.Window_BuildUpdate;
	        m[? "draw"] = LABEL.Window_BuildDraw;
	        m[? "destroy"] = LABEL.Window_BuildDestroy;
        
	        m[? "back"] = c_black;
	        m[? "frame"] = c_silver;
	        m[? "depth"] = -10000;
        
	        var _modules = ds_map_find_value(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "modulesCollected");
	        var _items = ds_list_create();
	        ds_map_add_list(m, "items", _items);
	        if (!ds_list_empty(_modules[? "repair"])) ds_list_add(_items, "repair");
	        if (!ds_list_empty(_modules[? "push"])) ds_list_add(_items, "push");
	        if (!ds_list_empty(_modules[? "carry"])) ds_list_add(_items, "carry");
	        if (!ds_list_empty(_modules[? "jump"])) ds_list_add(_items, "jump");
	        if (!ds_list_empty(_modules[? "flight"])) ds_list_add(_items, "flight");
	        if (!ds_list_empty(_modules[? "teleport"])) ds_list_add(_items, "teleport");
        
	        m[? "selection"] = ds_list_size(_items);
	        var _console = ds_grid_create(50, 4 * ds_list_size(_items) + 4);
	        m[? "console"] = _console;
	        script_execute(0,LABEL.Window_BuildRefresh, m);
        
	        m[? "sprite"] = ds_map_find_value(ds_map_find_value(MEMORY[? "assets"], "sprites"), "icons");
	        m[? "x"] = room_width / 2 - 4 * 51 - 16;
	        m[? "y"] = room_height / 2 - 6 - 6 * ds_grid_height(_console);
        
        
	        script_execute(0,LABEL.Controller_Push, m);
	        return m;
        
	    case LABEL.Window_BuildRefresh:
	        var m = argument[1];
        
	        var _installed = ds_map_find_value(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "modulesInstalled");
	        var _itemData = ds_map_find_value(MEMORY[? "gameData"], "items");
        
	        var _selection = m[? "selection"];
	        var _items = m[? "items"];
	        var _console = m[? "console"];
	        var _count = ds_list_size(_items);
        
	        var _item, _info, _text;
	        var _memCur = 0;
	        var _memAcc = 0;
	        var _memMax = ds_list_size(ds_map_find_value(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "memoryCollected"));
	        script_execute(0,LABEL.Console_Write, _console, "Hello again, ^10[[INSTANCE]]^3c.", 2, 0, 48, 1);
	        for (i = 0; i < _count; i++)
	        {
	            _item = _items[| i];
	            _info = _itemData[? _item];
	            _text = "^3c  ";
	            if (_selection == i) _text = "^26> ";
	            script_execute(0,LABEL.Console_Write, _console, _text + _info[? "name"], 0, 3 + 4 * i, 50, 1);
            
	            if (_installed[? _item] > 0) { _text = "   ENABLED (" + string(ds_list_find_value(_info[? "memory"], 0)) + ")"; _memAcc += ds_list_find_value(_info[? "memory"], 0); }
	            else _text = "  DISABLED (0)";
            
	            if (_installed[? _item] > 0) script_execute(0,LABEL.Console_Write, _console, "^1b" + _text, 50 - string_length(_text), 3 + 4 * i, string_length(_text), 1);
	            else script_execute(0,LABEL.Console_Write, _console, "^38" + _text, 50 - string_length(_text), 3 + 4 * i, string_length(_text), 1);
            
	            script_execute(0,LABEL.Console_Write, _console, _info[? "description"], 2, 4 + 4 * i, 48, 2);
	        }
        
	        if (_selection == _count) script_execute(0,LABEL.Console_Write, _console, "^26> Build", 0, 3 + 4 * _count, 50, 1);
	        else script_execute(0,LABEL.Console_Write, _console, "^3c  Build", 0, 3 + 4 * _count, 50, 1);
        
	        if (_memAcc > _memMax) _text = "^0b";
	        else _text = "^1b";
	        _text += "MEMORY: " + string(_memAcc) + "/" + string(_memMax);
        
	        m[? "ok"] = _memAcc <= _memMax;
	        script_execute(0,LABEL.Console_Write, _console, _text, 2, 1, 48, 1);
	        break;
        
	    case LABEL.Window_BuildUpdate:
	        var m = argument[1];
	        var _count = ds_list_size(m[? "items"]);
	        var _selection = m[? "selection"];
	        var _selected = script_execute(0,LABEL.Miscellaneous_Selection, ds_map_find_value(MEMORY[? "stepState"], "keypress"), m, _count+1, _count, false);
	        if (_selection != m[? "selection"]) script_execute(0,LABEL.Window_BuildRefresh, m);
	        if (_selected > -1)
	        {
	            if (_selected == _count)
	            {
	                if (m[? "ok"]) { script_execute(0,LABEL.Save_SaveGame); script_execute(0,LABEL.Controller_Pop); }
	                else { script_execute(0,LABEL.Window_InformMake, true, "^0bERROR#^3cNot enough memory to install all these modules.", undefined, undefined, 40, -1, -1); } 
	            }
	            else
	            {
	                var _item = ds_list_find_value(m[? "items"], _selected);
	                var _modules = ds_map_find_value(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "modulesInstalled"); 
	                _modules[? _item] = 1 - _modules[? _item];
	                script_execute(0,LABEL.Window_BuildRefresh, m);
	            }
	        }
	        break;
        
	    case LABEL.Window_BuildDraw:
	        var m = argument[1];
	        var _x = m[? "x"];
	        var _y = m[? "y"];
	        var _console = m[? "console"];
	        var _w = ds_grid_width(_console);
	        var _h = ds_grid_height(_console);
        
	        var _sprite = m[? "sprite"];
	        var _spritew = 32;
        
	        var _rectw = 8 * 51 + _spritew;
	        var _recth = 12 * ds_grid_height(_console) + 12;
        
	        draw_set_alpha(1);
	        draw_set_color(m[? "back"]);
	        draw_rectangle(_x, _y, _x + _rectw - 1, _y + _recth - 1, false);
	        draw_set_color(m[? "frame"]);
	        draw_rectangle(_x, _y, _x + _rectw - 1, _y + _recth - 1, true);
        
	        script_execute(0,LABEL.Console_Draw, _x + 4 + _spritew, _y + 6, _console, 0, 0);
        
	        var _itemData = ds_map_find_value(MEMORY[? "gameData"], "items");
	        var _items = m[? "items"];
	        var _count = ds_list_size(m[? "items"]);
	        for (i = 0; i < _count; i++)
	        {
	            draw_sprite(_sprite, ds_map_find_value(_itemData[? _items[| i]], "icon"), _x + 4, _y + 42 + 48 * i);
	        }
	        break;
        
	    case LABEL.Window_BuildDestroy:
	        var m = argument[1];
	        ds_grid_destroy(m[? "console"]);
	        break;
	    }
	    exit;
 
	/***********************
	 * CODEMAP SHENANIGANS *
	 ***********************/
	case LABEL.Codemap:
    
	    switch (_script)
	    {
	    case LABEL.Codemap_Init:
	        var _data = MEMORY[? "gameData"];
	        var _codemaps = ds_map_create();
	        ds_map_add_map(_data, "codemaps", _codemaps);
        
	        var _map = ds_map_create();
	        ds_map_add_map(_codemaps, "terminal", _map);
	        _map[? "jump"] = LABEL.Codemap_Jump;
        
	        _map[? "info"] = LABEL.Window_InformFromProcess;
	        _map[? "choice"] = LABEL.Window_ChoiceFromProcess;
	        _map[? "rename"] = LABEL.Window_NameFromProcess;

	        var _map = ds_map_create();
	        ds_map_add_map(_codemaps, "explore", _map);
	        _map[? "explore"] = LABEL.Explorer_Make;
	        exit;
    
	    case LABEL.Codemap_Process:
	        var _process = script_execute(0,LABEL.Object_Make);
        
	        if (is_string(argument[1])) _process[? "codemap"] = ds_map_find_value(ds_map_find_value(MEMORY[? "gameData"], "codemaps"), argument[1]);
	        else _process[? "codemap"] = argument[1];
	        _process[? "tree"] = argument[2];
	        if (argument[2] == -1 || !is_string(argument[3])) _process[? "branch"] = argument[3];
	        else _process[? "branch"] = ds_map_find_value(argument[2], argument[3]);
	        _process[? "position"] = 0;
	        if (argument_count > 4) ds_map_add_map(_process, "data", argument[4]);
	        else _process[? "data"] = ds_map_add_map(_process, "data", ds_map_create());
        
	        _process[? "update"] = LABEL.Codemap_UpdateProcess;
	        _process[? "onResume"] = LABEL.Codemap_UpdateProcess;
        
	        script_execute(0,LABEL.Controller_Push, _process);
	        script_execute(0,LABEL.Codemap_UpdateProcess, _process);
        
	        exit;
        
	    case LABEL.Codemap_UpdateProcess:
	        var _process = argument[1];
	        var _codemap = _process[? "codemap"];
	        var _branch, _position;
        
	        while (_process[? "focus"])
	        {
	            // the values are refreshed every iteration
	            // in case one of commands involved jumping to another branch
	            _branch = _process[? "branch"];
	            _position = _process[? "position"];
            
	            // getting off the process
	            if (_position >= ds_list_size(_branch))
	            {
	                script_execute(0,LABEL.Controller_Pop);
	                exit;
	            }
            
	            _value = _branch[| _position];
	            _process[? "position"]++;
            
	            // if the value is string, it's a label to be omitted
	            if (!is_string(_value)) script_execute(0,_codemap[? _value[? ">"]], _value, _process);
	        }
	        exit;
        
	    // Codemap process flow commands
	    case LABEL.Codemap_Jump:
	        var _params = argument[1];
	        var _process = argument[2];
        
	        if (ds_map_exists(_params, "branch")) _process[? "branch"] = ds_map_find_value(_process[? "tree"], _params[? "branch"]);
	        _process[? "position"] = 0;
        
	        if (ds_map_exists(_params, "label")) _process[? "position"] = ds_list_find_index(_process[? "branch"], _params[? "label"]) + 1;
	        exit;
        
	    // applying results obtained from modal windows
	    case LABEL.Codemap_ApplyChoice:
	        var _process = argument[1];
	        var _codemap = _process[? "codemap"];
	        var _modal = argument[2];
	        var _data = _process[? "data"];
	        var _choice = ds_list_find_value(_modal[? "choices"], _modal[? "selection"]);
        
	        if (ds_map_exists(_choice, ">")) script_execute(0,_codemap[? _choice[? ">"]], _choice, _process);
        
	        _process[? "onResume"] = LABEL.Codemap_UpdateProcess;
	        script_execute(0,LABEL.Codemap_UpdateProcess, _process);
	        exit;
        
	    case LABEL.Codemap_DoRename:
	        var _process = argument[1];
	        var _modal = argument[2];
        
	        ds_map_replace(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "name", _modal[? "name"]);
        
	        _process[? "onResume"] = LABEL.Codemap_UpdateProcess;
	        script_execute(0,LABEL.Codemap_UpdateProcess, _process);
	        exit;

	    }        
	    exit;

	/*********************************
	 * EVERYONE'S FAVOURITE EXPLORER *
	 *********************************/
	case LABEL.Explorer:
    
	    switch (_script)
	    {
	    // explorer
	    case LABEL.Explorer_Make:
	        var _map = argument[1];
	        var _area = argument[2];
	        var _previous = argument[3];
	        var _perState = ds_map_find_value(MEMORY[? "globalState"], "persistent");
        
	        var e = script_execute(0,LABEL.Object_Make);
	        e[? "update"] = LABEL.Explorer_Update;
	        e[? "drawRequest"] = LABEL.Explorer_DrawRequest;
	        e[? "draw"] = LABEL.Explorer_Draw;
	        e[? "destroy"] = LABEL.Explorer_Destroy;
        
	        var _w = _map[? "width"];
	        var _h = _map[? "height"];
	        var _plane = script_execute(0,LABEL.Explorer_SubMake_BorderGrid, _w, _h);
	        var _walls = script_execute(0,LABEL.Explorer_SubMake_BorderGrid, _w, _h);
	        var _objects = ds_grid_create(_w, _h);
	        ds_grid_clear(_objects, -1);
	        var _collisions = ds_grid_create(_w, _h);
	        ds_grid_clear(_collisions, -1);
        
	        e[? "source"] = _map;
	        e[? "x"] = 8;
	        e[? "y"] = 36;
	        e[? "skin"] = 0;
	        if (ds_map_exists(_map, "skin")) e[? "skin"] = _map[? "skin"];
	        e[? "width"] = _w;
	        e[? "height"] = _h;
	        e[? "plane"] = _plane;
	        e[? "walls"] = _walls;
	        e[? "objects"] = _objects;
	        e[? "collisions"] = _collisions;
        
	        var _name = _map[? "name"];
	        var _console = ds_grid_create(string_length(_name), 1);
	        e[? "name"] = _name;
	        e[? "console"] = _console;
	        script_execute(0,LABEL.Console_Write, _console, script_execute(0,LABEL.Console_Escape, _name), 0, 0, string_length(_name), -1);
        
	        // reading terrain from text
	        var _data = _map[? "terrain"];
        
	        _count = string_length(_data);
	        k = 1;
        
	        var o;
	        for (i = 0; i < _w; i++)
	        for (j = 0; j < _h; j++)
	        {
	            _value = ord(string_char_at(_data, k++)) - 33;
	            _collisions[# i, j] = _value;
            
	            if (_value == -1) continue;
            
	            if (_value < 16)
	            {
	                script_execute(0,LABEL.Explorer_SubMake_Place, _plane, i, j);
	                script_execute(0,LABEL.Explorer_SubMake_Place, _walls, i, j);
	            }
	            else if (_value < 32)
	            {
	                script_execute(0,LABEL.Explorer_SubMake_Place, _plane, i, j);
	                if (j == _h-1)
	                {
	                    script_execute(0,LABEL.Explorer_SubMake_Place, _plane, i, _h);
	                }
	            }
	            else
	            {
	                script_execute(0,LABEL.Explorer_SubMake_Place, _plane, i, j);
	                _objects[# i, j] = _value - 32;
	                switch (_value - 32)
	                {
	                    case 0: if (ds_list_find_index(_perState[? "keysCollected"], _area) > -1) _objects[# i, j] = 15; break;
	                    case 1: if (ds_list_find_index(_perState[? "memoryCollected"], _area) > -1) _objects[# i, j] = 15; break;
                    
	                    case 2: if (ds_list_find_index(ds_map_find_value(_perState[? "modulesCollected"], "repair"), _area) >  -1) _objects[# i, j] = 15; break;
	                    case 3: if (ds_list_find_index(ds_map_find_value(_perState[? "modulesCollected"], "push"), _area) >  -1) _objects[# i, j] = 15; break;
	                    case 4: if (ds_list_find_index(ds_map_find_value(_perState[? "modulesCollected"], "carry"), _area) >  -1) _objects[# i, j] = 15; break;
	                    case 5: if (ds_list_find_index(ds_map_find_value(_perState[? "modulesCollected"], "jump"), _area) >  -1) _objects[# i, j] = 15; break;
	                    case 6: if (ds_list_find_index(ds_map_find_value(_perState[? "modulesCollected"], "flight"), _area) >  -1) _objects[# i, j] = 15; break;
	                    case 7: if (ds_list_find_index(ds_map_find_value(_perState[? "modulesCollected"], "teleport"), _area) >  -1) _objects[# i, j] = 15; break;
                    
	                    case 17:
	                        if (_previous == "") e[? "player"] = script_execute(0,LABEL.Explorer_PlayerMake, e, 24 * i, 24 * (j + 1), 1, 0);
	                        break;
	                }
	                _collisions[# i, j] = _objects[# i, j] + 32;
	            }
	        }
        
	        // placing blocks
	        var _blocks = _map[? "blocks"];
	        var _count = ds_list_size(_blocks);
	        for (i = 0; i < _count; i += 2)
	        {
	            script_execute(0,LABEL.Explorer_SubMake_Place, _plane, _blocks[| i], _blocks[| i+1]);
	            _collisions[# _blocks[| i], _blocks[| i+1]] = 48;
	            _objects[# _blocks[| i], _blocks[| i+1]] = 16;
	        }
        
	        // dealing with endpoints
	        var _endpoints = _map[? "endpoints"];
	        e[? "endpoints"] = _endpoints;
	        _count = ds_list_size(_endpoints);
	        var _keys = _perState[? "keysCollected"];
	        for (i = 0; i < _count; i++)
	        {
	            _value = _endpoints[| i];
	            script_execute(0,LABEL.Explorer_SubMake_Place, _plane, _value[? "x"], _value[? "y"]);
	            if (_value[? "sector"] == _previous)
	            {
	                var _dir = 0 * (_value[? "x"] == 0) + 1 * (_value[? "y"] == _h-1) + 2 * (_value[? "x"] == _w-1) + 3 * (_value[? "y"] == 0);
	                var _dx = (_dir == 0) - (_dir == 2);
	                var _dy = (_dir == 3) - (_dir == 1);
                
	                e[? "player"] = script_execute(0,LABEL.Explorer_PlayerMake, e, 24 * (_value[? "x"] - _dx), 24 * (_value[? "y"] - _dy), _dir, 48);
	            }
            
	            if (ds_list_find_index(_keys, _area) > -1 || ds_list_find_index(_keys, _value[? "sector"]) > -1) _collisions[# _value[? "x"], _value[? "y"]] = 16;
	            else { _collisions[# _value[? "x"], _value[? "y"]] = 50; _objects[# _value[? "x"], _value[? "y"]] = 18; }
	        }

	        e[? "drawPlane"] = script_execute(0,LABEL.Explorer_SubMake_DrawGrid, _plane);
	        e[? "drawWalls"] = script_execute(0,LABEL.Explorer_SubMake_DrawGrid, _walls);
	        e[? "drawObjects"] = ds_grid_create(_w, _h);
        
	        script_execute(0,LABEL.Controller_Push, e);
	        break;
        
	    case LABEL.Explorer_SubMake:
	        switch (_subscript)
	        {
	            case LABEL.Explorer_SubMake_FreeGrid:
	                var _result = ds_grid_create(argument[1] + 2, argument[2] + 3);
	                ds_grid_clear(_result, -1);
	                return _result;
                
	            case LABEL.Explorer_SubMake_BorderGrid:
	                var _w = argument[1];
	                var _h = argument[2];
	                var _result = script_execute(0,LABEL.Explorer_SubMake_FreeGrid, _w, _h);
	                _h++;
                
	                ds_grid_set_region(_result, 0, 1, 0, _h, $7c);
	                ds_grid_set_region(_result, 1, _h+1, _w, _h+1, $f1);
	                ds_grid_set_region(_result, _w+1, 1, _w+1, _h, $c7);
	                ds_grid_set_region(_result, 1, 0, _w, 0, $1f);
                
	                _result[# 0, 0] = $7f;
	                _result[# 1, 0] |= (1 << 5);
	                _result[# 0, 1] |= (1 << 1);
                
	                _result[# 0, _h+1] = $fd;
	                _result[# 1, _h+1] |= (1 << 3);
	                _result[# 0, _h] |= (1 << 7);
                
	                _result[# _w+1, _h+1] = $f7;
	                _result[# _w, _h+1] |= (1 << 1);
	                _result[# _w+1, _h] |= (1 << 5);
                
	                _result[# _w+1, 0] = $df;
	                _result[# _w, 0] |= (1 << 7);
	                _result[# _w+1, 1] |= (1 << 3);
	                return _result;
                
	            case LABEL.Explorer_SubMake_Place:
	                var _grid = argument[1];
	                var _fx = argument[2]+1;
	                var _fy = argument[3]+1;
                
	                _value =  0;
	                if (_grid[# _fx+1, _fy  ] >= 0) { _value += (1 << 0); _grid[# _fx+1, _fy  ] += (1 << 4); }
	                if (_grid[# _fx+1, _fy-1] >= 0) { _value += (1 << 1); _grid[# _fx+1, _fy-1] += (1 << 5); }
	                if (_grid[# _fx  , _fy-1] >= 0) { _value += (1 << 2); _grid[# _fx  , _fy-1] += (1 << 6); }
	                if (_grid[# _fx-1, _fy-1] >= 0) { _value += (1 << 3); _grid[# _fx-1, _fy-1] += (1 << 7); }
	                if (_grid[# _fx-1, _fy  ] >= 0) { _value += (1 << 4); _grid[# _fx-1, _fy  ] += (1 << 0); }
	                if (_grid[# _fx-1, _fy+1] >= 0) { _value += (1 << 5); _grid[# _fx-1, _fy+1] += (1 << 1); }
	                if (_grid[# _fx  , _fy+1] >= 0) { _value += (1 << 6); _grid[# _fx  , _fy+1] += (1 << 2); }
	                if (_grid[# _fx+1, _fy+1] >= 0) { _value += (1 << 7); _grid[# _fx+1, _fy+1] += (1 << 3); }
	                _grid[# _fx, _fy] = _value;
                
	                if (_fy == ds_grid_height(_grid) - 3) script_execute(0,LABEL.Explorer_SubMake_Place, argument[1], argument[2], argument[3]+1);
	                exit;
                
	            case LABEL.Explorer_SubMake_DrawGrid:
	                var _sourceGrid = argument[1];
	                var _w = ds_grid_width(_sourceGrid) - 2;
	                var _h = ds_grid_height(_sourceGrid) - 3;
	                var _drawGrid = ds_grid_create(_w, _h + 1);
	                var _corner, _result;

	                for (i = 1; i <= _w; i++)
	                for (j = 1; j <= _h+1; j++)
	                {
	                    _value = _sourceGrid[# i, j];
	                    if (_value == -1) { _drawGrid[# i-1, j-1] = -1; continue; }
	                    _value *= $101;
                    
	                    _result = 0;
	                    for (k = 0; k < 4; k ++)
	                    {
	                        _corner = (_value >> 2*k) & 7;
	                        switch (_corner)
	                        {
	                            case 0: case 2: _result += 0 << (3*k); break;
	                            case 1: case 3: _result += 1 << (3*k); break;
	                            case 4: case 6: _result += 2 << (3*k); break;
	                            case 5: _result += 3 << (3*k); break;
	                            case 7: _result += 4 << (3*k); break;
	                        }
	                    }
                    
	                    if (((_value >> 6) & 1) == 0) _result += (1 << 14) + (1 << 13) * ((_value >> 4) & 1) + (1 << 12) * (_value & 1);
                    
	                    _drawGrid[# i-1, j-1] = _result;
	                }
	                return _drawGrid;
	        }
	        exit;
        
	    case LABEL.Explorer_Update:
	        var e = argument[1];
	        var p = e[? "player"];
	        script_execute(0,p[? "update"], p);
	        p[? "depth"] = -p[? "y"];
	        exit;
        
	    case LABEL.Explorer_DrawRequest:
	        var e = argument[1];
	        e[? "i"] = 0;
	        var _h = e[? "height"];
	        for (i = 0; i < _h+1; i++) ds_priority_add(argument[2], e, -24 * i);
        
	        ds_grid_copy(e[? "drawObjects"], e[? "objects"]);
	        exit;
        
	    case LABEL.Explorer_Draw:
	        var e = argument[1];
	        var _sprites = ds_map_find_value(MEMORY[? "assets"], "sprites");
        
	        i = e[? "i"];
	        var _x = e[? "x"];
	        var _y = e[? "y"];
	        var _skin = e[? "skin"];
	        var _objects = e[? "drawObjects"];
        
	        if (i == 0) script_execute(0,LABEL.WallConnect_Draw, e[? "drawPlane"], -1, _sprites[? "plane"], _skin, _x, _y + 12, 12);
        
	        script_execute(0,LABEL.WallConnect_Draw, e[? "drawWalls"], _objects, _sprites[? "walls"], _skin, _x, _y, 12, 0, i, 999, i+1);
	        script_execute(0,LABEL.WallConnect_DrawObjects, _objects, _skin, _x, _y, 0, i, 999, i+1);
        
        
	        if (i == e[? "height"])
	        {
	            draw_set_alpha(1);
	            draw_set_color(c_black);
	            draw_rectangle(0, 0, room_width-1, 35, false);
	            draw_rectangle(0, 36, 7, room_height-13, false);
	            draw_rectangle(room_width-8, 36, room_width-1, room_height-13, false);
	            draw_rectangle(0, room_height-12, room_width-1, room_height-1, false);
	            draw_set_color(c_silver);
	            draw_rectangle(7, 35, room_width-8, room_height-12, true);
	            var _console = e[? "console"];
	            script_execute(0,LABEL.Console_Draw, room_width/2 - 4 * ds_grid_width(_console), 12, _console, 0, 0);
	        }
	        e[? "i"]++;
	        exit;
        
	    case LABEL.Explorer_Destroy:
	        var e = argument[1];
	        ds_grid_destroy(e[? "plane"]);
	        ds_grid_destroy(e[? "walls"]);
	        ds_grid_destroy(e[? "objects"]);
	        ds_grid_destroy(e[? "collisions"]);
	        ds_grid_destroy(e[? "drawPlane"]);
	        ds_grid_destroy(e[? "drawWalls"]);
	        ds_grid_destroy(e[? "drawObjects"]);
	        exit;
        
	    /***********
	     * PLAYER *
	     **********/  
	    case LABEL.Explorer_PlayerMake:
	        var p = script_execute(0,LABEL.Object_Make);
	        p[? "update"] = LABEL.Explorer_PlayerExplore;
	        p[? "draw"] = LABEL.Explorer_PlayerDraw;
        
	        p[? "explorer"] = argument[1];
	        p[? "x"] = argument[2];
	        p[? "y"] = argument[3];
	        p[? "depth"] = -argument[3];
	        p[? "dir"] = argument[4];
	        p[? "mov"] = argument[5];
	        p[? "spd"] = ds_map_find_value(MEMORY[? "globalState"], "spd");
	        p[? "abilities"] = ds_map_find_value(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "modulesInstalled");
        
	        return p;
        
	    case LABEL.Explorer_PlayerExplore:
	        var p = argument[1];
	        var e = p[? "explorer"];
	        var _mov = p[? "mov"];
	        var _dir = p[? "dir"];
	        var _keypress = ds_map_find_value(MEMORY[? "stepState"], "keypress");
	        var _keycheck = ds_map_find_value(MEMORY[? "stepState"], "keycheck");
        
	        var _hold = _keycheck & INPUT.Cancel;
        
	        if (_keypress & INPUT.Select)
	        {   
	            p[? "spd"] = 15 - p[? "spd"];
	            ds_map_replace(MEMORY[? "globalState"], "spd", p[? "spd"]);   
	        }
        
	        if (_mov == 0)
	        {
	            if (_keypress & INPUT.Action)
	            {
	                if (!_hold) { script_execute(0,LABEL.Explorer_PlayerTryInteract, p); exit; }
	                else
	                {
	                    var _abilities = p[? "abilities"];
	                    if (_abilities[? "flight"] > 0 || _abilities[? "teleport"] > 0) { p[? "shift"] = script_execute(0,LABEL.Explorer_PlayerDoShift, p, 2*_abilities[? "flight"], 1 + _abilities[? "teleport"]); exit; }
	                }  
	            }
	            if (_keypress & INPUT.Info) { script_execute(0,LABEL.Window_InformMake, true, "Walk around the drive, collect keys and fix two memory leaks.##Use ^0c[[ACTION]]^3c to interact with objects and perform most actions.##Collect modules and assemble them when around Duel Caret to unlock new abilities.##Also, you can use ^0c[[SELECT]]^3c to toggle speed walking!", undefined, undefined, 50, -1, -1); exit; }
	            if (_keypress & INPUT.Menu) { exit; }
        
	            if (_keycheck & INPUT.Right) { p[? "dir"] = 0; if (!_hold) script_execute(0,LABEL.Explorer_PlayerTryMove, p); }
	            if (p[? "mov"] == 0 && _keycheck & INPUT.Up) { p[? "dir"] = 1; if (!_hold) script_execute(0,LABEL.Explorer_PlayerTryMove, p); }
	            if (p[? "mov"] == 0 && _keycheck & INPUT.Left) { p[? "dir"] = 2; if (!_hold) script_execute(0,LABEL.Explorer_PlayerTryMove, p); }
	            if (p[? "mov"] == 0 && _keycheck & INPUT.Down) { p[? "dir"] = 3; if (!_hold) script_execute(0,LABEL.Explorer_PlayerTryMove, p); }
	        }
	        if (_mov > 0)
	        {
	            var _spd = min(_mov, p[? "spd"]);
	            switch (_dir)
	            {
	                case 0: p[? "x"] += _spd; break;
	                case 1: p[? "y"] -= _spd; break;
	                case 2: p[? "x"] -= _spd; break;
	                case 3: p[? "y"] += _spd; break;
	            }
	            p[? "mov"] -= _spd;
	            if (p[? "mov"] == 0) script_execute(0,LABEL.Explorer_PlayerEndMove, p);
	        }
        
	        exit;
        
	    case LABEL.Explorer_PlayerPush:
	        var p = argument[1];
	        exit;
        
	    case LABEL.Explorer_PlayerUpdateShift:
	        var p = argument[1];
	        var s = p[? "shift"];
	        var _keypress = ds_map_find_value(MEMORY[? "stepState"], "keypress");
	        var _keycheck = ds_map_find_value(MEMORY[? "stepState"], "keycheck");        
        
	        exit;
        
	    case LABEL.Explorer_PlayerLeave:
	        var p = argument[1];
	        var _mov = p[? "mov"];
	        var _dir = p[? "dir"];

	        if (_mov > 0)
	        {
	            var _spd = min(_mov, p[? "spd"]);
	            switch (_dir)
	            {
	                case 0: p[? "x"] += _spd; break;
	                case 1: p[? "y"] -= _spd; break;
	                case 2: p[? "x"] -= _spd; break;
	                case 3: p[? "y"] += _spd; break;
	            }
	            p[? "mov"] -= _spd;
	        }
	        exit;
        
	    // checks and such
	    case LABEL.Explorer_PlayerTryMove:
	        var p = argument[1];
	        var e = p[? "explorer"];
	        var _x = p[? "x"] div 24;
	        var _y = p[? "y"] div 24;
	        var _dir = p[? "dir"];
	        var _abilities = p[? "abilities"];
	        var _collisions = e[? "collisions"];
        
	        var _dx = (_dir == 0) - (_dir == 2);
	        var _dy = (_dir == 3) - (_dir == 1);
	        var _tryx, _tryy;
        
	        // regular movement or jump attempt
	        for (i = 0; i<= _abilities[? "jump"]; i++)
	        {
	            _tryx = _x + (i+1)*_dx;
	            _tryy = _y + (i+1)*_dy;
	            if (_tryx < 0 || _tryy < 0 || _tryx >= e[? "width"] || _tryy >= e[? "height"]) break;
	            _value = _collisions[# _x + (i+1)*_dx, _y + (i+1)*_dy];
	            if (_value >= 16 && _value < 31)
	            {
	                p[? "mov"] = 24 * (i+1);
	                break;
	            }
	            else if (_value >= 0) break;
	        }
	        exit;
        
	    case LABEL.Explorer_PlayerTryInteract:
	        var p = argument[1];
	        var e = p[? "explorer"];
	        var _x = p[? "x"] div 24;
	        var _y = p[? "y"] div 24;
	        var _w = e[? "width"];
	        var _h = e[? "height"];
	        var _dir = p[? "dir"];
	        var _collisions = e[? "collisions"];
	        var _sprites = ds_map_find_value(MEMORY[? "assets"], "sprites");
        
	        var _abilities = p[? "abilities"];
	        var _hasRepair = _abilities[? "repair"] > 0;
	        var _hasCarry = _abilities[? "carry"] > 0;
	        var _hasFlight = _abilities[? "flight"] > 0;
	        var _hasTeleport = _abilities[? "teleport"] > 0;
        
	        var _area = ds_map_find_value(MEMORY[? "globalState"], "currentArea");
	        var _keys = ds_map_find_value(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "keysCollected");
	        var _memory = ds_map_find_value(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "memoryCollected");
	        var _modules = ds_map_find_value(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "modulesCollected");
        
	        var _dx = (_dir == 0) - (_dir == 2);
	        var _dy = (_dir == 3) - (_dir == 1);
        
	        var _cell = _collisions[# _x + _dx, _y + _dy];
        
	        var _ix = p[? "x"] + e[? "x"] + 24 * _dx;
	        var _iy = p[? "y"] + e[? "y"] + 24 * _dy;
        
	        if (_cell < 0 && (_hasFlight || _hasTeleport)) { p[? "shift"] = script_execute(0,LABEL.Explorer_PlayerDoShift, p, 2*_abilities[? "flight"], 1 + _abilities[? "teleport"]); exit; }
	        else if (_cell < 16 && _hasTeleport) { p[? "shift"] = script_execute(0,LABEL.Explorer_PlayerDoShift, p, 2*_abilities[? "flight"], 1 + _abilities[? "teleport"]); exit; }
	        else if (_cell < 32) exit;
	        else if (_cell < 48)
	        {
	            if (_cell == 47) exit;
	            if (_cell != 33 || _hasRepair)
	            {
	                _collisions[# _x + _dx, _y + _dy] = 47;
	                ds_grid_set(e[? "objects"], _x + _dx, _y + _dy, 15);
	            }
            
	            var _text = undefined;
	            switch (_cell-32)
	            {
	                case 0:
	                    if (!ds_grid_value_exists(e[? "objects"], 0, 0, e[? "width"]-1, e[? "height"]-1, 0))
	                    {
	                        _text = "You have collected all keys!";
	                        if (ds_list_empty(_keys)) _text += "# #Now you can move freely between this and neighbouring nodes.# #Don't forget to make a backup after unlocking new areas!";
	                        ds_list_add(_keys, _area);
                        
	                        for (i = 0; i < _w; i++)
	                        for (j = 0; j < _h; j++)
	                        {
	                            if (_collisions[# i, j] == 50)
	                            {
	                                _collisions[# i, j] = 16;
	                                ds_grid_set(e[? "objects"], i, j, -1);
	                            }
	                        }
	                    }
	                    break;
                
	                // memory
	                case 1:
	                    if (_hasRepair)
	                    {
	                        ds_list_add(_memory, _area);
	                        _text = "You have fixed a memory leak!";
	                        if (ds_list_size(_memory) == 3) _text += "##Those are all leaks so far. Thanks for playing!";
	                    }
	                    else _text = "You cannot fix a memory leak without a memory repair module installed...";
	                    break;
                    
	                // repair
	                case 2:
	                    ds_list_add(_modules[? "repair"], _area);
	                    _text = "You have found a memory repair kit!# #Use it to fix memory leaks so that you can get more memory for your modules.";
	                    break;
                    
	                // push
	                case 3:
	                    ds_list_add(_modules[? "push"], _area);
	                    _text = "You have found a block pushing module!";
	                    break;
	                // carry
	                case 4:
	                    ds_list_add(_modules[? "carry"], _area);
	                    _text = "You have found a block carring module!";
	                    break;
                    
	                // jump
	                case 5:
	                    _text = "You have found a jump module!";
	                    if (ds_list_empty(_modules[? "jump"])) _text += "# #Now go to ^2eDuel Caret^3c to install it.";
	                    ds_list_add(_modules[? "jump"], _area);
	                    break;
	                // flight
	                case 6:
	                    ds_list_add(_modules[? "flight"], _area);
	                    _text = "You have found a flight module!";
	                    break;
	                // teleport
	                case 7:
	                    ds_list_add(_modules[? "teleport"], _area);
	                    _text = "You have found a teleport module!";
	                    break;
	            }
	            if (_text != undefined) script_execute(0,LABEL.Window_InformMake, true, _text, undefined, undefined, 30, _sprites[? "icons"], _cell-32);
	        }
	        else if (_cell == 48)
	        {
	            if (_hasCarry) exit;
	            exit;
	        }
	        else if (_cell == 49)
	        {
	            script_execute(0,LABEL.Save_SaveGame);
	            if (ds_list_empty(_modules[? "jump"])) script_execute(0,LABEL.Window_InformMake, true, "Hello again, ^10[[INSTANCE]]^3c!# #A backup has been made.", undefined, undefined, 30, _sprites[? "portraits"], 0);
	            else script_execute(0,LABEL.Window_BuildMake, e);
	        }
	        else if (_cell == 50)
	        {
	            script_execute(0,LABEL.Window_InformMake, true, "^0b401 - Unauthorised^3c# #Collect all keys to pass.", undefined, undefined, 25, _sprites[? "icons"], 8);
	        }
	        exit;
        
	    // ending the move
	    case LABEL.Explorer_PlayerEndMove:
	        var p = argument[1];
	        var e = p[? "explorer"];
	        var _area = ds_map_find_value(MEMORY[? "globalState"], "currentArea");
	        var _sectorData = e[? "source"];
        
	        var _visited = ds_map_find_value(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "visited");
        
	        if (ds_map_exists(_sectorData, "note") && ds_list_find_index(_visited, _area) == -1)
	        {
	            var _sprites = ds_map_find_value(MEMORY[? "assets"], "sprites");
	            var _note = _sectorData[? "note"];
	            ds_list_add(_visited, _area);
	            if (ds_map_exists(_note, "icon")) script_execute(0,LABEL.Window_InformMake, true, _note[? "text"], undefined, undefined, 40, _sprites[? "icons"], _note[? "icon"]);
	            else script_execute(0,LABEL.Window_InformMake, true, _note[? "text"], undefined, undefined, 40, -1, -1);
	        }
        
	        var _x = p[? "x"] div 24;
	        var _y = p[? "y"] div 24;
	        var _dir = p[? "dir"];
	        var _abilities = p[? "abilities"];
	        var _collisions = e[? "collisions"];
        
	        var _dx = (_dir == 0) - (_dir == 2);
	        var _dy = (_dir == 3) - (_dir == 1);
        
	        var _cell = _collisions[# _x + _dx, _y + _dy];
	        if (_x == 0 || _y == 0 || _x == e[? "width"]-1 || _y == e[? "height"]-1)
	        {
	            p[? "mov"] = 24;
	            p[? "update"] = LABEL.Explorer_PlayerLeave;
            
	            var _endpoints = e[? "endpoints"];
	            _count = ds_list_size(_endpoints);
	            for (i = 0; i < _count; i++)
	            {
	                _value = _endpoints[| i];
	                if (_value[? "x"] == _x && _value[? "y"] == _y)
	                {
	                    ds_map_replace(MEMORY[? "globalState"], "previousArea", _area);
	                    ds_map_replace(MEMORY[? "globalState"], "currentArea", _value[? "sector"]);
	                    ds_map_replace(ds_map_find_value(MEMORY[? "globalState"], "persistent"), "area", _value[? "sector"]);
	                }
	            }
            
	            script_execute(0,LABEL.Transition_Make, LABEL.Step_Explore);
	        }
	        exit;
        
	    case LABEL.Explorer_PlayerDoShift:
	        // whatever
	        break;
        
	    case LABEL.Explorer_PlayerDrawShift:
	        var p = argument[1];
	        var e = p[? "explorer"];
	        var _x = p[? "x"] div 24;
	        var _y = p[? "y"] div 24;
	        var _dir = p[? "dir"];
	        var _abilities = p[? "abilities"];
	        var _collisions = e[? "collisions"];
        
	        var _dx = (_dir == 0) - (_dir == 2);
	        var _dy = (_dir == 3) - (_dir == 1);
        
	        var _cell = _collisions[# _x + _dx, _y + _dy];
	        if (_cell >= 16 && _cell < 31)
	        {
	            p[? "mov"] = 24;
	            exit;
	        }
	        exit;
        
	    case LABEL.Explorer_PlayerDraw:
	        var p = argument[1];
	        var e = p[? "explorer"];
	        var _sprites = ds_map_find_value(MEMORY[? "assets"], "sprites");
        
	        var _x = p[? "x"] + e[? "x"];
	        var _y = p[? "y"] + e[? "y"];
        
	        draw_sprite(_sprites[? "player"], p[? "dir"], _x, _y);
	        exit;
        
	    }
 
  
	/********************************
	 * CONNECTING WALLS AND TERRAIN *
	 ********************************/
	case LABEL.WallConnect:
	    switch (_script)
	    {
	    case LABEL.WallConnect_Draw:
	        var _drawGrid = argument[1];
	        var _objectsGrid = argument[2];
	        var _w = ds_grid_width(_drawGrid);
	        var _h = ds_grid_height(_drawGrid)-1;
        
	        var _sprite = argument[3];
	        var _osprite = ds_map_find_value(ds_map_find_value(MEMORY[? "assets"], "sprites"), "objects");
	        var _offset = 6 * argument[4];
	        var _x = argument[5];
	        var _y = argument[6];
	        var _elevation = argument[7];
	        _y -= _elevation;
        
	        var _mini = max(0, -_x div 24);
	        if (argument_count > 8) _mini = max(_mini, argument[8]);
	        var _minj = max(0, -_y div 24);
	        if (argument_count > 9) _minj = max(_minj, argument[9]);
	        var _maxi = min(_w, (room_width - _x) div 24);
	        if (argument_count > 10) _maxi = min(_maxi, argument[10]);
	        var _maxj = min(_h+1, (room_height - _y) div 24);
	        if (argument_count > 11) _maxj = min(_maxj, argument[11]);
        
	        for (i = _mini; i < _maxi; i++)
	        for (j = _minj; j <_maxj; j++)
	        {
	            _value = _drawGrid[# i, j];
	            if (_value < 0) continue;
            
	            draw_sprite_part(_sprite, _offset + _value & 7, 12, 0, 12, 12, _x + 12 + 24 * i, _y + 24 * j);
	            draw_sprite_part(_sprite, _offset + (_value >> 3) & 7, 0, 0, 12, 12, _x + 24 * i, _y + 24 * j);
	            draw_sprite_part(_sprite, _offset + (_value >> 6) & 7, 0, 12, 12, 12, _x + 24 * i, _y + 12 + 24 * j);
	            draw_sprite_part(_sprite, _offset + (_value >> 9) & 7, 12, 12, 12, 12, _x + 12 + 24 * i, _y + 12 + 24 * j);
            
	            if (_objectsGrid == -1 || j == _h) continue;
	            _value = _objectsGrid[# i, j];
	            if (_value >= 0) draw_sprite(_osprite, _value, _x + 24 * i, _y + 24 * j);
	            _objectsGrid[# i, j] = -1;
	        }
	        if (_elevation == 12)
	        {
	            for (i = _mini; i<_maxi; i++)
	            for (j = _minj; j<_maxj; j++)
	            {
	                _value = _drawGrid[# i, j];
	                if (_value < 0) continue;
                
	                if ((_value >> 14) & 1)
	                {
	                    draw_sprite_part(_sprite, _offset + 5, 12, 12 * ((_value >> 12) & 1), 12, 12, _x + 12 + 24 * i, _y + 24 + 24 * j);
	                    draw_sprite_part(_sprite, _offset + 5, 0, 12 * ((_value >> 13) & 1), 12, 12, _x + 24 * i, _y + 24 + 24 * j);
	                }
	            }
	        }
	        else if (_elevation > 0)
	        {
	            for (i = _mini; i<_maxi; i++)
	            for (j = _minj; j<_maxj; j++)
	            {
	                _value = _drawGrid[# i, j];
	                if (_value < 0) continue;
            
	                if ((_value >> 14) & 1)
	                {
	                    if (_elevation > 1)
	                    {
	                        draw_sprite_part(_sprite, _offset + 5, 12, 12 * ((_value >> 12) & 1), 12, _elevation-1, _x + 12 + 24 * i, _y + 24 + 24 * j);
	                        draw_sprite_part(_sprite, _offset + 5, 0, 12 * ((_value >> 13) & 1), 12, _elevation-1, _x + 24 * i, _y + 24 + 24 * j);
	                    }
	                    draw_sprite_part(_sprite, _offset + 5, 12, 11 + 12 * ((_value >> 12) & 1), 12, 1, _x + 12 + 24 * i, _y + 24 + _elevation-1 + 24 * j);
	                    draw_sprite_part(_sprite, _offset + 5, 0, 11 + 12 * ((_value >> 13) & 1), 12, 1, _x + 24 * i, _y + 24 + _elevation-1 + 24 * j);
	                }
	            }
	        }
	        break;
        
	    case LABEL.WallConnect_DrawObjects:
	        var _objectsGrid = argument[1];
	        var _w = ds_grid_width(_objectsGrid);
	        var _h = ds_grid_height(_objectsGrid);
        
	        var _osprite = ds_map_find_value(ds_map_find_value(MEMORY[? "assets"], "sprites"), "objects");
	        var _offset = 6 * argument[2];
	        var _x = argument[3];
	        var _y = argument[4];
        
	        var _mini = max(0, -_x div 24);
	        if (argument_count > 5) _mini = max(_mini, argument[5]);
	        var _minj = max(0, -_y div 24);
	        if (argument_count > 6) _minj = max(_minj, argument[6]);
	        var _maxi = min(_w, (room_width - _x) div 24);
	        if (argument_count > 7) _maxi = min(_maxi, argument[7]);
	        var _maxj = min(_h, (room_height - _y) div 24);
	        if (argument_count > 8) _maxj = min(_maxj, argument[8]);
        
	        for (i = _mini; i < _maxi; i++)
	        for (j = _minj; j < _maxj; j++)
	        {
	            _value = _objectsGrid[# i, j];
	            if (_value >= 0) draw_sprite(_osprite, _value, _x + 24 * i, _y + 24 * j);
	        }
	        break;
	    }
 
	/*************************
	 * FILESYSTEM OPERATIONS *
	 *************************/
	case LABEL.File:

	    switch (_script)
	    {
	    // scavenged Data Toolkit code
	    case LABEL.File_ReadAllText:
	        var _file = file_text_open_read(argument[1]);
	        if (_file == -1) return argument[2];                // couldn't read the file
	        if (file_text_eof(_file)) return "";                // the file is empty
        
	        // reading the first line of the file
	        var _result = "";
	        while (!file_text_eof(_file) && !file_text_eoln(_file))
	        {
	            _result += file_text_read_string(_file);
	        }
        
	        // reading the remaining lines, if such exist
	        while (!file_text_eof(_file))
	        {
	            // advancing to the next line, while adding a newline sequence
	            _result += chr(10);
	            file_text_readln(_file);
            
	            while (!file_text_eof(_file) && !file_text_eoln(_file))
	            {
	                _result += file_text_read_string(_file);
	            }
	        }
        
	        // returning the read contents of the file
	        return _result;
    
	    // that, too, is scavenged Data Toolkit code
	    case LABEL.File_WriteAllText:
	        var _file = file_text_open_write(argument[1]);
	        if (_file == -1) return false;
        
	        // writing to the file, if successfully opened for writing
	        file_text_write_string(_file, argument[2]);
	        file_text_close(_file);
        
	        // yay
	        return true;
	        exit;
    
	    // that is NOT scavenged Data Toolkit code
	    case LABEL.File_LoadAsset:
	        var _filename = "a" + argument[1];
	        var _section = argument[2];
	        var _totalSections = script_execute(0,LABEL.File_PassIncludedFile, string_delete(_filename, 1, 1), -1);
        
	        // the last section has been read, which means the asset can be now created from written file
	        if (_section == _totalSections)
	        {
	            var _type = argument[3];
	            switch (_type)
	            {
	                case asset_sprite: return sprite_add(_filename, argument[4], false, false, argument[5], argument[6]);
	                case asset_background: return background_add(_filename, false, false);
	                case asset_sound: return audio_create_stream(_filename);
	                case asset_unknown: return script_execute(0,LABEL.File_ReadAllText, _filename, "");
	            }
	        }
        
	        // otherwise, the asset file is assembled from 12KiB pieces made from reading 16KiB base64 chunks
        
	        // it appears even with megabytes' worth of files the buffer gets parsed and saved within <100ms on my machine
	        // which means on 10 times slower computers it's still giving ~1s between loading one asset and another
	        // and that's pretty acceptable to inform player something is happening when they can't interact with UI yet (except for quitting)
        
	        // so instead of writing to a binary file byte by byte I'll just write to the buffer and save it in a single step
	        // had it not been for that, I'd bother setting up a percentage based loading for larger assets
        
	        var t = get_timer();
        
	        var _last = script_execute(0,LABEL.File_PassIncludedFile, string_delete(_filename, 1, 1), _totalSections - 1);
	        _count = string_length(_last);
	        while (string_char_at(_last, _count) == "=") _count--;
	        _count = (_count div 4) * 3 + _count mod 4 - 1;
	        _count += (_totalSections - 1) * 12288;
        
	        var b = buffer_create(_count, buffer_fixed, 1);
	        while (_section < _totalSections)
	        {
	            buffer_base64_decode_ext(b, script_execute(0,LABEL.File_PassIncludedFile, string_delete(_filename, 1, 1), _section), 12288 * _section);
	            _section++;
	        }
	        buffer_save(b, _filename);
        
	        // if the asset hasn't been properly created yet, -section is passed to inform about the last reached section
	        // a negative number is passed so as not to be mistaken for asset id
	        return -_section;
        
	    case LABEL.File_PassIncludedFile:
	        switch (argument[1])
	        {
	        // for the record, the font has been ripped from Windows command line
	        case "font.png":
	            switch (argument[2])
	            {
	            case -1: return 1;
	            case 0: return "iVBORw0KGgoAAAANSUhEUgAAAQAAAAAkCAYAAABmOOTyAAAFhklEQVR4nO2YjW4dOwiE8/4vvVeqbqotMfAN4LPJiZFQj+1hGH62qvpxXdcH9E8jb9HZ44n4qbYonvKvcB1tP8FX5uFIvPpOdknJkdWW5ejon5rFZIyrv7ogdGir84pjZZXio1jC243/SR71jN6ps6c9pvjq3O53k/onZlLl9mJD/Sp5JUlkpOjVe5ar0tzsvfMRvGJ5qsviabfv3dppb6b4sv2x9dF6iP5IR/Y+NVeEUYmzAla/1YZXFoxoU3JUmmxt15C7bjXcz1ENVHuGy7gjfVM9VfJRPVfwlr3TGq2p/fjy1lmcqYZni0eXx8YrWpXaLDYzdYB0+DSe9u/D/BnhKn30dNs775zFe++VHSIzqHwH3d2bmvNff5XQe2zG472Te2s7ast0RFyqrt1L4eleYTPttDaLi0yJJzpIXWr8ztlkParM+Z/7Vy5epwAFH2E7Q1CaS3GvctK/TD/hmOiz+k60T8yu0sfK+645L30ruRNreVZWHbjHMVFjh1fJ3dVu4zNOGuPx2Hv1PM1HdU7F0/ll790dK3FPJqCxHk90T5czy1Gts8On5u3qXmlXYi2HZ/R9haE6aDzhJ2+Ef2LGXcwY786F3tGcd/XfXPtv8W8548cFHD9+/Dl/XMDx48drnhni+P/Hyiw4u6fx9j2LjYy80/xRnRFvhstyZtyRHvK+0tadnxqvvFnM9DnrX/W8ssoO4d1afPBX5S+ASCwV7+ErZ6Lnw5wn861yRffqB6vkXH143pnm6+rr5ludVzE7dquqr3KOcnp7TPwvj/347QPhm2jQ7oUjH5+XY6o+oqG6cBl3ZN7CqfleGb/iU+67Z1UfOStzrO7VF7z9+Be/U/easbqjDSULNDHkLJ42mNSnDGqFu99l7x7fysjMSL7ovCO+84F0zxFGwSo1dN5crP3gF/8aSPm8Ya3uSENtLBWTxUT83fyeVYdE9FWX43LuohoiPdX+KfH2XembshvkfDkYOgOCUesr79fUfwLaBtlCPaNDIoVF8d45iyfLSnJ1F5T0w7tT+azRfCsM7Z8y78pbplU5exqtTWl/CoOdENr3FT7CqHh1QSvDifR5XPRezdftnxdbzRfVZ62i38tF79WzqkfVF+Wk8QqO8iCvJPSKjTDKmfDbBndqyLR1F3R3P9R8BO/VeDlYJZ+Xi95H+QlHxtfVV+0xxSo8qZMB07MXnw0pi42MDD/L4+mpLFgWGy0k1ZctNKlBqY1+kKu7if5RjfSNaq3MV8GRPnfipb8Ajh8nbu1pPcf1mf1jT4s7fvz4g34/fNrjoo4fP/4avx8+TSW5GrGTXNVYJY7gLIbwW3t8MY5v8btF70qMh8li/jgRoBQ22aRqTDe+i1thJvnf1d+9bjLbCOO93e/t71TXK4vbydXNP6m/w79bx3f131A3qTHCeG/2/gqwX1wVn4nwMK+KJ/qjpnlcWf4ME+XL6vCM9k7RlmEsjvSW5vcw02dl3uSc6Sf7qe4x/W5TrwSRAlcN2jXQlakfn41dYegAMg0RB4md7m93ftEHUc2vzE89q/USvLpvHR/lU5PerdPQyoCV/OpACIY2P+LP4jNtl3MXaSe1RRglXomZmp9y9vStapjcj6g+BUd5sBMQKT7CqEWRfJMLNDHgDHO/U7SSBc60k9oiTCVenVMU363P1pLVQPRlZ3VHK30YcQIixUaYLL57Js1ZmVpjZ4gd/vvd5dxF3CR3hKnEd/ano9/TEfGT9yiHxze1O0q87BRoC89+rxrivWX8WXzGTRdydeflIFp38asfjNp/Er/K53FXMOp+KB+Pp7/6IXqm1khmJ33cxMcJv6Hb5k03czf/Ez2awr6bv13tjwt48eB2DXA3/3fpzU+u8zfONvXHBRw/fvw5/w+zDM2RxLBy/wAAAABJRU5ErkJggg==";
	            default: exit;
	            }
	        case "icons.png":
	            switch (argument[2])
	            {
	            case -1: return 1;
	            case 0: return "iVBORw0KGgoAAAANSUhEUgAAANgAAAAYCAYAAACYyDNZAAAEEklEQVR4nO2aAZKzMAiFe7Q9mkfrzfx3/Y0l+CBAiGk7vhlmttY8ovJJtPt43FL1fD7v+OK4NVmzC+Ddiurb/G8Zta6rKbzKviDW4nlHuCzHMto/8/hvwBzaAHos6xEt2JR9qbKLdRQ4kQLr1Qz/zHOQPd9UrctvLe6R4vdb6Ohv8/gdmuXxs4UKWWM/Lnpx/r7PvtjI/zXXx2oJrYDMAJR7jlHQXxnfhJGNRf7wHJJ7ZYlswGi9Z9W8mmj5eUVG0hswANh2uvVIA4wXqUEiYHQ8KH6YB+S1ALaN+Vle0YDLCxiq96yaFxPyZCVhejLPvNjST4WMAIb245IAqz39nUYFzOi3ZABmKHYkEbC90I+gADAYqn0cgIneO2BaR+P+mqR6H1LzNBltl56E9Kj5ZxRoDPQVIIKQMcCO/YQcHICzX6zTSIB5PBfgS+fN/U+SYGLbpRsP9KeF3wKM/m3whyBLwApdjftLklZqwyBDMHkBO3mCYqdFb/ZROtUJMmdODkA9/3inkQArvssVgDnOLzovor+3gwGFAFNy9QBGa7u35s0JIx3s5EkhIJECGIeMeGcCtgRBmAmY9WeN1tIZ+l/ZwVp5KOQ7ZNxf0uWAcfNIq0TLv1LYUrGHlogCZNKykL6y56oAeNTHmQ1Y2TalgyndBGlGB6s6kQSylLcDsKFLRN6tpMQhbwNgJp8GYK0XG+aXHHtBv+afD1jJE/Wl8+b+ovi9xiCTfwswrz+fp9SthM8ewP4kNZTU7iUB1QPW4Z0E2ObV6GCwcxkgqwp/XSvIRiwRLweMQ2WEzAyYFl7/BkAidHtEAEOQZdR+lSSL2lFLxG0/0q2kZy5rJ6P6asCkQmfb3S852PZWmP1RR0Sgsa5VxnoBO44/samcDEf+1pXawYAH6lw8H4KMqioEAtf/nHOXiFus68mz+HL/qCKADfHXlpwIMAZZD2Dpz11X/JDsfWXe48WXixpkVLzw65z5gBVfU+zz9QI29C3iQP8KMmlJCIDrAUxaIpoGI7ORnQstEbVAYyzeImBGyKgqwNh3PZ0GFRAqNPWYg4BBSctFQTP8xU5Gy0ZZJr4FYO/0L1AeNV9sCN8jyKhagEU7jQcwvjRFsgAm5uD3NiXHbP8DMBIn6FiXiwKG4OpiY/Qzl5iXdCfv0vAYx5cdjecsBJkXMO/cIoBxWK05zQDwojd2mln+UrSevd4CsGJ6deeaApjS6UYKXWzxmBhUHsgs/mKxs+3aM9JV/k24QFfrAUyD6xNXeN1C8ByB4FL2K8rqXpY78Gj/bzmGzFDnRN5HaBE64G+V942W54K0cvZe8Az/kiPyls9zDLP8nzvkVv9bk8UvSLRwPB1gpH/JYd03Mu6T/G9NVuRCfkKMPhef4j9a/wDpsn4+csvDHAAAAABJRU5ErkJggg==";
	            default: exit;
	            }
	        case "objects.png":
	            switch (argument[2])
	            {
	            case -1: return 1;
	            case 0: return "iVBORw0KGgoAAAANSUhEUgAAAcgAAAAwCAYAAACVF+oqAAAGKUlEQVR4nO2djXHqSBAGCcUhOAQycSrKxM7knJnuSeflhmX2f1Ya6/VXNWUbREtoEc2sAN9uhBBCCCGEEEIIIYQQcmq+vr7WGXX2/SKEEEK6s4lsWZYpdb/fkSQhhJDfmSDITWaypOR6LkeQhBBCfnXoIAkhhBAlsoMc7Rq1y8++f4QQQkhX6CAJIYQQJZyDJIQQQpTQQRJCCCFKOAdJCCGEKKGDJIQQQpRwDpIQQghRckQHuS63dUadve8IIYRcOJsg427QsrZ1bDJb7rfFshAkIYSQqQlfLP7PupiWJkirzvFFkDPM/v7+vsKHDx8+fN/8mTlakBadoyrIbT1W9bPzV/jw4cOH757/qHUwkrUlJcj7cquXobJsjyBlh9glyG3HWZQY0EP565/7FarEyC171vbDhw8f/gn8hxy/v7+HSkpyiybIILwaSaaWbRFkLMacKM0EKedsLQZYiqokuJwgl9t9rxyjtJynA2Dd71e5LLY/vGYY2f6a2+fW37P94rVO1X3wNL7w4Tvgm8gx1M87THd2LMgX0WUkmVu2VZA1l5kIUtj3UbEoEaTNAbDuY58vK0FaCSa+vSYvbT3y75bt3293X/6vQcEfOb7w4Xvgx3Ls/diF5Gx/b+yzz0HmplRzyw8JUspRStLDAyg80+YkKQWpLdcn+PpOr4Zfy1sMBJmTVev+fwhLilAKLJLZ0zINgkyyfxg54V/tCQ4+/BF+LLYgn9b66wUp5Ri9LfZJkjUCC1IqtRjabeoEk5ZkLMiwXKjWB2hrp1cryBrmIrg9B1hKhjlJlvhP4ioJUun8qgWpMFRxIkj48JP8Kwvy0ClWTYatgnxhKrIqTZPW8lOSLK2zbfvbOz1Pgpx1ALd2kF18TZCZdXnaP/Dhe+F7EOTT+UXxu5UgD3mTjkUH+cIUEpNlIcgUPyXHXkEujSK7uiAP7SBL6+mcwv1NT3Dw4Y/wPQgyiLH24x8tgpRSzMnRxTlIbfo0iCnVQfZMsT5tc2IdqSnd/PaPi8yrILVurvcAntVBymWTIk6tF0HCh+9WkLOmWOPrzAUZd4uxJMN1PQNcI8jRB5DWOabYJf4aCekqgoxfK1gdwLXTnrX8l9c0qW4x8fcVn+Dgwx/hI0gDQWpCjMXYM8BHCTLVOfbwpSSvIMhYiiVJNgsyU638kgCT0hTru9oTHHz4I/zZguzl1dS+/QVBapeXlu0WpCbElgGePcWqPQvHzJKE/yZBpkTVK7DZTxCpqdMXUSpdKoKED/+cDnJGnSrIeFq1Vo6tA2zZQda8AUdbX7yevIB9TbHGcrziAVwUpCbMzFTulfcPfPit/NmC7PnSgZqqEWTttGuXIFNvwrEc4JzULAUZd6w5SZYE+bz98wRZUx4OsKP5DwGmplQVYXrafvjwPfGPEOR2ffxTu0z7OSrIXDULcqRzrBlgbYo1V9ptcoLUplVjAZYk2Sb49k7P6wEWdt9v4KtilMJMTLN63v/w4Z/Bv3IH2VpVguztHD09gErnGnOSbBVka6fXs39yHaPF/o9fm3jna7xYilKc3h6f8OF74R/dQWqVWqbUYe7bL6RmUdWC7JFj7wDHHZ4FP3eeUbu+R5BH7J+cbC34sURKEvPGf+JGXaUlf+bjHz78s/hX6SAtK3sOMpj0yAE+Q5DxMh4FGUuxRpIt/JSschLzxI95NV2qp/GFD/9s/lEdpOz8ZOWur+0gZ9TtKgOcE6Q8d5mq2nOcV9s/8OHDhx//u6vexP8ya2NfpoMMO86q4gGGDx8+fPj++JrgRv9hcu4cpNYxWpyDnD7FOqHgw4cPH75j/ibHz8/PXToWcgysjX2ZDvLt7c204gGGDx8+fPj++EGQQWwjJTlBkJadr9IJI0j48OHDhz+HLwVpVVKQHx8fU4opVvjw4cOHP5WPIAuCDIMQXlmM/pQ7Hz58+PDh++UjyApBhkEQO3Ck1MCHDx8+fF98BNkgyO1VxkiVBhg+fPjw4fvhI0gECR8+fPjwFf4frqkkl/8+grGzEaSDAYYPHz58+H38TWZbLeJjGqNyDIIM2z2jAv8wQW7f1nCbOIcOHz58+PB98YPQgiRHSrKOyvTvYiWEEELIc/4FwHyBdr2ZO28AAAAASUVORK5CYII=";
	            default: exit;
	            }
	        case "plane.png":
	            switch (argument[2])
	            {
	            case -1: return 1;
	            case 0: return "iVBORw0KGgoAAAANSUhEUgAAAJAAAAAYCAYAAAAVpXQNAAABFUlEQVR4nO2aUQ6CQAwFPRo326NxNA0mazBBoNu+SnU+JmtMgNfd5/jDbZ7nu4rW2mudpum5HqHM07OcydAzW/Nb7p/B8qyeXbHelMOoDkDNVubKBVrnj1zfCtS/iGC96dYCRebYy3Z2063XnkVxz0+zpBhI8Qv7JQNVJdVAitAVD6Ni5r1ZMBAFCpsFA1Eg8ywYiAKFzYKBKJB5FgxEgcJmwUAUyDwLBqJALrotFMgLpNiQ6gXNprSBFBtCga5RnmWlQH8ABqJAw2AgCuQGA1GgYTAQBXKDgSjQMBiIArlJMVBrsS+09weMXHeEp0CeeaJQ3XeLNAMpw0fzDQMpDJ2F3EDLh6tgOYCRAo3mqfQX75nXygPwtLF6CyHAsQAAAABJRU5ErkJggg==";
	            default: exit;
	            }
	        case "player.png":
	            switch (argument[2])
	            {
	            case -1: return 1;
	            case 0: return "iVBORw0KGgoAAAANSUhEUgAAAGAAAAAkCAYAAAB2UT9CAAAA1UlEQVR4nO2YUQrDIBAF92g9mjdPKbT5EAvRromTzgN/gox5Pl1NIpRSSiml1FtbiW2kyU/gvzqWR5SRdmQQ+YsZ+KyOFqvVd7X3vzSAepJ6DdRb9MjzEf4tA2hN0koBfGMYwEkl6PYBZJSgGQb+pgStaoDOxxug8y1BlACyDuFZAZx1CGdfIgyg4/1nXKMtQaQAMrYwnX9ZCaJMEI0f9fbpbfJ//CVNX0F0Pt4AnY83QOfjDdD5eAN0Pt4AnY83QOfjDdD5eAN0/j7IlK88+UoppdSuJ32UQwdz7xpIAAAAAElFTkSuQmCC";
	            default: exit;
	            }
	        case "portraits.png":
	            switch (argument[2])
	            {
	            case -1: return 1;
	            case 0: return "iVBORw0KGgoAAAANSUhEUgAAAMAAAAAwCAYAAABHTnUeAAAB30lEQVR4nO2cSW7EMAwE/bQ8bX6Wp01OyWHgTWrSZEdVgE7ByNUiKQM+ZNsAAAAAAAAAAAAA1uHrtb0dFv74h/tXS6khqn3wr3dS/P8CfL9frddVAar98K93nPG3D4A//oq/fQD88Vf87QPgj7/ibx8Af/wVf/sA1f6fXxnc/LPOvyrXlc/UAGSHGXHo1EBHn9oU/6M9R54143y1/+wAPFWfq+dND0B2ENcbdPTmW20AXPrnNMDRIWQ1kcMNeucc9v4+e4NGN8zs/uoFFD0Io/sND0B2YVxvUAZgbgCiBmH290MDMFPgbg2UvbIGOOqM1Rqo/tENrP7+9gCMvlKyDv7Iq8sA7BXjzGX1AYh48yr7Db0BOq6OAzBSiFUHILrxo8+/vIGyC9BlrTYA2Y0/+jwGAP9H/atyMQBNF/49/e0D4I+/4m8fAH/8FX85wN3fRz0H/14N5O4fEuDuJ6iuBXD3r2wgd/+wANlfA7IL4O5f1UDu/qEBPvfK2Bv/Xg3k7h8e4He/rH3xP/e9Wvg/MMGZe+Lfq4Hc/e1fYfjjr/jbB8Aff8XfPgD++Cv+9gHwx1/xtw+AP/6Kv30A/PFX/O3/vXW1D/71Toq/VYhdefzxF/0BAAAAAAAAAAAA/iE/F3a3t+nC9+sAAAAASUVORK5CYII=";
	            default: exit;
	            }
	        case "walls.png":
	            switch (argument[2])
	            {
	            case -1: return 1;
	            case 0: return "iVBORw0KGgoAAAANSUhEUgAAAJAAAAAYCAYAAAAVpXQNAAABCklEQVR4nO2VUQ7CMAxDe7QdbTfjaAMidZomAQ2NqzZ6HyYIaZ29vJmyP45Dpe31UWfZdpu/pPRTvbR4qJ69/j3nj9D7XtW7YhZlGNUCRjz0u+eVAZLBcwXo/CFAPQBF+vjmrfWhe69tleLMT1mGNJDiDcvUQKvqnkXaQACUEyAaCIDCstBAAOTOQgMBUFgWGgiA3FloIAAKy0IDAZA7Cw0EQF0620IhNUDqBWdbtgog1QSg5FLCYxOA8osGAqAp4bEJQPlFAwHQlPDYBKD8ooEAaEp4bAJQfg1poLqYKF0X7L1OCVBPnsgXQHHuaHhsKkNkaiBFQ4+SvIHsyyRSA/Svn5X+4nvyevUEyhLHzN9KznYAAAAASUVORK5CYII=";
	            default: exit;
	            }
	        }
	        exit;
	    }
	    exit;
    
	/********************************************
	 * SMALL FUNCTIONS NOT PARTICULARLY RELATED *
	 ********************************************/
	case LABEL.Miscellaneous:
    
	    switch (_script)
	    {
	    case LABEL.Miscellaneous_Selection:
	        var _keypress = argument[1];
	        var _selectionSource = argument[2];
	        var _maxSelection = argument[3];
	        var _cancelOption = argument[4];
	        var _twoStepCancel = argument[5];
	        if (_keypress & INPUT.Up) _selectionSource[? "selection"] = (_selectionSource[? "selection"] + _maxSelection - 1) mod _maxSelection;
	        if (_keypress & (INPUT.Down | INPUT.Select)) _selectionSource[? "selection"] = (_selectionSource[? "selection"] + 1) mod _maxSelection;
	        if ((_keypress & INPUT.Cancel) && _cancelOption > -1)
	        {
	            if (_selectionSource[? "selection"] == _cancelOption) return _cancelOption;
	            _selectionSource[? "selection"] = _cancelOption;
	            if (!_twoStepCancel) return _cancelOption;
	        }
	        if (_keypress & (INPUT.Action | INPUT.Start)) return _selectionSource[? "selection"];
	        return -1;
	    }
	    exit;
    
	/*****************************
	 * CLEANING UP ALL THAT MESS *
	 *****************************/
	case LABEL.Close:
	    audio_stop_all();

	    var _assets = MEMORY[? "assets"];
	    background_delete(_assets[? "font"]);
    
	    var _collection = _assets[? "bgm"];
	    for (k = ds_map_find_first(_collection); !is_undefined(k); k = ds_map_find_next(_collection, k))
	    {
	        audio_destroy_stream(_collection[? k]);
	    }
    
	    game_end();
	    exit;
	}




}
