pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

-- main game code
-- all the game's core logic is contained here for easy testing.

-- =========================
-- ahmad: simple ui helpers
-- =========================
local function _str_px_w(s) return #s*4 end
local function _print_center(t,y,c,sh)
 local x=64-(_str_px_w(t)/2)
 if sh then print(t,x+1,y+1,sh) end
 print(t,x,y,c)
end

-- for non-play screens, make sure ui is visible (no camera offset, default palette)
local function _ui_begin()
 camera(0,0)
       -- reset palette remaps to default
      -- reset transparency to default
end

-- =========================
-- ahmad: game states
-- =========================
state_menu     = 0
state_instr    = 1
state_play     = 2
state_gameover = 3
game_state = state_menu

-- optional shared flag: other tabs can set game_over=true
game_over = false

-- ahmad: flexible game-over check (doesn't assume other tabs' fields)
local function _maybe_check_gameover()
 if game_over then return true end
 if player then
  if player.dead or player.is_dead then return true end
  if player.hp and player.hp<=0 then return true end
  -- stamina-based loss (only if your code uses it)
  if player.stamina and player.stamina<=0 and type(player_is_falling)=="function" and player_is_falling() then
   return true
  end
 end
 return false
end

-- reset to fresh run (safe: call your init again)
local function _soft_reset()
 _init()
 game_state = state_menu
 game_over = false
end

function _init()    
 custom_palette() --caitlyn carter
 --reset_pal() --rashad tubbs
 
 player_init() --caitlyn carter
 
 camera_init() --rashad tubbs
 
 audio_init() --ahmad thomas
 ui_init() --ahmad thomas

 -- start at menu each boot
 game_state = state_menu
 game_over = false
end

--! main game loop (updates)
function _update()
 if game_state == state_menu then
  if btnp(5) then -- ❎
   game_state = state_instr
  end

 elseif game_state == state_instr then
  if btnp(5) then
   game_state = state_play
  end

 elseif game_state == state_play then
  -- ============== gameplay only ==============
  -- caitlyn carter
  player_update()
  player_hook_update()
  player_anim()
  obstacle_update()
  particles_update() 
  r_update()

  -- rashad tubbs
  camera_update()

  if _maybe_check_gameover() then
   game_state = state_gameover
  end

 elseif game_state == state_gameover then
  if btnp(5) then
   _soft_reset()
  end
 end
end

--! main game loop (draws)
function _draw()
 cls(0) -- clear the screen to black

 if game_state == state_menu then
  _ui_begin()
  _print_center("time to escape the cave", 42, 7, 0)
  _print_center("press ❎ to start", 62, 6, 0)

 elseif game_state == state_instr then
  _ui_begin()
  _print_center("how to play", 18, 7, 0)
  _print_center("⬅️ move left   ➡️ move right", 40, 6, 0)
  _print_center("❎ fire grapple / latch", 50, 6, 0)
  _print_center("⬆️/⬇️ climb rope (hold)", 60, 6, 0)
  _print_center("speed kills!", 76, 8, 0)
  _print_center("press ❎ to begin", 96, 7, 0)

 elseif game_state == state_play then
  --! level and player drawing
  -- draw your level map here.
  map(0, 0)
  
  -- caitlyn carter
  player_draw()
  obstacle_draw()
  particles_draw()
  r_draw() 
  
  camera_draw() --rashad tubbs 

  -- ユか⬆️⌂ユかかた MY ADD: draw UI in screenspace (no camera logic changes)
  camera(0,0)
  if player and player.stamina then
   ui_draw_stamina(player.stamina, 100)
  else
   ui_draw_stamina(100, 100)
  end
  -- restore world camera so the next frame starts correct
  camera(cam_x, cam_y)

 elseif game_state == state_gameover then
  _ui_begin()
  _print_center("game over", 52, 8, 0)
  _print_center("press ❎ to retry", 70, 7, 0)
 end
end

-->8
--camera--
--written by rashad tubbs

--!init_camera() runs once when the game starts.
function camera_init()
	--! camera setup
 -- initializes the camera variables to their starting values.
 cam_x = 0
 cam_y = 488
 
 --! starting camera position
 -- moves the camera to the player's starting position at the beginning.
 cam_y = player.y - 60
 cam_y_bottom = 384
 

 camera(cam_x, cam_y)
end

function camera_draw()
	-- applies the calculated camera position for drawing the world.
 camera(cam_x, cam_y)
	-- resets the camera to a fixed position for drawing ui elements.
 --camera(0, 0)
end

--!update_camera() runs every frame to follow the player.
function camera_update()
 -- this moves the camera smoothly, keeping the player slightly above the center of the screen.
 -- you can adjust '60' to change the player's vertical position.
 cam_y = move(player.y - 60, cam_y, 0.2)
 
 -- this prevents the camera from scrolling below the starting point.
 cam_y = min(cam_y, cam_y_bottom)
 
 -- the camera in hook mountain is fixed on the x-axis.
 cam_x = 0
end

--! helper function for smooth movement
-- the move function smoothly interpolates a value from 'rx' towards 'mx'
-- 'c' is the speed of the interpolation.
function move(rx,mx,c)
 c=c and c or 0.7
 if abs(rx-mx)<1 then
     return mx
 end
 
 return (1-c)*mx+rx*c
