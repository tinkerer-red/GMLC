function Galladhan() {
	//show_debug_overlay(1);
	__background_set_showcolour( false );
	texture_set_interpolation(0);
	randomize();

	//DECLARE ALL VARIABLES
	var grid, has_drawn, grid_width, grid_height, seed, size, player, bullet;
	var PlayerBuffer, GridBuffer, SoundBuffer, CounterBuffer, BulletBuffer, IntroBuffer;
	var size, octaves, scale, persistence;
	var world_init, grid_init, counter_init, player_init, sound_init, room_init, bullet_init;
	var rate, hertz, hertz2, samples, soundId, bulletSound;

	//GRID VARS
	grid_width      = World.WIDTH/World.CELL_SIZE;
	grid_height     = World.HEIGHT/World.CELL_SIZE;
	size            = grid_width;
	seed            = 1000000;

	//PLAYER AND POINTS VARS
	player          = 0;
	bullet          = 0;
	bulletSound     = 0;

	//BUFFERS VARS
	GridBuffer      = 0;
	PlayerBuffer    = 0;
	SoundBuffer     = 0;
	CounterBuffer   = 0;
	BulletBuffer    = 0;
	IntroBuffer     = 0;

	//INIT VARS
	world_init      = file_exists("Save.ini");
	has_drawn       = file_exists("Drawn.ini");
	grid_init       = file_exists("Grid_Check.ini");
	player_init     = file_exists("Player_Check.ini");
	sound_init      = file_exists("Sound_Check.ini");
	bullet_init     = file_exists("Bullet_Check.ini");
	room_init       = file_exists("Room_Check.ini");

	//SOUNDS VARS
	soundId         = 0;
	rate            = 11025;
	hertz           = irandom_range(80, 400);
	hertz2          = 113;
	samples         = 68;

	//ENUMS
	enum World {
	    GRID_WIDTH  = 64,
	    GRID_HEIGHT = 48,
	    CELL_SIZE   = 16,
	    WIDTH       = World.GRID_WIDTH  * World.CELL_SIZE,
	    HEIGHT      = World.GRID_HEIGHT * World.CELL_SIZE
	}

	enum Colors {
	    WHITE       = c_white,
	    GREEN       = c_green,
	    RED         = c_red,
	    BLACK       = c_black,
	    BLUE        = c_blue,
	    ORANGE      = c_orange,
	    YELLOW      = c_yellow

	}

	if (!room_init){
	        __background_set_colour( c_black );
	        __background_set_showcolour( true );
        
	        var row_8, row_9, row_10, row_14, row_15, row_16;
	        var gridIntro;
	        gridIntro = 0;
        
	        row_8 = "00001101010111011101110101101000";
	        row_9 = "00001001110101010100100101011000";
	        row_10 = "00011001010111011100100101001000";
        
        
	        row_14 = "00000000110111011101110000000000";
	        row_15 = "00000000100010010101110000000000";
	        row_16 = "00000001100010010101001000000000";
    
	        if !ds_exists(0, ds_type_grid){
	            gridIntro = ds_grid_create(32,24);
	            ds_grid_clear(gridIntro, 0);
          
	            if !(IntroBuffer){
	                IntroBuffer = buffer_create(65536, buffer_fixed, 8);
	            }
	            buffer_seek (IntroBuffer, buffer_seek_start, 0);
	            buffer_write(IntroBuffer, buffer_u64, gridIntro);
	        }
        
	         buffer_seek(IntroBuffer, buffer_seek_start, 0);
	         gridIntro = buffer_read(IntroBuffer, buffer_u64);
        
	        for (var a=0; a<32; a++){
	            var read_string = string_char_at(row_8, a+1);
	            if read_string == "1"
	                gridIntro[# a, 8] = 1
	        }
        
	        for (var a=0; a<32; a++){
	            var read_string = string_char_at(row_9, a+1);
	            if read_string == "1"
	                gridIntro[# a, 9] = 1
	        }
        
	        for (var a=0; a<32; a++){
	            var read_string = string_char_at(row_10, a+1);
	            if read_string == "1"
	                gridIntro[# a, 10] = 1
	        }
        
	        for (var a=0; a<32; a++){
	            var read_string = string_char_at(row_14, a+1);
	            if read_string == "1"
	                gridIntro[# a, 14] = 1
	        }
        
	        for (var a=0; a<32; a++){
	            var read_string = string_char_at(row_15, a+1);
	            if read_string == "1"
	                gridIntro[# a, 15] = 1
	        }
        
	        for (var a=0; a<32; a++){
	            var read_string = string_char_at(row_16, a+1);
	            if read_string == "1"
	                gridIntro[# a, 16] = 1
	        }
        
	        for (var a=0; a<32; a++)
	        for (var b=0; b<24; b++){
	        var get_cell = ds_grid_get(gridIntro, a, b);
	        var rand_rgb_color4  = make_colour_rgb(random(255), random(255), random(255));
	        if get_cell == 1{
                
	                draw_rectangle_color(a*32, b*32, a*32+32, b*32+32, rand_rgb_color4, rand_rgb_color4, rand_rgb_color4, rand_rgb_color4, true);
	                draw_rectangle_color(a*32+8, b*32+8, a*32+32-8, b*32+32-8, rand_rgb_color4, rand_rgb_color4, rand_rgb_color4, rand_rgb_color4, false);
	            }
	            else{
	                draw_rectangle_color(a*32, b*32, a*32+32, b*32+32, Colors.BLACK, Colors.BLACK, Colors.BLACK, Colors.BLACK, true);
	                }
	        }
	        if keyboard_check_pressed(vk_anykey) && !keyboard_check_pressed(vk_escape){
	                    ini_open("Room_Check.ini");
	                    ini_write_string("Game", "Started", "True");
	                    ini_close();
	                    ds_grid_clear(gridIntro, 0);
	                    ds_grid_destroy(gridIntro);
	                    buffer_delete(IntroBuffer);
	        }
	        else if keyboard_check_pressed(vk_escape){
	                    ds_grid_destroy(gridIntro);
	                    buffer_delete(IntroBuffer);
	                    game_end();
	        }
	}
	else{
	        //#**************************************************************************************************************************************************************
	        //CREATE GRID WORLD AND SAVE
	        if (!world_init) {
	                //---------> HUDER CODE! <-------------------------------------------------------------------------------------------------------------------------------
	                octaves         = irandom(16); //8;
	                scale           = irandom(4);//2;
	                persistence     = random(2);//1.75;
	                randomize();
                
	                var vRawNoise, vS, vO, vSc, bPer;
        
	                var vS          = max(4, size);
	                var vO          = max(1, octaves);
	                var vSc         = max(1, scale);
	                var vPer        = max(0.01, persistence);
	                var vRawNoise   = surface_create(vS, vS);
	                var valueNoise  = surface_create(vS, vS);
        
	                surface_set_target(vRawNoise);
	                draw_clear_alpha( 0, 1 );
                
	                for (var i = 0; i < vS; i++)
	                for (var j = 0; j < vS; j++){
	                draw_point_color(i, j, make_color_hsv(0, 0, random(255)));               
	                }
                
	                surface_reset_target();
        
	                draw_set_blend_mode(bm_add);
	                surface_set_target(valueNoise);
	                draw_clear_alpha( 0, 1 );
	                var vAmplitude = vPer, vTotalAmplitude = 0;
	                for (var i = 1; i <= vO; i++){
	                    vAmplitude *= vPer;
	                    vTotalAmplitude += vAmplitude;
	                }
            
	                vAmplitude = vPer;   
	                for (var i = 1; i <= vO; i++){
	                    var vPos, vScale2, vColor;
	                    vScale2 = vSc*(1<<(i-1));
	                    vPos = -(vS*vScale2)/2+vS/2;
	                    vAmplitude *= vPer;
	                    vColor = (255*vAmplitude)/vTotalAmplitude;
	                    draw_surface_ext(vRawNoise, vPos+random_range(-0.5*vS*(i-1),
	                                        0.5*vS*(i-1)), vPos+random_range(-0.5*vS*(i-1),
	                                            0.5*vS*(i-1)), vScale2, vScale2, 0,
	                                                make_color_hsv(0, 0, vColor), 1);
	                }
	                surface_reset_target();
	                draw_set_blend_mode(bm_normal);
	                surface_free(vRawNoise);
	                var surfaceNoise = valueNoise;
	                //<<<<<<<<<<<<<<<<<<<---HUDER CODE END--->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                
	                var col;
	                for (var i=0; i<grid_width; i++){
	                        col[i] = surface_getpixel(surfaceNoise, i, 0);
	                }
                
	                grid = ds_grid_create(grid_width, grid_height);
	                ds_grid_clear(grid, noone);
	                for (var a=1; a<grid_width-1; a++)
	                for (var b=grid_height/2; b<(grid_height/2)+1; b++){
                
	                        ds_grid_set(grid, a, b+floor((col[a]/seed)-3), 1);
	                }
                
	                for (var a=1; a<grid_width-1; a++)
	                for (var b=(grid_height/2)+1; b<grid_height-1 ; b++){
	                        var get_cell       = ds_grid_get(grid, a, b);
	                        var get_cell_above = ds_grid_get(grid, a, b-1);
	                        var get_cell_below = ds_grid_get(grid, a, b+1);
	                        var get_cell_right = ds_grid_get(grid, a-1, b);
	                        var get_cell_left  = ds_grid_get(grid, a+1, b);
                    
	                        if get_cell == noone && get_cell_above == 1{
	                                ds_grid_set(grid, a, b, 2);
                        
	                        }
                        
	                        if get_cell == noone && get_cell_above == 2{
	                                ds_grid_set(grid, a, b, 2);
	                        }
                        
	                }
                
	                if ds_exists(0, ds_type_map){
                        
	                            repeat(player[? "level"]){
	                                if get_cell == noone{
	                                    ds_grid_set(grid, irandom_range(grid_width/3, grid_width-1), irandom_range(1, grid_height/2+1), 3);
	                                }
	                            }
	                }
                
	                surface_free(surfaceNoise);   
	                surface_free(vRawNoise);   
              
	               //SAVE
	                ini_open("Save.ini");
	                ini_write_string("Save", "Grid", ds_grid_write(grid));
	                ini_close();
	                ds_grid_destroy(grid);
                
	        }
	        //#*******************************************************************************************************************************************************
	        //LOAD WORLD
	        else{               
	            //INIT EVERYTHING
	            if (!grid_init){
                    
	                    //LOAD WORLD DATA
	                    ini_open("Grid_Check.ini");
	                    ini_write_string("Grid", "Checked", "True");
	                    ini_close();
                    
	                    grid = ds_grid_create(World.GRID_WIDTH, World.GRID_HEIGHT);
	                    ini_open("Save.ini");
	                    ds_grid_read(grid, ini_read_string("Save", "Grid", ""));
	                    ini_close();
                    
	                    if !(GridBuffer){
	                        GridBuffer = buffer_create(65536, buffer_fixed, 8);
	                    }
	                    buffer_seek (GridBuffer, buffer_seek_start, 0);
	                    buffer_write(GridBuffer, buffer_u64, grid);
                
	            }
            
	            if (!player_init){
	                    player = ds_map_create();
	                    player[? "x"] = World.CELL_SIZE;
	                    player[? "y"] = (World.HEIGHT/2)-(World.CELL_SIZE*2);
	                    player[? "bulletx"] = 0;
	                    player[? "bullety"] = (World.HEIGHT/2)-(World.CELL_SIZE*2);
	                    player[? "lives"]   = 4;
	                    player[? "level"]   = 1;
                    
	                    //if !buffer_exists(PlayerBuffer){
	                        PlayerBuffer = buffer_create(32768, buffer_grow, 4);
	                    //}
                    
	                    buffer_seek (PlayerBuffer, buffer_seek_start, 0);
	                    buffer_write(PlayerBuffer, buffer_u32, player[? "x"]);
	                    buffer_write(PlayerBuffer, buffer_u32, player[? "y"]);
	                    buffer_write(PlayerBuffer, buffer_u32, player[? "bulletx"]);
	                    buffer_write(PlayerBuffer, buffer_u32, player[? "bullety"]);
	                    buffer_write(PlayerBuffer, buffer_u32, player[? "lives"]);
	                    buffer_write(PlayerBuffer, buffer_u32, player[? "level"]);
                    
	                    ini_open("Player_Check.ini");
	                    ini_write_real("Player", "X", player[? "x"]);
	                    ini_write_real("Player", "Y", player[? "y"]);
	                    ini_write_real("Player", "X", player[? "bulletx"]);
	                    ini_write_real("Player", "Y", player[? "bullety"]);
	                    ini_close();
                
	            }
            
	            if (!sound_init){
	                    SoundBuffer       = buffer_create(rate, buffer_fast, 1);
	                    ini_open("Sound_Check.ini");
	                    ini_write_real("Sound", "Check", "True");
	                    ini_close();
	            }
        
          
	            //READ FROM BUFFERS
	            buffer_seek(GridBuffer, buffer_seek_start, 0);
	            grid = buffer_read(GridBuffer, buffer_u64);
        
	        //*******************************************************************************************************************************************************   
	            //DRAW WORLD
	            var rand_rgb_color  = make_colour_rgb(random(255), random(255), random(255));
	            var rand_rgb_color2 = make_colour_rgb(random(255), random(255), random(255));
	            var rand_rgb_color3 = make_colour_rgb(random(255), random(255), random(255));
	            var rand_rgb_color5 = make_colour_rgb(random(255), random(255), random(255));
            
	            if has_drawn == false{
	                ini_open("Drawn.ini");
	                ini_write_string("Drawn", "Checked", "True");
	                ini_close();
	                    for (var a=0; a<grid_width; a++)
	                    for (var b=0; b<grid_height; b++){
	                            var get_cell = ds_grid_get(grid, a, b);
                            
	                            if get_cell ==1{
	                                    draw_set_color(rand_rgb_color);
	                                    draw_rectangle(a*World.CELL_SIZE, b*World.CELL_SIZE,
	                                                    (a*World.CELL_SIZE)+World.CELL_SIZE,
	                                                    (b*World.CELL_SIZE)+World.CELL_SIZE, false);
	                            }
                            
                
	                            if get_cell ==2{
	                                    draw_set_color(rand_rgb_color2);
	                                    draw_rectangle(a*World.CELL_SIZE, b*World.CELL_SIZE,
	                                                    (a*World.CELL_SIZE)+World.CELL_SIZE,
	                                                    (b*World.CELL_SIZE)+World.CELL_SIZE, false);
	                            }
                            
	                            if get_cell == 3{
	                                   draw_set_color(rand_rgb_color5);
	                                   draw_rectangle(a*World.CELL_SIZE, b*World.CELL_SIZE,
	                                                    (a*World.CELL_SIZE)+World.CELL_SIZE,
	                                                    (b*World.CELL_SIZE)+World.CELL_SIZE, false);
                                  
	                                   draw_rectangle(a*World.CELL_SIZE, b*World.CELL_SIZE-World.CELL_SIZE,
	                                                    (a*World.CELL_SIZE)+World.CELL_SIZE,
	                                                    (b*World.CELL_SIZE), false);
	                            }
                            
	                            if get_cell == noone{
	                                   // draw_sprite(spr_air, 0, a*World.CELL_SIZE, b*World.CELL_SIZE);
	                                   draw_set_color(rand_rgb_color3);
	                                   draw_rectangle(a*World.CELL_SIZE, b*World.CELL_SIZE,
	                                                    (a*World.CELL_SIZE)+World.CELL_SIZE,
	                                                    (b*World.CELL_SIZE)+World.CELL_SIZE, false);
	                            }
                    
	                    }
	                            has_drawn = true;
	            }
            
	           //REDRAW SKY
	                    for (var a=0; a<grid_width; a++)
	                    for (var b=0; b<grid_height; b++){
	                        var rand_star = make_color_hsv(a, b, irandom(255));
	                        var get_cell = ds_grid_get(grid, a, b);
	                        if get_cell == noone{
	                                   // draw_sprite(spr_air, 0, a*World.CELL_SIZE, b*World.CELL_SIZE);
	                                   draw_set_color(Colors.BLUE);
	                                   draw_rectangle(a*World.CELL_SIZE, b*World.CELL_SIZE,
	                                                    (a*World.CELL_SIZE)+World.CELL_SIZE,
	                                                    (b*World.CELL_SIZE)+World.CELL_SIZE, false);
	                                }
	                        if get_cell == 3{
	                            draw_set_color(rand_star);
	                                   draw_rectangle(a*World.CELL_SIZE, b*World.CELL_SIZE,
	                                                    (a*World.CELL_SIZE)+World.CELL_SIZE,
	                                                    (b*World.CELL_SIZE)+World.CELL_SIZE, true);
                            
	                                     draw_rectangle(a*World.CELL_SIZE+4, b*World.CELL_SIZE+4,
	                                                    (a*World.CELL_SIZE)+World.CELL_SIZE-4,
	                                                    (b*World.CELL_SIZE)+World.CELL_SIZE-4, false);
	                        }
	                    }
        
	        //*******************************************************************************************************************************************************   
	            //DRAW PLAYER
	                    if ds_exists(0, ds_type_map){
	                        draw_set_color(rand_rgb_color);
	                        draw_rectangle(player[? "x"],   player[? "y"],   player[? "x"]   + World.CELL_SIZE, player[? "y"]    + World.CELL_SIZE, true);
	                        draw_rectangle(player[? "x"]+2, player[? "y"]+2, player[? "x"]-2 + World.CELL_SIZE, player[? "y"] -2 + World.CELL_SIZE, true);
	                        draw_rectangle(player[? "x"]+4, player[? "y"]+4, player[? "x"]-4 + World.CELL_SIZE, player[? "y"] -4 + World.CELL_SIZE, true);
	                        draw_rectangle(player[? "x"]+6, player[? "y"]+6, player[? "x"]-6 + World.CELL_SIZE, player[? "y"] -6 + World.CELL_SIZE, true);
                    
	                        draw_set_color(rand_rgb_color2);
	                        draw_rectangle(player[? "bulletx"]+4, player[? "bullety"]+4,   
	                                        player[? "bulletx"] + World.CELL_SIZE-4, player[? "bullety"] + World.CELL_SIZE-4, false);
	                    }
                    
                    
	            //CONTROLS ******************************************************************************************************************************************
	            var key_up          = keyboard_check(ord("W"));
	            var key_left        = keyboard_check(ord("A"));
	            var key_down        = keyboard_check(ord("S"));
	            var key_right       = keyboard_check(ord("D"));
          
	            var key_shoot_right = keyboard_check_pressed(vk_right);
	            var key_shoot_left  = keyboard_check(vk_left);
	            var key_shoot_up    = keyboard_check(vk_up);
	            var key_shoot_down  = keyboard_check(vk_down);
            
	            //BULLET CONTROL
	            if key_shoot_right{
	                if player[? "bulletx"] < player[? "x"]{
	                    //EMITS SOUND
	                    hertz           = irandom_range(70, 90);
	                    buffer_seek(SoundBuffer, buffer_seek_start, 0);
	                    var num_to_write = rate / hertz;
	                    var val_to_write = 1;
	                    for (var i = 0; i < (samples / num_to_write) + 1; i++) {
	                        for (var j = 0; j < num_to_write; j++) {
	                            buffer_write(SoundBuffer, buffer_u8, val_to_write * 255);
	                        }
	                        val_to_write = (1 - val_to_write);
	                    }
	                    soundId = audio_create_buffer_sound(SoundBuffer, buffer_u8, rate, 0, 68, audio_mono);
	                    bulletSound = audio_play_sound(soundId, 10, false);
	                    audio_sound_pitch(bulletSound, random_range(0.1, 0.2));
	                    audio_sound_gain(bulletSound, 1, 0);
                    
	                    while (audio_is_playing(bulletSound)){
	                        //take time
	                    }
                    
	                    audio_stop_sound(bulletSound);
	                    audio_free_buffer_sound(soundId);
	                }
            
	                player[? "bulletx"] += World.CELL_SIZE*2;
	                buffer_seek(PlayerBuffer, buffer_seek_start, 0);
	                buffer_write(PlayerBuffer, buffer_u32, player[? "bulletx"]);
	                buffer_write(PlayerBuffer, buffer_u32, player[? "bullety"]);
	            }
            
            
	            //IF BULLET GOES OUT OF SCREEN...
	            if player[? "bulletx"] > World.WIDTH-World.CELL_SIZE*3
	                player[? "bulletx"] = player[? "x"]-16;
	                buffer_seek (PlayerBuffer, buffer_seek_start, 0);
	                buffer_write(PlayerBuffer, buffer_u32, player[? "bulletx"]);
	                buffer_write(PlayerBuffer, buffer_u32, player[? "bullety"]);
            
	            //PLAYER CONTROL
	            if key_right{   
	                player[? "x"] += World.CELL_SIZE;
	                buffer_seek(PlayerBuffer, buffer_seek_start, 0);
	                buffer_write(PlayerBuffer, buffer_u32, player[? "x"]);
	                buffer_write(PlayerBuffer, buffer_u32, player[? "y"]);
                
	                player[? "bulletx"] += World.CELL_SIZE;
	                buffer_seek(PlayerBuffer, buffer_seek_start, 0);
	                buffer_write(PlayerBuffer, buffer_u32, player[? "bulletx"]);
	                buffer_write(PlayerBuffer, buffer_u32, player[? "bullety"]);
                  
	            }
	            if key_up{
	                    if grid[# (player[? "x"] div World.CELL_SIZE), (player[? "y"] div World.CELL_SIZE) - 1] == noone{
                            
	                            player[? "y"] -= World.CELL_SIZE/2;
	                            buffer_seek(PlayerBuffer, buffer_seek_start, 0);
	                            buffer_write(PlayerBuffer, buffer_u32, player[? "x"]);
	                            buffer_write(PlayerBuffer, buffer_u32, player[? "y"]);
                            
	                            if player[? "bulletx"] < player[? "x"]{
	                                player[? "bullety"] -= World.CELL_SIZE/2;
	                                buffer_seek(PlayerBuffer, buffer_seek_start, 0);
	                                buffer_write(PlayerBuffer, buffer_u32, player[? "bulletx"]);
	                                buffer_write(PlayerBuffer, buffer_u32, player[? "bullety"]);
	                            }
	                    }
	            }
            
	            if key_down{
	                 if grid[# (player[? "x"] div World.CELL_SIZE), (player[? "y"] div World.CELL_SIZE) + 1] == noone{ 
                  
	                            player[? "y"] += World.CELL_SIZE/2;
	                            buffer_seek (PlayerBuffer, buffer_seek_start, 0);
	                            buffer_write(PlayerBuffer, buffer_u32, player[? "x"]);
	                            buffer_write(PlayerBuffer, buffer_u32, player[? "y"]);
                            
	                            if player[? "bulletx"] < player[? "x"]{
	                                player[? "bullety"] += World.CELL_SIZE/2;
	                                buffer_seek(PlayerBuffer, buffer_seek_start, 0);
	                                buffer_write(PlayerBuffer, buffer_u32, player[? "bulletx"]);
	                                buffer_write(PlayerBuffer, buffer_u32, player[? "bullety"]);
	                            }
	                 }         
	            }
            
	            //**************************************************************************************************************************************************
            
	                if ds_exists(0, ds_type_map){
            
	            //****************************************************************************************************************************************************
	            //INFINITE RUNNER
            
	                if grid[# (player[? "x"] div World.CELL_SIZE) + 1,
	                            (player[? "y"] div World.CELL_SIZE)] == noone{
                
	                                    player[? "x"] += World.CELL_SIZE/2;
	                                    buffer_seek(PlayerBuffer, buffer_seek_start, 0);
	                                    buffer_write(PlayerBuffer, buffer_u32, player[? "x"]);
	                                    buffer_write(PlayerBuffer, buffer_u32, player[? "y"]);
                                    
	                                    if (player[? "bulletx"]) < player[? "x"]-16{
	                                        player[? "bulletx"] += World.CELL_SIZE/2;
	                                        player[? "bullety"] = player[? "y"];
	                                        buffer_write(PlayerBuffer, buffer_u32, player[? "bulletx"]);
	                                        buffer_write(PlayerBuffer, buffer_u32, player[? "bullety"]);
	                                    }
	                                    else{
	                                        player[? "bulletx"] += World.CELL_SIZE;
	                                        buffer_write(PlayerBuffer, buffer_u32, player[? "bulletx"]);
	                                        buffer_write(PlayerBuffer, buffer_u32, player[? "bullety"]);   
	                                    }
                            
	                }
              
	                //PLAYER COLLISION
	                if grid[# (player[? "x"] div World.CELL_SIZE) + 1,
	                            (player[? "y"] div World.CELL_SIZE)] != noone{
	                                       player[? "lives"] -= 1;
	                                       buffer_seek(PlayerBuffer, buffer_seek_start, 0);
	                                       buffer_write(PlayerBuffer, buffer_u32, player[? "lives"]);
	                                        //EMITS SOUND
	                                        hertz           = irandom_range(10, 20);
	                                        buffer_seek(SoundBuffer, buffer_seek_start, 0);
	                                        var num_to_write = rate / hertz;
	                                        var val_to_write = 1;
	                                        for (var i = 0; i < (samples / num_to_write) + 1; i++) {
	                                            for (var j = 0; j < num_to_write; j++) {
	                                                buffer_write(SoundBuffer, buffer_u8, val_to_write * 255);
	                                            }
	                                            val_to_write = (1 - val_to_write);
	                                        }
	                                        soundId = audio_create_buffer_sound(SoundBuffer, buffer_u8, rate, 0, 68, audio_mono);
	                                        bulletSound = audio_play_sound(soundId, 10, false);
	                                        audio_sound_pitch(bulletSound, 0.1);
	                                        audio_sound_gain(bulletSound, 1, 0);
	                                        while (audio_is_playing(bulletSound)){
	                                            //take time
	                                        }
	                                        audio_stop_sound(bulletSound);
	                                        audio_free_buffer_sound(soundId);
	                            }
                
	                //BULLET COLLISIONS
	                if grid[# (player[? "bulletx"] div World.CELL_SIZE)+1,
	                            (player[? "bullety"] div World.CELL_SIZE)] != noone{
	                                        ds_grid_set(grid, (player[? "bulletx"] div World.CELL_SIZE), (player[? "bullety"] div World.CELL_SIZE), noone);
	                                        ds_grid_set(grid, (player[? "bulletx"] div World.CELL_SIZE)+1, (player[? "bullety"] div World.CELL_SIZE), noone);
	                                        ds_grid_set(grid, (player[? "bulletx"] div World.CELL_SIZE)+2, (player[? "bullety"] div World.CELL_SIZE), noone);
	                                        ds_grid_set(grid, (player[? "bulletx"] div World.CELL_SIZE)-1, (player[? "bullety"] div World.CELL_SIZE), noone);
	                                        ds_grid_set(grid, (player[? "bulletx"] div World.CELL_SIZE)-2, (player[? "bullety"] div World.CELL_SIZE), noone);
	                                        buffer_seek (GridBuffer, buffer_seek_start, 0);
	                                        buffer_write(GridBuffer, buffer_u64, grid);
                                        
	                                        draw_set_color(Colors.BLUE);
	                                        draw_rectangle(player[? "bulletx"]-64, (player[? "bullety"]),
	                                                        (player[? "bulletx"]) + 64,
	                                                        (player[? "bullety"]) + 32, false);
	                            }
                
	                            //DRAW TRAIL ON FLOOR
	                            if grid[# (player[? "x"] div World.CELL_SIZE),
	                                        (player[? "y"] div World.CELL_SIZE)+1] == 1{
                                        
	                                                draw_set_color(c_red);
	                                                draw_rectangle(player[? "x"], player[? "y"]+World.CELL_SIZE, player[? "x"]+World.CELL_SIZE, player[? "y"]+World.CELL_SIZE*2, false);
                                                
	                            }
	                            //************************************************************************************************************************************************
                                        
	                            //CHANGE LEVEL!
	                            if player[? "x"] > World.WIDTH-World.CELL_SIZE*2{
	                                        file_delete("Grid_Check.ini");
	                                        player[? "x"] = World.CELL_SIZE;
	                                        player[? "y"] = (World.HEIGHT/2)-(World.CELL_SIZE*2);
	                                        player[? "bulletx"] = 0;
	                                        player[? "bullety"] = (World.HEIGHT/2)-(World.CELL_SIZE*2);
	                                        player[? "level"] += 1;
	                                        buffer_seek (PlayerBuffer, buffer_seek_start, 0);
	                                        buffer_write(PlayerBuffer, buffer_u32, player[? "x"]);
	                                        buffer_write(PlayerBuffer, buffer_u32, player[? "y"]);
	                                        buffer_write(PlayerBuffer, buffer_u32, player[? "bulletx"]);
	                                        buffer_write(PlayerBuffer, buffer_u32, player[? "bullety"]);
	                                        buffer_write(PlayerBuffer, buffer_u32, player[? "level"]);
	                                        file_delete("Save.ini");
	                                        file_delete("Drawn.ini");
	                                        ds_grid_destroy(grid);
        
	                            }
	                            //DRAW NUMBERS
	                            if player_init{
	                                    draw_rectangle_color(50, 680, 300, 710, Colors.RED, Colors.RED, Colors.RED, Colors.RED, false);
	                                    draw_rectangle_color(52, 682, 298, 708, Colors.BLACK, Colors.BLACK, Colors.BLACK, Colors.BLACK, false);
	                                    draw_text(200 , 690, string_hash_to_newline("LEVEL "+string(player[? "level"])));
	                                    draw_text_transformed_colour(60, 690, string_hash_to_newline("Lives " +string(player[? "lives"])), 1, 1, 0, Colors.WHITE, Colors.WHITE, Colors.WHITE, Colors.WHITE, 1);
	                            }
                            
	                            //GAME OVER!       
	                            if player[? "lives"] < 1{
	                                file_delete("Grid_Check.ini");
	                                file_delete("Save.ini");
	                                file_delete("Drawn.ini");
	                                file_delete("Player_Check.ini");
	                                file_delete("Sound_Check.ini");
	                                file_delete("Counter_Check.ini");
	                                file_delete("Bullet_Check.ini");
	                                file_delete("Room_Check.ini");
	                                buffer_delete(GridBuffer);
	                                buffer_delete(PlayerBuffer);
	                                buffer_delete(SoundBuffer);
	                                buffer_delete(CounterBuffer);
	                                buffer_delete(BulletBuffer);
	                                if ds_exists(0, ds_type_grid){
	                                    ds_grid_clear(grid,0);
	                                    ds_grid_destroy(grid);
	                                }
	                                if ds_exists(0, ds_type_map){
	                                    ds_map_destroy(player);
	                                }
                                
                            
	                            }
                            
	                            //PRESS ESC TO GO BACK TO INTRO SCREEN
	                            if keyboard_check_pressed(vk_escape){
	                                file_delete("Grid_Check.ini");
	                                file_delete("Save.ini");
	                                file_delete("Drawn.ini");
	                                file_delete("Player_Check.ini");
	                                file_delete("Sound_Check.ini");
	                                file_delete("Counter_Check.ini");
	                                file_delete("Bullet_Check.ini");
	                                file_delete("Room_Check.ini");
	                                buffer_delete(GridBuffer);
	                                buffer_delete(PlayerBuffer);
	                                buffer_delete(SoundBuffer);
	                                buffer_delete(CounterBuffer);
	                                buffer_delete(BulletBuffer);
	                                if ds_exists(0, ds_type_grid){
	                                    ds_grid_clear(grid,0);
	                                    ds_grid_destroy(grid);
	                                }
	                                if ds_exists(0, ds_type_map){
	                                    ds_map_destroy(player);
	                                }
                            
	                            }
	                    }
        
                
                
	            }


	}     



}
