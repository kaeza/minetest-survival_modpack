
local THIRST_TIME = survival.conf_getnum("thirst.start_time", 720);
local PASS_OUT_TIME = survival.conf_getnum("thirst.pass_out_time", 300);
local DTIME = survival.conf_getnum("thirst.check_interval", 0.5);

-- Boilerplate to support localized strings if intllib mod is installed.
local S;
if (minetest.get_modpath("intllib")) then
    dofile(minetest.get_modpath("intllib").."/intllib.lua");
    S = intllib.Getter(minetest.get_current_modname());
else
    S = function ( s ) return s; end
end

local timer = 0;

minetest.register_craftitem("survival_thirst:water_glass", {
    description = "Glass of Water";
    inventory_image = "survival_thirst_water_glass.png";
    groups = { drink=1; survival_no_override=1; };
    stack_max = 10;
    on_use = function ( itemstack, user, pointed_thing )
        local state = survival.get_player_state(user:get_player_name(), "thirst");
        state.count = 0;
        state.thirsty = false;
        minetest.sound_play({ name="survival_thirst_drink" }, {
            to_player = user:getpos();
            gain = 1.0;
        });
        local inv = user:get_inventory();
        local stack = ItemStack("vessels:drinking_glass");
        if (inv:room_for_item("main", stack)) then
            inv:add_item("main", stack);
        end
        itemstack:take_item(1);
        return itemstack;
    end;
});

local alt_water_sources = {
    ["3dforniture:sink"] = true;
    ["homedecor:kitchen_cabinet_with_sink"] = true;
};

minetest.register_on_punchnode(function ( pos, node, puncher )
    local item = puncher:get_wielded_item();
    if ((item:get_name() == "vessels:drinking_glass")
     and alt_water_sources[node.name]) then
        local newitem = ItemStack("survival_thirst:water_glass 1");
        local inv = puncher:get_inventory();
        if (inv:room_for_item("main", newitem)) then
            inv:remove_item("main", ItemStack(item:get_name().." 1"));
            inv:add_item("main", newitem);
        end
    end
end);

minetest.register_craft({
    output = "survival_thirst:water_glass";
    type = "shapeless";
    recipe = {
        "vessels:drinking_glass",
        "bucket:bucket_water",
    };
    replacements = {
        { "bucket:bucket_water", "bucket:bucket_empty" },
    };
});

-- Known drink items (more suggestions are welcome)
local known_drinks = {

    -- This very mod --
    --"survival_thirst:water_glass",

    -- rubenwardy's food --
    "food:apple_juice", "food:cactus_juice",

};

local function override_on_use ( def )
    local on_use = def.on_use;
    def.on_use = function ( itemstack, user, pointed_thing )
        local state = survival.get_player_state(user:get_player_name(), "thirst");
        minetest.sound_play({ name="survival_thirst_drink" }, {
            to_player = user:getpos();
            gain = 1.0;
        });
        if (on_use) then
            return on_use(itemstack, user, pointed_thing);
        else
            itemstack:take_item(1);
            return itemstack;
        end
    end
end

-- Try to override the on_use callback of as many food items as possible.
minetest.after(1, function ( )

    for _,name in ipairs(known_drinks) do
        local def = minetest.registered_items[name] or minetest.registered_nodes[name];
        if (def) then
            if ((not def.groups.survival_no_override) or (def.groups.survival_no_override == 0)) then
                override_on_use(def);
            end
        end
    end

    for name, def in pairs(minetest.registered_items) do
        if (def.groups and def.groups.drink and (def.groups.drink > 0)) then
            if ((not def.groups.survival_no_override) or (def.groups.survival_no_override == 0)) then
                override_on_use(def);
            end
        end
    end

end);

survival.register_state("thirst", {
    label = S("Thirst");
    item = {
        name = "survival_thirst:meter";
        description = S("Thirst Meter");
        inventory_image = "survival_thirst_meter.png";
        recipe = {
            { "", "default:wood", "" },
            { "default:wood", "vessels:drinking_glass", "default:wood" },
            { "", "default:wood", "" },
        };
    };
    get_default = function ( )
        return {
            count = 0;
            thirsty = false;
        };
    end;
    get_scaled_value = function ( state )
        if (state.thirsty) then
            return 0;
        else
            return 100 * (THIRST_TIME - state.count) / THIRST_TIME;
        end
    end;
    on_update = function ( dtime, player, state )
        if (player:get_hp() > 0) then
            state.count = state.count + dtime;
            local name = player:get_player_name();
            if (state.thirsty and (state.count >= PASS_OUT_TIME)) then
                state.count = 0;
                state.thirsty = false;
                if (player:get_hp() > 0) then
                    minetest.chat_send_player(name, S("You died from dehydration."));
                end
                player:set_hp(0);
                minetest.sound_play({ name="survival_thirst_pass_out" }, {
                    pos = player:getpos();
                    gain = 1.0;
                    max_hear_distance = 16;
                });
            elseif ((not state.thirsty) and (state.count >= THIRST_TIME)) then
                state.count = 0;
                state.thirsty = true;
                minetest.sound_play({ name="survival_thirst_thirst" }, {
                    pos = player:getpos();
                    gain = 1.0;
                    max_hear_distance = 16;
                });
                minetest.chat_send_player(name, S("You are thirsty."));
            end
        end
    end;
});