end
-->8
--player movement--
--written by caityln carter

anims = {
	idle = {
		w=1, 
		h=2,
		frames={65, 66},
		speed = 0.5
	},
	walking = {
		w=1, 
		h=2, 
		frames = {71, 78},
		speed = 0.07
		},
	running = {
		w=2, 
		h=2, 
		frames = {96, 110},
		speed = 0.5
	},
	crouching = {
		w=1, 
		h=2, 
		frames = {69},
		speed = 0.5
	},
	climbing = {
		w=1, 
		h=2, 
		frames = {132, 136},
		speed = 0.2
	},
	climbing_idle = {
		w = 1,
		h = 2,
		frames = {133},
		speed = 0.5
	},
	falling = {
		w=1, 
		h=2, 
		frames = {67},
		speed = 0.5
	},
	landed = {
	w = 1,
	h = 2,
	frames = {68, 69},
	speed = 0.5
	}
}

states = {
	none,
	idle = {anim = anims.idle, name = "idle"},
	walking = {anim = anims.walking, name = "walking"},
	running = {anim = anims.running, name = "running"},
	crouching = {anim = anims.crouching, name = "crouching"},
	climbing = {anim = anims.climbing, name = "climbing"},
	climbing_idle = {anim = anims.climbing_idle, name = "climbing_idle"},
	landed = {anim = anims.landed, name = "landed"},
	falling = {anim = anims.falling, name = "falling"},
    -- hook states as proper state tables (so player.state.anim exists)
    h_throw = { anim = anims.falling, name = "hook_throw" },
    wait_move = { anim = anims.falling, name = "wait_move" },
    h_move = { anim = anims.falling, name = "hook_move" },
    h_stop = { anim = anims.climbing_idle, name = "hook_stop" },
    s_climb = { anim = anims.climbing, name = "s_climb" },
    h_get  = { anim = anims.falling, name = "hook_get" }

}


gravity = 0.3
acceleration = 0.3
friction = 0.9
k_dx = 0
hook_p = 3.1       -- pull strength
hook_length = 42   -- max hook rope length

---

function player_init()
	player = {
		sprite = 65,
		x = 10,
		y = 480,
		w = 5,
		h = 16,
		flp = false,
		dx = 0,
		dy = 0,
		max_dy = 1.5,
		acc = 0.7,
		state = states.none,
		anim = anims.idle,
		anim_timing = 0,
		stamina = 100,
		stamina_rate = 1,
		on_floor = false,
		k_timer = 0,
        hooking = false,
        hook_x = 0,
        hook_y = 0,
        hook_angle = 0,
        hooking_state = nil
	}
end


function player_draw()
    spr(player.sprite, player.x, player.y, 1, 2, player.flp)
    
    if player.hooking then
        local px = player.x + player.w/2
        local py = player.y + player.h/2
        line(px, py, player.hook_x, player.hook_y, 6)
        circfill(player.hook_x, player.hook_y, 1, 7)
    end
end



function player_update()
	--physics--
 -- if grappling, skip normal controls
 if player.hooking and player.hooking_state == "pulling" then
     return
 end

	--checks block under player
	if map_collision(player, "down", 0) then
		player.on_floor = true
	else
		player.on_floor = false
	end
	
	--changes dy based on if player is on floor
	if player.on_floor == false then
		player.dy += gravity
	else
		player.dy = 0
	end	
	
	--controls--
	--normal sufrcaes
	if map_collision(player, "down", 2) != true then
			if btn(➡️) 	
		and  player.state != states.crouching then
			player.dx = 1.5
			player.state = states.walking
			player.on_floor = true
			player.flp = false
		elseif btn(⬅️) 
		and not (player.state == states.crouching) then
			player.dx = -1.5
			player.state = states.walking
			player.on_floor = true
			player.flp = true
		elseif btn(⬇️) 
		and not (player.state == states.walking) 
		and player.on_floor == true then
			player.state = states.crouching
		
		--climbing
		elseif btn(⬆️)
		and (map_collision(player, "left", 1)
		or map_collision(player, "right", 1)) 
		and player.stamina > 0 then
	 	player.dy = -0.5
	 	player.state = states.climbing
		 player.on_floor = false
		elseif btn(⬇️)
		and not map_collision(player, "down", 0)
		and (map_collision(player, "left", 1)
		or map_collision(player, "right", 1)) 
		and player.stamina > 0 then
	 	player.dy = 0.5
	 	player.state = states.climbing
		 player.on_floor = false
		 
		--climbing idle
		elseif (map_collision(player, "left", 1)
		or map_collision(player, "right", 1))
		and not map_collision(player, "down", 0) 
		and player.stamina > 0 
		and player.state == states.climbing then
			player.dy = 0
			player.state = states.climbing_idle
			player.on_floor = false
		
		--idle
		else
			player.dx = 0
			player.state = states.idle
		end
	else
	
		--slippery surfaces
		player.dx *= friction
		if btn(⬅️) then
			if player.dx > -2.5 then
   	player.dx-=player.acc
   end
   player.state=states.walking
   player.flp=true
  elseif btn(➡️) then
  	if player.dx < 2.5 then
   	player.dx+=player.acc
   end
   player.state=states.walking
   player.flp=false
  else
 		player.state = states.idle
 	end
 	
 	if map_collision(player, "left", 0)
 	or map_collision(player, "right", 0) then
 		player.dx *= -1
 	end
 end
 
 
	player.y += player.dy
	
	
	--stamina--
	if player.state == states.climbing
	and player.stamina > 0 then
		player.stamina -= player.stamina_rate
	elseif player.on_floor == true
	and player.stamina < 100 then	
		player.stamina += player.stamina_rate
	end
	
	if player.stamina == 0 then
		player.state = states.falling
	end
	
	--collision--
	--make sure flag 0 is checked for all platforms
	--check collision up and down
	-- vertical movement
	if player.dy > 0 then
  -- moving down
  if map_collision(player, "down", 0) then
      player.on_floor = true
      player.dy = 0
      -- snap to tile grid
      player.y = flr((player.y + player.h) / 8) * 8 - player.h
      player.state = states.idle
  else
      player.on_floor = false
      player.state = states.falling
  end
	elseif player.dy < 0 
	and player.state != states.climbing then
  -- moving up
  if map_collision(player, "up", 0) then
      player.dy = 0
      player.y = flr(player.y / 8) * 8 - 1
  end
	end

		
		--climbing collision
		if player.dy < 0
		and map_collision(player, "up", 0)
		and player.state == states.climbing then
			player.on_floor = false
			player.state = states.climbing_idle
			player.dy = 0
			player.y += (player.y)%8 - 1
		end
	
	--check collision left and right
	if player.dx < 0 then
		if map_collision(player, "left", 0) then
			player.dx = 0
		end
	elseif player.dx > 0 then
		if map_collision(player, "right", 0) then
			player.dx = 0
		end
	end
	
	if player.k_timer > 0 then
		player.k_timer -= 1
		player.dx = k_dx
		if player.k_timer <= 0 then
			if mget(player.x / 8, player.y/8 + 2) != 130 then
				player.dx = 0
			else
					player.dx *= friction
			end
		end
	end
	
	player.x += player.dx
