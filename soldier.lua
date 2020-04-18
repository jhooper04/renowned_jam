
--local abr = minetest.get_mapgen_setting('active_block_range')

--local spawn_rate = 1 - 0.2
--local spawn_reduction = 0.75

local function soldier_brain(self)

	-- vitals should be checked every step
    if mobkit.timer(self,1) then
        renowned_jam.unit_lava_dmg(self,6)
    end

	mobkit.vitals(self)

	if self.hp <= 0 then
		mobkit.clear_queue_high(self)									-- cease all activity
        mobkit.hq_die(self)												-- kick the bucket
        local commander = mobkit.recall(self, "commander")
        if commander ~= nil then
            renowned_jam.deselect_soldier(self.object, commander)
        end
		return
	end

	if mobkit.timer(self,1) then 			-- decision making needn't happen every engine step
		local prty = mobkit.get_queue_priority(self)

		if prty < 20 and self.isinliquid then
			mobkit.hq_liquid_recovery(self,20)
			return
        end

        local pos=self.object:get_pos()
        local commander = mobkit.recall(self, "commander") or ""
        local enemy_soldier = renowned_jam.unit_get_nearby_enemy(self, commander)

        if enemy_soldier and vector.distance(pos,enemy_soldier:get_pos()) < 10 then
            renowned_jam.unit_hq_hunt(self, 10, enemy_soldier)
        else
            if prty > 9 then
                mobkit.clear_queue_high(self)
            end
            renowned_jam.make_formation_step(self, prty)
        end
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
    on_activate = renowned_jam.unit_actfunc,
    get_staticdata = mobkit.statfunc,

    -- api props
    springiness=0,
    buoyancy = 0.75,					-- portion of hitbox submerged
    max_speed = 5,
    jump_height = 1.26,
    view_range = 24,
    lung_capacity = 20, 		-- seconds
    max_hp = 20,
    timeout=600,
    attack={ range=4, damage_groups={fleshy=6}},
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
        --print(dump(clicker:get_properties()))
    end,
})
