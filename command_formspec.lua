

function renowned_jam.show_command_formspec(playername)

    -- local formspec = [[
    --     size[8,9]
    --     list[current_player;main;0,4.85;8,1;]
	-- 	list[current_player;main;0,6.08;8,3;8]
	-- 	listring[current_player;main]
    -- ]]..default.get_hotbar_bg(0,4.85)

    local formspec = [[
        size[8,9]
    ]]

    minetest.show_formspec(playername, "renowned_jam", formspec)
end
