
local function hq_moveto(self,priority,target_pos)
	local func = function(theself)
		if mobkit.is_queue_empty_low(theself) and theself.isonground then
			local pos = mobkit.get_stand_pos(theself)
			if vector.distance(pos,target_pos) > 1 then
				mobkit.goto_next_waypoint(theself,target_pos)
			else
				mobkit.lq_idle(theself,1)
			end
		end
	end
	mobkit.queue_high(self,func,priority)
end

function renowned_jam.make_formation_to_pos(selections, targetPos)
    --local formation = { targetPos = targetPos, units = {} }
    local leader = nil
    for sel_idx, sel_obj in ipairs(selections) do
        if sel_obj ~= nil and sel_obj:get_attach() ~= nil then
            local parent = sel_obj:get_attach()
            local parent_entity = parent:get_luaentity()

            if sel_idx > 1 then
                parent_entity._leading_obj = leader
            else
                leader = parent
            end

            parent_entity._is_leader = (sel_idx == 1)
            parent_entity._targetPos = targetPos
            parent_entity._offset = {x=0, y=0, z=sel_idx}
            mobkit.clear_queue_high(parent_entity)
        end
    end
end

function renowned_jam.make_formation_step(self, priority)
    if self._is_leader then
        if priority < 9 and self._targetPos ~= nil then
            hq_moveto(self, 9, self._targetPos)
        end
    else
        if self._leading_obj ~= nil then
            mobkit.clear_queue_high(self)
            --print(dump(self._leading_obj:get_pos()))
            hq_moveto(self, 9, vector.add(self._leading_obj:get_pos(), self._offset))
        else
            if priority < 9 and self._targetPos ~= nil then
                hq_moveto(self, 9, self._targetPos)
            end
        end
    end
end
