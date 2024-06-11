/// @description  OSG_Asteroids();
function NocturneOSGAsteroids() {

	/*
	OSG ASTEROIDS is a one script game for GameMaker: Studio. All you need to play is to add this script
	as a Script Resource in the GameMaker: Studio resource tree, then create an object and call the script
	in the DRAW EVENT. Drop the object in a room and press Play to get the game running.

	The game was made in about 16 hours as part of the OSG Jam over at the GameMaker Community Forums:
	https://forum.yoyogames.com/index.php?threads/osg-jam.6018/

	This script is OPEN SOURCE under the creative commons 4.0 licence
	https://creativecommons.org/licenses/by-nc/4.0/

	You can share and modify this all you want, but please attribute it to:

	Mark Alexander
	NOCTURNE GAMES

	And you MAY NOT use it for commercial purposes.
	*/

	//////////////////////////////////////// INIT ///////////////////////////////////////////////

	// DEBUG /////////////////////////////////////////////////////////////////////
	//show_debug_overlay(true);

	// Init game room ////////////////////////////////////////////////////////////
	draw_set_colour(c_white);
	draw_set_alpha(0.2);
	draw_rectangle_colour(0, 0, rm.width, rm.height, c_black, c_black, c_black, c_black, false);
	draw_set_alpha(1);

	// Store base map ID
	enum map{
	    ID = 0
	    }

	// Room constants
	enum rm{
	    width = 1024,
	    height = 576,
	    spd = 30
	    }

	// Player constants
	enum player{
	    max_spd = 8,
	    max_turn = 5,
	    max_shoot = 15,
	    max_shoot_spd = 6,
	    max_shoot_timer = 45
	    }
    
	// Game state constants
	enum state{
	    game,
	    intro,
	    intro_fade,
	    gameover,
	    gameover_fade
	    }
    
	// Menu constants
	enum menu{
	    start,
	    colour,
	    quit
	    }

	// Define base asteroid shapes as constants
	enum a_small{
	    len1 = 9,       ang1 = 110,
	    len2 = 8,       ang2 = 140,
	    len3 = 8,       ang3 = 194,
	    len4 = 6,       ang4 = 225,
	    len5 = 9,       ang5 = 250,
	    len6 = 9,       ang6 = 315,
	    len7 = 8,       ang7 = 7,
	    len8 = 7,       ang8 = 56,
	    rad = 8
	    }
	enum a_medium{
	    len1 = 11,      ang1 = 100,
	    len2 = 18,      ang2 = 119,
	    len3 = 16,      ang3 = 180,
	    len4 = 17,      ang4 = 225,
	    len5 = 10,      ang5 = 265,
	    len6 = 18,      ang6 = 300,
	    len7 = 17,      ang7 = 343,
	    len8 = 16,      ang8 = 52,
	    rad = 16
	    }
	enum a_large{
	    len1 = 32,      ang1 = 95,
	    len2 = 34,      ang2 = 151,
	    len3 = 22,      ang3 = 193,
	    len4 = 39,      ang4 = 218,
	    len5 = 32,      ang5 = 265,
	    len6 = 38,      ang6 = 314,
	    len7 = 32,      ang7 = 3,
	    len8 = 36,      ang8 = 48,
	    rad = 32
	    }

	//////////////////////////////////////// GAME SETUP ////////////////////////////////////////
	if !ds_exists(map.ID, ds_type_map)
	    {
	    // SET UP ////////////////////////////////////////////////////////////////
	    texture_set_interpolation(false);
	    display_reset(0, false);
	    ini_open("OSGA.ini");
    
	    var m = ds_map_create();
	    gamepad_set_axis_deadzone(0, 0.25);
    
	    // ROOM //////////////////////////////////////////////////////////////////
	    room_width = rm.width;
	    room_height = rm.height;
	    __background_set( e__BG.Visible, 0, false );
	    __background_set_colour( c_black );
	    __background_set_showcolour( false );
	    view_enabled = false;
	    window_set_size(rm.width, rm.height);
	    window_set_position((display_get_width() / 2) - (rm.width / 2), (display_get_height() / 2) - (rm.height / 2));
	    surface_resize(application_surface, rm.width, rm.height);
	    window_set_cursor(cr_none);
    
	    // GAME STATE ////////////////////////////////////////////////////////////
	    m[? "game_state"] = state.intro;
	    m[? "game_timer"] = 0;
	    m[? "game_over_y"] = -100;
	    m[? "game_draw_alpha"] = 0;
	    m[? "game_score"] = 0;
	    m[? "game_level"] = 1;
	    m[? "game_highscore"] = false;
	    m[? "game_menu_pos"] = menu.start;
	    m[? "accent_colour"] = ini_read_real("Game", "Colour", c_red);
    
	    // PLAYER ////////////////////////////////////////////////////////////////
	    m[? "player_x"] = rm.width / 2;
	    m[? "player_y"] = rm.height / 2;
	    m[? "player_spd"] = 0;
	    m[? "player_dir"] = 90;
	    m[? "player_score"] = 0;
	    m[? "player_high_score"] = ini_read_real("Player", "Score", 0);
	    m[? "player_shoot_time"] = 0;
    
	    // BULLETS ///////////////////////////////////////////////////////////////
	    m[? "bullet_list"] = ds_list_create();
    
	    // ASTEROIDS /////////////////////////////////////////////////////////////
	    m[? "asteroid_list"] = ds_list_create();
        
	    // PARTICLES /////////////////////////////////////////////////////////////
	    m[? "p_sys"] = part_system_create();
	    part_system_depth(m[? "p_sys"], 100);
	    m[? "p1"] = part_type_create();
	    part_type_shape(m[? "p1"],pt_shape_pixel);
	    part_type_size(m[? "p1"],0.01,0.01,0.01,0);
	    part_type_scale(m[? "p1"],1,1);
	    part_type_color1(m[? "p1"],16777215);
	    part_type_alpha1(m[? "p1"],0.5);
	    part_type_speed(m[? "p1"],2,5,0,0);
	    part_type_direction(m[? "p1"],0,359,0,0);
	    part_type_gravity(m[? "p1"],0,270);
	    part_type_orientation(m[? "p1"],0,0,0,0,1);
	    part_type_blend(m[? "p1"],1);
	    part_type_life(m[? "p1"],300,300);
	    repeat(200)
	        {
	        part_particles_create_colour(m[? "p_sys"], rm.width / 2, rm.height / 2, m[? "p1"], merge_colour(c_white, c_black, random(0.75)), 1);
	        part_system_update(m[? "p_sys"]);
	        }
        
	    m[? "p2"] = part_type_create();
	    part_type_shape(m[? "p2"],pt_shape_ring);
	    part_type_size(m[? "p2"],0.10,0.10,0.10,0);
	    part_type_scale(m[? "p2"],1,1);
	    part_type_color1(m[? "p2"],c_white);
	    part_type_alpha2(m[? "p2"],1,0);
	    part_type_speed(m[? "p2"],0,0,0,0);
	    part_type_direction(m[? "p2"],0,359,0,0);
	    part_type_gravity(m[? "p2"],0,270);
	    part_type_orientation(m[? "p2"],0,0,0,0,1);
	    part_type_blend(m[? "p2"],1);
	    part_type_life(m[? "p2"],15,45);
    
	    m[? "p3"] = part_type_create();
	    part_type_shape(m[? "p3"],pt_shape_pixel);
	    part_type_size(m[? "p3"],1,1,0,0);
	    part_type_scale(m[? "p3"],1,1);
	    part_type_color1(m[? "p3"],16777215);
	    part_type_alpha2(m[? "p3"],1,0);
	    part_type_speed(m[? "p3"],1,5,0,0);
	    part_type_direction(m[? "p3"],0,359,0,0);
	    part_type_gravity(m[? "p3"],0,270);
	    part_type_orientation(m[? "p3"],0,0,0,0,0);
	    part_type_blend(m[? "p3"],1);
	    part_type_life(m[? "p3"],15,60);

	    // SOUND /////////////////////////////////////////////////////////////////
	    // Explosion
	    var rate = 2000;
	    var hertz = 500;
	    var bufferId = buffer_create(rate, buffer_fast, 1);
	    var num_to_write = (rate / hertz);
	    var vol = 255;
	    buffer_seek(bufferId, buffer_seek_start, 0);
	    for (var i = 0; i < (rate / num_to_write) + 1; i++;)
	        {
	        for (var j = 0; j < num_to_write; j++;)
	            {
	            buffer_write(bufferId, buffer_u8, clamp(random(1) * 255, 0.01, vol)); //val_to_write * 255);
	            }
	        vol -= 1;
	        }
	    m[? "snd_explode"] = audio_create_buffer_sound(bufferId, buffer_u8, rate, 0, 650, audio_mono);
	    // Thruster
	    rate = 8000;
	    hertz = 100; //irandom_range(220, 880);
	    bufferId = buffer_create(rate, buffer_fast, 1);
	    num_to_write = (rate / hertz);
	    vol = 255;
	    buffer_seek(bufferId, buffer_seek_start, 0);
	    for (var i = 0; i < (rate / num_to_write) + 1; i++;)
	        {
	        for (var j = 0; j < num_to_write; j++;)
	            {
	            buffer_write(bufferId, buffer_u8, random(1) * 32); //val_to_write * 255);
	            }
	        vol -= 1;
	        }
	    m[? "snd_thrust"] = audio_create_buffer_sound(bufferId, buffer_u8, rate, 0, 8000, audio_mono);
	    // Shoot
	    rate = 11025;
	    hertz = 220;
	    bufferId = buffer_create(rate, buffer_fast, 1);
	    buffer_seek(bufferId, buffer_seek_start, 0);
	    num_to_write = rate / hertz;
	    val_to_write = 1;
	    for (var i = 0; i < (rate / num_to_write) + 1; i++;)
	       {
	       for (var j = 0; j < num_to_write; j++;)
	          {
	          buffer_write(bufferId, buffer_u8, val_to_write * 255);
	          }
	       val_to_write = (1 - val_to_write);
	       }
	    m[? "snd_shoot"] = audio_create_buffer_sound(bufferId, buffer_u8, rate, 0, 200, audio_mono);
	    ini_write_real("Player", "Score", m[? "player_high_score"]);
	    ini_write_real("Game", "Colour", m[? "accent_colour"]);
	    ini_close();
	    }
	else
	    {
	//////////////////////////////////////// MAIN GAME LOOP ////////////////////////////////////////
	    // Get vars
	    var p_x = map.ID[? "player_x"];
	    var p_y = map.ID[? "player_y"];
	    var p_s = map.ID[? "player_spd"];
	    var p_d = map.ID[? "player_dir"];
	    var p_sc = map.ID[? "player_score"];
	    var p_t = map.ID[? "player_shoot_time"];
	    var b_list = map.ID[? "bullet_list"];
	    var a_list = map.ID[? "asteroid_list"];
    
	    if irandom(29) == 0 var cc = map.ID[? "accent_colour"] else var cc = merge_colour(c_white, c_black, random(0.75));
	    part_particles_create_colour(map.ID[? "p_sys"], rm.width / 2, rm.height / 2, map.ID[? "p1"], cc, 1);
      
	    // CHECK GAME STATE //////////////////////////////////////////////////////////////
	    switch (map.ID[? "game_state"])
	        {
	/////////////////////////////////////////// GAME INTRO ///////////////////////////////////////////////////
	        case state.intro:
	            var xx = rm.width / 2;
	            var yy = map.ID[? "game_over_y"];
	            var cc = map.ID[? "accent_colour"];
	            var time = clamp(map.ID[? "game_timer"] - 1, 0, rm.spd / 2);
	            var ry = rm.height / 2;
	            var y_max = 100;
	            yy = clamp(yy + 10, -100, y_max);
	            // Fade in text
	            var l_n = 7;
	            var l_l = 0;
	            var sz = 12;
	            var str, col;
	            str[0] = " ***   ***   ***      ***   ***  *****  ****  ***   ***  ***** ***    *** "; col[0] = c_white;
	            str[1] = "*   * *   * *   *    *   * *   *   *   *     *   * *   *   *   *  *  *   *"; col[1] = merge_colour(c_white, cc, 0.33);
	            str[2] = "*   * *     *        *   * *       *   *     *   * *   *   *   *   * *    "; col[2] = merge_colour(c_white, cc, 0.66);
	            str[3] = "*   *  ***  *  **    *****  ***    *   ***   ****  *   *   *   *   *  *** "; col[3] = cc;
	            str[4] = "*   *     * *   *    *   *     *   *   *     * *   *   *   *   *   *     *"; col[4] = merge_colour(c_white, cc, 0.66);
	            str[5] = "*   * *   * *   *    *   * *   *   *   *     *  *  *   *   *   *  *  *   *"; col[5] = merge_colour(c_white, cc, 0.33);
	            str[6] = " ***   ***   ***     *   *  ***    *    **** *   *  ***  ***** ***    *** "; col[6] = c_white;
	            for(var i = 0; i < l_n; i++;)
	                {
	                if string_length(str[i]) > l_l
	                    {
	                    l_l = string_length(str[i]);
	                    }
	                }
	            var xo = (rm.width / 2) - ((l_l * sz) / 2) - sz;
	            var yo = yy - ((l_n * sz) / 2);
	            for(i = 1; i < l_l + 1; i++;)
	                {
	                for(var j = 0; j < l_n; j++;) //...and for each line
	                    {
	                    if string_char_at(str[j],i) != " " && string_char_at(str[j],i) != ""
	                        {
	                        draw_rectangle_colour(xo + (i * sz), yo + (j * sz), xo + (i * sz) + sz, yo + (j * sz) + sz, col[j], col[j], col[j], col[j], false);
	                        }
	                    }
	                }
	            // DEAL WITH MENU AND TEXT ///////////////////////////////////////////////
	            draw_set_halign(fa_center);
	            if yy >= y_max
	                {
	                // Draw extra text
	                draw_text_colour(xx, rm.height - 30, string_hash_to_newline("(C) Nocturne Games"), cc, cc, cc, cc, 1);
	                draw_text(xx, rm.height - 80, string_hash_to_newline("HIGH SCORE TO BEAT: " + string(map.ID[? "player_high_score"])));
	                draw_text(xx, rm.height - 180, string_hash_to_newline("CONTROLS"));
	                draw_text(xx, rm.height - 160, string_hash_to_newline("Keyboard: Arrow Keys, Space"));
	                draw_text(xx, rm.height - 140, string_hash_to_newline("Gamepad0: Left Stick, A"));
	                if time <= 0
	                    {
	                    if keyboard_check(vk_down) || (gamepad_axis_value(0, gp_axislv) > 0)
	                        {
	                        map.ID[? "game_menu_pos"] += 1;
	                        if map.ID[? "game_menu_pos"] > 2 map.ID[? "game_menu_pos"] = 0;
	                        time = rm.spd / 3;
	                        }
	                    if keyboard_check(vk_up) || (gamepad_axis_value(0, gp_axislv) < 0)
	                        {
	                        map.ID[? "game_menu_pos"] -= 1;
	                        if map.ID[? "game_menu_pos"] < 0 map.ID[? "game_menu_pos"] = 2;
	                        time = rm.spd / 3;
	                        }
	                    }
	                // Loop through the menu options
	                for (var i = 0; i < 3; i++;)
	                    {
	                    if map.ID[? "game_menu_pos"] == i
	                         {
	                         switch (i)
	                             {
	                             case 0: // PLAY THE GAME!
	                                draw_text_transformed_colour(xx, ry - 34 + (i * 30) - 3 + random(6), string_hash_to_newline("PLAY"), 1.5, 1.9 + random(0.2), -10 + random(20), cc, cc, cc, cc, 1);
	                                if keyboard_check(vk_space) || gamepad_button_check(0, gp_face1)
	                                    {
	                                    map.ID[? "game_state"] = state.intro_fade;
	                                    map.ID[? "player_x"] = rm.width / 2;
	                                    map.ID[? "player_y"] = rm.height / 2;
	                                    map.ID[? "player_spd"] = 0;
	                                    map.ID[? "player_dir"] = 90;
	                                    map.ID[? "player_score"] = 0;
	                                    map.ID[? "player_shoot_time"] = 0;
	                                    map.ID[? "game_draw_alpha"] = rm.spd / 2;
	                                    repeat(1)
	                                        {
	                                        var am = ds_map_create();
	                                        am[? "xpos"] = random(rm.width);
	                                        am[? "ypos"] = random(rm.height);
	                                        while (point_in_circle(am[? "xpos"], am[? "ypos"], rm.width / 2, rm.height / 2, 64))
	                                            {
	                                            am[? "xpos"] = random(rm.width);
	                                            am[? "ypos"] = random(rm.height)
	                                            }
	                                        am[? "dir"] = random(360);
	                                        am[? "ang"] = random(360);    
	                                        am[? "ang_add"] = -1 + random(2);
	                                        am[? "type"] = 2;    
	                                        switch (am[? "type"])
	                                            {
	                                            case 0: am[? "spd"] = 1.5 + random(1.5); break;
	                                            case 1: am[? "spd"] = 0.5 + random(0.5); break;
	                                            case 2: am[? "spd"] = 0.25 + random(0.25); break;
	                                            }
	                                        ds_list_add(map.ID[? "asteroid_list"], am);
	                                        }
	                                    repeat(5000)
	                                        {
	                                        part_system_update(map.ID[? "p_sys"]);
	                                        part_system_drawit(map.ID[? "p_sys"]);
	                                        }
	                                    }
	                                break;
	                             case 1: // Change Accent Colour
	                                draw_text_transformed_colour(xx, ry - 34 + (i * 30) - 3 + random(6), string_hash_to_newline("COLOUR"), 1.5, 1.9 + random(0.2), -10 + random(20), cc, cc, cc, cc, 1);
	                                if (keyboard_check(vk_space) || gamepad_button_check(0, gp_face1)) && time <= 0
	                                    {
	                                    var hue = colour_get_hue(cc) + 16;
	                                    if hue > 255 hue -= 255;
	                                    cc = make_colour_hsv(hue, 255, 255);
	                                    ini_open("OSGA.ini");
	                                    ini_write_real("Game", "Colour", cc);
	                                    ini_close();
	                                    time = rm.spd / 3;
	                                    }
	                                break;
	                             case 2: // Quit Game
	                                draw_text_transformed_colour(xx, ry - 34 + (i * 30) - 3 + random(6), string_hash_to_newline("QUIT"), 1.5, 1.9 + random(0.2), -10 + random(20), cc, cc, cc, cc, 1);
	                                if keyboard_check(vk_space) || gamepad_button_check(0, gp_face1)
	                                    {
	                                    game_end();
	                                    }
	                                break;
	                             }
	                         }
	                    switch (i)
	                        {
	                        case 0: draw_text_transformed(xx, ry - 30 + (i * 30), string_hash_to_newline("PLAY"), 1.5, 1.5, 0); break;
	                        case 1: draw_text_transformed(xx, ry - 30 + (i * 30), string_hash_to_newline("COLOUR"), 1.5, 1.5, 0); break;
	                        case 2: draw_text_transformed(xx, ry - 30 + (i * 30), string_hash_to_newline("QUIT"), 1.5, 1.5, 0); break;
	                        }
	                    }
	                }
	            map.ID[? "game_over_y"] = yy;
	            map.ID[? "game_timer"] = time;
	            map.ID[? "accent_colour"] = cc;
	            break;
            
	//////////////////////////////////// GAME INTRO FADE / LEVEL FADE ////////////////////////////////////////////
	        case state.intro_fade:
	            audio_stop_sound(map.ID[? "snd_thrust"]);
	            var ss = rm.spd / 2;
	            var aa = map.ID[? "game_draw_alpha"]
	            aa = clamp(--aa, 0, ss);
	            var lm = 1 - (aa / ss);
	            // Particle effect
	            if aa > 0
	                {
	                repeat(100)
	                    {
	                    if irandom(29) == 0 var c = map.ID[? "accent_colour"] else var c = merge_colour(c_white, c_black, random(0.75));
	                    part_particles_create_colour(map.ID[? "p_sys"], rm.width / 2, rm.height / 2, map.ID[? "p1"], c, 1);
	                    part_system_update(map.ID[? "p_sys"]);
	                    part_system_drawit(map.ID[? "p_sys"]);
	                    }
	                }
	            else map.ID[? "game_state"] = state.game;
	            var c = map.ID[? "accent_colour"];
	            // Scale in the asteroids
	            for (var i = 0; i < ds_list_size(a_list); i++;)
	                {
	                var ax, ay, rr;
	                var a = ds_list_find_value(a_list, i);
	                var tx = a[? "xpos"];
	                var ty = a[? "ypos"];
	                ax[0] = tx + lengthdir_x(a_large.len1 * lm, a_large.ang1 + aa);
	                ay[0] = ty + lengthdir_y(a_large.len1 * lm, a_large.ang1 + aa);
	                ax[1] = tx + lengthdir_x(a_large.len2 * lm, a_large.ang2 + aa);
	                ay[1] = ty + lengthdir_y(a_large.len2 * lm, a_large.ang2 + aa);
	                ax[2] = tx + lengthdir_x(a_large.len3 * lm, a_large.ang3 + aa);
	                ay[2] = ty + lengthdir_y(a_large.len3 * lm, a_large.ang3 + aa);
	                ax[3] = tx + lengthdir_x(a_large.len4 * lm, a_large.ang4 + aa);
	                ay[3] = ty + lengthdir_y(a_large.len4 * lm, a_large.ang4 + aa);
	                ax[4] = tx + lengthdir_x(a_large.len5 * lm, a_large.ang5 + aa);
	                ay[4] = ty + lengthdir_y(a_large.len5 * lm, a_large.ang5 + aa);
	                ax[5] = tx + lengthdir_x(a_large.len6 * lm, a_large.ang6 + aa);
	                ay[5] = ty + lengthdir_y(a_large.len6 * lm, a_large.ang6 + aa);
	                ax[6] = tx + lengthdir_x(a_large.len7 * lm, a_large.ang7 + aa);
	                ay[6] = ty + lengthdir_y(a_large.len7 * lm, a_large.ang7 + aa);
	                ax[7] = tx + lengthdir_x(a_large.len8 * lm, a_large.ang8 + aa);
	                ay[7] = ty + lengthdir_y(a_large.len8 * lm, a_large.ang8 + aa);
	                draw_line(ax[0], ay[0], ax[1], ay[1]);
	                draw_line(ax[1], ay[1], ax[2], ay[2]);
	                draw_line(ax[2], ay[2], ax[3], ay[3]);
	                draw_line(ax[3], ay[3], ax[4], ay[4]);
	                draw_line(ax[4], ay[4], ax[5], ay[5]);
	                draw_line(ax[5], ay[5], ax[6], ay[6]);
	                draw_line(ax[6], ay[6], ax[7], ay[7]);
	                draw_line(ax[7], ay[7], ax[0], ay[0]); 
	                }
	            // Scale in the player
	            var px, py;
	            if map.ID[? "game_level"] > 1 lm = 1;
	            px[0] = p_x + lengthdir_x(16 * lm, p_d);
	            py[0] = p_y + lengthdir_y(16 * lm, p_d);
	            px[1] = p_x + lengthdir_x(16 * lm, p_d + 135);
	            py[1] = p_y + lengthdir_y(16 * lm, p_d + 135);
	            px[2] = p_x + lengthdir_x(8 * lm, p_d + 180);
	            py[2] = p_y + lengthdir_y(8 * lm, p_d + 180);
	            px[3] = p_x + lengthdir_x(16 * lm, p_d - 135);
	            py[3] = p_y + lengthdir_y(16 * lm, p_d - 135);
	            draw_line(px[0], py[0], px[1], py[1]);
	            draw_line(px[1], py[1], px[2], py[2]);
	            draw_line(px[2], py[2], px[3], py[3]);
	            draw_line(px[3], py[3], px[0], py[0]);
	            map.ID[? "game_draw_alpha"] = aa;
	            // Draw level text
	            draw_text_transformed_colour(rm.width / 2, rm.height - 100, string_hash_to_newline("LEVEL " + string(map.ID[? "game_level"])), 3, 2.9 + random(0.2), -10 + random(20), c, c, c, c, 1);
	            draw_text_transformed(rm.width / 2, rm.height - 100, string_hash_to_newline("LEVEL " + string(map.ID[? "game_level"])), 3, 3, 0);
	            break;
            
	//////////////////////////////////////// MAIN GAME SECTION ///////////////////////////////////////////////
	        case state.game:
	            // MOVE PLAYER ///////////////////////////////////////////////////////////
	            // Accelerate
	            if keyboard_check(vk_up) || gamepad_axis_value(0, gp_axislv) < 0
	                {
	                // Move forward
	                p_s = clamp(p_s + 0.25, 0, player.max_spd);
	                if !audio_is_playing(map.ID[? "snd_thrust"])
	                    {
	                    audio_play_sound(map.ID[? "snd_thrust"], 0, true);
	                    }
	                }
	            else
	                {
	                // Add friction
	                p_s = clamp(p_s - 0.25, 0, player.max_spd);
	                audio_stop_sound(map.ID[? "snd_thrust"]);
	                }
	            audio_sound_pitch(map.ID[? "snd_thrust"], 0.5 + ((p_s / player.max_spd) * 0.5));
	            // Break
	            if keyboard_check(vk_down) || gamepad_axis_value(0, gp_axislv) > 0
	                {
	                p_s = clamp(p_s - 0.5, 0, player.max_spd);
	                }
	            // Turn
	            if keyboard_check(vk_right) || (gamepad_axis_value(0, gp_axislh) > 0)
	                {
	                p_d -= player.max_turn;
	                if p_d < 0 p_d += 360;
	                }
	            if keyboard_check(vk_left) || (gamepad_axis_value(0, gp_axislh) < 0)
	                {
	                p_d += player.max_turn;
	                if p_d > 360 p_d -= 360;
	                }
                
	            // UPDATE THE PLAYER /////////////////////////////////////////////////////
	            // Get player vectors
	            var xv = lengthdir_x(p_s, p_d);
	            var yv = lengthdir_y(p_s, p_d);
            
	            // Check for out of bounds
	            if p_x + xv < 0 p_x += rm.width
	            else if p_x + xv > rm.width p_x -= rm.width
	            if p_y + yv < 0 p_y += rm.height
	            else if p_y + yv > rm.height p_y -= rm.height;
            
	            // Update player position
	            p_x += xv;
	            p_y += yv;
            
	            // CHECK FOR SHOOTING ////////////////////////////////////////////////////
	            if keyboard_check(vk_space) || gamepad_button_check(0, gp_face1)
	                {
	                if p_t <= 0
	                    {
	                    p_t = player.max_shoot;
	                    audio_play_sound(map.ID[? "snd_shoot"], 0, false);
	                    var bm = ds_map_create();
	                    bm[? "xpos"] = p_x + lengthdir_x(16, p_d);
	                    bm[? "ypos"] = p_y + lengthdir_y(16, p_d);
	                    bm[? "dir"] = p_d;
	                    bm[? "timer"] = player.max_shoot_timer;
	                    bm[? "spd"] = player.max_shoot_spd + p_s;
	                    ds_list_add(b_list, bm);
	                    }
	                }
                
	            // DEAL WITH THE BULLETS /////////////////////////////////////////////////
	            if ds_list_size(b_list) > 0
	                {
	                var temp_list = ds_list_create();
	                for (var i = 0; i < ds_list_size(b_list); i++;)
	                    {
	                    var b = ds_list_find_value(b_list, i);
	                    b[? "timer"] -= 1;
	                    // Check lifetime timer
	                    if b[? "timer"] <= 0
	                        {
	                        ds_list_add(temp_list, i);
	                        }
	                    else
	                        {
	                        // Update position
	                        var b_x = b[? "xpos"];
	                        var b_y = b[? "ypos"];
	                        b_x += lengthdir_x(b[? "spd"], b[? "dir"]);
	                        b_y += lengthdir_y(b[? "spd"], b[? "dir"]);
	                        // Check for out of bounds
	                        if b_x < 0 b_x += rm.width
	                            else if b_x > rm.width b_x -= rm.width
	                        if b_y < 0 b_y += rm.height
	                            else if b_y > rm.height b_y -= rm.height;
	                        b[? "xpos"] = b_x;
	                        b[? "ypos"] = b_y;
	                        // Draw it
	                        draw_circle_colour(b[? "xpos"], b[? "ypos"], 3, map.ID[? "accent_colour"], map.ID[? "accent_colour"], false);
	                        }
	                    }
	                // Remove bullets with 0 lifetime
	                if ds_list_size(temp_list) > 0
	                    {
	                    for (var i = 0; i < ds_list_size(temp_list); i++;)
	                        {            
	                        ds_map_destroy(b_list[| i]);
	                        ds_list_delete(b_list, i);
	                        }
	                    }
	                ds_list_destroy(temp_list);
	                }
                
	            // THE ASTEROIDS /////////////////////////////////////////////////////////
	            if ds_list_size(a_list) > 0
	                {
	                // "Fill" the asteroids (do this seperately to keep batches low)
	                for (var i = 0; i < ds_list_size(a_list); i++;)
	                    {
	                    var a = ds_list_find_value(a_list, i)
	                    switch (a[? "type"])
	                        {
	                        case 0: var rr = a_small.rad; break;
	                        case 1: var rr = a_medium.rad; break;
	                        case 2: var rr = a_large.rad; break;
	                        }
	                    draw_circle_colour(a[? "xpos"] + lengthdir_x(a[? "spd"], a[? "dir"]), a[? "ypos"] + lengthdir_x(a[? "spd"], a[? "dir"]), rr - 1, c_black, c_black, false);
	                    }
	                // Update and draw the asteroids
	                var temp_list = ds_list_create();
	                for (var i = 0; i < ds_list_size(a_list); i++;)
	                    {
	                    var ax, ay, rr;
	                    var a = ds_list_find_value(a_list, i);
	                    a[? "ang"] += a[? "ang_add"];
	                    var aa = a[? "ang"];
	                    var tx = a[? "xpos"] + lengthdir_x(a[? "spd"], a[? "dir"]);
	                    var ty = a[? "ypos"] + lengthdir_y(a[? "spd"], a[? "dir"]);
                    
	                    // Check for out of bounds
	                    if tx  < - 32 tx += rm.width + 64
	                    else if tx > rm.width + 32 tx = -32;
	                    if ty < -32 ty += rm.height + 64
	                    else if ty > rm.height + 32 ty -= rm.height + 64;
                    
	                    // Draw Asteroid
	                    switch (a[? "type"])
	                        {
	                        case 0:
	                            ax[0] = tx + lengthdir_x(a_small.len1, a_small.ang1 + aa);
	                            ay[0] = ty + lengthdir_y(a_small.len1, a_small.ang1 + aa);
	                            ax[1] = tx + lengthdir_x(a_small.len2, a_small.ang2 + aa);
	                            ay[1] = ty + lengthdir_y(a_small.len2, a_small.ang2 + aa);
	                            ax[2] = tx + lengthdir_x(a_small.len3, a_small.ang3 + aa);
	                            ay[2] = ty + lengthdir_y(a_small.len3, a_small.ang3 + aa);
	                            ax[3] = tx + lengthdir_x(a_small.len4, a_small.ang4 + aa);
	                            ay[3] = ty + lengthdir_y(a_small.len4, a_small.ang4 + aa);
	                            ax[4] = tx + lengthdir_x(a_small.len5, a_small.ang5 + aa);
	                            ay[4] = ty + lengthdir_y(a_small.len5, a_small.ang5 + aa);
	                            ax[5] = tx + lengthdir_x(a_small.len6, a_small.ang6 + aa);
	                            ay[5] = ty + lengthdir_y(a_small.len6, a_small.ang6 + aa);
	                            ax[6] = tx + lengthdir_x(a_small.len7, a_small.ang7 + aa);
	                            ay[6] = ty + lengthdir_y(a_small.len7, a_small.ang7 + aa);
	                            ax[7] = tx + lengthdir_x(a_small.len8, a_small.ang8 + aa);
	                            ay[7] = ty + lengthdir_y(a_small.len8, a_small.ang8 + aa);
	                            rr = a_small.rad;
	                            break;
	                        case 1:
	                            ax[0] = tx + lengthdir_x(a_medium.len1, a_medium.ang1 + aa);
	                            ay[0] = ty + lengthdir_y(a_medium.len1, a_medium.ang1 + aa);
	                            ax[1] = tx + lengthdir_x(a_medium.len2, a_medium.ang2 + aa);
	                            ay[1] = ty + lengthdir_y(a_medium.len2, a_medium.ang2 + aa);
	                            ax[2] = tx + lengthdir_x(a_medium.len3, a_medium.ang3 + aa);
	                            ay[2] = ty + lengthdir_y(a_medium.len3, a_medium.ang3 + aa);
	                            ax[3] = tx + lengthdir_x(a_medium.len4, a_medium.ang4 + aa);
	                            ay[3] = ty + lengthdir_y(a_medium.len4, a_medium.ang4 + aa);
	                            ax[4] = tx + lengthdir_x(a_medium.len5, a_medium.ang5 + aa);
	                            ay[4] = ty + lengthdir_y(a_medium.len5, a_medium.ang5 + aa);
	                            ax[5] = tx + lengthdir_x(a_medium.len6, a_medium.ang6 + aa);
	                            ay[5] = ty + lengthdir_y(a_medium.len6, a_medium.ang6 + aa);
	                            ax[6] = tx + lengthdir_x(a_medium.len7, a_medium.ang7 + aa);
	                            ay[6] = ty + lengthdir_y(a_medium.len7, a_medium.ang7 + aa);
	                            ax[7] = tx + lengthdir_x(a_medium.len8, a_medium.ang8 + aa);
	                            ay[7] = ty + lengthdir_y(a_medium.len8, a_medium.ang8 + aa);
	                            rr = a_medium.rad;
	                            break;
	                        case 2:
	                            ax[0] = tx + lengthdir_x(a_large.len1, a_large.ang1 + aa);
	                            ay[0] = ty + lengthdir_y(a_large.len1, a_large.ang1 + aa);
	                            ax[1] = tx + lengthdir_x(a_large.len2, a_large.ang2 + aa);
	                            ay[1] = ty + lengthdir_y(a_large.len2, a_large.ang2 + aa);
	                            ax[2] = tx + lengthdir_x(a_large.len3, a_large.ang3 + aa);
	                            ay[2] = ty + lengthdir_y(a_large.len3, a_large.ang3 + aa);
	                            ax[3] = tx + lengthdir_x(a_large.len4, a_large.ang4 + aa);
	                            ay[3] = ty + lengthdir_y(a_large.len4, a_large.ang4 + aa);
	                            ax[4] = tx + lengthdir_x(a_large.len5, a_large.ang5 + aa);
	                            ay[4] = ty + lengthdir_y(a_large.len5, a_large.ang5 + aa);
	                            ax[5] = tx + lengthdir_x(a_large.len6, a_large.ang6 + aa);
	                            ay[5] = ty + lengthdir_y(a_large.len6, a_large.ang6 + aa);
	                            ax[6] = tx + lengthdir_x(a_large.len7, a_large.ang7 + aa);
	                            ay[6] = ty + lengthdir_y(a_large.len7, a_large.ang7 + aa);
	                            ax[7] = tx + lengthdir_x(a_large.len8, a_large.ang8 + aa);
	                            ay[7] = ty + lengthdir_y(a_large.len8, a_large.ang8 + aa);
	                            rr = a_large.rad;
	                            break;
	                        }
	                    draw_line(ax[0], ay[0], ax[1], ay[1]);
	                    draw_line(ax[1], ay[1], ax[2], ay[2]);
	                    draw_line(ax[2], ay[2], ax[3], ay[3]);
	                    draw_line(ax[3], ay[3], ax[4], ay[4]);
	                    draw_line(ax[4], ay[4], ax[5], ay[5]);
	                    draw_line(ax[5], ay[5], ax[6], ay[6]);
	                    draw_line(ax[6], ay[6], ax[7], ay[7]);
	                    draw_line(ax[7], ay[7], ax[0], ay[0]); 
	                    a[? "xpos"] = tx;
	                    a[? "ypos"] = ty;
	                    // Check for player collision
	                    if rectangle_in_circle(p_x - 6, p_y - 6, p_x + 6, p_y + 6, tx, ty, rr)
	                        {
	                        audio_sound_pitch(map.ID[? "snd_explode"], 1);
	                        part_particles_create(map.ID[? "p_sys"], p_x, p_y, map.ID[? "p3"], 10);
	                        part_particles_create_colour(map.ID[? "p_sys"], p_x, p_y, map.ID[? "p3"], map.ID[? "accent_colour"], 10);
	                        repeat(5)
	                            {
	                            part_particles_create_colour(map.ID[? "p_sys"], p_x - 16 + random(32), p_y - 16 + random(32), map.ID[? "p2"], choose(map.ID[? "accent_colour"], c_white), 1);
	                            }
	                        map.ID[? "game_state"] = state.gameover;
	                        map.ID[? "game_timer"] = 60;
	                        map.ID[? "game_over_y"] = -100;
	                        map.ID[? "game_draw_alpha"] = 0;
	                        if p_sc > map.ID[? "player_high_score"]
	                            {
	                            map.ID[? "player_high_score"] = p_sc;
	                            map.ID[? "game_high_score"] = true;
	                            ini_open("OSGA.ini");
	                            ini_write_real("Player", "Score", map.ID[? "player_high_score"]);
	                            ini_close();
	                            }
	                        }
	                    // Check for bullet collision
	                    if ds_list_size(b_list) > 0
	                        {
	                        var t_list = ds_list_create();
	                        for (var j = 0; j < ds_list_size(b_list); j++;)
	                            {
	                            var b = ds_list_find_value(b_list, j);
	                            if rectangle_in_circle(b[? "xpos"] - 2, b[? "ypos"] - 2, b[? "xpos"] + 2, b[? "ypos"] + 2, tx, ty, rr)
	                                {
	                                // Mark bullets and asteroids for destruction
	                                ds_list_add(t_list, j);
	                                if !ds_list_find_value(temp_list, i)
	                                    {
	                                    ds_list_add(temp_list, i);
	                                    }
	                                }
	                            }
	                        // Check for destroyed bullets
	                        if ds_list_size(t_list) > 0
	                            {
	                            for (var j = 0; j < ds_list_size(t_list); j++;)
	                                {
	                                var val = t_list[| 0];    
	                                ds_map_destroy(b_list[| val]);
	                                ds_list_delete(b_list, val);
	                                ds_list_delete(t_list, 0);
	                                }
	                            }
	                        ds_list_destroy(t_list);
	                        }
	                    }     
	                // Check for destroyed asteroids
	                if ds_list_size(temp_list) > 0
	                    {
	                    for (var i = 0; i < ds_list_size(temp_list); i++;)
	                        {
	                        var val = temp_list[| 0];
	                        var asteroid = a_list[| val];
	                        switch (ds_map_find_value(asteroid, "type"))
	                            {
	                            case 0:
	                                p_sc += 50;
	                                audio_sound_pitch(map.ID[? "snd_explode"], 1.2);
	                                part_particles_create(map.ID[? "p_sys"], asteroid[? "xpos"], asteroid[? "ypos"], map.ID[? "p3"], 10);
	                                part_particles_create_colour(map.ID[? "p_sys"], asteroid[? "xpos"], asteroid[? "ypos"], map.ID[? "p3"], map.ID[? "accent_colour"], 10);
	                                break;
	                            case 1:
	                                p_sc += 25;
	                                audio_sound_pitch(map.ID[? "snd_explode"], 1);
	                                var num = 2 + irandom(2);
	                                var aang = random(360);
	                                var aang_add = 360 / num;
	                                repeat(num)
	                                    {
	                                    var mx = ds_map_find_value(asteroid, "xpos");
	                                    var my = ds_map_find_value(asteroid, "ypos");
	                                    var am = ds_map_create();
	                                    am[? "xpos"] = mx + lengthdir_x(8, aang);
	                                    am[? "ypos"] = my + lengthdir_y(8, aang);
	                                    am[? "spd"] = 1.5 + random(1.5);
	                                    am[? "dir"] = point_direction(mx, my, am[? "xpos"], am[? "ypos"]);
	                                    am[? "ang"] = random(360);    
	                                    am[? "ang_add"] = -1 + random(2);
	                                    am[? "type"] = 0;    
	                                    ds_list_add(a_list, am);
	                                    aang += aang_add;
	                                    }
	                                part_particles_create(map.ID[? "p_sys"], asteroid[? "xpos"], asteroid[? "ypos"], map.ID[? "p3"], 10);
	                                part_particles_create_colour(map.ID[? "p_sys"], asteroid[? "xpos"], asteroid[? "ypos"], map.ID[? "p3"], map.ID[? "accent_colour"], 10);
	                                break;
	                            case 2:
	                                p_sc += 10;
	                                audio_sound_pitch(map.ID[? "snd_explode"], 0.8);
	                                var num = 4 + irandom(4);
	                                var aang = random(360);
	                                var aang_add = 360 / num;
	                                repeat(num)
	                                    {
	                                    var mx = ds_map_find_value(asteroid, "xpos");
	                                    var my = ds_map_find_value(asteroid, "ypos");
	                                    var am = ds_map_create();
	                                    am[? "xpos"] = mx + lengthdir_x(8, aang);
	                                    am[? "ypos"] = my + lengthdir_y(8, aang);
	                                    am[? "spd"] = 1.5 + random(1.5);
	                                    am[? "dir"] = point_direction(mx, my, am[? "xpos"], am[? "ypos"]);
	                                    am[? "ang"] = random(360);    
	                                    am[? "ang_add"] = -1 + random(2);
	                                    am[? "type"] = choose(0, 1);    
	                                    ds_list_add(a_list, am);
	                                    aang += aang_add;
	                                    }
	                                part_particles_create(map.ID[? "p_sys"], asteroid[? "xpos"], asteroid[? "ypos"], map.ID[? "p3"], 20);
	                                part_particles_create_colour(map.ID[? "p_sys"], asteroid[? "xpos"], asteroid[? "ypos"], map.ID[? "p3"], map.ID[? "accent_colour"], 20);
	                                break;
	                            }
	                        ds_map_destroy(asteroid);
	                        ds_list_delete(a_list, val);
	                        ds_list_delete(temp_list, 0);
	                        audio_play_sound(map.ID[? "snd_explode"], 0, false);
	                        }
	                    }
	                ds_list_destroy(temp_list);
	                }
	            else
	                {
	                map.ID[? "game_level"]++;
	                map.ID[? "game_state"] = state.intro_fade;
	                map.ID[? "game_draw_alpha"] = rm.spd;
	                repeat(map.ID[? "game_level"])
	                    {
	                    var am = ds_map_create();
	                    am[? "xpos"] = random(rm.width);
	                    am[? "ypos"] = random(rm.height);
	                    while (point_in_circle(am[? "xpos"], am[? "ypos"], p_x, p_y, 64))
	                        {
	                        am[? "xpos"] = random(rm.width);
	                        am[? "ypos"] = random(rm.height)
	                        }
	                    am[? "dir"] = random(360);
	                    am[? "ang"] = random(360);    
	                    am[? "ang_add"] = -1 + random(2);
	                    am[? "type"] = 2;    
	                    switch (am[? "type"])
	                        {
	                        case 0: am[? "spd"] = 1.5 + random(1.5); break;
	                        case 1: am[? "spd"] = 0.5 + random(0.5); break;
	                        case 2: am[? "spd"] = 0.25 + random(0.25); break;
	                        }
	                    ds_list_add(map.ID[? "asteroid_list"], am);
	                    }
	                }
                
	            // DRAW THE PLAYER ///////////////////////////////////////////////////////
	            var px, py;
	            px[0] = p_x + lengthdir_x(16, p_d);
	            py[0] = p_y + lengthdir_y(16, p_d);
	            px[1] = p_x + lengthdir_x(16, p_d + 135);
	            py[1] = p_y + lengthdir_y(16, p_d + 135);
	            px[2] = p_x + lengthdir_x(8, p_d + 180);
	            py[2] = p_y + lengthdir_y(8, p_d + 180);
	            px[3] = p_x + lengthdir_x(16, p_d - 135);
	            py[3] = p_y + lengthdir_y(16, p_d - 135);
	            draw_line(px[0], py[0], px[1], py[1]);
	            draw_line(px[1], py[1], px[2], py[2]);
	            draw_line(px[2], py[2], px[3], py[3]);
	            draw_line(px[3], py[3], px[0], py[0]);
            
	            // DRAW THE HUD //////////////////////////////////////////////////////////
	            var half = rm.width / 2;
	            draw_set_halign(fa_center);
	            draw_rectangle_colour(half - 60, 10, half + 60, 30, c_black, c_black, c_black, c_black, false);
	            draw_rectangle(half - 60, 10, half + 60, 30, true);
	            draw_text(rm.width / 2, 13, string_hash_to_newline(p_sc));
                
	            // UPDATE MAP INFO ///////////////////////////////////////////////////////
	            map.ID[? "player_x"] = p_x;
	            map.ID[? "player_y"] = p_y;
	            map.ID[? "player_spd"] = p_s;
	            map.ID[? "player_dir"] = p_d;
	            map.ID[? "player_score"] = p_sc;
	            map.ID[? "player_shoot_time"] = clamp(p_t - 1, 0, player.max_shoot);
	            break;
            
	//////////////////////////////////////// GAME OVER ///////////////////////////////////////////////
	        case state.gameover:
	            // DESTROY ASTEROIDS /////////////////////////////////////////////////////
	            audio_stop_sound(map.ID[? "snd_thrust"]);
	            if ds_list_size(a_list) > 0
	                {
	                var temp_list = ds_list_create();
	                // Destroy the asteroids a few at a time
	                for (var i = 0; i < ds_list_size(a_list); i++;)
	                    {
	                    var a = ds_list_find_value(a_list, i)
	                    if irandom(29) = 0
	                        {
	                        switch (a[? "type"])
	                            {
	                            case 0: var num = 10; var rr = 8; break;
	                            case 1: var num = 30; var rr = 16; break;
	                            case 2: var num = 50; var rr = 32; break;
	                            }
	                        part_particles_create(map.ID[? "p_sys"], a[? "xpos"] - rr + random(rr * 2), a[? "ypos"] - rr + random(rr * 2), map.ID[? "p3"], 5);
	                        part_particles_create_colour(map.ID[? "p_sys"], a[? "xpos"] - rr + random(rr * 2), a[? "ypos"] - rr + random(rr * 2), map.ID[? "p3"], map.ID[? "accent_colour"], 5);
	                        part_particles_create_colour(map.ID[? "p_sys"], a[? "xpos"], a[? "ypos"], map.ID[? "p2"], map.ID[? "accent_colour"], 1);
	                        ds_list_add(temp_list, i);
	                        }
	                    }
	                // Remove the asteroid maps
	                for (var i = 0; i < ds_list_size(temp_list); i++;)
	                    {
	                    var val = temp_list[| 0];
	                    var asteroid = a_list[| val];
	                    ds_map_destroy(asteroid);
	                    ds_list_delete(a_list, val);
	                    ds_list_delete(temp_list, 0);
	                    }
	                ds_list_destroy(temp_list);
	                // Draw the remaining asteroids
	                for (var i = 0; i < ds_list_size(a_list); i++;)
	                    {
	                    var ax, ay, rr;
	                    var a = ds_list_find_value(a_list, i);
	                    a[? "ang"] += a[? "ang_add"];
	                    var aa = a[? "ang"];
	                    var tx = a[? "xpos"] + lengthdir_x(a[? "spd"], a[? "dir"]);
	                    var ty = a[? "ypos"] + lengthdir_y(a[? "spd"], a[? "dir"]);
                    
	                    // Check for out of bounds
	                    if tx  < - 32 tx += rm.width + 64
	                    else if tx > rm.width + 32 tx = -32;
	                    if ty < -32 ty += rm.height + 64
	                    else if ty > rm.height + 32 ty -= rm.height + 64;
                    
	                    // Draw Asteroid
	                    switch (a[? "type"])
	                        {
	                        case 0:
	                            ax[0] = tx + lengthdir_x(a_small.len1, a_small.ang1 + aa);
	                            ay[0] = ty + lengthdir_y(a_small.len1, a_small.ang1 + aa);
	                            ax[1] = tx + lengthdir_x(a_small.len2, a_small.ang2 + aa);
	                            ay[1] = ty + lengthdir_y(a_small.len2, a_small.ang2 + aa);
	                            ax[2] = tx + lengthdir_x(a_small.len3, a_small.ang3 + aa);
	                            ay[2] = ty + lengthdir_y(a_small.len3, a_small.ang3 + aa);
	                            ax[3] = tx + lengthdir_x(a_small.len4, a_small.ang4 + aa);
	                            ay[3] = ty + lengthdir_y(a_small.len4, a_small.ang4 + aa);
	                            ax[4] = tx + lengthdir_x(a_small.len5, a_small.ang5 + aa);
	                            ay[4] = ty + lengthdir_y(a_small.len5, a_small.ang5 + aa);
	                            ax[5] = tx + lengthdir_x(a_small.len6, a_small.ang6 + aa);
	                            ay[5] = ty + lengthdir_y(a_small.len6, a_small.ang6 + aa);
	                            ax[6] = tx + lengthdir_x(a_small.len7, a_small.ang7 + aa);
	                            ay[6] = ty + lengthdir_y(a_small.len7, a_small.ang7 + aa);
	                            ax[7] = tx + lengthdir_x(a_small.len8, a_small.ang8 + aa);
	                            ay[7] = ty + lengthdir_y(a_small.len8, a_small.ang8 + aa);
	                            rr = a_small.rad;
	                            break;
	                        case 1:
	                            ax[0] = tx + lengthdir_x(a_medium.len1, a_medium.ang1 + aa);
	                            ay[0] = ty + lengthdir_y(a_medium.len1, a_medium.ang1 + aa);
	                            ax[1] = tx + lengthdir_x(a_medium.len2, a_medium.ang2 + aa);
	                            ay[1] = ty + lengthdir_y(a_medium.len2, a_medium.ang2 + aa);
	                            ax[2] = tx + lengthdir_x(a_medium.len3, a_medium.ang3 + aa);
	                            ay[2] = ty + lengthdir_y(a_medium.len3, a_medium.ang3 + aa);
	                            ax[3] = tx + lengthdir_x(a_medium.len4, a_medium.ang4 + aa);
	                            ay[3] = ty + lengthdir_y(a_medium.len4, a_medium.ang4 + aa);
	                            ax[4] = tx + lengthdir_x(a_medium.len5, a_medium.ang5 + aa);
	                            ay[4] = ty + lengthdir_y(a_medium.len5, a_medium.ang5 + aa);
	                            ax[5] = tx + lengthdir_x(a_medium.len6, a_medium.ang6 + aa);
	                            ay[5] = ty + lengthdir_y(a_medium.len6, a_medium.ang6 + aa);
	                            ax[6] = tx + lengthdir_x(a_medium.len7, a_medium.ang7 + aa);
	                            ay[6] = ty + lengthdir_y(a_medium.len7, a_medium.ang7 + aa);
	                            ax[7] = tx + lengthdir_x(a_medium.len8, a_medium.ang8 + aa);
	                            ay[7] = ty + lengthdir_y(a_medium.len8, a_medium.ang8 + aa);
	                            rr = a_medium.rad;
	                            break;
	                        case 2:
	                            ax[0] = tx + lengthdir_x(a_large.len1, a_large.ang1 + aa);
	                            ay[0] = ty + lengthdir_y(a_large.len1, a_large.ang1 + aa);
	                            ax[1] = tx + lengthdir_x(a_large.len2, a_large.ang2 + aa);
	                            ay[1] = ty + lengthdir_y(a_large.len2, a_large.ang2 + aa);
	                            ax[2] = tx + lengthdir_x(a_large.len3, a_large.ang3 + aa);
	                            ay[2] = ty + lengthdir_y(a_large.len3, a_large.ang3 + aa);
	                            ax[3] = tx + lengthdir_x(a_large.len4, a_large.ang4 + aa);
	                            ay[3] = ty + lengthdir_y(a_large.len4, a_large.ang4 + aa);
	                            ax[4] = tx + lengthdir_x(a_large.len5, a_large.ang5 + aa);
	                            ay[4] = ty + lengthdir_y(a_large.len5, a_large.ang5 + aa);
	                            ax[5] = tx + lengthdir_x(a_large.len6, a_large.ang6 + aa);
	                            ay[5] = ty + lengthdir_y(a_large.len6, a_large.ang6 + aa);
	                            ax[6] = tx + lengthdir_x(a_large.len7, a_large.ang7 + aa);
	                            ay[6] = ty + lengthdir_y(a_large.len7, a_large.ang7 + aa);
	                            ax[7] = tx + lengthdir_x(a_large.len8, a_large.ang8 + aa);
	                            ay[7] = ty + lengthdir_y(a_large.len8, a_large.ang8 + aa);
	                            rr = a_large.rad;
	                            break;
	                        }
	                    draw_line(ax[0], ay[0], ax[1], ay[1]);
	                    draw_line(ax[1], ay[1], ax[2], ay[2]);
	                    draw_line(ax[2], ay[2], ax[3], ay[3]);
	                    draw_line(ax[3], ay[3], ax[4], ay[4]);
	                    draw_line(ax[4], ay[4], ax[5], ay[5]);
	                    draw_line(ax[5], ay[5], ax[6], ay[6]);
	                    draw_line(ax[6], ay[6], ax[7], ay[7]);
	                    draw_line(ax[7], ay[7], ax[0], ay[0]); 
	                    a[? "xpos"] = tx;
	                    a[? "ypos"] = ty;
	                    }
	                }
	            // GAME OVER TEXT ////////////////////////////////////////////////////////
	            var xx = rm.width / 2;
	            var yy = map.ID[? "game_over_y"];
	            var cc = map.ID[? "accent_colour"];
	            yy = clamp(yy + 10, -100, rm.height / 2);
	            draw_line(xx, yy - 47, xx + 23, yy - 39);
	            draw_line(xx + 23, yy - 39, xx + 35, yy - 18);
	            draw_line(xx + 35, yy - 18, xx + 36, yy + 3);
	            draw_line(xx + 36, yy + 3, xx + 40, yy + 15);
	            draw_line(xx + 40, yy + 15, xx + 21, yy + 34);
	            draw_line(xx + 21, yy + 34, xx + 19, yy + 45);
	            draw_line(xx + 19, yy + 45, xx - 19, yy + 45);
	            draw_line(xx - 19, yy + 45, xx - 21, yy + 34);
	            draw_line(xx - 21, yy + 34, xx - 40, yy + 15);
	            draw_line(xx - 40, yy + 15, xx - 36, yy + 3);
	            draw_line(xx - 36, yy + 3, xx - 35, yy - 18);
	            draw_line(xx - 35, yy - 18, xx - 23, yy - 39);
	            draw_line(xx - 23, yy - 39, xx, yy - 47);
	            draw_circle_colour(xx - 16, yy, 10, c_white, c_white, true);
	            draw_circle_colour(xx + 16, yy, 10, c_white, c_white, true);
	            draw_circle_colour(xx - 16, yy, 6, cc, cc, false);
	            draw_circle_colour(xx + 16, yy, 6, cc, cc, false);
	            draw_triangle_colour(xx, yy + 11, xx - 9, yy + 25, xx + 9, yy + 25, c_white, c_white, c_white, false);
	            // Fade in text
	            var l_n = 7;
	            var l_l = 0;
	            var sz = 0;
	            if yy >= rm.height / 2
	                {
	                map.ID[? "game_draw_alpha"] = clamp(map.ID[? "game_draw_alpha"] + 0.01, 0, 1);
	                sz = 12 * map.ID[? "game_draw_alpha"];
	                }
	            var str;
	            str[0] = " ***   ***  *   *  ****              ***  *   *  ****  ***";
	            str[1] = "*   * *   * ** ** *                 *   * *   * *     *   *";
	            str[2] = "*     *   * * * * *                 *   * *   * *     *   *";
	            str[3] = "*  ** ***** *   * ***               *   *  * *  ***   ****";
	            str[4] = "*   * *   * *   * *                 *   *  * *  *     * *";
	            str[5] = "*   * *   * *   * *                 *   *  * *  *     *  *";
	            str[6] = " ***  *   * *   *  ****              ***    *    **** *   *";
	            for(var i = 0; i < l_n; i++;)
	                {
	                if string_length(str[i]) > l_l
	                    {
	                    l_l = string_length(str[i]);
	                    }
	                }
	            var xo = (rm.width / 2) - ((l_l * sz) / 2) - sz;
	            var yo = yy - ((l_n * sz) / 2);
	            draw_set_alpha(map.ID[? "game_draw_alpha"]);
	            for(i = 1; i < l_l + 1; i++;)
	                {
	                for(var j = 0; j < l_n; j++;) //...and for each line
	                    {
	                    if string_char_at(str[j],i) != " " && string_char_at(str[j],i) != ""
	                        {
	                        draw_rectangle(xo + (i * sz), yo + (j * sz), xo + (i * sz) + sz, yo + (j * sz) + sz, false);
	                        }
	                    }
	                }
	            // Draw score and finish text
	            draw_set_alpha(1);
	            draw_set_halign(fa_center);
	            if map.ID[? "game_draw_alpha"] >= 1
	                {
	                draw_text(xx, yy + 64, string_hash_to_newline("YOUR SCORE: " + string(map.ID[? "player_score"])));
	                if map.ID[? "game_high_score"] == true
	                    {
	                    draw_text_colour(xx, yy + 80, string_hash_to_newline("NEW HIGH SCORE"), choose(c_white, cc), choose(c_white, cc), choose(c_white, cc), choose(c_white, cc), 1);
	                    }
	                draw_text(xx, rm.height - 32, string_hash_to_newline("Press any key"));
	                // Handle keyboard check for new game
	                if keyboard_check(vk_anykey) || gamepad_button_check(0, gp_face1)
	                    {
	                    map.ID[? "game_state"] = state.gameover_fade;
	                    }
	                }
	            map.ID[? "game_over_y"] = yy;
	            break;
            
	//////////////////////////////////////// GAME OVER TRANSITION///////////////////////////////////////////////
	        case state.gameover_fade:
	            // FADE OUT TEXT /////////////////////////////////////////////////////////
	            var yy = map.ID[? "game_over_y"];
	            var cc = map.ID[? "accent_colour"];
	            yy = clamp(yy + 10, -100, rm.height / 2);
	            var l_n = 7;
	            var l_l = 0;
	            var sz = 0;
	            map.ID[? "game_draw_alpha"] = clamp(map.ID[? "game_draw_alpha"] - 0.05, 0, 1);
	            sz = 12 * map.ID[? "game_draw_alpha"];
	            var str;
	            str[0] = " ***   ***  *   *  ****              ***  *   *  ****  ***";
	            str[1] = "*   * *   * ** ** *                 *   * *   * *     *   *";
	            str[2] = "*     *   * * * * *                 *   * *   * *     *   *";
	            str[3] = "*  ** ***** *   * ***               *   *  * *  ***   ****";
	            str[4] = "*   * *   * *   * *                 *   *  * *  *     * *";
	            str[5] = "*   * *   * *   * *                 *   *  * *  *     *  *";
	            str[6] = " ***  *   * *   *  ****              ***    *    **** *   *";
	            for(var i = 0; i < l_n; i++;)
	                {
	                if string_length(str[i]) > l_l
	                    {
	                    l_l = string_length(str[i]);
	                    }
	                }
	            var xo = (rm.width / 2) - ((l_l * sz) / 2) - sz;
	            var yo = yy - ((l_n * sz) / 2);
	            draw_set_alpha(map.ID[? "game_draw_alpha"]);
	            for(i = 1; i < l_l + 1; i++;)
	                {
	                for(var j = 0; j < l_n; j++;) //...and for each line
	                    {
	                    if string_char_at(str[j],i) != " " && string_char_at(str[j],i) != ""
	                        {
	                        draw_rectangle(xo + (i * sz), yo + (j * sz), xo + (i * sz) + sz, yo + (j * sz) + sz, false);
	                        }
	                    }
	                }
	            draw_set_alpha(1);
	            // CLEAN UP & RESTART ////////////////////////////////////////////////////
	            if map.ID[? "game_draw_alpha"] <= 0
	                {
	                map.ID[? "game_state"] = state.intro;
	                map.ID[? "game_over_y"] = -100;
	                map.ID[? "game_high_score"] = false;
	                map.ID[? "game_level"] = 1;
	                for (var i = 0; i < ds_list_size(a_list); i++;)
	                    {
	                    var a = ds_list_find_value(a_list, i);
	                    ds_map_destroy(a);
	                    }
	                for (var i = 0; i < ds_list_size(b_list); i++;)
	                    {
	                    var a = ds_list_find_value(b_list, i);
	                    ds_map_destroy(a);
	                    }
	                ds_list_clear(a_list);
	                ds_list_clear(b_list);
	                }
	            else
	                {
	                repeat(100)
	                    {
	                    if irandom(29) == 0 var c = map.ID[? "accent_colour"] else var c = merge_colour(c_white, c_black, random(0.75));
	                    part_particles_create_colour(map.ID[? "p_sys"], rm.width / 2, rm.height / 2, map.ID[? "p1"], c, 1);
	                    part_system_update(map.ID[? "p_sys"]);
	                    part_system_drawit(map.ID[? "p_sys"]);
	                    }
	                }
	            break;
	        }
	    }






}
