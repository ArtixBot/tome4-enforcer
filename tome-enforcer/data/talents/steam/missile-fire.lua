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
		return ([[Attach a "remote propellant device" to your steam generator, siphoning excess steam which you use to bombard foes.
		You can fire one of three grenades up to range 9: Flashbang, Noxious Gas, Shrapnel.
		
		Flashbang: Blinds and reduces global speed of hit targets by XX (effects decay by XX each turn) in a radius-2 circle for XX turns.
		
		Chemical Gas: Disperses crippling gases in a radius-XX circle. All units currently within the area of effect deal XX reduced damage and have XX reduced global speed. The gas lingers for XX turns.
		
		Shrapnel: Explodes, sending chunks of shrapnel in a radius-XX circle. All hit units bleed for XX damage over XX turns.
		
		Using any one of these abiltiies places the other two on a short cooldown, as the GC-001 needs time to fabricate another grenade. Effects increase with Steampower.]])
	end,
}

newTalent{
	-- Chance to ignore cooldown on grenade fire.
	-- Whenever you fire a grenade gain movement speed for 1 turn.
	name = "Bombardment",
	type = {"steamtech/missile-fire", 2},
	points = 5,
	require = steamreq2,
	mode = "passive",
	getMove = function(self, t) return self:combatTalentScale(t, 2.00, 5.00) end,
	callbackOnTalentPost = function(self, t, ab, ret)
		if (ab.id == self.T_GRENADE_FLASHBANG or ab.id == self.T_GRENADE_CHEMICAL_GAS or ab.id == self.T_GRENADE_SHRAPNEL) and ret == true then
			self:setEffect(self.EFF_STEP_UP, 1, {power=t.getMove(self, t)})
			game.logSeen(self, "#LIGHT_BLUE#%s repositions after firing!", self.name:capitalize())
		end
		return
	end,
	info = function(self, t)
		return ([[Firing a grenade channels additional steam through your remote propellant device which can be used to propel yourself.
		You gain %d%% movement speed for the next turn.
		This talent has a cooldown.]]):format(t.getMove(self, t) * 100)
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
		return ([[Open all steam vents from your generator's port to deliver a radius 5 conal steam blast, destroying all diggable terrain in its path.
		Hit targets are stunned and burn for %d damage over 4 turns. This effect bypasses resistances.
		The sheer blast force knocks you back 3 tiles.
		
		Damage scales based on your current steam reserves, reaching 100%% efficiency at 100 Steam (#YELLOW#currently: %d%%#WHITE#) and increases with Steampower.]]):format(t.getDamage(self, t), 100 * t.getFactor(self, t))
	end,
}

newTalent{
	-- Chance for free grenade launches!
	name = "Hair Trigger Mechanism",
	type = {"steamtech/missile-fire", 4},
	points = 5,
	require = steamreq4,
	drain_steam = 3,
	mode = "sustained",
	getChance = function(self, t) return self:combatTalentScale(t, 7, 21) end,
	activate = function(self, t)
		local talent = self:talentDialog(require("mod.dialogs.talents.EnforcerHairTrigger").new(self))
		if talent then
			return {talent = talent} 
		else return nil end
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		local talent = self:isTalentActive(t.id) and self:getTalentFromId(self:isTalentActive(t.id).talent).name or "None"
		return ([[Select a grenade skill.
		Every time you fire your steamgun there's a XX chance that the selected grenade is launched at the same location you fired at.
		This grenade launch is instant, ignores available resources, and does not incur cooldowns.
		
		Currently Selected Grenade: %s]]):format(talent)
	end,
}

-- GRENADE TALENTS --

newTalent{
	-- Core functionality works.
	name = "Grenade: Flashbang", short_name = "GRENADE_FLASHBANG",
	type = {"steamtech/missile-fire", 1},
	points = 5,
	range = 9,
	radius = 2,
	cooldown = 8,
	steam = 10,
	proj_speed = 6,
	hide = true,
	direct_hit = true,
	tactical = { ATTACKAREA = 2 },
	getSlow = function(self, t) return self:combatTalentScale(t, 0.20, 0.40) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 3, 5)) end,
	target = function(self, t) return {type="ball", range = self:getTalentRange(t), radius = self:getTalentRadius(t), selffire = false, friendlyfire = false, talent = t, display={particle="bolt_light", particle_args={size_factor=0.75}, trail="lighttrail"}} end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		
		-- Getting the particle effects to work on this ~as originally intended~ is unbelievably infuriating.
		-- Finally done though.
		self:projectile(tg, x, y, function(px, py, tg, self)
			game.level.map:particleEmitter(px, py, 1, "light")
			
			local target = game.level.map(px, py, Map.ACTOR)
			if not target then return end
			target:setEffect(target.EFF_FLASHBANG_BLIND, t.getDuration(self, t), {power=t.getSlow(self, t), orig_dur = t.getDuration(self, t), apply_power=self:combatSteampower()})
		end)
		
		game:playSoundNear(self, "talents/lightning")
		return true
	end,
	info = function(self, t)
		return ([[Launch a flashbang grenade which quickly travels towards the target area.
		Once it lands the grenade detonates, emitting a bright flash of light that blinds and slows (intensity %d%%, before scaling down) all enemies in a 2-tile radius around it for %d turns.
		The slow's intensity decays by %0.2f%% each turn.
		Negative effect application chance increases with Steampower.]]):format(t.getSlow(self, t) * 100, t.getDuration(self, t), 100 / t.getDuration(self, t))
	end,
}

newTalent{
	name = "Grenade: Chemical Gas", short_name = "GRENADE_CHEMICAL_GAS",
	type = {"steamtech/missile-fire", 1},
	points = 5,
	range = 9,
	radius = 3,
	cooldown = 8,
	steam = 10,
	proj_speed = 6,
	hide = true,
	direct_hit = true,
	tactical = { ATTACKAREA = 2 },
	getDam = function(self, t) return self:combatTalentScale(t, 12, 26) end,
	getMod = function(self, t) return self:combatTalentScale(t, 23, 45) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 5, 9)) end,
	target = function(self, t) return {type="ball", range = self:getTalentRange(t), radius = self:getTalentRadius(t), selffire = false, friendlyfire = false, talent = t, display={particle="bolt_light", particle_args={size_factor=0.75}, trail="lighttrail"}} end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		
		-- The projectile itself doesn't deal damage. As it turns out, cosmetic is a damage type and it doesn't clog the logs. How efficient!
		-- Makes adding effects to a map a lot easier since it prevents each tile from getting like 16 instances of the same map effect (also doesn't kill GPUs).
		self:projectile(tg, x, y, DamageType.COSMETIC, 0, function(self, tg, x, y, grids)
			game.level.map:addEffect(self,
				x, y, 8,	-- Effect epicenter location and duration.
				DamageType.CHEMICAL_GAS, {power = t.getDam(self, t), heal_factor = t.getMod(self, t)},	-- Damage type / damage dealt.
				3,	-- Effect radius.
				5, 5, 	-- Ball effect, angle.
				{type="vapour"}	--Overlay effect.
			)
		end)
		
		game:playSoundNear(self, "talents/lightning")
		return true
	end,
	info = function(self, t)
		return ([[Launch a chemical gas grenade which quickly travels towards the target area.
		Once it lands the grenade activates, dispersing a field of crippling vapors in a radius 3 circle, lasting 8 turns.
		All units (friend or foe) inside the target area are poisoned, reducing damage dealt by %d%% and healing mod by %d%%.
		This lasts up to 3 turns once outside the area of effect (but is indefinite otherwise).]]):format(t.getDam(self, t), t.getMod(self, t))
	end,
}

newTalent{
	name = "Grenade: Shrapnel", short_name = "GRENADE_SHRAPNEL",
	type = {"steamtech/missile-fire", 1},
	points = 5,
	range = 9,
	radius = 2,
	cooldown = 8,
	steam = 10,
	proj_speed = 6,
	direct_hit = true,
	hide = true,
	tactical = { ATTACKAREA = 2 },
	getDam = function(self, t) return self:combatTalentSteamDamage(t, 85, 300) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 5, 9)) end,
	target = function(self, t) return {type="ball", range = self:getTalentRange(t), radius = self:getTalentRadius(t), selffire = false, friendlyfire = false, talent = t, display={particle="bolt_light", particle_args={size_factor=0.75}, trail="lighttrail"}} end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		
		self:projectile(tg, x, y, DamageType.BLEED, t.getDam(self, t))
		
		game:playSoundNear(self, "talents/lightning")
		return true
	end,
	info = function(self, t)
		return ([[Launch a shrapnel grenade which quickly travels towards the target area.
		Once it lands the grenade explodes, hurling shrapnel in a radius 2 circle.
		Hit targets take %d physical damage and then bleed for %d damage over 5 turns. Allies are unaffected.
		Damage increases with Steampower.]]):format(t.getDam(self, t) * 0.2, t.getDam(self, t) * 0.8)
	end,
}
