pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
 frame=0
 btn_bfr=nil
 allow_input=true
 load_floor=false
 
 --colors used to provide fadeout effect
 fade_clrs={0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}
  
 --x and y deltas
 dxs,dys={-1,1,0,0,1,1,-1,-1},{0,0,-1,1,-1,1,1,-1}
 --neighbor deltas for 1d position
 --goes left right up down
 dnbors={-1,1,-17,17}
 shuf_dnbors={-1,1,-17,17} --use for shuffling.
 
 init_btns()
 start_game()
 
 --percentage of 'fadedness'
 fade_pct=1
 target_fade_pct=0
end

function _update60()
 upd_btns()
 --don't allow input while
 --screen is transitioning
 allow_input=fade_pct==0
 _upd_fn()
end

function _draw()
 camera(4,4)
 frame += 1
 fade_pct=approach(fade_pct,target_fade_pct,0.04)
 _draw_fn()
 draw_windows()
 set_fade(fade_pct,1)
 draw_dbgs()
end

function start_game()
 --delegates for update functions
 _upd_fn,_draw_fn=
  update_new_floor,draw_game
 
 mobs={}
 inv_i=0
 inv={}
 pc=add_mob(1,0,0)
 pc.vis=6
 inv={}
 floor=0
 
 toasts={}
 windows={}
 msg_window=nil
 item_window=nil
 hp_window=add_window(105,117,24,13,{},7)
 flr_window=add_window(70,117,35,13,{},7)
end



-->8
--updates

function update_game()
 local p_hp=pc.hp
 hp_window.txt={"♥"..p_hp}
 hp_window.clr=p_hp<4 and 8 or 7  
 
 flr_window.txt={"floor "..floor}
 
 if btn_bfr and p_hp>0 then
  handle_btn(btn_bfr)
  btn_bfr=nil
 elseif p_hp>0 then
  read_input()
 end
  
 if p_hp<=0 and pc.flash<=0 then
  fade_to(1,true)
  _upd_fn=update_gameover
  _draw_fn=draw_gameover
  return
 end
 
 --handle any mob deaths.
 for m in all(mobs) do
  if m.hp<=0 and m.flash<=0 then
   del(mobs, m)
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
   done=false
   m.xo=approach(m.xo,0,m.anim_spd)
   m.yo=approach(m.yo,0,m.anim_spd)
  end
 end
 
 --did everybody finish animating?
 if done then
  if load_floor then
   load_floor=false
   if floor==10 then --gameover
    fade_to(1,true)
    _upd_fn=update_gameover
    _draw_fn=draw_gameover
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
  if distance(fpos,tpos)<=dist then
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
 
 draw_items()
 draw_mobs()
 draw_fog()
 draw_toasts()
 draw_inv()
end

function draw_gameover()
 local msg=pc.hp>0 
  and "you win!! (🅾️ to restart)" 
  or "you died! (🅾️ to restart)"
 cls(1)
 print(msg,15,50,7)
end

function draw_mobs()
 for m in all(mobs) do
  local alive,flashing=m.hp>0,m.flash>0
  local clr = flashing and 7 or nil
  m.flash-=min(1,m.flash)
  
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

function draw_items()
 local yo={-1,-2,-1,0}
 for i in all(items) do
  local x,y=i.x*8,i.y*8
  spr(255,x,y)
  draw_sprite(
   i._spr,
   x,
   y+yo[flr(frame/15)%4+1],
   nil --color
  )
 end
end

function pal_dim()
 --alternate palette for dim look.
 pal(3,5)
 pal(9,4)
 pal(10,9)
 pal(13,5)
end

