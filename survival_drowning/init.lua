
local START_DROWNING_TIME = survival.conf_getnum("drowning.damage_start_time", 20);
local DROWNING_TIME = survival.conf_getnum("drowning.damage_interval", 2);
local DROWNING_DAMAGE = survival.conf_getnum("drowning.damage", 1);
local DTIME = survival.conf_getnum("drowning.check_interval", 0.5);

-- Boilerplate to support localized strings if intllib mod is installed.
local S;
if (minetest.get_modpath("intllib")) then
    dofile(minetest.get_modpath("intllib").."/intllib.lua");
    S = intllib.Getter(minetest.get_current_modname());
else
    S = function ( s ) return s; end
end

local liquids = { };

local player_state = { };

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

survival.drowning.is_player_under_liquid = function ( player )
	local pos = player:getpos()
	pos.y = pos.y + 1.5;
	return (liquids[minetest.env:get_node(pos).name]);
end

survival.drowning.register_liquid("default:water_source");
survival.drowning.register_liquid("default:water_flowing");
survival.drowning.register_liquid("default:lava_source");
survival.drowning.register_liquid("default:lava_flowing");
survival.drowning.register_liquid("oil:oil_source");
survival.drowning.register_liquid("oil:oil_flowing");
survival.drowning.register_liquid("survival_hazards:toxic_waste_source");
survival.drowning.register_liquid("survival_hazards:toxic_waste_flowing");

survival.register_state("oxygen", {
    label = S("Oxygen");
    not_in_plstats = true;
    item = {
        name = "survival_drowning:meter";
        description = S("Oxygen Meter");
        inventory_image = "survival_drowning_meter.png";
        recipe = {
            { "", "default:wood", "" },
            { "default:wood", "default:glass", "default:wood" },
            { "", "default:wood", "" },
        };
    };
    hud = {
        pos = {x=0.525, y=0.903};
        icon = "survival_drowning_hud.png";
    };
    get_default = function ( )
        return {
            count = 0;
            flag = false;
        };
    end;
    get_scaled_value = function ( state )
        if (state.flag) then
            return 0;
        else
            return 100 * (START_DROWNING_TIME - state.count) / START_DROWNING_TIME;
        end
    end;
    on_update = function ( dtime, player, state )
        local pos = player:getpos();
        pos.y = pos.y + 1;
        if (survival.drowning.is_player_under_liquid(player)) then
            state.count = state.count + dtime;
            if (math.random(1, 100) < 20) then
                if (not liquids[minetest.env:get_node({ x=pos.x; y=pos.y+8; z=pos.z}).name]) then
                    local bub = minetest.env:add_entity(pos, "survival_drowning:bubbles");
                    bub:setvelocity({ x=0; y=1; z=0 });
                end
            end
            if ((not state.flag) and (state.count >= START_DROWNING_TIME)) then
                player:set_hp(player:get_hp() - DROWNING_DAMAGE);
                minetest.sound_play({ name="drowning_gurp"; }, { pos = pos; gain = 1.0; max_hear_distance = 16; });
                state.flag = true;
                state.count = 0;
                minetest.chat_send_player(player:get_player_name(), S("You are out of oxygen."));
            elseif (state.flag and (state.count >= DROWNING_TIME)) then
                player:set_hp(player:get_hp() - DROWNING_DAMAGE);
                minetest.sound_play({ name="drowning_gurp"; }, { pos = pos; gain = 1.0; max_hear_distance = 16; });
                state.count = 0;
                if (player:get_hp() <= 0) then
                    minetest.chat_send_player(name, S("You drowned."));
                end
            end
        else
            if (state.count > 0) then
                minetest.sound_play({ name="drowning_gasp" }, { pos = pos; gain = 1.0; max_hear_distance = 32; });
            end
            state.count = 0;
            state.flag = false;
        end
    end;
});
