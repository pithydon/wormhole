local wormholes = {}

local on_hold = {}

local remove_name = function(name)
	for i,v in ipairs(on_hold) do
		if v == name then
			table.remove(on_hold, i)
		end
	end
end

minetest.register_privilege("wormhole", {description = "Allows you to manage wormholes.", give_to_singleplayer = false})

minetest.register_node("wormhole:wormhole", {
	description = "Wormhole",
	paramtype = "light",
	light_source = 10,
	walkable = false,
	inventory_image = "wormhole_placer.png",
	wield_image = "wormhole_placer.png",
	tiles = {"wormhole_top.png", "wormhole_bottom.png", "wormhole_side.png"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -1, -0.5, 0.5, 1, 0.5},
			{-1, -0.5, -0.5, -0.5, 0.5, 0.5},
			{0.5, -0.5, -0.5, 1, 0.5, 0.5},
			{-0.5, -0.5, -1, 0.5, 0.5, -0.5},
			{-0.5, -0.5, 0.5, 0.5, 0.5, 1}
		},
	},
	groups = {dig_immediate = 2},
	on_place = function(itemstack, placer, pointed_thing)
		if minetest.check_player_privs(placer, "wormhole") then
			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		else
			return itemstack
		end
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		table.insert(wormholes, pos)
	end,
	can_dig = function(pos, player)
		if minetest.check_player_privs(player, "wormhole") then
			return true
		else
			return false
		end
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local name = clicker:get_player_name()
		if minetest.check_player_privs(name, "wormhole") then
			local pos_string = minetest.pos_to_string(pos)
			local meta = minetest.get_meta(pos)
			local to_pos = meta:get_string("to_pos")
			minetest.show_formspec(name, "wormhole:"..pos_string, "field[text;Enter coords;"..to_pos.."]")
		end
	end,
	after_destruct = function(pos, oldnode)
		local pos_string = minetest.pos_to_string(pos)
		for i,v in ipairs(wormholes) do
			local v_string = minetest.pos_to_string(v)
			if pos_string == v_string then
				table.remove(wormholes, i)
			end
		end
	end,
	on_blast = function(pos, intensity)
	end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname:split(":")[1] == "wormhole" then
		if minetest.string_to_pos(fields.text) then
			local pos = minetest.string_to_pos(formname:split(":")[2])
			local meta = minetest.get_meta(pos)
			meta:set_string("to_pos", fields.text)
		end
		return true
	else
		return false
	end
end)

minetest.register_globalstep(function(dtime)
	for _,pos in ipairs(wormholes) do
		local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y - 0.5, z = pos.z}, 1.4)
		for _,v in ipairs(objs) do
			if v:is_player() then
				local name = v:get_player_name()
				for _,v in ipairs(on_hold) do
					if v == name then
						return
					end
				end
				local meta = minetest.get_meta(pos)
				local to_pos_string = meta:get_string("to_pos")
				local to_pos = minetest.string_to_pos(to_pos_string)
				if to_pos then
					table.insert(on_hold, name)
					v:setpos(to_pos)
					minetest.after(1.5, remove_name, name)
				end
			end
		end
	end
end)

minetest.register_lbm({
	name = "wormhole:index_wormholes",
	nodenames = {"wormhole:wormhole"},
	run_at_every_load = true,
	action = function(pos)
		table.insert(wormholes, pos)
	end
})
