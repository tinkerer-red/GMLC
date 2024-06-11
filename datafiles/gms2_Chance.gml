function Chance() {
	// chance's OSG entry

	// INIT LOOP
	if (!ds_exists(0,ds_type_map))
	  { randomize();
	    var W = 800; var H = 500;
	    window_set_size(W,H);
	    surface_resize(application_surface,W,H);
	    view_enabled = true; __view_set( e__VW.Visible, 0, true );
	    __view_set( e__VW.WPort, 0, W ); __view_set( e__VW.HPort, 0, H );
	    __view_set( e__VW.WView, 0, W ); __view_set( e__VW.HView, 0, H );
	    __background_set_colour( c_dkgray ); __background_set_showcolour( true );

	    draw_set_halign(fa_center); draw_set_valign(fa_middle);

	// CREATE BACKGROUNDS
	    var L1 = 125; var L2 = 290; var L3 = 465; // level heights
	    var c1, c2, c3; // colors for each floor   
	    c1[0] = make_color_rgb(0,130,255); c2[0] = make_color_rgb(80,170,255); c3[0] = make_color_rgb(140,190,255); 
	    c1[1] = make_color_rgb(255,130,0); c2[1] = make_color_rgb(255,170,80); c3[1] = make_color_rgb(255,190,140);
	    c1[2] = make_color_rgb(130,170,100); c2[2] = make_color_rgb(170,200,150); c3[2] = make_color_rgb(190,220,180);
	    var surf_bk = surface_create(W,H);
	    surface_set_target(surf_bk);
	    for (var i=0; i<3; i++;)
	      { draw_clear_alpha(c_black,0);
	        draw_set_colour(c1[i]); draw_rectangle(0,0,W,L1,0); 
	        draw_set_colour(c2[i]); draw_rectangle(0,L1,W,L2,0);
	        draw_set_colour(c3[i]); draw_rectangle(0,L2,W,H,0);
	        draw_set_color(c_gray);
	        draw_rectangle(0,L1,W,L1+40,false); //  place floors
	        draw_rectangle(0,L2,W,L2+40,false);
	        draw_rectangle(0,L3,W,L3+40,false);
	        if (surface_exists(surf_bk))
	             { __background_set( e__BG.Index, i, background_create_from_surface(surf_bk,0,0,W,H,0,0) ); }
	        else { __background_set( e__BG.Index, i, background_create_colour(W,H,c2) ); }
	      }
	    surface_reset_target(); surface_free(surf_bk);
	    draw_set_color(c_white);

	// CREATE SOUNDS
	    var freq, dur, n_samples, val, i, j, snd_buff, snd_buff2;  // beep sound
	    freq = 880; dur = 4410; n_samples = 44100/freq;
	    snd_buff = buffer_create(44100,buffer_fast,1);
	    buffer_seek(snd_buff,buffer_seek_start,0);
	    val = 1;
	    for (i=0; i<1+dur/n_samples; i++;)
	        { for (j=0; j<n_samples; j++;)
	           { buffer_write(snd_buff,buffer_u8,val*255); }
	          val = 1-val; // 0-1 toggle
	        }
	    var snd_beep = audio_create_buffer_sound(snd_buff,buffer_u8,44100,0,dur,audio_mono);

	    freq = 880; dur = 441; n_samples = 44100/freq; // thud sound
	    snd_buff2 = buffer_create(44100,buffer_fast,1);
	    buffer_seek(snd_buff2,buffer_seek_start,0);
	    val = 1; var imax = 1+dur/n_samples;
	    for (i=0; i<imax; i++;)
	        { for (j=0; j<n_samples; j++;)
	           { buffer_write(snd_buff2,buffer_u8,200*i/imax); }
	          val = 1-val; // 0-1 toggle
	        }
	    var snd_thud = audio_create_buffer_sound(snd_buff2,buffer_u8,44100,0,dur,audio_mono);

	// CREATE FONT SPRITES
	    var text, spr_text, w, h, w0, h0, scale, pix, char;
	    text[0] = "JUST SPACE"; text[1] = "You Win!"; // intro and final text
	    w = 8; h = 12; // default font character size
	    scale = 10; w0 = scale*w; h0 = 1.5*w0; // rendered font character size 
	    pix = 3;  // pix is rendered "pixel" halfwidth
    
	    for (var n=0; n<2; n++;)
	        { if (n == 1) { w = 12; w0 = 120; } // last minute kludge for second text
	          var surf = surface_create(w,h);
	          var surf_font = surface_create(w0,h0);
    
	          spr_text[n] = sprite_create_from_surface(surf_font,0,0,w0,h0,false,true,w0/2,h0/2); // first image empty
	          draw_set_color(c_red);
    
	          for (var m=1; m<string_length(text[n])+1; m++;)  // write character to small surface
	            { char = string_copy(text[n],m,1);
	              surface_set_target(surf);
              
	              draw_clear_alpha(c_black,0); draw_text(w/2,h/2,string_hash_to_newline(char));
	              surface_reset_target();
        
	              surface_set_target(surf_font); // find each pixel, draw square on new suface
	              draw_clear_alpha(c_black,0);
	              for (i=0; i<w; i++;)
	                { for (j=0; j<h; j++;)
	                    { if ( surface_getpixel(surf,i,j) > 200 )
	                        { if ( j < h/2 )
	                            { draw_rectangle(scale*i-pix,scale*j-pix,scale*i+pix,scale*j+pix,0);}
	                          else { draw_rectangle(scale*i-pix,scale*j-pix,scale*i+pix,scale*j+pix,1); }
	                        } 
	                    }
	                }   
	              surface_reset_target();
	              sprite_add_from_surface(spr_text[n],surf_font,0,0,w0,h0,true,false); // add sub-image
	            }
	          surface_free(surf); surface_free(surf_font);
	        }

	// CREATE GAME SPRITES
	    var d = 25;
	    var surf0 = surface_create(d,d); // player sprite
	        surface_set_target(surf0);
	        draw_clear_alpha(c_white,1);
	        var spr_player = sprite_create_from_surface(surf0,0,0,d,d,false,false,d/2,d/2);
	    surface_reset_target(); surface_free(surf0);
    
	    var bw = 30; var bh = 40; 
	    var surf1 = surface_create(bw,bh); // obstacle block
	        surface_set_target(surf1);
	        draw_clear_alpha(c_gray,1);
	        var spr_block = sprite_create_from_surface(surf1,0,0,bw,bh,false,true,bw/2,bh/2);
	    surface_reset_target(); surface_free(surf1);
    
	    var bw = 20; var bh = 40;
	    var surf2 = surface_create(bw,bh); // spike
	        surface_set_target(surf2);
	        draw_clear_alpha(c_gray,1);
	        draw_triangle_colour(1,bh,bw/2,0,bw,bh,c_gray,c_red,c_gray,false);
	        var spr_spike = sprite_create_from_surface(surf2,0,0,bw,bh,true,true,bw/2,bh/2);
	    surface_reset_target(); surface_free(surf2);
    
	    var d = 2; var D = 110; var ofst; // frag size, explosion size, velocity
	    var surf3 = surface_create(D,D); // fragment animation
	        surface_set_target(surf3); 
	        draw_clear_alpha(c_black,0); 
	        var d1 = D/2-d; var d2 = D/2+d;
	        draw_set_color(c_white); draw_rectangle(d1,d1,d2,d2,false);
	        var spr_frag = sprite_create_from_surface(surf3,0,0,D,D,true,false,D/2,D/2); // first sub-image
	        for (i=1; i<10; i++;) // 9 more sub-images
	            { ofst = 5*i;
	              draw_clear_alpha(c_black,0); draw_set_color(c_white); // clear before each re-draw
	              draw_rectangle(d1-ofst,d1,d2-ofst,d2,false); // left horizontal
	              draw_rectangle(d1+ofst,d1,d2+ofst,d2,false); // right horizontal
	              draw_rectangle(d1-ofst,d1-ofst,d2-ofst,d2-ofst,false); // left-up
	              draw_rectangle(d1+ofst,d1-ofst,d2+ofst,d2-ofst,false); // right-up
	              sprite_add_from_surface(spr_frag,surf3,0,0,D,D,true,true);
	            }
	    surface_reset_target(); surface_free(surf3);

	// CREATE DATA MAP
	    var map = ds_map_create(); 
	        ds_map_add(map,"count",0);              ds_map_add(map,"game_over",false);
	        ds_map_add(map,"rot",0);                ds_map_add(map,"ang",0); 
	        ds_map_add(map,"x",W/3+random(W/3));    ds_map_add(map,"y",H/2);
	        ds_map_add(map,"v_speed",0);            ds_map_add(map,"h_speed",5);
	        ds_map_add(map,"can_jump",false);       ds_map_add(map,"hits",0);
	        ds_map_add(map,"rot0",0); 
	        ds_map_add(map,"level",0);
	        ds_map_add(map,"sound_beep",snd_beep);  ds_map_add(map,"sound_thud",snd_thud);
	        ds_map_add(map,"spr_title",spr_text[0]);  
	        ds_map_add(map,"spr_win",spr_text[1]);
	        ds_map_add(map,"spr_player",spr_player);
	        ds_map_add(map,"spr_block",spr_block);  ds_map_add(map,"spr_spike",spr_spike);
	        ds_map_add(map,"spr_frag",spr_frag);    ds_map_add(map,"frag_alpha",1);
	        ds_map_add(map,"frag_x",0);             ds_map_add(map,"frag_y",0); 
	 } // INIT LOOP END

	// GAME STARTS HERE   
	// GET DYNAMIC DATA
	var count = ds_map_find_value(0,"count");   var game_over = ds_map_find_value(0,"game_over");
	var rot = ds_map_find_value(0,"rot");       var ang = ds_map_find_value(0,"ang");
	var x0 = ds_map_find_value(0,"x");          var y0 = ds_map_find_value(0,"y");
	var vs = ds_map_find_value(0,"v_speed");    var hs = ds_map_find_value(0,"h_speed");
	var can_jump = ds_map_find_value(0,"can_jump");
	var rot0 = ds_map_find_value(0,"rot0");
	var level = ds_map_find_value(0,"level");           var hits = ds_map_find_value(0,"hits");
	var beep = ds_map_find_value(0,"sound_beep");       var thud = ds_map_find_value(0,"sound_thud");
	var spr_title = ds_map_find_value(0,"spr_title");   var spr_win = ds_map_find_value(0,"spr_win");
	var spr_player = ds_map_find_value(0,"spr_player");
	var spr_block = ds_map_find_value(0,"spr_block");   var spr_spike = ds_map_find_value(0,"spr_spike");
	var spr_frag = ds_map_find_value(0,"spr_frag");     var frag_alpha = ds_map_find_value(0,"frag_alpha");
	var frag_x = ds_map_find_value(0,"frag_x");         var frag_y = ds_map_find_value(0,"frag_y");

	// Static data
	var W = 800; H = 500; // room size
	var d = 25; // player size

	// CHEESY INTRO and Game-Over Screen 
	if (level == 0) 
	    { var L0 = 400;  
	      if (can_jump) 
	        { can_jump = false;
	          y0 = L0; ang = choose(0,-8.6,8.6); vs = -30;
	        } 
	      rot += ang; vs += 1.4; y0 += vs; x0 += hs;
	      if (y0 > L0) 
	        { y0 = L0;  vs = 0; 
	          ang = 0; rot = 0;
	          can_jump = true;
	        }
	      if ( x0 < 20 || x0 > W-20 )
	        { hs = - hs; ang = -ang;
	          x0 += hs;
	          audio_play_sound(thud,0.5,false);
	        }    
	      draw_set_color(c_gray); draw_rectangle(0,L0+5,W,L0+40,false);
	      draw_set_color(c_white);
      
	      count += 0.1; 
	      if ( !game_over )
	        { for (var i=1; i<11; i++;) // 11 images in sprite
	            { draw_sprite(spr_title,i,80*i-50,100+20*sin(i*pi/4+count)); } // 80 is w0
	          var start_key = vk_space;
	          draw_text_transformed(W/2,L0-200,string_hash_to_newline("Press SPACE to..."),1.5,1.5,0);
	          draw_text_transformed(x0,y0,string_hash_to_newline("JUMP"),1.8,1.8,rot);
	          draw_text_transformed(W/2,L0+25,string_hash_to_newline("Press SPACE to Start Game"),1.5,1.5,0);
	        }
	      else
	        { for (var i=1; i<10; i++;) // 10 images in sprite
	            { draw_sprite(spr_win,i,90*i,100+20*sin(i*pi/4+count)); } 
	          var start_key = ord("R");
	          draw_text_transformed(W/2,L0-200,string_hash_to_newline("Vote for..."),1.5,1.5,0);
	          draw_text_transformed(x0,y0,string_hash_to_newline("CHANCE"),1.8,1.8,rot);
	          draw_text_transformed(W/2,L0+25,string_hash_to_newline("Press R to Replay"),1.5,1.5,0);
	          draw_set_color(c_red);
	          draw_text_transformed(W/2,L0-50,string_hash_to_newline("You Had "+string(hits)+" Misses"),1.5,1.5,0);
	        }
        
	      if ( keyboard_check_pressed(start_key) )
	        { level = 1; // (re) start game
	          hits = 0;
	          x0 = -2*d; hs = 8;
	          draw_set_color(c_white);
	        }
	    }
	else // MAIN GAME LOOP
	    { var L1 = 125; var L2 = 290; var L3 = 465; // level heights
	      var start, stop, theta; // start and stop values and rotation increment
	      var p1, p2, p3; // obstacle locations 
	      var grnd, bw, bh, spr_obs, zone; // ground levels, block sizes, obstacle type

	      switch(level) // Switch stucture chosen over data structure for ease of Level editing
	        { case 1: p1 = 0.5*W; p2 = 5*W; p3 = 7*W; // block locations
	            grnd = L1 ; bw = 30; bh = 40; // ground level, block sizes
	            spr_obs = spr_block; // obstacle type 
	            start = -2*d; stop = W; theta = -10;
	            __background_set( e__BG.Visible, 0, true );
	            draw_text_transformed(W/2,grnd+25,string_hash_to_newline("Press SPACE to Jump Block"),1.5,1.5,0);
	          break;
      
	          case 2: p1 = 0.4*W; p2 = 0.6*W; p3 = 8*W;
	            grnd = L2; bw = 30; bh = 40;
	            spr_obs = spr_block;  
	            start = W+2*d; stop = 0; theta = 10;
	            draw_text_transformed(W/2,grnd+25,string_hash_to_newline("OK, a Little Harder Now."),1.5,1.5,0);
	          break;
          
	          case 3: p1 = 0.3*W; p2 = 0.5*W; p3 = 0.7*W;
	            grnd = L3; bw = 20; bh = 40;
	            spr_obs = spr_spike;  
	            start = -2*d; stop = W; theta = -10;
	            draw_text_transformed(W/2,grnd+25,string_hash_to_newline("Watch for Spikes..!"),1.5,1.5,0);
	          break;
          
	          case 4: p1 = 0.3*W; p2 = 0.5*W; p3 = 0.7*W;
	            grnd = L1; bw = 30; bh = 40;
	            spr_obs = spr_block;
	            start = W+2*d; stop = 0; theta = 10;
	            __background_set( e__BG.Visible, 0, false ); __background_set( e__BG.Visible, 1, true );
	            draw_text_transformed(W/2,grnd+25,string_hash_to_newline("Getting a Bit More Serious."),1.5,1.5,0);
	          break;
      
	          case 5: p1 = 0.35*W; p2 = 0.5*W; p3 = 0.7*W;
	            grnd = L2; bw = 20; bh = 40;
	            spr_obs = spr_spike;
	            start = -2*d; stop = W; theta = -10;
	            draw_text_transformed(W/2,grnd+25,string_hash_to_newline("No, Really..."),1.5,1.5,0);
	          break;
          
	          case 6: p1 = 0.20*W; p2 = 0.45*W; p3 = 0.6*W;
	            grnd = L3; bw = 40; bh = 40;
	            spr_obs = spr_block;
	            start = W+2*d; stop = 0; theta = 10;
	            draw_text_transformed(W/2,grnd+25,string_hash_to_newline("Timing!  Timing!"),1.5,1.5,0);
	          break;
          
	          case 7: p1 = 0.2*W; p2 = 0.45*W; p3 = 0.7*W;
	            grnd = L1; bw = 30; bh = 40;
	            spr_obs = spr_block;
	            start = -2*d; stop = W; theta = -10;
	            __background_set( e__BG.Visible, 1, false ); __background_set( e__BG.Visible, 2, true );
	            draw_text_transformed(W/2,grnd+25,string_hash_to_newline("Three Levels Remaining."),1.5,1.5,0);
	          break;
      
	          case 8: p1 = 0.35*W; p2 = 0.55*W; p3 = 0.7*W;
	            grnd = L2; bw = 20; bh = 40;
	            spr_obs = spr_spike;
	            start = W+2*d; stop = 0; theta = 10;
	            draw_text_transformed(W/2,grnd+25,string_hash_to_newline("Almost Done."),1.5,1.5,0);
	          break;
          
	          case 9: p1 = 0.2*W; p2 = 0.45*W; p3 = 0.6*W;
	            grnd = L3; bw = 40; bh = 40;
	            spr_obs = spr_block;
	            start = -2*d; stop = W; theta = -10;
	            draw_text_transformed(W/2,grnd+25,string_hash_to_newline("The Final Level."),1.5,1.5,0);
	          break;
      
	          case 10: level = 0; game_over = true;  // game end, return to intro
	            can_jump = false;
	            __background_set( e__BG.Visible, 0, false ); 
	            __background_set( e__BG.Visible, 1, false );
	            __background_set( e__BG.Visible, 2, false );
	            x0 = W/2; y0 = H/2;
	            vs = 0; hs = 7;
	            p1 = 0; p2 = 0; p3 = 0;
	            bw = 0; bh = 0;
	            grnd = 10000;  // push off screen to fall though code
	            spr_obs = spr_block;
	            start = -10000; stop = 10000; theta = 0;
	          break;
	        } 
	     zone = d/2 + bw/2; // collision zone
      
	     if (keyboard_check_pressed(vk_space) && can_jump)
	        { can_jump = false;
	          ang = theta;
	          vs = -16;
	          rot0 += 180; 
	        }
   
	     rot += ang; vs += 1.6; y0 += vs; x0 += hs; // update physics
 
	     if ( abs(x0-p1)<zone || abs(x0-p2)<zone || abs(x0-p3)<zone ) // collision check
	        { if (y0 > grnd-bh/2-d/2)
	            { frag_alpha = 1; count = 0; // start fragment animation sprite
	              frag_x = x0; frag_y = y0;
	              audio_play_sound(thud,0.5,0);
	              hits++;
	              x0 = start; y0 = grnd-d/2;  
	              vs = 0; 
	              ang = 0; rot = 0; rot0 = 0;
	              can_jump = true; 
	            }
	        }

	     if (y0 > grnd-d/2) // landing
	        { y0 = grnd-d/2;  vs = 0;
	          ang = 0; rot = rot0;
	          can_jump = true;
	        }
    
	     if ( sign(hs)*x0 > stop ) // level complete
	        { audio_play_sound(beep,0.5,0);
	          level++;
	          hs = -hs; theta = -theta; // change direction and rotation angle
	          y0 = grnd-d/2;
	          rot = 0; rot0 = 0;
	        }
	// RENDER EVERYTHING
	     draw_sprite_ext(spr_player,0,x0,y0,1,1,rot,c_white,1); // player
    
	     var Ly = grnd-bh/2; // blocks
	     draw_sprite(spr_obs,0,p1,Ly); draw_sprite(spr_obs,0,p2,Ly); draw_sprite(spr_obs,0,p3,Ly);

	     draw_text_transformed(80,20,string_hash_to_newline("Missed: "+string(hits)),1.3,1.3,0); // Stats Display
	     draw_text_transformed(W-100,20,string_hash_to_newline("Level: "+string(level)+" of 9"),1.3,1.3,0);
     
	     if (count < 10)  // explosion
	        { draw_sprite_ext(spr_frag,count,frag_x,frag_y,1,1,45,c_white,frag_alpha);
	          draw_sprite_ext(spr_frag,count,frag_x,frag_y,2,1,-45,c_white,frag_alpha);
	          frag_alpha -= 0.05; count++;
	        }
	    } // END MAIN LOOP

	// UPDATE DYNAMIC DATA
	ds_map_replace(0,"count",count);        ds_map_replace(0,"game_over",game_over);
	ds_map_replace(0,"rot",rot);            ds_map_replace(0,"ang",ang); 
	ds_map_replace(0,"x",x0);               ds_map_replace(0,"y",y0);
	ds_map_replace(0,"v_speed",vs);         ds_map_replace(0,"h_speed",hs);
	ds_map_replace(0,"can_jump",can_jump);  ds_map_replace(0,"hits",hits); 
	ds_map_replace(0,"rot0",rot0);
	ds_map_replace(0,"level",level);
	ds_map_replace(0,"frag_x",frag_x);      ds_map_replace(0,"frag_y",frag_y);
	ds_map_replace(0,"frag_alpha",frag_alpha); 

	//draw_text(0,0,string(undefined_variable)); // diagnostic breakpoint





}
