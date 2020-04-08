renowned_jam = {}

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
--local worldpath = minetest.get_worldpath()

local to_remove = {}
for name, _ in pairs(minetest.registered_biomes) do
    if name:find("grassland") then
        print(name)
    else
        table.insert(to_remove, name)
    end
end
for _, name in ipairs(to_remove) do
    minetest.unregister_biome(name)
end

dofile(modpath.."/player.lua")
dofile(modpath.."/structure.lua")
dofile(modpath.."/soldier.lua")
dofile(modpath.."/formation.lua")
dofile(modpath.."/command_formspec.lua")
dofile(modpath.."/command_tool.lua")
dofile(modpath.."/match.lua")
