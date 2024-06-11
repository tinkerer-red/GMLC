#define osg
var _ = 0; // This is the hardcoded index to our main ds_map

///CONSTANTS/ENUMS///

// Sizes of buffer data types (because typing buffer_sizeof(buffer_blabla) all the time is ugly and cumbersome
// I probably won't/don't use all of them, but whatever. Or actually, not whatever:
// TODO: Delete the unused ones!!!!! (when finished)
var INT8 = buffer_sizeof(buffer_u8),
var INT16 = buffer_sizeof(buffer_u16),
var INT32 = buffer_sizeof(buffer_u32),
var FLOAT = buffer_sizeof(buffer_f16),
var DOUBLE = buffer_sizeof(buffer_f32),
var BOOL = buffer_sizeof(buffer_bool)

var TILE_SIZE = 16;

enum COLL // These are used for storing collision info as flags
    {
    left = 1,
    right = 2,
    above = 4,
    below = 8
    }
    
if (!ds_exists(_, ds_type_map))
    {
    ///INITIALIZE///
    _ = ds_map_create();
    
    ///GAME SETTINGS
    room_speed = 60;
    show_debug_overlay(true);
    window_set_caption("Nallebeorn's *EPIC* OSG jam entry");
    room_width = 512;
    room_height = 256;
    view_wview[0] = room_width;
    view_hview[0] = room_height;
    view_wport[0] = room_width * 2;
    view_hport[0] = room_height * 2;
    window_set_size(view_wport[0], view_hport[0]);
    surface_resize(application_surface, view_wport[0], view_hport[0]);
    
    ///TEXTURE PAGES
    var sprites = ds_map_create();
    var atlasBuf, atlasJson, tag, sprite;
    
    //16x16 atlas///
    // This is the data exported by Aseprite to accompany the sprite sheet/texture page/atlas. It contains information about all the different animations.
    atlasJson = json_decode(@'{"frames":[{"filename":"16x16 0.ase","frame":{"x":0,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":140},{"filename":"16x16 1.ase","frame":{"x":16,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":250},{"filename":"16x16 2.ase","frame":{"x":32,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":140},{"filename":"16x16 3.ase","frame":{"x":48,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":250},{"filename":"16x16 4.ase","frame":{"x":64,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":100},{"filename":"16x16 5.ase","frame":{"x":80,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":130},{"filename":"16x16 6.ase","frame":{"x":96,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":130},{"filename":"16x16 7.ase","frame":{"x":112,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":115},{"filename":"16x16 8.ase","frame":{"x":128,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":100},{"filename":"16x16 9.ase","frame":{"x":144,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":250},{"filename":"16x16 10.ase","frame":{"x":160,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":250},{"filename":"16x16 11.ase","frame":{"x":176,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":250},{"filename":"16x16 12.ase","frame":{"x":192,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":250},{"filename":"16x16 13.ase","frame":{"x":208,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":100},{"filename":"16x16 14.ase","frame":{"x":224,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":150},{"filename":"16x16 15.ase","frame":{"x":240,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":150},{"filename":"16x16 16.ase","frame":{"x":256,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":100},{"filename":"16x16 17.ase","frame":{"x":272,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":200},{"filename":"16x16 18.ase","frame":{"x":288,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":100},{"filename":"16x16 19.ase","frame":{"x":304,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":200},{"filename":"16x16 20.ase","frame":{"x":320,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":100},{"filename":"16x16 21.ase","frame":{"x":336,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":250},{"filename":"16x16 22.ase","frame":{"x":352,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":250},{"filename":"16x16 23.ase","frame":{"x":368,"y":0,"w":16,"h":16},"rotated":false,"trimmed":false,"spriteSourceSize":{"x":0,"y":0,"w":16,"h":16},"sourceSize":{"w":16,"h":16},"duration":250}],"meta":{"app":"http://www.aseprite.org/","version":"1.1.8-dev","image":"16x16.png","format":"RGBA8888","size":{"w":384,"h":16},"scale":"1","frameTags":[{"name":"Blob","from":0,"to":3,"direction":"forward"},{"name":"Decoration","from":4,"to":7,"direction":"forward"},{"name":"Wall","from":8,"to":8,"direction":"forward"},{"name":"Megaboy_idle","from":9,"to":16,"direction":"forward"},{"name":"Megaboy_run","from":17,"to":20,"direction":"forward"},{"name":"Megaboy_jump","from":21,"to":21,"direction":"forward"},{"name":"Megaboy_wall","from":22,"to":23,"direction":"forward"}]}}');
    
    var atlasFrames = atlasJson[?"frames"];
    var atlasTags = ds_map_find_value(atlasJson[?"meta"], "frameTags");
    for (var i = 0; i < ds_list_size(atlasTags); ++i) // Let's loop through all the aseprite tags (each one is one virtual sprite/animation)
        {
        tag = atlasTags[| i];
        spriteBuffer = buffer_create(buffer_sizeof(buffer_u16)*3*(tag[?"to"] - tag[?"from"] + 1), buffer_fixed, 2);
        buffer_seek(spriteBuffer, buffer_seek_start, 0);
        for (var frame = tag[?"from"]; frame <= tag[?"to"]; ++frame)
            {
            // For each frame in the sprite, we wanna store the x and y position of it on the atlas, as well as the duration of that frame
            buffer_write(spriteBuffer, buffer_u16, ds_map_find_value(ds_map_find_value(atlasFrames[| frame], "frame"), "x")); //frame.x in the <frame>th frame. Um, ok, that didn't actually get any less confusing.
            buffer_write(spriteBuffer, buffer_u16, ds_map_find_value(ds_map_find_value(atlasFrames[| frame], "frame"), "y"));
            buffer_write(spriteBuffer, buffer_u16, (ds_map_find_value(atlasFrames[| frame], "duration") / 1000) * room_speed); // Convert the duration from milliseconds to gamemaker steps
            }
        sprites[? tag[?"name"] ] = spriteBuffer;
        }
        
    // This is just a base64 encoding of a big ass sprite sheet exported by Aseprite. It will act like a virtual texture page (or atlas), as it contains multiple sprites/animations (all of the 16x16 ones, actually)
    atlasBuf = buffer_base64_decode("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");

    // We just save it to a file and then load it as a GM sprite.
    // Then, with the help of the data from the JSON, we'll draw_sprite_part() the different animations from the big atlas.
    // This means we don't need an entire native GM texture page for every sprite/animation.
    buffer_save(atlasBuf, "temp/atlas.png");
    buffer_delete(atlasBuf);
    _[?"sprites_16"] = sprite_add("temp/atlas.png", 1, false, false, 0, 0);
    _[?"sprites_16_data"] = sprites;
    file_delete("temp/atlas.png");
    
    // Then we do the same with some more images...
    ///BOXY BOLD+ FONT///
    atlasBuf = buffer_base64_decode("iVBORw0KGgoAAAANSUhEUgAAA7YAAAAJCAYAAAAGjrClAAAFi0lEQVR4nO1b0XLcMAi0O/3/X3YfOm44DsQuQrLuqp3JNMmtQQIEAjfnkcOlfj6TcixZntyI1/qcldUDxDaV9hshbwSiNTI+ydjY42+ezbO4Xlwx8VcVq70xIJ8ZkTtm8bLn6BPiCuFn14fmZeR3jN4eXo+NR+nNyMvq9fyRlefxUHktbk/MI/JWx8g7yagaYsmqzC8tudna+i1xNaLOVOMT7tkRRtmvsu/ptvNv9oF/mq+/us+zy7eXlqXkXofY1P2ZhNQvP79/f12XucZIVhJv+3GJjX1qeXKJoLxwjYjMakRrZHzC2DiSx/KMOJ2idzZPcqO4AnnI+UAbOOgMWXu1dKM8j/sEz9v30+uLzofmIkDOG3ouybxsPqd/NysfZM7uKL2RPMYfHg/1R1Jeid80tyLmEXlHfS3vHRaaeUj6zuClBnYNW1IXd8ZvL4Li/OLt1+O7IHNpU2+w32jwI2WWN6LF9ah6fVbuse4clXpH+APNz8w5yvY9KM/rj1ykG1sAkGFkkOrvrc3fzvAMI52leLfw0+M3eOUN5q23sRfkIHk2NvcKrhFuLAwuOoFpwvBJCt7QI8vr0d/DY9eH2q/KziDo5HcjOuviDLkJUF9kPaA8qb+ShwDIHbS8St434LZt5LfIBxKV8cKc3Yr4QxrB0WBsXYFMXSDW17ysAT7rvWinmy32pUDUPKL5HvVBpvFB/IaeI6BZvkCdKO9NN3I/bj3vPRtxewdEyBpR3sgBbysXjRrs6ZqUGewxyAz2qvIz2h95GNnYQobWn6HTqci5+l/NlYaTn3mGfKKgIwdJB1+yaW3K7JzAwA1NNcBCeP6l4g1epsD2FH4WPRcAjcqmx4iBZhMaqTyO44oSoHU5RaeFEVge6dvuQFB6u4dxrN5eMVm9s/dRPRwaJY+J+9WGGFY91/Bqeovj8SJdGTCDuAAvNfX+3pPJ1HNDzxt55KAVwYjGBxmaVA6SRtwNKvOf1UhFXFTmbDD2QBvu1fLjcWD5T6JyyC9lTrjDvuU/7ZtfWcXneZZvwPve0ukVLYuDNKrBdOAR6Ebc42heZyP6YsdKHz9l22Avl+R0yKF5kt/6WHxVyKPWpy+BPTwjUZoP3LICmfTABN0z42cEmQJxJBo7S69YoytP8ZqbYvzcCzT2tF7wmUt8ubKqYoBBMvc2/Xscvl0AfV7+ofJStK5eW1s1PZJTmQ8QJHPBG+ReGf+iNo4awicalAxae0bjoNL/iL4MT3IbvlnnctvA7IGiPkOzYpvNfxGY/IfEs26S0VxZgWyuv38e+je2aGOGvrENGt/z56PXBhWZ2slph9c0I4jkWHpbHOm4ysJahaS88PJciWjq+fQbl9n6RyRueXYRXiue0ZgCztBLTlBce8qRf7vhIlOoe3MHIw/FU5fZ2fkA+Uzz0OFPFdi3TaisSjD5AG24UFt7Yg5/AOAugH1r5nBaups6TWFKxxNNV3UDUvWmyeJVNQ0T8RmTAwLMG2/0c8Iv0PkOnv+ZyBe94Ufz3y2rKg6zd9Soj6t+Y5sdSmVXoK1iyWlZTvJn8m4u4tWWTM9ullzUNprHFODs+nojMBMHjO28Z56IP1T/N+mtjqvKuEfPmsVFdVr8FfNaBa/3XK5+fhEeWhdmxAtrkyq9rTVU+s3jMrVc8lfeR4Vuzy7W/nvqek+urIy/0XotLpsDe+p5aGdnyJq1C6J3xHlbhTfi3olysvJm5T9Wdzb/Vd0Twzo48m9sM8mVmmpOlIfuJauvJZ+5dPXoWUHexmeCGRYxl3N2DbNRna+ya1gNK9ilAmi8rr7XVdeo1xXFcmWe+WRYdqrKAyvmk/8SI/7M4YPgbZ5t/FYGm/9Wxeh8q+0S2ulTDbmxsbGxsbGxsbHxbWD+x97GxobAHzb4FuauGIAmAAAAAElFTkSuQmCC");
    buffer_save(atlasBuf, "temp/font.png");
    buffer_delete(atlasBuf);
    var fontSprite = sprite_add("temp/font.png", 95, false, false, 0, 0);
    _[?"font_boxyBold"] = font_add_sprite(fontSprite, ord(" "), false, 2);
    file_delete("temp/font.png");
    
    
    ///DISPLAY LIST
    //This will be a list of all the (virtual) sprites we should draw. They basically act like virtual Objects.
    _[?"displayList"] = ds_list_create();
    /*The display list follows this format:
    [
        {
        "atlas": E.g. "sprites_16", the GM sprite (acting a virtual texture page) where the image is located. Note it's the map key, not the actual index.
        "sprite": The name of the sprite/animation to draw, to find the correct data. The same as the tag in Aseprite.
        "x": X-position in the room to draw the image at
        "y": Y-position -||-
        "timer": Used for animation, it decreases every step until it reaches 0 and we go to the next frame
        "frame": Current frame (0-indexed). To change it, it should be set to <desired frame> - 1 AND TIMER SHOULD BE SET TO 0.
        "width": Width, typically the standard size of the atlas's sprites.
        "height": Height, -||-
        "xorigin": Self-explanatory, I hope.
        "yorigin": -||-
        "xscale": -||-
        "yscale": -||-
        },
        
        {
        ...
        },
       
        ...
    ]
    */
    
    // NOTE (to future self or whoever wants to use this as an "engine"):
    // When adding entries to the display list, set timer to 0 and frame to -1 (or <desired frame> - 1 )
    // and everything will be OK. If not, everything will be bad, and I don't want that, do I?
    // NOTE 2:
    // When creating new objects, it's usually easier to copy _[?"defaultObjectXX"] and edit it (where xx is the atlas' tile size)
    // unless almost all parameters are to be customized. Especially if I want to add new parameters to objects.
    _[?"defaultObject16"] = json_decode(@'{"x": 0, "y": 0, "width": 16, "height": 16, "atlas": "sprites_16", "timer": 0, "frame": -1, "xorigin": 0, "yorigin": 0, "xscale": 1, "yscale": 1}');
    
    
    ///POPULATE DISPLAY LIST
    var displayList = _[?"displayList"];
    var obj;
    
    // Initialize PLAYER
    obj = ds_map_create();
    ds_map_copy(obj, _[?"defaultObject16"]);
    obj[?"x"] = room_width*.5;
    obj[?"y"] = TILE_SIZE * 5;
    obj[?"sprite"] = "Blob";
    obj[?"xorigin"] = 8;
    obj[?"collisions"] = 0000; // This contains flags for where there have been a collisions: left, right, above, below
    obj[?"hspeed"] = 0;
    obj[?"vspeed"] = 0;
    _[?"player"] = obj;
    ds_list_add(displayList, obj);
        
    /// MAP ///
    var tileW = room_width/TILE_SIZE;
    var tileH = room_height/TILE_SIZE;
    var tileMap = ds_grid_create(tileW, tileH);

    var map =
@"################################
##########....8.8......8...#####
##########...#####....###.######
##########...#####....###.######
##########...#####....###.######
##########...#####....###.######
##########...###..........######
#.....####.@.##.8........8######
#.....########..##....##########
#...............##....##########
#..........8888.##....##########
##.........#######....##########
##.........#######....##########
##.........#######....##########
##.........#######.8.8##########
################################";
    
    var mapFile = file_text_open_from_string(map);
    var line;
    var ypos = 0;
    while (!file_text_eof(mapFile))
        {
        line = file_text_readln(mapFile);
        for (var c = 1; c <= string_length(line); c++)
            {
            switch (string_char_at(line, c))
                {
                case "#": // Wall
                    tileMap[# c-1, ypos] = true;
                    obj = ds_map_create();
                    ds_map_copy(obj, _[?"defaultObject16"]);
                    obj[?"x"] = (c-1) * TILE_SIZE;
                    obj[?"y"] = ypos * TILE_SIZE;
                    obj[?"sprite"] = "Wall";
                    ds_list_add(displayList, obj);
                    break;
                case "8": // Weird, decorative jelly
                    obj = ds_map_create();
                    ds_map_copy(obj, _[?"defaultObject16"]);
                    obj[?"x"] = (c-1) * TILE_SIZE;
                    obj[?"y"] = ypos * TILE_SIZE;
                    obj[?"sprite"] = "Decoration";
                    obj[?"frame"] = irandom(2) + 1;
                    ds_list_add(displayList, obj);
                    break;
                case "@": // Player
                    ds_map_replace(_[?"player"], "x", (c-1) * TILE_SIZE);
                    ds_map_replace(_[?"player"], "y", ypos * TILE_SIZE);
                    break;
                }
            }
        ypos++;
        }
    
    _[?"tileMap"] = tileMap;
    }
else /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    {
    ///MAIN LOOP///
    texture_set_interpolation(false); // For some reason, I have to do this every step, or it gets reset when minimizing the window (at least for text drawing...)
    
    //Store some commonly used (or used in uglily nested contexts) map keys in local variables for convenience (read: lazyness) and performance. But mostly lazyness.
    var player = _[?"player"];
    var displayList = _[?"displayList"];
    var tileMap = _[?"tileMap"];
    
    //CONSTANTS
    var PLAYER_MAXHSPEED = 3;
    var PLAYER_ACC = 0.075;
    var PLAYER_DEACC = 0.15;
    var PLAYER_JUMPSPEED = -4.75;
    var PLAYER_GRAVITY = 0.25;
    var PLAYER_MAXVSPEED = 7;
    var PLAYER_WALLJUMPSPEED = PLAYER_MAXHSPEED * .8;
    
    // Player movement
    var playerDir = (keyboard_check(vk_right) - keyboard_check(vk_left));
    if (playerDir == 0)
        {
        player[?"hspeed"] = median(player[?"hspeed"] - sign(player[?"hspeed"]) * PLAYER_DEACC, 0, player[?"hspeed"]);
        player[?"sprite"] = "Megaboy_idle";
        }
    else
        {
        player[?"hspeed"] = clamp(player[?"hspeed"] + PLAYER_ACC * playerDir, -PLAYER_MAXHSPEED, PLAYER_MAXHSPEED);
        if (playerDir != sign(player[?"hspeed"])) // We're trying to turn
            {
            player[?"hspeed"] -= sign(player[?"hspeed"]) * PLAYER_DEACC;
            }
        player[?"sprite"] = "Megaboy_run";
        player[?"xscale"] = playerDir;
        }
    player[?"x"] += player[?"hspeed"];
    
    if (player[?"collision"] & COLL.below or player[?"collision"] & COLL.left or player[?"collision"] & COLL.right)
        {    
        if (keyboard_check_pressed(vk_up))
            {
            player[?"vspeed"] = PLAYER_JUMPSPEED;
            if (player[?"collision"] & COLL.left)
                player[?"hspeed"] = PLAYER_WALLJUMPSPEED;
            else if (player[?"collision"] & COLL.right)
                player[?"hspeed"] = -PLAYER_WALLJUMPSPEED;
            }
        }
    if not (player[?"collision"] & COLL.below)
        {
        if (keyboard_check_released(vk_up)) // Variable jumping – this stops the jumping action
            player[?"vspeed"] *= 0.5;
        if (player[?"collision"] & COLL.left or player[?"collision"] & COLL.right)
            PLAYER_GRAVITY *= 0.3;
        player[?"vspeed"] = min(player[?"vspeed"] + PLAYER_GRAVITY, PLAYER_MAXVSPEED);
        if (player[?"collision"] & COLL.left)
            {
            player[?"sprite"] = "Megaboy_wall";
            player[?"xscale"] = 1;
            }
        else if (player[?"collision"] & COLL.right)
            {
            player[?"sprite"] = "Megaboy_wall";
            player[?"xscale"] = -1;
            }
        else
            player[?"sprite"] = "Megaboy_jump";
        }
    player[?"y"] += player[?"vspeed"];
    
    show_debug_message(player[?"hspeed"]);
    
    var playerLeft = round(player[?"x"]) - 8 + 2;
    var playerRight = playerLeft + 16 - 4;
    var playerTop = player[?"y"];
    var playerBottom = playerTop + 16;
    
    // Collisions: Player against terrain
    
    player[?"collision"] = 0;
    
    // Below
    if (tileMap[# (playerRight - 1) / TILE_SIZE, playerTop / TILE_SIZE + 1] == 1 or tileMap[# (playerLeft +  1) / TILE_SIZE, playerTop / TILE_SIZE + 1] == 1) // Below
        {
        player[?"y"] &= $ffFFf0;
        player[?"collision"] |= COLL.below;
        player[?"vspeed"] = 0;
        }

    // Above
    if (tileMap[# (playerRight - 1) / TILE_SIZE, playerTop / TILE_SIZE] == 1 or tileMap[# (playerLeft +  1) / TILE_SIZE, playerTop / TILE_SIZE ] == 1) // Above
        {
        player[?"y"] = (player[?"y"] & $ffFFf0) + TILE_SIZE;
        player[?"collision"] |= COLL.above;
        player[?"vspeed"] = 0;
        }
    
    playerBottom = player[?"y"] + 16; // Have to recalculate this since it might have changed because of the floor collision before
        
    if (tileMap[# (playerRight+1) / TILE_SIZE, (playerBottom - 2) / TILE_SIZE] == 1) // To the right
        {
        player[?"x"] = (player[?"x"] & $ffFFf0) + 9; // No idea why this one needs other magic numbers than the other one. The left-side-collision is the one that makes sense to me, this one just doesn't wanna collaborate :(
        player[?"collision"] |= COLL.right;
        if (player[?"hspeed"] > 0)
            player[?"hspeed"] = 0;
        }
    
    if (tileMap[# (playerLeft-1) / TILE_SIZE, (playerBottom - 2) / TILE_SIZE] == 1) // To the left
        {
        player[?"x"] = (player[?"x"] & $ffFFf0) + 6;
        player[?"collision"] |= COLL.left;
        if (player[?"hspeed"] < 0)
            player[?"hspeed"] = 0;
        }
        
    ///DRAW///
    
    ///LOOP THROUGH DISPLAY LIST
    var sprite, spriteData, duration;
    for (var i = 0; i < ds_list_size(displayList); ++i)
        {
        sprite = displayList[| i];
        spriteData = ds_map_find_value(_[? sprite[?"atlas"] + "_data"], sprite[?"sprite"]);
        if (sprite[?"timer"] <= 0)
            {
            sprite[?"frame"] += 1;
            sprite[?"timer"] = buffer_peek(spriteData, sprite[?"frame"] * INT16*3 + INT16*2, buffer_u16); // Set the timer to the desired length (converting it from milliseconds to steps)
            }
        else
            {
            sprite[?"timer"]--;
            }
        // Wrap around if the frame is too high. This is done every step (rather than only when changing frames)
        // to make it possible to cleanly change sprite without getting issues with frames because of different frame counts
        sprite[?"frame"] = sprite[?"frame"] mod ( (buffer_get_size(spriteData) / (INT16*3))  );
        
        draw_sprite_part_ext(_[? sprite[?"atlas"] ], 0,
            buffer_peek(spriteData, sprite[?"frame"] * INT16*3, buffer_u16),
            buffer_peek(spriteData, sprite[?"frame"] * INT16*3 + INT16, buffer_u16),
            sprite[?"width"], sprite[?"height"], sprite[?"x"] - sprite[?"xorigin"]*sprite[?"xscale"], sprite[?"y"] - sprite[?"yorigin"]*sprite[?"yscale"],
            sprite[?"xscale"], sprite[?"yscale"], c_white, 1);
        }
        
    draw_set_font(_[?"font_boxyBold"]);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    //draw_text_transformed(floor(room_width*.5), 10, "Hello, World!", 2, 2, 0);
    }
