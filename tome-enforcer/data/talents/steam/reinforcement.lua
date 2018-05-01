-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2017 Nicolas Casalini
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
	-- Instant ability. Restores Steam and temporarily buffs max Steam capacity.
	name = "Supercapacitators",
	type = {"steamtech/reinforcement", 1},
	require = steamreq1,
	mode = "sustained",
	points = 5,
	cooldown = 10,
	sustain_steam = 15,
	tactical = { BUFF=2 },
	on_pre_use = function(self, t, silent) if not self:hasShield() then if not silent then game.logPlayer(self, "You require a weapon and a shield to use this talent.") end return false end return true end,
	getBlock = function(self, t) return self:combatTalentSteamDamage(t, 20, 250) end,
	getStunDuration = function(self, t) return math.floor(self:combatTalentScale(t, 2.0, 4.0)) end,
	activate = function(self, t)
		local shield = self:hasShield()
		if not shield then
			game.logPlayer(self, "You cannot use Automated Kinetic Defense without a shield!")
			return nil
		end
		local ret = {
			block = self:addTemporaryValue("block_bonus", t.getBlock(self,t)),
		}
		if core.shader.active(4) then
			self:talentParticles(ret, {type="shader_shield", args={toback=true,  size_factor=1, img="rotating_shield"}, shader={type="rotatingshield", noup=2.0, appearTime=0.2}})
			self:talentParticles(ret, {type="shader_shield", args={toback=false, size_factor=1, img="rotating_shield"}, shader={type="rotatingshield", noup=1.0, appearTime=0.2}})
		end
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeTemporaryValue("block_bonus", p.block)
		return true
	end,
	callbackOnBlock = function(self, t, eff, dam, type, src)
		if self.block then
			game.logSeen(src, "Automated Kinetic Defense retaliates against %s!", src.name:capitalize())
			src:setEffect(src.EFF_STUNNED, t.getStunDuration(self, t), {apply_power=self:combatAttackStr()})
		end
	end,
	info = function(self, t)
		return ([[Supercapacitators provide a burst of steam during crucial moments.
		Instantly restores XX steam and increases tank capacity by XX for XX turns.]])
	end,
}

newTalent{
	-- Instant ability. Removes negative physical and mental effects, and buffs saves temporarily.
	name = "Adrenal Injector",
	type = {"steamtech/reinforcement", 2},
	require = steamreq2,
	mode = "sustained",
	points = 5,
	cooldown = 10,
	sustain_steam = 15,
	tactical = { BUFF=2 },
	on_pre_use = function(self, t, silent) if not self:hasShield() then if not silent then game.logPlayer(self, "You require a weapon and a shield to use this talent.") end return false end return true end,
	getCooldownReduction = function(self, t) return self:combatTalentLimit(t, 40, 5.0, 25.0) end,  -- Limit to <= 35%
	getDazeDur = function(self, t) return math.floor(self:combatTalentScale(t, 2.0, 4.0)) end,
	target = function(self, t)
		return {type="ball", range=0, radius=2, selffire=false, talent=t}
	end,
	activate = function(self, t)
		local shield = self:hasShield()
		if not shield then
			game.logPlayer(self, "You cannot use Thumper Module without a shield!")
			return nil
		end
		local ret = {
			cdred = self:addTemporaryValue("talent_cd_reduction", {
				[self.T_BLOCK] = math.floor(t.getCooldownReduction(self, t)*self:getTalentCooldown(	self.talents_def.T_BLOCK)/100),
			})
		}
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeTemporaryValue("talent_cd_reduction", p.cdred)
		return true
	end,
	callbackOnTalentPost = function(self, t, ab, ret)
		if ab.id == self.T_BLOCK and ret == true then
			local tg = self:getTalentTarget(t)
			
			if core.shader.active(4) then
				game.level.map:particleEmitter(self.x, self.y, tg.radius, "gravity_spike", {radius=tg.radius * 2, allow=core.shader.allow("distort")})
			end
			
			self:project(tg, self.x, self.y, function(px, py)
				local target = game.level.map(px, py, Map.ACTOR)
				if not target then return end
				target:setEffect(target.EFF_DAZED, t.getDazeDur(self, t), {apply_power=self:combatAttackStr()})
			end)
			
			game:playSoundNear(self, "talents/earth")
		end
		return
	end,
	info = function(self, t)
		local cooldownred = t.getCooldownReduction(self, t)
		return ([[Pain and fear are all in the mind. An adrenaline shot can rapidly clear such detriments.
		Instantly removes up to XX random negative physical / mental effects, and buffs all saves by +XX for XX turns.]])
	end,
}

