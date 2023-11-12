pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--yggdrasil
--by helloworldramen

function _init()
 thor=0
 gtime_start,gtime_end,
 frame,turn,fturn,
 fade_pct,target_fade_pct,
 allow_input,load_floor,
 aim_dir,inv_open,
 fade_clrs, --color transition table
 dxs,dys, --x and y deltas
 dnbors,shuf_dnbors, --neighbor deltas for 1d position
 wall_sigs,
 wall_msks,
 --nils
 aim_item,btn_bfr
 =
  0,0,
  0,0,0,
  1,0,
  true,false,
  ➡️,false,
  split"0,1,1,2,1,13,6,4,4,9,3,13,1,13,14",
  split"-1,1,0,0,1,1,-1,-1",split"0,0,-1,1,-1,1,1,-1",
  split"-1,1,-17,17",split"-1,1,-17,17",
  split"251,233,253,84,146,80,16,144,112,208,241,248,210,177,225,120,179,0,124,104,161,64,240,128,224,176,242,244,116,232,178,212,247,214,254,192,48,96,32,160,245,250,243,249,246,252",
  split"0,6,0,11,13,11,15,13,3,9,0,0,9,12,6,3,12,15,3,7,14,15,0,15,6,12,0,0,3,6,12,9,0,9,0,15,15,7,15,14,0,0,0,0,0,0"
 
 init_btns()
 start_game()
end

function _update60()
 upd_btns()
 --don't allow input while
 --screen is transitioning
 allow_input=fade_pct==0
 _upd_fn()
end

function _draw()
 if thor>0 then
  pal(3,rnd(split"1,2,4,5,6,7,9,10,11,12,13,14,15"))
  thor-=1
 end
  
 camera(4,4)
 frame+=1
 fade_pct=approach(fade_pct,target_fade_pct,0.04)
 _draw_fn()
 draw_windows()
 set_fade(fade_pct,1)
 draw_dbgs()
end

function start_game()
 --delegates for update functions
 _upd_fn,_draw_fn,
 msg_window,item_window
 =
  update_new_floor,draw_game
 
 mobs,traps,inv,toasts,ptcls,windows,
 inv_i,floor,turn,maps,kills,hp_lost,death =
  {},{},{},{},{},{},
  0,-1,0,0,0,0,true
 pc=add_mob(1,0,0)

 hp_window=add_window(100,117,28,13,{},7)
 flr_window=add_window(65,117,35,13,{},7)
end



-->8
--updates

