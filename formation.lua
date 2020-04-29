
local function round_number(num)
    if math.modf(num) > 0.5 then
        return math.ceil(num)
    end
    return math.floor(num)
end

local function round_pos(pos)
    return {x=round_number(pos.x), y=round_number(pos.y), z=round_number(pos.z)}
end

local function pos_to_string(pos)
    return "{ x="..pos.x..", y="..pos.y..", z="..pos.z.." }"
end

function renowned_jam.make_formation_to_pos(selections, target_pos)

    local formation = {
        leader = nil,
        start_pos = {x=0, y=0, z=0},
        target_pos = round_pos(target_pos),
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

    formation.start_pos = round_pos(vector.divide(unit_pos_sum, unit_count))

    local path_data = minetest.find_path(formation.start_pos, formation.target_pos, 24, 1, 4, "A*")
    if path_data == nil or #path_data < 2 then
        path_data = {formation.start_pos, formation.target_pos}
    end

    formation.leader = minetest.add_entity(formation.start_pos, "renowned_jam:command_lead")
    local leader_ent = formation.leader:get_luaentity()
    leader_ent._start_pos = formation.start_pos
    leader_ent._target_pos = formation.target_pos
    leader_ent._units = formation.units
    leader_ent._path_data = path_data
    leader_ent._next_idx = 2

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

--function renowned_jam.get_rotated_offset(

function renowned_jam.get_target_pos(self)
    local pos
    local rot

    if self._leading_obj == nil then
        return self._target_pos or self.object:get_pos()
    end

    pos = self._leading_obj:get_pos()
    if pos == nil then
        return self._target_pos or self.object:get_pos()
    end

    rot = self._leading_obj:get_rotation()
    if rot == nil then
        return self._target_pos or self.object:get_pos()
    end

    --mobkit.clear_queue_high(self)

    local offset = self._offset
    local rot_offset = {
        x=offset.x*math.cos(-rot.y) + offset.z*math.sin(-rot.y),
        y=offset.y,
        z=-offset.x*math.sin(-rot.y) + offset.z*math.cos(-rot.y)
    }
    return vector.add(pos, rot_offset)
end

function renowned_jam.make_formation_step(self, priority)

    -- local pos
    -- local rot

    -- if self._leading_obj == nil then
    --     return
    -- end

    -- pos = self._leading_obj:get_pos()
    -- if pos == nil then
    --     return
    -- end

    -- rot = self._leading_obj:get_rotation()
    -- if rot == nil then
    --     return
    -- end

    -- --mobkit.clear_queue_high(self)

    -- local offset = self._offset
    -- local rot_offset = {
    --     x=offset.x*math.cos(-rot.y) + offset.z*math.sin(-rot.y),
    --     y=offset.y,
    --     z=-offset.x*math.sin(-rot.y) + offset.z*math.cos(-rot.y)
    -- }
    -- local dest = vector.add(pos, rot_offset)


end

local function leader_activate(self, static_data, dtime)
    self.time_total = 0
end

local function leader_step(self, dtime)
    self.dtime = dtime
    if mobkit.timer(self, 1) then

        local waypoint = self._path_data[self._next_idx]

        if not waypoint then
            --local leader_pos = self.object:get_pos()
            for _,unit in ipairs(self._units) do
                local ent = unit:get_luaentity()
                if ent then
                    ent._target_pos = renowned_jam.get_target_pos(ent)
                end
            end
            self.object:remove()
            return
        end

        local pos = self.object:get_pos()

        if vector.distance(pos, waypoint) < 2 then
            self._next_idx = self._next_idx+1
            leader_step(self, dtime)
            return
        end

        local diff = vector.subtract(waypoint, pos)
        local dir = vector.normalize(diff)
        local step = vector.multiply(dir, 2)

        self.object:set_velocity(step)
        self.object:set_yaw(minetest.dir_to_yaw(dir))
        local target = vector.add(pos, vector.multiply(step, dtime))
        self.object:move_to(target, true)
    end
    self.time_total = self.time_total + dtime
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
    on_activate = leader_activate,
    on_step = leader_step,
})
