#define osg
////
/*
Input using only steady known data

City layers:  10, 20, 30
Enemy layers: 100
Target layer: 1

One-time init needed for graphics

*/


////  Initialization  ////

  // values and consts
var _msec = get_timer() * 0.001;

random_set_seed(current_day)
background_colour = make_colour_hsv(irandom(255) + 255 * _msec * 0.000005 , irandom(150)+80, irandom(63)+160);
texture_set_interpolation(false)

var build_layer_count = 3
var mouse_affect_x = 0.1
var mouse_affect_y = 0.2
var max_time = 30 * 60 * 1000
var max_shots = 100
var enemy_depth = 100
var target_depth = 1
var ui_depth = 0

// short one-time init
if application_surface_is_enabled() {
  application_surface_enable(false)
 
  // graphics
  window_set_cursor(cr_none)
  room_speed = 60
  var _img = [];
  _img[0] =
    "................" +
    "########........" +
    "#############..." +
    ".##############." +
    ".###############" +
    ".####....#######" +
    ".#####...#####.#" +
    "..####..#.###..#" +
    "..####..#####.##" +
    "..#####.#####.##" +
    "..##############" +
    "...############." +
    "....###########." +
    ".......###...##." +
    "........###.###." +
    "................" ;
  _img[1] =
    "......####......" +
    "......####......" +
    ".......##......." +
    ".......##......." +
    ".......##......." +
    "................" +
    "##............##" +
    "#####......#####" +
    "#####......#####" +
    "##............##" +
    "................" +
    ".......##......." +
    ".......##......." +
    ".......##......." +
    "......####......" +
    "......####......" ;
  _img[2] =   
    "################" +
    "################" +
    "################" +
    "################" +
    "################" +
    "################" +
    "################" +
    "################" +
    "################" +
    "################" +
    "################" +
    "################" +
    "################" +
    "################" +
    "################" +
    "################" ;
    
  var _img_count = array_length_1d(_img)
        
  var _surf = surface_create(16*_img_count, 16) 
  surface_set_target(_surf)
    draw_clear_alpha(c_white, 0)
    draw_set_colour(c_white)
    for (var i=0; i<_img_count; i++) {
      var _x = i*16
      var _p = 0
      for (var _y=0; _y<16; _y++) {
		  for (var xx=0; xx<16; xx++) {
			_p++
			if (string_char_at(_img[i], _p) == "#") {
			  draw_point(_x+xx, _y)
			}
		  }
		}
    } 
  surface_reset_target()
 
  if not background_exists(background_index[0]) {
    background_index[0] = background_create_from_surface(_surf, 0, 0, 16*_img_count, 16, false, false)
  }   
  if not background_exists(background_index[1]) {
    background_index[1] = background_create_colour(32, 32, c_white)  // img_build
  }   
 
  surface_free(_surf)

  // target
  var target = tile_add(background_index[0], 16, 0, 16, 16, 0, 0, target_depth)
//  tile_set_blend(target, c_red)
  tile_set_scale(target, 2, 2)
 
 
} 


enum _bl {    // build_layer properties
  count,
  color,
  scale,
  width,
  depth
}
enum _i {     // img properties
  index,  // background index
  width,  // within background
  height,
  x, y
}

var img_enemy = 0;
img_enemy[_i.index]  = background_index[0]
img_enemy[_i.x] = 0
img_enemy[_i.y] = 0
img_enemy[_i.width]  = 16
img_enemy[_i.height] = 16

var img_build = 0;
img_build[_i.index]  = background_index[1]
img_build[_i.x] = 0
img_build[_i.y] = 0
img_build[_i.width]  = 32
img_build[_i.height] = 32


// city
// delete city tiles

for (var i=0; i<build_layer_count; i++) {
  var _tiles = tile_get_ids_at_depth((i+1)*10);
  for (var j=0; j<array_length_1d(_tiles); j++)
  if tile_exists(_tiles[j])
    tile_delete(_tiles[j])
}   

// generate city
random_set_seed(1)
var builds = 0;     
var build_layer = 0;
build_layer[2, _bl.count] = 9    // far
build_layer[1, _bl.count] = 18   // mid
build_layer[0, _bl.count] = 24   // near

// init array
for (var i=build_layer_count-1; i>=0; i--) {
  builds[i, build_layer[i, _bl.count]] = 0        // [layer, num of builds]
}


// create tiles
for (var i=0; i<build_layer_count; i++) {
  build_layer[i ,_bl.width] = 0
  build_layer[i, _bl.depth] = (build_layer_count-i) * 10
  build_layer[i, _bl.color] = make_colour_hsv(
    colour_get_hue(background_colour),
    colour_get_saturation(background_colour),
    colour_get_value(background_colour)/(build_layer_count+1) * (build_layer_count-i)
  ) 
  for (var j=0; j<build_layer[i, _bl.count]; j++) {
    var _ysc = random_range(2, 7);
    var _xsc = random_range(1, _ysc);
    builds[i,j] = tile_add(
      img_build[_i.index],
      img_build[_i.x],  img_build[_i.y],
      img_build[_i.width],
      img_build[_i.height],
      build_layer[i, _bl.width],
     -img_build[_i.height] * _ysc,
      build_layer[i, _bl.depth]
    )
    
    tile_set_scale(builds[i,j], _xsc, _ysc)
    tile_set_blend(builds[i,j], build_layer[i, _bl.color])
    build_layer[i, _bl.width] += img_build[_i.width] * _xsc // + i*10*sqr(sqr(random(2)))
  }
  build_layer[i ,_bl.scale] = 24/build_layer[i, _bl.depth]
//    build_layer[i ,_bl.scale] = room_width / build_layer[i ,_bl.width]
//    build_layer[i ,_bl.scale] = (room_width + room_width * build_layer[i, _bl.scale] * mouse_affect_x) / build_layer[i ,_bl.width]
} 