newTalent{
	-- When health gets below a certain threshold, purge all debuffs and gain resistance to all damage.
	name = "Shock Therapy",
	type = {"steamtech/reinforcement", 3},
	require = steamreq3,
	mode = "sustained",
	points = 5,
	cooldown = 10,
	sustain_steam = 15,
	tactical = { BUFF=2 },
	on_pre_use = function(self, t, silent) if not self:hasShield() then if not silent then game.logPlayer(self, "You require a weapon and a shield to use this talent.") end return false end return true end,
	getDamageOnMeleeHit = function(self, t) return self:combatTalentScale(t, 21, 65) end,
	getDebuffDur = function(self, t) return math.floor(self:combatTalentScale(t, 2.0, 4.0)) end,
	
	target = function(self, t)
		return {type="ball", range=0, radius=1, selffire=false, talent=t}
	end,
	activate = function(self, t)
		local shield = self:hasShield()
		if not shield then
			game.logPlayer(self, "You cannot use Thermal Reprisal without a shield!")
			return nil
		end
		local ret = {
			onhit = self:addTemporaryValue("on_melee_hit", {[DamageType.FIRE]=t.getDamageOnMeleeHit(self, t)}),
			particle = self:addParticles(Particles.new("golden_shield", 1))
		}
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		self:removeTemporaryValue("on_melee_hit", p.onhit)
		return true
	end,
	callbackOnTalentPost = function(self, t, ab, ret)
		if ab.id == self.T_BLOCK and ret == true then
			local tg = self:getTalentTarget(t)
			
			if core.shader.active(4) then
				game.level.map:particleEmitter(self.x, self.y, tg.radius, "ball_fire", {radius=tg.radius})
			end
			
			self:project(tg, self.x, self.y, function(px, py)
				local target = game.level.map(px, py, Map.ACTOR)
				if not target then return end
				target:setEffect(target.EFF_DISARMED, t.getDebuffDur(self, t), {apply_power=self:combatAttackStr()})
				target:setEffect(target.EFF_BLINDED, t.getDebuffDur(self, t), {apply_power=self:combatAttackStr()})
			end)
		end
		return
	end,
	info = function(self, t)
		return ([[Outfit a tesladoc injector to your steam generators.
		The device jolts you whenever you are bloodied (health falls below <XX of max), instantly purging you of all negative effects and providing +XX resistance to all damage for XX turns.
		This can only trigger once every XX turns.]])
	end,
}

newTalent{
	-- Sustained talent. Whenever you deal damage, gain a Breaking Point.
	-- At max stacks, consume all Breaking Points to further buff dealt damage.
	name = "Breaking Point",
	type = {"steamtech/reinforcement", 4},
	points = 5,
	require = steamreq4,
	cooldown = 0,
	no_npc_use = true,
	getPower = function(self, t) return math.floor(60 + self:combatTalentScale(t, 10, 50)) end,
	getCooldownMod = function(self, t) return math.floor(140 - self:combatTalentLimit(t, 60, 5, 40)) end,
	on_learn = function(self, t)
		if self:getTalentLevelRaw(t) == 1 then self:addMedicalInjector(t) end
		self.inscriptions_data.MIND_INJECTION = {
			power = t.getPower(self, t),
			cooldown_mod = t.getCooldownMod(self, t),
			cooldown = 1,
		}
	end,
	on_unlearn = function(self, t)
		self.inscriptions_data.MIND_INJECTION = {
			power = t.getPower(self, t),
			cooldown_mod = t.getCooldownMod(self, t),
			cooldown = 1,
		}
		if self:getTalentLevelRaw(t) == 0 then self:removeMedicalInjector(t) self.inscriptions_data.MIND_INJECTION = nil end
	end,
	action = function(self, t)
		game.bignews:saySimple(120, "#LIGHT_BLUE#Mind Injection selected to be used first by salves.")
		game.logPlayer(self, "This medical injector will now be used first if available when using medical salves.")
		self:setFirstMedicalInjector(t)
		return false
	end,
	info = function(self, t)
		return ([[While Breaking Point is active, a specialized medical injector siphons a portion of your battle-generated adrenaline.
		Gain an adrenal point every time you deal damage.
		At 10 stacks, the injector provides you with a surge of adrenaline, increasing attack speed by XX and critical hit rate by XX for XX turns.
		Breaking points are removed upon running or resting.]])
	end,
}
