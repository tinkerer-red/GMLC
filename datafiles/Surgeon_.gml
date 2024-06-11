#define _osg
///_osg()
/*

  *** NOT TETRIS ***
  By Surgeon_
  
*/

enum GLOBAL {

  instances,
  graphics,
  general,
  dock_grid

  }
  
enum GAME {

  size=32,
  view_width=800,
  view_height=800,
  dg_size=41,
  dg_cent=20,

  }
  
enum SUB {

  create_instance,
  destroy,
  collision,
  game_reset,
  register

  }
  
enum INST {

  type,
  x,
  y,
  speed,
  direction,
  image_angle,
  image_color,
  
  cval0,
  cval1,
  cval2,
  cval3,
  cval4,
  cval5,
  cval6,
  cval7

  }
  
enum TYPE {

  player,
  block_free,
  block_dock,
  type_count

  }
  
// 0. INITIALIZE THE GAME: ------------------------------------------------------------------------|Initialize
var VARMAP,g,p,l,i;

if (!ds_exists(0,ds_type_map)) {

  VARMAP=ds_map_create();

  if (VARMAP<>0) {
    show_message("Game could not be initialized, it will now exit.");
    game_end();
    }
    
  room_speed=60;
    
  view_enabled=true;
  view_visible[0]=true;
  
  view_wview[0]=GAME.view_width;
  view_hview[0]=GAME.view_height;
  view_wport[0]=GAME.view_width;
  view_hport[0]=GAME.view_height;
  
  surface_resize(application_surface,GAME.view_width,GAME.view_height);
  window_set_size(GAME.view_width,GAME.view_height);
  window_set_caption("NOT TETRIS");
    
  l=ds_list_create();
  for (i=0; i<TYPE.type_count; i+=1) {
    l[|i]=ds_list_create();
    }
  
  VARMAP[?GLOBAL.instances]=l;
  VARMAP[?GLOBAL.graphics]=ds_map_create();
  VARMAP[?GLOBAL.general]=ds_map_create();
  VARMAP[?GLOBAL.dock_grid]=ds_grid_create(GAME.dg_size,GAME.dg_size);
  
  //----------------------------------------------------------------//
  
  //Create player instance:
  p=_osg(SUB.create_instance,GAME.view_width/2,GAME.view_height/2,TYPE.player);
  
  //Set up graphics map:
  g=VARMAP[?GLOBAL.graphics];
  g[?"player"]=-1;
  g[?"block_dock"]=-1;
  g[?"surf1"]=-1;
  g[?"surf2"]=-1;
  
  //Set up general map:
  g=VARMAP[?GLOBAL.general];
  g[?"timer"]=0;
  g[?"modulo"]=45;
  g[?"player_id"]=p;
  g[?"score"]=0;
  g[?"target_angle"]=0;
  g[?"current_angle"]=0;
  g[?"paused"]=1;
  g[?"lives"]=5;
  g[?"debug"]=0;
  g[?"flash"]=0;
  g[?"goal"]=1000;
  
  //Clear dock grid:
  ds_grid_clear(VARMAP[?GLOBAL.dock_grid],noone);
  
  //Other:
  randomize();
  
  }
else
  VARMAP=0;
  
// 1. SET UP CRUCIAL VARIABLES:
var INSTANCES=VARMAP[?GLOBAL.instances],
    GRAPHICS=VARMAP[?GLOBAL.graphics],
    GENERAL=VARMAP[?GLOBAL.general],
    DOCKGRID=VARMAP[?GLOBAL.dock_grid];