// arrange tiles
for (var i=0; i<build_layer_count; i++)
for (var j=0; j<build_layer[i, _bl.count]; j++) {
  tile_set_position(
    builds[i,j],
    tile_get_x(builds[i,j])*build_layer[i, _bl.scale],
    tile_get_y(builds[i,j])*build_layer[i, _bl.scale]+ room_height + (room_height*1.25*sqr(i/build_layer_count)),
  )
  tile_set_scale(
    builds[i,j],
    tile_get_xscale(builds[i,j])*build_layer[i, _bl.scale],
    tile_get_yscale(builds[i,j])*build_layer[i, _bl.scale]
  )
}

// target
var target = tile_get_ids_at_depth(target_depth)
target = target[0]



////  Implementation  ////

// input
if keyboard_check(vk_escape) game_end()
var _show_debug = keyboard_check(vk_f3)
var _dmx = mouse_x - tile_get_x(target)
var _dmy = mouse_y - tile_get_y(target)
var click = mouse_check_button_pressed(mb_left)



// place enemies at "source" position before moving around
var enemies;
enemies = tile_get_ids_at_depth(enemy_depth)
//enemies[0] = 0
var enemy_count = array_length_1d(enemies)
for (var i=0; i<enemy_count; i++)
if tile_exists(enemies[i]) {
  tile_set_position(enemies[i],
    tile_get_x(enemies[i]) + tile_get_width (enemies[i]) * tile_get_xscale(enemies[i])* 0.5,
    tile_get_y(enemies[i]) + tile_get_height(enemies[i]) * tile_get_yscale(enemies[i])* 0.5
  )
 
//  tile_set_position(enemies[i],
//    tile_get_x(enemies[i]) - 5 * tile_get_xscale(enemies[i]) , 
//    tile_get_y(enemies[i])
//  )
}

// spawn new enemy
var _rate = sqrt(_msec / max_time)*0.1
var _tile, _sc;
randomize()
if random(1)<_rate {
  background_colour = make_colour_hsv(
    colour_get_hue(background_colour),
    colour_get_saturation(background_colour),
    255
  )

  _tile = tile_add(
    img_enemy[_i.index],
    img_enemy[_i.x], img_enemy[_i.y],
    img_enemy[_i.width], img_enemy[_i.height],
    irandom(room_width-200)+100,
    irandom(room_height*0.25),
    enemy_depth
  ) 
  _sc = 0.1 + random(1)
  tile_set_scale(_tile, _sc, _sc)
}

// update city
for (var i=0; i<build_layer_count; i++)
for (var j=0; j<build_layer[i, _bl.count]; j++) {
  tile_set_position(
    builds[i,j],
    tile_get_x(builds[i,j])-mouse_x * mouse_affect_x * build_layer[i, _bl.scale],
    tile_get_y(builds[i,j])-mouse_y * mouse_affect_y * build_layer[i, _bl.scale]
  )
}

// update enemies
var _sc, _al;
for (var i=0; i<enemy_count; i++)
if tile_exists(enemies[i]) {
  _sc = tile_get_xscale(enemies[i])
  // scaling
  _sc = _sc * 1.01
  tile_set_scale(enemies[i], _sc, _sc)
  tile_set_position(enemies[i],
    tile_get_x(enemies[i]) - tile_get_width (enemies[i]) * tile_get_xscale(enemies[i])* 0.5,
    tile_get_y(enemies[i]) - tile_get_height(enemies[i]) * tile_get_yscale(enemies[i])* 0.5,
  )
  // mouse
  tile_set_position(enemies[i],
    tile_get_x(enemies[i]) - _dmx * tile_get_xscale(enemies[i])*0.05 ,
    tile_get_y(enemies[i]) - _dmy * tile_get_yscale(enemies[i])*0.025,
  )
 
  // moving
  tile_set_position(enemies[i],
    tile_get_x(enemies[i]) + (1.5-1/tile_get_xscale(enemies[i]))*1.5 , 
    tile_get_y(enemies[i]) + sqr(sqr(tile_get_xscale(enemies[i])*0.5))
  )
 
  tile_set_blend(enemies[i], 0)

  _al = 1 - sqr((6-tile_get_xscale(enemies[i]))/6)
  tile_set_alpha(enemies[i], _al)
  if _al <= 0 tile_delete(enemies[i])
 
}

// update target
tile_set_position(target, mouse_x, mouse_y)

// process mouse
var _tile;
if click {
  for (var i=0; i<enemy_count; i++) {
    _tile = tile_layer_find(
      enemy_depth,
      tile_get_x(target) + tile_get_width (target)*tile_get_xscale(target)*0.5,
      tile_get_y(target) + tile_get_height(target)*tile_get_yscale(target)*0.5
    )
    if tile_exists(_tile) {
      tile_delete(_tile)
    }
  }
  room_speed = 5
} else
  room_speed = 60


// draw things

// debug
if _show_debug {
  draw_set_color(c_white)
  draw_text(50, 20, string(fps_real))
  draw_text(50, 50,   "Hue: " + string(colour_get_hue(background_colour)) +
                    "; Sat: " + string(colour_get_saturation(background_colour)) +
                    "; Val: " + string(colour_get_value(background_colour))
  )
  draw_text(50, 80,  "rate: "    + string(_rate*100)+"%")
  draw_text(50, 110, "spawned: " + string(enemy_count))
  draw_text(50, 140, "mouse affect:")
  draw_text(50, 170, "     x: " + string(_dmx))
  draw_text(50, 200, "     y: " + string(_dmy))
}
