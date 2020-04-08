
--local abr = minetest.get_mapgen_setting('active_block_range')
local node_lava = nil
--local min=math.min
--local max=math.max

--local spawn_rate = 1 - 0.2
--local spawn_reduction = 0.75

local function lava_dmg(self,dmg)
	node_lava = node_lava or minetest.registered_nodes[minetest.registered_aliases.mapgen_lava_source]
	if node_lava then
		local pos=self.object:get_pos()
		local box = self.object:get_properties().collisionbox
		local pos1={x=pos.x+box[1],y=pos.y+box[2],z=pos.z+box[3]}
		local pos2={x=pos.x+box[4],y=pos.y+box[5],z=pos.z+box[6]}
		local nodes=mobkit.get_nodes_in_area(pos1,pos2)
		if nodes[node_lava] then mobkit.hurt(self,dmg) end
	end
end

local function hq_moveto(self,prty,tpos)
	local func = function(theself)
		if mobkit.is_queue_empty_low(theself) and theself.isonground then
			local pos = mobkit.get_stand_pos(theself)
			if vector.distance(pos,tpos) > 3 then
				mobkit.goto_next_waypoint(theself,tpos)
			else
				mobkit.lq_idle(theself,1)
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end

local function soldier_brain(self)
	-- vitals should be checked every step
	if mobkit.timer(self,1) then lava_dmg(self,6) end
	mobkit.vitals(self)
--	if self.object:get_hp() <=100 then
	if self.hp <= 0 then
		mobkit.clear_queue_high(self)									-- cease all activity
		mobkit.hq_die(self)												-- kick the bucket
		return
	end

	if mobkit.timer(self,1) then 			-- decision making needn't happen every engine step
		local prty = mobkit.get_queue_priority(self)

		if prty < 20 and self.isinliquid then
			mobkit.hq_liquid_recovery(self,20)
			return
		end

		--local pos=self.object:get_pos()

		-- -- hunt
		-- if prty < 10 then							-- if not busy with anything important
		-- 	local prey = mobkit.get_closest_entity(self,'new_rpg:npc')	-- look for prey
		-- 	if prey then
		-- 		mobkit.hq_hunt(self,10,prey) 									-- and chase it
		-- 	end
		-- end

        if prty < 9 and self._targetPos ~= nil then

            hq_moveto(self, 9, self._targetPos)
			-- local plyr = mobkit.get_nearby_player(self)
			-- if plyr and vector.distance(pos,plyr:get_pos()) < 10 then	-- if player close
            --     --mobkit.hq_warn(self,9,plyr)								-- try to repel them
            --     --mobkit.animate(self,"mine")
            --     --mobkit.make_sound(self, "attack")
            --     mobkit.hq_follow(self, 9, plyr)
            --     --print(dump(plyr:get_properties()))
			-- end															-- hq_warn will trigger subsequent bhaviors if needed
		end

		-- fool around
		--if mobkit.is_queue_empty_high(self) then
            --mobkit.hq_roam(self,0)
		--end
	end
end

-- local function spawnstep(dtime)

-- 	for _,plyr in ipairs(minetest.get_connected_players()) do
-- 		if math.random()<dtime*0.2 then	-- each player gets a spawn chance every 5s on average
-- 			local vel = plyr:get_player_velocity()
-- 			local spd = vector.length(vel)
-- 			local chance = spawn_rate * 1/(spd*0.75+1)  -- chance is quadrupled for speed=4

-- 			local yaw
-- 			if spd > 1 then
-- 				-- spawn in the front arc
-- 				yaw = plyr:get_look_horizontal() + math.random()*0.35 - 0.75
-- 			else
-- 				-- random yaw
-- 				yaw = math.random()*math.pi*2 - math.pi
-- 			end
-- 			local pos = plyr:get_pos()
-- 			local dir = vector.multiply(minetest.yaw_to_dir(yaw),abr*16)
-- 			local pos2 = vector.add(pos,dir)
-- 			pos2.y=pos2.y-5
-- 			local height, liquidflag = mobkit.get_terrain_height(pos2,32)