end


--controls player animation
function player_anim()
	local anim = player.state.anim
	
	--sets starting frame after state change
	if player.anim != anim then
		player.anim = anim
		player.sprite = player.anim.frames[1]
	else
	
		--single-frame animation
		if #anim.frames == 1 then
			player.sprite = player.anim.frames[1]
		
		--multiple-frame animation
		elseif time() - player.anim_timing > player.anim.speed then
			player.anim_timing = time()
			player.sprite += 1
			if player.sprite > player.anim.frames[2] then
				if player.state == states.landed then
					player.state = states.idle
					player.on_floor = true
				else
					player.sprite = player.anim.frames[1]
				end
			end
		end
	end
end

--player knockback when they collide with an obstacle
function player_obstacle_collision(obs)
	player.k_timer = 5
	if player.x >= obs.x then
		k_dx += obs.knockback
	else
		k_dx -= obs.knockback
	end
end

-->8
--grappling hook--
--written by moises

-- grappling hook mechanics (moises)
function player_hook_update()
    if btnp(❎) and not player.hooking then
        -- start hook
        player.hooking = true
        player.hook_x = player.x + 4
        player.hook_y = player.y + 8
        player.hook_angle = 0
        player.hook_dir = {x=0, y=0}

        -- check input direction
        if btn(⬆️) then
            player.hook_dir = {x=0, y=-1}
        elseif player.flp then
            player.hook_dir = {x=-1, y=0}
        else
            player.hook_dir = {x=1, y=0}
        end

        player.hooking_state = "flying"
         ui_bleep(0) --ahmad
    end


    if player.hooking then
        if player.hooking_state == "flying" then
            -- move hook outward
            player.hook_x += player.hook_dir.x * 4
            player.hook_y += player.hook_dir.y * 4

            -- check full rope distance
            local px = player.x + player.w/2
            local py = player.y + player.h/2
            local dx = player.hook_x - px
            local dy = player.hook_y - py
            local dist = sqrt(dx*dx + dy*dy)

            -- cancel if rope exceeds max length
            if dist > hook_length then
                player.hooking = false
                player.hooking_state = nil
            end


            -- check if hook hits flag 0 tile
            if fget(mget(player.hook_x\8, player.hook_y\8), 0) then
                player.hooking_state = "pulling"
                ui_bleep(1)
            end

            elseif player.hooking_state == "pulling" then
                local px = player.x + player.w/2
                local py = player.y + player.h/2
                local dx = player.hook_x - px
                local dy = player.hook_y - py
                local dist = sqrt(dx*dx + dy*dy)

                if btn(❎) then
                    if dist > 2 then
                        -- normalize
                        local nx = dx / dist
                        local ny = dy / dist

                        -- step size = hook_p
                        local step_x = nx * hook_p
                        local step_y = ny * hook_p

                        -- try horizontal move first
                        player.x += step_x
                        if map_collision(player, "left", 0) or map_collision(player, "right", 0) then
                            player.x -= step_x  -- undo if blocked
                        end

                        -- then vertical move
                        player.y += step_y
                        if map_collision(player, "up", 0) or map_collision(player, "down", 0) then
                            player.y -= step_y  -- undo if blocked
                        end

                        player.dx = 0
                        player.dy = 0
                        player.on_floor = false
                        player.state = states.h_move
                    else
                        -- reached hook point ヌ●★ hold there
                        player.x = player.hook_x - player.w/2
                        player.y = player.hook_y - player.h/2
                        player.dx = 0
                        player.dy = 0
                        player.state = states.h_stop
                        ui_bleep(2)
                    end
                else
                    -- released ❎ ヌ●★ drop back to normal
                    player.hooking = false
                    player.hooking_state = nil
                    player.state = states.idle
                    ui_bleep(3)
                end
            end







        -- cancel if button released
