/// @description sc_flappysouls()
function FlappySouls() {
	/*

	Flappy Souls by Threef

	Use space to fly and try to avoid hitting walls.
	Eveytime you die you'll destroy the piece of wall you hit.
	Next time your ghost will fly ahead of you showinng you path you flown.
	Seed of game resets every day. That means your progress resets at 00:00.

	*/

	enum gamestate {
	    play,
	    death,
	    menu
	}

	var map=0;
	var grav=0.7;
	var jumpPower=15;
	var hspd=6
	var ghostDistance=16;//192;
	var enemiesDistance=48;//64

	var playSounds=true; //Change to false if you don't want to hear it


	if(!ds_exists(map,ds_type_map)) {
	    //Init
	    room_speed=60
	    random_set_seed(date_date_of(date_current_datetime()))
	    __background_set_colour( $333333 )
	    display_set_windows_alternate_sync(1)
    
	    view_enabled=true
	    __view_set( e__VW.Visible, 0, true )
	    __view_set( e__VW.XView, 0, -__view_get( e__VW.WView, 0 ) )
    
	    var data=ds_map_create();
    
	    if(file_exists("data.json")) {
	        var f=file_text_open_read("data.json");
	        var s=file_text_read_string(f);
	        data=json_decode(s)
	        file_text_close(f)
        
	        //show_debug_message(json_encode(data))
        
	        if(data[?"seed"]!=random_get_seed()) {
	            ds_list_clear(data[?"prev runs"])
	            ds_list_clear(data[?"enemies"])
	        }           
        
	        ds_map_copy(0,data)
	        ds_map_add_map(0, "this run", data[?"this run"])
	        ds_map_add_list(0, "enemies", data[?"enemies"])
	        ds_map_add_list(0, "prev runs", data[?"prev runs"])
	        //ds_map_destroy(data)
	        data=0    
	    } else {                
	        data[?"seed"]=random_get_seed()
	        data[?"game step"]=0        
        
	        ds_map_add_list(data, "prev runs", ds_list_create())
        
	        ds_map_add_map(data, "this run", ds_map_create())
	        ds_map_add_list(data[?"this run"], "key press list", ds_list_create())
	        ds_map_add(data[?"this run"], "x", room_width/2)
	        ds_map_add(data[?"this run"], "y", room_height/2)
	        ds_map_add(data[?"this run"], "vspeed", 0)
	        ds_map_add(data[?"this run"], "number", 1)
           
	        ds_map_add_list(data, "enemies", ds_list_create())
	    }
    
	    data[?"game state"]=gamestate.menu
    
	    data[?"surface bird"]=-4
	    data[?"surface enemy"]=-4
	    data[?"surface ghosts"]=-4
	    data[?"sound death"]=-4
	    data[?"sound jump"]=-4
    
	    data[?"surface text - you died"]=-4
	    data[?"surface text - PRESS SPACE"]=-4
	    data[?"surface text - FLAPPY SOULS"]=-4
	    data[?"surface text - PRESS SPACE TO PLAY"]=-4
    
	    //show_debug_message(json_encode(data))
    
	} else {
	    //Main game loop
	    var data=map;
    
	    //Clear buffers in next game loop
	    /*for(var i=0; i<10; i++) {
	        if(buffer_exists(i)) {
	            //buffer_delete(i)
	        }
	    }*/
    
	    //Create bird sprite
	    if(!sprite_exists(data[?"surface bird"])) {
	        var w=180
	        var h=160
	        var s=surface_create(w,h)
	        surface_set_target(s)
	        draw_set_color($999999)
	        draw_circle(w/2,h/2,64,0)
        
	        draw_triangle(w/2+5,h/2-64-6,w/2-5,h/2-64+5,w/2,h/2-64+8,0)
	        draw_triangle(w/2+12,h/2-64-7,w/2-5,h/2-64+5,w/2,h/2-64+8,0)
	        draw_triangle(w/2+16,h/2-64-9,w/2-3,h/2-64+5,w/2+2,h/2-64+8,0)
        
	        draw_ellipse(w/2 -90,h/2 -24,w/2 -44,h/2 -4,0)
	        draw_ellipse(w/2 -75,h/2 -15,w/2 -44,h/2 +6,0)
	        draw_ellipse(w/2 +90,h/2 -24,w/2 +44,h/2 -4,0)
	        draw_ellipse(w/2 +75,h/2 -15,w/2 +44,h/2 +6,0)        
        
	        draw_set_blend_mode_ext(bm_dest_alpha, bm_src_alpha)
	        draw_set_colour($bbbbbb)
	        draw_ellipse(w/2-64-16,w/2-16,w/2+64+16,w/2+64+22,0)        
	        draw_set_blend_mode(bm_normal)
        
	        draw_set_colour($777777)
	        draw_circle(w/2-32,w/2-32,4,0)
	        draw_circle(w/2-32+64,w/2-32,4,0)
        
	        draw_set_colour($bbbbbb)
	        draw_ellipse(w/2-18,w/2-16-5,w/2+18,w/2-16+5,0) 
        
	        surface_reset_target()
	        data[?"surface bird"]=sprite_create_from_surface(s,0,0,w,h,0,0,w/2,h/2)
	        surface_free(s)
    
	    }
    
	    //Create enemy
	    if(!surface_exists(data[?"surface enemy"])) {
	        data[?"surface enemy"]=surface_create(128,128)
	        surface_set_target(data[?"surface enemy"])
	        draw_set_color(c_white)
	        draw_circle(64,64,64,0)
	        surface_reset_target()
	    }
    
	    //Create sounds
	    if(data[?"sound death"]=-4 && !audio_exists(data[?"sound death"])) {
	        var rate = 50000; //44100;
	        var parts = 4;
	        var hertz = 400;
	        var samples = 44100;
	        var bufferId = buffer_create(rate, buffer_fast, 1);
	        buffer_seek(bufferId, buffer_seek_start, 0);
	        for(var p=0; p<parts; p++) {
	            var num_to_write = rate / hertz;
	            var val_to_write = 1;
	            for (var i = 0; i < (samples / parts / num_to_write) + 1; i++;) {
	               for (var j = 0; j < num_to_write; j++;) {
	                  buffer_write(bufferId, buffer_u8, val_to_write * 255);
	               }
	               val_to_write = (1 - val_to_write);
	            }
            
	            hertz -= 50
	        }
	        data[?"sound death"] = audio_create_buffer_sound(bufferId, buffer_u8, rate, 0, samples, audio_mono);
	        //buffer_delete(bufferId)
	    }
    
	    if(data[?"sound jump"]=-4 && !audio_exists(data[?"sound jump"])) {
	        var rate = 44100;
	        var parts = 3;
	        var hertz = 540;
	        var samples = 4410;
	        var bufferId = buffer_create(rate, buffer_fast, 1);
	        buffer_seek(bufferId, buffer_seek_start, 0);
	        for(var p=0; p<parts; p++) {
	            var num_to_write = rate / hertz;
	            var val_to_write = 1;
	            for (var i = 0; i < (samples / parts / num_to_write) + 1; i++;) {
	               for (var j = 0; j < num_to_write; j++;) {
	                  buffer_write(bufferId, buffer_u8, val_to_write * 255);
	               }
	               val_to_write = (1 - val_to_write);
	            }
            
	            hertz -= 40
	        }
	        data[?"sound jump"] = audio_create_buffer_sound(bufferId, buffer_u8, rate, 0, samples, audio_mono);
	        //buffer_delete(bufferId)
	    }
    
	    //Create texts
	    if(!surface_exists(data[?"surface text - FLAPPY SOULS"])) {
	        var pixel_width=6;
	        var pixel_height=7;
	        var text="";
	        text[0]= "                                                                                                                                                                "
	        text[1]= "           BBBBBBBBBBBBBB  BBBBBBBBBBBBBBB   BBBBBBBB   BBBBBBBBBBBBB           XXXXXXXXXXX     XXXXXXXX     XXXXX        XXX  XXXXX             XXXXXXXXXXX    "
	        text[2]= "          BXXXXXXXXBXXXXB BXXXXXXXBXXXXXXXBB BXXXXXXXBB BXXXXXBXXXXXB        XXXXX      XX    XXX       XX    XXX          X    XXX           XXXXX      XX     "
	        text[3]= "         BXXXXXXXXXBXXXXBBXXXXXXXXBXXXXXXXXXBBXXXXXXXXXBBXXXXXBXXXXXB       XXXX         X   XXX          X   XXX          X    XXX          XXXX         X     "
	        text[4]= "         BXXXXBBBBBBXXXXBXXXXXXXXXBXXXXXXXXXXBXXXXXXXXXXBXXXXXBXXXXXB       XXXX             XXX          X   XXX          X    XXX          XXXX               "
	        text[5]= "         BXXXXXXXXXBXXXXBXXXXXXXXXBXXXXXXXXXXBXXXXXXXXXXBXXXXXBXXXXXB       XXXXX            XXX          X   XXX          X    XXX          XXXXX              "
	        text[6]= "         BXXXXXXXXXBXXXXBXXXXBXXXXBXXXXXBXXXXBXXXXXBXXXXBXXXXXBXXXXXB        XXXXXX          XXX          X   XXX          X    XXX           XXXXXX            "
	        text[7]= "         BXXXXXXXXXBXXXXBXXXXBXXXXBXXXXXBXXXXBXXXXXBXXXXBXXXXXBXXXXXB         XXXXXXX        XXX          X   XXX          X    XXX            XXXXXXX          "
	        text[8]= "         BXXXXBBBBBBXXXXBXXXXBXXXXBXXXXXBXXXXBXXXXXBXXXXBXXXXXXXXXXXBBBBBBBBBBBBXXXXXXBBBBBBBXXXBBBBBBBBBBXBBBXXXBBBBBBBBBBXBBBBXXXBBBBBBBBBBBBBBXXXXXXBBBBBBBBB"
	        text[9]= "         BXXXXBBBBBBXXXXBXXXXBXXXXBXXXXXBXXXXBXXXXXBXXXXBXXXXXXXXXXXB             XXXXXX     XXX          X   XXX          X    XXX                XXXXXX       "
	        text[10]="         BXXXXB    BXXXXBXXXXBXXXXBXXXXXBXXXXBXXXXXBXXXXBBXXXXXXXXXXB               XXXXXX   XXX          X   XXX          X    XXX                  XXXXXX     "
	        text[11]="         BXXXXB    BXXXXBXXXXXXXXXBXXXXXXXXXXBXXXXXXXXXXBBBXXXXXXXXXB                 XXXXX  XXX          X   XXX          X    XXX                    XXXXX    "
	        text[12]="         BXXXXB    BXXXXBBXXXXXXXXBXXXXXXXXXBBXXXXXXXXXBB BBBBXXXXXXB                  XXXX  XXX          X   XXX          X    XXX                     XXXX    "
	        text[13]="         BXXXXB    BXXXXBBBXXXXXXXBXXXXXXXXBBBXXXXXXXXBB   BBBXXXXXXB        X         XXXX  XXX          X   XXX          X    XXX           X         XXXX    "
	        text[14]="         BBBBBB    BBBBBB  BBBBBBBBXXXXXBBBB BXXXXXBBBB     BXXXXXXXB        XX      XXXXX    XXX       XX     XXX       XX     XXX       X   XX      XXXXX     "
	        text[15]="         BBBBBB    BBBBBB   BBBBBBBXXXXXBBB  BXXXXXBBB      BXXXXXXXB       XXXXXXXXXXX         XXXXXXXX         XXXXXXXX      XXXXXXXXXXXX  XXXXXXXXXXX        "
	        text[16]="                                  BXXXXXB    BXXXXXB        BXXXXXXBB                                                                                           "
	        text[17]="                                  BXXXXXB    BXXXXXB        BXXXXXBB                                                                                            "
	        text[18]="                                  BBBBBBB    BBBBBBB        BBBBBBB                                                                                             "
	        text[19]="                                  BBBBBBB    BBBBBBB        BBBBB                                                                                               "
        
        
	        data[?"surface text - FLAPPY SOULS"]=surface_create(string_length(text[0])*pixel_width, array_length_1d(text)*pixel_height)
        
	        surface_set_target(data[?"surface text - FLAPPY SOULS"])
	        draw_clear_alpha(0,0)
	        draw_set_color(c_white)
	        for(var _y=0; _y<array_length_1d(text); _y++)
	        for(var _x=0; _x<string_length(text[0]); _x++) {
	            if(string_char_at(text[_y],_x+1)="X") {
	                draw_set_color(c_white)
	                draw_rectangle(_x*pixel_width,_y*pixel_height,(_x+1)*pixel_width-1,(_y+1)*pixel_height-1,0)
	            }
	            if(string_char_at(text[_y],_x+1)="B") {
	                draw_set_color($333333)
	                draw_rectangle(_x*pixel_width,_y*pixel_height,(_x+1)*pixel_width-1,(_y+1)*pixel_height-1,0)
	            }
	        }
	        surface_reset_target()
	    }
    
	    if(!surface_exists(data[?"surface text - PRESS SPACE TO PLAY"])) {
	        var pixel_width=8;
	        var pixel_height=10;
	        var text="";
	        text[0]="                                                                                                    "
	        text[1]=" XXXX  XXXX  XXXXX  XXX   XXX     XXX XXXX   XXX   XXX XXXX   XXXXX  XXX    XXXX  X     XXX  X   X  "
	        text[2]=" X   X X   X X     X     X       X    X   X X   X X    X        X   X   X   X   X X    X   X X   X  "
	        text[3]=" X   X X   X X     X     X       X    X   X X   X X    X        X   X   X   X   X X    X   X X   X  "
	        text[4]=" XXXX  XXXX  XXXX  XXXX  XXXX    XXXX XXXX  XXXXX X    XXX      X   X   X   XXXX  X    XXXXX  X X   "
	        text[5]=" X     X X   X        X     X       X X     X   X X    X        X   X   X   X     X    X   X   X    "
	        text[6]=" X     X  X  X        X     X       X X     X   X X    X        X   X   X   X     X    X   X   X    "
	        text[7]=" X     X   X XXXXX XXX   XXX     XXX  X     X   X  XXX XXXX     X    XXX    X     XXXX X   X   X    "
        
        
	        data[?"surface text - PRESS SPACE TO PLAY"]=surface_create(string_length(text[0])*pixel_width, array_length_1d(text)*pixel_height)
        
	        surface_set_target(data[?"surface text - PRESS SPACE TO PLAY"])
	        draw_clear_alpha(0,0)
	        draw_set_color(c_white)
	        for(var _y=0; _y<array_length_1d(text); _y++)
	        for(var _x=0; _x<string_length(text[0]); _x++) {
	            if(string_char_at(text[_y],_x+1)="X") {
	                draw_rectangle(_x*pixel_width,_y*pixel_height,(_x+1)*pixel_width-1,(_y+1)*pixel_height-1,0)
	            }
	        }
	        surface_reset_target()
	    }
    
	    if(!surface_exists(data[?"surface text - you died"])) {
	        var pixel_width=12;
	        var pixel_height=16;
	        var text="";
	        text[0]="                                              "
	        text[1]=" X   X  XXX  X   X   XXXX  X XXXXX XXXX  XX   "
	        text[2]=" X   X X   X X   X   X   X X X     X   X XX   "
	        text[3]="  X X  X   X X   X   X   X X X     X   X XX   "
	        text[4]="   X   X   X X   X   X   X X XXXX  X   X XX   "
	        text[5]="   X   X   X X   X   X   X X X     X   X XX   "
	        text[6]="   X   X   X X   X   X   X X X     X   X      "
	        text[7]="   X    XXX   XXX    XXXX  X XXXXX XXXX  XX   "
        
        
	        data[?"surface text - you died"]=surface_create(string_length(text[0])*pixel_width, array_length_1d(text)*pixel_height)
        
	        surface_set_target(data[?"surface text - you died"])
	        draw_clear_alpha(0,0)
	        draw_set_color(c_white)
	        for(var _y=0; _y<array_length_1d(text); _y++)
	        for(var _x=0; _x<string_length(text[0]); _x++) {
	            if(string_char_at(text[_y],_x+1)="X") {
	                draw_rectangle(_x*pixel_width,_y*pixel_height,(_x+1)*pixel_width-1,(_y+1)*pixel_height-1,0)
	            }
	        }
	        surface_reset_target()
	    }
    
	    if(!surface_exists(data[?"surface text - PRESS SPACE"])) {
	        var pixel_width=6;
	        var pixel_height=5;
	        var text="";
	        text[0]="                                                             "
	        text[1]=" XXXX  XXXX  XXXXX  XXX   XXX     XXX XXXX   XXX   XXX XXXX "
	        text[2]=" X   X X   X X     X     X       X    X   X X   X X    X    "
	        text[3]=" X   X X   X X     X     X       X    X   X X   X X    X    "
	        text[4]=" XXXX  XXXX  XXXX  XXXX  XXXX    XXXX XXXX  XXXXX X    XXX  "
	        text[5]=" X     X X   X        X     X       X X     X   X X    X    "
	        text[6]=" X     X  X  X        X     X       X X     X   X X    X    "
	        text[7]=" X     X   X XXXXX XXX   XXX     XXX  X     X   X  XXX XXXX "
        
        
	        data[?"surface text - PRESS SPACE"]=surface_create(string_length(text[0])*pixel_width, array_length_1d(text)*pixel_height)
        
	        surface_set_target(data[?"surface text - PRESS SPACE"])
	        draw_clear_alpha(0,0)
	        draw_set_color(c_white)
	        for(var _y=0; _y<array_length_1d(text); _y++)
	        for(var _x=0; _x<string_length(text[0]); _x++) {
	            if(string_char_at(text[_y],_x+1)="X") {
	                draw_rectangle(_x*pixel_width,_y*pixel_height,(_x+1)*pixel_width-1,(_y+1)*pixel_height-1,0)
	            }
	        }
	        surface_reset_target()
	    }
    
	    //Draw mountains
	    draw_set_colour($222222)
	    draw_rectangle(__view_get( e__VW.XView, 0 ), 0, __view_get( e__VW.XView, 0 )+__view_get( e__VW.WView, 0 ), (room_height*0.6), 0)
	    for(var i=(__view_get( e__VW.XView, 0 )-__view_get( e__VW.WView, 0 )/2)-(__view_get( e__VW.XView, 0 )%128); i<__view_get( e__VW.XView, 0 )+__view_get( e__VW.WView, 0 )*3/2; i+=128) {        
	        var _y=(room_height*0.6)+dsin(i)*16
	        var _h=64
	        draw_ellipse(i-150, _y-_h,i+150, _y+_h,0)
	    }
    
	    if(data[?"game state"]=gamestate.play || data[?"game state"]=gamestate.death) {
	        var myBird=data[?"this run"];
        
	        //Enemies
	        for(var n=0; n<ds_list_size(data[?"enemies"]); n++) {
	            var currentEnemy=ds_list_find_value(data[?"enemies"], n);

	            if((!ds_map_exists(currentEnemy,"death") || currentEnemy[?"death"]>data[?"game step"]) && currentEnemy[?"y"]<room_height+64 && currentEnemy[?"x"]>__view_get( e__VW.XView, 0 )-64 && currentEnemy[?"x"]<__view_get( e__VW.XView, 0 )+__view_get( e__VW.WView, 0 )+64) {
	                var color=$777777;
	                if(ds_map_exists(currentEnemy,"death")) {
	                    color=$666666
	                }
	                if(surface_exists(currentEnemy[?"image"])) {
	                    draw_surface_ext(currentEnemy[?"image"], round(currentEnemy[?"x"]-64), round(currentEnemy[?"y"]-64), 1, 1, 0, color, 1)
	                }
	            }
	        }
    
	        //Previous runs
	        if(!surface_exists(data[?"surface ghosts"])) {
	            data[?"surface ghosts"]=surface_create(__view_get( e__VW.WView, 0 ),__view_get( e__VW.HView, 0 ))
	        }
        
	        surface_set_target(data[?"surface ghosts"])
	        draw_clear_alpha(0,0)
	        for(var n=0; n<ds_list_size(data[?"prev runs"]); n++) {
	            var currentGhost=ds_list_find_value(data[?"prev runs"], n);
        
	            currentGhost[?"x"]+=hspd
	            currentGhost[?"y"]+=currentGhost[?"vspeed"]
	            currentGhost[?"y"]=clamp(currentGhost[?"y"],0-64,room_width+64)
	            currentGhost[?"vspeed"]+=grav //Gravity
            
	            if(ds_exists(currentGhost[?"key press list"], ds_type_list) && ds_list_find_index(currentGhost[?"key press list"], currentGhost[?"live"])!=-1) {
	                currentGhost[?"vspeed"]=-jumpPower
	            }
            
	            var angle=0;
	            if(currentGhost[?"live"]>currentGhost[?"death"]) {
	                angle=max(-60,currentGhost[?"death"]-currentGhost[?"live"])*3
	            }
            
	            if(currentGhost[?"y"]<room_height+64 && currentGhost[?"x"]>__view_get( e__VW.XView, 0 )-64 && currentGhost[?"x"]<__view_get( e__VW.XView, 0 )+__view_get( e__VW.WView, 0 )+64) {
	                if(sprite_exists(data[?"surface bird"])) {
	                    draw_sprite_ext(data[?"surface bird"], 0, round(currentGhost[?"x"]-__view_get( e__VW.XView, 0 )), round(currentGhost[?"y"]-__view_get( e__VW.YView, 0 )), 1, 1, sin(currentGhost[?"x"]/30)*10-angle, $777777, 1) 
	                }
	            }
            
	            currentGhost[?"live"]++
	        }        
	        surface_reset_target()
	        draw_surface_ext(data[?"surface ghosts"],__view_get( e__VW.XView, 0 ),__view_get( e__VW.YView, 0 ),1,1,0,c_white,0.1)
	        //surface_free(data[?"surface ghosts"])
        
	        //Player sprite
	        var myBird=data[?"this run"];
	        myBird[?"x"]+=hspd
	        myBird[?"y"]+=myBird[?"vspeed"]
	        myBird[?"y"]=clamp(myBird[?"y"],0-64,room_width+64)
	        myBird[?"vspeed"]+=grav //Gravity

	        var angle=0;
	        if(data[?"game step"]>myBird[?"death"]) {
	            angle=max(-60,myBird[?"death"]-data[?"game step"])*3
	        }
        
	        if(sprite_exists(data[?"surface bird"])) {
	            draw_sprite_ext(data[?"surface bird"], 0, round(myBird[?"x"]), round(myBird[?"y"]), 1, 1, sin(myBird[?"x"]/30)*10-angle, $777777, 1) 
	        }
	    }
    
	    if(data[?"game state"]=gamestate.play) {        
	        //Game
	        var myBird=data[?"this run"];        
        
	        //view_xview[0]=floor(lerp(view_xview[0], myBird[?"x"]-view_wview[0]*0.2, 2/room_speed))
	        __view_set( e__VW.XView, 0, floor(lerp(__view_get( e__VW.XView, 0 ), myBird[?"x"]-__view_get( e__VW.WView, 0 )*0.2, 0.1)) )
        
	        if(keyboard_check_pressed(vk_space)) {
	            var kpl=myBird[?"key press list"];
	            ds_list_add(kpl, data[?"game step"])
	            myBird[?"vspeed"]=-jumpPower
            
	            if(playSounds && !audio_is_playing(data[?"sound jump"])) {
	                audio_play_sound(data[?"sound jump"],1,0)
	            }
	        }
        
	        //draw_surface_ext(data[?"surface bird"], round(myBird[?"x"]-64), round(myBird[?"y"]-64), 1, 1, 0, $777777, 1)        
        
	        if(myBird[?"y"]>room_height+64 || myBird[?"y"]<-64) {
	            data[?"game state"]=gamestate.death
	            myBird[?"death"]=data[?"game step"]
            
	            if(playSounds && !audio_is_playing(data[?"sound death"])) {
	                audio_play_sound(data[?"sound death"],1,0)
	            }
	        }
        
	        //Enemies
	        var enemies=data[?"enemies"];
	        if(ds_list_empty(enemies)) {
	            var enemy=ds_map_create();
	            enemy[?"x"]=max(__view_get( e__VW.XView, 0 ),0)+__view_get( e__VW.WView, 0 )
	            enemy[?"y"]=__view_get( e__VW.HView, 0 )-irandom(__view_get( e__VW.HView, 0 )/3)
	            enemy[?"image"]=data[?"surface enemy"]
	            enemy[?"death"]=-1
	            ds_list_add(enemies,enemy)
	            ds_list_mark_as_map(enemies, ds_list_size(enemies)-1)
	        }
        
	        for(var n=0; n<ds_list_size(enemies); n++) {
	            var enemy=enemies[|n];
            
	            //Check collision
	            if(!ds_map_exists(enemy,"death") && sqr(abs(enemy[?"x"]-myBird[?"x"]))+sqr(abs(enemy[?"y"]-myBird[?"y"]))<sqr(64+64)) {
	                data[?"game state"]=gamestate.death
	                enemy[?"death"]=data[?"game step"]
	                myBird[?"death"]=data[?"game step"]
                
	                if(playSounds && !audio_is_playing(data[?"sound death"])) {
	                    audio_play_sound(data[?"sound death"],1,0)
	                }
	            }
	        }

	        //Spawn more enemies
	        var lastEnemy=enemies[|ds_list_size(enemies)-1];
	        if(lastEnemy[?"x"]<max(__view_get( e__VW.XView, 0 ),0)+__view_get( e__VW.WView, 0 )+enemiesDistance) {
	            var used=false;
	            for(var _y=0; _y<=room_height+enemiesDistance; _y+=enemiesDistance) {
                
	                var enemy=ds_map_create();
	                enemy[?"x"]=lastEnemy[?"x"]+enemiesDistance
	                enemy[?"y"]=_y
	                enemy[?"image"]=data[?"surface enemy"]
    
	                ds_list_add(enemies,enemy)
	                ds_list_mark_as_map(enemies, ds_list_size(enemies)-1)
                
	                if(used=false && random(100)<60 && _y>=enemiesDistance) {
	                    _y+=room_height*random_range(0.5,0.8)
	                    _y=ceil(_y/enemiesDistance)*enemiesDistance
	                    used=true
	                }
                
	            }
	        }
                
	    }
    
	    if(data[?"game state"]=gamestate.play || data[?"game state"]=gamestate.death) {
	        //Move time
	        data[?"game step"]++
	    }
    
	    if(data[?"game state"]=gamestate.death) {
        
	        //On death reset game
	        if(keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_escape)) {
            
	            data[?"game state"]=gamestate.play
	            var tr=data[?"this run"];
                                 
	            //Reset variables to init values         
	            for(var n=0; n<ds_list_size(data[?"prev runs"]); n++) {
	                var currentGhost=ds_list_find_value(data[?"prev runs"], n);
	                currentGhost[?"x"]=room_width/2
	                currentGhost[?"y"]=room_height/2
	                currentGhost[?"vspeed"]=0
	                currentGhost[?"live"]=0
	            }
            
	            //Save this run as a ghost
	            var ghost=ds_map_create();
            
	            ghost[?"x"]=room_width/2
	            ghost[?"y"]=room_height/2
	            ghost[?"vspeed"]=0
	            ghost[?"live"]=0
	            ghost[?"death"]=tr[?"death"]
	            ghost[?"number"]=tr[?"number"]
	            var kpl=ds_list_create();
            
	            ds_list_copy(kpl, tr[?"key press list"])
	            ds_map_add_list(ghost, "key press list", kpl)
                    
	            ds_list_add(data[?"prev runs"],ghost)
	            ds_list_mark_as_map(data[?"prev runs"], ds_list_size(data[?"prev runs"])-1)
            
            
	            ds_map_destroy(data[?"this run"])
	            ds_map_add_map(data, "this run", ds_map_create())
	            ds_map_add_list(data[?"this run"], "key press list", ds_list_create())
	            ds_map_set(data[?"this run"], "x", room_width/2)
	            ds_map_set(data[?"this run"], "y", room_height/2)
	            ds_map_set(data[?"this run"], "vspeed", 0)
	            ds_map_set(data[?"this run"], "number", ds_list_size(data[?"prev runs"])+1)
            
	            //view_xview[0]=0
            
	            //Skip some distance for ghosts
	            for(var n=0; n<ds_list_size(data[?"prev runs"]); n++) {
	                var currentGhost=ds_list_find_value(data[?"prev runs"], n);

	                repeat((ds_list_size(data[?"prev runs"])+1-currentGhost[?"number"])*ghostDistance) {
	                    currentGhost[?"x"]+=hspd
	                    currentGhost[?"y"]+=currentGhost[?"vspeed"]
	                    currentGhost[?"y"]=clamp(currentGhost[?"y"],0-64,room_width+64)
	                    currentGhost[?"vspeed"]+=grav //Gravity

	                    if(ds_exists(currentGhost[?"key press list"], ds_type_list) && ds_list_find_index(currentGhost[?"key press list"], currentGhost[?"live"])!=-1) {
	                        currentGhost[?"vspeed"]=-jumpPower
	                    }
                    
	                    currentGhost[?"live"]++
	                }
	            }
            
	            //Move enemies
	            for(var n=0; n<ds_list_size(data[?"enemies"]); n++) {
	                var currentEnemy=ds_list_find_value(data[?"enemies"], n);
	                if(ds_map_exists(currentEnemy,"death")) {
	                    currentEnemy[?"death"]-=ghostDistance
	                }
	            }
            
	            data[?"game step"]=0
            
	            var f=file_text_open_write("data.json");
	            file_text_write_string(f,json_encode(0));
	            file_text_close(f)        
            
	            //show_debug_message(json_encode(data))            
                
	            //Go to menu
	            if(keyboard_check_pressed(vk_escape)) {
	                data[?"game state"]=gamestate.menu
	                exit
	            }
	        }
        
	        //"YOU DIED!" text
	        var _x=__view_get( e__VW.XView, 0 )+__view_get( e__VW.WView, 0 )*0.5;
	        var _y=__view_get( e__VW.YView, 0 )+__view_get( e__VW.HView, 0 )*0.4;
	        var _a=0;       
	        var s=data[?"surface text - you died"];
	        draw_surface(s, _x-surface_get_width(s)/2, _y-surface_get_height(s)/2)
        
	        //"Press SPACE" text
	        var _x=__view_get( e__VW.XView, 0 )+__view_get( e__VW.WView, 0 )*0.5;
	        var _y=__view_get( e__VW.YView, 0 )+__view_get( e__VW.HView, 0 )*0.6;
	        var _a=0;
	        var s=data[?"surface text - PRESS SPACE"];
	        draw_surface(s, _x-surface_get_width(s)/2, _y-surface_get_height(s)/2)
	    }
    
	    if(data[?"game state"]=gamestate.menu) {
    
	        __view_set( e__VW.XView, 0, floor(lerp(__view_get( e__VW.XView, 0 ), -__view_get( e__VW.WView, 0 ), 0.1)) )
    
	        //End game
	        if(keyboard_check_pressed(vk_escape)) {
	            game_end()
	            exit
	        }
    
	        //On death reset game
	        if(keyboard_check_pressed(vk_space)) {
	            data[?"game step"]=0
	            data[?"game state"]=gamestate.play
	            exit
	        }
        
	        //"FLAPPY SOULS" text
	        var _x=__view_get( e__VW.XView, 0 )+__view_get( e__VW.WView, 0 )*0.5;
	        var _y=__view_get( e__VW.YView, 0 )+__view_get( e__VW.HView, 0 )*0.25;
	        var _a=0;       
	        var s=data[?"surface text - FLAPPY SOULS"];
	        draw_surface(s, _x-surface_get_width(s)/2, _y-surface_get_height(s)/2)
        
	        //"PRESS SPACE TO PLAY" text
	        var _x=__view_get( e__VW.XView, 0 )+__view_get( e__VW.WView, 0 )*0.5;
	        var _y=__view_get( e__VW.YView, 0 )+__view_get( e__VW.HView, 0 )*0.85;
	        var _a=0;
	        var s=data[?"surface text - PRESS SPACE TO PLAY"];
	        draw_surface(s, _x-surface_get_width(s)/2, _y-surface_get_height(s)/2)
	    }
	}





}
