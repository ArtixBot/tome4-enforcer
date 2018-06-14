-- ToME - Tales of Maj'Eyal:
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

local Stats = require "engine.interface.ActorStats"
local Particles = require "engine.Particles"
local Entity = require "engine.Entity"
local Chat = require "engine.Chat"
local Map = require "engine.Map"
local Level = require "engine.Level"

newEffect{
	name = "FLASHBANG_BLIND", image = "talents/grenade_flashbang.png",
	desc = "Flashbang Blind",
	long_desc = function(self, eff)
		local desc = "This unit was struck by a flashbang, blinding it and applying a decaying global slow (current slow intensity: %d%%)." 
		return desc:format(eff.power * 100) end,
	type = "physical",
	display_desc = function(self, eff) return "Flashbang Blind" end,
	subtype = { blind=true, slow=true },
	status = "detrimental",
	parameters = {power = 0.01, orig_dur = 1},
	on_gain = function(self, err) return "#Target# is struck by a flashbang!", "+Flashbang Blind" end,
	on_lose = function(self, err) return "#Target# recovers from the flashbang.", "-Flashbang Blind" end,
	activate = function(self, eff)
		eff.spd = self:addTemporaryValue("global_speed_add", -eff.power)
		
		eff.tmpid = self:addTemporaryValue("blind", 1)
		if game.level then
			self:resetCanSeeCache()
			if self.player then for uid, e in pairs(game.level.entities) do if e.x then game.level.map:updateMap(e.x, e.y) end end game.level.map.changed = true end
		end
	end,
	-- Decaying effect.
	on_timeout = function(self, eff)
		-- There's something weird with detrimental effects lasting 1 turn longer on summoned creatures. Probably energy shenanigans.
		-- TODO: Check that...
		local newPower = eff.power * ( (eff.orig_dur - 1) / eff.orig_dur)
		if newPower ~= eff.power and eff.dur ~= eff.orig_dur then
			eff.power = newPower
			self:removeTemporaryValue("global_speed_add", eff.spd)
			eff.spd = self:addTemporaryValue("global_speed_add", -eff.power)
		end
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("global_speed_add", eff.spd)
		self:removeTemporaryValue("blind", eff.tmpid)
		if game.level then
			self:resetCanSeeCache()
			if self.player then for uid, e in pairs(game.level.entities) do if e.x then game.level.map:updateMap(e.x, e.y) end end game.level.map.changed = true end
		end
	end,
}