--        if not btn(❎) then
--            player.hooking = false
--        end
    end
end

-->8
--obstacles--

--example obstacles
stalactite = {
	x = 20,
	y = 10,
	w = 12,
	h = 15,
	dy = gravity,
	dx = 0,
	c = 4,
	sprite = 76,
	tile_w = 2,
	tile_h = 2,
	flp = ceil(rnd(2)),
	knockback = 5,
	dir = "down",
	timer = 20,
	state = "disabled",
	dist_x = ceil(rnd(10)) + 50,
	dist_y = ceil(rnd(20)) + 50,
	grounded = false,
	part_count = 10
	}

boulder = {
	x = 70,
	y = 50,
	w = 32,
	h = 32,
	dy = 0,
	dx = -0.3,
	c = 4,
	sprite = 192,
	tile_w = 4,
	tile_h = 4,
	flp = ceil(rnd(2)),
	knockback = 10,
	dir = "down",
	timer = 20,
	state = "disabled",
	dist_x = ceil(rnd(30)) + 50,
	dist_y = 32,
	grounded = true,
	part_count = 20,
	a = 0,
	speed = -0.3
	}

--holds all of the obstacles in the map
obstacles = {}

--------
--initializes obstacles
function obstacle_init()
	
end

--draws obstacles
function obstacle_draw()
	for obs in all(obstacles) do
		spr(obs.sprite, obs.x, obs.y, obs.tile_w, obs.tile_h, obs.flp)
	end
end

--updates obstacle state and movement
function obstacle_update()
	for obs in all(obstacles) do
		if obs.state == "disabled" then
			if ((obs.x - player.x)^2 < obs.dist_x 
			or (player.x - obs.x)^2 > obs.dist_x)
			and ((obs.y - player.y)^2 < obs.dist_y
			or (player.y - obs.y)^2 > obs.dist_y) then
				obs.state = "enabled"
			end
		
		--timer has started 	
		elseif obs.state == "enabled" then
			obs.timer -= 1
			if obs.timer <= 0 then
				obs.state = "moving"
				
				--makes obstacle rotatae
				if obs.dx < 0 then
					add(rotating_sprites, obs)
				end
			end
		
		--moves the obstacle
		elseif obs.state == "moving" then
			if obs.dx < 0 then
				obs.dx -= 0.01
				obs.x += obs.dx
				obs.speed -= 0.05
				if not map_collision(obs, obs.dir, 0) then
					obs.dx = 0
					obs.dy = gravity
					obs.grounded = false
					del(rotating_sprites, obs)
				end
				--limits rotation speed
				if obs.speed > 2 then
					obs.speed = 2
				end
			elseif obs.dy > 0 then
				obs.dy += gravity
				obs.y += obs.dy
			end
		
		--impact
			if map_collision(obs, obs.dir, 0) 
			and obs.grounded == false then
				obs.state = "impact"		
			elseif spr_collision(obs, player) then
				obs.state = "impact"
				player_obstacle_collision(obs)
		 end
		elseif obs.state == "impact" then
			obstacle_impact(obs)
		end
	end
end

--runs when an obstacle hits something
function obstacle_impact(obs)
	spawn_particles(obs)
	if obs.dx < 0 then
		del(rotating_sprites, obs)
	end
	del(obstacles, obs)
end
-->8
--collisions--
--written by caitlyn carter

--flag 0: can stand on
--flag 1: can climb
--flag 2: slippery surface
function map_collision(obj, dir, flag)
	--obj = table needs x, y, w, h	
	local x = obj.x
	local y = obj.y
	local w = obj.w
	local h = obj.h
	
	--creates a collision boundary
	local x1 = 0
	local y1 = 0
	local x2 = 0
	local y2 = 0
	
	--checking collision direction
	if dir == "left" then
		x1 = x - 1
		y1 = y
		x2 = x
		y2 = y + h - 1
		if obj.dx < -3 then
			x1 = x - 3
		end
	elseif dir == "right" then
		x1 = x + w + 2
		y1 = y
		x2 = x + w + 3
		y2 = y + h - 1
		if obj.dx > 3 then
			x2 = x + 5
		end
	elseif dir == "up" then
		x1 = x + 1
		y1 = y - 1
		x2 = x + w + 1
		y2 = y
	elseif dir == "down" then
		x1 = x + 1
		y1 = y + h
		x2 = x + w
		y2 = y + h + 3
		if obj.dy < 3 then
			y2 = y + h + 1
		end
	end
	
	--------test--------
	x1r = x1 y1r = y1
	x2r = x2 y2r = y2
	--------------------
	
	--pixels to tiles
	x1 /= 8 y1 /= 8
	x2 /= 8 y2 /= 8
	
	if fget(mget(x1, y1), flag)
	or fget(mget(x1, y2), flag) 
	or fget(mget(x2, y1), flag) 
	or fget(mget(x2, y2), flag) then
		return true
	else
		return false
	end
