pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-->8
--main
-- #include main.lua
-- #include tool.lua
-- #include objects.lua
-- #include particles.lua
-- #include input.lua
-- #include physics.lua
-- #include player.lua
-- #include map.lua
-- #include camera.lua
-- #include break_block.lua
-- #include wind.lua
local color_num = 
{
    back = 1,
    mid = 2,
    gray = 6,
    white = 7,
    red = 2,
    skin = 9
}

pal_change_no = 1


local cols =
{
    1, -- back wall
    13,-- mid asiba
    6, -- gray
    7, -- white snow
    2, -- player cloth
    9, -- player skin
    12, -- sky
}

local ch_colors =
{

    --cols
    {  1,  1,  1,  1,129,  0,  0},   -- back wall
    { 13,134,  4,  4,  4,  5,  5},  -- mid asiba
    {  6,  6, 15, 15,134,134,143}, -- gray
    {  7,  7,  7,  7,  6,  6,  7},   -- white snow
    {  2,  2,  2,136,136,136,136},   -- player cloth
    {  9,  9,  9,  9,  4,  4,  4},   -- player skin
    { 12, 12, 12,143,140,  1,140}   -- sky
}

pal_number = 1
    

frame =0
debug =false
is_title = true


nil_function = function()end
--debug
test = false

function _init()
    if not debug then
        pal(15,1)
    else

        mouse.init()
    end
    now_input = {}
    frame = 0
    sys ={}
    init_camera()
    init_game()
end

function _update()
    frame=((frame+1)%120)
    if debug then
        mouse_x,mouse_y = mouse.pos()
        mouse_btn = mouse.button()
    end
    check_update()
    update_camera()
    if debug then
        update_mouse()
    end


    sys.func_update()
end

local pal_change = false
local pal_change_no = 1

function _draw()
    
    for i = 1,#ch_colors do
        poke(0x5f10 +cols[i],ch_colors[i][pal_number])
    end

    sys.func_draw()

    draw_mouse_things()


    if pal_change and debug then

        local x,y =100+cam_x,12+cam_y
        local w = 2
        local c =ch_colors[pal_number]
        for i=1,#c do
            rectfill(x,y+6*(i-1),x+w,y+6*(i-1)+w,c[i])
            print(c[i],x+8,y+6*(i-1),0)
        end
        pset(x-8,y+6*pal_change_no-6,0)
        print(pal_number,x-8,y+6*pal_change_no-6,11)
    end

end

--game

function init_game()
    sys.func_update = update_game
    sys.func_draw = draw_game

    for i = 0,31 do
        inport_map(i)

        -- if player then
        --     break
        -- end
    end
    music_play(3)
end

