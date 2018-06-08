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

newTalent{
	-- Effectively the Enforcer's take on the Bulwark's Shield Wall talent.
	name = "Protect and Serve",
	type = {"technique/steamshield", 1},
	require = techs_dex_req1,
	mode = "sustained",
	points = 5,
	tactical = { BUFF = 3 },
	on_pre_use = function(self, t, silent) if not self:hasShield() then if not silent then game.logPlayer(self, "You require a steamgun and shield to use this talent.") end return false end return true end,
	getMaxCap = function(self, t) return 100 - (3 * self:getTalentLevelRaw(t)) end,	-- 97/94/91/88/85. Shouldn't be OP.
	getPercentStr = function(self, t) return 0.20 + self:combatTalentScale(t, 0.0, 0.20) end,
	getPercentDex = function(self, t) return 0.15 + self:combatTalentScale(t, 0.0, 0.15) end,
	getPassives = function(self, t) return self:combatTalentStatDamage(t, "str", 6, 22) end,
	activate = function(self, t)
		-- Could make this math.floor but it's just 1 point.
		local dr = math.ceil(t.getPercentStr(self, t) * self:getStr())
		local cmult = math.ceil(t.getPercentDex(self, t) * self:getDex())
		
		local ret = {
			flat = self:addTemporaryValue("flat_damage_armor", {all = dr}),
			crit = self:addTemporaryValue("ignore_direct_crits", cmult)
		}
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeTemporaryValue("flat_damage_armor", p.flat)
		self:removeTemporaryValue("ignore_direct_crits", p.crit)
		return true
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "flat_damage_cap", {all = t.getMaxCap(self, t)})
	end,
	info = function(self, t)
		local dr = math.ceil(t.getPercentStr(self, t) * self:getStr())
		local cmult = math.ceil(t.getPercentDex(self, t) * self:getDex())
		return ([[Enhances your skill with the shield and steamgun.
		While sustained, you adopt a defensive stance, conferring %d flat damage reduction against all attacks, equivalent to %d%% of your Strength stat.
		This stance steadies you against critical blows; all direct critical hits against you have %d%% reduced Critical multiplier (but still deal at least normal damage), equivalent to %d%% of your Dexterity stat.
		Learning this talent steels your resolve; even when not sustained, you can never take a single blow dealing more than %d%% of your max life.]]):
		format(dr, t.getPercentStr(self, t) * 100, cmult, t.getPercentDex(self, t) * 100, t.getMaxCap(self, t))
	end,
}

newTalent{
	-- Shoot all adjacent enemies at reduced accuracy. May startle targets, pushing them back.
	-- Immediately guard afterwards, even if on cooldown.
	name = "Circle Fire",
	type = {"technique/steamshield", 2},
	require = techs_dex_req2,
	points = 5,
	cooldown = 14,
	steam = 25,
	range = 0,
	radius = 1,
	tactical = { ATTACKAREA = { weapon = 3 } },
	random_ego = "attack",
	target = function(self, t)
		local weapon, ammo = self:hasArcheryWeapon()
		return {type="ball", radius=self:getTalentRadius(t), range=self:getTalentRange(t), selffire=false, display=self:archeryDefaultProjectileVisual(weapon, ammo)}
	end,
	on_pre_use = function(self, t, silent) if not self:hasArcheryWeapon("steamgun") or not self:hasShield() then if not silent then game.logPlayer(self, "You require a steamgun and shield for this talent.") end return false end return true end,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 0.6, 0.9) end,
	getKnockback = function(self, t) return math.floor(self:combatTalentScale(t, 2.0, 5.0)) end,
	archery_onhit = function(self, t, target, x, y)
		if target:canBe("knockback") and target:checkHit(self:combatAttack(), target:combatMentalResist(), 0, 95, 5) then
			target:knockback(self.x, self.y, t.getKnockback(self, t))
		end
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		
		local target = game.level.map(x, y, game.level.map.ACTOR)
		
		if not target then return end
		local targets = self:archeryAcquireTargets(tg, {x=target.x, y=target.y})
		
		if not targets then return nil end
		local dam = t.getDamage(self,t)
		self:archeryShoot(targets, t, {type = "hit", primaryeffect=tg.radius, primarytarget=target}, {mult=dam, one_shot=true, type="steamgun"})
		
		self:forceUseTalent(self.T_BLOCK, {ignore_energy=true, ignore_cd = true, silent = true})

		return true
	end,
	info = function(self, t)
		return ([[Rapidly fire your weapon, performing a basic ranged shot against all adjacent enemies for %d%% weapon damage.
		This startles them, which pushes them back %d tiles if they fail a mental save.
		Immediately afterwards, you instantly enter a blocking stance (even if Block is on cooldown).
		Chance to push enemies increases with Accuracy.]]):format(t.getDamage(self, t)*100, t.getKnockback(self, t))
	end,
}