// 2. SUBROUTINES: --------------------------------------------------------------------------------|Subroutines
if (argument_count>0) {

  switch (argument[0]) {
  
    //Create_instace(X, Y, Type)
    //Returns: Instance ID
    case SUB.create_instance:
      var a=ds_list_create();
      
      a[|INST.type]=argument[3];
      a[|INST.x]=argument[1];
      a[|INST.y]=argument[2];
      
      a[|INST.speed]=0;
      a[|INST.direction]=0;
      
      a[|INST.image_angle]=0;
      a[|INST.image_color]=c_white;
            
      ds_list_add(INSTANCES[|argument[3]],a);
      
      return a;
      
      break;
      
    //Destroy(Instance ID)
    //Returns: Void
    case SUB.destroy:
      var i,inst,list;
    
      inst=argument[1];
      list=INSTANCES[|inst[|INST.type]];
      
      if (inst[|INST.type]==TYPE.block_dock and inst[|INST.image_color]==c_purple)
        GENERAL[?"score"]+=19;
      
      i=ds_list_find_index(list,argument[1]);
      ds_list_delete(list,i);
      ds_list_destroy(argument[1]);
      
      break;
  
    //Collision(Instance ID, Target type, Padding)
    //Returns: Bool
    case SUB.collision:
      var i,l,r,u,d;
      var inst,list,lsize;
      var hsize=GAME.size/2;
      var pad=argument[3];
      
      l=ds_list_find_value(argument[1],INST.x)-hsize+pad;
      r=ds_list_find_value(argument[1],INST.x)+hsize-pad;
      u=ds_list_find_value(argument[1],INST.y)-hsize+pad;
      d=ds_list_find_value(argument[1],INST.y)+hsize-pad;
      
      list=INSTANCES[|argument[2]];
      lsize=ds_list_size(list);
      
      for (i=0; i<lsize; i+=1) {
      
        inst=list[|i];
        
        if (inst==argument[1]) continue;
        if (inst[|INST.type]<>argument[2]) continue;
        
        if (inst[|INST.x]-hsize<r and 
            inst[|INST.x]+hsize>l and
            inst[|INST.y]-hsize<d and
            inst[|INST.y]+hsize>u)
          return true;
        
        }
      
      return false;
        
      break;
      
    //Register(Instance ID, X, Y, Current angle)
    //Returns: Old ID
    case SUB.register:
      var gx,gy,rv;
      
      if (dcos(argument[4])<>0) { //0, 180
        
        gx=GAME.dg_cent+(argument[2]/GAME.size)*dcos(argument[4]);
        gy=GAME.dg_cent+(argument[3]/GAME.size)*dcos(argument[4]);
      
        }
      else { //90, 270
      
        gx=GAME.dg_cent+(argument[3]/GAME.size)*dsin(argument[4]);
        gy=GAME.dg_cent-(argument[2]/GAME.size)*dsin(argument[4]);
      
        }
        
      rv=DOCKGRID[#gx,gy];
      
      if (rv==noone)
        DOCKGRID[#gx,gy]=argument[1];
      
      return rv;
    
      break;
      
    //Game_reset()
    //Returns: Void
    case SUB.game_reset:
      var i,g,p,list;
      
      //Destroy all instances:
      for (i=0; i<ds_list_size(INSTANCES); i+=1) {
      
        list=INSTANCES[|i];
        
        repeat (ds_list_size(list))
          ds_list_destroy(list[|0]);
          
        ds_list_clear(list);
      
        }
        
      //Create player instance:
      p=_osg(SUB.create_instance,GAME.view_width/2,GAME.view_height/2,TYPE.player);
        
      //Reset general map:
      g=GENERAL;
      g[?"timer"]=0;
      g[?"modulo"]=45;
      g[?"player_id"]=p;
      g[?"score"]=0;
      g[?"target_angle"]=0;
      g[?"current_angle"]=0;
      g[?"paused"]=1;
      g[?"lives"]=5;
      g[?"debug"]=0;
      g[?"flash"]=0;
      g[?"goal"]=1000;
  
      //Clear dock grid:
      ds_grid_clear(VARMAP[?GLOBAL.dock_grid],noone); 
      
      //Clear graphics:
      if (surface_exists(GRAPHICS[?"surf1"]))
        surface_free(GRAPHICS[?"surf1"]);
      if (surface_exists(GRAPHICS[?"surf2"]))
        surface_free(GRAPHICS[?"surf2"]);
      
      break;
      
    default:
      break;
  
    }

  }
  
if (argument_count>0) exit;
  
//*** NOT PAUSED STEP/DRAW:
if (GENERAL[?"paused"]==0) begin

// 3.0 PRE STEP: ----------------------------------------------------------------------------------|Pre-Step

//Count instances:
var counter,instance_n=0;
for (counter=0; counter<ds_list_size(INSTANCES); counter+=1)
  instance_n+=ds_list_size(INSTANCES[|counter]);
  
//Create more blocks:
var a,pos,xx,yy,rand_x,rand_y;

if (/*instance_n<50 and*/ (GENERAL[?"timer"] mod GENERAL[?"modulo"])==0) {

  pos=choose(0,1,2,3);
  rand_x=random_range(GAME.size,GAME.view_width-GAME.size);
  rand_y=random_range(GAME.size,GAME.view_height-GAME.size);
  
  switch (pos) {
  
    case 0:
      xx=GAME.view_width+GAME.size;
      yy=rand_y;
      break;
    
    case 1:
      xx=rand_x;
      yy=-GAME.size;
      break;
    
    case 2:
      xx=-(GAME.view_width+GAME.size);
      yy=rand_y;
      break;
    
    case 3:
      xx=rand_x;
      yy=GAME.view_height+GAME.size;
      break;
    
    default:
      break;
  
    }
    
  a=_osg(SUB.create_instance,xx,yy,TYPE.block_free);
  a[|INST.speed]=1+irandom(100)/100;
  a[|INST.direction]=((pos*90+180) mod 360);
  a[|INST.image_color]=choose(c_red,c_blue,c_green,c_yellow);
  if (irandom(100)>=95) { //Turn purple
    a[|INST.image_color]=c_purple;
    a[|INST.speed]*=2;
    }
  if (irandom(100)>=99) { //Enchant
    a[|INST.cval3]=1;
    }
  else
    a[|INST.cval3]=0;
    
  if (irandom(100)>=96) { //Bomb
    a[|INST.image_color]=c_orange;
    a[|INST.cval3]=2;
    }

  }
  
if (GENERAL[?"modulo"]>15 and ((GENERAL[?"timer"] mod 400) == 0))
  GENERAL[?"modulo"]-=1;
  
//Calc angles:
var current_angle,target_angle;

current_angle=GENERAL[?"current_angle"];
target_angle=GENERAL[?"target_angle"];

if (abs(angle_difference(current_angle,target_angle))<45) {

  if (mouse_check_button_pressed(mb_right))
    target_angle+=90;
  if (mouse_check_button_pressed(mb_left))
    target_angle+=270;
    
  }

target_angle=target_angle mod 360;
  
if (current_angle<>target_angle)
  current_angle-=sign(angle_difference(current_angle,target_angle))*4.5;
  
current_angle=current_angle mod 360;
  
GENERAL[?"current_angle"]=current_angle;
GENERAL[?"target_angle"]=target_angle;

// 3.1 STEP PROCESSING: ---------------------------------------------------------------------------|Step
var i,counter,inst,list,lsize,skip;
var player_x,player_y;

for (counter=0; counter<ds_list_size(INSTANCES); counter+=1) {

  list=INSTANCES[|counter];
  lsize=ds_list_size(list);

  switch (counter) {
  
    //Process the player block:
    case TYPE.player:
      var dir,spd=6;
      
      inst=list[|0];
      
      if (point_distance(inst[|INST.x],inst[|INST.y],mouse_x,mouse_y)>spd) {
        dir=point_direction(inst[|INST.x],inst[|INST.y],mouse_x,mouse_y);
        inst[|INST.x]+=spd*dcos(dir);
        inst[|INST.y]-=spd*dsin(dir);
        }
      else {
        inst[|INST.x]=mouse_x;
        inst[|INST.y]=mouse_y;
        }
      player_x=inst[|INST.x];
      player_y=inst[|INST.y];
      break;
      
    //Process free blocks:
    case TYPE.block_free:
      var xx,yy,dist,dir,rv;
      
      for (i=0; i<lsize; i+=1) {
        inst=list[|i];
        
        if (_osg(SUB.collision,inst,TYPE.block_dock,6) or _osg(SUB.collision,inst,TYPE.player,6)) { 
                    
          if ((current_angle mod 90)<>0 or inst[|INST.cval3]==2) {        
            
            GENERAL[?"flash"]=1;
            GENERAL[?"lives"]-=1;
            _osg(SUB.destroy,inst);
            i-=1;
            lsize-=1;
            continue;
          
            }
        
            xx=round((inst[|INST.x]-player_x)/GAME.size)*GAME.size;
            yy=round((inst[|INST.y]-player_y)/GAME.size)*GAME.size;  
          dist=sqrt(sqr(xx)+sqr(yy));
           dir=point_direction(0,0,xx,yy)+current_angle;
            
          rv=_osg(SUB.register,inst,xx,yy,current_angle);
          if (rv<>noone) {          
            rv[|INST.image_color]=c_purple;
            _osg(SUB.destroy,inst);
            i-=1;
            lsize-=1;
            continue;            
            }
           
          inst[|INST.x]=player_x+xx;
          inst[|INST.y]=player_y+yy; 
           
          inst[|INST.cval0]=dist;
          inst[|INST.cval1]=dir;
          
          inst[|INST.type]=TYPE.block_dock;
          ds_list_add(INSTANCES[|TYPE.block_dock],inst);
          ds_list_delete(list,i);
          i-=1;
          lsize-=1;
        
          }
        else {
          
          inst[|INST.x]+=inst[|INST.speed]*dcos(inst[|INST.direction]);
          inst[|INST.y]-=inst[|INST.speed]*dsin(inst[|INST.direction]);
          
          if (!point_in_rectangle(inst[|INST.x],inst[|INST.y],
              -GAME.size-1,-GAME.size-1,GAME.view_width+GAME.size+1,GAME.view_height+GAME.size+1)) {
            
            _osg(SUB.destroy,inst);
            i-=1;
            lsize-=1;
              
            }
        
          }
        
        }      
      break;
      
    //Process docked blocks:
    case TYPE.block_dock:
      for (i=0; i<lsize; i+=1) {
        inst=list[|i];
        inst[|INST.x]=player_x+inst[|INST.cval0]*dcos(inst[|INST.cval1]-current_angle);
        inst[|INST.y]=player_y-inst[|INST.cval0]*dsin(inst[|INST.cval1]-current_angle);
        if (inst[|INST.cval3]==1)
          GENERAL[?"score"]+=1/60;
        }
      break;
      
    default:
      break;
  
    }

  }

// 3.2 POST STEP: ---------------------------------------------------------------------------------|Post-Step
GENERAL[?"timer"]+=1;

//Clear non-existing lists from dock grid:
for (t=0; t<GAME.dg_size; t+=1)
  for (i=0; i<GAME.dg_size; i+=1) {

    l=DOCKGRID[#i,t];
    
    if (l==noone) continue;
  
    if (!ds_exists(l,ds_type_list)) {
      DOCKGRID[#i,t]=noone;
      }
  
    }

//Process dock grid:
var l,n,col,col1,removed;

if (keyboard_check(vk_space)) {

  removed=0;

  for (t=0; t<GAME.dg_size; t+=1)
    for (i=0; i<GAME.dg_size; i+=1) {
  
      l=DOCKGRID[#i,t];
  
      if (ds_exists(l,ds_type_list)) {
    
        col=ds_list_find_value(l,INST.image_color);
        n=0;
      
        //Left:
        if (i-1>=0 and DOCKGRID[#i-1,t]<>noone) {      
          col1=ds_list_find_value(DOCKGRID[#i-1,t],INST.image_color);      
          if (col1==col) n+=1;        
          }
        //Right:
        if (i+1<GAME.dg_size and DOCKGRID[#i+1,t]<>noone) {      
          col1=ds_list_find_value(DOCKGRID[#i+1,t],INST.image_color);      
          if (col1==col) n+=1;        
          }
        //Up:
        if (t-1>=0 and DOCKGRID[#i,t-1]<>noone) {      
          col1=ds_list_find_value(DOCKGRID[#i,t-1],INST.image_color);      
          if (col1==col) n+=1;        
          }
        //Down:
        if (t+1<GAME.dg_size and DOCKGRID[#i,t+1]<>noone) {      
          col1=ds_list_find_value(DOCKGRID[#i,t+1],INST.image_color);      
          if (col1==col) n+=1;        
          }
        
        if (n>1) {
          //*** Flood fill algorithm ***//
          var j,g,w,h,xx,yy,ax,ay,nx,ny,_old,_stack,counter,col2;

          g=DOCKGRID;
          xx=i;
          yy=t;
          _old=col;

          w=GAME.dg_size;
          h=GAME.dg_size;

          _stack=ds_stack_create();

          ax[0]=1; ax[1]=0; ax[2]=-1; ax[3]=0;
          ay[0]=0; ay[1]=-1; ay[2]=0; ay[3]=1;

          ds_stack_push(_stack,yy,xx);
          counter=0;  

          while (true) {

          if (ds_stack_size(_stack)==0) break;
  
            xx=ds_stack_pop(_stack);
            yy=ds_stack_pop(_stack);

            if ((g[#xx,yy]<>noone) and (ds_list_find_value(g[#xx,yy],INST.image_color)==_old)) {
              _osg(SUB.destroy,g[#xx,yy]);
              g[#xx,yy]=noone;
              counter+=1;
              }
  
            for (j=0; j<4; j+=1) {
  
              nx=xx+ax[j];
              ny=yy+ay[j];
    
              if(nx>0 and nx<w and ny>0 and ny<h and g[#nx,ny]<>noone and ds_list_find_value(g[#nx,ny],INST.image_color)==_old) {
                ds_stack_push(_stack,ny,nx);        
                }
      
              }
    
            }
  
          ds_stack_destroy(_stack);
          //*** ******************** ***//
        
          removed+=counter;
        
          }
    
        }
  
      }
      
  GENERAL[?"score"]+=(removed/2)*(removed+1);  
    
  }
    
//Dock grid cleanup:
var list;

if (GENERAL[?"timer"] mod 15 == 0) {

  list=INSTANCES[|TYPE.block_dock];

  for (i=0; i<ds_list_size(list); i+=1)
    ds_list_set(list[|i],INST.cval5,0);
  
  //*** Flood fill algorithm ***//
  var j,g,w,h,xx,yy,ax,ay,nx,ny,_stack,counter;

  g=DOCKGRID;
  xx=GAME.dg_cent;
  yy=GAME.dg_cent;
  
  w=GAME.dg_size;
  h=GAME.dg_size;

  _stack=ds_stack_create();

  ax[0]=1; ax[1]=0; ax[2]=-1; ax[3]=0; ax[4]=-1;  ax[5]=1; ax[6]=1; ax[7]=-1;
  ay[0]=0; ay[1]=-1; ay[2]=0; ay[3]=1; ay[4]=-1; ay[5]=-1; ay[6]=1;  ay[7]=1;
  
  ds_stack_push(_stack,yy,xx);
  counter=0;  

  while (true) {

    if (ds_stack_size(_stack)==0) break;
  
    xx=ds_stack_pop(_stack);
    yy=ds_stack_pop(_stack);

    if (g[#xx,yy]<>noone) {
      ds_list_set(g[#xx,yy],INST.cval5,1);
      }
  
    for (j=0; j<8; j+=1) {
  
      nx=xx+ax[j];
      ny=yy+ay[j];
    
      if(nx>0 and nx<w and ny>0 and ny<h and g[#nx,ny]<>noone and ds_list_find_value(g[#nx,ny],INST.cval5)==0)
        ds_stack_push(_stack,ny,nx);   
      
      }
    
    }
  
  ds_stack_destroy(_stack);
  //*** ******************** ***//

  for (i=0; i<ds_list_size(list); i+=1) {
  
    inst=list[|i];
  
    if (inst[|INST.cval5]==0) {
      
      GENERAL[?"score"]+=1;
      _osg(SUB.destroy,inst);
      i-=1;
    
      }
  
    }
    
  }

//Pause chesk:
if (keyboard_check_pressed(vk_escape))
  GENERAL[?"paused"]=1;
  
if (keyboard_check_pressed(ord("O"))) {
  GENERAL[?"debug"]=!GENERAL[?"debug"];
  show_debug_overlay(GENERAL[?"debug"]);
  }
  
//Bonus lives:
if (GENERAL[?"score"]>=GENERAL[?"goal"]) {
  GENERAL[?"goal"]+=1000;
  GENERAL[?"lives"]=clamp(GENERAL[?"lives"]+1,0,10);
  }
  
//Game over check:
if (GENERAL[?"lives"]<1) {

  show_message("GAME OVER!#Your score is: "+string(floor(GENERAL[?"score"])));
  _osg(SUB.game_reset);

  }
  
// 4.0 PRE DRAW: ----------------------------------------------------------------------------------|Pre-Draw
var surf;  

//Create surfaces:
if (!surface_exists(GRAPHICS[?"player"])) {

  surf=surface_create(GAME.size,GAME.size);
  
  surface_set_target(surf);
    draw_clear(c_teal);
  surface_reset_target();

  GRAPHICS[?"player"]=surf;
  
  }

if (!surface_exists(GRAPHICS[?"block_dock"])) {

  surf=surface_create(GAME.size,GAME.size);
  
  surface_set_target(surf);
    draw_clear(c_white);
  surface_reset_target();

  GRAPHICS[?"block_dock"]=surf;
  
  }
  
if (!surface_exists(GRAPHICS[?"surf1"])) {

  surf=surface_create(1024,1024);
  
  surface_set_target(surf);
    draw_clear_alpha(c_black,0);
  surface_reset_target();

  GRAPHICS[?"surf1"]=surf;

  }
  
if (!surface_exists(GRAPHICS[?"surf2"])) {

  surf=surface_create(1024,1024);
  
  surface_set_target(surf);
    draw_clear_alpha(c_black,0);
  surface_reset_target();

  GRAPHICS[?"surf2"]=surf;

  }
  
// 4.1 DRAW: --------------------------------------------------------------------------------------|Draw
  
//Prepare splat surfaces:
var surf1,surf2;

if (GENERAL[?"timer"] mod 2 == 0) {
  surf1=GRAPHICS[?"surf1"];
  surf2=GRAPHICS[?"surf2"];
  }
else {
  surf1=GRAPHICS[?"surf2"];
  surf2=GRAPHICS[?"surf1"];
  }
  
surface_set_target(surf1);
  
  draw_clear_alpha(c_black,0);
  
  draw_set_blend_mode_ext(bm_one,bm_one);  
    draw_surface_ext(surf2,0,0,1,1,0,c_white,0.80);      
  draw_set_blend_mode(bm_normal);
  
surface_reset_target();

//Draw room:
var i,counter,list,lsize,inst,ox,oy;

draw_clear(c_black);
surface_set_target(surf1);

//Draw "warp lines":
var da,dir,len1,len2,col;

   dir=irandom(360);
  len1=irandom_range(32,128);
  len2=512;

  da[0]=GAME.view_width/2 +len1*dcos(dir);
  da[1]=GAME.view_height/2-len1*dsin(dir);

  da[2]=GAME.view_width/2 +len2*dcos(dir);
  da[3]=GAME.view_height/2-len2*dsin(dir);

  col=make_colour_hsv((GENERAL[?"timer"]/2) mod 256,irandom(255),irandom(200));
  draw_set_colour(col);
  draw_set_alpha(1);

  draw_line(da[0],da[1],da[2],da[3]);

//Draw instances:
for (counter=0; counter<ds_list_size(INSTANCES); counter+=1) {

  list=INSTANCES[|counter];
  lsize=ds_list_size(list);

  switch (counter) {
  
    //Draw the player:
    case TYPE.player:
      inst=list[|0];
      ox=+(GAME.size/sqrt(2))*dcos(-current_angle+135);
      oy=-(GAME.size/sqrt(2))*dsin(-current_angle+135);
      draw_surface_ext(GRAPHICS[?"player"],inst[|INST.x]+ox,inst[|INST.y]+oy,1,1,-current_angle,c_white,1);
      break;
      
    //Draw free blocks:
    case TYPE.block_free:
      for (i=0; i<lsize; i+=1) {
        inst=list[|i];
        draw_set_colour(inst[|INST.image_color]);
        draw_circle(inst[|INST.x],inst[|INST.y],10,false);
        if (inst[|INST.cval3]==1) {
          draw_set_colour(c_white);
          draw_set_alpha(0.8*abs(dsin(7*GENERAL[?"timer"])));
          draw_circle(inst[|INST.x],inst[|INST.y],10,false);
          draw_set_alpha(1);          
          }
        else if (inst[|INST.cval3]==2) {
          if (GENERAL[?"timer"] mod 12 == 0) {
            draw_set_colour(c_red);
            draw_circle(inst[|INST.x],inst[|INST.y],20,false);
            }
          }
        }
      break;
    
    //Draw docked blocks:
    case TYPE.block_dock:
      var alp;
      for (i=0; i<lsize; i+=1) {
        inst=list[|i];
        ox=+(GAME.size/sqrt(2))*dcos(-current_angle+135);
        oy=-(GAME.size/sqrt(2))*dsin(-current_angle+135);
        draw_surface_ext(GRAPHICS[?"block_dock"],inst[|INST.x]+ox,inst[|INST.y]+oy,1,1,-current_angle,inst[|INST.image_color],1);
        if (inst[|INST.cval3]==1) {
          alp=0.8*abs(dsin(7*GENERAL[?"timer"]));
          draw_surface_ext(GRAPHICS[?"block_dock"],inst[|INST.x]+ox,inst[|INST.y]+oy,1,1,-current_angle,c_white,alp);
          }
        }
      break;
    
    default:
      break;
  
    }
  
  }
  
if (GENERAL[?"flash"]==1) {

  draw_set_colour(c_red);
  draw_set_alpha(0.8);
  draw_rectangle(0,0,GAME.view_width,GAME.view_height,0);
  draw_set_alpha(1);
  
  GENERAL[?"flash"]=0;

  }
  
surface_reset_target();

draw_surface(surf1,0,0);  

//Draw score:
draw_set_color(c_white);
draw_text_transformed(8,8,"Score: "+string(floor(GENERAL[?"score"])),2,2,0);

//Draw lives:
draw_set_colour(c_teal);
for (i=0; i<GENERAL[?"lives"]; i+=1) {

  draw_rectangle(GAME.view_width-24-30*i,8,GAME.view_width-8-30*i,24,false);

  }

end;
//*** PAUSED STEP/DRAW:
else begin
  var s;

  draw_clear(c_black);
  
  //Draw title:
  draw_set_halign(fa_center);
  draw_text_transformed_colour(GAME.view_width/2,32,"NOT TETRIS",6,4,0,c_teal,c_teal,c_purple,c_purple,1);
  draw_set_colour(c_maroon);
  draw_text_transformed(GAME.view_width/2,96,"One Script Game by Surgeon_",2,2,0);
  
  //Draw menu and help:
  draw_set_halign(fa_left);
  draw_set_color(c_gray);
  
  s=">>PAUSE MENU:##"+
  
    "   -Press ESCAPE to unpause the game#"+
    "   -Press ENTER to start a new game#"+
    "   -Press BACKSPACE to exit###"+
    
    
    ">>HOW TO PLAY:##"+
    "   -The goal of the game is to accumulate as many points as possible.#"+
    "   -Use the mouse to move your collector (teal block) around the screen.#"+
    "   -Colliding with the coloured orbs will attach them to the collector.#"+
    "   -Once you have three or more orbs of the same colour attached next to#"+
    "    each other, press SPACE to collect them and gain points.#"+
    "   -The more orbs you collect at once (even if they are of different colour),#"+
    "    the more bonus points you will get.#"+
    "   -Purple blocks are rare but worth more points, they will also sometimes#"+
    "    *mysteriously* appear from other blocks.#"+
    "   -Orbs of any colour flashing white are *enchanted* and will slowly increase#"+
    "    your score as long as you hold on to them.#"+
    "   -Bright orbs flashing red are bombs - Avoid them or lose a life!#"+
    "   -Use left and right mouse buttons in order to rotate the collector along#"+
    "    with any attached orbs. If you touch any orbs while rotating, they will#"+
    "    be destroyed and you will lose a life.#"+
    "   -You start the game with 5 lives and you can track them in the top right#"+
    "    corner of the screen.#"+
    "   -You also gain one bonus life for every 1000 points (max 10).#"+
    "   -The game will become faster over time.#"+
    "   -Sorry for the horrible font :)#"+
    "   -And enjoy the game!";
    
  draw_text_ext_transformed_colour(32,160,s,20,800,1.15,1,-3,c_green,c_blue,c_yellow,c_red,1);  
  
  if (keyboard_check_pressed(vk_escape))
    GENERAL[?"paused"]=0;  
  
  if (keyboard_check_pressed(vk_enter)) {
  
    _osg(SUB.game_reset);
    GENERAL[?"paused"]=0;
  
    }
  
  if (keyboard_check_pressed(vk_backspace))
    game_end();
    
  end;