end

--checks if two sprites collide
function spr_collision(obj1, obj2)
	local x_1 = obj1.x
	local y_1 = obj1.y
	local h_1 = obj1.h
	local w_1 = obj1.w
	
	local x_2 = obj2.x
	local y_2 = obj2.y
	local h_2 = obj2.h
	local w_2 = obj2.w
	
	if x_1 + w_1 >= x_2
	and x_1 <= x_2 + w_2
	and y_1 <= y_2 + h_2
	and y_1 + h_1 >= y_2 then
		return true
	else
		return false
	end
end
-->8
--particle system--
--written by caitlyn

--holds all spawned particles
parts = {}

-----

--draws all particles
function particles_draw()
	for p in all(parts) do
		rectfill(p.x, p.y, p.x + 1, p.y + 1, p.c)
	end
end

--updates particle movement and timer
function particles_update()
	for p in all(parts) do
		p.x += p.dx
		p.y += p.dy
		p.dy += gravity
		p.timer -= 1
		if p.timer <= 0 then
			del(parts, p)
		end
	end
end

--spawns particles based on the object
function spawn_particles(obs)
	for i = 1, obs.part_count do
		add(parts, {
			x = obs.x + (rnd(20) - 5),
			y = obs.y + obs.h-10,
			w = 1;
			h = 1,
			c = obs.c,
			dx = rnd(5) - 2,
			dy = rnd(3) - 2,
			timer = flr(rnd(7) + 5)
		})
	end
end
-->8
--sprite rotation--
rotating_sprites = {}

function r_draw()
	for sprt in all(rotating_sprites) do
		spr_r(sprt.sprite, sprt.x, sprt.y, sprt.a, sprt.tile_w, sprt.tile_h)
	end
end

function r_update()
	for sprt in all(rotating_sprites) do
		sprt.a += sprt.speed
		sprt.a = sprt.a%360
	end
end
--[[
s = sprite
x = center x
y = center y
a = angle 
w = width
h = height
--]]
-- s = sprite index (top-left tile)
-- x,y = destination top-left (keeps same semantics as your code)
-- a = angle in degrees (kept like your original: code divides by 360)
-- w,h = sprite size in tiles (defaults to 1)
function spr_r(s, x, y, a, w, h)
 w = w or 1
 h = h or 1

 -- clamp/normalize sprite index into 0..255
 s = flr(s) % 256

 local sw, sh = w * 8, h * 8
 local x0, y0 = sw * 0.5, sh * 0.5

 -- keep your angle convention (degrees -> turns)
 local ang = a / 360
 local sa, ca = sin(ang), cos(ang)

 for ix = 0, sw - 1 do
  for iy = 0, sh - 1 do
   local dx = ix - x0
   local dy = iy - y0

   -- rotated coordinates inside the sprite block
   local xx = flr(dx * ca - dy * sa + x0)
   local yy = flr(dx * sa + dy * ca + y0)

   if xx >= 0 and xx < sw and yy >= 0 and yy < sh then
    -- which 8x8 tile inside the block is this pixel in?
    local tile_col = flr(xx / 8)
    local tile_row = flr(yy / 8)
    local px = xx % 8
    local py = yy % 8

    -- compute the sheet tile index for that tile (handles spanning rows)
    local tile_index = (s + tile_col + tile_row * 16) % 256

    -- convert tile_index -> sheet pixel coords
    local sx = (tile_index % 16) * 8 + px
    local sy = flr(tile_index / 16) * 8 + py

    local col = sget(sx, sy)
    if col ~= 0 then -- optional: skip transparent pixels
     pset(x + ix, y + iy, col)
    end
   end
  end
 end
end

-->8

-->8
--colors--

--fuschia (2) --> brownish gray (134)
--red (8) --> reddish brown (132)
--purple (13) --> purplish brown (133)
--pink (14) --> dark brown (128)

function custom_palette()
	poke(0x5f2e, 1)
	pal( 2, 134, 1)
	pal( 8, 132, 1)
	pal( 13, 133, 1)
	pal( 14, 128, 1)    
end

--! palette helper function
-- restores the pico-8 default palette then applies your custom one.
function reset_pal()
    pal()
    pal(custom_palette, 1)
end
-->8
--performance stats--

function show_detailed_stats() 
	local fps = stat(7) 
	local cpu = stat(1) 
	local mem = stat(0) 
	local lua_mem = stat(2)
	-- larger background box
	rectfill(0, 0, 128, 10, 0)

	print("fps: "..fps, 1, 1, 7)
	print("cpu: "..flr(cpu*100).."%", 35, 1, 10)
	print("mem: "..mem.."kb", 1, 6, 11)
	print("lua: "..lua_mem.."kb", 70, 1, 12)
	print("peak: "..stat(24).."kb", 65, 6, 13) -- peak memory 
end

-->8

-- sfx id constants (use these anywhere you want to sfx())
sfx_grapple_fire=0
sfx_grapple_attach=1
sfx_impact=2
sfx_hit=3
sfx_victory=4
sfx_fall=5

-- helper to play a sound on a channel (optional util; unused by others)
function play_sfx(id,ch)
 if id then sfx(id, ch or -1) end
