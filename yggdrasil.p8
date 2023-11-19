pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--yggdrasil
--by helloworldramen

--[[
data
0:tries
1:wins
2:best ⧗m
3:best ⧗s
4:souls
5:pal_i
6:best chain
7:current chain
8:top floor
9:endless tries
10:run started
62:mode
63:bgm
]]

function _init() 
 if not cartdata"helloworldramen_yggdrasil_0" then
  dset(5,1)
 end
 
 allow_input,
 fade_pct,target_fade_pct,
 gtime_start,gtime_m,gtime_s,aim_dir,
 turn,fturn
  =us"true,1,0,0,0,0,0,0,0"
 ytiers,
 item_names,
 item_sprs,
 item_tips,
 aim_items,
 poi,
 mob_hps,
	mob_atks,
	mob_vis,
	mob_loot_pct,
	mob_loot,
	mob_anims,
	mob_fly,
	mob_door,
	mob_spawns,
 fade_clrs,
 dxs,dys,
 dnbors,shuf_dnbors,
 dflt_dnbors,bat_dnbors,omni_dnbors,
 wall_sigs,
 wall_msks,
 dim_pal,
 stairb,
 pals,
 palnames,
 btnl_d,btn_t,fxs,baby_mobs,
 --nils
 aim_item,btn_bfr,
 load_floor,inv_open,
 task_map,task_map_fly,task_map_door
 =
  splitdict"0:4,3:4,6:4,9:4,12:3,15:3,18:3,21:2,24:2,27:1",
  split"rice,bell,warp,map,thor,bash,trap,gun,jump,pot,grim,hook,soul",
 	split"237,236,238,239,235,234,233,253,252,251,250,249,254",
 	split"recovers ♥,makes noise,teleports you,reveals things,brings wrath,breaks things,lays spikes,piercing shot,hop obstacles,places a pot,accursed tool,grabs things,...",
 	splitdict"bash:t,trap:t,gun:t,jump:t,pot:t,hook:t",
 	splitdict"201:t,202:t,203:t,204:t,205:t,206:t",
 	split"5,1,1,2,1,1,1,2,3,2,9,1,99,99",
		split"1,1,2,1,1,1,1,2,3,1,99,1,0,0",
		split"6,4,5,0,4,4,7,2.5,5,5,0,5,0,0",
		split"0,0.07,0.07,0.07,0.15,0.05,0.07,0.8,0.3,0.4,1,0.4,0,0",
		split2d"0|1,2,3,4,6,8,9,10,12|1,2,3,4,6,8,9,10,12|1,2,3,4,6,7,8,9,10,12|3,9,12|1|2,4|5,6,7,8,9,12|1,4,6,6,7,7,8,8,9,9,12,12|1,6,7,8,9,12|11|1,2,3,4,5,6,7,8,9,10,12|0|0|",
		split2d"1,2,3,4|5,6,5,7|8,9,10,11|19,20,21,20|16,17,18,17|35,36,35,37|22,23,24,23|25,26,27,28|32,32,33,33,32,32,34,34|12,13,14,15|29,29,30,30,29,29,31,31|38,39,38,40|58,58,59,59|60,61,62,63|",
		splitdict"5:bat,11:death",
		splitdict"1:player,3:skeleton,9:giant,10:knight,11:death,12:imp",
		split2d"2,2,4,5|2,2,3,4,5,12|2,3,4,5,6,12|2,3,3,4,4,5,5,6,6,10,12,12|3,3,4,5,6,6,7,7,9,9,10,10,12|3,3,4,5,6,7,7,9,9,10,10,12|3,3,6,7,7,8,9,9,10,10,12|3,6,7,8,9,10|3,3,7,8,9,9,10,10",
  split"0,1,1,2,1,13,6,4,4,9,3,13,1,13,14",
  split"-1,1,0,0,1,1,-1,-1",split"0,0,-1,1,-1,1,1,-1",
  split"-1,1,-17,17",split"-1,1,-17,17",
  split2d"-1,1,-17,17|1,-1,17,-17|-17,17,-1,1|17,-17,1,-1",
		split2d"-16,16,-18,18|16,-16,18,-18|-18,18,-16,16|18,-18,16,-16",
		split"-18,-17,-16,-1,1,16,17,18",
  split"251,233,253,84,146,80,16,144,112,208,241,248,210,177,225,120,179,0,124,104,161,64,240,128,224,176,242,244,116,232,178,212,247,214,254,192,48,96,32,160,245,250,243,249,246,252",
  split"0,6,0,11,13,11,15,13,3,9,0,0,9,12,6,3,12,15,3,7,14,15,0,15,6,12,0,0,3,6,12,9,0,9,0,15,15,7,15,14,0,0,0,0,0,0",
  splitdict"3:5,9:5,10:9,13:5",
  splitdict"124:t,179:t,214:t,233:t",
  --bg,f,d,p,e,i,i2,h,w,e2  
  split2d[[
   1,,3,,5,,7,8,9,10,11,,13,14,|
   1,,6,,5,,7,12,4,9,11,,13,6,|
   1,,4,,5,,7,8,2,9,11,,6,15,|
   1,,3,,5,,7,14,4,10,11,,6,15,|
   0,,6,,5,,10,10,10,10,10,,6,10,|
   1,,12,,5,,7,9,12,10,7,,10,10,|   
   0,,2,,1,,7,14,6,7,7,,13,7,|
   4,,7,,6,,15,15,15,15,15,,7,15,| 
   1,,8,,5,,7,10,8,10,7,,2,7,|
  ]],
  split"summer,winter,autumn,spring,porklike,juicy,gloomy,milktea,samurai",
  20,{},{},{}
		  
 --init button tools
 for i=1,6 do 
  add(btn_t,splitdict"p:0,d:0")
 end

 --setup palette setting
 pal_i=dget"5"
 function palstr()
  return "palette:"..palnames[pal_i]
 end
 function menu_pal(b)
  if(b&1>0) pal_i=max(1,pal_i-1)
  if(b&2>0) pal_i=min(pal_i+1,max_pal_i())
  dset(5,pal_i)
  return menuitem(_,palstr())
 end
 menuitem(1,palstr(),menu_pal)
 
 --setup bgm setting
 set_tglopt(us"2,63,music:on,music:off")
 
 start_game()
end

function set_tglopt(id,d_id,lbl0,lbl1)
 local function tglopt_str()
  return dget(d_id)==0 and lbl0 or lbl1
 end
 local function handle(b)
  if (b&3>0) dset(d_id,~dget(d_id))
  if d_id==63 and floor<top_flr then
   music2(us"0,0,7") 
  end
  return menuitem(_,tglopt_str())
 end
 menuitem(id,tglopt_str(),handle)
end

function _update60()
 --update button tools
 for i=0,5 do
  local b=btn_t[i+1]
  b.p=max(b.p-1,0)
  if (b.p==0) b.d=0
  if btn(i%6,i\6) then
   b.p=2
   b.d+=1
  end
 end
 
 allow_input=fade_pct==0
 _upd_fn()
end

function _draw()  
 camera(4,4)
 frame+=1
 fade_pct=lerp(fade_pct,target_fade_pct,0.04)
 _draw_fn()
 draw_windows()
 set_fade(fade_pct)
end

function start_game()
 music2(us"0,0,7") 
 mobs,traps,inv,toasts,ptcls,windows
 ={},{},{},{},{},{}
 
 _upd_fn,_draw_fn,
 pc,hp_window,
 flr_window,
 logo_t,logo_y,
 top_flr,floor,death,
 frame,inv_i,turn,maps,kills,hp_lost,
 --nils
 msg_window,item_window
 =
  update_new_floor,draw_game,
  add_mob(us"1,0,0"),
  add_window(us"100,117,28,13,_,7"),
  add_window(us"65,117,35,13,_,7"),
  us"15,46,10,-1,true,0,0,0,0,0,0"   

 --player quit midrun
 if (dget"10">0) dset(7,0)
 
  --setup endless setting
 if dget"1">0 then
  set_tglopt(us"3,62,mode:normal,mode:endless?")
 end
end



-->8

--updates

