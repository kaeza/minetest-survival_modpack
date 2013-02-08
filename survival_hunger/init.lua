
local START_HUNGER_TIME = survival.conf_getnum("hunger.damage_start_time", 720);
local HUNGER_TIME = survival.conf_getnum("hunger.damage_interval", 30);
local HUNGER_DAMAGE = survival.conf_getnum("hunger.damage", 4);
local DTIME = survival.conf_getnum("hunger.check_interval", 0.5);

-- Boilerplate to support localized strings if intllib mod is installed.
local S;
if (minetest.get_modpath("intllib")) then
    dofile(minetest.get_modpath("intllib").."/intllib.lua");
    S = intllib.Getter(minetest.get_current_modname());
else
    S = function ( s ) return s; end
end

local timer = 0;

local player_state = { };

if (minetest.setting_getbool("enable_damage") and survival.conf_getbool("hunger.enabled", true)) then
    minetest.register_globalstep(function ( dtime )
        timer = timer + dtime;
        if (timer < DTIME) then return; end
        timer = timer - DTIME;
        for i, v in ipairs(minetest.get_connected_players()) do
            local name = v:get_player_name();
            if (not player_state[name]) then
                player_state[name] = {
                    count = 0;
                    hungry = false;
                    next = START_HUNGER_TIME;
                };
            end
            local state = player_state[name];
            state.count = state.count + DTIME;
            if ((v:get_hp() > 0) and (state.count >= state.next)) then
                v:set_hp(v:get_hp() - HUNGER_DAMAGE);
                if (v:get_hp() <= 0) then
                    minetest.chat_send_player(name, S("You died from starvation."));
                end
                state.count = state.count - state.next;
                state.next = HUNGER_TIME;
                state.hungry = true;
                minetest.sound_play({ name="survival_hunger_stomach" }, {
                    pos = v:getpos();
                    gain = 1.0;
                    max_hear_distance = 16;
                });
            end
        end
    end);
end

survival.create_meter("survival_hunger:meter", {
    description = S("Hunger Meter");
    command = {
        name = "hunger";
        label = S("Hunger");
    };
    recipe = {
        { "", "default:wood", "" },
        { "default:wood", "default:apple", "default:wood" },
        { "", "default:wood", "" },
    };
    image = "survival_hunger_meter.png";
    get_value = function ( player )
        local name = player:get_player_name();
        if (player_state[name].hungry) then
            return 0;
        else
            return 100 * (START_HUNGER_TIME - player_state[name].count) / START_HUNGER_TIME;
        end
    end;
});

-- Known food items (more suggestions are welcome)
local known_foods = {

    -- Default game --
    "default:apple",

    -- PilzAdam's farming[_plus] --
    "farming:bread",
    "farming:pumpkin_bread",
    "farming_plus:orange_item",
    "farming_plus:tomato_item",
    "farming_plus:strawberry_item",
    "farming_plus:carrot_item",
    "farming_plus:banana",

    -- rubenwardy's food --
    "food:cheese", "food:chocolate_dark", "food:chocolate_milk",
    "food:coffee", "food:hotchoco", "food:ms_chocolate", "food:bread_slice",
    "food:bun", "food:sw_meat", "food:sw_cheese", "food:cake",
    "food:cake_chocolate", "food:cake_carrot", "food:crumble_rhubarb",
    "food:banana_split", "food:bread", "food:strawberry", "food:carrot",
    "food:banana", "food:meat_raw", "food:milk",
    -- These will be better for thirst
    --"food:apple_juice", "food:cactus_juice",

    -- GloopMaster's gloopores --
    -- "gloopores:kalite_lump", -- TODO: Should this be considered "food"?

    -- Sapier's animals_modpack (MOB Framework) --
    "animalmaterials:meat_pork", "animalmaterials:meat_beef",
    "animalmaterials:meat_chicken", "animalmaterials:meat_lamb",
    "animalmaterials:meat_venison", "animalmaterials:meat_toxic",
    "animalmaterials:meat_ostrich", "animalmaterials:meat_undead",
    "animalmaterials:fish_bluewhite", "animalmaterials:fish_clownfish",
    "animalmaterials:milk",

};

local function override_on_use ( def )
    local on_use = def.on_use;
    def.on_use = function ( itemstack, user, pointed_thing )
        player_state[user:get_player_name()] = {
            count = 0;
            next = START_HUNGER_TIME;
            hungry = false;
        };
        minetest.sound_play({ name="survival_hunger_eat" }, {
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

    for _,name in ipairs(known_foods) do
        local def = minetest.registered_items[name] or minetest.registered_nodes[name];
        if (def) then
            if ((not def.groups.survival_no_override) or (def.groups.survival_no_override == 0)) then
                override_on_use(def);
            end
        end
    end

    for name, def in pairs(minetest.registered_items) do
        if (def.groups and def.groups.food and (def.groups.food > 0)) then
            if ((not def.groups.survival_no_override) or (def.groups.survival_no_override == 0)) then
                override_on_use(def);
            end
        end
    end

end);

minetest.register_on_joinplayer(function ( player )
    player_state[player:get_player_name()] = {
        count = 0;
        hungry = false;
        next = START_HUNGER_TIME;
    };
end);

minetest.register_on_dieplayer(function ( player )
    local name = player:get_player_name();
    player_state[name] = {
        count = 0;
        hungry = false;
        next = START_HUNGER_TIME;
    };
end);