function draw_fog()
 pal_dim()
 
 for pos=1,256 do
  local x,y=pos_to_xy(pos)
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
   spr(194,x*8,y*8)
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
function show_timed_msg(msg, duration, clr)
 --calculate the required width, with some extra h-padding
 local w = (#msg+2)*4 + 7
 local window = add_window(
  63-w/2, --x
  56, --y
  w, --width
  13, --height
  {" "..msg}, --text
  clr --color
 )
 
 --we add a duration to the window
 --which we track every time windows are drawn
 window.dur = duration
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

function show_toast(_txt,_x,_y,_clr,center)
 local xo=center and -(#_txt*2)+4 or 0
 add(toasts,{
  txt=_txt,
  x=_x+xo,
  y=_y-5,
  yo=5,
  clr=_clr
 })
end

function draw_toasts()
 for t in all(toasts) do
  t.yo-=t.yo/15
  if t.yo<=1 then
   del(toasts,t)
  else
   print_outlined(t.txt,t.x,t.y+t.yo,t.clr,1)
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
 
 for i=1,#inv do
  local item,xo=inv[i],(i-1)*12+x
  if inv_i!=i then
   --dim unselected items
   pal(10,btn(❎) and 6 or 9)
   pal(9,btn(❎) and 5 or 4)
  end
  spr(item._spr,xo+3,y+2)
  if not btn(❎) then
   --print quantity by default
   print_outlined(item.qty,xo+11,y+8,7,1)
   --collapse existing item tips
   if (item_window) item_window.dur=0
  elseif inv_i==i then
   --for the selected item
   spr(254,xo+9,y+3)
   spr(254,xo-3,y+3,1,1,true)
   del(windows,item_window)
   item_window=add_window(x,y-14,64,13,{item.tip},7)  
  end
  pal()
 end
end
-->8
--misc

function approach(a, target, spd)
 return a<target and min(a+spd, target) or max(a-spd, target)
end


--is 'from' position adjacent
--to 'to' position, where each
--position is a 1d-pos.
--also checks for out of bounds.
function is_adj(fpos,tpos)
 local fx,fy=pos_to_xy(fpos)
 local tx,ty=pos_to_xy(tpos)
 local dx,dy=abs(fx-tx),abs(fy-ty)
 return 
  --didn't go oob horizontally
  abs(dx)<=1
  --didn't go oob vertically
  and abs(dy)<=1 
  and tpos>=1 
  and tpos<=289
--  --didn't go diagonally
--  and abs(dx+dy)<2
end

--[[
mode can be one of:
 "move": would this pos be movable to
]]--
function blocked(fpos,tpos,mode)
 local x,y=pos_to_xy(tpos)
 local tile=mget(x,y)
 
 if (not is_adj(fpos,tpos)) return true
 
 if mode=="move" then
  return fget(tile,0) 
    or get_mob(x,y)~=nil
 elseif mode=="move_thru_mobs" then
  return fget(tile,0)
 end
end


--shuffle a table via fisher-yates.
function shuf(t)
 for i=#t,1,-1 do
  local j = flr(rnd(i))+1
  t[i],t[j]=t[j],t[i]
 end
 return t
end

--return table indexed by 1d-pos
--where the valus indicate the
--walkable dist from original position
function get_dist_map(o_pos)
 local q,dmap,dist,i={o_pos},{},0,1

 while i<=#q do
  for _=i,#q do
   local pos=q[i]
   i+=1 
   if not dmap[pos] then
	   dmap[pos]=dist
	   for dnbor in all(dnbors) do
	    local nbor = pos+dnbor
	    if not dmap[nbor]
	      and not blocked(pos,nbor,"move_thru_mobs") 
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
function xy_to_pos(x,y)
 return x+y*17+1
end

--returns x,y (0 indexed)
--from pos (1 indexed)
function pos_to_xy(pos)
 return (pos-1)%17, flr((pos-1)/17)
end

--wait for a number of frames
function wait(_dur)
 for i=0,_dur do
  flip()
 end
end

--from position, to position.
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
 
 local fx,fy=pos_to_xy(fpos)
 local tx,ty=pos_to_xy(tpos)
 local dx,dy,sign_x,sign_y=
   abs(tx-fx),abs(ty-fy),
   sgn(tx-fx),sgn(ty-fy)
 local err=dx-dy
 
 while fx!=tx or fy!=ty do
  if fget(mget(fx,fy),2) then
   if retest then
    return false
   else
    return los(tpos,fpos,true)
   end
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
 local fx,fy=pos_to_xy(fpos)
 local tx,ty=pos_to_xy(tpos)
 local dx,dy=fx-tx,fy-ty
 return sqrt(dx*dx+dy*dy)
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

inv_open=false
function read_input()
 if (not allow_input) return
 --handle special inputs first
 if btnr(❎) then
  inv_open=false
 end
 if btn(❎) and inv_i>0 then
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
   msg_window.dur = 0
   msg_window = nil
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
  p_dist_map=get_dist_map(mob_pos(pc))
  update_fov()
  is_p_turn=#mobs==1
 end
 
 _upd_fn=update_anim
 update_fog()
end

-->8
--movement

function move_mob_pos(m,tpos)
 if (m.hp<=0) return false
 
 local tx,ty=pos_to_xy(tpos)
 return move_mob(m,tx-m.x,ty-m.y)
end

function move_mob(m,dx,dy)
 local dest_x, dest_y = m.x+dx, m.y+dy
 local fpos,tpos=xy_to_pos(m.x,m.y),xy_to_pos(dest_x,dest_y)
 local tile = mget(dest_x, dest_y)
 local did_act = false
 
 --handle orientation
 if (dx<0) m.flipped = true
 if (dx>0) m.flipped = false
 
 if blocked(fpos,tpos,"move") then
  --not walkable
  m.xo,m.yo,m.anim_spd=4*dx,4*dy,1
 else
  --walkable
  m.x+=dx
	 m.y+=dy
	 m.xo,m.yo,m.anim_spd=-8*dx,-8*dy,3
	 did_act = true
	 --player makes a walking sound.
	 if (m==pc) sfx(0)
 end
 
 --don't animate mobs out of sight
 if not fog[fpos] 
   and not fog[tpos] then
  m.xo,m.yo=0,0
 end

 did_act = handle_interact(m,tile,dest_x,dest_y) 
   or did_act
 
 return did_act
end

function handle_interact(mob,tile,x,y)
 local other,item=get_mob(x,y),get_item(x,y)

 if other 
   and mob!=other
   and (mob==pc or other==pc)
   then
  --handle combat
  hit_mob(mob,other)
  if mob==pc then
   sfx(9)
  elseif other==pc then
   sfx(10)
  end
  return true
 end
 
 if (mob!=pc) return false
 
 if item then
  pickup(item)
  return
 end
  
 if tile==202 or tile==201 then
  --vases
  mset(x, y, tile+16)
  sfx(4)
 elseif tile==203 then
  --doors
  mset(x, y, 219)
  sfx(1)
 elseif tile==204 or tile==205 then
  --chests
  mset(x, y, tile+16)
  add_item(ceil(rnd(2)),2,x,y)
  sfx(5)
 elseif tile==206 then
  --upstairs
  sfx(8)
  load_floor=true
 elseif tile==222 then
  --signs
  sfx(7)
  return false
 else
  return false
 end
 
 return true
end

-->8
--mobs

--[[
ideas

crab only goes left and right,
but has more health

slimes chase but sometimes
they move randomly

bats only move diagonally

snakes poison you, doubling
your damage taken

goblin is normal but
runs away when alone

hunter deals more damage
but will die easily

reapers move slowly but
can't be killed normally
and chases you through walls
dealing massive damage

cyclops moves slowly,
but has lots of health,
does lots of damage,
and blocks los

rats can multiply                           

the snitch always runs away
and drops an item when killed

the dragon charges a beam attack

the trex has high health and damage
--]]

--[[
the index is the mob type.
e.g, first entry of each these
tables is for the player (type 1).

mobs:
 1-player
 2-slime
--]] 

mob_hps={5,1}
mob_atks={1,1}
mob_anims={{1,2,3,4},{5,6,5,7}}

function spawn_mobs(rmap,down_pos)
 local pmap={}
 for p=1,255 do 
  if rmap[p] and distance(p,down_pos)>3 then
   add(pmap,p)
  end 
 end
 shuf(pmap)
 for n=1,8+floor do 
  while #pmap>0 do
  	local x,y=pos_to_xy(deli(pmap,#pmap))
  	local flag=fget(mget(x,y))
  	if flag==0 or flag==4 then
   	add_mob(2,x,y)
   	break
  	end
  end
 end
end

function add_mob(_typ,_x,_y)
 local m={
  typ=_typ,
  x=_x,
  y=_y,
  xo=0, --x offset, used for animation
  yo=0, --y offset, used for animation
  hp=mob_hps[_typ],
  atk=mob_atks[_typ],
  anim=mob_anims[_typ],
  anim_spd=0,
  flash=0,
  flipped=false,
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

function hit_mob(atkr,defr)
 local toast_clr = 10
 if (defr==pc) toast_clr=9
 
 defr.hp-=atkr.atk
 
 if defr.hp<=0 then
  defr.flash=12
  if defr==pc then
   sfx(11)
   defr.flash=64
  end
 else
  defr.flash=8
 end
 
 mob_say(defr,"-"..tostring(atkr.atk),toast_clr)
-- show_toast(
--  "-"..tostring(atkr.atk),
--  defr.x*8,
--  defr.y*8,
--  toast_clr --toast color
-- )
end

function mob_pos(m)
 return xy_to_pos(m.x,m.y)
end

function mob_say(mob,msg,clr)
 show_toast(
  msg,
  mob.x*8,
  mob.y*8,
  clr,
  true --center
 )
end
-->8
--ai

function update_ai()
 load_btn_bfr()
 
 for m in all(mobs) do
  if m.hp<=0 then
   --dead mobs can't act
  elseif m.typ==2 then --slimes
   --slimes will usually try
   --to chase the player if
   --they are close enough,
   --but sometimes move randomly
   local p_dist=p_dist_map[mob_pos(m)] or 999
   if p_dist>5 or rnd(100)<30 then
    ai_move_rnd(m)
   else
    ai_move_chase(m)
   end
  end
 end
 
 is_p_turn=true
end

--returns a random move that
--only checks for obstacles
function ai_move_rnd(m)
 local pos=mob_pos(m)
 
 shuf(shuf_dnbors)
 for dnbor in all(shuf_dnbors) do
  local tpos=pos+dnbor --'to' pos
  if not blocked(pos,tpos,"move_thru_mobs") then
   move_mob_pos(m,tpos)
   return
  end
 end
 
 --if no move was selected, still attempt to move
 move_mob_pos(m,pos+shuf_dnbors[1])
end

--returns the move that will
--bring this mob closest to 
--the player
function ai_move_chase(m)
 local pos,p_pos=mob_pos(m),mob_pos(pc)
 local cur_dist,min_dist,best=
   p_dist_map[pos],99,nil
 
 --use the player's dist map
 --to get closer to player
 for dnbor in all(dnbors) do
  local tpos=pos+dnbor
  local nxt_dist=p_dist_map[tpos]
  if nxt_dist and cur_dist 
    and nxt_dist<cur_dist then
   local tdist=distance(tpos,p_pos)
   if tdist<min_dist then
    best=tpos
    min_dist=tdist
   end
  end
 end
 
 if best then
  move_mob_pos(m,best)
 else
  --fallback is to move randomly
  ai_move_rnd(m)
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
 for i=1,289 do
  local x,y=pos_to_xy(i)
  if p_dist_map[i] then
    print(p_dist_map[i],x*8,y*8,11)
  end
 end
end
-->8
--items

item_names={"rice","bell"}
item_sprs={237,236}
item_tips={"recovers ♥","makes noise"}

function add_item(_id,_qty,_x,_y)
 local item
 
 item=add(items,{
  name=item_names[_id],
  _spr=item_sprs[_id],
  x=_x,
  y=_y,
  qty=_qty,
  tip=item_tips[_id]
 })
 
 mob_say(item,item.name,7)
end

function get_item(x,y)
 for i in all(items) do
  if i.x==x and i.y==y then
   return i
  end
 end
end

function pickup(item)
 if #inv>=4 then
  mob_say(pc,"full!",7)
 else
  for i=1,#inv+1 do
   if i==#inv+1 then
    add(inv,item)
   else
    local inv_item=inv[i]
    if inv_item.name==item.name then
     inv_item.qty+=item.qty
     break
    end
   end
  end

  del(items,item)
  sfx(12)
  
  if (inv_i<1) inv_i=1
 end
end

function use_item()
 if inv_i<1 then
  return false
 end
 
 local item=inv[inv_i]
 
 item.qty-=1
 
 if item.name=="rice" then
  pc.hp+=1
  mob_say(pc,"+1",11)
  sfx(13)
 elseif item.name=="bell" then
  mob_say(pc,"♪",7)
  sfx(16) 
 end
 
 if item.qty<=0 then
  del(inv,item)
  inv_i=min(inv_i,#inv)
 end
 
 return true
end
-->8
--button tools

--call from _init()
function init_btns()
 --long hold duration threshold
 btnl_d=20
 btn_t={} 
  
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

transt={
 floor=192,
 wall=193,
 door=203,
 up=206,
 down=207
}

function new_floor()
 local tmap,imap,bmap,rmap,down_pos=map_gen(17,15,transt)
 local px,py=pos_to_xy(down_pos)

 for pos=1,255 do
  local x,y=pos_to_xy(pos)
  mset(x,y,tmap[pos])
 end
 
 pc.x,pc.y,pc.xo,pc.yo=px,py,0,0
 p_dist_map=get_dist_map(mob_pos(pc))
 
 mobs={pc}
 spawn_mobs(rmap,down_pos)
 items={}
 fov={}
 fog={}
 frame=0
 update_fov()
 update_fog()
 floor+=1
 is_p_turn=true
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
  tmap,imap,bmap,rmap,down_pos=
  0.05,0.05,
  0.3,1,0.66,
  1,{},0,tw*th,
  {},{},{},{}
	
	function odd_int(n)
	 return flr(n+0.5) | 1
	end
	
	function oob(x,y)
	 return x<0 or y<0 or x>tw-1 or y>th-1
	end
	
	function gaus(mu,std)
	 local sum=0
	 for i=1,12 do sum+=rnd() end
	 return (sum-6)*std+mu
	end
	
	function twall(pos)
	 return tmap[pos]=="wall"
	end
	
	function can_rm(x,y,rmw,rmh)
	 if (oob(x,y) or rmw<2 or rmh<2) return false
	 if (x+rmw>=tw or y+rmh>=th) return false
	 
	 for _x=x,x+rmw do
	  for _y=y,y+rmh do
	   if tmap[xy_to_pos(_x,_y)]!="wall" then
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
	
	function intersect(ta,tb)
	 local n=0
	 for a in all(ta) do
	  for b in all(tb) do
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
	 for d in all{1,-1,tw,-tw} do
	  fn(pos+d)
	 end
	end
	
	function stairs()
	 local s={}
	 for x=1,tw-2 do
	  for y=1,th-2 do
	   local pos=xy_to_pos(x,y)
	   local b=bit360(pos)
   	if b==0b111000000
      or b==0b100100100
      or b==0b001001001
      or b==0b000000111 
      then
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
   tmap[spair[1]]="down"
   tmap[spair[2]]="up"
   down_pos=spair[1]
   stair_d=maxd
  end
	end
	
	function bit360(pos)
	 local n=0
	 for row in all({-tw,0,tw}) do
	  for col=-1,1 do
	   n=(n<<1)|(tmap[pos+row+col]=="floor" and 1 or 0)
	  end
	 end
	 return n
	end
	
	local try=0
 while true do
  for i=1,area do 
   tmap[i],bmap[i],rmap[i]="wall"
  end
  
  imap={}
  nxt_id=1
  merged_ids={}
  stair_d=0

		--do rooms
	 for i=1,75 do --number of tries
	  local x,y,rmw,rmh=
	   odd_int(rnd()*tw),
	   odd_int(rnd()*th),
	   odd_int(gaus(3,1)),
	   odd_int(gaus(3,1))  
	  if can_rm(x,y,rmw,rmh) then
	   --do rm
			 for _x=x,x+rmw-1 do
			  for _y=y,y+rmh-1 do
			   local pos=xy_to_pos(_x,_y)
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
	   if twall(xy_to_pos(x,y)) then
     --do hallway
     function do_hw(x1,y1)
					 local pos1,ds=
					  xy_to_pos(x1,y1),
					  {{1,0},{0,1},{-1,0},{0,-1}}
					  
					 for d in all(shuf(ds)) do
					  local x2,y2,x3,y3=
					   x1+d[1],y1+d[2],
					   x1+2*d[1],y1+2*d[2]
					  local pos2,pos3=
					   xy_to_pos(x2,y2),
					   xy_to_pos(x3,y3)
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
  local x,y=pos_to_xy(pos)
  local pi=1
  for yo=0,rh-1 do
   for xo=0,rw-1 do
    local npos=xy_to_pos(x+xo,y+yo)
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
  if (r<0.1) return 1
  if (r<0.25) return 2
  if (r<0.65) return 3
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
      rnd(rms3x3[get_tier()]),
      coinflip(),
      coinflip(),
      coinflip()),
     3,3)
   elseif rsize==15 then
    local rotate=needs_rotate(rpos)
    local rw=rotate and 3 or 5
    local rh=rotate and 5 or 3
    put_prfb(rpos,
     transform(
      rnd(rms5x3[get_tier()]),
      coinflip(),
      coinflip(),
      rotate),
     rw,rh)
   else
    put_prfb(rpos,
     transform(
      rnd(rms5x5),
      coinflip(),
      coinflip(),
      coinflip()),
     5,5)
   end
  end
 end
 
 function transform(prfb,fliph,flipv,rotate)
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
  
  if fliph then
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
  
  if flipv then
   local nrows={}
   for i=1,#rows do
    nrows[i]=rows[#rows-i+1]
   end
   rows=nrows
  end
  
  --*this rotate also flips
  if rotate then
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
__gfx__
11111111111111111117161111111111111716111111111111111111111111111118881811188818111888111118881111111111111111111111111111111111
11111111111716111117777111171611111777711111111111ee8111111111111118e8181118e8181118e8181118e81811111111111111111111111111111111
117117111117777111171711111777711117171111ee81111e188811111111111888818818888188188881181888811811111111111111111111111111111111
11177111171717111717777711771711117777771e188811181888111eee88811881888118818881188181881881818811111111111111111111111111111111
1117711177177777771111111777777717711111e188888118888811e11888881188188111818881188818811181888111111111111111111111111111111111
11711711777111117771771117711111177177118888888118888811888888881881111118188111188118811818888111111111111111111111111111111111
11111111177177111771771111717711117177111888881111888111188888811188111118818811118811111881881111111111111111111111111111111111
11111111111717111111711111171711111171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111ee118888ee118888ee118888111111111811111111111111111181811111818111118181
188188111111111111111111181e111111111111111111111181e111eee88ee8eee88ee8eee88ee8181888118888881111188811111188811111888111118881
8e111e811811181181888181811888111181e1111181e1111811888118ee888818ee888818ee8888888e8e81881e8e81188e8e8111818e8811818e8811818e88
ee888ee1888888818888888181888e811811888118118881181888881881e8811881e8811881e881881888818181888188888881188188881881888818818888
e18881e1888888818e181e8188888881181888e81818888818888888188888881888888818888888818188118188181188188811188818881888181118881811
11181111181818111881881118888111188888881888888811888811188118811881188818881881818818811188818181818881188888111888888818888811
11111111111111111111111118181811118888811188888111818181188818881888111111111888118881811188888181881881188188111881881118818888
11111111111111111111111111111111111111111111111111111111111111111111111111111111188888811888888118888181111111111111111111111111
1181e111111111111181e1111ee1ee111ee1ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
118888111181e11111888811e81118e1e88188e11ee1ee1111111111111111111111111111111111111111111111111111111111111111111111111111111111
118e8e1111888811118888118811188188111881e88188e111111111111111111111111111111111111111111111111111111111111111111111111111111111
11888811118e8e111188881181e1e18181e1e18188e1e88111111111111111111111111111111111111111111111111111111111111111111111111111111111
18111181118888111811118118888811188888111888881111111111111111111111111111111111111111111111111111111111111111111111111111111111
11188811181888811118881181888181818881818188818111111111111111111111111111111111111111111111111111111111111111111111111111111111
11811811111881111181181118111811181118111811181111111111111111111111111111111111111111111111111111111111111111111111111111111111
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
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111313331311111111111111111111111111111111111111111111111111711171111aaa11111aaa1111aaaaa1111aaa11111111111111111a133333331
1111111111111111111111111111111111111111111111111111111111111111161116111a111a111a111a11a11111a1a1aaa1a11aaaaaa1111aa1a111111111
1111111133313331111111111111111111111111111111111111111111111111616161611a111a111a111a1191999191a11111a11a1111a1aa1aa1a111111331
11111111111111111111111111111111111111111111111111111111111111111111111111aaa11191aaa1a111999111a11a11a11a1aa1a1aa1aa11111331331
11111111313331311111111111111111111111111111111111111111111111111711171119119a1199119aa191999191aaa1aaa11aaaaaa1aa11119131331331
111311111111111111111111111111111111111111111111111111111111111116111611199aaa11199aaa111199911111111111111111111119919131331331
11111111333133311111111111111111111111111111111111111111111111116161616111999111119991119199919199999991199999919919919131331331
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111113311111133111133333111111111111111111aaaaaaaa11111111
1313111111111111111111111111111111111111111111111111111111111111171117111311131113111311311111313333333113333331aaaaaaaa11111111
11311111111313111111111111111111111111111111111111111111111111111611161113111311131113113111113131111131131111319111111911111111
11111111111131111111111111111111111111111111111111111111111111111111111111111111311111311111111131111131131111311199191111111111
11113131111111111131311111111111111111111111111111111111111111111111111113113311331133313111113133333331133333319111111911111111
31311311131311111113111111111111111111111111111111111111111111111711171113313311133333111111111111111111111111119191991911111111
13111111113111111111111111111111111111111111111111111111111111111611161111333111113331113111113133333331133333319111111911111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111119999999911111111
31113113111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000011111111
131311311111131111111111111111111111111111111111111111111111111111111111111111111111111111111111000aa00000000000000aa00011111111
13131131113111111311113111111111111111111111111111111111111111111711171111111111111111111111111100000000000aa00000a11a0011111111
1131131111113111111111111111111111111111111111111111111111111111111111111111111111111111111111110099aa00009aaa00000aa00011111111
31131131311311311113111111111111111111111111111111111111111111111111111111111111111111111111111100991a0009999aa0009aaa0011111111
13131311131313111113131111111111111111111111111111111111111111111111111111111111111111111111111109aaaaa0099119a00099aa0011111111
13131311131113111311111111111111111111111111111111111111111111111711171111111111111111111111111100099000099119900009900011111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000011111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110011100011111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110017110011111111
11313311113133111111111111111111111111111111111111111111111111111311131111111111111111111111111111111111111111110017711011111111
11113311111133111111311111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110017771011111111
13311111133111111331111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110017711011111111
13313111133111111331111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110017110011111111
11111111111111111111111111111111111111111111111111111111111111111311131111111111111111111111111111111111111111110011100011111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000011111111
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000203030703030200000000000000000002000000000003000400000000000000020000000000000000000000000000000000000000000000
__map__
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fd1d0c0d2c0c0e1e2c9cacaf2d0c0c0e1e0e0e0e000c0c0c0c0c0c0f2f2d2c0e2c0c0d1c0e2f2c0c0d2c0c0d2d2e2c0f1f2c0c0c0d2d2d1c000c0d2c0f1c0d1e2c0c0c0d2f2d0d2d2f2c0e1e2e1e0
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fc0f0f2f1c0e1e0f2e0e1d2d1d0d0d1f1e1e0e0e000d1d2c0f2c0d2f1f0f1c0e1e2c0c0c0e1e2f0f1c0d2e2e2e1e2c0f1f0f0f2c0c0d1d0d200c0c0d1c0f0c0e1e2c0c0f2f1d2d2d0f0f2e2e2c0c0
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fc0f1f0d0d2c0f1f0f1e2c0d1f0d1f1f0e2e1e1e000d0d1d2d2c0f2d1f2c0f2e0e1e2e2d2e0e0e1e2c0c0f2e1e1e2f1f2c0d2f2d2c0c0d2c000d1c0c0d2f1c0e0e1e2f2f1f0c0d1c0f1c0c0e0e1e2
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fd1f1d1f1c0e2e0e1e0c0c0f2d2f1cac0f1d2e2e100d2d9c0c0c0e2f2c0c0d2e1c0e1c0c0c0c0f1f1c0c0d9d2c0d2d1c0c0c0f2c9c0c0c0d200e2c0c0c0c0f1c0c0d2d2d1d0c0c0c0e2e0e0c0c0c0
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fc0c0c0c0d2cae1c0c0c0c0c0cac9cad2d1c0f2e200c0f1f0d1f2e1e1f0f1c0d1f1d2e0e0c0f2c0d2c0d2c0d0d1c0c0c0d1f1dacad0f2c0c000c0c0e1f1c0c0d1c0daf2d2d1c0f2d9e0e1e2e2c0e1
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fc0d2f1c0d2c0e1e1f1e1c0f2e2d2e0c9e0e1e2d200f2c0d2d9dae1e0e0e1e2e2e1e1e0e0d2c0d2d1d2d0d1dac0d2f2c0f1d9c9cad2d0c0d200e1e2c0d9f2c0d9c0d2c0c0d2f2d9dae1dae2c0c0e2
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fcaf0d1d0c0e2e1e0c9f2c0c0e2c8e1dae1c0f2f200c0c9cae2c0c0d2c0d1c0e1e2c0c0d2f2cac0c0e2e0e1e1c0f2d2f2f2cacad2e2c9cac900d2c0c0d2c0c0e2e2e1c0c0c0c0d1c0c0c0d2c0c0e2
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fd2d2c1d2f2c0c8c8c8c0c0d2c0e1c0d2c0f0c0e200e2c0d2f2c0d1c9cae2c0e2c0d0cac0d2c0f0f2c0f2f2d0caf1e1c0f1f1c9f2c0d2e2d100c0c0c9c0d1d0c9e1e0caf1c0cad2d0d0c0c0c9e2c0
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fc0f2f1cac0e2c0f1e0e1d1c8d2c0c0e1f1f0e2d900e0e1c0c9e2c0e2d1c0d2d2c9c0c0d1c9f0e2f1f2e1d1f1f1c0f2c0d2c0f2f1d1c0c0d200c0f2c9d2c9cae1cae0f2c0c0d0c0c0c9c0c0e1f2c0
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fd2f1c9c0cac9c0c0e1c0d0d1c0f1c0f2c0c0c9ca00c0c0c0c0c0c9cac0e2e0f2c0c0d2d2c0c0f2cac0d0d2f2c0e1d2c9f2c9f1f2c0e2e1e100cac0d0cac0e2c0f2c0d2c0c0c0f2c0d1c0c0c0c9c9
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fc0e2d2f2c0c9e2e1e2e1e1e0e0f1e1caf2e1c0c000c9e2c0f1e2d9d9e2e0e0c0c9d2d1dad0c9d0f1d1f2c9c9f0e2c0c0cac0f0c9f0c0d2e200f2f1d1e2c0c0d9c0e2c0c0d1f1f0f2cad2c0d2c0d1
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fe1e0e1c8f1e0d0c9e1c0e2c1c9c1e2f1d1d0d0e100e0e1d2c9dad9e0d9e2e1d2d1f2dacaf2f0f1c0d2d2d9caf1c0e1d2c0f2d1cac9d1c0c000d2f2c0e1e2c0cae1f2e2c9daf2cad9cac9d2cad1d0
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fd2e1e1d0f0e2e0e0e1cae0c9cac9e0c0d1cdd1f100c0d1d0d0d1f1d1c0c0f1e1d2e2c0e2e1e1e0f1f2c0c0c0c9c1f2c9caf1c9e1e0d9c8da00d2d2c0d2c0d2c9cacad1d0d2c0c0c0c8c0c8d0c0c0
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fd1c8f0c8c0c0cae0e2d0f0c1c9c1e2c0f2d2f1ca00d2cad1d1c9c0cac9cad1e1e0e0e1d2f1e1e0e0e2c0c0d1c0c1c9cac9cac9c8e1e1c0d100d0cad1c0d2d0d2cad1d0d0d1f2c8c0f2f0f1d2c8d0
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fc0d0c0c0c0c9d2e2c9e1f1e1e0e0e1c0c0d9c9ca00c0d2c0c0c9c0f1c0f1d2e0e0e1c0e1c0f0e0e0e2d2c0c0d0c1caf1c9cac9d2d9c8dac000c0d0c0d1d0d0c9d1c9d1d1d2f1f0f1c8f2c8c0c8c0
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fc1cad2dac1e2e1e0e0e1e2c0e1e0c0c0e1e1e2c000f2c9c0f2f2e1e0c1d0dae1e0c9e0e1c0c0d2c0c0cad1d2c0c0e0e1e0e0e0d2f1f0f2c000c0c0c0f2f1f0d9dad2c0c0c0d1c0c0c0f0c8e0f1e2
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0ff1d0f0f0cac0c9cad9e0c0c9e0e0e0f0d1e0e1d200f1caf0c9daf2e1f0e0c1cae1e1e1e0f1cac1d2d9d2c0c0c0d1e0e0e0e0e1f1c8c8c8d200c0c9f2c0f0f1d1d9c9d9f0f1c9c8c0c8f1c0e1c8c0
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fcaf0cdf1caf1c1cdc1e1e2e1e0e0cad0f1c1c0c000c0f0f2f0d9d9c1d1e2d2e2e0e0cad0d1d0f1d9dac1c1c1c1c1e1e0e0e1e0f2f1f0d1f000e1e2c0c0f2dad9d2d9f2f1f2cac9d2c0f2c8c0c8f2
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fc9d1f2f2f1d0c8c8c8f1e1e0cde1e2c9f0f0d2e200d2e2e1e2d2e2e2f2c0d9e1e2e0e0e1c0d2d1d1c0cac1e1e0e1f2e2e1e0e0d9c9f1dada00f2f0c0c0e2e2c1c1c1e0e0e0e2c0e2c0d2d1c0f1c9
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fc1d9caf0c1d2f1f0d1c0e1d0e1c0d1cacdc9f2c000c0e1c1e1e2e1c1dcc1d0d0e0c8c8e0d1d0d0d0d1c9c1e0c1e0d2c1c1c1c8f2dac9d9ca00f1caf1e2e1e1c0c0c0e1e0e0e1c8c0c8c0c0c0c8f2
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fcacacac9cae0e0e1e1e2f2c0dad9d2c0d1c0e1e000e2e2e1d2c0d9e0e1d9dae2e1e1e0e2d2d1d1d2c0d0e0e0c1cdc0f1c0d2d1d9f0d9d9f200c0f2f2e1e2e2d1d2c0e0e0e1e0e2e1d1d0c8e1c8c0
ffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fc9c9c9cac9e1e0e0e1e0c0f0d1f2d9e2f1c8d1e100c0d9c0e1c0d9c8f1dac9c9f2e1dae1c0f1f0cad2e2e0cde0d1f2e2e1e0cacdf1c0c9d200d2f1c0e2e1e0e0cac9cacdc9f1caf2e0c8c0dac0d2
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cac9cacac9e1e0e0e0e0d1f1f2f2f2f0c8ccc8e200c0e1f2f1cdf2f1f0cdf2cdf0d1e1e1f0c9cdc8c0e1e0e0e1d2d2f0e2c9cdc9f0d2f2c000c0cdf1e0cde1dacdcad0c0cacaf0d9f1cde1d0c0c9
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cacac9c9c9e0e0e0e0e2f1f1f0f0d2c0d0c8e2c000f1c0c9cac9c9dac8d9d9cac9e2c0e2c9d2f1f2c9e2d1e1e2e1c0f2f1c8c9dacaf1c0c000f1d2c0e2e0e0c9c9e1c9d1c0cdc9c9c0c8e0cac0cd
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c9cac9cacae1e0e1e0e1dad1f1f2d9d2f2c0f0f200e2d2c9cdc9e2c0cacdcaf2d2cdc9f1cdcac9d2c0cdd9f2d0c9e1c0e2e1c8e2f0d1e1e100caf2c0cad2d1d2c0c0c9cdc9c0d1f2d1c0c8cdd2d0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e0e0e1e1e2c9c9c9d9d9e0e0e1e0d2c0c0d2c0c000c0f2d1f0cac0e1e2e1e0c0c9f1f0d2c9f0c0c0d0daf1d1c0cac0d1c8cde1d2cdc1e0e100cdf0c0c0c0d2cac0d2e1c0e2f2cdc0c0cdd1cac0d1
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e1c1c1c1e2c9cdf2cdcae0e0e0e0e1c0d2f1f0d200c0f2f1d2f2e1e1e0e0e1f1f2d1c0c9c0c0f2c0d1d2c0d2d2f2e2c0d0c8e0c0e2e1e1e200c9f1c0cdc9c0cdc9d1e2c0c0c0f1d2c8c0d2c0d2c0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c1ccc1d0d9f0f0f1c9d1e0cce0e0d2f0ccf1e200e2e2f1c8c0dad9e2e2c9d2e2f1d1d9e0e0cae0e2e2e1e0e0e1e1d1d2f2d2e1e0c8e1e200c9c9caf1c0d0e1e0e0c8c0c8cac9c9d1d2d2c0e1d1
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0c1cbc1d1cacdf1cdcae0e0e0e0e1c0f2f0f2c000c0f1ccd2c0c0c0cce1c9e2c1ccc1c0e1d9cccae1e0e1ccc8e0e2c1ccc1c9d1c1ccc1d100f1ccf0d0ccd1e0cce0d1ccf1caccc0c0ccc0d0ccc0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d2f0f1c0cadac9c9cae1e1e0e0e0e2c0c0e2c000e2c8d1f1f2d9e2c0c9cac0d1d0f2d2c0c9f1d9e2e0c8e0e1e0f2f1f0c9cacaf2f1d2c900d2f0c0d1f1c0e1e0e2c8f1c8c0c0f1d1c0f2e0e1d0
__sfx__
000100000612004000026000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000b1400b1300e0300d030016100c4000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
00010000167400c740107300075000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00010000160201a0301d04020050270502b00000000050001b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000026620247101f7102f7002f7001c700117001e7002072020710207101f7101b7001970017700087000e7000f7100f7100e7100e7100d71005700107000070000700007000070001700007000070000700
000600002661023600215202352025530295400060000600041000010000100031000610000100021000010001100001000110000100001000010000100001000010000100001000010000100001000010000100
000100000042000420004200042000420004000040017400114000d40000420004200042000420004200042000420004000040000400004000040000400004000740007400074000640005400004000040000400
0002000020130001000b1001e1301d13000100001001a13000100001002013000100001001e1301e1300010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000200002a63029630296000f600106000000000000000001f6201e6201d6000000000000000001c6001d6001862017610166000000025600256002660000000116000f6100f6002f60000000000000000005600
000100001b620201201a1301312015100131001310011100111000910007100051000310001100001000510004100041000310003100031000310003100021000210000100001000010000100001000010000100
0001000026130251202f1202a120241201e1202812039110011000110001100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000400002515025150001001f1501f150001001715017150001001215012150001000010005150041500415004150031500314002140021400113000130001200011000100001000010000100000000000000000
000100001d7401f74022730287102f730007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000500002b73028730247302873030730077000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000300001b5401b5501d55020000220000300014100091001e1000010000100001000e1000e1000e1000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000300002454000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500003c7603c7303c7203c7103c7103c7103c7103c7103c7103c7103c7103c7003c7003c7003c7003c7003c7003c7003c7003c700000003c70000000000000000000000000000000000000000000000000000