function update_game()
        
    if pal_change then
        for key = key_l,key_z do
            if btnp(key) then
                local c = false
                if key == key_l then
                    c = true
                    pal_number -=1
                elseif key == key_r then
                    c=true
                    pal_number +=1

                end

                pal_number = mid(pal_number,1,#ch_colors[1])

            end 
        end
    end

    update_title()
    update_cloud()
    update_wind()
    update_weather()
    make_snows()
    for obj in all(objects) do
        obj:update()
    end

    for part in all(particles) do
        part:update()
    end
    update_goal()
end


sky_col = 12

function draw_game()
    cls(sky_col)

    if is_goal then
        circfill(sun.x,sun.y,sun.r,sun.y>sun.goal and 7 or 10)
    end
    for part in all(particles) do
        part:draw_back()
    end
    draw_map(1)
    
    draw_tutorial()
    
    for obj in all(objects) do
        obj:draw_back()
    end
    for part in all(particles) do
        part:draw()
    end
    for obj in all(objects) do
        obj:draw()
    end
    for part in all(particles) do
        part:draw_front()
    end
    for obj in all(objects) do
        obj:draw_front()
    end

    draw_wind()

    draw_goal()
    if debug then
        cursor(cam_x+50,cam_y+50,0)
        print("test")
        print(test)
    end
    draw_title()
end

--goal
is_goal = false
goal_y = -2112
start_time = 0
goal_time = 0
sun = {x=63.5,y = goal_y+12,r=16,goal = goal_y-40,col =7}

function end_everything() return is_goal and sun.y <= sun.goal end

function update_goal()
    if is_goal == false then
        if player.y <= goal_y then
            is_goal = true
            music_play(-1)
            se(21)
            goal_time = time() - start_time

        end
    else
        if sun.y >sun.goal and frame%2==0 then
            sun.y -= 1
            if sun.y>sun.goal then
                music_play(3)
            end
        end

    end
end

function draw_goal()
    if end_everything() then
        local m,s = 0,0
        m = goal_time\60
        s = flr(goal_time%60)
        m = m>0 and m or "00"
        s = s<10 and "0"..tostr(s) or s
        local t= "time:"..m..":"..s
        local y = goal_y-20
        local x = 38
        print(t,hcenter(t),y+1,0)
        print(t,hcenter(t),y,7)

        local y = sun.goal-4
        print_center("thank you for",y,1)
        print_center("playing",y+6,1)
    end

end

if debug then
mouse = {
    init = function()
      poke(0x5f2d, 1)
    end,
    -- return int:x, int:y, onscreen:bool
    pos = function()
      local x,y = stat(32)-1,stat(33)-1
      return stat(32)-1,stat(33)-1
    end,
    -- return int:button [0..4]
    -- 0 .. no button
    -- 1 .. left
    -- 2 .. right
    -- 4 .. middle
    button = function()
      return stat(34)
    end,
  }


    menuitem(1, "save_map", 
    function()
        local map_start = 0x2000
        local map_size = 0x2000
        cstore(0x2000, 0x2000, map_size) --upper
        cstore(0x1000, 0x1000, map_size) --lower
        save()
    end)

    menuitem(2, "auto_tile", 
    function()
    autotile()
    end)

    menuitem(3, "pallete change", 
    function()
        pal_change = not pal_change
    end)
end


-->8
--tool
--music tool
function se(tbl)
    local num = tbl
    if type(tbl) == "table" then
        num = rnd(tbl)--tbl[rnd_int(1,#tbl)]
    end

    sfx(num)
end

music_on_off = true

function music_play(num)
    num = music_on_off and num or -1
    if now_music ~= num then
        music(num)
        now_music = num
    end
end

function sprint(tx,x,y,col1,col2)
    for i=1.2,-.9,-.25 do
        print(tx,x+.5+sin(i),y+.5+ceil(i)-cos(i),i>0 and 0 or col2)
    end
    print(tx,x,y,col1)
end

function frame_to_table(table,baisoku)
    local max = 30/baisoku 
    local f = frame%max/max
    return table[1+flr(#table*f)]
end


function hcenter(s)
    return 64-#s*2
end
  
function vcenter(s)
    return 61
end


function print_center(t,y,c)
    c = c or nil
    print(t,hcenter(t),y,c)
end

function rnd_int(min,max)
    return flr(rnd(max-min+1)+min)
end
function move(rx,mx,c)
    c=c and c or 0.7
    if abs(rx-mx)<1 then
        return mx
    end
    
    return (1-c)*mx+rx*c
end


--autotile
function autotile()
    local t_ground = 67
    -- Mapping 16 types of tiles to bitmask values
    tile_map = {
        [0b0000] = 67, -- isolated
        [0b0001] = 115, -- connected above
        [0b0010] = 83, -- connected below
        [0b0011] = 99, -- connected above and below
        [0b0100] = 114, -- connected to the left
        [0b0101] = 98, -- connected to the top-left
        [0b0110] = 66, -- connected to the bottom-left
        [0b0111] = 82, -- connected to the left and vertical
        [0b1000] = 112, -- connected to the right
        [0b1001] = 96, -- connected to the top-right
        [0b1010] = 64, -- connected to the bottom-right
        [0b1011] = 80, -- connected to the right and vertical
        [0b1100] = 113, -- connected horizontally
        [0b1101] = 97, -- connected horizontally and above
        [0b1110] = 65, -- connected horizontally and below
        [0b1111] = 81   -- fully connected
    }
    local map_w = 128
    local map_h = 128
    local mget_p = function(x,y)
        if x<0 or x>=map_w or y<0 or y>=map_h then
            return true
        end
        return fget(mget(x,y))==7
    end
    for y = 0, map_h - 1 do
        for x = 0, map_w - 1 do
            if mget_p(x, y) then
            -- Calculate the bitmask based on surrounding tiles
                local mask = 0
                if mget_p(x, y - 1)  then mask = mask | 0b0001 end -- above
                if mget_p(x, y + 1)  then mask = mask | 0b0010 end -- below
                if mget_p(x - 1, y)  then mask = mask | 0b0100 end -- left
                if mget_p(x + 1, y)  then mask = mask | 0b1000 end -- right

                -- Update the tile based on the bitmask
                local new_tile = tile_map[mask] or Tt_ground
                mset(x, y, new_tile)
            end
        end
    end
end

-->8
--objects
objects ={}
obj_meta ={}

obj ={}
obj.name ="object"
obj.x = 64
obj.y = 64
obj.spr = 0
obj.remainder_x = 0
obj.remainder_y = 0
obj.spd_x =0
obj.spd_y =0
obj.acs_x =0
obj.acs_y =0
obj.hit_l = 0
obj.hit_r = 7
obj.hit_u = 0
obj.hit_d = 7
obj.now_col_l = false
obj.now_col_r = false
obj.now_col_u = false
obj.now_col_d = false
obj.col_edge = nil
obj.is_solid = false
obj.now_player = false
obj.friction = 0.8
obj.fric_ground = 0.8
obj.col_type = 0

obj.is_flip = false

obj.update = nil_function

obj.draw = function(o)
    spr(o.spr,o.x,o.y,1,1,o.is_flip)
    -- rect(o.x+o.hit_l,o.y+o.hit_u,o.x+o.hit_r,o.y+o.hit_d,9)
end

obj.now_player_on = function(o)
    o.now_player = true
end

obj.draw_back =nil_function
obj.draw_front =nil_function

obj_meta.__index = obj


function make_object(name,x,y,spr)
    local o ={}
    o.name = name
    o.x = x
    o.y = y
    o.spr = spr
    setmetatable(o,obj_meta)
    add(objects,o)
    return o
end



-->8
--particles
particles ={}
particle_meta = {}
part = {}
part.x = 0
part.y = 0
part.size =5
part.change_size = nil
part.acs_x = 0
part.acs_y = 0
part.spd_x = 0
part.spd_y = 0
part.gravity = false
part.time = nil
part.friction = 0.9
part.color = 1
part.update = function(p)
    if p.gravity then
        p.acs_y+=p.gravity
    end
    p.spd_x +=p.acs_x
    p.spd_y +=p.acs_y
    p.x += p.spd_x
    p.y += p.spd_y
    p.spd_x*=p.friction
    p.spd_y*=p.friction
    p.acs_x,p.acs_y =0,0
    if p.time then
        p.time-=1
        if p.time <=0 then
            del(particles,p)
        end
    end
    if p.change_size then
        p.size *= p.change_size
        if p.size <0.5 then
            del(particles,p)
        end
    end
    
end
part.draw = function(p)
    circfill(p.x,p.y,p.size,p.col);
end
part.draw_back = nil_function
part.draw_back_obj = nil_function

part.draw_front = nil_function

particle_meta.__index = part

function make_particle(x,y,col)
    local p={}
    p.x,p.y,p.col =x,y,col
    setmetatable(p,particle_meta)
    add(particles,p)
    return p
end

--snow
--

local most_snow = -3000
function make_snows()
    if #particles <1000 then
        if frame%2 == 1 and rnd() > 0.9-0.4*(cam_y/-3000) then
            make_snow(rnd()*128-wind_x)
        end
    end
end

function make_dust()
    local s = make_particle(cam_x+128,cam_y+rnd_int(0,128),7)
    s.gravity = 0.01
    s.p = rnd()
    local c = (rnd()-0.5)*5
    s.update = function()
        part.update(s)
        if s.x <cam_x or s.y < cam_y or 
            s.x>cam_x+128 or s.y>cam_y+128 then
            del(particles,s)
        end

        if abs(wind_x) > 0 then
            s.acs_x =wind_x*5+s.p
            s.gravity = 0.1
        else
        end
        part.update(s)
    end
    s.draw =nil_function
    s.draw_front = function()
        -- rectfill(s.x,s.y,s.x+s.size,s.y+s.size,6)
        -- rectfill(s.x,s.y,s.x+s.size,s.y-1+s.size,13)
        pset(s.x,s.y,6)
        pset(s.x,s.y+1,13)
    end
end

function make_snow(x)
    local s = make_particle(x,cam_y,7)
    s.gravity = 0.1
    s.size = rnd()*2
    s.rx = x
    s.x_time = 0
    s.x_change = rnd()/30
    local c = (rnd()-0.5)*5
    s.update = function()
        s.x_time += s.x_change
        part.update(s)
        s.rx+=wind_x*2
        s.x = s.rx + 8*cos(s.x_time)
        if s.y >= cam_y+128 or s.y <= cam_y -128 then
            del(particles,s)
        end
    end
    s.draw =nil_function
    s.draw_front = function()
        rectfill(s.x,s.y,s.x+s.size,s.y+s.size,6)
        rectfill(s.x,s.y,s.x+s.size,s.y-1+s.size,7)
    end
end
--cloud
cloud_time =100
function update_cloud()
    if cam_y > goal_y+128 then
        cloud_time+=1

        if cloud_time >= 180 then
            cloud_time =0
            make_cloud()
        end
    end
end

function make_cloud()
    local y = cam_y +rnd_int(0,64)
    local w = rnd_int(15,48)
    local h = rnd_int(10,20)

    local c = make_particle(129,y,7)
    c.time = 0
    c.update = function()
        -- c.time +=0.01
        -- if c.time>=1 then
        --     c.x -=1

        --     c.time = 0
        -- end
        c.x -=1

        if c.x +w < 0 then
            del(particles,d)
        end
    end
    
    c.draw=nil_function
    c.draw_back = function()
        rectfill(c.x,c.y,c.x+w,c.y+h+1,13)
        rectfill(c.x,c.y,c.x+w,c.y+h,7)
    end
    if y< goal_y/2 then
        c.draw = function()
            rectfill(c.x,c.y,c.x+w,c.y+h+1,13)
            rectfill(c.x,c.y,c.x+w,c.y+h,7)
        end
    end
    -- c.draw_front = function()
    --     -- rect(c.x,c.y,c.x+w,c.y+h+1,7)
    --     for x=c.x,c.x+w,3 do
    --         for y=c.y,c.y+h,3 do
    --             pset(x+rnd(),y+rnd(),7)
    --         end
    --     end
        

    --     -- rectfill(c.x,c.y,c.x+w,c.y+h+1,7)
    --     -- fillp()
    -- end

end


-->8
-- input
key_l = 0
key_r = 1
key_u = 2
key_d = 3
key_z = 4
key_x = 5

inputs = {false,false,false,false,false,false}
before_inputs = {false,false,false,false,false,false}

last_pressed = {0,0,0,0,0,0}
last_released = {0,0,0,0,0,0}

function check_update()

    for key_no = key_l+1,key_x+1 do
        before_inputs[key_no] = inputs[key_no] 
        inputs[key_no] = btn(key_no-1)

        local b = before_inputs[key_no]
        if not b and now then
            last_pressed[key_no] =time()
        end
        if b and not now then
            last_released[key_no]=time()
        end

        if inputs[key_no] then
        else
        end

    end
end

function keyp(key,not_time,buffer)
    buffer = buffer or 0
    not_time = not_time or 1
    key+=1
    -- local b = false

    -- if last_pressed[key]
    -- and time()-last_pressed[key] < buffer 
    -- and last_pressed[key]-last_released[key] <not_time then
    --     b =true
    -- end
    -- return b

    return (not before_inputs[key] and inputs[key])
end

function key_hold(key,buffer)
    key+=1
    return inputs[key]
end

function draw_key_input()
    local rx,ry = 16,16

    -- for i = 1,5 do
    --     print()

    -- end
end



-->8
--physics

function obj.just_move(self)
    self.now_col_r = false
    self.now_col_l = false
    self.now_col_u = false
    self.now_col_d = false

    self.spd_x += self.acs_x
    self.spd_y += self.acs_y

    self:move_x(self.spd_x)
    self:move_y(self.spd_y)

    self.acs_x,self.acs_y = 0,0
    self.spd_x *= self.friction
    if self.now_col_d then
        self.spd_x *= self.fric_ground
    end
    self.spd_y *= self.friction

    local p = self
    
end
function obj.move_x(self,x)
    self.remainder_x +=x
    local cx = flr(self.remainder_x)
    self.remainder_x -= cx

    local total = cx
    local vecx = sgn(cx)
    while cx !=0
    do
        if self:check_solid(vecx,0) then
            if x > 0 then
                self.now_col_r = true
            else
                self.now_col_l = true
            end
            self.acs_x = -self.spd_x
            return true
        end
        self.x +=vecx
        cx -= vecx
    end 
    return false
end
function obj.move_y(self,y)
    self.remainder_y +=y
    local cy = flr(self.remainder_y)
    self.remainder_y -= cy
    local total = cy
    local vecy = sgn(cy)
    while cy !=0
    do
        if self:check_solid(0,vecy) then
            if y > 0 then
                self.now_col_d = true
            else
                self.now_col_u = true
            end
            self.spd_y = 0
            -- self.acs_y = -self.spd_y

            return true
        end
        self.y+=vecy
        cy -= vecy
    end 
    return false
end

function obj.now_col(self)
    return self.now_col_r or self.now_col_l or self.now_col_u or self.now_col_d
end

function obj.check_solid(self,ox,oy)
    ox = ox or 0
    oy = oy or 0

    local col = {}
    obj.col_edge = {}
    for x = self.x + ox + self.hit_l, self.x+ ox+self.hit_r,self.hit_r - self.hit_l do
        for y = self.y + oy + self.hit_u, self.y+ oy+self.hit_d,self.hit_d - self.hit_u do
            add(obj.col_edge,false)
            add(col,{x,y})
            -- if check_position_solid(x,y,self,col_type.player) then
            --     return true
            -- end
        end
    end

    local c = false

    for i=1,#col do
        local x,y = col[i][1],col[i][2]
        if check_position_solid(x,y,self,col_type.player) then
            obj.col_edge[i]=true
            c= true
        end
    end

    return c

    -- return false

end


col_type = 
{
    player =2,
    hook = 4,
    no_hook = 8,
    null = 0
}

function check_position_solid(x,y,ob,type)

    return get_col_type(x,y,ob)&type == type

    
end

function get_col_type(x,y,ob)

    local f =check_map_collide(x,y)
    if f>1 then
        return f
    end

    for o in all(objects) do
        if (ob ~= nil and ob ~= o) and o.is_solid and
        o.x+o.hit_l<=x and o.x+o.hit_r >= x and
        o.y+o.hit_u<=y and o.y+o.hit_d >= y then

        if o.name == "break" then
            o:start_broken()
        end
            if o.col_type>0 then
                return o.col_type
            end
        end
    end
    return 0
end

function check_area_player(self)
    local self = player
    for x = self.x  + self.hit_l, self.x+ self.hit_r,self.hit_r - self.hit_l do
        for y = self.y + self.hit_u, self.y+self.hit_d,self.hit_d - self.hit_u do
            for o in all(objects) do
                if o.is_area and
                o.x+o.hit_l<=x and o.x+o.hit_r >= x and
                o.y+o.hit_u<=y and o.y+o.hit_d >= y then
        
                    o:now_player_on()
                    o.now_player= true
        
        
        
                else
                    o.now_player = false
                end
            end
        end
    end
end



-->8
--player
gravity = 0.8

get_max_time = 90
circle_max_time = 60
fade_out_time = 0

get_time = 90

walk = 0.6
jump_init_p = 1.5
hook_p = 3.1--2
hook_length = 42

stop_move_time =0
stop_move_max_time =1
player =nil
f_margin_x = 3
f_margin_y = 3
p_h_l =2
p_h_r =6
p_h_u = 0
p_h_d = 7
p_has_hook = debug

p_state = 
{
    none = "none",
    walk = "walk",
    h_throw = "hook_throw",
    wait_move = "wait_move",
    h_move = "hook_move",
    h_stop = "stop",
    s_climb = "climb",
    h_get = "hook_get"
}
local bun = 100




function make_player(x,y)
    local p = make_object("player",x,y,1)
    player = p
    local function p_state_check(s)
        return p.state == s
    end
    p.state = p_state.walk
    p.now_hook =false
    p.hook_move= false
    p.hook_stop = false
    p.hook_get = false

    p.angle = key_r
    p.f_x =0
    p.f_y =0
    p.f_p_x = 0
    p.f_p_y = 0
    p.hit_l = 2
    p.hit_r = 6
    p.hook_angle = key_r
    p.stop_angle = 0
    p.cloth = {}
    p.stop_time = 0
    p.stop_move_angle = -1
    local not_hook_time =0
    fk_range_x = p.x
    fk_range_y = p.y
    climb_goal = {x = 0,y=0}
    max_climb_time = 10
    now_climb_time = 0
    local climb = false

    p_hp_max = 22
    p_hp_now = p_hp_max
    local climb_power_v = 3
    local climb_power_h = 2
    local p_col_d_before = false
    local p_b_y = p.y
    local p_b_sy = p.spd_y
    local input_catch = false

    p.update = function()
        if title_time > 0 then
            return
        end
        input_catch = false
        local can_get_hang =function(c)
            return c&4 ~= 0
        end
        p_b_sy = p.spd_y
        if not_hook_time > 0 then
            not_hook_time -=1
        else

        end

        if p.state == p_state.walk then
            p.acs_y +=gravity
            if p.now_col_d then
                p_hp_now = min(p_hp_max,p_hp_now+3)
                if p_b_sy >2 then
                    -- se(6)
                end
                if not p_col_d_before and p.y ~= p_b_y then
                    for i =1,4 do
                        local h = rnd()<0.5 and p.hit_l or p.hit_r

                        local p1= make_particle(p.x+h+rnd_int(-1,1),p.y+p.hit_d,rnd({7}))
                        p1.time =10
                        p1.acs_y = -2*rnd()
                        p1.gravity =gravity/3
                        p1.change_size = 0.9
                        p1.size = 2
                        p1.draw = function(p)
                            circfill(p.x,p.y,p.size,p.col)
                        end
                        -- p1.draw = nil_function
                    end
                end
            else
            end
            
            if key_hold(key_l) then
                p.acs_x -= walk
                p.is_flip = true
            elseif key_hold(key_r) then
                p.is_flip = false
                p.acs_x +=walk
            end
            if key_hold(key_x) then
                if p_has_hook then
                    if keyp(key_x,1,1) then
                        if not(p.now_col_d and p.angle == key_d) and not_hook_time ==0 then
                            p.acs_x =0
                            p.acs_y =0
                            p.spd_x = 0
                            p.spd_y = 0
                            p.f_p_x = p.x+f_margin_x
                            p.f_p_y = p.y+f_margin_y
                            local f,fx,fy =make_hook(p.angle,p)
                            p.hook_angle = p.angle

                            p.hook_get = f
                            p.f_x = fx
                            p.f_y = fy
                            p.state = p_state.h_throw

                            se({0,1})
                        end
                    end
                else
                    if keyp(key_x,1,1) then
                        se(20)
                    end
                    local cx = p.hit_r+1
                    p.hook_angle = key_r
                    if p.is_flip then
                        cx = p.hit_l-1
                        p.hook_angle = key_l

                    end

                    local no = get_col_type(p.x+cx,p.y,player)
                    input_catch = true
                    if can_get_hang(no) then
                        se(7)
                        p.state = p_state.h_stop
                    end
                end
                
            elseif btnp(key_z) then

                if p.now_col_d then
                    p.acs_y -=3
                end
            end
        elseif p.state == p_state.h_throw then
            p.f_p_x = move(p.f_p_x,p.f_x,0.4)
            p.f_p_y = move(p.f_p_y,p.f_y,0.4)

            if p.f_p_x == p.f_x and p.f_p_y == p.f_y then
                if p.hook_get then
                    p.state = p_state.wait_move
                    if can_get_hang(p.hook_get) then
                        se(2)
                        stop_move_time = stop_move_max_time

                    else
                        se(5)
                        stop_move_time = stop_move_max_time+1

                    end

                else
                    p.state = p_state.walk
                end
            end
            if not btn(key_x) then
                p.state = p_state.walk
            end
        elseif p.state == p_state.wait_move then
            stop_move_time -=1
            if stop_move_time<= 0 then
                if p.hook_get&4 ~= 0 then
                    p.state = p_state.h_move
                else
                    p.state = p_state.walk
                end
            end

        elseif p.state == p_state.h_move then

            local x,y = 0,0

            local f_angle = p.hook_angle
            local now_col = false
            local not_col = false

            if f_angle == key_l then
                if p.x+p.hit_l < p.f_p_x then
                    now_col = true
                    not_col = not p:check_solid(-1)
                end
                x =-1
            elseif f_angle == key_r then
                if p.x+p.hit_r > p.f_p_x then
                    now_col = true
                    not_col = not p:check_solid(1)
                end
                x=1
            elseif f_angle == key_u then
                if p.y+p.hit_u < p.f_p_y then
                    now_col = true
                    not_col = not p:check_solid(0,-1)
                end
                y=-1
            elseif f_angle == key_d then
                if p.y+p.hit_d < p.f_p_y then
                    now_col = true
                    not_col = not p:check_solid(0,1)
                end
                y=1
            end


            if now_col then
                if not_col then
                    p.state = p_state.walk
                else
                    if f_angle!=key_d then
                        p.state = p_state.h_stop
                        p.acs_x =0
                        p.acs_y =0
                        p.spd_x =0
                        p.spd_y =0
                    else
                        p.state = p_state.walk

                    end
                    p.stop_angle = f_angle
                    
                end
            else

                if p:now_col() then
                    while true do
                        local cx,cy = 0,0
                        if f_angle <2 then
                            local x = f_angle==key_l and p.hit_l-1 or p.hit_r+1
                            x+=p.x
                            local y = p.y
                            if check_position_solid(x,y+p.hit_u,p,col_type.player) then
                                cy=1
                            end
                            if check_position_solid(x,y+p.hit_d,p,col_type.player) then
                                cy=-1
                            end
                        else
                            local y = f_angle==key_u and p.hit_u-1 or p.hit_d+1
                            y+=p.y
                            local x = p.x
                            if check_position_solid(x+p.hit_l,y,p,col_type.player) then
                                cx=1
                            end
                            if check_position_solid(x+p.hit_r,y,p,col_type.player) then
                                cx=-1
                            end
                        end

                        if cx==0 and cy == 0 then
                            break
                        end
                        p.x+=cx
                        p.y+=cy
                    end
                end


                if abs(x)>0 then
                    p.acs_x += sgn(x)*hook_p
                end
                if abs(y)>0 then
                    p.acs_y += sgn(y)*hook_p
                end
            end

            if not btn(key_x) then
                p.state = p_state.walk
            end
        elseif p.state == p_state.h_stop then
            p.spd_x = 0
            p.spd_y = 0

            if p_hp_now<=0 then
                p_hp_now = 0
                p.state = p_state.walk
            else
                local climb_up = false
                if climb then
                    se({3,4})
                    local f_angle = p.hook_angle
                    
                    if f_angle == key_r then
                        p_hp_now -= climb_power_v

                        if not check_position_solid(p.x+p.hit_r+1,p.y+p.hit_u,self,col_type.player) then
                            climb_goal.x = ((p.x\8)+1)*8
                            climb_goal.y= ((p.y\8))*8
                            p.state = p_state.s_climb
                            now_climb_time = max_climb_time
                        end
                    elseif f_angle == key_l then
                        p_hp_now -= climb_power_v

                        if not check_position_solid(p.x+p.hit_l-1,p.y+p.hit_u,self,col_type.player) then
                            climb_goal.x = ((p.x\8))*8
                            climb_goal.y= ((p.y\8))*8
                            p.state = p_state.s_climb
                            now_climb_time = max_climb_time
                            p.is_flip = true

                        end
                    elseif f_angle == key_u then
                        p_hp_now -= climb_power_h

                        if not check_position_solid(p.x+p.hit_r-3,p.y+p.hit_u-1,self,col_type.player) then
                            p.state = p_state.walk
                            not_hook_time = 10

                        end
                    end
                end

                climb = false

                if not btn(key_x) then
                    p.state = p_state.walk
                else
                    local f_angle = p.hook_angle
                    
                    if btnp(key_u) then
                        if f_angle == key_r then
                            climb = true
                            p.acs_y = -1-gravity
                            p.acs_x = 1
                        elseif f_angle == key_l then
                            climb = true
                            p.acs_y = -1-gravity
                            p.acs_x = -1
                        end
                    elseif  btnp(key_d) then
                        if f_angle == key_r then
                            climb = true
                            p.acs_y = 2-gravity
                            p.acs_x = 1
                        elseif f_angle == key_l then
                            climb = true
                            p.acs_y = 2-gravity
                            p.acs_x = -1
                        end
                    elseif  btnp(key_r) then
                        if f_angle == key_u then
                            climb = true
                            p.acs_y = -gravity
                            p.acs_x = 1
                            
                        end
                    elseif  btnp(key_l) then
                        if f_angle == key_u then
                            climb = true
                            p.acs_y = -gravity
                            p.acs_x = -1
                        end
                    end
                end
            end
        elseif p.state == p_state.s_climb then
            now_climb_time -=1
            if now_climb_time <0 then
                p.state = p_state.walk
                p.x = climb_goal.x
                p.y = climb_goal.y
            elseif now_climb_time == 2*max_climb_time\3 then
                p.y = climb_goal.y+3
                not_hook_time = 10
            end
        elseif p.state == p_state.h_get then
            get_time-=1
            if get_time <0 then
                get_time = get_max_time
                p.state = p_state.walk
            end
        end 


        for k = 0,key_d do
            if btn(k) then
                p.angle = k
            end
        end

        p_col_d_before = p.now_col_d
        p_b_y = p.y

        
        if p.state == p_state.walk or p.state == p_state.h_move or 
            (p.state == p_state.h_stop and climb )then
            p:just_move()
        end


        p.cloth = {}
        local sx,sy =flr(p.spd_x),flr(p.spd_y)
        

        local mx = 4
        sx = mid(mx,-mx,sx)
        sy = mid(mx,-mx,sy)
        local cx,cy = p.x+4,p.y+5
        if not p.is_flip then
            cx-=1
        end
        local col = 4
        
        add(p.cloth,{x=cx,y=cy,size= 1,time =0})
        add(p.cloth,{x=cx-sx*0.5,y=cy-sy*0.5+1,size= 1,time =0})

        --sprite setting
        local s = 1

        if p_state_check(p_state.h_throw) or p_state_check(p_state.wait_move) then
            s=5
        elseif p_state_check(p_state.h_move) then
            s=5
        elseif p_state_check(p_state.h_stop) then
            p.is_flip = false
            if p.hook_angle == 0 then
                s=6
            elseif p.hook_angle == 1 then
                s=7
            elseif p.hook_angle == 2 then
                if p.spd_x ==0 then
                    s=8
                else
                    s=24
                end
            end
        elseif p_state_check(p_state.s_climb) then
            if now_climb_time <= 2*max_climb_time/3 then
                s=25
            else
                s = 9

            end
        elseif p_state_check(p_state.h_get) then
            s=21
        else --walk
            if abs(p.spd_x) >0.1 then
                s = frame_to_table({2,3,4},3)
            end
        end
        p.spr = s

        -- p.x = mid(0-p.hit_l,p.x,128-p.hit_r)
        check_area_player()
        
    end
    --pd
    p.draw = function()
        if p_state_check(p_state.h_throw) or p_state_check(p_state.h_move) or p_state_check(p_state.wait_move) then
            -- rectfill(p.x+2,p.y+2,p.f_p_x+1,p.f_p_y+1,4)
            line(p.x+3,p.y+3,p.f_p_x,p.f_p_y,6)
            circfill(p.f_p_x,p.f_p_y,1,7)
        end
        
        
        
        
        for c in all(p.cloth) do
            if c.time <=0 then
                del(p.cloth,c)
            end
            circfill(c.x,c.y,c.size,4)
        end

        local t = time()

        obj.draw(p)
        if input_catch then
            spr(19,p.x,p.y,1,1,p.is_flip)
        end
        if debug then
            -- cursor(cam_x+8,cam_y+16,12)
            -- print("player")
            -- print("d:"..tostr(p.now_col_d))
            -- print("u:"..tostr(p.now_col_u))
            -- print("l:"..tostr(p.now_col_l))
            -- print("r:"..tostr(p.now_col_r))
            -- print(p.spd_x)

        -- print(p_hp_now.."/"..p_hp_max,p.x+16,p.y,4)

        end

        
        local fx,fy =p.x+f_margin_x,p.y+f_margin_y
        if p.angle == key_l then
            fx -=hook_length
        elseif p.angle == key_r then
            fx +=hook_length
        elseif p.angle == key_u then
            fy -=hook_length
        elseif p.angle == key_d then
            fy +=hook_length
        end

        if p_hp_now < p_hp_max or p.state == p_state.h_stop then
            local st = {49,50}
            local spd = 1
            local h_color =10
            
            if p_hp_now < p_hp_max *2/3 then
                if p_hp_now < p_hp_max *1/3 then
                    if p_hp_now < p_hp_max *1/6 then
                        spd =5
                        h_color =8
                    else
                        spd =3
                        h_color =8
                    end
                else
                    spd =2
                    h_color =9
                end
            end
            pal(8,h_color)
            s = frame_to_table(st,spd)
            spr(s,p.x+6,p.y-3)
            pal(8,8)

        end


        fk_range_x = move(fk_range_x,fx,0.1)
        fk_range_y = move(fk_range_y,fy,0.1)
        spr(18,fk_range_x-2,fk_range_y-2)
        
        -- local c_x,c_y = 64+8,96
        -- local r = 6
        -- local r_col = {8,10,11,14}
        -- local katu = 100
        -- bun +=1
        -- if bun >=katu then
        --     bun =0
        -- else
        -- end
        -- for i = 0,bun do
        --     line(c_x,c_y,c_x+r*cos(i/katu),c_y+r*sin(i/katu),r_col[1])
        -- end

    end
    p.draw_front = function()
        local function draw_reverce_circle(s)
            local c = 7
            local cx,cy = p.x+3,p.y-5
            local uy = cy-s
            local dy = cy+s
            local lx = cx-s
            local rx = cx+s
            rectfill(cam_x-1, cam_y-1,   cam_x+128, uy,7)
            rectfill(cam_x-1, dy,      cam_x+128, cam_y+128,7)
            rectfill(cam_x-1, cam_y-1,   lx,        cam_y+128,7)
            rectfill(rx,    cam_y-1,   cam_x+128, cam_y+128,7)

            local r = s
            local square_top = cy - r
            local square_bottom = cy + r
        
            for i = 0, 1, 0.001 do
                local angle = i * 2
                local x = cx + cos(angle) * r
                local y = cy + sin(angle) * r
                if y <= cy then
                    line(x, square_top, x, y)
                else
                    line(x, square_bottom, x, y)
                end
            end
        end
        if p_state_check(p_state.h_get)then
            spr(20,p.x,p.y-8)
            local s= max(12,128*(get_time-(get_max_time-circle_max_time))/circle_max_time)
            draw_reverce_circle(s)
            fade_out_time = 12
        elseif fade_out_time >0 then
            fade_out_time *= 0.8
            local s= max(12,128*(1-fade_out_time/12))
            draw_reverce_circle(s)
        end
    end
end

    bool_to_str = function(r)
        return r and "t" or "f"
    end

    -- clth = {}
    -- function make_cloth(x,y)
    --     clth.positions = {}
    --     clth.dir_vec = {}
    --     clth.speed = {}
    --     local num = 4
    --     for i = 1,4 do
    --         add(clth.positions,x,y)
    --     end
    -- end


function wind_player()
    local p = player
    if p.state == p_state.walk then
        player.acs_x+=wind_x
        player.acs_y+=wind_y
    end
end

function make_hook(angle,p)
    local sx,sy = p.x+f_margin_x,p.y+f_margin_y
    local mx,my = 0,0
    local margin =1

    if angle == key_l then
        mx = -1
    elseif angle == key_r then
        mx = 1
    elseif angle == key_u then
        my = -1
    elseif angle == key_d then
        my =1
    end

    local col = false
    local count = 0
    local change=0

    while(true) do
        count+=1
        sx += mx*margin
        sy += my*margin
        change +=margin


        -- if check_position_solid(sx,sy,player,col_type.hook) then
        local cb = col_type.hook+col_type.no_hook
        if (get_col_type(sx,sy,player)&(cb))|0 >0 then
            local no = 10
            local b_no = no
            while(no>0)do
                b_no = no
                no = get_col_type(sx,sy,player)
                sx -= mx
                sy -= my
            end
            col = b_no--&col_type.hook == col_type.hook
            break
        end
        
        if change >hook_length then
            break
        end

        if count >1000 then
            break
        end
    end

    return col,sx,sy


end

function draw_tutorial()
    local col1,col2 = 7,13
	spr(btn(⬅️) and 52 or 53,12,98)
	spr(btn(➡️) and 52 or 53,28,98,1,1,true)
	spr(btn(❎) and 54 or 55,51,104)
	spr(btn(⬆️) and 56 or 57,59,100)
	spr(btn(⬇️) and 58 or 59,59,107)
end


-->8
--map

m = {24,16,8,0,26,18,10,2}
get_map_no = function(height,width)
    local h= height%4
    local w = height\4
    -- return (3-h)*8+w*2+0--(width and 1 or 0)
    return (3-h)*8+w*1
end

get_map_height=function(no)
    -- no = (no\2)*2

    local h = ((no%8))*4+(3-no\8)
    return h
end

get_map_pos = function(no)

    local y = get_map_height(no)*(-128)
    local x = 0--(no%2)*128

    return x,y
end

function inport_map(no)
    local rx,ry = (no%8)*16,(no\8)*16

    for x = rx,rx+15 do
        for y = ry,ry+15 do
            
            local cell= mget(x,y)
            local frag = fget(cell)

            local mx,my =get_map_pos(no)
            local px = (x-rx)*8+mx
            local py = (y-ry)*8+my

            if cell == 1 then
                make_player(px,py)
            elseif cell == 20 then
                make_item_hook(px,py)
            elseif cell == 68 then
                make_break_block(px,py)
            elseif cell == 75 then
                set_wind(py)
            elseif cell == 74 then
                set_weather_points(py)
            elseif cell == 76 then
                goal_y = py
                test = goal_y
                sun.y = goal_y+12
                sun.goal = goal_y-40
            end
            
            
        end
    end
    sort_descending(wind_pos)
    sort_descending(weather_points)
end

--item

function make_item_hook(px,py)
    py-=4
    local c = make_object("hook",px,py,20)
    c.is_area = true
    c.now_player_on = function(c)
        del(objects,c)
        p_has_hook = true
        player.state = p_state.h_get
        music_play(-1)
        se(8)
    end
    c.update = function()
        c.y+= 0.2*sin(-frame/60)

    end
end

function draw_map(tag)

    for i = 0,31 do
        local no = get_map_no(i)
        map((no%8)*16,(no\8)*16,0,-128*i,16,16,tag)
        no+=1
        map((no%8)*16,(no\8)*16,128,-128*i,16,16,tag)
    end
end

function get_map_x_y(x,y)
    local no = get_map_no((127.5-y)\128)
    if x>127 then
        no+=1
    end

    local mx,my = x%128,y%128

    mx +=(no%8)*128
    my +=(no\8)*128
    return mx,my
end

function check_map_collide(x,y)
    
    if x<0 or x>128 then
        return col_type.player
    end
    
    local no = get_map_no((127.5-y)\128)
    if x>127 then
        no+=1
    end

    local mx,my = x%128,y%128

    mx +=(no%8)*128
    my +=(no\8)*128

    return get_map_flag(mx,my)
end


function check_map_spr(x,y)
    return mget(x\8,y\8)
end

function get_map_flag(x,y)
    local celx,cely = flr(x/8),flr(y/8)
    local cell = mget(celx,cely)

    -- local cell = get_map_cell(x,y)
    
    return fget(cell),cell
end



-->8
--camera
cam_y_bottom = 0
function init_camera()
    camera_shake_time = 0
    camera_shake_strong = 0

    cam_x =0
    cam_y =0
    camera(cam_x,cam_y)
end

local cam_change_x,cam_change_y = 0,0


function update_camera()
    local change = 3
    cam_change_x,cam_change_y = 0,0

				local move_start_time = 10
    if title_time>=move_start_time then
        cam_y = goal_y-63
       	if title_time == move_start_time then
       		se(23)
       	end
    else
        cam_y = move(player.y-60,cam_y,0.2)

        cam_y = min(cam_y,cam_y_bottom)
        cam_x = 0
    end

    if camera_shake_time > 0 then
        cam_x += rnd(camera_shake_strong)-camera_shake_strong
        cam_y += rnd(camera_shake_strong)-camera_shake_strong
        camera_shake_time -=1
    else
        -- cam_x,cam_y =0,0
    end

    camera(cam_x+cam_change_x,cam_y+cam_change_y)
end
--mouse
local put_tile = {67,84,100}
local put_back = {103,72,73,88,89}
local last_changes = {}

local now_put_no = 1
local now_put_table =put_tile

local function change_put_table()
    if now_put_table == put_tile then
        now_put_table = put_back
    else
        now_put_table = put_tile
    end
end

function update_mouse()

    mouse_x+=cam_x
    mouse_y+=cam_y

    local cx,cy = mouse_x,mouse_y

    if mouse_btn == 1 then
        local mx,my = get_map_x_y(cx,cy)
        mx,my =flr(mx/8),flr(my/8)
        local l = mget(mx,my)
        if mget(mx,my) ~= now_put_table[now_put_no] then
            mset(mx,my,now_put_table[now_put_no])
            -- last_change = {x=mx,y=my,l=l}
            add(last_changes,{x=mx,y=my,l=l})
        end
    elseif mouse_btn == 2 then
        local mx,my = get_map_x_y(cx,cy)
        mx,my =flr(mx/8),flr(my/8)
        local l = mget(mx,my)

        if mget(mx,my) ~= 0 then

            -- last_change = {x=mx,y=my,l=l}
            add(last_changes,{x=mx,y=my,l=l})

            mset(mx,my,0)
        end
    elseif mouse_btn == 4 then
        player.x = mouse_x 
        player.y = mouse_y
    elseif btnp(key_r,1) then
        now_put_no +=1
        local n = #now_put_table
        if now_put_no <1 then now_put_no = n end
        if now_put_no >n then now_put_no = 1 end
    elseif btnp(key_l,1) then
        now_put_no -=1
        local n = #now_put_table
        if now_put_no <1 then now_put_no = n end
        if now_put_no >n then now_put_no = 1 end
    elseif btnp(key_u,1) then
        change_put_table()
    elseif btnp(key_x,1) then
        -- if last_change ~=nil then
        if #last_changes >0 then
            local last_change = last_changes[#last_changes]
            mset(last_change.x,last_change.y,last_change.l)
            del(last_changes,last_changes[#last_changes])
        end
    end
end

function draw_mouse_things()

    if debug then
    local cx,cy = mouse_x,mouse_y

    spr(now_put_table[now_put_no],(mouse_x\8)*8,(mouse_y\8)*8)
    -- circ((mouse_x\8)*8,(mouse_y\8)*8,3,9)
    circ(mouse_x,mouse_y,1,9)
    sprint(check_map_collide(cx,cy),mouse_x+10,mouse_y,10,0)

    -- local mx,my = get_map_x_y(cx,cy)
    -- mx,my =flr(mx/8),flr(my/8)
    -- sprint(mx..","..my,mouse_x+3,mouse_y+8,10,0)
    -- sprint(mouse_x..","..mouse_y,mouse_x+3,mouse_y+16,10,0)
    -- sprint(mouse_x-cam_x..","..mouse_y-cam_y,mouse_x+3,mouse_y+16,10,0)

    pset(mouse_x,mouse_y,10)
    end
end


function camera_shake(time,strong)
    camera_shake_time = time
    camera_shake_strong = strong
end

--title
title_time = 40
function update_title()
    if is_title then
        if key_hold(key_x) or key_hold(key_z) then
            start_time = time()
            is_title = false
            se(22)
        end
    else
        if title_time>0 then
            title_time -=1
        end
    end
end

function draw_title()
    if is_title or title_time>20 and title_time%4 < 2 then
        local xp,yp = 32,cam_y+28
        
        pal(7,1)
            for x = -1,1 do
                for y = 0,2 do
                    spr(90,32+x,yp+y,4,1)
                    spr(106,32+32+x,yp+y,4,1)
                end
            end
        pal(7,7)
        spr(90,32,yp,4,1)
        spr(106,32+32,yp,4,1)

        rectfill(xp-10,yp+3,xp-3,yp+5,1)
        rectfill(xp+61,yp+3,xp+68,yp+5,1)

        print("❎/🅾️",hcenter("❎/🅾️")-3,cam_y+60,7)
    end
end



-->8
--break_brock

break_block_time = 60
block_respawrn_time = 120
function make_break_block(x,y)
    local b = make_object("break",x,y,68)

    b.broken = false
    b.time = 0
    b.now_true = true
    b.is_solid = true
    b.is_area = true
    b.start_broken = function(b)
        if b.broken then return end
        b.broken = true
        b.time = break_block_time
    end
    b.update = function(b)
        if b.now_true == false then
            b.time -=1
            if b.time <0 then
                if b.now_player == false then
                    b.broken = false
                    b.now_true = true
                    b.is_solid = true
                    b.spr = 68
                end
            end
        end

        if b.broken then
            b.time -=1
            if b.time <= break_block_time*2/3 then
                b.spr = 69
            end
            if b.time <= break_block_time*1/4 then
                b.spr = 70
            end
            if b.time <0 then
                b.now_true = false
                b.time = block_respawrn_time
                b.is_solid = false
                b.is_area = true
            end
        end
    end
    b.draw = function(b)
        if b.now_true then
            obj.draw(b)
        end

        if debug then
            print(b.time,b.x,b.y)
        end
    end

end

--




-->8
--wind
wind_x = 0
wind_y = 0

wind_change_time = 5
wind_time = 0
local now_wind = false

wind_pos= {}

function set_wind(y)
    add(wind_pos,y)
end

function sort_descending(arr)
    local n = #arr
    for i = 1, n - 1 do
        for j = 1, n - i do
            if arr[j] < arr[j + 1] then
                local temp = arr[j]
                arr[j] = arr[j + 1]
                arr[j + 1] = temp
            end
        end
    end
end

function check_wind_blow(y)
    for i =1,#wind_pos,2 do
        if i+1 <=#wind_pos then
            if y < wind_pos[i] and y>wind_pos[i+1] then
                return true
            end
        end
    end
    return false
end

update_wind = function()
    wind_player()
    if player then
        if check_wind_blow(player.y)  then
            if not now_wind then
                now_wind = true
                music(1)
            end
            wind_time -= 1/30
            if wind_time<=0 then
                local x = -0.3
                if wind_x ~= x then
                    se(9)
                    wind_x = x
                else
                    wind_x = 0
                end
                wind_time = wind_change_time
            else
               
            end
        else
            music(3)
            now_wind = false
            wind_time = 0
            wind_x = 0
        end
    end

    if abs(wind_x)>0 then
        make_dust()
    end

end


draw_wind = function()
    

    
    if debug then
        print(check_wind_blow(player.y),cam_x,cam_y+8*#wind_pos+8)
        cursor(cam_x+10,cam_y+90,8)
        -- print("wind:"..wind_x)
        -- print("time:"..wind_time)
        print("pal_number:"..pal_number)
        
            for i=1,#weather_points do
                print(weather_points[i],cam_x,cam_y+8*i,0)
            end 
    end
end

--weather
weather_points ={}
now_whether = 1
set_weather_points = function(y)
    add(weather_points,y)
end


update_weather = function()
    if not pal_change then
        if end_everything() then
            pal_number =1
        else
            local py = player.y or 0

            if pal_number > #weather_points then
            	
                return
            end

            if py < weather_points[pal_number] then
            sfx(24)
                -- pal_number = mid(pal_number+1,1,#ch_colors)
                pal_number = pal_number+1
                -- if c then
                --     for i = 1,#cols do
                --         pal(cols[i],ch_colors[pal_number][i])
                --     end
                -- end
            end
        end
    end
end

__gfx__
0000000002222200022222000266660002222200022222900022222000222220926666090000660900044400000a4400000444000004440000a222a000000000
00000000026666000266660006111160026666000266660000266660006666200611116000261190004444400044444000444440004444400044444000000000
00700700061111600611116006116160061111600611116000611116061111600611616000261690000a9900000a9900000a990000099a00000a990000000000
00077000061161600611616009999900061161600611616000611616061611600999990000261190000aaa00000aaa00000aaa00000aaa00000aaa0000000000
0007700009999900099999000222200009999900099999000099999000999990002222000026119000a444000004440000a44000000044a00004440000000000
00700700022220000222206002222600022220000222200000922200000222900022220000226620000444a0000444a000444000000044400004440000000000
00000000022220000222226006000600622220006222200000222200000222200600006000002220000444000094440000444000000044400004440000000000
00000000066006600660000000000000600006600000600000600000000000600000000000000060000909000000900000900000000000900090009000000000
99999999006000000000000000000000575000009000009000000000000000000266669000222220000000000000000000000000000000000000000000000000
99999999076600000282000000000000776555000266660000000000000000000611116000266660000000000000000000000000000000000000000000000000
99999999666660000888000000000000575665000611116000000000000000000611616000611116000000000000000000000000000000000000000000000000
99999999066600000282000000000000050556500611616000000000000000000999990000611616000000000000000000000000000000000000000000000000
99999999006000000000000000000000005665000999990000000000000000000022220000999990000000000000000000000000000000000000000000000000
99999999000000000000000000000290056555500222200000000000000000000022226000022229000000000000000000000000000000000000000000000000
99999999000000000000000000000000005d44450222200000000000000000000060000000002220000000000000000000000000000000000000000000000000
99999999000000000000000000000000000555500600600000000000000000000000000000000060000000000000000000000000000000000000000000000000
061111600000000006666660006111000222220002666600000000001777777192222290000ddd00000000000000000000000000000000000000000000000000
061161600000000006116160008666000266660006111160000000007777d7770266660000d000d0000000000000000000000000000000000000000000000000
09999900000000000999990000f1f10006111160061161600000000077dddd77061111600d00d00d000000000000000000000000000000000000000000000000
09919100000000000999990000ffff000611616009229200000000006dddddd6061161600d0d000d000000000000000000000000000000000000000000000000
099999000000000009999900008888000999990009999900000000006dddddd6099999000d00d00d000000000000000000000000000000000000000000000000
022220000000000002222000081811800222220002222200000000006dddddd60022220000d000d0000000000000000000000000000000000000000000000000
022220000000000002222000801111000222220002222200000000006dddddd600222200000ddd00000000000000000000000000000000000000000000000000
0660066000000000066006600088088006600660066006600000000066dddd660600006000000000000000000000000000000000000000000000000000000000
0800080000000000000000000000000000077700000ddd0000077700000ddd000000000000000000000000000000000000000000000000000000000000000000
888088800080800000000000000000000070007000d000d00070007000d000d00000000000000000000000000000000000000000000000000000000000000000
88888880088888000080800000808000070070070d00d00d070707070d0d0d0d0000000000000000070700000d0d000000000000000000000000000000000000
88888880088888000088800000888000070700070d0d000d070070070d00d00d00000000000000000070000000d0000000000000000000000000000000000000
08888800008880000008000000080000070070070d00d00d070707070d0d0d0d0070000000d00000000000000000000000000000000000000000000000000000
008880000008000000000000000000000070007000d000d00070007000d000d0070700000d0d0000000000000000000000000000000000000000000000000000
0008000000000000000000000000000000077700000ddd0000077700000ddd000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17777777777777777777777117777771bbb3bbbbbbb3b3bbb3b3b3bb111551111111111111111111111f111111f1111111111111000000077000000000000000
7777777777777777777777777777d777b665666bb665656bb56565631151151111111110011111111f111f111f11111111ffff11000000777700000000000000
7777dddddddddddddddddd7777dddd77b656666bb656566bb656565b15111151111111000011111111fff11111ff11111f111f11000007711770000000000000
77ddddddddddddddddddddd76dddddd6b6666553b656655336556553151111511111100000011111f1fff1f11111fff11f111111000077111177000000000000
6dddddddddddddddddddddd66dddddd6b656556bb655556bb655555351111115111100000000111111fff11111f111111f11ff11000771111117700000000000
6dddddddddddddddddddddd66dddddd63566666b3556556b3556556b1111111111100000000001111f111f111f1f11111f111f11007711111111770000000000
6dddddddddddddddddddddd66dddddd6b665666b3665666b3665566b111111111100000000000011111f11111f1111111fffff11077711111111177000000000
6dddddddddddddddddddddd666666666bbb3bbbbbbb3bbbbbbb3b3bb1111111110000000000000011111111111ffff1111111111771111111111117700000000
6dddddddddddddddddddddd61777777111dddd111111111100000000ffffffff1000000000000001770007700000000007000077000770000000000000000000
6dddddddddddddddddddddd6777777771dddddd11111111100000000ffffffff1100000000000011770007700000000007000077707770000000000000000000
6dddddddddddddddddddddd67777dd77ddd77ddd1111111100000000ffffffff1110000000000111770007700000000007007077777770000000000000000000
6dddddddddddddddddddddd67dddddd7dd7667dd1111144100000000ffffffff1111000000001111777777700770077007070077070770077000000000006000
6dddddddddddddddddddddd66dddddd6dd1661dd1111445100000000ffffffff1111100000011111777777707007700707700077000770700760060666066600
6dddddddddddddddddddddd66dddddd6ddd11ddd1444451100000000ffffffff1111110000111111770007707007700707700077000770700760060600606000
6dddddddddddddddddddddd66dddddd61dddddd11154414400000000ffffffff1111111001111111770007707007700707070077000770700760060600606000
6dddddddddddddddddddddd66dddddd611dddd111445544100000000ffffffff1111111111111111770007700770077007007077000770077006600600606600
6dddddddddddddddddddddd66dddddd6766666670000000000000000111111111111111111111111000000000000000000000000000000000000600000000000
6dddddddddddddddddddddd66dddddd6677676760000000000000000111111111111111551111111000000000000000000000000000000000000000000000000
6dddddddddddddddddddddd66dddddd6677667660000000000000000111111111111115555111111000000000000070000070700000000000000000000000000
6dddddddddddddddddddddd66dddddd6666776760000000000000000111111111111155555511111700700707770777007770007077000000000000000000000
6dddddddddddddddddddddd66dddddd6676776660000000000000000111111111111555555551111070700707007070070070707707000000000000000000000
6dddddddddddddddddddddd66dddddd6667667760000000000000000111111111115555555555111070700707007070070070707007000000000000000000000
6dd7ddddd7ddddd7ddd7dd666dddddd6676767760000000000000000111111111155555555555511070700707007070070070707007000000000000000000000
7667776667766667766766676dddddd6766666670000000000000000111111111555555555555551700077007007077007770707007000000000000000000000
1777777777777777777777716dddddd6080008000000000000000000111111111555555555555551000000000000000000000000000000000000000000000000
7777777777777777777777776dddddd6888088800080800000000000111111111155555555555511000000000000000000000000000000000000000000000000
7777dddddddddddddddddd776dddddd6888888800888880000808000115111111115555555555111000000000000000000000000000000000000000000000000
77ddddddddddddddddddddd76dddddd6888888800888880000888000151111111111555555551111000000000000000000000000000000000000000000000000
6dddddddddddddddddddddd66dddddd6088888000088800000080000151111111111155555511111000000000000000000000000000000000000000000000000
6dddddddddddddddddddddd66ddd7dd6008880000008000000000000115111111111115555111111000000000000000000000000000000000000000000000000
6dddddddddddddddddddddd66dd7ddd6000800000000000000000000111511111111111551111111000000000000000000000000000000000000000000000000
76667766677666666667666776776667000000000000000000000000111111111111111111111111000000000000000000000000000000000000000000000000
00957676767676767676767676760000757676850000071717171717247600007575767606172700767684000000947675750000767676767676767676760000
75757676767676457676767676767676000000000000000000000000000000007575000000000000000000000000000075750000000000000000000000000000
95767604142476767676767676768500753576760000947676767676367600007576767676767676768400000000009475840000760717277677767676350000
75767676767676767676767676768400000000000000000000000000000000007500000000000000000000000000000075000000000000000000000000000000
76760415152576767676767676767676760524760000009476767676367600007676767676767676840000000000000084000095767676767677767676360000
76767676767676767676767676760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76041515151514141424767676763476760626760000000094767676367600007676767676767684000000000000000000000076777777777776767676370000
76767676767676767676767676768595000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76051515151515151525767676767676767676840000000000947676377600007676767676844500000000000000000000009576767676767676767676768500
76767676767676767676767676767676000000000000009585000000000000000000000000000000000000000000000000000000000000000000000000000000
14151515151616161616277676347676767684000000000000000000767600007676767684000000000000000000000000957677767777777634767676767600
76767676764576767676767676767676000000000000957676850000000000000000000000000000000000000000000000000000000000000000000000000000
15151515257676850000947676767676768400000000000000000035767600007676768400000000000000000000000095767676777776767676767676767685
767676767676767676767684007676760000000000d476c47676e400000000000000000000000000000000000000000000000000000000000000000000000000
1515161626767676850095767676767676000000000000000000003776768500767684000000957685000000000000009476b476760717172776767676767676
767676767676767676767600007676760000000095760414142476e4000000000000000000000000000000000000000000000000000000000000000000000000
15267676767676767676767676767635768500000007172776767676767676857684000000950424768500000000000095767676767676767676767676767676
76767676457676767676768500947676000000d47604151515152476e40000000000000000000000000000000000000000000000000000000000000000000000
26767676767676760414247676760425a47685000076767676767676041424767600000000041525767685000000000076767676767676767676767676767676
767676767676767676767676000076760000d4767605151515152576768500000000000000000000000000000000000000000000000000000000000000000000
76767607171717171616267676760626767676850076767676767676061626767685000095061616247676850000000076840095767676767676767676767676
76763576767676767676767685009476009576760415151515151524767685000000000000000000000000000000000000000000000000000000000000000000
76767676767676767676840094767676763576767676767676767676767676767676453546464646377676767676767676859576767676041424767676767676
76763676767676767676767676000076957676760515151515151525767676e40000000000000000000000000000000000000000000000000000000000000000
76767676767676767684000000947676763676767634767676767676767676767676763676767676767676767676767676767645760717161626767676767676
76763776767676767676767676000094767676041515151515151515247676760000000000000000000000000000000000000000000000000000000000000000
17172776760717277600000041009476760524767676767676767684000000007676763776767676767676767676767676767676767676767676767676767676
76767676767676764576767676000000767676051515151515151515257676760000000000000000000000000000000000000000000000000000000000000000
76767676767676767685000035000076760625767676767676767685950727857676767676767676767676767676767676767676767676348476767676767676
00009576767676767676767676850000757607151515151515151515152776760000000000000000000000000000000000000000000000000000000000000000
76767604247676767676850415240076767637767676767676767676767676767676767634767676767676767676767676767676767676760076767676767676
0095767676767676767676767676767676767606161515151515151626a476350000000000000000000000000000000000000000000000000000000000000000
76760415257676767676041515250094767676767676767676767676767676767676357676457676767676767676767675767676767684760034767676767676
757676767676767676767676767676767576b4767606151515162676767676377500000000000000000000000000000075000000000000000000000000000000
75041515257676767604151515250000767676767676760424767676767676767676367676767676767676767676767676767676767685760076767676767676
76767676767676a47676767676767676767676767676061526767676767676760000000000000000000000000000000000000000000000000000000000000000
76051515267676041415151515152400767676767676760626767676767676767676377676767676767676767676767676767676767676760076767676767676
76767676767676764676467676767676767676767676763676767676767676760000000000000000000000000000000000000000000000000000000000000000
76051525767676051516161616162600947676760414277676767676767676358494767676767676457676767676767676767676767676768576767676767676
76767676767676764645467676767676767676767676763676767676777676760000000000000000000000000000000000000000000000000000000000000000
76051525767604162676767676768500009476760525767676767676767676360000000094042476767676767676768400760717277676767676767635767676
94767676767676764676467676767676767676767676763776767676767676760000000000000000000000000000000000000000000000000000000000000000
76051515247637767676767676767685000094760525767676767676760414260000000000052576767676767676840095767676767676767676767636457676
00767676767676764676467676767676947676767676767676767776767676840000000000000000000000000000000000000000000000000000000000000000
94051515257676767676767676767676000000940525767676767676760525760000000000062576767676767684000076767676767676767676767636768400
00947676767676767676767676767676007676777676767676767676767676000000000000000000000000000000000000000000000000000000000000000000
00061615152476767676767676767676000000000525767676767676760626760000000095760617172745768400000076767676767676767676767637768500
00007676767676767676767676767676007676777676767676767676767676000000000000000000000000000000000000000000000000000000000000000000
00000006152576767676767676767676000000000525767607171727009576840000009576767676767676760000000076767676764576767676767676767685
00007676763576072476847676840000957676767776764576767676767676850000000000000000000000000000000000000000000000000000000000000000
00009576061524767676760414247676000000000525767600000000957676000000957676767676767676760000000076767676767676767676767676767676
00007676763776763776857676000000767676767676767676767676777676760000000000000000000000000000000000000000000000000000000000000000
10957676760615142476760515257676000000000525767600000095767676000095767676767676767676348500000076760717277676767676767676767676
00007676767676767676767676000000767676767676767676767776767676760000000000000000000000000000000000000000000000000000000000000000
76767676767606162676041515151424000000950626767685000076763476007676348400000094767676767676767676767676767676767676767676767676
00957676767676767676767676850000767676767676767676767676767676760000000000000000000000000000000000000000000000000000000000000000
76767676767676767676051515151525000095767676767676340076767676003576840000000000347676763576767694767676767676767676767676767676
00767676767676767676763446468500767676763576764576767676767676760000000000000000000000000000000000000000000000000000000000000000
76767676767676760414151515151525009576767676767676768576767676003676850046344695764607172676767600947676767676767676767676767676
00767676767676767676767676767676767676760627767676763476767676760000000000000000000000000000000000000000000000000000000000000000
76767676767676041515151515151525957676767676767676767676767676850617248500767676840000009476767676767607172776767676767676767676
95767676760717277676767676767676767676767676767676767676767676760000000000000000000000000000000000000000000000000000000000000000
17171717171717161616161616161616172776767676767676767676767676767600062785767684000000000094767676767676767676760727767676767676
76767676767676767676767676767676767676767676767676767676767676760000000000000000000000000000000000000000000000000000000000000000
__gff__
000000000000000000000000000000000100000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000707070700000001010101010101010007070707050100010101000000000000070707070b000001010100000000000007070707020202010101000000000000
0800000002020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6767674041414267676767676767676757575757676767580000000000004967575767676767676767676767676767675757676767676767676767676773676757676767676777777767676767676767575767676767676767676767676767675757676767676767676767676767676757576767676767676767676767676767
6767676061616267484967676767676757000049676767676767675800000049676767676767676767676767676767676767546767676767676767676764676767676767707171717172676767676767670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
6767676767676748000049676767676767000000404142676770726700000000676767676767676767676767676767676767676464647072676767676743676767676767676767676767676767676767670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
4142676767674800000000496767676767000000505152484967676700000000676767676767676767676767676767676767676467676767676767676748000067676767677777777767676767676767670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
6152676767675800000000000049676767000059505152000067676700000000676767546767676767676767676748676753676467676767676767674800000049676754677777677777676767676767670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
6750414141426758000000000000496767000067606162005967676700000000674967676767676767676767674800676773676767676767676767480000000000676767676767777767676767676700670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
4960615151526767580000000000004967000049676758596767404200000000670049676753676754676767480000676767676467676767676748000000000000675467676777777767676767676700670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
0049676051514142675800000000000067000000676767674849606258000000670000676763676767676767676758676767674367676767676700000000000000676767677767676767676767674800670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
0000496760616161417258000000000067000000404142480000496767580000670000676760717267676767676767676767676767677072676758000000000000496767676767676767676767480000670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
0000004967676767636767435800000067000000606162580000004967675800670000676767676767676767676767676767676767676767676767676767580000006770717171717171726767000000670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
0000000000496767636767676758000067000059676767675800005367674358676767676767676767676767676767676767676767676767676767676767675800596767676767676767676767000000670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
0000000000004967636767676767580067005967676767676758006367676767676767676767676767676767707172676767676770726767676767676767676700676767676767676777676767580000670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
0000000000000067607267674042675867676767676767676767586041424943676767676770717172676767676767486767676767676767676767676767676700676777777777677767676767676758670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
0000000000005967676767676052676767676767676767676767676750520049676767676767676767676767676748006767676767676767676767676767676700676777676767676777676767676767670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
0000596767676767676767676773676767676767676767676767676750526767676767676767676767676767674800596767707267676767676767676767676700676767777777677767675467676767670000000000000000000000000000676700000000000000000000000000006767000000000000000000000000000067
0059677072676767676749676767670067676767676767676767676750526767676767676767676767675467670059676767676767676767676767676767676767676767776767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767
67676767676767676767004967676700575757676767674348000049505172675767676767674042496767676767676757674b4071726464644a67676767674857676767676767646767676767676748570000000000000000000000000000005700000000000000000000000000000057000000000000000000000000000000
6740426767676767676767676767676757676767676753670000000050526767676467676767606200676467676767675349676367676767776767676767480067674b67676767647071726767480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6750526767676767707171717267676767676767676773480000000060626767676467676767480059536467676767676300706267677767676767676767580067676767676767676767676767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67505267676767676767676767676767676767674072480000000000004967676764674a6748005967636767676767677300676767677767676767675367670067676767676767676767676767000059000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6750514267676767674800000000496767676767736700000000000000004967674041414200596767734967676767670000676767777767776767676367670067676767546767676767676767000067000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6750515267676767670000000000004967676767674800000000000000000067676061616267676767675849676767670000676777677767777767677354670067676767676767676767676767000067000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6760616171717248000000000000000067676767480000000000005967676767674800496767676767676758676767480064676767676767777767676767670067676767676767676767676767000049000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6748004967676700005967675800000067676767000000000000596767676767480000004967676767677041426748000064646464646467677767676767670067676767676767676767676767580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4800000067676767676770726700000067676767000000000000436767676767000000000067676767676750626700000000006767676767676767676767670067676767676767676767676767670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000040414200004967676700000067675367580000000000676767676748000000000067676767436773674800000000006767776754676767676767480067676767676767676767676767670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000050516200000000496700000067486071725870717172676767674800000000000067676767676767480000000000006777776767676767676753000067676767676767676767676767670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000050524800000000006700000048000049676767676767676767480000000000005967676767676767000000000000006767676767676767676773000067676767675467676767676767670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000050520000000059676700000000000000496767674800496767000000005967676767676767676767000000000000006767677072677767676767000067676767676767676767676767675800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000060620000004041414258000058000000004970717200707267000000596767676754676767675367000000000000004967676767776767676767000067676767676767676767676767676767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000596767580000606161626700004a580000000067676700596767000000677071714200494364647367676767675800000067776777776767676753000067676767676767676767676767676767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000596767676758006767676767670067675800000067676767676767580000676767676358004967676748004967676758000067677777777777676773000067676767676767676767676767676767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0004000008740097400a730087520b7020a7020a7020c7020d7000e7001070211700127001f7021f70200700007001c7001c7001c7001c7021c7021c7021c7021c7021c7051c7001c7001c7001c7000070000700
010400000a7400b7400a730087520b7020a7020a7020c7020d7000e7001070211700127001f7021f70200700007001c7001c7001c7001c7021c7021c7021c7021c7021c7051c7001c7001c7001c7000070000700
000000000000000000080110b01411024170201d03000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000f11012120001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000200001011012120001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000100002501020030070200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000412000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000200001a13016120151400010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000f0000180601a0501c0601d5501a0601c0501d0601f5501c0601d0501f040215501d0601f040210602355024550245502455024550245502455024550245502454024540245402454024530245202451024515
000a0000096500a6600b6600b6500a65009650076400664007640096300a6300a6300c6300d6200c6200962007622056120562205622066120a6120d6100d6100b6200862006610036100361004610096200a620
000d0000046100661008620086300863008630066300462004610036100261002610016100161001610016100161202612046120461206612096120a6100b6100b61008610066100361003610026100061000610
000d0000046100661008610086100861008610066100461004610036100261002610016100161001610016100161202612046120461206622096320a6300b6300b63008620066100361003610026100061000610
001700000061000610016100061000610006100161000610006100161000610006100061001600016000160001602016020060200602006120161201610016100161000610006100161000610016000160001600
00170000036100661006610086000860008610066100461004610036000260002600016100161001610016100161202602026020460206602096120a6100b6100b61008610066000360003600026000060000600
010e00002304023050230220000228040280502803224002260402605026012240022105021012230502301218002180022105021012230502301218002180022304024031260402400228040280502802200002
0110000028150281402814028132281222811228112281122115021120211121f1501f1201f1201f1101f115000001c1501c1401c1401c1321c1221c1121c1121c1121c1151c1001c1001c1001c1000000000000
0010000028150281402814028132281222811228112281121f1501f1201f1122115121120211222111200000000001c1501c1401c1401c1321c1221c1121c1121c1121c1151c1001c1001c1001c1000000000000
191700000000000000240500000000000000001f05000000000000000000000000000000000000000000000000000000001c05000000000000000024050000000000000000000000000000000000000000000000
191700000000000000280500000000000000002405000000000000000000000000000000000000000000000000000000002905000000000000000026050000000000000000000000000000000000000000000000
010e00001f1301f1201f11200102211302112021112241021c1201c1201c112241022113021112231302311218102181022113021112231302311218102181022312024131261202410228130281402812200102
000300001254015530195001450014500145001450014500145000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
011200002875028750287402874028740247502475024740247402474026750267502675026740267401f7501f7501f7501f7401f7301f7201f71500700007002876028750287502874028740287402872028710
001000002b050280502f0502f0302f0153100033000340001f000230002a0002a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000060000600006000060006620066200662006620066200662006620066100661006610056100561003610026100161000610006100060011600146001460014600146001460000600006000060000600
010600000c0500c0400c0400c03011050110401103015050150501504015020150101501015015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 09424344
01 0a424344
02 0b424344
01 0c424344
00 0d514344
02 0c524344
00 0e534344

