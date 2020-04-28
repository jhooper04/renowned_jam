

function renowned_jam.show_command_formspec(playername)

    -- local formspec = [[
    --     size[8,9]
    --     list[current_player;main;0,4.85;8,1;]
	-- 	list[current_player;main;0,6.08;8,3;8]
	-- 	listring[current_player;main]
    -- ]]..default.get_hotbar_bg(0,4.85)

    local formspec = [[
        size[8,9]
        tabheader[0,2;command_tab;Selection,Units,Structures,Specials;Units;true;true]
        label[0,0.0;Food: 10]
        label[0,0.2;Wood: 25]
        label[2,0.0;Stone: 150]
        label[2,0.2;Tin: 5]
        label[4,0.0;Copper: 35]
        label[4,0.2;Iron: 12]
        label[6,0;Gold: 100]
        image_button[0.5,2;1,1;renowned_jam_villager_item.png;build_villager;]
    ]]

    minetest.show_formspec(playername, "renowned_jam", formspec)
end
