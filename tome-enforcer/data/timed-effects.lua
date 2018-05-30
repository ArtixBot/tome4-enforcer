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
	name = "SUPPRESSED", image = "talents/subjugation.png",
	desc = "Suppressed",
	long_desc = function(self, eff)
		local desc = "Under heavy fire! %d reduced physical and mental saves, %d reduced accuracy, and %d increased defense."
		if eff.dmg > 0 then desc = "Under heavy fire! %d reduced physical and mental saves, %d reduced accuracy, and %d increased defense. Lost focus, dealing %d%% less damage." end
		if eff.threshold > 0 and eff.stacks >= eff.threshold then desc = "#YELLOW#Under heavy fire!#WHITE# 25%% chance to fail talent usage, 90%% reduced move speed, %d reduced physical and mental saves, %d reduced accuracy, and %d increased defense. Lost focus, dealing %d%% less damage." end
		return desc:format(eff.power * eff.stacks, eff.acc * eff.stacks, eff.def * eff.stacks, eff.dmg * eff.stacks)
	end,
	type = "mental",
	display_desc = function(self, eff) return eff.stacks.." Suppressed" end,
	charges = function(self, eff) return eff.stacks or 1 end,
	subtype = { temporal=true },
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
			old_eff.tmpid = self:addTemporaryValue("movement_speed", -80)
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
			eff.tmpid = self:addTemporaryValue("movement_speed", -80)
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