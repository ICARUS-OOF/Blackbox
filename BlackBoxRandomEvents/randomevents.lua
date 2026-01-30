--==================================================
-- blackbox event demo (pico-8)
-- 3 events:
-- 1) echoing footsteps
-- 2) item betrayal
-- 3) blackout shift
--==================================================

-- ---------- helpers ----------
function rnd_int(a,b) -- inclusive
  return flr(rnd(b-a+1))+a
end

function clamp(v,a,b)
  if v<a then return a end
  if v>b then return b end
  return v
end

-- ---------- game state ----------
function _init()
  -- simple tile map: 0=empty, 1=wall
  -- (feel free to replace with your map())
  w=32 h=32
  grid={}
  for y=1,h do
    grid[y]={}
    for x=1,w do
      local wall=false
      if x==1 or y==1 or x==w or y==h then wall=true end
      -- add some interior walls
      if (x==10 and y>6 and y<26) or (y==18 and x>12 and x<28) then wall=true end
      grid[y][x]=wall and 1 or 0
    end
  end

  p={
    x=16,y=16,
    spd=1,
    lastx=16,lasty=16,
    moved=false,
    hp=10
  }

  inv={
    -- a "fake" item can be created by events
    heal=1,
    key=1
  }

  msg=""
  msg_t=0

  -- event manager
  ev={
    active=false,
    name="",
    t=0,
    dur=0,
    cooldown=120,
    cd=120,
    data={}
  }

  -- blackout visual
  blackout=0 -- 0..1
  -- for "layout shift" illusion
  shift_mode=false

  -- for footsteps tracking
  step={
    level=0,   -- intensity
    last_move_t=0,
    spawn_armed=false,
    ghost_x=0,
    ghost_y=0
  }
end

-- ---------- UI ----------
function set_msg(s, t)
  msg=s
  msg_t=t or 90
end

function draw_ui()
  rectfill(0,0,127,7,0)
  print("hp:"..p.hp.."  heal:"..inv.heal.."  key:"..inv.key, 2,1,7)

  if msg_t>0 then
    rectfill(0,120,127,127,0)
    print(msg, 2,121,7)
  end

  if ev.active then
    print("event: "..ev.name, 2, 9, 8)
  else
    -- hint for testing
    print("z=heal  x=force event", 2, 9, 6)
  end
end

-- ---------- collision ----------
function is_wall(tx,ty)
  if tx<1 or ty<1 or tx>w or ty>h then return true end
  local gx,gy=tx,ty
  if shift_mode then
    -- simple illusion: swap some walls in shift mode
    -- (you can replace this with real room changes)
    if gx==12 and gy>10 and gy<22 then
      return true
    end
  end
  return grid[gy][gx]==1
end

function try_move(dx,dy)
  local nx=p.x+dx
  local ny=p.y+dy
  if not is_wall(nx,ny) then
    p.x=nx
    p.y=ny
    return true
  end
  return false
end

-- ---------- event manager ----------
function start_event(name, dur)
  ev.active=true
  ev.name=name
  ev.t=0
  ev.dur=dur
  ev.data={}
end

function end_event()
  ev.active=false
  ev.name=""
  ev.t=0
  ev.dur=0
  ev.cd=ev.cooldown
  ev.data={}
end

function roll_random_event()
  -- pick one of 3
  local r=rnd_int(1,3)
  if r==1 then
    -- echoing footsteps
    start_event("echoing footsteps", 300)
    step.level=0
    step.spawn_armed=false
    set_msg("...footsteps behind you...", 120)
    -- optional: sfx(0)
  elseif r==2 then
    -- item betrayal
    start_event("item betrayal", 180)
    -- create a fake heal (player thinks they have more)
    ev.data.fake_added=true
    inv.heal += 1
    set_msg("you found a heal.", 90)
  else
    -- blackout shift
    start_event("blackout shift", 240)
    blackout=0
    shift_mode=false
    set_msg("lights out.", 90)
  end
end

function update_event()
  if not ev.active then
    if ev.cd>0 then
      ev.cd -= 1
    else
      -- random chance to trigger when cooldown done
      if rnd(1) < 0.01 then
        roll_random_event()
      end
    end
    return
  end

  ev.t += 1

  if ev.name=="echoing footsteps" then
    update_echo_footsteps()
  elseif ev.name=="item betrayal" then
    update_item_betrayal()
  elseif ev.name=="blackout shift" then
    update_blackout_shift()
  end

  if ev.t>=ev.dur then
    -- clean up per-event
    if ev.name=="item betrayal" then
      -- if still has fake heal, it vanishes at end
      if ev.data.fake_added then
        inv.heal = max(0, inv.heal-1)
        set_msg("something feels...missing.", 120)
      end
    end
    if ev.name=="blackout shift" then
      blackout=0
      shift_mode=false
    end
    end_event()
  end
end

