function renowned_jam.unit_get_nearby_enemy(self, commander) -- returns random player if nearby or nil
    for _, obj in ipairs(self.nearby_objects) do
        if mobkit.is_alive(obj) then
            if obj:is_player() and obj:get_player_name() ~= commander then
                return obj
            end
            if not obj:is_player() and mobkit.recall(obj:get_luaentity(), "commander") ~= commander then
                return obj
            end
        end
    end
    return
end

local node_lava = nil
function renowned_jam.unit_lava_dmg(self, dmg)
    node_lava = node_lava or minetest.registered_nodes[minetest.registered_aliases.mapgen_lava_source]
    if node_lava then
        local pos = self.object:get_pos()
        local box = self.object:get_properties().collisionbox
        local pos1 = {x = pos.x + box[1], y = pos.y + box[2], z = pos.z + box[3]}
        local pos2 = {x = pos.x + box[4], y = pos.y + box[5], z = pos.z + box[6]}
        local nodes = mobkit.get_nodes_in_area(pos1, pos2)
        if nodes[node_lava] then
            mobkit.hurt(self, dmg)
        end
    end
end

function renowned_jam.unit_actfunc(self, staticdata, dtime_s)
    mobkit.actfunc(self, staticdata, dtime_s)

    local props = {}
    props.textures = self.textures[self.texture_no or 1]
    self.object:set_properties(props)
end

function renowned_jam.unit_hq_moveto(self, priority, target_pos)
    local func = function(theself)
        if mobkit.is_queue_empty_low(theself) and theself.isonground then
            local pos = mobkit.get_stand_pos(theself)
            if vector.distance(pos, target_pos) > 0.6 then
                mobkit.goto_next_waypoint(theself, target_pos)
            else
                mobkit.lq_idle(theself, 1)
            end
        end
    end
    mobkit.queue_high(self, func, priority)
end

function renowned_jam.unit_lq_jumpattack(self, height, target)
    local phase = 1
    --local timer=0.5
    local tgtbox = target:get_properties().collisionbox
    local func = function(theself)
        if not mobkit.is_alive(target) then
            return true
        end
        if theself.isonground then
            if phase == 1 then -- collision bug workaround
                local vel = theself.object:get_velocity()
                vel.y = -mobkit.gravity * math.sqrt(height * 2 / -mobkit.gravity)
                theself.object:set_velocity(vel)
                mobkit.make_sound(theself, "charge")
                phase = 2
            else
                mobkit.lq_idle(theself, 0.3)
                return true
            end
        elseif phase == 2 then
            local dir = minetest.yaw_to_dir(theself.object:get_yaw())
            local vy = theself.object:get_velocity().y
            dir = vector.multiply(dir, 6)
            dir.y = vy
            theself.object:set_velocity(dir)
            phase = 3
        elseif phase == 3 then -- in air
            local tgtpos = target:get_pos()
            local pos = theself.object:get_pos()
            -- calculate attack spot
            local yaw = theself.object:get_yaw()
            local dir = minetest.yaw_to_dir(yaw)
            local apos = mobkit.pos_translate2d(pos, yaw, theself.attack.range)

            if mobkit.is_pos_in_box(apos, tgtpos, tgtbox) then --bite
                target:punch(theself.object, 1, theself.attack)
                -- bounce off
                local vy = theself.object:get_velocity().y
                theself.object:set_velocity({x = dir.x * -3, y = vy, z = dir.z * -3})
                -- play attack sound if defined
                mobkit.make_sound(theself, "attack")
                mobkit.animate(theself, "walk_mine")
                phase = 4
            end
        end
    end
    mobkit.queue_low(self, func)
end

function renowned_jam.unit_lq_fallover(self)
    local zrot = 0
    local init = true
    local func = function(theself)
        if init then
            local vel = theself.object:get_velocity()
            theself.object:set_velocity(mobkit.pos_shift(vel, {y = 1}))
            mobkit.animate(theself, "stand")
            init = false
        end
        zrot = zrot + math.pi * 0.05
        local rot = theself.object:get_rotation()
        theself.object:set_rotation({x = rot.x, y = rot.y, z = zrot})
        if zrot >= math.pi * 0.5 then
            return true
        end
    end
    mobkit.queue_low(self, func)
end

function renowned_jam.unit_hq_attack(self, prty, tgtobj)
    local func = function(theself)
        if not mobkit.is_alive(tgtobj) then
            return true
        end
        if mobkit.is_queue_empty_low(theself) then
            local pos = mobkit.get_stand_pos(theself)
            --			local tpos = tgtobj:get_pos()
            local tpos = mobkit.get_stand_pos(tgtobj)
            local dist = vector.distance(pos, tpos)
            if dist > 3 then
                return true
            else
                mobkit.lq_turn2pos(theself, tpos)
                local height = tgtobj:is_player() and 0.35 or tgtobj:get_luaentity().height * 0.6
                if tpos.y + height > pos.y then
                    renowned_jam.unit_lq_jumpattack(theself, tpos.y + height - pos.y, tgtobj)
                else
                    mobkit.lq_dumbwalk(
                        theself,
                        mobkit.pos_shift(tpos, {x = math.random() - 0.5, z = math.random() - 0.5})
                    )
                end
            end
        end
    end
    mobkit.queue_high(self, func, prty)
end

function renowned_jam.unit_hq_hunt(self, prty, tgtobj)
    local func = function(theself)
        if not mobkit.is_alive(tgtobj) then
            return true
        end
        if mobkit.is_queue_empty_low(theself) and theself.isonground then
            local pos = mobkit.get_stand_pos(theself)
            local opos = tgtobj:get_pos()
            local dist = vector.distance(pos, opos)
            if dist > theself.view_range then
                return true
            elseif dist > 3 then
                mobkit.goto_next_waypoint(theself, opos)
            else
                renowned_jam.unit_hq_attack(theself, prty + 1, tgtobj)
            end
        end
    end
    mobkit.queue_high(self, func, prty)
end

function renowned_jam.unit_hq_die(self)
    local timer = 5
    local start = true
    local func = function(theself)
        if start then
            renowned_jam.unit_lq_fallover(theself)
            theself.logic = function(theself2)
            end -- brain dead as well
            start = false
        end
        timer = timer - theself.dtime
        if timer < 0 then
            theself.object:remove()
        end
    end
    mobkit.queue_high(self, func, 100)
end