newEffect{
	name = "SUPPRESSED", image = "talents/subjugation.png",
	desc = "Suppressed",
	long_desc = function(self, eff)
		local desc = "Under heavy fire! %d reduced physical and mental saves, %d reduced accuracy, and %d increased defense."
		if eff.dmg > 0 then desc = "Under heavy fire! %d reduced physical and mental saves, %d reduced accuracy, and %d increased defense. Lost focus, dealing %d%% less damage." end
		if eff.threshold > 0 and eff.stacks >= eff.threshold then desc = "#YELLOW#Under heavy fire!#WHITE# 25%% chance to fail talent usage, 80%% reduced move speed, %d reduced physical and mental saves, %d reduced accuracy, and %d increased defense. Lost focus, dealing %d%% less damage." end
		return desc:format(eff.power * eff.stacks, eff.acc * eff.stacks, eff.def * eff.stacks, eff.dmg * eff.stacks)
	end,
	type = "mental",
	subtype = {slow=true},
	display_desc = function(self, eff) return eff.stacks.." Suppressed" end,
	charges = function(self, eff) return eff.stacks or 1 end,
	status = "detrimental",
	parameters = {power=1, acc=1, def=1, dmg=0, threshold=-1, stacks=1, max_stacks=10 },
	on_gain = function(self, err) return "#Target# is being suppressed!", "+Suppressed" end,
	on_lose = function(self, err) return "#Target# is no longer suppressed.", "-Suppressed" end,
	on_merge = function(self, old_eff, new_eff)
		old_eff.dur = new_eff.dur
		
		local stackCount = old_eff.stacks + new_eff.stacks
		if stackCount >= old_eff.max_stacks then 
			stackCount = old_eff.max_stacks
		end
	
		self:removeTemporaryValue("combat_mentalresist", old_eff.mental)
		self:removeTemporaryValue("combat_physresist", old_eff.physical)
		self:removeTemporaryValue("combat_atk", old_eff.accint)
		self:removeTemporaryValue("inc_damage", old_eff.dmgdown)
		
		if old_eff.tmpid then self:removeTemporaryValue("movement_speed", old_eff.tmpid) end
		if old_eff.failid then self:removeTemporaryValue("talent_fail_chance", old_eff.failid) end
		
		self:removeTemporaryValue("combat_def", old_eff.defint)	
			
		old_eff.mental = self:addTemporaryValue("combat_mentalresist", -old_eff.power*stackCount)
		old_eff.physical = self:addTemporaryValue("combat_physresist", -old_eff.power*stackCount)
		old_eff.accint = self:addTemporaryValue("combat_atk", -old_eff.acc*stackCount)
		old_eff.dmgdown = self:addTemporaryValue("inc_damage", {all = -old_eff.dmg*stackCount})
		
		if old_eff.threshold > 0 and old_eff.stacks >= old_eff.threshold then
			old_eff.tmpid = self:addTemporaryValue("movement_speed", -0.80)
			old_eff.failid = self:addTemporaryValue("talent_fail_chance", 25)
		end
		
		old_eff.defint = self:addTemporaryValue("combat_def", old_eff.def*stackCount)
		
		old_eff.stacks = stackCount
		
		return old_eff
		
	end,
	activate = function(self, eff)
		eff.defint = self:addTemporaryValue("combat_def", eff.def*eff.stacks)			
		
		eff.mental = self:addTemporaryValue("combat_mentalresist", -eff.power*eff.stacks)
		eff.physical = self:addTemporaryValue("combat_physresist", -eff.power*eff.stacks)
		eff.accint = self:addTemporaryValue("combat_atk", -eff.acc*eff.stacks)
		eff.dmgdown = self:addTemporaryValue("inc_damage", {all = -eff.dmg*eff.stacks})
		if eff.threshold > 0 and eff.stacks >= eff.threshold then
			eff.tmpid = self:addTemporaryValue("movement_speed", -0.80)
			eff.failid = self:addTemporaryValue("talent_fail_chance", 25)
		end
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("combat_def", eff.defint)	
		
		self:removeTemporaryValue("combat_mentalresist", eff.mental)
		self:removeTemporaryValue("combat_physresist", eff.physical)
		self:removeTemporaryValue("combat_atk", eff.accint)
		self:removeTemporaryValue("inc_damage", eff.dmgdown)
		if eff.tmpid then self:removeTemporaryValue("movement_speed", eff.tmpid) end
		if eff.failid then self:removeTemporaryValue("talent_fail_chance", eff.failid) end
	end,
}

newEffect{
	name = "CHEMICAL_GAS", image = "talents/grenade_chemical_gas.png",
	desc = "Chemical Gas",
	long_desc = function(self, eff)
		return ("This unit is poisoned by chemical fumes, reducing all damage dealt by %d%% and healing mod by %d%%."):format(eff.power, eff.heal_factor) end,
	type = "physical",
	display_desc = function(self, eff) return "Chemical Gas" end,
	subtype = { poison=true },
	status = "detrimental",
	parameters = {power = 1, heal_factor = 10},
	on_gain = function(self, err) return "#Target# suffers from chemical poisoning!", "+Chemical Gas" end,
	on_lose = function(self, err) return "#Target# recovers from chemical poisoning.", "-Chemical Gas" end,
	activate = function(self, eff)
		eff.dmg = self:addTemporaryValue("inc_damage", {all=-eff.power})
		eff.heal = self:addTemporaryValue("healing_factor", -eff.heal_factor / 100)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("inc_damage", eff.dmg)
		self:removeTemporaryValue("healing_factor", eff.heal)
	end,
}

newEffect{
	name = "BLAST_MANUEVERS", image = "talents/blast_manuevers.png",
	desc = "Blast Manuevers",
	long_desc = function(self, eff)
		return ("Actively venting steam from using a grenade talent; Blast Manuevers available for use."):format() end,
	type = "physical",
	display_desc = function(self, eff) return "Blast Manuevers" end,
	subtype = { speed=true, tactic=true },
	status = "beneficial",
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}