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
	getPassives = function(self, t) return self:combatTalentStatDamage(t, "dex", 6, 22) end,
	getSight = function(self, t) return math.floor(self:combatTalentScale(t, 2, 4, "log")) end,
	getReload = function(self, t) return math.floor(self:combatTalentScale(t, 3, 5, "log")) end,
	getAttackSpeed = function(self, t) return math.floor(self:combatTalentLimit(t, 50, 15, 45))/100 end,
	activate = function(self, t)
		local shield = self:hasShield()
		if not shield then
			game.logPlayer(self, "You cannot use Protect and Serve without a shield!")
			return nil
		end
		
		local sight = t.getSight(self, t)
		local ret = {
			sightA = self:addTemporaryValue("sight", sight),
			sightB = self:addTemporaryValue("infravision", sight),
			sightC = self:addTemporaryValue("heightened_senses", sight),
			sightD = self:addTemporaryValue("archery_bonus_range", sight),
			ammo = self:addTemporaryValue('ammo_mastery_reload', t.getReload(self, t)),
			speed = self:addTemporaryValue("combat_physspeed", t.getAttackSpeed(self, t)),
		}
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeTemporaryValue("sight", p.sightA)
		self:removeTemporaryValue("infravision", p.sightB)
		self:removeTemporaryValue("heightened_senses", p.sightC)
		self:removeTemporaryValue("archery_bonus_range", p.sightD)
		self:removeTemporaryValue("ammo_mastery_reload", p.ammo)
		self:removeTemporaryValue("combat_physspeed", p.speed)
		return true
	end,
	info = function(self, t)
		return ([[Deploy your shield in preparation for the battle ahead, rooting yourself in place.
		While active, increases your attack speed by %d%%, reload rate by %d, and weapon attack and sight range by %d tiles.
		Even when not active, this ability passively increases Defense and Armor by XX.
		The increase in attack speed scales with Strength, and passive Defense and Armor scale with Dexterity.]]):
		format(t.getAttackSpeed(self, t)*100, t.getReload(self, t), t.getSight(self, t))
	end,
}

newTalent{
	-- Shoot all adjacent enemies at reduced accuracy. May startle targets, pushing them back.
	-- Immediately guard afterwards, even if on cooldown.
	name = "Circle Fire",
	type = {"technique/steamshield", 2},
	require = techs_dex_req2,
	points = 5,
	cooldown = 30,
	steam = 30,
	range = 0,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 4, 8)) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 5, 7)) end,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), selffire=false, radius=1}
	end,
	on_pre_use = function(self, t, silent) if not self:hasDualWeapon() then if not silent then game.logPlayer(self, "You require two weapons to use this talent.") end return false end return true end,
	tactical = { ATTACKAREA = 3 },
	action = function(self, t)
		local weapon, offweapon = self:hasDualWeapon()
		if not weapon then
			game.logPlayer(self, "Symphonic Whirl can only be used while dual wielding.")
			return nil
		end
		
		local tg = self:getTalentTarget(t)
		
		self:project(tg, self.x, self.y, function(px, py, tg, self)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and target ~= self then
				self:attackTarget(target, nil, self:combatTalentWeaponDamage(t, 0.47, 1.00), true)
				target:setEffect(target.EFF_TEMPO_DISRUPTION, 2, {})
			end
		end)

		self:addParticles(Particles.new("meleestorm", 1, {}))
		return true
	end,
	info = function(self, t)
		return ([[Rapidly fire your weapon, allowing a basic attack against all adjacent enemies but at reduced accuracy (-XX). This startles enemies, attempting to push them XX tiles.
		Immediately afterwards, you enter a blocking stance (even if Block is on cooldown).
		Chance to push enemies scales with Accuracy.]])
	end,
}

newTalent{
	-- Shoot at an enemy with increased critical chance; then, perform a shield attack against an adjacent target.
	-- If you target the same enemy with both attacks, inflicts stun and crippled.
	name = "Slamshot",
	type = {"technique/steamshield", 3},
	require = techs_dex_req3,
	points = 5,
	cooldown = 12,
	steam = 25,
	requires_target = true,
	is_melee = true,
	on_pre_use = function(self, t, silent) if not self:hasDualWeapon() then if not silent then game.logPlayer(self, "You require two weapons to use this talent.") end return false end return true end,
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 3, 5)) end,
	action = function(self, t)
		local weapon, offweapon = self:hasDualWeapon()
		if not weapon then
			game.logPlayer(self, "Cadenza can only be used while dual wielding.")
			return nil
		end
		
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not target or not self:canProject(tg, x, y) then return nil end
		local hit = self:attackTarget(target, nil, self:combatTalentWeaponDamage(t, 1.26, 1.61), true)

		-- Attempts to disarm.
		if hit then
			if target:canBe("disarmed") then
				target:setEffect(target.EFF_DISARMED, t.getDuration(self, t), {apply_power=self:combatPhysicalpower()})
			else
				game.logSeen(target, "%s is not disarmed!", target.name:capitalize())
			end
		end
		
		-- Attempts to confuse.
		if hit then
			if target:canBe("confused") then
				target:setEffect(target.EFF_CONFUSED, t.getDuration(self, t), {power=25})
			else
				game.logSeen(target, "%s resisted the confusion!", target.name:capitalize())
			end
		end
		game.level.map:particleEmitter(target.x, target.y, 1, "stalked_start")
		return true
	end,
	info = function(self, t)
		return ([[Fire with masterful accuracy, performing a ranged basic attack that has +XX increased critical chance.
		You then follow up with a shield slam (if possible) against an adjacent enemy, dealing XX shield damage.
		If you hit the same enemy with both attacks, the target is stunned and crippled for XX turns.]])
	end,
}

newTalent{
	-- Perform a shield slam in an arc in front of the user; then, fire a buckshot round that hits nearby enemies in a cone.
	-- Slammed targets are pushed back; shot targets are dazed.
	name = "Clear the Way",
	type = {"technique/steamshield", 4},
	require = techs_dex_req4,
	points = 5,
	cooldown = 20,
	steam = 40,
	requires_target = true,
	is_melee = true,
	on_pre_use = function(self, t, silent) if not self:hasDualWeapon() then if not silent then game.logPlayer(self, "You require two weapons to use this talent.") end return false end return true end,
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	action = function(self, t)
		local weapon, offweapon = self:hasDualWeapon()
		if not weapon then
			game.logPlayer(self, "Finale can only be used while dual wielding.")
			return nil
		end
		
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not target or not self:canProject(tg, x, y) then return nil end
		local hit = self:attackTarget(target, nil, self:combatTalentWeaponDamage(t, 4.00, 6.35), true)
		self:setEffect(self.EFF_FINALE_DEBUFF, 4, {power=0.35, apply_power=10000, no_ct_effect=true})
		game:playSoundNear(self, "talents/breath")
		return true
	end,
	info = function(self, t)
		return ([[You viciously swipe your shield in an arc in front of you, dealing XX shield damage.
		Immediately afterwards, you follow up with a custom-made piercing buckshot round, dealing XX weapon damage in a size-XX cone.
		Slammed targets are pushed back XX tiles; shot targets are dazed for XX turns.
		Chance to push back scales with Strength, while daze chance scales with Accuracy.]])
	end,
}