newTalent{
	-- Shoot at an enemy with increased critical chance; then, perform a shield attack against an adjacent target.
	-- If you target the same enemy with both attacks, inflicts stun.
	name = "Slamshot",
	type = {"technique/steamshield", 3},
	points = 5,
	cooldown = 10,
	steam = 25,
	require = techs_dex_req3,
	range = steamgun_range,
	requires_target = true,
	tactical = { ATTACK = { weapon = 2 }, DISABLE = { stun = 2 }, },
	target = function(self, t) return {type="hit", range=1} end,
	on_pre_use = function(self, t, silent) if not self:hasArcheryWeapon("steamgun") or not self:hasShield() then if not silent then game.logPlayer(self, "You require a steamgun and shield for this talent.") end return false end return true end,
	getDur = function(self, t) return self:combatTalentLimit(t, 6, 1, 2.5) end,
	getShieldDamage = function(self, t) return self:combatTalentWeaponDamage(t, 1.2, 1.8) end,
	getDebuffDur = function(self, t) return math.floor(self:combatTalentScale(t, 2.0, 4.0)) end,
	getCripplePow = function(self, t) return self:combatTalentScale(t, 26, 50) / 100 end,
	archery_onreach = function(self, t, target, x, y)
		self.turn_procs.auto_phys_crit = true
	end,
	archery_onhit = function(self, t, target, x, y)
		target:setEffect(target.EFF_CRIPPLE, t.getDebuffDur(self, t), {speed=t.getCripplePow(self, t), apply_power=self:combatAttack()})
	end,
	action = function(self, t)
		local targetmode_trigger_hotkey
		if self.player then targetmode_trigger_hotkey = game.targetmode_trigger_hotkey end

		local targets = self:archeryAcquireTargets(nil, {no_energy=true, type="steamgun"})
		if not targets then return end
	
		self:archeryShoot(targets, t, nil, {type="steamgun"})
		self.turn_procs.auto_phys_crit = nil	
		

		-- Adapted code from Tactical Expert, located under cunning/tactical.lua. May (?) have bugs as a result.
		-- Used to automatically terminate talent if no enemies are adjacent.
		local nb_foes = 0
		local act
		for i = 1, #self.fov.actors_dist do
			act = self.fov.actors_dist[i]
			if act and game.level:hasEntity(act) and self:reactionToward(act) < 0 and self:canSee(act) and act["__sqdist"] <= 2 then nb_foes = nb_foes + 1 end
		end
		
		if nb_foes <= 0 then
			return true
		else
			local tg = self:getTalentTarget(t)
			local x, y, target = self:getTarget(tg)
			
			if not target or not self:canProject(tg, x, y) then
				return true
			else
				self:attackTargetWith(target, shield_combat, nil, t.getShieldDamage(self, t))
				target:setEffect(target.EFF_STUNNED, t.getDebuffDur(self, t), {apply_power=self:combatPhysicalpower()})
			end
		end	
		
		return true
	end,
	info = function(self, t)
		return ([[Fire at an enemy with your steamgun for 100%% weapon damage which critically strikes on hit.
		Afterwards, perform a shield slam against an adjacent target (if possible) for %d%% shield damage.
		The shot target is crippled, reducing melee/spellcasting/mental speed by %d%%; the slammed target is stunned. Both effects last %d turns.
		Chance to cripple increases with Accuracy, chance to stun increases with Physical Power.]]):format(100 * t.getShieldDamage(self, t), 100 * t.getCripplePow(self, t), t.getDebuffDur(self, t))
	end,
}

