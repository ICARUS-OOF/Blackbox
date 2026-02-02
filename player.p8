pico-8 cartridge // http://www.pico-8.com
version 42
__lua__


---ARROW KEYS - MOVE
---X - SHOOT
---Z - SWAP WEAPONS

isLoadingNewLevel = false
currentLevel = 0

player = {
  x = 64, -- initial x position (center of screen)
  y = 64, -- initial y position (center of screen)
  speed = 1, -- movement speed
  sprite = 1, -- sprite id,
  flipX = false,
  flipY = false,
  dirX = 1,
  dirY = 0,
  currentSelectedWeapon = 0
}

portals = {
  {x = 120, y = 5, targetLevel = 1},
  {x = 490, y = 20, targetLevel = 0}
}

footstepSfxOffset = 4;

-- the initialization function
function player_init()
	reload(0x0000, 0x0000, 0x5000, "main.p8")
  music(0, true)

  if (currentLevel == 0) then
    player.x = 64
    player.y = 64
  elseif (currentLevel == 1) then
    player.x = 450
    player.y = 68
  end

  event_cooldown = 160 + rnd(300)
  current_event = 0
end

function playfootstep()
  if (footstepSfxOffset > 4) then
    footstepSfxOffset -= 4

    sfx(8)
  end

  footstepSfxOffset += 1
end


-- Define a list to store projectiles
projectiles = {}

-- Function to create a projectile
function spawn_projectile(x, y, dx, dy, lifetime)
  add(projectiles, {x = x, y = y, dx = dx, dy = dy, lifeLeft = lifetime})
end

-- Function to update all projectiles
function update_projectiles()
  for i=#projectiles,1,-1 do
    local p = projectiles[i]
    
    p.x += p.dx
    p.y += p.dy
    
    
    if p.lifeLeft <= 0 then
      del(projectiles, p)
    else
      p.lifeLeft -= 1
    end
  end
end

function draw_projectiles()
    for p in all(projectiles) do
      if (player.currentSelectedWeapon == 0) then
        spr(231, p.x, p.y, 2, 2, false)
      elseif (player.currentSelectedWeapon == 1) then
        spr(150, p.x, p.y, 1, 1, false)
      elseif (player.currentSelectedWeapon == 2) then
        spr(187, p.x, p.y, 2, 2, false)
      end
    end
end

function draw_portals()
  for p in all(portals) do
    spr(201, p.x, p.y, 2, 2, false)
  end
end

function LoadNewLevel(targetLevelIndex)
  currentLevel = targetLevelIndex
  isLoadingNewLevel = true
  loadingscreen_init()
end

function update_portals()
  for p in all(portals) do
    if (player.x >= p.x + 0 and player.x <= p.x + 12 and player.y + 0 >= p.y and player.y <= p.y + 12) then
      LoadNewLevel(p.targetLevel)
    end
  end
end


function random_event(r)
  current_event = r
  
  if (r == 1) then
    sfx(12)
  elseif (r == 2) then
    blackout_countdown = 60
  end
end


function player_update()
  
  map()
  

  if (btn(2)) then
    player.y = player.y - player.speed
    player.sprite = 2;
    flipY = false;
    player.dirX = 0
    player.dirY = -1
    playfootstep()
  end
  
  if (btn(3)) then
    player.y = player.y + player.speed
    player.sprite = 2;
    flipY = true;
    player.dirX = 0
    player.dirY = 1
    playfootstep()
  end
  
  if (btn(0)) then
    player.x = player.x - player.speed
    player.sprite = 1;
    flipX = true;
    player.dirX = -1
    player.dirY = 0
    playfootstep()
  end
  
  if (btn(1)) then
    player.x = player.x + player.speed
    player.sprite = 1;
    flipX = false;
    player.dirX = 1
    player.dirY = 0
    playfootstep()
  end
  
  if btnp(🅾️) then
    player.currentSelectedWeapon += 1

    if (player.currentSelectedWeapon > 2) then
      player.currentSelectedWeapon = 0
    end
  end


-- spawn a projectile when button x pressed
  if btnp(❎) then

      bullet_speed = 0
      bullet_lifetime = 60
      
      if (player.currentSelectedWeapon == 0) then
        sfx(9)
        bullet_speed = 1
        bullet_lifetime = 60
      elseif (player.currentSelectedWeapon == 1) then
        sfx(10)
        bullet_speed = 2
        bullet_lifetime = 50
      elseif (player.currentSelectedWeapon == 2) then
        sfx(11)
        bullet_speed = 0.7
        bullet_lifetime = 30
      end
      
      spawn_projectile(player.x, player.y, player.dirX * bullet_speed, player.dirY * bullet_speed, bullet_lifetime) -- going right from center)
  end

  update_projectiles()
  update_portals()

  if (event_cooldown <= 0) then
    random_event(flr(rnd(2)) + 1)
    event_cooldown = 160 + rnd(300)
  end

  event_cooldown -= 1
end

-- the draw function (rendering)
function player_draw()
  map()
  -- spr(1, 63, 63);
  -- flip();
  spr(player.sprite, player.x, player.y, 1, 1, flipX, flipY);

  draw_projectiles()
  draw_portals()

  camera(player.x - 64, player.y - 64)

  print("current weapon:", player.x - 64, player.y - 64, 7)
  if (player.currentSelectedWeapon == 0) then
    spr(97, player.x - 0, player.y - 67, 2, 2)
  elseif (player.currentSelectedWeapon == 1) then
    spr(164, player.x - 0, player.y - 67, 2, 2)
  elseif (player.currentSelectedWeapon == 2) then
    spr(158, player.x - 0, player.y - 67, 2, 2)
  end

  if (current_event == 1) then
    print("current event: scary noise", player.x - 64, player.y + 54, 7)
  elseif (current_event == 2) then
    if (blackout_countdown > 0) then
      if (rnd(1) <= 0.5) then
        rectfill(player.x - 64, player.y - 64, player.x + 64, player.y + 64, 0)
      end
      blackout_countdown -= 1
    end

    print("current event: blackout", player.x - 64, player.y + 54, 7)
  end
end

function _init()
	player_init()
end

function _update()
	player_update()
end

function _draw()
	player_draw()
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
