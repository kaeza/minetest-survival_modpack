
drowning = { };

local player_state = { };

local START_DROWNING_TIME = survival.conf_getnum("drowning.damage_start_time", 20);
local DROWNING_TIME = survival.conf_getnum("drowning.damage_interval", 2);
local DROWNING_DAMAGE = survival.conf_getnum("drowning.damage", 1);
local DTIME = survival.conf_getnum("drowning.check_interval", 0.5);

local timer = 0;

local liquids = { };

-- Boilerplate to support localized strings if intllib mod is installed.
local S;
if (minetest.get_modpath("intllib")) then
    dofile(minetest.get_modpath("intllib").."/intllib.lua");
    S = intllib.Getter(minetest.get_current_modname());
else
    S = function ( s ) return s; end
end

minetest.register_entity("survival_drowning:bubbles", {
    physical = false;
    timer = 0;
    textures = { "survival_drowning_bubbles.png" };
    collisionbox = { 0, 0, 0, 0, 0, 0 };
    on_step = function ( self, dtime )
        self.timer = self.timer + dtime;
        if (self.timer > 0.5) then
            self.timer = self.timer - 0.5;
            local pos = self.object:getpos();
            pos.y = pos.y + 1;
            if (not liquids[minetest.env:get_node(pos).name]) then
                self.object:remove();
            end
        end
    end;
});

if (minetest.setting_getbool("enable_damage") and survival.conf_getbool("drowning.enabled", true)) then
    print("survival_drowning: Drowning is enabled!");
    minetest.register_globalstep(function ( dtime )
        timer = timer + dtime;
        if (timer < DTIME) then
            return;
        end
        timer = timer - DTIME;
        for k, v in pairs(minetest.get_connected_players()) do
            name = v:get_player_name();
            if (not player_state[name]) then
                player_state[name] = { count=0, drowning=false };
            end
            local puw = player_state[name];
            local pos = v:getpos()
            pos.y = pos.y + 1;
            if (is_player_under_liquid(v)) then
                state.count = state.count + 0.5;
                if (math.random(1, 100) < 20) then
                    if (not liquids[minetest.env:get_node({ x=pos.x; y=pos.y+8; z=pos.z}).name]) then
                        local bub = minetest.env:add_entity(pos, "survival_drowning:bubbles");
                        bub:setvelocity({ x=0; y=1; z=0 });
                    end
                end
                if ((not state.drowning) and (state.count >= START_DROWNING_TIME)) then
                    v:set_hp(v:get_hp() - DROWNING_DAMAGE);
                    minetest.sound_play({ name="drowning_gurp"; }, { pos = pos; gain = 1.0; max_hear_distance = 16; });
                    state.drowning = true;
                    state.count = state.count - START_DROWNING_TIME;
                    minetest.chat_send_player(name, S("You are out of oxygen."));
                elseif (state.drowning and (state.count >= DROWNING_TIME)) then
                    v:set_hp(v:get_hp() - DROWNING_DAMAGE);
                    minetest.sound_play({ name="drowning_gurp"; }, { pos = pos; gain = 1.0; max_hear_distance = 16; });
                    state.count = state.count - DROWNING_TIME;
                    if (v:get_hp() <= 0) then
                        minetest.chat_send_player(name, S("You drowned."));
                    end
                end
            else
                if (state.count > 0) then
                    pos = v:getpos();
                    pos.y = pos.y + 1;
                    minetest.sound_play({ name="drowning_gasp" }, { pos = pos; gain = 1.0; max_hear_distance = 32; });
                end
                state.count = 0;
                state.drowning = false;
            end
        end
    end)
end

function is_player_under_liquid(player)
	local pos = player:getpos()
	pos.y = pos.y + 1.5;

	return (liquids[minetest.env:get_node(pos).name]);
end

survival.drowning = { };

survival.drowning.register_liquid = function ( name )
    liquids[name] = true;
end

survival.drowning.is_liquid = function ( name )
    return liquids[name];
end

survival.drowning.is_liquid_at_pos = function ( pos )
    local name = minetest.env:get_node(pos).name;
    return liquids[name];
end

survival.drowning.register_liquid("default:water_source");
survival.drowning.register_liquid("default:water_flowing");
survival.drowning.register_liquid("default:lava_source");
survival.drowning.register_liquid("default:lava_flowing");
survival.drowning.register_liquid("oil:oil_source");
survival.drowning.register_liquid("oil:oil_flowing");

survival.create_meter("survival_drowning:meter", {
    description = S("Oxygen Meter");
    command = {
        name = "o2";
        label = S("Oxygen");
    };
    recipe = {
        { "", "default:wood", "" },
        { "default:wood", "default:glass", "default:wood" },
        { "", "default:wood", "" },
    };
    image = "survival_drowning_meter.png";
    not_in_plstats = true;
    get_value = function ( player )
        local name = player:get_player_name();
        if (player_state[name].drowning) then
            return 0.01;
        else
            return 100 * (START_DROWNING_TIME - player_state[name].count) / START_DROWNING_TIME;
        end
    end;
});

minetest.register_on_joinplayer(function ( player )
    player_state[player:get_player_name()] = {
        count = 0;
        drowning = false;
    };
end);
