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
	-- Root self. Increases attack speed, reload rate, and range while active.
	-- Passively increases Defense and Armor.
	name = "Protect and Serve",
	type = {"technique/steamshield", 1},
	message = "@Source@ braces for combat!",
	require = techs_dex_req1,
	mode = "sustained",
	points = 5,
	tactical = { BUFF = 3 },
	callbackOnRest = function(self, t) self:forceUseTalent(t.id, {ignore_cooldown=true, ignore_energy=true}) end,
	callbackOnRun = function(self, t) self:forceUseTalent(t.id, {ignore_cooldown=true, ignore_energy=true}) end,
	on_pre_use = function(self, t, silent) if not self:hasShield() then if not silent then game.logPlayer(self, "You require a weapon and a shield to use this talent.") end return false end return true end,
	getPassives = function(self, t) return self:combatTalentStatDamage(t, "str", 6, 22) end,
	getAtk = function(self, t) return self:combatTalentScale(t, 14, 47) end,
	getReload = function(self, t) return math.floor(self:combatTalentScale(t, 3, 5, "log")) end,
	getAttackSpeed = function(self, t) return math.floor(self:combatTalentLimit(t, 50, 15, 45))/100 end,
	activate = function(self, t)
		local shield = self:hasShield()
		if not shield then
			game.logPlayer(self, "You cannot use Protect and Serve without a shield!")
			return nil
		end
		
		local ret = {
			acc = self:addTemporaryValue('combat_atk', t.getAtk(self, t)),
			ammo = self:addTemporaryValue('ammo_mastery_reload', t.getReload(self, t)),
			speed = self:addTemporaryValue("combat_physspeed", t.getAttackSpeed(self, t)),
			nomove = self:addTemporaryValue("never_move", 1),
		}
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeTemporaryValue("combat_atk", p.acc)
		self:removeTemporaryValue("ammo_mastery_reload", p.ammo)
		self:removeTemporaryValue("combat_physspeed", p.speed)
		self:removeTemporaryValue("never_move", p.nomove)
		return true
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "combat_armor", t.getPassives(self, t) + 5)
		self:talentTemporaryValue(p, "combat_def", t.getPassives(self, t) + 5)
	end,
	info = function(self, t)
		return ([[Deploy your shield in preparation for the battle ahead, rooting yourself in place.
		While active, increases your attack speed by %d%%, reload rate by %d, and accuracy by %d.
		Learning this technique permanently increases Defense and Armor by %d (even while not sustained). These bonuses scale with Strength.
		This talent is disabled automatically on rest or run.]]):
		format(t.getAttackSpeed(self, t)*100, t.getReload(self, t), t.getAtk(self, t), t.getPassives(self, t) + 5)
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
	on_pre_use = function(self, t, silent) if not self:hasArcheryWeapon("steamgun") then if not silent then game.logPlayer(self, "You require a steamgun and shield for this talent.") end return false end return true end,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 1.0, 1.25) end,
	getKnockback = function(self, t) return math.floor(self:combatTalentScale(t, 2.0, 5.0)) end,
	archery_onhit = function(self, t, target, x, y)
		if target:canBe("knockback") and target:checkHit(self:combatAttack(), target:combatMentalResist(), 0, 95, 5) then
			target:knockback(self.x, self.y, t.getKnockback(self, t))
		end
	end,
	action = function(self, t)
		local shield = self:hasShield()
		if not shield then
			game.logPlayer(self, "You cannot use Circle Fire without a steamgun and shield!")
			return nil
		end

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
	on_pre_use = function(self, t, silent) if not self:hasArcheryWeapon("steamgun") then if not silent then game.logPlayer(self, "You require a steamgun for this talent.") end return false end return true end,
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
		Afterwards, perform a shield slam against an adjacent target for %d%% shield damage.
		The shot target is crippled, reducing melee/spellcasting/mental cast speeds by %d%%; the slammed target is stunned. Both effects last %d turns.
		The chance to cripple scales with Accuracy, and the chance to stun scales with Physical Power.]]):format(100 * t.getShieldDamage(self, t), 100 * t.getCripplePow(self, t), t.getDebuffDur(self, t))
	end,
}

newTalent{
	-- Perform a shield slam in an arc in front of the user; then, fire a buckshot round that hits nearby enemies in a cone.
	-- Slammed targets are pushed back; shot targets are dazed.
	name = "Clear the Way",
	type = {"technique/steamshield", 4},
	require = techs_dex_req4,
	points = 5,
	cooldown = 10,
	steam = 40,
	range = 0,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 3, 5)) end,
	radiusB = 1,
	tactical = { ATTACK = { weapon = 2 }, DISABLE = { stun = 2 }, },
	target = function(self, t)
		return {type="cone", range=self:getTalentRange(t), selffire=false, radius=self:getTalentRadius(t)}
	end,
	on_pre_use = function(self, t, silent) if not self:hasArcheryWeapon("steamgun") then if not silent then game.logPlayer(self, "You require a steamgun for this talent.") end return false end return true end,
	getShieldDamage = function(self, t) return self:combatTalentWeaponDamage(t, 1.2, 1.8) end,
	getDebuffDur = function(self, t) return math.floor(self:combatTalentScale(t, 2.0, 4.0)) end,
	archery_onhit = function(self, t, target, x, y)
		target:setEffect(target.EFF_DAZED, t.getDebuffDur(self, t), {apply_power=self:combatAttack()})
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
		self:archeryShoot(targets, t, {type = "hit", primaryeffect=tg.radius, primarytarget=target}, {mult=dam, one_shot=true, type="steamgun"})		return true
	end,
	info = function(self, t)
		return ([[You viciously swipe your shield in an arc in front of you, dealing %d%% shield damage.
		Immediately afterwards, you follow up with a custom-made piercing buckshot round, dealing XX damage in a radius-XX cone.
		Slammed targets are knocked back XX tiles; shot targets are dazed for XX turns.
		Chance to knockback scales with Strength, while daze chance scales with Accuracy.]]):format(100 * t.getShieldDamage(self, t))
	end,
}