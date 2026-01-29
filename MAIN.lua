-- Global variables for player
player = {
  x = 64, -- Initial x position (center of screen)
  y = 64, -- Initial y position (center of screen)
  speed = 1, -- Movement speed
  sprite = 1 -- Sprite ID
}

-- The initialization function
function _init()
  -- You can add any other startup code here
end

-- The update function (game logic)
function _update()
  -- Move up
  if (btn(2)) then
    player.y = player.y - player.speed
  end
  -- Move down
  if (btn(3)) then
    player.y = player.y + player.speed
  end
  -- Move left
  if (btn(0)) then
    player.x = player.x - player.speed
  end
  -- Move right
  if (btn(1)) then
    player.x = player.x + player.speed
  end
end

-- The draw function (rendering)
function _draw()
  cls() -- Clear the screen

  -- Draw the player sprite at the current x and y coordinates
  circfill(player.x, player.y, 4, 1)
end