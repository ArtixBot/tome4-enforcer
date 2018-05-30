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
	-- Sustained ability. Increases block value.
	-- When blocking, melee attackers are stunned.
	name = "Automated Kinetic Defense",
	type = {"steamtech/shield-augments", 1},
	require = steamreq1,
	mode = "sustained",
	points = 5,
	cooldown = 14,
	sustain_steam = 15,
	tactical = { BUFF=2 },
	on_pre_use = function(self, t, silent) if not self:hasShield() then if not silent then game.logPlayer(self, "You require a weapon and a shield to use this talent.") end return false end return true end,
	getBlock = function(self, t) return self:combatTalentSteamDamage(t, 20, 150) end,
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
			src:setEffect(src.EFF_STUNNED, t.getStunDuration(self, t), {apply_power=self:combatSteampower()})
		end
	end,
	info = function(self, t)
		return ([[Dedicate a portion of your steam tank towards constantly reinforcing your shield's tinkers.
		While active, your block value is increased by +%d.
		Additionally, whenever you block, melee attackers which fail a physical save will be stunned for %d turns.
		Effects increase with Steampower.]]):format(t.getBlock(self, t), t.getStunDuration(self, t))
	end,
}

newTalent{
	-- Sustained ability.
	-- Blocking now slams your shield down with such force that it disrupts enemies in a radius around you.
	name = "Thumper Module",
	type = {"steamtech/shield-augments", 2},
	require = steamreq2,
	mode = "sustained",
	points = 5,
	cooldown = 14,
	sustain_steam = 15,
	tactical = { BUFF=2 },
	on_pre_use = function(self, t, silent) if not self:hasShield() then if not silent then game.logPlayer(self, "You require a weapon and a shield to use this talent.") end return false end return true end,
	getAvoidPwr = function(self, t) return 3 * self:getTalentLevelRaw(t) end,
	getDazeDur = function(self, t) return math.floor(self:combatTalentScale(t, 2.0, 4.0)) end,
	target = function(self, t)
		return {type="ball", range=0, radius=2, selffire=false, talent=t}
	end,
	activate = function(self, t)
		local ret = {}
		self:talentTemporaryValue(ret, "cancel_damage_chance", t.getAvoidPwr(self, t))
		return ret
	end,
	deactivate = function(self, t, p)
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
				target:setEffect(target.EFF_DAZED, t.getDazeDur(self, t), {apply_power=self:combatSteampower()})
			end)
			
			game:playSoundNear(self, "talents/earth")
		end
		return
	end,
	info = function(self, t)
		return ([[Augments your shield with a steam-powered kinetic reinforcer.
		The kinetic reinforcer augments your reflexes, giving you a %d%% chance to reduce incoming damage to 0.
		This enhances shield deployment speed so much that it allows you to emit shockwaves in a 2-tile radius around you whenever you block (by slamming said shield onto the ground).
		Hit targets will be dazed for %d turns.]]):format(t.getAvoidPwr(self, t), t.getDazeDur(self, t))
	end,
}

newTalent{
	-- Sustained ability. When hit, deal fire damage to attacker.
	-- Blocking emits a scalding-steam nova around you, blinding and disarming targets.
	name = "Thermal Reprisal",
	type = {"steamtech/shield-augments", 3},
	require = steamreq3,
	mode = "sustained",
	points = 5,
	cooldown = 14,
	sustain_steam = 15,
	tactical = { BUFF=2 },
	on_pre_use = function(self, t, silent) if not self:hasShield() then if not silent then game.logPlayer(self, "You require a weapon and a shield to use this talent.") end return false end return true end,
	getDamageOnMeleeHit = function(self, t) return self:combatTalentScale(t, 15, 40) end,
	getDebuffDur = function(self, t) return math.floor(self:combatTalentScale(t, 2.0, 4.0)) end,
	getCripplePow = function(self, t) return self:combatTalentScale(t, 14, 28) / 100 end,
	target = function(self, t)
		return {type="ball", range=0, radius=1, selffire=false, talent=t}
	end,
	activate = function(self, t)
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
				target:setEffect(target.EFF_SUNDER_ARMS, t.getDebuffDur(self, t), {power=6*self:getTalentLevel(t), apply_power=self:combatSteampower()})
				target:setEffect(target.EFF_CRIPPLE, t.getDebuffDur(self, t), {speed=t.getCripplePow(self, t), apply_power=self:combatSteampower()})
			end)
		end
		return
	end,
	info = function(self, t)
		return ([[Destabilizes your heat tank, making it violently react to any sudden impact with a burst of scalding steam.
		All melee attackers take %d fire damage when they hit you.
		Additionally, whenever you block, the sudden motion causes scalding steam to erupt around you, reducing the accuracy of adjacent units by %d and their melee, spellcasting, and mental speeds by %d%% for %d turns.
		You are immune to the steam's effects (having endured it for so long).
		Effects increase with Steampower.]]):format(t.getDamageOnMeleeHit(self, t), 6 * self:getTalentLevel(t), t.getCripplePow(self, t)*100, t.getDebuffDur(self, t))
	end,
}

