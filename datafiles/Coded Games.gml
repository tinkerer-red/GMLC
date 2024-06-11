#define osg
/*
Unfinished Exploration game made for the OSG Jam
By Robert Cordingly (Coded Games)
Please excuse how unfinished this game is.
*/

var started = ds_exists(0, ds_type_list);

if (!started) {

    ds_list_create(); //For holding the "instances".
    ds_grid_create(2, 30); //For all of the other variables.
    
    randomize();
    
    //Set some constants.
    enum obj {
        player = 0, wall = 1, tree = 2
    }
    
    enum ROOM {
        width = 1280, height = 720
    }
    
    application_surface_enable(false);
    window_set_size(ROOM.width, ROOM.height);
    view_wview[0] = ROOM.width;
    view_hview[0] = ROOM.height;
    view_visible[0] = true;
    view_enabled = true;
    window_set_fullscreen(false);

    //Create objects in room.
    var player = ds_map_create();
    player[? "type"] = obj.player;
    player[? "x"] = ROOM.height/2;
    player[? "y"] = ROOM.width / 2;
    player[? "seed"] = floor(random_range(0, 2000000000));
    player[? "vsp"] = 0;
    ds_list_add(0, player);
    
    var sprites = ds_list_create();

    //Save all data.
    var view_x = 0;
    var view_y = 0;
    var row = 0;
    var column = 0;
    var selected = 0;
    var slots_in_row = 9;
    var hold = 0;
    var select1 = 0;
    var select2 = 0;
    var selectid1 = 0;
    var selectid2 = 0;
    var mousedover = 0;
    var inv;
    for (var i = 0; i < 10; i++) {
        inv[i] = 0
        amount[i] = 0;
    }
    var total_slots = 10;
    var slot_size = 64;
    var inventory_x = ROOM.width / 2 - 64 * 5;
    var inventory_y = ROOM.height - 64;
    var slot_sprite = 0;
    var slot_selected = 0;
    var show_inventory = true;
    var ticks = 0;
    var planet_seed = floor(random_range(0, 2000000000));
    
     //The awful font array. Luckily we will turn this into sprites so it can die in a fire.
    var letter;
    letter[0,0] = 1 letter[0,1] = 1 letter[0,2] = 1 letter[0,3] = 1 letter[0,4] = 0 letter[0,5] = 1 letter[0,6] = 1 letter[0,7] = 1 letter[0,8] = 1 letter[0,9] = 1 letter[0,10] = 0 letter[0,11] = 1 letter[0,12] = 1 letter[0,13] = 0 letter[0,14] = 1
    letter[1,0] = 1 letter[1,1] = 1 letter[1,2] = 1 letter[1,3] = 1 letter[1,4] = 0 letter[1,5] = 1 letter[1,6] = 1 letter[1,7] = 1 letter[1,8] = 1 letter[1,9] = 1 letter[1,10] = 0 letter[1,11] = 1 letter[1,12] = 1 letter[1,13] = 1 letter[1,14] = 1
    letter[2,0] = 1 letter[2,1] = 1 letter[2,2] = 1 letter[2,3] = 1 letter[2,4] = 0 letter[2,5] = 0 letter[2,6] = 1 letter[2,7] = 0 letter[2,8] = 0 letter[2,9] = 1 letter[2,10] = 0 letter[2,11] = 0 letter[2,12] = 1 letter[2,13] = 1 letter[2,14] = 1
    letter[3,0] = 1 letter[3,1] = 1 letter[3,2] = 0 letter[3,3] = 1 letter[3,4] = 0 letter[3,5] = 1 letter[3,6] = 1 letter[3,7] = 0 letter[3,8] = 1 letter[3,9] = 1 letter[3,10] = 0 letter[3,11] = 1 letter[3,12] = 1 letter[3,13] = 1 letter[3,14] = 0
    letter[4,0] = 1 letter[4,1] = 1 letter[4,2] = 1 letter[4,3] = 1 letter[4,4] = 0 letter[4,5] = 0 letter[4,6] = 1 letter[4,7] = 1 letter[4,8] = 1 letter[4,9] = 1 letter[4,10] = 0 letter[4,11] = 0 letter[4,12] = 1 letter[4,13] = 1 letter[4,14] = 1          
    letter[5,0] = 1 letter[5,1] = 1 letter[5,2] = 1 letter[5,3] = 1 letter[5,4] = 0 letter[5,5] = 0 letter[5,6] = 1 letter[5,7] = 1 letter[5,8] = 1 letter[5,9] = 1 letter[5,10] = 0 letter[5,11] = 0 letter[5,12] = 1 letter[5,13] = 0 letter[5,14] = 0
    letter[6,0] = 1 letter[6,1] = 1 letter[6,2] = 1 letter[6,3] = 1 letter[6,4] = 0 letter[6,5] = 0 letter[6,6] = 1 letter[6,7] = 0 letter[6,8] = 0 letter[6,9] = 1 letter[6,10] = 0 letter[6,11] = 1 letter[6,12] = 1 letter[6,13] = 1 letter[6,14] = 1
    letter[7,0] = 1 letter[7,1] = 0 letter[7,2] = 1 letter[7,3] = 1 letter[7,4] = 0 letter[7,5] = 1 letter[7,6] = 1 letter[7,7] = 1 letter[7,8] = 1 letter[7,9] = 1 letter[7,10] = 0 letter[7,11] = 1 letter[7,12] = 1 letter[7,13] = 0 letter[7,14] = 1
    letter[8,0] = 1 letter[8,1] = 1 letter[8,2] = 1 letter[8,3] = 0 letter[8,4] = 1 letter[8,5] = 0 letter[8,6] = 0 letter[8,7] = 1 letter[8,8] = 0 letter[8,9] = 0 letter[8,10] = 1 letter[8,11] = 0 letter[8,12] = 1 letter[8,13] = 1 letter[8,14] = 1                  
    letter[9,0] = 1 letter[9,1] = 1 letter[9,2] = 1 letter[9,3] = 0 letter[9,4] = 1 letter[9,5] = 0 letter[9,6] = 0 letter[9,7] = 1 letter[9,8] = 0 letter[9,9] = 0 letter[9,10] = 1 letter[9,11] = 0 letter[9,12] = 1 letter[9,13] = 1 letter[9,14] = 0
    letter[10,0] = 1 letter[10,1] = 0 letter[10,2] = 1 letter[10,3] = 1 letter[10,4] = 1 letter[10,5] = 0 letter[10,6] = 1 letter[10,7] = 0 letter[10,8] = 0 letter[10,9] = 1 letter[10,10] = 1 letter[10,11] = 1 letter[10,12] = 1 letter[10,13] = 0 letter[10,14] = 1
    letter[11,0] = 1 letter[11,1] = 0 letter[11,2] = 0 letter[11,3] = 1 letter[11,4] = 0 letter[11,5] = 0 letter[11,6] = 1 letter[11,7] = 0 letter[11,8] = 0 letter[11,9] = 1 letter[11,10] = 0 letter[11,11] = 0 letter[11,12] = 1 letter[11,13] = 1 letter[11,14] = 1 
    letter[12,0] = 1 letter[12,1] = 0 letter[12,2] = 1 letter[12,3] = 1 letter[12,4] = 1 letter[12,5] = 1 letter[12,6] = 1 letter[12,7] = 0 letter[12,8] = 1 letter[12,9] = 1 letter[12,10] = 0 letter[12,11] = 1 letter[12,12] = 1 letter[12,13] = 0 letter[12,14] = 1  
    letter[13,0] = 1 letter[13,1] = 1 letter[13,2] = 1 letter[13,3] = 1 letter[13,4] = 0 letter[13,5] = 1 letter[13,6] = 1 letter[13,7] = 0 letter[13,8] = 1 letter[13,9] = 1 letter[13,10] = 0 letter[13,11] = 1 letter[13,12] = 1 letter[13,13] = 0 letter[13,14] = 1 
    letter[14,0] = 1 letter[14,1] = 1 letter[14,2] = 1 letter[14,3] = 1 letter[14,4] = 0 letter[14,5] = 1 letter[14,6] = 1 letter[14,7] = 0 letter[14,8] = 1 letter[14,9] = 1 letter[14,10] = 0 letter[14,11] = 1 letter[14,12] = 1 letter[14,13] = 1 letter[14,14] = 1
    letter[15,0] = 1 letter[15,1] = 1 letter[15,2] = 1 letter[15,3] = 1 letter[15,4] = 0 letter[15,5] = 1 letter[15,6] = 1 letter[15,7] = 1 letter[15,8] = 1 letter[15,9] = 1 letter[15,10] = 0 letter[15,11] = 0 letter[15,12] = 1 letter[15,13] = 0 letter[15,14] = 0
    letter[16,0] = 0 letter[16,1] = 1 letter[16,2] = 0 letter[16,3] = 1 letter[16,4] = 0 letter[16,5] = 1 letter[16,6] = 1 letter[16,7] = 0 letter[16,8] = 1 letter[16,9] = 1 letter[16,10] = 1 letter[16,11] = 0 letter[16,12] = 0 letter[16,13] = 1 letter[16,14] = 1
    letter[17,0] = 1 letter[17,1] = 1 letter[17,2] = 1 letter[17,3] = 1 letter[17,4] = 0 letter[17,5] = 1 letter[17,6] = 1 letter[17,7] = 1 letter[17,8] = 0 letter[17,9] = 1 letter[17,10] = 0 letter[17,11] = 1 letter[17,12] = 1 letter[17,13] = 0 letter[17,14] = 1                     
    letter[18,0] = 1 letter[18,1] = 1 letter[18,2] = 1 letter[18,3] = 1 letter[18,4] = 0 letter[18,5] = 0 letter[18,6] = 1 letter[18,7] = 1 letter[18,8] = 1 letter[18,9] = 0 letter[18,10] = 0 letter[18,11] = 1 letter[18,12] = 1 letter[18,13] = 1 letter[18,14] = 1
    letter[19,0] = 1 letter[19,1] = 1 letter[19,2] = 1 letter[19,3] = 0 letter[19,4] = 1 letter[19,5] = 0 letter[19,6] = 0 letter[19,7] = 1 letter[19,8] = 0 letter[19,9] = 0 letter[19,10] = 1 letter[19,11] = 0 letter[19,12] = 0 letter[19,13] = 1 letter[19,14] = 0
    letter[20,0] = 1 letter[20,1] = 0 letter[20,2] = 1 letter[20,3] = 1 letter[20,4] = 0 letter[20,5] = 1 letter[20,6] = 1 letter[20,7] = 0 letter[20,8] = 1 letter[20,9] = 1 letter[20,10] = 0 letter[20,11] = 1 letter[20,12] = 1 letter[20,13] = 1 letter[20,14] = 1                  
    letter[21,0] = 1 letter[21,1] = 0 letter[21,2] = 1 letter[21,3] = 1 letter[21,4] = 0 letter[21,5] = 1 letter[21,6] = 1 letter[21,7] = 0 letter[21,8] = 1 letter[21,9] = 1 letter[21,10] = 0 letter[21,11] = 1 letter[21,12] = 0 letter[21,13] = 1 letter[21,14] = 0
    letter[22,0] = 1 letter[22,1] = 0 letter[22,2] = 1 letter[22,3] = 1 letter[22,4] = 0 letter[22,5] = 1 letter[22,6] = 1 letter[22,7] = 0 letter[22,8] = 1 letter[22,9] = 1 letter[22,10] = 1 letter[22,11] = 1 letter[22,12] = 1 letter[22,13] = 0 letter[22,14] = 1  
    letter[23,0] = 1 letter[23,1] = 0 letter[23,2] = 1 letter[23,3] = 1 letter[23,4] = 0 letter[23,5] = 1 letter[23,6] = 0 letter[23,7] = 1 letter[23,8] = 0 letter[23,9] = 1 letter[23,10] = 0 letter[23,11] = 1 letter[23,12] = 1 letter[23,13] = 0 letter[23,14] = 1              
    letter[24,0] = 1 letter[24,1] = 0 letter[24,2] = 1 letter[24,3] = 1 letter[24,4] = 0 letter[24,5] = 1 letter[24,6] = 1 letter[24,7] = 0 letter[24,8] = 1 letter[24,9] = 0 letter[24,10] = 1 letter[24,11] = 0 letter[24,12] = 0 letter[24,13] = 1 letter[24,14] = 0
    letter[25,0] = 1 letter[25,1] = 1 letter[25,2] = 1 letter[25,3] = 0 letter[25,4] = 0 letter[25,5] = 1 letter[25,6] = 0 letter[25,7] = 1 letter[25,8] = 0 letter[25,9] = 1 letter[25,10] = 0 letter[25,11] = 0 letter[25,12] = 1 letter[25,13] = 1 letter[25,14] = 1
    letter[26,0] = 0 letter[26,1] = 0 letter[26,2] = 0 letter[26,3] = 1 letter[26,4] = 0 letter[26,5] = 0 letter[26,6] = 0 letter[26,7] = 0 letter[26,8] = 0 letter[26,9] = 1 letter[26,10] = 0 letter[26,11] = 0 letter[26,12] = 0 letter[26,13] = 0 letter[26,14] = 0
    letter[27,0] = 0 letter[27,1] = 1 letter[27,2] = 0 letter[27,3] = 0 letter[27,4] = 1 letter[27,5] = 0 letter[27,6] = 0 letter[27,7] = 1 letter[27,8] = 0 letter[27,9] = 0 letter[27,10] = 1 letter[27,11] = 0 letter[27,12] = 0 letter[27,13] = 1 letter[27,14] = 0
    letter[28,0] = 1 letter[28,1] = 1 letter[28,2] = 1 letter[28,3] = 0 letter[28,4] = 0 letter[28,5] = 1 letter[28,6] = 1 letter[28,7] = 1 letter[28,8] = 0 letter[28,9] = 1 letter[28,10] = 0 letter[28,11] = 0 letter[28,12] = 1 letter[28,13] = 1 letter[28,14] = 1
    letter[29,0] = 1 letter[29,1] = 1 letter[29,2] = 1 letter[29,3] = 0 letter[29,4] = 0 letter[29,5] = 1 letter[29,6] = 1 letter[29,7] = 1 letter[29,8] = 1 letter[29,9] = 0 letter[29,10] = 0 letter[29,11] = 1 letter[29,12] = 1 letter[29,13] = 1 letter[29,14] = 1
    letter[30,0] = 1 letter[30,1] = 0 letter[30,2] = 1 letter[30,3] = 1 letter[30,4] = 0 letter[30,5] = 1 letter[30,6] = 1 letter[30,7] = 1 letter[30,8] = 1 letter[30,9] = 0 letter[30,10] = 0 letter[30,11] = 1 letter[30,12] = 0 letter[30,13] = 0 letter[30,14] = 1
    letter[31,0] = 1 letter[31,1] = 1 letter[31,2] = 1 letter[31,3] = 1 letter[31,4] = 0 letter[31,5] = 0 letter[31,6] = 1 letter[31,7] = 1 letter[31,8] = 1 letter[31,9] = 0 letter[31,10] = 0 letter[31,11] = 1 letter[31,12] = 1 letter[31,13] = 1 letter[31,14] = 1
    letter[32,0] = 1 letter[32,1] = 1 letter[32,2] = 1 letter[32,3] = 1 letter[32,4] = 0 letter[32,5] = 0 letter[32,6] = 1 letter[32,7] = 1 letter[32,8] = 1 letter[32,9] = 0 letter[32,10] = 0 letter[32,11] = 1 letter[32,12] = 1 letter[32,13] = 1 letter[32,14] = 1
    letter[33,0] = 1 letter[33,1] = 1 letter[33,2] = 1 letter[33,3] = 0 letter[33,4] = 0 letter[33,5] = 1 letter[33,6] = 0 letter[33,7] = 0 letter[33,8] = 1 letter[33,9] = 0 letter[33,10] = 1 letter[33,11] = 0 letter[33,12] = 0 letter[33,13] = 1 letter[33,14] = 0
    letter[34,0] = 1 letter[34,1] = 1 letter[34,2] = 1 letter[34,3] = 1 letter[34,4] = 0 letter[34,5] = 1 letter[34,6] = 1 letter[34,7] = 1 letter[34,8] = 1 letter[34,9] = 1 letter[34,10] = 0 letter[34,11] = 1 letter[34,12] = 1 letter[34,13] = 1 letter[34,14] = 1 
    letter[35,0] = 1 letter[35,1] = 1 letter[35,2] = 1 letter[35,3] = 1 letter[35,4] = 0 letter[35,5] = 1 letter[35,6] = 1 letter[35,7] = 1 letter[35,8] = 1 letter[35,9] = 0 letter[35,10] = 0 letter[35,11] = 1 letter[35,12] = 0 letter[35,13] = 0 letter[35,14] = 1
    letter[36,0] = 1 letter[36,1] = 1 letter[36,2] = 1 letter[36,3] = 1 letter[36,4] = 0 letter[36,5] = 1 letter[36,6] = 1 letter[36,7] = 0 letter[36,8] = 1 letter[36,9] = 1 letter[36,10] = 0 letter[36,11] = 1 letter[36,12] = 1 letter[36,13] = 1 letter[36,14] = 1
    letter[37,0] = 0 letter[37,1] = 0 letter[37,2] = 0 letter[37,3] = 0 letter[37,4] = 0 letter[37,5] = 0 letter[37,6] = 0 letter[37,7] = 0 letter[37,8] = 0 letter[37,9] = 0 letter[37,10] = 0 letter[37,11] = 0 letter[37,12] = 0 letter[37,13] = 0 letter[37,14] = 0
    
    //Process all of the letters and throw them into the list
    for (var i = 0; i < array_height_2d(letter); i++) {
        var surf;
        var text_size = 8;
        surf = surface_create(25, 40);
        surface_set_target(surf);
        draw_clear_alpha(c_white, 0);
        draw_set_color(c_black);
        for (var j = 0; j < 3; j++) {
            for (var k = 0; k < 5; k++) {
                if (letter[i, j + (k * 3)] == 1) {
                    draw_rectangle(1 + j * text_size,  k * text_size, 1 + (j * text_size) + text_size, (k * text_size) + text_size, false);
                }
            }
        }
        var spr = sprite_create_from_surface(surf, 0, 0, 25, 40, true, false, 0, 0);
        ds_list_add(sprites, spr);
        surface_reset_target();
        surface_free(surf);
    }
    
    ds_list_add(0, sprites);
    
    //Set some other variables.
    ds_grid_add(0, 0, 0, view_x);
    ds_grid_add(0, 1, 0, view_y);
    ds_grid_add(0, 0, 1, planet_seed);
    ds_grid_add(0, 0, 2, row);
    ds_grid_add(0, 1, 2, column);
    ds_grid_add(0, 0, 3, selected);
    ds_grid_add(0, 0, 4, slots_in_row);
    ds_grid_add(0, 1, 4, hold);
    ds_grid_add(0, 0, 5, select1);
    ds_grid_add(0, 1, 5, select2);
    ds_grid_add(0, 0, 6, selectid1);
    ds_grid_add(0, 1, 6, selectid2);
    ds_grid_add(0, 0, 7, mousedover);
    for (var i = 0; i < 10; i++) {
        ds_grid_add(0, 0, 8 + i, inv[i]);
        ds_grid_add(0, 1, 8 + i, amount[i]);
    }
    ds_grid_add(0, 0, 18, total_slots);
    ds_grid_add(0, 0, 19, slot_size);
    ds_grid_add(0, 0, 20, inventory_x);
    ds_grid_add(0, 1, 20, inventory_y);
    ds_grid_add(0, 0, 21, slot_sprite);
    ds_grid_add(0, 1, 21, slot_selected);
    ds_grid_add(0, 0, 22, show_inventory);
    ds_grid_add(0, 0, 23, ticks);
    
} else { 
    //Load all data.
    var instances = ds_list_size(0);
    var view_x = ds_grid_get(0, 0, 0);
    var view_y = ds_grid_get(0, 1, 0);
    var planet_seed = ds_grid_get(0, 0, 1);
    var row = ds_grid_get(0, 0, 2);
    var column = ds_grid_get(0, 1, 2);
    var selected = ds_grid_get(0, 0, 3);
    var slots_in_row = ds_grid_get(0, 0, 4);
    var hold = ds_grid_get(0, 1, 4);
    var select1 = ds_grid_get(0, 0, 5);
    var select2 = ds_grid_get(0, 1, 5);
    var selectid1 = ds_grid_get(0, 0, 6);
    var selectid2 = ds_grid_get(0, 1, 6);
    var mouseover = ds_grid_get(0, 0, 7);
    var inv, amount;
    for (var i = 0; i < 10; i++) {
       inv[i] = ds_grid_get(0, 0, 8 + i);
       amount[i] = ds_grid_get(0, 1, 8 + i);
    }
    var total_slots = ds_grid_get(0, 0, 18);
    var slot_size = ds_grid_get(0, 0, 19);
    var inventory_x = ds_grid_get(0, 0, 20);
    var inventory_y = ds_grid_get(0, 1, 20);
    var slot_sprite = ds_grid_get(0, 0, 21);
    var slot_selected = ds_grid_get(0, 1, 21);
    var show_inventory = ds_grid_get(0, 0, 22);
    var ticks = ds_grid_get(0, 0, 23);
    random_set_seed(planet_seed);
    
    ticks++;
    
    //Load Font
    var text = "the quick brown fox jumps over the lazy dog: 1234567890"
    var text_x = 128;
    var text_y = 128;
    
    if show_inventory = true { //Inventory Code
    if (mouse_y > inventory_y && mouse_y < inventory_y+ceil(total_slots/slots_in_row)*slot_size) && //Are you mousing in the inventory?
        (mouse_x > inventory_x && mouse_x < inventory_x+(slots_in_row+1)*slot_size) {
        row = ceil((mouse_y-inventory_y)/slot_size)
        column = ceil((mouse_x-inventory_x)/slot_size)
        hover = true
    }
    else {
        hover = false
    }
    
    if hover = true {
        selected = column+((row-1)*(slots_in_row+1))
        if selected > total_slots selected = 0
    }
    else {
        selected = 0
    }
    if selected != 0 {
        if mouse_check_button_pressed(mb_left) {
            select1 = selected 
            selectid1 = inv[select1]
            }
            
        if mouse_check_button_released(mb_left) {
            select2 = selected
            selectid2 = inv[select2]
            if select1 != select2 && select1 != 0 {
                hold = selectid1
                selectid1 = selectid2
                selectid2 = hold
                inv[select1] = selectid1
                inv[select2] = selectid2
                select1 = 0
                select2 = 0
                selectid1 = 0
                selectid2 = 0
                hold = 0
            }
            else {
                item = inv[selected]
                //inv_item_action_left() 
                select1 = 0
                select2 = 0
                selectid1 = 0
                selectid2 = 0
                hold = 0
            }
        }
        if mouse_check_button_released(mb_right) {
            item = inv[selected]
            //inv_item_action_right()
            select1 = 0
            select2 = 0
            selectid1 = 0
            selectid2 = 0
            hold = 0
            }     
    }
    else {
        if mouse_check_button_released(mb_left) {
            //inv_drop_item(inv[select1])
            inv[select1] = 0
            select1 = 0
            select2 = 0
            selectid1 = 0
            selectid2 = 0
            }
        }
    }

    //Find the player map.
    var player = ds_list_find_value(0, 0);
    
    //Randomly generate the amplitudes and angular frequency for the sine functions that create out land.
    random_set_seed(planet_seed);
    var water_level = random_range(ROOM.height / 2, ROOM.height * 1.5) - view_y;
    var grav = random_range(0.5, 2);
    var scale_factor = random_range(-20, 20);
    var py = 0;
    var p1 = 0;
    var p2 = 0;
    var deriv = 0;
    var ground_complexity = random_range(0, 10);
    var on_ground = false;
    
    for (var i = 0; i < ground_complexity; i++) {
        var a, w;
        a[i] = random_range(-20, 20);
        w[i] = random_range(-0.2, 0.2)/10;
        py += a[i] * sin(w[i] * (player[? "x"] + view_x))
    }
    var ground = (py * scale_factor) + ROOM.height/1.5 - 20 - view_y;
    
    //Make sure the player can't go lower than the ground.
    
    var y1 = player[? "y"];
    if (player[? "y"] > ground) {
        player[? "y"] = ground;
        if (player[? "vsp"] > 0) {
            player[? "vsp"] = 0;
        }
        on_ground = true;
    } else {
        player[? "vsp"] += grav;
        player[? "y"] += player[? "vsp"];
    }
    var y2 = player[? "y"];
    
    //Movement Code
    var player_speed = 10;
    if (keyboard_check(vk_left)) {
        if (on_ground) {
            player[? "x"] -= player_speed / ((y1 - y2) + 1);
            player[? "y"] = ground;
        } else {
            player[? "x"] -= player_speed;
        }
    }
    if (keyboard_check(vk_right)) {
        if (on_ground) {
             player[? "x"] += player_speed / ((y1 - y2) + 1);
             player[? "y"] = ground;
        } else {
            player[? "x"] += player_speed;
        }
    }
    
    if (keyboard_check(vk_up) && (on_ground || player[? "y"] > water_level)) {
        player[? "vsp"] -= 20;
        player[? "vsp"] = clamp(player[? "vsp"], -20, 20);
        if (on_ground) {
            player[? "y"] = ground - 5;
        }
    }
    
    if (keyboard_check(vk_escape)) {
        file_delete("Game");
        game_end();
    }
    
    //Adjust camera
    var shift_x = (ROOM.width/2 - player[? "x"]) / 20;
    var shift_y = (ROOM.height/2 - player[? "y"]) / 20;
    player[? "x"] += shift_x;
    player[? "y"] += shift_y;
    view_x -= shift_x;
    view_y -= shift_y;
   
    //Draw the sky color
    var color1 = make_color_rgb(floor(random(255)), floor(random(255)), floor(random(255)));
    var color2 = make_color_rgb(floor(random(255)), floor(random(255)), floor(random(255)));
    draw_rectangle_colour(0, 0, ROOM.width, ROOM.height, color1, color1, color2, color2, false);
    
    //Draw the water color
    var color1 = make_color_rgb(floor(random(255)), floor(random(255)), floor(random(255)));
    var color2 = make_color_rgb(floor(random(255)), floor(random(255)), floor(random(255)));
    draw_rectangle_colour(0, water_level, ROOM.width, (ROOM.height * 3) - view_y, color1, color1, color2, color2, false);
    
    //Draw everything in the list OLD
    /*
    for (var i = 0; i < instances; i++) {
        var temp = ds_list_find_value(0, i);
        switch (temp[? "type"]) {
            case (obj.tree):
                draw_set_color(make_color_rgb(floor(random(255)), floor(random(255)), floor(random(255))));
                draw_set_color(c_dkgray);
                random_set_seed(temp[? "seed"]);
                draw_primitive_begin(pr_trianglestrip);
                draw_vertex(temp[? "x"] - 128 * random(1) + 1 - view_x, temp[? "y"] - view_y);
                draw_vertex(temp[? "x"] + 128 * random(1) + 1 - view_x, temp[? "y"] - view_y);
                draw_vertex(temp[? "x"] - 128 * random(1) + 1 - view_x, 0 - view_y);
                draw_vertex(temp[? "x"] + 128 * random(1) + 1 - view_x, 0 - view_y);
                draw_primitive_end();
                break;
            case (obj.player):
                draw_set_color(c_gray);
                draw_rectangle(temp[? "x"] - 16, temp[? "y"] - 32, temp[? "x"] + 16, temp[? "y"] + 24, false);
                break;
        }
    }*/
    
    //Draw the player
    draw_set_color(c_gray);
    draw_rectangle(player[? "x"] - 16, player[? "y"] - 40, player[? "x"] + 16, player[? "y"] + 16, false);
   
   //show_debug_message(string(player[? "x"]) + " - " + string(player[? "y"]) + " - " + string(ds_list_size(0)) + " - " + string(view_x) + " - " + string(view_y));
    
   //Draw the terrain.
    draw_set_color(make_color_rgb(floor(random(255)), floor(random(255)), floor(random(255))));
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(ROOM.width / 2, ROOM.height * 5 - view_y);
    for (var i = - ROOM.width * 1.5 + view_x; i < ROOM.width * 1.5 + view_x; i += 16) {
        var xx = i - view_x
        var yy = 0; //0
        for (var j = 0; j < ground_complexity; j++) {
        yy += a[j] * sin(w[j] * (i));
        }
        random_set_seed(planet_seed);
        draw_vertex(xx, (yy * scale_factor) + ROOM.height / 1.5 - view_y);
    }
    draw_primitive_end();
    
    //Draw the inventory
    if (show_inventory == true) {
    var ss = 1
    var xx = 0
    var yy = 0
    while (ss <= total_slots) {
        if (xx <= slots_in_row) {
            if selected = ss {
                draw_set_color(c_gray);
                draw_rectangle(xx * slot_size + inventory_x, yy * slot_size + inventory_y, xx * slot_size + inventory_x + 64, yy * slot_size + inventory_y + 64, false);
                draw_set_color(c_black);
                draw_rectangle(xx*slot_size + inventory_x, yy * slot_size + inventory_y, xx * slot_size + inventory_x + 64, yy * slot_size + inventory_y + 64, true);
                }
            else {
                draw_set_color(c_white);
                draw_rectangle(xx * slot_size + inventory_x, yy * slot_size + inventory_y, xx * slot_size + inventory_x + 64, yy * slot_size + inventory_y + 64, false);
                draw_set_color(c_black);
                draw_rectangle(xx * slot_size + inventory_x, yy * slot_size + inventory_y, xx * slot_size + inventory_x + 64, yy * slot_size + inventory_y + 64, true);
                }
            xx+=1;
            ss+=1;
        }
        else {
            yy+=1;
            xx=0;
        }
    } 
    var ss = 1
    var xx = 0
    var yy = 0
    while (ss <= total_slots) {
        if (xx <= slots_in_row) {
            if select1 != ss {
                //draw_sprite(sprite[inv[ss]],0,xx*slot_size+inventory_x,yy*slot_size+inventory_y)
            }
            xx+=1;
            ss+=1;
        }
        else {
            yy+=1;
            xx=0;
        }
    } 
    var ss = 1
    var xx = 0
    var yy = 0
    while (ss <= total_slots) {
        if (xx <= slots_in_row) {
            if select1 = ss {
                //draw_sprite(sprite[inv[ss]],0,mouse_x-slot_size/2 - view_xview ,mouse_y-slot_size/2 - view_yview)
            }
            xx+=1;
            ss+=1;
        }
        else {
            yy+=1;
            xx=0;
            }
        } 
    }
    
    var text, text_x, text_y, text_size;
    text[0] = "planet: " + string(planet_seed);
    text_x[0] = 5;
    text_y[0] = 16;
    text_size[0] = 1;
    
    
    text[1] = "temperature: " + string(floor(random_range(0, 500))) + "f";
    text_x[1] = 16;
    text_y[1] = 68;
    text_size[1] = 0.5;


    text[2] = "gravity: " + string(grav) + "mps2";
    text_x[2] = 16;
    text_y[2] = 68 + 32;
    text_size[2] = 0.5;
    
    text[3] = "arrow keys: move";
    text_x[3] = 16;
    text_y[3] = 68 + 64 + 32;
    text_size[3] = 0.5;
    
    text[4] = "r: generate new planet";
    text_x[4] = 16;
    text_y[4] = 68 + 64 + 64;
    text_size[4] = 0.5;
    
     //Draw title
    for (var h = 0; h < array_length_1d(text); h++) {
        for (var i = 1; i < string_length(text[h]) + 1; i++) {
            var c = string_char_at(text[h], i);
            switch (c) {
                    case "a":
                        l = 0;
                        break;
                    case "b":
                        l = 1;
                        break;
                    case "c":
                        l = 2;
                        break;
                    case "d":
                        l = 3;
                        break;
                    case "e":
                        l = 4;
                        break;
                    case "f":
                        l = 5;
                        break;
                    case "g":
                        l = 6;
                        break;
                    case "h":
                        l = 7;
                        break;
                    case "i":
                        l = 8;
                        break;
                    case "j":
                        l = 9;
                        break;
                    case "k":
                        l = 10;
                        break;
                    case "l":
                        l = 11;
                        break;
                    case "m":
                        l = 12;
                        break;
                    case "n":
                        l = 13;
                        break;
                    case "o":
                        l = 14;
                        break;
                    case "p":
                        l = 15;
                        break;
                    case "q":
                        l = 16;
                        break;
                    case "r":
                        l = 17;
                        break;
                    case "s":
                        l = 18;
                        break;
                    case "t":
                        l = 19;
                        break;
                    case "u":
                        l = 20;
                        break;
                    case "v":
                        l = 21;
                        break;
                    case "w":
                        l = 22;
                        break;
                    case "x":
                        l = 23;
                        break;
                    case "y":
                        l = 24;
                        break;
                    case "z":
                        l = 25;
                        break;
                    case ":":
                        l = 26;
                        break;
                    case "1":
                        l = 27;
                        break;
                    case "2":
                        l = 28;
                        break;
                    case "3":
                        l = 29;
                        break;
                    case "4":
                        l = 30;
                        break;
                    case "5":
                        l = 31;
                        break;
                    case "6":
                        l = 32;
                        break;
                    case "7":
                        l = 33;
                        break;
                    case "8":
                        l = 34;
                        break;
                    case "9":
                        l = 35;
                        break;
                    case "0":
                        l = 36;
                        break;
                    case " ":
                        l = 37;
                        break;
            }
            var letters = ds_list_find_value(0, 1);
            draw_sprite_ext(ds_list_find_value(letters, l), 0, text_x[h] + i * (32 * text_size[h]), text_y[h], text_size[h], text_size[h], 0, draw_get_colour(), 1);
        }
    }
    
    //Save Data
    ds_grid_set(0, 0, 0, view_x);
    ds_grid_set(0, 1, 0, view_y);
    ds_grid_set(0, 0, 1, planet_seed);
    ds_grid_set(0, 0, 2, row);
    ds_grid_set(0, 1, 2, column);
    ds_grid_set(0, 0, 3, selected);
    ds_grid_set(0, 0, 4, slots_in_row);
    ds_grid_set(0, 1, 4, hold);
    ds_grid_set(0, 0, 5, select1);
    ds_grid_set(0, 1, 5, select2);
    ds_grid_set(0, 0, 6, selectid1);
    ds_grid_set(0, 1, 6, selectid2);
    ds_grid_set(0, 0, 7, mouseover);
    for (var i = 0; i < 10; i++) {
        ds_grid_set(0, 0, 8 + i, inv[i]);
        ds_grid_set(0, 1, 8 + i, amount[i]);
    }
    ds_grid_set(0, 0, 18, total_slots);
    ds_grid_set(0, 0, 19, slot_size);
    ds_grid_set(0, 0, 20, inventory_x);
    ds_grid_set(0, 1, 20, inventory_y);
    ds_grid_set(0, 0, 21, slot_sprite);
    ds_grid_set(0, 1, 21, slot_selected);
    ds_grid_set(0, 0, 22, show_inventory);
    ds_grid_set(0, 0, 23, ticks);
    
    //Debug create new planet
    if (keyboard_check(ord("R"))) {
        ds_list_destroy(0);
        ds_grid_destroy(0);
    }
    
}