function update_game()
 if (#ptcls>0) return
 
 local p_hp,flr_txt=pc.hp,"floor "..floor
 hp_window.txt,hp_window.clr,hp_window.hide
 =
  {"♥"..p_hp.."/"..pc.mxhp},
  p_hp<4 and 8 or 7,
  not combat()

 flr_window.x,
 flr_window.w,
 flr_window.txt,
 flr_window.hide
 =
  93-#flr_txt*4,
  7+#flr_txt*4,
  {flr_txt},
  not combat()
 
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
 
 foreach(mobs,function(m)
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
 end)
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
 
 foreach(mobs,function(m)
  if m.xo!=0 or m.yo!=0 then
   m.xo,m.yo,done=
    lerp(m.xo,0,m.anim_spd),
    lerp(m.yo,0,m.anim_spd),
    false
  end
 end)
 
 foreach(items,function(i)
  if i.xo!=0 or i.yo!=0 then
   i.xo,i.yo,done=
    lerp(i.xo,0,3),
    lerp(i.yo,0,3),
    false
   if i.xo+i.yo==0 and i.x==pc.x and i.y==pc.y then
    pickup(i)
   end
  end
 end)
 
 --did everybody finish animating?
 if done then
  if load_floor then
   load_floor=false
   if floor==top_flr then 
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
 
 forpos(function(tpos)
  if maps>2 then
   fov[tpos]=true
  elseif distance(fpos,tpos)<=dist then
   fov[tpos]=los(tpos,fpos)
  else
   fov[tpos]=false
  end
  fog[tpos]=fog[tpos] or fov[tpos]
 end)
end

function update_gameover()
 target_fade_pct,windows,dtime_m,dtime_s
 =0,{},dget"2",dget"3"
 
 if btnp(🅾️) and fade_pct==0 then  
	 --end run
	 if (top_flr<999) dset(10,0)
	 
	 if pc.hp>0 then
	  dinc"1"
	  dinc(4,soulct())
	  if gtime_m<dtime_m 
	    or (gtime_m==dtime_m and gtime_s<dtime_s)
	    or (dtime_m==0 and dtime_s==0)
	    then
	   dset(2,gtime_m)
	   dset(3,gtime_s)
	  end
	  --increase chain
	  dinc"7"
	  if (dget"7">dget"6") dset(6,dget"7")
	 elseif top_flr==10 then
	  dset(7,0) --reset chain
  end
	 
  fade_to(1,true)
  start_game() 
 end
end

function gameover()
 local gtime=max(0,t()-gtime_start)
 gtime_m,gtime_s,
 windows,_upd_fn,_draw_fn
 =flr(gtime/60),flr(gtime%60),
 {},update_gameover,draw_gameover
 if pc.hp>0 then
  music(us"48,0,7")
 else
  music(us"62,500,7")
 end
 fade_to(us"1,1,1")
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
 pal2()
 cls"1"
 map()

 --traps
 foreach(traps,function(t)
  draw_sprite(get_anim_sprite(t.anim),t.x*8,t.y*8)
 end)
 
 --items
 local yo2=split"-1,-2,-1,0"
 foreach(items,function(i)
  local x1,y1=i.x*8+i.xo,i.y*8+i.yo,i
  spr(255,x1,y1)
  draw_sprite(
   i._spr,
   x1,
   y1+yo2[flr(frame/15)%4+1]
  )
 end)

 --mobs
 foreach(mobs,function(m)
  local alive,flashing,soul=m.hp>0,m.flash>0,m.soul
  local c=flashing and 7 or nil
  m.flash-=min(1,m.flash)
  c=(soul and sin(frame/24)>0.8) and 7 or c
  if alive or flashing and sin(time()*8)>0 then
   draw_sprite(
    get_anim_sprite(m.anim),
    m.x*8+m.xo,
    m.y*8+m.yo,
    c, 
    m.flipped
   )
  end
 end)
 
 --effects
 foreach(fxs,function(fx)
  spr(deli(fx.anim,1),fx.x,fx.y)
  if (#fx.anim<1) del(fxs,fx)
 end)

 if (combat()) draw_fog()

 --toasts
 foreach(toasts,function(t)
  local offset,m=#t.txt*2-4,t.mob or t
  t.yo-=t.yo/20
  if t.yo<=1 then
   del(toasts,t)
  else
   printo(
    t.txt,
    min(126-#t.txt*3,max(4,m.x*8-offset)),
    m.y*8-6+t.yo,
    t.clr
   )
  end
 end)
 
 if floor<top_flr then
  draw_inv()
 end 
 
 if dget"62"!=0 and floor==0 then
  printo(us"endless,54,45,7")
 end
 
 --aim
 if aim_item then
  local aim_pos=mob_pos(pc)+dnbors[aim_dir]
  local ax,ay=posxy(aim_pos)
  local dx,dy=dxs[aim_dir],dys[aim_dir]
  spr(243+aim_dir,ax*8+dx*sin(frame/15),ay*8+dy*sin(frame/15))
 end
 
 --logo
 if floor==0 and logo_y>-32 then
  ?"v1",122,170-logo_y,5
  sspr(us("0,32,128,32,4,"..logo_y))
  if logo_t<15 or frame>240 then
   logo_t-=1
   if (logo_t<10) logo_y+=logo_t/15
  end
 end
end

function draw_gameover()
 cls()
 pal()
 if pc.hp>0 then
  ?us"~victorious~,41,30"
 else
  ?us"..defeated..,41,30"
 end
 ?" floor: "..floor,45,46,6
 ?" turns: "..turn,45,54
 ?" kills: "..kills,45,62
 ?"♥lost: "..hp_lost,45,70
 ?" time: "..timestr(gtime_m,gtime_s),45,82
 
 if pc.hp>0 then
  ?"souls returned: "..soulct(),33,94 
  if max_pal_i(dget"4"+soulct())>max_pal_i() then
   ?us"new palette unlocked!,25,101"
  end
  if dget"1"==0 then
   ?us"endless mode unlocked!,24,124"
  elseif dget"7">0 then
   ?(dget"7"+1).." win streak!",40,124
  end
 end
 ?us"🅾️ to continue,38,116,7"
end

function draw_fog()
 for f,t in pairs(dim_pal) do
  pal(f,getc(t))
 end
 
 forpos(function(pos)
  local x,y=posxy(pos)
  local uncovered,item,x8,y8=fog[pos],get_item(x,y),x*8,y*8
  if uncovered and not fov[pos] then 
   --uncovered and not currently in sight
   spr(mget(x,y),x8,y8)
   if item then
    spr(208,x8,y8)
    spr(item._spr,x8,y8)
   end
  elseif not uncovered then
   --covered
   spr(255,x8,y8)
  end
 end)
 
 pal2()
end

function get_anim_sprite(sprites)
 return sprites[flr(frame/15)%#sprites+1]
end

function draw_sprite(_spr,_x,_y,flash,_flipped)
 if flash then
  pal(8,7)
  pal(14,7)
 end
 spr(_spr,_x,_y,1,1,_flipped)
 pal2()
end

function add_window(_x,_y,_w,_h,_txt,_clr)
 return add(windows,{x=_x,y=_y,w=_w,h=_h,txt=_txt,clr=_clr})
end

function draw_windows()
 foreach(windows,function(w)
  if not w.hide then
	  local wx,wy,ww,wh,clr=w.x,w.y,w.w,w.h,w.clr
	  --drawing the main window with double borders
	  rectfill(wx,wy,wx+max(ww-1,0),wy+max(wh-1,0), 1)
	  rect(wx+1,wy+1,wx+ww-2,wy+wh-2,clr)
	  wx+=4
	  wy+=4
	  
	  clip(wx-4, wy-4, ww-8, wh-8)
	  foreach(w.txt,function(_txt)
	   ?_txt,wx,wy,clr
	   wy+=6
	  end)
	  clip()
	  
	  if w.dur then
	   w.dur-=1
	   if w.dur<=0 then
	    --animate collapsing the window
	    w.h-=w.h/3 --collapse by height
	    w.y+=w.h/6 --collapse towards center
	    if (w.h<1) del(windows, w)
	   end
	  end
	 end
 end)
end

function show_timed_msg(msg, _dur, c)
 --calculate the required width, with some extra h-padding
 local w=(#msg+2)*4+7
 local window=add_window(
  63-w/2,56,w,13,{" "..msg},c
 )
 
 window.dur=_dur
end

function show_msg(texts,c,yo)
 msg_window=add_window(
  20, --x
  46+(yo or 0), --y
  95, --width
  #texts*6+7, --height
  texts, --text
  c --color
 )
 msg_window.can_btn=true
end

function printo(txt,x,y,c1)
 for i=1,8 do
  ?txt,x+dxs[i],y+dys[i],1
 end 
 ?txt,x,y,c1
end

function show_toast(_txt,_x,_y,_clr,dur)
 add(toasts,{
  txt=_txt,
  x=_x,
  y=_y,
  yo=5,
  clr=_clr,
  dur=dur or 10
 })
end

function set_fade(pct)
 for j=1,15 do
  local c=j
  for k=1,flr((max(0,min(pct,1))*100+j*1.46)/22) do
   c=fade_clrs[c]
  end
  pal(j,c,1)
 end
end

function fade_to(pct,force,slow)
 target_fade_pct=pct
 if force then
  repeat
   fade_pct=lerp(fade_pct,target_fade_pct,0.04)
   set_fade(fade_pct)
   flip()
   if slow then
    flip()
    flip()
   end
  until fade_pct==target_fade_pct
 end
end

function draw_inv()
 local selecting,x,y,w,h=inv_scroll(),us"7,117,13,12"
  
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
   pal(10,getc(9))
   pal(9,getc(5))
  end
  spr(item._spr,xo+3,y+3)
  if not selecting then
   --print quantity by default
   printo(item.qty,xo+11,y+8,7)
   --collapse existing item tips
   if (item_window) item_window.dur=0
  elseif inv_i==i and selecting then
   --arrows
   spr(244,xo-5,y+3)
   spr(245,xo+11,y+3)
   del(windows,item_window)
   item_window=add_window(x,y-14,64,13,{item.tip},7)  
  end
  pal2()
 end
end

function getc(i)
 return pals[pal_i][i]
end

function pal2()
 for f,t in pairs(pals[pal_i]) do
  pal(f,t)
 end
end
-->8
--misc

function lerp(a, target, spd)
 return a<target and min(a+spd, target) or max(a-spd, target)
end

function border(pos)
 local x,y=posxy(pos)
 return x%16==0 or y%14==0
end

function coinflip()
 return rnd()<0.5
end

function blocked(tpos,mode,fly,door)
 local x,y=posxy(tpos)
 local tile,mob,trap=
  mget(x,y),
  get_mob(x,y),
  get_trap(x,y)
 local nonpc=mob and mob!=pc
 local unwalkable=fget(tile,0) and not(door and tile==203)
 if fly then
  unwalkable=unwalkable and fget(tile,2)
 end

 local r={
  move=mob,
  idle=not fly and trap or nonpc,
  chase=nonpc,
  breed=trap or mob
 }
 return unwalkable or r[mode]
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
	   foreach(dnbors,function(d)
	    local nbor=pos+d
	    if not dmap[nbor] 
	     and not blocked(nbor,mode,fly,door)
	     then
	     add(q,nbor)
	    end
	   end)
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

function get_sig(pos,get_bit)
 local sig=0
 foreach(split"-1,1,-17,17,-16,18,16,-18",function(d)
  sig=(sig<<1)|get_bit(pos+d)
 end)
 return sig
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

function us(s)
 return unpack(split(s))
end

function forpos(fn)
 for pos=1,255 do fn(pos) end
end

function combat()
 return floor%top_flr!=0
end

function soulct()
 for i in all(inv) do
  if (i.name=="soul") return i.qty
 end
 return 0
end

function dinc(i,amt)
 dset(i,dget(i)+(amt or 1))
end

function timestr(m,s)
 return m..":"..(s<10 and "0"..s or s)
end

function max_pal_i(n)
 return min(9,flr((n or dget"4")/4+1.5))
end

--lower priority sfx
function sfx2(...)
 if (stat"49"<0) sfx(...)
end

--honours bgm setting
function music2(...)
 if dget"63"==0 then
  music(...)
 else music"-1" end
end
 


-->8
--input

function load_btn_bfr()
 for i=0,5 do
  if allow_input and btnp(i) then 
   btn_bfr=i 
   return
  end
 end
end

function read_input()
 if allow_input then
	 --handle special inputs first
	 if (btnr(❎)) inv_open=false
	
	 if inv_scroll() and inv_i>0 then
	  if not inv_open then
	   --expand items
	   inv_open=true
	   sfx2"14"
	  elseif btnps(⬅️) then
	   --change item left
	   inv_i-=1
	   sfx2"15"
	  elseif btnps(➡️) then
	   --change item right
	   inv_i+=1
	   sfx2"15"
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
	    if (logo_t==15) logo_t-=1
	    aim_dir=i+1
	    handle_btn(i)
	    return
	   end
	  end
	 end
	end
end

function handle_btn(_btn,did_act)
 if msg_window then
  if _btn>3 then
   msg_window.dur,msg_window=0,nil
  end
 elseif aim_item then
  if _btn==❎ then
   aim_item=false
  elseif _btn==🅾️ then
   did_act=use_aim_item()
  else
   aim_dir=_btn+1
   sfx2"15"
  end
 elseif _btn==🅾️ then
  if combat() then
    did_act=use_item()
  else
   sfx"6"
  end
 elseif _btn<4 then  
  _btn+=1
  did_act=move_mob(pc,dxs[_btn],dys[_btn]) 
 end
 
 if did_act and combat() then
  turn+=1
  fturn+=1
  is_p_turn=false
 end
 
 _upd_fn=update_anim
 update_fov()
end

function inv_scroll()
 return not aim_item 
  and btn(❎)
  and floor<top_flr
  and not msg_window
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
	 --don't footstep when other sound
	 if (m==pc) sfx2"0"
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
  --handle npcs
  if other.typ==14 then
   mob_say(other,"♥ ",14)
   sfx(28,-1,0,coinflip() and 4 or 31)
  elseif other.typ==13 then
   show_msg(split",    very well then.,       go ahead.,",8,-24)
   sfx(us"7,-1,16")
  --handle combat
  elseif not hit_mob(mob,other) then
   sfx2"24"
  elseif pcatkr then
   sfx2"9"
  elseif pcdefr then
   sfx2"10"
  end
  return true
 end
 
 if tile==200 and not mob.fly then --trap
  trigger_trap(x,y)
  sfx2"17"
 elseif tile==203 and mob.door then
  --doors
  mset(x,y,219)
  sfx2"1"
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
  sfx2"4"
 elseif tile==204 or tile==205 then 
  --chests
  mset(x,y,tile+16)
  loot_box(x,y,206-tile)
  sfx"5"
 elseif tile==206 or fget(tile,3) then
  --upstairs
  load_floor=true
  sfx"8"
 else
  if tile==222 then
   local souls=dget"4"
   local txts=dget"62"!=0 and {
    "",
    "   attempts: "..dget"9",
    "    ★floor: "..dget"8",
    ""
   } or {
    "",
    "    attempts: "..dget"0",
    "   victories: "..dget"1",
    "",
    "      streak: "..dget"7",
    "    ★streak: "..dget"6",
    "",
    "      ★time: "..timestr(dget"2",dget"3"),
    "",
    " souls saved: "..souls..(max_pal_i()<9 and "/"..(4*(max_pal_i()+1)-6) or ""),
    "    palettes: "..max_pal_i().."/9",
    ""
   }
   show_msg(txts,7,-20)
   sfx(us"7,-1,0,15")
  end
  return
 end
 
 return true
end

-->8
--mobs

function spawn_mobs(rmap,down_pos)
 if floor==0 then
  add_mob(us"14,9,8")
  return
 elseif floor==top_flr then
  add_mob(us"13,6,7")
  add_mob(us"14,10,7")
  return
 end
 local pmap={}
 forpos(function(p)
  if rmap[p] and distance(p,down_pos)>3 then
   add(pmap,p)
  end 
 end)
 shuf(pmap)
 for n=1,min(9+floor,18) do 
  while #pmap>0 do
  	local x,y=posxy(deli(pmap,#pmap))
  	local flag=fget(mget(x,y))
  	if flag==0 or flag==4 then
   	local mob=rnd(top_flr>10 and split"2,3,4,5,6,7,8,9,10,12" or mob_spawns[floor])
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
 return add(mobs,{
  typ=_typ,
  x=_x,
  y=_y,
  xo=0,
  yo=0,
  hp=mob_hps[_typ],
  mxhp=mob_hps[_typ],
  atk=mob_atks[_typ],
  vis=mob_vis[_typ],
  eva=_typ==1 and 0.25 or 0,
  fly=mob_fly[_typ],
  door=mob_door[_typ],
  anim=mob_anims[_typ],
  anim_spd=0,
  flash=0,
  flipped=false,
  task="idle",
  stun=0
 })
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
 
 defr.flash=8
 if defr.hp<=0 then
  defr.flash=defr==pc and 64 or 12
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
 add(toasts,{
  txt=_txt,
  x=m.x,
  y=m.y,
  yo=5,
  clr=c,
  mob=fov[mob_pos(m)] and m or nil
 })
end

--can m los the player
function mob_los_p(m)
 if (m.typ==11) return true
 local mpos,ppos=mob_pos(m),mob_pos(pc)
 return distance(mpos,ppos)<=m.vis 
  and (
   (m.typ==7 and get_task_map(m)[mpos]) --hounds can smell
   or los(mpos,ppos)
  )
end
-->8
--ai

function get_task_map(m)
 local ppos=mob_pos(pc)
 if m.fly and m.door then
  return get_dist_map(ppos,nil,true,true)
 elseif m.fly then
  task_map_fly=task_map_fly or get_dist_map(ppos,nil,true)
  return task_map_fly
 elseif m.door then
  task_map_door=task_map_door or get_dist_map(ppos,nil,false,true)
  return task_map_door
 else
  task_map=task_map or get_dist_map(ppos)
  return task_map
 end
end

function dictcopy(t)
 local t2={}
 for k,v in pairs(t) do
  t2[k]=v
 end
 return t2
end

function update_ai()
 load_btn_bfr()
 local ppos,tm,tmf,tmd=mob_pos(pc)
 task_map,task_map_fly,task_map_door=nil
 
 foreach(mobs,function(m)
  local mpos=mob_pos(m)

  if m.stun>0 then
   m.stun-=1
   mob_say(m,"?!",10)
  elseif (m.typ==11 and fturn==109) or m.hp<=0 or m==pc or m.typ>12 then
   --don't move
  elseif m.task=="idle" then
   if mob_los_p(m) then
    m.task,m.task_pos,m.task_map
    ="chase",ppos,dictcopy(get_task_map(m))
    mob_say(m,"!",m.typ==11 and 8 or 10)
    ai_chase(m)
   else
    ai_idle(m)
   end
  elseif m.task=="chase" then
   if mob_los_p(m) then
    --keep chasing
    m.task_pos,m.task_map=ppos,dictcopy(get_task_map(m))
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
 end)
 
 foreach(baby_mobs,function(baby)
  baby=add_mob(baby.typ,baby.x,baby.y)
  mob_say(baby,"웃",14)
 end)

 if death and fturn==108 and combat() then
  forpos(function(pos)
   if mgetpos(pos)==207 then
    local x,y=posxy(pos)
    add_mob(11,x,y)
    show_timed_msg("death approaches",60,7)
    sfx"27"
   end
  end)
 end
 
 baby_mobs,is_p_turn={},true
end

function ai_dnbors(m)
 if (m.typ>=11) return omni_dnbors
 return rnd(m.typ==5 and bat_dnbors or dflt_dnbors)
end

function ai_idle(m)
 if m.typ==4 then
  --crab
  ai_idle_crab(m)
 elseif m.typ!=9 or turn%2!=0 then
  ai_idle_normal(m)
 end
end

function ai_chase(m)
 if m.typ==2 and rnd()<0.3 then
  --slime
  ai_idle_normal(m)
 elseif m.typ==5 then
  --bat
  if coinflip() then
   ai_idle(m)
  else
   ai_chase_normal(m)
  end
 elseif m.typ==6 and ai_breed(m,0.3) then
  --rat
 elseif m.typ==9 and turn%2!=0 then
  --giant
 elseif m.typ==11 then
  --death
   if coinflip() then
    ai_chase_normal(m)
   end
 else
  ai_chase_normal(m)
 end
end

function ai_idle_normal(m)
 local m_dnbors,pos=ai_dnbors(m),mob_pos(m)
 
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

function ai_chase_normal(m)
 local m_dnbors,pos,p_pos=ai_dnbors(m),mob_pos(m),m.task_pos
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
  local mpos=mob_pos(m)
  for dnbor in all(rnd(dflt_dnbors)) do
   if not blocked(mpos+dnbor,"breed") then
    local bx,by=posxy(mpos+dnbor)
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
-->8
--items

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
 
 if fov[xypos(_x,_y)] then
  show_toast(item.name.."(".._qty..")",_x,_y,7)
  sfx2"3"
 end
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
 
 if name=="rice" or name=="soul" and pc.mxhp>=9 then
  local heal=pc.hp<pc.mxhp and 1 or 0
  pc.hp+=heal
  mob_say(pc,"+"..heal,11)
  sfx(us"13,-1,0,5")
 elseif name=="bell" then
  mob_say(pc,"♪",7)
  sfx"16"
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
  forpos(function(p) add(tmap,p) end)
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
  forpos(function(pos)
   local x,y=posxy(pos)
   if poi[mget(x,y)] or maps>0 then
    fog[pos]=true
   end
  end)
  maps=min(maps+1,3)
  sfx(20,-1,0,split"10,13,31"[maps])
 elseif name=="thor" then
  for m in all(mobs) do
   if fov[mob_pos(m)] then
    hit_mob(pc,m,m==pc and 1 or 2)
   end
  end
  sfx"21"
 elseif name=="soul" then
  pc.hp+=1
  pc.mxhp+=1
  mob_say(pc,"+1max",11)
  sfx"13"
 elseif aim_items[name] then
  aim_item,did_act=item,false
  item.qty+=1 --reverse
  sfx2"14"
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
   sfx(us"17,-1,0,1")
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
    move_mob_pos(pc,hpos-dnbors[aim_dir],false)
    aoestun(mob_pos(pc))
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
  add_item(rnd(split"1,2,3,4,5,6,7,8,9,12"),1,x,y)
 elseif rnd()<0.05 then
  add_mob(rnd(split"2,4,5,6"),x,y).stun=1
 end
end

function loot_box(x,y,qty)
 add_item(rnd(split"1,2,3,4,5,6,7,8,9,10,12"),qty,x,y)
end

function loot_mob(m)
 local flritem=get_item(m.x,m.y)
 if m.soul then
  del(items,flritem)
  add_item(13,1,m.x,m.y)
 elseif not flritem 
   and rnd()<mob_loot_pct[m.typ] then
  add_item(rnd(mob_loot[m.typ]),1,m.x,m.y)
 end
end
-->8
--mapgen

function new_floor()
 floor+=1
 
 mobs,ptcls,traps,
 pc.xo,pc.yo,maps,fturn
 =
  {pc},{},{},
  us"0,0,0,0"
  
 if not combat() then
  --hub/end
	 for x=0,16 do
	  for y=0,16 do
	   mset(x,y,mget(x+(floor==0 and 33 or 17),y))
	  end
	 end
	 
	 spawn_mobs()
	 pc.x,pc.y=8,floor==0 and 13 or 14
 
  if (floor==top_flr) music(-1,2000)
 else
  --regular floor
  if floor==1 then
   if dget"62"!=0 then
    top_flr=999
    dinc"9"
   else
    dinc"10"
    dinc"0"
   end
   gtime_start=t()
  end
  
  --track endless floor
	 if (top_flr>10 and floor>dget"8") dset(8,floor)
  
  local sane,
   tmap,imap,bmap,rmap,down_pos,px,py
   =false
  
  while not sane do
   tmap,imap,bmap,rmap,down_pos=map_gen(17,15,transt)
	  px,py=posxy(down_pos)
	
	  forpos(function(pos)
		  local x,y=posxy(pos)
		  mset(x,y,tmap[pos])
		 end)
		 
		 sane=true
		 local reachable=get_dist_map(down_pos,"dmap",true,true)
		 for pos=1,255 do
		  if tmap[pos]!=143 and not reachable[pos] then
		   sane=false
		   break
		  end
		 end
  end

	 pc.x,pc.y=px,py
	 prettywalls()
  spawn_traps()
  spawn_mobs(rmap,down_pos)
 end
 
 items,fov,fog,frame,is_p_turn=
  {},{},{},0,true
 update_fov()
end
	
function map_gen(tw,th,transt)
 local nxt_id,stair_d,merged_ids,tmap,imap,bmap,rmap,roomsizes,
  --nil
  down_pos
  =1,0,{},{},{},{},{},split"3,3,5"
	
	function oob(x,y)
	 return x<0 or y<0 or x>16 or y>14
	end
	
	function twall(pos)
	 return tmap[pos]==143
	end
	
	function can_rm(x,y,rmw,rmh)
	 if (x+rmw>=15 or y+rmh>=13) return false
	 
	 for _x=x,x+rmw do
	  for _y=y,y+rmh do
	   if tmap[xypos(_x,_y)]!=143 then
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
  foreach(seta,function(a)
   foreach(setb,function(b)
    if (a==b) n+=1
   end) 
  end)
	 return n
	end
	
	function walls()
	 local t={}
	 forpos(function(i)
	  if (twall(i)) add(t,i)
	 end)
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
	 	 
	 tmap[pos],imap[pos]=143
	 for_nb(pos,function(nb)
	  do_dend(nb)
	 end)
	end
	
	function for_nb(pos,fn)
	 foreach(dnbors,function(d)
	  fn(pos+d)
	 end)
	end
	
	function stairs()
	 local s={}

  forpos(function(pos)
   if not border(pos) then
	   local b=get_sig(pos,function(p)
		   return tmap[p]==192 and 0 or 1
		  end)
		  if (stairb[b]) add(s,pos)
   end
  end)
  
  if #s>=2 then
   local maxd,spair=0
   foreach(s,function(s1)
    foreach(s,function(s2)
     local d=distance(s1,s2)
     if d>maxd then
      maxd,spair=d,{s1,s2}
     end
    end)
   end)
   
   local t=shuf(spair)
   tmap[spair[1]],tmap[spair[2]],down_pos,stair_d
   =
    207,206,spair[1],maxd
  end
	end
	
	local try=0
 while true do
  forpos(function(i)
   tmap[i],bmap[i],rmap[i]=143
  end)
  
  imap,nxt_id,merged_ids,stair_d=
   {},1,{},0

		--do rooms
	 for i=1,75 do --number of tries
	  local x,y,rmw,rmh=
	   rnd(split"1,3,5,7,9,11,13,15"),
	   rnd(split"1,3,5,7,9,11,13"),
	   rnd(roomsizes),
	   rnd(roomsizes)
	  if can_rm(x,y,rmw,rmh) then
	   --do room
			 for _x=x,x+rmw-1 do
			  for _y=y,y+rmh-1 do
			   local pos=xypos(_x,_y)
			   tmap[pos],rmap[pos],imap[pos]=
			    192,rmw*rmh,nxt_id
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
					  split2d"1,0,2,0|0,1,0,2|-1,0,-2,0|0,-1,0,-2"
					  
					 for d in all(shuf(ds)) do
					  local x3,y3=x1+d[3],y1+d[4]
					  local pos2,pos3=
					   xypos(x1+d[1],y1+d[2]),
					   xypos(x3,y3)
					  local can_cycle=
					   imap[pos3]==nxt_id
					    and tmap[pos2]!=192
					    and rnd()<0.05
					  if twall(pos3)
					    and not oob(x3+1,y3+1) 
					    and not oob(x3-1,y3-1) 
					    or can_cycle then
					   for p in all{pos1,pos2,pos3} do
					    tmap[p],imap[p]=192,nxt_id
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
	 foreach(wls,function(pos)
	  local adj={}
	  for_nb(pos,function(nb)
	   if tmap[nb]==192 then
	    set_add(adj,imap[nb])
	   end
	  end)
	  
	  if #adj==2 then
	   local need_mrg,disjoint,can_xtra=
	    true,true,xtra_drs<1 and rnd()<0.5
	   
	   foreach(merged_ids,function(merged)
	    local isize=intersect(adj,merged)
	    
	    if (isize==2) need_mrg=false
	    if isize==1 then
	     disjoint=false
	     foreach(adj,function(a)
	      set_add(merged,a)
	     end)
	    end
	   end)
	   
	   if need_mrg then
	    tmap[pos]=203
	    if (disjoint) add(merged_ids,adj)
	   elseif can_xtra then
	    tmap[pos]=203
	    xtra_drs+=1
	   end
	  end
	 end)

  forpos(do_dend)
  
  --cleanup doors
  forpos(function(pos)
	  if tmap[pos]==203 then
	   for_nb(pos,function(nb)
	    if (tmap[nb]==203) tmap[nb]=143
	   end)
	  end
	 end)
	 forpos(function(pos)
	  if tmap[pos]==203 then
	   if (rnd()<0.4) tmap[pos]=192
	  end
	 end)
	 
  stairs()
  
  --bits
  for i=1,255 do
	  local wall_ct,rm_flr_ct,b=0,0
	  for_nb(i,function(nb)
	   if (twall(nb)) wall_ct+=1
	   if (rmap[nb]) rm_flr_ct+=1
	  end)
	  
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
	   b=twall(i) and 143 or "hall"
	  end
	  bmap[i]=b
	 end

  try+=1
  
  local good=#walls()<=168 and stair_d>100
  if (good or (try>15 and stair_d>0)) break
 end

 prefab(tw,th,tmap,imap,bmap,rmap)
 
 return tmap,imap,bmap,rmap,down_pos
end

function is_wall(t)
 return not t or (t>141 and t<190)
end

function prettywalls()
 local ntmap={} 
 forpos(function(pos)
  if is_wall(mgetpos(pos)) then
   local wall_sig,sig_i=get_sig(pos,function(p)
    return is_wall(mgetpos(p)) and 1 or 0
   end),0
   for i=1,#wall_sigs do
    local _mask=wall_msks[i] or 0
    if wall_sig|_mask==wall_sigs[i]|_mask then
     sig_i=i
     break
    end
   end
   ntmap[pos]=143+sig_i
  end
 end)
 forpos(function(pos)
  local x,y=posxy(pos)
  if (ntmap[pos]) mset(x,y,ntmap[pos])
 end)
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
   add(rms3x3[ytiers[my]],rm)
  end
  --5x3 rooms
  for mx=71,101,5 do
   local rm={}
   for yo=0,2 do
    for xo=0,4 do
     add(rm,mget(mx+xo,my+yo))
    end
   end
   add(rms5x3[ytiers[my]],rm)
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
--button tools

--button released
function btnr(i)
 return btn_t[i+1].p==1
end

--button short press
function btnps(i)
 local b=btn_t[i+1]
 return b.p==1 and b.d<=btnl_d
end
__gfx__
11111111001111100017171100111110001717110000000000111110000000000018881e0018881e001888110018881101188810011888100118881101188811
1111111100171711001777710017171100177771001111100118ee11000000001118e81e1118e81e1118e81e1118e81e1188e8111188e8111188eeee1188eeee
11711711111777711117171101177771011717110118ee11018881e111111111188881ee188881ee1888811e1888811e18888eee18888eee18888ee118888ee1
1117711117171711171777771177171111777777118881e1018881811888eee1188188e1188188e1188181ee188181ee18818ee118818ee118818e1e18818e1e
11177111771777777711111117777777177111111888881e018888818888811e1188188111818881188818e1118188e111888e1e11818e1e11888eee11818eee
11711711777111117771771017711111177177101888888801888881888888881881111118188111188118811818888118811eee18188eee188111e1181881e1
111111111771771017717710117177101171771011888881011888111888888111881000188188101188111118818811118811e1188181e11188111118818811
11111111111717101111711001171710011171100111111100111110111111110111100011111110011110001111111001111111111111110111100011111110
1111111000000000000000001ee1ee111ee1ee111111111000018181000181810001818111118811111111101111111011118811111111101e11111000111110
188188111111111011111111e81118e1e88188e11ee1ee11011188810111888101118881181881881811881118118811181888881e188811eee8881111188811
8e111e8118111811818881818811188188111881e88188e111818e8811818e8811818e881818888818188e881818888818188888eee78781ee1787811e878781
ee888ee1888888818888888181e1e18181e1e18188e1e88118818888188188881881888818888811188888881888888818888811ee188881e1818881eee88881
e18881e1888888818e181e8118888811188888111888881118881888188818111888181118888881188888811888888118888881e1818811e1881811ee188811
11181111181818111881881181888181818881818188818118888811188888881888881118888111188881111888811118888111e188188111888181e1818881
001110001111111011111110181118111811181118111811188188101881881118818888118188101181881011818810118188101188818111888881e1881881
00000000000000000000000011101110111011101110111011111110111111101111111101111110011111100111111001111110188888811888888118888181
ee118888ee118888ee11888801111000000000000111100011111100111111001111110011111111111111111111111111111111111111111111111111111111
eee88ee8eee88ee8eee88ee801881110011111100188111018888110188881101888811011111111111111111111111111111111111111111111111111111111
18ee888818ee888818ee8888018188110188881101818811118e8811118e88111188881111111111111111111111111111111111111111111111111111111111
1881e8811881e8811881e88111188e8101818e8101188e811888881e1888881e1888881e11111111111111111111111111111111111111111111111111111111
188888881888888818888888181888811118888111188881188881e1188881e1188881e111111111111111111111111111111111111111111111111111111111
18811881188118881888188111888111188881111888811118888e1118888e1118888e1111111111111111111111111111111111111111111111111111111111
18881888188811111111188801881810118818101188181011818110111811101118111011111111111111111111111111111111111111111111111111111111
11111111111110000000111101111110011111100111111001111100011111000111110011111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111000001711117171000171710001717100017171000
11111111111111111111111111111111111111111111111111111111111111111111111111111111188871110001777117771000177710001777100017771000
11111111111111111111111111111111111111111111111111111111111111111111111111111111118877711111771777171111771711007717110077771100
11111111111111111111111111111111111111111111111111111111111111111111111111111111188877171888877777777171777771117777711077777111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111887771888881717777711177777711777771117777771
11111111111111111111111111111111111111111111111111111111111111111111111111111111188888171188881117777710177777111777777117777711
11111111111111111111111111111111111111111111111111111111111111111111111111111111118888110118111017171710171717101717171117171710
11111111111111111111111111111111111111111111111111111111111111111111111111111111011811100011100011111110111111101111111011111110
00011111000111111000111111111110000111111111110011111111111001111111111100000111111111100011111111111001111111001111111000000000
001aaaaaa11aaaaaa1001aaaaaaaaa100001aaaaaaaaa101aaaaaaaaaa101aaaaaaaaaa100001aaaaaaaaaa101aaaaaaaaaaa11aaaaaaa11aaaaaaa100000000
001aaaaaa11aaaaaa1011aaaaaaaaa110011aaaaaaaaa111aaaaaaaaaa111aaaaaaaaaa110011aaaaaaaaaa111aaaaaaaaaaa11aaaaaaa11aaaaaaa100000000
00111aaaa1111aaaa11aaa1111111aaa11aaa1111111aaa111aaa1111aaa111aaa1111aaa11aaa1111aaa111aaaa11111aa111111aaa111111aaa11100000000
00011aaaa1111aaaa11aaa1111111aaa11aaa1111111aaa111aaa1111aaa111aaa1111aaa11aaa1111aaa111aaaa11111aa111111aaa111111aaa11000000000
00001aaaa1111aaaa11aaa111111111111aaa1111111111111aaa1111aaa111aaa1111aaa11aaa1111aaa111aaaa1111111111111aaa111111aaa10000000000
00001aaaa1111aaaa11aaa111111111111aaa1111111111111aaa1111aaa111aaa1111aaa11aaa1111aaa111aaaa1111111111111aaa111111aaa10000000000
0000111aaaaaaaaaa11aaa11111aaaaa11aaa11111aaaaa111aaa1111aaa111aaaaaaaa1111aaaaaaaaaa11111aaaaaaaaa111111aaa111111aaa10000000000
00000119999999999119991111199999119991111199999111999111199911199999999111199999999991111199999999911111199911111199911111111000
00000011111119999119991111111999119991111111999111999111199911199911119991199911119991111111111119999111199911111199911111199100
00001111111119999119991111111999119991111111999111999111199911199911119991199911119991111111111119999111199911111199911111199100
00019911111119999119999911111999119999911111999111999111199911199911119991199911119991119999111119999111199911111199911119999100
00019911111119999119999911111999119999911111999111999111199911199911119991199911119991119999111119999111199911111199911119999100
00011199999999991111119999999911111199999999911101999999991110199911119991199911119991111199999999911111111999111199999999999100
00001199999999991000119999999911001199999999911001999999991100119910019991199910019991001199999999911000011999100199999999999100
00000111111111111000011111111110000111111111110001111111111000111110011111111110011111000111111111110000001111100111111111111100
00000011111111110000111111111110000111111111110000111111111000011100001110011100001110000011111111100000001111000011111111111000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111000001111110111111001110111011111100011110110011100111111101110111000001110011100111101111111011101110011110110011100000
00017777100017777771777777117771777177777710177771771177711777777717771077100017771177711777717777777177717771177771771177710000
00011771100177117711177117711771177117711771117711177117711711771111771177100011771117711177117117711117711771117711177117710000
00001771001177117711177777111771177117711771117711177717711111771111771177100001771117711177111117711117711771117711177717710000
00001771111177777711177117711177777117777711117711177777711111771111777777100001771717711177111117711117777771117711177777710000
00001771117177117711177117711111177117711771117711177177711111771111771177100001777777711177111117711117711771117711177177710000
00001771177177117711177117711711177117711771117711177117711111771111771177100001777177711177111117711117711771117711177117710000
00001777777177117711177777111177771117711771111771177111711111771111771177100001771117710117710117710017711771111771177111710000
00001111111111111110111111100111111011111111011111111101110001111111111111100001111011110011110011110011111111011111111101110000
00000111111011001100011111000011110001100110000110011000100000111000110011000000110001100001100001100001100110000110011000100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111ddddddddddddddddddddddd1d177777777777777777771d1d177777777777777777771d1d1ddd1d111111111
1111111111111111111111111111111111111111d111111111111111111111d1d177777777777777777771d1d177777777777777777771d11111111111111111
1111111111111111111111111111111111111111d177777777777777777771d1d177777777777777777771d1d177777777777777777771d1ddd1ddd111111111
1111111111111111111111111111111111111111d177777777777777777771d1d177777777777777777771d1d177777777777777777771d11111111111111111
1111111111111111111111111111111111111111d177777777777777777771d1d177777777777777777771d1d177777777777777777771d1d1ddd1d111111111
1111111111111111111111111111111111111111d177777777777777777771d1d177777777777777777771d1d111111111111111111111d11111111111111111
1111111111111111111111111111111111111111d177777777777777777771d1d177777777777777777771d1d111111111111111111111d1ddd1ddd111111111
1111111111111111111111111111111111111111d177777777777777777771d1d177777777777777777771d11111111111111111111111111111111111111111
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
11111111ccccccccd1d11dd1ddd1ddd1000000000000000000000000000000001d111d1111aaa11111aaa1111aaaaa1111aaa11111111111111111a1ddddddd1
11111111cccccccc111111111111111100000000aaaaaaaa0000000000000000131113111a111a111a111a11a11111a1a1aaa1a11aaaaaa1111aa1a111111111
11111111ccccccccd11dd1d1d1ddd1d10000000077777777aaaaaaaa00000000313131311a111a111a111a1191999191a11111a11a1111a1aa1aa1a111111dd1
11111111cccccccc1111111111111111aaaaaaaa7777777777777777777777771111111111aaa11191aaa1a111999111a11a11a11a1aa1a1aa1aa11111dd1dd1
11111111cccccccc11111111111111110000000077777777aaaaaaaa000000001d111d1119119a1199119aa191999191aaa1aaa11aaaaaa1aa111191d1dd1dd1
11131111cccccccc111311111113111100000000aaaaaaaa000000000000000013111311199aaa11199aaa1111999111111111111111111111199191d1dd1dd1
11111111cccccccc11111111111111110000000000000000000000000000000031313131119991111199911191999191999999911999999199199191d1dd1dd1
11111111cccccccc1111111111111111000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111ddd1ddd1000a00000a777a0000a7a00000070000111111111113311111133111133333111111111111111111aaaaaaa111111111
13131111111111111111111111111111000a00000a777a0000a7a000000700001d111d1113111311131113113111113133333331133333319999999111111111
113111111113131111111111d1ddd1d1000a00000a777a0000a7a000000700001311131113111311131113113111113131111131131111319111119111111111
11111111111131111111111111111111000a00000a777a0000a7a000000700001111111111111111311111311111111131111131131111311191911111111111
11113131111111111131311111113131000a00000a777a0000a7a000000700001111111113113311331133313111113133333331133333319191119111111111
31311311131311111113111131311311000a00000a777a0000a7a000000700001d111d1113313311133333111111111111111111111111119111919111111111
13111111113111111111111113111111000a00000a777a0000a7a000000700001311131111333111113331113111113133333331133333319111119111111111
11111111111111111111111111111111000a00000a777a0000a7a000000700001111111111111111111111111111111111111111111111119999999111111111
311131131111111111111111ddd1ddd11111111111111111111111111111111111111111000000000000000000000a00000000000000000000aaaa0000000000
13131131111113111111111111111111111111111111111111111111111111111111111100a00a000000a0000000a900000aa000000aa0000a1111a00a009a00
131311311131111113111131d1ddd1d1111111111111111111111111111111111d111d1100900900000aaa00000a900000000000009aaa0000aaaa000aa99aa0
113113111111311111111111111131111111111111111111111111111111111111111111191991910001aaa000aaa9000099aa0009999aa0091111900a191aa0
31131131311311311113111131131131111111111111111111111111111111111111111111a11a1100191a90000a900000991a00099119a0009999000aa19aa0
131313111313131111131311131313111111111111111111111111111111111111111111119119110191090000a9000009aaaaa0099119900a1111a00a191aa0
13131311131113111311111113111311111111111111111111111111111111111d111d11191991910910000000900000000990000000000000aaaa0000a990a0
11111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000
111111111111111111111111ddd1ddd10000011111100000000000001111111011111111111111111111111100000000000000000000aa000000110011111111
111111111111111111111111111111110000117117110000000000001777771011111111111aaaa1111aa11100aaa000009aa0a0000aa0000001991011111111
113133111131331111111111d1ddd1d1000117711771100000000000117771101311131111111aa11119aa110a111a0009111aa000aa90000019910011111111
1111331111113311111131111111111100017771177710000011100001171100111111111111a1a111919aa111aaa1111911aaa10aa900000199a91011111111
133111111331111113311111133111110001177117711000011711000011100011111111119911a1119111a119119a11111111110a9a0000199a999111111111
13313111133111111331111113311111000011711711000011777110000000001111111119991111191111a11999aa11119aa111099000001997a99111111111
1111111111111111111111111111111100000111111000001777771000000000131113111a9111111911111111999111119aa111099000000197a91011111111
11111111111111111111111111111111000000000000000011111110000000001111111111111111111111111111111111111111000000000011110011111111
__label__
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
111aaaaaa11aaaaaa1111aaaaaaaaa111111aaaaaaaaa111aaaaaaaaaa111aaaaaaaaaa111111aaaaaaaaaa111aaaaaaaaaaa11aaaaaaa11aaaaaaa111111111
111aaaaaa11aaaaaa1111aaaaaaaaa111111aaaaaaaaa111aaaaaaaaaa111aaaaaaaaaa111111aaaaaaaaaa111aaaaaaaaaaa11aaaaaaa11aaaaaaa111111111
11111aaaa1111aaaa11aaa1111111aaa11aaa1111111aaa111aaa1111aaa111aaa1111aaa11aaa1111aaa111aaaa11111aa111111aaa111111aaa11111111111
11111aaaa1111aaaa11aaa1111111aaa11aaa1111111aaa111aaa1111aaa111aaa1111aaa11aaa1111aaa111aaaa11111aa111111aaa111111aaa11111111111
11111aaaa1111aaaa11aaa111111111111aaa1111111111111aaa1111aaa111aaa1111aaa11aaa1111aaa111aaaa1111111111111aaa111111aaa11111111111
11111aaaa1111aaaa11aaa111111111111aaa1111111111111aaa1111aaa111aaa1111aaa11aaa1111aaa111aaaa1111111111111aaa111111aaa11111111111
1111111aaaaaaaaaa11aaa11111aaaaa11aaa11111aaaaa111aaa1111aaa111aaaaaaaa1111aaaaaaaaaa11111aaaaaaaaa111111aaa111111aaa11111111111
11111119999999999119991111199999119991111199999111999111199911199999999111199999999991111199999999911111199911111199911111111111
11111111111119999119991111111999119991111111999111999111199911199911119991199911119991111111111119999111199911111199911111199111
11111111111119999119991111111999119991111111999111999111199911199911119991199911119991111111111119999111199911111199911111199111
11119911111119999119999911111999119999911111999111999111199911199911119991199911119991119999111119999111199911111199911119999111
11119911111119999119999911111999119999911111999111999111199911199911119991199911119991119999111119999111199911111199911119999111
11111199999999991111119999999911111199999999911111999999991111199911119991199911119991111199999999911111111999111199999999999111
11111199999999991111119999999911111199999999911111999999991111119911119991199911119991111199999999911111111999111199999999999111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11117777111117777771777777117771777177777711177771771177711777777717771177111117771177711777717777777177717771177771771177711111
11111771111177117711177117711771177117711771117711177117711711771111771177111111771117711177117117711117711771117711177117711111
11111771111177117711177777111771177117711771117711177717711111771111771177111111771117711177111117711117711771117711177717711111
11111771111177777711177117711177777117777711117711177777711111771111777777111111771717711177111117711117777771117711177777711111
11111771117177117711177117711111177117711771117711177177711111771111771177111111777777711177111117711117711771117711177177711111
11111771177177117711177117711711177117711771117711177117711111771111771177111111777177711177111117711117711771117711177117711111
11111777777177117711177777111177771117711771111771177111711111771111771177111111771117711117711117711117711771111771177111711111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111133333333333331111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111333333333333333111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111333ddddddddd333111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111333111111111333111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111113331111111a1333111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111113331111aa1a1333111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111113331aa1aa1a1333111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111113331aa1aa111333111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111333333333333333333333333331aa111191333333333333333333333333331111111111111111111111111111111111
1111111111111111111111111111111133333333333333333333333333d111199191d33333333333333333333333333111111111111111111111111111111111
11111111111111111111111111111111333ddddddddddddddddddddddd11991991911ddddddddddddddddddddddd333111111111111111111111111111111111
11111111111111111111111111111111333111111111111111111111111111111111111111111111111111111111333111111111111111111111111111111111
11111111111111111111111111111111333131113113ddd1ddd1aaaaaaa11111111117171dd1ddd1ddd131113113333111111111111111111111111111111111
11111111111111111111111111111111333113131131111111119999999111111111177711111111111113131131333111111111111111111111111111111111
11111111111111111111111111111111333113131131d1ddd1d1911111911111111177171111d1ddd1d113131131333111111111111111111111111111111111
11111111111111111111111111111111333111311311111131111191911111113111777771711111311111311311333111111111111111111111111111111111
11111111111111111111111111111111333131131131311311319191119113311111177777113113113131131131333111111111111111111111111111111111
11111111111111111111111111111111333113131311131313119111919113311111177777111313131113131311333111111111111111111111111111111111
11111111111111111111111111111111333113131311131113119111119111111111171717111311131113131311333111111111111111111111111111111111
11111111111111111111111111111111333111111111111111119999999111111111111111111111111111111111333111111111111111111111111111111111
11111111111111111111111111111111333111111111111111111111111111111111111111111111111131113113333111111111111111111111111111111111
11111111111111111111111111111111333111111311111113111111111111111111111111111313111113131131333111111111111111111111111111111111
11111111111111111111111111111111333111311111113111111131331111111111111313111131111113131131333111111111111111111111111111111111
11111111111111111111111111111111333111113111111131111111331111113111111131111111111111311311333111111111111111111111111111111111
11111111111111111111111111111111333131131131311311311331111113311111111111111111313131131131333111111111111111111111111111111111
11111111111111111111111111111111333113131311131313111331111113311111131311113131131113131311333111111111111111111111111111111111
11111111111111111111111111111111333113111311131113111111111111111111113111111311111113131311333111111111111111111111111111111111
11111111111111111111111111111111333111111111111111111111111111111111111111111111111111111111333111111111111111111111111111111111
11111111111111111111111111111111333111111111111111111111111111aaa111111111111111111111111111333111111111111111111111111111111111
111111111111111111111111111111113331131311111111111111111111a1aaa1a1111111111111131111111311333111111111111111111111111111111111
111111111111111111111111111111113331113111111111111111313311a11111a1113133111131111111311111333111111111111111111111111111111111
111111111111111111111111111111113331111111111111111111113311a11a11a1111133111111311111113111333111111111111111111111111111111111
111111111111111111111111111111113331111131311131311113311111aaa1aaa1133111113113113131131131333111111111111111111111111111111111
11111111111111111111111111111111333131311311111311111331111111111111133111111313131113131311333111111111111111111111111111111111
11111111111111111111111111111111333113111111111111111111111199999991111111111311131113111311333111111111111111111111111111111111
11111111111111111111111111111111333111111111111111111111111111111111111111111111111111111111333111111111111111111111111111111111
11111111111111111111111111111111333111133111111111111111111111111111111111111111111111133111333111111111111111111111111111111111
11111111111111111111111111111111333113111311111111111111111111111111111111111111111113111311333111111111111111111111111111111111
11111111111111111111111111111111333113111311111313111111111111313311111313111111111113111311333111111111111111111111111111111111
11111111111111111111111111111111333111111111111131111111111111113311111131111111111111111111333111111111111111111111111111111111
11111111111111111111111111111111333113113311111111111111111113311111111111111131311113113311333111111111111111111111111111111111
11111111111111111111111111111111333113313311131311111113111113311111131311111113111113313311333111111111111111111111111111111111
11111111111111111111111111111111333111333111113111111111111111111111113111111111111111333111333111111111111111111111111111111111
11111111111111111111111111111111333111111111111111111111111111111111111111111111111111111111333111111111111111111111111111111111
11111111111111111111111111111111333111133111111331111111111111111111111111111113311111133111333111111111111111111111111111111111
11111111111111111111111111111111333113111311131113111111111111111111111111111311131113111311333111111111111111111111111111111111
11111111111111111111111111111111333113111311131113111113131111313311111111111311131113111311333111111111111111111111111111111111
11111111111111111111111111111111333131111131111111111111311111113311111111111111111131111131333111111111111111111111111111111111
11111111111111111111111111111111333133113331131133111111111113311111111111111311331133113331333111111111111111111111111111111111
11111111111111111111111111111111333113333311133133111313111113313111111311111331331113333311333111111111111111111111111111111111
11111111111111111111111111111111333111333111113331111131111111111111111111111133311111333111333111111111111111111111111111111111
11111111111111111111111111111111333111111111111111111111111111111111111111111111111111111111333111111111111111111111111111111111
11111111111111111111111111111111333333333333333333333333331113111111133333333333333333333333333111111111111111111111111111111111
11111111111111111111111111111111333333333333333333333333333131171711333333333333333333333333333111111111111111111111111111111111
11111111111111111111111111111111133333333333333333333333333111177771333333333333333333333333331111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111333117171711333111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111333177177777333111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111333177711111333111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111333117717711333111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111333111171711333111111111111111111111111111111111111111111111111111111111
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

__gff__
0000000000030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000101010101010a0a0a050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050000000000000000000203030703030200000000000000000002000000000003000400000000000000020000000000000000000000000000000000000300000000
__map__
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fd1d0c0d2c0c0e1e2c9cacaf2d0c0c0e1e0e0e0e0c1c0c0c0c0c0c0f2f2d2c0e2c0c0d1c0e2f2c0c0d2c0c0d2d2e2c0f1f2c0c0c0d2d2d1c0c1c0d2c0f1c0d1e2c0c0c0d2f2d0d2d2f2c0e1e2e1e0
00000000000000000000000000000000008f8f8f8f8f909191919191928f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc0f0f2f1c0e1e0f2e0e1d2d1d0d0d1f1e1e0e0e0c1d1d2c0f2c0d2f1f0f1c0e1e2c0c0c0e1e2f0f1c0d2e2e2e1e2c0f1f0f0f2c0c0d1d0d2c1c0c0d1c0f0c0e1e2c0c0f2f1d2d2d0f0f2e2e2c0c0
00000000000000000000000000000000008f8f8f8f8fa08e8e8e8e8ea28f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc0f1f0d0d2c0f1f0f1e2c0d1f0d1f1f0e2e1e1e0c1d0d1d2d2c0f2d1f2c0f2e0e1e2e2d2e0e0e1e2c0c0f2e1e1e2f1f2c0d2f2d2c0c0d2c0c1d1c0c0d2f1c0e0e1e2f2f1f0c0d1c0f1c0c0e0e1e2
00000000000000000000000000000000008f8f8f8f8fa08e8586878ea28f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fd1f1d1f1c0e2e0e1e0c0c0f2d2f1cac0f1d2e2e1c1d2d9c0c0c0e2f2c0c0d2e1c0e1c0c0c0c0f1f1c0c0d9d2c0d2d1c0c0c0f2c9c0c0c0d2c1e2c0c0c0c0f1c0c0d2d2d1d0c0c0c0e2e0e0c0c0c0
00000000000000000000000000000000008f8f8f8f8fa08e88898a8ea28f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc0c0c0c0d2cae1c0c0c0c0c0cac9cad2d1c0f2e2c1c0f1f0d1f2e1e1f0f1c0d1f1d2e0e0c0f2c0d2c0d2c0d0d1c0c0c0d1f1dacad0f2c0c0c1c0c0e1f1c0c0d1c0daf2d2d1c0f2d9e0e1e2e2c0e1
00000000000000000000000000000000008f8f8f8f8fa08e88898a8ea28f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc0d2f1c0d2c0e1e1f1e1c0f2e2d2e0c9e0e1e2d2c1f2c0d2d9dae1e0e0e1e2e2e1e1e0e0d2c0d2d1d2d0d1dac0d2f2c0f1d9c9cad2d0c0d2c1e1e2c0d9f2c0d9c0d2c0c0d2f2d9dae1dae2c0c0e2
00000000000000000000000000000000008f8f8f8f8fa08e8b8c8d8ea28f8f8f8f8f8f8f8f8f8f8f9091928f8f8f8f8f8f8fcaf0d1d0c0e2e1e0c9f2c0c0e2c8e1dae1c0f2f2c1c0c9cae2c0c0d2c0d1c0e1e2c0c0d2f2cac0c0e2e0e1e1c0f2d2f2f2cacad2e2c9cac9c1d2c0c0d2c0c0e2e2e1c0c0c0c0d1c0c0c0d2c0c0e2
00000000000000000000000000000000008f8f8f8f8fa0d0d2c0d2d0a28f8f8f8f8f8f8f8f909191a4cea39191928f8f8f8fd2d28ed2f2c0c8c8c8c0c0d2c0e1c0d2c0f0c0e2c1e2c0d2f2c0d1c9cae2c0e2c0d0cac0d2c0f0f2c0f2f2d0caf1e1c0f1f1c9f2c0d2e2d1c1c0c0c9c0d1d0c9e1e0caf1c0cad2d0d0c0c0c9e2c0
00000000000000000000000000000000008f8f8f8f8fa0a1d2f2d1a1a28f8f8f8f8f8f8f8fa0e0e3def2d3e3e0a28f8f8f8fc0f2f1cac0e2c0f1e0e1d1c8d2c0c0e1f1f0e2d9c1e0e1c0c9e2c0e2d1c0d2d2c9c0c0d1c9f0e2f1f2e1d1f1f1c0f2c0d2c0f2f1d1c0c0d2c1c0f2c9d2c9cae1cae0f2c0c0d0c0c0c9c0c0e1f2c0
00000000000000000000000000000000008f8f8f8f8fa08ed0f2d08ea28f8f8f8f8f8f8f8fa0e1e1f1f2d1d0e0a28f8f8f8fd2f1c9c0cac9c0c0e1c0d0d1c0f1c0f2c0c0c9cac1c0c0c0c0c0c9cac0e2e0f2c0c0d2d2c0c0f2cac0d0d2f2c0e1d2c9f2c9f1f2c0e2e1e1c1cac0d0cac0e2c0f2c0d2c0c0c0f2c0d1c0c0c0c9c9
00000000000000000000000000000000008f8f8f8f8fa0d3d0f1d1d3a28f8f8f8f8f8f8f8fa0d0d2f1ccf1e1e1a28f8f8f8fc0e2d2f2c0c9e2e1e2e1e1e0e0f1e1caf2e1c0c0c1c9e2c0f1e2d9d9e2e0e0c0c9d2d1dad0c9d0f1d1f2c9c9f0e2c0c0cac0f0c9f0c0d2e2c1f2f1d1e2c0c0d9c0e2c0c0d1f1f0f2cad2c0d2c0d1
00000000000000000000000000000000008f8f8f8f8fa0a1d1f2d0a1a28f8f8f8f8f8f8f8fa0d9d1c0f1d1d2d9a28f8f8f8fe1e0e1c8f1e0d0c9e1c0e28ec98ee2f1d1d0d0e1c1e0e1d2c9dad9e0d9e2e1d2d1f2dacaf2f0f1c0d2d2d9caf1c0e1d2c0f2d1cac9d1c0c0c1d2f2c0e1e2c0cae1f2e2c9daf2cad9cac9d2cad1d0
00000000000000000000000000000000008f8f8f8f8fa08ed0f1d18ea28f8f8f8f8f8f8f8fa0dad9d1f0c0d9daa28f8f8f8fd2e1e1d0f0e2e0e0e1cae0c9cac9e0c0d1cdd1f1c1c0d1d0d0d1f1d1c0c0f1e1d2e2c0e2e1e1e0f1f2c0c0c0c98ef2c9caf1c9e1e0d9c8dac1d2d2c0d2c0d2c9cacad1d0d2c0c0c0c8c0c8d0c0c0
00000000000000000000000000000000008f8f8f8f8fa0d3f2f0f2d3a28f8f8f8f8f8f8f8fb0b1b194db93b1b1b28f8f8f8fd1c8f0c8c0c0cae0e2d0f08ec98ee2c0f2d2f1cac1d2cad1d1c9c0cac9cad1e1e0e0e1d2f1e1e0e0e2c0c0d1c08ec9cac9cac9c8e1e1c0d1c1d0cad1c0d2d0d2cad1d0d0d1f2c8c0f2f0f1d2c8d0
00000000000000000000000000000000008f8f8f8f8fb0b194cf93b1b28f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc0d0c0c0c0c9d2e2c9e1f1e1e0e0e1c0c0d9c9cac1c0d2c0c0c9c0f1c0f1d2e0e0e1c0e1c0f0e0e0e2d2c0c0d08ecaf1c9cac9d2d9c8dac0c1c0d0c0d1d0d0c9d1c9d1d1d2f1f0f1c8f2c8c0c8c0
00000000000000000000000000000000008f8f8f8f8f8f8fb0b1b28f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8ecad2da8ee2e1e0e0e1e2c0e1e0c0c0e1e1e2c0c1f2c9c0f2f2e1e08ed0dae1e0c9e0e1c0c0d2c0c0cad1d2c0c0e0e1e0e0e0d2f1f0f2c0c1c0c0c0f2f1f0d9dad2c0c0c0d1c0c0c0f0c8e0f1e2
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8ff1d0f0f0cac0c9cad9e0c0c9e0e0e0f0d1e0e1d2c1f1caf0c9daf2e1f0e08ecae1e1e1e0f1ca8ed2d9d2c0c0c0d1e0e0e0e0e1f1c8c8c8d2c1c0c9f2c0f0f1d1d9c9d9f0f1c9c8c0c8f1c0e1c8c0
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1caf0cdf1caf18ecd8ee1e2e1e0e0cad0f18ec0c0c1c0f0f2f0d9d98ed1e2d2e2e0e0cad0d1d0f1d9da8e8e8e8e8ee1e0e0e1e0f2f1f0d1f0c1e1e2c0c0f2dad9d2d9f2f1f2cac9d2c0f2c8c0c8f2
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c9d1f2f2f1d0c8c8c8f1e1e0cde1e2c9f0f0d2e2c1d2e2e1e2d2e2e2f2c0d9e1e2e0e0e1c0d2d1d1c0ca8ee1e0e1f2e2e1e0e0d9c9f1dadac1f2f0c0c0e2e28e8e8ee0e0e0e2c0e2c0d2d1c0f1c9
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c18ed9caf08ed2f1f0d1c0e1d0e1c0d1cacdc9f2c0c1c0e18ee1e2e18edc8ed0d0e0c8c8e0d1d0d0d0d1c98ee08ee0d28e8e8ec8f2dac9d9cac1f1caf1e2e1e1c0c0c0e1e0e0e1c8c0c8c0c0c0c8f2
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1cacacac9cae0e0e1e1e2f2c0dad9d2c0d1c0e1e0c1e2e2e1d2c0d9e0e1d9dae2e1e1e0e2d2d1d1d2c0d0e0e08ecdc0f1c0d2d1d9f0d9d9f2c1c0f2f2e1e2e2d1d2c0e0e0e1e0e2e1d1d0c8e1c8c0
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c9c9c9cac9e1e0e0e1e0c0f0d1f2d9e2f1c8d1e1c1c0d9c0e1c0d9c8f1dac9c9f2e1dae1c0f1f0cad2e2e0cde0d1f2e2e1e0cacdf1c0c9d2c1d2f1c0e2e1e0e0cac9cacdc9f1caf2e0c8c0dac0d2
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1cac9cacac9e1e0e0e0e0d1f1f2f2f2f0c8ccc8e2c1c0e1f2f1cdf2f1f0cdf2cdf0d1e1e1f0c9cdc8c0e1e0e0e1d2d2f0e2c9cdc9f0d2f2c0c1c0cdf1e0cde1dacdcad0c0cacaf0d9f1cde1d0c0c9
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1cacac9c9c9e0e0e0e0e2f1f1f0f0d2c0d0c8e2c0c1f1c0c9cac9c9dac8d9d9cac9e2c0e2c9d2f1f2c9e2d1e1e2e1c0f2f1c8c9dacaf1c0c0c1f1d2c0e2e0e0c9c9e1c9d1c0cdc9c9c0c8e0cac0cd
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c9cac9cacae1e0e1e0e1dad1f1f2d9d2f2c0f0f2c1e2d2c9cdc9e2c0cacdcaf2d2cdc9f1cdcac9d2c0cdd9f2d0c9e1c0e2e1c8e2f0d1e1e1c1caf2c0cad2d1d2c0c0c9cdc9c0d1f2d1c0c8cdd2d0
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e0e0e1e1e2c9c9c9d9d9e0e0e1e0d2c0c0d2c0c0c1c0f2d1f0cac0e1e2e1e0c0c9f1f0d2c9f0c0c0d0daf1d1c0cac0d1c8cde1d2cd8ee0e1c1cdf0c0c0c0d2cac0d2e1c0e2f2cdc0c0cdd1cac0d1
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e18e8e8ee2c9cdf2cdcae0e0e0e0e1c0d2f1f0d2c1c0f2f1d2f2e1e1e0e0e1f1f2d1c0c9c0c0f2c0d1d2c0d2d2f2e2c0d0c8e0c0e2e1e1e2c1c9f1c0cdc9c0cdc9d1e2c0c0c0f1d2c8c0d2c0d2c0
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c08ecc8ed0d9f0f0f1c9d1e0cce0e0d2f0ccf1e2c1e2e2f1c8c0dad9e2e2c9d2e2f1d1d9e0e0cae0e2e2e1e0e0e1e1d1d2f2d2e1e0c8e1e2c1c9c9caf1c0d0e1e0e0c8c0c8cac9c9d1d2d2c0e1d1
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d08ecb8ed1cacdf1cdcae0e0e0e0e1c0f2f0f2c0c1c0f1ccd2c0c0c0cce1c9e28ecc8ec0e1d9cccae1e0e1ccc8e0e28ecc8ec9d18ecc8ed1c1f1ccf0d0ccd1e0cce0d1ccf1caccc0c0ccc0d0ccc0
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d1d2f0f1c0cadac9c9cae1e1e0e0e0e2c0c0e2c0c1e2c8d1f1f2d9e2c0c9cac0d1d0f2d2c0c9f1d9e2e0c8e0e1e0f2f1f0c9cacaf2f1d2c9c1d2f0c0d1f1c0e1e0e2c8f1c8c0c0f1d1c0f2e0e1d0
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8fc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
__sfx__
010100000514004100021000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000100000b1400b1300e0300d030016100c4000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
00010000167400c740107300075000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
01010000180201c0301f04022050290502d00003000070001d0000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000
0101000023620217101c7102c7002c700197000e7001b7001d7201d7101d7101c710187001670014700057000b7000c7100c7100b7100b7100a710027000d7000170001700017000170001700017000170001700
010600002761323600215202352025530295420160001600051000110001100041000710001100031000110002100011000210001100011000110001100011000110001100011000110001100011000110001100
000100000042000420004200042000420004000040017400114000d40000420004200042000420004200042000420004000040000400004000040000400004000740007400074000640005400004000040000400
010200001f130001000a1001d1301b13000100001001913000100001001f13000100001001d1301d130001001a1300010005100181301613000100001001413000100001001a1300010000100181301813000100
000200002a63029630296000f600106000000000000000001f6201e6201d6000000000000000001c6001d6001862017610166000000025600256002660000000116000f6100f6002f60000000000000000005600
010100001b620201201a1301312015100131001310011100111000910007100051000310001100001000510004100041000310003100031000310003100021000210000100001000010000100001000010000100
0001000025130241202e12029120231201d1202712038110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
010400002615026150031002015020150031001815018150031001315013150031000310006150051500515005150041500414003140031400313003130031200211003100031000310003100030000300003000
000100001e74020740237302971030730037000370003700037000370003700037000370003700037000370003700037000370003700037000370003700037000370003700037000370003700037000370003700
000500002b73028730247302873030730357403774001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700017000170001700
000300001b5401b5501d55020000220000300014100091001e1000010000100001000e1000e1000e1000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000300002454000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003200003c7453c7003c7003c7003c7003c7003c7003c7053c7003c7003c7003c7003c7003c7003c7003c7003c7003c7003c7003c700000003c70000000000000000000000000000000000000000000000000000
000100000863038000006001560001600006000060000600006000550031640006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
010900000c1101011013120181201a130181301c1401f140241400310003100031002615003100281502814028132281222811228112031000310003100031000310003100031000310003100031000310003100
0101000036050320402e0402b0302703023020200201d0201b02018010160101401012010100100f0100e0100c0100b0100a0100901008010070100501005010040200402005020060200a0200f0201403019040
0104000011522005021353200502155321c50217542175021954219552195521b5521b5521b5521d5521d5521d5521d5520050200502285020050200502005023050200502005020050200502005020050200502
000200003c4503c450306002f6002f6003341031450254402c4402b4402b430004301d4202a4202541028410264002140020400004001c4000040020400204000e4001c4001a4000040000400004000040000400
00010000066500475005650057400663008630216301c62016720146100f7100d6100a7100861007620077200762013600126000f6000d6000c600086000c6000d60014600196000060000600006000060000600
010100002d650226502c7572c7572c7572c7572c7572c7472b7472a747297372873727737257372473722727207271e7171b717197171671713717107170d7170c7170a717087170771706717057170571705707
000100000454004540055300a52010510185001150000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000200002c0331d0032c023180032c033140032c023100032c0331d0032c023180032c033140032c023100032c0331d0032c023180032c033140032c023100032c0331d0032c023180032c033140032c02310003
000100001356013550135401354014540155301753018520195101e51022510255102f5100a1400a1300d0300c030006100050000500005000050000500005000050000500005000050000500005000050000000
000300000043000430000000000000000000000000000000000000000000000000000000000000004300000000000004300043000430000000000000430004300000000000000000000000000000000000000000
00030000374303042130400324203c4023c4023c4023c405374303042130400324200040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
413200001d0441d0221d0221d0121d015010001b0441b05218041180221802218012180150100016034180221d0541d0221d0221d0121d015010001b04418041180221b012180121801218015010001402416024
413200001d0441d0221d0221d0121d015010001b0441b0321b0341b0221b0121b0121b0150100016034180221d0441d0221d0221d0121d015010001b0441b0521b0321d022180141801218015010001403416022
413200001d0441d0221d0221d0121d01501000200441b0311b0341b0221b0121b0121b0150100016034180221d0341d0221d0221d0121d015010001b0341b0421b0441d0221b0141b0121b0121b0151902418012
41320000160441602216022160121601501000140441602218034180221801218012180150100016034180221b0441b0221b0221b0121b01501000160441b0441d0441d0321d0321801118012180121801218015
793200001d1441d1221d1221d1121d115011001b1441b15218141181221812218112181150110016134181221d1541d1221d1221d1121d115011001b14418141181221b112181121811218115011001412418124
793200001d1441d1221d1221d1121d115011001b1441b1321f1311f1221f1121f1121f11501100201341f1221d1441d1221d1221d1121d115011001b1441b1521b1321b1321b1141b1121b114011001613418122
793200001d1441d1221d1221d1121d11501100201441b1311b1341b1221b1121b1121b1150110016134181221d1341d1221d1221d1121d115011001b1341b1421b1441d1221b1111b1121b1121b1151912418144
79320000161441612216122161121611501100141441612218134181221811218112181150110016134181221b1441b1221b1221b1121b11501100161441b1441d1441d1321d1321811118112181121811218115
c1120000000000000000000000000000000000245422453218542185321d5421d5322454224532225422253220542205321f5421f53218542185321d5421d5321d5221d5221d5121d5121d5101d5101d5101d515
c112000000000000000000000000000000000020532205221473214722197321972220732207221f7321f7221b7321b722167321672214732147221a7321a7221a7221a7121a7121a7121a7101a7101a71500705
a91200000000000000000000000000000000000d1340d1300d1300d1300d1200d1200d1100d1150c1340c1300c1300c1300c1200c1200c1100c1150a1340a1300a1300a1220a1220a1220a1200a1100a1100a115
2b0e180000000000000000000000000000000000000000000000000000000000000019542195321d5421d532205422053225542255321b5421b5321f5421f5320c50000000000000000000000000000000000000
110e18000000000000000000000000000000000000000000000000000000000000001154211532145421453218542185321d5421d532135421353216542165321b5001b5001f5001f50021500215002150021500
490e18000000000000000000000000000000000000000000000000000000000000000d4420d4320d4320d4320c4220c4200d4300d4350f4420f432114320f4320d4000d4000f4000f40011400114001140011400
2b160500225422252227542275322751229500295002950029500295000c5050c5050c5050c5050c5050c50500000000000000000000000000000000000000000000000000000000000000000000000000000000
2b1400002954229532295222952229512295122951029510295102951500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111605001b5421b5321f5421f5321f512215002150021500215002150021500215002150021500045050450504505045050450504505000000000000000000000000000000000000000000000000000000000000
111400002154221532215222152221512215122151221512215122151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
491605000d4220d4200f4300f4300f430114001140011400114001140011400114001140011400114001340013400134000740007400074000000000000000000000000000000000000000000000000000000000
491400001144011440114301143011430114221142211412114121141500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
193200000222002210022150120002220022100221504200012200121001215002000122001210012150320002220022100221502200022200221002215042000122001210012150120001220012100121503200
193200000822008210082150120008220082100821504200072200721007215002000722007210072150420008220082100821501200082200821008215042000822008210082150120008220082100821504200
193200000522005210052150500005220052100521501200072200721007215070000722007210072150020005220052100521505000052200521005215012000522005210052150800004220042100421500200
d13200000123001220012250121501232012220121505200042300422004225042150423204222042150420001230012200122501215012320122201215052000223002220022250221500232002220021500215
193200000822008210082150120008220082100821504200072200721007215002000722007210072150320008220082100821501200082200821008215042000722007210072150020007220072100721503200
193200000122001210012150100001220012100121501200012200121001215010000122001210012150120001220012100121501000012200121001215012000022000210002150000000220002100021501200
d13200000523005220052250521505232052220521505215052300522005225052150523205222052150521505230052200522505215052320522205215052150423004220042250421504232042220421504215
193200000122001210012150100001220012100121501200012200121001215010000122001210012150120001220012100121501000012200121001215012000122001210012150100001220012100121501200
193200000822008210082150120008220082100821504200082200821008215012000822008210082150420008220082100821501200082200821008215042000822008210082150120008220082100821504200
d13200000523005220052250521505232052220521505200052300522005225052150523205222052150520005230052200522505215052320522205215052000523005220052250521505232052220521505200
__music__
01 7f3e3f44
01 203e3f44
00 213d3f44
00 223a3f44
00 233b3c44
00 243a3f44
00 253d3f44
00 26363f44
00 273b3c44
00 413a3f44
02 41383944
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 2b2c2d44
00 2e303244
04 2f313344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
04 28292a44