end

-- ui state (tiny)
_ui={bar_x=3,bar_y=3,bar_w=58,bar_h=5,
      col_bg=1,col_frame=6,col_hi=11,col_mid=10,col_lo=8}

function ui_init()
 -- nothing needed now; reserved for future
end

-- draw stamina bar (non-invasive; draws in screen space)
function ui_draw_stamina(sta,max_sta)
 sta=sta or 0
 max_sta=max_sta or 100
 local r=max(0,min(1,sta/max_sta))
 local x,y,w,h=_ui.bar_x,_ui.bar_y,_ui.bar_w,_ui.bar_h
 -- frame
 rectfill(x-2,y-2,x+w+2,y+h+2,0)
 rect(x-1,y-1,x+w+1,y+h+1,_ui.col_frame)
 -- fill
 local fill_w=flr(w*r)
 local col=_ui.col_lo
 if r>=0.66 then col=_ui.col_hi
 elseif r>=0.33 then col=_ui.col_mid end
 rectfill(x,y,x+fill_w,y+h,col)
 print(flr(r*100).."%", x+w+6, y, 7)
end

-->8
-->8
-- audio helpers (my code only)

function audio_init()
  -- start music pattern 0, loop forever
  music(0)
end

-- play a short ui sfx on channel 3 so it won't cut bgm (0ヌ█⧗2)
-- call: ui_bleep(sfx_id)
function ui_bleep(id)
  sfx(id, -1, 0, 3)
end

