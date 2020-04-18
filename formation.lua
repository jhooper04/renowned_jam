

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

        mobkit.clear_queue_high(unit_entity)
    end
end

function renowned_jam.make_formation_step(self, priority)

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
        renowned_jam.unit_hq_moveto(self, 9, vector.add(pos, rot_offset))
    end
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

        self.dtime = dtime
        if mobkit.timer(self, 1) then

            local pos = self.object:get_pos()
            if mobkit.isnear3d(pos, self._target_pos, 4) then

                self.object:remove()
            end
        end
        self.time_total = self.time_total + dtime
    end
})
