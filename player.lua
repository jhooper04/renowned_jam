
local lobby_players = {}
local lobby_spawn = {x=0, y=0, z=0}

local function on_player_new(player)

end

local function on_player_join(player)
    local player_name = player:get_player_name()
    lobby_players[player_name] = true
end

local function on_player_leave(player, timed_out)
    local player_name = player:get_player_name()
    lobby_players[player_name] = nil
end

local function on_player_die(player, reason)

end

local function on_player_respawn(player)

end

minetest.register_on_newplayer(on_player_new)
minetest.register_on_joinplayer(on_player_join)
minetest.register_on_leaveplayer(on_player_leave)

minetest.register_on_dieplayer(on_player_die)
minetest.register_on_respawnplayer(on_player_respawn)
