pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
 frame = 0
 btn_bfr = nil
 allow_input=true
 
 --colors used to provide fadeout effect
 fade_clrs={0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}
  
 --x and y deltas
 dxs,dys={-1,1,0,0,1,1,-1,-1},{0,0,-1,1,-1,1,1,-1}
 --neighbor deltas for 1d position
 --goes left right up down
 dnbors={-1,1,-16,16}
 shuf_dnbors={-1,1,-16,16} --use for shuffling.
 
 start_game()
end

function _update60()
 --don't allow input while
 --screen is transitioning
 allow_input=fade_pct==0
 _upd_fn()
end

function _draw()
 frame += 1
 _draw_fn()
 draw_windows()
 set_fade()
end

function start_game()
 --reset the map
 --useful until procedural generation
 reload(0x1000, 0x1000, 0x2000)

 --percentage of 'fadedness'
 fade_pct=1 

 --delegates for update functions
 _upd_fn, _draw_fn = update_game, draw_game
 
 mobs={}
 player=add_mob(1,3,7)
 player.sight=6
 is_p_turn=true
 
 --temporary convenience
 --for adding mobs via map
 for x=0,15 do
  for y=0,15 do
   local tile=mget(x,y)   
   if tile==5 then
    add_mob(2,x,y)
    mset(x,y,192)
   end
  end
 end
 
 p_dist_map=get_dist_map(mob_pos(player))
 p_fov=get_fov(player)
 fog=get_fov(player)
 
 toasts={}
 windows={}
 msg_window=nil
 hp_window=add_window(101,112,24,13,"",7)
end



-->8
--updates

function update_game()
 load_btn_bfr()
 hp_window.txt={"♥"..player.hp}
 
 if btn_bfr and player.hp>0 then
  handle_btn(btn_bfr)
  btn_bfr = nil
 end
 
 if player.hp<=0 and player.flash<=0 then
  fade_to(1)
  windows={}
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
  if is_p_turn then
   is_p_turn=false
   update_ai()
  else
   is_p_turn=true
  _upd_fn=update_game
  end
 else
  _upd_fn=update_anim
 end
end

function update_fog()
 for i=1,256 do
  fog[i]=fog[i] or p_fov[i]
 end
end

function update_gameover()
 fade_to(0)
 
 if btnp(🅾️) then
  fade_to(1)
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

 draw_mobs()
 draw_toasts()
 draw_fog()
 
 fade_to(0)
end

function draw_gameover()
 cls(1)
 print(
  "you died! (🅾️ to restart)",
  15, --x
  50, --y
  7 --color
 )
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

function draw_fog()
 for pos=1,256 do
  local x,y=pos_to_xy(pos)
  if fog[pos] then 
   --uncovered
   if not p_fov[pos] then
    --not currently in sight
    pal(3,5)
    pal(9,4)
    pal(10,9)
    pal(13,5)
    spr(mget(x,y),x*8,y*8)
    pal()
   end
  else
   --covered
   spr(208,x*8,y*8)
  end
 end
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

function approach(a, target, spd)
 return a<target and min(a+spd, target) or max(a-spd, target)
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
  
  clip(wx, wy, ww-8, wh-8)
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
  16, --x
  50, --y
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

function show_toast(_txt,_x,_y,_clr)
 add(toasts,{
  txt=_txt,
  x=_x,
  y=_y-5,
  yo=5,
  clr=_clr
 })
end

function draw_toasts()
 for t in all(toasts) do
  t.yo-=t.yo/10
  if t.yo<=1 then
   del(toasts,t)
  else
   print_outlined(t.txt,t.x,t.y+t.yo,t.clr,0)
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

--requires fade_clrs, and fade_pct
--fade_pct 0 is no fade, 1 is max (blackout)
function fade_to(pct)
 --this is where the speed of the fade
 --can be set.
 while fade_pct!=pct do
  fade_pct=approach(fade_pct,pct,0.04)
  set_fade(fade_pct,1)
  flip()
 end
end
-->8
--misc

--is 'from' position adjacent
--to 'to' position, where each
--position is a 1d-pos.
function is_adj(fpos,tpos)
 local fx,fy=pos_to_xy(fpos)
 local tx,ty=pos_to_xy(tpos)
 local dx,dy=abs(fx-tx),abs(fy-ty)
 return abs(dx)<=1 --didn't go oob horizontally
  and abs(dy)<=1 --didn't go oob vertically
  and abs(dx+dy)<2 --didn't go diagonally
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
function shuffle(t)
 for i=#t,1,-1 do
  local j = flr(rnd(i))+1
  t[i],t[j]=t[j],t[i]
 end