-- ---------- event: echoing footsteps ----------
function update_echo_footsteps()
  -- intensity grows when moving
  if p.moved then
    step.level = clamp(step.level + 0.02, 0, 1)
    step.last_move_t = 0
  else
    step.last_move_t += 1
    -- if player stops too long while intense => danger
    if step.level > 0.6 and step.last_move_t > 60 then
      step.spawn_armed=true
    end
    -- intensity slowly decays if not moving
    step.level = clamp(step.level - 0.01, 0, 1)
  end

  -- scary audio cue (simple: use print + screen shake vibe)
  -- you can replace with sfx patterns:
  -- if (ev.t%30==0 and step.level>0.3) sfx(1)

  -- if armed and player still isn't moving => "spawn"
  if step.spawn_armed and step.last_move_t > 90 then
    -- spawn a "ghost hit" behind the player
    local bx=p.x-(p.x-p.lastx)
    local by=p.y-(p.y-p.lasty)
    -- if that spot is wall, just use player's tile
    if is_wall(bx,by) then bx=p.x by=p.y end

    step.ghost_x=bx
    step.ghost_y=by
    p.hp=max(0,p.hp-2)
    set_msg("DON'T STOP.", 120)
    step.spawn_armed=false
    step.level=0.2
  end
end

function draw_echo_footsteps()
  -- draw a faint "shadow" behind player when intensity high
  if step.level>0.4 then
    local sx=p.x+(p.x-p.lastx)
    local sy=p.y+(p.y-p.lasty)
    circfill(sx*4, sy*4, 2, 5)
  end

  -- flash the ghost hit tile briefly
  if ev.t%20<5 then
    rectfill(step.ghost_x*4-2, step.ghost_y*4-2, step.ghost_x*4+2, step.ghost_y*4+2, 8)
  end
end

-- ---------- event: item betrayal ----------
function update_item_betrayal()
  -- nothing continuous; betrayal happens when player uses heal
  -- we just keep the state here.
end

function use_heal()
  if inv.heal<=0 then
    set_msg("no heal.", 60)
    return
  end

  inv.heal -= 1

  -- if this event is active, sometimes the heal was never real
  if ev.active and ev.name=="item betrayal" then
    if rnd(1) < 0.7 then
      set_msg("...it was empty.", 120)
      -- OPTIONAL: add small penalty to make it scary
      p.hp=max(0,p.hp-1)
      return
    end
  end

  p.hp=min(10, p.hp+3)
  set_msg("+hp", 30)
end

-- ---------- event: blackout shift ----------
function update_blackout_shift()
  -- fade to dark then back
  if ev.t < 60 then
    blackout = clamp(blackout + 0.02, 0, 1)
  elseif ev.t == 60 then
    -- at peak darkness: shift room "layout"
    shift_mode=true
    -- also "teleport" player slightly to disorient
    local tx=p.x+rnd_int(-2,2)
    local ty=p.y+rnd_int(-2,2)
    if not is_wall(tx,ty) then
      p.x=tx p.y=ty
    end
    set_msg("where am i...?", 120)
  elseif ev.t > 120 then
    blackout = clamp(blackout - 0.02, 0, 1)
  end
end

function draw_blackout_overlay()
  if blackout<=0 then return end
  -- cheap darkness effect: draw stipple overlay
  -- stronger blackout => more pixels covered
  local d=blackout
  for y=0,127,2 do
    for x=0,127,2 do
      if rnd(1) < d then
        pset(x,y,0)
      end
    end
  end
end

-- ---------- input & update ----------
function _update60()
  -- message timer
  if msg_t>0 then msg_t-=1 end

  -- store last position each frame
  p.lastx=p.x
  p.lasty=p.y
  p.moved=false

  -- movement
  local dx=0 dy=0
  if btn(0) then dx=-p.spd end
  if btn(1) then dx= p.spd end
  if btn(2) then dy= p.spd end
  if btn(3) then dy=-p.spd end

  if dx~=0 or dy~=0 then
    if try_move(dx,0) or try_move(0,dy) then
      p.moved=true
    end
  end

  -- use heal
  if btnp(4) then -- z
    use_heal()
  end

  -- force event (testing)
  if btnp(5) then -- x
    if not ev.active then
      roll_random_event()
    else
      end_event()
      set_msg("event cancelled.", 60)
    end
  end

  update_event()
end

-- ---------- draw ----------
function _draw()
  cls(0)

  -- draw map
  for y=1,h do
    for x=1,w do
      if is_wall(x,y) then
        rectfill(x*4-4,y*4-4,x*4-1,y*4-1,1)
      end
    end
  end

  -- player
  rectfill(p.x*4-3,p.y*4-3,p.x*4-1,p.y*4-1,7)

  -- event visuals
  if ev.active and ev.name=="echoing footsteps" then
    draw_echo_footsteps()
  end

  if ev.active and ev.name=="blackout shift" then
    draw_blackout_overlay()
  end

  draw_ui()
end