__gfx__
88888888888888888888888800000000000000000000000066d66d66000000000000000000000000000aa0000000000000444444444444000044444444c44400
848444848448844484484448000000000000000000000000dd6dd6dd000000000000000000000000000aa0000000000000444444444444000044444444c44400
848888848888444484484448000000000000000000000000dd6dd6dd00000000000000000000000000a00a000000000000444444444444000044444444c44400
84844484844488884884884800000000000000000000000066d66d660000000000000000000000000a0000a000000000000eeee88888e000000eeee88818e000
848444884444444444444488000000000000000000000000dd6dd6dd0000000000000000000000000a0aa0a00000000000088884444480000008888444c48000
888444444444444444444848000000000000000000000000dd6dd6dd00000000000000000000000000aaaa000000000000044444444440000004444444c44000
84484444444444444444844800000000000000000000000066d66d6600000000000000000000000000000000000000000000e888eeee00000000e888ee1e0000
844844444444444444448448000000000000000000000000dd6dd6dd000000000000000000000000000000000000000000008444888800000000844481180000
888844444444444444444848444444444444444400000000dd6dd6dd000000000000000000000000000000000003300000000ee888e0000000000ee881e00000
84448444444444444444848844774444448448440000000066d66d66000000000000000000000000000000000030030000000884448000000000088411800000
844484444444444444448448447444444444444400000000dd6dd6dd0000000000000000000000000000000003300330000000e88e000000000000e81e000000
844484444444444444448448444446644844848400000000dd6dd6dd000000000000000000000000000000000030030000000084480000000000008418000000
84448444444444444444488844447764444444440000000066d66d660000000067cccc76000000000000000000033000000000444400000000000044c4000000
844484444444444444448448444677444844484400000000dd6dd6dd000000000cccccc000000000000000000003300000000008e000000000000008c0000000
888844444444444444448448444664444448444400000000dd6dd6dd0000000000c76600000000000000000000033000000000088000000000000008c0000000
84484444444444444444844844444444444444440000000066d66d66000000000000000000000000000000000330033000000000000000000000000000000000
844844444444444444444888000000008888888800000000dd6dd6dd000000000000000000000000000000000000000000000000000000000000000000000000
848844444444444444448448000000008484448400000000dd6dd6dd000000000000000000000000000000000000000000000000000000000000000000000000
84844444444444444444844800000000848888840000000066d66d66000000000000000000000000000000000000000000000000000000000000000000000000
888444444444444444448448000000008484448400000000dd6dd6dd000000000000000000000000000000000000000000000000000000000000000000000000
844488884488848844444888000000008484448800000000dd6dd6dd000000000000000000000000000000000000000000000000000000000000000000000000
84484448488448848888884800000000888444440000000066d66d66000000000000000000000000000000000000000000000000000000000000000000000000
844844484844448448448448000000008448444400000000dd6dd6dd000000000000000000000000000000000000000000000000000000000000000000000000
888888888888888888888888000000008448444400000000dd6dd6dd000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000bb33bbbbbbbbbbbbbbbbbbbbcccccccc0000000000000000bbbbbbbb11111111000000000000000000000000000000000000000000000000
0000000000000000b34433bbb3333bbbbb333333cccccccc0000000000000000bbbbbbbb11111111000000000000000000000000000000000000000000000000
0000000000000000334444333444433333444444cccccccc0000000000000000bbbbbbbb11111111000000000000000000000000000000000000000000000000
0000000000000000444444444444444444444444cccccccc0000000000000000bbbbbbbb11111111000000000000000000000000000000000000000000000000
0000000000000000444444444444444444444444cccccccc0000000000000000bbbbbbbb11111111000000000000000000000000000000000000000000000000
0000000000000000444444444444444444444444cccccccc0000000000000000bbbbbbbb11111111000000000000000000000000000000000000000000000000
0000000000000000444444444444444444444444cccccccc0000000000000000bbbbbbbb11111111000000000000000000000000000000000000000000000000
0000000000000000444444444444444444444444cccccccc0000000000000000bbbbbbbb11111111000000000000000000000000000000000000000000000000
00000000044000000000000040444000000000000000000000000000000400000000000000000000004400000044000000000000000000000044000000440000
07000070043440000044000004434400000000000000000004400000044344000044000000440000004344000043440000440000004400000043440000434400
007007000444f4000044400000044f4000440000000000000434400004044f40004344000043440000444f4000444f40004344000043440004044f4004044f40
00077000044ff000004ff4000004ff0000434400000000000444f4004004ff0004044f4000444f400044ff000004ff0000444f4000444f400404ff000404ff00
0007700004030000004ff4000000330000444f4000000000044ff000000030000404ff000044ff0000043000000040000044ff000044ff004000300000003000
007007000033300000430000000f3f0f0044ff00000000000403300000033000400030000040300000033000000330000004300000403000000330000003f300
0700007000f330000033300000f033f0040030000044000000f33f000003f0000003300000033000000f3000000f300000033000000330000003f00000033f00
0000000000f3300000f33000000044000003f30f00434400000ffff000f3f0000003f000000f3000000f300000f33000000f3000000f30000003f000000440ff
000000000f04400000f330000000111000333ff000444f400000440000f44f000003f000000f300000f4400000f44f00000f3000000f300000f4f00000011000
000000000f011f0000f4400000001111004400000044ff00000011000f0110f000f44f000004f00000f11f000f0110f000f44f000004f00000f11f0000011000
000000000011100000f11f00000010110011100000433000000111000011110000f11f000001f000000111000011110000f111000001f0000001110000011000
0000000000111100001110000000111000011100000f3f0000011110001111100011111000011100000111000011111000111110000111000001110000110000
000000000110110000111100000017000001110000f33f0000110110011101100011111000111100001110000111011000111110001111000011100000110000
000000000110110001101100000010700011100000f1111000110110110001100111011071101100001700001100011001110110711011000017000000100000
00000000010010000100100000007000070010000111011000100010700000171100010070001000001070007000001711000100700010000010700007100000
000000000770770007707700000070000070770007110077007700770700007d7700077000007700007700000700007077000770000077000077000000700000
00000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000400000000
00000004400000000000400000000000004004400000000000000443440000000000000440000000000040000000000000400440000000000000044344000000
000004403440000000004004000000000004443440000000000004044f400000000004403440000000004004000000000004443440000000000004044f400000
0000400044f40000000004434400000000000044f400000000004004ff0000000000400044f40000000004434400000000000044f400000000004004ff000000
000000004ff00000000000044f4000000000004ff00000000000000030000000000000004ff00000000000044f4000000000004ff00000000000000030000000
000000000300000000000004ff0000000000000300000000000000ff30f00000000000000300000000000004ff0000000000000300000000000000f3f0f00000
000000003f0000000000000030000000000000f300000000000000f33f00000000000000f300000000000000300000000000003f00000000000000f33f000000
0000000f33ff00000000000f3000000000000f33ff00000000000004400000000000000f33ff00000000000f3000000000000f33ff0000000000000440000000
000000f0440000000000000f3000000000000f44000000000000000111000000000000f0440000000000000f3000000000000f44000000000000000111000000
000077001100000000000004ff00000000000011000000000000001111107000000077001100000000000000ff00000000000011000000000000001111107000
00000101111000000000000111000000000001111000000000071111001170000000010111100000000000011100000000000111100000000007111100117000
00000111111100000000000111000000000001111100000000070110000000000000011111110000000000011100000000000111110000000007011000000000
00000011001100000000007110000000000011101100000000000000000000000000001100110000000000711000000000001110110000000000000000000000
00000000000110000000007110000000000110007700000000000000000000000000000000011000000000711000000000011000770000000000000000000000
00000000000017000000000100000000000700000000000000000000000000000000000000001700000000010000000000070000000000000000000000000000
00000000000070000000000770000000000070000000000000000000000000000000000000007000000000077000000000007000000000000000000000000000
21121212626201216262626262626201004440000000000000000000004440000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000044344000044000000000000044344000044000000000000000000000000000000000000000000000000000000000000
2160606060600121606060101010600140044f40004344000004400040044f400043440000440000000000000000000000000000000000000000000000000000
000000000000000000000000000000000004ff0f00444f40000434400004ff0f00444f4000434400000000000000000000000000000000000000000000000000
21616161616101216161610111216101000033f00044ff0f000444f4000033f00044ff0000444f40000000000000000000000000000000000000000000000000
0000000000000000000000000000000000003f0f040030f000044ff000003f00040030f00044ff0f000000000000000000000000000000000000000000000000
21626262626201226262620131216201000033f00003f30f004003f0000033ff0003ff0004003ff0000000000000000000000000000000000000000000000000
000000000000000000000000000000000000440000333ff000003f0f0000440000333f0f0003f00f000000000000000000000000000000000000000000000000
216060606060226160606012126060010000111000440000000333f000001111004400f000333ff0000000000000000000000000000000000000000000000000
00000000000000000000000000000000000011110011110000044000000011110011100000440000000000000000000000000000000000000000000000000000
21616161121222616161616161616101000010110001111000011100000011170001110000111000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000011100001110700001107000001100001117700011107000000000000000000000000000000000000000000000000
21102062216262626262626262626201000017000001107000001170000001100001100000011170000000000000000000000000000000000000000000000000
00000000000000000000000000000000000010700000100000000107000000100000100000011000000000000000000000000000000000000000000000000000
21606060216060604131416060606001000077000000770000000070000000770000770000001700000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000
21616161216111126161616161616101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21626262216221626262626262626201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21606002226021606011111160606001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21616161616121616161616101616101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21626262626221626262626210101001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21111111121212121212126060606001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21114122616161616161616161616101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21312262626262626262626262626201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21226060606060606060601010101001535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21616161611010106161616161114101535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21626262626262626262626262621101535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21606060606060601010101060606001535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21616161616161616161616161616101535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21101010101020626262626262626201535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21111111411112226060606060606001535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21111111112261616161616161616101535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21411141226262626262626262626201535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21111122606060604210101010101001535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21112261616161421112121212121201535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21226262626242112262626262626201535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21606060600212226060606060606001535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21616161616161616161616161616101535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21626262626262626262626262626201535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000
__gff__
0303030303000000000000000000000003030303030000000000000000000000030303030300000000000000000000000203030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3535353535353535353535353535353500000000003535350000000000000035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535353535353535353535353535353500000000003500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3432333432323535353534333434333200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1221212121213206063421212121211000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1216161616101116161616161616161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1226262626101126262626262626261000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1206060606201106060606060606061000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1216161616162011161616161610161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1226262626262610212226262610021000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1206060606060606060606060610111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1216161616161616161616161610111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1226262121262626262626262610111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1216121616161616161616161610221000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1226122626262610262626262622261000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1206120606060610060606060606061000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1216121616161610161616161616161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1226122626262610262626262626261000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1206120606060606060606060606061000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1216161616011616161616161616161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1226262626212626262626262626261000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1206060606060606060606060606061000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1216161616161616161616011616161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1226262626010101012626262626261000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1206060621060606062106060101011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1216161216161616161610161611161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1226261226262626262610262626261000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1206140606061012060610210606061000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1221211616161012161616161616161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
900200000c61000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
38060d0d00660027600000000730017300273003730037300473004730047300573005730067300673006730033000b6000b6000a600086000760005600046000460000000000000000000000000000000000000
000900000d610000000000000000000000000000000190502c05000000000000000000000000002c0501405000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c0108090100f010120100f0100c01009010060100c0100c0301104000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000033701165010620106200e6100b6100961007610036100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001b02000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c0430000000000000000000000000000000000024635000000000000000186250000000000000000c6250000000000000000c62500000000000000024635106320e6220c61200000000000000000000
01100000100401003010020100100000000000000000000000000000000000000000000000000000000000000e0400e0300e0200e010000000000000000000000000000000000000000000000000000000000000
011000001c7301c73500000000001c73500000000001c7351c7301c73500000000001f735000001a7350000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001c7301c73500000000001c73500000000001c7351c7301c73500000000001f735000001a735000000000000000000000000000000000000000000000000000000023740237352a7402a7351f7401f035
011000001c5511c5101c5111f5501f5311c5501c5301c5101c510175501755017530175101a5101a5301a5101a510000000000000000000000000000000000000000000000000000000000000000000000000000
011000001c5501c5301c5101c5111f5501f5311c5501c5501c5101c511175501753017510175111a5501a5301a5501a55100000000001f5501f5511c5501c5501c5501c551175501753017510175110000000000
__music__
00 410b0d44
00 0a0b0d44
00 0a0b0d44
00 0a0b0d0e
00 0a0b0d0e
00 0a0b0c0f
00 0a0b0d0e
00 0a0b0d0e
00 410b0d44
00 0a0b0d44
00 0a0b0d44
00 0a0b0d0e
00 0a0b0d0e
00 0a0b0c0f
00 0a0b0d0e
00 0a0b0d0e
00 410b0d44
00 0a0b0d44
00 0a0b0d44
00 0a0b0d0e
00 0a0b0d0e
00 0a0b0c0f
00 0a0b0d0e
00 0a0b0d0e
00 410b0d44
00 0a0b0d44
00 0a0b0d44
00 0a0b0d0e
00 0a0b0d0e
00 0a0b0c0f
00 0a0b0d0e
00 0a0b0d0e
00 410b0d44
00 0a0b0d44
00 0a0b0d44
00 0a0b0d0e
00 0a0b0d0e
00 0a0b0c0f
00 0a0b0d0e
00 0a0b0d0e
00 410b0d44
00 0a0b0d44
00 0a0b0d44
00 0a0b0d0e
00 0a0b0d0e
00 0a0b0c0f
00 0a0b0d0e
00 0a0b0d0e
00 410b0d44
00 0a0b0d44
00 0a0b0d44
00 0a0b0d0e
00 0a0b0d0e
00 0a0b0c0f
00 0a0b0d0e
00 0a0b0d0e
00 410b0d44
00 0a0b0d44
00 0a0b0d44
00 0a0b0d0e
00 0a0b0d0e
00 0a0b0c0f
00 0a0b0d0e
00 0a0b0d0e

