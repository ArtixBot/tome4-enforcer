-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2018 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

local Particles = require "engine.Particles"
getBirthDescriptor("class", "Tinker").descriptor_choices.subclass['Enforcer'] = "allow"

newBirthDescriptor{
	type = "subclass",
	name = "Enforcer",
	desc = {
		"Enforcers master the steamgun and shield to keep the peace.",
		"They sacrifice raw burst power and mobility for excellent survivability and crowd control.",
		"Their most important stats are: Strength and Dexterity.",
		"#GOLD#Stat modifiers:",
		"#LIGHT_BLUE# * +4 Strength, +4 Dexterity, +0 Constitution",
		"#LIGHT_BLUE# * +0 Magic, +0 Willpower, +1 Cunning",
		"#GOLD#Life per level:#LIGHT_BLUE# 4",
	},
	locked = function(birther) return birther:isDescriptorSet("world", "Orcs") or profile.mod.allow_build.orcs_tinker_eyal end,
	locked_desc = "Law and order will be enforced with shield and steamgun!",
	power_source = {steam=true, stamina=true},
	stats = { str=4, dex=3, con=2, },
	talents_types = {
		-- Class skills.
		["steamtech/gunner-training"]={true, 0.3},
		["steamtech/shield-augments"]={true, 0.3},
		["steamtech/missile-fire"]={true, 0.3},
		["steamtech/reinforcement"]={false, 0.3},
		["technique/steamshield"]={true, 0.3},
		["steamtech/reinforcement"]={true, 0.3},
		
		-- Generic skills.
		["technique/combat-training"]={true, 0.3},
		["technique/conditioning"]={true, 0.3},
		["steamtech/blacksmith"]={true, 0.2},
	},
	talents = {
		[ActorTalents.T_SHOOT] = 1,
		[ActorTalents.T_ARMOUR_TRAINING] = 2,
		[ActorTalents.T_WEAPON_COMBAT] = 1,
		[ActorTalents.T_STEAMGUN_MASTERY] = 1,
		[ActorTalents.T_PROTECT_AND_SERVE] = 1,
	},
	copy = {
		resolvers.equip{ id=true,
			{type="weapon", subtype="steamgun", name="iron steamgun", base_list="mod.class.Object:/data-orcs/general/objects/steamgun.lua", autoreq=true, ego_chance=-1000},
			{type="armor", subtype="shield", name="iron shield", autoreq=true, ego_chance=-1000, ego_chance=-1000},
			{type="ammo", subtype="shot", name="pouch of iron shots", autoreq=true, ego_chance=-1000},
			{type="armor", subtype="head", name="rough leather hat", autoreq=true, ego_chance=-1000, ego_chance=-1000},
			{type="armor", subtype="heavy", name="iron mail armour", autoreq=true, ego_chance=-1000, ego_chance=-1000}
		},
	},
	copy_add = {
		life_rating = 4,
	},
	party_copy = {
		known_tinkers = {
			PAIN_SUPPRESSOR_SALVE = true,
		}
	},
}