end

--return table indexed by 1d-pos
--where the valus indicate the
--walkable dist from original position
function get_dist_map(o_pos)
 local q,dmap,dist={o_pos},{},0
 
 while #q>0 do
  for i=1,#q do
   local pos=deli(q,1)
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
  dist+=1
 end
 
 return dmap
end

--convert x and y to 1d-pos
function xy_to_pos(x,y)
 return x+y*16+1
end

--returns x,y (0 indexed)
--from pos (1 indexed)
function pos_to_xy(pos)
 return (pos-1)%16, flr((pos-1)/16)
end

--for debugging
function logd(msg)
 show_timed_msg(msg,60,11)
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
  
  --e2 and err are somewhat
  --mysterious. i'm not good
  --enough at math to properly
  --explain what it does. but
  --if you increase the factor
  --you multiply err by,
  --the distance that corners are
  --fixed increases too, seemingly
  --linearly. thus i have chosen
  --the theoretical furthest
  --a corner could be from the player, 16
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

function get_fov(mob)
 local fpos,dist=mob_pos(mob),mob.sight
 local fmap={}

 for tpos=1,256 do
  if not fmap[tpos] 
    and (distance(fpos,tpos)<=dist) 
    then
   fmap[tpos]=los(tpos,fpos)
  end
 end
 
 return fmap
end
 


-->8
--input

function load_btn_bfr()
 if (not allow_input) return
 for i=0, 5 do
  if btnp(i) then
   btn_bfr = i
   return
  end
 end
end

function handle_btn(_btn)
 if (not _btn) return
 
 if msg_window then
  if _btn>3 then
   msg_window.dur = 0
   msg_window = nil
  end
 elseif _btn<4 then  
  if move_mob(
     player,
     dxs[_btn+1],
     dys[_btn+1]
    ) then
   p_dist_map=get_dist_map(mob_pos(player))
   p_fov=get_fov(player)
   update_fog()
  end
  
  _upd_fn=update_anim
 end
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
	 m.xo,m.yo,m.anim_spd=-8*dx,-8*dy,2
	 did_act = true
	 --player makes a walking sound.
	 if (m==player) sfx(0)
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
 local other=get_mob(x,y)

 if other 
   and mob!=other
   and (mob==player or other==player)
   then
  --handle combat
  hit_mob(mob,other)
  sfx(9)
  return true
 end
 
 if (mob!=player) return false
  
 if tile==202 or tile==201 then
  --vases
  mset(x, y, 192)
  sfx(4)
 elseif tile==203 then
  --doors
  mset(x, y, 219)
  sfx(1)
 elseif tile==204 or tile==205 then
  --chests
  mset(x, y, tile+16)
  sfx(5)
 elseif tile==206 then
  --upstairs
  sfx(8)
 elseif tile==222 then
  --signs
  if x==6 and y==5 then
   show_msg({
    " welcome to yggdrasil",
    ""
    ,"ascend the sacred tree"
    ,"  and find salvation",
    "",
    "  ...just kidding"},
    10 --color
   )
  elseif x==10 and y==7 then
   show_timed_msg(
    "i will disappear...",
    60, --duration
    10 --color
   )
  end
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
the index is the mob type.
e.g, first entry of each these
tables is for the player (type 1).

mobs:
 1-player
 2-slime
--]] 

mob_hps={99,1}
mob_atks={1,1}
mob_anims={{1,2,3,4},{5,6,5,7}}

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
 if (defr==player) toast_clr=9
 
 defr.hp-=atkr.atk
 
 if defr.hp<=0 then
  defr.flash=12
  if defr==player then
   sfx(11)
   defr.flash=64
  end
 else
  defr.flash=8
 end
 
 show_toast(
  "-"..tostring(atkr.atk),
  defr.x*8,
  defr.y*8,
  toast_clr --toast color
 )
end

function mob_pos(m)
 return xy_to_pos(m.x,m.y)
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
end

--returns a random move that
--only checks for obstacles
function ai_move_rnd(m)
 local pos=mob_pos(m)
 
 shuffle(shuf_dnbors)
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
 local pos=mob_pos(m)
 local cur_dist=p_dist_map[pos]
 
 --use the player's dist map
 --to get closer to player
 for dnbor in all(dnbors) do
  local tpos=pos+dnbor
  local nxt_dist=p_dist_map[tpos]
  if nxt_dist 
    and cur_dist 
    and nxt_dist<cur_dist then
   move_mob_pos(m,tpos)
   return
  end
 end
 
 --fallback is to move randomly
 ai_move_rnd(m)
