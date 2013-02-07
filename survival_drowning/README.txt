
Drowning Mod for Minetest
This mod is part of the Survival Modpack for Minetest.
Copyright (C) 2013 Diego Martínez <lkaezadl3@gmail.com>
Inspired by the existing drowning mod [TODO: who's the author?]

See the file `../LICENSE.txt' for information about distribution.

TECHNICAL NOTES
---------------
To detect if the player is under water (to restore the oxygen timer), this
mod has to know about all the nodes considered "liquid". It currently handles
water_{source|flowing}, lava_{source|flowing}, and oil_{source|flowing} from
the Oil Mod.

The original drowning mod checked whether or not there was an air node at the
player's head, but this was inaccurate as you could "drown" by standing
"inside" a torch node, or other walkable nodes.