-- 			if height and height >= 0 and not liquidflag -- and math.abs(height-pos2.y) <= 30 testin
-- 			        and mobkit.nodeatpos({x=pos2.x,y=height-0.01,z=pos2.z}).is_ground_content then

-- 				local objs = minetest.get_objects_inside_radius(pos,abr*16+5)
-- 				local ccnt=0
-- 				for _,obj in ipairs(objs) do				-- count mobs in abrange
-- 					if not obj:is_player() then
-- 						local luaent = obj:get_luaentity()
-- 						if luaent and luaent.name:find('renowned_jam:') then
-- 							chance=chance + (1-chance)*spawn_reduction	-- chance reduced for every mob in range
-- 							if luaent.name == 'renowned_jam:soldier' then ccnt=ccnt+1 end
-- 						end
-- 					end
-- 				end

-- 				if chance < math.random() then

-- 					-- if no wolves and at least one deer spawn wolf, else deer
-- 					local mobname = "renowned_jam:soldier"

-- 					pos2.y = height+0.5
-- 					objs = minetest.get_objects_inside_radius(pos2,abr*16-2)
-- 					for _,obj in ipairs(objs) do				-- do not spawn if another player around
-- 						if obj:is_player() then return end
-- 					end

-- 					minetest.add_entity(pos2,mobname)			-- ok spawn it already damnit
-- 				end
-- 			end
-- 		end
-- 	end
-- end

local function soldier_actfunc(self, staticdata, dtime_s)
    mobkit.actfunc(self, staticdata, dtime_s)

    local props = {}
    props.textures = self.textures[self.texture_no or 1]
    self.object:set_properties(props)
end

minetest.register_entity("renowned_jam:soldier", {
    -- common props
    physical = true,
    stepheight = 0.6,
    collide_with_objects = true,
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
    visual = "mesh",
    mesh = "3d_armor_character.b3d",
    textures = {
        {
            "character.png",
            "3d_armor_trans.png^3d_armor_helmet_steel.png^3d_armor_chestplate_steel.png^" ..
                    "shields_shield_steel.png^3d_armor_leggings_steel.png^3d_armor_boots_steel.png",
            wieldview:get_item_texture("default:sword_steel")
        },
    },
    visual_size = {x = 1, y = 1},
    static_save = true,
    makes_footstep_sound = true,

    on_step = mobkit.stepfunc,
    on_activate = soldier_actfunc,
    get_staticdata = mobkit.statfunc,

    -- api props
    springiness=0,
    buoyancy = 0.75,					-- portion of hitbox submerged
    max_speed = 5,
    jump_height = 1.26,
    view_range = 24,
    lung_capacity = 10, 		-- seconds
    max_hp = 14,
    timeout=600,
    attack={ range=0.5, damage_groups={fleshy=7}},
    sounds = {
        attack='renowned_jam_man_fight',
        warn = 'renowned_jam_man_yell',
        mumble = 'renowned_jam_man_mumble',
    },
    animation = {
        stand={range={x=0,y=79},speed=30,loop=true},
        lay={range={x=162,y=166},speed=30,loop=true},
        walk={range={x=168,y=187},speed=30,loop=true},
        mine={range={x=189,y=198},speed=30,loop=true},
        walk_mine={range={x=200,y=219},speed=30,loop=true},
        sit={range={x=81,y=160},speed=30,loop=true},
    },

    brainfunc = soldier_brain,
    on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)

        if mobkit.is_alive(self) then
            local hvel = vector.multiply(vector.normalize({x=dir.x,y=0,z=dir.z}),4)
            self.object:set_velocity({x=hvel.x,y=2,z=hvel.z})

            mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)

    -- if type(puncher)=='userdata' and puncher:is_player() then	-- if hit by a player
    --     mobkit.clear_queue_high(self)							-- abandon whatever they've been doing
    --     mobkit.hq_hunt(self,10,puncher)							-- get revenge
    -- end

        end
    end,

    on_rightclick = function(self, clicker)
        print(dump(clicker:get_properties()))
    end,
})