function update_game()
 if (#ptcls>0) return
 
 local p_hp=pc.hp
 hp_window.txt={"♥"..p_hp.."/"..pc.mxhp}
 hp_window.clr=p_hp<4 and 8 or 7  
 
 flr_window.txt={"floor "..floor}
 
 if btn_bfr and p_hp>0 then
  handle_btn(btn_bfr)
  btn_bfr=nil
 elseif p_hp>0 then
  read_input()
 end
  
 if p_hp<=0 and pc.flash<=0 then
  gameover()
  return
 end
 
 --handle any mob deaths.
 for m in all(mobs) do
  if m.hp<=0 then
   if m.flash<=0 then
    if (m!=pc) kills+=1
    death=death and m.typ!=11
    del(mobs,m)
   end
   if not m.looted then
    loot_mob(m)
    m.looted=true
   end
  end
 end 
end

function update_new_floor()
 target_fade_pct=1
 if fade_pct==1 then
  new_floor()
  fade_to(0)
  _upd_fn=update_game
 end
end

function update_anim()
 load_btn_bfr()
 
 local done=true
 
 for m in all(mobs) do
  if m.xo!=0 or m.yo!=0 then
   m.xo,m.yo,done=
    approach(m.xo,0,m.anim_spd),
    approach(m.yo,0,m.anim_spd),
    false
  end
 end
 
 for i in all(items) do
  if i.xo!=0 or i.yo!=0 then
   i.xo,i.yo,done=
    approach(i.xo,0,3),
    approach(i.yo,0,3),
    false
   if i.xo==0 and i.yo==0 and i.x==pc.x and i.y==pc.y then
    pickup(i)
   end
  end
 end
 
 --did everybody finish animating?
 if done then
  if load_floor then
   load_floor=false
   if floor==9 then --gameover
    sfx(18)
    gameover()
   else
    _upd_fn=update_new_floor
   end
  elseif is_p_turn then  
   _upd_fn=update_game
  else
   update_ai()
  end
 else
  _upd_fn=update_anim
 end
end

function update_fov()
 local fpos,dist=mob_pos(pc),pc.vis

 for tpos=1,289 do
  if maps>2 then
   fov[tpos]=true
  elseif distance(fpos,tpos)<=dist then
   fov[tpos]=los(tpos,fpos)
  else
   fov[tpos]=false
  end
 end
end

function update_fog()
 for i=1,289 do
  fog[i]=fog[i] or fov[i]
 end
end

function update_gameover()
 target_fade_pct=0
 windows={}
 if btnp(🅾️) then
  fade_to(1,true)
  start_game() 
 end
end

function gameover()
 gtime_end=t()
 fade_to(1,true)
 windows={}
 _upd_fn=update_gameover
 _draw_fn=draw_gameover
end
-->8
--drawing

--[[
flags appendix
1:blocks movement
2:interactible
3:blocks vision
--]]
function draw_game()
 cls(1)
 map()

 draw_traps()
 draw_items()
 draw_mobs()
 draw_fxs()
 if floor>0 then
  draw_fog()
 end
 draw_toasts()
 draw_inv()
 draw_aim()
 --draw_dist_map()
end

function draw_gameover()
 local td=gtime_end-gtime_start
 local tm,ts=flr(td/60),flr(td%60)
 local timemsg="time: "..tm..":"..(ts<10 and "0"..ts or ts)
 local title=pc.hp>0 
  and "~victorious~"
  or  "..defeated.."
 local xo,yo=41,30
 local xo2,yo2=xo+4,yo+16
 
 cls(0)
 print(title,xo,yo,7)
 print(" floor: "..floor,xo2,yo2,6)
 print(" turns: "..turn,xo2,yo2+8,6)
 print(" kills: "..kills,xo2,yo2+16,6)
 print("♥lost: "..hp_lost,xo2,yo2+24,6) 
 print(timemsg,xo2,yo2+40,6)
 
 if pc.hp>0 then
  local souls=0
  foreach(inv,function(i)
   if (i.name=="soul") souls+=1
  end)
  print("souls returned: "..souls,xo2-12,yo2+48,6) 
 end
 print("🅾️ to continue",xo-4,yo2+90,7)
end

function draw_mobs()
 for m in all(mobs) do
  local alive,flashing,soul=m.hp>0,m.flash>0,m.soul
  local clr=flashing and 7 or nil
  m.flash-=min(1,m.flash)
  clr=(soul and sin(frame/24)>0.8) and 13 or clr
  if alive or flashing and sin(time()*8)>0 then
   draw_sprite(
    get_anim_sprite(m.anim),
    m.x*8+m.xo,
    m.y*8+m.yo,
    clr, 
    m.flipped
   )
  end
 end
end

function draw_traps()
 for trap in all(traps) do
  draw_sprite(
   get_anim_sprite(trap.anim),
   trap.x*8,
   trap.y*8
  )
 end
end

function draw_items()
 local yo2={-1,-2,-1,0}
 for i in all(items) do
  local x1,y1=i.x*8+i.xo,i.y*8+i.yo,i
  spr(255,x1,y1)
  draw_sprite(
   i._spr,
   x1,
   y1+yo2[flr(frame/15)%4+1],
   nil --color
  )
 end
end

function pal_dim()
 --alternate palette for dim look.
 pal(3,5)
 pal(6,5)
 pal(7,6)
 pal(9,4)
 pal(10,9)
 pal(13,5)
end

function draw_fog()
 pal_dim()
 
 for pos=1,256 do
  local x,y=posxy(pos)
  local uncovered,item = fog[pos],get_item(x,y)
  if uncovered and not fov[pos] then 
   --uncovered and not currently in sight
   spr(mget(x,y),x*8,y*8)
   if item then
    spr(208,x*8,y*8)
    spr(item._spr,x*8,y*8)
   end
  elseif not uncovered then
   --covered
   spr(255,x*8,y*8)
  end
 end
 
 pal()
end

--tools

function get_anim_sprite(sprites)
 --divide frame by different 
 --values for different speeds,
 --lower is faster.
 return sprites[flr(frame/15)%#sprites+1]
end

function draw_sprite(_spr,_x,_y,_clr,_flipped)
 if _clr then
  for i=2,15 do pal(i,_clr) end
 end
 spr(_spr, _x, _y, 1, 1, _flipped)
 pal()
end

--ui

function add_window(_x, _y, _w, _h, _txt, _clr)
 return add(windows,{
  x=_x, 
  y=_y,
  w=_w, 
  h=_h,
  txt=_txt,
  clr=_clr
 })
end

function draw_windows()
 for w in all(windows) do
  local wx, wy, ww, wh, clr = w.x, w.y, w.w, w.h, w.clr
  --drawing the main window with double borders
  rectfill(wx,wy,wx+max(ww-1,0),wy+max(wh-1,0), 1)
  rect(wx+1,wy+1,wx+ww-2,wy+wh-2,clr)
  wx+=4
  wy+=4
  
  clip(wx-4, wy-4, ww-8, wh-8)
  for i=1, #w.txt do
   local _txt = w.txt[i]
   print(_txt, wx, wy, clr)
   wy+=6
  end
  clip()
  
  if w.dur then
   w.dur-=1
   if w.dur<=0 then
    --animate collapsing the window
    w.h-=w.h/3 --collapse by height
    w.y+=w.h/6 --collapse towards center
    if w.h<1 then
     del(windows, w)
    end
   end
  elseif w.can_btn then
   print_outlined(
    "🅾️", --text
     wx+ww-9, --x
     wy-1.5+sin(time()), --y
     clr, --button color
     1 --outline color
    ) 
  end
 end
end

--show a temporary message, with duration in frames.
--the message can only be one string.
function show_timed_msg(msg, _dur, c)
 --calculate the required width, with some extra h-padding
 local w=(#msg+2)*4+7
 local window=add_window(
  63-w/2,56,w,13,{" "..msg},c
 )
 
 window.dur=_dur
end

--[[
show a text box that may display
multiple lines of text. only the
height will adjust.
--]]
function show_msg(texts,clr)
 msg_window = add_window(
  20, --x
  46, --y
  95, --width
  #texts*6+7, --height
  texts, --text
  clr --color
 )
 msg_window.can_btn = true
end

function print_outlined(txt,x,y,clr,outline_clr)
 for i=1,8 do
  print(txt,x+dxs[i],y+dys[i],outline_clr)
 end 
 print(txt,x,y,clr)
end

function show_toast(_txt,_x,_y,_clr,dur)
 add(toasts,{
  txt=_txt,
  x=_x,
  y=_y-5,
  yo=5,
  clr=_clr,
  dur=dur or 10
 })
end

function draw_toasts()
 for t in all(toasts) do
  local m=t.mob
  t.yo-=t.yo/20
  if t.yo<=1 then
   del(toasts,t)
  elseif m then
   local x=(m.x*8)-(#t.txt*2)+4
   print_outlined(t.txt,x,m.y*8-5+t.yo,t.clr,1)
  else
   print_outlined(t.txt,t.x-(#t.txt*2)+4,t.y+t.yo,t.clr,1)
  end
 end
end

function set_fade(pct,mode)
 for j=1,15 do
  local clr=j
  for k=1,flr((max(0,min(pct,1))*100+j*1.46)/22) do
   clr=fade_clrs[clr]
  end
  pal(j,clr,mode)
 end
end

function fade_to(pct,force)
 target_fade_pct=pct
 if force then
  repeat
   fade_pct=approach(fade_pct,target_fade_pct,0.04)
   set_fade(fade_pct,1)
   flip()
  until fade_pct==target_fade_pct
 end
end

function draw_inv()
 local x,y,w,h=7,117,13,12
  
 --selected item border
 if inv_i>=1 then
  local xo=(inv_i-1)*12+x
  rectfill(xo,y,xo+w,y+h,1)
  rect(xo+1,y+1,xo+w-1,y+h-1,7)
 end
 
 local selecting=inv_scroll()
 
 for i=1,#inv do
  local item,xo=inv[i],(i-1)*12+x
  if inv_i!=i then
   --dim unselected items
   pal(10,selecting and 6 or 9)
   pal(9,selecting and 5 or 4)
  end
  spr(item._spr,xo+3,y+3)
  if not selecting then
   --print quantity by default
   print_outlined(item.qty,xo+11,y+8,7,1)
   --collapse existing item tips
   if (item_window) item_window.dur=0
  elseif inv_i==i and selecting then
   --for the selected item
   spr(244,xo-5,y+3)
   spr(245,xo+11,y+3)
   del(windows,item_window)
   item_window=add_window(x,y-14,64,13,{item.tip},7)  
  end
  pal()
 end
end

function draw_aim()
 if aim_item then
  local aim_pos=mob_pos(pc)+dnbors[aim_dir]
  local ax,ay=posxy(aim_pos)
  local dx,dy=dxs[aim_dir],dys[aim_dir]
  spr(243+aim_dir,ax*8+dx*sin(frame/15),ay*8+dy*sin(frame/15))
 end
end

function add_particle(_spr,x,y,tx,ty,spd)
 add(ptcls,{
  _spr=_spr,x=x,y=y,tx=tx,ty=ty,spd=spd
 })
end

fxs={}
function draw_fxs()
 for fx in all(fxs) do
  spr(deli(fx.anim,1),fx.x,fx.y)
  if (#fx.anim<1) del(fxs,fx)
 end
end
-->8
--misc

function approach(a, target, spd)
 return a<target and min(a+spd, target) or max(a-spd, target)
end

function border(pos)
 local x,y=posxy(pos)
 return x==0 or x==16 or y==0 or y==16
end

--[[
mode can be one of:
 "move"
 "move_thru_mobs"
 "fly_dmap"
 "idle"
 "breed"
]]--
function blocked(tpos,mode,fly,door)
 local x,y=posxy(tpos)
 local tile,mob,trap=
  mget(x,y),
  get_mob(x,y),
  get_trap(x,y)
 local nonpc_mob=mob and mob!=pc
 local unwalkable=fget(tile,0) and not(door and tile==203)
 if fly then
  unwalkable=unwalkable and fget(tile,2)
 end

 if (unwalkable) return true
  
 if mode=="move" then
  return mob
 elseif mode=="idle" then
  return (not fly and trap) or nonpc_mob
 elseif mode=="chase" then
  return nonpc_mob
 elseif mode=="breed" then
  return trap or mob
 end --default nil/false
end

--shuffle a table via fisher-yates.
function shuf(t)
 for i=#t,1,-1 do
  local j=flr(rnd(i))+1
  t[i],t[j]=t[j],t[i]
 end
 return t
end

--return table indexed by 1d-pos
--where the valus indicate the
--walkable dist from original position
function get_dist_map(o_pos,mode,fly,door)
 local q,dmap,dist,i={o_pos},{},0,1

 while i<=#q do
  for _=i,#q do
   local pos=q[i]
   i+=1 
   if not dmap[pos] then
	   dmap[pos]=dist
	   for dnbor in all(dnbors) do
	    local nbor=pos+dnbor
	    if not dmap[nbor]
	      and not blocked(nbor,mode,fly,door) 
	      then
	     add(q,nbor)
	    end
	   end
	  end
  end
  dist+=1
 end

 return dmap
end

--convert x and y to 1d-pos
function xypos(x,y)
 return x+y*17+1
end

--returns x,y (0 indexed)
--from pos (1 indexed)
function posxy(pos)
 return (pos-1)%17, flr((pos-1)/17)
end

function mgetpos(pos)
 return mget(posxy(pos))
end

--retest should be false on
--first call, it indicates whether
--we have called the function in
--reverse yet (for symmetry)
function los(fpos,tpos,retest)
 --always see adjacent things.
 --1.5 because permitting diagonals.
 if distance(fpos,tpos)<=1.5 then
  return true
 end
 
 local fx,fy=posxy(fpos)
 local tx,ty=posxy(tpos)
 local dx,dy,sign_x,sign_y=
   abs(tx-fx),abs(ty-fy),
   sgn(tx-fx),sgn(ty-fy)
 local err=dx-dy
 
 while fx!=tx or fy!=ty do
  if fget(mget(fx,fy),2) then
   return not retest and los(tpos,fpos,true)
  end
  local mob=get_mob(fx,fy)
  if mob and mob.typ==9 then --giants block sight
   return not retest and los(tpos,fpos,true)
  end
  
  --multiply by more for more
  --corner fix range
  local e2=err*16
  if e2>-dy then
   err-=dy
   fx+=sign_x
  end
  if e2<dx then
   err+=dx
   fy+=sign_y
  end
 end
  
 return true
end

function distance(fpos,tpos)
 local fx,fy=posxy(fpos)
 local tx,ty=posxy(tpos)
 local dx,dy=fx-tx,fy-ty
 return sqrt(dx^2+dy^2)
end

function bitcomp(sig,target,mask)
 local _mask=mask or 0
 return sig|_mask==target|_mask
end

function get_sig(pos,get_bit)
 local sig=0
 for d in all(split"-1,1,-17,17,-16,18,16,-18") do
  sig=(sig<<1)|get_bit(pos+d)
 end
 return sig
end

function get_sig_i(sig,sigs,msks)
 for i=1,#sigs do
  if bitcomp(sig,sigs[i],msks[i]) then
   return i
  end
 end
 return 0
end

function split2d(s)
 local t2={}
 foreach(split(s,"|",false),function(t)
  add(t2,split(t))
 end)
 return t2
end

function splitdict(s)
 local d={}
 foreach(split(s),function(e)
  local kv=split(e,":")
  d[kv[1]]=kv[2]
 end)
 return d
end
 


-->8
--input

function load_btn_bfr()
 if (not allow_input) return
 for i=0, 5 do
  if btnp(i) then 
   btn_bfr=i 
   return
  end
 end
end

function read_input()
 if (not allow_input) return
 --handle special inputs first
 if (btnr(❎)) inv_open=false

 if inv_scroll() and inv_i>0 then
  if not inv_open then
   inv_open=true
   sfx(14)
  end
  --expand items
  if btnps(⬅️) then
   --change item left
   inv_i-=1
   sfx(15)
  elseif btnps(➡️) then
   --change item right
   inv_i+=1
   sfx(15)
  end
  inv_i=(inv_i-1)%#inv+1
  if (#inv==0) inv_i=0
 --try getting other buttons
 elseif btnps(🅾️) then
  handle_btn(🅾️)
 elseif btnps(❎) then
  handle_btn(❎)
 elseif not btn(❎) and not btn(🅾️) then
  for i=0,3 do
  --make mvmt repeat by btnp
   if btnp(i) then
    aim_dir=i+1
    handle_btn(i)
    return
   end
  end
 end
end

function handle_btn(_btn)
 local did_act=false
 
 if msg_window then
  if _btn>3 then
   msg_window=nil
  end
 elseif aim_item then
  if _btn==❎ then
   aim_item=false
  elseif _btn==🅾️ then
   did_act=use_aim_item()
  else
   aim_dir=_btn+1
   sfx(15)
  end
 elseif _btn==🅾️ then
  did_act=use_item()
 elseif _btn<4 then  
  did_act=move_mob(
    pc,
    dxs[_btn+1],
    dys[_btn+1]
  ) 
 end
 
 if did_act then
  turn+=1
  fturn+=1
  is_p_turn=#mobs==1
 end
 
 p_dist_map=get_dist_map(mob_pos(pc))
 update_fov()
 _upd_fn=update_anim
 update_fog()
end

function inv_scroll()
 return not aim_item and (btn(❎) or btnl(🅾️))
end
-->8
--movement

function move_mob_pos(m,tpos,skip_anim)
 if (m.hp<=0) return false
 
 local tx,ty=posxy(tpos)
 return move_mob(m,tx-m.x,ty-m.y,skip_anim)
end

function move_mob(m,dx,dy,skip_anim)
 if m.wait then
  m.wait=false
  return
 end
 
 local tx,ty=m.x+dx,m.y+dy
 local fpos,tpos,tile,did_act=
  xypos(m.x,m.y),xypos(tx,ty),
  mget(tx,ty),false
 
 --handle orientation
 if (dx<0) m.flipped = true
 if (dx>0) m.flipped = false
 
 if blocked(tpos,"move",m.fly) then
  --not walkable
  m.xo,m.yo,m.anim_spd=4*dx,4*dy,1
 else
  --walkable
  m.x+=dx
	 m.y+=dy
	 if not skip_anim then
	  m.xo,m.yo,m.anim_spd=
	   -8*dx,-8*dy,3
	 end
	 did_act=true
	 if (m==pc) sfx(0)
 end
 
 --don't animate mobs out of sight
 if (not fov[fpos] and not fov[tpos])
   or (m!=pc and fov[tpos] and fget(tile,2)) --bumps
   then
  m.xo,m.yo=0,0
 end

 return handle_interact(m,tile,tx,ty) 
   or did_act
end

function handle_interact(mob,tile,x,y)
 local other,item=get_mob(x,y),get_item(x,y)
 local pcatkr,pcdefr=mob==pc,other==pc
 if other 
   and mob!=other
   and (mob==pc or pcdefr)
   then
  --handle combat
  if not hit_mob(mob,other) then
   sfx"24"
  elseif pcatkr then
   sfx"9"
  elseif pcdefr then
   sfx"10"
  end
  return true
 end
 
 if tile==200 and not mob.fly then --trap
  trigger_trap(x,y)
  sfx(17)
 elseif tile==203 and mob.door then
  --doors
  mset(x,y,219)
  sfx(1)
  return true
 end
 
 if (not pcatkr) return false
 
 if item then
  pickup(item)
  return
 end
  
 if tile==202 or tile==201 then
  --vases
  mset(x,y,tile+16)
  loot_pot(x,y)
  sfx"4"
 elseif tile==204 then 
  --l chest
  mset(x,y,220)
  loot_box_l(x,y)
  sfx"5"
 elseif tile==205 then
  --s chest
  mset(x, y, 221)
  loot_box_s(x,y)
  sfx"5"
 elseif tile==206 then
  --upstairs
  sfx"8"
  load_floor=true
 elseif tile==222 then
  --signs
  sfx"7"
  return false
 else
  return false
 end
 
 return true
end

-->8
--mobs

--[[
the index is the mob type.
e.g, first entry of each these
tables is for the player (type 1).

mobs:
 1-player
 2-slime
 3-skeleton
 4-crab
 5-bat
 6-rat
 7-hound
 8-trex
 9-giant
 10-knight
 11-death
--]] 

mob_hps=split"5,1,1,2,1,1,1,2,3,2,10"
mob_atks=split"1,1,2,1,1,1,1,2,3,1,99"
mob_vis=split"6,4,5,0,4,4,7,2.5,5,5,0"
mob_loot_pct=split"0,7,7,7,15,5,7,70,30,30,100"
mob_loot=split2d[[
0|
1,2,3,4,6,8,9,10|
1,2,3,4,6,8,9,10|
1,2,3,4,6,7,8,9,10|
1,2,3,3,4,4,9,10|
1|
2|
5,6,7,8|
1,4,6,6,7,7,8,8,9|
1,6,7,8,9|
11|
]]
mob_anims=split2d[[
1,2,3,4|
5,6,5,7|
8,9,10,11|
19,20,21,20|
16,17,18,17|
35,36,35,37|
22,23,24,23|
25,26,27,28|
32,32,33,33,32,32,34,34|
12,13,14,15|
29,29,30,30,29,29,31,31|
]]
mob_fly=splitdict"5:bat,11:death"
mob_door=splitdict"1:player,3:skeleton,9:giant,10:knight,11:death"
mob_spawns=split2d[[
2,2,5|
2,2,3,5|
2,3,4,5,6|
3,3,4,5,6,10|
3,4,6,7,9,10|
3,6,7,9,10|
3,3,6,6,7,7,8,9,9,10,10|
3,6,7,8,9,10|
7,8,9,9,10,10
]]

function spawn_mobs(rmap,down_pos)
 if (floor==0) return
 local pmap={}
 for p=1,255 do 
  if rmap[p] and distance(p,down_pos)>3 then
   add(pmap,p)
  end 
 end
 shuf(pmap)
 for n=1,9+floor do 
  while #pmap>0 do
  	local x,y=posxy(deli(pmap,#pmap))
  	local flag=fget(mget(x,y))
  	if flag==0 or flag==4 then
   	local mob=rnd(mob_spawns[floor])
   	if mob!=4 or crabsafe then
   	 add_mob(mob,x,y)
   	 break
   	end
  	end
  end
 end
 if floor%2==0 then
  mobs[flr(rnd(#mobs-1))+2].soul=true
 end
end

function crabsafe(x,y)
 local safe=true
 function brk(_x,_y)
  local t=mget(_x,_y)
  safe=safe and t!=200
  return fget(t,0)
 end
 for x2=x,0,-1 do
  if (brk(x2,y)) break
 end
 for x3=x,16 do
  if (brk(x3,y)) break
 end
 return safe
end

function add_mob(_typ,_x,_y)
 local m={
  typ=_typ,
  x=_x,
  y=_y,
  xo=0, --x offset, used for animation
  yo=0, --y offset, used for animation
  hp=mob_hps[_typ],
  mxhp=mob_hps[_typ],
  atk=mob_atks[_typ],
  vis=mob_vis[_typ],
  eva=_typ==1 and 0.1 or 0,
  fly=mob_fly[_typ],
  door=mob_door[_typ],
  anim=mob_anims[_typ],
  anim_spd=0,
  flash=0,
  flipped=false,
  task="idle",
  task_pos=nil,
  task_map={},
  stun=0
 }
 
 return add(mobs,m)
end

function get_mob(x,y)
 for m in all(mobs) do
  if m.x==x and m.y==y and m.hp>0 then
   return m
  end
 end
end

function hit_mob(atkr,defr,atk)
 if (not defr) return false
 
 local toast_clr,dmg=
  defr==pc and 9 or 10,atk or atkr.atk
 foreach(inv,function(i)
  if (i.name=="grim") dmg=99
 end) 
 
 --miss!
 if rnd()<defr.eva then
  mob_say(defr,"miss",toast_clr)
  return false
 end
 
 defr.hp-=dmg
 if (defr==pc) hp_lost+=dmg
 
 if defr.hp<=0 then
  defr.flash=12
  if defr==pc then
   sfx"11"
   defr.flash=64
  end
 else
  defr.flash=8
 end
 
 if fov[mob_pos(defr)] then
  mob_say(defr,"-"..dmg,toast_clr)
 end
 
 return true
end

function mob_pos(m)
 return xypos(m.x,m.y)
end

function mob_say(m,_txt,c)
 local mpos=mob_pos(m)
 add(toasts,{
  txt=_txt,
  x=m.x*8,
  y=m.y*8,
  yo=5,
  clr=c,
  mob=fov[mpos] and m or nil
 })
end

--can m los the player
function mob_los_p(m)
 if (m.typ==11) return true
 local mpos,ppos=mob_pos(m),mob_pos(pc)
 return distance(mpos,ppos)<=m.vis 
  and (
   (m.typ==7 and p_dist_map[mpos]) --hounds can smell
   or los(mpos,ppos)
  )
end
-->8
--ai

dflt_dnbors=split2d([[
-1,1,-17,17|
1,-1,17,-17|
-17,17,-1,1|
17,-17,1,-1
]])
bat_dnbors=split2d([[
-16,16,-18,18|
16,-16,18,-18|
-18,18,-16,16|
18,-18,16,-16
]])
omni_dnbors=split"-18,-17,-16,-1,1,16,17,18"

baby_mobs,
task_map,
task_map_fly,
task_map_door={}

function refresh_task_maps()
 local ppos=mob_pos(pc)
 task_map=get_dist_map(ppos)
 task_map_fly=get_dist_map(ppos,nil,true)
 task_map_door=get_dist_map(ppos,nil,false,true)
end

function get_task_map(m)
 if m.fly and m.door then
  return get_dist_map(mob_pos(pc),nil,true,true)
 elseif m.fly then
  return task_map_fly
 elseif m.door then
  return task_map_door
 else
  return task_map
 end
end

function update_ai()
 load_btn_bfr()
 local ppos=mob_pos(pc)
 refresh_task_maps()
 for m in all(mobs) do
  local mpos=mob_pos(m)
  local task_map=get_task_map(m)
  
  if m.stun>0 then
   m.stun-=1
   mob_say(m,"?!",10)
  elseif m.typ==11 and fturn==109 then
   --death waits a turn
  elseif m.hp<=0 or m==pc then
   --dead mobs can't act
   --pc doesn't have an ai
  elseif m.task=="idle" then
   if mob_los_p(m) then
    m.task="chase"
    m.task_pos=ppos
    m.task_map=task_map
    mob_say(m,"!",m.typ==11 and 8 or 10)
    ai_chase(m)
   else
    ai_idle(m)
   end
  elseif m.task=="chase" then
   if mob_los_p(m) then
    --keep chasing
    m.task_pos=ppos
    m.task_map=task_map
    ai_chase(m)
   elseif m.task_pos==mpos then
    --give up
    mob_say(m,"?",10)
    m.task="idle"
    ai_idle(m)
   else
    --keep chasing (guess)
    ai_chase(m)
   end
  end
 end
 
 for baby in all(baby_mobs) do
  baby=add_mob(baby.typ,baby.x,baby.y)
  mob_say(baby,"웃",14)
 end
 baby_mobs={}
 
 if death and fturn==108 then
  for pos=1,255 do
   if mgetpos(pos)==207 then
    local x,y=posxy(pos)
    add_mob(11,x,y)
    show_timed_msg("death approaches",60,7)
    sfx"27"
    break
   end
  end
 end

 is_p_turn=true
end

function ai_idle(m)
 if m.typ==4 then
  --crab
  ai_idle_crab(m)
 elseif m.typ==5 then
  --bat
  ai_idle_normal(m,rnd(bat_dnbors))
 elseif m.typ==9 then
  --giant
  if turn%2==0 then
   ai_idle_normal(m)
  end
 else
  ai_idle_normal(m)
 end
end

function ai_chase(m)
 if m.typ==2 then
  --slime
  if rnd()<0.3 then
   ai_idle_normal(m)
  else
   ai_chase_normal(m)
  end
 elseif m.typ==5 then
  --bat
  if rnd()<0.6 then
   ai_idle(m)
  else
   ai_chase_normal(m,rnd(bat_dnbors))
  end
 elseif m.typ==6 then
  --rat
  if not ai_breed(m,0.3) then
   ai_chase_normal(m)
  end
 elseif m.typ==9 then
  --giant
   if turn%2==0 then
    ai_chase_normal(m)
   end
 elseif m.typ==11 then
  --death
   if rnd()<0.35 then
    ai_chase_normal(m,omni_dnbors)
   end
 else
  ai_chase_normal(m)
 end
end

function ai_idle_normal(m,m_dnbors)
 if not m_dnbors then
  m_dnbors=rnd(dflt_dnbors)
 end
 local pos=mob_pos(m)
 
 for dnbor in all(m_dnbors) do
  local tpos=pos+dnbor --'to' pos
  local tx,ty=posxy(tpos)
  if not blocked(tpos,"idle",m.fly) then
   move_mob_pos(m,tpos)
   return
  end
 end
 
 move_mob_pos(m,rnd(m_dnbors)+pos)
end

function ai_idle_crab(m)
 local crableft=m.crableft
 local pos,dir=mob_pos(m),crableft and -1 or 1
 if blocked(pos+dir,"chase") then
  m.crableft=not crableft
  move_mob(m,-dir,0)
 else
  move_mob(m,dir,0)
 end 
 if mob_pos(m)==pos then
  m.crableft=not m.crableft
 end
end

function ai_chase_normal(m,m_dnbors)
 if not m_dnbors then
  m_dnbors=rnd(dflt_dnbors)
 end
 local pos,p_pos=mob_pos(m),m.task_pos
 local cur_dist,min_dist,best=
   m.task_map[pos],99
 
 --use the player's dist map
 --to get closer to player
 for dnbor in all(m_dnbors) do
  local tpos=pos+dnbor
  local nxt_dist=m.task_map[tpos]
  if nxt_dist and cur_dist 
    and nxt_dist<cur_dist 
    and not blocked(tpos,"chase",m.fly,m.door)
    then
   local tdist=distance(tpos,p_pos)
   if tdist<min_dist then
    best=tpos
    min_dist=tdist
   end
  end
 end
 
 return best and move_mob_pos(m,best) or ai_idle(m)
end

function ai_breed(m,pct)
 if not m.birthed and #mobs<30 and rnd()<pct then
  local bpos=get_breed_pos(m)
  if bpos then
   local bx,by=posxy(bpos)
   for otherbaby in all(baby_mobs) do
    if otherbaby.x==bx and otherbaby.y==by then
     return false
    end
   end
   add(baby_mobs,{
    typ=m.typ,
    x=bx,
    y=by
   })
   m.birthed=true
   return true
  end
 end
end

function get_breed_pos(m)
 local mpos=mob_pos(m)
 for dnbor in all(rnd(dflt_dnbors)) do
  if not blocked(mpos+dnbor,"breed") then
   return mpos+dnbor
  end
 end
end
-->8
--debug

dbgs={}

function draw_dbgs()
 local i=1
 for dbg in all(dbgs) do
  print(dbg,5,i*6,11)
  i+=1 
 end
end

function logd(i,txt,tag)
 dbgs[i]=(tag or "[no tag]")..": "..txt
end

function draw_dist_map()
 local dist_map=get_dist_map(mob_pos(pc),"dmap",false,true)
 for i=1,289 do
  local x,y=posxy(i)
  if dist_map[i] then
    print(dist_map[i],x*8,y*8,11)
  end
 end
end
-->8
--items
--[[
1: rice
2: bell
3: warp
4: map
5: thor
6: bash
7: trap
8: gun
9: jump
10: pot
11: grim scythe
12: hook
13: soul
]]--
item_names,
item_sprs,
item_tips
=
 split"rice,bell,warp,map,thor,bash,trap,gun,jump,pot,grim,hook,soul",
 split"237,236,238,239,235,234,233,253,252,251,250,249,254",
 split"recovers ♥,makes noise,teleports you,reveals things,brings wrath,breaks things,lays spikes,piercing shot,hop obstacles,places a pot,accursed tool,grabs things,..."

poi=splitdict"201:t,202:t,203:t,204:t,205:t,206:t"

function add_item(_id,_qty,_x,_y)
 local item
 
 item=add(items,{
  id=_id,
  name=item_names[_id],
  _spr=item_sprs[_id],
  x=_x,
  y=_y,
  xo=0,
  yo=0,
  qty=_qty,
  tip=item_tips[_id]
 })
 
 show_toast(item.name.."(".._qty..")",_x*8,_y*8,7)
 sfx"3"
end

function get_item(x,y)
 for i in all(items) do
  if i.x==x and i.y==y then
   return i
  end
 end
end

function pickup(item)
 local no_match,did_pickup=true,true
 
 for i=1,min(#inv+1,4) do
  if i==#inv+1 then
   --reached empty slot
   add(inv,del(items,item))
   no_match=false
   break
  else
   local inv_item=inv[i]
   if inv_item.name==item.name then
    local space=9-inv_item.qty
    if space<=0 then
     mob_say(pc,"full!",7)
     did_pickup=false
    elseif space>=item.qty then
     inv_item.qty+=item.qty
     del(items,item)
    else --space for some
     inv_item.qty=9
     item.qty=item.qty-space
    end
    no_match=false
    break
   end
  end
 end

 if (inv_i<1) inv_i=1
 
 if no_match then
  local cur_item=inv[inv_i]
  add_item(cur_item.id,cur_item.qty,pc.x,pc.y)
  inv[inv_i]=del(items,item)
 end
 
 sfx(did_pickup and 12 or 6)
end

function use_item()
 if (inv_i<1) return false

 
 local item,did_act=inv[inv_i],true
 local name=item.name
 
 if (name=="grim") then
  sfx"6"
  return false
 end
 
 item.qty-=1
 
 if name=="rice" then
  local heal=pc.hp<pc.mxhp and 1 or 0
  pc.hp+=heal
  mob_say(pc,"+"..heal,11)
  sfx(13,-1,0,5)
 elseif name=="bell" then
  mob_say(pc,"♪",7)
  sfx(16)
  local ppos=mob_pos(pc)
  for m in all(mobs) do
   if m!=pc and m.vis>0 and distance(mob_pos(m),ppos)<10 then
    mob_say(m,"!",10)
    m.task="chase"
    m.task_map=get_task_map(m)
    m.task_pos=ppos
   end
  end 
 elseif name=="warp" then
  local tmap={}
  for p=1,255 do add(tmap,p) end
  local pmap,pcpos,tpos,tpos2={},mob_pos(pc)
  
  for p in all(shuf(tmap)) do
   if not blocked(p,"move") 
     and distance(pcpos,p)>5 then
    tpos2=p
    --prefer somewhere new
    if not fog[p] then
     tpos=p
     break
    end
   end
  end
  local wpos=tpos or tpos2
  if wpos then
   move_mob_pos(pc,wpos,true)
   aoestun(wpos)
   sfx"19"
  else 
   sfx"6"
   return false
  end
 elseif name=="map" then
  for pos=1,255 do
   local x,y=posxy(pos)
   if poi[mget(x,y)] or maps>0 then
    fog[pos]=true
   end
  end
  maps=min(maps+1,3)
  sfx(20,-1,0,split"10,13,31"[maps])
 elseif name=="thor" then
  thor=10
  for m in all(mobs) do
   if fov[mob_pos(m)] then
    hit_mob(pc,m)
   end
  end
  sfx"21"
 elseif name=="soul" then
  pc.hp+=1
  pc.mxhp+=1
  mob_say(pc,"+1max",11)
  sfx"13"
 elseif name=="bash" 
   or name=="trap"
   or name=="gun" 
   or name=="jump"
   or name=="pot"
   or name=="hook"
   then
  aim_item,did_act=item,false
  item.qty+=1 --reverse
  sfx"14"
 end
 
 if item.qty<=0 then
  del(inv,item)
  inv_i=min(inv_i,#inv)
 end
 
 return did_act
end

function use_aim_item()
 local name,ppos,tpos,success,did_act=
  aim_item.name,mob_pos(pc),
  mob_pos(pc)+dnbors[aim_dir],
  false,true
 local tx,ty=posxy(tpos)
 
 if name=="bash" then
  if not border(tpos) then
   local mob=get_mob(tx,ty)
   sfx"22"
   if mob then
    hit_mob(pc,mob,2)
   else
    del(items,get_item(tx,ty))
    mset(tx,ty,192)
    trigger_trap(tx,ty)
    prettywalls()
   end
   success=true
  end
 elseif name=="trap" then
  if not blocked(tpos,"move") then
   trigger_trap(tx,ty)
   add_trap(tx,ty)
   sfx(17,-1,0,1)
   success=true
  end
 elseif name=="gun" then
  local gpos=tpos
  while true do
   local tile=mgetpos(gpos)
   local gx,gy=posxy(gpos)
   local mob=get_mob(gx,gy)
   if (mob) hit_mob(pc,mob,1)
   if fget(tile,0) and fget(tile,2) then
    break
   elseif fov[gpos] then
    local _anim=aim_dir>2 
     and split"212,212,213,214,214,214,214,215,215"
     or split"196,196,197,198,198,198,198,199,199"
    add(fxs,{anim=_anim,x=gx*8,y=gy*8})
   end
   gpos+=dnbors[aim_dir]
  end
  sfx"23"
  success=true
 elseif name=="jump" then
  local delta=dnbors[aim_dir]
  local jpos1,jpos2=ppos+delta,ppos+delta*2
  if not border(jpos1) 
    and not blocked(jpos2,"move") 
    then
   move_mob_pos(pc,jpos2)
   aoestun(jpos2)
   success=true
   sfx"26"
  end 
 elseif name=="pot" then
  if not blocked(tpos,"move") then
   trigger_trap(tx,ty)
   mset(tx,ty,201)
   del(items,get_item(tx,ty))
   success=true
  end
 elseif name=="hook" then
  --find the first thing in the direction.
  local hpos=tpos
  while true do
   local tile=mgetpos(hpos)
   local hx,hy=posxy(hpos)
   local item,mob=get_item(hx,hy),get_mob(hx,hy)

   if mob and mob.typ!=9 then
    --if mob, then yank it over
    --unless giant
    move_mob_pos(mob,tpos,false)
    mob.stun+=1
    break
   elseif item then
    local px,py=posxy(ppos)
    local pitem=get_item(px,py)
    local tx2,ty2=pitem and tx or px,pitem and ty or py
    item.xo,item.yo,
    item.x,item.y
    =
    (item.x-tx2)*8,(item.y-ty2)*8,
    tx2,ty2
    break
   elseif fget(tile,0) or (mob and mob.typ==9) then
    --if obstacle, get yanked to it
    if (mob) mob.stun+=1
    move_mob_pos(pc,hpos-dnbors[aim_dir],false)
    break
   end
   --keep checking
   hpos+=dnbors[aim_dir]
  end
  sfx(25,-1,0,min(16,flr(distance(ppos,hpos)))*2)
  success=true
 end
 
 if success then
  aim_item.qty-=1
  if aim_item.qty<=0 then
   del(inv,aim_item)
   inv_i=min(inv_i,#inv)
  end
  aim_item=nil
 else
  sfx"6"
 end
 
 return success and did_act
end

function aoestun(opos)
 foreach(omni_dnbors,function(d)
  local m=get_mob(posxy(opos+d))
  if (m) m.stun+=1
 end)
end

function loot_pot(x,y)
 if rnd()<0.07 then
  add_item(rnd(split"1,2,3,4,5,6,7,8,9"),1,x,y)
 elseif rnd()<0.05 then
  add_mob(rnd(split"2,4,5,6"),x,y).stun=1
 end
end

function loot_box_s(x,y)
 add_item(rnd(split"1,2,3,4,5,6,7,8,9,10"),1,x,y)
end

function loot_box_l(x,y)
 add_item(rnd(split"1,2,3,4,5,6,7,8,9,10"),2,x,y)
end

function loot_mob(m)
 local flritem=get_item(m.x,m.y)
 if m.soul then
  del(items,flritem)
  add_item(13,1,m.x,m.y)
 elseif not flritem 
   and rnd(100)<mob_loot_pct[m.typ] then
  add_item(rnd(mob_loot[m.typ]),1,m.x,m.y)
 end
end
-->8
--button tools

--call from _init()
function init_btns()
 --long hold duration threshold
 btnl_d,btn_t=20,{}
  
 for i=1,6 do 
  btn_t[i]={p=0,d=0} 
 end
end

--call from _update60()
function upd_btns()
 for i=0,5 do
  local b=btn_t[i+1]
  b.p=max(b.p-1,0)
  if (b.p==0) b.d=0
  if btn(i%6,i\6) then
   b.p=2
   b.d+=1
  end
 end
end

--released
function btnr(i)
 return btn_t[i+1].p==1
end

--short press
function btnps(i)
 local b=btn_t[i+1]
 return b.p==1 and b.d<=btnl_d
end

--long hold
function btnl(i)
 local b=btn_t[i+1]
 return b.p==2 and b.d>btnl_d
end
-->8
--mapgen

transt,stairb=
splitdict"floor:192,wall:143,door:203,up:206,down:207",
splitdict"124:t,179:t,214:t,233:t"

function new_floor()
 floor+=1
 
 pc.xo,pc.yo,
 ptcls,maps,fturn,mobs,traps
 =
  0,0,
  {},0,0,{pc},{}
 
 if floor==0 then
  --hub
	 for x=0,16 do
	  for y=0,16 do
	   mset(x,y,mget(x+17,y))
	  end
	 end
	 
	 pc.x,pc.y=8,12
 else
  --regular floor
  if (floor==1) gtime_start=t()
  local sane,tmap,imap,bmap,rmap,down_pos,px,py
   =false
  
  while not sane do
   tmap,imap,bmap,rmap,down_pos=map_gen(17,15,transt)
	  px,py=posxy(down_pos)
	
		 for pos=1,255 do
		  local x,y=posxy(pos)
		  mset(x,y,tmap[pos])
		 end
		 
		 sane=true
		 local reachable=get_dist_map(down_pos,"dmap",true,true)
		 for pos=1,255 do
		  if tmap[pos]!=143 and not reachable[pos] then
		   sane=false
		   break
		  end
		 end
  end

	 prettywalls()
	 
	 pc.x,pc.y=px,py
  p_dist_map=get_dist_map(mob_pos(pc))
  spawn_traps()
  spawn_mobs(rmap,down_pos)
  refresh_task_maps()
 end
 
 items,fov,fog,frame,is_p_turn=
  {},{},{},0,true
 update_fov()
 update_fog()
end
	
function map_gen(tw,th,transt)
	--[[
		tmap: tile map
	 imap: id map
	 bmap: 'bits' map
	 rmap: room (size) map
	]]--
 local cycle_pct,xtra_dr_pct,
  dr_rmv_pct,max_xtra_drs,max_wall_pct,
  nxt_id,merged_ids,stair_d,area,
  tmap,imap,bmap,rmap,down_pos,
  roomsizes,roomxs,roomys=
  0.05,0.05,
  0.4,1,0.66,
  1,{},0,tw*th,
  {},{},{},{},nil,
  split"3,3,5",split"1,3,5,7,9,11,13,15",split"1,3,5,7,9,11,13"
	
	function oob(x,y)
	 return x<0 or y<0 or x>tw-1 or y>th-1
	end
	
	function twall(pos)
	 return tmap[pos]=="wall"
	end
	
	function can_rm(x,y,rmw,rmh)
	 if (x+rmw>=tw or y+rmh>=th) return false
	 
	 for _x=x,x+rmw do
	  for _y=y,y+rmh do
	   if tmap[xypos(_x,_y)]!="wall" then
	    return false
	   end
	  end
	 end
	 
	 return true
	end
	
	function set_add(t,i)
	 for j in all(t) do
	  if (i==j) return t
	 end
	 add(t,i)
	 return t
	end
	
	function intersect(seta,setb)
	 local n=0
	 for a in all(seta) do
	  for b in all(setb) do
	   if (a==b) n+=1
	  end
	 end
	 return n
	end
	
	function walls()
	 local t={}
	 for i=1,tw*th do
	  if (twall(i)) add(t,i)
	 end
	 return shuf(t)
	end
	
	function do_dend(pos)
	 local nbwalls=0
	 for_nb(pos,function(nb)
	  if (twall(nb)) nbwalls+=1
	 end)
	 if twall(pos) or nbwalls<=2 then
	  return
	 end
	 	 
	 tmap[pos],imap[pos]="wall"
	 for_nb(pos,function(nb)
	  do_dend(nb)
	 end)
	end
	
	function for_nb(pos,fn)
	 for d in all(dnbors) do
	  fn(pos+d)
	 end
	end
	
	function stairs()
	 local s={}
	 for x=1,tw-2 do
	  for y=1,th-2 do
	   local pos=xypos(x,y)
	   local b=get_sig(pos,function(p)
	    return tmap[p]=="floor" and 0 or 1
	   end)
	   if stairb[b] then
	    add(s,pos)
	   end
   end
  end
  
  if #s>=2 then
   local maxd,spair=0
   for s1 in all(s) do
    for s2 in all(s) do
     local d=distance(s1,s2)
     if d>maxd then
      maxd,spair=d,{s1,s2}
     end
    end
   end
   
   local t=shuf(spair)
   tmap[spair[1]],tmap[spair[2]],down_pos,stair_d
   =
    "down","up",spair[1],maxd
  end
	end
	
	local try=0
 while true do
  for i=1,area do 
   tmap[i],bmap[i],rmap[i]="wall"
  end
  
  imap,nxt_id,merged_ids,stair_d=
   {},1,{},0

		--do rooms
	 for i=1,75 do --number of tries
	  local x,y,rmw,rmh=
	   rnd(roomxs),
	   rnd(roomys),
	   rnd(roomsizes),
	   rnd(roomsizes)
	  if can_rm(x,y,rmw,rmh) then
	   --do rm
			 for _x=x,x+rmw-1 do
			  for _y=y,y+rmh-1 do
			   local pos=xypos(_x,_y)
			   tmap[pos],rmap[pos],imap[pos]=
			    "floor",rmw*rmh,nxt_id
			  end
			 end
	   nxt_id+=1
	  end
	 end
	 
	 --do hallways
	 for x=1,tw,2 do
	  for y=1,th,2 do
	   if twall(xypos(x,y)) then
     --do hallway
     function do_hw(x1,y1)
					 local pos1,ds=
					  xypos(x1,y1),
					  {{1,0},{0,1},{-1,0},{0,-1}}
					  
					 for d in all(shuf(ds)) do
					  local x2,y2,x3,y3=
					   x1+d[1],y1+d[2],
					   x1+2*d[1],y1+2*d[2]
					  local pos2,pos3=
					   xypos(x2,y2),
					   xypos(x3,y3)
					  local can_cycle=
					   imap[pos3]==nxt_id
					    and tmap[pos2]!="floor"
					    and rnd()<cycle_pct
					  if twall(pos3)
					    and not oob(x3+1,y3+1) 
					    and not oob(x3-1,y3-1) 
					    or can_cycle then
					   for p in all({pos1,pos2,pos3}) do
					    tmap[p],imap[p]="floor",nxt_id
					   end
					   do_hw(x3,y3) 
					  end
					 end 
					end  
     do_hw(x,y)
     nxt_id+=1
    end
   end
  end

	 --do doors
	 local wls,xtra_drs=walls(),0
	 for pos in all(wls) do
	  local adj={}
	  for_nb(pos,function(nb)
	   if tmap[nb]=="floor" then
	    set_add(adj,imap[nb])
	   end
	  end)
	  
	  if #adj==2 then
	   local need_mrg,disjoint,can_xtra=
	    true,true,xtra_drs<max_xtra_drs and rnd()<xtra_dr_pct
	   
	   for merged in all(merged_ids) do
	    local isize=intersect(adj,merged)
	    
	    if (isize==2) need_mrg=false
	    if isize==1 then
	     disjoint=false
	     for a in all(adj) do
	      set_add(merged,a)
	     end
	    end
	   end
	   
	   if need_mrg then
	    tmap[pos]="door"
	    if (disjoint) add(merged_ids,adj)
	   elseif can_xtra then
	    tmap[pos]="door"
	    xtra_drs+=1
	   end
	  end
	 end

  --remove deadends
  for pos=1,area do 
	  do_dend(pos) 
	 end
  
  --cleanup doors
  for pos=1,area do
	  if tmap[pos]=="door" then
	   for_nb(pos,function(nb)
	    if (tmap[nb]=="door") tmap[nb]="wall"
	   end)
	  end
	 end
	 for pos=1,area do
	  if tmap[pos]=="door" then
	   if (rnd()<dr_rmv_pct) tmap[pos]="floor"
	  end
	 end
	 
  stairs()
  
  --bits
  for i=1,area do
	  local wall_ct,rm_flr_ct=0,0
	  for_nb(i,function(nb)
	   if (twall(nb)) wall_ct+=1
	  end)
	  for_nb(i,function(nb)
	   if (rmap[nb]) rm_flr_ct+=1
	  end)
	  
	  local b
	  if rmap[i] then
	   --in a room
	   if 4-wall_ct>rm_flr_ct then
	    b=wall_ct==2 and "hall" or "room_exit"
	   elseif wall_ct==0 then
	    b="room_mid"
	   else
	    b=wall_ct==2 and "room_corner" or "room_edge"
	   end
	  else
	   --not in a room
	   b=twall(i) and "wall" or "hall"
	  end
	  bmap[i]=b
	 end

  try+=1
  
  local good=#walls()<=area*max_wall_pct and stair_d>100
  if (good or (try>10 and stair_d>0)) break
 end
 
 --translate map
 for i=1,area do
  tmap[i]=transt[tmap[i]]
 end
 
 prefab(tw,th,tmap,imap,bmap,rmap)
 
 return tmap,imap,bmap,rmap,down_pos
end

function is_wall(t)
 return not t or (t>141 and t<190)
end

function prettywalls()
 local ntmap={} 
 for pos=1,255 do
  if is_wall(mgetpos(pos)) then
   local wall_sig=get_sig(pos,function(p)
    return is_wall(mgetpos(p)) and 1 or 0
   end)
   local sig_i=get_sig_i(wall_sig,wall_sigs,wall_msks)
   ntmap[pos]=143+sig_i
  end
 end
 for pos=1,255 do
  local x,y=posxy(pos)
  if (ntmap[pos]) mset(x,y,ntmap[pos])
 end
 --do 3d thing
 local wall3d_for_flr,flr_for_wall3d=splitdict"192:195,208:211,209:211,210:211,225:227,226:227,240:243,241:243,242:243",splitdict"195:192,211:210,227:226,243:242"
 for pos=19,237 do
  local tile,above=mgetpos(pos),mgetpos(pos-17)
  local wtile,ftile=wall3d_for_flr[tile],flr_for_wall3d[tile]
  local x,y=posxy(pos)
  if wtile and is_wall(above) then
   mset(x,y,wtile)
  elseif ftile and not is_wall(above) then
   mset(x,y,ftile)
  end  
 end
end

-->8
--prefab

function prefab(w,h,tmap,imap,bmap,rmap)
 local rms,area,pmap={},#tmap,{}
 
 for i=1,area do pmap[i]=i end
 shuf(pmap)
 
 function ytier(y)
  if (y<12) return 4
  if (y<21) return 3
  if (y<27) return 2
  return 1
 end
 
 --getting prefabs prepared
 local rms3x3,rms5x3,rms5x5=
  {{},{},{},{}},{{},{},{},{}},{}
 
 for my=0,27,3 do
  --3x3 rooms
  for mx=107,125,3 do
   local rm={}
   for yo=0,2 do
    for xo=0,2 do
     add(rm,mget(mx+xo,my+yo))
    end
   end
   add(rms3x3[ytier(my)],rm)
  end
  --5x3 rooms
  for mx=71,101,5 do
   local rm={}
   for yo=0,2 do
    for xo=0,4 do
     add(rm,mget(mx+xo,my+yo))
    end
   end
   add(rms5x3[ytier(my)],rm)
  end
 end
 --5x5 rooms
 for my=0,25,5 do
  for mx=50,65,5 do
   local rm={}
   for yo=0,4 do
    for xo=0,4 do
     add(rm,mget(mx+xo,my+yo))
    end
   end
   add(rms5x5,rm)
  end
 end
 
 function put_prfb(pos,prfb,rw,rh)
  local x,y=posxy(pos)
  local pi=1
  for yo=0,rh-1 do
   for xo=0,rw-1 do
    local npos=xypos(x+xo,y+yo)
    tmap[npos]=bmap[npos]=="room_exit" and 192 or prfb[pi]
    pi+=1
   end
  end
 end  
 
 function coinflip()
  return rnd()<0.5
 end
 
 function needs_rotate(rpos)
  --making assumption 5x3 room
  if (rmap[rpos]!=15) return false
  return imap[rpos]!=imap[rpos+3]
 end
 
 function get_tier()
  --todo: make this more balanced
  --based on what has already
  --been placed
  local r=rnd()
  if (r<0.05) return 1
  if (r<0.15) return 2
  if (r<0.60) return 3
  return 4 
 end
 
 function put_rms()
  local rms={}
  for pos=1,area do
   local id,rsize=imap[pos],rmap[pos]
   if id and rsize and not rms[id] then
    --assign top left corner of room
    rms[id]=pos 
   end
  end
  --we have all the top left
  --corners of each room. 
  --now shuffle, and then stamp
  --prefabs into each.
  shuf(rms)
  for rpos in all(rms) do
   local rsize=rmap[rpos]
   if rsize==9 then
    put_prfb(rpos,
     transform(
      rnd(rms3x3[get_tier()])),
     3,3)
   elseif rsize==15 then
    local rotate=needs_rotate(rpos)
    local rw=rotate and 3 or 5
    local rh=rotate and 5 or 3
    put_prfb(rpos,
     transform(
      rnd(rms5x3[get_tier()]),
      rotate),
     rw,rh)
   else
    put_prfb(rpos,
     transform(rnd(rms5x5)),
     5,5)
   end
  end
 end
 
 function transform(prfb,rotate,fliph,flipv)
  local rw=#prfb<15 and 3 or 5
  local rows,s={},0
  
  --slice the prefab into rows
  while s<#prfb do
   local row={}
   for i=1,rw do
    s+=1
    add(row,prfb[s])
   end
   add(rows,row)
  end
  
  if coinflip() then
   local nrows={}
   for i=1,#rows do
    local nrow={}
    for j=1,rw do
     nrow[j]=rows[i][rw-j+1]
    end
    add(nrows,nrow)
   end
   rows=nrows
  end
  
  if coinflip() then
   local nrows={}
   for i=1,#rows do
    nrows[i]=rows[#rows-i+1]
   end
   rows=nrows
  end
  
  --*this rotate also flips
  if rotate or coinflip() then
   local nrows={}
   for col=1,rw do
    local nrow={}
    for r=1,#rows do
     nrow[r]=rows[r][col]
    end
    add(nrows,nrow)
   end
   rows=nrows
  end
  
  local tprfb={}
  for row in all(rows) do
   for tile in all(row) do
    add(tprfb,tile)
   end
  end
  
  return tprfb
 end
 
 put_rms()
end
-->8
--traps

function get_trap(x,y)
 for trap in all(traps) do
  if trap.x==x and trap.y==y then 
   return trap
  end 
 end
end

function spawn_traps()
 for _x=1,17 do
  for _y=1,15 do
   if mget(_x,_y)==200 then
    add_trap(_x,_y)
   end
  end
 end
end

function add_trap(_x,_y)
 add(traps,{
  x=_x,y=_y,atk=2,anim=split"200,216,232,216"
 })
 mset(_x,_y,200)
end

function trigger_trap(x,y)
 local trap,mob=get_trap(x,y),get_mob(x,y)
 
 if trap then
  if mob then 
   hit_mob(trap,mob) 
  end
  del(traps,trap)
  mset(x,y,248)
 end
end
__gfx__
11111111111111111117161111111111111716111111111111111111111111111118881e1118881e111888111118881111188811111888111118881111188811
11111111111716111117777111171611111777711111111111ee8111111111111118e81e1118e81e1118e81e1118e81e1188e8111188e8111188eeee1188eeee
117117111117777111171711111777711117171111ee81111e18881111111111188881ee188881ee1888811e1888811e18888eee18888eee18888ee118888ee1
11177111171717111717777711771711117777771e188811181888111eee8881188188e1188188e1188181ee188181ee18818ee118818ee118818e1e18818e1e
1117711177177777771111111777777717711111e188888118888811e11888881188188111818881188818e1118188e111888e1e11818e1e11888eee11818eee
11711711777111117771771117711111177177118888888118888811888888881881111118188111188118811818888118811eee18188eee188111e1181881e1
111111111771771117717711117177111171771118888811118881111888888111881111188188111188111118818811118811e1188181e11188111118818811
11111111111717111111711111171711111171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111ee1ee111ee1ee111111111111118181111181811111818111118811111111111111111111118811111111111e11111111111111
188188111111111111111111e81118e1e88188e11ee1ee1111118881111188811111888118188e881811881118118811181888881e188811eee8881111188811
8e111e8118111811818881818811188188111881e88188e111818e8811818e8811818e881818888818188e881818888818188888eee78781ee1787811e878781
ee888ee1888888818888888181e1e18181e1e18188e1e88118818888188188881881888818888811188888881888888818888811ee188881e1818881eee88881
e18881e1888888818e181e8118888811188888111888881118881888188818111888181118888881188888811888888118888881e1818811e1881811ee188811
11181111181818111881881181888181818881818188818118888811188888881888881118888111188881111888811118888111e188188111888181e1818881
111111111111111111111111181118111811181118111811188188111881881118818888118188111181881111818811118188111188818111888881e1881881
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111188888811888888118888181
ee118888ee118888ee11888811111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
eee88ee8eee88ee8eee88ee8118811111111111111881111111111111111111111111111111111111111111111111111181e111111111111111111111181e111
18ee888818ee888818ee8888118188111188881111818811111111111111111111111111111111111111111111111111811888111181e1111181e11118118881
1881e8811881e8811881e88111188e8111818e8111188e8111111111111111111111111111111111111111111111111181888e81181188811811888118188888
18888888188888881888888818188881111888811118888111111111111111111111111111111111111111111111111188888881181888e81818888818888888
18811881188118881888188111888111188881111888811111111111111111111111111111111111111111111111111118888111188888881888888811888811
18881888188811111111188811881811118818111188181111111111111111111111111111111111111111111111111118181811118888811188888111818181
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1181e111111111111181e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
118888111181e1111188881111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
118e8e11118888111188881111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11888811118e8e111188881111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
18111181118888111811118111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11188811181888811118881111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11811811111881111181181111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111113133313111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111113331333111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111113133313111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111113331333111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111113333333333333111333333313333311333333113331333333333333111133333331111133333333111133311111333333311111
11111111111111111111111133333333333333313333333333333331333333313331333333333333111133333331111133333333111133311111333333311111
11111111111111111111111133333333333333313333333333313331333333313331133333333333111113333311111133333333111133311111133333311111
11111111111111111111111133311111111133313331111133313331111133313331111111111111111111111111111111111111111133311111111133311111
11111333333333333311111133311111111133313331133333313331331133313331133333111333331113333311133311111333331133313333333333311333
11113333333333333331111133311111111133313331333333313331333133313331333333313333333133333331333311113333333133313333333333313333
1111333ddddddddd3331111133311111111133313331333d33313331333133313331333d3331333d3331333d3331333d1111333d33313331dddddddd3331333d
11113331111111113331111133311111111133313331333133313331333133313331333133313331333133313331333111113331333133311111111133313331
11113331133333113331111133311111111133311333333333313333333333113331333333313331333133333331333333313333333111113331333133333333
11113331333333313331111133311111111133313333333333313333333333313331333333313331333133333331333333313333333111113331333133333333
11113331333333313331111133311111111133313333333333111333333333313311133333113331331113333311133333311333331111113311333133333333
11113331333133313331111133311111111133313331111111111111111133311111111111113331111111111111111133311111111111111111333111111111
11113331333333313331111133333333333333313333333333111333333333313333333333113331111113333311111133311111333333331111333133111111
11113331d33333d133311111d3333333333333d1d333333333313333333333d13333333333313331111133333331111133311111333333331111333133311111
111133311ddddd11333111111ddddddddddddd111ddddddd3331333ddddddd11dddddddd333133311111333d3331111133311111dddddddd1111333133311111
11113331111111113331111111111111111111111111111133313331111111111111111133313331111133313331111133311111111111111111333133311111
11113333333333333331111133333333333133313331333333313331333133311111333333311111111133331111111133313333333111111111111111111111
11113333333333333331111133333333333133313331333333313331333133311111333333311111111133331111111133313333333111111111111111111111
11111333333333333311111133333333333133313331133333313331331133311111133333111111111113331111111133111333331111111111111111111111
11111111111111111111111111111111333133313331111133313331111133311111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111133333333333133313333333333333331333333313311111111111333111113333311133311111111331111111111111111111111
1111111111111111111111113333333333313331d3333333d33333d1333333d13331111111113333111133333331333311111111333111111111111111111111
111111111111111111111111dddddddd333133311ddddddd1ddddd11dddddd11333111111111333d1111333d3331333d11111111333111111111111111111111
11111111111111111111111111111111333133311111111111111111111111113331111111113331111133313331333111111111333111111111111111111111
11111111ccccccccd1d11dd1ddd1ddd1000000000000000000000000000000001711171111aaa11111aaa1111aaaaa1111aaa11111111111111111a1ddddddd1
11111111cccccccc111111111111111100000000aaaaaaaa0000000000000000161116111a111a111a111a11a11111a1a1aaa1a11aaaaaa1111aa1a111111111
11111111ccccccccd11dd1d1d1ddd1d10000000077777777aaaaaaaa00000000616161611a111a111a111a1191999191a11111a11a1111a1aa1aa1a111111dd1
11111111cccccccc1111111111111111aaaaaaaa7777777777777777777777771111111111aaa11191aaa1a111999111a11a11a11a1aa1a1aa1aa11111dd1dd1
11111111cccccccc11111111111111110000000077777777aaaaaaaa000000001711171119119a1199119aa191999191aaa1aaa11aaaaaa1aa111191d1dd1dd1
11131111cccccccc111311111113111100000000aaaaaaaa000000000000000016111611199aaa11199aaa1111999111111111111111111111199191d1dd1dd1
11111111cccccccc11111111111111110000000000000000000000000000000061616161119991111199911191999191999999911999999199199191d1dd1dd1
11111111cccccccc1111111111111111000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111ddd1ddd1000a00000a777a0000a7a00000070000111111111113311111133111133333111111111111111111aaaaaaaa11111111
13131111111111111111111111111111000a00000a777a0000a7a00000070000171117111311131113111311311111313333333113333331aaaaaaaa11111111
113111111113131111111111d1ddd1d1000a00000a777a0000a7a000000700001611161113111311131113113111113131111131131111319111111911111111
11111111111131111111111111111111000a00000a777a0000a7a000000700001111111111111111311111311111111131111131131111311199191111111111
11113131111111111131311111113131000a00000a777a0000a7a000000700001111111113113311331133313111113133333331133333319111111911111111
31311311131311111113111131311311000a00000a777a0000a7a000000700001711171113313311133333111111111111111111111111119191991911111111
13111111113111111111111113111111000a00000a777a0000a7a000000700001611161111333111113331113111113133333331133333319111111911111111
11111111111111111111111111111111000a00000a777a0000a7a000000700001111111111111111111111111111111111111111111111119999999911111111
311131131111111111111111ddd1ddd11111111111111111111111111111111111111111000000000000000000000a00000000000000000000aaaa0000000000
13131131111113111111111111111111111111111111111111111111111111111111111100a00a000000a0000000a900000aa000000aa0000a1111a00a009a00
131311311131111113111131d1ddd1d1111111111111111111111111111111111711171100900900000aaa00000a900000000000009aaa0000aaaa000aa99aa0
113113111111311111111111111131111111111111111111111111111111111111111111191991910001aaa000aaa9000099aa0009999aa0091111900a191aa0
31131131311311311113111131131131111111111111111111111111111111111111111111a11a1100191a90000a900000991a00099119a0009999000aa19aa0
131313111313131111131311131313111111111111111111111111111111111111111111119119110191090000a9000009aaaaa0099119900a1111a00a191aa0
131313111311131113111111131113111111111111111111111111111111111117111711191991910910000000900000000990000000000000aaaa0000a990a0
11111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000
111111111111111111111111ddd1ddd10000011111100000000000001111111011111111111111111111111100000000000000000000aa000000110011111111
111111111111111111111111111111110000117117110000000000001777771011111111111aaaa1111aa11100aaa000009aa0a0000aa0000001dd1011111111
113133111131331111111111d1ddd1d1000117711771100000000000117771101311131111111aa11119aa110a111a0009111aa000aa9000001dd10011111111
1111331111113311111131111111111100017771177710000011100001171100111111111111a1a111919aa111aaa1111911aaa10aa9000001dd7d1011111111
133111111331111113311111133111110001177117711000011711000011100011111111119911a1119111a119119a11111111110a9a00001dd7ddd111111111
13313111133111111331111113311111000011711711000011777110000000001111111119991111191111a11999aa11119aa111099000001dd77dd111111111
1111111111111111111111111111111100000111111000001777771000000000131113111a9111111911111111999111119aa1110990000001d77d1011111111
11111111111111111111111111111111000000000000000011111110000000001111111111111111111111111111111111111111000000000011110011111111
__label__
mjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjaaajjjjjjjjjjjjjaaajjjmjmmmjmjjjaaajjjjjjjjjjjjjjjjjjjjjaaajjjmjmmmjmjmjmmmjmjmjmmmjmjjjaaajjjjjaaajjjjjaaajjjmjmmmjmj
jjjjjjjjjajjjajjjaaaaaajjajjjajjjjjjjjjjjajjjajjj333333j3333333jjajjjajjjjjjjjjjjjjjjjjjjjjjjjjjjajjjajjajaaajajjajjjajjjjjjjjjj
mmmjmmmjjajjjajjjajjjjajjajjjajjmmmjmmmjjajjjajjj3jjjj3j3jjjjj3jjajjjajjmmmjmmmjmmmjmmmjmmmjmmmjjajjjajjajjjjjajjajjjajjmmmjmmmj
jjjjjjjjjjaaajjjjajaajaj9jaaajajjjjjjjjj9jaaajajj3jjjj3j3jjjjj3jjjaaajjjjjjjjjjjjjjjjjjjjjjjjjjjjjaaajjjajjajjaj9jaaajajjjjjjjjj
mjmmmjmjj9jj9ajjjaaaaaaj99jj9aajmjmmmjmj99jj9aajj333333j3333333jj9jj9ajjmjmmmjmjmjmmmjmjmjmmmjmjj9jj9ajjaaajaaaj99jj9aajmjmmmjmj
jjjjjjjjj99aaajjjjjjjjjjj99aaajjjjjjjjjjj99aaajjjjjjjjjjjjjjjjjjj99aaajjjjjjjjjjjjjjjjjjjjjjjjjjj99aaajjjjjjjjjjj99aaajjjjjjjjjj
mmmjmmmjjj999jjjj999999jjj999jjjmmmjmmmjjj999jjjj333333j3333333jjj999jjjmmmjmmmjmmmjmmmjmmmjmmmjjj999jjj9999999jjj999jjjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjajaaajajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjajaaajajjjjjjjjjjjjjjjjjjjaaajjjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjajjjajjjjjjjjjj
mmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjj9j999j9jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj9j999j9jjjjjjjjjjjjjjjjjjajjjajjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj999jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj999jjjjjjjjjjjjjjjjjjjjjaaajjjjjjjjjjj
mjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjj9j999j9jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj9j999j9jjjjjjjjjjjjjjjjjj9jj9ajjmjmmmjmj
jjjjjjjjjjj3jjjjjjj3jjjjjjj3jjjjjj999jjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjjjj999jjjjjj3jjjjjjj3jjjjj99aaajjjjjjjjjj
mmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjj9j999j9jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj9j999j9jjjjjjjjjjjjjjjjjjj999jjjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjmjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjmjmmmjmjjjaaajjjjjjjjjjjjjaaajjjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjajjjajjjjjjjjjjjajjjajjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjmmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjmmmjmmmjjajjjajjjjjjjjjjjajjjajjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjaaajjjjjjjjjjj9jaaajajjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjmjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjmjmmmjmjj9jj9ajjjjjjjjjj99jj9aajmjmmmjmj
jjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjjjjjjjjjjj99aaajjjjj3jjjjj99aaajjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjmmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjmmmjmmmjjj999jjjjjjjjjjjjj999jjjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjjjjjjjjjaaaaaaaajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjajmjmmmjmjjjaaajjjjjjjjjjjjjjjjjjjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjaaaaaaaajjjjjjjjjjjjjjjjjjjjjjjjjjjaajajjjjjjjjjjajjjajjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjjj888jjjjjjjjjjj9jjjjjj9jjjjjjjjjjjjjjjjjjjjjjjjaajaajajmmmjmmmjjajjjajjjjjjjjjjjjjjjjjjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj8j888jjjjjjjjjjjj99j9jjjjjjjjjjjjjjjjjjjjjjjjjjaajaajjjjjjjjjjj9jaaajajjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmj8j88888jjjjjjjjj9jjjjjj9jjjjjjjjjjjjjjjjjjjjjjjjaajjjj9jmjmmmjmj99jj9aajjjjjjjjjjjjjjjjjmjmmmjmj
jjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjj8888888jjjj3jjjj9j9j99j9jjj3jjjjjjj3jjjjjjj3jjjjjjj99j9jjjjjjjjjj99aaajjjjj3jjjjjjj3jjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjj88888jjjjjjjjjj9jjjjjj9jjjjjjjjjjjjjjjjjjjjjjjj99j99j9jmmmjmmmjjj999jjjjjjjjjjjjjjjjjjjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj99999999jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjaaaaaajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjajjjjajmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjajaajajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjaaaaaajmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmj
jjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj999999jmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjaaajjjmjmmmjmjaaaaaaaamjmmmjmjmjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjj6j6jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjajaaajajjjjjjjjjaaaaaaaajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjjjj6666jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjajjjjjajmmmjmmmj9jjjjjj9mmmjmmmjmmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjj66j6jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjajjajjajjjjjjjjjjj99j9jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjj6666666jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjaaajaaajmjmmmjmj9jjjjjj9mjmmmjmjmjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmj
jjjjjjjjjjj3jjjjjjjjjjjjj66jjjjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjjjjjjjjjjjjjjjjjj9j9j99j9jjjjjjjjjjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjjj6j66jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj9999999jmmmjmmmj9jjjjjj9mmmjmmmjmmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjj6j6jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj99999999jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmj3j333j3jmjmmmjmjmjmmmjmjmjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmj3jjjjj3jmmmjmmmjmmmjmmmjmmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmj3jjjjj3jmjmmmjmjmjmmmjmjmjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmjmmmjmjmjmmmjmj
jjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmj3jjjjj3jmmmjmmmjmmmjmmmjmmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjmjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjmmmjmmmjjjjjjjjjjj888jjjjj888jjjjj888jjjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj8j888jjj8j888jjj8j888jjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjmjmmmjmjjjjjjjjj8j88888j8j88888j8j88888jmjmmmjmjmjmmmjmj
jjjjjjjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjjjjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3jjjj8888888j8888888j8888888jjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjmmmjmmmjjjjjjjjjj88888jjj88888jjj88888jjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj888jjjjj888jjjjj888jjjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj8j888jjj8j888jjj8j888jjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj8j88888j8j88888j8j88888jmjmmmjmjmjmmmjmj
jjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjj8888888j8888888j8888888jjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj88888jjj88888jjj88888jjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjajaaajajmjmmmjmjmjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmj9j999j9jmmmjmmmjmmmjmmmjjjjjjjjjjj888jjjjj888jjjjj888jjjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj999jjjjjjjjjjjjjjjjjjjjjjjjjjjj8j888jjj8j888jjj8j888jjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmj9j999j9jmjmmmjmjmjmmmjmjjjjjjjjj8j88888j8j88888j8j88888jmjmmmjmjmjmmmjmj
jjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjjjj999jjjjjjjjjjjjjjjjjjjjjj3jjjj8888888j8888888j8888888jjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmj9j999j9jmmmjmmmjmmmjmmmjjjjjjjjjj88888jjj88888jjj88888jjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjmjmmmjmjjjjjjjjjjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjaaaaaajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjjjjjjjjjmmmjmmmjjajjjjajjjjjjjjjmmmjmmmjmmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjajaajajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjmjmmmjmjjaaaaaajjjjjjjjjmjmmmjmjmjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmjmmmjmjmjmmmjmj
jjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjjjjj3jjjjjjjjjjjjjjjjjjjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjmmmjmmmjmmmjmmmjjjjjjjjjmmmjmmmjj999999jjjjjjjjjmmmjmmmjmmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmjmmmjmjjjaaajjjjjaaajjjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjajjjajjjajjjajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmmmjmmmjjajjjajjjajjjajjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjaaajjj9jaaajajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmjmmmjmjj9jj9ajj99jj9aajmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmj
jjjjjjjjjjj3jjjjjjj3jjjjjjj3jjjjjjj3jjjjjjjjjjjjj99aaajjj99aaajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjmmmjmmmjjj999jjjjj999jjjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmjmjmmmjmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
mmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmjmmmj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj

__gff__
0000000000030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050000000000000000000203030703030200000000000000000002000000000003000400000000000000020000000000000000000000000000000000000300000000
__map__
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d1d0c0d2c0c0e1e2c9cacaf2d0c0c0e1e0e0e0e0c1c0c0c0c0c0c0f2f2d2c0e2c0c0d1c0e2f2c0c0d2c0c0d2d2e2c0f1f2c0c0c0d2d2d1c0c1c0d2c0f1c0d1e2c0c0c0d2f2d0d2d2f2c0e1e2e1e0
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0f0f2f1c0e1e0f2e0e1d2d1d0d0d1f1e1e0e0e0c1d1d2c0f2c0d2f1f0f1c0e1e2c0c0c0e1e2f0f1c0d2e2e2e1e2c0f1f0f0f2c0c0d1d0d2c1c0c0d1c0f0c0e1e2c0c0f2f1d2d2d0f0f2e2e2c0c0
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0f1f0d0d2c0f1f0f1e2c0d1f0d1f1f0e2e1e1e0c1d0d1d2d2c0f2d1f2c0f2e0e1e2e2d2e0e0e1e2c0c0f2e1e1e2f1f2c0d2f2d2c0c0d2c0c1d1c0c0d2f1c0e0e1e2f2f1f0c0d1c0f1c0c0e0e1e2
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d1f1d1f1c0e2e0e1e0c0c0f2d2f1cac0f1d2e2e1c1d2d9c0c0c0e2f2c0c0d2e1c0e1c0c0c0c0f1f1c0c0d9d2c0d2d1c0c0c0f2c9c0c0c0d2c1e2c0c0c0c0f1c0c0d2d2d1d0c0c0c0e2e0e0c0c0c0
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0c0c0c0d2cae1c0c0c0c0c0cac9cad2d1c0f2e2c1c0f1f0d1f2e1e1f0f1c0d1f1d2e0e0c0f2c0d2c0d2c0d0d1c0c0c0d1f1dacad0f2c0c0c1c0c0e1f1c0c0d1c0daf2d2d1c0f2d9e0e1e2e2c0e1
00000000000000000000000000000000008f8f8f8f8f8f8f9091928f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0d2f1c0d2c0e1e1f1e1c0f2e2d2e0c9e0e1e2d2c1f2c0d2d9dae1e0e0e1e2e2e1e1e0e0d2c0d2d1d2d0d1dac0d2f2c0f1d9c9cad2d0c0d2c1e1e2c0d9f2c0d9c0d2c0c0d2f2d9dae1dae2c0c0e2
00000000000000000000000000000000008f8f8f8f909191a4cea39191928f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1caf0d1d0c0e2e1e0c9f2c0c0e2c8e1dae1c0f2f2c1c0c9cae2c0c0d2c0d1c0e1e2c0c0d2f2cac0c0e2e0e1e1c0f2d2f2f2cacad2e2c9cac9c1d2c0c0d2c0c0e2e2e1c0c0c0c0d1c0c0c0d2c0c0e2
00000000000000000000000000000000008f8f8f8fa0e0e3d3f2d3e3e0a28f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d2d28ed2f2c0c8c8c8c0c0d2c0e1c0d2c0f0c0e2c1e2c0d2f2c0d1c9cae2c0e2c0d0cac0d2c0f0f2c0f2f2d0caf1e1c0f1f1c9f2c0d2e2d1c1c0c0c9c0d1d0c9e1e0caf1c0cad2d0d0c0c0c9e2c0
00000000000000000000000000000000008f8f8f8fa0e1e1f1f2f1d0e0a28f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0f2f1cac0e2c0f1e0e1d1c8d2c0c0e1f1f0e2d9c1e0e1c0c9e2c0e2d1c0d2d2c9c0c0d1c9f0e2f1f2e1d1f1f1c0f2c0d2c0f2f1d1c0c0d2c1c0f2c9d2c9cae1cae0f2c0c0d0c0c0c9c0c0e1f2c0
00000000000000000000000000000000008f8f8f8fa0d0d2f1ccf1e1e1a28f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d2f1c9c0cac9c0c0e1c0d0d1c0f1c0f2c0c0c9cac1c0c0c0c0c0c9cac0e2e0f2c0c0d2d2c0c0f2cac0d0d2f2c0e1d2c9f2c9f1f2c0e2e1e1c1cac0d0cac0e2c0f2c0d2c0c0c0f2c0d1c0c0c0c9c9
00000000000000000000000000000000008f8f8f8fa0d9d1f1f0f1d2d9a28f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0e2d2f2c0c9e2e1e2e1e1e0e0f1e1caf2e1c0c0c1c9e2c0f1e2d9d9e2e0e0c0c9d2d1dad0c9d0f1d1f2c9c9f0e2c0c0cac0f0c9f0c0d2e2c1f2f1d1e2c0c0d9c0e2c0c0d1f1f0f2cad2c0d2c0d1
00000000000000000000000000000000008f8f8f8fa0dad9c0f0c0d9daa28f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1e0e1c8f1e0d0c9e1c0e28ec98ee2f1d1d0d0e1c1e0e1d2c9dad9e0d9e2e1d2d1f2dacaf2f0f1c0d2d2d9caf1c0e1d2c0f2d1cac9d1c0c0c1d2f2c0e1e2c0cae1f2e2c9daf2cad9cac9d2cad1d0
00000000000000000000000000000000008f8f8f8fb0b1b194db93b1b1b28f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d2e1e1d0f0e2e0e0e1cae0c9cac9e0c0d1cdd1f1c1c0d1d0d0d1f1d1c0c0f1e1d2e2c0e2e1e1e0f1f2c0c0c0c98ef2c9caf1c9e1e0d9c8dac1d2d2c0d2c0d2c9cacad1d0d2c0c0c0c8c0c8d0c0c0
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d1c8f0c8c0c0cae0e2d0f08ec98ee2c0f2d2f1cac1d2cad1d1c9c0cac9cad1e1e0e0e1d2f1e1e0e0e2c0c0d1c08ec9cac9cac9c8e1e1c0d1c1d0cad1c0d2d0d2cad1d0d0d1f2c8c0f2f0f1d2c8d0
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0d0c0c0c0c9d2e2c9e1f1e1e0e0e1c0c0d9c9cac1c0d2c0c0c9c0f1c0f1d2e0e0e1c0e1c0f0e0e0e2d2c0c0d08ecaf1c9cac9d2d9c8dac0c1c0d0c0d1d0d0c9d1c9d1d1d2f1f0f1c8f2c8c0c8c0
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c18ecad2da8ee2e1e0e0e1e2c0e1e0c0c0e1e1e2c0c1f2c9c0f2f2e1e08ed0dae1e0c9e0e1c0c0d2c0c0cad1d2c0c0e0e1e0e0e0d2f1f0f2c0c1c0c0c0f2f1f0d9dad2c0c0c0d1c0c0c0f0c8e0f1e2
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1f1d0f0f0cac0c9cad9e0c0c9e0e0e0f0d1e0e1d2c1f1caf0c9daf2e1f0e08ecae1e1e1e0f1ca8ed2d9d2c0c0c0d1e0e0e0e0e1f1c8c8c8d2c1c0c9f2c0f0f1d1d9c9d9f0f1c9c8c0c8f1c0e1c8c0
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1caf0cdf1caf18ecd8ee1e2e1e0e0cad0f18ec0c0c1c0f0f2f0d9d98ed1e2d2e2e0e0cad0d1d0f1d9da8e8e8e8e8ee1e0e0e1e0f2f1f0d1f0c1e1e2c0c0f2dad9d2d9f2f1f2cac9d2c0f2c8c0c8f2
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c9d1f2f2f1d0c8c8c8f1e1e0cde1e2c9f0f0d2e2c1d2e2e1e2d2e2e2f2c0d9e1e2e0e0e1c0d2d1d1c0ca8ee1e0e1f2e2e1e0e0d9c9f1dadac1f2f0c0c0e2e28e8e8ee0e0e0e2c0e2c0d2d1c0f1c9
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c18ed9caf08ed2f1f0d1c0e1d0e1c0d1cacdc9f2c0c1c0e18ee1e2e18edc8ed0d0e0c8c8e0d1d0d0d0d1c98ee08ee0d28e8e8ec8f2dac9d9cac1f1caf1e2e1e1c0c0c0e1e0e0e1c8c0c8c0c0c0c8f2
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1cacacac9cae0e0e1e1e2f2c0dad9d2c0d1c0e1e0c1e2e2e1d2c0d9e0e1d9dae2e1e1e0e2d2d1d1d2c0d0e0e08ecdc0f1c0d2d1d9f0d9d9f2c1c0f2f2e1e2e2d1d2c0e0e0e1e0e2e1d1d0c8e1c8c0
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c9c9c9cac9e1e0e0e1e0c0f0d1f2d9e2f1c8d1e1c1c0d9c0e1c0d9c8f1dac9c9f2e1dae1c0f1f0cad2e2e0cde0d1f2e2e1e0cacdf1c0c9d2c1d2f1c0e2e1e0e0cac9cacdc9f1caf2e0c8c0dac0d2
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1cac9cacac9e1e0e0e0e0d1f1f2f2f2f0c8ccc8e2c1c0e1f2f1cdf2f1f0cdf2cdf0d1e1e1f0c9cdc8c0e1e0e0e1d2d2f0e2c9cdc9f0d2f2c0c1c0cdf1e0cde1dacdcad0c0cacaf0d9f1cde1d0c0c9
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1cacac9c9c9e0e0e0e0e2f1f1f0f0d2c0d0c8e2c0c1f1c0c9cac9c9dac8d9d9cac9e2c0e2c9d2f1f2c9e2d1e1e2e1c0f2f1c8c9dacaf1c0c0c1f1d2c0e2e0e0c9c9e1c9d1c0cdc9c9c0c8e0cac0cd
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c9cac9cacae1e0e1e0e1dad1f1f2d9d2f2c0f0f2c1e2d2c9cdc9e2c0cacdcaf2d2cdc9f1cdcac9d2c0cdd9f2d0c9e1c0e2e1c8e2f0d1e1e1c1caf2c0cad2d1d2c0c0c9cdc9c0d1f2d1c0c8cdd2d0
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e0e0e1e1e2c9c9c9d9d9e0e0e1e0d2c0c0d2c0c0c1c0f2d1f0cac0e1e2e1e0c0c9f1f0d2c9f0c0c0d0daf1d1c0cac0d1c8cde1d2cd8ee0e1c1cdf0c0c0c0d2cac0d2e1c0e2f2cdc0c0cdd1cac0d1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e18e8e8ee2c9cdf2cdcae0e0e0e0e1c0d2f1f0d2c1c0f2f1d2f2e1e1e0e0e1f1f2d1c0c9c0c0f2c0d1d2c0d2d2f2e2c0d0c8e0c0e2e1e1e2c1c9f1c0cdc9c0cdc9d1e2c0c0c0f1d2c8c0d2c0d2c0
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c08ecc8ed0d9f0f0f1c9d1e0cce0e0d2f0ccf1e2c1e2e2f1c8c0dad9e2e2c9d2e2f1d1d9e0e0cae0e2e2e1e0e0e1e1d1d2f2d2e1e0c8e1e2c1c9c9caf1c0d0e1e0e0c8c0c8cac9c9d1d2d2c0e1d1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d08ecb8ed1cacdf1cdcae0e0e0e0e1c0f2f0f2c0c1c0f1ccd2c0c0c0cce1c9e28ecc8ec0e1d9cccae1e0e1ccc8e0e28ecc8ec9d18ecc8ed1c1f1ccf0d0ccd1e0cce0d1ccf1caccc0c0ccc0d0ccc0
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d1d2f0f1c0cadac9c9cae1e1e0e0e0e2c0c0e2c0c1e2c8d1f1f2d9e2c0c9cac0d1d0f2d2c0c9f1d9e2e0c8e0e1e0f2f1f0c9cacaf2f1d2c9c1d2f0c0d1f1c0e1e0e2c8f1c8c0c0f1d1c0f2e0e1d0
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
__sfx__
000100000613004100021000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000100000b1400b1300e0300d030016100c4000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
00010000167400c740107300075000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00010000160201a0301d04020050270502b00000000050001b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000026620247101f7102f7002f7001c700117001e7002072020710207101f7101b7001970017700087000e7000f7100f7100e7100e7100d71005700107000070000700007000070001700007000070000700
000600002661323600215202352025530295420060000600041000010000100031000610000100021000010001100001000110000100001000010000100001000010000100001000010000100001000010000100
000100000042000420004200042000420004000040017400114000d40000420004200042000420004200042000420004000040000400004000040000400004000740007400074000640005400004000040000400
0002000020130001000b1001e1301d13000100001001a13000100001002013000100001001e1301e1300010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000200002a63029630296000f600106000000000000000001f6201e6201d6000000000000000001c6001d6001862017610166000000025600256002660000000116000f6100f6002f60000000000000000005600
000100001b620201201a1301312015100131001310011100111000910007100051000310001100001000510004100041000310003100031000310003100021000210000100001000010000100001000010000100
0001000026130251202f1202a120241201e1202812039110011000110001100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000400002515025150001001f1501f150001001715017150001001215012150001000010005150041500415004150031500314002140021400113000130001200011000100001000010000100000000000000000
000100001d7401f74022730287102f730007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000500002b73028730247302873030730357403774000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000300001b5401b5501d55020000220000300014100091001e1000010000100001000e1000e1000e1000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000300002454000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003200003c7453c7003c7003c7003c7003c7003c7003c7053c7003c7003c7003c7003c7003c7003c7003c7003c7003c7003c7003c700000003c70000000000000000000000000000000000000000000000000000
000100000863038000006001560001600006000060000600006000550031640006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000900000c1101011013120181201a130181301c1401f140241400010000100001002615000100281502814028132281222811228112001000010000100001000010000100001000010000100001000010000100
0001000034050300402c0402903025030210201e0201b02019020160101401012010100100e0100d0100c0100a0100901008010070100601005010030100301002020020200302004020080200d0201203017040
0004000013522005021553200502175321e50219542195021b5421b5521b5521d5521d5521d5521f5521f5521f5521f55200502005022a5020050200502005023250200502005020050200502005020050200502
000200003c4503c450306002f6002f6003341031450254402c4402b4402b430004301d4202a4202541028410264002140020400004001c4000040020400204000e4001c4001a4000040000400004000040000400
00010000066500475005650057400663008630216301c62016720146100f7100d6100a7100861007620077200762013600126000f6000d6000c600086000c6000d60014600196000060000600006000060000600
00010000296501e650287572875728757287572875728747277472674725737247372373721737207371e7271c7271a7171771715717127170f7170c717097170871706717047170371702717017170071700707
000100000454004540055300a52010510185001150000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000200002c0131d0032c013180032c013140032c013100032c0131d0032c013180032c013140032c013100032c0131d0032c013180032c013140032c013100032c0131d0032c013180032c013140032c01310003
0001000014560145501454014540155401653018530195201a5101f5102351026510305100b1400b1300e0300d030016100050000500005000050000500005000050000500005000050000500005000050000000
010300000043000430000000000000000000000000000000000000000000000000000000000000000000043000000000000000000430004300043000000000000043000430000000000000000000000000000000
