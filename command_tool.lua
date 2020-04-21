local flag_obj = nil
local player_selections = {
    -- "jSnake" = {}
    -- "jSnake2" = {}
}

local function select_soldier(soldier, player)
    local pos = soldier:get_pos()
    local ent = soldier:get_luaentity()
    local player_name = player:get_player_name()
    local input = player:get_player_control()

    if ent._selected then
        if not input.aux1 then
            for _, sel_obj in ipairs(player_selections[player_name]) do
                local tsoldier = sel_obj:get_attach()
                if tsoldier then
                    local tent = tsoldier:get_luaentity()
                    tent._selected = false
                end
                sel_obj:remove()
            end
            player_selections[player_name] = {}
        else
            local toRemove = 1
            for index, sel_obj in ipairs(player_selections[player_name]) do
                if sel_obj == soldier then
                    local tsoldier = sel_obj:get_attach()
                    if tsoldier then
                        local tent = tsoldier:get_luaentity()
                        tent._selected = false
                    end
                    sel_obj:remove()
                    toRemove = index
                    break
                end
            end
            table.remove(player_selections[player_name], toRemove)
        end

    else
        if not input.aux1 then
            for _, sel_obj in ipairs(player_selections[player_name]) do
                local tsoldier = sel_obj:get_attach()
                if tsoldier then
                    local tent = tsoldier:get_luaentity()
                    tent._selected = false
                end
                sel_obj:remove()
            end
            player_selections[player_name] = {}
        end

        local selection_obj = minetest.add_entity(pos,"renowned_jam:command_select")
        selection_obj:set_attach(soldier, "Head", {x=0,y=6,z=0}, {x=0,y=0,z=0})
        ent._selected = true
        table.insert(player_selections[player_name], selection_obj)
    end
end

local function command_tool_on_use(itemstack, player, pointed_thing)

    local player_name = player:get_player_name()
    if player_selections[player_name] == nil then
        player_selections[player_name] = {}
    end

    if pointed_thing.type == "object" then

        local obj = pointed_thing.ref
        if obj:get_entity_name() == "renowned_jam:soldier" then
            select_soldier(obj, player)
        end
    elseif pointed_thing.type == "node" and #player_selections[player_name] > 0 then

        local pos = {
            x = pointed_thing.under.x, y = pointed_thing.under.y+0.5, z = pointed_thing.under.z
        }

        if flag_obj ~= nil then
            flag_obj:remove()
        end
        flag_obj = minetest.add_entity(pos,"renowned_jam:command_flag")

        renowned_jam.make_formation_to_pos(player_selections[player_name], pos)
    end
end

local function command_tool_on_place(itemstack, player, pointed_thing)
    local input = player:get_player_control()
    local player_name = player:get_player_name()

    if player_selections[player_name] == nil then
        player_selections[player_name] = {}
    end

    if input.aux1 then
        renowned_jam.show_command_formspec(player_name)
    else
        if pointed_thing.type == "node" then
            local pos = {
                x = pointed_thing.under.x, y = pointed_thing.under.y+0.5, z = pointed_thing.under.z
            }
            local soldier = minetest.add_entity(pos,"renowned_jam:soldier")
            local soldier_entity = soldier:get_luaentity()

            mobkit.remember(soldier_entity,"commander", player_name)
        end
    end
end

function renowned_jam.deselect_soldier(soldier, player_name)

    if player_selections[player_name] == nil then
        player_selections[player_name] = {}
    end

    local toRemove = -1
    for index, sel_obj in ipairs(player_selections[player_name]) do

        local tsoldier = sel_obj:get_attach()
        if tsoldier == soldier then
            local tent = tsoldier:get_luaentity()
            tent._selected = false
            sel_obj:remove()
            toRemove = index
            break
        end
    end
    if toRemove > 0 then
        table.remove(player_selections[player_name], toRemove)
    end
end

--minetest.register_globalstep(spawnstep)

minetest.register_entity("renowned_jam:command_flag", {
    physical = false,
    collide_with_objects = false,
    visual = "mesh",
    mesh = "renowned_jam_flag.b3d",
    textures = {
        "renowned_jam_command_arrow.png",
        "renowned_jam_command_flag_red.png",
        "default_wood.png"
    },
    visual_size = {x = 4, y = 4, z=4},
    pointable = false,
    static_save = false,
    view_range = 24,
    --timeout=600,
})

minetest.register_entity("renowned_jam:command_select", {
    physical = false,
    collide_with_objects = false,
    visual = "mesh",
    mesh = "renowned_jam_select_arrow.b3d",
    textures = {
        "renowned_jam_command_arrow.png",
    },
    visual_size = {x = 4, y = 4, z=4},
    pointable = false,
    static_save = false,
    view_range = 24,
    --timeout=600,
})

minetest.register_tool("renowned_jam:command_tool", {
	description = "1st Unit Command Tool",
    inventory_image = "renowned_jam_command_tool_red.png",
    stack_max = 1,
    range = 40,
    liquids_pointable = true,
    on_use = command_tool_on_use,
    on_place = command_tool_on_place
})
