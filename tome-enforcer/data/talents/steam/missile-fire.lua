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
	-- Fire one of three grenade types.
	-- Flashbang: Blind and decaying global speed slow.
	-- Noxious Gas: Reduces outgoing damage. All talents have a chance to fail.
	-- Shrapnel: Bleed.
	name = "Grenade Launcher",
	type = {"steamtech/missile-fire", 1},
	points = 5,
	cooldown = 10,
	mode = "sustained",
	require = steamreq1,
	tactical = { BUFF=2 },
	requires_target = true,
	range = 10,
	drain_steam = 4, -- 1 less than starting steam generator
	getSplash = function(self, t) return self:combatTalentSteamDamage(t, 2, 50) end,
	getReduction = function(self, t) return self:combatTalentLimit(t, 40, 5, 25) end,
	getResists = function(self, t) return self:combatTalentLimit(t, 40, 5, 20) end,
	activate = function(self, t)
		local ret = {}
		self:talentTemporaryValue(ret, "on_melee_hit", {[DamageType.FIRE] = t.getSplash(self, t)})
		self:talentTemporaryValue(ret, "resists", {all=t.getResists(self, t)})
		self:talentTemporaryValue(ret, "reduce_detrimental_status_effects_time", t.getReduction(self, t))
		return ret
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		return ([[Equipped with you at all times is the GC-001, a steam-powered "remote propellent device."
		The GC-001 is capable of firing three grenades: Flashbang, Noxious Gas, and Shrapnel.
		
		Flashbang: Blinds and reduces global speed of hit targets by XX (effects decay by XX each turn) in a radius-XX circle for XX turns.
		
		Noxious Gas: Disperses crippling gases in a radius-XX circle. All units currently within the area of effect deal XX reduced damage and have XX reduced global speed. The gas lingers for XX turns.
		
		Shrapnel: Explodes, sending chunks of shrapnel in a radius-XX circle. All hit units bleed for XX damage over XX turns.
		
		Using any one of these abiltiies places the other two on a short cooldown, as the GC-001 needs time to fabricate another grenade. Effects increase with Steampower.]])
	end,
}

newTalent{
	-- Enhances next grenade.
	-- Flashbang: Adds incendiary elements, burning all targets.
	-- Noxious Gas: Infuses antimagic elements, silencing targets and burning magical resources.
	-- Shrapnel: Overloads the grenade, increasing area of effect and shredding armor.
	name = "Volatile Chemicals",
	type = {"steamtech/missile-fire", 2},
	points = 5,
	require = steamreq2,
	cooldown = 12,
	steam = 30,
	getDamage = function(self, t) return self:combatTalentSteamDamage(t, 2, 240) end,
	tactical = { DISABLE = 1 },
	range = 10,
	reflectable = true,
	proj_speed = 2,
	requires_target = true,
	target = function(self, t)
		return {type="bolt", range=self:getTalentRange(t), talent=t, friendlyfire=false, selffire=false, display={display=' ', particle="arrow", particle_args={tile="shockbolt/npc/mechanical_drone_mind_drone"}}}
	end,
	getFail = function(self, t) return self:combatTalentLimit(t, 50, 19, 35) end, -- Limit < 50%
	getReduction = function(self, t) return self:combatTalentLimit(t, 70, 25, 65) end, -- Limit < 50%
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end

		local lx, ly
		local a = math.atan2(y - self.y, x - self.x) + math.pi / 2
		local l = core.fov.line(self.x, self.y, self.x + 10 * math.cos(a), self.y + 10 * math.sin(a))
		local nb = 0
		while nb < 2 do
			lx, ly = l:step() if not lx then break end
			local tg = self:getTalentTarget(t)
			tg.start_x = lx
			tg.start_y = ly
			self:projectile(tg, x, y, DamageType.MIND_DRONE, {dam=0, fail=t.getFail(self, t), reduction=t.getReduction(self, t)})
			nb = nb + 1
		end
		a = a + math.pi
		nb = 0
		local l = core.fov.line(self.x, self.y, self.x + 10 * math.cos(a), self.y + 10 * math.sin(a))
		while nb < 2 do
			lx, ly = l:step() if not lx then break end
			local tg = self:getTalentTarget(t)
			tg.start_x = lx
			tg.start_y = ly
			self:projectile(tg, x, y, DamageType.MIND_DRONE, {dam=0, fail=t.getFail(self, t), reduction=t.getReduction(self, t)})
			nb = nb + 1
		end
		local tg = self:getTalentTarget(t)
		self:projectile(tg, x, y, DamageType.MIND_DRONE, {dam=0, fail=t.getFail(self, t), reduction=t.getReduction(self, t)})

		return true
	end,
	info = function(self, t)
		return ([[Augments the effects of your grenades, adding the following effects to hit targets:
		
		Flashbang: Incorporates incendiary elements, causing all hit targets to burn for XX damage over XX turns.
		
		Noxious Gas: Incorporates antimagic gifts, silencing all targets in the area of effect and burning XX arcane resource(s) per turn.
		
		Shrapnel: Incorporates voratun shards, shredding XX Armor and reducing Physical Save by XX.
		
		Effects increase with Steampower.]])
	end,
}

newTalent{
	name = "Blastback",
	type = {"steamtech/missile-fire", 3},
	points = 5,
	cooldown = 20,
	steam = function(self, t) return self:getSteam() end,
	require = steamreq3,
	tactical = { DISABLE = 2, ATTACKAREA = { FIRE = 2 } },
	range = 0,
	radius = 5,
	getFactor = function(self, t) return self:combatScale(math.min(self:getSteam(), 100), 15, 0, 100, 100, 1) / 100 end,
	getDamage = function(self, t) return self:combatTalentSteamDamage(t, 180, 500) * (t.getFactor(self, t)) end,
	target = function(self, t)
		return {type="cone", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire=false, talent=t}
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:project(tg, x, y, DamageType.DIG, 1)
		self:project(tg, x, y, DamageType.FLAMESHOCK, {dam=t.getDamage(self, t), dur=4, apply_power = 10000})
		game.level.map:particleEmitter(self.x, self.y, tg.radius, "breath_fire", {radius=tg.radius, tx=x-self.x, ty=y-self.y})
		game:playSoundNear(self, "talents/fireflash")
		
		self:knockback(x, y, 3)
		
		return true
	end,
	info = function(self, t)
		return ([[Utilize all your steam reserves to deliver a radius-5 conal shrapnel blast from the GC-001, destroying all diggable terrain in its path.
		Hit targets are stunned and burn for %d damage over 4 turns. This effect bypasses resistances.
		The sheer blast force knocks you back 3 tiles.
		
		Damage scales based on your current steam reserves, reaching 100%% efficiency at 100 Steam (#YELLOW#currently: %d%%#WHITE#) and increases with Steampower.]]):format(t.getDamage(self, t), 100 * t.getFactor(self, t))
	end,
}

newTalent{
	-- Buff which removes all grenade cooldowns while active.
	name = "Catalyzing Agents",
	type = {"steamtech/missile-fire", 4},
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
		return ([[Installs an air-purifying catalyzer to the GC-001, causing anything fired from it to emit medicinal fumes.
		Firing a grenade releases some fumes, granting a stack of Invigoration (max 3) for 10 turns. Performing Blastback generates max stacks.
		
		Each stack of Invigoration grants +XX health regeneration (max: +XX) and +XX to all saves and powers (max: +XX).]])
	end,
}
