



local function hq_moveto(self,priority,target_pos)
	local func = function(theself)
		if mobkit.is_queue_empty_low(theself) and theself.isonground then
			local pos = mobkit.get_stand_pos(theself)
			if vector.distance(pos,target_pos) > 0.6 then
				mobkit.goto_next_waypoint(theself,target_pos)
			else
				mobkit.lq_idle(theself,1)
			end
		end
	end
	mobkit.queue_high(self,func,priority)
end

function renowned_jam.make_formation_to_pos(selections, target_pos)

    local formation = {
        leader = nil,
        start_pos = {x=0, y=0, z=0},
        target_pos = target_pos,
        units = {}
    }
    local unit_pos_sum = {x=0, y=0, z=0}
    local unit_count = 0

    for _, sel_obj in ipairs(selections) do
        if sel_obj ~= nil and sel_obj:get_attach() ~= nil then

            local unit = sel_obj:get_attach()
            local unit_pos = unit:get_pos()

            unit_pos_sum = vector.add(unit_pos_sum, unit_pos)
            unit_count = unit_count + 1

            table.insert(formation.units, unit)
        end
    end

    formation.start_pos = vector.divide(unit_pos_sum, unit_count)

    formation.leader = minetest.add_entity(formation.start_pos, "renowned_jam:command_lead")
    local leader_ent = formation.leader:get_luaentity()
    leader_ent._start_pos = formation.start_pos
    leader_ent._target_pos = formation.target_pos

    local dir = vector.direction(formation.start_pos, formation.target_pos)
    formation.leader:set_yaw(minetest.dir_to_yaw(dir))
    formation.leader:set_velocity(vector.multiply(dir, 4))
    --formation.leader:set_rotation({x=0, y=vector.angle(formation.start_pos, formation.target_pos), z=0})
    --formation.leader:move_to(formation.target_pos, false)

    if formation.leader == nil then
        minetest.log("error", "failed to create command_lead obj for selection")
        return
    end

    for unit_idx, unit_obj in ipairs(formation.units) do
        local unit_entity = unit_obj:get_luaentity()

        unit_entity._leading_obj = formation.leader
        unit_entity._target_pos = formation.target_pos
        unit_entity._start_pos = formation.start_pos
        unit_entity._offset = {x=unit_idx-(math.floor(#formation.units*0.5)), y=0, z=0}
        --if unit_idx >= math.floor(#selections*0.5)+2 then
        --    unit_entity._offset.x = unit_entity._offset.x+1
        --end
        mobkit.clear_queue_high(unit_entity)
    end

    -- for sel_idx, sel_obj in ipairs(selections) do
    --     if sel_obj ~= nil and sel_obj:get_attach() ~= nil then
    --         local soldier = sel_obj:get_attach()
    --         local soldier_entity = soldier:get_luaentity()

    --         if sel_idx > 1 then
    --             soldier_entity._leading_obj = leader
    --         else
    --             leader = soldier
    --         end

    --         soldier_entity._is_leader = (sel_idx == 1)
    --         soldier_entity._targetPos = targetPos
    --         soldier_entity._offset = {x=sel_idx-(math.floor(#selections*0.5)+2), y=0, z=0}
    --         if sel_idx >= math.floor(#selections*0.5)+2 then
    --             soldier_entity._offset.x = soldier_entity._offset.x+1
    --         end
    --         mobkit.clear_queue_high(soldier_entity)
    --     end
    -- end
end

function renowned_jam.make_formation_step(self, priority)
    -- if self._is_leader then
    --     if priority < 9 and self._target_pos ~= nil then
    --         hq_moveto(self, 9, self._target_pos)
    --     end
    -- else
    if self._leading_obj ~= nil and self._leading_obj:get_pos() ~= nil then
        mobkit.clear_queue_high(self)
        local pos = self._leading_obj:get_pos()
        local rot = self._leading_obj:get_rotation()
        local offset = self._offset
        local rot_offset = {
            x=offset.x*math.cos(-rot.y) + offset.z*math.sin(-rot.y),
            y=offset.y,
            z=-offset.x*math.sin(-rot.y) + offset.z*math.cos(-rot.y)
        }
        hq_moveto(self, 9, vector.add(pos, rot_offset))
    end
    -- end
end

minetest.register_entity("renowned_jam:command_lead", {
    physical = false,
    collide_with_objects = false,
    visual = "mesh",
    mesh = "renowned_jam_select_arrow.b3d",
    textures = {
        "renowned_jam_command_arrow.png",
    },
    visual_size = {x = 0.01, y = 0.01, z=0.01},
    pointable = false,
    static_save = false,
    view_range = 24,
    on_activate = function(self, static_data, dtime)
        self.time_total = 0
    end,
    on_step = function(self, dtime)
        self.dtime = dtime --math.min(dtime,0.2)
        if mobkit.timer(self, 1) then
            local pos = self.object:get_pos()
            --local dir = self.object:get_velocity()
            --if mobkit.is_there_yet2d(pos, dir, self._target_pos) then
            print("here")
            if mobkit.isnear3d(pos, self._target_pos, 4) then
                print("here 2")
                --self.object:set_velocity({x=0,y=0,z=0})
                self.object:remove()
            end
        end
        self.time_total = self.time_total + dtime
    end
})
