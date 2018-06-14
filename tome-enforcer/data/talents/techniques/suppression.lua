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


-- Damn it, this is the Jinx tree!
newTalent{
	-- Every time you attack an enemy you apply Suppressed, reducing physical save, mental save, and accuracy. The target does get bonus Defense (hunkering down).
	-- Stacks up to 10 times.
	name = "Subjugation",
	type = {"technique/suppression", 1},
	require = techs_dex_req1,
	mode = "passive",
	points = 5,
	getSaves = function(self, t) return math.ceil(self:getTalentLevelRaw(t) / 1.5) end,
	getAcc = function(self, t) return math.ceil(self:getTalentLevelRaw(t) / 2) end,
	getDef = function(self, t) return math.ceil(self:getTalentLevelRaw(t) / 2) end,
	getDuration = function(self, t)
		if self:knowTalent(self.T_STAY_DOWN) then
			local t = self:getTalentFromId(self.T_STAY_DOWN)
			return 2 + t.getDurInc(self, t)
		end
		return 2
	end,
	callbackOnArcheryAttack = function(self, t, target, hitted, crit, weapon, ammo, damtype, mult, dam)
		local x = t.getSaves(self, t)
		local y = t.getAcc(self, t)
		local g = t.getDef(self, t)
		local d = t.getDuration(self, t)
		if self:knowTalent(self.T_SUBDUED_TARGETS) and self:knowTalent(self.T_STAY_DOWN) then
			local z = self:getTalentFromId(self.T_SUBDUED_TARGETS).getReduction(self, t)
			local t = self:getTalentFromId(self.T_STAY_DOWN)
			target:setEffect(target.EFF_SUPPRESSED, d, {src=self, stacks=1, max_stacks = 10, power=x, acc = y, def = g, dmg = z, threshold = t.getThreshold(self, t)})
		elseif self:knowTalent(self.T_SUBDUED_TARGETS) then
			local t = self:getTalentFromId(self.T_SUBDUED_TARGETS)
			target:setEffect(target.EFF_SUPPRESSED, d, {src=self, stacks=1, max_stacks = 10, power=x, acc = y, def = g, dmg=t.getReduction(self, t)})
		else
			target:setEffect(target.EFF_SUPPRESSED, d, {src=self, stacks=1, max_stacks = 10, power=x, acc = y, def = g})
		end
	end,
	info = function(self, t)
		return ([[Managing overwhelming conflict requires a certain skill in suppressing the masses.
		Whenever you fire at an enemy you add a stack of Suppressed (max 10 stacks) to the target regardless of whether or not you hit, reducing its physical and mental saves by %d and its accuracy by %d, but increasing its Defense by %d per stack.
		Suppressed targets lose stacks if not shot at within 2 turns.]]):format(t.getSaves(self, t), t.getAcc(self, t), t.getDef(self, t))
	end,
}

newTalent{
	-- Suppression now reduces all damage dealt.
	-- Starts at 1% / stack, maxes out at 5% / stack (10-50% max reduction).
	name = "Subdued Targets",
	type = {"technique/suppression", 2},
	require = techs_dex_req2,
	points = 5,
	mode = "passive",
	getReduction = function(self, t) return self:getTalentLevelRaw(t) end,
	info = function(self, t)
		return ([[Incoming fire overwhelms your target.
		Suppressed targets cannot focus correctly, reducing all damage dealt by %d%% per stack (%d%% at 10 stacks).]]):format(t.getReduction(self, t), 10 * t.getReduction(self, t))
	end,
}

newTalent{
	-- Pin a target once it takes too many incoming shots.
	-- Also increases Suppressed duration.
	name = "Stay Down",
	type = {"technique/suppression", 3},
	points = 5,
	mode = "passive",
	require = techs_dex_req3,
	getThreshold = function(self, t)
		if self:getTalentLevelRaw(t) >= 5 then 
			return 4
		elseif self:getTalentLevelRaw(t) >= 3 then
			return 5
		else
			return 6
		end
	end,
	getDurInc = function(self, t)
		if self:getTalentLevel(t) >= 5 then
			return 2
		elseif self:getTalentLevel(t) >= 3 then
			return 1
		else
			return 0
		end
	end,
	info = function(self, t)
		return ([[Foes under fire stay hunkered down.
		Once a target reaches %d stacks of Suppressed it has a 25%% chance to fail talent usage and has 80%% reduced movement speed.
		At talent levels 3 and 5, Suppressed's duration increases by 1.]]):format(t.getThreshold(self, t))
	end,
}

newTalent{
	-- Apply negative status effects against Suppressed targets.
	name = "Hunkered Exploits",
	type = {"technique/suppression", 4},
	require = techs_dex_req4,
	points = 5,
	mode = "passive",
	getThreshold = function(self, t) return 5 - math.floor(self:getTalentLevelRaw(t) / 2) end,
	getCooldown = function(self, t) return 2 + math.floor(self:getTalentLevelRaw(t) / 2) end,
	getChance = function(self, t) return math.ceil(self:getTalentLevelRaw(t) / 2) end,
	callbackOnArcheryAttack = function(self, t, target, hitted, crit, weapon, ammo, damtype, mult, dam)
		local eff = target:hasEffect(target.EFF_SUPPRESSED)
		if eff and eff.stacks then
			local confuseChance = t.getChance(self, t) * eff.stacks
			if rng.percent(confuseChance + 5) then
				target:setEffect(target.EFF_CONFUSED, 2, {power = 40})
			end
		end
		if hitted and eff and eff.stacks >= t.getThreshold(self, t) then
			local tids = {}
			for tid, lev in pairs(target.talents) do
				local t = target:getTalentFromId(tid)
				if t and not target.talents_cd[tid] and t.mode == "activated" and not t.innate then tids[#tids+1] = t end
			end

			local cdr = t.getCooldown(self, t)
			local t = rng.tableRemove(tids)
			if not t then return end
			target.talents_cd[t.id] = cdr
			game.logSeen(target, "%s's %s is disrupted by the shot!", target.name:capitalize(), t.name)
		end
		
	end,
	info = function(self, t)
		return ([[A suppressed target puts self-preservation above all else.
		Whenever you shoot and hit a target with %d+ stacks of Suppressed, a random talent on the target is placed on cooldown for %d turns.
		Shots against Suppressed targets (even on miss) now gain a 5%% base chance + %d%% chance per stack (max: %d%%) to confuse the enemy (40%% power) for 3 turns.]]):format(t.getThreshold(self, t), t.getCooldown(self, t), t.getChance(self, t), 10 * t.getChance(self, t) + 5)
	end,
}