newTalent{
	-- Sustained. Automatically block every turn.
	-- Whenever you block, a random ball of lightning strikes a target in range, dealing damage to target and all units around it.
	name = "Galvanic Discharge",
	type = {"steamtech/shield-augments", 4},
	points = 5,
	require = steamreq4,
	mode = "sustained",
	points = 5,
	cooldown = 24,
	fixed_cooldown= true,
	range = 8,
	drain_steam = 22,
	tactical = { BUFF=2 },
	on_pre_use = function(self, t, silent) if not self:hasShield() then if not silent then game.logPlayer(self, "You require a weapon and a shield to use this talent.") end return false end return true end,
	getDamage = function(self, t) return self:combatTalentSteamDamage(t, 65, 140) end,
	getTargetCount = function(self, t) return 1 end,
	target = function(self, t)
		return {type="ball", range=0, radius=1, selffire=false, talent=t}
	end,
	activate = function(self, t)
		return true
	end,
	deactivate = function(self, t, p)
		return true
	end,
	callbackOnActBase = function(self, t)
		self:forceUseTalent(self.T_BLOCK, {ignore_energy=true, ignore_cd = true, silent = true})
		return
	end,
	callbackOnTalentPost = function(self, t, ab, ret)
		if ab.id == self.T_BLOCK and ret == true then
			local tg = {type="ball", radius=1, range=self:getTalentRange(t), talent=t, friendlyfire=false}
			
			local tgts = {}
			local grids = core.fov.circle_grids(self.x, self.y, 8, true)
			for x, yy in pairs(grids) do for y, _ in pairs(grids[x]) do
				local a = game.level.map(x, y, Map.ACTOR)
				if a and self:reactionToward(a) < 0 then
					tgts[#tgts+1] = a
				end
			end end
			
			for i = 1, t.getTargetCount(self, t) do
				if #tgts <= 0 then break end
				local a, id = rng.table(tgts)
				table.remove(tgts, id)

				self:project(tg, a.x, a.y, DamageType.LIGHTNING_DAZE, {dam=rng.avg(1, self:steamCrit(t.getDamage(self, t)), 3), daze=(self:attr("lightning_daze_tempest") or 0) / 2})
				if core.shader.active() then game.level.map:particleEmitter(a.x, a.y, tg.radius, "ball_lightning_beam", {radius=tg.radius, tx=x, ty=y}, {type="lightning"})
				else game.level.map:particleEmitter(a.x, a.y, tg.radius, "ball_lightning_beam", {radius=tg.radius, tx=x, ty=y}) end
				game.logSeen(self, "#LIGHT_BLUE#%s's shield pulses a bolt of lightning!", self.name:capitalize())
				game:playSoundNear(self, "talents/lightning")
			end
		end
		return
	end,
	info = function(self, t)
		local printAutoCd = autoShieldCooldown
		return ([[Overloads your shield's tinkers, boosting shielding capabilities beyond human capacity.
		While active, you instantly block at the start of every turn (even if block is on cooldown).
		Additionally, whenever you block, the installed tinkers burst with power; lightning electrocutes a random enemy within 8 tiles of you.
		The target and all units adjacent to it take %d lightning damage, scaling with Steampower.
		Rapidly drains steam while active (-22/turn).]]):format(t.getDamage(self, t))
	end,
}