end
__gfx__
11111111111111111117161111111111111716111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111716111117777111171611111777711111111111ee8111111111111111111111111111111111111111111111111111111111111111111111111111
117117111117777111171711111777711117171111ee81111e188811111111111111111111111111111111111111111111111111111111111111111111111111
11177111171717111717777711771711117777771e188811181888111eee88811111111111111111111111111111111111111111111111111111111111111111
1117711177177777771111111777777717711111e188888118888811e11888881111111111111111111111111111111111111111111111111111111111111111
11711711777111117771771117711111177177118888888118888811888888881111111111111111111111111111111111111111111111111111111111111111
11111111177177111771771111717711117177111888881111888111188888811111111111111111111111111111111111111111111111111111111111111111
11111111111717111111711111171711111171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
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
11111111117171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111117777111171711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111117171111177771111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111117777111171711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111171111711177771111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111777111717777111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111117117111171171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
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
11111111313331311111111111111111111111111111111111111111111111111111111111aaa11111aaa1111aaaaa1111aaa11111111111111111a133333331
1111111111111111111111111111111111111111111111111111111111111111111111111a111a111a111a11a11111a1a1aaa1a11aaaaaa1111aa1a111111111
1111111133313331111111111111111111111111111111111111111111111111111111111a111a111a111a1191999191a11111a11a1111a1aa1aa1a111111331
11111111111111111111111111111111111111111111111111111111111111111111111111aaa11191aaa1a111999111a11a11a11a1aa1a1aa1aa11111331331
11111111313331311111111111111111111111111111111111111111111111111111111119119a1199119aa191999191aaa1aaa11aaaaaa1aa11119131331331
111311111111111111111111111111111111111111111111111111111111111111111111199aaa11199aaa111199911111111111111111111119919131331331
11111111333133311111111111111111111111111111111111111111111111111111111111999111119991119199919199999991199999919919919131331331
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111133333111111111111111111aaaaaaaa11111111
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111311111313333333113333331aaaaaaaa11111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111113111113131111131131111319111111911111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111131111131131111311199191111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111113111113133333331133333319111111911111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111119191991911111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111113111113133333331133333319111111911111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111119999999911111111
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000003030703030200000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000
__map__
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c9cdcac1cadddcc9c1c1c1c9cccac100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c0c0c0cbc0c0c0c0c0c0cbc005c9c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c0c1c1c1c0c1c1c0c1c1c1c9c0cac100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c0c1c105c0dec0c0c0cec1cac0c0c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c0c1c1c0c0c0c0cdc1c1c1c1c0c1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c0c1cfc0c0c0c0ccc1dec1c1c0c1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c0c1c1c1c1dbc1c1c1c0c0c0c0c1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c0c0c0c0c1c0c1c1c1c005c0c0c1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c0c1c1c0c0c0c0c0c0c0c0c005c1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c0c1c1c0c1c1cbc1c1c0c0c0c0c1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c0c1c1c0c1cdc0c1c1c0c005c0c1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c0c0c005c1c9cac1c1c1c1c1c1c1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000612004000026000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000b1400b1300e0300d030016100c4000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
00010000167400c740107300075000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00010000160201a0301d04020050270502b00000000050001b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000026620247101f7102f7002f7001c700117001e7002072020710207101f7101b7001970017700087000e7000f7100f7100e7100e7100d71005700107000070000700007000070001700007000070000700
000600002661023600215202352025530295400060000600041000010000100031000610000100021000010001100001000110000100001000010000100001000010000100001000010000100001000010000100
000100000042000420004200042000420004200042017400114000d4000c400004200042000420004200042000420004200042000400004000040000400004000740007400074000640005400004000040000400
0002000020130001000b1001e1301d13000100001001a13000100001002013000100001001e1301e1300010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000200002a63029630296000f600106000000000000000001f6201e6201d6000000000000000001c6001d6001862017610166000000025600256002660000000116000f6100f6002f60000000000000000005600
000100001b620201201a1301312015100131001310011100111000910007100051000310001100001000510004100041000310003100031000310003100021000210000100001000010000100001000010000100
0001000026460254202f4302a430244301e4302842039410014000140001400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
000400002515025150001001f1501f150001001715017150001001215012150001000010005150041500415004150031500314002140021400113000130001200011000100001000010000100000000000000000