newTalent{
	-- Fire a buckshot round that hits nearby enemies in a cone, then charge along the fired path to deal additional damage.
	-- Shot targets are dazed. Targets along charge path are stunned instead.
	name = "Clear the Way",
	type = {"technique/steamshield", 4},
	require = techs_dex_req4,
	points = 5,
	cooldown = 10,
	steam = 40,
	range = 0,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 3, 5)) end,
	tactical = { ATTACK = { weapon = 2 }, DISABLE = { stun = 2 }, },
	target = function(self, t)
		local weapon, ammo = self:hasArcheryWeapon()
		return {type = "cone", range = self:getTalentRange(t), radius = self:getTalentRadius(t), selffire = false, talent = t }
	end,
	on_pre_use = function(self, t, silent) if not self:hasArcheryWeapon("steamgun") or not self:hasShield() then if not silent then game.logPlayer(self, "You require a steamgun for this talent.") end return false end return true end,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 0.4, 0.72) end,
	getShieldDamage = function(self, t) return self:combatTalentWeaponDamage(t, 1.2, 1.8) end,
	getDebuffDur = function(self, t) return math.floor(self:combatTalentScale(t, 2.0, 4.0)) end,
	archery_onhit = function(self, t, target, x, y)
		target:setEffect(target.EFF_DAZED, t.getDebuffDur(self, t), {apply_power=self:combatAttack()})
	end,
	action = function(self, t)
		-- Code salvaged from Scatter Shot (archery), albeit modified. The actual shooting part is conducted after knockback to prevent self-shooting (among other bugs).
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		local targets = {}
		local add_target = function(x, y)
			local target = game.level.map(x, y, game.level.map.ACTOR)
			if target and self:reactionToward(target) < 0 and self:canSee(target) then
				targets[#targets + 1] = target
			end
		end
		self:project(tg, x, y, add_target)
		if #targets == 0 then return end

		table.shuffle(targets)
		
		-- Code salvaged from Reckless Charge (cursed/slaughter), albeit modified.
		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", target) end
		local lineFunction = core.fov.line(self.x, self.y, x, y, block_actor)
		local nextX, nextY, is_corner_blocked = lineFunction:step()
		local currentX, currentY = self.x, self.y
		
		local tiles_moved = 0
		while nextX and nextY and tiles_moved < self:getTalentRadius(t) do
			local blockingTarget = game.level.map(nextX, nextY, Map.ACTOR)
			if blockingTarget and self:reactionToward(blockingTarget) < 0 then
				local dir = rng.range(0, 8)
				for i = dir, dir + 8 do
					local tX = nextX + (i % 3) - 1
					local tY = nextY + math.floor((i % 9) / 3) - 1
					if core.fov.distance(currentY, currentX, tX, tY) > 1 and game.level.map:isBound(tX, tY) and not game.level.map:checkAllEntities(tX, tY, "block_move", self) then
						blockingTarget:move(tX, tY, true)
						self:attackTargetWith(blockingTarget, shield_combat, nil, t.getShieldDamage(self, t))
						blockingTarget:setEffect(blockingTarget.EFF_STUNNED, t.getDebuffDur(self, t), {apply_power = self:combatPhysicalpower()})
						break
					end
				end
			end
			
			-- check that we can move
			if not game.level.map:isBound(nextX, nextY) or game.level.map:checkAllEntities(nextX, nextY, "block_move", self) then break end
			-- allow the move
			currentX, currentY = nextX, nextY
			nextX, nextY, is_corner_blocked = lineFunction:step()
			self:move(currentX, currentY, true)
			tiles_moved = tiles_moved + 1
		end
		
		-- Fire each shot individually.
		local old_target_forced = game.target.forced
		local shot_params_base = {mult = t.getDamage(self, t), phasing = true, type="steamgun"}
		for i = 1, #targets do
			local target = targets[i]
			game.target.forced = {target.x, target.y, target}
			local targets = self:archeryAcquireTargets({type = "hit"}, {infinite=true, one_shot=true, no_energy = true, type="steamgun"})
			if targets then
				local params = table.clone(shot_params_base)
				local target = targets.dual and targets.main[1] or targets[1]
				params.phase_target = game.level.map(target.x, target.y, game.level.map.ACTOR)
				self:archeryShoot(targets, t, {type = "beam"}, params)
			end
		end

		game.target.forced = old_target_forced
		
		return true
	end,
	info = function(self, t)
		return ([[Fire a piercing buckshot which deals %d%% weapon damage and dazes (duration %d) all hit targets in a radius-%d cone.
		You then charge with your shield, ending up at the same location as where you aimed; targets along the path take %d%% shield damage, are stunned for %d turns, and are knocked to an adjacent tile.
		Chance to daze increases with Accuracy, chance to stun increases with Physical Power.
		This talent does not use ammo.]]):format(100 * t.getDamage(self, t), t.getDebuffDur(self, t), self:getTalentRadius(t), 100 * t.getShieldDamage(self, t), t.getDebuffDur(self, t))
	end,
}